discard """
  output: '''
`false` first assertion from bar
`false` second assertion from bar
-1
'''
"""
from strutils import endsWith

type
  TLineInfo = tuple[filename: string, line: int, column: int]
  TMyError = object of Exception
    lineinfo: TLineInfo
  EMyError = ref TMyError


# NOTE: when entering newlines, adjust `expectedEnd` outputs

try:
  doAssert(false, "msg1") # doAssert test
except AssertionDefect as e:
  assert e.msg.endsWith "tassert2.nim(20, 11) `false` msg1"

try:
  assert false # assert test with no msg
except AssertionDefect as e:
  assert e.msg.endsWith "tassert2.nim(25, 10) `false` "

try:
  let a = 1
  doAssert(a+a==1) # assert test with Ast expression
  # BUG: const folding would make "1+1==1" appear as `false` in
  # assert message
except AssertionDefect as e:
  assert e.msg.endsWith "`a + a == 1` "

try:
  let a = 1
  doAssert a+a==1 # ditto with `doAssert` and no parens
except AssertionDefect as e:
  assert e.msg.endsWith "`a + a == 1` "

proc fooStatic() =
  # protect against https://github.com/nim-lang/Nim/issues/8758
  static: doAssert(true)
fooStatic()





block:
  # scope-wide policy to change the failed assert
  # exception type in order to include a lineinfo
  onFailedAssert(msg):
    var e = new(TMyError)
    e.msg = msg
    e.lineinfo = instantiationInfo(-2)
    raise e

  proc foo =
    assert(false, "assertion from foo")


  proc bar: int =
    # local overrides that are active only in this proc
    onFailedAssert(msg):
      echo msg[^32..^1]

    assert(false, "first assertion from bar")

    onFailedAssert(msg):
      echo msg[^33..^1]
      return -1

    assert(false, "second assertion from bar")
    return 10

  echo(bar())

  try:
    foo()
  except:
    let e = EMyError(getCurrentException())
    assert e.msg.endsWith "tassert2.nim(62, 11) `false` assertion from foo"

block: ## checks for issue https://github.com/nim-lang/Nim/issues/8518
  template fun(a: string): string =
      const pattern = a & a
      pattern

  try:
    doAssert fun("foo1") == fun("foo2"), "mymsg"
  except AssertionDefect as e:
    # used to expand out the template instantiaiton, sometimes filling hundreds of lines
    assert e.msg.endsWith ""

block: ## checks for issue https://github.com/nim-lang/Nim/issues/9301
  try:
    doAssert 1 + 1 == 3
  except AssertionDefect as e:
    # used to const fold as false
    assert e.msg.endsWith "tassert2.nim(100, 14) `1 + 1 == 3` "

block: ## checks AST isn't transformed as it used to
  let a = 1
  try:
    doAssert a > 1
  except AssertionDefect as e:
    # used to rewrite as `1 < a`
    assert e.msg.endsWith "tassert2.nim(108, 14) `a > 1` "
