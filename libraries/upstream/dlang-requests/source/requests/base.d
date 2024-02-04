module requests.base;

import requests.streams;
import requests.utils;
import requests.uri;
import requests.connmanager;

import std.format;
import std.datetime;
import core.time;
import std.stdio;
import std.algorithm;
import std.string;
import std.exception;
import std.bitmanip;
import std.conv;
import std.typecons;

/++ 
    Interface to provide user info and http headers requred for server auth.
+/
public interface Auth {
    string[string] authHeaders(string domain); /// Create headers for authentication
    string         userName();                 /// Returns user name
    string         password();                 /// Returns user password
}
/**
 * Basic authentication.
 * Adds $(B Authorization: Basic) header to request
 * Example:
 * ---
 * import requests;
 * void main() {
 * rq = Request();
 * rq.authenticator = new BasicAuthentication("user", "passwd");
 * rs = rq.get("http://httpbin.org/basic-auth/user/passwd");
 * }
 * ---
*/
public class BasicAuthentication: Auth {
    private {
        string   _username, _password;
        string[] _domains;
    }
    /// Constructor.
    /// Params:
    /// username = username
    /// password = password
    /// domains = not used now
    ///
    this(string username, string password, string[] domains = []) {
        _username = username;
        _password = password;
        _domains = domains;
    }
    /// create Basic Auth header
    override string[string] authHeaders(string domain) {
        import std.base64;
        string[string] auth;
        auth["Authorization"] = "Basic " ~ to!string(Base64.encode(cast(ubyte[])"%s:%s".format(_username, _password)));
        return auth;
    }
    /// returns username
    override string userName() {
        return _username;
    }
    /// return user password
    override string password() {
        return _password;
    }
}

/**
 * Struct to send multiple files in POST request.
 */
public struct PostFile {
    /// Path to the file to send.
    string fileName;
    /// Name of the field (if empty - send file base name)
    string fieldName;
    /// contentType of the file if not empty
    string contentType;
}
///
/// This is File-like interface for sending data to multipart forms
///
public interface FiniteReadable {
    /// size of the content
    abstract ulong  getSize();
    /// file-like read()
    abstract ubyte[] read();
}
///
/// Helper to create form elements from File.
/// Params:
/// name = name of the field in form
/// f = opened std.stio.File to send to server
/// parameters = optional parameters (most important are "filename" and "Content-Type")
///
public auto formData(string name, File f, string[string] parameters = null) {
    return MultipartForm.FormData(name, new FormDataFile(f), parameters);
}
///
/// Helper to create form elements from ubyte[].
/// Params:
/// name = name of the field in form
/// b = data to send to server
/// parameters = optional parameters (can be "filename" and "Content-Type")
///
public auto formData(string name, ubyte[] b, string[string] parameters = null) {
    return MultipartForm.FormData(name, new FormDataBytes(b), parameters);
}
public auto formData(string name, string b, string[string] parameters = null) {
    return MultipartForm.FormData(name, new FormDataBytes(b.dup.representation), parameters);
}

private immutable uint defaultBufferSize = 12*1024;
/// Class to provide FiniteReadable from user-provided ubyte[]
public class FormDataBytes : FiniteReadable {
    private {
        ulong   _size;
        ubyte[] _data;
        size_t  _offset;
        bool    _exhausted;
    }
    /// constructor from ubyte[]
    this(ubyte[] data) {
        _data = data;
        _size = data.length;
    }
    final override ulong getSize() {
        return _size;
    }
    final override ubyte[] read() {
        enforce( !_exhausted, "You can't read froum exhausted source" );
        size_t toRead = min(defaultBufferSize, _size - _offset);
        auto result = _data[_offset.._offset+toRead];
        _offset += toRead;
        if ( toRead == 0 ) {
            _exhausted = true;
        }
        return result;
    }
}
/// Class to provide FiniteReadable from File
public class FormDataFile : FiniteReadable {
    import  std.file;
    private {
        File    _fileHandle;
        ulong   _fileSize;
        size_t  _processed;
        bool    _exhausted;
    }
    /// constructor from File object
    this(File file) {
        import std.file;
        _fileHandle = file;
        _fileSize = std.file.getSize(file.name);
    }
    final override ulong getSize() pure nothrow @safe {
        return _fileSize;
    }
    final override ubyte[] read() {
        enforce( !_exhausted, "You can't read froum exhausted source" );
        auto b = new ubyte[defaultBufferSize];
        auto r = _fileHandle.rawRead(b);
        auto toRead = min(r.length, _fileSize - _processed);
        if ( toRead == 0 ) {
            _exhausted = true;
        }
        _processed += toRead;
        return r[0..toRead];
    }
}
///
/// This struct used to bulld POST's to forms.
/// Each part have name and data. data is something that can be read-ed and have size.
/// For example this can be string-like object (wrapped for reading) or opened File.
///
public struct MultipartForm {
    package struct FormData {
        FiniteReadable  input;
        string          name;
        string[string]  parameters;
        this(string name, FiniteReadable i, string[string] parameters = null) {
            this.input = i;
            this.name = name;
            this.parameters = parameters;
        }
    }

    package FormData[] _sources;
    auto add(FormData d) {
        _sources ~= d;
        return this;
    }
    auto add(string name, FiniteReadable i, string[string]parameters = null) {
        _sources ~= FormData(name, i, parameters);
        return this;
    }
    bool empty() const
    {
        return _sources.length == 0;
    }
}
///

/// General type exception from Request
public class RequestException: Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow {
        super(msg, file, line, next);
    }
}

/**
    ReceiveAsRange is InputRange used to supply client with data from response.
    Each popFront fetch next data portion.
*/
public struct ReceiveAsRange {
    bool empty() {
        return data.length == 0;
    }
    ubyte[] front() {
        return data;
    }
    void popFront() {
        if ( read ) {
            // get new portion
            data = read();
        } else {
            // we can't read any new data
            data.length = 0;
        }
    }
    package {
        bool                    activated;
        ubyte[]                 data;
        /// HTTP or FTP module set up delegate read() for reading next portion of data.
        ubyte[]                 delegate() read;
        RefCounted!ConnManager  cm;
    }
}

/**
    Response
*/
public class Response {
    package {
        /// Server status code
        ushort           _code;
        /// Response body
        Buffer!ubyte     _responseBody;
        /// Response headers
        string[string]   _responseHeaders;
        /// Initial URI
        URI              _uri;
        /// Final URI. Can differ from uri() if request go through redirections.
        URI              _finalURI;
        /// stream range stored here
        ReceiveAsRange   _receiveAsRange;
        SysTime          _startedAt,
                         _connectedAt,
                         _requestSentAt,
                         _finishedAt;
        /// Length of received content
        long             _contentReceived;
        /// Server-supplied content length (can be -1 when unknown)
        long             _contentLength = -1;
        mixin(Setter!ushort("code"));
        mixin(Setter!URI("uri"));
        mixin(Setter!URI("finalURI"));
    }
    mixin(Getter("code"));
    mixin(Getter("contentReceived"));
    mixin(Getter("contentLength"));
    mixin(Getter("uri"));
    mixin(Getter("finalURI"));

    @property auto getStats() const pure @safe {
        import std.typecons: Tuple;
        alias statTuple = Tuple!(Duration, "connectTime",
            Duration, "sendTime",
            Duration, "recvTime");
        statTuple stat;
        stat.connectTime = _connectedAt - _startedAt;
        stat.sendTime = _requestSentAt - _connectedAt;
        stat.recvTime = _finishedAt - _requestSentAt;
        return stat;
    }
    @property auto ref responseBody() @safe nothrow {
        return _responseBody;
    }
    @property auto ref responseHeaders() pure @safe nothrow {
        return _responseHeaders;
    }
    @property auto ref receiveAsRange() pure @safe nothrow {
        return _receiveAsRange;
    }
    /// string representation of response
    override string toString() const {
        return "Response(%d, %s)".format(_code, _finalURI.uri());
    }
    /// format response to string (hpPqsBTUS).
    /**

        %h - remote hostname

        %p - remote port

        %P - remote path

        %q - query parameters

        %s - string representation

        %B - received bytes

        %T - resquest total time

        %U - request uri()

        %S - status code
    */
    string format(string fmt) const {
        import std.array;
        auto a = appender!string();
        auto f = FormatSpec!char(fmt);
        while (f.writeUpToNextSpec(a)) {
            switch (f.spec) {
                case 'h':
                    // Remote hostname.
                    a.put(_uri.host);
                    break;
                case 'p':
                    // Remote port.
                    a.put("%d".format(_uri.port));
                    break;
                case 'P':
                    // Path.
                    a.put(_uri.path);
                    break;
                case 'q':
                    // query parameters supplied with url.
                    a.put(_uri.query);
                    break;
                case 's':
                    a.put("Response(%d, %s)".format(_code, _finalURI.uri()));
                    break;
                case 'B': // received bytes
                    a.put("%d".format(_responseBody.length));
                    break;
                case 'T': // request total time, ms
                    a.put("%d".format((_finishedAt - _startedAt).total!"msecs"));
                    break;
                case 'U':
                    a.put(_uri.uri());
                    break;
                case 'S':
                    a.put("%d".format(_code));
                    break;
                default:
                    throw new FormatException("Unknown Response format specifier: %" ~ f.spec);
            }
        }
        return a.data();
    }
}

struct _UH {
    // flags for each important header, added by user using addHeaders
    mixin(bitfields!(
    bool, "Host", 1,
    bool, "UserAgent", 1,
    bool, "ContentLength", 1,
    bool, "Connection", 1,
    bool, "AcceptEncoding", 1,
    bool, "ContentType", 1,
    bool, "Cookie", 1,
    uint, "", 1
    ));
}

