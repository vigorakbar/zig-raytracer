const vec3 = @import("vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

const Ray = @This();

origin: Point3,
direction: Vec3,

pub fn at(self: *const Ray, t: f32) Point3 {
    return self.origin + vec3.splat_vec3(t) * self.direction;
}
