import "../../compiler" / [llstream, nimeval]

proc myRepl(s: PLLStream, buf: pointer, bufLen: int): int =
  echo "OK"
  quit(0)

let std = findNimStdLibCompileTime()
var intr = createInterpreter("stdin", [std])
intr.evalScript(llStreamOpenStdIn(myRepl))
