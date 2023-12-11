const std = @import("std");
const Allocator = std.mem.Allocator;
const ComptimeStringMap = std.ComptimeStringMap;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const print = std.debug.print;

const inf = std.math.maxInt(i32);

const Pos = struct {
    x: usize,
    y: usize,
};

const Dir = struct {
    x: i32,
    y: i32,
};

const StartDir = struct {
    dir: Dir,
    pipes: []const u8,
};

const start_dir = [_]StartDir{
    StartDir{ .dir = Dir{ .x = -1, .y = 0 }, .pipes = "|LJ7F" },
    StartDir{ .dir = Dir{ .x = 1, .y = 0 }, .pipes = "|LJ7F" },
    StartDir{ .dir = Dir{ .x = 0, .y = 1 }, .pipes = "-LJ7F" },
    StartDir{ .dir = Dir{ .x = 0, .y = -1 }, .pipes = "-LJ7F" },
};

const pipes_dir = ComptimeStringMap([2]Dir, .{
    .{ "|", [2]Dir{ Dir{ .x = 1, .y = 0 }, Dir{ .x = -1, .y = 0 } } },
    .{ "-", [2]Dir{ Dir{ .x = 0, .y = 1 }, Dir{ .x = 0, .y = -1 } } },
    .{ "L", [2]Dir{ Dir{ .x = -1, .y = 0 }, Dir{ .x = 0, .y = 1 } } },
    .{ "J", [2]Dir{ Dir{ .x = -1, .y = 0 }, Dir{ .x = 0, .y = -1 } } },
    .{ "7", [2]Dir{ Dir{ .x = 1, .y = 0 }, Dir{ .x = 0, .y = -1 } } },
    .{ "F", [2]Dir{ Dir{ .x = 1, .y = 0 }, Dir{ .x = 0, .y = 1 } } },
});

// TODO: This queue do not free the items on pop
// TODO: Implement a proper Queue
const PipeQueue = struct {
    queue: ArrayList(Pos),
    dist: AutoHashMap(Pos, i32),
    idx: usize,

    pub fn init(alloc: Allocator) PipeQueue {
        return PipeQueue{
            .queue = ArrayList(Pos).init(alloc),
            .dist = AutoHashMap(Pos, i32).init(alloc),
            .idx = 0,
        };
    }

    pub fn append(self: *PipeQueue, pos: Pos, new_dist: i32) !void {
        try self.queue.append(pos);
        try self.dist.put(pos, new_dist);
    }

    pub fn popFront(self: *PipeQueue) ?Pos {
        if (!self.isEmpty()) {
            const pos = self.queue.items[self.idx];
            self.idx += 1;
            return pos;
        }
        return null;
    }

    pub fn getDist(self: *PipeQueue, pos: Pos) i32 {
        return self.dist.get(pos) orelse inf;
    }

    pub fn getMaxDist(self: *PipeQueue) i32 {
        // TODO: Set the max distance in .append
        var max_dist: i32 = 0;
        var dist_it = self.dist.valueIterator();
        while (dist_it.next()) |d| {
            max_dist = @max(max_dist, d.*);
        }
        return max_dist;
    }

    pub fn deinit(self: *PipeQueue) void {
        self.queue.deinit();
        self.dist.deinit();
    }

    pub fn isEmpty(self: *PipeQueue) bool {
        return self.idx >= self.queue.items.len;
    }
};

fn findStarPos(grid: [][]const u8) ?Pos {
    for (grid, 0..) |row, i| {
        for (row, 0..) |val, j| {
            if (val == 'S') {
                return Pos{ .x = i, .y = j };
            }
        }
    }
    return null;
}

// TODO: Avoid unnecessary casting
fn calcNextPos(pos: Pos, dir: Dir, m: usize, n: usize) ?Pos {
    const nx: i32 = @as(i32, @intCast(pos.x)) + dir.x;
    const ny: i32 = @as(i32, @intCast(pos.y)) + dir.y;
    if (nx < 0 or nx >= m or ny < 0 or ny >= n) {
        return null;
    }
    const new_x = @as(usize, @intCast(nx));
    const new_y = @as(usize, @intCast(ny));
    return Pos{ .x = new_x, .y = new_y };
}

fn findMaxDist(alloc: Allocator, grid: [][]const u8) !i32 {
    const m = grid.len;
    const n = grid[0].len;
    var pipe_queue = PipeQueue.init(alloc);
    defer pipe_queue.deinit();
    const start_pos = findStarPos(grid).?;
    try pipe_queue.append(start_pos, 0);
    while (!pipe_queue.isEmpty()) {
        const pos = pipe_queue.popFront().?;
        const cur_dist = pipe_queue.getDist(pos);
        const tile = grid[pos.x][pos.y];
        const tile_key = [_]u8{tile};
        if (pipes_dir.has(&tile_key)) {
            const dirs = pipes_dir.get(&tile_key).?;
            for (dirs) |dir| {
                if (calcNextPos(pos, dir, m, n)) |new_pos| {
                    const new_dist = pipe_queue.getDist(new_pos);
                    if (new_dist > cur_dist + 1) {
                        try pipe_queue.append(new_pos, cur_dist + 1);
                    }
                }
            }
        } else if (tile == 'S') {
            for (start_dir) |sd| {
                if (calcNextPos(pos, sd.dir, m, n)) |new_pos| {
                    const new_tile = grid[new_pos.x][new_pos.y];
                    if (std.mem.indexOfScalar(u8, sd.pipes, new_tile)) |_| {
                        try pipe_queue.append(new_pos, 1);
                    }
                }
            }
        }
    }
    return pipe_queue.getMaxDist();
}

fn countEnclosedTiles(alloc: Allocator, grid: [][]const u8) !i32 {
    const m = grid.len;
    const n = grid[0].len;
    var pipe_queue = PipeQueue.init(alloc);
    defer pipe_queue.deinit();
    const start_pos = findStarPos(grid).?;
    try pipe_queue.append(start_pos, 0);
    var pipes_set = AutoHashMap(Pos, void).init(alloc);
    defer pipes_set.deinit();
    while (!pipe_queue.isEmpty()) {
        const pos = pipe_queue.popFront().?;
        const cur_dist = pipe_queue.getDist(pos);
        const tile = grid[pos.x][pos.y];
        const tile_key = [_]u8{tile};
        try pipes_set.put(pos, {});
        if (pipes_dir.has(&tile_key)) {
            const dirs = pipes_dir.get(&tile_key).?;
            for (dirs) |dir| {
                if (calcNextPos(pos, dir, m, n)) |new_pos| {
                    const new_dist = pipe_queue.getDist(new_pos);
                    if (new_dist > cur_dist + 1) {
                        try pipe_queue.append(new_pos, cur_dist + 1);
                    }
                }
            }
        } else if (tile == 'S') {
            for (start_dir) |sd| {
                if (calcNextPos(pos, sd.dir, m, n)) |new_pos| {
                    const new_tile = grid[new_pos.x][new_pos.y];
                    if (std.mem.indexOfScalar(u8, sd.pipes, new_tile)) |_| {
                        try pipe_queue.append(new_pos, 1);
                    }
                }
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
            const cur = grid[x][y];
            if (pipes_set.contains(Pos{ .x = x, .y = y })) { // Main
                // NOTE: i.e line ---
                if (cur == '-') continue;
                // NOTE: i.e ] [
                if (!((prev == 'F' and cur == 'J') or (prev == 'L' and cur == '7'))) {
                    count += 1;
                }
                is_inside = @mod(count, 2) == 1;
            } else { // Other Tiles
                if (is_inside) {
                    result += 1;
                }
            }
            prev = cur;
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

    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        try grid.append(line);
    }

    const part1 = try findMaxDist(alloc, grid.items);
    const part2 = try countEnclosedTiles(alloc, grid.items);

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}

// TODO: Add tests
