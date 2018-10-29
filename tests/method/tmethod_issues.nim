discard """
  output: '''
wof!
wof!
'''
"""


# bug #1659
type Animal = ref object {.inheritable.}
type Dog = ref object of Animal

method say(a: Animal): auto {.base.} = "wat!"
method say(a: Dog): auto = "wof!"

proc saySomething(a: Animal): auto = a.say()

method ec(a: Animal): auto {.base.} = echo "wat!"
method ec(a: Dog): auto = echo "wof!"

proc ech(a: Animal): auto = a.ec()

var a = Dog()
echo saySomething(a)
ech a



# bug #2401
type MyClass = ref object of RootObj

method HelloWorld*(obj: MyClass) {.base.} =
  when defined(myPragma):
    echo("Hello World")
  # discard # with this line enabled it works

var obj = MyClass()
obj.HelloWorld()




# bug #5432
type
  Iterator[T] = ref object of RootObj

# base methods with `T` in the return type are okay
method methodThatWorks*[T](i: Iterator[T]): T {.base.} =
  discard

# base methods without `T` (void or basic types) fail
method methodThatFails*[T](i: Iterator[T]) {.base.} =
  discard

type
  SpecificIterator1 = ref object of Iterator[string]
  SpecificIterator2 = ref object of Iterator[int]




# bug #3431
type
  Lexer = object
    buf*: string
    pos*: int
    lastchar*: char

  ASTNode = object

method init*(self: var Lexer; buf: string) {.base.} =
  self.buf = buf
  self.pos = 0
  self.lastchar = self.buf[0]

method init*(self: var ASTNode; val: string) =
  discard



# bug #3370
type
  RefTestA*[T] = ref object of RootObj
    data*: T

method tester*[S](self: S): bool =
  true

type
  RefTestB* = RefTestA[(string, int)]

method tester*(self: RefTestB): bool =
  true

type
  RefTestC = RefTestA[string]

method tester*(self: RefTestC): bool =
  false



# bug #3468
type X = ref object of RootObj
type Y = ref object of RootObj

method draw*(x: X) {.base.} = discard
method draw*(y: Y) {.base.} = discard



# bug #3550
type 
  BaseClass = ref object of RootObj
  Class1 = ref object of BaseClass
  Class2 = ref object of BaseClass
  
method test(obj: Class1, obj2: BaseClass) =
  discard

method test(obj: Class2, obj2: BaseClass) =
  discard
  
var obj1 = Class1()
var obj2 = Class2()

obj1.test(obj2) 
obj2.test(obj1)
