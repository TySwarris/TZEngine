const std = @import("std");
const math = @import("zmath");
const Camera = @import("../../core/Camera.zig").Camera;

pub const OrthographicCamera = struct {
    cam: Camera,
    width: f32,
    height: f32,
    near: f32,
    far: f32,

    pub fn init(allocator: std.mem.Allocator, distance: f32, width: f32, height: f32, near: f32, far: f32) OrthographicCamera {
        return .{
            .cam = Camera.init(allocator, distance),
            .width = width,
            .height = height,
            .near = near,
            .far = far,
        };
    }

    pub fn getProjectionMatrix(self: *const OrthographicCamera) math.Mat {
        return math.orthographicRhGl(self.width, self.height, self.near, self.far);
    }
};
