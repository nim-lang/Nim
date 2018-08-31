discard """
  output: '''allocating
allocating
allocating
55
60
99
deallocating
deallocating
deallocating
'''
  cmd: '''nim c --newruntime $file'''
"""

type
  SharedPtr*[T] = object
    x: ptr T

#proc isNil[T](s: SharedPtr[T]): bool {.inline.} = s.x.isNil

template incRef(x) =
  atomicInc(x.refcount)

template decRef(x): untyped = atomicDec(x.refcount)

proc makeShared*[T](x: T): SharedPtr[T] =
  # XXX could benefit from 'sink' parameter.
  # XXX could benefit from a macro that generates it.
  result = cast[SharedPtr[T]](allocShared(sizeof(x)))
  result.x[] = x
  echo "allocating"

proc `=destroy`*[T](dest: var SharedPtr[T]) =
  var s = dest.x
  if s != nil and decRef(s) == 0:
    `=destroy`(s[])
    deallocShared(s)
    echo "deallocating"
    dest.x = nil

proc `=`*[T](dest: var SharedPtr[T]; src: SharedPtr[T]) =
  var s = src.x
  if s != nil: incRef(s)
  #atomicSwap(dest, s)
  # XXX use an atomic store here:
  swap(dest.x, s)
  if s != nil and decRef(s) == 0:
    `=destroy`(s[])
    deallocShared(s)
    echo "deallocating"

proc `=sink`*[T](dest: var SharedPtr[T]; src: SharedPtr[T]) =
  ## XXX make this an atomic store:
  if dest.x != src.x:
    let s = dest.x
    if s != nil:
      `=destroy`(s[])
      deallocShared(s)
      echo "deallocating"
    dest.x = src.x

template `.`*[T](s: SharedPtr[T]; field: untyped): untyped =
  s.x.field

template `.=`*[T](s: SharedPtr[T]; field, value: untyped) =
  s.x.field = value

from macros import unpackVarargs

template `.()`*[T](s: SharedPtr[T]; field: untyped, args: varargs[untyped]): untyped =
  unpackVarargs(s.x.field, args)


type
  Tree = SharedPtr[TreeObj]
  TreeObj = object
    refcount: int
    le, ri: Tree
    data: int

proc takesTree(a: Tree) =
  if not a.isNil:
    takesTree(a.le)
    echo a.data
    takesTree(a.ri)

proc createTree(data: int): Tree =
  result = makeShared(TreeObj(refcount: 1, data: data))

proc createTree(data: int; le, ri: Tree): Tree =
  result = makeShared(TreeObj(refcount: 1, le: le, ri: ri, data: data))


proc main =
  let le = createTree(55)
  let ri = createTree(99)
  let t = createTree(60, le, ri)
  takesTree(t)

main()

