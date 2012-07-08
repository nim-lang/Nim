
import 
  glib2, gtk2

type 
  TButtonSignalState = object 
    Obj: gtk2.PObject
    SignalID: int32
    Disable: bool

  PButtonSignalState = ptr TButtonSignalState

proc destroy(widget: pWidget, data: pgpointer){.cdecl.} = 
  main_quit()

proc widgetDestroy(w: PWidget) {.cdecl.} = destroy(w)

proc disablesignal(widget: pWidget, data: pgpointer){.cdecl.} = 
  var s = cast[PButtonSignalState](Data)
  if s.Disable: 
    signal_handler_block(s.Obj, s.SignalID)
  else: 
    signal_handler_unblock(s.Obj, s.SignalID)
  s.disable = not s.disable

var 
  QuitState: TButtonSignalState

nimrod_init()
var window = window_new(WINDOW_TOPLEVEL)
var quitbutton = button_new("Quit program")
var disablebutton = button_new("Disable button")
var windowbox = vbox_new(TRUE, 10)
pack_start(windowbox, disablebutton, True, false, 0)
pack_start(windowbox, quitbutton, True, false, 0)
set_border_width(Window, 10)
add(window, windowbox)
discard signal_connect(window, "destroy", SIGNAL_FUNC(ex6.destroy), nil)
QuitState.Obj = QuitButton
quitState.SignalID = signal_connect_object(QuitState.Obj, "clicked", 
                       SIGNAL_FUNC(widgetDestroy), window).int32
QuitState.Disable = True
discard signal_connect(disablebutton, "clicked", 
                   SIGNAL_FUNC(disablesignal), addr(QuitState))
show(quitbutton)
show(disablebutton)
show(windowbox)
show(window)
main()

