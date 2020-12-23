' Copyright 2020, Trevor Sundberg. See LICENSE.md
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
    Return Slice(memory, offset, length).ToAsciiString()
End Function

Function Slice(bytes as Object, offset as Integer, length as Integer) as Object
    part = CreateObject("roByteArray")
    MemoryCopy(part, 0, bytes, offset, length)
    Return part
End Function

Function OptimizedSlice(bytes as Object, offset as Integer, length as Integer) as Object
    If offset = 0 And length = bytes.Count() Return bytes
    Return Slice(bytes, offset, length)
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

Function PrintAndConsumeLines(fd as Integer, bytes as Object, lineCallback as Dynamic) as Object
    begin = 0
    For i = 0 To bytes.Count() - 1
        If bytes[i] = 10 Then
            line = StringFromBytes(bytes, begin, i - begin)
            Print line
            If lineCallback <> Invalid Then lineCallback(fd, line)
            begin = i + 1
        End If
    End For
    Return OptimizedSlice(bytes, begin, bytes.Count() - begin)
End Function

Function Min(a as Dynamic, b as Dynamic) as Dynamic
    If a < b Return a
    Return b
End Function

Function Max(a as Dynamic, b as Dynamic) as Dynamic
    If a > b Return a
    Return b
End Function

Function IsString(value as Dynamic) as Boolean
    runtimeType = LCase(Type(value))
    Return runtimeType = "string" Or runtimeType = "rostring"
End Function
