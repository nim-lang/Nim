# Section: Borrowed methods on distinct subtypes preserve dynamic dispatch.
type
  Animal = ref object of RootObj
    name: string
  Dog = ref object of Animal
    age: int

proc describe(animal: Animal): string =
  "animal:" & animal.name

proc describe(dog: Dog): string =
  "dog:" & dog.name & ":" & $dog.age

method kind(animal: Animal): string {.base.} =
  "animal"

method kind(dog: Dog): string =
  "dog"

type
  DistinctAnimal {.borrow: `.`.} = distinct Animal
  DistinctDog {.borrow: `.`.} = distinct Dog
  DistinctDog2 {.borrow: `.`.} = distinct DistinctDog

proc describe(animal: DistinctAnimal): string {.borrow.}
proc describe(dog: DistinctDog): string {.borrow.}
proc describe(dog: DistinctDog2): string {.borrow.}

method kind(animal: DistinctAnimal): string {.borrow.}
method kind(dog: DistinctDog): string {.borrow.}
method kind(dog: DistinctDog2): string {.borrow.}

# Section: Distinct wrappers forward method overloads and casts.
let dog = Dog(name: "Rex", age: 5)
let distinctDog = DistinctDog(dog)
let distinctDog2 = DistinctDog2(distinctDog)
let distinctAnimal = DistinctAnimal(Animal(name: "Rex"))
let distinctAnimalFromDog = DistinctAnimal(Animal(dog))

doAssert describe(distinctDog) == "dog:Rex:5"
doAssert describe(distinctDog2) == "dog:Rex:5"
doAssert describe(distinctAnimal) == "animal:Rex"

doAssert kind(distinctDog) == "dog"
doAssert kind(distinctDog2) == "dog"
doAssert kind(distinctAnimal) == "animal"
doAssert kind(distinctAnimalFromDog) == "dog"

let backDog = Dog(distinctDog)
let backDog2 = Dog(DistinctDog(distinctDog2))
let backAnimal = Animal(distinctAnimal)

doAssert backDog.age == 5

doAssert backDog2.age == 5

doAssert backAnimal.name == "Rex"

let distinctAnimalFromDistinctDog = DistinctAnimal(Animal(Dog(distinctDog)))

doAssert describe(distinctAnimalFromDistinctDog) == "animal:Rex"
