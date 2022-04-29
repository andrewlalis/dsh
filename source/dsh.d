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
public import dshutils;

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
