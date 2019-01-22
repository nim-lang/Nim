discard """
  output: "turn_destroy_into_finalizer works"
  joinable: false
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
  if destroyed > 30_000:
    echo "turn_destroy_into_finalizer works"
  else:
    echo "turn_destroy_into_finalizer failed: ", destroyed

main()
