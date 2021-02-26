#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

from typetraits import supportsCopyMem

type
  RodSection* = enum
    versionSection
    configSection
    stringsSection
    checkSumsSection
    depsSection
    integersSection
    floatsSection
    exportsSection
    reexportsSection
    compilerProcsSection
    trmacrosSection
    convertersSection
    methodsSection
    pureEnumsSection
    macroUsagesSection
    toReplaySection
    topLevelSection
    bodiesSection
    symsSection
    typesSection
    typeInstCacheSection
    procInstCacheSection
    attachedOpsSection
    methodsPerTypeSection
    enumToStringProcsSection
    aliveSymsSection # beware, this is stored in a `.alivesyms` file.

  RodFileError* = enum
    ok, tooBig, cannotOpen, ioFailure, wrongHeader, wrongSection, configMismatch,
    includeFileChanged

  RodFile* = object
    f*: File
    currentSection*: RodSection # for error checking
    err*: RodFileError # little experiment to see if this works
                       # better than exceptions.

const
  RodVersion = 1
  cookie = [byte(0), byte('R'), byte('O'), byte('D'),
            byte(sizeof(int)*8), byte(system.cpuEndian), byte(0), byte(RodVersion)]

proc setError(f: var RodFile; err: RodFileError) {.inline.} =
  f.err = err
  #raise newException(IOError, "IO error")

proc storePrim*(f: var RodFile; s: string) =
  if f.err != ok: return
  if s.len >= high(int32):
    setError f, tooBig
    return
  var lenPrefix = int32(s.len)
  if writeBuffer(f.f, addr lenPrefix, sizeof(lenPrefix)) != sizeof(lenPrefix):
    setError f, ioFailure
  else:
    if s.len != 0:
      if writeBuffer(f.f, unsafeAddr(s[0]), s.len) != s.len:
        setError f, ioFailure

proc storePrim*[T](f: var RodFile; x: T) =
  if f.err != ok: return
  when supportsCopyMem(T):
    if writeBuffer(f.f, unsafeAddr(x), sizeof(x)) != sizeof(x):
      setError f, ioFailure
  elif T is tuple:
    for y in fields(x):
      storePrim(f, y)
  elif T is object:
    for y in fields(x):
      when y is seq:
        storeSeq(f, y)
      else:
        storePrim(f, y)
  else:
    {.error: "unsupported type for 'storePrim'".}

proc storeSeq*[T](f: var RodFile; s: seq[T]) =
  if f.err != ok: return
  if s.len >= high(int32):
    setError f, tooBig
    return
  var lenPrefix = int32(s.len)
  if writeBuffer(f.f, addr lenPrefix, sizeof(lenPrefix)) != sizeof(lenPrefix):
    setError f, ioFailure
  else:
    for i in 0..<s.len:
      storePrim(f, s[i])

proc loadPrim*(f: var RodFile; s: var string) =
  if f.err != ok: return
  var lenPrefix = int32(0)
  if readBuffer(f.f, addr lenPrefix, sizeof(lenPrefix)) != sizeof(lenPrefix):
    setError f, ioFailure
  else:
    s = newString(lenPrefix)
    if lenPrefix > 0:
      if readBuffer(f.f, unsafeAddr(s[0]), s.len) != s.len:
        setError f, ioFailure

proc loadPrim*[T](f: var RodFile; x: var T) =
  if f.err != ok: return
  when supportsCopyMem(T):
    if readBuffer(f.f, unsafeAddr(x), sizeof(x)) != sizeof(x):
      setError f, ioFailure
  elif T is tuple:
    for y in fields(x):
      loadPrim(f, y)
  elif T is object:
    for y in fields(x):
      when y is seq:
        loadSeq(f, y)
      else:
        loadPrim(f, y)
  else:
    {.error: "unsupported type for 'loadPrim'".}

proc loadSeq*[T](f: var RodFile; s: var seq[T]) =
  if f.err != ok: return
  var lenPrefix = int32(0)
  if readBuffer(f.f, addr lenPrefix, sizeof(lenPrefix)) != sizeof(lenPrefix):
    setError f, ioFailure
  else:
    s = newSeq[T](lenPrefix)
    for i in 0..<lenPrefix:
      loadPrim(f, s[i])

proc storeHeader*(f: var RodFile) =
  if f.err != ok: return
  if f.f.writeBytes(cookie, 0, cookie.len) != cookie.len:
    setError f, ioFailure

proc loadHeader*(f: var RodFile) =
  if f.err != ok: return
  var thisCookie: array[cookie.len, byte]
  if f.f.readBytes(thisCookie, 0, thisCookie.len) != thisCookie.len:
    setError f, ioFailure
  elif thisCookie != cookie:
    setError f, wrongHeader

proc storeSection*(f: var RodFile; s: RodSection) =
  if f.err != ok: return
  assert f.currentSection < s
  f.currentSection = s
  storePrim(f, s)

proc loadSection*(f: var RodFile; expected: RodSection) =
  if f.err != ok: return
  var s: RodSection
  loadPrim(f, s)
  if expected != s and f.err == ok:
    setError f, wrongSection

proc create*(filename: string): RodFile =
  if not open(result.f, filename, fmWrite):
    setError result, cannotOpen

proc close*(f: var RodFile) = close(f.f)

proc open*(filename: string): RodFile =
  if not open(result.f, filename, fmRead):
    setError result, cannotOpen
