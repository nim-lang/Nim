#[
We can't merge this test inside a `when defined(cpp)` because some bug that was
fixed would not trigger in that case.
]#

import std/compilesettings

static:
  ## bugfix 1: this used to CT error with: Error: unhandled exception: mimportcpp.nim(6, 18) `defined(cpp)`
  doAssert defined(cpp)
  doAssert querySetting(backend) == "cpp"

  ## checks that `--backend:c` has no side effect (ie, can be overridden by subsequent commands)
  doAssert not defined(c)
  doAssert not defined(js)
  doAssert not defined(js)

type
  std_exception {.importcpp: "std::exception", header: "<exception>".} = object
proc what(s: std_exception): cstring {.importcpp: "((char *)#.what())".}

var isThrown = false
try:
  ## bugfix 2: this used to CT error with: Error: only a 'ref object' can be raised
  raise std_exception()
except std_exception as ex:
  doAssert ex.what().len > 0
  isThrown = true

doAssert isThrown
