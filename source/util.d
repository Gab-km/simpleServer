module simpleServer.util;

import std.datetime;
import core.exception;
import std.format;
import std.stdio;
import std.file;
import std.json;

import darjeeling.either;

class IMFFixDate
{
    this(DateTime dt)
    {
        auto dow = getDayOfWeekName(dt);
        if (dow.isRight)
        {
            dayOfWeek = dow.right();
        }
        else
        {
            throw new Exception(dow.left());
        }
        day = dt.day;
        auto mon = getMonthName(dt);
        if (mon.isRight)
        {
            month = mon.right();
        }
        else
        {
            throw new Exception(mon.left());
        }
        year = dt.year;
        hour = dt.hour;
        minute = dt.minute;
        second = dt.second;
        tz = "JST";  // bad solution...
    }
  
    override string toString()
    {
        // example:
        //   Sun, 06 Nov 1994 08:49:37 GMT
        return format("%s, %02d %s %d %02d:%02d:%02d %s",
                    dayOfWeek,
                    day,
                    month,
                    year,
                    hour,
                    minute,
                    second,
                    tz);
    }

    unittest
    {
        auto dt = DateTime(1994, 11, 6, 8, 49, 37);
        auto sut = new IMFFixDate(dt);
        assert(sut.toString() == "Sun, 06 Nov 1994 08:49:37 JST");
    }

private:
    string dayOfWeek;
    ubyte day;
    string month;
    short year;
    ubyte hour;
    ubyte minute;
    ubyte second;
    string tz;

    alias either = Either!(string, string);

    either getDayOfWeekName(DateTime dt)
    {
        switch (dt.dayOfWeek)
        {
            case DayOfWeek.sun:
                return either.right("Sun");
            case DayOfWeek.mon:
                return either.right("Mon");
            case DayOfWeek.tue:
                return either.right("Tue");
            case DayOfWeek.wed:
                return either.right("Wed");
            case DayOfWeek.thu:
                return either.right("Thu");
            case DayOfWeek.fri:
                return either.right("Fri");
            case DayOfWeek.sat:
                return either.right("Sat");
            default:
                return either.left(format("Invalid dayOfWeek: %d", dt.dayOfWeek));
        }
    }

    either getMonthName(DateTime dt)
    {
        switch (dt.month)
        {
            case Month.jan:
                return either.right("Jan");
            case Month.feb:
                return either.right("Feb");
            case Month.mar:
                return either.right("Mar");
            case Month.apr:
                return either.right("Apr");
            case Month.may:
                return either.right("May");
            case Month.jun:
                return either.right("Jun");
            case Month.jul:
                return either.right("Jul");
            case Month.aug:
                return either.right("Aug");
            case Month.sep:
                return either.right("Sep");
            case Month.oct:
                return either.right("Oct");
            case Month.nov:
                return either.right("Nov");
            case Month.dec:
                return either.right("Dec");
            default:
                return either.left(format("Invalid month: %d", dt.month));
        }
    }
}

class Config
{
    @property string wwwroot() { return _wwwroot; }
    @property void wwwroot(string value) { _wwwroot = value; }
    @property string hostname() { return _hostname; }
    @property void hostname(string value) { _hostname = value; }
    @property ushort port() { return _port; }
    @property void port(ushort value) { _port = value; }
    @property string[string] mimeTypes() { return _mimeTypes; }
    @property void mimeTypes(string[string] value) { _mimeTypes = value; }

private:
    string _wwwroot;
    string _hostname;
    ushort _port;
    string[string] _mimeTypes;
}

Either!(string, Config) readConf()
{
    alias either = Either!(string, Config);

    auto confPath = "./conf.json";
    if (!exists(confPath))
    {
        return either.left("conf.json doesn't exist");
    }
    auto confJSON = parseJSON(readText(confPath));
    auto conf = new Config();
    Either!(string, JSONValue) getJSONValue(string keyName)
    {
        auto msgTemplate = "'%s' in conf.json is null or not defined";

        auto existsField = keyName in confJSON.object;
        if (existsField)
        {
            return Either!(string, JSONValue).right(confJSON[keyName]);
        }
        else
        {
            return Either!(string, JSONValue).left(format(msgTemplate, keyName));
        }
    }

    auto wwwroot = getJSONValue("wwwroot");
    if (wwwroot.isLeft)
    {
        return either.left(wwwroot.left());
    }
    else
    {
        conf.wwwroot = wwwroot.right().str;
    }
    auto hostname = getJSONValue("hostname");
    if (hostname.isLeft)
    {
        return either.left(hostname.left());
    }
    else
    {
        conf.hostname = hostname.right().str;
    }
    auto port = getJSONValue("port");
    if (port.isLeft)
    {
        return either.left(port.left());
    }
    else
    {
        conf.port = cast(ushort) port.right().integer;
    }
    auto mimeTypes = getJSONValue("mime-types");
    if (mimeTypes.isLeft)
    {
        // if 'mime-types' is not defined in conf.json,
        // set empty assoc.
        string[string] empAssoc;
        conf.mimeTypes = empAssoc;
    }
    else
    {
        auto jobj = mimeTypes.right().object;
        string[string] mts;
        foreach (mime, jarray; jobj)
        {
            foreach (ext; jarray.array)
            {
                // if extension is duplicated, overwrites.
                mts[ext.str] = mime;
            }
        }
        mts.rehash;
        conf.mimeTypes = mts;
    }

    return either.right(conf);
}
