/**********************************************************************************

HTTP client library, inspired by python-requests with goals:

 $(UL
   $(LI small memory footprint)
   $(LI performance)
   $(LI simple, high level API)
   $(LI native D implementation)
 )
*/
module requests;

public import requests.http;
public import requests.ftp;
public import requests.streams;
public import requests.base;
public import requests.uri;
public import requests.request;
public import requests.pool;
public import requests.utils;
public import requests.rangeadapter;

import std.datetime;
import std.conv;
import std.experimental.logger;
import requests.utils;

///
package unittest {
    import std.algorithm;
    import std.range;
    import std.array;
    import std.json;
    import std.stdio;
    import std.string;
    import std.exception;

    string httpbinUrl = httpTestServer();
    globalLogLevel(LogLevel.info);

    version(vibeD) {
    }
    else {
        import httpbin;
        auto server = httpbinApp();
        server.start();
        scope(exit) {
            server.stop();
        }
    }


    infof("testing Request");
    Request rq;
    Response rs;
    // moved from http.d

    URI uri = URI(httpbinUrl);
    rs = rq.get(httpbinUrl);
    assert(rs.code==200);
    assert(rs.responseBody.length > 0);
    assert(rq.format("%m|%h|%p|%P|%q|%U") ==
    "GET|%s|%d|%s||%s"
    .format(uri.host, uri.port, uri.path, httpbinUrl));

    //
    rs = rq.get(httpbinUrl);
    assert(rs.code==200);
    assert(rs.responseBody.length > 0);
    rs = rq.get(httpbinUrl ~ "get", ["c":" d", "a":"b"]);
    assert(rs.code == 200);
    auto json = parseJSON(cast(string)rs.responseBody.data).object["args"].object;
    assert(json["c"].str == " d");
    assert(json["a"].str == "b");

    
    rq = Request();
    rq.keepAlive = false; // disable keepalive on idempotents requests
    {
        info("Check handling incomplete status line");
        rs = rq.get(httpbinUrl ~ "incomplete");
        if (httpbinUrl != "http://httpbin.org/") {
            // 600 when test direct server respond, or 502 if test through squid
            assert(rs.code==600 || rs.code == 502);
        }
    }
    // handmade json
    info("Check POST json");
    rs = rq.post(httpbinUrl ~ "post?b=x", `{"a":"b ", "c":[1,2,3]}`, "application/json");
    assert(rs.code==200);
    json = parseJSON(cast(string)rs.responseBody.data).object["args"].object;
    assert(json["b"].str == "x");
    json = parseJSON(cast(string)rs.responseBody.data).object["json"].object;
    assert(json["a"].str == "b ");
    assert(json["c"].array.map!(a=>a.integer).array == [1,2,3]);
    {
        import std.file;
        import std.path;
        auto tmpd = tempDir();
        auto tmpfname = tmpd ~ dirSeparator ~ "request_test.txt";
        auto f = File(tmpfname, "wb");
        f.rawWrite("abcdefgh\n12345678\n");
        f.close();
        // files
        info("Check POST files");
        PostFile[] files = [
            {fileName: tmpfname, fieldName:"abc", contentType:"application/octet-stream"}, 
            {fileName: tmpfname}
        ];
        rs = rq.post(httpbinUrl ~ "post", files);
        assert(rs.code==200);
        info("Check POST chunked from file.byChunk");
        f = File(tmpfname, "rb");
        rs = rq.post(httpbinUrl ~ "post", f.byChunk(3), "application/octet-stream");
        if (httpbinUrl != "http://httpbin.org/" ) {
            assert(rs.code==200);
            auto data = fromJsonArrayToStr(parseJSON(cast(string)rs.responseBody).object["data"]);
            assert(data=="abcdefgh\n12345678\n");
        }
        f.close();
    }
    // ranges
    {
        info("Check POST chunked from lineSplitter");
        auto s = lineSplitter("one,\ntwo,\nthree.");
        rs = rq.exec!"POST"(httpbinUrl ~ "post", s, "application/octet-stream");
        if (httpbinUrl != "http://httpbin.org/" ) {
            assert(rs.code==200);
            auto data = fromJsonArrayToStr(parseJSON(cast(string)rs.responseBody).object["data"]);
            assert(data=="one,two,three.");
        }
    }
    {
        info("Check POST chunked from array");
        auto s = ["one,", "two,", "three."];
        rs = rq.post(httpbinUrl ~ "post", s, "application/octet-stream");
        if (httpbinUrl != "http://httpbin.org/" ) {
            assert(rs.code==200);
            auto data = fromJsonArrayToStr(parseJSON(cast(string)rs.responseBody).object["data"]);
            assert(data=="one,two,three.");
        }
    }
    {
        info("Check POST chunked using std.range.chunks()");
        auto s = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        rs = rq.post(httpbinUrl ~ "post", s.representation.chunks(10), "application/octet-stream");
        if (httpbinUrl != "http://httpbin.org/") {
            assert(rs.code==200);
            auto data = fromJsonArrayToStr(parseJSON(cast(string)rs.responseBody).object["data"]);
            assert(data==s);
        }
    }
    info("Check POST from QueryParams");
    {
        rs = rq.post(httpbinUrl ~ "post", queryParams("name[]", "first", "name[]", 2));
        assert(rs.code==200);
        auto data = parseJSON(cast(string)rs.responseBody).object["form"].object;
        string[] a;
        try {
            a = to!(string[])(data["name[]"].str);
        }
        catch (JSONException e) {
            a = data["name[]"].array.map!"a.str".array;
        }
        assert(equal(["first", "2"], a));
    }
    info("Check POST json");
    {
        rs = rq.post(httpbinUrl ~ "post?b=x", `{"a":"a b", "c":[1,2,3]}`, "application/json");
        assert(rs.code==200);
        auto j = parseJSON(cast(string)rs.responseBody).object["args"].object;
        assert(j["b"].str == "x");
        j = parseJSON(cast(string)rs.responseBody).object["json"].object;
        assert(j["a"].str == "a b");
        assert(j["c"].array.map!(a=>a.integer).array == [1,2,3]);
    }
    // associative array
    info("Check POST from AA");
    rs = rq.post(httpbinUrl ~ "post", ["a":"b ", "c":"d"]);
    assert(rs.code==200);
    auto form = parseJSON(cast(string)rs.responseBody.data).object["form"].object;
    assert(form["a"].str == "b ");
    assert(form["c"].str == "d");
    info("Check HEAD");
    rs = rq.exec!"HEAD"(httpbinUrl);
    assert(rs.code==200);
    rs = rq.execute("HEAD", httpbinUrl);
    assert(rs.code==200);
    info("Check DELETE");
    rs = rq.exec!"DELETE"(httpbinUrl ~ "delete");
    assert(rs.code==200);
    rs = rq.execute("DELETE", httpbinUrl ~ "delete");
    assert(rs.code==200);
    info("Check PUT");
    rs = rq.exec!"PUT"(httpbinUrl ~ "put",  `{"a":"b", "c":[1,2,3]}`, "application/json");
    assert(rs.code==200);
    rs = rq.execute("PUT", httpbinUrl ~ "put",  `{"a":"b", "c":[1,2,3]}`, "application/json");
    assert(rs.code==200);
    info("Check PATCH");
    rs = rq.exec!"PATCH"(httpbinUrl ~ "patch", "привiт, свiт!", "application/octet-stream");
    assert(rs.code==200);
    rs = rq.execute("PATCH", httpbinUrl ~ "patch", "привiт, свiт!", "application/octet-stream");
    assert(rs.code==200);

    info("Check compressed content");
    rq = Request();
    rq.keepAlive = true;
    rq.addHeaders(["X-Header": "test"]);
    rs = rq.get(httpbinUrl ~ "gzip");
    assert(rs.code==200);
    info("gzip - ok");
    rs = rq.get(httpbinUrl ~ "deflate");
    assert(rs.code==200);
    info("deflate - ok");
    
    info("Check cookie");
    rq = Request();
    rs = rq.get(httpbinUrl ~ "cookies/set?A=abcd&b=cdef");
    assert(rs.code == 200);
    json = parseJSON(cast(string)rs.responseBody.data).object["cookies"].object;
    assert(json["A"].str == "abcd");
    assert(json["b"].str == "cdef");
    foreach(c; rq.cookie._array) {
        final switch(c.attr) {
            case "A":
                assert(c.value == "abcd");
                break;
            case "b":
                assert(c.value == "cdef");
                break;
        }
    }

    info("Check redirects");
    rq = Request();
    rq.keepAlive = true;
    rs = rq.get(httpbinUrl ~ "relative-redirect/2");
    assert((cast(HTTPResponse)rs).history.length == 2);
    assert((cast(HTTPResponse)rs).code==200);

    rs = rq.get(httpbinUrl ~ "absolute-redirect/2");
    assert((cast(HTTPResponse)rs).history.length == 2);
    assert((cast(HTTPResponse)rs).code==200);
    //    rq = Request();
    info("Check maxredirects");
    rq.maxRedirects = 2;
    rq.keepAlive = false;
    assertThrown!MaxRedirectsException(rq.get(httpbinUrl ~ "absolute-redirect/3"));

    rq.maxRedirects = 0;
    rs = rq.get(httpbinUrl ~ "absolute-redirect/1");
    assert(rs.code==302);
    rq.maxRedirects = 10;

    info("Check chunked content");
    rq = Request();
    rq.keepAlive = true;
    rq.bufferSize = 16*1024;
    rs = rq.get(httpbinUrl ~ "range/1024");
    assert(rs.code==200);
    assert(rs.responseBody.length==1024);
    
    info("Check basic auth");
    rq = Request();
    rq.authenticator = new BasicAuthentication("user", "passwd");
    rs = rq.get(httpbinUrl ~ "basic-auth/user/passwd");
    assert(rs.code==200);
    
    info("Check limits");
    rq = Request();
    rq.maxContentLength = 1;
    assertThrown!RequestException(rq.get(httpbinUrl));
    rq = Request();
    rq.maxHeadersLength = 1;
    assertThrown!RequestException(rq.get(httpbinUrl));

    info("Test getContent");
    auto r = getContent(httpbinUrl ~ "stream/20");
    assert(r.splitter('\n').filter!("a.length>0").count == 20);
    r = getContent(httpbinUrl ~ "get", ["a":"b", "c":"d"]);
    string name = "user", sex = "male";
    immutable age = 42;
    r = getContent(httpbinUrl ~ "get", "name", name, "age", age, "sex", sex);

    info("Test receiveAsRange with GET");
    rq = Request();
    rq.useStreaming = true;
    rq.bufferSize = 16;
    rs = rq.get(httpbinUrl ~ "stream/20");
    auto stream = rs.receiveAsRange();
    ubyte[] streamedContent;
    while( !stream.empty() ) {
        streamedContent ~= stream.front;
        stream.popFront();
    }
    rq = Request();
    rs = rq.get(httpbinUrl ~ "stream/20");
    assert(streamedContent.length == rs.responseBody.data.length,
            "streamedContent.length(%d) == rs.responseBody.data.length(%d)".
            format(streamedContent.length, rs.responseBody.data.length));
    info("Test postContent");
    r = postContent(httpbinUrl ~ "post", `{"a":"b", "c":1}`, "application/json");
    assert(parseJSON(cast(string)r).object["json"].object["c"].integer == 1);

    /// Posting to forms (for small data)
    ///
    /// posting query parameters using "application/x-www-form-urlencoded"
    info("Test postContent using query params");
    r = postContent(httpbinUrl ~ "post", queryParams("first", "a", "second", 2));
    assert(parseJSON(cast(string)r).object["form"].object["first"].str == "a");
    
    /// posting using multipart/form-data (large data and files). See docs fot HTTPRequest
    info("Test postContent form");
    MultipartForm mpform;
    mpform.add(formData(/* field name */ "greeting", /* content */ cast(ubyte[])"hello"));
    r = postContent(httpbinUrl ~ "post", mpform);
    assert(parseJSON(cast(string)r).object["form"].object["greeting"].str == "hello");
    
    /// you can do this using Request struct to access response details
    info("Test postContent form via Request()");
    rq = Request();
    mpform = MultipartForm().add(formData(/* field name */ "greeting", /* content */ cast(ubyte[])"hello"));
    rs = rq.post(httpbinUrl ~ "post", mpform);
    assert(rs.code == 200);
    assert(parseJSON(cast(string)(rs.responseBody().data)).object["form"].object["greeting"].str == "hello");

    info("Test receiveAsRange with POST");
    streamedContent.length = 0;
    rq = Request();
    rq.useStreaming = true;
    rq.bufferSize = 16;
    string s = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    rs = rq.post(httpbinUrl ~ "post", s.representation, "application/octet-stream");
    stream = rs.receiveAsRange();
    while( !stream.empty() ) {
        streamedContent ~= stream.front;
        stream.popFront();
    }
    rq = Request();
    rs = rq.post(httpbinUrl ~ "post", s.representation, "application/octet-stream");
    assert(streamedContent == rs.responseBody.data);

    streamedContent.length = 0;
    rq = Request();
    rq.useStreaming = true;
    rq.bufferSize = 16;
    mpform = MultipartForm().add(formData(/* field name */ "greeting", /* content */ cast(ubyte[])"hello"));
    rs = rq.post(httpbinUrl ~ "post", mpform);
    stream = rs.receiveAsRange();
    while( !stream.empty() ) {
        streamedContent ~= stream.front;
        stream.popFront();
    }
    info("Check POST files using multiPartForm");
    {
        /// This is example on usage files with MultipartForm data.
        /// For this example we have to create files which will be sent.
        import std.file;
        import std.path;
        /// preapare files
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
        MultipartForm mForm = MultipartForm().
        add(formData("Field1", cast(ubyte[])"form field from memory")).
        add(formData("Field2", cast(ubyte[])"file field from memory", ["filename":"data2"])).
        add(formData("File1", f1, ["filename":"file1", "Content-Type": "application/octet-stream"])).
        add(formData("File2", f2, ["filename":"file2", "Content-Type": "application/octet-stream"]));
        /// everything ready, send request
        rs = rq.post(httpbinUrl ~ "post", mForm);
    }

    rq = Request();
    mpform = MultipartForm().add(formData(/* field name */ "greeting", /* content */ cast(ubyte[])"hello"));
    rs = rq.post(httpbinUrl ~ "post", mpform);
    assert(parseJSON(cast(string)(rs.responseBody().data)).object["form"].object["greeting"].str ==
           parseJSON(cast(string)streamedContent).object["form"].object["greeting"].str);


    info("Test POST'ing from Rank(2) range with user-provided Content-Length");
    rq.addHeaders(["content-length": to!string(s.length)]);
    rs = rq.post(httpbinUrl ~ "post", s.representation.chunks(10), "application/octet-stream");
    auto flat_content = parseJSON(cast(string)rs.responseBody().data).object["data"];
    if ( flat_content.type == JSONType.string ) {
        // httpbin.org returns string in "data"
        assert(s == flat_content.str);
    } else {
        // internal httpbin server return array ob bytes
        assert(s.representation == flat_content.array.map!(i => i.integer).array);
    }

    /// Putting to forms (for small data)
    ///
    /// putting query parameters using "application/x-www-form-urlencoded"
    info("Test putContent using query params");
    r = putContent(httpbinUrl ~ "put", queryParams("first", "a", "second", 2));
    assert(parseJSON(cast(string)r).object["form"].object["first"].str == "a");
    
    /// putting using multipart/form-data (large data and files). See docs fot HTTPRequest
    info("Test putContent form");
    mpform = MultipartForm();
    mpform.add(formData(/* field name */ "greeting", /* content */ cast(ubyte[])"hello"));
    r = putContent(httpbinUrl ~ "put", mpform);
    assert(parseJSON(cast(string)r).object["form"].object["greeting"].str == "hello");

    /// Patching to forms (for small data)
    ///
    /// patching query parameters using "application/x-www-form-urlencoded"
    info("Test patchContent using query params");
    r = patchContent(httpbinUrl ~ "patch", queryParams("first", "a", "second", 2));
    assert(parseJSON(cast(string)r).object["form"].object["first"].str == "a");
    
    /// patching using multipart/form-data (large data and files). See docs fot HTTPRequest
    info("Test patchContent form");
    mpform = MultipartForm();
    mpform.add(formData(/* field name */ "greeting", /* content */ cast(ubyte[])"hello"));
    r = patchContent(httpbinUrl ~ "patch", mpform);
    assert(parseJSON(cast(string)r).object["form"].object["greeting"].str == "hello");

    info("Check exception handling, error messages and timeouts are OK");
    rq.clearHeaders();
    rq.timeout = 1.seconds;
    assertThrown!TimeoutException(rq.get(httpbinUrl ~ "delay/3"));

    info("Test ByLine interfaces");
    auto rsp = getContentByLine(httpbinUrl ~ "stream/50");
    assert(rsp.count == 50);
    rsp = getContentByLine(httpbinUrl ~ "stream/0");
    assert(rsp.count == 0);
    rsp = getContentByLine(httpbinUrl ~ "anything", ["1":"1"]);
    assert(rsp.map!"cast(string)a".filter!(a => a.canFind("data")).count == 1);
    rsp = getContentByLine(httpbinUrl ~ "anything", queryParams("1","1"));
    assert(rsp.map!"cast(string)a".filter!(a => a.canFind("data")).count == 1);
    rsp = postContentByLine(httpbinUrl ~ "anything", "123");
    assert(rsp.map!"cast(string)a".filter!(a => a.canFind("data")).count == 1);
    rsp = putContentByLine(httpbinUrl ~ "anything", "123");
    assert(rsp.map!"cast(string)a".filter!(a => a.canFind("data")).count == 1);


    info("Test get in parallel");
    {
        import std.stdio;
        import std.parallelism;
        import std.algorithm;
        import std.string;
        import core.atomic;
        
        immutable auto urls = [
            "stream/10",
            "stream/20",
            "stream/30",
            "stream/40",
            "stream/50",
            "stream/60",
            "stream/70",
        ].map!(a => httpbinUrl ~ a).array.idup;
        
        defaultPoolThreads(4);
        
        shared short lines;
        
        foreach(url; parallel(urls)) {
            atomicOp!"+="(lines, getContent(url).splitter("\n").count);
        }
        assert(lines == 287);
        
    }
}
/**
 * Call GET, and return response content.
 *
 * This is the simplest case, when all you need is the response body and have no parameters.
 * Returns:
 * Buffer!ubyte which you can use as ForwardRange or DirectAccessRange, or extract data with .data() method.
 */
public auto ref getContent(string url) {
    auto rq = Request();
    auto rs = rq.get(url);
    return rs.responseBody;
}
/**
  Call GET and lazily convert server response into InputRange of ubyte[], splitted by '\n'.
 */
public auto getContentByLine(string url)
{
    auto rq = Request();
    rq.useStreaming = true;
    auto rs = rq.get(url);
    _LineReader lr = _LineReader(rq, rs);
    return lr;
}
/**
 * Call GET, with parameters, and return response content.
 *
 * args = string[string] fo query parameters.
 * Returns:
 * Buffer!ubyte which you can use as ForwardRange or DirectAccessRange, or extract data with .data() method.
 */
public auto ref getContent(string url, string[string] args) {
    auto rq = Request();
    auto rs = rq.get(url, args);
    return rs.responseBody;
}
/**
  Call GET and lazily convert server response into InputRange of ubyte[], splitted by '\n'.
 */
public auto getContentByLine(string url, string[string] args)
{
    auto rq = Request();
    rq.useStreaming = true;
    auto rs = rq.get(url, args);
    _LineReader lr = _LineReader(rq, rs);
    return lr;
}
/**
 * Call GET, with parameters, and return response content.
 * 
 * args = QueryParam[] of parameters.
 * Returns:
 * Buffer!ubyte which you can use as ForwardRange or DirectAccessRange, or extract data with .data() method.
 */
public auto ref getContent(string url, QueryParam[] args) {
    auto rq = Request();
    auto rs = rq.get(url, args);
    return rs.responseBody;
}
/**
  Call GET and lazily convert server response into InputRange of ubyte[], splitted by '\n'.
 */
public auto getContentByLine(string url, QueryParam[] args)
{
    auto rq = Request();
    rq.useStreaming = true;
    auto rs = rq.get(url, args);
    _LineReader lr = _LineReader(rq, rs);
    return lr;
}
/**
 * Call GET, and return response content.
 * args = variadic args to supply parameter names and values.
 * Returns:
 * Buffer!ubyte which you can use as ForwardRange or DirectAccessRange, or extract data with .data() method.
 */
public auto ref getContent(A...)(string url, A args) if (args.length > 1 && args.length % 2 == 0 ) {
    return Request().
            get(url, queryParams(args)).
            responseBody;
}
/**
  Call GET and lazily convert server response into InputRange of ubyte[], splitted by '\n'.
 */
public auto getContentByLine(A...)(string url, A args) if (args.length > 1 && args.length % 2 == 0 )
{
    auto rq = Request();
    rq.useStreaming = true;
    auto rs = rq.get(url, queryParams(args));
    _LineReader lr = _LineReader(rq, rs);
    return lr;
}
///
/// Call post and return response content.
///
public auto postContent(A...)(string url, A args) {
    auto rq = Request();
    auto rs = rq.post(url, args);
    return rs.responseBody;
}
/**
  Call POST and lazily convert server response into InputRange of ubyte[], splitted by '\n'.
 */
public auto postContentByLine(A...)(string url, A args)
{
    auto rq = Request();
    rq.useStreaming = true;
    auto rs = rq.post(url, args);
    _LineReader lr = _LineReader(rq, rs);
    return lr;
}

///
/// Call put and return response content.
///
public auto putContent(A...)(string url, A args) {
    auto rq = Request();
    auto rs = rq.put(url, args);
    return rs.responseBody;
}
/**
  Call PUT and lazily convert server response into InputRange of ubyte[], splitted by '\n'.
 */
public auto putContentByLine(A...)(string url, A args)
{
    auto rq = Request();
    rq.useStreaming = true;
    auto rs = rq.put(url, args);
    _LineReader lr = _LineReader(rq, rs);
    return lr;
}

///
/// Call patch and return response content.
///
public auto patchContent(A...)(string url, A args) {
    auto rq = Request();
    auto rs = rq.patch(url, args);
    return rs.responseBody;
}