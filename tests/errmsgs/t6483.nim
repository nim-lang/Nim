discard """
  errormsg: "request to generate code for .compileTime proc: newSeq"
  line: 21
"""

type
  VarItem = object
    onode: NimNode
    nnode: NimNode
    suffix: string

  VarState = object
    scopes: seq[VarScope]

  VarScope = object
    variables: seq[VarItem]
    children: seq[VarScope]

when true:
  var scope1 = VarScope(
    variables: newSeq[VarItem](),
    children: newSeq[VarScope]()
  )
  var scope2 = VarScope(
    variables: newSeq[VarItem](),
    children: newSeq[VarScope]()
  )
  var state = VarState(scopes: newSeq[VarScope]())
  state.scopes.add(scope1)
  state.scopes[0].children.add(scope2)
  echo($state.scopes)