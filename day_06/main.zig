const std = @import("std");
const print = std.debug.print;

const Race = struct {
    time: usize,
    distance: usize = 0,
};

fn calcRaces(races: []const Race) usize {
    var result: usize = 1;
    for (races) |race| {
        result *= countWaysToWin(race);
    }
    return result;
}

fn countWaysToWin(race: Race) usize {
    var left: usize = 1;
    var right: usize = 0;
    var lo: usize = 1;
    var hi: usize = race.time;
    // bisect left
    while (lo <= hi) {
        const mid = lo + (hi - lo) / 2;
        const can = (race.time - mid) * mid > race.distance;
        if (can) {
            left = mid;
            hi = mid - 1;
        } else {
            lo = mid + 1;
        }
    }
    lo = left;
    hi = race.time;
    // bisect right
    while (lo <= hi) {
        const mid = lo + (hi - lo) / 2;
        const can = (race.time - mid) * mid > race.distance;
        if (can) {
            right = mid;
            lo = mid + 1;
        } else {
            hi = mid - 1;
        }
    }
    return (right - left + 1);
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var races = std.ArrayList(Race).init(alloc);
    defer races.deinit();

    var line = std.mem.tokenizeAny(u8, input, "\n");

    var total_time: usize = 0;
    var ti = std.mem.tokenizeAny(u8, line.next().?, " ");
    _ = ti.next();
    while (ti.next()) |time| {
        const race = Race{ .time = try std.fmt.parseInt(usize, time, 10) };
        try races.append(race);
        for (time) |d| {
            total_time = total_time * 10 + (d - '0');
        }
    }

    var total_distance: usize = 0;
    var di = std.mem.tokenizeAny(u8, line.next().?, " ");
    _ = di.next();
    for (races.items) |*race| {
        const dist = di.next().?;
        race.distance = try std.fmt.parseInt(usize, dist, 10);
        for (dist) |d| {
            total_distance = total_distance * 10 + (d - '0');
        }
    }

    const part1 = calcRaces(races.items);
    const part2 = calcRaces(&[_]Race{Race{ .distance = total_distance, .time = total_time }});

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}

test "sample - part 01" {
    const races = [_]Race{
        Race{ .time = 7, .distance = 9 },
        Race{ .time = 15, .distance = 40 },
        Race{ .time = 30, .distance = 200 },
    };
    const result = calcRaces(&races);
    try std.testing.expect(result == 288);
}

test "sample - part 02" {
    const races = [_]Race{
        Race{ .time = 71530, .distance = 940200 },
    };
    const result = calcRaces(&races);
    try std.testing.expect(result == 71503);
}
