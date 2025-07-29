Function Start()
    _rust_wasmInit__()
    wasi_init(m._rust_wasm_memory, "rust.wasm", {})
    _rust_wasm__start()
    wasi_shutdown()
End Function
