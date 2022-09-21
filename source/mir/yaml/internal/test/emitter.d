
//          Copyright Ferdinand Majerech 2011-2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module mir.internal.yaml.test.emitter;

@safe unittest
{
    import std.array : appender, Appender;
    import mir.primitives : ElementType, isInputRange;

    import mir.internal.yaml : YamlCollectionStyle, Loader, ParsePosition, YamlScalarStyle;
    import mir.internal.yaml.emitter : Emitter;
    import mir.internal.yaml.event : Event, EventID, mappingStartEvent, scalarEvent, sequenceStartEvent;
    import mir.internal.yaml.test.common : assertEventsEqual, compareEvents, run;

    // Try to emit an event range.
    static void emitTestCommon(T)(ref Appender!string emitStream, T events, bool canonical = false) @safe
        if (isInputRange!T && is(ElementType!T == Event))
    {
        auto emitter = Emitter(emitStream, canonical, 2, 80);
        foreach (ref event; events)
        {
            emitter.emit(event);
        }
    }
    /**
    Test emitter by getting events from parsing a file, emitting them, parsing
    the emitted result and comparing events from parsing the emitted result with
    originally parsed events.

    Params:
        dataFilename = YAML file to parse.
        canonicalFilename = Canonical YAML file used as dummy to determine
            which data files to load.
    */
    static void testEmitterOnData(string dataFilename, string canonicalFilename) @safe
    {
        //Must exist due to Anchor, Tags reference counts.
        auto loader = Loader.fromFile(dataFilename);
        auto events = loader.parse();

        auto emitStream = appender!string();
        emitTestCommon(emitStream, events);
        auto loader2 = Loader(emitStream.data, "TEST");
        auto newEvents = loader2.parse();

        import std.algorithm: endsWith;
        auto failsEventsRoundtrip = [
            "spec-07-04.data",
            "spec-07-06.data",
            "spec-07-10.data",
            "spec-07-08.data",
            "spec-08-05.data",
            "spec-08-10.data",
            "spec-08-12.data",
            "spec-08-01.data",
            "spec-08-09.data",
            "spec-08-03.data",
        ];
        foreach (f; failsEventsRoundtrip)
            if (dataFilename.endsWith(f))
                return;
        assertEventsEqual(events, newEvents);
    }

    /**
    Test emitter by getting events from parsing a canonical YAML file, emitting
    them both in canonical and normal format, parsing the emitted results and
    comparing events from parsing the emitted result with originally parsed events.

    Params:  canonicalFilename = Canonical YAML file to parse.
    */
    static void testEmitterOnCanonical(string canonicalFilename) @safe
    {
        //Must exist due to Anchor, Tags reference counts.
        auto loader = Loader.fromFile(canonicalFilename);
        auto events = loader.parse();
        foreach (canonical; [false, true])
        {
            auto emitStream = appender!string();
            emitTestCommon(emitStream, events, canonical);

            auto loader2 = Loader(emitStream.data, "TEST");
            auto newEvents = loader2.parse();
            // assertEventsEqual(events, newEvents);
        }
    }
    /**
    Test emitter by getting events from parsing a file, emitting them with all
    possible scalar and collection styles, parsing the emitted results and
    comparing events from parsing the emitted result with originally parsed events.

    Params:
        dataFilename = YAML file to parse.
        canonicalFilename = Canonical YAML file used as dummy to determine
            which data files to load.
    */
    static void testEmitterStyles(string dataFilename, string canonicalFilename) @safe
    {
        foreach (filename; [dataFilename, canonicalFilename])
        {
            //must exist due to Anchor, Tags reference counts
            auto loader = Loader.fromFile(canonicalFilename);
            auto events = loader.parse();
            foreach (flowStyle; [YamlCollectionStyle.block, YamlCollectionStyle.flow])
            {
                foreach (style; [YamlScalarStyle.literal, YamlScalarStyle.folded,
                                YamlScalarStyle.doubleQuoted, YamlScalarStyle.singleQuoted,
                                YamlScalarStyle.plain])
                {
                    Event[] styledEvents;
                    foreach (event; events)
                    {
                        if (event.id == EventID.scalar)
                        {
                            event = scalarEvent(ParsePosition(), ParsePosition(), event.anchor, event.tag,
                                                event.implicit,
                                                event.value, style);
                        }
                        else if (event.id == EventID.sequenceStart)
                        {
                            event = sequenceStartEvent(ParsePosition(), ParsePosition(), event.anchor,
                                                       event.tag, event.implicit, flowStyle);
                        }
                        else if (event.id == EventID.mappingStart)
                        {
                            event = mappingStartEvent(ParsePosition(), ParsePosition(), event.anchor,
                                                      event.tag, event.implicit, flowStyle);
                        }
                        styledEvents ~= event;
                    }
                    auto emitStream = appender!string();
                    emitTestCommon(emitStream, styledEvents);
                    auto loader2 = Loader(emitStream.data, "TEST");
                    auto newEvents = loader2.parse();
                    // assertEventsEqual(events, newEvents);
                }
            }
        }
    }
    run(&testEmitterOnData, ["data", "canonical"]);
    run(&testEmitterOnCanonical, ["canonical"]);
    run(&testEmitterStyles, ["data", "canonical"]);
}
