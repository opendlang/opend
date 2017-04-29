import reggae;
import std.typecons;

alias lib = dubDefaultTarget!(Flags("-g -debug"));
alias ut = dubTestTarget!();
alias utl = dubConfigurationTarget!(ExeName("utl"),
                                    Configuration("ut"),
                                    Flags("-unittest -version=unitThreadedLight"));
mixin build!(lib, ut, utl);
