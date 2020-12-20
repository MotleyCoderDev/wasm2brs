# Building wasm2brs
All the dependencies for wasm2brs are installed within a Docker image that can be run with `./run.sh`.

To build our repo:
```bash
git submodule update --init --recursive
./run.sh make
```

To run without the Docker image (not recommended) be sure to install the same dependencies as listed in the `Dockerfile`.

# Running the samples
```bash
./run.sh make doom
```

This will place all the output files in `project/`. To run, either side load the project manually or use vscode with the BrightScript Language extension. When opening our repository in vscode, running the debugger will run `project/`.

The samples we have are:
- `cmake`
- `doom`
- `files`
- `mandelbrot`
- `javascript`
- `rust`

# Starting your own project
The easiest way to get started is to look in our [samples](samples) directory. Specifically the [cmake](samples/cmake) sample is setup to be used as a template.

If you wish to use libc/libc++, then you should use install [wasienv](https://github.com/wasienv/wasienv), which comes with `wasi-libc` as well as helpful scripts that run clang/make/cmake/etc with the correct compiler flags and directories.

The mandelbrot sample shows how to use clang directly without wasienv and no standard libraries. Note that `wasm-ld` is required.

In general the process looks like:
- Run your build tool of choice to output a `.wasm` file, typicaly in Release mode with `-Oz`
- Run Binaryen's `wasm-opt` to perform wasm specific optimizations that reduce goto/labels and stack variables. This is located in `build/wasm2brs/third_party/binaryen/bin/wasm-opt`
- Run `wasm2brs` to convert into a `.brs` file. This is located in `build/wasm2brs/wasm2brs`

# WASM / Brightscript limitations
- Maximum number of arguments to a function is 32 due to BrightScript
- Stack depth is dependent upon BrightScript's limitations and may be less than WASM standards
- Floating point math is approximate (where possible we use the correct algorithm, but it may not perfectly match processors)
- NaN value bit patterns are not represented
- Loading and storing (or reinterpreting) Float/Double (also called f32/f64) to i32/i64 and back may lose precision / bits
- Any Float/Double with an exponent of 0 (denormalized) is treated as 0 when loaded
- Long jumps and exceptions are not yet supported (header `setjmp.h` does not exist, but we provide a stub that aborts)
- BrightScript files cannot exceed 2MB and must be broken up
  - Results in `Error loading file. (compile error &hb9) in pkg:/source/test.brs(NaN)`
  - Files are broken up automatically by wasm2brs via adding a number to the end (e.g. main.brs, main1.brs, main2.brs...)
- BrightScript debugger will wrap line numbers beyond 65536 (overflow)
  - Files are broken up automatically by wasm2brs so they don't exceed 65536, in the same way as the 2MB limit
- For the following BrightScript errors, optimizing (O4 or Oz) helps alleviate the issues:
  - BrightScript has an internal limit on the number of `If`/`Else If` blocks in a function
    - Results in `Internal limit size exceeded. (compile error &hae) in pkg:/source/test.brs(...)`
    - By observation, allowed to have maximum 279 blocks for the first group, and then maximum 25 blocks for subsequent groups
    - The last `Else` clause does not contribute to this limit
    - No limit on how many groups
  - BrightScript has an internal limit of 253 variables in a function including function parameters
    - Results in `Variable table size exceeded. (compile error &hb0)`
  - BrightScript has an internal limit of 256 goto labels in a function
    - Results in `Label/Line Not Found. (compile error &h0e) in pkg:/source/test.brs(NaN)'label256'`
    - A function can actually have more than 256 labels, but any attempts to goto labels beyond 256 will fail with the above error
    - BrightScript compilation becomes exponentially slower with the number of labels in a function (beyond 10000 will hard lock the device)

# WASI limitations
- Environment variables, command line arguments, and stdout/stderr/stdin strings always in UTF8 encoding

# API
`Function external_append_stdin(bytesOrString as Dynamic) as Void`
- Append an `roByteArray` or `String` to stdin

# Hooks
`m.external_print_line = custom_print_line`:
- Signature: `Function custom_print_line(fd as Integer, str as String) as Void`
- Will be called every time a line is parsed by stdout or stderr.
- Will *NOT* be called if the user provides their own `m.external_output`, however the helper function `PrintAndConsumeLines` can emulate the same behavior.

`m.external_output = custom_output`:
- Signature: `Function custom_output(fd as Integer, bytes as Object) as Void`
- Parameter bytes is an `roByteArray`
- Will be called when raw bytes are written to stdout (fd = 1) or stderr (fd = 2).
- Useful if the output of a program is binary data instead of text, or if special parsing is needed.
- Overriding this function will prevent `m.external_print_line` from being called, however the helper function `PrintAndConsumeLines` can emulate the same behavior.

`m.external_wait_for_stdin = custom_wait_for_stdin`:
- Signature: `Function custom_wait_for_stdin() as Void`
- Called when an attempt was made to read from stdin, but there was no bytes available.
- During this callback, you should invoke `external_append_stdin`.
- When the callback completes, the program will continue its attempt to read from stdin.

# Run tests
Run all the tests, this will auto discover your device with a default password of `rokudev`.
```bash
./run.sh make run_test
```

To run a specific test you can specify the .wast file as an absolute path, otherwise it assumes it's in the `third_part/testsuite/` directory, for example `i32.wast`:
```bash
./run.sh make run_test ARGS="wast i32.wast"
```

To use a non-default password:
```bash
./run.sh make run_test ARGS="password ..."
```

To deploy to a specific device (e.g. `1.2.3.4`):
```bash
./run.sh make run_test ARGS="deploy 1.2.3.4"
```

To provide multiple arguments:
```bash
./run.sh make run_test ARGS="password ... deploy 1.2.3.4 wast i32.wast"
```
