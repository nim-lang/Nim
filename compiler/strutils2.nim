##[
internal API for now, subject to modifications and moving around

string API's focusing on performance, that can be used as building blocks
for other routines.

Un-necessary allocations are avoided and appropriate algorithms are used at the
expense of code clarity when justified.
]##

proc dataPointer*[T](a: T): pointer =
  ## same as C++ `data` that works with std::string, std::vector etc.
  ## Note: safe to use when a.len == 0 but whether the result is nil or not
  ## is implementation defined for performance reasons.
  # this could be improved with ocmpiler support to avoid the `if`, e.g. in C++
  # `&a[0]` is well defined even if a.size() == 0
  when T is string | seq:
    if a.len == 0: nil else: cast[pointer](a[0].unsafeAddr)
  elif T is array:
    when a.len > 0: a.unsafeAddr
    else: nil
  elif T is cstring:
    cast[pointer](a)
  else: static: doAssert false, $T

proc setLen*(result: var string, n: int, isInit: bool) =
  ## when isInit = false, elements are left uninitialized, analog to `{.noinit.}`
  ## else, there are 0-initialized.
  # xxx placeholder until system.setLen supports this
  # to distinguish between algorithms that need 0-initialization vs not; note
  # that `setLen` for string is inconsistent with `setLen` for seq.
  # likwise with `newString` vs `newSeq`. This should be fixed in `system`.
  let n0 = result.len
  result.setLen(n)
  if isInit and n > n0:
    zeroMem(result[n0].addr, n - n0)

proc forceCopy*(result: var string, a: string) =
  ## also forces a copy if `a` is shallow
  # the naitve `result = a` would not work if `a` is shallow
  let n = a.len
  result.setLen n, isInit = false
  copyMem(result.dataPointer, a.dataPointer, n)

proc isUpperAscii(c: char): bool {.inline.} =
  # avoids import strutils.isUpperAscii
  c in {'A'..'Z'}

proc toLowerAscii*(a: var string) =
  ## optimized and inplace overload of strutils.toLowerAscii
  # refs https://github.com/timotheecour/Nim/pull/54
  # this is 10X faster than a naive implementation using a an optimization trick
  # that can be adapted in similar contexts. Predictable writes avoid write
  # hazards and lead to better machine code, compared to random writes arising
  # from: `if c.isUpperAscii: c = ...`
  for c in mitems(a):
    c = chr(c.ord + (if c.isUpperAscii: (ord('a') - ord('A')) else: 0))
