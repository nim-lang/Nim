type
  vecBase[I: static[int]] = distinct array[I, float32]
  vec2* = vecBase[2]

var v = vec2([0.0'f32, 0.0'f32])

