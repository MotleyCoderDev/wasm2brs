# Building wasm2brs
All the dependencies for wasm2brs are installed within a Docker image that can be run with `./run.sh`.

```bash
git submodule update --init --recursive
./run.sh make
```

It is not recommended, but if you wish to run without our Docker image, you must install:
- cmake
- clang
- python3
- pip3
- wasienv
- nodejs
- npm

# WASM / Brightscript limitations
- Maximum number of arguments to a function is 32 due to BrightScript
- Stack depth is dependent upon BrightScript's limitations and may be less than WASM standards
- Floating point math is approximate (where possible we use the correct algorithm, but it may not perfectly match processors)
- NaN value bit patterns are not represented
- Loading and storing (or reinterpreting) Float/Double (also called f32/f64) to i32/i64 and back may lose precision / bits
- Any Float/Double with an exponent of 0 (denormalized) is treated as 0 when loaded
- Long jumps and exceptions are not yet supported (header `setjmp.h` does not exist)
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
- BrightScript files cannot exceed 2MB and must be broken up
  - Results in `Error loading file. (compile error &hb9) in pkg:/source/test.brs(NaN)`
- BrightScript debugger will wrap line numbers beyond 65536 (overflow)

# WASI limitations
- Environment variables, command line arguments, and stdout/stderr/stdin strings only currently support ASCII strings

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

To use a non-default password:
```bash
./run.sh make run_test ARGS="password ..."
```

To run a specific test you can specify the .wast file as an absolute path, otherwise it assumes it's in the `third_part/testsuite/` directory, for example `i32.wast`:
```bash
./run.sh make run_test ARGS="wast i32.wast"
```