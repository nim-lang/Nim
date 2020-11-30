discard """
  cmd: "nim c --gc:arc $file"
  output: '''
hello
hello
@["a", "b"]
---------------------
plain:
destroying: ('first', 42)
destroying: ('second', 20)
destroying: ('third', 12)

Option[T]:
destroying: ('first', 42)
destroying: ('second', 20)
destroying: ('third', 12)

seq[T]:
destroying: ('first', 42)
destroying: ('second', 20)
destroying: ('third', 12)

1 1
'''
"""

import dmodule

var val = parseMinValue()
if val.kind == minDictionary:
  echo val

#------------------------------------------------------------------------------
# Issue #15238
#------------------------------------------------------------------------------

proc sinkArg(x: sink seq[string]) =
  discard

proc varArg(lst: var seq[string]) = 
  sinkArg(lst)

var x = @["a", "b"]
varArg(x)
echo x


#------------------------------------------------------------------------------
# Issue #15286
#------------------------------------------------------------------------------

import std/os
discard getFileInfo(".")


#------------------------------------------------------------------------------
# Issue #15707
#------------------------------------------------------------------------------

type
  JVMObject = ref object
proc freeJVMObject(o: JVMObject) =
  discard
proc fromJObject(T: typedesc[JVMObject]): T =
  result.new(cast[proc(r: T) {.nimcall.}](freeJVMObject))

discard JVMObject.fromJObject()


#------------------------------------------------------------------------------
# Issue #15910
#------------------------------------------------------------------------------

import options

type
  Thing = object
    name: string
    age: int

proc `=destroy`(thing: var Thing) =
  if thing.name != "":
    echo "destroying: ('", thing.name, "', ", thing.age, ")"
  `=destroy`(thing.name)
  `=destroy`(thing.age)

proc plain() =
  var t = Thing(name: "first", age: 42)
  t = Thing(name: "second", age: 20)
  t = Thing()
  let u = Thing(name: "third", age: 12)

proc optionT() =
  var t = Thing(name: "first", age: 42).some
  t = Thing(name: "second", age: 20).some
  t = none(Thing)
  let u = Thing(name: "third", age: 12).some

proc seqT() =
  var t = @[Thing(name: "first", age: 42)]
  t = @[Thing(name: "second", age: 20)]
  t = @[]
  let u = @[Thing(name: "third", age: 12)]

echo "---------------------"
echo "plain:"
plain()
echo()

echo "Option[T]:"
optionT()
echo()

echo "seq[T]:"
seqT()
echo()


#------------------------------------------------------------------------------
# Issue #16120, const seq into sink
#------------------------------------------------------------------------------

proc main =
  let avals = @[@[1.0'f32, 4.0, 7.0, 10.0]]
  let rankdef = avals
  echo avals.len, " ", rankdef.len

main()