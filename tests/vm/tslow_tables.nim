discard """
  timeout: "7"
  action: "compile"
  nimout: '''create
search
done'''
"""

# bug #12195

import tables

type Flop = object
  a: array[128, int]  # <-- compile time is proportional to array size

proc hop(): bool =
  var v: Table[int, Flop]

  echo "create"
  for i in 1..1000:
    v.add i, Flop()

  echo "search"
  for i in 1..1000:
    discard contains(v, i)

  echo "done"

const r {.used.} = hop()

