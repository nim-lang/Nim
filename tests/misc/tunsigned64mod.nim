
# bug #1638

import unsigned

let v1 = 7
let v2 = 7'u64

let t1 = v1 mod 2 # works
let t2 = 7'u64 mod 2'u64 # works
let t3 = v2 mod 2'u64 # Error: invalid type: 'range 0..1(uint64)
let t4 = (v2 mod 2'u64).uint64 # works

# bug #2550

var x: uint # doesn't work
echo x mod 2 == 0

var y: uint64 # doesn't work
echo y mod 2 == 0

var z: uint32 # works
echo z mod 2 == 0

var a: int # works
echo a mod 2 == 0
