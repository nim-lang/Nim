#[
ran from trunner
]#






# line 10
type Kind = enum k0, k1, k2, k3, k4

type Foo = object
  case kind: Kind
  of k0: f0: int
  of k1: f1: int
  of k2: f2: int
  of k3: f3: int
  of k4: f4: int

proc main()=
  var foo = Foo(kind: k3, f3: 3)
  let s1 = foo.f3
  doAssert s1 == 3
  let s2 = foo.f2

when defined case1:
  static: main()
when defined case2:
  main()
