discard """
  cmd: "nim c --gc:arc $file"
  action: "compile"
"""

# bug #13269

import posix
proc foo*() =
  var last = newSeq[Stat]()
  var next = last
  for i in 0..3:
    last = next
foo()
