discard """
  action: "compile"
"""

# A vector space over a field F concept.
type VectorSpace*[F] = concept x, y, type V
  vector_add(x, y) is V
  scalar_mul(x, F) is V
  dimension(V) is Natural

# Real numbers (here floats) form a vector space.
func vector_add*(v: float, w: float): float =  v + w
func scalar_mul*(v: float, s: float): float =   v * s
func dimension*(x: typedesc[float]): Natural = 1

# 2-tuples of real numbers form a vector space.
func vector_add*(v, w: (float, float)): (float, float) =
  (vector_add(v[0], w[0]), vector_add(v[1], w[1]))

func scalar_mul*(v: (float, float), s: float): (float, float) =
  (scalar_mul(v[0], s), scalar_mul(v[1], s))

func dimension*(x: typedesc[(float, float)]): Natural = 2

# Check concept requirements.
assert float is VectorSpace
assert (float, float) is VectorSpace

# Commutivity axiom for vector spaces over the same field.
func axiom_commutivity*[F](u, v: VectorSpace[F]): bool =
  vector_add(u, v) == vector_add(v, u)

# This is okay.
assert axiom_commutivity(2.2, 3.3)

# This is not.
assert axiom_commutivity((2.2, 3.3), (4.4, 5.5))
