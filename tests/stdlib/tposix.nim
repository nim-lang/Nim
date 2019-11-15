discard """
outputsub: ""
"""

# Test Posix interface

when not defined(windows):

  import posix, posix_utils

  var
    u: Utsname

  discard uname(u)

  writeLine(stdout, u.sysname)
  writeLine(stdout, u.nodename)
  writeLine(stdout, u.release)
  writeLine(stdout, u.machine)


  block:
    # lib/posix/posix_utils.nim
    let diskInfo = posix_utils.getDiskUsage(".")
    doAssert diskInfo is tuple
    doAssert diskInfo[0] is SomeInteger
    doAssert diskInfo[1] is SomeInteger
    doAssert diskInfo[2] is SomeInteger
