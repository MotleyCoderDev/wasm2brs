# wasm2brs

```bash
git submodule update --init --recursive
mkdir build
cd build
cmake ..
make -j
```

# limitations
- Maximum number of arguments to a function is 32 (BrightScript limitation)
- Stack depth is dependent upon BrightScript's limitations and may be less than WASM
- Floating point math is approximate (where possible we use the correct algorithm, but it may not perfectly match processors)
- NaN value bit patterns are not represented
- Loading and storing (or reinterpreting) f32/f64 to i32/i64 and back may lose precision / bits
- Any float with an exponent of 0 (denormalized) is treated as 0 when loaded
- Large functions may need to be broken up as BrightScript has an internal limit on size