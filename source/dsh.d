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

public void print(string, Args...)(string s, Args args) {
    writefln(s, args);
}

public void error(string, Args...)(string s, Args args) {
    stderr.writefln(s, args);
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

unittest {
    assert(!isDirEmpty("source"));
    assert(!isDirEmpty("source/dsh.d"));
    assert(!isDirEmpty("source/some-non-existant-file.blah"));
    auto d = ".test_empty_dir";
    d.mkdir;
    scope(exit) d.rmdir;
    assert(isDirEmpty(d));
}

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

unittest {
    auto p = new ProcessBuilder()
        .outputTo(".test.txt")
        .workingDir("source");
    p.run("ls");

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

unittest {
    version(Posix) {
        assert(run("ls") == 0);
    }
    version(Windows) {
        assert(run("dir") == 0);
    }
    assert(run("kjafhdflkuahlkefuhfahlfeuhaf") == -1);
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

unittest {
    assert(getEnv("PATH") !is null);
    assert(getEnv("flkahelkuhfalukfehlakuefhl") is null);
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

unittest {
    assert(getEnv("dsh_test_env_1") is null);
    setEnv("dsh_test_env_1", "yes");
    assert(getEnv("dsh_test_env_1") == "yes");
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
    import std.regex;
    auto re = regex(pattern);
    return std.regex.replaceAll(s, re, r);
}

unittest {
    assert(replaceAll("abc", "a", "d") == "dbc");
    assert(replaceAll("123abc123", "\\d+", "") == "abc");
}
