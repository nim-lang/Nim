discard """
  output: "Exit 1\nExit 2"
  matrix: "--gc:refc; --gc:arc; --gc:orc"
  target: "c"
  disabled: "openbsd"
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
