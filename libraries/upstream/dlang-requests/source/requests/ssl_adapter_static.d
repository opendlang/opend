module requests.ssl_adapter_static;

version(staticssl):

import std.typecons;
import core.stdc.stdlib;
import core.stdc.config;

version(Windows) {
    static assert("static build not implemented for windows");
}

struct SSL {};
struct SSL_CTX {};
struct SSL_METHOD {};

immutable int TLS_ANY_VERSION = 0x10000;
immutable int TLS1_VERSION = 0x0301;
immutable int TLS1_2_VERSION = 0x0303;

private alias Version = Tuple!(int, "major", int, "minor");

struct openssl {
    static Version reportVersion() @nogc nothrow pure {
        return OpenSSL_version_detect();
    }

    static private Version OpenSSL_version_detect() @nogc nothrow pure {
        auto v = OpenSSL_version_num() & 0xffffffff;
        return Version((v>>>20) & 0xff, (v>>>28) & 0xff);
    }

    static int SSL_CTX_set_min_proto_version(SSL_CTX* ctx, int v) @nogc nothrow {
        int r = cast(int)SSL_CTX_ctrl(ctx, SSL_CTRL_SET_MIN_PROTO_VERSION, cast(c_long)v, null);
        return r;
    }
    static int SSL_CTX_set_max_proto_version(SSL_CTX* ctx, int v) @nogc nothrow {
        int r = cast(int)SSL_CTX_ctrl(ctx, SSL_CTRL_SET_MAX_PROTO_VERSION, cast(c_long)v, null);
        return r;
    }

    static c_long SSL_set_tlsext_host_name(SSL* ssl, const char* host) @nogc nothrow {
        enum SSL_CTRL_SET_TLSEXT_HOSTNAME = 55;
        enum TLSEXT_NAMETYPE_host_name = 0;
        return SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME,TLSEXT_NAMETYPE_host_name, cast(void*)host);
    }
    // extern (C) {
        alias SSL_library_init = .SSL_library_init;
        alias OpenSSL_add_all_ciphers = .OpenSSL_add_all_ciphers;
        alias OpenSSL_add_all_digests = .OpenSSL_add_all_digests;
        alias OpenSSL_version_num = .OpenSSL_version_num;
        alias SSL_load_error_strings = .SSL_load_error_strings;
        alias OPENSSL_init_ssl = .OPENSSL_init_ssl;
        alias OPENSSL_init_crypto = .OPENSSL_init_crypto;
        alias TLSv1_client_method = .TLSv1_client_method;
        alias TLSv1_2_client_method = .TLSv1_2_client_method;
        alias SSLv23_client_method = .SSLv23_client_method;
        alias TLS_method = .TLS_method;
        alias SSL_CTX_new = .SSL_CTX_new;
        alias SSL_CTX_set_default_verify_paths = .SSL_CTX_set_default_verify_paths;
        alias SSL_CTX_load_verify_locations = .SSL_CTX_load_verify_locations;
        alias SSL_CTX_set_verify = .SSL_CTX_set_verify;
        alias SSL_CTX_use_PrivateKey_file = .SSL_CTX_use_PrivateKey_file;
        alias SSL_CTX_use_certificate_file = .SSL_CTX_use_certificate_file;
        alias SSL_CTX_set_cipher_list = .SSL_CTX_set_cipher_list;

        /*
         *
         * # define SSL_CTRL_SET_MIN_PROTO_VERSION          123
         * # define SSL_CTRL_SET_MAX_PROTO_VERSION          124
         */
        enum int SSL_CTRL_SET_MIN_PROTO_VERSION = 123;
        enum int SSL_CTRL_SET_MAX_PROTO_VERSION = 124;
        alias SSL_new = .SSL_new;
        alias SSL_set_fd = .SSL_set_fd;
        alias SSL_connect = .SSL_connect;
        alias SSL_read = .SSL_read;
        alias SSL_write = .SSL_write;
        alias SSL_free = .SSL_free;
        alias SSL_CTX_free = .SSL_CTX_free;
        alias SSL_get_error = .SSL_get_error;
        alias ERR_reason_error_string = .ERR_reason_error_string;
        alias ERR_get_error = .ERR_get_error;
        alias SSL_CTX_ctrl = .SSL_CTX_ctrl;
        alias SSL_ctrl = .SSL_ctrl;
    // }
}

extern (C) {
    static int SSL_library_init() @nogc nothrow @trusted;
    static void OpenSSL_add_all_ciphers() @nogc nothrow @trusted;
    static void OpenSSL_add_all_digests() @nogc nothrow @trusted;
    static c_ulong OpenSSL_version_num() @nogc nothrow @trusted pure;
    static void SSL_load_error_strings() @nogc nothrow @trusted;
    static int OPENSSL_init_ssl(ulong, void*) @nogc nothrow @trusted;
    static int OPENSSL_init_crypto(ulong, void*) @nogc nothrow @trusted;
    static SSL_METHOD* TLSv1_client_method() nothrow @trusted;
    static SSL_METHOD* TLSv1_2_client_method() nothrow @trusted;
    static SSL_METHOD* SSLv23_client_method() nothrow @trusted;
    static SSL_METHOD* TLS_method() nothrow @trusted;
    static SSL_CTX* SSL_CTX_new(SSL_METHOD* method) @nogc nothrow @trusted;
    static int SSL_CTX_set_default_verify_paths(SSL_CTX* ctx) @nogc nothrow;
    static int SSL_CTX_load_verify_locations(SSL_CTX* ctx, char* CAFile, char* CAPath) @nogc nothrow;
    static void SSL_CTX_set_verify(SSL_CTX* ctx, int mode, void* callback) @nogc nothrow;
    static int SSL_CTX_use_PrivateKey_file(SSL_CTX* ctx, const char* file, int type) @nogc nothrow;
    static int SSL_CTX_use_certificate_file(SSL_CTX* ctx, const char* file, int type) @nogc nothrow;
    static int SSL_CTX_set_cipher_list(SSL_CTX* ssl_ctx, const char* c) @nogc nothrow;

    /*
     *
     * # define SSL_CTRL_SET_MIN_PROTO_VERSION          123
     * # define SSL_CTRL_SET_MAX_PROTO_VERSION          124
     */
    enum int SSL_CTRL_SET_MIN_PROTO_VERSION = 123;
    enum int SSL_CTRL_SET_MAX_PROTO_VERSION = 124;
    static SSL* SSL_new(SSL_CTX* ctx) @nogc nothrow;
    static int SSL_set_fd(SSL* ssl, int fd) @nogc nothrow;
    static int SSL_connect(SSL* ssl) @nogc nothrow;
    static int SSL_read(SSL* ssl, void *b, int n) @nogc nothrow;
    static int SSL_write(SSL* ssl, const void *b, int n) @nogc nothrow;
    static void SSL_free(SSL* ssl) @nogc nothrow @trusted;
    static void SSL_CTX_free(SSL_CTX* ctx) @nogc nothrow @trusted;
    static int SSL_get_error(SSL* ssl, int err) @nogc nothrow;
    static char* ERR_reason_error_string(c_ulong code) @nogc nothrow;
    static c_ulong ERR_get_error() @nogc nothrow;
    static c_ulong SSL_CTX_ctrl(SSL_CTX*, int, c_long, void*) @nogc nothrow;
    static c_ulong SSL_ctrl(SSL*, int, c_long, void*) @nogc nothrow;
}
