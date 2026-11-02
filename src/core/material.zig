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
    fuzz: f32,

    pub fn scatter(self: *const Metal, ray: *const Ray, rec: *const HitRecord, rng: std.Random) ?Scatter {
        var reflected = vec3.reflect(ray.direction, rec.normal);
        reflected = vec3.unit_vec3(reflected) + (vec3.splat_vec3(self.fuzz) * vec3.random_unit_vec3(rng));

        const scaterred = Ray{ .origin = rec.point, .direction = reflected };

        if (vec3.dot(scaterred.direction, rec.normal) <= 0.0) {
            return null;
        }

        return Scatter{
            .scattered = scaterred,
            .attenuation = self.albedo,
        };
    }
};

pub const Dielectric = struct {
    refraction_index: f32,

    pub fn scatter(self: *const Dielectric, ray: *const Ray, rec: *const HitRecord) ?Scatter {
        const refraction_index = if (rec.front_face) 1.0 / self.refraction_index else self.refraction_index;

        const unit_direction = vec3.unit_vec3(ray.direction);
        const cos_theta: f32 = @min(vec3.dot(vec3.splat_vec3(-1.0) * unit_direction, rec.normal), 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);

        const cannot_refract = refraction_index * sin_theta > 1.0;
        var refracted: vec3.Vec3 = undefined;
        if (cannot_refract) {
            refracted = vec3.reflect(unit_direction, rec.normal);
        } else {
            refracted = vec3.refract(unit_direction, rec.normal, refraction_index);
        }

        return Scatter{
            .attenuation = Color{ 1.0, 1.0, 1.0 },
            .scattered = Ray{
                .origin = rec.point,
                .direction = refracted,
            },
        };
    }
};

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    dielectric: Dielectric,

    pub fn scatter(self: *const Material, ray: *const Ray, rec: *const HitRecord, rng: std.Random) ?Scatter {
        return switch (self.*) {
            .lambertian => |s| s.scatter(ray, rec, rng),
            .metal => |s| s.scatter(ray, rec, rng),
            .dielectric => |s| s.scatter(ray, rec),
        };
    }
};
