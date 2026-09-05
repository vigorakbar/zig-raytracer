const vec3 = @import("vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

const Self = @This();

origin: Point3,
direction: Vec3,

fn at(self: *Self, t: f32) Point3 {
    return self.origin + t * self.direction;
}
