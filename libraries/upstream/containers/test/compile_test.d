import containers.cyclicbuffer;
import containers.dynamicarray;
import containers.hashmap;
import containers.hashset;
import containers.openhashset;
import containers.simdset;
import containers.slist;
import containers.treemap;
import containers.ttree;
import containers.unrolledlist;

private void testContainerSingle(alias Container)()
{
	testContainerSingleVal!(Container)();
	testContainerSingleRef!(Container)();
}

private void testContainerSingleVal(alias Container)()
{
	Container!(int) mm;
	Container!(const int) mc;
	Container!(immutable int) mi;

	const Container!(int) cm;
	const Container!(const int) cc;
	const Container!(immutable int) ci;

	immutable Container!(int) im;
	immutable Container!(const int) ic;
	immutable Container!(immutable int) ii;

	checkSliceFunctionality!(int)(mm);
	checkSliceFunctionality!(const int)(mc);
	checkSliceFunctionality!(immutable int)(mi);

	checkSliceFunctionality!(int)(cm);
	checkSliceFunctionality!(const int)(cc);
	checkSliceFunctionality!(immutable int)(ci);

	checkSliceFunctionality!(int)(im);
	checkSliceFunctionality!(const int)(ic);
	checkSliceFunctionality!(immutable int)(ii);

	static struct NC { @disable this(this); }
	debug(check_compliance) static if (!is(Container!NC)) pragma(msg, __traits(identifier, Container) ~ " does not support non-copyable types");

	static struct NI { @disable this(); }
	debug(check_compliance) static if (!is(Container!NI)) pragma(msg, __traits(identifier, Container) ~ " does not support non-constructable types");

	static struct ND { @disable ~this() {} }
	debug(check_compliance) static if (!is(Container!ND)) pragma(msg, __traits(identifier, Container) ~ " does not support non-destructible types");
}

private void testContainerSingleRef(alias Container)()
{
	Container!(int*) mm;
	Container!(const int*) mc;
	Container!(immutable int*) mi;

	const Container!(int*) cm;
	const Container!(const int*) cc;
	const Container!(immutable int*) ci;

	immutable Container!(immutable int*) ii;

	checkSliceFunctionality!(int*)(mm);
	checkSliceFunctionality!(const int*)(mc);
	checkSliceFunctionality!(immutable int*)(mi);

	checkSliceFunctionality!(const(int)*)(cm);
	checkSliceFunctionality!(const int*)(cc);
	checkSliceFunctionality!(immutable int*)(ci);

	checkSliceFunctionality!(immutable int*)(ii);
}

private void testContainerDouble(alias Container)()
{
	testContainerDoubleVal!(Container)();
	testContainerDoubleRef!(Container)();
	testContainerDoubleAggregateKey!(Container)();
}

private void testContainerDoubleAggregateKey(alias Container)()
{
	static struct KeyType
	{
		int a;
		string[] c;

		int opCmp(ref const KeyType other) const
		{
			if (other.a < a)
				return -1;
			return other.a > a;
		}

		size_t toHash() const
		{
			return 10;
		}

		bool opEquals(ref const KeyType other) const
		{
			return a == other.a;
		}
	}

	Container!(const KeyType, int) cm;

	Container!(immutable KeyType, int) im;

	checkIndexFunctionality!(int, const KeyType)(cm);

	checkIndexFunctionality!(int, const KeyType)(im);

	checkSliceFunctionality!(int)(cm);

	checkSliceFunctionality!(int)(im);
}

private void testContainerDoubleVal(alias Container)()
{
	{
		Container!(int, int) mmm;
		Container!(int, const int) mmc;
		Container!(int, immutable int) mmi;

		Container!(const int, int) mcm;
		Container!(const int, const int) mcc;
		Container!(const int, immutable int) mci;

		Container!(immutable int, int) mim;
		Container!(immutable int, const int) mic;
		Container!(immutable int, immutable int) mii;

		checkIndexFunctionality!(int, int)(mmm);
		checkIndexFunctionality!(const int, int)(mmc);
		checkIndexFunctionality!(immutable int, int)(mmi);

		checkIndexFunctionality!(int, const int)(mcm);
		checkIndexFunctionality!(const int, const int)(mcc);
		checkIndexFunctionality!(immutable int, const int)(mci);

		checkIndexFunctionality!(int, immutable int)(mim);
		checkIndexFunctionality!(const int, immutable int)(mic);
		checkIndexFunctionality!(immutable int, immutable int)(mii);

		checkSliceFunctionality!(int)(mmm);
		checkSliceFunctionality!(const int)(mmc);
		checkSliceFunctionality!(immutable int)(mmi);

		checkSliceFunctionality!(int)(mcm);
		checkSliceFunctionality!(const int)(mcc);
		checkSliceFunctionality!(immutable int)(mci);

		checkSliceFunctionality!(int)(mim);
		checkSliceFunctionality!(const int)(mic);
		checkSliceFunctionality!(immutable int)(mii);
	}

	{
		const Container!(int, int) cmm;
		const Container!(int, const int) cmc;
		const Container!(int, immutable int) cmi;

		const Container!(const int, int) ccm;
		const Container!(const int, const int) ccc;
		const Container!(const int, immutable int) cci;

		const Container!(immutable int, int) cim;
		const Container!(immutable int, const int) cic;
		const Container!(immutable int, immutable int) cii;

		checkIndexFunctionality!(int, int)(cmm);
		checkIndexFunctionality!(const int, int)(cmc);
		checkIndexFunctionality!(immutable int, int)(cmi);

		checkIndexFunctionality!(int, const int)(ccm);
		checkIndexFunctionality!(const int, const int)(ccc);
		checkIndexFunctionality!(immutable int, const int)(cci);

		checkIndexFunctionality!(int, immutable int)(cim);
		checkIndexFunctionality!(const int, immutable int)(cic);
		checkIndexFunctionality!(immutable int, immutable int)(cii);

		checkSliceFunctionality!(int)(cmm);
		checkSliceFunctionality!(const int)(cmc);
		checkSliceFunctionality!(immutable int)(cmi);

		checkSliceFunctionality!(int)(ccm);
		checkSliceFunctionality!(const int)(ccc);
		checkSliceFunctionality!(immutable int)(cci);

		checkSliceFunctionality!(int)(cim);
		checkSliceFunctionality!(const int)(cic);
		checkSliceFunctionality!(immutable int)(cii);
	}

	{
		immutable Container!(int, int) imm;
		immutable Container!(int, const int) imc;
		immutable Container!(int, immutable int) imi;

		immutable Container!(const int, int) icm;
		immutable Container!(const int, const int) icc;
		immutable Container!(const int, immutable int) ici;

		immutable Container!(immutable int, int) iim;
		immutable Container!(immutable int, const int) iic;
		immutable Container!(immutable int, immutable int) iii;

		checkIndexFunctionality!(int, int)(imm);
		checkIndexFunctionality!(const int, int)(imc);
		checkIndexFunctionality!(immutable int, int)(imi);

		checkIndexFunctionality!(int, const int)(icm);
		checkIndexFunctionality!(const int, const int)(icc);
		checkIndexFunctionality!(immutable int, const int)(ici);

		checkIndexFunctionality!(int, immutable int)(iim);
		checkIndexFunctionality!(const int, immutable int)(iic);
		checkIndexFunctionality!(immutable int, immutable int)(iii);

		checkSliceFunctionality!(int)(imm);
		checkSliceFunctionality!(const int)(imc);
		checkSliceFunctionality!(immutable int)(imi);

		checkSliceFunctionality!(int)(icm);
		checkSliceFunctionality!(const int)(icc);
		checkSliceFunctionality!(immutable int)(ici);

		checkSliceFunctionality!(int)(iim);
		checkSliceFunctionality!(const int)(iic);
		checkSliceFunctionality!(immutable int)(iii);
	}

	static struct NC { @disable this(this); }
	debug(check_compliance) static if (!is(Container!(NC, int))) pragma(msg, __traits(identifier, Container) ~ " does not support non-copyable keys");
	debug(check_compliance) static if (!is(Container!(int, NC))) pragma(msg, __traits(identifier, Container) ~ " does not support non-copyable values");

	static struct NI { @disable this(); }
	debug(check_compliance) static if (!is(Container!(NI, int))) pragma(msg, __traits(identifier, Container) ~ " does not support non-constructable keys");
	debug(check_compliance) static if (!is(Container!(int, NI))) pragma(msg, __traits(identifier, Container) ~ " does not support non-constructable values");

	static struct ND { @disable ~this() {} }
	debug(check_compliance) static if (!is(Container!(ND, int))) pragma(msg, __traits(identifier, Container) ~ " does not support non-destructable keys");
	debug(check_compliance) static if (!is(Container!(int, ND))) pragma(msg, __traits(identifier, Container) ~ " does not support non-destructable values");
}

private void testContainerDoubleRef(alias Container)()
{
	{
		Container!(int, int*) mmm;
		Container!(int, const int*) mmc;
		Container!(int, immutable int*) mmi;

		Container!(const int, int*) mcm;
		Container!(const int, const int*) mcc;
		Container!(const int, immutable int*) mci;

		Container!(immutable int, int*) mim;
		Container!(immutable int, const int*) mic;
		Container!(immutable int, immutable int*) mii;

		checkIndexFunctionality!(int*, int)(mmm);
		checkIndexFunctionality!(const int*, int)(mmc);
		checkIndexFunctionality!(immutable int*, int)(mmi);

		checkIndexFunctionality!(int*, const int)(mcm);
		checkIndexFunctionality!(const int*, const int)(mcc);
		checkIndexFunctionality!(immutable int*, const int)(mci);

		checkIndexFunctionality!(int*, immutable int)(mim);
		checkIndexFunctionality!(const int*, immutable int)(mic);
		checkIndexFunctionality!(immutable int*, immutable int)(mii);

		checkSliceFunctionality!(int*)(mmm);
		checkSliceFunctionality!(const int*)(mmc);
		checkSliceFunctionality!(immutable int*)(mmi);

		checkSliceFunctionality!(int*)(mcm);
		checkSliceFunctionality!(const int*)(mcc);
		checkSliceFunctionality!(immutable int*)(mci);

		checkSliceFunctionality!(int*)(mim);
		checkSliceFunctionality!(const int*)(mic);
		checkSliceFunctionality!(immutable int*)(mii);
	}

	{
		const Container!(int, int*) cmm;
		const Container!(int, const int*) cmc;
		const Container!(int, immutable int*) cmi;

		const Container!(const int, int*) ccm;
		const Container!(const int, const int*) ccc;
		const Container!(const int, immutable int*) cci;

		const Container!(immutable int, int*) cim;
		const Container!(immutable int, const int*) cic;
		const Container!(immutable int, immutable int*) cii;

		checkIndexFunctionality!(const(int)*, int)(cmm);
		checkIndexFunctionality!(const int*, int)(cmc);
		checkIndexFunctionality!(immutable int*, int)(cmi);

		checkIndexFunctionality!(const(int)*, const int)(ccm);
		checkIndexFunctionality!(const int*, const int)(ccc);
		checkIndexFunctionality!(immutable int*, const int)(cci);

		checkIndexFunctionality!(const(int)*, immutable int)(cim);
		checkIndexFunctionality!(const int*, immutable int)(cic);
		checkIndexFunctionality!(immutable int*, immutable int)(cii);

		checkSliceFunctionality!(const(int)*)(cmm);
		checkSliceFunctionality!(const int*)(cmc);
		checkSliceFunctionality!(immutable int*)(cmi);

		checkSliceFunctionality!(const(int)*)(ccm);
		checkSliceFunctionality!(const int*)(ccc);
		checkSliceFunctionality!(immutable int*)(cci);

		checkSliceFunctionality!(const(int)*)(cim);
		checkSliceFunctionality!(const int*)(cic);
		checkSliceFunctionality!(immutable int*)(cii);
	}

	{
		immutable Container!(int, immutable int*) imi;

		immutable Container!(const int, immutable int*) ici;

		immutable Container!(immutable int, immutable int*) iii;

		checkIndexFunctionality!(immutable int*, int)(imi);

		checkIndexFunctionality!(immutable int*, const int)(ici);

		checkIndexFunctionality!(immutable int*, immutable int)(iii);

		checkSliceFunctionality!(immutable int*)(imi);

		checkSliceFunctionality!(immutable int*)(ici);

		checkSliceFunctionality!(immutable int*)(iii);
	}
}

private void checkSliceFunctionality(Type, Container)(ref Container container)
{
	import std.array : front;
	static if (__traits(hasMember, Container, "opSlice"))
	{
		auto r = container[];
		static assert(is(typeof(r.front()) == Type));
		static assert(is(typeof(container.length) == size_t));
		assert(container.length == 0);
	}
}

private void checkIndexFunctionality(Type, KeyType, Container)(ref Container container)
{
	import std.traits : hasFunctionAttributes;

	static assert(__traits(compiles, {container[KeyType.init];}));
	// The tests here will expect the wrong thing for opIndex implementations
	// that return by ref.
	static if (!hasFunctionAttributes!(Container.opIndex!Container, "ref"))
		static assert(is(typeof(container[KeyType.init]) == Type));
	static assert(is(typeof(container.length) == size_t));
	assert(container.length == 0);
}


unittest
{
	testContainerDouble!(HashMap)();
	testContainerDouble!(TreeMap)();
	testContainerSingle!(HashSet)();
	testContainerSingle!(UnrolledList)();
	testContainerSingle!(OpenHashSet)();
	version (D_InlineAsm_X86_64) testContainerSingle!(SimdSet)();
	testContainerSingle!(SList)();
	testContainerSingle!(TTree)();
	testContainerSingle!(DynamicArray)();
	testContainerSingle!(CyclicBuffer)();
}
