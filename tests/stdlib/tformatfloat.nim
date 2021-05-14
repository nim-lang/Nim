import system/formatfloat

const N = 65
var buffer: array[N, char]
let x = 1.234
let blen = writeFloatToBuffer(buffer, x)
doAssert cast[cstring](buffer[0].addr) == "1.234"
