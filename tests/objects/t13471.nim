discard """
  targets: "c cpp"
  matrix: "--warning:UseBase:off"
  output: '''
x
1.5
5
'''
"""

# bug #13471: converting a `var ChildRef` to `var ParentRef` produced invalid C
type Animal = ref object of RootObj
  name*: string
method readData(self: var Animal) {.base.} =
  self.name = "x"
type AerialAnimal = ref object of Animal
  flightSpeed: float
method readData(self: var AerialAnimal, flightSpeed: float) =
  self.flightSpeed = flightSpeed
  procCall readData(self.Animal)
var a = AerialAnimal()
readData(a, 1.5)
echo a.name
echo a.flightSpeed

# bug #12841
type Obj[V] = ref object of RootObj
  val: seq[V]
proc myInnerFunc[V](o: var Obj[V]) =
  o.val.add o.val.len.V
type ChildObj[V] = ref object of Obj[V]
iterator myGenFunc[V](order: var ChildObj[V]): V =
  order.myInnerFunc()
  for x in order.val: yield x
var obj = ChildObj[int](val: @[1, 2])
var s = 0
for x in obj.myGenFunc(): s += x
echo s
