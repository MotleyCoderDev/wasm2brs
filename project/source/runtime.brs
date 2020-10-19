'Function I32Store(buffer As Object, index As Integer, value As Integer)
'End Function
'Function I64Store(buffer As Object, index As Integer, value As Integer)
'End Function
'Function F32Store(buffer As Object, index As Integer, value As Integer)
'End Function
'Function F64Store(buffer As Object, index As Integer, value As Integer)
'End Function
Function I32Store8(buffer As Object, index As Integer, value As Integer)
    buffer[index] = value
End Function
'Function I64Store8(buffer As Object, index As Integer, value As Integer)
'End Function
'Function I32Store16(buffer As Object, index As Integer, value As Integer)
'End Function
'Function I64Store16(buffer As Object, index As Integer, value As Integer)
'End Function
'Function I64Store32(buffer As Object, index As Integer, value As Integer)
'End Function

Function I32Load(buffer as Object, index as Integer) as Integer
    Return buffer.GetSignedLong(index)
End Function
'Function I64Load(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
'Function F32Load(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
Function F64Load(buffer as Object, index as Integer) as Integer
    b0 = buffer[index]
    b1 = buffer[index + 1]
    b2 = buffer[index + 2]
    b3 = buffer[index + 3]

    sign = (b0 And 1<<7)>>7
    If b0 And 128 Then
        sign = -1
    End If

    exponent = (b0 << 1) And 255 
    ' NOT FINISHED (WAITING UNTIL F64 TESTS ARE RUNNING)
    Return 0
End Function
Function I32Load8S(buffer as Object, index as Integer) as Integer
    Return buffer.GetSignedByte(index)
End Function
'Function I64Load8S(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
Function I32Load8U(buffer As Object, index As Integer) as Integer
    Return buffer[index]
End Function
'Function I64Load8U(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
Function I32Load16S(buffer as Object, index as Integer) as Integer
    x = buffer[index] + (buffer[index + 1] << 8)
    If x > 32767 Then x = x + &HFFFF0000
    Return x
End Function
'Function I64Load16S(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
Function I32Load16U(buffer as Object, index as Integer) as Integer
    Return buffer[index] + (buffer[index + 1] << 8)
End Function
'Function I64Load16U(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
'Function I64Load32S(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
'Function I64Load32U(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function

Function GetMem() As Object
    If Not m.DoesExist("Mem") Then
        m.Mem = CreateObject("roByteArray")
    End If
    Return m.Mem
End Function

Function MemCpy(toBytes as Object, toOffset as Integer, fromBytes as Object, fromOffset as Integer, size as Integer)
    For i = 0 To size - 1 Step 1
        toBytes[i + toOffset] = fromBytes[i + fromOffset]
    End For
End Function
