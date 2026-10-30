const std = @import("std");
const vec3 = @import("./vec3.zig");
const Interval = @import("./Interval.zig");

pub const Color = vec3.Vec3;

// write pixel color component
pub fn write_colors(c: Color, out: *std.Io.Writer) !void {
    const intensity: Interval = .{ .min = 0.000, .max = 0.999 };

    const r: u8 = @intFromFloat(intensity.clamp(c[0]) * 256.0);
    const g: u8 = @intFromFloat(intensity.clamp(c[1]) * 256.0);
    const b: u8 = @intFromFloat(intensity.clamp(c[2]) * 256.0);

    try out.print("{d} {d} {d}\n", .{ r, g, b });
}
