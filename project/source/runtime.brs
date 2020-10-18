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

'Function I32Load(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
'Function I64Load(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
'Function F32Load(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
'Function F64Load(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
'Function I32Load8S(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
'Function I64Load8S(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
Function I32Load8U(buffer As Object, index As Integer) as Integer
    Return buffer[index]
End Function
'Function I64Load8U(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
'Function I32Load16S(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
'Function I64Load16S(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
'Function I32Load16U(buffer as Object, index as Integer) as Integer
'    Return 0
'End Function
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
