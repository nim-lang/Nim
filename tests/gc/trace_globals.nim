discard """
  joinable: false
  # because of --gc:boehm warning
"""

# bug #17085

#[
refs https://github.com/nim-lang/Nim/issues/17085#issuecomment-786466595
with --gc:boehm, this warning sometimes gets generated:
Warning: Repeated allocation of very large block (appr. size 14880768):
May lead to memory leak and poor performance.
]#

proc init(): string =
  for a in 0..<10000000:
    result.add 'c'

proc f() =
  var a {.global.} = init()
  var b {.global.} = init()
  var c {.global.} = init()

  doAssert a.len == 10000000
  doAssert b.len == 10000000
  doAssert c.len == 10000000

f()
