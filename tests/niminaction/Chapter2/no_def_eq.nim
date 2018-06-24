discard """
  line: 16
  errormsg: "type mismatch"
"""

type
    Dog = object
      name: string

    Cat = object
      name: string

let dog: Dog = Dog(name: "Fluffy")
let cat: Cat = Cat(name: "Fluffy")

echo(dog == cat)