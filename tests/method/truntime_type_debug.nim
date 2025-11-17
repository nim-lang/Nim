discard """
  output: '''
Compile-time type: Animal
Runtime type via repr: Dog
Method dispatch on: Dog(breed: "Labrador", name: "Buddy")
Processing a Dog
Method dispatch on: Cat(color: "Orange", name: "Whiskers")
Processing a Cat
Method dispatch on: Animal(name: "Generic")
Processing an Animal
'''
"""

## Test runtime type debugging for methods

type
  Animal {.inheritable.} = ref object of RootObj
    name: string

  Dog = ref object of Animal
    breed: string

  Cat = ref object of Animal
    color: string

# Helper proc to extract type name from repr
proc getRuntimeTypeName(obj: Animal): string =
  ## Gets the runtime type name of an object
  ## Works by parsing the repr() output
  let r = repr(obj)
  let parenPos = r.find('(')
  if parenPos > 0:
    return r[0..<parenPos]
  return r

# Methods with debug output
method process(a: Animal) {.base.} =
  echo "Processing an Animal"

method process(d: Dog) =
  echo "Processing a Dog"

method process(c: Cat) =
  echo "Processing a Cat"

# Test with debug output
proc testRuntimeTypeDebug() =
  # Test 1: typeof gives compile-time type
  let animal: Animal = Dog(name: "Buddy", breed: "Labrador")
  echo "Compile-time type: ", $typeof(animal)

  # Test 2: Get runtime type name
  echo "Runtime type via repr: ", getRuntimeTypeName(animal)

  # Test 3: Show dispatch with runtime type
  let animals: seq[Animal] = @[
    Dog(name: "Buddy", breed: "Labrador"),
    Cat(name: "Whiskers", color: "Orange"),
    Animal(name: "Generic")
  ]

  for animal in animals:
    echo "Method dispatch on: ", repr(animal)
    animal.process()

testRuntimeTypeDebug()
