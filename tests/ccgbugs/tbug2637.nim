import future, math

{.experimental.}
{.warning[TypelessParam]: off.}

type
  ListNodeKind = enum 
    lnkNil, lnkCons
  List[T] = ref object
    ## List ADT
    case kind: ListNodeKind
    of lnkNil:
      discard
    of lnkCons:
      value: T
      next: List[T] not nil

proc Cons[T](head: T, tail: List[T]): List[T] =
  ## Constructs non empty list
  List[T](kind: lnkCons, value: head, next: tail)

proc Nil[T](): List[T] =
  ## Constructs empty list
  List[T](kind: lnkNil)

type
  OptionKind = enum
    okNone, okSome
  OptionObj[T] = object
    case kind: OptionKind
    of okNone:
      discard
    else:
      value: T
  Option[T] = ref OptionObj[T] not nil

proc Some[T](value: T): Option[T] = Option[T](kind: okSome, value: value)
proc None[T](): Option[T] = Option[T](kind: okNone)

proc isEmpty(o: Option): bool = o.kind == okNone
proc isEmpty(xs: List): bool = xs.kind == lnkNil

proc asList[T](xs: varargs[T]): List[T] =
  proc initListImpl(i: int, xs: openarray[T]): List[T] =
    if i > high(xs):
      Nil[T]()
    else:
      Cons(xs[i], initListImpl(i+1, xs))
  initListImpl(0, xs)

proc foldRight*[T,U](xs: List[T], z: U, f: (T, U) -> U): U =
  case xs.isEmpty
  of true: z
  else: f(xs.value, xs.next.foldRight(z, f))

proc sequence[T](xs: List[Option[T]]): Option[List[T]] =
  proc f(x: Option[T], v: Option[List[T]]): Option[List[T]] =
    if v.isEmpty:
      v
    elif x.isEmpty:
      Some(Nil[T]())
    else: Some(Cons(x.value, v.value))
  xs.foldRight(Some(Nil[T]()), f)

when isMainModule:
  echo: @[Some(1), Some(2), Some(3)].asList.sequence()

