
Function FloatInf() as Float
    Return 1e39
End Function

Function FloatNan() as Float
    Return 0 * FloatInf()
End Function

Function FloatNegativeZero() as Float
    Return -1 / FloatInf()
End Function

Function IsFloatNan(value as Float) as Boolean
    Return value <> value
End Function

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
    Return buffer[index] + (buffer[index + 1] << 8) + (buffer[index + 2] << 16) + (buffer[index + 3] << 24)
End Function
Function I64Load(buffer as Object, index as Integer) as LongInteger
    Return 0& + buffer[index] + (buffer[index + 1] << 8) + (buffer[index + 2] << 16) + (buffer[index + 3] << 24) + (buffer[index + 4] << 32&) + (buffer[index + 5] << 40&) + (buffer[index + 6] << 48&) + (buffer[index + 7] << 56&)
End Function
Function F32Load(buffer as Object, index as Integer) as Float
    b0 = buffer[index + 3]
    b1 = buffer[index + 2]
    b2 = buffer[index + 1]
    b3 = buffer[index]

    signBit = (b0 And 1 << 7) >> 7
    sign = (-1) ^ signBit

    exponent = (((b0 And 127) << 1) Or (b1 And (1 << 7)) >> 7)

    If exponent = 0 Then Return 0

    mul = 2 ^ (exponent - 127 - 23)
    mantissa = b3 + b2 * (2 ^ (8 * 1)) + (b1 And 127) * (2 ^ (8 * 2)) + (2 ^ 23)

    If exponent = &HFF Then
        If mantissa = 0 Then
            Return sign * FloatInf()
        Else
            Return FloatNan()
        End If
    End If

    Return sign * mantissa * mul
End Function
Function F64Load(buffer as Object, index as Integer) as Double
    b0 = buffer[index + 7]
    b1 = buffer[index + 6]
    b2 = buffer[index + 5]
    b3 = buffer[index + 4]
    b4 = buffer[index + 3]
    b5 = buffer[index + 2]
    b6 = buffer[index + 1]
    b7 = buffer[index]

    signBit = (b0 And 1 << 7) >> 7
    sign = (-1) ^ signBit

    exponent = (((b0 And 127) << 4) Or (b1 And (15 << 4)) >> 4)

    If exponent = 0 Then Return 0
    If exponent = &H7FF Then Return sign * FloatInf()

    mul = 2 ^ (exponent - 1023 - 52)
    mantissa = b3 + b2 * (2 ^ (8 * 1)) + (b1 And 127) * (2 ^ (8 * 2)) + (2 ^ 23)
    Return sign * mantissa * mul
End Function
Function I32Load8S(buffer as Object, index as Integer) as Integer
    Return buffer.GetSignedByte(index)
End Function
Function I64Load8S(buffer as Object, index as Integer) as LongInteger
    Return 0& + buffer.GetSignedByte(index)
End Function
Function I32Load8U(buffer As Object, index As Integer) as Integer
    Return buffer[index]
End Function
Function I64Load8U(buffer as Object, index as Integer) as LongInteger
    Return 0& + buffer[index]
End Function
Function I32Load16S(buffer as Object, index as Integer) as Integer
    x = buffer[index] + (buffer[index + 1] << 8)
    If x > &H7FFF Then x = x + &HFFFF0000
    Return x
End Function
Function I64Load16S(buffer as Object, index as Integer) as LongInteger
    x = 0& + buffer[index] + (buffer[index + 1] << 8)
    If x > &H7FFF Then x = x + &HFFFFFFFF00000000&
    Return x
End Function
Function I32Load16U(buffer as Object, index as Integer) as Integer
    Return buffer[index] + (buffer[index + 1] << 8)
End Function
Function I64Load16U(buffer as Object, index as Integer) as LongInteger
    Return 0& + buffer[index] + (buffer[index + 1] << 8)
End Function
Function I64Load32S(buffer as Object, index as Integer) as LongInteger
    x = 0& + buffer[index] + (buffer[index + 1] << 8) + (buffer[index + 2] << 16) + (buffer[index + 3] << 24)
    If x > &H7FFFFFFF Then x = x + &HFFFFFFFF00000000&
    Return x
End Function
Function I64Load32U(buffer as Object, index as Integer) as LongInteger
    Return 0& + buffer[index] + (buffer[index + 1] << 8) + (buffer[index + 2] << 16) + (buffer[index + 3] << 24)
End Function

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
