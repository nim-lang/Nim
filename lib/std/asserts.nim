import system/assertions
import std/private/miscdollars

template enforce*(cond: untyped, msg = "", typ: typedesc = CatchableError) =
  ## similar to `doAssert` but defaults to raising `CatchableError` instead of
  ## `AssertionDefect`, and allows customizing the raised exception type.
  runnableExamples:
    let a = 1
    enforce a == 1
    enforce a == 1, $(a,)
    doAssertRaises(CatchableError): enforce a == 2
    doAssertRaises(ValueError): enforce a == 2, typ = ValueError
    doAssertRaises(ValueError): enforce a == 2, $(a,), ValueError

  const
    loc = instantiationInfo(fullPaths = compileOption("excessiveStackTrace"))
    ploc = $loc
  {.line: loc.}:
    if not cond:
      const expr = astToStr(cond)
      raise newException(typ, ploc & " `" & expr & "` " & msg)
