const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    var file = try std.fs.cwd().openFile("input.txt", .{ .mode = .read_only });
    defer file.close();

    var io_buffer: [2048]u8 = undefined;
    var file_reader = file.reader(&io_buffer);

    const count = try count_accessable_rolls_in_input(gpa.allocator(), &file_reader.interface);

    std.debug.print("{d}\n", .{count});
}

fn count_accessable_rolls_in_input(allocator: std.mem.Allocator, reader: *std.Io.Reader) !u32 {
    var arena: std.heap.ArenaAllocator = .init(allocator);
    defer arena.deinit();
    var arena_alloc = arena.allocator();

    var rows: std.ArrayList([]u8) = .empty;

    while (try reader.takeDelimiter('\n')) |current_line| {
        try rows.append(arena_alloc, try arena_alloc.alloc(u8, current_line.len));
        @memcpy(rows.items[rows.items.len - 1], current_line);
    }

    var count: u32 = 0;
    var last_count: ?u32 = null;

    while (last_count == null or last_count.? != count) {
        last_count = count;

        for (0..rows.items.len) |row_index| {
            count += count_and_mark_accessable_rolls_in_row(rows.items, row_index);
        }

        // Remove marked rolls
        for (rows.items) |row| {
            for (0..row.len) |i| {
                if (row[i] == 'x') {
                    row[i] = '.';
                }
            }
        }
    }

    return count;
}

test "count_accessable_rolls_in_input" {
    const allocator = std.testing.allocator;
    const build_reader = std.Io.Reader.fixed;

    var empty3x3 = build_reader("...\n...\n...\n");
    try expectEqual(0, count_accessable_rolls_in_input(allocator, &empty3x3));

    var corner2x2 = build_reader("..\n.@\n");
    try expectEqual(1, count_accessable_rolls_in_input(allocator, &corner2x2));

    var full3x3 = build_reader("@@@\n@@@\n@@@\n");
    try expectEqual(9, count_accessable_rolls_in_input(allocator, &full3x3));
}

fn count_and_mark_accessable_rolls_in_row(rows: [][]u8, row_to_check: usize) u32 {
    var count: u32 = 0;
    for (0..rows[row_to_check].len) |index| {
        if (rows[row_to_check][index] == '@' and count_adjacent_rolls(rows, row_to_check, index) < 4) {
            count += 1;
            rows[row_to_check][index] = 'x';
        }
    }
    return count;
}

/// Returns the number of rolls adjacent to `rows[row_index][index_in_row]`.
fn count_adjacent_rolls(rows: [][]u8, row_index: usize, index_in_row: usize) u32 {
    // We're allowing integer underflow to happen below, which is only safe when the underflowed index doesn't refer to a valid element.
    std.debug.assert(rows.len == 0 or rows[0].len < std.math.maxInt(usize));
    // Row lengths must match
    std.debug.assert(rows.len < 2 or rows[0].len == rows[1].len);
    std.debug.assert(rows.len < 3 or rows[0].len == rows[2].len);

    var count: u32 = 0;

    count += check_cell(rows, row_index -% 1, index_in_row -% 1);
    count += check_cell(rows, row_index -% 1, index_in_row);
    count += check_cell(rows, row_index -% 1, index_in_row + 1);
    count += check_cell(rows, row_index, index_in_row -% 1);
    count += check_cell(rows, row_index, index_in_row + 1);
    count += check_cell(rows, row_index + 1, index_in_row -% 1);
    count += check_cell(rows, row_index + 1, index_in_row);
    count += check_cell(rows, row_index + 1, index_in_row + 1);

    return count;
}

/// Returns 1 if the cell has a roll, otherwise 0.
fn check_cell(rows: [][]u8, row_index: usize, index_in_row: usize) u32 {
    return if (row_index < rows.len and index_in_row < rows[row_index].len)
        @intFromBool(rows[row_index][index_in_row] == '@' or rows[row_index][index_in_row] == 'x')
    else
        0;
}
