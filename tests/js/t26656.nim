# bug #26656

let ys = @[1104145649'i32, 1234567891'i32]
let zs = @[0xFFFFFFFF'u32]
doAssert zs[0] * zs[0] == 1'u32
doAssert ys[0] *% ys[1] == 1819290787'i32

var u = 0xFFFFFFFF'u32
u *= 0xFFFFFFFF'u32
doAssert u == 1'u32
