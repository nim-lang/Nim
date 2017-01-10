
import
  glib2, gtk2

proc destroy(widget: PWidget, data: Pgpointer){.cdecl.} =
  main_quit()

var
  window: PWidget
  button: PWidget

nim_init()
window = window_new(WINDOW_TOPLEVEL)
button = button_new("Click me")
set_border_width(PContainer(window), 5)
add(PContainer(window), button)
discard signal_connect(window, "destroy",
                           SIGNAL_FUNC(gtkex2.destroy), nil)
show(button)
show(window)
main()

