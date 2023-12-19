const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const Dir = enum(u8) {
    up,
    right,
    down,
    left,
};

const Dig = struct {
    dir: Dir,
    dist: i64,
    color: []const u8,
};

const Point = struct {
    x: i64,
    y: i64,
};

fn reversePoints(arr: []Point) void {
    var start: usize = 0;
    var end: usize = arr.len - 1;
    while (start < end) {
        const temp = arr[start];
        arr[start] = arr[end];
        arr[end] = temp;
        start += 1;
        end -= 1;
    }
}

fn abs(x: i64) i64 {
    if (x < 0) {
        return -x;
    }
    return x;
}

fn determinant(a: Point, b: Point) i64 {
    return a.x * b.y - a.y * b.x;
}

fn perimeter(points: []const Point) i64 {
    const n = points.len;
    var i: usize = 0;
    var res: i64 = 0;
    while (i < n) : (i += 1) {
        const j: usize = @mod(i + 1, n);
        const p1 = points[i];
        const p2 = points[j];
        res += abs(p1.x - p2.x) + abs(p1.y - p2.y);
    }
    return res;
}

// https://en.wikipedia.org/wiki/Shoelace_formula
fn shoelace(points: []const Point) i64 {
    const n = points.len;
    var i: usize = 0;
    var res: i64 = 0;
    while (i < n) : (i += 1) {
        const j: usize = @mod(i + 1, n);
        res += determinant(points[i], points[j]);
    }
    return @divFloor(res, 2);
}

// https://en.wikipedia.org/wiki/Pick's_theorem
fn picks(points: []const Point) i64 {
    return shoelace(points) + @divFloor(perimeter(points), 2) - 1;
}

// Initially I was trying to apply `Sweep Line` + `Area of Squares` but I had several edge cases.
// So I had to research and understand the solution with Shoelace + Picks.
fn calcArea(points: []const Point) i64 {
    return picks(points) + 2;
}

fn parseDigPlan(alloc: Allocator, input: []const u8) !ArrayList(Dig) {
    var plan = ArrayList(Dig).init(alloc);
    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        var l = std.mem.tokenizeAny(u8, line, "  ()");
        const dir: Dir = switch (l.next().?[0]) {
            'R' => Dir.right,
            'D' => Dir.down,
            'L' => Dir.left,
            'U' => Dir.up,
            else => unreachable,
        };
        const len: i64 = try std.fmt.parseInt(i64, l.next().?, 10);
        const color: []const u8 = l.next().?;
        const dig = Dig{ .dir = dir, .dist = len, .color = color };
        try plan.append(dig);
    }
    return plan;
}

fn parsePoints1(alloc: Allocator, plan: []const Dig) !ArrayList(Point) {
    var points = ArrayList(Point).init(alloc);
    var prev = Point{ .x = 0, .y = 0 };
    try points.append(prev);
    for (plan) |dig| {
        const cur: Point = switch (dig.dir) {
            .left => Point{ .x = prev.x - dig.dist, .y = prev.y },
            .right => Point{ .x = prev.x + dig.dist, .y = prev.y },
            .up => Point{ .x = prev.x, .y = prev.y + dig.dist },
            .down => Point{ .x = prev.x, .y = prev.y - dig.dist },
        };
        try points.append(cur);
        prev = cur;
    }
    reversePoints(points.items);
    return points;
}

fn parsePoints2(alloc: Allocator, plan: []const Dig) !ArrayList(Point) {
    var points = ArrayList(Point).init(alloc);
    var prev = Point{ .x = 0, .y = 0 };
    try points.append(prev);
    for (plan) |dig| {
        const dist = try std.fmt.parseInt(i64, dig.color[1 .. dig.color.len - 1], 16);
        const cur: Point = switch (dig.color[dig.color.len - 1]) {
            '2' => Point{ .x = prev.x - dist, .y = prev.y },
            '0' => Point{ .x = prev.x + dist, .y = prev.y },
            '3' => Point{ .x = prev.x, .y = prev.y + dist },
            '1' => Point{ .x = prev.x, .y = prev.y - dist },
            else => unreachable,
        };
        try points.append(cur);
        prev = cur;
    }
    reversePoints(points.items);
    return points;
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const plan = try parseDigPlan(allocator, input);
    defer plan.deinit();

    const points1 = try parsePoints1(allocator, plan.items);
    defer points1.deinit();

    const points2 = try parsePoints2(allocator, plan.items);
    defer points2.deinit();

    const part1 = calcArea(points1.items);
    const part2 = calcArea(points2.items);

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}
