const std = @import("std");
const Ray = @import("core/Ray.zig");
const HittableList = @import("./core/HittableList.zig");
const Interval = @import("./core/Interval.zig");
const Camera = @import("./core/Camera.zig");

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

    try world.add(gpa, .{ .sphere = .{ .center = .{ 0.0, 0.0, -1.0 }, .radius = 0.5 } });

    try world.add(gpa, .{ .sphere = .{
        .center = .{ 0.0, -100.5, -1.0 },
        .radius = 100.0,
    } });

    // Camera
    var cam: Camera = .init(.{});

    try cam.render(io, &world);
}
