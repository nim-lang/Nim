discard """
  output: '''
(v: [(v: [0.0, 1.1]), (v: [2.2, 3.3])])
(v: [(v: [0.0, 1.1]), (v: [2.2, 3.3])])
'''
"""

type
  V = object
    v:array[2,float]
  M = object
    v:array[2,V]

var
  a = M(v:[ V(v:[0.0,1.0]), V(v:[2.0,3.0]) ])
  b = M(v:[ V(v:[0.0,0.1]), V(v:[0.2,0.3]) ])

echo M(v: [V(v: [b.v[0].v[0] + a.v[0].v[0], b.v[0].v[1] + a.v[0].v[1]]),
       V(v: [b.v[1].v[0] + a.v[1].v[0], b.v[1].v[1] + a.v[1].v[1]])])
b = M(v: [V(v: [b.v[0].v[0] + a.v[0].v[0], b.v[0].v[1] + a.v[0].v[1]]),
      V(v: [b.v[1].v[0] + a.v[1].v[0], b.v[1].v[1] + a.v[1].v[1]])])
echo b
