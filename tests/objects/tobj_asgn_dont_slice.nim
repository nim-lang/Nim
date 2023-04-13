discard """
  matrix: "--mm:refc; --mm:arc"
"""

# bug #7637
type
  Fruit = object of RootObj
    name*: string
  Apple = object of Fruit
  Pear = object of Fruit

method eat(f: Fruit) {.base.} =
  raise newException(Exception, "PURE VIRTUAL CALL")

method eat(f: Apple) =
  echo "fruity"

method eat(f: Pear) =
  echo "juicy"

doAssertRaises(ObjectAssignmentDefect):
  proc foo =
    let basket = [Apple(name:"a"), Pear(name:"b")]
  foo()


# bug #7002
type
    BaseObj = object of RootObj
    DerivedObj = object of BaseObj

method `$`(bo: BaseObj): string {.base.} =
    return "Base"

method `$`(dob: DerivedObj): string =
    return "Derived"

type Container = object
    inner: BaseObj

doAssertRaises(ObjectAssignmentDefect):
  proc foo =
    var dob = DerivedObj()
    var cont = Container(inner: dob)
  foo()
