// https://csprimer.com/watch/fast-pangram/

const std = @import("std");

pub export fn main() void {
    run() catch unreachable;
}

fn run() !void {
    const in = std.io.getStdIn();
    defer in.close();
    var in_buf = std.io.bufferedReader(in.reader());
    var reader = in_buf.reader();

    const out = std.io.getStdOut();
    defer out.close();
    var out_buf = std.io.bufferedWriter(out.writer());
    var writer = out_buf.writer();

    var alloc = std.heap.page_allocator;
    const BIG_SIZE = std.math.maxInt(usize);
    while (try reader.readUntilDelimiterOrEofAlloc(alloc, '\n', BIG_SIZE)) |msg| {
        if (!is_panagram(msg)) continue;
        try writer.print("{s}\n", .{msg});
        try out_buf.flush();
    }
}

test "is_panagram works on partial phrase" {
    const phrase: []const u8 = "ABC def xyz";
    try std.testing.expect(!is_panagram(phrase));
}

test "is_panagram works on full phrase" {
    const phrase: []const u8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz";
    try std.testing.expect(is_panagram(phrase));
}

fn is_panagram(phrase: []const u8) bool {
    const COUNT_ALPHA = 26;
    var is_present = std.bit_set.IntegerBitSet(COUNT_ALPHA).initEmpty();

    for (phrase) |char| {
        if (!std.ascii.isAlphabetic(char)) continue;
        const index = std.ascii.toLower(char) - 'a';
        is_present.set(index);
    }

    return is_present.count() == COUNT_ALPHA;
}
