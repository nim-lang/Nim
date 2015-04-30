import macros

macro macro_bug*(s: stmt): stmt {.immediate.} =
  s.expectKind({nnkProcDef, nnkMethodDef})

  var params = s.params

  let genericParams = s[2]
  result = newNimNode(nnkProcDef).add(
    s.name, s[1], genericParams, params, pragma(s), newEmptyNode())

  var body = body(s)

  # Fails here.
  var call = newCall("macro_bug", s.params[1][0])
  body.insert(0, call)
  result.add(body)
