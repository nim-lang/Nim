const useLibC = not defined(nimNoLibc)

proc nimCopyMem(dest, source: pointer, size: Natural) {.compilerproc, inline.} =
  when useLibC:
    c_memcpy(dest, source, size)
  else:
    let d = cast[ptr UncheckedArray[byte]](dest)
    let s = cast[ptr UncheckedArray[byte]](source)
    var i = 0
    while i < size:
      d[i] = s[i]
      inc i

proc nimSetMem(a: pointer, v: cint, size: Natural) {.nonReloadable, inline.} =
  when useLibC:
    c_memset(a, v, size)
  else:
    let a = cast[ptr UncheckedArray[byte]](a)
    var i = 0
    let v = cast[byte](v)
    while i < size:
      a[i] = v
      inc i

proc nimZeroMem(p: pointer, size: Natural) {.compilerproc, nonReloadable, inline.} =
  nimSetMem(p, 0, size)

proc nimCmpMem(a, b: pointer, size: Natural): cint {.compilerproc, inline.} =
  when useLibC:
    c_memcmp(a, b, size)
  else:
    let a = cast[ptr UncheckedArray[byte]](a)
    let b = cast[ptr UncheckedArray[byte]](b)
    var i = 0
    while i < size:
      let d = a[i].cint - b[i].cint
      if d != 0: return d
      inc i

proc nimCStrLen(a: cstring): csize {.compilerproc, nonReloadable, inline.} =
  when useLibC:
    c_strlen(a)
  else:
    var a = cast[ptr byte](a)
    while a[] != 0:
      a = cast[ptr byte](cast[uint](a) + 1)
      inc result
