/*
   Original C comment:
   
   LZ4 - Fast LZ compression algorithm
   Copyright (C) 2011-2015, Yann Collet.
   BSD 2-Clause License (http://www.opensource.org/licenses/bsd-license.php)

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:

	   * Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
	   * Redistributions in binary form must reproduce the above
   copyright notice, this list of conditions and the following disclaimer
   in the documentation and/or other materials provided with the
   distribution.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

   You can contact the author at :
   - LZ4 source repository : http://code.google.com/p/lz4
   - LZ4 source mirror : https://github.com/Cyan4973/lz4
   - LZ4 public forum : https://groups.google.com/forum/#!forum/lz4c
*/
module gamut.codecs.lz4;


version(decodeQOIX)
    version = hasLZ4;
version(encodeQOIX)
    version = hasLZ4;

version(hasLZ4):

nothrow @nogc:

private import core.stdc.stdlib;
private import core.stdc.string;
private import std.system;
private import std.bitmanip;
private import gamut.codecs.ctypes;

/// Version constants
enum int LZ4_VERSION_MAJOR   =   1;    /* for breaking interface changes  */
/// ditto
enum int LZ4_VERSION_MINOR   =   5;    /* for new (non-breaking) interface capabilities */
/// ditto
enum int LZ4_VERSION_RELEASE =   0;    /* for tweaks, bug-fixes, or development */
/// ditto
enum int LZ4_VERSION_NUMBER  = (LZ4_VERSION_MAJOR *100*100 + LZ4_VERSION_MINOR *100 + LZ4_VERSION_RELEASE);

/// Tuning constant
enum int LZ4_MEMORY_USAGE    =  cLZ4_MEMORY_USAGE;
/// Constant
enum int LZ4_MAX_INPUT_SIZE  =  0x7E000000;   /* 2 113 929 216 bytes */
/// -
uint LZ4_COMPRESSBOUND(uint isize)
{
	return (isize > LZ4_MAX_INPUT_SIZE) ? 0 : ((isize) + ((isize)/255) + 16);
}
/// Streaming constants
enum int LZ4_STREAMSIZE_U64 =  ((1 << (LZ4_MEMORY_USAGE-3)) + 4);
/// ditto
enum int LZ4_STREAMSIZE     =  (LZ4_STREAMSIZE_U64 * 8);
/// ditto
enum int LZ4_STREAMDECODESIZE_U64 =  4;
/// ditto
enum int LZ4_STREAMDECODESIZE     =  (LZ4_STREAMDECODESIZE_U64 * 8);
/// -
struct LZ4_stream_t
{
	long[LZ4_STREAMSIZE_U64] table;
}
/// -
struct LZ4_streamDecode_t
{
	long[LZ4_STREAMDECODESIZE_U64] table;
}

//**********************************************************

version(LDC)
{
    // GP: When measured, did not make a difference tbh.
    import ldc.intrinsics;
    bool likely(bool b) { return llvm_expect!bool(b, true); }
    bool unlikely(bool b) { return llvm_expect!bool(b, false); }
}
else
{
    bool likely(bool b) { return b; }
    bool unlikely(bool b) { return b; }
}

/* *************************************
   Reading and writing into memory
**************************************/

private bool LZ4_64bits()
{
    return size_t.sizeof == 8;
}

private bool LZ4_isLittleEndian()
{
	version(LittleEndian)
		return true;
	else
		return false;
}


// FUTURE: use gamut.utils functions

private ushort LZ4_readLE16(const(void)* memPtr)
{
	version(LittleEndian)
	{
		return( cast(ushort*)(memPtr))[0];
	}
	else
	{
		const(ubyte)* p = memPtr;
		return cast(ushort)((cast(ushort*)p)[0] + (p[1]<<8));
	}
}

private void LZ4_writeLE16(void* memPtr, ushort value)
{
	version(LittleEndian)
	{
		(cast(ushort*)(memPtr))[0] = value;
	}
	else
	{
		ubyte* p = memPtr;
		p[0] = cast(ubyte) value;
		p[1] = cast(ubyte)(value>>8);
	}
}


private ushort LZ4_read16(const(void)* memPtr)
{
	return (cast(const(ushort)*)(memPtr))[0];
}

private uint LZ4_read32(const(void)* memPtr)
{
	return (cast(const(uint)*)(memPtr))[0];
}

private ulong LZ4_read64(const(void)* memPtr)
{
	return (cast(const(ulong)*)(memPtr))[0];
}

private size_t LZ4_read_ARCH(const(void)* p)
{
	static if (size_t.sizeof == 8) // BUG: this shouldn't work on arm64
	{
		return cast(size_t)LZ4_read64(p);
	}
	else
	{
		return cast(size_t)LZ4_read32(p);
	}
}


private void LZ4_copy4(void* dstPtr, const(void)* srcPtr)
{
	dstPtr[0..4][] = srcPtr[0..4][];
}

private void LZ4_copy8(void* dstPtr, const(void)* srcPtr)
{
	dstPtr[0..8][] = srcPtr[0..8][];
}

/* customized version of memcpy, which may overwrite up to 7 bytes beyond dstEnd */
private void LZ4_wildCopy(void* dstPtr, const(void)* srcPtr, void* dstEnd)
{
	ubyte* d = cast(ubyte*)dstPtr;
	const(ubyte)* s = cast(const(ubyte)*)srcPtr;
	ubyte* e = cast(ubyte*)dstEnd;
	do { LZ4_copy8(d,s); d+=8; s+=8; } while (d<e);
}

/**************************************/

public uint LZ4_NbCommonBytes (size_t val)
{
    import core.bitop: bsf;
    assert(val != 0);
    return bsf(val) >> 3;
}
unittest
{
    assert(LZ4_NbCommonBytes(1) == 0);
    assert(LZ4_NbCommonBytes(4) == 0);
    assert(LZ4_NbCommonBytes(256) == 1);
    assert(LZ4_NbCommonBytes(65534) == 0);
    assert(LZ4_NbCommonBytes(0xffffff) == 0);
    assert(LZ4_NbCommonBytes(0x1000000) == 3);
}


/********************************
   Common functions
********************************/

private uint LZ4_count(const(ubyte)* pIn, const(ubyte)* pMatch, const(ubyte)* pInLimit)
{
	const(ubyte)* pStart = pIn;

	while (likely(pIn<pInLimit-(STEPSIZE-1)))
	{
		size_t diff = LZ4_read_ARCH(pMatch) ^ LZ4_read_ARCH(pIn);
		if (!diff) { pIn+=STEPSIZE; pMatch+=STEPSIZE; continue; }
		pIn += LZ4_NbCommonBytes(diff);
		return cast(uint)(pIn - pStart);
	}

	static if (size_t.sizeof == 8) 
	{
		if ((pIn<(pInLimit-3)) && (LZ4_read32(pMatch) == LZ4_read32(pIn))) 
		{ 
			pIn+=4; 
			pMatch+=4; 
		}
	}
	if ((pIn<(pInLimit-1)) && (LZ4_read16(pMatch) == LZ4_read16(pIn))) { pIn+=2; pMatch+=2; }
	if ((pIn<pInLimit) && (*pMatch == *pIn)) pIn++;
	return cast(uint)(pIn - pStart);
}

/* *************************************
   Local Utils
**************************************/
int LZ4_versionNumber () { return LZ4_VERSION_NUMBER; }
int LZ4_compressBound(int isize)  { return LZ4_COMPRESSBOUND(isize); }


/* *************************************
   Local Structures and types
**************************************/
private
{
struct LZ4_stream_t_internal {
	uint[HASH_SIZE_U32] hashTable;
	uint currentOffset;
	uint initCheck;
	const(ubyte)* dictionary;
	const(ubyte)* bufferStart;
	uint dictSize;
}

enum : int { notLimited = 0, limitedOutput = 1 }
alias int limitedOutput_directive;
enum : int { byPtr, byU32, byU16 }
alias int tableType_t;

enum : int { noDict = 0, withPrefix64k, usingExtDict }
alias int dict_directive;
enum : int { noDictIssue = 0, dictSmall }
alias int dictIssue_directive;

enum : int { endOnOutputSize = 0, endOnInputSize = 1 }
alias int endCondition_directive;
enum : int { full = 0, partial = 1 }
alias int earlyEnd_directive;

}

/* *******************************
   Compression functions
********************************/

private uint LZ4_hashSequence(uint sequence, tableType_t tableType)
{
	if (tableType == byU16)
		return (((sequence) * 2654435761U) >> ((MINMATCH*8)-(LZ4_HASHLOG+1)));
	else
		return (((sequence) * 2654435761U) >> ((MINMATCH*8)-LZ4_HASHLOG));
}

private uint LZ4_hashPosition(const(ubyte)* p, tableType_t tableType) { return LZ4_hashSequence(LZ4_read32(p), tableType); }

private void LZ4_putPositionOnHash(const(ubyte)* p, uint h, void* tableBase, tableType_t tableType, const(ubyte)* srcBase)
{
	switch (tableType)
	{
	case byPtr: { const(ubyte)** hashTable = cast(const(ubyte)**)tableBase; hashTable[h] = p; return; }
	case byU32: { uint* hashTable = cast(uint*) tableBase; hashTable[h] = cast(uint)(p-srcBase); return; }
	case byU16: { ushort* hashTable = cast(ushort*) tableBase; hashTable[h] = cast(ushort)(p-srcBase); return; }
	default: assert(0);
	}
}

private void LZ4_putPosition(const(ubyte)* p, void* tableBase, tableType_t tableType, const(ubyte)* srcBase)
{
	uint h = LZ4_hashPosition(p, tableType);
	LZ4_putPositionOnHash(p, h, tableBase, tableType, srcBase);
}

private const(ubyte)* LZ4_getPositionOnHash(uint h, void* tableBase, tableType_t tableType, const(ubyte)* srcBase)
{
	if (tableType == byPtr) { const(ubyte)** hashTable = cast(const(ubyte)**) tableBase; return hashTable[h]; }
	if (tableType == byU32) { uint* hashTable = cast(uint*) tableBase; return hashTable[h] + srcBase; }
	{ ushort* hashTable = cast(ushort*) tableBase; return hashTable[h] + srcBase; }   /* default, to ensure a return */
}

private const(ubyte)* LZ4_getPosition(const(ubyte)* p, void* tableBase, tableType_t tableType, const(ubyte)* srcBase)
{
	uint h = LZ4_hashPosition(p, tableType);
	return LZ4_getPositionOnHash(h, tableBase, tableType, srcBase);
}

private int LZ4_compress_generic(
				 void* ctx,
				 const(char)* source,
				 char* dest,
				 int inputSize,
				 int maxOutputSize,
				 limitedOutput_directive outputLimited,
				 tableType_t tableType,
				 dict_directive dict,
				 dictIssue_directive dictIssue)
{
	LZ4_stream_t_internal* dictPtr = cast(LZ4_stream_t_internal*)ctx;

	const(ubyte)* ip = cast(const(ubyte)*) source;
	const(ubyte)* base;
	const(ubyte)* lowLimit;
	const(ubyte)* lowRefLimit = ip - dictPtr.dictSize;
	const(ubyte)* dictionary = dictPtr.dictionary;
	const(ubyte)* dictEnd = dictionary + dictPtr.dictSize;
	const(size_t) dictDelta = dictEnd - cast(const(ubyte)*)source;
	const(ubyte)* anchor = cast(const(ubyte)*) source;
	const(ubyte)* iend = ip + inputSize;
	const(ubyte)* mflimit = iend - MFLIMIT;
	const(ubyte)* matchlimit = iend - LASTLITERALS;

	ubyte* op = cast(ubyte*) dest;
	ubyte* olimit = op + maxOutputSize;

	uint forwardH;
	size_t refDelta=0;

	/* Init conditions */
	if (cast(uint)inputSize > cast(uint)LZ4_MAX_INPUT_SIZE) return 0;          /* Unsupported input size, too large (or negative) */
	switch(dict)
	{
	case noDict:
		base = cast(const(ubyte)*)source;
		lowLimit = cast(const(ubyte)*)source;
		break;
	case withPrefix64k:
		base = cast(const(ubyte)*)source - dictPtr.currentOffset;
		lowLimit = cast(const(ubyte)*)source - dictPtr.dictSize;
		break;
	case usingExtDict:
		base = cast(const(ubyte)*)source - dictPtr.currentOffset;
		lowLimit = cast(const(ubyte)*)source;
		break;
	default:
		base = cast(const(ubyte)*)source;
		lowLimit = cast(const(ubyte)*)source;
		break;
	}
	if ((tableType == byU16) && (inputSize>=LZ4_64Klimit)) return 0;   /* Size too large (not within 64K limit) */
	if (inputSize<LZ4_minLength) goto _last_literals;                  /* Input too small, no compression (all literals) */

	/* First ubyte */
	LZ4_putPosition(ip, ctx, tableType, base);
	ip++; forwardH = LZ4_hashPosition(ip, tableType);

	/* Main Loop */
	for ( ; ; )
	{
		const(ubyte)* match;
		ubyte* token;
		{
			const(ubyte)* forwardIp = ip;
			uint step=1;
			uint searchMatchNb = (1U << LZ4_skipTrigger);

			/* Find a match */
			do {
				uint h = forwardH;
				ip = forwardIp;
				forwardIp += step;
				step = searchMatchNb++ >> LZ4_skipTrigger;

				if (unlikely(forwardIp > mflimit)) goto _last_literals;

				match = LZ4_getPositionOnHash(h, ctx, tableType, base);
				if (dict==usingExtDict)
				{
					if (match<cast(const(ubyte)*)source)
					{
						refDelta = dictDelta;
						lowLimit = dictionary;
					}
					else
					{
						refDelta = 0;
						lowLimit = cast(const(ubyte)*)source;
					}
				}
				forwardH = LZ4_hashPosition(forwardIp, tableType);
				LZ4_putPositionOnHash(ip, h, ctx, tableType, base);

			} while ( ((dictIssue==dictSmall) ? (match < lowRefLimit) : 0)
				|| ((tableType==byU16) ? 0 : (match + MAX_DISTANCE < ip))
				|| (LZ4_read32(match+refDelta) != LZ4_read32(ip)) );
		}

		/* Catch up */
		while ((ip>anchor) && (match+refDelta > lowLimit) && (unlikely(ip[-1]==match[refDelta-1]))) { ip--; match--; }

		{
			/* Encode Literal length */
			uint litLength = cast(uint)(ip - anchor);
			token = op++;
			if ((outputLimited) && (unlikely(op + litLength + (2 + 1 + LASTLITERALS) + (litLength/255) > olimit)))
				return 0;   /* Check output limit */
			if (litLength>=RUN_MASK)
			{
				int len = cast(int)litLength-RUN_MASK;
				*token=(RUN_MASK<<ML_BITS);
				for(; len >= 255 ; len-=255) *op++ = 255;
				*op++ = cast(ubyte)len;
			}
			else *token = cast(ubyte)(litLength<<ML_BITS);

			/* Copy Literals */
			LZ4_wildCopy(op, anchor, op+litLength);
			op+=litLength;
		}

_next_match:
		/* Encode Offset */
		LZ4_writeLE16(op, cast(ushort)(ip-match)); op+=2;

		/* Encode MatchLength */
		{
			uint matchLength;

			if ((dict==usingExtDict) && (lowLimit==dictionary))
			{
				const(ubyte)* limit;
				match += refDelta;
				limit = ip + (dictEnd-match);
				if (limit > matchlimit) limit = matchlimit;
				matchLength = LZ4_count(ip+MINMATCH, match+MINMATCH, limit);
				ip += MINMATCH + matchLength;
				if (ip==limit)
				{
					uint more = LZ4_count(ip, cast(const(ubyte)*)source, matchlimit);
					matchLength += more;
					ip += more;
				}
			}
			else
			{
				matchLength = LZ4_count(ip+MINMATCH, match+MINMATCH, matchlimit);
				ip += MINMATCH + matchLength;
			}

			if ((outputLimited) && (unlikely(op + (1 + LASTLITERALS) + (matchLength>>8) > olimit)))
				return 0;    /* Check output limit */
			if (matchLength>=ML_MASK)
			{
				*token += ML_MASK;
				matchLength -= ML_MASK;
				for (; matchLength >= 510 ; matchLength-=510) { *op++ = 255; *op++ = 255; }
				if (matchLength >= 255) { matchLength-=255; *op++ = 255; }
				*op++ = cast(ubyte)matchLength;
			}
			else *token += cast(ubyte)(matchLength);
		}

		anchor = ip;

		/* Test end of chunk */
		if (ip > mflimit) break;

		/* Fill table */
		LZ4_putPosition(ip-2, ctx, tableType, base);

		/* Test next position */
		match = LZ4_getPosition(ip, ctx, tableType, base);
		if (dict==usingExtDict)
		{
			if (match<cast(const(ubyte)*)source)
			{
				refDelta = dictDelta;
				lowLimit = dictionary;
			}
			else
			{
				refDelta = 0;
				lowLimit = cast(const(ubyte)*)source;
			}
		}
		LZ4_putPosition(ip, ctx, tableType, base);
		if ( ((dictIssue==dictSmall) ? (match>=lowRefLimit) : 1)
			&& (match+MAX_DISTANCE>=ip)
			&& (LZ4_read32(match+refDelta)==LZ4_read32(ip)) )
		{ token=op++; *token=0; goto _next_match; }

		/* Prepare next loop */
		forwardH = LZ4_hashPosition(++ip, tableType);
	}

_last_literals:
	/* Encode Last Literals */
	{
		int lastRun = cast(int)(iend - anchor);
		if ((outputLimited) && ((cast(char*)op - dest) + lastRun + 1 + ((lastRun+255-RUN_MASK)/255) > cast(uint)maxOutputSize))
			return 0;   /* Check output limit */
		if (lastRun>=cast(int)RUN_MASK) { *op++=(RUN_MASK<<ML_BITS); lastRun-=RUN_MASK; for(; lastRun >= 255 ; lastRun-=255) *op++ = 255; *op++ = cast(ubyte) lastRun; }
		else *op++ = cast(ubyte)(lastRun<<ML_BITS);
		memcpy(op, anchor, iend - anchor);
		op += iend-anchor;
	}

	/* End */
	return cast(int) ((cast(char*)op)-dest);
}

/// -
int LZ4_compress(const(char)* source, char* dest, int inputSize)
{
	ulong[LZ4_STREAMSIZE_U64] ctx;
	int result;

	if (inputSize < LZ4_64Klimit)
		result = LZ4_compress_generic(cast(void*)ctx, source, dest, inputSize, 0, notLimited, byU16, noDict, noDictIssue);
	else
		result = LZ4_compress_generic(cast(void*)ctx, source, dest, inputSize, 0, notLimited, LZ4_64bits() ? byU32 : byPtr, noDict, noDictIssue);
	return result;
}
/// -
int LZ4_compress_limitedOutput(const(char)* source, char* dest, int inputSize, int maxOutputSize)
{
	ulong[LZ4_STREAMSIZE_U64] ctx;
	int result;

	if (inputSize < LZ4_64Klimit)
		result = LZ4_compress_generic(cast(void*)ctx, source, dest, inputSize, maxOutputSize, limitedOutput, byU16, noDict, noDictIssue);
	else
		result = LZ4_compress_generic(cast(void*)ctx, source, dest, inputSize, maxOutputSize, limitedOutput, LZ4_64bits() ? byU32 : byPtr, noDict, noDictIssue);
	return result;
}


/* ****************************************
   Experimental : Streaming functions
*****************************************/

/**
 * LZ4_initStream
 * Use this function once, to init a newly allocated LZ4_stream_t structure
 * Return : 1 if OK, 0 if error
 */
void LZ4_resetStream (LZ4_stream_t* LZ4_stream)
{
	MEM_INIT(LZ4_stream, 0, LZ4_stream_t.sizeof);
}
/// -
LZ4_stream_t* LZ4_createStream()
{
	LZ4_stream_t* lz4s = cast(LZ4_stream_t*)ALLOCATOR(8, LZ4_STREAMSIZE_U64);
	static assert(LZ4_STREAMSIZE >= LZ4_stream_t_internal.sizeof);    /* A compilation error here means LZ4_STREAMSIZE is not large enough */
	LZ4_resetStream(lz4s);
	return lz4s;
}
/// -
int LZ4_freeStream (LZ4_stream_t* LZ4_stream)
{
	FREEMEM(LZ4_stream);
	return (0);
}

/// -
int LZ4_loadDict (LZ4_stream_t* LZ4_dict, const(char)* dictionary, int dictSize)
{
	LZ4_stream_t_internal* dict = cast(LZ4_stream_t_internal*) LZ4_dict;
	const(ubyte)* p = cast(const(ubyte)*)dictionary;
	const(ubyte)* dictEnd = p + dictSize;
	const(ubyte)* base;

	if (dict.initCheck) LZ4_resetStream(LZ4_dict);                         /* Uninitialized structure detected */

	if (dictSize < MINMATCH)
	{
		dict.dictionary = null;
		dict.dictSize = 0;
		return 0;
	}

	if (p <= dictEnd - 64*KB) p = dictEnd - 64*KB;
	base = p - dict.currentOffset;
	dict.dictionary = p;
	dict.dictSize = cast(uint)(dictEnd - p);
	dict.currentOffset += dict.dictSize;

	while (p <= dictEnd-MINMATCH)
	{
		LZ4_putPosition(p, dict, byU32, base);
		p+=3;
	}

	return dict.dictSize;
}


private void LZ4_renormDictT(LZ4_stream_t_internal* LZ4_dict, const(ubyte)* src)
{
	if ((LZ4_dict.currentOffset > 0x80000000) ||
		(cast(size_t)LZ4_dict.currentOffset > cast(size_t)src))   /* address space overflow */
	{
		/* rescale hash table */
		uint delta = LZ4_dict.currentOffset - 64*KB;
		const(ubyte)* dictEnd = LZ4_dict.dictionary + LZ4_dict.dictSize;
		int i;
		for (i=0; i<HASH_SIZE_U32; i++)
		{
			if (LZ4_dict.hashTable[i] < delta) LZ4_dict.hashTable[i]=0;
			else LZ4_dict.hashTable[i] -= delta;
		}
		LZ4_dict.currentOffset = 64*KB;
		if (LZ4_dict.dictSize > 64*KB) LZ4_dict.dictSize = 64*KB;
		LZ4_dict.dictionary = dictEnd - LZ4_dict.dictSize;
	}
}

/// -
int LZ4_compress_continue_generic (void* LZ4_stream, const(char)* source, char* dest, int inputSize,
												int maxOutputSize, limitedOutput_directive limit)
{
	LZ4_stream_t_internal* streamPtr = cast(LZ4_stream_t_internal*)LZ4_stream;
	const(ubyte)* dictEnd = streamPtr.dictionary + streamPtr.dictSize;

	const(ubyte)* smallest = cast(const(ubyte)*) source;
	if (streamPtr.initCheck) return 0;   /* Uninitialized structure detected */
	if ((streamPtr.dictSize>0) && (smallest>dictEnd)) smallest = dictEnd;
	LZ4_renormDictT(streamPtr, smallest);

	/* Check overlapping input/dictionary space */
	{
		const(ubyte)* sourceEnd = cast(const(ubyte)*) source + inputSize;
		if ((sourceEnd > streamPtr.dictionary) && (sourceEnd < dictEnd))
		{
			streamPtr.dictSize = cast(uint)(dictEnd - sourceEnd);
			if (streamPtr.dictSize > 64*KB) streamPtr.dictSize = 64*KB;
			if (streamPtr.dictSize < 4) streamPtr.dictSize = 0;
			streamPtr.dictionary = dictEnd - streamPtr.dictSize;
		}
	}

	/* prefix mode : source data follows dictionary */
	if (dictEnd == cast(const(ubyte)*)source)
	{
		int result;
		if ((streamPtr.dictSize < 64*KB) && (streamPtr.dictSize < streamPtr.currentOffset))
			result = LZ4_compress_generic(LZ4_stream, source, dest, inputSize, maxOutputSize, limit, byU32, withPrefix64k, dictSmall);
		else
			result = LZ4_compress_generic(LZ4_stream, source, dest, inputSize, maxOutputSize, limit, byU32, withPrefix64k, noDictIssue);
		streamPtr.dictSize += cast(uint)inputSize;
		streamPtr.currentOffset += cast(uint)inputSize;
		return result;
	}

	/* external dictionary mode */
	{
		int result;
		if ((streamPtr.dictSize < 64*KB) && (streamPtr.dictSize < streamPtr.currentOffset))
			result = LZ4_compress_generic(LZ4_stream, source, dest, inputSize, maxOutputSize, limit, byU32, usingExtDict, dictSmall);
		else
			result = LZ4_compress_generic(LZ4_stream, source, dest, inputSize, maxOutputSize, limit, byU32, usingExtDict, noDictIssue);
		streamPtr.dictionary = cast(const(ubyte)*)source;
		streamPtr.dictSize = cast(uint)inputSize;
		streamPtr.currentOffset += cast(uint)inputSize;
		return result;
	}
}
/// -
int LZ4_compress_continue (LZ4_stream_t* LZ4_stream, const(char)* source, char* dest, int inputSize)
{
	return LZ4_compress_continue_generic(LZ4_stream, source, dest, inputSize, 0, notLimited);
}
/// -
int LZ4_compress_limitedOutput_continue (LZ4_stream_t* LZ4_stream, const(char)* source, char* dest, int inputSize, int maxOutputSize)
{
	return LZ4_compress_continue_generic(LZ4_stream, source, dest, inputSize, maxOutputSize, limitedOutput);
}


/** Hidden debug function, to force separate dictionary mode */
int LZ4_compress_forceExtDict (LZ4_stream_t* LZ4_dict, const(char)* source, char* dest, int inputSize)
{
	LZ4_stream_t_internal* streamPtr = cast(LZ4_stream_t_internal*)LZ4_dict;
	int result;
	const(ubyte)* dictEnd = streamPtr.dictionary + streamPtr.dictSize;

	const(ubyte)* smallest = dictEnd;
	if (smallest > cast(const(ubyte)*) source) smallest = cast(const(ubyte)*) source;
	LZ4_renormDictT(cast(LZ4_stream_t_internal*)LZ4_dict, smallest);

	result = LZ4_compress_generic(LZ4_dict, source, dest, inputSize, 0, notLimited, byU32, usingExtDict, noDictIssue);

	streamPtr.dictionary = cast(const(ubyte)*)source;
	streamPtr.dictSize = cast(uint)inputSize;
	streamPtr.currentOffset += cast(uint)inputSize;

	return result;
}

/// -
int LZ4_saveDict (LZ4_stream_t* LZ4_dict, char* safeBuffer, int dictSize)
{
	LZ4_stream_t_internal* dict = cast(LZ4_stream_t_internal*) LZ4_dict;
	const(ubyte)* previousDictEnd = dict.dictionary + dict.dictSize;

	if (cast(uint)dictSize > 64*KB) dictSize = 64*KB;   /* useless to define a dictionary > 64*KB */
	if (cast(uint)dictSize > dict.dictSize) dictSize = dict.dictSize;

	memmove(safeBuffer, previousDictEnd - dictSize, dictSize);

	dict.dictionary = cast(const(ubyte)*)safeBuffer;
	dict.dictSize = cast(uint)dictSize;

	return dictSize;
}



/* ***************************
   Decompression functions
****************************/
/**
 * This generic decompression function cover all use cases.
 * It shall be instantiated several times, using different sets of directives
 * Note that it is essential this generic function is really inlined,
 * in order to remove useless branches during compilation optimization.
 */
int LZ4_decompress_generic(
				 const(char)* source,
				 char* dest,
				 int inputSize,
				 int outputSize,         /* If endOnInput==endOnInputSize, this value is the max size of Output Buffer. */

				 int endOnInput,         /* endOnOutputSize, endOnInputSize */
				 int partialDecoding,    /* full, partial */
				 int targetOutputSize,   /* only used if partialDecoding==partial */
				 int dict,               /* noDict, withPrefix64k, usingExtDict */
				 const(ubyte)* lowPrefix,  /* == dest if dict == noDict */
				 const(ubyte)* dictStart,  /* only if dict==usingExtDict */
				 const size_t dictSize         /* note : = 0 if noDict */
				 )
{
	/* Local Variables */
	const(ubyte)*  ip = cast(const(ubyte)*) source;
	const(ubyte)* iend = ip + inputSize;

	ubyte* op = cast(ubyte*) dest;
	ubyte* oend = op + outputSize;
	ubyte* cpy;
	ubyte* oexit = op + targetOutputSize;
	const(ubyte)* lowLimit = lowPrefix - dictSize;

	const(ubyte)* dictEnd = cast(const(ubyte)*)dictStart + dictSize;
	const size_t[8] dec32table = [4, 1, 2, 1, 4, 4, 4, 4];
	const size_t[8] dec64table = [0, 0, 0, cast(size_t)-1, 0, 1, 2, 3];

	const int safeDecode = (endOnInput==endOnInputSize);
	const int checkOffset = ((safeDecode) && (dictSize < cast(int)(64*KB)));


	/* Special cases */
	if ((partialDecoding) && (oexit> oend-MFLIMIT)) oexit = oend-MFLIMIT;                         /* targetOutputSize too high => decode everything */
	if ((endOnInput) && (unlikely(outputSize==0))) return ((inputSize==1) && (*ip==0)) ? 0 : -1;  /* Empty output buffer */
	if ((!endOnInput) && (unlikely(outputSize==0))) return (*ip==0?1:-1);


	/* Main Loop */
	while (true)
	{
		uint token;
		size_t length;
		const(ubyte)* match;

		/* get literal length */
		token = *ip++;
		if ((length=(token>>ML_BITS)) == RUN_MASK)
		{
			uint s;
			do
			{
				s = *ip++;
				length += s;
			}
			while (likely((endOnInput)?ip<iend-RUN_MASK:1) && (s==255));
			if ((safeDecode) && unlikely(cast(size_t)(op+length)<cast(size_t)(op)))
            {
                goto _output_error;   /* overflow detection */
            }
			if ((safeDecode) && unlikely(cast(size_t)(ip+length)<cast(size_t)(ip))) 
            {
                goto _output_error;   /* overflow detection */
            }
		}

		/* copy literals */
		cpy = op+length;
		if (((endOnInput) && ((cpy>(partialDecoding?oexit:oend-MFLIMIT)) || (ip+length>iend-(2+1+LASTLITERALS))) )
			|| ((!endOnInput) && (cpy>oend-COPYLENGTH)))
		{
			if (partialDecoding)
			{
				if (cpy > oend) goto _output_error;                           /* Error : write attempt beyond end of output buffer */
				if ((endOnInput) && (ip+length > iend)) 
                {
                    goto _output_error;   /* Error : read attempt beyond end of input buffer */
                }
			}
			else
			{
				if ((!endOnInput) && (cpy != oend))
                {
                    goto _output_error;       /* Error : block decoding must stop exactly there */
                }
				if ((endOnInput) && ((ip+length != iend) || (cpy > oend)))
                {
                    goto _output_error;   /* Error : input must be consumed */
                }
			}
			memcpy(op, ip, length);
			ip += length;
			op += length;
			break;     /* Necessarily EOF, due to parsing restrictions */
		}
		LZ4_wildCopy(op, ip, cpy);
		ip += length; op = cpy;

		/* get offset */
		match = cpy - LZ4_readLE16(ip); ip+=2;
		if ((checkOffset) && (unlikely(match < lowLimit)))
        {
            goto _output_error;   /* Error : offset outside destination buffer */
        }

		/* get matchlength */
		length = token & ML_MASK;
		if (length == ML_MASK)
		{
			uint s;
			do
			{
				if ((endOnInput) && (ip > iend-LASTLITERALS))
                {
                    goto _output_error;
                }
				s = *ip++;
				length += s;
			} while (s==255);
			if ((safeDecode) && unlikely(cast(size_t)(op+length)<cast(size_t)op)) goto _output_error;   /* overflow detection */
		}
		length += MINMATCH;

		/* check external dictionary */
		if ((dict==usingExtDict) && (match < lowPrefix))
		{
			if (unlikely(op+length > oend-LASTLITERALS))
            {
                goto _output_error;   /* doesn't respect parsing restriction */
            }

			if (length <= cast(size_t)(lowPrefix-match))
			{
				/* match can be copied as a single segment from external dictionary */
				match = dictEnd - (lowPrefix-match);
				memcpy(op, match, length);
				op += length;
			}
			else
			{
				/* match encompass external dictionary and current segment */
				size_t copySize = cast(size_t)(lowPrefix-match);
				memcpy(op, dictEnd - copySize, copySize);
				op += copySize;
				copySize = length - copySize;
				if (copySize > cast(size_t)(op-lowPrefix))   /* overlap within current segment */
				{
					ubyte* endOfMatch = op + copySize;
					const(ubyte)* copyFrom = lowPrefix;
					while (op < endOfMatch) *op++ = *copyFrom++;
				}
				else
				{
					memcpy(op, lowPrefix, copySize);
					op += copySize;
				}
			}
			continue;
		}

		/* copy repeated sequence */
		cpy = op + length;
		if (unlikely((op-match)<8))
		{
			const size_t dec64 = dec64table[op-match];
			op[0] = match[0];
			op[1] = match[1];
			op[2] = match[2];
			op[3] = match[3];
			match += dec32table[op-match];
			LZ4_copy4(op+4, match);
			op += 8; match -= dec64;
		} else { LZ4_copy8(op, match); op+=8; match+=8; }

		if (unlikely(cpy>oend-12))
		{
			if (cpy > oend-LASTLITERALS)
            {
                goto _output_error;    /* Error : last LASTLITERALS bytes must be literals */
            }
			if (op < oend-8)
			{
				LZ4_wildCopy(op, match, oend-8);
				match += (oend-8) - op;
				op = oend-8;
			}
			while (op<cpy) *op++ = *match++;
		}
		else
			LZ4_wildCopy(op, match, cpy);
		op=cpy;   /* correction */
	}

	/* end of decoding */
	if (endOnInput)
	   return cast(int) ((cast(char*)op)-dest);     /* Nb of output bytes decoded */
	else
	   return cast(int) ((cast(char*)ip)-source);   /* Nb of input bytes read */

	/* Overflow error detected */
_output_error:
	return cast(int) (-((cast(char*)ip)-source))-1;
}

/// -
int LZ4_decompress_safe(const(char)* source, char* dest, int compressedSize, int maxDecompressedSize)
{
	return LZ4_decompress_generic(source, dest, compressedSize, maxDecompressedSize, endOnInputSize, full, 0, noDict, cast(ubyte*)dest, null, 0);
}
/// -
int LZ4_decompress_safe_partial(const(char)* source, char* dest, int compressedSize, int targetOutputSize, int maxDecompressedSize)
{
	return LZ4_decompress_generic(source, dest, compressedSize, maxDecompressedSize, endOnInputSize, partial, targetOutputSize, noDict, cast(ubyte*)dest, null, 0);
}
/// -
int LZ4_decompress_fast(const(char)* source, char* dest, int originalSize)
{
	return LZ4_decompress_generic(source, dest, 0, originalSize, endOnOutputSize, full, 0, withPrefix64k, cast(ubyte*)(dest - 64*KB), null, 64*KB);
}
/* streaming decompression functions */
private struct LZ4_streamDecode_t_internal
{
	ubyte* externalDict;
	size_t extDictSize;
	ubyte* prefixEnd;
	size_t prefixSize;
}

/**
 * If you prefer dynamic allocation methods,
 * LZ4_createStreamDecode()
 * provides a pointer (void*) towards an initialized LZ4_streamDecode_t structure.
 */
LZ4_streamDecode_t* LZ4_createStreamDecode()
{
	LZ4_streamDecode_t* lz4s = cast(LZ4_streamDecode_t*) ALLOCATOR(ulong.sizeof, LZ4_STREAMDECODESIZE_U64);
	return lz4s;
}
///ditto
int LZ4_freeStreamDecode (LZ4_streamDecode_t* LZ4_stream)
{
	FREEMEM(LZ4_stream);
	return 0;
}

/**
 * LZ4_setStreamDecode
 * Use this function to instruct where to find the dictionary
 * This function is not necessary if previous data is still available where it was decoded.
 * Loading a size of 0 is allowed (same effect as no dictionary).
 * Return : 1 if OK, 0 if error
 */
int LZ4_setStreamDecode (LZ4_streamDecode_t* LZ4_streamDecode, const(char)* dictionary, int dictSize)
{
	LZ4_streamDecode_t_internal* lz4sd = cast(LZ4_streamDecode_t_internal*) LZ4_streamDecode;
	lz4sd.prefixSize = cast(size_t) dictSize;
	lz4sd.prefixEnd = cast(ubyte*) dictionary + dictSize;
	lz4sd.externalDict = null;
	lz4sd.extDictSize  = 0;
	return 1;
}

/**
*_continue() :
	These decoding functions allow decompression of multiple blocks in "streaming" mode.
	Previously decoded blocks must still be available at the memory position where they were decoded.
	If it's not possible, save the relevant part of decoded data into a safe buffer,
	and indicate where it stands using LZ4_setStreamDecode()
*/
int LZ4_decompress_safe_continue (LZ4_streamDecode_t* LZ4_streamDecode, const(char)* source, char* dest, int compressedSize, int maxOutputSize)
{
	LZ4_streamDecode_t_internal* lz4sd = cast(LZ4_streamDecode_t_internal*) LZ4_streamDecode;
	int result;

	if (lz4sd.prefixEnd == cast(ubyte*)dest)
	{
		result = LZ4_decompress_generic(source, dest, compressedSize, maxOutputSize,
										endOnInputSize, full, 0,
										usingExtDict, lz4sd.prefixEnd - lz4sd.prefixSize, lz4sd.externalDict, lz4sd.extDictSize);
		if (result <= 0) return result;
		lz4sd.prefixSize += result;
		lz4sd.prefixEnd  += result;
	}
	else
	{
		lz4sd.extDictSize = lz4sd.prefixSize;
		lz4sd.externalDict = lz4sd.prefixEnd - lz4sd.extDictSize;
		result = LZ4_decompress_generic(source, dest, compressedSize, maxOutputSize,
										endOnInputSize, full, 0,
										usingExtDict, cast(ubyte*)dest, lz4sd.externalDict, lz4sd.extDictSize);
		if (result <= 0) return result;
		lz4sd.prefixSize = result;
		lz4sd.prefixEnd  = cast(ubyte*)dest + result;
	}

	return result;
}
///ditto
int LZ4_decompress_fast_continue (LZ4_streamDecode_t* LZ4_streamDecode, const(char)* source, char* dest, int originalSize)
{
	LZ4_streamDecode_t_internal* lz4sd = cast(LZ4_streamDecode_t_internal*) LZ4_streamDecode;
	int result;

	if (lz4sd.prefixEnd == cast(ubyte*)dest)
	{
		result = LZ4_decompress_generic(source, dest, 0, originalSize,
										endOnOutputSize, full, 0,
										usingExtDict, lz4sd.prefixEnd - lz4sd.prefixSize, lz4sd.externalDict, lz4sd.extDictSize);
		if (result <= 0) return result;
		lz4sd.prefixSize += originalSize;
		lz4sd.prefixEnd  += originalSize;
	}
	else
	{
		lz4sd.extDictSize = lz4sd.prefixSize;
		lz4sd.externalDict = cast(ubyte*)dest - lz4sd.extDictSize;
		result = LZ4_decompress_generic(source, dest, 0, originalSize,
										endOnOutputSize, full, 0,
										usingExtDict, cast(ubyte*)dest, lz4sd.externalDict, lz4sd.extDictSize);
		if (result <= 0) return result;
		lz4sd.prefixSize = originalSize;
		lz4sd.prefixEnd  = cast(ubyte*)dest + originalSize;
	}

	return result;
}


/**
Advanced decoding functions :
*_usingDict() :
	These decoding functions work the same as "_continue" ones,
	the dictionary must be explicitly provided within parameters
*/

int LZ4_decompress_usingDict_generic(const(char)* source, char* dest, int compressedSize, int maxOutputSize, int safe, const(char)* dictStart, int dictSize)
{
	if (dictSize==0)
		return LZ4_decompress_generic(source, dest, compressedSize, maxOutputSize, safe, full, 0, noDict, cast(ubyte*)dest, null, 0);
	if (dictStart+dictSize == dest)
	{
		if (dictSize >= cast(int)(64*KB - 1))
			return LZ4_decompress_generic(source, dest, compressedSize, maxOutputSize, safe, full, 0, withPrefix64k, cast(ubyte*)dest-64*KB, null, 0);
		return LZ4_decompress_generic(source, dest, compressedSize, maxOutputSize, safe, full, 0, noDict, cast(ubyte*)dest-dictSize, null, 0);
	}
	return LZ4_decompress_generic(source, dest, compressedSize, maxOutputSize, safe, full, 0, usingExtDict, cast(ubyte*)dest, cast(ubyte*)dictStart, dictSize);
}
///ditto
int LZ4_decompress_safe_usingDict(const(char)* source, char* dest, int compressedSize, int maxOutputSize, const(char)* dictStart, int dictSize)
{
	return LZ4_decompress_usingDict_generic(source, dest, compressedSize, maxOutputSize, 1, dictStart, dictSize);
}
///ditto
int LZ4_decompress_fast_usingDict(const(char)* source, char* dest, int originalSize, const(char)* dictStart, int dictSize)
{
	return LZ4_decompress_usingDict_generic(source, dest, 0, originalSize, 0, dictStart, dictSize);
}

/** debug function */
int LZ4_decompress_safe_forceExtDict(const(char)* source, char* dest, int compressedSize, int maxOutputSize, const(char)* dictStart, int dictSize)
{
	return LZ4_decompress_generic(source, dest, compressedSize, maxOutputSize, endOnInputSize, full, 0, usingExtDict, cast(ubyte*)dest, cast(ubyte*)dictStart, dictSize);
}
