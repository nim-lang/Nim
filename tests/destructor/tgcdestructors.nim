discard """
  cmd: '''nim c --gc:destructors $file'''
  output: '''1 1'''
"""

import allocators
include system / ansi_c

proc main =
  var s: seq[string] = @[]
  for i in 0..<80: s.add "foo"

main()

#echo s
let (a, d) = allocCounters()
cprintf("%ld %ld\n", a, d)
