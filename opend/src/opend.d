import std.process;
import std.file;

int main(string[] args) {
	// maybe override the normal config files
	// --opend-config-file
	// --opend-project-file
	try {
		if(args.length == 0) {
			return 1; // should never happen...
		} if(args.length == 1) {
			return Commands.run(null);
		} else switch(args[1]) {
			foreach(memberName; __traits(allMembers, Commands))
				case memberName:
					return __traits(getMember, Commands, memberName)(args[2 .. $]);
			case "-h", "--help":
				import std.stdio, std.string;
				foreach(memberName; __traits(allMembers, Commands))
					writeln(memberName, "\n\t", strip(__traits(docComment, __traits(getMember, Commands, memberName))));
				return 0;
			default:
				return Commands.build(args[1 .. $]);
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
		if(args.length == 0)
			foreach(memberName; __traits(allMembers, Commands))
				writeln(memberName, "\n\t", strip(__traits(docComment, __traits(getMember, Commands, memberName))));
			return 1;
		if(auto err = build(args))
			return err;

		auto oe = getOutputExecutable(args);

		return spawnProcess([oe.exe] ~ oe.args, [
			"LD_LIBRARY_PATH": getRuntimeLibPath()
		]).wait;
		return 0;
	}

	/// Builds the code and runs its unittests
	int test(string[] args) {
		return run(["-unittest", "-main"] ~ args);
	}

	/// Builds the code and runs unittests but only for files explicitly listed
	int testOnly(string[] args) {
		return run(["-unittest=explicit", "-main"] ~ args);
	}

	/// Performs quick syntax and semantic tests, without performing code generation
	int check(string[] args) {
		return build(args ~ ["-o-"]);
	}

	/// Does a debug build with the given arguments
	int build(string[] args) {
		// FIXME: pull info out of the cache to get the right libs and -i modifiers out
		return dmd(["-i"] ~ args);
	}

	/// Does a release build with the given arguments
	int publish(string[] args) {
		return ldmd2(["-i", "-O2"] ~ args);
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

struct OutputExecutable {
	string exe;
	string[] args;
}

OutputExecutable getOutputExecutable(string[] args) {
	// FIXME: make sure we have the actual output name here... maybe should ask the compiler itself
	size_t splitter = args.length;
	string name;
	foreach(idx, arg; args) {
		if(arg == "--") {
			splitter = idx + 1;
			break;
		}
		if(arg.length > 1 && arg[0] == '-') {
			if(arg.length > 3 && arg[0 .. 3] == "-of") {
				name = arg[3 .. $];
				break;
			}
			continue;
		} else {
			import std.path;
			name = arg.stripExtension;
			break;
		}
	}

	import std.path;
	return OutputExecutable(buildPath(".", name), args[splitter .. $]);
}
