discard """
  output: "SUCCESS"
"""

type
    BasicNumber = object of RootObj
        value: float32
    RefChild* = ref object
        curr*: TokenObject
    Token* {.pure.} = enum
        foo,
        bar,
    TokenObject = object
        case kind*: Token
        of Token.foo:
            foo*: string
        of Token.bar:
            bar*: BasicNumber


var t = RefChild()

t.curr = TokenObject(kind: Token.bar, bar: BasicNumber(value: 12.34))

t.curr = TokenObject(kind: Token.foo, foo: "foo")

echo "SUCCESS"

proc passToVar(x: var Token) = discard

{.cast(uncheckedAssign).}:
  passToVar(t.curr.kind)

  t.curr = TokenObject(kind: t.curr.kind, foo: "abc")

  t.curr.kind = Token.foo


block:
  type
    TokenKind = enum
      strLit, intLit
    Token = object
      case kind*: TokenKind
      of strLit:
        s*: string
      of intLit:
        i*: int64

  var t = Token(kind: strLit, s: "abc")

  {.cast(uncheckedAssign).}:

    # inside the 'cast' section it is allowed to assign to the 't.kind' field directly:
    t.kind = intLit

  {.cast(uncheckedAssign).}:
    t.kind = strLit