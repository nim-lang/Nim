
type
  PMenu = ref object
  PMenuItem = ref object

proc createMenuItem*(menu: PMenu, label: string, 
                     action: proc (i: PMenuItem, p: pointer) {.cdecl.}) = nil

var s: PMenu
createMenuItem(s, "Go to definition...",
      proc (i: PMenuItem, p: pointer) {.cdecl.} =
        try:
          echo(i.repr)
        except EInvalidValue:
          echo("blah")
)

