
# bug #4371

import strutils, asyncdispatch, asynchttpserver

type
  List[A] = ref object
    value: A
    next: List[A]
  StrPair* = tuple[k, v: string]
  Context* = object
    position*: int
    accept*: bool
    headers*: List[StrPair]
  Handler* = proc(req: ref Request, ctx: Context): Future[Context]

proc logging*(handler: Handler): auto =
  proc h(req: ref Request, ctx: Context): Future[Context] {.async.} =
    let ret = handler(req, ctx)
    debugEcho "$3 $1 $2".format(req.reqMethod, req.url.path, req.hostname)
    return await ret

  return h
