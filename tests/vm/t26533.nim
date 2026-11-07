discard """
  action: compile
"""

# bug #26533: `tryConstExpr` hands an expression containing `yield` to the
# VM; injecting destructors must not abort with an internal error.

proc g(_: static int | int) = discard
iterator d: int = g((; yield 0; 0))
