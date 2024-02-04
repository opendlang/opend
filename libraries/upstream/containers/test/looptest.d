module loops;

import containers.ttree;
import std.stdio;

void main()
{
	TTree!int ints;

	while (true)
	{
		foreach (i; 0 .. 1_000_000)
			ints.insert(i);

		foreach (i; 0 .. 1_000_000)
			ints.remove(i);
		writeln("iteration finished");
	}
}
