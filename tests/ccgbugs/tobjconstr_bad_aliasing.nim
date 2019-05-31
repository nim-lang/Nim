discard """
  output: '''(10, (20, ))
42'''
"""

import strutils, sequtils

# bug #668

type
  TThing = ref object
    data: int
    children: seq[TThing]

proc `$`(t: TThing): string =
  result = "($1, $2)" % @[$t.data, join(map(t.children, proc(th: TThing): string = $th), ", ")]

proc somethingelse(): seq[TThing] =
  result = @[TThing(data: 20, children: @[])]

proc dosomething(): seq[TThing] =
  result = somethingelse()

  result = @[TThing(data: 10, children: result)]

echo($dosomething()[0])


# bug #9844

proc f(v: int): int = v

type X = object
  v: int

var x = X(v: 42)

x = X(v: f(x.v))
echo x.v
