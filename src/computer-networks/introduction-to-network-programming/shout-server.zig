const std = @import("std");

pub fn main() !void {
    try run_server(4096, .{ 127, 0, 0, 1 }, 8888);
}

fn run_server(
    comptime BUFFER_SIZE: usize,
    host: [4]u8,
    port: u16,
) ServerError!void {
    const SOCK_DOMAIN = std.os.AF.INET;
    const SOCK_TYPE = std.os.SOCK.DGRAM;

    // Make socket descriptor.
    var sockfd = try std.os.socket(SOCK_DOMAIN, SOCK_TYPE, 0);
    defer std.os.closeSocket(sockfd);

    // Bind socket to address.
    const sockaddr = @bitCast(std.os.sockaddr, std.os.sockaddr.in{
        .family = SOCK_DOMAIN,
        .port = std.mem.nativeToBig(u16, port),
        .addr = @bitCast(u32, host),
        // .zeros = ...
    });
    try std.os.bind(sockfd, &sockaddr, @sizeOf(@TypeOf(sockaddr)));

    while (true) {
        std.debug.print("Waiting for message...\n", .{});

        var buffer: [BUFFER_SIZE]u8 = undefined;
        var sockaddr_from: std.os.sockaddr = undefined;
        var sockaddr_from_len: u32 = @sizeOf(@TypeOf(sockaddr_from));

        // Get message.
        const msg_len = try std.os.recvfrom(
            sockfd,
            &buffer,
            0,
            &sockaddr_from,
            &sockaddr_from_len,
        );
        std.debug.assert(sockaddr_from_len > 0);
        const socket_msg = buffer[0..msg_len];
        std.debug.print("    Received message: {s}\n", .{socket_msg});

        // Process message.
        for (socket_msg) |*char| {
            char.* = std.ascii.toUpper(char.*);
        }
        std.debug.print("    Sending response: {s}\n", .{socket_msg});

        // Return response.
        _ = try std.os.sendto(
            sockfd,
            socket_msg,
            0,
            &sockaddr_from,
            sockaddr_from_len,
        );
    }
}

const ServerError = std.os.SocketError || std.os.BindError || std.os.RecvFromError || std.os.SendToError;
