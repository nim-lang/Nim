discard """
  output: '''{"columns":[{"t":null},{"t":null}]}
{"columns":[{"t":null},{"t":null}]}
'''
"""

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


doAssert test.name == cstring"Jorden"
doAssert knight.age == 19
doAssert knight.item.price == 50
doAssert recurse1.next.next.data == 3

# bug #6035
proc toJson*[T](data: T): cstring {.importc: "JSON.stringify".}

type
  Column = object
    t: ref Column

  Test2 = object
    columns: seq[Column]

var test1 = Test2(columns: @[Column(t: nil), Column(t: nil)])
let test2 = test1

echo toJSON(test1)
echo toJSON(test2)

block issue10005:
  type
    Player = ref object of RootObj
      id*: string
      nickname*: string
      color*: string

  proc newPlayer(nickname: string, color: string): Player =
    let pl = Player(color: "#123", nickname: nickname)
    return Player(
        id: "foo",
        nickname: nickname,
        color: color,
    )

  doAssert newPlayer("foo", "#1232").nickname == "foo"
