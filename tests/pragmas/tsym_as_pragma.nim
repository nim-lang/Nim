
# bug #3171

template newDataWindow(): untyped =
    let eventClosure = proc (closure: pointer): bool {.closure, cdecl.} =
        discard

newDataWindow()
