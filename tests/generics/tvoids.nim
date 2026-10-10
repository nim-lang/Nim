block: # bug #25441
  func foo[T](x: T, y: int) =
    discard

  foo[void](10)

block:
  func foo[T: void|float](e: openArray[int], x: T, y: int) =
    discard

  var x: seq[int]
  foo[void] x, 2

block: # bug #7355
  proc gen[A: void, T: void|int](a: A, b: T) = discard

  gen[void, void]()     # Works
  gen[void, int] 0      # Crash
  gen[void, int](b = 0) # Crash