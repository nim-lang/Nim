discard """
  output: '''
Converting (int, int) to A
Converting (int, int) to A
Checked: A
Checked: A
Checked: A
Converting (A, A) to A
Converting (int, int) to A
Checked: A
Checked: A
Checked: A
Converting (A, A) to A
Converting (A, A) to A
Checked: A
Checked: A
Checked: A
'''
"""

# issue #19471

type A = ref object

converter toA(x: tuple): A =
  echo "Converting ", x.type, " to A"
  A()

proc check(a: A) =
  echo "Checked: ", a.type

proc mux(a: A, b: A, c: A) =
  check(a)
  check(b)
  check(c)

let a = A()

mux(a, (0, 0), (1, 1)) # both tuples are (int, int)
mux(a, (a, a), (1, 1)) # one tuple is (A, A), another (int, int)
mux(a, (a, a), (a, a)) # both tuples are (A, A)
