const std = @import("std");

const Ray = @import("./Ray.zig");
const Color = @import("./color.zig").Color;
const HitRecord = @import("./hittable.zig").HitRecord;

const vec3 = @import("./vec3.zig");

pub const Scatter = struct {
    scattered: Ray,
    attenuation: Color,
};

pub const Lambertian = struct {
    albedo: Color,

    pub fn scatter(self: *const Lambertian, ray: *const Ray, rec: *const HitRecord, rng: std.Random) ?Scatter {
        _ = ray;

        var scatter_direction = rec.normal + vec3.random_unit_vec3(rng);

        if (vec3.near_zero(scatter_direction)) {
            scatter_direction = rec.normal;
        }

        return Scatter{
            .scattered = Ray{ .origin = rec.point, .direction = scatter_direction },
            .attenuation = self.albedo,
        };
    }
};

pub const Metal = struct {
    albedo: Color,

    pub fn scatter(self: *const Metal, ray: *const Ray, rec: *const HitRecord, rng: std.Random) ?Scatter {
        _ = rng;

        const reflected = vec3.reflect(ray.direction, rec.normal);

        return Scatter{
            .scattered = Ray{ .origin = rec.point, .direction = reflected },
            .attenuation = self.albedo,
        };
    }
};

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,

    pub fn scatter(self: *const Material, ray: *const Ray, rec: *const HitRecord, rng: std.Random) ?Scatter {
        return switch (self.*) {
            .lambertian => |s| s.scatter(ray, rec, rng),
            .metal => |s| s.scatter(ray, rec, rng),
        };
    }
};
