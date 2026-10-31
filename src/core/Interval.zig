const std = @import("std");

const Interval = @This();

min: f32,
max: f32,

pub const empty: Interval = .{ .min = std.math.inf(f32), .max = -std.math.inf(f32) };
pub const universe: Interval = .{ .min = -std.math.inf(f32), .max = std.math.inf(f32) };

pub fn size(self: *const Interval) f32 {
    return self.max - self.min;
}
pub fn contains(self: *const Interval, val: f32) bool {
    return val >= self.min and val <= self.max;
}
pub fn surrounds(self: *const Interval, val: f32) bool {
    return val > self.min and val < self.max;
}
pub fn clamp(self: *const Interval, val: f32) f32 {
    if (val < self.min) return self.min;
    if (val > self.max) return self.max;
    return val;
}
