discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t1027.nim(20, 19) Error: ambiguous identifier: 'version_str' -- use one of the following:
  m1027a.version_str: string
  m1027b.version_str: string
'''
"""






import m1027a, m1027b

# bug #1027
template wrap_me(stuff): untyped =
  echo "Using " & version_str

wrap_me("hey")
