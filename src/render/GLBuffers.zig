const std = @import("std");
const gl = @cImport({
    @cInclude("glad/glad.h");
});

pub fn createBuffer(comptime T: type, data: []const T) gl.GLuint {
    var id: gl.GLuint = 0;
    gl.glGenBuffers(1, &id);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, id);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, data.len * @sizeOf(T), data.ptr, gl.GL_STATIC_DRAW);

    return id;
}

pub fn createIndexBuffer(indices: []const u32) gl.GLuint {
    var id: gl.GLuint = 0;
    gl.glGenBuffers(1, &id);

    gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, id);
    gl.glBufferData(gl.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u32), indices.ptr, gl.GL_STATIC_DRAW);

    return id;
}
