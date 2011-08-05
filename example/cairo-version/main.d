import cairo.cairo;
import std.stdio;

void main()
{
    auto cairoVer = Version.cairoVersion;
    auto bindingVer = Version.bindingVersion;
    writefln("Cairo version: %s", cairoVer);
    writefln("Binding version: %s", bindingVer);
    if(cairoVer.major != 1 || cairoVer.minor <= 8) //we don't care about micro
    {
        writeln("Cairo version not supported!");
    }
}
