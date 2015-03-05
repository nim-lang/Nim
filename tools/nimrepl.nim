#
#
#              Nim REPL
#        (c) Copyright 2012 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import glib2, gtk2, gdk2, os, osproc, dialogs, strutils

when defined(tinyc):
  const runCmd = "run"
else:
  const runCmd = "c -r"

var nimExe = findExe("nim")
if nimExe.len == 0: nimExe = "../bin" / addFileExt("nim", os.exeExt)

proc execCode(code: string): string =
  var f: TFile
  if open(f, "temp.nim", fmWrite):
    f.write(code)
    f.close()
    result = osproc.execProcess(
      "$# $# --verbosity:0 --hint[Conf]:off temp.nim" % [nimExe, runCmd],
      options = {poStdErrToStdOut})
  else:
    result = "cannot open file 'temp.nim'"

var shiftPressed = False
var w: gtk2.PWindow
var InputTextBuffer: PTextBuffer
var OutputTextBuffer: PTextBuffer

proc destroy(widget: PWidget, data: pgpointer){.cdecl.} = 
  main_quit()

proc fileOpenClicked(menuitem: PMenuItem, userdata: pgpointer) {.cdecl.} =
  var path = ChooseFileToOpen(w)
  if path != "":
    var file = readFile(path)
    if file != nil:
      set_text(InputTextBuffer, file, len(file).gint)
    else:
      error(w, "Unable to read from file")

proc fileSaveClicked(menuitem: PMenuItem, userdata: pgpointer) {.cdecl.} =
  var path = ChooseFileToSave(w)
  
  if path == "": return
  var startIter: TTextIter
  var endIter: TTextIter
  get_start_iter(InputTextBuffer, addr(startIter))
  get_end_iter(InputTextBuffer, addr(endIter))
  var InputText = get_text(InputTextBuffer, addr(startIter), 
                           addr(endIter), False)
  var f: TFile
  if open(f, path, fmWrite):
    f.write(InputText)
    f.close()
  else:
    error(w, "Unable to write to file")

proc inputKeyPressed(widget: PWidget, event: PEventKey, 
                     userdata: pgpointer): bool {.cdecl.} =
  if ($keyval_name(event.keyval)).tolower() == "shift_l":
    # SHIFT is pressed
    shiftPressed = True
  
proc setError(msg: string) = 
  outputTextBuffer.setText(msg, msg.len.gint)
  
proc inputKeyReleased(widget: PWidget, event: PEventKey, 
                      userdata: pgpointer): bool {.cdecl.} =
  #echo(keyval_name(event.keyval))
  if ($keyval_name(event.keyval)).tolower() == "shift_l":
    # SHIFT is released
    shiftPressed = False
    
  if ($keyval_name(event.keyval)).tolower() == "return":
    #echo($keyval_name(event.keyval), "Shift_L")
    # Enter pressed
    if shiftPressed == False:
      var startIter: TTextIter
      var endIter: TTextIter
      get_start_iter(InputTextBuffer, addr(startIter))
      get_end_iter(InputTextBuffer, addr(endIter))
      var InputText = get_text(InputTextBuffer, addr(startIter), 
                               addr(endIter), False)

      try:
        var r = execCode($InputText)
        set_text(OutputTextBuffer, r, len(r).gint)
      except EIO:
        setError("Error: Could not open file temp.nim")


proc initControls() =
  w = window_new(gtk2.WINDOW_TOPLEVEL)
  set_default_size(w, 500, 600)
  set_title(w, "Nimrod REPL")
  discard signal_connect(w, "destroy", SIGNAL_FUNC(nimrepl.destroy), nil)
  
  # MainBox (vbox)
  var MainBox = vbox_new(False, 0)
  add(w, MainBox)
  
  # TopMenu (MenuBar)
  var TopMenu = menu_bar_new()
  show(TopMenu)
  
  var FileMenu = menu_new()
  var OpenMenuItem = menu_item_new("Open")
  append(FileMenu, OpenMenuItem)
  show(OpenMenuItem)
  discard signal_connect(OpenMenuItem, "activate", 
                          SIGNAL_FUNC(fileOpenClicked), nil)
  var SaveMenuItem = menu_item_new("Save...")
  append(FileMenu, SaveMenuItem)
  show(SaveMenuItem)
  discard signal_connect(SaveMenuItem, "activate", 
                          SIGNAL_FUNC(fileSaveClicked), nil)
  var FileMenuItem = menu_item_new("File")

  
  set_submenu(FileMenuItem, FileMenu)
  show(FileMenuItem)
  append(TopMenu, FileMenuItem)
  
  pack_start(MainBox, TopMenu, False, False, 0)

  # VPaned - Separates the InputTextView and the OutputTextView
  var paned = vpaned_new()
  set_position(paned, 450)
  pack_start(MainBox, paned, True, True, 0)
  show(paned)

  # Init the TextBuffers
  InputTextBuffer = text_buffer_new(nil)
  OutputTextBuffer = text_buffer_new(nil)

  # InputTextView (TextView)
  var InputScrolledWindow = scrolled_window_new(nil, nil)
  set_policy(InputScrolledWindow, POLICY_AUTOMATIC, POLICY_AUTOMATIC)
  var InputTextView = text_view_new(InputTextBuffer)
  add_with_viewport(InputScrolledWindow, InputTextView)
  add1(paned, InputScrolledWindow)
  show(InputScrolledWindow)
  show(InputTextView)
  
  discard signal_connect(InputTextView, "key-release-event", 
                          SIGNAL_FUNC(inputKeyReleased), nil)
  discard signal_connect(InputTextView, "key-press-event", 
                          SIGNAL_FUNC(inputKeyPressed), nil)
  
  # OutputTextView (TextView)
  var OutputScrolledWindow = scrolled_window_new(nil, nil)
  set_policy(OutputScrolledWindow, POLICY_AUTOMATIC, POLICY_AUTOMATIC)
  var OutputTextView = text_view_new(OutputTextBuffer)
  add_with_viewport(OutputScrolledWindow, OutputTextView)
  add2(paned, OutputScrolledWindow)
  show(OutputScrolledWindow)
  show(OutputTextView)
  
  show(w)
  show(MainBox)
  
nimrod_init()
initControls()
main()

