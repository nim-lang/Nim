discard """
action: compile
"""

# bug #3313
import unittest, sugar
{.experimental: "notnil".}
type
  ListNodeKind = enum
    lnkNil, lnkCons
  List*[T] = ref object
    ## List ADT
    case kind: ListNodeKind
    of lnkNil:
      discard
    of lnkCons:
      value: T
      next: List[T] not nil

proc Cons*[T](head: T, tail: List[T]): List[T] =
  ## Constructs non empty list
  List[T](kind: lnkCons, value: head, next: tail)

proc Nil*[T](): List[T] =
  ## Constructs empty list
  List[T](kind: lnkNil)

proc head*[T](xs: List[T]): T =
  ## Returns list's head
  xs.value

# TODO
# proc headOption*[T](xs: List[T]): Option[T] = ???

proc tail*[T](xs: List[T]): List[T] =
  ## Returns list's tail
  case xs.kind
  of lnkCons: xs.next
  else: xs

proc isEmpty*(xs: List): bool =
  ## Checks  if list is empty
  xs.kind == lnkNil

proc `==`*[T](xs, ys: List[T]): bool =
  ## Compares two lists
  if (xs.isEmpty, ys.isEmpty) == (true, true): true
  elif (xs.isEmpty, ys.isEmpty) == (false, false): xs.head == ys.head and xs.tail == ys.tail
  else: false

proc asList*[T](xs: varargs[T]): List[T] =
  ## Creates list from varargs
  proc initListImpl(i: int, xs: openArray[T]): List[T] =
    if i > high(xs):
      Nil[T]()
    else:
      Cons(xs[i], initListImpl(i+1, xs))
  initListImpl(0, xs)

proc foldRight*[T,U](xs: List[T], z: U, f: (T, U) -> U): U =
  case xs.isEmpty
  of true: z
  else: f(xs.head, xs.tail.foldRight(z, f))

proc dup*[T](xs: List[T]): List[T] =
  ## Duplicates the list
  xs.foldRight(Nil[T](), (x: T, xs: List[T]) => Cons(x, xs))

type
  ListFormat = enum
    lfADT, lfSTD

proc asString[T](xs: List[T], f = lfSTD): string =
  proc asAdt(xs: List[T]): string =
    case xs.isEmpty
    of true: "Nil"
    else: "Cons(" & $xs.head & ", " & xs.tail.asAdt & ")"

  proc asStd(xs: List[T]): string =
    "List(" & xs.foldLeft("", (s: string, v: T) =>
      (if s == "": $v else: s & ", " & $v)) & ")"

  case f
  of lfADT: xs.asAdt
  else: xs.asStd

proc `$`*[T](xs: List[T]): string =
  ## Converts list to string
  result = xs.asString

proc foldLeft*[T,U](xs: List[T], z: U, f: (U, T) -> U): U =
  case xs.isEmpty
  of true: z
  else: foldLeft(xs.tail, f(z, xs.head), f)
