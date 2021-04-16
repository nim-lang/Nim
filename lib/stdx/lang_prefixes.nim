##[
This module allows annotating string literals with a language prefix which can be
exploited by tooling (e.g. for language specific syntax highlighting or linting).
]##

runnableExamples:
  # syntax highlighters can recognize `highlight"""js` and highlight the string as js.
  let a = highlight"""js
var a = 3n;
var b = 4n;"""
  doAssert a == "var a = 3n;\nvar b = 4n;" # js prefix is removed.

  # works with emit sections
  {.emit: highlight"""c
/*INCLUDESECTION*/
#include <stdio.h>""".}

  # works with emit strings containing backticks.
  proc fn(n: int): int =
    {.emit: highlight"""c
`result` = 3 * `n`; /* comment */
""".}
  doAssert fn(2) == 3 * 2

  # works with strutils.dedent
  from std/strutils import dedent
  let a2 = highlight"""cpp
    #include <vector>
    typedef std::vector<int> VInt; // some comment
    """.dedent
  assert a2 == "#include <vector>\ntypedef std::vector<int> VInt; // some comment\n"

  # one liner example
  let a3 = highlight"""js console.log(typeof(12n) == "bigint");"""
  assert a3 == """console.log(typeof(12n) == "bigint");"""

  # `highlight` avoids inherient ambiguities for syntax highlighters;
  # `asm """ ... """` could mean either assembly or js depending on backend so
  # cannot be highlighted correctly by itself.
  const a4 = highlight"""asm
    mov eax, ecx ; comment
    mov ecx, edx
    xor edx, edx
    call `raiseOverflow` ; backtick syntax
    ret """
  when false:
    {.emit: a4.} # example showing defered use of a literal in an emit statement.

  const nimModule = highlight"""nim
import std/os
echo @[1, 2]
"""
  # use `nimModule`, e.g. with `macros.parseStmt` or `writeFile`.

#[
xxx support in compiler asm with a non-string-literal, e.g.:
  asm highlight"""js console.log(typeof(12n) == "bigint");"""
  asm highlight"""asm mov eax, ecx"""
  asm highlight"""cpp #include <stdio.h>"""
]#

proc highlightImpl(a: string): string =
  for i in 0..<a.len:
    if a[i] == '\n' or a[i] == ' ':
      return a[i+1..a.len-1]

template highlight*(a: string{lit}): string =
  ## returns `a` stripped from its language prefix, see examples.
  const b = highlightImpl(a)
  b
