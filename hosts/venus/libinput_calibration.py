#!/usr/bin/env python

# For click{0..3} X & Y values run:
# $ xinput_calibrator --verbose

click0 = 176, 104
click1 = 1195, 104
click2 = 176, 675
click3 = 1195, 675


tablet = "Wacom ISDv4 E6 Pen"
screen = 1366, 768

a = (screen[0] * 6 / 8) / (click3[0] - click0[0])
c = ((screen[0] / 8) - a * click0[0]) / screen[0]
e = (screen[1] * 6 / 8) / (click3[1] - click0[1])
f = ((screen[1] / 8) - e * click0[1]) / screen[1]

print(f"ATTRS{{name}}==\"{tablet}\", ENV{{LIBINPUT_CALIBRATION_MATRIX}}=\"{a} 0.0 {c} 0.0 {e} {f}\"")
