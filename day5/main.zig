const std = @import("std");
const expectEqual = std.testing.expectEqual;

const Range = struct {
    lower: u64,
    higher: u64,

    pub fn in_range(self: *const Range, n: u64) bool {
        return n >= self.lower and n <= self.higher;
    }
};

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const alloc = gpa.allocator();
    var file = try std.fs.cwd().openFile("input.txt", .{ .mode = .read_only });
    defer file.close();

    var io_buffer: [2048]u8 = undefined;
    var file_reader = file.reader(&io_buffer);
    var reader = &file_reader.interface;

    var ranges: std.ArrayList(Range) = .empty;
    defer ranges.deinit(alloc);

    while (try reader.takeDelimiter('\n')) |current_line| {
        if (current_line.len == 0) {
            break;
        }

        var iter = std.mem.splitScalar(u8, current_line, '-');
        const lower = try std.fmt.parseInt(u64, iter.first(), 10);
        const higher = try std.fmt.parseInt(u64, iter.rest(), 10);

        try ranges.append(alloc, Range{ .lower = lower, .higher = higher });
    }

    var count: u64 = 0;

    while (try reader.takeDelimiter('\n')) |current_line| {
        const n = try std.fmt.parseInt(u64, current_line, 10);

        for (ranges.items) |range| {
            if (range.in_range(n)) {
                count += 1;
                break;
            }
        }
    }

    std.debug.print("{d}\n", .{count});
}
