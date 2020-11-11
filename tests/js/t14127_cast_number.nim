doAssert cast[int32](-1) is int32
doAssert cast[int32](-1) < 0
doAssert cast[int32](-1) + 1 == 0
doAssert cast[int8](-1) + 1 == 0
doAssert (cast[int32](-1) + 1) is int32
doAssert (cast[int8](-1) + 1) is int8