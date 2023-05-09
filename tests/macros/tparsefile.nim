import macros

static:
  let fn = "mparsefile.nim"
  var raised = false
  try:
    discard parseStmt(staticRead(fn), filename = fn)
  except ValueError as e:
    raised = true
    doAssert e.msg == "mparsefile.nim(4, 1) Error: invalid indentation"
  doAssert raised
