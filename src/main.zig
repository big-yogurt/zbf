const std = @import("std");

const parseFile = @import("parser.zig").parseFile;
const Interpreter = @import("interpreter.zig").Interpreter;

pub fn main() !void {
    var args = std.process.args();
    var fileName: [:0]const u8 = undefined;
    _ = args.skip();
    if (args.next()) |arg| {
        fileName = arg;
    } else {
        std.debug.print("Cannot open file\n", .{});
        return;
    }
    args.deinit();

    var commands = parseFile(fileName);

    var interpreter = Interpreter.init(&commands);
    try interpreter.run();
}
