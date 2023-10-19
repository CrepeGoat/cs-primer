const std = @import("std");

export fn sum(items: [*]c_int, items_len: usize) callconv(.C) c_int {
    return sum_impls.simd_accumulate(items, items_len);
}

const sum_impls = struct {
    /// Benchmark results:
    /// ```
    /// Unable to determine clock rate from sysctl: hw.cpufrequency: No such file or directory
    /// This does not affect benchmark measurements, only the metadata output.
    /// ***WARNING*** Failed to set thread affinity. Estimated CPU frequency may be incorrect.
    /// 2023-10-18T23:53:34-06:00
    /// Running ./bench
    /// Run on (8 X 24 MHz CPU s)
    /// CPU Caches:
    ///   L1 Data 64 KiB
    ///   L1 Instruction 128 KiB
    ///   L2 Unified 4096 KiB (x8)
    /// Load Average: 1.55, 1.52, 1.42
    /// ---------------------------------------------------------
    /// Benchmark               Time             CPU   Iterations
    /// ---------------------------------------------------------
    /// BM_Sum/4096          6.65 us         6.65 us       105126
    /// BM_Sum/16384         26.6 us         26.6 us        26347
    /// BM_Sum/65536          106 us          106 us         6597
    /// BM_Sum/262144         425 us          425 us         1648
    /// BM_Sum/1048576       1701 us         1701 us          413
    /// ```
    fn og(items: [*]c_int, items_len: usize) callconv(.C) c_int {
        var total: c_int = 0;
        var i: usize = 0;

        while (i < items_len) : (i += 1) {
            total +%= items[i];
        }
        return total;
    }

    /// Benchmark results:
    /// ```
    /// Unable to determine clock rate from sysctl: hw.cpufrequency: No such file or directory
    /// This does not affect benchmark measurements, only the metadata output.
    /// ***WARNING*** Failed to set thread affinity. Estimated CPU frequency may be incorrect.
    /// 2023-10-19T00:17:00-06:00
    /// Running ./bench
    /// Run on (8 X 24 MHz CPU s)
    /// CPU Caches:
    ///   L1 Data 64 KiB
    ///   L1 Instruction 128 KiB
    ///   L2 Unified 4096 KiB (x8)
    /// Load Average: 1.55, 1.69, 1.66
    /// ---------------------------------------------------------
    /// Benchmark               Time             CPU   Iterations
    /// ---------------------------------------------------------
    /// BM_Sum/4096          4.51 us         4.51 us       154450
    /// BM_Sum/16384         18.1 us         18.1 us        38703
    /// BM_Sum/65536         73.4 us         73.4 us         9738
    /// BM_Sum/262144         289 us          289 us         2435
    /// BM_Sum/1048576       1169 us         1169 us          599
    /// ```
    fn parallel_accumulate(items: [*]c_int, items_len: usize) callconv(.C) c_int {
        var total1: c_int = 0;
        var total2: c_int = 0;
        var total3: c_int = 0;
        var total4: c_int = 0;

        var i: usize = 0;
        while (i < items_len - 3) : (i += 4) {
            total1 +%= items[i];
            total2 +%= items[i + 1];
            total3 +%= items[i + 2];
            total4 +%= items[i + 3];
        }
        while (i < items_len) : (i += 1) {
            total1 +%= items[i];
        }
        return total1 +% total2 +% total3 +% total4;
    }

    /// Benchmark results:
    /// ```
    /// Unable to determine clock rate from sysctl: hw.cpufrequency: No such file or directory
    /// This does not affect benchmark measurements, only the metadata output.
    /// ***WARNING*** Failed to set thread affinity. Estimated CPU frequency may be incorrect.
    /// 2023-10-19T00:22:33-06:00
    /// Running ./bench
    /// Run on (8 X 24 MHz CPU s)
    /// CPU Caches:
    ///   L1 Data 64 KiB
    ///   L1 Instruction 128 KiB
    ///   L2 Unified 4096 KiB (x8)
    /// Load Average: 1.86, 1.85, 1.74
    /// ---------------------------------------------------------
    /// Benchmark               Time             CPU   Iterations
    /// ---------------------------------------------------------
    /// BM_Sum/4096         0.512 us        0.512 us      1367695
    /// BM_Sum/16384         2.01 us         2.01 us       347952
    /// BM_Sum/65536         8.63 us         8.63 us        81154
    /// BM_Sum/262144        34.4 us         34.4 us        20342
    /// BM_Sum/1048576        141 us          141 us         4980
    /// ```
    fn simd_accumulate(items: [*]c_int, items_len: usize) callconv(.C) c_int {
        const VECTOR_LEN = 64;
        var total: @Vector(VECTOR_LEN, c_int) = @splat(0);
        var i: usize = 0;

        while (i < items_len - VECTOR_LEN + 1) : (i += VECTOR_LEN) {
            const vector: @Vector(VECTOR_LEN, c_int) = @as(*[VECTOR_LEN]c_int, @ptrCast(items + i)).*;
            total +%= vector;
        }

        var result = @reduce(.Add, total);
        while (i < items_len) : (i += 1) {
            result +%= items[i];
        }
        return result;
    }

    /// Benchmark results:
    /// ```
    /// Unable to determine clock rate from sysctl: hw.cpufrequency: No such file or directory
    /// This does not affect benchmark measurements, only the metadata output.
    /// ***WARNING*** Failed to set thread affinity. Estimated CPU frequency may be incorrect.
    /// 2023-10-18T23:54:36-06:00
    /// Running ./bench
    /// Run on (8 X 24 MHz CPU s)
    /// CPU Caches:
    ///   L1 Data 64 KiB
    ///   L1 Instruction 128 KiB
    ///   L2 Unified 4096 KiB (x8)
    /// Load Average: 1.39, 1.51, 1.42
    /// ---------------------------------------------------------
    /// Benchmark               Time             CPU   Iterations
    /// ---------------------------------------------------------
    /// BM_Sum/4096         0.411 us        0.411 us      1702248
    /// BM_Sum/16384         1.60 us         1.60 us       437079
    /// BM_Sum/65536         6.47 us         6.47 us       108409
    /// BM_Sum/262144        26.0 us         26.0 us        27102
    /// BM_Sum/1048576        106 us          106 us         6604
    /// ```
    fn simd_reduce(items: [*]c_int, items_len: usize) callconv(.C) c_int {
        var total: c_int = 0;
        const VECTOR_LEN = 64;
        var i: usize = 0;

        while (i < items_len - VECTOR_LEN + 1) : (i += VECTOR_LEN) {
            const vector: @Vector(VECTOR_LEN, c_int) = @as(*[VECTOR_LEN]c_int, @ptrCast(items + i)).*;
            total +%= @reduce(.Add, vector);
        }

        while (i < items_len) : (i += 1) {
            total +%= items[i];
        }
        return total;
    }
};
