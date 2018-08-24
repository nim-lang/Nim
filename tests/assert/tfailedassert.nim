discard """
  output: '''
test1:ok
test2:ok
test3:ok
test4:ok
test5:ok
test6:ok
test7:ok
-1
tfailedassert.nim
test7:ok
'''
"""

import testhelper

type
  TLineInfo = tuple[filename: string, line: int, column: int]
  TMyError = object of Exception
    lineinfo: TLineInfo
  EMyError = ref TMyError

echo("")


# NOTE: when entering newlines, adjust `expectedEnd` ouptuts

try:
  doAssert(false, "msg1") # doAssert test
except AssertionError as e:
  checkMsg(e.msg, "tfailedassert.nim(30, 11) `false` msg1", "test1")

try:
  assert false, "msg2"  # assert test
except AssertionError as e:
  checkMsg(e.msg, "tfailedassert.nim(35, 10) `false` msg2", "test2")

try:
  assert false # assert test with no msg
except AssertionError as e:
  checkMsg(e.msg, "tfailedassert.nim(40, 10) `false` ", "test3")

try:
  let a = 1
  doAssert(a+a==1) # assert test with Ast expression
  # BUG: const folding would make "1+1==1" appear as `false` in
  # assert message
except AssertionError as e:
  checkMsg(e.msg, "`a + a == 1` ", "test4")

try:
  let a = 1
  doAssert a+a==1 # ditto with `doAssert` and no parens
except AssertionError as e:
  checkMsg(e.msg, "`a + a == 1` ", "test5")

proc fooStatic() =
  # protect against https://github.com/nim-lang/Nim/issues/8758
  static: doAssert(true)
fooStatic()

# module-wide policy to change the failed assert
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
    checkMsg(msg, "tfailedassert.nim(80, 9) `false` first assertion from bar", "test6")

  assert(false, "first assertion from bar")

  onFailedAssert(msg):
    checkMsg(msg, "tfailedassert.nim(86, 9) `false` second assertion from bar", "test7")
    return -1

  assert(false, "second assertion from bar")
  return 10

echo(bar())

try:
  foo()
except:
  let e = EMyError(getCurrentException())
  echo e.lineinfo.filename
  checkMsg(e.msg, "tfailedassert.nim(72, 9) `false` assertion from foo", "test7")
