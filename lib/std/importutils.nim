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
  type
    Foo = object
      f0: int # private
    Goo*[T] = object
      g0: int # private
  proc initFoo*(): auto = Foo()

proc privateAccess*(t: typedesc) {.magic: "PrivateAccess".} =
  ## Enables access to private fields of `t` in current scope.
  runnableExamples("-d:nimImportutilsExample"):
    # here we're importing a module containing:
    # type
    #   Foo = object
    #     f0: int # private
    #   Goo*[T] = object
    #     g0: int # private
    # proc initFoo*(): auto = Foo()
    var f = initFoo()
    block:
      assert not compiles(f.f0)
      privateAccess(f.type)
      f.f0 = 1 # accessible in this scope
      block:
        assert f.f0 == 1 # still in scope
    assert not compiles(f.f0)

    # this also works with generics
    privateAccess(Goo)
    assert Goo[float](g0: 1).g0 == 1
