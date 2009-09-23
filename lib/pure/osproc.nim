#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements an advanced facility for executing OS processes
## and process communication.
## **On Windows this module does not work properly. Please help!**

import
  os, strtabs, streams

when defined(windows):
  import winlean

type
  TProcess = object of TObject
    when defined(windows):
      FProcessHandle: Thandle
      FThreadHandle: Thandle
      inputHandle, outputHandle, errorHandle: TFileHandle
    else:
      inputHandle, outputHandle, errorHandle: TFileHandle
    id: cint
    exitCode: cint

  PProcess* = ref TProcess ## represents an operating system process

  TProcessOption* = enum ## options that can be passed `startProcess`
    poNone,              ## none option
    poUseShell,          ## use the shell to execute the command; NOTE: This
                         ## often creates a security whole!
    poStdErrToStdOut     ## merge stdout and stderr to the stdout stream

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

proc execProcess(command: string,
                 options: set[TProcessOption] = {poStdErrToStdOut,
                                                 poUseShell}): string =
  var c = parseCmdLine(command)
  var a: seq[string] = @[] # slicing is not yet implemented :-(
  for i in 1 .. c.len-1: add(a, c[i])
  var p = startProcess(command=c[0], args=a, options=options)
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
  proc hsAtEnd(s: PFileHandleStream): bool = return true

  proc hsReadData(s: PFileHandleStream, buffer: pointer, bufLen: int): int =
    var br: int32
    var a = winlean.ReadFile(s.handle, buffer, bufLen, br, nil)
    if a == 0: OSError()
    result = br
    #atEnd = bytesRead < bufLen

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
    var L = a.len
    for i in 0..high(args): inc(L, args[i].len+1)
    result = cast[cstring](alloc0(L+1))
    copyMem(result, cstring(a), a.len)
    L = a.len
    for i in 0..high(args):
      result[L] = ' '
      inc(L)
      copyMem(addr(result[L]), cstring(args[i]), args[i].len)
      inc(L, args[i].len)

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

  proc CreatePipeHandles(Inhandle, OutHandle: var THandle) =
    var piInheritablePipe: TSecurityAttributes
    piInheritablePipe.nlength = SizeOF(TSecurityAttributes)
    piInheritablePipe.lpSecurityDescriptor = nil
    piInheritablePipe.Binherithandle = 1
    if CreatePipe(Inhandle, Outhandle, piInheritablePipe, 0) == 0'i32:
      OSError()

  proc startProcess*(command: string,
                 workingDir: string = "",
                 args: openarray[string] = [],
                 env: PStringTable = nil,
                 options: set[TProcessOption] = {poStdErrToStdOut}): PProcess =
    new(result)
    var
      SI: TStartupInfo
      ProcInfo: TProcessInformation
      success: int
      hi, ho, he: THandle
    SI.cb = SizeOf(SI)
    SI.dwFlags = STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES
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
    var cmdl: cstring
    if poUseShell in options:
      var comspec = getEnv("COMSPEC")
      var a: seq[string] = @[]
      add(a, "/c")
      add(a, command)
      add(a, args)
      cmdl = buildCommandLine(comspec, a)
    else:
      cmdl = buildCommandLine(command, args)
    var wd: cstring = nil
    if len(workingDir) > 0: wd = workingDir
    if env == nil:
      success = winlean.CreateProcess(nil,
        cmdl, nil, nil, 0, NORMAL_PRIORITY_CLASS, nil, wd, SI, ProcInfo)
    else:
      var e = buildEnv(env)
      success = winlean.CreateProcess(nil,
        cmdl, nil, nil, 0, NORMAL_PRIORITY_CLASS, e, wd, SI, ProcInfo)
      dealloc(e)
    dealloc(cmdl)
    if success == 0:
      OSError()
    # NEW:
    # Close the handles now so anyone waiting is woken.
    discard closeHandle(procInfo.hThread)
    result.FProcessHandle = procInfo.hProcess
    result.FThreadHandle = procInfo.hThread
    result.id = procInfo.dwProcessID

  proc suspend(p: PProcess) =
    discard SuspendThread(p.FThreadHandle)

  proc resume(p: PProcess) =
    discard ResumeThread(p.FThreadHandle)

  proc running(p: PProcess): bool =
    var x = waitForSingleObject(p.FProcessHandle, 50)
    return x == WAIT_TIMEOUT

  proc terminate(p: PProcess) =
    if running(p):
      discard TerminateProcess(p.FProcessHandle, 0)

  proc waitForExit(p: PProcess): int =
    #CloseHandle(p.FThreadHandle)
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
  import posix

  const
    readIdx = 0
    writeIdx = 1

  proc addCmdArgs(command: string, args: openarray[string]): string =
    result = command
    for i in 0 .. high(args):
      add(result, " ")
      add(result, args[i])

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

  proc startProcess*(command: string,
                 workingDir: string = "",
                 args: openarray[string] = [],
                 env: PStringTable = nil,
                 options: set[TProcessOption] = {poStdErrToStdOut}): PProcess =
    new(result)
    var
      p_stdin, p_stdout, p_stderr: array [0..1, cint]
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
    result = 1
    if waitPid(p.id, p.exitCode, 0) == int(p.id):
      result = p.exitCode

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
  echo execCmd("gcc -v")
