
proc bar()=
  # import mimportlocalb
  from mimportlocalb import fn1
  doAssert fn1() == 1
  doAssert declared(fn1)
bar()

doAssert not compiles(fn1())
doAssert not declared(fn1)

block:
  from mimportlocalb import fn1
  doAssert fn1() == 1
  doAssert declared(fn1)
  block:
    from mimportlocalb import fn2
    doAssert fn2() == 2
  doAssert not declared(fn2)
  proc bara() =
    from mimportlocalb import fn4
    doAssert fn4() == 4
    doAssert fn1() == 1
    doAssert not declared(fn2)
  bara()
  doAssert not declared(fn4)

doAssert not compiles(fn1())
doAssert not declared(fn1)

proc bar2[T](a: T) =
  from mimportlocalb import fn1
  doAssert fn1() == 1
  doAssert declared(fn1)
bar2(3)
doAssert not declared(fn1)
doAssert not declared(mimportlocalb)
doAssert not compiles(fn1())

proc bar3[T](a: T) =
  when T is int8:
    from mimportlocalb import fn1
    doAssert declared(fn1)
    doAssert not declared(fn2)
    doAssert fn1() == 1
  when T is int16:
    from mimportlocalb import fn2
    doAssert declared(fn2)
    doAssert not declared(fn1)
    doAssert fn2() == 2

bar3(1'i8)
bar3(1'i16)
doAssert not declared(fn1)
doAssert not declared(fn2)

proc enumList(T: typedesc): seq[T] =
  for ai in T: result.add ai

proc bar4[T](a: T) =
  block: # overloaded symbol
    from mimportlocalb import fn3
    doAssert compiles(fn3(1.0))
    doAssert compiles(fn3(1))
    doAssert declared(fn3)
    doAssert fn3(1) == 3
    doAssert fn3(1.0) == 3.5

  block: # enum
    from mimportlocalb import A3
    doAssert g0 is A3
    doAssert A3.enumList == @[g0, g1, g2]
    doAssert A3.g0 == g0

  block: # pure enum
    block:
      from mimportlocalb import A1
      doAssert k1 is A1
      doAssert A1.enumList == @[k0, k1]
      doAssert not declared(A2)
      doAssert not declared(k2)
      # let x = A1.k1

    block:
      from mimportlocalb import A2
      doAssert k2 is A2
      doAssert A2.enumList == @[k0, k2]
      doAssert not declared(A1)
      doAssert not declared(k1)

    block:
      from mimportlocalb import A1, A2
      doAssert k1 is A1
      doAssert k2 is A2
      doAssert $enumList(A1) == "@[k0, k1]"
      doAssert $enumList(A2) == "@[k0, k2]"
      # let x = A1.k1
      # let x = A1.k0
      # echo x1
      # echo A2.enumList
      # doAssert A2.enumList == @[k0, k2]
      # doAssert not declared(A1)
      # doAssert not declared(k1)

bar4(1.0)
bar4("abc")
bar4("abc2")
doAssert not compiles(fn1())
doAssert not declared(fn1)
doAssert not declared(fn2)
doAssert not declared(fn3)

when true: # `from a import b` inside generics
  proc bar5(a: auto) =
    from mimportlocalb import fn1
    echo declared(mimportlocalb)
    doAssert mimportlocalb.fn1() == 1
    doAssert fn1() == 1
  bar5(1)
