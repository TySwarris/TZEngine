const std = @import("std");
const Hexagon = @import("../sceneObjects/Hexagon.zig").Hexagon;
const grid = @import("../dataStructures/grid.zig").grid;

const Coord = struct { col: i16, row: i16 };
const Neighbours = struct {
    items: [6]Coord,
    len: usize,
};

const MAX_ENTROPY: u4 = 5; //upp this if u make more cells

const WATER_COLOR: [3]f32 = .{ 0, 0.5, 0.95 }; //only next to grass or sand
const GRASS_COLOR: [3]f32 = .{ 0.04, 0.4, 0.08 };
const SAND_COLOR: [3]f32 = .{ 1, 1, 0.2 };
const FOREST_COLOR: [3]f32 = .{ 0.05, 0.15, 0 };
const ENTROPY_4: [3]f32 = .{};
const ENTROPY_3: [3]f32 = .{};
const ENTROPY_2: [3]f32 = .{};
const CONTRADICTION: [3]f32 = .{ 1, 0, 0 };

const WATER_NEIGHBOUR_MASK: u4 = 0b1110;
const GRASS_NEIGHBOUR_MASK: u4 = 0b1111;
const SAND_NEIGHBOUR_MASK: u4 = 0b1110;
const FOREST_NEIGHBOUR_MASK: u4 = 0b0101;

var changedCells: std.Deque(Coord) = undefined;

pub fn init(queueSize: usize, allocator: std.mem.Allocator) void {
    changedCells = std.Deque(Coord).initCapacity(allocator, queueSize) catch |err| {
        std.debug.print("couldn't initialise WFC queue: .{any}\n", .{err});
        return;
    };

    return;
}

pub fn deinit(allocator: std.mem.Allocator) void {
    changedCells.deinit(allocator);
}

const WATER: u4 = 0b1000;
const GRASS: u4 = 0b0100;
const SAND: u4 = 0b0010;
const FOREST: u4 = 0b0001;

pub fn neighbours(col: i16, row: i16, gridWidth: i16, gridHeight: i16) Neighbours {
    var unchecked = Neighbours{ .items = undefined, .len = 0 };

    //common between columns left right up down
    unchecked.items[0] = Coord{ //left
        .col = col - 1,
        .row = row,
    };
    unchecked.items[1] = Coord{ //right
        .col = col + 1,
        .row = row,
    };
    unchecked.items[2] = Coord{ //up
        .col = col,
        .row = row - 1,
    };
    unchecked.items[3] = Coord{ //down
        .col = col,
        .row = row + 1,
    };

    if (@mod(col, 2) == 0) { //even column
        unchecked.items[4] = Coord{ // up-right diagonal
            .col = col + 1,
            .row = row - 1,
        };
        unchecked.items[5] = Coord{ // up-left diagonal
            .col = col - 1,
            .row = row - 1,
        };
    } else { //odd column
        unchecked.items[4] = Coord{ //down right diagonal
            .col = col + 1,
            .row = row + 1,
        };
        unchecked.items[5] = Coord{ // down left diagonal
            .col = col - 1,
            .row = row + 1,
        };
    }

    std.debug.print("Initial Hex: col: {d}, row: {d}\n", .{ col, row });

    const out = checkBounds(unchecked, gridWidth, gridHeight);
    return out;
}

pub fn checkBounds(toCheck: Neighbours, gridWidth: i16, gridHeight: i16) Neighbours {
    var checked: Neighbours = Neighbours{ .items = undefined, .len = 0 };
    var checkedI: usize = 0;

    for (toCheck.items, 0..) |n, i| {
        if (!(n.col < 0 or n.col > gridWidth - 1 or n.row < 0 or n.row > gridHeight - 1)) {
            checked.items[checkedI].col = toCheck.items[i].col;
            checked.items[checkedI].row = toCheck.items[i].row;
            std.debug.print("Neighbour: {d} is col: {d} row: {d}\n", .{ checkedI, checked.items[checkedI].col, checked.items[checkedI].row });
            checkedI += 1;
        } else {
            continue;
        }
    }
    checked.len = checkedI;
    return checked;
}

pub fn WFCStep(hexagons: grid, allocator: std.mem.Allocator) void {
    var checkedCol: i16 = undefined;
    var checkedRow: i16 = undefined;
    var lowestEntropy: u4 = MAX_ENTROPY;

    for (0..hexagons.cells.len) |i| {
        var cell = &hexagons.cells[i];
        const currentEntropy: u4 = @popCount(cell.tileMask);
        switch (currentEntropy) {
            0 => cell.color = CONTRADICTION,
            1 => {
                cell.color = maskToTileColor(cell.tileMask);
                cell.collapsed = true;
            },
            2 => cell.color = ENTROPY_2,
            3 => cell.color = ENTROPY_3,
            4 => cell.color = ENTROPY_4,
        }
        if ((currentEntropy < lowestEntropy) and (currentEntropy > 1)) { //getting the lowest entropy hexagon.hexagons
            const col: i16 = @intCast(hexagons.indexToColRow(i)[0]);
            const row: i16 = @intCast(hexagons.indexToColRow(i)[1]);
            checkedCol = col;
            checkedRow = row;
            lowestEntropy = currentEntropy;
        }
    }

    //now we have the lowest entropy cell in checkekCol and Row variables. it would be the first with the lowest entropy, idk if that is a problem.
    changedCells.pushBack(allocator, Coord{ .col = checkedCol, .row = checkedRow }) catch return;
    propagation(hexagons, allocator);
}

pub fn maskToTileColor(mask: u4) [3]f32 {
    var out: [3]f32 = undefined;
    switch (mask) {
        WATER => out = WATER_COLOR,
        GRASS => out = GRASS_COLOR,
        SAND => out = SAND_COLOR,
        FOREST => out = FOREST_COLOR,
    }
    return out;
}

pub fn neighbourMask(mask: u4) u4 {
    var out: u4 = undefined;
    switch (mask) {
        WATER => out = WATER_NEIGHBOUR_MASK,
        GRASS => out = GRASS_NEIGHBOUR_MASK,
        SAND => out = SAND_NEIGHBOUR_MASK,
        FOREST => out = FOREST_NEIGHBOUR_MASK,
    }
    return out;
}

pub fn propagation(hexagons: grid, allocator: std.mem.Allocator) void {
    while (changedCells.popFront()) |changedCoords| {
        const col: usize = @intCast(changedCoords.col);
        const row: usize = @intCast(changedCoords.row);
        hexagons.get(col, row).inQueue = false;
        const mask: u4 = hexagons.get(col, row).tileMask;
        var nMask: u4 = 0;
        if ((mask & WATER) == WATER) {
            nMask = nMask | WATER_NEIGHBOUR_MASK;
        }
        if ((mask & GRASS) == GRASS) {
            nMask = nMask | GRASS_NEIGHBOUR_MASK;
        }
        if ((mask & SAND) == SAND) {
            nMask = nMask | SAND_NEIGHBOUR_MASK;
        }
        if ((mask & FOREST) == FOREST) {
            nMask = nMask | FOREST_NEIGHBOUR_MASK;
        }
        const checkNeighbours = neighbours(changedCoords.col, changedCoords.row, hexagons.len, hexagons[0].len);
        for (0..checkNeighbours.len) |i| {
            const innerCol: usize = @intCast(checkNeighbours.items[i].col);
            const innerRow: usize = @intCast(checkNeighbours.items[i].row);
            const old: u4 = hexagons.get(innerCol, innerRow).tileMask;
            const newMask: u4 = old & nMask;
            if ((newMask) != old) {
                hexagons.get(innerCol, innerRow).tileMask = newMask;
                if (hexagons.get(innerCol, innerRow).inQueue == false) {
                    changedCells.pushBack(allocator, checkNeighbours.items[i]) catch break;
                    hexagons.get(innerCol, innerRow).inQueue = true;
                }
            }
        }
    }
    return;
}
