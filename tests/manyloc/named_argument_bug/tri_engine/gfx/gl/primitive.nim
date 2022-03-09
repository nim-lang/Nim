import
  math,
  tri_engine/config,
  tri_engine/gfx/gl/gl,
  tri_engine/gfx/tex,
  tri_engine/gfx/color,
  tri_engine/math/vec,
  tri_engine/math/rect,
  tri_engine/math/circle

import strutils

type
  TVert* = tuple[pos: TV2[TR], texCoord: TV2[TR]]
  TVertAttrib* = object
    i*      : GLuint
    size*   : GLint
    stride* : GLsizei
    offset* : GLvoid
  TVertMode* = enum
    vmTriStrip = GLtriangleStrip,
    vmTriFan   = GLtriangleFan
  TZ_range* = range[-100_000..100_000]
  PPrimitive* = ref object
    verts*        : seq[TVert]
    indices*      : seq[GLushort]
    arrBufId*     : GLuint
    elemArrBufId* : GLuint
    tex*          : TTex
    color*        : TColor
    vertMode*     : TVertMode
    z*            : int

proc newVert*(pos, texCoord: TV2): TVert =
  (pos, texCoord)

proc newVertQuad*(min, minRight, maxLeft, max: TV2[TR]): seq[TVert] =
  @[newVert(min,      newV2()),
    newVert(minRight, newV2(x=1.0)),
    newVert(maxLeft,  newV2(y=1.0)),
    newVert(max,      newV2xy(1.0))
  ]

proc newVert*(rect: rect.TRect): seq[TVert] =
  newVertQuad(rect.min, newV2(rect.max.x, rect.min.y), newV2(rect.min.x, rect.max.y), rect.max)

proc newVertAttrib(i: GLuint, size: GLint, stride: GLsizei, offset: GLvoid): TVertAttrib =
  TVertAttrib(i: i, size: size, stride: stride, offset: offset)

proc genBuf*[T](vboTarget, objUsage: GLenum, data: var openArray[T]): GLuint =
  result = 0.GLuint
  ?glGenBuffers(1, result.addr)
  ?glBindBuffer(vboTarget, result)

  let size = (data.len * T.sizeof).GLsizeiptr
  ?glBufferData(vboTarget, size, data[0].addr, objUsage)

proc newPrimitive*(verts: var seq[TVert],
                   vertMode=vmTriStrip,
                   tex=whiteTex(),
                   color=white(),
                   z: TZ_range=0): PPrimitive =
  var indices = newSeq[GLushort](verts.len)
  for i in 0 ..< verts.len:
    indices[i] = i.GLushort

  new(result)
  result.verts = verts
  result.indices = indices

  result.arrBufId     = genBuf(GLarrayBuffer, GL_STATIC_DRAW, verts)
  result.elemArrBufId = genBuf(GLelementArrayBuffer, GL_STATIC_DRAW, indices)
  result.tex = tex
  result.color = color
  result.vertMode = vertMode
  result.z = z

proc bindBufs*(o: PPrimitive) =
  ?glBindBuffer(GLarrayBuffer, o.arrBufId)
  ?glBindBuffer(GLelementArrayBuffer, o.elemArrBufId)

proc enableVertAttribArrs*() =
  ?glEnableVertexAttribArray(0)
  ?glEnableVertexAttribArray(1)

proc disableVertAttribArrs*() =
  ?glDisableVertexAttribArray(1)
  ?glDisableVertexAttribArray(0)

proc setVertAttribPointers*() =
  let vertSize {.global.} = TVert.sizeof.GLint
  ?glVertexAttribPointer(0, 2, glRealType, false, vertSize, nil)
  ?glVertexAttribPointer(1, 2, glRealType, false, vertSize, cast[GLvoid](TR.sizeof * 2))

proc updVerts*(o: PPrimitive, start, `end`: int, f: proc(i: int, vert: var TVert)) =
  assert start <= `end`
  assert `end` < o.verts.len
  for i in start..`end`:
    f(i, o.verts[i])

  ?glBindBuffer(GLarrayBuffer, o.arrBufId)

  let byteLen = `end` - start + 1 * TVert.sizeof
  let byteOffset = start * TVert.sizeof
  ?glBufferSubData(GLarrayBuffer,
                   byteOffset.GLintptr, # Offset. Is this right?
                   byteLen.GLsizeiptr, # Size.
                   cast[GLvoid](cast[int](o.verts[0].addr) + byteOffset))

proc updAllVerts(o: PPrimitive, f: proc(i: int, vert: var TVert)) =
  for i in 0 ..< o.verts.len:
    f(i, o.verts[i])

  ?glBindBuffer(GLarrayBuffer, o.arrBufId)

  # Discard old buffer before creating a new one.
  let byteLen = (o.verts.len * TVert.sizeof).GLsizeiptr
  ?glBufferData(GLarrayBuffer, byteLen, nil, GLstaticDraw)
  ?glBufferData(GLarrayBuffer, byteLen, o.verts[0].addr, GLstaticDraw)

proc newVertCircle*(circle: TCircle, nSegs: Natural=0): seq[TVert] =
  let nSegs = if nSegs == 0:
      (circle.r.sqrt() * 400.0).int # TODO: Base this on the window resolution?
    else:
      max(nSegs, 3)

  let theta: TR = (PI * 2.0) / (nSegs.TR)
  let tanFactor = theta.tan()
  let radialFactor = theta.cos()
  var x = circle.r
  var y: TR = 0.0

  result = newSeq[TVert](nSegs)
  #result[0] = newVert(circle.p, newV2xy(0.5))
  for i in 1 ..< nSegs:
    let pos = newV2(x + circle.p.x, y + circle.p.y)
    let texCoord = pos * newV2xy(1.0 / circle.r)

    result[i] = newVert(pos, texCoord)

    let tx = -y
    let ty = x
    x += tx * tanFactor
    y += ty * tanFactor

    x *= radialFactor
    y *= radialFactor

  result.add(result[1])

proc newPrimitiveCircle*(circle: TCircle,
                         nSegs: Natural=0,
                         tex=whiteTex(),
                         color=white(),
                         z: TZ_range=0): PPrimitive =
  var verts = newVertCircle(circle, nSegs)
  newPrimitive(verts, vmTriFan, tex, color, z)
