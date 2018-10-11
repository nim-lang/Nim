type
  Iterable*[T] = concept c
    for x in items(c): x is T

  Indexable*[T] = concept c
    var i: int
    c[i] is T
    c.len is int

  MIndexable*[T] = concept c of Indexable[T]
    var i: int
    c[i] is var T
    var val: T
    c[i] = val

  BufferLike*[T] = concept c of MIndexable[T]
    var val: T
    c.add(val)
    c.pop() is T

  StringLike* = concept c of Indexable[char]
    for x in items(c): x is char
    var first, last: int
    substr(c, first, last)
    substr(c, first)

  MStringLike* = concept c of StringLike
    c.add(char)
    c.add(string)
