discard """
cmd: "nim doc --doccmd:-d:testFooExternal --hints:off $file"
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

when true: # issue #12746
  # this proc on its own works fine with `nim doc`
  proc goodProc*() =
    runnableExamples:
      try:
        discard
      except:
        # just the general except will work
        discard

  # FIXED: this proc fails with `nim doc`
  proc badProc*() =
    runnableExamples:
      try:
        discard
      except IOError:
        # specifying Error is culprit
        discard

when true: # runnableExamples with rdoccmd
  runnableExamples "-d:testFoo -d:testBar":
    doAssert defined(testFoo) and defined(testBar)
    doAssert defined(testFooExternal)
  runnableExamples "-d:testFoo2":
    doAssert defined(testFoo2)
    doAssert not defined(testFoo) # doesn't get confused by other examples

  ## all these syntaxes work too
  runnableExamples("-d:testFoo2"): discard
  runnableExamples(): discard
  runnableExamples: discard
  runnableExamples "-r:off": # issue #10731
    doAssert false ## we compile only (-r:off), so this won't be run
  runnableExamples "-b:js":
    import std/compilesettings
    proc startsWith*(s, prefix: cstring): bool {.noSideEffect, importjs: "#.startsWith(#)".}
    doAssert querySetting(backend) == "js"
  runnableExamples "-b:cpp":
    static: doAssert defined(cpp)
    type std_exception {.importcpp: "std::exception", header: "<exception>".} = object

  proc fun2*() =
    runnableExamples "-d:foo": discard # checks that it also works inside procs

  template fun3Impl(): untyped =
    runnableExamples(rdoccmd="-d:foo"):
      nonexistant
        # bugfix: this shouldn't be semchecked when `runnableExamples`
        # has more than 1 argument
    discard

  proc fun3*[T]() =
    fun3Impl()

  when false: # future work
    # passing non-string-litterals (for reuse)
    const a = "-b:cpp"
    runnableExamples(a): discard

    # passing seq (to run with multiple compilation options)
    runnableExamples(@["-b:cpp", "-b:js"]): discard

# also check for runnableExamples at module scope
runnableExamples:
  block:
    defer: echo "foo8"

runnableExamples:
  proc fun*()=echo "foo9"
  fun()

# note: there are yet other examples where putting runnableExamples at module
# scope is needed, for example when using an `include` before an `import`, etc.

##[
snippet:

.. code-block:: Nim
    :test:

  doAssert defined(testFooExternal)

]##
