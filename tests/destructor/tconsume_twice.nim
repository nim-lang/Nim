discard """
  cmd: "nim c --newruntime $file"
  errormsg: "'=copy' is not available for type <owned Foo>; requires a copy because it's not the last read of 'a'; another read is done here: tconsume_twice.nim(13, 10); routine: consumeTwice"
  line: 11
"""
type
  Foo = ref object

proc use(a: owned Foo): bool = discard
proc consumeTwice(a: owned Foo): owned Foo =
  if use(a):
    return
  return a

assert consumeTwice(Foo()) != nil
