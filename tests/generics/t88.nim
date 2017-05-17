# Issue 88

type
  BaseClass[V] = object of RootObj
    b: V

proc new[V](t: typedesc[BaseClass], v: V): BaseClass[V] =
  BaseClass[V](b: v)

proc baseMethod[V](v: BaseClass[V]): V = v.b
proc overriddenMethod[V](v: BaseClass[V]): V = v.baseMethod

type
  ChildClass[V] = object of BaseClass[V]
    c: V

proc new[V](t: typedesc[ChildClass], v1, v2: V): ChildClass[V] =
  ChildClass[V](b: v1, c: v2)

proc overriddenMethod[V](v: ChildClass[V]): V = v.c

let c = ChildClass[string].new("Base", "Child")

assert c.baseMethod == "Base"
assert c.overriddenMethod == "Child"


# bug #4528
type GenericBase[T] = ref object of RootObj
type GenericSubclass[T] = ref object of GenericBase[T]
proc foo[T](g: GenericBase[T]) = discard
var bar: GenericSubclass[int]
foo(bar)
