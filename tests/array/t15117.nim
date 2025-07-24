discard """
  matrix: "--cc:vcc"
  disabled: "linux"
  disabled: "bsd"
  disabled: "osx"
  disabled: "unix"
  disabled: "posix"
"""
{.experimental: "views".}

let a: array[0, byte] = []
discard a

type B = object
  a:int
let b: array[0, B] = []
let c: array[0, ptr B] = []
let d: array[0, ref B] = []
discard b
discard c
discard d

discard default(array[0, B])

type
  View1 = openArray[byte]
discard default(View1)
