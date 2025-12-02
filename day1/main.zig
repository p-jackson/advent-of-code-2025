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

        switch (line[0]) {
            'L' => current = @mod(current - num, 100),
            'R' => current = @mod(current + num, 100),
            else => continue,
        }

        if (current == 0) {
            zero_count += 1;
        }
    }

    std.debug.print("{d}\n", .{zero_count});
}
