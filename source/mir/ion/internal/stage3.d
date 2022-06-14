module mir.ion.internal.stage3;

import core.stdc.string: memcpy, memmove;
import mir.internal.memory: malloc, realloc, free;
import mir.bitop;
import mir.ion.exception;
import mir.ion.symbol_table;
import mir.ion.tape;
import mir.ion.type_code;
import mir.primitives;
import mir.utility: _expect;
import std.meta: AliasSeq, aliasSeqOf;
import std.traits;

///
struct IonErrorInfo
{
    ///
    IonErrorCode code;
    ///
    size_t location;
    /// refers tape or text
    const(char)[] key;
}

// version = MirDecimalJson;

alias Stage3Handle = void delegate(IonErrorInfo, scope const ubyte[]) @safe pure nothrow @nogc;

@trusted pure nothrow @nogc
bool stage12(
    scope const(char)[] text,
    scope ulong[2]* pairedMask1,
    scope ulong[2]* pairedMask2,
)
{
    pragma(inline, false);
    import core.stdc.string: memcpy;
    import mir.ion.internal.stage1;
    import mir.ion.internal.stage2;

    // assume 32KB L1 data cache
    // 32 * 2 / 5 > 12.5
    enum nMax = 1024 * 12 + 512;
    enum k = nMax / 64;

    bool backwardEscapeBit;
    align(64) ubyte[64][k] vector = void;

    while (text.length >= nMax)
    {
        memcpy(vector.ptr, text.ptr, nMax);
        stage1(k, cast(const) vector.ptr, pairedMask1, backwardEscapeBit);
        stage2(k, cast(const) vector.ptr, pairedMask2);
        text = text[nMax .. $];
        pairedMask1 += k;
        pairedMask2 += k;
    }

    if (text.length)
    {
        auto y = text.length / 64;
        if (auto tail = text.length % 64)
            vector[y++] = ' ';
        memcpy(vector.ptr, text.ptr, text.length);
        stage1(y, cast(const) vector.ptr, pairedMask1, backwardEscapeBit);
        stage2(y, cast(const) vector.ptr, pairedMask2);
    }

    return backwardEscapeBit;
}

struct Stage3Result
{
    ubyte[] tape;
    IonErrorInfo info;
}

@trusted pure nothrow @nogc
void stage3(
    scope const(char)[] text,
    scope Stage3Handle handle,
)
{
    version (LDC) pragma(inline, false);
    with(stage3(text))
    {
        version (measure) StopWatch swh;
        version (measure) assumePure(&swh.start)();
        scope(exit)
            tape.ptr.free;
        handle(info, tape);
        version (measure) assumePure(&swh.stop)();
        version (measure) assumePure(&printSw)(swh);
    }
}

@trusted pure nothrow @nogc
Stage3Result stage3(
    scope const(char)[] text,
)
{
    version (LDC) pragma(inline, false);

    import core.stdc.string: memcpy;
    import mir.utility: _expect, min, max;

    IonSymbolTableSequental symbolTable = void;
    symbolTable.initialize;

    ubyte[] tape;
    size_t currentTapePosition;
    ulong[2]* pairedMask1 = void;
    ulong[2]* pairedMask2 = void;
    // const(char)[] key; // Last key, it is the reference to the tape
    // size_t location;
    IonErrorCode errorCode;

    // vector[$ - 1] = ' ';
    // pairedMask1[$ - 1] = [0UL,  0UL];
    // pairedMask2[$ - 1] = [0UL,  ulong.max];

    version (measure) StopWatch swm;
    version (measure) assumePure(&swm.start)();

    size_t[1024] stack = void;
    sizediff_t stackPos = stack.length;

    bool skipSpaces()
    {
        version(LDC) pragma(inline, true);
        while (text.length)
        {
            auto index = text.length - 1;
            auto indexG = index >> 6;
            auto indexL = index & 0x3F;
            auto spacesMask = pairedMask2[indexG][1] << (63 - indexL);
            if (spacesMask != 0)
            {
                assert(ctlz(spacesMask) < text.length);
                text = text[0 .. $ - cast(size_t)ctlz(spacesMask)];
                return false;
            }
            text = text[0 .. index & ~0x3FUL];
        }
        return true;
    }

    int readUnicode()(ref dchar d, scope const(char)* ptr)
    {
        version(LDC) pragma(inline, true);

        uint e = 0;
        size_t i = 4;
        do
        {
            int c = uniFlags[*ptr++];
            assert(c < 16);
            if (c == -1)
                return -1;
            assert(c >= 0);
            e <<= 4;
            e ^= c;
        }
        while(--i);
        d = e;
        return 0;
    }

    size_t maskLength = text.length / 64 + (text.length % 64 != 0);
    currentTapePosition = text.length + 1024u + maskLength * (ulong[2]).sizeof;
    tape = (cast(ubyte*) malloc(currentTapePosition))[0 .. currentTapePosition];

    pairedMask1 = cast(ulong[2]*) tape.ptr;
    pairedMask2 = pairedMask1 + maskLength;

    if (stage12(text, pairedMask1, pairedMask2))
        goto unexpectedEnd;


    for (;;)
    {
        if (skipSpaces)
        {
            if (stackPos == stack.length)
                break;
            else
                goto unexpectedEnd;
        }
Next:
        auto startC = text[$ - 1];

        switch(startC)
        {
            case '"':
            {
                text = text[0 .. $ - 1];
                size_t oldTapePosition = currentTapePosition;
                for (;;)
                {
                    char[64] _textBuffer = void;
                    if (_expect(text.length < _textBuffer.length, false))
                    {
                        memcpy(_textBuffer.ptr + _textBuffer.length - text.length, text.ptr, text.length);
                        text = _textBuffer[$ - text.length .. $];
                    }
                    size_t index = text.length - 1;
                    auto indexG = index >> 6;
                    auto indexL = index & 0x3F;
                    auto quoteMask = pairedMask1[indexG][0] << (63 - indexL);
                    auto escapeMask = pairedMask1[indexG][1] << (63 - indexL);
                    auto mask = quoteMask | escapeMask;
                    memcpy(tape.ptr + currentTapePosition - 64, text.ptr + text.length - 64, 64);
                    if (mask != 0)
                    {
                        assert(text.length > ctlz(mask));
                        auto shift = cast(size_t)ctlz(mask);
                        text = text[0 .. $ - shift];
                        currentTapePosition -= shift;
                        if (_expect(quoteMask > escapeMask, true))
                        {
                            assert(text[$ - 1] == '"', text);
                            currentTapePosition -= ionPutEndR(tape.ptr + currentTapePosition, IonTypeCode.string, oldTapePosition - currentTapePosition);
                            text = text[0 .. $ - 1];
                            break;
                        }
                        else
                        {
                            assert(text.length >= 2);
                            auto c = text[$ - 1];
                            assert(text[$ - 2] == '\\', text[$ - min($, 40u) .. $]);
                            text = text[0 .. $ - 2];
                            --currentTapePosition;

                            switch (c)
                            {
                                case '/' :
                                case '\"':
                                case '\\': tape[currentTapePosition] =   c ; continue;
                                case 'b' : tape[currentTapePosition] = '\b'; continue;
                                case 'f' : tape[currentTapePosition] = '\f'; continue;
                                case 'n' : tape[currentTapePosition] = '\n'; continue;
                                case 'r' : tape[currentTapePosition] = '\r'; continue;
                                case 't' : tape[currentTapePosition] = '\t'; continue;
                                case 'u' :
                                    dchar d;
                                    if (oldTapePosition - currentTapePosition < 4)
                                        goto unexpected_escape_unicode_value; //unexpected \u
                                    currentTapePosition += 4;
                                    if (auto r = readUnicode(d, text.ptr + text.length + 2))
                                        goto unexpected_escape_unicode_value; //unexpected \u
                                    if (_expect(0xD800 <= d && d <= 0xDFFF, false))
                                    {
                                        if (d < 0xDC00)
                                            goto invalid_utf_value;
                                        if (text.length < 6 || text[$ - 6 .. $ - 4] != `\u`)
                                            goto invalid_utf_value;
                                        dchar trailing = d;
                                        if (auto r = readUnicode(d, text.ptr + text.length - 4))
                                            goto unexpected_escape_unicode_value; //unexpected \u
                                        if (!(0xD800 <= d && d <= 0xDFFF))
                                            goto invalid_trail_surrogate;
                                        text = text[0 .. $ - 6];
                                        d &= 0x3FF;
                                        trailing &= 0x3FF;
                                        d <<= 10;
                                        d |= trailing;
                                        d += 0x10000;
                                    }
                                    if (d < 0x80)
                                    {
                                        tape[currentTapePosition] = cast(ubyte) (d);
                                        continue;
                                    }
                                    if (d < 0x800)
                                    {
                                        tape[currentTapePosition - 1] = cast(ubyte) (0xC0 | (d >> 6));
                                        tape[currentTapePosition - 0] = cast(ubyte) (0x80 | (d & 0x3F));
                                        currentTapePosition -= 1;
                                        continue;
                                    }
                                    if (!(d < 0xD800 || (d > 0xDFFF && d <= 0x10FFFF)))
                                        goto invalid_trail_surrogate;
                                    if (d < 0x10000)
                                    {
                                        tape[currentTapePosition - 2] = cast(ubyte) (0xE0 | (d >> 12));
                                        tape[currentTapePosition - 1] = cast(ubyte) (0x80 | ((d >> 6) & 0x3F));
                                        tape[currentTapePosition - 0] = cast(ubyte) (0x80 | (d & 0x3F));
                                        currentTapePosition -= 2;
                                        continue;
                                    }
                                    //    assert(d < 0x200000);
                                    tape[currentTapePosition - 3] = cast(ubyte) (0xF0 | (d >> 18));
                                    tape[currentTapePosition - 2] = cast(ubyte) (0x80 | ((d >> 12) & 0x3F));
                                    tape[currentTapePosition - 1] = cast(ubyte) (0x80 | ((d >> 6) & 0x3F));
                                    tape[currentTapePosition - 0] = cast(ubyte) (0x80 | (d & 0x3F));
                                    currentTapePosition -= 3;
                                    continue;
                                default:
                                    goto unexpected_escape_value; // unexpected escape
                            }
                        }
                    }
                    size_t newTextLength = index & ~size_t(0x3F);
                    currentTapePosition -= text.length - newTextLength;
                    text = text[0 .. newTextLength];
                }
            }
            break;
            case '0': .. case '9':
            {
                size_t stringStart = text.length;
                for (;;)
                {
                    // FFFFFFFFFFFFFFD1
                    // {"a":3}
                    auto index = stringStart - 1; //5
                    auto indexG = index >> 6;
                    auto indexL = index & 0x3F;
                    auto spacesMask = pairedMask2[indexG][0] << (63 - indexL);
                    if (spacesMask != 0)
                    {
                        assert(stringStart >= ctlz(spacesMask), text);
                        stringStart -= ctlz(spacesMask);
                        break;
                    }
                    stringStart = index & ~0x3FUL;
                    if (stringStart == 0)
                        break;
                }

                auto str = text[stringStart .. $];
                text = text[0 .. stringStart];

                import mir.bignum.internal.parse: parseJsonNumberImpl;
                auto result = str.parseJsonNumberImpl;
                if (!result.success)
                    goto unexpected_decimal_value;

                if (!result.key) // integer
                {
                    currentTapePosition -= ionPutR(tape.ptr + currentTapePosition, result.coefficient, result.coefficient && result.sign);
                }
                else
                version(MirDecimalJson)
                {
                    currentTapePosition -= ionPutDecimalR(tape.ptr + currentTapePosition, result.sign, result.coefficient, result.exponent);
                }
                else
                {
                    import mir.bignum.internal.dec2float: decimalToFloatImpl;
                    auto fp = decimalToFloatImpl!double(result.coefficient, result.exponent);
                    if (result.sign)
                        fp = -fp;
                    // sciencific
                    currentTapePosition -= ionPutR(tape.ptr + currentTapePosition, fp);
                }
            }
            break;
            case '}':
            {
                text = text[0 .. $ - 1];
                assert(stackPos <= stack.length);

                if (skipSpaces)
                    goto unexpectedEnd;

                if (text[$ - 1] != '{')
                {
                    if (--stackPos < 0)
                        goto stack_overflow;
                    stack[stackPos] = (currentTapePosition << 1) | 1;
                    goto Next;
                }
                text = text[0 .. $ - 1];
                tape[--currentTapePosition] = IonTypeCode.struct_ << 4;
            }
            break;
            case ']':
            {
                text = text[0 .. $ - 1];
                assert(stackPos <= stack.length);

                if (skipSpaces)
                    goto unexpectedEnd;

                if (text[$ - 1] != '[')
                {
                    if (--stackPos < 0)
                        goto stack_overflow;
                    stack[stackPos] = (currentTapePosition << 1) | 0;
                    goto Next;
                }
                text = text[0 .. $ - 1];
                tape[--currentTapePosition] = IonTypeCode.list << 4;
            }
            break;
            case 'e':
                currentTapePosition--;
                if (text.length >= 4 && text[$ - 4 .. $] == "true")
                {
                    ionPut(tape.ptr + currentTapePosition, true);
                    text = text[0 .. $ - 4];
                    break;
                }
                else
                if (text.length >= 5 && text[$ - 5 .. $ - 1] == "fals")
                {
                    ionPut(tape.ptr + currentTapePosition, false);
                    text = text[0 .. $ - 5];
                    break;
                }
                else goto default;
            case 'l':
                currentTapePosition--;
                ionPut(tape.ptr + currentTapePosition, null);
                if (text.length >= 4 && text[$ - 4 .. $] == "null")
                {
                    text = text[0 .. $ - 4];
                    break;
                }
                else goto default;
            default:
                goto value_unexpectedStart;
        }

        for(;;)
        {
            if (stackPos == stack.length)
                break;

            // put key
            if (stack[stackPos] & 1)
            {
                if (skipSpaces)
                    goto unexpectedEnd;
                if (text[$ - 1] != ':')
                    goto object_after_key_is_missing;
                text = text[0 .. $ - 1];
                if (skipSpaces)
                    goto unexpectedEnd;

                if (text[$ - 1] != '"')
                    goto object_key_start_unexpectedValue;
                assert(text[$ - 1] == '"', "Internal Mir Ion logic error. Please report an issue.");
                text = text[0 .. $ - 1];

                size_t stringStart = text.length;
                for (;;)
                {
                    auto index = stringStart - 1;
                    auto indexG = index >> 6;
                    auto indexL = index & 0x3F;
                    auto spacesMask = pairedMask1[indexG][0] << (63 - indexL);
                    if (spacesMask != 0)
                    {
                        stringStart -= ctlz(spacesMask);
                        break;
                    }
                    stringStart = index & ~0x3FUL;
                }

                assert(text[stringStart - 1] == '"');
                auto str = text[stringStart .. $];
                text = text[0 .. stringStart - 1];
                auto id = symbolTable.insert(str);
                // TODO find id using the key
                currentTapePosition -= ionPutVarUIntR(tape.ptr + currentTapePosition, id);
            }

            // next 
            if (skipSpaces)
                goto unexpectedEnd;

            assert(stackPos >= 0);
            assert(stackPos < stack.length);

            const v = text[$ - 1];
            text = text[0 .. $ - 1];
            if (v == ',')
            {
                break;
            }
            else
            if (stack[stackPos] & 1)
            {
                if (v != '{')
                    goto unexpectedValue;
                currentTapePosition -= ionPutEndR(tape.ptr + currentTapePosition, IonTypeCode.struct_, (stack[stackPos++] >> 1) - currentTapePosition);
                continue;
            }
            else
            {
                if (v != '[')
                    goto unexpectedValue;
                currentTapePosition -= ionPutEndR(tape.ptr + currentTapePosition, IonTypeCode.list, (stack[stackPos++] >> 1) - currentTapePosition);
                continue;
            }
        }
    }

ret_final:
    {
        symbolTable.finalize;

        import mir.ion.internal.data_holder: ionPrefix;
        auto extendLength = symbolTable.serializer.data.length + ionPrefix.length;
        if (_expect(currentTapePosition < extendLength, false))
            tape = (cast(ubyte*) realloc(tape.ptr, tape.length + extendLength - currentTapePosition))[0 .. tape.length + extendLength - currentTapePosition];
        memmove(tape.ptr + extendLength, tape.ptr + currentTapePosition, tape.length - currentTapePosition);
        memcpy(tape.ptr, ionPrefix.ptr, ionPrefix.length);
        memcpy(tape.ptr + ionPrefix.length, symbolTable.serializer.data.ptr, symbolTable.serializer.data.length);
        tape = tape[0 .. $ + extendLength - currentTapePosition];
        // tape = (cast(ubyte*)tape.ptr.realloc(tape.length))[0 .. tape.length];
        version (measure) assumePure(&swm.stop)();
        version (measure) assumePure(&printSw)(swm);
        return Stage3Result(tape, IonErrorInfo(errorCode, text.length, /+key+/null));
    }

errorReadingFile:
    errorCode = IonErrorCode.errorReadingFile;
    goto ret_final;
cant_insert_key:
    errorCode = IonErrorCode.symbolTableCantInsertKey;
    goto ret_final;
unexpected_comma:
    errorCode = IonErrorCode.unexpectedComma;
    goto ret_final;
unexpectedEnd:
    errorCode = IonErrorCode.jsonUnexpectedEnd;
    goto ret_final;
unexpectedValue:
    errorCode = IonErrorCode.jsonUnexpectedValue;
    goto ret_final;
integerOverflow:
    errorCode = IonErrorCode.integerOverflow;
    goto ret_final;
unexpected_decimal_value:
    // _lastError = "unexpected decimal value";
    goto unexpectedValue;
unexpected_escape_unicode_value:
    // _lastError = "unexpected escape unicode value";
    goto unexpectedValue;
unexpected_escape_value:
    // _lastError = "unexpected escape value";
    goto unexpectedValue;
object_after_key_is_missing:
    // _lastError = "expected ':' after key";
    goto unexpectedValue;
object_key_start_unexpectedValue:
    // _lastError = "expected '\"' when start parsing object key";
    goto unexpectedValue;
key_is_to_large:
    // _lastError = "key length is limited to 255 characters";
    goto unexpectedValue;
next_unexpectedEnd:
    assert(stackPos >= 0);
    assert(stackPos < stack.length);
    goto unexpectedEnd;
next_unexpectedValue:
    assert(stackPos >= 0);
    assert(stackPos < stack.length);
    goto unexpectedValue;
value_unexpectedStart:
    // _lastError = "unexpected character when start parsing JSON value";
    goto unexpectedEnd;
value_unexpectedEnd:
    // _lastError = "unexpected end when start parsing JSON value";
    goto unexpectedEnd;
number_length_unexpectedValue:
    // _lastError = "number length is limited to 255 characters";
    goto unexpectedValue;
object_first_value_start_unexpectedEnd:
    // _lastError = "unexpected end of input data after '{'";
    goto unexpectedEnd;
array_first_value_start_unexpectedEnd:
    // _lastError = "unexpected end of input data after '['";
    goto unexpectedEnd;
false_unexpectedEnd:
    // _lastError = "unexpected end when parsing 'false'";
    goto unexpectedEnd;
false_unexpectedValue:
    // _lastError = "unexpected character when parsing 'false'";
    goto unexpectedValue;
null_unexpectedEnd:
    // _lastError = "unexpected end when parsing 'null'";
    goto unexpectedEnd;
null_unexpectedValue:
    // _lastError = "unexpected character when parsing 'null'";
    goto unexpectedValue;
true_unexpectedEnd:
    // _lastError = "unexpected end when parsing 'true'";
    goto unexpectedEnd;
true_unexpectedValue:
    // _lastError = "unexpected character when parsing 'true'";
    goto unexpectedValue;
string_unexpectedEnd:
    // _lastError = "unexpected end when parsing string";
    goto unexpectedEnd;
string_unexpectedValue:
    // _lastError = "unexpected character when parsing string";
    goto unexpectedValue;
failed_to_read_after_key:
    // _lastError = "unexpected end after object key";
    goto unexpectedEnd;
unexpected_character_after_key:
    // _lastError = "unexpected character after key";
    goto unexpectedValue;
string_length_is_too_large:
    // _lastError = "string size is limited to 2^32-1";
    goto unexpectedValue;
invalid_trail_surrogate:
    // _lastError = "invalid UTF-16 trail surrogate";
    goto unexpectedValue;
invalid_utf_value:
    // _lastError = "invalid UTF value";
    goto unexpectedValue;
stack_overflow:
    // _lastError = "overflow of internal stack";
    goto unexpectedValue;
}

private __gshared immutable byte[256] uniFlags = [
 //  0  1  2  3  4  5  6  7    8  9  A  B  C  D  E  F
    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1, // 0
    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1, // 1
    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1, // 2
     0, 1, 2, 3, 4, 5, 6, 7,   8, 9,-1,-1,-1,-1,-1,-1, // 3

    -1,10,11,12,13,14,15,-1,  -1,-1,-1,-1,-1,-1,-1,-1, // 4
    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1, // 5
    -1,10,11,12,13,14,15,-1,  -1,-1,-1,-1,-1,-1,-1,-1, // 6
    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1, // 7

    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1,

    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,-1,-1,-1,
];

@trusted pure nothrow
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @safe pure nothrow handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}

@trusted pure @nogc
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @safe pure @nogc handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}


@trusted pure
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @safe pure handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}


@trusted nothrow @nogc
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @safe nothrow @nogc handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}


@trusted nothrow
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @safe nothrow handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}

@trusted @nogc
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @safe @nogc handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}


@trusted
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @safe handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}


@system pure nothrow @nogc
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @system pure nothrow @nogc handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}

@system pure nothrow
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @system pure nothrow handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}

@system pure @nogc
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @system pure @nogc handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}


@system pure
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @system pure handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}


@system nothrow @nogc
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @system nothrow @nogc handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}


@system nothrow
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @system nothrow handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}

@system @nogc
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @system @nogc handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}


@system
void stage3(
    scope const(char)[] text,
    scope void delegate(IonErrorInfo, scope const ubyte[]) @system handle,
)
{
    stage3(text, cast(Stage3Handle) handle);
}


// version = measure;

version (measure)
{
    import std.datetime.stopwatch;
    import std.traits;
    auto assumePure(T)(T t)
    if (isFunctionPointer!T || isDelegate!T)
    {
        pragma(inline, false);
        enum attrs = functionAttributes!T | FunctionAttribute.pure_ | FunctionAttribute.nogc | FunctionAttribute.nothrow_;
        return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
    }

    void printSw(StopWatch sw)
    {
        import mir.stdio;
        tout << sw.peek << endl;
    }
}

///
version(none) unittest
{
    static ubyte[] jsonToIonTest(scope const(char)[] text)
    @trusted pure
    {
        import mir.serde: SerdeMirException;
        import mir.ion.exception: ionErrorMsg;
        import mir.ion.internal.data_holder;
        import mir.ion.symbol_table;

        enum sizediff_t nMax = 128;

        IonTapeHolder!(nMax * 4) tapeHolder = void;
        tapeHolder.initialize;

        auto errorInfo = stage3!nMax(tapeHolder, text);
        if (errorInfo.code)
            throw new SerdeMirException(errorInfo.code.ionErrorMsg, ". location = ", errorInfo.location, ", last input key = ", errorInfo.key);

        return tapeHolder.data.dup;
    }

    import mir.ion.value;
    import mir.ion.type_code;

    assert(jsonToIonTest("1 2 3") == [0x21, 1, 0x21, 2, 0x21, 3]);
    assert(IonValue(jsonToIonTest("12345")).describe.get!IonUInt.get!ulong == 12345);
    assert(IonValue(jsonToIonTest("-12345")).describe.get!IonNInt.get!long == -12345);
    // assert(IonValue(jsonToIonTest("-12.345")).describe.get!IonDecimal.get!double == -12.345);
    version (MirDecimalJson)
    {
        assert(IonValue(jsonToIonTest("\t \r\n-12345e-3 \t\r\n")).describe.get!IonDecimal.get!double == -12.345);
        assert(IonValue(jsonToIonTest(" -12345e-3 ")).describe.get!IonDecimal.get!double == -12.345);
    }
    else
    {
        assert(IonValue(jsonToIonTest("\t \r\n-12345e-3 \t\r\n")).describe.get!IonFloat.get!double == -12.345);
        assert(IonValue(jsonToIonTest(" -12345e-3 ")).describe.get!IonFloat.get!double == -12.345);
    }
    assert(IonValue(jsonToIonTest("   null")).describe.get!IonNull == IonNull(IonTypeCode.null_));
    assert(IonValue(jsonToIonTest("true ")).describe.get!bool == true);
    assert(IonValue(jsonToIonTest("  false")).describe.get!bool == false);
    assert(IonValue(jsonToIonTest(` "string"`)).describe.get!(const(char)[]) == "string");

    enum str = "iwfpwqocbpwoewouivhqpeobvnqeon wlekdnfw;lefqoeifhq[woifhdq[owifhq[owiehfq[woiehf[  oiehwfoqwewefiqweopurefhqweoifhqweofihqeporifhq3eufh38hfoidf";
    auto data = jsonToIonTest(`"` ~ str ~ `"`);
    assert(IonValue(jsonToIonTest(`"` ~ str ~ `"`)).describe.get!(const(char)[]) == str);

    assert(IonValue(jsonToIonTest(`"hey \uD801\uDC37tee"`)).describe.get!(const(char)[]) == "hey 𐐷tee");
    assert(IonValue(jsonToIonTest(`[]`)).describe.get!IonList.data.length == 0);
    assert(IonValue(jsonToIonTest(`{}`)).describe.get!IonStruct.data.length == 0);

    // assert(jsonToIonTest(" [ {}, true , \t\r\nfalse, null, \"string\", 12.3 ]") ==
        // cast(ubyte[])"\xbe\x8e\xd0\x11\x10\x0f\x86\x73\x74\x72\x69\x6e\x67\x52\xc1\x7b");

    data = jsonToIonTest(` { "a": "b",  "key": ["array", {"a": "c" } ] } `);
    assert(data == cast(ubyte[])"\xde\x8f\x8a\x81b\x8b\xba\x85array\xd3\x8a\x81c");

    data = jsonToIonTest(
    `{
        "tags":[
            "russian",
            "novel",
            "19th century"
        ]
    }`);

}
