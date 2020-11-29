## INTERNAL FILE FOR USE ONLY BY nre.nim.
import tables

const Ident = {'a'..'z', 'A'..'Z', '0'..'9', '_', '\128'..'\255'}
const StartIdent = Ident - {'0'..'9'}

template formatStr*(howExpr, namegetter, idgetter): untyped =
  let how = howExpr
  var val = newStringOfCap(how.len)
  var i = 0
  var lastNum = 1

  while i < how.len:
    if how[i] != '$':
      val.add(how[i])
      i += 1
    else:
      if how[i + 1] == '$':
        val.add('$')
        i += 2
      elif how[i + 1] == '#':
        var id {.inject.} = lastNum
        val.add(idgetter)
        lastNum += 1
        i += 2
      elif how[i + 1] in {'0'..'9'}:
        i += 1
        var id {.inject.} = 0
        while i < how.len and how[i] in {'0'..'9'}:
          id += (id * 10) + (ord(how[i]) - ord('0'))
          i += 1
        val.add(idgetter)
        lastNum = id + 1
      elif how[i + 1] in StartIdent:
        i += 1
        var name {.inject.} = ""
        while i < how.len and how[i] in Ident:
          name.add(how[i])
          i += 1
        val.add(namegetter)
      elif how[i + 1] == '{':
        i += 2
        var name {.inject.} = ""
        while i < how.len and how[i] != '}':
          name.add(how[i])
          i += 1
        i += 1
        val.add(namegetter)
      else:
        raise newException(ValueError, "Syntax error in format string at " & $i)
  val
