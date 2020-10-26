
Function Run()
'w2b_rot13()
'screen.ShowMessage(MemoryGet().ToAsciiString())
End Function

Function fill_buf(p0 As Integer, p1 As Integer) As Integer
MemoryGet().FromAsciiString("uryyb guvf vf n grfg")
Return MemoryGet().Count()
End Function

Function buf_done(p0 As Integer, p1 As Integer) As Void
End Function
