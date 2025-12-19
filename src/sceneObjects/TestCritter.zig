const SceneObject = @import("../core/SceneObject.zig").SceneObject;
const Shader = @import("../render/shader.zig").Shader;
const GLBuffers = @import("../render/GLBuffers.zig");

const math = @import("zmath");
const std = @import("std");
const gl = @cImport({
    @cInclude("glad/glad.h");
});
pub const TestCritter = struct {
    sceneObject: SceneObject,
    allocator: std.mem.Allocator,
    shader: Shader,
    vao: gl.GLuint = 0,
    vbo: gl.GLuint = 0,
    ebo: gl.GLuint = 0,

    color: [3]f32 = undefined,

    hunger: f32, //tim until hunger fully depleted, in seconds.
    thirst: f32, // time untill thirst fully depleted, in seconds.
    speed: f32,
    sightDistance: f32, //distance

    pub fn init(self: *TestCritter, allocator: std.mem.Allocator, hunger: f32, thirst: f32, speed: f32, sightDistance: f32) !void {
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

        self.hunger = hunger;
        self.thirst = thirst;
        self.speed = speed;
        self.sightDistance = sightDistance;

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

        const self: *TestCritter = @ptrCast(@alignCast(owner));
        self.shader.use();

        self.shader.setMat4("u_mvpMatrix", world);
        self.shader.setVec3("u_color", self.color);

        gl.glBindVertexArray(self.vao);
        gl.glPolygonMode(gl.GL_FRONT_AND_BACK, gl.GL_FILL);
        gl.glDrawElements(gl.GL_TRIANGLES, 6, gl.GL_UNSIGNED_INT, null);

        //gl.glBindVertexArray(0);
    }

    pub fn update(self: *TestCritter, dt: f32) void {
        self.self.sceneObject.translateLocal(0, 0 * dt, 0);
        self.hunger -= dt;
        self.thirst -= dt;
    }

    pub fn deinit(self: *TestCritter) void {
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
};
