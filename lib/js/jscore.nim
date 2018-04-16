## This module wraps core JavaScript functions.
##
## Unless your application has very
## specific requirements and solely targets JavaScript, you should be using
## the relevant functions in the ``math``, ``json``, and ``times`` stdlib
## modules instead.

when not defined(js) and not defined(Nimdoc):
  {.error: "This module only works on the JavaScript platform".}

type
  MathLib* = ref object
  JsonLib* = ref object
  DateLib* = ref object
  DateTime* = ref object

var
  Math* {.importc, nodecl.}: MathLib
  Date* {.importc, nodecl.}: DateLib
  JSON* {.importc, nodecl.}: JsonLib

{.push importcpp.}

# Math library
proc abs*(m: MathLib, a: SomeNumber): SomeNumber
proc acos*(m: MathLib, a: SomeNumber): float
proc acosh*(m: MathLib, a: SomeNumber): float
proc asin*(m: MathLib, a: SomeNumber): float
proc asinh*(m: MathLib, a: SomeNumber): float
proc atan*(m: MathLib, a: SomeNumber): float
proc atan2*(m: MathLib, a: SomeNumber): float
proc atanh*(m: MathLib, a: SomeNumber): float
proc cbrt*(m: MathLib, f: SomeFloat): SomeFloat
proc ceil*(m: MathLib, f: SomeFloat): SomeFloat
proc clz32*(m: MathLib, f: SomeInteger): int
proc cos*(m: MathLib, a: SomeNumber): float
proc cosh*(m: MathLib, a: SomeNumber): float
proc exp*(m: MathLib, a: SomeNumber): float
proc expm1*(m: MathLib, a: SomeNumber): float
proc floor*(m: MathLib, f: SomeFloat): int
proc fround*(m: MathLib, f: SomeFloat): float32
proc hypot*(m: MathLib, args: varargs[distinct SomeNumber]): float
proc imul*(m: MathLib, a, b: int32): int32
proc log*(m: MathLib, a: SomeNumber): float
proc log10*(m: MathLib, a: SomeNumber): float
proc log1p*(m: MathLib, a: SomeNumber): float
proc log2*(m: MathLib, a: SomeNumber): float
proc max*(m: MathLib, a, b: SomeNumber): SomeNumber
proc min*[T: SomeNumber | JsRoot](m: MathLib, a, b: T): T
proc pow*(m: MathLib, a, b: distinct SomeNumber): float
proc random*(m: MathLib): float
proc round*(m: MathLib, f: SomeFloat): int
proc sign*(m: MathLib, f: SomeNumber): int
proc sin*(m: MathLib, a: SomeNumber): float
proc sinh*(m: MathLib, a: SomeNumber): float
proc sqrt*(m: MathLib, f: SomeFloat): SomeFloat
proc tan*(m: MathLib, a: SomeNumber): float
proc tanh*(m: MathLib, a: SomeNumber): float
proc trunc*(m: MathLib, f: SomeFloat): int

# Date library
proc now*(d: DateLib): int
proc UTC*(d: DateLib): int
proc parse*(d: DateLib, s: cstring): int

proc newDate*(): DateTime {.
  importcpp: "new Date()".}

proc newDate*(date: int|string): DateTime {.
  importcpp: "new Date(#)".}

proc newDate*(year, month, day, hours, minutes,
             seconds, milliseconds: int): DateTime {.
  importcpp: "new Date(#,#,#,#,#,#,#)".}

proc getDay*(d: DateTime): int
proc getFullYear*(d: DateTime): int
proc getHours*(d: DateTime): int
proc getMilliseconds*(d: DateTime): int
proc getMinutes*(d: DateTime): int
proc getMonth*(d: DateTime): int
proc getSeconds*(d: DateTime): int
proc getYear*(d: DateTime): int
proc getTime*(d: DateTime): int
proc toString*(d: DateTime): cstring

#JSON library
proc stringify*(l: JsonLib, s: JsRoot): cstring
proc parse*(l: JsonLib, s: cstring): JsRoot

{.pop.}
