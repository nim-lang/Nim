
# bug #4545
type SomeObject = object
    a : int

type AbstractObject = object
  objet: ptr SomeObject

proc convert(this: var SomeObject): AbstractObject =
  AbstractObject(objet: this.addr)

proc varargProc(args: varargs[AbstractObject, convert]): int =
  for arg in args:
    result += arg.objet.a

var obj = SomeObject(a: 17)

discard varargProc(obj)
