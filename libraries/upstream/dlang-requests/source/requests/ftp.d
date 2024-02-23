module requests.ftp;

private:
import std.ascii;
import std.algorithm;
import std.conv;
import std.datetime;
import std.format;
import std.exception;
import std.string;
import std.range;
import std.experimental.logger;
import std.stdio;
import std.path;
import std.traits;
import std.typecons;

import requests.uri;
import requests.utils;
import requests.streams;
import requests.base;
import requests.request;
import requests.connmanager;
import requests.rangeadapter;

public class FTPServerResponseError: Exception {
    this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow {
        super(message, file, line, next);
    }
}

public class FTPResponse : Response {
}

public class FtpAuthentication: Auth {
    private {
        string   _username, _password;
    }
    /// Constructor.
    /// Params:
    /// username = username
    /// password = password
    ///
    this(string username, string password) {
        _username = username;
        _password = password;
    }
    override string userName() {
        return _username;
    }
    override string password() {
        return _password;
    }
    override string[string] authHeaders(string domain) {
        return null;
    }
}

enum defaultBufferSize = 8192;

public struct FTPRequest {
    private {
        URI           _uri;
        Duration      _timeout = 60.seconds;
        uint          _verbosity = 0;
        size_t        _bufferSize = defaultBufferSize;
        long          _maxContentLength = 5*1024*1024*1024;
        long          _contentLength = -1;
        long          _contentReceived;
        NetworkStream _controlChannel;
        string[]      _responseHistory;
        FTPResponse   _response;
        bool          _useStreaming;
        Auth           _authenticator;
        string        _method;
        string        _proxy;
        string        _bind;
        RefCounted!ConnManager      _cm;
        InputRangeAdapter           _postData;
    }
    mixin(Getter_Setter!Duration("timeout"));
    mixin(Getter_Setter!uint("verbosity"));
    mixin(Getter_Setter!size_t("bufferSize"));
    mixin(Getter_Setter!long("maxContentLength"));
    mixin(Getter_Setter!bool("useStreaming"));
    mixin(Getter("contentLength"));
    mixin(Getter("contentReceived"));
    mixin(Setter!Auth("authenticator"));
    mixin(Getter_Setter!string("proxy"));
    mixin(Getter_Setter!string("bind"));

    @property final string[] responseHistory() @safe @nogc nothrow {
        return _responseHistory;
    }
    this(string uri) {
        _uri = URI(uri);
    }

    this(in URI uri) {
        _uri = uri;
    }

    ~this() {
        //if ( _controlChannel ) {
        //    _controlChannel.close();
        //}
    }
    string toString() const {
        return "FTPRequest(%s, %s)".format(_method, _uri.uri());
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
    ushort sendCmdGetResponse(string cmd, NetworkStream __controlChannel) {
        debug(requests) tracef("cmd to server: %s", cmd.strip);
        if ( _verbosity >=1 ) {
            writefln("> %s", cmd.strip);
        }
        __controlChannel.send(cmd);
        string response = serverResponse(__controlChannel);
        _responseHistory ~= response;
        return responseToCode(response);
    }

    ushort responseToCode(string response) pure const @safe {
        return to!ushort(response[0..3]);
    }

    void handleChangeURI(in string uri) @safe {
        // if control channel exists and new URL not match old, then close
        URI newURI = URI(uri);
        if ( _controlChannel && 
            (newURI.host != _uri.host || newURI.port != _uri.port || newURI.username != _uri.username)) {
            _controlChannel.close();
            _controlChannel = null;
        }
        _uri = newURI;
    }

    string serverResponse(NetworkStream __controlChannel) {
        string res, buffer;
        immutable bufferLimit = 16*1024;
        __controlChannel.readTimeout = _timeout;
        scope(exit) {
            __controlChannel.readTimeout = 0.seconds;
        }
        debug(requests) trace("Wait on control channel");
        auto b = new ubyte[1];
        while ( __controlChannel && __controlChannel.isConnected && buffer.length < bufferLimit ) {
            ptrdiff_t rc;
            try {
                rc = __controlChannel.receive(b);
            }
            catch (Exception e) {
                error("Failed to read response from server");
                throw new FTPServerResponseError("Failed to read server responce over control channel", __FILE__, __LINE__, e);
            }
            //debug(requests) tracef("Got %d bytes from control socket", rc);
            if ( rc == 0 ) {
                error("Failed to read response from server");
                throw new FTPServerResponseError("Failed to read server responce over control channel", __FILE__, __LINE__);
            }
            buffer ~= b[0..rc];
            if ( buffer.endsWith('\n') ){
                if ( _verbosity >= 1 ) {
                    buffer.
                    splitLines.
                    each!(l=>writefln("< %s", l));
                }
                auto responseLines = buffer.
                    splitLines.
                    filter!(l => l.length>3 && l[3]==' ' && l[0..3].all!isDigit);
                if ( responseLines.count > 0 ) {
                    return responseLines.front;
                }
            }
        }
        throw new FTPServerResponseError("Failed to read server responce over control channel");
        assert(0);
    }
    ushort tryCdOrCreatePath(string[] path) {
        /*
         * At start we stay at original path, we have to create next path element
         * For example:
         * path = ["", "a", "b"] - we stay in root (path[0]), we have to cd and return ok
         * or try to cteate "a" and cd to "a".
         */
        debug(requests) info("Trying to create path %s".format(path));
        enforce(path.length>=2, "You called tryCdOrCreate, but there is nothing to create: %s".format(path));
        auto next_dir = path[1];
        auto code = sendCmdGetResponse("CWD " ~ next_dir ~ "\r\n", _controlChannel);
        if ( code >= 300) {
            // try to create, then again CWD
            code = sendCmdGetResponse("MKD " ~ next_dir ~ "\r\n", _controlChannel);
            if ( code > 300 ) {
                return code;
            }
            code = sendCmdGetResponse("CWD " ~ next_dir ~ "\r\n", _controlChannel);
        }
        if ( path.length == 2 ) {
            return code;
        }
        return tryCdOrCreatePath(path[1..$]);
    }

    FTPResponse post(R, A...)(string uri, R content, A args) 
        if ( __traits(compiles, cast(ubyte[])content) 
        || (rank!R == 2 && isSomeChar!(Unqual!(typeof(content.front.front)))) 
        || (rank!R == 2 && (is(Unqual!(typeof(content.front.front)) == ubyte)))
        )
    {
        if ( uri ) {
            handleChangeURI(uri);
        }
        _postData = makeAdapter(content);
        return post();
    }

    FTPResponse post()
    {
        string response;
        ushort code;

        _response = new FTPResponse;
        _response._startedAt = Clock.currTime;
        _method = "POST";

        scope(exit) {
            _response._finishedAt = Clock.currTime;
        }

        _response.uri = _uri;
        _response.finalURI = _uri;

        _controlChannel = _cm.get(_uri.scheme, _uri.host, _uri.port);
        
        if ( !_controlChannel ) {
            _controlChannel = new TCPStream();
            _controlChannel.connect(_uri.host, _uri.port, _timeout);
            response = serverResponse(_controlChannel);
            _responseHistory ~= response;
            
            code = responseToCode(response);
            debug(requests) tracef("Server initial response: %s", response);
            if ( code/100 > 2 ) {
                _response.code = code;
                return _response;
            }
            // Log in
            string user, pass;
            if ( _authenticator ) {
                user = _authenticator.userName();
                pass = _authenticator.password();
            }
            else{
                user = _uri.username.length ? _uri.username : "anonymous";
                pass = _uri.password.length ? _uri.password : "requests@";
            }
            debug(requests) tracef("Use %s:%s%s as username:password", user, pass[0], replicate("-", pass.length-1));
            
            code = sendCmdGetResponse("USER " ~ user ~ "\r\n", _controlChannel);
            if ( code/100 > 3 ) {
                _response.code = code;
                return _response;
            } else if ( code/100 == 3) {
                
                code = sendCmdGetResponse("PASS " ~ pass ~ "\r\n", _controlChannel);
                if ( code/100 > 2 ) {
                    _response.code = code;
                    return _response;
                }
            }
            
        }
        code = sendCmdGetResponse("PWD\r\n", _controlChannel);
        string pwd;
        if ( code/100 == 2 ) {
            // like '257 "/home/testuser"'
            auto a = _responseHistory[$-1].split();
            if ( a.length > 1 ) {
                pwd = a[1].chompPrefix(`"`).chomp(`"`);
            }
        }
        scope (exit) {
            if ( pwd && _controlChannel ) {
                sendCmdGetResponse("CWD " ~ pwd ~ "\r\n", _controlChannel);
            }
        }

        auto path = dirName(_uri.path);
        if ( path != "/") {
            path = path.chompPrefix("/");
        }
        code = sendCmdGetResponse("CWD " ~ path ~ "\r\n", _controlChannel);
        if ( code == 550 ) {
            // try to create directory end enter it
            code = tryCdOrCreatePath(dirName(_uri.path).split('/'));
        }
        if ( code/100 > 2 ) {
            _response.code = code;
            return _response;
        }

        code = sendCmdGetResponse("PASV\r\n", _controlChannel);
        if ( code/100 > 2 ) {
            _response.code = code;
            return _response;
        }
        // something like  "227 Entering Passive Mode (132,180,15,2,210,187)" expected
        // in last response.
        // Cut anything between ( and )
        auto v = _responseHistory[$-1].findSplitBefore(")")[0].findSplitAfter("(")[1];
        string host;
        ushort port;
        try {
            ubyte a1,a2,a3,a4,p1,p2;
            formattedRead(v, "%d,%d,%d,%d,%d,%d", &a1, &a2, &a3, &a4, &p1, &p2);
            host = std.format.format("%d.%d.%d.%d", a1, a2, a3, a4);
            port = (p1<<8) + p2;
        } catch (FormatException e) {
            error("Failed to parse ", v);
            _response.code = 500;
            return _response;
        }

        auto dataStream = new TCPStream();
        scope (exit ) {
            if ( dataStream !is null ) {
                dataStream.close();
            }
        }

        dataStream.connect(host, port, _timeout);

        code = sendCmdGetResponse("TYPE I\r\n", _controlChannel);
        if ( code/100 > 2 ) {
            _response.code = code;
            return _response;
        }

        code = sendCmdGetResponse("STOR " ~ baseName(_uri.path) ~ "\r\n", _controlChannel);
        if ( code/100 > 1 ) {
            _response.code = code;
            return _response;
        }
        size_t uploaded;
        while ( !_postData.empty ) {
            auto chunk = _postData.front;
            uploaded += chunk.length;
            dataStream.send(chunk);
            _postData.popFront;
        }
        debug(requests) tracef("sent");
        dataStream.close();
        dataStream = null;
        response = serverResponse(_controlChannel);
        code = responseToCode(response);
        if ( code/100 == 2 ) {
            debug(requests) tracef("Successfully uploaded %d bytes", uploaded);
        }
        _response.code = code;
        return _response;
    }
    private auto connectData(string v)
    {
        string host;
        ushort port;

        ubyte a1,a2,a3,a4,p1,p2;
        formattedRead(v, "%d,%d,%d,%d,%d,%d", &a1, &a2, &a3, &a4, &p1, &p2);
        host = std.format.format("%d.%d.%d.%d", a1, a2, a3, a4);
        port = (p1<<8) + p2;

        auto dataStream = new TCPStream();
        dataStream.bind(_bind);
        dataStream.connect(host, port, _timeout);
        return dataStream;
    }

    FTPResponse get(string uri = null) {
        enforce( uri || _uri.host, "FTP URL undefined");
        string response;
        ushort code;

        _response = new FTPResponse;
        _contentReceived = 0;
        _method = "GET";

        _response._startedAt = Clock.currTime;
        scope(exit) {
            _response._finishedAt = Clock.currTime;
        }

        if ( uri ) {
            handleChangeURI(uri);
        }

        _response.uri = _uri;
        _response.finalURI = _uri;

        _controlChannel = _cm.get(_uri.scheme, _uri.host, _uri.port);
        
        if ( !_controlChannel ) {
            _controlChannel = new TCPStream();
            _controlChannel.bind(_bind);
            _controlChannel.connect(_uri.host, _uri.port, _timeout);
            if ( auto purged_connection = _cm.put(_uri.scheme, _uri.host, _uri.port, _controlChannel) )
            {
                debug(requests) tracef("closing purged connection %s", purged_connection);
                purged_connection.close();
            }
            _response._connectedAt = Clock.currTime;
            response = serverResponse(_controlChannel);
            _responseHistory ~= response;
            
            code = responseToCode(response);
            debug(requests) tracef("Server initial response: %s", response);
            if ( code/100 > 2 ) {
                _response.code = code;
                return _response;
            }
            // Log in
            string user, pass;
            if ( _authenticator ) {
                user = _authenticator.userName();
                pass = _authenticator.password();
            }
            else{
                user = _uri.username.length ? _uri.username : "anonymous";
                pass = _uri.password.length ? _uri.password : "requests@";
            }
            debug(requests) tracef("Use %s:%s%s as username:password", user, pass[0], replicate("-", pass.length-1));
            
            code = sendCmdGetResponse("USER " ~ user ~ "\r\n", _controlChannel);
            if ( code/100 > 3 ) {
                _response.code = code;
                return _response;
            } else if ( code/100 == 3) {
                
                code = sendCmdGetResponse("PASS " ~ pass ~ "\r\n", _controlChannel);
                if ( code/100 > 2 ) {
                    _response.code = code;
                    return _response;
                }
            }
        }
        else {
            _response._connectedAt = Clock.currTime;
        }

        code = sendCmdGetResponse("PWD\r\n", _controlChannel);
        string pwd;
        if ( code/100 == 2 ) {
            // like '257 "/home/testuser"'
            auto a = _responseHistory[$-1].split();
            if ( a.length > 1 ) {
                pwd = a[1].chompPrefix(`"`).chomp(`"`);
            }
        }
        scope (exit) {
            if ( pwd && _controlChannel && !_useStreaming ) {
                sendCmdGetResponse("CWD " ~ pwd ~ "\r\n", _controlChannel);
            }
        }
        
        auto path = dirName(_uri.path);
        if ( path != "/") {
            path = path.chompPrefix("/");
        }
        code = sendCmdGetResponse("CWD " ~ path ~ "\r\n", _controlChannel);
        if ( code/100 > 2 ) {
            _response.code = code;
            return _response;
        }

        code = sendCmdGetResponse("TYPE I\r\n", _controlChannel);
        if ( code/100 > 2 ) {
            _response.code = code;
            return _response;
        }
        
        code = sendCmdGetResponse("SIZE " ~ baseName(_uri.path) ~ "\r\n", _controlChannel);
        if ( code/100 == 2 ) {
            // something like 
            // 213 229355520
            auto s = _responseHistory[$-1].findSplitAfter(" ");
            if ( s.length ) {
                try {
                    _contentLength = to!long(s[1]);
                } catch (ConvException) {
                    debug(requests) trace("Failed to convert string %s to file size".format(s[1]));
                }
            }
        }

        if ( _maxContentLength > 0 && _contentLength > _maxContentLength ) {
            throw new RequestException("maxContentLength exceeded for ftp data");
        }

        code = sendCmdGetResponse("PASV\r\n", _controlChannel);
        if ( code/100 > 2 ) {
            _response.code = code;
            return _response;
        }
        // something like  "227 Entering Passive Mode (132,180,15,2,210,187)" expected
        // in last response.
        // Cut anything between ( and )
        auto v = _responseHistory[$-1].findSplitBefore(")")[0].findSplitAfter("(")[1];

        TCPStream dataStream;
        try{
            dataStream = connectData(v);
        } catch (FormatException e) {
            error("Failed to parse ", v);
            _response.code = 500;
            return _response;
        }
        scope (exit ) {
            if ( dataStream !is null && !_response._receiveAsRange.activated ) {
                dataStream.close();
            }
        }

        _response._requestSentAt = Clock.currTime;
        
        code = sendCmdGetResponse("RETR " ~ baseName(_uri.path) ~ "\r\n", _controlChannel);
        if ( code/100 > 1 && code/100 < 5) {
            _response.code = code;
            return _response;
        }
        if ( code/100 == 5) {
            dataStream.close();
            code = sendCmdGetResponse("PASV\r\n", _controlChannel);
            if ( code/100 > 2 ) {
                _response.code = code;
                return _response;
            }
            v = _responseHistory[$-1].findSplitBefore(")")[0].findSplitAfter("(")[1];
            dataStream = connectData(v);
            code = sendCmdGetResponse("NLST " ~ _uri.path ~ "\r\n", _controlChannel);
            if ( code/100 > 1 ) {
                _response.code = code;
                return _response;
            }
        }

        dataStream.readTimeout = _timeout;
        while ( true ) {
            auto b = new ubyte[_bufferSize];
            auto rc = dataStream.receive(b);
            if ( rc <= 0 ) {
                debug(requests) trace("done");
                break;
            }
            debug(requests) tracef("got %d bytes from data channel", rc);

            _contentReceived += rc;
            _response._responseBody.putNoCopy(b[0..rc]);

            if ( _maxContentLength && _response._responseBody.length >= _maxContentLength ) {
                throw new RequestException("maxContentLength exceeded for ftp data");
            }
            if ( _useStreaming ) {
                debug(requests) trace("ftp uses streaming");

                auto __maxContentLength = _maxContentLength;
                auto __contentLength = _contentLength;
                auto __contentReceived = _contentReceived;
                auto __bufferSize = _bufferSize;
                auto __dataStream = dataStream;
                auto __controlChannel = _controlChannel;

                _response._contentLength = _contentLength;
                _response.receiveAsRange.activated = true;
                _response.receiveAsRange.data.length = 0;
                _response.receiveAsRange.data = _response._responseBody.data;
                _response.receiveAsRange.read = delegate ubyte[] () {
                    Buffer!ubyte result;
                    while(true) {
                        // check if we received everything we need
                        if ( __maxContentLength > 0 && __contentReceived >= __maxContentLength ) 
                        {
                            throw new RequestException("ContentLength > maxContentLength (%d>%d)".
                                format(__contentLength, __maxContentLength));
                        }
                        // have to continue
                        auto b = new ubyte[__bufferSize];
                        ptrdiff_t read;
                        try {
                            read = __dataStream.receive(b);
                        }
                        catch (Exception e) {
                            throw new RequestException("streaming_in error reading from socket", __FILE__, __LINE__, e);
                        }

                        if ( read > 0 ) {
                            _response._contentReceived += read;
                            __contentReceived += read;
                            result.putNoCopy(b[0..read]);
                            return result.data;
                        }
                        if ( read == 0 ) {
                            debug(requests) tracef("streaming_in: server closed connection");
                            __dataStream.close();
                            code = responseToCode(serverResponse(__controlChannel));
                            if ( code/100 == 2 ) {
                                debug(requests) tracef("Successfully received %d bytes", _response._responseBody.length);
                            }
                            _response.code = code;
                            sendCmdGetResponse("CWD " ~ pwd ~ "\r\n", __controlChannel);
                            break;
                        }
                    }
                    return result.data;
                };
                debug(requests) tracef("leave streaming get");
                return _response;
            }
        }
        dataStream.close();
        response = serverResponse(_controlChannel);
        code = responseToCode(response);
        if ( code/100 == 2 ) {
            debug(requests) tracef("Successfully received %d bytes", _response._responseBody.length);
        }
        _response.code = code;
        return _response;
    }
    FTPResponse list(string uri = null) {
        enforce( uri || _uri.host, "FTP URL undefined");
        string response;
        ushort code;

        _response = new FTPResponse;
        _contentReceived = 0;
        _method = "GET";

        _response._startedAt = Clock.currTime;
        scope(exit) {
            _response._finishedAt = Clock.currTime;
        }

        if ( uri ) {
            handleChangeURI(uri);
        }

        _response.uri = _uri;
        _response.finalURI = _uri;

        _controlChannel = _cm.get(_uri.scheme, _uri.host, _uri.port);

        if ( !_controlChannel ) {
            _controlChannel = new TCPStream();
            _controlChannel.bind(_bind);
            _controlChannel.connect(_uri.host, _uri.port, _timeout);
            if ( auto purged_connection = _cm.put(_uri.scheme, _uri.host, _uri.port, _controlChannel) )
            {
                debug(requests) tracef("closing purged connection %s", purged_connection);
                purged_connection.close();
            }
            _response._connectedAt = Clock.currTime;
            response = serverResponse(_controlChannel);
            _responseHistory ~= response;

            code = responseToCode(response);
            debug(requests) tracef("Server initial response: %s", response);
            if ( code/100 > 2 ) {
                _response.code = code;
                return _response;
            }
            // Log in
            string user, pass;
            if ( _authenticator ) {
                user = _authenticator.userName();
                pass = _authenticator.password();
            }
            else{
                user = _uri.username.length ? _uri.username : "anonymous";
                pass = _uri.password.length ? _uri.password : "requests@";
            }
            debug(requests) tracef("Use %s:%s%s as username:password", user, pass[0], replicate("-", pass.length-1));

            code = sendCmdGetResponse("USER " ~ user ~ "\r\n", _controlChannel);
            if ( code/100 > 3 ) {
                _response.code = code;
                return _response;
            } else if ( code/100 == 3) {
                code = sendCmdGetResponse("PASS " ~ pass ~ "\r\n", _controlChannel);
                if ( code/100 > 2 ) {
                    _response.code = code;
                    return _response;
                }
            }
        }
        else {
            _response._connectedAt = Clock.currTime;
        }

        code = sendCmdGetResponse("PWD\r\n", _controlChannel);
        string pwd;
        if ( code/100 == 2 ) {
            // like '257 "/home/testuser"'
            auto a = _responseHistory[$-1].split();
            if ( a.length > 1 ) {
                pwd = a[1].chompPrefix(`"`).chomp(`"`);
            }
        }
        scope (exit) {
            if ( pwd && _controlChannel && !_useStreaming ) {
                sendCmdGetResponse("CWD " ~ pwd ~ "\r\n", _controlChannel);
            }
        }

        auto path = dirName(_uri.path);
        if ( path != "/") {
            path = path.chompPrefix("/");
        }
        code = sendCmdGetResponse("CWD " ~ path ~ "\r\n", _controlChannel);
        if ( code/100 > 2 ) {
            _response.code = code;
            return _response;
        }

        code = sendCmdGetResponse("TYPE I\r\n", _controlChannel);
        if ( code/100 > 2 ) {
            _response.code = code;
            return _response;
        }

        code = sendCmdGetResponse("SIZE " ~ baseName(_uri.path) ~ "\r\n", _controlChannel);
        if ( code/100 == 2 ) {
            // something like
            // 213 229355520
            auto s = _responseHistory[$-1].findSplitAfter(" ");
            if ( s.length ) {
                try {
                    _contentLength = to!long(s[1]);
                } catch (ConvException) {
                    debug(requests) trace("Failed to convert string %s to file size".format(s[1]));
                }
            }
        }

        if ( _maxContentLength > 0 && _contentLength > _maxContentLength ) {
            throw new RequestException("maxContentLength exceeded for ftp data");
        }

        code = sendCmdGetResponse("PASV\r\n", _controlChannel);
        if ( code/100 > 2 ) {
            _response.code = code;
            return _response;
        }
        // something like  "227 Entering Passive Mode (132,180,15,2,210,187)" expected
        // in last response.
        // Cut anything between ( and )
        auto v = _responseHistory[$-1].findSplitBefore(")")[0].findSplitAfter("(")[1];

        TCPStream dataStream;
        try{
            dataStream = connectData(v);
        } catch (FormatException e) {
            error("Failed to parse ", v);
            _response.code = 500;
            return _response;
        }
        scope (exit ) {
            if ( dataStream !is null && !_response._receiveAsRange.activated ) {
                dataStream.close();
            }
        }

        _response._requestSentAt = Clock.currTime;

        code = sendCmdGetResponse("LIST " ~ baseName(_uri.path) ~ "\r\n", _controlChannel);
        if ( code/100 > 1 && code/100 < 5) {
            _response.code = code;
            return _response;
        }
        if ( code/100 == 5) {
            dataStream.close();
            code = sendCmdGetResponse("PASV\r\n", _controlChannel);
            if ( code/100 > 2 ) {
                _response.code = code;
                return _response;
            }
            v = _responseHistory[$-1].findSplitBefore(")")[0].findSplitAfter("(")[1];
            dataStream = connectData(v);
            code = sendCmdGetResponse("NLST " ~ _uri.path ~ "\r\n", _controlChannel);
            if ( code/100 > 1 ) {
                _response.code = code;
                return _response;
            }
        }

        dataStream.readTimeout = _timeout;
        while ( true ) {
            auto b = new ubyte[_bufferSize];
            auto rc = dataStream.receive(b);
            if ( rc <= 0 ) {
                debug(requests) trace("done");
                break;
            }
            debug(requests) tracef("got %d bytes from data channel", rc);

            _contentReceived += rc;
            _response._responseBody.putNoCopy(b[0..rc]);

            if ( _maxContentLength && _response._responseBody.length >= _maxContentLength ) {
                throw new RequestException("maxContentLength exceeded for ftp data");
            }
            if ( _useStreaming ) {
                debug(requests) trace("ftp uses streaming");

                auto __maxContentLength = _maxContentLength;
                auto __contentLength = _contentLength;
                auto __contentReceived = _contentReceived;
                auto __bufferSize = _bufferSize;
                auto __dataStream = dataStream;
                auto __controlChannel = _controlChannel;

                _response._contentLength = _contentLength;
                _response.receiveAsRange.activated = true;
                _response.receiveAsRange.data.length = 0;
                _response.receiveAsRange.data = _response._responseBody.data;
                _response.receiveAsRange.read = delegate ubyte[] () {
                    Buffer!ubyte result;
                    while(true) {
                        // check if we received everything we need
                        if ( __maxContentLength > 0 && __contentReceived >= __maxContentLength ) 
                        {
                            throw new RequestException("ContentLength > maxContentLength (%d>%d)".
                                format(__contentLength, __maxContentLength));
                        }
                        // have to continue
                        auto b = new ubyte[__bufferSize];
                        ptrdiff_t read;
                        try {
                            read = __dataStream.receive(b);
                        }
                        catch (Exception e) {
                            throw new RequestException("streaming_in error reading from socket", __FILE__, __LINE__, e);
                        }

                        if ( read > 0 ) {
                            _response._contentReceived += read;
                            __contentReceived += read;
                            result.putNoCopy(b[0..read]);
                            return result.data;
                        }
                        if ( read == 0 ) {
                            debug(requests) tracef("streaming_in: server closed connection");
                            __dataStream.close();
                            code = responseToCode(serverResponse(__controlChannel));
                            if ( code/100 == 2 ) {
                                debug(requests) tracef("Successfully received %d bytes", _response._responseBody.length);
                            }
                            _response.code = code;
                            sendCmdGetResponse("CWD " ~ pwd ~ "\r\n", __controlChannel);
                            break;
                        }
                    }
                    return result.data;
                };
                debug(requests) tracef("leave streaming get");
                return _response;
            }
        }
        dataStream.close();
        response = serverResponse(_controlChannel);
        code = responseToCode(response);
        if ( code/100 == 2 ) {
            debug(requests) tracef("Successfully received %d bytes", _response._responseBody.length);
        }
        _response.code = code;
        return _response;
    }
    FTPResponse execute(Request r)
    {
        string method = r.method;
        _uri = r.uri();
        _authenticator = r.authenticator;
        _maxContentLength = r.maxContentLength;
        _useStreaming = r.useStreaming;
        _verbosity = r.verbosity;
        _cm = r.cm;
        _postData = r.postData;
        _bufferSize = r.bufferSize;
        _proxy = r.proxy;
        _bind = r.bind;
        _timeout = r.timeout;

        if ( method == "GET" )
        {
            return get();
        }
        if ( method == "POST" )
        {
            return post();
        }
        if ( method == "LIST" ) {
            return list();
        }
        assert(0, "Can't handle method %s for ftp request".format(method));
    }
}

//package unittest {
//    import std.process;
//
//    globalLogLevel(LogLevel.info);
//    bool unreliable_network = environment.get("UNRELIABLENETWORK", "false") == "true";
//
//    info("testing ftp");
//    auto rq = FTPRequest();
//    info("ftp post ", "ftp://speedtest.tele2.net/upload/TEST.TXT");
//    auto rs = rq.post("ftp://speedtest.tele2.net/upload/TEST.TXT", "test, ignore please\n".representation);
//    assert(unreliable_network || rs.code == 226);
//    info("ftp get  ", "ftp://speedtest.tele2.net/nonexistent", ", in same session.");
//    rs = rq.get("ftp://speedtest.tele2.net/nonexistent");
//    assert(unreliable_network || rs.code != 226);
//    info("ftp get  ", "ftp://speedtest.tele2.net/1KB.zip", ", in same session.");
//    rs = rq.get("ftp://speedtest.tele2.net/1KB.zip");
//    assert(unreliable_network || rs.code == 226);
//    assert(unreliable_network || rs.responseBody.length == 1024);
//    info("ftp post ", "ftp://speedtest.tele2.net/upload/TEST.TXT");
//    rs = rq.post("ftp://speedtest.tele2.net/upload/TEST.TXT", "another test, ignore please\n".representation);
//    assert(unreliable_network || rs.code == 226);
//    info("ftp get  ", "ftp://ftp.iij.ad.jp/pub/FreeBSD/README.TXT");
//    try {
//        rs = rq.get("ftp://ftp.iij.ad.jp/pub/FreeBSD/README.TXT");
//    }
//    catch (ConnectError e)
//    {
//    }
//    assert(unreliable_network || rs.code == 226);
//    info("ftp get  ftp://ftp.iij.ad.jp/pub/FreeBSD/README.TXT with authenticator");
//    rq.authenticator = new FtpAuthentication("anonymous", "requests@");
//    try {
//        rs = rq.get("ftp://ftp.iij.ad.jp/pub/FreeBSD/README.TXT");
//    }
//    catch (ConnectError e)
//    {
//    }
//    assert(unreliable_network || rs.code == 226);
//    assert(unreliable_network || rs.finalURI.path == "/pub/FreeBSD/README.TXT");
//    assert(unreliable_network || rq.format("%m|%h|%p|%P|%q|%U") == "GET|ftp.iij.ad.jp|21|/pub/FreeBSD/README.TXT||ftp://ftp.iij.ad.jp/pub/FreeBSD/README.TXT");
//    assert(unreliable_network || rs.format("%h|%p|%P|%q|%U") == "ftp.iij.ad.jp|21|/pub/FreeBSD/README.TXT||ftp://ftp.iij.ad.jp/pub/FreeBSD/README.TXT");
//    info("testing ftp - done.");
//}
