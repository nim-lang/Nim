discard """
  output: "closed"
"""

when defined(windows):
  echo "closed"
else:
  import asyncdispatch, selectors, posix

  block:
    let disp = newDispatcher()
    let fd = getFd(getIoHandler(disp))
    disp.close()
    doAssert fcntl(fd.cint, F_GETFD) == -1

  block:
    let fd = getFd(getIoHandler(getGlobalDispatcher()))
    setGlobalDispatcher(nil)
    doAssert fcntl(fd.cint, F_GETFD) == -1

  echo "closed"
