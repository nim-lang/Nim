discard """
  output: '''apple
banana
Fruit
2
4
3
'''
"""

#bug #7601
type
  Fruit = object of RootObj
    name: string
  Apple = object of Fruit
  Banana = object of Fruit

var
  ir = Fruit(name: "Fruit")
  ia = Apple(name: "apple")
  ib = Banana(name: "banana")

let x = [ia.addr, ib.addr, ir.addr]
for c in x: echo c.name

type
  Vehicle[T] = object of RootObj
    tire: T
  Car[T] = object of Vehicle[T]
  Bike[T] = object of Vehicle[T]

var v = Vehicle[int](tire: 3)
var c = Car[int](tire: 4)
var b = Bike[int](tire: 2)

let y = [b.addr, c.addr, v.addr]
for c in y: echo c.tire
