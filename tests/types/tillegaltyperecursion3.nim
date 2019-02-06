discard """
  errormsg: "invalid recursion in type 'Account'"
  line: 7
"""
# bug #10565
type
  Account = ref tuple
    children: seq[Account]
var root:Account
