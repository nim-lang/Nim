import 
  cairo, glib2, gtk2

proc destroy(widget: pWidget, data: pgpointer) {.cdecl.} =
  main_quit()

var
  window: pWidget
nimrod_init()
window = window_new(WINDOW_TOPLEVEL)
discard signal_connect(window, "destroy",
                       SIGNAL_FUNC(gtkex1.destroy), nil)
show(window)
main()
