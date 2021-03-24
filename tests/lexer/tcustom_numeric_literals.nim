discard """
  targets: "c cpp js"
"""

# Test tkStrNumLit

import std/[macros, strutils]
import mlexerutils

# AST checks

assertAST dedent """
  StmtList
    ProcDef
      AccQuoted
        Ident "\'"
        Ident "wrap"
      Empty
      Empty
      FormalParams
        Ident "string"
        IdentDefs
          Ident "number"
          Ident "string"
          Empty
      Empty
      Empty
      StmtList
        Asgn
          Ident "result"
          Infix
            Ident "&"
            Infix
              Ident "&"
              StrLit "[["
              Ident "number"
            StrLit "]]"""":
  proc `'wrap`(number: string): string =
    result = "[[" & number & "]]"

assertAST dedent """
  StmtList
    DotExpr
      RStrLit "-38383839292839283928392839283928392839283.928493849385935898243e-50000"
      Ident "\'wrap"""":
  -38383839292839283928392839283928392839283.928493849385935898243e-50000'wrap

proc `'wrap`(number: string): string = "[[" & number & "]]"
doAssert lispReprStr(-1'wrap) == """(DotExpr (RStrLit "-1") (Ident "\'wrap"))"""

template main =
  block: # basic suffix usage
    template `'twrap`(number: string): untyped =
      number.`'wrap`
    proc extraContext(): string =
      22.40'wrap
    proc `*`(left, right: string): string =
      result = left & "times" & right
    proc `+`(left, right: string): string =
      result = left & "plus" & right

    doAssert 1'wrap == "[[1]]"
    doAssert -1'wrap == "[[-1]]":
      "unable to resolve a negative integer-suffix pattern"
    doAssert 12345.67890'wrap == "[[12345.67890]]"
    doAssert 1'wrap*1'wrap == "[[1]]times[[1]]":
      "unable to resolve an operator between two suffixed numeric literals"
    doAssert 1'wrap+ -1'wrap == "[[1]]plus[[-1]]":  # will generate a compiler warning about inconsistent spacing
      "unable to resolve a negative suffixed numeric literal following an operator"
    doAssert 1'wrap + -1'wrap == "[[1]]plus[[-1]]"
    doAssert 1'twrap == "[[1]]"
    doAssert extraContext() == "[[22.40]]":
      "unable to return a suffixed numeric literal by an implicit return"
    doAssert 0x5a3a'wrap == "[[0x5a3a]]"
    doAssert 0o5732'wrap == "[[0o5732]]"
    doAssert 0b0101111010101'wrap == "[[0b0101111010101]]"
    doAssert -38383839292839283928392839283928392839283.928493849385935898243e-50000'wrap == "[[-38383839292839283928392839283928392839283.928493849385935898243e-50000]]"
    doAssert 1234.56'wrap == "[[1234.56]]":
      "unable to properly account for context with suffixed numeric literals"

  block: # verify that the i64, f32, etc builtin suffixes still parse correctly
    const expectedF32: float32 = 123.125
    proc `'f9`(number: string): string =   # proc starts with 'f' just like 'f32'
      "[[" & number & "]]"
    proc `'f32a`(number: string): string =   # looks even more like 'f32'
      "[[" & number & "]]"
    proc `'d9`(number: string): string =   # proc starts with 'd' just like the d suffix
      "[[" & number & "]]"
    proc `'i9`(number: string): string =   # proc starts with 'i' just like 'i64'
      "[[" & number & "]]"
    proc `'u9`(number: string): string =   # proc starts with 'u' just like 'u8'
      "[[" & number & "]]"

    doAssert 123.125f32 == expectedF32:
      "failing to support non-quoted legacy f32 floating point suffix"
    doAssert 123.125'f32 == expectedF32
    doAssert 123.125e0'f32 == expectedF32
    doAssert 1234.56'wrap == 1234.56'f9
    doAssert 1234.56'wrap == 1234.56'f32a
    doAssert 1234.56'wrap == 1234.56'd9
    doAssert 1234.56'wrap == 1234.56'i9
    doAssert 1234.56'wrap == 1234.56'u9
    doAssert lispReprStr(1234.56'u9) == """(DotExpr (RStrLit "1234.56") (Ident "\'u9"))""":
      "failed to properly build AST for suffix that starts with u"
    doAssert -128'i8 == (-128).int8

  block: # case checks
    doAssert 1E2 == 100:
      "lexer not handling upper-case exponent"
    doAssert 1.0E2 == 100.0
    doAssert 1e2 == 100
    doAssert 0xdeadBEEF'wrap == "[[0xdeadBEEF]]":
      "lexer not maintaining original case"
    doAssert 0.1E12'wrap == "[[0.1E12]]"
    doAssert 0.0e12'wrap == "[[0.0e12]]"
    doAssert 0.0e+12'wrap == "[[0.0e+12]]"
    doAssert 0.0e-12'wrap == "[[0.0e-12]]"
    doAssert 0e-12'wrap == "[[0e-12]]"

  block: # macro and template usage
    template `'foo`(a: string): untyped = (a, 2)
    doAssert -12'foo == ("-12", 2)
    template `'fooplus`(a: string, b: int): untyped = (a, b)
    doAssert -12'fooplus(2) == ("-12", 2)
    template `'fooplusopt`(a: string, b: int = 99): untyped = (a, b)
    doAssert -12'fooplusopt(2) == ("-12", 2)
    doAssert -12'fooplusopt() == ("-12", 99)
    doAssert -12'fooplusopt == ("-12", 99)
    macro `'bar`(a: static string): untyped =
      var infix = newNimNode(nnkInfix)
      infix.add newIdentNode("&")
      infix.add newLit("got ")
      infix.add newLit(a.repr)
      result = newNimNode(nnkStmtList)
      result.add infix
    doAssert -12'bar == "got \"-12\""
    macro deb(a): untyped = newLit(a.repr)
    doAssert deb(-12'bar) == "-12'bar"
    # macro metawrap(): untyped =
    #   func wrap1(a: string): string = "{" & a & "}"
    #   func `'wrap2`(a: string): string = "{" & a & "}"
    #   result = quote do:
    #     let a1 = wrap1"-128"
    #     let a2 = -128'wrap2
    # metawrap()
    # doAssert a1 == "{-128}"
    # doAssert a2 == "{-128}"

static: main()
main()
