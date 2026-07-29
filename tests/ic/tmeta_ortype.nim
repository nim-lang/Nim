discard """
  description: '''metamorphic IC: or-type (type-class union) idiom from nimbus forks.nim'''
"""

# nimbus-eth2 writes a lot of generic code over `A | B | C` type-class unions
# (consensus forks). This models that idiom: a `Fruit = Apple | Banana` union
# with a generic `describe[T: Fruit]` dispatched by `when T is ...`. The generic
# is instantiated in `main`, so editing its body rebuilds both modules, and the
# incremental result must match a clean build. See doc/ic_ideas.md.

#? metamorphic

#!FILE forks.nim
type
  Apple* = object
    weight*: int
  Banana* = object
    length*: int
  Fruit* = Apple | Banana

proc describe*[T: Fruit](x: T): string =
  when T is Apple: "apple " & $x.weight
  else: "banana " & $x.length

#!FILE main.nim
import forks
echo describe(Apple(weight: 5)), " | ", describe(Banana(length: 9))

#!STEP expect: apple 5 | banana 9

# --- edit the generic body (no signature change). The union/constraint is
#     untouched, so no interface cookie changes; but `main` holds the two
#     instantiations, so both modules' codegen rebuilds.
#!FILE forks.nim
type
  Apple* = object
    weight*: int
  Banana* = object
    length*: int
  Fruit* = Apple | Banana

proc describe*[T: Fruit](x: T): string =
  when T is Apple: "APPLE " & $x.weight
  else: "BANANA " & $x.length

#!STEP expect: APPLE 5 | BANANA 9; body-edit; modules: 2

# --- re-emit identical content: nothing may change.
#!FILE forks.nim
type
  Apple* = object
    weight*: int
  Banana* = object
    length*: int
  Fruit* = Apple | Banana

proc describe*[T: Fruit](x: T): string =
  when T is Apple: "APPLE " & $x.weight
  else: "BANANA " & $x.length

#!STEP expect: APPLE 5 | BANANA 9; noop
