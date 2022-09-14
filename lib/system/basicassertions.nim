import std/private/assertionimpl

template assert*(cond: untyped, msg = "") =
  ## Raises `AssertionDefect` with `msg` if `cond` is false. Note
  ## that `AssertionDefect` is hidden from the effect system, so it doesn't
  ## produce `{.raises: [AssertionDefect].}`. This exception is only supposed
  ## to be caught by unit testing frameworks.
  ##
  ## No code will be generated for `assert` when passing `-d:danger` (implied by `--assertions:off`).
  ## See `command line switches <nimc.html#compiler-usage-commandminusline-switches>`_.
  runnableExamples: assert 1 == 1
  runnableExamples("--assertions:off"):
    assert 1 == 2 # no code generated, no failure here
  runnableExamples("-d:danger"): assert 1 == 2 # ditto
  assertImpl(cond, msg, astToStr(cond), compileOption("assertions"))

template doAssert*(cond: untyped, msg = "") =
  ## Similar to `assert <#assert.t,untyped,string>`_ but is always turned on regardless of `--assertions`.
  runnableExamples:
    doAssert 1 == 1 # generates code even when built with `-d:danger` or `--assertions:off`
  assertImpl(cond, msg, astToStr(cond), true)
