/**
General functions.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/

module gamut.general;

import gamut.types;
import gamut.plugin;
import gamut.internals.mutex;

nothrow @nogc @safe:

/// Initialises the library. 
/// When the `load_local_plugins_only` parameter is TRUE, FreeImage won’t make use of external plugins.
/// You must call this function exactly once at the start of your program.
void FreeImage_Initialise(bool load_local_plugins_only) @trusted
{
    g_libraryMutex.lockLazy();
    scope(exit) g_libraryMutex.unlock();

    if (!g_libraryInitialized)
    {
        g_libraryInitialized = true;
        FreeImage_registerInternalPlugins();
    }
}

/// Deinitialises the library.
/// You must call this function exactly once at the end of your program to clean up allocated resources 
/// in the FreeImage library.
void FreeImage_DeInitialise() pure
{
    // should clean remaining resources here.
}

/// Returns a string containing the current version of the library.
const(char)* FreeImage_GetVersion() pure
{
    return "1.0.0";
}

const(char)* FreeImage_GetCopyrightMessage() pure
{
    return ""; // No BSD clause in the library for now.
}


extern(C)
{
    alias FreeImage_OutputMessageFunction = void function(FREE_IMAGE_FORMAT fif, const(char)* message);
}

/// When a certain bitmap cannot be loaded or saved there is usually an explanation for it. For 
/// example a certain bitmap format might not be supported due to patent restrictions, or there 
/// might be a known issue with a certain bitmap subtype. Whenever something fails in 
/// FreeImage internally a log-string is generated, which can be captured by an application 
/// driving FreeImage. You use the function FreeImage_SetOutputMessage to capture the log 
/// string so that you can show it to the user of the program.
void FreeImage_SetOutputMessage(FreeImage_OutputMessageFunction omf)
{
    g_omf = omf;
}

shared FreeImage_OutputMessageFunction g_omf = null;


private:

__gshared Mutex g_libraryMutex; // protects g_libraryInitialized
__gshared g_libraryInitialized = false;