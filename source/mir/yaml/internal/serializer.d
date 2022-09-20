
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/**
 * YAML serializer.
 * Code based on PyYAML: http://www.pyyaml.org
 */
module mir.internal.yaml.serializer;


import std.array;
import std.format;
import std.typecons;

import mir.internal.yaml.emitter;
import mir.internal.yaml.event;
import mir.internal.yaml.exception;
import mir.algebraic_alias.yaml;
import mir.internal.yaml.resolver;
import mir.internal.yaml.tagdirective;
import mir.internal.yaml.token;


package:

///Serializes represented YAML nodes, generating events which are then emitted by Emitter.
struct Serializer
{
    private:
        ///Resolver used to determine which tags are automaticaly resolvable.
        Resolver resolver_;

        ///Do all document starts have to be specified explicitly?
        Flag!"explicitStart" explicitStart_;
        ///Do all document ends have to be specified explicitly?
        Flag!"explicitEnd" explicitEnd_;
        ///YAML version string.
        string YAMLVersion_;

        ///Tag directives to emit.
        TagDirective[] tagDirectives_;

        //TODO Use something with more deterministic memory usage.
        ///Nodes with assigned anchors.
        string[YamlAlgebraic] anchors_;
        ///Nodes with assigned anchors that are already serialized.
        bool[YamlAlgebraic] serializedNodes_;
        ///ID of the last anchor generated.
        uint lastAnchorID_ = 0;

    public:
        /**
         * Construct a Serializer.
         *
         * Params:
         *          resolver      = Resolver used to determine which tags are automaticaly resolvable.
         *          explicitStart = Do all document starts have to be specified explicitly?
         *          explicitEnd   = Do all document ends have to be specified explicitly?
         *          YAMLVersion   = YAML version string.
         *          tagDirectives = Tag directives to emit.
         */
        this(Resolver resolver,
             const Flag!"explicitStart" explicitStart,
             const Flag!"explicitEnd" explicitEnd, string YAMLVersion,
             TagDirective[] tagDirectives) @safe
        {
            resolver_      = resolver;
            explicitStart_ = explicitStart;
            explicitEnd_   = explicitEnd;
            YAMLVersion_   = YAMLVersion;
            tagDirectives_ = tagDirectives;
        }

        ///Begin the stream.
        void startStream(EmitterT)(ref EmitterT emitter) @safe
        {
            emitter.emit(streamStartEvent(ParsePosition(), ParsePosition()));
        }

        ///End the stream.
        void endStream(EmitterT)(ref EmitterT emitter) @safe
        {
            emitter.emit(streamEndEvent(ParsePosition(), ParsePosition()));
        }

        ///Serialize a node, emitting it in the process.
        void serialize(EmitterT)(ref EmitterT emitter, ref YamlAlgebraic node) @safe
        {
            emitter.emit(documentStartEvent(ParsePosition(), ParsePosition(), explicitStart_,
                                             YAMLVersion_, tagDirectives_));
            anchorNode(node);
            serializeNode(emitter, node);
            emitter.emit(documentEndEvent(ParsePosition(), ParsePosition(), explicitEnd_));
            serializedNodes_ = null;
            anchors_ = null;
            string[YamlAlgebraic] emptyAnchors;
            anchors_ = emptyAnchors;
            lastAnchorID_ = 0;
        }

    private:
        /**
         * Determine if it's a good idea to add an anchor to a node.
         *
         * Used to prevent associating every single repeating scalar with an
         * anchor/alias - only nodes long enough can use anchors.
         *
         * Params:  node = YamlAlgebraic to check for anchorability.
         *
         * Returns: True if the node is anchorable, false otherwise.
         */
        static bool anchorable(ref YamlAlgebraic node) @safe
        {
            import mir.algebraic: visit;
            return node.visit!
                (
                    (string s) => s.length > 64,
                    (Blob s) => s.data.length > 64,
                    (YamlAlgebraic[] s) => s.length > 2,
                    (YamlMap s) => s.length > 2,
                    (s) => false,
                    (typeof(null)) => false,
                );
        }

        @safe unittest
        {
            import std.string : representation;
            auto shortString = "not much";
            auto longString = "A fairly long string that would be a good idea to add an anchor to";
            auto node1 = YamlAlgebraic(shortString);
            auto node2 = YamlAlgebraic(shortString.representation.dup);
            auto node3 = YamlAlgebraic(longString);
            auto node4 = YamlAlgebraic(longString.representation.dup);
            auto node5 = YamlAlgebraic([node1]);
            auto node6 = YamlAlgebraic([node1, node2, node3, node4]);
            assert(!anchorable(node1));
            assert(!anchorable(node2));
            assert(anchorable(node3));
            assert(anchorable(node4));
            assert(!anchorable(node5));
            assert(anchorable(node6));
        }

        ///Add an anchor to the node if it's anchorable and not anchored yet.
        void anchorNode(ref YamlAlgebraic node) @safe
        {
            if(!anchorable(node)){return;}

            if((node in anchors_) !is null)
            {
                if(anchors_[node] is null)
                {
                    anchors_[node] = generateAnchor();
                }
                return;
            }

            anchors_.remove(node);
            switch (node.kind)
            {
                case YamlAlgebraic.Kind.object:
                    foreach(ref pair; node.get!"object".pairs) with(pair)
                    {
                        anchorNode(key);
                        anchorNode(value);
                    }
                    break;
                case YamlAlgebraic.Kind.array:
                    foreach(ref YamlAlgebraic item; node.get!"array")
                    {
                        anchorNode(item);
                    }
                    break;
                default:
                    break;
            }
        }

        ///Generate and return a new anchor.
        string generateAnchor() @safe
        {
            ++lastAnchorID_;
            auto appender = appender!string();
            formattedWrite(appender, "id%03d", lastAnchorID_);
            return appender.data;
        }

        ///Serialize a node and all its subnodes.
        void serializeNode(EmitterT)(ref EmitterT emitter, ref YamlAlgebraic node) @safe
        {
            //If the node has an anchor, emit an anchor (as aliasEvent) on the
            //first occurrence, save it in serializedNodes_, and emit an alias
            //if it reappears.
            string aliased;
            if(anchorable(node) && (node in anchors_) !is null)
            {
                aliased = anchors_[node];
                if((node in serializedNodes_) !is null)
                {
                    emitter.emit(aliasEvent(ParsePosition(), ParsePosition(), aliased));
                    return;
                }
                serializedNodes_[node] = true;
            }
            switch (node.kind)
            {
                case YamlAlgebraic.Kind.object:
                    const defaultTag = resolver_.defaultMappingTag;
                    const implicit = node.tag == defaultTag;
                    emitter.emit(mappingStartEvent(ParsePosition(), ParsePosition(), aliased, node.tag,
                                                    implicit, node.collectionStyle));
                    foreach(ref pair; node.get!"object".pairs) with(pair)
                    {
                        serializeNode(emitter, key);
                        serializeNode(emitter, value);
                    }
                    emitter.emit(mappingEndEvent(ParsePosition(), ParsePosition()));
                    return;
                case YamlAlgebraic.Kind.array:
                    const defaultTag = resolver_.defaultSequenceTag;
                    const implicit = node.tag == defaultTag;
                    emitter.emit(sequenceStartEvent(ParsePosition(), ParsePosition(), aliased, node.tag,
                                                     implicit, node.collectionStyle));
                    foreach(ref YamlAlgebraic item; node.get!"array")
                    {
                        serializeNode(emitter, item);
                    }
                    emitter.emit(sequenceEndEvent(ParsePosition(), ParsePosition()));
                    return;
                default:
                    assert(node.kind == YamlAlgebraic.Kind.string, "Scalar node type must be string before serialized");
                    auto value = node.get!string;
                    const detectedTag = resolver_.resolve(node.kind, null, value, true);
                    const bool isDetected = node.tag == detectedTag;

                    emitter.emit(scalarEvent(ParsePosition(), ParsePosition(), aliased, node.tag,
                                  isDetected, value, node.scalarStyle));
                    return;
            }
        }
}

// Issue #244
@safe unittest
{
    import mir.internal.yaml.dumper : dumper;
    auto node = YamlAlgebraic([
        YamlPair(
            YamlAlgebraic(""),
            YamlAlgebraic([
                YamlAlgebraic([
                    YamlPair(
                        ("d"),
                        YamlAlgebraic([
                            YamlAlgebraic([
                                YamlPair(
                                    ("c"),
                                    ("")
                                ),
                                YamlPair(
                                    ("b"),
                                    ("")
                                ),
                                YamlPair(
                                    (""),
                                    ("")
                                )
                            ])
                        ])
                    ),
                ]),
                YamlAlgebraic([
                    YamlPair(
                        ("d"),
                        YamlAlgebraic([
                            YamlAlgebraic(""),
                            YamlAlgebraic(""),
                            YamlAlgebraic([
                                YamlPair(
                                    ("c"),
                                    ("")
                                ),
                                YamlPair(
                                    ("b"),
                                    ("")
                                ),
                                YamlPair(
                                    (""),
                                    ("")
                                )
                            ])
                        ])
                    ),
                    YamlPair(
                        ("z"),
                        ("")
                    ),
                    YamlPair(
                        (""),
                        ("")
                    )
                ]),
                YamlAlgebraic("")
            ])
        ),
        YamlPair(
            ("g"),
            ("")
        ),
        YamlPair(
            ("h"),
            ("")
        ),
    ]);

    auto stream = appender!string();
    dumper().dump(stream, node);
}
