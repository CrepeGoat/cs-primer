// https://csprimer.com/watch/bitcount/

const std = @import("std");

test "count bits works" {
    try std.testing.expectEqual(@as(u64, 0), bitcount(0));
    try std.testing.expectEqual(@as(u64, 1), bitcount(1));
    try std.testing.expectEqual(@as(u64, 2), bitcount(3));
    try std.testing.expectEqual(@as(u64, 1), bitcount(8));
}

fn bitcount(n: u64) u8 {
    return @popCount(n);
}
