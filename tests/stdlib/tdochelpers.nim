discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''

[Suite] Integration with Nim
'''
"""

# tests for dochelpers.nim module

import ../../lib/packages/docutils/[rstast, rst, dochelpers]
import unittest
import std/assertions

proc testMsgHandler(filename: string, line, col: int, msgkind: MsgKind,
                    arg: string) =
  doAssert msgkind == mwBrokenLink

proc fromRst(text: string): LangSymbol =
  let r = rstParse(text, "-input-", LineRstInit, ColRstInit,
                   {roNimFile},
                   msgHandler=testMsgHandler)
  assert r.node.kind == rnRstRef
  result = toLangSymbol(r.node)

proc fromMd(text: string): LangSymbol =
  let r = rstParse(text, "-input-", LineRstInit, ColRstInit,
                   {roPreferMarkdown, roSupportMarkdown, roNimFile},
                   msgHandler=testMsgHandler)
  assert r.node.kind == rnPandocRef
  assert r.node.len == 2
  # this son is the target:
  assert r.node.sons[1].kind == rnInner
  result = toLangSymbol(r.node.sons[1])

suite "Integration with Nim":
  test "simple symbol parsing (shortest form)":
    let expected = LangSymbol(symKind: "", name: "g")
    check "g_".fromRst == expected
    check "[g]".fromMd == expected
    # test also alternative syntax variants of Pandoc Markdown:
    check "[g][]".fromMd == expected
    check "[this symbol][g]".fromMd == expected

  test "simple symbol parsing (group of words)":
    #let input1 = "`Y`_".rstParseTest
    let expected1 = LangSymbol(symKind: "", name: "Y")
    check "`Y`_".fromRst == expected1
    check "[Y]".fromMd == expected1

    # this means not a statement 'type', it's a backticked identifier `type`:
    let expected2 = LangSymbol(symKind: "", name: "type")
    check "`type`_".fromRst == expected2
    check "[type]".fromMd == expected2

    let expected3 = LangSymbol(symKind: "", name: "[]")
    check "`[]`_".fromRst == expected3
    # Markdown syntax for this case is NOT [[]]
    check "[`[]`]".fromMd == expected3

    let expected4 = LangSymbol(symKind: "", name: "Xyz")
    check "`X Y Z`_".fromRst == expected4
    check "[X Y Z]".fromMd == expected4

  test "simple proc parsing":
    let expected = LangSymbol(symKind: "proc", name: "f")
    check "`proc f`_".fromRst == expected
    check "[proc f]".fromMd == expected

  test "another backticked name":
    let expected = LangSymbol(symKind: "template", name: "type")
    check """`template \`type\``_""".fromRst == expected
    # no backslash in Markdown:
    check """[template `type`]""".fromMd == expected

  test "simple proc parsing with parameters":
    let expected = LangSymbol(symKind: "proc", name: "f",
                              parametersProvided: true)
    check "`proc f*()`_".fromRst == expected
    check "`proc f()`_".fromRst == expected
    check "[proc f*()]".fromMd == expected
    check "[proc f()]".fromMd == expected

  test "symbol parsing with 1 parameter":
    let expected = LangSymbol(symKind: "", name: "f",
                              parameters: @[("G[int]", "")],
                              parametersProvided: true)
    check "`f(G[int])`_".fromRst == expected
    check "[f(G[int])]".fromMd == expected

  test "more proc parsing":
    let input1 = "`proc f[T](x:G[T]):M[T]`_".fromRst
    let input2 = "`proc f[ T ] ( x: G [T] ): M[T]`_".fromRst
    let input3 = "`proc f*[T](x: G[T]): M[T]`_".fromRst
    let expected = LangSymbol(symKind: "proc",
                              name: "f",
                              generics: "[T]",
                              parameters: @[("x", "G[T]")],
                              parametersProvided: true,
                              outType: "M[T]")
    check(input1 == expected)
    check(input2 == expected)
    check(input3 == expected)

  test "advanced proc parsing with Nim identifier normalization":
    let inputRst = """`proc binarySearch*[T, K](a: openarray[T]; key: K;
                       cmp: proc (x: T; y: K): int)`_"""
    let inputMd = """[proc binarySearch*[T, K](a: openarray[T]; key: K;
                       cmp: proc (x: T; y: K): int)]"""
    let expected = LangSymbol(symKind: "proc",
                              name: "binarysearch",
                              generics: "[T,K]",
                              parameters: @[
                                ("a", "openarray[T]"),
                                ("key", "K"),
                                ("cmp", "proc(x:T;y:K):int")],
                              parametersProvided: true,
                              outType: "")
    check(inputRst.fromRst == expected)
    check(inputMd.fromMd == expected)

  test "the same without proc":
    let input = """`binarySearch*[T, K](a: openarray[T]; key: K;
                    cmp: proc (x: T; y: K): int {.closure.})`_"""
    let expected = LangSymbol(symKind: "",
                              name: "binarysearch",
                              generics: "[T,K]",
                              parameters: @[
                                ("a", "openarray[T]"),
                                ("key", "K"),
                                ("cmp", "proc(x:T;y:K):int")],
                              parametersProvided: true,
                              outType: "")
    check(input.fromRst == expected)
    let inputMd = """[binarySearch*[T, K](a: openarray[T]; key: K;
                      cmp: proc (x: T; y: K): int {.closure.})]"""
    check(inputMd.fromMd == expected)

  test "operator $ with and without backticks":
    let input1 = """`func \`$\`*[T](a: \`open Array\`[T]): string`_"""
    let input1md = "[func `$`*[T](a: `open Array`[T]): string]"
    let input2 = """`func $*[T](a: \`open Array\`[T]): string`_"""
    let input2md = "[func $*[T](a: `open Array`[T]): string]"
    let expected = LangSymbol(symKind: "func",
                              name: "$",
                              generics: "[T]",
                              parameters: @[("a", "openarray[T]")],
                              parametersProvided: true,
                              outType: "string")
    check input1.fromRst == expected
    check input2.fromRst == expected
    check input1md.fromMd == expected
    check input2md.fromMd == expected

  test "operator [] with and without backticks":
    let input1 = """`func \`[]\`[T](a: \`open Array\`[T], idx: int): T`_"""
    let input1md = "[func `[]`[T](a: `open Array`[T], idx: int): T]"
    let input2 = """`func [][T](a: \`open Array\`[T], idx: int): T`_"""
    let input2md = "[func [][T](a: `open Array`[T], idx: int): T]"
    let expected = LangSymbol(symKind: "func",
                              name: "[]",
                              generics: "[T]",
                              parameters: @[("a", "openarray[T]"),
                                            ("idx", "int")],
                              parametersProvided: true,
                              outType: "T")
    check input1.fromRst == expected
    check input2.fromRst == expected
    check input1md.fromMd == expected
    check input2md.fromMd == expected

  test "postfix symbol specifier #1":
    let input = "`walkDir iterator`_"
    let inputMd = "[walkDir iterator]"
    let expected = LangSymbol(symKind: "iterator",
                              name: "walkdir")
    check input.fromRst == expected
    check inputMd.fromMd == expected

  test "postfix symbol specifier #2":
    let input1 = """`\`[]\`[T](a: \`open Array\`[T], idx: int): T func`_"""
    let input1md = "[`[]`[T](a: `open Array`[T], idx: int): T func]"
    let input2 = """`[][T](a: \`open Array\`[T], idx: int): T func`_"""
    # note again that ` is needed between 1st and second [
    let input2md = "[`[]`[T](a: `open Array`[T], idx: int): T func]"
    let expected = LangSymbol(symKind: "func",
                              name: "[]",
                              generics: "[T]",
                              parameters: @[("a", "openarray[T]"),
                                            ("idx", "int")],
                              parametersProvided: true,
                              outType: "T")
    check input1.fromRst == expected
    check input2.fromRst == expected
    check input1md.fromMd == expected
    check input2md.fromMd == expected

  test "type of type":
    let inputRst = "`CopyFlag enum`_"
    let inputMd = "[CopyFlag enum]"
    let expected = LangSymbol(symKind: "type",
                              symTypeKind: "enum",
                              name: "Copyflag")
    check inputRst.fromRst == expected
    check inputMd.fromMd == expected

  test "prefixed module":
    let inputRst = "`module std / paths`_"
    let inputMd = "[module std / paths]"
    let expected = LangSymbol(symKind: "module",
                              name: "std/paths")
    check inputRst.fromRst == expected
    check inputMd.fromMd == expected

  test "postfixed module":
    let inputRst = "`std / paths module`_"
    let inputMd = "[std / paths module]"
    let expected = LangSymbol(symKind: "module",
                              name: "std/paths")
    check inputRst.fromRst == expected
    check inputMd.fromMd == expected
