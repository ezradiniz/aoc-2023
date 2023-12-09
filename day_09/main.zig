const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const test_allocator = std.testing.allocator;

// NOTE: Naive solution
fn predictNextValue(alloc: Allocator, history: []i64) !i64 {
    var result: i64 = 0;
    var row = ArrayList(i64).init(alloc);
    defer row.deinit();
    try row.appendSlice(history);
    while (true) {
        var next_row = ArrayList(i64).init(alloc);
        defer next_row.deinit();
        var i: usize = 1;
        var is_all_zero = true;
        while (i < row.items.len) : (i += 1) {
            const diff = row.items[i] - row.items[i - 1];
            is_all_zero = diff == 0 and is_all_zero;
            try next_row.append(diff);
        }
        result += row.getLast();
        if (is_all_zero) {
            break;
        }
        row.clearAndFree();
        try row.appendSlice(next_row.items);
    }
    return result;
}

// NOTE: Naive solution
//TODO: Avoid unnecessary memory allocation
fn predictNextExtrapolatedValue(alloc: Allocator, history: []i64) !i64 {
    var row = ArrayList(i64).init(alloc);
    defer row.deinit();
    var left_values = ArrayList(i64).init(alloc);
    defer left_values.deinit();
    try row.appendSlice(history);
    while (true) {
        var next_row = ArrayList(i64).init(alloc);
        defer next_row.deinit();
        var i: usize = 1;
        var is_all_zero = true;
        while (i < row.items.len) : (i += 1) {
            const diff = row.items[i] - row.items[i - 1];
            is_all_zero = diff == 0 and is_all_zero;
            try next_row.append(diff);
        }
        try left_values.append(row.items[0]);
        if (is_all_zero) {
            break;
        }
        row.clearAndFree();
        try row.appendSlice(next_row.items);
    }
    var result: i64 = left_values.getLast();
    var i: usize = left_values.items.len - 1;
    while (i > 0) : (i -= 1) {
        result = left_values.items[i - 1] - result;
    }
    return result;
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var part1: i64 = 0;
    var part2: i64 = 0;

    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        var history = ArrayList(i64).init(alloc);
        defer history.deinit();
        var di = std.mem.tokenizeAny(u8, line, " ");
        while (di.next()) |num| {
            try history.append(try std.fmt.parseInt(i64, num, 10));
        }
        part1 += try predictNextValue(alloc, history.items);
        part2 += try predictNextExtrapolatedValue(alloc, history.items);
    }

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}

// TODO: simplify tests cases
test "sample - part 01" {
    const input = @embedFile("sample.txt");
    var it = std.mem.tokenizeAny(u8, input, "\n");
    var result: i64 = 0;
    while (it.next()) |line| {
        var history = ArrayList(i64).init(test_allocator);
        defer history.deinit();
        var di = std.mem.tokenizeAny(u8, line, " ");
        while (di.next()) |num| {
            try history.append(try std.fmt.parseInt(i64, num, 10));
        }
        result += try predictNextValue(test_allocator, history.items);
    }
    try std.testing.expectEqual(result, 114);
}

test "sample - part 02" {
    const input = @embedFile("sample.txt");
    var it = std.mem.tokenizeAny(u8, input, "\n");
    var result: i64 = 0;
    while (it.next()) |line| {
        var history = ArrayList(i64).init(test_allocator);
        defer history.deinit();
        var di = std.mem.tokenizeAny(u8, line, " ");
        while (di.next()) |num| {
            try history.append(try std.fmt.parseInt(i64, num, 10));
        }
        result += try predictNextExtrapolatedValue(test_allocator, history.items);
    }
    try std.testing.expectEqual(result, 2);
}
