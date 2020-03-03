discard """
  cmd: "nim $target --hints:on --threads:on $options $file"
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

proc `@||->`*[T](fn: proc(): T {.thread.},
                 callback: proc(val: T){.thread.}): Thread[ThreadFuncArgs[T]] =
  var thr: Thread[ThreadFuncArgs[T]]
  var args: ThreadFuncArgs[T]
  args.a = fn
  args.b = callback
  createThread(thr, handleThreadFunc, args)
  return thr

proc `||->`*[T](fn: proc(): T{.thread.}, callback: proc(val: T){.thread.}) =
  discard fn @||-> callback

when true:
  import os
  proc testFunc(): int {.thread.} =
    return 1
  proc callbackFunc(val: int) {.thread.} =
    echo($(val))

  var thr = (testFunc @||-> callbackFunc)
  echo("test")
  joinThread(thr)
  os.sleep(3000)
