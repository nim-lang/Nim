#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# We produce C code as a list of tokens.

import std / assertions
import .. / ic / bitabs

type
  Token = LitId # indexing into the tokens BiTable[string]

  PredefinedToken = enum
    IgnoreMe = "<unused>"
    EmptyToken = ""
    DeclPrefix = "" # the next token is the name of a definition
    CurlyLe = "{"
    CurlyRi = "}"
    ParLe = "("
    ParRi = ")"
    BracketLe = "["
    BracketRi = "]"
    NewLine = "\n"
    Semicolon = ";"
    Comma = ", "
    Space = " "
    Colon = ":"
    Dot = "."
    Arrow = "->"
    Star = "*"
    Amp = "&"
    AsgnOpr = " = "
    ScopeOpr = "::"
    ConstKeyword = "const "
    StaticKeyword = "static "
    NimString = "NimString"
    StrLitPrefix = "(NimChar*)"
    StrLitNamePrefix = "Qstr"
    LoopKeyword = "while (true) "
    WhileKeyword = "while ("
    IfKeyword = "if ("
    ElseKeyword = "else "
    SwitchKeyword = "switch ("
    CaseKeyword = "case "
    DefaultKeyword = "default:"
    BreakKeyword = "break"
    NullPtr = "nullptr"
    IfNot = "if (!("
    ReturnKeyword = "return "

const
  ModulePrefix = Token(int(ReturnKeyword)+1)

proc fillTokenTable(tab: var BiTable[string]) =
  for e in EmptyToken..high(PredefinedToken):
    let id = tab.getOrIncl $e
    assert id == LitId(e)

type
  GeneratedCode* = object
    code: seq[LitId]
    tokens: BiTable[string]

proc initGeneratedCode*(): GeneratedCode =
  result = GeneratedCode(code: @[], tokens: initBiTable[string]())
  fillTokenTable(result.tokens)

proc add*(g: var GeneratedCode; t: PredefinedToken) {.inline.} =
  g.code.add Token(t)

proc add*(g: var GeneratedCode; s: string) {.inline.} =
  g.code.add g.tokens.getOrIncl(s)

