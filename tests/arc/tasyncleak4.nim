discard """
  cmd: "nim c --gc:orc -d:useMalloc $file"
  output: '''ok'''
  valgrind: "leaks"
"""

# bug #15076
import asyncdispatch

var futures: seq[Future[void]]

for i in 1..20:
  futures.add sleepAsync 1
  futures.add sleepAsync 1

  futures.all.waitFor()
  futures.setLen 0

setGlobalDispatcher nil
GC_fullCollect()
echo "ok"
