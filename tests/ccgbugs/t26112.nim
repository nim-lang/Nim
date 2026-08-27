discard """
  matrix: "--mm:refc; --mm:orc"
  ccodeCheck: "'result.fromScalar = x_p0;'"
  ccodeCheck: "'result.fromObject = x_p0.fromObject;'"
  ccodeCheck: "'result.nested.fromNested = x_p0.fromNested;'"
"""

# bug #26112: unrelated parameters were considered potential aliases of the
# result location when their types could be contained in the returned object.

type
  Inner = object
    fromNested: int
  P = object
    fromScalar: int
    fromObject: int
    nested: Inner

func fromScalar(x: int): P =
  P(fromScalar: x)

proc fromObject(x: P): P =
  P(fromObject: x.fromObject)

func fromNested(x: Inner): P =
  P(nested: Inner(fromNested: x.fromNested))

proc selfAlias(): P =
  result.fromScalar = 42
  result = P(fromScalar: result.fromScalar)

doAssert fromScalar(1).fromScalar == 1
doAssert fromObject(P(fromObject: 2)).fromObject == 2
doAssert fromNested(Inner(fromNested: 3)).nested.fromNested == 3
doAssert selfAlias().fromScalar == 42
