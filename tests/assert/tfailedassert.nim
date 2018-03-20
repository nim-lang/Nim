discard """
  output: '''
WARNING: false first assertion from bar
ERROR: false second assertion from bar
-1
tfailedassert.nim:27 false assertion from foo
'''
"""

type
  TLineInfo = tuple[filename: string, line: int, column: int]

  TMyError = object of Exception
    lineinfo: TLineInfo

  EMyError = ref TMyError

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
  # local overrides that are active only
  # in this proc
  onFailedAssert(msg): echo "WARNING: " & msg

  assert(false, "first assertion from bar")

  onFailedAssert(msg):
    echo "ERROR: " & msg
    return -1

  assert(false, "second assertion from bar")
  return 10

echo("")
echo(bar())

try:
  foo()
except:
  let e = EMyError(getCurrentException())
  echo e.lineinfo.filename, ":", e.lineinfo.line, " ", e.msg

