/++
Ion Text Deserialization API

Heavily influenced (and compatible) with upstream Ion implementations (compatible with ion-go)
Authors: Harrison Ford
+/
module mir.deser.text;
import mir.deser.text.readers;
import mir.deser.text.skippers;
import mir.deser.text.tokenizer;
import mir.deser.text.tokens;
import mir.ion.symbol_table;
import mir.ion.type_code;
import mir.ion.tape;
import mir.ser.ion;
import mir.serde;
import mir.format; // Quoted symbol support
import mir.ion.internal.data_holder;
import mir.ion.internal.stage3 : IonErrorInfo;
import mir.bignum.integer;
import std.traits : hasUDA, getUDAs;

private mixin template Stack(T, size_t maxDepth = 1024)
{
    private
    {
        immutable maxDepthReachedMsg = "max depth on stack reached";
        immutable cannotPopNoElementsMsg = "cannot pop from stack with 0 elements";
        version(D_Exceptions) {
            immutable maxDepthException = new Exception(maxDepthReachedMsg);
            immutable cannotPopNoElementsException = new Exception(cannotPopNoElementsMsg);
        }
        T[maxDepth] stack;
        size_t stackLength;
    }

    T peekStack() @safe @nogc pure
    {
        if (stackLength == 0) return T.init;
        return stack[stackLength - 1];
    }

    void pushStack(T element) @safe @nogc pure
    {
        if (stackLength + 1 > maxDepth) {
            version(D_Exceptions)
                throw maxDepthException;
            else
                assert(0, maxDepthReachedMsg);
        }
        stack[stackLength++] = element;
    }

    T popStackBack() @safe @nogc pure
    {
        if (stackLength <= 0) {
            version (D_Exceptions)
                throw cannotPopNoElementsException;
            else
                assert(0, cannotPopNoElementsMsg);
        }
        T code = stack[stackLength];
        stack[--stackLength] = T.init;
        return code;
    }
}

private enum State {
    beforeAnnotations,
    beforeFieldName,
    beforeContainer,
    afterValue,
    EOF
}

// UDA
private struct S 
{
    State state;
    bool transition = false;
    bool disableAfterValue = false;
}

/++
Deserializer for the Ion Text format
+/
struct IonTextDeserializer(Serializer)
{
    mixin Stack!(IonTypeCode);
    private Serializer* ser;
    private State state;
    private IonTokenizer t;

    /++
    Constructor
    Params:
        ser = A pointer to a serializer
    +/
    this(Serializer* ser) @safe pure
    {
        this.ser = ser;
        this.state = State.beforeAnnotations;
    }

    /++
    This function starts the deserializing process, and attempts to fully read through
    the text provided until it reaches the end.
    Params:
        text = The text to deserialize
    +/
    void opCall(scope const(char)[] text) @trusted pure
    {
        t = IonTokenizer(text);
        while (!t.isEOF())
        {
            auto ntr = t.nextToken();
            assert(ntr, "hit eof when tokenizer says we're not at an EOF??");

            switch (state) with (State)
            {
                case afterValue:
                case beforeFieldName:
                case beforeAnnotations:
                    handleState(state);
                    break;
                default:
                    version(D_Exceptions)
                        throw IonDeserializerErrorCode.unexpectedState.ionDeserializerException;
                    else
                        assert(0, "unexpected state");
            }
        }
    }

private:

    static void __bar()
    {
        typeof(*typeof(this).init.ser).init.putAnnotation("symbolText");
    }

    static assert(__traits(compiles, (){__bar();}));

    // import std.traits: 
    static if (__traits(compiles, ()@nogc{__bar();}))
    {
        void handleState(State s) @safe pure @nogc { handleStateImpl(s); }
        void handleToken(IonTokenType t) @safe pure @nogc { handleTokenImpl(t); }
    }
    else
    {
        void handleState(State s) @safe pure { handleStateImpl(s); }
        void handleToken(IonTokenType t) @safe pure { handleTokenImpl(t); }
    }

    private void handleStateImpl(State s) @safe pure
    {
        switch (s) {
            // Cannot use getSymbolsByUDA as it leads to recursive template instantiations
            static foreach(member; __traits(allMembers, typeof(this))) {
                static foreach(registeredState; getUDAs!(__traits(getMember, this, member), S))
                    static if (!registeredState.transition) {
                        case registeredState.state:
                            __traits(getMember, this, member)(); 
                            static if (!registeredState.disableAfterValue)
                                state = handleStateTransition(State.afterValue);
                            return;
                    }
            }
            default: {
                version (D_Exceptions)
                    throw IonDeserializerErrorCode.unexpectedState.ionDeserializerException;
                else
                    assert(0, "Unexpected state");
            }
        }
    }

    private State handleStateTransition(State s) @safe pure
    {
        switch (s)
        {
            static foreach(member; __traits(allMembers, typeof(this)))
                static foreach(registeredState; getUDAs!(__traits(getMember, this, member), S))
                    static if (registeredState.transition) {
                        case registeredState.state:
                            return __traits(getMember, this, member);
                    }
            default:
                version (D_Exceptions)
                    throw IonDeserializerErrorCode.unexpectedState.ionDeserializerException;
                else
                    assert(0, "Unexpected state");
        }
    }

    private void handleTokenImpl(IonTokenType t) @safe pure
    {
        switch (t)
        {
            static foreach(member; __traits(allMembers, typeof(this)))
                static foreach(registeredToken; getUDAs!(__traits(getMember, this, member), IonTokenType)) {
                    case registeredToken:
                        return __traits(getMember, this, member);
                }
            default:
                version (D_Exceptions)
                    throw IonDeserializerErrorCode.unexpectedToken.ionDeserializerException;
                else
                    assert(0, "Unexpected token");
        }
    }

    /* State / state transition handlers */

    @S(State.beforeAnnotations) 
    bool handleBeforeAnnotations() @safe pure
    {
        switch (t.currentToken) with (IonTokenType) 
        {
            case TokenString:
            case TokenLongString:
            case TokenTimestamp:
            case TokenBinary:
            case TokenHex:
            case TokenNumber:
            case TokenFloatInf:
            case TokenFloatMinusInf:
            case TokenFloatNaN:
            case TokenSymbolQuoted:
            case TokenSymbol:
            case TokenSymbolOperator:
            case TokenDot:
            case TokenOpenDoubleBrace:
            case TokenOpenBrace: 
            case TokenOpenBracket:
            case TokenOpenParen:
                handleToken(t.currentToken);
                return true;
            case TokenEOF:
                return false;
            default:
                version(D_Exceptions)
                    throw IonDeserializerErrorCode.unexpectedToken.ionDeserializerException;
                else
                    assert(0, "unexpected token");
        }
    }

    // Typically called within a struct
    @S(State.beforeFieldName, false, true)
    bool handleBeforeFieldName() @safe pure
    {
        switch (t.currentToken) with (IonTokenType) 
        {
            case TokenCloseBrace: // Simply just return if this is empty
                return true; 
            case TokenString:
            case TokenLongString:
            {
                // This code is very similar to the string handling code,
                // but we put the data on a scoped buffer rather then using the serializer
                // to put a string by parts.
                auto buf = stringBuf;
                IonTextString v;
                if (t.currentToken == TokenString)
                {
                    v = t.readValue!(TokenString);
                }
                else
                {
                    v = t.readValue!(TokenLongString);
                }

                buf.put(v.matchedText); 
                while (!v.isFinal)
                {
                    if (t.currentToken == IonTokenType.TokenString)
                    {
                        v = t.readValue!(IonTokenType.TokenString);
                    }
                    else 
                    {
                        v = t.readValue!(IonTokenType.TokenLongString);
                    }
                    buf.put(v.matchedText);
                }

                // At this point, we should've fully read out the contents of the first long string,
                // so we should check if there's any long strings following this one. 
                if (t.currentToken == IonTokenType.TokenLongString)
                {
                    while (true)
                    {
                        char c = t.skipWhitespace();
                        if (c == '\'')
                        {
                            auto cs = t.peekMax(2);
                            if (cs.length == 2 && cs[0] == '\'' && cs[1] == '\'')
                            {
                                t.skipExactly(2);
                                v = t.readValue!(IonTokenType.TokenLongString);
                                buf.put(v.matchedText);
                                while (!v.isFinal)
                                {
                                    v = t.readValue!(IonTokenType.TokenLongString);
                                    buf.put(v.matchedText);
                                }
                            }
                            else
                            {
                                t.unread(c);
                                break;
                            }
                        }
                        else
                        {
                            t.unread(c);
                            break;
                        }
                    }
                }

                ser.putKey(buf.data);
                if (!t.nextToken())
                {
                    version(D_Exceptions)
                        throw IonDeserializerErrorCode.unexpectedEOF.ionDeserializerException;
                    else
                        assert(0, "unexpected end of file");
                }
                if (t.currentToken != TokenColon)
                {
                    version(D_Exceptions)
                        throw IonDeserializerErrorCode.unexpectedToken.ionDeserializerException;
                    else
                        assert(0, "unexpected token");
                }
                state = State.beforeAnnotations;
                return true;
            }
            static foreach(tok; [TokenSymbol, TokenSymbolQuoted])
            {
                case tok: 
                {
                    auto val = t.readValue!(tok);

                    static if (tok == TokenSymbol) 
                    {
                        if (symbolNeedsQuotes(val.matchedText)) 
                        {
                            version(D_Exceptions)
                                throw IonDeserializerErrorCode.requiresQuotes.ionDeserializerException;
                            else
                                assert(0, "unquoted symbol requires quotes");
                        }
                        ser.putKey(val.matchedText);
                    } else {
                        auto buf = stringBuf;
                        buf.put(val.matchedText);
                        while (!val.isFinal) {
                            val = t.readValue!(tok);
                            buf.put(val.matchedText);
                        }
                        ser.putKey(buf.data);
                    }

                    if (!t.nextToken())
                    {
                        version(D_Exceptions)
                            throw IonDeserializerErrorCode.unexpectedEOF.ionDeserializerException;
                        else
                            assert(0, "unexpected end of file");
                    }
                    
                    if (t.currentToken != TokenColon)
                    {
                        version(D_Exceptions)
                            throw IonDeserializerErrorCode.unexpectedToken.ionDeserializerException;
                        else
                            assert(0, "unexpected token");
                    }
                    state = State.beforeAnnotations;
                    return true;
                }
            }

            default:
                version(D_Exceptions)
                    throw IonDeserializerErrorCode.unexpectedToken.ionDeserializerException;
                else
                    assert(0, "unexpected token");
        }
    }

    @S(State.afterValue, false, true)
    bool handleAfterValue() @safe @nogc pure
    {
        switch (t.currentToken) with (IonTokenType)
        {
            case TokenComma:
                auto top = peekStack();
                if (top == IonTypeCode.struct_)
                {
                    state = State.beforeFieldName;
                }
                else if (top == IonTypeCode.list) 
                {
                    state = State.beforeAnnotations;
                }
                else
                {
                    version(D_Exceptions)
                        throw IonDeserializerErrorCode.unexpectedState.ionDeserializerException;
                    else
                        assert(0, "unexpected state");
                }
                return false;
            case TokenCloseBrace:
                if (peekStack() == IonTypeCode.struct_)
                {
                    return true;
                }
                goto default;
            case TokenCloseBracket:
                if (peekStack() == IonTypeCode.list)
                {
                    return true;
                }
                goto default;
            case TokenCloseParen:
                if (peekStack() == IonTypeCode.sexp)
                {
                    return true;
                }
                goto default;
            default:
                version(D_Exceptions)
                    throw IonDeserializerErrorCode.unexpectedToken.ionDeserializerException;
                else
                    assert(0, "unexpected token");
        }
    }

    @S(State.afterValue, true)
    State transitionAfterValue() @safe @nogc pure
    {
        switch (peekStack()) with (IonTypeCode)
        {
            case list:
            case struct_:
                return State.afterValue;
            case sexp:
            case null_:
                return State.beforeAnnotations;
            default:
                version(D_Exceptions)
                    throw IonDeserializerErrorCode.unexpectedState.ionDeserializerException;
                else
                    assert(0, "unexpected state");
        }
    }

    /* Individual token handlers */

    void onNull() @safe pure
    {
        auto cs = t.peekMax(1);
        // Nulls cannot have any whitespace preceding the dot
        // This is a workaround, as we skip all whitespace checking for the double-colon
        if (cs.length == 1 && cs[0] == '.' && !isWhitespace(t.input[t.position - 1 .. t.position][0]))
        {
            t.skipOne();
            if (!t.nextToken())
            {
                version(D_Exceptions)
                    throw IonDeserializerErrorCode.unexpectedEOF.ionDeserializerException;
                else
                    assert(0, "unexpected end of file");
            }

            if (t.currentToken != IonTokenType.TokenSymbol)
            {
                version(D_Exceptions)
                    throw IonDeserializerErrorCode.unexpectedToken.ionDeserializerException;
                else
                    assert(0, "unexpected token");
            }
            auto val = t.readValue!(IonTokenType.TokenSymbol);
            sw: switch (val.matchedText)
            {
                static foreach(v; ["null", "bool", "int", "float", "decimal", 
                                  "timestamp", "symbol", "string", "blob", 
                                  "clob", "list", "struct", "sexp"]) 
                {
                    case v:
                        static if (v == "null" || v == "bool" || v == "float" || v == "struct")
                        {
                            mixin ("ser.putNull(IonTypeCode." ~ v ~ "_);");
                        }
                        else static if (v == "int")
                        {
                            ser.putNull(IonTypeCode.uInt);
                        }
                        else
                        {
                            mixin ("ser.putNull(IonTypeCode." ~ v ~ ");");
                        }
                        break sw;
                }
                default:
                    version(D_Exceptions)
                        throw IonDeserializerErrorCode.invalidNullType.ionDeserializerException;
                    else
                        assert(0, "invalid null type specified");
            }
        }
        else
        {
            ser.putValue(null);
        }
    }

    @(IonTokenType.TokenOpenBrace)
    void onStruct() @safe pure
    {
        auto s0 = ser.structBegin();
        pushStack(IonTypeCode.struct_);
        state = State.beforeFieldName;
        t.finished = true;
        while (t.nextToken())
        {
            if (t.currentToken == IonTokenType.TokenCloseBrace)
            {
                t.finished = true;
                break;
            }

            handleState(state);
        }
        assert(peekStack() == IonTypeCode.struct_, "XXX: should never happen");
        popStackBack();
        ser.structEnd(s0);
    }

    @(IonTokenType.TokenOpenBracket)
    void onList() @safe pure
    {
        auto s0 = ser.listBegin();
        pushStack(IonTypeCode.list);
        state = State.beforeAnnotations;
        t.finished = true;
        while (t.nextToken()) 
        {
            if (t.currentToken == IonTokenType.TokenCloseBracket)
            {
                t.finished = true;
                break;
            }

            ser.elemBegin; handleState(state);
        }
        assert(peekStack() == IonTypeCode.list, "XXX: should never happen");
        popStackBack();
        ser.listEnd(s0);
    }

    @(IonTokenType.TokenOpenParen)
    void onSexp() @safe pure
    {
        auto s0 = ser.sexpBegin();
        pushStack(IonTypeCode.sexp);
        state = State.beforeAnnotations;
        t.finished = true;
        while (t.nextToken())
        {
            if (t.currentToken == IonTokenType.TokenCloseParen) 
            {
                t.finished = true;
                break;
            }

            ser.sexpElemBegin; handleState(state);
        }
        assert(peekStack() == IonTypeCode.sexp, "XXX: should never happen");
        popStackBack();
        ser.sexpEnd(s0);
    }

    @(IonTokenType.TokenSymbolOperator)
    @(IonTokenType.TokenDot)
    void onSymbolOperator() @safe pure 
    {
        if (peekStack() != IonTypeCode.sexp)
        {
            version(D_Exceptions)
                throw IonDeserializerErrorCode.unexpectedToken.ionDeserializerException;
            else
                assert(0, "unexpected token");
        }
        onSymbol();
    }

    @(IonTokenType.TokenSymbol)
    @(IonTokenType.TokenSymbolQuoted)
    void onSymbol() @safe pure
    {
        // The use of a scoped buffer is inevitable, as quoted symbols
        // may contain UTF code points, which we read out separately
        auto buf = stringBuf;
        const(char)[] symbolText;

        if (t.currentToken == IonTokenType.TokenSymbol)
        {
            IonTextSymbol val = t.readValue!(IonTokenType.TokenSymbol);
            buf.put(val.matchedText);
        }
        else if (t.currentToken == IonTokenType.TokenSymbolOperator || t.currentToken == IonTokenType.TokenDot)
        {
            IonTextSymbolOperator val = t.readValue!(IonTokenType.TokenSymbolOperator);
            buf.put(val.matchedText);
        }
        else if (t.currentToken == IonTokenType.TokenSymbolQuoted)
        {
            IonTextQuotedSymbol val = t.readValue!(IonTokenType.TokenSymbolQuoted);
            buf.put(val.matchedText);
            while (!val.isFinal)
            {
                val = t.readValue!(IonTokenType.TokenSymbolQuoted);
                buf.put(val.matchedText);
            }
        }
        symbolText = buf.data;

        if (t.isDoubleColon())
        {
            if (t.currentToken == IonTokenType.TokenSymbol && symbolNeedsQuotes(symbolText))
            {
                version(D_Exceptions)
                    throw IonDeserializerErrorCode.requiresQuotes.ionDeserializerException;
                else
                    assert(0, "unquoted symbol requires quotes");
            }
            else if (t.currentToken == IonTokenType.TokenSymbolOperator)
            {
                version(D_Exceptions)
                    throw IonDeserializerErrorCode.requiresQuotes.ionDeserializerException;
                else
                    assert(0, "unquoted symbol requires quotes");
            }
            // we are an annotation -- special handling is needed here
            // since we've identified this symbol to be an annotation,
            // we technically *aren't* finished with reading out the value
            // and should not default to skipping over the ending mark
            // rather, we should skip any whitespace and find the next token 
            // (which is ensured to be a double-colon)
            if (!t.nextToken()) 
            {
                version(D_Exceptions)
                    throw IonDeserializerErrorCode.unexpectedEOF.ionDeserializerException;
                else
                    assert(0, "unexpected end of file");
            }
            
            if (t.currentToken != IonTokenType.TokenDoubleColon)
            {
                version(D_Exceptions)
                    throw IonDeserializerErrorCode.unexpectedToken.ionDeserializerException;
                else
                    assert(0, "unexpected token");
            }

            size_t wrapperStart = ser.annotationWrapperBegin();
            ser.putAnnotation(symbolText);

            while (t.nextToken())
            {
                // check if the next token read is a candidate for our annotation array
                if (t.currentToken == IonTokenType.TokenSymbol || t.currentToken == IonTokenType.TokenSymbolQuoted)
                {
                    buf.reset;
                    if (t.currentToken == IonTokenType.TokenSymbol)
                    {
                        IonTextSymbol val = t.readValue!(IonTokenType.TokenSymbol);
                        buf.put(val.matchedText);
                    }
                    else if (t.currentToken == IonTokenType.TokenSymbolQuoted)
                    {
                        IonTextQuotedSymbol val = t.readValue!(IonTokenType.TokenSymbolQuoted);
                        buf.put(val.matchedText);
                        while (!val.isFinal)
                        {
                            val = t.readValue!(IonTokenType.TokenSymbolQuoted);
                            buf.put(val.matchedText);
                        }
                    }

                    // if the symbol we read is followed by a ::, then that means that
                    // this is not the end of our annotation array sequence
                    if (t.isDoubleColon())
                    {
                        // set finished to false so we don't skip over values, rather skip over whitespace
                        if (!t.nextToken())
                        {
                            version(D_Exceptions)
                                throw IonDeserializerErrorCode.unexpectedEOF.ionDeserializerException;
                            else
                                assert(0, "unexpected end of file");
                        }

                        if (t.currentToken != IonTokenType.TokenDoubleColon)
                        {
                            version(D_Exceptions)
                                throw IonDeserializerErrorCode.unexpectedToken.ionDeserializerException;
                            else
                                assert(0, "unexpected token");
                        }
                        ser.putAnnotation(buf.data);
                    }
                    else
                    {
                        // if not, this is where we end
                        auto arrayStart = ser.annotationsEnd(wrapperStart);
                        ser.putSymbol(buf.data);
                        ser.annotationWrapperEnd(arrayStart, wrapperStart);
                        break;
                    }
                }
                else
                {
                    // if the current token is a value type (a non-symbol), then we should also end the annotation array
                    auto arrayStart = ser.annotationsEnd(wrapperStart);
                    handleToken(t.currentToken);
                    ser.annotationWrapperEnd(arrayStart, wrapperStart);
                    break;
                }
            }
        }
        else
        {
            if (t.currentToken == IonTokenType.TokenSymbol 
            || t.currentToken == IonTokenType.TokenSymbolOperator
            || t.currentToken == IonTokenType.TokenDot)
            {
                switch (symbolText)
                {
                    case "null":
                        onNull();
                        break;
                    case "true":
                        ser.putValue(true);
                        break;
                    case "false":
                        ser.putValue(false);
                        break;
                    default:
                        ser.putSymbol(symbolText);
                        break;
                }
            }
            else
            {
                ser.putSymbol(symbolText);
            }
        }
    }

    @(IonTokenType.TokenString)
    @(IonTokenType.TokenLongString)
    void onString() @safe pure
    {
        IonTextString v;
        if (t.currentToken == IonTokenType.TokenString)
        {
            v = t.readValue!(IonTokenType.TokenString);
        }
        else
        {
            v = t.readValue!(IonTokenType.TokenLongString);
        }
        auto s0 = ser.stringBegin;
        ser.putStringPart(v.matchedText);
        while (!v.isFinal)
        {
            if (t.currentToken == IonTokenType.TokenString)
            {
                v = t.readValue!(IonTokenType.TokenString);
            }
            else
            {
                v = t.readValue!(IonTokenType.TokenLongString);
            }
            ser.putStringPart(v.matchedText);
        }

        // At this point, we should've fully read out the contents of the first long string,
        // so we should check if there's any long strings following this one. 
        if (t.currentToken == IonTokenType.TokenLongString)
        {
            while (true)
            {
                char c = t.skipWhitespace();
                if (c == '\'')
                {
                    auto cs = t.peekMax(2);
                    if (cs.length == 2 && cs[0] == '\'' && cs[1] == '\'')
                    {
                        t.skipExactly(2);
                        v = t.readValue!(IonTokenType.TokenLongString);
                        ser.putStringPart(v.matchedText);
                        while (!v.isFinal)
                        {
                            v = t.readValue!(IonTokenType.TokenLongString);
                            ser.putStringPart(v.matchedText);
                        }
                    }
                    else
                    {
                        t.unread(c);
                        break;
                    }
                }
                else
                {
                    t.unread(c);
                    break;
                }
            }
        }

        ser.stringEnd(s0);
    }

    @(IonTokenType.TokenTimestamp)
    void onTimestamp() @safe pure
    {
        import mir.timestamp : Timestamp;
        auto v = t.readValue!(IonTokenType.TokenTimestamp);
        ser.putValue(Timestamp(v.matchedText));
    }

    @(IonTokenType.TokenNumber)
    void onNumber() @safe pure
    {
        import mir.bignum.integer;
        import mir.bignum.decimal;
        import mir.parse;
        auto v = t.readValue!(IonTokenType.TokenNumber);

        if (v.type == IonTypeCode.null_)
        {
            ser.putNull(v.type);
            return;
        }

        Decimal!128 dec = void;
        DecimalExponentKey exponentKey;
        // special values are handled within the tokenizer and emit different token types
        // i.e. nan == IonTokenType.TokenFloatNaN, +inf == IonTokenType.TokenFloatInf, etc
        enum bool allowSpecialValues = false;
        // Ion spec allows this
        enum bool allowDotOnBounds = true;
        enum bool allowDExponent = true;
        enum bool allowStartingPlus = false;
        enum bool allowUnderscores = true;
        enum bool allowLeadingZeros = false;
        enum bool allowExponent = true; 
        // shouldn't be empty anyways, tokenizer wouldn't allow it
        enum bool checkEmpty = false; 

        if (!dec.fromStringImpl!(
            char,
            allowSpecialValues,
            allowDotOnBounds,
            allowDExponent,
            allowStartingPlus,
            allowUnderscores,
            allowLeadingZeros,
            allowExponent,
            checkEmpty
        )(v.matchedText, exponentKey))
        {
            goto unexpected_decimal_value;
        }

        if (exponentKey == DecimalExponentKey.none)
        {
            dec.coefficient.sign = v.type == IonTypeCode.nInt;
            // this is not a FP, so we can discard the exponent 
            ser.putValue(dec.coefficient);
        }
        else if (
            exponentKey == DecimalExponentKey.d 
         || exponentKey == DecimalExponentKey.D
         || exponentKey == DecimalExponentKey.dot)
        {
            ser.putValue(dec);
        }
        else
        { // floats handle infinity / nan / e / E 
            ser.putValue(cast(double)dec);
        }

        return;

        unexpected_decimal_value:
            version(D_Exceptions)
                throw IonDeserializerErrorCode.unexpectedDecimalValue.ionDeserializerException;
            else
                assert(0, "unexpected decimal value");
    }

    @(IonTokenType.TokenBinary)
    void onBinaryNumber() @safe pure
    {
        auto v = t.readValue!(IonTokenType.TokenBinary);
        BigInt!128 val = void;
        if (v[0] == '-')
        {
            val.fromBinaryStringImpl!(char, true)(v[3 .. $]); // skip over the negative + 0b
            val.sign = true;
        }
        else
        {
            val.fromBinaryStringImpl!(char, true)(v[2 .. $]);
        }
        ser.putValue(val);
    }

    @(IonTokenType.TokenHex)
    void onHexNumber() @safe pure
    {
        auto v = t.readValue!(IonTokenType.TokenHex);
        BigInt!128 val = void;
        if (v[0] == '-')
        {
            val.fromHexStringImpl!(char, true)(v[3 .. $]); // skip over the negative + 0x
            val.sign = true;
        }
        else
        {
            val.fromHexStringImpl!(char, true)(v[2 .. $]); // skip over the 0x
        }
        ser.putValue(val);
    }

    @(IonTokenType.TokenFloatInf)
    @(IonTokenType.TokenFloatMinusInf)
    @(IonTokenType.TokenFloatNaN)
    void onFloatSpecial() @safe pure
    {
        if (t.currentToken == IonTokenType.TokenFloatNaN)
        {
            ser.putValue(float.nan);
        }
        else if (t.currentToken == IonTokenType.TokenFloatMinusInf)
        {
            ser.putValue(-float.infinity);
        }
        else
        {
            ser.putValue(float.infinity);
        }
    }

    @(IonTokenType.TokenOpenDoubleBrace)
    void onLob() @safe pure
    {
        import mir.lob;
        auto buf = stringBuf;

        char c = t.skipLobWhitespace();
        if (c == '"')
        {
            IonTextClob clob = t.readClob();
            buf.put(clob.matchedText);
            while (!clob.isFinal) {
                clob = t.readClob();
                buf.put(clob.matchedText);
            }
            ser.putValue(Clob(buf.data));
        }
        else if (c == '\'')
        {
            if (!t.isTripleQuote)
                t.unexpectedChar(c);
            // XXX: ScopedBuffer is unavoidable for the implicit concatenation of long clob values.
            // Replace when we're able to put in a clob by parts (similar to strings)
            IonTextClob clob = t.readClob!true();
            buf.put(clob.matchedText);
            while (!clob.isFinal)
            {
                clob = t.readClob!true();
                buf.put(clob.matchedText);
            }
            ser.putValue(Clob(buf.data));    
        }
        else
        {
            import mir.appender : scopedBuffer;
            import mir.base64 : decodeBase64;
            // This is most likely a "blob", and we need every single
            // character to be read correctly, so we will unread this byte.
            t.unread(c);
            auto decoded = scopedBuffer!ubyte;
            IonTextBlob blob = t.readBlob();
            // Since we don't do any whitespace trimming, we need to do that here...
            foreach(b; blob.matchedText) {
                if (b.isWhitespace) {
                    continue;
                }

                buf.put(b);
            }

            if (buf.data.length % 4 != 0) {
                version(D_Exceptions)
                    throw IonDeserializerErrorCode.invalidBase64Length.ionDeserializerException;
                else
                    assert(0, "invalid Base64 length (maybe missing padding?)");
            }
            decodeBase64(buf.data, decoded);
            ser.putValue(Blob(decoded.data));
        }
        t.finished = true;
    } 
}

/++
Deserialize an Ion Text value to a D value.
Params:
    value = (optional) value to deserialize
    text = The text to deserialize
Returns:
    The deserialized Ion Text value
+/
T deserializeText(T)(scope const(char)[] text)
{
    import mir.deser.ion;
    import mir.ion.conv : text2ion;
    import mir.ion.value;
    import mir.appender : scopedBuffer;

    T value;
    deserializeText!T(value, text);
    return value;
}

///ditto
void deserializeText(T)(scope ref T value, scope const(char)[] text)
{
    import mir.deser.ion;
    import mir.ion.conv : text2ion;
    import mir.ion.value;
    import mir.appender : scopedBuffer;

    auto buf = scopedBuffer!ubyte;
    text2ion(text, buf);
    return deserializeIon!T(value, buf.data);
}

/// Test struct deserialization
@safe pure
version(mir_ion_parser_test) unittest
{
    import mir.ion.value;
    static struct Book
    {
        string title;
        bool wouldRecommend;
        string description;
        uint numberOfNovellas;
        double price;
        float weight;
        string[] tags;
    }

    static immutable textData = `
    {
        "title": "A Hero of Our Time",
        "wouldRecommend": true,
        "description": "",
        "numberOfNovellas": 5,
        "price": 7.99,
        "weight": 6.88,
        "tags": ["russian", "novel", "19th century"]
    }`;

    Book book = deserializeText!Book(textData);
    assert(book.description.length == 0);
    assert(book.numberOfNovellas == 5);
    assert(book.price == 7.99);
    assert(book.tags.length == 3);
    assert(book.tags[0] == "russian");
    assert(book.tags[1] == "novel");
    assert(book.tags[2] == "19th century");
    assert(book.title == "A Hero of Our Time");
    assert(book.weight == 6.88f);
    assert(book.wouldRecommend);
}

/// Test @nogc struct deserialization
@safe pure @nogc
version(mir_ion_parser_test) unittest
{
    import mir.ion.value;
    import mir.bignum.decimal;
    import mir.small_string;
    import mir.small_array;
    import mir.conv : to;
    static struct Book
    {
        SmallString!64 title;
        bool wouldRecommend;
        SmallString!64 description;
        uint numberOfNovellas;
        Decimal!1 price;
        double weight;
        SmallArray!(SmallString!(16), 10) tags;
    }

    static immutable textData = `
    {
        "title": "A Hero of Our Time",
        "wouldRecommend": true,
        "description": "",
        "numberOfNovellas": 5,
        "price": 7.99,
        "weight": 6.88,
        "tags": ["russian", "novel", "19th century"]
    }`;

    Book book = deserializeText!Book(textData);
    assert(book.description.length == 0);
    assert(book.numberOfNovellas == 5);
    assert(book.price.to!double == 7.99);
    assert(book.tags.length == 3);
    assert(book.tags[0] == "russian");
    assert(book.tags[1] == "novel");
    assert(book.tags[2] == "19th century");
    assert(book.title == "A Hero of Our Time");
    assert(book.weight == 6.88f);
    assert(book.wouldRecommend);
}

/// Test that strings are being de-serialized properly
version(mir_ion_parser_test) unittest
{
    import mir.test: should;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    import mir.ser.text;
    void test(const(char)[] ionData, const(char)[] expected)
    {
        const(char)[] output = ionData.text2ion.IonValueStream.serializeText;
        output.should == expected;
    }

    test(`"hello"`, `"hello"`);
    test(`"hello\x20world"`, `"hello world"`);
    test(`"hello\u2248world"`, `"hello≈world"`);
    test(`"hello\U0001F44Dworld"`, `"hello👍world"`);
}

/// Test that timestamps are de-serialized properly
version(mir_ion_parser_test) unittest
{
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    import mir.ion.value : IonTimestamp;
    import std.datetime.date : TimeOfDay;
    import mir.timestamp : Timestamp;
    void test(const(char)[] ionData, Timestamp expected)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            Timestamp t = ionValue.get!(IonTimestamp).get;
            assert(expected == t);
        }
    }
    
    void testFail(const(char)[] ionData, Timestamp expected)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            Timestamp t = ionValue.get!(IonTimestamp).get;
            assert(expected != t);
        }
    }

    test("2001-01T", Timestamp(2001, 1));
    test("2001-01-02", Timestamp(2001, 1, 2));
    test("2001-01-02T", Timestamp(2001, 1, 2));
    test("2001-01-02T03:04", Timestamp(2001, 1, 2, 3, 4));
    test("2001-01-02T03:04Z", Timestamp(2001, 1, 2, 3, 4));
    test("2001-01-02T03:04+00:00", Timestamp(2001, 1, 2, 3, 4));
    test("2001-01-02T03:05+00:01", Timestamp(2001, 1, 2, 3, 4).withOffset(1));
    test("2001-01-02T05:05+02:01", Timestamp(2001, 1, 2, 3, 4).withOffset(2*60+1));
    test("2001-01-02T03:04:05", Timestamp(2001, 1, 2, 3, 4, 5));
    test("2001-01-02T03:04:05Z", Timestamp(2001, 1, 2, 3, 4, 5));
    test("2001-01-02T03:04:05+00:00", Timestamp(2001, 1, 2, 3, 4, 5));
    test("2001-01-02T03:05:05+00:01", Timestamp(2001, 1, 2, 3, 4, 5).withOffset(1));
    test("2001-01-02T05:05:05+02:01", Timestamp(2001, 1, 2, 3, 4, 5).withOffset(2*60+1));
    test("2001-01-02T03:04:05.666", Timestamp(2001, 1, 2, 3, 4, 5, -3, 666));
    test("2001-01-02T03:04:05.666Z", Timestamp(2001, 1, 2, 3, 4, 5, -3, 666));
    test("2001-01-02T03:04:05.666666Z", Timestamp(2001, 1, 2, 3, 4, 5, -6, 666_666));
    test("2001-01-02T03:54:05.666+00:50", Timestamp(2001, 1, 2, 3, 4, 5, -3, 666).withOffset(50));
    test("2001-01-02T03:54:05.666666+00:50", Timestamp(2001, 1, 2, 3, 4, 5, -6, 666_666).withOffset(50));

    // Time of day tests
    test("03:04", Timestamp(0, 0, 0, 3, 4));
    test("03:04Z", Timestamp(0, 0, 0, 3, 4));
    test("03:04+00:00", Timestamp(0, 0, 0, 3, 4));
    test("03:05+00:01", Timestamp(0, 0, 0, 3, 4).withOffset(1));
    test("05:05+02:01", Timestamp(0, 0, 0, 3, 4).withOffset(2*60+1));
    test("03:04:05", Timestamp(0, 0, 0, 3, 4, 5));
    test("03:04:05Z", Timestamp(0, 0, 0, 3, 4, 5));
    test("03:04:05+00:00", Timestamp(0, 0, 0, 3, 4, 5));
    test("03:05:05+00:01", Timestamp(0, 0, 0, 3, 4, 5).withOffset(1));
    test("05:05:05+02:01", Timestamp(0, 0, 0, 3, 4, 5).withOffset(2*60+1));
    test("03:04:05.666", Timestamp(0, 0, 0, 3, 4, 5, -3, 666));
    test("03:04:05.666Z", Timestamp(0, 0, 0, 3, 4, 5, -3, 666));
    test("03:04:05.666666Z", Timestamp(0, 0, 0, 3, 4, 5, -6, 666_666));
    test("03:54:05.666+00:50", Timestamp(0, 0, 0, 3, 4, 5, -3, 666).withOffset(50));
    test("03:54:05.666666+00:50", Timestamp(0, 0, 0, 3, 4, 5, -6, 666_666).withOffset(50));

    // Mir doesn't like 03:04 only (as technically it's less precise then TimeOfDay)... ugh
    test("03:04:05", Timestamp(TimeOfDay(3, 4, 5)));
    test("03:04:05Z", Timestamp(TimeOfDay(3, 4, 5)));
    test("03:04:05+00:00", Timestamp(TimeOfDay(3, 4, 5)));
    test("03:05:05+00:01", Timestamp(TimeOfDay(3, 4, 5)).withOffset(1));
    test("05:05:05+02:01", Timestamp(TimeOfDay(3, 4, 5)).withOffset(2*60+1));

    testFail("2001-01-02T03:04+00:50", Timestamp(2001, 1, 2, 3, 4));
    testFail("2001-01-02T03:04:05+00:50", Timestamp(2001, 1, 2, 3, 4, 5));
    testFail("2001-01-02T03:04:05.666Z", Timestamp(2001, 1, 2, 3, 4, 5));
    testFail("2001-01-02T03:54:05.666+00:50", Timestamp(2001, 1, 2, 3, 4, 5));

    // Fake timestamps for Duration encoding
    import core.time : weeks, days, hours, minutes, seconds, hnsecs;
    test("0005-02-88T07:40:04.9876543", Timestamp(5.weeks + 2.days + 7.hours + 40.minutes + 4.seconds + 9876543.hnsecs));
    test("0005-02-99T07:40:04.9876543", Timestamp(-5.weeks - 2.days - 7.hours - 40.minutes - 4.seconds - 9876543.hnsecs));
}

/// Test that binary literals are de-serialized properly.
version (mir_ion_parser_test) unittest
{
    import mir.ion.value : IonUInt;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    void test(const(char)[] ionData, uint val)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            auto v = ionValue.get!(IonUInt);
            assert(v.get!uint == val);
        }
    }

    test("0b00001", 0b1);
    test("0b10101", 0b10101);
    test("0b11111", 0b11111);
    test("0b111111111111111111111", 0b1111_1111_1111_1111_1111_1);
    test("0b1_1111_1111_1111_1111_1111", 0b1_1111_1111_1111_1111_1111);
}

/// Test that signed / unsigned integers are de-serialized properly.
version (mir_ion_parser_test) unittest
{
    import mir.ion.value : IonUInt, IonNInt;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    void test(const(char)[] ionData, ulong val)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            auto v = ionValue.get!(IonUInt);
            assert(v.get!ulong == val);
        }
    }

    void testNeg(const(char)[] ionData, ulong val)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            auto v = ionValue.get!(IonNInt);
            assert(v.get!long == -val);
        }
    }

    test("0xabc_def", 0xabc_def);
    test("0xabcdef", 0xabcdef);
    test("0xDEADBEEF", 0xDEADBEEF);
    test("0xDEADBEEF", 0xDEAD_BEEF);
    test("0xDEAD_BEEF", 0xDEAD_BEEF);
    test("0xDEAD_BEEF", 0xDEADBEEF);
    test("0x0123456789", 0x0123456789);
    test("0x0123456789abcdef", 0x0123456789abcdef);
    test("0x0123_4567_89ab_cdef", 0x0123_4567_89ab_cdef);

    testNeg("-0xabc_def", 0xabc_def);
    testNeg("-0xabc_def", 0xabc_def);
    testNeg("-0xabcdef", 0xabcdef);
    testNeg("-0xDEADBEEF", 0xDEADBEEF);
    testNeg("-0xDEADBEEF", 0xDEAD_BEEF);
    testNeg("-0xDEAD_BEEF", 0xDEAD_BEEF);
    testNeg("-0xDEAD_BEEF", 0xDEADBEEF);
    testNeg("-0x0123456789", 0x0123456789);
    testNeg("-0x0123456789abcdef", 0x0123456789abcdef);
    testNeg("-0x0123_4567_89ab_cdef", 0x0123_4567_89ab_cdef);

}

/// Test that infinity & negative infinity are deserialized properly.
version (mir_ion_parser_test) unittest
{
    import mir.test: should;
    import mir.ion.value : IonFloat;
    import mir.ion.conv : text2ion;
    import mir.ion.stream;
    void test(const(char)[] ionData, float expected)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            auto v = ionValue.get!(IonFloat);
            v.get!float.should == expected;
        }
    }

    test("-inf", -float.infinity);
    test("+inf", float.infinity);
}

/// Test that NaN is deserialized properly.
version (mir_ion_parser_test) unittest
{
    import mir.ion.value;
    import mir.ion.conv : text2ion;
    import mir.ion.stream;

    alias isNaN = x => x != x;
    void test(const(char)[] ionData)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            auto v = ionValue.get!(IonFloat);
            assert(isNaN(v.get!float));
        }
    }

    test("nan");
}

/// Test that signed / unsigned integers and decimals and floats are all deserialized properly.
version (mir_ion_parser_test) unittest
{
    import mir.test: should;
    import mir.ion.value;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    void test_uint(const(char)[] ionData, ulong expected)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            auto v = ionValue.get!(IonUInt);
            v.get!ulong.should == expected;
        }
    }

    void test_nint(const(char)[] ionData, long expected)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            auto v = ionValue.get!(IonNInt);
            v.get!long.should == expected;
        }
    }

    void test_dec(const(char)[] ionData, double expected)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            auto v = ionValue.get!(IonDecimal);
            v.get!double.should == expected;
        }
    }

    void test_float(const(char)[] ionData, float expected)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            auto v = ionValue.get!(IonFloat);
            v.get!float.should == expected;
        }
    }

    test_uint("123", 123);
    test_nint("-123", -123);
    test_dec("123.123123", 123.123123);
    test_dec("123.123123", 123.123123);
    test_dec("123.123123d0", 123.123123);
    test_dec("123.123123d0", 123.123123);
    test_dec("-123.123123", -123.123123);
    test_dec("-123.123123d0", -123.123123);
    test_dec("18446744073709551615.", 1844_6744_0737_0955_1615.0);
    test_dec("-18446744073709551615.", -1844_6744_0737_0955_1615.0);
    test_dec("18446744073709551616.", 1844_6744_0737_0955_1616.0);
    test_dec("-18446744073709551616.", -1844_6744_0737_0955_1616.0);
    test_float("123.456789e-6", 123.456789e-6);
    test_float("-123.456789e-6", -123.456789e-6);
}

/// Test that quoted / unquoted symbols are deserialized properly.
version (mir_ion_parser_test) unittest
{
    import mir.ion.value;
    import mir.ion.conv : text2ion;
    import mir.ion.stream;
    void test(const(char)[] ionData, string symbol)
    {
        foreach (symbolTable, val; ionData.text2ion.IonValueStream) {
            auto sym = val.get!(IonSymbolID).get;
            assert(symbol == symbolTable[sym]);
        }
    }

    test("$0", "$0");
    test("$ion", "$ion");
    test("$ion_1_0", "$ion_1_0");
    test("name", "name");
    test("version", "version");
    test("imports", "imports");
    test("symbols", "symbols");
    test("max_id", "max_id");
    test("$ion_shared_symbol_table", "$ion_shared_symbol_table");
    test("hello", "hello");
    test("world", "world");
    test("'foobaz'", "foobaz");
    test("'👍'", "👍");
    test("' '", " ");
    test("'\\U0001F44D'", "👍");
    test("'\\u2248'", "\u2248");
    test("'true'", "true");
    test("'false'", "false");
    test("'nan'", "nan");
    test("'null'", "null");
}

/// Test that all variations of the "null" value are deserialized properly.
version (mir_ion_parser_test) unittest
{
    import mir.ion.value;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    void test(const(char)[] ionData, IonTypeCode nullType)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            auto v = ionValue.get!(IonNull);
            assert(v.code == nullType);
        }
    }

    test("null", IonTypeCode.null_);
    test("null.bool", IonTypeCode.bool_);
    test("null.int", IonTypeCode.uInt);
    test("null.float", IonTypeCode.float_);
    test("null.decimal", IonTypeCode.decimal);
    test("null.timestamp", IonTypeCode.timestamp);
    test("null.symbol", IonTypeCode.symbol);
    test("null.string", IonTypeCode.string);
    test("null.blob", IonTypeCode.blob);
    test("null.clob", IonTypeCode.clob);
    test("null.list", IonTypeCode.list);
    test("null.struct", IonTypeCode.struct_);
    test("null.sexp", IonTypeCode.sexp);
}

/// Test that blobs are getting de-serialized correctly. 
version (mir_ion_parser_test) unittest
{
    import mir.ion.value;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    import mir.lob;
    void test(const(char)[] ionData, ubyte[] blobData)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            auto v = ionValue.get!(Blob);
            assert(v.data == blobData);
        }
    }

    test("{{ SGVsbG8sIHdvcmxkIQ== }}", cast(ubyte[])"Hello, world!");
    test("{{ R29vZCBhZnRlcm5vb24hIPCfkY0= }}", cast(ubyte[])"Good afternoon! 👍");
}

/// Test that long/short clobs are getting de-serialized correctly.
version (mir_ion_parser_test) unittest
{
    import mir.ion.value;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    import mir.lob;
    void test(const(char)[] ionData, const(char)[] blobData)
    {
        foreach(symbolTable, scope ionValue; ionData.text2ion.IonValueStream) {
            auto v = ionValue.get!(Clob);
            assert(v.data == blobData);
        }
    }

    test(`{{ "This is a short clob."  }}`, "This is a short clob.");
    test(`
    {{ 
        '''This is a long clob,'''
        ''' which spans over multiple lines,'''
        ''' and can have a theoretically infinite length.'''
    }}`, "This is a long clob, which spans over multiple lines, and can have a theoretically infinite length.");
    test(`{{ 
            '''Long clobs can also have their data contained in one value,
 but spread out across multiple lines.'''
          }}`, "Long clobs can also have their data contained in one value,\n but spread out across multiple lines.");
    test(`{{ '''Or, you can have multiple values on the same line,''' ''' like this!'''}}`, 
        "Or, you can have multiple values on the same line, like this!");
}

/// Test that structs are getting de-serialized properly 
version (mir_ion_parser_test)
unittest
{
    import mir.test: should;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    import mir.ser.text;
    void test(const(char)[] ionData, const(char)[] expected)
    {
        auto v = ionData.text2ion.IonValueStream.serializeText;
        v.should == expected;
    }

    test(`1`, `1`);
    test(`test::1`, `test::1`);

    test(`{"test":"world", test: false, 'test': usd::123.456, '''test''': "asdf"}`,
         `{test:"world",test:false,test:usd::123.456,test:"asdf"}`);

    test(`{'''foo'''
    '''bar''': "foobar"}`,
         `{foobar:"foobar"}`);

    test(`{a: 1, b: 2}`, `{a:1,b:2}`);

    test(`{}`, `{}`);
}

/// Test that sexps are getting de-serialized properly.
version (mir_ion_parser_test) unittest
{
    import mir.test: should;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    import mir.ser.text;
    void test(const(char)[] ionData, const(char)[] expected)
    {
        auto v = ionData.text2ion.IonValueStream.serializeText;
        v.should == expected;
    }

    test(`(this is a sexp list)`, "(this is a sexp list)");
    test(`('+' '++' '+-+' '-++' '-' '--' '---' -3 - 3 '--' 3 '--'3 )`, 
        "('+' '++' '+-+' '-++' '-' '--' '---' -3 '-' 3 '--' 3 '--' 3)");
    test(`(a_plus_plus_plus_operator::+++ a_3::3)`, `(a_plus_plus_plus_operator::'+++' a_3::3)`);
    test(`(& (% -[42, 3]+(2)-))`, `('&' ('%' '-' [42,3] '+' (2) '-'))`);
}

/// Test that arrays are getting de-serialized properly.
version (mir_ion_parser_test) unittest
{
    import mir.test: should;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    import mir.ser.text;
    void test(const(char)[] ionData, const(char)[] expected)
    {
        auto v = ionData.text2ion.IonValueStream.serializeText;
        v.should == expected;
    }

    test(`[hello, world]`, `[hello,world]`);
    test(`[this::is::an::annotated::symbol, this::is::annotated::123.456]`,
         `[this::is::an::annotated::symbol,this::is::annotated::123.456]`);
    test(`[date::of::birth::0001-01-01T00:00:00.0-00:00, date::of::birth::1970-01-01T]`,
         `[date::of::birth::0001-01-01T00:00:00.0Z,date::of::birth::1970-01-01]`);
    test(`['hello', "hello", '''hello''', '''hello ''''''world''']`,
         `[hello,"hello","hello","hello world"]`);
    test(`[0x123_456, 0xF00D_BAD]`, `[1193046,251714477]`);
}

/// Test that annotations work with symbols
version (mir_ion_parser_test) unittest
{
    import mir.test: should;
    import mir.ion.stream;
    import mir.ser.text;
    import mir.ion.conv : text2ion;
    void test(const(char)[] ionData, const(char)[] expected)
    {
        auto v = ionData.text2ion.IonValueStream.serializeText;
        v.should == expected;
    }

    test(`'test'::'hello'::'world'`, "test::hello::world");
    test(`foo::bar`, "foo::bar");
    test(`foo::'bar'`, "foo::bar");
    test(`'foo'::bar`, "foo::bar");
    test(`'foo bar'::cash`, "'foo bar'::cash");
    test(`'foo\U0001F44D'::'baz\U0001F44D'`, "'foo\U0001F44D'::'baz\U0001F44D'");
    test(`'\u2248'::'\u2248'`, "'\u2248'::'\u2248'");
    test(`'\u2248'::foo`, "'\u2248'::foo");
}

/// Test that annotations work with floats
version (mir_ion_parser_test) unittest
{
    import mir.test: should;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    import mir.ser.text;
    void test(const(char)[] ionData, const(char)[] expected)
    {
        auto v = ionData.text2ion.IonValueStream.serializeText;
        v.should == expected;
    }

    test(`usd::10.50e0`, "usd::10.5");
    test(`'Value is good \U0001F44D'::12.34e0`, "'Value is good \U0001F44D'::12.34");
    test(`'null'::150.00e0`, "'null'::150.0");
}

/// Test that annotations work with decimals 
version (mir_ion_parser_test) unittest
{
    import mir.test: should;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    import mir.ser.text;
    void test(const(char)[] ionData, const(char)[] expected)
    {
        auto v = ionData.text2ion.IonValueStream.serializeText;
        v.should == expected;
    }

    test(`Types::Speed::MetersPerSecondSquared::9.81`, "Types::Speed::MetersPerSecondSquared::9.81");
    test(`Rate::USD::GBP::12.345`, "Rate::USD::GBP::12.345");
    test(`usd::10.50d0`, "usd::10.50");
    test(`'Value is good \U0001F44D'::12.34d0`, "'Value is good \U0001F44D'::12.34");
    test(`'null'::150.00d0`, "'null'::150.00");
    test(`'Cool'::27182818284590450000000000d-25`, "Cool::2.7182818284590450000000000");
    test(`mass::2.718281828459045d0`, "mass::2.718281828459045");
    test(`weight::0.000000027182818284590450000000000d+8`, "weight::2.7182818284590450000000000");
    test(`coeff::-0.000000027182818284590450000000000d+8`, "coeff::-2.7182818284590450000000000");
}

/// Test that annotations work with strings
version (mir_ion_parser_test) unittest
{
    import mir.test: should;
    import mir.ion.stream;
    import mir.ion.conv : text2ion;
    import mir.ser.text;
    void test(const(char)[] ionData, const(char)[] expected)
    {
        auto v = ionData.text2ion.IonValueStream.serializeText;
        v.should == expected;
    }

    test(`Password::"Super Secure Password"`, `Password::"Super Secure Password"`);
    test(`Magic::String::"Hello, world!"`, `Magic::String::"Hello, world!"`);
    test(`SSH::PublicKey::'''ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNrMk7QmmmNIusf10CwHQHs6Z9HJIiuknwoqtQLzEPxdMnNHKJexNnfF5QQ2v84BBhVjxvPgSqhdcVMEFy8PrGu44MqhK/cV6BGx430v2FnArWDO+9LUSd+3iwMJVZUQgZGtjSLAkZO+NOSPWZ+W0SODGgUfbNVu35GjVoA2+e1lOINUe22oZPnaD+gpJGUOx7j5JqpCblBZntvZyOjTPl3pc52rIGfxi1TYJnDXjqX76OinZceBzp5Oh0oUTrPbu55ig+b8bd4HtzLWxcqXBCnsw0OAKsAiXfLlBcrgZUsoAP9unrcqsqoJ2qEEumdsPqcpJakpO7/n0lMP6lRdSZ'''`,
         `SSH::PublicKey::"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNrMk7QmmmNIusf10CwHQHs6Z9HJIiuknwoqtQLzEPxdMnNHKJexNnfF5QQ2v84BBhVjxvPgSqhdcVMEFy8PrGu44MqhK/cV6BGx430v2FnArWDO+9LUSd+3iwMJVZUQgZGtjSLAkZO+NOSPWZ+W0SODGgUfbNVu35GjVoA2+e1lOINUe22oZPnaD+gpJGUOx7j5JqpCblBZntvZyOjTPl3pc52rIGfxi1TYJnDXjqX76OinZceBzp5Oh0oUTrPbu55ig+b8bd4HtzLWxcqXBCnsw0OAKsAiXfLlBcrgZUsoAP9unrcqsqoJ2qEEumdsPqcpJakpO7/n0lMP6lRdSZ"`);
}
