const std = @import("std");

export fn quantize(red: u8, green: u8, blue: u8) callconv(.C) u8 {
    const RgbStruct = packed struct {
        blue: u2,
        green: u3,
        red: u3,
    };

    return @bitCast(RgbStruct{
        .red = @intCast(red >> 5),
        .green = @intCast(green >> 5),
        .blue = @intCast(blue >> 6),
    });
}
