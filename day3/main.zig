const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{ .mode = .read_only });
    defer file.close();

    var io_buffer: [4096]u8 = undefined;
    var file_reader = file.reader(&io_buffer);
    const reader = &file_reader.interface;

    var sum: u32 = 0;

    while (try reader.takeDelimiter('\n')) |line| {
        sum += largest_pair(line);
    }

    std.debug.print("{d}\n", .{sum});
}

fn largest_pair(list: []const u8) u32 {
    std.debug.assert(list.len >= 2);

    const first, const i = largest_in_range(list[0 .. list.len - 1]);
    const second, _ = largest_in_range(list[i + 1 ..]);

    return 10 * (first - '0') + (second - '0');
}

test "largest_pair" {
    try expectEqual(98, largest_pair("987654321111111"));
    try expectEqual(89, largest_pair("811111111111119"));
    try expectEqual(78, largest_pair("234234234234278"));
    try expectEqual(92, largest_pair("818181911112111"));
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
