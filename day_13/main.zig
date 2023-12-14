const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;

const Line = enum {
    vertical,
    horizontal,
};

const Reflection = struct {
    line: Line,
    count: usize,
};

// TODO: is there any built-in function for this?
fn countBits(n: u64) i32 {
    var x = n;
    var bits: i32 = 0;
    while (x > 0) {
        bits += 1;
        x &= x - 1;
    }
    return bits;
}

fn countReflections(allocator: Allocator, pattern: []const []const u8) !Reflection {
    const m = pattern.len;
    const n = pattern[0].len;

    var row = ArrayList(u64).init(allocator);
    defer row.deinit();
    for (pattern) |line| {
        var row_mask: u64 = 0;
        for (line) |p| {
            switch (p) {
                '.' => {
                    row_mask = row_mask * 2;
                },
                '#' => {
                    row_mask = row_mask * 2 + 1;
                },
                else => unreachable,
            }
        }
        try row.append(row_mask);
    }

    for (1..m) |i| {
        var l: usize = i;
        var r: usize = i;
        while (l > 0 and r < m and row.items[l - 1] == row.items[r]) {
            l -= 1;
            r += 1;
        }
        if (l == 0 or r == m) {
            return Reflection{ .line = .horizontal, .count = i };
        }
    }

    var col = ArrayList(u64).init(allocator);
    defer col.deinit();
    for (0..n) |j| {
        var col_mask: u64 = 0;
        for (0..m) |i| {
            switch (pattern[i][j]) {
                '.' => {
                    col_mask = col_mask * 2;
                },
                '#' => {
                    col_mask = col_mask * 2 + 1;
                },
                else => unreachable,
            }
        }
        try col.append(col_mask);
    }

    for (1..n) |i| {
        var l: usize = i;
        var r: usize = i;
        while (l > 0 and r < n and col.items[l - 1] == col.items[r]) {
            l -= 1;
            r += 1;
        }
        if (l == 0 or r == n) {
            return Reflection{ .line = .vertical, .count = i };
        }
    }

    unreachable;
}

fn countSmudgeReflections(allocator: Allocator, pattern: []const []const u8) !Reflection {
    const m = pattern.len;
    const n = pattern[0].len;

    var row = ArrayList(u64).init(allocator);
    defer row.deinit();
    for (pattern) |line| {
        var row_mask: u64 = 0;
        for (line) |p| {
            switch (p) {
                '.' => {
                    row_mask = row_mask * 2;
                },
                '#' => {
                    row_mask = row_mask * 2 + 1;
                },
                else => unreachable,
            }
        }
        try row.append(row_mask);
    }

    for (1..m) |i| {
        var l: usize = i;
        var r: usize = i;
        var smudge: i32 = 0;
        while (l > 0 and r < m) {
            if (row.items[l - 1] == row.items[r]) {
                l -= 1;
                r += 1;
            } else if (smudge == 0 and countBits(row.items[l - 1] ^ row.items[r]) == 1) {
                smudge += 1;
                l -= 1;
                r += 1;
            } else {
                break;
            }
        }
        if (smudge == 1 and (l == 0 or r == m)) {
            return Reflection{ .line = .horizontal, .count = i };
        }
    }

    var col = ArrayList(u64).init(allocator);
    defer col.deinit();
    for (0..n) |j| {
        var col_mask: u64 = 0;
        for (0..m) |i| {
            switch (pattern[i][j]) {
                '.' => {
                    col_mask = col_mask * 2;
                },
                '#' => {
                    col_mask = col_mask * 2 + 1;
                },
                else => unreachable,
            }
        }
        try col.append(col_mask);
    }

    for (1..n) |i| {
        var l: usize = i;
        var r: usize = i;
        var smudge: i32 = 0;
        while (l > 0 and r < n) {
            if (col.items[l - 1] == col.items[r]) {
                l -= 1;
                r += 1;
            } else if (smudge == 0 and countBits(col.items[l - 1] ^ col.items[r]) == 1) {
                l -= 1;
                r += 1;
                smudge += 1;
            } else {
                break;
            }
        }
        if (smudge == 1 and (l == 0 or r == n)) {
            return Reflection{ .line = .vertical, .count = i };
        }
    }

    return try countReflections(allocator, pattern);
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var pattern = ArrayList([]const u8).init(allocator);
    defer pattern.deinit();

    var rows1: usize = 0;
    var cols1: usize = 0;

    var rows2: usize = 0;
    var cols2: usize = 0;

    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |line| {
        if (line.len == 0) {
            const ref1 = try countReflections(allocator, pattern.items);
            const ref2 = try countSmudgeReflections(allocator, pattern.items);

            switch (ref1.line) {
                .vertical => {
                    cols1 += ref1.count;
                },
                .horizontal => {
                    rows1 += ref1.count;
                },
            }
            switch (ref2.line) {
                .vertical => {
                    cols2 += ref2.count;
                },
                .horizontal => {
                    rows2 += ref2.count;
                },
            }

            pattern.clearAndFree();
            continue;
        }
        try pattern.append(line);
    }

    const part1 = cols1 + rows1 * 100;
    const part2 = cols2 + rows2 * 100;

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}
