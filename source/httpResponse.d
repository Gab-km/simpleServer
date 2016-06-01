module simpleServer.httpResponse;

import std.string;
import std.file;
import std.format;
import std.array;
import std.datetime;
import std.algorithm;
import std.path;

import simpleServer.httpRequest;
import simpleServer.util;

abstract class HttpResponse
{
    @property char[] httpVersion() { return http_version; }
    @property int statusCode() { return status_code; }
    @property string reasonPhrase() { return reason_phrase; }
    @property void[] responseBody() { return response_body; }

    static HttpResponse create(Config conf, HttpRequest request)
    {
        auto hrl = request.requestLine;
        if (!canFind(["GET", "HEAD"], hrl.methodName))
        {
            return new HttpResponse501(hrl.httpVersion);
        }
        auto filePath = conf.wwwroot ~ substituteRootPath(hrl.uriAddress);
        if (exists(filePath))
        {
            return new HttpResponse200(hrl.httpVersion, filePath, hrl.methodName, conf.mimeTypes);
        }
        else
        {
            return new HttpResponse404(hrl.httpVersion);
        }
    }

    string getHeader()
    {
        auto strBuilder = appender!string;
        strBuilder.put(makeStatusLine());
        strBuilder.put(makeDate());
        strBuilder.put(makeContentLength());
        strBuilder.put(makeContentType());
        strBuilder.put(makeAllow());
        strBuilder.put(makeServer());
        strBuilder.put(makeConnection());
        return strBuilder.data;
    }

    const(void)[] toResponse()
    {
        auto header = getHeader();
        return header ~ makeResponseBody();
    }

protected:
    char[] http_version;
    int status_code;
    string reason_phrase;
    void[] response_body;

    string makeStatusLine()
    {
        return format("%s %s %s\r\n", http_version, status_code, reason_phrase);
    }

    string makeDate()
    {
        auto sd = Clock.currTime();
        auto imf = new IMFFixDate(cast(DateTime) sd);
        return format("Date: %s\r\n", imf);
    }

    string makeContentLength()
    {
        return format("Content-Length: %s\r\n", response_body.length);
    }

    final string makeContentLengthZero()
    {
        return "Content-Length: 0\r\n";
    }

    string makeContentType()
    {
        // default value, not from any resources.
        return "Content-Type: text/html; charset=utf-8\r\n";
    }

    string makeAllow()
    {
        // default value is an empty string.
        return "";
    }

    string makeServer()
    {
        return "Server: simpleServer\r\n";
    }

    string makeConnection()
    {
        return "Connection: Keep-Alive\r\n";
    }

    final string makeConnectionClose()
    {
        return "Connection: close\r\n";
    }

    void[] makeResponseBody()
    {
        return "\r\n" ~ response_body;
    }

private:
    static string substituteRootPath(char[] uri_addr)
    {
        if (uri_addr == "/")
        {
            return "/index.html";
        }
        else
        {
            return cast(string) uri_addr;
        }
    }
}

class HttpResponse200 : HttpResponse
{
    this(char[] httpVersion, string filePath, char[] methodName, string[string] mimeTypes)
    {
        http_version = httpVersion;
        status_code = 200;
        reason_phrase = "OK";
        response_body = read(filePath);
        method_name = methodName;
        mime_type = getMimeType(filePath, mimeTypes);
    }

protected:
    override void[] makeResponseBody()
    {
        if (method_name == "HEAD")
        {
            return [];
        }
        else
        {
            return super.makeResponseBody();
        }
    }

    override string makeContentType()
    {
        return "Content-Type: " ~ mime_type ~ "; charset=utf-8\r\n";
    }
  
private:
    char[] method_name;
    string mime_type;

    string getMimeType(string filePath, string[string] mimeTypes)
    {
        auto ext = extension(filePath)[1..$];
        debug
        {
            import std.stdio;
            writefln("extension: %s", ext);
        }
        if (ext in mimeTypes)
        {
            return mimeTypes[ext];
        }
        else
        {
            //return "application/octet-stream";
            // Is it good to get from Accept in the request?
            return "text/html";
        }
    }
}

class HttpResponse404 : HttpResponse
{
    this(char[] httpVersion)
    {
        http_version = httpVersion;
        status_code = 404;
        reason_phrase = "Not Found";
        response_body = [];
    }

protected:
    override string makeContentLength()
    {
        return makeContentLengthZero();
    }

    override string makeConnection()
    {
        return makeConnectionClose();
    }
}

class HttpResponse501 : HttpResponse
{
    this(char[] httpVersion)
    {
        http_version = httpVersion;
        status_code = 501;
        reason_phrase = "Not Implemented";
        response_body = [];
    }

protected:
    override string makeContentLength()
    {
        return makeContentLengthZero();
    }

    override string makeAllow()
    {
        return "Allow: GET, HEAD\r\n";
    }

    override string makeConnection()
    {
        return makeConnectionClose();
    }
}
