const std = @import("std");

export fn sum(items: [*]c_int, items_len: usize) callconv(.C) c_int {
    var total: c_int = 0;
    var i: usize = 0;
    while (i < items_len) : (i += 1) {
        total +%= items[i];
    }
    return total;
}
