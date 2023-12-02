const std = @import("std");
const print = std.debug.print;

const Cube = struct {
    red: usize = 0,
    green: usize = 0,
    blue: usize = 0,
};

fn max(a: usize, b: usize) usize {
    if (a > b) {
        return a;
    }
    return b;
}

pub fn main() !void {
    const input = @embedFile("input.txt");
    var it = std.mem.tokenizeAny(u8, input, "\n");

    var part1: usize = 0;
    var part2: usize = 0;

    // TODO: Refactor this parser
    while (it.next()) |line| {
        var game_id: usize = 0;
        var record = std.mem.tokenizeAny(u8, line, ":");
        if (record.next()) |game| {
            var game_it = std.mem.tokenizeAny(u8, game, " ");
            _ = game_it.next();
            if (game_it.next()) |id| {
                game_id = try std.fmt.parseInt(usize, id, 10);
            }
        }
        var cubes2: Cube = .{};
        var is_possible = true;
        if (record.next()) |bags| {
            var bag_it = std.mem.tokenizeAny(u8, bags, ";");
            while (bag_it.next()) |bag| {
                var cubes1: Cube = .{};
                var cubes_it = std.mem.tokenizeAny(u8, bag, ",");
                while (cubes_it.next()) |cube_pair| {
                    var cube_it = std.mem.tokenizeAny(u8, cube_pair, " ");
                    var amount: usize = 0;
                    if (cube_it.next()) |cube_amount| {
                        amount = try std.fmt.parseInt(usize, cube_amount, 10);
                    }
                    var cube = cube_it.next();
                    if (cube) |c| {
                        switch (c[0]) {
                            'r' => {
                                cubes1.red += amount;
                                cubes2.red = max(cubes2.red, amount);
                            },
                            'g' => {
                                cubes1.green += amount;
                                cubes2.green = max(cubes2.green, amount);
                            },
                            'b' => {
                                cubes1.blue += amount;
                                cubes2.blue = max(cubes2.blue, amount);
                            },
                            else => unreachable,
                        }
                    }
                }
                if (cubes1.red > 12 or cubes1.green > 13 or cubes1.blue > 14) {
                    is_possible = false;
                }
            }
        }
        if (is_possible) {
            part1 += game_id;
        }
        part2 += cubes2.blue * cubes2.green * cubes2.red;
    }

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}
