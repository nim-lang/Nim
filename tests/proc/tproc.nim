discard """
  output: '''
Hello
1
'''
"""


block t8357:
  type T = ref int

  let r = new(string)
  r[] = "Hello"
  echo r[]


block t8683:
  proc foo[T](bar: proc (x, y: T): int = system.cmp, baz: int) =
    echo "1"
  proc foo[T](bar: proc (x, y: T): int = system.cmp) =
    echo "2"

  foo[int](baz = 5)


block tnestprc:
  proc Add3(x: int): int =
    proc add(x, y: int): int {.noconv.} =
      result = x + y
    result = add(x, 3)
  doAssert Add3(7) == 10
