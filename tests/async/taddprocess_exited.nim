discard """
  output: "exit reported"
"""
# `addProcess` must report a child that ends before it is registered. Callers
# such as `waitForExit` check `waitpid(WNOHANG)` first, so the child can end
# between that check and the registration. On Linux the SIGCHLD of such a child
# was lost and the exit was never reported. kqueue raises ESRCH for such a
# child instead, which the callers handle, so this checks Linux only.
when defined(linux) and (defined(amd64) or defined(arm64) or defined(i386)):
  import std/[asyncdispatch, osproc, posix, times]

  proc syscall(n: clong): cint {.importc, varargs, header: "<unistd.h>".}

  proc hasPidfd(): bool =
    # the selector needs pidfd_open (Linux 5.3) for this; without it, it falls
    # back to the signalfd, which cannot see the exit
    let fd = syscall(clong(434), getpid(), cuint(0))
    result = fd != -1
    if result: discard posix.close(fd)

  if hasPidfd():
    let p = startProcess("true", options = {poUsePath})
    # let the child end, but do not reap it
    var info: SigInfo
    doAssert waitid(P_PID, Id(p.processID), info, WEXITED or WNOWAIT) == 0

    var reported = false
    addProcess(p.processID, proc (fd: AsyncFD): bool =
      reported = true
      true)
    let start = epochTime()
    while not reported and epochTime() - start < 10:
      poll(100)
    doAssert reported, "the exit was not reported within 10 s"
    doAssert p.waitForExit() == 0
    p.close()
echo "exit reported"
