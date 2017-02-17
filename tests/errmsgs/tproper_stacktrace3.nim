discard """
  outputsub: '''tproper_stacktrace3.nim(21) main'''
  exitcode: 1
"""

# bug #5400

type Container = object
  val: int

proc actualResolver(x: ptr Container): ptr Container = x

template resolve(): untyped = actualResolver(db)

proc myfail(): int =
  doAssert false

proc main() =
  var db: ptr Container = nil
  # actualResolver(db).val = myfail() # actualResolver is not included in stack trace.
  resolve().val = myfail() # resolve template is included in stack trace.

main()
