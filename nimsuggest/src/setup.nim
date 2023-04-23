


import  net
# Do NOT import suggest. It will lead to weird bugs with
# suggestionResultHook, because suggest.nim is included by sigmatch.
# So we import that one instead.
import compiler/[options , msgs, lineinfos ]

type
  Mode * = enum mstdin, mtcp, mepc, mcmdsug, mcmdcon
  CachedMsg * = object
    info*: TLineInfo
    msg*: string
    sev*: Severity
  CachedMsgs * = seq[CachedMsg]

var
  gPort* = 6000.Port
  gAddress* = ""
  gMode*: Mode
  gEmitEof*: bool # whether we write '!EOF!' dummy lines
  gLogging* = defined(logging)
  gRefresh*: bool
  gAutoBind* = false

  requests*: Channel[string]
  results*: Channel[Suggest]
proc myLog*(s: string) =
  if gLogging: log(s)
