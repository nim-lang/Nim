discard """
  disabled: "windows"
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
"""

when defined(linux) and sizeof(int) == 8:
  import std/[assertions, posix]

  proc nativeSize[T](value {.bycopy.}: T): csize_t {.
    importc: "sizeof", nodecl, noSideEffect.}
    ## Reads the size of the header-defined C type.

  template check(typ: typedesc) =
    ## Compares Nim's runtime size with the C header.
    block:
      var value: typ
      echo $typ, ": ", sizeof(typ), " / ", nativeSize(value)
      doAssert sizeof(typ) == int(nativeSize(value))

  check(Off)
  check(posix.Time)
  check(SockLen)
  check(Stat)
  check(Sigset)
  check(Pthread_attr)
  check(Pthread_barrierattr)
  check(Pthread_condattr)
  check(Pthread_mutexattr)
  check(Pthread_rwlockattr)
  check(Pthread_mutex)
  check(Pthread_cond)
  check(Pthread_rwlock)
  check(Pthread_barrier)
  check(Sockaddr_in)
  check(Sockaddr_in6)

  block:
    type Guarded = object
      before: uint64
      mutex: Pthread_mutex
      after: uint64
    var guards = newSeq[Guarded](2)
    for i in 0 ..< guards.len:
      guards[i].before = 123
      guards[i].after = 456
      doAssert pthread_mutex_init(addr guards[i].mutex, nil) == 0
      doAssert pthread_mutex_lock(addr guards[i].mutex) == 0
      doAssert pthread_mutex_unlock(addr guards[i].mutex) == 0
      doAssert pthread_mutex_destroy(addr guards[i].mutex) == 0
      doAssert guards[i].before == 123 and guards[i].after == 456
