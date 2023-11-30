#!/bin/bash

set -e

template=$(cat <<EOF
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const input = @embedFile("sample.txt");
    var it = std.mem.tokenizeAny(u8, input, "\n");
    while (it.next()) |line| {
        print("{s}\n", .{line});
    }
}
EOF
)

day="$1"

directory=$(printf "day_%02d" "$day")

if [ -d "$directory" ]; then
    echo "This $directory already exists!"
    exit 1
fi

mkdir -p "$directory"
echo "$template" > "./$directory/main.zig"
touch "./$directory/sample.txt"
touch "./$directory/input.txt"

echo "Enjoy day $day!"
