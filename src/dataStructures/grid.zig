const std = @import("std");
const Hexagon = @import("../sceneObjects/Hexagon.zig").Hexagon;

pub const grid = struct {
    width: usize,
    height: usize,
    cells: []Hexagon,

    pub fn init(self: *grid, allocator: std.mem.Allocator, width: usize, height: usize) void {
        self.width = width;
        self.height = height;
        self.cells = try allocator.alloc(Hexagon, width * height);
    }

    pub fn deinit(self: *grid, allocator: std.mem.Allocator) void {
        allocator.free(self.cells);
    }

    //converts col, row to flat index.
    inline fn indexFromColRow(self: *grid, col: usize, row: usize) usize {
        return col * self.height + row;
    }

    pub fn get(self: *grid, col: usize, row: usize) *Hexagon {
        return &self.cells[self.index(col, row)];
    }

    pub fn indexToColRow(self: *grid, index: usize) [2]usize {
        return .{ index / self.width, @mod(index, self.width) };
    }
};
