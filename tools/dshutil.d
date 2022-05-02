#!/usr/bin/env dub
/+ dub.sdl:
    dependency "dsh" version="~>1.6.0"
    dependency "fswatch" version="~>0.6.0"
    dependency "requests" version="~>2.0.6"
+/

/**
 * A helper program that can be used to make, build, and manage dsh scripts.
 */
module tools.dshutil;

import dsh;

const DSH_VERSION = "1.6.0";

int main(string[] args) {
    import std.string;
    if (args.length < 2) {
        stderr.writeln("Missing required command argument.");
        printHelp();
        return 1;
    }
    string command = args[1].strip;
    if (command == "--version" || command == "-v") {
        writeln(DSH_VERSION);
        return 0;
    }
    if (command == "--help" || command == "-h") printHelp();
    if (command == "create") return createScript(args[2..$]);
    if (command == "build") return buildScript(args[2..$]);
    if (command == "compile") return compileScript(args[2..$]);
    version(linux) {
        if (command == "install") return install();
        if (command == "uninstall") return uninstall();
    }
    stderr.writefln!"Unsupported command: %s"(command);
    return 1;
}

void printHelp() {
    writeln(
        "dshutil is a command-line utility that helps you create DSH scripts.\n" ~
        "The following subcommands are available:\n" ~
        "  create [name] [--single]  Creates a new DSH script (optionally with the given filename).\n" ~
        "                            If --single, dshs.d will be downloaded to the script's directory.\n" ~
        "  build <name>              Starts watching the given script and compiles it automatically.\n" ~
        "  compile <name>            Compiles the given script to a native executable.\n" ~
        "  install                   (Linux only) Installs a native version of dshutil to /usr/local/bin, and\n" ~
        "                            installs dshs.d to /usr/include.\n" ~
        "  uninstall                 (Linux only) Removes dshutil from /usr/local/bin removes dshs.d from /usr/include.\n" ~
        "  --help | -h               Show this help message.\n" ~
        "  --version | -v            Show the version of DSH that is being used.\n"
    );
}

/** 
 * Creates a new, empty script.
 * Params:
 *   args = The arguments to the command. Accepts one optional argument to
 *          specify a name for the script file.
 * Returns: 0 if successful, or 1 otherwise.
 */
int createScript(string[] args) {
    import std.conv : to;
    import std.string : strip;
    string filePath = "script.d";
    int tryCount = 1;
    while (filePath.exists) {
         filePath = "script" ~ tryCount.to!string ~ ".d";
    }
    bool useDub = true;
    if (args.length > 0) {
        string arg1 = args[0].strip;
        if (arg1 == "--single") {
            useDub = false;
        } else {
            filePath = arg1;
            if (filePath.exists) {
                stderr.writefln!"Cannot create script because %s already exists."(filePath);
                return 1;
            }
            if (args.length > 1 && args[1].strip == "--single") {
                useDub = false;
            }
        }
    }
    auto f = new File(filePath, "w");
    if (useDub) {
        // Only include the shebang on Linux.
        version (linux) {
            f.writeln("#!/usr/bin/env dub");
        }
        f.writeln("/+ dub.sdl:");
        f.writeln("    dependency \"dsh\" version=\"~>" ~ DSH_VERSION ~ "\"");
        f.writeln("+/");
    }
    f.writeln("import dsh;");
    f.writeln();
    f.writeln("void main() {");
    f.writeln("    print(\"Edit this to start writing your script.\");");
    f.writeln("}");
    f.writeln();
    f.close();
    if (useDub) {
        // If on linux, set the file to be executable.
        version (linux) {
            run("chmod +x " ~ filePath);
        }
    } else {
        downloadDshs(".");
        writeln("Downloaded dshs.d for DSH single-file mode. Include this file when compiling your script.");
    }
    writeln("Created script.");
    return 0;
}

/** 
 * Watches a file to build it using DUB single-file mode, any time a change
 * is noticed.
 * Params:
 *   args = The program arguments. Accepts a single required argument being
 *          the file to build/watch.
 * Returns: 0 if successful, or 1 otherwise.
 */
int buildScript(string[] args) {
    import std.string;
    if (args.length < 1) {
        stderr.writeln("Missing required file argument.");
        return 1;
    }
    string filePath = args[0].strip;
    if (!exists(filePath) || !isFile(filePath)) {
        stderr.writefln!"%s is not a file."(filePath);
        return 1;
    }
    import fswatch;
    import core.thread;
    auto watcher = FileWatch(filePath, false);
    writefln!"Watching %s to build when file changes."(filePath);
    ProcessBuilder pb = new ProcessBuilder();
    pb.run("dub build --single " ~ filePath);
    while (true) {
        foreach (event; watcher.getEvents()) {
            if (event.type == FileChangeEventType.modify) handleFileUpdate(filePath, pb);
        }
        Thread.sleep(seconds(1));
    }
}

private void handleFileUpdate(string filePath, ProcessBuilder pb) {
    import std.algorithm;
    writeln("File changed. Rebuilding...");
    if (pb.run("dub build --single " ~ filePath) == 0) {
        auto f = File(filePath, "r");
        foreach (string line; lines(f)) {
            if (startsWith(line, "// DSHTEST:")) runScriptTest(filePath, line);
        }
        f.close();
    }
}

private void runScriptTest(string filePath, string line) {
    import std.string;
    import std.algorithm;
    if (line.length < 12) return;
    string args = line[11 .. $].strip;
    if (args.length == 0) return;
    string scriptName = filePath;
    if (endsWith(filePath, ".d")) {
        scriptName = filePath[0..$-2];
    }
    version (linux) {
        scriptName = "./" ~ scriptName;
    }
    version (Windows) {
        scriptName = scriptName ~ ".exe";
    }
    string command = scriptName ~ " " ~ args;
    writefln!"Running \"%s\""(command);
    int result = run(command);
    writefln!"Script exited %d"(result);
}

int compileScript(string[] args) {
    import std.string;
    if (args.length < 1) {
        stderr.writeln("Missing required file argument.");
        return 1;
    }
    string filePath = args[0].strip;
    if (!exists(filePath) || !isFile(filePath)) {
        stderr.writefln!"%s is not a file."(filePath);
        return 1;
    }
    writeln("Compiling " ~ filePath);
    int r = run("dub build --single --build=release " ~ filePath);
    if (r != 0) {
        stderr.writefln!"Could not compile: %d"(r);
        return 1;
    }
    return 0;
}

private void downloadDshs(string path) {
    import requests;
    auto rq = Request();
    rq.useStreaming = true;
    auto rs = rq.get("https://raw.githubusercontent.com/andrewlalis/dsh/v"~DSH_VERSION~"/tools/dshs.d");
    auto stream = rs.receiveAsRange();
    import std.path;
    File dshFile = File(buildPath(path, "dshs.d"), "wb");
    while (!stream.empty) {
        dshFile.rawWrite(stream.front);
        stream.popFront;
    }
    dshFile.close();
}

version(linux) {
    int install() {
        runOrQuit("dub build --single --build=release dshutil.d");
        writeln("Copying dshutil to /usr/local/bin/dshutil");
        runOrQuit("sudo mv dshutil /usr/local/bin/dshutil");
        writeln("Installed dshutil to /usr/local/bin");
        writeln("Downloading dshs.d to /usr/include/dshs.d");
        runOrQuit("sudo wget https://raw.githubusercontent.com/andrewlalis/dsh/main/tools/dshs.d -O /usr/include/dshs.d");
        return 0;
    }

    int uninstall() {
        writeln("Removing dshutil from /usr/local/bin");
        runOrQuit("sudo rm -f /usr/local/bin/dshutil");
        writeln("Uninstalled dshutil from /usr/local/bin");
        if (exists("/usr/include/dshs.d")) {
            runOrQuit("sudo rm -f /usr/include/dshs.d");
            writeln("Removed /usr/include/dshs.d");
        }
        return 0;
    }
}
