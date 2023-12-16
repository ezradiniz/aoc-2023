const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const print = std.debug.print;

const Dir = enum(u8) {
    top,
    right,
    bottom,
    left,
};

const Pos = struct {
    row: i32,
    col: i32,
};

const Beam = struct {
    dir: Dir,
    pos: Pos,
};

// TODO: Implement queue without ArrayList
const Queue = struct {
    queue: ArrayList(Beam),
    seen: AutoHashMap(Beam, void),
    pos: usize,

    pub fn init(alloc: Allocator) Queue {
        return Queue{ .pos = 0, .seen = AutoHashMap(Beam, void).init(alloc), .queue = ArrayList(Beam).init(alloc) };
    }

    pub fn deinit(self: *Queue) void {
        self.queue.deinit();
        self.seen.deinit();
    }

    pub fn push(self: *Queue, beam: Beam) !void {
        if (self.seen.contains(beam)) {
            return;
        }
        try self.queue.append(beam);
        try self.seen.put(beam, {});
    }

    pub fn pull(self: *Queue) ?Beam {
        if (self.isEmpty()) {
            return null;
        }
        self.pos += 1;
        return self.queue.items[self.pos - 1];
    }

    pub fn isEmpty(self: Queue) bool {
        return self.queue.items.len - self.pos == 0;
    }
};

// TODO: Refactor this code, I'm too lazy to do that now
fn countEnergizedTiles(alloc: Allocator, grid: []const []const u8, start: Beam) !usize {
    const m = grid.len;
    const n = grid[0].len;
    var queue = Queue.init(alloc);
    defer queue.deinit();
    var path = AutoHashMap(Pos, void).init(alloc);
    defer path.deinit();
    try queue.push(start);
    while (!queue.isEmpty()) {
        const beam = queue.pull().?;
        const tile = grid[@as(usize, @intCast(beam.pos.row))][@as(usize, @intCast(beam.pos.col))];
        try path.put(beam.pos, {});
        switch (tile) {
            '.' => {
                const new_pos: Pos = switch (beam.dir) {
                    .top => Pos{ .row = beam.pos.row - 1, .col = beam.pos.col },
                    .right => Pos{ .row = beam.pos.row, .col = beam.pos.col + 1 },
                    .bottom => Pos{ .row = beam.pos.row + 1, .col = beam.pos.col },
                    .left => Pos{ .row = beam.pos.row, .col = beam.pos.col - 1 },
                };
                if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                    continue;
                }
                const new_beam = Beam{ .dir = beam.dir, .pos = new_pos };
                try queue.push(new_beam);
            },
            '\\' => {
                switch (beam.dir) {
                    .right => {
                        const new_pos = Pos{ .row = beam.pos.row + 1, .col = beam.pos.col };
                        if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                            continue;
                        }
                        const new_beam = Beam{ .dir = Dir.bottom, .pos = new_pos };
                        try queue.push(new_beam);
                    },
                    .bottom => {
                        const new_pos = Pos{ .row = beam.pos.row, .col = beam.pos.col + 1 };
                        if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                            continue;
                        }
                        const new_beam = Beam{ .dir = Dir.right, .pos = new_pos };
                        try queue.push(new_beam);
                    },
                    .left => {
                        const new_pos = Pos{ .row = beam.pos.row - 1, .col = beam.pos.col };
                        if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                            continue;
                        }
                        const new_beam = Beam{ .dir = Dir.top, .pos = new_pos };
                        try queue.push(new_beam);
                    },
                    .top => {
                        const new_pos = Pos{ .row = beam.pos.row, .col = beam.pos.col - 1 };
                        if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                            continue;
                        }
                        const new_beam = Beam{ .dir = Dir.left, .pos = new_pos };
                        try queue.push(new_beam);
                    },
                }
            },
            '/' => {
                switch (beam.dir) {
                    .right => {
                        const new_pos = Pos{ .row = beam.pos.row - 1, .col = beam.pos.col };
                        if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                            continue;
                        }
                        const new_beam = Beam{ .dir = Dir.top, .pos = new_pos };
                        try queue.push(new_beam);
                    },
                    .top => {
                        const new_pos = Pos{ .row = beam.pos.row, .col = beam.pos.col + 1 };
                        if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                            continue;
                        }
                        const new_beam = Beam{ .dir = Dir.right, .pos = new_pos };
                        try queue.push(new_beam);
                    },
                    .left => {
                        const new_pos = Pos{ .row = beam.pos.row + 1, .col = beam.pos.col };
                        if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                            continue;
                        }
                        const new_beam = Beam{ .dir = Dir.bottom, .pos = new_pos };
                        try queue.push(new_beam);
                    },
                    .bottom => {
                        const new_pos = Pos{ .row = beam.pos.row, .col = beam.pos.col - 1 };
                        if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                            continue;
                        }
                        const new_beam = Beam{ .dir = Dir.left, .pos = new_pos };
                        try queue.push(new_beam);
                    },
                }
            },
            '-' => {
                switch (beam.dir) {
                    .right => {
                        var new_pos = Pos{ .row = beam.pos.row, .col = beam.pos.col + 1 };
                        if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                            continue;
                        }
                        const new_beam = Beam{ .dir = beam.dir, .pos = new_pos };
                        try queue.push(new_beam);
                    },
                    .left => {
                        var new_pos = Pos{ .row = beam.pos.row, .col = beam.pos.col - 1 };
                        if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                            continue;
                        }
                        const new_beam = Beam{ .dir = beam.dir, .pos = new_pos };
                        try queue.push(new_beam);
                    },
                    .top, .bottom => {
                        var new_pos = Pos{ .row = beam.pos.row, .col = beam.pos.col + 1 };
                        if (!(new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n)) {
                            const new_beam = Beam{ .dir = Dir.right, .pos = new_pos };
                            try queue.push(new_beam);
                        }
                        new_pos = Pos{ .row = beam.pos.row, .col = beam.pos.col - 1 };
                        if (!(new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n)) {
                            const new_beam = Beam{ .dir = Dir.left, .pos = new_pos };
                            try queue.push(new_beam);
                        }
                    },
                }
            },
            '|' => {
                switch (beam.dir) {
                    .top => {
                        var new_pos = Pos{ .row = beam.pos.row - 1, .col = beam.pos.col };
                        if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                            continue;
                        }
                        const new_beam = Beam{ .dir = beam.dir, .pos = new_pos };
                        try queue.push(new_beam);
                    },
                    .bottom => {
                        var new_pos = Pos{ .row = beam.pos.row + 1, .col = beam.pos.col };
                        if (new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n) {
                            continue;
                        }
                        const new_beam = Beam{ .dir = beam.dir, .pos = new_pos };
                        try queue.push(new_beam);
                    },
                    .left, .right => {
                        var new_pos = Pos{ .row = beam.pos.row + 1, .col = beam.pos.col };
                        if (!(new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n)) {
                            const new_beam = Beam{ .dir = Dir.bottom, .pos = new_pos };
                            try queue.push(new_beam);
                        }
                        new_pos = Pos{ .row = beam.pos.row - 1, .col = beam.pos.col };
                        if (!(new_pos.row < 0 or new_pos.row >= m or new_pos.col < 0 or new_pos.col >= n)) {
                            const new_beam = Beam{ .dir = Dir.top, .pos = new_pos };
                            try queue.push(new_beam);
                        }
                    },
                }
            },
            else => unreachable,
        }
    }
    return path.count();
}

fn countLargestEnergizedTiles(alloc: Allocator, grid: []const []const u8) !usize {
    const m = @as(i32, @intCast(grid.len));
    const n = @as(i32, @intCast(grid[0].len));
    var count: usize = 0;
    var i: i32 = 0;
    while (i < m) : (i += 1) {
        count = @max(count, try countEnergizedTiles(alloc, grid, Beam{ .dir = Dir.left, .pos = Pos{ .row = i, .col = 0 } }));
        count = @max(count, try countEnergizedTiles(alloc, grid, Beam{ .dir = Dir.right, .pos = Pos{ .row = i, .col = n - 1 } }));
    }
    var j: i32 = 0;
    while (j < n) : (j += 1) {
        count = @max(count, try countEnergizedTiles(alloc, grid, Beam{ .dir = Dir.bottom, .pos = Pos{ .row = 0, .col = j } }));
        count = @max(count, try countEnergizedTiles(alloc, grid, Beam{ .dir = Dir.top, .pos = Pos{ .row = m - 1, .col = j } }));
    }
    return count;
}

fn appendGrid(grid: *ArrayList([]const u8), input: []const u8) !void {
    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        try grid.append(line);
    }
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var grid = ArrayList([]const u8).init(allocator);
    defer grid.deinit();

    try appendGrid(&grid, input);

    const part1 = try countEnergizedTiles(allocator, grid.items, Beam{ .dir = Dir.right, .pos = Pos{ .row = 0, .col = 0 } });
    const part2 = try countLargestEnergizedTiles(allocator, grid.items);

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}

test "sample - test 01" {
    const input = @embedFile("sample.txt");
    const allocator = std.testing.allocator;
    var grid = ArrayList([]const u8).init(allocator);
    defer grid.deinit();
    try appendGrid(&grid, input);
    const result = try countEnergizedTiles(allocator, grid.items, Beam{ .dir = Dir.right, .pos = Pos{ .row = 0, .col = 0 } });
    try std.testing.expectEqual(result, 46);
}

test "sample - test 02" {
    const input = @embedFile("sample.txt");
    const allocator = std.testing.allocator;
    var grid = ArrayList([]const u8).init(allocator);
    defer grid.deinit();
    try appendGrid(&grid, input);
    const result = try countLargestEnergizedTiles(allocator, grid.items);
    try std.testing.expectEqual(result, 51);
}
