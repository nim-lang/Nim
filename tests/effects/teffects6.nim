discard """
action: compile
"""

# XXX: it is not actually tested if the effects are inferred

type
  PMenu = ref object
  PMenuItem = ref object

proc createMenuItem*(menu: PMenu, label: string,
                    action: proc (i: PMenuItem, p: pointer) {.cdecl.}) = discard

var s: PMenu
createMenuItem(s, "Go to definition...",
      proc (i: PMenuItem, p: pointer) {.cdecl.} =
        try:
          echo(i.repr)
        except ValueError:
          echo("blah")
)


proc noRaise(x: proc()) {.raises: [].} =
  # unknown call that might raise anything, but valid:
  x()

proc doRaise() {.raises: [IoError].} =
  raise newException(IoError, "IO")

proc use*() =
  noRaise(doRaise)
  # Here the compiler inferes that EIO can be raised.


use()
