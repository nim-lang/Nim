# bug #3431

type
  Lexer = object
    buf*: string
    pos*: int
    lastchar*: char

  ASTNode = object

method init*(self: var Lexer; buf: string) {.base.} =
  self.buf = buf
  self.pos = 0
  self.lastchar = self.buf[0]

method init*(self: var ASTNode; val: string) =
  discard


# bug #3370
type
  RefTestA*[T] = ref object of RootObj
    data*: T

method tester*[S](self: S): bool =
  true

type
  RefTestB* = RefTestA[(string, int)]

method tester*(self: RefTestB): bool =
  true

type
  RefTestC = RefTestA[string]

method tester*(self: RefTestC): bool =
  false


# bug #3468

type X = ref object of RootObj
type Y = ref object of RootObj

method draw*(x: X) {.base.} = discard
method draw*(y: Y) {.base.} = discard
