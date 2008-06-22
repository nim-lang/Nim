
import 
  gdk2, glib2, gtk2

proc destroy(widget: pGtkWidget, data: pgpointer){.cdecl.} = 
  gtk_main_quit()

const 
  Inside: cstring = "Mouse is over label"
  OutSide: cstring = "Mouse is not over label"

var 
  OverLabel: bool
  window, box1, box2, stackbox, label1, Label2: PGtkWidget

proc ChangeLabel(P: PGtkWidget, Event: PGdkEventCrossing, 
                Data: var bool){.cdecl.} = 
  if not Data: gtk_label_set_text(GTKLABEL(Label2), Inside)
  else: gtk_label_set_text(GTKLABEL(Label2), Outside)
  Data = not Data

gtk_nimrod_init()
window = gtk_window_new(GTK_WINDOW_TOPLEVEL)
stackbox = gtk_vbox_new(TRUE, 10)
box1 = gtk_event_box_new()
label1 = gtk_label_new("Move mouse over label")
gtk_container_add(GTK_CONTAINER(box1), label1)
box2 = gtk_event_box_new()
label2 = gtk_label_new(OutSide)
gtk_container_add(GTK_CONTAINER(box2), label2)
gtk_box_pack_start(GTK_BOX(stackbox), box1, TRUE, TRUE, 0)
gtk_box_pack_start(GTK_BOX(stackbox), box2, TRUE, TRUE, 0)
gtk_container_set_border_width(GTK_CONTAINER(Window), 5)
gtk_container_add(GTK_Container(window), stackbox)
discard gtk_signal_connect(GTKOBJECT(window), "destroy", 
                   GTK_SIGNAL_FUNC(destroy), nil)
overlabel = False
discard gtk_signal_connect(GTKOBJECT(box1), "enter_notify_event", 
                   GTK_SIGNAL_FUNC(ChangeLabel), addr(Overlabel))
discard gtk_signal_connect(GTKOBJECT(box1), "leave_notify_event", 
                   GTK_SIGNAL_FUNC(ChangeLabel), addr(Overlabel))
gtk_widget_show_all(window)
gtk_main()
