
# bug #4345

# only needs to compile
proc f(): tuple[a, b: uint8] = (1'u8, 2'u8)

let a, b = f()
let c = cast[int](b)
