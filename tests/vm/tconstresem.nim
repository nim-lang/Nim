block: # issue #19849
  type
    Vec2[T] = object
      x, y: T
    Vec2i = Vec2[int]
  template getX(p: Vec2i): int = p.x
  let x = getX:
    const t = Vec2i(x: 1, y: 2)
    t
  doAssert x == 1
