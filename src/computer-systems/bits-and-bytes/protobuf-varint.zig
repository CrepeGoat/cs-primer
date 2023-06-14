// https://csprimer.com/watch/varint/

const std = @import("std");

test "VarintByte has correct size & alignment" {
    try comptime std.testing.expectEqual(1, @sizeOf(VarintByte));
    try comptime std.testing.expectEqual(1, @alignOf(VarintByte));
}

test "VarintByte bits are ordered correctly" {
    try comptime std.testing.expectEqual(0x80, @bitCast(u8, VarintByte{ .has_more = true, .value = 0 }));
}

pub const VarintByte = packed struct {
    value: u7,
    has_more: bool,
};

// Encoding

test "encode literals" {
    var buffer: [MAX_BYTES]VarintByte = undefined;
    inline for (.{
        .{ 0, [_]u8{0x00} },
        .{ 1, [_]u8{0x01} },
        .{ 150, [_]u8{ 0x96, 0x01 } },
        .{ std.math.maxInt(u64), [_]u8{0xFF} ** (MAX_BYTES - 1) ++ [_]u8{0x01} },
    }) |vals| {
        const input = vals[0];
        const expt_result = vals[1];

        const result = encode(input, &buffer);
        try std.testing.expectEqualSlices(u8, &expt_result, @ptrCast([]u8, result));
    }
}

pub fn encode(value: u64, buffer: *[MAX_BYTES]VarintByte) []VarintByte {
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

// TODO compiler bug!
// test "decode literals" {
//     inline for (.{
//         .{ @as(u64, 0), [_]u8{0x00} },
//         .{ @as(u64, 1), [_]u8{0x01} },
//         .{ @as(u64, 150), [_]u8{ 0x96, 0x01 } },
//         .{ @as(u64, std.math.maxInt(u64)), [_]u8{0xFF} ** (MAX_BYTES - 1) ++ [_]u8{0x01} },
//     }) |vals| {
//         const expt_result = vals[0];
//         const input: []const u8 = &vals[1];

//         const result = try decode(@ptrCast([]const VarintByte, input));
//         try std.testing.expectEqual(expt_result, result);
//     }
// }
test "decode literal 0" {
    const expt_result = @as(u64, 0);
    const input: []const u8 = &[_]u8{0x00};

    const result = try decode(@ptrCast([]const VarintByte, input));
    try std.testing.expectEqual(expt_result, result);
}
test "decode literal 1" {
    const expt_result = @as(u64, 1);
    const input: []const u8 = &[_]u8{0x01};

    const result = try decode(@ptrCast([]const VarintByte, input));
    try std.testing.expectEqual(expt_result, result);
}
test "decode literal 150" {
    const expt_result = @as(u64, 150);
    const input: []const u8 = &[_]u8{ 0x96, 0x01 };

    const result = try decode(@ptrCast([]const VarintByte, input));
    try std.testing.expectEqual(expt_result, result);
}
test "decode literal max value" {
    const expt_result = @as(u64, std.math.maxInt(u64));
    const input: []const u8 = &([_]u8{0xFF} ** (MAX_BYTES - 1) ++ [_]u8{0x01});

    const result = try decode(@ptrCast([]const VarintByte, input));
    try std.testing.expectEqual(expt_result, result);
}

const DecodeError = error{NoTermination};

pub fn decode(buffer: []const VarintByte) DecodeError!u64 {
    var terminal_pos: usize = inline for (0..MAX_BYTES + 1) |j| {
        if (j >= MAX_BYTES or j >= buffer.len) {
            return DecodeError.NoTermination;
        }
        const item = buffer[j];
        if (!item.has_more and (j < MAX_BYTES - 1 or item.value <= 1)) {
            break j;
        }
    } else unreachable;

    var result: u64 = 0;
    var bytes_rev = std.mem.reverseIterator(buffer[0 .. terminal_pos + 1]);
    while (bytes_rev.next()) |item| {
        result = (result << 7) | item.value;
    }
    return result;
}

/// The maximum number of bytes required to store a 64-bit varint.
const MAX_BYTES = 10;
