discard """
  cmd: "nim check $file"
  action: "reject"
  nimout: '''
t8799.nim(10, 12) Error: undeclared identifier: 'on'
'''
"""

# bug #8799, bug #8822; `nim check` crashed on an error in `{.reorder: on.}`
{.reorder: on.}

proc x() =
  echo(foo)

x()
