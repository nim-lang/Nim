#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import posix, strutils, os

proc getSystemVersion*(): string =
  ## retrieves the system name ("Linux", "Mac OS X") & the system version.
  ## The implementation uses ``posix.uname``.
  var info: TUtsname
  if uname(info) < 0'i32: OSError()
  case $info.sysname
  of "Linux":
    result = "Linux " & $info.release & " " & $info.machine
  of "Darwin":
    result = "Mac OS X "
    if "10" in $info.release:
      result.add("v10.6 Snow Leopard")
    elif "0" in $info.release:
      result.add("Server 1.0 Hera")
    elif "1.3" in $info.release:
      result.add("v10.0 Cheetah")
    elif "1.4" in $info.release:
      result.add("v10.1 Puma")
    elif "6" in $info.release:
      result.add("v10.2 Jaguar")
    elif "7" in $info.release:
      result.add("v10.3 Panther")
    elif "8" in $info.release:
      result.add("v10.4 Tiger")
    elif "9" in $info.release:
      result.add("v10.5 Leopard")
  else:
    result = $info.sysname & " " & $info.release
    
when isMainModule:
  echo(getSystemVersion())