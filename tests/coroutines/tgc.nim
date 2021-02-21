discard """
  matrix: "--gc:refc; --gc:arc; --gc:orc"
  target: "c"
"""

when compileOption("gc", "refc") or not defined(openbsd):
  # xxx openbsd gave: stdlib_coro.nim.c:406:22: error: array type 'jmp_buf' (aka 'long [11]') is not assignable (*dest).execContext = src.execContext;
  import coro

  var maxOccupiedMemory = 0

  proc testGC() =
    var numbers = newSeq[int](100)
    maxOccupiedMemory = max(maxOccupiedMemory, getOccupiedMem())
    suspend(0)

  start(testGC)
  start(testGC)
  run()

  GC_fullCollect()
  doAssert(getOccupiedMem() < maxOccupiedMemory, "GC did not free any memory allocated in coroutines")
