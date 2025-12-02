const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{ .mode = .read_only });
    defer file.close();

    var io_buffer: [4096]u8 = undefined;
    var file_reader = file.reader(&io_buffer);
    const reader = &file_reader.interface;

    var sum_of_invalid: u64 = 0;

    while (try reader.takeDelimiter(',')) |line| {
        var iter = std.mem.splitScalar(u8, line, '-');

        const low_str = iter.first();
        const high_str = std.mem.trimEnd(u8, iter.rest(), "\n"); // The end of the file has a trailing new line

        const low = try std.fmt.parseInt(u64, low_str, 10);
        const high = try std.fmt.parseInt(u64, high_str, 10);

        sum_of_invalid += sum_invalid_in_range(low, high);
    }

    std.debug.print("{d}\n", .{sum_of_invalid});
}

fn sum_invalid_in_range(low: u64, high: u64) u64 {
    std.debug.assert(low < high);
    std.debug.assert(high < std.math.maxInt(u64));

    var sum: u64 = 0;
    for (low..(high + 1)) |n| {
        if (is_invalid(n)) {
            sum += n;
        }
    }
    return sum;
}

test "sum_invalid_in_range" {
    try expectEqual(33, sum_invalid_in_range(11, 22));
    try expectEqual(38593859, sum_invalid_in_range(38593856, 38593862));
}

fn is_invalid(n: u64) bool {
    const digit_count = std.math.log10(n) + 1;
    if (digit_count & 1 != 0) {
        return false;
    }

    const divisor = std.math.pow(u64, 10, digit_count / 2);
    return @divTrunc(n, divisor) == @mod(n, divisor);
}

test "is_invalid" {
    try expect(!is_invalid(1));
    try expect(!is_invalid(2));
    try expect(is_invalid(11));
    try expect(is_invalid(99));
    try expect(!is_invalid(101));
    try expect(is_invalid(1010));
    try expect(!is_invalid(222220));
    try expect(is_invalid(222222));
    try expect(is_invalid(1188511885));
}
