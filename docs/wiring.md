# Wiring

The ESP32 drives a BTS7960 (IBT-2) H-bridge module, which switches 12 V to the RS550 motor. The firmware runs the motor in one direction only.

## Connections

### Logic (ESP32 → BTS7960 control header)

| ESP32 pin | BTS7960 pin | Purpose |
|---|---|---|
| GPIO25 | `RPWM` | Speed (20 kHz PWM, forward) |
| GPIO26 | `LPWM` | Held low (reverse unused) |
| GPIO27 | `R_EN` | Driver enable |
| GPIO14 | `L_EN` | Driver enable |
| 5 V (VIN) | `VCC` | Driver logic supply |
| GND | `GND` | Common ground |

The ESP32 is powered over USB (a power bank in the demo). Its 5 V pin feeds the driver's logic supply.

### Power (12 V supply → BTS7960 screw terminals → motor)

```text
12 V supply +  ── 10–15 A fuse ── B+
12 V supply −  ─────────────────── B−
motor tab 1    ─────────────────── M+
motor tab 2    ─────────────────── M−
```

- Use 16 AWG or heavier wire for the 12 V supply and the motor leads. Jumper wires are only for the logic header.
- The order of `M+`/`M−` sets the spin direction. Swap the motor wires if the wheel spins the wrong way. The underside of the wheel must move **in the direction you want to throw** (it rolls over the top of the ball and pushes it out of the lane).
- Female spade terminals fit the RS550's motor tabs.

## Cautions

- Never connect 12 V to the ESP32, the logic header, a breadboard or jumper wires.
- Clone BTS7960 boards vary. Check the silkscreen pin names before you power it up.
- For the first power-up, test with no wheel fitted, the motor held down, and hands clear of the shaft. A current-limited bench supply (start around 2 A) is the safest first test.
- Stop the motor before you change direction.
- The motor's current under load wasn't measured. After a run, check the driver, wires and fuse for heat.
