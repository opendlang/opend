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

struct Stage3Stage
{
    ubyte[] tape;
    ptrdiff_t currentTapePosition;
    ptrdiff_t index;
    ptrdiff_t n;
    const(ubyte)* strPtr;
    ulong[2]* pairedMask1;
    ulong[2]* pairedMask2;
    const(char)[] key; // Last key, it is the reference to the tape
}

IonErrorCode stage3(Table)(
    ref Table symbolTable,
    ref Stage3Stage stage,
    scope bool delegate() @safe pure nothrow @nogc fetchNext,
    out size_t currentTapePositionResult,
)
@trusted pure nothrow
{
    pragma(inline, false)
    string _lastError;

    bool last = fetchNext();

    with(stage){

    ptrdiff_t prepareSmallInput()
    {
        ptrdiff_t ret = n - index;
        // assert(ret >= 0);
        if (_expect(ret < 64 && !last, false))
        {
            last = fetchNext();
            ret = n - index;
            assert(ret >= 0);
        }
        return ret;
    }

    bool skipSpaces()
    {
        assert(index <= n);
        F:
        if (_expect(index < n, true))
        {
        L:
            auto indexG = index >> 6;
            auto indexL = index & 0x3F;
            auto spacesMask = ~pairedMask2[indexG][1] >> indexL;
            if (_expect(spacesMask != 0, true))
            {
                auto oldIndex = index;
                index += cttz(spacesMask);
                return true;
            }
            else
            {
                index = (indexG + 1) << 6;
                goto F;
            }
        }
        else
        {
            if (prepareSmallInput > 0)
                goto L;
            return false;
        }
    }

    int readUnicode()(ref dchar d)
    {
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

    size_t[1024] stack;// = void;
    sizediff_t stackPos = stack.length;

    typeof(return) retCode;
    bool currIsKey;// = void;
    goto value;

/////////// RETURN
ret:
    assert(stackPos == stack.length);
    if (prepareSmallInput() > 0)
    {
        auto indexG = index >> 6;
        auto indexL = index & 0x3F;
        auto mask = (pairedMask2[indexG][0] | pairedMask2[indexG][1]) >> indexL;
        if ((mask & 1) == 0)
        {
            retCode = IonErrorCode.jsonUnexpectedValue;
        }
    }
ret_final:
    currentTapePositionResult = currentTapePosition;
    return retCode;
///////////

key:
    if (!skipSpaces)
        goto object_key_unexpectedEnd;
key_start:
    if (strPtr[index] != '"')
        goto object_key_start_unexpectedValue;
    currIsKey = true;
    // reserve 1 byte for the length
string:
    assert(strPtr[index] == '"', "Internal Mir Ion logic error. Please report an issue.");
    index++;
StringLoop: {
    
    const stringCodeStart = currentTapePosition;
    currentTapePosition += ionPutStartLength;
    for(;;) 
    {
        sizediff_t smallInputLength = prepareSmallInput;
        auto indexG = index >> 6;
        auto indexL = index & 0x3F;
        auto mask = pairedMask1[indexG];
        mask[0] >>= indexL;
        mask[1] >>= indexL;
        auto strMask = mask[0] | mask[1];
        // TODO: memcpy optimisation for DMD
        assert(currentTapePosition + 64 <= tape.length);
        memcpy(tape.ptr + currentTapePosition, strPtr + index, 64);
        auto value = strMask == 0 ? 64 - indexL : cttz(strMask);
        smallInputLength -= cast(ptrdiff_t) value;
        if (smallInputLength < 0)
            goto string_unexpectedEnd;
        currentTapePosition += value;
        index += value;
        if (strMask == 0)
            continue;
        if (_expect(((mask[1] >> value) & 1) == 0, true)) // no escape value
        {
            assert(strPtr[index] == '"');
            index++;
            auto stringLength = currentTapePosition - (stringCodeStart + ionPutStartLength);
            // foreach(i, e; tape[currentTapePosition - stringLength .. currentTapePosition])
                
            if (!currIsKey)
            {
                currentTapePosition = stringCodeStart + ionPutEnd(tape.ptr + stringCodeStart, IonTypeCode.string, stringLength);
                goto next;
            }
            currentTapePosition -= stringLength;
            key = cast(const(char)[]) tape[currentTapePosition .. currentTapePosition + stringLength];
            currentTapePosition -= ionPutStartLength;
            static if (__traits(hasMember, Table, "insert"))
            {
                auto id = symbolTable.insert(key);
            }
            else // mir string table
            {
                uint id;
                if (!symbolTable.get(key, id))
                {
                    debug(ion) if (!__ctfe)
                    {
                        import core.stdc.stdio: stderr, fprintf;
                        fprintf(stderr, "Error: (debug) can't insert key %*.*s\n", cast(int)key.length, cast(int)key.length, key.ptr);
                    }
                    goto cant_insert_key;
                }
            }
            // TODO find id using the key
            currentTapePosition += ionPutVarUInt(tape.ptr + currentTapePosition, id);
            if (!skipSpaces)
                goto unexpectedEnd;
            if (strPtr[index++] != ':')
                goto object_after_key_is_missing;
            goto value;
        }
        else
        {
            --currentTapePosition;
            assert(strPtr[index - 1] == '\\', cast(string)strPtr[index .. index + 1]);
            if ((smallInputLength -= 1) <= 0)
                goto string_unexpectedEnd;
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
                    if ((smallInputLength -= 4) <= 0)
                        goto string_unexpectedEnd;
                    if (auto r = readUnicode(d))
                        goto unexpected_escape_unicode_value; //unexpected \u
                    if (_expect(0xD800 <= d && d <= 0xDFFF, false))
                    {
                        if (d >= 0xDC00)
                            goto invalid_utf_value;
                        if ((smallInputLength -= 6) < 0)
                            goto string_unexpectedEnd;
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
next:
    if (stackPos == stack.length)
    {
        if (!skipSpaces)
            goto ret;
        goto value_start;
    }
next_start: {
    if (!skipSpaces)
        goto next_unexpectedEnd;
    assert(stackPos >= 0);
    assert(stackPos < stack.length);
    const isObject = (tape[stack[stackPos]] & 0x40) != 0;
    const v = strPtr[index++];
    if (isObject)
    {
        if (v == ',')
            goto key;
        if (v != '}')
            goto next_unexpectedValue;
    }
    else
    {
        if (v == ',')
            goto value;
        if (v != ']')
            goto next_unexpectedValue;
    }
}
structure_end: {
    assert(stackPos >= 0);
    assert(stackPos < stack.length);
    auto stackValue = stack[stackPos++];
    const structureLength = currentTapePosition - (stackValue + ionPutStartLength);
    currentTapePosition = stackValue + ionPutEnd(tape.ptr + stackValue, structureLength);
    goto next;
}
value: {
    if (!skipSpaces)
        goto value_unexpectedEnd;
value_start:
    auto startC = strPtr[index];
    if (startC <= '9')
    {
        currIsKey = false;
        if (startC == '"')
            goto string;

        if (startC == '+')
        {
            index++;
            goto infinity;
        }

        size_t numberLength;            
        for(;;)
        {
            sizediff_t smallInputLength = prepareSmallInput;
            auto indexG = index >> 6;
            auto indexL = index & 0x3F;
            auto endMask = (pairedMask2[indexG][0] | pairedMask2[indexG][1]) >> indexL;
            // TODO: memcpy optimisation for DMD
            memcpy(tape.ptr + currentTapePosition + numberLength, strPtr + index, 64);
            auto additive = endMask == 0 ? 64 - indexL : cttz(endMask);
            numberLength += additive;
            index += additive;
            if (endMask == 0)
                continue;
            break;
        }
        auto numberStringView = cast(const(char)[]) (tape.ptr + currentTapePosition)[0 .. numberLength];

        import mir.bignum.decimal: Decimal, DecimalExponentKey;
        Decimal!256 decimal;
        DecimalExponentKey exponentKey;

        if (!decimal.fromStringImpl(numberStringView, exponentKey))
            goto unexpected_decimal_value;
        if (!exponentKey) // integer
        {
            currentTapePosition += ionPut(tape.ptr + currentTapePosition, decimal.coefficient.view);
            goto next;
        }
        else
        if ((exponentKey | 0x20) != DecimalExponentKey.e) // decimal
        {
            currentTapePosition += ionPut(tape.ptr + currentTapePosition, decimal.view);
            goto next;
        }
        else
        {
            // sciencific
            currentTapePosition += ionPut(tape.ptr + currentTapePosition, cast(double)decimal);
            goto next;
        }
    }
    if ((startC | 0x20) == '{')
    {
        index++;
        assert(stackPos <= stack.length);
        if (--stackPos < 0)
            goto stack_overflow;
        stack[stackPos] = currentTapePosition;
        tape[currentTapePosition] = startC == '{' ? IonTypeCode.struct_ << 4 : IonTypeCode.list << 4;
        currentTapePosition += ionPutStartLength;
        if (!skipSpaces)
            goto next_unexpectedEnd;
        if (strPtr[index] != startC + 2)
        {
            if (startC == '{')
                // goto key_start;
                goto key;
            else
                // goto value_start;
                goto value;
        }
        else
        {
            index++;
            goto structure_end;
        }
    }
    prepareSmallInput;
    static foreach(name; AliasSeq!("true", "false", "null"))
    {
        if (*cast(ubyte[name.length]*)(strPtr + index) == cast(ubyte[name.length]) name)
        {
            currentTapePosition += ionPut(tape.ptr + currentTapePosition, mixin(name));
            index += name.length;
            goto next;
        }
    }
    {
        enum name = "nan";
        if (*cast(ubyte[name.length]*)(strPtr + index) == cast(ubyte[name.length]) name)
        {
            currentTapePosition += ionPut(tape.ptr + currentTapePosition, float.nan);
            index += name.length;
            goto next;
        }
    }
    goto value_unexpectedStart;

infinity:

    prepareSmallInput;
    {
        enum name = "inf";
        if (*cast(ubyte[name.length]*)(strPtr + index) == cast(ubyte[name.length]) name)
        {
            currentTapePosition += ionPut(tape.ptr + currentTapePosition, float.nan);
            index += name.length;
            goto next;
        }
    }
    goto value_unexpectedStart;
}

cant_insert_key:
    retCode = IonErrorCode.symbolTableCantInsertKey;
    goto ret_final;
unexpectedEnd:
    retCode = IonErrorCode.jsonUnexpectedEnd;
    goto ret_final;
unexpectedValue:
    retCode = IonErrorCode.jsonUnexpectedValue;
    goto ret_final;
unexpected_decimal_value:
    _lastError = "unexpected decimal value";
    goto unexpectedValue;
unexpected_escape_unicode_value:
    _lastError = "unexpected escape unicode value";
    goto unexpectedValue;
unexpected_escape_value:
    _lastError = "unexpected escape value";
    goto unexpectedValue;
object_key_unexpectedEnd:
    _lastError = "unexpected end of object key";
    goto unexpectedEnd;
object_after_key_is_missing:
    _lastError = "expected ':' after key";
    goto unexpectedValue;
object_key_start_unexpectedValue:
    _lastError = "expected '\"' when start parsing object key";
    goto unexpectedValue;
key_is_to_large:
    _lastError = "key length is limited to 255 characters";
    goto unexpectedValue;
next_unexpectedEnd:
    assert(stackPos >= 0);
    assert(stackPos < stack.length);
    _lastError = (stack[stackPos] & 1) ? "unexpected end when parsing object" : "unexpected end when parsing array";
    goto unexpectedEnd;
next_unexpectedValue:
    assert(stackPos >= 0);
    assert(stackPos < stack.length);
    _lastError = (stack[stackPos] & 1) ? "expected ',' or `}` when parsing object" : "expected ',' or `]` when parsing array";
    goto unexpectedValue;
value_unexpectedStart:
    _lastError = "unexpected character when start parsing JSON value";
    goto unexpectedEnd;
value_unexpectedEnd:
    _lastError = "unexpected end when start parsing JSON value";
    goto unexpectedEnd;
number_length_unexpectedValue:
    _lastError = "number length is limited to 255 characters";
    goto unexpectedValue;
object_first_value_start_unexpectedEnd:
    _lastError = "unexpected end of input data after '{'";
    goto unexpectedEnd;
array_first_value_start_unexpectedEnd:
    _lastError = "unexpected end of input data after '['";
    goto unexpectedEnd;
false_unexpectedEnd:
    _lastError = "unexpected end when parsing 'false'";
    goto unexpectedEnd;
false_unexpectedValue:
    _lastError = "unexpected character when parsing 'false'";
    goto unexpectedValue;
null_unexpectedEnd:
    _lastError = "unexpected end when parsing 'null'";
    goto unexpectedEnd;
null_unexpectedValue:
    _lastError = "unexpected character when parsing 'null'";
    goto unexpectedValue;
true_unexpectedEnd:
    _lastError = "unexpected end when parsing 'true'";
    goto unexpectedEnd;
true_unexpectedValue:
    _lastError = "unexpected character when parsing 'true'";
    goto unexpectedValue;
string_unexpectedEnd:
    _lastError = "unexpected end when parsing string";
    goto unexpectedEnd;
string_unexpectedValue:
    _lastError = "unexpected character when parsing string";
    goto unexpectedValue;
failed_to_read_after_key:
    _lastError = "unexpected end after object key";
    goto unexpectedEnd;
unexpected_character_after_key:
    _lastError = "unexpected character after key";
    goto unexpectedValue;
string_length_is_too_large:
    _lastError = "string size is limited to 2^32-1";
    goto unexpectedValue;
invalid_trail_surrogate:
    _lastError = "invalid UTF-16 trail surrogate";
    goto unexpectedValue;
invalid_utf_value:
    _lastError = "invalid UTF value";
    goto unexpectedValue;
stack_overflow:
    _lastError = "overflow of internal stack";
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
