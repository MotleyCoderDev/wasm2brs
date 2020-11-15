Sub Init()
    m.keyboard = m.top.findNode("keyboard")
    m.enter = m.top.findNode("enter")
End Sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    If press Then
        If key = "down" And m.keyboard.isInFocusChain() Then
            m.enter.setFocus(True)
            Return True
        End If
        If key = "up" And m.enter.isInFocusChain() Then
            m.keyboard.setFocus(True)
            Return True
        End If
    End If
    Return False
End Function
