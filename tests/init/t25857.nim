discard """
  output: "1"
"""

# Regression for #25857: `typeof(result)` inside `result`'s initializer must not be
# treated as a use-before-initialization of `result`. `typeof` is a type query and
# never evaluates its operand, so this compiles and runs.
# (Before the fix this errored: "'result' requires explicit initialization" on
#  {.requiresInit.} return types, breaking the `ok(typeof(result), v)` idiom.)

type Box[T] {.requiresInit.} = object
  v: T

func make[T](_: typedesc[Box[T]], v: T): Box[T] = Box[T](v: v)

proc f(): Box[int] =
  make(typeof(result), 1)

echo f().v
