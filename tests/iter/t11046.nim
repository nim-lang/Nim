discard """
  output: '''name = Foo
species = Bar
Field0 = 1
Field1 = x
a: 1 2
b: 3 4
kind = true
x = 7
generic: name
generic: species
'''
"""

# bug #11046: macros like `fmt` see the variables of a `fieldPairs` loop
import std/[strformat, macros]

type
  Animal = object
    name, species: string

let a = Animal(name: "Foo", species: "Bar")
for key, val in a.fieldPairs:
  echo fmt"{key} = {val}"

for key, val in (1, "x").fieldPairs:
  echo fmt"{key} = {val}"

type P = object
  a, b: int
for key, x, y in fieldPairs(P(a: 1, b: 3), P(a: 2, b: 4)):
  echo fmt"{key}: {x} {y}"

macro setTo(name: static string; value: untyped): untyped =
  newAssignment(ident(name), value)

var m = Animal()
for v in m.fields:
  setTo("v", "changed")
doAssert m.name == "changed" and m.species == "changed"

type
  C = object
    case kind: bool
    of true: x: int
    of false: y: string
for key, val in fieldPairs(C(kind: true, x: 7)):
  echo fmt"{key} = {val}"

proc gen[T](t: T) =
  for key, _ in t.fieldPairs:
    echo fmt"generic: {key}"
gen(a)

# unused loop variables are fine:
for key, val in a.fieldPairs:
  discard
