discard """
  line: 18
  errormsg: "type mismatch: got <proc (s: TScgi: ScgiState or AsyncScgiState) | proc (client: AsyncSocket, headers: StringTableRef, input: string){.noSideEffect, gcsafe, locks: 0.}>"
"""

#bug #442
import scgi, sockets, asyncio, strtabs
proc handleSCGIRequest[TScgi: ScgiState | AsyncScgiState](s: TScgi) =
  discard
proc handleSCGIRequest(client: AsyncSocket, headers: StringTableRef,
                       input: string) =
  discard

proc test(handle: proc (client: AsyncSocket, headers: StringTableRef,
                        input: string), b: int) =
  discard

test(handleSCGIRequest)
