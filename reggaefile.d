import reggae;
import std.typecons;

enum debugFlags = "-w -g -debug";
static if (__VERSION__ >= 2077)
    enum allTogether = Yes.allTogether;
else
    enum allTogether = Yes.allTogether;

alias lib = dubDefaultTarget!(CompilerFlags(debugFlags));
alias ut = dubTestTarget!(CompilerFlags(debugFlags),
                          LinkerFlags(),
                          allTogether);
alias utl = dubConfigurationTarget!(Configuration("ut"),
                                    CompilerFlags("-unittest -version=unitThreadedLight " ~ debugFlags));
mixin build!(lib, ut, utl);
