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
    tabs: seq[PTab]
    currTab: int
  PEditor = ptr TEditor

proc onWindowDestroy(obj: PGtkObject, event: PGdkEvent,
                     data: pointer): gboolean {.cdecl.} =
  gtkMainQuit()

proc onAboutMenuItemActivate(menuItem: PGtkMenuItem, e: PEditor) {.cdecl.} =
  gtkShowAboutDialog(e.window,
    "comments", "A fast and lightweight IDE for Nimrod",
    "copyright", "Copyright \xc2\xa9 2010 Andreas Rumpf",
    "version", "0.1",
    "website", "http://force7.de/nimrod/",
    "program-name", "Nimrod IDE",
    nil)

proc getTabIndex(e: PEditor, tab: PTab): int =
  var i = 0
  while true:
    var w = gtkNotebookGetNthPage(e.notebook, i)
    if w == nil: return -1
    var v = gtkNotebookGetTabLabel(e.notebook, w)
    if tab.hbox == v: return i
    inc(i)

proc getActiveTab(e: PEditor): PTab =
  nil

type
  TAnswer = enum
    answerYes, answerNo, answerCancel

proc askWhetherToSave(e: PEditor): TAnswer =
  var dialog = gtkDialogNewWithButtons("Should the changes be saved?",
    e.window, GTK_DIALOG_MODAL, GTK_STOCK_SAVE, 1, "gtk-discard", 2,
    GTK_STOCK_CANCEL, 3, nil)
  result = TAnswer(gtkDialogRun(dialog)+1)
  gtkWidgetDestroy(dialog)

proc saveTab(tab: PTab) =
  if tab.untitled:
    tab.filename = ChooseFileToSave(tab.e.window, getRoot(tab))
    tab.untitled = false
  XXX

proc OnCloseTab(button: PGtkButton, tab: PTab) {.cdecl.} =
  var idx = -1
  for i in 0..high(tab.e.tabs):
    if tab.e.tabs[i] == tab:
      idx = i
      break
  if idx >= 0:
    if gtkTextBufferGetModified(gtkTextViewGetBuffer(tab.textView)):
      case askWhetherToSave(tab.e)
      of answerCancel: return
      of answerYes: saveTab(tab)
      of answerNo: nil

    gtkNotebookRemovePage(tab.e.notebook, idx)
    if idx < high(tab.e.tabs):
      for i in idx..high(tab.e.tabs)-1:
        tab.e.tabs[i] = tab.e.tabs[i+1]
    else:
      dec currTab
    GC_unref(tab.filename)
    dealloc(tab)
  #var idx = getTabIndex(tab.e, tab)
  #if idx >= 0: gtk_notebook_remove_page(tab.e.notebook, idx)

proc createTab(e: PEditor, filename: string, untitled: bool) =
  var t = cast[PTab](alloc0(sizeof(TTab)))
  t.textview = gtkTextViewNewWithBuffer(gtkTextBufferNew(nil))
  var fontDesc = pangoFontDescriptionFromString("monospace 10")
  gtkWidgetModifyFont(t.textview, fontDesc)
  pangoFontDescriptionFree(fontDesc)
  t.filename = filename
  t.untitled = untitled
  gtkWidgetShow(t.textview)
  var scroll = gtkScrolledWindowNew(nil, nil)
  gtkContainerAdd(scroll, t.textview)
  gtkWidgetShow(scroll)

  t.e = e
  t.hbox = gtkHboxNew(false, 0)
  var image = gtkImageNewFromStock(GTK_STOCK_CLOSE, GTK_ICON_SIZE_MENU)
  var button = gtkButtonNew()
  var lab = gtkLabelNew(filename)
  gtkButtonSetImage(button, image)
  gtkButtonSetRelief(button, GTK_RELIEF_NONE)
  gtkBoxPackStart(t.hbox, lab, false, false, 2)
  gtkBoxPackEnd(t.hbox, button, false, false, 0)

  discard gSignalConnect(button, "clicked", G_Callback(onCloseTab), t)
  gtkWidgetShow(button)
  gtkWidgetShow(lab)

  var idx = gtkNotebookAppendPage(e.notebook, scroll, t.hbox)
  e.currTab = idx
  add(e.tabs, t)
  gtkNotebookSetCurrentPage(e.notebook, idx)


proc onOpenMenuItemActivate(menuItem: PGtkMenuItem, e: PEditor) {.cdecl.} =
  var files = ChooseFilesToOpen(e.window, getRoot(getActiveTab(e)))
  for f in items(files): createTab(e, f, untitled=false)

proc onSaveMenuItemActivate(menuItem: PGtkMenuItem, e: PEditor) {.cdecl.} =
  var cp = gtkNotebookGetCurrentPage(e.notebook)


proc onSaveAsMenuItemActivate(menuItem: PGtkMenuItem, e: PEditor) {.cdecl.} =
  nil

proc onNewMenuItemActivate(menuItem: PGtkMenuItem, e: PEditor) {.cdecl.} =
  inc(e.tabname)
  createTab(e, "untitled-" & $e.tabname, true)

proc main(e: PEditor) =
  var builder = gladeXmlNew(getApplicationDir() / GuiTemplate, nil, nil)
  if builder == nil: quit("cannot open: " & GuiTemplate)
  # get the components:
  e.window = GTK_WINDOW(gladeXmlGetWidget(builder, "window"))
  e.statusbar = GTK_STATUSBAR(gladeXmlGetWidget(builder, "statusbar"))
  e.notebook = GTK_NOTEBOOK(gladeXmlGetWidget(builder, "notebook"))
  e.tabs = @[]
  e.currTab = -1
  setHomogeneous(e.notebook^, 1)

  # connect the signal handlers:
  gladeXmlSignalConnect(builder, "on_window_destroy",
                        GCallback(onWindowDestroy))
  var about = GTK_MENU_ITEM(gladeXmlGetWidget(builder, "about_menu_item"))
  discard gSignalConnect(about, "activate",
                         G_CALLBACK(onAboutMenuItemActivate), e)

  var newItem = GTK_MENU_ITEM(gladeXmlGetWidget(builder, "new_menu_item"))
  discard gSignalConnect(newItem, "activate",
                         G_CALLBACK(onNewMenuItemActivate), e)

  var quitItem = GTK_MENU_ITEM(gladeXmlGetWidget(builder, "quit_menu_item"))
  discard gSignalConnect(quitItem, "activate",
                         G_CALLBACK(onWindowDestroy), e)

  var openItem = GTK_MENU_ITEM(gladeXmlGetWidget(builder, "open_menu_item"))
  discard gSignalConnect(openItem, "activate",
                         G_CALLBACK(onOpenMenuItemActivate), e)

  var saveItem = GTK_MENU_ITEM(gladeXmlGetWidget(builder, "save_menu_item"))
  discard gSignalConnect(saveItem, "activate",
                         G_CALLBACK(onSaveMenuItemActivate), e)

  var saveAsItem = GTK_MENU_ITEM(gladeXmlGetWidget(builder, "save_as_menu_item"))
  discard gSignalConnect(saveAsItem, "activate",
                         G_CALLBACK(onSaveAsMenuItemActivate), e)

  gtkWindowSetDefaultIconName(GTK_STOCK_EDIT)
  gtkWidgetShow(e.window)
  gtkMain()


gtkNimrodInit()
var e = cast[PEditor](alloc0(sizeof(TEditor)))
main(e)

