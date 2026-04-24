const std = @import("std");
const Token = @import("token.zig").Token;

pub const InterpreterError = error {
    OutOfTape,
    CannotReadInput,
    CannotPrint,
};

pub const Interpreter = struct{
    const Self = @This();

    commands: *std.ArrayList(Token) = undefined,
    commandCursor: usize = 0,

    tape: [30000]u8 = [_]u8{0} ** 30000,
    cellCursor: i32 = 0,

    stdinBuffer: [128]u8 = undefined,
    stdin: std.fs.File.Reader = undefined,
    lineBuffer: [128]u8 = undefined,
    stdinWriter: std.io.Writer = undefined,

    stdoutBuffer: [16]u8 = undefined,
    stdout: std.fs.File.Writer = undefined,

    pub fn init(commands: *std.ArrayList(Token)) Interpreter {
        var self = Interpreter {
            .stdinBuffer = undefined,
            .stdin = undefined,
            .lineBuffer = undefined,
            .stdinWriter = undefined,
            .commands = commands,
        };

        self.stdin = std.fs.File.stdin().reader(&self.stdinBuffer);
        self.stdinWriter = .fixed(&self.lineBuffer);

        self.stdout = std.fs.File.stdout().writer(&self.stdoutBuffer);

        return self;
    }

    pub fn run(self: *Self) InterpreterError!void {
        while (true) : (self.commandCursor += 1) {
            if (self.commandCursor >= self.commands.items.len) break;
            var command = self.commands.items[self.commandCursor];
            try self.execCommand(&command);
        }
        self.stdout.interface.flush() catch {};
    }
    
    fn execCommand(self: *Self, command: *Token) InterpreterError!void {
        switch (command.kind) {
            .inc => self.tape[@as(usize, @abs(self.cellCursor))] +%= @intCast(command.diff),
            .dec => self.tape[@as(usize, @abs(self.cellCursor))] -%= @intCast(command.diff),
            .next => {
                if (self.cellCursor == @as(u16, @intCast(self.tape.len-1))) {
                    return InterpreterError.OutOfTape;
                }
                self.cellCursor += command.diff;
            },
            .prev => {
                if (self.cellCursor == 0) {
                    return InterpreterError.OutOfTape;
                }
                self.cellCursor -= command.diff;
            },
            .print => {
                for (0..@as(usize, @intCast(command.diff))) |_| {
                    self.stdout.interface.writeByte(self.tape[@as(usize, @abs(self.cellCursor))]) catch |err| switch (err) {
                        std.io.Writer.Error.WriteFailed => return InterpreterError.CannotPrint,
                    };
                }
            },
            .input => {
                for (0..@as(usize, @intCast(command.diff))) |_| {
                    self.tape[@as(usize, @abs(self.cellCursor))] = self.stdin.interface
                        .takeByte() catch |err| switch (err) {
                            std.io.Reader.Error.EndOfStream => return,
                            std.io.Reader.Error.ReadFailed => return InterpreterError.CannotReadInput,
                        };
                }
            },
            .loopBegin => {
                if (self.tape[@as(usize, @abs(self.cellCursor))] == 0) {
                    self.commandCursor = @as(usize, command.loopEdgeIndex);
                }
            },
            .loopEnd => {
                if (self.tape[@as(usize, @abs(self.cellCursor))] != 0) {
                    self.commandCursor = @as(usize, command.loopEdgeIndex);
                }
            },
        }
    }
};
