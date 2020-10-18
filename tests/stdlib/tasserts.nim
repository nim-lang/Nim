#[
see also tassert2
]#

import std/asserts
import std/strutils



# line 10
block: ## checks AST isn't transformed as it used to
  let a = 1
  enforce a == 1
  try:
    enforce a > 1
  except CatchableError as e:
    echo e.msg
    assert e.msg.endsWith "tasserts.nim(15, 13) `a > 1` "
  doAssertRaises(CatchableError): enforce a > 1
