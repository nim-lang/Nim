template reject(x) =
    static: assert(not compiles(x))

reject:
    const i = int8(300)

type
    R = range[0..10]

reject:
    const r = R(11)

type E = enum a, b, c

reject:
    const e = E(4) 

reject:
    const i = (500.0).int8

reject:
    const c = NaN.char

reject:
    const i = 9223372036854775808.0.int64
