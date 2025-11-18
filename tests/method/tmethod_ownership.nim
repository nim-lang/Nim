discard """
  output: '''
Processing Animal: Generic
Processing Dog: Buddy
Processing Cat: Whiskers
Animal processes
Dog processes
Cat processes
'''
"""

# Test to demonstrate clear method ownership and dispatch

type
  Animal {.inheritable.} = ref object of RootObj
    name: string

  Dog = ref object of Animal
    breed: string

  Cat = ref object of Animal
    color: string

# Methods belong to the Animal type hierarchy
# The first parameter determines which type the method belongs to
method process(a: Animal) {.base.} =
  echo "Processing Animal: ", a.name

method process(d: Dog) =
  echo "Processing Dog: ", d.name

method process(c: Cat) =
  echo "Processing Cat: ", c.name

# Additional method to show dispatch
method doWork(a: Animal) {.base.} =
  echo "Animal processes"

method doWork(d: Dog) =
  echo "Dog processes"

method doWork(c: Cat) =
  echo "Cat processes"

# Test
let animals: seq[Animal] = @[
  Animal(name: "Generic"),
  Dog(name: "Buddy", breed: "Labrador"),
  Cat(name: "Whiskers", color: "Orange")
]

for animal in animals:
  animal.process()

for animal in animals:
  animal.doWork()
