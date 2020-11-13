
Function wasi_helper_print_consume_lines(fd as Integer, added as String, lineCallback as Dynamic)
    str = m.wasi_outputs[fd] + added
    While True
        newlineIndex = Instr(1, str, Chr(10))
        If newlineIndex <> 0 Then
            line = Left(str, newlineIndex - 1)
            Print line
            If lineCallback <> Invalid Then lineCallback(fd, line)
            str = Mid(str, newlineIndex + 1)
        Else
            Exit While
        End If
    End While
    m.wasi_outputs[fd] = str
End Function

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

    ' Indexed by the stdout(1) / stderr(2) fd
    m.wasi_outputs = [invalid, "", ""]
End Function

Function wasi_snapshot_preview1_proc_exit(rval As Integer) As Void
    Stop
End Function

Function wasi_snapshot_preview1_args_sizes_get(argc_pSize As Integer, argv_buf_pSize As Integer) As Integer
    StringArrayWriteSizes(m.wasi_memory, m.wasi_config.args, argc_pSize, argv_buf_pSize)
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_args_get(argv_ppU8 As Integer, argv_buf_pU8 As Integer) As Integer
    StringArrayWriteMemory(m.wasi_memory, m.wasi_config.args, argv_ppU8, argv_buf_pU8)
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_environ_sizes_get(argc_pSize As Integer, argv_buf_pSize As Integer) As Integer
    StringArrayWriteSizes(m.wasi_memory, m.wasi_config.env, argc_pSize, argv_buf_pSize)
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_environ_get(argv_ppU8 As Integer, argv_buf_pU8 As Integer) As Integer
    StringArrayWriteMemory(m.wasi_memory, m.wasi_config.env, argv_ppU8, argv_buf_pU8)
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_fd_write(fd As Integer, iovs_pCiovec As Integer, iovs_len As Integer, nwritten_pSize As Integer) As Integer
    nwritten = 0
    For i = 0 To iovs_len - 1
        buf_pU8 = I32Load(m.wasi_memory, iovs_pCiovec)
        buf_len_Size = I32Load(m.wasi_memory, iovs_pCiovec + 4)
        nwritten += buf_len_Size
        If fd = 1 Or fd = 2 Then ' stdout Or stderr
            str = StringFromBytes(m.wasi_memory, buf_pU8, buf_len_Size)
            m.wasi_stdout = wasi_helper_print_consume_lines(fd, str, m.wasi_print_line)
        Else
            Stop ' Need to handle writing to fds
        End If
        iovs_pCiovec += 8
    End For
    I32Store(m.wasi_memory, nwritten_pSize, nwritten)
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_path_open(fd As Integer, dirflags As Integer, path_pU8 As Integer, path_len_Size As Integer, oflags As Integer, fs_rights_base As LongInteger, fs_rights_inherting As LongInteger, fdflags As Integer, opened_fd_pFd As Integer) As Integer
    path = StringFromBytes(m.wasi_memory, path_pU8, path_len_Size)
    Stop
    Return 11
End Function

Function wasi_snapshot_preview1_fd_close(fd As Integer) As Integer
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_path_filestat_get(fd As Integer, flags As Integer, path_pU8 As Integer, path_len_Size As Integer, buf_pFilestat As Integer) As Integer
    path = StringFromBytes(m.wasi_memory, path_pU8, path_len_Size)
    Stop
    Return 11
End Function

Function wasi_snapshot_preview1_fd_prestat_get(fd As Integer, buf_pPrestat As Integer) As Integer
    Return 8 ' badf
End Function

Function wasi_snapshot_preview1_fd_prestat_dir_name(fd As Integer, path_pU8 As Integer, path_len_Size As Integer) As Integer
    Return 52 ' nosys
End Function
