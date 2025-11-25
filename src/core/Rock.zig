const SceneObject = @import("SceneObject.zig");
const math = @import("zmath");
const std = @import("std");

const Rock = struct {
    sceneObject: SceneObject,

    pub fn init(allocator: std.mem.Allocator) Rock {
        var r = Rock{
            .sceneObject = SceneObject.init(allocator),
        };

        r.sceneObject.owner = &r;
        r.sceneObject.ownerDraw = draw;

        return r;
    }

    fn draw(owner: *anyopaque, world: math.Mat, pass: u32) void {}
};
