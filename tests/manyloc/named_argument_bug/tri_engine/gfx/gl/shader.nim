import
  pure/os,
  tri_engine/gfx/gl/gl

type
  TShader* = object
    id*: GL_handle
  TShaderType* {.pure.} = enum
    frag = GL_FRAGMENT_SHADER,
    vert   = GL_VERTEX_SHADER
  E_Shader* = object of Exception
  E_UnknownShaderType* = object of E_Shader

converter pathToShaderType*(s: string): TShaderType =
  case s.splitFile().ext:
  of ".vs":
    return TShaderType.vert
  of ".fs":
    return TShaderType.frag
  else:
    raise newException(E_UnknownShaderType, "Can't determine shader type from file extension: " & s)

proc setSrc*(shader: TShader, src: string) =
  var s = src.cstring
  ?glShaderSource(shader.id, 1, cast[cstringarray](s.addr), nil)

proc newShader*(id: GL_handle): TShader =
  if id.int != 0 and not (?glIsShader(id)).bool:
    raise newException(E_GL, "Invalid shader ID: " & $id)

  result.id = id

proc shaderInfoLog*(o: TShader): string =
  var log {.global.}: array[0..1024, char]
  var logLen: GLsizei
  ?glGetShaderInfoLog(o.id.GLuint, log.len.GLsizei, addr logLen, cast[cstring](log.addr))
  cast[string](log.addr).substr(0, logLen)

proc compile*(shader: TShader, path="") =
  ?glCompileShader(shader.id)
  var compileStatus = 0.GLint
  ?glGetShaderIv(shader.id, GL_COMPILE_STATUS, compileStatus.addr)

  if compileStatus == 0:
    raise newException(E_GL, if path.len == 0:
        shaderInfoLog(shader)
      else:
        path & ":\n" & shaderInfoLog(shader)
    )

proc newShaderFromSrc*(src: string, `type`: TShaderType): TShader =
  result.id = ?glCreateShader(`type`.GLenum)
  result.setSrc(src)
  result.compile()

proc newShaderFromFile*(path: string): TShader =
  newShaderFromSrc(readFile(path), path)

type
  TProgram* = object
    id*: GL_handle
    shaders: seq[TShader]

proc attach*(o: TProgram, shader: TShader) =
  ?glAttachShader(o.id, shader.id)

proc infoLog*(o: TProgram): string =
  var log {.global.}: array[0..1024, char]
  var logLen: GLsizei
  ?glGetProgramInfoLog(o.id.GLuint, log.len.GLsizei, addr logLen, cast[cstring](log.addr))
  cast[string](log.addr).substr(0, logLen)

proc link*(o: TProgram) =
  ?glLinkProgram(o.id)
  var linkStatus = 0.GLint
  ?glGetProgramIv(o.id, GL_LINK_STATUS, linkStatus.addr)
  if linkStatus == 0:
    raise newException(E_GL, o.infoLog())

proc validate*(o: TProgram) =
  ?glValidateProgram(o.id)
  var validateStatus = 0.GLint
  ?glGetProgramIv(o.id, GL_VALIDATE_STATUS, validateStatus.addr)
  if validateStatus == 0:
    raise newException(E_GL, o.infoLog())

proc newProgram*(shaders: seq[TShader]): TProgram =
  result.id = ?glCreateProgram()
  if result.id.int == 0:
    return

  for shader in shaders:
    if shader.id.int == 0:
      return

    ?result.attach(shader)

  result.shaders = shaders
  result.link()
  result.validate()

proc use*(o: TProgram) =
  ?glUseProgram(o.id)
