const std = @import("std");
const os = std.os;

pub fn main() !void {
    try run_server(4096, .{ 127, 0, 0, 1 }, 8888);
}

const ServerError = os.SocketError || os.BindError || os.ListenError || os.AcceptError || os.RecvFromError || SendHttpResponseError;

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
        std.debug.print("closed socket {d}\n", .{sockfd});
    }
    std.debug.print("opened socket {d}\n", .{sockfd});

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
        "listening at @{d}.{d}.{d}.{d}:{d}\n",
        .{ host[0], host[1], host[2], host[3], port },
    );

    // Accept an incoming connection.
    while (true) {
        const sockfd_accept = try os.accept(sockfd, null, null, 0);
        defer {
            os.closeSocket(sockfd_accept);
            std.debug.print("connection to socket {d} closed\n", .{sockfd_accept});
        }
        std.debug.print("accepted connection to socket {d}\n", .{sockfd_accept});

        var buffer: [BUFFER_SIZE]u8 = undefined;
        // Receive incoming messages.
        const msg_len = try std.os.recv(sockfd_accept, &buffer, 0);
        if (msg_len == 0) break;
        const socket_msg = buffer[0..msg_len];
        std.debug.print("    Received message:\n{s}\n", .{socket_msg});

        // Send response.
        _ = try sendHttpResponse(BUFFER_SIZE, sockfd_accept, socket_msg);
    }
}

const SendHttpResponseError = os.SendError || HttpHeadersIterator.NextError || error{
    Overflow,
    NoStartLine,
    BadStartLine,
};

fn sendHttpResponse(
    comptime BUFFER_SIZE: usize,
    sockfd: os.socket_t,
    request: []const u8,
) SendHttpResponseError!void {
    const start_line = request[0 .. std.mem.indexOf(u8, request, "\r\n") orelse request.len];
    if (request.len == 0) return SendHttpResponseError.NoStartLine;
    // TODO don't assume start line is OK!

    // Make the writer object.
    var send_writer = OsSendWriter{ .sockfd = sockfd };
    var buf_send_writer = std.io.BufferedWriter(
        BUFFER_SIZE,
        OsSendWriter.Writer,
    ){ .unbuffered_writer = send_writer.writer() };
    var writer = buf_send_writer.writer();
    var json_writer = std.json.writeStream(writer, 3);

    _ = try writer.write("HTTP/1.1 200 OK\r\n\r\n");

    var headers_iter = HttpHeadersIterator.init(request[start_line.len + 2 ..]);

    // Build the JSON blob.
    try json_writer.beginObject();
    while (try headers_iter.next()) |header| {
        try json_writer.objectField(header[0]);
        try json_writer.emitString(header[1]);
    }
    try json_writer.endObject();

    // Flush the buffer.
    try buf_send_writer.flush();
}

const OsSendWriter = struct {
    sockfd: os.socket_t,

    const Self = @This();

    const WriteError = os.SendError;

    pub fn write(self: *Self, str: []const u8) WriteError!usize {
        return os.send(self.sockfd, str, 0);
    }

    pub const Writer = std.io.Writer(*Self, WriteError, write);

    pub fn writer(self: *Self) Writer {
        return .{ .context = self };
    }
};

const HttpHeadersIterator = struct {
    lines_iter: std.mem.SplitIterator(u8),

    const Self = @This();

    pub fn init(request: []const u8) Self {
        return .{ .lines_iter = .{ .buffer = request, .delimiter = "\r\n", .index = 0 } };
    }

    const NextError = error{NoDivider};

    pub fn next(self: *Self) !?struct { []const u8, []const u8 } {
        const DIVIDER: []const u8 = ": ";

        const line = self.lines_iter.next() orelse return null;
        if (line.len == 0) return null;

        const div_pos = std.mem.indexOf(u8, line, DIVIDER) orelse return NextError.NoDivider;
        const result = .{
            line[0..div_pos],
            line[div_pos + DIVIDER.len ..],
        };
        return result;
    }
};
