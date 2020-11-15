# wasm2brs

```bash
git submodule update --init --recursive
mkdir build
cd build
cmake ..
make -j
```

# WASM / Brightscript limitations
- Maximum number of arguments to a function is 32 (BrightScript limitation)
- Stack depth is dependent upon BrightScript's limitations and may be less than WASM
- Floating point math is approximate (where possible we use the correct algorithm, but it may not perfectly match processors)
- NaN value bit patterns are not represented
- Loading and storing (or reinterpreting) f32/f64 to i32/i64 and back may lose precision / bits
- Any float with an exponent of 0 (denormalized) is treated as 0 when loaded
- BrightScript has an internal limit on function size and number of local variables (around 254)
  - Results in `Variable table size exceeded. (compile error &hb0)`
  - Compiling with optimziations often alleviates the function size limit

# WASI limitations
- Environment variables and command line arguments must be ASCII strings

# Hooks
`m.external_print_line`:
  - Signature: `Function external_print_line(fd as Integer, str as String) as Void`
  - Will be called every time a line is parsed by stdout or stderr.
  - Will *NOT* be called if the user provides their own `m.external_output`, however the helper function `PrintAndConsumeLines` can emulate the same behavior.

`m.external_output`:
  - Signature: `Function external_output(fd as Integer, bytes as Object) as Void`
  - Will be called when raw bytes are written to stdout or stderr.
  - Useful if the output of a program is binary data instead of text, or if special parsing is needed.
  - Overriding this function will prevent `m.external_print_line` from being called, however the helper function `PrintAndConsumeLines` can emulate the same behavior.
