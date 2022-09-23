discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t13992.nim(9, 5) Error: sequence expects one type parameter
t13992.nim(11, 7) Error: array expects two type parameters
'''
"""
let test:seq = @[ "abc" ]
echo typeof test[0] 
const t2:array = ["abc"]
echo typeof t2[0]
