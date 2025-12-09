const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

const Range = struct {
    lower: u64,
    higher: u64,

    pub fn print(self: *const Range) void {
        std.debug.assert(self.lower <= self.higher);
        std.debug.print("{d}-{d}\n", .{ self.lower, self.higher });
    }

    pub fn intersects(self: *const Range, other: *const Range) bool {
        return (other.lower <= self.higher and other.lower >= self.lower) or
            (other.higher >= self.lower and other.higher <= self.higher) or
            (self.higher >= other.lower and self.higher <= other.higher) or
            (self.lower <= other.higher and self.lower >= other.lower);
    }

    pub fn merge(self: *Range, other: *const Range) void {
        self.lower = @min(self.lower, other.lower);
        self.higher = @max(self.higher, other.higher);
    }

    pub fn count(self: *const Range) u64 {
        return self.higher - self.lower + 1;
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

    var done = false;

    blk: while (!done) {
        done = true;

        for (0..ranges.items.len) |i| {
            const candidate = ranges.items[i];

            for (i + 1..ranges.items.len) |j| {
                if (ranges.items[j].intersects(&candidate)) {
                    done = false;
                    ranges.items[j].merge(&candidate);
                    _ = ranges.orderedRemove(i);
                    continue :blk;
                }
            }
        }
    }

    var count: u64 = 0;

    for (ranges.items) |range| count += range.count();

    std.debug.print("{d}\n", .{count});
}

test "intersection" {
    try expect(!(Range{ .lower = 10, .higher = 100 }).intersects(&Range{ .lower = 120, .higher = 1100 }));
    try expect((Range{ .lower = 10, .higher = 100 }).intersects(&Range{ .lower = 100, .higher = 110 }));
    try expect((Range{ .lower = 10, .higher = 100 }).intersects(&Range{ .lower = 90, .higher = 110 }));
    try expect((Range{ .lower = 10, .higher = 100 }).intersects(&Range{ .lower = 10, .higher = 100 }));
    try expect((Range{ .lower = 10, .higher = 100 }).intersects(&Range{ .lower = 20, .higher = 80 }));
    try expect((Range{ .lower = 10, .higher = 100 }).intersects(&Range{ .lower = 20, .higher = 100 }));
    try expect((Range{ .lower = 10, .higher = 100 }).intersects(&Range{ .lower = 10, .higher = 80 }));
    try expect((Range{ .lower = 10, .higher = 100 }).intersects(&Range{ .lower = 5, .higher = 80 }));
    try expect((Range{ .lower = 10, .higher = 100 }).intersects(&Range{ .lower = 5, .higher = 10 }));
    try expect(!(Range{ .lower = 10, .higher = 100 }).intersects(&Range{ .lower = 5, .higher = 6 }));

    try expect(!(Range{ .lower = 120, .higher = 1100 }).intersects(&Range{ .lower = 10, .higher = 100 }));
    try expect((Range{ .lower = 100, .higher = 110 }).intersects(&Range{ .lower = 10, .higher = 100 }));
    try expect((Range{ .lower = 90, .higher = 110 }).intersects(&Range{ .lower = 10, .higher = 100 }));
    try expect((Range{ .lower = 10, .higher = 100 }).intersects(&Range{ .lower = 10, .higher = 100 }));
    try expect((Range{ .lower = 20, .higher = 80 }).intersects(&Range{ .lower = 10, .higher = 100 }));
    try expect((Range{ .lower = 20, .higher = 100 }).intersects(&Range{ .lower = 10, .higher = 100 }));
    try expect((Range{ .lower = 10, .higher = 80 }).intersects(&Range{ .lower = 10, .higher = 100 }));
    try expect((Range{ .lower = 5, .higher = 80 }).intersects(&Range{ .lower = 10, .higher = 100 }));
    try expect((Range{ .lower = 5, .higher = 10 }).intersects(&Range{ .lower = 10, .higher = 100 }));
    try expect(!(Range{ .lower = 5, .higher = 6 }).intersects(&Range{ .lower = 10, .higher = 100 }));
}
