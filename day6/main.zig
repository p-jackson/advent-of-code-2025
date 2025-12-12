const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const alloc = gpa.allocator();
    var file = try std.fs.cwd().openFile("input.txt", .{ .mode = .read_only });
    defer file.close();

    var io_buffer: [8192]u8 = undefined;
    var file_reader = file.reader(&io_buffer);
    var reader = &file_reader.interface;

    var all_lines: std.ArrayList([]u8) = .empty;
    defer all_lines.deinit(alloc);
    defer for (all_lines.items) |c| alloc.free(c);

    var grand_total: u64 = 0;

    while (try reader.takeDelimiter('\n')) |current_line| {
        if (current_line.len == 0) break;
        try all_lines.append(alloc, try alloc.alloc(u8, current_line.len));
        @memcpy(all_lines.items[all_lines.items.len - 1], current_line);
    }

    const lines = all_lines.items[0 .. all_lines.items.len - 1];
    const operations = all_lines.items[all_lines.items.len - 1];

    var last_operator_idx: usize = 0;
    for (1..operations.len) |i| {
        const next_operator = operations[i];
        if (next_operator != '*' and next_operator != '+' and i != operations.len - 1) {
            continue;
        }

        const num_end_idx = if (i == operations.len - 1) i + 1 else i - 1;

        grand_total += process(lines, last_operator_idx, num_end_idx, operations[last_operator_idx]);

        last_operator_idx = i;
    }

    std.debug.print("{d}\n", .{grand_total});
}

fn process(lines: [][]u8, begin: usize, end: usize, operation: u8) u64 {
    var accumulator: u64 = switch (operation) {
        '+' => 0,
        '*' => 1,
        else => unreachable,
    };

    var str_buff: [128]u8 = undefined;
    var str_len: usize = 0;
    std.debug.assert(lines.len < str_buff.len);

    for (begin..end) |i| {
        str_len = 0;

        for (lines) |line| {
            if (line[i] != ' ') {
                str_buff[str_len] = line[i];
                str_len += 1;
            }
        }

        const n = std.fmt.parseInt(u64, str_buff[0..str_len], 10) catch unreachable;

        switch (operation) {
            '+' => accumulator += n,
            '*' => accumulator *= n,
            else => unreachable,
        }
    }

    return accumulator;
}
