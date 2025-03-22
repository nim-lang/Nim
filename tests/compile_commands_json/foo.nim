{.compile("foo.cpp", "-DENABLE_FOO").}

proc foo() {.importc.}

when isMainModule:
  foo()
