discard """
  cmd: "nim check -d:useNimRtl $options $file"
  action: "compile"
"""

# Ensure `.compilerRtl.` (`compilerproc` + `importc`) routines such as
# `getCurrentException` default to empty raises/tags/forbids under `-d:useNimRtl`
# instead of being treated as having unknown effects.

proc testRaises() {.raises: [].} =
  let e = getCurrentException()
  discard e

proc testTags() {.tags: [].} =
  let e = getCurrentException()
  discard e

proc testForbids() {.forbids: [RootEffect].} =
  let e = getCurrentException()
  discard e

proc customCompilerImport(): int {.compilerproc, importc.}
proc customCompilerRaising(): int {.compilerproc, importc, raises: [ValueError].}

proc testCustom() {.raises: [], tags: [], forbids: [RootEffect].} =
  discard customCompilerImport()

proc testCustomRaising() {.raises: [ValueError].} =
  discard customCompilerRaising()
