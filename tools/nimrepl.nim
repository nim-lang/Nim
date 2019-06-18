#
#
#              Nim REPL
#        (c) Copyright 2012 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import glib2, gtk2, gdk2, os, osproc, dialogs, strutils


const runCmd = "c -r"

var nimExe = findExe("nim")
if nimExe.len == 0: nimExe = "../bin" / addFileExt("nim", os.ExeExt)

proc execCode(code: string): string =
  var f: File
  if open(f, "temp.nim", fmWrite):
    f.write(code)
    f.close()
    result = osproc.execProcess(
      "$# $# --verbosity:0 --hint[Conf]:off temp.nim" % [nimExe, runCmd],
      options = {poStdErrToStdOut})
  else:
    result = "cannot open file 'temp.nim'"

var shiftPressed = false
var w: gtk2.PWindow
var inputTextBuffer: PTextBuffer
var outputTextBuffer: PTextBuffer

proc destroy(widget: PWidget, data: pointer){.cdecl.} =
  main_quit()

proc fileOpenClicked(menuitem: PMenuItem, userdata: pointer) {.cdecl.} =
  var path = chooseFileToOpen(w)
  if path != "":
    var file = readFile(path)
    if file != nil:
      set_text(inputTextBuffer, file, len(file).gint)
    else:
      error(w, "Unable to read from file")

proc fileSaveClicked(menuitem: PMenuItem, userdata: pointer) {.cdecl.} =
  var path = chooseFileToSave(w)

  if path == "": return
  var startIter: TTextIter
  var endIter: TTextIter
  get_start_iter(inputTextBuffer, addr(startIter))
  get_end_iter(inputTextBuffer, addr(endIter))
  var inputText = get_text(inputTextBuffer, addr(startIter),
                           addr(endIter), false)
  var f: File
  if open(f, path, fmWrite):
    f.write(inputText)
    f.close()
  else:
    error(w, "Unable to write to file")

proc inputKeyPressed(widget: PWidget, event: PEventKey,
                     userdata: pointer): bool {.cdecl.} =
  if ($keyval_name(event.keyval)).tolower() == "shift_l":
    # SHIFT is pressed
    shiftPressed = true

proc setError(msg: string) =
  outputTextBuffer.setText(msg, msg.len.gint)

proc inputKeyReleased(widget: PWidget, event: PEventKey,
                      userdata: pointer): bool {.cdecl.} =
  #echo(keyval_name(event.keyval))
  if ($keyval_name(event.keyval)).tolower() == "shift_l":
    # SHIFT is released
    shiftPressed = false

  if ($keyval_name(event.keyval)).tolower() == "return":
    #echo($keyval_name(event.keyval), "Shift_L")
    # Enter pressed
    if not shiftPressed:
      var startIter: TTextIter
      var endIter: TTextIter
      get_start_iter(inputTextBuffer, addr(startIter))
      get_end_iter(inputTextBuffer, addr(endIter))
      var inputText = get_text(inputTextBuffer, addr(startIter),
                               addr(endIter), false)

      try:
        var r = execCode($inputText)
        set_text(outputTextBuffer, r, len(r).gint)
      except IOError:
        setError("Error: Could not open file temp.nim")


proc initControls() =
  w = window_new(gtk2.WINDOW_TOPLEVEL)
  set_default_size(w, 500, 600)
  set_title(w, "Nim REPL")
  discard signal_connect(w, "destroy", SIGNAL_FUNC(nimrepl.destroy), nil)

  # MainBox (vbox)
  var mainBox = vbox_new(false, 0)
  add(w, mainBox)

  # TopMenu (MenuBar)
  var topMenu = menu_bar_new()
  show(topMenu)

  var fileMenu = menu_new()
  var openMenuItem = menu_item_new("Open")
  append(fileMenu, openMenuItem)
  show(openMenuItem)
  discard signal_connect(openMenuItem, "activate",
                          SIGNAL_FUNC(fileOpenClicked), nil)
  var saveMenuItem = menu_item_new("Save...")
  append(fileMenu, saveMenuItem)
  show(saveMenuItem)
  discard signal_connect(saveMenuItem, "activate",
                          SIGNAL_FUNC(fileSaveClicked), nil)
  var fileMenuItem = menu_item_new("File")


  set_submenu(fileMenuItem, fileMenu)
  show(fileMenuItem)
  append(topMenu, fileMenuItem)

  pack_start(mainBox, topMenu, false, false, 0)

  # VPaned - Separates the InputTextView and the OutputTextView
  var paned = vpaned_new()
  set_position(paned, 450)
  pack_start(mainBox, paned, true, true, 0)
  show(paned)

  # Init the TextBuffers
  inputTextBuffer = text_buffer_new(nil)
  outputTextBuffer = text_buffer_new(nil)

  # InputTextView (TextView)
  var inputScrolledWindow = scrolled_window_new(nil, nil)
  set_policy(inputScrolledWindow, POLICY_AUTOMATIC, POLICY_AUTOMATIC)
  var inputTextView = text_view_new(inputTextBuffer)
  add_with_viewport(inputScrolledWindow, inputTextView)
  add1(paned, inputScrolledWindow)
  show(inputScrolledWindow)
  show(inputTextView)

  discard signal_connect(inputTextView, "key-release-event",
                          SIGNAL_FUNC(inputKeyReleased), nil)
  discard signal_connect(inputTextView, "key-press-event",
                          SIGNAL_FUNC(inputKeyPressed), nil)

  # OutputTextView (TextView)
  var outputScrolledWindow = scrolled_window_new(nil, nil)
  set_policy(outputScrolledWindow, POLICY_AUTOMATIC, POLICY_AUTOMATIC)
  var outputTextView = text_view_new(outputTextBuffer)
  add_with_viewport(outputScrolledWindow, outputTextView)
  add2(paned, outputScrolledWindow)
  show(outputScrolledWindow)
  show(outputTextView)

  show(w)
  show(mainBox)

nim_init()
initControls()
main()

