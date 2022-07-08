/*
 * Helper macros/constants from C
*/
module gamut.codecs.ctypes;

private import core.stdc.stdlib;
private import core.stdc.string;
private import std.exception;

alias ALLOCATOR = calloc;
alias FREEMEM = free;
alias MEM_INIT = memset;

enum size_t STEPSIZE = size_t.sizeof;
deprecated enum bool LZ4_UNALIGNED_ACCESS = true;

enum int cLZ4_MEMORY_USAGE    =  14;
enum int MINMATCH = 4;
enum int COPYLENGTH = 8;
enum int LASTLITERALS = 5;
enum int MFLIMIT = (COPYLENGTH+MINMATCH);
enum int LZ4_minLength = (MFLIMIT+1);

enum int KB = (1 <<10);
enum int MB = (1 <<20);
enum int GB = (1U<<30);

enum int MAXD_LOG = 16;
enum int MAX_DISTANCE = ((1 << MAXD_LOG) - 1);

enum int ML_BITS  = 4;
enum int ML_MASK  = ((1U<<ML_BITS)-1);
enum int RUN_BITS = (8-ML_BITS);
enum int RUN_MASK = ((1U<<RUN_BITS)-1);

enum int LZ4_HASHLOG   = (cLZ4_MEMORY_USAGE-2);
enum int HASHTABLESIZE = (1 << cLZ4_MEMORY_USAGE);
enum int HASH_SIZE_U32 = (1 << LZ4_HASHLOG);       /* required as macro for static allocation */

enum int LZ4_64Klimit = ((64 *KB) + (MFLIMIT-1));
enum uint LZ4_skipTrigger = 6;  /* Increase this value ==> compression run slower on incompressible data */


