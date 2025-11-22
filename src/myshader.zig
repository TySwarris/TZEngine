const std = @import("std");

const c = @cImport({
    @cInclude("GLFW/glfw3.h");
    @cInclude("GL/gl.h");
});

pub const shaderError = error{
    FileReadFailed,
    CompileFailed,
    LinkFailed,
};

pub const Shader = struct {
    program: c.GLuint,

    pub fn initFromFiles(
        allocator: std.mem.Allocator,
        vertexPath: []const u8,
        fragmentPath: []const u8,
    ) !Shader {
        const vertSrc = try readFileAlloc(allocator, vertexPath);
        defer allocator.free(vertSrc);

        const fragSrc = try readFileAlloc(allocator, fragmentPath);
        defer allocator.free(fragSrc);

        const vert = try compileShader();
    }
};

fn readFileAlloc(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const stat = try file.stat();
    const buf = try allocator.alloc(u8, @intCast(stat.size));

    const n = try file.readAll(buf);
    return buf[0..n];
}

fn compileShader(source: []const u8, kind: c.GLenum, label: []const u8) !c.GLuint {
    const shader = c.glCreateShader(kind);

    var ptr = source.ptr;
    var len: c.GLint = @intCast(source.len);
}
