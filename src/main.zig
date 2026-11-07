const std = @import("std");
const Ray = @import("core/Ray.zig");
const HittableList = @import("./core/HittableList.zig");
const Interval = @import("./core/Interval.zig");
const Camera = @import("./core/Camera.zig");
const material = @import("./core/material.zig");
const numbers = @import("./core/numbers.zig");

const vec3 = @import("core/vec3.zig");
const color = @import("core/color.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Color = color.Color;
const splat_vec3 = vec3.splat_vec3;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // World
    var debug_alloc: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_alloc.deinit();
    const gpa = debug_alloc.allocator();

    var world: HittableList = .{};
    defer world.deinit(gpa);

    var pnrg = std.Random.DefaultPrng.init(1);
    var rng = pnrg.random();

    const material_ground: material.Material = .{ .lambertian = .{
        .albedo = .{ 0.5, 0.5, 0.5 },
    } };
    try world.add(gpa, .{ .sphere = .{
        .center = .{ 0.0, -1000, 0.0 },
        .radius = 1000.0,
        .material = material_ground,
    } });

    var a: i32 = -11;
    while (a < 11) : (a += 1) {
        var b: i32 = -11;
        while (b < 11) : (b += 1) {
            const aFloat = @as(f32, @floatFromInt(a));
            const bFloat = @as(f32, @floatFromInt(b));

            const choose_mat = rng.float(f32);
            const center: Point3 = .{ aFloat + 0.9 * rng.float(f32), 0.2, bFloat + 0.9 * rng.float(f32) };

            if (vec3.length(center - Point3{ 4.0, 0.2, 0.0 }) > 0.9) {
                var material_sphere: material.Material = undefined;

                if (choose_mat < 0.8) {
                    // diffuse
                    const albedo: Color = vec3.random(rng) * vec3.random(rng);
                    material_sphere = .{ .lambertian = .{
                        .albedo = albedo,
                    } };
                    try world.add(gpa, .{ .sphere = .{
                        .center = center,
                        .radius = 0.2,
                        .material = material_sphere,
                    } });
                } else if (choose_mat < 0.95) {
                    // metal
                    const albedo: Color = vec3.random_range(rng, 0.5, 1.0);
                    const fuzz = numbers.random_range(rng, 0.0, 0.5);
                    material_sphere = .{ .metal = .{
                        .albedo = albedo,
                        .fuzz = fuzz,
                    } };
                    try world.add(gpa, .{ .sphere = .{
                        .center = center,
                        .radius = 0.2,
                        .material = material_sphere,
                    } });
                } else {
                    // glass
                    material_sphere = .{ .dielectric = .{
                        .refraction_index = 1.5,
                    } };
                    try world.add(gpa, .{ .sphere = .{
                        .center = center,
                        .radius = 0.2,
                        .material = material_sphere,
                    } });
                }
            }
        }
    }

    const material_1: material.Material = .{ .dielectric = .{
        .refraction_index = 1.5,
    } };
    try world.add(gpa, .{ .sphere = .{
        .center = .{ 0.0, 1.0, 0.0 },
        .radius = 1.0,
        .material = material_1,
    } });

    const material_2: material.Material = .{ .lambertian = .{
        .albedo = .{ 0.4, 0.2, 0.1 },
    } };
    try world.add(gpa, .{ .sphere = .{
        .center = .{ -4.0, 1.0, 0.0 },
        .radius = 1.0,
        .material = material_2,
    } });

    const material_3: material.Material = .{ .metal = .{
        .albedo = .{ 0.7, 0.6, 0.5 },
        .fuzz = 0.0,
    } };
    try world.add(gpa, .{ .sphere = .{
        .center = .{ 4.0, 1.0, 0.0 },
        .radius = 1.0,
        .material = material_3,
    } });

    // Camera
    var cam: Camera = .init(.{
        .image_width = 1200,

        // change to 500 for sharper image. But it will take a while to render
        .samples_per_pixel = 10,

        .vert_fov = 20.0,
        .look_from = Point3{ 13.0, 2.0, 3.0 },
        .look_at = Point3{ 0.0, 0.0, 0.0 },
        .view_up = Vec3{ 0.0, 1.0, 0.0 },

        .defocus_angle = 0.6,
        .focus_dist = 10.0,
    });

    try cam.render(io, &world);
}
