discard """
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
"""

when defined(posix):
  import std/[assertions, posix]

  block:
    let pageSize = sysconf(SC_PAGESIZE)
    var
      attributes: Pthread_attr
      guardSize, stackSize: csize_t
      stack: pointer
      state: cint
    doAssert pthread_attr_init(addr attributes) == 0
    defer:
      doAssert pthread_attr_destroy(addr attributes) == 0
    doAssert pthread_attr_setguardsize(addr attributes, pageSize) == 0
    doAssert pthread_attr_getguardsize(addr attributes, guardSize) == 0
    doAssert guardSize == csize_t(pageSize)
    doAssert pthread_attr_setstacksize(addr attributes, 2 * 1024 * 1024) == 0
    doAssert pthread_attr_getstacksize(addr attributes, stackSize) == 0
    doAssert stackSize == 2 * 1024 * 1024
    let storage = mmap(
      nil,
      2 * 1024 * 1024,
      PROT_READ or PROT_WRITE,
      MAP_PRIVATE or MAP_ANONYMOUS,
      -1,
      0
    )
    doAssert storage != MAP_FAILED
    defer:
      doAssert munmap(storage, 2 * 1024 * 1024) == 0
    doAssert pthread_attr_setstack(
      addr attributes,
      storage,
      2 * 1024 * 1024
    ) == 0
    doAssert pthread_attr_getstack(addr attributes, stack, stackSize) == 0
    doAssert stack == storage
    doAssert stackSize == 2 * 1024 * 1024
    doAssert pthread_attr_setdetachstate(
      addr attributes,
      PTHREAD_CREATE_JOINABLE
    ) == 0
    doAssert pthread_attr_getdetachstate(addr attributes, state) == 0
    doAssert state == PTHREAD_CREATE_JOINABLE
