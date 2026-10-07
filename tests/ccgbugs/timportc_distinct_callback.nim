discard """
  matrix: "-d:pointerFirst; -d:fileFirst"
  output: "ok"
"""

type
  PFile {.importc: "FILE*", header: "<stdio.h>".} = distinct pointer
  FileCb = proc (f: PFile) {.cdecl.}
  PtrCb = proc (p: pointer) {.cdecl.}

proc onFile(f: PFile) {.cdecl.} = discard
proc onPtr(p: pointer) {.cdecl.} = discard

# Bug #26312: compile each order separately so each type gets to be first.
when defined(fileFirst):
  var b: FileCb = onFile
  var a: PtrCb = onPtr
else:
  var a: PtrCb = onPtr
  var b: FileCb = onFile

a(nil)
b(PFile(nil))

echo "ok"
