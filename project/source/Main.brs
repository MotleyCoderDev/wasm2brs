' Copyright 2020, Trevor Sundberg. See LICENSE.md
Function custom_print_line(fd as Integer, str as String) as Void
    If m.screen <> Invalid Then
        Return
    End If
    m.outputLines.Push(str)
    If m.outputLines.Count() > m.output.maxLines Then
        m.outputLines.Shift()
    End If
    m.output.text = m.outputLines.Join(Chr(10))
End Function

Function WaitForEvent()
    msg = wait(0, m.port)
    If msg <> Invalid Then
        msgType = type(msg)

        If msgType = "roSGNodeEvent" Then
            If msg.getNode() = "enter" Then
                external_append_stdin(m.keyboard.text + Chr(10))
                m.keyboard.text = ""
            Else
            End If
        End If
    End If
End Function

Function custom_wait_for_stdin() as Void
    If m.screen <> Invalid Then
        Return
    End If
    ' This works because we only have the stdin keyboard event
    WaitForEvent()
End Function

Function CatchingStart()
    Try
        Start()
    Catch e
        Print e
    End Try
EndFunction

sub Main()
    settings = {}
    Try
        settings = GetSettings()
    Catch e
    End Try

    m.port = CreateObject("roMessagePort")

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

    If settings.CustomInit <> Invalid Then
        m.CustomInit = settings.CustomInit
        m.CustomInit()
    End if

    If settings.RestartOnFailure = True Then
        While True
            CatchingStart()
        End While
    Else If settings.Profiling = True Then
        CatchingStart()
    Else
        Start()
    End If

    Print "------ Completed ------"

    If settings.PauseOnExit = True Then
        While True
            WaitForEvent()
        End While
    End If
end sub
