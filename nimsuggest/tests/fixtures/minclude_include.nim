# this file is included and relies on imports within the include

proc create*(greeting: string = "Hello", subject: string = "World"): Greet =
  Greet(greeting: greeting, subject: subject)
