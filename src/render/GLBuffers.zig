const std = @import("std");
const gl = @cImport({
    @cInclude("glad/glad.h");
});
pub fn createVAO() gl.GLuint {
    var id: gl.GLuint = 0;
    gl.glGenVertexArrays(1, &id);
    return id;
}

pub fn createVBO(data: []const f32) gl.GLuint {
    var id: gl.GLuint = 0;
    gl.glGenBuffers(1, &id);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, id);
    const byteSize: gl.GLsizeiptr = @intCast(data.len * @sizeOf(f32));
    gl.glBufferData(gl.GL_ARRAY_BUFFER, byteSize, data.ptr, gl.GL_STATIC_DRAW);
    return id;
}

pub fn createEBO(indices: []const u32) gl.GLuint {
    var id: gl.GLuint = 0;
    const byteSize: gl.GLsizeiptr = @intCast(indices.len * @sizeOf(u32));
    gl.glGenBuffers(1, &id);
    gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, id);

    gl.glBufferData(gl.GL_ELEMENT_ARRAY_BUFFER, byteSize, indices.ptr, gl.GL_STATIC_DRAW);
    return id;
}

pub fn defineVertexAttribute(index: u32, size: u32, stride: usize, offset: usize) void {
    const glSize: gl.GLint = @intCast(size);
    const glStride: gl.GLsizei = @intCast(stride);
    gl.glVertexAttribPointer(
        index,
        glSize,
        gl.GL_FLOAT,
        gl.GL_FALSE,
        glStride,
        @ptrFromInt(offset),
    );
    gl.glEnableVertexAttribArray(index);
}
