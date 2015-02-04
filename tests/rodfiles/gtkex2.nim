
import
  glib2, gtk2

proc destroy(widget: pWidget, data: pgpointer){.cdecl.} =
  main_quit()

var
  window: PWidget
  button: PWidget

nimrod_init()
window = window_new(WINDOW_TOPLEVEL)
button = button_new("Click me")
set_border_width(PContainer(Window), 5)
add(PContainer(window), button)
discard signal_connect(window, "destroy",
                           SIGNAL_FUNC(gtkex2.destroy), nil)
show(button)
show(window)
main()

