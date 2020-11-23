Function Start()
    w2bInit__()
    wasi_init(m.w2b_memory, "javascript.wasm", {})
    w2b__start()
End Function

Function GetSettings()
    Return { RestartOnFailure: True }
End Function