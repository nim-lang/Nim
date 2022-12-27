discard """
  joinable: false
"""

{.passC: "-flto".}
{.passL: "-flto".}

template f(n: int) = discard card(default(set[range[0 .. (1 shl n) - 1]]))
f( 7)
f( 8)
f( 9)
f(10)
f(11)
f(12)
f(13)
f(14)
f(15)
f(16)
