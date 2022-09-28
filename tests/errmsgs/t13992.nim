discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t13992.nim(9, 5) Error: invalid type: 'None' in this context: 'seq' for let
t13992.nim(11, 7) Error: invalid type: 'None' in this context: 'array' for const
'''
"""
let test:seq = @[ "abc" ]
echo typeof test[0] 
const t2:array = ["abc"]
echo typeof t2[0]
