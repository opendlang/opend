module app;

/*
 This is a test for the DerelictUtil library. When executing 'dub build', the
 library will be built and put in the 'util/lib'. To build this test app,
 type instead 'dub build --config=test' and an executable named 'DerelictUtil'
 will be created in the 'util/bin'.
 */

import derelict.util.exception;
import derelict.util.loader;

class TestLoader : SharedLibLoader {
    this() {
        super( "OpenGL32.dll" );
    }

    alias da_glClear = void function( float, float, float, float );
    da_glClear glClear;
    da_glClear glDummy;

    protected override void loadSymbols() {
        bindFunc( cast( void** )&glClear, "glClear" );
        bindFunc( cast( void** )&glDummy, "glDummy" );
        bindFunc( cast( void** )&glDummy, "glDummier" );
    }
}

// The expected output is a SymbolLoadException complaining about the missing
// symbol, "glDummier".
void main() {
    import std.stdio;

    ShouldThrow cb( string symname ) {
        if( symname == "glDummy" ) return ShouldThrow.No;
        else if( symname == "glDummier" ) writeln( "Gonna throw now!" );
        return ShouldThrow.Yes;
    }

    auto loader = new TestLoader();
    loader.missingSymbolCallback = &cb;
    scope( exit ) loader.unload();
    loader.load();

    writefln( "glClear address is %X", loader.glClear );
}