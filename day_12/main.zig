const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;

const SpringsAnalyzer = struct {
    allocator: Allocator,
    springs_list: []const u8,
    damaged_list: []const usize,

    pub fn init(allocator: Allocator, springs_list: []const u8, damaged_list: []const usize) SpringsAnalyzer {
        return SpringsAnalyzer{
            .allocator = allocator,
            .springs_list = springs_list,
            .damaged_list = damaged_list,
        };
    }

    pub fn countArrangements(self: SpringsAnalyzer) !u64 {
        var memo = AutoHashMap(Arrangement, u64).init(self.allocator);
        defer memo.deinit();
        return try self.recCount(Arrangement{ .i = 0, .j = 0, .count = 0 }, &memo);
    }

    // TODO: Improve time complexity to (m*n)
    // TODO: Reduce cyclomatic complexity
    // TODO: Implement bottom-up DP alternative
    fn recCount(self: SpringsAnalyzer, arr: Arrangement, memo: *AutoHashMap(Arrangement, u64)) !u64 {
        if (arr.i == self.springs_list.len + 1 and arr.j == self.damaged_list.len) {
            return if (arr.count == 0) 1 else 0;
        }
        if (arr.i == self.springs_list.len + 1) {
            return 0;
        }
        if (memo.get(arr)) |count| {
            return count;
        }
        if (arr.i == self.springs_list.len) {
            var count: u64 = 0;
            if (arr.count > 0) {
                if (arr.j < self.damaged_list.len and self.damaged_list[arr.j] == arr.count) {
                    count += try self.recCount(Arrangement{ .i = arr.i + 1, .j = arr.j + 1, .count = 0 }, memo);
                }
            } else {
                count += try self.recCount(Arrangement{ .i = arr.i + 1, .j = arr.j, .count = arr.count }, memo);
            }
            return count;
        }
        var count: u64 = 0;
        switch (self.springs_list[arr.i]) {
            '.' => {
                if (arr.count > 0) {
                    if (arr.j < self.damaged_list.len and self.damaged_list[arr.j] == arr.count) {
                        count += try self.recCount(Arrangement{ .i = arr.i + 1, .j = arr.j + 1, .count = 0 }, memo);
                    }
                } else {
                    count += try self.recCount(Arrangement{ .i = arr.i + 1, .j = arr.j, .count = arr.count }, memo);
                }
            },
            '?' => {
                count += try self.recCount(Arrangement{ .i = arr.i + 1, .j = arr.j, .count = arr.count + 1 }, memo);
                if (arr.count > 0) {
                    if (arr.j < self.damaged_list.len and self.damaged_list[arr.j] == arr.count) {
                        count += try self.recCount(Arrangement{ .i = arr.i + 1, .j = arr.j + 1, .count = 0 }, memo);
                    }
                } else {
                    count += try self.recCount(Arrangement{ .i = arr.i + 1, .j = arr.j, .count = arr.count }, memo);
                }
            },
            '#' => {
                count += try self.recCount(Arrangement{ .i = arr.i + 1, .j = arr.j, .count = arr.count + 1 }, memo);
            },
            else => unreachable,
        }
        try memo.put(arr, count);
        return count;
    }

    const Arrangement = struct {
        i: usize,
        j: usize,
        count: usize,
    };
};

fn parseRecords(input: []const u8, springsList: *ArrayList(u8), damagedList: *ArrayList(usize)) !void {
    var records = std.mem.tokenizeAny(u8, input, " ");
    try springsList.appendSlice(records.next().?);
    var d_list = std.mem.tokenizeAny(u8, records.next().?, ",");
    while (d_list.next()) |num| {
        try damagedList.append(try std.fmt.parseInt(usize, num, 10));
    }
}

fn unfoldRecords(springsList: *ArrayList(u8), damagedList: *ArrayList(usize)) !void {
    const copies_count = 5;
    const s_len = springsList.items.len;
    for (0..copies_count - 1) |_| {
        try springsList.append('?');
        for (0..s_len) |i| {
            try springsList.append(springsList.items[i]);
        }
    }
    const d_len = damagedList.items.len;
    for (0..copies_count - 1) |_| {
        for (0..d_len) |i| {
            try damagedList.append(damagedList.items[i]);
        }
    }
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var part1: u64 = 0;
    var part2: u64 = 0;

    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        var springsList = ArrayList(u8).init(allocator);
        defer springsList.deinit();
        var damagedList = ArrayList(usize).init(allocator);
        defer damagedList.deinit();

        try parseRecords(line, &springsList, &damagedList);

        var analyzer = SpringsAnalyzer.init(allocator, springsList.items, damagedList.items);
        part1 += try analyzer.countArrangements();

        try unfoldRecords(&springsList, &damagedList);

        var analyzer2 = SpringsAnalyzer.init(allocator, springsList.items, damagedList.items);
        part2 += try analyzer2.countArrangements();
    }

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}
