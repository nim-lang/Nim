
discard """
  errormsg: "cannot instantiate 'A[T, P]' inside of type definition: 'init'; Maybe generic arguments are missing?"
"""
type A[T,P] = object
  b:T
  c:P
proc init(): ref A =      
  new(result)
var a = init()
