module requests.idna.punycode.codec;

/***********************************************************
 * Adapted from https://gist.github.com/bnoordhuis/1035947 *
 ***********************************************************/

import std.stdio;
import std.uni;
import std.ascii;
import std.exception;
import std.typecons;
import std.algorithm;
import std.functional;
import std.array;
import std.format;
import std.conv;
import std.utf;
import std.exception;
import std.string;

enum base = 36,
     tmin = 1, tmax = 26,
     skew = 38, damp = 700,
     initial_bias = 72,
     initial_n = 0x80,
     delimiter = 0x2D,
     unicode_max = 0x11_0000;

class DecodeException: Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) pure @safe {
        super(msg, file, line);
    }
}

size_t next_smallest_codepoint(in uint[] extended, size_t n) pure nothrow @safe @nogc {
    size_t m = unicode_max; // Unicode's upper bound + 1

    foreach(c; extended) {
        if ( c >= n &&  c < m ) {
            m = c;
        }
    }
    assert(m < 0x110000);
    return m;
}

uint encode_digit(size_t d) pure nothrow @safe @nogc {
    assert(d < base);
    return cast(uint)(d + (d < 26 ? 97 : 22));
}

uint decode_digit(uint d) pure @safe {
    if ( d >= 48 && d <= 57 ) {
        return d - 22; // 0..9
    }
    if ( d >= 65 && d <= 90 ) {
        return d - 65; // A..Z
    }
    if ( d >= 97 && d <= 122 ) {
        return d - 97; // a..z
    }
    throw new DecodeException("unexpected symbod %c while decoding".format(cast(dchar)d));
}

size_t threshold(size_t k, size_t bias) pure nothrow @safe @nogc {
    if ( k <= bias + tmin ) {
        return tmin;
    }
    if ( k >= bias + tmax ) {
        return tmax;
    }
    return k - bias;
}

size_t adapt_bias(size_t delta, size_t n_points, bool is_first) pure nothrow @safe @nogc {
    delta  = delta / (is_first ? damp : 2);
    delta += delta / n_points;

    immutable s = (base - tmin);
    immutable t = (s * tmax) / 2; // threshold=455
    auto k = 0;

    while (delta > t) {
        delta = delta / s;
        k += base;
    }
    auto a = (base - tmin + 1) * delta;
    auto b = (delta + skew);

    return k + (a / b);
}

uint[] encode_int(size_t bias, size_t delta) pure nothrow @safe {
    uint[] result;

    size_t k = base;
    size_t q = delta;

    while ( true ) {
        immutable size_t t = threshold(k, bias);
        if ( q < t ) {
            result ~= encode_digit(q);
            break;
        }
        auto c = t + ((q - t) % (base - t));
        q = (q - t) / (base - t);
        k += base;
        result ~= encode_digit(c);
    }
    return result;
}

string encode(string input) pure @safe nothrow {
    immutable uint[] source = input.byUTF!dchar.map!(c => cast(uint)c).array;
    immutable uint[] extended = source.filter!(not!isASCII).array;
    if ( extended.length == 0 ) {
        return input;
    }
    immutable uint[] basic = source.filter!isASCII.array;
    auto b = basic.length;
    auto h = b;

    size_t n = initial_n;
    size_t bias = initial_bias;
    size_t delta = 0;

    char[] output = basic.map!(c => cast(char)c).array;

    if ( output.length ) {
        output ~= cast(uint)'-';
    }

    while ( h < source.length ) {
        immutable size_t m = next_smallest_codepoint(extended, n);
        delta += (m - n) * (h + 1);
        n = m;
        foreach(c; source) {
            if ( c < n) {
                delta++;
                // TODO check overflow
            }
            if ( c == n ) {
                auto e = encode_int(bias, delta);
                output ~= e.map!(c => cast(char)c).array;
                bias = adapt_bias(delta, h + 1, b == h);
                delta = 0;
                h++;
            }
        }
        delta++;
        n++;
    }
    return to!string(output);
}

string decode(string input) pure @safe {

    auto b = input.lastIndexOf('-') + 1;
    immutable uint[] source = input.byUTF!char.map!(c => cast(uint)c).array;
    uint[]           output = b > 0 ? source[0..b-1].dup : [];

    size_t i = 0;
    size_t n = initial_n;
    size_t bias = initial_bias;

    while (b < source.length) {
        size_t org_i = i;
        size_t k = base;
        size_t w = 1;

        while ( true ) {
            if ( b >= source.length ) {
                throw new DecodeException("Got overflow decoding string %s".format(input));
            }
            immutable next_digit = source[b];
            if (!next_digit.isASCII ) {
                throw new DecodeException("Trying to decode improper code %d".format(next_digit));
            }
            immutable d = decode_digit(source[b]);
            b += 1;

            // TODO overflow check
            i += d * w;

            immutable t = threshold(k, bias);
            if ( d < t ) {
                break;
            }
            // TODO overflow check
            w *= base - t;
            k += base;
        }
        size_t x = 1 + output.length;
        bias = adapt_bias(i - org_i, x, org_i == 0);

        n += i / x;
        i %= x;
        if ( n >= unicode_max ) {
            throw new DecodeException("Got overflow decoding string %s".format(input));
        }
        output.insertInPlace(i, cast(uint)n);
        i += 1;
    }
    return output.map!(c => cast(dchar)c).toUTF8;
}

unittest {
    import std.algorithm.comparison;

    auto pairs = [
        ["пpи-вeт", "p-e-gdd2a4b0a"],
        ["bücher", "bcher-kva"],
        ["а2б1￠𓃰", "21-6kcf07233afs7b"],
        ["例子", "fsqu00a"],
        ["उदाहरण", "p1b6ci4b4b3a"],
        ["παράδειγμα", "hxajbheg2az3al"],
        ["실례", "9n2bp8q"],
        ["例え", "r8jz45g"],
        ["உதாரணம்", "zkc6cc5bi7f6e"]
    ];
    foreach(p; pairs) {
        assert(encode(p[0]) == p[1]);
        assert(decode(p[1]) == p[0]);
    }
    assertThrown!DecodeException(decode("99999999999")); // overflow
    assertThrown!DecodeException(decode("1𓃰2𓃰3𓃰")); // not a valid string to decode
    assertThrown!DecodeException(decode("ab+"));         // not a valid string to decode
}