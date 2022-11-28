discard """
  cmd: "nim check $options $file"
  action: "reject"
  nimout: '''
t20922.nim(27, 5) Error: an 'of' branch must be succeeded by an expression, but got ':'
t20922.nim(27, 3) Error: illformed AST:
of :
  '+':
    incDataPtrByte
t20922.nim(35, 7) Error: an 'of' branch must be succeeded by an expression, but got ':'
t20922.nim(35, 5) Error: illformed AST:
of :
  x: int
t20922.nim(23, 6) Hint: 'mapInstrToToken' is declared but not used [XDeclaredButNotUsed]
t20922.nim(33, 3) Hint: 'Foo' is declared but not used [XDeclaredButNotUsed]
'''
"""
# original test case issue #t20922
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
