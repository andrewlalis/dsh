#!/usr/bin/env dub
/+ dub.sdl:
    dependency "dsh" version="~>1.5.1"
+/

/** 
 * Testing script that is used to ensure that the single-file dshs.d script
 * is legitimate and without error, by compiling and running a test script that
 * uses the single-file dshs.d.
 */
module tools.buildsingle_test;

import dsh;

void main() {
    print("Building single-file dshs.d.");
    runOrQuit("./buildsingle.d");
    assert(exists("dshs.d"));
    if (exists("test.d")) std.file.remove("test.d");
    std.file.write(
        "test.d",
        "module test;\n" ~
        "import dsh;\n" ~ 
        "void main() {\n" ~
        "  print(\"Hello world!\");\n" ~
        "}\n"
    );
    print("Compiling test.d using single-file dshs.d.");
    runOrQuit("dmd test.d dshs.d");
    print("Running test executable.");
    runOrQuit("./test");
    print("Successful!");
}
