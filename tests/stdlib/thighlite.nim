
import unittest, strutils
import ../../lib/packages/docutils/highlite

block: # Nim tokenizing
  test "string literals and escape seq":
    check("\"ok1\\nok2\\nok3\"".tokenize(langNim) ==
       @[("\"ok1", gtStringLit), ("\\n", gtEscapeSequence), ("ok2", gtStringLit),
         ("\\n", gtEscapeSequence), ("ok3\"", gtStringLit)
      ])
    check("\"\"\"ok1\\nok2\\nok3\"\"\"".tokenize(langNim) ==
       @[("\"\"\"ok1\\nok2\\nok3\"\"\"", gtLongStringLit)
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
