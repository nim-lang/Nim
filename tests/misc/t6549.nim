
const l = $(range[low(uint64) .. high(uint64)])
const r = "range 0..18446744073709551615(uint64)"
doAssert l == r
