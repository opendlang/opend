import std.process;
import std.file;

// FIXME: when we call spawnProcess it doesn't print an error (though it does return a code) when the process segfaults.

// FIXME: tell people to install xpack if not already done when then use --target

// FIXME mebbe i could make opend --src=path/to/opend/git/dir args.... pull the build versions out of there, that'd be kinda useful
// hellit oculd even forward itself to the new opend program. hmmmmm

int main(string[] args) {
	// maybe override the normal config files
	// --opend-config-file
	// --opend-project-file
	try {
		import std.algorithm;
		string[] buildSpecificArgs;
		string[] allOtherArgs;
		foreach(arg; args)
			if(arg.startsWith("--opend-to-build="))
				buildSpecificArgs ~= arg["--opend-to-build=".length .. $];
			else
				allOtherArgs ~= arg;

		if(allOtherArgs.length == 0) {
			return 1; // should never happen...
		} if(allOtherArgs.length == 1) {
			return Commands.run(null);
		} else switch(allOtherArgs[1]) {
			foreach(memberName; __traits(allMembers, Commands))
				case memberName:
					return __traits(getMember, Commands, memberName)(buildSpecificArgs ~ allOtherArgs[2 .. $]);
			case "-h", "--help":
				import std.stdio, std.string;
				foreach(memberName; __traits(allMembers, Commands))
					writeln(memberName, "\n\t", strip(__traits(docComment, __traits(getMember, Commands, memberName))));
				return 0;
			default:
				return Commands.build(buildSpecificArgs ~ allOtherArgs[1 .. $]);
		}
	} catch (Throwable e) {
		import std.stdio;
		stderr.writeln(e.msg);
		return 1;
	}
}

struct Commands {
	static:

	/// Does a debug build and immediately runs the program
	int run(string[] args) {
		import std.stdio, std.string;
		if(args.length == 0) {
			foreach(memberName; __traits(allMembers, Commands))
				writeln(memberName, "\n\t", strip(__traits(docComment, __traits(getMember, Commands, memberName))));
			return 1;
		}

		auto oe = getOutputExecutable(args);

		if(auto err = build(oe.buildArgs))
			return err;

		return spawnProcess([oe.exe] ~ oe.args, [
			"LD_LIBRARY_PATH": getRuntimeLibPath()
		]).wait;
	}

	/// Builds the code and runs its unittests
	int test(string[] args) {
		return run(["-unittest", "-main", "-checkaction=context"] ~ args);
	}

	/// Builds the code and runs unittests but only for files explicitly listed, not auto-imported files
	int testOnly(string[] args) {
		return run(["-unittest=explicit", "-main", "-checkaction=context"] ~ args);
	}

	/// Performs quick syntax and semantic tests, without performing code generation
	int check(string[] args) {
		return build(args ~ ["-o-"]);
	}

	/// Does a debug build with the given arguments
	int build(string[] args) {
		// FIXME: pull info out of the cache to get the right libs and -i modifiers out
		return sendToCompilerDriver(["-i"] ~ args, "dmd");
	}

	/// Does a release build with the given arguments
	int publish(string[] args) {
		return sendToCompilerDriver(["-i", "-O2"] ~ args, "ldmd2");
	}

	int sendToCompilerDriver(string[] args, string preferredCompiler = null) {
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
				return dmd(args);
			case "ldmd2":
				return ldmd2(args);
			case "ldc2":
				return ldc2(args);
			default:
				goto case "ldmd2";
		}
	}

	// publish-source which puts the dependencies together?
	// locate-module which spits out the path to a particular module
	// fetch-dependencies

	// if i do a server thing i need to be able to migrate it between attached displays

	/// Pre-compiles with the given arguments so future calls to `build` can use the cached library
	int precompile(string[] args) {
		// any modules present in the precompile need to be written to the cache, knowing which output file they went into
		// FIXME
		return 1;
	}

	/// Watches for changes to its source and attempts to automatically recompile and restart the application (if compatible)
	int watch(string[] args) {
		// FIXME
		return 1;
	}

	/// Passes args to the compiler, then opens a debugger to run the generated file.
	int dbg(string[] args) {
		// FIXME
		return 1;
	}

	/// Allows for updating the OpenD compiler or libraries
	int update(string[] args) {
		// FIXME
		return 1;
	}

	/// Forwards arguments directly to the OpenD dmd driver
	int dmd(string[] args) {
		return spawnProcess([getCompilerPath("dmd")] ~  args, null).wait;
	}

	/// Forwards arguments directly to the OpenD ldmd2 driver
	int ldmd2(string[] args) {
		return spawnProcess([getCompilerPath("ldmd2")] ~  args, null).wait;
	}

	/// Forwards arguments directly to the OpenD ldc2 driver
	int ldc2(string[] args) {
		return spawnProcess([getCompilerPath("ldc2")] ~  args, null).wait;
	}

	/// Installs optional components or updates to opend
	int install(string[] args) {
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
						"--linker=emcc",
						"-i=std",
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

	foreach(idx, arg; args) {
		if(arg == "--") {
			buildArgsSplitter = idx;
			splitter = idx + 1;
			break;
		}
		if(arg.length > 1 && arg[0] == '-') {
			if(arg.length > 3 && arg[0 .. 3] == "-of") {
				name = arg[3 .. $];
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
