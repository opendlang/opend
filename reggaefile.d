import reggae;
import std.typecons;

enum debugFlags = "-w -g -debug";
static if (__VERSION__ >= 2077)
    enum allTogether = No.allTogether;
else
    enum allTogether = Yes.allTogether;

alias lib = dubDefaultTarget!(CompilerFlags(debugFlags));
alias ut = dubTestTarget!(CompilerFlags(debugFlags),
                          LinkerFlags(),
                          allTogether);
alias utl = dubConfigurationTarget!(
    Configuration("ut"),
    CompilerFlags(debugFlags ~ " -unittest -version=unitThreadedLight -cov")
);

mixin build!(lib, ut, utl);
