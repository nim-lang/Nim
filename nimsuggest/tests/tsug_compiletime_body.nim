import std/macros

proc inner(): int =
  return 2

proc outer(): int =
  const k = inner()
  return k + 1

macro declareIfThree(p: untyped): untyped =
  if outer() == 3:
    result = quote do:
      const vIsMacro {.inject.} = true
  else:
    result = newEmptyNode()

proc tagged() {.declareIfThree.} = discard

const v = outer()

when v == 3:
  const vIsThree = true

proc user(): bool =
  vIs#[!]#

# `outer` and `inner` run at compile time while `sug` checks this file: the
# `const` and the pragma macro call them. Their bodies must be checked, or the
# VM runs them unchecked (it crashed), and `v` must be 3 so both constants are
# declared.
discard """
$nimsuggest --tester $file
>sug $1
sug;;skConst;;tsug_compiletime_body.vIsMacro;;bool;;$file;;13;;12;;"";;100;;Prefix
sug;;skConst;;tsug_compiletime_body.vIsThree;;bool;;$file;;22;;8;;"";;100;;Prefix
"""
