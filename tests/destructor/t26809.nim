discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
destroyed 3
destroyed 2
destroyed 1
'''
"""

# bug #26809: `=destroy` taking `T` instead of `var T` must work with refc too

type O = object
  x: int

proc `=destroy`(x: O) =
  echo "destroyed ", x.x

type W = object
  o: O
  s: string

proc main =
  var o = O(x: 1)
  var w = W(o: O(x: 2), s: "abc")
  var s = @[O(x: 3)]

main()
