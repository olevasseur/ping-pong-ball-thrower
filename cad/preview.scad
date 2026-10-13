// README pictures: launcher base with the rear door, an RS550 motor stand-in,
// the 57 mm wheel and a 40 mm ball. Preview only, not a print file.
// part = "assembly" (base + motor + wheel + ball), "base" (printed parts only)
// or "section" (cut through the lane centre, ball under the wheel).

use <launcher_base.scad>
use <lib/motor_cradle.scad>
use <wheel_57mm.scad>

part = "assembly";
$fn = 96;

shaft_z = 6 + 66.5;          // launch base top + shaft height
cradle_z = 49;
wheel_center_y = -17.6;      // lane centre
wheel_w = 16;
ball_d = 40;

base_color  = [0.20, 0.21, 0.24];
door_color  = [0.85, 0.45, 0.15];
motor_color = [0.78, 0.78, 0.80];
wheel_color = [0.30, 0.55, 0.80];
ball_color  = [1.00, 0.88, 0.45];

module door() { translate([0, 0, cradle_z]) sliding_door_installed(); }

module motor_stand_in() {
    translate([0, 0, shaft_z]) rotate([-90, 0, 0]) {
        cylinder(d = 35, h = 58);                                              // can (face pins to rear door)
        translate([0, 0, -0.01]) mirror([0, 0, 1]) cylinder(d = 3.2, h = 23);  // shaft + pinion
    }
    for (x = [-5, 5]) translate([x - 1.5, 58, shaft_z + 8]) cube([3, 6, 0.8]);  // terminal tabs
}

module wheel_installed() {
    translate([0, wheel_center_y - wheel_w / 2, shaft_z]) rotate([-90, 0, 0])
        smooth_taped_wheel();
}

module ball(x = 46) { translate([x, wheel_center_y, 6 + ball_d / 2]) sphere(d = ball_d); }

// Removes everything nearer the viewer than the lane centre plane.
module cut() {
    difference() {
        children();
        translate([-200, wheel_center_y - 200, -1]) cube([400, 200, 200]);
    }
}

if (part == "section") {
    color(base_color) cut() mount_body();
    color(door_color) cut() door();
    color(motor_color) cut() motor_stand_in();
    color(wheel_color) cut() wheel_installed();
    color(ball_color) cut() ball(0);
} else {
    color(base_color) mount_body();
    color(door_color) door();
    if (part == "assembly") {
        color(motor_color) motor_stand_in();
        color(wheel_color) wheel_installed();
        color(ball_color) ball();
    }
}
