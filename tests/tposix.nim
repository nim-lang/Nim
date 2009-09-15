# Test Posix interface

import posix

var
  u: Tutsname

discard uname(u)

writeln(stdout, u.sysname)
writeln(stdout, u.nodename)
writeln(stdout, u.release)
writeln(stdout, u.machine)
