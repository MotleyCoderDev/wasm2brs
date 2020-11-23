Function Start()
    w2bInit__()
    wasi_init(m.w2b_memory, "mandelbrot.wasm", {})
    w2b__start()
End Function

Function GetSettings()
    Return { graphical: True }
End Function
