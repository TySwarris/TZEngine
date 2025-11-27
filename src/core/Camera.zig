const std = @import("std");

const SceneObject = @import("SceneObject.zig").SceneObject;
const math = @import("zmath");

pub const Camera = struct {
    sceneObject: SceneObject,
    distance: f32,
    angle: math.Vec,

    pub fn init(allocator: std.mem.Allocator, distance: f32) Camera {
        return .{
            .sceneObject = SceneObject.init(allocator),
            .distance = distance,
            .angle = math.f32x4(0, 0, 0, 0),
        };
    }

    pub fn getViewMatrix(self: *const Camera) math.Mat {
        return math.inverse(self.sceneObject.getWorldMatrix());
    }

    pub fn getCameraMatrix(self: *const Camera) math.Mat {
        return self.sceneObject.getWorldMatrix();
    }
};
