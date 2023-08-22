discard """
disabled: true
"""

import os

proc getDllName: string =
  result = "mylib.dll"
  if fileExists(result): return
  result = "mylib2.dll"
  if fileExists(result): return
  quit("could not load dynamic library")

proc myImport(s: cstring) {.cdecl, importc, dynlib: getDllName().}
proc myImport2(s: int) {.cdecl, importc, dynlib: getDllName().}

myImport("test2")
myImport2(12)
