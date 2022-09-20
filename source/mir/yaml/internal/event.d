
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/**
 * YAML events.
 * Code based on PyYAML: http://www.pyyaml.org
 */
module mir.internal.yaml.event;

import std.array;
import std.conv;

import mir.internal.yaml.exception;
import mir.internal.yaml.reader;
import mir.internal.yaml.tagdirective;
import mir.algebraic_alias.yaml: YamlScalarStyle, YamlCollectionStyle;


package:
///Event types.
enum EventID : ubyte
{
    invalid = 0,     /// Invalid (uninitialized) event.
    streamStart,     /// Stream start
    streamEnd,       /// Stream end
    documentStart,   /// Document start
    documentEnd,     /// Document end
    alias_,           /// Alias
    scalar,          /// Scalar
    sequenceStart,   /// Sequence start
    sequenceEnd,     /// Sequence end
    mappingStart,    /// Mapping start
    mappingEnd       /// Mapping end
}

/**
 * YAML event produced by parser.
 *
 * 48 bytes on 64bit.
 */
struct Event
{
    @disable int opCmp(ref Event);

    ///Value of the event, if any.
    string value;
    ///Start position of the event in file/stream.
    ParsePosition startMark;
    ///End position of the event in file/stream.
    ParsePosition endMark;
    struct
    {
        struct
        {
            ///Anchor of the event, if any.
            string _anchor;
            ///Tag of the event, if any.
            string _tag;
        }
        ///Tag directives, if this is a DocumentStart.
        //TagDirectives tagDirectives;
        TagDirective[] _tagDirectives;
    }
    ///Event type.
    EventID id = EventID.invalid;
    ///Style of scalar event, if this is a scalar event.
    YamlScalarStyle scalarStyle = YamlScalarStyle.invalid;
    struct
    {
        ///Should the tag be implicitly resolved?
        bool implicit;
        /**
         * Is this document event explicit?
         *
         * Used if this is a DocumentStart or DocumentEnd.
         */
        bool explicitDocument;
    }
    ///Collection style, if this is a SequenceStart or MappingStart.
    YamlCollectionStyle collectionStyle = YamlCollectionStyle.invalid;

    ///Is this a null (uninitialized) event?
    @property bool isNull() const pure @safe nothrow {return id == EventID.invalid;}

    ///Get string representation of the token ID.
    @property string idString() const @safe {return to!string(id);}

    auto ref anchor() inout @trusted pure {
        assert(id != EventID.documentStart, "DocumentStart events cannot have anchors.");
        return _anchor;
    }

    auto ref tag() inout @trusted pure {
        assert(id != EventID.documentStart, "DocumentStart events cannot have tags.");
        return _tag;
    }

    auto ref tagDirectives() inout @trusted pure {
        assert(id == EventID.documentStart, "Only DocumentStart events have tag directives.");
        return _tagDirectives;
    }
}

/**
 * Construct a simple event.
 *
 * Params:  start    = Start position of the event in the file/stream.
 *          end      = End position of the event in the file/stream.
 *          anchor   = Anchor, if this is an alias event.
 */
Event event(EventID id)(const ParsePosition start, const ParsePosition end, const string anchor = null)
    @safe
    in(!(id == EventID.alias_ && anchor == ""), "Missing anchor for alias event")
{
    Event result;
    result.startMark = start;
    result.endMark   = end;
    result.anchor    = anchor;
    result.id        = id;
    return result;
}

/**
 * Construct a collection (mapping or sequence) start event.
 *
 * Params:  start    = Start position of the event in the file/stream.
 *          end      = End position of the event in the file/stream.
 *          anchor   = Anchor of the sequence, if any.
 *          tag      = Tag of the sequence, if specified.
 *          implicit = Should the tag be implicitly resolved?
 *          style = Style to use when outputting document.
 */
Event collectionStartEvent(EventID id)
    (const ParsePosition start, const ParsePosition end, const string anchor, const string tag,
     const bool implicit, const YamlCollectionStyle style) pure @safe nothrow
{
    static assert(id == EventID.sequenceStart || id == EventID.sequenceEnd ||
                  id == EventID.mappingStart || id == EventID.mappingEnd);
    Event result;
    result.startMark       = start;
    result.endMark         = end;
    result.anchor          = anchor;
    result.tag             = tag;
    result.id              = id;
    result.implicit        = implicit;
    result.collectionStyle = style;
    return result;
}

/**
 * Construct a stream start event.
 *
 * Params:  start    = Start position of the event in the file/stream.
 *          end      = End position of the event in the file/stream.
 */
Event streamStartEvent(const ParsePosition start, const ParsePosition end)
    pure @safe nothrow
{
    Event result;
    result.startMark = start;
    result.endMark   = end;
    result.id        = EventID.streamStart;
    return result;
}

///Aliases for simple events.
alias streamEndEvent = event!(EventID.streamEnd);
alias aliasEvent = event!(EventID.alias_);
alias sequenceEndEvent = event!(EventID.sequenceEnd);
alias mappingEndEvent = event!(EventID.mappingEnd);

///Aliases for collection start events.
alias sequenceStartEvent = collectionStartEvent!(EventID.sequenceStart);
alias mappingStartEvent = collectionStartEvent!(EventID.mappingStart);

/**
 * Construct a document start event.
 *
 * Params:  start         = Start position of the event in the file/stream.
 *          end           = End position of the event in the file/stream.
 *          explicit      = Is this an explicit document start?
 *          YAMLVersion   = YAML version string of the document.
 *          tagDirectives = Tag directives of the document.
 */
Event documentStartEvent(const ParsePosition start, const ParsePosition end, const bool explicit, string YAMLVersion,
                         TagDirective[] tagDirectives) pure @safe nothrow
{
    Event result;
    result.value            = YAMLVersion;
    result.startMark        = start;
    result.endMark          = end;
    result.id               = EventID.documentStart;
    result.explicitDocument = explicit;
    result.tagDirectives    = tagDirectives;
    return result;
}

/**
 * Construct a document end event.
 *
 * Params:  start    = Start position of the event in the file/stream.
 *          end      = End position of the event in the file/stream.
 *          explicit = Is this an explicit document end?
 */
Event documentEndEvent(const ParsePosition start, const ParsePosition end, const bool explicit) pure @safe nothrow
{
    Event result;
    result.startMark        = start;
    result.endMark          = end;
    result.id               = EventID.documentEnd;
    result.explicitDocument = explicit;
    return result;
}

/// Construct a scalar event.
///
/// Params:  start    = Start position of the event in the file/stream.
///          end      = End position of the event in the file/stream.
///          anchor   = Anchor of the scalar, if any.
///          tag      = Tag of the scalar, if specified.
///          implicit = Should the tag be implicitly resolved?
///          value    = String value of the scalar.
///          style    = Scalar style.
Event scalarEvent(const ParsePosition start, const ParsePosition end, const string anchor, const string tag,
                  const bool implicit, const string value,
                  const YamlScalarStyle style = YamlScalarStyle.invalid) @safe pure nothrow @nogc
{
    Event result;
    result.value       = value;
    result.startMark   = start;
    result.endMark     = end;

    result.anchor  = anchor;
    result.tag     = tag;

    result.id          = EventID.scalar;
    result.scalarStyle = style;
    result.implicit    = implicit;
    return result;
}
