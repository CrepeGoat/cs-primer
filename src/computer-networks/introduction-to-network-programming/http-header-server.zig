const std = @import("std");
const os = std.os;

pub fn main() !void {
    try run_server(4096, .{ 127, 0, 0, 1 }, 8888);
}

fn run_server(
    comptime BUFFER_SIZE: usize,
    host: [4]u8,
    port: u16,
) ServerError!void {
    const SOCK_DOMAIN = os.AF.INET;
    const SOCK_TYPE = os.SOCK.STREAM;

    // Make socket descriptor.
    var sockfd = try os.socket(SOCK_DOMAIN, SOCK_TYPE, 0);
    defer {
        os.closeSocket(sockfd);
        std.debug.print("closed socket {any}\n", .{sockfd});
    }
    std.debug.print("opened socket {any}\n", .{sockfd});

    // Bind socket to address.
    const sockaddr = @bitCast(os.sockaddr, os.sockaddr.in{
        .family = SOCK_DOMAIN,
        .port = std.mem.nativeToBig(u16, port),
        .addr = @bitCast(u32, host),
        // .zeros = ...
    });
    try os.bind(sockfd, &sockaddr, @sizeOf(@TypeOf(sockaddr)));

    try os.listen(sockfd, 1);
    std.debug.print(
        "listening at @{any}.{any}.{any}.{any}:{any}\n",
        .{ host[0], host[1], host[2], host[3], port },
    );

    // Accept an incoming connection.
    while (true) {
        const sockfd_accept = try os.accept(sockfd, null, null, 0);
        defer {
            os.closeSocket(sockfd_accept);
            std.debug.print("connection to socket {any} closed\n", .{sockfd_accept});
        }
        std.debug.print("accepted connection to socket {any}\n", .{sockfd_accept});

        var buffer: [BUFFER_SIZE]u8 = undefined;
        // Receive incoming messages.
        while (true) {
            const msg_len = try std.os.recv(sockfd_accept, &buffer, 0);
            if (msg_len == 0) break;
            const socket_msg = buffer[0..msg_len];
            std.debug.print("    Received message:\n    {s}\n", .{socket_msg});

            // Echo received message.
            _ = try std.os.send(sockfd_accept, socket_msg, 0);
        }
    }
}

const ServerError = os.SocketError || os.BindError || os.ListenError || os.AcceptError || os.RecvFromError || os.SendError;
