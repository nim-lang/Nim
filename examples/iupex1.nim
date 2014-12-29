# Example IUP program

# iupTabs: Creates a iupTabs control.

import iup

discard iup.open(nil, nil)

var vbox1 = iup.vbox(iup.label("Inside Tab A"), iup.button("Button A", ""), nil)
var vbox2 = iup.vbox(iup.label("Inside Tab B"), iup.button("Button B", ""), nil)

iup.setAttribute(vbox1, "TABTITLE", "Tab A")
iup.setAttribute(vbox2, "TABTITLE", "Tab B")

var tabs1 = iup.tabs(vbox1, vbox2, nil)

vbox1 = iup.vbox(iup.label("Inside Tab C"), iup.button("Button C", ""), nil)
vbox2 = iup.vbox(iup.label("Inside Tab D"), iup.button("Button D", ""), nil)

iup.setAttribute(vbox1, "TABTITLE", "Tab C")
iup.setAttribute(vbox2, "TABTITLE", "Tab D")

var tabs2 = iup.tabs(vbox1, vbox2, nil)
iup.setAttribute(tabs2, "TABTYPE", "LEFT")

var box = iup.hbox(tabs1, tabs2, nil)
iup.setAttribute(box, "MARGIN", "10x10")
iup.setAttribute(box, "GAP", "10")

var dlg = iup.dialog(box)
iup.setAttribute(dlg, "TITLE", "iupTabs")
iup.setAttribute(dlg, "SIZE", "200x100")

discard showXY(dlg, IUP_CENTER, IUP_CENTER)
discard mainLoop()
close()

