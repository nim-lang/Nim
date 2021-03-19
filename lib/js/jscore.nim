#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module wraps core JavaScript functions.
##
## Unless your application has very
## specific requirements and solely targets JavaScript, you should be using
## the relevant functions in the `math`, `json`, and `times` stdlib
## modules instead.
import std/private/since

when not defined(js):
  {.error: "This module only works on the JavaScript platform".}

type
  MathLib* = ref object
  JsonLib* = ref object
  DateLib* = ref object
  DateTime* = ref object

var
  Math* {.importjs, nodecl.}: MathLib
  Date* {.importjs, nodecl.}: DateLib
  JSON* {.importjs, nodecl.}: JsonLib

# Math library
proc abs*(m: MathLib, a: SomeNumber): SomeNumber {.importjs.}
proc acos*(m: MathLib, a: SomeNumber): float {.importjs.}
proc acosh*(m: MathLib, a: SomeNumber): float {.importjs.}
proc asin*(m: MathLib, a: SomeNumber): float {.importjs.}
proc asinh*(m: MathLib, a: SomeNumber): float {.importjs.}
proc atan*(m: MathLib, a: SomeNumber): float {.importjs.}
proc atan2*(m: MathLib, a: SomeNumber): float {.importjs.}
proc atanh*(m: MathLib, a: SomeNumber): float {.importjs.}
proc cbrt*(m: MathLib, f: SomeFloat): SomeFloat {.importjs.}
proc ceil*(m: MathLib, f: SomeFloat): SomeFloat {.importjs.}
proc clz32*(m: MathLib, f: SomeInteger): int {.importjs.}
proc cos*(m: MathLib, a: SomeNumber): float {.importjs.}
proc cosh*(m: MathLib, a: SomeNumber): float {.importjs.}
proc exp*(m: MathLib, a: SomeNumber): float {.importjs.}
proc expm1*(m: MathLib, a: SomeNumber): float {.importjs.}
proc floor*(m: MathLib, f: SomeFloat): int {.importjs.}
proc fround*(m: MathLib, f: SomeFloat): float32 {.importjs.}
proc hypot*(m: MathLib, args: varargs[distinct SomeNumber]): float {.importjs.}
proc imul*(m: MathLib, a, b: int32): int32 {.importjs.}
proc log*(m: MathLib, a: SomeNumber): float {.importjs.}
proc log10*(m: MathLib, a: SomeNumber): float {.importjs.}
proc log1p*(m: MathLib, a: SomeNumber): float {.importjs.}
proc log2*(m: MathLib, a: SomeNumber): float {.importjs.}
proc max*(m: MathLib, a, b: SomeNumber): SomeNumber {.importjs.}
proc min*[T: SomeNumber | JsRoot](m: MathLib, a, b: T): T {.importjs.}
proc pow*(m: MathLib, a, b: distinct SomeNumber): float {.importjs.}
proc random*(m: MathLib): float {.importjs.}
proc round*(m: MathLib, f: SomeFloat): int {.importjs.}
proc sign*(m: MathLib, f: SomeNumber): int {.importjs.}
proc sin*(m: MathLib, a: SomeNumber): float {.importjs.}
proc sinh*(m: MathLib, a: SomeNumber): float {.importjs.}
proc sqrt*(m: MathLib, f: SomeFloat): SomeFloat {.importjs.}
proc tan*(m: MathLib, a: SomeNumber): float {.importjs.}
proc tanh*(m: MathLib, a: SomeNumber): float {.importjs.}
proc trunc*(m: MathLib, f: SomeFloat): int {.importjs.}

# Date library
proc now*(d: DateLib): int {.importjs.}
proc UTC*(d: DateLib): int {.importjs.}
proc parse*(d: DateLib, s: cstring): int {.importjs.}

proc newDate*(): DateTime {.
  importjs: "new Date()".}

proc newDate*(date: int|int64|string): DateTime {.
  importjs: "new Date(#)".}

proc newDate*(year, month, day, hours, minutes,
             seconds, milliseconds: int): DateTime {.
  importjs: "new Date(#,#,#,#,#,#,#)".}

proc getDay*(d: DateTime): int {.importjs.}
proc getFullYear*(d: DateTime): int {.importjs.}
proc getHours*(d: DateTime): int {.importjs.}
proc getMilliseconds*(d: DateTime): int {.importjs.}
proc getMinutes*(d: DateTime): int {.importjs.}
proc getMonth*(d: DateTime): int {.importjs.}
proc getSeconds*(d: DateTime): int {.importjs.}
proc getYear*(d: DateTime): int {.importjs.}
proc getTime*(d: DateTime): int {.importjs.}
proc toString*(d: DateTime): cstring {.importjs.}
proc getUTCDate*(d: DateTime): int {.importjs.}
proc getUTCFullYear*(d: DateTime): int {.importjs.}
proc getUTCHours*(d: DateTime): int {.importjs.}
proc getUTCMilliseconds*(d: DateTime): int {.importjs.}
proc getUTCMinutes*(d: DateTime): int {.importjs.}
proc getUTCMonth*(d: DateTime): int {.importjs.}
proc getUTCSeconds*(d: DateTime): int {.importjs.}
proc getUTCDay*(d: DateTime): int {.importjs.}
proc getTimezoneOffset*(d: DateTime): int {.importjs.}
proc setFullYear*(d: DateTime, year: int) {.importjs.}

#JSON library
proc stringify*(l: JsonLib, s: JsRoot): cstring {.importjs.}
proc parse*(l: JsonLib, s: cstring): JsRoot {.importjs.}


since (1, 5):
  func debugger*() {.importjs: "debugger@".}
    ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/debugger
