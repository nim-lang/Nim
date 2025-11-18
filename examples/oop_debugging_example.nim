## Example: Debugging OOP Method Dispatch in Nim
##
## This example shows how to use Nim's debugging utilities to track
## which method is being called at runtime.

import system/debugging

# Define your type hierarchy
type
  Animal {.inheritable.} = ref object of RootObj
    name: string
    age: int

  Dog = ref object of Animal
    breed: string

  Cat = ref object of Animal
    indoor: bool

  Bird = ref object of Animal
    canFly: bool

# STEP 1: Generate runtime type checking
# List all derived types after the base type
genRuntimeTypeCheck(Animal, Dog, Cat, Bird)

# STEP 2: Use runtime type info in your methods
method speak(a: Animal) {.base.} =
  # You can now call runtimeTypeName(a) to get the actual type!
  echo runtimeTypeName(a), " (", a.name, "): [generic animal sound]"

method speak(d: Dog) =
  echo runtimeTypeName(d), " (", d.name, "): Woof!"

method speak(c: Cat) =
  echo runtimeTypeName(c), " (", c.name, "): Meow!"

method speak(b: Bird) =
  echo runtimeTypeName(b), " (", b.name, "): Chirp!"

# STEP 3 (Optional): Add debug output to track dispatch
method eat(a: Animal, food: string) {.base.} =
  debugMethodDispatch(a, "eat", runtimeTypeName(a))
  echo a.name, " eats ", food

method eat(d: Dog, food: string) =
  debugMethodDispatch(d, "eat", runtimeTypeName(d))
  echo d.name, " devours ", food, " happily!"

method eat(c: Cat, food: string) =
  debugMethodDispatch(c, "eat", runtimeTypeName(c))
  echo c.name, " nibbles on ", food, " delicately"

# Test the system
proc main() =
  echo "=== Creating polymorphic animals ==="
  let animals: seq[Animal] = @[
    Dog(name: "Buddy", age: 5, breed: "Labrador"),
    Cat(name: "Whiskers", age: 3, indoor: true),
    Bird(name: "Tweety", age: 1, canFly: true),
    Animal(name: "Mystery", age: 10)
  ]

  echo "\n=== Testing speak method (with automatic type detection) ==="
  for animal in animals:
    animal.speak()

  echo "\n=== Testing eat method (with debug output) ==="
  animals[0].eat("kibble")  # Dog
  animals[1].eat("fish")    # Cat

  echo "\n=== Direct runtime type inspection ==="
  for animal in animals:
    echo animal.name, " is actually a ", runtimeTypeName(animal)

main()
