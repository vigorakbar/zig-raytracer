const vec3 = @import("./vec3.zig");
const std = @import("std");

pub const Color = vec3.Vec3;

// write pixel color component
pub fn write_colors(c: Color, out: *std.Io.Writer) !void {
    const r: u8 = @intFromFloat(c[0] * 255.999);
    const g: u8 = @intFromFloat(c[1] * 255.999);
    const b: u8 = @intFromFloat(c[2] * 255.999);

    try out.print("{d} {d} {d}\n", .{ r, g, b });
}
