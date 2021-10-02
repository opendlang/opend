// This file is licensed under the Boost License, with code adopted from Silly (https://gitlab.com/AntonMeep/silly),
// which is licensed under the ISC license:
// Copyright (c) 2019, Anton Fediushin
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import tests;
import std.traits;
import std.stdio;

__gshared size_t runnerThreads;
__gshared bool failFast = false;
__gshared bool verbose = false;
__gshared bool disableSummary = false;
__gshared bool failuresOnly = false;
__gshared string includePattern = "";
__gshared string excludePattern = "";
__gshared string singleTestGroup = "";

bool runAllTests() {
	import core.atomic : atomicOp;
	import std.parallelism : totalCPUs, TaskPool;
	import core.time : MonoTime, Duration;
	import std.path : buildNormalizedPath, absolutePath;

	shared size_t total, failed, passed;

	if (runnerThreads == 0)
		runnerThreads = totalCPUs;

	// FIXME: druntime bug
	// Since Mir Ion uses statically allocated exceptions,
	// object.Throwable.chainTogether has a good old jolly time
	// and permanently hangs because it's trying to chain together itself
	// and gets stuck in a infinite loop.
	runnerThreads = 1;

	// Fix up our data location
	testDataLocation = testDataLocation.absolutePath.buildNormalizedPath;

	auto beginTime = MonoTime.currTime;

	static foreach(member; __traits(allMembers, tests.cases))
	{{
		alias m = __traits(getMember, tests.cases, member);
		static if (isFunction!(m) && hasUDA!(m, IonTestCase))
		{
			static foreach(testRunner; getUDAs!(m, IonTestCase)) {{
				import std.path : buildPath;
				if (singleTestGroup.length != 0 && singleTestGroup != testRunner.name)
				{
					writefln("Skipping test case (name: %s, expectedFail: %s)",
								testRunner.name,
								testRunner.expectedFail);
				}
				else
				{
					writefln("Running test case (name: %s, expectedFail: %s)".emphasizeText, 
							testRunner.name,
							testRunner.expectedFail);

					Test[] testCases = loadIonTestData(testDataLocation, testRunner.data, testRunner.expectedFail, testRunner.wantedData);
					atomicOp!"+="(total, testCases.length);

					with (new TaskPool(runnerThreads - 1))
					{
						try {
							foreach(Test testCase; parallel(testCases))
							{
								import std.regex : matchFirst;
								if (includePattern.length != 0 && testCase.name.matchFirst(includePattern).empty) {
									continue;
								} else if (excludePattern.length != 0 && !(testCase.name.matchFirst(excludePattern).empty)) {
									continue;
								} 

								TestResult result;
								scope(exit) {
									result.print(failuresOnly, verbose);
									atomicOp!"+="(result.passed ? passed : failed, 1);
								}

								testCase.run!(m)(result, failFast, verbose);
							}
							finish(true);
						} catch (Throwable t) {
							stop();
							goto end;
						}
					}
				}
			}}
		}
	}}

end:

	if (!disableSummary) {
		writefln("\n----- SUMMARY -----".emphasizeText);
		writefln("%d registered tests".emphasizeText,
				total);
		writefln("Ran %d tests".emphasizeText,
				passed + failed);
		writefln("   %d test(s) %s".emphasizeText,
				passed, "passed".okayText);
		writefln("   %d test(s) %s".emphasizeText,
				failed, "failed".failText);
		writefln("Took %d msecs".emphasizeText,
				(MonoTime.currTime - beginTime).total!"msecs");
		writefln("Total pass rate: %.2f%%".emphasizeText, 
				(cast(double)passed / (passed + failed)) * 100.0);
	} else {
		writefln("%d passed, %d failed, %d total", passed, failed, passed + failed);
	}

	return failed == 0;
}

int main(string[] args)
{
	import std.getopt : getopt;

	auto helpInformation = args.getopt(
		"c|case",
			"Only run a specific test case",
			&singleTestGroup,
		"d|data",
			"Path to the iontestdata directory.",
			&testDataLocation,
		"e|exclude",
			"Exclude test files with a given regex pattern",
			&excludePattern,
		"fail-fast",
			"Stop executing all tests when one fails.",
			&failFast,
		"fails-only",
			"Only print the tests that fail.",
			&failuresOnly,
		"i|include",
			"Only use test files matching this regex pattern",
			&includePattern,
		"no-colors", 
			"Disable colored output.",
			&disableColors,
		"no-summary",
			"Disable the detailed summary.",
			&disableSummary,
		"t|threads",
			"Number of worker threads. 0 to auto-detect (default)",
			&runnerThreads,
		"v|verbose",
			"Show verbose output (stack traces, etc)",
			&verbose
	);

	if (helpInformation.helpWanted) {
		writefln("Usage:");
		writefln("\tmir-ion-integration-tester <options>");
		writefln("Options:");
		foreach(option; helpInformation.options) {
			import std.string : leftJustifier;
			writefln("  %s\t%s\t%s", 
				option.optShort,
				option.optLong.leftJustifier(20),
				option.help);
		}

		return true;
	}


	// Exit with a non-zero error code if all of the tests
	// do not run successfully.
	return runAllTests() == false; 
}
