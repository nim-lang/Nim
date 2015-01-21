discard """
  output: "0.0"
"""

# bug #1919

type
  Base[M] = object of RootObj
    a : M

  Sub1[M] = object of Base[M]
    b : int

  Sub2[M] = object of Sub1[M]
    c : int

var x: Sub2[float]

echo x.a
