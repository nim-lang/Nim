
import 
  glib2, gtk2

proc destroy(widget: pGtkWidget, data: pgpointer){.cdecl.} = 
  gtk_main_quit()

var 
  window: PGtkWidget
  button: PGtkWidget

gtk_nimrod_init()
window = gtk_window_new(GTK_WINDOW_TOPLEVEL)
button = gtk_button_new_with_label("Click me")
gtk_container_set_border_width(GTK_CONTAINER(Window), 5)
gtk_container_add(GTK_Container(window), button)
discard gtk_signal_connect(GTKOBJECT(window), "destroy", 
                           GTK_SIGNAL_FUNC(destroy), nil)
discard gtk_signal_connect_object(GTKOBJECT(button), "clicked", 
                                  GTK_SIGNAL_FUNC(gtk_widget_destroy), 
                                  GTKOBJECT(window))
gtk_widget_show(button)
gtk_widget_show(window)
gtk_main()
