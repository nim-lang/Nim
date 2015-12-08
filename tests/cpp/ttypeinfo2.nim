discard """
  file: "ttypeinfo2.nim"
  cmd: "nim cpp $file"
"""
# bug #2841
import typeinfo
var tt: Any
