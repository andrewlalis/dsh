/** 
 * Utilities for interacting with strings.
 */
module dshutils.stringutils;

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

unittest {
    assert(replaceAll("abc", "a", "d") == "dbc");
    assert(replaceAll("123abc123", "\\d+", "") == "abc");
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

unittest {
    assert(find("abc123abc", "\\d+") == "123");
    assert(find("1.345f dollars", "\\d+\\.\\d+f") == "1.345f");
    assert(find("abc", "\\d") is null);
    assert(find(null, "\\w+") is null);
}