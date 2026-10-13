// Ping-pong ball thrower: RS550 speed control from a phone, through a BTS7960
// driver.
//
// Joins your Wi-Fi (settings in config.h); page at http://ballthrower.local
// or the IP printed on serial. Without config.h, or if the Wi-Fi join fails
// for 30 s, it makes its own network "BallThrower" with the page at
// http://192.168.4.1. Unplug the board when not in use.
//
// Safety:
// - boots stopped, driver disabled;
// - speed changes ramp (no instant jump to full power);
// - STOP is instant (PWM 0 and driver disabled);
// - if the page stops checking in for 3 s (phone locked, tab closed, out of
//   range), the motor ramps to a stop.
//
// Wiring (see docs/wiring.md): RPWM 25, LPWM 26, R_EN 27, L_EN 14.
// ESP32 Arduino core 3.x (pin-based LEDC API).

#include <WiFi.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include <esp_wifi.h>
#include <DNSServer.h>

// Wi-Fi and device settings live in config.h (git-ignored).
// Copy config.example.h to config.h and fill it in.
#if __has_include("config.h")
#include "config.h"
#endif

#if defined(WIFI_STA_SSID) && defined(WIFI_STA_PASSWORD)
#define HAS_WIFI_SECRETS 1
#else
#define HAS_WIFI_SECRETS 0
#endif

// Fallback access point. Set your own AP_PASSWORD (8+ characters) in config.h.
#ifndef AP_SSID
#define AP_SSID "BallThrower"
#endif
#ifndef AP_PASSWORD
#define AP_PASSWORD "change-me-please"
#endif
#ifndef DEVICE_HOSTNAME
#define DEVICE_HOSTNAME "ballthrower"
#endif

constexpr uint8_t RPWM = 25;
constexpr uint8_t LPWM = 26;
constexpr uint8_t R_EN = 27;
constexpr uint8_t L_EN = 14;
constexpr uint32_t PWM_FREQUENCY = 20000;
constexpr uint8_t PWM_RESOLUTION = 8;

constexpr float RAMP_PERCENT_PER_S = 50.0f;      // 0 -> 100 % takes 2 s
constexpr uint32_t HEARTBEAT_TIMEOUT_MS = 3000;
constexpr uint32_t CONTROL_PERIOD_MS = 20;

WebServer server(80);

float targetPercent = 0.0f;
float currentPercent = 0.0f;
bool driverEnabled = false;
uint32_t lastHeartbeatMs = 0;
uint32_t lastControlMs = 0;
const char *lastStopReason = "boot";

void writeDuty(float percent) {
  const uint32_t duty = static_cast<uint32_t>(percent * 255.0f / 100.0f + 0.5f);
  ledcWrite(RPWM, duty);
  ledcWrite(LPWM, 0);
}

void enableDriver(bool on) {
  digitalWrite(R_EN, on ? HIGH : LOW);
  digitalWrite(L_EN, on ? HIGH : LOW);
  driverEnabled = on;
}

void stopNow(const char *reason) {
  targetPercent = 0.0f;
  currentPercent = 0.0f;
  writeDuty(0.0f);
  enableDriver(false);
  lastStopReason = reason;
  Serial.printf("STOP (%s)\n", reason);
}

void controlTick() {
  const uint32_t now = millis();
  const float dt = (now - lastControlMs) / 1000.0f;
  lastControlMs = now;

  if (targetPercent > 0.0f && now - lastHeartbeatMs > HEARTBEAT_TIMEOUT_MS) {
    targetPercent = 0.0f;
    lastStopReason = "page stopped checking in";
    Serial.println("Heartbeat lost: ramping to stop");
  }

  const float step = RAMP_PERCENT_PER_S * dt;
  if (currentPercent < targetPercent) {
    currentPercent = min(targetPercent, currentPercent + step);
  } else if (currentPercent > targetPercent) {
    currentPercent = max(targetPercent, currentPercent - step);
  }

  if (currentPercent > 0.0f && !driverEnabled) enableDriver(true);
  writeDuty(currentPercent);
  if (currentPercent == 0.0f && targetPercent == 0.0f && driverEnabled) enableDriver(false);
}

const char kPage[] PROGMEM = R"HTML(<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Ball Thrower</title>
<style>
:root{--bg:#14161a;--panel:#1e2127;--ink:#eef0f3;--muted:#9aa1ad;--go:#2f9e6a;--stop:#d43c3c;--accent:#e8a33d}
*{box-sizing:border-box}body{margin:0;padding:20px 16px;background:var(--bg);color:var(--ink);
font:16px/1.4 system-ui,-apple-system,Segoe UI,Roboto,sans-serif;max-width:480px;margin-inline:auto}
h1{font-size:22px;margin:0 0 4px}.sub{color:var(--muted);font-size:13px;margin-bottom:18px}
.panel{background:var(--panel);border-radius:14px;padding:18px;margin-bottom:14px}
.big{font-size:56px;font-weight:700;font-variant-numeric:tabular-nums;line-height:1}
.row{display:flex;gap:10px;flex-wrap:wrap}.lbl{color:var(--muted);font-size:13px}
input[type=range]{width:100%;height:44px;accent-color:var(--accent)}
button{flex:1;min-width:64px;padding:16px 10px;border:0;border-radius:12px;font-size:18px;font-weight:600;
background:#2b2f37;color:var(--ink)}button:active{transform:scale(.97)}
#go{background:var(--go)}#stop{background:var(--stop);font-size:26px;padding:26px;width:100%}
.bar{height:10px;background:#2b2f37;border-radius:6px;overflow:hidden;margin-top:10px}
.bar>div{height:100%;width:0;background:var(--accent);transition:width .1s}
#msg{color:var(--muted);font-size:13px;min-height:1.4em}
</style></head><body>
<h1>Ball Thrower</h1><div class="sub">RS550 speed control</div>
<div class="panel"><div class="lbl">Motor now</div><div class="big"><span id="cur">0</span>%</div>
<div class="bar"><div id="curbar"></div></div></div>
<div class="panel"><div class="lbl">Set speed: <b id="setv">0</b>%</div>
<input id="sl" type="range" min="0" max="100" step="1" value="0">
<div class="row"><button data-p="25">25</button><button data-p="50">50</button><button data-p="75">75</button><button data-p="100">100</button></div>
<div class="row" style="margin-top:10px"><button id="go">Go</button></div></div>
<button id="stop">STOP</button>
<p id="msg"></p>
<script>
const $=id=>document.getElementById(id);let running=false;
function show(s){$('cur').textContent=Math.round(s.current);$('curbar').style.width=s.current+'%';
 $('msg').textContent=s.target>0?'running':'stopped ('+s.reason+')';}
async function call(p){try{const r=await fetch(p,{cache:'no-store'});show(await r.json());}catch(e){$('msg').textContent='no connection';}}
$('sl').oninput=()=>{$('setv').textContent=$('sl').value;if(running)call('/set?p='+$('sl').value);};
document.querySelectorAll('[data-p]').forEach(b=>b.onclick=()=>{$('sl').value=b.dataset.p;$('sl').oninput();});
$('go').onclick=()=>{running=true;call('/set?p='+$('sl').value);};
$('stop').onclick=()=>{running=false;call('/stop');};
setInterval(()=>call('/hb'),500);
</script></body></html>)HTML";

void sendState() {
  char buf[160];
  snprintf(buf, sizeof buf, "{\"target\":%.1f,\"current\":%.1f,\"driver\":%s,\"reason\":\"%s\"}",
           targetPercent, currentPercent, driverEnabled ? "true" : "false", lastStopReason);
  server.sendHeader("Cache-Control", "no-store");
  server.send(200, "application/json", buf);
}

void handleSet() {
  lastHeartbeatMs = millis();
  float p = server.arg("p").toFloat();
  p = constrain(p, 0.0f, 100.0f);
  targetPercent = p;
  if (p == 0.0f) lastStopReason = "set to 0";
  sendState();
}

void setup() {
  Serial.begin(115200);
  pinMode(R_EN, OUTPUT);
  pinMode(L_EN, OUTPUT);
  enableDriver(false);
  if (!ledcAttach(RPWM, PWM_FREQUENCY, PWM_RESOLUTION) ||
      !ledcAttach(LPWM, PWM_FREQUENCY, PWM_RESOLUTION)) {
    Serial.println("PWM setup failed; driver stays disabled.");
    while (true) delay(1000);
  }
  stopNow("boot");

  // Home WiFi first (station only: an access point on another channel makes
  // the join flaky). If it has not joined within 30 s, start the own network.
  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);
#ifdef WIFI_STA_MAC
  // Optional fixed MAC (config.h), e.g. if the router blocks the factory MAC
  // after repeated failed joins.
  {
    const uint8_t mac[6] = {WIFI_STA_MAC};
    esp_wifi_set_mac(WIFI_IF_STA, mac);
  }
#endif
  WiFi.setSleep(false);
  WiFi.setAutoReconnect(true);
  WiFi.onEvent([](WiFiEvent_t, WiFiEventInfo_t info) {
    Serial.printf("Home WiFi disconnect reason %d\n", info.wifi_sta_disconnected.reason);
  }, ARDUINO_EVENT_WIFI_STA_DISCONNECTED);
#if HAS_WIFI_SECRETS
  {
    const int n = WiFi.scanNetworks();
    int seen = 0;
    for (int i = 0; i < n; i++) {
      if (WiFi.SSID(i) == WIFI_STA_SSID) {
        seen++;
        Serial.printf("Home WiFi seen: signal %d dBm, channel %d, encryption %d\n",
                      static_cast<int>(WiFi.RSSI(i)), static_cast<int>(WiFi.channel(i)), static_cast<int>(WiFi.encryptionType(i)));
      }
    }
    Serial.printf("Scan: %d networks, home WiFi seen %d time(s)\n", n, seen);
    WiFi.scanDelete();
  }
  // Some ESP32 boards see the router fine but fail to join at full transmit
  // power (auth expires); a lower power fixes it on those boards.
  WiFi.setTxPower(WIFI_POWER_8_5dBm);
  WiFi.begin(WIFI_STA_SSID, WIFI_STA_PASSWORD);
  Serial.printf("Joining home WiFi as %s...\n", WiFi.macAddress().c_str());
#else
  Serial.println("No config.h: starting the BallThrower network.");
#endif

  server.on("/", [] { server.send_P(200, "text/html; charset=utf-8", kPage); });
  server.on("/set", handleSet);
  server.on("/stop", [] { stopNow("STOP pressed"); sendState(); });
  server.on("/hb", [] { lastHeartbeatMs = millis(); sendState(); });
  server.on("/state", sendState);
  // Android/Chrome connectivity checks: "internet works", stay on this WiFi.
  server.on("/generate_204", [] { server.send(204); });
  server.on("/gen_204", [] { server.send(204); });
  server.onNotFound([] {
    server.sendHeader("Location", "http://192.168.4.1/");
    server.send(302);
  });
  server.begin();
  lastControlMs = millis();
}

bool apStarted = false;
DNSServer dns;

void wifiTick() {
  static bool wasConnected = false;
  static bool mdnsStarted = false;
  const bool connected = WiFi.status() == WL_CONNECTED;
  if (connected && !wasConnected) {
    if (!mdnsStarted) mdnsStarted = MDNS.begin(DEVICE_HOSTNAME);
    Serial.printf("Home WiFi OK. Open http://%s.local or http://%s\n",
                  DEVICE_HOSTNAME, WiFi.localIP().toString().c_str());
  }
  if (!connected && !apStarted && (!HAS_WIFI_SECRETS || millis() > 30000)) {
    apStarted = true;
    WiFi.disconnect(true);
    WiFi.mode(WIFI_AP);
    WiFi.softAP(AP_SSID, AP_PASSWORD);
    // Answer every name with this board, so Android believes the network has
    // internet and does not send the browser over mobile data instead.
    dns.start(53, "*", WiFi.softAPIP());
    Serial.printf("Home WiFi unavailable. Join WiFi \"%s\", open http://%s (reset the board to retry home WiFi)\n",
                  AP_SSID, WiFi.softAPIP().toString().c_str());
  }
  wasConnected = connected;
}

void loop() {
  server.handleClient();
  if (millis() - lastControlMs >= CONTROL_PERIOD_MS) controlTick();
  wifiTick();
  if (apStarted) dns.processNextRequest();
}
