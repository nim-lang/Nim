discard """
  cmd: "nim check $options $file"
  action: "reject"
  nimout: '''
t20922.nim(18, 5) Error: expression expected, but found ':'
Error: in expression ' '+'': identifier expected, but found ''
t20922.nim(18, 7) Error: attempting to call undeclared routine: '<Error>'
Error: in expression ' '+'': identifier expected, but found ''
t20922.nim(18, 7) Error: attempting to call undeclared routine: '<Error>'
t20922.nim(18, 7) Error: expression '' cannot be called
t20922.nim(18, 7) Error: expression '' has no type (or is ambiguous)
t20922.nim(18, 7) Error: VM problem: dest register is not set
t20922.nim(26, 7) Error: expression expected, but found ':'
t20922.nim(27, 5) Error: ':' or '=' expected, but got 'keyword of'
t20922.nim(26, 9) Error: undeclared identifier: 'x'
t20922.nim(26, 9) Error: expression 'x' has no type (or is ambiguous)
Error: in expression ' x': identifier expected, but found ''
t20922.nim(26, 9) Error: attempting to call undeclared routine: '<Error>'
Error: in expression ' x': identifier expected, but found ''
t20922.nim(26, 9) Error: attempting to call undeclared routine: '<Error>'
t20922.nim(26, 9) Error: expression '' cannot be called
t20922.nim(26, 9) Error: expression '' has no type (or is ambiguous)
t20922.nim(26, 9) Error: VM problem: dest register is not set
t20922.nim(14, 6) Hint: 'mapInstrToToken' is declared but not used [XDeclaredButNotUsed]
t20922.nim(24, 3) Hint: 'Foo' is declared but not used [XDeclaredButNotUsed]
'''
"""
# original test case issue #20922
type Token = enum
  incDataPtr,
  incDataPtrByte

proc mapInstrToToken(instr: char): Token =
  case instr:
  of '>':
    incDataPtr
  of: '+':
    incDataPtrByte

# same issue with `of` in object branches (different parser procs calling `exprList`)
type
  Bar = enum A, B
  Foo = object
    case kind: Bar
    of: x: int
    of B: y: float
