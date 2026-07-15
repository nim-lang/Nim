discard """
  description: '''metamorphic IC: Result[T, E] (nim-results style) variant-object idiom'''
"""

# nimbus-eth2 threads errors through nim-results' `Result[T, E]`, a generic
# *variant* (case) object. This models a minimal hermetic version and exercises
# the generic-variant cache path across edits: a body edit of a generic accessor,
# adding a public overload (an interface edit), and a no-op — with a final
# clean==incremental check. See doc/ic_ideas.md.

#? metamorphic

#!FILE results.nim
type
  ResultKind = enum rOk, rErr
  Result*[T, E] = object
    case kind: ResultKind
    of rOk: v: T
    of rErr: e: E

proc ok*[T, E](x: T): Result[T, E] = Result[T, E](kind: rOk, v: x)
proc err*[T, E](x: E): Result[T, E] = Result[T, E](kind: rErr, e: x)
proc isOk*[T, E](r: Result[T, E]): bool = r.kind == rOk
proc get*[T, E](r: Result[T, E]): T = r.v
proc error*[T, E](r: Result[T, E]): E = r.e

#!FILE main.nim
import results
proc parse(s: string): Result[int, string] =
  if s == "42": ok[int, string](42)
  else: err[int, string]("bad: " & s)
let a = parse("42")
let b = parse("x")
echo (if a.isOk: $a.get else: a.error), " ", (if b.isOk: $b.get else: b.error)

#!STEP expect: 42 bad: x

# --- body-only edit of a generic accessor (`error`): signature unchanged, so no
#     interface cookie changes; the importer holds the instantiation, so both
#     modules' codegen rebuilds.
#!FILE results.nim
type
  ResultKind = enum rOk, rErr
  Result*[T, E] = object
    case kind: ResultKind
    of rOk: v: T
    of rErr: e: E

proc ok*[T, E](x: T): Result[T, E] = Result[T, E](kind: rOk, v: x)
proc err*[T, E](x: E): Result[T, E] = Result[T, E](kind: rErr, e: x)
proc isOk*[T, E](r: Result[T, E]): bool = r.kind == rOk
proc get*[T, E](r: Result[T, E]): T = r.v
proc error*[T, E](r: Result[T, E]): E = "ERR:" & r.e

#!STEP expect: 42 ERR:bad: x; body-edit; modules: 2

# --- re-emit identical content: nothing may change.
#!FILE results.nim
type
  ResultKind = enum rOk, rErr
  Result*[T, E] = object
    case kind: ResultKind
    of rOk: v: T
    of rErr: e: E

proc ok*[T, E](x: T): Result[T, E] = Result[T, E](kind: rOk, v: x)
proc err*[T, E](x: E): Result[T, E] = Result[T, E](kind: rErr, e: x)
proc isOk*[T, E](r: Result[T, E]): bool = r.kind == rOk
proc get*[T, E](r: Result[T, E]): T = r.v
proc error*[T, E](r: Result[T, E]): E = "ERR:" & r.e

#!STEP expect: 42 ERR:bad: x; noop

# --- interface edit: add a public `get` overload (a new exported signature).
#     `main` doesn't call it, yet importing `results` whose interface changed
#     forces a re-sem; the cookie changes and >= 2 modules rebuild. The final
#     step also runs the clean==incremental check.
#!FILE results.nim
type
  ResultKind = enum rOk, rErr
  Result*[T, E] = object
    case kind: ResultKind
    of rOk: v: T
    of rErr: e: E

proc ok*[T, E](x: T): Result[T, E] = Result[T, E](kind: rOk, v: x)
proc err*[T, E](x: E): Result[T, E] = Result[T, E](kind: rErr, e: x)
proc isOk*[T, E](r: Result[T, E]): bool = r.kind == rOk
proc get*[T, E](r: Result[T, E], fallback: T): T = (if r.kind == rOk: r.v else: fallback)
proc get*[T, E](r: Result[T, E]): T = r.v
proc error*[T, E](r: Result[T, E]): E = "ERR:" & r.e

#!STEP expect: 42 ERR:bad: x; iface-edit; modules: 2
