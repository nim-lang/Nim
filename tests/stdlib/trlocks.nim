discard """
  action: "compile"
  cmd: "nim c --threads:on $file"
"""
import rlocks

var r: RLock
r.initRLock()
