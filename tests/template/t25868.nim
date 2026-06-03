discard """
  matrix: "--mm:orc; --mm:arc; --mm:refc"
"""

# bug #25868: a named tuple passed through a `static` or `template` parameter could only be
# accessed positionally (layout[0]), not by field name (layout.shape), because an anonymous
# tuple literal kept its nameless type instead of the formal's named type.

block template_and_static:
  template t(layout: tuple[shape, strides: int]): (int, int) = (layout.shape, layout.strides)
  doAssert t((2, 4)) == (2, 4)
  proc p(layout: static[tuple[shape, strides: int]]): (int, int) = (layout.shape, layout.strides)
  doAssert p((2, 4)) == (2, 4)

block concept_field:  # the original report: template + static + nested + a concept field type
  type
    IntTuple = concept x
      x is tuple
      for field in fields(x):
        field is IntOrIntTuple
    IntOrIntTuple = int or IntTuple
  template coalesce(layout: static[tuple[shape, strides: IntOrIntTuple]]): untyped =
    (layout.shape, layout.strides)
  let r = coalesce(((2, 4, 6, 8), (1, 2, 8, 48)))
  doAssert r[0] == (2, 4, 6, 8)
  doAssert r[1] == (1, 2, 8, 48)

block named_literal_unaffected:  # a literal that already carries names must stay working
  template t(layout: tuple[shape, strides: int]): int = layout.shape
  doAssert t((shape: 2, strides: 4)) == 2
  proc p(layout: static[tuple[shape, strides: int]]): int = layout.shape
  doAssert p((shape: 2, strides: 4)) == 2

block incompatible_rejected:  # the relabel must not accept structurally-wrong tuples
  proc p(layout: static[tuple[shape, strides: int]]): int = layout.shape
  doAssert not compiles(p((1, 2, 3)))   # wrong arity
  doAssert not compiles(p((1, "x")))    # wrong field type
