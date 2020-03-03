import rtarray

type
  T = tuple[x:int]

var
  arr: array[1,T]

proc init*() =
  discard head(arr)
