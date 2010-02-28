
import 
  gdk2, glib2, gtk2

proc destroy(widget: pWidget, data: pgpointer){.cdecl.} = 
  main_quit()

const 
  Inside: cstring = "Mouse is over label"
  OutSide: cstring = "Mouse is not over label"

var 
  OverLabel: bool

nimrod_init()
var window = window_new(gtk2.WINDOW_TOPLEVEL)
var stackbox = vbox_new(TRUE, 10)
var box1 = event_box_new()
var label1 = label_new("Move mouse over label")
add(box1, label1)
var box2 = event_box_new()
var label2 = label_new(OutSide)
add(box2, label2)
pack_start(stackbox, box1, TRUE, TRUE, 0)
pack_start(stackbox, box2, TRUE, TRUE, 0)
set_border_width(Window, 5)
add(window, stackbox)
discard signal_connect(window, "destroy", 
                   SIGNAL_FUNC(ex7.destroy), nil)
overlabel = False


proc ChangeLabel(P: PWidget, Event: gdk2.PEventCrossing, 
                Data: var bool){.cdecl.} = 
  if not Data: set_text(Label1, Inside)
  else: set_text(Label2, Outside)
  Data = not Data


discard signal_connect(box1, "enter_notify_event", 
                   SIGNAL_FUNC(ChangeLabel), addr(Overlabel))
discard signal_connect(box1, "leave_notify_event", 
                   SIGNAL_FUNC(ChangeLabel), addr(Overlabel))
show_all(window)
main()

