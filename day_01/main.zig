const std = @import("std");
const print = std.debug.print;

const Digit = struct {
    pattern: []const u8,
    value: i32,
};
const digits = [_]Digit{
    .{ .pattern = "1", .value = 1 },
    .{ .pattern = "2", .value = 2 },
    .{ .pattern = "3", .value = 3 },
    .{ .pattern = "4", .value = 4 },
    .{ .pattern = "5", .value = 5 },
    .{ .pattern = "6", .value = 6 },
    .{ .pattern = "7", .value = 7 },
    .{ .pattern = "8", .value = 8 },
    .{ .pattern = "9", .value = 9 },
};
const letters = [_]Digit{
    .{ .pattern = "one", .value = 1 },
    .{ .pattern = "two", .value = 2 },
    .{ .pattern = "three", .value = 3 },
    .{ .pattern = "four", .value = 4 },
    .{ .pattern = "five", .value = 5 },
    .{ .pattern = "six", .value = 6 },
    .{ .pattern = "seven", .value = 7 },
    .{ .pattern = "eight", .value = 8 },
    .{ .pattern = "nine", .value = 9 },
};
const all = digits ++ letters;

fn getDigit(line: []const u8, pattern: []const Digit) i32 {
    var first: i32 = -1;
    var second: i32 = 0;
    var start_idx: usize = 0;

    // TODO: Time complexity could be better
    for (line, 0..) |_, end_idx| {
        for (pattern) |digit| {
            // TODO: what is the best way to find the string?
            if (std.mem.indexOf(u8, line[start_idx .. end_idx + 1], digit.pattern)) |idx| {
                const value = digit.value;
                if (first == -1) {
                    first = value;
                }
                second = value;
                start_idx += idx + 1;
            }
        }
    }
    return first * 10 + second;
}

pub fn main() !void {
    const input = @embedFile("input.txt");
    var part1: i32 = 0;
    var part2: i32 = 0;
    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        part1 += getDigit(line, &digits);
        part2 += getDigit(line, &all);
    }
    print("part1 = {d}\n", .{part1});
    print("part2 = {d}\n", .{part2});
}

test "sample" {
    const input = @embedFile("sample.txt");
    var result: i32 = 0;
    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        result += try getDigit(line, &digits);
    }
    try std.testing.expect(result == 142);
}
