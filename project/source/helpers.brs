
Function StringToBytes(str as String) as Object
    bytes = CreateObject("roByteArray")
    bytes.FromAsciiString(str)
    Return bytes
End Function

Function StringToBytesNullTerminated(str as String) as Object
    bytes = StringToBytes(str)
    bytes.push(0)
    Return bytes
End Function

Function StringFromBytes(memory as Object, offset as Integer, length as Integer) as Object
    bytes = CreateObject("roByteArray")
    ' This is just to resize the array (not a null terminator)
    bytes[length - 1] = 0
    MemoryCopy(bytes, 0, memory, offset, length)
    Return bytes.ToAsciiString()
End Function

Function MemoryCopyAll(toBytes as Object, toOffset as Integer, fromBytes as Object) as Integer
    Return MemoryCopy(toBytes, toOffset, fromBytes, 0, fromBytes.Count())
End Function

Function StringArrayWriteSizes(memory as Object, strings as Object, argc_pSize As Integer, argv_buf_pSize As Integer)
    bufferSize = 0
    For Each str In strings
        ' Add one for the null terminator
        bufferSize += str.Len() + 1
    End For

    I32Store(memory, argc_pSize, strings.Count())
    I32Store(memory, argv_buf_pSize, bufferSize)
End Function

Function StringArrayWriteMemory(memory as Object, strings as Object, argv_ppU8 As Integer, argv_buf_pU8 As Integer)
    For Each str In strings
        I32Store(memory, argv_ppU8, argv_buf_pU8)
        argv_ppU8 += 4
        argv_buf_pU8 += MemoryCopyAll(memory, argv_buf_pU8, StringToBytesNullTerminated(str))
    End For
End Function

Function PrintAndConsumeLines(str as String) as String
    While True
        newlineIndex = Instr(1, str, Chr(10))
        If newlineIndex <> 0 Then
            line = Left(str, newlineIndex - 1)
            str = Mid(str, newlineIndex + 1)
            Print line
        Else
            Exit While
        End If
    End While
    Return str
End Function