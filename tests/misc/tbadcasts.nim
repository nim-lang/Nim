template reject(x) =
  static: assert(not compiles(x))

reject:
  discard cast[enum](0)
proc a = echo "hi"

reject:
  discard cast[ptr](a)
