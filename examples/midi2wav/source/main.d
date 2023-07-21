import std.stdio;
import std.file;
import std.conv;

import audioformats;
import nukedopl3;

void usage()
{
    writeln("Usage:");
    writeln("        midi2wav input.mid output.wav [-sr 96000][-opl2|-opl3]");
    writeln();
    writeln("Description:");
    writeln("        This describes a WAV files and its content.");
    writeln;
    writeln("Flags:");
    writeln("        -h            Shows this help");
    writeln("        -sr <number>  Specify sampling rate of output (default = 48000)");
    writeln("        -opl2         OPL2 mode");
    writeln("        -opl3         OPL3 mode (default)");
    writeln("        -amp <number> Volume (defaut = 1.0)");
    writeln;
}


// Use arsd.nukedopl3 to transcode MIDI to wav.
int main(string[] args)
{
    bool help = false;
    int samplerate = 48000;
    float volume = 1.0f;
    bool opl3mode = true;
    string inputPath = null;
    string outputPath = null;
    for (int i = 1; i < args.length; ++ i)
    {
        string arg = args[i];

        if (arg == "-h")
            help = true;
        else if (arg == "-opl2")
            opl3mode = false;
        else if (arg == "-opl3")
            opl3mode = true;
        else if (arg == "-sr")
        {
            ++i;
            samplerate = to!int(args[i]);
        }
        else if (arg == "-amp")
        {
            ++i;
            volume = to!double(args[i]);
        }
        else if (inputPath is null)
        {
            inputPath = arg;
        }
        else if (outputPath is null)
        {
            outputPath = arg;
        }
        else
        {
            writeln("error: too many files given");
            usage;
            return 1;
        }
    }  

    if (help)
    {
        usage;
        return 0;
    }

    if (inputPath is null || outputPath is null)
    {
        usage;
        return 1;
    }

    try
    {
    
        bool stereo = true;
        OPLPlayer synth = new OPLPlayer(samplerate, opl3mode, stereo);

        ubyte[] songBytes = cast(ubyte[]) std.file.read(inputPath);
        if (!synth.load(songBytes))
            throw new Exception("Can't load song");

        if (!synth.play ())
            throw new Exception("Can't play song");

        short[2 * 1024] buf;
        float[2 * 1024] fbuf;

        AudioStream stream;

        AudioFileFormat outFormat = AudioFileFormat.wav;
        int channels = 2;
        stream.openToFile(outputPath, outFormat, samplerate, channels);

        ulong totalFrames = 0;
        while(true)
        {
            uint frames = synth.generate(buf[]);

            if (frames == 0)
              break;

            totalFrames += frames;
        
            for (uint n = 0; n < frames*2; ++n)
            {
                fbuf[n] = buf[n] / 32767.0f;
            }
            stream.writeSamplesFloat(fbuf[0..frames*channels]);
        }

        writefln("%s frames transcoded from %s to %s", totalFrames, inputPath, outputPath);
        return 0;
    }
    catch(AudioFormatsException e)
    {
        writeln(e.msg);
        destroyAudioFormatException(e);
        return 1;
    }
    catch(Exception e)
    {
        writeln(e.msg);
        return 1;
    }
}