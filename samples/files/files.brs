Function Start()
    w2bInit__()
    wasi_init(m.w2b_memory, "main.wasm", { env: ["TEST=Hello"]})
    w2b__start()
End Function
