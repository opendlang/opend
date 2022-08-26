/**
Library for sound file decoding and encoding. See README.md for licence explanations.

Copyright: Guillaume Piolats 2020.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module audioformats;


// Public API

public import audioformats.stream;


public import audioformats.internals: AudioFormatsException;

/// Frees an exception thrown by audio-formats.
void destroyAudioFormatException(AudioFormatsException e)
{
    import audioformats.internals;
    destroyFree!AudioFormatsException(e);
}