const Hittable = @import("./hittable.zig").Hittable;
const HitRecord = @import("./hittable.zig").HitRecord;
const Interval = @import("./Interval.zig");

const std = @import("std");
const Ray = @import("./Ray.zig");

const HittableList = @This();

objects: std.ArrayList(Hittable) = .empty,

pub fn add(self: *HittableList, gpa: std.mem.Allocator, item: Hittable) !void {
    try self.objects.append(gpa, item);
}

pub fn deinit(self: *HittableList, gpa: std.mem.Allocator) void {
    self.objects.deinit(gpa);
}

pub fn hit(self: *HittableList, ray: *const Ray, ray_t: Interval) ?HitRecord {
    var closest_so_far = ray_t.max;
    var result: ?HitRecord = null;

    for (self.objects.items) |item| {
        if (item.hit(ray, Interval{ .min = ray_t.min, .max = closest_so_far })) |rec| {
            closest_so_far = rec.t;
            result = rec;
        }
    }

    return result;
}
