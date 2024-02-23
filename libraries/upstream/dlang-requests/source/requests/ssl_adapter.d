module requests.ssl_adapter;

version(staticssl) {
    public import requests.ssl_adapter_static;
} else:

import std.stdio;
import std.string;
import std.format;
import std.typecons;
import core.stdc.stdlib;
import core.sys.posix.dlfcn;
import std.experimental.logger;
import core.stdc.config;

version(Windows) {
    import core.sys.windows.windows;
    alias DLSYM = GetProcAddress;
} else {
    alias DLSYM = dlsym;
}

version(RequestsSkipSSL)
{
    enum enableSSL = false;
}
else
{
    enum enableSSL = true;
}

/*
 * /usr/include/openssl/tls1.h:# define TLS_ANY_VERSION 0x10000
 */

immutable int TLS_ANY_VERSION = 0x10000;
immutable int TLS1_VERSION = 0x0301;
immutable int TLS1_2_VERSION = 0x0303;

struct SSL {};
struct SSL_CTX {};
struct SSL_METHOD {};

//
// N  - function name, R - return type, A - args
//
string SSL_Function_decl(string N, R, A...)() {
    string F = "extern (C) @nogc nothrow %s function %s adapter_%s;".format(R.stringof, A.stringof, N);
    return F;
}
string SSL_Function_set_i(string N, R, A...)() {
    string F = "openssl.adapter_%s = cast(typeof(openssl.adapter_%s))DLSYM(cast(void*)openssl._libssl, \"%s\");".format(N, N, N);
    return F;
}
string CRYPTO_Function_set_i(string N, R, A...)() {
    string F = "openssl.adapter_%s = cast(typeof(openssl.adapter_%s))DLSYM(cast(void*)openssl._libcrypto, \"%s\");".format(N, N, N);
    return F;
}

private alias Version = Tuple!(int, "major", int, "minor");

immutable static OpenSSL openssl;

shared static this() {
    version(OSX) {
        enum loadFunction = "dlopen(lib.ptr, RTLD_LAZY)";
        immutable string[] libsslname = [
            "libssl.46.dylib",
            "libssl.44.dylib",
            "libssl.43.dylib",
            "libssl.35.dylib",
            "libssl.dylib",
        ];
        immutable string[] libcryptoname = [
            "libcrypto.44.dylib",
            "libcrypto.42.dylib",
            "libcrypto.41.dylib",
            "libcrypto.35.dylib",
            "libcrypto.dylib",
        ];
    } else
    version(linux) {
        enum loadFunction = "dlopen(lib.ptr, RTLD_LAZY)";
        immutable string[] libsslname = [
            "libssl.so.3",
            "libssl.so.1.1",
            "libssl.so.1.0.2",
            "libssl.so.1.0.1",
            "libssl.so.1.0.0",
            "libssl.so",
        ];
        immutable string[] libcryptoname = [
            "libcrypto.so.3",
            "libcrypto.so.1.1",
            "libcrypto.so.1.0.2",
            "libcrypto.so.1.0.1",
            "libcrypto.so.1.0.0",
            "libcrypto.so",
        ];
    } else
    version(FreeBSD) {
        enum loadFunction = "dlopen(lib.ptr, RTLD_LAZY)";
        immutable string[] libsslname = [
            "libssl.so.1.1",
            "libssl.so.1.0.2",
            "libssl.so.1.0.1",
            "libssl.so.1.0.0",
            "libssl.so",
        ];
        immutable string[] libcryptoname = [
            "libcrypto.so.1.1",
            "libcrypto.so.1.0.2",
            "libcrypto.so.1.0.1",
            "libcrypto.so.1.0.0",
            "libcrypto.so",
        ];
    } else
    version(Windows) {
        enum loadFunction = "LoadLibrary(lib.ptr)";
        immutable wstring[] libsslname = [
             "libssl32.dll"w,
             "libssl-1_1"w,
             "libssl-1_1-x64"w,
         ];
         immutable wstring[] libcryptoname = [
             "libeay32.dll"w,
             "libcrypto-1_1"w,
             "libcrypto-1_1-x64"w,
        ];
    } else {
        debug(requests) trace("error loading openssl: unsupported system - first access over https will fail");
        return;
    }

    static if ( enableSSL && is(typeof(loadFunction)) ) {
        foreach(lib; libsslname) {
            openssl._libssl = cast(typeof(openssl._libssl))mixin(loadFunction);
            if ( openssl._libssl !is null ) {
                debug(requests) tracef("will use %s".format(lib));
                break;
            }
        }
        foreach(lib; libcryptoname) {
            openssl._libcrypto = cast(typeof(openssl._libcrypto))mixin(loadFunction);
            if ( openssl._libcrypto !is null ) {
                debug(requests) tracef("will use %s".format(lib));
                break;
            }
        }
    }

    if ( openssl._libssl is null ) {
        debug(requests) trace("warning: failed to load libssl - first access over https will fail");
        return;
    }
    if ( openssl._libcrypto is null ) {
        debug(requests) trace("warning: failed to load libcrypto - first access over https will fail");
        return;
    }
    openssl._ver = openssl.OpenSSL_version_detect();

    mixin(SSL_Function_set_i!("SSL_library_init", int));
    mixin(CRYPTO_Function_set_i!("OpenSSL_add_all_ciphers", void));
    mixin(CRYPTO_Function_set_i!("OpenSSL_add_all_digests", void));
    mixin(SSL_Function_set_i!("SSL_load_error_strings", void));

    mixin(SSL_Function_set_i!("OPENSSL_init_ssl", int, ulong, void*));
    mixin(CRYPTO_Function_set_i!("OPENSSL_init_crypto", int, ulong, void*));

    mixin(SSL_Function_set_i!("TLSv1_client_method", SSL_METHOD*));
    mixin(SSL_Function_set_i!("TLSv1_2_client_method", SSL_METHOD*));
    mixin(SSL_Function_set_i!("TLS_method", SSL_METHOD*));
    mixin(SSL_Function_set_i!("SSLv23_client_method", SSL_METHOD*));
    mixin(SSL_Function_set_i!("SSL_CTX_new", SSL_CTX*, SSL_METHOD*));
    mixin(SSL_Function_set_i!("SSL_CTX_set_default_verify_paths", int, SSL_CTX*));
    mixin(SSL_Function_set_i!("SSL_CTX_load_verify_locations", int, SSL_CTX*, char*, char*));
    mixin(SSL_Function_set_i!("SSL_CTX_set_verify", void, SSL_CTX*, int, void*));
    mixin(SSL_Function_set_i!("SSL_CTX_use_PrivateKey_file", int, SSL_CTX*, const char*, int));
    mixin(SSL_Function_set_i!("SSL_CTX_use_certificate_file", int, SSL_CTX*, const char*, int));
    mixin(SSL_Function_set_i!("SSL_CTX_set_cipher_list", int, SSL_CTX*, const char*));
    mixin(SSL_Function_set_i!("SSL_CTX_ctrl", c_long, SSL_CTX*, int, c_long, void*));
    mixin(SSL_Function_set_i!("SSL_new", SSL*, SSL_CTX*));
    mixin(SSL_Function_set_i!("SSL_set_fd", int, SSL*, int));
    mixin(SSL_Function_set_i!("SSL_connect", int, SSL*));
    mixin(SSL_Function_set_i!("SSL_write", int, SSL*, const void*, int));
    mixin(SSL_Function_set_i!("SSL_read", int, SSL*, void*, int));
    mixin(SSL_Function_set_i!("SSL_free", void, SSL*));
    mixin(SSL_Function_set_i!("SSL_CTX_free", void, SSL_CTX*));
    mixin(SSL_Function_set_i!("SSL_get_error", int, SSL*, int));
    mixin(SSL_Function_set_i!("SSL_ctrl", c_long, SSL*, int, c_long, void*));
    mixin(CRYPTO_Function_set_i!("ERR_reason_error_string", char*, c_ulong));
    mixin(CRYPTO_Function_set_i!("ERR_get_error", c_ulong));

    void delegate()[Version] init_matrix;
    init_matrix[Version(1,0)] = &openssl.init1_0;
    init_matrix[Version(1,1)] = &openssl.init1_1;
    init_matrix[Version(2,0)] = &openssl.init1_1;
    init_matrix[Version(0,2)] = &openssl.init1_1; // libressl >= 2.7.1
    init_matrix[Version(0,3)] = &openssl.init1_1; // libressl >= 3.0.0
    init_matrix[Version(3,0)] = &openssl.init1_1; // >=3.0
    auto initVer = (ver) {
        if (ver.major == 3 && ver.minor >= 1) // set 3.x to 3.0 for the init matrix
            return Version(3, 0);
        else
            return ver;
    }(openssl._ver);
    auto init = init_matrix.get(initVer, null);
    if ( init is null ) {
        throw new Exception("loading openssl: unknown version %s for init".format(openssl._ver));
    }
    init();
}

struct OpenSSL {

    private {
        Version         _ver;
        void*           _libssl;
        void*           _libcrypto;

        // openssl 1.0.x init functions
        mixin(SSL_Function_decl!("SSL_library_init", int));
        mixin(SSL_Function_decl!("OpenSSL_add_all_ciphers", void));
        mixin(SSL_Function_decl!("OpenSSL_add_all_digests", void));
        mixin(SSL_Function_decl!("SSL_load_error_strings", void));

        // openssl 1.1.x init functions
        mixin(SSL_Function_decl!("OPENSSL_init_ssl", int, ulong, void*)); // fixed width 64 bit arg
        mixin(SSL_Function_decl!("OPENSSL_init_crypto", int, ulong, void*)); // fixed width 64 bit arg

        // all other functions
        mixin(SSL_Function_decl!("TLSv1_client_method", SSL_METHOD*));
        mixin(SSL_Function_decl!("TLSv1_2_client_method", SSL_METHOD*));
        mixin(SSL_Function_decl!("TLS_method", SSL_METHOD*));
        mixin(SSL_Function_decl!("SSLv23_client_method", SSL_METHOD*));
        mixin(SSL_Function_decl!("SSL_CTX_new", SSL_CTX*, SSL_METHOD*));
        mixin(SSL_Function_decl!("SSL_CTX_set_default_verify_paths", int, SSL_CTX*));
        mixin(SSL_Function_decl!("SSL_CTX_load_verify_locations", int, SSL_CTX*, char*, char*));
        mixin(SSL_Function_decl!("SSL_CTX_set_verify", void, SSL_CTX*, int, void*));
        mixin(SSL_Function_decl!("SSL_CTX_use_PrivateKey_file", int, SSL_CTX*, const char*, int));
        mixin(SSL_Function_decl!("SSL_CTX_use_certificate_file", int, SSL_CTX*, const char*, int));
        mixin(SSL_Function_decl!("SSL_CTX_set_cipher_list", int, SSL_CTX*, const char*));
        mixin(SSL_Function_decl!("SSL_CTX_ctrl", c_long, SSL_CTX*, int, c_long, void*));
        mixin(SSL_Function_decl!("SSL_new", SSL*, SSL_CTX*));
        mixin(SSL_Function_decl!("SSL_set_fd", int, SSL*, int));
        mixin(SSL_Function_decl!("SSL_connect", int, SSL*));
        mixin(SSL_Function_decl!("SSL_write", int, SSL*, const void*, int));
        mixin(SSL_Function_decl!("SSL_read", int, SSL*, void*, int));
        mixin(SSL_Function_decl!("SSL_free", void, SSL*));
        mixin(SSL_Function_decl!("SSL_CTX_free", void, SSL_CTX*));
        mixin(SSL_Function_decl!("SSL_get_error", int, SSL*, int));
        mixin(SSL_Function_decl!("SSL_ctrl", c_long, SSL*, int, c_long, void*));
        mixin(SSL_Function_decl!("ERR_reason_error_string", char*, c_ulong));
        mixin(SSL_Function_decl!("ERR_get_error", c_ulong));
    }

    Version reportVersion() const @nogc nothrow pure {
        return _ver;
    };

    private Version OpenSSL_version_detect() const {
        c_ulong function() OpenSSL_version_num = cast(c_ulong function())DLSYM(cast(void*)_libcrypto, "OpenSSL_version_num".ptr);
        if ( OpenSSL_version_num ) {
            auto v = OpenSSL_version_num() & 0xffffffff;
            return Version((v>>>28) & 0xff, (v>>>20) & 0xff);
        }
        return Version(1, 0);
    }

    private void init1_0() const {
        adapter_SSL_library_init();
        adapter_OpenSSL_add_all_ciphers();
        adapter_OpenSSL_add_all_digests();
        adapter_SSL_load_error_strings();
    }
    private void init1_1() const {
        /**
        Standard initialisation options

        #define OPENSSL_INIT_LOAD_SSL_STRINGS       0x00200000L

        # define OPENSSL_INIT_LOAD_CRYPTO_STRINGS    0x00000002L
        # define OPENSSL_INIT_ADD_ALL_CIPHERS        0x00000004L
        # define OPENSSL_INIT_ADD_ALL_DIGESTS        0x00000008L
        **/
        enum OPENSSL_INIT_LOAD_SSL_STRINGS = 0x00200000L;
        enum OPENSSL_INIT_LOAD_CRYPTO_STRINGS = 0x00000002L;
        enum OPENSSL_INIT_ADD_ALL_CIPHERS = 0x00000004L;
        enum OPENSSL_INIT_ADD_ALL_DIGESTS = 0x00000008L;
        adapter_OPENSSL_init_ssl(OPENSSL_INIT_LOAD_SSL_STRINGS, null);
        adapter_OPENSSL_init_crypto(OPENSSL_INIT_ADD_ALL_CIPHERS | OPENSSL_INIT_ADD_ALL_DIGESTS | OPENSSL_INIT_LOAD_CRYPTO_STRINGS, null);
    }

    SSL_METHOD* TLSv1_client_method() const {
        if ( adapter_TLSv1_client_method is null ) {
            throw new Exception("openssl not initialized - is it installed?");
        }
        return adapter_TLSv1_client_method();
    }
    SSL_METHOD* TLSv1_2_client_method() const {
        if ( adapter_TLSv1_2_client_method is null ) {
            throw new Exception("openssl not initialized - is it installed?");
        }
        return adapter_TLSv1_2_client_method();
    }
    SSL_METHOD* SSLv23_client_method() const {
        if ( adapter_SSLv23_client_method is null ) {
            throw new Exception("can't complete call to SSLv23_client_method");
        }
        return adapter_SSLv23_client_method();
    }
    SSL_METHOD* TLS_method() const {
        if ( adapter_TLS_method !is null ) {
            return adapter_TLS_method();
        }
        if ( adapter_SSLv23_client_method !is null ) {
            return adapter_SSLv23_client_method();
        }
        throw new Exception("can't complete call to TLS_method");
    }
    SSL_CTX* SSL_CTX_new(SSL_METHOD* method) const {
        if ( adapter_SSL_CTX_new is null ) {
            throw new Exception("openssl not initialized - is it installed?");
        }
        return adapter_SSL_CTX_new(method);
    }
    int SSL_CTX_set_default_verify_paths(SSL_CTX* ctx) const @nogc nothrow {
        return adapter_SSL_CTX_set_default_verify_paths(ctx);
    }
    int SSL_CTX_load_verify_locations(SSL_CTX* ctx, char* CAFile, char* CAPath) const @nogc nothrow {
        return adapter_SSL_CTX_load_verify_locations(ctx, CAFile, CAPath);
    }
    void SSL_CTX_set_verify(SSL_CTX* ctx, int mode, void* callback) const @nogc nothrow {
        adapter_SSL_CTX_set_verify(ctx, mode, callback);
    }
    int SSL_CTX_use_PrivateKey_file(SSL_CTX* ctx, const char* file, int type) const @nogc nothrow {
        return adapter_SSL_CTX_use_PrivateKey_file(ctx, file, type);
    }
    int SSL_CTX_use_certificate_file(SSL_CTX* ctx, const char* file, int type) const @nogc nothrow {
        return adapter_SSL_CTX_use_certificate_file(ctx, file, type);
    }
    int SSL_CTX_set_cipher_list(SSL_CTX* ssl_ctx, const char* c) const @nogc nothrow {
        return adapter_SSL_CTX_set_cipher_list(ssl_ctx, c);
    }
    /*
     *
     * # define SSL_CTRL_SET_MIN_PROTO_VERSION          123
     * # define SSL_CTRL_SET_MAX_PROTO_VERSION          124
    */
    enum int SSL_CTRL_SET_MIN_PROTO_VERSION = 123;
    enum int SSL_CTRL_SET_MAX_PROTO_VERSION = 124;
    int SSL_CTX_set_min_proto_version(SSL_CTX* ctx, int v) const @nogc nothrow {
        int r = cast(int)adapter_SSL_CTX_ctrl(ctx, SSL_CTRL_SET_MIN_PROTO_VERSION, cast(c_long)v, null);
        return r;
    }
    int SSL_CTX_set_max_proto_version(SSL_CTX* ctx, int v) const @nogc nothrow {
        int r = cast(int)adapter_SSL_CTX_ctrl(ctx, SSL_CTRL_SET_MAX_PROTO_VERSION, cast(c_long)v, null);
        return r;
    }
    SSL* SSL_new(SSL_CTX* ctx) const @nogc nothrow {
        return adapter_SSL_new(ctx);
    }
    int SSL_set_fd(SSL* ssl, int fd) const @nogc nothrow {
        return adapter_SSL_set_fd(ssl, fd);
    }
    int SSL_connect(SSL* ssl) const @nogc nothrow {
        return adapter_SSL_connect(ssl);
    }
    int SSL_read(SSL* ssl, void *b, int n) const @nogc nothrow {
        return adapter_SSL_read(ssl, b, n);
    }
    int SSL_write(SSL* ssl, const void *b, int n) const @nogc nothrow {
        return adapter_SSL_write(ssl, b, n);
    }
    void SSL_free(SSL* ssl) const @nogc nothrow @trusted {
        adapter_SSL_free(ssl);
    }
    void SSL_CTX_free(SSL_CTX* ctx) const @nogc nothrow @trusted {
        adapter_SSL_CTX_free(ctx);
    }
    int SSL_get_error(SSL* ssl, int err) const @nogc nothrow {
        return adapter_SSL_get_error(ssl, err);
    }
    c_long SSL_set_tlsext_host_name(SSL* ssl, const char* host) const @nogc nothrow {
        enum SSL_CTRL_SET_TLSEXT_HOSTNAME = 55;
        enum TLSEXT_NAMETYPE_host_name = 0;
        return adapter_SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME,TLSEXT_NAMETYPE_host_name, cast(void*)host);
    }
    char* ERR_reason_error_string(c_ulong code) const @nogc nothrow {
        return adapter_ERR_reason_error_string(code);
    }
    c_ulong ERR_get_error() const @nogc nothrow {
        return adapter_ERR_get_error();
    }
}
/*
int main() {
    import std.socket;

    auto v = openssl.reportVersion();
    writefln("openSSL v.%s.%s", v.major, v.minor);
    openssl.SSL_library_init();
    writeln("InitSSL - ok");
    SSL_CTX* ctx = openssl.SSL_CTX_new(openssl.TLSv1_client_method());
    writefln("SSL_CTX_new = %x", ctx);
    int r = openssl.adapter_SSL_CTX_set_default_verify_paths(ctx);
    writefln("SSL_CTX_set_default_verify_paths = %d(%s)", r, r==1?"ok":"fail");
    r = openssl.adapter_SSL_CTX_load_verify_locations(ctx, cast(char*)null, cast(char*)null);
    writefln("SSL_CTX_load_verify_locations - ok");
    openssl.SSL_CTX_set_verify(ctx, 0, null);
    writefln("SSL_CTX_set_verify - ok");
    //r = openssl.SSL_CTX_use_PrivateKey_file(ctx, null, 0);
    //writefln("SSL_CTX_use_PrivateKey_file = %d(%s)", r, r==1?"ok":"fail");
    //r = openssl.SSL_CTX_use_certificate_file(ctx, cast(char*), 0);
    //writefln("SSL_CTX_use_certificate_file = %d(%s)", r, r==1?"ok":"fail");
    SSL* ssl = openssl.SSL_new(ctx);
    writefln("SSL_new = %x", ssl);
    auto s = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
    Address[] a = getAddress("ns.od.ua", 443);
    writeln(a[0]);
    s.connect(a[0]);
    r = openssl.SSL_set_fd(ssl, s.handle);
    writefln("SSL_set_fd = %d(%s)", r, r==1?"ok":"fail");
    r = openssl.SSL_connect(ssl);
    writefln("SSL_connect = %d(%s)", r, r==1?"ok":"fail");
    if ( r < 0 ) {
        writefln("code: %d", openssl.SSL_get_error(ssl, r));
    }
    string req = "GET / HTTP/1.0\n\n";
    r = openssl.SSL_write(ssl, cast(void*)req.ptr, cast(int)req.length);
    writefln("SSL_write = %d", r);
    do {
        ubyte[]  resp = new ubyte[](1024);
        r = openssl.SSL_read(ssl, cast(void*)resp.ptr, cast(int)1024);
        writefln("SSL_read = %d", r);
        if ( r > 0 ) {
            writeln(cast(string)resp);
        }
    } while(r > 0);
    openssl.SSL_free(ssl);
    openssl.SSL_CTX_free(ctx);
    s.close();
    return 0;
}
*/
