import reggae;
import std.typecons;

alias lib = dubBuild!();
alias ut = dubTest!(CompilationMode.options, Yes.coverage);
alias asan = dubBuild!(
    Configuration("asan"),
    CompilerFlags("-unittest -cov -fsanitize=address"),
    LinkerFlags("-fsanitize=address"),
);


mixin build!(lib, optional!ut, optional!asan);
