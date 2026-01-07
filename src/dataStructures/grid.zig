const std = @import("std");
const Hexagon = @import("../sceneObjects/Hexagon.zig").Hexagon;

pub const grid = struct {
    width: usize,
    height: usize,
    cells: []Hexagon,

    pub fn init(self: *grid, allocator: std.mem.Allocator, width: usize, height: usize) void {
        self.width = width;
        self.height = height;
        self.cells = allocator.alloc(Hexagon, width * height) catch |err| {
            std.debug.print("couldn't initialise Hexagon list in grid: .{any}\n", .{err});
            return;
        };
    }

    pub fn deinit(self: *grid, allocator: std.mem.Allocator) void {
        allocator.free(self.cells);
    }

    //converts col, row to flat index.
    inline fn indexFromColRow(self: *const grid, col: usize, row: usize) usize {
        return col * self.height + row;
    }

    pub fn get(self: *grid, col: usize, row: usize) *Hexagon {
        return &self.cells[self.indexFromColRow(col, row)];
    }

    pub fn indexToColRow(self: *const grid, index: usize) [2]isize {
        return .{ @intCast(index / self.width), @intCast(@mod(index, self.width)) };
    }
};
