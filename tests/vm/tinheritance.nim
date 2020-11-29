discard """
  nimout: '''Hello fred, managed by sally
Hello sally, managed by bob
0'''
"""
# bug #3973

type
  EmployeeCode = enum
    ecCode1,
    ecCode2

  Person* = object of RootObj
    name*: string
    last_name*: string

  Employee* = object of Person
    empl_code*: EmployeeCode
    mgr_name*: string

proc test() =
  var
    empl1 = Employee(name: "fred", last_name: "smith", mgr_name: "sally", empl_code: ecCode1)
    empl2 = Employee(name: "sally", last_name: "jones", mgr_name: "bob", empl_code: ecCode2)

  echo "Hello ", empl1.name, ", managed by ", empl1.mgr_name
  echo "Hello ", empl2.name, ", managed by ", empl2.mgr_name

static:
  test()

#----------------------------------------------
# Bugs #9701 and #9702
type
  MyKind = enum
    kA, kB, kC

  Base = ref object of RootObj
    x: string

  A = ref object of Base
    a: string

  B = ref object of Base
    b: string

  C = ref object of B
    c: string

template check_templ(n: Base, k: MyKind) =
  if k == kA: doAssert(n of A) else: doAssert(not (n of A))
  if k in {kB, kC}: doAssert(n of B) else: doAssert(not (n of B))
  if k == kC: doAssert(n of C) else: doAssert(not (n of C))
  doAssert(n of Base)

proc check_proc(n: Base, k: MyKind) =
  if k == kA: doAssert(n of A) else: doAssert(not (n of A))
  if k in {kB, kC}: doAssert(n of B) else: doAssert(not (n of B))
  if k == kC: doAssert(n of C) else: doAssert(not (n of C))
  doAssert(n of Base)

static:
  let aa = new(A)
  check_templ(aa, kA)
  check_proc(aa, kA)
  let bb = new(B)
  check_templ(bb, kB)
  check_proc(bb, kB)
  let cc = new(C)
  check_templ(cc, kC)
  check_proc(cc, kC)

let aa = new(A)
check_templ(aa, kA)
check_proc(aa, kA)
let bb = new(B)
check_templ(bb, kB)
check_proc(bb, kB)
let cc = new(C)
check_templ(cc, kC)
check_proc(cc, kC)

type
  BBar = object of RootObj
    bbarField: set[char]
    xbarField: string
    d, e: int
  FooBar = object of BBar
    a: int
    b: string

static:
  var fb: FooBar
  echo fb.a
