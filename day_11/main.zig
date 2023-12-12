const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;

const Pos = struct {
    i: usize,
    j: usize,
};

fn abs(a: usize, b: usize) usize {
    if (a >= b) {
        return a - b;
    }
    return b - a;
}

fn appendGalaxies(alloc: Allocator, galaxies: *ArrayList(Pos), image: [][]const u8, factor: usize) !void {
    const m = image.len;
    const n = image[0].len;
    var check_row = ArrayList(bool).init(alloc);
    defer check_row.deinit();
    try check_row.appendNTimes(false, m);
    var check_col = ArrayList(bool).init(alloc);
    defer check_col.deinit();
    try check_col.appendNTimes(false, n);
    for (0..m) |i| {
        for (0..n) |j| {
            const has_galaxy = image[i][j] == '#';
            check_row.items[i] = check_row.items[i] or has_galaxy;
            check_col.items[j] = check_col.items[j] or has_galaxy;
        }
    }
    var expand_row: usize = 0;
    for (0..m) |i| {
        if (!check_row.items[i]) {
            expand_row += factor - 1;
        }
        var expand_col: usize = 0;
        for (0..n) |j| {
            if (!check_col.items[j]) {
                expand_col += factor - 1;
            }
            if (image[i][j] == '#') {
                try galaxies.append(Pos{ .i = i + expand_row, .j = j + expand_col });
            }
        }
    }
}

fn sumShortestPaths(galaxies: []const Pos) u64 {
    var sum: u64 = 0;
    for (0..galaxies.len) |i| {
        for (i + 1..galaxies.len) |j| {
            const start = galaxies[i];
            const target = galaxies[j];
            sum += abs(start.i, target.i) + abs(start.j, target.j);
        }
    }
    return sum;
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var image = ArrayList([]const u8).init(alloc);
    defer image.deinit();

    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        try image.append(line);
    }

    var galaxies_1 = ArrayList(Pos).init(alloc);
    defer galaxies_1.deinit();
    try appendGalaxies(alloc, &galaxies_1, image.items, 2);

    var galaxies_2 = ArrayList(Pos).init(alloc);
    defer galaxies_2.deinit();
    try appendGalaxies(alloc, &galaxies_2, image.items, 1_000_000);

    const part1 = sumShortestPaths(galaxies_1.items);
    const part2 = sumShortestPaths(galaxies_2.items);

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}

// TODO: Add tests
