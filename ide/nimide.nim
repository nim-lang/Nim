# The beginning of an IDE for Nimrod
#  (c) 2008 Andreas Rumpf

import os, glib2, gdk2, gtk2, libglade2, pango, dialogs, parseopt

const
  GuiTemplate = "nimide.glade"
  dummyConst = ""

type
  TTab {.pure, final.} = object
    textview: PGtkTextView
    filename: string
    untitled: bool
    hbox: PGtkHBox
    e: PEditor
  PTab = ptr TTab
    
  TEditor = object of TObject
    window: PGtkWindow
    statusbar: PGtkStatusBar
    menu: PGtkMenuBar
    notebook: PGtkNotebook
    tabname: int               # used for generating tab names
  PEditor = ptr TEditor

proc on_window_destroy(obj: PGtkObject, event: PGdkEvent, 
                       data: pointer): gboolean {.cdecl.} =
  gtk_main_quit()

proc on_about_menu_item_activate(menuItem: PGtkMenuItem, e: PEditor) {.cdecl.} =
  gtk_show_about_dialog(e.window,
    "comments", "A fast and leight-weight IDE for Nimrod",
    "copyright", "Copyright \xc2\xa9 2008 Andreas Rumpf",
    "version", "0.1",
    "website", "http://nimrod.ethexor.com",
    "program-name", "Nimrod IDE",
    nil)

proc getTabIndex(e: PEditor, tab: PTab): int = 
  var i = 0
  while true:
    var w = gtk_notebook_get_nth_page(e.notebook, i)
    if w == nil: return -1
    var v = gtk_notebook_get_tab_label(e.notebook, w)
    if tab.hbox == v: return i
    inc(i)
  
proc OnCloseTab(button: PGtkButton, tab: PTab) {.cdecl.} = 
  var idx = getTabIndex(tab.e, tab)
  if idx >= 0: gtk_notebook_remove_page(tab.e.notebook, idx)

proc createTab(e: PEditor, filename: string, untitled: bool) = 
  var t = cast[PTab](alloc0(sizeof(TTab)))
  t.textview = gtk_text_view_new_with_buffer(gtk_text_buffer_new(nil))
  var font_desc = pango_font_description_from_string("monospace 10")
  gtk_widget_modify_font(t.textview, font_desc)
  pango_font_description_free(font_desc)
  t.filename = filename
  t.untitled = untitled
  gtk_widget_show(t.textview)
  var scroll = gtk_scrolled_window_new(nil, nil)
  gtk_container_add(scroll, t.textview)
  gtk_widget_show(scroll)
  
  t.e = e
  t.hbox = gtk_hbox_new(false, 0)
  var image = gtk_image_new_from_stock(GTK_STOCK_CLOSE, GTK_ICON_SIZE_MENU)
  var button = gtk_button_new()
  var lab = gtk_label_new(filename)
  gtk_button_set_image(button, image)
  gtk_button_set_relief(button, GTK_RELIEF_NONE)
  gtk_box_pack_start(t.hbox, lab, false, false, 2)
  gtk_box_pack_end(t.hbox, button, false, false, 0)
  
  discard g_signal_connect(button, "clicked", G_Callback(onCloseTab), t)
  gtk_widget_show(button)
  gtk_widget_show(lab)
 
  var idx = gtk_notebook_append_page(e.notebook, scroll, t.hbox)
  gtk_notebook_set_current_page(e.notebook, idx)

proc on_new_menu_item_activate(menuItem: PGtkMenuItem, e: PEditor) {.cdecl.} =
  inc(e.tabname)
  createTab(e, "untitled-" & $e.tabname, true)

proc main(e: PEditor) = 
  var builder = glade_xml_new(getApplicationDir() / GuiTemplate, nil, nil)
  if builder == nil: quit("cannot open: " & GuiTemplate)
  # get the components:
  e.window = GTK_WINDOW(glade_xml_get_widget(builder, "window"))
  e.statusbar = GTK_STATUSBAR(glade_xml_get_widget(builder, "statusbar"))
  e.notebook = GTK_NOTEBOOK(glade_xml_get_widget(builder, "notebook"))
  setHomogeneous(e.notebook^, 1)

  # connect the signal handlers:
  glade_xml_signal_connect(builder, "on_window_destroy",
                           GCallback(on_window_destroy))
  var about = GTK_MENU_ITEM(glade_xml_get_widget(builder, "about_menu_item"))
  discard g_signal_connect(about, "activate", 
                           G_CALLBACK(on_about_menu_item_activate), e)

  var newItem = GTK_MENU_ITEM(glade_xml_get_widget(builder, "new_menu_item"))
  discard g_signal_connect(newItem, "activate", 
                           G_CALLBACK(on_new_menu_item_activate), e)

  var quitItem = GTK_MENU_ITEM(glade_xml_get_widget(builder, "quit_menu_item"))
  discard g_signal_connect(quitItem, "activate", 
                           G_CALLBACK(on_window_destroy), e)

  gtk_window_set_default_icon_name(GTK_STOCK_EDIT)
  gtk_widget_show(e.window)
  gtk_main()


gtk_nimrod_init()
var e = cast[PEditor](alloc0(sizeof(TEditor)))
main(e)
