discard """
  description: '''metamorphic IC: expression-based `let x = case ...` idiom'''
"""

# nimbus-eth2 leans on expression-style code (`let x = case ...` rather than
# statement assignment). This exercises that construct through the incremental
# path: a body edit that adds a `case` branch stays local to the module, while a
# return-type change (interface edit) propagates to the importer even though the
# importer's source is byte-identical. See doc/ic_ideas.md.

#? metamorphic

#!FILE classify.nim
proc classify*(n: int): string =
  let kind = case n
    of 0: "zero"
    of 1, 2, 3: "small"
    else: "big"
  result = kind & "(" & $n & ")"

#!FILE main.nim
import classify
echo classify(0), " ", classify(2), " ", classify(99)

#!STEP expect: zero(0) small(2) big(99)

# --- body edit: add a `case` branch and tweak a label. The signature is
#     unchanged, so no interface cookie changes and only `classify` rebuilds.
#!FILE classify.nim
proc classify*(n: int): string =
  let kind = case n
    of 0: "ZERO"
    of 1, 2, 3: "small"
    of 4, 5, 6: "medium"
    else: "big"
  result = kind & "(" & $n & ")"

#!STEP expect: ZERO(0) small(2) big(99); body-edit; modules: 1

# --- re-emit identical content: nothing may change.
#!FILE classify.nim
proc classify*(n: int): string =
  let kind = case n
    of 0: "ZERO"
    of 1, 2, 3: "small"
    of 4, 5, 6: "medium"
    else: "big"
  result = kind & "(" & $n & ")"

#!STEP expect: ZERO(0) small(2) big(99); noop

# --- interface edit: the expression-`case` now yields `int`, changing
#     `classify`'s return type. `main`'s source is byte-identical (`echo` prints
#     either) yet must re-sem & recodegen -> the cookie changes and 2 modules
#     rebuild. The final step also runs the clean==incremental check.
#!FILE classify.nim
proc classify*(n: int): int =
  result = case n
    of 0: 0
    of 1, 2, 3: 1
    of 4, 5, 6: 5
    else: 9

#!STEP expect: 0 1 9; iface-edit; modules: 2
