template forwardImpl*(impl, arg) {.dirty.} =
  when sizeof(x) <= 4:
    when x is SomeSignedInt:
      impl(cast[uint32](x.int32))
    else:
      impl(x.uint32)
  else:
    when x is SomeSignedInt:
      impl(cast[uint64](x.int64))
    else:
      impl(x.uint64)

template toUnsigned*(x: int8): uint8 = cast[uint8](x)
template toUnsigned*(x: int16): uint16 = cast[uint16](x)
template toUnsigned*(x: int32): uint32 = cast[uint32](x)
template toUnsigned*(x: int64): uint64 = cast[uint64](x)
template toUnsigned*(x: int): uint = cast[uint](x)

when defined(nimSeqsV2):
  # sync with system.movingCopy
  template movingCopy(a, b) =
    a = move(b)
else:
  template movingCopy(a, b) =
    shallowCopy(a, b)

func delete*[T](x: var seq[T], i: Natural) =
  ## Deletes the item at index `i` by moving all `x[i+1..^1]` items by one position.
  ##
  ## This is an `O(n)` operation.
  ##
  ## See also:
  ## * `del <#del,seq[T],Natural>`_ for O(1) operation
  ##
  runnableExamples:
    var s = @[1, 2, 3, 4, 5]
    s.delete(2)
    doAssert s == @[1, 2, 4, 5]

    doAssertRaises(IndexDefect):
      s.delete(4)

  if i > high(x):
    # xxx this should call `raiseIndexError2(i, high(x))` after some refactoring
    raise (ref IndexDefect)(msg: "index out of bounds: '" & $i & "' < '" & $x.len & "' failed")

  template defaultImpl =
    let xl = x.len
    for j in i.int..xl-2: movingCopy(x[j], x[j+1])
    setLen(x, xl-1)

  when nimvm:
    defaultImpl()
  else:
    when defined(js):
      {.emit: "`x`.splice(`i`, 1);".}
    else:
      defaultImpl()
