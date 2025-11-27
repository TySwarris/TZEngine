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
        var world = self.localMatrix;

        var p = self.parent;

        while (p) |parent| {
            world = math.mul(world, parent.localMatrix);
            p = parent.parent;
        }
        return world;
    }

    pub fn draw(self: *SceneObject, parentMatrix: math.Mat, pass: u32) void {
        // World = Model/localMatrix * parentMatrix, zmath has vector major so its flipped.
        const world = math.mul(self.localMatrix, parentMatrix);

        if (self.ownerDraw) |drawFn| {
            if (self.owner) |o| {
                drawFn(o, world, pass);
            }
        }

        for (self.children.items) |child| {
            child.draw(world, pass);
        }
    }

    pub fn translateLocal(self: *SceneObject, x: f32, y: f32, z: f32) void {
        self.localMatrix = math.mul(self.localMatrix, math.translation(x, y, z));
    }

    pub fn rotateZLocal(self: *SceneObject, angle: f32) void {
        self.localMatrix = math.mul(self.localMatrix, math.rotationZ(angle));
    }

    pub fn rotateYLocal(self: *SceneObject, angle: f32) void {
        self.localMatrix = math.mul(self.localMatrix, math.rotationY(angle));
    }

    pub fn rotateXLocal(self: *SceneObject, angle: f32) void {
        self.localMatrix = math.mul(self.localMatrix, math.rotationX(angle));
    }

    pub fn scaleLocal(self: *SceneObject, x: f32, y: f32, z: f32) void {
        self.localMatrix = math.mul(self.localMatrix, math.scaling(x, y, z));
    }
};
