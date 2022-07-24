import ../../lib/system/memory

# "Test 1: Zero-length copy."
var dest1: array[3, byte] = [0xa.byte, 0xb.byte, 0xc.byte]
var source1: array[3, byte] = [0x1.byte, 0x2.byte, 0x3.byte]
let size1: Natural = 0

nimMoveMem(dest1[0].addr, source1[0].addr, size1)
assert(dest1 == [0xa.byte, 0xb.byte, 0xc.byte])

# Test 2: Overlap, left-to-right.
var arr2: array[6, byte] = [0x1.byte, 0x2.byte, 0x3.byte, 0xa.byte, 0xb.byte, 0xc.byte]
let size2: Natural = 4

nimMoveMem(arr2[1].addr, arr2[2].addr, size2)
assert(arr2 == [0x1.byte, 0x3.byte, 0xa.byte, 0xb.byte, 0xc.byte, 0xc.byte])

# Test 3: Overlap, right-to-left.
var arr3: array[6, byte] = [0x1.byte, 0x2.byte, 0x3.byte, 0xa.byte, 0xb.byte, 0xc.byte]
let size3: Natural = 4

nimMoveMem(arr3[2].addr, arr3[0].addr, size3)
assert(arr3 == [0x1.byte, 0x2.byte, 0x1.byte, 0x2.byte, 0x3.byte, 0xa.byte])

# Test 4: 100% overlap.
var arr4: array[6, byte] = [0x1.byte, 0x2.byte, 0x3.byte, 0x4.byte, 0x5.byte, 0x6.byte]
let size4: Natural = 6

nimMoveMem(arr4[0].addr, arr4[0].addr, size4)
assert(arr4 == [0x1.byte, 0x2.byte, 0x3.byte, 0x4.byte, 0x5.byte, 0x6.byte])

var dest4: array[6, byte] = [0x1.byte, 0x2.byte, 0x3.byte, 0x4.byte, 0x5.byte, 0x6.byte]
var source4: array[6, byte] = [0x6.byte, 0x5.byte, 0x4.byte, 0x3.byte, 0x2.byte, 0x1.byte]
nimMoveMem(dest4[0].addr, source4[0].addr, size4)
assert(dest4 == [0x6.byte, 0x5.byte, 0x4.byte, 0x3.byte, 0x2.byte, 0x1.byte])

# Test 5: Basic test
var dest5: array[7, byte] = [0x1.byte, 0x2.byte, 0x3.byte, 0x4.byte, 0x5.byte, 0x6.byte, 0x7.byte]
var source5: array[4, byte] = [0xa.byte, 0xb.byte, 0xc.byte, 0xd.byte]
let size5: Natural = 4

nimMoveMem(dest5[1].addr, source5[0].addr, size5)
assert(dest5 == [0x1.byte, 0xa.byte, 0xb.byte, 0xc.byte, 0xd.byte, 0x6.byte, 0x7.byte])
