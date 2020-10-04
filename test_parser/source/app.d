
import std.stdio;
import std.exception;

import mir.ion;

int main(string[] args)
{
	if(args.length < 2)
	{
		writeln("Usage: test_json-ion <input_filname>.");
		return -1;
	}
	auto filename = args[1];
	try
	{
		auto ion = File(filename)
			.byChunk(4096)
			.parseJson();
	}
	catch(Exception e)
	{
		return 1;
	}
	return 0;
}
