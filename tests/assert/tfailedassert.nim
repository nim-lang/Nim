discard """
  output: '''
true
true
true
true
MOCKEDFILE `a + a == 1` doAssert failed
MOCKEDFILE `a + a == 1` assert failed
WARNING: MOCKEDFILE `false` first assertion from bar
ERROR: MOCKEDFILE `false` second assertion from bar
-1
tfailedassert.nim MOCKEDFILE `false` assertion from foo
'''
"""

from strutils import endsWith, split
from ospaths import isAbsolute

type
  TLineInfo = tuple[filename: string, line: int, column: int]

  TMyError = object of Exception
    lineinfo: TLineInfo

  EMyError = ref TMyError

echo("")

## using real files to make sure we print what we expect and prevent
## future regressions
try:
  doAssert(false, "doAssert:realLoc")
except AssertionError as e:
  echo e.msg.endsWith("tfailedassert.nim(32, 11) `false` doAssert:realLoc")
  echo e.msg.split(' ', maxSplit = 1)[0].isAbsolute

try:
  assert false, "assert:realLoc"
except AssertionError as e:
  echo e.msg.endsWith("tfailedassert.nim(38, 10) `false` assert:realLoc")
  echo e.msg.split(' ', maxSplit = 1)[0].isAbsolute

## from now on, it's simpler to use `fakeLoc` for remainder of tests
const fakeLoc = "MOCKEDFILE"
try:
  let a = 1
  doAssert(a+a==1, "doAssert failed", fakeLoc)
  # BUG: const folding would make "1+1==1" appear as `false` in
  # assert message
except AssertionError as e:
  echo e.msg

try:
  let a = 1
  assert(a+a==1, "assert failed", fakeLoc)
except AssertionError as e:
  echo e.msg

proc foo2() =
  # protect against https://github.com/nim-lang/Nim/issues/8758
  static: doAssert(true)

# module-wide policy to change the failed assert
# exception type in order to include a lineinfo
onFailedAssert(msg):
  var e = new(TMyError)
  e.msg = msg
  e.lineinfo = instantiationInfo(-2)
  raise e

proc foo =
  assert(false, "assertion from foo", fakeLoc)

proc bar: int =
  # local overrides that are active only
  # in this proc
  onFailedAssert(msg): echo "WARNING: " & msg

  assert(false, "first assertion from bar", fakeLoc)

  onFailedAssert(msg):
    echo "ERROR: " & msg
    return -1

  assert(false, "second assertion from bar", fakeLoc)
  return 10

echo(bar())

try:
  foo()
except:
  let e = EMyError(getCurrentException())
  echo e.lineinfo.filename, " ", e.msg
