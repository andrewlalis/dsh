# dsh
A single-import D library for writing scripts.

Here's an example of how you can write a single-file executable D script with DSH:
```d
#!/usr/bin/env dub
/+ dub.sdl:
    dependency "dsh" version="~>1.1.0"
+/
import dsh;

void main() {
    writeln("Hello world!");
    "cat dub.json".run;
}
```

To write your own DSH script, you can copy the above example to your own local D file.

If you use a script often, you might want to consider compiling your script to an executable. You can do so like this:

```
dub build --single script.d
```
> Add the `--build=release` option to specify that you're building a release and not a debug build.

## Why use DSH?
DSH offers a few main benefits over writing a script in plain D:
- You get all the benefits of the D language: strong type checking, high-level constructs and a familiar syntax that compiles to native machine code.
- Type-safety combined with universal function call syntax make it easy to write expressive scripts that are readable by those who know nothing about D.
- Easily extend the functionality of your script by importing literally any library from the [DUB package registry](https://code.dlang.org).
- Cross-platform by default, but D gives you the ability to write platform-specific code whenever you need.

## dshutil.d
Included in this repository is a `dshutil.d` executable script. You can use this script to make it easier to write DSH scripts. It includes the following commands:
- `./dshutils.d create [filename]` - Creates a new DSH script with all the necessary boilerplate code.
- `./dshutils.d build <filename>` - Starts watching the given script, and rebuilds it if any changes are made. If the script starts with a comment line like `// DSHTEST: `, the script will be executed with everything following the `:` as command-line arguments to the script.
