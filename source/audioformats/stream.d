module audioformats.stream;

package: // not meant to be imported at all

// Internal object for audio-formats


nothrow @nogc
{
	alias ioSeekCallback          = void function(long offset, void* userData);
	alias ioTellCallback          = long function(void* userData);	
	alias ioGetFileLengthCallback = long function(void* userData);
	alias ioReadCallback          = int  function(void* outData, int bytes, void* userData); // returns number of read bytes
	alias ioWriteCallback         = int  function(void* inData, int bytes, void* userData); // returns number of written bytes
}


struct IOCallbacks
{
	ioSeekCallback seek;
	ioTellCallback tell;
	ioGetFileLengthCallback getFileLength;
	ioReadCallback read;
	ioWriteCallback write;
}

class AudioStream
{
nothrow:
@nogc:
	this()
	{
		
	}



}