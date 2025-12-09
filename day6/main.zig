const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const alloc = gpa.allocator();
    var file = try std.fs.cwd().openFile("input.txt", .{ .mode = .read_only });
    defer file.close();

    var io_buffer: [8192]u8 = undefined;
    var file_reader = file.reader(&io_buffer);
    var reader = &file_reader.interface;

    var columns: std.ArrayList(std.ArrayList(u64)) = .empty;
    defer columns.deinit(alloc);
    defer for (columns.items) |*c| c.deinit(alloc);

    var grand_total: u64 = 0;

    while (try reader.takeDelimiter('\n')) |current_line| {
        if (current_line.len == 0) {
            break;
        }

        var iter = std.mem.splitAny(u8, current_line, " ");

        var col_index: usize = 0;
        while (iter.next()) |num| {
            if (num.len == 0) continue;

            if (col_index <= columns.items.len) {
                try columns.append(alloc, .empty);
            }

            const n = std.fmt.parseInt(u64, num, 10) catch {
                if (num[0] == '+') {
                    for (columns.items[col_index].items) |a| grand_total += a;
                }
                if (num[0] == '*') {
                    var product: u64 = 1;
                    for (columns.items[col_index].items) |a| product *= a;
                    grand_total += product;
                }
                col_index += 1;
                continue;
            };

            try columns.items[col_index].append(alloc, n);
            col_index += 1;
        }
    }

    std.debug.print("{d}\n", .{grand_total});
}
