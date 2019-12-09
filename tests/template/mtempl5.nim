
var
  gx = 88
  gy = 44

template templ*(): int =
  bind gx, gy
  gx + gy

import json

const
  codeField = "foobar"
  messageField = "more"

template trap*(path: string, body: untyped): untyped =
  #bind codeField, messageField
  try:
    body
  except:
    let msg = getCurrentExceptionMsg()
    #debug "Error occurred within RPC ", path = path, errorMessage = msg
    result = %*{codeField: "SERVER_ERROR", messageField: msg}

