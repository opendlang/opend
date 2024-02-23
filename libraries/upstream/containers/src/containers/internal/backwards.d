module containers.internal.backwards;

static if (__VERSION__ < 2071)
{
	/// 64-bit popcnt
	int popcnt(ulong v) pure nothrow @nogc @safe
	{
		import core.bitop : popcnt;

		return popcnt(cast(uint) v) + popcnt(cast(uint)(v >>> 32));
	}

	version (X86_64)
		public import core.bitop : bsf;
	else
	{
		/// Allow 64-bit bsf on old compilers
		int bsf(ulong v) pure nothrow @nogc @safe
		{
			import core.bitop : bsf;

			immutable uint lower = cast(uint) v;
			immutable uint upper = cast(uint)(v >>> 32);
			return lower == 0 ? bsf(upper) + 32 : bsf(lower);
		}
	}
}
else
	public import core.bitop : bsf, popcnt;
