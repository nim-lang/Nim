discard """
  exitCode: 0
  outputsub: '''42 is greater than 0'''
"""

if 42 >= 0:
  echo "42 is greater than 0"


echo("Output: ",
  5)
echo(5 +
  5)
# --- Removed code that is supposed to fail here. Not going to test those. ---

# Single-line comment
#[
Multiline comment
]#
when false:
  echo("Commented-out code")

let decimal = 42
let hex = 0x42
let octal = 0o42
let binary = 0b101010

let a: int16 = 42
let b = 42'i8

let c = 1'f32 # --- Changed names here to avoid clashes ---
let d = 1.0e19

let e = false
let f = true

let g = 'A'
let h = '\109'
let i = '\x79'

let text = "The book title is \"Nim in Action\""

let filepath = "C:\\Program Files\\Nim"

# --- Changed name here to avoid clashes ---
let filepath1 = r"C:\Program Files\Nim"

let multiLine = """foo
  bar
  baz
"""
echo multiLine

import strutils
# --- Changed name here to avoid clashes ---
let multiLine1 = """foo
  bar
  baz
"""
echo multiLine1.unindent
doAssert multiLine1.unindent == "foo\nbar\nbaz\n"

proc fillString(): string =
  result = ""
  echo("Generating string")
  for i in 0 .. 4:
    result.add($i) #<1>

const count = fillString()

var
  text1 = "hello"
  number: int = 10
  isTrue = false

var 火 = "Fire"
let ogień = true

var `var` = "Hello"
echo(`var`)

proc myProc(name: string): string = "Hello " & name
discard myProc("Dominik")

proc bar(): int #<1>

proc foo(): float = bar().float
proc bar(): int = foo().int

proc noReturn() = echo("Hello")
proc noReturn2(): void = echo("Hello")

proc noReturn3 = echo("Hello")

proc message(recipient: string): auto =
  "Hello " & recipient

doAssert message("Dom") == "Hello Dom"

proc max(a: int, b: int): int =
  if a > b: a else: b

doAssert max(5, 10) == 10

proc max2(a, b: int): int =
  if a > b: a else: b

proc genHello(name: string, surname = "Doe"): string =
  "Hello " & name & " " & surname

# -- Leaving these as asserts as that is in the original code, just in case
# -- somehow in the future `assert` is removed :)
assert genHello("Peter") == "Hello Peter Doe"
assert genHello("Peter", "Smith") == "Hello Peter Smith"

proc genHello2(names: varargs[string]): string =
  result = ""
  for name in names:
    result.add("Hello " & name & "\n")

doAssert genHello2("John", "Bob") == "Hello John\nHello Bob\n"

proc getUserCity(firstName, lastName: string): string =
  case firstName
  of "Damien": return "Tokyo"
  of "Alex": return "New York"
  else: return "Unknown"

proc getUserCity(userID: int): string =
  case userID
  of 1: return "Tokyo"
  of 2: return "New York"
  else: return "Unknown"

doAssert getUserCity("Damien", "Lundi") == "Tokyo"
doAssert getUserCity(2) == "New York" # -- Errata here: missing closing "

import sequtils
let numbers = @[1, 2, 3, 4, 5, 6]
let odd = filter(numbers, proc (x: int): bool = x mod 2 != 0)
doAssert odd == @[1, 3, 5]

import sequtils, sugar
let numbers1 = @[1, 2, 3, 4, 5, 6]
let odd1 = filter(numbers1, (x: int) -> bool => x mod 2 != 0)
assert odd1 == @[1, 3, 5]

proc isValid(x: int, validator: proc (x: int): bool) =
  if validator(x): echo(x, " is valid")
  else: echo(x, " is NOT valid")

import sugar
proc isValid2(x: int, validator: (x: int) -> bool) =
  if validator(x): echo(x, " is valid")
  else: echo(x, " is NOT valid")

var list: array[3, int]
list[0] = 1
list[1] = 42
assert list[0] == 1
assert list[1] == 42
assert list[2] == 0 #<1>

echo list.repr #<2>

# echo list[500]

var list2: array[-10 .. -9, int]
list2[-10] = 1
list2[-9] = 2

var list3 = ["Hi", "There"]

var list4 = ["My", "name", "is", "Dominik"]
for item in list4:
  echo(item)

for i in list4.low .. list4.high:
  echo(list4[i])

var list5: seq[int] = @[]
doAssertRaises(IndexDefect):
  list5[0] = 1

list5.add(1)

assert list5[0] == 1
doAssertRaises(IndexDefect):
  echo list5[42]

# -- Errata: var list: seq[int]; echo(list[0]). This now creates an exception,
# --         not a SIGSEGV.

block:
  var list = newSeq[string](3)
  assert list[0].len == 0
  list[0] = "Foo"
  list[1] = "Bar"
  list[2] = "Baz"

  list.add("Lorem")

block:
  let list = @[4, 8, 15, 16, 23, 42]
  for i in 0 ..< list.len:
    stdout.write($list[i] & " ")

var collection: set[int16]
doAssert collection == {}

block:
  let collection = {'a', 'x', 'r'}
  doAssert 'a' in collection

block:
  let collection = {'a', 'T', 'z'}
  let isAllLowerCase = {'A' .. 'Z'} * collection == {}
  doAssert(not isAllLowerCase)

let age = 10
if age > 0 and age <= 10:
  echo("You're still a child")
elif age > 10 and age < 18:
  echo("You're a teenager")
else:
  echo("You're an adult")

let variable = "Arthur"
case variable
of "Arthur", "Zaphod", "Ford":
  echo("Male")
of "Marvin":
  echo("Robot")
of "Trillian":
  echo("Female")
else:
  echo("Unknown")

let ageDesc = if age < 18: "Non-Adult" else: "Adult"

block:
  var i = 0
  while i < 3:
    echo(i)
    i.inc

block label:
  var i = 0
  while true:
    while i < 5:
      if i > 3: break label
      i.inc

iterator values(): int =
  var i = 0
  while i < 5:
    yield i
    i.inc

for value in values():
  echo(value)

import os
for filename in walkFiles("*.nim"):
  echo(filename)

for item in @[1, 2, 3]:
  echo(item)

for i, value in @[1, 2, 3]: echo("Value at ", i, ": ", value)

doAssertRaises(IOError):
  proc second() =
    raise newException(IOError, "Somebody set us up the bomb")

  proc first() =
    second()

  first()

block:
  proc second() =
    raise newException(IOError, "Somebody set us up the bomb")

  proc first() =
    try:
      second()
    except:
      echo("Cannot perform second action because: " &
        getCurrentExceptionMsg())

  first()

block:
  type
    Person = object
      name: string
      age: int

  var person: Person
  var person1 = Person(name: "Neo", age: 28)

block:
  type
    PersonObj = object
      name: string
      age: int
    PersonRef = ref PersonObj

  # proc setName(person: PersonObj) =
  #   person.name = "George"

  proc setName(person: PersonRef) =
    person.name = "George"

block:
  type
    Dog = object
      name: string

    Cat = object
      name: string

  let dog: Dog = Dog(name: "Fluffy")
  let cat: Cat = Cat(name: "Fluffy")

block:
  type
    Dog = tuple
      name: string

    Cat = tuple
      name: string

  let dog: Dog = (name: "Fluffy")
  let cat: Cat = (name: "Fluffy")

  echo(dog == cat)

block:
  type
    Point = tuple[x, y: int]
    Point2 = (int, int)

  let pos: Point = (x: 100, y: 50)
  doAssert pos == (100, 50)

  let pos1: Point = (x: 100, y: 50)
  let (x, y) = pos1 #<1>
  let (left, _) = pos1
  doAssert x == pos1[0]
  doAssert y == pos1[1]
  doAssert left == x

block:
  type
    Color = enum
      colRed,
      colGreen,
      colBlue

  let color: Color = colRed

block:
  type
    Color {.pure.} = enum
      red, green, blue

  let color = Color.red
