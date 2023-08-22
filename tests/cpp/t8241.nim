discard """
  targets: "cpp"
  action: "compile"
"""

proc foo(): cstring {.importcpp: "", dynlib: "".}
echo foo()


## bug #9222
import os
import amodule
proc findlib2: string =
  let path = getEnv("MYLIB2_DOES_NOT_EXIST_PATH")
  if path.len > 0 and dirExists(path):
    path / "alib_does_not_matter.dll"
  else:
    "alib_does_not_matter.dll"

proc imported_func2*(a: cint): cstring {.importc, dynlib: findlib2().}

echo imported_func(1)
echo imported_func2(1)

# issue #8946

from json import JsonParsingError
import marshal

const nothing = ""
doAssertRaises(JsonParsingError):
  var bar = marshal.to[int](nothing)
