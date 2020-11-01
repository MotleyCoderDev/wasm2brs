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
    If a <> b Then
        aStr = a.ToStr()
        bStr = b.ToStr()
        If aStr <> bStr Then
            If type(a) = "Float" Or type(a) = "Double" Then
                If F64Abs(a - b) > 1e-45 Stop
            Else
                Stop
            End If
        End If
    End If
End Function

Function I32ToUnsignedI64(value as LongInteger) as LongInteger
    Return value And &HFFFFFFFF&
End Function

Function I32DivU(lhs as LongInteger, rhs as LongInteger) as Integer
    Return I32ToUnsignedI64(lhs) / I32ToUnsignedI64(rhs)
End Function

Function I64DivideUnsigned(dividend as LongInteger, divisor as LongInteger) as Object
    result = {remainder: 0&, quotient: 0&}
  
    If divisor = 0& Then
        ' Trap here
        Return result
    End If
  
    If I64GtU(divisor, dividend) Then
        result.remainder = dividend
        Return result
    End If
  
    If divisor = dividend Then
        result.quotient = 1&
        Return result
    End If
  
    num_bits = 64&
    d = 0&
    remainder = 0&
    quotient = 0&

    While I64GtU(divisor, remainder)
        bit = (dividend And &H8000000000000000&) >> 63&
        remainder = (remainder << 1&) Or bit
        d = dividend
        dividend = dividend << 1&
        num_bits--
    End While
  
    dividend = d
    remainder = remainder >> 1&
    num_bits++
  
    While num_bits > 0
        bit = (dividend And &H8000000000000000&) >> 63&
        remainder = (remainder << 1&) Or bit
        t = remainder - divisor
        q = (Not ((t And &H8000000000000000&) >> 63&)) And 1
        dividend = dividend << 1&
        quotient = (quotient << 1&) Or q
        If q Then remainder = t
        num_bits = num_bits - 1
    End While

    result.remainder = remainder
    result.quotient = quotient
    Return result
End Function

Function I64DivU(lhs as LongInteger, rhs as LongInteger) as LongInteger
    If lhs >= 0& And rhs >= 0& Return lhs / rhs
    Return I64DivideUnsigned(lhs, rhs).quotient
End Function

Function I32RemU(lhs as LongInteger, rhs as LongInteger) as Integer
    Return I32ToUnsignedI64(lhs) Mod I32ToUnsignedI64(rhs)
End Function

Function I64RemU(lhs as LongInteger, rhs as LongInteger) as LongInteger
    If lhs >= 0& And rhs >= 0& Return lhs Mod rhs
    Return I64DivideUnsigned(lhs, rhs).remainder
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
    rhsWrapped = rhs And &H1F
    leftBits = 0
    If lhs < 0 And rhsWrapped <> 0 Then
        leftBits = &HFFFFFFFF << (32& - rhsWrapped)
    End If
    Return (lhs >> rhsWrapped) Or leftBits
End Function

Function I64ShrS(lhs as LongInteger, rhs as LongInteger) as LongInteger
    rhsWrapped = rhs And &H3F
    leftBits = 0
    If lhs < 0 And rhsWrapped <> 0 Then
        leftBits = &HFFFFFFFFFFFFFFFF << (64& - rhsWrapped)
    End If
    Return (lhs >> rhsWrapped) Or leftBits
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
    hi = (x >> 32&) And &HFFFFFFFF
    lo =  x         And &HFFFFFFFF
    clzHi = I32Clz(hi)
    If clzHi <> 32 Return clzHi
    Return 32 + I32Clz(lo)
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
    hi = (x >> 32&) And &HFFFFFFFF
    lo =  x         And &HFFFFFFFF
    ctzLo = I32Ctz(lo)
    If ctzLo <> 32 Return ctzLo
    Return 32 + I32Ctz(hi)
End Function

Function I32Popcnt(n as Integer) as Integer
    n = n - ((n >> 1) And &H55555555)
    n = (n And &H33333333) + ((n >> 2) And &H33333333)
    Return ((n + (n >> 4) And &HF0F0F0F) * &H1010101) >> 24
End Function

Function I64Popcnt(x as LongInteger) as LongInteger
    hi = (x >> 32&) And &HFFFFFFFF
    lo =  x         And &HFFFFFFFF
    Return I32Popcnt(hi) + I32Popcnt(lo)
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

Function GetSignBit(value) as Integer
    If Asc(value.ToStr()) = 45 Return -1
    Return 1
End Function

Function F32Copysign(lhs as Float, rhs as Float) as Float
    lhsSign = GetSignBit(lhs)
    rhsSign = GetSignBit(rhs)
    If lhsSign = rhsSign Return lhs
    Return -lhs
End Function

Function F64Copysign(lhs as Double, rhs as Double) as Double
    lhsSign = GetSignBit(lhs)
    rhsSign = GetSignBit(rhs)
    If lhsSign = rhsSign Return lhs
    Return -lhs
End Function

Function F64Abs(value as Double) as Double
    If value < 0 Return -value
    Return value
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
    whole = LongInt(value)
    fraction = value - whole
    If fraction >  0.5! Return whole + 1
    If fraction < -0.5! Return whole - 1
    If fraction =  0.5! Or fraction = -0.5! Return whole + whole Mod 2
    Return whole
End Function

Function F64Nearest(value as Double) as Double
    If IsOutsideLongIntegerRange(value) Return value
    whole = LongInt(value)
    fraction = value - whole
    If fraction >  0.5# Return whole + 1
    If fraction < -0.5# Return whole - 1
    If fraction =  0.5# Or fraction = -0.5# Return whole + whole Mod 2
    Return whole
End Function

Function I32Eqz(value as Integer) as Integer
    If value = 0% Return 1%
    Return 0%
End Function

Function I64Eqz(value as LongInteger) as LongInteger
    If value = 0& Return 1&
    Return 0&
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
    lhsPositive = lhs >= 0
    rhsPositive = rhs >= 0
    If lhsPositive = rhsPositive Then
        If lhs < rhs Return 1
        Return 0
    Else If lhsPositive
        Return 1
    End If
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
    If lhs = rhs Return 1
    Return I64LtU(lhs, rhs)
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
    lhsPositive = lhs >= 0
    rhsPositive = rhs >= 0
    If lhsPositive = rhsPositive Then
        If lhs > rhs Return 1
        Return 0
    Else If rhsPositive
        Return 1
    End If
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
    If lhs = rhs Return 1
    Return I64GtU(lhs, rhs)
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
    Return n
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
    b3 =  value        And &HFF
    b2 = (value >> 8)  And &HFF
    b1 = (value >> 16) And &HFF
    b0 = (value >> 24) And &HFF

    signBit = (b0 And 1 << 7) >> 7
    sign = (-1) ^ signBit

    exponent = (((b0 And 127) << 1) Or (b1 And (1 << 7)) >> 7)

    If exponent = 0 Return 0!

    mul = 2# ^ (exponent - 127 - 23)
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

Function F64ReinterpretI64(value as LongInteger) as Double
    b7 =  value        And &HFF
    b6 = (value >> 8)  And &HFF
    b5 = (value >> 16) And &HFF
    b4 = (value >> 24) And &HFF
    b3 = (value >> 32) And &HFF
    b2 = (value >> 40) And &HFF
    b1 = (value >> 48) And &HFF
    b0 = (value >> 56) And &HFF

    signBit = (b0 And 1 << 7) >> 7
    sign = (-1) ^ signBit

    exponent = (((b0 And 127) << 4) Or (b1 And (15 << 4)) >> 4)

    If exponent = 0 Return 0#

    mul = 2# ^ (exponent - 1023 - 52)
    mantissa = b7 + b6 * (2& ^ (8& * 1&)) + b5 * (2& ^ (8& * 2&)) + b4 * (2& ^ (8& * 3&)) + b3 * (2& ^ (8& * 4&)) + b2 * (2& ^ (8& * 5&)) + (b1 And 15) * (2& ^ (8& * 6&)) + (2& ^ 52&)

    If exponent = &H7FF Then
        If mantissa = 0 Then
            Return sign * DoubleInf()
        Else
            Return DoubleNan()
        End If
    End If

    Return sign * mantissa * mul
End Function

Function I32ReinterpretF32(value as Float) as Integer
    If value =  FloatInf() Return &H7F800000
    If value = -FloatInf() Return &HFF800000
    If value =  3.4028234663852886e+38! Return &H7F7FFFFF
    If value = -3.4028234663852886e+38! Return &HFF7FFFFF
    If value =  1.401298464324817e-45! Return 1%
    If value = -1.401298464324817e-45! Return 2147483649%

    If value = 0 Then
        If IsNegativeZero(value) Return &H80000000
        Return &H00000000
    End If

    If IsNan(value) Return &HFFFFFFFF

    bytes = 0%
    If value <= -0.0! Then
        bytes = &H80000000
        value = -value
    End If

    exponent = F32Floor(Log(value) / Log(2))
    significand = ((value / (2 ^ exponent)) * (2 ^ 23))

    exponent += 127
    If exponent >= &HFF Then
        exponent = &HFF
        significand = 0
    Else If exponent < 0
        exponent = 0
    End If

    exponentWhole% = exponent
    significandWhole% = significand
    bytes = bytes Or (exponentWhole% << 23)
    Return bytes Or (significandWhole% And Not (-1 << 23))
End Function

Function I64ReinterpretF64(value as Double) as LongInteger
    If value =  DoubleInf() Return &H7FF0000000000000&
    If value = -DoubleInf() Return &HFFF0000000000000&
    If value =  5e-324# Return &H0000000000000001&
    If value = -5e-324# Return &H8000000000000001&
    If value =  1.7976931348623157e+308# Return 9218868437227405311&
    If value = -1.7976931348623157e+308# Return 18442240474082181119&

    If value = 0 Then
        If IsNegativeZero(value) Return &H8000000000000000&
        Return &H0000000000000000&
    End If

    If IsNan(value) Return &HFFFFFFFFFFFFFFFF&

    bytes = 0&
    If value <= -0.0# Then
        bytes = &H8000000000000000&
        value = -value
    End If

    exponent = F64Floor(Log(value) / Log(2))
    If exponent = -DoubleInf() Then exponent = -1074
    significand = ((value / (2& ^ exponent)) * (2& ^ 52&))

    exponent += 1023
    If exponent >= &H7FF Then
        exponent = &H7FF
        significand = 0
    Else If exponent < 0
        exponent = 0
    End If

    exponentWhole& = exponent
    significandWhole& = significand
    bytes = bytes Or (exponentWhole& << 52&)
    Return bytes Or (significandWhole& And Not (-1& << 52&))
End Function

Function F32Store(buffer As Object, index As Integer, value As Float)
    I32Store(buffer, index, I32ReinterpretF32(value))
End Function
Function F64Store(buffer As Object, index As Integer, value As Double)
    I64Store(buffer, index, I64ReinterpretF64(value))
End Function


Function I32Store8(buffer As Object, index As Integer, value As Integer)
    buffer[index] = value
End Function
Function I32Store16(buffer As Object, index As Integer, value As Integer)
    buffer[index] = value
    buffer[index + 1] = (value >> 8)
End Function
Function I32Store(buffer As Object, index As Integer, value As Integer)
    ' Since buffer is already a byte array, we don't need to Mod 256
    buffer[index] = value
    buffer[index + 1] = (value >> 8)
    buffer[index + 2] = (value >> 16)
    buffer[index + 3] = (value >> 24)
End Function

Function I64Store8(buffer As Object, index As Integer, value As LongInteger)
    I32Store8(buffer, index, value)
End Function
Function I64Store16(buffer As Object, index As Integer, value As LongInteger)
    I32Store16(buffer, index, value)
End Function
Function I64Store32(buffer As Object, index As Integer, value As LongInteger)
    I32Store(buffer, index, value)
End Function
Function I64Store(buffer As Object, index As Integer, value As LongInteger)
    buffer[index] = value
    buffer[index + 1] = (value >> 8&)
    buffer[index + 2] = (value >> 16&)
    buffer[index + 3] = (value >> 24&)
    buffer[index + 4] = (value >> 32&)
    buffer[index + 5] = (value >> 40&)
    buffer[index + 6] = (value >> 48&)
    buffer[index + 7] = (value >> 56&)
End Function

Function I32Load(buffer as Object, index as Integer) as Integer
    Return buffer[index] + (buffer[index + 1] << 8) + (buffer[index + 2] << 16) + (buffer[index + 3] << 24)
End Function
Function I64Load(buffer as Object, index as Integer) as LongInteger
    Return (buffer[index]) + (buffer[index + 1] << 8&) + (buffer[index + 2] << 16&) + (buffer[index + 3] << 24&) + (buffer[index + 4] << 32&) + (buffer[index + 5] << 40&) + (buffer[index + 6] << 48&) + (buffer[index + 7] << 56&)
End Function
Function F32Load(buffer as Object, index as Integer) as Float
    Return F32ReinterpretI32(I32Load(buffer, index))
End Function
Function F64Load(buffer as Object, index as Integer) as Double
    Return F64ReinterpretI64(I64Load(buffer, index))
End Function
Function I32Load8S(buffer as Object, index as Integer) as Integer
    Return buffer.GetSignedByte(index)
End Function
Function I64Load8S(buffer as Object, index as Integer) as LongInteger
    Return buffer.GetSignedByte(index)
End Function
Function I32Load8U(buffer As Object, index As Integer) as Integer
    Return buffer[index]
End Function
Function I64Load8U(buffer as Object, index as Integer) as LongInteger
    Return buffer[index]
End Function
Function I32Load16S(buffer as Object, index as Integer) as Integer
    x = buffer[index] + (buffer[index + 1] << 8)
    If x > &H7FFF Then x = x + &HFFFF0000
    Return x
End Function
Function I64Load16S(buffer as Object, index as Integer) as LongInteger
    Return I32Load16S(buffer, index)
End Function
Function I32Load16U(buffer as Object, index as Integer) as Integer
    Return buffer[index] + (buffer[index + 1] << 8)
End Function
Function I64Load16U(buffer as Object, index as Integer) as LongInteger
    Return I32Load16U(buffer, index)
End Function
Function I64Load32S(buffer as Object, index as Integer) as LongInteger
    Return I32Load(buffer, index)
End Function
Function I64Load32U(buffer as Object, index as Integer) as LongInteger
    Return I32ToUnsignedI64(I32Load(buffer, index))
End Function

Function MemoryGet() As Object
    If Not m.DoesExist("Mem") Then
        m.Mem = CreateObject("roByteArray")
    End If
    Return m.Mem
End Function

Function MemorySize(memory as Object) As Integer
    Return memory.Count() \ 65536
End Function

Function MemoryGrow(memory as Object, deltaPages as Integer) As Integer
    previous = MemorySize(memory)
    memory[memory.Count() + deltaPages * 65536] = 0
    Return previous
End Function

Function MemCpy(toBytes as Object, toOffset as Integer, fromBytes as Object, fromOffset as Integer, size as Integer)
    For i = 0 To size - 1 Step 1
        toBytes[i + toOffset] = fromBytes[i + fromOffset]
    End For
End Function
