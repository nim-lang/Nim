discard """
  output: '''int
array[0..7, byte]
'''
"""

import system

type Bar[T] = ref object
 value: T

type types = int32|int64 # if I change this to just int32 or int64 it works (compiles)

# if I replace Bar everywhere with seq it also compiles fine
proc Foo[T: Bar[types]](): T =
 when T is Bar: nil

discard Foo[Bar[int32]]()
#bug #6073

# bug #11479

import tables

proc test() =
  discard readfile("temp.nim")
  echo "ho"

const
  map = {
    "test": test,
  }.toTable

#map["test"]()

#-------------------------------------------------------------------
# bug
const val = 10
 
type 
  t = object
    when val >= 10:


#-------------------------------------------------------------------
# issue #15959

proc my[T](a: T): typeof(a[0]) =
  echo typeof(result)

proc my2[T](a: T): array[sizeof(a[0]), byte] =
  echo typeof(result)


discard my([1,2,3])

discard my2([10.0, 20.0])