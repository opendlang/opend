#!/usr/bin/env dub --build=release-nobounds --compiler=ldmd2 -v --single
/+ dub.json: {
	"name":"Mt19937_bench",
	"dependencies": {
		"mir-random":{"path": "../"}
	}
} +/

import mir.random.engine.mersenne_twister;
/+
Mir 32-bit Mt19937: 6.80851 Gb/s
check sum = 214724495853043511

Mir 64-bit Mt19937: 12.5984 Gb/s
check sum = 8857660070542815631

Phobos 32-bit Mt19937: 4.41989 Gb/s
check sum = 214724495853043511

Phobos 64-bit Mt19937: wrong initialization and tempering

1.54 = 6.80851 / 4.41989
2.85 = 12.5984 / 4.41989
+/

static import std.random;

import std.stdio, std.datetime, std.conv;


void main()
{
	auto seed = Mt19937_32.defaultSeed;
	auto std = std.random.Mt19937(seed); //32-bit
	auto mir_32 = Mt19937_32(seed);
	auto mir_64 = Mt19937_64(seed);
	enum ulong count = 100_000_000;
	ulong s;
	StopWatch sw;
	sw.start;
	foreach(_; 0..count) //boost CPU
	{
		s += std.front;
		std.popFront;
		s += mir_32();
		s += mir_64();
	}
	s = 0;
	sw.stop;
	sw.reset;
	sw.start;
	foreach(_; 0..count)
		s += mir_32();
	sw.stop;
	writefln("Mir 32-bit Mt19937: %s Gb/s", double(count * 32u) / sw.peek.msecs / 1000 ^^ 2);
	writeln("check sum = ", s, "\n");
	s = 0;
	sw.reset;
	sw.start;
	foreach(_; 0..count)
		s += mir_64();
	sw.stop;
	writefln("Mir 64-bit Mt19937: %s Gb/s", double(count * 64u) / sw.peek.msecs / 1000 ^^ 2);
	writeln("check sum = ", s, "\n");
	s = 0;
	sw.reset;
	sw.start;
	foreach(_; 0..count)
	{
		s += std.front;
		std.popFront;
	}
	sw.stop;
	writefln("Phobos 32-bit Mt19937: %s Gb/s", double(count * 32u) / sw.peek.msecs / 1000 ^^ 2);
	writeln("check sum = ", s, "\n");
	writefln("Phobos 64-bit Mt19937: wrong initialization and tempering");
}
