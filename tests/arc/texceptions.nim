discard """
  cmd: "nim cpp --gc:arc $file"
"""

block: # issue #13071
  type MyExcept = object of CatchableError
  proc gun()=
    raise newException(MyExcept, "foo:")
  proc fun()=
    var a = ""
    try:
      gun()
    except Exception as e:
      a = e.msg & $e.name # was segfaulting here for `nim cpp --gc:arc`
    doAssert a == "foo:MyExcept"
  fun()
