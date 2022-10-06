discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t18886.nim(18, 24) Error: ambiguous identifier: 'bar' -- you need a helper proc to disambiguate the following:
  t18886.bar: proc (i: ptr int){.noSideEffect, gcsafe, locks: 0.}
  t18886.bar: proc (i: ptr char){.noSideEffect, gcsafe, locks: 0.}
'''
"""

type Foo = (proc(_: pointer): void)


proc bar(i: ptr[int]) = discard
proc bar(i: ptr[char]) = discard


let fooBar = cast[Foo](bar)