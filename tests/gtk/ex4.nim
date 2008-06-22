
import 
  glib2, gtk2

proc newbutton(ALabel: cstring): PGtkWidget = 
  Result = gtk_button_new_with_label(ALabel)
  gtk_widget_show(result)

proc destroy(widget: pGtkWidget, data: pgpointer){.cdecl.} = 
  gtk_main_quit()

var 
  window, maintable: PgtkWidget

proc AddToTable(Widget: PGtkWidget, Left, Right, Top, Bottom: guint) = 
  gtk_table_attach_defaults(GTK_TABLE(MainTable), Widget, Left, right, top, 
                            bottom)

gtk_nimrod_init()
window = gtk_window_new(GTK_WINDOW_TOPLEVEL)
Maintable = gtk_table_new(6, 6, True)
gtk_widget_show(MainTable)
AddToTable(newbutton("1,1 At 1,1"), 1, 2, 1, 2)
AddToTable(newbutton("2,2 At 3,1"), 3, 5, 1, 3)
AddToTable(newbutton("4,1 At 4,1"), 1, 5, 4, 5) # Put all in window
gtk_container_set_border_width(GTK_CONTAINER(Window), 5)
gtk_container_add(GTK_Container(window), maintable)
discard gtk_signal_connect(GTKOBJECT(window), "destroy", 
                           GTK_SIGNAL_FUNC(destroy), nil)
gtk_widget_show(window)
gtk_main()
