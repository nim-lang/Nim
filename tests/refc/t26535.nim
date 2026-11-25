discard """
  matrix: "--mm:refc; --mm:refc -d:release; --mm:orc"
  output: '''
1
1
1
1'''
"""

# bug #26535: a seq whose element type has a hook was not considered a GC'ed
# ref under refc, so storing it inside another object skipped the incRef

type D = object
  x: int

proc `=copy`(a: var D; b: D) = a.x = b.x

type Root = object
  s: seq[D]

proc fill(v: int): seq[D] =
  result = newSeq[D](64)
  for d in result.mitems: d.x = v

var roots: seq[Root]
var tups: seq[(int, seq[D])]
var arrs: seq[array[1, Root]]
var nested: seq[seq[Root]]

proc store() {.noinline.} =
  roots.add Root(s: fill(1))
  tups.add (0, fill(1))
  arrs.add [Root(s: fill(1))]
  var inner = @[Root(s: fill(1))]
  nested.add inner
  nested = nested # genericAssign of seq[seq[Root]]

proc churn() {.noinline.} =
  GC_fullCollect()
  var junk: seq[seq[D]]
  for i in 0 ..< 100: junk.add fill(2)

store()
churn()
echo roots[0].s[0].x
echo tups[0][1][0].x
echo arrs[0][0].s[0].x
echo nested[0][0].s[0].x
