#[
see also tassert2
]#

import std/exceptions
import std/strutils



# line 10
block: ## checks AST isn't transformed as it used to
  let a = 1
  enforce a == 1, $a
  var raised = false
  try:
    enforce a > 1, $a
  except EnforceError as e:
    raised = true
    doAssert e.msg.endsWith "texceptions.nim(16, 13) `a > 1` 1"
  doAssert raised
  doAssertRaises(EnforceError): enforce a > 1, $a
