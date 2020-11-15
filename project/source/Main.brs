Function custom_print_line(fd as Integer, str as String) as Void
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

    enter = scene.findNode("enter")
    enter.observeField("buttonSelected", m.port)

    m.output = scene.findNode("output")

    m.external_print_line = custom_print_line

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
                If msg.getNode() = "enter" Then
                    external_append_stdin(keyboard.text)
                    keyboard.text = ""
                Else
                End If
            End If
        End If
    End While
end sub
