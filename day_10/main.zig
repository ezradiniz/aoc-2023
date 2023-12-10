const std = @import("std");
const Allocator = std.mem.Allocator;
const ComptimeStringMap = std.ComptimeStringMap;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const print = std.debug.print;

const Pos = struct {
    x: usize,
    y: usize,
};

const Start = struct {
    x: i32,
    y: i32,
    t: []const u8,
};

fn appendQueue(queue: *ArrayList(Pos), dirs: []const [2]i32, dist: *AutoHashMap(Pos, i32), m: usize, n: usize, x: usize, y: usize) !void {
    const cur_dist = dist.get(Pos{ .x = x, .y = y }) orelse 0;
    for (dirs) |d| {
        const dx = d[0];
        const dy = d[1];
        const nx: i32 = @as(i32, @intCast(x)) + dx;
        const ny: i32 = @as(i32, @intCast(y)) + dy;
        if (nx < 0 or nx >= m or ny < 0 or ny >= n) {
            continue;
        }
        const new_x = @as(usize, @intCast(nx));
        const new_y = @as(usize, @intCast(ny));
        const nxt_dist = dist.get(Pos{ .x = new_x, .y = new_y }) orelse std.math.maxInt(i32);
        // print("({d},{d}) -> ({d},{d}) | {d} -> {d}\n", .{ x, y, new_x, new_y, cur_dist, nxt_dist });
        if (nxt_dist > cur_dist + 1) {
            try queue.append(Pos{ .x = new_x, .y = new_y });
            try dist.put(Pos{ .x = new_x, .y = new_y }, cur_dist + 1);
        }
    }
}

fn findMaxDist(alloc: Allocator, grid: [][]const u8, start_x: usize, start_y: usize) !i32 {
    const m = grid.len;
    const n = grid[0].len;
    var dist = AutoHashMap(Pos, i32).init(alloc);
    defer dist.deinit();
    var queue = ArrayList(Pos).init(alloc);
    defer queue.deinit();
    try queue.append(.{ .x = start_x, .y = start_y });
    try dist.put(Pos{ .x = start_x, .y = start_y }, 0);
    var i: usize = 0;
    while (i < queue.items.len) {
        const len = queue.items.len;
        while (i < len) : (i += 1) {
            const pos = queue.items[i];
            const x = pos.x;
            const y = pos.y;
            const cur = grid[x][y];
            // print("cur: ({d},{d}) - {c}\n", .{ x, y, cur });
            switch (cur) {
                '|' => {
                    const dirs = [_][2]i32{ [2]i32{ 1, 0 }, [2]i32{ -1, 0 } };
                    try appendQueue(&queue, &dirs, &dist, m, n, x, y);
                },
                '-' => {
                    const dirs = [_][2]i32{ [2]i32{ 0, 1 }, [2]i32{ 0, -1 } };
                    try appendQueue(&queue, &dirs, &dist, m, n, x, y);
                },
                'L' => {
                    const dirs = [_][2]i32{ [2]i32{ -1, 0 }, [2]i32{ 0, 1 } };
                    try appendQueue(&queue, &dirs, &dist, m, n, x, y);
                },
                'J' => {
                    const dirs = [_][2]i32{ [2]i32{ -1, 0 }, [2]i32{ 0, -1 } };
                    try appendQueue(&queue, &dirs, &dist, m, n, x, y);
                },
                '7' => {
                    const dirs = [_][2]i32{ [2]i32{ 1, 0 }, [2]i32{ 0, -1 } };
                    try appendQueue(&queue, &dirs, &dist, m, n, x, y);
                },
                'F' => {
                    const dirs = [_][2]i32{ [2]i32{ 1, 0 }, [2]i32{ 0, 1 } };
                    try appendQueue(&queue, &dirs, &dist, m, n, x, y);
                },
                'S' => {
                    const s_dirs = [_]Start{
                        Start{ .x = -1, .y = 0, .t = "|LJ7F" },
                        Start{ .x = 1, .y = 0, .t = "|LJ7F" },
                        Start{ .x = 0, .y = 1, .t = "-LJ7F" },
                        Start{ .x = 0, .y = -1, .t = "-LJ7F" },
                    };
                    for (s_dirs) |d| {
                        const dx = d.x;
                        const dy = d.y;
                        const nx: i32 = @as(i32, @intCast(x)) + dx;
                        const ny: i32 = @as(i32, @intCast(y)) + dy;
                        if (nx < 0 or nx >= m or ny < 0 or ny >= n) {
                            continue;
                        }
                        const new_x = @as(usize, @intCast(nx));
                        const new_y = @as(usize, @intCast(ny));
                        if (std.mem.indexOfScalar(u8, d.t, grid[new_x][new_y])) |_| {
                            //const dirs = [_][2]i32{ [2]i32{ -1, 0 }, [2]i32{ 1, 0 } };
                            // print("{d},{d} - {c}\n", .{ d.x, d.y, grid[new_x][new_y] });
                            try appendQueue(&queue, &[_][2]i32{[2]i32{ d.x, d.y }}, &dist, m, n, x, y);
                        }
                    }
                },
                else => unreachable,
            }
        }
    }
    var max_dist: i32 = 0;
    var dist_it = dist.valueIterator();
    while (dist_it.next()) |d| {
        max_dist = @max(max_dist, d.*);
    }
    return max_dist;
}

fn countEnclosedTiles(alloc: Allocator, grid: [][]const u8, start_x: usize, start_y: usize) !i32 {
    const m = grid.len;
    const n = grid[0].len;
    var pipes = AutoHashMap(Pos, void).init(alloc);
    defer pipes.deinit();
    var dist = AutoHashMap(Pos, i32).init(alloc);
    defer dist.deinit();
    var queue = ArrayList(Pos).init(alloc);
    defer queue.deinit();
    try queue.append(.{ .x = start_x, .y = start_y });
    try dist.put(Pos{ .x = start_x, .y = start_y }, 0);
    var i: usize = 0;
    while (i < queue.items.len) {
        const len = queue.items.len;
        while (i < len) : (i += 1) {
            const pos = queue.items[i];
            const x = pos.x;
            const y = pos.y;
            const cur = grid[x][y];
            try pipes.put(pos, {});
            // print("cur: ({d},{d}) - {c}\n", .{ x, y, cur });
            switch (cur) {
                '|' => {
                    const dirs = [_][2]i32{ [2]i32{ 1, 0 }, [2]i32{ -1, 0 } };
                    try appendQueue(&queue, &dirs, &dist, m, n, x, y);
                },
                '-' => {
                    const dirs = [_][2]i32{ [2]i32{ 0, 1 }, [2]i32{ 0, -1 } };
                    try appendQueue(&queue, &dirs, &dist, m, n, x, y);
                },
                'L' => {
                    const dirs = [_][2]i32{ [2]i32{ -1, 0 }, [2]i32{ 0, 1 } };
                    try appendQueue(&queue, &dirs, &dist, m, n, x, y);
                },
                'J' => {
                    const dirs = [_][2]i32{ [2]i32{ -1, 0 }, [2]i32{ 0, -1 } };
                    try appendQueue(&queue, &dirs, &dist, m, n, x, y);
                },
                '7' => {
                    const dirs = [_][2]i32{ [2]i32{ 1, 0 }, [2]i32{ 0, -1 } };
                    try appendQueue(&queue, &dirs, &dist, m, n, x, y);
                },
                'F' => {
                    const dirs = [_][2]i32{ [2]i32{ 1, 0 }, [2]i32{ 0, 1 } };
                    try appendQueue(&queue, &dirs, &dist, m, n, x, y);
                },
                'S' => {
                    const s_dirs = [_]Start{
                        Start{ .x = -1, .y = 0, .t = "|LJ7F" },
                        Start{ .x = 1, .y = 0, .t = "|LJ7F" },
                        Start{ .x = 0, .y = 1, .t = "-LJ7F" },
                        Start{ .x = 0, .y = -1, .t = "-LJ7F" },
                    };
                    for (s_dirs) |d| {
                        const dx = d.x;
                        const dy = d.y;
                        const nx: i32 = @as(i32, @intCast(x)) + dx;
                        const ny: i32 = @as(i32, @intCast(y)) + dy;
                        if (nx < 0 or nx >= m or ny < 0 or ny >= n) {
                            continue;
                        }
                        const new_x = @as(usize, @intCast(nx));
                        const new_y = @as(usize, @intCast(ny));
                        if (std.mem.indexOfScalar(u8, d.t, grid[new_x][new_y])) |_| {
                            //const dirs = [_][2]i32{ [2]i32{ -1, 0 }, [2]i32{ 1, 0 } };
                            // print("{d},{d} - {c}\n", .{ d.x, d.y, grid[new_x][new_y] });
                            try appendQueue(&queue, &[_][2]i32{[2]i32{ d.x, d.y }}, &dist, m, n, x, y);
                        }
                    }
                },
                else => unreachable,
            }
        }
    }

    // Reference: https://en.wikipedia.org/wiki/Point_in_polygon
    var result: i32 = 0;
    for (0..m) |x| {
        var prev: u8 = ' ';
        var count: i32 = 0;
        var is_inside: bool = false;
        for (0..n) |y| {
            if (pipes.contains(Pos{ .x = x, .y = y })) {
                const cur = grid[x][y];
                if (cur == '-') continue;
                if (!((cur == 'J' and prev == 'F') or (cur == '7' and prev == 'L'))) {
                    count += 1;
                }
                prev = cur;
                is_inside = @mod(count, 2) == 1;
            } else {
                if (is_inside) {
                    result += 1;
                }
            }
        }
    }
    return result;
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var grid = ArrayList([]const u8).init(alloc);
    defer grid.deinit();

    var start_x: usize = undefined;
    var start_y: usize = undefined;

    var it = std.mem.tokenizeAny(u8, input, "\n");
    var i: usize = 0;
    while (it.next()) |line| : (i += 1) {
        try grid.append(line);
        for (line, 0..) |ch, j| {
            if (ch == 'S') {
                start_x = i;
                start_y = j;
            }
        }
    }

    const part1 = try findMaxDist(alloc, grid.items, start_x, start_y);
    const part2 = try countEnclosedTiles(alloc, grid.items, start_x, start_y);

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}
