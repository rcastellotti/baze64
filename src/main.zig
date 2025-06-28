const std = @import("std");

const baze64 = struct {
    _table: *const [64]u8,

    pub fn init() baze64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers_symb = "0123456789+/";
        return baze64{
            ._table = upper ++ lower ++ numbers_symb,
        };
    }

    fn _char_at(self: baze64, index: usize) u8 {
        return self._table[index];
    }

    fn _char_index(self: baze64, char: usize) u8 {
        if (char == '=') return 0x40;
        var index: u8 = 0;
        for (0..self._table.len) |i| {
            if (self._char_at(i) == char) break;
            index += 1;
        }
        return index;
    }

    fn _calc_encode_length(input: []const u8) usize {
        return ((input.len + 2) / 3) * 4;
    }

    fn _calc_decode_length(input: []const u8) usize {
        if (input.len == 0) return 0;

        var len = (input.len / 4) * 3;

        // Subtract bytes for padding
        if (input[input.len - 1] == '=') {
            len -= 1;
            if (input.len > 1 and input[input.len - 2] == '=') {
                len -= 1;
            }
        }

        return len;
    }

    pub fn encode(self: baze64, allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
        if (input.len == 0) return "";

        var output = try allocator.alloc(u8, _calc_encode_length(input));
        const complete_groups = input.len / 3;

        // process complete 3-byte groups
        for (0..complete_groups) |i| {
            // base64 encodes chunks of 3 bytes into chunks of 4 bytes
            const in_start = i * 3;
            const out_start = i * 4;
            output[out_start + 0] = self._char_at(input[in_start + 0] >> 2);
            output[out_start + 1] = self._char_at((input[in_start + 0] & 0x03) << 4 | input[in_start + 1] >> 4);
            output[out_start + 2] = self._char_at((input[in_start + 1] & 0x0f) << 2 | input[in_start + 2] >> 6);
            output[out_start + 3] = self._char_at(input[in_start + 2] & 0x3f);
        }

        // handle remaining bytes (if any)
        const remaining = input.len % 3; // count of leftover bytes
        if (remaining > 0) {
            const start = complete_groups * 3;
            const out_start = complete_groups * 4;

            var padded = [3]u8{ 0, 0, 0 };

            for (input[start..], 0..) |byte, idx| {
                padded[idx] = byte;
            }

            output[out_start + 0] = self._char_at(padded[0] >> 2);
            output[out_start + 1] = self._char_at(((padded[0] & 0x03) << 4) | padded[1] >> 4);

            // the third byte is only padded when processing a 1-byte chunk
            if (remaining == 1) {
                output[out_start + 2] = '=';
            } else {
                output[out_start + 2] = self._char_at((padded[1] & 0x0f) << 2);
            }
            // last byte is always padded
            output[out_start + 3] = '=';
        }

        return output;
    }

    pub fn decode(self: baze64, allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
        if (input.len == 0) {
            return "";
        }

        var output = try allocator.alloc(u8, _calc_decode_length(input));
        // we use count to track 4-byte chunks, once we have one we reset it to
        // use `buf` for the next one.
        var count: u8 = 0;
        var iout: u64 = 0;
        var buf = [4]u8{ 0, 0, 0, 0 };

        for (0..input.len) |i| {
            buf[count] = self._char_index(input[i]);
            count += 1;

            if (count == 4) {
                output[iout] = (buf[0] << 2) | (buf[1] >> 4);

                if (buf[2] != 0x40) {
                    output[iout + 1] = (buf[1] << 4) | (buf[2] >> 2);
                }

                if (buf[3] != 0x40) {
                    output[iout + 2] = (buf[2] << 6) | buf[3];
                }

                iout += 3;
                count = 0;
            }
        }

        return output;
    }
};

test "encode_length" {
    const test_cases = [_]struct { input: []const u8, expected: usize }{
        .{ .input = "", .expected = 0 },
        .{ .input = "foo", .expected = 4 },
        .{ .input = "foobar", .expected = 8 },
    };

    for (test_cases) |case| {
        const result = baze64._calc_encode_length(case.input);
        try std.testing.expectEqual(case.expected, result);
    }
}

test "decode_length" {
    const test_cases = [_]struct { input: []const u8, expected: usize }{
        .{ .input = "", .expected = 0 },
        .{ .input = "Zg==", .expected = 1 },
        .{ .input = "Zm9vYmFy", .expected = 6 },
        .{ .input = "SGVsbG8=", .expected = 5 },
        .{ .input = "SGVsbG8gV29ybGQ=", .expected = 11 },
    };

    for (test_cases) |case| {
        const result = baze64._calc_decode_length(case.input);
        try std.testing.expectEqual(case.expected, result);
    }
}

test "encoding" {
    const allocator = std.testing.allocator;
    const baz = baze64.init();

    const test_cases = [_]struct { input: []const u8, expected: []const u8 }{
        .{ .input = "", .expected = "" },
        .{ .input = "f", .expected = "Zg==" },
        .{ .input = "fo", .expected = "Zm8=" },
        .{ .input = "foo", .expected = "Zm9v" },
        .{ .input = "foob", .expected = "Zm9vYg==" },
        .{ .input = "fooba", .expected = "Zm9vYmE=" },
        .{ .input = "foobar", .expected = "Zm9vYmFy" },
    };

    for (test_cases) |case| {
        const result = try baz.encode(allocator, case.input);
        defer allocator.free(result);

        try std.testing.expectEqualStrings(case.expected, result);
    }
}

test "decoding" {
    const allocator = std.testing.allocator;
    const baz = baze64.init();

    const test_cases = [_]struct { input: []const u8, expected: []const u8 }{
        .{ .input = "", .expected = "" },
        .{ .input = "Zg==", .expected = "f" },
        .{ .input = "Zm8=", .expected = "fo" },
        .{ .input = "Zm9v", .expected = "foo" },
        .{ .input = "Zm9vYg==", .expected = "foob" },
        .{ .input = "Zm9vYmE=", .expected = "fooba" },
        .{ .input = "Zm9vYmFy", .expected = "foobar" },
    };

    for (test_cases) |case| {
        const result = try baz.decode(allocator, case.input);
        defer allocator.free(result);

        try std.testing.expectEqualStrings(case.expected, result);
    }
}

test "roundtrip" {
    const allocator = std.testing.allocator;
    const baz = baze64.init();

    const test_cases = [_][]const u8{
        "Communicate intent precisely.",
        "Edge cases matter.",
        "Favor reading code over writing code.",
        "Only one obvious way to do things.",
        "Runtime crashes are better than bugs.",
        "Compile errors are better than runtime crashes.",
        "Incremental improvements.",
        "Avoid local maximums.",
        "Reduce the amount one must remember.",
        "Focus on code rather than style.",
        "Resource allocation may fail; resource deallocation must succeed.",
        "Memory is a resource.",
        "Together we serve the users.",
    };

    for (test_cases) |input| {
        const encoded = try baz.encode(allocator, input);
        defer allocator.free(encoded);

        const decoded = try baz.decode(allocator, encoded);
        defer allocator.free(decoded);

        try std.testing.expectEqualStrings(input, decoded);
    }
}
