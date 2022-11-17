discard """
  errormsg: "expression 'E.N' type cannot be inferred"
"""

type
  Example[N: static int] = distinct void
  What[E: Example] = Example[E.N + E.N]
