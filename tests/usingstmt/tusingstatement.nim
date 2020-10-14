discard """
  output: "Using test.Closing test."
"""

import
  macros

# This macro mimics the using statement from C#
#
# It's kept only as a test for the macro system
# Nim's destructors offer a mechanism for automatic
# disposal of resources.
#
macro autoClose(args: varargs[untyped]): untyped =
  let e = callsite()
  if e.len != 3:
    error "Using statement: unexpected number of arguments. Got " &
      $e.len & ", expected: 1 or more variable assignments and a block"

  var args = e
  var body = e[2]

  var
    variables : seq[NimNode]
    closingCalls : seq[NimNode]

  newSeq(variables, 0)
  newSeq(closingCalls, 0)

  for i in countup(1, args.len-2):
    if args[i].kind == nnkExprEqExpr:
      var varName = args[i][0]
      var varValue = args[i][1]

      var varAssignment = newNimNode(nnkIdentDefs)
      varAssignment.add(varName)
      varAssignment.add(newNimNode(nnkEmpty)) # empty means no type
      varAssignment.add(varValue)
      variables.add(varAssignment)

      closingCalls.add(newCall(newIdentNode("close"), varName))
    else:
      error "Using statement: Unexpected expression. Got " &
        $args[i].kind & " instead of assignment."

  var varSection = newNimNode(nnkVarSection)
  varSection.add(variables)

  var finallyBlock = newNimNode(nnkStmtList)
  finallyBlock.add(closingCalls)

  # XXX: Use a template here once getAst is working properly
  var targetAst = parseStmt"""block:
    var
      x = foo()
      y = bar()

    try:
      body()

    finally:
      close x
      close y
  """

  targetAst[0][1][0] = varSection
  targetAst[0][1][1][0] = body
  targetAst[0][1][1][1][0] = finallyBlock

  result = targetAst

type
  TResource* = object
    field*: string

proc openResource(param: string): TResource =
  result.field = param

proc close(r: var TResource) =
  write(stdout, "Closing " & r.field & ".")

proc use(r: var TResource) =
  write(stdout, "Using " & r.field & ".")

autoClose(r = openResource("test")):
  use r

write stdout, "\n"
