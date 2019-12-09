discard """
cmd: "nim doc $file"
action: "compile"
nimout: '''
foo1
foo2
foo3
foo5
foo6
foo7
foo8
foo9
'''
joinable: false
"""

proc fun*() =
  runnableExamples:
    block: # `defer` only allowed inside a block
      defer: echo "foo1"

  runnableExamples:
    # `fun*` only allowed at top level
    proc fun*()=echo "foo2"
    fun()
    block:
      defer: echo "foo3"

  runnableExamples:
    # ditto
    proc fun*()=echo "foo5"
    fun()

  runnableExamples:
    # `codeReordering` only allowed at top level
    {.experimental: "codeReordering".}
    proc fun1() = fun2()
    proc fun2() = echo "foo6"
    fun1()

  runnableExamples:
    # only works at top level
    import std/macros
    macro myImport(a: static string): untyped =
      newTree(nnkImportStmt, [newLit a])
    myImport "str" & "utils"
    doAssert declared(isAlphaAscii)
    echo "foo7"

# also check for runnableExamples at module scope
runnableExamples:
  block:
    defer: echo "foo8"

runnableExamples:
  proc fun*()=echo "foo9"
  fun()

# note: there are yet other examples where putting runnableExamples at module
# scope is needed, for example when using an `include` before an `import`, etc.
