module simpleServer.server;

import std.socket;
import std.stdio;
import std.string;
import std.array;
import std.algorithm;
import std.datetime : dur;

import simpleServer.httpRequest;
import simpleServer.httpResponse;
import simpleServer.util : Config;

class Server
{
    this(Config config)
    {
        conf = config;
    }

    void run()
    {
        auto addressFamily = AddressFamily.INET;
        auto sock = new TcpSocket(addressFamily);
        scope(exit) sock.close();

        auto address = findAddress(addressFamily);
        sock.bind(address);

        while(true)
        {
            sock.listen(1);
            write("Waiting for connection... ");
            auto listener = sock.accept();
            scope(exit) listener.close();
            listener.setOption(SocketOptionLevel.SOCKET,
                 SocketOption.RCVTIMEO,
                 dur!"seconds"(3));
            auto laddr = listener.remoteAddress;
            writeln("Accepted.\n");

            auto received = receive(listener);
            if (received.length == 0)
            {
                debug
                {
                    writeln("received.length is 0.");
                }
                continue;
            }
            auto request = HttpRequest.interpret(received.getString());
            auto response = HttpResponse.create(conf, request);

            debug
            {
                writeln(response.getHeader());
            }
            listener.send(response.toResponse());
        }
    }

private:
    Config conf;

    ubyte[] receive(Socket listener)
    {
        auto buffer = appender!(ubyte[])();
        while(true)
        {
            ubyte[1024] buf;
            auto receivedLength = listener.receive(buf);
            if (receivedLength <= 0) break;
            buffer.put(buf.array);
            if (receivedLength < 1024) break;
        }

        return buffer.data;
    }

    Address findAddress(AddressFamily addressFamily)
    {
        auto addresses = getAddress(cast(char[])(conf.hostname), conf.port);
        auto candidates = find!(a => a.addressFamily == addressFamily)(addresses);
        if (candidates.length == 0)
        {
            throw new Exception(format("No candidates of server: %s:%d", conf.hostname, conf.port));
        }
        writefln(" Target: %s", candidates[0]);

        return candidates[0];
    }
}

char[] getString(ubyte[] buf)
{
    auto request = cast(char[]) buf;
    writeln(request);
    return request;
}
