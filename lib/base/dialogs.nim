#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## This module implements portable dialogs for Nimrod; the implementation
## builds on the GTK interface. On Windows, native dialogs are shown if
## appropriate.

import
  glib2, gtk2

when defined(Windows):
  import windows, ShellAPI, os

type
  PWindow* = PGtkWindow ## A shortcut for a GTK window.

proc info*(window: PWindow, msg: string) =
  ## Shows an information message to the user. The process waits until the
  ## user presses the OK button.
  when defined(Windows):
    discard MessageBoxA(0, msg, "Information", MB_OK or MB_ICONINFORMATION)
  else:
    var dialog = GTK_DIALOG(gtk_message_dialog_new(window,
                GTK_DIALOG_MODAL or GTK_DIALOG_DESTROY_WITH_PARENT,
                GTK_MESSAGE_INFO, GTK_BUTTONS_OK, "%s", cstring(msg)))
    gtk_window_set_title(dialog, "Information")
    discard gtk_dialog_run(dialog)
    gtk_widget_destroy(dialog)

proc warning*(window: PWindow, msg: string) =
  ## Shows a warning message to the user. The process waits until the user
  ## presses the OK button.
  when defined(Windows):
    discard MessageBoxA(0, msg, "Warning", MB_OK or MB_ICONWARNING)
  else:
    var dialog = GTK_DIALOG(gtk_message_dialog_new(window,
                GTK_DIALOG_MODAL or GTK_DIALOG_DESTROY_WITH_PARENT,
                GTK_MESSAGE_WARNING, GTK_BUTTONS_OK, "%s", cstring(msg)))
    gtk_window_set_title(dialog, "Warning")
    discard gtk_dialog_run(dialog)
    gtk_widget_destroy(dialog)

proc error*(window: PWindow, msg: string) =
  ## Shows an error message to the user. The process waits until the user
  ## presses the OK button.
  when defined(Windows):
    discard MessageBoxA(0, msg, "Error", MB_OK or MB_ICONERROR)
  else:
    var dialog = GTK_DIALOG(gtk_message_dialog_new(window,
                GTK_DIALOG_MODAL or GTK_DIALOG_DESTROY_WITH_PARENT,
                GTK_MESSAGE_ERROR, GTK_BUTTONS_OK, "%s", cstring(msg)))
    gtk_window_set_title(dialog, "Error")
    discard gtk_dialog_run(dialog)
    gtk_widget_destroy(dialog)


proc ChooseFileToOpen*(window: PWindow, root: string = ""): string =
  ## Opens a dialog that requests a filename from the user. Returns ""
  ## if the user closed the dialog without selecting a file. On Windows,
  ## the native dialog is used, else the GTK dialog is used.
  when defined(Windows):
    var
      opf: TOPENFILENAME
      buf: array [0..2047, char]
    opf.lStructSize = sizeof(opf)
    if root.len > 0:
      opf.lpstrInitialDir = root
    opf.lpstrFilter = "All Files\0*.*\0\0"
    opf.flags = OFN_FILEMUSTEXIST
    opf.lpstrFile = buf
    opf.nMaxFile = sizeof(buf)
    var res = GetOpenFileName(addr(opf))
    if res != 0:
      result = $buf
    else:
      result = ""
  else:
    var
      chooser: PGtkDialog
    chooser = GTK_DIALOG(gtk_file_chooser_dialog_new("Open File", window,
                GTK_FILE_CHOOSER_ACTION_OPEN,
                GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
                GTK_STOCK_OPEN, GTK_RESPONSE_OK, nil))
    if root.len > 0:
      discard gtk_file_chooser_set_current_folder(chooser, root)
    if gtk_dialog_run(chooser) == cint(GTK_RESPONSE_OK):
      var x = gtk_file_chooser_get_filename(chooser)
      result = $x
      g_free(x)
    else:
      result = ""
    gtk_widget_destroy(chooser)

proc ChooseFilesToOpen*(window: PWindow, root: string = ""): seq[string] =
  ## Opens a dialog that requests filenames from the user. Returns ``@[]``
  ## if the user closed the dialog without selecting a file. On Windows,
  ## the native dialog is used, else the GTK dialog is used.
  when defined(Windows):
    var
      opf: TOPENFILENAME
      buf: array [0..2047*4, char]
    opf.lStructSize = sizeof(opf)
    if root.len > 0:
      opf.lpstrInitialDir = root
    opf.lpstrFilter = "All Files\0*.*\0\0"
    opf.flags = OFN_FILEMUSTEXIST or OFN_ALLOWMULTISELECT or OFN_EXPLORER
    opf.lpstrFile = buf
    opf.nMaxFile = sizeof(buf)
    var res = GetOpenFileName(addr(opf))
    result = @[]
    if res != 0:
      # parsing the result is horrible:
      var
        i = 0
        s: string
        path = ""
      while buf[i] != '\0':
        add(path, buf[i])
        inc(i)
      inc(i)
      if buf[i] != '\0':
        while true:
          s = ""
          while buf[i] != '\0':
            add(s, buf[i])
            inc(i)
          add(result, s)
          inc(i)
          if buf[i] == '\0': break
        for i in 0..result.len-1: result[i] = os.joinPath(path, result[i])
  else:
    var
      chooser: PGtkDialog
    chooser = GTK_DIALOG(gtk_file_chooser_dialog_new("Open Files", window,
                GTK_FILE_CHOOSER_ACTION_OPEN,
                GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
                GTK_STOCK_OPEN, GTK_RESPONSE_OK, nil))
    if root.len > 0:
      discard gtk_file_chooser_set_current_folder(chooser, root)
    gtk_file_chooser_set_select_multiple(chooser, true)
    result = @[]
    if gtk_dialog_run(chooser) == cint(GTK_RESPONSE_OK):
      var L = gtk_file_chooser_get_filenames(chooser)
      var it = L
      while it != nil:
        add(result, $cast[cstring](it.data))
        g_free(it.data)
        it = it.next
      g_slist_free(L)
    gtk_widget_destroy(chooser)


proc ChooseFileToSave*(window: PWindow, root: string = ""): string =
  ## Opens a dialog that requests a filename to save to from the user.
  ## Returns "" if the user closed the dialog without selecting a file.
  ## On Windows, the native dialog is used, else the GTK dialog is used.
  when defined(Windows):
    var
      opf: TOPENFILENAME
      buf: array [0..2047, char]
    opf.lStructSize = sizeof(opf)
    if root.len > 0:
      opf.lpstrInitialDir = root
    opf.lpstrFilter = "All Files\0*.*\0\0"
    opf.flags = OFN_OVERWRITEPROMPT
    opf.lpstrFile = buf
    opf.nMaxFile = sizeof(buf)
    var res = GetSaveFileName(addr(opf))
    if res != 0:
      result = $buf
    else:
      result = ""
  else:
    var
      chooser: PGtkDialog
    chooser = GTK_DIALOG(gtk_file_chooser_dialog_new("Save File", window,
                GTK_FILE_CHOOSER_ACTION_SAVE,
                GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
                GTK_STOCK_OPEN, GTK_RESPONSE_OK, nil))
    if root.len > 0:
      discard gtk_file_chooser_set_current_folder(chooser, root)
    gtk_file_chooser_set_do_overwrite_confirmation(chooser, true)
    if gtk_dialog_run(chooser) == cint(GTK_RESPONSE_OK):
      var x = gtk_file_chooser_get_filename(chooser)
      result = $x
      g_free(x)
    else:
      result = ""
    gtk_widget_destroy(chooser)


proc ChooseDir*(window: PWindow, root: string = ""): string =
  ## Opens a dialog that requests a directory from the user.
  ## Returns "" if the user closed the dialog without selecting a directory.
  ## On Windows, the native dialog is used, else the GTK dialog is used.
  when defined(Windows):
    var
      lpItemID: PItemIDList
      BrowseInfo: TBrowseInfo
      DisplayName: array [0..MAX_PATH, char]
      TempPath: array [0..MAX_PATH, char]
    Result = ""
    #BrowseInfo.hwndOwner = Application.Handle
    BrowseInfo.pszDisplayName = DisplayName
    BrowseInfo.ulFlags = 1 #BIF_RETURNONLYFSDIRS
    lpItemID = SHBrowseForFolder(cast[LPBrowseInfo](addr(BrowseInfo)))
    if lpItemId != nil:
      discard SHGetPathFromIDList(lpItemID, TempPath)
      Result = $TempPath
      discard GlobalFreePtr(lpItemID)
  else:
    var
      chooser: PGtkDialog
    chooser = GTK_DIALOG(gtk_file_chooser_dialog_new("Select Directory", window,
                GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER,
                GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
                GTK_STOCK_OPEN, GTK_RESPONSE_OK, nil))
    if root.len > 0:
      discard gtk_file_chooser_set_current_folder(chooser, root)
    if gtk_dialog_run(chooser) == cint(GTK_RESPONSE_OK):
      var x = gtk_file_chooser_get_filename(chooser)
      result = $x
      g_free(x)
    else:
      result = ""
    gtk_widget_destroy(chooser)

