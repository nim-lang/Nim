import
  algorithm,
  tri_engine/config,
  tri_engine/gfx/gl/gl,
  tri_engine/gfx/gl/primitive,
  tri_engine/gfx/gl/shader,
  tri_engine/gfx/color

const primitiveVs = """
#version 330 core

layout(location = 0) in vec2 pos;
layout(location = 1) in vec2 texCoord;

out vec2 uv;

void main()
{
    gl_Position = vec4(pos, 0, 1);
    uv = texCoord;
}

"""
const primitiveFs = """
#version 330 core

in vec2 uv;
out vec4 color;
uniform sampler2D tex;
uniform vec4 inColor;

void main()
{
    color = texture(tex, uv) * inColor;
}

"""

var gW, gH: Natural = 0

proc w*(): int =
  gW

proc h*(): int =
  gH

type
  PRenderer = ref object
    primitiveProgram: TProgram
    primitives: seq[PPrimitive]

proc setupGL() =
  ?glEnable(GLblend)
  ?glBlendFunc(GLsrcAlpha, GLoneMinusSrcAlpha)
  ?glClearColor(0.0, 0.0, 0.0, 1.0)
  ?glPolygonMode(GLfrontAndBack, GLfill)

proc newRenderer*(w, h: Positive): PRenderer =
  gW = w
  gH = h

  new(result)
  newSeq(result.primitives, 0)
  loadExtensions()
  setupGL()
  result.primitiveProgram = newProgram(@[
    newShaderFromSrc(primitiveVs, TShaderType.vert),
    newShaderFromSrc(primitiveFs, TShaderType.frag)])

proc draw(o: PRenderer, p: PPrimitive) =
  let loc = proc(x: string): Glint =
    result = glGetUniformLocation(o.primitiveProgram.id, x)
    if result == -1:
      raise newException(E_GL, "Shader error: " & x & " does not correspond to a uniform variable")

  setUniformV4(loc("inColor"), p.color)
  ?glActiveTexture(GLtexture0)
  ?glBindTexture(GLtexture2D, p.tex.id.GLuint)
  ?glUniform1i(loc("tex"), 0)

  p.bindBufs()
  setVertAttribPointers()

  ?glDrawElements(p.vertMode.GLenum, p.indices.len.GLsizei, cGLunsignedShort, nil)

proc draw*(o: PRenderer) =
  ?glClear(GLcolorBufferBit)
  o.primitiveProgram.use()

  enableVertAttribArrs()
  var zSortedPrimitives = o.primitives
  zSortedPrimitives.sort(proc(x, y: PPrimitive): int =
    if x.z < y.z:
      -1
    elif x.z > y.z:
      1
    else:
      0)

  for x in zSortedPrimitives:
    o.draw(x)

  disableVertAttribArrs()

proc addPrimitive*(o: PRenderer, p: PPrimitive) =
  o.primitives.add(p)
