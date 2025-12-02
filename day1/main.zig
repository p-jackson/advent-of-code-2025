const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{ .mode = .read_only });
    defer file.close();

    var io_buffer: [4096]u8 = undefined;
    var file_reader = file.reader(&io_buffer);
    const reader = &file_reader.interface;

    var current: i32 = 50;
    var zero_count: u32 = 0;

    while (try reader.takeDelimiter('\n')) |line| {
        if (line.len == 0) continue;

        const num = try std.fmt.parseInt(i32, line[1..], 10);

        // Returns new new dial position, _and_ how number for calculating zero clicks.
        const result = switch (line[0]) {
            'L' => if (current == 0)
                .{ current - num, num }
            else
                .{ current - num, (100 - current) + num },
            'R' => .{ current + num, current + num },
            else => continue,
        };

        current = @mod(result[0], 100);
        zero_count += @abs(@divFloor(result[1], 100));
    }

    std.debug.print("{d}\n", .{zero_count});
}
