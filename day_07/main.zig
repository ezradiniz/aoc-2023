const std = @import("std");
const ArrayList = std.ArrayList;
const print = std.debug.print;

// TODO: use a string like "AKQJT98765432"
const labels = [_]u8{ 'A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2' };
const labels_with_joker = [_]u8{ 'A', 'K', 'Q', 'T', '9', '8', '7', '6', '5', '4', '3', '2', 'J' };

const HandType = enum(u8) {
    high_card,
    one_pair,
    two_pair,
    three_of_a_kind,
    full_house,
    four_of_a_kind,
    five_of_a_kind,
};

const Hand = struct {
    cards: []const u8,
    type: HandType,
    bid: usize,
};

// TODO: How to define card_labels as slice?
fn lessThanHands(card_labels: [13]u8, a: Hand, b: Hand) bool {
    if (a.type != b.type) {
        return @intFromEnum(a.type) <= @intFromEnum(b.type);
    }
    for (a.cards, b.cards) |c1, c2| {
        const i = std.mem.indexOfAny(u8, &card_labels, &[_]u8{c1}).?;
        const j = std.mem.indexOfAny(u8, &card_labels, &[_]u8{c2}).?;
        if (i == j) continue;
        return i >= j;
    }
    return true;
}

fn parseHandType(cards_counter: []usize) HandType {
    var freq = [_]usize{0} ** 6;
    for (cards_counter) |c| {
        if (c > 0) {
            freq[c] += 1;
        }
    }
    var i = freq.len;
    while (i > 0) : (i -= 1) {
        if (freq[i - 1] == 0) continue;
        if (i == 6) {
            return .five_of_a_kind;
        } else if (i == 5) {
            return .four_of_a_kind;
        } else if (i == 4) {
            return if (freq[i - 2] > 0) .full_house else .three_of_a_kind;
        } else if (i == 3) {
            return if (freq[i - 1] == 2) .two_pair else .one_pair;
        }
    }
    return .high_card;
}

fn parseHandType1(cards: []const u8) HandType {
    var counter = [_]usize{0} ** labels.len;
    for (cards) |label| {
        const i = std.mem.indexOfAny(u8, &labels, &[_]u8{label}).?;
        counter[i] += 1;
    }
    return parseHandType(&counter);
}

fn parseHandType2(cards: []const u8) HandType {
    var counter = [_]usize{0} ** labels_with_joker.len;
    var jokers: usize = 0;
    var max_count: usize = 0;
    for (cards) |label| {
        if (label == 'J') {
            jokers += 1;
            continue;
        }
        const i = std.mem.indexOfAny(u8, &labels_with_joker, &[_]u8{label}).?;
        counter[i] += 1;
        max_count = @max(max_count, counter[i]);
    }
    for (counter, 0..) |c, i| {
        if (c == max_count) {
            counter[i] += jokers;
            break;
        }
    }
    return parseHandType(&counter);
}

pub fn main() !void {
    const input = @embedFile("input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var hands1 = ArrayList(Hand).init(allocator);
    defer hands1.deinit();

    var hands2 = ArrayList(Hand).init(allocator);
    defer hands2.deinit();

    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        var li = std.mem.tokenizeAny(u8, line, " ");
        const cards = li.next().?;
        const bid = try std.fmt.parseInt(usize, li.next().?, 10);
        try hands1.append(Hand{
            .cards = cards,
            .type = parseHandType1(cards),
            .bid = bid,
        });
        try hands2.append(Hand{
            .cards = cards,
            .type = parseHandType2(cards),
            .bid = bid,
        });
    }

    std.mem.sort(Hand, hands1.items, labels, lessThanHands);
    std.mem.sort(Hand, hands2.items, labels_with_joker, lessThanHands);

    var part1: usize = 0;
    for (hands1.items, 1..) |hand, rank| {
        part1 += hand.bid * rank;
    }

    var part2: usize = 0;
    for (hands2.items, 1..) |hand, rank| {
        part2 += hand.bid * rank;
    }

    print("part1: {d}\n", .{part1});
    print("part2: {d}\n", .{part2});
}
