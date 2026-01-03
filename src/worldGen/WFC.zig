const std = @import("std");
const Hexagon = @import("../sceneObjects/Hexagon.zig").Hexagon;

const Coord = struct { col: i16, row: i16 };
const Neighbours = struct {
    items: [6]Coord,
    len: usize,
};

const Tiles = struct {
    waterColor: [3]f32 = .{ 0, 0.5, 0.95 }, //only next to grass or sand
    grassColor: [3]f32 = .{ 0.04, 0.4, 0.08 }, //only next to grass. sand or forest
    sandColor: [3]f32 = .{ 1, 1, 0.2 }, //only next to grass or water
    forestColor: [3]f32 = .{ 0.05, 0.15, 0 }, //only next to grass,
};

const NeighbourMasks = struct {
    waterNeighbourMask: u4 = 0b1110,
    grassNeighbourMask: u4 = 0b1111,
    sandNeighbourMask: u4 = 0b1110,
    forestNeighbourMask: u4 = 0b0101,
};

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
    } else {
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

pub fn WFCStep(Hexagons: [][]Hexagon, gridWidth: i16, gridHeight: i16) void {
    var checkedCol: usize = undefined;
    var checkedRow: usize = undefined;
    var entropy: u4 = undefined;
    for (Hexagons) |col| {
        for (col) |hex| {
            const currentEntropy: u4 = @popCount(hex.tileMask);
            if (currentEntropy == 1 and hex.collapsed == false) {
                //checking if any squares only have 1 option in their possible tiles, if they do u should make it that colour and update thhe neighbours possible tile mask.
                hex.color = maskToTile(hex.tileMask);
                hex.collapsed = true;
                var toChange = neighbours(hex.col, hex.row, gridWidth, gridHeight);
                for (0..toChange.len) |i| {
                    Hexagons[toChange.items[i]][toChange.items[i]].tileMask = Hexagons[toChange.items[i]][toChange.items[i]].tileMask & neighbourMask(hex.tileMask);
                }
                continue;
            }
            if (currentEntropy < entropy) { //getting the lowest entropy hexagon.
                checkedCol = hex.col;
                checkedRow = hex.row;
                entropy = currentEntropy;
            }
        }
    }
    //now we have the lowest entropy cell in checkekCol and Row variables. it would be the first with the lowest entropy, idk if that is a problem.

}

pub fn maskToTile(mask: u4) [3]f32 {
    var out: [3]f32 = undefined;
    switch (mask) {
        0b1000 => out = Tiles.waterColor,
        0b0100 => out = Tiles.grassColor,
        0b0010 => out = Tiles.sandColor,
        0b0001 => out = Tiles.forestColor,
    }
    return out;
}

pub fn neighbourMask(mask: u4) u4 {
    var out: u4 = undefined;
    switch (mask) {
        0b1000 => out = NeighbourMasks.waterNeighbourMask,
        0b0100 => out = NeighbourMasks.grassNeighbourMask,
        0b0010 => out = NeighbourMasks.sandNeighbourMask,
        0b0001 => out = NeighbourMasks.forestNeighbourMask,
    }
    return out;
}
