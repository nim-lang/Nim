# issue 16754

type
  Opt[T] = object
    when T is ref:
      val: T
      x: int
    else:
      val: T
      x: string

type
  Foo = ref object
    x: Opt[Foo]

  Bar = object
    x: ref Opt[Bar]

var f = Foo()
assert f.x.x is int
var b = Bar()
assert b.x.x is string

type
  BazG[T] = object
    x: int

  BazGRef[T] = ref object
    x: T

  Baz = object
    x: Opt[BazG[Baz]]
    y: Opt[BazGRef[Baz]]

var z = Baz()
assert z.x.x is string
assert z.y.x is int

import options

type
  Person = ref object
    parent: Option[Person]

proc newPerson(parent: Option[Person]): Person =
  Person(parent: parent)

var person = newPerson(none(Person))
