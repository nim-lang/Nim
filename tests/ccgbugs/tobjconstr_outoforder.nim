discard """
  output: '''(left: 1, up: 0, right: 2, down: 0)
(left: 0, up: 1, right: 0, down: 2)
@[(left: 1, up: 0, right: 2, down: 0), (left: 0, up: 1, right: 0, down: 2)]
@[(left: 1, up: 0, right: 2, down: 0), (left: 0, up: 1, right: 0, down: 2)]
true'''
"""

# bug #5339
type
  Dirs = object
    left: int
    up: int
    right: int
    down: int

let
  a = Dirs(
    left: 1,
    right: 2,
  )
  b = Dirs(
    up: 1,
    down: 2,
  )
  works = @[
    a,
    b,
  ]
  fails = @[
    Dirs(left: 1, right: 2),
    Dirs(up: 1, down: 2),
  ]
echo a
echo b
echo works
echo fails
echo works == fails
