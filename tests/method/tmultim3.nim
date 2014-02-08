discard """
  file: "tmultim3.nim"
  output: "Hi derived!"
"""
import mmultim3

type
    TBObj* = object of TObj


method test123(a : ref TBObj) =
    echo("Hi derived!")

var a : ref TBObj
new(a)
myObj = a
testMyObj()



