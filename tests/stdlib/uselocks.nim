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
  doAssert ($l).len > 0
    # on posix, "()", on windows, something else, but that shouldn't be part of the spec
    # what matters is that `$` doesn't cause the codegen bug mentioned

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
