
import 
  glib2, gtk2

proc destroy(widget: pWidget, data: pgpointer){.cdecl.} = 
  main_quit()

nimrod_init()
var window = window_new(WINDOW_TOPLEVEL)
var stackbox = vbox_new(TRUE, 10)
var label1 = label_new("Red label text")
var labelstyle = copy(get_style(label1))
LabelStyle.fg[STATE_NORMAL].pixel = 0
LabelStyle.fg[STATE_NORMAL].red = -1'i16
LabelStyle.fg[STATE_NORMAL].blue = 0'i16
LabelStyle.fg[STATE_NORMAL].green = 0'i16
set_style(label1, labelstyle) 
# Uncomment this to see the effect of setting the default style.
# set_default_style(labelstyle)
var label2 = label_new("Black label text")
pack_start(stackbox, label1, TRUE, TRUE, 0)
pack_start(stackbox, label2, TRUE, TRUE, 0)
set_border_width(Window, 5)
add(window, stackbox)
discard signal_connect(window, "destroy", 
                   SIGNAL_FUNC(ex8.destroy), nil)
show_all(window)
main()

