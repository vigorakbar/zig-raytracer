const std = @import("std");
const numbers = @import("./numbers.zig");

pub const Vec3 = @Vector(3, f32);
// alias for clarity
pub const Point3 = Vec3;

pub fn length_squared(v: Vec3) f32 {
    return @reduce(.Add, v * v);
}

pub fn length(v: Vec3) f32 {
    return @sqrt(length_squared(v));
}

pub fn near_zero(v: Vec3) bool {
    // return true if vec3 is close to zero in all dimension
    const s: f32 = 1e-8;
    return (@abs(v[0]) < s) and (@abs(v[1]) < s) and (@abs(v[2]) < s);
}

pub fn dot(a: Vec3, b: Vec3) f32 {
    return @reduce(.Add, a * b);
}

pub fn cross(a: Vec3, b: Vec3) Vec3 {
    return .{
        a[1] * b[2] - a[2] * b[1], // x
        a[2] * b[0] - a[0] * b[2], // y
        a[0] * b[1] - a[1] * b[0], // z
    };
}

pub fn splat_vec3(a: f32) Vec3 {
    return @as(Vec3, @splat(a));
}

pub fn unit_vec3(a: Vec3) Vec3 {
    return a / splat_vec3(length(a));
}

pub fn random(rng: std.Random) Vec3 {
    return .{
        rng.float(f32),
        rng.float(f32),
        rng.float(f32),
    };
}

pub fn random_range(rng: std.Random, min: f32, max: f32) Vec3 {
    return .{
        numbers.random_range(rng, min, max),
        numbers.random_range(rng, min, max),
        numbers.random_range(rng, min, max),
    };
}

pub fn random_unit_vec3(rng: std.Random) Vec3 {
    while (true) {
        // find point sample inside sphere from the cube bounding box with x y z in range (-1.0, 1.0)
        const sample = random_range(rng, -1.0, 1.0);
        const sample_len_squared = length_squared(sample);
        // ignore near 0 (very near center) point to avoid floating point precision error
        if (sample_len_squared > 1e-30 and sample_len_squared <= 1.0)
            return sample / splat_vec3(length(sample));
    }
}

pub fn random_on_hemisphere(rng: std.Random, normal: Vec3) Vec3 {
    const on_unit_sphere = random_unit_vec3(rng);
    if (dot(on_unit_sphere, normal) > 0.0) {
        return on_unit_sphere;
    } else {
        return splat_vec3(-1.0) * on_unit_sphere;
    }
}

pub fn random_in_unit_disk(rng: std.Random) Vec3 {
    while (true) {
        const p = Vec3{ numbers.random_range(rng, -1.0, 1.0), numbers.random_range(rng, -1.0, 1.0), 0.0 };
        if (length_squared(p) < 1.0) {
            return p;
        }
    }
}

pub fn reflect(vec: Vec3, normal: Vec3) Vec3 {
    return vec - splat_vec3(2.0) * splat_vec3(dot(vec, normal)) * normal;
}

pub fn refract(unit_vec: Vec3, normal: Vec3, eta_ratio: f32) Vec3 {
    const cos_theta: f32 = @min(dot(splat_vec3(-1.0) * unit_vec, normal), 1.0);
    const refracted_perpendi = splat_vec3(eta_ratio) * (unit_vec + splat_vec3(cos_theta) * normal);
    const refracted_parallel = splat_vec3(-1.0 * @sqrt(@abs(1.0 - length_squared(refracted_perpendi)))) * normal;
    return refracted_perpendi + refracted_parallel;
}
