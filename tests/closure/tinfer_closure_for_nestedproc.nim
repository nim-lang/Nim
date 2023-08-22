discard """
  action: compile
"""

# bug #9441
import asyncdispatch, asyncfutures, strtabs

type
  Request = object
  Context = object
    position: int
    accept: bool
    headers: StringTableRef
  Handler = proc (r: ref Request, c: Context): Future[Context]

proc respond(req: Request): Future[void] = discard

proc handle*(h: Handler): auto = # (proc (req: Request): Future[void]) =
  proc server(req: Request): Future[void] {.async.} =
    let emptyCtx = Context(
      position: 0,
      accept: true,
      headers: newStringTable()
    )
    var reqHeap = new(Request)
    reqHeap[] = req
    var
      f: Future[Context]
      ctx: Context
    try:
      f = h(reqHeap, emptyCtx)
      ctx = await f
    except:
      discard
    if f.failed:
      await req.respond()
    else:
      if not ctx.accept:
        await req.respond()
  return server

waitFor handle(nil)(Request())
