discard """
  cmd: "nim $target $options --cpu:amd64 $file"
  disabled: "32bit"
"""

import strutils

static:
  #cpu is set to "i386" in tcpuamd64.nim.cfg, but --cpu:amd64 in command line should override it.
  doAssert cmpIgnoreCase(hostCPU, "amd64") == 0
