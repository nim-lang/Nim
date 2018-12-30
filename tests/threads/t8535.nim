discard """
  output: "0"
"""

type
  CircAlloc* [Size: static[int] , T]  =  tuple
    baseArray           : array[Size,T]
    index               : uint16

type
  Job = object of RootObj

var foo {.threadvar.}: CircAlloc[1,Job]

when true:
  echo foo.index
