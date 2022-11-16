discard """
  errormsg: "expression 'E.N' has no type (or is ambiguous)"
"""

type
  Example[N: static int] = distinct void
  What[E: Example] = Example[E.N + E.N]
