/** 
 * Utilities for running and interacting with processes.
 */
module dshutils.processutils;

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
    print("Running test of run(cmd). Expect some test output!");
    version(Posix) {
        assert(run("ls") == 0);
    }
    version(Windows) {
        assert(run("dir") == 0);
    }
    print("Testing run(cmd) with a non-existent command. Expect an error message.");
    assert(run("kjafhdflkuahlkefuhfahlfeuhaf") == -1);
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