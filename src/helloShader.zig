const std = @import("std");

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
}
