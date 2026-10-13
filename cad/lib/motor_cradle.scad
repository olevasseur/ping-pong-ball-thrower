// RS550 motor cradle. Units: mm.
// Open bed for the 38 mm motor envelope, two 2 mm face pins that key into the
// motor's front mounting holes (stops it turning), side vent slots, and a
// removable sliding rear door. Used by ../launcher_base.scad; can also be
// printed alone as a bench holder (part = "print").

$fn = 96;
part = "print"; // "print" puts bed and separate door on plate; "assembly" installs door.

motor_envelope_d = 38;
motor_envelope_r = motor_envelope_d / 2;
sheet_clearance = 0.5;
cavity_r = motor_envelope_r + sheet_clearance; // Actual rail faces: +/-19.5.

// Face-key pins: 25.5 mm apart, matching the RS550 front mounting holes.
hole_inner_span = 23;
hole_mouth_d = 2.5;
pin_d = 2;
pin_h = 4;
pin_tip_chamfer = 0.3;
pin_overlap_behind_face = 0.1;
pin_r = (hole_inner_span + hole_mouth_d) / 2;
boss_od = 13.25;
ring_id = 14.25;
ring_od = 18.5;
deck_t = 3;
pad_d = 5;
arm_w = 4;

// Bed length: 58 mm bed + 3 mm rear door receiver; total -3..61 = 64 mm.
coupon_y0 = -3;
old_bed_y1 = 55;
semicircle_extension = 3;
semi_bed_y1 = old_bed_y1 + semicircle_extension; // 58
rear_receiver_t = 3;
coupon_y1 = semi_bed_y1 + rear_receiver_t;       // -3..61 = 64
seated_motor_rear_y = semi_bed_y1;
receiver_join_overlap = 0.1;
rear_receiver_y0 = semi_bed_y1 - receiver_join_overlap;
rear_receiver_l = rear_receiver_t + receiver_join_overlap;

// Side vent slots line up with the motor's rear ventilation openings.
physical_vent_y1 = old_bed_y1 - 9; // 46
physical_vent_y0 = physical_vent_y1 - 6; // 40
vent_slot_y0 = physical_vent_y0 - 1;
vent_slot_l = 8;
base_t = 4;
vent_slot_z_top = 12;

// Rear support arms and two small posts under the motor can.
rear_support_y0 = 47;
rear_support_l = 11;
post_y0 = 48.5;
post_l = 5;
post_d = 1.4;
post_center_r = 17.95;
post_angle = 22.2;
post_lower_z = 1;

coupon_w = 52;
axis_z = base_t + cavity_r;
rail_h = 34;
side_wall_t = coupon_w / 2 - cavity_r; // Actual vertical-wall thickness 6.5 mm.

// Sliding rear door: 2.0 mm door in a 2.2 mm groove.
door_t = 2.0;
door_groove_t = 2.2;
door_w = 16;
door_h = 7.5; // Taller than the rear posts (about 6.6 mm top).
door_tab_w = 2;
door_receiver_w = 4;
door_receiver_h = 9;
door_receiver_x = [-10, 6];
door_groove_y0 = seated_motor_rear_y + 0.2;

assert(hole_inner_span + hole_mouth_d == 25.5);
assert(pin_d == 2 && pin_h == 4 && pin_r == 12.75);
assert(ring_id >= boss_od + 1);
assert(2 * cavity_r >= motor_envelope_d + 2 * sheet_clearance);
assert(coupon_y1 - coupon_y0 == 64);
assert(seated_motor_rear_y == old_bed_y1 + 3);
assert(door_groove_t == door_t + 0.2);
assert(door_h > axis_z - post_center_r - post_lower_z + post_d / 2);
assert(vent_slot_z_top > base_t - 1);
assert(rear_support_y0 + rear_support_l == semi_bed_y1);

module y_cylinder(d, h, center) {
    translate(center) rotate([-90, 0, 0]) cylinder(d = d, h = h);
}

module horizontal_cylinder(radius, y0, length) {
    translate([0, y0 - 0.1, axis_z])
        rotate([-90, 0, 0]) cylinder(r = radius, h = length + 0.2);
}

module outer_rail(side) {
    x0 = side < 0 ? -coupon_w / 2 : cavity_r;
    x1 = side < 0 ? -cavity_r : coupon_w / 2;
    difference() {
        translate([x0, coupon_y0, 0]) cube([x1 - x0, semi_bed_y1 - coupon_y0, rail_h]);
        horizontal_cylinder(cavity_r, coupon_y0, semi_bed_y1 - coupon_y0);
    }
}

module front_gusset(side) {
    x = side * pin_r;
    hull() {
        translate([side < 0 ? -20 : 16, coupon_y0, 0]) cube([4, deck_t - 0.1, base_t]);
        y_cylinder(pad_d, deck_t - 0.1, [x, coupon_y0, axis_z]);
    }
}

module face_pin(center_x) {
    body_h = pin_h - pin_tip_chamfer + pin_overlap_behind_face;
    y_cylinder(pin_d, body_h, [center_x, -pin_overlap_behind_face, axis_z]);
    translate([center_x, body_h - pin_overlap_behind_face, axis_z])
        rotate([-90, 0, 0]) cylinder(d1 = pin_d, d2 = pin_d - 2 * pin_tip_chamfer,
                                     h = pin_tip_chamfer);
}

module face_key() {
    difference() {
        union() {
            y_cylinder(ring_od, deck_t, [0, -deck_t, axis_z]);
            for (x = [-pin_r, pin_r]) y_cylinder(pad_d, deck_t, [x, -deck_t, axis_z]);
            for (side = [-1, 1]) hull() {
                y_cylinder(arm_w, deck_t, [side * ring_od / 2, -deck_t, axis_z]);
                y_cylinder(arm_w, deck_t, [side * pin_r, -deck_t, axis_z]);
            }
        }
        y_cylinder(ring_id, deck_t + 0.2, [0, -deck_t - 0.1, axis_z]);
    }
    for (x = [-pin_r, pin_r]) face_pin(x);
}

module rear_support_arm(side) {
    x0 = side < 0 ? -20 : 6;
    x1 = side < 0 ? -6 : 20;
    difference() {
        translate([x0, rear_support_y0, 0]) cube([x1 - x0, rear_support_l, rail_h]);
        horizontal_cylinder(cavity_r, rear_support_y0, rear_support_l);
    }
}

module lowered_bottom_post(angle) {
    anchor_r = cavity_r + post_d / 2 - 0.1;
    hull() {
        y_cylinder(post_d, post_l,
                   [post_center_r * cos(angle), post_y0,
                    axis_z + post_center_r * sin(angle) - post_lower_z]);
        y_cylinder(post_d, post_l,
                   [anchor_r * cos(angle), post_y0,
                    axis_z + anchor_r * sin(angle) - post_lower_z]);
    }
}

module lower_crossbar() {
    translate([-coupon_w / 2, 20, 0]) cube([coupon_w, 4, base_t]);
}

module door_receivers() {
    // Independent side blocks behind the bed; no fixed wall joins them.
    for (x = door_receiver_x)
        difference() {
            translate([x, rear_receiver_y0, 0])
                cube([door_receiver_w, rear_receiver_l, door_receiver_h]);
            // Through-top channel follows the door edge; the outer lip stays
            // connected to the bed.
            translate([x < 0 ? -door_w / 2 - 0.1 : door_w / 2 - door_tab_w - 0.1,
                       door_groove_y0, -0.1])
                cube([door_tab_w + 0.2, door_groove_t, door_receiver_h + 0.2]);
        }
}

module sliding_door_local() {
    translate([-door_w / 2, -door_t / 2, 0]) cube([door_w, door_t, door_h]);
}

module sliding_door_installed() {
    translate([0, door_groove_y0 + door_groove_t / 2, 0]) sliding_door_local();
}

module sliding_door_print() {
    // Same door, laid flat beside the cradle for printing.
    translate([31, 3, 0]) cube([door_w, door_h, door_t]);
}

module vertical_wall_vent_slots() {
    // Side openings through the 6.5 mm side walls.
    translate([-coupon_w / 2 - 0.1, vent_slot_y0, -0.1])
        cube([side_wall_t + 0.2, vent_slot_l, vent_slot_z_top + 0.1]);
    translate([cavity_r - 0.1, vent_slot_y0, -0.1])
        cube([side_wall_t + 0.2, vent_slot_l, vent_slot_z_top + 0.1]);
}

module coupon_base() {
    difference() {
        union() {
            outer_rail(-1);
            outer_rail(1);
            front_gusset(-1);
            front_gusset(1);
            face_key();
            rear_support_arm(-1);
            rear_support_arm(1);
            lowered_bottom_post(-90 - post_angle);
            lowered_bottom_post(-90 + post_angle);
            lower_crossbar();
            door_receivers();
            // Print strut under the face-key ring (cut away in the launcher base).
            translate([-2, -deck_t, 0]) cube([4, deck_t - 0.1, axis_z - ring_od / 2 + 0.3]);
        }
        vertical_wall_vent_slots();
        // Original open middle remains open.
        translate([-6, 45, -0.1]) cube([12, 6, rail_h + 0.2]);
    }
}

if (part == "assembly") {
    coupon_base();
    sliding_door_installed();
} else {
    coupon_base();
    sliding_door_print();
}
