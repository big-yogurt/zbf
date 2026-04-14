const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;
const LexerError = @import("lexer.zig").LexerError;
const Token = @import("token.zig").Token;

var commandsAllocatorBuffer: [1 << 20]u8 = undefined;
var commandsFba = std.heap.FixedBufferAllocator.init(&commandsAllocatorBuffer);
const commandsAllocator = commandsFba.allocator();

var loopStackAllocatorBuffer: [1 << 20]u8 = undefined;
var loopStackFba = std.heap.FixedBufferAllocator.init(&loopStackAllocatorBuffer);
const loopStackAllocator = loopStackFba.allocator();

const Parser = struct {
    const Self = @This();
    
    lexer: Lexer = undefined,

    // For set Token.loopEdgeIndex
    loopStack: std.ArrayList(u16) = .empty,

    pub fn parseFile(self: *Self, fileName: [:0]const u8) std.ArrayList(Token) {
        const file = std.fs.cwd().openFile(fileName, .{}) catch {
            std.debug.print("Failed to open file\n", .{});
            std.process.exit(1);
        };
        defer file.close();

        var commands = std.ArrayList(Token).initCapacity(commandsAllocator, 64) catch {
            std.debug.print("Failed to create array\n", .{});
            std.process.exit(1);
        };

        var readerBuffer: [1024]u8 = undefined;
        var reader = file.reader(&readerBuffer);

        var lexer = Lexer.init(&reader.interface);

        while (lexer.getToken()) |token| {
            commands.append(commandsAllocator, token) catch {
                // TODO: nice error handling
                std.debug.print("Failed to parse file\n", .{});
                std.process.exit(1);
            };
            if (token.kind == .loopBegin) {
                self.loopStack.append(loopStackAllocator, @as(u16, @intCast(commands.items.len)) - 1) catch {
                    std.debug.print("Failed to append\n", .{});
                    std.process.exit(1);
                };
            } else if (token.kind == .loopEnd) {
                const loopBeginIndex = if (self.loopStack.pop()) |index| index else {
                    std.debug.print("Failed to get loop index\n", .{});
                    std.process.exit(1);
                };
                // Set begin of loop
                commands.items[commands.items.len-1].loopEdgeIndex = loopBeginIndex;
                // Set end of loop
                commands.items[loopBeginIndex].loopEdgeIndex = commands.items.len - 1;
            }
        } else |err| {
            if (err != LexerError.EndOfFile) {
                std.debug.print("Failed to lexing\n", .{});
                std.process.exit(1);
            }
        }

        return commands;
    }
};

pub fn parseFile(fileName: [:0]const u8) std.ArrayList(Token) {
    var parser = Parser {};
    return parser.parseFile(fileName);
}
