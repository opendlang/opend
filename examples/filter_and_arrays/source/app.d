import std.algorithm;
import std.stdio;
import mir.ion;

void main()
{
	auto target = IonDescribedValue("red");
	File("input.jsonl")
		.byChunk(10)                  // Use at least 4096 bytes for real world apps
		.parseJsonByLine
		.filter!(object => object["colors"]
			.byElement                // iterates over an array
			.canFind(target))         // Comparison with Ion is little bit faster than
			//.canFind("tadmp5800"))  //    comparison with a string.
		.each!writeln;                // See also `lockingTextWriter` from `std.stdio`.
}
