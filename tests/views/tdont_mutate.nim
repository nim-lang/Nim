discard """
  cmd: "nim check --hints:off $file"
"""

import tables

{.experimental: "views".}

const
  Whitespace = {' ', '\t', '\n', '\r'}

proc split*(s: string, seps: set[char] = Whitespace, maxsplit: int = -1): Table[int, openArray[char]] #[tt.Error
      'result' borrows from the immutable location 's' and attempts to mutate it
    ]# =
  var last = 0
  var splits = maxsplit
  result = initTable[int, openArray[char]]()

  while last <= len(s):
    var first = last
    while last < len(s) and s[last] notin seps:
      inc(last)
    if splits == 0: last = len(s)
    result[first] = toOpenArray(s, first, last-1)

    result[first][0] = 'c'

    if splits == 0: break
    dec(splits)
    inc(last)

proc `$`(x: openArray[char]): string =
  result = newString(x.len)
  for i in 0..<x.len: result[i] = x[i]

proc otherTest(x: int) =
  var y: var int = x #[tt.Error
    'y' borrows from the immutable location 'x' and attempts to mutate it
  ]#
  y = 3

proc main() =
  let words = split("asdf 231")
  for i, x in words:
    echo i, ": ", x

main()

# This has to continue to work:

type
  PNode = ref object
  TSrcGen = object
    comStack: seq[PNode]

proc pushCom(g: var TSrcGen, n: PNode) =
  setLen(g.comStack, g.comStack.len + 1)
  g.comStack[^1] = n
