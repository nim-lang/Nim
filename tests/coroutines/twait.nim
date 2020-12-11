discard """
  output: "Exit 1\nExit 2"
  target: "c"
"""
import coro

var coro1: CoroutineRef

proc testCoroutine1() =
  for i in 0..<10:
    suspend(0)
  echo "Exit 1"

proc testCoroutine2() =
  coro1.wait()
  echo "Exit 2"

coro1 = coro.start(testCoroutine1)
coro.start(testCoroutine2)
run()
