type
  BackwardsIndex* = distinct int ## Type that is constructed by `^` for
                                 ## reversed array accesses.
                                 ## (See `^ template <#^.t,int>`_)

template `^`*(x: int): BackwardsIndex = BackwardsIndex(x)
  ## Builtin `roof`:idx: operator that can be used for convenient array access.
  ## `a[^x]` is a shortcut for `a[a.len-x]`.
  ##
  ##   ```
  ##   let
  ##     a = [1, 3, 5, 7, 9]
  ##     b = "abcdefgh"
  ##
  ##   echo a[^1] # => 9
  ##   echo b[^2] # => g
  ##   ```

template `^^`*(s, i: untyped): untyped =
  (when i is BackwardsIndex: s.len - int(i) else: int(i))

proc `[]`*[T](s: openArray[T]; i: BackwardsIndex): T {.inline.} =
  system.`[]`(s, s.len - int(i))

proc `[]`*[Idx, T](a: array[Idx, T]; i: BackwardsIndex): T {.inline.} =
  a[Idx(a.len - int(i) + int low(a))]
proc `[]`*(s: string; i: BackwardsIndex): char {.inline.} = s[s.len - int(i)]

proc `[]`*[T](s: var openArray[T]; i: BackwardsIndex): var T {.inline.} =
  system.`[]`(s, s.len - int(i))
proc `[]`*[Idx, T](a: var array[Idx, T]; i: BackwardsIndex): var T {.inline.} =
  a[Idx(a.len - int(i) + int low(a))]
proc `[]`*(s: var string; i: BackwardsIndex): var char {.inline.} = s[s.len - int(i)]

proc `[]=`*[T](s: var openArray[T]; i: BackwardsIndex; x: T) {.inline.} =
  system.`[]=`(s, s.len - int(i), x)
proc `[]=`*[Idx, T](a: var array[Idx, T]; i: BackwardsIndex; x: T) {.inline.} =
  a[Idx(a.len - int(i) + int low(a))] = x
proc `[]=`*(s: var string; i: BackwardsIndex; x: char) {.inline.} =
  s[s.len - int(i)] = x
