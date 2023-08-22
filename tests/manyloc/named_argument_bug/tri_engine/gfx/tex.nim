import
  tri_engine/gfx/gl/gl

type
  TTex* = object
    id*: GLuint

var gWhiteTex = TTex(id: 0)

proc setTexParams() =
  ?glTexParameteri(GLtexture2D, GLtextureMinFilter, GLlinear)

  #glTexParameteri(GLtexture2D, GLtextureMagFilter, GLlinear)
  ?glTexParameteri(GLtexture2D, GLTextureMagFilter, GLnearest)

  ?glTexParameteri(GLtexture2D, GLTextureWrapS, GLClampToEdge)
  ?glTexParameteri(GLtexture2D, GLTextureWrapT, GLClampToEdge)

proc whiteTex*(): TTex =
  if gWhiteTex.id.int != 0:
    return gWhiteTex

  ?glGenTextures(1, gWhiteTex.id.addr)
  ?glBindTexture(GLtexture2D, gWhiteTex.id)
  setTexParams()

  var pixel = [255'u8, 255'u8, 255'u8, 255'u8]
  ?glTexImage2D(GLtexture2D, 0, GLint GL_RGBA, 1, 1, 0, GL_BGRA, cGLUnsignedByte, pixel[0].addr)
  ?glBindTexture(GLtexture2D, 0)

  result = gWhiteTex
