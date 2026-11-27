discard """
  matrix: "--mm:orc -d:useMalloc -d:noSignalHandler -d:case1; --mm:orc -d:useMalloc -d:noSignalHandler -d:case2; --mm:orc -d:useMalloc -d:noSignalHandler -d:case3; --mm:arc -d:useMalloc -d:noSignalHandler -d:case1"
  targets: "c"
  disabled: "windows"
  output: "out of memory"
  exitcode: 0
"""

# bug #26331: with -d:useMalloc a failed malloc/calloc/realloc must call
# `raiseOutOfMem` instead of returning nil to the caller

{.passC: "-Dmalloc=nimTestMalloc -Dcalloc=nimTestCalloc -Drealloc=nimTestRealloc".}

{.emit: """
#undef malloc
#undef calloc
#undef realloc
void *malloc(size_t size);
void *calloc(size_t n, size_t size);
void *realloc(void *p, size_t size);
int nimFailAlloc = 0;
void *nimTestMalloc(size_t size) { return nimFailAlloc ? NULL : malloc(size); }
void *nimTestCalloc(size_t n, size_t size) { return nimFailAlloc ? NULL : calloc(n, size); }
void *nimTestRealloc(void *p, size_t size) { return nimFailAlloc ? NULL : realloc(p, size); }
""".}

var failAlloc {.importc: "nimFailAlloc".}: cint

proc onOom() {.gcsafe, raises: [].} =
  failAlloc = 0
  echo "out of memory"
  quit(0)

outOfMemHook = onOom

when defined(case1): # alloc0
  failAlloc = 1
  var s = newSeq[byte](16)
  doAssert s.len == 16
elif defined(case2): # alloc
  failAlloc = 1
  var s = newSeqOfCap[byte](16)
  s.add 1
elif defined(case3): # realloc
  var s = @[1]
  failAlloc = 1
  for i in 0 ..< 100: s.add i

quit(3) # the allocation above must not succeed
