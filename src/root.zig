const std = @import("std");

pub fn split_1_byte(input: [1]u8) [4]u8 {
    var output: [4]u8 = undefined;

    output[0] = input[0] >> 2;
    output[1] = (input[0] & 0x03) << 4;
    output[2] = 0x40; // padding marker
    output[3] = 0x40; // padding marker

    return output;
}

pub fn split_2_bytes(input: [2]u8) [4]u8 {
    var output: [4]u8 = undefined;

    output[0] = input[0] >> 2;
    output[1] = ((input[0] & 0x03) << 4) | (input[1] >> 4); // 0x03 == 0b00000011
    output[2] = (input[1] & 0x0F) << 2; // 0x0F == 0b00001111
    output[3] = 0x40; // padding marker

    return output;
}

pub fn split_3_bytes(input: [3]u8) [4]u8 {
    var output: [4]u8 = undefined;

    output[0] = input[0] >> 2;
    output[1] = ((input[0] & 0x03) << 4) | (input[1] >> 4);
    output[2] = ((input[1] & 0x0F) << 2) | (input[2] >> 6);
    output[3] = input[2] & 0x3F; // 0x3F = 0b00111111

    return output;
}

// we use "X" to indicate padding, the value used is (0x40, 0b01000000)
test "split_1_byte" {
    // input : 10100100
    // output: 101001 00XXXX XXXXXX XXXXXX
    const expected = [_]u8{ 0b00101001, 0b00000000, 0x40, 0x40 };
    const actual = split_1_byte(.{0b10100100});
    try std.testing.expectEqualSlices(u8, &expected, &actual);
}
test "split_2_bytes" {
    // input : 10100100 11000010
    // output: 101001 001100 001XXX XXXXXX
    const expected = [_]u8{ 0b00101001, 0b00001100, 0b001000, 0x40 };
    const actual = split_2_bytes(.{ 0b10100100, 0b11000010 });
    try std.testing.expectEqualSlices(u8, &expected, &actual);
}

test "split_3_bytes" {
    // input : 10100100 11000010 10100011
    // output: 101001 001100 001010 100011
    const expected = [_]u8{ 0b00101001, 0b00001100, 0b00001010, 0b00100011 };
    const actual = split_3_bytes(.{ 0b10100100, 0b11000010, 0b10100011 });
    try std.testing.expectEqualSlices(u8, &expected, &actual);
}
