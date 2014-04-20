discard """
  line: 18
  errormsg: "type mismatch: got (proc (TScgi) | proc (PAsyncSocket, PStringTable, string){.gcsafe.})"
"""

#bug #442
import scgi, sockets, asyncio, strtabs
proc handleSCGIRequest[TScgi: TScgiState | PAsyncScgiState](s: TScgi) =
  discard
proc handleSCGIRequest(client: PAsyncSocket, headers: PStringTable, 
                       input: string) =
  discard

proc test(handle: proc (client: PAsyncSocket, headers: PStringTable, 
                        input: string), b: int) =
  discard

test(handleSCGIRequest)
