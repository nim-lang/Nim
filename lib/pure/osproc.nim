#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements an advanced facility for executing OS processes
## and process communication.

import
  strutils, os, strtabs, streams

when defined(windows):
  import winlean
else:
  import posix

type
  TProcess = object of TObject
    when defined(windows):
      FProcessHandle: Thandle
      inputHandle, outputHandle, errorHandle: TFileHandle
    else:
      inputHandle, outputHandle, errorHandle: TFileHandle
    id: cint
    exitCode: cint

  PProcess* = ref TProcess ## represents an operating system process

  TProcessOption* = enum ## options that can be passed `startProcess`
    poEchoCmd,           ## echo the command before execution
    poUseShell,          ## use the shell to execute the command; NOTE: This
                         ## often creates a security hole!
    poStdErrToStdOut,    ## merge stdout and stderr to the stdout stream
    poParentStreams      ## use the parent's streams

proc execProcess*(command: string,
                  options: set[TProcessOption] = {poStdErrToStdOut,
                                                  poUseShell}): string
  ## A convience procedure that executes ``command`` with ``startProcess``
  ## and returns its output as a string.

proc executeProcess*(command: string,
                     options: set[TProcessOption] = {poStdErrToStdOut,
                                                     poUseShell}): string {.
                                                     deprecated.} =
  ## **Deprecated since version 0.8.2**: Use `execProcess` instead.
  result = execProcess(command, options)

proc execCmd*(command: string): int
  ## Executes ``command`` and returns its error code. Standard input, output,
  ## error streams are inherited from the calling process.

proc executeCommand*(command: string): int {.deprecated.} =
  ## **Deprecated since version 0.8.2**: Use `execCmd` instead.
  result = execCmd(command)


proc startProcess*(command: string,
                   workingDir: string = "",
                   args: openarray[string] = [],
                   env: PStringTable = nil,
                   options: set[TProcessOption] = {poStdErrToStdOut}): PProcess
  ## Starts a process. `Command` is the executable file, `workingDir` is the
  ## process's working directory. If ``workingDir == ""`` the current directory
  ## is used. `args` are the command line arguments that are passed to the
  ## process. On many operating systems, the first command line argument is the
  ## name of the executable. `args` should not contain this argument!
  ## `env` is the environment that will be passed to the process.
  ## If ``env == nil`` the environment is inherited of
  ## the parent process. `options` are additional flags that may be passed
  ## to `startProcess`. See the documentation of ``TProcessOption`` for the
  ## meaning of these flags.
  ##
  ## Return value: The newly created process object. Nil is never returned,
  ## but ``EOS`` is raised in case of an error.

proc suspend*(p: PProcess)
  ## Suspends the process `p`.

proc resume*(p: PProcess)
  ## Resumes the process `p`.

proc terminate*(p: PProcess)
  ## Terminates the process `p`.

proc running*(p: PProcess): bool
  ## Returns true iff the process `p` is still running. Returns immediately.

proc processID*(p: PProcess): int =
  ## returns `p`'s process ID.
  return p.id

proc waitForExit*(p: PProcess): int
  ## waits for the process to finish and returns `p`'s error code.

proc inputStream*(p: PProcess): PStream
  ## returns ``p``'s input stream for writing to

proc outputStream*(p: PProcess): PStream
  ## returns ``p``'s output stream for reading from

proc errorStream*(p: PProcess): PStream
  ## returns ``p``'s output stream for reading from

when defined(macosx) or defined(bsd):
  const
    CTL_HW = 6
    HW_AVAILCPU = 25
    HW_NCPU = 3
  proc sysctl(x: ptr array[0..3, cint], y: cint, z: pointer,
              a: var int, b: pointer, c: int): cint {.
             importc: "sysctl", header: "<sys/sysctl.h>".}

proc countProcessors*(): int =
  ## returns the numer of the processors/cores the machine has.
  ## Returns 0 if it cannot be detected.
  when defined(windows):
    var x = getenv("NUMBER_OF_PROCESSORS")
    if x.len > 0: result = parseInt(x)
  elif defined(macosx) or defined(bsd):
    var
      mib: array[0..3, cint]
      len, numCPU: int
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

proc startProcessAux(cmd: string, options: set[TProcessOption]): PProcess =
  var c = parseCmdLine(cmd)
  var a: seq[string] = @[] # slicing is not yet implemented :-(
  for i in 1 .. c.len-1: add(a, c[i])
  result = startProcess(command=c[0], args=a, options=options)

proc execProcesses*(cmds: openArray[string],
                    options = {poStdErrToStdOut, poParentStreams},
                    n = countProcessors()): int =
  ## executes the commands `cmds` in parallel. Creates `n` processes
  ## that execute in parallel. The highest return value of all processes
  ## is returned.
  assert n > 0
  if n > 1:
    var q: seq[PProcess]
    newSeq(q, n)
    var m = min(n, cmds.len)
    for i in 0..m-1:
      q[i] = startProcessAux(cmds[i], options=options)
    when defined(noBusyWaiting):
      var r = 0
      for i in m..high(cmds):
        when defined(debugExecProcesses):
          var err = ""
          var outp = outputStream(q[r])
          while running(q[r]) or not outp.atEnd(outp):
            err.add(outp.readLine())
            err.add("\n")
          echo(err)
        result = max(waitForExit(q[r]), result)
        q[r] = startProcessAux(cmds[i], options=options)
        r = (r + 1) mod n
    else:
      var i = m
      while i <= high(cmds):
        sleep(50)
        for r in 0..n-1:
          if not running(q[r]):
            #echo(outputStream(q[r]).readLine())
            result = max(waitForExit(q[r]), result)
            q[r] = startProcessAux(cmds[i], options=options)
            inc(i)
            if i > high(cmds): break
    for i in 0..m-1:
      result = max(waitForExit(q[i]), result)
  else:
    for i in 0..high(cmds):
      var p = startProcessAux(cmds[i], options=options)
      result = max(waitForExit(p), result)

when true:
  nil
else:
  proc startGUIProcess*(command: string,
                     workingDir: string = "",
                     args: openarray[string] = [],
                     env: PStringTable = nil,
                     x = -1,
                     y = -1,
                     width = -1,
                     height = -1): PProcess

proc execProcess(command: string,
                 options: set[TProcessOption] = {poStdErrToStdOut,
                                                 poUseShell}): string =
  var p = startProcessAux(command, options=options)
  var outp = outputStream(p)
  result = ""
  while running(p) or not outp.atEnd(outp):
    result.add(outp.readLine())
    result.add("\n")

when false:
  proc deallocCStringArray(a: cstringArray) =
    var i = 0
    while a[i] != nil:
      dealloc(a[i])
      inc(i)
    dealloc(a)

when defined(Windows):
  # We need to implement a handle stream for Windows:
  type
    PFileHandleStream = ref TFileHandleStream
    TFileHandleStream = object of TStream
      handle: THandle
      atTheEnd: bool

  proc hsClose(s: PFileHandleStream) = nil # nothing to do here
  proc hsAtEnd(s: PFileHandleStream): bool = return s.atTheEnd

  proc hsReadData(s: PFileHandleStream, buffer: pointer, bufLen: int): int =
    if s.atTheEnd: return 0
    var br: int32
    var a = winlean.ReadFile(s.handle, buffer, bufLen, br, nil)
    # TRUE and zero bytes returned (EOF).
    # TRUE and n (>0) bytes returned (good data).
    # FALSE and bytes returned undefined (system error).
    if a == 0 and br != 0: OSError()
    s.atTheEnd = br < bufLen
    result = br

  proc hsWriteData(s: PFileHandleStream, buffer: pointer, bufLen: int) =
    var bytesWritten: int32
    var a = winlean.writeFile(s.handle, buffer, bufLen, bytesWritten, nil)
    if a == 0: OSError()

  proc newFileHandleStream(handle: THandle): PFileHandleStream =
    new(result)
    result.handle = handle
    result.close = hsClose
    result.atEnd = hsAtEnd
    result.readData = hsReadData
    result.writeData = hsWriteData

  proc buildCommandLine(a: string, args: openarray[string]): cstring =
    var res = quoteIfContainsWhite(a)
    for i in 0..high(args):
      res.add(' ')
      res.add(quoteIfContainsWhite(args[i]))
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

  proc CreatePipeHandles(Rdhandle, WrHandle: var THandle) =
    var piInheritablePipe: TSecurityAttributes
    piInheritablePipe.nlength = SizeOF(TSecurityAttributes)
    piInheritablePipe.lpSecurityDescriptor = nil
    piInheritablePipe.Binherithandle = 1
    if CreatePipe(Rdhandle, Wrhandle, piInheritablePipe, 1024) == 0'i32:
      OSError()

  proc fileClose(h: THandle) {.inline.} =
    if h > 4: discard CloseHandle(h)

  proc startProcess(command: string,
                 workingDir: string = "",
                 args: openarray[string] = [],
                 env: PStringTable = nil,
                 options: set[TProcessOption] = {poStdErrToStdOut}): PProcess =
    var
      SI: TStartupInfo
      ProcInfo: TProcessInformation
      success: int
      hi, ho, he: THandle
    new(result)
    SI.cb = SizeOf(SI)
    if poParentStreams notin options:
      SI.dwFlags = STARTF_USESTDHANDLES # STARTF_USESHOWWINDOW or
      CreatePipeHandles(SI.hStdInput, HI)
      CreatePipeHandles(HO, Si.hStdOutput)
      if poStdErrToStdOut in options:
        SI.hStdError = SI.hStdOutput
        HE = HO
      else:
        CreatePipeHandles(HE, Si.hStdError)
      result.inputHandle = hi
      result.outputHandle = ho
      result.errorHandle = he
    else:
      SI.hStdError = GetStdHandle(STD_ERROR_HANDLE)
      SI.hStdInput = GetStdHandle(STD_INPUT_HANDLE)
      SI.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE)
      result.inputHandle = si.hStdInput
      result.outputHandle = si.hStdOutput
      result.errorHandle = si.hStdError

    var cmdl: cstring
    if false: # poUseShell in options:
      cmdl = buildCommandLine(getEnv("COMSPEC"), @["/c", command] & args)
    else:
      cmdl = buildCommandLine(command, args)
    var wd: cstring = nil
    var e: cstring = nil
    if len(workingDir) > 0: wd = workingDir
    if env != nil: e = buildEnv(env)
    if poEchoCmd in options: echo($cmdl)
    success = winlean.CreateProcess(nil,
      cmdl, nil, nil, 1, NORMAL_PRIORITY_CLASS, e, wd, SI, ProcInfo)

    if poParentStreams notin options:
      FileClose(si.hStdInput)
      FileClose(si.hStdOutput)
      if poStdErrToStdOut notin options:
        FileClose(si.hStdError)

    if e != nil: dealloc(e)
    dealloc(cmdl)
    if success == 0: OSError()
    # Close the handle now so anyone waiting is woken:
    discard closeHandle(procInfo.hThread)
    result.FProcessHandle = procInfo.hProcess
    result.id = procInfo.dwProcessID

  proc suspend(p: PProcess) =
    discard SuspendThread(p.FProcessHandle)

  proc resume(p: PProcess) =
    discard ResumeThread(p.FProcessHandle)

  proc running(p: PProcess): bool =
    var x = waitForSingleObject(p.FProcessHandle, 50)
    return x == WAIT_TIMEOUT

  proc terminate(p: PProcess) =
    if running(p):
      discard TerminateProcess(p.FProcessHandle, 0)

  proc waitForExit(p: PProcess): int =
    discard WaitForSingleObject(p.FProcessHandle, Infinite)
    var res: int32
    discard GetExitCodeProcess(p.FProcessHandle, res)
    result = res
    discard CloseHandle(p.FProcessHandle)

  proc inputStream(p: PProcess): PStream =
    result = newFileHandleStream(p.inputHandle)

  proc outputStream(p: PProcess): PStream =
    result = newFileHandleStream(p.outputHandle)

  proc errorStream(p: PProcess): PStream =
    result = newFileHandleStream(p.errorHandle)

  proc execCmd(command: string): int =
    var
      SI: TStartupInfo
      ProcInfo: TProcessInformation
      process: THandle
      L: int32
    SI.cb = SizeOf(SI)
    SI.hStdError = GetStdHandle(STD_ERROR_HANDLE)
    SI.hStdInput = GetStdHandle(STD_INPUT_HANDLE)
    SI.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE)
    if winlean.CreateProcess(nil, command, nil, nil, 0,
        NORMAL_PRIORITY_CLASS, nil, nil, SI, ProcInfo) == 0:
      OSError()
    else:
      Process = ProcInfo.hProcess
      discard CloseHandle(ProcInfo.hThread)
      if WaitForSingleObject(Process, INFINITE) != -1:
        discard GetExitCodeProcess(Process, L)
        result = int(L)
      else:
        result = -1
      discard CloseHandle(Process)

else:
  const
    readIdx = 0
    writeIdx = 1

  proc addCmdArgs(command: string, args: openarray[string]): string =
    result = quoteIfContainsWhite(command)
    for i in 0 .. high(args):
      add(result, " ")
      add(result, quoteIfContainsWhite(args[i]))

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

  proc startProcess(command: string,
                 workingDir: string = "",
                 args: openarray[string] = [],
                 env: PStringTable = nil,
                 options: set[TProcessOption] = {poStdErrToStdOut}): PProcess =
    var
      p_stdin, p_stdout, p_stderr: array [0..1, cint]
    new(result)
    result.exitCode = 3 # for ``waitForExit``
    if pipe(p_stdin) != 0'i32 or pipe(p_stdout) != 0'i32:
      OSError("failed to create a pipe")
    var Pid = fork()
    if Pid < 0:
      OSError("failed to fork process")

    if pid == 0:
      ## child process:
      discard close(p_stdin[writeIdx])
      if dup2(p_stdin[readIdx], readIdx) < 0: OSError()
      discard close(p_stdout[readIdx])
      if dup2(p_stdout[writeIdx], writeIdx) < 0: OSError()
      if poStdErrToStdOut in options:
        if dup2(p_stdout[writeIdx], 2) < 0: OSError()
      else:
        if pipe(p_stderr) != 0'i32: OSError("failed to create a pipe")
        discard close(p_stderr[readIdx])
        if dup2(p_stderr[writeIdx], 2) < 0: OSError()

      if workingDir.len > 0:
        os.setCurrentDir(workingDir)
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
      echo(command & " " & join(args, " "))
    result.id = pid

    result.inputHandle = p_stdin[writeIdx]
    result.outputHandle = p_stdout[readIdx]
    if poStdErrToStdOut in options:
      result.errorHandle = result.outputHandle
    else:
      result.errorHandle = p_stderr[readIdx]
      discard close(p_stderr[writeIdx])
    discard close(p_stdin[readIdx])
    discard close(p_stdout[writeIdx])

  proc suspend(p: PProcess) =
    discard kill(p.id, SIGSTOP)

  proc resume(p: PProcess) =
    discard kill(p.id, SIGCONT)

  proc running(p: PProcess): bool =
    result = waitPid(p.id, p.exitCode, WNOHANG) == int(p.id)

  proc terminate(p: PProcess) =
    if kill(p.id, SIGTERM) == 0'i32:
      if running(p): discard kill(p.id, SIGKILL)

  proc waitForExit(p: PProcess): int =
    #if waitPid(p.id, p.exitCode, 0) == int(p.id):
    # ``waitPid`` fails if the process is not running anymore. But then
    # ``running`` probably set ``p.exitCode`` for us. Since ``p.exitCode`` is
    # initialized with 3, wrong success exit codes are prevented.
    var oldExitCode = p.exitCode
    if waitPid(p.id, p.exitCode, 0) < 0:
      # failed, so restore old exitCode
      p.exitCode = oldExitCode
    result = int(p.exitCode)

  proc inputStream(p: PProcess): PStream =
    var f: TFile
    if not open(f, p.inputHandle, fmWrite): OSError()
    result = newFileStream(f)

  proc outputStream(p: PProcess): PStream =
    var f: TFile
    if not open(f, p.outputHandle, fmRead): OSError()
    result = newFileStream(f)

  proc errorStream(p: PProcess): PStream =
    var f: TFile
    if not open(f, p.errorHandle, fmRead): OSError()
    result = newFileStream(f)

  proc csystem(cmd: cstring): cint {.nodecl, importc: "system".}

  proc execCmd(command: string): int =
    result = csystem(command)

when isMainModule:
  var x = execProcess("gcc -v")
  echo "ECHO ", x
