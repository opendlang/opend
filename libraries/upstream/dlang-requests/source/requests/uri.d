module requests.uri;

import std.experimental.logger;
import std.array;
import std.format;
import std.algorithm;
import std.conv;
import std.typecons;
import requests.utils;
static import requests.idna;

class UriException: Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) @safe pure {
        super(msg, file, line);
    }
}

struct URI {
    import std.string;
    private {
        string _uri;
        string _scheme;
        string _username;
        string _password;
        ushort _port=80;
        string _host;
        string _path="/";
        string _query;
        string _original_host;      // can differ from _host if host is unicode
    }
    this(string uri) @safe pure {
        _uri = uri;
        auto parsed = uri_parse(uri);
        if ( !parsed ) {
            throw new UriException("Can't parse uri '" ~ _uri ~ "'");
        }
    }
    
    bool uri_parse(string uri) @safe pure {
        auto i = uri.findSplit("://");
        string   rest, authority, path_and_query;
        if ( i[1].length ) {
            _scheme = i[0].toLower;
            rest = i[2];
        } else {
            return false;
        }
        if ( _scheme !in standard_ports ) {
            return false;
        }
        // separate Authority from path and query
        auto query = rest.indexOf("?");
        auto path = rest.indexOf("/");
        // auth/p?q p>0 q>p
        // auth/p   p>0 q=-1
        // auth?q/p p>0 q<p
        // auth?q   p=-1 q>0
        // auth     p=-1 q=-1
        if ( path >= 0 ) {
            if ( query > path || query == -1 ) {
                // a/p?q or a/p
                authority = rest[0..path];
                path_and_query = rest[path+1..$];
            } else if ( query < path ) {
                // a?q/p
                authority = rest[0..query];
                path_and_query = rest[query..$];
            }
        } else {
            if ( query >= 0) {
                // auth?q   p=-1 q>0
                authority = rest[0..query];
                path_and_query = rest[query..$];
            } else {
                // auth     p=-1 q=-1
                authority = rest;
                path_and_query = "";
            }
        }

        // find user/password/host:port in authority
        i = authority.findSplit("@");
        string up;
        string hp;
        if ( i[1].length ) {
            up = i[0];
            hp = i[2];
        } else {
            hp = i[0];
        }

        i = hp.findSplit(":");
        _original_host = i[0];
        _host = i[0];
        _port = i[2].length ? to!ushort(i[2]) : standard_ports[_scheme];

        if ( up.length ) {
            i = up.findSplit(":");
            _username = i[0];
            _password = i[2];
        }
        // finished with authority
        // handle path and query
        if ( path_and_query.length ) {
            i = path_and_query.findSplit("?");
            _path = "/" ~ i[0];
            if ( i[2].length) {
                _query = "?" ~ i[2];
            }
        }
        //
        return true;
    }
    
    string recalc_uri(Flag!"params" params = Yes.params) const pure @safe {
        string userinfo;
        if ( _username ) {
            userinfo = "%s".format(_username);
            if ( _password ) {
                userinfo ~= ":" ~ _password;
            }
            userinfo ~= "@";
        }
        string r = "%s://%s%s".format(_scheme, userinfo, _host);
        if ( _scheme !in standard_ports || standard_ports[_scheme] != _port ) {
            r ~= ":%d".format(_port);
        }
        r ~= _path;
        if ( params == Flag!"params".yes && _query ) {
            r ~= _query;
        }
        return r;
    }
    mixin(Getter_Setter!string("scheme"));
    mixin(Getter_Setter!string("host"));
    mixin(Getter_Setter!string("username"));
    mixin(Getter_Setter!string("password"));
    mixin(Getter_Setter!ushort("port"));
    mixin(Getter_Setter!string("path"));
    mixin(Getter("query"));
    mixin(Getter("original_host"));
    @property void query(string s) {
        if ( s[0]=='?' ) {
            _query = s;
        }
        else {
            _query = "?" ~ s;
        }
    }
//    mixin(setter("scheme"));
//    mixin(setter("host"));
//    mixin(setter("username"));
//    mixin(setter("password"));
//    mixin(setter("port"));
//    mixin(setter("path"));
//    mixin(setter("query"));
    @property auto uri(Flag!"params" params = Yes.params) pure @safe const {
        return recalc_uri(params);
    }
    @property void uri(string s) @trusted {
        _uri = s;
        //        auto parsed = uri_grammar(s);
        //        if ( !parsed.successful || parsed.matches.joiner.count != __uri.length) {
        //            throw new UriException("Can't parse uri '" ~ __uri ~ "'");
        //        }
        //        traverseTree(parsed);
    }
    void idn_encode() @safe {
        _host = requests.idna.idn_encode(_original_host);
    }
}
unittest {
    import std.exception;
    import std.experimental.logger;
    
    globalLogLevel(LogLevel.info);
    auto a = URI("http://example.com/");
    assert(a.scheme == "http");
    assert(a.host == "example.com");
    assert(a.path == "/");
    a = URI("https://igor@example.com:1234");
    assert(a.scheme == "https");
    assert(a.host == "example.com");
    assert(a.username == "igor");
    assert(a.path == "/");
    a = URI("https://example.com?a");
    assert(a.scheme == "https");
    assert(a.host == "example.com");
    assert(a.path == "/");
    assert(a.query == "?a");
    a = URI("https://example.com?a=/test");
    assert(a.scheme == "https");
    assert(a.host == "example.com");
    assert(a.path == "/");
    assert(a.query == "?a=/test");
    a = URI("http://igor:pass;word@example.com:1234/abc?q=x");
    assert(a.password == "pass;word");
    assert(a.port == 1234);
    assert(a.path == "/abc");
    assert(a.query == "?q=x");
    assert(a.uri(No.params) == "http://igor:pass;word@example.com:1234/abc",
        "Expected http://igor:pass;word@example.com:1234/abc, got %s".format(a.uri(No.params)));
    a.scheme = "https";
    a.query = "x=y";
    a.port = 345;
    auto expected = "https://igor:pass;word@example.com:345/abc?x=y";
    assert(a.uri == expected, "Expected '%s', got '%s'".format(expected, a.uri));
    assertThrown!UriException(URI("@unparsable"));
    a = URI("http://registrera-domän.se");
    a.idn_encode();
    assert(a.host == "xn--registrera-domn-elb.se");
    assertThrown!UriException(URI("cnn://deeplink?section=livetv&subsection=sliver&stream=CNN1"));
}

