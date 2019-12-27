discard """
  targets: "c cpp"
  output: "OK"
"""

type
  GRBase[T] = ref object of RootObj
    val: T
  GRC[T] = ref object of GRBase[T]
  GRD[T] = ref object of GRBase[T]

proc testGR[T](x: varargs[GRBase[T]]): string =
  result = ""
  for c in x:
    result.add $c.val

block test_t4799_1:
  var rgv = GRBase[int](val: 3)
  var rgc = GRC[int](val: 4)
  var rgb = GRD[int](val: 2)
  doAssert(testGR(rgb, rgc, rgv) == "243")
  doAssert(testGR(rgc, rgv, rgb) == "432")
  doAssert(testGR(rgv, rgb, rgc) == "324")
  doAssert(testGR([rgb, rgc, rgv]) == "243")
  doAssert(testGR([rgc, rgv, rgb]) == "432")
  doAssert(testGR([rgv, rgb, rgc]) == "324")

type
  PRBase[T] = object of RootObj
    val: T
  PRC[T] = object of PRBase[T]
  PRD[T] = object of PRBase[T]

proc testPR[T](x: varargs[ptr PRBase[T]]): string =
  result = ""
  for c in x:
    result.add $c.val

block test_t4799_2:
  var pgv = PRBase[int](val: 3)
  var pgc = PRC[int](val: 4)
  var pgb = PRD[int](val: 2)
  doAssert(testPR(pgb.addr, pgc.addr, pgv.addr) == "243")
  doAssert(testPR(pgc.addr, pgv.addr, pgb.addr) == "432")
  doAssert(testPR(pgv.addr, pgb.addr, pgc.addr) == "324")
  doAssert(testPR([pgb.addr, pgc.addr, pgv.addr]) == "243")
  doAssert(testPR([pgc.addr, pgv.addr, pgb.addr]) == "432")
  doAssert(testPR([pgv.addr, pgb.addr, pgc.addr]) == "324")

type
  RBase = ref object of RootObj
    val: int
  RC = ref object of RBase
  RD = ref object of RBase

proc testR(x: varargs[RBase]): string =
  result = ""
  for c in x:
    result.add $c.val

block test_t4799_3:
  var rv = RBase(val: 3)
  var rc = RC(val: 4)
  var rb = RD(val: 2)
  doAssert(testR(rb, rc, rv) == "243")
  doAssert(testR(rc, rv, rb) == "432")
  doAssert(testR(rv, rb, rc) == "324")
  doAssert(testR([rb, rc, rv]) == "243")
  doAssert(testR([rc, rv, rb]) == "432")
  doAssert(testR([rv, rb, rc]) == "324")

type
  PBase = object of RootObj
    val: int
  PC = object of PBase
  PD = object of PBase

proc testP(x: varargs[ptr PBase]): string =
  result = ""
  for c in x:
    result.add $c.val

block test_t4799_4:
  var pv = PBase(val: 3)
  var pc = PC(val: 4)
  var pb = PD(val: 2)
  doAssert(testP(pb.addr, pc.addr, pv.addr) == "243")
  doAssert(testP(pc.addr, pv.addr, pb.addr) == "432")
  doAssert(testP(pv.addr, pb.addr, pc.addr) == "324")
  doAssert(testP([pb.addr, pc.addr, pv.addr]) == "243")
  doAssert(testP([pc.addr, pv.addr, pb.addr]) == "432")
  doAssert(testP([pv.addr, pb.addr, pc.addr]) == "324")

type
  PSBase[T, V] = ref object of RootObj
    val: T
    color: V
  PSRC[T] = ref object of PSBase[T, int]
  PSRD[T] = ref object of PSBase[T, int]

proc testPS[T, V](x: varargs[PSBase[T, V]]): string =
  result = ""
  for c in x:
    result.add c.val
    result.add $c.color

block test_t4799_5:
  var a = PSBase[string, int](val: "base", color: 1)
  var b = PSRC[string](val: "rc", color: 2)
  var c = PSRD[string](val: "rd", color: 3)

  doAssert(testPS(a, b, c) == "base1rc2rd3")
  doAssert(testPS(b, a, c) == "rc2base1rd3")
  doAssert(testPS(c, b, a) == "rd3rc2base1")
  doAssert(testPS([a, b, c]) == "base1rc2rd3")
  doAssert(testPS([b, a, c]) == "rc2base1rd3")
  doAssert(testPS([c, b, a]) == "rd3rc2base1")

type
  SBase[T, V] = ref object of RootObj
    val: T
    color: V
  SRC = ref object of SBase[string, int]
  SRD = ref object of SBase[string, int]

proc testS[T, V](x: varargs[SBase[T, V]]): string =
  result = ""
  for c in x:
    result.add c.val
    result.add $c.color

block test_t4799_6:
  var a = SBase[string, int](val: "base", color: 1)
  var b = SRC(val: "rc", color: 2)
  var c = SRD(val: "rd", color: 3)

  doAssert(testS(a, b, c) == "base1rc2rd3")
  doAssert(testS(b, a, c) == "rc2base1rd3")
  doAssert(testS(c, b, a) == "rd3rc2base1")
  doAssert(testS([a, b, c]) == "base1rc2rd3")
  # this is not varargs bug, but array construction bug
  # see #7955
  #doAssert(testS([b, c, a]) == "rc2rd3base1")
  #doAssert(testS([c, b, a]) == "rd3rc2base1")

proc test_inproc() =
  block test_inproc_1:
    var rgv = GRBase[int](val: 3)
    var rgc = GRC[int](val: 4)
    var rgb = GRD[int](val: 2)
    doAssert(testGR(rgb, rgc, rgv) == "243")
    doAssert(testGR(rgc, rgv, rgb) == "432")
    doAssert(testGR(rgv, rgb, rgc) == "324")
    doAssert(testGR([rgb, rgc, rgv]) == "243")
    doAssert(testGR([rgc, rgv, rgb]) == "432")
    doAssert(testGR([rgv, rgb, rgc]) == "324")

  block test_inproc_2:
    var pgv = PRBase[int](val: 3)
    var pgc = PRC[int](val: 4)
    var pgb = PRD[int](val: 2)
    doAssert(testPR(pgb.addr, pgc.addr, pgv.addr) == "243")
    doAssert(testPR(pgc.addr, pgv.addr, pgb.addr) == "432")
    doAssert(testPR(pgv.addr, pgb.addr, pgc.addr) == "324")
    doAssert(testPR([pgb.addr, pgc.addr, pgv.addr]) == "243")
    doAssert(testPR([pgc.addr, pgv.addr, pgb.addr]) == "432")
    doAssert(testPR([pgv.addr, pgb.addr, pgc.addr]) == "324")

test_inproc()

template reject(x) =
  static: assert(not compiles(x))

block test_t4799_7:
  type
    Vehicle[T] = ref object of RootObj
      tire: T
    Car[T] = object of Vehicle[T]
    Bike[T] = object of Vehicle[T]

  proc testVehicle[T](x: varargs[Vehicle[T]]): string {.used.} =
    result = ""
    for c in x:
      result.add $c.tire

  var v = Vehicle[int](tire: 3)
  var c = Car[int](tire: 4)
  var b = Bike[int](tire: 2)

  reject:
    echo testVehicle(b, c, v)

block test_t4799_8:
  type
    Vehicle = ref object of RootObj
      tire: int
    Car = object of Vehicle
    Bike = object of Vehicle

  proc testVehicle(x: varargs[Vehicle]): string {.used.} =
    result = ""
    for c in x:
      result.add $c.tire

  var v = Vehicle(tire: 3)
  var c = Car(tire: 4)
  var b = Bike(tire: 2)

  reject:
    echo testVehicle(b, c, v)

type
  PGVehicle[T] = ptr object of RootObj
    tire: T
  PGCar[T] = object of PGVehicle[T]
  PGBike[T] = object of PGVehicle[T]

proc testVehicle[T](x: varargs[PGVehicle[T]]): string {.used.} =
  result = ""
  for c in x:
    result.add $c.tire

var pgc = PGCar[int](tire: 4)
var pgb = PGBike[int](tire: 2)

reject:
  echo testVehicle(pgb, pgc)

type
  RVehicle = ptr object of RootObj
    tire: int
  RCar = object of RVehicle
  RBike = object of RVehicle

proc testVehicle(x: varargs[RVehicle]): string {.used.} =
  result = ""
  for c in x:
    result.add $c.tire

var rc = RCar(tire: 4)
var rb = RBike(tire: 2)

reject:
  echo testVehicle(rb, rc)

echo "OK"
