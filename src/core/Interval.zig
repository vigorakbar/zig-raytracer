const std = @import("std");

const Self = @This();

min: f32,
max: f32,

pub const empty: Self = .{ .min = std.math.inf(f32), .max = -std.math.inf(f32) };
pub const universe: Self = .{ .min = -std.math.inf(f32), .max = std.math.inf(f32) };

pub fn size(self: *const Self) f32 {
    return self.max - self.min;
}
pub fn contains(self: *const Self, val: f32) bool {
    return val >= self.min and val <= self.max;
}
pub fn surrounds(self: *const Self, val: f32) bool {
    return val > self.min and val < self.max;
}
pub fn clamp(self: *const Self, val: f32) f32 {
    if (val < self.min) return self.min;
    if (val > self.max) return self.max;
    return val;
}
