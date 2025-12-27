const std = @import("std");

const Coord = struct { col: i16, row: i16 };
const Neighbours = struct {
    items: [6]Coord,
    len: usize,
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
