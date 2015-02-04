discard """
  cmd: "nim $target --hints:on --threads:on $options $file"
"""

type
  TThreadFuncArgs[T] = object of TObject
    a: proc(): T {.thread.}
    b: proc(val: T) {.thread.}

proc handleThreadFunc(arg: TThreadFuncArgs[int]){.thread.} =
  var fn = arg.a
  var callback = arg.b
  var output = fn()
  callback(output)

proc `@||->`*[T](fn: proc(): T {.thread.}, 
                 callback: proc(val: T){.thread.}): Thread[TThreadFuncArgs[T]] =
  var thr: Thread[TThreadFuncArgs[T]]
  var args: TThreadFuncArgs[T]
  args.a = fn
  args.b = callback
  createThread(thr, handleThreadFunc, args)
  return thr

proc `||->`*[T](fn: proc(): T{.thread.}, callback: proc(val: T){.thread.}) =
  discard fn @||-> callback

when isMainModule:
  import os
  proc testFunc(): int {.thread.} =
    return 1
  proc callbackFunc(val: int) {.thread.} =
    echo($(val))
   
  var thr = (testFunc @||-> callbackFunc)
  echo("test")
  joinThread(thr)
  os.sleep(3000)

