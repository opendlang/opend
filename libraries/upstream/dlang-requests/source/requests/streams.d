module requests.streams;

private:
import std.algorithm;
import std.array;
import std.conv;
import std.experimental.logger;
import std.exception;
import std.format;
import std.range;
import std.range.primitives;
import std.string;
import std.stdio;
import std.traits;
import std.zlib;
import std.datetime;
import std.socket;
import core.stdc.errno;
import core.stdc.string;

import requests.ssl_adapter : openssl, SSL, SSL_CTX;

alias InDataHandler = DataPipeIface!ubyte;

public class ConnectError: Exception {
    this(string message, string file =__FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow {
        super(message, file, line, next);
    }
}

class DecodingException: Exception {
    this(string message, string file =__FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow {
        super(message, file, line, next);
    }
}

public class TimeoutException: Exception {
    this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow {
        super(message, file, line, next);
    }
}

public class NetworkException: Exception {
    this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow {
        super(message, file, line, next);
    }
}

/**
 * DataPipeIface can accept some data, process, and return processed data.
 */
public interface DataPipeIface(E) {
    /// Is there any processed data ready for reading?
    bool empty();
    /// Put next data portion for processing
    //void put(E[]);
    void putNoCopy(E[]);
    /// Get any ready data
    E[] get();
    /// Signal on end of incoming data stream.
    void flush();
}
/**
 * DataPipe is a pipeline of data processors, each accept some data, process it, and put result to next element in line.
 * This class used to combine different Transfer- and Content- encodings. For example: unchunk transfer-encoding "chunnked",
 * and uncompress Content-Encoding "gzip".
 */
public class DataPipe(E) : DataPipeIface!E {

    DataPipeIface!(E)[]  pipe;
    Buffer!E             buffer;
    /// Append data processor to pipeline
    /// Params:
    /// p = processor
    final void insert(DataPipeIface!E p) {
        pipe ~= p;
    }
    final E[][] process(DataPipeIface!E p, E[][] data) {
        E[][] result;
        data.each!(e => p.putNoCopy(e));
        while(!p.empty()) result ~= p.get();
        return result;
    }
    /// Process next data portion. Data passed over pipeline and store result in buffer.
    /// Params:
    /// data = input data buffer.
    /// NoCopy means we do not copy data to buffer, we keep reference
    final void putNoCopy(E[] data) {
        if ( pipe.empty ) {
            buffer.putNoCopy(data);
            return;
        }
        try {
            auto t = process(pipe.front, [data]);
            foreach(ref p; pipe[1..$]) {
                t = process(p, t);
            }
            t.each!(b => buffer.putNoCopy(b));
        }
        catch (Exception e) {
            throw new DecodingException(e.msg);
        }
    }
    /// Get what was collected in internal buffer and clear it.
    /// Returns:
    /// data collected.
    final E[] get() {
        if ( buffer.empty ) {
            return E[].init;
        }
        auto res = buffer.data;
        buffer = Buffer!E.init;
        return res;
    }
    ///
    /// get without datamove. but user receive [][]
    ///
    final E[][] getNoCopy()  {
        if ( buffer.empty ) {
            return E[][].init;
        }
        E[][] res = buffer.__repr.__buffer;
        buffer = Buffer!E.init;
        return res;
    }
    /// Test if internal buffer is empty
    /// Returns:
    /// true if internal buffer is empty (nothing to get())
    final bool empty() pure const @safe {
        return buffer.empty;
    }
    final void flush() {
        E[][] product;
        foreach(ref p; pipe) {
            product.each!(e => p.putNoCopy(e));
            p.flush();
            product.length = 0;
            while( !p.empty ) product ~= p.get();
        }
        product.each!(b => buffer.putNoCopy(b));
    }
}

/**
 * Processor for gzipped/compressed content.
 * Also support InputRange interface.
 */
public class Decompressor(E) : DataPipeIface!E {
    private {
        Buffer!ubyte __buff;
        UnCompress   __zlib;
    }
    this() {
        __buff = Buffer!ubyte();
        __zlib = new UnCompress();
    }
    final override void putNoCopy(E[] data) {
        if ( __zlib is null  ) {
            __zlib = new UnCompress();
        }
        __buff.putNoCopy(__zlib.uncompress(data));
    }
    final override E[] get() pure {
        assert(__buff.length);
        auto r = __buff.__repr.__buffer[0];
        __buff.popFrontN(r.length);
        return cast(E[])r;
    }
    final override void flush() {
        if ( __zlib is null  ) {
            return;
        }
        __buff.put(__zlib.flush());
    }
    final override @property bool empty() const pure @safe {
        debug(requests) tracef("empty=%b", __buff.empty);
        return __buff.empty;
    }
    final @property auto ref front() pure const @safe {
        debug(requests) tracef("front: buff length=%d", __buff.length);
        return __buff.front;
    }
    final @property auto popFront() pure @safe {
        debug(requests) tracef("popFront: buff length=%d", __buff.length);
        return __buff.popFront;
    }
    final @property void popFrontN(size_t n) pure @safe {
        __buff.popFrontN(n);
    }
}

/**
 * Unchunk chunked http responce body.
 */
public class DecodeChunked : DataPipeIface!ubyte {
    //    length := 0
    //    read chunk-size, chunk-extension (if any) and CRLF
    //    while (chunk-size > 0) {
    //        read chunk-data and CRLF
    //        append chunk-data to entity-body
    //        length := length + chunk-size
    //        read chunk-size and CRLF
    //    }
    //    read entity-header
    //    while (entity-header not empty) {
    //        append entity-header to existing header fields
    //        read entity-header
    //    }
    //    Content-Length := length
    //    Remove "chunked" from Transfer-Encoding
    //

    //    Chunked-Body   = *chunk
    //                      last-chunk
    //                      trailer
    //                      CRLF
    //
    //    chunk          = chunk-size [ chunk-extension ] CRLF
    //                     chunk-data CRLF
    //                     chunk-size     = 1*HEX
    //                     last-chunk     = 1*("0") [ chunk-extension ] CRLF
    //
    //    chunk-extension= *( ";" chunk-ext-name [ "=" chunk-ext-val ] )
    //    chunk-ext-name = token
    //    chunk-ext-val  = token | quoted-string
    //    chunk-data     = chunk-size(OCTET)
    //    trailer        = *(entity-header CRLF)

    alias eType = ubyte;
    immutable eType[] CRLF = ['\r', '\n'];
    private {
        enum         States {huntingSize, huntingSeparator, receiving, trailer};
        char         state = States.huntingSize;
        size_t       chunk_size, to_receive;
        Buffer!ubyte buff;
        ubyte[]      linebuff;
    }
    final void putNoCopy(eType[] data) {
        while ( data.length ) {
            if ( state == States.trailer ) {
                to_receive = to_receive - min(to_receive, data.length);
                return;
            }
            if ( state == States.huntingSize ) {
                import std.ascii;
                ubyte[10] digits;
                int i;
                for(i=0;i<data.length;i++) {
                    ubyte v = data[i];
                    digits[i] = v;
                    if ( v == '\n' ) {
                        i+=1;
                        break;
                    }
                }
                linebuff ~= digits[0..i];
                if ( linebuff.length >= 80 ) {
                    throw new DecodingException("Can't find chunk size in the body");
                }
                data = data[i..$];
                if (!linebuff.canFind(CRLF)) {
                    continue;
                }
                chunk_size = linebuff.filter!isHexDigit.map!toUpper.map!"a<='9'?a-'0':a-'A'+10".reduce!"a*16+b";
                state = States.receiving;
                to_receive = chunk_size;
                if ( chunk_size == 0 ) {
                    to_receive = 2-min(2, data.length); // trailing \r\n
                    state = States.trailer;
                    return;
                }
                continue;
            }
            if ( state == States.receiving ) {
                if (to_receive > 0 ) {
                    auto can_store = min(to_receive, data.length);
                    buff.putNoCopy(data[0..can_store]);
                    data = data[can_store..$];
                    to_receive -= can_store;
                    //tracef("Unchunked %d bytes from %d", can_store, chunk_size);
                    if ( to_receive == 0 ) {
                        //tracef("switch to huntig separator");
                        state = States.huntingSeparator;
                        continue;
                    }
                    continue;
                }
                assert(false);
            }
            if ( state == States.huntingSeparator ) {
                if ( data[0] == '\n' || data[0]=='\r') {
                    data = data[1..$];
                    continue;
                }
                state = States.huntingSize;
                linebuff.length = 0;
                continue;
            }
        }
    }
    final eType[] get() {
        auto r = buff.__repr.__buffer[0];
        buff.popFrontN(r.length);
        return r;
    }
    final void flush() {
    }
    final bool empty() {
        debug(requests) tracef("empty=%b", buff.empty);
        return buff.empty;
    }
    final bool done() {
        return state==States.trailer && to_receive==0;
    }
}

unittest {
    info("Testing DataPipe");
    globalLogLevel(LogLevel.info);
    alias eType = char;
    eType[] gzipped = [
        0x1F, 0x8B, 0x08, 0x00, 0xB1, 0xA3, 0xEA, 0x56,
        0x00, 0x03, 0x4B, 0x4C, 0x4A, 0xE6, 0x4A, 0x49,
        0x4D, 0xE3, 0x02, 0x00, 0x75, 0x0B, 0xB0, 0x88,
        0x08, 0x00, 0x00, 0x00
    ]; // "abc\ndef\n"
    auto d = new Decompressor!eType();
    d.putNoCopy(gzipped[0..2].dup);
    d.putNoCopy(gzipped[2..10].dup);
    d.putNoCopy(gzipped[10..$].dup);
    d.flush();
    assert(equal(d.filter!(a => a!='b'), "ac\ndef\n"));

    auto e = new Decompressor!eType();
    e.putNoCopy(gzipped[0..10].dup);
    e.putNoCopy(gzipped[10..$].dup);
    e.flush();
    assert(equal(e.filter!(a => a!='b'), "ac\ndef\n"));
    //    writeln(gzipped.decompress.filter!(a => a!='b').array);
    auto dp = new DataPipe!eType;
    dp.insert(new Decompressor!eType());
    dp.putNoCopy(gzipped[0..2].dup);
    dp.putNoCopy(gzipped[2..$].dup);
    dp.flush();
    assert(equal(dp.get(), "abc\ndef\n"));
    // empty datapipe shoul just pass input to output
    auto dpu = new DataPipe!ubyte;
    dpu.putNoCopy("abcd".dup.representation);
    dpu.putNoCopy("efgh".dup.representation);
    dpu.flush();
    assert(equal(dpu.get(), "abcdefgh"));
    info("Test unchunker properties");
    ubyte[] twoChunks = "2\r\n12\r\n2\r\n34\r\n0\r\n\r\n".dup.representation;
    ubyte[][] result;
    auto uc = new DecodeChunked();
    uc.putNoCopy(twoChunks);
    while(!uc.empty) {
        result ~= uc.get();
    }
    assert(equal(result[0], ['1', '2']));
    assert(equal(result[1], ['3', '4']));
    info("unchunker correctness - ok");
    result[0][0] = '5';
    assert(twoChunks[3] == '5');
    info("unchunker zero copy - ok");
    info("Testing DataPipe - done");
}

public class LineSplitter : DataPipeIface!ubyte
{
    private
    {
        Buffer!ubyte    buff;
        int            NL = -1;
        int            scanned;
    }
    bool empty()
    {
        return NL == -1;
    }
    void putNoCopy(ubyte[] s)
    {
        debug(requests) tracef("put data: <<%s>>", cast(string)s);
        buff.putNoCopy(s);
        if (NL == -1)
        {
            auto new_NL = buff.indexOf(cast(ubyte)'\n', scanned);
            NL = new_NL;
            debug(requests) tracef("new nl=%d", NL);
        }
        scanned = cast(int)buff.length;
    }
    ubyte[] get()
    {
        if (NL>=0)
        {
            auto res = buff[0..NL+1].data;
            buff.popFrontN(NL+1);
            NL = buff.indexOf(cast(ubyte)'\n', 0);
            if (NL == -1)
            {
                scanned = cast(int)buff.length;
            }
            return res;
        }
        return new ubyte[](0);
    }
    void flush()
    {
        NL = cast(int)buff.length - 1;
    }
}
unittest
{
    info("testing LineSplitter");
    LineSplitter ls = new LineSplitter();
    ls.putNoCopy("abc".representation.dup);
    assert(ls.empty);
    ls.putNoCopy("\n".representation.dup);
    assert(!ls.empty);
    assert(equal(ls.get, "abc\n"));
    assert(ls.empty);
    assert(equal(ls.get,""));
    ls.putNoCopy("def\n".representation.dup);
    ls.putNoCopy("ghi\njk".representation.dup);
    assert(!ls.empty);
    assert(equal(ls.get, "def\n"));
    assert(!ls.empty);
    assert(equal(ls.get, "ghi\n"));
    assert(ls.empty);
    ls.flush();
    assert(equal(ls.get, "jk"));
}
/**
 * Buffer used to collect and process data from network. It remainds Appender, but support
 * also Range interface.
 * $(P To place data in buffer use put() method.)
 * $(P  To retrieve data from buffer you can use several methods:)
 * $(UL
 *  $(LI Range methods: front, back, index [])
 *  $(LI data method: return collected data (like Appender.data))
 * )
 */
enum   CACHESIZE = 1024;

static long reprAlloc;
static long reprCacheHit;
static long reprCacheRequests;


public struct Buffer(T) {
//    static Repr[CACHESIZE]  cache;
//    static uint             cacheIndex;

    private {
        Repr  cachedOrNew() {
            return new Repr;
//            reprCacheRequests++;
//            if ( false && cacheIndex>0 ) {
//                reprCacheHit++;
//                cacheIndex -= 1;
//                return cache[cacheIndex];
//            } else {
//                return new Repr;
//            }
        }
        class Repr {
            size_t         __length;
            Unqual!T[][]   __buffer;
            this() {
                reprAlloc++;
                __length = 0;
            }
            this(Repr other) {
                reprAlloc++;
                if ( other is null )
                    return;
                __length = other.__length;
                __buffer = other.__buffer.dup;
            }
        }
        Repr __repr;
    }

    alias toString = data!string;

    this(this) {
        if ( !__repr ) {
            return;
        }
        __repr = new Repr(__repr);
    }
    this(U)(U[] data) {
        put(data);
    }
    ~this() {
        __repr = null;
    }
    /***************
     * store data. Data copied
     */
    auto put(U)(U[] data) {
        if ( data.length == 0 ) {
            return;
        }
        if ( !__repr ) {
            __repr = cachedOrNew();
        }
        static if (!is(U == T)) {
            auto d = cast(T[])(data);
            __repr.__length += d.length;
            __repr.__buffer ~= d.dup;
        } else {
            __repr.__length += data.length;
            __repr.__buffer ~= data.dup;
        }
        return;
    }
    auto putNoCopy(U)(U[] data) {
        if ( data.length == 0 ) {
            return;
        }
        if ( !__repr ) {
            __repr = cachedOrNew();
        }
        static if (!is(U == T)) {
            auto d = cast(T[])(data);
            __repr.__length += d.length;
            __repr.__buffer ~= d;
        } else {
            __repr.__length += data.length;
            __repr.__buffer ~= data;
        }
        return;
    }
    @property auto opDollar() const pure @safe {
        return __repr.__length;
    }
    @property size_t length() const pure @safe {
        if ( !__repr ) {
            return 0;
        }
        return __repr.__length;
    }
    @property auto empty() const pure @safe {
        return length == 0;
    }
    @property auto ref front() const pure @safe {
        assert(length);
        return __repr.__buffer.front.front;
    }
    @property auto ref back() const pure @safe {
        assert(length);
        return __repr.__buffer.back.back;
    }
    @property void popFront() pure @safe {
        assert(length);
        with ( __repr ) {
            __buffer.front.popFront;
            if ( __buffer.front.length == 0 ) {
                __buffer.popFront;
            }
            __length--;
        }
    }
    @property void popFrontN(size_t n) pure @safe {
        assert(n <= length, "lengnt: %d, n=%d".format(length, n));
        __repr.__length -= n;
        while( n ) {
            if ( n <= __repr.__buffer.front.length ) {
                __repr.__buffer.front.popFrontN(n);
                if ( __repr.__buffer.front.length == 0 ) {
                    __repr.__buffer.popFront;
                }
                return;
            }
            n -= __repr.__buffer.front.length;
            __repr.__buffer.popFront;
        }
    }
    @property void popBack() pure @safe {
        assert(length);
        __repr.__buffer.back.popBack;
        if ( __repr.__buffer.back.length == 0 ) {
            __repr.__buffer.popBack;
        }
        __repr.__length--;
    }
    @property void popBackN(size_t n) pure @safe {
        assert(n <= length, "n: %d, length: %d".format(n, length));
        __repr.__length -= n;
        while( n ) {
            if ( n <= __repr.__buffer.back.length ) {
                __repr.__buffer.back.popBackN(n);
                if ( __repr.__buffer.back.length == 0 ) {
                    __repr.__buffer.popBack;
                }
                return;
            }
            n -= __repr.__buffer.back.length;
            __repr.__buffer.popBack;
        }
    }
    @property auto save() @safe {
        auto n = Buffer!T();
        n.__repr = new Repr(__repr);
        return n;
    }
    @property auto ref opIndex(size_t n) const pure @safe {
        assert( __repr && n < __repr.__length );
        foreach(b; __repr.__buffer) {
            if ( n < b.length ) {
                return b[n];
            }
            n -= b.length;
        }
        assert(false, "Impossible");
    }
    int indexOf(ubyte needle, int pos)
    {
        if ( pos >= length || !__repr || !__repr.__buffer)
        {
            return -1;
        }
        // skip pos bytes
        debug(requests) tracef("search %d from pos %d", needle, pos);
        int cp;
        foreach (ref b; __repr.__buffer)
        {
            if ( pos >= b.length )
            {
                pos -= b.length;
                cp += b.length;
                continue;
            }
            auto i = b[pos..$].countUntil(needle);
            pos = 0;
            if (i>=0)
            {
                debug(requests) tracef("found at %d", i+cp);
                return cast(int)i+cp;
            }
            cp += b.length;
        }
        return -1;
    }
    Buffer!T opSlice(size_t m, size_t n) {
        if ( empty || m == n ) {
            return Buffer!T();
        }
        assert( m <= n && n <= __repr.__length);
        auto res = this.save();
        res.popBackN(res.__repr.__length-n);
        res.popFrontN(m);
        return res;
    }
    @property auto data(U=T[])() pure {
        static if ( is(U==T[]) ) {
            if ( __repr && __repr.__buffer && __repr.__buffer.length == 1 ) {
                return __repr.__buffer.front;
            }
        }
        Appender!(T[]) a;
        if ( __repr && __repr.__buffer ) {
            foreach(ref b; __repr.__buffer) {
                a.put(b);
            }
        }
        static if ( is(U==T[]) ) {
            return a.data;
        } else {
            return cast(U)a.data;
        }
    }
    string opCast(string)() {
        return this.toString;
    }
    bool opEquals(U)(U x) {
        return cast(U)this == x;
    }

}
///
public unittest {

    static assert(isInputRange!(Buffer!ubyte));
    static assert(isForwardRange!(Buffer!ubyte));
    static assert(hasLength!(Buffer!ubyte));
    static assert(hasSlicing!(Buffer!ubyte));
    static assert(isBidirectionalRange!(Buffer!ubyte));
    static assert(isRandomAccessRange!(Buffer!ubyte));

    auto b = Buffer!ubyte();
    b.put("abc".representation.dup);
    b.put("def".representation.dup);
    assert(b.length == 6);
    assert(b.toString == "abcdef");
    assert(b.front == 'a');
    assert(b.back == 'f');
    assert(equal(b[0..$], "abcdef"));
    assert(equal(b[$-2..$], "ef"));
    assert(b == "abcdef");
    b.popFront;
    b.popBack;
    assert(b.front == 'b');
    assert(b.back == 'e');
    assert(b.length == 4);
    assert(retro(b).front == 'e');
    assert(countUntil(b, 'e') == 3);
    assert(equal(splitter(b, 'c').array[1], ['d', 'e'])); // split "bcde" on 'c'
    assert(equal(b, "bcde"));
    b.popFront; b.popFront;
    assert(b.front == 'd');
    assert(b.front == b[0]);
    assert(b.back == b[$-1]);

    auto c = Buffer!ubyte();
    c.put("Header0: value0\n".representation.dup);
    c.put("Header1: value1\n".representation.dup);
    c.put("Header2: value2\n\nbody".representation.dup);
    auto c_length = c.length;
    auto eoh = countUntil(c, "\n\n");
    assert(eoh == 47);
    // foreach(header; c[0..eoh].splitter('\n') ) {
    //     writeln(cast(string)header.data);
    // }
    assert(equal(findSplit(c, "\n\n")[2], "body"));
    assert(c.length == c_length);
    assert(c.indexOf('\n', 0) == 15);
    assert(c.indexOf('\n', 16) == 31);
    assert(c.indexOf('X', 16) == -1);
}

public struct SSLOptions {
    enum filetype {
        pem,
        asn1,
        der = asn1,
    }
    private {
        /**
         * do we need to veryfy peer?
         */
        bool     _verifyPeer = true;
        /**
         * path to CA cert
         */
        string   _caCert;
        /**
         * path to key file (can also contain cert (for pem)
         */
        string   _keyFile;
        /**
         * path to cert file (can also contain key (for pem)
         */
        string   _certFile;
        filetype _keyType = filetype.pem;
        filetype _certType = filetype.pem;
    }
    ubyte haveFiles() pure nothrow @safe @nogc {
        ubyte r = 0;
        if ( _keyFile  ) r|=1;
        if ( _certFile ) r|=2;
        return r;
    }
    // do we want to verify peer certificates?
    bool getVerifyPeer() pure nothrow @nogc {
        return _verifyPeer;
    }
    SSLOptions setVerifyPeer(bool v) pure nothrow @nogc @safe {
        _verifyPeer = v;
        return this;
    }
    /// set key file name and type (default - pem)
    auto setKeyFile(string f, filetype t = filetype.pem) @safe pure nothrow @nogc {
        _keyFile = f;
        _keyType = t;
        return this;
    }
    auto getKeyFile() @safe pure nothrow @nogc {
        return _keyFile;
    }
    auto getKeyType() @safe pure nothrow @nogc {
        return _keyType;
    }
    /// set cert file name and type (default - pem)
    auto setCertFile(string f, filetype t = filetype.pem) @safe pure nothrow @nogc {
        _certFile = f;
        _certType = t;
        return this;
    }
    auto setCaCert(string p) @safe pure nothrow @nogc {
        _caCert = p;
        return this;
    }
    auto getCaCert() @safe pure nothrow @nogc {
        return _caCert;
    }
    auto getCertFile() @safe pure nothrow @nogc {
        return _certFile;
    }
    auto getCertType() @safe pure nothrow @nogc {
        return _certType;
    }
    /// set key file type
    void setKeyType(string t) @safe pure nothrow {
        _keyType = cast(filetype)sslKeyTypes[t];
    }
    /// set cert file type
    void setCertType(string t) @safe pure nothrow {
        _certType = cast(filetype)sslKeyTypes[t];
    }
}
static immutable int[string] sslKeyTypes;
shared static this() {
    sslKeyTypes = [
        "pem":SSLOptions.filetype.pem,
        "asn1":SSLOptions.filetype.asn1,
        "der":SSLOptions.filetype.der,
    ];
}

version(vibeD) {
}
else {
    extern(C) {
        int SSL_library_init();
    }

    enum SSL_VERIFY_PEER = 0x01;
    enum SSL_FILETYPE_PEM = 1;
    enum SSL_FILETYPE_ASN1 = 2;

    immutable int[SSLOptions.filetype] ft2ssl;

    shared static this() {
        ft2ssl = [
            SSLOptions.filetype.pem: SSL_FILETYPE_PEM,
            SSLOptions.filetype.asn1: SSL_FILETYPE_ASN1,
            SSLOptions.filetype.der: SSL_FILETYPE_ASN1
        ];
    }

    public class OpenSslSocket : Socket {
        //enum SSL_MODE_RELEASE_BUFFERS = 0x00000010L;
        private SSL* ssl;
        private SSL_CTX* ctx;

        private void initSsl(SSLOptions opts) {
            //ctx = SSL_CTX_new(SSLv3_client_method());
            ctx = openssl.SSL_CTX_new(openssl.TLS_method());
            assert(ctx !is null);
            if ( opts.getVerifyPeer() ) {
                openssl.SSL_CTX_set_default_verify_paths(ctx);
                if ( opts.getCaCert() ) {
                    openssl.SSL_CTX_load_verify_locations(ctx, cast(char*)opts.getCaCert().toStringz(), cast(char*)null);
                }
                openssl.SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, null);
            }
            immutable keyFile = opts.getKeyFile();
            immutable keyType = opts.getKeyType();
            immutable certFile = opts.getCertFile();
            immutable certType = opts.getCertType();
            final switch(opts.haveFiles()) {
                case 0b11:  // both files
                    openssl.SSL_CTX_use_PrivateKey_file(ctx,  keyFile.toStringz(), ft2ssl[keyType]);
                    openssl.SSL_CTX_use_certificate_file(ctx, certFile.toStringz(),ft2ssl[certType]);
                    break;
                case 0b01:  // key only
                    openssl.SSL_CTX_use_PrivateKey_file(ctx,  keyFile.toStringz(), ft2ssl[keyType]);
                    openssl.SSL_CTX_use_certificate_file(ctx, keyFile.toStringz(), ft2ssl[keyType]);
                    break;
                case 0b10:  // cert only
                    openssl.SSL_CTX_use_PrivateKey_file(ctx,  certFile.toStringz(), ft2ssl[certType]);
                    openssl.SSL_CTX_use_certificate_file(ctx, certFile.toStringz(), ft2ssl[certType]);
                    break;
                case 0b00:
                    break;
            }
            //SSL_CTX_set_mode(ctx, SSL_MODE_RELEASE_BUFFERS);
            //SSL_CTX_ctrl(ctx, 33, SSL_MODE_RELEASE_BUFFERS, null);
            ssl = openssl.SSL_new(ctx);
            openssl.SSL_set_fd(ssl, cast(int)this.handle);
        }

        @trusted
        override void connect(Address dest) {
            super.connect(dest);
            if(openssl.SSL_connect(ssl) == -1) {
                throw new Exception("ssl connect failed: %s".format(to!string(openssl.ERR_reason_error_string(openssl.ERR_get_error()))));
            }
        }
        auto connectSSL() {
            if(openssl.SSL_connect(ssl) == -1) {
                throw new Exception("ssl connect failed: %s".format(to!string(openssl.ERR_reason_error_string(openssl.ERR_get_error()))));
            }
            debug(requests) tracef("ssl socket connected");
            return this;
        }
        @trusted
        override ptrdiff_t send(scope const(void)[] buf, SocketFlags flags) scope {
            return openssl.SSL_write(ssl, buf.ptr, cast(uint) buf.length);
        }
        override ptrdiff_t send(scope const(void)[] buf) scope {
            return send(buf, SocketFlags.NONE);
        }
        @trusted
        override ptrdiff_t receive(scope void[] buf, SocketFlags flags) scope {
            return openssl.SSL_read(ssl, buf.ptr, cast(int)buf.length);
        }
        override ptrdiff_t receive(scope void[] buf) scope {
            return receive(buf, SocketFlags.NONE);
        }
        this(AddressFamily af, SocketType type = SocketType.STREAM, SSLOptions opts = SSLOptions()) {
            super(af, type);
            initSsl(opts);
        }
        this(socket_t sock, AddressFamily af, SSLOptions opts = SSLOptions()) {
            super(sock, af);
            initSsl(opts);
        }
        override void close() scope {
            super.close();
            if ( ssl !is null ) {
                openssl.SSL_free(ssl);
                ssl = null;
            }
            if ( ctx !is null ) {
                openssl.SSL_CTX_free(ctx);
                ctx = null;
            }
        }
        void SSL_set_tlsext_host_name(string host) {

        }
    }

    public class SSLSocketStream: SocketStream {
        private SSLOptions _sslOptions;
        private Socket underlyingSocket;
        private SSL* ssl;
        private string host;

        this(SSLOptions opts) {
            _sslOptions = opts;
        }
        this(NetworkStream ostream, SSLOptions opts, string host = null) {
            _sslOptions = opts;
            this.host = host;
            auto osock = ostream.so();
            underlyingSocket = osock;
            osock.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, 1);
            auto ss = new OpenSslSocket(osock.handle, osock.addressFamily, _sslOptions);
            ssl = ss.ssl;
            if ( host !is null ) {
                openssl.SSL_set_tlsext_host_name(ssl, toStringz(host));
            }
            ss.connectSSL();
            __isOpen = true;
            __isConnected = true;
            s = ss;
            debug(requests) tracef("ssl stream created from another stream: %s", s);
        }
        override void close() {
            ssl = null;
            host = null;
            super.close();
            if ( underlyingSocket ) {
                underlyingSocket.close();
            }
        }
        override void open(AddressFamily fa) {
            if ( s !is null ) {
                s.close();
            }
            auto ss = new OpenSslSocket(fa, SocketType.STREAM, _sslOptions);
            assert(ss !is null, "Can't create socket");
            ssl = ss.ssl;
            if ( host !is null ) {
                openssl.SSL_set_tlsext_host_name(ssl, toStringz(host));
            }
            s = ss;
            s.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, 1);
            __isOpen = true;
        }
        override SocketStream connect(string h, ushort p, Duration timeout = 10.seconds) {
            host = h;
            return super.connect(h, p, timeout);
        }
        override SSLSocketStream accept() {
            auto newso = s.accept();
            if ( s is null ) {
                return null;
            }
            auto newstream = new SSLSocketStream(_sslOptions);
            auto sslSocket = new OpenSslSocket(newso.handle, s.addressFamily);
            newstream.s = sslSocket;
            newstream.__isOpen = true;
            newstream.__isConnected = true;
            return newstream;
        }
    }
    public class TCPSocketStream : SocketStream {
        override void open(AddressFamily fa) {
            if ( s !is null ) {
                s.close();
            }
            s = new Socket(fa, SocketType.STREAM, ProtocolType.TCP);
            assert(s !is null, "Can't create socket");
            __isOpen = true;
            s.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, 1);
        }
        override TCPSocketStream accept() {
            auto newso = s.accept();
            if ( s is null ) {
                return null;
            }
            auto newstream = new TCPSocketStream();
            newstream.s = newso;
            newstream.__isOpen = true;
            newstream.__isConnected = true;
            newstream.s.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, 1);
            return newstream;
        }
    }
}

public interface NetworkStream {
    @property bool isConnected() const;
    @property bool isOpen() const;

    void close() @trusted;

    ///
    /// timeout is the socket write timeout.
    ///
    NetworkStream connect(string host, ushort port, Duration timeout = 10.seconds);

    ptrdiff_t send(const(void)[] buff);
    ptrdiff_t receive(void[] buff);

    NetworkStream accept();
    @property void reuseAddr(bool);
    void bind(string);
    void bind(Address);
    void listen(int);
    version(vibeD) {
        TCPConnection so();
    } else {
        Socket so();
    }
    ///
    /// Set timeout for receive calls. 0 means no timeout.
    ///
    @property void readTimeout(Duration timeout);
}

public abstract class SocketStream : NetworkStream {
    private {
        Duration timeout;
        Socket   s;
        bool     __isOpen;
        bool     __isConnected;
        string   _bind;
    }
    void open(AddressFamily fa) {
    }
    @property Socket so() @safe pure {
        return s;
    }
    @property bool isOpen() @safe @nogc pure const {
        return s && __isOpen;
    }
    @property bool isConnected() @safe @nogc pure const {
        return s && __isOpen && __isConnected;
    }
    void close() @trusted {
        // can be callsed from dtor in GC, no gc calls here
        if ( isOpen ) {
            s.close();
            __isOpen = false;
            __isConnected = false;
        }
        s = null;
    }
    /***
    *  bind() just remember address. We will cal bind() at the time of connect as
    *  we can have several connection trials.
    ***/
    override void bind(string to) {
        _bind = to;
    }
    /***
    *  Make connection to remote site. Bind, handle connection error, try several addresses, etc
    ***/
    SocketStream connect(string host, ushort port, Duration timeout = 10.seconds) {
        debug(requests) tracef(format("Create connection to %s:%d", host, port));
        Address[] addresses;
        __isConnected = false;
        try {
            addresses = getAddress(host, port);
        } catch (Exception e) {
            throw new ConnectError("Can't resolve name when connect to %s:%d: %s".format(host, port, e.msg));
        }
        foreach(a; addresses) {
            debug(requests) tracef("Trying %s", a);
            try {
                open(a.addressFamily);
                if ( _bind !is null ) {
                    auto ad = getAddress(_bind);
                    debug(requests) tracef("bind to %s", ad[0]);
                    s.bind(ad[0]);
                }
                s.setOption(SocketOptionLevel.SOCKET, SocketOption.SNDTIMEO, timeout);
                s.connect(a);
                debug(requests) tracef("Connected to %s", a);
                __isConnected = true;
                break;
            } catch (SocketException e) {
                debug(requests) warningf("Failed to connect to %s:%d(%s): %s", host, port, a, e.msg);
                s.close();
            }
        }
        if ( !__isConnected ) {
            throw new ConnectError("Can't connect to %s:%d".format(host, port));
        }
        return this;
    }

    ptrdiff_t send(const(void)[] buff)
    in {assert(isConnected);}
    do {
        auto rc = s.send(buff);
        if (rc < 0) {
            close();
            throw new NetworkException("sending data: %s".format(to!string(strerror(errno))));
        }
        return rc;
    }

    ptrdiff_t receive(void[] buff) {
        while (true) {
            auto r = s.receive(buff);
            if (r < 0) {
                auto e = errno;
                version(Windows) {
                    close();
                    if ( e == 0 ) {
                        throw new TimeoutException("Timeout receiving data");
                    }
                    throw new NetworkException("Unexpected error %s while receiving data".format(to!string(strerror(errno))));
                }
                version(Posix) {
                    if ( e == EINTR ) {
                        continue;
                    }
                    close();
                    if ( e == EAGAIN ) {
                        throw new TimeoutException("Timeout receiving data");
                    }
                    throw new NetworkException("Unexpected error %s while receiving data".format(to!string(strerror(errno))));
                }
            }
            else {
                buff.length = r;
            }
            return r;
        }
        assert(false);
    }

    @property void readTimeout(Duration timeout) @safe {
        if ( __isConnected )
        {
            s.setOption(SocketOptionLevel.SOCKET, SocketOption.RCVTIMEO, timeout);
        }
    }
    override SocketStream accept() {
        assert(false, "Implement before use");
    }
    @property override void reuseAddr(bool yes){
        if (yes) {
            s.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, 1);
        }
        else {
            s.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, 0);
        }
    }
    override void bind(Address addr){
        s.bind(addr);
    }
    override void listen(int n) {
        s.listen(n);
    };
}

version (vibeD) {
    import vibe.core.net, vibe.stream.tls;

    public class TCPVibeStream : NetworkStream {
    private:
        TCPConnection _conn;
        Duration _readTimeout = Duration.max;
        bool _isOpen = true;
        string _bind;

    public:
        @property bool isConnected() const {
            return _conn.connected;
        }
        @property override bool isOpen() const {
            return _conn && _isOpen;
        }
        void close() @trusted {
            _conn.close();
            _isOpen = false;
        }
        override TCPConnection so() {
            return _conn;
        }
        override void bind(string to) {
                _bind = to;
        }
        NetworkStream connect(string host, ushort port, Duration timeout = 10.seconds) {
            // FIXME: timeout not supported in vibe.d
            try {
                _conn = connectTCP(host, port, _bind);
            }
            catch (Exception e)
                throw new ConnectError("Can't connect to %s:%d".format(host, port), __FILE__, __LINE__, e);

            return this;
        }

        ptrdiff_t send(const(void)[] buff) {
            _conn.write(cast(const(ubyte)[])buff);
            return buff.length;
        }

        ptrdiff_t receive(void[] buff) {
            if (!_conn.waitForData(_readTimeout)) {
                if (!_conn.connected || _conn.empty ) {
                    return 0;
                }
                throw new TimeoutException("Timeout receiving data");
            }

            if(_conn.empty) {
                return 0;
            }

            auto chunk = min(_conn.leastSize, buff.length);
            assert(chunk != 0);
            _conn.read(cast(ubyte[])buff[0 .. chunk]);
            return chunk;
        }

        @property void readTimeout(Duration timeout) {
            if (timeout == 0.seconds) {
                _readTimeout = Duration.max;
            }
            else {
                _readTimeout = timeout;
            }
        }
        override TCPVibeStream accept() {
            assert(false, "Must be implemented");
        }
        override @property void reuseAddr(bool){
            assert(false, "Not Implemented");
        }
        override void bind(Address){
            assert(false, "Not Implemented");
        }
        override void listen(int){
            assert(false, "Not Implemented");
        }
    }

    public class SSLVibeStream : TCPVibeStream {
    private:
        TLSStream _sslStream;
        bool   _isOpen = true;
        SSLOptions _sslOptions;
        TCPConnection underlyingConnection;

        void connectSSL(string host) {
            auto sslctx = createTLSContext(TLSContextKind.client);
            if ( _sslOptions.getVerifyPeer() ) {
                if ( _sslOptions.getCaCert() == null ) {
                    throw new ConnectError("With vibe.d you have to call setCaCert() before verify server certificate.");
                }
                sslctx.useTrustedCertificateFile(_sslOptions.getCaCert());
                sslctx.peerValidationMode = TLSPeerValidationMode.trustedCert;
            } else {
                sslctx.peerValidationMode = TLSPeerValidationMode.none;
            }
            immutable keyFile = _sslOptions.getKeyFile();
            immutable certFile = _sslOptions.getCertFile();
            final switch(_sslOptions.haveFiles()) {
                case 0b11:  // both files
                    sslctx.usePrivateKeyFile(keyFile);
                    sslctx.useCertificateChainFile(certFile);
                    break;
                case 0b01:  // key only
                    sslctx.usePrivateKeyFile(keyFile);
                    sslctx.useCertificateChainFile(keyFile);
                    break;
                case 0b10:  // cert only
                    sslctx.usePrivateKeyFile(certFile);
                    sslctx.useCertificateChainFile(certFile);
                    break;
                case 0b00:
                    break;
            }
            _sslStream = createTLSStream(_conn, sslctx, host);
        }

    public:
        this(SSLOptions opts) {
            _sslOptions = opts;
        }
        override TCPConnection so() {
            return _conn;
        }
        this(NetworkStream ostream, SSLOptions opts, string host = null) {
            _sslOptions = opts;
            auto oconn = ostream.so();
            underlyingConnection = oconn;
            _conn = oconn;
            connectSSL(host);
        }
        override NetworkStream connect(string host, ushort port, Duration timeout = 10.seconds) {
            try {
                _conn = connectTCP(host, port);
                connectSSL(host);
            }
            catch (ConnectError e) {
                throw e;
            }
            catch (Exception e) {
                throw new ConnectError("Can't connect to %s:%d".format(host, port), __FILE__, __LINE__, e);
            }

            return this;
        }

        override ptrdiff_t send(const(void)[] buff) {
            _sslStream.write(cast(const(ubyte)[])buff);
            return buff.length;
        }

        override ptrdiff_t receive(void[] buff) {
            if (!_sslStream.dataAvailableForRead) {
                if (!_conn.waitForData(_readTimeout)) {
                    if (!_conn.connected) {
                        return 0;
                    }
                    throw new TimeoutException("Timeout receiving data");
                }
            }

            if(_sslStream.empty) {
                return 0;
            }

            auto chunk = min(_sslStream.leastSize, buff.length);
            assert(chunk != 0);
            _sslStream.read(cast(ubyte[])buff[0 .. chunk]);
            return chunk;
        }

        override void close() @trusted {
            if ( _sslStream )
            {
                _sslStream.finalize();
            }
            _conn.close();
            _isOpen = false;
        }
        @property override bool isOpen() const {
            return _conn && _isOpen;
        }
        override SSLVibeStream accept() {
            assert(false, "Must be implemented");
        }
        override @property void reuseAddr(bool){
            assert(false, "Not Implemented");
        }
        override void bind(Address){
            assert(false, "Not Implemented");
        }
        override void listen(int){
            assert(false, "Not Implemented");
        }
    }
}

version (vibeD) {
    public alias TCPStream = TCPVibeStream;
    public alias SSLStream = SSLVibeStream;
}
else {
    public alias TCPStream = TCPSocketStream;
    public alias SSLStream = SSLSocketStream;
}
