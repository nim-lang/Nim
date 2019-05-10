template reject(x) =
    static: assert(not compiles(x))

reject:
    const x = int8(300)

reject:
    const x = int64(NaN)

type
    R = range[0..10]

reject:
    const x = R(11)

reject:
    const x = R(11.0)

reject:
    const x = R(NaN)

reject:
    const x = R(Inf)

type
    FloatRange = range[0'f..10'f]

reject:
    const x = FloatRange(-1'f)

reject:
    const x = FloatRange(-1)

reject:
    const x = FloatRange(NaN)

block:
    const x = float32(NaN)

type E = enum a, b, c

reject:
    const e = E(4)
