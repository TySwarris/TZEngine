const SceneObject = @import("../core/SceneObject.zig").SceneObject;
const Shader = @import("../render/shader.zig").Shader;

const math = @import("zmath");
const std = @import("std");
const gl = @cImport({
    @cInclude("glad/glad.h");
});
pub const Rock = struct {
    sceneObject: SceneObject,
    allocator: std.mem.Allocator,
    shader: Shader,
    vao: gl.GLuint = 0,
    vbo: gl.GLuint = 0,

    pub fn init(self: *Rock, allocator: std.mem.Allocator) !void {
        self.sceneObject = SceneObject.init(allocator);
        self.allocator = allocator;
        self.sceneObject.owner = self;
        self.sceneObject.ownerDraw = draw;
        self.shader = try Shader.initFromFiles(
            allocator,
            "shaders/vertexShader.glsl",
            "shaders/fragmentShader.glsl",
        );

        const vertices = [_]f32{
            //Positions                            //Colours
            1.0,  1.0,  0.0,
            -1.0, -1.0, 0.0,
            1.0,  -1.0, 0.0,
        };

        //const

        gl.glGenVertexArrays(1, &self.vao);
        gl.glGenBuffers(1, &self.vbo);

        gl.glBindVertexArray(self.vao);

        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.vbo);
        gl.glBufferData(gl.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), vertices[0..].ptr, gl.GL_STATIC_DRAW);

        gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 3 * @sizeOf(f32), @as(?*const anyopaque, @ptrFromInt(0)));
        gl.glEnableVertexAttribArray(0);

        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0);

        gl.glBindVertexArray(0);
    }

    fn draw(owner: *anyopaque, world: math.Mat, pass: u32) void {
        _ = pass;

        const self: *Rock = @ptrCast(@alignCast(owner));
        self.shader.use();

        self.shader.setMat4("u_mvpMatrix", world);
        //self.shader.setFloat

        gl.glBindVertexArray(self.vao);

        gl.glDrawArrays(gl.GL_TRIANGLES, 0, 3);
    }

    pub fn deinit(self: *Rock) void {
        // Delete GL vertex array + buffers
        if (self.vao != 0) {
            gl.glDeleteVertexArrays(1, &self.vao);
            self.vao = 0;
        }
        if (self.vbo != 0) {
            gl.glDeleteBuffers(1, &self.vbo);
            self.vbo = 0;
        }

        // Deinit shader (assuming Shader has its own deinit)
        self.shader.deinit();

        // Deinit the embedded SceneObject
        self.sceneObject.deinit();
    }
};
