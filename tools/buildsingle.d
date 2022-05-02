#!/usr/bin/env dub
/+ dub.sdl:
    dependency "dsh" version="~>1.5.1"
+/

/**
 * This script is used to build `dshs.d`, which is a single-file version of DSH
 * that can be included in other D programs without the use of Dub.
 */
module tools.buildsingle;

import dsh;
import std.algorithm;
import std.array;
import std.string;

const MAIN_SOURCE = "../source/dsh.d";

int main() {
    string mainSourceText = readText(MAIN_SOURCE);
    ptrdiff_t importLocation = indexOf(mainSourceText, "public import dshutils;");
    mainSourceText = mainSourceText.replaceAll("public import dshutils;", "").stripTests;
    auto app = appender!string;
    app ~= mainSourceText[0 .. importLocation];

    findFilesByExtension("../source/dshutils", ".d")
        .filter!(s => !s.endsWith("package.d"))
        .each!((s) {
            string src = readText(s).strip.cleanSource.stripTests;
            app ~= "// IMPORTED SOURCE: " ~ s ~ "\n";
            app ~= src ~ "\n";
        });

    app ~= mainSourceText[importLocation .. $];
    std.file.write("dshs.d", app[]);
    print("Wrote single-file dsh to dshs.d.");
    
    return 0;
}

private string cleanSource(string src) {
    string moduleText = dsh.find(src, "module .*;");
    if (moduleText !is null) {
        ptrdiff_t moduleIndex = indexOf(src, moduleText);
        src = src[moduleIndex + moduleText.length .. $];
    }
    return stripTests(src);
}

private string stripTests(string src) {
    while (true) {
        const marker = "unittest {";
        ptrdiff_t start = indexOf(src, marker);
        if (start == -1) break;
        ptrdiff_t end = indexOf(src, "\n}", start);
        src = src[0 .. start] ~ src[end + 2 .. $];
    }
    return src;
}
