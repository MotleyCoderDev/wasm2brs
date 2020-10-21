
Function Run()
'w2b_rot13()
'screen.ShowMessage(GetMem().ToAsciiString())
End Function

Function fill_buf(p0 As Integer, p1 As Integer) As Integer
GetMem().FromAsciiString("uryyb guvf vf n grfg")
Return GetMem().Count()
End Function

Function buf_done(p0 As Integer, p1 As Integer) As Void
End Function
