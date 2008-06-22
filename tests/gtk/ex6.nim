
import 
  glib2, gtk2

type 
  TButtonSignalState = record 
    Obj: PgtkObject
    SignalID: int32
    Disable: bool

  PButtonSignalState = ptr TButtonSignalState

proc destroy(widget: pGtkWidget, data: pgpointer){.cdecl.} = 
  gtk_main_quit()

proc disablesignal(widget: pGtkWidget, data: pgpointer){.cdecl.} = 
  if PButtonSignalState(Data).Disable: 
    gtk_signal_handler_block(PButtonSignalState(Data).Obj, SignalID)
  else: 
    gtk_signal_handler_unblock(PButtonSignalState(Data).Obj, SignalID)
  PButtonSignalState(Data).disable = not PButtonSignalState(Data).disable

var 
  window: PGtkWidget
  quitbutton: PGtkWidget
  disablebutton: PGTKWidget
  windowbox: PGTKWidget
  quitsignal: guint
  QuitState: TButtonSignalState

gtk_nimrod_init()
window = gtk_window_new(GTK_WINDOW_TOPLEVEL)
quitbutton = gtk_button_new_with_label("Quit program")
disablebutton = gtk_button_new_with_label("Disable button")
windowbox = gtk_vbox_new(TRUE, 10)
gtk_box_pack_start(GTK_BOX(windowbox), disablebutton, True, false, 0)
gtk_box_pack_start(GTK_BOX(windowbox), quitbutton, True, false, 0)
gtk_container_set_border_width(GTK_CONTAINER(Window), 10)
gtk_container_add(GTK_Container(window), windowbox)
gtk_signal_connect(GTKOBJECT(window), "destroy", 
                   GTK_SIGNAL_FUNC(destroy), nil)
QuitState.Obj = GTKObject(QuitButton)
SignalID = gtk_signal_connect_object(QuitState.Obj, "clicked", GTK_SIGNAL_FUNC(
              gtk_widget_destroy), GTKOBJECT(window))
QuitState.Disable = True
discard gtk_signal_connect(GTKOBJECT(disablebutton), "clicked", 
                   GTK_SIGNAL_FUNC(disablesignal), addr(QuitState))
gtk_widget_show(quitbutton)
gtk_widget_show(disablebutton)
gtk_widget_show(windowbox)
gtk_widget_show(window)
gtk_main()
