discard """
  output: "Success"
"""

import math, random, threadPool

# ---

type
  Person = object
    age: int
    friend: ref Person

var
  people: seq[ref Person] = @[]

proc newPerson(age:int): ref Person =
  result.new()
  result.age = age

proc greet(p:Person) =
  #echo p.age, ", ", p.friend.age
  p.friend.age += 1

# ---

proc setup =
  for i in 0 .. <20:
    people.add newPerson(i + 1)
  for i in 0 .. <20:
    people[i].friend = people[random(20)]

proc update =
  var countA: array[20, int]
  var countB: array[20, int]

  for i, p in people:
    countA[i] = getRefCount(p)
  parallel:
    for i in 0 .. people.high:
      spawn greet(people[i][])
  for i, p in people:
    countB[i] = getRefCount(p)

  for i in 0 .. <20:
    doAssert countA[i] == countB[i]
  echo "Success"

# ---

when true:
  setup()
  update()
