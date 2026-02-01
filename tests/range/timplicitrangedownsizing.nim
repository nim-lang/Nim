discard """
cmd: "nim check $options --hints:off --warning:ImplicitRangeConversion --warningaserror:ImplicitRangeConversion $file"
action: "reject"
nimout: '''
timplicitrangedownsizing.nim(22, 5) Error: implicit range conversion int -> FakeUint8 [ImplicitRangeConversion]
timplicitrangedownsizing.nim(24, 5) Error: implicit range conversion OffByOneRange -> FakeUint8 [ImplicitRangeConversion]
timplicitrangedownsizing.nim(28, 5) Error: implicit range conversion int -> FakeUint8 [ImplicitRangeConversion]
timplicitrangedownsizing.nim(55, 6) Error: implicit range conversion float64 -> SmallFloat [ImplicitRangeConversion]
timplicitrangedownsizing.nim(59, 6) Error: implicit range conversion FloatRange -> SmallFloat [ImplicitRangeConversion]
timplicitrangedownsizing.nim(63, 6) Error: implicit range conversion float64 -> SmallFloat [ImplicitRangeConversion]
'''
"""
# Integer range tests
type FakeUint8 = range[0..255]
type OffByOneRange = range[1..256]
type WideRange = range[0..65535]

var v: FakeUint8
var x = 256
var y = OffByOneRange(256)

v = x # panics, should trigger warning
v = FakeUint8(x) # panics, should not trigger warning
v = y # panics should trigger warning

proc xxx(v: FakeUint8)= discard

xxx(x) # panics, should trigger warning
xxx(FakeUint8(x)) # panics, should not trigger warning

# Test narrower to wider range conversions (should NOT warn)
proc acceptWide(v: WideRange) = discard

var smallRange: FakeUint8 = FakeUint8(100)
acceptWide(smallRange)  # OK - FakeUint8 (0..255) fits in WideRange (0..65535)

var medRange: OffByOneRange = OffByOneRange(150)
acceptWide(medRange)  # OK - OffByOneRange (1..256) fits in WideRange (0..65535)

var w: WideRange
w = smallRange  # OK - FakeUint8 range fits in WideRange
w = medRange    # OK - OffByOneRange range fits in WideRange

# Test narrower range passed to function (should NOT warn)
xxx(smallRange)  # OK - FakeUint8 value fits in range[0..255]

# Float range tests
type SmallFloat = range[0.0..10.0]
type FloatRange = range[5.0..15.0]
type WideFloatRange = range[0.0..100.0]

var fv: SmallFloat
var fx = 11.5  # Out of range

fv = fx  # panics, should trigger warning
fv = SmallFloat(fx)  # panics, should not trigger warning

var fy = FloatRange(7.5)
fv = fy  # panics, should trigger warning (5.0..15.0 → 0.0..10.0)

proc fffx(v: SmallFloat) = discard

fffx(fx)  # panics, should trigger warning
fffx(SmallFloat(fx))  # panics, should not trigger warning

# Test narrower to wider float range conversions (should NOT warn)
proc acceptWideFloat(v: WideFloatRange) = discard

var smallFloatRange: SmallFloat = SmallFloat(5.0)
acceptWideFloat(smallFloatRange)  # OK - SmallFloat (0.0..10.0) fits in WideFloatRange (0.0..100.0)

var wf: WideFloatRange
wf = smallFloatRange  # OK - SmallFloat range fits in WideFloatRange