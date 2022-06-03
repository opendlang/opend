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
        auto speedJson = report.json_input_size * 10 / report.json_to_ion.total!"usecs" / 10.0;
        auto speedMsgpackVsJson = report.json_input_size * 10 / report.msgpack_to_ion.total!"usecs" / 10.0;
        auto speedMsgpack = report.msgpack_size * 10 / report.msgpack_to_ion.total!"usecs" / 10.0;
        auto speedIon = report.ion_size * 10 / report.ion_to_ion.total!"usecs" / 10.0;
        auto speedIonVsJson = report.json_input_size * 10 / report.ion_to_ion.total!"usecs" / 10.0;
        auto speedIonVsMsgpack = report.msgpack_size * 10 / report.ion_to_ion.total!"usecs" / 10.0;
        auto compressionJson = (report.json_input_size * 1000 / report.ion_size - 1000) / 10;
        auto compressionMsgpack = (report.msgpack_size * 1000 / report.ion_size - 1000) / 10;
        dout
            << "-------------------------------------------------" << endl
            << "JSON     --> Ion  " << speedJson << " MB/s" << endl
            << "- - - - - - - - - - - - - - - - - - - - - - - - -" << endl
            << "MsgPack  --> Ion  " << speedMsgpack << " MB/s" << endl
            << "  is the same as  " << speedMsgpackVsJson << " MB/s of JSON" << endl
            << "- - - - - - - - - - - - - - - - - - - - - - - - -" << endl
            << "Ion      --> Ion  " << speedIon << " MB/s" << "         (full cycle)" << endl
            << "  is the same as  " << speedIonVsJson << " MB/s of JSON" << endl
            << "- - - - - - - - - - - - - - - - - - - - - - - - -" << endl
            << "JSON    vs Ion data size " << "+" << compressionJson << "%" << endl
            << "MsgPack vs Ion data size " << "+" << compressionMsgpack << "%" << endl
            << "- - - - - - - - - - - - - - - - - - - - - - - - -" << endl
            << "processed file: " << jsonFileName << endl 
            << "number of iterations: " << count << endl 
            << "os: " << size_t.sizeof * 8 << "bit " << os << endl
            // << "details (in the text ion format): " << endl
            // // << "- - - - - - - - - - - - - - - - - - - - - - - - -" << endl
            // << report.serializeTextPretty << endl
            << "-------------------------------------------------"
            << endl;
    }
}
