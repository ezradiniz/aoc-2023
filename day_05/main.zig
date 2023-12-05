const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const test_allocator = std.testing.allocator;

const SeedRange = struct {
    start: usize,
    end: usize,
};

fn appendSeeds(arr: *ArrayList(usize), input: []const u8) !void {
    var s = std.mem.tokenizeAny(u8, input, ":");
    _ = s.next();
    var it = std.mem.tokenizeAny(u8, s.next().?, " ");
    while (it.next()) |num| {
        try arr.append(try std.fmt.parseInt(usize, num, 10));
    }
}

fn appendSeedsRange(arr: *ArrayList(SeedRange), input: []const u8) !void {
    var s = std.mem.tokenizeAny(u8, input, ":");
    _ = s.next();
    var it = std.mem.tokenizeAny(u8, s.next().?, " ");
    while (it.next()) |val| {
        const start = try std.fmt.parseInt(usize, val, 10);
        const len = try std.fmt.parseInt(usize, it.next().?, 10);
        try arr.append(SeedRange{
            .start = start,
            .end = start + len - 1,
        });
    }
}

fn findSeedLocation(alloc: Allocator, input: []const u8) !usize {
    var seeds = ArrayList(usize).init(alloc);
    defer seeds.deinit();

    var it = std.mem.splitAny(u8, input, "\n");
    try appendSeeds(&seeds, it.next().?);

    _ = it.next();
    for (0..7) |_| {
        _ = it.next();
        var seen = AutoHashMap(usize, void).init(alloc);
        defer seen.deinit();

        while (it.next()) |line| {
            if (line.len == 0) break;
            var range = std.mem.tokenizeAny(u8, line, " ");
            const dst = try std.fmt.parseInt(usize, range.next().?, 10);
            const src = try std.fmt.parseInt(usize, range.next().?, 10);
            const len = try std.fmt.parseInt(usize, range.next().?, 10);

            for (seeds.items, 0..) |seed, i| {
                if (seen.contains(i)) {
                    continue;
                }
                if (src <= seed and seed < src + len) {
                    seeds.items[i] = dst + (seed - src);
                    try seen.put(i, {});
                }
            }
        }
    }

    var result: usize = std.math.maxInt(usize);
    for (seeds.items) |seed| {
        result = @min(result, seed);
    }
    return result;
}

fn findSeedRangeLocation(alloc: Allocator, input: []const u8) !usize {
    var seeds = ArrayList(SeedRange).init(alloc);
    defer seeds.deinit();

    var it = std.mem.splitAny(u8, input, "\n");
    try appendSeedsRange(&seeds, it.next().?);

    _ = it.next();
    for (0..7) |_| {
        _ = it.next();
        var new_seeds = ArrayList(SeedRange).init(alloc);
        defer new_seeds.deinit();

        while (it.next()) |line| {
            if (line.len == 0) break;
            var range = std.mem.tokenizeAny(u8, line, " ");
            const dst = try std.fmt.parseInt(usize, range.next().?, 10);
            const src = try std.fmt.parseInt(usize, range.next().?, 10);
            const len = try std.fmt.parseInt(usize, range.next().?, 10);

            const range_start = src;
            const range_end = src + len - 1;

            var i: usize = seeds.items.len;
            while (i > 0) : (i -= 1) {
                const seed = seeds.items[i - 1];
                if (range_start <= seed.start and seed.end <= range_end) {
                    try new_seeds.append(SeedRange{
                        .start = dst + (seed.start - range_start),
                        .end = dst + (seed.end - range_start),
                    });
                    _ = seeds.swapRemove(i - 1);
                } else if (seed.start <= range_start and range_start <= seed.end and seed.end <= range_end) {
                    try new_seeds.append(SeedRange{
                        .start = dst,
                        .end = dst + (seed.end - range_start),
                    });
                    const iseed = &seeds.items[i - 1];
                    iseed.*.start = seed.start;
                    iseed.*.end = range_start - 1;
                } else if (range_start <= seed.start and seed.start <= range_end and range_end <= seed.end) {
                    try new_seeds.append(SeedRange{
                        .start = dst + (seed.start - range_start),
                        .end = dst + (range_end - range_start),
                    });
                    const iseed = &seeds.items[i - 1];
                    iseed.*.start = range_end + 1;
                    iseed.*.end = seed.end;
                }
            }
        }

        for (new_seeds.items) |seed| {
            try seeds.append(seed);
        }
    }

    var result: usize = std.math.maxInt(usize);
    for (seeds.items) |seed| {
        result = @min(result, seed.start);
    }
    return result;
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const part1 = try findSeedLocation(alloc, input);
    const part2 = try findSeedRangeLocation(alloc, input);

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}

test "sample - part 1" {
    const input = @embedFile("sample.txt");
    const result = try findSeedLocation(test_allocator, input);
    try std.testing.expect(result == 35);
}

test "sample - part 2" {
    const input = @embedFile("sample.txt");
    const result = try findSeedRangeLocation(test_allocator, input);
    try std.testing.expect(result == 46);
}
