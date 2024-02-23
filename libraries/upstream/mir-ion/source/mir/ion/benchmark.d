/++
Compares formats for your data.
+/
module mir.ion.benchmark;

import mir.serde;

///
struct Report
{
    import core.time: Duration;

    ///
    size_t json_input_size;
    ///
    size_t json_minimized_size;
    ///
    size_t msgpack_size;
    ///
    size_t ion_size;

@serdeProxy!string:

    /// Avg duration per call
    Duration json_to_ion;
    /// Avg duration per call
    Duration ion_to_ion;
    /// Avg duration per call
    Duration ion_to_json;
    /// Avg duration per call
    Duration ion_to_msgpack;
    /// Avg duration per call
    Duration msgpack_to_ion;
    /// Avg duration per call
    Duration ion_parsgin;
    /// Avg duration per call
    Duration ion_writing;
    /// Avg duration per call for JSON
    Duration memcpy;
}

///
Report benchmarkData(string json, uint count)
{
    import mir.algebraic_alias.json;
    import mir.appender: scopedBuffer;
    import mir.ion.conv;
    import mir.ion.stream;
    import mir.deser.ion: deserializeIon;

    auto jsonBuffer = scopedBuffer!char;
    auto ionBuffer = scopedBuffer!ubyte;
    auto binaryBuffer = scopedBuffer!ubyte;

    import std.datetime.stopwatch: benchmark;
    json.json2ion(ionBuffer);
    auto data = ionBuffer.data.deserializeIon!JsonAlgebraic;
    auto memory = jsonBuffer.prepare(json.length);

    auto res = count.benchmark!(
        () { // JSON -> Ion
            ionBuffer.shrinkTo(0);
            json.json2ion(ionBuffer);
        },
        () { // Ion -> Ion
            import mir.ser.ion: serializeIon;
            binaryBuffer.shrinkTo(0);
            serializeIon(binaryBuffer, ionBuffer.data.IonValueStream);
        },
        () { // Ion -> JSON
            import mir.ser.json: serializeJson;
            jsonBuffer.shrinkTo(0);
            serializeJson(jsonBuffer, ionBuffer.data.IonValueStream);
        },
        () { // Ion -> Msgpack
            import mir.ser.msgpack: serializeMsgpack;
            binaryBuffer.shrinkTo(0);
            serializeMsgpack(binaryBuffer, ionBuffer.data.IonValueStream);
        },
        () { // Msgpack -> Ion
            ionBuffer.shrinkTo(0);
            binaryBuffer.data.msgpack2ion(ionBuffer);
        },
        () { // Data -> Ion
            import mir.ser.ion: serializeIon;
            ionBuffer.shrinkTo(0);
            serializeIon(ionBuffer, data);
        },
        () { // memcpy
            import core.stdc.string: memcpy;
            memcpy(memory.ptr, json.ptr, json.length);
        },
    );

    Report report;

    report.json_to_ion = res[0] / count;
    report.ion_to_ion = res[1] / count;
    report.ion_to_json = res[2] / count;
    report.ion_to_msgpack = res[3] / count;
    report.msgpack_to_ion = res[4] / count;
    report.ion_writing = res[5] / count;
    report.ion_parsgin = report.ion_to_ion - report.ion_writing;
    report.memcpy = res[6] / count;

    report.json_input_size = json.length;
    report.json_minimized_size = jsonBuffer.data.length;
    report.msgpack_size = binaryBuffer.data.length;
    report.ion_size = ionBuffer.data.length;

    return report;
}
