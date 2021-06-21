import macros

macro macro_bug*(s: untyped) =
  echo s.treeRepr
  s.expectKind({nnkProcDef, nnkMethodDef})

  var params = s.params

  let genericParams = s[2]
  result = newNimNode(nnkProcDef).add(
    s.name, s[1], genericParams, params, pragma(s), newEmptyNode())

  # don't really do anything
  var body = body(s)
  result.add(body)

  echo "result:"
  echo result.repr
