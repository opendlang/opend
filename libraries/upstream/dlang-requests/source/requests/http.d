module requests.http;

private:
import std.algorithm;
import std.array;
import std.ascii;
import std.conv;
import std.datetime;
import std.exception;
import std.format;
import std.stdio;
import std.range;
import std.string;
import std.traits;
import std.typecons;
import std.experimental.logger;
import core.thread;

import requests.streams;
import requests.uri;
import requests.utils;
import requests.base;
import requests.connmanager;
import requests.rangeadapter;

static immutable ushort[] redirectCodes = [301, 302, 303, 307, 308];

enum   HTTP11 = 101;
enum   HTTP10 = 100;

static immutable string[string] proxies;
shared static this() {
    import std.process;
    import std.string;
    foreach(p; ["http", "https", "all"])
    {
        auto v = environment.get(p ~ "_proxy", environment.get(p.toUpper() ~ "_PROXY"));
        if ( v !is null && v.length > 0 )
        {
            debug(requests) tracef("will use %s for %s as proxy", v, p);
            proxies[p] = v;
        }
    }
}

public class MaxRedirectsException: Exception {
    this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow {
        super(message, file, line, next);
    }
}

///
///
///
//public auto queryParams(T...)(T params) pure nothrow @safe
//{
//    static assert (T.length % 2 == 0, "wrong args count");
//
//    QueryParam[] output;
//    output.reserve = T.length / 2;
//
//    void queryParamsHelper(T...)(T params, ref QueryParam[] output)
//    {
//        static if (T.length > 0)
//        {
//            output ~= QueryParam(params[0].to!string, params[1].to!string);
//            queryParamsHelper(params[2..$], output);
//        }
//    }
//
//    queryParamsHelper(params, output);
//    return output;
//}

///
/// Response - result of request execution.
///
/// Response.code - response HTTP code.
/// Response.status_line - received HTTP status line.
/// Response.responseHeaders - received headers.
/// Response.responseBody - container for received body
/// Response.history - for redirected responses contain all history
///
public class HTTPResponse : Response {
    private {
        string              _status_line;

        HTTPResponse[]      _history; // redirects history

        mixin(Setter!string("status_line"));

        int                 _version;
    }

    ~this() {
        _responseHeaders = null;
        _history.length = 0;
    }

    mixin(Getter("status_line"));

    @property final string[string] responseHeaders() @safe @nogc nothrow {
        return _responseHeaders;
    }
    @property final HTTPResponse[] history() @safe @nogc nothrow {
        return _history;
    }

    private int parse_version(in string v) pure const nothrow @safe {
        // try to parse HTTP/1.x to version
        try if ( v.length > 5 ) {
            return (v[5..$].split(".").map!"to!int(a)".array[0..2].reduce!((a,b) => a*100 + b));
        } catch (Exception e) {
        }
        return 0;
    }
    unittest {
        auto r = new HTTPResponse();
        assert(r.parse_version("HTTP/1.1") == 101);
        assert(r.parse_version("HTTP/1.0") == 100);
        assert(r.parse_version("HTTP/0.9") == 9);
        assert(r.parse_version("HTTP/xxx") == 0);
    }
}

///
/// Request.
/// Configurable parameters:
/// $(B method) - string, method to use (GET, POST, ...)
/// $(B headers) - string[string], add any additional headers you'd like to send.
/// $(B authenticator) - class Auth, class to send auth headers.
/// $(B keepAlive) - bool, set true for keepAlive requests. default true.
/// $(B maxRedirects) - uint, maximum number of redirects. default 10.
/// $(B maxHeadersLength) - size_t, maximum length of server response headers. default = 32KB.
/// $(B maxContentLength) - size_t, maximun content length. delault - 0 = unlimited.
/// $(B bufferSize) - size_t, send and receive buffer size. default = 16KB.
/// $(B verbosity) - uint, level of verbosity(0 - nothing, 1 - headers, 2 - headers and body progress). default = 0.
/// $(B proxy) - string, set proxy url if needed. default - null.
/// $(B cookie) - Tuple Cookie, Read/Write cookie You can get cookie setted by server, or set cookies before doing request.
/// $(B timeout) - Duration, Set timeout value for connect/receive/send.
///
public struct HTTPRequest {
    private {
        string         _method = "GET";
        URI            _uri;
        string[string] _headers;
        string[]       _filteredHeaders;
        Auth           _authenticator;
        bool           _keepAlive = true;
        uint           _maxRedirects = 10;
        size_t         _maxHeadersLength = 32 * 1024;   // 32 KB
        size_t         _maxContentLength;               // 0 - Unlimited
        string         _proxy;
        uint           _verbosity = 0;                  // 0 - no output, 1 - headers, 2 - headers+body info
        Duration       _timeout = 30.seconds;
        size_t         _bufferSize = 16*1024; // 16k
        bool           _useStreaming;                   // return iterator instead of completed request

        HTTPResponse[] _history;                        // redirects history
        DataPipe!ubyte _bodyDecoder;
        DecodeChunked  _unChunker;
        long           _contentLength;
        long           _contentReceived;
        SSLOptions     _sslOptions;
        string         _bind;
        _UH            _userHeaders;

        RefCounted!ConnManager      _cm;
        RefCounted!Cookies          _cookie;
        string[URI]                 _permanent_redirects;            // cache 301 redirects for GET requests
        MultipartForm               _multipartForm;

        NetStreamFactory  _socketFactory;

        QueryParam[]        _params;
        string              _contentType;
        InputRangeAdapter   _postData;
    }
    package HTTPResponse   _response;

    mixin(Getter_Setter!string     ("method"));
    mixin(Getter_Setter!bool       ("keepAlive"));
    mixin(Getter_Setter!size_t     ("maxContentLength"));
    mixin(Getter_Setter!size_t     ("maxHeadersLength"));
    mixin(Getter_Setter!size_t     ("bufferSize"));
    mixin(Getter_Setter!uint       ("maxRedirects"));
    mixin(Getter_Setter!uint       ("verbosity"));
    mixin(Getter                   ("proxy"));
    mixin(Getter_Setter!Duration   ("timeout"));
    mixin(Setter!Auth              ("authenticator"));
    mixin(Getter_Setter!bool       ("useStreaming"));
    mixin(Getter                   ("contentLength"));
    mixin(Getter                   ("contentReceived"));
    mixin(Getter_Setter!SSLOptions ("sslOptions"));
    mixin(Getter_Setter!string     ("bind"));
    mixin(Setter!NetStreamFactory  ("socketFactory"));

    @property void sslSetVerifyPeer(bool v) pure @safe nothrow @nogc {
        _sslOptions.setVerifyPeer(v);
    }
    @property void sslSetKeyFile(string p, SSLOptions.filetype t = SSLOptions.filetype.pem) pure @safe nothrow @nogc {
        _sslOptions.setKeyFile(p, t);
    }
    @property void sslSetCertFile(string p, SSLOptions.filetype t = SSLOptions.filetype.pem) pure @safe nothrow @nogc {
        _sslOptions.setCertFile(p, t);
    }
    @property void sslSetCaCert(string path) pure @safe nothrow @nogc {
        _sslOptions.setCaCert(path);
    }
    //@property final void cookie(Cookie[] s) pure @safe @nogc nothrow {
    //    _cookie = s;
    //}
    @property final void proxy(string v) {
        if ( v != _proxy ) {
            _cm.clear();
        }
        _proxy = v;
    }
    //@property final Cookie[] cookie() pure @safe @nogc nothrow {
    //    return _cookie;
    //}

    this(string uri) {
        _uri = URI(uri);
        _cm = ConnManager(10);
    }
    ~this() {
        _headers = null;
        _authenticator = null;
        _history = null;
        _bodyDecoder = null;
        _unChunker = null;
        //if ( _cm ) {
        //    _cm.clear();
        //}
    }
    string toString() const {
        return "HTTPRequest(%s, %s)".format(_method, _uri.uri());
    }
    string format(string fmt) const {
        import std.array;
        import std.stdio;
        auto a = appender!string();
        auto f = FormatSpec!char(fmt);
        while (f.writeUpToNextSpec(a)) {
            switch(f.spec) {
                case 'h':
                    // Remote hostname.
                    a.put(_uri.host);
                    break;
                case 'm':
                    // method.
                    a.put(_method);
                    break;
                case 'p':
                    // Remote port.
                    a.put("%d".format(_uri.port));
                    break;
                case 'P':
                    // Path
                    a.put(_uri.path);
                    break;
                case 'q':
                    // query parameters supplied with url.
                    a.put(_uri.query);
                    break;
                case 'U':
                    a.put(_uri.uri());
                    break;
                default:
                    throw new FormatException("Unknown Request format spec " ~ f.spec);
            }
        }
        return a.data();
    }
    string select_proxy(string scheme) {
        if ( _proxy is null && proxies.length == 0 ) {
            debug(requests) tracef("proxy=null");
            return null;
        }
        if ( _proxy ) {
            debug(requests) tracef("proxy=%s", _proxy);
            return _proxy;
        }
        auto p = scheme in proxies;
        if ( p !is null && *p != "") {
            debug(requests) tracef("proxy=%s", *p);
            return *p;
        }
        p = "all" in proxies;
        if ( p !is null && *p != "") {
            debug(requests) tracef("proxy=%s", *p);
            return *p;
        }
        debug(requests) tracef("proxy=null");
        return null;
    }
    void clearHeaders() {
        _headers = null;
    }
    @property void uri(in URI newURI) {
        //handleURLChange(_uri, newURI);
        _uri = newURI;
    }
    /// Add headers to request
    /// Params:
    /// headers = headers to send.
    void addHeaders(in string[string] headers) {
        foreach(pair; headers.byKeyValue) {
            string _h = pair.key;
            switch(toLower(_h)) {
            case "host":
                _userHeaders.Host = true;
                break;
            case "user-agent":
                _userHeaders.UserAgent = true;
                break;
            case "content-length":
                _userHeaders.ContentLength = true;
                break;
            case "content-type":
                _userHeaders.ContentType = true;
                break;
            case "connection":
                _userHeaders.Connection = true;
                break;
            case "cookie":
                _userHeaders.Cookie = true;
                break;
            default:
                break;
            }
            _headers[pair.key] = pair.value;
        }
    }
    private void safeSetHeader(ref string[string] headers, bool userAdded, string h, string v) pure @safe {
        if ( !userAdded ) {
            headers[h] = v;
        }
    }
    /// Remove headers from request
    /// Params:
    /// headers = headers to remove.
    void removeHeaders(in string[] headers) pure {
        _filteredHeaders ~= headers;
    }
    ///
    /// compose headers to send
    ///
    private string[string] requestHeaders() {

        string[string] generatedHeaders;

        if ( _authenticator ) {
            _authenticator.
                authHeaders(_uri.host).
                byKeyValue.
                each!(pair => generatedHeaders[pair.key] = pair.value);
        }

        _headers.byKey.each!(h => generatedHeaders[h] = _headers[h]);

        safeSetHeader(generatedHeaders, _userHeaders.AcceptEncoding, "Accept-Encoding", "gzip,deflate");
        safeSetHeader(generatedHeaders, _userHeaders.UserAgent, "User-Agent", "dlang-requests");
        safeSetHeader(generatedHeaders, _userHeaders.Connection, "Connection", _keepAlive?"Keep-Alive":"Close");

        if ( !_userHeaders.Host )
        {
            generatedHeaders["Host"] = _uri.host;
            if ( _uri.scheme !in standard_ports || _uri.port != standard_ports[_uri.scheme] ) {
                generatedHeaders["Host"] ~= ":%d".format(_uri.port);
            }
        }

        if ( _cookie._array.length && !_userHeaders.Cookie ) {
            auto cs = _cookie._array.
                filter!(c => _uri.path.pathMatches(c.path) && _uri.host.domainMatches(c.domain)).
                map!(c => "%s=%s".format(c.attr, c.value)).
                joiner(";");
            if ( ! cs.empty )
            {
                generatedHeaders["Cookie"] = to!string(cs);
            }
        }

        _filteredHeaders.each!(h => generatedHeaders.remove(h));

        return generatedHeaders;
    }
    ///
    /// Build request string.
    /// Handle proxy and query parameters.
    ///
    private @property string requestString(QueryParam[] params = null) {
        auto query = _uri.query.dup;
        if ( params ) {
            query ~= params2query(params);
            if ( query[0] != '?' ) {
                query = "?" ~ query;
            }
        }
        string actual_proxy = select_proxy(_uri.scheme);
        if ( actual_proxy && _uri.scheme != "https" ) {
            return "%s %s%s HTTP/1.1\r\n".format(_method, _uri.uri(No.params), query);
        }
        return "%s %s%s HTTP/1.1\r\n".format(_method, _uri.path, query);
    }

    unittest {
        HTTPRequest request;
        request._uri = URI("https://www.blub.de/");
        import std.stdio;
        auto expected = "GET /?a=b&c=d HTTP/1.1\r\n";
        auto actual = request.requestString([QueryParam("a", "b"), QueryParam("c", "d")]);
        assert(expected == actual, "Expected\n  '%s' but got\n  '%s'".format(expected, actual));
    }

    ///
    /// encode parameters and build query part of the url
    ///
    private static string params2query(in QueryParam[] params) pure @safe {
        return params.
                map!(a => "%s=%s".format(a.key.urlEncoded, a.value.urlEncoded)).
                join("&");
    }
    //
    package unittest {
        assert(params2query(queryParams("a","b", "c", " d "))=="a=b&c=%20d%20");
    }
    ///
    /// Analyze received headers, take appropriate actions:
    /// check content length, attach unchunk and uncompress
    ///
    private void analyzeHeaders(in string[string] headers) {

        _contentLength = -1;
        _unChunker = null;
        auto contentLength = "content-length" in headers;
        if ( contentLength ) {
            try {
                string l = *contentLength;
                _contentLength = parse!long(l);
                // TODO: maybe add a strict mode that checks if l was parsed completely
                if ( _maxContentLength && _contentLength > _maxContentLength) {
                    throw new RequestException("ContentLength > maxContentLength (%d>%d)".
                                format(_contentLength, _maxContentLength));
                }
            } catch (ConvException e) {
                throw new RequestException("Can't convert Content-Length from %s".format(*contentLength));
            }
        }
        auto transferEncoding = "transfer-encoding" in headers;
        if ( transferEncoding ) {
            debug(requests) tracef("transferEncoding: %s", *transferEncoding);
            if ( (*transferEncoding).toLower == "chunked") {
                _unChunker = new DecodeChunked();
                _bodyDecoder.insert(_unChunker);
            }
        }
        auto contentEncoding = "content-encoding" in headers;
        if ( contentEncoding ) switch (*contentEncoding) {
            default:
                throw new RequestException("Unknown content-encoding " ~ *contentEncoding);
            case "gzip":
            case "deflate":
                _bodyDecoder.insert(new Decompressor!ubyte);
        }

    }
    ///
    /// Called when we know that all headers already received in buffer.
    /// This routine does not interpret headers content (see analyzeHeaders).
    /// 1. Split headers on lines
    /// 2. store status line, store response code
    /// 3. unfold headers if needed
    /// 4. store headers
    ///
    private void parseResponseHeaders(in ubyte[] input, string lineSep) {
        string lastHeader;
        auto buffer = cast(string)input;

        foreach(line; buffer.split(lineSep).map!(l => l.stripRight)) {
            if ( ! _response.status_line.length ) {
                debug (requests) tracef("statusLine: %s", line);
                _response.status_line = line;
                if ( _verbosity >= 1 ) {
                    writefln("< %s", line);
                }
                auto parsed = line.split(" ");
                if ( parsed.length >= 2 ) {
                    _response.code = parsed[1].to!ushort;
                    _response._version = _response.parse_version(parsed[0]);
                }
                continue;
            }
            if ( line[0] == ' ' || line[0] == '\t' ) {
                // unfolding https://tools.ietf.org/html/rfc822#section-3.1
                if ( auto stored = lastHeader in _response._responseHeaders) {
                    *stored ~= line;
                }
                continue;
            }
            auto parsed = line.findSplit(":");
            auto header = parsed[0].toLower;
            auto value = parsed[2].strip;

            if ( _verbosity >= 1 ) {
                writefln("< %s: %s", header, value);
            }

            lastHeader = header;
            debug (requests) tracef("Header %s = %s", header, value);

            if ( header != "set-cookie" ) {
                auto stored = _response.responseHeaders.get(header, null);
                if ( stored ) {
                    value = stored ~ "," ~ value;
                }
                _response._responseHeaders[header] = value;
                continue;
            }
            _cookie._array ~= processCookie(value);
        }
    }

    ///
    /// Process Set-Cookie header from server response
    ///
    private Cookie[] processCookie(string value ) pure {
        // cookie processing
        //
        // as we can't join several set-cookie lines in single line
        // < Set-Cookie: idx=7f2800f63c112a65ef5082957bcca24b; expires=Mon, 29-May-2017 00:31:25 GMT; path=/; domain=example.com
        // < Set-Cookie: idx=7f2800f63c112a65ef5082957bcca24b; expires=Mon, 29-May-2017 00:31:25 GMT; path=/; domain=example.com, cs=ip764-RgKqc-HvSkxRxdQQAKW8LA; path=/; domain=.example.com; HttpOnly
        //
        Cookie[] res;
        string[string] kv;
        auto fields = value.split(";").map!strip;
        while(!fields.empty) {
            auto s = fields.front.findSplit("=");
            fields.popFront;
            if ( s[1] != "=" ) {
                continue;
            }
            auto k = s[0];
            auto v = s[2];
            switch(k.toLower()) {
                case "domain":
                    k = "domain";
                    break;
                case "path":
                    k = "path";
                    break;
                case "expires":
                    continue;
                case "max-age":
                    continue;
                default:
                    break;
            }
            kv[k] = v;
        }
        if ( "domain" !in kv ) {
            kv["domain"] = _uri.host;
        }
        if ( "path" !in kv ) {
            kv["path"] = _uri.path;
        }
        auto domain = kv["domain"]; kv.remove("domain");
        auto path   = kv["path"];   kv.remove("path");
        foreach(pair; kv.byKeyValue) {
            auto _attr = pair.key;
            auto _value = pair.value;
            auto cookie = Cookie(path, domain, _attr, _value);
            res ~= cookie;
        }
        return res;
    }

    private bool willFollowRedirect() {
        if ( !canFind(redirectCodes, _response.code) ) {
            return false;
        }
        if ( !_maxRedirects ) {
            return false;
        }
        if ( "location" !in _response.responseHeaders ) {
            return false;
        }
        return true;
    }
    private URI uriFromLocation(const ref URI uri, in string location) {
        URI newURI = uri;
        try {
            newURI = URI(location);
        } catch (UriException e) {
            debug(requests) trace("Can't parse Location:, try relative uri");
            newURI.path = location;
            newURI.uri = newURI.recalc_uri;
        }
        return newURI;
    }
    ///
    /// if we have new uri, then we need to check if we have to reopen existent connection
    ///
    private void checkURL(string url, string file=__FILE__, size_t line=__LINE__) {
        if (url is null && _uri.uri == "" ) {
            throw new RequestException("No url configured", file, line);
        }

        if ( url !is null ) {
            URI newURI = URI(url);
            //handleURLChange(_uri, newURI);
            _uri = newURI;
        }
    }
    ///
    /// Setup connection. Handle proxy and https case
    ///
    /// Place new connection in ConnManager cache
    ///
    private NetworkStream setupConnection()
    do {

        debug(requests) tracef("Set up new connection");
        NetworkStream stream;

        // on exit
        // place created connection to conn. manager
        // close connection purged from manager (if any)
        //
        scope(exit) {
            if ( stream )
            {
                if ( auto purged_connection = _cm.put(_uri.scheme, _uri.host, _uri.port, stream) )
                {
                    debug(requests) tracef("closing purged connection %s", purged_connection);
                    purged_connection.close();
                }
            }
        }

        if ( _socketFactory )
        {
            debug(requests) tracef("use socketFactory");
            stream = _socketFactory(_uri.scheme, _uri.host, _uri.port);
        }

        if ( stream ) // socket factory created connection
        {
            return stream;
        }

        URI   uri; // this URI will be used temporarry if we need proxy
        string actual_proxy = select_proxy(_uri.scheme);
        final switch (_uri.scheme) {
            case"http":
                if ( actual_proxy ) {
                    uri.uri_parse(actual_proxy);
                    uri.idn_encode();
                } else {
                    // use original uri
                    uri = _uri;
                }
                stream = new TCPStream();
                stream.bind(_bind);
                stream.connect(uri.host, uri.port, _timeout);
                break ;
            case"https":
                if ( actual_proxy ) {
                    uri.uri_parse(actual_proxy);
                    uri.idn_encode();
                    stream = new TCPStream();
                    stream.bind(_bind);
                    stream.connect(uri.host, uri.port, _timeout);
                    if ( verbosity>=1 ) {
                        writeln("> CONNECT %s:%d HTTP/1.1".format(_uri.host, _uri.port));
                    }
                    stream.send("CONNECT %s:%d HTTP/1.1\r\n".format(_uri.host, _uri.port));
                    if (uri.username)
                    {
                        debug(requests) tracef("Add Proxy-Authorization header");
                        auto auth = new BasicAuthentication(uri.username, uri.password);
                        auto header = auth.authHeaders("");
                        stream.send("Proxy-Authorization: %s\r\n".format(header["Authorization"]));
                    }
                    stream.send("\r\n");
                    while ( stream.isConnected ) {
                        ubyte[1024] b;
                        auto read = stream.receive(b);
                        if ( verbosity>=1) {
                            writefln("< %s", cast(string)b[0..read]);
                        }
                        debug(requests) tracef("read: %d", read);
                        if ( b[0..read].canFind("\r\n\r\n") || b[0..read].canFind("\n\n") ) {
                            debug(requests) tracef("proxy connection ready");
                            // convert connection to ssl
                            stream = new SSLStream(stream, _sslOptions, _uri.host);
                            break ;
                        } else {
                            debug(requests) tracef("still wait for proxy connection");
                        }
                    }
                } else {
                    uri = _uri;
                    stream = new SSLStream(_sslOptions);
                    stream.bind(_bind);
                    stream.connect(uri.host, uri.port, _timeout);
                    debug(requests) tracef("ssl connection to origin server ready");
                }
                break ;
        }

        return stream;
    }
    ///
    /// Request sent, now receive response.
    /// Find headers, split on headers and body, continue to receive body
    ///
    private void receiveResponse(NetworkStream _stream) {

        try {
            _stream.readTimeout = timeout;
        } catch (Exception e) {
            debug(requests) tracef("Failed to set read timeout for stream: %s", e.msg);
            return;
        }
        // Commented this out as at exit we can have alreade closed socket
        // scope(exit) {
        //     if ( _stream && _stream.isOpen ) {
        //         _stream.readTimeout = 0.seconds;
        //     }
        // }

        _bodyDecoder = new DataPipe!ubyte();
        scope(exit) {
            if ( !_useStreaming ) {
                _bodyDecoder = null;
                _unChunker = null;
            }
        }

        auto buffer = Buffer!ubyte();
        Buffer!ubyte partialBody;
        ptrdiff_t read;
        string lineSep = null, headersEnd = null;
        bool headersHaveBeenReceived;

        while( !headersHaveBeenReceived ) {

            auto b = new ubyte[_bufferSize];
            read = _stream.receive(b);

            debug(requests) tracef("read: %d", read);
            if ( read == 0 ) {
                break;
            }
            auto data = b[0..read];
            buffer.putNoCopy(data);
            if ( verbosity>=3 ) {
                writeln(data.dump.join("\n"));
            }

            if ( buffer.length > maxHeadersLength ) {
                throw new RequestException("Headers length > maxHeadersLength (%d > %d)".format(buffer.length, maxHeadersLength));
            }

            // Proper HTTP uses "\r\n" as a line separator, but broken servers sometimes use "\n".
            // Servers that use "\r\n" might have "\n" inside a header.
            // For any half-sane server, the first '\n' should be at the end of the status line, so this can be used to detect the line separator.
            // In any case, all the interesting points in the header for now are at '\n' characters, so scan the newly read data for them.
            foreach (idx; buffer.length-read..buffer.length)
            {
                if ( buffer[idx] == '\n' )
                {
                    if ( lineSep is null )
                    {
                        // First '\n'. Detect line/header endings.
                        // HTTP header sections end with a double line separator
                        lineSep = "\n";
                        headersEnd = "\n\n";
                        if ( idx > 0 && buffer[idx-1] == '\r' )
                        {
                            lineSep = "\r\n";
                            headersEnd = "\r\n\r\n";
                        }
                    }
                    else
                    {
                        // Potential header ending.
                        if ( buffer.data[0..idx+1].endsWith(headersEnd) )
                        {
                            auto ResponseHeaders = buffer.data[0..idx+1-headersEnd.length];
                            partialBody = buffer[idx+1..$];
                            _contentReceived += partialBody.length;
                            parseResponseHeaders(ResponseHeaders, lineSep);
                            headersHaveBeenReceived = true;
                            break;
                        }
                    }
                }
            }
        }

        analyzeHeaders(_response._responseHeaders);

        _bodyDecoder.putNoCopy(partialBody.data);

        auto v = _bodyDecoder.get();
        _response._responseBody.putNoCopy(v);

        // https://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.4
        if  (
                // document must not have body:
                (_method == "HEAD") || responseMustNotIncludeBody(_response.code) || 
                // we can receive doc without content length and without chunking only in streaming mode
                // see https://github.com/ikod/dlang-requests/issues/146
                ((_contentLength < 0 && _unChunker is null) && !_useStreaming)
            )
        {
            debug(requests) tracef("response without body");
            return;
        }

        _response._contentLength = _contentLength;
        _response._contentReceived = _contentReceived;

        if ( _verbosity >= 2 ) writefln("< %d bytes of body received", partialBody.length);

        while( true ) {
            if ( _contentLength >= 0 && _contentReceived >= _contentLength ) {
                debug(requests) trace("Body received.");
                break;
            }
            if ( _unChunker && _unChunker.done ) {
                break;
            }

            if ( _useStreaming && _response._responseBody.length && !redirectCodes.canFind(_response.code) ) {
                debug(requests) trace("streaming requested");
                // save _stream in closure
                auto __stream = _stream;
                auto __bodyDecoder = _bodyDecoder;
                auto __unChunker = _unChunker;
                auto __contentReceived = _contentReceived;
                auto __contentLength = _contentLength;
                auto __bufferSize = _bufferSize;
                auto __response = _response;
                auto __verbosity = _verbosity;

                // set up response
                _response._contentLength = _contentLength;
                _response.receiveAsRange.activated = true;
                _response.receiveAsRange.data = _response._responseBody.data;
                _response.receiveAsRange.cm = _cm;
                _response.receiveAsRange.read = delegate ubyte[] () {

                    while(true) {
                        // check if we received everything we need
                        if ( ( __unChunker && __unChunker.done )
                            || !__stream.isConnected()
                            || (__contentLength > 0 && __contentReceived >= __contentLength) )
                        {
                            debug(requests) trace("streaming_in receive completed");
                            __bodyDecoder.flush();
                            return __bodyDecoder.get();
                        }
                        // have to continue
                        auto b = new ubyte[__bufferSize];
                        try {
                            read = __stream.receive(b);
                        }
                        catch (Exception e) {
                            throw new RequestException("streaming_in error reading from socket", __FILE__, __LINE__, e);
                        }
                        debug(requests) tracef("streaming_in received %d bytes", read);

                        if ( read == 0 ) {
                            debug(requests) tracef("streaming_in: server closed connection");
                            __bodyDecoder.flush();
                            return __bodyDecoder.get();
                        }

                        if ( __verbosity>=3 ) {
                            writeln(b[0..read].dump.join("\n"));
                        }
                        __response._contentReceived += read;
                        __contentReceived += read;
                        __bodyDecoder.putNoCopy(b[0..read]);
                        auto res = __bodyDecoder.getNoCopy();
                        if ( res.length == 0 ) {
                            // there were nothing to produce (beginning of the chunk or no decompressed data)
                            continue;
                        }
                        if (res.length == 1) {
                            return res[0];
                        }
                        //
                        // I'd like to "return _bodyDecoder.getNoCopy().join;" but it is slower
                        //
                        auto total = res.map!(b=>b.length).sum;
                        // create buffer for joined bytes
                        ubyte[] joined = new ubyte[total];
                        size_t p;
                        // memcopy
                        foreach(ref _; res) {
                            joined[p .. p + _.length] = _;
                            p += _.length;
                        }
                        return joined;
                    }
                    assert(0);
                };
                // we prepared for streaming
                return;
            }

            auto b = new ubyte[_bufferSize];
            read = _stream.receive(b);

            if ( read == 0 ) {
                debug(requests) trace("read done");
                break;
            }
            if ( _verbosity >= 2 ) {
                writefln("< %d bytes of body received", read);
            }

            if ( verbosity>=3 ) {
                writeln(b[0..read].dump.join("\n"));
            }

            debug(requests) tracef("read: %d", read);
            _contentReceived += read;
            if ( _maxContentLength && _contentReceived > _maxContentLength ) {
                throw new RequestException("ContentLength > maxContentLength (%d>%d)".
                    format(_contentLength, _maxContentLength));
            }

            _bodyDecoder.putNoCopy(b[0..read]); // send buffer to all decoders

            _bodyDecoder.getNoCopy.             // fetch result and place to body
                each!(b => _response._responseBody.putNoCopy(b));

            debug(requests) tracef("receivedTotal: %d, contentLength: %d, bodyLength: %d", _contentReceived, _contentLength, _response._responseBody.length);

        }
        _bodyDecoder.flush();
        _response._responseBody.putNoCopy(_bodyDecoder.get());
        _response._contentReceived = _contentReceived;
    }
    ///
    /// Check that we received anything.
    /// Server can close previous connection (keepalive or not)
    ///
    private bool serverPrematurelyClosedConnection() pure @safe {
        immutable server_closed_connection = _response._responseHeaders.length == 0 && _response._status_line.length == 0;
        // debug(requests) tracef("server closed connection = %s (headers.length=%s, status_line.length=%s)",
        //     server_closed_connection, _response._responseHeaders.length,  _response._status_line.length);
        return server_closed_connection;
    }
    private bool isIdempotent(in string method) pure @safe nothrow {
        return ["GET", "HEAD"].canFind(method);
    }
    ///
    /// If we do not want keepalive request,
    /// or server signalled to close connection,
    /// then close it
    ///
    void close_connection_if_not_keepalive(NetworkStream _stream) {
        auto connection = "connection" in _response._responseHeaders;
        if ( !_keepAlive ) {
            _stream.close();
        } else switch(_response._version) {
            case HTTP11:
                // HTTP/1.1 defines the "close" connection option for the sender to signal that the connection
                // will be closed after completion of the response. For example,
                //        Connection: close
                // in either the request or the response header fields indicates that the connection
                // SHOULD NOT be considered `persistent' (section 8.1) after the current request/response is complete.
                // HTTP/1.1 applications that do not support persistent connections MUST include the "close" connection
                // option in every message.
                if ( connection && (*connection).toLower.split(",").canFind("close") ) {
                    _stream.close();
                }
                break;
            default:
                // for anything else close connection if there is no keep-alive in Connection
                if ( connection && !(*connection).toLower.split(",").canFind("keep-alive") ) {
                    _stream.close();
                }
                break;
        }
    }
    ///
    /// Send multipart for request.
    /// You would like to use this method for sending large portions of mixed data or uploading files to forms.
    /// Content of the posted form consist of sources. Each source have at least name and value (can be string-like object or opened file, see more docs for MultipartForm struct)
    /// Params:
    ///     url = url
    ///     sources = array of sources.
    deprecated("Use Request() instead of HTTPRequest(); will be removed 2019-07")
    HTTPResponse exec(string method="POST")(string url, MultipartForm sources) {
        import std.uuid;
        import std.file;

        checkURL(url);
        //if ( _cm is null ) {
        //    _cm = new ConnManager();
        //}

        NetworkStream _stream;
        _method = method;
        _response = new HTTPResponse;
        _response.uri = _uri;
        _response.finalURI = _uri;
        bool restartedRequest = false;

    connect:
        _contentReceived = 0;
        _response._startedAt = Clock.currTime;

        assert(_stream is null);

        _stream = _cm.get(_uri.scheme, _uri.host, _uri.port);

        if ( _stream is null ) {
            debug(requests) trace("create new connection");
            _stream = setupConnection();
        } else {
            debug(requests) trace("reuse old connection");
        }

        assert(_stream !is null);

        if ( !_stream.isConnected ) {
            debug(requests) trace("disconnected stream on enter");
            if ( !restartedRequest ) {
                debug(requests) trace("disconnected stream on enter: retry");
                assert(_cm.get(_uri.scheme, _uri.host, _uri.port) == _stream);

                _cm.del(_uri.scheme, _uri.host, _uri.port);
                _stream.close();
                _stream = null;

                restartedRequest = true;
                goto connect;
            }
            debug(requests) trace("disconnected stream on enter: return response");
            //_stream = null;
            return _response;
        }
        _response._connectedAt = Clock.currTime;

        Appender!string req;
        req.put(requestString());

        string   boundary = randomUUID().toString;
        string[] partHeaders;
        size_t   contentLength;

        foreach(ref part; sources._sources) {
            string h = "--" ~ boundary ~ "\r\n";
            string disposition = `form-data; name="%s"`.format(part.name);
            string optionals = part.
                parameters.byKeyValue().
                filter!(p => p.key!="Content-Type").
                map!   (p => "%s=%s".format(p.key, p.value)).
                join("; ");

            h ~= `Content-Disposition: ` ~ [disposition, optionals].join("; ") ~ "\r\n";

            auto contentType = "Content-Type" in part.parameters;
            if ( contentType ) {
                h ~= "Content-Type: " ~ *contentType ~ "\r\n";
            }

            h ~= "\r\n";
            partHeaders ~= h;
            contentLength += h.length + part.input.getSize() + "\r\n".length;
        }
        contentLength += "--".length + boundary.length + "--\r\n".length;

        auto h = requestHeaders();
        safeSetHeader(h, _userHeaders.ContentType, "Content-Type", "multipart/form-data; boundary=" ~ boundary);
        safeSetHeader(h, _userHeaders.ContentLength, "Content-Length", to!string(contentLength));

        h.byKeyValue.
            map!(kv => kv.key ~ ": " ~ kv.value ~ "\r\n").
                each!(h => req.put(h));
        req.put("\r\n");

        debug(requests) trace(req.data);
        if ( _verbosity >= 1 ) req.data.splitLines.each!(a => writeln("> " ~ a));

        try {
            _stream.send(req.data());
            foreach(ref source; sources._sources) {
                debug(requests) tracef("sending part headers <%s>", partHeaders.front);
                _stream.send(partHeaders.front);
                partHeaders.popFront;
                while (true) {
                    auto chunk = source.input.read();
                    if ( chunk.length <= 0 ) {
                        break;
                    }
                    _stream.send(chunk);
                }
                _stream.send("\r\n");
            }
            _stream.send("--" ~ boundary ~ "--\r\n");
            _response._requestSentAt = Clock.currTime;
            receiveResponse(_stream);
            _response._finishedAt = Clock.currTime;
        }
        catch (NetworkException e) {
            errorf("Error sending request: ", e.msg);
            _stream.close();
            return _response;
        }

        if ( serverPrematurelyClosedConnection()
        && !restartedRequest
        && isIdempotent(_method)
        ) {
            ///
            /// We didn't receive any data (keepalive connectioin closed?)
            /// and we can restart this request.
            /// Go ahead.
            ///
            debug(requests) tracef("Server closed keepalive connection");

            assert(_cm.get(_uri.scheme, _uri.host, _uri.port) == _stream);

            _cm.del(_uri.scheme, _uri.host, _uri.port);
            _stream.close();
            _stream = null;

            restartedRequest = true;
            goto connect;
        }

        if ( _useStreaming ) {
            if ( _response._receiveAsRange.activated ) {
                debug(requests) trace("streaming_in activated");
                return _response;
            } else {
                // this can happen if whole response body received together with headers
                _response._receiveAsRange.data = _response.responseBody.data;
            }
        }

        close_connection_if_not_keepalive(_stream);

        if ( _verbosity >= 1 ) {
            writeln(">> Connect time: ", _response._connectedAt - _response._startedAt);
            writeln(">> Request send time: ", _response._requestSentAt - _response._connectedAt);
            writeln(">> Response recv time: ", _response._finishedAt - _response._requestSentAt);
        }

        if ( willFollowRedirect ) {
            if ( _history.length >= _maxRedirects ) {
                _stream = null;
                throw new MaxRedirectsException("%d redirects reached maxRedirects %d.".format(_history.length, _maxRedirects));
            }
            // "location" in response already checked in canFollowRedirect
            immutable new_location = *("location" in _response.responseHeaders);
            immutable current_uri = _uri, next_uri = uriFromLocation(_uri, new_location);

            // save current response for history
            _history ~= _response;

            // prepare new response (for redirected request)
            _response = new HTTPResponse;
            _response.uri = current_uri;
            _response.finalURI = next_uri;
            _stream = null;

            // set new uri
            this._uri = next_uri;
            debug(requests) tracef("Redirected to %s", next_uri);
            if ( _method != "GET" && _response.code != 307 && _response.code != 308 ) {
                // 307 and 308 do not change method
                return this.get();
            }
            if ( restartedRequest ) {
                debug(requests) trace("Rare event: clearing 'restartedRequest' on redirect");
                restartedRequest = false;
            }
            goto connect;
        }

        _response._history = _history;
        return _response;
    }

    // we use this if we send from ubyte[][] and user provided Content-Length
    private void sendFlattenContent(T)(NetworkStream _stream, T content) {
        while ( !content.empty ) {
            auto chunk = content.front;
            _stream.send(chunk);
            content.popFront;
        }
        debug(requests) tracef("sent");
    }
    // we use this if we send from ubyte[][] as chunked content
    private void sendChunkedContent(T)(NetworkStream _stream, T content) {
        while ( !content.empty ) {
            auto chunk = content.front;
            auto chunkHeader = "%x\r\n".format(chunk.length);
            debug(requests) tracef("sending %s%s", chunkHeader, chunk);
            _stream.send(chunkHeader);
            _stream.send(chunk);
            _stream.send("\r\n");
            content.popFront;
        }
        debug(requests) tracef("sent");
        _stream.send("0\r\n\r\n");
    }
    ///
    /// POST/PUT/... data from some string(with Content-Length), or from range of strings/bytes (use Transfer-Encoding: chunked).
    /// When rank 1 (flat array) used as content it must have length. In that case "content" will be sent directly to network, and Content-Length headers will be added.
    /// If you are goung to send some range and do not know length at the moment when you start to send request, then you can send chunks of chars or ubyte.
    /// Try not to send too short chunks as this will put additional load on client and server. Chunks of length 2048 or 4096 are ok.
    ///
    /// Parameters:
    ///    url = url
    ///    content = string or input range
    ///    contentType = content type
    ///  Returns:
    ///     Response
    ///  Examples:
    ///  ---------------------------------------------------------------------------------------------------------
    ///      rs = rq.exec!"POST"("http://httpbin.org/post", "привiт, свiт!", "application/octet-stream");
    ///
    ///      auto s = lineSplitter("one,\ntwo,\nthree.");
    ///      rs = rq.exec!"POST"("http://httpbin.org/post", s, "application/octet-stream");
    ///
    ///      auto s = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    ///      rs = rq.exec!"POST"("http://httpbin.org/post", s.representation.chunks(10), "application/octet-stream");
    ///
    ///      auto f = File("tests/test.txt", "rb");
    ///      rs = rq.exec!"POST"("http://httpbin.org/post", f.byChunk(3), "application/octet-stream");
    ///  --------------------------------------------------------------------------------------------------------
    deprecated("Use Request() instead of HTTPRequest(); will be removed 2019-07")
    HTTPResponse exec(string method="POST", R)(string url, R content, string contentType="application/octet-stream")
        if ( (rank!R == 1)
            || (rank!R == 2 && isSomeChar!(Unqual!(typeof(content.front.front))))
            || (rank!R == 2 && (is(Unqual!(typeof(content.front.front)) == ubyte)))
        )
    do {
        debug(requests) tracef("started url=%s, this._uri=%s", url, _uri);

        checkURL(url);
        //if ( _cm is null ) {
        //    _cm = new ConnManager();
        //}

        NetworkStream _stream;
        _method = method;
        _response = new HTTPResponse;
        _history.length = 0;
        _response.uri = _uri;
        _response.finalURI = _uri;
        bool restartedRequest = false;
        bool send_flat;

    connect:
        _contentReceived = 0;
        _response._startedAt = Clock.currTime;

        assert(_stream is null);

        _stream = _cm.get(_uri.scheme, _uri.host, _uri.port);

        if ( _stream is null ) {
            debug(requests) trace("create new connection");
            _stream = setupConnection();
        } else {
            debug(requests) trace("reuse old connection");
        }

        assert(_stream !is null);

        if ( !_stream.isConnected ) {
            debug(requests) trace("disconnected stream on enter");
            if ( !restartedRequest ) {
                debug(requests) trace("disconnected stream on enter: retry");
                assert(_cm.get(_uri.scheme, _uri.host, _uri.port) == _stream);

                _cm.del(_uri.scheme, _uri.host, _uri.port);
                _stream.close();
                _stream = null;

                restartedRequest = true;
                goto connect;
            }
            debug(requests) trace("disconnected stream on enter: return response");
            //_stream = null;
            return _response;
        }
        _response._connectedAt = Clock.currTime;

        Appender!string req;
        req.put(requestString());

        auto h = requestHeaders;
        if ( contentType ) {
            safeSetHeader(h, _userHeaders.ContentType, "Content-Type", contentType);
        }
        static if ( rank!R == 1 ) {
            safeSetHeader(h, _userHeaders.ContentLength, "Content-Length", to!string(content.length));
        } else {
            if ( _userHeaders.ContentLength ) {
                debug(requests) tracef("User provided content-length for chunked content");
                send_flat = true;
            } else {
                h["Transfer-Encoding"] = "chunked";
                send_flat = false;
            }
        }
        h.byKeyValue.
            map!(kv => kv.key ~ ": " ~ kv.value ~ "\r\n").
            each!(h => req.put(h));
        req.put("\r\n");

        debug(requests) trace(req.data);
        if ( _verbosity >= 1 ) {
            req.data.splitLines.each!(a => writeln("> " ~ a));
        }

        try {
            // send headers
            _stream.send(req.data());
            // send body
            static if ( rank!R == 1) {
                _stream.send(content);
            } else {
                if ( send_flat ) {
                    sendFlattenContent(_stream, content);
                } else {
                    sendChunkedContent(_stream, content);
                }
            }
            _response._requestSentAt = Clock.currTime;
            debug(requests) trace("starting receive response");
            receiveResponse(_stream);
            debug(requests) trace("finished receive response");
            _response._finishedAt = Clock.currTime;
        } catch (NetworkException e) {
            _stream.close();
            throw new RequestException("Network error during data exchange");
        }

        if ( serverPrematurelyClosedConnection()
            && !restartedRequest
            && isIdempotent(_method))
        {
            ///
            /// We didn't receive any data (keepalive connectioin closed?)
            /// and we can restart this request.
            /// Go ahead.
            ///
            debug(requests) tracef("Server closed keepalive connection");

            assert(_cm.get(_uri.scheme, _uri.host, _uri.port) == _stream);

            _cm.del(_uri.scheme, _uri.host, _uri.port);
            _stream.close();
            _stream = null;

            restartedRequest = true;
            goto connect;
        }

        if ( _useStreaming ) {
            if ( _response._receiveAsRange.activated ) {
                debug(requests) trace("streaming_in activated");
                return _response;
            } else {
                // this can happen if whole response body received together with headers
                _response._receiveAsRange.data = _response.responseBody.data;
            }
        }

        close_connection_if_not_keepalive(_stream);

        if ( _verbosity >= 1 ) {
            writeln(">> Connect time: ", _response._connectedAt - _response._startedAt);
            writeln(">> Request send time: ", _response._requestSentAt - _response._connectedAt);
            writeln(">> Response recv time: ", _response._finishedAt - _response._requestSentAt);
        }


        if ( willFollowRedirect ) {
            if ( _history.length >= _maxRedirects ) {
                _stream = null;
                throw new MaxRedirectsException("%d redirects reached maxRedirects %d.".format(_history.length, _maxRedirects));
            }
            // "location" in response already checked in canFollowRedirect
            immutable new_location = *("location" in _response.responseHeaders);
            immutable current_uri = _uri, next_uri = uriFromLocation(_uri, new_location);

            // save current response for history
            _history ~= _response;

            // prepare new response (for redirected request)
            _response = new HTTPResponse;
            _response.uri = current_uri;
            _response.finalURI = next_uri;

            _stream = null;

            // set new uri
            this._uri = next_uri;
            debug(requests) tracef("Redirected to %s", next_uri);
            if ( _method != "GET" && _response.code != 307 && _response.code != 308 ) {
                // 307 and 308 do not change method
                return this.get();
            }
            if ( restartedRequest ) {
                debug(requests) trace("Rare event: clearing 'restartedRequest' on redirect");
                restartedRequest = false;
            }
            goto connect;
        }

        _response._history = _history;
        return _response;
    }
    ///
    /// Send request with parameters.
    /// If used for POST or PUT requests then application/x-www-form-urlencoded used.
    /// Request parameters will be encoded into request string or placed in request body for POST/PUT
    /// requests.
    /// Parameters:
    ///     url = url
    ///     params = request parameters
    ///  Returns:
    ///     Response
    ///  Examples:
    ///  ---------------------------------------------------------------------------------
    ///     rs = Request().exec!"GET"("http://httpbin.org/get", ["c":"d", "a":"b"]);
    ///  ---------------------------------------------------------------------------------
    ///
    deprecated("Use Request() instead of HTTPRequest; will be removed 2019-07")
    HTTPResponse exec(string method="GET")(string url = null, QueryParam[] params = null)
    do {
        debug(requests) tracef("started url=%s, this._uri=%s", url, _uri);

        checkURL(url);
        //if ( _cm is null ) {
        //    _cm = new ConnManager();
        //}

        NetworkStream _stream;
        _method = method;
        _response = new HTTPResponse;
        _history.length = 0;
        _response.uri = _uri;
        _response.finalURI = _uri;
        bool restartedRequest = false; // True if this is restarted keepAlive request

    connect:
        if ( _method == "GET" && _uri in _permanent_redirects ) {
            debug(requests) trace("use parmanent redirects cache");
            _uri = uriFromLocation(_uri, _permanent_redirects[_uri]);
            _response._finalURI = _uri;
        }
        _contentReceived = 0;
        _response._startedAt = Clock.currTime;

        assert(_stream is null);

        _stream = _cm.get(_uri.scheme, _uri.host, _uri.port);

        if ( _stream is null ) {
            debug(requests) trace("create new connection");
            _stream = setupConnection();
        } else {
            debug(requests) trace("reuse old connection");
        }

        assert(_stream !is null);

        if ( !_stream.isConnected ) {
            debug(requests) trace("disconnected stream on enter");
            if ( !restartedRequest ) {
                debug(requests) trace("disconnected stream on enter: retry");
                assert(_cm.get(_uri.scheme, _uri.host, _uri.port) == _stream);

                _cm.del(_uri.scheme, _uri.host, _uri.port);
                _stream.close();
                _stream = null;

                restartedRequest = true;
                goto connect;
            }
            debug(requests) trace("disconnected stream on enter: return response");
            //_stream = null;
            return _response;
        }
        _response._connectedAt = Clock.currTime;

        auto h = requestHeaders();

        Appender!string req;

        string encoded;

        switch (_method) {
            case "POST","PUT","PATCH":
                encoded = params2query(params);
                safeSetHeader(h, _userHeaders.ContentType, "Content-Type", "application/x-www-form-urlencoded");
                if ( encoded.length > 0) {
                    safeSetHeader(h, _userHeaders.ContentLength, "Content-Length", to!string(encoded.length));
                }
                req.put(requestString());
                break;
            default:
                req.put(requestString(params));
        }

        h.byKeyValue.
            map!(kv => kv.key ~ ": " ~ kv.value ~ "\r\n").
            each!(h => req.put(h));
        req.put("\r\n");
        if ( encoded ) {
            req.put(encoded);
        }

        debug(requests) trace(req.data);
        if ( _verbosity >= 1 ) {
            req.data.splitLines.each!(a => writeln("> " ~ a));
        }
        //
        // Now send request and receive response
        //
        try {
            _stream.send(req.data());
            _response._requestSentAt = Clock.currTime;
            debug(requests) trace("starting receive response");
            receiveResponse(_stream);
            debug(requests) trace("done receive response");
            _response._finishedAt = Clock.currTime;
        }
        catch (NetworkException e) {
            // On SEND this can means:
            // we started to send request to the server, but it closed connection because of keepalive timeout.
            // We have to restart request if possible.

            // On RECEIVE - if we received something - then this exception is real and unexpected error.
            // If we didn't receive anything - we can restart request again as it can be
            debug(requests) tracef("Exception on receive response: %s", e.msg);
            if ( _response._responseHeaders.length != 0 )
            {
                _stream.close();
                throw new RequestException("Unexpected network error");
            }
        }

        if ( serverPrematurelyClosedConnection()
            && !restartedRequest
            && isIdempotent(_method)
            ) {
            ///
            /// We didn't receive any data (keepalive connectioin closed?)
            /// and we can restart this request.
            /// Go ahead.
            ///
            debug(requests) tracef("Server closed keepalive connection");

            assert(_cm.get(_uri.scheme, _uri.host, _uri.port) == _stream);

            _cm.del(_uri.scheme, _uri.host, _uri.port);
            _stream.close();
            _stream = null;

            restartedRequest = true;
            goto connect;
        }

        if ( _useStreaming ) {
            if ( _response._receiveAsRange.activated ) {
                debug(requests) trace("streaming_in activated");
                return _response;
            } else {
                // this can happen if whole response body received together with headers
                _response._receiveAsRange.data = _response.responseBody.data;
            }
        }

        close_connection_if_not_keepalive(_stream);

        if ( _verbosity >= 1 ) {
            writeln(">> Connect time: ", _response._connectedAt - _response._startedAt);
            writeln(">> Request send time: ", _response._requestSentAt - _response._connectedAt);
            writeln(">> Response recv time: ", _response._finishedAt - _response._requestSentAt);
        }

        if ( willFollowRedirect ) {
            debug(requests) trace("going to follow redirect");
            if ( _history.length >= _maxRedirects ) {
                _stream = null;
                throw new MaxRedirectsException("%d redirects reached maxRedirects %d.".format(_history.length, _maxRedirects));
            }
            // "location" in response already checked in canFollowRedirect
            immutable new_location = *("location" in _response.responseHeaders);
            immutable current_uri = _uri, next_uri = uriFromLocation(_uri, new_location);

            if ( _method == "GET" && _response.code == 301 ) {
                _permanent_redirects[_uri] = new_location;
            }

            // save current response for history
            _history ~= _response;

            // prepare new response (for redirected request)
            _response = new HTTPResponse;
            _response.uri = current_uri;
            _response.finalURI = next_uri;
            _stream = null;

            // set new uri
            _uri = next_uri;
            debug(requests) tracef("Redirected to %s", next_uri);
            if ( _method != "GET" && _response.code != 307 && _response.code != 308 ) {
                // 307 and 308 do not change method
                return this.get();
            }
            if ( restartedRequest ) {
                debug(requests) trace("Rare event: clearing 'restartedRequest' on redirect");
                restartedRequest = false;
            }
            goto connect;
        }

        _response._history = _history;
        return _response;
    }

    /// WRAPPERS
    ///
    /// send file(s) using POST and multipart form.
    /// This wrapper will be deprecated, use post with MultipartForm - it is more general and clear.
    /// Parameters:
    ///     url = url
    ///     files = array of PostFile structures
    /// Returns:
    ///     Response
    /// Each PostFile structure contain path to file, and optional field name and content type.
    /// If no field name provided, then basename of the file will be used.
    /// application/octet-stream is default when no content type provided.
    /// Example:
    /// ---------------------------------------------------------------
    ///    PostFile[] files = [
    ///                   {fileName:"tests/abc.txt", fieldName:"abc", contentType:"application/octet-stream"},
    ///                   {fileName:"tests/test.txt"}
    ///               ];
    ///    rs = rq.exec!"POST"("http://httpbin.org/post", files);
    /// ---------------------------------------------------------------
    ///
    deprecated("Use Request() instead of HTTPRequest(); will be removed 2019-07")
    HTTPResponse exec(string method="POST")(string url, PostFile[] files) if (method=="POST") {
        MultipartForm multipart;
        File[]        toClose;
        foreach(ref f; files) {
            File file = File(f.fileName, "rb");
            toClose ~= file;
            string fileName = f.fileName ? f.fileName : f.fieldName;
            string contentType = f.contentType ? f.contentType : "application/octetstream";
            multipart.add(f.fieldName, new FormDataFile(file), ["filename":fileName, "Content-Type": contentType]);
        }
        auto res = exec!"POST"(url, multipart);
        toClose.each!"a.close";
        return res;
    }
    ///
    /// exec request with parameters when you can use dictionary (when you have no duplicates in parameter names)
    /// Consider switch to exec(url, QueryParams) as it more generic and clear.
    /// Parameters:
    ///     url = url
    ///     params = dictionary with field names as keys and field values as values.
    /// Returns:
    ///     Response
    deprecated("Use Request() instead of HTTPRequest(); will be removed 2019-07")
    HTTPResponse exec(string method="GET")(string url, string[string] params) {
        return exec!method(url, params.byKeyValue.map!(p => QueryParam(p.key, p.value)).array);
    }
    ///
    /// GET request. Simple wrapper over exec!"GET"
    /// Params:
    /// args = request parameters. see exec docs.
    ///
    deprecated("Use Request() instead of HTTPRequest; will be removed 2019-07")
    HTTPResponse get(A...)(A args) {
        return exec!"GET"(args);
    }
    ///
    /// POST request. Simple wrapper over exec!"POST"
    /// Params:
    /// uri = endpoint uri
    /// args = request parameters. see exec docs.
    ///
    deprecated("Use Request() instead of HTTPRequest; will be removed 2019-07")
    HTTPResponse post(A...)(string uri, A args) {
        return exec!"POST"(uri, args);
    }

    import requests.request;

    // we use this if we send from ubyte[][] and user provided Content-Length
    private void sendFlattenContent(NetworkStream _stream) {
        while ( !_postData.empty ) {
            auto chunk = _postData.front;
            _stream.send(chunk);
            _postData.popFront;
        }
        debug(requests) tracef("sent");
    }
    // we use this if we send from ubyte[][] as chunked content
    private void sendChunkedContent(NetworkStream _stream) {
        while ( !_postData.empty ) {
            auto chunk = _postData.front;
            auto chunkHeader = "%x\r\n".format(chunk.length);
            debug(requests) tracef("sending %s%s", chunkHeader, cast(string)chunk);
            _stream.send(chunkHeader);
            _stream.send(chunk);
            _stream.send("\r\n");
            debug(requests) tracef("chunk sent");
            _postData.popFront;
        }
        debug(requests) tracef("sent");
        _stream.send("0\r\n\r\n");
    }

    HTTPResponse exec_from_range(InputRangeAdapter postData)
    do {

        _postData = postData;

        debug(requests) tracef("exec from range");

        NetworkStream _stream;
        _response = new HTTPResponse;
        _history.length = 0;
        _response.uri = _uri;
        _response.finalURI = _uri;
        bool restartedRequest = false;
        bool send_flat;

    connect:
        _contentReceived = 0;
        _response._startedAt = Clock.currTime;

        assert(_stream is null);

        _stream = _cm.get(_uri.scheme, _uri.host, _uri.port);

        if ( _stream is null ) {
            debug(requests) trace("create new connection");
            _stream = setupConnection();
        } else {
            debug(requests) trace("reuse old connection");
        }

        assert(_stream !is null);

        if ( !_stream.isConnected ) {
            debug(requests) trace("disconnected stream on enter");
            if ( !restartedRequest ) {
                debug(requests) trace("disconnected stream on enter: retry");
                assert(_cm.get(_uri.scheme, _uri.host, _uri.port) == _stream);

                _cm.del(_uri.scheme, _uri.host, _uri.port);
                _stream.close();
                _stream = null;

                restartedRequest = true;
                goto connect;
            }
            debug(requests) trace("disconnected stream on enter: return response");
            //_stream = null;
            return _response;
        }
        _response._connectedAt = Clock.currTime;

        Appender!string req;
        req.put(requestString());

        auto h = requestHeaders;
        if ( _contentType ) {
            safeSetHeader(h, _userHeaders.ContentType, "Content-Type", _contentType);
        }

        if ( _postData.length >= 0 )
        {
            // we know t
            safeSetHeader(h, _userHeaders.ContentLength, "Content-Length", to!string(_postData.length));
        }

        if ( _userHeaders.ContentLength || "Content-Length" in h )
        {
            debug(requests) tracef("User provided content-length for chunked content");
            send_flat = true;
        }
        else
        {
            h["Transfer-Encoding"] = "chunked";
            send_flat = false;
        }
        h.byKeyValue.
            map!(kv => kv.key ~ ": " ~ kv.value ~ "\r\n").
            each!(h => req.put(h));
        req.put("\r\n");

        debug(requests) tracef("send <%s>", req.data);
        if ( _verbosity >= 1 ) {
            req.data.splitLines.each!(a => writeln("> " ~ a));
        }

        try {
            // send headers
            _stream.send(req.data());
            // send body
            if ( send_flat ) {
                sendFlattenContent(_stream);
            } else {
                sendChunkedContent(_stream);
            }
            _response._requestSentAt = Clock.currTime;
            debug(requests) trace("starting receive response");
            receiveResponse(_stream);
            debug(requests) trace("finished receive response");
            _response._finishedAt = Clock.currTime;
        }
        catch (NetworkException e)
        {
            _stream.close();
            throw new RequestException("Network error during data exchange");
        }
        if ( serverPrematurelyClosedConnection()
        && !restartedRequest
        && isIdempotent(_method)
        ) {
            ///
            /// We didn't receive any data (keepalive connectioin closed?)
            /// and we can restart this request.
            /// Go ahead.
            ///
            debug(requests) tracef("Server closed keepalive connection");

            assert(_cm.get(_uri.scheme, _uri.host, _uri.port) == _stream);

            _cm.del(_uri.scheme, _uri.host, _uri.port);
            _stream.close();
            _stream = null;

            restartedRequest = true;
            goto connect;
        }

        if ( _useStreaming ) {
            if ( _response._receiveAsRange.activated ) {
                debug(requests) trace("streaming_in activated");
                return _response;
            } else {
                // this can happen if whole response body received together with headers
                _response._receiveAsRange.data = _response.responseBody.data;
            }
        }

        close_connection_if_not_keepalive(_stream);

        if ( _verbosity >= 1 ) {
            writeln(">> Connect time: ", _response._connectedAt - _response._startedAt);
            writeln(">> Request send time: ", _response._requestSentAt - _response._connectedAt);
            writeln(">> Response recv time: ", _response._finishedAt - _response._requestSentAt);
        }


        if ( willFollowRedirect ) {
            if ( _history.length >= _maxRedirects ) {
                _stream = null;
                throw new MaxRedirectsException("%d redirects reached maxRedirects %d.".format(_history.length, _maxRedirects));
            }
            // "location" in response already checked in canFollowRedirect
            immutable new_location = *("location" in _response.responseHeaders);
            immutable current_uri = _uri, next_uri = uriFromLocation(_uri, new_location);

            immutable get_or_head = _method == "GET" || _method == "HEAD";
            immutable code = _response.code;

            // save current response for history
            _history ~= _response;

            if ( code == 301 )
            {
                // permanent redirect and change method
                _permanent_redirects[_uri] = new_location;
                if ( !get_or_head )
                {
                    _method = "GET";
                }
            }
            if ( (code == 302 || code == 303) && !get_or_head)
            {
                // only change method
                _method = "GET";
            }
            if ( code == 307 )
            {
                // no change method, no permanent
            }
            if ( code == 308 )
            {
                // permanent redirection and do not change method
                _permanent_redirects[_uri] = new_location;
            }

            // prepare new response (for redirected request)
            _response = new HTTPResponse;
            _response.uri = current_uri;
            _response.finalURI = next_uri;

            _stream = null;

            // set new uri
            this._uri = next_uri;
            debug(requests) tracef("Redirected to %s", next_uri);
            if ( restartedRequest ) {
                debug(requests) trace("Rare event: clearing 'restartedRequest' on redirect");
                restartedRequest = false;
            }
            if ( _method == "GET")
            {
                return exec_from_parameters();
            }
            goto connect;
        }

        _response._history = _history;
        return _response;
    }

    HTTPResponse exec_from_multipart_form(MultipartForm form) {
        import std.uuid;
        import std.file;

        _multipartForm = form;

        debug(requests) tracef("exec from multipart form");

        NetworkStream _stream;
        _response = new HTTPResponse;
        _response.uri = _uri;
        _response.finalURI = _uri;
        bool restartedRequest = false;

    connect:
        _contentReceived = 0;
        _response._startedAt = Clock.currTime;

        assert(_stream is null);

        _stream = _cm.get(_uri.scheme, _uri.host, _uri.port);

        if ( _stream is null ) {
            debug(requests) trace("create new connection");
            _stream = setupConnection();
        } else {
            debug(requests) trace("reuse old connection");
        }

        assert(_stream !is null);

        if ( !_stream.isConnected ) {
            debug(requests) trace("disconnected stream on enter");
            if ( !restartedRequest ) {
                debug(requests) trace("disconnected stream on enter: retry");
                assert(_cm.get(_uri.scheme, _uri.host, _uri.port) == _stream);

                _cm.del(_uri.scheme, _uri.host, _uri.port);
                _stream.close();
                _stream = null;

                restartedRequest = true;
                goto connect;
            }
            debug(requests) trace("disconnected stream on enter: return response");
            //_stream = null;
            return _response;
        }
        _response._connectedAt = Clock.currTime;

        Appender!string req;
        req.put(requestString());

        string   boundary = randomUUID().toString;
        string[] partHeaders;
        size_t   contentLength;

        foreach(ref part; _multipartForm._sources) {
            string h = "--" ~ boundary ~ "\r\n";
            string disposition = `form-data; name="%s"`.format(part.name);
            string optionals = part.
            parameters.byKeyValue().
            filter!(p => p.key!="Content-Type").
            map!   (p => "%s=%s".format(p.key, p.value)).
            join("; ");

            h ~= `Content-Disposition: ` ~ [disposition, optionals].join("; ") ~ "\r\n";

            auto contentType = "Content-Type" in part.parameters;
            if ( contentType ) {
                h ~= "Content-Type: " ~ *contentType ~ "\r\n";
            }

            h ~= "\r\n";
            partHeaders ~= h;
            contentLength += h.length + part.input.getSize() + "\r\n".length;
        }
        contentLength += "--".length + boundary.length + "--\r\n".length;

        auto h = requestHeaders();
        safeSetHeader(h, _userHeaders.ContentType, "Content-Type", "multipart/form-data; boundary=" ~ boundary);
        safeSetHeader(h, _userHeaders.ContentLength, "Content-Length", to!string(contentLength));

        h.byKeyValue.
        map!(kv => kv.key ~ ": " ~ kv.value ~ "\r\n").
        each!(h => req.put(h));
        req.put("\r\n");

        debug(requests) trace(req.data);
        if ( _verbosity >= 1 ) req.data.splitLines.each!(a => writeln("> " ~ a));

        try {
            _stream.send(req.data());
            foreach(ref source; _multipartForm._sources) {
                debug(requests) tracef("sending part headers <%s>", partHeaders.front);
                _stream.send(partHeaders.front);
                partHeaders.popFront;
                while (true) {
                    auto chunk = source.input.read();
                    if ( chunk.length <= 0 ) {
                        break;
                    }
                    _stream.send(chunk);
                }
                _stream.send("\r\n");
            }
            _stream.send("--" ~ boundary ~ "--\r\n");
            _response._requestSentAt = Clock.currTime;
            receiveResponse(_stream);
            _response._finishedAt = Clock.currTime;
        }
        catch (NetworkException e) {
            errorf("Error sending request: ", e.msg);
            _stream.close();
            return _response;
        }

        if ( serverPrematurelyClosedConnection()
        && !restartedRequest
        && isIdempotent(_method)
        ) {
            ///
            /// We didn't receive any data (keepalive connectioin closed?)
            /// and we can restart this request.
            /// Go ahead.
            ///
            debug(requests) tracef("Server closed keepalive connection");

            assert(_cm.get(_uri.scheme, _uri.host, _uri.port) == _stream);

            _cm.del(_uri.scheme, _uri.host, _uri.port);
            _stream.close();
            _stream = null;

            restartedRequest = true;
            goto connect;
        }

        if ( _useStreaming ) {
            if ( _response._receiveAsRange.activated ) {
                debug(requests) trace("streaming_in activated");
                return _response;
            } else {
                // this can happen if whole response body received together with headers
                _response._receiveAsRange.data = _response.responseBody.data;
            }
        }

        close_connection_if_not_keepalive(_stream);

        if ( _verbosity >= 1 ) {
            writeln(">> Connect time: ", _response._connectedAt - _response._startedAt);
            writeln(">> Request send time: ", _response._requestSentAt - _response._connectedAt);
            writeln(">> Response recv time: ", _response._finishedAt - _response._requestSentAt);
        }

        if ( willFollowRedirect ) {
            if ( _history.length >= _maxRedirects ) {
                _stream = null;
                throw new MaxRedirectsException("%d redirects reached maxRedirects %d.".format(_history.length, _maxRedirects));
            }
            // "location" in response already checked in canFollowRedirect
            immutable new_location = *("location" in _response.responseHeaders);
            immutable current_uri = _uri;
            immutable next_uri = uriFromLocation(_uri, new_location);

            immutable get_or_head = _method == "GET" || _method == "HEAD";
            immutable code = _response.code;

            // save current response for history
            _history ~= _response;

            if ( code == 301 )
            {
                // permanent redirect and change method
                _permanent_redirects[_uri] = new_location;
                if ( !get_or_head )
                {
                    _method = "GET";
                }
            }
            if ( (code == 302 || code == 303) && !get_or_head)
            {
                // only change method
                _method = "GET";
            }
            if ( code == 307 )
            {
                // no change method, no permanent
            }
            if ( code == 308 )
            {
                // permanent redirection and do not change method
                _permanent_redirects[_uri] = new_location;
            }

            // prepare new response (for redirected request)
            _response = new HTTPResponse;
            _response.uri = current_uri;
            _response.finalURI = next_uri;
            _stream = null;

            // set new uri
            this._uri = next_uri;
            debug(requests) tracef("Redirected to %s", next_uri);
            if ( restartedRequest ) {
                debug(requests) trace("Rare event: clearing 'restartedRequest' on redirect");
                restartedRequest = false;
            }
            if ( _method == "GET")
            {
                return exec_from_parameters();
            }
            goto connect;
        }

        _response._history = _history;
        return _response;
    }

    HTTPResponse exec_from_parameters() {

        debug(requests) tracef("exec from parameters request");

        assert(_uri != URI.init);
        NetworkStream _stream;
        _response = new HTTPResponse;
        _history.length = 0;
        _response.uri = _uri;
        _response.finalURI = _uri;
        bool restartedRequest = false; // True if this is restarted keepAlive request

    connect:
        if ( _method == "GET" && _uri in _permanent_redirects ) {
            debug(requests) trace("use parmanent redirects cache");
            _uri = uriFromLocation(_uri, _permanent_redirects[_uri]);
            _response._finalURI = _uri;
        }
        _contentReceived = 0;
        _response._startedAt = Clock.currTime;

        assert(_stream is null);

        _stream = _cm.get(_uri.scheme, _uri.host, _uri.port);

        if ( _stream is null ) {
            debug(requests) trace("create new connection");
            _stream = setupConnection();
        } else {
            debug(requests) trace("reuse old connection");
        }

        assert(_stream !is null);

        if ( !_stream.isConnected ) {
            debug(requests) trace("disconnected stream on enter");
            if ( !restartedRequest ) {
                debug(requests) trace("disconnected stream on enter: retry");
                assert(_cm.get(_uri.scheme, _uri.host, _uri.port) == _stream);

                _cm.del(_uri.scheme, _uri.host, _uri.port);
                _stream.close();
                _stream = null;

                restartedRequest = true;
                goto connect;
            }
            debug(requests) trace("disconnected stream on enter: return response");
            //_stream = null;
            return _response;
        }
        _response._connectedAt = Clock.currTime;

        auto h = requestHeaders();

        Appender!string req;

        string encoded;

        switch (_method) {
            case "POST","PUT","PATCH":
                encoded = params2query(_params);
                safeSetHeader(h, _userHeaders.ContentType, "Content-Type", "application/x-www-form-urlencoded");
                safeSetHeader(h, _userHeaders.ContentLength, "Content-Length", to!string(encoded.length));
                req.put(requestString());
                break;
            default:
                req.put(requestString(_params));
        }

        h.byKeyValue.
        map!(kv => kv.key ~ ": " ~ kv.value ~ "\r\n").
        each!(h => req.put(h));
        req.put("\r\n");
        if ( encoded ) {
            req.put(encoded);
        }

        debug(requests) trace(req.data);
        if ( _verbosity >= 1 ) {
            req.data.splitLines.each!(a => writeln("> " ~ a));
        }
        //
        // Now send request and receive response
        //
        try {
            _stream.send(req.data());
            _response._requestSentAt = Clock.currTime;
            debug(requests) trace("starting receive response");
            receiveResponse(_stream);
            debug(requests) tracef("done receive response");
            _response._finishedAt = Clock.currTime;
        }
        catch (NetworkException e) {
            // On SEND this can means:
            // we started to send request to the server, but it closed connection because of keepalive timeout.
            // We have to restart request if possible.

            // On RECEIVE - if we received something - then this exception is real and unexpected error.
            // If we didn't receive anything - we can restart request again as it can be
            debug(requests) tracef("Exception on receive response: %s", e.msg);
            if ( _response._responseHeaders.length != 0 )
            {
                _stream.close();
                throw new RequestException("Unexpected network error");
            }
        }

        if ( serverPrematurelyClosedConnection()
            && !restartedRequest
            && isIdempotent(_method)
            ) {
            ///
            /// We didn't receive any data (keepalive connectioin closed?)
            /// and we can restart this request.
            /// Go ahead.
            ///
            debug(requests) tracef("Server closed keepalive connection");

            assert(_cm.get(_uri.scheme, _uri.host, _uri.port) == _stream);

            _cm.del(_uri.scheme, _uri.host, _uri.port);
            _stream.close();
            _stream = null;

            restartedRequest = true;
            goto connect;
        }

        if ( _useStreaming ) {
            if ( _response._receiveAsRange.activated ) {
                debug(requests) trace("streaming_in activated");
                return _response;
            } else {
                // this can happen if whole response body received together with headers
                _response._receiveAsRange.data = _response.responseBody.data;
            }
        }

        close_connection_if_not_keepalive(_stream);

        if ( _verbosity >= 1 ) {
            writeln(">> Connect time: ", _response._connectedAt - _response._startedAt);
            writeln(">> Request send time: ", _response._requestSentAt - _response._connectedAt);
            writeln(">> Response recv time: ", _response._finishedAt - _response._requestSentAt);
        }

        if ( willFollowRedirect ) {
            debug(requests) trace("going to follow redirect");
            if ( _history.length >= _maxRedirects ) {
                _stream = null;
                throw new MaxRedirectsException("%d redirects reached maxRedirects %d.".format(_history.length, _maxRedirects));
            }
            // "location" in response already checked in canFollowRedirect
            immutable new_location = *("location" in _response.responseHeaders);
            immutable current_uri = _uri;
            immutable next_uri = uriFromLocation(_uri, new_location);

            immutable get_or_head = _method == "GET" || _method == "HEAD";
            immutable code = _response.code;

            // save current response for history
            _history ~= _response;

            if ( code == 301 )
            {
                // permanent redirect and change method
                _permanent_redirects[_uri] = new_location;
                if ( !get_or_head )
                {
                    _method = "GET";
                }
            }
            if ( (code == 302 || code == 303) && !get_or_head)
            {
                // only change method
                _method = "GET";
            }
            if ( code == 307 )
            {
                // no change method, no permanent
            }
            if ( code == 308 )
            {
                // permanent redirection and do not change method
                _permanent_redirects[_uri] = new_location;
            }

            // prepare new response (for redirected request)
            _response = new HTTPResponse;
            _response.uri = current_uri;
            _response.finalURI = next_uri;
            _stream = null;

            // set new uri
            _uri = next_uri;
            debug(requests) tracef("Redirected to %s", next_uri);
            //if ( _method != "GET" && _response.code != 307 && _response.code != 308 ) {
            //    // 307 and 308 do not change method
            //    return exec_from_parameters(r);
            //}
            if ( restartedRequest ) {
                debug(requests) trace("Rare event: clearing 'restartedRequest' on redirect");
                restartedRequest = false;
            }
            goto connect;
        }

        _response._history = _history;
        return _response;
    }
    HTTPResponse execute(Request r)
    {
        _method = r.method;
        _uri = r.uri;
        _useStreaming = r.useStreaming;
        _permanent_redirects = r.permanent_redirects;
        _maxRedirects = r.maxRedirects;
        _authenticator = r.authenticator;
        _maxHeadersLength = r.maxHeadersLength;
        _maxContentLength = r.maxContentLength;
        _verbosity = r.verbosity;
        _keepAlive = r.keepAlive;
        _bufferSize = r.bufferSize;
        _proxy = r.proxy;
        _timeout = r.timeout;
        _contentType = r.contentType;
        _socketFactory = r.socketFactory;
        _sslOptions = r.sslOptions;
        _bind = r.bind;
        _headers = r.headers;
        _userHeaders = r.userHeaders;

        _params = r.params;

        // this assignments increments refCounts, so we can't use const Request
        // but Request is anyway struct and called by-value
        _cm = r.cm;
        _cookie = r.cookie;

        debug(requests) trace("serving %s".format(r));
        if ( !r.postData.empty)
        {
            return exec_from_range(r.postData);
        }
        if ( r.hasMultipartForm )
        {
            return exec_from_multipart_form(r.multipartForm);
        }
        auto rs = exec_from_parameters();
        return rs;
    }
}

version(vibeD) {
    import std.json;
    package string httpTestServer() {
        return "http://httpbin.org/";
    }
    package string fromJsonArrayToStr(JSONValue v) {
        return v.str;
    }
}
else {
    import std.json;
    package string httpTestServer() {
        return "http://127.0.0.1:8081/";
    }
    package string fromJsonArrayToStr(JSONValue v) {
        return cast(string)(v.array.map!"cast(ubyte)a.integer".array);
    }
}
