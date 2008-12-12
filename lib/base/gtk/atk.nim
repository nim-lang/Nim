import
  glib2

when defined(windows):
  const
    atklib = "libatk-1.0-0.dll"
else:
  const
    atklib = "libatk-1.0.so"
type
  PAtkImplementor* = pointer
  PAtkAction* = pointer
  PAtkComponent* = pointer
  PAtkDocument* = pointer
  PAtkEditableText* = pointer
  PAtkHypertext* = pointer
  PAtkImage* = pointer
  PAtkSelection* = pointer
  PAtkStreamableContent* = pointer
  PAtkTable* = pointer
  PAtkText* = pointer
  PAtkValue* = pointer
  PAtkRelationSet* = ptr TAtkRelationSet
  PAtkStateSet* = ptr TAtkStateSet
  PAtkAttributeSet* = ptr TAtkAttributeSet
  PAtkCoordType* = ptr TAtkCoordType
  TAtkCoordType* = enum
    ATK_XY_SCREEN, ATK_XY_WINDOW
  PAtkRole* = ptr TAtkRole
  TAtkRole* = enum
    ATK_ROLE_INVALID, ATK_ROLE_ACCEL_LABEL, ATK_ROLE_ALERT, ATK_ROLE_ANIMATION,
    ATK_ROLE_ARROW, ATK_ROLE_CALENDAR, ATK_ROLE_CANVAS, ATK_ROLE_CHECK_BOX,
    ATK_ROLE_CHECK_MENU_ITEM, ATK_ROLE_COLOR_CHOOSER, ATK_ROLE_COLUMN_HEADER,
    ATK_ROLE_COMBO_BOX, ATK_ROLE_DATE_EDITOR, ATK_ROLE_DESKTOP_ICON,
    ATK_ROLE_DESKTOP_FRAME, ATK_ROLE_DIAL, ATK_ROLE_DIALOG,
    ATK_ROLE_DIRECTORY_PANE, ATK_ROLE_DRAWING_AREA, ATK_ROLE_FILE_CHOOSER,
    ATK_ROLE_FILLER, ATK_ROLE_FONT_CHOOSER, ATK_ROLE_FRAME, ATK_ROLE_GLASS_PANE,
    ATK_ROLE_HTML_CONTAINER, ATK_ROLE_ICON, ATK_ROLE_IMAGE,
    ATK_ROLE_INTERNAL_FRAME, ATK_ROLE_LABEL, ATK_ROLE_LAYERED_PANE,
    ATK_ROLE_LIST, ATK_ROLE_LIST_ITEM, ATK_ROLE_MENU, ATK_ROLE_MENU_BAR,
    ATK_ROLE_MENU_ITEM, ATK_ROLE_OPTION_PANE, ATK_ROLE_PAGE_TAB,
    ATK_ROLE_PAGE_TAB_LIST, ATK_ROLE_PANEL, ATK_ROLE_PASSWORD_TEXT,
    ATK_ROLE_POPUP_MENU, ATK_ROLE_PROGRESS_BAR, ATK_ROLE_PUSH_BUTTON,
    ATK_ROLE_RADIO_BUTTON, ATK_ROLE_RADIO_MENU_ITEM, ATK_ROLE_ROOT_PANE,
    ATK_ROLE_ROW_HEADER, ATK_ROLE_SCROLL_BAR, ATK_ROLE_SCROLL_PANE,
    ATK_ROLE_SEPARATOR, ATK_ROLE_SLIDER, ATK_ROLE_SPLIT_PANE,
    ATK_ROLE_SPIN_BUTTON, ATK_ROLE_STATUSBAR, ATK_ROLE_TABLE,
    ATK_ROLE_TABLE_CELL, ATK_ROLE_TABLE_COLUMN_HEADER,
    ATK_ROLE_TABLE_ROW_HEADER, ATK_ROLE_TEAR_OFF_MENU_ITEM, ATK_ROLE_TERMINAL,
    ATK_ROLE_TEXT, ATK_ROLE_TOGGLE_BUTTON, ATK_ROLE_TOOL_BAR, ATK_ROLE_TOOL_TIP,
    ATK_ROLE_TREE, ATK_ROLE_TREE_TABLE, ATK_ROLE_UNKNOWN, ATK_ROLE_VIEWPORT,
    ATK_ROLE_WINDOW, ATK_ROLE_LAST_DEFINED
  PAtkLayer* = ptr TAtkLayer
  TAtkLayer* = enum
    ATK_LAYER_INVALID, ATK_LAYER_BACKGROUND, ATK_LAYER_CANVAS, ATK_LAYER_WIDGET,
    ATK_LAYER_MDI, ATK_LAYER_POPUP, ATK_LAYER_OVERLAY
  PAtkPropertyValues* = ptr TAtkPropertyValues
  TAtkPropertyValues* {.final, pure.} = object
    property_name*: cstring
    old_value*: TGValue
    new_value*: TGValue

  TAtkFunction* = proc (data: gpointer): gboolean{.cdecl.}
  PAtkObject* = ptr TAtkObject
  PPAtkObject* = ptr PAtkObject
  TAtkObject* = object of TGObject
    description*: cstring
    name*: cstring
    accessible_parent*: PAtkObject
    role*: TAtkRole
    relation_set*: PAtkRelationSet
    layer*: TAtkLayer

  TAtkPropertyChangeHandler* = proc (para1: PAtkObject,
                                     para2: PAtkPropertyValues){.cdecl.}
  PAtkObjectClass* = ptr TAtkObjectClass
  TAtkObjectClass* = object of TGObjectClass
    get_name*: proc (accessible: PAtkObject): cstring{.cdecl.}
    get_description*: proc (accessible: PAtkObject): cstring{.cdecl.}
    get_parent*: proc (accessible: PAtkObject): PAtkObject{.cdecl.}
    get_n_children*: proc (accessible: PAtkObject): gint{.cdecl.}
    ref_child*: proc (accessible: PAtkObject, i: gint): PAtkObject{.cdecl.}
    get_index_in_parent*: proc (accessible: PAtkObject): gint{.cdecl.}
    ref_relation_set*: proc (accessible: PAtkObject): PAtkRelationSet{.cdecl.}
    get_role*: proc (accessible: PAtkObject): TAtkRole{.cdecl.}
    get_layer*: proc (accessible: PAtkObject): TAtkLayer{.cdecl.}
    get_mdi_zorder*: proc (accessible: PAtkObject): gint{.cdecl.}
    ref_state_set*: proc (accessible: PAtkObject): PAtkStateSet{.cdecl.}
    set_name*: proc (accessible: PAtkObject, name: cstring){.cdecl.}
    set_description*: proc (accessible: PAtkObject, description: cstring){.cdecl.}
    set_parent*: proc (accessible: PAtkObject, parent: PAtkObject){.cdecl.}
    set_role*: proc (accessible: PAtkObject, role: TAtkRole){.cdecl.}
    connect_property_change_handler*: proc (accessible: PAtkObject,
        handler: TAtkPropertyChangeHandler): guint{.cdecl.}
    remove_property_change_handler*: proc (accessible: PAtkObject,
        handler_id: guint){.cdecl.}
    initialize*: proc (accessible: PAtkObject, data: gpointer){.cdecl.}
    children_changed*: proc (accessible: PAtkObject, change_index: guint,
                             changed_child: gpointer){.cdecl.}
    focus_event*: proc (accessible: PAtkObject, focus_in: gboolean){.cdecl.}
    property_change*: proc (accessible: PAtkObject, values: PAtkPropertyValues){.
        cdecl.}
    state_change*: proc (accessible: PAtkObject, name: cstring,
                         state_set: gboolean){.cdecl.}
    visible_data_changed*: proc (accessible: PAtkObject){.cdecl.}
    pad1*: TAtkFunction
    pad2*: TAtkFunction
    pad3*: TAtkFunction
    pad4*: TAtkFunction

  PAtkImplementorIface* = ptr TAtkImplementorIface
  TAtkImplementorIface* = object of TGTypeInterface
    ref_accessible*: proc (implementor: PAtkImplementor): PAtkObject{.cdecl.}

  PAtkActionIface* = ptr TAtkActionIface
  TAtkActionIface* = object of TGTypeInterface
    do_action*: proc (action: PAtkAction, i: gint): gboolean{.cdecl.}
    get_n_actions*: proc (action: PAtkAction): gint{.cdecl.}
    get_description*: proc (action: PAtkAction, i: gint): cstring{.cdecl.}
    get_name*: proc (action: PAtkAction, i: gint): cstring{.cdecl.}
    get_keybinding*: proc (action: PAtkAction, i: gint): cstring{.cdecl.}
    set_description*: proc (action: PAtkAction, i: gint, desc: cstring): gboolean{.
        cdecl.}
    pad1*: TAtkFunction
    pad2*: TAtkFunction

  TAtkFocusHandler* = proc (para1: PAtkObject, para2: gboolean){.cdecl.}
  PAtkComponentIface* = ptr TAtkComponentIface
  TAtkComponentIface* = object of TGTypeInterface
    add_focus_handler*: proc (component: PAtkComponent,
                              handler: TAtkFocusHandler): guint{.cdecl.}
    contains*: proc (component: PAtkComponent, x: gint, y: gint,
                     coord_type: TAtkCoordType): gboolean{.cdecl.}
    ref_accessible_at_point*: proc (component: PAtkComponent, x: gint, y: gint,
                                    coord_type: TAtkCoordType): PAtkObject{.
        cdecl.}
    get_extents*: proc (component: PAtkComponent, x: Pgint, y: Pgint,
                        width: Pgint, height: Pgint, coord_type: TAtkCoordType){.
        cdecl.}
    get_position*: proc (component: PAtkComponent, x: Pgint, y: Pgint,
                         coord_type: TAtkCoordType){.cdecl.}
    get_size*: proc (component: PAtkComponent, width: Pgint, height: Pgint){.
        cdecl.}
    grab_focus*: proc (component: PAtkComponent): gboolean{.cdecl.}
    remove_focus_handler*: proc (component: PAtkComponent, handler_id: guint){.
        cdecl.}
    set_extents*: proc (component: PAtkComponent, x: gint, y: gint, width: gint,
                        height: gint, coord_type: TAtkCoordType): gboolean{.
        cdecl.}
    set_position*: proc (component: PAtkComponent, x: gint, y: gint,
                         coord_type: TAtkCoordType): gboolean{.cdecl.}
    set_size*: proc (component: PAtkComponent, width: gint, height: gint): gboolean{.
        cdecl.}
    get_layer*: proc (component: PAtkComponent): TAtkLayer{.cdecl.}
    get_mdi_zorder*: proc (component: PAtkComponent): gint{.cdecl.}
    pad1*: TAtkFunction
    pad2*: TAtkFunction

  PAtkDocumentIface* = ptr TAtkDocumentIface
  TAtkDocumentIface* = object of TGTypeInterface
    get_document_type*: proc (document: PAtkDocument): cstring{.cdecl.}
    get_document*: proc (document: PAtkDocument): gpointer{.cdecl.}
    pad1*: TAtkFunction
    pad2*: TAtkFunction
    pad3*: TAtkFunction
    pad4*: TAtkFunction
    pad5*: TAtkFunction
    pad6*: TAtkFunction
    pad7*: TAtkFunction
    pad8*: TAtkFunction

  PAtkEditableTextIface* = ptr TAtkEditableTextIface
  TAtkEditableTextIface* = object of TGTypeInterface
    set_run_attributes*: proc (text: PAtkEditableText,
                               attrib_set: PAtkAttributeSet, start_offset: gint,
                               end_offset: gint): gboolean{.cdecl.}
    set_text_contents*: proc (text: PAtkEditableText, `string`: cstring){.cdecl.}
    insert_text*: proc (text: PAtkEditableText, `string`: cstring, length: gint,
                        position: Pgint){.cdecl.}
    copy_text*: proc (text: PAtkEditableText, start_pos: gint, end_pos: gint){.
        cdecl.}
    cut_text*: proc (text: PAtkEditableText, start_pos: gint, end_pos: gint){.
        cdecl.}
    delete_text*: proc (text: PAtkEditableText, start_pos: gint, end_pos: gint){.
        cdecl.}
    paste_text*: proc (text: PAtkEditableText, position: gint){.cdecl.}
    pad1*: TAtkFunction
    pad2*: TAtkFunction

  PAtkGObjectAccessible* = ptr TAtkGObjectAccessible
  TAtkGObjectAccessible* = object of TAtkObject

  PAtkGObjectAccessibleClass* = ptr TAtkGObjectAccessibleClass
  TAtkGObjectAccessibleClass* = object of TAtkObjectClass
    pad5*: TAtkFunction
    pad6*: TAtkFunction

  PAtkHyperlink* = ptr TAtkHyperlink
  TAtkHyperlink* = object of TGObject

  PAtkHyperlinkClass* = ptr TAtkHyperlinkClass
  TAtkHyperlinkClass* = object of TGObjectClass
    get_uri*: proc (link: PAtkHyperlink, i: gint): cstring{.cdecl.}
    get_object*: proc (link: PAtkHyperlink, i: gint): PAtkObject{.cdecl.}
    get_end_index*: proc (link: PAtkHyperlink): gint{.cdecl.}
    get_start_index*: proc (link: PAtkHyperlink): gint{.cdecl.}
    is_valid*: proc (link: PAtkHyperlink): gboolean{.cdecl.}
    get_n_anchors*: proc (link: PAtkHyperlink): gint{.cdecl.}
    pad7*: TAtkFunction
    pad8*: TAtkFunction
    pad9*: TAtkFunction
    pad10*: TAtkFunction

  PAtkHypertextIface* = ptr TAtkHypertextIface
  TAtkHypertextIface* = object of TGTypeInterface
    get_link*: proc (hypertext: PAtkHypertext, link_index: gint): PAtkHyperlink{.
        cdecl.}
    get_n_links*: proc (hypertext: PAtkHypertext): gint{.cdecl.}
    get_link_index*: proc (hypertext: PAtkHypertext, char_index: gint): gint{.
        cdecl.}
    pad11*: TAtkFunction
    pad12*: TAtkFunction
    pad13*: TAtkFunction
    pad14*: TAtkFunction

  PAtkImageIface* = ptr TAtkImageIface
  TAtkImageIface* = object of TGTypeInterface
    get_image_position*: proc (image: PAtkImage, x: Pgint, y: Pgint,
                               coord_type: TAtkCoordType){.cdecl.}
    get_image_description*: proc (image: PAtkImage): cstring{.cdecl.}
    get_image_size*: proc (image: PAtkImage, width: Pgint, height: Pgint){.cdecl.}
    set_image_description*: proc (image: PAtkImage, description: cstring): gboolean{.
        cdecl.}
    pad15*: TAtkFunction
    pad16*: TAtkFunction

  PAtkObjectFactory* = ptr TAtkObjectFactory
  TAtkObjectFactory* = object of TGObject

  PAtkObjectFactoryClass* = ptr TAtkObjectFactoryClass
  TAtkObjectFactoryClass* = object of TGObjectClass
    create_accessible*: proc (obj: PGObject): PAtkObject{.cdecl.}
    invalidate*: proc (factory: PAtkObjectFactory){.cdecl.}
    get_accessible_type*: proc (): GType{.cdecl.}
    pad17*: TAtkFunction
    pad18*: TAtkFunction

  PAtkRegistry* = ptr TAtkRegistry
  TAtkRegistry* = object of TGObject
    factory_type_registry*: PGHashTable
    factory_singleton_cache*: PGHashTable

  PAtkRegistryClass* = ptr TAtkRegistryClass
  TAtkRegistryClass* = object of TGObjectClass

  PAtkRelationType* = ptr TAtkRelationType
  TAtkRelationType* = enum
    ATK_RELATION_NULL, ATK_RELATION_CONTROLLED_BY, ATK_RELATION_CONTROLLER_FOR,
    ATK_RELATION_LABEL_FOR, ATK_RELATION_LABELLED_BY, ATK_RELATION_MEMBER_OF,
    ATK_RELATION_NODE_CHILD_OF, ATK_RELATION_LAST_DEFINED
  PAtkRelation* = ptr TAtkRelation
  PGPtrArray = pointer
  TAtkRelation* = object of TGObject
    target*: PGPtrArray
    relationship*: TAtkRelationType

  PAtkRelationClass* = ptr TAtkRelationClass
  TAtkRelationClass* = object of TGObjectClass

  TAtkRelationSet* = object of TGObject
    relations*: PGPtrArray

  PAtkRelationSetClass* = ptr TAtkRelationSetClass
  TAtkRelationSetClass* = object of TGObjectClass
    pad19*: TAtkFunction
    pad20*: TAtkFunction

  PAtkSelectionIface* = ptr TAtkSelectionIface
  TAtkSelectionIface* = object of TGTypeInterface
    add_selection*: proc (selection: PAtkSelection, i: gint): gboolean{.cdecl.}
    clear_selection*: proc (selection: PAtkSelection): gboolean{.cdecl.}
    ref_selection*: proc (selection: PAtkSelection, i: gint): PAtkObject{.cdecl.}
    get_selection_count*: proc (selection: PAtkSelection): gint{.cdecl.}
    is_child_selected*: proc (selection: PAtkSelection, i: gint): gboolean{.
        cdecl.}
    remove_selection*: proc (selection: PAtkSelection, i: gint): gboolean{.cdecl.}
    select_all_selection*: proc (selection: PAtkSelection): gboolean{.cdecl.}
    selection_changed*: proc (selection: PAtkSelection){.cdecl.}
    pad1*: TAtkFunction
    pad2*: TAtkFunction

  PAtkStateType* = ptr TAtkStateType
  TAtkStateType* = enum
    ATK_STATE_INVALID, ATK_STATE_ACTIVE, ATK_STATE_ARMED, ATK_STATE_BUSY,
    ATK_STATE_CHECKED, ATK_STATE_DEFUNCT, ATK_STATE_EDITABLE, ATK_STATE_ENABLED,
    ATK_STATE_EXPANDABLE, ATK_STATE_EXPANDED, ATK_STATE_FOCUSABLE,
    ATK_STATE_FOCUSED, ATK_STATE_HORIZONTAL, ATK_STATE_ICONIFIED,
    ATK_STATE_MODAL, ATK_STATE_MULTI_LINE, ATK_STATE_MULTISELECTABLE,
    ATK_STATE_OPAQUE, ATK_STATE_PRESSED, ATK_STATE_RESIZABLE,
    ATK_STATE_SELECTABLE, ATK_STATE_SELECTED, ATK_STATE_SENSITIVE,
    ATK_STATE_SHOWING, ATK_STATE_SINGLE_LINE, ATK_STATE_STALE,
    ATK_STATE_TRANSIENT, ATK_STATE_VERTICAL, ATK_STATE_VISIBLE,
    ATK_STATE_LAST_DEFINED
  PAtkState* = ptr TAtkState
  TAtkState* = guint64
  TAtkStateSet* = object of TGObject

  PAtkStateSetClass* = ptr TAtkStateSetClass
  TAtkStateSetClass* = object of TGObjectClass

  PAtkStreamableContentIface* = ptr TAtkStreamableContentIface
  TAtkStreamableContentIface* = object of TGTypeInterface
    get_n_mime_types*: proc (streamable: PAtkStreamableContent): gint{.cdecl.}
    get_mime_type*: proc (streamable: PAtkStreamableContent, i: gint): cstring{.
        cdecl.}
    get_stream*: proc (streamable: PAtkStreamableContent, mime_type: cstring): PGIOChannel{.
        cdecl.}
    pad21*: TAtkFunction
    pad22*: TAtkFunction
    pad23*: TAtkFunction
    pad24*: TAtkFunction

  PAtkTableIface* = ptr TAtkTableIface
  TAtkTableIface* = object of TGTypeInterface
    ref_at*: proc (table: PAtkTable, row: gint, column: gint): PAtkObject{.cdecl.}
    get_index_at*: proc (table: PAtkTable, row: gint, column: gint): gint{.cdecl.}
    get_column_at_index*: proc (table: PAtkTable, index: gint): gint{.cdecl.}
    get_row_at_index*: proc (table: PAtkTable, index: gint): gint{.cdecl.}
    get_n_columns*: proc (table: PAtkTable): gint{.cdecl.}
    get_n_rows*: proc (table: PAtkTable): gint{.cdecl.}
    get_column_extent_at*: proc (table: PAtkTable, row: gint, column: gint): gint{.
        cdecl.}
    get_row_extent_at*: proc (table: PAtkTable, row: gint, column: gint): gint{.
        cdecl.}
    get_caption*: proc (table: PAtkTable): PAtkObject{.cdecl.}
    get_column_description*: proc (table: PAtkTable, column: gint): cstring{.
        cdecl.}
    get_column_header*: proc (table: PAtkTable, column: gint): PAtkObject{.cdecl.}
    get_row_description*: proc (table: PAtkTable, row: gint): cstring{.cdecl.}
    get_row_header*: proc (table: PAtkTable, row: gint): PAtkObject{.cdecl.}
    get_summary*: proc (table: PAtkTable): PAtkObject{.cdecl.}
    set_caption*: proc (table: PAtkTable, caption: PAtkObject){.cdecl.}
    set_column_description*: proc (table: PAtkTable, column: gint,
                                   description: cstring){.cdecl.}
    set_column_header*: proc (table: PAtkTable, column: gint, header: PAtkObject){.
        cdecl.}
    set_row_description*: proc (table: PAtkTable, row: gint, description: cstring){.
        cdecl.}
    set_row_header*: proc (table: PAtkTable, row: gint, header: PAtkObject){.
        cdecl.}
    set_summary*: proc (table: PAtkTable, accessible: PAtkObject){.cdecl.}
    get_selected_columns*: proc (table: PAtkTable, selected: PPgint): gint{.
        cdecl.}
    get_selected_rows*: proc (table: PAtkTable, selected: PPgint): gint{.cdecl.}
    is_column_selected*: proc (table: PAtkTable, column: gint): gboolean{.cdecl.}
    is_row_selected*: proc (table: PAtkTable, row: gint): gboolean{.cdecl.}
    is_selected*: proc (table: PAtkTable, row: gint, column: gint): gboolean{.
        cdecl.}
    add_row_selection*: proc (table: PAtkTable, row: gint): gboolean{.cdecl.}
    remove_row_selection*: proc (table: PAtkTable, row: gint): gboolean{.cdecl.}
    add_column_selection*: proc (table: PAtkTable, column: gint): gboolean{.
        cdecl.}
    remove_column_selection*: proc (table: PAtkTable, column: gint): gboolean{.
        cdecl.}
    row_inserted*: proc (table: PAtkTable, row: gint, num_inserted: gint){.cdecl.}
    column_inserted*: proc (table: PAtkTable, column: gint, num_inserted: gint){.
        cdecl.}
    row_deleted*: proc (table: PAtkTable, row: gint, num_deleted: gint){.cdecl.}
    column_deleted*: proc (table: PAtkTable, column: gint, num_deleted: gint){.
        cdecl.}
    row_reordered*: proc (table: PAtkTable){.cdecl.}
    column_reordered*: proc (table: PAtkTable){.cdecl.}
    model_changed*: proc (table: PAtkTable){.cdecl.}
    pad25*: TAtkFunction
    pad26*: TAtkFunction
    pad27*: TAtkFunction
    pad28*: TAtkFunction

  TAtkAttributeSet* = TGSList
  PAtkAttribute* = ptr TAtkAttribute
  TAtkAttribute* {.final, pure.} = object
    name*: cstring
    value*: cstring

  PAtkTextAttribute* = ptr TAtkTextAttribute
  TAtkTextAttribute* = enum
    ATK_TEXT_ATTR_INVALID, ATK_TEXT_ATTR_LEFT_MARGIN,
    ATK_TEXT_ATTR_RIGHT_MARGIN, ATK_TEXT_ATTR_INDENT, ATK_TEXT_ATTR_INVISIBLE,
    ATK_TEXT_ATTR_EDITABLE, ATK_TEXT_ATTR_PIXELS_ABOVE_LINES,
    ATK_TEXT_ATTR_PIXELS_BELOW_LINES, ATK_TEXT_ATTR_PIXELS_INSIDE_WRAP,
    ATK_TEXT_ATTR_BG_FULL_HEIGHT, ATK_TEXT_ATTR_RISE, ATK_TEXT_ATTR_UNDERLINE,
    ATK_TEXT_ATTR_STRIKETHROUGH, ATK_TEXT_ATTR_SIZE, ATK_TEXT_ATTR_SCALE,
    ATK_TEXT_ATTR_WEIGHT, ATK_TEXT_ATTR_LANGUAGE, ATK_TEXT_ATTR_FAMILY_NAME,
    ATK_TEXT_ATTR_BG_COLOR, ATK_TEXT_ATTR_FG_COLOR, ATK_TEXT_ATTR_BG_STIPPLE,
    ATK_TEXT_ATTR_FG_STIPPLE, ATK_TEXT_ATTR_WRAP_MODE, ATK_TEXT_ATTR_DIRECTION,
    ATK_TEXT_ATTR_JUSTIFICATION, ATK_TEXT_ATTR_STRETCH, ATK_TEXT_ATTR_VARIANT,
    ATK_TEXT_ATTR_STYLE, ATK_TEXT_ATTR_LAST_DEFINED
  PAtkTextBoundary* = ptr TAtkTextBoundary
  TAtkTextBoundary* = enum
    ATK_TEXT_BOUNDARY_CHAR, ATK_TEXT_BOUNDARY_WORD_START,
    ATK_TEXT_BOUNDARY_WORD_END, ATK_TEXT_BOUNDARY_SENTENCE_START,
    ATK_TEXT_BOUNDARY_SENTENCE_END, ATK_TEXT_BOUNDARY_LINE_START,
    ATK_TEXT_BOUNDARY_LINE_END
  PAtkTextIface* = ptr TAtkTextIface
  TAtkTextIface* = object of TGTypeInterface
    get_text*: proc (text: PAtkText, start_offset: gint, end_offset: gint): cstring{.
        cdecl.}
    get_text_after_offset*: proc (text: PAtkText, offset: gint,
                                  boundary_type: TAtkTextBoundary,
                                  start_offset: Pgint, end_offset: Pgint): cstring{.
        cdecl.}
    get_text_at_offset*: proc (text: PAtkText, offset: gint,
                               boundary_type: TAtkTextBoundary,
                               start_offset: Pgint, end_offset: Pgint): cstring{.
        cdecl.}
    get_character_at_offset*: proc (text: PAtkText, offset: gint): gunichar{.
        cdecl.}
    get_text_before_offset*: proc (text: PAtkText, offset: gint,
                                   boundary_type: TAtkTextBoundary,
                                   start_offset: Pgint, end_offset: Pgint): cstring{.
        cdecl.}
    get_caret_offset*: proc (text: PAtkText): gint{.cdecl.}
    get_run_attributes*: proc (text: PAtkText, offset: gint,
                               start_offset: Pgint, end_offset: Pgint): PAtkAttributeSet{.
        cdecl.}
    get_default_attributes*: proc (text: PAtkText): PAtkAttributeSet{.cdecl.}
    get_character_extents*: proc (text: PAtkText, offset: gint, x: Pgint,
                                  y: Pgint, width: Pgint, height: Pgint,
                                  coords: TAtkCoordType){.cdecl.}
    get_character_count*: proc (text: PAtkText): gint{.cdecl.}
    get_offset_at_point*: proc (text: PAtkText, x: gint, y: gint,
                                coords: TAtkCoordType): gint{.cdecl.}
    get_n_selections*: proc (text: PAtkText): gint{.cdecl.}
    get_selection*: proc (text: PAtkText, selection_num: gint,
                          start_offset: Pgint, end_offset: Pgint): cstring{.cdecl.}
    add_selection*: proc (text: PAtkText, start_offset: gint, end_offset: gint): gboolean{.
        cdecl.}
    remove_selection*: proc (text: PAtkText, selection_num: gint): gboolean{.
        cdecl.}
    set_selection*: proc (text: PAtkText, selection_num: gint,
                          start_offset: gint, end_offset: gint): gboolean{.cdecl.}
    set_caret_offset*: proc (text: PAtkText, offset: gint): gboolean{.cdecl.}
    text_changed*: proc (text: PAtkText, position: gint, length: gint){.cdecl.}
    text_caret_moved*: proc (text: PAtkText, location: gint){.cdecl.}
    text_selection_changed*: proc (text: PAtkText){.cdecl.}
    pad29*: TAtkFunction
    pad30*: TAtkFunction
    pad31*: TAtkFunction
    pad32*: TAtkFunction

  TAtkEventListener* = proc (para1: PAtkObject){.cdecl.}
  TAtkEventListenerInitProc* = proc ()
  TAtkEventListenerInit* = proc (para1: TAtkEventListenerInitProc){.cdecl.}
  PAtkKeyEventStruct* = ptr TAtkKeyEventStruct
  TAtkKeyEventStruct* {.final, pure.} = object
    `type`*: gint
    state*: guint
    keyval*: guint
    length*: gint
    string*: cstring
    keycode*: guint16
    timestamp*: guint32

  TAtkKeySnoopFunc* = proc (event: PAtkKeyEventStruct, func_data: gpointer): gint{.
      cdecl.}
  PAtkKeyEventType* = ptr TAtkKeyEventType
  TAtkKeyEventType* = enum
    ATK_KEY_EVENT_PRESS, ATK_KEY_EVENT_RELEASE, ATK_KEY_EVENT_LAST_DEFINED
  PAtkUtil* = ptr TAtkUtil
  TAtkUtil* = object of TGObject

  PAtkUtilClass* = ptr TAtkUtilClass
  TAtkUtilClass* = object of TGObjectClass
    add_global_event_listener*: proc (listener: TGSignalEmissionHook,
                                      event_type: cstring): guint{.cdecl.}
    remove_global_event_listener*: proc (listener_id: guint){.cdecl.}
    add_key_event_listener*: proc (listener: TAtkKeySnoopFunc, data: gpointer): guint{.
        cdecl.}
    remove_key_event_listener*: proc (listener_id: guint){.cdecl.}
    get_root*: proc (): PAtkObject{.cdecl.}
    get_toolkit_name*: proc (): cstring{.cdecl.}
    get_toolkit_version*: proc (): cstring{.cdecl.}

  PAtkValueIface* = ptr TAtkValueIface
  TAtkValueIface* = object of TGTypeInterface
    get_current_value*: proc (obj: PAtkValue, value: PGValue){.cdecl.}
    get_maximum_value*: proc (obj: PAtkValue, value: PGValue){.cdecl.}
    get_minimum_value*: proc (obj: PAtkValue, value: PGValue){.cdecl.}
    set_current_value*: proc (obj: PAtkValue, value: PGValue): gboolean{.cdecl.}
    pad33*: TAtkFunction
    pad34*: TAtkFunction


proc atk_role_register*(name: cstring): TAtkRole{.cdecl, dynlib: atklib,
    importc: "atk_role_register".}
proc atk_object_get_type*(): GType{.cdecl, dynlib: atklib,
                                    importc: "atk_object_get_type".}
proc ATK_TYPE_OBJECT*(): GType
proc ATK_OBJECT*(obj: pointer): PAtkObject
proc ATK_OBJECT_CLASS*(klass: pointer): PAtkObjectClass
proc ATK_IS_OBJECT*(obj: pointer): bool
proc ATK_IS_OBJECT_CLASS*(klass: pointer): bool
proc ATK_OBJECT_GET_CLASS*(obj: pointer): PAtkObjectClass
proc ATK_TYPE_IMPLEMENTOR*(): GType
proc ATK_IS_IMPLEMENTOR*(obj: pointer): bool
proc ATK_IMPLEMENTOR*(obj: pointer): PAtkImplementor
proc ATK_IMPLEMENTOR_GET_IFACE*(obj: pointer): PAtkImplementorIface
proc atk_implementor_get_type*(): GType{.cdecl, dynlib: atklib,
    importc: "atk_implementor_get_type".}
proc atk_implementor_ref_accessible*(implementor: PAtkImplementor): PAtkObject{.
    cdecl, dynlib: atklib, importc: "atk_implementor_ref_accessible".}
proc atk_object_get_name*(accessible: PAtkObject): cstring{.cdecl,
    dynlib: atklib, importc: "atk_object_get_name".}
proc atk_object_get_description*(accessible: PAtkObject): cstring{.cdecl,
    dynlib: atklib, importc: "atk_object_get_description".}
proc atk_object_get_parent*(accessible: PAtkObject): PAtkObject{.cdecl,
    dynlib: atklib, importc: "atk_object_get_parent".}
proc atk_object_get_n_accessible_children*(accessible: PAtkObject): gint{.cdecl,
    dynlib: atklib, importc: "atk_object_get_n_accessible_children".}
proc atk_object_ref_accessible_child*(accessible: PAtkObject, i: gint): PAtkObject{.
    cdecl, dynlib: atklib, importc: "atk_object_ref_accessible_child".}
proc atk_object_ref_relation_set*(accessible: PAtkObject): PAtkRelationSet{.
    cdecl, dynlib: atklib, importc: "atk_object_ref_relation_set".}
proc atk_object_get_role*(accessible: PAtkObject): TAtkRole{.cdecl,
    dynlib: atklib, importc: "atk_object_get_role".}
proc atk_object_get_layer*(accessible: PAtkObject): TAtkLayer{.cdecl,
    dynlib: atklib, importc: "atk_object_get_layer".}
proc atk_object_get_mdi_zorder*(accessible: PAtkObject): gint{.cdecl,
    dynlib: atklib, importc: "atk_object_get_mdi_zorder".}
proc atk_object_ref_state_set*(accessible: PAtkObject): PAtkStateSet{.cdecl,
    dynlib: atklib, importc: "atk_object_ref_state_set".}
proc atk_object_get_index_in_parent*(accessible: PAtkObject): gint{.cdecl,
    dynlib: atklib, importc: "atk_object_get_index_in_parent".}
proc atk_object_set_name*(accessible: PAtkObject, name: cstring){.cdecl,
    dynlib: atklib, importc: "atk_object_set_name".}
proc atk_object_set_description*(accessible: PAtkObject, description: cstring){.
    cdecl, dynlib: atklib, importc: "atk_object_set_description".}
proc atk_object_set_parent*(accessible: PAtkObject, parent: PAtkObject){.cdecl,
    dynlib: atklib, importc: "atk_object_set_parent".}
proc atk_object_set_role*(accessible: PAtkObject, role: TAtkRole){.cdecl,
    dynlib: atklib, importc: "atk_object_set_role".}
proc atk_object_connect_property_change_handler*(accessible: PAtkObject,
    handler: TAtkPropertyChangeHandler): guint{.cdecl, dynlib: atklib,
    importc: "atk_object_connect_property_change_handler".}
proc atk_object_remove_property_change_handler*(accessible: PAtkObject,
    handler_id: guint){.cdecl, dynlib: atklib,
                        importc: "atk_object_remove_property_change_handler".}
proc atk_object_notify_state_change*(accessible: PAtkObject, state: TAtkState,
                                     value: gboolean){.cdecl, dynlib: atklib,
    importc: "atk_object_notify_state_change".}
proc atk_object_initialize*(accessible: PAtkObject, data: gpointer){.cdecl,
    dynlib: atklib, importc: "atk_object_initialize".}
proc atk_role_get_name*(role: TAtkRole): cstring{.cdecl, dynlib: atklib,
    importc: "atk_role_get_name".}
proc atk_role_for_name*(name: cstring): TAtkRole{.cdecl, dynlib: atklib,
    importc: "atk_role_for_name".}
proc ATK_TYPE_ACTION*(): GType
proc ATK_IS_ACTION*(obj: pointer): bool
proc ATK_ACTION*(obj: pointer): PAtkAction
proc ATK_ACTION_GET_IFACE*(obj: pointer): PAtkActionIface
proc atk_action_get_type*(): GType{.cdecl, dynlib: atklib,
                                    importc: "atk_action_get_type".}
proc atk_action_do_action*(action: PAtkAction, i: gint): gboolean{.cdecl,
    dynlib: atklib, importc: "atk_action_do_action".}
proc atk_action_get_n_actions*(action: PAtkAction): gint{.cdecl, dynlib: atklib,
    importc: "atk_action_get_n_actions".}
proc atk_action_get_description*(action: PAtkAction, i: gint): cstring{.cdecl,
    dynlib: atklib, importc: "atk_action_get_description".}
proc atk_action_get_name*(action: PAtkAction, i: gint): cstring{.cdecl,
    dynlib: atklib, importc: "atk_action_get_name".}
proc atk_action_get_keybinding*(action: PAtkAction, i: gint): cstring{.cdecl,
    dynlib: atklib, importc: "atk_action_get_keybinding".}
proc atk_action_set_description*(action: PAtkAction, i: gint, desc: cstring): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_action_set_description".}
proc ATK_TYPE_COMPONENT*(): GType
proc ATK_IS_COMPONENT*(obj: pointer): bool
proc ATK_COMPONENT*(obj: pointer): PAtkComponent
proc ATK_COMPONENT_GET_IFACE*(obj: pointer): PAtkComponentIface
proc atk_component_get_type*(): GType{.cdecl, dynlib: atklib,
                                       importc: "atk_component_get_type".}
proc atk_component_add_focus_handler*(component: PAtkComponent,
                                      handler: TAtkFocusHandler): guint{.cdecl,
    dynlib: atklib, importc: "atk_component_add_focus_handler".}
proc atk_component_contains*(component: PAtkComponent, x, y: gint,
                             coord_type: TAtkCoordType): gboolean{.cdecl,
    dynlib: atklib, importc: "atk_component_contains".}
proc atk_component_ref_accessible_at_point*(component: PAtkComponent,
    x, y: gint, coord_type: TAtkCoordType): PAtkObject{.cdecl, dynlib: atklib,
    importc: "atk_component_ref_accessible_at_point".}
proc atk_component_get_extents*(component: PAtkComponent,
                                x, y, width, height: Pgint,
                                coord_type: TAtkCoordType){.cdecl,
    dynlib: atklib, importc: "atk_component_get_extents".}
proc atk_component_get_position*(component: PAtkComponent, x: Pgint, y: Pgint,
                                 coord_type: TAtkCoordType){.cdecl,
    dynlib: atklib, importc: "atk_component_get_position".}
proc atk_component_get_size*(component: PAtkComponent, width: Pgint,
                             height: Pgint){.cdecl, dynlib: atklib,
    importc: "atk_component_get_size".}
proc atk_component_get_layer*(component: PAtkComponent): TAtkLayer{.cdecl,
    dynlib: atklib, importc: "atk_component_get_layer".}
proc atk_component_get_mdi_zorder*(component: PAtkComponent): gint{.cdecl,
    dynlib: atklib, importc: "atk_component_get_mdi_zorder".}
proc atk_component_grab_focus*(component: PAtkComponent): gboolean{.cdecl,
    dynlib: atklib, importc: "atk_component_grab_focus".}
proc atk_component_remove_focus_handler*(component: PAtkComponent,
    handler_id: guint){.cdecl, dynlib: atklib,
                        importc: "atk_component_remove_focus_handler".}
proc atk_component_set_extents*(component: PAtkComponent, x: gint, y: gint,
                                width: gint, height: gint,
                                coord_type: TAtkCoordType): gboolean{.cdecl,
    dynlib: atklib, importc: "atk_component_set_extents".}
proc atk_component_set_position*(component: PAtkComponent, x: gint, y: gint,
                                 coord_type: TAtkCoordType): gboolean{.cdecl,
    dynlib: atklib, importc: "atk_component_set_position".}
proc atk_component_set_size*(component: PAtkComponent, width: gint, height: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_component_set_size".}
proc ATK_TYPE_DOCUMENT*(): GType
proc ATK_IS_DOCUMENT*(obj: pointer): bool
proc ATK_DOCUMENT*(obj: pointer): PAtkDocument
proc ATK_DOCUMENT_GET_IFACE*(obj: pointer): PAtkDocumentIface
proc atk_document_get_type*(): GType{.cdecl, dynlib: atklib,
                                      importc: "atk_document_get_type".}
proc atk_document_get_document_type*(document: PAtkDocument): cstring{.cdecl,
    dynlib: atklib, importc: "atk_document_get_document_type".}
proc atk_document_get_document*(document: PAtkDocument): gpointer{.cdecl,
    dynlib: atklib, importc: "atk_document_get_document".}
proc ATK_TYPE_EDITABLE_TEXT*(): GType
proc ATK_IS_EDITABLE_TEXT*(obj: pointer): bool
proc ATK_EDITABLE_TEXT*(obj: pointer): PAtkEditableText
proc ATK_EDITABLE_TEXT_GET_IFACE*(obj: pointer): PAtkEditableTextIface
proc atk_editable_text_get_type*(): GType{.cdecl, dynlib: atklib,
    importc: "atk_editable_text_get_type".}
proc atk_editable_text_set_run_attributes*(text: PAtkEditableText,
    attrib_set: PAtkAttributeSet, start_offset: gint, end_offset: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_editable_text_set_run_attributes".}
proc atk_editable_text_set_text_contents*(text: PAtkEditableText, string: cstring){.
    cdecl, dynlib: atklib, importc: "atk_editable_text_set_text_contents".}
proc atk_editable_text_insert_text*(text: PAtkEditableText, `string`: cstring,
                                    length: gint, position: Pgint){.cdecl,
    dynlib: atklib, importc: "atk_editable_text_insert_text".}
proc atk_editable_text_copy_text*(text: PAtkEditableText, start_pos: gint,
                                  end_pos: gint){.cdecl, dynlib: atklib,
    importc: "atk_editable_text_copy_text".}
proc atk_editable_text_cut_text*(text: PAtkEditableText, start_pos: gint,
                                 end_pos: gint){.cdecl, dynlib: atklib,
    importc: "atk_editable_text_cut_text".}
proc atk_editable_text_delete_text*(text: PAtkEditableText, start_pos: gint,
                                    end_pos: gint){.cdecl, dynlib: atklib,
    importc: "atk_editable_text_delete_text".}
proc atk_editable_text_paste_text*(text: PAtkEditableText, position: gint){.
    cdecl, dynlib: atklib, importc: "atk_editable_text_paste_text".}
proc ATK_TYPE_GOBJECT_ACCESSIBLE*(): GType
proc ATK_GOBJECT_ACCESSIBLE*(obj: pointer): PAtkGObjectAccessible
proc ATK_GOBJECT_ACCESSIBLE_CLASS*(klass: pointer): PAtkGObjectAccessibleClass
proc ATK_IS_GOBJECT_ACCESSIBLE*(obj: pointer): bool
proc ATK_IS_GOBJECT_ACCESSIBLE_CLASS*(klass: pointer): bool
proc ATK_GOBJECT_ACCESSIBLE_GET_CLASS*(obj: pointer): PAtkGObjectAccessibleClass
proc atk_gobject_accessible_get_type*(): GType{.cdecl, dynlib: atklib,
    importc: "atk_gobject_accessible_get_type".}
proc atk_gobject_accessible_for_object*(obj: PGObject): PAtkObject{.cdecl,
    dynlib: atklib, importc: "atk_gobject_accessible_for_object".}
proc atk_gobject_accessible_get_object*(obj: PAtkGObjectAccessible): PGObject{.
    cdecl, dynlib: atklib, importc: "atk_gobject_accessible_get_object".}
proc ATK_TYPE_HYPERLINK*(): GType
proc ATK_HYPERLINK*(obj: pointer): PAtkHyperlink
proc ATK_HYPERLINK_CLASS*(klass: pointer): PAtkHyperlinkClass
proc ATK_IS_HYPERLINK*(obj: pointer): bool
proc ATK_IS_HYPERLINK_CLASS*(klass: pointer): bool
proc ATK_HYPERLINK_GET_CLASS*(obj: pointer): PAtkHyperlinkClass
proc atk_hyperlink_get_type*(): GType{.cdecl, dynlib: atklib,
                                       importc: "atk_hyperlink_get_type".}
proc atk_hyperlink_get_uri*(link: PAtkHyperlink, i: gint): cstring{.cdecl,
    dynlib: atklib, importc: "atk_hyperlink_get_uri".}
proc atk_hyperlink_get_object*(link: PAtkHyperlink, i: gint): PAtkObject{.cdecl,
    dynlib: atklib, importc: "atk_hyperlink_get_object".}
proc atk_hyperlink_get_end_index*(link: PAtkHyperlink): gint{.cdecl,
    dynlib: atklib, importc: "atk_hyperlink_get_end_index".}
proc atk_hyperlink_get_start_index*(link: PAtkHyperlink): gint{.cdecl,
    dynlib: atklib, importc: "atk_hyperlink_get_start_index".}
proc atk_hyperlink_is_valid*(link: PAtkHyperlink): gboolean{.cdecl,
    dynlib: atklib, importc: "atk_hyperlink_is_valid".}
proc atk_hyperlink_get_n_anchors*(link: PAtkHyperlink): gint{.cdecl,
    dynlib: atklib, importc: "atk_hyperlink_get_n_anchors".}
proc ATK_TYPE_HYPERTEXT*(): GType
proc ATK_IS_HYPERTEXT*(obj: pointer): bool
proc ATK_HYPERTEXT*(obj: pointer): PAtkHypertext
proc ATK_HYPERTEXT_GET_IFACE*(obj: pointer): PAtkHypertextIface
proc atk_hypertext_get_type*(): GType{.cdecl, dynlib: atklib,
                                       importc: "atk_hypertext_get_type".}
proc atk_hypertext_get_link*(hypertext: PAtkHypertext, link_index: gint): PAtkHyperlink{.
    cdecl, dynlib: atklib, importc: "atk_hypertext_get_link".}
proc atk_hypertext_get_n_links*(hypertext: PAtkHypertext): gint{.cdecl,
    dynlib: atklib, importc: "atk_hypertext_get_n_links".}
proc atk_hypertext_get_link_index*(hypertext: PAtkHypertext, char_index: gint): gint{.
    cdecl, dynlib: atklib, importc: "atk_hypertext_get_link_index".}
proc ATK_TYPE_IMAGE*(): GType
proc ATK_IS_IMAGE*(obj: pointer): bool
proc ATK_IMAGE*(obj: pointer): PAtkImage
proc ATK_IMAGE_GET_IFACE*(obj: pointer): PAtkImageIface
proc atk_image_get_type*(): GType{.cdecl, dynlib: atklib,
                                   importc: "atk_image_get_type".}
proc atk_image_get_image_description*(image: PAtkImage): cstring{.cdecl,
    dynlib: atklib, importc: "atk_image_get_image_description".}
proc atk_image_get_image_size*(image: PAtkImage, width: Pgint, height: Pgint){.
    cdecl, dynlib: atklib, importc: "atk_image_get_image_size".}
proc atk_image_set_image_description*(image: PAtkImage, description: cstring): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_image_set_image_description".}
proc atk_image_get_image_position*(image: PAtkImage, x: Pgint, y: Pgint,
                                   coord_type: TAtkCoordType){.cdecl,
    dynlib: atklib, importc: "atk_image_get_image_position".}
proc ATK_TYPE_OBJECT_FACTORY*(): GType
proc ATK_OBJECT_FACTORY*(obj: pointer): PAtkObjectFactory
proc ATK_OBJECT_FACTORY_CLASS*(klass: pointer): PAtkObjectFactoryClass
proc ATK_IS_OBJECT_FACTORY*(obj: pointer): bool
proc ATK_IS_OBJECT_FACTORY_CLASS*(klass: pointer): bool
proc ATK_OBJECT_FACTORY_GET_CLASS*(obj: pointer): PAtkObjectFactoryClass
proc atk_object_factory_get_type*(): GType{.cdecl, dynlib: atklib,
    importc: "atk_object_factory_get_type".}
proc atk_object_factory_create_accessible*(factory: PAtkObjectFactory,
    obj: PGObject): PAtkObject{.cdecl, dynlib: atklib,
                                importc: "atk_object_factory_create_accessible".}
proc atk_object_factory_invalidate*(factory: PAtkObjectFactory){.cdecl,
    dynlib: atklib, importc: "atk_object_factory_invalidate".}
proc atk_object_factory_get_accessible_type*(factory: PAtkObjectFactory): GType{.
    cdecl, dynlib: atklib, importc: "atk_object_factory_get_accessible_type".}
proc ATK_TYPE_REGISTRY*(): GType
proc ATK_REGISTRY*(obj: pointer): PAtkRegistry
proc ATK_REGISTRY_CLASS*(klass: pointer): PAtkRegistryClass
proc ATK_IS_REGISTRY*(obj: pointer): bool
proc ATK_IS_REGISTRY_CLASS*(klass: pointer): bool
proc ATK_REGISTRY_GET_CLASS*(obj: pointer): PAtkRegistryClass
proc atk_registry_get_type*(): GType{.cdecl, dynlib: atklib,
                                      importc: "atk_registry_get_type".}
proc atk_registry_set_factory_type*(registry: PAtkRegistry, `type`: GType,
                                    factory_type: GType){.cdecl, dynlib: atklib,
    importc: "atk_registry_set_factory_type".}
proc atk_registry_get_factory_type*(registry: PAtkRegistry, `type`: GType): GType{.
    cdecl, dynlib: atklib, importc: "atk_registry_get_factory_type".}
proc atk_registry_get_factory*(registry: PAtkRegistry, `type`: GType): PAtkObjectFactory{.
    cdecl, dynlib: atklib, importc: "atk_registry_get_factory".}
proc atk_get_default_registry*(): PAtkRegistry{.cdecl, dynlib: atklib,
    importc: "atk_get_default_registry".}
proc ATK_TYPE_RELATION*(): GType
proc ATK_RELATION*(obj: pointer): PAtkRelation
proc ATK_RELATION_CLASS*(klass: pointer): PAtkRelationClass
proc ATK_IS_RELATION*(obj: pointer): bool
proc ATK_IS_RELATION_CLASS*(klass: pointer): bool
proc ATK_RELATION_GET_CLASS*(obj: pointer): PAtkRelationClass
proc atk_relation_get_type*(): GType{.cdecl, dynlib: atklib,
                                      importc: "atk_relation_get_type".}
proc atk_relation_type_register*(name: cstring): TAtkRelationType{.cdecl,
    dynlib: atklib, importc: "atk_relation_type_register".}
proc atk_relation_type_get_name*(`type`: TAtkRelationType): cstring{.cdecl,
    dynlib: atklib, importc: "atk_relation_type_get_name".}
proc atk_relation_type_for_name*(name: cstring): TAtkRelationType{.cdecl,
    dynlib: atklib, importc: "atk_relation_type_for_name".}
proc atk_relation_new*(targets: PPAtkObject, n_targets: gint,
                       relationship: TAtkRelationType): PAtkRelation{.cdecl,
    dynlib: atklib, importc: "atk_relation_new".}
proc atk_relation_get_relation_type*(relation: PAtkRelation): TAtkRelationType{.
    cdecl, dynlib: atklib, importc: "atk_relation_get_relation_type".}
proc atk_relation_get_target*(relation: PAtkRelation): PGPtrArray{.cdecl,
    dynlib: atklib, importc: "atk_relation_get_target".}
proc ATK_TYPE_RELATION_SET*(): GType
proc ATK_RELATION_SET*(obj: pointer): PAtkRelationSet
proc ATK_RELATION_SET_CLASS*(klass: pointer): PAtkRelationSetClass
proc ATK_IS_RELATION_SET*(obj: pointer): bool
proc ATK_IS_RELATION_SET_CLASS*(klass: pointer): bool
proc ATK_RELATION_SET_GET_CLASS*(obj: pointer): PAtkRelationSetClass
proc atk_relation_set_get_type*(): GType{.cdecl, dynlib: atklib,
    importc: "atk_relation_set_get_type".}
proc atk_relation_set_new*(): PAtkRelationSet{.cdecl, dynlib: atklib,
    importc: "atk_relation_set_new".}
proc atk_relation_set_contains*(RelationSet: PAtkRelationSet,
                                relationship: TAtkRelationType): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_relation_set_contains".}
proc atk_relation_set_remove*(RelationSet: PAtkRelationSet,
                              relation: PAtkRelation){.cdecl, dynlib: atklib,
    importc: "atk_relation_set_remove".}
proc atk_relation_set_add*(RelationSet: PAtkRelationSet, relation: PAtkRelation){.
    cdecl, dynlib: atklib, importc: "atk_relation_set_add".}
proc atk_relation_set_get_n_relations*(RelationSet: PAtkRelationSet): gint{.
    cdecl, dynlib: atklib, importc: "atk_relation_set_get_n_relations".}
proc atk_relation_set_get_relation*(RelationSet: PAtkRelationSet, i: gint): PAtkRelation{.
    cdecl, dynlib: atklib, importc: "atk_relation_set_get_relation".}
proc atk_relation_set_get_relation_by_type*(RelationSet: PAtkRelationSet,
    relationship: TAtkRelationType): PAtkRelation{.cdecl, dynlib: atklib,
    importc: "atk_relation_set_get_relation_by_type".}
proc ATK_TYPE_SELECTION*(): GType
proc ATK_IS_SELECTION*(obj: pointer): bool
proc ATK_SELECTION*(obj: pointer): PAtkSelection
proc ATK_SELECTION_GET_IFACE*(obj: pointer): PAtkSelectionIface
proc atk_selection_get_type*(): GType{.cdecl, dynlib: atklib,
                                       importc: "atk_selection_get_type".}
proc atk_selection_add_selection*(selection: PAtkSelection, i: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_selection_add_selection".}
proc atk_selection_clear_selection*(selection: PAtkSelection): gboolean{.cdecl,
    dynlib: atklib, importc: "atk_selection_clear_selection".}
proc atk_selection_ref_selection*(selection: PAtkSelection, i: gint): PAtkObject{.
    cdecl, dynlib: atklib, importc: "atk_selection_ref_selection".}
proc atk_selection_get_selection_count*(selection: PAtkSelection): gint{.cdecl,
    dynlib: atklib, importc: "atk_selection_get_selection_count".}
proc atk_selection_is_child_selected*(selection: PAtkSelection, i: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_selection_is_child_selected".}
proc atk_selection_remove_selection*(selection: PAtkSelection, i: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_selection_remove_selection".}
proc atk_selection_select_all_selection*(selection: PAtkSelection): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_selection_select_all_selection".}
proc atk_state_type_register*(name: cstring): TAtkStateType{.cdecl,
    dynlib: atklib, importc: "atk_state_type_register".}
proc atk_state_type_get_name*(`type`: TAtkStateType): cstring{.cdecl,
    dynlib: atklib, importc: "atk_state_type_get_name".}
proc atk_state_type_for_name*(name: cstring): TAtkStateType{.cdecl,
    dynlib: atklib, importc: "atk_state_type_for_name".}
proc ATK_TYPE_STATE_SET*(): GType
proc ATK_STATE_SET*(obj: pointer): PAtkStateSet
proc ATK_STATE_SET_CLASS*(klass: pointer): PAtkStateSetClass
proc ATK_IS_STATE_SET*(obj: pointer): bool
proc ATK_IS_STATE_SET_CLASS*(klass: pointer): bool
proc ATK_STATE_SET_GET_CLASS*(obj: pointer): PAtkStateSetClass
proc atk_state_set_get_type*(): GType{.cdecl, dynlib: atklib,
                                       importc: "atk_state_set_get_type".}
proc atk_state_set_new*(): PAtkStateSet{.cdecl, dynlib: atklib,
    importc: "atk_state_set_new".}
proc atk_state_set_is_empty*(StateSet: PAtkStateSet): gboolean{.cdecl,
    dynlib: atklib, importc: "atk_state_set_is_empty".}
proc atk_state_set_add_state*(StateSet: PAtkStateSet, `type`: TAtkStateType): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_state_set_add_state".}
proc atk_state_set_add_states*(StateSet: PAtkStateSet, types: PAtkStateType,
                               n_types: gint){.cdecl, dynlib: atklib,
    importc: "atk_state_set_add_states".}
proc atk_state_set_clear_states*(StateSet: PAtkStateSet){.cdecl, dynlib: atklib,
    importc: "atk_state_set_clear_states".}
proc atk_state_set_contains_state*(StateSet: PAtkStateSet, `type`: TAtkStateType): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_state_set_contains_state".}
proc atk_state_set_contains_states*(StateSet: PAtkStateSet,
                                    types: PAtkStateType, n_types: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_state_set_contains_states".}
proc atk_state_set_remove_state*(StateSet: PAtkStateSet, `type`: TAtkStateType): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_state_set_remove_state".}
proc atk_state_set_and_sets*(StateSet: PAtkStateSet, compare_set: PAtkStateSet): PAtkStateSet{.
    cdecl, dynlib: atklib, importc: "atk_state_set_and_sets".}
proc atk_state_set_or_sets*(StateSet: PAtkStateSet, compare_set: PAtkStateSet): PAtkStateSet{.
    cdecl, dynlib: atklib, importc: "atk_state_set_or_sets".}
proc atk_state_set_xor_sets*(StateSet: PAtkStateSet, compare_set: PAtkStateSet): PAtkStateSet{.
    cdecl, dynlib: atklib, importc: "atk_state_set_xor_sets".}
proc ATK_TYPE_STREAMABLE_CONTENT*(): GType
proc ATK_IS_STREAMABLE_CONTENT*(obj: pointer): bool
proc ATK_STREAMABLE_CONTENT*(obj: pointer): PAtkStreamableContent
proc ATK_STREAMABLE_CONTENT_GET_IFACE*(obj: pointer): PAtkStreamableContentIface
proc atk_streamable_content_get_type*(): GType{.cdecl, dynlib: atklib,
    importc: "atk_streamable_content_get_type".}
proc atk_streamable_content_get_n_mime_types*(streamable: PAtkStreamableContent): gint{.
    cdecl, dynlib: atklib, importc: "atk_streamable_content_get_n_mime_types".}
proc atk_streamable_content_get_mime_type*(streamable: PAtkStreamableContent,
    i: gint): cstring{.cdecl, dynlib: atklib,
                      importc: "atk_streamable_content_get_mime_type".}
proc atk_streamable_content_get_stream*(streamable: PAtkStreamableContent,
                                        mime_type: cstring): PGIOChannel{.cdecl,
    dynlib: atklib, importc: "atk_streamable_content_get_stream".}
proc ATK_TYPE_TABLE*(): GType
proc ATK_IS_TABLE*(obj: pointer): bool
proc ATK_TABLE*(obj: pointer): PAtkTable
proc ATK_TABLE_GET_IFACE*(obj: pointer): PAtkTableIface
proc atk_table_get_type*(): GType{.cdecl, dynlib: atklib,
                                   importc: "atk_table_get_type".}
proc atk_table_ref_at*(table: PAtkTable, row, column: gint): PAtkObject{.cdecl,
    dynlib: atklib, importc: "atk_table_ref_at".}
proc atk_table_get_index_at*(table: PAtkTable, row, column: gint): gint{.cdecl,
    dynlib: atklib, importc: "atk_table_get_index_at".}
proc atk_table_get_column_at_index*(table: PAtkTable, index: gint): gint{.cdecl,
    dynlib: atklib, importc: "atk_table_get_column_at_index".}
proc atk_table_get_row_at_index*(table: PAtkTable, index: gint): gint{.cdecl,
    dynlib: atklib, importc: "atk_table_get_row_at_index".}
proc atk_table_get_n_columns*(table: PAtkTable): gint{.cdecl, dynlib: atklib,
    importc: "atk_table_get_n_columns".}
proc atk_table_get_n_rows*(table: PAtkTable): gint{.cdecl, dynlib: atklib,
    importc: "atk_table_get_n_rows".}
proc atk_table_get_column_extent_at*(table: PAtkTable, row: gint, column: gint): gint{.
    cdecl, dynlib: atklib, importc: "atk_table_get_column_extent_at".}
proc atk_table_get_row_extent_at*(table: PAtkTable, row: gint, column: gint): gint{.
    cdecl, dynlib: atklib, importc: "atk_table_get_row_extent_at".}
proc atk_table_get_caption*(table: PAtkTable): PAtkObject{.cdecl,
    dynlib: atklib, importc: "atk_table_get_caption".}
proc atk_table_get_column_description*(table: PAtkTable, column: gint): cstring{.
    cdecl, dynlib: atklib, importc: "atk_table_get_column_description".}
proc atk_table_get_column_header*(table: PAtkTable, column: gint): PAtkObject{.
    cdecl, dynlib: atklib, importc: "atk_table_get_column_header".}
proc atk_table_get_row_description*(table: PAtkTable, row: gint): cstring{.cdecl,
    dynlib: atklib, importc: "atk_table_get_row_description".}
proc atk_table_get_row_header*(table: PAtkTable, row: gint): PAtkObject{.cdecl,
    dynlib: atklib, importc: "atk_table_get_row_header".}
proc atk_table_get_summary*(table: PAtkTable): PAtkObject{.cdecl,
    dynlib: atklib, importc: "atk_table_get_summary".}
proc atk_table_set_caption*(table: PAtkTable, caption: PAtkObject){.cdecl,
    dynlib: atklib, importc: "atk_table_set_caption".}
proc atk_table_set_column_description*(table: PAtkTable, column: gint,
                                       description: cstring){.cdecl,
    dynlib: atklib, importc: "atk_table_set_column_description".}
proc atk_table_set_column_header*(table: PAtkTable, column: gint,
                                  header: PAtkObject){.cdecl, dynlib: atklib,
    importc: "atk_table_set_column_header".}
proc atk_table_set_row_description*(table: PAtkTable, row: gint,
                                    description: cstring){.cdecl, dynlib: atklib,
    importc: "atk_table_set_row_description".}
proc atk_table_set_row_header*(table: PAtkTable, row: gint, header: PAtkObject){.
    cdecl, dynlib: atklib, importc: "atk_table_set_row_header".}
proc atk_table_set_summary*(table: PAtkTable, accessible: PAtkObject){.cdecl,
    dynlib: atklib, importc: "atk_table_set_summary".}
proc atk_table_get_selected_columns*(table: PAtkTable, selected: PPgint): gint{.
    cdecl, dynlib: atklib, importc: "atk_table_get_selected_columns".}
proc atk_table_get_selected_rows*(table: PAtkTable, selected: PPgint): gint{.
    cdecl, dynlib: atklib, importc: "atk_table_get_selected_rows".}
proc atk_table_is_column_selected*(table: PAtkTable, column: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_table_is_column_selected".}
proc atk_table_is_row_selected*(table: PAtkTable, row: gint): gboolean{.cdecl,
    dynlib: atklib, importc: "atk_table_is_row_selected".}
proc atk_table_is_selected*(table: PAtkTable, row: gint, column: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_table_is_selected".}
proc atk_table_add_row_selection*(table: PAtkTable, row: gint): gboolean{.cdecl,
    dynlib: atklib, importc: "atk_table_add_row_selection".}
proc atk_table_remove_row_selection*(table: PAtkTable, row: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_table_remove_row_selection".}
proc atk_table_add_column_selection*(table: PAtkTable, column: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_table_add_column_selection".}
proc atk_table_remove_column_selection*(table: PAtkTable, column: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_table_remove_column_selection".}
proc atk_text_attribute_register*(name: cstring): TAtkTextAttribute{.cdecl,
    dynlib: atklib, importc: "atk_text_attribute_register".}
proc ATK_TYPE_TEXT*(): GType
proc ATK_IS_TEXT*(obj: pointer): bool
proc ATK_TEXT*(obj: pointer): PAtkText
proc ATK_TEXT_GET_IFACE*(obj: pointer): PAtkTextIface
proc atk_text_get_type*(): GType{.cdecl, dynlib: atklib,
                                  importc: "atk_text_get_type".}
proc atk_text_get_text*(text: PAtkText, start_offset: gint, end_offset: gint): cstring{.
    cdecl, dynlib: atklib, importc: "atk_text_get_text".}
proc atk_text_get_character_at_offset*(text: PAtkText, offset: gint): gunichar{.
    cdecl, dynlib: atklib, importc: "atk_text_get_character_at_offset".}
proc atk_text_get_text_after_offset*(text: PAtkText, offset: gint,
                                     boundary_type: TAtkTextBoundary,
                                     start_offset: Pgint, end_offset: Pgint): cstring{.
    cdecl, dynlib: atklib, importc: "atk_text_get_text_after_offset".}
proc atk_text_get_text_at_offset*(text: PAtkText, offset: gint,
                                  boundary_type: TAtkTextBoundary,
                                  start_offset: Pgint, end_offset: Pgint): cstring{.
    cdecl, dynlib: atklib, importc: "atk_text_get_text_at_offset".}
proc atk_text_get_text_before_offset*(text: PAtkText, offset: gint,
                                      boundary_type: TAtkTextBoundary,
                                      start_offset: Pgint, end_offset: Pgint): cstring{.
    cdecl, dynlib: atklib, importc: "atk_text_get_text_before_offset".}
proc atk_text_get_caret_offset*(text: PAtkText): gint{.cdecl, dynlib: atklib,
    importc: "atk_text_get_caret_offset".}
proc atk_text_get_character_extents*(text: PAtkText, offset: gint, x: Pgint,
                                     y: Pgint, width: Pgint, height: Pgint,
                                     coords: TAtkCoordType){.cdecl,
    dynlib: atklib, importc: "atk_text_get_character_extents".}
proc atk_text_get_run_attributes*(text: PAtkText, offset: gint,
                                  start_offset: Pgint, end_offset: Pgint): PAtkAttributeSet{.
    cdecl, dynlib: atklib, importc: "atk_text_get_run_attributes".}
proc atk_text_get_default_attributes*(text: PAtkText): PAtkAttributeSet{.cdecl,
    dynlib: atklib, importc: "atk_text_get_default_attributes".}
proc atk_text_get_character_count*(text: PAtkText): gint{.cdecl, dynlib: atklib,
    importc: "atk_text_get_character_count".}
proc atk_text_get_offset_at_point*(text: PAtkText, x: gint, y: gint,
                                   coords: TAtkCoordType): gint{.cdecl,
    dynlib: atklib, importc: "atk_text_get_offset_at_point".}
proc atk_text_get_n_selections*(text: PAtkText): gint{.cdecl, dynlib: atklib,
    importc: "atk_text_get_n_selections".}
proc atk_text_get_selection*(text: PAtkText, selection_num: gint,
                             start_offset: Pgint, end_offset: Pgint): cstring{.
    cdecl, dynlib: atklib, importc: "atk_text_get_selection".}
proc atk_text_add_selection*(text: PAtkText, start_offset: gint,
                             end_offset: gint): gboolean{.cdecl, dynlib: atklib,
    importc: "atk_text_add_selection".}
proc atk_text_remove_selection*(text: PAtkText, selection_num: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_text_remove_selection".}
proc atk_text_set_selection*(text: PAtkText, selection_num: gint,
                             start_offset: gint, end_offset: gint): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_text_set_selection".}
proc atk_text_set_caret_offset*(text: PAtkText, offset: gint): gboolean{.cdecl,
    dynlib: atklib, importc: "atk_text_set_caret_offset".}
proc atk_attribute_set_free*(attrib_set: PAtkAttributeSet){.cdecl,
    dynlib: atklib, importc: "atk_attribute_set_free".}
proc atk_text_attribute_get_name*(attr: TAtkTextAttribute): cstring{.cdecl,
    dynlib: atklib, importc: "atk_text_attribute_get_name".}
proc atk_text_attribute_for_name*(name: cstring): TAtkTextAttribute{.cdecl,
    dynlib: atklib, importc: "atk_text_attribute_for_name".}
proc atk_text_attribute_get_value*(attr: TAtkTextAttribute, index: gint): cstring{.
    cdecl, dynlib: atklib, importc: "atk_text_attribute_get_value".}
proc ATK_TYPE_UTIL*(): GType
proc ATK_IS_UTIL*(obj: pointer): bool
proc ATK_UTIL*(obj: pointer): PAtkUtil
proc ATK_UTIL_CLASS*(klass: pointer): PAtkUtilClass
proc ATK_IS_UTIL_CLASS*(klass: pointer): bool
proc ATK_UTIL_GET_CLASS*(obj: pointer): PAtkUtilClass
proc atk_util_get_type*(): GType{.cdecl, dynlib: atklib,
                                  importc: "atk_util_get_type".}
proc atk_add_focus_tracker*(focus_tracker: TAtkEventListener): guint{.cdecl,
    dynlib: atklib, importc: "atk_add_focus_tracker".}
proc atk_remove_focus_tracker*(tracker_id: guint){.cdecl, dynlib: atklib,
    importc: "atk_remove_focus_tracker".}
proc atk_focus_tracker_init*(add_function: TAtkEventListenerInit){.cdecl,
    dynlib: atklib, importc: "atk_focus_tracker_init".}
proc atk_focus_tracker_notify*(anObject: PAtkObject){.cdecl, dynlib: atklib,
    importc: "atk_focus_tracker_notify".}
proc atk_add_global_event_listener*(listener: TGSignalEmissionHook,
                                    event_type: cstring): guint{.cdecl,
    dynlib: atklib, importc: "atk_add_global_event_listener".}
proc atk_remove_global_event_listener*(listener_id: guint){.cdecl,
    dynlib: atklib, importc: "atk_remove_global_event_listener".}
proc atk_add_key_event_listener*(listener: TAtkKeySnoopFunc, data: gpointer): guint{.
    cdecl, dynlib: atklib, importc: "atk_add_key_event_listener".}
proc atk_remove_key_event_listener*(listener_id: guint){.cdecl, dynlib: atklib,
    importc: "atk_remove_key_event_listener".}
proc atk_get_root*(): PAtkObject{.cdecl, dynlib: atklib, importc: "atk_get_root".}
proc atk_get_toolkit_name*(): cstring{.cdecl, dynlib: atklib,
                                      importc: "atk_get_toolkit_name".}
proc atk_get_toolkit_version*(): cstring{.cdecl, dynlib: atklib,
    importc: "atk_get_toolkit_version".}
proc ATK_TYPE_VALUE*(): GType
proc ATK_IS_VALUE*(obj: pointer): bool
proc ATK_VALUE*(obj: pointer): PAtkValue
proc ATK_VALUE_GET_IFACE*(obj: pointer): PAtkValueIface
proc atk_value_get_type*(): GType{.cdecl, dynlib: atklib,
                                   importc: "atk_value_get_type".}
proc atk_value_get_current_value*(obj: PAtkValue, value: PGValue){.cdecl,
    dynlib: atklib, importc: "atk_value_get_current_value".}
proc atk_value_get_maximum_value*(obj: PAtkValue, value: PGValue){.cdecl,
    dynlib: atklib, importc: "atk_value_get_maximum_value".}
proc atk_value_get_minimum_value*(obj: PAtkValue, value: PGValue){.cdecl,
    dynlib: atklib, importc: "atk_value_get_minimum_value".}
proc atk_value_set_current_value*(obj: PAtkValue, value: PGValue): gboolean{.
    cdecl, dynlib: atklib, importc: "atk_value_set_current_value".}
proc ATK_TYPE_OBJECT*(): GType =
  result = atk_object_get_type()

proc ATK_OBJECT*(obj: pointer): PAtkObject =
  result = cast[PAtkObject](G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_OBJECT()))

proc ATK_OBJECT_CLASS*(klass: pointer): PAtkObjectClass =
  result = cast[PAtkObjectClass](G_TYPE_CHECK_CLASS_CAST(klass, ATK_TYPE_OBJECT()))

proc ATK_IS_OBJECT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_OBJECT())

proc ATK_IS_OBJECT_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, ATK_TYPE_OBJECT())

proc ATK_OBJECT_GET_CLASS*(obj: pointer): PAtkObjectClass =
  result = cast[PAtkObjectClass](G_TYPE_INSTANCE_GET_CLASS(obj, ATK_TYPE_OBJECT()))

proc ATK_TYPE_IMPLEMENTOR*(): GType =
  result = atk_implementor_get_type()

proc ATK_IS_IMPLEMENTOR*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_IMPLEMENTOR())

proc ATK_IMPLEMENTOR*(obj: pointer): PAtkImplementor =
  result = PAtkImplementor(G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_IMPLEMENTOR()))

proc ATK_IMPLEMENTOR_GET_IFACE*(obj: pointer): PAtkImplementorIface =
  result = cast[PAtkImplementorIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      ATK_TYPE_IMPLEMENTOR()))

proc ATK_TYPE_ACTION*(): GType =
  result = atk_action_get_type()

proc ATK_IS_ACTION*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_ACTION())

proc ATK_ACTION*(obj: pointer): PAtkAction =
  result = PAtkAction(G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_ACTION()))

proc ATK_ACTION_GET_IFACE*(obj: pointer): PAtkActionIface =
  result = cast[PAtkActionIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
    ATK_TYPE_ACTION()))

proc ATK_TYPE_COMPONENT*(): GType =
  result = atk_component_get_type()

proc ATK_IS_COMPONENT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_COMPONENT())

proc ATK_COMPONENT*(obj: pointer): PAtkComponent =
  result = PAtkComponent(G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_COMPONENT()))

proc ATK_COMPONENT_GET_IFACE*(obj: pointer): PAtkComponentIface =
  result = cast[PAtkComponentIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      ATK_TYPE_COMPONENT()))

proc ATK_TYPE_DOCUMENT*(): GType =
  result = atk_document_get_type()

proc ATK_IS_DOCUMENT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_DOCUMENT())

proc ATK_DOCUMENT*(obj: pointer): PAtkDocument =
  result = cast[PAtkDocument](G_TYPE_CHECK_INSTANCE_CAST(obj,
    ATK_TYPE_DOCUMENT()))

proc ATK_DOCUMENT_GET_IFACE*(obj: pointer): PAtkDocumentIface =
  result = cast[PAtkDocumentIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      ATK_TYPE_DOCUMENT()))

proc ATK_TYPE_EDITABLE_TEXT*(): GType =
  result = atk_editable_text_get_type()

proc ATK_IS_EDITABLE_TEXT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_EDITABLE_TEXT())

proc ATK_EDITABLE_TEXT*(obj: pointer): PAtkEditableText =
  result = cast[PAtkEditableText](G_TYPE_CHECK_INSTANCE_CAST(obj,
      ATK_TYPE_EDITABLE_TEXT()))

proc ATK_EDITABLE_TEXT_GET_IFACE*(obj: pointer): PAtkEditableTextIface =
  result = cast[PAtkEditableTextIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      ATK_TYPE_EDITABLE_TEXT()))

proc ATK_TYPE_GOBJECT_ACCESSIBLE*(): GType =
  result = atk_gobject_accessible_get_type()

proc ATK_GOBJECT_ACCESSIBLE*(obj: pointer): PAtkGObjectAccessible =
  result = cast[PAtkGObjectAccessible](G_TYPE_CHECK_INSTANCE_CAST(obj,
      ATK_TYPE_GOBJECT_ACCESSIBLE()))

proc ATK_GOBJECT_ACCESSIBLE_CLASS*(klass: pointer): PAtkGObjectAccessibleClass =
  result = cast[PAtkGObjectAccessibleClass](G_TYPE_CHECK_CLASS_CAST(klass,
      ATK_TYPE_GOBJECT_ACCESSIBLE()))

proc ATK_IS_GOBJECT_ACCESSIBLE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_GOBJECT_ACCESSIBLE())

proc ATK_IS_GOBJECT_ACCESSIBLE_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, ATK_TYPE_GOBJECT_ACCESSIBLE())

proc ATK_GOBJECT_ACCESSIBLE_GET_CLASS*(obj: pointer): PAtkGObjectAccessibleClass =
  result = cast[PAtkGObjectAccessibleClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      ATK_TYPE_GOBJECT_ACCESSIBLE()))

proc ATK_TYPE_HYPERLINK*(): GType =
  result = atk_hyperlink_get_type()

proc ATK_HYPERLINK*(obj: pointer): PAtkHyperlink =
  result = cast[PAtkHyperlink](G_TYPE_CHECK_INSTANCE_CAST(obj,
                              ATK_TYPE_HYPERLINK()))

proc ATK_HYPERLINK_CLASS*(klass: pointer): PAtkHyperlinkClass =
  result = cast[PAtkHyperlinkClass](G_TYPE_CHECK_CLASS_CAST(klass,
                                    ATK_TYPE_HYPERLINK()))

proc ATK_IS_HYPERLINK*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_HYPERLINK())

proc ATK_IS_HYPERLINK_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, ATK_TYPE_HYPERLINK())

proc ATK_HYPERLINK_GET_CLASS*(obj: pointer): PAtkHyperlinkClass =
  result = cast[PAtkHyperlinkClass](G_TYPE_INSTANCE_GET_CLASS(obj, ATK_TYPE_HYPERLINK()))

proc ATK_TYPE_HYPERTEXT*(): GType =
  result = atk_hypertext_get_type()

proc ATK_IS_HYPERTEXT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_HYPERTEXT())

proc ATK_HYPERTEXT*(obj: pointer): PAtkHypertext =
  result = cast[PAtkHypertext](G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_HYPERTEXT()))

proc ATK_HYPERTEXT_GET_IFACE*(obj: pointer): PAtkHypertextIface =
  result = cast[PAtkHypertextIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      ATK_TYPE_HYPERTEXT()))

proc ATK_TYPE_IMAGE*(): GType =
  result = atk_image_get_type()

proc ATK_IS_IMAGE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_IMAGE())

proc ATK_IMAGE*(obj: pointer): PAtkImage =
  result = cast[PAtkImage](G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_IMAGE()))

proc ATK_IMAGE_GET_IFACE*(obj: pointer): PAtkImageIface =
  result = cast[PAtkImageIface](G_TYPE_INSTANCE_GET_INTERFACE(obj, ATK_TYPE_IMAGE()))

proc ATK_TYPE_OBJECT_FACTORY*(): GType =
  result = atk_object_factory_get_type()

proc ATK_OBJECT_FACTORY*(obj: pointer): PAtkObjectFactory =
  result = cast[PAtkObjectFactory](G_TYPE_CHECK_INSTANCE_CAST(obj,
      ATK_TYPE_OBJECT_FACTORY()))

proc ATK_OBJECT_FACTORY_CLASS*(klass: pointer): PAtkObjectFactoryClass =
  result = cast[PAtkObjectFactoryClass](G_TYPE_CHECK_CLASS_CAST(klass,
      ATK_TYPE_OBJECT_FACTORY()))

proc ATK_IS_OBJECT_FACTORY*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_OBJECT_FACTORY())

proc ATK_IS_OBJECT_FACTORY_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, ATK_TYPE_OBJECT_FACTORY())

proc ATK_OBJECT_FACTORY_GET_CLASS*(obj: pointer): PAtkObjectFactoryClass =
  result = cast[PAtkObjectFactoryClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      ATK_TYPE_OBJECT_FACTORY()))

proc ATK_TYPE_REGISTRY*(): GType =
  result = atk_registry_get_type()

proc ATK_REGISTRY*(obj: pointer): PAtkRegistry =
  result = cast[PAtkRegistry](G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_REGISTRY()))

proc ATK_REGISTRY_CLASS*(klass: pointer): PAtkRegistryClass =
  result = cast[PAtkRegistryClass](G_TYPE_CHECK_CLASS_CAST(klass,
                                   ATK_TYPE_REGISTRY()))

proc ATK_IS_REGISTRY*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_REGISTRY())

proc ATK_IS_REGISTRY_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, ATK_TYPE_REGISTRY())

proc ATK_REGISTRY_GET_CLASS*(obj: pointer): PAtkRegistryClass =
  result = cast[PAtkRegistryClass](G_TYPE_INSTANCE_GET_CLASS(obj, ATK_TYPE_REGISTRY()))

proc ATK_TYPE_RELATION*(): GType =
  result = atk_relation_get_type()

proc ATK_RELATION*(obj: pointer): PAtkRelation =
  result = cast[PAtkRelation](G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_RELATION()))

proc ATK_RELATION_CLASS*(klass: pointer): PAtkRelationClass =
  result = cast[PAtkRelationClass](G_TYPE_CHECK_CLASS_CAST(klass, ATK_TYPE_RELATION()))

proc ATK_IS_RELATION*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_RELATION())

proc ATK_IS_RELATION_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, ATK_TYPE_RELATION())

proc ATK_RELATION_GET_CLASS*(obj: pointer): PAtkRelationClass =
  result = cast[PAtkRelationClass](G_TYPE_INSTANCE_GET_CLASS(obj,
    ATK_TYPE_RELATION()))

proc ATK_TYPE_RELATION_SET*(): GType =
  result = atk_relation_set_get_type()

proc ATK_RELATION_SET*(obj: pointer): PAtkRelationSet =
  result = cast[PAtkRelationSet](G_TYPE_CHECK_INSTANCE_CAST(obj,
    ATK_TYPE_RELATION_SET()))

proc ATK_RELATION_SET_CLASS*(klass: pointer): PAtkRelationSetClass =
  result = cast[PAtkRelationSetClass](G_TYPE_CHECK_CLASS_CAST(klass,
      ATK_TYPE_RELATION_SET()))

proc ATK_IS_RELATION_SET*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_RELATION_SET())

proc ATK_IS_RELATION_SET_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, ATK_TYPE_RELATION_SET())

proc ATK_RELATION_SET_GET_CLASS*(obj: pointer): PAtkRelationSetClass =
  result = cast[PAtkRelationSetClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      ATK_TYPE_RELATION_SET()))

proc ATK_TYPE_SELECTION*(): GType =
  result = atk_selection_get_type()

proc ATK_IS_SELECTION*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_SELECTION())

proc ATK_SELECTION*(obj: pointer): PAtkSelection =
  result = cast[PAtkSelection](G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_SELECTION()))

proc ATK_SELECTION_GET_IFACE*(obj: pointer): PAtkSelectionIface =
  result = cast[PAtkSelectionIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      ATK_TYPE_SELECTION()))

proc ATK_TYPE_STATE_SET*(): GType =
  result = atk_state_set_get_type()

proc ATK_STATE_SET*(obj: pointer): PAtkStateSet =
  result = cast[PAtkStateSet](G_TYPE_CHECK_INSTANCE_CAST(obj,
    ATK_TYPE_STATE_SET()))

proc ATK_STATE_SET_CLASS*(klass: pointer): PAtkStateSetClass =
  result = cast[PAtkStateSetClass](G_TYPE_CHECK_CLASS_CAST(klass,
    ATK_TYPE_STATE_SET()))

proc ATK_IS_STATE_SET*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_STATE_SET())

proc ATK_IS_STATE_SET_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, ATK_TYPE_STATE_SET())

proc ATK_STATE_SET_GET_CLASS*(obj: pointer): PAtkStateSetClass =
  result = cast[PAtkStateSetClass](G_TYPE_INSTANCE_GET_CLASS(obj,
    ATK_TYPE_STATE_SET()))

proc ATK_TYPE_STREAMABLE_CONTENT*(): GType =
  result = atk_streamable_content_get_type()

proc ATK_IS_STREAMABLE_CONTENT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_STREAMABLE_CONTENT())

proc ATK_STREAMABLE_CONTENT*(obj: pointer): PAtkStreamableContent =
  result = cast[PAtkStreamableContent](G_TYPE_CHECK_INSTANCE_CAST(obj,
      ATK_TYPE_STREAMABLE_CONTENT()))

proc ATK_STREAMABLE_CONTENT_GET_IFACE*(obj: pointer): PAtkStreamableContentIface =
  result = cast[PAtkStreamableContentIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      ATK_TYPE_STREAMABLE_CONTENT()))

proc ATK_TYPE_TABLE*(): GType =
  result = atk_table_get_type()

proc ATK_IS_TABLE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_TABLE())

proc ATK_TABLE*(obj: pointer): PAtkTable =
  result = cast[PAtkTable](G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_TABLE()))

proc ATK_TABLE_GET_IFACE*(obj: pointer): PAtkTableIface =
  result = cast[PAtkTableIface](G_TYPE_INSTANCE_GET_INTERFACE(obj, ATK_TYPE_TABLE()))

proc ATK_TYPE_TEXT*(): GType =
  result = atk_text_get_type()

proc ATK_IS_TEXT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_TEXT())

proc ATK_TEXT*(obj: pointer): PAtkText =
  result = cast[PAtkText](G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_TEXT()))

proc ATK_TEXT_GET_IFACE*(obj: pointer): PAtkTextIface =
  result = cast[PAtkTextIface](G_TYPE_INSTANCE_GET_INTERFACE(obj, ATK_TYPE_TEXT()))

proc ATK_TYPE_UTIL*(): GType =
  result = atk_util_get_type()

proc ATK_IS_UTIL*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_UTIL())

proc ATK_UTIL*(obj: pointer): PAtkUtil =
  result = cast[PAtkUtil](G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_UTIL()))

proc ATK_UTIL_CLASS*(klass: pointer): PAtkUtilClass =
  result = cast[PAtkUtilClass](G_TYPE_CHECK_CLASS_CAST(klass, ATK_TYPE_UTIL()))

proc ATK_IS_UTIL_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, ATK_TYPE_UTIL())

proc ATK_UTIL_GET_CLASS*(obj: pointer): PAtkUtilClass =
  result = cast[PAtkUtilClass](G_TYPE_INSTANCE_GET_CLASS(obj, ATK_TYPE_UTIL()))

proc ATK_TYPE_VALUE*(): GType =
  result = atk_value_get_type()

proc ATK_IS_VALUE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, ATK_TYPE_VALUE())

proc ATK_VALUE*(obj: pointer): PAtkValue =
  result = cast[PAtkValue](G_TYPE_CHECK_INSTANCE_CAST(obj, ATK_TYPE_VALUE()))

proc ATK_VALUE_GET_IFACE*(obj: pointer): PAtkValueIface =
  result = cast[PAtkValueIface](G_TYPE_INSTANCE_GET_INTERFACE(obj, ATK_TYPE_VALUE()))
