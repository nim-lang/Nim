discard """
  disabled: true
"""
import
  gtk2, glib2, atk, gdk2, gdk2pixbuf, libglade2, pango,
  pangoutils

proc hello(widget: PWidget, data: pointer) {.cdecl.} =
  write(stdout, "Hello World\n")

proc delete_event(widget: PWidget, event: PEvent,
                  data: pointer): bool {.cdecl.} =
  # If you return FALSE in the "delete_event" signal handler,
  # GTK will emit the "destroy" signal. Returning TRUE means
  # you don't want the window to be destroyed.
  # This is useful for popping up 'are you sure you want to quit?'
  # type dialogs.
  write(stdout, "delete event occurred\n")
  # Change TRUE to FALSE and the main window will be destroyed with
  # a "delete_event".
  return false

# Another callback
proc mydestroy(widget: PWidget, data: pointer) {.cdecl.} =
  gtk2.main_quit()

proc mymain() =
  # GtkWidget is the storage type for widgets
  gtk2.nimrod_init()
  var window = window_new(gtk2.WINDOW_TOPLEVEL)
  discard g_signal_connect(window, "delete_event",
                           Gcallback(delete_event), nil)
  discard g_signal_connect(window, "destroy", Gcallback(mydestroy), nil)
  # Sets the border width of the window.
  set_border_width(window, 10)

  # Creates a new button with the label "Hello World".
  var button = button_new("Hello World")

  discard g_signal_connect(button, "clicked", Gcallback(hello), nil)

  # This packs the button into the window (a gtk container).
  add(window, button)

  # The final step is to display this newly created widget.
  show(button)

  # and the window
  show(window)

  gtk2.main()

mymain()
