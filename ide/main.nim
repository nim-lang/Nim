
import glib2, gtk2, libglade2
 
proc on_window_destroy(obj: PGtkObject, data: pointer) {.exportc, cdecl.} =
  gtk_main_quit()
 
const
  GuiTemplate = "/media/hda4/nimrod/ide/nimide.glade"
 
type
  TMyTextEditor = record
    window: PGtkWindow
    statusbar: PGtkStatusBar
    textview: PGtkTextview
    statusbarContextId: int
    filename: string

proc error_message(msg: string) = 
  var
    dialog: PGtkDialog
  dialog = GTK_DIALOG(gtk_message_dialog_new(nil, 
              GTK_DIALOG_MODAL or GTK_DIALOG_DESTROY_WITH_PARENT,
              GTK_MESSAGE_ERROR, GTK_BUTTONS_OK, msg))
  
  gtk_window_set_title(dialog, "Error!")
  gtk_dialog_run(dialog)
  gtk_widget_destroy(dialog)


proc get_open_filename(e: TMyTextEditor): string =
  var
    chooser: PGtkDialog                
  chooser = gtk_file_chooser_dialog_new("Open File...", e.window,
              GTK_FILE_CHOOSER_ACTION_OPEN,
              GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
              GTK_STOCK_OPEN, GTK_RESPONSE_OK, nil)
                                               
  if gtk_dialog_run(chooser) == GTK_RESPONSE_OK:
    result = $gtk_file_chooser_get_filename(chooser)
  else:
    result = ""        
  gtk_widget_destroy(chooser)

  
proc get_save_filename(e: TMyTextEditor): string = 
  var
    chooser: PGtkDialog                
  chooser = gtk_file_chooser_dialog_new("Save File...", e.window,
              GTK_FILE_CHOOSER_ACTION_SAVE,
              GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
              GTK_STOCK_OPEN, GTK_RESPONSE_OK, nil)
                                               
  if gtk_dialog_run(chooser) == GTK_RESPONSE_OK:
    result = $gtk_file_chooser_get_filename(chooser)
  else:
    result = ""        
  gtk_widget_destroy(chooser)
  
proc load_file(e: var TMyTextEditor, filename: string) =
  var 
    err: ptr GError
    status: cstring
    text: cstring
    result: bool
    buffer: PGtkTextBuffer
  gtk_statusbar_push(e.statusbar, e.statusbar_context_id, "Loading...")
  while gtk_events_pending(): gtk_main_iteration()
  
  # get the file contents
  result = g_file_get_contents(filename, addr(text), nil, addr(err))
  if not result:
    error_message("Cannot load file")
    g_error_free(err)
  
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
                           cast[TGCallback](on_window_destroy))
  
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

  gtk_nimrod_init()  
  initApp(editor)
  gtk_widget_show(editor.window)
  gtk_main()

main()


proc reset_default_status(e: var TMyTextEditor)
  gchar           *file;
  gchar           *status;
  
  if e.filename == "":
    file = g_strdup("(UNTITLED)")
  else:
    file = g_path_get_basename(editor->filename)
  
  status = g_strdup_printf("File: %s", file)
  gtk_statusbar_pop(e.statusbar,
                    e.statusbar_context_id)
  gtk_statusbar_push(e.statusbar,
                     e.statusbar_context_id, status)
  g_free(status)
  g_free(file)

        
gboolean
check_for_save(e: var TMyTextEditor)
  gboolean                ret = FALSE;
  GtkTextBuffer           *buffer;  
  buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (editor->text_view));
  if (gtk_text_buffer_get_modified (buffer) == TRUE)
  {
    GtkWidget       *dialog;
    const gchar *msg  = "Do you want to save the changes you have made?";
    dialog = gtk_message_dialog_new (NULL, 
                                     GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
                                     GTK_MESSAGE_QUESTION,
                                     GTK_BUTTONS_YES_NO,
                                     msg);
    gtk_window_set_title (GTK_WINDOW (dialog), "Save?");
    if (gtk_dialog_run (GTK_DIALOG (dialog)) == GTK_RESPONSE_NO)
    {
      ret = FALSE;
    } else ret = TRUE;
    gtk_widget_destroy (dialog);      
  }     
  return ret;


/*
When the window is requested to be closed, we need to check if they have 
unsaved work. We use this callback to prompt the user to save their work before
they exit the application. From the "delete-event" signal, we can choose to
effectively cancel the close based on the value we return.
*/
gboolean 
on_window_delete_event(GtkWidget *widget, GdkEvent *event, 
                       TutorialTextEditor *editor)
{
  if (check_for_save (editor) == TRUE)
    on_save_menu_item_activate (NULL, editor);  
  return FALSE;   /* propogate event */
}

/*
Called when the user clicks the 'New' menu. We need to prompt for save if the
file has been modified, and then delete the buffer and clear the modified flag.
*/
void on_new_menu_item_activate (GtkMenuItem *menuitem, TutorialTextEditor *editor)
{
        GtkTextBuffer           *buffer;
        
        if (check_for_save (editor) == TRUE)
        {
              on_save_menu_item_activate (NULL, editor);  
        }
        
        /* clear editor for a new file */
        editor->filename = NULL;
        buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (editor->text_view));
        gtk_text_buffer_set_text (buffer, "", -1);
        gtk_text_buffer_set_modified (buffer, FALSE);
        
        reset_default_status (editor);
}

/*
Called when the user clicks the 'Open' menu. We need to prompt for save if the
file has been modified, allow the user to choose a file to open, and then call
load_file() on that file.
*/
void on_open_menu_item_activate (GtkMenuItem *menuitem, TutorialTextEditor *editor)
{
        gchar                   *filename;
        
        if (check_for_save (editor) == TRUE)
        {
              on_save_menu_item_activate (NULL, editor);  
        }
        
        filename = get_open_filename (editor);
        if (filename != NULL) load_file (editor, filename); 
}

/*
Called when the user clicks the 'Save' menu. We need to allow the user to choose 
a file to save if it's an untitled document, and then call write_file() on that 
file.
*/
void on_save_menu_item_activate (GtkMenuItem *menuitem, TutorialTextEditor *editor)
{
        gchar                   *filename;
        
        if (editor->filename == NULL) 
        {
                filename = get_save_filename (editor);
                if (filename != NULL) write_file (editor, filename); 
        }
        else write_file (editor, NULL);
        
}

/*
Called when the user clicks the 'Save As' menu. We need to allow the user to 
choose a file to save and then call write_file() on that file.
*/
void on_save_as_menu_item_activate (GtkMenuItem *menuitem, TutorialTextEditor *editor)
{
        gchar                   *filename;
        
        filename = get_save_filename (editor);
        if (filename != NULL) write_file (editor, filename); 
}

/*
Called when the user clicks the 'Quit' menu. We need to prompt for save if the
file has been modified and then break out of the GTK+ main loop.
*/
void on_quit_menu_item_activate (GtkMenuItem *menuitem, TutorialTextEditor *editor)
{
        if (check_for_save (editor) == TRUE)
        {
              on_save_menu_item_activate (NULL, editor);  
        }
        gtk_main_quit();
}

/*
Called when the user clicks the 'Cut' menu. 
*/
void on_cut_menu_item_activate (GtkMenuItem *menuitem, TutorialTextEditor *editor)
{
        GtkTextBuffer           *buffer;
        GtkClipboard            *clipboard;
        
        clipboard = gtk_clipboard_get (GDK_SELECTION_CLIPBOARD);
        buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (editor->text_view));
        gtk_text_buffer_cut_clipboard (buffer, clipboard, TRUE);
}

/*
Called when the user clicks the 'Copy' menu. 
*/
void on_copy_menu_item_activate (GtkMenuItem *menuitem, TutorialTextEditor *editor)
{
        GtkTextBuffer           *buffer;
        GtkClipboard            *clipboard;
        
        clipboard = gtk_clipboard_get (GDK_SELECTION_CLIPBOARD);
        buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (editor->text_view));
        gtk_text_buffer_copy_clipboard (buffer, clipboard);
}

/*
Called when the user clicks the 'Paste' menu. 
*/
void on_paste_menu_item_activate (GtkMenuItem *menuitem, TutorialTextEditor *editor)
{
        GtkTextBuffer           *buffer;
        GtkClipboard            *clipboard;
        clipboard = gtk_clipboard_get (GDK_SELECTION_CLIPBOARD);
        buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (editor->text_view));
        gtk_text_buffer_paste_clipboard (buffer, clipboard, NULL, TRUE);
}

/*
Called when the user clicks the 'Delete' menu. 
*/
void on_delete_menu_item_activate (GtkMenuItem *menuitem, TutorialTextEditor *editor)
{
        GtkTextBuffer           *buffer;
        buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (editor->text_view));
        gtk_text_buffer_delete_selection (buffer, FALSE, TRUE);
}

void on_about_menu_item_activate (GtkMenuItem *menuitem, TutorialTextEditor *editor)
{
  static const gchar * const authors[] = {
		"Micah Carrick <email@micahcarrick.com>",
		NULL
	};
	static const gchar copyright[] = "Copyright \xc2\xa9 2008 Andreas Rumpf";
	static const gchar comments[] = "GTK+ and Glade3 GUI Programming Tutorial";
	gtk_show_about_dialog (e.window,
	  "authors", authors,
	  "comments", comments,
	  "copyright", copyright,
		"version", "0.1",
		"website", "http://www.micahcarrick.com",
		"program-name", "GTK+ Text Editor",
		"logo-icon-name", GTK_STOCK_EDIT, nil) 
}
