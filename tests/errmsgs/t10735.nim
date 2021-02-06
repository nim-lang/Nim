discard """
  cmd: "nim check $file"
  errormsg: "illformed AST"
  nimout: '''
t10735.nim(38, 5) Error: 'let' symbol requires an initialization
t10735.nim(39, 10) Error: undeclared identifier: 'pos'
t10735.nim(41, 3) Error: illformed AST: case buf[pos]
'''
  joinable: false
"""



























let buf: cstring
case buf[pos]
else:
  case buf[pos]
