discard """
  output: '''
(name: "hello")
(-1, 0)
(FirstName: "James", LastName: "Franco")
'''
"""

# bug #2774, bug #3195
type Foo = object
  name: string

const fooArray = [
  Foo(name: "hello")
]

echo fooArray[0]

type
    Position = object
        x, y: int

proc `$`(pos: Position): string =
    result = "(" & $pos.x & ", " & $pos.y & ")"

proc newPos(x, y: int): Position =
    result = Position(x: x, y: y)

const
     offset: array[1..4, Position] = [
         newPos(-1, 0),
         newPos(1, 0),
         newPos(0, -1),
         newPos(0, 1)
     ]

echo offset[1]

# bug #1547
import tables

type Person* = object
    FirstName*: string
    LastName*: string

let people = {
    "001": Person(FirstName: "James", LastName: "Franco")
}.toTable()

echo people["001"]
