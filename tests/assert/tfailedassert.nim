discard """
  file: "tfailedassert.nim"
  exitcode: "1"
"""

type
  TLineInfo = tuple[filename: string, line: int]

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
  doAssert(false, "assertion from foo")

proc bar: int =
  # local overrides that are active only
  # in this proc
  onFailedAssert(msg): echo "WARNING: " & msg

  doAssert(false, "first assertion from bar")

  onFailedAssert(msg):
    echo "ERROR: " & msg
    return -1

  doAssert(false, "second assertion from bar")
  return 10

echo("")
echo(bar())

try:
  foo()
except:
  let e = EMyError(getCurrentException())
  echo e.lineinfo.filename, ":", e.lineinfo.line, " ", e.msg
