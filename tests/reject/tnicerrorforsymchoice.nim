discard """
  line: 18
  errormsg: "type mismatch: got (proc (TScgi) | proc (PAsyncSocket, PStringTable, string))"
"""

#bug #442
import scgi, sockets, asyncio, strtabs
proc handleSCGIRequest[TScgi: TScgiState | PAsyncScgiState](s: TScgi) =
  nil
proc handleSCGIRequest(client: PAsyncSocket, headers: PStringTable, 
                       input: string) =
  nil

proc test(handle: proc (client: PAsyncSocket, headers: PStringTable, 
                        input: string), b: int) =
  nil

test(handleSCGIRequest)
