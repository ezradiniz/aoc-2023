const std = @import("std");
const StringHashMap = std.StringHashMap;
const print = std.debug.print;

const Node = struct {
    left: []const u8,
    right: []const u8,
};

fn countMySteps(map: StringHashMap(Node), instructions: []const u8) u64 {
    var count: u64 = 0;
    const start = "AAA";
    const end = "ZZZ";
    var cur: []const u8 = start;
    var i: usize = 0;
    while (true) : (i = @mod(i + 1, instructions.len)) {
        if (std.mem.eql(u8, cur, end)) {
            break;
        }
        const node = map.get(cur).?;
        const inst = instructions[i];
        if (inst == 'L') {
            cur = node.left;
        } else {
            cur = node.right;
        }
        count += 1;
    }
    return count;
}

fn countGhostSteps(map: StringHashMap(Node), instructions: []const u8) u64 {
    var count: u64 = 1;
    var it = map.keyIterator();
    while (it.next()) |key| {
        if (std.mem.endsWith(u8, key.*, "A")) {
            var cur: []const u8 = key.*;
            var steps: u64 = 0;
            var i: usize = 0;
            while (true) : (i = @mod(i + 1, instructions.len)) {
                if (std.mem.endsWith(u8, cur, "Z")) {
                    break;
                }
                const node = map.get(cur).?;
                const inst = instructions[i];
                if (inst == 'L') {
                    cur = node.left;
                } else {
                    cur = node.right;
                }
                steps += 1;
            }
            // NOTE: lcm(a,b) = (a*b)/gcd(a,b)
            count = (count * steps) / std.math.gcd(count, steps);
        }
    }
    return count;
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var map = StringHashMap(Node).init(alloc);
    defer map.deinit();

    var it = std.mem.tokenizeAny(u8, input, "\n");

    const instructions = it.next().?;

    while (it.next()) |line| {
        var el = std.mem.tokenizeAny(u8, line, "= ,()");
        const cur = el.next().?;
        const left = el.next().?;
        const right = el.next().?;
        try map.put(cur, Node{
            .left = left,
            .right = right,
        });
    }

    const part1 = countMySteps(map, instructions);
    const part2 = countGhostSteps(map, instructions);

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}
