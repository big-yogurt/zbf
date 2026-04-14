const std = @import("std");

pub const TokenError = error {
    UnknownSymbol,
};

pub const TokenKind = enum(u8) {
    inc = '+',
    dec = '-',
    next = '>',
    prev = '<',
    loopBegin = '[',
    loopEnd = ']',
    print = '.',
    input = ',',

    pub fn fromByte(byte: u8) TokenError!TokenKind {
        return switch (byte) {
            '+' => .inc,
            '-' => .dec,
            '>' => .next,
            '<' => .prev,
            '[' => .loopBegin,
            ']' => .loopEnd,
            '.' => .print,
            ',' => .input,
            else => TokenError.UnknownSymbol,
        };
    }
};

pub const Token = struct {
    // Kind of token. 
    kind: TokenKind = undefined,

    // Difference between disired value and current value of the cell
    //
    // Example:
    //     Commands: ++-
    //     Difference: 1 (2 times increment and 1 time decrement)
    //
    // Example:
    //     Commands: ...
    //     Difference: 3 (3 times print)
    //
    // This field is only for '+', '-', '>', '<', '.' and ',' commands. For '['
    // and ']' it is always equal to 1
    diff: i16 = 1,

    // Index of loop start or end for fast jumps without scanning the loop body.
    // If kind == .loopBegin, loopEdge is end of the loop.
    // If kind == .loopEnd, loopEdge is start of the loop.
    // Used only for '[' and ']' commands.
    loopEdgeIndex: usize = undefined,
};

test "Unknown character" {
    try std.testing.expect(
        TokenKind.fromByte('a') == TokenError.UnknownSymbol
    );
}

test "'+' to token kind" {
    try std.testing.expect(try TokenKind.fromByte('+') == .inc);
}

test "'-' to token kind" {
    try std.testing.expect(try TokenKind.fromByte('-') == .dec);
}

test "'>' to token kind" {
    try std.testing.expect(try TokenKind.fromByte('>') == .next);
}

test "'<' to token kind" {
    try std.testing.expect(try TokenKind.fromByte('<') == .prev);
}

test "'[' to token kind" {
    try std.testing.expect(try TokenKind.fromByte('[') == .loopBegin);
}

test "']' to token kind" {
    try std.testing.expect(try TokenKind.fromByte(']') == .loopEnd);
}

test "'.' to token kind" {
    try std.testing.expect(try TokenKind.fromByte('.') == .print);
}

test "',' to token kind" {
    try std.testing.expect(try TokenKind.fromByte(',') == .input);
}
