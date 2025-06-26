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
    fn _char_at(self: @This(), index: u8) u8 {
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

    fn _encode_partial(self: baze64, input: []const u8, output: []u8, count: usize) void {
        var padded = [3]u8{ 0, 0, 0 };

        for (input, 0..) |byte, idx| {
            padded[idx] = byte;
        }

        output[0] = self._char_at(padded[0] >> 2);
        output[1] = self._char_at(((padded[0] & 0x03) << 4) | padded[1] >> 4);

        if (count == 1) {
            output[2] = '=';
            output[3] = '=';
        } else {
            output[2] = self._char_at((padded[1] & 0x0f) << 2);
            output[3] = '=';
        }
    }

    pub fn encode(self: baze64, allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
        if (input.len == 0) {
            return "";
        }

        const n_out = _calc_encode_length(input);
        var out = try allocator.alloc(u8, n_out);

        var idx: usize = 0;
        var out_idx: usize = 0;

        // Process complete 3-byte groups
        while (idx + 2 < input.len) {
            _encode_triplet(self, input[idx .. idx + 3], out[out_idx .. out_idx + 4]);
            idx += 3;
            out_idx += 4;
        }

        // Handle remaining bytes (padding cases)
        const remaining = input.len - idx;
        if (remaining > 0) {
            _encode_partial(self, input[idx..], out[out_idx..], remaining);
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
