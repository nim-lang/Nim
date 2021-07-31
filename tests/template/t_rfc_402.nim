# test https://github.com/nim-lang/Nim/pull/18618
# for https://github.com/nim-lang/RFCs/issues/402

block: # test basic template overload with untyped
   template t1(x: int, body: untyped) =
      block:
         var v {.inject.} = x
         body

   template t1(body: untyped) = t1(1, body)

   static:
      doAssert compiles do: t1: discard v
      doAssert compiles do: t1(2): discard v
      doAssert compiles do: t1(echo "hello")
      doAssert not (compiles do: (t1("hello", 10)))
      doAssert not compiles(t1())
      doAssert not compiles(t1(1,2,3))

block: # test template with varargs combine untyped
   template t1(x: int, vs: varargs[string], body: untyped) =
      block:
         var v {.inject.} = x + vs.len
         body

   template t1(body: untyped) = t1(1, "hello", body)

   static:
      doAssert compiles do: t1: discard v
      doAssert compiles do: t1(2, "hello"): discard v
      doAssert not compiles((t1(2, 3): (discard v)))
      doAssert not compiles((t1("hello", "world"): (discard v)))

block: # test template with named parameter combine untyped
   template t1(x: int, y = 4, body: untyped) =
      block:
         var v {.inject.} = x + y
         body

   template t1(body: untyped) = t1(1, 3, body)

   static:
      doAssert compiles do: t1: discard v
      doAssert compiles do: t1(x = 1, 3): discard v
      doAssert not (compiles do: t1(2): discard v)
