const std = @import("std");
const Ray = @import("Ray.zig");
const HittableList = @import("./hittable_list.zig").HittableList;
const Interval = @import("./Interval.zig");

const vec3 = @import("vec3.zig");
const color = @import("color.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Color = color.Color;
const splat_vec3 = vec3.splat_vec3;

// --- START ---

const Self = @This();

aspect_ratio: f32,
image_width: usize,
image_height: usize, // Rendered image height
camera_center: Point3, // Camera center
pixel00_location: Point3, // Location of pixel 0, 0
pixel_delta_u: Vec3, // Offset to pixel to the right
pixel_delta_v: Vec3, // Offset to pixel below

pub fn init(aspect_ratio: f32, image_width: usize) Self {
    const width_f: f32 = @floatFromInt(image_width);
    var image_height: usize = @intFromFloat(width_f / aspect_ratio);
    image_height = if (image_height < 1) 1 else image_height;

    const focal_length: f32 = 1.0;
    const viewport_height: f32 = 2.0;
    const viewport_width: f32 = viewport_height *
        @as(f32, @floatFromInt(image_width)) /
        @as(f32, @floatFromInt(image_height));

    const camera_center: Point3 = .{ 0.0, 0.0, 0.0 };

    const viewport_u: Vec3 = .{ viewport_width, 0.0, 0.0 };
    const viewport_v: Vec3 = .{ 0.0, -viewport_height, 0.0 };

    const pixel_delta_u = viewport_u / splat_vec3(@floatFromInt(image_width));
    const pixel_delta_v = viewport_v / splat_vec3(@floatFromInt(image_height));

    // world coordinate of viewport point
    const viewport_upper_left: Vec3 = camera_center - Vec3{ 0.0, 0.0, focal_length } - (viewport_u / splat_vec3(2.0)) - viewport_v / splat_vec3(2.0);
    const pixel00_location = viewport_upper_left + (pixel_delta_u / splat_vec3(2.0)) + (pixel_delta_v / splat_vec3(2.0));

    return .{ // init camera
        .aspect_ratio = aspect_ratio,
        .image_width = image_width,
        .camera_center = camera_center,
        .image_height = image_height,
        .pixel00_location = pixel00_location,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
    };
}

pub fn render(self: *Self, io: std.Io, world: *HittableList) !void {
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
    try writer_interface.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });

    for (0..self.image_height) |j| {
        try log.print("\rProgress: {d}/{d}", .{ j + 1, self.image_height });
        try log.flush();

        for (0..self.image_width) |i| {
            const pixel_center: Vec3 = self.pixel00_location +
                (splat_vec3(@floatFromInt(i)) * self.pixel_delta_u) +
                (splat_vec3(@floatFromInt(j)) * self.pixel_delta_v);
            const ray_direction: Vec3 = pixel_center - self.camera_center;
            const r: Ray = .{ .origin = self.camera_center, .direction = ray_direction };

            const pixel_color: Color = ray_color(&r, world);

            try color.write_colors(pixel_color, writer_interface);
        }
    }
    try writer_interface.flush();

    try log.print("\nDone!\n", .{});
    try log.flush();
}

fn ray_color(r: *const Ray, world: *HittableList) Color {
    if (world.hit(r, Interval{ .min = 0.0, .max = std.math.inf(f32) })) |rec| {
        return splat_vec3(0.5) * (rec.normal + Color{ 1.0, 1.0, 1.0 });
    }

    const unit_direction = vec3.unit_vec3(r.direction);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return splat_vec3(1.0 - a) * Color{ 1.0, 1.0, 1.0 } + splat_vec3(a) * Color{ 0.5, 0.7, 1.0 };
}
