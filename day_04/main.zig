const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var cards_map = std.AutoHashMap(usize, i64).init(allocator);
    defer cards_map.deinit();

    var part1: u64 = 0;
    var part2: i64 = 0;

    var card_number: usize = 1;
    var card_count: i64 = 0;

    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        if (cards_map.get(card_number)) |value| {
            card_count += value;
        }
        var card_it = std.mem.tokenizeAny(u8, line, ":");
        _ = card_it.next();
        if (card_it.next()) |list| {
            var list_it = std.mem.tokenizeAny(u8, list, "|");
            var win_set = std.AutoHashMap(usize, void).init(allocator);
            defer win_set.deinit();
            if (list_it.next()) |wlist| {
                var dig_it = std.mem.tokenizeAny(u8, wlist, " ");
                while (dig_it.next()) |dig| {
                    const nb = try std.fmt.parseInt(usize, dig, 10);
                    try win_set.put(nb, {});
                }
            }
            var matches: u6 = 0;
            if (list_it.next()) |mlist| {
                var dig_it = std.mem.tokenizeAny(u8, mlist, " ");
                while (dig_it.next()) |dig| {
                    const nb = try std.fmt.parseInt(usize, dig, 10);
                    if (win_set.contains(nb)) {
                        matches += 1;
                    }
                }
            }
            const count: i64 = card_count + 1;
            if (matches > 0) {
                part1 += @as(u64, 1) << (matches - 1);
                card_count += count;
                const v = try cards_map.getOrPut(card_number + matches + 1);
                if (v.found_existing) {
                    var value = &v.value_ptr.*;
                    value.* += -count;
                } else {
                    v.value_ptr.* = -count;
                }
            }
            part2 += count;
        }
        card_number += 1;
    }

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}
