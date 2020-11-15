
Function wasi_helper_output(fd as Integer, bytes as Object) as Void
    m.wasi_fds[fd].Append(bytes)
    m.wasi_fds[fd] = PrintAndConsumeLines(fd, m.wasi_fds[fd], m.external_print_line)
End Function

Function external_append_stdin(bytesOrString as Dynamic) as Void
    If IsString(bytesOrString) Then
        bytesOrString = StringToBytes(bytesOrString)
    End If
    m.wasi_fds[0].Append(bytesOrString)
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

    If Not m.DoesExist("external_output") Then
        m.external_output = wasi_helper_output
    End If

    ' Indexed by fds stdin(0) / stdout(1) / stderr(2)
    m.wasi_fds = [CreateObject("roByteArray"), CreateObject("roByteArray"), CreateObject("roByteArray")]

    If m.wasi_config.DoesExist("stdin") Then
        external_append_stdin(m.wasi_config.stdin)
    End If
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
    If Not (fd = 1 Or fd = 2) Then ' Not stdout Or stderr
        Return 8 ' badf
    End If

    nwritten = 0
    For i = 0 To iovs_len - 1
        buf_pU8 = I32Load(m.wasi_memory, iovs_pCiovec)
        buf_len_Size = I32Load(m.wasi_memory, iovs_pCiovec + 4)
        nwritten += buf_len_Size
        bytes = Slice(m.wasi_memory, buf_pU8, buf_len_Size)
        If fd = 1 Or fd = 2 Then ' stdout Or stderr
            m.external_output(fd, bytes)
        Else
            Stop ' Need to handle writing to fds
        End If
        iovs_pCiovec += 8
    End For
    I32Store(m.wasi_memory, nwritten_pSize, nwritten)
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_fd_read(fd As Integer, iovs_pCiovec As Integer, iovs_len As Integer, nread_pSize As Integer) As Integer
    If Not (fd = 0) Then ' Not stdin
        Return 8 ' badf
    End If

    nread = 0
    For i = 0 To iovs_len - 1
        buf_pU8 = I32Load(m.wasi_memory, iovs_pCiovec)
        buf_len_Size = I32Load(m.wasi_memory, iovs_pCiovec + 4)
        If fd = 0 Then ' stdin
            If m.wasi_fds[0].Count() = 0 And m.external_wait_for_stdin <> Invalid Then
                m.external_wait_for_stdin()
            End If
            existingSize = m.wasi_fds[0].Count()
            copySize = Min(buf_len_Size, existingSize)
            MemoryCopy(m.wasi_memory, buf_pU8, m.wasi_fds[0], 0, copySize)
            m.wasi_fds[0] = Slice(m.wasi_fds[0], copySize, existingSize - copySize)
            nread += copySize
        Else
            Stop ' Need to handle reading from fds
        End If
        iovs_pCiovec += 8
    End For
    I32Store(m.wasi_memory, nread_pSize, nread)
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


Function wasi_unstable_fd_prestat_get(p0 As Integer, p1 As Integer) As Integer
    Return wasi_snapshot_preview1_fd_prestat_get(p0, p1)
End Function
Function wasi_unstable_fd_prestat_dir_name(p0 As Integer, p1 As Integer, p2 As Integer) As Integer
    Return wasi_snapshot_preview1_fd_prestat_dir_name(p0, p1, p2)
End Function
Function wasi_unstable_proc_exit(p0 As Integer) As Void
    wasi_snapshot_preview1_proc_exit(p0)
End Function
Function wasi_unstable_fd_fdstat_get(p0 As Integer, p1 As Integer) As Integer
    Return 8 ' badf
End Function
Function wasi_unstable_fd_close(p0 As Integer) As Integer
    Return wasi_snapshot_preview1_fd_close(p0)
End Function
Function wasi_unstable_fd_seek(p0 As Integer, p1 As LongInteger, p2 As Integer, p3 As Integer) As Integer
    Return 8 ' badf
End Function
Function wasi_unstable_fd_write(p0 As Integer, p1 As Integer, p2 As Integer, p3 As Integer) As Integer
    Return wasi_snapshot_preview1_fd_write(p0, p1, p2, p3)
End Function
