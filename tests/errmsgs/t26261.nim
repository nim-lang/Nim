discard """
cmd: "nim check --hints:off $file"
action: reject
nimout: '''
t26261.nim(15, 26) Error: undeclared identifier: 'V'
t26261.nim(15, 27) Error: no generic parameters allowed for V
t26261.nim(16, 10) template/generic instantiation of `d` from here
t26261.nim(15, 8) Error: cannot instantiate: 'k'
t26261.nim(16, 10) template/generic instantiation of `d` from here
t26261.nim(15, 39) Error: expression 'k' has no type (or is ambiguous)
'''
"""

template t{0 <= a}(a: int): bool = a
proc d[k: static int](_: V[k]): int = k
discard d(0)
