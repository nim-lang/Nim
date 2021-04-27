discard """
  cmd: '''nim check --hints:off --spellSuggest:0 --filenames:legacyRelProj $file'''
  nimout: '''
tnimoutfull.nim(21, 1) Error: undeclared identifier: 'asdf4'
'''
  targets: "c"
  action: reject
"""











# line 20
asdf1
asdf2
