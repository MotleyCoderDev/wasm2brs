Function Start()
    w2bInit__()
    wasi_init(m.w2b_memory, "mandelbrot.wasm", {})

    iterations = 3%
    x =  -0.7436447860#
    y =  0.1318252536#
    d =  0.00029336#

    ts = CreateObject("roTimespan")

    offset = w2b_mandelbrot(iterations, x, y, d)

    print ts.TotalMilliseconds()

    print "------------------------------ FINISHED MANDLEBROT"

    ts.Mark()
    DrawScreen(m.w2b_memory, offset)
    print ts.TotalMilliseconds()
    print "------------------------------ SWAPPED SCREEN"
End Function

Function GetSettings()
    Return { graphical: True }
End Function
