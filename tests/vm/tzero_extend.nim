
const RANGE = -384.. -127

proc get_values(): (seq[int8], seq[int16], seq[int32]) =
  let i8 = -3'i8
  let i16 = -3'i16
  let i32 = -3'i32
  doAssert i8.ze == 0xFD
  doAssert i8.ze64 == 0xFD
  doAssert i16.ze == 0xFFFD
  doAssert i16.ze64 == 0xFFFD

  result[0] = @[]; result[1] = @[]; result[2] = @[]

  for offset in RANGE:
    let i8  = -(1'i64 shl  9) + offset
    let i16 = -(1'i64 shl 17) + offset
    let i32 = -(1'i64 shl 33) + offset

    # higher bits are masked. these should be exactly equal to offset.
    result[0].add cast[int8](cast[uint64](i8))
    result[1].add cast[int16](cast[uint64](i16))
    result[2].add cast[int32](cast[uint64](i32))


# these values this computed by VM
const COMPILETIME_VALUES = get_values()

# these values this computed by compiler
let RUNTIME_VALUES = get_values()

template check_values(int_type: static[int]) =
  var index = 0
  let cvalues = COMPILETIME_VALUES[int_type]
  let rvalues = RUNTIME_VALUES[int_type]
  for offset in RANGE:
    let moffset = cast[type(rvalues[0])](offset)
    doAssert(moffset == rvalues[index] and moffset == cvalues[index],
      "expected: " & $moffset & " got runtime: " & $rvalues[index] & " && compiletime: " & $cvalues[index] )
    inc(index)

check_values(0) # uint8
check_values(1) # uint16
check_values(2) # uint32
