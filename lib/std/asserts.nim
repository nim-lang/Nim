import system/assertions
import std/private/miscdollars

proc onEnforceFail[T](typ: typedesc, prefix: string, arg: T) {.noreturn, noinline.} =
  ## Making this a proc reduces size of binaries
  raise newException(typ, prefix & $arg)

template enforce*[T](cond: untyped, arg: T, typ: typedesc = EnforceError) =
  ## similar to `doAssert` but defaults to raising catchable exception
  ## instead of `AssertionDefect`, and allows customizing the raised exception type.
  # `-d:nimLeanMessages` further reduces size of binaries at expense of not
  # showing location information; in future we can avoid generating un-necessary
  # strings and forward `TLineInfo` directly (or some equivalent compact type),
  # and then defer the string rendering until needed in `onEnforceFail`,
  # reducing binary size while preserving location information. stacktraces
  # can benefit from the same optimization.
  runnableExamples:
    let a = 1
    enforce a == 1, $(a,)
    doAssertRaises(EnforceError): enforce a == 2, $(a,)
    doAssertRaises(ValueError): enforce a == 2, $(a,), ValueError
  const loc = instantiationInfo(fullPaths = compileOption("excessiveStackTrace"))
  {.line: loc.}:
    if not cond:
      const prefix =
        when defined(nimLeanMessages): ""
        else: $loc & " `" & astToStr(cond) & "` "
      onEnforceFail(typ, prefix, arg)
