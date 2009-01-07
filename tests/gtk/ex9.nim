
import 
  gdk2, glib2, gtk2

proc destroy(widget: pGtkWidget, data: pgpointer){.cdecl.} = 
  gtk_main_quit()

const 
  Inside: cstring = "Mouse is over label"
  OutSide: cstring = "Mouse is not over label"

var 
  window, button1, Button2, Alabel, stackbox: PGtkWidget
  buttonstyle: pgtkstyle
  OverButton: bool

proc ChangeLabel(P: PGtkWidget, Event: PGdkEventCrossing, Data: var bool){.cdecl.} = 
  if Not Data: gtk_label_set_text(GTKLABEL(ALabel), Inside)
  else: gtk_label_set_text(GTKLABEL(ALabel), Outside)
  Data = Not Data

gtk_nimrod_init()
window = gtk_window_new(GTK_WINDOW_TOPLEVEL)
stackbox = gtk_vbox_new(TRUE, 10)
button1 = gtk_button_new_with_label("Move mouse over button")
buttonstyle = gtk_style_copy(gtk_widget_get_style(Button1))
ButtonStyle.bg[GTK_STATE_PRELIGHT].pixel = 0
ButtonStyle.bg[GTK_STATE_PRELIGHT].red = 0x0000FFFF'i16
ButtonStyle.bg[GTK_STATE_PRELIGHT].blue = 0'i16
ButtonStyle.bg[GTK_STATE_PRELIGHT].green = 0'i16
gtk_widget_set_style(button1, buttonstyle)
button2 = gtk_button_new()
ALabel = gtk_label_new(Outside)
gtk_container_add(GTK_CONTAINER(button2), ALAbel)
gtk_box_pack_start(GTK_BOX(stackbox), button1, TRUE, TRUE, 0)
gtk_box_pack_start(GTK_BOX(stackbox), button2, TRUE, TRUE, 0)
gtk_container_set_border_width(GTK_CONTAINER(Window), 5)
gtk_container_add(GTK_Container(window), stackbox)
discard gtk_signal_connect(GTKOBJECT(window), "destroy", 
                   GTK_SIGNAL_FUNC(destroy), nil)
overbutton = False
discard gtk_signal_connect(GTKOBJECT(button1), "enter_notify_event", 
                   GTK_SIGNAL_FUNC(ChangeLabel), addr(OverButton))
discard gtk_signal_connect(GTKOBJECT(button1), "leave_notify_event", 
                   GTK_SIGNAL_FUNC(ChangeLabel), addr(OverButton))
gtk_widget_show_all(window)
gtk_main()
