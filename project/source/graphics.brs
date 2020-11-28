Function wasi_experimental_create_surface(bitsPerPixel As Integer, width As Integer, height As Integer, colorTableOffset as Integer) as Void
    If bitsPerPixel <> 8 And bitsPerPixel <> 16 And bitsPerPixel <> 24 Then
        Throw "Invalid size for bitsPerPixel: " + bitsPerPixel.ToStr()
    End If

    bytesPerPixel = bitsPerPixel / 8

    If bitsPerPixel = 8 Then
        usedColors = 2 ^ bitsPerPixel
        colorTableSize = 4 * usedColors ' rgb_
    Else
        usedColors = 0
        colorTableSize = 0
    End If

    scanLineSize = width * bytesPerPixel
    If scanLineSize Mod 4 <> 0 Then
        Throw "Scanline size (width * bitsPerPixel / 8) must be a multiple of 4, scan line size was: " + scanLineSize.ToStr()
    End If

    allHeadersSize = 54
    pixelDataSize = width * height * bytesPerPixel

    fileSize = allHeadersSize + colorTableSize + pixelDataSize
    dataOffset = allHeadersSize + colorTableSize

    headers = CreateObject("roByteArray")
    ' Header
    I32Store8(headers, &H00, &H42) 'B
    I32Store8(headers, &H01, &H4D) 'M
    I32Store(headers, &H02, fileSize) ' FileSize
    I32Store(headers, &H06, 0) ' Reserved
    I32Store(headers, &H0A, dataOffset) ' DataOffset

    'InfoHeader
    I32Store(headers, &H0E, 40) ' InfoHeader Size
    I32Store(headers, &H12, width) ' Width
    I32Store(headers, &H16, height) ' Height
    I32Store16(headers, &H1A, 1) ' Planes
    I32Store16(headers, &H1C, bitsPerPixel) ' BitsPerPixel
    I32Store(headers, &H1E, 0) ' Compression (BI_RGB No compression)
    I32Store(headers, &H22, 0) ' ImageSize (0 is valid for no compression)
    I32Store(headers, &H26, 2835) ' XpixelsPerM
    I32Store(headers, &H2A, 2835) ' YpixelsPerM
    I32Store(headers, &H2E, usedColors) ' UsedColors
    I32Store(headers, &H32, 0) ' ImportantColors

    MemoryCopy(headers, allHeadersSize, m.wasi_memory, colorTableOffset, colorTableSize)

    m.surfaceHeaders = headers
    m.surfacePixelDataSize = pixelDataSize
    m.surfaceHeight = height

    m.screenport = CreateObject("roMessagePort")
    m.screen = CreateObject("roScreen", true, 320, 200)
    m.screen.SetMessagePort(m.screenport)
End Function

Function wasi_experimental_draw_surface(pixelDataOffset As Integer) as Void
    path = "tmp:/surface.bmp"
    m.surfaceHeaders.WriteFile(path)
    m.wasi_memory.AppendFile(path, pixelDataOffset, m.surfacePixelDataSize)
    bitmap = CreateObject("roBitmap", path)
    m.screen.DrawScaledObject(0, m.surfaceHeight, 1, -1, bitmap)
    m.screen.SwapBuffers()
End Function

Function wasi_experimental_poll_button() as Integer
    If m.screenport <> Invalid Then
        msg = m.screenport.GetMessage()
        If type(msg) = "roUniversalControlEvent" Then
            button = msg.GetInt()
            Return button
        End If
    End If
    Return &HFFFFFFFF
End Function