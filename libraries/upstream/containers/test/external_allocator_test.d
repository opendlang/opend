module external_allocator_test;

import containers.cyclicbuffer;
import containers.dynamicarray;
import containers.hashmap;
import containers.hashset;
import containers.immutablehashset;
import containers.openhashset;
import containers.simdset;
import containers.slist;
import containers.treemap;
import containers.ttree;
import containers.unrolledlist;
import std.meta : AliasSeq;
import std.range.primitives : walkLength;
import std.stdio : stdout;
import std.experimental.allocator.building_blocks.allocator_list : AllocatorList;
import std.experimental.allocator.building_blocks.free_list : FreeList;
import std.experimental.allocator.building_blocks.region : Region;
import std.experimental.allocator.building_blocks.stats_collector : StatsCollector;
import std.experimental.allocator.mallocator : Mallocator;

// Chosen for a very important and completely undocumented reason
private enum VERY_SPECIFIC_NUMBER = 371;

private void testSingle(alias Container, Allocator)(Allocator allocator)
{
	auto intMap = Container!(int, Allocator)(allocator);
	foreach (i; 0 .. VERY_SPECIFIC_NUMBER)
		intMap.insert(i);
	assert(intMap.length == VERY_SPECIFIC_NUMBER);
}

private void testDouble(alias Container, Allocator)(Allocator allocator)
{
	auto intMap = Container!(int, int, Allocator)(allocator);
	foreach (i; 0 .. VERY_SPECIFIC_NUMBER)
		intMap[i] = VERY_SPECIFIC_NUMBER - i;
	assert(intMap.length == VERY_SPECIFIC_NUMBER);
}

version (D_InlineAsm_X86_64)
{
	alias SingleContainers = AliasSeq!(CyclicBuffer, DynamicArray,  HashSet,  /+ImmutableHashSet,+/
	OpenHashSet, SimdSet, SList, TTree, UnrolledList);
}
else
{
	alias SingleContainers = AliasSeq!(CyclicBuffer, DynamicArray,  HashSet,  /+ImmutableHashSet,+/
	OpenHashSet, /+SimdSet,+/ SList, TTree, UnrolledList);
}

alias DoubleContainers = AliasSeq!(HashMap, TreeMap);

alias AllocatorType = StatsCollector!(
	FreeList!(AllocatorList!(a => Region!(Mallocator)(1024 * 1024), Mallocator), 64));

unittest
{
	foreach (C; SingleContainers)
	{
		AllocatorType allocator;
		testSingle!(C, AllocatorType*)(&allocator);
		assert(allocator.numAllocate > 0 || allocator.numReallocate > 0,
			"No allocations happened for " ~ C.stringof);
		assert(allocator.numAllocate == allocator.numDeallocate || allocator.numReallocate > 0);
		assert(allocator.bytesUsed == 0);
	}
	foreach (C; DoubleContainers)
	{
		AllocatorType allocator;
		testDouble!(C, AllocatorType*)(&allocator);
		assert(allocator.numAllocate > 0 || allocator.numReallocate > 0,
			"No allocations happened for " ~ C.stringof);
		assert(allocator.numAllocate == allocator.numDeallocate || allocator.numReallocate > 0);
		assert(allocator.bytesUsed == 0);
	}
}
