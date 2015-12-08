discard """
  file: "tsym_as_pragma.nim"
"""

# bug #3171

template newDataWindow(): stmt =
    let eventClosure = proc (closure: pointer): bool {.closure, cdecl.} =
        discard

newDataWindow()
