discard """
  disabled: "windows"
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc; --mm:orc -d:checkAbi"
"""

when defined(linux) and sizeof(int) == 8:
  import std/[assertions, posix]

  proc nativeSize[T](value {.bycopy.}: T): csize_t {.
    importc: "sizeof", nodecl, noSideEffect.}
    ## Reads the size of the header-defined C type.

  template check(typ: typedesc) =
    ## Checks modeled layouts at compile time and opaque layouts at runtime.
    block:
      var value {.volatile.}: typ
      when defined(checkAbi) and compiles(static(sizeof(typ))):
        discard addr value
      else:
        echo $typ, ": ", sizeof(typ), " / ", nativeSize(value)
        doAssert sizeof(typ) == int(nativeSize(value))

  when not defined(checkAbi):
    # Keep the additional compiler ABI checks focused on pthread layouts.
    check(Off)
    check(posix.Time)
    check(SockLen)
    check(Stat)
    check(Sigset)
    check(Sockaddr_in)
    check(Sockaddr_in6)
  check(Pthread_attr)
  check(Pthread_barrierattr)
  check(Pthread_condattr)
  check(Pthread_mutexattr)
  check(Pthread_rwlockattr)
  check(Pthread_mutex)
  check(Pthread_cond)
  check(Pthread_rwlock)
  check(Pthread_barrier)

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
