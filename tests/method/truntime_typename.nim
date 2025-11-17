discard """
  output: '''
Test 1: Basic runtime type check
Compile-time type: Animal
Runtime type: Dog
Test 2: Polymorphic variables
Animal polymorphic variable contains: Dog
Cat polymorphic variable contains: Cat
Base polymorphic variable contains: Animal
Test 3: Method dispatch with debug
[Method Dispatch] makeSound on Dog (compile-time type: Dog)
Dog barks
[Method Dispatch] makeSound on Cat (compile-time type: Cat)
Cat meows
[Method Dispatch] makeSound on Animal (compile-time type: Animal)
Animal makes sound
Test 4: Complex hierarchy
Shape polymorphic variable contains: Circle
Shape polymorphic variable contains: Rectangle
'''
"""

import system/debugging

type
  Animal {.inheritable.} = ref object of RootObj
    name: string

  Dog = ref object of Animal
    breed: string

  Cat = ref object of Animal
    color: string

# Generate runtime type checking for Animal hierarchy
genRuntimeTypeCheck(Animal, Dog, Cat)

method makeSound(a: Animal) {.base.} =
  debugMethodDispatch(a, "makeSound", runtimeTypeName(a))
  echo "Animal makes sound"

method makeSound(d: Dog) =
  debugMethodDispatch(d, "makeSound", runtimeTypeName(d))
  echo "Dog barks"

method makeSound(c: Cat) =
  debugMethodDispatch(c, "makeSound", runtimeTypeName(c))
  echo "Cat meows"

# Test 1: Basic runtime type checking
proc test1() =
  echo "Test 1: Basic runtime type check"
  let animal: Animal = Dog(name: "Buddy", breed: "Labrador")

  echo "Compile-time type: ", $typeof(animal)
  echo "Runtime type: ", runtimeTypeName(animal)

# Test 2: Polymorphic variables
proc test2() =
  echo "Test 2: Polymorphic variables"
  let dog: Animal = Dog(name: "Max", breed: "Golden")
  let cat: Animal = Cat(name: "Felix", color: "Black")
  let animal: Animal = Animal(name: "Generic")

  # Uses auto-generated runtimeTypeName proc
  echo "Animal polymorphic variable contains: ", runtimeTypeName(dog)
  echo "Cat polymorphic variable contains: ", runtimeTypeName(cat)
  echo "Base polymorphic variable contains: ", runtimeTypeName(animal)

# Test 3: Method dispatch with debug output
proc test3() =
  echo "Test 3: Method dispatch with debug"
  let animals: seq[Animal] = @[
    Dog(name: "Buddy", breed: "Labrador"),
    Cat(name: "Whiskers", color: "Orange"),
    Animal(name: "Generic")
  ]

  for animal in animals:
    animal.makeSound()

# Test 4: More complex hierarchy
type
  Shape {.inheritable.} = ref object of RootObj
    x, y: float

  Circle = ref object of Shape
    radius: float

  Rectangle = ref object of Shape
    width, height: float

genRuntimeTypeCheck(Shape, Circle, Rectangle)

proc test4() =
  echo "Test 4: Complex hierarchy"
  let shapes: seq[Shape] = @[
    Circle(x: 0, y: 0, radius: 5.0),
    Rectangle(x: 0, y: 0, width: 4.0, height: 6.0)
  ]

  for shape in shapes:
    echo "Shape polymorphic variable contains: ", runtimeTypeName(shape)

test1()
test2()
test3()
test4()
