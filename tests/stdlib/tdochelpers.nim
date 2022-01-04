discard """
  output: '''

[Suite] Integration with Nim
'''
"""

# tests for dochelpers.nim module

import ../../lib/packages/docutils/[rstast, rst, dochelpers]
import unittest

proc rstParseTest(text: string): PRstNode =
  proc testMsgHandler(filename: string, line, col: int, msgkind: MsgKind,
                      arg: string) =
    doAssert msgkind == mwBrokenLink
  let r = rstParse(text, "-input-", LineRstInit, ColRstInit,
                   {roPreferMarkdown, roSupportMarkdown, roNimFile},
                   msgHandler=testMsgHandler)
  result = r.node

suite "Integration with Nim":
  test "simple symbol parsing (shortest form)":
    let input1 = "g_".rstParseTest
    check input1.toLangSymbol == LangSymbol(symKind: "", name: "g")

  test "simple symbol parsing (group of words)":
    let input1 = "`Y`_".rstParseTest
    check input1.toLangSymbol == LangSymbol(symKind: "", name: "Y")

    # this means not a statement 'type', it's a backticked identifier `type`:
    let input2 = "`type`_".rstParseTest
    check input2.toLangSymbol == LangSymbol(symKind: "", name: "type")

    let input3 = "`[]`_".rstParseTest
    check input3.toLangSymbol == LangSymbol(symKind: "", name: "[]")

    let input4 = "`X Y Z`_".rstParseTest
    check input4.toLangSymbol == LangSymbol(symKind: "", name: "Xyz")

  test "simple proc parsing":
    let input1 = "proc f".rstParseTest
    check input1.toLangSymbol == LangSymbol(symKind: "proc", name: "f")

  test "another backticked name":
    let input1 = """`template \`type\``_""".rstParseTest
    check input1.toLangSymbol == LangSymbol(symKind: "template", name: "type")

  test "simple proc parsing with parameters":
    let input1 = "`proc f*()`_".rstParseTest
    let input2 = "`proc f()`_".rstParseTest
    let expected = LangSymbol(symKind: "proc", name: "f",
                              parametersProvided: true)
    check input1.toLangSymbol == expected
    check input2.toLangSymbol == expected

  test "symbol parsing with 1 parameter":
    let input = "`f(G[int])`_".rstParseTest
    let expected = LangSymbol(symKind: "", name: "f",
                              parameters: @[("G[int]", "")],
                              parametersProvided: true)
    check input.toLangSymbol == expected

  test "more proc parsing":
    let input1 = "`proc f[T](x:G[T]):M[T]`_".rstParseTest
    let input2 = "`proc f[ T ] ( x: G [T] ): M[T]`_".rstParseTest
    let input3 = "`proc f*[T](x: G[T]): M[T]`_".rstParseTest
    let expected = LangSymbol(symKind: "proc",
                              name: "f",
                              generics: "[T]",
                              parameters: @[("x", "G[T]")],
                              parametersProvided: true,
                              outType: "M[T]")
    check(input1.toLangSymbol == expected)
    check(input2.toLangSymbol == expected)
    check(input3.toLangSymbol == expected)

  test "advanced proc parsing with Nim identifier normalization":
    let input = """`proc binarySearch*[T, K](a: openarray[T]; key: K;
                    cmp: proc (x: T; y: K): int)`_""".rstParseTest
    let expected = LangSymbol(symKind: "proc",
                              name: "binarysearch",
                              generics: "[T,K]",
                              parameters: @[
                                ("a", "openarray[T]"),
                                ("key", "K"),
                                ("cmp", "proc(x:T;y:K):int")],
                              parametersProvided: true,
                              outType: "")
    check(input.toLangSymbol == expected)

  test "the same without proc":
    let input = """`binarySearch*[T, K](a: openarray[T]; key: K;
                    cmp: proc (x: T; y: K): int {.closure.})`_""".rstParseTest
    let expected = LangSymbol(symKind: "",
                              name: "binarysearch",
                              generics: "[T,K]",
                              parameters: @[
                                ("a", "openarray[T]"),
                                ("key", "K"),
                                ("cmp", "proc(x:T;y:K):int")],
                              parametersProvided: true,
                              outType: "")
    check(input.toLangSymbol == expected)

  test "operator $ with and without backticks":
    let input1 = """`func \`$\`*[T](a: \`open Array\`[T]): string`_""".
                  rstParseTest
    let input2 = """`func $*[T](a: \`open Array\`[T]): string`_""".
                  rstParseTest
    let expected = LangSymbol(symKind: "func",
                              name: "$",
                              generics: "[T]",
                              parameters: @[("a", "openarray[T]")],
                              parametersProvided: true,
                              outType: "string")
    check(input1.toLangSymbol == expected)
    check(input2.toLangSymbol == expected)

  test "operator [] with and without backticks":
    let input1 = """`func \`[]\`[T](a: \`open Array\`[T], idx: int): T`_""".
                  rstParseTest
    let input2 = """`func [][T](a: \`open Array\`[T], idx: int): T`_""".
                  rstParseTest
    let expected = LangSymbol(symKind: "func",
                              name: "[]",
                              generics: "[T]",
                              parameters: @[("a", "openarray[T]"),
                                            ("idx", "int")],
                              parametersProvided: true,
                              outType: "T")
    check(input1.toLangSymbol == expected)
    check(input2.toLangSymbol == expected)

  test "postfix symbol specifier #1":
    let input = """`walkDir iterator`_""".
                  rstParseTest
    let expected = LangSymbol(symKind: "iterator",
                              name: "walkdir")
    check(input.toLangSymbol == expected)

  test "postfix symbol specifier #2":
    let input1 = """`\`[]\`[T](a: \`open Array\`[T], idx: int): T func`_""".
                  rstParseTest
    let input2 = """`[][T](a: \`open Array\`[T], idx: int): T func`_""".
                  rstParseTest
    let expected = LangSymbol(symKind: "func",
                              name: "[]",
                              generics: "[T]",
                              parameters: @[("a", "openarray[T]"),
                                            ("idx", "int")],
                              parametersProvided: true,
                              outType: "T")
    check(input1.toLangSymbol == expected)
    check(input2.toLangSymbol == expected)

  test "type of type":
    check ("`CopyFlag enum`_".rstParseTest.toLangSymbol ==
           LangSymbol(symKind: "type",
                      symTypeKind: "enum",
                      name: "Copyflag"))
