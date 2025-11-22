const std = @import("std");

const ShaderMod = @import("render/shader.zig");
const Shader = ShaderMod.Shader;
const c = @cImport({
    @cInclude("GLFW/glfw3.h");
    @cInclude("GL/gl.h");
});
pub fn main() void {
    std.debug.print("GLFW version: {s}\n", .{c.glfwGetVersionString()});

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window = c.glfwCreateWindow(800, 600, "OpenGL with Zig", null, null);

    if (window == null) {
        std.debug.print("Failed to create GLFW window", .{});
        c.glfwTerminate();
    }
    c.glfwMakeContextCurrent(window);
    c.glfwSetFramebufferSizeCallback(window, frameBuffer_size_callback);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var shader = try Shader.initFromFiles(
        allocator,
        "shader/vertexShader",
        "shader/fragmentShader",
    );

    var vertices = [_]f32{
        //Positions                            //Colours
        -1.0, 1.0,  0.0, 1.0, 0.0, 0.0,
        -1.0, -1.0, 0.0, 0.0, 1.0, 0.0,
        1.0,  -1.0, 0.0, 0.0, 0.0, 1.0,
    };

    var indicies = [_]u32{ 0, 1, 2 };

    var VBO: c.GLuint = undefined;
    var VAO: u32 = undefined;

    c.glGenVertexArrays(1, &VAO);
}

fn processInput(window: ?*c.GLFWwindow) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
    }
}

fn frameBuffer_size_callback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.c) void {
    _ = window;
    c.glViewport(0, 0, width, height);
}
