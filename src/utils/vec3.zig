pub const Vec3 = @Vector(3, f32);
// alias for clarity
pub const Point3 = Vec3;

pub fn length(v: Vec3) f32 {
    return @sqrt(@reduce(.Add, v * v));
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
