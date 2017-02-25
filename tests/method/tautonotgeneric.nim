discard """
  output: '''wof!
wof!'''
"""

# bug #1659
type Animal = ref object {.inheritable.}
type Dog = ref object of Animal

method say(a: Animal): auto {.base.} = "wat!"
method say(a: Dog): auto = "wof!"

proc saySomething(a: Animal): auto = a.say()


method ec(a: Animal): auto {.base.} = echo "wat!"
method ec(a: Dog): auto = echo "wof!"

proc ech(a: Animal): auto = a.ec()


var a = Dog()
echo saySomething(a)
ech a
