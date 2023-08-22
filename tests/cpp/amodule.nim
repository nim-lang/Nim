import os

proc findlib: string =
  let path = getEnv("MYLIB_DOES_NOT_EXIST_PATH")
  if path.len > 0 and dirExists(path):
    path / "alib_does_not_matter.dll"
  else:
    "alib_does_not_matter.dll"

proc imported_func*(a: cint): cstring {.importc, dynlib: findlib().}