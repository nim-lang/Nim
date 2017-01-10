discard """
  output: '''G:0,1:0.1
G:0,1:0.1
H:1:0.1'''
"""

type
  G[i,j:static[int]] = object
    v:float
  H[j:static[int]] = G[0,j]
proc p[i,j:static[int]](x:G[i,j]) = echo "G:",i,",",j,":",x.v
proc q[j:static[int]](x:H[j]) = echo "H:",j,":",x.v

var
  g0 = G[0,1](v: 0.1)
  h0:H[1] = g0
p(g0)
p(h0)
q(h0)
# bug #4863
