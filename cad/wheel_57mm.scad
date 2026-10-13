// 57 mm throwing wheel that presses straight onto the RS550's fixed 10-tooth
// pinion. Units: mm. Needs OpenSCAD's bundled MCAD library.
// Print flat, closed face down. Wrap one even band of tape around the tread
// after installing: bare PLA throws only a short distance.

use <MCAD/involute_gears.scad>;

$fn = 96;

ball_diameter = 40;
shaft_above_base_top = 66.5;
wheel_diameter = 57;
wheel_width = 16;
nominal_tape_width = 12;

// Internal-gear socket fitted to the motor pinion (tested fit; do not change).
pinion_teeth = 10;
pinion_outside_d = 10.0;
pinion_face_width = 13.0;
pinion_module = pinion_outside_d / (pinion_teeth + 2);
pressure_angle = 20;
tooth_clearance = pinion_module * 0.25;
cavity_profile_clearance = 0.30;
socket_base_thickness = 2.6;
socket_depth = pinion_face_width + 0.4;

wheel_lower_rim_height = shaft_above_base_top - wheel_diameter / 2;
ball_top_height = ball_diameter;

function pitch_radius(teeth) = pinion_module * teeth / 2;
function outer_radius(teeth) = pitch_radius(teeth) + pinion_module;
function root_radius(teeth) = pitch_radius(teeth) - pinion_module - tooth_clearance;
function base_radius(teeth) = pitch_radius(teeth) * cos(pressure_angle);
function half_tooth_angle(teeth) = 360 / teeth / 4;

assert(ball_diameter == 40, "Designed for a standard 40 mm ball.");
assert(wheel_width == socket_base_thickness + socket_depth,
       "Wheel must keep a closed socket base behind the pinion.");
assert(nominal_tape_width < wheel_width, "Tape must fit smooth wheel width.");
assert(wheel_lower_rim_height == 38 && ball_top_height - wheel_lower_rim_height == 2,
       "57 mm wheel gives 38 mm lower rim and 2 mm nominal ball pinch.");
assert(wheel_diameter / 2 > outer_radius(pinion_teeth) + cavity_profile_clearance + 10,
       "Wheel needs substantial solid rim beyond passed pinion socket.");

module cavity_profile() {
    offset(delta = cavity_profile_clearance)
        gear_shape(number_of_teeth = pinion_teeth,
                   pitch_radius = pitch_radius(pinion_teeth),
                   root_radius = root_radius(pinion_teeth),
                   base_radius = base_radius(pinion_teeth),
                   outer_radius = outer_radius(pinion_teeth),
                   half_thick_angle = half_tooth_angle(pinion_teeth),
                   involute_facets = 10);
}

module smooth_taped_wheel() {
    difference() {
        cylinder(d = wheel_diameter, h = wheel_width);
        // Pinion enters from top; closed bottom transfers torque.
        translate([0, 0, socket_base_thickness])
            linear_extrude(height = socket_depth + 0.02, convexity = 10)
                cavity_profile();
    }
}

smooth_taped_wheel();
