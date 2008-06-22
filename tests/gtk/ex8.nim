
import 
  glib2, gtk2

proc destroy(widget: pGtkWidget, data: pgpointer){.cdecl.} = 
  gtk_main_quit()

var 
  window, stackbox, label1, Label2: PGtkWidget
  labelstyle: pgtkstyle

gtk_nimrod_init()
window = gtk_window_new(GTK_WINDOW_TOPLEVEL)
stackbox = gtk_vbox_new(TRUE, 10)
label1 = gtk_label_new("Red label text")
labelstyle = gtk_style_copy(gtk_widget_get_style(label1))
LabelStyle.fg[GTK_STATE_NORMAL].pixel = 0
LabelStyle.fg[GTK_STATE_NORMAL].red = 0x0000FFFF
LabelStyle.fg[GTK_STATE_NORMAL].blue = 0
LabelStyle.fg[GTK_STATE_NORMAL].green = 0
gtk_widget_set_style(label1, labelstyle) # Uncomment this to see the effect of setting the default style.
                                         # 
                                         # gtk_widget_set_default_style(labelstyle)
label2 = gtk_label_new("Black label text")
gtk_box_pack_start(GTK_BOX(stackbox), label1, TRUE, TRUE, 0)
gtk_box_pack_start(GTK_BOX(stackbox), label2, TRUE, TRUE, 0)
gtk_container_set_border_width(GTK_CONTAINER(Window), 5)
gtk_container_add(GTK_Container(window), stackbox)
discard gtk_signal_connect(GTKOBJECT(window), "destroy", 
                   GTK_SIGNAL_FUNC(destroy), nil)
gtk_widget_show_all(window)
gtk_main()
