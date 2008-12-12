# The beginning of an IDE for Nimrod
#  (c) 2008 Andreas Rumpf

import os, glib2, gtk2, libglade2, dialogs, parseopt

proc on_window_destroy(obj: PGtkObject, data: pointer) {.cdecl.} =
  gtk_main_quit()

const
  GuiTemplate = "/media/hda1/Eigenes/nimrod/ide/nimide.glade"

type
  TTab = object of TObject
    textview: PGtkTextView
    filename: string
    untitled: bool

  TMyTextEditor = object of TObject
    window: PGtkWindow
    statusbar: PGtkStatusBar
    textview: PGtkTextview
    statusbarContextId: int



proc on_about_menu_item_activate(menuItem: PGtkMenuItem,
                                 e: var TMyTextEditor) {.cdecl.} =
  gtk_show_about_dialog(e.window,
    "comments", "A fast and leight-weight IDE for Nimrod",
    "copyright", "Copyright \xc2\xa9 2008 Andreas Rumpf",
    "version", "0.1",
    "website", "http://nimrod.ethexor.com",
    "program-name", "Nimrod IDE",
    nil)

proc load_file(e: var TMyTextEditor, filename: string) =
  var
    err: pointer
    status: cstring
    text: cstring
    result: bool
    buffer: PGtkTextBuffer
  discard gtk_statusbar_push(e.statusbar, e.statusbar_context_id, "Loading...")
  while gtk_events_pending() != 0: discard gtk_main_iteration()

  # get the file contents
  result = g_file_get_contents(filename, addr(text), nil, addr(err))
  if not result:
    error(e.window, "Cannot load file")
    #g_error_free(err)

  # disable the text view while loading the buffer with the text
  gtk_widget_set_sensitive(e.text_view, false)
  buffer = gtk_text_view_get_buffer(e.text_view)
  gtk_text_buffer_set_text(buffer, text, -1)
  gtk_text_buffer_set_modified(buffer, false)
  gtk_widget_set_sensitive(e.text_view, true)
  g_free(text)

  e.filename = filename
  gtk_statusbar_pop(e.statusbar, e.statusbar_context_id)
  reset_default_status(e)

proc write_file(e: var TMyTextEditor, filename: string) =
  var
    err: ptr GError
    status: cstring
    text: cstring
    result: bool
    buffer: PGtkTextBuffer
    start, ende: TGtkTextIter
  # add Saving message to status bar and ensure GUI is current
  gtk_statusbar_push(e.statusbar, e.statusbar_context_id, "Saving....")
  while gtk_events_pending(): gtk_main_iteration()

  # disable text view and get contents of buffer
  gtk_widget_set_sensitive(editor->text_view, FALSE)
  buffer = gtk_text_view_get_buffer(e.text_view)
  gtk_text_buffer_get_start_iter(buffer, start)
  gtk_text_buffer_get_end_iter(buffer, ende)
  text = gtk_text_buffer_get_text(buffer, start, ende, FALSE)
  gtk_text_buffer_set_modified(buffer, false)
  gtk_widget_set_sensitive(e.text_view, true)
  # set the contents of the file to the text from the buffer
  if filename != "":
    result = g_file_set_contents(filename, text, -1, addr(err))
  else:
    result = g_file_set_contents(editor->filename, text, -1, addr(err))
  if not result:
    error_message("cannot save")
    g_error_free(err)
  g_free(text)
  if filename != "":
    e.filename = filename
  gtk_statusbar_pop(e.statusbar, e.statusbar_context_id)
  reset_default_status(editor)


proc check_for_save(e: var TMyTextEditor): bool =
  GtkTextBuffer           *buffer;
  buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (editor->text_view));
  if gtk_text_buffer_get_modified(buffer):
    GtkWidget       *dialog;
    const gchar *msg  = "Do you want to save the changes you have made?";
    dialog = gtk_message_dialog_new (nil,
                                     GTK_DIALOG_MODAL or
                                       GTK_DIALOG_DESTROY_WITH_PARENT,
                                     GTK_MESSAGE_QUESTION,
                                     GTK_BUTTONS_YES_NO,
                                     msg);
    gtk_window_set_title (GTK_WINDOW (dialog), "Save?");
    result = gtk_dialog_run(dialog) != GTK_RESPONSE_NO
    gtk_widget_destroy(dialog)

proc initApp(e: var TMyTextEditor) =
  var
    builder: PGladeXML
    window: PGtkWidget
    fontDesc: PPangoFontDescription
    id: int
  builder = glade_xml_new(GuiTemplate, nil, nil)
  if builder == nil:
    error_message("cannot open: " & GuiTemplate)
    quit(1)
  # get the components:
  e.window = GTK_WINDOW(glade_xml_get_widget(builder, "window"))
  e.statusbar = GTK_STATUSBAR(glade_xml_get_widget(builder, "statusbar"))
  e.textview = GTK_TEXTVIEW(glade_xml_get_widget(builder, "textview"))

  # connect the signal handlers:
  glade_xml_signal_connect(builder, "on_window_destroy",
                           GCallback(on_window_destroy))

  font_desc = pango_font_description_from_string("monospace 10")
  gtk_widget_modify_font(e.textview, font_desc)
  pango_font_description_free(font_desc)
  gtk_window_set_default_icon_name(GTK_STOCK_EDIT)

  id = gtk_statusbar_get_context_id(e.statusbar, "Nimrod IDE")
  e.statusbarContextId = id
  reset_default_status(e)

  e.filename = ""


proc main() =
  var
    editor: TMyTextEditor

  initApp(editor)
  gtk_widget_show(editor.window)
  gtk_main()

gtk_nimrod_init()
main()

proc on_window_delete_event(widget: PGtkWidget, event: PGdkEvent,
                       e: TMyTextEditor): bool {.cdecl.} =
  if check_for_save(editor):
    on_save_menu_item_activate(nil, editor)
  result = false

proc on_new_menu_item_activate(GtkMenuItem *menuitem, TutorialTextEditor *editor)
  GtkTextBuffer           *buffer;

  if check_for_save(editor):
    on_save_menu_item_activate(nil, editor)

  /* clear editor for a new file */
  editor->filename = nil;
  buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW (editor->text_view));
  gtk_text_buffer_set_text(buffer, "", -1);
  gtk_text_buffer_set_modified(buffer, FALSE);

  reset_default_status(editor);


proc on_open_menu_item_activate(menuItem: PGtkMenuItem,
                                TutorialTextEditor *editor) =
  gchar                   *filename;

  if check_for_save(editor):
    on_save_menu_item_activate(nil, editor)
  filename = get_open_filename(editor)
  if filename != nil: load_file(editor, filename)

proc on_save_menu_item_activate(menuItem: PGtkMenuItem, TutorialTextEditor *editor) =
  gchar                   *filename;
  if (editor->filename == nil)
  {
    filename = get_save_filename(editor);
    if (filename != nil) write_file(editor, filename);
  }
  else write_file(editor, nil);

proc on_save_as_menu_item_activate(GtkMenuItem *menuitem,
                                   TutorialTextEditor *editor) =
  gchar                   *filename;

  filename = get_save_filename(editor)
  if filename != nil: write_file(editor, filename)

proc on_quit_menu_item_activate(GtkMenuItem *menuitem, TutorialTextEditor *editor)
  if check_for_save(editor):
    on_save_menu_item_activate(nil, editor)
  gtk_main_quit()

proc on_cut_menu_item_activate(GtkMenuItem *menuitem, TutorialTextEditor *editor) =
  GtkTextBuffer           *buffer;
  GtkClipboard            *clipboard;

  clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  buffer = gtk_text_view_get_buffer(editor->text_view)
  gtk_text_buffer_cut_clipboard(buffer, clipboard, TRUE)

proc on_copy_menu_item_activate(GtkMenuItem *menuitem, TutorialTextEditor *editor) =
  GtkTextBuffer           *buffer;
  GtkClipboard            *clipboard;
  clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD)
  buffer = gtk_text_view_get_buffer(editor->text_view)
  gtk_text_buffer_copy_clipboard(buffer, clipboard)


proc on_paste_menu_item_activate(GtkMenuItem *menuitem, TutorialTextEditor *editor)
  GtkTextBuffer           *buffer;
  GtkClipboard            *clipboard;
  clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD)
  buffer = gtk_text_view_get_buffer(editor->text_view)
  gtk_text_buffer_paste_clipboard(buffer, clipboard, nil, TRUE)

proc on_delete_menu_item_activate(GtkMenuItem *menuitem, TutorialTextEditor *editor)
  GtkTextBuffer           *buffer;
  buffer = gtk_text_view_get_buffer(editor->text_view);
  gtk_text_buffer_delete_selection(buffer, FALSE, TRUE);
