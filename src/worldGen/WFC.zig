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

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

var changedCells = std.Deque(Coord).initCapacity(gpa, 160);

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
        WATER => out = Tiles.waterColor,
        GRASS => out = Tiles.grassColor,
        SAND => out = Tiles.sandColor,
        FOREST => out = Tiles.forestColor,
    }
    return out;
}

pub fn neighbourMask(mask: u4) u4 {
    var out: u4 = undefined;
    switch (mask) {
        WATER => out = NeighbourMasks.waterNeighbourMask,
        GRASS => out = NeighbourMasks.grassNeighbourMask,
        SAND => out = NeighbourMasks.sandNeighbourMask,
        FOREST => out = NeighbourMasks.forestNeighbourMask,
    }
    return out;
}

pub fn propogation(hexagons: [][]Hexagon, changedQueue: std.Deque(Coord)) void {
    while (changedQueue.popFront()) |changedCoords| {
        const mask = hexagons[changedCoords.col][changedCoords.row].tileMask;
        var nMask: u4 = 0;
        if ((mask & WATER) == WATER) { // if the tile has water available.
            nMask = nMask | NeighbourMasks.waterNeighbourMask;
        }
        if ((mask & GRASS) == GRASS) { //if the tile has grass available.
            nMask = nMask | NeighbourMasks.grassNeighbourMask;
        }
        if ((mask & SAND) == SAND) {
            nMask = nMask | NeighbourMasks.sandNeighbourMask;
        }
        if ((mask & FOREST) == FOREST) {
            nMask = nMask | NeighbourMasks.forestNeighbourMask;
        }
        const checkNeighbours = neighbours(changedCoords.col, changedCoords.row, hexagons.len, hexagons[0].len);
        for (0..checkNeighbours.len) |i| {
            const old = hexagons[checkNeighbours.items[i].col][checkNeighbours.items[i].row].tileMask;
            if (old & nMask != old) {
                if (hexagons[checkNeighbours.items[i].col][checkNeighbours.items[i].row].inQueue == false) {
                    changedQueue.pushBack(gpa, checkNeighbours.items[i]) orelse break;
                }
                hexagons[checkNeighbours.items[i].col][checkNeighbours.items[i].row].tileMask = old & nMask;
            }
        }
    }
    return;
}
