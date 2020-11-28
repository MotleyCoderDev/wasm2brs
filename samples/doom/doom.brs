Function Start()
    w2bInit__()
    wasi_init(m.w2b_memory, "doom.wasm", { env: ["DOOMWADDIR=pkg:/source"] })
    w2b__start()
End Function
