
Function wasi_enum_filetype_directory() As Integer
    Return 3
End Function

Function wasi_enum_filetype_regular_file() As Integer
    Return 4
End Function


Function wasi_snapshot_preview1_enum_whence_set() As Integer
    Return 0
End Function

Function wasi_snapshot_preview1_enum_whence_cur() As Integer
    Return 1
End Function

Function wasi_snapshot_preview1_enum_whence_end() As Integer
    Return 2
End Function


Function wasi_unstable_enum_whence_set() As Integer
    Return 2
End Function

Function wasi_unstable_enum_whence_cur() As Integer
    Return 0
End Function

Function wasi_unstable_enum_whence_end() As Integer
    Return 1
End Function

Function wasi_helper_output(fd as Integer, bytes as Object) as Void
    file = m.wasi_fds[fd]
    If file = Invalid Or fd <> 1 And fd <> 2 Throw "Invalid output fd"
    file.memory.Append(bytes)
    file.memory = PrintAndConsumeLines(fd, file.memory, m.external_print_line)
End Function

Function external_append_stdin(bytesOrString as Dynamic) as Void
    If IsString(bytesOrString) Then
        bytesOrString = StringToBytes(bytesOrString)
    End If
    m.wasi_fds[0].memory.Append(bytesOrString)
End Function

Function wasi_helper_create_file(path as String, filetype as Integer) as Object
    file = { path: path, pathBytes: StringToBytes(path), filetype: filetype, fd: m.wasi_fds.Count() }
    m.wasi_fds.Push(file)
    Return file
End Function

Function wasi_helper_create_memory_file(path as String) as Object
    file = wasi_helper_create_file(path, wasi_enum_filetype_regular_file())
    file.memory = CreateObject("roByteArray")
    file.position = 0&
    Return file
End Function

Function wasi_helper_recurse_preopen_dirs(dir as String) as Void
    stat = m.wasi_filesystem.Stat(dir)
    If stat.type <> "directory" Return
    wasi_helper_create_file(dir, wasi_enum_filetype_directory())
    For Each filename In m.wasi_filesystem.GetDirectoryListing(dir)
        wasi_helper_recurse_preopen_dirs(dir + "/" + filename)
    End For
End Function

Function wasi_helper_datetime_to_nanoseconds(dateTime as Object) as LongInteger
    nanoseconds = I32ToUnsignedI64(m.wasi_date.AsSeconds()) * 1000000000&
    nanoseconds += m.wasi_date.GetMilliseconds() * 1000000&
    Return nanoseconds
End Function

Function wasi_init(memory as Object, executableFile as String, config as Object)
    m.wasi_memory = memory
    m.wasi_config = config

    If Not m.wasi_config.DoesExist("args") Then
        m.wasi_config.args = []
    End If
    If Not m.wasi_config.DoesExist("env") Then
        m.wasi_config.env = []
    End If

    m.wasi_config.args.Unshift(executableFile)

    If Not m.DoesExist("external_output") Then
        m.external_output = wasi_helper_output
    End If

    ' Indexed by fds stdin(0) / stdout(1) / stderr(2)
    m.wasi_fds = []
    wasi_helper_create_memory_file("/dev/stdin")
    wasi_helper_create_memory_file("/dev/stdout")
    wasi_helper_create_memory_file("/dev/stderr")

    m.wasi_filesystem = CreateObject("roFileSystem")

    wasi_helper_recurse_preopen_dirs("pkg:/")

    If m.wasi_config.DoesExist("stdin") Then
        external_append_stdin(m.wasi_config.stdin)
    End If

    m.wasi_date = CreateObject("roDateTime")
End Function

Function wasi_snapshot_preview1_proc_exit(rval As Integer) As Void
    Throw "Exit:" + rval.ToStr()
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
    nread = 0
    file = m.wasi_fds[fd]
    For i = 0 To iovs_len - 1
        buf_pU8 = I32Load(m.wasi_memory, iovs_pCiovec)
        buf_len_Size = I32Load(m.wasi_memory, iovs_pCiovec + 4)
        If fd = 0 Then ' stdin
            If file.memory.Count() = 0 And m.external_wait_for_stdin <> Invalid Then
                m.external_wait_for_stdin()
            End If
        End If
        existingSize = file.memory.Count() - file.position
        copySize = Min(buf_len_Size, existingSize)
        MemoryCopy(m.wasi_memory, buf_pU8, file.memory, file.position, copySize)
        file.position += copySize
        nread += copySize
        iovs_pCiovec += 8
    End For
    I32Store(m.wasi_memory, nread_pSize, nread)
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_path_open(fd As Integer, dirflags As Integer, path_pU8 As Integer, path_len_Size As Integer, oflags As Integer, fs_rights_base As LongInteger, fs_rights_inherting As LongInteger, fdflags As Integer, opened_fd_pFd As Integer) As Integer
    dir = m.wasi_fds[fd]
    If dir = Invalid Return 8 ' badf
    path = dir.path + StringFromBytes(m.wasi_memory, path_pU8, path_len_Size)
    file = wasi_helper_create_memory_file(path)
    ' Not correct as this is read only and doesn't account for directories, writes, etc.
    If Not file.memory.ReadFile(path) Then
        Return 8 ' badf
    End If
    I32Store(m.wasi_memory, opened_fd_pFd, file.fd)
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_path_filestat_get(fd As Integer, flags As Integer, path_pU8 As Integer, path_len_Size As Integer, buf_pFilestat As Integer) As Integer
    dir = m.wasi_fds[fd]
    If dir = Invalid Return 8 ' badf
    path = dir.path + StringFromBytes(m.wasi_memory, path_pU8, path_len_Size)
    stats = m.wasi_filesystem.Stat(path)
    If stats.type = Invalid Return 44 ' noent
    If stats.type = "directory" Then
        filetype = wasi_enum_filetype_directory()
    Else
        filetype = wasi_enum_filetype_regular_file()
    End If
    
    ctime = wasi_helper_datetime_to_nanoseconds(stats.ctime)
    mtime = wasi_helper_datetime_to_nanoseconds(stats.mtime)

    I64Store(m.wasi_memory, buf_pFilestat + 0, 0)
    I64Store(m.wasi_memory, buf_pFilestat + 8, 0)
    I32Store8(m.wasi_memory, buf_pFilestat + 16, filetype)
    I64Store(m.wasi_memory, buf_pFilestat + 24, 0)
    I64Store(m.wasi_memory, buf_pFilestat + 32, stats.sizeex)
    I64Store(m.wasi_memory, buf_pFilestat + 40, mtime) 'atime, but we don't have it so use mtime
    I64Store(m.wasi_memory, buf_pFilestat + 48, mtime)
    I64Store(m.wasi_memory, buf_pFilestat + 56, ctime)
    Return 0
End Function

Function wasi_snapshot_preview1_fd_close(fd As Integer) As Integer
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_fd_seek(fd As Integer, offset As LongInteger, whence As Integer, newoffset_pU64 As Integer) As Integer
    file = m.wasi_fds[fd]
    If file = Invalid Return 8 ' badf
    If whence = wasi_snapshot_preview1_enum_whence_set() Then
        file.position = offset
    Else If whence = wasi_snapshot_preview1_enum_whence_cur() Then
        file.position += offset
    Else
        file.position = file.memory.Count() + offset
    End If
    I64Store(m.wasi_memory, newoffset_pU64, file.position)
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_fd_fdstat_get(fd As Integer, pFdstat As Integer) As Integer
    file = m.wasi_fds[fd]
    If file = Invalid Return 8 ' badf
    I32Store8(m.wasi_memory, pFdstat, file.filetype)
    I32Store16(m.wasi_memory, pFdstat + 2, 0)
    I64Store(m.wasi_memory, pFdstat + 8, &HFFFFFFFFFFFFFFFF&) ' rights base
    I64Store(m.wasi_memory, pFdstat + 16, &HFFFFFFFFFFFFFFFF&) ' rights inheriting
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_fd_prestat_get(fd As Integer, buf_pPrestat As Integer) As Integer
    file = m.wasi_fds[fd]
    If file = Invalid Return 8 ' badf
    I32Store8(m.wasi_memory, buf_pPrestat, 0) ' 0 means dir
    I32Store(m.wasi_memory, buf_pPrestat + 4, file.pathBytes.Count())
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_fd_prestat_dir_name(fd As Integer, path_pU8 As Integer, path_len_Size As Integer) As Integer
    file = m.wasi_fds[fd]
    If file = Invalid Return 8 ' badf
    MemoryCopy(m.wasi_memory, path_pU8, file.pathBytes, 0, path_len_Size)
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_clock_time_get(clockid As Integer, precision As LongInteger, time_pTimestamp64 As Integer) As Integer
    m.wasi_date.Mark()
    I64Store(m.wasi_memory, time_pTimestamp64, wasi_helper_datetime_to_nanoseconds(m.wasi_date))
    Return 0 ' success
End Function

Function wasi_snapshot_preview1_poll_oneoff(in_pSubscription As Integer, out_pEvent As Integer, nsubscriptions As Integer, nevents_pSize As Integer) As Integer
    ' Not yet implemented (things like sleep)
    Stop
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
    Return wasi_snapshot_preview1_fd_fdstat_get(p0, p1)
End Function
Function wasi_unstable_path_filestat_get(fd As Integer, flags As Integer, path_pU8 As Integer, path_len_Size As Integer, buf_pFilestat As Integer) As Integer
    Return wasi_snapshot_preview1_path_filestat_get(fd, flags, path_pU8, path_len_Size, buf_pFilestat)
End Function
Function wasi_unstable_path_open(p0 As Integer, p1 As Integer, p2 As Integer, p3 As Integer, p4 As Integer, p5 As LongInteger, p6 As LongInteger, p7 As Integer, p8 As Integer) As Integer
    Return wasi_snapshot_preview1_path_open(p0, p1, p2, p3, p4, p5, p6, p7, p8)
End Function
Function wasi_unstable_fd_close(p0 As Integer) As Integer
    Return wasi_snapshot_preview1_fd_close(p0)
End Function
Function wasi_unstable_fd_seek(fd As Integer, offset As LongInteger, whence As Integer, newoffset_pU64 As Integer) As Integer
    If whence = wasi_unstable_enum_whence_set() Then
        whence = wasi_snapshot_preview1_enum_whence_set()
    Else If whence = wasi_unstable_enum_whence_cur() Then
        whence = wasi_snapshot_preview1_enum_whence_cur()
    Else
        whence = wasi_snapshot_preview1_enum_whence_end()
    End If
    Return wasi_snapshot_preview1_fd_seek(fd, offset, whence, newoffset_pU64)
End Function
Function wasi_unstable_fd_write(p0 As Integer, p1 As Integer, p2 As Integer, p3 As Integer) As Integer
    Return wasi_snapshot_preview1_fd_write(p0, p1, p2, p3)
End Function
Function wasi_unstable_fd_read(p0 As Integer, p1 As Integer, p2 As Integer, p3 As Integer) As Integer
    Return wasi_snapshot_preview1_fd_read(p0, p1, p2, p3)
End Function
Function wasi_unstable_args_sizes_get(p0 As Integer, p1 As Integer) As Integer
    Return wasi_snapshot_preview1_args_sizes_get(p0, p1)
End Function

Function wasi_unstable_args_get(p0 As Integer, p1 As Integer) As Integer
    Return wasi_snapshot_preview1_args_sizes_get(p0, p1)
End Function
Function wasi_unstable_environ_sizes_get(p0 As Integer, p1 As Integer) As Integer
    Return wasi_snapshot_preview1_environ_sizes_get(p0, p1)
End Function
Function wasi_unstable_environ_get(p0 As Integer, p1 As Integer) As Integer
    Return wasi_snapshot_preview1_environ_get(p0, p1)
End Function
Function wasi_unstable_clock_time_get(p0 As Integer, p1 As LongInteger, p2 As Integer) As Integer
    Return wasi_snapshot_preview1_clock_time_get(p0, p1, p2)
End Function
Function wasi_unstable_poll_oneoff(p0 As Integer, p1 As Integer, p2 As Integer, p3 As Integer) As Integer
    Return wasi_snapshot_preview1_poll_oneoff(p0, p1, p2, p3)
End Function