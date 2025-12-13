const SceneObject = @import("../core/SceneObject.zig").SceneObject;
const Shader = @import("../render/shader.zig").Shader;
const GLBuffers = @import("../render/GLBuffers.zig");

const math = @import("zmath");
const std = @import("std");
const gl = @cImport({
    @cInclude("glad/glad.h");
});
pub const SquareCritter = struct {
    sceneObject: SceneObject,
    allocator: std.mem.Allocator,
    shader: Shader,
    vao: gl.GLuint = 0,
    vbo: gl.GLuint = 0,
    ebo: gl.GLuint = 0,

    color: [3]f32 = undefined,
    rChange: f16 = 0.01,
    gChange: f16 = 0.05,
    bChange: f16 = 0.075,

    pub fn init(self: *SquareCritter, allocator: std.mem.Allocator) !void {
        self.sceneObject = SceneObject.init(allocator);
        self.allocator = allocator;
        self.sceneObject.owner = self;
        self.sceneObject.ownerDraw = draw;
        self.shader = try Shader.initFromFiles(
            allocator,
            "shaders/vertexShader.glsl",
            "shaders/fragmentShader.glsl",
        );
        self.color = .{ 0.8, 0.2, 0.2 };

        const vertices = [_]f32{
            //Positions
            0.5,  0.5,  0.0,
            -0.5, 0.5,  0.0,
            -0.5, -0.5, 0.0,
            0.5,  -0.5, 0.0,
        };

        const indices = [_]u32{
            0, 1, 2,
            0, 2, 3,
        };

        self.vao = GLBuffers.createVAO();
        gl.glBindVertexArray(self.vao);

        self.vbo = GLBuffers.createVBO(&vertices);
        GLBuffers.defineVertexAttribute(0, 3, 3 * @sizeOf(f32), 0);

        self.ebo = GLBuffers.createEBO(&indices);

        gl.glBindVertexArray(0);
    }

    fn draw(owner: *anyopaque, world: math.Mat, pass: u32) void {
        _ = pass;

        const self: *SquareCritter = @ptrCast(@alignCast(owner));
        self.shader.use();

        self.shader.setMat4("u_mvpMatrix", world);
        self.shader.setVec3("u_color", self.color);

        gl.glBindVertexArray(self.vao);
        gl.glPolygonMode(gl.GL_FRONT_AND_BACK, gl.GL_FILL);
        gl.glDrawElements(gl.GL_TRIANGLES, 6, gl.GL_UNSIGNED_INT, null);

        //gl.glBindVertexArray(0);
    }

    pub fn update(self: *SquareCritter, dt: f32) void {
        if (self.color[0] >= 1.0 or self.color[0] <= 0.0) {
            self.rChange *= -1;
        }
        if (self.color[1] >= 1.0 or self.color[1] <= 0.0) {
            self.gChange *= -1;
        }
        if (self.color[2] >= 1.0 or self.color[2] <= 0.0) {
            self.bChange *= -1;
        }
        self.color[0] += self.rChange * dt;
        self.color[1] += self.gChange * dt;
        self.color[2] += self.bChange * dt;
    }

    pub fn deinit(self: *SquareCritter) void {
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

        // Deinit shader (assuming Shader has its own deinit)
        self.shader.deinit();

        // Deinit the embedded SceneObject
        self.sceneObject.deinit();
    }
};
