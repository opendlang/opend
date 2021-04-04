module mir.ion.internal.stage3;

import core.stdc.string: memcpy;
import mir.bitop;
import mir.ion.exception;
import mir.ion.symbol_table;
import mir.ion.tape;
import mir.ion.type_code;
import mir.primitives;
import mir.utility: _expect;
import std.meta: AliasSeq, aliasSeqOf;
import std.traits;

struct Stage3State
{
    ubyte[] tape;
    ptrdiff_t currentTapePosition;
    ptrdiff_t index;
    ptrdiff_t n;
    const(char)* strPtr;
    ulong[2]* pairedMask1;
    ulong[2]* pairedMask2;
    const(char)[] key; // Last key, it is the reference to the tape
    size_t location;
    bool eof;
    IonErrorCode errorCode;
}

void stage3(alias fetchNext, Table)(ref Stage3State stage, ref Table symbolTable)
@trusted nothrow @nogc
{
    version(LDC) pragma(inline, true);

    import mir.bignum.decimal: Decimal, DecimalExponentKey;

    enum stackLength = 1024;
    size_t currentTapePositionSkip;
    sizediff_t stackPos = stackLength;
    sizediff_t stackPosSkip = -1;
    size_t[stackLength] stack = void;
    Decimal!1 decimal = void;

    with(stage){

    bool prepareSmallInput()
    {
        version(LDC) pragma(inline, true);
        if (_expect(n - index < 64 && !eof, false))
        {
            if (!fetchNext())
                return false;
            assert(n - index > 0);
        }
        return true;
    }

    bool skipSpaces(ref bool seof)
    {
        version(LDC) pragma(inline, true);

        assert(index <= n);
        F:
        if (_expect(index < n, true))
        {
        L:
            auto indexG = index >> 6;
            auto indexL = index & 0x3F;
            auto spacesMask = ~pairedMask2[indexG][1] >> indexL;
            if (spacesMask != 0)
            {
                auto oldIndex = index;
                index += cttz(spacesMask);
                seof = false;
                return true;
            }
            else
            {
                index = (indexG + 1) << 6;
                goto F;
            }
        }
        else
        if (eof)
        {
            seof = true;
            return true;
        }
        else
        if (!fetchNext())
        {
            return false;
        }
        goto L;
    }

    int readUnicode()(ref dchar d)
    {
        version(LDC) pragma(inline, true);

        uint e = 0;
        size_t i = 4;
        do
        {
            int c = uniFlags[strPtr[index++]];
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

    if (_expect(!fetchNext(), false))
        goto errorReadingFile;

next: for(;;)
{
    {
        bool seof;
        if (!skipSpaces(seof))
            goto errorReadingFile;
        if (stackPos == stack.length)
        {
            if (seof)
                goto ret_final;
            else
                goto value_start;
        }
        else
        {
            if (seof)
                goto next_unexpectedEnd;
            if (stackPosSkip == stackPos)
            {
                currentTapePosition = currentTapePositionSkip;
                stackPosSkip = -1;
            }
        }
    }
    assert(stackPos >= 0);
    assert(stackPos < stack.length);
    auto stackValue = stack[stackPos];
    bool isStruct = stackValue & 1;
    const v = strPtr[index++];
    if (v == ',')
    {
        bool seof;
        if (!skipSpaces(seof))
            goto errorReadingFile;
        if (seof)
            goto value_unexpectedEnd;
        if (isStruct)
            goto key_start;
        else
            goto value_start;
    }
    if (v != (isStruct ? '}' : ']'))
        goto next_unexpectedValue;
    assert(stackPos >= 0);
    assert(stackPos < stack.length);
    stackValue >>= 1;
    auto aCode = isStruct ? IonTypeCode.struct_ : IonTypeCode.list;
    auto aLength = currentTapePosition - (stackValue + ionPutStartLength);
    stackPos++;
    currentTapePosition = stackValue;
    currentTapePosition += ionPutEnd(tape.ptr + currentTapePosition, aCode, aLength);
}

///////////
key_start: {
    if (strPtr[index] != '"')
        goto object_key_start_unexpectedValue;
    assert(strPtr[index] == '"', "Internal Mir Ion logic error. Please report an issue.");
    index++;
    const stringCodeStart = currentTapePosition;
    currentTapePosition += ionPutStartLength;
    for(;;) 
    {
        if (!prepareSmallInput)
            goto errorReadingFile;
        auto indexG = index >> 6;
        auto indexL = index & 0x3F;
        auto mask = pairedMask1[indexG];
        mask[0] >>= indexL;
        mask[1] >>= indexL;
        auto strMask = mask[0] | mask[1];
        // TODO: memcpy optimisation for DMD
        assert(currentTapePosition + 64 <= tape.length);
        *cast(ubyte[64]*)(tape.ptr + currentTapePosition) = *cast(const ubyte[64]*)(strPtr + index);
        auto value = strMask == 0 ? 64 - indexL : cttz(strMask);
        currentTapePosition += value;
        index += value;
        if (strMask == 0)
            continue;
        if (_expect(((mask[1] >> value) & 1) == 0, true)) // no escape value
        {
            {
                assert(strPtr[index] == '"');
                index++;
                auto aLength = currentTapePosition - (stringCodeStart + ionPutStartLength);
                currentTapePosition = stringCodeStart;
                key = cast(const(char)[]) tape[currentTapePosition + ionPutStartLength .. currentTapePosition + ionPutStartLength + aLength];
            }
            static if (__traits(hasMember, Table, "insert"))
            {
                auto id = symbolTable.insert(key);
            }
            else // mir string table
            {
                uint id;
                if (_expect(!symbolTable.get(key, id), false))
                {
                    debug(ion) if (!__ctfe)
                    {
                        import core.stdc.stdio: stderr, fprintf;
                        fprintf(stderr, "Error: (debug) can't insert key %*.*s\n", cast(int)key.length, cast(int)key.length, key.ptr);
                    }
                    if (stackPos > stackPosSkip)
                    {
                        currentTapePositionSkip = currentTapePosition;
                        stackPosSkip = stackPos;
                    }
                }
            }
            // TODO find id using the key
            currentTapePosition += ionPutVarUInt(tape.ptr + currentTapePosition, id);
            {
                bool seof;
                if (!skipSpaces(seof))
                    goto errorReadingFile;
                if (seof)
                    goto unexpectedEnd;
            }
            if (strPtr[index++] != ':')
                goto object_after_key_is_missing;
            {
                bool seof;
                if (!skipSpaces(seof))
                    goto errorReadingFile;
                if (seof)
                    goto unexpectedEnd;
            }
            goto value_start;
        }
        else
        {
            if (n - index < 64 && !eof)
                continue;
            --currentTapePosition;
            assert(strPtr[index - 1] == '\\', cast(string)strPtr[index .. index + 1]);
            dchar d = void;
            auto c = strPtr[index];
            index += 1;
            switch(c)
            {
                case '/' :
                case '\"':
                case '\\':
                    d = cast(ubyte) c;
                    goto PutASCII_key;
                case 'b' : d = '\b'; goto PutASCII_key;
                case 'f' : d = '\f'; goto PutASCII_key;
                case 'n' : d = '\n'; goto PutASCII_key;
                case 'r' : d = '\r'; goto PutASCII_key;
                case 't' : d = '\t'; goto PutASCII_key;
                case 'u' :
                    if (auto r = readUnicode(d))
                        goto unexpected_escape_unicode_value; //unexpected \u
                    if (_expect(0xD800 <= d && d <= 0xDFFF, false))
                    {
                        if (d >= 0xDC00)
                            goto invalid_utf_value;
                        if (strPtr[index++] != '\\')
                            goto invalid_utf_value;
                        if (strPtr[index++] != 'u')
                            goto invalid_utf_value;
                        d = (d & 0x3FF) << 10;
                        dchar trailing = void;
                        if (auto r = readUnicode(trailing))
                            goto unexpected_escape_unicode_value; //unexpected \u
                        if (!(0xDC00 <= trailing && trailing <= 0xDFFF))
                            goto invalid_trail_surrogate;
                        {
                            d |= trailing & 0x3FF;
                            d += 0x10000;
                        }
                    }
                    if (d < 0x80)
                    {
                    PutASCII_key:
                        tape[currentTapePosition] = cast(ubyte) (d);
                        currentTapePosition += 1;
                        continue;
                    }
                    if (d < 0x800)
                    {
                        tape[currentTapePosition + 0] = cast(ubyte) (0xC0 | (d >> 6));
                        tape[currentTapePosition + 1] = cast(ubyte) (0x80 | (d & 0x3F));
                        currentTapePosition += 2;
                        continue;
                    }
                    if (!(d < 0xD800 || (d > 0xDFFF && d <= 0x10FFFF)))
                        goto invalid_trail_surrogate;
                    if (d < 0x10000)
                    {
                        tape[currentTapePosition + 0] = cast(ubyte) (0xE0 | (d >> 12));
                        tape[currentTapePosition + 1] = cast(ubyte) (0x80 | ((d >> 6) & 0x3F));
                        tape[currentTapePosition + 2] = cast(ubyte) (0x80 | (d & 0x3F));
                        currentTapePosition += 3;
                        continue;
                    }
                    //    assert(d < 0x200000);
                    tape[currentTapePosition + 0] = cast(ubyte) (0xF0 | (d >> 18));
                    tape[currentTapePosition + 1] = cast(ubyte) (0x80 | ((d >> 12) & 0x3F));
                    tape[currentTapePosition + 2] = cast(ubyte) (0x80 | ((d >> 6) & 0x3F));
                    tape[currentTapePosition + 3] = cast(ubyte) (0x80 | (d & 0x3F));
                    currentTapePosition += 4;
                    continue;
                default: goto unexpected_escape_value; // unexpected escape
            }
        }
    }
}

value_start: {
    auto startC = strPtr[index];
    if (startC <= '9')
    {
        if (startC == '"')
        {
            assert(strPtr[index] == '"', "Internal Mir Ion logic error. Please report an issue.");
            index++;
            const stringCodeStart = currentTapePosition;
            currentTapePosition += ionPutStartLength;
            for(;;) 
            {
                if (!prepareSmallInput)
                    goto errorReadingFile;
                auto indexG = index >> 6;
                auto indexL = index & 0x3F;
                auto mask = pairedMask1[indexG];
                mask[0] >>= indexL;
                mask[1] >>= indexL;
                auto strMask = mask[0] | mask[1];
                // TODO: memcpy optimisation for DMD
                assert(currentTapePosition + 64 <= tape.length);
                *cast(ubyte[64]*)(tape.ptr + currentTapePosition) = *cast(const ubyte[64]*)(strPtr + index);
                auto value = strMask == 0 ? 64 - indexL : cttz(strMask);
                currentTapePosition += value;
                index += value;
                if (strMask == 0)
                    continue;
                if (_expect(((mask[1] >> value) & 1) == 0, true)) // no escape value
                {
                    assert(strPtr[index] == '"');
                    index++;
                    auto stringLength = currentTapePosition - (stringCodeStart + ionPutStartLength);
                    currentTapePosition = stringCodeStart;
                    currentTapePosition += ionPutEnd(tape.ptr + currentTapePosition, IonTypeCode.string, stringLength);
                    goto next;
                }
                else
                {
                    if (n - index < 64 && !eof)
                        continue;
                    --currentTapePosition;
                    assert(strPtr[index - 1] == '\\', cast(string)strPtr[index .. index + 1]);
                    dchar d = void;
                    auto c = strPtr[index];
                    index += 1;
                    switch(c)
                    {
                        case '/' :
                        case '\"':
                        case '\\':
                            d = cast(ubyte) c;
                            goto PutASCII;
                        case 'b' : d = '\b'; goto PutASCII;
                        case 'f' : d = '\f'; goto PutASCII;
                        case 'n' : d = '\n'; goto PutASCII;
                        case 'r' : d = '\r'; goto PutASCII;
                        case 't' : d = '\t'; goto PutASCII;
                        case 'u' :
                            if (auto r = readUnicode(d))
                                goto unexpected_escape_unicode_value; //unexpected \u
                            if (_expect(0xD800 <= d && d <= 0xDFFF, false))
                            {
                                if (d >= 0xDC00)
                                    goto invalid_utf_value;
                                if (strPtr[index++] != '\\')
                                    goto invalid_utf_value;
                                if (strPtr[index++] != 'u')
                                    goto invalid_utf_value;
                                d = (d & 0x3FF) << 10;
                                dchar trailing = void;
                                if (auto r = readUnicode(trailing))
                                    goto unexpected_escape_unicode_value; //unexpected \u
                                if (!(0xDC00 <= trailing && trailing <= 0xDFFF))
                                    goto invalid_trail_surrogate;
                                {
                                    d |= trailing & 0x3FF;
                                    d += 0x10000;
                                }
                            }
                            if (d < 0x80)
                            {
                            PutASCII:
                                tape[currentTapePosition] = cast(ubyte) (d);
                                currentTapePosition += 1;
                                continue;
                            }
                            if (d < 0x800)
                            {
                                tape[currentTapePosition + 0] = cast(ubyte) (0xC0 | (d >> 6));
                                tape[currentTapePosition + 1] = cast(ubyte) (0x80 | (d & 0x3F));
                                currentTapePosition += 2;
                                continue;
                            }
                            if (!(d < 0xD800 || (d > 0xDFFF && d <= 0x10FFFF)))
                                goto invalid_trail_surrogate;
                            if (d < 0x10000)
                            {
                                tape[currentTapePosition + 0] = cast(ubyte) (0xE0 | (d >> 12));
                                tape[currentTapePosition + 1] = cast(ubyte) (0x80 | ((d >> 6) & 0x3F));
                                tape[currentTapePosition + 2] = cast(ubyte) (0x80 | (d & 0x3F));
                                currentTapePosition += 3;
                                continue;
                            }
                            //    assert(d < 0x200000);
                            tape[currentTapePosition + 0] = cast(ubyte) (0xF0 | (d >> 18));
                            tape[currentTapePosition + 1] = cast(ubyte) (0x80 | ((d >> 12) & 0x3F));
                            tape[currentTapePosition + 2] = cast(ubyte) (0x80 | ((d >> 6) & 0x3F));
                            tape[currentTapePosition + 3] = cast(ubyte) (0x80 | (d & 0x3F));
                            currentTapePosition += 4;
                            continue;
                        default: goto unexpected_escape_value; // unexpected escape
                    }
                }
            }
        }

        version(none)
        {                    
            size_t numberLength; 
            for(;;)
            {
                if (!prepareSmallInput)
                    goto errorReadingFile;
                auto indexG = index >> 6;
                auto indexL = index & 0x3F;
                auto endMask = (pairedMask2[indexG][0] | pairedMask2[indexG][1]) >> indexL;
                // TODO: memcpy optimisation for DMD
                auto additive = endMask == 0 ? 64 - indexL : cttz(endMask);
                *cast(ubyte[64]*)(tape.ptr + currentTapePosition + numberLength) = *cast(const ubyte[64]*)(strPtr + index);
                numberLength += additive;
                index += additive;
                if (endMask != 0)
                    break;
            }
            auto numberStringView = cast(const(char)[]) (tape.ptr + currentTapePosition)[0 .. numberLength];
        }
        else
        {
            if (!prepareSmallInput)
                goto errorReadingFile;
            auto indexG = index >> 6;
            auto indexL = index & 0x3F;
                auto endMask = (pairedMask2[indexG][0] | pairedMask2[indexG][1]) >> indexL;
            endMask |= indexL != 0 ? (pairedMask2[indexG + 1][0] | pairedMask2[indexG + 1][1]) << (64 - indexL) : 0;
            if (endMask == 0)
                goto integerOverflow;
            auto numberLength = cttz(endMask);
            auto numberStringView = cast(const(char)[]) (strPtr + index)[0 .. numberLength];
            index += numberLength;
        }

        DecimalExponentKey exponentKey;

        if (!decimal.fromStringImpl!(char, false, false, false, false, false)(numberStringView, exponentKey))
            goto unexpected_decimal_value;
        if (!exponentKey) // integer
        {
            auto unsignedView = decimal.coefficient.view.unsigned;
            enum l = ulong.sizeof / size_t.sizeof;
            if (_expect(unsignedView.coefficients.length > l, true))
                goto integerOverflow;
            currentTapePosition += ionPut(tape.ptr + currentTapePosition, cast(ulong) unsignedView, decimal.coefficient.sign);
            goto next;
            // // else
            // {
            //     currentTapePosition += ionPut(tape.ptr + currentTapePosition, decimal.coefficient.view);
            //     goto next;
            // }
        }
        // else
        // if ((exponentKey | 0x20) != DecimalExponentKey.e) // decimal
        // {
        //     currentTapePosition += ionPut(tape.ptr + currentTapePosition, decimal.view);
        //     goto next;
        // }
        else
        {
            // sciencific
            currentTapePosition += ionPut(tape.ptr + currentTapePosition, decimal.opCast!(double, true));
            goto next;
        }
    }

    if ((startC | 0x20) == '{')
    {
        index++;
        bool seof;
        if (!skipSpaces(seof))
            goto errorReadingFile;
        if (seof)
            goto next_unexpectedEnd;
        assert(stackPos <= stack.length);
        if (--stackPos < 0)
            goto stack_overflow;
        bool isStruct = startC == '{';
        stack[stackPos] = (currentTapePosition << 1) ^ isStruct;
        currentTapePosition += ionPutStartLength;
        if (isStruct)
        {
            if (strPtr[index] != '}')
                goto key_start;
        }
        else
        {
            if (strPtr[index] != ']')
                goto value_start;
        }
        currentTapePosition -= ionPutStartLength;
        index++;
        stackPos++;
        tape[currentTapePosition++] = startC == '{' ? IonTypeCode.struct_ << 4 : IonTypeCode.list << 4;
        goto next;
    }

    if (!prepareSmallInput)
        goto errorReadingFile;
    static foreach(name; AliasSeq!("true", "false", "null"))
    {
        if (*cast(ubyte[name.length]*)(strPtr + index) == cast(ubyte[name.length]) name)
        {
            currentTapePosition += ionPut(tape.ptr + currentTapePosition, mixin(name));
            index += name.length;
            goto next;
        }
    }
    goto value_unexpectedStart;
}

ret_final:
    return;
errorReadingFile:
    errorCode = IonErrorCode.errorReadingFile;
    goto ret_final;
cant_insert_key:
    errorCode = IonErrorCode.symbolTableCantInsertKey;
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
}}

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
