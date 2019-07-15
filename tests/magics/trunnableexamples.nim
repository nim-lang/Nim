discard """
cmd: "nim doc $file"
action: "compile"
nimout: '''
foo1
foo2
foo3
foo4
foo5
foo6
foo7
foo8
'''
joinable: false
"""

proc fun*() =
  runnableExamples:
    # `defer` only allowed inside a block
    defer: echo "foo1"

  runnableExamples(topLevel=false):
    defer: echo "foo2"

  runnableExamples(topLevel=true):
    # `fun*` only allowed at top level
    proc fun*()=echo "foo3"
    fun()
    block:
      defer: echo "foo4"

  runnableExamples(topLevel=true):
    # `codeReordering` only allowed at top level
    {.experimental: "codeReordering".}
    proc fun1() = fun2()
    proc fun2() = echo "foo5"
    fun1()

  runnableExamples(topLevel=true):
    # only works at top level
    import std/macros
    macro myImport(a: static string): untyped =
      newTree(nnkImportStmt, [newLit a])
    myImport "str" & "utils"
    doAssert declared(isAlphaAscii)
    echo "foo6"

# also check for runnableExamples at module scope
runnableExamples:
  defer: echo "foo7"

runnableExamples(topLevel=true):
  proc fun*()=echo "foo8"
  fun()

# note: there are yet other examples where `topLevel=true` is needed,
# for example when using an `include` before an `import`, etc.
