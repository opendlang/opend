import containers : HashMap;
import std.stdio : writefln;
import core.memory : GC;

/**
 * Generate a random alphanumeric string.
 */
@trusted string randomString(uint len)
{
	import std.ascii : letters, digits;
	import std.conv : to;
	import std.random : randomSample;
	import std.range : chain;

	auto asciiLetters = to!(dchar[])(letters);
	auto asciiDigits = to!(dchar[])(digits);

	if (len == 0)
		len = 1;

	auto res = to!string(randomSample(chain(asciiLetters, asciiDigits), len));
	return res;
}

void main()
{
	immutable iterationCount = 4;
	HashMap!(string, string) hmap;

	for (uint n = 1; n <= iterationCount; n++)
	{
		foreach (i; 0 .. 1_000_000)
			hmap[randomString(4)] = randomString(16);
		GC.collect();
		hmap = HashMap!(string, string)(16);
		GC.collect();

		foreach (i; 0 .. 1_000_000)
			hmap[randomString(4)] = randomString(16);
		GC.collect();
		hmap.clear();
		GC.collect();

		writefln("iteration %s/%s finished", n, iterationCount);
	}
}
