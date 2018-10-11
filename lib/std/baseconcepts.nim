type
  Iterable*[T] = concept c
    for x in items(c): x is T

  Indexable*[T] = concept c
    var i: int
    c[i] is T
    c.len is int

  StringLike* = concept c of Indexable[char]
    for x in items(c): x is char
    var first, last: int
    substr(c, first, last)
    substr(c, first)

  MutStringLike* = concept var c of StringLike
    c.add(char)
    c.add(string)

