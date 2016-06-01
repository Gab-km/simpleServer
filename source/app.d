module simpleServer.main;

import std.stdio;
import simpleServer.server: Server;
import simpleServer.util : readConf;

/*
 * Return values:
 *  0: normal
 *  1: invalid config
 */
int main()
{
    auto e_conf = readConf();
    if (e_conf.isLeft)
    {
        stderr.writeln(e_conf.left());
        return 1;
    }

    auto conf = e_conf.right();
    writeln("Start simpleServer.");
    writefln(" wwwroot: %s", conf.wwwroot);
    auto server = new Server(conf);
    server.run();

    return 0;
}