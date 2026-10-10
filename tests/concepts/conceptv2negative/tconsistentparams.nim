discard """
action: "reject"
errormsg: "type mismatch"
"""

type
  Dollarable = concept
    proc `$`(x: Self): string

proc checkEqual(x, y: Dollarable) =
  if x != y:
    echo $x
    echo $y

type
  StateFlags = enum
    sfMatch
    sfSoft

  MatchKind = enum
    NoFurtherMatch
    NoMatch
    Match
    AllFurtherMatch

proc `==`(a: set[StateFlags]; b: MatchKind): bool = true

checkEqual({sfMatch, sfSoft}, Match)
