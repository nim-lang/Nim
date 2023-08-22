discard """
  matrix: "--mm:refc; --mm:orc"
"""

import unittest, strutils
import ../../lib/packages/docutils/highlite
import std/objectdollar

block: # Nim tokenizing
  test "string literals and escape seq":
    check("\"ok1\\nok2\\nok3\"".tokenize(langNim) ==
       @[("\"ok1", gtStringLit), ("\\n", gtEscapeSequence), ("ok2", gtStringLit),
         ("\\n", gtEscapeSequence), ("ok3\"", gtStringLit)
      ])
    check("\"\"\"ok1\\nok2\\nok3\"\"\"".tokenize(langNim) ==
       @[("\"\"\"ok1\\nok2\\nok3\"\"\"", gtLongStringLit)
      ])

  test "whitespace at beginning of line is preserved":
    check("  discard 1".tokenize(langNim) ==
       @[("  ", gtWhitespace), ("discard", gtKeyword), (" ", gtWhitespace),
         ("1", gtDecNumber)
       ])

block: # Cmd (shell) tokenizing
  test "cmd with dollar and output":
    check(
      dedent"""
        $ nim c file.nim
        out: file [SuccessX]"""
        .tokenize(langConsole) ==
      @[("$ ", gtPrompt), ("nim", gtProgram),
        (" ", gtWhitespace), ("c", gtOption), (" ", gtWhitespace),
        ("file.nim", gtIdentifier), ("\n", gtWhitespace),
        ("out: file [SuccessX]", gtProgramOutput)
      ])

block: # bug #21232
  let code = "/"
  var toknizr: GeneralTokenizer

  initGeneralTokenizer(toknizr, code)

  getNextToken(toknizr, langC)
  check $toknizr == """(kind: gtOperator, start: 0, length: 1, buf: "/", pos: 1, state: gtEof, lang: langC)"""
