import ./msugarexported

doAssert x == 3
doAssert foo(1) == 2
doAssert foo("Hello") == "Hello."

var obj: Foo
doAssert not compiles(obj.field)

doAssert macroPragmaProc()
