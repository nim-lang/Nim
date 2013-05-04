
import 
  gdk2, glib2, gtk2

proc destroy(widget: pWidget, data: pgpointer){.cdecl.} = 
  main_quit()

const 
  Inside: cstring = "Mouse is over label"
  OutSide: cstring = "Mouse is not over label"

var 
  OverButton: bool

nimrod_init()
var window = window_new(gtk2.WINDOW_TOPLEVEL)
var stackbox = vbox_new(TRUE, 10)
var button1 = button_new("Move mouse over button")
var buttonstyle = copy(get_style(Button1))
ButtonStyle.bg[STATE_PRELIGHT].pixel = 0
ButtonStyle.bg[STATE_PRELIGHT].red = -1'i16
ButtonStyle.bg[STATE_PRELIGHT].blue = 0'i16
ButtonStyle.bg[STATE_PRELIGHT].green = 0'i16
set_style(button1, buttonstyle)
var button2 = button_new()
var ALabel = label_new(Outside)


proc ChangeLabel(P: PWidget, Event: gdk2.PEventCrossing, 
                 Data: var bool){.cdecl.} = 
  if Not Data: set_text(ALabel, Inside)
  else: set_text(ALabel, Outside)
  Data = Not Data


add(button2, ALAbel)
pack_start(stackbox, button1, TRUE, TRUE, 0)
pack_start(stackbox, button2, TRUE, TRUE, 0)
set_border_width(Window, 5)
add(window, stackbox)
discard signal_connect(window, "destroy", 
                   SIGNAL_FUNC(ex9.destroy), nil)
overbutton = False
discard signal_connect(button1, "enter_notify_event", 
                   SIGNAL_FUNC(ChangeLabel), addr(OverButton))
discard signal_connect(button1, "leave_notify_event", 
                   SIGNAL_FUNC(ChangeLabel), addr(OverButton))
show_all(window)
main()
