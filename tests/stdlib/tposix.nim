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

  when defined(linux):
    block:
      # lib/posix/posix_utils.nim
      doAssert posix_utils.isSsd(diskLetter = 'a') is bool
