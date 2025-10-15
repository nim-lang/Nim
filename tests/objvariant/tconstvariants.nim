import std/macros 

# bug #11862
type
  Kind = enum kOne, kTwo

  Thing = object
    case kind: Kind
      of kOne:
        v1: int
      of kTwo:
        v2: int
               
macro magic(): untyped =
  var b = Thing(kind: kOne, v1: 3)
  quote do:                       
    `b`    
           
const c = magic()

# bug #25123
type V = object
  case a: bool
  of false: discard
  of true:  t: int

proc s(): V {.compileTime.} = discard
proc h(_: V) = discard

proc e(m: static[V]) = h(m)
template j(m: static[V]) = h(m)
macro r(m: static[V]) = h(m)

e(s())
j(s())
r(s())

s().e()
s().j()
s().r()