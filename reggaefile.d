import reggae;
import std.typecons;

alias lib = dubDefaultTarget!(CompilerFlags("-g -debug"));
alias ut = dubTestTarget!();
alias utl = dubConfigurationTarget!(Configuration("ut"),
                                    CompilerFlags("-unittest -version=unitThreadedLight"));
mixin build!(lib, ut, utl);
