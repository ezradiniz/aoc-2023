const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;

const Grid = struct {
    grid: ArrayList(ArrayList(u8)),
    m: usize,
    n: usize,

    fn init(alloc: Allocator, input: []const u8) !Grid {
        const grid = try parseGrid(alloc, input);
        return Grid{ .grid = grid, .m = grid.items.len, .n = grid.items[0].items.len };
    }

    pub fn deinit(self: Grid) void {
        for (self.grid.items) |item| {
            item.deinit();
        }
        self.grid.deinit();
    }

    pub fn get(self: Grid, i: usize, j: usize) u8 {
        return self.grid.items[i].items[j];
    }

    pub fn set(self: Grid, i: usize, j: usize, ch: u8) void {
        self.grid.items[i].items[j] = ch;
    }

    fn parseGrid(allocator: Allocator, input: []const u8) !ArrayList(ArrayList(u8)) {
        var grid = ArrayList(ArrayList(u8)).init(allocator);
        var it = std.mem.tokenizeAny(u8, input, "\n");
        while (it.next()) |line| {
            var row = ArrayList(u8).init(allocator);
            try row.appendSlice(line);
            try grid.append(row);
        }
        return grid;
    }
};

const Platform = struct {
    alloc: Allocator,
    grid: Grid,
    m: usize,
    n: usize,

    pub fn init(alloc: Allocator, grid: Grid) Platform {
        return Platform{ .alloc = alloc, .grid = grid, .m = grid.m, .n = grid.n };
    }

    pub fn spinCycle(self: *Platform, cycles: usize) !void {
        var snapshots = ArrayList(ArrayList(u8)).init(self.alloc);
        defer {
            for (snapshots.items) |item| {
                item.deinit();
            }
            snapshots.deinit();
        }
        for (0..cycles) |_| {
            const snapshot = try self.generateSnapshot();
            var restored = false;
            if (indexOf(snapshots, snapshot.items)) |i| {
                const idx = @mod(cycles - i, snapshots.items.len - i) + i;
                self.restoreSnapshot(snapshots.items[idx].items);
                restored = true;
            }
            try snapshots.append(snapshot);
            if (restored) {
                break;
            }
            self.rollToNorth();
            self.rollToWest();
            self.rollToSouth();
            self.rollToEast();
        }
    }

    fn restoreSnapshot(self: *Platform, snapshot: []const u8) void {
        var it = std.mem.tokenizeAny(u8, snapshot, ",");
        var i: usize = 0;
        while (it.next()) |row| : (i += 1) {
            for (row, 0..) |val, j| {
                self.grid.set(i, j, val);
            }
        }
    }

    fn generateSnapshot(self: *Platform) !ArrayList(u8) {
        var snapshot = ArrayList(u8).init(self.alloc);
        for (self.grid.grid.items) |row| {
            try snapshot.appendSlice(row.items);
            try snapshot.append(',');
        }
        return snapshot;
    }

    fn setRow(self: *Platform, row: usize, start: usize, end: usize, chr: u8) void {
        for (start..end + 1) |col| {
            self.grid.set(row, col, chr);
        }
    }

    fn setCol(self: *Platform, col: usize, start: usize, end: usize, chr: u8) void {
        for (start..end + 1) |row| {
            self.grid.set(row, col, chr);
        }
    }

    pub fn rollToNorth(self: *Platform) void {
        for (0..self.n) |j| {
            var start: usize = 0;
            var count: usize = 0;
            for (0..self.m) |i| {
                if (self.grid.get(i, j) == 'O') {
                    self.grid.set(i, j, '.');
                    count += 1;
                } else if (self.grid.get(i, j) == '#') {
                    if (count > 0) {
                        self.setCol(j, start, start + count - 1, 'O');
                    }
                    start = i + 1;
                    count = 0;
                }
            }
            if (count > 0) {
                self.setCol(j, start, start + count - 1, 'O');
            }
        }
    }

    pub fn rollToWest(self: *Platform) void {
        for (0..self.m) |i| {
            var start: usize = 0;
            var count: usize = 0;
            for (0..self.n) |j| {
                if (self.grid.get(i, j) == 'O') {
                    self.grid.set(i, j, '.');
                    count += 1;
                } else if (self.grid.get(i, j) == '#') {
                    if (count > 0) {
                        self.setRow(i, start, start + count - 1, 'O');
                    }
                    start = j + 1;
                    count = 0;
                }
            }
            if (count > 0) {
                self.setRow(i, start, start + count - 1, 'O');
            }
        }
    }

    pub fn rollToSouth(self: *Platform) void {
        for (0..self.n) |j| {
            var start: usize = 0;
            var count: usize = 0;
            for (0..self.m) |i| {
                if (self.grid.get(i, j) == 'O') {
                    self.grid.set(i, j, '.');
                    count += 1;
                } else if (self.grid.get(i, j) == '#') {
                    if (count > 0) {
                        self.setCol(j, i - count, i - 1, 'O');
                    }
                    start = i + 1;
                    count = 0;
                }
            }
            if (count > 0) {
                self.setCol(j, self.m - count, self.m - 1, 'O');
            }
        }
    }

    pub fn rollToEast(self: *Platform) void {
        for (0..self.m) |i| {
            var start: usize = 0;
            var count: usize = 0;
            for (0..self.n) |j| {
                if (self.grid.get(i, j) == 'O') {
                    self.grid.set(i, j, '.');
                    count += 1;
                } else if (self.grid.get(i, j) == '#') {
                    if (count > 0) {
                        self.setRow(i, j - count, j - 1, 'O');
                    }
                    start = j + 1;
                    count = 0;
                }
            }
            if (count > 0) {
                self.setRow(i, self.n - count, self.n - 1, 'O');
            }
        }
    }

    pub fn countTotalLoad(self: *Platform) usize {
        var load: usize = 0;
        for (0..self.m) |i| {
            for (0..self.n) |j| {
                if (self.grid.get(i, j) == 'O') {
                    load += (self.m - i);
                }
            }
        }
        return load;
    }
};

fn indexOf(arr: ArrayList(ArrayList(u8)), target: []const u8) ?usize {
    for (arr.items, 0..) |inner, i| {
        if (std.mem.eql(u8, inner.items, target)) {
            return i;
        }
    }
    return null;
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const grid1 = try Grid.init(allocator, input);
    defer grid1.deinit();

    const grid2 = try Grid.init(allocator, input);
    defer grid2.deinit();

    var platform1 = Platform.init(allocator, grid1);
    platform1.rollToNorth();
    const part1 = platform1.countTotalLoad();

    var platform2 = Platform.init(allocator, grid2);
    try platform2.spinCycle(1000000000);
    const part2 = platform2.countTotalLoad();

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}

test "sample - part 01" {
    const input = @embedFile("sample.txt");
    const test_allocator = std.testing.allocator;

    const grid = try Grid.init(test_allocator, input);
    defer grid.deinit();

    var platform = Platform.init(test_allocator, grid);
    platform.rollToNorth();

    const total_load = platform.countTotalLoad();
    try std.testing.expectEqual(total_load, 136);
}

test "sample - part 02" {
    const input = @embedFile("sample.txt");
    const test_allocator = std.testing.allocator;

    const grid = try Grid.init(test_allocator, input);
    defer grid.deinit();

    var platform = Platform.init(test_allocator, grid);
    try platform.spinCycle(1000000000);

    const total_load = platform.countTotalLoad();
    try std.testing.expectEqual(total_load, 64);
}
