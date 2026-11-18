discard """
  output: '''
copy
5
'''
"""

# bug #8973: a generic `=copy` hook is used
type Generic[T] = object
  value: T

proc `=copy`[T](x: var Generic[T], y: Generic[T]) =
  echo "copy"
  x.value = y.value

proc main =
  var t: Generic[int]
  t = Generic[int](value: 5)
  var u = t
  echo u.value
  t.value = 4

main()
