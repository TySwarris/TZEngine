const std = @import("std");
const math = @import("zmath");
const SceneObject = @import("core/SceneObject.zig").SceneObject;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) std.debug.print("LEAKS DETECTED!\n", .{});
    }

    const allocator = gpa.allocator();

    var root = SceneObject.init(allocator);
    defer root.deinit();

    root.localMatrix = math.translation(-4, -4, 0);
    root.localMatrix = math.mul(root.localMatrix, math.translation(-4, -4, 0));

    var objects: [15]SceneObject = undefined;

    for (&objects) |*o| {
        o.* = SceneObject.init(allocator);
    }

    defer for (&objects) |*o| {
        o.deinit();
    };

    for (&objects, 0..) |*o, i| {
        const x: f32 = @floatFromInt(i);
        o.localMatrix = math.translation(x, -x, 0);
        try o.setParent(&root);
    }
    var rootToWorld = root.getWorldMatrix();
    var rootPos = rootToWorld[3];
    std.debug.print("Root has {d} children\n Root coords = (x:{},y:{},z{}\n", .{
        root.children.items.len,
        rootPos[0],
        rootPos[1],
        rootPos[2],
    });

    for (&objects, 0..) |*o, i| {
        var oToWorld = o.*.getWorldMatrix();
        const pos = oToWorld[3];
        std.debug.print("Child {d} world posisiton = (x:{d},y:{d},z:{d})\n", .{
            i + 1,
            pos[0],
            pos[1],
            pos[2],
        });
    }

    root.localMatrix = math.translation(-32, 4, 0);
    //root.localMatrix =

    rootToWorld = root.getWorldMatrix();
    rootPos = rootToWorld[3];
    std.debug.print("Root has {d} children\n Root coords = (x:{},y:{},z{}\n", .{
        root.children.items.len,
        rootPos[0],
        rootPos[1],
        rootPos[2],
    });

    for (&objects, 0..) |*o, i| {
        var oToWorld = o.*.getWorldMatrix();
        const pos = oToWorld[3];
        std.debug.print("Child {d} world posisiton = (x:{d},y:{d},z:{d})\n", .{
            i + 1,
            pos[0],
            pos[1],
            pos[2],
        });
    }
}
