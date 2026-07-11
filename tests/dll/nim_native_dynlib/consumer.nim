import std/os

const nativeLibrary =
  when defined(macosx):
    currentSourcePath.parentDir / "libproducer.dylib"
  elif defined(linux):
    currentSourcePath.parentDir / "libproducer.so"
  else:
    {.error: "unsupported native dynlib test platform".}

proc nativeNimMain() {.cdecl, importc: "NimMain", dynlib: nativeLibrary.}
proc nativeMessage(): string {.
  nimcall,
  importc: "_ZN8producer7messageE",
  dynlib: nativeLibrary.}

nativeNimMain()
doAssert nativeMessage() == "hello from the dynlib"
