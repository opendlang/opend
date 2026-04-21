import std.process;
import std.file;

/+
	PACKAGE FETCHING

	opend fetch [--global] [spec]
		spec can be:
			git://thing - requires shell out to git
			http[s]://thing - downloads zip or tarball or whatever
			https://github.com - knows how to adjust the thing
			file:///path - extractors D source from it

	It checks for src/ or source/ for extracting, if present

	UPDATING THE COMPILER

	opend install update
+/

/+
	opend run
	opend test
	opend debug

	--opend-compiler=dmd/ldmd2
    --opend-dev=yes
+/

// rumor has it arm64 for apple can be better than aarch64 but i think they the same

/+
	BUILD OPTIONS
+/


// edit and test by module name instead of by file name

string[] testRunnerBuildArgs(string[] userArgs) {
    auto args = ["-g", "-oftest_runner", "-unittest", "-checkaction=context", "-version=OD_TestRunner", getBundledModulePath("odc.test_runner")];
    args ~= userArgs;
    return args;
}

string preferredCompiler;
bool devCompiler;

int main(string[] args) {
	// maybe override the normal config files
	// --opend-config-file
	// --opend-project-file
	try {
		import std.algorithm;
		string[] buildSpecificArgs;
		string[] otherOpendArgs;
		string[] allOtherArgs;
		foreach(arg; args) {
			if(arg.startsWith("--opend-to-build="))
				buildSpecificArgs ~= arg["--opend-to-build=".length .. $];
			else
			if(arg.startsWith("--opend-"))
				otherOpendArgs ~= arg["--opend-".length .. $];
			else
				allOtherArgs ~= arg;
		}
		foreach(arg; otherOpendArgs) {
			import std.string;
			auto equal = arg.indexOf("=");
			if(equal == -1)
				throw new Exception("opend arg without param: " ~ arg);
			auto name = arg[0 .. equal];
			auto value = arg[equal + 1 .. $];

			switch(name) {
				case "compiler":
					preferredCompiler = value;
				break;
                case "dev":
                    devCompiler = true;
                break;
				default:
					throw new Exception("unknown opend arg: " ~ name);
			}
		}


		if(allOtherArgs.length == 0) {
			return 1; // should never happen...
		} if(allOtherArgs.length == 1) {
			return Commands.run(null, buildSpecificArgs);
		} else switch(auto a = allOtherArgs[1]) {
			foreach(memberName; __traits(allMembers, Commands))
			static if(__traits(getProtection, __traits(getMember, Commands, memberName)) == "public")
				case memberName.trimLeadingUnderscore: {
					string[] argsToSend = allOtherArgs[2 .. $];
					if(a == "build" || a == "test" || a == "publish" || a == "testOnly" || a == "check" || a == "run")
						argsToSend = allOtherArgs[2 .. $];
					return __traits(getMember, Commands, memberName)(argsToSend, buildSpecificArgs);
				}
			case "-h", "--help":
				Commands.help(null, null);
				return 0;
			default:
				return Commands.build(allOtherArgs[1 .. $], buildSpecificArgs);
		}
	} catch (Throwable e) {
		import std.stdio;
		stderr.writeln(e.msg);
		return 1;
	}
}

int checkForCrash(int code, string program) {
	import std.stdio;
	version(Posix) {
		if(code < 0) {
			writeln(program, " killed by signal ", -code);
		}
	}
	version(Windows) {
		if(code > 255) {
			writefln(program, " exited with code %08x", code);
		}
	}
	return code;
}

struct Commands {
	static:

	/// Displays this information
	int help(string[] args, string[] extraBuildArgs) {
		import std.stdio, std.string;

		writeln("`opend [--opend-args...] command_or_filename [args...]`");

		writeln("Where opend-args include:");
		writeln("\t--opend-compiler=ldmd2     prefer the ldc-based compiler in all cases");
		writeln("\t--opend-to-build=flag      passes the given flag to the compiler when building");
		writeln("\t--opend-dev=yes            assumes opend source dev directory layout");

		writeln("And commands include:");

		foreach(memberName; __traits(allMembers, Commands))
		static if(__traits(getProtection, __traits(getMember, Commands, memberName)) == "public")
			static if(memberName != "sendToCompilerDriver")
				writefln("%9s\t%s", memberName.trimLeadingUnderscore, strip(__traits(docComment, __traits(getMember, Commands, memberName))));

		writefln("%9s\t%s", "anyfile.d", "Compiles the given file");
		return 0;
	}

	/// Does a debug build and immediately runs the program
	int run(string[] args, string[] extraBuildArgs) {
		import std.stdio, std.string;
		if(args.length == 0) {
			help(null, null);
			return 1;
		}

		args = extraBuildArgs ~ args;

		auto oe = getOutputExecutable(args);

		if(auto err = build(oe.buildArgs, null))
			return err;

		return spawnProcess([oe.exe] ~ oe.args, [
			"LD_LIBRARY_PATH": getRuntimeLibPath()
		]).wait.checkForCrash("generated program");
	}

	/// Builds the code and runs its unittests
	int test(string[] args, string[] extraBuildArgs) {
		// Check if user wants advanced test runner features
		if(args.length > 0) {
			switch(args[0]) {
				case "list":
					return testList(args[1..$]);
				case "filter":
					return testFilter(args[1..$]);
				case "run":
					return testRun(args[1..$]);
				case "--help", "-h":
					// Delegate to test runner's help system to avoid duplication
					auto oe = getOutputExecutable(testRunnerBuildArgs([]));

					if(auto err = build(oe.buildArgs, extraBuildArgs))
						return err;

					return spawnProcess([oe.exe, "help"], [
						"LD_LIBRARY_PATH": getRuntimeLibPath()
					]).wait.checkForCrash("test runner");
				case "help":
					// Also handle "opend test help"
					goto case "--help";
				default:
					// Fall through to normal test execution
					break;
			}
		}

		// Original test behavior - run all tests
		return run(["-g", "-unittest", "-main", "-checkaction=context"] ~ extraBuildArgs ~ args, null);
	}

	private int testList(string[] args) {
		// Build executable with test runner embedded (no -main since test_runner.d has its own)
		auto oe = getOutputExecutable(testRunnerBuildArgs(args));

		if(auto err = build(oe.buildArgs, null))
			return err;

		return spawnProcess([oe.exe, "list"] ~ oe.args, [
			"LD_LIBRARY_PATH": getRuntimeLibPath()
		]).wait.checkForCrash("test runner");
	}

	private int testFilter(string[] args) {
		if(args.length == 0) {
			import std.stdio;
			stderr.writeln("Error: Please specify a filter pattern.");
			stderr.writeln("Usage: opend test filter <pattern>");
			stderr.writeln("Example: opend test filter \"Math*\"");
			return 1;
		}

		// Build executable with test runner embedded (no -main since test_runner.d has its own)
		auto oe = getOutputExecutable(testRunnerBuildArgs(args[1..$]));

		if(auto err = build(oe.buildArgs, null))
			return err;

		return spawnProcess([oe.exe, "filter", args[0]] ~ oe.args, [
			"LD_LIBRARY_PATH": getRuntimeLibPath()
		]).wait.checkForCrash("test runner");
	}

	private int testRun(string[] args) {
		if(args.length == 0) {
			import std.stdio;
			stderr.writeln("Error: Please specify a test name.");
			stderr.writeln("Usage: opend test run <test_name>");
			return 1;
		}

		// Build executable with test runner embedded (no -main since test_runner.d has its own)
		auto oe = getOutputExecutable(testRunnerBuildArgs(args[1..$]));

		if(auto err = build(oe.buildArgs, null))
			return err;

		return spawnProcess([oe.exe, "run", args[0]] ~ oe.args, [
			"LD_LIBRARY_PATH": getRuntimeLibPath()
		]).wait.checkForCrash("test runner");
	}

	/// Builds the code and runs unittests but only for files explicitly listed, not auto-imported files
	int testOnly(string[] args, string[] extraBuildArgs) {
		return run(["-g", "-unittest=explicit", "-main", "-checkaction=context"] ~ extraBuildArgs ~ args, null);
	}

	/// Performs quick syntax and semantic tests, without performing code generation
	int check(string[] args, string[] extraBuildArgs) {
		return build(args ~ ["-o-"], extraBuildArgs);
	}

	/// Does a debug build with the given arguments
	int build(string[] args, string[] extraBuildArgs) {
		// FIXME: support -gnone?
		// FIXME: pull info out of the cache to get the right libs and -i modifiers out
		return sendToCompilerDriver(["-g", "-i"] ~ extraBuildArgs ~ args, "dmd");
	}

	/// Does an optimized build with the given arguments
	int publish(string[] args, string[] extraBuildArgs) {
		return sendToCompilerDriver(["-i", "-O2"] ~ args, "ldmd2");
	}

	private int sendToCompilerDriver(string[] args, string preferredCompiler = null) {
		if(.preferredCompiler !is null)
			preferredCompiler = .preferredCompiler;
		version(OSX) version(AArch64) if(preferredCompiler == "dmd") preferredCompiler = "ldmd2";

		// extract --target
		string[] argsToKeep;
		argsToKeep.reserve(args.length);

		int warnAboutXpack(string which) {
			import std.path, std.file;
			if(!std.file.exists(getXpackPath() ~ "opend-latest-" ~ which)) {
				import std.stdio;
				stderr.writeln("Error: the support files for this target is not found.");
				stderr.writeln("Try `opend install " ~ which ~ "` first");
				return 1;
			}
			return 0;
		}

		int translateTarget(string target) {
			import std.string;

			string os;
			string platform;
			string cpu;
			string detail;

			foreach(part; target.toLower.split("-")) {
				switch(part) {
					case "windows":
					case "win64":
						cpu = "x86_64";
						os = "windows";
						detail = "msvc";
						if(auto r = warnAboutXpack("xpack-win64"))
							return r;
					break;
					case "mac":
					case "macos":
						if(cpu is null)
							cpu = "x86_64,aarch64";
						os = "apple";
						detail = "darwin";
					break;
					case "ipad":
					case "iphone":
						if(cpu is null)
							cpu = "aarch64,x86_64";
						os = "apple";
						detail = "ios";
					break;
					case "android":
						if(cpu is null)
							cpu = "aarch64,x86_64";
						os = "linux";
						detail = "android";
					break;
					// FIXME: i should add some bsd stuff too
					case "linux":
						if(cpu is null)
							cpu = "x86_64";
						os = "linux";
						detail = "gnu";
					break;
					case "arm":
					case "aarch64":
						cpu = "aarch64";
					break;
					case "amd64":
					case "x86_64":
					case "intel":
						cpu = "x86_64";
					break;
					case "wasm":
					case "webassembly":
						cpu = "wasm32";
						if(os is null)
							os = "emscripten";
					break;
					case "musl":
						if(cpu is null)
							cpu = "x86_64";
						if(os is null)
							os = "linux";
						detail = "musl";
					break;
					case "emscripten":
						if(auto r = warnAboutXpack("xpack-emscripten"))
							return r;
						os = "emscripten";
						if(cpu is null) cpu = "wasm32";
					break;
					case "wasi":
						detail = "wasi";
						if(cpu is null) cpu = "wasm32";
					break;
					case "none":
						os = "unknown";
						detail = "none";
					break;
					case "x86":
						import std.stdio;
						stderr.writeln("32 bit not supported right now by opend, contact us to ask for it. Try amd64 instead.\n");
						return 1;
					case "win32":
						import std.stdio;
						stderr.writeln("32 bit not supported right now by opend, contact us to ask for it. Try win64 instead.\n");
						return 1;
					default:
						import std.stdio;
						stderr.writeln("Unknown part ", part, " try using -mtriple instead.");
						return 1;
				}
			}

			string triple;
			void addPart(string w) {
				if(w.length) {
					if(triple.length)
						triple ~= "-";
					triple ~= w;
				}
			}

			auto comma = cpu.indexOf(",");
			if(comma != -1)
				cpu = cpu[0 .. comma]; // FIXME: should actually spawn two instances

			addPart(cpu);
			addPart(platform);
			addPart(os);
			addPart(detail);

			argsToKeep ~= "--mtriple=" ~ triple;
			if(preferredCompiler.length == 0 || preferredCompiler == "dmd")
				preferredCompiler = "ldmd2";

			return 0;
		}

		bool nextIsTarget;
		bool verbose;
		import std.algorithm;
		import std.string;
		foreach(arg; args) {
			if(nextIsTarget) {
				nextIsTarget = false;
				if(auto err = translateTarget(arg)) return err;
			} else if(arg == "--target" || arg == "-target") {
				nextIsTarget = true;
			} else if(arg.startsWith("--target=")) {
				if(auto err = translateTarget(arg["--target=".length .. $])) return err;
			} else if(arg.indexOf("-mtriple") != -1) {
				preferredCompiler = "ldmd2";
			} else if(arg == "-v") {
				argsToKeep ~= arg;
				verbose = true;
			} else
				argsToKeep ~= arg;
		}
		args = argsToKeep;

		if(verbose) {
			import std.stdio;
			stderr.writeln(preferredCompiler, " ", args);
		}
		switch(preferredCompiler) {
			case "dmd":
				return dmd(args, null);
			case "ldmd2":
				return ldmd2(args, null);
			case "ldc2":
				return ldc2(args, null);
			default:
				goto case "ldmd2";
		}
	}

	// publish-source which puts the dependencies together?
	// locate-module which spits out the path to a particular module
	// fetch-dependencies
	// needs to keep the whole directory of source but figure out where it is an d put it in the correct place.

	// if i do a server thing i need to be able to migrate it between attached displays

	/// Pre-compiles with the given arguments so future calls to `build` can use the cached library
	version(none)
	int precompile(string[] args, string[] extraBuildArgs) {
		// any modules present in the precompile need to be written to the cache, knowing which output file they went into
		// FIXME
		return 1;
	}

	/// Watches for changes to its source and attempts to automatically recompile and restart the application (if compatible)
	version(none)
	int watch(string[] args, string[] extraBuildArgs) {
		// FIXME
		return 1;
	}

    /// Performs a publish build then calls a user-defined deployment on the generated artifact
	version(none)
	int deploy(string[] args, string[] extraBuildArgs) {
		// FIXME
		return 1;
	}

	/// Passes args to the compiler, then opens a debugger to run the generated file. -- ONLY SHELLS TO GDB RIGHT NOW
	int _debug(string[] args, string[] extraBuildArgs) {
		args = extraBuildArgs ~ args;

		auto oe = getOutputExecutable(args);

		if(auto err = build(oe.buildArgs, null))
			return err;

		return spawnProcess(["gdb", "--args", oe.exe] ~ oe.args, [
			"LD_LIBRARY_PATH": getRuntimeLibPath()
		]).wait.checkForCrash("generated program");
	}

	/// Forwards arguments directly to the OpenD dmd driver
	int dmd(string[] args, string[] extraBuildArgs) {
        if(devCompiler) {
            string osFolder;
            version(linux)
                osFolder = "linux";
            else version(Windows)
                osFolder = "windows";
            else version(OSX)
                osFolder = "osx";
            else version(FreeBSD)
                osFolder = "freebsd";

		    return spawnProcess([getCompilerPath("../generated/"~osFolder~"/release/64/dmd")] ~  args, null).wait.checkForCrash("dmd-dev");
        } else
		    return spawnProcess([getCompilerPath("dmd")] ~  args, null).wait.checkForCrash("dmd");
	}

	/// Forwards arguments directly to the OpenD ldmd2 driver
	int ldmd2(string[] args, string[] extraBuildArgs) {
        if(devCompiler) {
		    return spawnProcess([getCompilerPath("../ldc-build/bin/ldmd2")] ~  args, null).wait.checkForCrash("ldmd2-dev");
        } else
		    return spawnProcess([getCompilerPath("ldmd2")] ~  args, null).wait.checkForCrash("ldmd2");
	}

	/// Forwards arguments directly to the OpenD ldc2 driver
	int ldc2(string[] args, string[] extraBuildArgs) {
        if(devCompiler) {
		    return spawnProcess([getCompilerPath("../ldc-build/bin/ldc2")] ~  args, null).wait.checkForCrash("ldc2-dev");
        } else
		    return spawnProcess([getCompilerPath("ldc2")] ~  args, null).wait.checkForCrash("ldc2");
	}

	/// Installs optional components or updates to opend
	int install(string[] args, string[] extraBuildArgs) {

		// FIXME: remove any --opend-to-build= stuff before args[0]

		// create the ../xpacks directory

		static import std.file;
		if(!std.file.exists(getXpackPath()))
			std.file.mkdir(getXpackPath());

		switch(args[0]) {
			case "update":
				// get the new update, if available, then repeat other xpack installs
				return 1;
			case "xpack-android":
				// can extract the libs from the android downloads
				// you must also install the ndk
				return 1;
			case "xpack-emscripten":
				// https://github.com/opendlang/opend/releases/download/CI/opend-latest-xpack-emscripten.tar.xz
				// you must also install the emsdk

				downloadXpack("xpack-emscripten");


				// brianush suggests:
				// -sSTANDALONE_WASM -sEXPORTED_FUNCTIONS="[\"__start\"]"

				string ext = "";
				version(Windows)
					ext = ".bat";

				// phobos is compiled but puts out some warnings so gonna reenable it with -i and not link the phobos
				// tbh might be a good idea to do that for other platforms too
				installConfig(`
					"^wasm(32|64)-.*-emscripten":
					{
					    lib-dirs = [
						"%%ldcbinarypath%%/../xpacks/opend-latest-xpack-emscripten/lib",
					    ];

					    switches = [
						"-defaultlib=druntime-ldc",
						"--linker=emcc`~ext~`",
						"-i=std",
						"-i=.",
					    ];
					};
				`);

				import std.stdio;
				writeln("Installation complete, build with `opend --target=emscripten <other args>`");
				writeln("You will need the emsdk. Install that separately and follow its instructions to activate it before trying to build D code because opend will use emcc to finish the link step.");
				writeln("https://emscripten.org/docs/getting_started/downloads.html");

				return 0;
			case "xpack-win64":
				// https://github.com/opendlang/opend/releases/download/CI/opend-latest-xpack-win64.tar.xz
				downloadXpack("xpack-win64");
				installConfig(`
					"x86_64-.*-windows-msvc":
					{
					    lib-dirs = [
						"%%ldcbinarypath%%/../xpacks/opend-latest-xpack-win64/lib",
					    ];
					};
				`);

				import std.stdio;
				writeln("Installation complete, build with `opend --target=win64 <other args>`");

				return 0;
			default:
				import std.stdio;
				stderr.writeln("Unknown thing");
				return 1;

			// maybe should do xpack-freestanding-{amd64,aarch64}
			// xpack-linux-aarch64, xpack-linux-musl
		}
	}
}

void installConfig(string configInfo) {
	import std.file, std.path;
	std.file.append(buildPath([dirName(thisExePath()), "../etc/ldc2.conf"]), configInfo);
}

string getCompilerPath(string compiler) {
	import std.file, std.path;
	version(Windows)
		string exeExtension = ".exe";
	else
		string exeExtension = "";
	return buildPath([dirName(thisExePath()), setExtension(compiler, exeExtension)]);
}


string getBundledModulePath(string moduleName) {
	import std.file, std.path;
	import std.string;
	return buildPath([dirName(thisExePath()), "../import/" ~ moduleName.replace(".", "/") ~ ".d"]);

}

string getRuntimeLibPath() {
	import std.file, std.path;
	return buildPath([dirName(thisExePath()), "../lib/"]);
}

string getXpackPath() {
	import std.file, std.path;
	return buildPath([dirName(thisExePath()), "../xpacks/"]);
}


struct OutputExecutable {
	string exe;
	string[] args;
	string[] buildArgs;
}

OutputExecutable getOutputExecutable(string[] args) {
	// FIXME: make sure we have the actual output name here... maybe should ask the compiler itself
	size_t splitter = args.length;
	size_t buildArgsSplitter = args.length;
	string first;
	string name;
	string extension;
	bool nameExplicitlyGiven = false;
	version(Windows)
		extension = ".exe";

	import std.path;

	foreach(idx, arg; args) {
		if(arg == "--") {
			buildArgsSplitter = idx;
			splitter = idx + 1;
			break;
		}
		if(arg.length > 1 && arg[0] == '-') {
			if(arg.length > 3 && arg[0 .. 3] == "-of") {
				name = baseName(arg[3 .. $]);
				extension = null;
				nameExplicitlyGiven = true;
				break;
			}
			if(arg == "-lib") {
				version(Windows)
					extension = ".lib";
				else
					extension = ".a";
			}
			if(arg == "-shared") {
				version(Windows)
					extension = ".dll";
				else version(OSX)
					extension = ".dylib";
				else
					extension = ".so";
			}
			continue;
		} else {
			import std.path;
			if(first is null) {
				first = arg.stripExtension;
			}
		}
	}

	if(!nameExplicitlyGiven)
		name = first ~ extension;

	import std.path;
	return OutputExecutable(buildPath(".", name), args[splitter .. $], args[0 .. buildArgsSplitter]);
}

void downloadXpack(string which) {
	import arsd.archive;

        import std.net.curl;

	import core.thread.fiber;

	ubyte[] availableData;

	string url = "https://github.com/opendlang/opend/releases/download/CI/opend-latest-" ~ which ~ ".tar.xz";
	string destination = getXpackPath();
	bool done;

	void processor() {
		TarFileHeader tfh;
		long size;
		ubyte[512] tarBuffer;

		import std.stdio;
		File file;
		long currentFileSize;
		bool skippingFile;

		decompressLzma(
			(in ubyte[] chunk) => cast(void) processTar(&tfh, &size, chunk,
				(header, isNewFile, fileFinished, data) {
					if(isNewFile) {
						if(header.type == TarFileType.normal)
							skippingFile = false;
						else
							skippingFile = true;

						if(!skippingFile) {
							import std.stdio; writeln("inflating xpack file ", header.filename);
							import std.path, std.file;
							mkdirRecurse(dirName(buildPath(destination, header.filename)));
							file = File(buildPath(destination, header.filename), "wb");
							currentFileSize = header.size;
						} else {
						}
					}
					if(!skippingFile)
						file.rawWrite(data);
					if(fileFinished) {
						if(!skippingFile)
							file.close();
						skippingFile = false;
					}
				}),
			(ubyte[] buffer) {
				try_again:
				auto canUse = buffer.length < availableData.length ? buffer.length : availableData.length;
				if(canUse) {
					buffer[0 .. canUse] = availableData[0 .. canUse];
					availableData = availableData[canUse .. $];
					return buffer[0 .. canUse];
				} else {
					Fiber.yield();
					goto try_again;
				}
			},
			tarBuffer[]
		);

		done = true;
	}

	auto fiber = new Fiber(&processor, 1 * 1024 * 1024 /* reserve 1 MB stack */);

	import std.stdio;
	writeln("Downloading...");

        auto http = HTTP(url);
        http.onReceive = (ubyte[] data) {
		availableData = data;
		if(!done)
			fiber.call();
                return data.length;
        };
        http.perform();

}

string trimLeadingUnderscore(string s) {
    if(s[0] == '_')
        return s[1..$];
    return s;
}

