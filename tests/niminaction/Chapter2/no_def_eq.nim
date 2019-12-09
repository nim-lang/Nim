discard """
  errormsg: "type mismatch"
  line: 16
"""

type
    Dog = object
      name: string

    Cat = object
      name: string

let dog: Dog = Dog(name: "Fluffy")
let cat: Cat = Cat(name: "Fluffy")

echo(dog == cat)
