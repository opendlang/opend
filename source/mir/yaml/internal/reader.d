
//          Copyright Ferdinand Majerech 2011-2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module mir.internal.yaml.reader;

import mir.array.allocation: array;
import mir.conv;
import mir.internal.yaml.exception;
import mir.utility: min;
import std.algorithm.comparison: among;
import std.utf;

alias isBreak = among!('\n', '\u0085', '\u2028', '\u2029');

package:


///Exception thrown at Reader errors.
class ReaderException : YamlException
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
        @safe pure nothrow
    {
        super("Reader error: " ~ msg, file, line);
    }
}

/// Provides an API to read characters from a UTF-8 buffer and build slices into that
/// buffer to avoid allocations (see Reader).
struct Reader
{
    @disable this(this) {}
    private:
        // Buffer of currently loaded characters.
        char[] buffer_;

        // Current position within buffer. Only data after this position can be read.
        size_t bufferOffset_;

        // Index of the current character in the buffer.
        size_t charIndex_;
        // Number of characters (code points) in buffer_.
        size_t characterCount_;

        // File name
        package string name;
        // Current line in file.
        uint line_;
        // Current column in file.
        uint column_;

        // The number of consecutive ASCII characters starting at bufferOffset_.
        //
        // Used to minimize UTF-8 decoding.
        size_t upcomingASCII_;

        // Index to buffer_ where the last decoded character starts.
        size_t lastDecodedBufferOffset_;
        // Offset, relative to charIndex_, of the last decoded character,
        // in code points, not chars.
        size_t lastDecodedCharOffset_;


    public:
        /// Construct a Reader.
        ///
        /// Params:  buffer = string with YAML data.
        ///          name   = File name if the buffer is the contents of a file or
        ///                   `"<unknown>"` if the buffer is the contents of a string.
        ///
        /// Throws:  ReaderException on a UTF decoding error or if there are
        ///          nonprintable Unicode characters illegal in YAML.
        this(scope const(char)[] buffer, string name = "<unknown>") @safe pure
        {
            import std.utf: count, validate, UTFException;

            this.name = name;
            buffer_ = buffer.dup;
            characterCount_ = buffer_.count;
            // Check that all characters in buffer are printable.
            validate(buffer_);

            if (buffer_.length >= 3 && buffer_[0 .. 3] == [char(0xEF), 0xBB, 0xBF])
                throw new UTFException("YAML: UTF-8 BOM isn't allowed");
            if (!isPrintableValidUTF8(buffer_))
                throw new UTFException("YAML: Special unicode characters are not allowed");

            // this.sliceBuilder = Reader(&this);
            checkASCII();
        }

        /// Get character at specified index relative to current position.
        ///
        /// Params:  index = Index of the character to get relative to current position
        ///                  in the buffer. Can point outside of the buffer; In that
        ///                  case, '\0' will be returned.
        ///
        /// Returns: Character at specified position or '\0' if outside of the buffer.
        ///
        // XXX removed; search for 'risky' to find why.
        // Throws:  ReaderException if trying to read past the end of the buffer.
        dchar peek(const size_t index) @safe pure
        {
            if(index < upcomingASCII_) { return buffer_[bufferOffset_ + index]; }
            if(characterCount_ <= charIndex_ + index)
            {
                // XXX This is risky; revert this if bugs are introduced. We rely on
                // the assumption that Reader only uses peek() to detect end of buffer.
                // The test suite passes.
                // Revert this case here and in other peek() versions if this causes
                // errors.
                // throw new ReaderException("Trying to read past the end of the buffer");
                return '\0';
            }

            // Optimized path for Scanner code that peeks chars in linear order to
            // determine the length of some sequence.
            if(index == lastDecodedCharOffset_)
            {
                ++lastDecodedCharOffset_;
                const char b = buffer_[lastDecodedBufferOffset_];
                // ASCII
                if(b < 0x80)
                {
                    ++lastDecodedBufferOffset_;
                    return b;
                }
                return decode(buffer_, lastDecodedBufferOffset_);
            }

            // 'Slow' path where we decode everything up to the requested character.
            const asciiToTake = min(upcomingASCII_, index);
            lastDecodedCharOffset_   = asciiToTake;
            lastDecodedBufferOffset_ = bufferOffset_ + asciiToTake;
            dchar d;
            while(lastDecodedCharOffset_ <= index)
            {
                d = decodeNext();
            }

            return d;
        }

        /// Optimized version of peek() for the case where peek index is 0.
        dchar peek() @safe pure
        {
            if(upcomingASCII_ > 0)            { return buffer_[bufferOffset_]; }
            if(characterCount_ <= charIndex_) { return '\0'; }

            lastDecodedCharOffset_   = 0;
            lastDecodedBufferOffset_ = bufferOffset_;
            return decodeNext();
        }

        /// Get byte at specified index relative to current position.
        ///
        /// Params:  index = Index of the byte to get relative to current position
        ///                  in the buffer. Can point outside of the buffer; In that
        ///                  case, '\0' will be returned.
        ///
        /// Returns: Byte at specified position or '\0' if outside of the buffer.
        char peekByte(const size_t index) @safe pure nothrow @nogc
        {
            return characterCount_ > (charIndex_ + index) ? buffer_[bufferOffset_ + index] : '\0';
        }

        /// Optimized version of peekByte() for the case where peek byte index is 0.
        char peekByte() @safe pure nothrow @nogc
        {
            return characterCount_ > charIndex_ ? buffer_[bufferOffset_] : '\0';
        }


        /// Get specified number of characters starting at current position.
        ///
        /// Note: This gets only a "view" into the internal buffer, which will be
        ///       invalidated after other Reader calls. Use Reader to build slices
        ///       for permanent use.
        ///
        /// Params: length = Number of characters (code points, not bytes) to get. May
        ///                  reach past the end of the buffer; in that case the returned
        ///                  slice will be shorter.
        ///
        /// Returns: Characters starting at current position or an empty slice if out of bounds.
        const(char)[] prefix(const size_t length) @safe pure
        {
            return slice(length);
        }

        /// Get specified number of bytes, not code points, starting at current position.
        ///
        /// Note: This gets only a "view" into the internal buffer, which will be
        ///       invalidated after other Reader calls. Use Reader to build slices
        ///       for permanent use.
        ///
        /// Params: length = Number bytes (not code points) to get. May NOT reach past
        ///                  the end of the buffer; should be used with peek() to avoid
        ///                  this.
        ///
        /// Returns: Bytes starting at current position.
        const(char)[] prefixBytes(const size_t length) @safe pure nothrow @nogc
        in(length == 0 || bufferOffset_ + length <= buffer_.length, "prefixBytes out of bounds")
        {
            return buffer_[bufferOffset_ .. bufferOffset_ + length];
        }

        /// Get a slice view of the internal buffer, starting at the current position.
        ///
        /// Note: This gets only a "view" into the internal buffer,
        ///       which get invalidated after other Reader calls.
        ///
        /// Params:  end = End of the slice relative to current position. May reach past
        ///                the end of the buffer; in that case the returned slice will
        ///                be shorter.
        ///
        /// Returns: Slice into the internal buffer or an empty slice if out of bounds.
        const(char)[] slice(const size_t end) @safe pure
        {
            // Fast path in case the caller has already peek()ed all the way to end.
            if(end == lastDecodedCharOffset_)
            {
                return buffer_[bufferOffset_ .. lastDecodedBufferOffset_];
            }

            const asciiToTake = min(upcomingASCII_, end, buffer_.length);
            lastDecodedCharOffset_   = asciiToTake;
            lastDecodedBufferOffset_ = bufferOffset_ + asciiToTake;

            // 'Slow' path - decode everything up to end.
            while(lastDecodedCharOffset_ < end &&
                  lastDecodedBufferOffset_ < buffer_.length)
            {
                decodeNext();
            }

            return buffer_[bufferOffset_ .. lastDecodedBufferOffset_];
        }

        /// Get the next character, moving buffer position beyond it.
        ///
        /// Returns: Next character.
        ///
        /// Throws:  ReaderException if trying to read past the end of the buffer
        ///          or if invalid data is read.
        dchar get() @safe pure
        {
            const result = peek();
            forward();
            return result;
        }

        /// Get specified number of characters, moving buffer position beyond them.
        ///
        /// Params:  length = Number or characters (code points, not bytes) to get.
        ///
        /// Returns: Characters starting at current position.
        const(char)[] get(const size_t length) @safe pure
        {
            auto result = slice(length);
            forward(length);
            return result;
        }

        /// Move current position forward.
        ///
        /// Params:  length = Number of characters to move position forward.
        void forward(size_t length) @safe pure
        {
            while(length > 0)
            {
                auto asciiToTake = min(upcomingASCII_, length);
                charIndex_     += asciiToTake;
                length         -= asciiToTake;
                upcomingASCII_ -= asciiToTake;

                for(; asciiToTake > 0; --asciiToTake)
                {
                    const c = buffer_[bufferOffset_++];
                    // c is ASCII, do we only need to check for ASCII line breaks.
                    if(c == '\n' || (c == '\r' && buffer_[bufferOffset_] != '\n'))
                    {
                        ++line_;
                        column_ = 0;
                        continue;
                    }
                    ++column_;
                }

                // If we have used up all upcoming ASCII chars, the next char is
                // non-ASCII even after this returns, so upcomingASCII_ doesn't need to
                // be updated - it's zero.
                if(length == 0) { break; }

                assert(upcomingASCII_ == 0,
                       "Running unicode handling code but we haven't run out of ASCII chars");
                assert(bufferOffset_ < buffer_.length,
                       "Attempted to decode past the end of YAML buffer");
                assert(buffer_[bufferOffset_] >= 0x80,
                       "ASCII must be handled by preceding code");

                ++charIndex_;
                const c = decode(buffer_, bufferOffset_);

                // New line. (can compare with '\n' without decoding since it's ASCII)
                if(c.isBreak || (c == '\r' && buffer_[bufferOffset_] != '\n'))
                {
                    ++line_;
                    column_ = 0;
                }
                else if(c != '\uFEFF') { ++column_; }
                --length;
                checkASCII();
            }

            lastDecodedBufferOffset_ = bufferOffset_;
            lastDecodedCharOffset_ = 0;
        }

        /// Move current position forward by one character.
        void forward() @safe pure
        {
            ++charIndex_;
            lastDecodedBufferOffset_ = bufferOffset_;
            lastDecodedCharOffset_ = 0;

            // ASCII
            if(upcomingASCII_ > 0)
            {
                --upcomingASCII_;
                const c = buffer_[bufferOffset_++];

                if(c == '\n' || (c == '\r' && buffer_[bufferOffset_] != '\n'))
                {
                    ++line_;
                    column_ = 0;
                    return;
                }
                ++column_;
                return;
            }

            // UTF-8
            assert(bufferOffset_ < buffer_.length,
                   "Attempted to decode past the end of YAML buffer");
            assert(buffer_[bufferOffset_] >= 0x80,
                   "ASCII must be handled by preceding code");

            const c = decode(buffer_, bufferOffset_);

            // New line. (can compare with '\n' without decoding since it's ASCII)
            if(c.isBreak || (c == '\r' && buffer_[bufferOffset_] != '\n'))
            {
                ++line_;
                column_ = 0;
            }
            else if(c != '\uFEFF') { ++column_; }

            checkASCII();
        }

        /// Get a string describing current buffer position, used for error messages.
        ParsePosition mark() const pure nothrow @nogc @safe { return ParsePosition(name, line_ + 1, column_ + 1); }

        /// Get current line number.
        uint line() const @safe pure nothrow @nogc { return line_; }

        /// Get current column number.
        uint column() const @safe pure nothrow @nogc { return column_; }

        /// Get index of the current character in the buffer.
        size_t charIndex() const @safe pure nothrow @nogc { return charIndex_; }

private:
        // Update upcomingASCII_ (should be called forward()ing over a UTF-8 sequence)
        void checkASCII() @safe pure nothrow @nogc
        {
            upcomingASCII_ = countASCII(buffer_[bufferOffset_ .. $]);
        }

        // Decode the next character relative to
        // lastDecodedCharOffset_/lastDecodedBufferOffset_ and update them.
        //
        // Does not advance the buffer position. Used in peek() and slice().
        dchar decodeNext() @safe pure
        {
            assert(lastDecodedBufferOffset_ < buffer_.length,
                   "Attempted to decode past the end of YAML buffer");
            const char b = buffer_[lastDecodedBufferOffset_];
            ++lastDecodedCharOffset_;
            // ASCII
            if(b < 0x80)
            {
                ++lastDecodedBufferOffset_;
                return b;
            }

            return decode(buffer_, lastDecodedBufferOffset_);
        }
private:

    // // Reader this builder works in.
    // Reader* reader_;

    // Start of the slice om buffer_ (size_t.max while no slice being build)
    size_t start_ = size_t.max;
    // End of the slice om buffer_ (size_t.max while no slice being build)
    size_t end_   = size_t.max;

    // Stack of slice ends to revert to (see Transaction)
    //
    // Very few levels as we don't want arbitrarily nested transactions.
    size_t[4] endStack_;
    // The number of elements currently in endStack_.
    size_t endStackUsed_;

    @safe const pure nothrow @nogc invariant()
    {
        if(!inProgress) { return; }
        assert(end_ <= bufferOffset_, "Slice ends after buffer position");
        assert(start_ <= end_, "Slice start after slice end");
    }

    // Is a slice currently being built?
    bool inProgress() @safe const pure nothrow @nogc
    in(start_ == size_t.max ? end_ == size_t.max : end_ != size_t.max, "start_/end_ are not consistent")
    {
        return start_ != size_t.max;
    }

public:
    /// Begin building a slice.
    ///
    /// Only one slice can be built at any given time; before beginning a new slice,
    /// finish the previous one (if any).
    ///
    /// The slice starts at the current position in the Reader buffer. It can only be
    /// extended up to the current position in the buffer; Reader methods get() and
    /// forward() move the position. E.g. it is valid to extend a slice by write()-ing
    /// a string just returned by get() - but not one returned by prefix() unless the
    /// position has changed since the prefix() call.
    void begin() @safe pure nothrow @nogc
    in(!inProgress, "Beginning a slice while another slice is being built")
    in(endStackUsed_ == 0, "Slice stack not empty at slice begin")
    {

        start_ = bufferOffset_;
        end_   = bufferOffset_;
    }

    /// Finish building a slice and return it.
    ///
    /// Any Transactions on the slice must be committed or destroyed before the slice
    /// is finished.
    ///
    /// Returns a string; once a slice is finished it is definitive that its contents
    /// will not be changed.
    const(char)[] finish() @safe pure nothrow @nogc
    in(inProgress, "finish called without begin")
    in(endStackUsed_ == 0, "Finishing a slice with running transactions.")
    {

        auto result = buffer_[start_ .. end_];
        start_ = end_ = size_t.max;
        return result;
    }

    /// Write a string to the slice being built.
    ///
    /// Data can only be written up to the current position in the Reader buffer.
    ///
    /// If str is a string returned by a Reader method, and str starts right after the
    /// end of the slice being built, the slice is extended (trivial operation).
    ///
    /// See_Also: begin
    void write(scope const char[] str) @safe pure nothrow @nogc
    {
        assert(inProgress, "write called without begin");
        assert(end_ <= bufferOffset_,
            "AT START: Slice ends after buffer position");

        // Nothing? Already done.
        if (str.length == 0) { return; }
        // If str starts at the end of the slice (is a string returned by a Reader
        // method), just extend the slice to contain str.
        if(&str[0] == &buffer_[end_])
        {
            end_ += str.length;
        }
        // Even if str does not start at the end of the slice, it still may be returned
        // by a Reader method and point to buffer. So we need to memmove.
        else
        {
            import std.algorithm.mutation: copy;
            copy(str, buffer_[end_..end_ + str.length * char.sizeof]);
            end_ += str.length;
        }
    }

    /// Write a character to the slice being built.
    ///
    /// Data can only be written up to the current position in the Reader buffer.
    ///
    /// See_Also: begin
    void write(dchar c) @safe pure
    in(inProgress, "write called without begin")
    {
        if(c < 0x80)
        {
            buffer_[end_++] = cast(char)c;
            return;
        }

        // We need to encode a non-ASCII dchar into UTF-8
        char[4] encodeBuf;
        const bytes = encode(encodeBuf, c);
        buffer_[end_ .. end_ + bytes] = encodeBuf[0 .. bytes];
        end_ += bytes;
    }

    /// Insert a character to a specified position in the slice.
    ///
    /// Enlarges the slice by 1 char. Note that the slice can only extend up to the
    /// current position in the Reader buffer.
    ///
    /// Params:
    ///
    /// c        = The character to insert.
    /// position = Position to insert the character at in code units, not code points.
    ///            Must be less than slice length(); a previously returned length()
    ///            can be used.
    void insert(const dchar c, const size_t position) @safe pure
    in(inProgress, "insert called without begin")
    in(start_ + position <= end_, "Trying to insert after the end of the slice")
    {

        const point       = start_ + position;
        const movedLength = end_ - point;

        // Encode c into UTF-8
        char[4] encodeBuf;
        if(c < 0x80) { encodeBuf[0] = cast(char)c; }
        const size_t bytes = c < 0x80 ? 1 : encode(encodeBuf, c);

        if(movedLength > 0)
        {
            import std.algorithm.mutation: copy;
            copy(buffer_[point..point + movedLength * char.sizeof],
                    buffer_[point + bytes..point + bytes + movedLength * char.sizeof]);
        }
        buffer_[point .. point + bytes] = encodeBuf[0 .. bytes];
        end_ += bytes;
    }

    /// Get the current length of the slice.
    size_t length() @safe const pure nothrow @nogc
    {
        return end_ - start_;
    }

    /// A slice building transaction.
    ///
    /// Can be used to save and revert back to slice state.
    struct Transaction
    {
    private:
        // The slice builder affected by the transaction.
        // Reader* builder_;
        // Index of the return point of the transaction in StringBuilder.endStack_.
        size_t stackLevel_;
        // True after commit() has been called.
        bool committed_;
        bool ended_ = true;

    public:
        /// Begins a transaction on a Reader object.
        ///
        /// The transaction must end $(B after) any transactions created within the
        /// transaction but $(B before) the slice is finish()-ed. A transaction can be
        /// ended either by commit()-ing or reverting through the destructor.
        ///
        /// Saves the current state of a slice.
        this(ref Reader builder) @safe pure nothrow @nogc
        {
            ended_ = false;
            stackLevel_ = builder.endStackUsed_;
            builder.push();
        }

    scope:
        /// Commit changes to the slice.
        ///
        /// Ends the transaction - can only be called once, and removes the possibility
        /// to revert slice state.
        ///
        /// Does nothing for a default-initialized transaction (the transaction has not
        /// been started yet).
        void commit(ref Reader builder) @safe pure nothrow @nogc
        in(!committed_, "Can't commit a transaction more than once")
        {

            if(ended_) { return; }
            assert(builder.endStackUsed_ == stackLevel_ + 1,
                "Parent transactions don't fully contain child transactions");
            builder.apply();
            committed_ = true;
        }

        /// Destroy the transaction and revert it if it hasn't been committed yet.
        void end(ref Reader builder) @safe pure nothrow @nogc
        in(!ended_ && builder.endStackUsed_ == stackLevel_ + 1, "Parent transactions don't fully contain child transactions")
        {
        // if(!ended_ && builder.endStackUsed_ == stackLevel_ + 1, "Parent transactions don't fully contain child transactions")

            builder.pop();
            ended_ = true;
        }
    }

private:
    // Push the current end of the slice so we can revert to it if needed.
    //
    // Used by Transaction.
    void push() @safe pure nothrow @nogc
    in(inProgress, "push called without begin")
    in(endStackUsed_ < endStack_.length, "Slice stack overflow")
    {
        endStack_[endStackUsed_++] = end_;
    }

    // Pop the current end of endStack_ and set the end of the slice to the popped
    // value, reverting changes since the old end was pushed.
    //
    // Used by Transaction.
    void pop() @safe pure nothrow @nogc
    in(inProgress, "pop called without begin")
    in(endStackUsed_ > 0, "Trying to pop an empty slice stack")
    {
        end_ = endStack_[--endStackUsed_];
    }

    // Pop the current end of endStack_, but keep the current end of the slice, applying
    // changes made since pushing the old end.
    //
    // Used by Transaction.
    void apply() @safe pure nothrow @nogc
    in(inProgress, "apply called without begin")
    in(endStackUsed_ > 0, "Trying to apply an empty slice stack")
    {
        --endStackUsed_;
    }

}

/// Used to build slices of already read data in Reader buffer, avoiding allocations.
///
/// Usually these slices point to unchanged Reader data, but sometimes the data is
/// changed due to how YAML interprets certain characters/strings.
///
/// See begin() documentation.



private:

/// Determine if all characters (code points, not bytes) in a string are printable.
bool isPrintableValidUTF8(scope const char[] chars) @safe pure
{
    import std.uni : isControl, isWhite;
    foreach (dchar chr; chars)
    {
        if (!chr.isValidDchar || (chr.isControl && !chr.isWhite))
        {
            return false;
        }
    }
    return true;
}

/// Counts the number of ASCII characters in buffer until the first UTF-8 sequence.
///
/// Used to determine how many characters we can process without decoding.
size_t countASCII(const(char)[] buffer) @safe pure nothrow @nogc
{
    import mir.primitives: walkLength;
    import std.algorithm.searching: until;
    return buffer.byCodeUnit.until!(x => x > 0x7F).walkLength;
}
// Unittests.

void testPeekPrefixForward(R)()
{
    string data = "data";
    auto reader = new R(data);
    assert(reader.peek() == 'd');
    assert(reader.peek(1) == 'a');
    assert(reader.peek(2) == 't');
    assert(reader.peek(3) == 'a');
    assert(reader.peek(4) == '\0');
    assert(reader.prefix(4) == "data");
    // assert(reader.prefix(6) == "data\0");
    reader.forward(2);
    assert(reader.peek(1) == 'a');
    // assert(collectException(reader.peek(3)));
}

void test1Byte(R)()
{
    string data = [97];

    auto reader = new R(data);
    assert(reader.peek() == 'a');
    assert(reader.peek(1) == '\0');
    // assert(collectException(reader.peek(2)));
}

@system unittest
{
    testPeekPrefixForward!Reader();
    test1Byte!Reader();
}
//Issue 257 - https://github.com/dlang-community/D-YAML/issues/257
@safe unittest
{
    import mir.internal.yaml.loader : Loader;
    auto yaml = "hello ";
    auto root = Loader.fromString(yaml).load();
    assert(root._is!string);
}
