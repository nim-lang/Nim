#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements an advanced facility for executing OS processes
## and process communication.

include "system/inclrtl"

import
  strutils, os, strtabs, streams

when defined(windows):
  import winlean
else:
  import posix

type
  TProcess = object of TObject
    when defined(windows):
      FProcessHandle: THandle
      inHandle, outHandle, errHandle: TFileHandle
      id: THandle
    else:
      inHandle, outHandle, errHandle: TFileHandle
      inStream, outStream, errStream: PStream
      id: TPid
    exitCode: cint

  PProcess* = ref TProcess ## represents an operating system process

  TProcessOption* = enum ## options that can be passed `startProcess`
    poEchoCmd,           ## echo the command before execution
    poUseShell,          ## use the shell to execute the command; NOTE: This
                         ## often creates a security hole!
    poStdErrToStdOut,    ## merge stdout and stderr to the stdout stream
    poParentStreams      ## use the parent's streams

proc quoteShellWindows*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
  ## Quote s, so it can be safely passed to Windows API.
  ## Based on Python's subprocess.list2cmdline
  ## See http://msdn.microsoft.com/en-us/library/17w5ykft.aspx
  let needQuote = {' ', '\t'} in s or s.len == 0

  result = ""
  var backslashBuff = ""
  if needQuote:
    result.add("\"")

  for c in s:
    if c == '\\':
      backslashBuff.add(c)
    elif c == '\"':
      result.add(backslashBuff)
      result.add(backslashBuff)
      backslashBuff.setLen(0)
      result.add("\\\"")
    else:
      if backslashBuff.len != 0:
        result.add(backslashBuff)
        backslashBuff.setLen(0)
      result.add(c)

  if needQuote:
    result.add("\"")

proc quoteShellPosix*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
  ## Quote s, so it can be safely passed to POSIX shell.
  ## Based on Python's pipes.quote
  const safeUnixChars = {'%', '+', '-', '.', '/', '_', ':', '=', '@',
                         '0'..'9', 'A'..'Z', 'a'..'z'}
  if s.len == 0:
    return "''"

  let safe = s.allCharsInSet(safeUnixChars)

  if safe:
    return s
  else:
    return "'" & s.replace("'", "'\"'\"'") & "'"

proc quoteShell*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
  ## Quote s, so it can be safely passed to shell.
  when defined(Windows):
    return quoteShellWindows(s)
  elif defined(posix):
    return quoteShellPosix(s)
  else:
    {.error:"quoteShell is not supported on your system".}

proc execProcess*(command: string,
                  options: set[TProcessOption] = {poStdErrToStdOut,
                                                  poUseShell}): TaintedString {.
                                                  rtl, extern: "nosp$1",
                                                  tags: [FExecIO, FReadIO].}
  ## A convenience procedure that executes ``command`` with ``startProcess``
  ## and returns its output as a string.

proc execCmd*(command: string): int {.rtl, extern: "nosp$1", tags: [FExecIO].}
  ## Executes ``command`` and returns its error code. Standard input, output,
  ## error streams are inherited from the calling process. This operation
  ## is also often called `system`:idx:.

proc startProcess*(command: string,
                   workingDir: string = "",
                   args: openArray[string] = [],
                   env: PStringTable = nil, 
                   options: set[TProcessOption] = {poStdErrToStdOut}): 
              PProcess {.rtl, extern: "nosp$1", tags: [FExecIO, FReadEnv].}
  ## Starts a process. `Command` is the executable file, `workingDir` is the
  ## process's working directory. If ``workingDir == ""`` the current directory
  ## is used. `args` are the command line arguments that are passed to the
  ## process. On many operating systems, the first command line argument is the
  ## name of the executable. `args` should not contain this argument!
  ## `env` is the environment that will be passed to the process.
  ## If ``env == nil`` the environment is inherited of
  ## the parent process. `options` are additional flags that may be passed
  ## to `startProcess`. See the documentation of ``TProcessOption`` for the
  ## meaning of these flags. You need to `close` the process when done.
  ##
  ## Return value: The newly created process object. Nil is never returned,
  ## but ``EOS`` is raised in case of an error.

proc startCmd*(command: string, options: set[TProcessOption] = {
               poStdErrToStdOut, poUseShell}): PProcess {.
               tags: [FExecIO, FReadEnv].} =
  ## a simpler version of `startProcess` that parses the command line into
  ## program and arguments and then calls `startProcess` with the empty string
  ## for `workingDir` and the nil string table for `env`.
  var c = parseCmdLine(command)
  var a: seq[string]
  newSeq(a, c.len-1) # avoid slicing for now (still unstable)
  for i in 1 .. c.len-1: a[i-1] = c[i]
  result = startProcess(command=c[0], args=a, options=options)

proc close*(p: PProcess) {.rtl, extern: "nosp$1", tags: [].}
  ## When the process has finished executing, cleanup related handles

proc suspend*(p: PProcess) {.rtl, extern: "nosp$1", tags: [].}
  ## Suspends the process `p`.

proc resume*(p: PProcess) {.rtl, extern: "nosp$1", tags: [].}
  ## Resumes the process `p`.

proc terminate*(p: PProcess) {.rtl, extern: "nosp$1", tags: [].}
  ## Terminates the process `p`.

proc running*(p: PProcess): bool {.rtl, extern: "nosp$1", tags: [].}
  ## Returns true iff the process `p` is still running. Returns immediately.

proc processID*(p: PProcess): int {.rtl, extern: "nosp$1".} =
  ## returns `p`'s process ID.
  return p.id

proc waitForExit*(p: PProcess, timeout: int = -1): int {.rtl, 
  extern: "nosp$1", tags: [].}
  ## waits for the process to finish and returns `p`'s error code.

proc peekExitCode*(p: PProcess): int {.tags: [].}
  ## return -1 if the process is still running. Otherwise the process' exit code

proc inputStream*(p: PProcess): PStream {.rtl, extern: "nosp$1", tags: [].}
  ## returns ``p``'s input stream for writing to.
  ##
  ## **Warning**: The returned `PStream` should not be closed manually as it 
  ## is closed when closing the PProcess ``p``.

proc outputStream*(p: PProcess): PStream {.rtl, extern: "nosp$1", tags: [].}
  ## returns ``p``'s output stream for reading from.
  ##
  ## **Warning**: The returned `PStream` should not be closed manually as it 
  ## is closed when closing the PProcess ``p``.

proc errorStream*(p: PProcess): PStream {.rtl, extern: "nosp$1", tags: [].}
  ## returns ``p``'s error stream for reading from.
  ##
  ## **Warning**: The returned `PStream` should not be closed manually as it 
  ## is closed when closing the PProcess ``p``.

proc inputHandle*(p: PProcess): TFileHandle {.rtl, extern: "nosp$1",
  tags: [].} =
  ## returns ``p``'s input file handle for writing to.
  ##
  ## **Warning**: The returned `TFileHandle` should not be closed manually as
  ## it is closed when closing the PProcess ``p``.
  result = p.inHandle

proc outputHandle*(p: PProcess): TFileHandle {.rtl, extern: "nosp$1",
  tags: [].} =
  ## returns ``p``'s output file handle for reading from.
  ##
  ## **Warning**: The returned `TFileHandle` should not be closed manually as
  ## it is closed when closing the PProcess ``p``.
  result = p.outHandle

proc errorHandle*(p: PProcess): TFileHandle {.rtl, extern: "nosp$1",
  tags: [].} =
  ## returns ``p``'s error file handle for reading from.
  ##
  ## **Warning**: The returned `TFileHandle` should not be closed manually as
  ## it is closed when closing the PProcess ``p``.
  result = p.errHandle

when defined(macosx) or defined(bsd):
  const
    CTL_HW = 6
    HW_AVAILCPU = 25
    HW_NCPU = 3
  proc sysctl(x: ptr array[0..3, cint], y: cint, z: pointer,
              a: var csize, b: pointer, c: int): cint {.
             importc: "sysctl", header: "<sys/sysctl.h>".}

proc countProcessors*(): int {.rtl, extern: "nosp$1".} =
  ## returns the numer of the processors/cores the machine has.
  ## Returns 0 if it cannot be detected.
  when defined(windows):
    var x = getEnv("NUMBER_OF_PROCESSORS")
    if x.len > 0: result = parseInt(x.string)
  elif defined(macosx) or defined(bsd):
    var
      mib: array[0..3, cint]
      numCPU: int
      len: csize
    mib[0] = CTL_HW
    mib[1] = HW_AVAILCPU
    len = sizeof(numCPU)
    discard sysctl(addr(mib), 2, addr(numCPU), len, nil, 0)
    if numCPU < 1:
      mib[1] = HW_NCPU
      discard sysctl(addr(mib), 2, addr(numCPU), len, nil, 0)
    result = numCPU
  elif defined(hpux):
    result = mpctl(MPC_GETNUMSPUS, nil, nil)
  elif defined(irix):
    var SC_NPROC_ONLN {.importc: "_SC_NPROC_ONLN", header: "<unistd.h>".}: cint
    result = sysconf(SC_NPROC_ONLN)
  else:
    result = sysconf(SC_NPROCESSORS_ONLN)
  if result <= 0: result = 1

proc execProcesses*(cmds: openArray[string],
                    options = {poStdErrToStdOut, poParentStreams},
                    n = countProcessors()): int {.rtl, extern: "nosp$1", 
                    tags: [FExecIO, FTime, FReadEnv].} =
  ## executes the commands `cmds` in parallel. Creates `n` processes
  ## that execute in parallel. The highest return value of all processes
  ## is returned.
  when defined(posix):
    # poParentStreams causes problems on Posix, so we simply disable it:
    var options = options - {poParentStreams}
  
  assert n > 0
  if n > 1:
    var q: seq[PProcess]
    newSeq(q, n)
    var m = min(n, cmds.len)
    for i in 0..m-1:
      q[i] = startCmd(cmds[i], options=options)
    when defined(noBusyWaiting):
      var r = 0
      for i in m..high(cmds):
        when defined(debugExecProcesses):
          var err = ""
          var outp = outputStream(q[r])
          while running(q[r]) or not atEnd(outp):
            err.add(outp.readLine())
            err.add("\n")
          echo(err)
        result = max(waitForExit(q[r]), result)
        if q[r] != nil: close(q[r])
        q[r] = startCmd(cmds[i], options=options)
        r = (r + 1) mod n
    else:
      var i = m
      while i <= high(cmds):
        sleep(50)
        for r in 0..n-1:
          if not running(q[r]):
            #echo(outputStream(q[r]).readLine())
            result = max(waitForExit(q[r]), result)
            if q[r] != nil: close(q[r])
            q[r] = startCmd(cmds[i], options=options)
            inc(i)
            if i > high(cmds): break
    for j in 0..m-1:
      result = max(waitForExit(q[j]), result)
      if q[j] != nil: close(q[j])
  else:
    for i in 0..high(cmds):
      var p = startCmd(cmds[i], options=options)
      result = max(waitForExit(p), result)
      close(p)

proc select*(readfds: var seq[PProcess], timeout = 500): int
  ## `select` with a sensible Nimrod interface. `timeout` is in miliseconds.
  ## Specify -1 for no timeout. Returns the number of processes that are
  ## ready to read from. The processes that are ready to be read from are
  ## removed from `readfds`.
  ##
  ## **Warning**: This function may give unexpected or completely wrong
  ## results on Windows.

when not defined(useNimRtl):
  proc execProcess(command: string,
                   options: set[TProcessOption] = {poStdErrToStdOut,
                                                   poUseShell}): TaintedString =
    var p = startCmd(command, options=options)
    var outp = outputStream(p)
    result = TaintedString""
    var line = newStringOfCap(120).TaintedString
    while true:
      if outp.readLine(line):
        result.string.add(line.string)
        result.string.add("\n")
      elif not running(p): break
    close(p)


when defined(Windows) and not defined(useNimRtl):
  # We need to implement a handle stream for Windows:
  type
    PFileHandleStream = ref TFileHandleStream
    TFileHandleStream = object of TStream
      handle: THandle
      atTheEnd: bool

  proc hsClose(s: PStream) = nil # nothing to do here
  proc hsAtEnd(s: PStream): bool = return PFileHandleStream(s).atTheEnd

  proc hsReadData(s: PStream, buffer: pointer, bufLen: int): int =
    var s = PFileHandleStream(s)
    if s.atTheEnd: return 0
    var br: int32
    var a = winlean.ReadFile(s.handle, buffer, bufLen.cint, br, nil)
    # TRUE and zero bytes returned (EOF).
    # TRUE and n (>0) bytes returned (good data).
    # FALSE and bytes returned undefined (system error).
    if a == 0 and br != 0: osError(osLastError())
    s.atTheEnd = br < bufLen
    result = br

  proc hsWriteData(s: PStream, buffer: pointer, bufLen: int) =
    var s = PFileHandleStream(s)
    var bytesWritten: int32
    var a = winlean.writeFile(s.handle, buffer, bufLen.cint, bytesWritten, nil)
    if a == 0: osError(osLastError())

  proc newFileHandleStream(handle: THandle): PFileHandleStream =
    new(result)
    result.handle = handle
    result.closeImpl = hsClose
    result.atEndImpl = hsAtEnd
    result.readDataImpl = hsReadData
    result.writeDataImpl = hsWriteData

  proc buildCommandLine(a: string, args: openArray[string]): cstring =
    var res = quoteShell(a)
    for i in 0..high(args):
      res.add(' ')
      res.add(quoteShell(args[i]))
    result = cast[cstring](alloc0(res.len+1))
    copyMem(result, cstring(res), res.len)

  proc buildEnv(env: PStringTable): cstring =
    var L = 0
    for key, val in pairs(env): inc(L, key.len + val.len + 2)
    result = cast[cstring](alloc0(L+2))
    L = 0
    for key, val in pairs(env):
      var x = key & "=" & val
      copyMem(addr(result[L]), cstring(x), x.len+1) # copy \0
      inc(L, x.len+1)

  #proc open_osfhandle(osh: THandle, mode: int): int {.
  #  importc: "_open_osfhandle", header: "<fcntl.h>".}

  #var
  #  O_WRONLY {.importc: "_O_WRONLY", header: "<fcntl.h>".}: int
  #  O_RDONLY {.importc: "_O_RDONLY", header: "<fcntl.h>".}: int

  proc createPipeHandles(Rdhandle, WrHandle: var THandle) =
    var piInheritablePipe: TSECURITY_ATTRIBUTES
    piInheritablePipe.nlength = sizeof(TSECURITY_ATTRIBUTES).cint
    piInheritablePipe.lpSecurityDescriptor = nil
    piInheritablePipe.Binherithandle = 1
    if createPipe(Rdhandle, WrHandle, piInheritablePipe, 1024) == 0'i32:
      osError(osLastError())

  proc fileClose(h: THandle) {.inline.} =
    if h > 4: discard closeHandle(h)

  proc startProcess(command: string,
                 workingDir: string = "",
                 args: openArray[string] = [],
                 env: PStringTable = nil,
                 options: set[TProcessOption] = {poStdErrToStdOut}): PProcess =
    var
      si: TSTARTUPINFO
      procInfo: TPROCESS_INFORMATION
      success: int
      hi, ho, he: THandle
    new(result)
    si.cb = sizeof(si).cint
    if poParentStreams notin options:
      si.dwFlags = STARTF_USESTDHANDLES # STARTF_USESHOWWINDOW or
      createPipeHandles(si.hStdInput, hi)
      createPipeHandles(ho, si.hStdOutput)
      if poStdErrToStdOut in options:
        si.hStdError = si.hStdOutput
        he = ho
      else:
        createPipeHandles(he, si.hStdError)
      result.inHandle = TFileHandle(hi)
      result.outHandle = TFileHandle(ho)
      result.errHandle = TFileHandle(he)
    else:
      si.hStdError = getStdHandle(STD_ERROR_HANDLE)
      si.hStdInput = getStdHandle(STD_INPUT_HANDLE)
      si.hStdOutput = getStdHandle(STD_OUTPUT_HANDLE)
      result.inHandle = TFileHandle(si.hStdInput)
      result.outHandle = TFileHandle(si.hStdOutput)
      result.errHandle = TFileHandle(si.hStdError)

    var cmdl: cstring
    when false: # poUseShell in options:
      cmdl = buildCommandLine(getEnv("COMSPEC"), @["/c", command] & args)
    else:
      cmdl = buildCommandLine(command, args)
    var wd: cstring = nil
    var e: cstring = nil
    if len(workingDir) > 0: wd = workingDir
    if env != nil: e = buildEnv(env)
    if poEchoCmd in options: echo($cmdl)
    when useWinUnicode:
      var tmp = newWideCString(cmdl)
      var ee = newWideCString(e)
      var wwd = newWideCString(wd)
      success = winlean.CreateProcessW(nil,
        tmp, nil, nil, 1, NORMAL_PRIORITY_CLASS or CREATE_UNICODE_ENVIRONMENT, 
        ee, wwd, si, procInfo)
    else:
      success = winlean.CreateProcessA(nil,
        cmdl, nil, nil, 1, NORMAL_PRIORITY_CLASS, e, wd, SI, ProcInfo)
    let lastError = osLastError()

    if poParentStreams notin options:
      fileClose(si.hStdInput)
      fileClose(si.hStdOutput)
      if poStdErrToStdOut notin options:
        fileClose(si.hStdError)

    if e != nil: dealloc(e)
    dealloc(cmdl)
    if success == 0: osError(lastError)
    # Close the handle now so anyone waiting is woken:
    discard closeHandle(procInfo.hThread)
    result.FProcessHandle = procInfo.hProcess
    result.id = procInfo.dwProcessID

  proc close(p: PProcess) =
    when false:
      # somehow this does not work on Windows:
      discard CloseHandle(p.inHandle)
      discard CloseHandle(p.outHandle)
      discard CloseHandle(p.errHandle)
      discard CloseHandle(p.FProcessHandle)

  proc suspend(p: PProcess) =
    discard suspendThread(p.FProcessHandle)

  proc resume(p: PProcess) =
    discard resumeThread(p.FProcessHandle)

  proc running(p: PProcess): bool =
    var x = waitForSingleObject(p.FProcessHandle, 50)
    return x == WAIT_TIMEOUT

  proc terminate(p: PProcess) =
    if running(p):
      discard terminateProcess(p.FProcessHandle, 0)

  proc waitForExit(p: PProcess, timeout: int = -1): int =
    discard waitForSingleObject(p.FProcessHandle, timeout.int32)

    var res: int32
    discard getExitCodeProcess(p.FProcessHandle, res)
    result = res
    discard closeHandle(p.FProcessHandle)

  proc peekExitCode(p: PProcess): int =
    var b = waitForSingleObject(p.FProcessHandle, 50) == WAIT_TIMEOUT
    if b: result = -1
    else: 
      var res: int32
      discard getExitCodeProcess(p.FProcessHandle, res)
      return res

  proc inputStream(p: PProcess): PStream =
    result = newFileHandleStream(p.inHandle)

  proc outputStream(p: PProcess): PStream =
    result = newFileHandleStream(p.outHandle)

  proc errorStream(p: PProcess): PStream =
    result = newFileHandleStream(p.errHandle)

  proc execCmd(command: string): int =
    var
      si: TSTARTUPINFO
      procInfo: TPROCESS_INFORMATION
      process: THandle
      L: int32
    si.cb = sizeof(si).cint
    si.hStdError = getStdHandle(STD_ERROR_HANDLE)
    si.hStdInput = getStdHandle(STD_INPUT_HANDLE)
    si.hStdOutput = getStdHandle(STD_OUTPUT_HANDLE)
    when useWinUnicode:
      var c = newWideCString(command)
      var res = winlean.CreateProcessW(nil, c, nil, nil, 0,
        NORMAL_PRIORITY_CLASS, nil, nil, si, procInfo)
    else:
      var res = winlean.CreateProcessA(nil, command, nil, nil, 0,
        NORMAL_PRIORITY_CLASS, nil, nil, SI, ProcInfo)
    if res == 0:
      osError(osLastError())
    else:
      process = procInfo.hProcess
      discard closeHandle(procInfo.hThread)
      if waitForSingleObject(process, INFINITE) != -1:
        discard getExitCodeProcess(process, L)
        result = int(L)
      else:
        result = -1
      discard closeHandle(process)

  proc select(readfds: var seq[PProcess], timeout = 500): int = 
    assert readfds.len <= MAXIMUM_WAIT_OBJECTS
    var rfds: TWOHandleArray
    for i in 0..readfds.len()-1:
      rfds[i] = readfds[i].FProcessHandle
    
    var ret = waitForMultipleObjects(readfds.len.int32, 
                                     addr(rfds), 0'i32, timeout.int32)
    case ret
    of WAIT_TIMEOUT:
      return 0
    of WAIT_FAILED:
      osError(osLastError())
    else:
      var i = ret - WAIT_OBJECT_0
      readfds.del(i)
      return 1

elif not defined(useNimRtl):
  const
    readIdx = 0
    writeIdx = 1

  proc addCmdArgs(command: string, args: openarray[string]): string =
    result = quoteShell(command)
    for i in 0 .. high(args):
      add(result, " ")
      add(result, quoteShell(args[i]))

  proc toCStringArray(b, a: openarray[string]): cstringArray =
    result = cast[cstringArray](alloc0((a.len + b.len + 1) * sizeof(cstring)))
    for i in 0..high(b):
      result[i] = cast[cstring](alloc(b[i].len+1))
      copyMem(result[i], cstring(b[i]), b[i].len+1)
    for i in 0..high(a):
      result[i+b.len] = cast[cstring](alloc(a[i].len+1))
      copyMem(result[i+b.len], cstring(a[i]), a[i].len+1)

  proc ToCStringArray(t: PStringTable): cstringArray =
    result = cast[cstringArray](alloc0((t.len + 1) * sizeof(cstring)))
    var i = 0
    for key, val in pairs(t):
      var x = key & "=" & val
      result[i] = cast[cstring](alloc(x.len+1))
      copyMem(result[i], addr(x[0]), x.len+1)
      inc(i)

  proc EnvToCStringArray(): cstringArray =
    var counter = 0
    for key, val in envPairs(): inc counter
    result = cast[cstringArray](alloc0((counter + 1) * sizeof(cstring)))
    var i = 0
    for key, val in envPairs():
      var x = key.string & "=" & val.string
      result[i] = cast[cstring](alloc(x.len+1))
      copyMem(result[i], addr(x[0]), x.len+1)
      inc(i)
    
  proc startProcess(command: string,
                 workingDir: string = "",
                 args: openarray[string] = [],
                 env: PStringTable = nil,
                 options: set[TProcessOption] = {poStdErrToStdOut}): PProcess =
    var
      p_stdin, p_stdout, p_stderr: array [0..1, cint]
    new(result)
    result.exitCode = -3 # for ``waitForExit``
    if poParentStreams notin options:
      if pipe(p_stdin) != 0'i32 or pipe(p_stdout) != 0'i32 or
         pipe(p_stderr) != 0'i32:
        osError(osLastError())
    
    var pid: TPid
    when defined(posix_spawn) and not defined(useFork):
      var attr: Tposix_spawnattr
      var fops: Tposix_spawn_file_actions

      template chck(e: expr) = 
        if e != 0'i32: osError(osLastError())

      chck posix_spawn_file_actions_init(fops)
      chck posix_spawnattr_init(attr)
      
      var mask: Tsigset
      chck sigemptyset(mask)
      chck posix_spawnattr_setsigmask(attr, mask)
      chck posix_spawnattr_setpgroup(attr, 0'i32)
      
      chck posix_spawnattr_setflags(attr, POSIX_SPAWN_USEVFORK or
                                          POSIX_SPAWN_SETSIGMASK or
                                          POSIX_SPAWN_SETPGROUP)

      if poParentStreams notin options:
        chck posix_spawn_file_actions_addclose(fops, p_stdin[writeIdx])
        chck posix_spawn_file_actions_adddup2(fops, p_stdin[readIdx], readIdx)
        chck posix_spawn_file_actions_addclose(fops, p_stdout[readIdx])
        chck posix_spawn_file_actions_adddup2(fops, p_stdout[writeIdx], writeIdx)
        chck posix_spawn_file_actions_addclose(fops, p_stderr[readIdx])
        if poStdErrToStdOut in options:
          chck posix_spawn_file_actions_adddup2(fops, p_stdout[writeIdx], 2)
        else:
          chck posix_spawn_file_actions_adddup2(fops, p_stderr[writeIdx], 2)
      
      var e = if env == nil: EnvToCStringArray() else: ToCStringArray(env)
      var a: cstringArray
      var res: cint
      if workingDir.len > 0: os.setCurrentDir(workingDir)
      if poUseShell notin options:
        a = toCStringArray([extractFilename(command)], args)
        res = posix_spawn(pid, command, fops, attr, a, e)
      else:
        var x = addCmdArgs(command, args)
        a = toCStringArray(["sh", "-c"], [x])
        res = posix_spawn(pid, "/bin/sh", fops, attr, a, e)
      deallocCStringArray(a)
      deallocCStringArray(e)
      discard posix_spawn_file_actions_destroy(fops)
      discard posix_spawnattr_destroy(attr)
      chck res

    else:
    
      Pid = fork()
      if Pid < 0: osError(osLastError())
      if pid == 0:
        ## child process:

        if poParentStreams notin options:
          discard close(p_stdin[writeIdx])
          if dup2(p_stdin[readIdx], readIdx) < 0: osError(osLastError())
          discard close(p_stdout[readIdx])
          if dup2(p_stdout[writeIdx], writeIdx) < 0: osError(osLastError())
          discard close(p_stderr[readIdx])
          if poStdErrToStdOut in options:
            if dup2(p_stdout[writeIdx], 2) < 0: osError(osLastError())
          else:
            if dup2(p_stderr[writeIdx], 2) < 0: osError(osLastError())

        # Create a new process group
        if setpgid(0, 0) == -1: quit("setpgid call failed: " & $strerror(errno))

        if workingDir.len > 0: os.setCurrentDir(workingDir)
        if poUseShell notin options:
          var a = toCStringArray([extractFilename(command)], args)
          if env == nil:
            discard execv(command, a)
          else:
            discard execve(command, a, ToCStringArray(env))
        else:
          var x = addCmdArgs(command, args)
          var a = toCStringArray(["sh", "-c"], [x])
          if env == nil:
            discard execv("/bin/sh", a)
          else:
            discard execve("/bin/sh", a, ToCStringArray(env))
        # too risky to raise an exception here:
        quit("execve call failed: " & $strerror(errno))
    # Parent process. Copy process information.
    if poEchoCmd in options:
      echo(command, " ", join(args, " "))
    result.id = pid

    if poParentStreams in options:
      # does not make much sense, but better than nothing:
      result.inHandle = 0
      result.outHandle = 1
      if poStdErrToStdOut in options:
        result.errHandle = result.outHandle
      else:
        result.errHandle = 2
    else:
      result.inHandle = p_stdin[writeIdx]
      result.outHandle = p_stdout[readIdx]
      if poStdErrToStdOut in options:
        result.errHandle = result.outHandle
        discard close(p_stderr[readIdx])
      else:
        result.errHandle = p_stderr[readIdx]
      discard close(p_stderr[writeIdx])
      discard close(p_stdin[readIdx])
      discard close(p_stdout[writeIdx])

  proc close(p: PProcess) =
    if p.inStream != nil: close(p.inStream)
    if p.outStream != nil: close(p.outStream)
    if p.errStream != nil: close(p.errStream)
    discard close(p.inHandle)
    discard close(p.outHandle)
    discard close(p.errHandle)

  proc suspend(p: PProcess) =
    if kill(-p.id, SIGSTOP) != 0'i32: osError(osLastError())

  proc resume(p: PProcess) =
    if kill(-p.id, SIGCONT) != 0'i32: osError(osLastError())

  proc running(p: PProcess): bool =
    var ret = waitPid(p.id, p.exitCode, WNOHANG)
    if ret == 0: return true # Can't establish status. Assume running.
    result = ret == int(p.id)

  proc terminate(p: PProcess) =
    if kill(-p.id, SIGTERM) == 0'i32:
      if p.running():
        if kill(-p.id, SIGKILL) != 0'i32: osError(osLastError())
    else: osError(osLastError())

  proc waitForExit(p: PProcess, timeout: int = -1): int =
    #if waitPid(p.id, p.exitCode, 0) == int(p.id):
    # ``waitPid`` fails if the process is not running anymore. But then
    # ``running`` probably set ``p.exitCode`` for us. Since ``p.exitCode`` is
    # initialized with -3, wrong success exit codes are prevented.
    if p.exitCode != -3: return p.exitCode
    if waitPid(p.id, p.exitCode, 0) < 0:
      p.exitCode = -3
      osError(osLastError())
    result = int(p.exitCode) shr 8

  proc peekExitCode(p: PProcess): int =
    if p.exitCode != -3: return p.exitCode
    var ret = waitPid(p.id, p.exitCode, WNOHANG)
    var b = ret == int(p.id)
    if b: result = -1
    if p.exitCode == -3: result = -1
    else: result = p.exitCode.int shr 8

  proc createStream(stream: var PStream, handle: var TFileHandle,
                    fileMode: TFileMode) =
    var f: TFile
    if not open(f, handle, fileMode): osError(osLastError())
    stream = newFileStream(f)

  proc inputStream(p: PProcess): PStream =
    if p.inStream == nil:
      createStream(p.inStream, p.inHandle, fmWrite)
    return p.inStream

  proc outputStream(p: PProcess): PStream =
    if p.outStream == nil:
      createStream(p.outStream, p.outHandle, fmRead)
    return p.outStream

  proc errorStream(p: PProcess): PStream =
    if p.errStream == nil:
      createStream(p.errStream, p.errHandle, fmRead)
    return p.errStream

  proc csystem(cmd: cstring): cint {.nodecl, importc: "system".}

  proc execCmd(command: string): int =
    result = csystem(command)

  proc createFdSet(fd: var TFdSet, s: seq[PProcess], m: var int) = 
    FD_ZERO(fd)
    for i in items(s): 
      m = max(m, int(i.outHandle))
      FD_SET(cint(i.outHandle), fd)
     
  proc pruneProcessSet(s: var seq[PProcess], fd: var TFdSet) = 
    var i = 0
    var L = s.len
    while i < L:
      if FD_ISSET(cint(s[i].outHandle), fd) != 0'i32:
        s[i] = s[L-1]
        dec(L)
      else:
        inc(i)
    setLen(s, L)

  proc select(readfds: var seq[PProcess], timeout = 500): int = 
    var tv: TTimeVal
    tv.tv_sec = 0
    tv.tv_usec = timeout * 1000
    
    var rd: TFdSet
    var m = 0
    createFdSet((rd), readfds, m)
    
    if timeout != -1:
      result = int(select(cint(m+1), addr(rd), nil, nil, addr(tv)))
    else:
      result = int(select(cint(m+1), addr(rd), nil, nil, nil))
    
    pruneProcessSet(readfds, (rd))


proc execCmdEx*(command: string, options: set[TProcessOption] = {
                poStdErrToStdOut, poUseShell}): tuple[
                output: TaintedString, 
                exitCode: int] {.tags: [FExecIO, FReadIO].} =
  ## a convenience proc that runs the `command`, grabs all its output and
  ## exit code and returns both.
  var p = startCmd(command, options)
  var outp = outputStream(p)
  result = (TaintedString"", -1)
  var line = newStringOfCap(120).TaintedString
  while true:
    if outp.readLine(line):
      result[0].string.add(line.string)
      result[0].string.add("\n")
    else:
      result[1] = peekExitCode(p)
      if result[1] != -1: break
  close(p)

when isMainModule:
  assert quoteShellWindows("aaa") == "aaa"
  assert quoteShellWindows("aaa\"") == "aaa\\\""
  assert quoteShellWindows("") == "\"\""

  assert quoteShellPosix("aaa") == "aaa"
  assert quoteShellPosix("aaa a") == "'aaa a'"
  assert quoteShellPosix("") == "''"
  assert quoteShellPosix("a'a") == "'a'\"'\"'a'"

  when defined(posix):
    assert quoteShell("") == "''"
