import
  macros, algorithm, strutils

proc normalProc(x: int) =
  echo x

template templateWithtouParams =
  echo 10

proc overloadedProc(x: int) =
  echo x

proc overloadedProc(x: string) =
  echo x

proc overloadedProc[T](x: T) =
  echo x

template normalTemplate(x: int) =
  echo x

template overloadedTemplate(x: int) =
  echo x

template overloadedTemplate(x: string) =
  echo x

macro normalMacro(x: int): untyped =
  discard

macro macroWithoutParams: untyped =
  discard

macro inspectSymbol(sym: typed, expected: static[string]): untyped =
  if sym.kind == nnkSym:
    echo "Symbol node:"
    let res = sym.getImpl.repr & "\n"
    echo res
    # echo "|", res, "|"
    # echo "|", expected, "|"
    if expected.len > 0: assert res == expected
  elif sym.kind in {nnkClosedSymChoice, nnkOpenSymChoice}:
    echo "Begin sym choice:"
    var results = newSeq[string](0)
    for innerSym in sym:
      results.add innerSym.getImpl.repr
    sort(results, cmp[string])
    let res = results.join("\n") & "\n"
    echo res
    if expected.len > 0: assert res == expected
    echo "End symchoice."
  else:
    echo "Non-symbol node: ", sym.kind
    if expected.len > 0: assert $sym.kind == expected

macro inspectUntyped(sym: untyped, expected: static[string]): untyped =
  let res = sym.repr
  echo "Untyped node: ", res
  assert res == expected

inspectSymbol templateWithtouParams, "nnkCommand"
  # this template is expanded, because bindSym was not used
  # the end result is the template body (nnkCommand)

inspectSymbol bindSym("templateWithtouParams"), """
template templateWithtouParams() =
  echo 10

"""

inspectSymbol macroWithoutParams, "nnkEmpty"
  # Just like the template above, the macro was expanded

inspectSymbol bindSym("macroWithoutParams"), """
macro macroWithoutParams(): untyped =
  discard

"""

inspectSymbol normalMacro, """
macro normalMacro(x: int): untyped =
  discard

"""
  # Since the normalMacro has params, it's automatically
  # treated as a symbol here (no need for `bindSym`)

inspectSymbol bindSym("normalMacro"), """
macro normalMacro(x: int): untyped =
  discard

"""

inspectSymbol normalTemplate, """
template normalTemplate(x: int) =
  echo x

"""

inspectSymbol bindSym("normalTemplate"), """
template normalTemplate(x: int) =
  echo x

"""

inspectSymbol overloadedTemplate, """
template overloadedTemplate(x: int) =
  echo x

template overloadedTemplate(x: string) =
  echo x

"""

inspectSymbol bindSym("overloadedTemplate"), """
template overloadedTemplate(x: int) =
  echo x

template overloadedTemplate(x: string) =
  echo x

"""

inspectUntyped bindSym("overloadedTemplate"), """bindSym("overloadedTemplate")"""
  # binSym is active only in the presence of `typed` params.
  # `untyped` params still get the raw AST

inspectSymbol normalProc, """
proc normalProc(x: int) =
  echo [x]

"""

inspectSymbol bindSym("normalProc"), """
proc normalProc(x: int) =
  echo [x]

"""

inspectSymbol overloadedProc, """
proc overloadedProc(x: int) =
  echo [x]

proc overloadedProc(x: string) =
  echo [x]

proc overloadedProc[T](x: T) =
  echo x

"""
  # XXX: There seems to be a repr rendering problem above.
  # Notice that `echo [x]`

inspectSymbol overloadedProc[float], """
proc overloadedProc(x: T) =
  echo [x]

"""
  # As expected, when we select a specific generic, the
  # AST is no longer a symChoice

inspectSymbol bindSym("overloadedProc"), """
proc overloadedProc(x: int) =
  echo [x]

proc overloadedProc(x: string) =
  echo [x]

proc overloadedProc[T](x: T) =
  echo x

"""

