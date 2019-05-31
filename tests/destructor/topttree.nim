discard """
  output: '''10.0
60.0
90.0
120.0
10.0
60.0
90.0
120.0
8 8'''
joinable: false
"""

import typetraits

type
  opt[T] = object
    data: ptr T

var
  allocCount, deallocCount: int

proc `=destroy`*[T](x: var opt[T]) =
  if x.data != nil:
    mixin `=destroy`
    when not supportsCopyMem(T):
      `=destroy`(x.data[])
    dealloc(x.data)
    inc deallocCount
    x.data = nil

proc `=`*[T](a: var opt[T]; b: opt[T]) =
  if a.data == b.data: return
  if a.data != nil:
    dealloc(a.data)
    inc deallocCount
    a.data = nil
  if b.data != nil:
    a.data = cast[type(a.data)](alloc(sizeof(T)))
    inc allocCount
    when supportsCopyMem(T):
      copyMem(a.data, b.data, sizeof(T))
    else:
      a.data[] = b.data[]

proc `=sink`*[T](a: var opt[T]; b: opt[T]) =
  if a.data != nil and a.data != b.data:
    dealloc(a.data)
    inc deallocCount
  a.data = b.data

proc createOpt*[T](x: T): opt[T] =
  result.data = cast[type(result.data)](alloc(sizeof(T)))
  inc allocCount
  result.data[] = x

template `[]`[T](x: opt[T]): T =
  assert x.p != nil, "attempt to read from moved/destroyed value"
  x.p[]

template `?=`[T](it: untyped; x: opt[T]): bool =
  template it: untyped {.inject.} = x.data[]
  if x.data != nil:
    true
  else:
    false

type
  Tree = object
    data: float
    le, ri: opt[Tree]

proc createTree(data: float): Tree =
  result.data = data

proc insert(t: var opt[Tree]; newVal: float) =
  #if it ?= t:
  if t.data != nil:
    if newVal < t.data[].data:
      insert(t.data[].le, newVal)
    elif t.data[].data < newVal:
      insert(t.data[].ri, newVal)
    else:
      discard "already in the tree"
  else:
    t = createOpt(Tree(data: newVal))

proc write(t: opt[Tree]) =
  if it ?= t:
    write(it.le)
    write stdout, it.data, "\n"
    write(it.ri)

proc use(t: opt[Tree]) = discard

proc main =
  var t: opt[Tree]
  insert t, 60.0
  insert t, 90.0
  insert t, 10.0
  insert t, 120.0
  write t
  let copy = t
  write copy
  use t

main()
echo allocCount, " ", deallocCount
