discard """
action: compile
"""

# bug #3669

import tables

type
  G[T] = object
    inodes: Table[int, T]
    rnodes: Table[T, int]

var g: G[string]
echo g.rnodes["foo"]
