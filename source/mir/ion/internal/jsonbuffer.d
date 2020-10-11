module mir.ion.internal.jsonbuffer;

version(LDC)
{
    import ldc.attributes: optStrategy;
    enum minsize = optStrategy("minsize");

    static if (__traits(targetHasFeature, "sse4.2"))
    {
        import ldc.simd;
        import ldc.gccbuiltins_x86;
        version = SSE42;
    }
}
else
{
    enum minsize;
}

package(mir.ion) struct JsonBuffer(Dg)
{
    Dg sink;
    // current buffer length
    size_t length;

    char[4096 * 4] buffer = void;

    /+
    Puts char
    +/
    void put(char c)
    {
        if(length == buffer.length)
        {
            flush;
        }
        buffer[length++] = c;
    }

    /+
    Uses compile time loop for values `null`, `true`, `false`
    +/
    void put(string str)()
    {
        size_t newLength = length + str.length;
        if(newLength > buffer.length)
        {
            flush;
            newLength = str.length;
        }
        import mir.internal.utility;
        // compile time loop
        foreach(i; Iota!(0, str.length))
            buffer[length + i] = str[i];
        length = newLength;
    }

    /+
    Puts key/number
    +/
    void putSmallEscaped(in char[] str)
    {
        assert(str.length <= ubyte.max);
        size_t newLength = length + str.length;
        if(newLength > buffer.length)
        {
            flush;
            newLength = str.length;
        }
        buffer[length .. newLength] = str;
        length = newLength;
    }

    /++
    Decodes byte `b` to the form `u00XX`, where `XX` is 2 hexadecimal characters.
    +/
    private void putUnicode(ubyte b)
    {
        buffer[length + 0] = 'u';
        buffer[length + 1] = '0';
        buffer[length + 2] = '0';
        ubyte[2] spl;
        spl[0] = b >> 4;
        spl[1] = b & 0xF;
        buffer[length + 3] = cast(ubyte)(spl[0] < 10 ? spl[0] + '0' : spl[0] - 10 + 'A');
        buffer[length + 4] = cast(ubyte)(spl[1] < 10 ? spl[1] + '0' : spl[1] - 10 + 'A');
        length += 5;
    }

    /+
    Puts string
    +/
    void put(in char[] str)
    {
        import std.range: chunks;
        import std.string: representation;

        version(SSE42)
        {
            alias ubyte16 = __vector(ubyte[16]);
            import ldc.simd;
            import ldc.gccbuiltins_x86;

            enum byte16 str2E = [
                '\u0001', '\u001F',
                '\"', '\"',
                '\\', '\\',
                '\u007f', '\u007f',
                '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0'];
            enum byte16 str3E = ['\"', '\\', '\b', '\f', '\n', '\r', '\t', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0'];
            byte16 str2 = str2E;
            byte16 str3 = str3E;

            static immutable emap = ['\"', '\\', 'b', 'f', 'n', 'r', 't'];

            for(auto d = str.representation; d.length;)
            {
                if(length + 21 > buffer.length)
                {
                    flush;
                }
                int ecx = void;
                byte16 str1 = void;
                if(d.length >= 16)
                {
                    str1 = loadUnaligned!ubyte16(cast(ubyte*) d.ptr);
                    storeUnaligned!ubyte16(str1, cast(ubyte*) buffer.ptr + length);
                    auto cflag = __builtin_ia32_pcmpistric128(str2, str1, 0x04);
                    ecx =        __builtin_ia32_pcmpistri128 (str2, str1, 0x04);
                    d = d[ecx .. $];
                    length += ecx;
                    if(ecx == 16)
                        continue;
                }
                else
                {
                    str1 ^= str1;
                    switch(d.length)
                    {
                        default   : goto case;
                        case 0xE+1: str1.array[0xE] = d[0xE]; goto case;
                        case 0xD+1: str1.array[0xD] = d[0xD]; goto case;
                        case 0xC+1: str1.array[0xC] = d[0xC]; goto case;
                        case 0xB+1: str1.array[0xB] = d[0xB]; goto case;
                        case 0xA+1: str1.array[0xA] = d[0xA]; goto case;
                        case 0x9+1: str1.array[0x9] = d[0x9]; goto case;
                        case 0x8+1: str1.array[0x8] = d[0x8]; goto case;
                        case 0x7+1: str1.array[0x7] = d[0x7]; goto case;
                        case 0x6+1: str1.array[0x6] = d[0x6]; goto case;
                        case 0x5+1: str1.array[0x5] = d[0x5]; goto case;
                        case 0x4+1: str1.array[0x4] = d[0x4]; goto case;
                        case 0x3+1: str1.array[0x3] = d[0x3]; goto case;
                        case 0x2+1: str1.array[0x2] = d[0x2]; goto case;
                        case 0x1+1: str1.array[0x1] = d[0x1]; goto case;
                        case 0x0+1: str1.array[0x0] = d[0x0]; goto case;
                        case 0x0  : break;
                    }
                    storeUnaligned!ubyte16(str1, cast(ubyte*) buffer.ptr + length);
                    auto cflag = __builtin_ia32_pcmpistric128(str2, str1, 0x04);
                    ecx =        __builtin_ia32_pcmpistri128 (str2, str1, 0x04);
                    if(!cflag)
                    {
                        length += d.length;
                        break;
                    }
                    d = d[ecx .. $];
                    length += ecx;
                }

                int eax = ecx + 1;
                auto cflag = __builtin_ia32_pcmpestric128(str1, eax, str3, emap.length, 0x00);
                auto edx =        __builtin_ia32_pcmpestri128 (str1, eax, str3, emap.length, 0x00);
                d = d[1 .. $];
                buffer[length + 0] = '\\';
                if(cflag)
                {
                    buffer[length + 1] = emap[edx];
                    length += 2;
                    continue;
                }
                length += 1;
                putUnicode(str1.array[ecx]);
            }
        }
        else
        {
            foreach(chunk; str.representation.chunks(256))
            {
                if(chunk.length * 2 + length + 16 > buffer.length)
                {
                    flush;
                }
                foreach(size_t i, char e; chunk)
                {
                    switch(e)
                    {
                        case '\b':
                            buffer[length + 0] = '\\';
                            buffer[length + 1] = 'b';
                            length += 2;
                            continue;
                        case '\f':
                            buffer[length + 0] = '\\';
                            buffer[length + 1] = 'f';
                            length += 2;
                            continue;
                        case '\n':
                            buffer[length + 0] = '\\';
                            buffer[length + 1] = 'n';
                            length += 2;
                            continue;
                        case '\r':
                            buffer[length + 0] = '\\';
                            buffer[length + 1] = 'r';
                            length += 2;
                            continue;
                        case '\t':
                            buffer[length + 0] = '\\';
                            buffer[length + 1] = 't';
                            length += 2;
                            continue;
                        case '\\':
                            buffer[length + 0] = '\\';
                            buffer[length + 1] = '\\';
                            length += 2;
                            continue;
                        case '\"':
                            buffer[length + 0] = '\\';
                            buffer[length + 1] = '\"';
                            length += 2;
                            continue;
                        case '\0': .. case '\u0007':
                        case '\u000e': .. case '\u001f':
                        case '\u000b':
                        case '\u00ff':
                            buffer[length + 0] = '\\';
                            length++;
                            putUnicode(e);
                            if(chunk.length * 2 + length + 16 > buffer.length)
                            {
                                flush;
                            }
                            continue;
                        default:
                            buffer[length] = e;
                            length++;
                    }
                }
            }
        }
    }

    /+
    Sends remaining data to `sink`.
    +/
    void flush()
    {
        sink(buffer[0 .. length]);
        length = 0;
    }
}
