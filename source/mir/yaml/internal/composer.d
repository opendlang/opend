
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/**
 * Composes nodes from YAML events provided by parser.
 * Code based on PyYAML: http://www.pyyaml.org
 */
module mir.internal.yaml.composer;

import core.memory;

import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.range;
import std.typecons;

import mir.internal.yaml.constructor;
import mir.internal.yaml.event;
import mir.internal.yaml.exception;
import mir.algebraic_alias.yaml;
import mir.internal.yaml.parser;
import mir.internal.yaml.resolver;


package:
/**
 * Exception thrown at composer errors.
 *
 * See_Also: MarkedYamlException
 */
class ComposerException : MarkedYamlException
{
    mixin MarkedExceptionCtors;
}

///Composes YAML documents from events provided by a Parser.
struct Composer
{
    private:
        ///Parser providing YAML events.
        package Parser parser_;
        ///Resolver resolving tags (data types).
        Resolver resolver_;
        ///Nodes associated with anchors. Used by YAML aliases.
        YamlAlgebraic[string] anchors_;

        ///Used to reduce allocations when creating pair arrays.
        ///
        ///We need one appender for each nesting level that involves
        ///a pair array, as the inner levels are processed as a
        ///part of the outer levels. Used as a stack.
        Appender!(YamlPair[])[] pairAppenders_;
        ///Used to reduce allocations when creating node arrays.
        ///
        ///We need one appender for each nesting level that involves
        ///a node array, as the inner levels are processed as a
        ///part of the outer levels. Used as a stack.
        Appender!(YamlAlgebraic[])[] nodeAppenders_;

    public:
        /**
         * Construct a composer.
         *
         * Params:  parser      = Parser to provide YAML events.
         *          resolver    = Resolver to resolve tags (data types).
         */
        this(Parser parser, Resolver resolver) @safe
        {
            import core.lifetime;
            parser_ = move(parser);
            resolver_ = resolver;
        }

        /**
         * Determine if there are any nodes left.
         *
         * Must be called before loading as it handles the stream start event.
         */
        bool checkNode() @safe
        {
            // If next event is stream start, skip it
            parser_.skipOver!"a.id == b"(EventID.streamStart);

            //True if there are more documents available.
            return parser_.front.id != EventID.streamEnd;
        }

        ///Get a YAML document as a node (the root of the document).
        YamlAlgebraic getNode() @safe
        {
            //Get the root node of the next document.
            assert(parser_.front.id != EventID.streamEnd,
                   "Trying to get a node from Composer when there is no node to " ~
                   "get. use checkNode() to determine if there is a node.");

            return composeDocument();
        }

    private:

        void skipExpected(const EventID id) @safe
        {
            const foundExpected = parser_.skipOver!"a.id == b"(id);
            assert(foundExpected, text("Expected ", id, " not found."));
        }
        ///Ensure that appenders for specified nesting levels exist.
        ///
        ///Params:  pairAppenderLevel = Current level in the pair appender stack.
        ///         nodeAppenderLevel = Current level the node appender stack.
        void ensureAppendersExist(const uint pairAppenderLevel, const uint nodeAppenderLevel)
            @safe
        {
            while(pairAppenders_.length <= pairAppenderLevel)
            {
                pairAppenders_ ~= appender!(YamlPair[])();
            }
            while(nodeAppenders_.length <= nodeAppenderLevel)
            {
                nodeAppenders_ ~= appender!(YamlAlgebraic[])();
            }
        }

        ///Compose a YAML document and return its root node.
        YamlAlgebraic composeDocument() @safe
        {
            skipExpected(EventID.documentStart);

            //Compose the root node.
            YamlAlgebraic node = composeNode(0, 0);

            skipExpected(EventID.documentEnd);

            anchors_ = null;
            return node;
        }

        /// Compose a node.
        ///
        /// Params: pairAppenderLevel = Current level of the pair appender stack.
        ///         nodeAppenderLevel = Current level of the node appender stack.
        YamlAlgebraic composeNode(const uint pairAppenderLevel, const uint nodeAppenderLevel) @safe
        {
            if(parser_.front.id == EventID.alias_)
            {
                const event = parser_.front;
                parser_.popFront();
                const anchor = event.anchor;
                enforce((anchor in anchors_) !is null,
                        new ComposerException("Found undefined alias: " ~ anchor,
                                              event.startMark));

                //If the node referenced by the anchor is uninitialized,
                //it's not finished, i.e. we're currently composing it
                //and trying to use it recursively here.
                enforce(anchors_[anchor] != YamlAlgebraic(),
                        new ComposerException("Found recursive alias: " ~ anchor,
                                              event.startMark));

                return anchors_[anchor];
            }

            const event = parser_.front;
            const anchor = event.anchor;
            if((anchor !is null) && (anchor in anchors_) !is null)
            {
                throw new ComposerException("Found duplicate anchor: " ~ anchor,
                                            event.startMark);
            }

            YamlAlgebraic result;
            //Associate the anchor, if any, with an uninitialized node.
            //used to detect duplicate and recursive anchors.
            if(anchor !is null)
            {
                anchors_[anchor] = YamlAlgebraic();
            }

            switch (parser_.front.id)
            {
                case EventID.scalar:
                    result = composeScalarNode();
                    break;
                case EventID.sequenceStart:
                    result = composeSequenceNode(pairAppenderLevel, nodeAppenderLevel);
                    break;
                case EventID.mappingStart:
                    result = composeMappingNode(pairAppenderLevel, nodeAppenderLevel);
                    break;
                default: assert(false, "This code should never be reached");
            }

            if(anchor !is null)
            {
                anchors_[anchor] = result;
            }
            return result;
        }

        ///Compose a scalar node.
        YamlAlgebraic composeScalarNode() @safe
        {
            const event = parser_.front;
            parser_.popFront();
            const tag = resolver_.resolve(YamlAlgebraic.Kind.string, event.tag, event.value,
                                          event.implicit);

            YamlAlgebraic node = constructNode(event.startMark, event.endMark, tag,
                                          event.value);
            node.scalarStyle = event.scalarStyle;

            return node;
        }

        /// Compose a sequence node.
        ///
        /// Params: pairAppenderLevel = Current level of the pair appender stack.
        ///         nodeAppenderLevel = Current level of the node appender stack.
        YamlAlgebraic composeSequenceNode(const uint pairAppenderLevel, const uint nodeAppenderLevel)
            @safe
        {
            ensureAppendersExist(pairAppenderLevel, nodeAppenderLevel);
            auto nodeAppender = &(nodeAppenders_[nodeAppenderLevel]);

            const startEvent = parser_.front;
            parser_.popFront();
            const tag = resolver_.resolve(YamlAlgebraic.Kind.array, startEvent.tag, null,
                                          startEvent.implicit);

            while(parser_.front.id != EventID.sequenceEnd)
            {
                nodeAppender.put(composeNode(pairAppenderLevel, nodeAppenderLevel + 1));
            }

            YamlAlgebraic node = constructNode(startEvent.startMark, parser_.front.endMark,
                                          tag, nodeAppender.data.dup);
            node.collectionStyle = startEvent.collectionStyle;
            parser_.popFront();
            nodeAppender.clear();

            return node;
        }

        /**
         * Flatten a node, merging it with nodes referenced through YAMLMerge data type.
         *
         * YamlAlgebraic must be a mapping or a sequence of mappings.
         *
         * Params:  root              = YamlAlgebraic to flatten.
         *          startMark         = Start position of the node.
         *          endMark           = End position of the node.
         *          pairAppenderLevel = Current level of the pair appender stack.
         *          nodeAppenderLevel = Current level of the node appender stack.
         *
         * Returns: Flattened mapping as pairs.
         */
        YamlPair[] flatten(ref YamlAlgebraic root, const ParsePosition startMark, const ParsePosition endMark,
                            const uint pairAppenderLevel, const uint nodeAppenderLevel) @safe
        {
            void error(YamlAlgebraic node)
            {
                //this is Composer, but the code is related to Constructor.
                throw new ConstructorException("While constructing a mapping, " ~
                                               "expected a mapping or a list of " ~
                                               "mappings for merging, but found: " ~
                                               text(node.kind) ~
                                               " NOTE: line/column shows topmost parent " ~
                                               "to which the content is being merged",
                                               startMark, endMark);
            }

            ensureAppendersExist(pairAppenderLevel, nodeAppenderLevel);
            auto pairAppender = &(pairAppenders_[pairAppenderLevel]);

            switch (root.kind)
            {
                case YamlAlgebraic.Kind.object:
                    YamlAlgebraic[] toMerge;
                    toMerge.reserve(root.get!"object".length);
                    foreach (ref pair; root.get!"object".pairs) with(pair)
                    {
                        if(key == "<<")
                        {
                            toMerge ~= value;
                        }
                        else
                        {
                            auto temp = YamlPair(key, value);
                            pairAppender.put(temp);
                        }
                    }
                    foreach (node; toMerge)
                    {
                        pairAppender.put(flatten(node, startMark, endMark,
                                                     pairAppenderLevel + 1, nodeAppenderLevel));
                    }
                    break;
                case YamlAlgebraic.Kind.array:
                    foreach (ref YamlAlgebraic node; root.get!"array")
                    {
                        if (node.kind != YamlAlgebraic.Kind.object)
                        {
                            error(node);
                        }
                        pairAppender.put(flatten(node, startMark, endMark,
                                                     pairAppenderLevel + 1, nodeAppenderLevel));
                    }
                    break;
                default:
                    error(root);
                    break;
            }

            auto flattened = pairAppender.data.dup;
            pairAppender.clear();

            return flattened;
        }

        /// Compose a mapping node.
        ///
        /// Params: pairAppenderLevel = Current level of the pair appender stack.
        ///         nodeAppenderLevel = Current level of the node appender stack.
        YamlAlgebraic composeMappingNode(const uint pairAppenderLevel, const uint nodeAppenderLevel)
            @safe
        {
            ensureAppendersExist(pairAppenderLevel, nodeAppenderLevel);
            const startEvent = parser_.front;
            parser_.popFront();
            const tag = resolver_.resolve(YamlAlgebraic.Kind.object, startEvent.tag, null,
                                          startEvent.implicit);
            auto pairAppender = &(pairAppenders_[pairAppenderLevel]);

            Tuple!(YamlAlgebraic, ParsePosition)[] toMerge;
            while(parser_.front.id != EventID.mappingEnd)
            {
                auto pair = YamlPair(composeNode(pairAppenderLevel + 1, nodeAppenderLevel),
                                      composeNode(pairAppenderLevel + 1, nodeAppenderLevel));

                // Need to flatten and merge the node referred by YAMLMerge.
                if(pair.key == "<<")
                {
                    toMerge ~= tuple(pair.value, cast(ParsePosition)parser_.front.endMark);
                }
                //Not YAMLMerge, just add the pair.
                else
                {
                    pairAppender.put(pair);
                }
            }
            foreach(node; toMerge)
            {
                merge(*pairAppender, flatten(node[0], startEvent.startMark, node[1],
                                             pairAppenderLevel + 1, nodeAppenderLevel));
            }

            auto sorted = pairAppender.data.dup.sort!((x,y) => x.key > y.key);
            if (sorted.length) {
                foreach (index, const ref value; sorted[0 .. $ - 1].enumerate)
                    if (value.key == sorted[index + 1].key) {
                        const message = () @trusted {
                            import mir.format: text;
                            import mir.algebraic: visit;
                            return text("Key '", value.key.visit!text, "' appears multiple times in mapping (first: ", value.key.startMark, ")");
                        }();
                        throw new ComposerException(message, sorted[index + 1].key.startMark);
                    }
            }

            YamlAlgebraic node = constructNode(startEvent.startMark, parser_.front.endMark,
                                          tag, pairAppender.data.dup);
            node.collectionStyle = startEvent.collectionStyle;
            parser_.popFront();

            pairAppender.clear();
            return node;
        }
}

// Provide good error message on multiple keys (which JSON supports)
@safe unittest
{
    import mir.internal.yaml.loader : Loader;

    const str = `{
    "comment": "This is a common technique",
    "name": "foobar",
    "comment": "To write down comments pre-JSON5"
}`;

    import mir.test: should;

    try
        auto node = Loader.fromString(str).load();
    catch (ComposerException exc)
        (()@trusted => exc.message())().should ==
               "Key 'comment' appears multiple times in mapping " ~
               "(first: <unknown>(2,5))\n<unknown>(4,5)";
}
package:
// Merge pairs into an array of pairs based on merge rules in the YAML spec.
//
// Any new pair will only be added if there is not already a pair
// with the same key.
//
// Params:  pairs   = Appender managing the array of pairs to merge into.
//          toMerge = Pairs to merge.
void merge(ref Appender!(YamlPair[]) pairs, YamlPair[] toMerge) @safe
{
    foreach(ref pair; toMerge) if(!canFind!"a.key == b.key"(pairs.data, pair))
    {
        pairs.put(pair);
    }
}