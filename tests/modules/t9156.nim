# bug #9156: a proc and a type of the same name from different modules
import m9156/[a, b]

var x: testing
doAssert x.foo == "doink!"
doAssert foo(x) == "doink!"
var y: foo
discard y
