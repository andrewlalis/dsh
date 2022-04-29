/** 
 * Utilities for interacting with the file system.
 */
module utils.fileutils;

import std.file;
import std.path;

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

unittest {
    ulong totalSize = 0;
    uint filesVisited = 0;
    void addSize(DirEntry entry) {
        totalSize += entry.size;
        filesVisited++;
    }
    walkDir(".", &addSize);
    assert(totalSize > 0);
    assert(filesVisited > 10);
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
    import std.regex;
    string[] matches = [];
    walkDirFiles(dir, (entry) {
        string filename = baseName(entry.name);
        Captures!string c = matchFirst(filename, pattern);
        if (!c.empty && c.hit.length == filename.length) matches ~= entry.name;
    }, recursive, maxDepth);
    return matches;
}

unittest {
    assert(findFiles("source", ".*\\.d", true, 0) == ["source/dsh.d"]);
    assert(findFiles(".", "dub.*", false).length == 2);
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

unittest {
    assert(findFilesByExtension(".", "json").length == 2);
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

unittest {
    assert(findFile(".", "dub\\.json") !is null);
    assert(findFile(".", ".*\\.d") is null);
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
    foreach (DirEntry entry; dirEntries(sourceDir, SpanMode.shallow)) {
        string destPath = buildPath(destDir, baseName(entry.name));
        if (entry.isDir) {
            copyDir(entry.name, destPath);
        } else if (entry.isFile) {
            copy(entry.name, destPath);
        }
    }
}

unittest {
    copyDir("source", "source2");
    assert(exists("source2") && isDir("source2"));
    assert(exists("source2/dsh.d"));
    rmdirRecurse("source2");
}
