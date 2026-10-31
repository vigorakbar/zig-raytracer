const std = @import("std");
const Ray = @import("Ray.zig");
const HittableList = @import("./HittableList.zig");
const Interval = @import("./Interval.zig");

const vec3 = @import("vec3.zig");
const color = @import("color.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Color = color.Color;
const splat_vec3 = vec3.splat_vec3;

// --- START ---

const Camera = @This();
prng: std.Random.DefaultPrng,

aspect_ratio: f32,
image_width: usize,
samples_per_pixel: usize,
pixel_sample_scales: f32,
max_depth: usize,
image_height: usize, // Rendered image height
camera_center: Point3, // Camera center
pixel00_location: Point3, // Location of pixel 0, 0
pixel_delta_u: Vec3, // Offset to pixel to the right
pixel_delta_v: Vec3, // Offset to pixel below

pub const InitOptions = struct {
    aspect_ratio: f32 = 16.0 / 9.0,
    image_width: usize = 400,
    samples_per_pixel: usize = 100,
    max_depth: usize = 50,
};
pub fn init(options: InitOptions) Camera {
    const width_f: f32 = @floatFromInt(options.image_width);
    var image_height: usize = @intFromFloat(width_f / options.aspect_ratio);
    image_height = if (image_height < 1) 1 else image_height;

    const focal_length: f32 = 1.0;
    const viewport_height: f32 = 2.0;
    const viewport_width: f32 = viewport_height *
        @as(f32, @floatFromInt(options.image_width)) /
        @as(f32, @floatFromInt(image_height));

    const camera_center: Point3 = .{ 0.0, 0.0, 0.0 };

    const viewport_u: Vec3 = .{ viewport_width, 0.0, 0.0 };
    const viewport_v: Vec3 = .{ 0.0, -viewport_height, 0.0 };

    const pixel_delta_u = viewport_u / splat_vec3(@floatFromInt(options.image_width));
    const pixel_delta_v = viewport_v / splat_vec3(@floatFromInt(image_height));

    // world coordinate of viewport point
    const viewport_upper_left: Vec3 = camera_center - Vec3{ 0.0, 0.0, focal_length } - (viewport_u / splat_vec3(2.0)) - viewport_v / splat_vec3(2.0);
    const pixel00_location = viewport_upper_left + (pixel_delta_u / splat_vec3(2.0)) + (pixel_delta_v / splat_vec3(2.0));

    const pixel_sample_scales: f32 = 1.0 / @as(f32, @floatFromInt(options.samples_per_pixel));

    return .{ // init camera
        .aspect_ratio = options.aspect_ratio,
        .image_width = options.image_width,
        .samples_per_pixel = options.samples_per_pixel,
        .max_depth = options.max_depth,
        .camera_center = camera_center,
        .image_height = image_height,
        .pixel00_location = pixel00_location,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
        .pixel_sample_scales = pixel_sample_scales,
        .prng = .init(0),
    };
}

pub fn render(self: *Camera, io: std.Io, world: *HittableList) !void {
    const rng = self.prng.random();

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
            var pixel_color: Color = .{ 0.0, 0.0, 0.0 };
            for (0..self.samples_per_pixel) |_| {
                const r = self.get_ray(rng, i, j);
                pixel_color += ray_color(&r, self.max_depth, world, rng);
            }

            try color.write_colors(splat_vec3(self.pixel_sample_scales) * pixel_color, writer_interface);
        }
    }
    try writer_interface.flush();

    try log.print("\nDone!\n", .{});
    try log.flush();
}

fn ray_color(r: *const Ray, depth: usize, world: *HittableList, rng: std.Random) Color {
    if (depth <= 0) return Color{ 0.0, 0.0, 0.0 };

    if (world.hit(r, Interval{ .min = 0.001, .max = std.math.inf(f32) })) |rec| {
        const direction = rec.normal + vec3.random_unit_vec3(rng);

        const bounced_ray: Ray = .{
            .origin = rec.point,
            .direction = direction,
        };
        return splat_vec3(0.5) * ray_color(&bounced_ray, depth - 1, world, rng);
    }

    const unit_direction = vec3.unit_vec3(r.direction);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return splat_vec3(1.0 - a) * Color{ 1.0, 1.0, 1.0 } + splat_vec3(a) * Color{ 0.5, 0.7, 1.0 };
}

fn get_ray(self: *Camera, rng: std.Random, i: usize, j: usize) Ray {
    // Construct a camera ray originating from the origin and directed at randomly sampled
    // point around the pixel location i, j.
    const offset = sample_square(rng);
    const pixel_sample = self.pixel00_location +
        (splat_vec3((@as(f32, @floatFromInt(i)) + offset[0])) * self.pixel_delta_u) +
        (splat_vec3((@as(f32, @floatFromInt(j)) + offset[1])) * self.pixel_delta_v);
    const ray_origin = self.camera_center;
    const ray_direction = pixel_sample - ray_origin;

    return .{ .origin = ray_origin, .direction = ray_direction };
}

fn sample_square(rng: std.Random) Vec3 {
    // sample square coord between -0.5 and +0.5 in x and y
    return .{ rng.float(f32) - 0.5, rng.float(f32) - 0.5, 0.0 };
}
