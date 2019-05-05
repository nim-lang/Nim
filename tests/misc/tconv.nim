template reject(x) =
    static: assert(not compiles(x))

reject:
    const i = int8(300)

type
    R = range[0..10]

reject:
    const r = R(11)

reject:
    const x = R(11.0)

reject:
    const y = R(NaN)

reject:
    const z = R(Inf)

type
    FloatRange = range[0'f..10'f]

reject:
    const x = FloatRange(-1'f)

reject:
    const y = FloatRange(-1)

reject:
    const z = FloatRange(NaN)

type E = enum a, b, c

reject:
    const e = E(4)
