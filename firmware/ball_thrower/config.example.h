#pragma once

// Copy this file to config.h (git-ignored) and fill in your details.
// Without config.h (or if the Wi-Fi join fails for 30 s), the ESP32 starts
// its own access point instead; its page is then at http://192.168.4.1/

// Wi-Fi network the ESP32 joins (2.4 GHz).
#define WIFI_STA_SSID "your-wifi-name"
#define WIFI_STA_PASSWORD "your-wifi-password"

// mDNS name: the page is served at http://<DEVICE_HOSTNAME>.local
#define DEVICE_HOSTNAME "ballthrower"

// Fallback access point name and password (password: 8+ characters).
#define AP_SSID "BallThrower"
#define AP_PASSWORD "choose-an-ap-password"

// Optional: use a fixed, locally administered MAC address (first byte 0x02)
// if your router stops accepting the board after repeated failed joins.
// #define WIFI_STA_MAC 0x02, 0x00, 0x00, 0x00, 0x00, 0x01
