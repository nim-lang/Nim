discard """
  output: '''(repo: "", package: "meo", ext: "")
doing shady stuff...
3
6
(@[1], @[2])'''
  cmd: '''nim c --gc:arc --expandArc:newTarget --expandArc:delete --expandArc:p1 --expandArc:tt --hint:Performance:off $file'''
  nimout: '''--expandArc: newTarget

var
  splat
  :tmp
  :tmp_1
  :tmp_2
splat = splitFile(path)
:tmp = splat.dir
wasMoved(splat.dir)
:tmp_1 = splat.name
wasMoved(splat.name)
:tmp_2 = splat.ext
wasMoved(splat.ext)
result = (
  let blitTmp = :tmp
  blitTmp,
  let blitTmp_1 = :tmp_1
  blitTmp_1,
  let blitTmp_2 = :tmp_2
  blitTmp_2)
`=destroy`(splat)
-- end of expandArc ------------------------
--expandArc: delete

var
  sibling
  saved
`=copy`(sibling, target.parent.left)
`=copy`(saved, sibling.right)
`=copy`(sibling.right, saved.left)
`=sink`(sibling.parent, saved)
`=destroy`(sibling)
-- end of expandArc ------------------------
--expandArc: p1

var
  lresult
  lvalue
  lnext
  _
lresult = @[123]
_ = (
  let blitTmp = lresult
  blitTmp, ";")
lvalue = _[0]
lnext = _[1]
`=sink`(result.value, move lvalue)
`=destroy`(lnext)
`=destroy_1`(lvalue)
-- end of expandArc ------------------------
--expandArc: tt

var
  a
  :tmpD
  :tmpD_1
  :tmpD_2
try:
  var it_cursor = x
  a = (
    wasMoved(:tmpD)
    `=copy`(:tmpD, it_cursor.key)
    :tmpD,
    wasMoved(:tmpD_1)
    `=copy`(:tmpD_1, it_cursor.val)
    :tmpD_1)
  echo [
    :tmpD_2 = `$`(a)
    :tmpD_2]
finally:
  `=destroy`(:tmpD_2)
  `=destroy_1`(a)
-- end of expandArc ------------------------'''
"""

import os

type Target = tuple[repo, package, ext: string]

proc newTarget*(path: string): Target =
  let splat = path.splitFile
  result = (repo: splat.dir, package: splat.name, ext: splat.ext)

echo newTarget("meo")

type
  Node = ref object
    left, right, parent: Node
    value: int

proc delete(target: var Node) =
  var sibling = target.parent.left # b3
  var saved = sibling.right # b3.right -> r4

  sibling.right = saved.left # b3.right -> r4.left = nil
  sibling.parent = saved # b3.parent -> r5 = r4

  #[after this proc:
        b 5
      /   \
    b 3     b 6
  ]#


#[before:
      r 5
    /   \
  b 3    b 6 - to delete
  /    \
empty  r 4
]#
proc main =
  var five = Node(value: 5)

  var six = Node(value: 6)
  six.parent = five
  five.right = six

  var three = Node(value: 3)
  three.parent = five
  five.left = three

  var four = Node(value: 4)
  four.parent = three
  three.right = four

  echo "doing shady stuff..."
  delete(six)
  # need both of these echos
  echo five.left.value
  echo five.right.value

main()

type
  Maybe = object
    value: seq[int]

proc p1(): Maybe =
  let lresult = @[123]
  var lvalue: seq[int]
  var lnext: string
  (lvalue, lnext) = (lresult, ";")

  result.value = move lvalue

proc tissue15130 =
  doAssert p1().value == @[123]

tissue15130()

type
  KeyValue = tuple[key, val: seq[int]]

proc tt(x: KeyValue) =
  var it = x
  let a = (it.key, it.val)
  echo a

proc encodedQuery =
  var query: seq[KeyValue]
  query.add (key: @[1], val: @[2])

  for elem in query:
    elem.tt()

encodedQuery()

# bug #15147

proc s(input: string): (string, string) =
  result = (";", "")

proc charmatch(input: string): (string, string) =
  result = ("123", input[0 .. input.high])

proc plus(input: string) =
  var
    lvalue, rvalue: string # cursors
    lnext: string # must be cursor!!!
    rnext: string # cursor
  let lresult = charmatch(input)
  (lvalue, lnext) = lresult

  let rresult = s(lnext)
  (rvalue, rnext) = rresult

plus("123;")
