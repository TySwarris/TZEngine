const math = @import("zmath");
const std = @import("std");

pub const SceneObject = struct {
    localMatrix: math.,
    children: std.ArrayList(*SceneObject),
};
