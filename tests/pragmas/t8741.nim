discard """
  cmd: "nim check --hint:processing:off $file"
  errormsg: "3 is not two"
  nimout: '''t8741.nim(13, 9) Error: cannot attach a custom pragma to 'a'
t8741.nim(29, 15) template/generic instantiation of `onlyTwo` from here
t8741.nim(25, 12) Error: 3 is not two
'''
"""

for a {.gensym, inject.} in @[1,2,3]:
  discard

for a {.foobar.} in @[1,2,3]:
  discard

type Foo[N: static[int]] = distinct int

proc isTwo(n: int): bool =
  n == 2

proc onlyTwo[N: static[int]](a: Foo[N]): int =
  when isTwo(N):
    int(a)
  else:
    {.error: $(N) & " is not two".}

when isMainModule:
  let foo: Foo[3] = Foo[3](5)
  echo onlyTwo(foo)
