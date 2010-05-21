# Example IUP program

# IupTabs: Creates a IupTabs control.

import iup

discard iup.Open(nil, nil)

var vbox1 = Iup.Vbox(Iup.Label("Inside Tab A"), Iup.Button("Button A", ""), nil)
var vbox2 = Iup.Vbox(Iup.Label("Inside Tab B"), Iup.Button("Button B", ""), nil)

Iup.SetAttribute(vbox1, "TABTITLE", "Tab A")
Iup.SetAttribute(vbox2, "TABTITLE", "Tab B")

var tabs1 = Iup.Tabs(vbox1, vbox2, nil)

vbox1 = Iup.Vbox(Iup.Label("Inside Tab C"), Iup.Button("Button C", ""), nil)
vbox2 = Iup.Vbox(Iup.Label("Inside Tab D"), Iup.Button("Button D", ""), nil)

Iup.SetAttribute(vbox1, "TABTITLE", "Tab C")
Iup.SetAttribute(vbox2, "TABTITLE", "Tab D")

var tabs2 = Iup.Tabs(vbox1, vbox2, nil)
Iup.SetAttribute(tabs2, "TABTYPE", "LEFT")

var box = Iup.Hbox(tabs1, tabs2, nil)
Iup.SetAttribute(box, "MARGIN", "10x10")
Iup.SetAttribute(box, "GAP", "10")

var dlg = Iup.Dialog(box)
Iup.SetAttribute(dlg, "TITLE", "IupTabs")
Iup.SetAttribute(dlg, "SIZE", "200x100")

discard ShowXY(dlg, IUP_CENTER, IUP_CENTER)
discard MainLoop()
Close()

