#[
see also tassert2
]#

import std/asserts
import std/strutils



# line 10
block: ## checks AST isn't transformed as it used to
  let a = 1
  enforce a == 1, $a
  try:
    enforce a > 1, $a
  except CatchableError as e:
    assert e.msg.endsWith "tasserts.nim(15, 13) `a > 1` 1"
  doAssertRaises(CatchableError): enforce a > 1, $a
