{.deadCodeElim: on.}
import
  glib2

when defined(windows):
  const
    lib = "libatk-1.0-0.dll"
elif defined(macosx):
  const
    lib = "libatk-1.0.dylib"
else:
  const
    lib = "libatk-1.0.so"
type
  PImplementor* = pointer
  PAction* = pointer
  PComponent* = pointer
  PDocument* = pointer
  PEditableText* = pointer
  PHypertext* = pointer
  PImage* = pointer
  PSelection* = pointer
  PStreamableContent* = pointer
  PTable* = pointer
  PText* = pointer
  PValue* = pointer
  PRelationSet* = ptr TRelationSet
  PStateSet* = ptr TStateSet
  PAttributeSet* = ptr TAttributeSet
  PCoordType* = ptr TCoordType
  TCoordType* = enum
    XY_SCREEN, XY_WINDOW
  PRole* = ptr TRole
  TRole* = enum
    ROLE_INVALID, ROLE_ACCEL_LABEL, ROLE_ALERT, ROLE_ANIMATION, ROLE_ARROW,
    ROLE_CALENDAR, ROLE_CANVAS, ROLE_CHECK_BOX, ROLE_CHECK_MENU_ITEM,
    ROLE_COLOR_CHOOSER, ROLE_COLUMN_HEADER, ROLE_COMBO_BOX, ROLE_DATE_EDITOR,
    ROLE_DESKTOP_ICON, ROLE_DESKTOP_FRAME, ROLE_DIAL, ROLE_DIALOG,
    ROLE_DIRECTORY_PANE, ROLE_DRAWING_AREA, ROLE_FILE_CHOOSER, ROLE_FILLER,
    ROLE_FONT_CHOOSER, ROLE_FRAME, ROLE_GLASS_PANE, ROLE_HTML_CONTAINER,
    ROLE_ICON, ROLE_IMAGE, ROLE_INTERNAL_FRAME, ROLE_LABEL, ROLE_LAYERED_PANE,
    ROLE_LIST, ROLE_LIST_ITEM, ROLE_MENU, ROLE_MENU_BAR, ROLE_MENU_ITEM,
    ROLE_OPTION_PANE, ROLE_PAGE_TAB, ROLE_PAGE_TAB_LIST, ROLE_PANEL,
    ROLE_PASSWORD_TEXT, ROLE_POPUP_MENU, ROLE_PROGRESS_BAR, ROLE_PUSH_BUTTON,
    ROLE_RADIO_BUTTON, ROLE_RADIO_MENU_ITEM, ROLE_ROOT_PANE, ROLE_ROW_HEADER,
    ROLE_SCROLL_BAR, ROLE_SCROLL_PANE, ROLE_SEPARATOR, ROLE_SLIDER,
    ROLE_SPLIT_PANE, ROLE_SPIN_BUTTON, ROLE_STATUSBAR, ROLE_TABLE,
    ROLE_TABLE_CELL, ROLE_TABLE_COLUMN_HEADER, ROLE_TABLE_ROW_HEADER,
    ROLE_TEAR_OFF_MENU_ITEM, ROLE_TERMINAL, ROLE_TEXT, ROLE_TOGGLE_BUTTON,
    ROLE_TOOL_BAR, ROLE_TOOL_TIP, ROLE_TREE, ROLE_TREE_TABLE, ROLE_UNKNOWN,
    ROLE_VIEWPORT, ROLE_WINDOW, ROLE_LAST_DEFINED
  PLayer* = ptr TLayer
  TLayer* = enum
    LAYER_INVALID, LAYER_BACKGROUND, LAYER_CANVAS, LAYER_WIDGET, LAYER_MDI,
    LAYER_POPUP, LAYER_OVERLAY
  PPropertyValues* = ptr TPropertyValues
  TPropertyValues*{.final, pure.} = object
    property_name*: cstring
    old_value*: TGValue
    new_value*: TGValue

  TFunction* = proc (data: gpointer): gboolean{.cdecl.}
  PObject* = ptr TObject
  PPAtkObject* = ptr PObject
  TObject* = object of TGObject
    description*: cstring
    name*: cstring
    accessible_parent*: PObject
    role*: TRole
    relation_set*: PRelationSet
    layer*: TLayer

  TPropertyChangeHandler* = proc (para1: PObject, para2: PPropertyValues){.cdecl.}
  PObjectClass* = ptr TObjectClass
  TObjectClass* = object of TGObjectClass
    get_name*: proc (accessible: PObject): cstring{.cdecl.}
    get_description*: proc (accessible: PObject): cstring{.cdecl.}
    get_parent*: proc (accessible: PObject): PObject{.cdecl.}
    get_n_children*: proc (accessible: PObject): gint{.cdecl.}
    ref_child*: proc (accessible: PObject, i: gint): PObject{.cdecl.}
    get_index_in_parent*: proc (accessible: PObject): gint{.cdecl.}
    ref_relation_set*: proc (accessible: PObject): PRelationSet{.cdecl.}
    get_role*: proc (accessible: PObject): TRole{.cdecl.}
    get_layer*: proc (accessible: PObject): TLayer{.cdecl.}
    get_mdi_zorder*: proc (accessible: PObject): gint{.cdecl.}
    ref_state_set*: proc (accessible: PObject): PStateSet{.cdecl.}
    set_name*: proc (accessible: PObject, name: cstring){.cdecl.}
    set_description*: proc (accessible: PObject, description: cstring){.cdecl.}
    set_parent*: proc (accessible: PObject, parent: PObject){.cdecl.}
    set_role*: proc (accessible: PObject, role: TRole){.cdecl.}
    connect_property_change_handler*: proc (accessible: PObject,
        handler: TPropertyChangeHandler): guint{.cdecl.}
    remove_property_change_handler*: proc (accessible: PObject,
        handler_id: guint){.cdecl.}
    initialize*: proc (accessible: PObject, data: gpointer){.cdecl.}
    children_changed*: proc (accessible: PObject, change_index: guint,
                             changed_child: gpointer){.cdecl.}
    focus_event*: proc (accessible: PObject, focus_in: gboolean){.cdecl.}
    property_change*: proc (accessible: PObject, values: PPropertyValues){.cdecl.}
    state_change*: proc (accessible: PObject, name: cstring, state_set: gboolean){.
        cdecl.}
    visible_data_changed*: proc (accessible: PObject){.cdecl.}
    pad1*: TFunction
    pad2*: TFunction
    pad3*: TFunction
    pad4*: TFunction

  PImplementorIface* = ptr TImplementorIface
  TImplementorIface* = object of TGTypeInterface
    ref_accessible*: proc (implementor: PImplementor): PObject{.cdecl.}

  PActionIface* = ptr TActionIface
  TActionIface* = object of TGTypeInterface
    do_action*: proc (action: PAction, i: gint): gboolean{.cdecl.}
    get_n_actions*: proc (action: PAction): gint{.cdecl.}
    get_description*: proc (action: PAction, i: gint): cstring{.cdecl.}
    get_name*: proc (action: PAction, i: gint): cstring{.cdecl.}
    get_keybinding*: proc (action: PAction, i: gint): cstring{.cdecl.}
    set_description*: proc (action: PAction, i: gint, desc: cstring): gboolean{.
        cdecl.}
    pad1*: TFunction
    pad2*: TFunction

  TFocusHandler* = proc (para1: PObject, para2: gboolean){.cdecl.}
  PComponentIface* = ptr TComponentIface
  TComponentIface* = object of TGTypeInterface
    add_focus_handler*: proc (component: PComponent, handler: TFocusHandler): guint{.
        cdecl.}
    contains*: proc (component: PComponent, x: gint, y: gint,
                     coord_type: TCoordType): gboolean{.cdecl.}
    ref_accessible_at_point*: proc (component: PComponent, x: gint, y: gint,
                                    coord_type: TCoordType): PObject{.cdecl.}
    get_extents*: proc (component: PComponent, x: Pgint, y: Pgint, width: Pgint,
                        height: Pgint, coord_type: TCoordType){.cdecl.}
    get_position*: proc (component: PComponent, x: Pgint, y: Pgint,
                         coord_type: TCoordType){.cdecl.}
    get_size*: proc (component: PComponent, width: Pgint, height: Pgint){.cdecl.}
    grab_focus*: proc (component: PComponent): gboolean{.cdecl.}
    remove_focus_handler*: proc (component: PComponent, handler_id: guint){.
        cdecl.}
    set_extents*: proc (component: PComponent, x: gint, y: gint, width: gint,
                        height: gint, coord_type: TCoordType): gboolean{.cdecl.}
    set_position*: proc (component: PComponent, x: gint, y: gint,
                         coord_type: TCoordType): gboolean{.cdecl.}
    set_size*: proc (component: PComponent, width: gint, height: gint): gboolean{.
        cdecl.}
    get_layer*: proc (component: PComponent): TLayer{.cdecl.}
    get_mdi_zorder*: proc (component: PComponent): gint{.cdecl.}
    pad1*: TFunction
    pad2*: TFunction

  PDocumentIface* = ptr TDocumentIface
  TDocumentIface* = object of TGTypeInterface
    get_document_type*: proc (document: PDocument): cstring{.cdecl.}
    get_document*: proc (document: PDocument): gpointer{.cdecl.}
    pad1*: TFunction
    pad2*: TFunction
    pad3*: TFunction
    pad4*: TFunction
    pad5*: TFunction
    pad6*: TFunction
    pad7*: TFunction
    pad8*: TFunction

  PEditableTextIface* = ptr TEditableTextIface
  TEditableTextIface* = object of TGTypeInterface
    set_run_attributes*: proc (text: PEditableText, attrib_set: PAttributeSet,
                               start_offset: gint, end_offset: gint): gboolean{.
        cdecl.}
    set_text_contents*: proc (text: PEditableText, `string`: cstring){.cdecl.}
    insert_text*: proc (text: PEditableText, `string`: cstring, length: gint,
                        position: Pgint){.cdecl.}
    copy_text*: proc (text: PEditableText, start_pos: gint, end_pos: gint){.
        cdecl.}
    cut_text*: proc (text: PEditableText, start_pos: gint, end_pos: gint){.cdecl.}
    delete_text*: proc (text: PEditableText, start_pos: gint, end_pos: gint){.
        cdecl.}
    paste_text*: proc (text: PEditableText, position: gint){.cdecl.}
    pad1*: TFunction
    pad2*: TFunction

  PGObjectAccessible* = ptr TGObjectAccessible
  TGObjectAccessible* = object of TObject
  PGObjectAccessibleClass* = ptr TGObjectAccessibleClass
  TGObjectAccessibleClass* = object of TObjectClass
    pad5*: TFunction
    pad6*: TFunction

  PHyperlink* = ptr THyperlink
  THyperlink* = object of TGObject
  PHyperlinkClass* = ptr THyperlinkClass
  THyperlinkClass* = object of TGObjectClass
    get_uri*: proc (link: PHyperlink, i: gint): cstring{.cdecl.}
    get_object*: proc (link: PHyperlink, i: gint): PObject{.cdecl.}
    get_end_index*: proc (link: PHyperlink): gint{.cdecl.}
    get_start_index*: proc (link: PHyperlink): gint{.cdecl.}
    is_valid*: proc (link: PHyperlink): gboolean{.cdecl.}
    get_n_anchors*: proc (link: PHyperlink): gint{.cdecl.}
    pad7*: TFunction
    pad8*: TFunction
    pad9*: TFunction
    pad10*: TFunction

  PHypertextIface* = ptr THypertextIface
  THypertextIface* = object of TGTypeInterface
    get_link*: proc (hypertext: PHypertext, link_index: gint): PHyperlink{.cdecl.}
    get_n_links*: proc (hypertext: PHypertext): gint{.cdecl.}
    get_link_index*: proc (hypertext: PHypertext, char_index: gint): gint{.cdecl.}
    pad11*: TFunction
    pad12*: TFunction
    pad13*: TFunction
    pad14*: TFunction

  PImageIface* = ptr TImageIface
  TImageIface* = object of TGTypeInterface
    get_image_position*: proc (image: PImage, x: Pgint, y: Pgint,
                               coord_type: TCoordType){.cdecl.}
    get_image_description*: proc (image: PImage): cstring{.cdecl.}
    get_image_size*: proc (image: PImage, width: Pgint, height: Pgint){.cdecl.}
    set_image_description*: proc (image: PImage, description: cstring): gboolean{.
        cdecl.}
    pad15*: TFunction
    pad16*: TFunction

  PObjectFactory* = ptr TObjectFactory
  TObjectFactory* = object of TGObject
  PObjectFactoryClass* = ptr TObjectFactoryClass
  TObjectFactoryClass* = object of TGObjectClass
    create_accessible*: proc (obj: PGObject): PObject{.cdecl.}
    invalidate*: proc (factory: PObjectFactory){.cdecl.}
    get_accessible_type*: proc (): GType{.cdecl.}
    pad17*: TFunction
    pad18*: TFunction

  PRegistry* = ptr TRegistry
  TRegistry* = object of TGObject
    factory_type_registry*: PGHashTable
    factory_singleton_cache*: PGHashTable

  PRegistryClass* = ptr TRegistryClass
  TRegistryClass* = object of TGObjectClass
  PRelationType* = ptr TRelationType
  TRelationType* = enum
    RELATION_NULL, RELATION_CONTROLLED_BY, RELATION_CONTROLLER_FOR,
    RELATION_LABEL_FOR, RELATION_LABELLED_BY, RELATION_MEMBER_OF,
    RELATION_NODE_CHILD_OF, RELATION_LAST_DEFINED
  PRelation* = ptr TRelation
  PGPtrArray = pointer
  TRelation* = object of TGObject
    target*: PGPtrArray
    relationship*: TRelationType

  PRelationClass* = ptr TRelationClass
  TRelationClass* = object of TGObjectClass
  TRelationSet* = object of TGObject
    relations*: PGPtrArray

  PRelationSetClass* = ptr TRelationSetClass
  TRelationSetClass* = object of TGObjectClass
    pad19*: TFunction
    pad20*: TFunction

  PSelectionIface* = ptr TSelectionIface
  TSelectionIface* = object of TGTypeInterface
    add_selection*: proc (selection: PSelection, i: gint): gboolean{.cdecl.}
    clear_selection*: proc (selection: PSelection): gboolean{.cdecl.}
    ref_selection*: proc (selection: PSelection, i: gint): PObject{.cdecl.}
    get_selection_count*: proc (selection: PSelection): gint{.cdecl.}
    is_child_selected*: proc (selection: PSelection, i: gint): gboolean{.cdecl.}
    remove_selection*: proc (selection: PSelection, i: gint): gboolean{.cdecl.}
    select_all_selection*: proc (selection: PSelection): gboolean{.cdecl.}
    selection_changed*: proc (selection: PSelection){.cdecl.}
    pad1*: TFunction
    pad2*: TFunction

  PStateType* = ptr TStateType
  TStateType* = enum
    STATE_INVALID, STATE_ACTIVE, STATE_ARMED, STATE_BUSY, STATE_CHECKED,
    STATE_DEFUNCT, STATE_EDITABLE, STATE_ENABLED, STATE_EXPANDABLE,
    STATE_EXPANDED, STATE_FOCUSABLE, STATE_FOCUSED, STATE_HORIZONTAL,
    STATE_ICONIFIED, STATE_MODAL, STATE_MULTI_LINE, STATE_MULTISELECTABLE,
    STATE_OPAQUE, STATE_PRESSED, STATE_RESIZABLE, STATE_SELECTABLE,
    STATE_SELECTED, STATE_SENSITIVE, STATE_SHOWING, STATE_SINGLE_LINE,
    STATE_STALE, STATE_TRANSIENT, STATE_VERTICAL, STATE_VISIBLE,
    STATE_LAST_DEFINED
  PState* = ptr TState
  TState* = guint64
  TStateSet* = object of TGObject
  PStateSetClass* = ptr TStateSetClass
  TStateSetClass* = object of TGObjectClass
  PStreamableContentIface* = ptr TStreamableContentIface
  TStreamableContentIface* = object of TGTypeInterface
    get_n_mime_types*: proc (streamable: PStreamableContent): gint{.cdecl.}
    get_mime_type*: proc (streamable: PStreamableContent, i: gint): cstring{.
        cdecl.}
    get_stream*: proc (streamable: PStreamableContent, mime_type: cstring): PGIOChannel{.
        cdecl.}
    pad21*: TFunction
    pad22*: TFunction
    pad23*: TFunction
    pad24*: TFunction

  PTableIface* = ptr TTableIface
  TTableIface* = object of TGTypeInterface
    ref_at*: proc (table: PTable, row: gint, column: gint): PObject{.cdecl.}
    get_index_at*: proc (table: PTable, row: gint, column: gint): gint{.cdecl.}
    get_column_at_index*: proc (table: PTable, index: gint): gint{.cdecl.}
    get_row_at_index*: proc (table: PTable, index: gint): gint{.cdecl.}
    get_n_columns*: proc (table: PTable): gint{.cdecl.}
    get_n_rows*: proc (table: PTable): gint{.cdecl.}
    get_column_extent_at*: proc (table: PTable, row: gint, column: gint): gint{.
        cdecl.}
    get_row_extent_at*: proc (table: PTable, row: gint, column: gint): gint{.
        cdecl.}
    get_caption*: proc (table: PTable): PObject{.cdecl.}
    get_column_description*: proc (table: PTable, column: gint): cstring{.cdecl.}
    get_column_header*: proc (table: PTable, column: gint): PObject{.cdecl.}
    get_row_description*: proc (table: PTable, row: gint): cstring{.cdecl.}
    get_row_header*: proc (table: PTable, row: gint): PObject{.cdecl.}
    get_summary*: proc (table: PTable): PObject{.cdecl.}
    set_caption*: proc (table: PTable, caption: PObject){.cdecl.}
    set_column_description*: proc (table: PTable, column: gint,
                                   description: cstring){.cdecl.}
    set_column_header*: proc (table: PTable, column: gint, header: PObject){.
        cdecl.}
    set_row_description*: proc (table: PTable, row: gint, description: cstring){.
        cdecl.}
    set_row_header*: proc (table: PTable, row: gint, header: PObject){.cdecl.}
    set_summary*: proc (table: PTable, accessible: PObject){.cdecl.}
    get_selected_columns*: proc (table: PTable, selected: PPgint): gint{.cdecl.}
    get_selected_rows*: proc (table: PTable, selected: PPgint): gint{.cdecl.}
    is_column_selected*: proc (table: PTable, column: gint): gboolean{.cdecl.}
    is_row_selected*: proc (table: PTable, row: gint): gboolean{.cdecl.}
    is_selected*: proc (table: PTable, row: gint, column: gint): gboolean{.cdecl.}
    add_row_selection*: proc (table: PTable, row: gint): gboolean{.cdecl.}
    remove_row_selection*: proc (table: PTable, row: gint): gboolean{.cdecl.}
    add_column_selection*: proc (table: PTable, column: gint): gboolean{.cdecl.}
    remove_column_selection*: proc (table: PTable, column: gint): gboolean{.
        cdecl.}
    row_inserted*: proc (table: PTable, row: gint, num_inserted: gint){.cdecl.}
    column_inserted*: proc (table: PTable, column: gint, num_inserted: gint){.
        cdecl.}
    row_deleted*: proc (table: PTable, row: gint, num_deleted: gint){.cdecl.}
    column_deleted*: proc (table: PTable, column: gint, num_deleted: gint){.
        cdecl.}
    row_reordered*: proc (table: PTable){.cdecl.}
    column_reordered*: proc (table: PTable){.cdecl.}
    model_changed*: proc (table: PTable){.cdecl.}
    pad25*: TFunction
    pad26*: TFunction
    pad27*: TFunction
    pad28*: TFunction

  TAttributeSet* = TGSList
  PAttribute* = ptr TAttribute
  TAttribute*{.final, pure.} = object
    name*: cstring
    value*: cstring

  PTextAttribute* = ptr TTextAttribute
  TTextAttribute* = enum
    TEXT_ATTR_INVALID, TEXT_ATTR_LEFT_MARGIN, TEXT_ATTR_RIGHT_MARGIN,
    TEXT_ATTR_INDENT, TEXT_ATTR_INVISIBLE, TEXT_ATTR_EDITABLE,
    TEXT_ATTR_PIXELS_ABOVE_LINES, TEXT_ATTR_PIXELS_BELOW_LINES,
    TEXT_ATTR_PIXELS_INSIDE_WRAP, TEXT_ATTR_BG_FULL_HEIGHT, TEXT_ATTR_RISE,
    TEXT_ATTR_UNDERLINE, TEXT_ATTR_STRIKETHROUGH, TEXT_ATTR_SIZE,
    TEXT_ATTR_SCALE, TEXT_ATTR_WEIGHT, TEXT_ATTR_LANGUAGE,
    TEXT_ATTR_FAMILY_NAME, TEXT_ATTR_BG_COLOR, TEXT_ATTR_FG_COLOR,
    TEXT_ATTR_BG_STIPPLE, TEXT_ATTR_FG_STIPPLE, TEXT_ATTR_WRAP_MODE,
    TEXT_ATTR_DIRECTION, TEXT_ATTR_JUSTIFICATION, TEXT_ATTR_STRETCH,
    TEXT_ATTR_VARIANT, TEXT_ATTR_STYLE, TEXT_ATTR_LAST_DEFINED
  PTextBoundary* = ptr TTextBoundary
  TTextBoundary* = enum
    TEXT_BOUNDARY_CHAR, TEXT_BOUNDARY_WORD_START, TEXT_BOUNDARY_WORD_END,
    TEXT_BOUNDARY_SENTENCE_START, TEXT_BOUNDARY_SENTENCE_END,
    TEXT_BOUNDARY_LINE_START, TEXT_BOUNDARY_LINE_END
  PTextIface* = ptr TTextIface
  TTextIface* = object of TGTypeInterface
    get_text*: proc (text: PText, start_offset: gint, end_offset: gint): cstring{.
        cdecl.}
    get_text_after_offset*: proc (text: PText, offset: gint,
                                  boundary_type: TTextBoundary,
                                  start_offset: Pgint, end_offset: Pgint): cstring{.
        cdecl.}
    get_text_at_offset*: proc (text: PText, offset: gint,
                               boundary_type: TTextBoundary,
                               start_offset: Pgint, end_offset: Pgint): cstring{.
        cdecl.}
    get_character_at_offset*: proc (text: PText, offset: gint): gunichar{.cdecl.}
    get_text_before_offset*: proc (text: PText, offset: gint,
                                   boundary_type: TTextBoundary,
                                   start_offset: Pgint, end_offset: Pgint): cstring{.
        cdecl.}
    get_caret_offset*: proc (text: PText): gint{.cdecl.}
    get_run_attributes*: proc (text: PText, offset: gint, start_offset: Pgint,
                               end_offset: Pgint): PAttributeSet{.cdecl.}
    get_default_attributes*: proc (text: PText): PAttributeSet{.cdecl.}
    get_character_extents*: proc (text: PText, offset: gint, x: Pgint, y: Pgint,
                                  width: Pgint, height: Pgint,
                                  coords: TCoordType){.cdecl.}
    get_character_count*: proc (text: PText): gint{.cdecl.}
    get_offset_at_point*: proc (text: PText, x: gint, y: gint,
                                coords: TCoordType): gint{.cdecl.}
    get_n_selections*: proc (text: PText): gint{.cdecl.}
    get_selection*: proc (text: PText, selection_num: gint, start_offset: Pgint,
                          end_offset: Pgint): cstring{.cdecl.}
    add_selection*: proc (text: PText, start_offset: gint, end_offset: gint): gboolean{.
        cdecl.}
    remove_selection*: proc (text: PText, selection_num: gint): gboolean{.cdecl.}
    set_selection*: proc (text: PText, selection_num: gint, start_offset: gint,
                          end_offset: gint): gboolean{.cdecl.}
    set_caret_offset*: proc (text: PText, offset: gint): gboolean{.cdecl.}
    text_changed*: proc (text: PText, position: gint, length: gint){.cdecl.}
    text_caret_moved*: proc (text: PText, location: gint){.cdecl.}
    text_selection_changed*: proc (text: PText){.cdecl.}
    pad29*: TFunction
    pad30*: TFunction
    pad31*: TFunction
    pad32*: TFunction

  TEventListener* = proc (para1: PObject){.cdecl.}
  TEventListenerInitProc* = proc (){.cdecl.}
  TEventListenerInit* = proc (para1: TEventListenerInitProc){.cdecl.}
  PKeyEventStruct* = ptr TKeyEventStruct
  TKeyEventStruct*{.final, pure.} = object
    `type`*: gint
    state*: guint
    keyval*: guint
    length*: gint
    string*: cstring
    keycode*: guint16
    timestamp*: guint32

  TKeySnoopFunc* = proc (event: PKeyEventStruct, func_data: gpointer): gint{.
      cdecl.}
  PKeyEventType* = ptr TKeyEventType
  TKeyEventType* = enum
    KEY_EVENT_PRESS, KEY_EVENT_RELEASE, KEY_EVENT_LAST_DEFINED
  PUtil* = ptr TUtil
  TUtil* = object of TGObject
  PUtilClass* = ptr TUtilClass
  TUtilClass* = object of TGObjectClass
    add_global_event_listener*: proc (listener: TGSignalEmissionHook,
                                      event_type: cstring): guint{.cdecl.}
    remove_global_event_listener*: proc (listener_id: guint){.cdecl.}
    add_key_event_listener*: proc (listener: TKeySnoopFunc, data: gpointer): guint{.
        cdecl.}
    remove_key_event_listener*: proc (listener_id: guint){.cdecl.}
    get_root*: proc (): PObject{.cdecl.}
    get_toolkit_name*: proc (): cstring{.cdecl.}
    get_toolkit_version*: proc (): cstring{.cdecl.}

  PValueIface* = ptr TValueIface
  TValueIface* = object of TGTypeInterface
    get_current_value*: proc (obj: PValue, value: PGValue){.cdecl.}
    get_maximum_value*: proc (obj: PValue, value: PGValue){.cdecl.}
    get_minimum_value*: proc (obj: PValue, value: PGValue){.cdecl.}
    set_current_value*: proc (obj: PValue, value: PGValue): gboolean{.cdecl.}
    pad33*: TFunction
    pad34*: TFunction


proc role_register*(name: cstring): TRole{.cdecl, dynlib: lib,
    importc: "atk_role_register".}
proc object_get_type*(): GType{.cdecl, dynlib: lib,
                                importc: "atk_object_get_type".}
proc TYPE_OBJECT*(): GType
proc `OBJECT`*(obj: pointer): PObject
proc OBJECT_CLASS*(klass: pointer): PObjectClass
proc IS_OBJECT*(obj: pointer): bool
proc IS_OBJECT_CLASS*(klass: pointer): bool
proc OBJECT_GET_CLASS*(obj: pointer): PObjectClass
proc TYPE_IMPLEMENTOR*(): GType
proc IS_IMPLEMENTOR*(obj: pointer): bool
proc IMPLEMENTOR*(obj: pointer): PImplementor
proc IMPLEMENTOR_GET_IFACE*(obj: pointer): PImplementorIface
proc implementor_get_type*(): GType{.cdecl, dynlib: lib,
                                     importc: "atk_implementor_get_type".}
proc ref_accessible*(implementor: PImplementor): PObject{.cdecl,
    dynlib: lib, importc: "atk_implementor_ref_accessible".}
proc get_name*(accessible: PObject): cstring{.cdecl, dynlib: lib,
    importc: "atk_object_get_name".}
proc get_description*(accessible: PObject): cstring{.cdecl, dynlib: lib,
    importc: "atk_object_get_description".}
proc get_parent*(accessible: PObject): PObject{.cdecl, dynlib: lib,
    importc: "atk_object_get_parent".}
proc get_n_accessible_children*(accessible: PObject): gint{.cdecl,
    dynlib: lib, importc: "atk_object_get_n_accessible_children".}
proc ref_accessible_child*(accessible: PObject, i: gint): PObject{.cdecl,
    dynlib: lib, importc: "atk_object_ref_accessible_child".}
proc ref_relation_set*(accessible: PObject): PRelationSet{.cdecl,
    dynlib: lib, importc: "atk_object_ref_relation_set".}
proc get_role*(accessible: PObject): TRole{.cdecl, dynlib: lib,
    importc: "atk_object_get_role".}
proc get_layer*(accessible: PObject): TLayer{.cdecl, dynlib: lib,
    importc: "atk_object_get_layer".}
proc get_mdi_zorder*(accessible: PObject): gint{.cdecl, dynlib: lib,
    importc: "atk_object_get_mdi_zorder".}
proc ref_state_set*(accessible: PObject): PStateSet{.cdecl, dynlib: lib,
    importc: "atk_object_ref_state_set".}
proc get_index_in_parent*(accessible: PObject): gint{.cdecl, dynlib: lib,
    importc: "atk_object_get_index_in_parent".}
proc set_name*(accessible: PObject, name: cstring){.cdecl, dynlib: lib,
    importc: "atk_object_set_name".}
proc set_description*(accessible: PObject, description: cstring){.cdecl,
    dynlib: lib, importc: "atk_object_set_description".}
proc set_parent*(accessible: PObject, parent: PObject){.cdecl,
    dynlib: lib, importc: "atk_object_set_parent".}
proc set_role*(accessible: PObject, role: TRole){.cdecl, dynlib: lib,
    importc: "atk_object_set_role".}
proc connect_property_change_handler*(accessible: PObject,
    handler: TPropertyChangeHandler): guint{.cdecl, dynlib: lib,
    importc: "atk_object_connect_property_change_handler".}
proc remove_property_change_handler*(accessible: PObject,
    handler_id: guint){.cdecl, dynlib: lib,
                        importc: "atk_object_remove_property_change_handler".}
proc notify_state_change*(accessible: PObject, state: TState,
                                 value: gboolean){.cdecl, dynlib: lib,
    importc: "atk_object_notify_state_change".}
proc initialize*(accessible: PObject, data: gpointer){.cdecl,
    dynlib: lib, importc: "atk_object_initialize".}
proc role_get_name*(role: TRole): cstring{.cdecl, dynlib: lib,
    importc: "atk_role_get_name".}
proc role_for_name*(name: cstring): TRole{.cdecl, dynlib: lib,
    importc: "atk_role_for_name".}
proc TYPE_ACTION*(): GType
proc IS_ACTION*(obj: pointer): bool
proc ACTION*(obj: pointer): PAction
proc ACTION_GET_IFACE*(obj: pointer): PActionIface
proc action_get_type*(): GType{.cdecl, dynlib: lib,
                                importc: "atk_action_get_type".}
proc do_action*(action: PAction, i: gint): gboolean{.cdecl, dynlib: lib,
    importc: "atk_action_do_action".}
proc get_n_actions*(action: PAction): gint{.cdecl, dynlib: lib,
    importc: "atk_action_get_n_actions".}
proc get_description*(action: PAction, i: gint): cstring{.cdecl,
    dynlib: lib, importc: "atk_action_get_description".}
proc get_name*(action: PAction, i: gint): cstring{.cdecl, dynlib: lib,
    importc: "atk_action_get_name".}
proc get_keybinding*(action: PAction, i: gint): cstring{.cdecl,
    dynlib: lib, importc: "atk_action_get_keybinding".}
proc set_description*(action: PAction, i: gint, desc: cstring): gboolean{.
    cdecl, dynlib: lib, importc: "atk_action_set_description".}
proc TYPE_COMPONENT*(): GType
proc IS_COMPONENT*(obj: pointer): bool
proc COMPONENT*(obj: pointer): PComponent
proc COMPONENT_GET_IFACE*(obj: pointer): PComponentIface
proc component_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "atk_component_get_type".}
proc add_focus_handler*(component: PComponent, handler: TFocusHandler): guint{.
    cdecl, dynlib: lib, importc: "atk_component_add_focus_handler".}
proc contains*(component: PComponent, x, y: gint,
                         coord_type: TCoordType): gboolean{.cdecl, dynlib: lib,
    importc: "atk_component_contains".}
proc ref_accessible_at_point*(component: PComponent, x, y: gint,
                                        coord_type: TCoordType): PObject{.cdecl,
    dynlib: lib, importc: "atk_component_ref_accessible_at_point".}
proc get_extents*(component: PComponent, x, y, width, height: Pgint,
                            coord_type: TCoordType){.cdecl, dynlib: lib,
    importc: "atk_component_get_extents".}
proc get_position*(component: PComponent, x: Pgint, y: Pgint,
                             coord_type: TCoordType){.cdecl, dynlib: lib,
    importc: "atk_component_get_position".}
proc get_size*(component: PComponent, width: Pgint, height: Pgint){.
    cdecl, dynlib: lib, importc: "atk_component_get_size".}
proc get_layer*(component: PComponent): TLayer{.cdecl, dynlib: lib,
    importc: "atk_component_get_layer".}
proc get_mdi_zorder*(component: PComponent): gint{.cdecl, dynlib: lib,
    importc: "atk_component_get_mdi_zorder".}
proc grab_focus*(component: PComponent): gboolean{.cdecl, dynlib: lib,
    importc: "atk_component_grab_focus".}
proc remove_focus_handler*(component: PComponent, handler_id: guint){.
    cdecl, dynlib: lib, importc: "atk_component_remove_focus_handler".}
proc set_extents*(component: PComponent, x: gint, y: gint,
                            width: gint, height: gint, coord_type: TCoordType): gboolean{.
    cdecl, dynlib: lib, importc: "atk_component_set_extents".}
proc set_position*(component: PComponent, x: gint, y: gint,
                             coord_type: TCoordType): gboolean{.cdecl,
    dynlib: lib, importc: "atk_component_set_position".}
proc set_size*(component: PComponent, width: gint, height: gint): gboolean{.
    cdecl, dynlib: lib, importc: "atk_component_set_size".}
proc TYPE_DOCUMENT*(): GType
proc IS_DOCUMENT*(obj: pointer): bool
proc DOCUMENT*(obj: pointer): PDocument
proc DOCUMENT_GET_IFACE*(obj: pointer): PDocumentIface
proc document_get_type*(): GType{.cdecl, dynlib: lib,
                                  importc: "atk_document_get_type".}
proc get_document_type*(document: PDocument): cstring{.cdecl,
    dynlib: lib, importc: "atk_document_get_document_type".}
proc get_document*(document: PDocument): gpointer{.cdecl, dynlib: lib,
    importc: "atk_document_get_document".}
proc TYPE_EDITABLE_TEXT*(): GType
proc IS_EDITABLE_TEXT*(obj: pointer): bool
proc EDITABLE_TEXT*(obj: pointer): PEditableText
proc EDITABLE_TEXT_GET_IFACE*(obj: pointer): PEditableTextIface
proc editable_text_get_type*(): GType{.cdecl, dynlib: lib,
                                       importc: "atk_editable_text_get_type".}
proc set_run_attributes*(text: PEditableText,
                                       attrib_set: PAttributeSet,
                                       start_offset: gint, end_offset: gint): gboolean{.
    cdecl, dynlib: lib, importc: "atk_editable_text_set_run_attributes".}
proc set_text_contents*(text: PEditableText, string: cstring){.
    cdecl, dynlib: lib, importc: "atk_editable_text_set_text_contents".}
proc insert_text*(text: PEditableText, `string`: cstring,
                                length: gint, position: Pgint){.cdecl,
    dynlib: lib, importc: "atk_editable_text_insert_text".}
proc copy_text*(text: PEditableText, start_pos: gint,
                              end_pos: gint){.cdecl, dynlib: lib,
    importc: "atk_editable_text_copy_text".}
proc cut_text*(text: PEditableText, start_pos: gint, end_pos: gint){.
    cdecl, dynlib: lib, importc: "atk_editable_text_cut_text".}
proc delete_text*(text: PEditableText, start_pos: gint,
                                end_pos: gint){.cdecl, dynlib: lib,
    importc: "atk_editable_text_delete_text".}
proc paste_text*(text: PEditableText, position: gint){.cdecl,
    dynlib: lib, importc: "atk_editable_text_paste_text".}
proc TYPE_GOBJECT_ACCESSIBLE*(): GType
proc GOBJECT_ACCESSIBLE*(obj: pointer): PGObjectAccessible
proc GOBJECT_ACCESSIBLE_CLASS*(klass: pointer): PGObjectAccessibleClass
proc IS_GOBJECT_ACCESSIBLE*(obj: pointer): bool
proc IS_GOBJECT_ACCESSIBLE_CLASS*(klass: pointer): bool
proc GOBJECT_ACCESSIBLE_GET_CLASS*(obj: pointer): PGObjectAccessibleClass
proc gobject_accessible_get_type*(): GType{.cdecl, dynlib: lib,
    importc: "atk_gobject_accessible_get_type".}
proc accessible_for_object*(obj: PGObject): PObject{.cdecl, dynlib: lib,
    importc: "atk_gobject_accessible_for_object".}
proc get_object*(obj: PGObjectAccessible): PGObject{.cdecl,
    dynlib: lib, importc: "atk_gobject_accessible_get_object".}
proc TYPE_HYPERLINK*(): GType
proc HYPERLINK*(obj: pointer): PHyperlink
proc HYPERLINK_CLASS*(klass: pointer): PHyperlinkClass
proc IS_HYPERLINK*(obj: pointer): bool
proc IS_HYPERLINK_CLASS*(klass: pointer): bool
proc HYPERLINK_GET_CLASS*(obj: pointer): PHyperlinkClass
proc hyperlink_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "atk_hyperlink_get_type".}
proc get_uri*(link: PHyperlink, i: gint): cstring{.cdecl, dynlib: lib,
    importc: "atk_hyperlink_get_uri".}
proc get_object*(link: PHyperlink, i: gint): PObject{.cdecl,
    dynlib: lib, importc: "atk_hyperlink_get_object".}
proc get_end_index*(link: PHyperlink): gint{.cdecl, dynlib: lib,
    importc: "atk_hyperlink_get_end_index".}
proc get_start_index*(link: PHyperlink): gint{.cdecl, dynlib: lib,
    importc: "atk_hyperlink_get_start_index".}
proc is_valid*(link: PHyperlink): gboolean{.cdecl, dynlib: lib,
    importc: "atk_hyperlink_is_valid".}
proc get_n_anchors*(link: PHyperlink): gint{.cdecl, dynlib: lib,
    importc: "atk_hyperlink_get_n_anchors".}
proc TYPE_HYPERTEXT*(): GType
proc IS_HYPERTEXT*(obj: pointer): bool
proc HYPERTEXT*(obj: pointer): PHypertext
proc HYPERTEXT_GET_IFACE*(obj: pointer): PHypertextIface
proc hypertext_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "atk_hypertext_get_type".}
proc get_link*(hypertext: PHypertext, link_index: gint): PHyperlink{.
    cdecl, dynlib: lib, importc: "atk_hypertext_get_link".}
proc get_n_links*(hypertext: PHypertext): gint{.cdecl, dynlib: lib,
    importc: "atk_hypertext_get_n_links".}
proc get_link_index*(hypertext: PHypertext, char_index: gint): gint{.
    cdecl, dynlib: lib, importc: "atk_hypertext_get_link_index".}
proc TYPE_IMAGE*(): GType
proc IS_IMAGE*(obj: pointer): bool
proc IMAGE*(obj: pointer): PImage
proc IMAGE_GET_IFACE*(obj: pointer): PImageIface
proc image_get_type*(): GType{.cdecl, dynlib: lib, importc: "atk_image_get_type".}
proc get_image_description*(image: PImage): cstring{.cdecl, dynlib: lib,
    importc: "atk_image_get_image_description".}
proc get_image_size*(image: PImage, width: Pgint, height: Pgint){.cdecl,
    dynlib: lib, importc: "atk_image_get_image_size".}
proc set_image_description*(image: PImage, description: cstring): gboolean{.
    cdecl, dynlib: lib, importc: "atk_image_set_image_description".}
proc get_image_position*(image: PImage, x: Pgint, y: Pgint,
                               coord_type: TCoordType){.cdecl, dynlib: lib,
    importc: "atk_image_get_image_position".}
proc TYPE_OBJECT_FACTORY*(): GType
proc OBJECT_FACTORY*(obj: pointer): PObjectFactory
proc OBJECT_FACTORY_CLASS*(klass: pointer): PObjectFactoryClass
proc IS_OBJECT_FACTORY*(obj: pointer): bool
proc IS_OBJECT_FACTORY_CLASS*(klass: pointer): bool
proc OBJECT_FACTORY_GET_CLASS*(obj: pointer): PObjectFactoryClass
proc object_factory_get_type*(): GType{.cdecl, dynlib: lib,
                                        importc: "atk_object_factory_get_type".}
proc create_accessible*(factory: PObjectFactory, obj: PGObject): PObject{.
    cdecl, dynlib: lib, importc: "atk_object_factory_create_accessible".}
proc invalidate*(factory: PObjectFactory){.cdecl, dynlib: lib,
    importc: "atk_object_factory_invalidate".}
proc get_accessible_type*(factory: PObjectFactory): GType{.cdecl,
    dynlib: lib, importc: "atk_object_factory_get_accessible_type".}
proc TYPE_REGISTRY*(): GType
proc REGISTRY*(obj: pointer): PRegistry
proc REGISTRY_CLASS*(klass: pointer): PRegistryClass
proc IS_REGISTRY*(obj: pointer): bool
proc IS_REGISTRY_CLASS*(klass: pointer): bool
proc REGISTRY_GET_CLASS*(obj: pointer): PRegistryClass
proc registry_get_type*(): GType{.cdecl, dynlib: lib,
                                  importc: "atk_registry_get_type".}
proc set_factory_type*(registry: PRegistry, `type`: GType,
                                factory_type: GType){.cdecl, dynlib: lib,
    importc: "atk_registry_set_factory_type".}
proc get_factory_type*(registry: PRegistry, `type`: GType): GType{.
    cdecl, dynlib: lib, importc: "atk_registry_get_factory_type".}
proc get_factory*(registry: PRegistry, `type`: GType): PObjectFactory{.
    cdecl, dynlib: lib, importc: "atk_registry_get_factory".}
proc get_default_registry*(): PRegistry{.cdecl, dynlib: lib,
    importc: "atk_get_default_registry".}
proc TYPE_RELATION*(): GType
proc RELATION*(obj: pointer): PRelation
proc RELATION_CLASS*(klass: pointer): PRelationClass
proc IS_RELATION*(obj: pointer): bool
proc IS_RELATION_CLASS*(klass: pointer): bool
proc RELATION_GET_CLASS*(obj: pointer): PRelationClass
proc relation_get_type*(): GType{.cdecl, dynlib: lib,
                                  importc: "atk_relation_get_type".}
proc relation_type_register*(name: cstring): TRelationType{.cdecl, dynlib: lib,
    importc: "atk_relation_type_register".}
proc relation_type_get_name*(`type`: TRelationType): cstring{.cdecl,
    dynlib: lib, importc: "atk_relation_type_get_name".}
proc relation_type_for_name*(name: cstring): TRelationType{.cdecl, dynlib: lib,
    importc: "atk_relation_type_for_name".}
proc relation_new*(targets: PPAtkObject, n_targets: gint,
                   relationship: TRelationType): PRelation{.cdecl, dynlib: lib,
    importc: "atk_relation_new".}
proc get_relation_type*(relation: PRelation): TRelationType{.cdecl,
    dynlib: lib, importc: "atk_relation_get_relation_type".}
proc get_target*(relation: PRelation): PGPtrArray{.cdecl, dynlib: lib,
    importc: "atk_relation_get_target".}
proc TYPE_RELATION_SET*(): GType
proc RELATION_SET*(obj: pointer): PRelationSet
proc RELATION_SET_CLASS*(klass: pointer): PRelationSetClass
proc IS_RELATION_SET*(obj: pointer): bool
proc IS_RELATION_SET_CLASS*(klass: pointer): bool
proc RELATION_SET_GET_CLASS*(obj: pointer): PRelationSetClass
proc relation_set_get_type*(): GType{.cdecl, dynlib: lib,
                                      importc: "atk_relation_set_get_type".}
proc relation_set_new*(): PRelationSet{.cdecl, dynlib: lib,
                                        importc: "atk_relation_set_new".}
proc contains*(RelationSet: PRelationSet,
                            relationship: TRelationType): gboolean{.cdecl,
    dynlib: lib, importc: "atk_relation_set_contains".}
proc remove*(RelationSet: PRelationSet, relation: PRelation){.
    cdecl, dynlib: lib, importc: "atk_relation_set_remove".}
proc add*(RelationSet: PRelationSet, relation: PRelation){.cdecl,
    dynlib: lib, importc: "atk_relation_set_add".}
proc get_n_relations*(RelationSet: PRelationSet): gint{.cdecl,
    dynlib: lib, importc: "atk_relation_set_get_n_relations".}
proc get_relation*(RelationSet: PRelationSet, i: gint): PRelation{.
    cdecl, dynlib: lib, importc: "atk_relation_set_get_relation".}
proc get_relation_by_type*(RelationSet: PRelationSet,
                                        relationship: TRelationType): PRelation{.
    cdecl, dynlib: lib, importc: "atk_relation_set_get_relation_by_type".}
proc TYPE_SELECTION*(): GType
proc IS_SELECTION*(obj: pointer): bool
proc SELECTION*(obj: pointer): PSelection
proc SELECTION_GET_IFACE*(obj: pointer): PSelectionIface
proc selection_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "atk_selection_get_type".}
proc add_selection*(selection: PSelection, i: gint): gboolean{.cdecl,
    dynlib: lib, importc: "atk_selection_add_selection".}
proc clear_selection*(selection: PSelection): gboolean{.cdecl,
    dynlib: lib, importc: "atk_selection_clear_selection".}
proc ref_selection*(selection: PSelection, i: gint): PObject{.cdecl,
    dynlib: lib, importc: "atk_selection_ref_selection".}
proc get_selection_count*(selection: PSelection): gint{.cdecl,
    dynlib: lib, importc: "atk_selection_get_selection_count".}
proc is_child_selected*(selection: PSelection, i: gint): gboolean{.
    cdecl, dynlib: lib, importc: "atk_selection_is_child_selected".}
proc remove_selection*(selection: PSelection, i: gint): gboolean{.
    cdecl, dynlib: lib, importc: "atk_selection_remove_selection".}
proc select_all_selection*(selection: PSelection): gboolean{.cdecl,
    dynlib: lib, importc: "atk_selection_select_all_selection".}
proc state_type_register*(name: cstring): TStateType{.cdecl, dynlib: lib,
    importc: "atk_state_type_register".}
proc state_type_get_name*(`type`: TStateType): cstring{.cdecl, dynlib: lib,
    importc: "atk_state_type_get_name".}
proc state_type_for_name*(name: cstring): TStateType{.cdecl, dynlib: lib,
    importc: "atk_state_type_for_name".}
proc TYPE_STATE_SET*(): GType
proc STATE_SET*(obj: pointer): PStateSet
proc STATE_SET_CLASS*(klass: pointer): PStateSetClass
proc IS_STATE_SET*(obj: pointer): bool
proc IS_STATE_SET_CLASS*(klass: pointer): bool
proc STATE_SET_GET_CLASS*(obj: pointer): PStateSetClass
proc state_set_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "atk_state_set_get_type".}
proc state_set_new*(): PStateSet{.cdecl, dynlib: lib,
                                  importc: "atk_state_set_new".}
proc is_empty*(StateSet: PStateSet): gboolean{.cdecl, dynlib: lib,
    importc: "atk_state_set_is_empty".}
proc add_state*(StateSet: PStateSet, `type`: TStateType): gboolean{.
    cdecl, dynlib: lib, importc: "atk_state_set_add_state".}
proc add_states*(StateSet: PStateSet, types: PStateType, n_types: gint){.
    cdecl, dynlib: lib, importc: "atk_state_set_add_states".}
proc clear_states*(StateSet: PStateSet){.cdecl, dynlib: lib,
    importc: "atk_state_set_clear_states".}
proc contains_state*(StateSet: PStateSet, `type`: TStateType): gboolean{.
    cdecl, dynlib: lib, importc: "atk_state_set_contains_state".}
proc contains_states*(StateSet: PStateSet, types: PStateType,
                                n_types: gint): gboolean{.cdecl, dynlib: lib,
    importc: "atk_state_set_contains_states".}
proc remove_state*(StateSet: PStateSet, `type`: TStateType): gboolean{.
    cdecl, dynlib: lib, importc: "atk_state_set_remove_state".}
proc and_sets*(StateSet: PStateSet, compare_set: PStateSet): PStateSet{.
    cdecl, dynlib: lib, importc: "atk_state_set_and_sets".}
proc or_sets*(StateSet: PStateSet, compare_set: PStateSet): PStateSet{.
    cdecl, dynlib: lib, importc: "atk_state_set_or_sets".}
proc xor_sets*(StateSet: PStateSet, compare_set: PStateSet): PStateSet{.
    cdecl, dynlib: lib, importc: "atk_state_set_xor_sets".}
proc TYPE_STREAMABLE_CONTENT*(): GType
proc IS_STREAMABLE_CONTENT*(obj: pointer): bool
proc STREAMABLE_CONTENT*(obj: pointer): PStreamableContent
proc STREAMABLE_CONTENT_GET_IFACE*(obj: pointer): PStreamableContentIface
proc streamable_content_get_type*(): GType{.cdecl, dynlib: lib,
    importc: "atk_streamable_content_get_type".}
proc get_n_mime_types*(streamable: PStreamableContent): gint{.
    cdecl, dynlib: lib, importc: "atk_streamable_content_get_n_mime_types".}
proc get_mime_type*(streamable: PStreamableContent, i: gint): cstring{.
    cdecl, dynlib: lib, importc: "atk_streamable_content_get_mime_type".}
proc get_stream*(streamable: PStreamableContent,
                                    mime_type: cstring): PGIOChannel{.cdecl,
    dynlib: lib, importc: "atk_streamable_content_get_stream".}
proc TYPE_TABLE*(): GType
proc IS_TABLE*(obj: pointer): bool
proc TABLE*(obj: pointer): PTable
proc TABLE_GET_IFACE*(obj: pointer): PTableIface
proc table_get_type*(): GType{.cdecl, dynlib: lib, importc: "atk_table_get_type".}
proc ref_at*(table: PTable, row, column: gint): PObject{.cdecl,
    dynlib: lib, importc: "atk_table_ref_at".}
proc get_index_at*(table: PTable, row, column: gint): gint{.cdecl,
    dynlib: lib, importc: "atk_table_get_index_at".}
proc get_column_at_index*(table: PTable, index: gint): gint{.cdecl,
    dynlib: lib, importc: "atk_table_get_column_at_index".}
proc get_row_at_index*(table: PTable, index: gint): gint{.cdecl,
    dynlib: lib, importc: "atk_table_get_row_at_index".}
proc get_n_columns*(table: PTable): gint{.cdecl, dynlib: lib,
    importc: "atk_table_get_n_columns".}
proc get_n_rows*(table: PTable): gint{.cdecl, dynlib: lib,
    importc: "atk_table_get_n_rows".}
proc get_column_extent_at*(table: PTable, row: gint, column: gint): gint{.
    cdecl, dynlib: lib, importc: "atk_table_get_column_extent_at".}
proc get_row_extent_at*(table: PTable, row: gint, column: gint): gint{.
    cdecl, dynlib: lib, importc: "atk_table_get_row_extent_at".}
proc get_caption*(table: PTable): PObject{.cdecl, dynlib: lib,
    importc: "atk_table_get_caption".}
proc get_column_description*(table: PTable, column: gint): cstring{.cdecl,
    dynlib: lib, importc: "atk_table_get_column_description".}
proc get_column_header*(table: PTable, column: gint): PObject{.cdecl,
    dynlib: lib, importc: "atk_table_get_column_header".}
proc get_row_description*(table: PTable, row: gint): cstring{.cdecl,
    dynlib: lib, importc: "atk_table_get_row_description".}
proc get_row_header*(table: PTable, row: gint): PObject{.cdecl,
    dynlib: lib, importc: "atk_table_get_row_header".}
proc get_summary*(table: PTable): PObject{.cdecl, dynlib: lib,
    importc: "atk_table_get_summary".}
proc set_caption*(table: PTable, caption: PObject){.cdecl, dynlib: lib,
    importc: "atk_table_set_caption".}
proc set_column_description*(table: PTable, column: gint,
                                   description: cstring){.cdecl, dynlib: lib,
    importc: "atk_table_set_column_description".}
proc set_column_header*(table: PTable, column: gint, header: PObject){.
    cdecl, dynlib: lib, importc: "atk_table_set_column_header".}
proc set_row_description*(table: PTable, row: gint, description: cstring){.
    cdecl, dynlib: lib, importc: "atk_table_set_row_description".}
proc set_row_header*(table: PTable, row: gint, header: PObject){.cdecl,
    dynlib: lib, importc: "atk_table_set_row_header".}
proc set_summary*(table: PTable, accessible: PObject){.cdecl, dynlib: lib,
    importc: "atk_table_set_summary".}
proc get_selected_columns*(table: PTable, selected: PPgint): gint{.cdecl,
    dynlib: lib, importc: "atk_table_get_selected_columns".}
proc get_selected_rows*(table: PTable, selected: PPgint): gint{.cdecl,
    dynlib: lib, importc: "atk_table_get_selected_rows".}
proc is_column_selected*(table: PTable, column: gint): gboolean{.cdecl,
    dynlib: lib, importc: "atk_table_is_column_selected".}
proc is_row_selected*(table: PTable, row: gint): gboolean{.cdecl,
    dynlib: lib, importc: "atk_table_is_row_selected".}
proc is_selected*(table: PTable, row: gint, column: gint): gboolean{.
    cdecl, dynlib: lib, importc: "atk_table_is_selected".}
proc add_row_selection*(table: PTable, row: gint): gboolean{.cdecl,
    dynlib: lib, importc: "atk_table_add_row_selection".}
proc remove_row_selection*(table: PTable, row: gint): gboolean{.cdecl,
    dynlib: lib, importc: "atk_table_remove_row_selection".}
proc add_column_selection*(table: PTable, column: gint): gboolean{.cdecl,
    dynlib: lib, importc: "atk_table_add_column_selection".}
proc remove_column_selection*(table: PTable, column: gint): gboolean{.
    cdecl, dynlib: lib, importc: "atk_table_remove_column_selection".}
proc text_attribute_register*(name: cstring): TTextAttribute{.cdecl,
    dynlib: lib, importc: "atk_text_attribute_register".}
proc TYPE_TEXT*(): GType
proc IS_TEXT*(obj: pointer): bool
proc TEXT*(obj: pointer): PText
proc TEXT_GET_IFACE*(obj: pointer): PTextIface
proc text_get_type*(): GType{.cdecl, dynlib: lib, importc: "atk_text_get_type".}
proc get_text*(text: PText, start_offset: gint, end_offset: gint): cstring{.
    cdecl, dynlib: lib, importc: "atk_text_get_text".}
proc get_character_at_offset*(text: PText, offset: gint): gunichar{.cdecl,
    dynlib: lib, importc: "atk_text_get_character_at_offset".}
proc get_text_after_offset*(text: PText, offset: gint,
                                 boundary_type: TTextBoundary,
                                 start_offset: Pgint, end_offset: Pgint): cstring{.
    cdecl, dynlib: lib, importc: "atk_text_get_text_after_offset".}
proc get_text_at_offset*(text: PText, offset: gint,
                              boundary_type: TTextBoundary, start_offset: Pgint,
                              end_offset: Pgint): cstring{.cdecl, dynlib: lib,
    importc: "atk_text_get_text_at_offset".}
proc get_text_before_offset*(text: PText, offset: gint,
                                  boundary_type: TTextBoundary,
                                  start_offset: Pgint, end_offset: Pgint): cstring{.
    cdecl, dynlib: lib, importc: "atk_text_get_text_before_offset".}
proc get_caret_offset*(text: PText): gint{.cdecl, dynlib: lib,
    importc: "atk_text_get_caret_offset".}
proc get_character_extents*(text: PText, offset: gint, x: Pgint, y: Pgint,
                                 width: Pgint, height: Pgint, coords: TCoordType){.
    cdecl, dynlib: lib, importc: "atk_text_get_character_extents".}
proc get_run_attributes*(text: PText, offset: gint, start_offset: Pgint,
                              end_offset: Pgint): PAttributeSet{.cdecl,
    dynlib: lib, importc: "atk_text_get_run_attributes".}
proc get_default_attributes*(text: PText): PAttributeSet{.cdecl,
    dynlib: lib, importc: "atk_text_get_default_attributes".}
proc get_character_count*(text: PText): gint{.cdecl, dynlib: lib,
    importc: "atk_text_get_character_count".}
proc get_offset_at_point*(text: PText, x: gint, y: gint, coords: TCoordType): gint{.
    cdecl, dynlib: lib, importc: "atk_text_get_offset_at_point".}
proc get_n_selections*(text: PText): gint{.cdecl, dynlib: lib,
    importc: "atk_text_get_n_selections".}
proc get_selection*(text: PText, selection_num: gint, start_offset: Pgint,
                         end_offset: Pgint): cstring{.cdecl, dynlib: lib,
    importc: "atk_text_get_selection".}
proc add_selection*(text: PText, start_offset: gint, end_offset: gint): gboolean{.
    cdecl, dynlib: lib, importc: "atk_text_add_selection".}
proc remove_selection*(text: PText, selection_num: gint): gboolean{.cdecl,
    dynlib: lib, importc: "atk_text_remove_selection".}
proc set_selection*(text: PText, selection_num: gint, start_offset: gint,
                         end_offset: gint): gboolean{.cdecl, dynlib: lib,
    importc: "atk_text_set_selection".}
proc set_caret_offset*(text: PText, offset: gint): gboolean{.cdecl,
    dynlib: lib, importc: "atk_text_set_caret_offset".}
proc free*(attrib_set: PAttributeSet){.cdecl, dynlib: lib,
    importc: "atk_attribute_set_free".}
proc text_attribute_get_name*(attr: TTextAttribute): cstring{.cdecl,
    dynlib: lib, importc: "atk_text_attribute_get_name".}
proc text_attribute_for_name*(name: cstring): TTextAttribute{.cdecl,
    dynlib: lib, importc: "atk_text_attribute_for_name".}
proc text_attribute_get_value*(attr: TTextAttribute, index: gint): cstring{.
    cdecl, dynlib: lib, importc: "atk_text_attribute_get_value".}
proc TYPE_UTIL*(): GType
proc IS_UTIL*(obj: pointer): bool
proc UTIL*(obj: pointer): PUtil
proc UTIL_CLASS*(klass: pointer): PUtilClass
proc IS_UTIL_CLASS*(klass: pointer): bool
proc UTIL_GET_CLASS*(obj: pointer): PUtilClass
proc util_get_type*(): GType{.cdecl, dynlib: lib, importc: "atk_util_get_type".}
proc add_focus_tracker*(focus_tracker: TEventListener): guint{.cdecl,
    dynlib: lib, importc: "atk_add_focus_tracker".}
proc remove_focus_tracker*(tracker_id: guint){.cdecl, dynlib: lib,
    importc: "atk_remove_focus_tracker".}
proc focus_tracker_init*(add_function: TEventListenerInit){.cdecl, dynlib: lib,
    importc: "atk_focus_tracker_init".}
proc focus_tracker_notify*(anObject: PObject){.cdecl, dynlib: lib,
    importc: "atk_focus_tracker_notify".}
proc add_global_event_listener*(listener: TGSignalEmissionHook,
                                event_type: cstring): guint{.cdecl, dynlib: lib,
    importc: "atk_add_global_event_listener".}
proc remove_global_event_listener*(listener_id: guint){.cdecl, dynlib: lib,
    importc: "atk_remove_global_event_listener".}
proc add_key_event_listener*(listener: TKeySnoopFunc, data: gpointer): guint{.
    cdecl, dynlib: lib, importc: "atk_add_key_event_listener".}
proc remove_key_event_listener*(listener_id: guint){.cdecl, dynlib: lib,
    importc: "atk_remove_key_event_listener".}
proc get_root*(): PObject{.cdecl, dynlib: lib, importc: "atk_get_root".}
proc get_toolkit_name*(): cstring{.cdecl, dynlib: lib,
                                   importc: "atk_get_toolkit_name".}
proc get_toolkit_version*(): cstring{.cdecl, dynlib: lib,
                                      importc: "atk_get_toolkit_version".}
proc TYPE_VALUE*(): GType
proc IS_VALUE*(obj: pointer): bool
proc VALUE*(obj: pointer): PValue
proc VALUE_GET_IFACE*(obj: pointer): PValueIface
proc value_get_type*(): GType{.cdecl, dynlib: lib, importc: "atk_value_get_type".}
proc get_current_value*(obj: PValue, value: PGValue){.cdecl, dynlib: lib,
    importc: "atk_value_get_current_value".}
proc get_maximum_value*(obj: PValue, value: PGValue){.cdecl, dynlib: lib,
    importc: "atk_value_get_maximum_value".}
proc get_minimum_value*(obj: PValue, value: PGValue){.cdecl, dynlib: lib,
    importc: "atk_value_get_minimum_value".}
proc set_current_value*(obj: PValue, value: PGValue): gboolean{.cdecl,
    dynlib: lib, importc: "atk_value_set_current_value".}
proc TYPE_OBJECT*(): GType =
  result = object_get_type()

proc `OBJECT`*(obj: pointer): PObject =
  result = cast[PObject](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_OBJECT()))

proc OBJECT_CLASS*(klass: pointer): PObjectClass =
  result = cast[PObjectClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_OBJECT()))

proc IS_OBJECT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_OBJECT())

proc IS_OBJECT_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_OBJECT())

proc OBJECT_GET_CLASS*(obj: pointer): PObjectClass =
  result = cast[PObjectClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_OBJECT()))

proc TYPE_IMPLEMENTOR*(): GType =
  result = implementor_get_type()

proc IS_IMPLEMENTOR*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_IMPLEMENTOR())

proc IMPLEMENTOR*(obj: pointer): PImplementor =
  result = PImplementor(G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_IMPLEMENTOR()))

proc IMPLEMENTOR_GET_IFACE*(obj: pointer): PImplementorIface =
  result = cast[PImplementorIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      TYPE_IMPLEMENTOR()))

proc TYPE_ACTION*(): GType =
  result = action_get_type()

proc IS_ACTION*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_ACTION())

proc ACTION*(obj: pointer): PAction =
  result = PAction(G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_ACTION()))

proc ACTION_GET_IFACE*(obj: pointer): PActionIface =
  result = cast[PActionIface](G_TYPE_INSTANCE_GET_INTERFACE(obj, TYPE_ACTION()))

proc TYPE_COMPONENT*(): GType =
  result = component_get_type()

proc IS_COMPONENT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_COMPONENT())

proc COMPONENT*(obj: pointer): PComponent =
  result = PComponent(G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_COMPONENT()))

proc COMPONENT_GET_IFACE*(obj: pointer): PComponentIface =
  result = cast[PComponentIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      TYPE_COMPONENT()))

proc TYPE_DOCUMENT*(): GType =
  result = document_get_type()

proc IS_DOCUMENT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_DOCUMENT())

proc DOCUMENT*(obj: pointer): PDocument =
  result = cast[PDocument](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_DOCUMENT()))

proc DOCUMENT_GET_IFACE*(obj: pointer): PDocumentIface =
  result = cast[PDocumentIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      TYPE_DOCUMENT()))

proc TYPE_EDITABLE_TEXT*(): GType =
  result = editable_text_get_type()

proc IS_EDITABLE_TEXT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_EDITABLE_TEXT())

proc EDITABLE_TEXT*(obj: pointer): PEditableText =
  result = cast[PEditableText](G_TYPE_CHECK_INSTANCE_CAST(obj,
      TYPE_EDITABLE_TEXT()))

proc EDITABLE_TEXT_GET_IFACE*(obj: pointer): PEditableTextIface =
  result = cast[PEditableTextIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      TYPE_EDITABLE_TEXT()))

proc TYPE_GOBJECT_ACCESSIBLE*(): GType =
  result = gobject_accessible_get_type()

proc GOBJECT_ACCESSIBLE*(obj: pointer): PGObjectAccessible =
  result = cast[PGObjectAccessible](G_TYPE_CHECK_INSTANCE_CAST(obj,
      TYPE_GOBJECT_ACCESSIBLE()))

proc GOBJECT_ACCESSIBLE_CLASS*(klass: pointer): PGObjectAccessibleClass =
  result = cast[PGObjectAccessibleClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_GOBJECT_ACCESSIBLE()))

proc IS_GOBJECT_ACCESSIBLE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_GOBJECT_ACCESSIBLE())

proc IS_GOBJECT_ACCESSIBLE_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_GOBJECT_ACCESSIBLE())

proc GOBJECT_ACCESSIBLE_GET_CLASS*(obj: pointer): PGObjectAccessibleClass =
  result = cast[PGObjectAccessibleClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_GOBJECT_ACCESSIBLE()))

proc TYPE_HYPERLINK*(): GType =
  result = hyperlink_get_type()

proc HYPERLINK*(obj: pointer): PHyperlink =
  result = cast[PHyperlink](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_HYPERLINK()))

proc HYPERLINK_CLASS*(klass: pointer): PHyperlinkClass =
  result = cast[PHyperlinkClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_HYPERLINK()))

proc IS_HYPERLINK*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_HYPERLINK())

proc IS_HYPERLINK_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_HYPERLINK())

proc HYPERLINK_GET_CLASS*(obj: pointer): PHyperlinkClass =
  result = cast[PHyperlinkClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_HYPERLINK()))

proc TYPE_HYPERTEXT*(): GType =
  result = hypertext_get_type()

proc IS_HYPERTEXT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_HYPERTEXT())

proc HYPERTEXT*(obj: pointer): PHypertext =
  result = cast[PHypertext](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_HYPERTEXT()))

proc HYPERTEXT_GET_IFACE*(obj: pointer): PHypertextIface =
  result = cast[PHypertextIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      TYPE_HYPERTEXT()))

proc TYPE_IMAGE*(): GType =
  result = image_get_type()

proc IS_IMAGE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_IMAGE())

proc IMAGE*(obj: pointer): PImage =
  result = cast[PImage](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_IMAGE()))

proc IMAGE_GET_IFACE*(obj: pointer): PImageIface =
  result = cast[PImageIface](G_TYPE_INSTANCE_GET_INTERFACE(obj, TYPE_IMAGE()))

proc TYPE_OBJECT_FACTORY*(): GType =
  result = object_factory_get_type()

proc OBJECT_FACTORY*(obj: pointer): PObjectFactory =
  result = cast[PObjectFactory](G_TYPE_CHECK_INSTANCE_CAST(obj,
      TYPE_OBJECT_FACTORY()))

proc OBJECT_FACTORY_CLASS*(klass: pointer): PObjectFactoryClass =
  result = cast[PObjectFactoryClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_OBJECT_FACTORY()))

proc IS_OBJECT_FACTORY*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_OBJECT_FACTORY())

proc IS_OBJECT_FACTORY_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_OBJECT_FACTORY())

proc OBJECT_FACTORY_GET_CLASS*(obj: pointer): PObjectFactoryClass =
  result = cast[PObjectFactoryClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_OBJECT_FACTORY()))

proc TYPE_REGISTRY*(): GType =
  result = registry_get_type()

proc REGISTRY*(obj: pointer): PRegistry =
  result = cast[PRegistry](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_REGISTRY()))

proc REGISTRY_CLASS*(klass: pointer): PRegistryClass =
  result = cast[PRegistryClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_REGISTRY()))

proc IS_REGISTRY*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_REGISTRY())

proc IS_REGISTRY_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_REGISTRY())

proc REGISTRY_GET_CLASS*(obj: pointer): PRegistryClass =
  result = cast[PRegistryClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_REGISTRY()))

proc TYPE_RELATION*(): GType =
  result = relation_get_type()

proc RELATION*(obj: pointer): PRelation =
  result = cast[PRelation](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_RELATION()))

proc RELATION_CLASS*(klass: pointer): PRelationClass =
  result = cast[PRelationClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_RELATION()))

proc IS_RELATION*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_RELATION())

proc IS_RELATION_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_RELATION())

proc RELATION_GET_CLASS*(obj: pointer): PRelationClass =
  result = cast[PRelationClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_RELATION()))

proc TYPE_RELATION_SET*(): GType =
  result = relation_set_get_type()

proc RELATION_SET*(obj: pointer): PRelationSet =
  result = cast[PRelationSet](G_TYPE_CHECK_INSTANCE_CAST(obj,
      TYPE_RELATION_SET()))

proc RELATION_SET_CLASS*(klass: pointer): PRelationSetClass =
  result = cast[PRelationSetClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_RELATION_SET()))

proc IS_RELATION_SET*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_RELATION_SET())

proc IS_RELATION_SET_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_RELATION_SET())

proc RELATION_SET_GET_CLASS*(obj: pointer): PRelationSetClass =
  result = cast[PRelationSetClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_RELATION_SET()))

proc TYPE_SELECTION*(): GType =
  result = selection_get_type()

proc IS_SELECTION*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_SELECTION())

proc SELECTION*(obj: pointer): PSelection =
  result = cast[PSelection](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_SELECTION()))

proc SELECTION_GET_IFACE*(obj: pointer): PSelectionIface =
  result = cast[PSelectionIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      TYPE_SELECTION()))

proc TYPE_STATE_SET*(): GType =
  result = state_set_get_type()

proc STATE_SET*(obj: pointer): PStateSet =
  result = cast[PStateSet](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_STATE_SET()))

proc STATE_SET_CLASS*(klass: pointer): PStateSetClass =
  result = cast[PStateSetClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_STATE_SET()))

proc IS_STATE_SET*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_STATE_SET())

proc IS_STATE_SET_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_STATE_SET())

proc STATE_SET_GET_CLASS*(obj: pointer): PStateSetClass =
  result = cast[PStateSetClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_STATE_SET()))

proc TYPE_STREAMABLE_CONTENT*(): GType =
  result = streamable_content_get_type()

proc IS_STREAMABLE_CONTENT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_STREAMABLE_CONTENT())

proc STREAMABLE_CONTENT*(obj: pointer): PStreamableContent =
  result = cast[PStreamableContent](G_TYPE_CHECK_INSTANCE_CAST(obj,
      TYPE_STREAMABLE_CONTENT()))

proc STREAMABLE_CONTENT_GET_IFACE*(obj: pointer): PStreamableContentIface =
  result = cast[PStreamableContentIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      TYPE_STREAMABLE_CONTENT()))

proc TYPE_TABLE*(): GType =
  result = table_get_type()

proc IS_TABLE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_TABLE())

proc TABLE*(obj: pointer): PTable =
  result = cast[PTable](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_TABLE()))

proc TABLE_GET_IFACE*(obj: pointer): PTableIface =
  result = cast[PTableIface](G_TYPE_INSTANCE_GET_INTERFACE(obj, TYPE_TABLE()))

proc TYPE_TEXT*(): GType =
  result = text_get_type()

proc IS_TEXT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_TEXT())

proc TEXT*(obj: pointer): PText =
  result = cast[PText](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_TEXT()))

proc TEXT_GET_IFACE*(obj: pointer): PTextIface =
  result = cast[PTextIface](G_TYPE_INSTANCE_GET_INTERFACE(obj, TYPE_TEXT()))

proc TYPE_UTIL*(): GType =
  result = util_get_type()

proc IS_UTIL*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_UTIL())

proc UTIL*(obj: pointer): PUtil =
  result = cast[PUtil](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_UTIL()))

proc UTIL_CLASS*(klass: pointer): PUtilClass =
  result = cast[PUtilClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_UTIL()))

proc IS_UTIL_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_UTIL())

proc UTIL_GET_CLASS*(obj: pointer): PUtilClass =
  result = cast[PUtilClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_UTIL()))

proc TYPE_VALUE*(): GType =
  result = value_get_type()

proc IS_VALUE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_VALUE())

proc VALUE*(obj: pointer): PValue =
  result = cast[PValue](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_VALUE()))

proc VALUE_GET_IFACE*(obj: pointer): PValueIface =
  result = cast[PValueIface](G_TYPE_INSTANCE_GET_INTERFACE(obj, TYPE_VALUE()))
