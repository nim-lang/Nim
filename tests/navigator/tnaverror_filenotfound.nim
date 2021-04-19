discard """
  cmd: "nim check $options --defusages:foofoo.nim,12,7 $file"
  action: "reject"
  nimout: '''cannot find file 'foofoo.nim' [ERecoverableError]'''
  errormsg: '''cannot find file 'foofoo.nim' [ERecoverableError]'''
"""

# XXX: not sure how to get this test to work