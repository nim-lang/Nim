discard """
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
"""

when defined(linux) and (defined(amd64) or defined(arm64)):
  import std/[assertions, posix]

  proc nativeSize[T](value {.bycopy.}: T): csize_t {.
    importc: "sizeof", nodecl, noSideEffect.}
    ## Reads the size of the header-defined C type.

  template check(typ: typedesc) =
    ## Compares Nim's size with the native C typedef.
    block:
      var value: typ
      doAssert sizeof(typ) == int(nativeSize(value))

  check(ClockId)
  check(Gid)
  check(Id)
  check(Key)
  check(Nlink)
  check(Uid)
  check(Useconds)
  check(Pthread_key)
  check(Pthread_once)
  check(Pthread_spinlock)
  doAssert high(Uid) == Uid(high(cuint))

  {.emit: "static void set_second_gid(gid_t *gids) { gids[1] = 42; }".}
  proc setSecond(values: ptr Gid) {.importc: "set_second_gid", nodecl.}
    ## Writes the second array element using the native C stride.

  var values = newSeq[Gid](2)
  setSecond(addr values[0])
  doAssert values == @[Gid(0), Gid(42)]
