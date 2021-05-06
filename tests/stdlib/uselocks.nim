import locks

type MyType* [T] = object
  lock: Lock

proc createMyType*[T]: MyType[T] =
  initLock(result.lock)

proc use* (m: var MyType): int =
  withLock m.lock:
    result = 3

block:
  # bug #14873
  var l: Lock
  doAssert $l == "()"

when true: # intentional
  # bug https://github.com/nim-lang/Nim/issues/14873#issuecomment-784241605
  type
    Test = object
      path: string # Removing this makes both cases work.
      lock: Lock
  # A: This is not fine.
  var a = Test()
  proc main(): void =
    # B: This is fine.
    var b = Test()
  main()
