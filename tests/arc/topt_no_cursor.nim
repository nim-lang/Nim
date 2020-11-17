discard """
  output: '''(repo: "", package: "meo", ext: "")
doing shady stuff...
3
6'''
  cmd: '''nim c --gc:arc --expandArc:newTarget --expandArc:delete --hint:Performance:off $file'''
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

var saved
var sibling_cursor = target.parent.left
`=`(saved, sibling_cursor.right)
`=`(sibling_cursor.right, saved.left)
`=sink`(sibling_cursor.parent, saved)
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
