const Ray = @import("./Ray.zig");
const vec3 = @import("./vec3.zig");
const Interval = @import("./Interval.zig");

const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const splat_vec3 = vec3.splat_vec3;

pub const HitRecord = struct {
    point: Point3,
    normal: Vec3,
    t: f32,
    front_face: bool,
};

pub const Sphere = struct {
    center: Point3,
    radius: f32,

    pub fn hit(self: *const Sphere, r: *const Ray, ray_t: Interval) ?HitRecord {
        const originToCenter = self.center - r.origin;
        const a = vec3.length_squared(r.direction);
        const h = vec3.dot(r.direction, originToCenter);
        const c = vec3.length_squared(originToCenter) - (self.radius * self.radius);
        const discriminant = (h * h) - (a * c);

        if (discriminant < 0) {
            return null;
        }

        const sqrtd = @sqrt(discriminant);
        var root = (h - sqrtd) / a;
        if (!ray_t.surrounds(root)) {
            root = (h + sqrtd) / a;
            if (!ray_t.surrounds(root)) {
                return null;
            }
        }

        const point = r.at(root);
        const outward_normal = (point - self.center) / splat_vec3(self.radius);
        const front_face = vec3.dot(r.direction, outward_normal) < 0; // detect if ray is inside or outside the sphere
        return .{
            .t = root,
            .point = point,
            .normal = if (front_face) outward_normal else -outward_normal,
            .front_face = front_face,
        };
    }
};

pub const Hittable = union(enum) {
    sphere: Sphere,

    pub fn hit(self: *const Hittable, r: *const Ray, ray_t: Interval) ?HitRecord {
        return switch (self.*) {
            .sphere => |s| s.hit(r, ray_t),
        };
    }
};
