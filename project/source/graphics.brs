Function CreateSurface(bitsPerPixel As Integer, width As Integer, height As Integer, colorTableMemory As Object, colorTableOffset as Integer)
    If bitsPerPixel <> 8 And bitsPerPixel <> 16 And bitsPerPixel <> 24 Then
        Throw "Invalid size for bitsPerPixel: " + bitsPerPixel.ToStr()
    End If

    bytesPerPixel = bitsPerPixel / 8

    If bitsPerPixel = 8 Then
        colorTableSize = 4 * (2 ^ bitsPerPixel) ' rgb_
    Else
        colorTableSize = 0
    End If

    scanLineSize = width * bytesPerPixel
    If scanLineSize Mod 4 <> 0 Then
        Throw "Scanline size (width * bitsPerPixel / 8) must be a multiple of 4, scan line size was: " + scanLineSize.ToStr()
    End If

    usedColors = 2 ^ bitsPerPixel

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

    MemoryCopy(headers, allHeadersSize, colorTableMemory, colorTableOffset, colorTableSize)

    Return {
        bitsPerPixel: bitsPerPixel,
        width: width,
        height: height,
        headers: headers,
        pixelDataSize: pixelDataSize
    }
End Function

Function SurfaceToBitmap(surface As Object, pixelDataMemory As Object, pixelDataOffset As Integer) As Object
    path = "tmp:/surface.bmp"
    surface.headers.WriteFile(path)
    pixelDataMemory.AppendFile(path, pixelDataOffset, surface.pixelDataSize)
    Return CreateObject("roBitmap", path)
End Function
