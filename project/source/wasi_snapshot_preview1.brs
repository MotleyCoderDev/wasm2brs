
Function wasi_helper_snapshot_preview1_init(memory as Object, executableFile as String, config as Object)
    m.wasi_memory = memory
    m.wasi_config = config

    If Not m.wasi_config.DoesExist("args") Then
        m.wasi_config.args = []
    End If
    If m.wasi_config.DoesExist("env") Then
        If GetInterface(m.wasi_config.env, "ifAssociativeArray") <> invalid Then
            envAssociative = m.wasi_config.env
            m.wasi_config.env = []
            For Each envName In envAssociative
                m.wasi_config.env.Push(envName + "=" + envAssociative[envName])
            End For
        End If
    Else
        m.wasi_config.env = []
    End If

    m.wasi_config.args.Unshift(executableFile)

    m.wasi_stdout = ""
    m.wasi_stderr = ""
End Function

Function wasi_snapshot_preview1_proc_exit(rval As Integer) As Void
    Stop
End Function

Function wasi_snapshot_preview1_args_sizes_get(argc_pSize As Integer, argv_buf_pSize As Integer) As Integer
    StringArrayWriteSizes(m.wasi_memory, m.wasi_config.args, argc_pSize, argv_buf_pSize)
End Function

Function wasi_snapshot_preview1_args_get(argv_ppU8 As Integer, argv_buf_pU8 As Integer) As Integer
    StringArrayWriteMemory(m.wasi_memory, m.wasi_config.args, argv_ppU8, argv_buf_pU8)
End Function

Function wasi_snapshot_preview1_environ_sizes_get(argc_pSize As Integer, argv_buf_pSize As Integer) As Integer
    StringArrayWriteSizes(m.wasi_memory, m.wasi_config.env, argc_pSize, argv_buf_pSize)
End Function

Function wasi_snapshot_preview1_environ_get(argv_ppU8 As Integer, argv_buf_pU8 As Integer) As Integer
    StringArrayWriteMemory(m.wasi_memory, m.wasi_config.env, argv_ppU8, argv_buf_pU8)
End Function

Function wasi_snapshot_preview1_fd_write(fd As Integer, iovs_pCiovec As Integer, iovs_len As Integer, nwritten_pSize As Integer) As Integer
    nwritten = 0
    For i = 0 To iovs_len - 1
        buf_pU8 = I32Load(m.wasi_memory, iovs_pCiovec)
        buf_len_Size = I32Load(m.wasi_memory, iovs_pCiovec + 4)
        nwritten += buf_len_Size
        If fd = 1 Or fd = 2 Then ' stdout Or stderr
            str = StringFromBytes(m.wasi_memory, buf_pU8, buf_len_Size)
            If fd = 1 Then
                m.wasi_stdout += str
                m.wasi_stdout = PrintAndConsumeLines(m.wasi_stdout)
            Else
                m.wasi_stderr += str
                m.wasi_stderr = PrintAndConsumeLines(m.wasi_stderr)
            End If
        Else
            Stop ' Need to handle writing to fds
        End If
        iovs_pCiovec += 8
    End For
    I32Store(m.wasi_memory, nwritten_pSize, nwritten)
    Return 0 ' success
End Function
