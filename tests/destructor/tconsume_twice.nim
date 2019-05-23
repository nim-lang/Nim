discard """
  cmd: "nim c --newruntime $file"
  errormsg: "sink parameter `a` is already consumed at tconsume_twice.nim(8, 6)"
  line: 10
"""

proc consumeTwice(a: owned proc()): owned proc() =
  if a == nil:
    return
  return a

assert consumeTwice(proc() = discard) != nil
