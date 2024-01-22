/**
 * This module provides API using Request structure.
 *
 * Structure Request provides configuration, connection pooling, cookie
 * persistance. You can consider it as 'Session' and reuse it - all caches and settings will effective
 * for next requests.

 * Some most usefull settings:

$(TABLE
 $(TR
  $(TH name)
  $(TH type)
  $(TH meaning)
  $(TH default)
 )
 $(TR
  $(TD keepAlive)
  $(TD `bool`)
  $(TD use keepalive connection)
  $(TD `true`)
 )
 $(TR
  $(TD verbosity)
  $(TD `uint`)
  $(TD verbosity level $(LPAREN)0, 1, 2 or 3$(RPAREN))
  $(TD `16KB`)
 )
 $(TR
  $(TD maxRedirects)
  $(TD `uint`)
  $(TD maximum redirects allowed $(LPAREN)0 to disable redirects$(RPAREN))
  $(TD `true`)
 )
 $(TR
  $(TD maxHeadersLength)
  $(TD `size_t`)
  $(TD max. acceptable response headers length)
  $(TD `32KB`)
 )
 $(TR
  $(TD maxContentLength)
  $(TD `size_t`)
  $(TD max. acceptable content length)
  $(TD `0` - unlimited)
 )
 $(TR
  $(TD bufferSize)
  $(TD `size_t`)
  $(TD socket io buffer size)
  $(TD `16KB`)
 )
 $(TR
  $(TD timeout)
  $(TD `Duration`)
  $(TD timeout on connect or data transfer)
  $(TD `30.seconds`)
 )
 $(TR
  $(TD proxy)
  $(TD `string`)
  $(TD url of the HTTP/HTTPS/FTP proxy)
  $(TD `null`)
 )
 $(TR
  $(TD bind)
  $(TD `string`)
  $(TD use local address for outgoing connections)
  $(TD `null`)
 )
 $(TR
  $(TD useStreaming)
  $(TD `bool`)
  $(TD receive response data as `InputRange` in case it can't fit memory)
  $(TD `false`)
 )
 $(TR
  $(TD addHeaders)
  $(TD `string[string]`)
  $(TD custom headers)
  $(TD `null`)
 )
 $(TR
  $(TD cookie)
  $(TD `Cookie[]`)
  $(TD cookies you will send to server)
  $(TD `null`)
 )
 $(TR
  $(TD authenticator)
  $(TD `Auth`)
  $(TD authenticator)
  $(TD `null`)
 )
 $(TR
  $(TD socketFactory)
  $(TD see doc for socketFactory)
  $(TD user-provided connection factory)
  $(TD `null`)
 )
)

 * Example:
 * ---
 * import requests;
 * import std.datetime;
 *
 * void main()
 * {
 *     Request rq = Request();
 *     Response rs;
 *     rq.timeout = 10.seconds;
 *     rq.addHeaders(["User-Agent": "unknown"]);
 *     rs = rq.get("https://httpbin.org/get");
 *     assert(rs.code==200);
 *     rs = rq.post("http://httpbin.org/post", "abc");
 *     assert(rs.code==200);
 * }
 * ---

*/
module requests.request;
import requests.http;
import requests.ftp;
import requests.streams;
import requests.base;
import requests.uri;

import std.datetime;
import std.conv;
import std.range;
import std.experimental.logger;
import std.format;
import std.typecons;
import std.stdio;
import std.algorithm;
import std.uni;

import requests.utils;
import requests.connmanager;
import requests.rangeadapter;

alias NetStreamFactory = NetworkStream delegate(string, string, ushort);

/**
 *  'Intercepror' intercepts Request. It can modify request, or log it, or cache it
 *  or do whatever you need. When done it can return response or
 *  pass it to next request handler.
 *                                                                    
 *   Example:                                                       
 *   ---
 *   class ChangePath : Interceptor                              
 *   {                                                                
 *      Response opCall(Request r, RequestHandler next)
 *         {
 *             r.path = r.path ~ "get";
 *             auto rs = next.handle(r);
 *             return rs;
 *         }                                                                 
 *   }                                                                
 *   ---                                                              
 *   Later in the code you can use this class:    
 *   Example:                                                        
 *   ---
 *   Request rq;
 *   rq.addInterceptor(new ChangePath());
 *   rq.get("http://example.com");
 *   ---
 *
*/
interface Interceptor {
    Response opCall(Request r, RequestHandler next);
}
class RequestHandler {
    private Interceptor[] _interceptors;
    this(Interceptor[] i)
    {
        _interceptors = i;
    }
    Response handle(Request r)
    {
        auto i = _interceptors.front();
        _interceptors.popFront();
        return i(r, this);
    }
}

private Interceptor[] _static_interceptors;
/**
 * Add module-level interceptor. Each Request will include it in the processing.
 * it is handy as you can change behaviour of your requests without any changes
 * in your code, just install interceptor before any call to Request().
*/
public void addInterceptor(Interceptor i)
{
    _static_interceptors ~= i;
}

/**
 * Structure Request provides configuration, connection pooling, cookie
 * persistance. You can consider it as 'Session'.
*/
public struct Request {
    private {
        /// use streaming when receive response
        bool                    _useStreaming;

        /// limit redirect number
        uint                    _maxRedirects = 10;

        /// Auth provider
        Auth                    _authenticator;

        /// maximum headers length
        size_t                  _maxHeadersLength = 32 * 1024;   // 32 KB

        /// maximum content length
        size_t                  _maxContentLength;               // 0 - Unlimited

        /// logging verbosity
        uint                    _verbosity = 0;

        /// use keepalive requests
        bool                    _keepAlive = true;

        /// io buffer size
        size_t                  _bufferSize = 16*1024;

        /// http/https proxy
        string                  _proxy;

        /// content type for POST/PUT requests
        string                  _contentType;                     // content type for POST/PUT payloads

        /// timeout for connect/send/receive
        Duration                _timeout = 30.seconds;

        /// verify peer when using ssl
        bool                    _sslSetVerifyPeer = true;
        SSLOptions              _sslOptions;

        /// bind outgoing connections to this addr (name or ip)
        string                  _bind;

        _UH                     _userHeaders;

        /// user-provided headers(use addHeader to add)
        string[string]          _headers;
        //

        // instrumentation
        /// user-provided socket factory
        NetStreamFactory        _socketFactory;

        /// user-provided interceptors
        Interceptor[]           _interceptors;
        //

        // parameters for each request
        /// uri for the request
        URI                     _uri;
        /// method (GET, POST, ...)
        string                  _method;
        /// request parameters
        QueryParam[]            _params;
        /// multipart form (for multipart POST requests)
        MultipartForm           _multipartForm;
        /// unified interface for post data
        InputRangeAdapter       _postData;
        //

        // can be changed during execution
        /// connection cache
        RefCounted!ConnManager  _cm;                              // connection manager
        /// cookie storage
        RefCounted!Cookies      _cookie;                          // cookies received
        /// permanent redirect cache
        string[URI]             _permanent_redirects;             // cache 301 redirects for GET requests
        //

    }
    /** Get/Set timeout on connection and IO operation.
     *  **v** - timeout value
     *  If timeout expired Request operation will throw $(B TimeoutException).
     */
    mixin(Getter_Setter!Duration("timeout"));
    mixin(Getter_Setter!bool("keepAlive"));
    mixin(Getter_Setter!uint("maxRedirects"));
    mixin(Getter_Setter!size_t("maxContentLength"));
    mixin(Getter_Setter!size_t("maxHeadersLength"));
    mixin(Getter_Setter!size_t("bufferSize"));
    mixin(Getter_Setter!uint("verbosity"));
    mixin(Getter_Setter!Auth("authenticator"));
    /// set proxy property.
    /// $(B v) - full url to proxy.
    ///
    /// Note that we recognize proxy settings from process environment (see $(LINK https://github.com/ikod/dlang-requests/issues/46)):
    /// you can use http_proxy, https_proxy, all_proxy (as well as uppercase names).
    mixin(Getter_Setter!string("proxy"));
    mixin(Getter_Setter!string("method"));
    mixin(Getter("uri"));
    mixin(Getter("params"));
    mixin(Getter("contentType"));
    mixin(Getter_Setter!InputRangeAdapter("postData"));
    mixin(Getter("permanent_redirects"));
    mixin(Getter("multipartForm"));
    mixin(Getter_Setter!NetStreamFactory("socketFactory"));
    mixin(Getter_Setter!bool("useStreaming"));
    mixin(Getter_Setter!(RefCounted!Cookies)("cookie"));
    mixin(Getter_Setter!string("bind"));
    mixin(Getter_Setter!(string[string])("headers"));

    /**
        Set and Get uri for next request.
     */
    @property void uri(string u) pure @safe
    {
        _uri = URI(u);
    }

    /**
        Set/Get path for next request.
    */
    @property void path(string p) pure @nogc
    {
        _uri.path = p;
    }
    /**
        ditto
    */
    @property string path() const @safe pure @nogc
    {
        return _uri.path;
    }

    mixin(Getter("sslOptions"));
    /**
        Enable/disable ssl peer verification..
    */
    @property void sslSetVerifyPeer(bool v) pure @safe nothrow @nogc {
        _sslOptions.setVerifyPeer(v);
    }
    /**
        Set path and format for ssl key file.
    */
    @property void sslSetKeyFile(string p, SSLOptions.filetype t = SSLOptions.filetype.pem) pure @safe nothrow @nogc {
        _sslOptions.setKeyFile(p, t);
    }
    /**
        Set path and format for ssl certificate file.
    */
    @property void sslSetCertFile(string p, SSLOptions.filetype t = SSLOptions.filetype.pem) pure @safe nothrow @nogc {
        _sslOptions.setCertFile(p, t);
    }
    /**
        Set path to certificate authority file.
    */
    @property void sslSetCaCert(string path) pure @safe nothrow @nogc {
        _sslOptions.setCaCert(path);
    }

    /*
        userHeaders keep bitflags for user-setted important headers
    */
    package @property auto userHeaders() pure @safe nothrow @nogc
    {
        return _userHeaders;
    }

    /++
     + Add headers to request
     + Params:
     + headers = headers to send.
     + Example:
     + ---
     +    rq = Request();
     +    rq.keepAlive = true;
     +    rq.addHeaders(["X-Header": "test"]);
     + ---
     +/
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
    ///
    /// Remove any previously added headers.
    ///
    void clearHeaders() {
        _headers = null;
        _userHeaders = _UH.init;
    }
    /// Execute GET for http and retrieve file for FTP.
    /// You have to provide at least $(B uri). All other arguments should conform to HTTPRequest.get or FTPRequest.get depending on the URI scheme.
    /// When arguments do not conform scheme (for example you try to call get("ftp://somehost.net/pub/README", {"a":"b"}) which doesn't make sense)
    /// you will receive Exception("Operation not supported for ftp")
    ///

    /// Execute POST for http and STOR file for FTP.
    /// You have to provide  $(B uri) and data. Data should conform to HTTPRequest.post or FTPRequest.post depending on the URI scheme.
    /// When arguments do not conform scheme you will receive Exception("Operation not supported for ftp")
    ///

    Response exec(string method="GET", A...)(string url, A args)
    {
        return execute(method, url, args);
    }
    Response exec(string method="GET")(string url, string[string] query)
    {
        return execute(method, url, aa2params(query));
    }
    string toString() const {
        return "Request(%s, %s)".format(_method, _uri.uri());
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
    @property auto cm() {
        return _cm;
    }
    /// helper
    @property bool hasMultipartForm() const
    {
        return !_multipartForm.empty;
    }
    /// Add interceptor to request.
    void addInterceptor(Interceptor i)
    {
        _interceptors ~= i;
    }

    package class LastInterceptor : Interceptor
    {
        Response opCall(Request r, RequestHandler _)
        {
            switch (r._uri.scheme)
            {
                case "ftp":
                    FTPRequest ftp;
                    return ftp.execute(r);
                case "https","http":
                    HTTPRequest http;
                    return http.execute(r);
                default:
                    assert(0, "".format(r._uri.scheme));
            }
        }
    }
    Response post(string uri, string[string] query)
    {
        return execute("POST", uri, aa2params(query));
    }
    Response post(string uri, QueryParam[] query)
    {
        return execute("POST", uri, query);
    }
    Response post(string uri, MultipartForm form)
    {
        return execute("POST", uri, form);
    }
    Response post(R)(string uri, R content, string contentType="application/octet-stream")
    {
        return execute("POST", uri, content, contentType);
    }

    Response get(string uri, string[string] query)
    {
        return execute("GET", uri, aa2params(query));
    }
    Response get(string uri, QueryParam[] params = null)
    {
        return execute("GET", uri, params);
    }
    Response put(string uri, QueryParam[] query)
    {
        return execute("PUT", uri, query);
    }
    Response put(string uri, MultipartForm form)
    {
        return execute("PUT", uri, form);
    }
    Response put(R)(string uri, R content, string contentType="application/octet-stream")
    {
        return execute("PUT", uri, content, contentType);
    }
    Response patch(string uri, QueryParam[] query)
    {
        return execute("PATCH", uri, query);
    }
    Response patch(string uri, MultipartForm form)
    {
        return execute("PATCH", uri, form);
    }
    Response patch(R)(string uri, R content, string contentType="application/octet-stream")
    {
        return execute("PATCH", uri, content, contentType);
    }
    Response deleteRequest(string uri, string[string] query)
    {
        return execute("DELETE", uri, aa2params(query));
    }
    Response deleteRequest(string uri, QueryParam[] params = null)
    {
        return execute("DELETE", uri, params);
    }
    Response execute(R)(string method, string url, R content, string ct = "application/octet-stream") if (isInputRange!R)
    {
        _method = method;
        _uri = URI(url);
        _uri.idn_encode();
        _params = null;
        _multipartForm = MultipartForm.init;
        _contentType = ct;
        _postData = makeAdapter(content);
        // https://issues.dlang.org/show_bug.cgi?id=10535
        _permanent_redirects[URI.init] = ""; _permanent_redirects.remove(URI.init);
        //
        if ( _cm.refCountedStore().refCount() == 0)
        {
            _cm = RefCounted!ConnManager(10);
        }
        if ( _cookie.refCountedStore().refCount() == 0)
        {
            _cookie = RefCounted!Cookies(Cookies());
        }
        auto interceptors = _static_interceptors ~ _interceptors ~ new LastInterceptor();
        auto handler = new RequestHandler(interceptors);
        return handler.handle(this);
    }
    Response execute(string method, string url, MultipartForm form)
    {
        _method = method;
        _uri = URI(url);
        _uri.idn_encode();
        _params = null;
        _multipartForm = form;

        // https://issues.dlang.org/show_bug.cgi?id=10535
        _permanent_redirects[URI.init] = ""; _permanent_redirects.remove(URI.init);
        //

        if ( _cm.refCountedStore().refCount() == 0)
        {
            _cm = RefCounted!ConnManager(10);
        }
        if ( _cookie.refCountedStore().refCount() == 0)
        {
            _cookie = RefCounted!Cookies(Cookies());
        }
        auto interceptors = _static_interceptors ~ _interceptors ~ new LastInterceptor();
        auto handler = new RequestHandler(interceptors);
        return handler.handle(this);
    }
    Response execute(string method, string url, QueryParam[] params = null)
    {
        _method = method;
        _uri = URI(url);
        _uri.idn_encode();
        _multipartForm = MultipartForm.init;
        _params = params;

        // https://issues.dlang.org/show_bug.cgi?id=10535
        _permanent_redirects[URI.init] = ""; _permanent_redirects.remove(URI.init);
        //
        if ( _cm.refCountedStore().refCount() == 0)
        {
            _cm = RefCounted!ConnManager(10);
        }
        if ( _cookie.refCountedStore().refCount() == 0)
        {
            _cookie = RefCounted!Cookies(Cookies());
        }
        auto interceptors = _static_interceptors ~ _interceptors ~ new LastInterceptor();
        auto handler = new RequestHandler(interceptors);
        auto r = handler.handle(this);
        return r;
    }
}

unittest {
    info("testing Request");
    int interceptorCalls;

    class DummyInterceptor : Interceptor {
        Response opCall(Request r, RequestHandler next)
        {
            interceptorCalls++;
            auto rs = next.handle(r);
            return rs;
        }
    }
    globalLogLevel = LogLevel.info;
    Request rq;
    Response rs;
    rq.addInterceptor(new DummyInterceptor());

    rs = rq.execute("GET", "http://httpbin.org/");
    rq.useStreaming = true;
    rq.bufferSize = 128;
    rs = rq.execute("GET", "http://httpbin.org/");
    auto s = rs.receiveAsRange;
    while (!s.empty)
    {
        s.front;
        s.popFront();
    }
    assert(interceptorCalls == 2, "Expected interceptorCalls==2, got %d".format(interceptorCalls));

    // test global/static interceptors
    //
    // save and clear static_interceptors
    Interceptor[] saved_interceptors = _static_interceptors;
    scope(exit)
    {
        _static_interceptors = saved_interceptors;
    }
    _static_interceptors.length = 0;

    // add RqModifier to  static_interceptors
    class RqModifier : Interceptor {
        Response opCall(Request r, RequestHandler next)
        {
            r.path = "/get";
            r.method = "GET";
            auto rs = next.handle(r);
            return rs;
        }
    }
    addInterceptor(new RqModifier());
    // from now any request will pass through Pathmodifier without changing your code:
    rq = Request();
    rs = rq.get("http://httpbin.org/");
    assert(rs.uri.path == "/get", "Expected /get, but got %s".format(rs.uri.path));

    rs = rq.post("http://httpbin.org/post", "abc");
    assert(rs.code == 200);
    assert(rs.uri().path() == "/get");

    rs = rq.put("http://httpbin.org/put", "abc");
    assert(rs.code == 200);
    assert(rs.uri().path() == "/get");

    rs = rq.patch("http://httpbin.org/patch", "abc");
    assert(rs.code == 200);
    assert(rs.uri().path() == "/get");

    rs = rq.deleteRequest("http://httpbin.org/delete");
    assert(rs.uri.path == "/get", "Expected /get, but got %s".format(rs.uri.path));
}

struct _LineReader
{
    private
    {
        Request        _rq;
        ReceiveAsRange _stream;
        LineSplitter   _lineSplitter;
        ubyte[]        _data;
    }
    this(ref Request rq, ref Response rs)
    {
        _rq = rq;
        _stream = rs.receiveAsRange();
        _lineSplitter = new LineSplitter();
        while(_lineSplitter.empty && !_stream.empty)
        {
            auto d = _stream.front();
            _lineSplitter.putNoCopy(d);
            _stream.popFront();
        }
        if (_lineSplitter.empty && _stream.empty)
        {
            _lineSplitter.flush();
        }
        _data = _lineSplitter.get();
    }
    bool empty()
    {
        return _data.length == 0;
    }
    ubyte[] front()
    {
        return _data;
    }
    void popFront()
    {
        if (!_lineSplitter.empty)
        {
            _data = _lineSplitter.get();
            debug(requests) tracef("data1 = <<<%s>>>", cast(string)_data);
            return;
        }
        if ( _stream.empty )
        {
            _lineSplitter.flush();
            _data = _lineSplitter.get();
            debug(requests) tracef("data2 = <<<%s>>>", cast(string)_data);
            return;
        }
        while(_lineSplitter.empty && !_stream.empty)
        {
            auto d = _stream.front();
            _lineSplitter.putNoCopy(d);
            _stream.popFront();
        }
        _data = _lineSplitter.get();
        debug(requests) tracef("data3 = <<<%s>>>", cast(string)_data);
    }
}
