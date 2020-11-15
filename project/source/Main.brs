Function print_line(fd as Integer, str as String)
    m.output.text += str + Chr(10)
End Function

sub Main()
    m.port = CreateObject("roMessagePort")

    sgScreen = CreateObject("roSGScreen")
    sgScreen.SetMessagePort(m.port)
    scene = sgScreen.CreateScene("main")
    sgScreen.show()
    keyboard = scene.findNode("keyboard")
    keyboard.setFocus(True)
    keyboard.observeField("text", m.port)
    m.output = scene.findNode("output")

    m.external_print_line = print_line

    Try
        InitSpectestMinified()
    Catch e
    End Try
    RunTests()

    print "------ Completed ------"

    While True
        msg = wait(0, m.port)
        If msg <> Invalid Then
            msgType = type(msg)

            If msgType = "roSGScreenEvent" Then
                If msg.isScreenClosed() Return
            Else If msgType = "roSGNodeEvent" Then
                Print msg.getData()
            End If
        End If
    End While
end sub
