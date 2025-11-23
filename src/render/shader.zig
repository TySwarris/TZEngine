const std = @import("std");

// Import OpenGL (and GLFW if you need it here)
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

pub const ShaderError = error{
    FileReadFailed,
    CompileFailed,
    LinkFailed,
};

pub const Shader = struct {
    program: c.GLuint,

    /// Create a shader program from two GLSL files.
    pub fn initFromFiles(
        allocator: std.mem.Allocator,
        vertex_path: []const u8,
        fragment_path: []const u8,
    ) !Shader {
        const vert_src = try readFileAlloc(allocator, vertex_path);
        defer allocator.free(vert_src);

        const frag_src = try readFileAlloc(allocator, fragment_path);
        defer allocator.free(frag_src);

        const vert = try compileShader(vert_src, c.GL_VERTEX_SHADER, "VERTEX");
        defer c.glDeleteShader(vert);

        const frag = try compileShader(frag_src, c.GL_FRAGMENT_SHADER, "FRAGMENT");
        defer c.glDeleteShader(frag);

        const program = try linkProgram(vert, frag);

        return Shader{ .program = program };
    }

    /// Use/bind the shader program.
    pub fn use(self: *Shader) void {
        c.glUseProgram(self.program);
    }

    /// Set a bool uniform (name must be a C-string literal, e.g. c"uFlag")
    pub fn setBool(self: *Shader, name: [:0]const u8, value: bool) void {
        const loc = c.glGetUniformLocation(self.program, name);
        if (loc == -1) return; // uniform not found; ignore
        c.glUniform1i(loc, if (value) 1 else 0);
    }

    /// Set an int uniform
    pub fn setInt(self: *Shader, name: [:0]const u8, value: i32) void {
        const loc = c.glGetUniformLocation(self.program, name);
        if (loc == -1) return;
        c.glUniform1i(loc, value);
    }

    /// Set a float uniform
    pub fn setFloat(self: *Shader, name: [:0]const u8, value: f32) void {
        const loc = c.glGetUniformLocation(self.program, name);
        if (loc == -1) return;
        c.glUniform1f(loc, value);
    }
};

fn readFileAlloc(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const fs = std.fs;

    var file = try fs.cwd().openFile(path, .{});
    defer file.close();

    const stat = try file.stat();
    const size: usize = @intCast(stat.size);

    //alocate a buffer big enough for whole file
    const buf = try allocator.alloc(u8, size);

    var offset: usize = 0;
    while (offset < size) {
        const n = try file.read(buf[offset..]);
        if (n == 0) break;
        offset += n;
    }

    return buf[0..offset];
}

fn compileShader(source: []const u8, kind: c.GLenum, label: []const u8) !c.GLuint {
    const shader = c.glCreateShader(kind);

    var ptr = source.ptr;
    var len: c.GLint = @intCast(source.len);
    c.glShaderSource(shader, 1, &ptr, &len);
    c.glCompileShader(shader);

    var success: c.GLint = 0;
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        var log_buf: [1024]u8 = undefined;
        var log_len: c.GLsizei = 0;

        c.glGetShaderInfoLog(shader, 1024, &log_len, &log_buf);
        const msg = log_buf[0..@intCast(log_len)];

        std.debug.print(
            "ERROR::SHADER_COMPILATION_ERROR of type {s}\n{s}\n---\n",
            .{ label, msg },
        );

        return ShaderError.CompileFailed;
    }

    return shader;
}

fn linkProgram(vert: c.GLuint, frag: c.GLuint) !c.GLuint {
    const program = c.glCreateProgram();
    c.glAttachShader(program, vert);
    c.glAttachShader(program, frag);
    c.glLinkProgram(program);

    var success: c.GLint = 0;
    c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);
    if (success == 0) {
        var log_buf: [1024]u8 = undefined;
        var log_len: c.GLsizei = 0;

        c.glGetProgramInfoLog(program, 1024, &log_len, &log_buf);
        const msg = log_buf[0..@intCast(log_len)];

        std.debug.print(
            "ERROR::PROGRAM_LINKING_ERROR\n{s}\n---\n",
            .{msg},
        );

        return ShaderError.LinkFailed;
    }

    return program;
}
