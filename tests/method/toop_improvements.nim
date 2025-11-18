discard """
  output: '''
Animal makes a sound
Dog barks
Cat meows
Dog barks
Cat meows
'''
"""

# Test comprehensive OOP features and improvements

# Test 1: Basic inheritance and method dispatch
type
  Animal {.inheritable.} = ref object of RootObj
    name: string

  Dog = ref object of Animal
    breed: string

  Cat = ref object of Animal
    indoor: bool

# Base methods with implementation
method makeSound(a: Animal) {.base.} =
  echo "Animal makes a sound"

method makeSound(d: Dog) =
  echo "Dog barks"

method makeSound(c: Cat) =
  echo "Cat meows"

# Test 2: Abstract types and methods
type
  Shape {.abstract.} = ref object of RootObj
    x, y: float

  Circle = ref object of Shape
    radius: float

  Rectangle = ref object of Shape
    width, height: float

method area(s: Shape): float {.base, abstract.} =
  0.0  # Abstract method with placeholder

method area(c: Circle): float =
  3.14159 * c.radius * c.radius

method area(r: Rectangle): float =
  r.width * r.height

# Test 3: Multiple parameters (multi-methods)
type
  Container {.inheritable.} = ref object of RootObj

method interact(a: Animal, c: Container) {.base.} =
  discard

# Test dispatch
proc testBasicDispatch() =
  let animals: seq[Animal] = @[
    Animal(name: "Generic"),
    Dog(name: "Buddy", breed: "Golden Retriever"),
    Cat(name: "Whiskers", indoor: true)
  ]

  for animal in animals:
    animal.makeSound()

proc testAbstractTypes() =
  # Shape() would cause a compile error due to {.abstract.}
  let shapes: seq[Shape] = @[
    Circle(x: 0, y: 0, radius: 5.0),
    Rectangle(x: 0, y: 0, width: 4.0, height: 6.0)
  ]

  for shape in shapes:
    let a = shape.area()
    doAssert a > 0

proc testPolymorphism() =
  # Demonstrate runtime dispatch
  let animal: Animal = Dog(name: "Max", breed: "Labrador")
  animal.makeSound()  # Should print "Dog barks"

  let cat: Animal = Cat(name: "Fluffy", indoor: true)
  cat.makeSound()  # Should print "Cat meows"

# Run tests
testBasicDispatch()
testPolymorphism()
