discard """
  cmd: "nim check --warningAsError:UnreachableCode $file"
  action: "reject"
  nimout: '''
tunreachable.nim(23, 3) Error: unreachable code after 'return' statement or '{.noReturn.}' proc [UnreachableCode]
tunreachable.nim(30, 3) Error: unreachable code after 'return' statement or '{.noReturn.}' proc [UnreachableCode]
'''
"""
  
# bug #9839
template myquit1():untyped=
  ## foo
  quit(1)
template myquit2():untyped=
  echo 123
  myquit1()

proc main1()=

  # BUG: uncommenting this doesn't give `Error: unreachable statement`
  myquit2()

  echo "after"

main1()

proc main2() =
  myquit1()

  echo "after"

main2()
