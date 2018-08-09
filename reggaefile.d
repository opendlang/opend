import reggae;
import std.typecons;

enum debugFlags = "-w -g -debug";

alias lib = dubDefaultTarget!(CompilerFlags(debugFlags));
alias ut = dubTestTarget!(CompilerFlags(debugFlags ~ " -cov"));
alias utl = dubConfigurationTarget!(
    Configuration("utl"),
    CompilerFlags(debugFlags ~ " -unittest -version=unitThreadedLight -cov")
);
alias asan = dubConfigurationTarget!(
    Configuration("asan"),
    CompilerFlags(debugFlags ~ " -unittest -cov -fsanitize=address"),
    LinkerFlags("-fsanitize=address"),
);


mixin build!(lib, optional!ut, optional!utl, optional!asan);
