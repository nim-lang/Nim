discard """
  cmd: '''nim check --hints:off $file'''
  action: reject
nimout: '''
t19986.nim(19, 7) Error: 'foo' borrows from the immutable location 'a' and attempts to mutate it
t19986.nim(28, 7) Error: 'foo' borrows from the immutable location 'a' and attempts to mutate it
t19986.nim(37, 7) Error: 'foo' borrows from the immutable location 'a' and attempts to mutate it
'''
"""

{.experimental: "views".}

type
  Object = object
    id: int

proc foo() =
  let a = Object(id: 3)
  var foo: var Object = a

  foo.id = 777
  echo a

foo()

proc bar() =
  let a = "123"
  var foo: var string = a

  foo[0] = '7'
  echo a

bar()

proc main() =
  let a = 3
  var foo: var int = a

  foo = 777
  echo a

main()
