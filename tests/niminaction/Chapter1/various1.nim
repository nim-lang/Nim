discard """
  exitCode: 0
  outputsub: "Woof!"
"""

import strutils
echo("hello".to_upper())
echo("world".toUpper())

type
  Dog = object #<1>
    age: int #<2>

let dog = Dog(age: 3) #<3>

proc showNumber(num: int | float) =
  echo(num)

showNumber(3.14)
showNumber(42)

for i in 0 ..< 10:
  echo(i)

block: # Block added due to clash.
  type
    Dog = object

  proc bark(self: Dog) = #<1>
    echo("Woof!")

  let dog = Dog()
  dog.bark() #<2>

import sequtils, sugar, strutils
let list = @["Dominik Picheta", "Andreas Rumpf", "Desmond Hume"]
list.map(
  (x: string) -> (string, string) => (x.split[0], x.split[1])
).echo

import strutils
let list1 = @["Dominik Picheta", "Andreas Rumpf", "Desmond Hume"]
for name in list1:
  echo((name.split[0], name.split[1]))

