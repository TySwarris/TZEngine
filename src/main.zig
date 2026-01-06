const std = @import("std");
const math = @import("zmath");

const Rock = @import("sceneObjects/Rock.zig").Rock;
const Camera = @import("sceneObjects/cameras/OrthographicCamera.zig").OrthographicCamera;
const Grid = @import("dataStructures/grid.zig").grid;

const ShaderMod = @import("render/shader.zig");
const Shader = ShaderMod.Shader;
const glfw = @import("glfw.zig").glfw;

const WFC = @import("worldGen/WFC.zig");

const gl = @cImport({
    @cInclude("glad/glad.h");
});

const SCritter = @import("sceneObjects/SquareCritter.zig").SquareCritter;
const Hexagon = @import("sceneObjects/Hexagon.zig").Hexagon;

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

    const width: f32 = 50;
    const height: f32 = 50;
    var camera: Camera = Camera.init(allocator, 2.0, width, height, 0.5, 10.0);

    var critter1: SCritter = undefined;
    try critter1.init(allocator, width, height);

    var timer = try std.time.Timer.start();

    const yOffset: f32 = std.math.sin(60 * std.math.pi / 180.0);
    var hexArr: [20][20]Hexagon = undefined;

    for (&hexArr, 0..) |*col, c| {
        const column: f32 = @floatFromInt(c);
        for (col, 0..) |*cell, r| {
            const row: f32 = @floatFromInt(r);
            if (@mod(c, 2) == 1) { // if odd row
                try cell.init(allocator, .{ 0, 0, 0 }, .{ 0.75 * column, (-row - 0.5) * yOffset }, .{ @intCast(r), @intCast(c) }); //shift down to allign
            } else {
                try cell.init(allocator, .{ 1, 1, 1 }, .{ 0.75 * column, -row * yOffset }, .{ @intCast(r), @intCast(c) });
            }
        }
    }
    // var prng = std.Random.DefaultPrng.init(seed: {
    //     var seed: u64 = undefined;
    //     try std.posix.getrandom(std.mem.asBytes(&seed));
    //     break :seed seed;
    // });

    WFC.init(hexArr.len * 2, allocator);
    defer WFC.deinit(allocator);

    // const rand = prng.random();
    // const col = rand.intRangeLessThan(i16, 0, hexArr.len);
    // const row = rand.intRangeLessThan(i16, 0, hexArr[0].len);
    //
    // hexArr[@intCast(col)][@intCast(row)].color = .{ 0, 0, 1 };
    // const neighbours = WFC.neighbours(col, row, hexArr.len, hexArr[0].len);
    //
    // for (0..neighbours.len) |i| {
    //     const colI = neighbours.items[i].col;
    //     const rowI = neighbours.items[i].row;
    //     hexArr[@intCast(colI)][@intCast(rowI)].color = .{ 0.8, 0.8, 0 };
    // }

    var frames: f32 = 0.0;
    var timeAccum: f32 = 0.0;
    while (glfw.glfwWindowShouldClose(window) == 0) {
        const dt_ns: f32 = @floatFromInt(timer.lap());
        const dt: f32 = dt_ns / 1_000_000_000;
        processInput(window);

        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_N) == glfw.GLFW_PRESS) {
            try WFC.WFCStep(&hexArr, allocator);
        }

        camera.update(window, dt);
        const view = camera.cam.getViewMatrix();
        const proj = camera.getProjectionMatrix();
        const viewProj: [4]@Vector(4, f32) = math.mul(view, proj);

        gl.glClearColor(0.2, 0.3, 0.3, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        critter1.sceneObject.draw(viewProj, 0);

        for (&hexArr) |*hexS| {
            for (hexS) |*hex| {
                hex.sceneObject.draw(viewProj, 0);
            }
        }

        critter1.update(dt);

        //FPS Counter
        frames += 1.0;
        timeAccum += dt;
        if (timeAccum >= 0.5) {
            const fps = frames / timeAccum;
            std.debug.print("FPS: {d}\n", .{fps});

            frames = 0.0;
            timeAccum = 0.0;
        }

        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();
    }

    critter1.deinit();
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
