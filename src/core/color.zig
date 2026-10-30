const std = @import("std");
const vec3 = @import("./vec3.zig");
const Interval = @import("./Interval.zig");

pub const Color = vec3.Vec3;

fn linnear_to_gamma(linear_component: f32) f32 {
    if (linear_component > 0.0) return @sqrt(linear_component);

    return 0;
}

// write pixel color component
pub fn write_colors(c: Color, out: *std.Io.Writer) !void {
    const intensity: Interval = .{ .min = 0.000, .max = 0.999 };

    const r_gamma: f32 = linnear_to_gamma(c[0]);
    const g_gamma: f32 = linnear_to_gamma(c[1]);
    const b_gamma: f32 = linnear_to_gamma(c[2]);

    const r_byte: u8 = @intFromFloat(intensity.clamp(r_gamma) * 256.0);
    const g_byte: u8 = @intFromFloat(intensity.clamp(g_gamma) * 256.0);
    const b_byte: u8 = @intFromFloat(intensity.clamp(b_gamma) * 256.0);

    try out.print("{d} {d} {d}\n", .{ r_byte, g_byte, b_byte });
}
