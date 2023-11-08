import reggae;
import std.typecons;

alias lib = dubTarget!();
alias ut = dubTestTarget!(CompilationMode.options, Yes.coverage);
alias asan = dubConfigurationTarget!(
    Configuration("asan"),
    CompilerFlags("-unittest -cov -fsanitize=address"),
    LinkerFlags("-fsanitize=address"),
);


mixin build!(lib, optional!ut, optional!asan);
