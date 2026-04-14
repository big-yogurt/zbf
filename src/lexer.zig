const std = @import("std");
const Token = @import("token.zig").Token;
const TokenKind = @import("token.zig").TokenKind;

pub const LexerError = error {
    UnknownSymbol,
    ReadFailed,
    EndOfFile,
};

pub const Lexer = struct {
    const Self = @This();

    // For read the code.
    reader: *std.io.Reader,

    pub fn init(reader: *std.io.Reader) Lexer {
        return Lexer {
            .reader = reader,
        };
    }

    pub fn getToken(self: *Self) LexerError!Token {
        try self.skipWhitespace();
        var token = Token {};
        const byte = try self.next();
        token.kind = try TokenKind.fromByte(byte);

        // Handle sequence of commands
        switch (token.kind) {
            .inc => try self.commandHandler(&token.diff, '+', '-'),
            .dec => try self.commandHandler(&token.diff, '-', '+'),
            .next => try self.commandHandler(&token.diff, '>', '<'),
            .prev => try self.commandHandler(&token.diff, '<', '>'),
            .print => try self.commandHandler(&token.diff, '.', 0),
            .input => try self.commandHandler(&token.diff, ',', 0),
            else => {
                // The lexer doesn't handle '[' and ']'.
            },
        }
        return token;
    }

    fn skipWhitespace(self: *Self) LexerError!void {
        while (true) {
            const byte = try self.peek();
            if (!std.ascii.isWhitespace(byte)) {
                return;
            }
            _ = try self.next();
        }
    }

    fn commandHandler(self: *Self, diff: *i16, plusDiffCommand: u8,
        minusDiffCommand: u8) LexerError!void
    {
        while (true) {
            const byte = self.peek() catch |err| {
                return
                    if (err == LexerError.EndOfFile)
                        break
                    else 
                        LexerError.ReadFailed;
            };

            if (plusDiffCommand == byte) {
                diff.* += 1;
            } else if (minusDiffCommand == byte) {
                diff.* -= 1;
            } else {
                break;
            }

            _ = try self.next();
        }
    }

    fn next(self: *Self) LexerError!u8 {
        return self.reader.takeByte() catch |err| switch (err) {
            std.Io.Reader.Error.EndOfStream => LexerError.EndOfFile,
            std.Io.Reader.Error.ReadFailed => LexerError.ReadFailed,
        };
    }

    fn peek(self: *Self) LexerError!u8 {
        return self.reader.peekByte() catch |err| switch (err) {
            std.Io.Reader.Error.EndOfStream => LexerError.EndOfFile,
            std.Io.Reader.Error.ReadFailed => LexerError.ReadFailed,
        };
    }
};

test "'+' to token" {
    const reader = std.io.Reader.fixed("+");
    var lexer = Lexer.init(reader);
    const token = try lexer.getToken();

    try std.testing.expect(token.kind == TokenKind.inc);
    try std.testing.expect(token.diff == 1);
}

test "'+++' to token" {
    const reader = std.io.Reader.fixed("+++");
    var lexer = Lexer.init(reader);
    const token = try lexer.getToken();

    try std.testing.expect(token.kind == TokenKind.inc);
    try std.testing.expect(token.diff == 3);
}

test "'+-++' to token" {
    const reader = std.io.Reader.fixed("+-++");
    var lexer = Lexer.init(reader);
    const token = try lexer.getToken();

    try std.testing.expect(token.kind == TokenKind.inc);
    try std.testing.expect(token.diff == 2);
}

test "'-' to token" {
    const reader = std.io.Reader.fixed("-");
    var lexer = Lexer.init(reader);
    const token = try lexer.getToken();

    try std.testing.expect(token.kind == TokenKind.dec);
    try std.testing.expect(token.diff == 1);
}

test "'>' to token" {
    const reader = std.io.Reader.fixed(">");
    var lexer = Lexer.init(reader);
    const token = try lexer.getToken();

    try std.testing.expect(token.kind == TokenKind.next);
    try std.testing.expect(token.diff == 1);
}

test "'<' to token" {
    const reader = std.io.Reader.fixed("<");
    var lexer = Lexer.init(reader);
    const token = try lexer.getToken();

    try std.testing.expect(token.kind == TokenKind.prev);
    try std.testing.expect(token.diff == 1);
}

test "'[' to token" {
    const reader = std.io.Reader.fixed("[");
    var lexer = Lexer.init(reader);
    const token = try lexer.getToken();

    try std.testing.expect(token.kind == TokenKind.loopBegin);
    try std.testing.expect(token.diff == 1);
}

test "']' to token" {
    const reader = std.io.Reader.fixed("]");
    var lexer = Lexer.init(reader);
    const token = try lexer.getToken();

    try std.testing.expect(token.kind == TokenKind.loopEnd);
    try std.testing.expect(token.diff == 1);
}

test "'.' to token" {
    const reader = std.io.Reader.fixed(".");
    var lexer = Lexer.init(reader);
    const token = try lexer.getToken();

    try std.testing.expect(token.kind == TokenKind.print);
    try std.testing.expect(token.diff == 1);
}

test "',' to token" {
    const reader = std.io.Reader.fixed(",");
    var lexer = Lexer.init(reader);
    const token = try lexer.getToken();

    try std.testing.expect(token.kind == TokenKind.input);
    try std.testing.expect(token.diff == 1);
}

test "End of file" {
    const reader = std.io.Reader.fixed("+");
    var lexer = Lexer.init(reader);
    _ = try lexer.getToken();
    try std.testing.expect(lexer.getToken() == LexerError.EndOfFile);
}

test "Unknown symbol" {
    const reader = std.io.Reader.fixed("a");
    var lexer = Lexer.init(reader);
    try std.testing.expect(lexer.getToken() == LexerError.UnknownSymbol);
}
