const std = @import("std");
const Ray = @import("utils/Ray.zig");

const vec3 = @import("utils/vec3.zig");
const color = @import("utils/color.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Color = color.Color;
const splat_vec3 = vec3.splat_vec3;

// 𝑎𝑥2 + 𝑏𝑥 + 𝑐 =0
// solve using quadratic formula to find ray-sphere intersection
// 𝑎 = 𝐝⋅𝐝
// 𝑏 = −2𝐝⋅(originToCenter)
// 𝑐 = (originToCenter)⋅(originToCenter) − 𝑟2
fn hit_sphere(center: Point3, radius: f32, r: Ray) bool {
    const originToCenter = center - r.origin;
    const a = vec3.dot(r.direction, r.direction);
    const b = -2.0 * vec3.dot(r.direction, originToCenter);
    const c = vec3.dot(originToCenter, originToCenter) - radius * radius;
    const discriminant = b * b - 4 * a * c;

    return discriminant >= 0;
}

fn ray_color(r: Ray) Color {
    if (hit_sphere(Point3{ 0.0, 0.0, -1.0 }, 0.5, r)) {
        return Color{ 1.0, 0.0, 0.0 };
    }
    const unit_direction = vec3.unit_vec3(r.direction);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return splat_vec3(1.0 - a) * Color{ 1.0, 1.0, 1.0 } + splat_vec3(a) * Color{ 0.5, 0.7, 1.0 };
}
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const aspect_ratio: f32 = 16.0 / 9.0;
    const image_width: usize = 400;
    var image_height: usize = @intFromFloat(image_width / aspect_ratio);
    image_height = if (image_height < 1) 1 else image_height;

    const focal_length: f32 = 1.0;
    const viewport_height: f32 = 2.0;
    const viewport_width: f32 = viewport_height *
        @as(f32, @floatFromInt(image_width)) /
        @as(f32, @floatFromInt(image_height));
    const camera_center: Point3 = .{ 0.0, 0.0, 0.0 };

    const viewport_u: Vec3 = .{ viewport_width, 0.0, 0.0 };
    const viewport_v: Vec3 = .{ 0.0, -viewport_height, 0.0 };

    const pixel_delta_u: Vec3 = viewport_u / splat_vec3(@floatFromInt(image_width));
    const pixel_delta_v: Vec3 = viewport_v / splat_vec3(@floatFromInt(image_height));

    // world coordinate of viewport point
    const viewport_upper_left: Vec3 = camera_center + Vec3{ 0.0, 0.0, focal_length } - (viewport_u / splat_vec3(2.0)) - viewport_v / splat_vec3(2.0);
    const pixel00_location: Vec3 = viewport_upper_left + (pixel_delta_u / splat_vec3(2.0)) + (pixel_delta_v / splat_vec3(2.0));

    const file = try std.Io.Dir.cwd().createFile(io, "output.ppm", .{});
    defer file.close(io);

    var buf: [8192]u8 = undefined;
    var file_writer = file.writer(io, &buf);
    const writer_interface = &file_writer.interface;

    // std err writer for console debugging
    var stderr_buf: [1024]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buf);
    const log = &stderr_writer.interface;

    // PPM header
    try writer_interface.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        try log.print("\rProgress: {d}/{d}", .{ j + 1, image_height });
        try log.flush();

        for (0..image_width) |i| {
            const pixel_center: Vec3 = pixel00_location +
                (splat_vec3(@floatFromInt(i)) * pixel_delta_u) +
                (splat_vec3(@floatFromInt(j)) * pixel_delta_v);
            const ray_direction: Vec3 = pixel_center - camera_center;
            const r: Ray = .{ .origin = camera_center, .direction = ray_direction };

            const pixel_color: Color = ray_color(r);

            try color.write_colors(pixel_color, writer_interface);
        }
    }
    try writer_interface.flush();

    try log.print("\nDone!\n", .{});
    try log.flush();
}
