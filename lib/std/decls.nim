#[
keep this module dependency-light to be usable in low level modules.

see `semLowerLetVarCustomPragma` for compiler support that enables these
lowerings
]#

template byaddr*(lhs, typ, ex) =
  ## Allows a syntax for lvalue reference, exact analog to
  ## `auto& a = ex;` in C++
  runnableExamples:
    var s = @[10,11,12]
    var a {.byaddr.} = s[0]
    a+=100
    doAssert s == @[110,11,12]
    doAssert a is int
    var b {.byaddr.}: int = s[0]
    doAssert a.addr == b.addr
  when typ is typeof(nil):
    let tmp = addr(ex)
  else:
    let tmp: ptr typ = addr(ex)
  template lhs: untyped = tmp[]

proc byLent*[T](a: var T): lent T {.inline.} =
  ## Transforms `a` into a let param without copying; this is useful for overload
  ## resolution
  runnableExamples:
    proc fn(a: int): int = result = a*2
    proc fn(a: var int) = a = a*2
    var x = 3
    # x = fn(x)  # would give: Error: expression 'fn(x)' has no type (or is ambiguous)
    x = fn(x.byLent) # works
    doAssert x == 3*2
  result = a # just `a` hits: bug #14420
