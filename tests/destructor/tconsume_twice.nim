discard """
  cmd: "nim c --newruntime $file"
  errormsg: "sink parameter `a` is already consumed at tconsume_twice.nim(11, 10)"
  line: 13
"""
type
  Foo = ref object

proc use(a: owned Foo): bool = discard
proc consumeTwice(a: owned Foo): owned Foo =
  if use(a):
    return
  return a

assert consumeTwice(Foo()) != nil
