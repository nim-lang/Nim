discard """
  errormsg: "type mismatch"
  line: 7
"""

proc p(q: proc() ): proc() {.tags: [], raises: [], closure.} =
  return proc () =
    q()

let yay = p(proc () = raise newException(EIO, "IO"))

proc main() {.raises: [], tags: [].} = yay()

main()
