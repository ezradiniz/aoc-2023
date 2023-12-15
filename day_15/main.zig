const std = @import("std");
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const Lens = struct {
    label: []const u8,
    focal_length: usize,
};

const Slots = struct {
    map: StringHashMap(*Node),
    alloc: Allocator,
    len: usize,
    head: ?*Node,

    const Node = struct {
        lens: Lens,
        next: ?*Node = null,
        prev: ?*Node = null,
    };

    pub fn init(alloc: Allocator) Slots {
        return Slots{ .alloc = alloc, .head = null, .len = 0, .map = StringHashMap(*Node).init(alloc) };
    }

    pub fn deinit(self: *Slots) void {
        var cur_node = self.head;
        while (cur_node != null) {
            var nxt_node = cur_node.?.next;
            self.alloc.destroy(cur_node.?);
            cur_node = nxt_node;
            self.len -= 1;
        }
        self.map.deinit();
    }

    pub fn remove(self: *Slots, label: []const u8) void {
        if (self.map.get(label)) |node| {
            if (node.next != null) {
                node.next.?.prev = node.prev;
            }
            if (node.prev != null) {
                node.prev.?.next = node.next;
            }
            if (node == self.head) {
                self.head = self.head.?.next;
            }
            _ = self.map.remove(label);
            self.alloc.destroy(node);
            self.len -= 1;
        }
    }

    pub fn add(self: *Slots, lens: Lens) !void {
        if (self.map.contains(lens.label)) {
            var node = &self.map.get(lens.label).?;
            node.*.lens = lens;
        } else {
            var new_node = try self.alloc.create(Node);
            var cur_head = self.head;
            new_node.lens = lens;
            new_node.prev = null;
            new_node.next = cur_head;
            if (cur_head != null) {
                cur_head.?.prev = new_node;
            }
            self.head = new_node;
            self.len += 1;
            try self.map.put(lens.label, new_node);
        }
    }
};

fn hash(seq: []const u8) usize {
    var cur: usize = 0;
    for (seq) |chr| {
        cur = @mod((cur + chr) * 17, 256);
    }
    return cur;
}

fn sumHashResult(input: []const u8) usize {
    var sum: usize = 0;
    var it = std.mem.tokenizeAny(u8, input, ",\n");
    while (it.next()) |step| {
        sum += hash(step);
    }
    return sum;
}

fn calcFocusingPower(alloc: Allocator, input: []const u8) !usize {
    var boxes: [256]Slots = undefined;
    for (&boxes) |*slots| {
        slots.* = Slots.init(alloc);
    }
    defer {
        for (&boxes) |*slots| {
            slots.deinit();
        }
    }
    var it = std.mem.tokenizeAny(u8, input, ",\n");
    while (it.next()) |seq| {
        if (std.mem.indexOfScalar(u8, seq, '=')) |_| {
            var part = std.mem.tokenizeScalar(u8, seq, '=');
            const label = part.next().?;
            const focal_length = try std.fmt.parseInt(usize, part.next().?, 10);
            var box = &boxes[hash(label)];
            try box.add(Lens{ .label = label, .focal_length = focal_length });
        } else {
            var part = std.mem.tokenizeScalar(u8, seq, '-');
            const label = part.next().?;
            var box = &boxes[hash(label)];
            box.remove(label);
        }
    }
    var power: usize = 0;
    for (&boxes, 1..) |*slots, box| {
        var cur = slots.head;
        var slot = slots.len;
        while (cur != null) : (cur = cur.?.next) {
            power += box * slot * cur.?.lens.focal_length;
            slot -= 1;
        }
    }
    return power;
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const part1 = sumHashResult(input);
    const part2 = try calcFocusingPower(allocator, input);

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}

test "sample - part 01" {
    const input = @embedFile("sample.txt");
    const result = sumHashResult(input);
    try std.testing.expectEqual(result, 1320);
}

test "sample - part 02" {
    const input = @embedFile("sample.txt");
    const result = try calcFocusingPower(std.testing.allocator, input);
    try std.testing.expectEqual(result, 145);
}
