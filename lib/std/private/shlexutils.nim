type State = enum
  sInStart
  sInRegular
  sInSpace
  sInSingleQuote
  sInDoubleQuote
  sFinished

type ShlexError = enum
  seOk
  seMissingDoubleQuote
  seMissingSingleQuote

iterator shlex*(a: openArray[char], error: var ShlexError): string =
  var i = 0
  var buf: string
  var state = sInStart
  var ready = false
  error = seOk
  const ShellWhiteSpace = {' ', '\t'} # not \n
  while true:
    if i >= a.len:
      case state
      of sInSingleQuote:
        error = seMissingSingleQuote
      of sInDoubleQuote:
        error = seMissingDoubleQuote
      of sInStart: discard
      else:
        # dbg ready, state
        ready = true
      state = sFinished
    var c: char
    if i < a.len:
      c = a[i]
    i.inc
    case state
    of sFinished: discard
    of sInStart:
      case c
      of ShellWhiteSpace: discard
      of '\'': state = sInSingleQuote
      of '\"': state = sInDoubleQuote
      else:
        state = sInRegular
        buf.add c
    of sInRegular:
      case c
      of ShellWhiteSpace: ready = true
      of '\'': state = sInSingleQuote
      of '\"': state = sInDoubleQuote
      else: buf.add c
    of sInSingleQuote:
      case c
      of '\'': state = sInRegular
      else: buf.add c
    of sInDoubleQuote:
      case c
      of '\"': state = sInRegular
      # of '\'': state = sInRegular
      else: buf.add c
    of sInSpace:
      case c
      of ShellWhiteSpace: discard
      of '\'': state = sInSingleQuote
      of '\"': state = sInDoubleQuote
      else:
        state = sInRegular
        buf.add c
    if ready:
      ready = false
      # echo (buf,)
      # if state != sInStart:
      yield buf
      buf.setLen 0
      if state != sFinished:
        state = sInStart
    if state == sFinished:
      break

proc parseCmdLineImpl*(a: string): seq[string] {.inline.} =
  var err: ShlexError
  for val in shlex(a, err):
    if err == seOk:
      result.add val
    else:
      raise newException(ValueError, $(a, err))
