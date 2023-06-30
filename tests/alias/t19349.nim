discard """
  action: "compile"
"""

type
  Vec3[T: SomeNumber] = object
    arr: array[3, T]

var 
  cfloatArr: array[3, array[3, cfloat]]
  cfloatSeq = newSeq[Vec3[cfloat]]()
for row in cfloatArr:
  cfloatSeq.add(Vec3[float32](arr: [row[0], row[1], row[2]]))

var 
  cuintArr: array[3, array[3, cuint]]
  cuintSeq = newSeq[Vec3[cuint]]()
for row in cuintArr:
  cuintSeq.add(Vec3[uint32](arr: [row[0], row[1], row[2]]))
