discard """
  matrix: "--mm:orc; --mm:refc; --mm:orc -d:useMalloc"
  output: '''
@[1, 2, 3]
@[1, 2, 3]
@[4, 5]
kid
'''
"""

# bug #26773
type Node = object
  next: ref Node
  values: seq[int]

proc main =
  var x = Node(next: (ref Node)(values: @[1, 2, 3]))
  x = x.next[]
  echo x.values

proc viaTemp =
  var x = Node(next: (ref Node)(values: @[1, 2, 3]))
  let tmp = x.next[]
  x = tmp
  echo x.values

proc derefLhs =
  var p = (ref Node)(next: (ref Node)(values: @[4, 5]))
  p[] = p.next[]
  echo p.values

type Tree = object
  kids: seq[Tree]
  name: string

proc seqIndex =
  var t = Tree(kids: @[Tree(name: "kid")], name: "root")
  t = t.kids[0]
  echo t.name

main()
viaTemp()
derefLhs()
seqIndex()
