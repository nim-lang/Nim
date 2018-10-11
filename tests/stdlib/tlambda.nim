discard """
"""

import macros
import lambda

import typetraits

block: # 0-param lambda
  template testLambda(fun: untyped): auto =
    makeLambda(fun, lambda)
    # doAssert: not compiles(lambda(10))
    lambda()

  doAssert testLambda(() ~> 100) == 100

block: # 1-param lambda
  template testLambda[T](fun: untyped, a:T): auto =
    makeLambda(fun, lambda)
    lambda(a)

  doAssert testLambda(a ~> a*10, 2) == 20

block: # 2-param lambda
  template testLambda[T](fun: untyped, a:T, b:T): auto =
    makeLambda(fun, lambda)
    lambda(a,b)

  doAssert testLambda((u1,u2) ~> u1*u2, 2, 3) == 2 * 3

block: # 3-param lambda
  template testLambda[T](fun: untyped, a:T, b:T, c:T): auto =
    makeLambda(fun, lambda)
    when false:
      # BUG: SIGSEGV: Illegal storage access
      doAssert: not compiles(lambda(a,b))
      # but `lambda(a,b)` correctly gives compile error
    lambda(a,b,c)

  doAssert testLambda((u1,u2,u3) ~> u1*u2*u3, 2, 3, 4) == 2 * 3 * 4

block: # multiple lambda application
  template testLambda[T](fun: untyped, a:T): auto =
    makeLambda(fun, lambda)
    lambda(lambda(a))
  doAssert testLambda(x ~> x * 3, 2) == (2 * 3) * 3

block: # lambda with local param
  template testLambda[T](fun: untyped, a:T): auto =
    makeLambda(fun, lambda)
    lambda a
  let x = 10
  doAssert testLambda(u ~> u * x, 11) == 11 * x

block: # nested lambda
  template testLambda1[T](fun: untyped, a:T): auto =
    makeLambda(fun, lambda)
    lambda(a)
  template testLambda2[T](fun: untyped, a:T): auto =
    makeLambda(fun, lambda)
    lambda a
  doAssert testLambda1(u ~> u + testLambda2(v ~> v*3, u), 100) == 100 + 100*3

block: # multiple lambdas
  template testLambda[T](fun1: untyped, fun2: untyped, a:T, b:T): auto =
    makeLambda(fun1, lambda1)
    makeLambda(fun2, lambda2)
    (lambda1(a,b), lambda2(a,b))

  doAssert testLambda((u1,u2) ~> u1*u2, (u1,u2) ~> u1+u2, 2, 3) == (2 * 3, 2 + 3)

block:
  template map2(s: typed, lambda: untyped): untyped =
    ## like ``mapIt`` but with cleaner syntax: ``[1,2].mapIt(a ~> a*10)``
    makeLambda(lambda, lambda2)
    type outType = type((
      block:
        var it: type(items(s))
        lambda2(it)
        ))

    when compiles(s.len):
      block:
        # Note: a more robust implementation would use `evalOnceAs`, see `mapIt`
        let s2=s
        var i = 0
        var result = newSeq[outType](s2.len)
        for it in s2:
          result[i] = lambda2(it)
          i += 1
        result
    else:
      var result: seq[outType] = @[]
      for it in s:
        result.add lambda2(it)
      result

  doAssert [1,2].map2(a ~> a*10) == @[10, 20]
  let foo=3
  doAssert [1,2].map2(a ~> a*foo) == @[3, 6]
