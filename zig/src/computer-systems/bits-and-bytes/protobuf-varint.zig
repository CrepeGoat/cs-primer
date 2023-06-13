// https://csprimer.com/watch/varint/

const std = @import("std");

test "VarintByte has correct size & alignment" {
    try comptime std.testing.expectEqual(1, @sizeOf(VarintByte));
    try comptime std.testing.expectEqual(1, @alignOf(VarintByte));
}

test "VarintByte bits are ordered correctly" {
    try comptime std.testing.expectEqual(0x80, @bitCast(u8, VarintByte{ .has_more = true, .value = 0 }));
}

const VarintByte = packed struct {
    value: u7,
    has_more: bool,
};

// Encoding

test "encode literals" {
    var buffer: [10]VarintByte = undefined;
    inline for (.{
        .{ 0, [_]u8{0x00} },
        .{ 1, [_]u8{0x01} },
        .{ 150, [_]u8{ 0x96, 0x01 } },
        .{ std.math.maxInt(u64), [_]u8{0xFF} ** 9 ++ [_]u8{0x01} },
    }) |vals| {
        const input = vals[0];
        const expt_result = vals[1];

        const result = encode(input, &buffer);
        try std.testing.expectEqualSlices(u8, &expt_result, @ptrCast([]u8, result));
    }
}

pub fn encode(value: u64, buffer: *[10]VarintByte) []VarintByte {
    var val = value;
    for (buffer, 0..) |*item, i| {
        item.* = VarintByte{ .has_more = true, .value = @truncate(u7, val) };

        val = val >> 7;
        if (val == 0) {
            item.*.has_more = false;
            return buffer[0 .. i + 1];
        }
    }
    unreachable;
}

// Decoding

test "decode literals" {
    inline for (.{
        .{ @as(u64, 0), [_]u8{0x00} },
        .{ @as(u64, 1), [_]u8{0x01} },
        .{ @as(u64, 150), [_]u8{ 0x96, 0x01 } },
        .{ @as(u64, std.math.maxInt(u64)), [_]u8{0xFF} ** 9 ++ [_]u8{0x01} },
    }) |vals| {
        const expt_result = vals[0];
        const input: []const u8 = &vals[1];

        const result = try decode(@ptrCast([]const VarintByte, input));
        try std.testing.expectEqual(expt_result, result);
    }
}

const DecodeError = error{NoTermination};

pub fn decode(buffer: []const VarintByte) DecodeError!u64 {
    var i: usize = inline for (buffer, 0..10) |item, j| {
        if (!item.has_more and (j < 9 or item.value <= 1)) {
            break j;
        }
    } else {
        return DecodeError.NoTermination;
    };

    var result: u64 = 0;
    var bytes_rev = std.mem.reverseIterator(buffer[0..i]);
    while (bytes_rev.next()) |item| {
        result = result << 7;
        result = result | item.value;
    }
    return result;
}

// test "encode-decode round trip" {
//     inline for ([_]u64{ 0, 1, 150, std.math.maxInt(u64) }) |n| {
//         var buffer: [10]u8 = undefined;
//         try std.testing.expectEqual(n, decode(encode(n, buffer)));
//     }
// }
