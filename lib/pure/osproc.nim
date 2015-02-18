#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements an advanced facility for executing OS processes
## and process communication.

include "system/inclrtl"

import
  strutils, os, strtabs, streams, cpuinfo

when defined(windows):
  import winlean
else:
  import posix

when defined(linux):
  import linux

type
  ProcessObj = object of RootObj
    when defined(windows):
      fProcessHandle: THandle
      inHandle, outHandle, errHandle: FileHandle
      id: THandle
    else:
      inHandle, outHandle, errHandle: FileHandle
      inStream, outStream, errStream: Stream
      id: TPid
    exitCode: cint

  Process* = ref ProcessObj ## represents an operating system process

  ProcessOption* = enum ## options that can be passed `startProcess`
    poEchoCmd,           ## echo the command before execution
    poUsePath,           ## Asks system to search for executable using PATH environment
                         ## variable.
                         ## On Windows, this is the default.
    poEvalCommand,       ## Pass `command` directly to the shell, without quoting.
                         ## Use it only if `command` comes from trused source.
    poStdErrToStdOut,    ## merge stdout and stderr to the stdout stream
    poParentStreams      ## use the parent's streams

{.deprecated: [TProcess: ProcessObj, PProcess: Process,
  TProcessOption: ProcessOption].}

const poUseShell* {.deprecated.} = poUsePath
  ## Deprecated alias for poUsePath.

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
                  args: openArray[string] = [],
                  env: StringTableRef = nil,
                  options: set[ProcessOption] = {poStdErrToStdOut,
                                                  poUsePath,
                                                  poEvalCommand}): TaintedString {.
                                                  rtl, extern: "nosp$1",
                                                  tags: [ExecIOEffect, ReadIOEffect].}
  ## A convenience procedure that executes ``command`` with ``startProcess``
  ## and returns its output as a string.
  ## WARNING: this function uses poEvalCommand by default for backward compatibility.
  ## Make sure to pass options explicitly.

proc execCmd*(command: string): int {.rtl, extern: "nosp$1", tags: [ExecIOEffect].}
  ## Executes ``command`` and returns its error code. Standard input, output,
  ## error streams are inherited from the calling process. This operation
  ## is also often called `system`:idx:.

proc startProcess*(command: string,
                   workingDir: string = "",
                   args: openArray[string] = [],
                   env: StringTableRef = nil,
                   options: set[ProcessOption] = {poStdErrToStdOut}):
              Process {.rtl, extern: "nosp$1", tags: [ExecIOEffect, ReadEnvEffect].}
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
  ## Note that you can't pass any `args` if you use the option
  ## ``poEvalCommand``, which invokes the system shell to run the specified
  ## `command`. In this situation you have to concatenate manually the contents
  ## of `args` to `command` carefully escaping/quoting any special characters,
  ## since it will be passed *as is* to the system shell. Each system/shell may
  ## feature different escaping rules, so try to avoid this kind of shell
  ## invocation if possible as it leads to non portable software.
  ##
  ## Return value: The newly created process object. Nil is never returned,
  ## but ``EOS`` is raised in case of an error.

proc startCmd*(command: string, options: set[ProcessOption] = {
               poStdErrToStdOut, poUsePath}): Process {.
               tags: [ExecIOEffect, ReadEnvEffect], deprecated.} =
  ## Deprecated - use `startProcess` directly.
  result = startProcess(command=command, options=options + {poEvalCommand})

proc close*(p: Process) {.rtl, extern: "nosp$1", tags: [].}
  ## When the process has finished executing, cleanup related handles

proc suspend*(p: Process) {.rtl, extern: "nosp$1", tags: [].}
  ## Suspends the process `p`.

proc resume*(p: Process) {.rtl, extern: "nosp$1", tags: [].}
  ## Resumes the process `p`.

proc terminate*(p: Process) {.rtl, extern: "nosp$1", tags: [].}
  ## Stop the process `p`. On Posix OSes the procedure sends ``SIGTERM``
  ## to the process. On Windows the Win32 API function ``TerminateProcess()``
  ## is called to stop the process.

proc kill*(p: Process) {.rtl, extern: "nosp$1", tags: [].}
  ## Kill the process `p`. On Posix OSes the procedure sends ``SIGKILL`` to
  ## the process. On Windows ``kill()`` is simply an alias for ``terminate()``.
  
proc running*(p: Process): bool {.rtl, extern: "nosp$1", tags: [].}
  ## Returns true iff the process `p` is still running. Returns immediately.

proc processID*(p: Process): int {.rtl, extern: "nosp$1".} =
  ## returns `p`'s process ID.
  return p.id

proc waitForExit*(p: Process, timeout: int = -1): int {.rtl,
  extern: "nosp$1", tags: [].}
  ## waits for the process to finish and returns `p`'s error code.
  ##
  ## **Warning**: Be careful when using waitForExit for processes created without
  ## poParentStreams because they may fill output buffers, causing deadlock.

proc peekExitCode*(p: Process): int {.tags: [].}
  ## return -1 if the process is still running. Otherwise the process' exit code

proc inputStream*(p: Process): Stream {.rtl, extern: "nosp$1", tags: [].}
  ## returns ``p``'s input stream for writing to.
  ##
  ## **Warning**: The returned `PStream` should not be closed manually as it
  ## is closed when closing the PProcess ``p``.

proc outputStream*(p: Process): Stream {.rtl, extern: "nosp$1", tags: [].}
  ## returns ``p``'s output stream for reading from.
  ##
  ## **Warning**: The returned `PStream` should not be closed manually as it
  ## is closed when closing the PProcess ``p``.

proc errorStream*(p: Process): Stream {.rtl, extern: "nosp$1", tags: [].}
  ## returns ``p``'s error stream for reading from.
  ##
  ## **Warning**: The returned `PStream` should not be closed manually as it
  ## is closed when closing the PProcess ``p``.

proc inputHandle*(p: Process): FileHandle {.rtl, extern: "nosp$1",
  tags: [].} =
  ## returns ``p``'s input file handle for writing to.
  ##
  ## **Warning**: The returned `TFileHandle` should not be closed manually as
  ## it is closed when closing the PProcess ``p``.
  result = p.inHandle

proc outputHandle*(p: Process): FileHandle {.rtl, extern: "nosp$1",
  tags: [].} =
  ## returns ``p``'s output file handle for reading from.
  ##
  ## **Warning**: The returned `TFileHandle` should not be closed manually as
  ## it is closed when closing the PProcess ``p``.
  result = p.outHandle

proc errorHandle*(p: Process): FileHandle {.rtl, extern: "nosp$1",
  tags: [].} =
  ## returns ``p``'s error file handle for reading from.
  ##
  ## **Warning**: The returned `TFileHandle` should not be closed manually as
  ## it is closed when closing the PProcess ``p``.
  result = p.errHandle

proc countProcessors*(): int {.rtl, extern: "nosp$1".} =
  ## returns the numer of the processors/cores the machine has.
  ## Returns 0 if it cannot be detected.
  result = cpuinfo.countProcessors()

proc execProcesses*(cmds: openArray[string],
                    options = {poStdErrToStdOut, poParentStreams},
                    n = countProcessors(),
                    beforeRunEvent: proc(idx: int) = nil): int
                    {.rtl, extern: "nosp$1",
                    tags: [ExecIOEffect, TimeEffect, ReadEnvEffect, RootEffect]} =
  ## executes the commands `cmds` in parallel. Creates `n` processes
  ## that execute in parallel. The highest return value of all processes
  ## is returned. Runs `beforeRunEvent` before running each command.
  when defined(posix):
    # poParentStreams causes problems on Posix, so we simply disable it:
    var options = options - {poParentStreams}

  assert n > 0
  if n > 1:
    var q: seq[Process]
    newSeq(q, n)
    var m = min(n, cmds.len)
    for i in 0..m-1:
      if beforeRunEvent != nil:
        beforeRunEvent(i)
      q[i] = startProcess(cmds[i], options=options + {poEvalCommand})
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
        if beforeRunEvent != nil:
          beforeRunEvent(i)
        q[r] = startProcess(cmds[i], options=options + {poEvalCommand})
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
            if beforeRunEvent != nil:
              beforeRunEvent(i)
            q[r] = startProcess(cmds[i], options=options + {poEvalCommand})
            inc(i)
            if i > high(cmds): break
    for j in 0..m-1:
      result = max(waitForExit(q[j]), result)
      if q[j] != nil: close(q[j])
  else:
    for i in 0..high(cmds):
      if beforeRunEvent != nil:
        beforeRunEvent(i)
      var p = startProcess(cmds[i], options=options + {poEvalCommand})
      result = max(waitForExit(p), result)
      close(p)

proc select*(readfds: var seq[Process], timeout = 500): int
  ## `select` with a sensible Nim interface. `timeout` is in miliseconds.
  ## Specify -1 for no timeout. Returns the number of processes that are
  ## ready to read from. The processes that are ready to be read from are
  ## removed from `readfds`.
  ##
  ## **Warning**: This function may give unexpected or completely wrong
  ## results on Windows.

when not defined(useNimRtl):
  proc execProcess(command: string,
                   args: openArray[string] = [],
                   env: StringTableRef = nil,
                   options: set[ProcessOption] = {poStdErrToStdOut,
                                                   poUsePath,
                                                   poEvalCommand}): TaintedString =
    var p = startProcess(command, args=args, env=env, options=options)
    var outp = outputStream(p)
    result = TaintedString""
    var line = newStringOfCap(120).TaintedString
    while true:
      # FIXME: converts CR-LF to LF.
      if outp.readLine(line):
        result.string.add(line.string)
        result.string.add("\n")
      elif not running(p): break
    close(p)


when defined(Windows) and not defined(useNimRtl):
  # We need to implement a handle stream for Windows:
  type
    PFileHandleStream = ref TFileHandleStream
    TFileHandleStream = object of StreamObj
      handle: THandle
      atTheEnd: bool

  proc hsClose(s: Stream) = discard # nothing to do here
  proc hsAtEnd(s: Stream): bool = return PFileHandleStream(s).atTheEnd

  proc hsReadData(s: Stream, buffer: pointer, bufLen: int): int =
    var s = PFileHandleStream(s)
    if s.atTheEnd: return 0
    var br: int32
    var a = winlean.readFile(s.handle, buffer, bufLen.cint, addr br, nil)
    # TRUE and zero bytes returned (EOF).
    # TRUE and n (>0) bytes returned (good data).
    # FALSE and bytes returned undefined (system error).
    if a == 0 and br != 0: raiseOSError(osLastError())
    s.atTheEnd = br < bufLen
    result = br

  proc hsWriteData(s: Stream, buffer: pointer, bufLen: int) =
    var s = PFileHandleStream(s)
    var bytesWritten: int32
    var a = winlean.writeFile(s.handle, buffer, bufLen.cint,
                              addr bytesWritten, nil)
    if a == 0: raiseOSError(osLastError())

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

  proc buildEnv(env: StringTableRef): cstring =
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

  proc createPipeHandles(rdHandle, wrHandle: var THandle) =
    var piInheritablePipe: TSECURITY_ATTRIBUTES
    piInheritablePipe.nLength = sizeof(TSECURITY_ATTRIBUTES).cint
    piInheritablePipe.lpSecurityDescriptor = nil
    piInheritablePipe.bInheritHandle = 1
    if createPipe(rdHandle, wrHandle, piInheritablePipe, 1024) == 0'i32:
      raiseOSError(osLastError())

  proc fileClose(h: THandle) {.inline.} =
    if h > 4: discard closeHandle(h)

  proc startProcess(command: string,
                 workingDir: string = "",
                 args: openArray[string] = [],
                 env: StringTableRef = nil,
                 options: set[ProcessOption] = {poStdErrToStdOut}): Process =
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
      result.inHandle = FileHandle(hi)
      result.outHandle = FileHandle(ho)
      result.errHandle = FileHandle(he)
    else:
      si.hStdError = getStdHandle(STD_ERROR_HANDLE)
      si.hStdInput = getStdHandle(STD_INPUT_HANDLE)
      si.hStdOutput = getStdHandle(STD_OUTPUT_HANDLE)
      result.inHandle = FileHandle(si.hStdInput)
      result.outHandle = FileHandle(si.hStdOutput)
      result.errHandle = FileHandle(si.hStdError)

    var cmdl: cstring
    if poEvalCommand in options:
      cmdl = command
      assert args.len == 0
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
      success = winlean.createProcessW(nil,
        tmp, nil, nil, 1, NORMAL_PRIORITY_CLASS or CREATE_UNICODE_ENVIRONMENT,
        ee, wwd, si, procInfo)
    else:
      success = winlean.createProcessA(nil,
        cmdl, nil, nil, 1, NORMAL_PRIORITY_CLASS, e, wd, si, procInfo)
    let lastError = osLastError()

    if poParentStreams notin options:
      fileClose(si.hStdInput)
      fileClose(si.hStdOutput)
      if poStdErrToStdOut notin options:
        fileClose(si.hStdError)

    if e != nil: dealloc(e)
    if success == 0: raiseOSError(lastError)
    # Close the handle now so anyone waiting is woken:
    discard closeHandle(procInfo.hThread)
    result.fProcessHandle = procInfo.hProcess
    result.id = procInfo.dwProcessId

  proc close(p: Process) =
    when false:
      # somehow this does not work on Windows:
      discard closeHandle(p.inHandle)
      discard closeHandle(p.outHandle)
      discard closeHandle(p.errHandle)
      discard closeHandle(p.FProcessHandle)

  proc suspend(p: Process) =
    discard suspendThread(p.fProcessHandle)

  proc resume(p: Process) =
    discard resumeThread(p.fProcessHandle)

  proc running(p: Process): bool =
    var x = waitForSingleObject(p.fProcessHandle, 50)
    return x == WAIT_TIMEOUT

  proc terminate(p: Process) =
    if running(p):
      discard terminateProcess(p.fProcessHandle, 0)

  proc kill(p: Process) =
    terminate(p)

  proc waitForExit(p: Process, timeout: int = -1): int =
    discard waitForSingleObject(p.fProcessHandle, timeout.int32)

    var res: int32
    discard getExitCodeProcess(p.fProcessHandle, res)
    result = res
    discard closeHandle(p.fProcessHandle)

  proc peekExitCode(p: Process): int =
    var b = waitForSingleObject(p.fProcessHandle, 50) == WAIT_TIMEOUT
    if b: result = -1
    else:
      var res: int32
      discard getExitCodeProcess(p.fProcessHandle, res)
      return res

  proc inputStream(p: Process): Stream =
    result = newFileHandleStream(p.inHandle)

  proc outputStream(p: Process): Stream =
    result = newFileHandleStream(p.outHandle)

  proc errorStream(p: Process): Stream =
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
      var res = winlean.createProcessW(nil, c, nil, nil, 0,
        NORMAL_PRIORITY_CLASS, nil, nil, si, procInfo)
    else:
      var res = winlean.createProcessA(nil, command, nil, nil, 0,
        NORMAL_PRIORITY_CLASS, nil, nil, si, procInfo)
    if res == 0:
      raiseOSError(osLastError())
    else:
      process = procInfo.hProcess
      discard closeHandle(procInfo.hThread)
      if waitForSingleObject(process, INFINITE) != -1:
        discard getExitCodeProcess(process, L)
        result = int(L)
      else:
        result = -1
      discard closeHandle(process)

  proc select(readfds: var seq[Process], timeout = 500): int =
    assert readfds.len <= MAXIMUM_WAIT_OBJECTS
    var rfds: TWOHandleArray
    for i in 0..readfds.len()-1:
      rfds[i] = readfds[i].fProcessHandle

    var ret = waitForMultipleObjects(readfds.len.int32,
                                     addr(rfds), 0'i32, timeout.int32)
    case ret
    of WAIT_TIMEOUT:
      return 0
    of WAIT_FAILED:
      raiseOSError(osLastError())
    else:
      var i = ret - WAIT_OBJECT_0
      readfds.del(i)
      return 1

elif not defined(useNimRtl):
  const
    readIdx = 0
    writeIdx = 1

  proc envToCStringArray(t: StringTableRef): cstringArray =
    result = cast[cstringArray](alloc0((t.len + 1) * sizeof(cstring)))
    var i = 0
    for key, val in pairs(t):
      var x = key & "=" & val
      result[i] = cast[cstring](alloc(x.len+1))
      copyMem(result[i], addr(x[0]), x.len+1)
      inc(i)

  proc envToCStringArray(): cstringArray =
    var counter = 0
    for key, val in envPairs(): inc counter
    result = cast[cstringArray](alloc0((counter + 1) * sizeof(cstring)))
    var i = 0
    for key, val in envPairs():
      var x = key.string & "=" & val.string
      result[i] = cast[cstring](alloc(x.len+1))
      copyMem(result[i], addr(x[0]), x.len+1)
      inc(i)

  type TStartProcessData = object
    sysCommand: cstring
    sysArgs: cstringArray
    sysEnv: cstringArray
    workingDir: cstring
    pStdin, pStdout, pStderr, pErrorPipe: array[0..1, cint]
    optionPoUsePath: bool
    optionPoParentStreams: bool
    optionPoStdErrToStdOut: bool

  when not defined(useFork):
    proc startProcessAuxSpawn(data: TStartProcessData): TPid {.
      tags: [ExecIOEffect, ReadEnvEffect], gcsafe.}
  proc startProcessAuxFork(data: TStartProcessData): TPid {.
    tags: [ExecIOEffect, ReadEnvEffect], gcsafe.}
  {.push stacktrace: off, profiler: off.}
  proc startProcessAfterFork(data: ptr TStartProcessData) {.
    tags: [ExecIOEffect, ReadEnvEffect], cdecl, gcsafe.}
  {.pop.}

  proc startProcess(command: string,
                 workingDir: string = "",
                 args: openArray[string] = [],
                 env: StringTableRef = nil,
                 options: set[ProcessOption] = {poStdErrToStdOut}): Process =
    var
      pStdin, pStdout, pStderr: array [0..1, cint]
    new(result)
    result.exitCode = -3 # for ``waitForExit``
    if poParentStreams notin options:
      if pipe(pStdin) != 0'i32 or pipe(pStdout) != 0'i32 or
         pipe(pStderr) != 0'i32:
        raiseOSError(osLastError())

    var sysCommand: string
    var sysArgsRaw: seq[string]
    if poEvalCommand in options:
      sysCommand = "/bin/sh"
      sysArgsRaw = @[sysCommand, "-c", command]
      assert args.len == 0, "`args` has to be empty when using poEvalCommand."
    else:
      sysCommand = command
      sysArgsRaw = @[command]
      for arg in args.items:
        sysArgsRaw.add arg

    var pid: TPid

    var sysArgs = allocCStringArray(sysArgsRaw)
    defer: deallocCStringArray(sysArgs)

    var sysEnv = if env == nil:
        envToCStringArray()
      else:
        envToCStringArray(env)

    defer: deallocCStringArray(sysEnv)

    var data: TStartProcessData
    data.sysCommand = sysCommand
    data.sysArgs = sysArgs
    data.sysEnv = sysEnv
    data.pStdin = pStdin
    data.pStdout = pStdout
    data.pStderr = pStderr
    data.optionPoParentStreams = poParentStreams in options
    data.optionPoUsePath = poUsePath in options
    data.optionPoStdErrToStdOut = poStdErrToStdOut in options
    data.workingDir = workingDir


    when declared(posix_spawn) and not defined(useFork) and 
        not defined(useClone) and not defined(linux):
      pid = startProcessAuxSpawn(data)
    else:
      pid = startProcessAuxFork(data)

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
      result.inHandle = pStdin[writeIdx]
      result.outHandle = pStdout[readIdx]
      if poStdErrToStdOut in options:
        result.errHandle = result.outHandle
        discard close(pStderr[readIdx])
      else:
        result.errHandle = pStderr[readIdx]
      discard close(pStderr[writeIdx])
      discard close(pStdin[readIdx])
      discard close(pStdout[writeIdx])

  when not defined(useFork):
    proc startProcessAuxSpawn(data: TStartProcessData): TPid =
      var attr: Tposix_spawnattr
      var fops: Tposix_spawn_file_actions

      template chck(e: expr) =
        if e != 0'i32: raiseOSError(osLastError())

      chck posix_spawn_file_actions_init(fops)
      chck posix_spawnattr_init(attr)

      var mask: Tsigset
      chck sigemptyset(mask)
      chck posix_spawnattr_setsigmask(attr, mask)
      chck posix_spawnattr_setpgroup(attr, 0'i32)

      chck posix_spawnattr_setflags(attr, POSIX_SPAWN_USEVFORK or
                                          POSIX_SPAWN_SETSIGMASK or
                                          POSIX_SPAWN_SETPGROUP)

      if not data.optionPoParentStreams:
        chck posix_spawn_file_actions_addclose(fops, data.pStdin[writeIdx])
        chck posix_spawn_file_actions_adddup2(fops, data.pStdin[readIdx], readIdx)
        chck posix_spawn_file_actions_addclose(fops, data.pStdout[readIdx])
        chck posix_spawn_file_actions_adddup2(fops, data.pStdout[writeIdx], writeIdx)
        chck posix_spawn_file_actions_addclose(fops, data.pStderr[readIdx])
        if data.optionPoStdErrToStdOut:
          chck posix_spawn_file_actions_adddup2(fops, data.pStdout[writeIdx], 2)
        else:
          chck posix_spawn_file_actions_adddup2(fops, data.pStderr[writeIdx], 2)

      var res: cint
      # FIXME: chdir is global to process
      if data.workingDir.len > 0:
        setCurrentDir($data.workingDir)
      var pid: TPid

      if data.optionPoUsePath:
        res = posix_spawnp(pid, data.sysCommand, fops, attr, data.sysArgs, data.sysEnv)
      else:
        res = posix_spawn(pid, data.sysCommand, fops, attr, data.sysArgs, data.sysEnv)

      discard posix_spawn_file_actions_destroy(fops)
      discard posix_spawnattr_destroy(attr)
      chck res
      return pid

  proc startProcessAuxFork(data: TStartProcessData): TPid =
    if pipe(data.pErrorPipe) != 0:
      raiseOSError(osLastError())

    defer:
      discard close(data.pErrorPipe[readIdx])

    var pid: TPid
    var dataCopy = data

    when defined(useClone):
      const stackSize = 65536
      let stackEnd = cast[clong](alloc(stackSize))
      let stack = cast[pointer](stackEnd + stackSize)
      let fn: pointer = startProcessAfterFork
      pid = clone(fn, stack,
                  cint(CLONE_VM or CLONE_VFORK or SIGCHLD),
                  pointer(addr dataCopy), nil, nil, nil)
      discard close(data.pErrorPipe[writeIdx])
      dealloc(stack)
    else:
      pid = fork()
      if pid == 0:
        startProcessAfterFork(addr(dataCopy))
        exitnow(1)

    discard close(data.pErrorPipe[writeIdx])
    if pid < 0: raiseOSError(osLastError())

    var error: cint
    let sizeRead = read(data.pErrorPipe[readIdx], addr error, sizeof(error))
    if sizeRead == sizeof(error):
      raiseOSError($strerror(error))

    return pid

  {.push stacktrace: off, profiler: off.}
  proc startProcessFail(data: ptr TStartProcessData) =
    var error: cint = errno
    discard write(data.pErrorPipe[writeIdx], addr error, sizeof(error))
    exitnow(1)

  when defined(macosx) or defined(freebsd):
    var environ {.importc.}: cstringArray

  proc startProcessAfterFork(data: ptr TStartProcessData) =
    # Warning: no GC here!
    # Or anything that touches global structures - all called nim procs
    # must be marked with stackTrace:off. Inspect C code after making changes.
    if not data.optionPoParentStreams:
      discard close(data.pStdin[writeIdx])
      if dup2(data.pStdin[readIdx], readIdx) < 0:
        startProcessFail(data)
      discard close(data.pStdout[readIdx])
      if dup2(data.pStdout[writeIdx], writeIdx) < 0:
        startProcessFail(data)
      discard close(data.pStderr[readIdx])
      if data.optionPoStdErrToStdOut:
        if dup2(data.pStdout[writeIdx], 2) < 0:
          startProcessFail(data)
      else:
        if dup2(data.pStderr[writeIdx], 2) < 0:
          startProcessFail(data)

    if data.workingDir.len > 0:
      if chdir(data.workingDir) < 0:
        startProcessFail(data)

    discard close(data.pErrorPipe[readIdx])
    discard fcntl(data.pErrorPipe[writeIdx], F_SETFD, FD_CLOEXEC)

    if data.optionPoUsePath:
      when defined(macosx) or defined(freebsd):
        # MacOSX doesn't have execvpe, so we need workaround.
        # On MacOSX we can arrive here only from fork, so this is safe:
        environ = data.sysEnv
        discard execvp(data.sysCommand, data.sysArgs)
      else:
        when defined(uClibc):
          # uClibc environment (OpenWrt included) doesn't have the full execvpe 
          discard execve(data.sysCommand, data.sysArgs, data.sysEnv)
        else:
          discard execvpe(data.sysCommand, data.sysArgs, data.sysEnv)
    else:
      discard execve(data.sysCommand, data.sysArgs, data.sysEnv)

    startProcessFail(data)
  {.pop}

  proc close(p: Process) =
    if p.inStream != nil: close(p.inStream)
    if p.outStream != nil: close(p.outStream)
    if p.errStream != nil: close(p.errStream)
    discard close(p.inHandle)
    discard close(p.outHandle)
    discard close(p.errHandle)

  proc suspend(p: Process) =
    if kill(p.id, SIGSTOP) != 0'i32: raiseOsError(osLastError())

  proc resume(p: Process) =
    if kill(p.id, SIGCONT) != 0'i32: raiseOsError(osLastError())

  proc running(p: Process): bool =
    var ret : int
    when not defined(freebsd):
      ret = waitpid(p.id, p.exitCode, WNOHANG)
    else:
      var status : cint = 1
      ret = waitpid(p.id, status, WNOHANG)
      if WIFEXITED(status):
        p.exitCode = status
    if ret == 0: return true # Can't establish status. Assume running.
    result = ret == int(p.id)

  proc terminate(p: Process) =
    if kill(p.id, SIGTERM) != 0'i32:
      raiseOsError(osLastError())

  proc kill(p: Process) =
    if kill(p.id, SIGKILL) != 0'i32: 
      raiseOsError(osLastError())
    
  proc waitForExit(p: Process, timeout: int = -1): int =
    #if waitPid(p.id, p.exitCode, 0) == int(p.id):
    # ``waitPid`` fails if the process is not running anymore. But then
    # ``running`` probably set ``p.exitCode`` for us. Since ``p.exitCode`` is
    # initialized with -3, wrong success exit codes are prevented.
    if p.exitCode != -3: return p.exitCode
    if waitpid(p.id, p.exitCode, 0) < 0:
      p.exitCode = -3
      raiseOSError(osLastError())
    result = int(p.exitCode) shr 8

  proc peekExitCode(p: Process): int =
    if p.exitCode != -3: return p.exitCode
    var ret = waitpid(p.id, p.exitCode, WNOHANG)
    var b = ret == int(p.id)
    if b: result = -1
    if p.exitCode == -3: result = -1
    else: result = p.exitCode.int shr 8

  proc createStream(stream: var Stream, handle: var FileHandle,
                    fileMode: FileMode) =
    var f: File
    if not open(f, handle, fileMode): raiseOSError(osLastError())
    stream = newFileStream(f)

  proc inputStream(p: Process): Stream =
    if p.inStream == nil:
      createStream(p.inStream, p.inHandle, fmWrite)
    return p.inStream

  proc outputStream(p: Process): Stream =
    if p.outStream == nil:
      createStream(p.outStream, p.outHandle, fmRead)
    return p.outStream

  proc errorStream(p: Process): Stream =
    if p.errStream == nil:
      createStream(p.errStream, p.errHandle, fmRead)
    return p.errStream

  proc csystem(cmd: cstring): cint {.nodecl, importc: "system", 
                                     header: "<stdlib.h>".}

  proc execCmd(command: string): int =
    when defined(linux):
      result = csystem(command) shr 8
    else:
      result = csystem(command)

  proc createFdSet(fd: var TFdSet, s: seq[Process], m: var int) =
    FD_ZERO(fd)
    for i in items(s):
      m = max(m, int(i.outHandle))
      FD_SET(cint(i.outHandle), fd)

  proc pruneProcessSet(s: var seq[Process], fd: var TFdSet) =
    var i = 0
    var L = s.len
    while i < L:
      if FD_ISSET(cint(s[i].outHandle), fd) == 0'i32:
        s[i] = s[L-1]
        dec(L)
      else:
        inc(i)
    setLen(s, L)

  proc select(readfds: var seq[Process], timeout = 500): int =
    var tv: Timeval
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


proc execCmdEx*(command: string, options: set[ProcessOption] = {
                poStdErrToStdOut, poUsePath}): tuple[
                output: TaintedString,
                exitCode: int] {.tags: [ExecIOEffect, ReadIOEffect], gcsafe.} =
  ## a convenience proc that runs the `command`, grabs all its output and
  ## exit code and returns both.
  var p = startProcess(command, options=options + {poEvalCommand})
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
