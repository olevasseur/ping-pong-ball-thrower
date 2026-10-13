// Ping-pong ball launcher base. Units: mm.
// One printed base: 42 mm ball lane with low side rails, two side towers, and
// the raised RS550 motor cradle (lib/motor_cradle.scad). The rear door that
// holds the motor in is a separate small print (part = "door").
// Print the base with tree supports under the raised cradle; see README.

use <lib/motor_cradle.scad>

$fn = 96;
part = "base"; // base, door, assembly

launch_base_t = 6;
shaft_above_launch_base_top = 66.5;
passed_cradle_axis_z = 23.5;
cradle_z = launch_base_t + shaft_above_launch_base_top - passed_cradle_axis_z;

ball_d = 40;
ball_r = ball_d / 2;
side_clear = 1;
lane_gap = ball_d + 2 * side_clear;
lane_center_y = -17.6; // Lane centre under the wheel, ahead of the motor face.
lane_y0 = lane_center_y - lane_gap / 2;
lane_y1 = lane_center_y + lane_gap / 2;
rail_t = 3;
rail_h = ball_r;
lane_x0 = -50;
lane_x1 = 50;
end_margin = 3;

passed_rail_face = 19.5;
passed_outer_x = 26;
passed_y0 = -3;
passed_bed_y1 = 58;
passed_front_key_support_z = 14.55;
vent_y0 = 39;
vent_y1 = 47;
vent_z1 = 12;

tower_y0 = lane_y1;
tower_y1 = passed_bed_y1;
tower_cradle_overlap = 2;
face_ring_lower_z = cradle_z + 14.25;

base_x0 = lane_x0 - end_margin;
base_x1 = lane_x1 + end_margin;
base_y0 = lane_y0 - rail_t;
base_y1 = 61;

assert(part == "base" || part == "door" || part == "assembly" || part == "check" ||
       part == "floor" || part == "floor_towers");
assert(shaft_above_launch_base_top == 66.5 && cradle_z == 49);
assert(lane_gap == 42 && rail_t == 3 && rail_h == 20);

module base_floor() {
    translate([base_x0, base_y0, 0]) cube([base_x1 - base_x0, base_y1 - base_y0, launch_base_t]);
}

module lane_rail(y0) {
    translate([lane_x0, y0, launch_base_t]) cube([lane_x1 - lane_x0, rail_t, rail_h]);
}

module external_tower(side) {
    x0 = side < 0 ? -passed_outer_x : passed_rail_face;
    x1 = side < 0 ? -passed_rail_face : passed_outer_x;
    translate([x0, tower_y0, launch_base_t])
        cube([x1 - x0, tower_y1 - tower_y0, cradle_z - launch_base_t + tower_cradle_overlap]);
}

module tower_vent_relief(side) {
    x0 = side < 0 ? -passed_outer_x - 0.1 : passed_rail_face - 0.1;
    translate([x0, vent_y0, cradle_z - 0.1])
        cube([passed_outer_x - passed_rail_face + 0.2, vent_y1 - vent_y0, vent_z1 + 0.2]);
}

module v07_print_strut_cut() {
    // The cradle's own print strut would start in mid-air once raised; cut it
    // below the face-key ring.
    translate([-2.1, -3.1, cradle_z - 0.1])
        cube([4.2, 3.2, face_ring_lower_z - cradle_z]);
}

module mount_body() {
    difference() {
        union() {
            base_floor();
            lane_rail(lane_y0 - rail_t);
            lane_rail(lane_y1);
            external_tower(-1);
            external_tower(1);
            translate([0, 0, cradle_z]) coupon_base();
        }
        tower_vent_relief(-1);
        tower_vent_relief(1);
        v07_print_strut_cut();
    }
}

module loose_rear_door() {
    translate([60, 0, 0]) cube([16, 7.5, 2]);
}

if (part == "floor") {
    base_floor();
    lane_rail(lane_y0 - rail_t);
    lane_rail(lane_y1);
} else if (part == "floor_towers") {
    base_floor();
    lane_rail(lane_y0 - rail_t);
    lane_rail(lane_y1);
    external_tower(-1);
    external_tower(1);
} else if (part == "base") {
    mount_body();
} else if (part == "door") {
    loose_rear_door();
} else if (part == "check") {
    echo(["base_top_z", launch_base_t]);
    echo(["shaft_z", cradle_z + passed_cradle_axis_z]);
    echo(["lane_inner_faces_y", lane_y0, lane_y1]);
    echo(["left_lane_rail_box", lane_x0, lane_x1, lane_y0 - rail_t, lane_y0, launch_base_t, launch_base_t + rail_h]);
    echo(["right_lane_rail_box", lane_x0, lane_x1, lane_y1, lane_y1 + rail_t, launch_base_t, launch_base_t + rail_h]);
    echo(["left_tower_box", -passed_outer_x, -passed_rail_face, tower_y0, tower_y1, launch_base_t, cradle_z + tower_cradle_overlap]);
    echo(["right_tower_box", passed_rail_face, passed_outer_x, tower_y0, tower_y1, launch_base_t, cradle_z + tower_cradle_overlap]);
    echo(["cradle_low_box", -passed_outer_x, passed_outer_x, passed_y0, passed_bed_y1, cradle_z, cradle_z + 34]);
    echo(["v07_rail_faces_x", -passed_rail_face, passed_rail_face]);
    echo(["door_groove_faces_y", 58.2, 60.4]);
    echo(["base_print_box", base_x0, base_x1, base_y0, base_y1, 0, launch_base_t]);
    echo(["door_print_box", 60, 76, 0, 7.5, 0, 2]);
    echo(["support_plane", 0, 0]);
} else {
    mount_body();
    translate([0, 0, cradle_z]) sliding_door_installed();
}
