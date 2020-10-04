import std.algorithm;
import std.range;
import std.stdio;
import mir.ion;

void main()
{
	foreach(a;
		File("input.jsonl")
		.byChunk(4096)
		.parseJsonByLine
		.map!(a => a["colors"]))
	{
		auto elems = a.byElement;
		auto count = elems.save.count;
		if(count < 2)
			writefln(`{"num_cols": %s}`, count);
		else
			writefln(`{"num_cols": %s, "fav_color": %s}`, count, elems.dropExactly(1).front);
	}
}
