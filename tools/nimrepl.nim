import glib2, gtk2, gdk2, osproc, dialogs, strutils

type
  output = tuple[compiler, app: string]

proc execCode(code: string): output =

  var f: TFile
  if open(f, "temp.nim", fmWrite):
    f.write(code)
    f.close()
  else:
    raise newException(EIO, "Unable to open file")
    
  var compilerOutput = osproc.execProcess("nimrod c temp.nim")
  var appOutput = osproc.execProcess("temp.exe")
  return (compilerOutput, appOutput)

var shiftPressed = False
var w: PGtkWindow
var InputTextBuffer: PGtkTextBuffer
var OutputTextBuffer: PGtkTextBuffer

proc destroy(widget: PGtkWidget, data: pgpointer){.cdecl.} = 
  gtk_main_quit()

proc FileOpenClicked(menuitem: PGtkMenuItem, userdata: pgpointer) =
  var path = ChooseFileToOpen(w)
  
  if path != "":

    var file: string = readFile(path)
    if file != nil:
      gtk_text_buffer_set_text(InputTextBuffer, file, len(file))
      
    else:
      error(w, "Unable to read from file")

proc FileSaveClicked(menuitem: PGtkMenuItem, userdata: pgpointer) =
  var path = ChooseFileToSave(w)
  
  if path != "":
    var startIter: TGtkTextIter
    var endIter: TGtkTextIter
    gtk_text_buffer_get_start_iter(InputTextBuffer, addr(startIter))
    gtk_text_buffer_get_end_iter(InputTextBuffer, addr(endIter))
    var InputText = gtk_text_buffer_get_text(InputTextBuffer, addr(startIter), addr(endIter), False)

    var f: TFile
    if open(f, path, fmWrite):
      f.write(InputText)
      f.close()
    else:
      error(w, "Unable to write to file")


proc inputKeyPressed(widget: PGtkWidget, event: PGdkEventKey, userdata: pgpointer): bool =
  if ($gdk_keyval_name(event.keyval)).tolower() == "shift_l":
    # SHIFT is pressed
    shiftPressed = True
  
  return False
proc inputKeyReleased(widget: PGtkWidget, event: PGdkEventKey, userdata: pgpointer): bool =
  echo(gdk_keyval_name(event.keyval))
  if ($gdk_keyval_name(event.keyval)).tolower() == "shift_l":
    # SHIFT is released
    shiftPressed = False
    
  if ($gdk_keyval_name(event.keyval)).tolower() == "return":
    echo($gdk_keyval_name(event.keyval), "Shift_L")
    # Enter pressed
    if shiftPressed == False:
      var startIter: TGtkTextIter
      var endIter: TGtkTextIter
      gtk_text_buffer_get_start_iter(InputTextBuffer, addr(startIter))
      gtk_text_buffer_get_end_iter(InputTextBuffer, addr(endIter))
      var InputText = gtk_text_buffer_get_text(InputTextBuffer, addr(startIter), addr(endIter), False)

      try:
        var r: output = execCode($InputText)
        gtk_text_buffer_set_text(OutputTextBuffer, r[0] & r[1], len(r[0] & r[1]))
      except:
        gtk_text_buffer_set_text(OutputTextBuffer, "Error: Could not open file temp.nim", len("Error: Could not open file temp.nim"))

  return False

proc initControls() =
  w = gtk_window_new(GTK_WINDOW_TOPLEVEL)
  gtk_window_set_default_size(w, 500, 600)
  gtk_window_set_title(w, "Nimrod REPL")
  discard gtk_signal_connect(GTKOBJECT(w), "destroy", 
                          GTK_SIGNAL_FUNC(destroy), nil)
  
  # MainBox (vbox)
  var MainBox: PGtkWidget = gtk_vbox_new(False, 0)
  gtk_container_add(GTK_Container(w), MainBox)
  
  # TopMenu (MenuBar)
  var TopMenu: PGtkWidget = gtk_menu_bar_new()
  gtk_widget_show(TopMenu)
  
  var FileMenu = gtk_menu_new()
  var OpenMenuItem = gtk_menu_item_new_with_label("Open")
  gtk_menu_append(FileMenu, OpenMenuItem)
  gtk_widget_show(OpenMenuItem)
  discard gtk_signal_connect(GTKOBJECT(OpenMenuItem), "activate", 
                          GTK_SIGNAL_FUNC(FileOpenClicked), nil)
  var SaveMenuItem = gtk_menu_item_new_with_label("Save...")
  gtk_menu_append(FileMenu, SaveMenuItem)
  gtk_widget_show(SaveMenuItem)
  discard gtk_signal_connect(GTKOBJECT(SaveMenuItem), "activate", 
                          GTK_SIGNAL_FUNC(FileSaveClicked), nil)
  var FileMenuItem = gtk_menu_item_new_with_label("File")

  
  gtk_menu_item_set_submenu(FileMenuItem, FileMenu)
  gtk_widget_show(FileMenuItem)
  gtk_menu_bar_append(TopMenu, FileMenuItem)
  
  gtk_box_pack_start(GTK_Box(MainBox), TopMenu, False, False, 0)

  # VPaned - Seperates the InputTextView and the OutputTextView
  var paned = gtk_vpaned_new()
  gtk_paned_set_position(paned, 450)
  gtk_box_pack_start(GTK_Box(MainBox), paned, True, True, 0)
  gtk_widget_show(paned)

  # Init the TextBuffers
  InputTextBuffer = gtk_text_buffer_new(nil)
  OutputTextBuffer = gtk_text_buffer_new(nil)

  # InputTextView (TextView)
  var InputScrolledWindow = gtk_scrolled_window_new(nil, nil)
  gtk_scrolled_window_set_policy(InputScrolledWindow,
                GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC)
  var InputTextView = gtk_text_view_new_with_buffer(InputTextBuffer)
  gtk_scrolled_window_add_with_viewport(InputScrolledWindow, InputTextView)
  gtk_paned_add1(paned, InputScrolledWindow)
  gtk_widget_show(InputScrolledWindow)
  gtk_widget_show(InputTextView)
  
  discard gtk_signal_connect(GTKOBJECT(InputTextView), "key-release-event", 
                          GTK_SIGNAL_FUNC(inputKeyReleased), nil)
  discard gtk_signal_connect(GTKOBJECT(InputTextView), "key-press-event", 
                          GTK_SIGNAL_FUNC(inputKeyPressed), nil)
  
  # OutputTextView (TextView)
  var OutputScrolledWindow = gtk_scrolled_window_new(nil, nil)
  gtk_scrolled_window_set_policy(OutputScrolledWindow,
                GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC)
  var OutputTextView = gtk_text_view_new_with_buffer(OutputTextBuffer)
  gtk_scrolled_window_add_with_viewport(OutputScrolledWindow, OutputTextView)
  gtk_paned_add2(paned, OutputScrolledWindow)
  gtk_widget_show(OutputScrolledWindow)
  gtk_widget_show(OutputTextView)
  
  gtk_widget_show(w)
  gtk_widget_show(MainBox)
  
gtk_nimrod_init()
initControls()
gtk_main()
