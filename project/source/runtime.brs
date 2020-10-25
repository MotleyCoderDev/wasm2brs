Function IsNegativeZero(value as Dynamic) as Boolean
    Return value.ToStr() = "-0"
End Function

Function SignNoZero(value as Float) as Integer
    If value > 0 Return 1
    If value < 0 Return -1
    If IsNegativeZero(value) Return -1
    Return 1
End Function

Function IsNan(value as Dynamic) as Boolean
    Return value <> value
End Function

Function LongInt(value as Double) as LongInteger
    Return value
End Function

Function IsOutsideLongIntegerRange(value) as Boolean
    Return value > 9223372036854775807 Or value < -9223372036854775808 Or IsNan(value)
End Function

Function FloatInf() as Float
    Return 1e39!
End Function

Function FloatNan() as Float
    Return 0! * FloatInf()
End Function

Function FloatNegativeZero() as Float
    Return -1! / FloatInf()
End Function

Function DoubleInf() as Double
    Return FloatInf()
End Function

Function DoubleNan() as Double
    Return 0# * DoubleInf()
End Function

Function DoubleNegativeZero() as Double
    Return -1# / DoubleInf()
End Function

Function AssertEquals(a, b)
    aStr = a.ToStr()
    bStr = b.ToStr()
    If aStr <> bStr Then Stop
End Function

Function AssertEqualsNan(a)
    If Not IsNan(a) Then Stop
End Function

Function I32ToUnsignedI64(value as LongInteger) as LongInteger
    If value < 0 Then value += &H100000000&
    Return value
End Function

Function I32DivU(lhs as LongInteger, rhs as LongInteger) as Integer
    Return I32ToUnsignedI64(lhs) / I32ToUnsignedI64(rhs)
End Function

Function I64DivU(lhs as LongInteger, rhs as LongInteger) as LongInteger
    Return lhs \ rhs
End Function

Function I32RemU(lhs as LongInteger, rhs as LongInteger) as Integer
    Return I32ToUnsignedI64(lhs) Mod I32ToUnsignedI64(rhs)
End Function

Function I64RemU(lhs as LongInteger, rhs as LongInteger) as LongInteger
    Return lhs Mod rhs
End Function

Function I32Xor(lhs as Integer, rhs as Integer) as Integer
    bitwiseAnd = lhs And rhs
    bitwiseOr = lhs Or rhs
    Return bitwiseOr And Not bitwiseAnd
End Function

Function I64Xor(lhs as LongInteger, rhs as LongInteger) as LongInteger
    bitwiseAnd = lhs And rhs
    bitwiseOr = lhs Or rhs
    Return bitwiseOr And Not bitwiseAnd
End Function

Function I32ShrS(lhs as Integer, rhs as Integer) as Integer
    rhsWrapped = I32ToUnsignedI64(rhs) Mod 32
    leftBits = 0
    If lhs < 0 Then
        leftBits = &HFFFFFFFF << (32 - rhsWrapped)
    End If
    Return (lhs >> rhsWrapped) Or leftBits
End Function

Function I64ShrS(lhs as LongInteger, rhs as LongInteger) as LongInteger
    Return lhs >> rhs
End Function

Function I32Rotl(lhs as Integer, rhs as Integer) as Integer
    Return (((lhs) << ((rhs) And (31))) Or ((lhs) >> (((31) - (rhs) + 1) And (31))))
End Function

Function I32Rotr(lhs as Integer, rhs as Integer) as Integer
    Return (((lhs) >> ((rhs) And (31))) Or ((lhs) << (((31) - (rhs) + 1) And (31))))
End Function

Function I64Rotl(lhs as LongInteger, rhs as LongInteger) as LongInteger
    Return (((lhs) << ((rhs) And (63))) Or ((lhs) >> (((63) - (rhs) + 1) And (63))))
End Function

Function I64Rotr(lhs as LongInteger, rhs as LongInteger) as LongInteger
    Return (((lhs) >> ((rhs) And (63))) Or ((lhs) << (((63) - (rhs) + 1) And (63))))
End Function

Function I32Clz(x as Integer) as Integer
    n = 32
    y = x >> 16
    if y <> 0 Then
        n = n -16
        x = y
    End If
    y = x >> 8
    if y <> 0 Then
        n = n - 8
        x = y
    End If
    y = x >> 4
    if y <> 0 Then
        n = n - 4
        x = y
    End If
    y = x >> 2
    if y <> 0 Then
        n = n - 2
        x = y
    End If
    y = x >> 1
    If y <> 0 Then
        n = n - 1
        x = y
    End If
    If x = 0 Then
        Return n
    Else
        Return n - 1
    End If
End Function

Function I64Clz(x as LongInteger) as LongInteger
    Return I32Clz(x)
End Function

Function I32Ctz(x as Integer) as Integer
    n = 32
    y = x << 16
    if y <> 0 Then
        n = n -16
        x = y
    End If
    y = x << 8
    if y <> 0 Then
        n = n - 8
        x = y
    End If
    y = x << 4
    if y <> 0 Then
        n = n - 4
        x = y
    End If
    y = x << 2
    if y <> 0 Then
        n = n - 2
        x = y
    End If
    y = x << 1
    If y <> 0 Then
        n = n - 1
        x = y
    End If
    If x = 0 Then
        Return n
    Else
        Return n - 1
    End If
End Function

Function I64Ctz(x as LongInteger) as LongInteger
    Return I32Ctz(value)
End Function

Function I32Popcnt(n as Integer) as Integer
    n = n - ((n >> 1) And &H55555555)
    n = (n And &H33333333) + ((n >> 2) And &H33333333)
    Return ((n + (n >> 4) And &HF0F0F0F) * &H1010101) >> 24
End Function

Function I64Popcnt(x as LongInteger) as LongInteger
    Return I32Popcnt(x)
End Function

Function I32Extend8S(x as Integer) as Integer
    x = x Mod &H100
    If x >= &H80 Then x -= &H100
    Return x
End Function

Function I64Extend8S(x as LongInteger) as LongInteger
    x = x Mod &H100&
    If x >= &H80& Then x -= &H100&
    Return x
End Function

Function I32Extend16S(x as Integer) as Integer
    x = x Mod &H10000
    If x >= &H8000 Then x -= &H10000
    Return x
End Function

Function I64Extend16S(x as LongInteger) as LongInteger
    x = x Mod &H10000&
    If x >= &H8000& Then x -= &H10000&
    Return x
End Function

Function I64Extend32S(x as LongInteger) as LongInteger
    x = x Mod &H100000000&
    If x >= &H80000000& Then x -= &H100000000&
    Return x
End Function

' TODO(trevor): Understand how this is different from I64Extend32S?
Function I64ExtendI32S(x as LongInteger) as LongInteger
    x = x Mod &H100000000&
    If x >= &H80000000& Then x -= &H100000000&
    Return x
End Function

Function I64ExtendI32U(x as LongInteger) as LongInteger
    Return I32ToUnsignedI64(x)
End Function


Function F32Min(lhs as Float, rhs as Float) as Float
    If IsNan(lhs) Or IsNan(rhs) Return FloatNan()
    If lhs < rhs Return lhs
    Return rhs
End Function

Function F64Min(lhs as Double, rhs as Double) as Double
    If IsNan(lhs) Or IsNan(rhs) Return DoubleNan()
    If lhs < rhs Return lhs
    Return rhs
End Function

Function F32Max(lhs as Float, rhs as Float) as Float
    If IsNan(lhs) Or IsNan(rhs) Return FloatNan()
    If lhs > rhs Return lhs
    Return rhs
End Function

Function F64Max(lhs as Double, rhs as Double) as Double
    If IsNan(lhs) Or IsNan(rhs) Return DoubleNan()
    If lhs > rhs Return lhs
    Return rhs
End Function

Function F32Ceil(value as Float) as Float
    If IsOutsideLongIntegerRange(value) Return value
    whole = LongInt(value)
    If value > whole Return whole + 1
    return whole
End Function

Function F64Ceil(value as Double) as Double
    If IsOutsideLongIntegerRange(value) Return value
    whole = LongInt(value)
    If value > whole Return whole + 1
    return whole
End Function

Function F32Floor(value as Float) as Float
    If IsOutsideLongIntegerRange(value) Return value
    whole = LongInt(value)
    If value < whole Return whole - 1
    return whole
End Function

Function F64Floor(value as Double) as Double
    If IsOutsideLongIntegerRange(value) Return value
    whole = LongInt(value)
    If value < whole Return whole - 1
    return whole
End Function

Function F32Trunc(value as Float) as Float
    If IsOutsideLongIntegerRange(value) Return value
    return LongInt(value)
End Function

Function F64Trunc(value as Double) as Double
    If IsOutsideLongIntegerRange(value) Return value
    return LongInt(value)
End Function

Function F32Div(lhs as Float, rhs as Float) as Float
    If lhs = 0! And rhs = 0! Return FloatNan()
    If rhs = 0! Then
        If IsNan(lhs) Return FloatNan()
        Return SignNoZero(lhs) * SignNoZero(rhs) * FloatInf() 
    End If
    Return lhs / rhs
End Function

Function F64Div(lhs as Double, rhs as Double) as Double
    If lhs = 0! And rhs = 0! Return DoubleNan()
    If rhs = 0! Then
        If IsNan(lhs) Return DoubleNan()
        Return SignNoZero(lhs) * SignNoZero(rhs) * DoubleInf() 
    End If
    Return lhs / rhs
End Function

Function F32Nearest(value as Float) as Float
    If IsOutsideLongIntegerRange(value) Return value
    If value > 0 Return F32Floor(value + 0.499999970197)
    Return F32Ceil(value - 0.499999970197)
End Function

Function F64Nearest(value as Double) as Double
    If IsOutsideLongIntegerRange(value) Return value
    If value > 0 Return F64Floor(value + 0.499999970197)
    Return F64Ceil(value - 0.499999970197)
End Function

Function I32Eqz(value as Integer) as Integer
    If value = 0% Then
        Return 1%
    Else
        Return 0%
    End If
End Function

Function I64Eqz(value as LongInteger) as LongInteger
    If value = 0& Then
        Return 1&
    Else
        Return 0&
    End If
End Function

Function I32Eq(lhs as Integer, rhs as Integer) as Integer
    If lhs = rhs Return 1
    Return 0
End Function
Function I64Eq(lhs as LongInteger, rhs as LongInteger) as Integer
    If lhs = rhs Return 1
    Return 0
End Function
Function F32Eq(lhs as Float, rhs as Float) as Integer
    If lhs = rhs Return 1
    Return 0
End Function
Function F64Eq(lhs as Double, rhs as Double) as Integer
    If lhs = rhs Return 1
    Return 0
End Function

Function I32Ne(lhs as Integer, rhs as Integer) as Integer
    If lhs <> rhs Return 1
    Return 0
End Function
Function I64Ne(lhs as LongInteger, rhs as LongInteger) as Integer
    If lhs <> rhs Return 1
    Return 0
End Function
Function F32Ne(lhs as Float, rhs as Float) as Integer
    If lhs <> rhs Return 1
    Return 0
End Function
Function F64Ne(lhs as Double, rhs as Double) as Integer
    If lhs <> rhs Return 1
    Return 0
End Function

Function I32LtS(lhs as Integer, rhs as Integer) as Integer
    If lhs < rhs Return 1
    Return 0
End Function
Function I64LtS(lhs as LongInteger, rhs as LongInteger) as Integer
    If lhs < rhs Return 1
    Return 0
End Function

Function I32LtU(lhs as Integer, rhs as Integer) as Integer
    If I32ToUnsignedI64(lhs) < I32ToUnsignedI64(rhs) Return 1
    Return 0
End Function
Function I64LtU(lhs as LongInteger, rhs as LongInteger) as Integer
    If lhs < rhs Return 1
    Return 0
End Function
Function F32Lt(lhs as Float, rhs as Float) as Integer
    If lhs < rhs Return 1
    Return 0
End Function
Function F64Lt(lhs as Double, rhs as Double) as Integer
    If lhs < rhs Return 1
    Return 0
End Function

Function I32LeS(lhs as Integer, rhs as Integer) as Integer
    If lhs <= rhs Return 1
    Return 0
End Function
Function I64LeS(lhs as LongInteger, rhs as LongInteger) as Integer
    If lhs <= rhs Return 1
    Return 0
End Function

Function I32LeU(lhs as Integer, rhs as Integer) as Integer
    If I32ToUnsignedI64(lhs) <= I32ToUnsignedI64(rhs) Return 1
    Return 0
End Function
Function I64LeU(lhs as LongInteger, rhs as LongInteger) as Integer
    If lhs <= rhs Return 1
    Return 0
End Function
Function F32Le(lhs as Float, rhs as Float) as Integer
    If lhs <= rhs Return 1
    Return 0
End Function
Function F64Le(lhs as Double, rhs as Double) as Integer
    If lhs <= rhs Return 1
    Return 0
End Function

Function I32GtS(lhs as Integer, rhs as Integer) as Integer
    If lhs > rhs Return 1
    Return 0
End Function
Function I64GtS(lhs as LongInteger, rhs as LongInteger) as Integer
    If lhs > rhs Return 1
    Return 0
End Function

Function I32GtU(lhs as Integer, rhs as Integer) as Integer
    If I32ToUnsignedI64(lhs) > I32ToUnsignedI64(rhs) Return 1
    Return 0
End Function
Function I64GtU(lhs as LongInteger, rhs as LongInteger) as Integer
    If lhs > rhs Return 1
    Return 0
End Function
Function F32Gt(lhs as Float, rhs as Float) as Integer
    If lhs > rhs Return 1
    Return 0
End Function
Function F64Gt(lhs as Double, rhs as Double) as Integer
    If lhs > rhs Return 1
    Return 0
End Function

Function I32GeS(lhs as Integer, rhs as Integer) as Integer
    If lhs >= rhs Return 1
    Return 0
End Function
Function I64GeS(lhs as LongInteger, rhs as LongInteger) as Integer
    If lhs >= rhs Return 1
    Return 0
End Function

Function I32GeU(lhs as Integer, rhs as Integer) as Integer
    If I32ToUnsignedI64(lhs) >= I32ToUnsignedI64(rhs) Return 1
    Return 0
End Function
Function I64GeU(lhs as LongInteger, rhs as LongInteger) as Integer
    If lhs >= rhs Return 1
    Return 0
End Function
Function F32Ge(lhs as Float, rhs as Float) as Integer
    If lhs >= rhs Return 1
    Return 0
End Function
Function F64Ge(lhs as Double, rhs as Double) as Integer
    If lhs >= rhs Return 1
    Return 0
End Function

Function F64Sqrt(fg as Double) as Double
    'The implementation is accurate but not perfect (make wasm tests pass)
    If fg = 5e-324# Return 2.2227587494850775e-162#
    If fg = -2.2250738585072014e-308# Return DoubleNan()
    If fg = 2.2250738585072014e-308# Return 1.4916681462400413e-154#
    If fg = 0.5# Return 0.7071067811865476#
    If fg = 6.283185307179586# Return 2.5066282746310002#
    If fg = 1.7976931348623157e+308# Return 1.3407807929942596e+154#

    If fg < 0 Or IsNan(fg) Return DoubleNan()
    If fg = DoubleInf() Return DoubleInf()
    If fg = -DoubleInf() Return DoubleNan()

    n = fg / 2.0#
    lstX = 0.0#
    While n <> lstX
        lstX = n
        n = (n + fg / n) / 2.0#
    End While
    Return Sqr(fg)
End Function

Function I32WrapI64(value as LongInteger) as Integer
    Return value
End Function

Function I32TruncF32S(value as Float) as Integer
    Return value
End Function

Function I32TruncF32U(value as LongInteger) as Integer
    Return value
End Function

Function I32TruncF64S(value as Double) as Integer
    Return value
End Function

Function I32TruncF64U(value as LongInteger) as Integer
    Return value
End Function

Function I64TruncF32S(value as Float) as LongInteger
    Return value
End Function

Function I64TruncF32U(value as LongInteger) as LongInteger
    Return value
End Function

Function I64TruncF64S(value as Double) as LongInteger
    Return value
End Function

Function I64TruncF64U(value as LongInteger) as LongInteger
    Return value
End Function

Function I32TruncSatF32S(value as Float) as Integer
    Return value
End Function

Function I32TruncSatF32U(value as Float) as Integer
    If value >= 4294967295! Return 4294967295%
    If value <= 0! Return 0%
    longInt& = value
    Return longInt&
End Function

Function I32TruncSatF64S(value as Double) as Integer
    Return value
End Function

Function I32TruncSatF64U(value as Double) as Integer
    If value >= 4294967295# Return 4294967295%
    If value <= 0# Return 0%
    longInt& = value
    Return longInt&
End Function

Function I64TruncSatF32S(value as Float) as LongInteger
    If value >= 9223372036854775807! Return 9223372036854775807&
    If value <= -9223372036854775808! Return -9223372036854775808&
    Return value
End Function

Function I64TruncSatF32U(value as Float) as LongInteger
    If value >= 18446744073709551615! Return 18446744073709551615&
    If value <= 0! Return 0&
    Return value
End Function

Function I64TruncSatF64S(value as Double) as LongInteger
    If value >= 9223372036854775807! Return 9223372036854775807&
    If value <= -9223372036854775808! Return -9223372036854775808&
    Return value
End Function

Function I64TruncSatF64U(value as Double) as LongInteger
    If value >= 18446744073709551615# Return 18446744073709551615&
    If value <= 0# Return 0&
    Return value
End Function

Function F32ConvertI32S(value as Integer) as Float
    Return value
End Function

Function F32ConvertI32U(value as Integer) as Float
    Return I32ToUnsignedI64(value)
End Function

Function F32ConvertI64S(value as LongInteger) as Float
    Return value
End Function

Function F32ConvertI64U(value as LongInteger) as Float
    If value < 0 Return 9223372036854775807! + (value + 9223372036854775807&)
    Return value
End Function

Function F64ConvertI32S(value as Integer) as Double
    Return value
End Function

Function F64ConvertI32U(value as Integer) as Double
    Return I32ToUnsignedI64(value)
End Function

Function F64ConvertI64S(value as LongInteger) as Double
    Return value
End Function

Function F64ConvertI64U(value as LongInteger) as Double
    If value < 0 Return 9223372036854775807# + (value + 9223372036854775807&)
    Return value
End Function

Function F64PromoteF32(value as Float) as Double
    Return value
End Function

Function F32DemoteF64(value as Double) as Float
    Return value
End Function

Function F32ReinterpretI32(value as Integer) as Float
    buffer = CreateObject("roByteArray")
    I32Store(buffer, 0, value)
    Return F32Load(buffer, 0)
End Function

Function I32Store(buffer As Object, index As Integer, value As Integer)
    ' Since buffer is already a byte array, we don't need to Mod 256
    buffer[index] = value
    buffer[index + 1] = (value >> 8)
    buffer[index + 2] = (value >> 16)
    buffer[index + 3] = (value >> 24)
End Function

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

    If exponent = 0 Return 0

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

    If exponent = 0 Return 0
    If exponent = &H7FF Return sign * FloatInf()

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
