const std = @import("std");
const c = @import("libuiohook");

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    var event = try allocator.create(c.uiohook_event);
    defer allocator.destroy(event);

    event.data.mouse.x = 10;
    event.data.mouse.y = 35;
    c.hook_post_event(event);
}
