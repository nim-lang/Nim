discard """
  output: '''foo88
23 24foo 88
18
18
99
99
99
99 99
99 99
12 99 99
12 99 99'''
"""

when true:
  # test simple closure within dummy 'main':
  proc dummy =
    proc main2(param: int) =
      var fooB = 23
      proc outer(outerParam: string) =
        var outerVar = 88
        echo outerParam, outerVar
        proc inner() =
          block Test:
            echo fooB, " ", param, outerParam, " ", outerVar
        inner()
      outer("foo")
    main2(24)

  dummy()

when true:
  proc outer2(x:int) : proc(y:int):int =   # curry-ed application
      return proc(y:int):int = x*y

  var fn = outer2(6)  # the closure
  echo fn(3)   # it works

  var rawP = fn.rawProc()
  var rawE = fn.rawEnv()

  # A type to cast the function pointer into a nimcall
  type
    TimesClosure = proc(a: int, x: pointer): int {.nimcall.}

  # Call the function with its closure
  echo cast[TimesClosure](rawP)(3, rawE)

when true:
  proc outer =
    var x, y: int = 99
    proc innerA = echo x
    proc innerB =
      echo y
      innerA()

    innerA()
    innerB()

  outer()

when true:
  proc indirectDep =
    var x, y: int = 99
    proc innerA = echo x, " ", y
    proc innerB =
      innerA()

    innerA()
    innerB()

  indirectDep()

when true:
  proc needlessIndirection =
    var x, y: int = 99
    proc indirection =
      var z = 12
      proc innerA = echo z, " ", x, " ", y
      proc innerB =
        innerA()

      innerA()
      innerB()
    indirection()

  needlessIndirection()
