# bug #2401

type MyClass = ref object of RootObj

method HelloWorld*(obj: MyClass) {.base.} =
  when defined(myPragma):
    echo("Hello World")
  # discard # with this line enabled it works

var obj = MyClass()
obj.HelloWorld()
