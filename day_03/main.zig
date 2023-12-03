const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const isDigit = std.ascii.isDigit;
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;

const directions = [_][2]i32{
    [_]i32{ 1, 0 },
    [_]i32{ 0, 1 },
    [_]i32{ -1, 0 },
    [_]i32{ 0, -1 },
    [_]i32{ 1, 1 },
    [_]i32{ 1, -1 },
    [_]i32{ -1, 1 },
    [_]i32{ -1, -1 },
};

fn isSymbol(ch: u8) bool {
    return ch != '.' and !isDigit(ch);
}

fn isGearSymbol(ch: u8) bool {
    return ch == '*';
}

fn isAdjacentToSymbol(grid: ArrayList([]const u8), i: usize, j: usize) bool {
    const m: usize = grid.items.len;
    const n: usize = grid.items[0].len;
    for (directions) |dx| {
        const ni = @as(i32, @intCast(i)) + dx[0];
        const nj = @as(i32, @intCast(j)) + dx[1];
        if (ni >= 0 and ni < m and nj >= 0 and nj < n and isSymbol(grid.items[@as(usize, @intCast(ni))][@as(usize, @intCast(nj))])) {
            return true;
        }
    }
    return false;
}

fn addAdjacentGears(grid: ArrayList([]const u8), hm: *AutoHashMap([2]usize, void), i: usize, j: usize) !void {
    const m: usize = grid.items.len;
    const n: usize = grid.items[0].len;
    for (directions) |dx| {
        const ni = @as(i32, @intCast(i)) + dx[0];
        const nj = @as(i32, @intCast(j)) + dx[1];
        if (ni >= 0 and ni < m and nj >= 0 and nj < n and isGearSymbol(grid.items[@as(usize, @intCast(ni))][@as(usize, @intCast(nj))])) {
            // TODO: is there a better way to cast the number?
            try hm.put([2]usize{ @as(usize, @intCast(ni)), @as(usize, @intCast(nj)) }, {});
        }
    }
}

fn sumAllPartNumbers(grid: ArrayList([]const u8)) usize {
    const m: usize = grid.items[0].len;
    var sum: usize = 0;
    for (grid.items, 0..) |row, i| {
        var num: usize = 0;
        var is_valid = false;
        for (row, 0..) |col, j| {
            if (isDigit(col)) {
                num = num * 10 + (col - '0');
                is_valid = is_valid or isAdjacentToSymbol(grid, i, j);
            } else {
                is_valid = false;
                num = 0;
            }
            if (is_valid and (j + 1 == m or !isDigit(grid.items[i][j + 1]))) {
                sum += num;
            }
        }
    }
    return sum;
}

fn sumAllGearRatios(alloc: Allocator, grid: ArrayList([]const u8)) !usize {
    const m: usize = grid.items[0].len;
    var gears = std.AutoHashMap([2]usize, [2]usize).init(alloc);
    defer gears.deinit();

    for (grid.items, 0..) |row, i| {
        var num: usize = 0;
        // NOTE: This is a Set / HashSet in Zig
        var adj_gears = std.AutoHashMap([2]usize, void).init(alloc);
        defer adj_gears.deinit();

        for (row, 0..) |col, j| {
            if (isDigit(col)) {
                num = num * 10 + (col - '0');
                try addAdjacentGears(grid, &adj_gears, i, j);
            } else {
                num = 0;
                // TODO: how to clear items in the HashMap?
                var it = adj_gears.keyIterator();
                while (it.next()) |key| {
                    adj_gears.removeByPtr(key);
                }
            }
            if (num != 0 and (j + 1 == m or !isDigit(grid.items[i][j + 1]))) {
                var it = adj_gears.keyIterator();
                while (it.next()) |key| {
                    var v = try gears.getOrPut(key.*);
                    if (!v.found_existing) {
                        v.value_ptr.* = [2]usize{ 1, num };
                    } else {
                        var value = &v.value_ptr.*;
                        value[0] += 1;
                        value[1] *= num;
                    }
                }
            }
        }
    }

    var sum: usize = 0;
    var it = gears.valueIterator();
    while (it.next()) |value| {
        if (value[0] == 2) {
            sum += value[1];
        }
    }
    return sum;
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var grid = std.ArrayList([]const u8).init(allocator);
    defer grid.deinit();

    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        try grid.append(line);
    }

    const part1 = sumAllPartNumbers(grid);
    const part2 = try sumAllGearRatios(allocator, grid);

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}

test "sample - part1" {
    const input = @embedFile("sample.txt");
    var grid = std.ArrayList([]const u8).init(test_allocator);
    defer grid.deinit();
    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        try grid.append(line);
    }
    const result = sumAllPartNumbers(grid);
    try expect(result == 4361);
}

test "sample - part2" {
    const input = @embedFile("sample.txt");
    var grid = std.ArrayList([]const u8).init(test_allocator);
    defer grid.deinit();
    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        try grid.append(line);
    }
    const result = try sumAllGearRatios(test_allocator, grid);
    try expect(result == 467835);
}
