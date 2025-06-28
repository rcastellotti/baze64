const std = @import("std");

const baze64 = @import("root.zig");

const usage_text =
    \\Usage: baze64 [options]
    \\
    \\Options:
    \\  --encode <string>    Encode the given string to base64
    \\  --decode <string>    Decode the given base64 string
    \\  -h, --help          Show this help message
    \\
;

const Action = enum {
    encode,
    decode,
    help,
    unknown,
};

pub fn main() !void {
    const out = std.io.getStdOut().writer();
    const err = std.io.getStdErr().writer();
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        try err.print("{s}", .{usage_text});
        std.process.exit(1);
    }
    const encoder = baze64.baze64.init();

    var i: usize = 1;
    while (i < args.len) {
        const arg = args[i];

        const action: Action = if (std.mem.eql(u8, arg, "--encode"))
            .encode
        else if (std.mem.eql(u8, arg, "--decode"))
            .decode
        else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help"))
            .help
        else
            .unknown;

        switch (action) {
            .encode => {
                if (i + 1 >= args.len) {
                    try err.print("Error: --encode requires a string argument\n", .{});
                    std.process.exit(1);
                }
                i += 1;
                const input = args[i];
                const encoded = try encoder.encode(std.heap.page_allocator, input);
                try out.print("{s}", .{encoded});
                std.process.exit(0);
            },
            .decode => {
                if (i + 1 >= args.len) {
                    try err.print("Error: --decode requires a string argument\n", .{});
                    std.process.exit(1);
                }
                i += 1;
                const input = args[i];
                const decoded = try encoder.decode(std.heap.page_allocator, input);
                try out.print("{s}", .{decoded});
                std.process.exit(0);
            },
            .help => {
                try err.print("{s}", .{usage_text});
                std.process.exit(1);
            },
            .unknown => {
                try err.print("Error: Unknown argument '{s}'\n", .{arg});
                try err.print("{s}", .{usage_text});
                std.process.exit(1);
            },
        }

        i += 1;
    }

    try out.print("{s}", .{usage_text});
}
