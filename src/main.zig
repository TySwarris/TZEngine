const std = @import("std");
const math = @import("zmath");

const Rock = @import("sceneObjects/Rock.zig").Rock;
const Camera = @import("sceneObjects/cameras/OrthographicCamera.zig").OrthographicCamera;

const ShaderMod = @import("render/shader.zig");
const Shader = ShaderMod.Shader;
const glfw = @import("glfw.zig").glfw;

const gl = @cImport({
    @cInclude("glad/glad.h");
});

const SCritter = @import("sceneObjects/SquareCritter.zig").SquareCritter;

fn zigGlfwLoader(name: [*c]const u8) callconv(.c) ?*anyopaque {
    const proc_opt = glfw.glfwGetProcAddress(name);
    if (proc_opt) |p| {
        const addr = @intFromPtr(p);
        return @as(?*anyopaque, @ptrFromInt(addr));
    }
    return null;
}

fn glfwErrorCallback(error_code: c_int, description: [*c]const u8) callconv(.c) void {
    const msg = std.mem.span(description);
    std.debug.print("GLFW error {d}: {s}\n", .{ error_code, msg });
}
pub fn main() !void {
    std.debug.print("GLFW version: {s}\n", .{glfw.glfwGetVersionString()});
    //std.debug.print("{f}".{iden})
    const mat = math.identity();
    std.debug.print("mat[0][0] = {d}\n", .{mat[0][0]});

    if (glfw.glfwInit() == 0) {
        std.debug.print("Failed to initialize GLFW\n", .{});
        return error.FailedToInitGlfw;
    }
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);

    const window = glfw.glfwCreateWindow(800, 600, "OpenGL with Zig", null, null);

    if (window == null) {
        std.debug.print("Failed to create GLFW window", .{});
        glfw.glfwTerminate();
        return error.FailedToCreateWindow;
    }
    glfw.glfwMakeContextCurrent(window);
    _ = glfw.glfwSetFramebufferSizeCallback(window, frameBuffer_size_callback);

    if (gl.gladLoadGLLoader(zigGlfwLoader) == 0) {
        std.debug.print("Failed to initialize GLAD\n", .{});
        return;
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    //var _indicies = [_]u32{ 0, 1, 2 };
    var camera: Camera = Camera.init(allocator, 2.0, 4.0, 4.0, 0.5, 10.0);

    //var r: Rock = undefined;
    //try r.init(allocator);
    //r.sceneObject.localMatrix = math.identity();
    //r.sceneObject.scaleLocal(0.5, 0.5, 1);

    //var r2: Rock = undefined;
    //try r2.init(allocator);
    // try r2.sceneObject.setParent(&r.sceneObject);
    // r2.sceneObject.localMatrix = math.identity();
    // r2.sceneObject.scaleLocal(0.2, 0.2, 0);
    // r2.sceneObject.translateLocal(-1, 0.5, 0);
    //
    //var x = 0;
    //
    var critter1: SCritter = undefined;
    try critter1.init(allocator);
    defer critter1.deinit();

    while (glfw.glfwWindowShouldClose(window) == 0) {
        processInput(window);

        camera.update(window);
        const view = camera.cam.getViewMatrix();
        const proj = camera.getProjectionMatrix();
        const viewProj = math.mul(view, proj);

        gl.glClearColor(0.2, 0.3, 0.3, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        critter1.sceneObject.draw(viewProj, 1);

        // r.sceneObject.draw(viewProj, 0);
        //
        // r.sceneObject.rotateZLocal(0.02);
        //r.sceneObject.rotateYLocal(0.008);
        //r2.sceneObject.localMatrix = math.mul(r2.sceneObject.localMatrix, math.translation(0.005, 0, 0));
        //
        // if (glfw.glfwGetKey(window, glfw.GLFW_KEY_W) == glfw.GLFW_PRESS) {
        //     r2.sceneObject.translateLocal(0, 0.01, 0);
        // }
        //
        // if (glfw.glfwGetKey(window, glfw.GLFW_KEY_S) == glfw.GLFW_PRESS) {
        //     r2.sceneObject.translateLocal(0, -0.01, 0);
        // }
        //
        // std.debug.print("r2 local tx,ty = {d}, {d}\n", .{ r2.sceneObject.localMatrix[3][0], r2.sceneObject.localMatrix[3][1] });
        //
        // const world = r2.sceneObject.getWorldMatrix();
        // std.debug.print("r2 WORLD tx,ty = {d}, {d}\n", .{ world[3][0], world[3][1] });

        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();
    }

    // r.deinit();
    glfw.glfwTerminate();
    return;
}

fn processInput(window: ?*glfw.GLFWwindow) void {
    if (glfw.glfwGetKey(window, glfw.GLFW_KEY_ESCAPE) == glfw.GLFW_PRESS) {
        glfw.glfwSetWindowShouldClose(window, glfw.GLFW_TRUE);
    }
}

fn frameBuffer_size_callback(window: ?*glfw.GLFWwindow, width: c_int, height: c_int) callconv(.c) void {
    _ = window;
    gl.glViewport(0, 0, width, height);
}
