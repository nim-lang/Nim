discard """
  output: '''
p 1 20
p 1000 200
p 1 1
p 1000 1000
p 1 1000
p 1000 1
p 1 200
p 1000 20
'''
"""

# issue #4554

type
  G[N:static[int]] = object
    v: int
  F[N:static[int]] = object
    v: int

converter G2int[N:static[int]](x:G[N]):int = x.v
converter F2int[N:static[int]](x:F[N]):int = x.v
proc p(x,y:int) = echo "p ",x," ",y
var
  g1 = G[1](v:1)
  g2 = G[2](v:20)
  f1 = F[1](v:1000)
  f2 = F[2](v:200)
p(g1,g2)    # Error: type mismatch: got (G[1], G[2])
p(f1,f2)    # Error: type mismatch: got (F[1], F[2])
p(g1,g1)    # compiles
p(f1,f1)    # compiles
p(g1,f1)    # compiles
p(f1,g1)    # compiles
p(g1,f2)    # compiles
p(f1,g2)    # compiles
