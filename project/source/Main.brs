Function custom_print_line(fd as Integer, str as String) as Void
    m.outputLines.Push(str)
    If m.outputLines.Count() > m.output.maxLines Then
        m.outputLines.Shift()
    End If
    m.output.text = m.outputLines.Join(Chr(10))
End Function

Function WaitForEvent() as Boolean
    msg = wait(0, m.port)
    If msg <> Invalid Then
        msgType = type(msg)

        If msgType = "roSGScreenEvent" Then
            If msg.isScreenClosed() Return False
        Else If msgType = "roSGNodeEvent" Then
            If msg.getNode() = "enter" Then
                external_append_stdin(m.keyboard.text + Chr(10))
                m.keyboard.text = ""
            Else
            End If
        End If
    End If
    Return True
End Function

Function custom_wait_for_stdin() as Void
    ' Not correct but it works for right now
    WaitForEvent()
End Function

sub Main()
    settings = {}
    Try
        settings = GetSettings()
    Catch e
    End Try

    m.port = CreateObject("roMessagePort")

    If settings.Graphical Then
        screen = CreateObject("roScreen", true, 320, 200)
        screen.SetMessagePort(m.port)
        screen.SetAlphaEnable(true)
        m.screen = screen
    Else
        sgScreen = CreateObject("roSGScreen")
        sgScreen.SetMessagePort(m.port)
        scene = sgScreen.CreateScene("main")
        sgScreen.show()

        m.keyboard = scene.findNode("keyboard")
        m.keyboard.setFocus(True)

        scene.findNode("enter").observeField("buttonSelected", m.port)

        m.output = scene.findNode("output")
        m.outputMaxLines = m.output.maxLines
        m.outputLines = []

        m.external_print_line = custom_print_line
        m.external_wait_for_stdin = custom_wait_for_stdin
    End If

    If settings.CustomInit <> Invalid Then
        settings.CustomInit()
    End if

    If settings.RestartOnFailure = True Then
        While True
            Try
                Start()
            Catch e
                Print e
            End Try
        End While
    Else
        Start()
    End If

    Print "------ Completed ------"

    While True
        If WaitForEvent() = False Return
    End While
end sub

Function DrawScreen(memory as Object, pointer as Integer)
    If pointer Mod 4 <> 0 Then Throw "Pixel pointer must be 4 byte aligned"
    w = m.screen.GetWidth()
    h = m.screen.GetHeight()
    For y = 0 To h - 1
        For x = 0 To w - 1
            m.screen.DrawRect(x, y, 1, 1, memory.GetSignedLong(pointer / 4 + (x + y * w)))
        End For
    End For
    m.screen.SwapBuffers()
End Function
