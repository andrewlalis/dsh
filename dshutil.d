#!/usr/bin/env dub
/+ dub.sdl:
    dependency "dsh" version="~>1.0.0"
    dependency "fswatch" version="~>0.6.0"
+/

/**
 * A helper program that can be used to make, build, and manage dsh scripts.
 */
module dshutil;

import dsh;

int main(string[] args) {
    import std.string;
    if (args.length < 2) {
        stderr.writeln("Missing required command argument.");
        return 1;
    }
    string command = args[1].strip;
    if (command == "create") return createScript(args[2..$]);
    if (command == "build") return buildScript(args[2..$]);
    
    stderr.writefln!"Unsupported command: %s"(command);
    return 1;
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
    if (args.length > 0) {
        filePath = args[0].strip;
        if (filePath.exists) {
            stderr.writefln!"Cannot create script because %s already exists."(filePath);
            return 1;
        }
    }
    auto f = new File(filePath, "w");
    // Only include the shebang on Linux.
    version (linux) {
        f.writeln("#!/usr/bin/env dub");
    }
    f.writeln("/+ dub.sdl:");
    f.writeln("    dependency \"dsh\" version=\"~>1.1.0\"");
    f.writeln("+/");
    f.writeln("import dsh;");
    f.writeln();
    f.writeln("void main() {");
    f.writeln("    writeln(\"Edit this to start writing your script.\");");
    f.writeln("}");
    f.writeln();
    f.close();
    // If on linux, set the file to be executable.
    version (linux) {
        run("chmod +x " ~ filePath);
    }
    writefln!"Created script: %s. Call \"./%s\" to run your script."(filePath, filePath);
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
