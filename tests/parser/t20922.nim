discard """
  cmd: "nim check $options --verbosity:0 --hints:off $file"
  action: "reject"
  nimout: '''
t20922.nim(37, 5) Error: expression expected, but found ':'
t20922.nim(45, 7) Error: expression expected, but found ':'
t20922.nim(46, 5) Error: ':' or '=' expected, but got 'keyword of'
Error: in expression ' '+'': identifier expected, but found ''
t20922.nim(37, 7) Error: attempting to call undeclared routine: '<Error>'
Error: in expression ' '+'': identifier expected, but found ''
t20922.nim(37, 7) Error: attempting to call undeclared routine: '<Error>'
t20922.nim(37, 7) Error: expression '' cannot be called
t20922.nim(37, 7) Error: expression '' has no type (or is ambiguous)
t20922.nim(37, 7) Error: VM problem: dest register is not set
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
