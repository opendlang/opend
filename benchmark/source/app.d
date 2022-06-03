import mir.ion.benchmark;
import mir.ser.text;
import mir.stdio;
import std.file: readText;
import std.getopt;

void main(string[] args)
{
    version (assert)
    {
        dout << "please compile with --build=release" <<  endl;
    }
    else
    {
        string jsonFileName;
        uint count;

        auto helpInformation = getopt(
            args,
            std.getopt.config.required, "file|f", "JSON file name", &jsonFileName,
            std.getopt.config.required, "count|c", "Count of iterations", &count,
        );    // enum

        if (helpInformation.helpWanted)
        {
            defaultGetoptPrinter("Some information about the program.",
            helpInformation.options);
        }

        auto json = jsonFileName.readText;

        import std.system: os;
        auto report = json.benchmarkData(count);
        auto speedJson = report.json_input_size / report.json_to_ion.total!"usecs" / 1000.0;
        auto speedMsgpackVsJson = report.json_input_size / report.msgpack_to_ion.total!"usecs" / 1000.0;
        auto speedMsgpack = report.msgpack_size / report.msgpack_to_ion.total!"usecs" / 1000.0;
        auto speedIon = report.ion_size / report.ion_to_ion.total!"usecs" / 1000.0;
        auto speedIonVsJson = report.json_input_size / report.ion_to_ion.total!"usecs" / 1000.0;
        auto speedIonVsMsgpack = report.msgpack_size / report.ion_to_ion.total!"usecs" / 1000.0;

        auto speedParsing = report.ion_size / report.ion_parsgin.total!"usecs" / 1000.0;
        auto speedParsingVsJson = report.json_input_size / report.ion_parsgin.total!"usecs" / 1000.0;

        auto speedIonWriting = report.ion_size / report.ion_writing.total!"usecs" / 1000.0;
        auto speedIonWritingVsJson = report.json_input_size / report.ion_writing.total!"usecs" / 1000.0;

        auto compressionJson = (report.json_minimized_size * 100 / report.ion_size - 100) / 100.0;
        auto compressionMsgpack = (report.msgpack_size * 100 / report.ion_size - 100) / 100.0;

        auto speedMemcpy = report.json_input_size / report.memcpy.total!"usecs" / 1000.0;

        dout
            << "The benchmark for binary Ion format," << endl
            << "Mir Ion" << endl
            << "--------------------------------------------------" << endl
            << "Binary Ion parsing      " << speedParsing << " GB/s" << " (estimated)" << endl
            << "     is equivalent of   " << speedParsingVsJson << " GB/s for JSON" << endl
            << endl
            << "Binary Ion writing      " << speedIonWriting << " GB/s" << endl
            << "     is equivalent of   " << speedIonWritingVsJson << " GB/s for JSON" << endl
            << endl
            << "JSON    -> binary Ion   " << speedJson << " GB/s" << endl
            << endl
            << "MsgPack -> binary Ion   " << speedMsgpack << " GB/s" << endl
            << "     is equivalent of   " << speedMsgpackVsJson << " GB/s for JSON" << endl
            // << endl
            // << "memcpy of the JSON file " << speedMemcpy << " GB/s" << "         " << endl
            << endl
            << endl
            << "Ion is " << compressionJson << "% smaller then minimized JSON" << endl
            << "   and " << compressionMsgpack << "% smaller then MsgPack" << endl
            << "- - - - - - - - - - - - - - - - - - - - - - - - -" << endl
            << "processed file: " << jsonFileName << endl 
            << "number of iterations: " << count << endl 
            << "os: " << size_t.sizeof * 8 << "bit " << os << endl
            // << "details (in the text ion format): " << endl
            // // << "- - - - - - - - - - - - - - - - - - - - - - - - -" << endl
            // << report.serializeTextPretty << endl
            << "--------------------------------------------------"
            << endl;
    }
}
