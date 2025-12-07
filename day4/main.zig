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
    var count: u32 = 0;

    var arena: std.heap.ArenaAllocator = .init(allocator);
    defer arena.deinit();
    var arena_alloc = arena.allocator();

    var rows_buffer: [3][]u8 = undefined;
    var rows: std.ArrayList([]u8) = .initBuffer(&rows_buffer);

    var row_count: usize = 0;

    while (try reader.takeDelimiter('\n')) |current_line| {
        if (rows.items.len < rows.capacity) {
            rows.appendAssumeCapacity(try arena_alloc.alloc(u8, current_line.len));
        }

        std.debug.assert(current_line.len == rows.items[row_count].len);

        @memcpy(rows.items[row_count], current_line);
        row_count += 1;

        std.debug.assert(row_count <= rows.items.len);

        if (row_count == 1) {
            continue;
        }

        count += count_accessable_rolls_in_row(rows.items, row_count - 2);

        if (row_count > 2) {
            // Recycle buffers, using the oldest row's buffer for the next line.
            const temp = rows.items[0];
            rows.items[0] = rows.items[1];
            rows.items[1] = rows.items[2];
            rows.items[2] = temp;
            row_count = 2;
        }
    }

    return count + count_accessable_rolls_in_row(rows.items[0..row_count], row_count - 1);
}

test "count_accessable_rolls_in_input" {
    const allocator = std.testing.allocator;
    const build_reader = std.Io.Reader.fixed;

    var empty3x3 = build_reader("...\n...\n...\n");
    try expectEqual(0, count_accessable_rolls_in_input(allocator, &empty3x3));

    var corner2x2 = build_reader("..\n.@\n");
    try expectEqual(1, count_accessable_rolls_in_input(allocator, &corner2x2));

    var full3x3 = build_reader("@@@\n@@@\n@@@\n");
    try expectEqual(4, count_accessable_rolls_in_input(allocator, &full3x3));

    var input_sample = build_reader("@..@@.@.@@@....@@\n@.@@.@@@@@@..@.@@\n@@.@@@@@.@.@@.@@@\n");
    try expectEqual(17, count_accessable_rolls_in_input(allocator, &input_sample));

    var input_sample2 = build_reader("@..@@.@.@@@....@@\n@.@@.@@@@@@..@.@@\n@@.@@@@@.@.@@.@@@\n@@@@.@..@@@.@@.@@\n.@@@@.@@@.@@.@@@.\n@@@@@@@.@@.@.@.@@\n..@@@.@@.@...@.@@\n@@.@.@.@@..@@@@.@\n@@.@.@@@@.@@@@..@\n");
    try expectEqual(22, count_accessable_rolls_in_input(allocator, &input_sample2));
}

fn count_accessable_rolls_in_row(rows: [][]u8, row_to_check: usize) u32 {
    var count: u32 = 0;
    for (0..rows[row_to_check].len) |index| {
        if (rows[row_to_check][index] == '@' and count_adjacent_rolls(rows, row_to_check, index) < 4) {
            count += 1;
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
        @intFromBool(rows[row_index][index_in_row] == '@')
    else
        0;
}
