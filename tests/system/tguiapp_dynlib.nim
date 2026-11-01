discard """
  action: compile
  matrix: "--app:gui"
  disabled: "posix"
"""

# A Windows GUI app with a dynlib import compiles: the load-error path in
# system/dyncalls.nim reports through MessageBoxA, which must be declared
# whatever the order system.nim includes dyncalls and excpt in.

proc missingProc() {.importc: "missingProc", dynlib: "nim_tguiapp_missing.dll".}

if false:
  missingProc()
