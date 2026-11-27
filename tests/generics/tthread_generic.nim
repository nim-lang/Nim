discard """
  matrix: "--mm:refc; --mm:orc"
  action: compile
"""

type
  ThreadFuncArgs[T] = object of RootObj
    a: proc(): T {.thread.}
    b: proc(val: T) {.thread.}

proc handleThreadFunc(arg: ThreadFuncArgs[int]){.thread.} =
  var fn = arg.a
  var callback = arg.b
  var output = fn()
  callback(output)

# A `Thread` cannot be moved, so the caller owns it and passes it by `var`.
proc startThreadFunc*[T](thr: var Thread[ThreadFuncArgs[T]],
                         fn: proc(): T {.thread.},
                         callback: proc(val: T){.thread.}) =
  var args: ThreadFuncArgs[T]
  args.a = fn
  args.b = callback
  createThread(thr, handleThreadFunc, args)

proc runThreadFunc*[T](fn: proc(): T{.thread.}, callback: proc(val: T){.thread.}) =
  var thr: Thread[ThreadFuncArgs[T]]
  startThreadFunc(thr, fn, callback)
  joinThread(thr)

when true:
  import os
  proc testFunc(): int {.thread.} =
    return 1
  proc callbackFunc(val: int) {.thread.} =
    echo($(val))

  var thr: Thread[ThreadFuncArgs[int]]
  startThreadFunc(thr, testFunc, callbackFunc)
  echo("test")
  joinThread(thr)
  os.sleep(3000)
