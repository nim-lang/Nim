discard """
  output: '''
assign
destroy
destroy
5
123
destroy Foo: 123
destroy Foo: 5
(x1: (val: ...))
destroy
---------------
app begin
(val: ...)
destroy
app end
'''
joinable: false
"""

# bug #2821

type T = object

proc `=`(lhs: var T, rhs: T) =
  echo "assign"

proc `=destroy`(v: var T) =
  echo "destroy"

proc use(x: T) = discard

proc usedToBeBlock =
  var v1 = T()
  var v2: T = v1
  discard addr(v2) # prevent cursorfication
  use v1

usedToBeBlock()

# bug #1632

type
  Foo = object of RootObj
    x: int

proc `=destroy`(a: var Foo) =
  echo "destroy Foo: " & $a.x

template toFooPtr(a: int{lit}): ptr Foo =
  var temp = Foo(x:a)
  temp.addr

proc test(a: ptr Foo) =
  echo a[].x

proc main =
  test(toFooPtr(5))
  test(toFooPtr(123))

main()

# bug #11517
type
  UniquePtr*[T] = object
    val: ptr T

proc `=destroy`*[T](p: var UniquePtr[T]) =
  mixin `=destroy`
  echo "destroy"
  if p.val != nil:
    `=destroy`(p.val[])
    dealloc(p.val)
    p.val = nil

proc `=`*[T](dest: var UniquePtr[T], src: UniquePtr[T]) {.error.}

proc `=sink`*[T](dest: var UniquePtr[T], src: UniquePtr[T]) {.inline.} =
  if dest.val != src.val:
    if dest.val != nil:
      `=destroy`(dest)
    dest.val = src.val

proc newUniquePtr*[T](val: sink T): UniquePtr[T] =
  result.val = create(T)
  result.val[] = val

#-------------------------------------------------------------

type
  MyObject = object of RootObj
    x1: UniquePtr[int]

  MyObject2 = object of MyObject

proc newObj2(x:int, y: float): MyObject2 =
  MyObject2(x1: newUniquePtr(x))

proc test =
  let obj2 = newObj2(1, 1.0)
  echo obj2

test()


#------------------------------------------------------------
# Issue #12883

type
  TopObject = object
    internal: UniquePtr[int]

proc deleteTop(p: ptr TopObject) =
  if p != nil:
    `=destroy`(p[]) # !!! this operation used to leak the integer
    deallocshared(p)

proc createTop(): ptr TopObject =
  result = cast[ptr TopObject](allocShared0(sizeof(TopObject)))
  result.internal = newUniquePtr(1)

proc test2() =
  let x = createTop()
  echo $x.internal
  deleteTop(x)

echo "---------------"
echo "app begin"
test2()
echo "app end"

# bug #14601

when true: # D20200607T202043
  type Foo2 = object
    x: int
    x2: array[10, int]

  type Vec = object
    vals: seq[Foo2]

  proc `=destroy`*(a: var Foo2) {.inline.} =
    discard

  proc initFoo2(x: int): Foo2 = Foo2(x: x)

  proc add2(v: var Vec, a: Foo2) = # ditto with `a: sink Foo2`
    v.vals.add a

  proc add3(v: var Vec, a: Foo2) = # ditto with `a: sink Foo2`
    v.vals = @[a]

  proc add4(v: var Vec, a: sink Foo2) = # ditto with `a: sink Foo2`
    v.vals.add a

  proc add5(v: var Vec, a: sink Foo2) = # ditto with `a: sink Foo2`
    v.vals = @[a]

  proc main2()=
    var a: Vec
    var b = Foo2(x: 10)
    a.add2 b # ok
    a.vals.add Foo2(x: 10) # ok
    a.add2 initFoo2(x = 10) # ok
    a.add2 Foo2(x: 10) # bug
    a.add3 initFoo2(x = 10) # ok
    a.add3 Foo2(x: 10) # bug
    a.add4 initFoo2(x = 10) # ok
    a.add4 Foo2(x: 10) # bug
    a.add5 initFoo2(x = 10) # ok
    a.add5 Foo2(x: 10) # bug
  main2()



#------------------------------------------------------------
# Issue #15825

type
  Union = string | int | char

proc run(a: sink Union) =
  discard

run("123")
