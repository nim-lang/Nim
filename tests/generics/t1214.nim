discard """
  output: '''
int8
int16
int8
int16
'''
"""

import typetraits

# bug #1214: an int literal must bind to the branch of the union type
# that accepts it, not to its base type, which would circumvent the
# constraint entirely

proc p(x: int8|int16) =
  echo x.type.name

proc q[T: int8|int16](x: T) =
  echo T.name

p(1)
p(300)
q(1)
q(300)

proc r[T: SomeInteger](x: T): T = x
# `int` is a branch of `SomeInteger` and matches the literal exactly,
# so the base type is still bound:
doAssert typeof(r(1)) is int

proc reject(x: int8|int16) = discard
doAssert not compiles(reject(100_000))
doAssert not compiles(reject(100_000'i64))
