// FLAC audio decoder. Public domain. See "unlicense" statement at the end of this file.
// dr_flac - v0.3d - 11/06/2016
// commit eebbf6ed17e9200a48c8f83a350a82722295558f
//
// David Reid - mackron@gmail.com
//
// some fixes from v0.4f - 2017-03-10
//   - Fix a couple of bugs with the bitstreaming code.
//
// fix from 767c3fbda48f54ce1050afa75110ae69cccdf0dd
//
// some fixes from v0.8d - 2017-09-22 (actually, one)
//   k8 SKIPPED: Add support for decoding streams with ID3 tags. ID3 tags are just skipped.
//   k8: i am absolutely not interested in such fucked flac files, and won't support that idiocy.
//
// D translation by Ketmar // Invisible Vector
module audioformats.drflac;

nothrow @nogc:
version(decodeFLAC):


// USAGE
//
// dr_flac is a single-file library.
//
// To decode audio data, do something like the following:
//
//     drflac* pFlac = drflac_open_file("MySong.flac");
//     if (pFlac is null) {
//         // Failed to open FLAC file
//     }
//
//     int* pSamples = malloc(pFlac.totalSampleCount * (int)).sizeof;
//     ulong numberOfInterleavedSamplesActuallyRead = drflac_read_s32(pFlac, pFlac.totalSampleCount, pSamples);
//
// The drflac object represents the decoder. It is a transparent type so all the information you need, such as the number of
// channels and the bits per sample, should be directly accessible - just make sure you don't change their values. Samples are
// always output as interleaved signed 32-bit PCM. In the example above a native FLAC stream was opened, however dr_flac has
// seamless support for Ogg encapsulated FLAC streams as well.
//
// You do not need to decode the entire stream in one go - you just specify how many samples you'd like at any given time and
// the decoder will give you as many samples as it can, up to the amount requested. Later on when you need the next batch of
// samples, just call it again. Example:
//
//     while (drflac_read_s32(pFlac, chunkSize, pChunkSamples) > 0) {
//         do_something();
//     }
//
// You can seek to a specific sample with drflac_seek_to_sample(). The given sample is based on interleaving. So for example,
// if you were to seek to the sample at index 0 in a stereo stream, you'll be seeking to the first sample of the left channel.
// The sample at index 1 will be the first sample of the right channel. The sample at index 2 will be the second sample of the
// left channel, etc.
//
//
// If you just want to quickly decode an entire FLAC file in one go you can do something like this:
//
//     uint sampleRate;
//     uint channels;
//     ulong totalSampleCount;
//     int* pSampleData = drflac_open_and_decode_file("MySong.flac", &sampleRate, &channels, &totalSampleCount);
//     if (pSampleData is null) {
//         // Failed to open and decode FLAC file.
//     }
//
//     ...
//
//     drflac_free(pSampleData);
//
//
// If you need access to metadata (album art, etc.), use drflac_open_with_metadata(), drflac_open_file_with_metdata() or
// drflac_open_memory_with_metadata(). The rationale for keeping these APIs separate is that they're slightly slower than the
// normal versions and also just a little bit harder to use.
//
// dr_flac reports metadata to the application through the use of a callback, and every metadata block is reported before
// drflac_open_with_metdata() returns. See https://github.com/mackron/dr_libs_tests/blob/master/dr_flac/dr_flac_test_2.c for
// an example on how to read metadata.
//
//
//
// OPTIONS
// #define these options before including this file.
//
// #define DR_FLAC_NO_STDIO
//   Disable drflac_open_file().
//
// #define DR_FLAC_NO_OGG
//   Disables support for Ogg/FLAC streams.
//
// #define DR_FLAC_NO_WIN32_IO
//   In the Win32 build, dr_flac uses the Win32 IO APIs for drflac_open_file() by default. This setting will make it use the
//   standard FILE APIs instead. Ignored when DR_FLAC_NO_STDIO is #defined. (The rationale for this configuration is that
//   there's a bug in one compiler's Win32 implementation of the FILE APIs which is not present in the Win32 IO APIs.)
//
// #define DR_FLAC_BUFFER_SIZE <number>
//   Defines the size of the internal buffer to store data from onRead(). This buffer is used to reduce the number of calls
//   back to the client for more data. Larger values means more memory, but better performance. My tests show diminishing
//   returns after about 4KB (which is the default). Consider reducing this if you have a very efficient implementation of
//   onRead(), or increase it if it's very inefficient. Must be a multiple of 8.
//
//
//
// QUICK NOTES
// - Based on my tests, the performance of the 32-bit build is at about parity with the reference implementation. The 64-bit build
//   is slightly faster.
// - dr_flac does not currently do any CRC checks.
// - dr_flac should work fine with valid native FLAC files, but for broadcast streams it won't work if the header and STREAMINFO
//   block is unavailable.
// - Audio data is output as signed 32-bit PCM, regardless of the bits per sample the FLAC stream is encoded as.
// - This has not been tested on big-endian architectures.
// - Rice codes in unencoded binary form (see https://xiph.org/flac/format.html#rice_partition) has not been tested. If anybody
//   knows where I can find some test files for this, let me know.
// - Perverse and erroneous files have not been tested. Again, if you know where I can get some test files let me know.
// - dr_flac is not thread-safe, but it's APIs can be called from any thread so long as you do your own synchronization.

enum DrFlacHasVFS = false;


// As data is read from the client it is placed into an internal buffer for fast access. This controls the
// size of that buffer. Larger values means more speed, but also more memory. In my testing there is diminishing
// returns after about 4KB, but you can fiddle with this to suit your own needs. Must be a multiple of 8.
enum DR_FLAC_BUFFER_SIZE = 4096;

// Check if we can enable 64-bit optimizations.
//version = DRFLAC_64BIT;

version(DRFLAC_64BIT) alias drflac_cache_t = ulong; else alias drflac_cache_t = uint;

// The various metadata block types.
enum DRFLAC_METADATA_BLOCK_TYPE_STREAMINFO = 0;
enum DRFLAC_METADATA_BLOCK_TYPE_PADDING = 1;
enum DRFLAC_METADATA_BLOCK_TYPE_APPLICATION = 2;
enum DRFLAC_METADATA_BLOCK_TYPE_SEEKTABLE = 3;
enum DRFLAC_METADATA_BLOCK_TYPE_VORBIS_COMMENT = 4;
enum DRFLAC_METADATA_BLOCK_TYPE_CUESHEET = 5;
enum DRFLAC_METADATA_BLOCK_TYPE_PICTURE = 6;
enum DRFLAC_METADATA_BLOCK_TYPE_INVALID = 127;

// The various picture types specified in the PICTURE block.
enum DRFLAC_PICTURE_TYPE_OTHER = 0;
enum DRFLAC_PICTURE_TYPE_FILE_ICON = 1;
enum DRFLAC_PICTURE_TYPE_OTHER_FILE_ICON = 2;
enum DRFLAC_PICTURE_TYPE_COVER_FRONT = 3;
enum DRFLAC_PICTURE_TYPE_COVER_BACK = 4;
enum DRFLAC_PICTURE_TYPE_LEAFLET_PAGE = 5;
enum DRFLAC_PICTURE_TYPE_MEDIA = 6;
enum DRFLAC_PICTURE_TYPE_LEAD_ARTIST = 7;
enum DRFLAC_PICTURE_TYPE_ARTIST = 8;
enum DRFLAC_PICTURE_TYPE_CONDUCTOR = 9;
enum DRFLAC_PICTURE_TYPE_BAND = 10;
enum DRFLAC_PICTURE_TYPE_COMPOSER = 11;
enum DRFLAC_PICTURE_TYPE_LYRICIST = 12;
enum DRFLAC_PICTURE_TYPE_RECORDING_LOCATION = 13;
enum DRFLAC_PICTURE_TYPE_DURING_RECORDING = 14;
enum DRFLAC_PICTURE_TYPE_DURING_PERFORMANCE = 15;
enum DRFLAC_PICTURE_TYPE_SCREEN_CAPTURE = 16;
enum DRFLAC_PICTURE_TYPE_BRIGHT_COLORED_FISH = 17;
enum DRFLAC_PICTURE_TYPE_ILLUSTRATION = 18;
enum DRFLAC_PICTURE_TYPE_BAND_LOGOTYPE = 19;
enum DRFLAC_PICTURE_TYPE_PUBLISHER_LOGOTYPE = 20;

alias drflac_container = int;
enum {
  drflac_container_native,
  drflac_container_ogg,
}

alias drflac_seek_origin = int;
enum {
  drflac_seek_origin_start,
  drflac_seek_origin_current,
}

// Packing is important on this structure because we map this directly to the raw data within the SEEKTABLE metadata block.
//#pragma pack(2)
align(2) struct drflac_seekpoint {
align(2):
  ulong firstSample;
  ulong frameOffset;   // The offset from the first byte of the header of the first frame.
  ushort sampleCount;
}
//#pragma pack()

struct drflac_streaminfo {
  ushort minBlockSize;
  ushort maxBlockSize;
  uint minFrameSize;
  uint maxFrameSize;
  uint sampleRate;
  ubyte channels;
  ubyte bitsPerSample;
  ulong totalSampleCount;
  ubyte[16] md5;
}

struct drflac_metadata {
  // The metadata type. Use this to know how to interpret the data below.
  uint type;

  // A pointer to the raw data. This points to a temporary buffer so don't hold on to it. It's best to
  // not modify the contents of this buffer. Use the structures below for more meaningful and structured
  // information about the metadata. It's possible for this to be null.
  const(void)* pRawData;

  // The size in bytes of the block and the buffer pointed to by pRawData if it's non-null.
  uint rawDataSize;

  static struct Padding {
    int unused;
  }

  static struct Application {
    uint id;
    const(void)* pData;
    uint dataSize;
  }

  static struct SeekTable {
    uint seekpointCount;
    const(drflac_seekpoint)* pSeekpoints;
  }

  static struct VorbisComment {
    uint vendorLength;
    const(char)* vendor;
    uint commentCount;
    const(char)* comments;
  }

  static struct CueSheet {
    char[128] catalog;
    ulong leadInSampleCount;
    bool isCD;
    ubyte trackCount;
    const(ubyte)* pTrackData;
  }

  static struct Picture {
    uint type;
    uint mimeLength;
    const(char)* mime;
    uint descriptionLength;
    const(char)* description;
    uint width;
    uint height;
    uint colorDepth;
    uint indexColorCount;
    uint pictureDataSize;
    const(ubyte)* pPictureData;
  }

  static union Data {
    drflac_streaminfo streaminfo;
    Padding padding;
    Application application;
    SeekTable seektable;
    VorbisComment vorbis_comment;
    CueSheet cuesheet;
    Picture picture;
  }

  Data data;
}


// Callback for when data needs to be read from the client.
//
// pUserData   [in]  The user data that was passed to drflac_open() and family.
// pBufferOut  [out] The output buffer.
// bytesToRead [in]  The number of bytes to read.
//
// Returns the number of bytes actually read.
alias drflac_read_proc = size_t function (void* pUserData, void* pBufferOut, size_t bytesToRead);

// Callback for when data needs to be seeked.
//
// pUserData [in] The user data that was passed to drflac_open() and family.
// offset    [in] The number of bytes to move, relative to the origin. Will never be negative.
// origin    [in] The origin of the seek - the current position or the start of the stream.
//
// Returns whether or not the seek was successful.
//
// The offset will never be negative. Whether or not it is relative to the beginning or current position is determined
// by the "origin" parameter which will be either drflac_seek_origin_start or drflac_seek_origin_current.
alias drflac_seek_proc = bool function (void* pUserData, int offset, drflac_seek_origin origin);

// Callback for when a metadata block is read.
//
// pUserData [in] The user data that was passed to drflac_open() and family.
// pMetadata [in] A pointer to a structure containing the data of the metadata block.
//
// Use pMetadata.type to determine which metadata block is being handled and how to read the data.
alias drflac_meta_proc = void delegate (void* pUserData, drflac_metadata* pMetadata);


// Structure for internal use. Only used for decoders opened with drflac_open_memory.
struct drflac__memory_stream {
  const(ubyte)* data;
  size_t dataSize;
  size_t currentReadPos;
}

// Structure for internal use. Used for bit streaming.
struct drflac_bs {
  // The function to call when more data needs to be read.
  //drflac_read_proc onRead;

  // The function to call when the current read position needs to be moved.
  //drflac_seek_proc onSeek;

  // The user data to pass around to onRead and onSeek.
  //void* pUserData;

  ReadStruct rs;

  // The number of unaligned bytes in the L2 cache. This will always be 0 until the end of the stream is hit. At the end of the
  // stream there will be a number of bytes that don't cleanly fit in an L1 cache line, so we use this variable to know whether
  // or not the bistreamer needs to run on a slower path to read those last bytes. This will never be more than (drflac_cache_t).sizeof.
  size_t unalignedByteCount;

  // The content of the unaligned bytes.
  drflac_cache_t unalignedCache;

  // The index of the next valid cache line in the "L2" cache.
  size_t nextL2Line;

  // The number of bits that have been consumed by the cache. This is used to determine how many valid bits are remaining.
  size_t consumedBits;

  // The cached data which was most recently read from the client. There are two levels of cache. Data flows as such:
  // Client . L2 . L1. The L2 . L1 movement is aligned and runs on a fast path in just a few instructions.
  drflac_cache_t[DR_FLAC_BUFFER_SIZE/(drflac_cache_t).sizeof] cacheL2;
  drflac_cache_t cache;
}

struct drflac_subframe {
  // The type of the subframe: SUBFRAME_CONSTANT, SUBFRAME_VERBATIM, SUBFRAME_FIXED or SUBFRAME_LPC.
  ubyte subframeType;

  // The number of wasted bits per sample as specified by the sub-frame header.
  ubyte wastedBitsPerSample;

  // The order to use for the prediction stage for SUBFRAME_FIXED and SUBFRAME_LPC.
  ubyte lpcOrder;

  // The number of bits per sample for this subframe. This is not always equal to the current frame's bit per sample because
  // an extra bit is required for side channels when interchannel decorrelation is being used.
  uint bitsPerSample;

  // A pointer to the buffer containing the decoded samples in the subframe. This pointer is an offset from drflac::pExtraData, or
  // null if the heap is not being used. Note that it's a signed 32-bit integer for each value.
  int* pDecodedSamples;
}

struct drflac_frame_header {
  // If the stream uses variable block sizes, this will be set to the index of the first sample. If fixed block sizes are used, this will
  // always be set to 0.
  ulong sampleNumber;

  // If the stream uses fixed block sizes, this will be set to the frame number. If variable block sizes are used, this will always be 0.
  uint frameNumber;

  // The sample rate of this frame.
  uint sampleRate;

  // The number of samples in each sub-frame within this frame.
  ushort blockSize;

  // The channel assignment of this frame. This is not always set to the channel count. If interchannel decorrelation is being used this
  // will be set to DRFLAC_CHANNEL_ASSIGNMENT_LEFT_SIDE, DRFLAC_CHANNEL_ASSIGNMENT_RIGHT_SIDE or DRFLAC_CHANNEL_ASSIGNMENT_MID_SIDE.
  ubyte channelAssignment;

  // The number of bits per sample within this frame.
  ubyte bitsPerSample;

  // The frame's CRC. This is set, but unused at the moment.
  ubyte crc8;
}

struct drflac_frame {
  // The header.
  drflac_frame_header header;

  // The number of samples left to be read in this frame. This is initially set to the block size multiplied by the channel count. As samples
  // are read, this will be decremented. When it reaches 0, the decoder will see this frame as fully consumed and load the next frame.
  uint samplesRemaining;

  // The list of sub-frames within the frame. There is one sub-frame for each channel, and there's a maximum of 8 channels.
  drflac_subframe[8] subframes;
}

struct drflac {
  // The function to call when a metadata block is read.
  //drflac_meta_proc onMeta;

  // The user data posted to the metadata callback function.
  //void* pUserDataMD;


  // The sample rate. Will be set to something like 44100.
  uint sampleRate;

  // The number of channels. This will be set to 1 for monaural streams, 2 for stereo, etc. Maximum 8. This is set based on the
  // value specified in the STREAMINFO block.
  ubyte channels;

  // The bits per sample. Will be set to somthing like 16, 24, etc.
  ubyte bitsPerSample;

  // The maximum block size, in samples. This number represents the number of samples in each channel (not combined).
  ushort maxBlockSize;

  // The total number of samples making up the stream. This includes every channel. For example, if the stream has 2 channels,
  // with each channel having a total of 4096, this value will be set to 2*4096 = 8192. Can be 0 in which case it's still a
  // valid stream, but just means the total sample count is unknown. Likely the case with streams like internet radio.
  ulong totalSampleCount;


  // The container type. This is set based on whether or not the decoder was opened from a native or Ogg stream.
  drflac_container container;


  // The position of the seektable in the file.
  ulong seektablePos;

  // The size of the seektable.
  uint seektableSize;


  // Information about the frame the decoder is currently sitting on.
  drflac_frame currentFrame;

  // The position of the first frame in the stream. This is only ever used for seeking.
  ulong firstFramePos;


  // A hack to avoid a malloc() when opening a decoder with drflac_open_memory().
  drflac__memory_stream memoryStream;


  // A pointer to the decoded sample data. This is an offset of pExtraData.
  int* pDecodedSamples;


  // The bit streamer. The raw FLAC data is fed through this object.
  drflac_bs bs;

  // Variable length extra data. We attach this to the end of the object so we avoid unnecessary mallocs.
  ubyte[1] pExtraData;
}


// Opens a FLAC decoder.
//
// onRead    [in]           The function to call when data needs to be read from the client.
// onSeek    [in]           The function to call when the read position of the client data needs to move.
// pUserData [in, optional] A pointer to application defined data that will be passed to onRead and onSeek.
//
// Returns a pointer to an object representing the decoder.
//
// Close the decoder with drflac_close().
//
// This function will automatically detect whether or not you are attempting to open a native or Ogg encapsulated
// FLAC, both of which should work seamlessly without any manual intervention. Ogg encapsulation also works with
// multiplexed streams which basically means it can play FLAC encoded audio tracks in videos.
//
// This is the lowest level function for opening a FLAC stream. You can also use drflac_open_file() and drflac_open_memory()
// to open the stream from a file or from a block of memory respectively.
//
// The STREAMINFO block must be present for this to succeed.
//
// See also: drflac_open_file(), drflac_open_memory(), drflac_open_with_metadata(), drflac_close()
//drflac* drflac_open(drflac_read_proc onRead, drflac_seek_proc onSeek, void* pUserData);

// Opens a FLAC decoder and notifies the caller of the metadata chunks (album art, etc.).
//
// onRead    [in]           The function to call when data needs to be read from the client.
// onSeek    [in]           The function to call when the read position of the client data needs to move.
// onMeta    [in]           The function to call for every metadata block.
// pUserData [in, optional] A pointer to application defined data that will be passed to onRead, onSeek and onMeta.
//
// Returns a pointer to an object representing the decoder.
//
// Close the decoder with drflac_close().
//
// This is slower that drflac_open(), so avoid this one if you don't need metadata. Internally, this will do a malloc()
// and free() for every metadata block except for STREAMINFO and PADDING blocks.
//
// The caller is notified of the metadata via the onMeta callback. All metadata blocks withh be handled before the function
// returns.
//
// See also: drflac_open_file_with_metadata(), drflac_open_memory_with_metadata(), drflac_open(), drflac_close()
//drflac* drflac_open_with_metadata(drflac_read_proc onRead, drflac_seek_proc onSeek, drflac_meta_proc onMeta, void* pUserData);

// Closes the given FLAC decoder.
//
// pFlac [in] The decoder to close.
//
// This will destroy the decoder object.
//void drflac_close(drflac* pFlac);


// Reads sample data from the given FLAC decoder, output as interleaved signed 32-bit PCM.
//
// pFlac         [in]            The decoder.
// samplesToRead [in]            The number of samples to read.
// pBufferOut    [out, optional] A pointer to the buffer that will receive the decoded samples.
//
// Returns the number of samples actually read.
//
// pBufferOut can be null, in which case the call will act as a seek, and the return value will be the number of samples
// seeked.
//ulong drflac_read_s32(drflac* pFlac, ulong samplesToRead, int* pBufferOut);

// Seeks to the sample at the given index.
//
// pFlac       [in] The decoder.
// sampleIndex [in] The index of the sample to seek to. See notes below.
//
// Returns true if successful; false otherwise.
//
// The sample index is based on interleaving. In a stereo stream, for example, the sample at index 0 is the first sample
// in the left channel; the sample at index 1 is the first sample on the right channel, and so on.
//
// When seeking, you will likely want to ensure it's rounded to a multiple of the channel count. You can do this with
// something like drflac_seek_to_sample(pFlac, (mySampleIndex + (mySampleIndex % pFlac.channels)))
//bool drflac_seek_to_sample(drflac* pFlac, ulong sampleIndex);


// Opens a FLAC decoder from the file at the given path.
//
// filename [in] The path of the file to open, either absolute or relative to the current directory.
//
// Returns a pointer to an object representing the decoder.
//
// Close the decoder with drflac_close().
//
// This will hold a handle to the file until the decoder is closed with drflac_close(). Some platforms will restrict the
// number of files a process can have open at any given time, so keep this mind if you have many decoders open at the
// same time.
//
// See also: drflac_open(), drflac_open_file_with_metadata(), drflac_close()
//drflac* drflac_open_file(const(char)[] filename);

// Opens a FLAC decoder from the file at the given path and notifies the caller of the metadata chunks (album art, etc.)
//
// Look at the documentation for drflac_open_with_metadata() for more information on how metadata is handled.
//drflac* drflac_open_file_with_metadata(const(char)[] filename, drflac_meta_proc onMeta, void* pUserData);

// Opens a FLAC decoder from a pre-allocated block of memory
//
// This does not create a copy of the data. It is up to the application to ensure the buffer remains valid for
// the lifetime of the decoder.
//drflac* drflac_open_memory(const void* data, size_t dataSize);

// Opens a FLAC decoder from a pre-allocated block of memory and notifies the caller of the metadata chunks (album art, etc.)
//
// Look at the documentation for drflac_open_with_metadata() for more information on how metadata is handled.
//drflac* drflac_open_memory_with_metadata(const void* data, size_t dataSize, drflac_meta_proc onMeta, void* pUserData);



//// High Level APIs ////

// Opens a FLAC stream from the given callbacks and fully decodes it in a single operation. The return value is a
// pointer to the sample data as interleaved signed 32-bit PCM. The returned data must be freed with drflac_free().
//
// Sometimes a FLAC file won't keep track of the total sample count. In this situation the function will continuously
// read samples into a dynamically sized buffer on the heap until no samples are left.
//
// Do not call this function on a broadcast type of stream (like internet radio streams and whatnot).
//int* drflac_open_and_decode(drflac_read_proc onRead, drflac_seek_proc onSeek, void* pUserData, uint* sampleRate, uint* channels, ulong* totalSampleCount);

//#ifndef DR_FLAC_NO_STDIO
// Same as drflac_open_and_decode() except opens the decoder from a file.
//int* drflac_open_and_decode_file(const(char)[] filename, uint* sampleRate, uint* channels, ulong* totalSampleCount);
//#endif

// Same as drflac_open_and_decode() except opens the decoder from a block of memory.
//int* drflac_open_and_decode_memory(const void* data, size_t dataSize, uint* sampleRate, uint* channels, ulong* totalSampleCount);

// Frees data returned by drflac_open_and_decode_*().
//void drflac_free(void* pSampleDataReturnedByOpenAndDecode);


// Structure representing an iterator for vorbis comments in a VORBIS_COMMENT metadata block.
struct drflac_vorbis_comment_iterator {
  uint countRemaining;
  const(char)* pRunningData;
}

// Initializes a vorbis comment iterator. This can be used for iterating over the vorbis comments in a VORBIS_COMMENT
// metadata block.
//void drflac_init_vorbis_comment_iterator(drflac_vorbis_comment_iterator* pIter, uint commentCount, const(char)* pComments);

// Goes to the next vorbis comment in the given iterator. If null is returned it means there are no more comments. The
// returned string is NOT null terminated.
//const(char)* drflac_next_vorbis_comment(drflac_vorbis_comment_iterator* pIter, uint* pCommentLengthOut);


///////////////////////////////////////////////////////////////////////////////
//
// IMPLEMENTATION
//
///////////////////////////////////////////////////////////////////////////////
private: nothrow {
enum DRFLAC_SUBFRAME_CONSTANT = 0;
enum DRFLAC_SUBFRAME_VERBATIM = 1;
enum DRFLAC_SUBFRAME_FIXED = 8;
enum DRFLAC_SUBFRAME_LPC = 32;
enum DRFLAC_SUBFRAME_RESERVED = 255;

enum DRFLAC_RESIDUAL_CODING_METHOD_PARTITIONED_RICE = 0;
enum DRFLAC_RESIDUAL_CODING_METHOD_PARTITIONED_RICE2 = 1;

enum DRFLAC_CHANNEL_ASSIGNMENT_INDEPENDENT = 0;
enum DRFLAC_CHANNEL_ASSIGNMENT_LEFT_SIDE = 8;
enum DRFLAC_CHANNEL_ASSIGNMENT_RIGHT_SIDE = 9;
enum DRFLAC_CHANNEL_ASSIGNMENT_MID_SIDE = 10;


//// Endian Management ////
version(LittleEndian) enum drflac__is_little_endian = true; else enum drflac__is_little_endian = false;

ushort drflac__be2host_16 (ushort n) pure nothrow @safe @nogc {
  static if (__VERSION__ > 2067) pragma(inline, true);
  version(LittleEndian) {
    return cast(ushort)((n>>8)|((n&0xff)<<8));
  } else {
    return n;
  }
}

uint drflac__be2host_32 (uint n) pure nothrow @safe @nogc {
  static if (__VERSION__ > 2067) pragma(inline, true);
  version(LittleEndian) {
    import core.bitop : bswap;
    return bswap(n);
  } else {
    return n;
  }
}

ulong drflac__be2host_64 (ulong n) pure nothrow @safe @nogc {
  static if (__VERSION__ > 2067) pragma(inline, true);
  version(LittleEndian) {
    import core.bitop : bswap;
    version(GNU) {
      auto n0 = cast(ulong)bswap(cast(uint)n);
      auto n1 = cast(ulong)bswap(cast(uint)(n>>32));
      return (n0<<32)|n1;
    } else {
      return bswap(n);
    }
  } else {
    return n;
  }
}


uint drflac__le2host_32 (uint n) pure nothrow @safe @nogc {
  static if (__VERSION__ > 2067) pragma(inline, true);
  version(LittleEndian) {
    return n;
  } else {
    import core.bitop : bswap;
    return bswap(n);
  }
}


version(DRFLAC_64BIT) {
  alias drflac__be2host__cache_line = drflac__be2host_64;
} else {
  alias drflac__be2host__cache_line = drflac__be2host_32;
}

// BIT READING ATTEMPT #2
//
// This uses a 32- or 64-bit bit-shifted cache - as bits are read, the cache is shifted such that the first valid bit is sitting
// on the most significant bit. It uses the notion of an L1 and L2 cache (borrowed from CPU architecture), where the L1 cache
// is a 32- or 64-bit unsigned integer (depending on whether or not a 32- or 64-bit build is being compiled) and the L2 is an
// array of "cache lines", with each cache line being the same size as the L1. The L2 is a buffer of about 4KB and is where data
// from onRead() is read into.
enum DRFLAC_CACHE_L1_SIZE_BYTES(string bs) = "((("~bs~").cache).sizeof)";
enum DRFLAC_CACHE_L1_SIZE_BITS(string bs) = "((("~bs~").cache).sizeof*8)";
enum DRFLAC_CACHE_L1_BITS_REMAINING(string bs) = "("~DRFLAC_CACHE_L1_SIZE_BITS!(bs)~"-(("~bs~").consumedBits))";
version(DRFLAC_64BIT) {
  enum DRFLAC_CACHE_L1_SELECTION_MASK(string _bitCount) = "(~((cast(ulong)-1L)>>("~_bitCount~")))";
} else {
  enum DRFLAC_CACHE_L1_SELECTION_MASK(string _bitCount) = "(~((cast(uint)-1)>>("~_bitCount~")))";
}
enum DRFLAC_CACHE_L1_SELECTION_SHIFT(string bs, string _bitCount) = "("~DRFLAC_CACHE_L1_SIZE_BITS!bs~"-("~_bitCount~"))";
enum DRFLAC_CACHE_L1_SELECT(string bs, string _bitCount) = "((("~bs~").cache)&"~DRFLAC_CACHE_L1_SELECTION_MASK!_bitCount~")";
enum DRFLAC_CACHE_L1_SELECT_AND_SHIFT(string bs, string _bitCount) = "("~DRFLAC_CACHE_L1_SELECT!(bs, _bitCount)~">>"~DRFLAC_CACHE_L1_SELECTION_SHIFT!(bs, _bitCount)~")";
enum DRFLAC_CACHE_L2_SIZE_BYTES(string bs) = "((("~bs~").cacheL2).sizeof)";
enum DRFLAC_CACHE_L2_LINE_COUNT(string bs) = "("~DRFLAC_CACHE_L2_SIZE_BYTES!bs~"/(("~bs~").cacheL2[0]).sizeof)";
enum DRFLAC_CACHE_L2_LINES_REMAINING(string bs) = "("~DRFLAC_CACHE_L2_LINE_COUNT!bs~"-("~bs~").nextL2Line)";

bool drflac__reload_l1_cache_from_l2 (drflac_bs* bs) {
  // Fast path. Try loading straight from L2.
  if (bs.nextL2Line < mixin(DRFLAC_CACHE_L2_LINE_COUNT!"bs")) {
    bs.cache = bs.cacheL2.ptr[bs.nextL2Line++];
    return true;
  }

  // If we get here it means we've run out of data in the L2 cache. We'll need to fetch more from the client, if there's any left.
  if (bs.unalignedByteCount > 0) return false; // If we have any unaligned bytes it means there's no more aligned bytes left in the client.

  size_t bytesRead = bs.rs.read(bs.cacheL2.ptr, mixin(DRFLAC_CACHE_L2_SIZE_BYTES!"bs"));

  bs.nextL2Line = 0;
  if (bytesRead == mixin(DRFLAC_CACHE_L2_SIZE_BYTES!"bs")) {
    bs.cache = bs.cacheL2.ptr[bs.nextL2Line++];
    return true;
  }

  // If we get here it means we were unable to retrieve enough data to fill the entire L2 cache. It probably
  // means we've just reached the end of the file. We need to move the valid data down to the end of the buffer
  // and adjust the index of the next line accordingly. Also keep in mind that the L2 cache must be aligned to
  // the size of the L1 so we'll need to seek backwards by any misaligned bytes.
  size_t alignedL1LineCount = bytesRead/mixin(DRFLAC_CACHE_L1_SIZE_BYTES!"bs");

  // We need to keep track of any unaligned bytes for later use.
  bs.unalignedByteCount = bytesRead-(alignedL1LineCount*mixin(DRFLAC_CACHE_L1_SIZE_BYTES!"bs"));
  if (bs.unalignedByteCount > 0) {
      bs.unalignedCache = bs.cacheL2.ptr[alignedL1LineCount];
  }

  if (alignedL1LineCount > 0) {
    size_t offset = mixin(DRFLAC_CACHE_L2_LINE_COUNT!"bs")-alignedL1LineCount;
    for (size_t i = alignedL1LineCount; i > 0; --i) bs.cacheL2.ptr[i-1+offset] = bs.cacheL2.ptr[i-1];
    bs.nextL2Line = offset;
    bs.cache = bs.cacheL2.ptr[bs.nextL2Line++];
    return true;
  } else {
    // If we get into this branch it means we weren't able to load any L1-aligned data.
    bs.nextL2Line = mixin(DRFLAC_CACHE_L2_LINE_COUNT!"bs");
    return false;
  }
}

bool drflac__reload_cache (drflac_bs* bs) {
  // Fast path. Try just moving the next value in the L2 cache to the L1 cache.
  if (drflac__reload_l1_cache_from_l2(bs)) {
    bs.cache = drflac__be2host__cache_line(bs.cache);
    bs.consumedBits = 0;
    return true;
  }

  // Slow path.

  // If we get here it means we have failed to load the L1 cache from the L2. Likely we've just reached the end of the stream and the last
  // few bytes did not meet the alignment requirements for the L2 cache. In this case we need to fall back to a slower path and read the
  // data from the unaligned cache.
  size_t bytesRead = bs.unalignedByteCount;
  if (bytesRead == 0) return false;

  assert(bytesRead < mixin(DRFLAC_CACHE_L1_SIZE_BYTES!"bs"));
  bs.consumedBits = (mixin(DRFLAC_CACHE_L1_SIZE_BYTES!"bs")-bytesRead)*8;

  bs.cache = drflac__be2host__cache_line(bs.unalignedCache);
  //bs.cache &= DRFLAC_CACHE_L1_SELECTION_MASK(DRFLAC_CACHE_L1_SIZE_BITS(bs)-bs.consumedBits);
  bs.cache &= mixin(DRFLAC_CACHE_L1_SELECTION_MASK!(DRFLAC_CACHE_L1_SIZE_BITS!"bs"~"-bs.consumedBits"));
    // <-- Make sure the consumed bits are always set to zero. Other parts of the library depend on this property.
  bs.unalignedByteCount = 0; // <-- At this point the unaligned bytes have been moved into the cache and we thus have no more unaligned bytes.
  return true;
}

void drflac__reset_cache (drflac_bs* bs) {
  bs.nextL2Line   = mixin(DRFLAC_CACHE_L2_LINE_COUNT!"bs");  // <-- This clears the L2 cache.
  bs.consumedBits = mixin(DRFLAC_CACHE_L1_SIZE_BITS!"bs");   // <-- This clears the L1 cache.
  bs.cache = 0;
  bs.unalignedByteCount = 0; // <-- This clears the trailing unaligned bytes.
  bs.unalignedCache = 0;
}

bool drflac__seek_bits (drflac_bs* bs, size_t bitsToSeek) {
  if (bitsToSeek <= mixin(DRFLAC_CACHE_L1_BITS_REMAINING!"bs")) {
    bs.consumedBits += bitsToSeek;
    bs.cache <<= bitsToSeek;
    return true;
  } else {
    // It straddles the cached data. This function isn't called too frequently so I'm favouring simplicity here.
    bitsToSeek -= mixin(DRFLAC_CACHE_L1_BITS_REMAINING!"bs");
    bs.consumedBits += mixin(DRFLAC_CACHE_L1_BITS_REMAINING!"bs");
    bs.cache = 0;

    size_t wholeBytesRemainingToSeek = bitsToSeek/8;
    if (wholeBytesRemainingToSeek > 0) {
      // The next bytes to seek will be located in the L2 cache. The problem is that the L2 cache is not byte aligned,
      // but rather DRFLAC_CACHE_L1_SIZE_BYTES aligned (usually 4 or 8). If, for example, the number of bytes to seek is
      // 3, we'll need to handle it in a special way.
      size_t wholeCacheLinesRemaining = wholeBytesRemainingToSeek/mixin(DRFLAC_CACHE_L1_SIZE_BYTES!"bs");
      if (wholeCacheLinesRemaining < mixin(DRFLAC_CACHE_L2_LINES_REMAINING!"bs")) {
        wholeBytesRemainingToSeek -= wholeCacheLinesRemaining*mixin(DRFLAC_CACHE_L1_SIZE_BYTES!"bs");
        bitsToSeek -= wholeCacheLinesRemaining*mixin(DRFLAC_CACHE_L1_SIZE_BITS!"bs");
        bs.nextL2Line += wholeCacheLinesRemaining;
      } else {
        wholeBytesRemainingToSeek -= mixin(DRFLAC_CACHE_L2_LINES_REMAINING!"bs")*mixin(DRFLAC_CACHE_L1_SIZE_BYTES!"bs");
        bitsToSeek -= mixin(DRFLAC_CACHE_L2_LINES_REMAINING!"bs")*mixin(DRFLAC_CACHE_L1_SIZE_BITS!"bs");
        bs.nextL2Line += mixin(DRFLAC_CACHE_L2_LINES_REMAINING!"bs");
        // Note that we only seek on the client side if it's got any data left to seek. We can know this by checking
        // if we have any unaligned data which can be determined with bs->unalignedByteCount.
        if (wholeBytesRemainingToSeek > 0 && bs.unalignedByteCount == 0) {
          if (!bs.rs.seek(cast(int)wholeBytesRemainingToSeek, drflac_seek_origin_current)) return false;
          bitsToSeek -= wholeBytesRemainingToSeek*8;
        }
      }
    }
    if (bitsToSeek > 0) {
      if (!drflac__reload_cache(bs)) return false;
      return drflac__seek_bits(bs, bitsToSeek);
    }
    return true;
  }
}

bool drflac__read_uint32 (drflac_bs* bs, uint bitCount, uint* pResultOut) {
  assert(bs !is null);
  assert(pResultOut !is null);
  assert(bitCount > 0);
  assert(bitCount <= 32);

  if (bs.consumedBits == mixin(DRFLAC_CACHE_L1_SIZE_BITS!"bs")) {
    if (!drflac__reload_cache(bs)) return false;
  }

  if (bitCount <= mixin(DRFLAC_CACHE_L1_BITS_REMAINING!"bs")) {
    if (bitCount < mixin(DRFLAC_CACHE_L1_SIZE_BITS!"bs")) {
      *pResultOut = cast(uint)mixin(DRFLAC_CACHE_L1_SELECT_AND_SHIFT!("bs", "bitCount")); //k8
      bs.consumedBits += bitCount;
      bs.cache <<= bitCount;
    } else {
      *pResultOut = cast(uint)bs.cache;
      bs.consumedBits = mixin(DRFLAC_CACHE_L1_SIZE_BITS!"bs");
      bs.cache = 0;
    }
    return true;
  } else {
    // It straddles the cached data. It will never cover more than the next chunk. We just read the number in two parts and combine them.
    size_t bitCountHi = mixin(DRFLAC_CACHE_L1_BITS_REMAINING!"bs");
    size_t bitCountLo = bitCount-bitCountHi;
    uint resultHi = cast(uint)mixin(DRFLAC_CACHE_L1_SELECT_AND_SHIFT!("bs", "bitCountHi")); //k8
    if (!drflac__reload_cache(bs)) return false;
    *pResultOut = cast(uint)((resultHi<<bitCountLo)|mixin(DRFLAC_CACHE_L1_SELECT_AND_SHIFT!("bs", "bitCountLo"))); //k8
    bs.consumedBits += bitCountLo;
    bs.cache <<= bitCountLo;
    return true;
  }
}

bool drflac__read_int32 (drflac_bs* bs, uint bitCount, int* pResult) {
  assert(bs !is null);
  assert(pResult !is null);
  assert(bitCount > 0);
  assert(bitCount <= 32);

  uint result;
  if (!drflac__read_uint32(bs, bitCount, &result)) return false;

  uint signbit = ((result>>(bitCount-1))&0x01);
  result |= (~signbit+1)<<bitCount;

  *pResult = cast(int)result;
  return true;
}

bool drflac__read_uint64 (drflac_bs* bs, uint bitCount, ulong* pResultOut) {
  assert(bitCount <= 64);
  assert(bitCount >  32);

  uint resultHi;
  if (!drflac__read_uint32(bs, bitCount-32, &resultHi)) return false;

  uint resultLo;
  if (!drflac__read_uint32(bs, 32, &resultLo)) return false;

  *pResultOut = ((cast(ulong)resultHi)<<32)|(cast(ulong)resultLo);
  return true;
}

bool drflac__read_uint16 (drflac_bs* bs, uint bitCount, ushort* pResult) {
  assert(bs !is null);
  assert(pResult !is null);
  assert(bitCount > 0);
  assert(bitCount <= 16);

  uint result;
  if (!drflac__read_uint32(bs, bitCount, &result)) return false;

  *pResult = cast(ushort)result;
  return true;
}

bool drflac__read_int16 (drflac_bs* bs, uint bitCount, short* pResult) {
  assert(bs !is null);
  assert(pResult !is null);
  assert(bitCount > 0);
  assert(bitCount <= 16);

  int result;
  if (!drflac__read_int32(bs, bitCount, &result)) return false;

  *pResult = cast(short)result;
  return true;
}

bool drflac__read_uint8 (drflac_bs* bs, uint bitCount, ubyte* pResult) {
  assert(bs !is null);
  assert(pResult !is null);
  assert(bitCount > 0);
  assert(bitCount <= 8);

  uint result;
  if (!drflac__read_uint32(bs, bitCount, &result)) return false;

  *pResult = cast(ubyte)result;
  return true;
}

bool drflac__read_int8 (drflac_bs* bs, uint bitCount, byte* pResult) {
  assert(bs !is null);
  assert(pResult !is null);
  assert(bitCount > 0);
  assert(bitCount <= 8);

  int result;
  if (!drflac__read_int32(bs, bitCount, &result)) return false;

  *pResult = cast(byte)result;
  return true;
}


bool drflac__seek_past_next_set_bit (drflac_bs* bs, uint* pOffsetOut) {
  uint zeroCounter = 0;
  while (bs.cache == 0) {
    zeroCounter += cast(uint)mixin(DRFLAC_CACHE_L1_BITS_REMAINING!"bs");
    if (!drflac__reload_cache(bs)) return false;
  }

  // At this point the cache should not be zero, in which case we know the first set bit should be somewhere in here. There is
  // no need for us to perform any cache reloading logic here which should make things much faster.
  assert(bs.cache != 0);

  static immutable uint[16] bitOffsetTable = [
    0,
    4,
    3, 3,
    2, 2, 2, 2,
    1, 1, 1, 1, 1, 1, 1, 1
  ];

  uint setBitOffsetPlus1 = bitOffsetTable.ptr[mixin(DRFLAC_CACHE_L1_SELECT_AND_SHIFT!("bs", "4"))];
  if (setBitOffsetPlus1 == 0) {
    if (bs.cache == 1) {
      setBitOffsetPlus1 = mixin(DRFLAC_CACHE_L1_SIZE_BITS!"bs");
    } else {
      setBitOffsetPlus1 = 5;
      for (;;) {
        if ((bs.cache&mixin(DRFLAC_CACHE_L1_SELECT!("bs", "setBitOffsetPlus1")))) break;
        setBitOffsetPlus1 += 1;
      }
    }
  }

  bs.consumedBits += setBitOffsetPlus1;
  bs.cache <<= setBitOffsetPlus1;

  *pOffsetOut = zeroCounter+setBitOffsetPlus1-1;
  return true;
}


bool drflac__seek_to_byte (drflac_bs* bs, ulong offsetFromStart) {
  assert(bs !is null);
  assert(offsetFromStart > 0);

  // Seeking from the start is not quite as trivial as it sounds because the onSeek callback takes a signed 32-bit integer (which
  // is intentional because it simplifies the implementation of the onSeek callbacks), however offsetFromStart is unsigned 64-bit.
  // To resolve we just need to do an initial seek from the start, and then a series of offset seeks to make up the remainder.
  if (offsetFromStart > 0x7FFFFFFF) {
    ulong bytesRemaining = offsetFromStart;
    if (!bs.rs.seek(0x7FFFFFFF, drflac_seek_origin_start)) return false;
    bytesRemaining -= 0x7FFFFFFF;
    while (bytesRemaining > 0x7FFFFFFF) {
      if (!bs.rs.seek(0x7FFFFFFF, drflac_seek_origin_current)) return false;
      bytesRemaining -= 0x7FFFFFFF;
    }
    if (bytesRemaining > 0) {
      if (!bs.rs.seek(cast(int)bytesRemaining, drflac_seek_origin_current)) return false;
    }
  } else {
    if (!bs.rs.seek(cast(int)offsetFromStart, drflac_seek_origin_start)) return false;
  }
  // The cache should be reset to force a reload of fresh data from the client.
  drflac__reset_cache(bs);
  return true;
}


bool drflac__read_utf8_coded_number (drflac_bs* bs, ulong* pNumberOut) {
  assert(bs !is null);
  assert(pNumberOut !is null);

  ubyte[7] utf8 = 0;
  if (!drflac__read_uint8(bs, 8, utf8.ptr)) {
    *pNumberOut = 0;
    return false;
  }

  if ((utf8.ptr[0]&0x80) == 0) {
    *pNumberOut = utf8.ptr[0];
    return true;
  }

  int byteCount = 1;
       if ((utf8.ptr[0]&0xE0) == 0xC0) byteCount = 2;
  else if ((utf8.ptr[0]&0xF0) == 0xE0) byteCount = 3;
  else if ((utf8.ptr[0]&0xF8) == 0xF0) byteCount = 4;
  else if ((utf8.ptr[0]&0xFC) == 0xF8) byteCount = 5;
  else if ((utf8.ptr[0]&0xFE) == 0xFC) byteCount = 6;
  else if ((utf8.ptr[0]&0xFF) == 0xFE) byteCount = 7;
  else { *pNumberOut = 0; return false; } // Bad UTF-8 encoding.

  // Read extra bytes.
  assert(byteCount > 1);

  ulong result = cast(ulong)(utf8.ptr[0]&(0xFF>>(byteCount+1)));
  for (int i = 1; i < byteCount; ++i) {
    if (!drflac__read_uint8(bs, 8, utf8.ptr+i)) {
      *pNumberOut = 0;
      return false;
    }
    result = (result<<6)|(utf8.ptr[i]&0x3F);
  }

  *pNumberOut = result;
  return true;
}


bool drflac__read_and_seek_rice (drflac_bs* bs, ubyte m) {
  uint unused;
  if (!drflac__seek_past_next_set_bit(bs, &unused)) return false;
  if (m > 0) {
    if (!drflac__seek_bits(bs, m)) return false;
  }
  return true;
}


// The next two functions are responsible for calculating the prediction.
//
// When the bits per sample is >16 we need to use 64-bit integer arithmetic because otherwise we'll run out of precision. It's
// safe to assume this will be slower on 32-bit platforms so we use a more optimal solution when the bits per sample is <=16.
int drflac__calculate_prediction_32 (uint order, int shift, const(short)* coefficients, int* pDecodedSamples) {
  assert(order <= 32);
  int prediction = 0;
  switch (order) {
    case 32: prediction += coefficients[31]*pDecodedSamples[-32]; goto case;
    case 31: prediction += coefficients[30]*pDecodedSamples[-31]; goto case;
    case 30: prediction += coefficients[29]*pDecodedSamples[-30]; goto case;
    case 29: prediction += coefficients[28]*pDecodedSamples[-29]; goto case;
    case 28: prediction += coefficients[27]*pDecodedSamples[-28]; goto case;
    case 27: prediction += coefficients[26]*pDecodedSamples[-27]; goto case;
    case 26: prediction += coefficients[25]*pDecodedSamples[-26]; goto case;
    case 25: prediction += coefficients[24]*pDecodedSamples[-25]; goto case;
    case 24: prediction += coefficients[23]*pDecodedSamples[-24]; goto case;
    case 23: prediction += coefficients[22]*pDecodedSamples[-23]; goto case;
    case 22: prediction += coefficients[21]*pDecodedSamples[-22]; goto case;
    case 21: prediction += coefficients[20]*pDecodedSamples[-21]; goto case;
    case 20: prediction += coefficients[19]*pDecodedSamples[-20]; goto case;
    case 19: prediction += coefficients[18]*pDecodedSamples[-19]; goto case;
    case 18: prediction += coefficients[17]*pDecodedSamples[-18]; goto case;
    case 17: prediction += coefficients[16]*pDecodedSamples[-17]; goto case;
    case 16: prediction += coefficients[15]*pDecodedSamples[-16]; goto case;
    case 15: prediction += coefficients[14]*pDecodedSamples[-15]; goto case;
    case 14: prediction += coefficients[13]*pDecodedSamples[-14]; goto case;
    case 13: prediction += coefficients[12]*pDecodedSamples[-13]; goto case;
    case 12: prediction += coefficients[11]*pDecodedSamples[-12]; goto case;
    case 11: prediction += coefficients[10]*pDecodedSamples[-11]; goto case;
    case 10: prediction += coefficients[ 9]*pDecodedSamples[-10]; goto case;
    case  9: prediction += coefficients[ 8]*pDecodedSamples[- 9]; goto case;
    case  8: prediction += coefficients[ 7]*pDecodedSamples[- 8]; goto case;
    case  7: prediction += coefficients[ 6]*pDecodedSamples[- 7]; goto case;
    case  6: prediction += coefficients[ 5]*pDecodedSamples[- 6]; goto case;
    case  5: prediction += coefficients[ 4]*pDecodedSamples[- 5]; goto case;
    case  4: prediction += coefficients[ 3]*pDecodedSamples[- 4]; goto case;
    case  3: prediction += coefficients[ 2]*pDecodedSamples[- 3]; goto case;
    case  2: prediction += coefficients[ 1]*pDecodedSamples[- 2]; goto case;
    case  1: prediction += coefficients[ 0]*pDecodedSamples[- 1]; goto default;
    default:
  }
  return cast(int)(prediction>>shift);
}

int drflac__calculate_prediction_64 (uint order, int shift, const(short)* coefficients, int* pDecodedSamples) {
  assert(order <= 32);
  long prediction = 0;
  switch (order) {
    case 32: prediction += coefficients[31]*cast(long)pDecodedSamples[-32]; goto case;
    case 31: prediction += coefficients[30]*cast(long)pDecodedSamples[-31]; goto case;
    case 30: prediction += coefficients[29]*cast(long)pDecodedSamples[-30]; goto case;
    case 29: prediction += coefficients[28]*cast(long)pDecodedSamples[-29]; goto case;
    case 28: prediction += coefficients[27]*cast(long)pDecodedSamples[-28]; goto case;
    case 27: prediction += coefficients[26]*cast(long)pDecodedSamples[-27]; goto case;
    case 26: prediction += coefficients[25]*cast(long)pDecodedSamples[-26]; goto case;
    case 25: prediction += coefficients[24]*cast(long)pDecodedSamples[-25]; goto case;
    case 24: prediction += coefficients[23]*cast(long)pDecodedSamples[-24]; goto case;
    case 23: prediction += coefficients[22]*cast(long)pDecodedSamples[-23]; goto case;
    case 22: prediction += coefficients[21]*cast(long)pDecodedSamples[-22]; goto case;
    case 21: prediction += coefficients[20]*cast(long)pDecodedSamples[-21]; goto case;
    case 20: prediction += coefficients[19]*cast(long)pDecodedSamples[-20]; goto case;
    case 19: prediction += coefficients[18]*cast(long)pDecodedSamples[-19]; goto case;
    case 18: prediction += coefficients[17]*cast(long)pDecodedSamples[-18]; goto case;
    case 17: prediction += coefficients[16]*cast(long)pDecodedSamples[-17]; goto case;
    case 16: prediction += coefficients[15]*cast(long)pDecodedSamples[-16]; goto case;
    case 15: prediction += coefficients[14]*cast(long)pDecodedSamples[-15]; goto case;
    case 14: prediction += coefficients[13]*cast(long)pDecodedSamples[-14]; goto case;
    case 13: prediction += coefficients[12]*cast(long)pDecodedSamples[-13]; goto case;
    case 12: prediction += coefficients[11]*cast(long)pDecodedSamples[-12]; goto case;
    case 11: prediction += coefficients[10]*cast(long)pDecodedSamples[-11]; goto case;
    case 10: prediction += coefficients[ 9]*cast(long)pDecodedSamples[-10]; goto case;
    case  9: prediction += coefficients[ 8]*cast(long)pDecodedSamples[- 9]; goto case;
    case  8: prediction += coefficients[ 7]*cast(long)pDecodedSamples[- 8]; goto case;
    case  7: prediction += coefficients[ 6]*cast(long)pDecodedSamples[- 7]; goto case;
    case  6: prediction += coefficients[ 5]*cast(long)pDecodedSamples[- 6]; goto case;
    case  5: prediction += coefficients[ 4]*cast(long)pDecodedSamples[- 5]; goto case;
    case  4: prediction += coefficients[ 3]*cast(long)pDecodedSamples[- 4]; goto case;
    case  3: prediction += coefficients[ 2]*cast(long)pDecodedSamples[- 3]; goto case;
    case  2: prediction += coefficients[ 1]*cast(long)pDecodedSamples[- 2]; goto case;
    case  1: prediction += coefficients[ 0]*cast(long)pDecodedSamples[- 1]; goto default;
    default:
  }
  return cast(int)(prediction>>shift);
}


// Reads and decodes a string of residual values as Rice codes. The decoder should be sitting on the first bit of the Rice codes.
//
// This is the most frequently called function in the library. It does both the Rice decoding and the prediction in a single loop
// iteration. The prediction is done at the end, and there's an annoying branch I'd like to avoid so the main function is defined
// as a #define - sue me!
//#define DRFLAC__DECODE_SAMPLES_WITH_RESIDULE__RICE__PROC(funcName, predictionFunc)
enum DRFLAC__DECODE_SAMPLES_WITH_RESIDULE__RICE__PROC(string funcName, string predictionFunc) =
"static bool "~funcName~" (drflac_bs* bs, uint count, ubyte riceParam, uint order, int shift, const(short)* coefficients, int* pSamplesOut) {\n"~
"  assert(bs !is null);\n"~
"  assert(count > 0);\n"~
"  assert(pSamplesOut !is null);\n"~
"\n"~
"  static immutable uint[16] bitOffsetTable = [\n"~
"    0,\n"~
"    4,\n"~
"    3, 3,\n"~
"    2, 2, 2, 2,\n"~
"    1, 1, 1, 1, 1, 1, 1, 1\n"~
"  ];\n"~
"\n"~
"  drflac_cache_t riceParamMask = cast(drflac_cache_t)("~DRFLAC_CACHE_L1_SELECTION_MASK!"riceParam"~");\n"~
"  drflac_cache_t resultHiShift = cast(drflac_cache_t)("~DRFLAC_CACHE_L1_SIZE_BITS!"bs"~"-riceParam);\n"~
"\n"~
"  for (int i = 0; i < cast(int)count; ++i) {\n"~
"    uint zeroCounter = 0;\n"~
"    while (bs.cache == 0) {\n"~
"      zeroCounter += cast(uint)"~DRFLAC_CACHE_L1_BITS_REMAINING!"bs"~";\n"~
"      if (!drflac__reload_cache(bs)) return false;\n"~
"    }\n"~
"\n"~
"    /* At this point the cache should not be zero, in which case we know the first set bit should be somewhere in here. There is\n"~
"       no need for us to perform any cache reloading logic here which should make things much faster. */\n"~
"    assert(bs.cache != 0);\n"~
"    uint decodedRice;\n"~
"\n"~
"    uint setBitOffsetPlus1 = bitOffsetTable.ptr["~DRFLAC_CACHE_L1_SELECT_AND_SHIFT!("bs", "4")~"];\n"~
"    if (setBitOffsetPlus1 > 0) {\n"~
"      decodedRice = (zeroCounter+(setBitOffsetPlus1-1))<<riceParam;\n"~
"    } else {\n"~
"      if (bs.cache == 1) {\n"~
"        setBitOffsetPlus1 = cast(uint)("~DRFLAC_CACHE_L1_SIZE_BITS!"bs"~");\n"~
"        decodedRice = cast(uint)((zeroCounter+("~DRFLAC_CACHE_L1_SIZE_BITS!"bs"~"-1))<<riceParam);\n"~
"      } else {\n"~
"        setBitOffsetPlus1 = 5;\n"~
"        for (;;) {\n"~
"          if ((bs.cache&"~DRFLAC_CACHE_L1_SELECT!("bs", "setBitOffsetPlus1")~")) {\n"~
"            decodedRice = (zeroCounter+(setBitOffsetPlus1-1))<<riceParam;\n"~
"            break;\n"~
"          }\n"~
"          setBitOffsetPlus1 += 1;\n"~
"        }\n"~
"      }\n"~
"    }\n"~
"\n"~
"    uint bitsLo = 0;\n"~
"    uint riceLength = setBitOffsetPlus1+riceParam;\n"~
"    if (riceLength < "~DRFLAC_CACHE_L1_BITS_REMAINING!"bs"~") {\n"~
"      bitsLo = cast(uint)((bs.cache&(riceParamMask>>setBitOffsetPlus1))>>("~DRFLAC_CACHE_L1_SIZE_BITS!"bs"~"-riceLength));\n"~
"      bs.consumedBits += riceLength;\n"~
"      bs.cache <<= riceLength;\n"~
"    } else {\n"~
"      bs.consumedBits += riceLength;\n"~
"      bs.cache <<= setBitOffsetPlus1;\n"~
"\n"~
"      /* It straddles the cached data. It will never cover more than the next chunk. We just read the number in two parts and combine them. */\n"~
"      size_t bitCountLo = bs.consumedBits-"~DRFLAC_CACHE_L1_SIZE_BITS!"bs"~";\n"~
"      drflac_cache_t resultHi = bs.cache&riceParamMask;    /* <-- This mask is OK because all bits after the first bits are always zero. */\n"~
"\n"~
"      if (bs.nextL2Line < "~DRFLAC_CACHE_L2_LINE_COUNT!"bs"~") {\n"~
"        bs.cache = drflac__be2host__cache_line(bs.cacheL2.ptr[bs.nextL2Line++]);\n"~
"      } else {\n"~
"        /* Slow path. We need to fetch more data from the client. */\n"~
"        if (!drflac__reload_cache(bs)) return false;\n"~
"      }\n"~
"\n"~
"      bitsLo = cast(uint)((resultHi>>resultHiShift)|"~DRFLAC_CACHE_L1_SELECT_AND_SHIFT!("bs", "bitCountLo")~");\n"~
"      bs.consumedBits = bitCountLo;\n"~
"      bs.cache <<= bitCountLo;\n"~
"    }\n"~
"\n"~
"    decodedRice |= bitsLo;\n"~
"    decodedRice = (decodedRice>>1)^(~(decodedRice&0x01)+1);   /* <-- Ah, much faster! :) */\n"~
"    /*\n"~
"    if ((decodedRice&0x01)) {\n"~
"      decodedRice = ~(decodedRice>>1);\n"~
"    } else {\n"~
"      decodedRice = (decodedRice>>1);\n"~
"    }\n"~
"    */\n"~
"\n"~
"    /* In order to properly calculate the prediction when the bits per sample is >16 we need to do it using 64-bit arithmetic. We can assume this\n"~
"       is probably going to be slower on 32-bit systems so we'll do a more optimized 32-bit version when the bits per sample is low enough.*/\n"~
"    pSamplesOut[i] = (cast(int)decodedRice+"~predictionFunc~"(order, shift, coefficients, pSamplesOut+i));\n"~
"  }\n"~
"\n"~
"  return true;\n"~
"}\n";

mixin(DRFLAC__DECODE_SAMPLES_WITH_RESIDULE__RICE__PROC!("drflac__decode_samples_with_residual__rice_64", "drflac__calculate_prediction_64"));
mixin(DRFLAC__DECODE_SAMPLES_WITH_RESIDULE__RICE__PROC!("drflac__decode_samples_with_residual__rice_32", "drflac__calculate_prediction_32"));


// Reads and seeks past a string of residual values as Rice codes. The decoder should be sitting on the first bit of the Rice codes.
bool drflac__read_and_seek_residual__rice (drflac_bs* bs, uint count, ubyte riceParam) {
  assert(bs !is null);
  assert(count > 0);

  for (uint i = 0; i < count; ++i) {
    if (!drflac__read_and_seek_rice(bs, riceParam)) return false;
  }

  return true;
}

bool drflac__decode_samples_with_residual__unencoded (drflac_bs* bs, uint bitsPerSample, uint count, ubyte unencodedBitsPerSample, uint order, int shift, const short* coefficients, int* pSamplesOut) {
  assert(bs !is null);
  assert(count > 0);
  assert(unencodedBitsPerSample > 0 && unencodedBitsPerSample <= 32);
  assert(pSamplesOut !is null);

  for (uint i = 0; i < count; ++i) {
    if (!drflac__read_int32(bs, unencodedBitsPerSample, pSamplesOut+i)) return false;
    if (bitsPerSample > 16) {
      pSamplesOut[i] += drflac__calculate_prediction_64(order, shift, coefficients, pSamplesOut+i);
    } else {
      pSamplesOut[i] += drflac__calculate_prediction_32(order, shift, coefficients, pSamplesOut+i);
    }
  }

  return true;
}


// Reads and decodes the residual for the sub-frame the decoder is currently sitting on. This function should be called
// when the decoder is sitting at the very start of the RESIDUAL block. The first <order> residuals will be ignored. The
// <blockSize> and <order> parameters are used to determine how many residual values need to be decoded.
bool drflac__decode_samples_with_residual (drflac_bs* bs, uint bitsPerSample, uint blockSize, uint order, int shift, const short* coefficients, int* pDecodedSamples) {
  assert(bs !is null);
  assert(blockSize != 0);
  assert(pDecodedSamples !is null);       // <-- Should we allow null, in which case we just seek past the residual rather than do a full decode?

  ubyte residualMethod;
  if (!drflac__read_uint8(bs, 2, &residualMethod)) return false;

  if (residualMethod != DRFLAC_RESIDUAL_CODING_METHOD_PARTITIONED_RICE && residualMethod != DRFLAC_RESIDUAL_CODING_METHOD_PARTITIONED_RICE2) return false; // Unknown or unsupported residual coding method.

  // Ignore the first <order> values.
  pDecodedSamples += order;

  ubyte partitionOrder;
  if (!drflac__read_uint8(bs, 4, &partitionOrder)) return false;

  uint samplesInPartition = (blockSize/(1<<partitionOrder))-order;
  uint partitionsRemaining = (1<<partitionOrder);
  for (;;) {
    ubyte riceParam = 0;
    if (residualMethod == DRFLAC_RESIDUAL_CODING_METHOD_PARTITIONED_RICE) {
      if (!drflac__read_uint8(bs, 4, &riceParam)) return false;
      if (riceParam == 16) riceParam = 0xFF;
    } else if (residualMethod == DRFLAC_RESIDUAL_CODING_METHOD_PARTITIONED_RICE2) {
      if (!drflac__read_uint8(bs, 5, &riceParam)) return false;
      if (riceParam == 32) riceParam = 0xFF;
    }

    if (riceParam != 0xFF) {
      if (bitsPerSample > 16) {
        if (!drflac__decode_samples_with_residual__rice_64(bs, samplesInPartition, riceParam, order, shift, coefficients, pDecodedSamples)) return false;
      } else {
        if (!drflac__decode_samples_with_residual__rice_32(bs, samplesInPartition, riceParam, order, shift, coefficients, pDecodedSamples)) return false;
      }
    } else {
      ubyte unencodedBitsPerSample = 0;
      if (!drflac__read_uint8(bs, 5, &unencodedBitsPerSample)) return false;
      if (!drflac__decode_samples_with_residual__unencoded(bs, bitsPerSample, samplesInPartition, unencodedBitsPerSample, order, shift, coefficients, pDecodedSamples)) return false;
    }

    pDecodedSamples += samplesInPartition;

    if (partitionsRemaining == 1) break;

    partitionsRemaining -= 1;
    samplesInPartition = blockSize/(1<<partitionOrder);
  }

  return true;
}

// Reads and seeks past the residual for the sub-frame the decoder is currently sitting on. This function should be called
// when the decoder is sitting at the very start of the RESIDUAL block. The first <order> residuals will be set to 0. The
// <blockSize> and <order> parameters are used to determine how many residual values need to be decoded.
bool drflac__read_and_seek_residual (drflac_bs* bs, uint blockSize, uint order) {
  assert(bs !is null);
  assert(blockSize != 0);

  ubyte residualMethod;
  if (!drflac__read_uint8(bs, 2, &residualMethod)) return false;

  if (residualMethod != DRFLAC_RESIDUAL_CODING_METHOD_PARTITIONED_RICE && residualMethod != DRFLAC_RESIDUAL_CODING_METHOD_PARTITIONED_RICE2) return false; // Unknown or unsupported residual coding method.

  ubyte partitionOrder;
  if (!drflac__read_uint8(bs, 4, &partitionOrder)) return false;

  uint samplesInPartition = (blockSize/(1<<partitionOrder))-order;
  uint partitionsRemaining = (1<<partitionOrder);
  for (;;) {
    ubyte riceParam = 0;
    if (residualMethod == DRFLAC_RESIDUAL_CODING_METHOD_PARTITIONED_RICE) {
      if (!drflac__read_uint8(bs, 4, &riceParam)) return false;
      if (riceParam == 16) riceParam = 0xFF;
    } else if (residualMethod == DRFLAC_RESIDUAL_CODING_METHOD_PARTITIONED_RICE2) {
      if (!drflac__read_uint8(bs, 5, &riceParam)) return false;
      if (riceParam == 32) riceParam = 0xFF;
    }

    if (riceParam != 0xFF) {
      if (!drflac__read_and_seek_residual__rice(bs, samplesInPartition, riceParam)) return false;
    } else {
      ubyte unencodedBitsPerSample = 0;
      if (!drflac__read_uint8(bs, 5, &unencodedBitsPerSample)) return false;
      if (!drflac__seek_bits(bs, unencodedBitsPerSample*samplesInPartition)) return false;
    }

    if (partitionsRemaining == 1) break;

    partitionsRemaining -= 1;
    samplesInPartition = blockSize/(1<<partitionOrder);
  }

  return true;
}


bool drflac__decode_samples__constant (drflac_bs* bs, uint blockSize, uint bitsPerSample, int* pDecodedSamples) {
  // Only a single sample needs to be decoded here.
  int sample;
  if (!drflac__read_int32(bs, bitsPerSample, &sample)) return false;

  // We don't really need to expand this, but it does simplify the process of reading samples. If this becomes a performance issue (unlikely)
  // we'll want to look at a more efficient way.
  for (uint i = 0; i < blockSize; ++i) pDecodedSamples[i] = sample;

  return true;
}

bool drflac__decode_samples__verbatim (drflac_bs* bs, uint blockSize, uint bitsPerSample, int* pDecodedSamples) {
  for (uint i = 0; i < blockSize; ++i) {
    int sample;
    if (!drflac__read_int32(bs, bitsPerSample, &sample)) return false;
    pDecodedSamples[i] = sample;
  }
  return true;
}

bool drflac__decode_samples__fixed (drflac_bs* bs, uint blockSize, uint bitsPerSample, ubyte lpcOrder, int* pDecodedSamples) {
  static immutable short[4][5] lpcCoefficientsTable = [
      [0,  0, 0,  0],
      [1,  0, 0,  0],
      [2, -1, 0,  0],
      [3, -3, 1,  0],
      [4, -6, 4, -1]
  ];

  // Warm up samples and coefficients.
  for (uint i = 0; i < lpcOrder; ++i) {
    int sample;
    if (!drflac__read_int32(bs, bitsPerSample, &sample)) return false;
    pDecodedSamples[i] = sample;
  }

  if (!drflac__decode_samples_with_residual(bs, bitsPerSample, blockSize, lpcOrder, 0, lpcCoefficientsTable.ptr[lpcOrder].ptr, pDecodedSamples)) return false;

  return true;
}

bool drflac__decode_samples__lpc (drflac_bs* bs, uint blockSize, uint bitsPerSample, ubyte lpcOrder, int* pDecodedSamples) {
  // Warm up samples.
  for (ubyte i = 0; i < lpcOrder; ++i) {
    int sample;
    if (!drflac__read_int32(bs, bitsPerSample, &sample)) return false;
    pDecodedSamples[i] = sample;
  }

  ubyte lpcPrecision;
  if (!drflac__read_uint8(bs, 4, &lpcPrecision)) return false;
  if (lpcPrecision == 15) return false;    // Invalid.
  lpcPrecision += 1;

  byte lpcShift;
  if (!drflac__read_int8(bs, 5, &lpcShift)) return false;

  short[32] coefficients;
  for (ubyte i = 0; i < lpcOrder; ++i) {
    if (!drflac__read_int16(bs, lpcPrecision, coefficients.ptr+i)) return false;
  }

  if (!drflac__decode_samples_with_residual(bs, bitsPerSample, blockSize, lpcOrder, lpcShift, coefficients.ptr, pDecodedSamples)) return false;

  return true;
}


bool drflac__read_next_frame_header (drflac_bs* bs, ubyte streaminfoBitsPerSample, drflac_frame_header* header) {
  assert(bs !is null);
  assert(header !is null);

  // At the moment the sync code is as a form of basic validation. The CRC is stored, but is unused at the moment. This
  // should probably be handled better in the future.

  static immutable uint[12] sampleRateTable  = [0, 88200, 176400, 192000, 8000, 16000, 22050, 24000, 32000, 44100, 48000, 96000];
  static immutable ubyte[8] bitsPerSampleTable = [0, 8, 12, cast(ubyte)-1, 16, 20, 24, cast(ubyte)-1];   // -1 = reserved.

  ushort syncCode = 0;
  if (!drflac__read_uint16(bs, 14, &syncCode)) return false;

  if (syncCode != 0x3FFE) return false; // TODO: Try and recover by attempting to seek to and read the next frame?

  ubyte reserved;
  if (!drflac__read_uint8(bs, 1, &reserved)) return false;

  ubyte blockingStrategy = 0;
  if (!drflac__read_uint8(bs, 1, &blockingStrategy)) return false;

  ubyte blockSize = 0;
  if (!drflac__read_uint8(bs, 4, &blockSize)) return false;

  ubyte sampleRate = 0;
  if (!drflac__read_uint8(bs, 4, &sampleRate)) return false;

  ubyte channelAssignment = 0;
  if (!drflac__read_uint8(bs, 4, &channelAssignment)) return false;

  ubyte bitsPerSample = 0;
  if (!drflac__read_uint8(bs, 3, &bitsPerSample)) return false;

  if (!drflac__read_uint8(bs, 1, &reserved)) return false;

  bool isVariableBlockSize = blockingStrategy == 1;
  if (isVariableBlockSize) {
    ulong sampleNumber;
    if (!drflac__read_utf8_coded_number(bs, &sampleNumber)) return false;
    header.frameNumber  = 0;
    header.sampleNumber = sampleNumber;
  } else {
    ulong frameNumber = 0;
    if (!drflac__read_utf8_coded_number(bs, &frameNumber)) return false;
    header.frameNumber  = cast(uint)frameNumber;   // <-- Safe cast.
    header.sampleNumber = 0;
  }

  if (blockSize == 1) {
    header.blockSize = 192;
  } else if (blockSize >= 2 && blockSize <= 5) {
    header.blockSize = cast(ushort)(576*(1<<(blockSize-2))); //k8
  } else if (blockSize == 6) {
    if (!drflac__read_uint16(bs, 8, &header.blockSize)) return false;
    header.blockSize += 1;
  } else if (blockSize == 7) {
    if (!drflac__read_uint16(bs, 16, &header.blockSize)) return false;
    header.blockSize += 1;
  } else {
    header.blockSize = cast(ushort)(256*(1<<(blockSize-8))); //k8
  }

  if (sampleRate <= 11) {
    header.sampleRate = sampleRateTable.ptr[sampleRate];
  } else if (sampleRate == 12) {
    if (!drflac__read_uint32(bs, 8, &header.sampleRate)) return false;
    header.sampleRate *= 1000;
  } else if (sampleRate == 13) {
    if (!drflac__read_uint32(bs, 16, &header.sampleRate)) return false;
  } else if (sampleRate == 14) {
    if (!drflac__read_uint32(bs, 16, &header.sampleRate)) return false;
    header.sampleRate *= 10;
  } else {
    return false;  // Invalid.
  }

  header.channelAssignment = channelAssignment;

  header.bitsPerSample = bitsPerSampleTable.ptr[bitsPerSample];
  if (header.bitsPerSample == 0) header.bitsPerSample = streaminfoBitsPerSample;

  if (drflac__read_uint8(bs, 8, &header.crc8) != 1) return false;

  return true;
}

bool drflac__read_subframe_header (drflac_bs* bs, drflac_subframe* pSubframe) {
  ubyte header;
  if (!drflac__read_uint8(bs, 8, &header)) return false;

  // First bit should always be 0.
  if ((header&0x80) != 0) return false;

  int type = (header&0x7E)>>1;
  if (type == 0) {
    pSubframe.subframeType = DRFLAC_SUBFRAME_CONSTANT;
  } else if (type == 1) {
    pSubframe.subframeType = DRFLAC_SUBFRAME_VERBATIM;
  } else {
    if ((type&0x20) != 0) {
      pSubframe.subframeType = DRFLAC_SUBFRAME_LPC;
      pSubframe.lpcOrder = (type&0x1F)+1;
    } else if ((type&0x08) != 0) {
      pSubframe.subframeType = DRFLAC_SUBFRAME_FIXED;
      pSubframe.lpcOrder = (type&0x07);
      if (pSubframe.lpcOrder > 4) {
        pSubframe.subframeType = DRFLAC_SUBFRAME_RESERVED;
        pSubframe.lpcOrder = 0;
      }
    } else {
      pSubframe.subframeType = DRFLAC_SUBFRAME_RESERVED;
    }
  }

  if (pSubframe.subframeType == DRFLAC_SUBFRAME_RESERVED) return false;

  // Wasted bits per sample.
  pSubframe.wastedBitsPerSample = 0;
  if ((header&0x01) == 1) {
    uint wastedBitsPerSample;
    if (!drflac__seek_past_next_set_bit(bs, &wastedBitsPerSample)) return false;
    pSubframe.wastedBitsPerSample = cast(ubyte)(cast(ubyte)wastedBitsPerSample+1); // k8
  }

  return true;
}

bool drflac__decode_subframe (drflac_bs* bs, drflac_frame* frame, int subframeIndex, int* pDecodedSamplesOut) {
  assert(bs !is null);
  assert(frame !is null);

  drflac_subframe* pSubframe = frame.subframes.ptr+subframeIndex;
  if (!drflac__read_subframe_header(bs, pSubframe)) return false;

  // Side channels require an extra bit per sample. Took a while to figure that one out...
  pSubframe.bitsPerSample = frame.header.bitsPerSample;
  if ((frame.header.channelAssignment == DRFLAC_CHANNEL_ASSIGNMENT_LEFT_SIDE || frame.header.channelAssignment == DRFLAC_CHANNEL_ASSIGNMENT_MID_SIDE) && subframeIndex == 1) {
    pSubframe.bitsPerSample += 1;
  } else if (frame.header.channelAssignment == DRFLAC_CHANNEL_ASSIGNMENT_RIGHT_SIDE && subframeIndex == 0) {
    pSubframe.bitsPerSample += 1;
  }

  // Need to handle wasted bits per sample.
  pSubframe.bitsPerSample -= pSubframe.wastedBitsPerSample;
  pSubframe.pDecodedSamples = pDecodedSamplesOut;

  switch (pSubframe.subframeType) {
    case DRFLAC_SUBFRAME_CONSTANT: drflac__decode_samples__constant(bs, frame.header.blockSize, pSubframe.bitsPerSample, pSubframe.pDecodedSamples); break;
    case DRFLAC_SUBFRAME_VERBATIM: drflac__decode_samples__verbatim(bs, frame.header.blockSize, pSubframe.bitsPerSample, pSubframe.pDecodedSamples); break;
    case DRFLAC_SUBFRAME_FIXED: drflac__decode_samples__fixed(bs, frame.header.blockSize, pSubframe.bitsPerSample, pSubframe.lpcOrder, pSubframe.pDecodedSamples); break;
    case DRFLAC_SUBFRAME_LPC: drflac__decode_samples__lpc(bs, frame.header.blockSize, pSubframe.bitsPerSample, pSubframe.lpcOrder, pSubframe.pDecodedSamples); break;
    default: return false;
  }

  return true;
}

bool drflac__seek_subframe (drflac_bs* bs, drflac_frame* frame, int subframeIndex) {
  assert(bs !is null);
  assert(frame !is null);

  drflac_subframe* pSubframe = frame.subframes.ptr+subframeIndex;
  if (!drflac__read_subframe_header(bs, pSubframe)) return false;

  // Side channels require an extra bit per sample. Took a while to figure that one out...
  pSubframe.bitsPerSample = frame.header.bitsPerSample;
  if ((frame.header.channelAssignment == DRFLAC_CHANNEL_ASSIGNMENT_LEFT_SIDE || frame.header.channelAssignment == DRFLAC_CHANNEL_ASSIGNMENT_MID_SIDE) && subframeIndex == 1) {
    pSubframe.bitsPerSample += 1;
  } else if (frame.header.channelAssignment == DRFLAC_CHANNEL_ASSIGNMENT_RIGHT_SIDE && subframeIndex == 0) {
    pSubframe.bitsPerSample += 1;
  }

  // Need to handle wasted bits per sample.
  pSubframe.bitsPerSample -= pSubframe.wastedBitsPerSample;
  pSubframe.pDecodedSamples = null;
  //pSubframe.pDecodedSamples = pFlac.pDecodedSamples+(pFlac.currentFrame.header.blockSize*subframeIndex);

  switch (pSubframe.subframeType) {
    case DRFLAC_SUBFRAME_CONSTANT:
      if (!drflac__seek_bits(bs, pSubframe.bitsPerSample)) return false;
      break;

    case DRFLAC_SUBFRAME_VERBATIM:
      uint bitsToSeek = frame.header.blockSize*pSubframe.bitsPerSample;
      if (!drflac__seek_bits(bs, bitsToSeek)) return false;
      break;

    case DRFLAC_SUBFRAME_FIXED:
      uint bitsToSeek = pSubframe.lpcOrder*pSubframe.bitsPerSample;
      if (!drflac__seek_bits(bs, bitsToSeek)) return false;
      if (!drflac__read_and_seek_residual(bs, frame.header.blockSize, pSubframe.lpcOrder)) return false;
      break;

    case DRFLAC_SUBFRAME_LPC:
      uint bitsToSeek = pSubframe.lpcOrder*pSubframe.bitsPerSample;
      if (!drflac__seek_bits(bs, bitsToSeek)) return false;
      ubyte lpcPrecision;
      if (!drflac__read_uint8(bs, 4, &lpcPrecision)) return false;
      if (lpcPrecision == 15) return false;    // Invalid.
      lpcPrecision += 1;
      bitsToSeek = (pSubframe.lpcOrder*lpcPrecision)+5;    // +5 for shift.
      if (!drflac__seek_bits(bs, bitsToSeek)) return false;
      if (!drflac__read_and_seek_residual(bs, frame.header.blockSize, pSubframe.lpcOrder)) return false;
      break;

    default: return false;
  }

  return true;
}


ubyte drflac__get_channel_count_from_channel_assignment (byte channelAssignment) {
  assert(channelAssignment <= 10);
  static immutable ubyte[11] lookup = [1, 2, 3, 4, 5, 6, 7, 8, 2, 2, 2];
  return lookup.ptr[channelAssignment];
}

bool drflac__decode_frame (drflac* pFlac) {
  import core.stdc.string : memset;
  // This function should be called while the stream is sitting on the first byte after the frame header.
  memset(pFlac.currentFrame.subframes.ptr, 0, (pFlac.currentFrame.subframes).sizeof);

  int channelCount = drflac__get_channel_count_from_channel_assignment(pFlac.currentFrame.header.channelAssignment);
  for (int i = 0; i < channelCount; ++i) {
    if (!drflac__decode_subframe(&pFlac.bs, &pFlac.currentFrame, i, pFlac.pDecodedSamples+(pFlac.currentFrame.header.blockSize*i))) return false;
  }

  // At the end of the frame sits the padding and CRC. We don't use these so we can just seek past.
  if (!drflac__seek_bits(&pFlac.bs, (mixin(DRFLAC_CACHE_L1_BITS_REMAINING!"(&pFlac.bs)")&7)+16)) return false;

  pFlac.currentFrame.samplesRemaining = pFlac.currentFrame.header.blockSize*channelCount;

  return true;
}

bool drflac__seek_frame (drflac* pFlac) {
  int channelCount = drflac__get_channel_count_from_channel_assignment(pFlac.currentFrame.header.channelAssignment);
  for (int i = 0; i < channelCount; ++i) {
    if (!drflac__seek_subframe(&pFlac.bs, &pFlac.currentFrame, i)) return false;
  }
  // Padding and CRC.
  return drflac__seek_bits(&pFlac.bs, (mixin(DRFLAC_CACHE_L1_BITS_REMAINING!"(&pFlac.bs)")&7)+16);
}

bool drflac__read_and_decode_next_frame (drflac* pFlac) {
  assert(pFlac !is null);

  if (!drflac__read_next_frame_header(&pFlac.bs, pFlac.bitsPerSample, &pFlac.currentFrame.header)) return false;

  return drflac__decode_frame(pFlac);
}


void drflac__get_current_frame_sample_range (drflac* pFlac, ulong* pFirstSampleInFrameOut, ulong* pLastSampleInFrameOut) {
  assert(pFlac !is null);

  uint channelCount = drflac__get_channel_count_from_channel_assignment(pFlac.currentFrame.header.channelAssignment);

  ulong firstSampleInFrame = pFlac.currentFrame.header.sampleNumber;
  if (firstSampleInFrame == 0) firstSampleInFrame = pFlac.currentFrame.header.frameNumber*pFlac.maxBlockSize*channelCount;

  ulong lastSampleInFrame = firstSampleInFrame+(pFlac.currentFrame.header.blockSize*channelCount);
  if (lastSampleInFrame > 0) lastSampleInFrame -= 1; // Needs to be zero based.

  if (pFirstSampleInFrameOut) *pFirstSampleInFrameOut = firstSampleInFrame;
  if (pLastSampleInFrameOut) *pLastSampleInFrameOut = lastSampleInFrame;
}

bool drflac__seek_to_first_frame (drflac* pFlac) {
  import core.stdc.string : memset;
  assert(pFlac !is null);

  bool result = drflac__seek_to_byte(&pFlac.bs, pFlac.firstFramePos);

  memset(&pFlac.currentFrame, 0, (pFlac.currentFrame).sizeof);
  return result;
}

bool drflac__seek_to_next_frame (drflac* pFlac) {
  // This function should only ever be called while the decoder is sitting on the first byte past the FRAME_HEADER section.
  assert(pFlac !is null);
  return drflac__seek_frame(pFlac);
}

bool drflac__seek_to_frame_containing_sample (drflac* pFlac, ulong sampleIndex) {
  assert(pFlac !is null);

  if (!drflac__seek_to_first_frame(pFlac)) return false;

  ulong firstSampleInFrame = 0;
  ulong lastSampleInFrame = 0;
  for (;;) {
    // We need to read the frame's header in order to determine the range of samples it contains.
    if (!drflac__read_next_frame_header(&pFlac.bs, pFlac.bitsPerSample, &pFlac.currentFrame.header)) return false;
    drflac__get_current_frame_sample_range(pFlac, &firstSampleInFrame, &lastSampleInFrame);
    if (sampleIndex >= firstSampleInFrame && sampleIndex <= lastSampleInFrame) break;  // The sample is in this frame.
    if (!drflac__seek_to_next_frame(pFlac)) return false;
  }

  // If we get here we should be right at the start of the frame containing the sample.
  return true;
}

public bool drflac__seek_to_sample__brute_force (drflac* pFlac, ulong sampleIndex) {
  if (!drflac__seek_to_frame_containing_sample(pFlac, sampleIndex)) return false;

  // At this point we should be sitting on the first byte of the frame containing the sample. We need to decode every sample up to (but
  // not including) the sample we're seeking to.
  ulong firstSampleInFrame = 0;
  drflac__get_current_frame_sample_range(pFlac, &firstSampleInFrame, null);

  assert(firstSampleInFrame <= sampleIndex);
  size_t samplesToDecode = cast(size_t)(sampleIndex-firstSampleInFrame);    // <-- Safe cast because the maximum number of samples in a frame is 65535.
  if (samplesToDecode == 0) return true;

  // At this point we are just sitting on the byte after the frame header. We need to decode the frame before reading anything from it.
  if (!drflac__decode_frame(pFlac)) return false;

  return drflac_read_s32(pFlac, samplesToDecode, null) != 0;
}


bool drflac__seek_to_sample__seek_table (drflac* pFlac, ulong sampleIndex) {
  assert(pFlac !is null);

  if (pFlac.seektablePos == 0) return false;

  if (!drflac__seek_to_byte(&pFlac.bs, pFlac.seektablePos)) return false;

  // The number of seek points is derived from the size of the SEEKTABLE block.
  uint seekpointCount = pFlac.seektableSize/18;   // 18 = the size of each seek point.
  if (seekpointCount == 0) return false;   // Would this ever happen?

  drflac_seekpoint closestSeekpoint = {0};

  uint seekpointsRemaining = seekpointCount;
  while (seekpointsRemaining > 0) {
    drflac_seekpoint seekpoint;
    if (!drflac__read_uint64(&pFlac.bs, 64, &seekpoint.firstSample)) break;
    if (!drflac__read_uint64(&pFlac.bs, 64, &seekpoint.frameOffset)) break;
    if (!drflac__read_uint16(&pFlac.bs, 16, &seekpoint.sampleCount)) break;
    if (seekpoint.firstSample*pFlac.channels > sampleIndex) break;
    closestSeekpoint = seekpoint;
    seekpointsRemaining -= 1;
  }

  // At this point we should have found the seekpoint closest to our sample. We need to seek to it using basically the same
  // technique as we use with the brute force method.
  if (!drflac__seek_to_byte(&pFlac.bs, pFlac.firstFramePos+closestSeekpoint.frameOffset)) return false;

  ulong firstSampleInFrame = 0;
  ulong lastSampleInFrame = 0;
  for (;;) {
    // We need to read the frame's header in order to determine the range of samples it contains.
    if (!drflac__read_next_frame_header(&pFlac.bs, pFlac.bitsPerSample, &pFlac.currentFrame.header)) return false;
    drflac__get_current_frame_sample_range(pFlac, &firstSampleInFrame, &lastSampleInFrame);
    if (sampleIndex >= firstSampleInFrame && sampleIndex <= lastSampleInFrame) break;  // The sample is in this frame.
    if (!drflac__seek_to_next_frame(pFlac)) return false;
  }

  assert(firstSampleInFrame <= sampleIndex);

  // At this point we are just sitting on the byte after the frame header. We need to decode the frame before reading anything from it.
  if (!drflac__decode_frame(pFlac)) return false;

  size_t samplesToDecode = cast(size_t)(sampleIndex-firstSampleInFrame);    // <-- Safe cast because the maximum number of samples in a frame is 65535.
  return drflac_read_s32(pFlac, samplesToDecode, null) == samplesToDecode;
}


//#ifndef DR_FLAC_NO_OGG
struct drflac_ogg_page_header {
  ubyte[4] capturePattern;  // Should be "OggS"
  ubyte structureVersion;   // Always 0.
  ubyte headerType;
  ulong granulePosition;
  uint serialNumber;
  uint sequenceNumber;
  uint checksum;
  ubyte segmentCount;
  ubyte[255] segmentTable;
}
//#endif

struct drflac_init_info {
  //drflac_read_proc onRead;
  //drflac_seek_proc onSeek;
  //void* pUserData;
  ReadStruct rs;
  //drflac_meta_proc onMeta;
  //void* pUserDataMD;
  drflac_container container;
  uint sampleRate;
  ubyte  channels;
  ubyte  bitsPerSample;
  ulong totalSampleCount;
  ushort maxBlockSize;
  ulong runningFilePos;
  bool hasMetadataBlocks;

//#ifndef DR_FLAC_NO_OGG
  uint oggSerial;
  ulong oggFirstBytePos;
  drflac_ogg_page_header oggBosHeader;
//#endif
}

private struct ReadStruct {
@nogc:	
  drflac_read_proc onReadCB;
  drflac_seek_proc onSeekCB;
  void* pUserData;

  size_t read (void* pBufferOut, size_t bytesToRead) nothrow {
    auto b = cast(ubyte*)pBufferOut;
    auto res = 0;
    try {
      while (bytesToRead > 0) {
        size_t rd = 0;
        if (onReadCB !is null) {
          rd = onReadCB(pUserData, b, bytesToRead);
        } else {
         }
        if (rd == 0) break;
        b += rd;
        res += rd;
        bytesToRead -= rd;
      }
      return res;
    } catch (Exception e) {
      return 0;
    }
  }

  bool seek (int offset, drflac_seek_origin origin) nothrow {
    try {
      if (onSeekCB !is null) {
        return onSeekCB(pUserData, offset, origin);
      } else {
      }
      return false;
    } catch (Exception e) {
      return 0;
    }
  }
}


void drflac__decode_block_header (uint blockHeader, ubyte* isLastBlock, ubyte* blockType, uint* blockSize) {
  blockHeader = drflac__be2host_32(blockHeader);
  *isLastBlock = (blockHeader&(0x01<<31))>>31;
  *blockType   = (blockHeader&(0x7F<<24))>>24;
  *blockSize   = (blockHeader&0xFFFFFF);
}

bool drflac__read_and_decode_block_header (ref ReadStruct rs, ubyte* isLastBlock, ubyte* blockType, uint* blockSize) {
  uint blockHeader;
  if (rs.read(&blockHeader, 4) != 4) return false;
  drflac__decode_block_header(blockHeader, isLastBlock, blockType, blockSize);
  return true;
}

bool drflac__read_streaminfo (ref ReadStruct rs, drflac_streaminfo* pStreamInfo) {
  import core.stdc.string : memcpy;
  // min/max block size.
  uint blockSizes;
  if (rs.read(&blockSizes, 4) != 4) return false;
  // min/max frame size.
  ulong frameSizes = 0;
  if (rs.read(&frameSizes, 6) != 6) return false;
  // Sample rate, channels, bits per sample and total sample count.
  ulong importantProps;
  if (rs.read(&importantProps, 8) != 8) return false;
  // MD5
  ubyte[16] md5;
  if (rs.read(md5.ptr, md5.sizeof) != md5.sizeof) return false;

  blockSizes     = drflac__be2host_32(blockSizes);
  frameSizes     = drflac__be2host_64(frameSizes);
  importantProps = drflac__be2host_64(importantProps);

  pStreamInfo.minBlockSize     = (blockSizes&0xFFFF0000)>>16;
  pStreamInfo.maxBlockSize     = blockSizes&0x0000FFFF;
  pStreamInfo.minFrameSize     = cast(uint)((frameSizes&0xFFFFFF0000000000UL)>>40);
  pStreamInfo.maxFrameSize     = cast(uint)((frameSizes&0x000000FFFFFF0000UL)>>16);
  pStreamInfo.sampleRate       = cast(uint)((importantProps&0xFFFFF00000000000UL)>>44);
  pStreamInfo.channels         = cast(ubyte )((importantProps&0x00000E0000000000UL)>>41)+1;
  pStreamInfo.bitsPerSample    = cast(ubyte )((importantProps&0x000001F000000000UL)>>36)+1;
  pStreamInfo.totalSampleCount = (importantProps&0x0000000FFFFFFFFFUL)*pStreamInfo.channels;
  memcpy(pStreamInfo.md5.ptr, md5.ptr, md5.sizeof);

  return true;
}

bool drflac__read_and_decode_metadata (drflac* pFlac, scope drflac_meta_proc onMeta, void* pUserDataMD) {
  import core.stdc.stdlib : malloc, free;
  assert(pFlac !is null);

  // We want to keep track of the byte position in the stream of the seektable. At the time of calling this function we know that
  // we'll be sitting on byte 42.
  ulong runningFilePos = 42;
  ulong seektablePos  = 0;
  uint seektableSize = 0;

  for (;;) {
    ubyte isLastBlock = 0;
    ubyte blockType;
    uint blockSize;
    if (!drflac__read_and_decode_block_header(pFlac.bs.rs, &isLastBlock, &blockType, &blockSize)) return false;
    runningFilePos += 4;

    drflac_metadata metadata;
    metadata.type = blockType;
    metadata.pRawData = null;
    metadata.rawDataSize = 0;

    switch (blockType) {
      case DRFLAC_METADATA_BLOCK_TYPE_APPLICATION:
        if (onMeta) {
            void* pRawData = malloc(blockSize);
            if (pRawData is null) return false;
            scope(exit) free(pRawData);

            if (pFlac.bs.rs.read(pRawData, blockSize) != blockSize) return false;

            metadata.pRawData = pRawData;
            metadata.rawDataSize = blockSize;
            metadata.data.application.id       = drflac__be2host_32(*cast(uint*)pRawData);
            metadata.data.application.pData    = cast(const(void)*)(cast(ubyte*)pRawData+uint.sizeof);
            metadata.data.application.dataSize = blockSize-cast(uint)uint.sizeof;
            try { onMeta(pUserDataMD, &metadata); } catch (Exception e) { return false; }
        }
        break;

      case DRFLAC_METADATA_BLOCK_TYPE_SEEKTABLE:
        seektablePos  = runningFilePos;
        seektableSize = blockSize;

        if (onMeta) {
          void* pRawData = malloc(blockSize);
          if (pRawData is null) return false;
          scope(exit) free(pRawData);

          if (pFlac.bs.rs.read(pRawData, blockSize) != blockSize) return false;

          metadata.pRawData = pRawData;
          metadata.rawDataSize = blockSize;
          metadata.data.seektable.seekpointCount = blockSize/(drflac_seekpoint).sizeof;
          metadata.data.seektable.pSeekpoints = cast(const(drflac_seekpoint)*)pRawData;

          // Endian swap.
          for (uint iSeekpoint = 0; iSeekpoint < metadata.data.seektable.seekpointCount; ++iSeekpoint) {
            drflac_seekpoint* pSeekpoint = cast(drflac_seekpoint*)pRawData+iSeekpoint;
            pSeekpoint.firstSample = drflac__be2host_64(pSeekpoint.firstSample);
            pSeekpoint.frameOffset = drflac__be2host_64(pSeekpoint.frameOffset);
            pSeekpoint.sampleCount = drflac__be2host_16(pSeekpoint.sampleCount);
          }

          try { onMeta(pUserDataMD, &metadata); } catch (Exception e) { return false; }
        }
        break;

      case DRFLAC_METADATA_BLOCK_TYPE_VORBIS_COMMENT:
        if (onMeta) {
          void* pRawData = malloc(blockSize);
          if (pRawData is null) return false;
          scope(exit) free(pRawData);

          if (pFlac.bs.rs.read(pRawData, blockSize) != blockSize) return false;

          metadata.pRawData = pRawData;
          metadata.rawDataSize = blockSize;

          const(char)* pRunningData = cast(const(char)*)pRawData;
          metadata.data.vorbis_comment.vendorLength = drflac__le2host_32(*cast(uint*)pRunningData); pRunningData += 4;
          metadata.data.vorbis_comment.vendor       = pRunningData;                                 pRunningData += metadata.data.vorbis_comment.vendorLength;
          metadata.data.vorbis_comment.commentCount = drflac__le2host_32(*cast(uint*)pRunningData); pRunningData += 4;
          metadata.data.vorbis_comment.comments     = pRunningData;
          try { onMeta(pUserDataMD, &metadata); } catch (Exception e) { return false; }
        }
        break;

      case DRFLAC_METADATA_BLOCK_TYPE_CUESHEET:
        if (onMeta) {
          import core.stdc.string : memcpy;
          void* pRawData = malloc(blockSize);
          if (pRawData is null) return false;
          scope(exit) free(pRawData);

          if (pFlac.bs.rs.read(pRawData, blockSize) != blockSize) return false;

          metadata.pRawData = pRawData;
          metadata.rawDataSize = blockSize;

          const(char)* pRunningData = cast(const(char)*)pRawData;
          memcpy(metadata.data.cuesheet.catalog.ptr, pRunningData, 128);                           pRunningData += 128;
          metadata.data.cuesheet.leadInSampleCount = drflac__be2host_64(*cast(ulong*)pRunningData);pRunningData += 4;
          metadata.data.cuesheet.isCD              = ((pRunningData[0]&0x80)>>7) != 0;         pRunningData += 259;
          metadata.data.cuesheet.trackCount        = pRunningData[0];                              pRunningData += 1;
          metadata.data.cuesheet.pTrackData        = cast(const(ubyte)*)pRunningData;
          try { onMeta(pUserDataMD, &metadata); } catch (Exception e) { return false; }
        }
        break;

      case DRFLAC_METADATA_BLOCK_TYPE_PICTURE:
        if (onMeta) {
          void* pRawData = malloc(blockSize);
          if (pRawData is null) return false;
          scope(exit) free(pRawData);

          if (pFlac.bs.rs.read(pRawData, blockSize) != blockSize) return false;

          metadata.pRawData = pRawData;
          metadata.rawDataSize = blockSize;

          const(char)* pRunningData = cast(const(char)*)pRawData;
          metadata.data.picture.type              = drflac__be2host_32(*cast(uint*)pRunningData); pRunningData += 4;
          metadata.data.picture.mimeLength        = drflac__be2host_32(*cast(uint*)pRunningData); pRunningData += 4;
          metadata.data.picture.mime              = pRunningData;                                 pRunningData += metadata.data.picture.mimeLength;
          metadata.data.picture.descriptionLength = drflac__be2host_32(*cast(uint*)pRunningData); pRunningData += 4;
          metadata.data.picture.description       = pRunningData;
          metadata.data.picture.width             = drflac__be2host_32(*cast(uint*)pRunningData); pRunningData += 4;
          metadata.data.picture.height            = drflac__be2host_32(*cast(uint*)pRunningData); pRunningData += 4;
          metadata.data.picture.colorDepth        = drflac__be2host_32(*cast(uint*)pRunningData); pRunningData += 4;
          metadata.data.picture.indexColorCount   = drflac__be2host_32(*cast(uint*)pRunningData); pRunningData += 4;
          metadata.data.picture.pictureDataSize   = drflac__be2host_32(*cast(uint*)pRunningData); pRunningData += 4;
          metadata.data.picture.pPictureData      = cast(const(ubyte)*)pRunningData;
          try { onMeta(pUserDataMD, &metadata); } catch (Exception e) { return false; }
        }
        break;

      case DRFLAC_METADATA_BLOCK_TYPE_PADDING:
        if (onMeta) {
          metadata.data.padding.unused = 0;
          // Padding doesn't have anything meaningful in it, so just skip over it.
          if (!pFlac.bs.rs.seek(blockSize, drflac_seek_origin_current)) return false;
          //onMeta(pUserDataMD, &metadata);
        }
        break;

      case DRFLAC_METADATA_BLOCK_TYPE_INVALID:
        // Invalid chunk. Just skip over this one.
        if (onMeta) {
          if (!pFlac.bs.rs.seek(blockSize, drflac_seek_origin_current)) return false;
        }
        goto default;

      default:
        // It's an unknown chunk, but not necessarily invalid. There's a chance more metadata blocks might be defined later on, so we
        // can at the very least report the chunk to the application and let it look at the raw data.
        if (onMeta) {
          void* pRawData = malloc(blockSize);
          if (pRawData is null) return false;
          scope(exit) free(pRawData);

          if (pFlac.bs.rs.read(pRawData, blockSize) != blockSize) return false;

          metadata.pRawData = pRawData;
          metadata.rawDataSize = blockSize;
          try { onMeta(pUserDataMD, &metadata); } catch (Exception e) { return false; }
        }
        break;
    }

    // If we're not handling metadata, just skip over the block. If we are, it will have been handled earlier in the switch statement above.
    if (onMeta is null) {
      if (!pFlac.bs.rs.seek(blockSize, drflac_seek_origin_current)) return false;
    }

    runningFilePos += blockSize;
    if (isLastBlock) break;
  }

  pFlac.seektablePos = seektablePos;
  pFlac.seektableSize = seektableSize;
  pFlac.firstFramePos = runningFilePos;

  return true;
}

bool drflac__init_private__native (drflac_init_info* pInit, ref ReadStruct rs, scope drflac_meta_proc onMeta, void* pUserDataMD) {
  // Pre: The bit stream should be sitting just past the 4-byte id header.

  pInit.container = drflac_container_native;

  // The first metadata block should be the STREAMINFO block.
  ubyte isLastBlock;
  ubyte blockType;
  uint blockSize;
  if (!drflac__read_and_decode_block_header(rs, &isLastBlock, &blockType, &blockSize)) return false;

  if (blockType != DRFLAC_METADATA_BLOCK_TYPE_STREAMINFO || blockSize != 34) return false;    // Invalid block type. First block must be the STREAMINFO block.

  drflac_streaminfo streaminfo;
  if (!drflac__read_streaminfo(rs, &streaminfo)) return false;

  pInit.sampleRate       = streaminfo.sampleRate;
  pInit.channels         = streaminfo.channels;
  pInit.bitsPerSample    = streaminfo.bitsPerSample;
  pInit.totalSampleCount = streaminfo.totalSampleCount;
  pInit.maxBlockSize     = streaminfo.maxBlockSize;    // Don't care about the min block size - only the max (used for determining the size of the memory allocation).

  if (onMeta !is null) {
    drflac_metadata metadata;
    metadata.type = DRFLAC_METADATA_BLOCK_TYPE_STREAMINFO;
    metadata.pRawData = null;
    metadata.rawDataSize = 0;
    metadata.data.streaminfo = streaminfo;
    try { onMeta(pUserDataMD, &metadata); } catch (Exception e) { return false; }
  }

  pInit.hasMetadataBlocks = !isLastBlock;
  return true;
}

//#ifndef DR_FLAC_NO_OGG
bool drflac_ogg__is_capture_pattern (const(ubyte)* pattern/*[4]*/) {
  return pattern[0] == 'O' && pattern[1] == 'g' && pattern[2] == 'g' && pattern[3] == 'S';
}

uint drflac_ogg__get_page_header_size (drflac_ogg_page_header* pHeader) {
  return 27+pHeader.segmentCount;
}

uint drflac_ogg__get_page_body_size (drflac_ogg_page_header* pHeader) {
  uint pageBodySize = 0;
  for (int i = 0; i < pHeader.segmentCount; ++i) pageBodySize += pHeader.segmentTable.ptr[i];
  return pageBodySize;
}

bool drflac_ogg__read_page_header_after_capture_pattern (ref ReadStruct rs, drflac_ogg_page_header* pHeader, uint* pHeaderSize) {
  if (rs.read(&pHeader.structureVersion, 1) != 1 || pHeader.structureVersion != 0) return false;   // Unknown structure version. Possibly corrupt stream.
  if (rs.read(&pHeader.headerType, 1) != 1) return false;
  if (rs.read(&pHeader.granulePosition, 8) != 8) return false;
  if (rs.read(&pHeader.serialNumber, 4) != 4) return false;
  if (rs.read(&pHeader.sequenceNumber, 4) != 4) return false;
  if (rs.read(&pHeader.checksum, 4) != 4) return false;
  if (rs.read(&pHeader.segmentCount, 1) != 1 || pHeader.segmentCount == 0) return false;   // Should not have a segment count of 0.
  if (rs.read(&pHeader.segmentTable, pHeader.segmentCount) != pHeader.segmentCount) return false;
  if (pHeaderSize) *pHeaderSize = (27+pHeader.segmentCount);
  return true;
}

bool drflac_ogg__read_page_header (ref ReadStruct rs, drflac_ogg_page_header* pHeader, uint* pHeaderSize) {
  ubyte[4] id;
  if (rs.read(id.ptr, 4) != 4) return false;
  if (id.ptr[0] != 'O' || id.ptr[1] != 'g' || id.ptr[2] != 'g' || id.ptr[3] != 'S') return false;
  return drflac_ogg__read_page_header_after_capture_pattern(rs, pHeader, pHeaderSize);
}


// The main part of the Ogg encapsulation is the conversion from the physical Ogg bitstream to the native FLAC bitstream. It works
// in three general stages: Ogg Physical Bitstream . Ogg/FLAC Logical Bitstream . FLAC Native Bitstream. dr_flac is architecured
// in such a way that the core sections assume everything is delivered in native format. Therefore, for each encapsulation type
// dr_flac is supporting there needs to be a layer sitting on top of the onRead and onSeek callbacks that ensures the bits read from
// the physical Ogg bitstream are converted and delivered in native FLAC format.
struct drflac_oggbs {
  //drflac_read_proc onRead;    // The original onRead callback from drflac_open() and family.
  //drflac_seek_proc onSeek;    // The original onSeek callback from drflac_open() and family.
  //void* pUserData;            // The user data passed on onRead and onSeek. This is the user data that was passed on drflac_open() and family.
  ReadStruct rs;
  ulong currentBytePos;    // The position of the byte we are sitting on in the physical byte stream. Used for efficient seeking.
  ulong firstBytePos;      // The position of the first byte in the physical bitstream. Points to the start of the "OggS" identifier of the FLAC bos page.
  uint serialNumber;      // The serial number of the FLAC audio pages. This is determined by the initial header page that was read during initialization.
  drflac_ogg_page_header bosPageHeader;   // Used for seeking.
  drflac_ogg_page_header currentPageHeader;
  uint bytesRemainingInPage;
  bool stdio; //k8: it is drflac's stdio shit
} // oggbs = Ogg Bitstream

size_t drflac_oggbs__read_physical (drflac_oggbs* oggbs, void* bufferOut, size_t bytesToRead) {
  size_t bytesActuallyRead = oggbs.rs.read(bufferOut, bytesToRead);
  oggbs.currentBytePos += bytesActuallyRead;
  return bytesActuallyRead;
}

bool drflac_oggbs__seek_physical (drflac_oggbs* oggbs, ulong offset, drflac_seek_origin origin) {
  if (origin == drflac_seek_origin_start) {
    if (offset <= 0x7FFFFFFF) {
      if (!oggbs.rs.seek(cast(int)offset, drflac_seek_origin_start)) return false;
      oggbs.currentBytePos = offset;
      return true;
    } else {
      if (!oggbs.rs.seek(0x7FFFFFFF, drflac_seek_origin_start)) return false;
      oggbs.currentBytePos = offset;
      return drflac_oggbs__seek_physical(oggbs, offset-0x7FFFFFFF, drflac_seek_origin_current);
    }
  } else {
    while (offset > 0x7FFFFFFF) {
      if (!oggbs.rs.seek(0x7FFFFFFF, drflac_seek_origin_current)) return false;
      oggbs.currentBytePos += 0x7FFFFFFF;
      offset -= 0x7FFFFFFF;
    }
    if (!oggbs.rs.seek(cast(int)offset, drflac_seek_origin_current)) return false; // <-- Safe cast thanks to the loop above.
    oggbs.currentBytePos += offset;
    return true;
  }
}

bool drflac_oggbs__goto_next_page (drflac_oggbs* oggbs) {
  drflac_ogg_page_header header;
  for (;;) {
    uint headerSize;
    if (!drflac_ogg__read_page_header(oggbs.rs, &header, &headerSize)) return false;
    oggbs.currentBytePos += headerSize;
    uint pageBodySize = drflac_ogg__get_page_body_size(&header);
    if (header.serialNumber == oggbs.serialNumber) {
      oggbs.currentPageHeader = header;
      oggbs.bytesRemainingInPage = pageBodySize;
      return true;
    }
    // If we get here it means the page is not a FLAC page - skip it.
    if (pageBodySize > 0 && !drflac_oggbs__seek_physical(oggbs, pageBodySize, drflac_seek_origin_current)) return false; // <-- Safe cast - maximum size of a page is way below that of an int.
  }
}

size_t drflac__on_read_ogg (void* pUserData, void* bufferOut, size_t bytesToRead) {
  drflac_oggbs* oggbs = cast(drflac_oggbs*)pUserData;
  assert(oggbs !is null);

  ubyte* pRunningBufferOut = cast(ubyte*)bufferOut;

  // Reading is done page-by-page. If we've run out of bytes in the page we need to move to the next one.
  size_t bytesRead = 0;
  while (bytesRead < bytesToRead) {
    size_t bytesRemainingToRead = bytesToRead-bytesRead;

    if (oggbs.bytesRemainingInPage >= bytesRemainingToRead) {
      bytesRead += oggbs.rs.read(pRunningBufferOut, bytesRemainingToRead);
      oggbs.bytesRemainingInPage -= cast(uint)bytesRemainingToRead;
      break;
    }

    // If we get here it means some of the requested data is contained in the next pages.
    if (oggbs.bytesRemainingInPage > 0) {
      size_t bytesJustRead = oggbs.rs.read(pRunningBufferOut, oggbs.bytesRemainingInPage);
      bytesRead += bytesJustRead;
      pRunningBufferOut += bytesJustRead;
      if (bytesJustRead != oggbs.bytesRemainingInPage) break;  // Ran out of data.
    }

    assert(bytesRemainingToRead > 0);
    if (!drflac_oggbs__goto_next_page(oggbs)) break;  // Failed to go to the next chunk. Might have simply hit the end of the stream.
  }

  oggbs.currentBytePos += bytesRead;
  return bytesRead;
}

bool drflac__on_seek_ogg (void* pUserData, int offset, drflac_seek_origin origin) {
  drflac_oggbs* oggbs = cast(drflac_oggbs*)pUserData;
  assert(oggbs !is null);
  assert(offset > 0 || (offset == 0 && origin == drflac_seek_origin_start));

  // Seeking is always forward which makes things a lot simpler.
  if (origin == drflac_seek_origin_start) {
    int startBytePos = cast(int)oggbs.firstBytePos+(79-42);  // 79 = size of bos page; 42 = size of FLAC header data. Seek up to the first byte of the native FLAC data.
    if (!drflac_oggbs__seek_physical(oggbs, startBytePos, drflac_seek_origin_start)) return false;
    oggbs.currentPageHeader = oggbs.bosPageHeader;
    oggbs.bytesRemainingInPage = 42;   // 42 = size of the native FLAC header data. That's our start point for seeking.
    return drflac__on_seek_ogg(pUserData, offset, drflac_seek_origin_current);
  }

  assert(origin == drflac_seek_origin_current);

  int bytesSeeked = 0;
  while (bytesSeeked < offset) {
    int bytesRemainingToSeek = offset-bytesSeeked;
    assert(bytesRemainingToSeek >= 0);

    if (oggbs.bytesRemainingInPage >= cast(size_t)bytesRemainingToSeek) {
      if (!drflac_oggbs__seek_physical(oggbs, bytesRemainingToSeek, drflac_seek_origin_current)) return false;
      bytesSeeked += bytesRemainingToSeek;
      oggbs.bytesRemainingInPage -= bytesRemainingToSeek;
      break;
    }

    // If we get here it means some of the requested data is contained in the next pages.
    if (oggbs.bytesRemainingInPage > 0) {
      if (!drflac_oggbs__seek_physical(oggbs, oggbs.bytesRemainingInPage, drflac_seek_origin_current)) return false;
      bytesSeeked += cast(int)oggbs.bytesRemainingInPage;
    }

    assert(bytesRemainingToSeek > 0);
    if (!drflac_oggbs__goto_next_page(oggbs)) break;  // Failed to go to the next chunk. Might have simply hit the end of the stream.
  }

  return true;
}

bool drflac_ogg__seek_to_sample (drflac* pFlac, ulong sample) {
  drflac_oggbs* oggbs = cast(drflac_oggbs*)((cast(int*)pFlac.pExtraData)+pFlac.maxBlockSize*pFlac.channels);

  ulong originalBytePos = oggbs.currentBytePos;   // For recovery.

  // First seek to the first frame.
  if (!drflac__seek_to_byte(&pFlac.bs, pFlac.firstFramePos)) return false;
  oggbs.bytesRemainingInPage = 0;

  ulong runningGranulePosition = 0;
  ulong runningFrameBytePos = oggbs.currentBytePos;   // <-- Points to the OggS identifier.
  for (;;) {
    if (!drflac_oggbs__goto_next_page(oggbs)) {
      drflac_oggbs__seek_physical(oggbs, originalBytePos, drflac_seek_origin_start);
      return false;   // Never did find that sample...
    }

    runningFrameBytePos = oggbs.currentBytePos-drflac_ogg__get_page_header_size(&oggbs.currentPageHeader);
    if (oggbs.currentPageHeader.granulePosition*pFlac.channels >= sample) break; // The sample is somewhere in the previous page.

    // At this point we know the sample is not in the previous page. It could possibly be in this page. For simplicity we
    // disregard any pages that do not begin a fresh packet.
    if ((oggbs.currentPageHeader.headerType&0x01) == 0) {    // <-- Is it a fresh page?
      if (oggbs.currentPageHeader.segmentTable.ptr[0] >= 2) {
        ubyte[2] firstBytesInPage;
        if (drflac_oggbs__read_physical(oggbs, firstBytesInPage.ptr, 2) != 2) {
          drflac_oggbs__seek_physical(oggbs, originalBytePos, drflac_seek_origin_start);
          return false;
        }
        if ((firstBytesInPage.ptr[0] == 0xFF) && (firstBytesInPage.ptr[1]&0xFC) == 0xF8) {    // <-- Does the page begin with a frame's sync code?
          runningGranulePosition = oggbs.currentPageHeader.granulePosition*pFlac.channels;
        }

        if (!drflac_oggbs__seek_physical(oggbs, cast(int)oggbs.bytesRemainingInPage-2, drflac_seek_origin_current)) {
          drflac_oggbs__seek_physical(oggbs, originalBytePos, drflac_seek_origin_start);
          return false;
        }

        continue;
      }
    }

    if (!drflac_oggbs__seek_physical(oggbs, cast(int)oggbs.bytesRemainingInPage, drflac_seek_origin_current)) {
      drflac_oggbs__seek_physical(oggbs, originalBytePos, drflac_seek_origin_start);
      return false;
    }
  }

  // We found the page that that is closest to the sample, so now we need to find it. The first thing to do is seek to the
  // start of that page. In the loop above we checked that it was a fresh page which means this page is also the start of
  // a new frame. This property means that after we've seeked to the page we can immediately start looping over frames until
  // we find the one containing the target sample.
  if (!drflac_oggbs__seek_physical(oggbs, runningFrameBytePos, drflac_seek_origin_start)) return false;
  if (!drflac_oggbs__goto_next_page(oggbs)) return false;

  // At this point we'll be sitting on the first byte of the frame header of the first frame in the page. We just keep
  // looping over these frames until we find the one containing the sample we're after.
  ulong firstSampleInFrame = runningGranulePosition;
  for (;;) {
    // NOTE for later: When using Ogg's page/segment based seeking later on we can't use this function (or any drflac__*
    // reading functions) because otherwise it will pull extra data for use in it's own internal caches which will then
    // break the positioning of the read pointer for the Ogg bitstream.
    if (!drflac__read_next_frame_header(&pFlac.bs, pFlac.bitsPerSample, &pFlac.currentFrame.header)) return false;

    int channels = drflac__get_channel_count_from_channel_assignment(pFlac.currentFrame.header.channelAssignment);
    ulong lastSampleInFrame = firstSampleInFrame+(pFlac.currentFrame.header.blockSize*channels);
    lastSampleInFrame -= 1; // <-- Zero based.

    if (sample >= firstSampleInFrame && sample <= lastSampleInFrame) break;  // The sample is in this frame.

    // If we get here it means the sample is not in this frame so we need to move to the next one. Now the cool thing
    // with Ogg is that we can efficiently seek past the frame by looking at the lacing values of each segment in
    // the page.
    firstSampleInFrame = lastSampleInFrame+1;

    version(all) {
      // Slow way. This uses the native FLAC decoder to seek past the frame. This is slow because it needs to do a partial
      // decode of the frame. Although this is how the native version works, we can use Ogg's framing system to make it
      // more efficient. Leaving this here for reference and to use as a basis for debugging purposes.
      if (!drflac__seek_to_next_frame(pFlac)) return false;
    } else {
      // TODO: This is not yet complete. See note at the top of this loop body.

      // Fast(er) way. This uses Ogg's framing system to seek past the frame. This should be much more efficient than the
      // native FLAC seeking.
      if (!drflac_oggbs__seek_to_next_frame(oggbs)) return false;
    }
  }

  assert(firstSampleInFrame <= sample);

  if (!drflac__decode_frame(pFlac)) return false;

  size_t samplesToDecode = cast(size_t)(sample-firstSampleInFrame);    // <-- Safe cast because the maximum number of samples in a frame is 65535.
  return drflac_read_s32(pFlac, samplesToDecode, null) == samplesToDecode;
}


bool drflac__init_private__ogg (drflac_init_info* pInit, ref ReadStruct rs, scope drflac_meta_proc onMeta, void* pUserDataMD) {
  // Pre: The bit stream should be sitting just past the 4-byte OggS capture pattern.

  pInit.container = drflac_container_ogg;
  pInit.oggFirstBytePos = 0;

  // We'll get here if the first 4 bytes of the stream were the OggS capture pattern, however it doesn't necessarily mean the
  // stream includes FLAC encoded audio. To check for this we need to scan the beginning-of-stream page markers and check if
  // any match the FLAC specification. Important to keep in mind that the stream may be multiplexed.
  drflac_ogg_page_header header;

  uint headerSize = 0;
  if (!drflac_ogg__read_page_header_after_capture_pattern(rs, &header, &headerSize)) return false;
  pInit.runningFilePos += headerSize;

  for (;;) {
    // Break if we're past the beginning of stream page.
    if ((header.headerType&0x02) == 0) return false;

    // Check if it's a FLAC header.
    int pageBodySize = drflac_ogg__get_page_body_size(&header);
    if (pageBodySize == 51) { // 51 = the lacing value of the FLAC header packet.
      // It could be a FLAC page...
      uint bytesRemainingInPage = pageBodySize;

      ubyte packetType;
      if (rs.read(&packetType, 1) != 1) return false;

      bytesRemainingInPage -= 1;
      if (packetType == 0x7F) {
        // Increasingly more likely to be a FLAC page...
        ubyte[4] sig;
        if (rs.read(sig.ptr, 4) != 4) return false;

        bytesRemainingInPage -= 4;
        if (sig.ptr[0] == 'F' && sig.ptr[1] == 'L' && sig.ptr[2] == 'A' && sig.ptr[3] == 'C') {
          // Almost certainly a FLAC page...
          ubyte[2] mappingVersion;
          if (rs.read(mappingVersion.ptr, 2) != 2) return false;

          if (mappingVersion.ptr[0] != 1) return false;   // Only supporting version 1.x of the Ogg mapping.

          // The next 2 bytes are the non-audio packets, not including this one. We don't care about this because we're going to
          // be handling it in a generic way based on the serial number and packet types.
          if (!rs.seek(2, drflac_seek_origin_current)) return false;

          // Expecting the native FLAC signature "fLaC".
          if (rs.read(sig.ptr, 4) != 4) return false;

          if (sig.ptr[0] == 'f' && sig.ptr[1] == 'L' && sig.ptr[2] == 'a' && sig.ptr[3] == 'C') {
            // The remaining data in the page should be the STREAMINFO block.
            ubyte isLastBlock;
            ubyte blockType;
            uint blockSize;
            if (!drflac__read_and_decode_block_header(rs, &isLastBlock, &blockType, &blockSize)) return false;

            if (blockType != DRFLAC_METADATA_BLOCK_TYPE_STREAMINFO || blockSize != 34) return false;    // Invalid block type. First block must be the STREAMINFO block.

            drflac_streaminfo streaminfo;
            if (drflac__read_streaminfo(rs, &streaminfo)) {
              // Success!
              pInit.sampleRate       = streaminfo.sampleRate;
              pInit.channels         = streaminfo.channels;
              pInit.bitsPerSample    = streaminfo.bitsPerSample;
              pInit.totalSampleCount = streaminfo.totalSampleCount;
              pInit.maxBlockSize     = streaminfo.maxBlockSize;

              if (onMeta !is null) {
                drflac_metadata metadata;
                metadata.type = DRFLAC_METADATA_BLOCK_TYPE_STREAMINFO;
                metadata.pRawData = null;
                metadata.rawDataSize = 0;
                metadata.data.streaminfo = streaminfo;
                try { onMeta(pUserDataMD, &metadata); } catch (Exception e) { return false; }
              }

              pInit.runningFilePos  += pageBodySize;
              pInit.oggFirstBytePos  = pInit.runningFilePos-79;   // Subtracting 79 will place us right on top of the "OggS" identifier of the FLAC bos page.
              pInit.oggSerial        = header.serialNumber;
              pInit.oggBosHeader     = header;
              break;
            } else {
              // Failed to read STREAMINFO block. Aww, so close...
              return false;
            }
          } else {
            // Invalid file.
            return false;
          }
        } else {
          // Not a FLAC header. Skip it.
          if (!rs.seek(bytesRemainingInPage, drflac_seek_origin_current)) return false;
        }
      } else {
        // Not a FLAC header. Seek past the entire page and move on to the next.
        if (!rs.seek(bytesRemainingInPage, drflac_seek_origin_current)) return false;
      }
    } else {
      if (!rs.seek(pageBodySize, drflac_seek_origin_current)) return false;
    }

    pInit.runningFilePos += pageBodySize;

    // Read the header of the next page.
    if (!drflac_ogg__read_page_header(rs, &header, &headerSize)) return false;
    pInit.runningFilePos += headerSize;
  }


  // If we get here it means we found a FLAC audio stream. We should be sitting on the first byte of the header of the next page. The next
  // packets in the FLAC logical stream contain the metadata. The only thing left to do in the initialiation phase for Ogg is to create the
  // Ogg bistream object.
  pInit.hasMetadataBlocks = true;    // <-- Always have at least VORBIS_COMMENT metadata block.
  return true;
}
//#endif

bool drflac__check_init_private (drflac_init_info* pInit, scope drflac_meta_proc onMeta, void* pUserDataMD) {
  ubyte[4] id;
  if (pInit.rs.read(id.ptr, 4) != 4) return false;
  if (id.ptr[0] == 'f' && id.ptr[1] == 'L' && id.ptr[2] == 'a' && id.ptr[3] == 'C') return drflac__init_private__native(pInit, pInit.rs, onMeta, pUserDataMD);
//#ifndef DR_FLAC_NO_OGG
  if (id.ptr[0] == 'O' && id.ptr[1] == 'g' && id.ptr[2] == 'g' && id.ptr[3] == 'S') return drflac__init_private__ogg(pInit, pInit.rs, onMeta, pUserDataMD);
//#endif
  // unsupported container
  return false;
}

bool drflac__init_private (drflac_init_info* pInit, drflac_read_proc onRead, drflac_seek_proc onSeek, scope drflac_meta_proc onMeta, void* pUserData, void* pUserDataMD) {
  if (pInit is null || onRead is null || onSeek is null) return false;

  pInit.rs.onReadCB  = onRead;
  pInit.rs.onSeekCB  = onSeek;
  pInit.rs.pUserData = pUserData;
  //pInit.onMeta       = onMeta;
  //pInit.pUserDataMD  = pUserDataMD;

  return drflac__check_init_private(pInit, onMeta, pUserDataMD);
}

} //nothrow

nothrow {
void drflac__init_from_info (drflac* pFlac, drflac_init_info* pInit) {
  import core.stdc.string : memcpy, memset;
  assert(pFlac !is null);
  assert(pInit !is null);

  memset(pFlac, 0, (*pFlac).sizeof);
  pFlac.bs.rs            = pInit.rs;
  pFlac.bs.nextL2Line    = (pFlac.bs.cacheL2).sizeof/(pFlac.bs.cacheL2.ptr[0]).sizeof; // <-- Initialize to this to force a client-side data retrieval right from the start.
  pFlac.bs.consumedBits  = (pFlac.bs.cache).sizeof*8;

  //pFlac.onMeta           = pInit.onMeta;
  //pFlac.pUserDataMD      = pInit.pUserDataMD;
  pFlac.maxBlockSize     = pInit.maxBlockSize;
  pFlac.sampleRate       = pInit.sampleRate;
  pFlac.channels         = cast(ubyte)pInit.channels;
  pFlac.bitsPerSample    = cast(ubyte)pInit.bitsPerSample;
  pFlac.totalSampleCount = pInit.totalSampleCount;
  pFlac.container        = pInit.container;
}

drflac* drflac_open_with_metadata_private_xx (drflac_init_info* init, scope drflac_meta_proc onMeta, void* pUserDataMD, bool stdio) {
  import core.stdc.stdlib : malloc, free;
  import core.stdc.string : memset;

  size_t allocationSize = (drflac).sizeof;
  allocationSize += init.maxBlockSize*init.channels*(int).sizeof;
  //allocationSize += init.seektableSize;

//#ifndef DR_FLAC_NO_OGG
  // There's additional data required for Ogg streams.
  if (init.container == drflac_container_ogg) allocationSize += (drflac_oggbs).sizeof;
//#endif

  drflac* pFlac = cast(drflac*)malloc(allocationSize);
  memset(pFlac, 0, (*pFlac).sizeof);
  drflac__init_from_info(pFlac, init);
  pFlac.pDecodedSamples = cast(int*)pFlac.pExtraData;

//#ifndef DR_FLAC_NO_OGG
  if (init.container == drflac_container_ogg) {
    drflac_oggbs* oggbs = cast(drflac_oggbs*)((cast(int*)pFlac.pExtraData)+init.maxBlockSize*init.channels);
    oggbs.stdio = stdio;
    oggbs.rs = init.rs;
    oggbs.currentBytePos = init.oggFirstBytePos;
    oggbs.firstBytePos = init.oggFirstBytePos;
    oggbs.serialNumber = init.oggSerial;
    oggbs.bosPageHeader = init.oggBosHeader;
    oggbs.bytesRemainingInPage = 0;

    // The Ogg bistream needs to be layered on top of the original bitstream.
    pFlac.bs.rs.onReadCB = &drflac__on_read_ogg;
    pFlac.bs.rs.onSeekCB = &drflac__on_seek_ogg;
    pFlac.bs.rs.pUserData = cast(void*)oggbs;
  }
//#endif

  // Decode metadata before returning.
  if (init.hasMetadataBlocks) {
    if (!drflac__read_and_decode_metadata(pFlac, onMeta, pUserDataMD)) {
      free(pFlac);
      return null;
    }
  }

  return pFlac;
}


drflac* drflac_open_with_metadata_private (drflac_read_proc onRead, drflac_seek_proc onSeek, scope drflac_meta_proc onMeta, void* pUserData, void* pUserDataMD, bool stdio) {
  drflac_init_info init;
  if (!drflac__init_private(&init, onRead, onSeek, onMeta, pUserData, pUserDataMD)) return null;
  return drflac_open_with_metadata_private_xx(&init, onMeta, pUserDataMD, stdio);
}

} //nothrow

nothrow {

size_t drflac__on_read_memory (void* pUserData, void* bufferOut, size_t bytesToRead) {
  drflac__memory_stream* memoryStream = cast(drflac__memory_stream*)pUserData;
  assert(memoryStream !is null);
  assert(memoryStream.dataSize >= memoryStream.currentReadPos);

  size_t bytesRemaining = memoryStream.dataSize-memoryStream.currentReadPos;
  if (bytesToRead > bytesRemaining) bytesToRead = bytesRemaining;

  if (bytesToRead > 0) {
    import core.stdc.string : memcpy;
    memcpy(bufferOut, memoryStream.data+memoryStream.currentReadPos, bytesToRead);
    memoryStream.currentReadPos += bytesToRead;
  }

  return bytesToRead;
}

bool drflac__on_seek_memory (void* pUserData, int offset, drflac_seek_origin origin) {
  drflac__memory_stream* memoryStream = cast(drflac__memory_stream*)pUserData;
  assert(memoryStream !is null);
  assert(offset > 0 || (offset == 0 && origin == drflac_seek_origin_start));

  if (origin == drflac_seek_origin_current) {
    if (memoryStream.currentReadPos+offset <= memoryStream.dataSize) {
      memoryStream.currentReadPos += offset;
    } else {
      memoryStream.currentReadPos = memoryStream.dataSize;  // Trying to seek too far forward.
    }
  } else {
    if (cast(uint)offset <= memoryStream.dataSize) {
      memoryStream.currentReadPos = offset;
    } else {
      memoryStream.currentReadPos = memoryStream.dataSize;  // Trying to seek too far forward.
    }
  }

  return true;
}

public drflac* drflac_open_memory (const(void)* data, size_t dataSize) {

  drflac__memory_stream memoryStream;
  memoryStream.data = cast(const(ubyte)*)data;
  memoryStream.dataSize = dataSize;
  memoryStream.currentReadPos = 0;

  drflac* pFlac = drflac_open(&drflac__on_read_memory, &drflac__on_seek_memory, &memoryStream);
  if (pFlac is null) return null;

  pFlac.memoryStream = memoryStream;

  // This is an awful hack...
//#ifndef DR_FLAC_NO_OGG
  if (pFlac.container == drflac_container_ogg) {
    drflac_oggbs* oggbs = cast(drflac_oggbs*)((cast(int*)pFlac.pExtraData)+pFlac.maxBlockSize*pFlac.channels);
    oggbs.rs.pUserData = &pFlac.memoryStream;
  }
  else
//#endif
  {
    pFlac.bs.rs.pUserData = &pFlac.memoryStream;
  }

  return pFlac;
}

public drflac* drflac_open_memory_with_metadata (const(void)* data, size_t dataSize, scope drflac_meta_proc onMeta, void* pUserData) {

  drflac__memory_stream memoryStream;
  memoryStream.data = cast(const(ubyte)*)data;
  memoryStream.dataSize = dataSize;
  memoryStream.currentReadPos = 0;

  drflac* pFlac = drflac_open_with_metadata_private(&drflac__on_read_memory, &drflac__on_seek_memory, onMeta, &memoryStream, pUserData, false);
  if (pFlac is null) return null;

  pFlac.memoryStream = memoryStream;

  // This is an awful hack...
//#ifndef DR_FLAC_NO_OGG
  if (pFlac.container == drflac_container_ogg) {
    drflac_oggbs* oggbs = cast(drflac_oggbs*)((cast(int*)pFlac.pExtraData)+pFlac.maxBlockSize*pFlac.channels);
    oggbs.rs.pUserData = &pFlac.memoryStream;
  } else
//#endif
  {
    pFlac.bs.rs.pUserData = &pFlac.memoryStream;
  }

  return pFlac;
}

public drflac* drflac_open (drflac_read_proc onRead, drflac_seek_proc onSeek, void* pUserData) {
  return drflac_open_with_metadata_private(onRead, onSeek, null, pUserData, pUserData, false);
}

} //nothrow


nothrow {

public drflac* drflac_open_with_metadata (drflac_read_proc onRead, drflac_seek_proc onSeek, scope drflac_meta_proc onMeta, void* pUserData) {
  return drflac_open_with_metadata_private(onRead, onSeek, onMeta, pUserData, pUserData, false);
}

public void drflac_close (drflac* pFlac) 
{
    import core.stdc.stdlib : free;
    free(pFlac);
}


ulong drflac__read_s32__misaligned (drflac* pFlac, ulong samplesToRead, int* bufferOut) {
  uint channelCount = drflac__get_channel_count_from_channel_assignment(pFlac.currentFrame.header.channelAssignment);

  // We should never be calling this when the number of samples to read is >= the sample count.
  assert(samplesToRead < channelCount);
  assert(pFlac.currentFrame.samplesRemaining > 0 && samplesToRead <= pFlac.currentFrame.samplesRemaining);

  ulong samplesRead = 0;
  while (samplesToRead > 0) {
    ulong totalSamplesInFrame = pFlac.currentFrame.header.blockSize*channelCount;
    ulong samplesReadFromFrameSoFar = totalSamplesInFrame-pFlac.currentFrame.samplesRemaining;
    uint channelIndex = samplesReadFromFrameSoFar%channelCount;

    ulong nextSampleInFrame = samplesReadFromFrameSoFar/channelCount;

    int decodedSample = 0;
    switch (pFlac.currentFrame.header.channelAssignment) {
      case DRFLAC_CHANNEL_ASSIGNMENT_LEFT_SIDE:
        if (channelIndex == 0) {
          decodedSample = pFlac.currentFrame.subframes.ptr[channelIndex].pDecodedSamples[cast(uint)nextSampleInFrame];
        } else {
          int side = pFlac.currentFrame.subframes.ptr[channelIndex+0].pDecodedSamples[cast(uint)nextSampleInFrame];
          int left = pFlac.currentFrame.subframes.ptr[channelIndex-1].pDecodedSamples[cast(uint)nextSampleInFrame];
          decodedSample = left-side;
        }
        break;

      case DRFLAC_CHANNEL_ASSIGNMENT_RIGHT_SIDE:
        if (channelIndex == 0) {
          int side  = pFlac.currentFrame.subframes.ptr[channelIndex+0].pDecodedSamples[cast(uint)nextSampleInFrame];
          int right = pFlac.currentFrame.subframes.ptr[channelIndex+1].pDecodedSamples[cast(uint)nextSampleInFrame];
          decodedSample = side+right;
        } else {
          decodedSample = pFlac.currentFrame.subframes.ptr[channelIndex].pDecodedSamples[cast(uint)nextSampleInFrame];
        }
        break;

      case DRFLAC_CHANNEL_ASSIGNMENT_MID_SIDE:
        int mid;
        int side;
        if (channelIndex == 0) {
          mid  = pFlac.currentFrame.subframes.ptr[channelIndex+0].pDecodedSamples[cast(uint)nextSampleInFrame];
          side = pFlac.currentFrame.subframes.ptr[channelIndex+1].pDecodedSamples[cast(uint)nextSampleInFrame];
          mid = ((cast(uint)mid)<<1)|(side&0x01);
          decodedSample = (mid+side)>>1;
        } else {
          mid  = pFlac.currentFrame.subframes.ptr[channelIndex-1].pDecodedSamples[cast(uint)nextSampleInFrame];
          side = pFlac.currentFrame.subframes.ptr[channelIndex+0].pDecodedSamples[cast(uint)nextSampleInFrame];
          mid = ((cast(uint)mid)<<1)|(side&0x01);
          decodedSample = (mid-side)>>1;
        }
        break;

      case DRFLAC_CHANNEL_ASSIGNMENT_INDEPENDENT: goto default;
      default:
        decodedSample = pFlac.currentFrame.subframes.ptr[channelIndex].pDecodedSamples[cast(uint)nextSampleInFrame];
        break;
    }

    decodedSample <<= ((32-pFlac.bitsPerSample)+pFlac.currentFrame.subframes.ptr[channelIndex].wastedBitsPerSample);

    if (bufferOut) *bufferOut++ = decodedSample;

    samplesRead += 1;
    pFlac.currentFrame.samplesRemaining -= 1;
    samplesToRead -= 1;
  }

  return samplesRead;
}

ulong drflac__seek_forward_by_samples (drflac* pFlac, ulong samplesToRead) {
  ulong samplesRead = 0;
  while (samplesToRead > 0) {
    if (pFlac.currentFrame.samplesRemaining == 0) {
      if (!drflac__read_and_decode_next_frame(pFlac)) break;  // Couldn't read the next frame, so just break from the loop and return.
    } else {
      samplesRead += 1;
      pFlac.currentFrame.samplesRemaining -= 1;
      samplesToRead -= 1;
    }
  }
  return samplesRead;
}

public ulong drflac_read_s32 (drflac* pFlac, ulong samplesToRead, int* bufferOut) {
  // Note that <bufferOut> is allowed to be null, in which case this will be treated as something like a seek.
  if (pFlac is null || samplesToRead == 0) return 0;

  if (bufferOut is null) 
  {
     // wtf
     return drflac__seek_forward_by_samples(pFlac, samplesToRead);
  }

  ulong samplesRead = 0;
  while (samplesToRead > 0) {
    // If we've run out of samples in this frame, go to the next.
    if (pFlac.currentFrame.samplesRemaining == 0) {
      if (!drflac__read_and_decode_next_frame(pFlac)) break;  // Couldn't read the next frame, so just break from the loop and return.
    } else {
      // Here is where we grab the samples and interleave them.

      uint channelCount = drflac__get_channel_count_from_channel_assignment(pFlac.currentFrame.header.channelAssignment);
      ulong totalSamplesInFrame = pFlac.currentFrame.header.blockSize*channelCount;
      ulong samplesReadFromFrameSoFar = totalSamplesInFrame-pFlac.currentFrame.samplesRemaining;

      int misalignedSampleCount = cast(int)(samplesReadFromFrameSoFar%channelCount);
      if (misalignedSampleCount > 0) {
        ulong misalignedSamplesRead = drflac__read_s32__misaligned(pFlac, misalignedSampleCount, bufferOut);
        samplesRead   += misalignedSamplesRead;
        samplesReadFromFrameSoFar += misalignedSamplesRead;
        bufferOut     += misalignedSamplesRead;
        samplesToRead -= misalignedSamplesRead;
      }

      ulong alignedSampleCountPerChannel = samplesToRead/channelCount;
      if (alignedSampleCountPerChannel > pFlac.currentFrame.samplesRemaining/channelCount) {
        alignedSampleCountPerChannel = pFlac.currentFrame.samplesRemaining/channelCount;
      }

      ulong firstAlignedSampleInFrame = samplesReadFromFrameSoFar/channelCount;
      uint unusedBitsPerSample = 32-pFlac.bitsPerSample;

      switch (pFlac.currentFrame.header.channelAssignment) {
        case DRFLAC_CHANNEL_ASSIGNMENT_LEFT_SIDE:
          const int* pDecodedSamples0 = pFlac.currentFrame.subframes.ptr[0].pDecodedSamples+firstAlignedSampleInFrame;
          const int* pDecodedSamples1 = pFlac.currentFrame.subframes.ptr[1].pDecodedSamples+firstAlignedSampleInFrame;

          for (/*ulong*/uint i = 0; i < alignedSampleCountPerChannel; ++i) {
            int left  = pDecodedSamples0[i];
            int side  = pDecodedSamples1[i];
            int right = left-side;
            bufferOut[i*2+0] = left<<(unusedBitsPerSample+pFlac.currentFrame.subframes.ptr[0].wastedBitsPerSample);
            bufferOut[i*2+1] = right<<(unusedBitsPerSample+pFlac.currentFrame.subframes.ptr[1].wastedBitsPerSample);
          }
          break;

        case DRFLAC_CHANNEL_ASSIGNMENT_RIGHT_SIDE:
          const int* pDecodedSamples0 = pFlac.currentFrame.subframes.ptr[0].pDecodedSamples+firstAlignedSampleInFrame;
          const int* pDecodedSamples1 = pFlac.currentFrame.subframes.ptr[1].pDecodedSamples+firstAlignedSampleInFrame;
          for (/*ulong*/uint i = 0; i < alignedSampleCountPerChannel; ++i) {
            int side  = pDecodedSamples0[i];
            int right = pDecodedSamples1[i];
            int left  = right+side;
            bufferOut[i*2+0] = left<<(unusedBitsPerSample+pFlac.currentFrame.subframes.ptr[0].wastedBitsPerSample);
            bufferOut[i*2+1] = right<<(unusedBitsPerSample+pFlac.currentFrame.subframes.ptr[1].wastedBitsPerSample);
          }
          break;

        case DRFLAC_CHANNEL_ASSIGNMENT_MID_SIDE:
          const int* pDecodedSamples0 = pFlac.currentFrame.subframes.ptr[0].pDecodedSamples+firstAlignedSampleInFrame;
          const int* pDecodedSamples1 = pFlac.currentFrame.subframes.ptr[1].pDecodedSamples+firstAlignedSampleInFrame;
          for (/*ulong*/uint i = 0; i < alignedSampleCountPerChannel; ++i) {
            int side = pDecodedSamples1[i];
            int mid  = ((cast(uint)pDecodedSamples0[i])<<1)|(side&0x01);
            bufferOut[i*2+0] = ((mid+side)>>1)<<(unusedBitsPerSample+pFlac.currentFrame.subframes.ptr[0].wastedBitsPerSample);
            bufferOut[i*2+1] = ((mid-side)>>1)<<(unusedBitsPerSample+pFlac.currentFrame.subframes.ptr[1].wastedBitsPerSample);
          }
          break;

        case DRFLAC_CHANNEL_ASSIGNMENT_INDEPENDENT: goto default;
        default:
          if (pFlac.currentFrame.header.channelAssignment == 1) { // 1 = Stereo
            // Stereo optimized inner loop unroll.
            const int* pDecodedSamples0 = pFlac.currentFrame.subframes.ptr[0].pDecodedSamples+firstAlignedSampleInFrame;
            const int* pDecodedSamples1 = pFlac.currentFrame.subframes.ptr[1].pDecodedSamples+firstAlignedSampleInFrame;
            for (/*ulong*/uint i = 0; i < alignedSampleCountPerChannel; ++i) {
              bufferOut[i*2+0] = pDecodedSamples0[i]<<(unusedBitsPerSample+pFlac.currentFrame.subframes.ptr[0].wastedBitsPerSample);
              bufferOut[i*2+1] = pDecodedSamples1[i]<<(unusedBitsPerSample+pFlac.currentFrame.subframes.ptr[1].wastedBitsPerSample);
            }
          } else {
            // Generic interleaving.
            for (/*ulong*/uint i = 0; i < alignedSampleCountPerChannel; ++i) {
              for (uint j = 0; j < channelCount; ++j) {
                bufferOut[(i*channelCount)+j] = (pFlac.currentFrame.subframes.ptr[j].pDecodedSamples[cast(uint)firstAlignedSampleInFrame+i])<<(unusedBitsPerSample+pFlac.currentFrame.subframes.ptr[j].wastedBitsPerSample);
              }
            }
          }
          break;
      }

      ulong alignedSamplesRead = alignedSampleCountPerChannel*channelCount;
      samplesRead   += alignedSamplesRead;
      samplesReadFromFrameSoFar += alignedSamplesRead;
      bufferOut     += alignedSamplesRead;
      samplesToRead -= alignedSamplesRead;
      pFlac.currentFrame.samplesRemaining -= cast(uint)alignedSamplesRead;

      // At this point we may still have some excess samples left to read.
      if (samplesToRead > 0 && pFlac.currentFrame.samplesRemaining > 0) {
        ulong excessSamplesRead = 0;
        if (samplesToRead < pFlac.currentFrame.samplesRemaining) {
          excessSamplesRead = drflac__read_s32__misaligned(pFlac, samplesToRead, bufferOut);
        } else {
          excessSamplesRead = drflac__read_s32__misaligned(pFlac, pFlac.currentFrame.samplesRemaining, bufferOut);
        }

        samplesRead   += excessSamplesRead;
        samplesReadFromFrameSoFar += excessSamplesRead;
        bufferOut     += excessSamplesRead;
        samplesToRead -= excessSamplesRead;
      }
    }
  }

  return samplesRead;
}

public bool drflac_seek_to_sample (drflac* pFlac, ulong sampleIndex) {
  if (pFlac is null) return false;

  // If we don't know where the first frame begins then we can't seek. This will happen when the STREAMINFO block was not present
  // when the decoder was opened.
  if (pFlac.firstFramePos == 0) return false;

  if (sampleIndex == 0) return drflac__seek_to_first_frame(pFlac);

  // Clamp the sample to the end.
  if (sampleIndex >= pFlac.totalSampleCount) sampleIndex  = pFlac.totalSampleCount-1;

  // Different techniques depending on encapsulation. Using the native FLAC seektable with Ogg encapsulation is a bit awkward so
  // we'll instead use Ogg's natural seeking facility.
//#ifndef DR_FLAC_NO_OGG
  if (pFlac.container == drflac_container_ogg) {
    return drflac_ogg__seek_to_sample(pFlac, sampleIndex);
  }
  else
//#endif
  {
    // First try seeking via the seek table. If this fails, fall back to a brute force seek which is much slower.
    if (!drflac__seek_to_sample__seek_table(pFlac, sampleIndex)) return drflac__seek_to_sample__brute_force(pFlac, sampleIndex);
  }

  return true;
}

public void drflac_free (void* pSampleDataReturnedByOpenAndDecode) {
  import core.stdc.stdlib : free;
  free(pSampleDataReturnedByOpenAndDecode);
}


public void drflac_init_vorbis_comment_iterator (drflac_vorbis_comment_iterator* pIter, uint commentCount, const(char)* pComments) {
  if (pIter is null) return;
  pIter.countRemaining = commentCount;
  pIter.pRunningData   = pComments;
}

public const(char)* drflac_next_vorbis_comment (drflac_vorbis_comment_iterator* pIter, uint* pCommentLengthOut) {
  // Safety.
  if (pCommentLengthOut) *pCommentLengthOut = 0;

  if (pIter is null || pIter.countRemaining == 0 || pIter.pRunningData is null) return null;

  uint length = drflac__le2host_32(*cast(uint*)pIter.pRunningData);
  pIter.pRunningData += 4;

  const(char)* pComment = pIter.pRunningData;
  pIter.pRunningData += length;
  pIter.countRemaining -= 1;

  if (pCommentLengthOut) *pCommentLengthOut = length;
  return pComment;
}


public long drflac_vorbis_comment_size (uint commentCount, const(char)* pComments) {
  uint res = 0;
  while (commentCount-- > 0) {
    uint length = drflac__le2host_32(*cast(uint*)pComments);
    pComments += 4;
    pComments += length;
    res += length+4;
  }
  return res;
}

}

// REVISION HISTORY
//
// v0.3d - 11/06/2016
//   - Minor clean up.
//
// v0.3c - 28/05/2016
//   - Fixed compilation error.
//
// v0.3b - 16/05/2016
//   - Fixed Linux/GCC build.
//   - Updated documentation.
//
// v0.3a - 15/05/2016
//   - Minor fixes to documentation.
//
// v0.3 - 11/05/2016
//   - Optimizations. Now at about parity with the reference implementation on 32-bit builds.
//   - Lots of clean up.
//
// v0.2b - 10/05/2016
//   - Bug fixes.
//
// v0.2a - 10/05/2016
//   - Made drflac_open_and_decode() more robust.
//   - Removed an unused debugging variable
//
// v0.2 - 09/05/2016
//   - Added support for Ogg encapsulation.
//   - API CHANGE. Have the onSeek callback take a third argument which specifies whether or not the seek
//     should be relative to the start or the current position. Also changes the seeking rules such that
//     seeking offsets will never be negative.
//   - Have drflac_open_and_decode() fail gracefully if the stream has an unknown total sample count.
//
// v0.1b - 07/05/2016
//   - Properly close the file handle in drflac_open_file() and family when the decoder fails to initialize.
//   - Removed a stale comment.
//
// v0.1a - 05/05/2016
//   - Minor formatting changes.
//   - Fixed a warning on the GCC build.
//
// v0.1 - 03/05/2016
//   - Initial versioned release.

// TODO
// - Add support for initializing the decoder without a header STREAMINFO block.
// - Test CUESHEET metadata blocks.


/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
*/
