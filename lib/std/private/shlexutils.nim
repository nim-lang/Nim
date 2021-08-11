type State = enum
  sInStart
  sInRegular
  sInSingleQuote
  sInDoubleQuote
  sFinished

type ShlexError = enum
  seOk
  seUnclosedDoubleQuote
  seUnclosedSingleQuote
  seUnfinishedEscape

iterator shlex*(a: openArray[char], error: var ShlexError): string =
  # see quoting rules in https://ss64.com/bash/syntax-quoting.html
  # we try to follow behavior of python3 `list(shlex.shlex(..., posix=True)))`
  var i = 0
  var buf: string
  var state = sInStart
  var ready = false
  error = seOk
  const
    ShellWhiteSpace = {' ', '\t', '\n'}
    Quote = '\''
    DoubleQuote = '"'
    BackSlash = '\\'
    Special = {'$', '{', '}'}

  template eatEscape(state2) =
    if i >= a.len:
      error = seUnfinishedEscape
      state = sFinished
    else:
      buf.add a[i]
      i.inc
      state = state2

  while true:
    if i >= a.len:
      case state
      of sInSingleQuote: error = seUnclosedSingleQuote
      of sInDoubleQuote: error = seUnclosedDoubleQuote
      of sInStart: discard
      else: ready = true
      state = sFinished
    var c: char
    if i < a.len:
      c = a[i]
    i.inc
    case state
    of sFinished: discard
    of sInStart:
      case c
      of Special:
        buf.add c
        ready = true
      of ShellWhiteSpace: discard
      of Quote: state = sInSingleQuote
      of DoubleQuote: state = sInDoubleQuote
      of BackSlash: eatEscape(sInRegular)
      else:
        state = sInRegular
        buf.add c
    of sInRegular:
      case c
      of ShellWhiteSpace: ready = true
      of Quote: state = sInSingleQuote
      of DoubleQuote: state = sInDoubleQuote
      of BackSlash: eatEscape(state)
      of Special:
        ready = true
        i.dec
      else: buf.add c
    of sInSingleQuote:
      case c
      of Quote: state = sInRegular
      else: buf.add c
    of sInDoubleQuote:
      case c
      of DoubleQuote: state = sInRegular
      of BackSlash:
        if i < a.len:
          let c = a[i]
          case c
          of DoubleQuote, Quote, BackSlash: buf.add c
          else:
            buf.add BackSlash
            buf.add c
          i+=1
        else:
          error = seUnfinishedEscape
          state = sFinished
      else: buf.add c
    if ready:
      ready = false
      yield buf
      buf.setLen 0
      if state != sFinished:
        state = sInStart
    if state == sFinished:
      break

iterator shlex*(a: openArray[char]): string =
  var err: ShlexError
  for val in shlex(a, err):
    assert err == seOk
    yield val
  if err != seOk:
    var msg = "error: " & $err & " a: "
    for ai in a: msg.add ai
    raise newException(ValueError, msg)
