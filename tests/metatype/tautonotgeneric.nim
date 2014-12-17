discard """
  output: "wof!"
"""

# bug #1659
type Animal = ref object {.inheritable.}
type Dog = ref object of Animal

method say(a: Animal): auto = "wat!"
method say(a: Dog): auto = "wof!"

proc saySomething(a: Animal): auto = a.say()

var a = Dog()
echo saySomething(a)
