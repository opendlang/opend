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
}

///
Report benchmarkData(string json, uint count)
{
    import mir.ion.conv;
    import mir.appender: scopedBuffer;
    import mir.ion.stream;

    auto jsonBuffer = scopedBuffer!char;
    auto ionBuffer = scopedBuffer!ubyte;
    auto binaryBuffer = scopedBuffer!ubyte;

    import std.datetime.stopwatch: benchmark;

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
    );

    Report report;

    report.json_to_ion = res[0] / count;
    report.ion_to_ion = res[1] / count;
    report.ion_to_json = res[2] / count;
    report.ion_to_msgpack = res[3] / count;
    report.msgpack_to_ion = res[4] / count;

    report.json_input_size = json.length;
    report.json_minimized_size = jsonBuffer.data.length;
    report.msgpack_size = binaryBuffer.data.length;
    report.ion_size = ionBuffer.data.length;

    return report;
}
