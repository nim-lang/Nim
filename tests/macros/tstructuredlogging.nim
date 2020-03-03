discard """
output: '''
main started: a=10, b=inner-b, c=10, d=some-d, x=16, z=20
exiting: a=12, b=overriden-b, c=100, msg=bye bye, x=16
'''
"""

import macros, tables

template scopeHolder =
  0 # scope revision number

type
  BindingsSet = Table[string, NimNode]

proc actualBody(n: NimNode): NimNode =
  # skip over the double StmtList node introduced in `mergeScopes`
  result = n.body
  if result.kind == nnkStmtList and result[0].kind == nnkStmtList:
    result = result[0]

iterator bindings(n: NimNode, skip = 0): (string, NimNode) =
  for i in skip ..< n.len:
    let child = n[i]
    if child.kind in {nnkAsgn, nnkExprEqExpr}:
      let name = $child[0]
      let value = child[1]
      yield (name, value)

proc scopeRevision(scopeHolder: NimNode): int =
  # get the revision number from a scopeHolder sym
  assert scopeHolder.kind == nnkSym
  var revisionNode = scopeHolder.getImpl.actualBody[0]
  result = int(revisionNode.intVal)

proc lastScopeHolder(scopeHolders: NimNode): NimNode =
  # get the most recent scopeHolder from a symChoice node
  if scopeHolders.kind in {nnkClosedSymChoice, nnkOpenSymChoice}:
    var bestScopeRev = 0
    assert scopeHolders.len > 0
    for scope in scopeHolders:
      let rev = scope.scopeRevision
      if result == nil or rev > bestScopeRev:
        result = scope
        bestScopeRev = rev
  else:
    result = scopeHolders

  assert result.kind == nnkSym

macro mergeScopes(scopeHolders: typed, newBindings: untyped): untyped =
  var
    bestScope = scopeHolders.lastScopeHolder
    bestScopeRev = bestScope.scopeRevision

  var finalBindings = initTable[string, NimNode]()
  for k, v in bindings(bestScope.getImpl.actualBody, skip = 1):
    finalBindings[k] = v

  for k, v in bindings(newBindings):
    finalBindings[k] = v

  var newScopeDefinition = newStmtList(newLit(bestScopeRev + 1))

  for k, v in finalBindings:
    newScopeDefinition.add newAssignment(newIdentNode(k), v)

  result = quote:
    template scopeHolder = `newScopeDefinition`

template scope(newBindings: untyped) {.dirty.} =
  mergeScopes(bindSym"scopeHolder", newBindings)

type
  TextLogRecord = object
    line: string

  StdoutLogRecord = object

template setProperty(r: var TextLogRecord, key: string, val: string, isFirst: bool) =
  if not first: r.line.add ", "
  r.line.add key
  r.line.add "="
  r.line.add val

template setEventName(r: var StdoutLogRecord, name: string) =
  stdout.write(name & ": ")

template setProperty(r: var StdoutLogRecord, key: string, val: auto, isFirst: bool) =
  when not isFirst: stdout.write ", "
  stdout.write key
  stdout.write "="
  stdout.write $val

template flushRecord(r: var StdoutLogRecord) =
  stdout.write "\n"
  stdout.flushFile

macro logImpl(scopeHolders: typed,
              logStmtProps: varargs[untyped]): untyped =
  let lexicalScope = scopeHolders.lastScopeHolder.getImpl.actualBody
  var finalBindings = initOrderedTable[string, NimNode]()

  for k, v in bindings(lexicalScope, skip = 1):
    finalBindings[k] = v

  for k, v in bindings(logStmtProps, skip = 1):
    finalBindings[k] = v

  finalBindings.sort(system.cmp)

  let eventName = logStmtProps[0]
  assert eventName.kind in {nnkStrLit}
  let record = genSym(nskVar, "record")

  result = quote:
    var `record`: StdoutLogRecord
    setEventName(`record`, `eventName`)

  var isFirst = true
  for k, v in finalBindings:
    result.add newCall(newIdentNode"setProperty",
                       record, newLit(k), v, newLit(isFirst))
    isFirst = false

  result.add newCall(newIdentNode"flushRecord", record)

template log(props: varargs[untyped]) {.dirty.} =
  logImpl(bindSym"scopeHolder", props)

scope:
  a = 12
  b = "original-b"

scope:
  x = 16
  b = "overriden-b"

scope:
  c = 100

proc main =
  scope:
    c = 10

  scope:
    z = 20

  log("main started", a = 10, b = "inner-b", d = "some-d")

main()

log("exiting", msg = "bye bye")

