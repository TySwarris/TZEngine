const math = @import("zmath");
const std = @import("std");

pub const SceneObject = struct {
    allocator: std.mem.Allocator,

    localMatrix: math.Mat,
    children: std.ArrayList(*SceneObject),
    parent: ?*SceneObject, //nullable parent

    owner: ?*anyopaque = null,
    ownerDraw: ?*const fn (owner: *anyopaque, world: math.Mat, pass: u32) void = null,

    pub fn init(allocator: std.mem.Allocator) SceneObject {
        return .{
            .allocator = allocator,
            .localMatrix = math.identity(),
            .children = std.ArrayList(*SceneObject).empty,
            .parent = null,
        };
    }

    pub fn deinit(self: *SceneObject) void {
        self.children.deinit(self.allocator);
    }

    pub fn setParent(self: *SceneObject, newParent: ?*SceneObject) !void {
        if (self.parent) |old| {
            for (old.children.items, 0..) |parentChildren, i| {
                if (parentChildren == self) {
                    _ = old.children.orderedRemove(i);
                    break;
                }
            }
        }
        self.parent = newParent;

        if (newParent) |p| {
            try p.children.append(self.allocator, self);
        }
    }

    pub fn getWorldMatrix(self: *SceneObject) math.Mat {
        var tempMatrix = math.identity();

        var current: ?*SceneObject = self;

        while (current) |obj| {
            tempMatrix = math.mul(obj.localMatrix, tempMatrix);
            current = obj.parent;
        }
        return tempMatrix;
    }

    pub fn draw(self: *SceneObject, parentMatrix: math.Mat, pass: u32) !void {
        const world = math.Mul(parentMatrix, self.localMatrix);

        if (self.ownerDraw) |drawFn| {
            if (self.owner) |ctx| {
                drawFn(ctx, world, pass);
            }
        }

        for (self.children.items) |child| {
            child.draw(world, pass);
        }
    }
};
