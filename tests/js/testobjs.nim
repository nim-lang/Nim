## Tests javascript object generation

type
  Kg = distinct float
  Price = int
  Item = object of RootObj
    weight: Kg
    price: Price
    desc: cstring
  Person = object of RootObj
    name: cstring
    age: int
    item: Item
  Test = object
    name: cstring
  Recurse[T] = object
    data: T
    next: ref Recurse[T]

var
  test = Test(name: "Jorden")
  sword = Item(desc: "pointy", weight: Kg(10.0),
                price: Price(50))
  knight = Person(name: "robert", age: 19, item: sword)
  recurse4 = (ref Recurse[int])(data: 4, next: nil)
  recurse3 = (ref Recurse[int])(data: 3, next: recurse4)
  recurse2 = (ref Recurse[int])(data: 2, next: recurse3)
  recurse1 = Recurse[int](data: 1, next: recurse2)


assert(test.name == "Jorden")
assert(knight.age == 19)
assert(knight.item.price == 50)
assert(recurse1.next.next.data == 3)
