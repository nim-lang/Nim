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
