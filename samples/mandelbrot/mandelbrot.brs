' This takes several minutes to complete
Function Start()
    w2bInit__()
    wasi_init(m.w2b_memory, "mandelbrot.wasm", {})
    roku_create_surface(24, 320, 200)

    iterations = 1000%
    x =  -0.7436447860#
    y =  0.1318252536#
    d =  0.00029336#

    ts = CreateObject("roTimespan")

    offset = w2b_mandelbrot(iterations, x, y, d)

    print ts.TotalMilliseconds()

    roku_draw_surface(offset)
    wasi_shutdown()
End Function

Function GetSettings()
    Return { PauseOnExit: True }
End Function
