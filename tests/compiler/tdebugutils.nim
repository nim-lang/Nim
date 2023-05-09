discard """
  joinable: false
  disabled: true
"""

#[
This test illustrates some features of `debugutils` to debug the compiler.

## example
this shows how to enable compiler logging just for a section of user code,
without generating tons of unrelated log messages for code you're not interested
in debugging.

```sh
# enable some debugging code, e.g. the `when false:` block in `semExpr`
nim c -o:bin/nim_temp --stacktrace -d:debug -d:nimDebugUtils compiler/nim
bin/nim_temp c tests/compiler/tdebugutils.nim
```

(use --filenames:abs for abs files)

## result
("<", "tdebugutils.nim(16, 3)",  {.define(nimCompilerDebug).}, nil)
(">", "tdebugutils.nim(17, 3)", let a = 2.5 * 3, {}, nkLetSection)
(">", "tdebugutils.nim(17, 15)", 2.5 * 3, {efAllowDestructor, efWantValue}, nkInfix)
(">", "tdebugutils.nim(17, 11)", 2.5, {efAllowStmt, efDetermineType, efOperand}, nkFloatLit)
("<", "tdebugutils.nim(17, 11)", 2.5, float64)
(">", "tdebugutils.nim(17, 17)", 3, {efAllowStmt, efDetermineType, efOperand}, nkIntLit)
("<", "tdebugutils.nim(17, 17)", 3, int literal(3))
("<", "tdebugutils.nim(17, 15)", 2.5 * 3, float)
("<", "tdebugutils.nim(17, 3)", let a = 2.5 * 3, nil)
(">", "tdebugutils.nim(18, 3)",  {.undef(nimCompilerDebug).}, {}, nkPragma)
]#

proc main =
  {.define(nimCompilerDebug).}
  let a = 2.5 * 3
  {.undef(nimCompilerDebug).}
