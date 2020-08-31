discard """
  output: '''0
4
4
1
2
3'''
"""

type
  Comparable = concept # no T, an atom
    proc cmp(a, b: self): int

  ToStringable = concept
    proc `$`(a: self): string

  Hashable = concept
    proc hash(x: self): int
    proc `==`(x, y: self): bool

  Swapable = concept
    proc swap(x, y: var self)

when true:
  proc compare(a: Comparable) =
    echo cmp(a, a)

  compare(4)

proc dollar(x: ToStringable) =
  echo x

when true:
  dollar 4
  dollar "4"

#type D = distinct int

#dollar D(4)

when true:
  # Work on concepts
  # Write article about ARC/ORC

  type
    Iterable[Ix] = concept
      iterator items(c: self): Ix

  proc g[Tu](it: Iterable[Tu]) =
    for x in it:
      echo x

  g(@[1, 2, 3])
