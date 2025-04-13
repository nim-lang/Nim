# issue #4711

type
  Vec4 = object
    x,y,z,w : float32

  Vec3 = object
    x,y,z : float32

proc `+=`(v0: var Vec3; v1: Vec3) =
  v0.x += v1.x
  v0.y += v1.y
  v0.z += v1.z

proc xyz(v: var Vec4): var Vec3 =
  cast[ptr Vec3](v.x.addr)[]

let tmp = Vec3(x: 1, y:2, z:3)
var dst = Vec4(x: 4, y:4, z:4, w:4)

xyz(dst)  = tmp # works
dst.xyz() = tmp # works
dst.xyz  += tmp # works
dst.xyz   = tmp # attempting to call undeclared routine `xyz=`
