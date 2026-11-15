discard """
action: compile
"""

# bug #23031

type
  DisInt = distinct int

proc `[]`[N: static int](a: array[N, int]; i: DisInt): int =
  a[i.int]

proc `[]`[N: static int](a: var array[N, int]; i: DisInt): var int =
  a[i.int]

var
  a = [1, 2]
  i = 1.DisInt
echo a[i]
a[i] += 3
echo a[i]
