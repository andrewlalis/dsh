/** 
 * DSH provides conveniences that make it easier to write simple scripts in D.
 * 
 * Several phobos modules are preemptively imported so that you don't need to
 * do so in your script. Additionally, helper functions are defined which are
 * especially useful for scripts.
 */
module dsh;

// Public imports from the standard library.
public import std.stdio;
public import std.file;

// Import all the various utilities.
// IMPORTED SOURCE: ../source/dshutils/fileutils.d


import std.file;

/** 
 * Removes a file or directory if it exists.
 * Params:
 *   file = The file or directory to remove.
 *   recursive = Whether to recursively remove subdirectories.
 * Returns: True if the file or directory was removed, or false otherwise.
 */
public bool removeIfExists(string file, bool recursive = true) {
    if (!exists(file)) return false;
    if (isFile(file)) {
        remove(file);
    } else if (isDir(file)) {
        if (recursive) {
            rmdirRecurse(file);
        } else {
            rmdir(file);
        }
    }
    return true;
}

/** 
 * Removes a set of files or directories, if they exist.
 * Returns: True if any of the given files were removed.
 */
public bool removeAnyIfExists(string[] files...) {
    bool any = false;
    foreach (file; files) {
        bool result = removeIfExists(file);
        any = any || result;
    }
    return any;
}

/** 
 * Checks if a directory is empty.
 * Params:
 *   dir = The directory to check.
 * Returns: True if the given directory exists, is a directory, and is empty.
 */
public bool isDirEmpty(string dir) {
    import std.range : empty;
    import std.array : array;
    if (!exists(dir) || !isDir(dir)) return false;
    return empty(dirEntries(dir, SpanMode.shallow).array);
}



/** 
 * Walks through all the entries in a directory, and applies the given visitor
 * function to all entries.
 * Params:
 *   dir = The directory to walk through.
 *   visitor = A visitor delegate function to apply to all entries discovered.
 *   recursive = Whether to recursively walk through subdirectories.
 *   maxDepth = How deep to search recursively. -1 indicates infinite recursion.
 */
public void walkDir(string dir, void delegate(DirEntry entry) visitor, bool recursive = true, int maxDepth = -1) {
    if (!exists(dir) || !isDir(dir)) return;
    foreach (DirEntry entry; dirEntries(dir, SpanMode.shallow)) {
        visitor(entry);
        if (recursive && entry.isDir && (maxDepth > 0 || maxDepth == -1)) {
            walkDir(entry.name, visitor, recursive, maxDepth - 1);
        }
    }
}



/** 
 * Walks through all the entries in a directory, and applies the given visitor
 * function to all entries for which a given filter function returns true.
 * Params:
 *   dir = The directory to walk through.
 *   visitor = A visitor delegate function to apply to all entries discovered.
 *   filter = A filter delegate that determines if an entry should be visited.
 *   recursive = Whether to recursively walk through subdirectories.
 *   maxDepth = How deep to search recursively. -1 indicates infinite recursion.
 */
public void walkDirFiltered(
    string dir,
    void delegate(DirEntry entry) visitor,
    bool delegate(DirEntry entry) filter,
    bool recursive = true,
    int maxDepth = -1
) {
    walkDir(dir, delegate(DirEntry entry) {
        if (filter(entry)) visitor(entry);
    }, recursive, maxDepth);
}

/** 
 * Walks through all files in a directory.
 * Params:
 *   dir = The directory to walk through.
 *   visitor = A visitor delegate function to apply to all entries discovered.
 *   recursive = Whether to recursively walk through subdirectories.
 *   maxDepth = How deep to search recursively. -1 indicates infinite recursion.
 */
public void walkDirFiles(
    string dir,
    void delegate(DirEntry entry) visitor,
    bool recursive = true,
    int maxDepth = -1
) {
    walkDirFiltered(dir, visitor, (entry) {return entry.isFile;}, recursive, maxDepth);
}

/** 
 * Finds matching files in a directory.
 * Params:
 *   dir = The directory to search in.
 *   pattern = A regex pattern to match against each filename.
 *   recursive = Whether to recursively search subdirectories.
 *   maxDepth = How deep to search recursively. -1 indicates infinite recursion.
 * Returns: A list of matching filenames.
 */
public string[] findFiles(string dir, string pattern, bool recursive = true, int maxDepth = -1) {
    import std.regex : matchFirst, Captures;
    import std.path : baseName;
    string[] matches = [];
    walkDirFiles(dir, (entry) {
        string filename = baseName(entry.name);
        Captures!string c = matchFirst(filename, pattern);
        if (!c.empty && c.hit.length == filename.length) matches ~= entry.name;
    }, recursive, maxDepth);
    return matches;
}



/** 
 * Finds all files in a directory that end with the given extension text.
 * Params:
 *   dir = The directory to search in.
 *   extension = The extension for matching files, such as ".txt" or ".d"
 *   recursive = Whether to recursively search subdirectories.
 *   maxDepth = How deep to search recursively. -1 indicates infinite recursion.
 * Returns: The list of matching files.
 */
public string[] findFilesByExtension(string dir, string extension, bool recursive = true, int maxDepth = -1) {
    return findFiles(dir, ".*" ~ extension, recursive, maxDepth);
}



/** 
 * Tries to find a single file matching the given pattern.
 * Params:
 *   dir = The directory to search in.
 *   pattern = A regex pattern to match against each filename.
 *   recursive = Whether to recursively search subdirectories.
 *   maxDepth = How deep to search recursively. -1 indicates infinite recursion.
 * Returns: The single matching file that was found, or null if no match was
 * found, or if multiple matches were found.
 */
public string findFile(string dir, string pattern, bool recursive = true, int maxDepth = -1) {
    auto matches = findFiles(dir, pattern, recursive, maxDepth);
    if (matches.length != 1) return null;
    return matches[0];
}



/** 
 * Copies all files from the given source directory, to the given destination
 * directory. Will create the destination directory if it doesn't exist yet.
 * Overwrites any files that already exist in the destination directory.
 * Params:
 *   sourceDir = The source directory to copy from.
 *   destDir = The destination directory to copy to.
 */
public void copyDir(string sourceDir, string destDir) {
    if (!isDir(sourceDir)) return;
    if (exists(destDir) && !isDir(destDir)) return;
    if (!exists(destDir)) mkdirRecurse(destDir);
    import std.path : buildPath, baseName;
    foreach (DirEntry entry; dirEntries(sourceDir, SpanMode.shallow)) {
        string destPath = buildPath(destDir, baseName(entry.name));
        if (entry.isDir) {
            copyDir(entry.name, destPath);
        } else if (entry.isFile) {
            copy(entry.name, destPath);
        }
    }
}


// IMPORTED SOURCE: ../source/dshutils/stringutils.d


/** 
 * Convenience method to replace all occurrences of matching patterns with
 * some other string.
 * Params:
 *   s = The string to replace things in.
 *   pattern = The regular expression to use to match.
 *   r = The thing to replace each match with.
 * Returns: The string with all matches replaced.
 */
public string replaceAll(string s, string pattern, string r) {
    if (s is null) return null;
    if (r is null) return s;
    import std.regex;
    auto re = regex(pattern);
    return std.regex.replaceAll(s, re, r);
}



/** 
 * Finds a matching substring in a given string.
 * Params:
 *   s = The string to find a pattern in.
 *   pattern = The pattern to look for.
 * Returns: The matching string, if one was found, or null otherwise.
 */
public string find(string s, string pattern) {
    if (s is null || pattern is null) return null;
    import std.regex;
    Captures!string c = std.regex.matchFirst(s, pattern);
    if (c.empty) return null;
    return c.hit;
}


// IMPORTED SOURCE: ../source/dshutils/processutils.d


import dsh;

/** 
 * Helper for more easily creating processes.
 */
public class ProcessBuilder {
    private File stdin;
    private File stdout;
    private File stderr;
    private string[string] env;
    private string dir;

    public this() {
        this.stdin = std.stdio.stdin;
        this.stdout = std.stdio.stdout;
        this.stderr = std.stdio.stderr;
        this.dir = getcwd();
    }

    public ProcessBuilder inputFrom(string filename) {
        this.stdin = File(filename, "r");
        return this;
    }

    public ProcessBuilder outputTo(string filename) {
        this.stdout = File(filename, "w");
        return this;
    }

    public ProcessBuilder errorTo(string filename) {
        this.stderr = File(filename, "w");
        return this;
    }

    public ProcessBuilder withEnv(string key, string value) {
        this.env[key] = value;
        return this;
    }

    public ProcessBuilder workingDir(string dir) {
        this.dir = dir;
        return this;
    }

    public int run(string command) {
        import std.process;
        import std.regex;
        try {
            auto r = regex("\\s+");
            auto s = split(command, r);
            auto pid = spawnProcess(s, this.stdin, this.stdout, this.stderr, this.env, Config.none, this.dir);
            return wait(pid);
        } catch (ProcessException e) {
            error("Could not start process \"%s\": %s", command, e.msg);
            return -1;
        }
    }
}



/**
 * Runs the given command using the user's shell.
 * Params:
 *   cmd = The command to execute.
 * Returns: The exit code from the command. Generally, 0 indicates success. If
 * the process could not be started, -1 is returned.
 */
public int run(string cmd) {
    return new ProcessBuilder().run(cmd);
}



/** 
 * Convenience method to run a command and pipe output to a file.
 * Params:
 *   cmd = The command to run.
 *   outputFile = The file to send output to.
 * Returns: The exit code from the command.
 */
public int run(string cmd, string outputFile) {
    return new ProcessBuilder()
        .outputTo(outputFile)
        .errorTo(outputFile)
        .run(cmd);
}

/** 
 * Runs the given command, and exits the program if the return code is not 0.
 * Params:
 *   cmd = The command to run.
 */
public void runOrQuit(string cmd) {
    import core.stdc.stdlib : exit;
    int r = run(cmd);
    if (r != 0) {
        error("Process \"%s\" exited with code %d", cmd, r);
        exit(r);
    }
}

public void runOrQuit(string cmd, string outputFile) {
    import core.stdc.stdlib : exit;
    int r = run(cmd, outputFile);
    if (r != 0) {
        error("Process \"%s\" exited with code %d", cmd, r);
        exit(r);
    }
}

/** 
 * Gets an environment variable.
 * Params:
 *   key = The name of the environment variable.
 * Returns: The value of the environment variable, or null.
 */
public string getEnv(string key) {
    import std.process : environment;
    try {
        return environment[key];
    } catch (Exception e) {
        return null;
    }
}



/** 
 * Sets an environment variable.
 * Params:
 *   key = The name of the environment variable.
 *   value = The value to set.
 */
public void setEnv(string key, string value) {
    import std.process : environment;
    try {
        environment[key] = value;
    } catch (Exception e) {
        error("Could not set environment variable \"%s\": %s", key, e.msg);
    }
}




public void print(string, Args...)(string s, Args args) {
    writefln(s, args);
}

public void error(string, Args...)(string s, Args args) {
    stderr.writefln(s, args);
}

/** 
 * Sleeps for a specified amount of milliseconds.
 * Params:
 *   amount = The amount of milliseconds to sleep for.
 */
public void sleepMillis(long amount) {
    import core.thread;
    Thread.sleep(msecs(amount));
}

/** 
 * Sleeps for a specified amount of seconds.
 * Params:
 *   amount = The amount of seconds to sleep for.
 */
public void sleepSeconds(long amount) {
    import core.thread;
    Thread.sleep(seconds(amount));
}
