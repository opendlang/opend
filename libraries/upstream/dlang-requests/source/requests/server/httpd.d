module requests.server.httpd;

import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
import std.exception;
import std.experimental.logger;
import std.format;
import std.parallelism;
import std.range;
import std.regex;
import std.socket;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;
import core.thread;
import requests.utils;
import requests.streams;
import requests.uri;

version(vibeD){
    pragma(msg, "httpd will not compile with vibeD");
}
else {
    /*
     ** This is small http server to run something like httpbin(http://httpbin.org) internally
     ** for Requests unittest's.
     */

    enum    DSBUFFSIZE = 16*1024;

    class HTTPD_RequestException: Exception {
        this(string message, string file =__FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow {
            super(message, file, line, next);
        }
    }

    struct HTTPD_Request {
        private {
            string          _requestLine;
            string[string]  _requestHeaders;
            Buffer!ubyte    _requestBody;
            bool            _keepAlive;
            URI             _uri;
            string[string]  _query; // query in url
            string          _method;
            string          _path;
            string          _json; // json for application/json
            string[string]  _form; // form values for application/x-www-form-urlencoded
            ubyte[][string] _files;
            ubyte[]         _data; // raw data for unrecognized mime's
            _DataSource     _dataSource;
            string[string]  _cookies;
        }
        private mixin(Setter!(string[string])("requestHeaders"));
        auto ref requestHeaders() inout @property @safe @nogc nothrow {
            return _requestHeaders;
        }
        auto ref cookies() inout @property @safe @nogc nothrow {
            return _cookies;
        }
        private mixin(Setter!(string[string])("query"));
        auto ref query() inout @property @safe @nogc nothrow {
            return _query;
        }
        auto ref requestBody() inout @property @safe @nogc nothrow {
            return _requestBody;
        }
        private mixin(Setter!string("method"));
        mixin(Getter("method"));
        private mixin(Setter!string("requestLine"));
        mixin(Getter("requestLine"));
        private mixin(Setter!string("path"));
        mixin(Getter("path"));
        private mixin(Setter!bool("keepAlive"));
        mixin(Getter("keepAlive"));
        private mixin(Setter!URI("uri"));
        mixin(Getter("uri"));

        @property string json() {
            if ( _dataSource._readStarted ) {
                throw new HTTPD_RequestException("Request read() call already started.");
            }
            if ( _dataSource._requestHasBody && !_dataSource._requestBodyProcessed ) {
                debug(httpd) trace("receiving body on demand for json");
                loadBodyOnDemand(_dataSource);
            }
            return _json;
        }
        @property ubyte[] data() {
            if ( _dataSource._readStarted ) {
                throw new HTTPD_RequestException("Request body read() already started.");
            }
            if ( _dataSource._requestHasBody && !_dataSource._requestBodyProcessed ) {
                debug(httpd) trace("receiving body on demand for data");
                loadBodyOnDemand(_dataSource);
            }
            return _data;
        }
        @property string[string] form() {
            if ( _dataSource._readStarted ) {
                throw new HTTPD_RequestException("Request body read() already started.");
            }
            if ( _dataSource._requestHasBody && !_dataSource._requestBodyProcessed ) {
                debug(httpd) trace("receiving body on demand for form");
                loadBodyOnDemand(_dataSource);
            }
            return _form;
        }
        @property auto files() {
            if ( _dataSource._readStarted ) {
                throw new HTTPD_RequestException("Request body read() already started.");
            }
            if ( _dataSource._requestHasBody && !_dataSource._requestBodyProcessed ) {
                debug(httpd) trace("receiving body on demand for form");
                loadBodyOnDemand(_dataSource);
            }
            return _files;
        }

        @property bool requestHasBody() pure {
            if ( "content-length" in _requestHeaders ) {
                return true;
            }
            if ( auto contentTransferEncoding = "transfer-encoding" in _requestHeaders ) {
                if ( *contentTransferEncoding=="chunked" ) {
                    return true;
                }
            }
            return false;
        }

        class _DataSource {
            private {
                NetworkStream  _stream;
                DataPipe!ubyte _bodyDecoder;
                DecodeChunked  _unChunker;
                long           _contentLength =  0;
                long           _receivedLength = 0;
                ubyte[]        _content;
                bool           _requestHasBody;         // request has body
                bool           _requestBodyRecvInProgr; // loading body currently active
                bool           _requestBodyProcessed;   // we processed body - this can happens only once
                bool           _requestBodyReceived;    // all body data were received from network (we have to close socket if request terminated before all data received)
                bool           _readStarted;
            }
            bool empty() {
                debug(httpd) tracef("datasource empty: %s", _content.length==0);
                return _content.length==0;
            }
            ubyte[] front() {
                return _content;
            }
            void popFront() {
                debug(httpd) trace("datasource enters popFront");
                _content.length = 0;
                if ( !_requestBodyRecvInProgr ) {
                    debug(httpd) trace("popFront called when dataSource is not active anymore");
                    return;
                }
                while ( _bodyDecoder.empty && _stream && _stream.isOpen ) {
                    auto b    = new ubyte[DSBUFFSIZE];
                    auto read = _stream.receive(b);
                    if ( read == 0 ) {
                        debug(httpd) trace("stream closed when receiving in datasource");
                        _bodyDecoder.flush();
                        _requestBodyRecvInProgr = false;
                        break;
                    }
                    debug(httpd) tracef("place %d bytes to datasource", read);
                    _receivedLength += read;
                    _bodyDecoder.putNoCopy(b[0..read]);
                    if (   (_unChunker && _unChunker.done)
                        || (_contentLength > 0 && _receivedLength >= _contentLength) )
                    {
                        debug(httpd) trace("request body reading complete (due contentLength or due last chunk consumed)");
                        _bodyDecoder.flush();
                        _requestBodyRecvInProgr = false;
                        _requestBodyReceived = true;
                        break;
                    }
                }
                _content = _bodyDecoder.getNoCopy().join();
                debug(httpd) tracef("%d bytes in content after popFront", _content.length);
            }
            ///
            /// raplace current front with another value
            ///
            void unPop(ubyte[] data) {
                assert(data.length > 0);
                _content = data;
            }
            ///
            /// Scan over input stream,
            /// can return data from stream
            /// acc - accumulator for receiving needle
            /// return empty data if we receiving needle
            /// if needle found in stream, then acc == needle
            /// if end of stream happened, then eos = true
            ///
            ubyte[] scanUntilR(string needle, ref ubyte[] acc, out bool eos) {
                auto d = needle.representation;
                ubyte[] l;

                while (!this.empty) {
                    auto c = this.front;
                    debug(httpd) tracef("on scan: %s", cast(string)c);
                    l = acc ~ c;
                    auto s = l.findSplit(d);
                    if ( s[1].length ) {
                        if ( s[2].length ) {
                            this.unPop(s[2]);
                        } else {
                            this.popFront;
                        }
                        acc = s[1];
                        return s[0];
                    }
                    auto i = min(l.length, d.length);
                    for(;i>0; i--) {
                        if ( l.endsWith(d[0..i]) ) {
                            acc = l[$-i..$];
                            this.popFront;
                            return l[0..$-i];
                        }
                    }
                    if ( i == 0 ) {
                        acc.length = 0;
                        this.popFront;
                        return l;
                    }
                }
                eos = true; // end of stream
                acc.length = 0;
                return l;
            }
            void scanUntil(F)(string needle, F f) {
                auto d = needle.representation;
                ubyte[] acc;
                bool    eos; // end of stream

                while( !eos ) {
                    auto l = scanUntilR(needle, acc, eos);
                    debug(httpd) tracef("scanr returned <%s> and <%s>", cast(string)l, cast(string)acc);
                    f(l);
                    if ( acc == needle) {
                        return;
                    }
                }
            }
            void skipUntil(string needle) {
                auto d = needle.representation;
                ubyte[] acc;
                bool    eos; // end of stream

                while( !eos ) {
                    auto l = scanUntilR(needle, acc, eos);
                    debug(httpd) tracef("scanr returned <%s> and <%s>", cast(string)l, cast(string)acc);
                    if ( acc == needle) {
                        return;
                    }
                }
            }
        }

        auto createDataSource(string partialBody, NetworkStream stream) {

            if ( !requestHasBody ) {
                return new _DataSource();
            }

            auto ds = new _DataSource();

            ds._requestHasBody = true;
            ds._requestBodyRecvInProgr = true;
            ds._bodyDecoder = new DataPipe!ubyte;
            ds._stream = stream;

            if ( auto contentLengthHeader = "content-length" in _requestHeaders ) {
                ds._contentLength = to!long(*contentLengthHeader);
            }
            else if ( auto contentTransferEncoding = "transfer-encoding" in _requestHeaders ) {
                if ( *contentTransferEncoding=="chunked" ) {
                    ds._unChunker = new DecodeChunked();
                    ds._bodyDecoder.insert(ds._unChunker);
                }
            }
            if ( partialBody.length ) {
                ds._bodyDecoder.putNoCopy(cast(ubyte[])partialBody);
                ds._receivedLength = (cast(ubyte[])partialBody).length;
            }
            while ( ds._bodyDecoder.empty ) {
                auto b    = new ubyte[DSBUFFSIZE];
                auto read = stream.receive(b);
                if ( read == 0 ) {
                    debug(httpd) trace("stream closed when receiving in datasource");
                    ds._requestBodyRecvInProgr = false;
                    return ds;
                }
                debug(httpd) tracef("place %d bytes to datasource", read);
                ds._receivedLength += read;
                ds._bodyDecoder.putNoCopy(b[0..read]);
            }
            ds._content = ds._bodyDecoder.getNoCopy().join();
            if (   ( ds._contentLength > 0 && ds._receivedLength >= ds._contentLength )
                || ( ds._unChunker && ds._unChunker.done) ) {
                // all data received we need not wait any data from network
                debug(httpd) trace("looks like we received complete request body together with request headers");
                ds._requestBodyRecvInProgr = false;
                ds._requestBodyReceived = true;
            }
            debug(httpd) tracef("initial content: %d bytes", ds._content.length);
            return ds;
        }
        @property auto contentType() {
            if ( auto ct = "content-type" in _requestHeaders ) {
                auto f = (*ct).split(";").map!strip;
                return f[0];
            }
            return null;
        }

        struct PartData {
            // handler for each part data stream
            _DataSource    _ds;
            string         _boundary;
            ubyte[]        _content;
            ubyte[]        _acc;
            bool           _done;
            bool           _eos;

            this(_DataSource ds, string boundary) {
                _ds = ds;
                _boundary = "\r\n" ~ boundary;
                _content = _ds.scanUntilR(_boundary, _acc, _eos);
            }
            bool empty() {
                return _content.length == 0;
            }
            auto front() {
                return _content;
            }
            void popFront() {
                _content.length = 0;
                if ( _done ) {
                    return;
                }
                while( _content.length == 0 ) {
                    _content = _ds.scanUntilR(_boundary, _acc, _eos);
                    if ( _eos ) {
                        return;
                    }
                    if (_acc == _boundary) {
                        debug(httpd) tracef("part data done");
                        _ds.skipUntil("\r\n");
                        return;
                    }
                }
            }
        }
        struct Part {
            _DataSource    _ds;
            string[string] _headers;
            string         _boundary;

            this(_DataSource ds, string[string] h, string boundary) {
                _ds = ds;
                _headers = h;
                _boundary = boundary;
            }
            @property string[string] headers() {
                return _headers;
            }
            @property disposition() {
                string[string] res;
                auto d = "content-disposition" in _headers;
                if ( !d ) {
                    return res;
                }
                (*d).split(";").
                    filter!"a.indexOf('=')>0".
                        map!   "a.strip.split('=')".
                        each!(p => res[p[0]] = urlDecode(p[1]).strip('"'));
                return res;
            }
            @property data() {
                return PartData(_ds, _boundary);
            }
        }
        struct MultiPart {
            string      _boundary;
            _DataSource _ds;
            Part        _part;
            /*
             --8a60ded0-ee76-4b6a-a1a0-dccaf93b92e7
             Content-Disposition: form-data; name=Field1;

             form field from memory
             --8a60ded0-ee76-4b6a-a1a0-dccaf93b92e7
             Content-Disposition: form-data; name=Field2; filename=data2

             file field from memory
             --8a60ded0-ee76-4b6a-a1a0-dccaf93b92e7
             Content-Disposition: form-data; name=File1; filename=file1
             Content-Type: application/octet-stream

             file1 content

             --8a60ded0-ee76-4b6a-a1a0-dccaf93b92e7
             Content-Disposition: form-data; name=File2; filename=file2
             Content-Type: application/octet-stream

             file2 content

             --8a60ded0-ee76-4b6a-a1a0-dccaf93b92e7--
             */
            int opApply(int delegate(Part p) dg) {
                int result = 0;
                while(!_ds.empty) {
                    result = dg(_part);
                    if ( result ) {
                        break;
                    }
                    auto headers = skipHeaders();
                    _part = Part(_ds, headers, _boundary);
                }
                return result;
            }
            auto skipHeaders() {
                ubyte[] buf;
                string[string] headers;

                debug(httpd) tracef("Search for headers");
                _ds.scanUntil("\r\n\r\n", delegate void (ubyte[] data) {
                        buf ~= data;
                    });
                foreach(h; buf.split('\n').map!"cast(string)a".map!strip.filter!"a.length") {
                    auto parsed = h.findSplit(":");
                    headers[parsed[0].toLower] = parsed[2].strip;
                }
                debug(httpd) tracef("Headers: %s ", headers);
                return headers;
            }
            ///
            /// Find boundary from request headers,
            /// skip to begin of the first part,
            /// create first part(read/parse headers, stop on the body begin)
            ///
            this(HTTPD_Request rq) {
                ubyte[] buf, rest;
                string separator;
                auto ct = "content-type" in rq._requestHeaders;
                auto b = (*ct).split(";").map!"a.strip.split(`=`)".filter!"a[0].toLower==`boundary`";
                if ( b.empty ) {
                    throw new HTTPD_RequestException("Can't find 'boundary' in Content-Type %s".format(*ct));
                }
                _boundary = "--" ~ b.front[1];
                _ds = rq._dataSource;
                _ds.skipUntil(_boundary~"\r\n");
                auto headers = skipHeaders();
                _part = Part(_ds, headers, _boundary);
            }
        }

        auto multiPartRead() {
            return MultiPart(this);
        }

        auto read() {
            if ( requestHasBody && _dataSource._requestBodyProcessed ) {
                throw new HTTPD_RequestException("Request body already consumed by call to data/form/json");
            }
            if ( _dataSource._readStarted ) {
                throw new HTTPD_RequestException("Request body read() already started.");
            }
            _dataSource._readStarted = true;
            return _dataSource;
        }

        void loadBodyOnDemand(ref _DataSource ds) {
            ds._requestBodyProcessed = true;
            debug(httpd) tracef("Process %s onDemand", contentType);
            switch ( contentType ) {
                case "application/json":
                    while(!ds.empty) {
                        debug(httpd) tracef("add %d bytes to json from dataSource", ds.front.length);
                        _json ~= cast(string)ds.front;
                        ds.popFront;
                    }
                    break;
                case "application/x-www-form-urlencoded":
                    string qBody;
                    while(!ds.empty) {
                        debug(httpd) tracef("add %d bytes to json from dataSource", ds.front.length);
                        qBody ~= cast(string)ds.front;
                        ds.popFront;
                    }
                    _form = parseQuery(qBody);
                    break;
                case "multipart/form-data":
                    debug(httpd) tracef("loading multiPart on demand");
                    auto parts = multiPartRead();
                    foreach(p; parts) {
                        auto disposition = p.disposition;
                        auto data = p.data.joiner.array;

                        if ( !("name" in disposition) ) {
                            continue;
                        }
                        if ( auto fn = "filename" in disposition ) {
                            _files[disposition["name"]] = data;
                        } else {
                            _form[disposition["name"]]  = cast(string)data;
                        }
                    }
                    break;
                default:
                    while(!ds.empty) {
                        debug(httpd) tracef("add %d bytes to data from dataSource", ds.front.length);
                        _data ~= ds.front;
                        ds.popFront;
                    }
                    break;
            }
        }
    }

    string[int] codes;
    shared static this() {
        codes = [
            200: "OK",
            302: "Found",
            401: "Unauthorized",
            404: "Not found",
            405: "Method not allowed",
            500: "Server error"
        ];
    }
    enum Compression : int {
        no    =   0,
        gzip   =  1,
        deflate = 2,
        yes     = gzip|deflate,
    };

    auto response(C)(HTTPD_Request rq, C content, ushort code = 200)
        if ( isSomeString!C
            || (__traits(compiles, cast(ubyte[])content))
            || (__traits(compiles, cast(ubyte[])content.front))
            )
    {
        return new HTTPD_Response!C(rq, content, code);
    }

    class _Response {
        abstract void send(NetworkStream);
        abstract ref string[string] headers();
    }

    class HTTPD_Response(C) : _Response {
        ushort          _status = 200;
        string          _status_reason = "Unspecified";
        string[string]  _headers;
        C               _content;
        Compression     _compression = Compression.no;
        HTTPD_Request   _request;
        Cookie[]        _cookies;

        mixin(Getter_Setter!ushort("status"));
        mixin(Getter("compression"));
        @property void compress(Compression c = Compression.yes) {
            _compression = c;
        }
        this(ref HTTPD_Request request, C content, ushort status = 200) {
            _status  = status;
            _request = request;
            _content = content;
        }
        override ref string[string] headers() @property {
            return _headers;
        }
        ref Cookie[] cookies() {
            return _cookies;
        }
        void content(C)(C c) @property {
            _content = makeContent(c);
        }
        auto selectCompression(in HTTPD_Request rq, in HTTPD_Response rs) {
            if ( auto acceptEncodings = "accept-encoding" in rq.requestHeaders) {
                auto heAccept = (*acceptEncodings).split(",").map!strip;
                if ( (rs.compression & Compression.gzip) && heAccept.canFind("gzip")) {
                    return "gzip";
                }
                if ( (compression & Compression.deflate) && heAccept.canFind("deflate")) {
                    return "deflate";
                }
            }
            return null;
        }
        void sendCookies(NetworkStream stream) {
            if ( _cookies.length ) {
                foreach(c; _cookies) {
                    auto setCookie = "Set-Cookie: %s=%s; Path=%s\r\n".format(c.attr, c.value, c.path);
                    stream.send(setCookie);
                }
            }
        }
        final override void send(NetworkStream stream) {
            import std.zlib;
            auto    statusLine = "HTTP/1.1 " ~ to!string(_status) ~ " " ~ codes.get(_status, _status_reason) ~ " \r\n";

            if ( !stream.isOpen || !stream.isConnected ) {
                debug(httpd) tracef("Will not send to closed connection");
                return;
            }
            debug(httpd) tracef("sending statusLine: %s", statusLine.stripRight);
            stream.send(statusLine);

            auto comp = selectCompression(_request, this);

            static if ( isSomeString!C || __traits(compiles, cast(ubyte[])_content) ) {
                ubyte[] data;
                if ( comp ) {
                    _headers["content-encoding"] = comp;
                    Compress compressor;
                    final switch (comp) {
                        case "gzip": // gzip
                            compressor = new Compress(6, HeaderFormat.gzip);
                            break;
                        case "deflate": // deflate
                            compressor = new Compress(6, HeaderFormat.deflate);
                            break;
                    }
                    data = cast(ubyte[])compressor.compress(_content);
                    data ~= cast(ubyte[])compressor.flush();
                }
                else {
                    data = cast(ubyte[])_content;
                }
                _headers["content-length"] = to!string(data.length);
                foreach(p; _headers.byKeyValue) {
                    stream.send(p.key ~ ": " ~ p.value ~ "\r\n");
                }
                if ( _cookies.length ) {
                    sendCookies(stream);
                }
                stream.send("\r\n");
                if (_request.method == "HEAD") {
                    return;
                }
                stream.send(data);
            }
            else {
                _headers["transfer-encoding"] = "chunked";
                Compress compressor;
                if ( comp !is null ) {
                    _headers["content-encoding"] = comp;
                    final switch (comp) {
                        case "gzip": // gzip
                            compressor = new Compress(6, HeaderFormat.gzip);
                            break;
                        case "deflate": // deflate
                            compressor = new Compress(6, HeaderFormat.deflate);
                            break;
                    }
                }
                foreach(p; _headers.byKeyValue) {
                    stream.send(p.key ~ ": " ~ p.value ~ "\r\n");
                }
                if ( _cookies.length ) {
                    sendCookies(stream);
                }
                stream.send("\r\n");
                if (_request.method == "HEAD") {
                    return;
                }
                ubyte[] data;
                while(!_content.empty) {
                    auto chunk = cast(ubyte[])_content.front;
                    _content.popFront;

                    if ( compressor ) {
                        data ~= cast(ubyte[])compressor.compress(chunk);
                        if ( data.length == 0 ) {
                            continue;
                        }
                    } else {
                        data = chunk;
                    }
                    stream.send("%x\r\n".format(data.length));
                    stream.send(data);
                    stream.send("\r\n");
                    data.length = 0;
                }
                if ( compressor ) {
                    data = cast(ubyte[])compressor.flush();
                    stream.send("%x\r\n".format(data.length));
                    stream.send(data);
                    stream.send("\r\n");
                }
                stream.send("0\r\n\r\n");
            }
        }
    }

    alias Handler = _Response delegate(in App app, ref HTTPD_Request, RequestArgs);

    struct RequestArgs {
        private {
            Captures!string _captures = void;
            string          _string;
        }
        this(Captures!string c) @nogc @safe nothrow {
            _captures = c;
        }
        this(string s) @nogc @safe pure nothrow {
            _string = s;
        }
        bool empty() @nogc @safe pure nothrow {
            return _captures.empty && _string is null;
        }
        string opIndex(string s) @safe pure {
            return _captures[s];
        }
        string opIndex(size_t i) @safe pure {
            if ( _string && i==0 ) {
                return _string;
            }
            return _captures[i];
        }
    }

    auto exactRoute(string s, Handler h) @safe pure nothrow {
        return new ExactRoute(s, h);
    }

    auto regexRoute(string s, Handler h) @safe {
        return new RegexRoute(s, h);
    }

    class Route {
        Handler _handler;
        string  _origin;

        abstract RequestArgs match(string) {
            return RequestArgs();
        };
        final Handler handler() {
            return _handler;
        }
        final string origin() {
            return _origin;
        }
    }

    class ExactRoute: Route {

        this(string s, Handler h) @safe pure nothrow {
            _origin = s;
            _handler = h;
        }
        final override RequestArgs match(string input) {
            if ( input == _origin ) {
                debug(httpd) tracef("%s matches %s", input, _origin);
                return RequestArgs(input);
            }
            return RequestArgs();
        }
    }
    class RegexRoute: Route {
        Regex!char        _re;

        this(string r, Handler h) @safe {
            _origin = r;
            _handler = h;
            _re = regex(r);
        }
        final override RequestArgs match(string input) {
            auto m = matchFirst(input, _re);
            debug(httpd) if (!m.empty) {tracef("%s matches %s", input, _origin);}
            return RequestArgs(m);
        }
    }

    struct Router {
        alias RouteMatch = Tuple!(Handler, "handler", RequestArgs, "args");
        private Route[] _routes;

        void addRoute(Route r) {
            _routes ~= r;
        }
        auto getRoute(string path) {
            RouteMatch match;
            foreach(r; _routes) {
                auto args = r.match(path);
                if (!args.empty) {
                    match.handler = r.handler;
                    match.args = args;
                    break;
                }
            }
            return match;
        }
    }

    private auto parseQuery(string query) {
        /// TODO
        /// switch to return dict of
        /// struct QueryParam {
        ///   private:
        ///     string   name;
        ///     string[] value;
        ///   public:
        ///     uint length() {return value.length;}
        ///     string toString() {return value[0];}
        ///     string[] toArray() {return value;}
        /// }
        debug (httpd) tracef("query: %s", query);
        string[string] q;
        if ( !query ) {
            return q;
        }
        if ( query[0] == '?') {
            query = query[1..$];
        }
        string[][] parsed = query.splitter("&").
            map!(s => s.split("=")).
                filter!"a.length==2".
                map!(p => [urlDecode(p[0]), urlDecode(p[1])]).
                array;

        auto grouped = sort!"a[0]<b[0]"(parsed).assumeSorted!"a[0]<b[0]".groupBy();
        foreach(g; grouped) {
            string key = g.front[0];
            string val;
            auto vals = g.map!"a[1]".array;
            if (vals.length == 1) {
                val = vals[0];
            }
            if (vals.length > 1) {
                val = to!string(vals);
            }
            q[key] = val;
        }
        return q;
    }

    private bool headersReceived(in ubyte[] data, ref Buffer!ubyte buffer, out string separator) @safe {
        foreach(s; ["\r\n\r\n", "\n\n"]) {
            if ( data.canFind(s) || buffer.canFind(s) ) {
                separator = s;
                return true;
            }
        }
        return false;
    }

    private void parseRequestHeaders(in App app, ref HTTPD_Request rq, string buffer) {
        string lastHeader;
        auto   lines = buffer.splitLines.map!stripRight;
        rq.requestLine = lines[0];
        if ( lines.count == 1) {
            return;
        }
        foreach(line; lines[1..$]) {
            if ( !line.length ) {
                continue;
            }
            if ( line[0] == ' ' || line[0] == '\t' ) {
                // unfolding https://tools.ietf.org/html/rfc822#section-3.1
                if ( auto prevValue = lastHeader in rq.requestHeaders) {
                    *prevValue ~= line;
                }
                continue;
            }
            auto parsed = line.findSplit(":");
            auto header = parsed[0].toLower;
            auto value =  parsed[2].strip;
            lastHeader = header;
            if ( auto h = header in rq.requestHeaders ) {
                *h ~= "; " ~ value;
            } else {
                rq.requestHeaders[header] = value;
            }
            debug(httpd) tracef("%s: %s", header, value);
        }
        auto rqlFields = rq.requestLine.split(" ");
        debug (httpd) tracef("rqLine %s", rq.requestLine);
        rq.method = rqlFields[0];
        auto scheme = app.useSSL?
            "https://":
                "http://";
        if ( "host" in rq.requestHeaders ) {
            rq.uri = URI(scheme ~ rq.requestHeaders["host"] ~ rqlFields[1]);
        } else {
            rq.uri = URI(scheme ~ app.host ~ rqlFields[1]);
        }
        rq.path  = rq.uri.path;
        rq.query = parseQuery(rq.uri.query);
        debug (httpd) tracef("path: %s", rq.path);
        debug (httpd) tracef("query: %s", rq.query);
        //
        // now analyze what we have
        //
        auto header = "connection" in rq.requestHeaders;
        if ( header && toLower(*header) == "keep-alive") {
            rq.keepAlive = true;
        }
        auto cookies = "cookie" in rq.requestHeaders;
        if ( cookies ) {
            (*cookies).split(';').
                map!"strip(a).split('=')".
                    filter!(kv => kv.length==2).
                    each!(kv => rq._cookies[kv[0]] = kv[1]);
        }
    }

    private auto read_request(in App app, NetworkStream stream) {
        HTTPD_Request rq;
        Buffer!ubyte  input;
        string        separator;

        while( true ) {
            ubyte[] b = new ubyte[app.bufferSize];
            auto read = stream.receive(b);

            if ( read == 0 ) {
                return rq;
            }
            debug(httpd) tracef("received %d bytes", read);
            input.putNoCopy(b[0..read]);

            if ( headersReceived(b, input, separator) ) {
                break;
            }

            if ( input.length >= app.maxHeadersSize ) {
                throw new HTTPD_RequestException("Request headers length %d too large".format(input.length));
            }
        }
        debug(httpd) trace("Headers received");
        auto s = input.data!(string).findSplit(separator);
        auto requestHeaders = s[0];
        debug(httpd) tracef("Headers: %s", cast(string)requestHeaders);
        parseRequestHeaders(app, rq, requestHeaders);
        debug(httpd) trace("Headers parsed");

        rq._dataSource = rq.createDataSource(s[2], stream);

        return rq;
    }

    void processor(in App app, HTTPD httpd, NetworkStream stream) {
        stream.readTimeout = app.timeout;
        HTTPD_Request  rq;
        _Response      rs;
        scope (exit) {
            if ( stream.isOpen ) {
                stream.close();
            }
        }
        uint rqLimit = max(app.rqLimit, 1);
        try {
            while ( rqLimit > 0 ) {
                rq = read_request(app, stream);
                if ( !httpd._running || !rq.requestLine.length ) {
                    return;
                }
                auto match = httpd._router.getRoute(rq.path);
                if ( !match.handler ) {
                    // return 404;
                    debug (httpd) tracef("Route not found for %s", rq.path);
                    rs = response(rq, "Requested path %s not found".format(rq.path), 404);
                    break;
                }
                auto handler = match.handler;
                rs = handler(app, rq, match.args);
                if ( !stream.isOpen ) {
                    debug(httpd) tracef("Request handler closed connection");
                    return;
                }
                if ( rq.keepAlive && rqLimit > 1 ) {
                    rs.headers["Connection"] = "Keep-Alive";
                }
                if ( rq._dataSource._requestHasBody && !rq._dataSource._requestBodyReceived ) {
                    // for some reason some part of the request body still not received, and it will
                    // stay on the way of next request if this is keep-Alive session,
                    // so we must abort this connection anyway.
                    debug(httpd) trace("Request handler did not consumed whole request body. We have to close connection after sending response.");
                    rs.send(stream);
                    return;
                }
                rs.send(stream);
                --rqLimit;
                if ( !rq.keepAlive || rqLimit==0 ) {
                    debug(httpd) trace("Finished with that connection");
                    return;
                }
                debug(httpd) trace("Continue with keepalive request");
                rq = rq.init;
            }
        }
        catch (HTTPD_RequestException e) {
            debug(httpd)  error("Request exception: " ~ e.msg);
            rs = response(rq, "Request exception:\n" ~ e.msg, 500);
        }
        catch (TimeoutException e) {
            debug(httpd) {
                if ( rq.requestLine ) {
                    error("Timeout reading/writing to client");
                }
            }
        }
        catch (Exception e) {
            debug(httpd) error("Unexpected Exception " ~ e.msg);
            rs = response(rq, "Unexpected exception:\n" ~ e.msg, 500);
        }
        catch (Error e) {
            error(e.msg, e.info);
            rs = response(rq, "Unexpected error:\n" ~ e.msg, 500);
        }
        try {
            if ( stream.isOpen ) {
                rs.send(stream);
            }
        }
        catch (Exception e) {
            infof("Exception when send %s", e.msg);
        }
        catch (Error e) {
            error("Error sending response: " ~ e.msg);
        }
    }

    class HTTPD
    {
        private {
            TaskPool              _server;
            __gshared bool        _running;
            Router                _router;
            App                   _app;
        }
        auto ref addRoute(Route r) {
            _router.addRoute(r);
            return this;
        }
        static NetworkStream openStream(in App app) {
            auto host = app.host;
            auto port = app.port;
            Address[] addresses;
            SSLOptions _sslOptions;

            try {
                addresses = getAddress(host, port);
            } catch (Exception e) {
                throw new ConnectError("Can't resolve name when connect to %s:%d: %s".format(host, port, e.msg));
            }
            auto tcpStream = app.useSSL?
                new SSLStream(_sslOptions):
                new TCPStream();
            tcpStream.open(addresses[0].addressFamily);
            return tcpStream;
        }
        static void run(in App app, HTTPD httpd) {
            Address[] addresses;
            try {
                addresses = getAddress(app.host, app.port);
            } catch (Exception e) {
                throw new ConnectError("Can't resolve name when connect to %s:%d: %s".format(app.host, app.port, e.msg));
            }
            auto tcpStream = openStream(app);
            tcpStream.reuseAddr(true);
            tcpStream.bind(addresses[0]);
            tcpStream.listen(128);
            defaultPoolThreads(64);
            auto pool = taskPool();
            _running = true;
            while ( _running ) {
                auto stream = tcpStream.accept();
                if ( _running ) {
                    auto connHandler = task!processor(app, httpd, stream);
                    pool.put(connHandler);
                } else {
                    tcpStream.close();
                    break;
                }
            }
        }
        void app(App a) {
            _app = a;
        }
        void start() {
            defaultPoolThreads(64);
            _server = taskPool();
            auto t = task!run(_app, this);
            _server.put(t);
            Thread.sleep(500.msecs);
        }
        void start(App app) {
            defaultPoolThreads(64);
            _app = app;
            _server = taskPool();
            auto t = task!run(_app, this);
            _server.put(t);
            Thread.sleep(500.msecs);
        }
        void stop() {
            if ( !_running ) {
                return;
            }
            _running = false;
            try {
                auto s = openStream(_app);
                s.connect(_app.host, _app.port);
            } catch (Exception e) {
            }
            //        _server.stop();
        }
    }

    struct App {
        private {
            string   _name;
            string   _host;
            ushort   _port;
            Duration _timeout = 30.seconds;
            size_t   _bufferSize =     16*1024;
            size_t   _maxHeadersSize = 32*1024;
            bool     _useSSL = false;
            uint      _rqLimit = 10; // keepalive requestst per connection
            Router   _router;
        }
        mixin(Getter_Setter!string("name"));
        mixin(Getter_Setter!string("host"));
        mixin(Getter_Setter!ushort("port"));
        mixin(Getter_Setter!size_t("bufferSize"));
        mixin(Getter_Setter!size_t("maxHeadersSize"));
        mixin(Getter_Setter!Duration("timeout"));
        mixin(Getter_Setter!bool("useSSL"));
        mixin(Getter_Setter!uint("rqLimit"));
        this(string name) {
            _name = name;
        }
    }


    version(none) private unittest {
        import std.json;
        import std.conv;
        import requests.http: HTTPRequest, TimeoutException, BasicAuthentication, queryParams, MultipartForm, formData;
        globalLogLevel(LogLevel.info);

        static auto buildReply(ref HTTPD_Request rq) {
            auto args    = JSONValue(rq.query);
            auto headers = JSONValue(rq.requestHeaders);
            auto url     = JSONValue(rq.uri.uri);
            auto json    = JSONValue(rq.json);
            auto data    = JSONValue(rq.data);
            auto form    = JSONValue(rq.form);
            auto files   = JSONValue(rq.files);
            auto reply   = JSONValue(["args":args, "headers": headers, "json": json, "url": url, "data": data, "form": form, "files": files]);
            return reply.toString();
        }

        Router router;
        router.addRoute(exactRoute(r"/get", null));
        router.addRoute(regexRoute(r"/get/(?P<param>\d+)", null));
        auto r = router.getRoute(r"/get");
        assert(!r.args.empty);
        r = router.getRoute(r"/post");
        assert(r.args.empty);

        r = router.getRoute(r"/get/333");
        assert(!r.args.empty);
        assert(r.args["param"]=="333");
        r = router.getRoute(r"/get/aaa");
        assert(r.args.empty);

        HTTPD_Request rq;
        string headers = "GET /get?a=b&list[]=1&c=d&list[]=2 HTTP/1.1\n" ~
                         "Host: host\n" ~
                         "X-Test: test1\n" ~
                         " test2\n" ~
                         "Content-Length: 1\n";
        parseRequestHeaders(App(), rq, headers);
        assert(rq.requestHeaders["x-test"] == "test1 test2");
        assert(rq.requestHeaders["host"] == "host");
        assert(rq.path == "/get");
        assert(rq.query["a"] == "b");
        assert(rq.query["c"] == "d");
        assert(rq.query["list[]"] == `["1", "2"]`);
        auto root(in App app, ref HTTPD_Request rq,  RequestArgs args) {
            debug (httpd) trace("handler / called");
            auto rs = response(rq, buildReply(rq));
            rs.headers["Content-Type"] = "application/json";
            return rs;
        }
        auto get(in App app, ref HTTPD_Request rq,  RequestArgs args) {
            debug (httpd) trace("handler /get called");
            auto rs = response(rq, buildReply(rq));
            rs.headers["Content-Type"] = "application/json";
            return rs;
        }
        auto basicAuth(in App app, ref HTTPD_Request rq, RequestArgs args) {
            import std.base64;
            auto user    = args["user"];
            auto password= args["password"];
            auto auth    = cast(string)Base64.decode(rq.requestHeaders["authorization"].split()[1]);
            auto up      = auth.split(":");
            short status;
            if ( up[0]==user && up[1]==password) {
                status = 200;
            } else {
                status = 401;
            }
            auto rs = response(rq, buildReply(rq), status);
            rs.headers["Content-Type"] = "application/json";
            return rs;
        }
        auto rredir(in App app, ref HTTPD_Request rq,  RequestArgs args) {
            auto rs = response(rq, buildReply(rq));
            auto redirects = to!long(args["redirects"]);
            if ( redirects > 1 ) {
                rs.headers["Location"] = "/relative-redirect/%d".format(redirects-1);
            } else {
                rs.headers["Location"] = "/get";
            }
            rs.status    = 302;
            return rs;
        }
        auto aredir(in App app, ref HTTPD_Request rq,  RequestArgs args) {
            auto rs = response(rq, buildReply(rq));
            auto redirects = to!long(args["redirects"]);
            if ( redirects > 1 ) {
                rs.headers["Location"] = "http://127.0.0.1:8081/absolute-redirect/%d".format(redirects-1);
            } else {
                rs.headers["Location"] = "http://127.0.0.1:8081/get";
            }
            rs.status    = 302;
            return rs;
        }
        auto delay(in App app, ref HTTPD_Request rq, RequestArgs args) {
            auto delay = dur!"seconds"(to!long(args["delay"]));
            Thread.sleep(delay);
            auto rs = response(rq, buildReply(rq));
            rs.headers["Content-Type"] = "application/json";
            return rs;
        }
        auto gzip(in App app, ref HTTPD_Request rq, RequestArgs args) {
            auto rs = response(rq, buildReply(rq));
            rs.compress(Compression.gzip);
            rs.headers["Content-Type"] = "application/json";
            return rs;
        }
        auto deflate(in App app, ref HTTPD_Request rq, RequestArgs args) {
            auto rs = response(rq, buildReply(rq));
            rs.compress(Compression.deflate);
            return rs;
        }
        auto range(in App app, ref HTTPD_Request rq, RequestArgs args) {
            auto size = to!size_t(args["size"]);
            auto rs = response(rq, new ubyte[size].chunks(16));
            rs.compress(Compression.yes);
            return rs;
        }
        auto head(in App app, ref HTTPD_Request rq, RequestArgs args) {
            if ( rq.method != "HEAD") {
                auto rs = response(rq, "Illegal method %s".format(rq.method), 405);
                return rs;
            }
            else {
                auto rs = response(rq, buildReply(rq));
                rs.compress(Compression.yes);
                return rs;
            }
        }
        auto del(in App app, ref HTTPD_Request rq, RequestArgs args) {
            if ( rq.method != "DELETE") {
                auto rs = response(rq, "Illegal method %s".format(rq.method), 405);
                return rs;
            }
            else {
                auto rs = response(rq, buildReply(rq));
                return rs;
            }
        }
        auto post(in App app, ref HTTPD_Request rq, RequestArgs args) {
            auto rs = response(rq, buildReply(rq));
            return rs;
        }
        auto postIter(in App app, ref HTTPD_Request rq, RequestArgs args) {
            int  c;

            if ( rq.contentType == "multipart/form-data" ) {
                auto parts = rq.multiPartRead();
                foreach(p; parts) {
                    auto disposition = p.disposition;
                    c += p.data.joiner.count;
                }
                auto rs = response(rq, "%d".format(c));
                return rs;
            }
            else {
                auto r = rq.read();
                while ( !r.empty ) {
                    c += r.front.length;
                    r.popFront;
                }
                auto rs = response(rq, "%d".format(c));
                return rs;
            }
        }
        auto read(in App app, ref HTTPD_Request rq, RequestArgs args) {
            auto r = rq.read();
            int  c;
            while ( !r.empty ) {
                c += r.front.length;
                r.popFront;
            }
            auto rs = response(rq, "%d".format(c));
            return rs;
        }
        auto readf1(in App app, ref HTTPD_Request rq, RequestArgs args) {
            // now call to read must throw exception
            auto r = rq.read();
            int  c;
            while ( !r.empty ) {
                c += r.front.length;
                r.popFront;
                break;
            }
            auto rs = response(rq, "%d".format(c));
            return rs;
        }
        auto cookiesSet(in App app, ref HTTPD_Request rq, RequestArgs args) {
            Cookie[] cookies;
            foreach(p; rq.query.byKeyValue) {
                cookies ~= Cookie("/cookies", rq.requestHeaders["host"], p.key, p.value);
            }
            auto rs = response(rq, buildReply(rq), 302);
            rs.headers["Location"] = "/cookies";
            rs.cookies = cookies;
            return rs;
        }
        auto cookies(in App app, ref HTTPD_Request rq, RequestArgs args) {
            auto cookies = ["cookies": JSONValue(rq.cookies)];
            auto rs = response(rq, JSONValue(cookies).toString);
            return rs;
        }

        auto httpbin = App("httpbin");

        httpbin.port = 8081;
        httpbin.host = "127.0.0.1";

        httpbin.timeout = 10.seconds;
        HTTPD server = new HTTPD();

        server.addRoute(exactRoute(r"/", &root)).
                addRoute(exactRoute(r"/get", &get)).
                addRoute(regexRoute(r"/delay/(?P<delay>\d+)", &delay)).
                addRoute(regexRoute(r"/relative-redirect/(?P<redirects>\d+)", &rredir)).
                addRoute(regexRoute(r"/absolute-redirect/(?P<redirects>\d+)", &aredir)).
                addRoute(regexRoute(r"/basic-auth/(?P<user>[^/]+)/(?P<password>[^/]+)", &basicAuth)).
                addRoute(exactRoute(r"/gzip", &gzip)).
                addRoute(exactRoute(r"/deflate", &deflate)).
                addRoute(regexRoute(r"/range/(?P<size>\d+)", &range)).
                addRoute(exactRoute(r"/cookies/set", &cookiesSet)).
                addRoute(exactRoute(r"/cookies", &cookies)).
                addRoute(exactRoute(r"/head", &head)).
                addRoute(exactRoute(r"/delete", &del)).
                addRoute(exactRoute(r"/read", &read)).
                addRoute(exactRoute(r"/readf1", &readf1)).
                addRoute(exactRoute(r"/post", &post)).
                addRoute(exactRoute(r"/postIter", &postIter));

        server.start(httpbin);
        scope(exit) {
            server.stop();
        }
        auto request = HTTPRequest();

        globalLogLevel(LogLevel.info);
        auto httpbin_url = "http://%s:%d/".format(httpbin.host, httpbin.port);
        request.timeout = 5.seconds;
        request.keepAlive = true;
        info("httpd Check GET");
        auto rs = request.get(httpbin_url);
        assert(rs.code == 200);
        assert(rs.responseBody.length > 0);
        auto content = rs.responseBody.data!string;
        auto json = parseJSON(cast(string)content);
        assert(json.object["url"].str == httpbin_url);

        info("httpd Check GET with parameters");
        rs = request.get(httpbin_url ~ "get", ["c":" d", "a":"b"]);
        assert(rs.code == 200);
        json = parseJSON(cast(string)rs.responseBody.data).object["args"].object;
        assert(json["a"].str == "b");
        assert(json["c"].str == " d");

        info("httpd Check relative redirect");
        rs = request.get(httpbin_url ~ "relative-redirect/2");
        assert(rs.history.length == 2);
        assert(rs.code==200);

        info("httpd Check absolute redirect");
        rs = request.get(httpbin_url ~ "absolute-redirect/2");
        assert(rs.history.length == 2);
        assert(rs.code==200);

        info("httpd Check basic auth");
        request.authenticator = new BasicAuthentication("user", "password");
        rs = request.get(httpbin_url ~ "basic-auth/user/password");
        assert(rs.code==200);
        request.authenticator = null;

        info("httpd Check timeout");
        request.timeout = 1.seconds;
        assertThrown!TimeoutException(request.get(httpbin_url ~ "delay/2"));
        Thread.sleep(1.seconds);
        request.timeout = 30.seconds;

        info("httpd Check gzip");
        rs = request.get(httpbin_url ~ "gzip");
        assert(rs.code==200);
        json = parseJSON(cast(string)rs.responseBody);
        assert(json.object["url"].str == httpbin_url ~ "gzip");

        info("httpd Check deflate");
        rs = request.get(httpbin_url ~ "deflate");
        assert(rs.code==200);
        json = parseJSON(cast(string)rs.responseBody);
        assert(json.object["url"].str == httpbin_url ~ "deflate");

        info("httpd Check range");
        rs = request.get(httpbin_url ~ "range/1023");
        assert(rs.code==200);
        assert(rs.responseBody.length == 1023);

        info("httpd Check HEAD");
        rs = request.exec!"HEAD"(httpbin_url ~ "head");
        assert(rs.code==200);
        assert(rs.responseBody.length == 0);

        info("httpd Check DELETE");
        rs = request.exec!"DELETE"(httpbin_url ~ "delete");
        assert(rs.code==200);

        info("httpd Check POST json");
        rs = request.post(httpbin_url ~ "post?b=x", `{"a":"b", "c":[1,2,3]}`, "application/json");
        json = parseJSON(cast(string)rs.responseBody);
        auto rqJson = parseJSON(json.object["json"].str);
        assert(rqJson.object["a"].str == "b");
        assert(equal([1,2,3], rqJson.object["c"].array.map!"a.integer"));

        info("httpd Check POST json/chunked body");
        rs = request.post(httpbin_url ~ "post?b=x", [`{"a":"b",`,` "c":[1,2,3]}`], "application/json");
        json = parseJSON(cast(string)rs.responseBody);
        assert(json.object["args"].object["b"].str == "x");
        rqJson = parseJSON(json.object["json"].str);
        assert(rqJson.object["a"].str == "b");
        assert(equal([1,2,3], rqJson.object["c"].array.map!"a.integer"));

        rs = request.post(httpbin_url ~ "post", "0123456789".repeat(32));
        json = parseJSON(cast(string)rs.responseBody);
        assert(equal(json.object["data"].array.map!"a.integer", "0123456789".repeat(32).join));

        info("httpd Check POST with params");
        rs = request.post(httpbin_url ~ "post", queryParams("b", 2, "a", "A"));
        assert(rs.code==200);
        auto data = parseJSON(cast(string)rs.responseBody).object["form"].object;
        assert((data["a"].str == "A"));
        assert((data["b"].str == "2"));

        // this is tests for httpd read() interface
        info("httpd Check POST/iterating over body");
        rs = request.post(httpbin_url ~ "read", "0123456789".repeat(1500));
        assert(equal(rs.responseBody, "15000"));

        {
            request.keepAlive = true;
            // this is test on how we can handle keepalive session when previous request leave unread data in socket
            try {
                rs = request.post(httpbin_url ~ "readf1", "0123456789".repeat(1500));
            }
            catch (Exception e) {
                // this can fail as httpd will close connection prematurely
            }
            // but next idempotent request must succeed
            rs = request.get(httpbin_url ~ "get");
            assert(rs.code == 200);
        }
        //
        {
            info("httpd Check POST/multipart form");
            import std.file;
            import std.path;
            auto tmpd = tempDir();
            auto tmpfname1 = tmpd ~ dirSeparator ~ "request_test1.txt";
            auto f = File(tmpfname1, "wb");
            f.rawWrite("file1 content\n");
            f.close();
            auto tmpfname2 = tmpd ~ dirSeparator ~ "request_test2.txt";
            f = File(tmpfname2, "wb");
            f.rawWrite("file2 content\n");
            f.close();
            ///
            /// Ok, files ready.
            /// Now we will prepare Form data
            ///
            File f1 = File(tmpfname1, "rb");
            File f2 = File(tmpfname2, "rb");
            scope(exit) {
                f1.close();
                f2.close();
            }
            ///
            /// for each part we have to set field name, source (ubyte array or opened file) and optional filename and content-type
            ///
            MultipartForm form = MultipartForm().
                add(formData("Field1", cast(ubyte[])"form field from memory")).
                    add(formData("Field2", cast(ubyte[])"file field from memory", ["filename":"data2"])).
                    add(formData("Field3", cast(ubyte[])`{"a":"b"}`, ["Content-Type": "application/json"])).
                    add(formData("File1", f1, ["filename":"file1", "Content-Type": "application/octet-stream"])).
                    add(formData("File2", f2, ["filename":"file2", "Content-Type": "application/octet-stream"]));
            /// everything ready, send request
            rs = request.post(httpbin_url ~ "post?a=b", form);
            /* expected:
             {
             "args": {
             "a": "b"
             },
             "data": "",
             "files": {
             "Field2": "file field from memory",
             "File1": "file1 content\n",
             "File2": "file2 content\n"
             },
             "form": {
             "Field1": "form field from memory",
             "Field3": "{\"a\":\"b\"}"
             },
             "headers": {
             "Accept-Encoding": "gzip, deflate",
             "Content-Length": "730",
             "Content-Type": "multipart/form-data; boundary=d79a383e-7912-4d36-a6db-a6774bf37133",
             "Host": "httpbin.org",
             "User-Agent": "dlang-requests"
             },
             "json": null,
             "origin": "xxx.xxx.xxx.xxx",
             "url": "http://httpbin.org/post?a=b"
             }
             */
            json = parseJSON(cast(string)rs.responseBody);
            assert("file field from memory" == cast(string)(json.object["files"].object["Field2"].array.map!(a => cast(ubyte)a.integer).array));
            assert("file1 content\n" == cast(string)(json.object["files"].object["File1"].array.map!(a => cast(ubyte)a.integer).array));

            info("httpd Check POST/iterate over multipart form");
            form = MultipartForm().
                add(formData("Field1", cast(ubyte[])"form field from memory")).
                    add(formData("Field2", cast(ubyte[])"file field from memory", ["filename":"data2"])).
                    add(formData("Field3", cast(ubyte[])`{"a":"b"}`, ["Content-Type": "application/json"]));
            /// everything ready, send request
            rs = request.post(httpbin_url ~ "postIter?a=b", form);
            assert(equal(rs.responseBody, "53"));
            rs = request.post(httpbin_url ~ "postIter", "0123456789".repeat(1500));
            assert(equal(rs.responseBody, "15000"));
        }
        info("httpd Check cookies");
        rs = request.get(httpbin_url ~ "cookies/set?A=abcd&b=cdef");
        json = parseJSON(cast(string)rs.responseBody.data).object["cookies"].object;
        assert(json["A"].str == "abcd");
        assert(json["b"].str == "cdef");
    }
}
