discard """
  cmd: "nim check $options $file"
  action: "reject"
  nimout: '''
t15667.nim(23, 5) Error: invalid indentation, maybe you forgot a '=' at t15667.nim(22, 13) ?
t15667.nim(28, 5) Error: invalid indentation, maybe you forgot a '=' at t15667.nim(26, 13) ?
t15667.nim(33, 5) Error: invalid indentation, maybe you forgot a '=' at t15667.nim(31, 25) ?
t15667.nim(42, 5) Error: invalid indentation, maybe you forgot a '=' at t15667.nim(38, 12) ?
t15667.nim(56, 5) Error: invalid indentation, maybe you forgot a '=' at t15667.nim(55, 13) ?
t15667.nim(61, 48) Error: expression expected, but found ','
'''
"""







# line 20
block:
  proc fn1()
    discard

block:
  proc fn2()
    #
    discard

block:
  proc fn3() {.exportc.}
    #
    discard

block: # complex example
  proc asdfasdfsd() {. exportc, 
      inline
         .}     # foo
    #[
    bar
    ]#
    discard

block: # xxx this doesn't work yet (only a bare `invalid indentation` error)
  proc fn5()
    ##
    discard

block: # ditto
  proc fn6*()
    ## foo bar
    runnableExamples: discard

block:
  proc fn8()
    runnableExamples:
      discard
    discard

# semiStmtList loop issue
proc bar(k:static bool):SomeNumber = (when k: 3, else: 3.0)
