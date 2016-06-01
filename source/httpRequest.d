module simpleServer.httpRequest;

import std.array;
import std.string;
import std.algorithm;

class HttpRequestLine
{
    @property char[] methodName() { return method_name; }
    @property char[] uriAddress() { return uri_address; }
    @property char[] httpVersion() { return http_version; }

    this(char[] requestLine)
    {
        auto rl = split(requestLine);
        method_name = rl[0];
        auto a_p = split(rl[1], "?");
        uri_address = a_p[0];
        if (a_p.length > 1)
        {
            parameters = split(a_p[1], "&");
        }
        http_version = rl[2];
    }
private:
    char[] method_name;
    char[] uri_address;
    char[] http_version;
    char[][] parameters;
}

class HttpRequest
{
    @property HttpRequestLine requestLine() { return request_line; }
    @property string[] requests() { return _requests; }

    this(char[][] request)
    {
        request_line = new HttpRequestLine(request[0]);
        _requests = map!(cs => cast(string) cs)(request).array;
    }

    static HttpRequest interpret(char[] httpRequest)
    {
        auto lines = splitLines(httpRequest);
        return new HttpRequest(lines);
    }

private:
    HttpRequestLine request_line;
    string[] _requests;
}
