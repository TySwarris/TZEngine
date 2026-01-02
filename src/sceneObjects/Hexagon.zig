const SceneObject = @import("../core/SceneObject.zig").SceneObject;
const Shader = @import("../render/shader.zig").Shader;
const GLBuffers = @import("../render/GLBuffers.zig");

const math = @import("zmath");
const std = @import("std");
const gl = @cImport({
    @cInclude("glad/glad.h");
});
pub const Hexagon = struct {
    sceneObject: SceneObject,
    allocator: std.mem.Allocator,
    shader: Shader,
    vao: gl.GLuint = 0,
    vbo: gl.GLuint = 0,
    ebo: gl.GLuint = 0,

    color: [3]f32 = undefined,

    row: u16,
    col: u16,

    tileMask: u4,
    collapsed: bool,
    indicesLen: c_int,

    pub fn init(self: *Hexagon, allocator: std.mem.Allocator, color: [3]f32, xy: [2]f32, rowCol: [2]u16) !void {
        self.sceneObject = SceneObject.init(allocator);
        self.allocator = allocator;
        self.sceneObject.owner = self;
        self.sceneObject.ownerDraw = draw;
        self.shader = try Shader.initFromFiles(
            allocator,
            "shaders/vertexShader.glsl",
            "shaders/fragmentShader.glsl",
        );
        self.color = color;

        self.row = rowCol[0];
        self.row = rowCol[1];

        self.tileMask = 0b1111;
        self.collapsed = false;
        //Each bit represents a tiles.
        //Same order as in Rules.md
        //Water, Grass, Sand, Forest

        var vertices: [21]f32 = undefined;
        var i: usize = 3;
        vertices[0] = 0;
        vertices[1] = 0;
        vertices[2] = 0;
        var radians: f32 = 0;
        while (i < vertices.len) {
            vertices[i] = 0.5 * math.cos(radians);
            vertices[i + 1] = 0.5 * std.math.sin(radians);
            vertices[i + 2] = 0;
            radians += 60 * std.math.pi / 180.0;
            //std.debug.print("vertex {d} at x:{d} y: {d}\n", .{ i / 3, vertices[i], vertices[i + 1] });
            i += 3;
        }

        const indices = [_]u32{
            0, 1, 2,
            0, 2, 3,
            0, 3, 4,
            0, 4, 5,
            0, 5, 6,
            0, 6, 1,
        };

        self.sceneObject.translateLocal(xy[0], xy[1], 0);

        self.indicesLen = indices.len;

        self.vao = GLBuffers.createVAO();
        gl.glBindVertexArray(self.vao);

        self.vbo = GLBuffers.createVBO(&vertices);
        GLBuffers.defineVertexAttribute(0, 3, 3 * @sizeOf(f32), 0);

        self.ebo = GLBuffers.createEBO(&indices);

        gl.glBindVertexArray(0);
    }

    fn draw(owner: *anyopaque, world: math.Mat, pass: u32) void {
        _ = pass;

        const self: *Hexagon = @ptrCast(@alignCast(owner));
        self.shader.use();

        self.shader.setMat4("u_mvpMatrix", world);
        self.shader.setVec3("u_color", self.color);

        gl.glBindVertexArray(self.vao);
        gl.glPolygonMode(gl.GL_FRONT_AND_BACK, gl.GL_FILL);
        gl.glDrawElements(gl.GL_TRIANGLES, self.indicesLen, gl.GL_UNSIGNED_INT, null);

        //gl.glBindVertexArray(0);
    }

    pub fn update(self: *Hexagon, dt: f32) void {
        // if (self.color[0] >= 1.0 or self.color[0] <= 0.0) {
        //     self.rChange *= -1;
        // }
        // if (self.color[1] >= 1.0 or self.color[1] <= 0.0) {
        //     self.gChange *= -1;
        // }
        // if (self.color[2] >= 1.0 or self.color[2] <= 0.0) {
        //     self.bChange *= -1;
        // }
        // self.color[0] += self.rChange * dt;
        // self.color[1] += self.gChange * dt;
        // self.color[2] += self.bChange * dt;
        //self.gravity(dt);
        //self.collision();
        self.sceneObject.translateLocal(0, self.yVelocity * dt, 0);
    }

    pub fn deinit(self: *Hexagon) void {
        // Delete GL vertex array + buffers
        if (self.vao != 0) {
            gl.glDeleteVertexArrays(1, &self.vao);
            self.vao = 0;
        }
        if (self.vbo != 0) {
            gl.glDeleteBuffers(1, &self.vbo);
            self.vbo = 0;
        }
        if (self.ebo != 0) {
            gl.glDeleteBuffers(1, &self.ebo);
            self.ebo = 0;
        }

        // Deinit shader
        self.shader.deinit();

        // Deinit the embedded SceneObject
        self.sceneObject.deinit();
    }
    fn gravity(self: *Hexagon, dt: f32) void {
        const drag: f32 = -self.yVelocity * self.airResistance;
        self.yVelocity -= (9.8 * dt);
        self.yVelocity += drag * dt;
    }
    fn collision(self: *Hexagon) void {
        const worldPos: math.Mat = self.sceneObject.getWorldMatrix();
        const worldYPos: f32 = worldPos[3][1];

        //bounce
        if (worldYPos + 0.5 < -self.screenHeight / 2) {
            self.sceneObject.translateLocal(0, -self.screenHeight / 2 - worldYPos, 0);
            std.debug.print("velocity before bounce: {d}\n", .{self.yVelocity});
            self.yVelocity = -self.yVelocity * (1.0 - self.bounceLoss);
            std.debug.print("velocity after bounce: {d}\n", .{self.yVelocity});
        }
    }
};
