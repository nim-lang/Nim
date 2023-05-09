import
  opengl,
  tri_engine/math/vec

export
  opengl

type
  EGL* = object of Exception
  EGL_code* = object of EGL
    code*: EGL_err
  EGL_err {.pure.} = enum
    none                 = GL_NO_ERROR
    invalidEnum          = GL_INVALID_ENUM
    invalidVal           = GL_INVALID_VALUE
    invalidOp            = GL_INVALID_OPERATION
    stackOverflow        = GL_STACK_OVERFLOW
    stackUnderflow       = GL_STACK_UNDERFLOW
    outOfMem             = GL_OUT_OF_MEMORY
    invalidFramebufferOp = GL_INVALID_FRAMEBUFFER_OPERATION
    unknown

proc newGL_codeException*(msg: string, code: EGL_err): ref EGL_code =
  result      = newException(EGL_code, $code)
  result.code = code

proc getErr*(): EGL_err =
  result = glGetError().EGL_err
  if result notin {EGL_err.none,
                   EGL_err.invalidEnum,
                   EGL_err.invalidVal,
                   EGL_err.invalidOp,
                   EGL_err.invalidFramebufferOp,
                   EGL_err.outOfMem,
                   EGL_err.stackUnderflow,
                   EGL_err.stackOverflow}:
    return EGL_err.unknown

proc errCheck*() =
  let err = getErr()
  if err != EGL_err.none:
    raise newGL_codeException($err, err)

macro `?`*(call: expr{nkCall}): expr =
  result = call
  # Can't yet reference foreign symbols in macros.
  #errCheck()

when defined(doublePrecision):
  const
    glRealType* = cGLdouble
else:
  const
    glRealType* = cGLfloat

proc setUniformV4*[T](loc: GLint, vecs: var openArray[TV4[T]]) =
  glUniform4fv(loc, vecs.len.GLsizei, cast[ptr GLfloat](vecs[0].addr))

proc setUniformV4*[T](loc: GLint, vec: TV4[T]) =
  var vecs = [vec]
  setUniformV4(loc, vecs)
