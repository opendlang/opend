import reggae;
import std.typecons;

enum debugFlags = "-w -g -debug";

alias lib = dubDefaultTarget!(CompilerFlags(debugFlags));
alias ut = dubTestTarget!(CompilerFlags(debugFlags ~ " -cov"));
alias utl = dubConfigurationTarget!(
    Configuration("utl"),
    CompilerFlags(debugFlags ~ " -unittest -version=unitThreadedLight -cov")
);

mixin build!(lib, optional!ut, optional!utl);
