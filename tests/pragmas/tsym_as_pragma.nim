
# bug #3171
when false:
  # now getting: Error: invalid pragma: closure`gensym272010
  template newDataWindow(): untyped =
      let eventClosure = proc (closure: pointer): bool {.closure, cdecl.} =
          discard

  newDataWindow()
