module opend.tools.library_extractor;

import arsd.jsvar;
import std.process;
import std.file;
import std.string;
import std.stdio;
import std.path;

void getProject(string url, string sourceDir, string[] excludedDirectories, string branch) {
	if(url.indexOf("github.com/") != -1) {
		auto folderIdx = url.lastIndexOf("/");
		if(folderIdx == -1 || folderIdx + 1 == url.length)
			throw new Exception("bad url don't put a trailing slash");
		auto folder = url[folderIdx + 1 .. $];

		if(!std.file.exists(folder)) {
			writeln("clone ", url, " ", getcwd, "/", folder);
			wait(spawnShell("git remote add -f " ~ folder ~ " " ~ url ~ ".git"));
			wait(spawnShell("git merge -s ours --no-commit --allow-unrelated-histories " ~ folder ~ "/" ~ branch));
			auto thing = executeShell("git read-tree --prefix=libraries/upstream/" ~ folder ~ "/ -u " ~ folder ~ "/" ~ branch);
			// auto thing = executeShell("git pull -s subtree "~folder~" " ~ url ~ ".git");
			if(thing.status != 0)
				throw new Exception("clone " ~ url ~ " failed");
			wait(spawnShell("git commit -a -m \"add " ~ folder ~ "\""));
			// chdir(folder);
		} else {
		/+
			chdir(folder);
			auto thing = executeShell("git pull");
			writeln("git pull");
			if(thing.status != 0 || thing.output.indexOf("Already up to date.") != -1) {
				writeln("up to date");
				chdir("..");
				return;
			}
		+/
			// assuming up to date
			return;
		}
	} else {
		throw new Exception("not implemented repo");
	}

	/+
	scope(exit)
		chdir("..");

	fileLoop: foreach(filename; dirEntries(sourceDir, "*.d", SpanMode.breadth)) {
		foreach(excluded; excludedDirectories)
			if(filename.indexOf(excluded ~ "/") != -1)
				continue fileLoop;
		copyInFile("../../importable/", filename);
		writeln(filename);
	}
	+/
}

string extractModuleName(string code) {
	// FIXME: it should actually do some lexing cuz there could be fake module names in a comment or UDA prior to the real thing but meh. i sh ould borrow the code from adrdox

	tryMore:
	auto idx = code.indexOf("module ");
	if(idx == -1)
		return null;
	code = code[idx + "module ".length .. $];
	idx = code.indexOf(";");
	if(idx == -1)
		return null;
	auto name = code[0 .. idx];
	if(name.length == 0)
		return null;
	bool valid = name.length > 0;
	foreach(ch; name) {
		if(!(
			(ch >= 'a' && ch <= 'z') ||
			(ch >= 'A' && ch <= 'Z') ||
			(ch >= '0' && ch <= '9') ||
			ch == '.' ||
			ch == '_'
		)) {
			valid = false;
			break;
		}
	}
	if(!valid)
		goto tryMore;

	return name;

}

void copyInFile(string locationDirectory, string codeFilename) {
	auto code = readText(codeFilename);
	auto moduleName = extractModuleName(code);
	if(moduleName is null) {
		writeln(codeFilename ~ " has no module declaration");
		return; // useless trash
	}
	auto path = moduleName.replace(".", "/") ~ ".d";
	if(codeFilename.indexOf("package.d") != -1) {
		// gotta keep this stupid filename
		path = moduleName.replace(".", "/") ~ "/package.d";
	}
	mkdirRecurse(locationDirectory ~ path.dirName);
	std.file.write(locationDirectory ~ path, code);
}

void main() {
	auto list = var.fromJson(readText("list.json"));
	chdir("upstream");
	foreach(pkg; list.packages) {
		getProject(
			pkg.repository.get!string,
			pkg.sourceDirectory.get!string,
			pkg.excludedDirectories.get!(string[]),
			pkg.branch == null ? "master" : pkg.branch.get!string
		);
	}
	chdir("..");
}
