
import
  gtk2, glib2, atk, gdk2, gdk2pixbuf, libglade2, pango,
  pangoutils

proc hello(widget: PGtkWidget, data: pointer) {.cdecl.} =
  write(stdout, "Hello World\n")

proc delete_event(widget: PGtkWidget, event: PGdkEvent,
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
proc destroy(widget: PGtkWidget, data: pointer) {.cdecl.} =
  gtk_main_quit()

proc main() =
  # GtkWidget is the storage type for widgets
  var
    window: PGtkWindow 
    button: PGtkButton

  gtk_nimrod_init()
  window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL))
  discard g_signal_connect(window, "delete_event", 
                           Gcallback(delete_event), nil)
  discard g_signal_connect(window, "destroy", Gcallback(destroy), nil)
  # Sets the border width of the window.
  gtk_container_set_border_width(window, 10)

  # Creates a new button with the label "Hello World".
  button = GTK_BUTTON(gtk_button_new_with_label("Hello World"))

  discard g_signal_connect(button, "clicked", Gcallback(hello), nil)

  # This will cause the window to be destroyed by calling
  # gtk_widget_destroy(window) when "clicked".  Again, the destroy
  # signal could come from here, or the window manager.
  discard g_signal_connect_swapped(button, "clicked", 
    Gcallback(gtk_widget_destroy), window)

  # This packs the button into the window (a gtk container).
  gtk_container_add(window, button)

  # The final step is to display this newly created widget.
  gtk_widget_show(button)

  # and the window
  gtk_widget_show(window)

  gtk_main()

main()
