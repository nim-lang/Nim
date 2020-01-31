# comparison operators:
func `==`*[Enum: enum](x, y: Enum): bool {.magic: "EqEnum".}
  ## Checks whether values within the *same enum* have the same underlying value.
  ##
  ## .. code-block:: Nim
  ##  type
  ##    Enum1 = enum
  ##      Field1 = 3, Field2
  ##    Enum2 = enum
  ##      Place1, Place2 = 3
  ##  var
  ##    e1 = Field1
  ##    e2 = Enum1(Place2)
  ##  echo (e1 == e2) # true
  ##  echo (e1 == Place2) # raises error
func `==`*(x, y: pointer): bool {.magic: "EqRef".}
  ## .. code-block:: Nim
  ##  var # this is a wildly dangerous example
  ##    a = cast[pointer](0)
  ##    b = cast[pointer](nil)
  ##  echo (a == b) # true due to the special meaning of `nil`/0 as a pointer
func `==`*(x, y: string): bool {.magic: "EqStr".}
  ## Checks for equality between two `string` variables.

func `==`*(x, y: char): bool {.magic: "EqCh".}
  ## Checks for equality between two `char` variables.
func `==`*(x, y: bool): bool {.magic: "EqB".}
  ## Checks for equality between two `bool` variables.
func `==`*[T](x, y: set[T]): bool {.magic: "EqSet".}
  ## Checks for equality between two variables of type `set`.
  ##
  ## .. code-block:: Nim
  ##  var a = {1, 2, 2, 3} # duplication in sets is ignored
  ##  var b = {1, 2, 3}
  ##  echo (a == b) # true
func `==`*[T](x, y: ref T): bool {.magic: "EqRef".}
  ## Checks that two `ref` variables refer to the same item.
func `==`*[T](x, y: ptr T): bool {.magic: "EqRef".}
  ## Checks that two `ptr` variables refer to the same item.
func `==`*[T: proc](x, y: T): bool {.magic: "EqProc".}
  ## Checks that two `proc` variables refer to the same procedure.

func `<=`*[Enum: enum](x, y: Enum): bool {.magic: "LeEnum".}
func `<=`*(x, y: string): bool {.magic: "LeStr".}
  ## Compares two strings and returns true if `x` is lexicographically
  ## before `y` (uppercase letters come before lowercase letters).
  ##
  ## .. code-block:: Nim
  ##     let
  ##       a = "abc"
  ##       b = "abd"
  ##       c = "ZZZ"
  ##     assert a <= b
  ##     assert a <= a
  ##     assert (a <= c) == false
func `<=`*(x, y: char): bool {.magic: "LeCh".}
  ## Compares two chars and returns true if `x` is lexicographically
  ## before `y` (uppercase letters come before lowercase letters).
  ##
  ## .. code-block:: Nim
  ##     let
  ##       a = 'a'
  ##       b = 'b'
  ##       c = 'Z'
  ##     assert a <= b
  ##     assert a <= a
  ##     assert (a <= c) == false
func `<=`*[T](x, y: set[T]): bool {.magic: "LeSet".}
  ## Returns true if `x` is a subset of `y`.
  ##
  ## A subset `x` has all of its members in `y` and `y` doesn't necessarily
  ## have more members than `x`. That is, `x` can be equal to `y`.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = {3, 5}
  ##     b = {1, 3, 5, 7}
  ##     c = {2}
  ##   assert a <= b
  ##   assert a <= a
  ##   assert (a <= c) == false
func `<=`*(x, y: bool): bool {.magic: "LeB".}
func `<=`*[T](x, y: ref T): bool {.magic: "LePtr".}
func `<=`*(x, y: pointer): bool {.magic: "LePtr".}

func `<`*[Enum: enum](x, y: Enum): bool {.magic: "LtEnum".}
func `<`*(x, y: string): bool {.magic: "LtStr".}
  ## Compares two strings and returns true if `x` is lexicographically
  ## before `y` (uppercase letters come before lowercase letters).
  ##
  ## .. code-block:: Nim
  ##     let
  ##       a = "abc"
  ##       b = "abd"
  ##       c = "ZZZ"
  ##     assert a < b
  ##     assert (a < a) == false
  ##     assert (a < c) == false
func `<`*(x, y: char): bool {.magic: "LtCh".}
  ## Compares two chars and returns true if `x` is lexicographically
  ## before `y` (uppercase letters come before lowercase letters).
  ##
  ## .. code-block:: Nim
  ##     let
  ##       a = 'a'
  ##       b = 'b'
  ##       c = 'Z'
  ##     assert a < b
  ##     assert (a < a) == false
  ##     assert (a < c) == false
func `<`*[T](x, y: set[T]): bool {.magic: "LtSet".}
  ## Returns true if `x` is a strict or proper subset of `y`.
  ##
  ## A strict or proper subset `x` has all of its members in `y` but `y` has
  ## more elements than `y`.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = {3, 5}
  ##     b = {1, 3, 5, 7}
  ##     c = {2}
  ##   assert a < b
  ##   assert (a < a) == false
  ##   assert (a < c) == false
func `<`*(x, y: bool): bool {.magic: "LtB".}
func `<`*[T](x, y: ref T): bool {.magic: "LtPtr".}
func `<`*[T](x, y: ptr T): bool {.magic: "LtPtr".}
func `<`*(x, y: pointer): bool {.magic: "LtPtr".}

template `!=`*(x, y: untyped): untyped =
  ## Unequals operator. This is a shorthand for ``not (x == y)``.
  not (x == y)

template `>=`*(x, y: untyped): untyped =
  ## "is greater or equals" operator. This is the same as ``y <= x``.
  y <= x

template `>`*(x, y: untyped): untyped =
  ## "is greater" operator. This is the same as ``y < x``.
  y < x


func `==`*(x, y: int): bool {.magic: "EqI".}
  ## Compares two integers for equality.
func `==`*(x, y: int8): bool {.magic: "EqI".}
func `==`*(x, y: int16): bool {.magic: "EqI".}
func `==`*(x, y: int32): bool {.magic: "EqI".}
func `==`*(x, y: int64): bool {.magic: "EqI".}

func `<=`*(x, y: int): bool {.magic: "LeI".}
  ## Returns true if `x` is less than or equal to `y`.
func `<=`*(x, y: int8): bool {.magic: "LeI".}
func `<=`*(x, y: int16): bool {.magic: "LeI".}
func `<=`*(x, y: int32): bool {.magic: "LeI".}
func `<=`*(x, y: int64): bool {.magic: "LeI".}

func `<`*(x, y: int): bool {.magic: "LtI".}
  ## Returns true if `x` is less than `y`.
func `<`*(x, y: int8): bool {.magic: "LtI".}
func `<`*(x, y: int16): bool {.magic: "LtI".}
func `<`*(x, y: int32): bool {.magic: "LtI".}
func `<`*(x, y: int64): bool {.magic: "LtI".}


func `<=%`*(x, y: IntMax32): bool {.magic: "LeU".}
func `<=%`*(x, y: int64): bool {.magic: "LeU64".}
  ## Treats `x` and `y` as unsigned and compares them.
  ## Returns true if ``unsigned(x) <= unsigned(y)``.

func `<%`*(x, y: IntMax32): bool {.magic: "LtU".}
func `<%`*(x, y: int64): bool {.magic: "LtU64".}
  ## Treats `x` and `y` as unsigned and compares them.
  ## Returns true if ``unsigned(x) < unsigned(y)``.

template `>=%`*(x, y: untyped): untyped = y <=% x
  ## Treats `x` and `y` as unsigned and compares them.
  ## Returns true if ``unsigned(x) >= unsigned(y)``.

template `>%`*(x, y: untyped): untyped = y <% x
  ## Treats `x` and `y` as unsigned and compares them.
  ## Returns true if ``unsigned(x) > unsigned(y)``.


func `==`*(x, y: uint): bool {.magic: "EqI".}
  ## Compares two unsigned integers for equality.
func `==`*(x, y: uint8): bool {.magic: "EqI".}
func `==`*(x, y: uint16): bool {.magic: "EqI".}
func `==`*(x, y: uint32): bool {.magic: "EqI".}
func `==`*(x, y: uint64): bool {.magic: "EqI".}


func `<=`*(x, y: uint): bool {.magic: "LeU".}
  ## Returns true if ``x <= y``.
func `<=`*(x, y: uint8): bool {.magic: "LeU".}
func `<=`*(x, y: uint16): bool {.magic: "LeU".}
func `<=`*(x, y: uint32): bool {.magic: "LeU".}
func `<=`*(x, y: uint64): bool {.magic: "LeU".}

func `<`*(x, y: uint): bool {.magic: "LtU".}
  ## Returns true if ``unsigned(x) < unsigned(y)``.
func `<`*(x, y: uint8): bool {.magic: "LtU".}
func `<`*(x, y: uint16): bool {.magic: "LtU".}
func `<`*(x, y: uint32): bool {.magic: "LtU".}
func `<`*(x, y: uint64): bool {.magic: "LtU".}


{.push stackTrace: off.}

func min*(x, y: int): int {.magic: "MinI".} =
  if x <= y: x else: y
func min*(x, y: int8): int8 {.magic: "MinI".} =
  if x <= y: x else: y
func min*(x, y: int16): int16 {.magic: "MinI".} =
  if x <= y: x else: y
func min*(x, y: int32): int32 {.magic: "MinI".} =
  if x <= y: x else: y
func min*(x, y: int64): int64 {.magic: "MinI".} =
  ## The minimum value of two integers.
  if x <= y: x else: y

func max*(x, y: int): int {.magic: "MaxI".} =
  if y <= x: x else: y
func max*(x, y: int8): int8 {.magic: "MaxI".} =
  if y <= x: x else: y
func max*(x, y: int16): int16 {.magic: "MaxI".} =
  if y <= x: x else: y
func max*(x, y: int32): int32 {.magic: "MaxI".} =
  if y <= x: x else: y
func max*(x, y: int64): int64 {.magic: "MaxI".} =
  ## The maximum value of two integers.
  if y <= x: x else: y


func min*[T](x: openArray[T]): T =
  ## The minimum value of `x`. ``T`` needs to have a ``<`` operator.
  result = x[0]
  for i in 1..high(x):
    if x[i] < result: result = x[i]

func max*[T](x: openArray[T]): T =
  ## The maximum value of `x`. ``T`` needs to have a ``<`` operator.
  result = x[0]
  for i in 1..high(x):
    if result < x[i]: result = x[i]

{.pop.} # stackTrace: off


func clamp*[T](x, a, b: T): T =
  ## Limits the value ``x`` within the interval [a, b].
  ##
  ## .. code-block:: Nim
  ##   assert((1.4).clamp(0.0, 1.0) == 1.0)
  ##   assert((0.5).clamp(0.0, 1.0) == 0.5)
  if x < a: return a
  if x > b: return b
  return x


func `==`*[I, T](x, y: array[I, T]): bool =
  for f in low(x)..high(x):
    if x[f] != y[f]:
      return
  result = true

func `==`*[T](x, y: openArray[T]): bool =
  if x.len != y.len:
    return false
  for f in low(x)..high(x):
    if x[f] != y[f]:
      return false
  result = true


func `==`*[T](x, y: seq[T]): bool {.noSideEffect.} =
  ## Generic equals operator for sequences: relies on a equals operator for
  ## the element type `T`.
  when nimvm:
    when not defined(nimNoNil):
      if x.isNil and y.isNil:
        return true
    else:
      if x.len == 0 and y.len == 0:
        return true
  else:
    when not defined(js):
      proc seqToPtr[T](x: seq[T]): pointer {.inline, noSideEffect.} =
        when defined(nimSeqsV2):
          result = cast[NimSeqV2[T]](x).p
        else:
          result = cast[pointer](x)

      if seqToPtr(x) == seqToPtr(y):
        return true
    else:
      var sameObject = false
      asm """`sameObject` = `x` === `y`"""
      if sameObject: return true

  when not defined(nimNoNil):
    if x.isNil or y.isNil:
      return false

  if x.len != y.len:
    return false

  for i in 0..x.len-1:
    if x[i] != y[i]:
      return false

  return true
