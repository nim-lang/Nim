discard """
  nimout: '''
tstatret.nim(9, 7) Warning: unreachable code after 'return' statement or '{.noReturn.}' proc [UnreachableCode]
'''
"""
# no statement after return
proc main() =
  return
  echo("huch?") #ERROR_MSG statement not allowed after
