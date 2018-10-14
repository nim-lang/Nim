discard """
  output: '''true'''
"""

type
  Foo = object
    id: int

var destroyed: int

proc `=destroy`(x: var Foo) =
  #echo "finally ", x.id
  inc destroyed

proc main =
  var r: ref Foo
  for i in 1..50_000:
    new(r)
    r.id = i
  echo destroyed > 30_000

main()
