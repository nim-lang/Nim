type
  Animal = object of RootObj
    name: string
  Dog = object of Animal
    age: int

proc describe(animal: Animal): string =
  "animal:" & animal.name

proc describe(dog: Dog): string =
  "dog:" & dog.name & ":" & $dog.age

proc kind(animal: Animal): string =
  "animal"

proc kind(dog: Dog): string =
  "dog"

type
  DistinctAnimal {.borrow: `.`.} = distinct Animal
  DistinctDog {.borrow: `.`.} = distinct Dog
  DistinctDog2 {.borrow: `.`.} = distinct DistinctDog

proc describe(animal: DistinctAnimal): string {.borrow.}
proc describe(dog: DistinctDog): string {.borrow.}
proc describe(dog: DistinctDog2): string {.borrow.}

proc kind(animal: DistinctAnimal): string {.borrow.}
proc kind(dog: DistinctDog): string {.borrow.}
proc kind(dog: DistinctDog2): string {.borrow.}

let dog = Dog(name: "Rex", age: 5)
let distinctDog = DistinctDog(dog)
let distinctDog2 = DistinctDog2(distinctDog)
let distinctAnimal = DistinctAnimal(Animal(dog))

doAssert describe(distinctDog) == "dog:Rex:5"
doAssert describe(distinctDog2) == "dog:Rex:5"
doAssert describe(distinctAnimal) == "animal:Rex"

doAssert kind(distinctDog) == "dog"
doAssert kind(distinctDog2) == "dog"
doAssert kind(distinctAnimal) == "animal"

let backDog = Dog(distinctDog)
let backDog2 = Dog(DistinctDog(distinctDog2))
let backAnimal = Animal(distinctAnimal)

doAssert backDog.age == 5

doAssert backDog2.age == 5

doAssert backAnimal.name == "Rex"

let distinctAnimalFromDog = DistinctAnimal(Animal(Dog(distinctDog)))

doAssert describe(distinctAnimalFromDog) == "animal:Rex"
