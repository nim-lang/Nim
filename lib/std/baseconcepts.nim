type
  Iterable*[T] = concept c
    for x in items(c): x is T
    for x in mitems(c): x is var T

  Indexable*[T] = concept c
    var i: int
    c[i] is T
    c[i] is var T
    var val: T
    c[i] = val
    c.len is int

#   StringLike* = concept c of Indexable[char]
#     for x in items(c): x is char
#     var first, last: int
#     substr(c, first, last)
#     substr(c, first)
#     c.add(char)
#     c.add(string)
