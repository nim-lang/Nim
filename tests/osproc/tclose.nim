discard """
  exitcode: 0
"""

when defined(linux):
  import osproc, os

  proc countFds(): int =
    result = 0
    for i in walkDir("/proc/self/fd"):
      result += 1

  let initCount = countFds()

  let p = osproc.startProcess("echo", options={poUsePath})
  assert countFds() == initCount + 3
  p.close
  assert countFds() == initCount

  let p1 = osproc.startProcess("echo", options={poUsePath})
  discard p1.inputStream
  assert countFds() == initCount + 3
  p.close
  assert countFds() == initCount
