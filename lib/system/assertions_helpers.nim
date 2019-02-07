# copy-pasted from system.nim, so system/assertions.nim could compile

when hostOS == "standalone":
  include "$projectpath/panicoverride"

when not declared(sysFatal):
  {.push profiler: off.}
  when hostOS == "standalone":
    proc sysFatal(exceptn: typedesc, message: string) {.inline.} =
      panic(message)

    proc sysFatal(exceptn: typedesc, message, arg: string) {.inline.} =
      rawoutput(message)
      panic(arg)
  else:
    proc sysFatal(exceptn: typedesc, message: string) {.inline, noReturn.} =
      var e: ref exceptn
      new(e)
      e.msg = message
      raise e

    proc sysFatal(exceptn: typedesc, message, arg: string) {.inline, noReturn.} =
      var e: ref exceptn
      new(e)
      e.msg = message & arg
      raise e
  {.pop.}

proc astToStr[T](x: T): string {.magic: "AstToStr", noSideEffect.}

proc instantiationInfo(index = -1, fullPaths = false): tuple[
  filename: string, line: int, column: int] {.magic: "InstantiationInfo", noSideEffect.}

include "system/helpers" # for `lineInfoToString`, `isNamedTuple`

iterator fieldPairs[T: tuple|object](x: T): RootObj {.
  magic: "FieldPairs", noSideEffect.}

proc compiles(x: untyped): bool {.magic: "Compiles", noSideEffect, compileTime.} =
  discard

proc `$`[T: tuple|object](x: T): string =
  result = "("
  var firstElement = true
  const isNamed = T is object or isNamedTuple(T)
  when not isNamed:
    var count = 0
  for name, value in fieldPairs(x):
    if not firstElement: result.add(", ")
    when isNamed:
      result.add(name)
      result.add(": ")
    else:
      count.inc
    when compiles($value):
      when value isnot string and value isnot seq and compiles(value.isNil):
        if value.isNil: result.add "nil"
        else: result.addQuoted(value)
      else:
        result.addQuoted(value)
      firstElement = false
    else:
      result.add("...")
      firstElement = false
  when not isNamed:
    if count == 1:
      result.add(",") # $(1,) should print as the semantically legal (1,)
  result.add(")")
