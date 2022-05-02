# DSH Tools
This directory contains some scripts. Their descriptions are given below.

## `dshutil.d`
Included in this repository is a `dshutil.d` executable script. You can use this script to make it easier to write DSH scripts. It includes the following commands:
- `./dshutil.d create [filename]` - Creates a new DSH script with all the necessary boilerplate code.
- `./dshutil.d build <filename>` - Starts watching the given script, and rebuilds it if any changes are made. If the script starts with a comment line like `// DSHTEST: `, the script will be executed with everything following the `:` as command-line arguments to the script.
- `./dshutil.d compile <filename>` - Builds an executable file using `dub build --single <filename> --build=release`.

On linux, you may additionally perform the following commands to install dshutil as an executable on your system, to help with scripts anywhere.

- `./dshutil.d install` - Builds and installs this script in `/usr/local/bin` so that you can simply run `dshutil` from anywhere.
- `./dshutil.d uninstall` - Removes `dshutil` from `/usr/local/bin`, if it exists.

As a shortcut, you can install the latest version of dshutil by executing the following command:
```
wget https://raw.githubusercontent.com/andrewlalis/dsh/main/tools/dshutil.d -O dshutil.d
chmod +x dshutil.d
./dshutil.d install
```

## `dshs.d`
A single-file version of DSH. Use this when you don't want to use dub for DSH scripts, but want to instead directly compile your script to an executable. For example, suppose we have the following `hi.d` script which makes use of DSH's `print` function:
```d
import dsh;
void main(string[] args) {
    print("hi, %s", args[0]);
}
```
We can compile this script using `dmd test.d path/to/dshs.d`.

## `buildsingle.d`
Builds a single-file version of DSH to `dshs.d`, which can be useful in cases where you don't want to use dub, but instead just want to compile your script with `dmd my_script.d dshs.d`. It does this by combining the source code of all `.d` sources into a single `dshs.d` file that contains the `dsh` module. It also strips out unittests, as these are not necessary when the main multi-file project is tested.

## `buildsingle_test.d`
A simple testing script that can be run to ensure that `buildsingle.d` can successfully build a single-file DSH script.
