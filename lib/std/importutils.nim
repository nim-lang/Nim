##[
Utilities related to import and symbol resolution.

Experimental API, subject to change.
]##

#[
Possible future APIs:
* module symbols (https://github.com/nim-lang/Nim/pull/9560)
* whichModule (subsumes canImport / moduleExists) (https://github.com/timotheecour/Nim/issues/376)
* getCurrentPkgDir (https://github.com/nim-lang/Nim/pull/10530)
* import from a computed string + related APIs (https://github.com/nim-lang/Nim/pull/10527)
]#

when defined(nimImportutilsExample):
  type Foo = object
    x1: int # private
  proc initFoo*(): auto = Foo()

proc privateAccess*(t: typedesc) {.magic: "PrivateAccess".} =
  ## Enables access to private fields of `t` in current scope.
  runnableExamples("-d:nimImportutilsExample"):
    # here we're importing a module containing:
    # type Foo = object
    #   x1: int # private
    # proc initFoo*(): auto = Foo()
    var a = initFoo()
    block:
      assert not compiles(a.x1)
      privateAccess(a.type)
      a.x1 = 1 # accessible in this scope
      block:
        assert a.x1 == 1 # still in scope
    assert not compiles(a.x1)
