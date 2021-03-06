discard """
  cmd: "nim $target --threads:on --gc:orc $options $file"
  output: "42"
"""

from std/threadpool import spawn, `^`, sync

proc doworkok(i: int) {.thread.} = echo i
spawn(doworkok(42)); sync() # this works when returning void!

proc doworkbad(i: int): int {.thread.} = i
doAssert ^spawn(doworkbad(42)) == 42
