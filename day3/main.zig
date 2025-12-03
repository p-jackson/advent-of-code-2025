const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{ .mode = .read_only });
    defer file.close();

    var io_buffer: [4096]u8 = undefined;
    var file_reader = file.reader(&io_buffer);
    const reader = &file_reader.interface;

    var sum: u64 = 0;

    while (try reader.takeDelimiter('\n')) |line| {
        sum += largest_sequence(line);
    }

    std.debug.print("{d}\n", .{sum});
}

fn largest_sequence(list: []const u8) u64 {
    std.debug.assert(list.len >= 2);

    var sum: u64 = 0;
    var start: usize = 0;
    for (1..13) |i| {
        const digit, const pos = largest_in_range(list[start .. list.len - 12 + i]);
        start += pos + 1;

        sum = sum * 10 + @as(u64, digit - '0');
    }

    return sum;
}

test "largest_sequence" {
    try expectEqual(987654321111, largest_sequence("987654321111111"));
    try expectEqual(811111111119, largest_sequence("811111111111119"));
    try expectEqual(434234234278, largest_sequence("234234234234278"));
    try expectEqual(888911112111, largest_sequence("818181911112111"));
}

fn largest_in_range(list: []const u8) struct { u8, usize } {
    std.debug.assert(list.len != 0);

    var max = list[0];
    var max_i: usize = 0;

    for (1..list.len) |i| {
        if (list[i] > max) {
            max = list[i];
            max_i = i;
        }
    }

    return .{ max, max_i };
}
