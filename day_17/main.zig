const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const PriorityQueue = std.PriorityQueue;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;

const inf = std.math.maxInt(u64);

const Dir = enum(u8) {
    top,
    right,
    bottom,
    left,

    pub fn move(self: Dir) [2]Dir {
        return switch (self) {
            .top => [_]Dir{
                Dir.right,
                Dir.left,
            },
            .right => [_]Dir{
                Dir.top,
                Dir.bottom,
            },
            .bottom => [_]Dir{
                Dir.right,
                Dir.left,
            },
            .left => [_]Dir{
                Dir.bottom,
                Dir.top,
            },
        };
    }
};

const velocity = [_][2]i32{
    [_]i32{ -1, 0 }, // top
    [_]i32{ 0, 1 }, // right
    [_]i32{ 1, 0 }, // bottom
    [_]i32{ 0, -1 }, // left
};

const Block = struct {
    pos: Pos,
    loss: u64 = inf,

    pub fn compare(_: void, a: Block, b: Block) std.math.Order {
        if (a.loss <= b.loss) return .lt;
        return .gt;
    }
};

const Pos = struct {
    x: i32,
    y: i32,
    dir: Dir,
    moves: usize = 1,

    pub fn is_inside_map(self: Pos, m: usize, n: usize) bool {
        return self.x >= 0 and self.x < m and self.y >= 0 and self.y < n;
    }
};

fn getMinHeatLoss(allocator: Allocator, map: []const []const u8, min_moves: usize, max_moves: usize) !u64 {
    const m = map.len;
    const n = map[0].len;

    var heat_loss = AutoHashMap(Pos, u64).init(allocator);
    defer heat_loss.deinit();
    var queue = PriorityQueue(Block, void, Block.compare).init(allocator, {});
    defer queue.deinit();

    try queue.add(Block{ .pos = Pos{ .x = 0, .y = 1, .dir = Dir.right, .moves = 1 }, .loss = 0 });
    try heat_loss.put(Pos{ .x = 0, .y = 1, .dir = Dir.right, .moves = 1 }, 0);
    try queue.add(Block{ .pos = Pos{ .x = 1, .y = 0, .dir = Dir.bottom, .moves = 1 }, .loss = 0 });
    try heat_loss.put(Pos{ .x = 1, .y = 0, .dir = Dir.bottom, .moves = 1 }, 0);

    while (queue.len > 0) {
        const block = queue.remove();
        const loss = map[@as(usize, @intCast(block.pos.x))][@as(usize, @intCast(block.pos.y))] - '0';

        if (block.pos.x == m - 1 and block.pos.y == n - 1) {
            return block.loss + loss;
        }

        if (block.pos.moves >= min_moves) {
            for (block.pos.dir.move()) |new_dir| {
                const vel = velocity[@intFromEnum(new_dir)];
                const new_block = Block{ .pos = Pos{ .x = block.pos.x + vel[0], .y = block.pos.y + vel[1], .dir = new_dir }, .loss = block.loss + loss };
                if (!new_block.pos.is_inside_map(m, n)) continue;
                const cur_loss = heat_loss.get(new_block.pos) orelse inf;
                if (new_block.loss < cur_loss) {
                    try heat_loss.put(new_block.pos, new_block.loss);
                    try queue.add(new_block);
                }
            }
        }

        if (block.pos.moves < max_moves) {
            const vel = velocity[@intFromEnum(block.pos.dir)];
            const new_block = Block{ .pos = Pos{ .x = block.pos.x + vel[0], .y = block.pos.y + vel[1], .dir = block.pos.dir, .moves = block.pos.moves + 1 }, .loss = block.loss + loss };
            if (!new_block.pos.is_inside_map(m, n)) continue;
            const cur_loss = heat_loss.get(new_block.pos) orelse inf;
            if (new_block.loss < cur_loss) {
                try heat_loss.put(new_block.pos, new_block.loss);
                try queue.add(new_block);
            }
        }
    }

    return 0;
}

fn parseMap(allocator: Allocator, input: []const u8) !ArrayList([]const u8) {
    var map = ArrayList([]const u8).init(allocator);
    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        try map.append(line);
    }
    return map;
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const map = try parseMap(allocator, input);
    defer map.deinit();

    const part1 = try getMinHeatLoss(allocator, map.items, 0, 3);
    const part2 = try getMinHeatLoss(allocator, map.items, 4, 10);

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}

test "sample - part 01" {
    const input = @embedFile("sample.txt");
    const testing_allocator = std.testing.allocator;
    const map = try parseMap(testing_allocator, input);
    defer map.deinit();
    const loss = try getMinHeatLoss(testing_allocator, map.items, 0, 3);
    try std.testing.expectEqual(loss, 102);
}

test "sample - part 02" {
    const input = @embedFile("sample.txt");
    const testing_allocator = std.testing.allocator;
    const map = try parseMap(testing_allocator, input);
    defer map.deinit();
    const loss = try getMinHeatLoss(testing_allocator, map.items, 4, 10);
    try std.testing.expectEqual(loss, 94);
}
