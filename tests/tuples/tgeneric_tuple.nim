# bug #2121

type
  Item[K,V] = tuple
    key: K
    value: V

var q = newseq[Item[int,int]](0)
let (x,y) = q[0]
