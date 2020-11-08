discard """
  targets: "c cpp"
"""

proc f1(v: typeof(nil)) = discard
f1(nil)

proc f2[T]() = discard
f2[typeof(nil)]()

proc f3(_: typedesc) = discard
f3(typeof(nil))

proc f4[T](_: T) = discard
f4(nil)
