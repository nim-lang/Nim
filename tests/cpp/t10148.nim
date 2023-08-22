discard """
  output: '''Expected successful exit'''
  joinable: false
"""

import os

proc another_proc: string =
  ## trigger many GC allocations
  var x = @[""]
  for i in 0..100:
   x.add $i
  result = "not_existent_path"

proc findlib2: string =
  let path = getEnv("MYLIB2_DOES_NOT_EXIST_PATH")
  let another_path = another_proc()
  GC_fullCollect()

  if path.len > 0 and dirExists(path):
    path / "alib_does_not_matter.dll"
  elif fileExists(another_path):
    another_path
  else:
    quit("Expected successful exit", 0)

proc imported_func*(a: cint): cstring {.importc, dynlib: findlib2().}

echo imported_func(0)
