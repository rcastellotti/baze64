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

    fn _char_at(self: baze64, index: u8) u8 {
        return self._table[index];
    }

    fn _calc_encode_length(input: []const u8) usize {
        return ((input.len + 2) / 3) * 4;
    }

    fn _encode_triplet(self: baze64, input: []const u8, output: []u8) void {
        output[0] = self._char_at(input[0] >> 2);
        output[1] = self._char_at((input[0] & 0x03) << 4 | input[1] >> 4);
        output[2] = self._char_at((input[1] & 0x0f) << 2 | input[2] >> 6);
        output[3] = self._char_at(input[2] & 0x3f);
    }

    // count indicates how many bytes we are processing,
    fn _encode_partial(self: baze64, input: []const u8, output: []u8, count: usize) void {
        var padded = [3]u8{ 0, 0, 0 };

        for (input, 0..) |byte, idx| {
            padded[idx] = byte;
        }

        output[0] = self._char_at(padded[0] >> 2);
        output[1] = self._char_at(((padded[0] & 0x03) << 4) | padded[1] >> 4);

        // the third byte is only padded when processing a 1-byte chunk
        if (count == 1) {
            output[2] = '=';
        } else {
            output[2] = self._char_at((padded[1] & 0x0f) << 2);
        }
        // last byte is always padded
        output[3] = '=';
    }

    pub fn encode(self: baze64, allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
        if (input.len == 0) return "";

        var out = try allocator.alloc(u8, _calc_encode_length(input));

        const complete_groups = input.len / 3;

        // process complete 3-byte groups
        for (0..complete_groups) |i| {
            // base64 encodes chunks of 3 bytes into chunks of 4 bytes
            const in_start = i * 3;
            const out_start = i * 4;
            self._encode_triplet(input[in_start .. in_start + 3], out[out_start .. out_start + 4]);
        }

        // handle remaining bytes (if any)
        const remaining = input.len % 3; // count of leftover bytes
        if (remaining > 0) {
            const start = complete_groups * 3;
            const out_start = complete_groups * 4;
            self._encode_partial(input[start..], out[out_start..], remaining);
        }

        return out;
    }
};

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

test "encode_length" {
    const test_cases = [_]struct { input: []const u8, expected: usize }{
        .{ .input = "", .expected = 0 },
        .{ .input = "f", .expected = 4 },
        .{ .input = "fo", .expected = 4 },
        .{ .input = "foo", .expected = 4 },
        .{ .input = "foob", .expected = 8 },
        .{ .input = "fooba", .expected = 8 },
        .{ .input = "foobar", .expected = 8 },
    };

    for (test_cases) |case| {
        const result = baze64._calc_encode_length(case.input);
        try std.testing.expectEqual(case.expected, result);
    }
}
