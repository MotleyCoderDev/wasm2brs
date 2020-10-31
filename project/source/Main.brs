'*************************************************************
'** Hello World example 
'** Copyright (c) 2015 Roku, Inc.  All rights reserved.
'** Use of the Roku Platform is subject to the Roku SDK Licence Agreement:
'** https://docs.roku.com/doc/developersdk/en-us
'*************************************************************

sub Main()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    screen.ShowMessage("Initializing")
    screen.Show()

    RunTests()

    print "------ Completed ------"
    screen.ShowMessage("Completed")

    While True
        msg = wait(0, m.port)
        msgType = type(msg)
        If msgType = "roSGScreenEvent"
            If msg.isScreenClosed() Then Return
        End If
    End While
end sub
