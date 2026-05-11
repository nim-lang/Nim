type
  Foo = object
    id: int

proc `=wasMoved`(x: var Foo) =
  x.id = -1

proc foo =
  var s = Foo(id: 999)
  var m = move s
  doAssert s.id == -1
  doAssert m.id == 999

foo()

block:
  type Foo = object
    a,b,c: int

  var dest: Foo

  # proc `=wasMoved`(x: var Foo) =
  #   debugEcho "wasMoved called"

  proc main() =
    var x = Foo(a:11, b:12, c:13)
    dest = move(x)

  main()

block:
  type Foo = object
    a,b,c: int

  var dest: Foo

  proc `=wasMoved`(x: var Foo) =
    discard "wasMoved called"

  proc main() =
    var x = Foo(a:11, b:12, c:13)
    dest = move(x)

  main()

