const std = @import("std");

const Coord = struct { col: i16, row: i16 };
const Neighbours = struct {
    items: [6]Coord,
    len: i8,
};
pub fn neighbours(col: i16, row: i16, gridWidth: u16, gridHeight: u16) Neighbours {
    var unchecked = Neighbours{ .items = undefined, .len = 0 };

    unchecked.items[0].col = col;
    unchecked.items[0].row = row - 1;
    unchecked.items[1].col = col + 1;
    unchecked.items[1].row = row - 1;
    unchecked.items[2].col = col + 1;
    unchecked.items[2].row = row;
    unchecked.items[3].col = col;
    unchecked.items[3].row = row + 1;
    unchecked.items[4].col = col - 1;
    unchecked.items[4].row = row;
    unchecked.items[5].col = col - 1;
    unchecked.items[5].row = row - 1;

    const out = checkBounds(unchecked, gridWidth, gridHeight);
    return out;
}

pub fn checkBounds(toCheck: Neighbours, gridWidth: u16, gridHeight: u16) Neighbours {
    var checked: Neighbours = Neighbours{ .items = undefined, .len = 0 };
    var checkedI: usize = 0;
    for (toCheck.items, 0..) |n, i| {
        if (!(n.col < 0 or n.col > gridWidth or n.row < 0 or n.row > gridHeight)) {
            checked.items[checkedI].col = toCheck.items[i].col;
            checked.items[checkedI].row = toCheck.items[i].row;
            std.debug.print("Neighbour: .{d} is col:.{d} row: .{d}{", .{ checkedI, checked.items[checkedI].col, checked.items[checkedI].row });
            checkedI += 1;
        } else {
            continue;
        }
    }
    checked.len = @intCast(checkedI);
    return checked;
}
