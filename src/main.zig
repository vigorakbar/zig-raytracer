const std = @import("std");
const vec3 = @import("utils/vec3.zig");
const color = @import("utils/color.zig");

const Color = color.Color;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const image_width: usize = 256;
    const image_height: usize = 256;

    const file = try std.Io.Dir.cwd().createFile(io, "output.ppm", .{});
    defer file.close(io);

    var buf: [8192]u8 = undefined;
    var file_writer = file.writer(io, &buf);
    const writer_interface = &file_writer.interface;

    // == std err writer for console debugging ==
    var stderr_buf: [1024]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buf);
    const log = &stderr_writer.interface;
    // == ==

    // PPM header
    try writer_interface.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    const width_f: f32 = @floatFromInt(image_width - 1);
    const height_f: f32 = @floatFromInt(image_height - 1);
    for (0..image_height) |j| {
        try log.print("\rProgress: {d}/{d}", .{ j + 1, image_height });
        try log.flush();

        for (0..image_width) |i| {
            const pixel_color: Color = .{
                @as(f32, @floatFromInt(i)) / @as(f32, width_f), // r
                @as(f32, @floatFromInt(j)) / @as(f32, height_f), // g
                0.5, // b
            };

            try color.write_colors(pixel_color, writer_interface);
        }
    }
    try writer_interface.flush();

    try log.print("\nDone!\n", .{});
    try log.flush();
}
