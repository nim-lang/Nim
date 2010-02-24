import 
  cairo, glib2, gtk2

proc destroy(widget: pGtkWidget, data: pgpointer) {.cdecl.} =
  gtk_main_quit()

var
  window: pGtkWidget
gtk_nimrod_init()
window = gtk_window_new(GTK_WINDOW_TOPLEVEL)
discard gtk_signal_connect(GTKOBJECT(window), "destroy",
                   GTK_SIGNAL_FUNC(destroy), nil)
gtk_widget_show(window)
gtk_main()
