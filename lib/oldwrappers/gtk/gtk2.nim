{.deadCodeElim: on.}

import
  glib2, atk, pango, gdk2pixbuf, gdk2

when defined(win32):
  const
    gtklib = "libgtk-win32-2.0-0.dll"
elif defined(darwin):
  const
    gtklib = "gtk-x11-2.0"
  # linklib gtk-x11-2.0
  # linklib gdk-x11-2.0
  # linklib pango-1.0.0
  # linklib glib-2.0.0
  # linklib gobject-2.0.0
  # linklib gdk_pixbuf-2.0.0
  # linklib atk-1.0.0
else:
  const
    gtklib = "libgtk-x11-2.0.so"
type
  PPPchar* = PPPgchar

const
  GTK_MAX_COMPOSE_LEN* = 7

type
  PGtkObject* = ptr TGtkObject
  PPGtkObject* = ptr PGtkObject
  PGtkArg* = ptr TGtkArg
  PGtkType* = ptr TGtkType
  TGtkType* = GType
  PGtkWidget* = ptr TGtkWidget
  PGtkMisc* = ptr TGtkMisc
  PGtkLabel* = ptr TGtkLabel
  PGtkMenu* = ptr TGtkMenu
  PGtkAnchorType* = ptr TGtkAnchorType
  TGtkAnchorType* = int32
  PGtkArrowType* = ptr TGtkArrowType
  TGtkArrowType* = int32
  PGtkAttachOptions* = ptr TGtkAttachOptions
  TGtkAttachOptions* = int32
  PGtkButtonBoxStyle* = ptr TGtkButtonBoxStyle
  TGtkButtonBoxStyle* = int32
  PGtkCurveType* = ptr TGtkCurveType
  TGtkCurveType* = int32
  PGtkDeleteType* = ptr TGtkDeleteType
  TGtkDeleteType* = int32
  PGtkDirectionType* = ptr TGtkDirectionType
  TGtkDirectionType* = int32
  PGtkExpanderStyle* = ptr TGtkExpanderStyle
  TGtkExpanderStyle* = int32
  PPGtkIconSize* = ptr PGtkIconSize
  PGtkIconSize* = ptr TGtkIconSize
  TGtkIconSize* = int32
  PGtkTextDirection* = ptr TGtkTextDirection
  TGtkTextDirection* = int32
  PGtkJustification* = ptr TGtkJustification
  TGtkJustification* = int32
  PGtkMenuDirectionType* = ptr TGtkMenuDirectionType
  TGtkMenuDirectionType* = int32
  PGtkMetricType* = ptr TGtkMetricType
  TGtkMetricType* = int32
  PGtkMovementStep* = ptr TGtkMovementStep
  TGtkMovementStep* = int32
  PGtkOrientation* = ptr TGtkOrientation
  TGtkOrientation* = int32
  PGtkCornerType* = ptr TGtkCornerType
  TGtkCornerType* = int32
  PGtkPackType* = ptr TGtkPackType
  TGtkPackType* = int32
  PGtkPathPriorityType* = ptr TGtkPathPriorityType
  TGtkPathPriorityType* = int32
  PGtkPathType* = ptr TGtkPathType
  TGtkPathType* = int32
  PGtkPolicyType* = ptr TGtkPolicyType
  TGtkPolicyType* = int32
  PGtkPositionType* = ptr TGtkPositionType
  TGtkPositionType* = int32
  PGtkReliefStyle* = ptr TGtkReliefStyle
  TGtkReliefStyle* = int32
  PGtkResizeMode* = ptr TGtkResizeMode
  TGtkResizeMode* = int32
  PGtkScrollType* = ptr TGtkScrollType
  TGtkScrollType* = int32
  PGtkSelectionMode* = ptr TGtkSelectionMode
  TGtkSelectionMode* = int32
  PGtkShadowType* = ptr TGtkShadowType
  TGtkShadowType* = int32
  PGtkStateType* = ptr TGtkStateType
  TGtkStateType* = int32
  PGtkSubmenuDirection* = ptr TGtkSubmenuDirection
  TGtkSubmenuDirection* = int32
  PGtkSubmenuPlacement* = ptr TGtkSubmenuPlacement
  TGtkSubmenuPlacement* = int32
  PGtkToolbarStyle* = ptr TGtkToolbarStyle
  TGtkToolbarStyle* = int32
  PGtkUpdateType* = ptr TGtkUpdateType
  TGtkUpdateType* = int32
  PGtkVisibility* = ptr TGtkVisibility
  TGtkVisibility* = int32
  PGtkWindowPosition* = ptr TGtkWindowPosition
  TGtkWindowPosition* = int32
  PGtkWindowType* = ptr TGtkWindowType
  TGtkWindowType* = int32
  PGtkWrapMode* = ptr TGtkWrapMode
  TGtkWrapMode* = int32
  PGtkSortType* = ptr TGtkSortType
  TGtkSortType* = int32
  PGtkStyle* = ptr TGtkStyle
  PPGtkTreeModel* = ptr PGtkTreeModel
  PGtkTreeModel* = pointer
  PGtkTreePath* = pointer
  PGtkTreeIter* = ptr TGtkTreeIter
  PGtkSelectionData* = ptr TGtkSelectionData
  PGtkTextTagTable* = ptr TGtkTextTagTable
  PGtkTextBTreeNode* = pointer
  PGtkTextBTree* = pointer
  PGtkTextLine* = ptr TGtkTextLine
  PGtkTreeViewColumn* = ptr TGtkTreeViewColumn
  PGtkTreeView* = ptr TGtkTreeView
  TGtkTreeViewColumnDropFunc* = proc (tree_view: PGtkTreeView,
                                      column: PGtkTreeViewColumn,
                                      prev_column: PGtkTreeViewColumn,
                                      next_column: PGtkTreeViewColumn,
                                      data: gpointer): gboolean{.cdecl.}
  TGtkTreeViewMappingFunc* = proc (tree_view: PGtkTreeView, path: PGtkTreePath,
                                   user_data: gpointer){.cdecl.}
  TGtkTreeViewSearchEqualFunc* = proc (model: PGtkTreeModel, column: gint,
                                       key: cstring, iter: PGtkTreeIter,
                                       search_data: gpointer): gboolean{.cdecl.}
  TGtkTreeDestroyCountFunc* = proc (tree_view: PGtkTreeView, path: PGtkTreePath,
                                    children: gint, user_data: gpointer){.cdecl.}
  PGtkTreeViewDropPosition* = ptr TGtkTreeViewDropPosition
  TGtkTreeViewDropPosition* = enum
    GTK_TREE_VIEW_DROP_BEFORE, GTK_TREE_VIEW_DROP_AFTER,
    GTK_TREE_VIEW_DROP_INTO_OR_BEFORE, GTK_TREE_VIEW_DROP_INTO_OR_AFTER
  PGtkObjectFlags* = ptr TGtkObjectFlags
  TGtkObjectFlags* = int32
  TGtkObject* = object of TGObject
    flags*: guint32

  PGtkObjectClass* = ptr TGtkObjectClass
  TGtkObjectClass* = object of TGObjectClass
    set_arg*: proc (anObject: PGtkObject, arg: PGtkArg, arg_id: guint){.cdecl.}
    get_arg*: proc (anObject: PGtkObject, arg: PGtkArg, arg_id: guint){.cdecl.}
    destroy*: proc (anObject: PGtkObject){.cdecl.}

  PGtkFundamentalType* = ptr TGtkFundamentalType
  TGtkFundamentalType* = GType
  TGtkFunction* = proc (data: gpointer): gboolean{.cdecl.}
  TGtkDestroyNotify* = proc (data: gpointer){.cdecl.}
  TGtkCallbackMarshal* = proc (anObject: PGtkObject, data: gpointer,
                               n_args: guint, args: PGtkArg){.cdecl.}
  TGtkSignalFuncProc* = proc ()
  TGtkSignalFunc* = proc (para1: TGtkSignalFuncProc){.cdecl.}
  PGtkSignalMarshaller* = ptr TGtkSignalMarshaller
  TGtkSignalMarshaller* = TGSignalCMarshaller
  TGtkArgSignalData* {.final, pure.} = object
    f*: TGtkSignalFunc
    d*: gpointer

  TGtkArg* {.final, pure.} = object
    `type`*: TGtkType
    name*: cstring
    d*: gdouble               # was a union type

  PGtkTypeInfo* = ptr TGtkTypeInfo
  TGtkTypeInfo* {.final, pure.} = object
    type_name*: cstring
    object_size*: guint
    class_size*: guint
    class_init_func*: pointer #TGtkClassInitFunc
    object_init_func*: pointer #TGtkObjectInitFunc
    reserved_1*: gpointer
    reserved_2*: gpointer
    base_class_init_func*: pointer #TGtkClassInitFunc

  PGtkEnumValue* = ptr TGtkEnumValue
  TGtkEnumValue* = TGEnumValue
  PGtkFlagValue* = ptr TGtkFlagValue
  TGtkFlagValue* = TGFlagsValue
  PGtkWidgetFlags* = ptr TGtkWidgetFlags
  TGtkWidgetFlags* = int32
  PGtkWidgetHelpType* = ptr TGtkWidgetHelpType
  TGtkWidgetHelpType* = enum
    GTK_WIDGET_HELP_TOOLTIP, GTK_WIDGET_HELP_WHATS_THIS
  PGtkAllocation* = ptr TGtkAllocation
  TGtkAllocation* = TGdkRectangle
  TGtkCallback* = proc (widget: PGtkWidget, data: gpointer){.cdecl.}
  PGtkRequisition* = ptr TGtkRequisition
  TGtkRequisition* {.final, pure.} = object
    width*: gint
    height*: gint

  TGtkWidget* = object of TGtkObject
    private_flags*: guint16
    state*: guint8
    saved_state*: guint8
    name*: cstring
    style*: PGtkStyle
    requisition*: TGtkRequisition
    allocation*: TGtkAllocation
    window*: PGdkWindow
    parent*: PGtkWidget

  PGtkWidgetClass* = ptr TGtkWidgetClass
  TGtkWidgetClass* = object of TGtkObjectClass
    activate_signal*: guint
    set_scroll_adjustments_signal*: guint
    dispatch_child_properties_changed*: proc (widget: PGtkWidget,
        n_pspecs: guint, pspecs: PPGParamSpec){.cdecl.}
    show*: proc (widget: PGtkWidget){.cdecl.}
    show_all*: proc (widget: PGtkWidget){.cdecl.}
    hide*: proc (widget: PGtkWidget){.cdecl.}
    hide_all*: proc (widget: PGtkWidget){.cdecl.}
    map*: proc (widget: PGtkWidget){.cdecl.}
    unmap*: proc (widget: PGtkWidget){.cdecl.}
    realize*: proc (widget: PGtkWidget){.cdecl.}
    unrealize*: proc (widget: PGtkWidget){.cdecl.}
    size_request*: proc (widget: PGtkWidget, requisition: PGtkRequisition){.
        cdecl.}
    size_allocate*: proc (widget: PGtkWidget, allocation: PGtkAllocation){.cdecl.}
    state_changed*: proc (widget: PGtkWidget, previous_state: TGtkStateType){.
        cdecl.}
    parent_set*: proc (widget: PGtkWidget, previous_parent: PGtkWidget){.cdecl.}
    hierarchy_changed*: proc (widget: PGtkWidget, previous_toplevel: PGtkWidget){.
        cdecl.}
    style_set*: proc (widget: PGtkWidget, previous_style: PGtkStyle){.cdecl.}
    direction_changed*: proc (widget: PGtkWidget,
                              previous_direction: TGtkTextDirection){.cdecl.}
    grab_notify*: proc (widget: PGtkWidget, was_grabbed: gboolean){.cdecl.}
    child_notify*: proc (widget: PGtkWidget, pspec: PGParamSpec){.cdecl.}
    mnemonic_activate*: proc (widget: PGtkWidget, group_cycling: gboolean): gboolean{.
        cdecl.}
    grab_focus*: proc (widget: PGtkWidget){.cdecl.}
    focus*: proc (widget: PGtkWidget, direction: TGtkDirectionType): gboolean{.
        cdecl.}
    event*: proc (widget: PGtkWidget, event: PGdkEvent): gboolean{.cdecl.}
    button_press_event*: proc (widget: PGtkWidget, event: PGdkEventButton): gboolean{.
        cdecl.}
    button_release_event*: proc (widget: PGtkWidget, event: PGdkEventButton): gboolean{.
        cdecl.}
    scroll_event*: proc (widget: PGtkWidget, event: PGdkEventScroll): gboolean{.
        cdecl.}
    motion_notify_event*: proc (widget: PGtkWidget, event: PGdkEventMotion): gboolean{.
        cdecl.}
    delete_event*: proc (widget: PGtkWidget, event: PGdkEventAny): gboolean{.
        cdecl.}
    destroy_event*: proc (widget: PGtkWidget, event: PGdkEventAny): gboolean{.
        cdecl.}
    expose_event*: proc (widget: PGtkWidget, event: PGdkEventExpose): gboolean{.
        cdecl.}
    key_press_event*: proc (widget: PGtkWidget, event: PGdkEventKey): gboolean{.
        cdecl.}
    key_release_event*: proc (widget: PGtkWidget, event: PGdkEventKey): gboolean{.
        cdecl.}
    enter_notify_event*: proc (widget: PGtkWidget, event: PGdkEventCrossing): gboolean{.
        cdecl.}
    leave_notify_event*: proc (widget: PGtkWidget, event: PGdkEventCrossing): gboolean{.
        cdecl.}
    configure_event*: proc (widget: PGtkWidget, event: PGdkEventConfigure): gboolean{.
        cdecl.}
    focus_in_event*: proc (widget: PGtkWidget, event: PGdkEventFocus): gboolean{.
        cdecl.}
    focus_out_event*: proc (widget: PGtkWidget, event: PGdkEventFocus): gboolean{.
        cdecl.}
    map_event*: proc (widget: PGtkWidget, event: PGdkEventAny): gboolean{.cdecl.}
    unmap_event*: proc (widget: PGtkWidget, event: PGdkEventAny): gboolean{.
        cdecl.}
    property_notify_event*: proc (widget: PGtkWidget, event: PGdkEventProperty): gboolean{.
        cdecl.}
    selection_clear_event*: proc (widget: PGtkWidget, event: PGdkEventSelection): gboolean{.
        cdecl.}
    selection_request_event*: proc (widget: PGtkWidget,
                                    event: PGdkEventSelection): gboolean{.cdecl.}
    selection_notify_event*: proc (widget: PGtkWidget, event: PGdkEventSelection): gboolean{.
        cdecl.}
    proximity_in_event*: proc (widget: PGtkWidget, event: PGdkEventProximity): gboolean{.
        cdecl.}
    proximity_out_event*: proc (widget: PGtkWidget, event: PGdkEventProximity): gboolean{.
        cdecl.}
    visibility_notify_event*: proc (widget: PGtkWidget,
                                    event: PGdkEventVisibility): gboolean{.cdecl.}
    client_event*: proc (widget: PGtkWidget, event: PGdkEventClient): gboolean{.
        cdecl.}
    no_expose_event*: proc (widget: PGtkWidget, event: PGdkEventAny): gboolean{.
        cdecl.}
    window_state_event*: proc (widget: PGtkWidget, event: PGdkEventWindowState): gboolean{.
        cdecl.}
    selection_get*: proc (widget: PGtkWidget, selection_data: PGtkSelectionData,
                          info: guint, time: guint){.cdecl.}
    selection_received*: proc (widget: PGtkWidget,
                               selection_data: PGtkSelectionData, time: guint){.
        cdecl.}
    drag_begin*: proc (widget: PGtkWidget, context: PGdkDragContext){.cdecl.}
    drag_end*: proc (widget: PGtkWidget, context: PGdkDragContext){.cdecl.}
    drag_data_get*: proc (widget: PGtkWidget, context: PGdkDragContext,
                          selection_data: PGtkSelectionData, info: guint,
                          time: guint){.cdecl.}
    drag_data_delete*: proc (widget: PGtkWidget, context: PGdkDragContext){.
        cdecl.}
    drag_leave*: proc (widget: PGtkWidget, context: PGdkDragContext, time: guint){.
        cdecl.}
    drag_motion*: proc (widget: PGtkWidget, context: PGdkDragContext, x: gint,
                        y: gint, time: guint): gboolean{.cdecl.}
    drag_drop*: proc (widget: PGtkWidget, context: PGdkDragContext, x: gint,
                      y: gint, time: guint): gboolean{.cdecl.}
    drag_data_received*: proc (widget: PGtkWidget, context: PGdkDragContext,
                               x: gint, y: gint,
                               selection_data: PGtkSelectionData, info: guint,
                               time: guint){.cdecl.}
    popup_menu*: proc (widget: PGtkWidget): gboolean{.cdecl.}
    show_help*: proc (widget: PGtkWidget, help_type: TGtkWidgetHelpType): gboolean{.
        cdecl.}
    get_accessible*: proc (widget: PGtkWidget): PAtkObject{.cdecl.}
    gtk_reserved1: proc (){.cdecl.}
    gtk_reserved2: proc (){.cdecl.}
    gtk_reserved3: proc (){.cdecl.}
    gtk_reserved4: proc (){.cdecl.}
    gtk_reserved5*: proc (){.cdecl.}
    gtk_reserved6*: proc (){.cdecl.}
    gtk_reserved7*: proc (){.cdecl.}
    gtk_reserved8*: proc (){.cdecl.}

  PGtkWidgetAuxInfo* = ptr TGtkWidgetAuxInfo
  TGtkWidgetAuxInfo* {.final, pure.} = object
    x*: gint
    y*: gint
    width*: gint
    height*: gint
    flag0*: guint16

  PGtkWidgetShapeInfo* = ptr TGtkWidgetShapeInfo
  TGtkWidgetShapeInfo* {.final, pure.} = object
    offset_x*: gint16
    offset_y*: gint16
    shape_mask*: PGdkBitmap

  TGtkMisc* = object of TGtkWidget
    xalign*: gfloat
    yalign*: gfloat
    xpad*: guint16
    ypad*: guint16

  PGtkMiscClass* = ptr TGtkMiscClass
  TGtkMiscClass* = object of TGtkWidgetClass

  PGtkAccelFlags* = ptr TGtkAccelFlags
  TGtkAccelFlags* = int32
  PGtkAccelGroup* = ptr TGtkAccelGroup
  PGtkAccelGroupEntry* = ptr TGtkAccelGroupEntry
  TGtkAccelGroupActivate* = proc (accel_group: PGtkAccelGroup,
                                  acceleratable: PGObject, keyval: guint,
                                  modifier: TGdkModifierType): gboolean{.cdecl.}
  TGtkAccelGroup* = object of TGObject
    lock_count*: guint
    modifier_mask*: TGdkModifierType
    acceleratables*: PGSList
    n_accels*: guint
    priv_accels*: PGtkAccelGroupEntry

  PGtkAccelGroupClass* = ptr TGtkAccelGroupClass
  TGtkAccelGroupClass* = object of TGObjectClass
    accel_changed*: proc (accel_group: PGtkAccelGroup, keyval: guint,
                          modifier: TGdkModifierType, accel_closure: PGClosure){.
        cdecl.}
    gtk_reserved1: proc (){.cdecl.}
    gtk_reserved2: proc (){.cdecl.}
    gtk_reserved3: proc (){.cdecl.}
    gtk_reserved4: proc (){.cdecl.}

  PGtkAccelKey* = ptr TGtkAccelKey
  TGtkAccelKey* {.final, pure.} = object
    accel_key*: guint
    accel_mods*: TGdkModifierType
    flag0*: guint16

  TGtkAccelGroupEntry* {.final, pure.} = object
    key*: TGtkAccelKey
    closure*: PGClosure
    accel_path_quark*: TGQuark

  Tgtk_accel_group_find_func* = proc (key: PGtkAccelKey, closure: PGClosure,
                                      data: gpointer): gboolean{.cdecl.}
  PGtkContainer* = ptr TGtkContainer
  TGtkContainer* = object of TGtkWidget
    focus_child*: PGtkWidget
    GtkContainer_flag0*: int32

  PGtkContainerClass* = ptr TGtkContainerClass
  TGtkContainerClass* = object of TGtkWidgetClass
    add*: proc (container: PGtkContainer, widget: PGtkWidget){.cdecl.}
    remove*: proc (container: PGtkContainer, widget: PGtkWidget){.cdecl.}
    check_resize*: proc (container: PGtkContainer){.cdecl.}
    forall*: proc (container: PGtkContainer, include_internals: gboolean,
                   callback: TGtkCallback, callback_data: gpointer){.cdecl.}
    set_focus_child*: proc (container: PGtkContainer, widget: PGtkWidget){.cdecl.}
    child_type*: proc (container: PGtkContainer): TGtkType{.cdecl.}
    composite_name*: proc (container: PGtkContainer, child: PGtkWidget): cstring{.
        cdecl.}
    set_child_property*: proc (container: PGtkContainer, child: PGtkWidget,
                               property_id: guint, value: PGValue,
                               pspec: PGParamSpec){.cdecl.}
    get_child_property*: proc (container: PGtkContainer, child: PGtkWidget,
                               property_id: guint, value: PGValue,
                               pspec: PGParamSpec){.cdecl.}
    gtk_reserved20: proc (){.cdecl.}
    gtk_reserved21: proc (){.cdecl.}
    gtk_reserved23: proc (){.cdecl.}
    gtk_reserved24: proc (){.cdecl.}

  PGtkBin* = ptr TGtkBin
  TGtkBin* = object of TGtkContainer
    child*: PGtkWidget

  PGtkBinClass* = ptr TGtkBinClass
  TGtkBinClass* = object of TGtkContainerClass

  PGtkWindowGeometryInfo* = pointer
  PGtkWindowGroup* = ptr TGtkWindowGroup
  PGtkWindow* = ptr TGtkWindow
  TGtkWindow* = object of TGtkBin
    title*: cstring
    wmclass_name*: cstring
    wmclass_class*: cstring
    wm_role*: cstring
    focus_widget*: PGtkWidget
    default_widget*: PGtkWidget
    transient_parent*: PGtkWindow
    geometry_info*: PGtkWindowGeometryInfo
    frame*: PGdkWindow
    group*: PGtkWindowGroup
    configure_request_count*: guint16
    gtkwindow_flag0*: int32
    frame_left*: guint
    frame_top*: guint
    frame_right*: guint
    frame_bottom*: guint
    keys_changed_handler*: guint
    mnemonic_modifier*: TGdkModifierType
    screen*: PGdkScreen

  PGtkWindowClass* = ptr TGtkWindowClass
  TGtkWindowClass* = object of TGtkBinClass
    set_focus*: proc (window: PGtkWindow, focus: PGtkWidget){.cdecl.}
    frame_event*: proc (window: PGtkWindow, event: PGdkEvent): gboolean{.cdecl.}
    activate_focus*: proc (window: PGtkWindow){.cdecl.}
    activate_default*: proc (window: PGtkWindow){.cdecl.}
    move_focus*: proc (window: PGtkWindow, direction: TGtkDirectionType){.cdecl.}
    keys_changed*: proc (window: PGtkWindow){.cdecl.}
    gtk_reserved30: proc (){.cdecl.}
    gtk_reserved31: proc (){.cdecl.}
    gtk_reserved32: proc (){.cdecl.}
    gtk_reserved33: proc (){.cdecl.}

  TGtkWindowGroup* = object of TGObject
    grabs*: PGSList

  PGtkWindowGroupClass* = ptr TGtkWindowGroupClass
  TGtkWindowGroupClass* = object of TGObjectClass
    gtk_reserved40: proc (){.cdecl.}
    gtk_reserved41: proc (){.cdecl.}
    gtk_reserved42: proc (){.cdecl.}
    gtk_reserved43: proc (){.cdecl.}

  TGtkWindowKeysForeachFunc* = proc (window: PGtkWindow, keyval: guint,
                                     modifiers: TGdkModifierType,
                                     is_mnemonic: gboolean, data: gpointer){.
      cdecl.}
  PGtkLabelSelectionInfo* = pointer
  TGtkLabel* = object of TGtkMisc
    `label`*: cstring
    GtkLabel_flag0*: guint16
    mnemonic_keyval*: guint
    text*: cstring
    attrs*: PPangoAttrList
    effective_attrs*: PPangoAttrList
    layout*: PPangoLayout
    mnemonic_widget*: PGtkWidget
    mnemonic_window*: PGtkWindow
    select_info*: PGtkLabelSelectionInfo

  PGtkLabelClass* = ptr TGtkLabelClass
  TGtkLabelClass* = object of TGtkMiscClass
    move_cursor*: proc (`label`: PGtkLabel, step: TGtkMovementStep, count: gint,
                        extend_selection: gboolean){.cdecl.}
    copy_clipboard*: proc (`label`: PGtkLabel){.cdecl.}
    populate_popup*: proc (`label`: PGtkLabel, menu: PGtkMenu){.cdecl.}
    gtk_reserved50: proc (){.cdecl.}
    gtk_reserved51: proc (){.cdecl.}
    gtk_reserved52: proc (){.cdecl.}
    gtk_reserved53: proc (){.cdecl.}

  PGtkAccelLabel* = ptr TGtkAccelLabel
  TGtkAccelLabel* = object of TGtkLabel
    queue_id*: guint
    accel_padding*: guint
    accel_widget*: PGtkWidget
    accel_closure*: PGClosure
    accel_group*: PGtkAccelGroup
    accel_string*: cstring
    accel_string_width*: guint16

  PGtkAccelLabelClass* = ptr TGtkAccelLabelClass
  TGtkAccelLabelClass* = object of TGtkLabelClass
    signal_quote1*: cstring
    signal_quote2*: cstring
    mod_name_shift*: cstring
    mod_name_control*: cstring
    mod_name_alt*: cstring
    mod_separator*: cstring
    accel_seperator*: cstring
    GtkAccelLabelClass_flag0*: guint16
    gtk_reserved61: proc (){.cdecl.}
    gtk_reserved62: proc (){.cdecl.}
    gtk_reserved63: proc (){.cdecl.}
    gtk_reserved64: proc (){.cdecl.}

  TGtkAccelMapForeach* = proc (data: gpointer, accel_path: cstring,
                               accel_key: guint, accel_mods: TGdkModifierType,
                               changed: gboolean){.cdecl.}
  PGtkAccessible* = ptr TGtkAccessible
  TGtkAccessible* = object of TAtkObject
    widget*: PGtkWidget

  PGtkAccessibleClass* = ptr TGtkAccessibleClass
  TGtkAccessibleClass* = object of TAtkObjectClass
    connect_widget_destroyed*: proc (accessible: PGtkAccessible){.cdecl.}
    gtk_reserved71: proc (){.cdecl.}
    gtk_reserved72: proc (){.cdecl.}
    gtk_reserved73: proc (){.cdecl.}
    gtk_reserved74: proc (){.cdecl.}

  PGtkAdjustment* = ptr TGtkAdjustment
  TGtkAdjustment* = object of TGtkObject
    lower*: gdouble
    upper*: gdouble
    value*: gdouble
    step_increment*: gdouble
    page_increment*: gdouble
    page_size*: gdouble

  PGtkAdjustmentClass* = ptr TGtkAdjustmentClass
  TGtkAdjustmentClass* = object of TGtkObjectClass
    changed*: proc (adjustment: PGtkAdjustment){.cdecl.}
    value_changed*: proc (adjustment: PGtkAdjustment){.cdecl.}
    gtk_reserved81: proc (){.cdecl.}
    gtk_reserved82: proc (){.cdecl.}
    gtk_reserved83: proc (){.cdecl.}
    gtk_reserved84: proc (){.cdecl.}

  PGtkAlignment* = ptr TGtkAlignment
  TGtkAlignment* = object of TGtkBin
    xalign*: gfloat
    yalign*: gfloat
    xscale*: gfloat
    yscale*: gfloat

  PGtkAlignmentClass* = ptr TGtkAlignmentClass
  TGtkAlignmentClass* = object of TGtkBinClass

  PGtkFrame* = ptr TGtkFrame
  TGtkFrame* = object of TGtkBin
    label_widget*: PGtkWidget
    shadow_type*: gint16
    label_xalign*: gfloat
    label_yalign*: gfloat
    child_allocation*: TGtkAllocation

  PGtkFrameClass* = ptr TGtkFrameClass
  TGtkFrameClass* = object of TGtkBinClass
    compute_child_allocation*: proc (frame: PGtkFrame,
                                     allocation: PGtkAllocation){.cdecl.}

  PGtkAspectFrame* = ptr TGtkAspectFrame
  TGtkAspectFrame* = object of TGtkFrame
    xalign*: gfloat
    yalign*: gfloat
    ratio*: gfloat
    obey_child*: gboolean
    center_allocation*: TGtkAllocation

  PGtkAspectFrameClass* = ptr TGtkAspectFrameClass
  TGtkAspectFrameClass* = object of TGtkFrameClass

  PGtkArrow* = ptr TGtkArrow
  TGtkArrow* = object of TGtkMisc
    arrow_type*: gint16
    shadow_type*: gint16

  PGtkArrowClass* = ptr TGtkArrowClass
  TGtkArrowClass* = object of TGtkMiscClass

  PGtkBindingEntry* = ptr TGtkBindingEntry
  PGtkBindingSignal* = ptr TGtkBindingSignal
  PGtkBindingArg* = ptr TGtkBindingArg
  PGtkBindingSet* = ptr TGtkBindingSet
  TGtkBindingSet* {.final, pure.} = object
    set_name*: cstring
    priority*: gint
    widget_path_pspecs*: PGSList
    widget_class_pspecs*: PGSList
    class_branch_pspecs*: PGSList
    entries*: PGtkBindingEntry
    current*: PGtkBindingEntry
    flag0*: guint16

  TGtkBindingEntry* {.final, pure.} = object
    keyval*: guint
    modifiers*: TGdkModifierType
    binding_set*: PGtkBindingSet
    flag0*: guint16
    set_next*: PGtkBindingEntry
    hash_next*: PGtkBindingEntry
    signals*: PGtkBindingSignal

  TGtkBindingSignal* {.final, pure.} = object
    next*: PGtkBindingSignal
    signal_name*: cstring
    n_args*: guint
    args*: PGtkBindingArg

  TGtkBindingArg* {.final, pure.} = object
    arg_type*: TGtkType
    d*: gdouble

  PGtkBox* = ptr TGtkBox
  TGtkBox* = object of TGtkContainer
    children*: PGList
    spacing*: gint16
    gtkbox_flag0*: guint16

  PGtkBoxClass* = ptr TGtkBoxClass
  TGtkBoxClass* = object of TGtkContainerClass

  PGtkBoxChild* = ptr TGtkBoxChild
  TGtkBoxChild* {.final, pure.} = object
    widget*: PGtkWidget
    padding*: guint16
    flag0*: guint16

  PGtkButtonBox* = ptr TGtkButtonBox
  TGtkButtonBox* = object of TGtkBox
    child_min_width*: gint
    child_min_height*: gint
    child_ipad_x*: gint
    child_ipad_y*: gint
    layout_style*: TGtkButtonBoxStyle

  PGtkButtonBoxClass* = ptr TGtkButtonBoxClass
  TGtkButtonBoxClass* = object of TGtkBoxClass

  PGtkButton* = ptr TGtkButton
  TGtkButton* = object of TGtkBin
    event_window*: PGdkWindow
    label_text*: cstring
    activate_timeout*: guint
    gtkbutton_flag0*: guint16

  PGtkButtonClass* = ptr TGtkButtonClass
  TGtkButtonClass* = object of TGtkBinClass
    pressed*: proc (button: PGtkButton){.cdecl.}
    released*: proc (button: PGtkButton){.cdecl.}
    clicked*: proc (button: PGtkButton){.cdecl.}
    enter*: proc (button: PGtkButton){.cdecl.}
    leave*: proc (button: PGtkButton){.cdecl.}
    activate*: proc (button: PGtkButton){.cdecl.}
    gtk_reserved101: proc (){.cdecl.}
    gtk_reserved102: proc (){.cdecl.}
    gtk_reserved103: proc (){.cdecl.}
    gtk_reserved104: proc (){.cdecl.}

  PGtkCalendarDisplayOptions* = ptr TGtkCalendarDisplayOptions
  TGtkCalendarDisplayOptions* = int32
  PGtkCalendar* = ptr TGtkCalendar
  TGtkCalendar* = object of TGtkWidget
    header_style*: PGtkStyle
    label_style*: PGtkStyle
    month*: gint
    year*: gint
    selected_day*: gint
    day_month*: array[0..5, array[0..6, gint]]
    day*: array[0..5, array[0..6, gint]]
    num_marked_dates*: gint
    marked_date*: array[0..30, gint]
    display_flags*: TGtkCalendarDisplayOptions
    marked_date_color*: array[0..30, TGdkColor]
    gc*: PGdkGC
    xor_gc*: PGdkGC
    focus_row*: gint
    focus_col*: gint
    highlight_row*: gint
    highlight_col*: gint
    private_data*: gpointer
    grow_space*: array[0..31, gchar]
    gtk_reserved111: proc (){.cdecl.}
    gtk_reserved112: proc (){.cdecl.}
    gtk_reserved113: proc (){.cdecl.}
    gtk_reserved114: proc (){.cdecl.}

  PGtkCalendarClass* = ptr TGtkCalendarClass
  TGtkCalendarClass* = object of TGtkWidgetClass
    month_changed*: proc (calendar: PGtkCalendar){.cdecl.}
    day_selected*: proc (calendar: PGtkCalendar){.cdecl.}
    day_selected_double_click*: proc (calendar: PGtkCalendar){.cdecl.}
    prev_month*: proc (calendar: PGtkCalendar){.cdecl.}
    next_month*: proc (calendar: PGtkCalendar){.cdecl.}
    prev_year*: proc (calendar: PGtkCalendar){.cdecl.}
    next_year*: proc (calendar: PGtkCalendar){.cdecl.}

  PGtkCellEditable* = pointer
  PGtkCellEditableIface* = ptr TGtkCellEditableIface
  TGtkCellEditableIface* = object of TGTypeInterface
    editing_done*: proc (cell_editable: PGtkCellEditable){.cdecl.}
    remove_widget*: proc (cell_editable: PGtkCellEditable){.cdecl.}
    start_editing*: proc (cell_editable: PGtkCellEditable, event: PGdkEvent){.
        cdecl.}

  PGtkCellRendererState* = ptr TGtkCellRendererState
  TGtkCellRendererState* = int32
  PGtkCellRendererMode* = ptr TGtkCellRendererMode
  TGtkCellRendererMode* = enum
    GTK_CELL_RENDERER_MODE_INERT, GTK_CELL_RENDERER_MODE_ACTIVATABLE,
    GTK_CELL_RENDERER_MODE_EDITABLE
  PGtkCellRenderer* = ptr TGtkCellRenderer
  TGtkCellRenderer* = object of  TGtkObject
    xalign*: gfloat
    yalign*: gfloat
    width*: gint
    height*: gint
    xpad*: guint16
    ypad*: guint16
    GtkCellRenderer_flag0*: guint16

  PGtkCellRendererClass* = ptr TGtkCellRendererClass
  TGtkCellRendererClass* = object of TGtkObjectClass
    get_size*: proc (cell: PGtkCellRenderer, widget: PGtkWidget,
                     cell_area: PGdkRectangle, x_offset: Pgint, y_offset: Pgint,
                     width: Pgint, height: Pgint){.cdecl.}
    render*: proc (cell: PGtkCellRenderer, window: PGdkWindow,
                   widget: PGtkWidget, background_area: PGdkRectangle,
                   cell_area: PGdkRectangle, expose_area: PGdkRectangle,
                   flags: TGtkCellRendererState){.cdecl.}
    activate*: proc (cell: PGtkCellRenderer, event: PGdkEvent,
                     widget: PGtkWidget, path: cstring,
                     background_area: PGdkRectangle, cell_area: PGdkRectangle,
                     flags: TGtkCellRendererState): gboolean{.cdecl.}
    start_editing*: proc (cell: PGtkCellRenderer, event: PGdkEvent,
                          widget: PGtkWidget, path: cstring,
                          background_area: PGdkRectangle,
                          cell_area: PGdkRectangle, flags: TGtkCellRendererState): PGtkCellEditable{.
        cdecl.}
    gtk_reserved121: proc (){.cdecl.}
    gtk_reserved122: proc (){.cdecl.}
    gtk_reserved123: proc (){.cdecl.}
    gtk_reserved124: proc (){.cdecl.}

  PGtkCellRendererText* = ptr TGtkCellRendererText
  TGtkCellRendererText* = object of TGtkCellRenderer
    text*: cstring
    font*: PPangoFontDescription
    font_scale*: gdouble
    foreground*: TPangoColor
    background*: TPangoColor
    extra_attrs*: PPangoAttrList
    underline_style*: TPangoUnderline
    rise*: gint
    fixed_height_rows*: gint
    GtkCellRendererText_flag0*: guint16

  PGtkCellRendererTextClass* = ptr TGtkCellRendererTextClass
  TGtkCellRendererTextClass* = object of TGtkCellRendererClass
    edited*: proc (cell_renderer_text: PGtkCellRendererText, path: cstring,
                   new_text: cstring){.cdecl.}
    gtk_reserved131: proc (){.cdecl.}
    gtk_reserved132: proc (){.cdecl.}
    gtk_reserved133: proc (){.cdecl.}
    gtk_reserved134: proc (){.cdecl.}

  PGtkCellRendererToggle* = ptr TGtkCellRendererToggle
  TGtkCellRendererToggle* = object of TGtkCellRenderer
    GtkCellRendererToggle_flag0*: guint16

  PGtkCellRendererToggleClass* = ptr TGtkCellRendererToggleClass
  TGtkCellRendererToggleClass* = object of TGtkCellRendererClass
    toggled*: proc (cell_renderer_toggle: PGtkCellRendererToggle, path: cstring){.
        cdecl.}
    gtk_reserved141: proc (){.cdecl.}
    gtk_reserved142: proc (){.cdecl.}
    gtk_reserved143: proc (){.cdecl.}
    gtk_reserved144: proc (){.cdecl.}

  PGtkCellRendererPixbuf* = ptr TGtkCellRendererPixbuf
  TGtkCellRendererPixbuf* = object of TGtkCellRenderer
    pixbuf*: PGdkPixbuf
    pixbuf_expander_open*: PGdkPixbuf
    pixbuf_expander_closed*: PGdkPixbuf

  PGtkCellRendererPixbufClass* = ptr TGtkCellRendererPixbufClass
  TGtkCellRendererPixbufClass* = object of TGtkCellRendererClass
    gtk_reserved151: proc (){.cdecl.}
    gtk_reserved152: proc (){.cdecl.}
    gtk_reserved153: proc (){.cdecl.}
    gtk_reserved154: proc (){.cdecl.}

  PGtkItem* = ptr TGtkItem
  TGtkItem* = object of TGtkBin

  PGtkItemClass* = ptr TGtkItemClass
  TGtkItemClass* = object of TGtkBinClass
    select*: proc (item: PGtkItem){.cdecl.}
    deselect*: proc (item: PGtkItem){.cdecl.}
    toggle*: proc (item: PGtkItem){.cdecl.}
    gtk_reserved161: proc (){.cdecl.}
    gtk_reserved162: proc (){.cdecl.}
    gtk_reserved163: proc (){.cdecl.}
    gtk_reserved164: proc (){.cdecl.}

  PGtkMenuItem* = ptr TGtkMenuItem
  TGtkMenuItem* = object of TGtkItem
    submenu*: PGtkWidget
    event_window*: PGdkWindow
    toggle_size*: guint16
    accelerator_width*: guint16
    accel_path*: cstring
    GtkMenuItem_flag0*: guint16
    timer*: guint

  PGtkMenuItemClass* = ptr TGtkMenuItemClass
  TGtkMenuItemClass* = object of TGtkItemClass
    GtkMenuItemClass_flag0*: guint16
    activate*: proc (menu_item: PGtkMenuItem){.cdecl.}
    activate_item*: proc (menu_item: PGtkMenuItem){.cdecl.}
    toggle_size_request*: proc (menu_item: PGtkMenuItem, requisition: Pgint){.
        cdecl.}
    toggle_size_allocate*: proc (menu_item: PGtkMenuItem, allocation: gint){.
        cdecl.}
    gtk_reserved171: proc (){.cdecl.}
    gtk_reserved172: proc (){.cdecl.}
    gtk_reserved173: proc (){.cdecl.}
    gtk_reserved174: proc (){.cdecl.}

  PGtkToggleButton* = ptr TGtkToggleButton
  TGtkToggleButton* = object of TGtkButton
    GtkToggleButton_flag0*: guint16

  PGtkToggleButtonClass* = ptr TGtkToggleButtonClass
  TGtkToggleButtonClass* = object of TGtkButtonClass
    toggled*: proc (toggle_button: PGtkToggleButton){.cdecl.}
    gtk_reserved171: proc (){.cdecl.}
    gtk_reserved172: proc (){.cdecl.}
    gtk_reserved173: proc (){.cdecl.}
    gtk_reserved174: proc (){.cdecl.}

  PGtkCheckButton* = ptr TGtkCheckButton
  TGtkCheckButton* = object of TGtkToggleButton

  PGtkCheckButtonClass* = ptr TGtkCheckButtonClass
  TGtkCheckButtonClass* = object of TGtkToggleButtonClass
    draw_indicator*: proc (check_button: PGtkCheckButton, area: PGdkRectangle){.
        cdecl.}
    gtk_reserved181: proc (){.cdecl.}
    gtk_reserved182: proc (){.cdecl.}
    gtk_reserved183: proc (){.cdecl.}
    gtk_reserved184: proc (){.cdecl.}

  PGtkCheckMenuItem* = ptr TGtkCheckMenuItem
  TGtkCheckMenuItem* = object of TGtkMenuItem
    GtkCheckMenuItem_flag0*: guint16

  PGtkCheckMenuItemClass* = ptr TGtkCheckMenuItemClass
  TGtkCheckMenuItemClass* = object of TGtkMenuItemClass
    toggled*: proc (check_menu_item: PGtkCheckMenuItem){.cdecl.}
    draw_indicator*: proc (check_menu_item: PGtkCheckMenuItem,
                           area: PGdkRectangle){.cdecl.}
    gtk_reserved191: proc (){.cdecl.}
    gtk_reserved192: proc (){.cdecl.}
    gtk_reserved193: proc (){.cdecl.}
    gtk_reserved194: proc (){.cdecl.}

  PGtkClipboard* = pointer
  TGtkClipboardReceivedFunc* = proc (clipboard: PGtkClipboard,
                                     selection_data: PGtkSelectionData,
                                     data: gpointer){.cdecl.}
  TGtkClipboardTextReceivedFunc* = proc (clipboard: PGtkClipboard, text: cstring,
      data: gpointer){.cdecl.}
  TGtkClipboardGetFunc* = proc (clipboard: PGtkClipboard,
                                selection_data: PGtkSelectionData, info: guint,
                                user_data_or_owner: gpointer){.cdecl.}
  TGtkClipboardClearFunc* = proc (clipboard: PGtkClipboard,
                                  user_data_or_owner: gpointer){.cdecl.}
  PGtkCList* = ptr TGtkCList
  PGtkCListColumn* = ptr TGtkCListColumn
  PGtkCListRow* = ptr TGtkCListRow
  PGtkCell* = ptr TGtkCell
  PGtkCellType* = ptr TGtkCellType
  TGtkCellType* = enum
    GTK_CELL_EMPTY, GTK_CELL_TEXT, GTK_CELL_PIXMAP, GTK_CELL_PIXTEXT,
    GTK_CELL_WIDGET
  PGtkCListDragPos* = ptr TGtkCListDragPos
  TGtkCListDragPos* = enum
    GTK_CLIST_DRAG_NONE, GTK_CLIST_DRAG_BEFORE, GTK_CLIST_DRAG_INTO,
    GTK_CLIST_DRAG_AFTER
  PGtkButtonAction* = ptr TGtkButtonAction
  TGtkButtonAction* = int32
  TGtkCListCompareFunc* = proc (clist: PGtkCList, ptr1: gconstpointer,
                                ptr2: gconstpointer): gint{.cdecl.}
  PGtkCListCellInfo* = ptr TGtkCListCellInfo
  TGtkCListCellInfo* {.final, pure.} = object
    row*: gint
    column*: gint

  PGtkCListDestInfo* = ptr TGtkCListDestInfo
  TGtkCListDestInfo* {.final, pure.} = object
    cell*: TGtkCListCellInfo
    insert_pos*: TGtkCListDragPos

  TGtkCList* = object of TGtkContainer
    GtkCList_flags*: guint16
    row_mem_chunk*: PGMemChunk
    cell_mem_chunk*: PGMemChunk
    freeze_count*: guint
    internal_allocation*: TGdkRectangle
    rows*: gint
    row_height*: gint
    row_list*: PGList
    row_list_end*: PGList
    columns*: gint
    column_title_area*: TGdkRectangle
    title_window*: PGdkWindow
    column*: PGtkCListColumn
    clist_window*: PGdkWindow
    clist_window_width*: gint
    clist_window_height*: gint
    hoffset*: gint
    voffset*: gint
    shadow_type*: TGtkShadowType
    selection_mode*: TGtkSelectionMode
    selection*: PGList
    selection_end*: PGList
    undo_selection*: PGList
    undo_unselection*: PGList
    undo_anchor*: gint
    button_actions*: array[0..4, guint8]
    drag_button*: guint8
    click_cell*: TGtkCListCellInfo
    hadjustment*: PGtkAdjustment
    vadjustment*: PGtkAdjustment
    xor_gc*: PGdkGC
    fg_gc*: PGdkGC
    bg_gc*: PGdkGC
    cursor_drag*: PGdkCursor
    x_drag*: gint
    focus_row*: gint
    focus_header_column*: gint
    anchor*: gint
    anchor_state*: TGtkStateType
    drag_pos*: gint
    htimer*: gint
    vtimer*: gint
    sort_type*: TGtkSortType
    compare*: TGtkCListCompareFunc
    sort_column*: gint
    drag_highlight_row*: gint
    drag_highlight_pos*: TGtkCListDragPos

  PGtkCListClass* = ptr TGtkCListClass
  TGtkCListClass* = object of TGtkContainerClass
    set_scroll_adjustments*: proc (clist: PGtkCList,
                                   hadjustment: PGtkAdjustment,
                                   vadjustment: PGtkAdjustment){.cdecl.}
    refresh*: proc (clist: PGtkCList){.cdecl.}
    select_row*: proc (clist: PGtkCList, row: gint, column: gint,
                       event: PGdkEvent){.cdecl.}
    unselect_row*: proc (clist: PGtkCList, row: gint, column: gint,
                         event: PGdkEvent){.cdecl.}
    row_move*: proc (clist: PGtkCList, source_row: gint, dest_row: gint){.cdecl.}
    click_column*: proc (clist: PGtkCList, column: gint){.cdecl.}
    resize_column*: proc (clist: PGtkCList, column: gint, width: gint){.cdecl.}
    toggle_focus_row*: proc (clist: PGtkCList){.cdecl.}
    select_all*: proc (clist: PGtkCList){.cdecl.}
    unselect_all*: proc (clist: PGtkCList){.cdecl.}
    undo_selection*: proc (clist: PGtkCList){.cdecl.}
    start_selection*: proc (clist: PGtkCList){.cdecl.}
    end_selection*: proc (clist: PGtkCList){.cdecl.}
    extend_selection*: proc (clist: PGtkCList, scroll_type: TGtkScrollType,
                             position: gfloat, auto_start_selection: gboolean){.
        cdecl.}
    scroll_horizontal*: proc (clist: PGtkCList, scroll_type: TGtkScrollType,
                              position: gfloat){.cdecl.}
    scroll_vertical*: proc (clist: PGtkCList, scroll_type: TGtkScrollType,
                            position: gfloat){.cdecl.}
    toggle_add_mode*: proc (clist: PGtkCList){.cdecl.}
    abort_column_resize*: proc (clist: PGtkCList){.cdecl.}
    resync_selection*: proc (clist: PGtkCList, event: PGdkEvent){.cdecl.}
    selection_find*: proc (clist: PGtkCList, row_number: gint,
                           row_list_element: PGList): PGList{.cdecl.}
    draw_row*: proc (clist: PGtkCList, area: PGdkRectangle, row: gint,
                     clist_row: PGtkCListRow){.cdecl.}
    draw_drag_highlight*: proc (clist: PGtkCList, target_row: PGtkCListRow,
                                target_row_number: gint,
                                drag_pos: TGtkCListDragPos){.cdecl.}
    clear*: proc (clist: PGtkCList){.cdecl.}
    fake_unselect_all*: proc (clist: PGtkCList, row: gint){.cdecl.}
    sort_list*: proc (clist: PGtkCList){.cdecl.}
    insert_row*: proc (clist: PGtkCList, row: gint): gint{.cdecl, varargs.}
    remove_row*: proc (clist: PGtkCList, row: gint){.cdecl.}
    set_cell_contents*: proc (clist: PGtkCList, clist_row: PGtkCListRow,
                              column: gint, thetype: TGtkCellType, text: cstring,
                              spacing: guint8, pixmap: PGdkPixmap,
                              mask: PGdkBitmap){.cdecl.}
    cell_size_request*: proc (clist: PGtkCList, clist_row: PGtkCListRow,
                              column: gint, requisition: PGtkRequisition){.cdecl.}

  PGPtrArray = pointer
  PGArray = pointer
  TGtkCListColumn* {.final, pure.} = object
    title*: cstring
    area*: TGdkRectangle
    button*: PGtkWidget
    window*: PGdkWindow
    width*: gint
    min_width*: gint
    max_width*: gint
    justification*: TGtkJustification
    flag0*: guint16

  TGtkCListRow* {.final, pure.} = object
    cell*: PGtkCell
    state*: TGtkStateType
    foreground*: TGdkColor
    background*: TGdkColor
    style*: PGtkStyle
    data*: gpointer
    destroy*: TGtkDestroyNotify
    flag0*: guint16

  PGtkCellText* = ptr TGtkCellText
  TGtkCellText* {.final, pure.} = object
    `type`*: TGtkCellType
    vertical*: gint16
    horizontal*: gint16
    style*: PGtkStyle
    text*: cstring

  PGtkCellPixmap* = ptr TGtkCellPixmap
  TGtkCellPixmap* {.final, pure.} = object
    `type`*: TGtkCellType
    vertical*: gint16
    horizontal*: gint16
    style*: PGtkStyle
    pixmap*: PGdkPixmap
    mask*: PGdkBitmap

  PGtkCellPixText* = ptr TGtkCellPixText
  TGtkCellPixText* {.final, pure.} = object
    `type`*: TGtkCellType
    vertical*: gint16
    horizontal*: gint16
    style*: PGtkStyle
    text*: cstring
    spacing*: guint8
    pixmap*: PGdkPixmap
    mask*: PGdkBitmap

  PGtkCellWidget* = ptr TGtkCellWidget
  TGtkCellWidget* {.final, pure.} = object
    `type`*: TGtkCellType
    vertical*: gint16
    horizontal*: gint16
    style*: PGtkStyle
    widget*: PGtkWidget

  TGtkCell* {.final, pure.} = object
    `type`*: TGtkCellType
    vertical*: gint16
    horizontal*: gint16
    style*: PGtkStyle
    text*: cstring
    spacing*: guint8
    pixmap*: PGdkPixmap
    mask*: PGdkBitmap

  PGtkDialogFlags* = ptr TGtkDialogFlags
  TGtkDialogFlags* = int32
  PGtkResponseType* = ptr TGtkResponseType
  TGtkResponseType* = int32
  PGtkDialog* = ptr TGtkDialog
  TGtkDialog* = object of TGtkWindow
    vbox*: PGtkWidget
    action_area*: PGtkWidget
    separator*: PGtkWidget

  PGtkDialogClass* = ptr TGtkDialogClass
  TGtkDialogClass* = object of TGtkWindowClass
    response*: proc (dialog: PGtkDialog, response_id: gint){.cdecl.}
    closeFile*: proc (dialog: PGtkDialog){.cdecl.}
    gtk_reserved201: proc (){.cdecl.}
    gtk_reserved202: proc (){.cdecl.}
    gtk_reserved203: proc (){.cdecl.}
    gtk_reserved204: proc (){.cdecl.}

  PGtkVBox* = ptr TGtkVBox
  TGtkVBox* = object of TGtkBox

  PGtkVBoxClass* = ptr TGtkVBoxClass
  TGtkVBoxClass* = object of TGtkBoxClass

  TGtkColorSelectionChangePaletteFunc* = proc (colors: PGdkColor, n_colors: gint){.
      cdecl.}
  TGtkColorSelectionChangePaletteWithScreenFunc* = proc (screen: PGdkScreen,
      colors: PGdkColor, n_colors: gint){.cdecl.}
  PGtkColorSelection* = ptr TGtkColorSelection
  TGtkColorSelection* = object of TGtkVBox
    private_data*: gpointer

  PGtkColorSelectionClass* = ptr TGtkColorSelectionClass
  TGtkColorSelectionClass* = object of TGtkVBoxClass
    color_changed*: proc (color_selection: PGtkColorSelection){.cdecl.}
    gtk_reserved211: proc (){.cdecl.}
    gtk_reserved212: proc (){.cdecl.}
    gtk_reserved213: proc (){.cdecl.}
    gtk_reserved214: proc (){.cdecl.}

  PGtkColorSelectionDialog* = ptr TGtkColorSelectionDialog
  TGtkColorSelectionDialog* = object of TGtkDialog
    colorsel*: PGtkWidget
    ok_button*: PGtkWidget
    cancel_button*: PGtkWidget
    help_button*: PGtkWidget

  PGtkColorSelectionDialogClass* = ptr TGtkColorSelectionDialogClass
  TGtkColorSelectionDialogClass* = object of TGtkDialogClass
    gtk_reserved221: proc (){.cdecl.}
    gtk_reserved222: proc (){.cdecl.}
    gtk_reserved223: proc (){.cdecl.}
    gtk_reserved224: proc (){.cdecl.}

  PGtkHBox* = ptr TGtkHBox
  TGtkHBox* = object of TGtkBox

  PGtkHBoxClass* = ptr TGtkHBoxClass
  TGtkHBoxClass* = object of TGtkBoxClass

  PGtkCombo* = ptr TGtkCombo
  TGtkCombo* = object of TGtkHBox
    entry*: PGtkWidget
    button*: PGtkWidget
    popup*: PGtkWidget
    popwin*: PGtkWidget
    list*: PGtkWidget
    entry_change_id*: guint
    list_change_id*: guint
    GtkCombo_flag0*: guint16
    current_button*: guint16
    activate_id*: guint

  PGtkComboClass* = ptr TGtkComboClass
  TGtkComboClass* = object of TGtkHBoxClass
    gtk_reserved231: proc (){.cdecl.}
    gtk_reserved232: proc (){.cdecl.}
    gtk_reserved233: proc (){.cdecl.}
    gtk_reserved234: proc (){.cdecl.}

  PGtkCTreePos* = ptr TGtkCTreePos
  TGtkCTreePos* = enum
    GTK_CTREE_POS_BEFORE, GTK_CTREE_POS_AS_CHILD, GTK_CTREE_POS_AFTER
  PGtkCTreeLineStyle* = ptr TGtkCTreeLineStyle
  TGtkCTreeLineStyle* = enum
    GTK_CTREE_LINES_NONE, GTK_CTREE_LINES_SOLID, GTK_CTREE_LINES_DOTTED,
    GTK_CTREE_LINES_TABBED
  PGtkCTreeExpanderStyle* = ptr TGtkCTreeExpanderStyle
  TGtkCTreeExpanderStyle* = enum
    GTK_CTREE_EXPANDER_NONE, GTK_CTREE_EXPANDER_SQUARE,
    GTK_CTREE_EXPANDER_TRIANGLE, GTK_CTREE_EXPANDER_CIRCULAR
  PGtkCTreeExpansionType* = ptr TGtkCTreeExpansionType
  TGtkCTreeExpansionType* = enum
    GTK_CTREE_EXPANSION_EXPAND, GTK_CTREE_EXPANSION_EXPAND_RECURSIVE,
    GTK_CTREE_EXPANSION_COLLAPSE, GTK_CTREE_EXPANSION_COLLAPSE_RECURSIVE,
    GTK_CTREE_EXPANSION_TOGGLE, GTK_CTREE_EXPANSION_TOGGLE_RECURSIVE
  PGtkCTree* = ptr TGtkCTree
  PGtkCTreeNode* = ptr TGtkCTreeNode
  TGtkCTreeFunc* = proc (ctree: PGtkCTree, node: PGtkCTreeNode, data: gpointer){.
      cdecl.}
  TGtkCTreeGNodeFunc* = proc (ctree: PGtkCTree, depth: guint, gnode: PGNode,
                              cnode: PGtkCTreeNode, data: gpointer): gboolean{.
      cdecl.}
  TGtkCTreeCompareDragFunc* = proc (ctree: PGtkCTree,
                                    source_node: PGtkCTreeNode,
                                    new_parent: PGtkCTreeNode,
                                    new_sibling: PGtkCTreeNode): gboolean{.cdecl.}
  TGtkCTree* = object of TGtkCList
    lines_gc*: PGdkGC
    tree_indent*: gint
    tree_spacing*: gint
    tree_column*: gint
    GtkCTree_flag0*: guint16
    drag_compare*: TGtkCTreeCompareDragFunc

  PGtkCTreeClass* = ptr TGtkCTreeClass
  TGtkCTreeClass* = object of TGtkCListClass
    tree_select_row*: proc (ctree: PGtkCTree, row: PGtkCTreeNode, column: gint){.
        cdecl.}
    tree_unselect_row*: proc (ctree: PGtkCTree, row: PGtkCTreeNode, column: gint){.
        cdecl.}
    tree_expand*: proc (ctree: PGtkCTree, node: PGtkCTreeNode){.cdecl.}
    tree_collapse*: proc (ctree: PGtkCTree, node: PGtkCTreeNode){.cdecl.}
    tree_move*: proc (ctree: PGtkCTree, node: PGtkCTreeNode,
                      new_parent: PGtkCTreeNode, new_sibling: PGtkCTreeNode){.
        cdecl.}
    change_focus_row_expansion*: proc (ctree: PGtkCTree,
                                       action: TGtkCTreeExpansionType){.cdecl.}

  PGtkCTreeRow* = ptr TGtkCTreeRow
  TGtkCTreeRow* {.final, pure.} = object
    row*: TGtkCListRow
    parent*: PGtkCTreeNode
    sibling*: PGtkCTreeNode
    children*: PGtkCTreeNode
    pixmap_closed*: PGdkPixmap
    mask_closed*: PGdkBitmap
    pixmap_opened*: PGdkPixmap
    mask_opened*: PGdkBitmap
    level*: guint16
    GtkCTreeRow_flag0*: guint16

  TGtkCTreeNode* {.final, pure.} = object
    list*: TGList

  PGtkDrawingArea* = ptr TGtkDrawingArea
  TGtkDrawingArea* = object of TGtkWidget
    draw_data*: gpointer

  PGtkDrawingAreaClass* = ptr TGtkDrawingAreaClass
  TGtkDrawingAreaClass* = object of TGtkWidgetClass
    gtk_reserved241: proc (){.cdecl.}
    gtk_reserved242: proc (){.cdecl.}
    gtk_reserved243: proc (){.cdecl.}
    gtk_reserved244: proc (){.cdecl.}

  Tctlpoint* = array[0..1, gfloat]
  Pctlpoint* = ptr Tctlpoint
  PGtkCurve* = ptr TGtkCurve
  TGtkCurve* = object of TGtkDrawingArea
    cursor_type*: gint
    min_x*: gfloat
    max_x*: gfloat
    min_y*: gfloat
    max_y*: gfloat
    pixmap*: PGdkPixmap
    curve_type*: TGtkCurveType
    height*: gint
    grab_point*: gint
    last*: gint
    num_points*: gint
    point*: PGdkPoint
    num_ctlpoints*: gint
    ctlpoint*: Pctlpoint

  PGtkCurveClass* = ptr TGtkCurveClass
  TGtkCurveClass* = object of TGtkDrawingAreaClass
    curve_type_changed*: proc (curve: PGtkCurve){.cdecl.}
    gtk_reserved251: proc (){.cdecl.}
    gtk_reserved252: proc (){.cdecl.}
    gtk_reserved253: proc (){.cdecl.}
    gtk_reserved254: proc (){.cdecl.}

  PGtkDestDefaults* = ptr TGtkDestDefaults
  TGtkDestDefaults* = int32
  PGtkTargetFlags* = ptr TGtkTargetFlags
  TGtkTargetFlags* = int32
  PGtkEditable* = pointer
  PGtkEditableClass* = ptr TGtkEditableClass
  TGtkEditableClass* = object of TGTypeInterface
    insert_text*: proc (editable: PGtkEditable, text: cstring, length: gint,
                        position: Pgint){.cdecl.}
    delete_text*: proc (editable: PGtkEditable, start_pos: gint, end_pos: gint){.
        cdecl.}
    changed*: proc (editable: PGtkEditable){.cdecl.}
    do_insert_text*: proc (editable: PGtkEditable, text: cstring, length: gint,
                           position: Pgint){.cdecl.}
    do_delete_text*: proc (editable: PGtkEditable, start_pos: gint,
                           end_pos: gint){.cdecl.}
    get_chars*: proc (editable: PGtkEditable, start_pos: gint, end_pos: gint): cstring{.
        cdecl.}
    set_selection_bounds*: proc (editable: PGtkEditable, start_pos: gint,
                                 end_pos: gint){.cdecl.}
    get_selection_bounds*: proc (editable: PGtkEditable, start_pos: Pgint,
                                 end_pos: Pgint): gboolean{.cdecl.}
    set_position*: proc (editable: PGtkEditable, position: gint){.cdecl.}
    get_position*: proc (editable: PGtkEditable): gint{.cdecl.}

  PGtkIMContext* = ptr TGtkIMContext
  TGtkIMContext* = object of TGObject

  PGtkIMContextClass* = ptr TGtkIMContextClass
  TGtkIMContextClass* = object of TGtkObjectClass
    preedit_start*: proc (context: PGtkIMContext){.cdecl.}
    preedit_end*: proc (context: PGtkIMContext){.cdecl.}
    preedit_changed*: proc (context: PGtkIMContext){.cdecl.}
    commit*: proc (context: PGtkIMContext, str: cstring){.cdecl.}
    retrieve_surrounding*: proc (context: PGtkIMContext): gboolean{.cdecl.}
    delete_surrounding*: proc (context: PGtkIMContext, offset: gint,
                               n_chars: gint): gboolean{.cdecl.}
    set_client_window*: proc (context: PGtkIMContext, window: PGdkWindow){.cdecl.}
    get_preedit_string*: proc (context: PGtkIMContext, str: PPgchar,
                               attrs: var PPangoAttrList, cursor_pos: Pgint){.
        cdecl.}
    filter_keypress*: proc (context: PGtkIMContext, event: PGdkEventKey): gboolean{.
        cdecl.}
    focus_in*: proc (context: PGtkIMContext){.cdecl.}
    focus_out*: proc (context: PGtkIMContext){.cdecl.}
    reset*: proc (context: PGtkIMContext){.cdecl.}
    set_cursor_location*: proc (context: PGtkIMContext, area: PGdkRectangle){.
        cdecl.}
    set_use_preedit*: proc (context: PGtkIMContext, use_preedit: gboolean){.
        cdecl.}
    set_surrounding*: proc (context: PGtkIMContext, text: cstring, len: gint,
                            cursor_index: gint){.cdecl.}
    get_surrounding*: proc (context: PGtkIMContext, text: PPgchar,
                            cursor_index: Pgint): gboolean{.cdecl.}
    gtk_reserved261: proc (){.cdecl.}
    gtk_reserved262: proc (){.cdecl.}
    gtk_reserved263: proc (){.cdecl.}
    gtk_reserved264: proc (){.cdecl.}
    gtk_reserved265: proc (){.cdecl.}
    gtk_reserved266: proc (){.cdecl.}

  PGtkMenuShell* = ptr TGtkMenuShell
  TGtkMenuShell* = object of TGtkContainer
    children*: PGList
    active_menu_item*: PGtkWidget
    parent_menu_shell*: PGtkWidget
    button*: guint
    activate_time*: guint32
    GtkMenuShell_flag0*: guint16

  PGtkMenuShellClass* = ptr TGtkMenuShellClass
  TGtkMenuShellClass* = object of TGtkContainerClass
    GtkMenuShellClass_flag0*: guint16
    deactivate*: proc (menu_shell: PGtkMenuShell){.cdecl.}
    selection_done*: proc (menu_shell: PGtkMenuShell){.cdecl.}
    move_current*: proc (menu_shell: PGtkMenuShell,
                         direction: TGtkMenuDirectionType){.cdecl.}
    activate_current*: proc (menu_shell: PGtkMenuShell, force_hide: gboolean){.
        cdecl.}
    cancel*: proc (menu_shell: PGtkMenuShell){.cdecl.}
    select_item*: proc (menu_shell: PGtkMenuShell, menu_item: PGtkWidget){.cdecl.}
    insert*: proc (menu_shell: PGtkMenuShell, child: PGtkWidget, position: gint){.
        cdecl.}
    gtk_reserved271: proc (){.cdecl.}
    gtk_reserved272: proc (){.cdecl.}
    gtk_reserved273: proc (){.cdecl.}
    gtk_reserved274: proc (){.cdecl.}

  TGtkMenuPositionFunc* = proc (menu: PGtkMenu, x: Pgint, y: Pgint,
                                push_in: Pgboolean, user_data: gpointer){.cdecl.}
  TGtkMenuDetachFunc* = proc (attach_widget: PGtkWidget, menu: PGtkMenu){.cdecl.}
  TGtkMenu* = object of TGtkMenuShell
    parent_menu_item*: PGtkWidget
    old_active_menu_item*: PGtkWidget
    accel_group*: PGtkAccelGroup
    accel_path*: cstring
    position_func*: TGtkMenuPositionFunc
    position_func_data*: gpointer
    toggle_size*: guint
    toplevel*: PGtkWidget
    tearoff_window*: PGtkWidget
    tearoff_hbox*: PGtkWidget
    tearoff_scrollbar*: PGtkWidget
    tearoff_adjustment*: PGtkAdjustment
    view_window*: PGdkWindow
    bin_window*: PGdkWindow
    scroll_offset*: gint
    saved_scroll_offset*: gint
    scroll_step*: gint
    timeout_id*: guint
    navigation_region*: PGdkRegion
    navigation_timeout*: guint
    GtkMenu_flag0*: guint16

  PGtkMenuClass* = ptr TGtkMenuClass
  TGtkMenuClass* = object of TGtkMenuShellClass
    gtk_reserved281: proc (){.cdecl.}
    gtk_reserved282: proc (){.cdecl.}
    gtk_reserved283: proc (){.cdecl.}
    gtk_reserved284: proc (){.cdecl.}

  PGtkEntry* = ptr TGtkEntry
  TGtkEntry* = object of TGtkWidget
    text*: cstring
    GtkEntry_flag0*: guint16
    text_length*: guint16
    text_max_length*: guint16
    text_area*: PGdkWindow
    im_context*: PGtkIMContext
    popup_menu*: PGtkWidget
    current_pos*: gint
    selection_bound*: gint
    cached_layout*: PPangoLayout
    flag1*: guint16
    button*: guint
    blink_timeout*: guint
    recompute_idle*: guint
    scroll_offset*: gint
    ascent*: gint
    descent*: gint
    text_size*: guint16
    n_bytes*: guint16
    preedit_length*: guint16
    preedit_cursor*: guint16
    dnd_position*: gint
    drag_start_x*: gint
    drag_start_y*: gint
    invisible_char*: gunichar
    width_chars*: gint

  PGtkEntryClass* = ptr TGtkEntryClass
  TGtkEntryClass* = object of TGtkWidgetClass
    populate_popup*: proc (entry: PGtkEntry, menu: PGtkMenu){.cdecl.}
    activate*: proc (entry: PGtkEntry){.cdecl.}
    move_cursor*: proc (entry: PGtkEntry, step: TGtkMovementStep, count: gint,
                        extend_selection: gboolean){.cdecl.}
    insert_at_cursor*: proc (entry: PGtkEntry, str: cstring){.cdecl.}
    delete_from_cursor*: proc (entry: PGtkEntry, thetype: TGtkDeleteType,
                               count: gint){.cdecl.}
    cut_clipboard*: proc (entry: PGtkEntry){.cdecl.}
    copy_clipboard*: proc (entry: PGtkEntry){.cdecl.}
    paste_clipboard*: proc (entry: PGtkEntry){.cdecl.}
    toggle_overwrite*: proc (entry: PGtkEntry){.cdecl.}
    gtk_reserved291: proc (){.cdecl.}
    gtk_reserved292: proc (){.cdecl.}
    gtk_reserved293: proc (){.cdecl.}
    gtk_reserved294: proc (){.cdecl.}

  PGtkEventBox* = ptr TGtkEventBox
  TGtkEventBox* = object of TGtkBin

  PGtkEventBoxClass* = ptr TGtkEventBoxClass
  TGtkEventBoxClass* = object of TGtkBinClass

  PGtkFileSelection* = ptr TGtkFileSelection
  TGtkFileSelection* = object of TGtkDialog
    dir_list*: PGtkWidget
    file_list*: PGtkWidget
    selection_entry*: PGtkWidget
    selection_text*: PGtkWidget
    main_vbox*: PGtkWidget
    ok_button*: PGtkWidget
    cancel_button*: PGtkWidget
    help_button*: PGtkWidget
    history_pulldown*: PGtkWidget
    history_menu*: PGtkWidget
    history_list*: PGList
    fileop_dialog*: PGtkWidget
    fileop_entry*: PGtkWidget
    fileop_file*: cstring
    cmpl_state*: gpointer
    fileop_c_dir*: PGtkWidget
    fileop_del_file*: PGtkWidget
    fileop_ren_file*: PGtkWidget
    button_area*: PGtkWidget
    gtkFileSelection_action_area*: PGtkWidget
    selected_names*: PGPtrArray
    last_selected*: cstring

  PGtkFileSelectionClass* = ptr TGtkFileSelectionClass
  TGtkFileSelectionClass* = object of TGtkDialogClass
    gtk_reserved301: proc (){.cdecl.}
    gtk_reserved302: proc (){.cdecl.}
    gtk_reserved303: proc (){.cdecl.}
    gtk_reserved304: proc (){.cdecl.}

  PGtkFixed* = ptr TGtkFixed
  TGtkFixed* = object of TGtkContainer
    children*: PGList

  PGtkFixedClass* = ptr TGtkFixedClass
  TGtkFixedClass* = object of TGtkContainerClass

  PGtkFixedChild* = ptr TGtkFixedChild
  TGtkFixedChild* {.final, pure.} = object
    widget*: PGtkWidget
    x*: gint
    y*: gint

  PGtkFontSelection* = ptr TGtkFontSelection
  TGtkFontSelection* = object of TGtkVBox
    font_entry*: PGtkWidget
    family_list*: PGtkWidget
    font_style_entry*: PGtkWidget
    face_list*: PGtkWidget
    size_entry*: PGtkWidget
    size_list*: PGtkWidget
    pixels_button*: PGtkWidget
    points_button*: PGtkWidget
    filter_button*: PGtkWidget
    preview_entry*: PGtkWidget
    family*: PPangoFontFamily
    face*: PPangoFontFace
    size*: gint
    font*: PGdkFont

  PGtkFontSelectionClass* = ptr TGtkFontSelectionClass
  TGtkFontSelectionClass* = object of TGtkVBoxClass
    gtk_reserved311: proc (){.cdecl.}
    gtk_reserved312: proc (){.cdecl.}
    gtk_reserved313: proc (){.cdecl.}
    gtk_reserved314: proc (){.cdecl.}

  PGtkFontSelectionDialog* = ptr TGtkFontSelectionDialog
  TGtkFontSelectionDialog* = object of TGtkDialog
    fontsel*: PGtkWidget
    main_vbox*: PGtkWidget
    GtkFontSelectionDialog_action_area*: PGtkWidget
    ok_button*: PGtkWidget
    apply_button*: PGtkWidget
    cancel_button*: PGtkWidget
    dialog_width*: gint
    auto_resize*: gboolean

  PGtkFontSelectionDialogClass* = ptr TGtkFontSelectionDialogClass
  TGtkFontSelectionDialogClass* = object of TGtkDialogClass
    gtk_reserved321: proc (){.cdecl.}
    gtk_reserved322: proc (){.cdecl.}
    gtk_reserved323: proc (){.cdecl.}
    gtk_reserved324: proc (){.cdecl.}

  PGtkGammaCurve* = ptr TGtkGammaCurve
  TGtkGammaCurve* = object of TGtkVBox
    table*: PGtkWidget
    curve*: PGtkWidget
    button*: array[0..4, PGtkWidget]
    gamma*: gfloat
    gamma_dialog*: PGtkWidget
    gamma_text*: PGtkWidget

  PGtkGammaCurveClass* = ptr TGtkGammaCurveClass
  TGtkGammaCurveClass* = object of TGtkVBoxClass
    gtk_reserved331: proc (){.cdecl.}
    gtk_reserved332: proc (){.cdecl.}
    gtk_reserved333: proc (){.cdecl.}
    gtk_reserved334: proc (){.cdecl.}

  PGtkHandleBox* = ptr TGtkHandleBox
  TGtkHandleBox* = object of TGtkBin
    bin_window*: PGdkWindow
    float_window*: PGdkWindow
    shadow_type*: TGtkShadowType
    GtkHandleBox_flag0*: guint16
    deskoff_x*: gint
    deskoff_y*: gint
    attach_allocation*: TGtkAllocation
    float_allocation*: TGtkAllocation

  PGtkHandleBoxClass* = ptr TGtkHandleBoxClass
  TGtkHandleBoxClass* = object of TGtkBinClass
    child_attached*: proc (handle_box: PGtkHandleBox, child: PGtkWidget){.cdecl.}
    child_detached*: proc (handle_box: PGtkHandleBox, child: PGtkWidget){.cdecl.}
    gtk_reserved341: proc (){.cdecl.}
    gtk_reserved342: proc (){.cdecl.}
    gtk_reserved343: proc (){.cdecl.}
    gtk_reserved344: proc (){.cdecl.}

  PGtkPaned* = ptr TGtkPaned
  TGtkPaned* = object of TGtkContainer
    child1*: PGtkWidget
    child2*: PGtkWidget
    handle*: PGdkWindow
    xor_gc*: PGdkGC
    cursor_type*: TGdkCursorType
    handle_pos*: TGdkRectangle
    child1_size*: gint
    last_allocation*: gint
    min_position*: gint
    max_position*: gint
    GtkPaned_flag0*: guint16
    last_child1_focus*: PGtkWidget
    last_child2_focus*: PGtkWidget
    saved_focus*: PGtkWidget
    drag_pos*: gint
    original_position*: gint

  PGtkPanedClass* = ptr TGtkPanedClass
  TGtkPanedClass* = object of TGtkContainerClass
    cycle_child_focus*: proc (paned: PGtkPaned, reverse: gboolean): gboolean{.
        cdecl.}
    toggle_handle_focus*: proc (paned: PGtkPaned): gboolean{.cdecl.}
    move_handle*: proc (paned: PGtkPaned, scroll: TGtkScrollType): gboolean{.
        cdecl.}
    cycle_handle_focus*: proc (paned: PGtkPaned, reverse: gboolean): gboolean{.
        cdecl.}
    accept_position*: proc (paned: PGtkPaned): gboolean{.cdecl.}
    cancel_position*: proc (paned: PGtkPaned): gboolean{.cdecl.}
    gtk_reserved351: proc (){.cdecl.}
    gtk_reserved352: proc (){.cdecl.}
    gtk_reserved353: proc (){.cdecl.}
    gtk_reserved354: proc (){.cdecl.}

  PGtkHButtonBox* = ptr TGtkHButtonBox
  TGtkHButtonBox* = object of TGtkButtonBox

  PGtkHButtonBoxClass* = ptr TGtkHButtonBoxClass
  TGtkHButtonBoxClass* = object of TGtkButtonBoxClass

  PGtkHPaned* = ptr TGtkHPaned
  TGtkHPaned* = object of TGtkPaned

  PGtkHPanedClass* = ptr TGtkHPanedClass
  TGtkHPanedClass* = object of TGtkPanedClass

  PGtkRulerMetric* = ptr TGtkRulerMetric
  PGtkRuler* = ptr TGtkRuler
  TGtkRuler* = object of TGtkWidget
    backing_store*: PGdkPixmap
    non_gr_exp_gc*: PGdkGC
    metric*: PGtkRulerMetric
    xsrc*: gint
    ysrc*: gint
    slider_size*: gint
    lower*: gdouble
    upper*: gdouble
    position*: gdouble
    max_size*: gdouble

  PGtkRulerClass* = ptr TGtkRulerClass
  TGtkRulerClass* = object of TGtkWidgetClass
    draw_ticks*: proc (ruler: PGtkRuler){.cdecl.}
    draw_pos*: proc (ruler: PGtkRuler){.cdecl.}
    gtk_reserved361: proc (){.cdecl.}
    gtk_reserved362: proc (){.cdecl.}
    gtk_reserved363: proc (){.cdecl.}
    gtk_reserved364: proc (){.cdecl.}

  TGtkRulerMetric* {.final, pure.} = object
    metric_name*: cstring
    abbrev*: cstring
    pixels_per_unit*: gdouble
    ruler_scale*: array[0..9, gdouble]
    subdivide*: array[0..4, gint]

  PGtkHRuler* = ptr TGtkHRuler
  TGtkHRuler* = object of TGtkRuler

  PGtkHRulerClass* = ptr TGtkHRulerClass
  TGtkHRulerClass* = object of TGtkRulerClass

  PGtkRcContext* = pointer
  PGtkSettings* = ptr TGtkSettings
  TGtkSettings* = object of TGObject
    queued_settings*: PGData
    property_values*: PGValue
    rc_context*: PGtkRcContext
    screen*: PGdkScreen

  PGtkSettingsClass* = ptr TGtkSettingsClass
  TGtkSettingsClass* = object of TGObjectClass

  PGtkSettingsValue* = ptr TGtkSettingsValue
  TGtkSettingsValue* {.final, pure.} = object
    origin*: cstring
    value*: TGValue

  PGtkRcFlags* = ptr TGtkRcFlags
  TGtkRcFlags* = int32
  PGtkRcStyle* = ptr TGtkRcStyle
  TGtkRcStyle* = object of TGObject
    name*: cstring
    bg_pixmap_name*: array[0..4, cstring]
    font_desc*: PPangoFontDescription
    color_flags*: array[0..4, TGtkRcFlags]
    fg*: array[0..4, TGdkColor]
    bg*: array[0..4, TGdkColor]
    text*: array[0..4, TGdkColor]
    base*: array[0..4, TGdkColor]
    xthickness*: gint
    ythickness*: gint
    rc_properties*: PGArray
    rc_style_lists*: PGSList
    icon_factories*: PGSList
    GtkRcStyle_flag0*: guint16

  PGtkRcStyleClass* = ptr TGtkRcStyleClass
  TGtkRcStyleClass* = object of TGObjectClass
    create_rc_style*: proc (rc_style: PGtkRcStyle): PGtkRcStyle{.cdecl.}
    parse*: proc (rc_style: PGtkRcStyle, settings: PGtkSettings,
                  scanner: PGScanner): guint{.cdecl.}
    merge*: proc (dest: PGtkRcStyle, src: PGtkRcStyle){.cdecl.}
    create_style*: proc (rc_style: PGtkRcStyle): PGtkStyle{.cdecl.}
    gtk_reserved371: proc (){.cdecl.}
    gtk_reserved372: proc (){.cdecl.}
    gtk_reserved373: proc (){.cdecl.}
    gtk_reserved374: proc (){.cdecl.}

  PGtkRcTokenType* = ptr TGtkRcTokenType
  TGtkRcTokenType* = enum
    GTK_RC_TOKEN_INVALID, GTK_RC_TOKEN_INCLUDE, GTK_RC_TOKEN_NORMAL,
    GTK_RC_TOKEN_ACTIVE, GTK_RC_TOKEN_PRELIGHT, GTK_RC_TOKEN_SELECTED,
    GTK_RC_TOKEN_INSENSITIVE, GTK_RC_TOKEN_FG, GTK_RC_TOKEN_BG,
    GTK_RC_TOKEN_TEXT, GTK_RC_TOKEN_BASE, GTK_RC_TOKEN_XTHICKNESS,
    GTK_RC_TOKEN_YTHICKNESS, GTK_RC_TOKEN_FONT, GTK_RC_TOKEN_FONTSET,
    GTK_RC_TOKEN_FONT_NAME, GTK_RC_TOKEN_BG_PIXMAP, GTK_RC_TOKEN_PIXMAP_PATH,
    GTK_RC_TOKEN_STYLE, GTK_RC_TOKEN_BINDING, GTK_RC_TOKEN_BIND,
    GTK_RC_TOKEN_WIDGET, GTK_RC_TOKEN_WIDGET_CLASS, GTK_RC_TOKEN_CLASS,
    GTK_RC_TOKEN_LOWEST, GTK_RC_TOKEN_GTK, GTK_RC_TOKEN_APPLICATION,
    GTK_RC_TOKEN_THEME, GTK_RC_TOKEN_RC, GTK_RC_TOKEN_HIGHEST,
    GTK_RC_TOKEN_ENGINE, GTK_RC_TOKEN_MODULE_PATH, GTK_RC_TOKEN_IM_MODULE_PATH,
    GTK_RC_TOKEN_IM_MODULE_FILE, GTK_RC_TOKEN_STOCK, GTK_RC_TOKEN_LTR,
    GTK_RC_TOKEN_RTL, GTK_RC_TOKEN_LAST
  PGtkRcProperty* = ptr TGtkRcProperty
  TGtkRcProperty* {.final, pure.} = object
    type_name*: TGQuark
    property_name*: TGQuark
    origin*: cstring
    value*: TGValue

  PGtkIconSource* = pointer
  TGtkRcPropertyParser* = proc (pspec: PGParamSpec, rc_string: PGString,
                                property_value: PGValue): gboolean{.cdecl.}
  TGtkStyle* = object of TGObject
    fg*: array[0..4, TGdkColor]
    bg*: array[0..4, TGdkColor]
    light*: array[0..4, TGdkColor]
    dark*: array[0..4, TGdkColor]
    mid*: array[0..4, TGdkColor]
    text*: array[0..4, TGdkColor]
    base*: array[0..4, TGdkColor]
    text_aa*: array[0..4, TGdkColor]
    black*: TGdkColor
    white*: TGdkColor
    font_desc*: PPangoFontDescription
    xthickness*: gint
    ythickness*: gint
    fg_gc*: array[0..4, PGdkGC]
    bg_gc*: array[0..4, PGdkGC]
    light_gc*: array[0..4, PGdkGC]
    dark_gc*: array[0..4, PGdkGC]
    mid_gc*: array[0..4, PGdkGC]
    text_gc*: array[0..4, PGdkGC]
    base_gc*: array[0..4, PGdkGC]
    text_aa_gc*: array[0..4, PGdkGC]
    black_gc*: PGdkGC
    white_gc*: PGdkGC
    bg_pixmap*: array[0..4, PGdkPixmap]
    attach_count*: gint
    depth*: gint
    colormap*: PGdkColormap
    private_font*: PGdkFont
    private_font_desc*: PPangoFontDescription
    rc_style*: PGtkRcStyle
    styles*: PGSList
    property_cache*: PGArray
    icon_factories*: PGSList

  PGtkStyleClass* = ptr TGtkStyleClass
  TGtkStyleClass* = object of TGObjectClass
    realize*: proc (style: PGtkStyle){.cdecl.}
    unrealize*: proc (style: PGtkStyle){.cdecl.}
    copy*: proc (style: PGtkStyle, src: PGtkStyle){.cdecl.}
    clone*: proc (style: PGtkStyle): PGtkStyle{.cdecl.}
    init_from_rc*: proc (style: PGtkStyle, rc_style: PGtkRcStyle){.cdecl.}
    set_background*: proc (style: PGtkStyle, window: PGdkWindow,
                           state_type: TGtkStateType){.cdecl.}
    render_icon*: proc (style: PGtkStyle, source: PGtkIconSource,
                        direction: TGtkTextDirection, state: TGtkStateType,
                        size: TGtkIconSize, widget: PGtkWidget, detail: cstring): PGdkPixbuf{.
        cdecl.}
    draw_hline*: proc (style: PGtkStyle, window: PGdkWindow,
                       state_type: TGtkStateType, area: PGdkRectangle,
                       widget: PGtkWidget, detail: cstring, x1: gint, x2: gint,
                       y: gint){.cdecl.}
    draw_vline*: proc (style: PGtkStyle, window: PGdkWindow,
                       state_type: TGtkStateType, area: PGdkRectangle,
                       widget: PGtkWidget, detail: cstring, y1: gint, y2: gint,
                       x: gint){.cdecl.}
    draw_shadow*: proc (style: PGtkStyle, window: PGdkWindow,
                        state_type: TGtkStateType, shadow_type: TGtkShadowType,
                        area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                        x: gint, y: gint, width: gint, height: gint){.cdecl.}
    draw_polygon*: proc (style: PGtkStyle, window: PGdkWindow,
                         state_type: TGtkStateType, shadow_type: TGtkShadowType,
                         area: PGdkRectangle, widget: PGtkWidget,
                         detail: cstring, point: PGdkPoint, npoints: gint,
                         fill: gboolean){.cdecl.}
    draw_arrow*: proc (style: PGtkStyle, window: PGdkWindow,
                       state_type: TGtkStateType, shadow_type: TGtkShadowType,
                       area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                       arrow_type: TGtkArrowType, fill: gboolean, x: gint,
                       y: gint, width: gint, height: gint){.cdecl.}
    draw_diamond*: proc (style: PGtkStyle, window: PGdkWindow,
                         state_type: TGtkStateType, shadow_type: TGtkShadowType,
                         area: PGdkRectangle, widget: PGtkWidget,
                         detail: cstring, x: gint, y: gint, width: gint,
                         height: gint){.cdecl.}
    draw_string*: proc (style: PGtkStyle, window: PGdkWindow,
                        state_type: TGtkStateType, area: PGdkRectangle,
                        widget: PGtkWidget, detail: cstring, x: gint, y: gint,
                        `string`: cstring){.cdecl.}
    draw_box*: proc (style: PGtkStyle, window: PGdkWindow,
                     state_type: TGtkStateType, shadow_type: TGtkShadowType,
                     area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                     x: gint, y: gint, width: gint, height: gint){.cdecl.}
    draw_flat_box*: proc (style: PGtkStyle, window: PGdkWindow,
                          state_type: TGtkStateType,
                          shadow_type: TGtkShadowType, area: PGdkRectangle,
                          widget: PGtkWidget, detail: cstring, x: gint, y: gint,
                          width: gint, height: gint){.cdecl.}
    draw_check*: proc (style: PGtkStyle, window: PGdkWindow,
                       state_type: TGtkStateType, shadow_type: TGtkShadowType,
                       area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                       x: gint, y: gint, width: gint, height: gint){.cdecl.}
    draw_option*: proc (style: PGtkStyle, window: PGdkWindow,
                        state_type: TGtkStateType, shadow_type: TGtkShadowType,
                        area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                        x: gint, y: gint, width: gint, height: gint){.cdecl.}
    draw_tab*: proc (style: PGtkStyle, window: PGdkWindow,
                     state_type: TGtkStateType, shadow_type: TGtkShadowType,
                     area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                     x: gint, y: gint, width: gint, height: gint){.cdecl.}
    draw_shadow_gap*: proc (style: PGtkStyle, window: PGdkWindow,
                            state_type: TGtkStateType,
                            shadow_type: TGtkShadowType, area: PGdkRectangle,
                            widget: PGtkWidget, detail: cstring, x: gint,
                            y: gint, width: gint, height: gint,
                            gap_side: TGtkPositionType, gap_x: gint,
                            gap_width: gint){.cdecl.}
    draw_box_gap*: proc (style: PGtkStyle, window: PGdkWindow,
                         state_type: TGtkStateType, shadow_type: TGtkShadowType,
                         area: PGdkRectangle, widget: PGtkWidget,
                         detail: cstring, x: gint, y: gint, width: gint,
                         height: gint, gap_side: TGtkPositionType, gap_x: gint,
                         gap_width: gint){.cdecl.}
    draw_extension*: proc (style: PGtkStyle, window: PGdkWindow,
                           state_type: TGtkStateType,
                           shadow_type: TGtkShadowType, area: PGdkRectangle,
                           widget: PGtkWidget, detail: cstring, x: gint, y: gint,
                           width: gint, height: gint, gap_side: TGtkPositionType){.
        cdecl.}
    draw_focus*: proc (style: PGtkStyle, window: PGdkWindow,
                       state_type: TGtkStateType, area: PGdkRectangle,
                       widget: PGtkWidget, detail: cstring, x: gint, y: gint,
                       width: gint, height: gint){.cdecl.}
    draw_slider*: proc (style: PGtkStyle, window: PGdkWindow,
                        state_type: TGtkStateType, shadow_type: TGtkShadowType,
                        area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                        x: gint, y: gint, width: gint, height: gint,
                        orientation: TGtkOrientation){.cdecl.}
    draw_handle*: proc (style: PGtkStyle, window: PGdkWindow,
                        state_type: TGtkStateType, shadow_type: TGtkShadowType,
                        area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                        x: gint, y: gint, width: gint, height: gint,
                        orientation: TGtkOrientation){.cdecl.}
    draw_expander*: proc (style: PGtkStyle, window: PGdkWindow,
                          state_type: TGtkStateType, area: PGdkRectangle,
                          widget: PGtkWidget, detail: cstring, x: gint, y: gint,
                          expander_style: TGtkExpanderStyle){.cdecl.}
    draw_layout*: proc (style: PGtkStyle, window: PGdkWindow,
                        state_type: TGtkStateType, use_text: gboolean,
                        area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                        x: gint, y: gint, layout: PPangoLayout){.cdecl.}
    draw_resize_grip*: proc (style: PGtkStyle, window: PGdkWindow,
                             state_type: TGtkStateType, area: PGdkRectangle,
                             widget: PGtkWidget, detail: cstring,
                             edge: TGdkWindowEdge, x: gint, y: gint,
                             width: gint, height: gint){.cdecl.}
    gtk_reserved381: proc (){.cdecl.}
    gtk_reserved382: proc (){.cdecl.}
    gtk_reserved383: proc (){.cdecl.}
    gtk_reserved384: proc (){.cdecl.}
    gtk_reserved385: proc (){.cdecl.}
    gtk_reserved386: proc (){.cdecl.}
    gtk_reserved387: proc (){.cdecl.}
    gtk_reserved388: proc (){.cdecl.}
    gtk_reserved389: proc (){.cdecl.}
    gtk_reserved3810: proc (){.cdecl.}
    gtk_reserved3811: proc (){.cdecl.}
    gtk_reserved3812: proc (){.cdecl.}

  PGtkBorder* = ptr TGtkBorder
  TGtkBorder* {.final, pure.} = object
    left*: gint
    right*: gint
    top*: gint
    bottom*: gint

  PGtkRangeLayout* = pointer
  PGtkRangeStepTimer* = pointer
  PGtkRange* = ptr TGtkRange
  TGtkRange* = object of TGtkWidget
    adjustment*: PGtkAdjustment
    update_policy*: TGtkUpdateType
    GtkRange_flag0*: guint16
    min_slider_size*: gint
    orientation*: TGtkOrientation
    range_rect*: TGdkRectangle
    slider_start*: gint
    slider_end*: gint
    round_digits*: gint
    flag1*: guint16
    layout*: PGtkRangeLayout
    timer*: PGtkRangeStepTimer
    slide_initial_slider_position*: gint
    slide_initial_coordinate*: gint
    update_timeout_id*: guint
    event_window*: PGdkWindow

  PGtkRangeClass* = ptr TGtkRangeClass
  TGtkRangeClass* = object of TGtkWidgetClass
    slider_detail*: cstring
    stepper_detail*: cstring
    value_changed*: proc (range: PGtkRange){.cdecl.}
    adjust_bounds*: proc (range: PGtkRange, new_value: gdouble){.cdecl.}
    move_slider*: proc (range: PGtkRange, scroll: TGtkScrollType){.cdecl.}
    get_range_border*: proc (range: PGtkRange, border: PGtkBorder){.cdecl.}
    gtk_reserved401: proc (){.cdecl.}
    gtk_reserved402: proc (){.cdecl.}
    gtk_reserved403: proc (){.cdecl.}
    gtk_reserved404: proc (){.cdecl.}

  PGtkScale* = ptr TGtkScale
  TGtkScale* = object of TGtkRange
    digits*: gint
    GtkScale_flag0*: guint16

  PGtkScaleClass* = ptr TGtkScaleClass
  TGtkScaleClass* = object of TGtkRangeClass
    format_value*: proc (scale: PGtkScale, value: gdouble): cstring{.cdecl.}
    draw_value*: proc (scale: PGtkScale){.cdecl.}
    gtk_reserved411: proc (){.cdecl.}
    gtk_reserved412: proc (){.cdecl.}
    gtk_reserved413: proc (){.cdecl.}
    gtk_reserved414: proc (){.cdecl.}

  PGtkHScale* = ptr TGtkHScale
  TGtkHScale* = object of TGtkScale

  PGtkHScaleClass* = ptr TGtkHScaleClass
  TGtkHScaleClass* = object of TGtkScaleClass

  PGtkScrollbar* = ptr TGtkScrollbar
  TGtkScrollbar* = object of TGtkRange

  PGtkScrollbarClass* = ptr TGtkScrollbarClass
  TGtkScrollbarClass* = object of TGtkRangeClass
    gtk_reserved421: proc (){.cdecl.}
    gtk_reserved422: proc (){.cdecl.}
    gtk_reserved423: proc (){.cdecl.}
    gtk_reserved424: proc (){.cdecl.}

  PGtkHScrollbar* = ptr TGtkHScrollbar
  TGtkHScrollbar* = object of TGtkScrollbar

  PGtkHScrollbarClass* = ptr TGtkHScrollbarClass
  TGtkHScrollbarClass* = object of TGtkScrollbarClass

  PGtkSeparator* = ptr TGtkSeparator
  TGtkSeparator* = object of TGtkWidget

  PGtkSeparatorClass* = ptr TGtkSeparatorClass
  TGtkSeparatorClass* = object of TGtkWidgetClass

  PGtkHSeparator* = ptr TGtkHSeparator
  TGtkHSeparator* = object of TGtkSeparator

  PGtkHSeparatorClass* = ptr TGtkHSeparatorClass
  TGtkHSeparatorClass* = object of TGtkSeparatorClass

  PGtkIconFactory* = ptr TGtkIconFactory
  TGtkIconFactory* = object of TGObject
    icons*: PGHashTable

  PGtkIconFactoryClass* = ptr TGtkIconFactoryClass
  TGtkIconFactoryClass* = object of TGObjectClass
    gtk_reserved431: proc (){.cdecl.}
    gtk_reserved432: proc (){.cdecl.}
    gtk_reserved433: proc (){.cdecl.}
    gtk_reserved434: proc (){.cdecl.}

  PGtkIconSet* = pointer
  PGtkImagePixmapData* = ptr TGtkImagePixmapData
  TGtkImagePixmapData* {.final, pure.} = object
    pixmap*: PGdkPixmap

  PGtkImageImageData* = ptr TGtkImageImageData
  TGtkImageImageData* {.final, pure.} = object
    image*: PGdkImage

  PGtkImagePixbufData* = ptr TGtkImagePixbufData
  TGtkImagePixbufData* {.final, pure.} = object
    pixbuf*: PGdkPixbuf

  PGtkImageStockData* = ptr TGtkImageStockData
  TGtkImageStockData* {.final, pure.} = object
    stock_id*: cstring

  PGtkImageIconSetData* = ptr TGtkImageIconSetData
  TGtkImageIconSetData* {.final, pure.} = object
    icon_set*: PGtkIconSet

  PGtkImageAnimationData* = ptr TGtkImageAnimationData
  TGtkImageAnimationData* {.final, pure.} = object
    anim*: PGdkPixbufAnimation
    iter*: PGdkPixbufAnimationIter
    frame_timeout*: guint

  PGtkImageType* = ptr TGtkImageType
  TGtkImageType* = enum
    GTK_IMAGE_EMPTY, GTK_IMAGE_PIXMAP, GTK_IMAGE_IMAGE, GTK_IMAGE_PIXBUF,
    GTK_IMAGE_STOCK, GTK_IMAGE_ICON_SET, GTK_IMAGE_ANIMATION
  PGtkImage* = ptr TGtkImage
  TGtkImage* = object of TGtkMisc
    storage_type*: TGtkImageType
    pixmap*: TGtkImagePixmapData
    mask*: PGdkBitmap
    icon_size*: TGtkIconSize

  PGtkImageClass* = ptr TGtkImageClass
  TGtkImageClass* = object of TGtkMiscClass
    gtk_reserved441: proc (){.cdecl.}
    gtk_reserved442: proc (){.cdecl.}
    gtk_reserved443: proc (){.cdecl.}
    gtk_reserved444: proc (){.cdecl.}

  PGtkImageMenuItem* = ptr TGtkImageMenuItem
  TGtkImageMenuItem* = object of TGtkMenuItem
    image*: PGtkWidget

  PGtkImageMenuItemClass* = ptr TGtkImageMenuItemClass
  TGtkImageMenuItemClass* = object of TGtkMenuItemClass

  PGtkIMContextSimple* = ptr TGtkIMContextSimple
  TGtkIMContextSimple* = object of TGtkIMContext
    tables*: PGSList
    compose_buffer*: array[0..(GTK_MAX_COMPOSE_LEN + 1) - 1, guint]
    tentative_match*: gunichar
    tentative_match_len*: gint
    GtkIMContextSimple_flag0*: guint16

  PGtkIMContextSimpleClass* = ptr TGtkIMContextSimpleClass
  TGtkIMContextSimpleClass* = object of TGtkIMContextClass

  PGtkIMMulticontext* = ptr TGtkIMMulticontext
  TGtkIMMulticontext* = object of TGtkIMContext
    slave*: PGtkIMContext
    client_window*: PGdkWindow
    context_id*: cstring

  PGtkIMMulticontextClass* = ptr TGtkIMMulticontextClass
  TGtkIMMulticontextClass* = object of TGtkIMContextClass
    gtk_reserved451: proc (){.cdecl.}
    gtk_reserved452: proc (){.cdecl.}
    gtk_reserved453: proc (){.cdecl.}
    gtk_reserved454: proc (){.cdecl.}

  PGtkInputDialog* = ptr TGtkInputDialog
  TGtkInputDialog* = object of TGtkDialog
    axis_list*: PGtkWidget
    axis_listbox*: PGtkWidget
    mode_optionmenu*: PGtkWidget
    close_button*: PGtkWidget
    save_button*: PGtkWidget
    axis_items*: array[0..(GDK_AXIS_LAST) - 1, PGtkWidget]
    current_device*: PGdkDevice
    keys_list*: PGtkWidget
    keys_listbox*: PGtkWidget

  PGtkInputDialogClass* = ptr TGtkInputDialogClass
  TGtkInputDialogClass* = object of TGtkDialogClass
    enable_device*: proc (inputd: PGtkInputDialog, device: PGdkDevice){.cdecl.}
    disable_device*: proc (inputd: PGtkInputDialog, device: PGdkDevice){.cdecl.}
    gtk_reserved461: proc (){.cdecl.}
    gtk_reserved462: proc (){.cdecl.}
    gtk_reserved463: proc (){.cdecl.}
    gtk_reserved464: proc (){.cdecl.}

  PGtkInvisible* = ptr TGtkInvisible
  TGtkInvisible* = object of TGtkWidget
    has_user_ref_count*: gboolean
    screen*: PGdkScreen

  PGtkInvisibleClass* = ptr TGtkInvisibleClass
  TGtkInvisibleClass* = object of TGtkWidgetClass
    gtk_reserved701: proc (){.cdecl.}
    gtk_reserved702: proc (){.cdecl.}
    gtk_reserved703: proc (){.cdecl.}
    gtk_reserved704: proc (){.cdecl.}

  TGtkPrintFunc* = proc (func_data: gpointer, str: cstring){.cdecl.}
  PGtkTranslateFunc* = ptr TGtkTranslateFunc
  TGtkTranslateFunc* = gchar
  TGtkItemFactoryCallback* = proc (){.cdecl.}
  TGtkItemFactoryCallback1* = proc (callback_data: gpointer,
                                    callback_action: guint, widget: PGtkWidget){.
      cdecl.}
  PGtkItemFactory* = ptr TGtkItemFactory
  TGtkItemFactory* = object of TGtkObject
    path*: cstring
    accel_group*: PGtkAccelGroup
    widget*: PGtkWidget
    items*: PGSList
    translate_func*: TGtkTranslateFunc
    translate_data*: gpointer
    translate_notify*: TGtkDestroyNotify

  PGtkItemFactoryClass* = ptr TGtkItemFactoryClass
  TGtkItemFactoryClass* = object of TGtkObjectClass
    item_ht*: PGHashTable
    gtk_reserved471: proc (){.cdecl.}
    gtk_reserved472: proc (){.cdecl.}
    gtk_reserved473: proc (){.cdecl.}
    gtk_reserved474: proc (){.cdecl.}

  PGtkItemFactoryEntry* = ptr TGtkItemFactoryEntry
  TGtkItemFactoryEntry* {.final, pure.} = object
    path*: cstring
    accelerator*: cstring
    callback*: TGtkItemFactoryCallback
    callback_action*: guint
    item_type*: cstring
    extra_data*: gconstpointer

  PGtkItemFactoryItem* = ptr TGtkItemFactoryItem
  TGtkItemFactoryItem* {.final, pure.} = object
    path*: cstring
    widgets*: PGSList

  PGtkLayout* = ptr TGtkLayout
  TGtkLayout* = object of TGtkContainer
    children*: PGList
    width*: guint
    height*: guint
    hadjustment*: PGtkAdjustment
    vadjustment*: PGtkAdjustment
    bin_window*: PGdkWindow
    visibility*: TGdkVisibilityState
    scroll_x*: gint
    scroll_y*: gint
    freeze_count*: guint

  PGtkLayoutClass* = ptr TGtkLayoutClass
  TGtkLayoutClass* = object of TGtkContainerClass
    set_scroll_adjustments*: proc (layout: PGtkLayout,
                                   hadjustment: PGtkAdjustment,
                                   vadjustment: PGtkAdjustment){.cdecl.}
    gtk_reserved481: proc (){.cdecl.}
    gtk_reserved482: proc (){.cdecl.}
    gtk_reserved483: proc (){.cdecl.}
    gtk_reserved484: proc (){.cdecl.}

  PGtkList* = ptr TGtkList
  TGtkList* = object of TGtkContainer
    children*: PGList
    selection*: PGList
    undo_selection*: PGList
    undo_unselection*: PGList
    last_focus_child*: PGtkWidget
    undo_focus_child*: PGtkWidget
    htimer*: guint
    vtimer*: guint
    anchor*: gint
    drag_pos*: gint
    anchor_state*: TGtkStateType
    GtkList_flag0*: guint16

  PGtkListClass* = ptr TGtkListClass
  TGtkListClass* = object of TGtkContainerClass
    selection_changed*: proc (list: PGtkList){.cdecl.}
    select_child*: proc (list: PGtkList, child: PGtkWidget){.cdecl.}
    unselect_child*: proc (list: PGtkList, child: PGtkWidget){.cdecl.}

  TGtkTreeModelForeachFunc* = proc (model: PGtkTreeModel, path: PGtkTreePath,
                                    iter: PGtkTreeIter, data: gpointer): gboolean{.
      cdecl.}
  PGtkTreeModelFlags* = ptr TGtkTreeModelFlags
  TGtkTreeModelFlags* = int32
  TGtkTreeIter* {.final, pure.} = object
    stamp*: gint
    user_data*: gpointer
    user_data2*: gpointer
    user_data3*: gpointer

  PGtkTreeModelIface* = ptr TGtkTreeModelIface
  TGtkTreeModelIface* = object of TGTypeInterface
    row_changed*: proc (tree_model: PGtkTreeModel, path: PGtkTreePath,
                        iter: PGtkTreeIter){.cdecl.}
    row_inserted*: proc (tree_model: PGtkTreeModel, path: PGtkTreePath,
                         iter: PGtkTreeIter){.cdecl.}
    row_has_child_toggled*: proc (tree_model: PGtkTreeModel, path: PGtkTreePath,
                                  iter: PGtkTreeIter){.cdecl.}
    row_deleted*: proc (tree_model: PGtkTreeModel, path: PGtkTreePath){.cdecl.}
    rows_reordered*: proc (tree_model: PGtkTreeModel, path: PGtkTreePath,
                           iter: PGtkTreeIter, new_order: Pgint){.cdecl.}
    get_flags*: proc (tree_model: PGtkTreeModel): TGtkTreeModelFlags{.cdecl.}
    get_n_columns*: proc (tree_model: PGtkTreeModel): gint{.cdecl.}
    get_column_type*: proc (tree_model: PGtkTreeModel, index: gint): GType{.
        cdecl.}
    get_iter*: proc (tree_model: PGtkTreeModel, iter: PGtkTreeIter,
                     path: PGtkTreePath): gboolean{.cdecl.}
    get_path*: proc (tree_model: PGtkTreeModel, iter: PGtkTreeIter): PGtkTreePath{.
        cdecl.}
    get_value*: proc (tree_model: PGtkTreeModel, iter: PGtkTreeIter,
                      column: gint, value: PGValue){.cdecl.}
    iter_next*: proc (tree_model: PGtkTreeModel, iter: PGtkTreeIter): gboolean{.
        cdecl.}
    iter_children*: proc (tree_model: PGtkTreeModel, iter: PGtkTreeIter,
                          parent: PGtkTreeIter): gboolean{.cdecl.}
    iter_has_child*: proc (tree_model: PGtkTreeModel, iter: PGtkTreeIter): gboolean{.
        cdecl.}
    iter_n_children*: proc (tree_model: PGtkTreeModel, iter: PGtkTreeIter): gint{.
        cdecl.}
    iter_nth_child*: proc (tree_model: PGtkTreeModel, iter: PGtkTreeIter,
                           parent: PGtkTreeIter, n: gint): gboolean{.cdecl.}
    iter_parent*: proc (tree_model: PGtkTreeModel, iter: PGtkTreeIter,
                        child: PGtkTreeIter): gboolean{.cdecl.}
    ref_node*: proc (tree_model: PGtkTreeModel, iter: PGtkTreeIter){.cdecl.}
    unref_node*: proc (tree_model: PGtkTreeModel, iter: PGtkTreeIter){.cdecl.}

  PGtkTreeSortable* = pointer
  TGtkTreeIterCompareFunc* = proc (model: PGtkTreeModel, a: PGtkTreeIter,
                                   b: PGtkTreeIter, user_data: gpointer): gint{.
      cdecl.}
  PGtkTreeSortableIface* = ptr TGtkTreeSortableIface
  TGtkTreeSortableIface* = object of TGTypeInterface
    sort_column_changed*: proc (sortable: PGtkTreeSortable){.cdecl.}
    get_sort_column_id*: proc (sortable: PGtkTreeSortable,
                               sort_column_id: Pgint, order: PGtkSortType): gboolean{.
        cdecl.}
    set_sort_column_id*: proc (sortable: PGtkTreeSortable, sort_column_id: gint,
                               order: TGtkSortType){.cdecl.}
    set_sort_func*: proc (sortable: PGtkTreeSortable, sort_column_id: gint,
                          func: TGtkTreeIterCompareFunc, data: gpointer,
                          destroy: TGtkDestroyNotify){.cdecl.}
    set_default_sort_func*: proc (sortable: PGtkTreeSortable,
                                  func: TGtkTreeIterCompareFunc, data: gpointer,
                                  destroy: TGtkDestroyNotify){.cdecl.}
    has_default_sort_func*: proc (sortable: PGtkTreeSortable): gboolean{.cdecl.}

  PGtkTreeModelSort* = ptr TGtkTreeModelSort
  TGtkTreeModelSort* = object of TGObject
    root*: gpointer
    stamp*: gint
    child_flags*: guint
    child_model*: PGtkTreeModel
    zero_ref_count*: gint
    sort_list*: PGList
    sort_column_id*: gint
    order*: TGtkSortType
    default_sort_func*: TGtkTreeIterCompareFunc
    default_sort_data*: gpointer
    default_sort_destroy*: TGtkDestroyNotify
    changed_id*: guint
    inserted_id*: guint
    has_child_toggled_id*: guint
    deleted_id*: guint
    reordered_id*: guint

  PGtkTreeModelSortClass* = ptr TGtkTreeModelSortClass
  TGtkTreeModelSortClass* = object of TGObjectClass
    gtk_reserved491: proc (){.cdecl.}
    gtk_reserved492: proc (){.cdecl.}
    gtk_reserved493: proc (){.cdecl.}
    gtk_reserved494: proc (){.cdecl.}

  PGtkListStore* = ptr TGtkListStore
  TGtkListStore* = object of TGObject
    stamp*: gint
    root*: gpointer
    tail*: gpointer
    sort_list*: PGList
    n_columns*: gint
    sort_column_id*: gint
    order*: TGtkSortType
    column_headers*: PGType
    length*: gint
    default_sort_func*: TGtkTreeIterCompareFunc
    default_sort_data*: gpointer
    default_sort_destroy*: TGtkDestroyNotify
    GtkListStore_flag0*: guint16

  PGtkListStoreClass* = ptr TGtkListStoreClass
  TGtkListStoreClass* = object of TGObjectClass
    gtk_reserved501: proc (){.cdecl.}
    gtk_reserved502: proc (){.cdecl.}
    gtk_reserved503: proc (){.cdecl.}
    gtk_reserved504: proc (){.cdecl.}

  TGtkModuleInitFunc* = proc (argc: Pgint, argv: PPPgchar){.cdecl.}
  TGtkKeySnoopFunc* = proc (grab_widget: PGtkWidget, event: PGdkEventKey,
                            func_data: gpointer): gint{.cdecl.}
  PGtkMenuBar* = ptr TGtkMenuBar
  TGtkMenuBar* = object of TGtkMenuShell

  PGtkMenuBarClass* = ptr TGtkMenuBarClass
  TGtkMenuBarClass* = object of TGtkMenuShellClass
    gtk_reserved511: proc (){.cdecl.}
    gtk_reserved512: proc (){.cdecl.}
    gtk_reserved513: proc (){.cdecl.}
    gtk_reserved514: proc (){.cdecl.}

  PGtkMessageType* = ptr TGtkMessageType
  TGtkMessageType* = enum
    GTK_MESSAGE_INFO, GTK_MESSAGE_WARNING, GTK_MESSAGE_QUESTION,
    GTK_MESSAGE_ERROR
  PGtkButtonsType* = ptr TGtkButtonsType
  TGtkButtonsType* = enum
    GTK_BUTTONS_NONE, GTK_BUTTONS_OK, GTK_BUTTONS_CLOSE, GTK_BUTTONS_CANCEL,
    GTK_BUTTONS_YES_NO, GTK_BUTTONS_OK_CANCEL
  PGtkMessageDialog* = ptr TGtkMessageDialog
  TGtkMessageDialog* = object of TGtkDialog
    image*: PGtkWidget
    label*: PGtkWidget

  PGtkMessageDialogClass* = ptr TGtkMessageDialogClass
  TGtkMessageDialogClass* = object of TGtkDialogClass
    gtk_reserved521: proc (){.cdecl.}
    gtk_reserved522: proc (){.cdecl.}
    gtk_reserved523: proc (){.cdecl.}
    gtk_reserved524: proc (){.cdecl.}

  PGtkNotebookPage* = pointer
  PGtkNotebookTab* = ptr TGtkNotebookTab
  TGtkNotebookTab* = enum
    GTK_NOTEBOOK_TAB_FIRST, GTK_NOTEBOOK_TAB_LAST
  PGtkNotebook* = ptr TGtkNotebook
  TGtkNotebook* = object of TGtkContainer
    cur_page*: PGtkNotebookPage
    children*: PGList
    first_tab*: PGList
    focus_tab*: PGList
    menu*: PGtkWidget
    event_window*: PGdkWindow
    timer*: guint32
    tab_hborder*: guint16
    tab_vborder*: guint16
    GtkNotebook_flag0*: guint16

  PGtkNotebookClass* = ptr TGtkNotebookClass
  TGtkNotebookClass* = object of TGtkContainerClass
    switch_page*: proc (notebook: PGtkNotebook, page: PGtkNotebookPage,
                        page_num: guint){.cdecl.}
    select_page*: proc (notebook: PGtkNotebook, move_focus: gboolean): gboolean{.
        cdecl.}
    focus_tab*: proc (notebook: PGtkNotebook, thetype: TGtkNotebookTab): gboolean{.
        cdecl.}
    change_current_page*: proc (notebook: PGtkNotebook, offset: gint){.cdecl.}
    move_focus_out*: proc (notebook: PGtkNotebook, direction: TGtkDirectionType){.
        cdecl.}
    gtk_reserved531: proc (){.cdecl.}
    gtk_reserved532: proc (){.cdecl.}
    gtk_reserved533: proc (){.cdecl.}
    gtk_reserved534: proc (){.cdecl.}

  PGtkOldEditable* = ptr TGtkOldEditable
  TGtkOldEditable* = object of TGtkWidget
    current_pos*: guint
    selection_start_pos*: guint
    selection_end_pos*: guint
    GtkOldEditable_flag0*: guint16
    clipboard_text*: cstring

  TGtkTextFunction* = proc (editable: PGtkOldEditable, time: guint32){.cdecl.}
  PGtkOldEditableClass* = ptr TGtkOldEditableClass
  TGtkOldEditableClass* = object of TGtkWidgetClass
    activate*: proc (editable: PGtkOldEditable){.cdecl.}
    set_editable*: proc (editable: PGtkOldEditable, is_editable: gboolean){.
        cdecl.}
    move_cursor*: proc (editable: PGtkOldEditable, x: gint, y: gint){.cdecl.}
    move_word*: proc (editable: PGtkOldEditable, n: gint){.cdecl.}
    move_page*: proc (editable: PGtkOldEditable, x: gint, y: gint){.cdecl.}
    move_to_row*: proc (editable: PGtkOldEditable, row: gint){.cdecl.}
    move_to_column*: proc (editable: PGtkOldEditable, row: gint){.cdecl.}
    kill_char*: proc (editable: PGtkOldEditable, direction: gint){.cdecl.}
    kill_word*: proc (editable: PGtkOldEditable, direction: gint){.cdecl.}
    kill_line*: proc (editable: PGtkOldEditable, direction: gint){.cdecl.}
    cut_clipboard*: proc (editable: PGtkOldEditable){.cdecl.}
    copy_clipboard*: proc (editable: PGtkOldEditable){.cdecl.}
    paste_clipboard*: proc (editable: PGtkOldEditable){.cdecl.}
    update_text*: proc (editable: PGtkOldEditable, start_pos: gint,
                        end_pos: gint){.cdecl.}
    get_chars*: proc (editable: PGtkOldEditable, start_pos: gint, end_pos: gint): cstring{.
        cdecl.}
    set_selection*: proc (editable: PGtkOldEditable, start_pos: gint,
                          end_pos: gint){.cdecl.}
    set_position*: proc (editable: PGtkOldEditable, position: gint){.cdecl.}

  PGtkOptionMenu* = ptr TGtkOptionMenu
  TGtkOptionMenu* = object of TGtkButton
    menu*: PGtkWidget
    menu_item*: PGtkWidget
    width*: guint16
    height*: guint16

  PGtkOptionMenuClass* = ptr TGtkOptionMenuClass
  TGtkOptionMenuClass* = object of TGtkButtonClass
    changed*: proc (option_menu: PGtkOptionMenu){.cdecl.}
    gtk_reserved541: proc (){.cdecl.}
    gtk_reserved542: proc (){.cdecl.}
    gtk_reserved543: proc (){.cdecl.}
    gtk_reserved544: proc (){.cdecl.}

  PGtkPixmap* = ptr TGtkPixmap
  TGtkPixmap* = object of TGtkMisc
    pixmap*: PGdkPixmap
    mask*: PGdkBitmap
    pixmap_insensitive*: PGdkPixmap
    GtkPixmap_flag0*: guint16

  PGtkPixmapClass* = ptr TGtkPixmapClass
  TGtkPixmapClass* = object of TGtkMiscClass

  PGtkPlug* = ptr TGtkPlug
  TGtkPlug* = object of TGtkWindow
    socket_window*: PGdkWindow
    modality_window*: PGtkWidget
    modality_group*: PGtkWindowGroup
    grabbed_keys*: PGHashTable
    GtkPlug_flag0*: guint16

  PGtkPlugClass* = ptr TGtkPlugClass
  TGtkPlugClass* = object of TGtkWindowClass
    embedded*: proc (plug: PGtkPlug){.cdecl.}
    gtk_reserved551: proc (){.cdecl.}
    gtk_reserved552: proc (){.cdecl.}
    gtk_reserved553: proc (){.cdecl.}
    gtk_reserved554: proc (){.cdecl.}

  PGtkPreview* = ptr TGtkPreview
  TGtkPreview* = object of TGtkWidget
    buffer*: Pguchar
    buffer_width*: guint16
    buffer_height*: guint16
    bpp*: guint16
    rowstride*: guint16
    dither*: TGdkRgbDither
    GtkPreview_flag0*: guint16

  PGtkPreviewInfo* = ptr TGtkPreviewInfo
  TGtkPreviewInfo* {.final, pure.} = object
    lookup*: Pguchar
    gamma*: gdouble

  PGtkDitherInfo* = ptr TGtkDitherInfo
  TGtkDitherInfo* {.final, pure.} = object
    c*: array[0..3, guchar]

  PGtkPreviewClass* = ptr TGtkPreviewClass
  TGtkPreviewClass* = object of TGtkWidgetClass
    info*: TGtkPreviewInfo

  PGtkProgress* = ptr TGtkProgress
  TGtkProgress* = object of TGtkWidget
    adjustment*: PGtkAdjustment
    offscreen_pixmap*: PGdkPixmap
    format*: cstring
    x_align*: gfloat
    y_align*: gfloat
    GtkProgress_flag0*: guint16

  PGtkProgressClass* = ptr TGtkProgressClass
  TGtkProgressClass* = object of TGtkWidgetClass
    paint*: proc (progress: PGtkProgress){.cdecl.}
    update*: proc (progress: PGtkProgress){.cdecl.}
    act_mode_enter*: proc (progress: PGtkProgress){.cdecl.}
    gtk_reserved561: proc (){.cdecl.}
    gtk_reserved562: proc (){.cdecl.}
    gtk_reserved563: proc (){.cdecl.}
    gtk_reserved564: proc (){.cdecl.}

  PGtkProgressBarStyle* = ptr TGtkProgressBarStyle
  TGtkProgressBarStyle* = enum
    GTK_PROGRESS_CONTINUOUS, GTK_PROGRESS_DISCRETE
  PGtkProgressBarOrientation* = ptr TGtkProgressBarOrientation
  TGtkProgressBarOrientation* = enum
    GTK_PROGRESS_LEFT_TO_RIGHT, GTK_PROGRESS_RIGHT_TO_LEFT,
    GTK_PROGRESS_BOTTOM_TO_TOP, GTK_PROGRESS_TOP_TO_BOTTOM
  PGtkProgressBar* = ptr TGtkProgressBar
  TGtkProgressBar* = object of TGtkProgress
    bar_style*: TGtkProgressBarStyle
    orientation*: TGtkProgressBarOrientation
    blocks*: guint
    in_block*: gint
    activity_pos*: gint
    activity_step*: guint
    activity_blocks*: guint
    pulse_fraction*: gdouble
    GtkProgressBar_flag0*: guint16

  PGtkProgressBarClass* = ptr TGtkProgressBarClass
  TGtkProgressBarClass* = object of TGtkProgressClass
    gtk_reserved571: proc (){.cdecl.}
    gtk_reserved572: proc (){.cdecl.}
    gtk_reserved573: proc (){.cdecl.}
    gtk_reserved574: proc (){.cdecl.}

  PGtkRadioButton* = ptr TGtkRadioButton
  TGtkRadioButton* = object of TGtkCheckButton
    group*: PGSList

  PGtkRadioButtonClass* = ptr TGtkRadioButtonClass
  TGtkRadioButtonClass* = object of TGtkCheckButtonClass
    gtk_reserved581: proc (){.cdecl.}
    gtk_reserved582: proc (){.cdecl.}
    gtk_reserved583: proc (){.cdecl.}
    gtk_reserved584: proc (){.cdecl.}

  PGtkRadioMenuItem* = ptr TGtkRadioMenuItem
  TGtkRadioMenuItem* = object of TGtkCheckMenuItem
    group*: PGSList

  PGtkRadioMenuItemClass* = ptr TGtkRadioMenuItemClass
  TGtkRadioMenuItemClass* = object of TGtkCheckMenuItemClass
    gtk_reserved591: proc (){.cdecl.}
    gtk_reserved592: proc (){.cdecl.}
    gtk_reserved593: proc (){.cdecl.}
    gtk_reserved594: proc (){.cdecl.}

  PGtkScrolledWindow* = ptr TGtkScrolledWindow
  TGtkScrolledWindow* = object of TGtkBin
    hscrollbar*: PGtkWidget
    vscrollbar*: PGtkWidget
    GtkScrolledWindow_flag0*: guint16
    shadow_type*: guint16

  PGtkScrolledWindowClass* = ptr TGtkScrolledWindowClass
  TGtkScrolledWindowClass* = object of TGtkBinClass
    scrollbar_spacing*: gint
    scroll_child*: proc (scrolled_window: PGtkScrolledWindow,
                         scroll: TGtkScrollType, horizontal: gboolean){.cdecl.}
    move_focus_out*: proc (scrolled_window: PGtkScrolledWindow,
                           direction: TGtkDirectionType){.cdecl.}
    gtk_reserved601: proc (){.cdecl.}
    gtk_reserved602: proc (){.cdecl.}
    gtk_reserved603: proc (){.cdecl.}
    gtk_reserved604: proc (){.cdecl.}

  TGtkSelectionData* {.final, pure.} = object
    selection*: TGdkAtom
    target*: TGdkAtom
    thetype*: TGdkAtom
    format*: gint
    data*: Pguchar
    length*: gint
    display*: PGdkDisplay

  PGtkTargetEntry* = ptr TGtkTargetEntry
  TGtkTargetEntry* {.final, pure.} = object
    target*: cstring
    flags*: guint
    info*: guint

  PGtkTargetList* = ptr TGtkTargetList
  TGtkTargetList* {.final, pure.} = object
    list*: PGList
    ref_count*: guint

  PGtkTargetPair* = ptr TGtkTargetPair
  TGtkTargetPair* {.final, pure.} = object
    target*: TGdkAtom
    flags*: guint
    info*: guint

  PGtkSeparatorMenuItem* = ptr TGtkSeparatorMenuItem
  TGtkSeparatorMenuItem* = object of TGtkMenuItem

  PGtkSeparatorMenuItemClass* = ptr TGtkSeparatorMenuItemClass
  TGtkSeparatorMenuItemClass* = object of TGtkMenuItemClass

  PGtkSizeGroup* = ptr TGtkSizeGroup
  TGtkSizeGroup* = object of TGObject
    widgets*: PGSList
    mode*: guint8
    GtkSizeGroup_flag0*: guint16
    requisition*: TGtkRequisition

  PGtkSizeGroupClass* = ptr TGtkSizeGroupClass
  TGtkSizeGroupClass* = object of TGObjectClass
    gtk_reserved611: proc (){.cdecl.}
    gtk_reserved612: proc (){.cdecl.}
    gtk_reserved613: proc (){.cdecl.}
    gtk_reserved614: proc (){.cdecl.}

  PGtkSizeGroupMode* = ptr TGtkSizeGroupMode
  TGtkSizeGroupMode* = enum
    GTK_SIZE_GROUP_NONE, GTK_SIZE_GROUP_HORIZONTAL, GTK_SIZE_GROUP_VERTICAL,
    GTK_SIZE_GROUP_BOTH
  PGtkSocket* = ptr TGtkSocket
  TGtkSocket* = object of TGtkContainer
    request_width*: guint16
    request_height*: guint16
    current_width*: guint16
    current_height*: guint16
    plug_window*: PGdkWindow
    plug_widget*: PGtkWidget
    xembed_version*: gshort
    GtkSocket_flag0*: guint16
    accel_group*: PGtkAccelGroup
    toplevel*: PGtkWidget

  PGtkSocketClass* = ptr TGtkSocketClass
  TGtkSocketClass* = object of TGtkContainerClass
    plug_added*: proc (socket: PGtkSocket){.cdecl.}
    plug_removed*: proc (socket: PGtkSocket): gboolean{.cdecl.}
    gtk_reserved621: proc (){.cdecl.}
    gtk_reserved622: proc (){.cdecl.}
    gtk_reserved623: proc (){.cdecl.}
    gtk_reserved624: proc (){.cdecl.}

  PGtkSpinButtonUpdatePolicy* = ptr TGtkSpinButtonUpdatePolicy
  TGtkSpinButtonUpdatePolicy* = enum
    GTK_UPDATE_ALWAYS, GTK_UPDATE_IF_VALID
  PGtkSpinType* = ptr TGtkSpinType
  TGtkSpinType* = enum
    GTK_SPIN_STEP_FORWARD, GTK_SPIN_STEP_BACKWARD, GTK_SPIN_PAGE_FORWARD,
    GTK_SPIN_PAGE_BACKWARD, GTK_SPIN_HOME, GTK_SPIN_END, GTK_SPIN_USER_DEFINED
  PGtkSpinButton* = ptr TGtkSpinButton
  TGtkSpinButton* = object of TGtkEntry
    adjustment*: PGtkAdjustment
    panel*: PGdkWindow
    timer*: guint32
    climb_rate*: gdouble
    timer_step*: gdouble
    update_policy*: TGtkSpinButtonUpdatePolicy
    GtkSpinButton_flag0*: int32

  PGtkSpinButtonClass* = ptr TGtkSpinButtonClass
  TGtkSpinButtonClass* = object of TGtkEntryClass
    input*: proc (spin_button: PGtkSpinButton, new_value: Pgdouble): gint{.cdecl.}
    output*: proc (spin_button: PGtkSpinButton): gint{.cdecl.}
    value_changed*: proc (spin_button: PGtkSpinButton){.cdecl.}
    change_value*: proc (spin_button: PGtkSpinButton, scroll: TGtkScrollType){.
        cdecl.}
    gtk_reserved631: proc (){.cdecl.}
    gtk_reserved632: proc (){.cdecl.}
    gtk_reserved633: proc (){.cdecl.}
    gtk_reserved634: proc (){.cdecl.}

  PGtkStockItem* = ptr TGtkStockItem
  TGtkStockItem* {.final, pure.} = object
    stock_id*: cstring
    label*: cstring
    modifier*: TGdkModifierType
    keyval*: guint
    translation_domain*: cstring

  PGtkStatusbar* = ptr TGtkStatusbar
  TGtkStatusbar* = object of TGtkHBox
    frame*: PGtkWidget
    `label`*: PGtkWidget
    messages*: PGSList
    keys*: PGSList
    seq_context_id*: guint
    seq_message_id*: guint
    grip_window*: PGdkWindow
    GtkStatusbar_flag0*: guint16

  PGtkStatusbarClass* = ptr TGtkStatusbarClass
  TGtkStatusbarClass* = object of TGtkHBoxClass
    messages_mem_chunk*: PGMemChunk
    text_pushed*: proc (statusbar: PGtkStatusbar, context_id: guint,
                        text: cstring){.cdecl.}
    text_popped*: proc (statusbar: PGtkStatusbar, context_id: guint,
                        text: cstring){.cdecl.}
    gtk_reserved641: proc (){.cdecl.}
    gtk_reserved642: proc (){.cdecl.}
    gtk_reserved643: proc (){.cdecl.}
    gtk_reserved644: proc (){.cdecl.}

  PGtkTableRowCol* = ptr TGtkTableRowCol
  PGtkTable* = ptr TGtkTable
  TGtkTable* = object of TGtkContainer
    children*: PGList
    rows*: PGtkTableRowCol
    cols*: PGtkTableRowCol
    nrows*: guint16
    ncols*: guint16
    column_spacing*: guint16
    row_spacing*: guint16
    GtkTable_flag0*: guint16

  PGtkTableClass* = ptr TGtkTableClass
  TGtkTableClass* = object of TGtkContainerClass

  PGtkTableChild* = ptr TGtkTableChild
  TGtkTableChild* {.final, pure.} = object
    widget*: PGtkWidget
    left_attach*: guint16
    right_attach*: guint16
    top_attach*: guint16
    bottom_attach*: guint16
    xpadding*: guint16
    ypadding*: guint16
    GtkTableChild_flag0*: guint16

  TGtkTableRowCol* {.final, pure.} = object
    requisition*: guint16
    allocation*: guint16
    spacing*: guint16
    flag0*: guint16

  PGtkTearoffMenuItem* = ptr TGtkTearoffMenuItem
  TGtkTearoffMenuItem* = object of TGtkMenuItem
    GtkTearoffMenuItem_flag0*: guint16

  PGtkTearoffMenuItemClass* = ptr TGtkTearoffMenuItemClass
  TGtkTearoffMenuItemClass* = object of TGtkMenuItemClass
    gtk_reserved651: proc (){.cdecl.}
    gtk_reserved652: proc (){.cdecl.}
    gtk_reserved653: proc (){.cdecl.}
    gtk_reserved654: proc (){.cdecl.}

  PGtkTextFont* = pointer
  PGtkPropertyMark* = ptr TGtkPropertyMark
  TGtkPropertyMark* {.final, pure.} = object
    `property`*: PGList
    offset*: guint
    index*: guint

  PGtkText* = ptr TGtkText
  TGtkText* = object of TGtkOldEditable
    text_area*: PGdkWindow
    hadj*: PGtkAdjustment
    vadj*: PGtkAdjustment
    gc*: PGdkGC
    line_wrap_bitmap*: PGdkPixmap
    line_arrow_bitmap*: PGdkPixmap
    text*: Pguchar
    text_len*: guint
    gap_position*: guint
    gap_size*: guint
    text_end*: guint
    line_start_cache*: PGList
    first_line_start_index*: guint
    first_cut_pixels*: guint
    first_onscreen_hor_pixel*: guint
    first_onscreen_ver_pixel*: guint
    GtkText_flag0*: guint16
    freeze_count*: guint
    text_properties*: PGList
    text_properties_end*: PGList
    point*: TGtkPropertyMark
    scratch_buffer*: Pguchar
    scratch_buffer_len*: guint
    last_ver_value*: gint
    cursor_pos_x*: gint
    cursor_pos_y*: gint
    cursor_mark*: TGtkPropertyMark
    cursor_char*: TGdkWChar
    cursor_char_offset*: gchar
    cursor_virtual_x*: gint
    cursor_drawn_level*: gint
    current_line*: PGList
    tab_stops*: PGList
    default_tab_width*: gint
    current_font*: PGtkTextFont
    timer*: gint
    button*: guint
    bg_gc*: PGdkGC

  PGtkTextClass* = ptr TGtkTextClass
  TGtkTextClass* = object of TGtkOldEditableClass
    set_scroll_adjustments*: proc (text: PGtkText, hadjustment: PGtkAdjustment,
                                   vadjustment: PGtkAdjustment){.cdecl.}

  PGtkTextSearchFlags* = ptr TGtkTextSearchFlags
  TGtkTextSearchFlags* = int32
  PGtkTextIter* = ptr TGtkTextIter
  TGtkTextIter* {.final, pure.} = object
    dummy1*: gpointer
    dummy2*: gpointer
    dummy3*: gint
    dummy4*: gint
    dummy5*: gint
    dummy6*: gint
    dummy7*: gint
    dummy8*: gint
    dummy9*: gpointer
    dummy10*: gpointer
    dummy11*: gint
    dummy12*: gint
    dummy13*: gint
    dummy14*: gpointer

  TGtkTextCharPredicate* = proc (ch: gunichar, user_data: gpointer): gboolean{.
      cdecl.}
  PGtkTextTagClass* = ptr TGtkTextTagClass
  PGtkTextAttributes* = ptr TGtkTextAttributes
  PGtkTextTag* = ptr TGtkTextTag
  PPGtkTextTag* = ptr PGtkTextTag
  TGtkTextTag* = object of TGObject
    table*: PGtkTextTagTable
    name*: cstring
    priority*: int32
    values*: PGtkTextAttributes
    GtkTextTag_flag0*: int32

  TGtkTextTagClass* = object of TGObjectClass
    event*: proc (tag: PGtkTextTag, event_object: PGObject, event: PGdkEvent,
                  iter: PGtkTextIter): gboolean{.cdecl.}
    gtk_reserved661: proc (){.cdecl.}
    gtk_reserved662: proc (){.cdecl.}
    gtk_reserved663: proc (){.cdecl.}
    gtk_reserved664: proc (){.cdecl.}

  PGtkTextAppearance* = ptr TGtkTextAppearance
  TGtkTextAppearance* {.final, pure.} = object
    bg_color*: TGdkColor
    fg_color*: TGdkColor
    bg_stipple*: PGdkBitmap
    fg_stipple*: PGdkBitmap
    rise*: gint
    padding1*: gpointer
    flag0*: guint16

  TGtkTextAttributes* {.final, pure.} = object
    refcount*: guint
    appearance*: TGtkTextAppearance
    justification*: TGtkJustification
    direction*: TGtkTextDirection
    font*: PPangoFontDescription
    font_scale*: gdouble
    left_margin*: gint
    indent*: gint
    right_margin*: gint
    pixels_above_lines*: gint
    pixels_below_lines*: gint
    pixels_inside_wrap*: gint
    tabs*: PPangoTabArray
    wrap_mode*: TGtkWrapMode
    language*: PPangoLanguage
    padding1*: gpointer
    flag0*: guint16

  TGtkTextTagTableForeach* = proc (tag: PGtkTextTag, data: gpointer){.cdecl.}
  TGtkTextTagTable* = object of TGObject
    hash*: PGHashTable
    anonymous*: PGSList
    anon_count*: gint
    buffers*: PGSList

  PGtkTextTagTableClass* = ptr TGtkTextTagTableClass
  TGtkTextTagTableClass* = object of TGObjectClass
    tag_changed*: proc (table: PGtkTextTagTable, tag: PGtkTextTag,
                        size_changed: gboolean){.cdecl.}
    tag_added*: proc (table: PGtkTextTagTable, tag: PGtkTextTag){.cdecl.}
    tag_removed*: proc (table: PGtkTextTagTable, tag: PGtkTextTag){.cdecl.}
    gtk_reserved1: proc (){.cdecl.}
    gtk_reserved2: proc (){.cdecl.}
    gtk_reserved3: proc (){.cdecl.}
    gtk_reserved4: proc (){.cdecl.}

  PGtkTextMark* = ptr TGtkTextMark
  TGtkTextMark* = object of TGObject
    segment*: gpointer

  PGtkTextMarkClass* = ptr TGtkTextMarkClass
  TGtkTextMarkClass* = object of TGObjectClass
    gtk_reserved1: proc (){.cdecl.}
    gtk_reserved2: proc (){.cdecl.}
    gtk_reserved3: proc (){.cdecl.}
    gtk_reserved4: proc (){.cdecl.}

  PGtkTextMarkBody* = ptr TGtkTextMarkBody
  TGtkTextMarkBody* {.final, pure.} = object
    obj*: PGtkTextMark
    name*: cstring
    tree*: PGtkTextBTree
    line*: PGtkTextLine
    flag0*: guint16

  PGtkTextChildAnchor* = ptr TGtkTextChildAnchor
  TGtkTextChildAnchor* = object of TGObject
    segment*: gpointer

  PGtkTextChildAnchorClass* = ptr TGtkTextChildAnchorClass
  TGtkTextChildAnchorClass* = object of TGObjectClass
    gtk_reserved1: proc (){.cdecl.}
    gtk_reserved2: proc (){.cdecl.}
    gtk_reserved3: proc (){.cdecl.}
    gtk_reserved4: proc (){.cdecl.}

  PGtkTextPixbuf* = ptr TGtkTextPixbuf
  TGtkTextPixbuf* {.final, pure.} = object
    pixbuf*: PGdkPixbuf

  PGtkTextChildBody* = ptr TGtkTextChildBody
  TGtkTextChildBody* {.final, pure.} = object
    obj*: PGtkTextChildAnchor
    widgets*: PGSList
    tree*: PGtkTextBTree
    line*: PGtkTextLine

  PGtkTextLineSegment* = ptr TGtkTextLineSegment
  PGtkTextLineSegmentClass* = ptr TGtkTextLineSegmentClass
  PGtkTextTagInfo* = ptr TGtkTextTagInfo
  TGtkTextTagInfo* {.final, pure.} = object
    tag*: PGtkTextTag
    tag_root*: PGtkTextBTreeNode
    toggle_count*: gint

  PGtkTextToggleBody* = ptr TGtkTextToggleBody
  TGtkTextToggleBody* {.final, pure.} = object
    info*: PGtkTextTagInfo
    inNodeCounts*: gboolean

  TGtkTextLineSegment* {.final, pure.} = object
    `type`*: PGtkTextLineSegmentClass
    next*: PGtkTextLineSegment
    char_count*: int32
    byte_count*: int32
    body*: TGtkTextChildBody

  PGtkTextSegSplitFunc* = ptr TGtkTextSegSplitFunc
  TGtkTextSegSplitFunc* = TGtkTextLineSegment
  TGtkTextSegDeleteFunc* = proc (seg: PGtkTextLineSegment, line: PGtkTextLine,
                                 tree_gone: gboolean): gboolean{.cdecl.}
  PGtkTextSegCleanupFunc* = ptr TGtkTextSegCleanupFunc
  TGtkTextSegCleanupFunc* = TGtkTextLineSegment
  TGtkTextSegLineChangeFunc* = proc (seg: PGtkTextLineSegment,
                                     line: PGtkTextLine){.cdecl.}
  TGtkTextSegCheckFunc* = proc (seg: PGtkTextLineSegment, line: PGtkTextLine){.
      cdecl.}
  TGtkTextLineSegmentClass* {.final, pure.} = object
    name*: cstring
    leftGravity*: gboolean
    splitFunc*: TGtkTextSegSplitFunc
    deleteFunc*: TGtkTextSegDeleteFunc
    cleanupFunc*: TGtkTextSegCleanupFunc
    lineChangeFunc*: TGtkTextSegLineChangeFunc
    checkFunc*: TGtkTextSegCheckFunc

  PGtkTextLineData* = ptr TGtkTextLineData
  TGtkTextLineData* {.final, pure.} = object
    view_id*: gpointer
    next*: PGtkTextLineData
    height*: gint
    flag0*: int32

  TGtkTextLine* {.final, pure.} = object
    parent*: PGtkTextBTreeNode
    next*: PGtkTextLine
    segments*: PGtkTextLineSegment
    views*: PGtkTextLineData

  PGtkTextLogAttrCache* = pointer
  PGtkTextBuffer* = ptr TGtkTextBuffer
  TGtkTextBuffer* = object of TGObject
    tag_table*: PGtkTextTagTable
    btree*: PGtkTextBTree
    clipboard_contents_buffers*: PGSList
    selection_clipboards*: PGSList
    log_attr_cache*: PGtkTextLogAttrCache
    user_action_count*: guint
    GtkTextBuffer_flag0*: guint16

  PGtkTextBufferClass* = ptr TGtkTextBufferClass
  TGtkTextBufferClass* = object of TGObjectClass
    insert_text*: proc (buffer: PGtkTextBuffer, pos: PGtkTextIter, text: cstring,
                        length: gint){.cdecl.}
    insert_pixbuf*: proc (buffer: PGtkTextBuffer, pos: PGtkTextIter,
                          pixbuf: PGdkPixbuf){.cdecl.}
    insert_child_anchor*: proc (buffer: PGtkTextBuffer, pos: PGtkTextIter,
                                anchor: PGtkTextChildAnchor){.cdecl.}
    delete_range*: proc (buffer: PGtkTextBuffer, start: PGtkTextIter,
                         theEnd: PGtkTextIter){.cdecl.}
    changed*: proc (buffer: PGtkTextBuffer){.cdecl.}
    modified_changed*: proc (buffer: PGtkTextBuffer){.cdecl.}
    mark_set*: proc (buffer: PGtkTextBuffer, location: PGtkTextIter,
                     mark: PGtkTextMark){.cdecl.}
    mark_deleted*: proc (buffer: PGtkTextBuffer, mark: PGtkTextMark){.cdecl.}
    apply_tag*: proc (buffer: PGtkTextBuffer, tag: PGtkTextTag,
                      start_char: PGtkTextIter, end_char: PGtkTextIter){.cdecl.}
    remove_tag*: proc (buffer: PGtkTextBuffer, tag: PGtkTextTag,
                       start_char: PGtkTextIter, end_char: PGtkTextIter){.cdecl.}
    begin_user_action*: proc (buffer: PGtkTextBuffer){.cdecl.}
    end_user_action*: proc (buffer: PGtkTextBuffer){.cdecl.}
    gtk_reserved1: proc (){.cdecl.}
    gtk_reserved2: proc (){.cdecl.}
    gtk_reserved3: proc (){.cdecl.}
    gtk_reserved4: proc (){.cdecl.}
    gtk_reserved5: proc (){.cdecl.}
    gtk_reserved6: proc (){.cdecl.}

  PGtkTextLineDisplay* = ptr TGtkTextLineDisplay
  PGtkTextLayout* = ptr TGtkTextLayout
  TGtkTextLayout* = object of TGObject
    screen_width*: gint
    width*: gint
    height*: gint
    buffer*: PGtkTextBuffer
    default_style*: PGtkTextAttributes
    ltr_context*: PPangoContext
    rtl_context*: PPangoContext
    one_style_cache*: PGtkTextAttributes
    one_display_cache*: PGtkTextLineDisplay
    wrap_loop_count*: gint
    GtkTextLayout_flag0*: guint16
    preedit_string*: cstring
    preedit_attrs*: PPangoAttrList
    preedit_len*: gint
    preedit_cursor*: gint

  PGtkTextLayoutClass* = ptr TGtkTextLayoutClass
  TGtkTextLayoutClass* = object of TGObjectClass
    invalidated*: proc (layout: PGtkTextLayout){.cdecl.}
    changed*: proc (layout: PGtkTextLayout, y: gint, old_height: gint,
                    new_height: gint){.cdecl.}
    wrap*: proc (layout: PGtkTextLayout, line: PGtkTextLine,
                 line_data: PGtkTextLineData): PGtkTextLineData{.cdecl.}
    get_log_attrs*: proc (layout: PGtkTextLayout, line: PGtkTextLine,
                          attrs: var PPangoLogAttr, n_attrs: Pgint){.cdecl.}
    invalidate*: proc (layout: PGtkTextLayout, start: PGtkTextIter,
                       theEnd: PGtkTextIter){.cdecl.}
    free_line_data*: proc (layout: PGtkTextLayout, line: PGtkTextLine,
                           line_data: PGtkTextLineData){.cdecl.}
    allocate_child*: proc (layout: PGtkTextLayout, child: PGtkWidget, x: gint,
                           y: gint){.cdecl.}
    gtk_reserved1: proc (){.cdecl.}
    gtk_reserved2: proc (){.cdecl.}
    gtk_reserved3: proc (){.cdecl.}
    gtk_reserved4: proc (){.cdecl.}

  PGtkTextAttrAppearance* = ptr TGtkTextAttrAppearance
  TGtkTextAttrAppearance* {.final, pure.} = object
    attr*: TPangoAttribute
    appearance*: TGtkTextAppearance

  PGtkTextCursorDisplay* = ptr TGtkTextCursorDisplay
  TGtkTextCursorDisplay* {.final, pure.} = object
    x*: gint
    y*: gint
    height*: gint
    flag0*: guint16

  TGtkTextLineDisplay* {.final, pure.} = object
    layout*: PPangoLayout
    cursors*: PGSList
    shaped_objects*: PGSList
    direction*: TGtkTextDirection
    width*: gint
    total_width*: gint
    height*: gint
    x_offset*: gint
    left_margin*: gint
    right_margin*: gint
    top_margin*: gint
    bottom_margin*: gint
    insert_index*: gint
    size_only*: gboolean
    line*: PGtkTextLine

  PGtkTextWindow* = pointer
  PGtkTextPendingScroll* = pointer
  PGtkTextWindowType* = ptr TGtkTextWindowType
  TGtkTextWindowType* = enum
    GTK_TEXT_WINDOW_PRIVATE, GTK_TEXT_WINDOW_WIDGET, GTK_TEXT_WINDOW_TEXT,
    GTK_TEXT_WINDOW_LEFT, GTK_TEXT_WINDOW_RIGHT, GTK_TEXT_WINDOW_TOP,
    GTK_TEXT_WINDOW_BOTTOM
  PGtkTextView* = ptr TGtkTextView
  TGtkTextView* = object of TGtkContainer
    layout*: PGtkTextLayout
    buffer*: PGtkTextBuffer
    selection_drag_handler*: guint
    scroll_timeout*: guint
    pixels_above_lines*: gint
    pixels_below_lines*: gint
    pixels_inside_wrap*: gint
    wrap_mode*: TGtkWrapMode
    justify*: TGtkJustification
    left_margin*: gint
    right_margin*: gint
    indent*: gint
    tabs*: PPangoTabArray
    GtkTextView_flag0*: guint16
    text_window*: PGtkTextWindow
    left_window*: PGtkTextWindow
    right_window*: PGtkTextWindow
    top_window*: PGtkTextWindow
    bottom_window*: PGtkTextWindow
    hadjustment*: PGtkAdjustment
    vadjustment*: PGtkAdjustment
    xoffset*: gint
    yoffset*: gint
    width*: gint
    height*: gint
    virtual_cursor_x*: gint
    virtual_cursor_y*: gint
    first_para_mark*: PGtkTextMark
    first_para_pixels*: gint
    dnd_mark*: PGtkTextMark
    blink_timeout*: guint
    first_validate_idle*: guint
    incremental_validate_idle*: guint
    im_context*: PGtkIMContext
    popup_menu*: PGtkWidget
    drag_start_x*: gint
    drag_start_y*: gint
    children*: PGSList
    pending_scroll*: PGtkTextPendingScroll
    pending_place_cursor_button*: gint

  PGtkTextViewClass* = ptr TGtkTextViewClass
  TGtkTextViewClass* = object of TGtkContainerClass
    set_scroll_adjustments*: proc (text_view: PGtkTextView,
                                   hadjustment: PGtkAdjustment,
                                   vadjustment: PGtkAdjustment){.cdecl.}
    populate_popup*: proc (text_view: PGtkTextView, menu: PGtkMenu){.cdecl.}
    move_cursor*: proc (text_view: PGtkTextView, step: TGtkMovementStep,
                        count: gint, extend_selection: gboolean){.cdecl.}
    page_horizontally*: proc (text_view: PGtkTextView, count: gint,
                              extend_selection: gboolean){.cdecl.}
    set_anchor*: proc (text_view: PGtkTextView){.cdecl.}
    insert_at_cursor*: proc (text_view: PGtkTextView, str: cstring){.cdecl.}
    delete_from_cursor*: proc (text_view: PGtkTextView, thetype: TGtkDeleteType,
                               count: gint){.cdecl.}
    cut_clipboard*: proc (text_view: PGtkTextView){.cdecl.}
    copy_clipboard*: proc (text_view: PGtkTextView){.cdecl.}
    paste_clipboard*: proc (text_view: PGtkTextView){.cdecl.}
    toggle_overwrite*: proc (text_view: PGtkTextView){.cdecl.}
    move_focus*: proc (text_view: PGtkTextView, direction: TGtkDirectionType){.
        cdecl.}
    gtk_reserved711: proc (){.cdecl.}
    gtk_reserved712: proc (){.cdecl.}
    gtk_reserved713: proc (){.cdecl.}
    gtk_reserved714: proc (){.cdecl.}
    gtk_reserved715: proc (){.cdecl.}
    gtk_reserved716: proc (){.cdecl.}
    gtk_reserved717: proc (){.cdecl.}
    gtk_reserved718: proc (){.cdecl.}

  PGtkTipsQuery* = ptr TGtkTipsQuery
  TGtkTipsQuery* = object of TGtkLabel
    GtkTipsQuery_flag0*: guint16
    label_inactive*: cstring
    label_no_tip*: cstring
    caller*: PGtkWidget
    last_crossed*: PGtkWidget
    query_cursor*: PGdkCursor

  PGtkTipsQueryClass* = ptr TGtkTipsQueryClass
  TGtkTipsQueryClass* = object of TGtkLabelClass
    start_query*: proc (tips_query: PGtkTipsQuery){.cdecl.}
    stop_query*: proc (tips_query: PGtkTipsQuery){.cdecl.}
    widget_entered*: proc (tips_query: PGtkTipsQuery, widget: PGtkWidget,
                           tip_text: cstring, tip_private: cstring){.cdecl.}
    widget_selected*: proc (tips_query: PGtkTipsQuery, widget: PGtkWidget,
                            tip_text: cstring, tip_private: cstring,
                            event: PGdkEventButton): gint{.cdecl.}
    gtk_reserved721: proc (){.cdecl.}
    gtk_reserved722: proc (){.cdecl.}
    gtk_reserved723: proc (){.cdecl.}
    gtk_reserved724: proc (){.cdecl.}

  PGtkTooltips* = ptr TGtkTooltips
  PGtkTooltipsData* = ptr TGtkTooltipsData
  TGtkTooltipsData* {.final, pure.} = object
    tooltips*: PGtkTooltips
    widget*: PGtkWidget
    tip_text*: cstring
    tip_private*: cstring

  TGtkTooltips* = object of TGtkObject
    tip_window*: PGtkWidget
    tip_label*: PGtkWidget
    active_tips_data*: PGtkTooltipsData
    tips_data_list*: PGList
    GtkTooltips_flag0*: int32
    flag1*: guint16
    timer_tag*: gint
    last_popdown*: TGTimeVal

  PGtkTooltipsClass* = ptr TGtkTooltipsClass
  TGtkTooltipsClass* = object of TGtkObjectClass
    gtk_reserved1: proc (){.cdecl.}
    gtk_reserved2: proc (){.cdecl.}
    gtk_reserved3: proc (){.cdecl.}
    gtk_reserved4: proc (){.cdecl.}

  PGtkToolbarChildType* = ptr TGtkToolbarChildType
  TGtkToolbarChildType* = enum
    GTK_TOOLBAR_CHILD_SPACE, GTK_TOOLBAR_CHILD_BUTTON,
    GTK_TOOLBAR_CHILD_TOGGLEBUTTON, GTK_TOOLBAR_CHILD_RADIOBUTTON,
    GTK_TOOLBAR_CHILD_WIDGET
  PGtkToolbarSpaceStyle* = ptr TGtkToolbarSpaceStyle
  TGtkToolbarSpaceStyle* = enum
    GTK_TOOLBAR_SPACE_EMPTY, GTK_TOOLBAR_SPACE_LINE
  PGtkToolbarChild* = ptr TGtkToolbarChild
  TGtkToolbarChild* {.final, pure.} = object
    `type`*: TGtkToolbarChildType
    widget*: PGtkWidget
    icon*: PGtkWidget
    label*: PGtkWidget

  PGtkToolbar* = ptr TGtkToolbar
  TGtkToolbar* = object of TGtkContainer
    num_children*: gint
    children*: PGList
    orientation*: TGtkOrientation
    GtkToolbar_style*: TGtkToolbarStyle
    icon_size*: TGtkIconSize
    tooltips*: PGtkTooltips
    button_maxw*: gint
    button_maxh*: gint
    style_set_connection*: guint
    icon_size_connection*: guint
    GtkToolbar_flag0*: guint16

  PGtkToolbarClass* = ptr TGtkToolbarClass
  TGtkToolbarClass* = object of TGtkContainerClass
    orientation_changed*: proc (toolbar: PGtkToolbar,
                                orientation: TGtkOrientation){.cdecl.}
    style_changed*: proc (toolbar: PGtkToolbar, style: TGtkToolbarStyle){.cdecl.}
    gtk_reserved731: proc (){.cdecl.}
    gtk_reserved732: proc (){.cdecl.}
    gtk_reserved733: proc (){.cdecl.}
    gtk_reserved734: proc (){.cdecl.}

  PGtkTreeViewMode* = ptr TGtkTreeViewMode
  TGtkTreeViewMode* = enum
    GTK_TREE_VIEW_LINE, GTK_TREE_VIEW_ITEM
  PGtkTree* = ptr TGtkTree
  TGtkTree* = object of TGtkContainer
    children*: PGList
    root_tree*: PGtkTree
    tree_owner*: PGtkWidget
    selection*: PGList
    level*: guint
    indent_value*: guint
    current_indent*: guint
    GtkTree_flag0*: guint16

  PGtkTreeClass* = ptr TGtkTreeClass
  TGtkTreeClass* = object of TGtkContainerClass
    selection_changed*: proc (tree: PGtkTree){.cdecl.}
    select_child*: proc (tree: PGtkTree, child: PGtkWidget){.cdecl.}
    unselect_child*: proc (tree: PGtkTree, child: PGtkWidget){.cdecl.}

  PGtkTreeDragSource* = pointer
  PGtkTreeDragDest* = pointer
  PGtkTreeDragSourceIface* = ptr TGtkTreeDragSourceIface
  TGtkTreeDragSourceIface* = object of TGTypeInterface
    row_draggable*: proc (drag_source: PGtkTreeDragSource, path: PGtkTreePath): gboolean{.
        cdecl.}
    drag_data_get*: proc (drag_source: PGtkTreeDragSource, path: PGtkTreePath,
                          selection_data: PGtkSelectionData): gboolean{.cdecl.}
    drag_data_delete*: proc (drag_source: PGtkTreeDragSource, path: PGtkTreePath): gboolean{.
        cdecl.}

  PGtkTreeDragDestIface* = ptr TGtkTreeDragDestIface
  TGtkTreeDragDestIface* = object of TGTypeInterface
    drag_data_received*: proc (drag_dest: PGtkTreeDragDest, dest: PGtkTreePath,
                               selection_data: PGtkSelectionData): gboolean{.
        cdecl.}
    row_drop_possible*: proc (drag_dest: PGtkTreeDragDest,
                              dest_path: PGtkTreePath,
                              selection_data: PGtkSelectionData): gboolean{.
        cdecl.}

  PGtkTreeItem* = ptr TGtkTreeItem
  TGtkTreeItem* = object of TGtkItem
    subtree*: PGtkWidget
    pixmaps_box*: PGtkWidget
    plus_pix_widget*: PGtkWidget
    minus_pix_widget*: PGtkWidget
    pixmaps*: PGList
    GtkTreeItem_flag0*: guint16

  PGtkTreeItemClass* = ptr TGtkTreeItemClass
  TGtkTreeItemClass* = object of TGtkItemClass
    expand*: proc (tree_item: PGtkTreeItem){.cdecl.}
    collapse*: proc (tree_item: PGtkTreeItem){.cdecl.}

  PGtkTreeSelection* = ptr TGtkTreeSelection
  TGtkTreeSelectionFunc* = proc (selection: PGtkTreeSelection,
                                 model: PGtkTreeModel, path: PGtkTreePath,
                                 path_currently_selected: gboolean,
                                 data: gpointer): gboolean{.cdecl.}
  TGtkTreeSelectionForeachFunc* = proc (model: PGtkTreeModel,
                                        path: PGtkTreePath, iter: PGtkTreeIter,
                                        data: gpointer){.cdecl.}
  TGtkTreeSelection* = object of TGObject
    tree_view*: PGtkTreeView
    thetype*: TGtkSelectionMode
    user_func*: TGtkTreeSelectionFunc
    user_data*: gpointer
    destroy*: TGtkDestroyNotify

  PGtkTreeSelectionClass* = ptr TGtkTreeSelectionClass
  TGtkTreeSelectionClass* = object of TGObjectClass
    changed*: proc (selection: PGtkTreeSelection){.cdecl.}
    gtk_reserved741: proc (){.cdecl.}
    gtk_reserved742: proc (){.cdecl.}
    gtk_reserved743: proc (){.cdecl.}
    gtk_reserved744: proc (){.cdecl.}

  PGtkTreeStore* = ptr TGtkTreeStore
  TGtkTreeStore* = object of TGObject
    stamp*: gint
    root*: gpointer
    last*: gpointer
    n_columns*: gint
    sort_column_id*: gint
    sort_list*: PGList
    order*: TGtkSortType
    column_headers*: PGType
    default_sort_func*: TGtkTreeIterCompareFunc
    default_sort_data*: gpointer
    default_sort_destroy*: TGtkDestroyNotify
    GtkTreeStore_flag0*: guint16

  PGtkTreeStoreClass* = ptr TGtkTreeStoreClass
  TGtkTreeStoreClass* = object of TGObjectClass
    gtk_reserved751: proc (){.cdecl.}
    gtk_reserved752: proc (){.cdecl.}
    gtk_reserved753: proc (){.cdecl.}
    gtk_reserved754: proc (){.cdecl.}

  PGtkTreeViewColumnSizing* = ptr TGtkTreeViewColumnSizing
  TGtkTreeViewColumnSizing* = enum
    GTK_TREE_VIEW_COLUMN_GROW_ONLY, GTK_TREE_VIEW_COLUMN_AUTOSIZE,
    GTK_TREE_VIEW_COLUMN_FIXED
  TGtkTreeCellDataFunc* = proc (tree_column: PGtkTreeViewColumn,
                                cell: PGtkCellRenderer,
                                tree_model: PGtkTreeModel, iter: PGtkTreeIter,
                                data: gpointer){.cdecl.}
  TGtkTreeViewColumn* = object of TGtkObject
    tree_view*: PGtkWidget
    button*: PGtkWidget
    child*: PGtkWidget
    arrow*: PGtkWidget
    alignment*: PGtkWidget
    window*: PGdkWindow
    editable_widget*: PGtkCellEditable
    xalign*: gfloat
    property_changed_signal*: guint
    spacing*: gint
    column_type*: TGtkTreeViewColumnSizing
    requested_width*: gint
    button_request*: gint
    resized_width*: gint
    width*: gint
    fixed_width*: gint
    min_width*: gint
    max_width*: gint
    drag_x*: gint
    drag_y*: gint
    title*: cstring
    cell_list*: PGList
    sort_clicked_signal*: guint
    sort_column_changed_signal*: guint
    sort_column_id*: gint
    sort_order*: TGtkSortType
    GtkTreeViewColumn_flag0*: guint16

  PGtkTreeViewColumnClass* = ptr TGtkTreeViewColumnClass
  TGtkTreeViewColumnClass* = object of TGtkObjectClass
    clicked*: proc (tree_column: PGtkTreeViewColumn){.cdecl.}
    gtk_reserved751: proc (){.cdecl.}
    gtk_reserved752: proc (){.cdecl.}
    gtk_reserved753: proc (){.cdecl.}
    gtk_reserved754: proc (){.cdecl.}

  PGtkRBNodeColor* = ptr TGtkRBNodeColor
  TGtkRBNodeColor* = int32
  PGtkRBTree* = ptr TGtkRBTree
  PGtkRBNode* = ptr TGtkRBNode
  TGtkRBTreeTraverseFunc* = proc (tree: PGtkRBTree, node: PGtkRBNode,
                                  data: gpointer){.cdecl.}
  TGtkRBTree* {.final, pure.} = object
    root*: PGtkRBNode
    `nil`*: PGtkRBNode
    parent_tree*: PGtkRBTree
    parent_node*: PGtkRBNode

  TGtkRBNode* {.final, pure.} = object
    flag0*: guint16
    left*: PGtkRBNode
    right*: PGtkRBNode
    parent*: PGtkRBNode
    count*: gint
    offset*: gint
    children*: PGtkRBTree

  PGtkTreeRowReference* = pointer
  PGtkTreeViewFlags* = ptr TGtkTreeViewFlags
  TGtkTreeViewFlags* = int32
  TGtkTreeViewSearchDialogPositionFunc* = proc (tree_view: PGtkTreeView,
      search_dialog: PGtkWidget){.cdecl.}
  PGtkTreeViewColumnReorder* = ptr TGtkTreeViewColumnReorder
  TGtkTreeViewColumnReorder* {.final, pure.} = object
    left_align*: gint
    right_align*: gint
    left_column*: PGtkTreeViewColumn
    right_column*: PGtkTreeViewColumn

  PGtkTreeViewPrivate* = ptr TGtkTreeViewPrivate
  TGtkTreeViewPrivate* {.final, pure.} = object
    model*: PGtkTreeModel
    flags*: guint
    tree*: PGtkRBTree
    button_pressed_node*: PGtkRBNode
    button_pressed_tree*: PGtkRBTree
    children*: PGList
    width*: gint
    height*: gint
    expander_size*: gint
    hadjustment*: PGtkAdjustment
    vadjustment*: PGtkAdjustment
    bin_window*: PGdkWindow
    header_window*: PGdkWindow
    drag_window*: PGdkWindow
    drag_highlight_window*: PGdkWindow
    drag_column*: PGtkTreeViewColumn
    last_button_press*: PGtkTreeRowReference
    last_button_press_2*: PGtkTreeRowReference
    top_row*: PGtkTreeRowReference
    top_row_dy*: gint
    dy*: gint
    drag_column_x*: gint
    expander_column*: PGtkTreeViewColumn
    edited_column*: PGtkTreeViewColumn
    presize_handler_timer*: guint
    validate_rows_timer*: guint
    scroll_sync_timer*: guint
    focus_column*: PGtkTreeViewColumn
    anchor*: PGtkTreeRowReference
    cursor*: PGtkTreeRowReference
    drag_pos*: gint
    x_drag*: gint
    prelight_node*: PGtkRBNode
    prelight_tree*: PGtkRBTree
    expanded_collapsed_node*: PGtkRBNode
    expanded_collapsed_tree*: PGtkRBTree
    expand_collapse_timeout*: guint
    selection*: PGtkTreeSelection
    n_columns*: gint
    columns*: PGList
    header_height*: gint
    column_drop_func*: TGtkTreeViewColumnDropFunc
    column_drop_func_data*: gpointer
    column_drop_func_data_destroy*: TGtkDestroyNotify
    column_drag_info*: PGList
    cur_reorder*: PGtkTreeViewColumnReorder
    destroy_count_func*: TGtkTreeDestroyCountFunc
    destroy_count_data*: gpointer
    destroy_count_destroy*: TGtkDestroyNotify
    scroll_timeout*: guint
    drag_dest_row*: PGtkTreeRowReference
    drag_dest_pos*: TGtkTreeViewDropPosition
    open_dest_timeout*: guint
    pressed_button*: gint
    press_start_x*: gint
    press_start_y*: gint
    scroll_to_path*: PGtkTreeRowReference
    scroll_to_column*: PGtkTreeViewColumn
    scroll_to_row_align*: gfloat
    scroll_to_col_align*: gfloat
    flag0*: guint16
    search_column*: gint
    search_dialog_position_func*: TGtkTreeViewSearchDialogPositionFunc
    search_equal_func*: TGtkTreeViewSearchEqualFunc
    search_user_data*: gpointer
    search_destroy*: TGtkDestroyNotify

  TGtkTreeView* = object of TGtkContainer
    priv*: PGtkTreeViewPrivate

  PGtkTreeViewClass* = ptr TGtkTreeViewClass
  TGtkTreeViewClass* = object of TGtkContainerClass
    set_scroll_adjustments*: proc (tree_view: PGtkTreeView,
                                   hadjustment: PGtkAdjustment,
                                   vadjustment: PGtkAdjustment){.cdecl.}
    row_activated*: proc (tree_view: PGtkTreeView, path: PGtkTreePath,
                          column: PGtkTreeViewColumn){.cdecl.}
    test_expand_row*: proc (tree_view: PGtkTreeView, iter: PGtkTreeIter,
                            path: PGtkTreePath): gboolean{.cdecl.}
    test_collapse_row*: proc (tree_view: PGtkTreeView, iter: PGtkTreeIter,
                              path: PGtkTreePath): gboolean{.cdecl.}
    row_expanded*: proc (tree_view: PGtkTreeView, iter: PGtkTreeIter,
                         path: PGtkTreePath){.cdecl.}
    row_collapsed*: proc (tree_view: PGtkTreeView, iter: PGtkTreeIter,
                          path: PGtkTreePath){.cdecl.}
    columns_changed*: proc (tree_view: PGtkTreeView){.cdecl.}
    cursor_changed*: proc (tree_view: PGtkTreeView){.cdecl.}
    move_cursor*: proc (tree_view: PGtkTreeView, step: TGtkMovementStep,
                        count: gint): gboolean{.cdecl.}
    select_all*: proc (tree_view: PGtkTreeView){.cdecl.}
    unselect_all*: proc (tree_view: PGtkTreeView){.cdecl.}
    select_cursor_row*: proc (tree_view: PGtkTreeView, start_editing: gboolean){.
        cdecl.}
    toggle_cursor_row*: proc (tree_view: PGtkTreeView){.cdecl.}
    expand_collapse_cursor_row*: proc (tree_view: PGtkTreeView,
                                       logical: gboolean, expand: gboolean,
                                       open_all: gboolean){.cdecl.}
    select_cursor_parent*: proc (tree_view: PGtkTreeView){.cdecl.}
    start_interactive_search*: proc (tree_view: PGtkTreeView){.cdecl.}
    gtk_reserved760: proc (){.cdecl.}
    gtk_reserved761: proc (){.cdecl.}
    gtk_reserved762: proc (){.cdecl.}
    gtk_reserved763: proc (){.cdecl.}
    gtk_reserved764: proc (){.cdecl.}

  PGtkVButtonBox* = ptr TGtkVButtonBox
  TGtkVButtonBox* = object of TGtkButtonBox

  PGtkVButtonBoxClass* = ptr TGtkVButtonBoxClass
  TGtkVButtonBoxClass* = object of TGtkButtonBoxClass

  PGtkViewport* = ptr TGtkViewport
  TGtkViewport* = object of TGtkBin
    shadow_type*: TGtkShadowType
    view_window*: PGdkWindow
    bin_window*: PGdkWindow
    hadjustment*: PGtkAdjustment
    vadjustment*: PGtkAdjustment

  PGtkViewportClass* = ptr TGtkViewportClass
  TGtkViewportClass* = object of TGtkBinClass
    set_scroll_adjustments*: proc (viewport: PGtkViewport,
                                   hadjustment: PGtkAdjustment,
                                   vadjustment: PGtkAdjustment){.cdecl.}

  PGtkVPaned* = ptr TGtkVPaned
  TGtkVPaned* = object of TGtkPaned

  PGtkVPanedClass* = ptr TGtkVPanedClass
  TGtkVPanedClass* = object of TGtkPanedClass

  PGtkVRuler* = ptr TGtkVRuler
  TGtkVRuler* = object of TGtkRuler

  PGtkVRulerClass* = ptr TGtkVRulerClass
  TGtkVRulerClass* = object of TGtkRulerClass

  PGtkVScale* = ptr TGtkVScale
  TGtkVScale* = object of TGtkScale

  PGtkVScaleClass* = ptr TGtkVScaleClass
  TGtkVScaleClass* = object of TGtkScaleClass

  PGtkVScrollbar* = ptr TGtkVScrollbar
  TGtkVScrollbar* = object of TGtkScrollbar

  PGtkVScrollbarClass* = ptr TGtkVScrollbarClass
  TGtkVScrollbarClass* = object of TGtkScrollbarClass

  PGtkVSeparator* = ptr TGtkVSeparator
  TGtkVSeparator* = object of TGtkSeparator

  PGtkVSeparatorClass* = ptr TGtkVSeparatorClass
  TGtkVSeparatorClass* = object of TGtkSeparatorClass


const
  GTK_IN_DESTRUCTION* = 1 shl 0
  GTK_FLOATING* = 1 shl 1
  GTK_RESERVED_1* = 1 shl 2
  GTK_RESERVED_2* = 1 shl 3
  GTK_ARG_READABLE* = G_PARAM_READABLE
  GTK_ARG_WRITABLE* = G_PARAM_WRITABLE
  GTK_ARG_CONSTRUCT* = G_PARAM_CONSTRUCT
  GTK_ARG_CONSTRUCT_ONLY* = G_PARAM_CONSTRUCT_ONLY
  GTK_ARG_CHILD_ARG* = 1 shl 4

proc GTK_TYPE_OBJECT*(): GType
proc GTK_OBJECT*(anObject: pointer): PGtkObject
proc GTK_OBJECT_CLASS*(klass: pointer): PGtkObjectClass
proc GTK_IS_OBJECT*(anObject: pointer): bool
proc GTK_IS_OBJECT_CLASS*(klass: pointer): bool
proc GTK_OBJECT_GET_CLASS*(anObject: pointer): PGtkObjectClass
proc GTK_OBJECT_TYPE*(anObject: pointer): GType
proc GTK_OBJECT_TYPE_NAME*(anObject: pointer): cstring
proc GTK_OBJECT_FLAGS*(obj: pointer): guint32
proc GTK_OBJECT_FLOATING*(obj: pointer): gboolean
proc GTK_OBJECT_SET_FLAGS*(obj: pointer, flag: guint32)
proc GTK_OBJECT_UNSET_FLAGS*(obj: pointer, flag: guint32)
proc gtk_object_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_object_get_type".}
proc gtk_object_new*(thetype: TGtkType, first_property_name: cstring): PGtkObject{.
    cdecl, varargs, dynlib: gtklib, importc: "gtk_object_new".}
proc gtk_object_sink*(anObject: PGtkObject){.cdecl, dynlib: gtklib,
    importc: "gtk_object_sink".}
proc gtk_object_destroy*(anObject: PGtkObject){.cdecl, dynlib: gtklib,
    importc: "gtk_object_destroy".}
const
  GTK_TYPE_INVALID* = G_TYPE_INVALID
  GTK_TYPE_NONE* = G_TYPE_NONE
  GTK_TYPE_ENUM* = G_TYPE_ENUM
  GTK_TYPE_FLAGS* = G_TYPE_FLAGS
  GTK_TYPE_CHAR* = G_TYPE_CHAR
  GTK_TYPE_UCHAR* = G_TYPE_UCHAR
  GTK_TYPE_BOOL* = G_TYPE_BOOLEAN
  GTK_TYPE_INT* = G_TYPE_INT
  GTK_TYPE_UINT* = G_TYPE_UINT
  GTK_TYPE_LONG* = G_TYPE_LONG
  GTK_TYPE_ULONG* = G_TYPE_ULONG
  GTK_TYPE_FLOAT* = G_TYPE_FLOAT
  GTK_TYPE_DOUBLE* = G_TYPE_DOUBLE
  GTK_TYPE_STRING* = G_TYPE_STRING
  GTK_TYPE_BOXED* = G_TYPE_BOXED
  GTK_TYPE_POINTER* = G_TYPE_POINTER

proc GTK_TYPE_IDENTIFIER*(): GType
proc gtk_identifier_get_type*(): GType{.cdecl, dynlib: gtklib,
                                        importc: "gtk_identifier_get_type".}
proc GTK_SIGNAL_FUNC*(f: pointer): TGtkSignalFunc
proc gtk_type_class*(thetype: TGtkType): gpointer{.cdecl, dynlib: gtklib,
    importc: "gtk_type_class".}
const
  GTK_TOPLEVEL* = 1 shl 4
  GTK_NO_WINDOW* = 1 shl 5
  GTK_REALIZED* = 1 shl 6
  GTK_MAPPED* = 1 shl 7
  GTK_VISIBLE* = 1 shl 8
  GTK_SENSITIVE* = 1 shl 9
  GTK_PARENT_SENSITIVE* = 1 shl 10
  GTK_CAN_FOCUS* = 1 shl 11
  GTK_HAS_FOCUS* = 1 shl 12
  GTK_CAN_DEFAULT* = 1 shl 13
  GTK_HAS_DEFAULT* = 1 shl 14
  GTK_HAS_GRAB* = 1 shl 15
  GTK_RC_STYLE* = 1 shl 16
  GTK_COMPOSITE_CHILD* = 1 shl 17
  GTK_NO_REPARENT* = 1 shl 18
  GTK_APP_PAINTABLE* = 1 shl 19
  GTK_RECEIVES_DEFAULT* = 1 shl 20
  GTK_DOUBLE_BUFFERED* = 1 shl 21

const
  bm_TGtkWidgetAuxInfo_x_set* = 0x00000001'i16
  bp_TGtkWidgetAuxInfo_x_set* = 0'i16
  bm_TGtkWidgetAuxInfo_y_set* = 0x00000002'i16
  bp_TGtkWidgetAuxInfo_y_set* = 1'i16

proc GTK_TYPE_WIDGET*(): GType
proc GTK_WIDGET*(widget: pointer): PGtkWidget
proc GTK_WIDGET_CLASS*(klass: pointer): PGtkWidgetClass
proc GTK_IS_WIDGET*(widget: pointer): bool
proc GTK_IS_WIDGET_CLASS*(klass: pointer): bool
proc GTK_WIDGET_GET_CLASS*(obj: pointer): PGtkWidgetClass
proc GTK_WIDGET_TYPE*(wid: pointer): GType
proc GTK_WIDGET_STATE*(wid: pointer): int32
proc GTK_WIDGET_SAVED_STATE*(wid: pointer): int32
proc GTK_WIDGET_FLAGS*(wid: pointer): guint32
proc GTK_WIDGET_TOPLEVEL*(wid: pointer): gboolean
proc GTK_WIDGET_NO_WINDOW*(wid: pointer): gboolean
proc GTK_WIDGET_REALIZED*(wid: pointer): gboolean
proc GTK_WIDGET_MAPPED*(wid: pointer): gboolean
proc GTK_WIDGET_VISIBLE*(wid: pointer): gboolean
proc GTK_WIDGET_DRAWABLE*(wid: pointer): gboolean
proc GTK_WIDGET_SENSITIVE*(wid: pointer): gboolean
proc GTK_WIDGET_PARENT_SENSITIVE*(wid: pointer): gboolean
proc GTK_WIDGET_IS_SENSITIVE*(wid: pointer): gboolean
proc GTK_WIDGET_CAN_FOCUS*(wid: pointer): gboolean
proc GTK_WIDGET_HAS_FOCUS*(wid: pointer): gboolean
proc GTK_WIDGET_CAN_DEFAULT*(wid: pointer): gboolean
proc GTK_WIDGET_HAS_DEFAULT*(wid: pointer): gboolean
proc GTK_WIDGET_HAS_GRAB*(wid: pointer): gboolean
proc GTK_WIDGET_RC_STYLE*(wid: pointer): gboolean
proc GTK_WIDGET_COMPOSITE_CHILD*(wid: pointer): gboolean
proc GTK_WIDGET_APP_PAINTABLE*(wid: pointer): gboolean
proc GTK_WIDGET_RECEIVES_DEFAULT*(wid: pointer): gboolean
proc GTK_WIDGET_DOUBLE_BUFFERED*(wid: pointer): gboolean
proc GTK_WIDGET_SET_FLAGS*(wid: PGtkWidget, flags: TGtkWidgetFlags): TGtkWidgetFlags
proc GTK_WIDGET_UNSET_FLAGS*(wid: PGtkWidget, flags: TGtkWidgetFlags): TGtkWidgetFlags
proc GTK_TYPE_REQUISITION*(): GType
proc x_set*(a: var TGtkWidgetAuxInfo): guint
proc set_x_set*(a: var TGtkWidgetAuxInfo, x_set: guint)
proc y_set*(a: var TGtkWidgetAuxInfo): guint
proc set_y_set*(a: var TGtkWidgetAuxInfo, y_set: guint)
proc gtk_widget_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_widget_get_type".}
proc gtk_widget_ref*(widget: PGtkWidget): PGtkWidget{.cdecl, dynlib: gtklib,
    importc: "gtk_widget_ref".}
proc gtk_widget_unref*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_unref".}
proc gtk_widget_destroy*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_destroy".}
proc gtk_widget_destroyed*(widget: PGtkWidget, r: var PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_destroyed".}
proc gtk_widget_unparent*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_unparent".}
proc gtk_widget_show*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_show".}
proc gtk_widget_show_now*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_show_now".}
proc gtk_widget_hide*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_hide".}
proc gtk_widget_show_all*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_show_all".}
proc gtk_widget_hide_all*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_hide_all".}
proc gtk_widget_map*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_map".}
proc gtk_widget_unmap*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_unmap".}
proc gtk_widget_realize*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_realize".}
proc gtk_widget_unrealize*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_unrealize".}
proc gtk_widget_queue_draw*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_queue_draw".}
proc gtk_widget_queue_draw_area*(widget: PGtkWidget, x: gint, y: gint,
                                 width: gint, height: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_queue_draw_area".}
proc gtk_widget_queue_resize*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_queue_resize".}
proc gtk_widget_size_request*(widget: PGtkWidget, requisition: PGtkRequisition){.
    cdecl, dynlib: gtklib, importc: "gtk_widget_size_request".}
proc gtk_widget_size_allocate*(widget: PGtkWidget, allocation: PGtkAllocation){.
    cdecl, dynlib: gtklib, importc: "gtk_widget_size_allocate".}
proc gtk_widget_get_child_requisition*(widget: PGtkWidget,
                                       requisition: PGtkRequisition){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_child_requisition".}
proc gtk_widget_add_accelerator*(widget: PGtkWidget, accel_signal: cstring,
                                 accel_group: PGtkAccelGroup, accel_key: guint,
                                 accel_mods: TGdkModifierType,
                                 accel_flags: TGtkAccelFlags){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_add_accelerator".}
proc gtk_widget_remove_accelerator*(widget: PGtkWidget,
                                    accel_group: PGtkAccelGroup,
                                    accel_key: guint,
                                    accel_mods: TGdkModifierType): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_remove_accelerator".}
proc gtk_widget_set_accel_path*(widget: PGtkWidget, accel_path: cstring,
                                accel_group: PGtkAccelGroup){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_accel_path".}
proc gtk_widget_get_accel_path*(widget: PGtkWidget, locked: Pgboolean): cstring{.
    cdecl, dynlib: gtklib, importc: "_gtk_widget_get_accel_path".}
proc gtk_widget_list_accel_closures*(widget: PGtkWidget): PGList{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_list_accel_closures".}
proc gtk_widget_mnemonic_activate*(widget: PGtkWidget, group_cycling: gboolean): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_mnemonic_activate".}
proc gtk_widget_event*(widget: PGtkWidget, event: PGdkEvent): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_event".}
proc gtk_widget_send_expose*(widget: PGtkWidget, event: PGdkEvent): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_send_expose".}
proc gtk_widget_activate*(widget: PGtkWidget): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_widget_activate".}
proc gtk_widget_set_scroll_adjustments*(widget: PGtkWidget,
                                        hadjustment: PGtkAdjustment,
                                        vadjustment: PGtkAdjustment): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_set_scroll_adjustments".}
proc gtk_widget_reparent*(widget: PGtkWidget, new_parent: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_reparent".}
proc gtk_widget_intersect*(widget: PGtkWidget, area: PGdkRectangle,
                           intersection: PGdkRectangle): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_intersect".}
proc gtk_widget_region_intersect*(widget: PGtkWidget, region: PGdkRegion): PGdkRegion{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_region_intersect".}
proc gtk_widget_freeze_child_notify*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_freeze_child_notify".}
proc gtk_widget_child_notify*(widget: PGtkWidget, child_property: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_widget_child_notify".}
proc gtk_widget_thaw_child_notify*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_thaw_child_notify".}
proc gtk_widget_is_focus*(widget: PGtkWidget): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_widget_is_focus".}
proc gtk_widget_grab_focus*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_grab_focus".}
proc gtk_widget_grab_default*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_grab_default".}
proc gtk_widget_set_name*(widget: PGtkWidget, name: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_name".}
proc gtk_widget_get_name*(widget: PGtkWidget): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_widget_get_name".}
proc gtk_widget_set_state*(widget: PGtkWidget, state: TGtkStateType){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_state".}
proc gtk_widget_set_sensitive*(widget: PGtkWidget, sensitive: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_sensitive".}
proc gtk_widget_set_app_paintable*(widget: PGtkWidget, app_paintable: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_widget_set_app_paintable".}
proc gtk_widget_set_double_buffered*(widget: PGtkWidget,
                                     double_buffered: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_double_buffered".}
proc gtk_widget_set_redraw_on_allocate*(widget: PGtkWidget,
                                        redraw_on_allocate: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_redraw_on_allocate".}
proc gtk_widget_set_parent*(widget: PGtkWidget, parent: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_parent".}
proc gtk_widget_set_parent_window*(widget: PGtkWidget, parent_window: PGdkWindow){.
    cdecl, dynlib: gtklib, importc: "gtk_widget_set_parent_window".}
proc gtk_widget_set_child_visible*(widget: PGtkWidget, is_visible: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_widget_set_child_visible".}
proc gtk_widget_get_child_visible*(widget: PGtkWidget): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_child_visible".}
proc gtk_widget_get_parent*(widget: PGtkWidget): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_parent".}
proc gtk_widget_get_parent_window*(widget: PGtkWidget): PGdkWindow{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_parent_window".}
proc gtk_widget_child_focus*(widget: PGtkWidget, direction: TGtkDirectionType): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_child_focus".}
proc gtk_widget_set_size_request*(widget: PGtkWidget, width: gint, height: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_widget_set_size_request".}
proc gtk_widget_get_size_request*(widget: PGtkWidget, width: Pgint,
                                  height: Pgint){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_get_size_request".}
proc gtk_widget_set_events*(widget: PGtkWidget, events: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_events".}
proc gtk_widget_add_events*(widget: PGtkWidget, events: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_add_events".}
proc gtk_widget_set_extension_events*(widget: PGtkWidget,
                                      mode: TGdkExtensionMode){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_extension_events".}
proc gtk_widget_get_extension_events*(widget: PGtkWidget): TGdkExtensionMode{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_get_extension_events".}
proc gtk_widget_get_toplevel*(widget: PGtkWidget): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_toplevel".}
proc gtk_widget_get_ancestor*(widget: PGtkWidget, widget_type: TGtkType): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_get_ancestor".}
proc gtk_widget_get_colormap*(widget: PGtkWidget): PGdkColormap{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_colormap".}
proc gtk_widget_get_visual*(widget: PGtkWidget): PGdkVisual{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_visual".}
proc gtk_widget_get_screen*(widget: PGtkWidget): PGdkScreen{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_screen".}
proc gtk_widget_has_screen*(widget: PGtkWidget): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_has_screen".}
proc gtk_widget_get_display*(widget: PGtkWidget): PGdkDisplay{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_display".}
proc gtk_widget_get_root_window*(widget: PGtkWidget): PGdkWindow{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_root_window".}
proc gtk_widget_get_settings*(widget: PGtkWidget): PGtkSettings{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_settings".}
proc gtk_widget_get_clipboard*(widget: PGtkWidget, selection: TGdkAtom): PGtkClipboard{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_get_clipboard".}
proc gtk_widget_get_accessible*(widget: PGtkWidget): PAtkObject{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_accessible".}
proc gtk_widget_set_colormap*(widget: PGtkWidget, colormap: PGdkColormap){.
    cdecl, dynlib: gtklib, importc: "gtk_widget_set_colormap".}
proc gtk_widget_get_events*(widget: PGtkWidget): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_widget_get_events".}
proc gtk_widget_get_pointer*(widget: PGtkWidget, x: Pgint, y: Pgint){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_pointer".}
proc gtk_widget_is_ancestor*(widget: PGtkWidget, ancestor: PGtkWidget): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_is_ancestor".}
proc gtk_widget_translate_coordinates*(src_widget: PGtkWidget,
                                       dest_widget: PGtkWidget, src_x: gint,
                                       src_y: gint, dest_x: Pgint, dest_y: Pgint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_translate_coordinates".}
proc gtk_widget_hide_on_delete*(widget: PGtkWidget): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_hide_on_delete".}
proc gtk_widget_set_style*(widget: PGtkWidget, style: PGtkStyle){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_style".}
proc gtk_widget_ensure_style*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_ensure_style".}
proc gtk_widget_get_style*(widget: PGtkWidget): PGtkStyle{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_style".}
proc gtk_widget_modify_style*(widget: PGtkWidget, style: PGtkRcStyle){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_modify_style".}
proc gtk_widget_get_modifier_style*(widget: PGtkWidget): PGtkRcStyle{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_modifier_style".}
proc gtk_widget_modify_fg*(widget: PGtkWidget, state: TGtkStateType,
                           color: PGdkColor){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_modify_fg".}
proc gtk_widget_modify_bg*(widget: PGtkWidget, state: TGtkStateType,
                           color: PGdkColor){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_modify_bg".}
proc gtk_widget_modify_text*(widget: PGtkWidget, state: TGtkStateType,
                             color: PGdkColor){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_modify_text".}
proc gtk_widget_modify_base*(widget: PGtkWidget, state: TGtkStateType,
                             color: PGdkColor){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_modify_base".}
proc gtk_widget_modify_font*(widget: PGtkWidget,
                             font_desc: PPangoFontDescription){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_modify_font".}
proc gtk_widget_create_pango_context*(widget: PGtkWidget): PPangoContext{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_create_pango_context".}
proc gtk_widget_get_pango_context*(widget: PGtkWidget): PPangoContext{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_pango_context".}
proc gtk_widget_create_pango_layout*(widget: PGtkWidget, text: cstring): PPangoLayout{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_create_pango_layout".}
proc gtk_widget_render_icon*(widget: PGtkWidget, stock_id: cstring,
                             size: TGtkIconSize, detail: cstring): PGdkPixbuf{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_render_icon".}
proc gtk_widget_set_composite_name*(widget: PGtkWidget, name: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_composite_name".}
proc gtk_widget_get_composite_name*(widget: PGtkWidget): cstring{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_composite_name".}
proc gtk_widget_reset_rc_styles*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_reset_rc_styles".}
proc gtk_widget_push_colormap*(cmap: PGdkColormap){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_push_colormap".}
proc gtk_widget_push_composite_child*(){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_push_composite_child".}
proc gtk_widget_pop_composite_child*(){.cdecl, dynlib: gtklib, importc: "gtk_widget_pop_composite_child".}
proc gtk_widget_pop_colormap*(){.cdecl, dynlib: gtklib,
                                 importc: "gtk_widget_pop_colormap".}
proc gtk_widget_class_install_style_property*(klass: PGtkWidgetClass,
    pspec: PGParamSpec){.cdecl, dynlib: gtklib,
                         importc: "gtk_widget_class_install_style_property".}
proc gtk_widget_class_install_style_property_parser*(klass: PGtkWidgetClass,
    pspec: PGParamSpec, parser: TGtkRcPropertyParser){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_class_install_style_property_parser".}
proc gtk_widget_class_find_style_property*(klass: PGtkWidgetClass,
    property_name: cstring): PGParamSpec{.cdecl, dynlib: gtklib,
    importc: "gtk_widget_class_find_style_property".}
proc gtk_widget_class_list_style_properties*(klass: PGtkWidgetClass,
    n_properties: Pguint): PPGParamSpec{.cdecl, dynlib: gtklib,
    importc: "gtk_widget_class_list_style_properties".}
proc gtk_widget_style_get_property*(widget: PGtkWidget, property_name: cstring,
                                    value: PGValue){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_style_get_property".}
proc gtk_widget_set_default_colormap*(colormap: PGdkColormap){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_default_colormap".}
proc gtk_widget_get_default_style*(): PGtkStyle{.cdecl, dynlib: gtklib,
    importc: "gtk_widget_get_default_style".}
proc gtk_widget_set_direction*(widget: PGtkWidget, dir: TGtkTextDirection){.
    cdecl, dynlib: gtklib, importc: "gtk_widget_set_direction".}
proc gtk_widget_get_direction*(widget: PGtkWidget): TGtkTextDirection{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_direction".}
proc gtk_widget_set_default_direction*(dir: TGtkTextDirection){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_set_default_direction".}
proc gtk_widget_get_default_direction*(): TGtkTextDirection{.cdecl,
    dynlib: gtklib, importc: "gtk_widget_get_default_direction".}
proc gtk_widget_shape_combine_mask*(widget: PGtkWidget, shape_mask: PGdkBitmap,
                                    offset_x: gint, offset_y: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_shape_combine_mask".}
proc gtk_widget_reset_shapes*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_reset_shapes".}
proc gtk_widget_path*(widget: PGtkWidget, path_length: Pguint, path: PPgchar,
                      path_reversed: PPgchar){.cdecl, dynlib: gtklib,
    importc: "gtk_widget_path".}
proc gtk_widget_class_path*(widget: PGtkWidget, path_length: Pguint,
                            path: PPgchar, path_reversed: PPgchar){.cdecl,
    dynlib: gtklib, importc: "gtk_widget_class_path".}
proc gtk_requisition_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_requisition_get_type".}
proc gtk_requisition_copy*(requisition: PGtkRequisition): PGtkRequisition{.
    cdecl, dynlib: gtklib, importc: "gtk_requisition_copy".}
proc gtk_requisition_free*(requisition: PGtkRequisition){.cdecl, dynlib: gtklib,
    importc: "gtk_requisition_free".}
proc gtk_widget_get_aux_info*(widget: PGtkWidget, create: gboolean): PGtkWidgetAuxInfo{.
    cdecl, dynlib: gtklib, importc: "gtk_widget_get_aux_info".}
proc gtk_widget_propagate_hierarchy_changed*(widget: PGtkWidget,
    previous_toplevel: PGtkWidget){.cdecl, dynlib: gtklib, importc: "_gtk_widget_propagate_hierarchy_changed".}
proc gtk_widget_peek_colormap*(): PGdkColormap{.cdecl, dynlib: gtklib,
    importc: "_gtk_widget_peek_colormap".}
proc GTK_TYPE_MISC*(): GType
proc GTK_MISC*(obj: pointer): PGtkMisc
proc GTK_MISC_CLASS*(klass: pointer): PGtkMiscClass
proc GTK_IS_MISC*(obj: pointer): bool
proc GTK_IS_MISC_CLASS*(klass: pointer): bool
proc GTK_MISC_GET_CLASS*(obj: pointer): PGtkMiscClass
proc gtk_misc_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                     importc: "gtk_misc_get_type".}
proc gtk_misc_set_alignment*(misc: PGtkMisc, xalign: gfloat, yalign: gfloat){.
    cdecl, dynlib: gtklib, importc: "gtk_misc_set_alignment".}
proc gtk_misc_get_alignment*(misc: PGtkMisc, xalign, yalign: var Pgfloat){.
    cdecl, dynlib: gtklib, importc: "gtk_misc_get_alignment".}
proc gtk_misc_set_padding*(misc: PGtkMisc, xpad: gint, ypad: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_misc_set_padding".}
proc gtk_misc_get_padding*(misc: PGtkMisc, xpad, ypad: var Pgint){.cdecl,
    dynlib: gtklib, importc: "gtk_misc_get_padding".}
const
  GTK_ACCEL_VISIBLE* = 1 shl 0
  GTK_ACCEL_LOCKED* = 1 shl 1
  GTK_ACCEL_MASK* = 0x00000007
  bm_TGtkAccelKey_accel_flags* = 0x0000FFFF'i16
  bp_TGtkAccelKey_accel_flags* = 0'i16

proc GTK_TYPE_ACCEL_GROUP*(): GType
proc GTK_ACCEL_GROUP*(anObject: pointer): PGtkAccelGroup
proc GTK_ACCEL_GROUP_CLASS*(klass: pointer): PGtkAccelGroupClass
proc GTK_IS_ACCEL_GROUP*(anObject: pointer): bool
proc GTK_IS_ACCEL_GROUP_CLASS*(klass: pointer): bool
proc GTK_ACCEL_GROUP_GET_CLASS*(obj: pointer): PGtkAccelGroupClass
proc accel_flags*(a: var TGtkAccelKey): guint
proc set_accel_flags*(a: var TGtkAccelKey, `accel_flags`: guint)
proc gtk_accel_group_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_accel_group_get_type".}
proc gtk_accel_group_new*(): PGtkAccelGroup{.cdecl, dynlib: gtklib,
    importc: "gtk_accel_group_new".}
proc gtk_accel_group_lock*(accel_group: PGtkAccelGroup){.cdecl, dynlib: gtklib,
    importc: "gtk_accel_group_lock".}
proc gtk_accel_group_unlock*(accel_group: PGtkAccelGroup){.cdecl,
    dynlib: gtklib, importc: "gtk_accel_group_unlock".}
proc gtk_accel_group_connect*(accel_group: PGtkAccelGroup, accel_key: guint,
                              accel_mods: TGdkModifierType,
                              accel_flags: TGtkAccelFlags, closure: PGClosure){.
    cdecl, dynlib: gtklib, importc: "gtk_accel_group_connect".}
proc gtk_accel_group_connect_by_path*(accel_group: PGtkAccelGroup,
                                      accel_path: cstring, closure: PGClosure){.
    cdecl, dynlib: gtklib, importc: "gtk_accel_group_connect_by_path".}
proc gtk_accel_group_disconnect*(accel_group: PGtkAccelGroup, closure: PGClosure): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_accel_group_disconnect".}
proc gtk_accel_group_disconnect_key*(accel_group: PGtkAccelGroup,
                                     accel_key: guint,
                                     accel_mods: TGdkModifierType): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_accel_group_disconnect_key".}
proc gtk_accel_group_attach*(accel_group: PGtkAccelGroup, anObject: PGObject){.
    cdecl, dynlib: gtklib, importc: "_gtk_accel_group_attach".}
proc gtk_accel_group_detach*(accel_group: PGtkAccelGroup, anObject: PGObject){.
    cdecl, dynlib: gtklib, importc: "_gtk_accel_group_detach".}
proc gtk_accel_groups_activate*(anObject: PGObject, accel_key: guint,
                                accel_mods: TGdkModifierType): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_accel_groups_activate".}
proc gtk_accel_groups_from_object*(anObject: PGObject): PGSList{.cdecl,
    dynlib: gtklib, importc: "gtk_accel_groups_from_object".}
proc gtk_accel_group_find*(accel_group: PGtkAccelGroup,
                           find_func: Tgtk_accel_group_find_func, data: gpointer): PGtkAccelKey{.
    cdecl, dynlib: gtklib, importc: "gtk_accel_group_find".}
proc gtk_accel_group_from_accel_closure*(closure: PGClosure): PGtkAccelGroup{.
    cdecl, dynlib: gtklib, importc: "gtk_accel_group_from_accel_closure".}
proc gtk_accelerator_valid*(keyval: guint, modifiers: TGdkModifierType): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_accelerator_valid".}
proc gtk_accelerator_parse*(accelerator: cstring, accelerator_key: Pguint,
                            accelerator_mods: PGdkModifierType){.cdecl,
    dynlib: gtklib, importc: "gtk_accelerator_parse".}
proc gtk_accelerator_name*(accelerator_key: guint,
                           accelerator_mods: TGdkModifierType): cstring{.cdecl,
    dynlib: gtklib, importc: "gtk_accelerator_name".}
proc gtk_accelerator_set_default_mod_mask*(default_mod_mask: TGdkModifierType){.
    cdecl, dynlib: gtklib, importc: "gtk_accelerator_set_default_mod_mask".}
proc gtk_accelerator_get_default_mod_mask*(): guint{.cdecl, dynlib: gtklib,
    importc: "gtk_accelerator_get_default_mod_mask".}
proc gtk_accel_group_query*(accel_group: PGtkAccelGroup, accel_key: guint,
                            accel_mods: TGdkModifierType, n_entries: Pguint): PGtkAccelGroupEntry{.
    cdecl, dynlib: gtklib, importc: "gtk_accel_group_query".}
proc gtk_accel_group_reconnect*(accel_group: PGtkAccelGroup,
                                accel_path_quark: TGQuark){.cdecl,
    dynlib: gtklib, importc: "_gtk_accel_group_reconnect".}
const
  bm_TGtkContainer_border_width* = 0x0000FFFF'i32
  bp_TGtkContainer_border_width* = 0'i32
  bm_TGtkContainer_need_resize* = 0x00010000'i32
  bp_TGtkContainer_need_resize* = 16'i32
  bm_TGtkContainer_resize_mode* = 0x00060000'i32
  bp_TGtkContainer_resize_mode* = 17'i32
  bm_TGtkContainer_reallocate_redraws* = 0x00080000'i32
  bp_TGtkContainer_reallocate_redraws* = 19'i32
  bm_TGtkContainer_has_focus_chain* = 0x00100000'i32
  bp_TGtkContainer_has_focus_chain* = 20'i32

proc GTK_TYPE_CONTAINER*(): GType
proc GTK_CONTAINER*(obj: pointer): PGtkContainer
proc GTK_CONTAINER_CLASS*(klass: pointer): PGtkContainerClass
proc GTK_IS_CONTAINER*(obj: pointer): bool
proc GTK_IS_CONTAINER_CLASS*(klass: pointer): bool
proc GTK_CONTAINER_GET_CLASS*(obj: pointer): PGtkContainerClass
proc GTK_IS_RESIZE_CONTAINER*(widget: pointer): bool
proc border_width*(a: var TGtkContainer): guint
proc set_border_width*(a: var TGtkContainer, `border_width`: guint)
proc need_resize*(a: var TGtkContainer): guint
proc set_need_resize*(a: var TGtkContainer, `need_resize`: guint)
proc resize_mode*(a: PGtkContainer): guint
proc set_resize_mode*(a: var TGtkContainer, `resize_mode`: guint)
proc reallocate_redraws*(a: var TGtkContainer): guint
proc set_reallocate_redraws*(a: var TGtkContainer, `reallocate_redraws`: guint)
proc has_focus_chain*(a: var TGtkContainer): guint
proc set_has_focus_chain*(a: var TGtkContainer, `has_focus_chain`: guint)
proc gtk_container_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_container_get_type".}
proc gtk_container_set_border_width*(container: PGtkContainer,
                                     border_width: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_container_set_border_width".}
proc gtk_container_get_border_width*(container: PGtkContainer): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_container_get_border_width".}
proc gtk_container_add*(container: PGtkContainer, widget: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_container_add".}
proc gtk_container_remove*(container: PGtkContainer, widget: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_container_remove".}
proc gtk_container_set_resize_mode*(container: PGtkContainer,
                                    resize_mode: TGtkResizeMode){.cdecl,
    dynlib: gtklib, importc: "gtk_container_set_resize_mode".}
proc gtk_container_get_resize_mode*(container: PGtkContainer): TGtkResizeMode{.
    cdecl, dynlib: gtklib, importc: "gtk_container_get_resize_mode".}
proc gtk_container_check_resize*(container: PGtkContainer){.cdecl,
    dynlib: gtklib, importc: "gtk_container_check_resize".}
proc gtk_container_foreach*(container: PGtkContainer, callback: TGtkCallback,
                            callback_data: gpointer){.cdecl, dynlib: gtklib,
    importc: "gtk_container_foreach".}
proc gtk_container_get_children*(container: PGtkContainer): PGList{.cdecl,
    dynlib: gtklib, importc: "gtk_container_get_children".}
proc gtk_container_propagate_expose*(container: PGtkContainer,
                                     child: PGtkWidget, event: PGdkEventExpose){.
    cdecl, dynlib: gtklib, importc: "gtk_container_propagate_expose".}
proc gtk_container_set_focus_chain*(container: PGtkContainer,
                                    focusable_widgets: PGList){.cdecl,
    dynlib: gtklib, importc: "gtk_container_set_focus_chain".}
proc gtk_container_get_focus_chain*(container: PGtkContainer, s: var PGList): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_container_get_focus_chain".}
proc gtk_container_unset_focus_chain*(container: PGtkContainer){.cdecl,
    dynlib: gtklib, importc: "gtk_container_unset_focus_chain".}
proc gtk_container_set_reallocate_redraws*(container: PGtkContainer,
    needs_redraws: gboolean){.cdecl, dynlib: gtklib,
                              importc: "gtk_container_set_reallocate_redraws".}
proc gtk_container_set_focus_child*(container: PGtkContainer, child: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "gtk_container_set_focus_child".}
proc gtk_container_set_focus_vadjustment*(container: PGtkContainer,
    adjustment: PGtkAdjustment){.cdecl, dynlib: gtklib,
                                 importc: "gtk_container_set_focus_vadjustment".}
proc gtk_container_get_focus_vadjustment*(container: PGtkContainer): PGtkAdjustment{.
    cdecl, dynlib: gtklib, importc: "gtk_container_get_focus_vadjustment".}
proc gtk_container_set_focus_hadjustment*(container: PGtkContainer,
    adjustment: PGtkAdjustment){.cdecl, dynlib: gtklib,
                                 importc: "gtk_container_set_focus_hadjustment".}
proc gtk_container_get_focus_hadjustment*(container: PGtkContainer): PGtkAdjustment{.
    cdecl, dynlib: gtklib, importc: "gtk_container_get_focus_hadjustment".}
proc gtk_container_resize_children*(container: PGtkContainer){.cdecl,
    dynlib: gtklib, importc: "gtk_container_resize_children".}
proc gtk_container_child_type*(container: PGtkContainer): TGtkType{.cdecl,
    dynlib: gtklib, importc: "gtk_container_child_type".}
proc gtk_container_class_install_child_property*(cclass: PGtkContainerClass,
    property_id: guint, pspec: PGParamSpec){.cdecl, dynlib: gtklib,
    importc: "gtk_container_class_install_child_property".}
proc gtk_container_class_find_child_property*(cclass: PGObjectClass,
    property_name: cstring): PGParamSpec{.cdecl, dynlib: gtklib,
    importc: "gtk_container_class_find_child_property".}
proc gtk_container_class_list_child_properties*(cclass: PGObjectClass,
    n_properties: Pguint): PPGParamSpec{.cdecl, dynlib: gtklib,
    importc: "gtk_container_class_list_child_properties".}
proc gtk_container_child_set_property*(container: PGtkContainer,
                                       child: PGtkWidget, property_name: cstring,
                                       value: PGValue){.cdecl, dynlib: gtklib,
    importc: "gtk_container_child_set_property".}
proc gtk_container_child_get_property*(container: PGtkContainer,
                                       child: PGtkWidget, property_name: cstring,
                                       value: PGValue){.cdecl, dynlib: gtklib,
    importc: "gtk_container_child_get_property".}
proc GTK_CONTAINER_WARN_INVALID_CHILD_PROPERTY_ID*(anObject: pointer,
    property_id: guint, pspec: pointer)
proc gtk_container_forall*(container: PGtkContainer, callback: TGtkCallback,
                           callback_data: gpointer){.cdecl, dynlib: gtklib,
    importc: "gtk_container_forall".}
proc gtk_container_queue_resize*(container: PGtkContainer){.cdecl,
    dynlib: gtklib, importc: "_gtk_container_queue_resize".}
proc gtk_container_clear_resize_widgets*(container: PGtkContainer){.cdecl,
    dynlib: gtklib, importc: "_gtk_container_clear_resize_widgets".}
proc gtk_container_child_composite_name*(container: PGtkContainer,
    child: PGtkWidget): cstring{.cdecl, dynlib: gtklib,
                                importc: "_gtk_container_child_composite_name".}
proc gtk_container_dequeue_resize_handler*(container: PGtkContainer){.cdecl,
    dynlib: gtklib, importc: "_gtk_container_dequeue_resize_handler".}
proc gtk_container_focus_sort*(container: PGtkContainer, children: PGList,
                                 direction: TGtkDirectionType,
                                 old_focus: PGtkWidget): PGList{.cdecl,
    dynlib: gtklib, importc: "_gtk_container_focus_sort".}
proc GTK_TYPE_BIN*(): GType
proc GTK_BIN*(obj: pointer): PGtkBin
proc GTK_BIN_CLASS*(klass: pointer): PGtkBinClass
proc GTK_IS_BIN*(obj: pointer): bool
proc GTK_IS_BIN_CLASS*(klass: pointer): bool
proc GTK_BIN_GET_CLASS*(obj: pointer): PGtkBinClass
proc gtk_bin_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                    importc: "gtk_bin_get_type".}
proc gtk_bin_get_child*(bin: PGtkBin): PGtkWidget{.cdecl, dynlib: gtklib,
    importc: "gtk_bin_get_child".}
const
  bm_TGtkWindow_allow_shrink* = 0x00000001'i32
  bp_TGtkWindow_allow_shrink* = 0'i32
  bm_TGtkWindow_allow_grow* = 0x00000002'i32
  bp_TGtkWindow_allow_grow* = 1'i32
  bm_TGtkWindow_configure_notify_received* = 0x00000004'i32
  bp_TGtkWindow_configure_notify_received* = 2'i32
  bm_TGtkWindow_need_default_position* = 0x00000008'i32
  bp_TGtkWindow_need_default_position* = 3'i32
  bm_TGtkWindow_need_default_size* = 0x00000010'i32
  bp_TGtkWindow_need_default_size* = 4'i32
  bm_TGtkWindow_position* = 0x000000E0'i32
  bp_TGtkWindow_position* = 5'i32
  bm_TGtkWindow_type* = 0x00000F00'i32
  bp_TGtkWindow_type* = 8'i32
  bm_TGtkWindow_has_user_ref_count* = 0x00001000'i32
  bp_TGtkWindow_has_user_ref_count* = 12'i32
  bm_TGtkWindow_has_focus* = 0x00002000'i32
  bp_TGtkWindow_has_focus* = 13'i32
  bm_TGtkWindow_modal* = 0x00004000'i32
  bp_TGtkWindow_modal* = 14'i32
  bm_TGtkWindow_destroy_with_parent* = 0x00008000'i32
  bp_TGtkWindow_destroy_with_parent* = 15'i32
  bm_TGtkWindow_has_frame* = 0x00010000'i32
  bp_TGtkWindow_has_frame* = 16'i32
  bm_TGtkWindow_iconify_initially* = 0x00020000'i32
  bp_TGtkWindow_iconify_initially* = 17'i32
  bm_TGtkWindow_stick_initially* = 0x00040000'i32
  bp_TGtkWindow_stick_initially* = 18'i32
  bm_TGtkWindow_maximize_initially* = 0x00080000'i32
  bp_TGtkWindow_maximize_initially* = 19'i32
  bm_TGtkWindow_decorated* = 0x00100000'i32
  bp_TGtkWindow_decorated* = 20'i32
  bm_TGtkWindow_type_hint* = 0x00E00000'i32
  bp_TGtkWindow_type_hint* = 21'i32
  bm_TGtkWindow_gravity* = 0x1F000000'i32
  bp_TGtkWindow_gravity* = 24'i32

proc GTK_TYPE_WINDOW*(): GType
proc GTK_WINDOW*(obj: pointer): PGtkWindow
proc GTK_WINDOW_CLASS*(klass: pointer): PGtkWindowClass
proc GTK_IS_WINDOW*(obj: pointer): bool
proc GTK_IS_WINDOW_CLASS*(klass: pointer): bool
proc GTK_WINDOW_GET_CLASS*(obj: pointer): PGtkWindowClass
proc allow_shrink*(a: var TGtkWindow): guint
proc set_allow_shrink*(a: var TGtkWindow, `allow_shrink`: guint)
proc allow_grow*(a: var TGtkWindow): guint
proc set_allow_grow*(a: var TGtkWindow, `allow_grow`: guint)
proc configure_notify_received*(a: var TGtkWindow): guint
proc set_configure_notify_received*(a: var TGtkWindow,
                                    `configure_notify_received`: guint)
proc need_default_position*(a: var TGtkWindow): guint
proc set_need_default_position*(a: var TGtkWindow,
                                `need_default_position`: guint)
proc need_default_size*(a: var TGtkWindow): guint
proc set_need_default_size*(a: var TGtkWindow, `need_default_size`: guint)
proc position*(a: var TGtkWindow): guint
proc set_position*(a: var TGtkWindow, `position`: guint)
proc get_type*(a: var TGtkWindow): guint
proc set_type*(a: var TGtkWindow, `type`: guint)
proc has_user_ref_count*(a: var TGtkWindow): guint
proc set_has_user_ref_count*(a: var TGtkWindow, `has_user_ref_count`: guint)
proc has_focus*(a: var TGtkWindow): guint
proc set_has_focus*(a: var TGtkWindow, `has_focus`: guint)
proc modal*(a: var TGtkWindow): guint
proc set_modal*(a: var TGtkWindow, `modal`: guint)
proc destroy_with_parent*(a: var TGtkWindow): guint
proc set_destroy_with_parent*(a: var TGtkWindow, `destroy_with_parent`: guint)
proc has_frame*(a: var TGtkWindow): guint
proc set_has_frame*(a: var TGtkWindow, `has_frame`: guint)
proc iconify_initially*(a: var TGtkWindow): guint
proc set_iconify_initially*(a: var TGtkWindow, `iconify_initially`: guint)
proc stick_initially*(a: var TGtkWindow): guint
proc set_stick_initially*(a: var TGtkWindow, `stick_initially`: guint)
proc maximize_initially*(a: var TGtkWindow): guint
proc set_maximize_initially*(a: var TGtkWindow, `maximize_initially`: guint)
proc decorated*(a: var TGtkWindow): guint
proc set_decorated*(a: var TGtkWindow, `decorated`: guint)
proc type_hint*(a: var TGtkWindow): guint
proc set_type_hint*(a: var TGtkWindow, `type_hint`: guint)
proc gravity*(a: var TGtkWindow): guint
proc set_gravity*(a: var TGtkWindow, `gravity`: guint)
proc GTK_TYPE_WINDOW_GROUP*(): GType
proc GTK_WINDOW_GROUP*(anObject: pointer): PGtkWindowGroup
proc GTK_WINDOW_GROUP_CLASS*(klass: pointer): PGtkWindowGroupClass
proc GTK_IS_WINDOW_GROUP*(anObject: pointer): bool
proc GTK_IS_WINDOW_GROUP_CLASS*(klass: pointer): bool
proc GTK_WINDOW_GROUP_GET_CLASS*(obj: pointer): PGtkWindowGroupClass
proc gtk_window_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_window_get_type".}
proc gtk_window_new*(thetype: TGtkWindowType): PGtkWindow {.cdecl,
    dynlib: gtklib, importc: "gtk_window_new".}
proc gtk_window_set_title*(window: PGtkWindow, title: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_title".}
proc gtk_window_get_title*(window: PGtkWindow): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_window_get_title".}
proc gtk_window_set_wmclass*(window: PGtkWindow, wmclass_name: cstring,
                             wmclass_class: cstring){.cdecl, dynlib: gtklib,
    importc: "gtk_window_set_wmclass".}
proc gtk_window_set_role*(window: PGtkWindow, role: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_role".}
proc gtk_window_get_role*(window: PGtkWindow): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_window_get_role".}
proc gtk_window_add_accel_group*(window: PGtkWindow, accel_group: PGtkAccelGroup){.
    cdecl, dynlib: gtklib, importc: "gtk_window_add_accel_group".}
proc gtk_window_remove_accel_group*(window: PGtkWindow,
                                    accel_group: PGtkAccelGroup){.cdecl,
    dynlib: gtklib, importc: "gtk_window_remove_accel_group".}
proc gtk_window_set_position*(window: PGtkWindow, position: TGtkWindowPosition){.
    cdecl, dynlib: gtklib, importc: "gtk_window_set_position".}
proc gtk_window_activate_focus*(window: PGtkWindow): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_window_activate_focus".}
proc gtk_window_set_focus*(window: PGtkWindow, focus: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_focus".}
proc gtk_window_get_focus*(window: PGtkWindow): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_window_get_focus".}
proc gtk_window_set_default*(window: PGtkWindow, default_widget: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "gtk_window_set_default".}
proc gtk_window_activate_default*(window: PGtkWindow): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_window_activate_default".}
proc gtk_window_set_transient_for*(window: PGtkWindow, parent: PGtkWindow){.
    cdecl, dynlib: gtklib, importc: "gtk_window_set_transient_for".}
proc gtk_window_get_transient_for*(window: PGtkWindow): PGtkWindow{.cdecl,
    dynlib: gtklib, importc: "gtk_window_get_transient_for".}
proc gtk_window_set_type_hint*(window: PGtkWindow, hint: TGdkWindowTypeHint){.
    cdecl, dynlib: gtklib, importc: "gtk_window_set_type_hint".}
proc gtk_window_get_type_hint*(window: PGtkWindow): TGdkWindowTypeHint{.cdecl,
    dynlib: gtklib, importc: "gtk_window_get_type_hint".}
proc gtk_window_set_destroy_with_parent*(window: PGtkWindow, setting: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_window_set_destroy_with_parent".}
proc gtk_window_get_destroy_with_parent*(window: PGtkWindow): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_window_get_destroy_with_parent".}
proc gtk_window_set_resizable*(window: PGtkWindow, resizable: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_resizable".}
proc gtk_window_get_resizable*(window: PGtkWindow): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_window_get_resizable".}
proc gtk_window_set_gravity*(window: PGtkWindow, gravity: TGdkGravity){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_gravity".}
proc gtk_window_get_gravity*(window: PGtkWindow): TGdkGravity{.cdecl,
    dynlib: gtklib, importc: "gtk_window_get_gravity".}
proc gtk_window_set_geometry_hints*(window: PGtkWindow,
                                    geometry_widget: PGtkWidget,
                                    geometry: PGdkGeometry,
                                    geom_mask: TGdkWindowHints){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_geometry_hints".}
proc gtk_window_set_screen*(window: PGtkWindow, screen: PGdkScreen){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_screen".}
proc gtk_window_get_screen*(window: PGtkWindow): PGdkScreen{.cdecl,
    dynlib: gtklib, importc: "gtk_window_get_screen".}
proc gtk_window_set_has_frame*(window: PGtkWindow, setting: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_has_frame".}
proc gtk_window_get_has_frame*(window: PGtkWindow): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_window_get_has_frame".}
proc gtk_window_set_frame_dimensions*(window: PGtkWindow, left: gint, top: gint,
                                      right: gint, bottom: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_frame_dimensions".}
proc gtk_window_get_frame_dimensions*(window: PGtkWindow, left: Pgint,
                                      top: Pgint, right: Pgint, bottom: Pgint){.
    cdecl, dynlib: gtklib, importc: "gtk_window_get_frame_dimensions".}
proc gtk_window_set_decorated*(window: PGtkWindow, setting: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_decorated".}
proc gtk_window_get_decorated*(window: PGtkWindow): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_window_get_decorated".}
proc gtk_window_set_icon_list*(window: PGtkWindow, list: PGList){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_icon_list".}
proc gtk_window_get_icon_list*(window: PGtkWindow): PGList{.cdecl,
    dynlib: gtklib, importc: "gtk_window_get_icon_list".}
proc gtk_window_set_icon*(window: PGtkWindow, icon: PGdkPixbuf){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_icon".}
proc gtk_window_get_icon*(window: PGtkWindow): PGdkPixbuf{.cdecl,
    dynlib: gtklib, importc: "gtk_window_get_icon".}
proc gtk_window_set_default_icon_list*(list: PGList){.cdecl, dynlib: gtklib,
    importc: "gtk_window_set_default_icon_list".}
proc gtk_window_get_default_icon_list*(): PGList{.cdecl, dynlib: gtklib,
    importc: "gtk_window_get_default_icon_list".}
proc gtk_window_set_modal*(window: PGtkWindow, modal: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_modal".}
proc gtk_window_get_modal*(window: PGtkWindow): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_window_get_modal".}
proc gtk_window_list_toplevels*(): PGList{.cdecl, dynlib: gtklib,
    importc: "gtk_window_list_toplevels".}
proc gtk_window_add_mnemonic*(window: PGtkWindow, keyval: guint,
                              target: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_window_add_mnemonic".}
proc gtk_window_remove_mnemonic*(window: PGtkWindow, keyval: guint,
                                 target: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_window_remove_mnemonic".}
proc gtk_window_mnemonic_activate*(window: PGtkWindow, keyval: guint,
                                   modifier: TGdkModifierType): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_window_mnemonic_activate".}
proc gtk_window_set_mnemonic_modifier*(window: PGtkWindow,
                                       modifier: TGdkModifierType){.cdecl,
    dynlib: gtklib, importc: "gtk_window_set_mnemonic_modifier".}
proc gtk_window_get_mnemonic_modifier*(window: PGtkWindow): TGdkModifierType{.
    cdecl, dynlib: gtklib, importc: "gtk_window_get_mnemonic_modifier".}
proc gtk_window_present*(window: PGtkWindow){.cdecl, dynlib: gtklib,
    importc: "gtk_window_present".}
proc gtk_window_iconify*(window: PGtkWindow){.cdecl, dynlib: gtklib,
    importc: "gtk_window_iconify".}
proc gtk_window_deiconify*(window: PGtkWindow){.cdecl, dynlib: gtklib,
    importc: "gtk_window_deiconify".}
proc gtk_window_stick*(window: PGtkWindow){.cdecl, dynlib: gtklib,
    importc: "gtk_window_stick".}
proc gtk_window_unstick*(window: PGtkWindow){.cdecl, dynlib: gtklib,
    importc: "gtk_window_unstick".}
proc gtk_window_maximize*(window: PGtkWindow){.cdecl, dynlib: gtklib,
    importc: "gtk_window_maximize".}
proc gtk_window_unmaximize*(window: PGtkWindow){.cdecl, dynlib: gtklib,
    importc: "gtk_window_unmaximize".}
proc gtk_window_begin_resize_drag*(window: PGtkWindow, edge: TGdkWindowEdge,
                                   button: gint, root_x: gint, root_y: gint,
                                   timestamp: guint32){.cdecl, dynlib: gtklib,
    importc: "gtk_window_begin_resize_drag".}
proc gtk_window_begin_move_drag*(window: PGtkWindow, button: gint, root_x: gint,
                                 root_y: gint, timestamp: guint32){.cdecl,
    dynlib: gtklib, importc: "gtk_window_begin_move_drag".}
proc gtk_window_set_default_size*(window: PGtkWindow, width: gint, height: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_window_set_default_size".}
proc gtk_window_get_default_size*(window: PGtkWindow, width: Pgint,
                                  height: Pgint){.cdecl, dynlib: gtklib,
    importc: "gtk_window_get_default_size".}
proc gtk_window_resize*(window: PGtkWindow, width: gint, height: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_window_resize".}
proc gtk_window_get_size*(window: PGtkWindow, width: Pgint, height: Pgint){.
    cdecl, dynlib: gtklib, importc: "gtk_window_get_size".}
proc gtk_window_move*(window: PGtkWindow, x: gint, y: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_window_move".}
proc gtk_window_get_position*(window: PGtkWindow, root_x: Pgint, root_y: Pgint){.
    cdecl, dynlib: gtklib, importc: "gtk_window_get_position".}
proc gtk_window_parse_geometry*(window: PGtkWindow, geometry: cstring): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_window_parse_geometry".}
proc gtk_window_reshow_with_initial_size*(window: PGtkWindow){.cdecl,
    dynlib: gtklib, importc: "gtk_window_reshow_with_initial_size".}
proc gtk_window_group_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_window_group_get_type".}
proc gtk_window_group_new*(): PGtkWindowGroup{.cdecl, dynlib: gtklib,
    importc: "gtk_window_group_new".}
proc gtk_window_group_add_window*(window_group: PGtkWindowGroup,
                                  window: PGtkWindow){.cdecl, dynlib: gtklib,
    importc: "gtk_window_group_add_window".}
proc gtk_window_group_remove_window*(window_group: PGtkWindowGroup,
                                     window: PGtkWindow){.cdecl, dynlib: gtklib,
    importc: "gtk_window_group_remove_window".}
proc gtk_window_set_default_icon_name*(name: cstring) {.
    cdecl, dynlib: gtklib, importc.}
proc gtk_window_internal_set_focus*(window: PGtkWindow, focus: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "_gtk_window_internal_set_focus".}
proc gtk_window_remove_embedded_xid*(window: PGtkWindow, xid: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_window_remove_embedded_xid".}
proc gtk_window_add_embedded_xid*(window: PGtkWindow, xid: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_window_add_embedded_xid".}
proc gtk_window_reposition*(window: PGtkWindow, x: gint, y: gint){.cdecl,
    dynlib: gtklib, importc: "_gtk_window_reposition".}
proc gtk_window_constrain_size*(window: PGtkWindow, width: gint, height: gint,
                                  new_width: Pgint, new_height: Pgint){.cdecl,
    dynlib: gtklib, importc: "_gtk_window_constrain_size".}
proc gtk_window_get_group*(window: PGtkWindow): PGtkWindowGroup{.cdecl,
    dynlib: gtklib, importc: "_gtk_window_get_group".}
proc gtk_window_activate_key*(window: PGtkWindow, event: PGdkEventKey): gboolean{.
    cdecl, dynlib: gtklib, importc: "_gtk_window_activate_key".}
proc gtk_window_keys_foreach*(window: PGtkWindow,
                                func: TGtkWindowKeysForeachFunc,
                                func_data: gpointer){.cdecl, dynlib: gtklib,
    importc: "_gtk_window_keys_foreach".}
proc gtk_window_query_nonaccels*(window: PGtkWindow, accel_key: guint,
                                   accel_mods: TGdkModifierType): gboolean{.
    cdecl, dynlib: gtklib, importc: "_gtk_window_query_nonaccels".}
const
  bm_TGtkLabel_jtype* = 0x00000003'i16
  bp_TGtkLabel_jtype* = 0'i16
  bm_TGtkLabel_wrap* = 0x00000004'i16
  bp_TGtkLabel_wrap* = 2'i16
  bm_TGtkLabel_use_underline* = 0x00000008'i16
  bp_TGtkLabel_use_underline* = 3'i16
  bm_TGtkLabel_use_markup* = 0x00000010'i16
  bp_TGtkLabel_use_markup* = 4'i16

proc GTK_TYPE_LABEL*(): GType
proc GTK_LABEL*(obj: pointer): PGtkLabel
proc GTK_LABEL_CLASS*(klass: pointer): PGtkLabelClass
proc GTK_IS_LABEL*(obj: pointer): bool
proc GTK_IS_LABEL_CLASS*(klass: pointer): bool
proc GTK_LABEL_GET_CLASS*(obj: pointer): PGtkLabelClass
proc jtype*(a: var TGtkLabel): guint
proc set_jtype*(a: var TGtkLabel, `jtype`: guint)
proc wrap*(a: var TGtkLabel): guint
proc set_wrap*(a: var TGtkLabel, `wrap`: guint)
proc use_underline*(a: var TGtkLabel): guint
proc set_use_underline*(a: var TGtkLabel, `use_underline`: guint)
proc use_markup*(a: var TGtkLabel): guint
proc set_use_markup*(a: var TGtkLabel, `use_markup`: guint)
proc gtk_label_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_label_get_type".}
proc gtk_label_new*(str: cstring): PGtkLabel {.cdecl, dynlib: gtklib,
    importc: "gtk_label_new".}
proc gtk_label_new_with_mnemonic*(str: cstring): PGtkLabel {.cdecl,
    dynlib: gtklib, importc: "gtk_label_new_with_mnemonic".}
proc gtk_label_set_text*(`label`: PGtkLabel, str: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_label_set_text".}
proc gtk_label_get_text*(`label`: PGtkLabel): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_label_get_text".}
proc gtk_label_set_attributes*(`label`: PGtkLabel, attrs: PPangoAttrList){.
    cdecl, dynlib: gtklib, importc: "gtk_label_set_attributes".}
proc gtk_label_get_attributes*(`label`: PGtkLabel): PPangoAttrList{.cdecl,
    dynlib: gtklib, importc: "gtk_label_get_attributes".}
proc gtk_label_set_label*(`label`: PGtkLabel, str: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_label_set_label".}
proc gtk_label_get_label*(`label`: PGtkLabel): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_label_get_label".}
proc gtk_label_set_markup*(`label`: PGtkLabel, str: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_label_set_markup".}
proc gtk_label_set_use_markup*(`label`: PGtkLabel, setting: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_label_set_use_markup".}
proc gtk_label_get_use_markup*(`label`: PGtkLabel): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_label_get_use_markup".}
proc gtk_label_set_use_underline*(`label`: PGtkLabel, setting: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_label_set_use_underline".}
proc gtk_label_get_use_underline*(`label`: PGtkLabel): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_label_get_use_underline".}
proc gtk_label_set_markup_with_mnemonic*(`label`: PGtkLabel, str: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_label_set_markup_with_mnemonic".}
proc gtk_label_get_mnemonic_keyval*(`label`: PGtkLabel): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_label_get_mnemonic_keyval".}
proc gtk_label_set_mnemonic_widget*(`label`: PGtkLabel, widget: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "gtk_label_set_mnemonic_widget".}
proc gtk_label_get_mnemonic_widget*(`label`: PGtkLabel): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_label_get_mnemonic_widget".}
proc gtk_label_set_text_with_mnemonic*(`label`: PGtkLabel, str: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_label_set_text_with_mnemonic".}
proc gtk_label_set_justify*(`label`: PGtkLabel, jtype: TGtkJustification){.
    cdecl, dynlib: gtklib, importc: "gtk_label_set_justify".}
proc gtk_label_get_justify*(`label`: PGtkLabel): TGtkJustification{.cdecl,
    dynlib: gtklib, importc: "gtk_label_get_justify".}
proc gtk_label_set_pattern*(`label`: PGtkLabel, pattern: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_label_set_pattern".}
proc gtk_label_set_line_wrap*(`label`: PGtkLabel, wrap: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_label_set_line_wrap".}
proc gtk_label_get_line_wrap*(`label`: PGtkLabel): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_label_get_line_wrap".}
proc gtk_label_set_selectable*(`label`: PGtkLabel, setting: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_label_set_selectable".}
proc gtk_label_get_selectable*(`label`: PGtkLabel): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_label_get_selectable".}
proc gtk_label_select_region*(`label`: PGtkLabel, start_offset: gint,
                              end_offset: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_label_select_region".}
proc gtk_label_get_selection_bounds*(`label`: PGtkLabel, start: Pgint,
                                     theEnd: Pgint): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_label_get_selection_bounds".}
proc gtk_label_get_layout*(`label`: PGtkLabel): PPangoLayout{.cdecl,
    dynlib: gtklib, importc: "gtk_label_get_layout".}
proc gtk_label_get_layout_offsets*(`label`: PGtkLabel, x: Pgint, y: Pgint){.
    cdecl, dynlib: gtklib, importc: "gtk_label_get_layout_offsets".}
const
  bm_TGtkAccelLabelClass_latin1_to_char* = 0x00000001'i16
  bp_TGtkAccelLabelClass_latin1_to_char* = 0'i16

proc GTK_TYPE_ACCEL_LABEL*(): GType
proc GTK_ACCEL_LABEL*(obj: pointer): PGtkAccelLabel
proc GTK_ACCEL_LABEL_CLASS*(klass: pointer): PGtkAccelLabelClass
proc GTK_IS_ACCEL_LABEL*(obj: pointer): bool
proc GTK_IS_ACCEL_LABEL_CLASS*(klass: pointer): bool
proc GTK_ACCEL_LABEL_GET_CLASS*(obj: pointer): PGtkAccelLabelClass
proc latin1_to_char*(a: var TGtkAccelLabelClass): guint
proc set_latin1_to_char*(a: var TGtkAccelLabelClass, `latin1_to_char`: guint)
proc gtk_accel_label_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_accel_label_get_type".}
proc gtk_accel_label_new*(`string`: cstring): PGtkAccelLabel {.cdecl, dynlib: gtklib,
    importc: "gtk_accel_label_new".}
proc gtk_accel_label_get_accel_widget*(accel_label: PGtkAccelLabel): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_accel_label_get_accel_widget".}
proc gtk_accel_label_get_accel_width*(accel_label: PGtkAccelLabel): guint{.
    cdecl, dynlib: gtklib, importc: "gtk_accel_label_get_accel_width".}
proc gtk_accel_label_set_accel_widget*(accel_label: PGtkAccelLabel,
                                       accel_widget: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_accel_label_set_accel_widget".}
proc gtk_accel_label_set_accel_closure*(accel_label: PGtkAccelLabel,
                                        accel_closure: PGClosure){.cdecl,
    dynlib: gtklib, importc: "gtk_accel_label_set_accel_closure".}
proc gtk_accel_label_refetch*(accel_label: PGtkAccelLabel): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_accel_label_refetch".}
proc gtk_accel_map_add_entry*(accel_path: cstring, accel_key: guint,
                              accel_mods: TGdkModifierType){.cdecl,
    dynlib: gtklib, importc: "gtk_accel_map_add_entry".}
proc gtk_accel_map_lookup_entry*(accel_path: cstring, key: PGtkAccelKey): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_accel_map_lookup_entry".}
proc gtk_accel_map_change_entry*(accel_path: cstring, accel_key: guint,
                                 accel_mods: TGdkModifierType, replace: gboolean): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_accel_map_change_entry".}
proc gtk_accel_map_load*(file_name: cstring){.cdecl, dynlib: gtklib,
    importc: "gtk_accel_map_load".}
proc gtk_accel_map_save*(file_name: cstring){.cdecl, dynlib: gtklib,
    importc: "gtk_accel_map_save".}
proc gtk_accel_map_foreach*(data: gpointer, foreach_func: TGtkAccelMapForeach){.
    cdecl, dynlib: gtklib, importc: "gtk_accel_map_foreach".}
proc gtk_accel_map_load_fd*(fd: gint){.cdecl, dynlib: gtklib,
                                       importc: "gtk_accel_map_load_fd".}
proc gtk_accel_map_load_scanner*(scanner: PGScanner){.cdecl, dynlib: gtklib,
    importc: "gtk_accel_map_load_scanner".}
proc gtk_accel_map_save_fd*(fd: gint){.cdecl, dynlib: gtklib,
                                       importc: "gtk_accel_map_save_fd".}
proc gtk_accel_map_add_filter*(filter_pattern: cstring){.cdecl, dynlib: gtklib,
    importc: "gtk_accel_map_add_filter".}
proc gtk_accel_map_foreach_unfiltered*(data: gpointer,
                                       foreach_func: TGtkAccelMapForeach){.
    cdecl, dynlib: gtklib, importc: "gtk_accel_map_foreach_unfiltered".}
proc gtk_accel_map_init*(){.cdecl, dynlib: gtklib,
                              importc: "_gtk_accel_map_init".}
proc gtk_accel_map_add_group*(accel_path: cstring, accel_group: PGtkAccelGroup){.
    cdecl, dynlib: gtklib, importc: "_gtk_accel_map_add_group".}
proc gtk_accel_map_remove_group*(accel_path: cstring,
                                   accel_group: PGtkAccelGroup){.cdecl,
    dynlib: gtklib, importc: "_gtk_accel_map_remove_group".}
proc gtk_accel_path_is_valid*(accel_path: cstring): gboolean{.cdecl,
    dynlib: gtklib, importc: "_gtk_accel_path_is_valid".}
proc GTK_TYPE_ACCESSIBLE*(): GType
proc GTK_ACCESSIBLE*(obj: pointer): PGtkAccessible
proc GTK_ACCESSIBLE_CLASS*(klass: pointer): PGtkAccessibleClass
proc GTK_IS_ACCESSIBLE*(obj: pointer): bool
proc GTK_IS_ACCESSIBLE_CLASS*(klass: pointer): bool
proc GTK_ACCESSIBLE_GET_CLASS*(obj: pointer): PGtkAccessibleClass
proc gtk_accessible_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_accessible_get_type".}
proc gtk_accessible_connect_widget_destroyed*(accessible: PGtkAccessible){.
    cdecl, dynlib: gtklib, importc: "gtk_accessible_connect_widget_destroyed".}
proc GTK_TYPE_ADJUSTMENT*(): GType
proc GTK_ADJUSTMENT*(obj: pointer): PGtkAdjustment
proc GTK_ADJUSTMENT_CLASS*(klass: pointer): PGtkAdjustmentClass
proc GTK_IS_ADJUSTMENT*(obj: pointer): bool
proc GTK_IS_ADJUSTMENT_CLASS*(klass: pointer): bool
proc GTK_ADJUSTMENT_GET_CLASS*(obj: pointer): PGtkAdjustmentClass
proc gtk_adjustment_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_adjustment_get_type".}
proc gtk_adjustment_new*(value: gdouble, lower: gdouble, upper: gdouble,
                         step_increment: gdouble, page_increment: gdouble,
                         page_size: gdouble): PGtkAdjustment {.cdecl, dynlib: gtklib,
    importc: "gtk_adjustment_new".}
proc gtk_adjustment_changed*(adjustment: PGtkAdjustment){.cdecl, dynlib: gtklib,
    importc: "gtk_adjustment_changed".}
proc gtk_adjustment_value_changed*(adjustment: PGtkAdjustment){.cdecl,
    dynlib: gtklib, importc: "gtk_adjustment_value_changed".}
proc gtk_adjustment_clamp_page*(adjustment: PGtkAdjustment, lower: gdouble,
                                upper: gdouble){.cdecl, dynlib: gtklib,
    importc: "gtk_adjustment_clamp_page".}
proc gtk_adjustment_get_value*(adjustment: PGtkAdjustment): gdouble{.cdecl,
    dynlib: gtklib, importc: "gtk_adjustment_get_value".}
proc gtk_adjustment_set_value*(adjustment: PGtkAdjustment, value: gdouble){.
    cdecl, dynlib: gtklib, importc: "gtk_adjustment_set_value".}
proc GTK_TYPE_ALIGNMENT*(): GType
proc GTK_ALIGNMENT*(obj: pointer): PGtkAlignment
proc GTK_ALIGNMENT_CLASS*(klass: pointer): PGtkAlignmentClass
proc GTK_IS_ALIGNMENT*(obj: pointer): bool
proc GTK_IS_ALIGNMENT_CLASS*(klass: pointer): bool
proc GTK_ALIGNMENT_GET_CLASS*(obj: pointer): PGtkAlignmentClass
proc gtk_alignment_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_alignment_get_type".}
proc gtk_alignment_new*(xalign: gfloat, yalign: gfloat, xscale: gfloat,
                        yscale: gfloat): PGtkAlignment {.cdecl, dynlib: gtklib,
    importc: "gtk_alignment_new".}
proc gtk_alignment_set*(alignment: PGtkAlignment, xalign: gfloat,
                        yalign: gfloat, xscale: gfloat, yscale: gfloat){.cdecl,
    dynlib: gtklib, importc: "gtk_alignment_set".}
proc GTK_TYPE_FRAME*(): GType
proc GTK_FRAME*(obj: pointer): PGtkFrame
proc GTK_FRAME_CLASS*(klass: pointer): PGtkFrameClass
proc GTK_IS_FRAME*(obj: pointer): bool
proc GTK_IS_FRAME_CLASS*(klass: pointer): bool
proc GTK_FRAME_GET_CLASS*(obj: pointer): PGtkFrameClass
proc gtk_frame_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_frame_get_type".}
proc gtk_frame_new*(`label`: cstring): PGtkFrame {.cdecl, dynlib: gtklib,
    importc: "gtk_frame_new".}
proc gtk_frame_set_label*(frame: PGtkFrame, `label`: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_frame_set_label".}
proc gtk_frame_get_label*(frame: PGtkFrame): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_frame_get_label".}
proc gtk_frame_set_label_widget*(frame: PGtkFrame, label_widget: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "gtk_frame_set_label_widget".}
proc gtk_frame_get_label_widget*(frame: PGtkFrame): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_frame_get_label_widget".}
proc gtk_frame_set_label_align*(frame: PGtkFrame, xalign: gfloat, yalign: gfloat){.
    cdecl, dynlib: gtklib, importc: "gtk_frame_set_label_align".}
proc gtk_frame_get_label_align*(frame: PGtkFrame, xalign: Pgfloat,
                                yalign: Pgfloat){.cdecl, dynlib: gtklib,
    importc: "gtk_frame_get_label_align".}
proc gtk_frame_set_shadow_type*(frame: PGtkFrame, thetype: TGtkShadowType){.
    cdecl, dynlib: gtklib, importc: "gtk_frame_set_shadow_type".}
proc gtk_frame_get_shadow_type*(frame: PGtkFrame): TGtkShadowType{.cdecl,
    dynlib: gtklib, importc: "gtk_frame_get_shadow_type".}
proc GTK_TYPE_ASPECT_FRAME*(): GType
proc GTK_ASPECT_FRAME*(obj: pointer): PGtkAspectFrame
proc GTK_ASPECT_FRAME_CLASS*(klass: pointer): PGtkAspectFrameClass
proc GTK_IS_ASPECT_FRAME*(obj: pointer): bool
proc GTK_IS_ASPECT_FRAME_CLASS*(klass: pointer): bool
proc GTK_ASPECT_FRAME_GET_CLASS*(obj: pointer): PGtkAspectFrameClass
proc gtk_aspect_frame_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_aspect_frame_get_type".}
proc gtk_aspect_frame_new*(`label`: cstring, xalign: gfloat, yalign: gfloat,
                           ratio: gfloat, obey_child: gboolean): PGtkAspectFrame {.
    cdecl, dynlib: gtklib, importc: "gtk_aspect_frame_new".}
proc gtk_aspect_frame_set*(aspect_frame: PGtkAspectFrame, xalign: gfloat,
                           yalign: gfloat, ratio: gfloat, obey_child: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_aspect_frame_set".}
proc GTK_TYPE_ARROW*(): GType
proc GTK_ARROW*(obj: pointer): PGtkArrow
proc GTK_ARROW_CLASS*(klass: pointer): PGtkArrowClass
proc GTK_IS_ARROW*(obj: pointer): bool
proc GTK_IS_ARROW_CLASS*(klass: pointer): bool
proc GTK_ARROW_GET_CLASS*(obj: pointer): PGtkArrowClass
proc gtk_arrow_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_arrow_get_type".}
proc gtk_arrow_new*(arrow_type: TGtkArrowType, shadow_type: TGtkShadowType): PGtkArrow{.
    cdecl, dynlib: gtklib, importc: "gtk_arrow_new".}
proc gtk_arrow_set*(arrow: PGtkArrow, arrow_type: TGtkArrowType,
                    shadow_type: TGtkShadowType){.cdecl, dynlib: gtklib,
    importc: "gtk_arrow_set".}
const
  bm_TGtkBindingSet_parsed* = 0x00000001'i16
  bp_TGtkBindingSet_parsed* = 0'i16
  bm_TGtkBindingEntry_destroyed* = 0x00000001'i16
  bp_TGtkBindingEntry_destroyed* = 0'i16
  bm_TGtkBindingEntry_in_emission* = 0x00000002'i16
  bp_TGtkBindingEntry_in_emission* = 1'i16

proc gtk_binding_entry_add*(binding_set: PGtkBindingSet, keyval: guint,
                            modifiers: TGdkModifierType)
proc parsed*(a: var TGtkBindingSet): guint
proc set_parsed*(a: var TGtkBindingSet, `parsed`: guint)
proc destroyed*(a: var TGtkBindingEntry): guint
proc set_destroyed*(a: var TGtkBindingEntry, `destroyed`: guint)
proc in_emission*(a: var TGtkBindingEntry): guint
proc set_in_emission*(a: var TGtkBindingEntry, `in_emission`: guint)
proc gtk_binding_set_new*(set_name: cstring): PGtkBindingSet{.cdecl,
    dynlib: gtklib, importc: "gtk_binding_set_new".}
proc gtk_binding_set_by_class*(object_class: gpointer): PGtkBindingSet{.cdecl,
    dynlib: gtklib, importc: "gtk_binding_set_by_class".}
proc gtk_binding_set_find*(set_name: cstring): PGtkBindingSet{.cdecl,
    dynlib: gtklib, importc: "gtk_binding_set_find".}
proc gtk_bindings_activate*(anObject: PGtkObject, keyval: guint,
                            modifiers: TGdkModifierType): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_bindings_activate".}
proc gtk_binding_set_activate*(binding_set: PGtkBindingSet, keyval: guint,
                               modifiers: TGdkModifierType, anObject: PGtkObject): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_binding_set_activate".}
proc gtk_binding_entry_clear*(binding_set: PGtkBindingSet, keyval: guint,
                              modifiers: TGdkModifierType){.cdecl,
    dynlib: gtklib, importc: "gtk_binding_entry_clear".}
proc gtk_binding_set_add_path*(binding_set: PGtkBindingSet,
                               path_type: TGtkPathType, path_pattern: cstring,
                               priority: TGtkPathPriorityType){.cdecl,
    dynlib: gtklib, importc: "gtk_binding_set_add_path".}
proc gtk_binding_entry_remove*(binding_set: PGtkBindingSet, keyval: guint,
                               modifiers: TGdkModifierType){.cdecl,
    dynlib: gtklib, importc: "gtk_binding_entry_remove".}
proc gtk_binding_entry_add_signall*(binding_set: PGtkBindingSet, keyval: guint,
                                    modifiers: TGdkModifierType,
                                    signal_name: cstring, binding_args: PGSList){.
    cdecl, dynlib: gtklib, importc: "gtk_binding_entry_add_signall".}
proc gtk_binding_parse_binding*(scanner: PGScanner): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_binding_parse_binding".}
proc gtk_bindings_activate_event*(anObject: PGtkObject, event: PGdkEventKey): gboolean{.
    cdecl, dynlib: gtklib, importc: "_gtk_bindings_activate_event".}
proc gtk_binding_reset_parsed*(){.cdecl, dynlib: gtklib,
                                  importc: "_gtk_binding_reset_parsed".}
const
  bm_TGtkBox_homogeneous* = 0x00000001'i16
  bp_TGtkBox_homogeneous* = 0'i16
  bm_TGtkBoxChild_expand* = 0x00000001'i16
  bp_TGtkBoxChild_expand* = 0'i16
  bm_TGtkBoxChild_fill* = 0x00000002'i16
  bp_TGtkBoxChild_fill* = 1'i16
  bm_TGtkBoxChild_pack* = 0x00000004'i16
  bp_TGtkBoxChild_pack* = 2'i16
  bm_TGtkBoxChild_is_secondary* = 0x00000008'i16
  bp_TGtkBoxChild_is_secondary* = 3'i16

proc GTK_TYPE_BOX*(): GType
proc GTK_BOX*(obj: pointer): PGtkBox
proc GTK_BOX_CLASS*(klass: pointer): PGtkBoxClass
proc GTK_IS_BOX*(obj: pointer): bool
proc GTK_IS_BOX_CLASS*(klass: pointer): bool
proc GTK_BOX_GET_CLASS*(obj: pointer): PGtkBoxClass
proc homogeneous*(a: var TGtkBox): guint
proc set_homogeneous*(a: var TGtkBox, `homogeneous`: guint)
proc expand*(a: var TGtkBoxChild): guint
proc set_expand*(a: var TGtkBoxChild, `expand`: guint)
proc fill*(a: var TGtkBoxChild): guint
proc set_fill*(a: var TGtkBoxChild, `fill`: guint)
proc pack*(a: var TGtkBoxChild): guint
proc set_pack*(a: var TGtkBoxChild, `pack`: guint)
proc is_secondary*(a: var TGtkBoxChild): guint
proc set_is_secondary*(a: var TGtkBoxChild, `is_secondary`: guint)
proc gtk_box_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                    importc: "gtk_box_get_type".}
proc gtk_box_pack_start*(box: PGtkBox, child: PGtkWidget, expand: gboolean,
                         fill: gboolean, padding: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_box_pack_start".}
proc gtk_box_pack_end*(box: PGtkBox, child: PGtkWidget, expand: gboolean,
                       fill: gboolean, padding: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_box_pack_end".}
proc gtk_box_pack_start_defaults*(box: PGtkBox, widget: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_box_pack_start_defaults".}
proc gtk_box_pack_end_defaults*(box: PGtkBox, widget: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_box_pack_end_defaults".}
proc gtk_box_set_homogeneous*(box: PGtkBox, homogeneous: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_box_set_homogeneous".}
proc gtk_box_get_homogeneous*(box: PGtkBox): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_box_get_homogeneous".}
proc gtk_box_set_spacing*(box: PGtkBox, spacing: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_box_set_spacing".}
proc gtk_box_get_spacing*(box: PGtkBox): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_box_get_spacing".}
proc gtk_box_reorder_child*(box: PGtkBox, child: PGtkWidget, position: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_box_reorder_child".}
proc gtk_box_query_child_packing*(box: PGtkBox, child: PGtkWidget,
                                  expand: Pgboolean, fill: Pgboolean,
                                  padding: Pguint, pack_type: PGtkPackType){.
    cdecl, dynlib: gtklib, importc: "gtk_box_query_child_packing".}
proc gtk_box_set_child_packing*(box: PGtkBox, child: PGtkWidget,
                                expand: gboolean, fill: gboolean,
                                padding: guint, pack_type: TGtkPackType){.cdecl,
    dynlib: gtklib, importc: "gtk_box_set_child_packing".}
const
  GTK_BUTTONBOX_DEFAULT* = - (1)

proc GTK_TYPE_BUTTON_BOX*(): GType
proc GTK_BUTTON_BOX*(obj: pointer): PGtkButtonBox
proc GTK_BUTTON_BOX_CLASS*(klass: pointer): PGtkButtonBoxClass
proc GTK_IS_BUTTON_BOX*(obj: pointer): bool
proc GTK_IS_BUTTON_BOX_CLASS*(klass: pointer): bool
proc GTK_BUTTON_BOX_GET_CLASS*(obj: pointer): PGtkButtonBoxClass
proc gtk_button_box_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_button_box_get_type".}
proc gtk_button_box_get_layout*(widget: PGtkButtonBox): TGtkButtonBoxStyle{.
    cdecl, dynlib: gtklib, importc: "gtk_button_box_get_layout".}
proc gtk_button_box_set_layout*(widget: PGtkButtonBox,
                                layout_style: TGtkButtonBoxStyle){.cdecl,
    dynlib: gtklib, importc: "gtk_button_box_set_layout".}
proc gtk_button_box_set_child_secondary*(widget: PGtkButtonBox,
    child: PGtkWidget, is_secondary: gboolean){.cdecl, dynlib: gtklib,
    importc: "gtk_button_box_set_child_secondary".}
proc gtk_button_box_child_requisition*(widget: PGtkWidget,
    nvis_children: var int32, nvis_secondaries: var int32, width: var int32,
    height: var int32){.cdecl, dynlib: gtklib,
                       importc: "_gtk_button_box_child_requisition".}
const
  bm_TGtkButton_constructed* = 0x00000001'i16
  bp_TGtkButton_constructed* = 0'i16
  bm_TGtkButton_in_button* = 0x00000002'i16
  bp_TGtkButton_in_button* = 1'i16
  bm_TGtkButton_button_down* = 0x00000004'i16
  bp_TGtkButton_button_down* = 2'i16
  bm_TGtkButton_relief* = 0x00000018'i16
  bp_TGtkButton_relief* = 3'i16
  bm_TGtkButton_use_underline* = 0x00000020'i16
  bp_TGtkButton_use_underline* = 5'i16
  bm_TGtkButton_use_stock* = 0x00000040'i16
  bp_TGtkButton_use_stock* = 6'i16
  bm_TGtkButton_depressed* = 0x00000080'i16
  bp_TGtkButton_depressed* = 7'i16
  bm_TGtkButton_depress_on_activate* = 0x00000100'i16
  bp_TGtkButton_depress_on_activate* = 8'i16

proc GTK_TYPE_BUTTON*(): GType
proc GTK_BUTTON*(obj: pointer): PGtkButton
proc GTK_BUTTON_CLASS*(klass: pointer): PGtkButtonClass
proc GTK_IS_BUTTON*(obj: pointer): bool
proc GTK_IS_BUTTON_CLASS*(klass: pointer): bool
proc GTK_BUTTON_GET_CLASS*(obj: pointer): PGtkButtonClass
proc constructed*(a: var TGtkButton): guint
proc set_constructed*(a: var TGtkButton, `constructed`: guint)
proc in_button*(a: var TGtkButton): guint
proc set_in_button*(a: var TGtkButton, `in_button`: guint)
proc button_down*(a: var TGtkButton): guint
proc set_button_down*(a: var TGtkButton, `button_down`: guint)
proc relief*(a: var TGtkButton): guint
proc set_relief*(a: var TGtkButton, `relief`: guint)
proc use_underline*(a: var TGtkButton): guint
proc set_use_underline*(a: var TGtkButton, `use_underline`: guint)
proc use_stock*(a: var TGtkButton): guint
proc set_use_stock*(a: var TGtkButton, `use_stock`: guint)
proc depressed*(a: var TGtkButton): guint
proc set_depressed*(a: var TGtkButton, `depressed`: guint)
proc depress_on_activate*(a: var TGtkButton): guint
proc set_depress_on_activate*(a: var TGtkButton, `depress_on_activate`: guint)
proc gtk_button_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_button_get_type".}
proc gtk_button_new*(): PGtkButton {.cdecl, dynlib: gtklib,
                                    importc: "gtk_button_new".}
proc gtk_button_new_with_label*(`label`: cstring): PGtkButton {.cdecl,
    dynlib: gtklib, importc: "gtk_button_new_with_label".}
proc gtk_button_new_from_stock*(stock_id: cstring): PGtkButton {.cdecl,
    dynlib: gtklib, importc: "gtk_button_new_from_stock".}
proc gtk_button_new_with_mnemonic*(`label`: cstring): PGtkButton {.cdecl,
    dynlib: gtklib, importc: "gtk_button_new_with_mnemonic".}
proc gtk_button_pressed*(button: PGtkButton){.cdecl, dynlib: gtklib,
    importc: "gtk_button_pressed".}
proc gtk_button_released*(button: PGtkButton){.cdecl, dynlib: gtklib,
    importc: "gtk_button_released".}
proc gtk_button_clicked*(button: PGtkButton){.cdecl, dynlib: gtklib,
    importc: "gtk_button_clicked".}
proc gtk_button_enter*(button: PGtkButton){.cdecl, dynlib: gtklib,
    importc: "gtk_button_enter".}
proc gtk_button_leave*(button: PGtkButton){.cdecl, dynlib: gtklib,
    importc: "gtk_button_leave".}
proc gtk_button_set_relief*(button: PGtkButton, newstyle: TGtkReliefStyle){.
    cdecl, dynlib: gtklib, importc: "gtk_button_set_relief".}
proc gtk_button_get_relief*(button: PGtkButton): TGtkReliefStyle{.cdecl,
    dynlib: gtklib, importc: "gtk_button_get_relief".}
proc gtk_button_set_label*(button: PGtkButton, `label`: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_button_set_label".}
proc gtk_button_get_label*(button: PGtkButton): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_button_get_label".}
proc gtk_button_set_use_underline*(button: PGtkButton, use_underline: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_button_set_use_underline".}
proc gtk_button_get_use_underline*(button: PGtkButton): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_button_get_use_underline".}
proc gtk_button_set_use_stock*(button: PGtkButton, use_stock: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_button_set_use_stock".}
proc gtk_button_get_use_stock*(button: PGtkButton): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_button_get_use_stock".}
proc gtk_button_set_depressed*(button: PGtkButton, depressed: gboolean){.
    cdecl, dynlib: gtklib, importc: "_gtk_button_set_depressed".}
proc gtk_button_paint*(button: PGtkButton, area: PGdkRectangle,
                         state_type: TGtkStateType, shadow_type: TGtkShadowType,
                         main_detail: cstring, default_detail: cstring){.cdecl,
    dynlib: gtklib, importc: "_gtk_button_paint".}
proc gtk_button_set_image*(button: PGtkButton, image: PGtkWidget) {.cdecl,
    dynlib: gtklib, importc.}
proc gtk_button_get_image*(button: PGtkButton): PGtkWidget {.cdecl, 
    dynlib: gtklib, importc.}
    
const
  GTK_CALENDAR_SHOW_HEADING* = 1 shl 0
  GTK_CALENDAR_SHOW_DAY_NAMES* = 1 shl 1
  GTK_CALENDAR_NO_MONTH_CHANGE* = 1 shl 2
  GTK_CALENDAR_SHOW_WEEK_NUMBERS* = 1 shl 3
  GTK_CALENDAR_WEEK_START_MONDAY* = 1 shl 4

proc GTK_TYPE_CALENDAR*(): GType
proc GTK_CALENDAR*(obj: pointer): PGtkCalendar
proc GTK_CALENDAR_CLASS*(klass: pointer): PGtkCalendarClass
proc GTK_IS_CALENDAR*(obj: pointer): bool
proc GTK_IS_CALENDAR_CLASS*(klass: pointer): bool
proc GTK_CALENDAR_GET_CLASS*(obj: pointer): PGtkCalendarClass
proc gtk_calendar_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_calendar_get_type".}
proc gtk_calendar_new*(): PGtkCalendar {.cdecl, dynlib: gtklib,
                                      importc: "gtk_calendar_new".}
proc gtk_calendar_select_month*(calendar: PGtkCalendar, month: guint,
                                year: guint): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_calendar_select_month".}
proc gtk_calendar_select_day*(calendar: PGtkCalendar, day: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_calendar_select_day".}
proc gtk_calendar_mark_day*(calendar: PGtkCalendar, day: guint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_calendar_mark_day".}
proc gtk_calendar_unmark_day*(calendar: PGtkCalendar, day: guint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_calendar_unmark_day".}
proc gtk_calendar_clear_marks*(calendar: PGtkCalendar){.cdecl, dynlib: gtklib,
    importc: "gtk_calendar_clear_marks".}
proc gtk_calendar_display_options*(calendar: PGtkCalendar,
                                   flags: TGtkCalendarDisplayOptions){.cdecl,
    dynlib: gtklib, importc: "gtk_calendar_display_options".}
proc gtk_calendar_get_date*(calendar: PGtkCalendar, year: Pguint, month: Pguint,
                            day: Pguint){.cdecl, dynlib: gtklib,
    importc: "gtk_calendar_get_date".}
proc gtk_calendar_freeze*(calendar: PGtkCalendar){.cdecl, dynlib: gtklib,
    importc: "gtk_calendar_freeze".}
proc gtk_calendar_thaw*(calendar: PGtkCalendar){.cdecl, dynlib: gtklib,
    importc: "gtk_calendar_thaw".}
proc GTK_TYPE_CELL_EDITABLE*(): GType
proc GTK_CELL_EDITABLE*(obj: pointer): PGtkCellEditable
proc GTK_CELL_EDITABLE_CLASS*(obj: pointer): PGtkCellEditableIface
proc GTK_IS_CELL_EDITABLE*(obj: pointer): bool
proc GTK_CELL_EDITABLE_GET_IFACE*(obj: pointer): PGtkCellEditableIface
proc gtk_cell_editable_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_cell_editable_get_type".}
proc gtk_cell_editable_start_editing*(cell_editable: PGtkCellEditable,
                                      event: PGdkEvent){.cdecl, dynlib: gtklib,
    importc: "gtk_cell_editable_start_editing".}
proc gtk_cell_editable_editing_done*(cell_editable: PGtkCellEditable){.cdecl,
    dynlib: gtklib, importc: "gtk_cell_editable_editing_done".}
proc gtk_cell_editable_remove_widget*(cell_editable: PGtkCellEditable){.cdecl,
    dynlib: gtklib, importc: "gtk_cell_editable_remove_widget".}
const
  GTK_CELL_RENDERER_SELECTED* = 1 shl 0
  GTK_CELL_RENDERER_PRELIT* = 1 shl 1
  GTK_CELL_RENDERER_INSENSITIVE* = 1 shl 2
  GTK_CELL_RENDERER_SORTED* = 1 shl 3

const
  bm_TGtkCellRenderer_mode* = 0x00000003'i16
  bp_TGtkCellRenderer_mode* = 0'i16
  bm_TGtkCellRenderer_visible* = 0x00000004'i16
  bp_TGtkCellRenderer_visible* = 2'i16
  bm_TGtkCellRenderer_is_expander* = 0x00000008'i16
  bp_TGtkCellRenderer_is_expander* = 3'i16
  bm_TGtkCellRenderer_is_expanded* = 0x00000010'i16
  bp_TGtkCellRenderer_is_expanded* = 4'i16
  bm_TGtkCellRenderer_cell_background_set* = 0x00000020'i16
  bp_TGtkCellRenderer_cell_background_set* = 5'i16

proc GTK_TYPE_CELL_RENDERER*(): GType
proc GTK_CELL_RENDERER*(obj: pointer): PGtkCellRenderer
proc GTK_CELL_RENDERER_CLASS*(klass: pointer): PGtkCellRendererClass
proc GTK_IS_CELL_RENDERER*(obj: pointer): bool
proc GTK_IS_CELL_RENDERER_CLASS*(klass: pointer): bool
proc GTK_CELL_RENDERER_GET_CLASS*(obj: pointer): PGtkCellRendererClass
proc mode*(a: var TGtkCellRenderer): guint
proc set_mode*(a: var TGtkCellRenderer, `mode`: guint)
proc visible*(a: var TGtkCellRenderer): guint
proc set_visible*(a: var TGtkCellRenderer, `visible`: guint)
proc is_expander*(a: var TGtkCellRenderer): guint
proc set_is_expander*(a: var TGtkCellRenderer, `is_expander`: guint)
proc is_expanded*(a: var TGtkCellRenderer): guint
proc set_is_expanded*(a: var TGtkCellRenderer, `is_expanded`: guint)
proc cell_background_set*(a: var TGtkCellRenderer): guint
proc set_cell_background_set*(a: var TGtkCellRenderer,
                              `cell_background_set`: guint)
proc gtk_cell_renderer_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_cell_renderer_get_type".}
proc gtk_cell_renderer_get_size*(cell: PGtkCellRenderer, widget: PGtkWidget,
                                 cell_area: PGdkRectangle, x_offset: Pgint,
                                 y_offset: Pgint, width: Pgint, height: Pgint){.
    cdecl, dynlib: gtklib, importc: "gtk_cell_renderer_get_size".}
proc gtk_cell_renderer_render*(cell: PGtkCellRenderer, window: PGdkWindow,
                               widget: PGtkWidget,
                               background_area: PGdkRectangle,
                               cell_area: PGdkRectangle,
                               expose_area: PGdkRectangle,
                               flags: TGtkCellRendererState){.cdecl,
    dynlib: gtklib, importc: "gtk_cell_renderer_render".}
proc gtk_cell_renderer_activate*(cell: PGtkCellRenderer, event: PGdkEvent,
                                 widget: PGtkWidget, path: cstring,
                                 background_area: PGdkRectangle,
                                 cell_area: PGdkRectangle,
                                 flags: TGtkCellRendererState): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_cell_renderer_activate".}
proc gtk_cell_renderer_start_editing*(cell: PGtkCellRenderer, event: PGdkEvent,
                                      widget: PGtkWidget, path: cstring,
                                      background_area: PGdkRectangle,
                                      cell_area: PGdkRectangle,
                                      flags: TGtkCellRendererState): PGtkCellEditable{.
    cdecl, dynlib: gtklib, importc: "gtk_cell_renderer_start_editing".}
proc gtk_cell_renderer_set_fixed_size*(cell: PGtkCellRenderer, width: gint,
                                       height: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_cell_renderer_set_fixed_size".}
proc gtk_cell_renderer_get_fixed_size*(cell: PGtkCellRenderer, width: Pgint,
                                       height: Pgint){.cdecl, dynlib: gtklib,
    importc: "gtk_cell_renderer_get_fixed_size".}
const
  bm_TGtkCellRendererText_strikethrough* = 0x00000001'i16
  bp_TGtkCellRendererText_strikethrough* = 0'i16
  bm_TGtkCellRendererText_editable* = 0x00000002'i16
  bp_TGtkCellRendererText_editable* = 1'i16
  bm_TGtkCellRendererText_scale_set* = 0x00000004'i16
  bp_TGtkCellRendererText_scale_set* = 2'i16
  bm_TGtkCellRendererText_foreground_set* = 0x00000008'i16
  bp_TGtkCellRendererText_foreground_set* = 3'i16
  bm_TGtkCellRendererText_background_set* = 0x00000010'i16
  bp_TGtkCellRendererText_background_set* = 4'i16
  bm_TGtkCellRendererText_underline_set* = 0x00000020'i16
  bp_TGtkCellRendererText_underline_set* = 5'i16
  bm_TGtkCellRendererText_rise_set* = 0x00000040'i16
  bp_TGtkCellRendererText_rise_set* = 6'i16
  bm_TGtkCellRendererText_strikethrough_set* = 0x00000080'i16
  bp_TGtkCellRendererText_strikethrough_set* = 7'i16
  bm_TGtkCellRendererText_editable_set* = 0x00000100'i16
  bp_TGtkCellRendererText_editable_set* = 8'i16
  bm_TGtkCellRendererText_calc_fixed_height* = 0x00000200'i16
  bp_TGtkCellRendererText_calc_fixed_height* = 9'i16

proc GTK_TYPE_CELL_RENDERER_TEXT*(): GType
proc GTK_CELL_RENDERER_TEXT*(obj: pointer): PGtkCellRendererText
proc GTK_CELL_RENDERER_TEXT_CLASS*(klass: pointer): PGtkCellRendererTextClass
proc GTK_IS_CELL_RENDERER_TEXT*(obj: pointer): bool
proc GTK_IS_CELL_RENDERER_TEXT_CLASS*(klass: pointer): bool
proc GTK_CELL_RENDERER_TEXT_GET_CLASS*(obj: pointer): PGtkCellRendererTextClass
proc strikethrough*(a: var TGtkCellRendererText): guint
proc set_strikethrough*(a: var TGtkCellRendererText, `strikethrough`: guint)
proc editable*(a: var TGtkCellRendererText): guint
proc set_editable*(a: var TGtkCellRendererText, `editable`: guint)
proc scale_set*(a: var TGtkCellRendererText): guint
proc set_scale_set*(a: var TGtkCellRendererText, `scale_set`: guint)
proc foreground_set*(a: var TGtkCellRendererText): guint
proc set_foreground_set*(a: var TGtkCellRendererText, `foreground_set`: guint)
proc background_set*(a: var TGtkCellRendererText): guint
proc set_background_set*(a: var TGtkCellRendererText, `background_set`: guint)
proc underline_set*(a: var TGtkCellRendererText): guint
proc set_underline_set*(a: var TGtkCellRendererText, `underline_set`: guint)
proc rise_set*(a: var TGtkCellRendererText): guint
proc set_rise_set*(a: var TGtkCellRendererText, `rise_set`: guint)
proc strikethrough_set*(a: var TGtkCellRendererText): guint
proc set_strikethrough_set*(a: var TGtkCellRendererText,
                            `strikethrough_set`: guint)
proc editable_set*(a: var TGtkCellRendererText): guint
proc set_editable_set*(a: var TGtkCellRendererText, `editable_set`: guint)
proc calc_fixed_height*(a: var TGtkCellRendererText): guint
proc set_calc_fixed_height*(a: var TGtkCellRendererText,
                            `calc_fixed_height`: guint)
proc gtk_cell_renderer_text_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_cell_renderer_text_get_type".}
proc gtk_cell_renderer_text_new*(): PGtkCellRenderer{.cdecl, dynlib: gtklib,
    importc: "gtk_cell_renderer_text_new".}
proc gtk_cell_renderer_text_set_fixed_height_from_font*(
    renderer: PGtkCellRendererText, number_of_rows: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_cell_renderer_text_set_fixed_height_from_font".}
const
  bm_TGtkCellRendererToggle_active* = 0x00000001'i16
  bp_TGtkCellRendererToggle_active* = 0'i16
  bm_TGtkCellRendererToggle_activatable* = 0x00000002'i16
  bp_TGtkCellRendererToggle_activatable* = 1'i16
  bm_TGtkCellRendererToggle_radio* = 0x00000004'i16
  bp_TGtkCellRendererToggle_radio* = 2'i16

proc GTK_TYPE_CELL_RENDERER_TOGGLE*(): GType
proc GTK_CELL_RENDERER_TOGGLE*(obj: pointer): PGtkCellRendererToggle
proc GTK_CELL_RENDERER_TOGGLE_CLASS*(klass: pointer): PGtkCellRendererToggleClass
proc GTK_IS_CELL_RENDERER_TOGGLE*(obj: pointer): bool
proc GTK_IS_CELL_RENDERER_TOGGLE_CLASS*(klass: pointer): bool
proc GTK_CELL_RENDERER_TOGGLE_GET_CLASS*(obj: pointer): PGtkCellRendererToggleClass
proc active*(a: var TGtkCellRendererToggle): guint
proc set_active*(a: var TGtkCellRendererToggle, `active`: guint)
proc activatable*(a: var TGtkCellRendererToggle): guint
proc set_activatable*(a: var TGtkCellRendererToggle, `activatable`: guint)
proc radio*(a: var TGtkCellRendererToggle): guint
proc set_radio*(a: var TGtkCellRendererToggle, `radio`: guint)
proc gtk_cell_renderer_toggle_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_cell_renderer_toggle_get_type".}
proc gtk_cell_renderer_toggle_new*(): PGtkCellRenderer{.cdecl, dynlib: gtklib,
    importc: "gtk_cell_renderer_toggle_new".}
proc gtk_cell_renderer_toggle_get_radio*(toggle: PGtkCellRendererToggle): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_cell_renderer_toggle_get_radio".}
proc gtk_cell_renderer_toggle_set_radio*(toggle: PGtkCellRendererToggle,
    radio: gboolean){.cdecl, dynlib: gtklib,
                      importc: "gtk_cell_renderer_toggle_set_radio".}
proc gtk_cell_renderer_toggle_get_active*(toggle: PGtkCellRendererToggle): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_cell_renderer_toggle_get_active".}
proc gtk_cell_renderer_toggle_set_active*(toggle: PGtkCellRendererToggle,
    setting: gboolean){.cdecl, dynlib: gtklib,
                        importc: "gtk_cell_renderer_toggle_set_active".}
proc GTK_TYPE_CELL_RENDERER_PIXBUF*(): GType
proc GTK_CELL_RENDERER_PIXBUF*(obj: pointer): PGtkCellRendererPixbuf
proc GTK_CELL_RENDERER_PIXBUF_CLASS*(klass: pointer): PGtkCellRendererPixbufClass
proc GTK_IS_CELL_RENDERER_PIXBUF*(obj: pointer): bool
proc GTK_IS_CELL_RENDERER_PIXBUF_CLASS*(klass: pointer): bool
proc GTK_CELL_RENDERER_PIXBUF_GET_CLASS*(obj: pointer): PGtkCellRendererPixbufClass
proc gtk_cell_renderer_pixbuf_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_cell_renderer_pixbuf_get_type".}
proc gtk_cell_renderer_pixbuf_new*(): PGtkCellRenderer{.cdecl, dynlib: gtklib,
    importc: "gtk_cell_renderer_pixbuf_new".}
proc GTK_TYPE_ITEM*(): GType
proc GTK_ITEM*(obj: pointer): PGtkItem
proc GTK_ITEM_CLASS*(klass: pointer): PGtkItemClass
proc GTK_IS_ITEM*(obj: pointer): bool
proc GTK_IS_ITEM_CLASS*(klass: pointer): bool
proc GTK_ITEM_GET_CLASS*(obj: pointer): PGtkItemClass
proc gtk_item_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                     importc: "gtk_item_get_type".}
proc gtk_item_select*(item: PGtkItem){.cdecl, dynlib: gtklib,
                                       importc: "gtk_item_select".}
proc gtk_item_deselect*(item: PGtkItem){.cdecl, dynlib: gtklib,
    importc: "gtk_item_deselect".}
proc gtk_item_toggle*(item: PGtkItem){.cdecl, dynlib: gtklib,
                                       importc: "gtk_item_toggle".}
const
  bm_TGtkMenuItem_show_submenu_indicator* = 0x00000001'i16
  bp_TGtkMenuItem_show_submenu_indicator* = 0'i16
  bm_TGtkMenuItem_submenu_placement* = 0x00000002'i16
  bp_TGtkMenuItem_submenu_placement* = 1'i16
  bm_TGtkMenuItem_submenu_direction* = 0x00000004'i16
  bp_TGtkMenuItem_submenu_direction* = 2'i16
  bm_TGtkMenuItem_right_justify* = 0x00000008'i16
  bp_TGtkMenuItem_right_justify* = 3'i16
  bm_TGtkMenuItem_timer_from_keypress* = 0x00000010'i16
  bp_TGtkMenuItem_timer_from_keypress* = 4'i16
  bm_TGtkMenuItemClass_hide_on_activate* = 0x00000001'i16
  bp_TGtkMenuItemClass_hide_on_activate* = 0'i16

proc GTK_TYPE_MENU_ITEM*(): GType
proc GTK_MENU_ITEM*(obj: pointer): PGtkMenuItem
proc GTK_MENU_ITEM_CLASS*(klass: pointer): PGtkMenuItemClass
proc GTK_IS_MENU_ITEM*(obj: pointer): bool
proc GTK_IS_MENU_ITEM_CLASS*(klass: pointer): bool
proc GTK_MENU_ITEM_GET_CLASS*(obj: pointer): PGtkMenuItemClass
proc show_submenu_indicator*(a: var TGtkMenuItem): guint
proc set_show_submenu_indicator*(a: var TGtkMenuItem,
                                 `show_submenu_indicator`: guint)
proc submenu_placement*(a: var TGtkMenuItem): guint
proc set_submenu_placement*(a: var TGtkMenuItem, `submenu_placement`: guint)
proc submenu_direction*(a: var TGtkMenuItem): guint
proc set_submenu_direction*(a: var TGtkMenuItem, `submenu_direction`: guint)
proc right_justify*(a: var TGtkMenuItem): guint
proc set_right_justify*(a: var TGtkMenuItem, `right_justify`: guint)
proc timer_from_keypress*(a: var TGtkMenuItem): guint
proc set_timer_from_keypress*(a: var TGtkMenuItem, `timer_from_keypress`: guint)
proc hide_on_activate*(a: var TGtkMenuItemClass): guint
proc set_hide_on_activate*(a: var TGtkMenuItemClass, `hide_on_activate`: guint)
proc gtk_menu_item_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_menu_item_get_type".}
proc gtk_menu_item_new*(): PGtkMenuItem {.cdecl, dynlib: gtklib,
                                       importc: "gtk_menu_item_new".}
proc gtk_menu_item_new_with_label*(`label`: cstring): PGtkMenuItem {.cdecl,
    dynlib: gtklib, importc: "gtk_menu_item_new_with_label".}
proc gtk_menu_item_new_with_mnemonic*(`label`: cstring): PGtkMenuItem {.cdecl,
    dynlib: gtklib, importc: "gtk_menu_item_new_with_mnemonic".}
proc gtk_menu_item_set_submenu*(menu_item: PGtkMenuItem, submenu: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "gtk_menu_item_set_submenu".}
proc gtk_menu_item_get_submenu*(menu_item: PGtkMenuItem): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_menu_item_get_submenu".}
proc gtk_menu_item_remove_submenu*(menu_item: PGtkMenuItem){.cdecl,
    dynlib: gtklib, importc: "gtk_menu_item_remove_submenu".}
proc gtk_menu_item_select*(menu_item: PGtkMenuItem){.cdecl, dynlib: gtklib,
    importc: "gtk_menu_item_select".}
proc gtk_menu_item_deselect*(menu_item: PGtkMenuItem){.cdecl, dynlib: gtklib,
    importc: "gtk_menu_item_deselect".}
proc gtk_menu_item_activate*(menu_item: PGtkMenuItem){.cdecl, dynlib: gtklib,
    importc: "gtk_menu_item_activate".}
proc gtk_menu_item_toggle_size_request*(menu_item: PGtkMenuItem,
                                        requisition: Pgint){.cdecl,
    dynlib: gtklib, importc: "gtk_menu_item_toggle_size_request".}
proc gtk_menu_item_toggle_size_allocate*(menu_item: PGtkMenuItem,
    allocation: gint){.cdecl, dynlib: gtklib,
                       importc: "gtk_menu_item_toggle_size_allocate".}
proc gtk_menu_item_set_right_justified*(menu_item: PGtkMenuItem,
                                        right_justified: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_menu_item_set_right_justified".}
proc gtk_menu_item_get_right_justified*(menu_item: PGtkMenuItem): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_menu_item_get_right_justified".}
proc gtk_menu_item_set_accel_path*(menu_item: PGtkMenuItem, accel_path: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_menu_item_set_accel_path".}
proc gtk_menu_item_refresh_accel_path*(menu_item: PGtkMenuItem,
    prefix: cstring, accel_group: PGtkAccelGroup, group_changed: gboolean){.
    cdecl, dynlib: gtklib, importc: "_gtk_menu_item_refresh_accel_path".}
proc gtk_menu_item_is_selectable*(menu_item: PGtkWidget): gboolean{.cdecl,
    dynlib: gtklib, importc: "_gtk_menu_item_is_selectable".}
const
  bm_TGtkToggleButton_active* = 0x00000001'i16
  bp_TGtkToggleButton_active* = 0'i16
  bm_TGtkToggleButton_draw_indicator* = 0x00000002'i16
  bp_TGtkToggleButton_draw_indicator* = 1'i16
  bm_TGtkToggleButton_inconsistent* = 0x00000004'i16
  bp_TGtkToggleButton_inconsistent* = 2'i16

proc GTK_TYPE_TOGGLE_BUTTON*(): GType
proc GTK_TOGGLE_BUTTON*(obj: pointer): PGtkToggleButton
proc GTK_TOGGLE_BUTTON_CLASS*(klass: pointer): PGtkToggleButtonClass
proc GTK_IS_TOGGLE_BUTTON*(obj: pointer): bool
proc GTK_IS_TOGGLE_BUTTON_CLASS*(klass: pointer): bool
proc GTK_TOGGLE_BUTTON_GET_CLASS*(obj: pointer): PGtkToggleButtonClass
proc active*(a: var TGtkToggleButton): guint
proc set_active*(a: var TGtkToggleButton, `active`: guint)
proc draw_indicator*(a: var TGtkToggleButton): guint
proc set_draw_indicator*(a: var TGtkToggleButton, `draw_indicator`: guint)
proc inconsistent*(a: var TGtkToggleButton): guint
proc set_inconsistent*(a: var TGtkToggleButton, `inconsistent`: guint)
proc gtk_toggle_button_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_toggle_button_get_type".}
proc gtk_toggle_button_new*(): PGtkToggleButton {.cdecl, dynlib: gtklib,
    importc: "gtk_toggle_button_new".}
proc gtk_toggle_button_new_with_label*(`label`: cstring): PGtkToggleButton {.cdecl,
    dynlib: gtklib, importc: "gtk_toggle_button_new_with_label".}
proc gtk_toggle_button_new_with_mnemonic*(`label`: cstring): PGtkToggleButton {.cdecl,
    dynlib: gtklib, importc: "gtk_toggle_button_new_with_mnemonic".}
proc gtk_toggle_button_set_mode*(toggle_button: PGtkToggleButton,
                                 draw_indicator: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_toggle_button_set_mode".}
proc gtk_toggle_button_get_mode*(toggle_button: PGtkToggleButton): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_toggle_button_get_mode".}
proc gtk_toggle_button_set_active*(toggle_button: PGtkToggleButton,
                                   is_active: gboolean){.cdecl, dynlib: gtklib,
    importc: "gtk_toggle_button_set_active".}
proc gtk_toggle_button_get_active*(toggle_button: PGtkToggleButton): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_toggle_button_get_active".}
proc gtk_toggle_button_toggled*(toggle_button: PGtkToggleButton){.cdecl,
    dynlib: gtklib, importc: "gtk_toggle_button_toggled".}
proc gtk_toggle_button_set_inconsistent*(toggle_button: PGtkToggleButton,
    setting: gboolean){.cdecl, dynlib: gtklib,
                        importc: "gtk_toggle_button_set_inconsistent".}
proc gtk_toggle_button_get_inconsistent*(toggle_button: PGtkToggleButton): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_toggle_button_get_inconsistent".}
proc GTK_TYPE_CHECK_BUTTON*(): GType
proc GTK_CHECK_BUTTON*(obj: pointer): PGtkCheckButton
proc GTK_CHECK_BUTTON_CLASS*(klass: pointer): PGtkCheckButtonClass
proc GTK_IS_CHECK_BUTTON*(obj: pointer): bool
proc GTK_IS_CHECK_BUTTON_CLASS*(klass: pointer): bool
proc GTK_CHECK_BUTTON_GET_CLASS*(obj: pointer): PGtkCheckButtonClass
proc gtk_check_button_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_check_button_get_type".}
proc gtk_check_button_new*(): PGtkCheckButton{.cdecl, dynlib: gtklib,
    importc: "gtk_check_button_new".}
proc gtk_check_button_new_with_label*(`label`: cstring): PGtkCheckButton{.cdecl,
    dynlib: gtklib, importc: "gtk_check_button_new_with_label".}
proc gtk_check_button_new_with_mnemonic*(`label`: cstring): PGtkCheckButton {.cdecl,
    dynlib: gtklib, importc: "gtk_check_button_new_with_mnemonic".}
proc gtk_check_button_get_props*(check_button: PGtkCheckButton,
                                   indicator_size: Pgint,
                                   indicator_spacing: Pgint){.cdecl,
    dynlib: gtklib, importc: "_gtk_check_button_get_props".}
const
  bm_TGtkCheckMenuItem_active* = 0x00000001'i16
  bp_TGtkCheckMenuItem_active* = 0'i16
  bm_TGtkCheckMenuItem_always_show_toggle* = 0x00000002'i16
  bp_TGtkCheckMenuItem_always_show_toggle* = 1'i16
  bm_TGtkCheckMenuItem_inconsistent* = 0x00000004'i16
  bp_TGtkCheckMenuItem_inconsistent* = 2'i16

proc GTK_TYPE_CHECK_MENU_ITEM*(): GType
proc GTK_CHECK_MENU_ITEM*(obj: pointer): PGtkCheckMenuItem
proc GTK_CHECK_MENU_ITEM_CLASS*(klass: pointer): PGtkCheckMenuItemClass
proc GTK_IS_CHECK_MENU_ITEM*(obj: pointer): bool
proc GTK_IS_CHECK_MENU_ITEM_CLASS*(klass: pointer): bool
proc GTK_CHECK_MENU_ITEM_GET_CLASS*(obj: pointer): PGtkCheckMenuItemClass
proc active*(a: var TGtkCheckMenuItem): guint
proc set_active*(a: var TGtkCheckMenuItem, `active`: guint)
proc always_show_toggle*(a: var TGtkCheckMenuItem): guint
proc set_always_show_toggle*(a: var TGtkCheckMenuItem,
                             `always_show_toggle`: guint)
proc inconsistent*(a: var TGtkCheckMenuItem): guint
proc set_inconsistent*(a: var TGtkCheckMenuItem, `inconsistent`: guint)
proc gtk_check_menu_item_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_check_menu_item_get_type".}
proc gtk_check_menu_item_new*(): PGtkWidget{.cdecl, dynlib: gtklib,
    importc: "gtk_check_menu_item_new".}
proc gtk_check_menu_item_new_with_label*(`label`: cstring): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_check_menu_item_new_with_label".}
proc gtk_check_menu_item_new_with_mnemonic*(`label`: cstring): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_check_menu_item_new_with_mnemonic".}
proc gtk_check_menu_item_set_active*(check_menu_item: PGtkCheckMenuItem,
                                     is_active: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_check_menu_item_set_active".}
proc gtk_check_menu_item_get_active*(check_menu_item: PGtkCheckMenuItem): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_check_menu_item_get_active".}
proc gtk_check_menu_item_toggled*(check_menu_item: PGtkCheckMenuItem){.cdecl,
    dynlib: gtklib, importc: "gtk_check_menu_item_toggled".}
proc gtk_check_menu_item_set_inconsistent*(check_menu_item: PGtkCheckMenuItem,
    setting: gboolean){.cdecl, dynlib: gtklib,
                        importc: "gtk_check_menu_item_set_inconsistent".}
proc gtk_check_menu_item_get_inconsistent*(check_menu_item: PGtkCheckMenuItem): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_check_menu_item_get_inconsistent".}
proc gtk_clipboard_get_for_display*(display: PGdkDisplay, selection: TGdkAtom): PGtkClipboard{.
    cdecl, dynlib: gtklib, importc: "gtk_clipboard_get_for_display".}
proc gtk_clipboard_get_display*(clipboard: PGtkClipboard): PGdkDisplay{.cdecl,
    dynlib: gtklib, importc: "gtk_clipboard_get_display".}
proc gtk_clipboard_set_with_data*(clipboard: PGtkClipboard,
                                  targets: PGtkTargetEntry, n_targets: guint,
                                  get_func: TGtkClipboardGetFunc,
                                  clear_func: TGtkClipboardClearFunc,
                                  user_data: gpointer): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_clipboard_set_with_data".}
proc gtk_clipboard_set_with_owner*(clipboard: PGtkClipboard,
                                   targets: PGtkTargetEntry, n_targets: guint,
                                   get_func: TGtkClipboardGetFunc,
                                   clear_func: TGtkClipboardClearFunc,
                                   owner: PGObject): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_clipboard_set_with_owner".}
proc gtk_clipboard_get_owner*(clipboard: PGtkClipboard): PGObject{.cdecl,
    dynlib: gtklib, importc: "gtk_clipboard_get_owner".}
proc gtk_clipboard_clear*(clipboard: PGtkClipboard){.cdecl, dynlib: gtklib,
    importc: "gtk_clipboard_clear".}
proc gtk_clipboard_set_text*(clipboard: PGtkClipboard, text: cstring, len: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_clipboard_set_text".}
proc gtk_clipboard_request_contents*(clipboard: PGtkClipboard, target: TGdkAtom,
                                     callback: TGtkClipboardReceivedFunc,
                                     user_data: gpointer){.cdecl,
    dynlib: gtklib, importc: "gtk_clipboard_request_contents".}
proc gtk_clipboard_request_text*(clipboard: PGtkClipboard,
                                 callback: TGtkClipboardTextReceivedFunc,
                                 user_data: gpointer){.cdecl, dynlib: gtklib,
    importc: "gtk_clipboard_request_text".}
proc gtk_clipboard_wait_for_contents*(clipboard: PGtkClipboard, target: TGdkAtom): PGtkSelectionData{.
    cdecl, dynlib: gtklib, importc: "gtk_clipboard_wait_for_contents".}
proc gtk_clipboard_wait_for_text*(clipboard: PGtkClipboard): cstring{.cdecl,
    dynlib: gtklib, importc: "gtk_clipboard_wait_for_text".}
proc gtk_clipboard_wait_is_text_available*(clipboard: PGtkClipboard): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_clipboard_wait_is_text_available".}
const
  GTK_CLIST_IN_DRAG* = 1 shl 0
  GTK_CLIST_ROW_HEIGHT_SET* = 1 shl 1
  GTK_CLIST_SHOW_TITLES* = 1 shl 2
  GTK_CLIST_ADD_MODE* = 1 shl 4
  GTK_CLIST_AUTO_SORT* = 1 shl 5
  GTK_CLIST_AUTO_RESIZE_BLOCKED* = 1 shl 6
  GTK_CLIST_REORDERABLE* = 1 shl 7
  GTK_CLIST_USE_DRAG_ICONS* = 1 shl 8
  GTK_CLIST_DRAW_DRAG_LINE* = 1 shl 9
  GTK_CLIST_DRAW_DRAG_RECT* = 1 shl 10
  GTK_BUTTON_IGNORED* = 0
  GTK_BUTTON_SELECTS* = 1 shl 0
  GTK_BUTTON_DRAGS* = 1 shl 1
  GTK_BUTTON_EXPANDS* = 1 shl 2

const
  bm_TGtkCListColumn_visible* = 0x00000001'i16
  bp_TGtkCListColumn_visible* = 0'i16
  bm_TGtkCListColumn_width_set* = 0x00000002'i16
  bp_TGtkCListColumn_width_set* = 1'i16
  bm_TGtkCListColumn_resizeable* = 0x00000004'i16
  bp_TGtkCListColumn_resizeable* = 2'i16
  bm_TGtkCListColumn_auto_resize* = 0x00000008'i16
  bp_TGtkCListColumn_auto_resize* = 3'i16
  bm_TGtkCListColumn_button_passive* = 0x00000010'i16
  bp_TGtkCListColumn_button_passive* = 4'i16
  bm_TGtkCListRow_fg_set* = 0x00000001'i16
  bp_TGtkCListRow_fg_set* = 0'i16
  bm_TGtkCListRow_bg_set* = 0x00000002'i16
  bp_TGtkCListRow_bg_set* = 1'i16
  bm_TGtkCListRow_selectable* = 0x00000004'i16
  bp_TGtkCListRow_selectable* = 2'i16

proc GTK_TYPE_CLIST*(): GType
proc GTK_CLIST*(obj: pointer): PGtkCList
proc GTK_CLIST_CLASS*(klass: pointer): PGtkCListClass
proc GTK_IS_CLIST*(obj: pointer): bool
proc GTK_IS_CLIST_CLASS*(klass: pointer): bool
proc GTK_CLIST_GET_CLASS*(obj: pointer): PGtkCListClass
proc GTK_CLIST_FLAGS*(clist: pointer): guint16
proc GTK_CLIST_SET_FLAG*(clist: PGtkCList, flag: guint16)
proc GTK_CLIST_UNSET_FLAG*(clist: PGtkCList, flag: guint16)
#proc GTK_CLIST_IN_DRAG_get*(clist: pointer): bool
#proc GTK_CLIST_ROW_HEIGHT_SET_get*(clist: pointer): bool
#proc GTK_CLIST_SHOW_TITLES_get*(clist: pointer): bool
#proc GTK_CLIST_ADD_MODE_get*(clist: pointer): bool
#proc GTK_CLIST_AUTO_SORT_get*(clist: pointer): bool
#proc GTK_CLIST_AUTO_RESIZE_BLOCKED_get*(clist: pointer): bool
#proc GTK_CLIST_REORDERABLE_get*(clist: pointer): bool
#proc GTK_CLIST_USE_DRAG_ICONS_get*(clist: pointer): bool
#proc GTK_CLIST_DRAW_DRAG_LINE_get*(clist: pointer): bool
#proc GTK_CLIST_DRAW_DRAG_RECT_get*(clist: pointer): bool
#proc GTK_CLIST_ROW_get*(glist: PGList): PGtkCListRow
#proc GTK_CELL_TEXT_get*(cell: pointer): PGtkCellText
#proc GTK_CELL_PIXMAP_get*(cell: pointer): PGtkCellPixmap
#proc GTK_CELL_PIXTEXT_get*(cell: pointer): PGtkCellPixText
#proc GTK_CELL_WIDGET_get*(cell: pointer): PGtkCellWidget
proc visible*(a: var TGtkCListColumn): guint
proc set_visible*(a: var TGtkCListColumn, `visible`: guint)
proc width_set*(a: var TGtkCListColumn): guint
proc set_width_set*(a: var TGtkCListColumn, `width_set`: guint)
proc resizeable*(a: var TGtkCListColumn): guint
proc set_resizeable*(a: var TGtkCListColumn, `resizeable`: guint)
proc auto_resize*(a: var TGtkCListColumn): guint
proc set_auto_resize*(a: var TGtkCListColumn, `auto_resize`: guint)
proc button_passive*(a: var TGtkCListColumn): guint
proc set_button_passive*(a: var TGtkCListColumn, `button_passive`: guint)
proc fg_set*(a: var TGtkCListRow): guint
proc set_fg_set*(a: var TGtkCListRow, `fg_set`: guint)
proc bg_set*(a: var TGtkCListRow): guint
proc set_bg_set*(a: var TGtkCListRow, `bg_set`: guint)
proc selectable*(a: var TGtkCListRow): guint
proc set_selectable*(a: var TGtkCListRow, `selectable`: guint)
proc gtk_clist_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_clist_get_type".}
proc gtk_clist_new*(columns: gint): PGtkCList {.cdecl, dynlib: gtklib,
    importc: "gtk_clist_new".}
proc gtk_clist_set_hadjustment*(clist: PGtkCList, adjustment: PGtkAdjustment){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_hadjustment".}
proc gtk_clist_set_vadjustment*(clist: PGtkCList, adjustment: PGtkAdjustment){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_vadjustment".}
proc gtk_clist_get_hadjustment*(clist: PGtkCList): PGtkAdjustment{.cdecl,
    dynlib: gtklib, importc: "gtk_clist_get_hadjustment".}
proc gtk_clist_get_vadjustment*(clist: PGtkCList): PGtkAdjustment{.cdecl,
    dynlib: gtklib, importc: "gtk_clist_get_vadjustment".}
proc gtk_clist_set_shadow_type*(clist: PGtkCList, thetype: TGtkShadowType){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_shadow_type".}
proc gtk_clist_set_selection_mode*(clist: PGtkCList, mode: TGtkSelectionMode){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_selection_mode".}
proc gtk_clist_set_reorderable*(clist: PGtkCList, reorderable: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_set_reorderable".}
proc gtk_clist_set_use_drag_icons*(clist: PGtkCList, use_icons: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_use_drag_icons".}
proc gtk_clist_set_button_actions*(clist: PGtkCList, button: guint,
                                   button_actions: guint8){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_set_button_actions".}
proc gtk_clist_freeze*(clist: PGtkCList){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_freeze".}
proc gtk_clist_thaw*(clist: PGtkCList){.cdecl, dynlib: gtklib,
                                        importc: "gtk_clist_thaw".}
proc gtk_clist_column_titles_show*(clist: PGtkCList){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_column_titles_show".}
proc gtk_clist_column_titles_hide*(clist: PGtkCList){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_column_titles_hide".}
proc gtk_clist_column_title_active*(clist: PGtkCList, column: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_column_title_active".}
proc gtk_clist_column_title_passive*(clist: PGtkCList, column: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_column_title_passive".}
proc gtk_clist_column_titles_active*(clist: PGtkCList){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_column_titles_active".}
proc gtk_clist_column_titles_passive*(clist: PGtkCList){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_column_titles_passive".}
proc gtk_clist_set_column_title*(clist: PGtkCList, column: gint, title: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_column_title".}
proc gtk_clist_get_column_title*(clist: PGtkCList, column: gint): cstring{.cdecl,
    dynlib: gtklib, importc: "gtk_clist_get_column_title".}
proc gtk_clist_set_column_widget*(clist: PGtkCList, column: gint,
                                  widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_set_column_widget".}
proc gtk_clist_get_column_widget*(clist: PGtkCList, column: gint): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_clist_get_column_widget".}
proc gtk_clist_set_column_justification*(clist: PGtkCList, column: gint,
    justification: TGtkJustification){.cdecl, dynlib: gtklib, importc: "gtk_clist_set_column_justification".}
proc gtk_clist_set_column_visibility*(clist: PGtkCList, column: gint,
                                      visible: gboolean){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_set_column_visibility".}
proc gtk_clist_set_column_resizeable*(clist: PGtkCList, column: gint,
                                      resizeable: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_set_column_resizeable".}
proc gtk_clist_set_column_auto_resize*(clist: PGtkCList, column: gint,
                                       auto_resize: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_set_column_auto_resize".}
proc gtk_clist_columns_autosize*(clist: PGtkCList): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_clist_columns_autosize".}
proc gtk_clist_optimal_column_width*(clist: PGtkCList, column: gint): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_clist_optimal_column_width".}
proc gtk_clist_set_column_width*(clist: PGtkCList, column: gint, width: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_column_width".}
proc gtk_clist_set_column_min_width*(clist: PGtkCList, column: gint,
                                     min_width: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_set_column_min_width".}
proc gtk_clist_set_column_max_width*(clist: PGtkCList, column: gint,
                                     max_width: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_set_column_max_width".}
proc gtk_clist_set_row_height*(clist: PGtkCList, height: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_set_row_height".}
proc gtk_clist_moveto*(clist: PGtkCList, row: gint, column: gint,
                       row_align: gfloat, col_align: gfloat){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_moveto".}
proc gtk_clist_row_is_visible*(clist: PGtkCList, row: gint): TGtkVisibility{.
    cdecl, dynlib: gtklib, importc: "gtk_clist_row_is_visible".}
proc gtk_clist_get_cell_type*(clist: PGtkCList, row: gint, column: gint): TGtkCellType{.
    cdecl, dynlib: gtklib, importc: "gtk_clist_get_cell_type".}
proc gtk_clist_set_text*(clist: PGtkCList, row: gint, column: gint, text: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_text".}
proc gtk_clist_get_text*(clist: PGtkCList, row: gint, column: gint,
                         text: PPgchar): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_clist_get_text".}
proc gtk_clist_set_pixmap*(clist: PGtkCList, row: gint, column: gint,
                           pixmap: PGdkPixmap, mask: PGdkBitmap){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_set_pixmap".}
proc gtk_clist_get_pixmap*(clist: PGtkCList, row: gint, column: gint,
                           pixmap: var PGdkPixmap, mask: var PGdkBitmap): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_clist_get_pixmap".}
proc gtk_clist_set_pixtext*(clist: PGtkCList, row: gint, column: gint,
                            text: cstring, spacing: guint8, pixmap: PGdkPixmap,
                            mask: PGdkBitmap){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_set_pixtext".}
proc gtk_clist_set_foreground*(clist: PGtkCList, row: gint, color: PGdkColor){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_foreground".}
proc gtk_clist_set_background*(clist: PGtkCList, row: gint, color: PGdkColor){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_background".}
proc gtk_clist_set_cell_style*(clist: PGtkCList, row: gint, column: gint,
                               style: PGtkStyle){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_set_cell_style".}
proc gtk_clist_get_cell_style*(clist: PGtkCList, row: gint, column: gint): PGtkStyle{.
    cdecl, dynlib: gtklib, importc: "gtk_clist_get_cell_style".}
proc gtk_clist_set_row_style*(clist: PGtkCList, row: gint, style: PGtkStyle){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_row_style".}
proc gtk_clist_get_row_style*(clist: PGtkCList, row: gint): PGtkStyle{.cdecl,
    dynlib: gtklib, importc: "gtk_clist_get_row_style".}
proc gtk_clist_set_shift*(clist: PGtkCList, row: gint, column: gint,
                          vertical: gint, horizontal: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_set_shift".}
proc gtk_clist_set_selectable*(clist: PGtkCList, row: gint, selectable: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_selectable".}
proc gtk_clist_get_selectable*(clist: PGtkCList, row: gint): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_clist_get_selectable".}
proc gtk_clist_remove*(clist: PGtkCList, row: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_remove".}
proc gtk_clist_set_row_data*(clist: PGtkCList, row: gint, data: gpointer){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_set_row_data".}
proc gtk_clist_set_row_data_full*(clist: PGtkCList, row: gint, data: gpointer,
                                  destroy: TGtkDestroyNotify){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_set_row_data_full".}
proc gtk_clist_get_row_data*(clist: PGtkCList, row: gint): gpointer{.cdecl,
    dynlib: gtklib, importc: "gtk_clist_get_row_data".}
proc gtk_clist_find_row_from_data*(clist: PGtkCList, data: gpointer): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_clist_find_row_from_data".}
proc gtk_clist_select_row*(clist: PGtkCList, row: gint, column: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_select_row".}
proc gtk_clist_unselect_row*(clist: PGtkCList, row: gint, column: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_unselect_row".}
proc gtk_clist_undo_selection*(clist: PGtkCList){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_undo_selection".}
proc gtk_clist_clear*(clist: PGtkCList){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_clear".}
proc gtk_clist_get_selection_info*(clist: PGtkCList, x: gint, y: gint,
                                   row: Pgint, column: Pgint): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_clist_get_selection_info".}
proc gtk_clist_select_all*(clist: PGtkCList){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_select_all".}
proc gtk_clist_unselect_all*(clist: PGtkCList){.cdecl, dynlib: gtklib,
    importc: "gtk_clist_unselect_all".}
proc gtk_clist_swap_rows*(clist: PGtkCList, row1: gint, row2: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_swap_rows".}
proc gtk_clist_row_move*(clist: PGtkCList, source_row: gint, dest_row: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_clist_row_move".}
proc gtk_clist_set_compare_func*(clist: PGtkCList,
                                 cmp_func: TGtkCListCompareFunc){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_set_compare_func".}
proc gtk_clist_set_sort_column*(clist: PGtkCList, column: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_set_sort_column".}
proc gtk_clist_set_sort_type*(clist: PGtkCList, sort_type: TGtkSortType){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_set_sort_type".}
proc gtk_clist_sort*(clist: PGtkCList){.cdecl, dynlib: gtklib,
                                        importc: "gtk_clist_sort".}
proc gtk_clist_set_auto_sort*(clist: PGtkCList, auto_sort: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_clist_set_auto_sort".}
proc gtk_clist_create_cell_layout*(clist: PGtkCList, clist_row: PGtkCListRow,
                                     column: gint): PPangoLayout{.cdecl,
    dynlib: gtklib, importc: "_gtk_clist_create_cell_layout".}
const
  GTK_DIALOG_MODAL* = 1 shl 0
  GTK_DIALOG_DESTROY_WITH_PARENT* = 1 shl 1
  GTK_DIALOG_NO_SEPARATOR* = 1 shl 2
  GTK_RESPONSE_NONE* = - (1)
  GTK_RESPONSE_REJECT* = - (2)
  GTK_RESPONSE_ACCEPT* = - (3)
  GTK_RESPONSE_DELETE_EVENT* = - (4)
  GTK_RESPONSE_OK* = - (5)
  GTK_RESPONSE_CANCEL* = - (6)
  GTK_RESPONSE_CLOSE* = - (7)
  GTK_RESPONSE_YES* = - (8)
  GTK_RESPONSE_NO* = - (9)
  GTK_RESPONSE_APPLY* = - (10)
  GTK_RESPONSE_HELP* = - (11)

proc GTK_TYPE_DIALOG*(): GType
proc GTK_DIALOG*(obj: pointer): PGtkDialog
proc GTK_DIALOG_CLASS*(klass: pointer): PGtkDialogClass
proc GTK_IS_DIALOG*(obj: pointer): bool
proc GTK_IS_DIALOG_CLASS*(klass: pointer): bool
proc GTK_DIALOG_GET_CLASS*(obj: pointer): PGtkDialogClass
proc gtk_dialog_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_dialog_get_type".}
proc gtk_dialog_new*(): PGtkDialog {.cdecl, dynlib: gtklib,
                                    importc: "gtk_dialog_new".}
proc gtk_dialog_add_action_widget*(dialog: PGtkDialog, child: PGtkWidget,
                                   response_id: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_dialog_add_action_widget".}
proc gtk_dialog_add_button*(dialog: PGtkDialog, button_text: cstring,
                            response_id: gint): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_dialog_add_button".}
proc gtk_dialog_set_response_sensitive*(dialog: PGtkDialog, response_id: gint,
                                        setting: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_dialog_set_response_sensitive".}
proc gtk_dialog_set_default_response*(dialog: PGtkDialog, response_id: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_dialog_set_default_response".}
proc gtk_dialog_set_has_separator*(dialog: PGtkDialog, setting: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_dialog_set_has_separator".}
proc gtk_dialog_get_has_separator*(dialog: PGtkDialog): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_dialog_get_has_separator".}
proc gtk_dialog_response*(dialog: PGtkDialog, response_id: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_dialog_response".}
proc gtk_dialog_run*(dialog: PGtkDialog): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_dialog_run".}
proc gtk_show_about_dialog*(parent: PGtkWindow, firstPropertyName: cstring) {.
    cdecl, dynlib: gtklib, importc: "gtk_show_about_dialog", varargs.}
    
proc GTK_TYPE_VBOX*(): GType
proc GTK_VBOX*(obj: pointer): PGtkVBox
proc GTK_VBOX_CLASS*(klass: pointer): PGtkVBoxClass
proc GTK_IS_VBOX*(obj: pointer): bool
proc GTK_IS_VBOX_CLASS*(klass: pointer): bool
proc GTK_VBOX_GET_CLASS*(obj: pointer): PGtkVBoxClass
proc gtk_vbox_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                     importc: "gtk_vbox_get_type".}
proc gtk_vbox_new*(homogeneous: gboolean, spacing: gint): PGtkVBox {.cdecl,
    dynlib: gtklib, importc: "gtk_vbox_new".}
proc GTK_TYPE_COLOR_SELECTION*(): GType
proc GTK_COLOR_SELECTION*(obj: pointer): PGtkColorSelection
proc GTK_COLOR_SELECTION_CLASS*(klass: pointer): PGtkColorSelectionClass
proc GTK_IS_COLOR_SELECTION*(obj: pointer): bool
proc GTK_IS_COLOR_SELECTION_CLASS*(klass: pointer): bool
proc GTK_COLOR_SELECTION_GET_CLASS*(obj: pointer): PGtkColorSelectionClass
proc gtk_color_selection_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_color_selection_get_type".}
proc gtk_color_selection_new*(): PGtkColorSelection {.cdecl, dynlib: gtklib,
    importc: "gtk_color_selection_new".}
proc gtk_color_selection_get_has_opacity_control*(colorsel: PGtkColorSelection): gboolean{.
    cdecl, dynlib: gtklib,
    importc: "gtk_color_selection_get_has_opacity_control".}
proc gtk_color_selection_set_has_opacity_control*(colorsel: PGtkColorSelection,
    has_opacity: gboolean){.cdecl, dynlib: gtklib, importc: "gtk_color_selection_set_has_opacity_control".}
proc gtk_color_selection_get_has_palette*(colorsel: PGtkColorSelection): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_color_selection_get_has_palette".}
proc gtk_color_selection_set_has_palette*(colorsel: PGtkColorSelection,
    has_palette: gboolean){.cdecl, dynlib: gtklib,
                            importc: "gtk_color_selection_set_has_palette".}
proc gtk_color_selection_set_current_color*(colorsel: PGtkColorSelection,
    color: PGdkColor){.cdecl, dynlib: gtklib,
                       importc: "gtk_color_selection_set_current_color".}
proc gtk_color_selection_set_current_alpha*(colorsel: PGtkColorSelection,
    alpha: guint16){.cdecl, dynlib: gtklib,
                     importc: "gtk_color_selection_set_current_alpha".}
proc gtk_color_selection_get_current_color*(colorsel: PGtkColorSelection,
    color: PGdkColor){.cdecl, dynlib: gtklib,
                       importc: "gtk_color_selection_get_current_color".}
proc gtk_color_selection_get_current_alpha*(colorsel: PGtkColorSelection): guint16{.
    cdecl, dynlib: gtklib, importc: "gtk_color_selection_get_current_alpha".}
proc gtk_color_selection_set_previous_color*(colorsel: PGtkColorSelection,
    color: PGdkColor){.cdecl, dynlib: gtklib,
                       importc: "gtk_color_selection_set_previous_color".}
proc gtk_color_selection_set_previous_alpha*(colorsel: PGtkColorSelection,
    alpha: guint16){.cdecl, dynlib: gtklib,
                     importc: "gtk_color_selection_set_previous_alpha".}
proc gtk_color_selection_get_previous_color*(colorsel: PGtkColorSelection,
    color: PGdkColor){.cdecl, dynlib: gtklib,
                       importc: "gtk_color_selection_get_previous_color".}
proc gtk_color_selection_get_previous_alpha*(colorsel: PGtkColorSelection): guint16{.
    cdecl, dynlib: gtklib, importc: "gtk_color_selection_get_previous_alpha".}
proc gtk_color_selection_is_adjusting*(colorsel: PGtkColorSelection): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_color_selection_is_adjusting".}
proc gtk_color_selection_palette_from_string*(str: cstring,
    colors: var PGdkColor, n_colors: Pgint): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_color_selection_palette_from_string".}
proc gtk_color_selection_palette_to_string*(colors: PGdkColor, n_colors: gint): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_color_selection_palette_to_string".}
proc gtk_color_selection_set_change_palette_with_screen_hook*(
    func: TGtkColorSelectionChangePaletteWithScreenFunc): TGtkColorSelectionChangePaletteWithScreenFunc{.
    cdecl, dynlib: gtklib,
    importc: "gtk_color_selection_set_change_palette_with_screen_hook".}
proc GTK_TYPE_COLOR_SELECTION_DIALOG*(): GType
proc GTK_COLOR_SELECTION_DIALOG*(obj: pointer): PGtkColorSelectionDialog
proc GTK_COLOR_SELECTION_DIALOG_CLASS*(klass: pointer): PGtkColorSelectionDialogClass
proc GTK_IS_COLOR_SELECTION_DIALOG*(obj: pointer): bool
proc GTK_IS_COLOR_SELECTION_DIALOG_CLASS*(klass: pointer): bool
proc GTK_COLOR_SELECTION_DIALOG_GET_CLASS*(obj: pointer): PGtkColorSelectionDialogClass
proc gtk_color_selection_dialog_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_color_selection_dialog_get_type".}
proc gtk_color_selection_dialog_new*(title: cstring): PGtkColorSelectionDialog {.cdecl,
    dynlib: gtklib, importc: "gtk_color_selection_dialog_new".}
proc GTK_TYPE_HBOX*(): GType
proc GTK_HBOX*(obj: pointer): PGtkHBox
proc GTK_HBOX_CLASS*(klass: pointer): PGtkHBoxClass
proc GTK_IS_HBOX*(obj: pointer): bool
proc GTK_IS_HBOX_CLASS*(klass: pointer): bool
proc GTK_HBOX_GET_CLASS*(obj: pointer): PGtkHBoxClass
proc gtk_hbox_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                     importc: "gtk_hbox_get_type".}
proc gtk_hbox_new*(homogeneous: gboolean, spacing: gint): PGtkHBox {.cdecl,
    dynlib: gtklib, importc: "gtk_hbox_new".}
const
  bm_TGtkCombo_value_in_list* = 0x00000001'i16
  bp_TGtkCombo_value_in_list* = 0'i16
  bm_TGtkCombo_ok_if_empty* = 0x00000002'i16
  bp_TGtkCombo_ok_if_empty* = 1'i16
  bm_TGtkCombo_case_sensitive* = 0x00000004'i16
  bp_TGtkCombo_case_sensitive* = 2'i16
  bm_TGtkCombo_use_arrows* = 0x00000008'i16
  bp_TGtkCombo_use_arrows* = 3'i16
  bm_TGtkCombo_use_arrows_always* = 0x00000010'i16
  bp_TGtkCombo_use_arrows_always* = 4'i16

proc GTK_TYPE_COMBO*(): GType
proc GTK_COMBO*(obj: pointer): PGtkCombo
proc GTK_COMBO_CLASS*(klass: pointer): PGtkComboClass
proc GTK_IS_COMBO*(obj: pointer): bool
proc GTK_IS_COMBO_CLASS*(klass: pointer): bool
proc GTK_COMBO_GET_CLASS*(obj: pointer): PGtkComboClass
proc value_in_list*(a: var TGtkCombo): guint
proc set_value_in_list*(a: var TGtkCombo, `value_in_list`: guint)
proc ok_if_empty*(a: var TGtkCombo): guint
proc set_ok_if_empty*(a: var TGtkCombo, `ok_if_empty`: guint)
proc case_sensitive*(a: var TGtkCombo): guint
proc set_case_sensitive*(a: var TGtkCombo, `case_sensitive`: guint)
proc use_arrows*(a: var TGtkCombo): guint
proc set_use_arrows*(a: var TGtkCombo, `use_arrows`: guint)
proc use_arrows_always*(a: var TGtkCombo): guint
proc set_use_arrows_always*(a: var TGtkCombo, `use_arrows_always`: guint)
proc gtk_combo_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_combo_get_type".}
proc gtk_combo_new*(): PGtkCombo {.cdecl, dynlib: gtklib,
                                   importc: "gtk_combo_new".}
proc gtk_combo_set_value_in_list*(combo: PGtkCombo, val: gboolean,
                                  ok_if_empty: gboolean){.cdecl, dynlib: gtklib,
    importc: "gtk_combo_set_value_in_list".}
proc gtk_combo_set_use_arrows*(combo: PGtkCombo, val: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_combo_set_use_arrows".}
proc gtk_combo_set_use_arrows_always*(combo: PGtkCombo, val: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_combo_set_use_arrows_always".}
proc gtk_combo_set_case_sensitive*(combo: PGtkCombo, val: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_combo_set_case_sensitive".}
proc gtk_combo_set_item_string*(combo: PGtkCombo, item: PGtkItem,
                                item_value: cstring){.cdecl, dynlib: gtklib,
    importc: "gtk_combo_set_item_string".}
proc gtk_combo_set_popdown_strings*(combo: PGtkCombo, strings: PGList){.cdecl,
    dynlib: gtklib, importc: "gtk_combo_set_popdown_strings".}
proc gtk_combo_disable_activate*(combo: PGtkCombo){.cdecl, dynlib: gtklib,
    importc: "gtk_combo_disable_activate".}
const
  bm_TGtkCTree_line_style* = 0x00000003'i16
  bp_TGtkCTree_line_style* = 0'i16
  bm_TGtkCTree_expander_style* = 0x0000000C'i16
  bp_TGtkCTree_expander_style* = 2'i16
  bm_TGtkCTree_show_stub* = 0x00000010'i16
  bp_TGtkCTree_show_stub* = 4'i16
  bm_TGtkCTreeRow_is_leaf* = 0x00000001'i16
  bp_TGtkCTreeRow_is_leaf* = 0'i16
  bm_TGtkCTreeRow_expanded* = 0x00000002'i16
  bp_TGtkCTreeRow_expanded* = 1'i16

proc GTK_TYPE_CTREE*(): GType
proc GTK_CTREE*(obj: pointer): PGtkCTree
proc GTK_CTREE_CLASS*(klass: pointer): PGtkCTreeClass
proc GTK_IS_CTREE*(obj: pointer): bool
proc GTK_IS_CTREE_CLASS*(klass: pointer): bool
proc GTK_CTREE_GET_CLASS*(obj: pointer): PGtkCTreeClass
proc GTK_CTREE_ROW*(`node`: TAddress): PGtkCTreeRow
proc GTK_CTREE_NODE*(`node`: TAddress): PGtkCTreeNode
proc GTK_CTREE_NODE_NEXT*(`nnode`: TAddress): PGtkCTreeNode
proc GTK_CTREE_NODE_PREV*(`pnode`: TAddress): PGtkCTreeNode
proc GTK_CTREE_FUNC*(`func`: TAddress): TGtkCTreeFunc
proc GTK_TYPE_CTREE_NODE*(): GType
proc line_style*(a: var TGtkCTree): guint
proc set_line_style*(a: var TGtkCTree, `line_style`: guint)
proc expander_style*(a: var TGtkCTree): guint
proc set_expander_style*(a: var TGtkCTree, `expander_style`: guint)
proc show_stub*(a: var TGtkCTree): guint
proc set_show_stub*(a: var TGtkCTree, `show_stub`: guint)
proc is_leaf*(a: var TGtkCTreeRow): guint
proc set_is_leaf*(a: var TGtkCTreeRow, `is_leaf`: guint)
proc expanded*(a: var TGtkCTreeRow): guint
proc set_expanded*(a: var TGtkCTreeRow, `expanded`: guint)
proc gtk_ctree_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_ctree_get_type".}
proc gtk_ctree_new*(columns: gint, tree_column: gint): PGtkCTree {.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_new".}
proc gtk_ctree_insert_node*(ctree: PGtkCTree, parent: PGtkCTreeNode,
                            sibling: PGtkCTreeNode, text: openarray[cstring],
                            spacing: guint8, pixmap_closed: PGdkPixmap,
                            mask_closed: PGdkBitmap, pixmap_opened: PGdkPixmap,
                            mask_opened: PGdkBitmap, is_leaf: gboolean,
                            expanded: gboolean): PGtkCTreeNode{.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_insert_node".}
proc gtk_ctree_remove_node*(ctree: PGtkCTree, node: PGtkCTreeNode){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_remove_node".}
proc gtk_ctree_insert_gnode*(ctree: PGtkCTree, parent: PGtkCTreeNode,
                             sibling: PGtkCTreeNode, gnode: PGNode,
                             fun: TGtkCTreeGNodeFunc, data: gpointer): PGtkCTreeNode{.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_insert_gnode".}
proc gtk_ctree_export_to_gnode*(ctree: PGtkCTree, parent: PGNode,
                                sibling: PGNode, node: PGtkCTreeNode,
                                fun: TGtkCTreeGNodeFunc, data: gpointer): PGNode{.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_export_to_gnode".}
proc gtk_ctree_post_recursive*(ctree: PGtkCTree, node: PGtkCTreeNode,
                               fun: TGtkCTreeFunc, data: gpointer){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_post_recursive".}
proc gtk_ctree_post_recursive_to_depth*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                        depth: gint, fun: TGtkCTreeFunc,
                                        data: gpointer){.cdecl, dynlib: gtklib,
    importc: "gtk_ctree_post_recursive_to_depth".}
proc gtk_ctree_pre_recursive*(ctree: PGtkCTree, node: PGtkCTreeNode,
                              fun: TGtkCTreeFunc, data: gpointer){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_pre_recursive".}
proc gtk_ctree_pre_recursive_to_depth*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                       depth: gint, fun: TGtkCTreeFunc,
                                       data: gpointer){.cdecl, dynlib: gtklib,
    importc: "gtk_ctree_pre_recursive_to_depth".}
proc gtk_ctree_is_viewable*(ctree: PGtkCTree, node: PGtkCTreeNode): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_is_viewable".}
proc gtk_ctree_last*(ctree: PGtkCTree, node: PGtkCTreeNode): PGtkCTreeNode{.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_last".}
proc gtk_ctree_find_node_ptr*(ctree: PGtkCTree, ctree_row: PGtkCTreeRow): PGtkCTreeNode{.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_find_node_ptr".}
proc gtk_ctree_node_nth*(ctree: PGtkCTree, row: guint): PGtkCTreeNode{.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_node_nth".}
proc gtk_ctree_find*(ctree: PGtkCTree, node: PGtkCTreeNode,
                     child: PGtkCTreeNode): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_ctree_find".}
proc gtk_ctree_is_ancestor*(ctree: PGtkCTree, node: PGtkCTreeNode,
                            child: PGtkCTreeNode): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_is_ancestor".}
proc gtk_ctree_find_by_row_data*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                 data: gpointer): PGtkCTreeNode{.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_find_by_row_data".}
proc gtk_ctree_find_all_by_row_data*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                     data: gpointer): PGList{.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_find_all_by_row_data".}
proc gtk_ctree_find_by_row_data_custom*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                        data: gpointer, fun: TGCompareFunc): PGtkCTreeNode{.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_find_by_row_data_custom".}
proc gtk_ctree_find_all_by_row_data_custom*(ctree: PGtkCTree,
    node: PGtkCTreeNode, data: gpointer, fun: TGCompareFunc): PGList{.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_find_all_by_row_data_custom".}
proc gtk_ctree_is_hot_spot*(ctree: PGtkCTree, x: gint, y: gint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_is_hot_spot".}
proc gtk_ctree_move*(ctree: PGtkCTree, node: PGtkCTreeNode,
                     new_parent: PGtkCTreeNode, new_sibling: PGtkCTreeNode){.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_move".}
proc gtk_ctree_expand*(ctree: PGtkCTree, node: PGtkCTreeNode){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_expand".}
proc gtk_ctree_expand_recursive*(ctree: PGtkCTree, node: PGtkCTreeNode){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_expand_recursive".}
proc gtk_ctree_expand_to_depth*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                depth: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_ctree_expand_to_depth".}
proc gtk_ctree_collapse*(ctree: PGtkCTree, node: PGtkCTreeNode){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_collapse".}
proc gtk_ctree_collapse_recursive*(ctree: PGtkCTree, node: PGtkCTreeNode){.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_collapse_recursive".}
proc gtk_ctree_collapse_to_depth*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                  depth: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_ctree_collapse_to_depth".}
proc gtk_ctree_toggle_expansion*(ctree: PGtkCTree, node: PGtkCTreeNode){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_toggle_expansion".}
proc gtk_ctree_toggle_expansion_recursive*(ctree: PGtkCTree,
    node: PGtkCTreeNode){.cdecl, dynlib: gtklib,
                           importc: "gtk_ctree_toggle_expansion_recursive".}
proc gtk_ctree_select*(ctree: PGtkCTree, node: PGtkCTreeNode){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_select".}
proc gtk_ctree_select_recursive*(ctree: PGtkCTree, node: PGtkCTreeNode){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_select_recursive".}
proc gtk_ctree_unselect*(ctree: PGtkCTree, node: PGtkCTreeNode){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_unselect".}
proc gtk_ctree_unselect_recursive*(ctree: PGtkCTree, node: PGtkCTreeNode){.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_unselect_recursive".}
proc gtk_ctree_real_select_recursive*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                      state: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_ctree_real_select_recursive".}
proc gtk_ctree_node_set_text*(ctree: PGtkCTree, node: PGtkCTreeNode,
                              column: gint, text: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_node_set_text".}
proc gtk_ctree_node_set_pixmap*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                column: gint, pixmap: PGdkPixmap,
                                mask: PGdkBitmap){.cdecl, dynlib: gtklib,
    importc: "gtk_ctree_node_set_pixmap".}
proc gtk_ctree_node_set_pixtext*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                 column: gint, text: cstring, spacing: guint8,
                                 pixmap: PGdkPixmap, mask: PGdkBitmap){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_node_set_pixtext".}
proc gtk_ctree_set_node_info*(ctree: PGtkCTree, node: PGtkCTreeNode,
                              text: cstring, spacing: guint8,
                              pixmap_closed: PGdkPixmap,
                              mask_closed: PGdkBitmap,
                              pixmap_opened: PGdkPixmap,
                              mask_opened: PGdkBitmap, is_leaf: gboolean,
                              expanded: gboolean){.cdecl, dynlib: gtklib,
    importc: "gtk_ctree_set_node_info".}
proc gtk_ctree_node_set_shift*(ctree: PGtkCTree, node: PGtkCTreeNode,
                               column: gint, vertical: gint, horizontal: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_node_set_shift".}
proc gtk_ctree_node_set_selectable*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                    selectable: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_node_set_selectable".}
proc gtk_ctree_node_get_selectable*(ctree: PGtkCTree, node: PGtkCTreeNode): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_node_get_selectable".}
proc gtk_ctree_node_get_cell_type*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                   column: gint): TGtkCellType{.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_node_get_cell_type".}
proc gtk_ctree_node_get_text*(ctree: PGtkCTree, node: PGtkCTreeNode,
                              column: gint, text: PPgchar): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_node_get_text".}
proc gtk_ctree_node_set_row_style*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                   style: PGtkStyle){.cdecl, dynlib: gtklib,
    importc: "gtk_ctree_node_set_row_style".}
proc gtk_ctree_node_get_row_style*(ctree: PGtkCTree, node: PGtkCTreeNode): PGtkStyle{.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_node_get_row_style".}
proc gtk_ctree_node_set_cell_style*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                    column: gint, style: PGtkStyle){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_node_set_cell_style".}
proc gtk_ctree_node_get_cell_style*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                    column: gint): PGtkStyle{.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_node_get_cell_style".}
proc gtk_ctree_node_set_foreground*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                    color: PGdkColor){.cdecl, dynlib: gtklib,
    importc: "gtk_ctree_node_set_foreground".}
proc gtk_ctree_node_set_background*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                    color: PGdkColor){.cdecl, dynlib: gtklib,
    importc: "gtk_ctree_node_set_background".}
proc gtk_ctree_node_set_row_data*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                  data: gpointer){.cdecl, dynlib: gtklib,
    importc: "gtk_ctree_node_set_row_data".}
proc gtk_ctree_node_set_row_data_full*(ctree: PGtkCTree, node: PGtkCTreeNode,
                                       data: gpointer,
                                       destroy: TGtkDestroyNotify){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_node_set_row_data_full".}
proc gtk_ctree_node_get_row_data*(ctree: PGtkCTree, node: PGtkCTreeNode): gpointer{.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_node_get_row_data".}
proc gtk_ctree_node_moveto*(ctree: PGtkCTree, node: PGtkCTreeNode,
                            column: gint, row_align: gfloat, col_align: gfloat){.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_node_moveto".}
proc gtk_ctree_node_is_visible*(ctree: PGtkCTree, node: PGtkCTreeNode): TGtkVisibility{.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_node_is_visible".}
proc gtk_ctree_set_indent*(ctree: PGtkCTree, indent: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_set_indent".}
proc gtk_ctree_set_spacing*(ctree: PGtkCTree, spacing: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_set_spacing".}
proc gtk_ctree_set_show_stub*(ctree: PGtkCTree, show_stub: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_set_show_stub".}
proc gtk_ctree_set_line_style*(ctree: PGtkCTree, line_style: TGtkCTreeLineStyle){.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_set_line_style".}
proc gtk_ctree_set_expander_style*(ctree: PGtkCTree,
                                   expander_style: TGtkCTreeExpanderStyle){.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_set_expander_style".}
proc gtk_ctree_set_drag_compare_func*(ctree: PGtkCTree,
                                      cmp_func: TGtkCTreeCompareDragFunc){.
    cdecl, dynlib: gtklib, importc: "gtk_ctree_set_drag_compare_func".}
proc gtk_ctree_sort_node*(ctree: PGtkCTree, node: PGtkCTreeNode){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_sort_node".}
proc gtk_ctree_sort_recursive*(ctree: PGtkCTree, node: PGtkCTreeNode){.cdecl,
    dynlib: gtklib, importc: "gtk_ctree_sort_recursive".}
proc gtk_ctree_set_reorderable*(t: pointer, r: bool)
proc gtk_ctree_node_get_type*(): GType{.cdecl, dynlib: gtklib,
                                        importc: "gtk_ctree_node_get_type".}
proc GTK_TYPE_DRAWING_AREA*(): GType
proc GTK_DRAWING_AREA*(obj: pointer): PGtkDrawingArea
proc GTK_DRAWING_AREA_CLASS*(klass: pointer): PGtkDrawingAreaClass
proc GTK_IS_DRAWING_AREA*(obj: pointer): bool
proc GTK_IS_DRAWING_AREA_CLASS*(klass: pointer): bool
proc GTK_DRAWING_AREA_GET_CLASS*(obj: pointer): PGtkDrawingAreaClass
proc gtk_drawing_area_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_drawing_area_get_type".}
proc gtk_drawing_area_new*(): PGtkDrawingArea {.cdecl, dynlib: gtklib,
    importc: "gtk_drawing_area_new".}
proc GTK_TYPE_CURVE*(): GType
proc GTK_CURVE*(obj: pointer): PGtkCurve
proc GTK_CURVE_CLASS*(klass: pointer): PGtkCurveClass
proc GTK_IS_CURVE*(obj: pointer): bool
proc GTK_IS_CURVE_CLASS*(klass: pointer): bool
proc GTK_CURVE_GET_CLASS*(obj: pointer): PGtkCurveClass
proc gtk_curve_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_curve_get_type".}
proc gtk_curve_new*(): PGtkCurve {.cdecl, dynlib: gtklib,
                                   importc: "gtk_curve_new".}
proc gtk_curve_reset*(curve: PGtkCurve){.cdecl, dynlib: gtklib,
    importc: "gtk_curve_reset".}
proc gtk_curve_set_gamma*(curve: PGtkCurve, gamma: gfloat){.cdecl,
    dynlib: gtklib, importc: "gtk_curve_set_gamma".}
proc gtk_curve_set_range*(curve: PGtkCurve, min_x: gfloat, max_x: gfloat,
                          min_y: gfloat, max_y: gfloat){.cdecl, dynlib: gtklib,
    importc: "gtk_curve_set_range".}
proc gtk_curve_set_curve_type*(curve: PGtkCurve, thetype: TGtkCurveType){.cdecl,
    dynlib: gtklib, importc: "gtk_curve_set_curve_type".}
const
  GTK_DEST_DEFAULT_MOTION* = 1 shl 0
  GTK_DEST_DEFAULT_HIGHLIGHT* = 1 shl 1
  GTK_DEST_DEFAULT_DROP* = 1 shl 2
  GTK_DEST_DEFAULT_ALL* = 0x00000007
  GTK_TARGET_SAME_APP* = 1 shl 0
  GTK_TARGET_SAME_WIDGET* = 1 shl 1

proc gtk_drag_get_data*(widget: PGtkWidget, context: PGdkDragContext,
                        target: TGdkAtom, time: guint32){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_get_data".}
proc gtk_drag_finish*(context: PGdkDragContext, success: gboolean,
                      del: gboolean, time: guint32){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_finish".}
proc gtk_drag_get_source_widget*(context: PGdkDragContext): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_drag_get_source_widget".}
proc gtk_drag_highlight*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_highlight".}
proc gtk_drag_unhighlight*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_unhighlight".}
proc gtk_drag_dest_set*(widget: PGtkWidget, flags: TGtkDestDefaults,
                        targets: PGtkTargetEntry, n_targets: gint,
                        actions: TGdkDragAction){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_dest_set".}
proc gtk_drag_dest_set_proxy*(widget: PGtkWidget, proxy_window: PGdkWindow,
                              protocol: TGdkDragProtocol,
                              use_coordinates: gboolean){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_dest_set_proxy".}
proc gtk_drag_dest_unset*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_dest_unset".}
proc gtk_drag_dest_find_target*(widget: PGtkWidget, context: PGdkDragContext,
                                target_list: PGtkTargetList): TGdkAtom{.cdecl,
    dynlib: gtklib, importc: "gtk_drag_dest_find_target".}
proc gtk_drag_dest_get_target_list*(widget: PGtkWidget): PGtkTargetList{.cdecl,
    dynlib: gtklib, importc: "gtk_drag_dest_get_target_list".}
proc gtk_drag_dest_set_target_list*(widget: PGtkWidget,
                                    target_list: PGtkTargetList){.cdecl,
    dynlib: gtklib, importc: "gtk_drag_dest_set_target_list".}
proc gtk_drag_source_set*(widget: PGtkWidget,
                          start_button_mask: TGdkModifierType,
                          targets: PGtkTargetEntry, n_targets: gint,
                          actions: TGdkDragAction){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_source_set".}
proc gtk_drag_source_unset*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_source_unset".}
proc gtk_drag_source_set_icon*(widget: PGtkWidget, colormap: PGdkColormap,
                               pixmap: PGdkPixmap, mask: PGdkBitmap){.cdecl,
    dynlib: gtklib, importc: "gtk_drag_source_set_icon".}
proc gtk_drag_source_set_icon_pixbuf*(widget: PGtkWidget, pixbuf: PGdkPixbuf){.
    cdecl, dynlib: gtklib, importc: "gtk_drag_source_set_icon_pixbuf".}
proc gtk_drag_source_set_icon_stock*(widget: PGtkWidget, stock_id: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_drag_source_set_icon_stock".}
proc gtk_drag_begin*(widget: PGtkWidget, targets: PGtkTargetList,
                     actions: TGdkDragAction, button: gint, event: PGdkEvent): PGdkDragContext{.
    cdecl, dynlib: gtklib, importc: "gtk_drag_begin".}
proc gtk_drag_set_icon_widget*(context: PGdkDragContext, widget: PGtkWidget,
                               hot_x: gint, hot_y: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_set_icon_widget".}
proc gtk_drag_set_icon_pixmap*(context: PGdkDragContext, colormap: PGdkColormap,
                               pixmap: PGdkPixmap, mask: PGdkBitmap,
                               hot_x: gint, hot_y: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_set_icon_pixmap".}
proc gtk_drag_set_icon_pixbuf*(context: PGdkDragContext, pixbuf: PGdkPixbuf,
                               hot_x: gint, hot_y: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_set_icon_pixbuf".}
proc gtk_drag_set_icon_stock*(context: PGdkDragContext, stock_id: cstring,
                              hot_x: gint, hot_y: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_drag_set_icon_stock".}
proc gtk_drag_set_icon_default*(context: PGdkDragContext){.cdecl,
    dynlib: gtklib, importc: "gtk_drag_set_icon_default".}
proc gtk_drag_check_threshold*(widget: PGtkWidget, start_x: gint, start_y: gint,
                               current_x: gint, current_y: gint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_drag_check_threshold".}
proc gtk_drag_source_handle_event*(widget: PGtkWidget, event: PGdkEvent){.
    cdecl, dynlib: gtklib, importc: "_gtk_drag_source_handle_event".}
proc gtk_drag_dest_handle_event*(toplevel: PGtkWidget, event: PGdkEvent){.
    cdecl, dynlib: gtklib, importc: "_gtk_drag_dest_handle_event".}
proc GTK_TYPE_EDITABLE*(): GType
proc GTK_EDITABLE*(obj: pointer): PGtkEditable
proc GTK_EDITABLE_CLASS*(vtable: pointer): PGtkEditableClass
proc GTK_IS_EDITABLE*(obj: pointer): bool
proc GTK_IS_EDITABLE_CLASS*(vtable: pointer): bool
proc GTK_EDITABLE_GET_CLASS*(inst: pointer): PGtkEditableClass
proc gtk_editable_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_editable_get_type".}
proc gtk_editable_select_region*(editable: PGtkEditable, start: gint,
                                 theEnd: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_editable_select_region".}
proc gtk_editable_get_selection_bounds*(editable: PGtkEditable, start: Pgint,
                                        theEnd: Pgint): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_editable_get_selection_bounds".}
proc gtk_editable_insert_text*(editable: PGtkEditable, new_text: cstring,
                               new_text_length: gint, position: Pgint){.cdecl,
    dynlib: gtklib, importc: "gtk_editable_insert_text".}
proc gtk_editable_delete_text*(editable: PGtkEditable, start_pos: gint,
                               end_pos: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_editable_delete_text".}
proc gtk_editable_get_chars*(editable: PGtkEditable, start_pos: gint,
                             end_pos: gint): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_editable_get_chars".}
proc gtk_editable_cut_clipboard*(editable: PGtkEditable){.cdecl, dynlib: gtklib,
    importc: "gtk_editable_cut_clipboard".}
proc gtk_editable_copy_clipboard*(editable: PGtkEditable){.cdecl,
    dynlib: gtklib, importc: "gtk_editable_copy_clipboard".}
proc gtk_editable_paste_clipboard*(editable: PGtkEditable){.cdecl,
    dynlib: gtklib, importc: "gtk_editable_paste_clipboard".}
proc gtk_editable_delete_selection*(editable: PGtkEditable){.cdecl,
    dynlib: gtklib, importc: "gtk_editable_delete_selection".}
proc gtk_editable_set_position*(editable: PGtkEditable, position: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_editable_set_position".}
proc gtk_editable_get_position*(editable: PGtkEditable): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_editable_get_position".}
proc gtk_editable_set_editable*(editable: PGtkEditable, is_editable: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_editable_set_editable".}
proc gtk_editable_get_editable*(editable: PGtkEditable): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_editable_get_editable".}
proc GTK_TYPE_IM_CONTEXT*(): GType
proc GTK_IM_CONTEXT*(obj: pointer): PGtkIMContext
proc GTK_IM_CONTEXT_CLASS*(klass: pointer): PGtkIMContextClass
proc GTK_IS_IM_CONTEXT*(obj: pointer): bool
proc GTK_IS_IM_CONTEXT_CLASS*(klass: pointer): bool
proc GTK_IM_CONTEXT_GET_CLASS*(obj: pointer): PGtkIMContextClass
proc gtk_im_context_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_im_context_get_type".}
proc gtk_im_context_set_client_window*(context: PGtkIMContext,
                                       window: PGdkWindow){.cdecl,
    dynlib: gtklib, importc: "gtk_im_context_set_client_window".}
proc gtk_im_context_filter_keypress*(context: PGtkIMContext, event: PGdkEventKey): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_im_context_filter_keypress".}
proc gtk_im_context_focus_in*(context: PGtkIMContext){.cdecl, dynlib: gtklib,
    importc: "gtk_im_context_focus_in".}
proc gtk_im_context_focus_out*(context: PGtkIMContext){.cdecl, dynlib: gtklib,
    importc: "gtk_im_context_focus_out".}
proc gtk_im_context_reset*(context: PGtkIMContext){.cdecl, dynlib: gtklib,
    importc: "gtk_im_context_reset".}
proc gtk_im_context_set_cursor_location*(context: PGtkIMContext,
    area: PGdkRectangle){.cdecl, dynlib: gtklib,
                          importc: "gtk_im_context_set_cursor_location".}
proc gtk_im_context_set_use_preedit*(context: PGtkIMContext,
                                     use_preedit: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_im_context_set_use_preedit".}
proc gtk_im_context_set_surrounding*(context: PGtkIMContext, text: cstring,
                                     len: gint, cursor_index: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_im_context_set_surrounding".}
proc gtk_im_context_get_surrounding*(context: PGtkIMContext, text: PPgchar,
                                     cursor_index: Pgint): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_im_context_get_surrounding".}
proc gtk_im_context_delete_surrounding*(context: PGtkIMContext, offset: gint,
                                        n_chars: gint): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_im_context_delete_surrounding".}
const
  bm_TGtkMenuShell_active* = 0x00000001'i16
  bp_TGtkMenuShell_active* = 0'i16
  bm_TGtkMenuShell_have_grab* = 0x00000002'i16
  bp_TGtkMenuShell_have_grab* = 1'i16
  bm_TGtkMenuShell_have_xgrab* = 0x00000004'i16
  bp_TGtkMenuShell_have_xgrab* = 2'i16
  bm_TGtkMenuShell_ignore_leave* = 0x00000008'i16
  bp_TGtkMenuShell_ignore_leave* = 3'i16
  bm_TGtkMenuShell_menu_flag* = 0x00000010'i16
  bp_TGtkMenuShell_menu_flag* = 4'i16
  bm_TGtkMenuShell_ignore_enter* = 0x00000020'i16
  bp_TGtkMenuShell_ignore_enter* = 5'i16
  bm_TGtkMenuShellClass_submenu_placement* = 0x00000001'i16
  bp_TGtkMenuShellClass_submenu_placement* = 0'i16

proc GTK_TYPE_MENU_SHELL*(): GType
proc GTK_MENU_SHELL*(obj: pointer): PGtkMenuShell
proc GTK_MENU_SHELL_CLASS*(klass: pointer): PGtkMenuShellClass
proc GTK_IS_MENU_SHELL*(obj: pointer): bool
proc GTK_IS_MENU_SHELL_CLASS*(klass: pointer): bool
proc GTK_MENU_SHELL_GET_CLASS*(obj: pointer): PGtkMenuShellClass
proc active*(a: var TGtkMenuShell): guint
proc set_active*(a: var TGtkMenuShell, `active`: guint)
proc have_grab*(a: var TGtkMenuShell): guint
proc set_have_grab*(a: var TGtkMenuShell, `have_grab`: guint)
proc have_xgrab*(a: var TGtkMenuShell): guint
proc set_have_xgrab*(a: var TGtkMenuShell, `have_xgrab`: guint)
proc ignore_leave*(a: var TGtkMenuShell): guint
proc set_ignore_leave*(a: var TGtkMenuShell, `ignore_leave`: guint)
proc menu_flag*(a: var TGtkMenuShell): guint
proc set_menu_flag*(a: var TGtkMenuShell, `menu_flag`: guint)
proc ignore_enter*(a: var TGtkMenuShell): guint
proc set_ignore_enter*(a: var TGtkMenuShell, `ignore_enter`: guint)
proc submenu_placement*(a: var TGtkMenuShellClass): guint
proc set_submenu_placement*(a: var TGtkMenuShellClass,
                            `submenu_placement`: guint)
proc gtk_menu_shell_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_menu_shell_get_type".}
proc gtk_menu_shell_append*(menu_shell: PGtkMenuShell, child: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "gtk_menu_shell_append".}
proc gtk_menu_shell_prepend*(menu_shell: PGtkMenuShell, child: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "gtk_menu_shell_prepend".}
proc gtk_menu_shell_insert*(menu_shell: PGtkMenuShell, child: PGtkWidget,
                            position: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_menu_shell_insert".}
proc gtk_menu_shell_deactivate*(menu_shell: PGtkMenuShell){.cdecl,
    dynlib: gtklib, importc: "gtk_menu_shell_deactivate".}
proc gtk_menu_shell_select_item*(menu_shell: PGtkMenuShell,
                                 menu_item: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_menu_shell_select_item".}
proc gtk_menu_shell_deselect*(menu_shell: PGtkMenuShell){.cdecl, dynlib: gtklib,
    importc: "gtk_menu_shell_deselect".}
proc gtk_menu_shell_activate_item*(menu_shell: PGtkMenuShell,
                                   menu_item: PGtkWidget,
                                   force_deactivate: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_menu_shell_activate_item".}
proc gtk_menu_shell_select_first*(menu_shell: PGtkMenuShell){.cdecl,
    dynlib: gtklib, importc: "_gtk_menu_shell_select_first".}
proc gtk_menu_shell_activate*(menu_shell: PGtkMenuShell){.cdecl,
    dynlib: gtklib, importc: "_gtk_menu_shell_activate".}
const
  bm_TGtkMenu_needs_destruction_ref_count* = 0x00000001'i16
  bp_TGtkMenu_needs_destruction_ref_count* = 0'i16
  bm_TGtkMenu_torn_off* = 0x00000002'i16
  bp_TGtkMenu_torn_off* = 1'i16
  bm_TGtkMenu_tearoff_active* = 0x00000004'i16
  bp_TGtkMenu_tearoff_active* = 2'i16
  bm_TGtkMenu_scroll_fast* = 0x00000008'i16
  bp_TGtkMenu_scroll_fast* = 3'i16
  bm_TGtkMenu_upper_arrow_visible* = 0x00000010'i16
  bp_TGtkMenu_upper_arrow_visible* = 4'i16
  bm_TGtkMenu_lower_arrow_visible* = 0x00000020'i16
  bp_TGtkMenu_lower_arrow_visible* = 5'i16
  bm_TGtkMenu_upper_arrow_prelight* = 0x00000040'i16
  bp_TGtkMenu_upper_arrow_prelight* = 6'i16
  bm_TGtkMenu_lower_arrow_prelight* = 0x00000080'i16
  bp_TGtkMenu_lower_arrow_prelight* = 7'i16

proc GTK_TYPE_MENU*(): GType
proc GTK_MENU*(obj: pointer): PGtkMenu
proc GTK_MENU_CLASS*(klass: pointer): PGtkMenuClass
proc GTK_IS_MENU*(obj: pointer): bool
proc GTK_IS_MENU_CLASS*(klass: pointer): bool
proc GTK_MENU_GET_CLASS*(obj: pointer): PGtkMenuClass
proc needs_destruction_ref_count*(a: var TGtkMenu): guint
proc set_needs_destruction_ref_count*(a: var TGtkMenu,
                                      `needs_destruction_ref_count`: guint)
proc torn_off*(a: var TGtkMenu): guint
proc set_torn_off*(a: var TGtkMenu, `torn_off`: guint)
proc tearoff_active*(a: var TGtkMenu): guint
proc set_tearoff_active*(a: var TGtkMenu, `tearoff_active`: guint)
proc scroll_fast*(a: var TGtkMenu): guint
proc set_scroll_fast*(a: var TGtkMenu, `scroll_fast`: guint)
proc upper_arrow_visible*(a: var TGtkMenu): guint
proc set_upper_arrow_visible*(a: var TGtkMenu, `upper_arrow_visible`: guint)
proc lower_arrow_visible*(a: var TGtkMenu): guint
proc set_lower_arrow_visible*(a: var TGtkMenu, `lower_arrow_visible`: guint)
proc upper_arrow_prelight*(a: var TGtkMenu): guint
proc set_upper_arrow_prelight*(a: var TGtkMenu, `upper_arrow_prelight`: guint)
proc lower_arrow_prelight*(a: var TGtkMenu): guint
proc set_lower_arrow_prelight*(a: var TGtkMenu, `lower_arrow_prelight`: guint)
proc gtk_menu_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                     importc: "gtk_menu_get_type".}
proc gtk_menu_new*(): PGtkMenu {.cdecl, dynlib: gtklib, importc: "gtk_menu_new".}
proc gtk_menu_popup*(menu: PGtkMenu, parent_menu_shell: PGtkWidget,
                     parent_menu_item: PGtkWidget, fun: TGtkMenuPositionFunc,
                     data: gpointer, button: guint, activate_time: guint32){.
    cdecl, dynlib: gtklib, importc: "gtk_menu_popup".}
proc gtk_menu_reposition*(menu: PGtkMenu){.cdecl, dynlib: gtklib,
    importc: "gtk_menu_reposition".}
proc gtk_menu_popdown*(menu: PGtkMenu){.cdecl, dynlib: gtklib,
                                        importc: "gtk_menu_popdown".}
proc gtk_menu_get_active*(menu: PGtkMenu): PGtkWidget{.cdecl, dynlib: gtklib,
    importc: "gtk_menu_get_active".}
proc gtk_menu_set_active*(menu: PGtkMenu, index: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_menu_set_active".}
proc gtk_menu_set_accel_group*(menu: PGtkMenu, accel_group: PGtkAccelGroup){.
    cdecl, dynlib: gtklib, importc: "gtk_menu_set_accel_group".}
proc gtk_menu_get_accel_group*(menu: PGtkMenu): PGtkAccelGroup{.cdecl,
    dynlib: gtklib, importc: "gtk_menu_get_accel_group".}
proc gtk_menu_set_accel_path*(menu: PGtkMenu, accel_path: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_menu_set_accel_path".}
proc gtk_menu_attach_to_widget*(menu: PGtkMenu, attach_widget: PGtkWidget,
                                detacher: TGtkMenuDetachFunc){.cdecl,
    dynlib: gtklib, importc: "gtk_menu_attach_to_widget".}
proc gtk_menu_detach*(menu: PGtkMenu){.cdecl, dynlib: gtklib,
                                       importc: "gtk_menu_detach".}
proc gtk_menu_get_attach_widget*(menu: PGtkMenu): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_menu_get_attach_widget".}
proc gtk_menu_set_tearoff_state*(menu: PGtkMenu, torn_off: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_menu_set_tearoff_state".}
proc gtk_menu_get_tearoff_state*(menu: PGtkMenu): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_menu_get_tearoff_state".}
proc gtk_menu_set_title*(menu: PGtkMenu, title: cstring){.cdecl, dynlib: gtklib,
    importc: "gtk_menu_set_title".}
proc gtk_menu_get_title*(menu: PGtkMenu): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_menu_get_title".}
proc gtk_menu_reorder_child*(menu: PGtkMenu, child: PGtkWidget, position: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_menu_reorder_child".}
proc gtk_menu_set_screen*(menu: PGtkMenu, screen: PGdkScreen){.cdecl,
    dynlib: gtklib, importc: "gtk_menu_set_screen".}
const
  bm_TGtkEntry_editable* = 0x00000001'i16
  bp_TGtkEntry_editable* = 0'i16
  bm_TGtkEntry_visible* = 0x00000002'i16
  bp_TGtkEntry_visible* = 1'i16
  bm_TGtkEntry_overwrite_mode* = 0x00000004'i16
  bp_TGtkEntry_overwrite_mode* = 2'i16
  bm_TGtkEntry_in_drag* = 0x00000008'i16
  bp_TGtkEntry_in_drag* = 3'i16
  bm_TGtkEntry_cache_includes_preedit* = 0x00000001'i16
  bp_TGtkEntry_cache_includes_preedit* = 0'i16
  bm_TGtkEntry_need_im_reset* = 0x00000002'i16
  bp_TGtkEntry_need_im_reset* = 1'i16
  bm_TGtkEntry_has_frame* = 0x00000004'i16
  bp_TGtkEntry_has_frame* = 2'i16
  bm_TGtkEntry_activates_default* = 0x00000008'i16
  bp_TGtkEntry_activates_default* = 3'i16
  bm_TGtkEntry_cursor_visible* = 0x00000010'i16
  bp_TGtkEntry_cursor_visible* = 4'i16
  bm_TGtkEntry_in_click* = 0x00000020'i16
  bp_TGtkEntry_in_click* = 5'i16
  bm_TGtkEntry_is_cell_renderer* = 0x00000040'i16
  bp_TGtkEntry_is_cell_renderer* = 6'i16
  bm_TGtkEntry_editing_canceled* = 0x00000080'i16
  bp_TGtkEntry_editing_canceled* = 7'i16
  bm_TGtkEntry_mouse_cursor_obscured* = 0x00000100'i16
  bp_TGtkEntry_mouse_cursor_obscured* = 8'i16

proc GTK_TYPE_ENTRY*(): GType
proc GTK_ENTRY*(obj: pointer): PGtkEntry
proc GTK_ENTRY_CLASS*(klass: pointer): PGtkEntryClass
proc GTK_IS_ENTRY*(obj: pointer): bool
proc GTK_IS_ENTRY_CLASS*(klass: pointer): bool
proc GTK_ENTRY_GET_CLASS*(obj: pointer): PGtkEntryClass
proc editable*(a: var TGtkEntry): guint
proc set_editable*(a: var TGtkEntry, `editable`: guint)
proc visible*(a: var TGtkEntry): guint
proc set_visible*(a: var TGtkEntry, `visible`: guint)
proc overwrite_mode*(a: var TGtkEntry): guint
proc set_overwrite_mode*(a: var TGtkEntry, `overwrite_mode`: guint)
proc in_drag*(a: var TGtkEntry): guint
proc set_in_drag*(a: var TGtkEntry, `in_drag`: guint)
proc cache_includes_preedit*(a: var TGtkEntry): guint
proc set_cache_includes_preedit*(a: var TGtkEntry,
                                 `cache_includes_preedit`: guint)
proc need_im_reset*(a: var TGtkEntry): guint
proc set_need_im_reset*(a: var TGtkEntry, `need_im_reset`: guint)
proc has_frame*(a: var TGtkEntry): guint
proc set_has_frame*(a: var TGtkEntry, `has_frame`: guint)
proc activates_default*(a: var TGtkEntry): guint
proc set_activates_default*(a: var TGtkEntry, `activates_default`: guint)
proc cursor_visible*(a: var TGtkEntry): guint
proc set_cursor_visible*(a: var TGtkEntry, `cursor_visible`: guint)
proc in_click*(a: var TGtkEntry): guint
proc set_in_click*(a: var TGtkEntry, `in_click`: guint)
proc is_cell_renderer*(a: var TGtkEntry): guint
proc set_is_cell_renderer*(a: var TGtkEntry, `is_cell_renderer`: guint)
proc editing_canceled*(a: var TGtkEntry): guint
proc set_editing_canceled*(a: var TGtkEntry, `editing_canceled`: guint)
proc mouse_cursor_obscured*(a: var TGtkEntry): guint
proc set_mouse_cursor_obscured*(a: var TGtkEntry, `mouse_cursor_obscured`: guint)
proc gtk_entry_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_entry_get_type".}
proc gtk_entry_new*(): PGtkEntry {.cdecl, dynlib: gtklib,
                                   importc: "gtk_entry_new".}
proc gtk_entry_set_visibility*(entry: PGtkEntry, visible: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_entry_set_visibility".}
proc gtk_entry_get_visibility*(entry: PGtkEntry): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_entry_get_visibility".}
proc gtk_entry_set_invisible_char*(entry: PGtkEntry, ch: gunichar){.cdecl,
    dynlib: gtklib, importc: "gtk_entry_set_invisible_char".}
proc gtk_entry_get_invisible_char*(entry: PGtkEntry): gunichar{.cdecl,
    dynlib: gtklib, importc: "gtk_entry_get_invisible_char".}
proc gtk_entry_set_has_frame*(entry: PGtkEntry, setting: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_entry_set_has_frame".}
proc gtk_entry_get_has_frame*(entry: PGtkEntry): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_entry_get_has_frame".}
proc gtk_entry_set_max_length*(entry: PGtkEntry, max: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_entry_set_max_length".}
proc gtk_entry_get_max_length*(entry: PGtkEntry): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_entry_get_max_length".}
proc gtk_entry_set_activates_default*(entry: PGtkEntry, setting: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_entry_set_activates_default".}
proc gtk_entry_get_activates_default*(entry: PGtkEntry): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_entry_get_activates_default".}
proc gtk_entry_set_width_chars*(entry: PGtkEntry, n_chars: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_entry_set_width_chars".}
proc gtk_entry_get_width_chars*(entry: PGtkEntry): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_entry_get_width_chars".}
proc gtk_entry_set_text*(entry: PGtkEntry, text: cstring){.cdecl, dynlib: gtklib,
    importc: "gtk_entry_set_text".}
proc gtk_entry_get_text*(entry: PGtkEntry): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_entry_get_text".}
proc gtk_entry_get_layout*(entry: PGtkEntry): PPangoLayout{.cdecl,
    dynlib: gtklib, importc: "gtk_entry_get_layout".}
proc gtk_entry_get_layout_offsets*(entry: PGtkEntry, x: Pgint, y: Pgint){.cdecl,
    dynlib: gtklib, importc: "gtk_entry_get_layout_offsets".}
const
  GTK_ANCHOR_CENTER* = 0
  GTK_ANCHOR_NORTH* = 1
  GTK_ANCHOR_NORTH_WEST* = 2
  GTK_ANCHOR_NORTH_EAST* = 3
  GTK_ANCHOR_SOUTH* = 4
  GTK_ANCHOR_SOUTH_WEST* = 5
  GTK_ANCHOR_SOUTH_EAST* = 6
  GTK_ANCHOR_WEST* = 7
  GTK_ANCHOR_EAST* = 8
  GTK_ANCHOR_N* = GTK_ANCHOR_NORTH
  GTK_ANCHOR_NW* = GTK_ANCHOR_NORTH_WEST
  GTK_ANCHOR_NE* = GTK_ANCHOR_NORTH_EAST
  GTK_ANCHOR_S* = GTK_ANCHOR_SOUTH
  GTK_ANCHOR_SW* = GTK_ANCHOR_SOUTH_WEST
  GTK_ANCHOR_SE* = GTK_ANCHOR_SOUTH_EAST
  GTK_ANCHOR_W* = GTK_ANCHOR_WEST
  GTK_ANCHOR_E* = GTK_ANCHOR_EAST
  GTK_ARROW_UP* = 0
  GTK_ARROW_DOWN* = 1
  GTK_ARROW_LEFT* = 2
  GTK_ARROW_RIGHT* = 3
  GTK_EXPAND* = 1 shl 0
  GTK_SHRINK* = 1 shl 1
  GTK_FILL* = 1 shl 2
  GTK_BUTTONBOX_DEFAULT_STYLE* = 0
  GTK_BUTTONBOX_SPREAD* = 1
  GTK_BUTTONBOX_EDGE* = 2
  GTK_BUTTONBOX_START* = 3
  GTK_BUTTONBOX_END* = 4
  GTK_CURVE_TYPE_LINEAR* = 0
  GTK_CURVE_TYPE_SPLINE* = 1
  GTK_CURVE_TYPE_FREE* = 2
  GTK_DELETE_CHARS* = 0
  GTK_DELETE_WORD_ENDS* = 1
  GTK_DELETE_WORDS* = 2
  GTK_DELETE_DISPLAY_LINES* = 3
  GTK_DELETE_DISPLAY_LINE_ENDS* = 4
  GTK_DELETE_PARAGRAPH_ENDS* = 5
  GTK_DELETE_PARAGRAPHS* = 6
  GTK_DELETE_WHITESPACE* = 7
  GTK_DIR_TAB_FORWARD* = 0
  GTK_DIR_TAB_BACKWARD* = 1
  GTK_DIR_UP* = 2
  GTK_DIR_DOWN* = 3
  GTK_DIR_LEFT* = 4
  GTK_DIR_RIGHT* = 5
  GTK_EXPANDER_COLLAPSED* = 0
  GTK_EXPANDER_SEMI_COLLAPSED* = 1
  GTK_EXPANDER_SEMI_EXPANDED* = 2
  GTK_EXPANDER_EXPANDED* = 3
  GTK_ICON_SIZE_INVALID* = 0
  GTK_ICON_SIZE_MENU* = 1
  GTK_ICON_SIZE_SMALL_TOOLBAR* = 2
  GTK_ICON_SIZE_LARGE_TOOLBAR* = 3
  GTK_ICON_SIZE_BUTTON* = 4
  GTK_ICON_SIZE_DND* = 5
  GTK_ICON_SIZE_DIALOG* = 6
  GTK_TEXT_DIR_NONE* = 0
  GTK_TEXT_DIR_LTR* = 1
  GTK_TEXT_DIR_RTL* = 2
  GTK_JUSTIFY_LEFT* = 0
  GTK_JUSTIFY_RIGHT* = 1
  GTK_JUSTIFY_CENTER* = 2
  GTK_JUSTIFY_FILL* = 3
  GTK_MENU_DIR_PARENT* = 0
  GTK_MENU_DIR_CHILD* = 1
  GTK_MENU_DIR_NEXT* = 2
  GTK_MENU_DIR_PREV* = 3
  GTK_PIXELS* = 0
  GTK_INCHES* = 1
  GTK_CENTIMETERS* = 2
  GTK_MOVEMENT_LOGICAL_POSITIONS* = 0
  GTK_MOVEMENT_VISUAL_POSITIONS* = 1
  GTK_MOVEMENT_WORDS* = 2
  GTK_MOVEMENT_DISPLAY_LINES* = 3
  GTK_MOVEMENT_DISPLAY_LINE_ENDS* = 4
  GTK_MOVEMENT_PARAGRAPHS* = 5
  GTK_MOVEMENT_PARAGRAPH_ENDS* = 6
  GTK_MOVEMENT_PAGES* = 7
  GTK_MOVEMENT_BUFFER_ENDS* = 8
  GTK_ORIENTATION_HORIZONTAL* = 0
  GTK_ORIENTATION_VERTICAL* = 1
  GTK_CORNER_TOP_LEFT* = 0
  GTK_CORNER_BOTTOM_LEFT* = 1
  GTK_CORNER_TOP_RIGHT* = 2
  GTK_CORNER_BOTTOM_RIGHT* = 3
  GTK_PACK_START* = 0
  GTK_PACK_END* = 1
  GTK_PATH_PRIO_LOWEST* = 0
  GTK_PATH_PRIO_GTK* = 4
  GTK_PATH_PRIO_APPLICATION* = 8
  GTK_PATH_PRIO_THEME* = 10
  GTK_PATH_PRIO_RC* = 12
  GTK_PATH_PRIO_HIGHEST* = 15
  GTK_PATH_WIDGET* = 0
  GTK_PATH_WIDGET_CLASS* = 1
  GTK_PATH_CLASS* = 2
  GTK_POLICY_ALWAYS* = 0
  GTK_POLICY_AUTOMATIC* = 1
  GTK_POLICY_NEVER* = 2
  GTK_POS_LEFT* = 0
  GTK_POS_RIGHT* = 1
  GTK_POS_TOP* = 2
  GTK_POS_BOTTOM* = 3
  GTK_PREVIEW_COLOR* = 0
  GTK_PREVIEW_GRAYSCALE* = 1
  GTK_RELIEF_NORMAL* = 0
  GTK_RELIEF_HALF* = 1
  GTK_RELIEF_NONE* = 2
  GTK_RESIZE_PARENT* = 0
  GTK_RESIZE_QUEUE* = 1
  GTK_RESIZE_IMMEDIATE* = 2
  GTK_SCROLL_NONE* = 0
  GTK_SCROLL_JUMP* = 1
  GTK_SCROLL_STEP_BACKWARD* = 2
  GTK_SCROLL_STEP_FORWARD* = 3
  GTK_SCROLL_PAGE_BACKWARD* = 4
  GTK_SCROLL_PAGE_FORWARD* = 5
  GTK_SCROLL_STEP_UP* = 6
  GTK_SCROLL_STEP_DOWN* = 7
  GTK_SCROLL_PAGE_UP* = 8
  GTK_SCROLL_PAGE_DOWN* = 9
  GTK_SCROLL_STEP_LEFT* = 10
  GTK_SCROLL_STEP_RIGHT* = 11
  GTK_SCROLL_PAGE_LEFT* = 12
  GTK_SCROLL_PAGE_RIGHT* = 13
  GTK_SCROLL_START* = 14
  GTK_SCROLL_END* = 15
  GTK_SELECTION_NONE* = 0
  GTK_SELECTION_SINGLE* = 1
  GTK_SELECTION_BROWSE* = 2
  GTK_SELECTION_MULTIPLE* = 3
  GTK_SELECTION_EXTENDED* = GTK_SELECTION_MULTIPLE
  GTK_SHADOW_NONE* = 0
  GTK_SHADOW_IN* = 1
  GTK_SHADOW_OUT* = 2
  GTK_SHADOW_ETCHED_IN* = 3
  GTK_SHADOW_ETCHED_OUT* = 4
  GTK_STATE_NORMAL* = 0
  GTK_STATE_ACTIVE* = 1
  GTK_STATE_PRELIGHT* = 2
  GTK_STATE_SELECTED* = 3
  GTK_STATE_INSENSITIVE* = 4
  GTK_DIRECTION_LEFT* = 0
  GTK_DIRECTION_RIGHT* = 1
  GTK_TOP_BOTTOM* = 0
  GTK_LEFT_RIGHT* = 1
  GTK_TOOLBAR_ICONS* = 0
  GTK_TOOLBAR_TEXT* = 1
  GTK_TOOLBAR_BOTH* = 2
  GTK_TOOLBAR_BOTH_HORIZ* = 3
  GTK_UPDATE_CONTINUOUS* = 0
  GTK_UPDATE_DISCONTINUOUS* = 1
  GTK_UPDATE_DELAYED* = 2
  GTK_VISIBILITY_NONE* = 0
  GTK_VISIBILITY_PARTIAL* = 1
  GTK_VISIBILITY_FULL* = 2
  GTK_WIN_POS_NONE* = 0
  GTK_WIN_POS_CENTER* = 1
  GTK_WIN_POS_MOUSE* = 2
  GTK_WIN_POS_CENTER_ALWAYS* = 3
  GTK_WIN_POS_CENTER_ON_PARENT* = 4
  GTK_WINDOW_TOPLEVEL* = 0
  GTK_WINDOW_POPUP* = 1
  GTK_WRAP_NONE* = 0
  GTK_WRAP_CHAR* = 1
  GTK_WRAP_WORD* = 2
  GTK_SORT_ASCENDING* = 0
  GTK_SORT_DESCENDING* = 1

proc GTK_TYPE_EVENT_BOX*(): GType
proc GTK_EVENT_BOX*(obj: pointer): PGtkEventBox
proc GTK_EVENT_BOX_CLASS*(klass: pointer): PGtkEventBoxClass
proc GTK_IS_EVENT_BOX*(obj: pointer): bool
proc GTK_IS_EVENT_BOX_CLASS*(klass: pointer): bool
proc GTK_EVENT_BOX_GET_CLASS*(obj: pointer): PGtkEventBoxClass
proc gtk_event_box_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_event_box_get_type".}
proc gtk_event_box_new*(): PGtkEventBox {.cdecl, dynlib: gtklib,
                                          importc: "gtk_event_box_new".}
const
  FNM_PATHNAME* = 1 shl 0
  FNM_NOESCAPE* = 1 shl 1
  FNM_PERIOD* = 1 shl 2

const
  FNM_FILE_NAME* = FNM_PATHNAME
  FNM_LEADING_DIR* = 1 shl 3
  FNM_CASEFOLD* = 1 shl 4

const
  FNM_NOMATCH* = 1

proc fnmatch*(`pattern`: char, `string`: char, `flags`: gint): gint{.cdecl,
    dynlib: gtklib, importc: "fnmatch".}
proc GTK_TYPE_FILE_SELECTION*(): GType
proc GTK_FILE_SELECTION*(obj: pointer): PGtkFileSelection
proc GTK_FILE_SELECTION_CLASS*(klass: pointer): PGtkFileSelectionClass
proc GTK_IS_FILE_SELECTION*(obj: pointer): bool
proc GTK_IS_FILE_SELECTION_CLASS*(klass: pointer): bool
proc GTK_FILE_SELECTION_GET_CLASS*(obj: pointer): PGtkFileSelectionClass
proc gtk_file_selection_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_file_selection_get_type".}
proc gtk_file_selection_new*(title: cstring): PGtkFileSelection {.cdecl, dynlib: gtklib,
    importc: "gtk_file_selection_new".}
proc gtk_file_selection_set_filename*(filesel: PGtkFileSelection,
                                      filename: cstring){.cdecl, dynlib: gtklib,
    importc: "gtk_file_selection_set_filename".}
proc gtk_file_selection_get_filename*(filesel: PGtkFileSelection): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_file_selection_get_filename".}
proc gtk_file_selection_complete*(filesel: PGtkFileSelection, pattern: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_file_selection_complete".}
proc gtk_file_selection_show_fileop_buttons*(filesel: PGtkFileSelection){.cdecl,
    dynlib: gtklib, importc: "gtk_file_selection_show_fileop_buttons".}
proc gtk_file_selection_hide_fileop_buttons*(filesel: PGtkFileSelection){.cdecl,
    dynlib: gtklib, importc: "gtk_file_selection_hide_fileop_buttons".}
proc gtk_file_selection_get_selections*(filesel: PGtkFileSelection): PPgchar{.
    cdecl, dynlib: gtklib, importc: "gtk_file_selection_get_selections".}
proc gtk_file_selection_set_select_multiple*(filesel: PGtkFileSelection,
    select_multiple: gboolean){.cdecl, dynlib: gtklib, importc: "gtk_file_selection_set_select_multiple".}
proc gtk_file_selection_get_select_multiple*(filesel: PGtkFileSelection): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_file_selection_get_select_multiple".}
proc GTK_TYPE_FIXED*(): GType
proc GTK_FIXED*(obj: pointer): PGtkFixed
proc GTK_FIXED_CLASS*(klass: pointer): PGtkFixedClass
proc GTK_IS_FIXED*(obj: pointer): bool
proc GTK_IS_FIXED_CLASS*(klass: pointer): bool
proc GTK_FIXED_GET_CLASS*(obj: pointer): PGtkFixedClass
proc gtk_fixed_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_fixed_get_type".}
proc gtk_fixed_new*(): PGtkFixed {.cdecl, dynlib: gtklib,
                                   importc: "gtk_fixed_new".}
proc gtk_fixed_put*(fixed: PGtkFixed, widget: PGtkWidget, x: gint, y: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_fixed_put".}
proc gtk_fixed_move*(fixed: PGtkFixed, widget: PGtkWidget, x: gint, y: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_fixed_move".}
proc gtk_fixed_set_has_window*(fixed: PGtkFixed, has_window: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_fixed_set_has_window".}
proc gtk_fixed_get_has_window*(fixed: PGtkFixed): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_fixed_get_has_window".}
proc GTK_TYPE_FONT_SELECTION*(): GType
proc GTK_FONT_SELECTION*(obj: pointer): PGtkFontSelection
proc GTK_FONT_SELECTION_CLASS*(klass: pointer): PGtkFontSelectionClass
proc GTK_IS_FONT_SELECTION*(obj: pointer): bool
proc GTK_IS_FONT_SELECTION_CLASS*(klass: pointer): bool
proc GTK_FONT_SELECTION_GET_CLASS*(obj: pointer): PGtkFontSelectionClass
proc GTK_TYPE_FONT_SELECTION_DIALOG*(): GType
proc GTK_FONT_SELECTION_DIALOG*(obj: pointer): PGtkFontSelectionDialog
proc GTK_FONT_SELECTION_DIALOG_CLASS*(klass: pointer): PGtkFontSelectionDialogClass
proc GTK_IS_FONT_SELECTION_DIALOG*(obj: pointer): bool
proc GTK_IS_FONT_SELECTION_DIALOG_CLASS*(klass: pointer): bool
proc GTK_FONT_SELECTION_DIALOG_GET_CLASS*(obj: pointer): PGtkFontSelectionDialogClass
proc gtk_font_selection_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_font_selection_get_type".}
proc gtk_font_selection_new*(): PGtkFontSelection{.cdecl, dynlib: gtklib,
    importc: "gtk_font_selection_new".}
proc gtk_font_selection_get_font_name*(fontsel: PGtkFontSelection): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_font_selection_get_font_name".}
proc gtk_font_selection_set_font_name*(fontsel: PGtkFontSelection,
                                       fontname: cstring): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_font_selection_set_font_name".}
proc gtk_font_selection_get_preview_text*(fontsel: PGtkFontSelection): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_font_selection_get_preview_text".}
proc gtk_font_selection_set_preview_text*(fontsel: PGtkFontSelection,
    text: cstring){.cdecl, dynlib: gtklib,
                   importc: "gtk_font_selection_set_preview_text".}
proc gtk_font_selection_dialog_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_font_selection_dialog_get_type".}
proc gtk_font_selection_dialog_new*(title: cstring): PGtkFontSelectionDialog{.cdecl,
    dynlib: gtklib, importc: "gtk_font_selection_dialog_new".}
proc gtk_font_selection_dialog_get_font_name*(fsd: PGtkFontSelectionDialog): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_font_selection_dialog_get_font_name".}
proc gtk_font_selection_dialog_set_font_name*(fsd: PGtkFontSelectionDialog,
    fontname: cstring): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_font_selection_dialog_set_font_name".}
proc gtk_font_selection_dialog_get_preview_text*(fsd: PGtkFontSelectionDialog): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_font_selection_dialog_get_preview_text".}
proc gtk_font_selection_dialog_set_preview_text*(fsd: PGtkFontSelectionDialog,
    text: cstring){.cdecl, dynlib: gtklib,
                   importc: "gtk_font_selection_dialog_set_preview_text".}
proc GTK_TYPE_GAMMA_CURVE*(): GType
proc GTK_GAMMA_CURVE*(obj: pointer): PGtkGammaCurve
proc GTK_GAMMA_CURVE_CLASS*(klass: pointer): PGtkGammaCurveClass
proc GTK_IS_GAMMA_CURVE*(obj: pointer): bool
proc GTK_IS_GAMMA_CURVE_CLASS*(klass: pointer): bool
proc GTK_GAMMA_CURVE_GET_CLASS*(obj: pointer): PGtkGammaCurveClass
proc gtk_gamma_curve_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_gamma_curve_get_type".}
proc gtk_gamma_curve_new*(): PGtkGammaCurve{.cdecl, dynlib: gtklib,
    importc: "gtk_gamma_curve_new".}
proc gtk_gc_get*(depth: gint, colormap: PGdkColormap, values: PGdkGCValues,
                 values_mask: TGdkGCValuesMask): PGdkGC{.cdecl, dynlib: gtklib,
    importc: "gtk_gc_get".}
proc gtk_gc_release*(gc: PGdkGC){.cdecl, dynlib: gtklib,
                                  importc: "gtk_gc_release".}
const
  bm_TGtkHandleBox_handle_position* = 0x00000003'i16
  bp_TGtkHandleBox_handle_position* = 0'i16
  bm_TGtkHandleBox_float_window_mapped* = 0x00000004'i16
  bp_TGtkHandleBox_float_window_mapped* = 2'i16
  bm_TGtkHandleBox_child_detached* = 0x00000008'i16
  bp_TGtkHandleBox_child_detached* = 3'i16
  bm_TGtkHandleBox_in_drag* = 0x00000010'i16
  bp_TGtkHandleBox_in_drag* = 4'i16
  bm_TGtkHandleBox_shrink_on_detach* = 0x00000020'i16
  bp_TGtkHandleBox_shrink_on_detach* = 5'i16
  bm_TGtkHandleBox_snap_edge* = 0x000001C0'i16
  bp_TGtkHandleBox_snap_edge* = 6'i16

proc GTK_TYPE_HANDLE_BOX*(): GType
proc GTK_HANDLE_BOX*(obj: pointer): PGtkHandleBox
proc GTK_HANDLE_BOX_CLASS*(klass: pointer): PGtkHandleBoxClass
proc GTK_IS_HANDLE_BOX*(obj: pointer): bool
proc GTK_IS_HANDLE_BOX_CLASS*(klass: pointer): bool
proc GTK_HANDLE_BOX_GET_CLASS*(obj: pointer): PGtkHandleBoxClass
proc handle_position*(a: var TGtkHandleBox): guint
proc set_handle_position*(a: var TGtkHandleBox, `handle_position`: guint)
proc float_window_mapped*(a: var TGtkHandleBox): guint
proc set_float_window_mapped*(a: var TGtkHandleBox, `float_window_mapped`: guint)
proc child_detached*(a: var TGtkHandleBox): guint
proc set_child_detached*(a: var TGtkHandleBox, `child_detached`: guint)
proc in_drag*(a: var TGtkHandleBox): guint
proc set_in_drag*(a: var TGtkHandleBox, `in_drag`: guint)
proc shrink_on_detach*(a: var TGtkHandleBox): guint
proc set_shrink_on_detach*(a: var TGtkHandleBox, `shrink_on_detach`: guint)
proc snap_edge*(a: var TGtkHandleBox): gint
proc set_snap_edge*(a: var TGtkHandleBox, `snap_edge`: gint)
proc gtk_handle_box_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_handle_box_get_type".}
proc gtk_handle_box_new*(): PGtkHandleBox{.cdecl, dynlib: gtklib,
                                        importc: "gtk_handle_box_new".}
proc gtk_handle_box_set_shadow_type*(handle_box: PGtkHandleBox,
                                     thetype: TGtkShadowType){.cdecl,
    dynlib: gtklib, importc: "gtk_handle_box_set_shadow_type".}
proc gtk_handle_box_get_shadow_type*(handle_box: PGtkHandleBox): TGtkShadowType{.
    cdecl, dynlib: gtklib, importc: "gtk_handle_box_get_shadow_type".}
proc gtk_handle_box_set_handle_position*(handle_box: PGtkHandleBox,
    position: TGtkPositionType){.cdecl, dynlib: gtklib,
                                 importc: "gtk_handle_box_set_handle_position".}
proc gtk_handle_box_get_handle_position*(handle_box: PGtkHandleBox): TGtkPositionType{.
    cdecl, dynlib: gtklib, importc: "gtk_handle_box_get_handle_position".}
proc gtk_handle_box_set_snap_edge*(handle_box: PGtkHandleBox,
                                   edge: TGtkPositionType){.cdecl,
    dynlib: gtklib, importc: "gtk_handle_box_set_snap_edge".}
proc gtk_handle_box_get_snap_edge*(handle_box: PGtkHandleBox): TGtkPositionType{.
    cdecl, dynlib: gtklib, importc: "gtk_handle_box_get_snap_edge".}
const
  bm_TGtkPaned_position_set* = 0x00000001'i16
  bp_TGtkPaned_position_set* = 0'i16
  bm_TGtkPaned_in_drag* = 0x00000002'i16
  bp_TGtkPaned_in_drag* = 1'i16
  bm_TGtkPaned_child1_shrink* = 0x00000004'i16
  bp_TGtkPaned_child1_shrink* = 2'i16
  bm_TGtkPaned_child1_resize* = 0x00000008'i16
  bp_TGtkPaned_child1_resize* = 3'i16
  bm_TGtkPaned_child2_shrink* = 0x00000010'i16
  bp_TGtkPaned_child2_shrink* = 4'i16
  bm_TGtkPaned_child2_resize* = 0x00000020'i16
  bp_TGtkPaned_child2_resize* = 5'i16
  bm_TGtkPaned_orientation* = 0x00000040'i16
  bp_TGtkPaned_orientation* = 6'i16
  bm_TGtkPaned_in_recursion* = 0x00000080'i16
  bp_TGtkPaned_in_recursion* = 7'i16
  bm_TGtkPaned_handle_prelit* = 0x00000100'i16
  bp_TGtkPaned_handle_prelit* = 8'i16

proc GTK_TYPE_PANED*(): GType
proc GTK_PANED*(obj: pointer): PGtkPaned
proc GTK_PANED_CLASS*(klass: pointer): PGtkPanedClass
proc GTK_IS_PANED*(obj: pointer): bool
proc GTK_IS_PANED_CLASS*(klass: pointer): bool
proc GTK_PANED_GET_CLASS*(obj: pointer): PGtkPanedClass
proc position_set*(a: var TGtkPaned): guint
proc set_position_set*(a: var TGtkPaned, `position_set`: guint)
proc in_drag*(a: var TGtkPaned): guint
proc set_in_drag*(a: var TGtkPaned, `in_drag`: guint)
proc child1_shrink*(a: var TGtkPaned): guint
proc set_child1_shrink*(a: var TGtkPaned, `child1_shrink`: guint)
proc child1_resize*(a: var TGtkPaned): guint
proc set_child1_resize*(a: var TGtkPaned, `child1_resize`: guint)
proc child2_shrink*(a: var TGtkPaned): guint
proc set_child2_shrink*(a: var TGtkPaned, `child2_shrink`: guint)
proc child2_resize*(a: var TGtkPaned): guint
proc set_child2_resize*(a: var TGtkPaned, `child2_resize`: guint)
proc orientation*(a: var TGtkPaned): guint
proc set_orientation*(a: var TGtkPaned, `orientation`: guint)
proc in_recursion*(a: var TGtkPaned): guint
proc set_in_recursion*(a: var TGtkPaned, `in_recursion`: guint)
proc handle_prelit*(a: var TGtkPaned): guint
proc set_handle_prelit*(a: var TGtkPaned, `handle_prelit`: guint)
proc gtk_paned_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_paned_get_type".}
proc gtk_paned_add1*(paned: PGtkPaned, child: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_paned_add1".}
proc gtk_paned_add2*(paned: PGtkPaned, child: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_paned_add2".}
proc gtk_paned_pack1*(paned: PGtkPaned, child: PGtkWidget, resize: gboolean,
                      shrink: gboolean){.cdecl, dynlib: gtklib,
    importc: "gtk_paned_pack1".}
proc gtk_paned_pack2*(paned: PGtkPaned, child: PGtkWidget, resize: gboolean,
                      shrink: gboolean){.cdecl, dynlib: gtklib,
    importc: "gtk_paned_pack2".}
proc gtk_paned_get_position*(paned: PGtkPaned): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_paned_get_position".}
proc gtk_paned_set_position*(paned: PGtkPaned, position: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_paned_set_position".}
proc gtk_paned_compute_position*(paned: PGtkPaned, allocation: gint,
                                 child1_req: gint, child2_req: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_paned_compute_position".}
proc GTK_TYPE_HBUTTON_BOX*(): GType
proc GTK_HBUTTON_BOX*(obj: pointer): PGtkHButtonBox
proc GTK_HBUTTON_BOX_CLASS*(klass: pointer): PGtkHButtonBoxClass
proc GTK_IS_HBUTTON_BOX*(obj: pointer): bool
proc GTK_IS_HBUTTON_BOX_CLASS*(klass: pointer): bool
proc GTK_HBUTTON_BOX_GET_CLASS*(obj: pointer): PGtkHButtonBoxClass
proc gtk_hbutton_box_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_hbutton_box_get_type".}
proc gtk_hbutton_box_new*(): PGtkHButtonBox{.cdecl, dynlib: gtklib,
    importc: "gtk_hbutton_box_new".}
proc GTK_TYPE_HPANED*(): GType
proc GTK_HPANED*(obj: pointer): PGtkHPaned
proc GTK_HPANED_CLASS*(klass: pointer): PGtkHPanedClass
proc GTK_IS_HPANED*(obj: pointer): bool
proc GTK_IS_HPANED_CLASS*(klass: pointer): bool
proc GTK_HPANED_GET_CLASS*(obj: pointer): PGtkHPanedClass
proc gtk_hpaned_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_hpaned_get_type".}
proc gtk_hpaned_new*(): PGtkHPaned{.cdecl, dynlib: gtklib,
                                    importc: "gtk_hpaned_new".}
proc GTK_TYPE_RULER*(): GType
proc GTK_RULER*(obj: pointer): PGtkRuler
proc GTK_RULER_CLASS*(klass: pointer): PGtkRulerClass
proc GTK_IS_RULER*(obj: pointer): bool
proc GTK_IS_RULER_CLASS*(klass: pointer): bool
proc GTK_RULER_GET_CLASS*(obj: pointer): PGtkRulerClass
proc gtk_ruler_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_ruler_get_type".}
proc gtk_ruler_set_metric*(ruler: PGtkRuler, metric: TGtkMetricType){.cdecl,
    dynlib: gtklib, importc: "gtk_ruler_set_metric".}
proc gtk_ruler_set_range*(ruler: PGtkRuler, lower: gdouble, upper: gdouble,
                          position: gdouble, max_size: gdouble){.cdecl,
    dynlib: gtklib, importc: "gtk_ruler_set_range".}
proc gtk_ruler_draw_ticks*(ruler: PGtkRuler){.cdecl, dynlib: gtklib,
    importc: "gtk_ruler_draw_ticks".}
proc gtk_ruler_draw_pos*(ruler: PGtkRuler){.cdecl, dynlib: gtklib,
    importc: "gtk_ruler_draw_pos".}
proc gtk_ruler_get_metric*(ruler: PGtkRuler): TGtkMetricType{.cdecl,
    dynlib: gtklib, importc: "gtk_ruler_get_metric".}
proc gtk_ruler_get_range*(ruler: PGtkRuler, lower: Pgdouble, upper: Pgdouble,
                          position: Pgdouble, max_size: Pgdouble){.cdecl,
    dynlib: gtklib, importc: "gtk_ruler_get_range".}
proc GTK_TYPE_HRULER*(): GType
proc GTK_HRULER*(obj: pointer): PGtkHRuler
proc GTK_HRULER_CLASS*(klass: pointer): PGtkHRulerClass
proc GTK_IS_HRULER*(obj: pointer): bool
proc GTK_IS_HRULER_CLASS*(klass: pointer): bool
proc GTK_HRULER_GET_CLASS*(obj: pointer): PGtkHRulerClass
proc gtk_hruler_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_hruler_get_type".}
proc gtk_hruler_new*(): PGtkHRuler{.cdecl, dynlib: gtklib,
                                    importc: "gtk_hruler_new".}
proc GTK_TYPE_SETTINGS*(): GType
proc GTK_SETTINGS*(obj: pointer): PGtkSettings
proc GTK_SETTINGS_CLASS*(klass: pointer): PGtkSettingsClass
proc GTK_IS_SETTINGS*(obj: pointer): bool
proc GTK_IS_SETTINGS_CLASS*(klass: pointer): bool
proc GTK_SETTINGS_GET_CLASS*(obj: pointer): PGtkSettingsClass
proc gtk_settings_get_type*(): GType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_settings_get_type".}
proc gtk_settings_get_for_screen*(screen: PGdkScreen): PGtkSettings{.cdecl,
    dynlib: gtklib, importc: "gtk_settings_get_for_screen".}
proc gtk_settings_install_property*(pspec: PGParamSpec){.cdecl, dynlib: gtklib,
    importc: "gtk_settings_install_property".}
proc gtk_settings_install_property_parser*(pspec: PGParamSpec,
    parser: TGtkRcPropertyParser){.cdecl, dynlib: gtklib, importc: "gtk_settings_install_property_parser".}
proc gtk_rc_property_parse_color*(pspec: PGParamSpec, gstring: PGString,
                                  property_value: PGValue): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_rc_property_parse_color".}
proc gtk_rc_property_parse_enum*(pspec: PGParamSpec, gstring: PGString,
                                 property_value: PGValue): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_rc_property_parse_enum".}
proc gtk_rc_property_parse_flags*(pspec: PGParamSpec, gstring: PGString,
                                  property_value: PGValue): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_rc_property_parse_flags".}
proc gtk_rc_property_parse_requisition*(pspec: PGParamSpec, gstring: PGString,
                                        property_value: PGValue): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_rc_property_parse_requisition".}
proc gtk_rc_property_parse_border*(pspec: PGParamSpec, gstring: PGString,
                                   property_value: PGValue): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_rc_property_parse_border".}
proc gtk_settings_set_property_value*(settings: PGtkSettings, name: cstring,
                                      svalue: PGtkSettingsValue){.cdecl,
    dynlib: gtklib, importc: "gtk_settings_set_property_value".}
proc gtk_settings_set_string_property*(settings: PGtkSettings, name: cstring,
                                       v_string: cstring, origin: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_settings_set_string_property".}
proc gtk_settings_set_long_property*(settings: PGtkSettings, name: cstring,
                                     v_long: glong, origin: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_settings_set_long_property".}
proc gtk_settings_set_double_property*(settings: PGtkSettings, name: cstring,
                                       v_double: gdouble, origin: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_settings_set_double_property".}
proc gtk_settings_handle_event*(event: PGdkEventSetting){.cdecl,
    dynlib: gtklib, importc: "_gtk_settings_handle_event".}
proc gtk_rc_property_parser_from_type*(thetype: GType): TGtkRcPropertyParser{.
    cdecl, dynlib: gtklib, importc: "_gtk_rc_property_parser_from_type".}
proc gtk_settings_parse_convert*(parser: TGtkRcPropertyParser,
                                   src_value: PGValue, pspec: PGParamSpec,
                                   dest_value: PGValue): gboolean{.cdecl,
    dynlib: gtklib, importc: "_gtk_settings_parse_convert".}
const
  GTK_RC_FG* = 1 shl 0
  GTK_RC_BG* = 1 shl 1
  GTK_RC_TEXT* = 1 shl 2
  GTK_RC_BASE* = 1 shl 3
  bm_TGtkRcStyle_engine_specified* = 0x00000001'i16
  bp_TGtkRcStyle_engine_specified* = 0'i16

proc GTK_TYPE_RC_STYLE*(): GType
proc GTK_RC_STYLE_get*(anObject: pointer): PGtkRcStyle
proc GTK_RC_STYLE_CLASS*(klass: pointer): PGtkRcStyleClass
proc GTK_IS_RC_STYLE*(anObject: pointer): bool
proc GTK_IS_RC_STYLE_CLASS*(klass: pointer): bool
proc GTK_RC_STYLE_GET_CLASS*(obj: pointer): PGtkRcStyleClass
proc engine_specified*(a: var TGtkRcStyle): guint
proc set_engine_specified*(a: var TGtkRcStyle, `engine_specified`: guint)
proc gtk_rc_init*(){.cdecl, dynlib: gtklib, importc: "_gtk_rc_init".}
proc gtk_rc_add_default_file*(filename: cstring){.cdecl, dynlib: gtklib,
    importc: "gtk_rc_add_default_file".}
proc gtk_rc_set_default_files*(filenames: PPgchar){.cdecl, dynlib: gtklib,
    importc: "gtk_rc_set_default_files".}
proc gtk_rc_get_default_files*(): PPgchar{.cdecl, dynlib: gtklib,
    importc: "gtk_rc_get_default_files".}
proc gtk_rc_get_style*(widget: PGtkWidget): PGtkStyle{.cdecl, dynlib: gtklib,
    importc: "gtk_rc_get_style".}
proc gtk_rc_get_style_by_paths*(settings: PGtkSettings, widget_path: cstring,
                                class_path: cstring, thetype: GType): PGtkStyle{.
    cdecl, dynlib: gtklib, importc: "gtk_rc_get_style_by_paths".}
proc gtk_rc_reparse_all_for_settings*(settings: PGtkSettings,
                                      force_load: gboolean): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_rc_reparse_all_for_settings".}
proc gtk_rc_find_pixmap_in_path*(settings: PGtkSettings, scanner: PGScanner,
                                 pixmap_file: cstring): cstring{.cdecl,
    dynlib: gtklib, importc: "gtk_rc_find_pixmap_in_path".}
proc gtk_rc_parse*(filename: cstring){.cdecl, dynlib: gtklib,
                                      importc: "gtk_rc_parse".}
proc gtk_rc_parse_string*(rc_string: cstring){.cdecl, dynlib: gtklib,
    importc: "gtk_rc_parse_string".}
proc gtk_rc_reparse_all*(): gboolean{.cdecl, dynlib: gtklib,
                                      importc: "gtk_rc_reparse_all".}
proc gtk_rc_style_get_type*(): GType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_rc_style_get_type".}
proc gtk_rc_style_new*(): PGtkRcStyle{.cdecl, dynlib: gtklib,
                                       importc: "gtk_rc_style_new".}
proc gtk_rc_style_copy*(orig: PGtkRcStyle): PGtkRcStyle{.cdecl, dynlib: gtklib,
    importc: "gtk_rc_style_copy".}
proc gtk_rc_style_ref*(rc_style: PGtkRcStyle){.cdecl, dynlib: gtklib,
    importc: "gtk_rc_style_ref".}
proc gtk_rc_style_unref*(rc_style: PGtkRcStyle){.cdecl, dynlib: gtklib,
    importc: "gtk_rc_style_unref".}
proc gtk_rc_find_module_in_path*(module_file: cstring): cstring{.cdecl,
    dynlib: gtklib, importc: "gtk_rc_find_module_in_path".}
proc gtk_rc_get_theme_dir*(): cstring{.cdecl, dynlib: gtklib,
                                      importc: "gtk_rc_get_theme_dir".}
proc gtk_rc_get_module_dir*(): cstring{.cdecl, dynlib: gtklib,
                                       importc: "gtk_rc_get_module_dir".}
proc gtk_rc_get_im_module_path*(): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_rc_get_im_module_path".}
proc gtk_rc_get_im_module_file*(): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_rc_get_im_module_file".}
proc gtk_rc_scanner_new*(): PGScanner{.cdecl, dynlib: gtklib,
                                       importc: "gtk_rc_scanner_new".}
proc gtk_rc_parse_color*(scanner: PGScanner, color: PGdkColor): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_rc_parse_color".}
proc gtk_rc_parse_state*(scanner: PGScanner, state: PGtkStateType): guint{.
    cdecl, dynlib: gtklib, importc: "gtk_rc_parse_state".}
proc gtk_rc_parse_priority*(scanner: PGScanner, priority: PGtkPathPriorityType): guint{.
    cdecl, dynlib: gtklib, importc: "gtk_rc_parse_priority".}
proc gtk_rc_style_lookup_rc_property*(rc_style: PGtkRcStyle,
                                        type_name: TGQuark,
                                        property_name: TGQuark): PGtkRcProperty{.
    cdecl, dynlib: gtklib, importc: "_gtk_rc_style_lookup_rc_property".}
proc gtk_rc_context_get_default_font_name*(settings: PGtkSettings): cstring{.
    cdecl, dynlib: gtklib, importc: "_gtk_rc_context_get_default_font_name".}
proc GTK_TYPE_STYLE*(): GType
proc GTK_STYLE*(anObject: pointer): PGtkStyle
proc GTK_STYLE_CLASS*(klass: pointer): PGtkStyleClass
proc GTK_IS_STYLE*(anObject: pointer): bool
proc GTK_IS_STYLE_CLASS*(klass: pointer): bool
proc GTK_STYLE_GET_CLASS*(obj: pointer): PGtkStyleClass
proc GTK_TYPE_BORDER*(): GType
proc GTK_STYLE_ATTACHED*(style: pointer): bool
proc gtk_style_get_type*(): GType{.cdecl, dynlib: gtklib,
                                   importc: "gtk_style_get_type".}
proc gtk_style_new*(): PGtkStyle{.cdecl, dynlib: gtklib,
                                  importc: "gtk_style_new".}
proc gtk_style_copy*(style: PGtkStyle): PGtkStyle{.cdecl, dynlib: gtklib,
    importc: "gtk_style_copy".}
proc gtk_style_attach*(style: PGtkStyle, window: PGdkWindow): PGtkStyle{.cdecl,
    dynlib: gtklib, importc: "gtk_style_attach".}
proc gtk_style_detach*(style: PGtkStyle){.cdecl, dynlib: gtklib,
    importc: "gtk_style_detach".}
proc gtk_style_set_background*(style: PGtkStyle, window: PGdkWindow,
                               state_type: TGtkStateType){.cdecl,
    dynlib: gtklib, importc: "gtk_style_set_background".}
proc gtk_style_apply_default_background*(style: PGtkStyle, window: PGdkWindow,
    set_bg: gboolean, state_type: TGtkStateType, area: PGdkRectangle, x: gint,
    y: gint, width: gint, height: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_style_apply_default_background".}
proc gtk_style_lookup_icon_set*(style: PGtkStyle, stock_id: cstring): PGtkIconSet{.
    cdecl, dynlib: gtklib, importc: "gtk_style_lookup_icon_set".}
proc gtk_style_render_icon*(style: PGtkStyle, source: PGtkIconSource,
                            direction: TGtkTextDirection, state: TGtkStateType,
                            size: TGtkIconSize, widget: PGtkWidget,
                            detail: cstring): PGdkPixbuf{.cdecl, dynlib: gtklib,
    importc: "gtk_style_render_icon".}
proc gtk_paint_hline*(style: PGtkStyle, window: PGdkWindow,
                      state_type: TGtkStateType, area: PGdkRectangle,
                      widget: PGtkWidget, detail: cstring, x1: gint, x2: gint,
                      y: gint){.cdecl, dynlib: gtklib,
                                importc: "gtk_paint_hline".}
proc gtk_paint_vline*(style: PGtkStyle, window: PGdkWindow,
                      state_type: TGtkStateType, area: PGdkRectangle,
                      widget: PGtkWidget, detail: cstring, y1: gint, y2: gint,
                      x: gint){.cdecl, dynlib: gtklib,
                                importc: "gtk_paint_vline".}
proc gtk_paint_shadow*(style: PGtkStyle, window: PGdkWindow,
                       state_type: TGtkStateType, shadow_type: TGtkShadowType,
                       area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                       x: gint, y: gint, width: gint, height: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_paint_shadow".}
proc gtk_paint_polygon*(style: PGtkStyle, window: PGdkWindow,
                        state_type: TGtkStateType, shadow_type: TGtkShadowType,
                        area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                        points: PGdkPoint, npoints: gint, fill: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_paint_polygon".}
proc gtk_paint_arrow*(style: PGtkStyle, window: PGdkWindow,
                      state_type: TGtkStateType, shadow_type: TGtkShadowType,
                      area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                      arrow_type: TGtkArrowType, fill: gboolean, x: gint,
                      y: gint, width: gint, height: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_paint_arrow".}
proc gtk_paint_diamond*(style: PGtkStyle, window: PGdkWindow,
                        state_type: TGtkStateType, shadow_type: TGtkShadowType,
                        area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                        x: gint, y: gint, width: gint, height: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_paint_diamond".}
proc gtk_paint_box*(style: PGtkStyle, window: PGdkWindow,
                    state_type: TGtkStateType, shadow_type: TGtkShadowType,
                    area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                    x: gint, y: gint, width: gint, height: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_paint_box".}
proc gtk_paint_flat_box*(style: PGtkStyle, window: PGdkWindow,
                         state_type: TGtkStateType, shadow_type: TGtkShadowType,
                         area: PGdkRectangle, widget: PGtkWidget,
                         detail: cstring, x: gint, y: gint, width: gint,
                         height: gint){.cdecl, dynlib: gtklib,
                                        importc: "gtk_paint_flat_box".}
proc gtk_paint_check*(style: PGtkStyle, window: PGdkWindow,
                      state_type: TGtkStateType, shadow_type: TGtkShadowType,
                      area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                      x: gint, y: gint, width: gint, height: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_paint_check".}
proc gtk_paint_option*(style: PGtkStyle, window: PGdkWindow,
                       state_type: TGtkStateType, shadow_type: TGtkShadowType,
                       area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                       x: gint, y: gint, width: gint, height: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_paint_option".}
proc gtk_paint_tab*(style: PGtkStyle, window: PGdkWindow,
                    state_type: TGtkStateType, shadow_type: TGtkShadowType,
                    area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                    x: gint, y: gint, width: gint, height: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_paint_tab".}
proc gtk_paint_shadow_gap*(style: PGtkStyle, window: PGdkWindow,
                           state_type: TGtkStateType,
                           shadow_type: TGtkShadowType, area: PGdkRectangle,
                           widget: PGtkWidget, detail: cstring, x: gint, y: gint,
                           width: gint, height: gint,
                           gap_side: TGtkPositionType, gap_x: gint,
                           gap_width: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_paint_shadow_gap".}
proc gtk_paint_box_gap*(style: PGtkStyle, window: PGdkWindow,
                        state_type: TGtkStateType, shadow_type: TGtkShadowType,
                        area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                        x: gint, y: gint, width: gint, height: gint,
                        gap_side: TGtkPositionType, gap_x: gint, gap_width: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_paint_box_gap".}
proc gtk_paint_extension*(style: PGtkStyle, window: PGdkWindow,
                          state_type: TGtkStateType,
                          shadow_type: TGtkShadowType, area: PGdkRectangle,
                          widget: PGtkWidget, detail: cstring, x: gint, y: gint,
                          width: gint, height: gint, gap_side: TGtkPositionType){.
    cdecl, dynlib: gtklib, importc: "gtk_paint_extension".}
proc gtk_paint_focus*(style: PGtkStyle, window: PGdkWindow,
                      state_type: TGtkStateType, area: PGdkRectangle,
                      widget: PGtkWidget, detail: cstring, x: gint, y: gint,
                      width: gint, height: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_paint_focus".}
proc gtk_paint_slider*(style: PGtkStyle, window: PGdkWindow,
                       state_type: TGtkStateType, shadow_type: TGtkShadowType,
                       area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                       x: gint, y: gint, width: gint, height: gint,
                       orientation: TGtkOrientation){.cdecl, dynlib: gtklib,
    importc: "gtk_paint_slider".}
proc gtk_paint_handle*(style: PGtkStyle, window: PGdkWindow,
                       state_type: TGtkStateType, shadow_type: TGtkShadowType,
                       area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                       x: gint, y: gint, width: gint, height: gint,
                       orientation: TGtkOrientation){.cdecl, dynlib: gtklib,
    importc: "gtk_paint_handle".}
proc gtk_paint_expander*(style: PGtkStyle, window: PGdkWindow,
                         state_type: TGtkStateType, area: PGdkRectangle,
                         widget: PGtkWidget, detail: cstring, x: gint, y: gint,
                         expander_style: TGtkExpanderStyle){.cdecl,
    dynlib: gtklib, importc: "gtk_paint_expander".}
proc gtk_paint_layout*(style: PGtkStyle, window: PGdkWindow,
                       state_type: TGtkStateType, use_text: gboolean,
                       area: PGdkRectangle, widget: PGtkWidget, detail: cstring,
                       x: gint, y: gint, layout: PPangoLayout){.cdecl,
    dynlib: gtklib, importc: "gtk_paint_layout".}
proc gtk_paint_resize_grip*(style: PGtkStyle, window: PGdkWindow,
                            state_type: TGtkStateType, area: PGdkRectangle,
                            widget: PGtkWidget, detail: cstring,
                            edge: TGdkWindowEdge, x: gint, y: gint, width: gint,
                            height: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_paint_resize_grip".}
proc gtk_border_get_type*(): GType{.cdecl, dynlib: gtklib,
                                    importc: "gtk_border_get_type".}
proc gtk_border_copy*(border: PGtkBorder): PGtkBorder{.cdecl, dynlib: gtklib,
    importc: "gtk_border_copy".}
proc gtk_border_free*(border: PGtkBorder){.cdecl, dynlib: gtklib,
    importc: "gtk_border_free".}
proc gtk_style_peek_property_value*(style: PGtkStyle, widget_type: GType,
                                      pspec: PGParamSpec,
                                      parser: TGtkRcPropertyParser): PGValue{.
    cdecl, dynlib: gtklib, importc: "_gtk_style_peek_property_value".}
proc gtk_get_insertion_cursor_gc*(widget: PGtkWidget, is_primary: gboolean): PGdkGC{.
    cdecl, dynlib: gtklib, importc: "_gtk_get_insertion_cursor_gc".}
proc gtk_draw_insertion_cursor*(widget: PGtkWidget, drawable: PGdkDrawable,
                                  gc: PGdkGC, location: PGdkRectangle,
                                  direction: TGtkTextDirection,
                                  draw_arrow: gboolean){.cdecl, dynlib: gtklib,
    importc: "_gtk_draw_insertion_cursor".}
const
  bm_TGtkRange_inverted* = 0x00000001'i16
  bp_TGtkRange_inverted* = 0'i16
  bm_TGtkRange_flippable* = 0x00000002'i16
  bp_TGtkRange_flippable* = 1'i16
  bm_TGtkRange_has_stepper_a* = 0x00000004'i16
  bp_TGtkRange_has_stepper_a* = 2'i16
  bm_TGtkRange_has_stepper_b* = 0x00000008'i16
  bp_TGtkRange_has_stepper_b* = 3'i16
  bm_TGtkRange_has_stepper_c* = 0x00000010'i16
  bp_TGtkRange_has_stepper_c* = 4'i16
  bm_TGtkRange_has_stepper_d* = 0x00000020'i16
  bp_TGtkRange_has_stepper_d* = 5'i16
  bm_TGtkRange_need_recalc* = 0x00000040'i16
  bp_TGtkRange_need_recalc* = 6'i16
  bm_TGtkRange_slider_size_fixed* = 0x00000080'i16
  bp_TGtkRange_slider_size_fixed* = 7'i16
  bm_TGtkRange_trough_click_forward* = 0x00000001'i16
  bp_TGtkRange_trough_click_forward* = 0'i16
  bm_TGtkRange_update_pending* = 0x00000002'i16
  bp_TGtkRange_update_pending* = 1'i16

proc GTK_TYPE_RANGE*(): GType
proc GTK_RANGE*(obj: pointer): PGtkRange
proc GTK_RANGE_CLASS*(klass: pointer): PGtkRangeClass
proc GTK_IS_RANGE*(obj: pointer): bool
proc GTK_IS_RANGE_CLASS*(klass: pointer): bool
proc GTK_RANGE_GET_CLASS*(obj: pointer): PGtkRangeClass
proc inverted*(a: var TGtkRange): guint
proc set_inverted*(a: var TGtkRange, `inverted`: guint)
proc flippable*(a: var TGtkRange): guint
proc set_flippable*(a: var TGtkRange, `flippable`: guint)
proc has_stepper_a*(a: var TGtkRange): guint
proc set_has_stepper_a*(a: var TGtkRange, `has_stepper_a`: guint)
proc has_stepper_b*(a: var TGtkRange): guint
proc set_has_stepper_b*(a: var TGtkRange, `has_stepper_b`: guint)
proc has_stepper_c*(a: var TGtkRange): guint
proc set_has_stepper_c*(a: var TGtkRange, `has_stepper_c`: guint)
proc has_stepper_d*(a: var TGtkRange): guint
proc set_has_stepper_d*(a: var TGtkRange, `has_stepper_d`: guint)
proc need_recalc*(a: var TGtkRange): guint
proc set_need_recalc*(a: var TGtkRange, `need_recalc`: guint)
proc slider_size_fixed*(a: var TGtkRange): guint
proc set_slider_size_fixed*(a: var TGtkRange, `slider_size_fixed`: guint)
proc trough_click_forward*(a: var TGtkRange): guint
proc set_trough_click_forward*(a: var TGtkRange, `trough_click_forward`: guint)
proc update_pending*(a: var TGtkRange): guint
proc set_update_pending*(a: var TGtkRange, `update_pending`: guint)
proc gtk_range_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_range_get_type".}
proc gtk_range_set_update_policy*(range: PGtkRange, policy: TGtkUpdateType){.
    cdecl, dynlib: gtklib, importc: "gtk_range_set_update_policy".}
proc gtk_range_get_update_policy*(range: PGtkRange): TGtkUpdateType{.cdecl,
    dynlib: gtklib, importc: "gtk_range_get_update_policy".}
proc gtk_range_set_adjustment*(range: PGtkRange, adjustment: PGtkAdjustment){.
    cdecl, dynlib: gtklib, importc: "gtk_range_set_adjustment".}
proc gtk_range_get_adjustment*(range: PGtkRange): PGtkAdjustment{.cdecl,
    dynlib: gtklib, importc: "gtk_range_get_adjustment".}
proc gtk_range_set_inverted*(range: PGtkRange, setting: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_range_set_inverted".}
proc gtk_range_get_inverted*(range: PGtkRange): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_range_get_inverted".}
proc gtk_range_set_increments*(range: PGtkRange, step: gdouble, page: gdouble){.
    cdecl, dynlib: gtklib, importc: "gtk_range_set_increments".}
proc gtk_range_set_range*(range: PGtkRange, min: gdouble, max: gdouble){.cdecl,
    dynlib: gtklib, importc: "gtk_range_set_range".}
proc gtk_range_set_value*(range: PGtkRange, value: gdouble){.cdecl,
    dynlib: gtklib, importc: "gtk_range_set_value".}
proc gtk_range_get_value*(range: PGtkRange): gdouble{.cdecl, dynlib: gtklib,
    importc: "gtk_range_get_value".}
const
  bm_TGtkScale_draw_value* = 0x00000001'i16
  bp_TGtkScale_draw_value* = 0'i16
  bm_TGtkScale_value_pos* = 0x00000006'i16
  bp_TGtkScale_value_pos* = 1'i16

proc GTK_TYPE_SCALE*(): GType
proc GTK_SCALE*(obj: pointer): PGtkScale
proc GTK_SCALE_CLASS*(klass: pointer): PGtkScaleClass
proc GTK_IS_SCALE*(obj: pointer): bool
proc GTK_IS_SCALE_CLASS*(klass: pointer): bool
proc GTK_SCALE_GET_CLASS*(obj: pointer): PGtkScaleClass
proc draw_value*(a: var TGtkScale): guint
proc set_draw_value*(a: var TGtkScale, `draw_value`: guint)
proc value_pos*(a: var TGtkScale): guint
proc set_value_pos*(a: var TGtkScale, `value_pos`: guint)
proc gtk_scale_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_scale_get_type".}
proc gtk_scale_set_digits*(scale: PGtkScale, digits: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_scale_set_digits".}
proc gtk_scale_get_digits*(scale: PGtkScale): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_scale_get_digits".}
proc gtk_scale_set_draw_value*(scale: PGtkScale, draw_value: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_scale_set_draw_value".}
proc gtk_scale_get_draw_value*(scale: PGtkScale): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_scale_get_draw_value".}
proc gtk_scale_set_value_pos*(scale: PGtkScale, pos: TGtkPositionType){.cdecl,
    dynlib: gtklib, importc: "gtk_scale_set_value_pos".}
proc gtk_scale_get_value_pos*(scale: PGtkScale): TGtkPositionType{.cdecl,
    dynlib: gtklib, importc: "gtk_scale_get_value_pos".}
proc gtk_scale_get_value_size*(scale: PGtkScale, width: Pgint, height: Pgint){.
    cdecl, dynlib: gtklib, importc: "_gtk_scale_get_value_size".}
proc gtk_scale_format_value*(scale: PGtkScale, value: gdouble): cstring{.cdecl,
    dynlib: gtklib, importc: "_gtk_scale_format_value".}
proc GTK_TYPE_HSCALE*(): GType
proc GTK_HSCALE*(obj: pointer): PGtkHScale
proc GTK_HSCALE_CLASS*(klass: pointer): PGtkHScaleClass
proc GTK_IS_HSCALE*(obj: pointer): bool
proc GTK_IS_HSCALE_CLASS*(klass: pointer): bool
proc GTK_HSCALE_GET_CLASS*(obj: pointer): PGtkHScaleClass
proc gtk_hscale_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_hscale_get_type".}
proc gtk_hscale_new*(adjustment: PGtkAdjustment): PGtkHScale{.cdecl,
    dynlib: gtklib, importc: "gtk_hscale_new".}
proc gtk_hscale_new_with_range*(min: gdouble, max: gdouble, step: gdouble): PGtkHScale{.
    cdecl, dynlib: gtklib, importc: "gtk_hscale_new_with_range".}
proc GTK_TYPE_SCROLLBAR*(): GType
proc GTK_SCROLLBAR*(obj: pointer): PGtkScrollbar
proc GTK_SCROLLBAR_CLASS*(klass: pointer): PGtkScrollbarClass
proc GTK_IS_SCROLLBAR*(obj: pointer): bool
proc GTK_IS_SCROLLBAR_CLASS*(klass: pointer): bool
proc GTK_SCROLLBAR_GET_CLASS*(obj: pointer): PGtkScrollbarClass
proc gtk_scrollbar_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_scrollbar_get_type".}
proc GTK_TYPE_HSCROLLBAR*(): GType
proc GTK_HSCROLLBAR*(obj: pointer): PGtkHScrollbar
proc GTK_HSCROLLBAR_CLASS*(klass: pointer): PGtkHScrollbarClass
proc GTK_IS_HSCROLLBAR*(obj: pointer): bool
proc GTK_IS_HSCROLLBAR_CLASS*(klass: pointer): bool
proc GTK_HSCROLLBAR_GET_CLASS*(obj: pointer): PGtkHScrollbarClass
proc gtk_hscrollbar_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_hscrollbar_get_type".}
proc gtk_hscrollbar_new*(adjustment: PGtkAdjustment): PGtkHScrollbar{.cdecl,
    dynlib: gtklib, importc: "gtk_hscrollbar_new".}
proc GTK_TYPE_SEPARATOR*(): GType
proc GTK_SEPARATOR*(obj: pointer): PGtkSeparator
proc GTK_SEPARATOR_CLASS*(klass: pointer): PGtkSeparatorClass
proc GTK_IS_SEPARATOR*(obj: pointer): bool
proc GTK_IS_SEPARATOR_CLASS*(klass: pointer): bool
proc GTK_SEPARATOR_GET_CLASS*(obj: pointer): PGtkSeparatorClass
proc gtk_separator_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_separator_get_type".}
proc GTK_TYPE_HSEPARATOR*(): GType
proc GTK_HSEPARATOR*(obj: pointer): PGtkHSeparator
proc GTK_HSEPARATOR_CLASS*(klass: pointer): PGtkHSeparatorClass
proc GTK_IS_HSEPARATOR*(obj: pointer): bool
proc GTK_IS_HSEPARATOR_CLASS*(klass: pointer): bool
proc GTK_HSEPARATOR_GET_CLASS*(obj: pointer): PGtkHSeparatorClass
proc gtk_hseparator_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_hseparator_get_type".}
proc gtk_hseparator_new*(): PGtkHSeparator{.cdecl, dynlib: gtklib,
                                        importc: "gtk_hseparator_new".}
proc GTK_TYPE_ICON_FACTORY*(): GType
proc GTK_ICON_FACTORY*(anObject: pointer): PGtkIconFactory
proc GTK_ICON_FACTORY_CLASS*(klass: pointer): PGtkIconFactoryClass
proc GTK_IS_ICON_FACTORY*(anObject: pointer): bool
proc GTK_IS_ICON_FACTORY_CLASS*(klass: pointer): bool
proc GTK_ICON_FACTORY_GET_CLASS*(obj: pointer): PGtkIconFactoryClass
proc GTK_TYPE_ICON_SET*(): GType
proc GTK_TYPE_ICON_SOURCE*(): GType
proc gtk_icon_factory_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_icon_factory_get_type".}
proc gtk_icon_factory_new*(): PGtkIconFactory{.cdecl, dynlib: gtklib,
    importc: "gtk_icon_factory_new".}
proc gtk_icon_factory_add*(factory: PGtkIconFactory, stock_id: cstring,
                           icon_set: PGtkIconSet){.cdecl, dynlib: gtklib,
    importc: "gtk_icon_factory_add".}
proc gtk_icon_factory_lookup*(factory: PGtkIconFactory, stock_id: cstring): PGtkIconSet{.
    cdecl, dynlib: gtklib, importc: "gtk_icon_factory_lookup".}
proc gtk_icon_factory_add_default*(factory: PGtkIconFactory){.cdecl,
    dynlib: gtklib, importc: "gtk_icon_factory_add_default".}
proc gtk_icon_factory_remove_default*(factory: PGtkIconFactory){.cdecl,
    dynlib: gtklib, importc: "gtk_icon_factory_remove_default".}
proc gtk_icon_factory_lookup_default*(stock_id: cstring): PGtkIconSet{.cdecl,
    dynlib: gtklib, importc: "gtk_icon_factory_lookup_default".}
proc gtk_icon_size_lookup*(size: TGtkIconSize, width: Pgint, height: Pgint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_icon_size_lookup".}
proc gtk_icon_size_register*(name: cstring, width: gint, height: gint): TGtkIconSize{.
    cdecl, dynlib: gtklib, importc: "gtk_icon_size_register".}
proc gtk_icon_size_register_alias*(alias: cstring, target: TGtkIconSize){.cdecl,
    dynlib: gtklib, importc: "gtk_icon_size_register_alias".}
proc gtk_icon_size_from_name*(name: cstring): TGtkIconSize{.cdecl,
    dynlib: gtklib, importc: "gtk_icon_size_from_name".}
proc gtk_icon_size_get_name*(size: TGtkIconSize): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_icon_size_get_name".}
proc gtk_icon_set_get_type*(): GType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_icon_set_get_type".}
proc gtk_icon_set_new*(): PGtkIconSet{.cdecl, dynlib: gtklib,
                                       importc: "gtk_icon_set_new".}
proc gtk_icon_set_new_from_pixbuf*(pixbuf: PGdkPixbuf): PGtkIconSet{.cdecl,
    dynlib: gtklib, importc: "gtk_icon_set_new_from_pixbuf".}
proc gtk_icon_set_ref*(icon_set: PGtkIconSet): PGtkIconSet{.cdecl,
    dynlib: gtklib, importc: "gtk_icon_set_ref".}
proc gtk_icon_set_unref*(icon_set: PGtkIconSet){.cdecl, dynlib: gtklib,
    importc: "gtk_icon_set_unref".}
proc gtk_icon_set_copy*(icon_set: PGtkIconSet): PGtkIconSet{.cdecl,
    dynlib: gtklib, importc: "gtk_icon_set_copy".}
proc gtk_icon_set_render_icon*(icon_set: PGtkIconSet, style: PGtkStyle,
                               direction: TGtkTextDirection,
                               state: TGtkStateType, size: TGtkIconSize,
                               widget: PGtkWidget, detail: cstring): PGdkPixbuf{.
    cdecl, dynlib: gtklib, importc: "gtk_icon_set_render_icon".}
proc gtk_icon_set_add_source*(icon_set: PGtkIconSet, source: PGtkIconSource){.
    cdecl, dynlib: gtklib, importc: "gtk_icon_set_add_source".}
proc gtk_icon_set_get_sizes*(icon_set: PGtkIconSet, sizes: PPGtkIconSize,
                             n_sizes: pgint){.cdecl, dynlib: gtklib,
    importc: "gtk_icon_set_get_sizes".}
proc gtk_icon_source_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_icon_source_get_type".}
proc gtk_icon_source_new*(): PGtkIconSource{.cdecl, dynlib: gtklib,
    importc: "gtk_icon_source_new".}
proc gtk_icon_source_copy*(source: PGtkIconSource): PGtkIconSource{.cdecl,
    dynlib: gtklib, importc: "gtk_icon_source_copy".}
proc gtk_icon_source_free*(source: PGtkIconSource){.cdecl, dynlib: gtklib,
    importc: "gtk_icon_source_free".}
proc gtk_icon_source_set_filename*(source: PGtkIconSource, filename: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_icon_source_set_filename".}
proc gtk_icon_source_set_pixbuf*(source: PGtkIconSource, pixbuf: PGdkPixbuf){.
    cdecl, dynlib: gtklib, importc: "gtk_icon_source_set_pixbuf".}
proc gtk_icon_source_get_filename*(source: PGtkIconSource): cstring{.cdecl,
    dynlib: gtklib, importc: "gtk_icon_source_get_filename".}
proc gtk_icon_source_get_pixbuf*(source: PGtkIconSource): PGdkPixbuf{.cdecl,
    dynlib: gtklib, importc: "gtk_icon_source_get_pixbuf".}
proc gtk_icon_source_set_direction_wildcarded*(source: PGtkIconSource,
    setting: gboolean){.cdecl, dynlib: gtklib,
                        importc: "gtk_icon_source_set_direction_wildcarded".}
proc gtk_icon_source_set_state_wildcarded*(source: PGtkIconSource,
    setting: gboolean){.cdecl, dynlib: gtklib,
                        importc: "gtk_icon_source_set_state_wildcarded".}
proc gtk_icon_source_set_size_wildcarded*(source: PGtkIconSource,
    setting: gboolean){.cdecl, dynlib: gtklib,
                        importc: "gtk_icon_source_set_size_wildcarded".}
proc gtk_icon_source_get_size_wildcarded*(source: PGtkIconSource): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_icon_source_get_size_wildcarded".}
proc gtk_icon_source_get_state_wildcarded*(source: PGtkIconSource): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_icon_source_get_state_wildcarded".}
proc gtk_icon_source_get_direction_wildcarded*(source: PGtkIconSource): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_icon_source_get_direction_wildcarded".}
proc gtk_icon_source_set_direction*(source: PGtkIconSource,
                                    direction: TGtkTextDirection){.cdecl,
    dynlib: gtklib, importc: "gtk_icon_source_set_direction".}
proc gtk_icon_source_set_state*(source: PGtkIconSource, state: TGtkStateType){.
    cdecl, dynlib: gtklib, importc: "gtk_icon_source_set_state".}
proc gtk_icon_source_set_size*(source: PGtkIconSource, size: TGtkIconSize){.
    cdecl, dynlib: gtklib, importc: "gtk_icon_source_set_size".}
proc gtk_icon_source_get_direction*(source: PGtkIconSource): TGtkTextDirection{.
    cdecl, dynlib: gtklib, importc: "gtk_icon_source_get_direction".}
proc gtk_icon_source_get_state*(source: PGtkIconSource): TGtkStateType{.cdecl,
    dynlib: gtklib, importc: "gtk_icon_source_get_state".}
proc gtk_icon_source_get_size*(source: PGtkIconSource): TGtkIconSize{.cdecl,
    dynlib: gtklib, importc: "gtk_icon_source_get_size".}
proc gtk_icon_set_invalidate_caches*(){.cdecl, dynlib: gtklib,
    importc: "_gtk_icon_set_invalidate_caches".}
proc gtk_icon_factory_list_ids*(): PGSList{.cdecl, dynlib: gtklib,
    importc: "_gtk_icon_factory_list_ids".}
proc GTK_TYPE_IMAGE*(): GType
proc GTK_IMAGE*(obj: pointer): PGtkImage
proc GTK_IMAGE_CLASS*(klass: pointer): PGtkImageClass
proc GTK_IS_IMAGE*(obj: pointer): bool
proc GTK_IS_IMAGE_CLASS*(klass: pointer): bool
proc GTK_IMAGE_GET_CLASS*(obj: pointer): PGtkImageClass
proc gtk_image_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_image_get_type".}
proc gtk_image_new*(): PGtkImage{.cdecl, dynlib: gtklib,
                                   importc: "gtk_image_new".}
proc gtk_image_new_from_pixmap*(pixmap: PGdkPixmap, mask: PGdkBitmap): PGtkImage{.
    cdecl, dynlib: gtklib, importc: "gtk_image_new_from_pixmap".}
proc gtk_image_new_from_image*(image: PGdkImage, mask: PGdkBitmap): PGtkImage{.
    cdecl, dynlib: gtklib, importc: "gtk_image_new_from_image".}
proc gtk_image_new_from_file*(filename: cstring): PGtkImage{.cdecl,
    dynlib: gtklib, importc: "gtk_image_new_from_file".}
proc gtk_image_new_from_pixbuf*(pixbuf: PGdkPixbuf): PGtkImage{.cdecl,
    dynlib: gtklib, importc: "gtk_image_new_from_pixbuf".}
proc gtk_image_new_from_stock*(stock_id: cstring, size: TGtkIconSize): PGtkImage{.
    cdecl, dynlib: gtklib, importc: "gtk_image_new_from_stock".}
proc gtk_image_new_from_icon_set*(icon_set: PGtkIconSet, size: TGtkIconSize): PGtkImage{.
    cdecl, dynlib: gtklib, importc: "gtk_image_new_from_icon_set".}
proc gtk_image_new_from_animation*(animation: PGdkPixbufAnimation): PGtkImage{.
    cdecl, dynlib: gtklib, importc: "gtk_image_new_from_animation".}
proc gtk_image_set_from_pixmap*(image: PGtkImage, pixmap: PGdkPixmap,
                                mask: PGdkBitmap){.cdecl, dynlib: gtklib,
    importc: "gtk_image_set_from_pixmap".}
proc gtk_image_set_from_image*(image: PGtkImage, gdk_image: PGdkImage,
                               mask: PGdkBitmap){.cdecl, dynlib: gtklib,
    importc: "gtk_image_set_from_image".}
proc gtk_image_set_from_file*(image: PGtkImage, filename: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_image_set_from_file".}
proc gtk_image_set_from_pixbuf*(image: PGtkImage, pixbuf: PGdkPixbuf){.cdecl,
    dynlib: gtklib, importc: "gtk_image_set_from_pixbuf".}
proc gtk_image_set_from_stock*(image: PGtkImage, stock_id: cstring,
                               size: TGtkIconSize){.cdecl, dynlib: gtklib,
    importc: "gtk_image_set_from_stock".}
proc gtk_image_set_from_icon_set*(image: PGtkImage, icon_set: PGtkIconSet,
                                  size: TGtkIconSize){.cdecl, dynlib: gtklib,
    importc: "gtk_image_set_from_icon_set".}
proc gtk_image_set_from_animation*(image: PGtkImage,
                                   animation: PGdkPixbufAnimation){.cdecl,
    dynlib: gtklib, importc: "gtk_image_set_from_animation".}
proc gtk_image_get_storage_type*(image: PGtkImage): TGtkImageType{.cdecl,
    dynlib: gtklib, importc: "gtk_image_get_storage_type".}
proc gtk_image_get_pixbuf*(image: PGtkImage): PGdkPixbuf{.cdecl, dynlib: gtklib,
    importc: "gtk_image_get_pixbuf".}
proc gtk_image_get_stock*(image: PGtkImage, stock_id: PPgchar,
                          size: PGtkIconSize){.cdecl, dynlib: gtklib,
    importc: "gtk_image_get_stock".}
proc gtk_image_get_animation*(image: PGtkImage): PGdkPixbufAnimation{.cdecl,
    dynlib: gtklib, importc: "gtk_image_get_animation".}
proc GTK_TYPE_IMAGE_MENU_ITEM*(): GType
proc GTK_IMAGE_MENU_ITEM*(obj: pointer): PGtkImageMenuItem
proc GTK_IMAGE_MENU_ITEM_CLASS*(klass: pointer): PGtkImageMenuItemClass
proc GTK_IS_IMAGE_MENU_ITEM*(obj: pointer): bool
proc GTK_IS_IMAGE_MENU_ITEM_CLASS*(klass: pointer): bool
proc GTK_IMAGE_MENU_ITEM_GET_CLASS*(obj: pointer): PGtkImageMenuItemClass
proc gtk_image_menu_item_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_image_menu_item_get_type".}
proc gtk_image_menu_item_new*(): PGtkImageMenuItem{.cdecl, dynlib: gtklib,
    importc: "gtk_image_menu_item_new".}
proc gtk_image_menu_item_new_with_label*(`label`: cstring): PGtkImageMenuItem{.cdecl,
    dynlib: gtklib, importc: "gtk_image_menu_item_new_with_label".}
proc gtk_image_menu_item_new_with_mnemonic*(`label`: cstring): PGtkImageMenuItem{.cdecl,
    dynlib: gtklib, importc: "gtk_image_menu_item_new_with_mnemonic".}
proc gtk_image_menu_item_new_from_stock*(stock_id: cstring,
    accel_group: PGtkAccelGroup): PGtkImageMenuItem{.cdecl, dynlib: gtklib,
    importc: "gtk_image_menu_item_new_from_stock".}
proc gtk_image_menu_item_set_image*(image_menu_item: PGtkImageMenuItem,
                                    image: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_image_menu_item_set_image".}
proc gtk_image_menu_item_get_image*(image_menu_item: PGtkImageMenuItem): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_image_menu_item_get_image".}
const
  bm_TGtkIMContextSimple_in_hex_sequence* = 0x00000001'i16
  bp_TGtkIMContextSimple_in_hex_sequence* = 0'i16

proc GTK_TYPE_IM_CONTEXT_SIMPLE*(): GType
proc GTK_IM_CONTEXT_SIMPLE*(obj: pointer): PGtkIMContextSimple
proc GTK_IM_CONTEXT_SIMPLE_CLASS*(klass: pointer): PGtkIMContextSimpleClass
proc GTK_IS_IM_CONTEXT_SIMPLE*(obj: pointer): bool
proc GTK_IS_IM_CONTEXT_SIMPLE_CLASS*(klass: pointer): bool
proc GTK_IM_CONTEXT_SIMPLE_GET_CLASS*(obj: pointer): PGtkIMContextSimpleClass
proc in_hex_sequence*(a: var TGtkIMContextSimple): guint
proc set_in_hex_sequence*(a: var TGtkIMContextSimple, `in_hex_sequence`: guint)
proc gtk_im_context_simple_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_im_context_simple_get_type".}
proc gtk_im_context_simple_new*(): PGtkIMContext{.cdecl, dynlib: gtklib,
    importc: "gtk_im_context_simple_new".}
proc gtk_im_context_simple_add_table*(context_simple: PGtkIMContextSimple,
                                      data: Pguint16, max_seq_len: gint,
                                      n_seqs: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_im_context_simple_add_table".}
proc GTK_TYPE_IM_MULTICONTEXT*(): GType
proc GTK_IM_MULTICONTEXT*(obj: pointer): PGtkIMMulticontext
proc GTK_IM_MULTICONTEXT_CLASS*(klass: pointer): PGtkIMMulticontextClass
proc GTK_IS_IM_MULTICONTEXT*(obj: pointer): bool
proc GTK_IS_IM_MULTICONTEXT_CLASS*(klass: pointer): bool
proc GTK_IM_MULTICONTEXT_GET_CLASS*(obj: pointer): PGtkIMMulticontextClass
proc gtk_im_multicontext_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_im_multicontext_get_type".}
proc gtk_im_multicontext_new*(): PGtkIMContext{.cdecl, dynlib: gtklib,
    importc: "gtk_im_multicontext_new".}
proc gtk_im_multicontext_append_menuitems*(context: PGtkIMMulticontext,
    menushell: PGtkMenuShell){.cdecl, dynlib: gtklib,
                               importc: "gtk_im_multicontext_append_menuitems".}
proc GTK_TYPE_INPUT_DIALOG*(): GType
proc GTK_INPUT_DIALOG*(obj: pointer): PGtkInputDialog
proc GTK_INPUT_DIALOG_CLASS*(klass: pointer): PGtkInputDialogClass
proc GTK_IS_INPUT_DIALOG*(obj: pointer): bool
proc GTK_IS_INPUT_DIALOG_CLASS*(klass: pointer): bool
proc GTK_INPUT_DIALOG_GET_CLASS*(obj: pointer): PGtkInputDialogClass
proc gtk_input_dialog_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_input_dialog_get_type".}
proc gtk_input_dialog_new*(): PGtkInputDialog{.cdecl, dynlib: gtklib,
    importc: "gtk_input_dialog_new".}
proc GTK_TYPE_INVISIBLE*(): GType
proc GTK_INVISIBLE*(obj: pointer): PGtkInvisible
proc GTK_INVISIBLE_CLASS*(klass: pointer): PGtkInvisibleClass
proc GTK_IS_INVISIBLE*(obj: pointer): bool
proc GTK_IS_INVISIBLE_CLASS*(klass: pointer): bool
proc GTK_INVISIBLE_GET_CLASS*(obj: pointer): PGtkInvisibleClass
proc gtk_invisible_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_invisible_get_type".}
proc gtk_invisible_new*(): PGtkInvisible{.cdecl, dynlib: gtklib,
                                       importc: "gtk_invisible_new".}
proc gtk_invisible_new_for_screen*(screen: PGdkScreen): PGtkInvisible{.cdecl,
    dynlib: gtklib, importc: "gtk_invisible_new_for_screen".}
proc gtk_invisible_set_screen*(invisible: PGtkInvisible, screen: PGdkScreen){.
    cdecl, dynlib: gtklib, importc: "gtk_invisible_set_screen".}
proc gtk_invisible_get_screen*(invisible: PGtkInvisible): PGdkScreen{.cdecl,
    dynlib: gtklib, importc: "gtk_invisible_get_screen".}
proc GTK_TYPE_ITEM_FACTORY*(): GType
proc GTK_ITEM_FACTORY*(anObject: pointer): PGtkItemFactory
proc GTK_ITEM_FACTORY_CLASS*(klass: pointer): PGtkItemFactoryClass
proc GTK_IS_ITEM_FACTORY*(anObject: pointer): bool
proc GTK_IS_ITEM_FACTORY_CLASS*(klass: pointer): bool
proc GTK_ITEM_FACTORY_GET_CLASS*(obj: pointer): PGtkItemFactoryClass
proc gtk_item_factory_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_item_factory_get_type".}
proc gtk_item_factory_new*(container_type: TGtkType, path: cstring,
                           accel_group: PGtkAccelGroup): PGtkItemFactory{.cdecl,
    dynlib: gtklib, importc: "gtk_item_factory_new".}
proc gtk_item_factory_construct*(ifactory: PGtkItemFactory,
                                 container_type: TGtkType, path: cstring,
                                 accel_group: PGtkAccelGroup){.cdecl,
    dynlib: gtklib, importc: "gtk_item_factory_construct".}
proc gtk_item_factory_add_foreign*(accel_widget: PGtkWidget, full_path: cstring,
                                   accel_group: PGtkAccelGroup, keyval: guint,
                                   modifiers: TGdkModifierType){.cdecl,
    dynlib: gtklib, importc: "gtk_item_factory_add_foreign".}
proc gtk_item_factory_from_widget*(widget: PGtkWidget): PGtkItemFactory{.cdecl,
    dynlib: gtklib, importc: "gtk_item_factory_from_widget".}
proc gtk_item_factory_path_from_widget*(widget: PGtkWidget): cstring{.cdecl,
    dynlib: gtklib, importc: "gtk_item_factory_path_from_widget".}
proc gtk_item_factory_get_item*(ifactory: PGtkItemFactory, path: cstring): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_item_factory_get_item".}
proc gtk_item_factory_get_widget*(ifactory: PGtkItemFactory, path: cstring): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_item_factory_get_widget".}
proc gtk_item_factory_get_widget_by_action*(ifactory: PGtkItemFactory,
    action: guint): PGtkWidget{.cdecl, dynlib: gtklib, importc: "gtk_item_factory_get_widget_by_action".}
proc gtk_item_factory_get_item_by_action*(ifactory: PGtkItemFactory,
    action: guint): PGtkWidget{.cdecl, dynlib: gtklib,
                                importc: "gtk_item_factory_get_item_by_action".}
proc gtk_item_factory_create_item*(ifactory: PGtkItemFactory,
                                   entry: PGtkItemFactoryEntry,
                                   callback_data: gpointer, callback_type: guint){.
    cdecl, dynlib: gtklib, importc: "gtk_item_factory_create_item".}
proc gtk_item_factory_create_items*(ifactory: PGtkItemFactory, n_entries: guint,
                                    entries: PGtkItemFactoryEntry,
                                    callback_data: gpointer){.cdecl,
    dynlib: gtklib, importc: "gtk_item_factory_create_items".}
proc gtk_item_factory_delete_item*(ifactory: PGtkItemFactory, path: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_item_factory_delete_item".}
proc gtk_item_factory_delete_entry*(ifactory: PGtkItemFactory,
                                    entry: PGtkItemFactoryEntry){.cdecl,
    dynlib: gtklib, importc: "gtk_item_factory_delete_entry".}
proc gtk_item_factory_delete_entries*(ifactory: PGtkItemFactory,
                                      n_entries: guint,
                                      entries: PGtkItemFactoryEntry){.cdecl,
    dynlib: gtklib, importc: "gtk_item_factory_delete_entries".}
proc gtk_item_factory_popup*(ifactory: PGtkItemFactory, x: guint, y: guint,
                             mouse_button: guint, time: guint32){.cdecl,
    dynlib: gtklib, importc: "gtk_item_factory_popup".}
proc gtk_item_factory_popup_with_data*(ifactory: PGtkItemFactory,
                                       popup_data: gpointer,
                                       destroy: TGtkDestroyNotify, x: guint,
                                       y: guint, mouse_button: guint,
                                       time: guint32){.cdecl, dynlib: gtklib,
    importc: "gtk_item_factory_popup_with_data".}
proc gtk_item_factory_popup_data*(ifactory: PGtkItemFactory): gpointer{.cdecl,
    dynlib: gtklib, importc: "gtk_item_factory_popup_data".}
proc gtk_item_factory_popup_data_from_widget*(widget: PGtkWidget): gpointer{.
    cdecl, dynlib: gtklib, importc: "gtk_item_factory_popup_data_from_widget".}
proc gtk_item_factory_set_translate_func*(ifactory: PGtkItemFactory,
    fun: TGtkTranslateFunc, data: gpointer, notify: TGtkDestroyNotify){.cdecl,
    dynlib: gtklib, importc: "gtk_item_factory_set_translate_func".}
proc GTK_TYPE_LAYOUT*(): GType
proc GTK_LAYOUT*(obj: pointer): PGtkLayout
proc GTK_LAYOUT_CLASS*(klass: pointer): PGtkLayoutClass
proc GTK_IS_LAYOUT*(obj: pointer): bool
proc GTK_IS_LAYOUT_CLASS*(klass: pointer): bool
proc GTK_LAYOUT_GET_CLASS*(obj: pointer): PGtkLayoutClass
proc gtk_layout_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_layout_get_type".}
proc gtk_layout_new*(hadjustment: PGtkAdjustment, vadjustment: PGtkAdjustment): PGtkLayout{.
    cdecl, dynlib: gtklib, importc: "gtk_layout_new".}
proc gtk_layout_put*(layout: PGtkLayout, child_widget: PGtkWidget, x: gint,
                     y: gint){.cdecl, dynlib: gtklib, importc: "gtk_layout_put".}
proc gtk_layout_move*(layout: PGtkLayout, child_widget: PGtkWidget, x: gint,
                      y: gint){.cdecl, dynlib: gtklib,
                                importc: "gtk_layout_move".}
proc gtk_layout_set_size*(layout: PGtkLayout, width: guint, height: guint){.
    cdecl, dynlib: gtklib, importc: "gtk_layout_set_size".}
proc gtk_layout_get_size*(layout: PGtkLayout, width: Pguint, height: Pguint){.
    cdecl, dynlib: gtklib, importc: "gtk_layout_get_size".}
proc gtk_layout_get_hadjustment*(layout: PGtkLayout): PGtkAdjustment{.cdecl,
    dynlib: gtklib, importc: "gtk_layout_get_hadjustment".}
proc gtk_layout_get_vadjustment*(layout: PGtkLayout): PGtkAdjustment{.cdecl,
    dynlib: gtklib, importc: "gtk_layout_get_vadjustment".}
proc gtk_layout_set_hadjustment*(layout: PGtkLayout, adjustment: PGtkAdjustment){.
    cdecl, dynlib: gtklib, importc: "gtk_layout_set_hadjustment".}
proc gtk_layout_set_vadjustment*(layout: PGtkLayout, adjustment: PGtkAdjustment){.
    cdecl, dynlib: gtklib, importc: "gtk_layout_set_vadjustment".}
const
  bm_TGtkList_selection_mode* = 0x00000003'i16
  bp_TGtkList_selection_mode* = 0'i16
  bm_TGtkList_drag_selection* = 0x00000004'i16
  bp_TGtkList_drag_selection* = 2'i16
  bm_TGtkList_add_mode* = 0x00000008'i16
  bp_TGtkList_add_mode* = 3'i16

proc GTK_TYPE_LIST*(): GType
proc GTK_LIST*(obj: pointer): PGtkList
proc GTK_LIST_CLASS*(klass: pointer): PGtkListClass
proc GTK_IS_LIST*(obj: pointer): bool
proc GTK_IS_LIST_CLASS*(klass: pointer): bool
proc GTK_LIST_GET_CLASS*(obj: pointer): PGtkListClass
proc selection_mode*(a: var TGtkList): guint
proc set_selection_mode*(a: var TGtkList, `selection_mode`: guint)
proc drag_selection*(a: var TGtkList): guint
proc set_drag_selection*(a: var TGtkList, `drag_selection`: guint)
proc add_mode*(a: var TGtkList): guint
proc set_add_mode*(a: var TGtkList, `add_mode`: guint)
proc gtk_list_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                     importc: "gtk_list_get_type".}
proc gtk_list_new*(): PGtkList{.cdecl, dynlib: gtklib, importc: "gtk_list_new".}
proc gtk_list_insert_items*(list: PGtkList, items: PGList, position: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_list_insert_items".}
proc gtk_list_append_items*(list: PGtkList, items: PGList){.cdecl,
    dynlib: gtklib, importc: "gtk_list_append_items".}
proc gtk_list_prepend_items*(list: PGtkList, items: PGList){.cdecl,
    dynlib: gtklib, importc: "gtk_list_prepend_items".}
proc gtk_list_remove_items*(list: PGtkList, items: PGList){.cdecl,
    dynlib: gtklib, importc: "gtk_list_remove_items".}
proc gtk_list_remove_items_no_unref*(list: PGtkList, items: PGList){.cdecl,
    dynlib: gtklib, importc: "gtk_list_remove_items_no_unref".}
proc gtk_list_clear_items*(list: PGtkList, start: gint, theEnd: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_list_clear_items".}
proc gtk_list_select_item*(list: PGtkList, item: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_list_select_item".}
proc gtk_list_unselect_item*(list: PGtkList, item: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_list_unselect_item".}
proc gtk_list_select_child*(list: PGtkList, child: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_list_select_child".}
proc gtk_list_unselect_child*(list: PGtkList, child: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_list_unselect_child".}
proc gtk_list_child_position*(list: PGtkList, child: PGtkWidget): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_list_child_position".}
proc gtk_list_set_selection_mode*(list: PGtkList, mode: TGtkSelectionMode){.
    cdecl, dynlib: gtklib, importc: "gtk_list_set_selection_mode".}
proc gtk_list_extend_selection*(list: PGtkList, scroll_type: TGtkScrollType,
                                position: gfloat, auto_start_selection: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_list_extend_selection".}
proc gtk_list_start_selection*(list: PGtkList){.cdecl, dynlib: gtklib,
    importc: "gtk_list_start_selection".}
proc gtk_list_end_selection*(list: PGtkList){.cdecl, dynlib: gtklib,
    importc: "gtk_list_end_selection".}
proc gtk_list_select_all*(list: PGtkList){.cdecl, dynlib: gtklib,
    importc: "gtk_list_select_all".}
proc gtk_list_unselect_all*(list: PGtkList){.cdecl, dynlib: gtklib,
    importc: "gtk_list_unselect_all".}
proc gtk_list_scroll_horizontal*(list: PGtkList, scroll_type: TGtkScrollType,
                                 position: gfloat){.cdecl, dynlib: gtklib,
    importc: "gtk_list_scroll_horizontal".}
proc gtk_list_scroll_vertical*(list: PGtkList, scroll_type: TGtkScrollType,
                               position: gfloat){.cdecl, dynlib: gtklib,
    importc: "gtk_list_scroll_vertical".}
proc gtk_list_toggle_add_mode*(list: PGtkList){.cdecl, dynlib: gtklib,
    importc: "gtk_list_toggle_add_mode".}
proc gtk_list_toggle_focus_row*(list: PGtkList){.cdecl, dynlib: gtklib,
    importc: "gtk_list_toggle_focus_row".}
proc gtk_list_toggle_row*(list: PGtkList, item: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_list_toggle_row".}
proc gtk_list_undo_selection*(list: PGtkList){.cdecl, dynlib: gtklib,
    importc: "gtk_list_undo_selection".}
proc gtk_list_end_drag_selection*(list: PGtkList){.cdecl, dynlib: gtklib,
    importc: "gtk_list_end_drag_selection".}
const
  GTK_TREE_MODEL_ITERS_PERSIST* = 1 shl 0
  GTK_TREE_MODEL_LIST_ONLY* = 1 shl 1

proc GTK_TYPE_TREE_MODEL*(): GType
proc GTK_TREE_MODEL*(obj: pointer): PGtkTreeModel
proc GTK_IS_TREE_MODEL*(obj: pointer): bool
proc GTK_TREE_MODEL_GET_IFACE*(obj: pointer): PGtkTreeModelIface
proc GTK_TYPE_TREE_ITER*(): GType
proc GTK_TYPE_TREE_PATH*(): GType
proc gtk_tree_path_new*(): PGtkTreePath{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_path_new".}
proc gtk_tree_path_new_from_string*(path: cstring): PGtkTreePath{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_path_new_from_string".}
proc gtk_tree_path_to_string*(path: PGtkTreePath): cstring{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_path_to_string".}
proc gtk_tree_path_new_root*(): PGtkTreePath
proc gtk_tree_path_new_first*(): PGtkTreePath{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_path_new_first".}
proc gtk_tree_path_append_index*(path: PGtkTreePath, index: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_path_append_index".}
proc gtk_tree_path_prepend_index*(path: PGtkTreePath, index: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_path_prepend_index".}
proc gtk_tree_path_get_depth*(path: PGtkTreePath): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_path_get_depth".}
proc gtk_tree_path_get_indices*(path: PGtkTreePath): Pgint{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_path_get_indices".}
proc gtk_tree_path_free*(path: PGtkTreePath){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_path_free".}
proc gtk_tree_path_copy*(path: PGtkTreePath): PGtkTreePath{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_path_copy".}
proc gtk_tree_path_get_type*(): GType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_tree_path_get_type".}
proc gtk_tree_path_compare*(a: PGtkTreePath, b: PGtkTreePath): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_path_compare".}
proc gtk_tree_path_next*(path: PGtkTreePath){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_path_next".}
proc gtk_tree_path_prev*(path: PGtkTreePath): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_path_prev".}
proc gtk_tree_path_up*(path: PGtkTreePath): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_path_up".}
proc gtk_tree_path_down*(path: PGtkTreePath){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_path_down".}
proc gtk_tree_path_is_ancestor*(path: PGtkTreePath, descendant: PGtkTreePath): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_path_is_ancestor".}
proc gtk_tree_path_is_descendant*(path: PGtkTreePath, ancestor: PGtkTreePath): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_path_is_descendant".}
proc gtk_tree_row_reference_new*(model: PGtkTreeModel, path: PGtkTreePath): PGtkTreeRowReference{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_row_reference_new".}
proc gtk_tree_row_reference_new_proxy*(proxy: PGObject, model: PGtkTreeModel,
                                       path: PGtkTreePath): PGtkTreeRowReference{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_row_reference_new_proxy".}
proc gtk_tree_row_reference_get_path*(reference: PGtkTreeRowReference): PGtkTreePath{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_row_reference_get_path".}
proc gtk_tree_row_reference_valid*(reference: PGtkTreeRowReference): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_row_reference_valid".}
proc gtk_tree_row_reference_free*(reference: PGtkTreeRowReference){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_row_reference_free".}
proc gtk_tree_row_reference_inserted*(proxy: PGObject, path: PGtkTreePath){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_row_reference_inserted".}
proc gtk_tree_row_reference_deleted*(proxy: PGObject, path: PGtkTreePath){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_row_reference_deleted".}
proc gtk_tree_row_reference_reordered*(proxy: PGObject, path: PGtkTreePath,
                                       iter: PGtkTreeIter, new_order: Pgint){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_row_reference_reordered".}
proc gtk_tree_iter_copy*(iter: PGtkTreeIter): PGtkTreeIter{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_iter_copy".}
proc gtk_tree_iter_free*(iter: PGtkTreeIter){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_iter_free".}
proc gtk_tree_iter_get_type*(): GType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_tree_iter_get_type".}
proc gtk_tree_model_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_model_get_type".}
proc gtk_tree_model_get_flags*(tree_model: PGtkTreeModel): TGtkTreeModelFlags{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_model_get_flags".}
proc gtk_tree_model_get_n_columns*(tree_model: PGtkTreeModel): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_model_get_n_columns".}
proc gtk_tree_model_get_column_type*(tree_model: PGtkTreeModel, index: gint): GType{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_model_get_column_type".}
proc gtk_tree_model_get_iter*(tree_model: PGtkTreeModel, iter: PGtkTreeIter,
                              path: PGtkTreePath): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_model_get_iter".}
proc gtk_tree_model_get_iter_from_string*(tree_model: PGtkTreeModel,
    iter: PGtkTreeIter, path_string: cstring): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_model_get_iter_from_string".}
proc gtk_tree_model_get_iter_root*(tree_model: PGtkTreeModel, iter: PGtkTreeIter): gboolean
proc gtk_tree_model_get_iter_first*(tree_model: PGtkTreeModel,
                                    iter: PGtkTreeIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_model_get_iter_first".}
proc gtk_tree_model_get_path*(tree_model: PGtkTreeModel, iter: PGtkTreeIter): PGtkTreePath{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_model_get_path".}
proc gtk_tree_model_get_value*(tree_model: PGtkTreeModel, iter: PGtkTreeIter,
                               column: gint, value: PGValue){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_model_get_value".}
proc gtk_tree_model_iter_next*(tree_model: PGtkTreeModel, iter: PGtkTreeIter): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_model_iter_next".}
proc gtk_tree_model_iter_children*(tree_model: PGtkTreeModel,
                                   iter: PGtkTreeIter, parent: PGtkTreeIter): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_model_iter_children".}
proc gtk_tree_model_iter_has_child*(tree_model: PGtkTreeModel,
                                    iter: PGtkTreeIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_model_iter_has_child".}
proc gtk_tree_model_iter_n_children*(tree_model: PGtkTreeModel,
                                     iter: PGtkTreeIter): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_model_iter_n_children".}
proc gtk_tree_model_iter_nth_child*(tree_model: PGtkTreeModel,
                                    iter: PGtkTreeIter, parent: PGtkTreeIter,
                                    n: gint): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_model_iter_nth_child".}
proc gtk_tree_model_iter_parent*(tree_model: PGtkTreeModel, iter: PGtkTreeIter,
                                 child: PGtkTreeIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_model_iter_parent".}
proc gtk_tree_model_ref_node*(tree_model: PGtkTreeModel, iter: PGtkTreeIter){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_model_ref_node".}
proc gtk_tree_model_unref_node*(tree_model: PGtkTreeModel, iter: PGtkTreeIter){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_model_unref_node".}
proc gtk_tree_model_foreach*(model: PGtkTreeModel,
                             fun: TGtkTreeModelForeachFunc,
                             user_data: gpointer){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_model_foreach".}
proc gtk_tree_model_row_changed*(tree_model: PGtkTreeModel, path: PGtkTreePath,
                                 iter: PGtkTreeIter){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_model_row_changed".}
proc gtk_tree_model_row_inserted*(tree_model: PGtkTreeModel, path: PGtkTreePath,
                                  iter: PGtkTreeIter){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_model_row_inserted".}
proc gtk_tree_model_row_has_child_toggled*(tree_model: PGtkTreeModel,
    path: PGtkTreePath, iter: PGtkTreeIter){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_model_row_has_child_toggled".}
proc gtk_tree_model_row_deleted*(tree_model: PGtkTreeModel, path: PGtkTreePath){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_model_row_deleted".}
proc gtk_tree_model_rows_reordered*(tree_model: PGtkTreeModel,
                                    path: PGtkTreePath, iter: PGtkTreeIter,
                                    new_order: Pgint){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_model_rows_reordered".}
const
  GTK_TREE_SORTABLE_DEFAULT_SORT_COLUMN_ID* = - (1)

proc GTK_TYPE_TREE_SORTABLE*(): GType
proc GTK_TREE_SORTABLE*(obj: pointer): PGtkTreeSortable
proc GTK_TREE_SORTABLE_CLASS*(obj: pointer): PGtkTreeSortableIface
proc GTK_IS_TREE_SORTABLE*(obj: pointer): bool
proc GTK_TREE_SORTABLE_GET_IFACE*(obj: pointer): PGtkTreeSortableIface
proc gtk_tree_sortable_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_sortable_get_type".}
proc gtk_tree_sortable_sort_column_changed*(sortable: PGtkTreeSortable){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_sortable_sort_column_changed".}
proc gtk_tree_sortable_get_sort_column_id*(sortable: PGtkTreeSortable,
    sort_column_id: Pgint, order: PGtkSortType): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_sortable_get_sort_column_id".}
proc gtk_tree_sortable_set_sort_column_id*(sortable: PGtkTreeSortable,
    sort_column_id: gint, order: TGtkSortType){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_sortable_set_sort_column_id".}
proc gtk_tree_sortable_set_sort_func*(sortable: PGtkTreeSortable,
                                      sort_column_id: gint,
                                      sort_func: TGtkTreeIterCompareFunc,
                                      user_data: gpointer,
                                      destroy: TGtkDestroyNotify){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_sortable_set_sort_func".}
proc gtk_tree_sortable_set_default_sort_func*(sortable: PGtkTreeSortable,
    sort_func: TGtkTreeIterCompareFunc, user_data: gpointer,
    destroy: TGtkDestroyNotify){.cdecl, dynlib: gtklib, importc: "gtk_tree_sortable_set_default_sort_func".}
proc gtk_tree_sortable_has_default_sort_func*(sortable: PGtkTreeSortable): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_sortable_has_default_sort_func".}
proc GTK_TYPE_TREE_MODEL_SORT*(): GType
proc GTK_TREE_MODEL_SORT*(obj: pointer): PGtkTreeModelSort
proc GTK_TREE_MODEL_SORT_CLASS*(klass: pointer): PGtkTreeModelSortClass
proc GTK_IS_TREE_MODEL_SORT*(obj: pointer): bool
proc GTK_IS_TREE_MODEL_SORT_CLASS*(klass: pointer): bool
proc GTK_TREE_MODEL_SORT_GET_CLASS*(obj: pointer): PGtkTreeModelSortClass
proc gtk_tree_model_sort_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_model_sort_get_type".}
proc gtk_tree_model_sort_new_with_model*(child_model: PGtkTreeModel): PGtkTreeModel{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_model_sort_new_with_model".}
proc gtk_tree_model_sort_get_model*(tree_model: PGtkTreeModelSort): PGtkTreeModel{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_model_sort_get_model".}
proc gtk_tree_model_sort_convert_child_path_to_path*(
    tree_model_sort: PGtkTreeModelSort, child_path: PGtkTreePath): PGtkTreePath{.
    cdecl, dynlib: gtklib,
    importc: "gtk_tree_model_sort_convert_child_path_to_path".}
proc gtk_tree_model_sort_convert_child_iter_to_iter*(
    tree_model_sort: PGtkTreeModelSort, sort_iter: PGtkTreeIter,
    child_iter: PGtkTreeIter){.cdecl, dynlib: gtklib, importc: "gtk_tree_model_sort_convert_child_iter_to_iter".}
proc gtk_tree_model_sort_convert_path_to_child_path*(
    tree_model_sort: PGtkTreeModelSort, sorted_path: PGtkTreePath): PGtkTreePath{.
    cdecl, dynlib: gtklib,
    importc: "gtk_tree_model_sort_convert_path_to_child_path".}
proc gtk_tree_model_sort_convert_iter_to_child_iter*(
    tree_model_sort: PGtkTreeModelSort, child_iter: PGtkTreeIter,
    sorted_iter: PGtkTreeIter){.cdecl, dynlib: gtklib, importc: "gtk_tree_model_sort_convert_iter_to_child_iter".}
proc gtk_tree_model_sort_reset_default_sort_func*(
    tree_model_sort: PGtkTreeModelSort){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_model_sort_reset_default_sort_func".}
proc gtk_tree_model_sort_clear_cache*(tree_model_sort: PGtkTreeModelSort){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_model_sort_clear_cache".}
const
  bm_TGtkListStore_columns_dirty* = 0x00000001'i16
  bp_TGtkListStore_columns_dirty* = 0'i16

proc GTK_TYPE_LIST_STORE*(): GType
proc GTK_LIST_STORE*(obj: pointer): PGtkListStore
proc GTK_LIST_STORE_CLASS*(klass: pointer): PGtkListStoreClass
proc GTK_IS_LIST_STORE*(obj: pointer): bool
proc GTK_IS_LIST_STORE_CLASS*(klass: pointer): bool
proc GTK_LIST_STORE_GET_CLASS*(obj: pointer): PGtkListStoreClass
proc columns_dirty*(a: var TGtkListStore): guint
proc set_columns_dirty*(a: var TGtkListStore, `columns_dirty`: guint)
proc gtk_list_store_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_list_store_get_type".}
proc gtk_list_store_newv*(n_columns: gint, types: PGType): PGtkListStore{.cdecl,
    dynlib: gtklib, importc: "gtk_list_store_newv".}
proc gtk_list_store_set_column_types*(list_store: PGtkListStore,
                                      n_columns: gint, types: PGType){.cdecl,
    dynlib: gtklib, importc: "gtk_list_store_set_column_types".}
proc gtk_list_store_set_value*(list_store: PGtkListStore, iter: PGtkTreeIter,
                               column: gint, value: PGValue){.cdecl,
    dynlib: gtklib, importc: "gtk_list_store_set_value".}
proc gtk_list_store_remove*(list_store: PGtkListStore, iter: PGtkTreeIter){.
    cdecl, dynlib: gtklib, importc: "gtk_list_store_remove".}
proc gtk_list_store_insert*(list_store: PGtkListStore, iter: PGtkTreeIter,
                            position: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_list_store_insert".}
proc gtk_list_store_insert_before*(list_store: PGtkListStore,
                                   iter: PGtkTreeIter, sibling: PGtkTreeIter){.
    cdecl, dynlib: gtklib, importc: "gtk_list_store_insert_before".}
proc gtk_list_store_insert_after*(list_store: PGtkListStore, iter: PGtkTreeIter,
                                  sibling: PGtkTreeIter){.cdecl, dynlib: gtklib,
    importc: "gtk_list_store_insert_after".}
proc gtk_list_store_prepend*(list_store: PGtkListStore, iter: PGtkTreeIter){.
    cdecl, dynlib: gtklib, importc: "gtk_list_store_prepend".}
proc gtk_list_store_append*(list_store: PGtkListStore, iter: PGtkTreeIter){.
    cdecl, dynlib: gtklib, importc: "gtk_list_store_append".}
proc gtk_list_store_clear*(list_store: PGtkListStore){.cdecl, dynlib: gtklib,
    importc: "gtk_list_store_clear".}

when false:
  const
    GTK_PRIORITY_RESIZE* = G_PRIORITY_HIGH_IDLE + 10

proc gtk_check_version*(required_major: guint, required_minor: guint,
                        required_micro: guint): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_check_version".}
proc gtk_disable_setlocale*(){.cdecl, dynlib: gtklib,
                               importc: "gtk_disable_setlocale".}
proc gtk_set_locale*(): cstring{.cdecl, dynlib: gtklib, importc: "gtk_set_locale".}
proc gtk_get_default_language*(): PPangoLanguage{.cdecl, dynlib: gtklib,
    importc: "gtk_get_default_language".}
proc gtk_events_pending*(): gint{.cdecl, dynlib: gtklib,
                                  importc: "gtk_events_pending".}
proc gtk_main_do_event*(event: PGdkEvent){.cdecl, dynlib: gtklib,
    importc: "gtk_main_do_event".}
proc gtk_main*(){.cdecl, dynlib: gtklib, importc: "gtk_main".}
proc gtk_init*(argc, argv: pointer){.cdecl, dynlib: gtklib, importc: "gtk_init".}
proc gtk_main_level*(): guint{.cdecl, dynlib: gtklib, importc: "gtk_main_level".}
proc gtk_main_quit*(){.cdecl, dynlib: gtklib, importc: "gtk_main_quit".}
proc gtk_main_iteration*(): gboolean{.cdecl, dynlib: gtklib,
                                      importc: "gtk_main_iteration".}
proc gtk_main_iteration_do*(blocking: gboolean): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_main_iteration_do".}
proc gtk_true*(): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_true".}
proc gtk_false*(): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_false".}
proc gtk_grab_add*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
                                        importc: "gtk_grab_add".}
proc gtk_grab_get_current*(): PGtkWidget{.cdecl, dynlib: gtklib,
    importc: "gtk_grab_get_current".}
proc gtk_grab_remove*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_grab_remove".}
proc gtk_init_add*(`function`: TGtkFunction, data: gpointer){.cdecl,
    dynlib: gtklib, importc: "gtk_init_add".}
proc gtk_quit_add_destroy*(main_level: guint, anObject: PGtkObject){.cdecl,
    dynlib: gtklib, importc: "gtk_quit_add_destroy".}
proc gtk_quit_add*(main_level: guint, `function`: TGtkFunction, data: gpointer): guint{.
    cdecl, dynlib: gtklib, importc: "gtk_quit_add".}
proc gtk_quit_add_full*(main_level: guint, `function`: TGtkFunction,
                        marshal: TGtkCallbackMarshal, data: gpointer,
                        destroy: TGtkDestroyNotify): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_quit_add_full".}
proc gtk_quit_remove*(quit_handler_id: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_quit_remove".}
proc gtk_quit_remove_by_data*(data: gpointer){.cdecl, dynlib: gtklib,
    importc: "gtk_quit_remove_by_data".}
proc gtk_timeout_add*(interval: guint32, `function`: TGtkFunction,
                      data: gpointer): guint{.cdecl, dynlib: gtklib,
    importc: "gtk_timeout_add".}
proc gtk_timeout_add_full*(interval: guint32, `function`: TGtkFunction,
                           marshal: TGtkCallbackMarshal, data: gpointer,
                           destroy: TGtkDestroyNotify): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_timeout_add_full".}
proc gtk_timeout_remove*(timeout_handler_id: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_timeout_remove".}
proc gtk_idle_add*(`function`: TGtkFunction, data: gpointer): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_idle_add".}
proc gtk_idle_add_priority*(priority: gint, `function`: TGtkFunction,
                            data: gpointer): guint{.cdecl, dynlib: gtklib,
    importc: "gtk_idle_add_priority".}
proc gtk_idle_add_full*(priority: gint, `function`: TGtkFunction,
                        marshal: TGtkCallbackMarshal, data: gpointer,
                        destroy: TGtkDestroyNotify): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_idle_add_full".}
proc gtk_idle_remove*(idle_handler_id: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_idle_remove".}
proc gtk_idle_remove_by_data*(data: gpointer){.cdecl, dynlib: gtklib,
    importc: "gtk_idle_remove_by_data".}
proc gtk_input_add_full*(source: gint, condition: TGdkInputCondition,
                         `function`: TGdkInputFunction,
                         marshal: TGtkCallbackMarshal, data: gpointer,
                         destroy: TGtkDestroyNotify): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_input_add_full".}
proc gtk_input_remove*(input_handler_id: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_input_remove".}
proc gtk_key_snooper_install*(snooper: TGtkKeySnoopFunc, func_data: gpointer): guint{.
    cdecl, dynlib: gtklib, importc: "gtk_key_snooper_install".}
proc gtk_key_snooper_remove*(snooper_handler_id: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_key_snooper_remove".}
proc gtk_get_current_event*(): PGdkEvent{.cdecl, dynlib: gtklib,
    importc: "gtk_get_current_event".}
proc gtk_get_current_event_time*(): guint32{.cdecl, dynlib: gtklib,
    importc: "gtk_get_current_event_time".}
proc gtk_get_current_event_state*(state: PGdkModifierType): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_get_current_event_state".}
proc gtk_get_event_widget*(event: PGdkEvent): PGtkWidget{.cdecl, dynlib: gtklib,
    importc: "gtk_get_event_widget".}
proc gtk_propagate_event*(widget: PGtkWidget, event: PGdkEvent){.cdecl,
    dynlib: gtklib, importc: "gtk_propagate_event".}
proc gtk_boolean_handled_accumulator*(ihint: PGSignalInvocationHint,
                                        return_accu: PGValue,
                                        handler_return: PGValue, dummy: gpointer): gboolean{.
    cdecl, dynlib: gtklib, importc: "_gtk_boolean_handled_accumulator".}
proc gtk_find_module*(name: cstring, thetype: cstring): cstring{.cdecl,
    dynlib: gtklib, importc: "_gtk_find_module".}
proc gtk_get_module_path*(thetype: cstring): PPgchar{.cdecl, dynlib: gtklib,
    importc: "_gtk_get_module_path".}
proc GTK_TYPE_MENU_BAR*(): GType
proc GTK_MENU_BAR*(obj: pointer): PGtkMenuBar
proc GTK_MENU_BAR_CLASS*(klass: pointer): PGtkMenuBarClass
proc GTK_IS_MENU_BAR*(obj: pointer): bool
proc GTK_IS_MENU_BAR_CLASS*(klass: pointer): bool
proc GTK_MENU_BAR_GET_CLASS*(obj: pointer): PGtkMenuBarClass
proc gtk_menu_bar_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_menu_bar_get_type".}
proc gtk_menu_bar_new*(): PGtkMenuBar{.cdecl, dynlib: gtklib,
                                      importc: "gtk_menu_bar_new".}
proc gtk_menu_bar_cycle_focus*(menubar: PGtkMenuBar, dir: TGtkDirectionType){.
    cdecl, dynlib: gtklib, importc: "_gtk_menu_bar_cycle_focus".}
proc GTK_TYPE_MESSAGE_DIALOG*(): GType
proc GTK_MESSAGE_DIALOG*(obj: pointer): PGtkMessageDialog
proc GTK_MESSAGE_DIALOG_CLASS*(klass: pointer): PGtkMessageDialogClass
proc GTK_IS_MESSAGE_DIALOG*(obj: pointer): bool
proc GTK_IS_MESSAGE_DIALOG_CLASS*(klass: pointer): bool
proc GTK_MESSAGE_DIALOG_GET_CLASS*(obj: pointer): PGtkMessageDialogClass
proc gtk_message_dialog_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_message_dialog_get_type".}
const
  bm_TGtkNotebook_show_tabs* = 0x00000001'i16
  bp_TGtkNotebook_show_tabs* = 0'i16
  bm_TGtkNotebook_homogeneous* = 0x00000002'i16
  bp_TGtkNotebook_homogeneous* = 1'i16
  bm_TGtkNotebook_show_border* = 0x00000004'i16
  bp_TGtkNotebook_show_border* = 2'i16
  bm_TGtkNotebook_tab_pos* = 0x00000018'i16
  bp_TGtkNotebook_tab_pos* = 3'i16
  bm_TGtkNotebook_scrollable* = 0x00000020'i16
  bp_TGtkNotebook_scrollable* = 5'i16
  bm_TGtkNotebook_in_child* = 0x000000C0'i16
  bp_TGtkNotebook_in_child* = 6'i16
  bm_TGtkNotebook_click_child* = 0x00000300'i16
  bp_TGtkNotebook_click_child* = 8'i16
  bm_TGtkNotebook_button* = 0x00000C00'i16
  bp_TGtkNotebook_button* = 10'i16
  bm_TGtkNotebook_need_timer* = 0x00001000'i16
  bp_TGtkNotebook_need_timer* = 12'i16
  bm_TGtkNotebook_child_has_focus* = 0x00002000'i16
  bp_TGtkNotebook_child_has_focus* = 13'i16
  bm_TGtkNotebook_have_visible_child* = 0x00004000'i16
  bp_TGtkNotebook_have_visible_child* = 14'i16
  bm_TGtkNotebook_focus_out* = 0x00008000'i16
  bp_TGtkNotebook_focus_out* = 15'i16

proc GTK_TYPE_NOTEBOOK*(): GType
proc GTK_NOTEBOOK*(obj: pointer): PGtkNotebook
proc GTK_NOTEBOOK_CLASS*(klass: pointer): PGtkNotebookClass
proc GTK_IS_NOTEBOOK*(obj: pointer): bool
proc GTK_IS_NOTEBOOK_CLASS*(klass: pointer): bool
proc GTK_NOTEBOOK_GET_CLASS*(obj: pointer): PGtkNotebookClass
proc show_tabs*(a: var TGtkNotebook): guint
proc set_show_tabs*(a: var TGtkNotebook, `show_tabs`: guint)
proc homogeneous*(a: var TGtkNotebook): guint
proc set_homogeneous*(a: var TGtkNotebook, `homogeneous`: guint)
proc show_border*(a: var TGtkNotebook): guint
proc set_show_border*(a: var TGtkNotebook, `show_border`: guint)
proc tab_pos*(a: var TGtkNotebook): guint
proc set_tab_pos*(a: var TGtkNotebook, `tab_pos`: guint)
proc scrollable*(a: var TGtkNotebook): guint
proc set_scrollable*(a: var TGtkNotebook, `scrollable`: guint)
proc in_child*(a: var TGtkNotebook): guint
proc set_in_child*(a: var TGtkNotebook, `in_child`: guint)
proc click_child*(a: var TGtkNotebook): guint
proc set_click_child*(a: var TGtkNotebook, `click_child`: guint)
proc button*(a: var TGtkNotebook): guint
proc set_button*(a: var TGtkNotebook, `button`: guint)
proc need_timer*(a: var TGtkNotebook): guint
proc set_need_timer*(a: var TGtkNotebook, `need_timer`: guint)
proc child_has_focus*(a: var TGtkNotebook): guint
proc set_child_has_focus*(a: var TGtkNotebook, `child_has_focus`: guint)
proc have_visible_child*(a: var TGtkNotebook): guint
proc set_have_visible_child*(a: var TGtkNotebook, `have_visible_child`: guint)
proc focus_out*(a: var TGtkNotebook): guint
proc set_focus_out*(a: var TGtkNotebook, `focus_out`: guint)
proc gtk_notebook_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_notebook_get_type".}
proc gtk_notebook_new*(): PGtkNotebook{.cdecl, dynlib: gtklib,
                                      importc: "gtk_notebook_new".}
proc gtk_notebook_append_page*(notebook: PGtkNotebook, child: PGtkWidget,
                               tab_label: PGtkWidget): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_notebook_append_page".}
proc gtk_notebook_append_page_menu*(notebook: PGtkNotebook, child: PGtkWidget,
                                    tab_label: PGtkWidget,
                                    menu_label: PGtkWidget): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_notebook_append_page_menu".}
proc gtk_notebook_prepend_page*(notebook: PGtkNotebook, child: PGtkWidget,
                                tab_label: PGtkWidget): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_notebook_prepend_page".}
proc gtk_notebook_prepend_page_menu*(notebook: PGtkNotebook, child: PGtkWidget,
                                     tab_label: PGtkWidget,
                                     menu_label: PGtkWidget): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_notebook_prepend_page_menu".}
proc gtk_notebook_insert_page*(notebook: PGtkNotebook, child: PGtkWidget,
                               tab_label: PGtkWidget, position: gint): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_insert_page".}
proc gtk_notebook_insert_page_menu*(notebook: PGtkNotebook, child: PGtkWidget,
                                    tab_label: PGtkWidget,
                                    menu_label: PGtkWidget, position: gint): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_insert_page_menu".}
proc gtk_notebook_remove_page*(notebook: PGtkNotebook, page_num: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_notebook_remove_page".}
proc gtk_notebook_get_current_page*(notebook: PGtkNotebook): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_notebook_get_current_page".}
proc gtk_notebook_get_n_pages*(notebook: PGtkNotebook): gint {.cdecl, 
    dynlib: gtklib, importc.}
proc gtk_notebook_get_nth_page*(notebook: PGtkNotebook, page_num: gint): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_get_nth_page".}
proc gtk_notebook_page_num*(notebook: PGtkNotebook, child: PGtkWidget): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_page_num".}
proc gtk_notebook_set_current_page*(notebook: PGtkNotebook, page_num: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_set_current_page".}
proc gtk_notebook_next_page*(notebook: PGtkNotebook){.cdecl, dynlib: gtklib,
    importc: "gtk_notebook_next_page".}
proc gtk_notebook_prev_page*(notebook: PGtkNotebook){.cdecl, dynlib: gtklib,
    importc: "gtk_notebook_prev_page".}
proc gtk_notebook_set_show_border*(notebook: PGtkNotebook, show_border: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_set_show_border".}
proc gtk_notebook_get_show_border*(notebook: PGtkNotebook): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_notebook_get_show_border".}
proc gtk_notebook_set_show_tabs*(notebook: PGtkNotebook, show_tabs: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_set_show_tabs".}
proc gtk_notebook_get_show_tabs*(notebook: PGtkNotebook): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_notebook_get_show_tabs".}
proc gtk_notebook_set_tab_pos*(notebook: PGtkNotebook, pos: TGtkPositionType){.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_set_tab_pos".}
proc gtk_notebook_get_tab_pos*(notebook: PGtkNotebook): TGtkPositionType{.cdecl,
    dynlib: gtklib, importc: "gtk_notebook_get_tab_pos".}
proc gtk_notebook_set_scrollable*(notebook: PGtkNotebook, scrollable: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_set_scrollable".}
proc gtk_notebook_get_scrollable*(notebook: PGtkNotebook): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_notebook_get_scrollable".}
proc gtk_notebook_popup_enable*(notebook: PGtkNotebook){.cdecl, dynlib: gtklib,
    importc: "gtk_notebook_popup_enable".}
proc gtk_notebook_popup_disable*(notebook: PGtkNotebook){.cdecl, dynlib: gtklib,
    importc: "gtk_notebook_popup_disable".}
proc gtk_notebook_get_tab_label*(notebook: PGtkNotebook, child: PGtkWidget): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_get_tab_label".}
proc gtk_notebook_set_tab_label*(notebook: PGtkNotebook, child: PGtkWidget,
                                 tab_label: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_notebook_set_tab_label".}
proc gtk_notebook_set_tab_label_text*(notebook: PGtkNotebook, child: PGtkWidget,
                                      tab_text: cstring){.cdecl, dynlib: gtklib,
    importc: "gtk_notebook_set_tab_label_text".}
proc gtk_notebook_get_tab_label_text*(notebook: PGtkNotebook, child: PGtkWidget): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_get_tab_label_text".}
proc gtk_notebook_get_menu_label*(notebook: PGtkNotebook, child: PGtkWidget): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_get_menu_label".}
proc gtk_notebook_set_menu_label*(notebook: PGtkNotebook, child: PGtkWidget,
                                  menu_label: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_notebook_set_menu_label".}
proc gtk_notebook_set_menu_label_text*(notebook: PGtkNotebook,
                                       child: PGtkWidget, menu_text: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_set_menu_label_text".}
proc gtk_notebook_get_menu_label_text*(notebook: PGtkNotebook, child: PGtkWidget): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_get_menu_label_text".}
proc gtk_notebook_query_tab_label_packing*(notebook: PGtkNotebook,
    child: PGtkWidget, expand: Pgboolean, fill: Pgboolean,
    pack_type: PGtkPackType){.cdecl, dynlib: gtklib,
                              importc: "gtk_notebook_query_tab_label_packing".}
proc gtk_notebook_set_tab_label_packing*(notebook: PGtkNotebook,
    child: PGtkWidget, expand: gboolean, fill: gboolean, pack_type: TGtkPackType){.
    cdecl, dynlib: gtklib, importc: "gtk_notebook_set_tab_label_packing".}
proc gtk_notebook_reorder_child*(notebook: PGtkNotebook, child: PGtkWidget,
                                 position: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_notebook_reorder_child".}
const
  bm_TGtkOldEditable_has_selection* = 0x00000001'i16
  bp_TGtkOldEditable_has_selection* = 0'i16
  bm_TGtkOldEditable_editable* = 0x00000002'i16
  bp_TGtkOldEditable_editable* = 1'i16
  bm_TGtkOldEditable_visible* = 0x00000004'i16
  bp_TGtkOldEditable_visible* = 2'i16

proc GTK_TYPE_OLD_EDITABLE*(): GType
proc GTK_OLD_EDITABLE*(obj: pointer): PGtkOldEditable
proc GTK_OLD_EDITABLE_CLASS*(klass: pointer): PGtkOldEditableClass
proc GTK_IS_OLD_EDITABLE*(obj: pointer): bool
proc GTK_IS_OLD_EDITABLE_CLASS*(klass: pointer): bool
proc GTK_OLD_EDITABLE_GET_CLASS*(obj: pointer): PGtkOldEditableClass
proc has_selection*(a: var TGtkOldEditable): guint
proc set_has_selection*(a: var TGtkOldEditable, `has_selection`: guint)
proc editable*(a: var TGtkOldEditable): guint
proc set_editable*(a: var TGtkOldEditable, `editable`: guint)
proc visible*(a: var TGtkOldEditable): guint
proc set_visible*(a: var TGtkOldEditable, `visible`: guint)
proc gtk_old_editable_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_old_editable_get_type".}
proc gtk_old_editable_claim_selection*(old_editable: PGtkOldEditable,
                                       claim: gboolean, time: guint32){.cdecl,
    dynlib: gtklib, importc: "gtk_old_editable_claim_selection".}
proc gtk_old_editable_changed*(old_editable: PGtkOldEditable){.cdecl,
    dynlib: gtklib, importc: "gtk_old_editable_changed".}
proc GTK_TYPE_OPTION_MENU*(): GType
proc GTK_OPTION_MENU*(obj: pointer): PGtkOptionMenu
proc GTK_OPTION_MENU_CLASS*(klass: pointer): PGtkOptionMenuClass
proc GTK_IS_OPTION_MENU*(obj: pointer): bool
proc GTK_IS_OPTION_MENU_CLASS*(klass: pointer): bool
proc GTK_OPTION_MENU_GET_CLASS*(obj: pointer): PGtkOptionMenuClass
proc gtk_option_menu_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_option_menu_get_type".}
proc gtk_option_menu_new*(): PGtkOptionMenu{.cdecl, dynlib: gtklib,
    importc: "gtk_option_menu_new".}
proc gtk_option_menu_get_menu*(option_menu: PGtkOptionMenu): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_option_menu_get_menu".}
proc gtk_option_menu_set_menu*(option_menu: PGtkOptionMenu, menu: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "gtk_option_menu_set_menu".}
proc gtk_option_menu_remove_menu*(option_menu: PGtkOptionMenu){.cdecl,
    dynlib: gtklib, importc: "gtk_option_menu_remove_menu".}
proc gtk_option_menu_get_history*(option_menu: PGtkOptionMenu): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_option_menu_get_history".}
proc gtk_option_menu_set_history*(option_menu: PGtkOptionMenu, index: guint){.
    cdecl, dynlib: gtklib, importc: "gtk_option_menu_set_history".}
const
  bm_TGtkPixmap_build_insensitive* = 0x00000001'i16
  bp_TGtkPixmap_build_insensitive* = 0'i16

proc GTK_TYPE_PIXMAP*(): GType
proc GTK_PIXMAP*(obj: pointer): PGtkPixmap
proc GTK_PIXMAP_CLASS*(klass: pointer): PGtkPixmapClass
proc GTK_IS_PIXMAP*(obj: pointer): bool
proc GTK_IS_PIXMAP_CLASS*(klass: pointer): bool
proc GTK_PIXMAP_GET_CLASS*(obj: pointer): PGtkPixmapClass
proc build_insensitive*(a: var TGtkPixmap): guint
proc set_build_insensitive*(a: var TGtkPixmap, `build_insensitive`: guint)
proc gtk_pixmap_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_pixmap_get_type".}
proc gtk_pixmap_new*(pixmap: PGdkPixmap, mask: PGdkBitmap): PGtkPixmap{.cdecl,
    dynlib: gtklib, importc: "gtk_pixmap_new".}
proc gtk_pixmap_set*(pixmap: PGtkPixmap, val: PGdkPixmap, mask: PGdkBitmap){.
    cdecl, dynlib: gtklib, importc: "gtk_pixmap_set".}
proc gtk_pixmap_get*(pixmap: PGtkPixmap, val: var PGdkPixmap,
                     mask: var PGdkBitmap){.cdecl, dynlib: gtklib,
    importc: "gtk_pixmap_get".}
proc gtk_pixmap_set_build_insensitive*(pixmap: PGtkPixmap, build: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_pixmap_set_build_insensitive".}
const
  bm_TGtkPlug_same_app* = 0x00000001'i16
  bp_TGtkPlug_same_app* = 0'i16

proc GTK_TYPE_PLUG*(): GType
proc GTK_PLUG*(obj: pointer): PGtkPlug
proc GTK_PLUG_CLASS*(klass: pointer): PGtkPlugClass
proc GTK_IS_PLUG*(obj: pointer): bool
proc GTK_IS_PLUG_CLASS*(klass: pointer): bool
proc GTK_PLUG_GET_CLASS*(obj: pointer): PGtkPlugClass
proc same_app*(a: var TGtkPlug): guint
proc set_same_app*(a: var TGtkPlug, `same_app`: guint)
proc gtk_plug_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                     importc: "gtk_plug_get_type".}
proc gtk_plug_construct_for_display*(plug: PGtkPlug, display: PGdkDisplay,
                                     socket_id: TGdkNativeWindow){.cdecl,
    dynlib: gtklib, importc: "gtk_plug_construct_for_display".}
proc gtk_plug_new_for_display*(display: PGdkDisplay, socket_id: TGdkNativeWindow): PGtkPlug{.
    cdecl, dynlib: gtklib, importc: "gtk_plug_new_for_display".}
proc gtk_plug_get_id*(plug: PGtkPlug): TGdkNativeWindow{.cdecl, dynlib: gtklib,
    importc: "gtk_plug_get_id".}
proc gtk_plug_add_to_socket*(plug: PGtkPlug, socket: PGtkSocket){.cdecl,
    dynlib: gtklib, importc: "_gtk_plug_add_to_socket".}
proc gtk_plug_remove_from_socket*(plug: PGtkPlug, socket: PGtkSocket){.cdecl,
    dynlib: gtklib, importc: "_gtk_plug_remove_from_socket".}
const
  bm_TGtkPreview_type* = 0x00000001'i16
  bp_TGtkPreview_type* = 0'i16
  bm_TGtkPreview_expand* = 0x00000002'i16
  bp_TGtkPreview_expand* = 1'i16

proc GTK_TYPE_PREVIEW*(): GType
proc GTK_PREVIEW*(obj: pointer): PGtkPreview
proc GTK_PREVIEW_CLASS*(klass: pointer): PGtkPreviewClass
proc GTK_IS_PREVIEW*(obj: pointer): bool
proc GTK_IS_PREVIEW_CLASS*(klass: pointer): bool
proc GTK_PREVIEW_GET_CLASS*(obj: pointer): PGtkPreviewClass
proc get_type*(a: var TGtkPreview): guint
proc set_type*(a: var TGtkPreview, `type`: guint)
proc get_expand*(a: var TGtkPreview): guint
proc set_expand*(a: var TGtkPreview, `expand`: guint)
proc gtk_preview_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                        importc: "gtk_preview_get_type".}
proc gtk_preview_uninit*(){.cdecl, dynlib: gtklib, importc: "gtk_preview_uninit".}
proc gtk_preview_new*(thetype: TGtkPreviewClass): PGtkPreview{.cdecl,
    dynlib: gtklib, importc: "gtk_preview_new".}
proc gtk_preview_size*(preview: PGtkPreview, width: gint, height: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_preview_size".}
proc gtk_preview_put*(preview: PGtkPreview, window: PGdkWindow, gc: PGdkGC,
                      srcx: gint, srcy: gint, destx: gint, desty: gint,
                      width: gint, height: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_preview_put".}
proc gtk_preview_draw_row*(preview: PGtkPreview, data: Pguchar, x: gint,
                           y: gint, w: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_preview_draw_row".}
proc gtk_preview_set_expand*(preview: PGtkPreview, expand: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_preview_set_expand".}
proc gtk_preview_set_gamma*(gamma: float64){.cdecl, dynlib: gtklib,
    importc: "gtk_preview_set_gamma".}
proc gtk_preview_set_color_cube*(nred_shades: guint, ngreen_shades: guint,
                                 nblue_shades: guint, ngray_shades: guint){.
    cdecl, dynlib: gtklib, importc: "gtk_preview_set_color_cube".}
proc gtk_preview_set_install_cmap*(install_cmap: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_preview_set_install_cmap".}
proc gtk_preview_set_reserved*(nreserved: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_preview_set_reserved".}
proc gtk_preview_set_dither*(preview: PGtkPreview, dither: TGdkRgbDither){.
    cdecl, dynlib: gtklib, importc: "gtk_preview_set_dither".}
proc gtk_preview_get_info*(): PGtkPreviewInfo{.cdecl, dynlib: gtklib,
    importc: "gtk_preview_get_info".}
proc gtk_preview_reset*(){.cdecl, dynlib: gtklib, importc: "gtk_preview_reset".}
const
  bm_TGtkProgress_show_text* = 0x00000001'i16
  bp_TGtkProgress_show_text* = 0'i16
  bm_TGtkProgress_activity_mode* = 0x00000002'i16
  bp_TGtkProgress_activity_mode* = 1'i16
  bm_TGtkProgress_use_text_format* = 0x00000004'i16
  bp_TGtkProgress_use_text_format* = 2'i16

proc show_text*(a: var TGtkProgress): guint
proc set_show_text*(a: var TGtkProgress, `show_text`: guint)
proc activity_mode*(a: var TGtkProgress): guint
proc set_activity_mode*(a: var TGtkProgress, `activity_mode`: guint)
proc use_text_format*(a: var TGtkProgress): guint
proc set_use_text_format*(a: var TGtkProgress, `use_text_format`: guint)
const
  bm_TGtkProgressBar_activity_dir* = 0x00000001'i16
  bp_TGtkProgressBar_activity_dir* = 0'i16

proc GTK_TYPE_PROGRESS_BAR*(): GType
proc GTK_PROGRESS_BAR*(obj: pointer): PGtkProgressBar
proc GTK_PROGRESS_BAR_CLASS*(klass: pointer): PGtkProgressBarClass
proc GTK_IS_PROGRESS_BAR*(obj: pointer): bool
proc GTK_IS_PROGRESS_BAR_CLASS*(klass: pointer): bool
proc GTK_PROGRESS_BAR_GET_CLASS*(obj: pointer): PGtkProgressBarClass
proc activity_dir*(a: var TGtkProgressBar): guint
proc set_activity_dir*(a: var TGtkProgressBar, `activity_dir`: guint)
proc gtk_progress_bar_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_progress_bar_get_type".}
proc gtk_progress_bar_new*(): PGtkProgressBar{.cdecl, dynlib: gtklib,
    importc: "gtk_progress_bar_new".}
proc gtk_progress_bar_pulse*(pbar: PGtkProgressBar){.cdecl, dynlib: gtklib,
    importc: "gtk_progress_bar_pulse".}
proc gtk_progress_bar_set_text*(pbar: PGtkProgressBar, text: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_progress_bar_set_text".}
proc gtk_progress_bar_set_fraction*(pbar: PGtkProgressBar, fraction: gdouble){.
    cdecl, dynlib: gtklib, importc: "gtk_progress_bar_set_fraction".}
proc gtk_progress_bar_set_pulse_step*(pbar: PGtkProgressBar, fraction: gdouble){.
    cdecl, dynlib: gtklib, importc: "gtk_progress_bar_set_pulse_step".}
proc gtk_progress_bar_set_orientation*(pbar: PGtkProgressBar,
                                       orientation: TGtkProgressBarOrientation){.
    cdecl, dynlib: gtklib, importc: "gtk_progress_bar_set_orientation".}
proc gtk_progress_bar_get_text*(pbar: PGtkProgressBar): cstring{.cdecl,
    dynlib: gtklib, importc: "gtk_progress_bar_get_text".}
proc gtk_progress_bar_get_fraction*(pbar: PGtkProgressBar): gdouble{.cdecl,
    dynlib: gtklib, importc: "gtk_progress_bar_get_fraction".}
proc gtk_progress_bar_get_pulse_step*(pbar: PGtkProgressBar): gdouble{.cdecl,
    dynlib: gtklib, importc: "gtk_progress_bar_get_pulse_step".}
proc gtk_progress_bar_get_orientation*(pbar: PGtkProgressBar): TGtkProgressBarOrientation{.
    cdecl, dynlib: gtklib, importc: "gtk_progress_bar_get_orientation".}
proc GTK_TYPE_RADIO_BUTTON*(): GType
proc GTK_RADIO_BUTTON*(obj: pointer): PGtkRadioButton
proc GTK_RADIO_BUTTON_CLASS*(klass: pointer): PGtkRadioButtonClass
proc GTK_IS_RADIO_BUTTON*(obj: pointer): bool
proc GTK_IS_RADIO_BUTTON_CLASS*(klass: pointer): bool
proc GTK_RADIO_BUTTON_GET_CLASS*(obj: pointer): PGtkRadioButtonClass
proc gtk_radio_button_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_radio_button_get_type".}
proc gtk_radio_button_new*(group: PGSList): PGtkRadioButton{.cdecl, dynlib: gtklib,
    importc: "gtk_radio_button_new".}
proc gtk_radio_button_new_from_widget*(group: PGtkRadioButton): PGtkRadioButton{.
    cdecl, dynlib: gtklib, importc: "gtk_radio_button_new_from_widget".}
proc gtk_radio_button_new_with_label*(group: PGSList, `label`: cstring): PGtkRadioButton{.
    cdecl, dynlib: gtklib, importc: "gtk_radio_button_new_with_label".}
proc gtk_radio_button_new_with_label_from_widget*(group: PGtkRadioButton,
    `label`: cstring): PGtkRadioButton{.cdecl, dynlib: gtklib, importc: "gtk_radio_button_new_with_label_from_widget".}
proc gtk_radio_button_new_with_mnemonic*(group: PGSList, `label`: cstring): PGtkRadioButton{.
    cdecl, dynlib: gtklib, importc: "gtk_radio_button_new_with_mnemonic".}
proc gtk_radio_button_new_with_mnemonic_from_widget*(group: PGtkRadioButton,
    `label`: cstring): PGtkRadioButton{.cdecl, dynlib: gtklib, importc: "gtk_radio_button_new_with_mnemonic_from_widget".}
proc gtk_radio_button_get_group*(radio_button: PGtkRadioButton): PGSList{.cdecl,
    dynlib: gtklib, importc: "gtk_radio_button_get_group".}
proc gtk_radio_button_set_group*(radio_button: PGtkRadioButton, group: PGSList){.
    cdecl, dynlib: gtklib, importc: "gtk_radio_button_set_group".}
proc GTK_TYPE_RADIO_MENU_ITEM*(): GType
proc GTK_RADIO_MENU_ITEM*(obj: pointer): PGtkRadioMenuItem
proc GTK_RADIO_MENU_ITEM_CLASS*(klass: pointer): PGtkRadioMenuItemClass
proc GTK_IS_RADIO_MENU_ITEM*(obj: pointer): bool
proc GTK_IS_RADIO_MENU_ITEM_CLASS*(klass: pointer): bool
proc GTK_RADIO_MENU_ITEM_GET_CLASS*(obj: pointer): PGtkRadioMenuItemClass
proc gtk_radio_menu_item_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_radio_menu_item_get_type".}
proc gtk_radio_menu_item_new*(group: PGSList): PGtkRadioMenuItem{.cdecl,
    dynlib: gtklib, importc: "gtk_radio_menu_item_new".}
proc gtk_radio_menu_item_new_with_label*(group: PGSList, `label`: cstring): PGtkRadioMenuItem{.
    cdecl, dynlib: gtklib, importc: "gtk_radio_menu_item_new_with_label".}
proc gtk_radio_menu_item_new_with_mnemonic*(group: PGSList, `label`: cstring): PGtkRadioMenuItem{.
    cdecl, dynlib: gtklib, importc: "gtk_radio_menu_item_new_with_mnemonic".}
proc gtk_radio_menu_item_get_group*(radio_menu_item: PGtkRadioMenuItem): PGSList{.
    cdecl, dynlib: gtklib, importc: "gtk_radio_menu_item_get_group".}
proc gtk_radio_menu_item_set_group*(radio_menu_item: PGtkRadioMenuItem,
                                    group: PGSList){.cdecl, dynlib: gtklib,
    importc: "gtk_radio_menu_item_set_group".}
const
  bm_TGtkScrolledWindow_hscrollbar_policy* = 0x00000003'i16
  bp_TGtkScrolledWindow_hscrollbar_policy* = 0'i16
  bm_TGtkScrolledWindow_vscrollbar_policy* = 0x0000000C'i16
  bp_TGtkScrolledWindow_vscrollbar_policy* = 2'i16
  bm_TGtkScrolledWindow_hscrollbar_visible* = 0x00000010'i16
  bp_TGtkScrolledWindow_hscrollbar_visible* = 4'i16
  bm_TGtkScrolledWindow_vscrollbar_visible* = 0x00000020'i16
  bp_TGtkScrolledWindow_vscrollbar_visible* = 5'i16
  bm_TGtkScrolledWindow_window_placement* = 0x000000C0'i16
  bp_TGtkScrolledWindow_window_placement* = 6'i16
  bm_TGtkScrolledWindow_focus_out* = 0x00000100'i16
  bp_TGtkScrolledWindow_focus_out* = 8'i16

proc GTK_TYPE_SCROLLED_WINDOW*(): GType
proc GTK_SCROLLED_WINDOW*(obj: pointer): PGtkScrolledWindow
proc GTK_SCROLLED_WINDOW_CLASS*(klass: pointer): PGtkScrolledWindowClass
proc GTK_IS_SCROLLED_WINDOW*(obj: pointer): bool
proc GTK_IS_SCROLLED_WINDOW_CLASS*(klass: pointer): bool
proc GTK_SCROLLED_WINDOW_GET_CLASS*(obj: pointer): PGtkScrolledWindowClass
proc hscrollbar_policy*(a: var TGtkScrolledWindow): guint
proc set_hscrollbar_policy*(a: var TGtkScrolledWindow,
                            `hscrollbar_policy`: guint)
proc vscrollbar_policy*(a: var TGtkScrolledWindow): guint
proc set_vscrollbar_policy*(a: var TGtkScrolledWindow,
                            `vscrollbar_policy`: guint)
proc hscrollbar_visible*(a: var TGtkScrolledWindow): guint
proc set_hscrollbar_visible*(a: var TGtkScrolledWindow,
                             `hscrollbar_visible`: guint)
proc vscrollbar_visible*(a: var TGtkScrolledWindow): guint
proc set_vscrollbar_visible*(a: var TGtkScrolledWindow,
                             `vscrollbar_visible`: guint)
proc window_placement*(a: var TGtkScrolledWindow): guint
proc set_window_placement*(a: var TGtkScrolledWindow, `window_placement`: guint)
proc focus_out*(a: var TGtkScrolledWindow): guint
proc set_focus_out*(a: var TGtkScrolledWindow, `focus_out`: guint)
proc gtk_scrolled_window_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_scrolled_window_get_type".}
proc gtk_scrolled_window_new*(hadjustment: PGtkAdjustment,
                              vadjustment: PGtkAdjustment): PGtkScrolledWindow{.cdecl,
    dynlib: gtklib, importc: "gtk_scrolled_window_new".}
proc gtk_scrolled_window_set_hadjustment*(scrolled_window: PGtkScrolledWindow,
    hadjustment: PGtkAdjustment){.cdecl, dynlib: gtklib, importc: "gtk_scrolled_window_set_hadjustment".}
proc gtk_scrolled_window_set_vadjustment*(scrolled_window: PGtkScrolledWindow,
    hadjustment: PGtkAdjustment){.cdecl, dynlib: gtklib, importc: "gtk_scrolled_window_set_vadjustment".}
proc gtk_scrolled_window_get_hadjustment*(scrolled_window: PGtkScrolledWindow): PGtkAdjustment{.
    cdecl, dynlib: gtklib, importc: "gtk_scrolled_window_get_hadjustment".}
proc gtk_scrolled_window_get_vadjustment*(scrolled_window: PGtkScrolledWindow): PGtkAdjustment{.
    cdecl, dynlib: gtklib, importc: "gtk_scrolled_window_get_vadjustment".}
proc gtk_scrolled_window_set_policy*(scrolled_window: PGtkScrolledWindow,
                                     hscrollbar_policy: TGtkPolicyType,
                                     vscrollbar_policy: TGtkPolicyType){.cdecl,
    dynlib: gtklib, importc: "gtk_scrolled_window_set_policy".}
proc gtk_scrolled_window_get_policy*(scrolled_window: PGtkScrolledWindow,
                                     hscrollbar_policy: PGtkPolicyType,
                                     vscrollbar_policy: PGtkPolicyType){.cdecl,
    dynlib: gtklib, importc: "gtk_scrolled_window_get_policy".}
proc gtk_scrolled_window_set_placement*(scrolled_window: PGtkScrolledWindow,
                                        window_placement: TGtkCornerType){.
    cdecl, dynlib: gtklib, importc: "gtk_scrolled_window_set_placement".}
proc gtk_scrolled_window_get_placement*(scrolled_window: PGtkScrolledWindow): TGtkCornerType{.
    cdecl, dynlib: gtklib, importc: "gtk_scrolled_window_get_placement".}
proc gtk_scrolled_window_set_shadow_type*(scrolled_window: PGtkScrolledWindow,
    thetype: TGtkShadowType){.cdecl, dynlib: gtklib,
                              importc: "gtk_scrolled_window_set_shadow_type".}
proc gtk_scrolled_window_get_shadow_type*(scrolled_window: PGtkScrolledWindow): TGtkShadowType{.
    cdecl, dynlib: gtklib, importc: "gtk_scrolled_window_get_shadow_type".}
proc gtk_scrolled_window_add_with_viewport*(scrolled_window: PGtkScrolledWindow,
    child: PGtkWidget){.cdecl, dynlib: gtklib,
                        importc: "gtk_scrolled_window_add_with_viewport".}
proc GTK_TYPE_SELECTION_DATA*(): GType
proc gtk_target_list_new*(targets: PGtkTargetEntry, ntargets: guint): PGtkTargetList{.
    cdecl, dynlib: gtklib, importc: "gtk_target_list_new".}
proc gtk_target_list_ref*(list: PGtkTargetList){.cdecl, dynlib: gtklib,
    importc: "gtk_target_list_ref".}
proc gtk_target_list_unref*(list: PGtkTargetList){.cdecl, dynlib: gtklib,
    importc: "gtk_target_list_unref".}
proc gtk_target_list_add*(list: PGtkTargetList, target: TGdkAtom, flags: guint,
                          info: guint){.cdecl, dynlib: gtklib,
                                        importc: "gtk_target_list_add".}
proc gtk_target_list_add_table*(list: PGtkTargetList, targets: PGtkTargetEntry,
                                ntargets: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_target_list_add_table".}
proc gtk_target_list_remove*(list: PGtkTargetList, target: TGdkAtom){.cdecl,
    dynlib: gtklib, importc: "gtk_target_list_remove".}
proc gtk_target_list_find*(list: PGtkTargetList, target: TGdkAtom, info: Pguint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_target_list_find".}
proc gtk_selection_owner_set*(widget: PGtkWidget, selection: TGdkAtom,
                              time: guint32): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_selection_owner_set".}
proc gtk_selection_owner_set_for_display*(display: PGdkDisplay,
    widget: PGtkWidget, selection: TGdkAtom, time: guint32): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_selection_owner_set_for_display".}
proc gtk_selection_add_target*(widget: PGtkWidget, selection: TGdkAtom,
                               target: TGdkAtom, info: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_selection_add_target".}
proc gtk_selection_add_targets*(widget: PGtkWidget, selection: TGdkAtom,
                                targets: PGtkTargetEntry, ntargets: guint){.
    cdecl, dynlib: gtklib, importc: "gtk_selection_add_targets".}
proc gtk_selection_clear_targets*(widget: PGtkWidget, selection: TGdkAtom){.
    cdecl, dynlib: gtklib, importc: "gtk_selection_clear_targets".}
proc gtk_selection_convert*(widget: PGtkWidget, selection: TGdkAtom,
                            target: TGdkAtom, time: guint32): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_selection_convert".}
proc gtk_selection_data_set*(selection_data: PGtkSelectionData,
                             thetype: TGdkAtom, format: gint, data: Pguchar,
                             length: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_selection_data_set".}
proc gtk_selection_data_set_text*(selection_data: PGtkSelectionData,
                                  str: cstring, len: gint): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_selection_data_set_text".}
proc gtk_selection_data_get_text*(selection_data: PGtkSelectionData): Pguchar{.
    cdecl, dynlib: gtklib, importc: "gtk_selection_data_get_text".}
proc gtk_selection_data_targets_include_text*(selection_data: PGtkSelectionData): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_selection_data_targets_include_text".}
proc gtk_selection_remove_all*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "gtk_selection_remove_all".}
proc gtk_selection_clear*(widget: PGtkWidget, event: PGdkEventSelection): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_selection_clear".}
proc gtk_selection_request*(widget: PGtkWidget, event: PGdkEventSelection): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_selection_request".}
proc gtk_selection_incr_event*(window: PGdkWindow, event: PGdkEventProperty): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_selection_incr_event".}
proc gtk_selection_notify*(widget: PGtkWidget, event: PGdkEventSelection): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_selection_notify".}
proc gtk_selection_property_notify*(widget: PGtkWidget, event: PGdkEventProperty): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_selection_property_notify".}
proc gtk_selection_data_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_selection_data_get_type".}
proc gtk_selection_data_copy*(data: PGtkSelectionData): PGtkSelectionData{.
    cdecl, dynlib: gtklib, importc: "gtk_selection_data_copy".}
proc gtk_selection_data_free*(data: PGtkSelectionData){.cdecl, dynlib: gtklib,
    importc: "gtk_selection_data_free".}
proc GTK_TYPE_SEPARATOR_MENU_ITEM*(): GType
proc GTK_SEPARATOR_MENU_ITEM*(obj: pointer): PGtkSeparatorMenuItem
proc GTK_SEPARATOR_MENU_ITEM_CLASS*(klass: pointer): PGtkSeparatorMenuItemClass
proc GTK_IS_SEPARATOR_MENU_ITEM*(obj: pointer): bool
proc GTK_IS_SEPARATOR_MENU_ITEM_CLASS*(klass: pointer): bool
proc GTK_SEPARATOR_MENU_ITEM_GET_CLASS*(obj: pointer): PGtkSeparatorMenuItemClass
proc gtk_separator_menu_item_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_separator_menu_item_get_type".}
proc gtk_separator_menu_item_new*(): PGtkSeparatorMenuItem{.cdecl, dynlib: gtklib,
    importc: "gtk_separator_menu_item_new".}
const
  bm_TGtkSizeGroup_have_width* = 0x00000001'i16
  bp_TGtkSizeGroup_have_width* = 0'i16
  bm_TGtkSizeGroup_have_height* = 0x00000002'i16
  bp_TGtkSizeGroup_have_height* = 1'i16

proc GTK_TYPE_SIZE_GROUP*(): GType
proc GTK_SIZE_GROUP*(obj: pointer): PGtkSizeGroup
proc GTK_SIZE_GROUP_CLASS*(klass: pointer): PGtkSizeGroupClass
proc GTK_IS_SIZE_GROUP*(obj: pointer): bool
proc GTK_IS_SIZE_GROUP_CLASS*(klass: pointer): bool
proc GTK_SIZE_GROUP_GET_CLASS*(obj: pointer): PGtkSizeGroupClass
proc have_width*(a: var TGtkSizeGroup): guint
proc set_have_width*(a: var TGtkSizeGroup, `have_width`: guint)
proc have_height*(a: var TGtkSizeGroup): guint
proc set_have_height*(a: var TGtkSizeGroup, `have_height`: guint)
proc gtk_size_group_get_type*(): GType{.cdecl, dynlib: gtklib,
                                        importc: "gtk_size_group_get_type".}
proc gtk_size_group_new*(mode: TGtkSizeGroupMode): PGtkSizeGroup{.cdecl,
    dynlib: gtklib, importc: "gtk_size_group_new".}
proc gtk_size_group_set_mode*(size_group: PGtkSizeGroup, mode: TGtkSizeGroupMode){.
    cdecl, dynlib: gtklib, importc: "gtk_size_group_set_mode".}
proc gtk_size_group_get_mode*(size_group: PGtkSizeGroup): TGtkSizeGroupMode{.
    cdecl, dynlib: gtklib, importc: "gtk_size_group_get_mode".}
proc gtk_size_group_add_widget*(size_group: PGtkSizeGroup, widget: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "gtk_size_group_add_widget".}
proc gtk_size_group_remove_widget*(size_group: PGtkSizeGroup, widget: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "gtk_size_group_remove_widget".}
proc gtk_size_group_get_child_requisition*(widget: PGtkWidget,
    requisition: PGtkRequisition){.cdecl, dynlib: gtklib, importc: "_gtk_size_group_get_child_requisition".}
proc gtk_size_group_compute_requisition*(widget: PGtkWidget,
    requisition: PGtkRequisition){.cdecl, dynlib: gtklib, importc: "_gtk_size_group_compute_requisition".}
proc gtk_size_group_queue_resize*(widget: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "_gtk_size_group_queue_resize".}
const
  bm_TGtkSocket_same_app* = 0x00000001'i16
  bp_TGtkSocket_same_app* = 0'i16
  bm_TGtkSocket_focus_in* = 0x00000002'i16
  bp_TGtkSocket_focus_in* = 1'i16
  bm_TGtkSocket_have_size* = 0x00000004'i16
  bp_TGtkSocket_have_size* = 2'i16
  bm_TGtkSocket_need_map* = 0x00000008'i16
  bp_TGtkSocket_need_map* = 3'i16
  bm_TGtkSocket_is_mapped* = 0x00000010'i16
  bp_TGtkSocket_is_mapped* = 4'i16

proc GTK_TYPE_SOCKET*(): GType
proc GTK_SOCKET*(obj: pointer): PGtkSocket
proc GTK_SOCKET_CLASS*(klass: pointer): PGtkSocketClass
proc GTK_IS_SOCKET*(obj: pointer): bool
proc GTK_IS_SOCKET_CLASS*(klass: pointer): bool
proc GTK_SOCKET_GET_CLASS*(obj: pointer): PGtkSocketClass
proc same_app*(a: var TGtkSocket): guint
proc set_same_app*(a: var TGtkSocket, `same_app`: guint)
proc focus_in*(a: var TGtkSocket): guint
proc set_focus_in*(a: var TGtkSocket, `focus_in`: guint)
proc have_size*(a: var TGtkSocket): guint
proc set_have_size*(a: var TGtkSocket, `have_size`: guint)
proc need_map*(a: var TGtkSocket): guint
proc set_need_map*(a: var TGtkSocket, `need_map`: guint)
proc is_mapped*(a: var TGtkSocket): guint
proc set_is_mapped*(a: var TGtkSocket, `is_mapped`: guint)
proc gtk_socket_new*(): PGtkSocket {.cdecl, dynlib: gtklib,
                                    importc: "gtk_socket_new".}
proc gtk_socket_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_socket_get_type".}
proc gtk_socket_add_id*(socket: PGtkSocket, window_id: TGdkNativeWindow){.cdecl,
    dynlib: gtklib, importc: "gtk_socket_add_id".}
proc gtk_socket_get_id*(socket: PGtkSocket): TGdkNativeWindow{.cdecl,
    dynlib: gtklib, importc: "gtk_socket_get_id".}
const
  GTK_INPUT_ERROR* = - (1)
  bm_TGtkSpinButton_in_child* = 0x00000003'i32
  bp_TGtkSpinButton_in_child* = 0'i32
  bm_TGtkSpinButton_click_child* = 0x0000000C'i32
  bp_TGtkSpinButton_click_child* = 2'i32
  bm_TGtkSpinButton_button* = 0x00000030'i32
  bp_TGtkSpinButton_button* = 4'i32
  bm_TGtkSpinButton_need_timer* = 0x00000040'i32
  bp_TGtkSpinButton_need_timer* = 6'i32
  bm_TGtkSpinButton_timer_calls* = 0x00000380'i32
  bp_TGtkSpinButton_timer_calls* = 7'i32
  bm_TGtkSpinButton_digits* = 0x000FFC00'i32
  bp_TGtkSpinButton_digits* = 10'i32
  bm_TGtkSpinButton_numeric* = 0x00100000'i32
  bp_TGtkSpinButton_numeric* = 20'i32
  bm_TGtkSpinButton_wrap* = 0x00200000'i32
  bp_TGtkSpinButton_wrap* = 21'i32
  bm_TGtkSpinButton_snap_to_ticks* = 0x00400000'i32
  bp_TGtkSpinButton_snap_to_ticks* = 22'i32

proc GTK_TYPE_SPIN_BUTTON*(): GType
proc GTK_SPIN_BUTTON*(obj: pointer): PGtkSpinButton
proc GTK_SPIN_BUTTON_CLASS*(klass: pointer): PGtkSpinButtonClass
proc GTK_IS_SPIN_BUTTON*(obj: pointer): bool
proc GTK_IS_SPIN_BUTTON_CLASS*(klass: pointer): bool
proc GTK_SPIN_BUTTON_GET_CLASS*(obj: pointer): PGtkSpinButtonClass
proc in_child*(a: var TGtkSpinButton): guint
proc set_in_child*(a: var TGtkSpinButton, `in_child`: guint)
proc click_child*(a: var TGtkSpinButton): guint
proc set_click_child*(a: var TGtkSpinButton, `click_child`: guint)
proc button*(a: var TGtkSpinButton): guint
proc set_button*(a: var TGtkSpinButton, `button`: guint)
proc need_timer*(a: var TGtkSpinButton): guint
proc set_need_timer*(a: var TGtkSpinButton, `need_timer`: guint)
proc timer_calls*(a: var TGtkSpinButton): guint
proc set_timer_calls*(a: var TGtkSpinButton, `timer_calls`: guint)
proc digits*(a: var TGtkSpinButton): guint
proc set_digits*(a: var TGtkSpinButton, `digits`: guint)
proc numeric*(a: var TGtkSpinButton): guint
proc set_numeric*(a: var TGtkSpinButton, `numeric`: guint)
proc wrap*(a: var TGtkSpinButton): guint
proc set_wrap*(a: var TGtkSpinButton, `wrap`: guint)
proc snap_to_ticks*(a: var TGtkSpinButton): guint
proc set_snap_to_ticks*(a: var TGtkSpinButton, `snap_to_ticks`: guint)
proc gtk_spin_button_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_spin_button_get_type".}
proc gtk_spin_button_configure*(spin_button: PGtkSpinButton,
                                adjustment: PGtkAdjustment, climb_rate: gdouble,
                                digits: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_spin_button_configure".}
proc gtk_spin_button_new*(adjustment: PGtkAdjustment, climb_rate: gdouble,
                          digits: guint): PGtkSpinButton{.cdecl, dynlib: gtklib,
    importc: "gtk_spin_button_new".}
proc gtk_spin_button_new_with_range*(min: gdouble, max: gdouble, step: gdouble): PGtkSpinButton{.
    cdecl, dynlib: gtklib, importc: "gtk_spin_button_new_with_range".}
proc gtk_spin_button_set_adjustment*(spin_button: PGtkSpinButton,
                                     adjustment: PGtkAdjustment){.cdecl,
    dynlib: gtklib, importc: "gtk_spin_button_set_adjustment".}
proc gtk_spin_button_get_adjustment*(spin_button: PGtkSpinButton): PGtkAdjustment{.
    cdecl, dynlib: gtklib, importc: "gtk_spin_button_get_adjustment".}
proc gtk_spin_button_set_digits*(spin_button: PGtkSpinButton, digits: guint){.
    cdecl, dynlib: gtklib, importc: "gtk_spin_button_set_digits".}
proc gtk_spin_button_get_digits*(spin_button: PGtkSpinButton): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_spin_button_get_digits".}
proc gtk_spin_button_set_increments*(spin_button: PGtkSpinButton, step: gdouble,
                                     page: gdouble){.cdecl, dynlib: gtklib,
    importc: "gtk_spin_button_set_increments".}
proc gtk_spin_button_get_increments*(spin_button: PGtkSpinButton,
                                     step: Pgdouble, page: Pgdouble){.cdecl,
    dynlib: gtklib, importc: "gtk_spin_button_get_increments".}
proc gtk_spin_button_set_range*(spin_button: PGtkSpinButton, min: gdouble,
                                max: gdouble){.cdecl, dynlib: gtklib,
    importc: "gtk_spin_button_set_range".}
proc gtk_spin_button_get_range*(spin_button: PGtkSpinButton, min: Pgdouble,
                                max: Pgdouble){.cdecl, dynlib: gtklib,
    importc: "gtk_spin_button_get_range".}
proc gtk_spin_button_get_value*(spin_button: PGtkSpinButton): gdouble{.cdecl,
    dynlib: gtklib, importc: "gtk_spin_button_get_value".}
proc gtk_spin_button_get_value_as_int*(spin_button: PGtkSpinButton): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_spin_button_get_value_as_int".}
proc gtk_spin_button_set_value*(spin_button: PGtkSpinButton, value: gdouble){.
    cdecl, dynlib: gtklib, importc: "gtk_spin_button_set_value".}
proc gtk_spin_button_set_update_policy*(spin_button: PGtkSpinButton,
                                        policy: TGtkSpinButtonUpdatePolicy){.
    cdecl, dynlib: gtklib, importc: "gtk_spin_button_set_update_policy".}
proc gtk_spin_button_get_update_policy*(spin_button: PGtkSpinButton): TGtkSpinButtonUpdatePolicy{.
    cdecl, dynlib: gtklib, importc: "gtk_spin_button_get_update_policy".}
proc gtk_spin_button_set_numeric*(spin_button: PGtkSpinButton, numeric: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_spin_button_set_numeric".}
proc gtk_spin_button_get_numeric*(spin_button: PGtkSpinButton): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_spin_button_get_numeric".}
proc gtk_spin_button_spin*(spin_button: PGtkSpinButton, direction: TGtkSpinType,
                           increment: gdouble){.cdecl, dynlib: gtklib,
    importc: "gtk_spin_button_spin".}
proc gtk_spin_button_set_wrap*(spin_button: PGtkSpinButton, wrap: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_spin_button_set_wrap".}
proc gtk_spin_button_get_wrap*(spin_button: PGtkSpinButton): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_spin_button_get_wrap".}
proc gtk_spin_button_set_snap_to_ticks*(spin_button: PGtkSpinButton,
                                        snap_to_ticks: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_spin_button_set_snap_to_ticks".}
proc gtk_spin_button_get_snap_to_ticks*(spin_button: PGtkSpinButton): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_spin_button_get_snap_to_ticks".}
proc gtk_spin_button_update*(spin_button: PGtkSpinButton){.cdecl,
    dynlib: gtklib, importc: "gtk_spin_button_update".}
const
  GTK_STOCK_DIALOG_INFO* = "gtk-dialog-info"
  GTK_STOCK_DIALOG_WARNING* = "gtk-dialog-warning"
  GTK_STOCK_DIALOG_ERROR* = "gtk-dialog-error"
  GTK_STOCK_DIALOG_QUESTION* = "gtk-dialog-question"
  GTK_STOCK_DND* = "gtk-dnd"
  GTK_STOCK_DND_MULTIPLE* = "gtk-dnd-multiple"
  GTK_STOCK_ABOUT* = "gtk-about"
  GTK_STOCK_ADD_name* = "gtk-add"
  GTK_STOCK_APPLY* = "gtk-apply"
  GTK_STOCK_BOLD* = "gtk-bold"
  GTK_STOCK_CANCEL* = "gtk-cancel"
  GTK_STOCK_CDROM* = "gtk-cdrom"
  GTK_STOCK_CLEAR* = "gtk-clear"
  GTK_STOCK_CLOSE* = "gtk-close"
  GTK_STOCK_COLOR_PICKER* = "gtk-color-picker"
  GTK_STOCK_CONVERT* = "gtk-convert"
  GTK_STOCK_CONNECT* = "gtk-connect"
  GTK_STOCK_COPY* = "gtk-copy"
  GTK_STOCK_CUT* = "gtk-cut"
  GTK_STOCK_DELETE* = "gtk-delete"
  GTK_STOCK_EDIT* = "gtk-edit"
  GTK_STOCK_EXECUTE* = "gtk-execute"
  GTK_STOCK_FIND* = "gtk-find"
  GTK_STOCK_FIND_AND_REPLACE* = "gtk-find-and-replace"
  GTK_STOCK_FLOPPY* = "gtk-floppy"
  GTK_STOCK_GOTO_BOTTOM* = "gtk-goto-bottom"
  GTK_STOCK_GOTO_FIRST* = "gtk-goto-first"
  GTK_STOCK_GOTO_LAST* = "gtk-goto-last"
  GTK_STOCK_GOTO_TOP* = "gtk-goto-top"
  GTK_STOCK_GO_BACK* = "gtk-go-back"
  GTK_STOCK_GO_DOWN* = "gtk-go-down"
  GTK_STOCK_GO_FORWARD* = "gtk-go-forward"
  GTK_STOCK_GO_UP* = "gtk-go-up"
  GTK_STOCK_HELP* = "gtk-help"
  GTK_STOCK_HOME* = "gtk-home"
  GTK_STOCK_INDEX* = "gtk-index"
  GTK_STOCK_ITALIC* = "gtk-italic"
  GTK_STOCK_JUMP_TO* = "gtk-jump-to"
  GTK_STOCK_JUSTIFY_CENTER* = "gtk-justify-center"
  GTK_STOCK_JUSTIFY_FILL* = "gtk-justify-fill"
  GTK_STOCK_JUSTIFY_LEFT* = "gtk-justify-left"
  GTK_STOCK_JUSTIFY_RIGHT* = "gtk-justify-right"
  GTK_STOCK_MEDIA_FORWARD* = "gtk-media-forward"
  GTK_STOCK_MEDIA_NEXT* = "gtk-media-next"
  GTK_STOCK_MEDIA_PAUSE* = "gtk-media-pause"
  GTK_STOCK_MEDIA_PLAY* = "gtk-media-play"
  GTK_STOCK_MEDIA_PREVIOUS* = "gtk-media-previous"
  GTK_STOCK_MEDIA_RECORD* = "gtk-media-record"
  GTK_STOCK_MEDIA_REWIND* = "gtk-media-rewind"
  GTK_STOCK_MEDIA_STOP* = "gtk-media-stop"
  GTK_STOCK_MISSING_IMAGE* = "gtk-missing-image"
  GTK_STOCK_NEW* = "gtk-new"
  GTK_STOCK_NO* = "gtk-no"
  GTK_STOCK_OK* = "gtk-ok"
  GTK_STOCK_OPEN* = "gtk-open"
  GTK_STOCK_PASTE* = "gtk-paste"
  GTK_STOCK_PREFERENCES* = "gtk-preferences"
  GTK_STOCK_PRINT* = "gtk-print"
  GTK_STOCK_PRINT_PREVIEW* = "gtk-print-preview"
  GTK_STOCK_PROPERTIES* = "gtk-properties"
  GTK_STOCK_QUIT* = "gtk-quit"
  GTK_STOCK_REDO* = "gtk-redo"
  GTK_STOCK_REFRESH* = "gtk-refresh"
  GTK_STOCK_REMOVE* = "gtk-remove"
  GTK_STOCK_REVERT_TO_SAVED* = "gtk-revert-to-saved"
  GTK_STOCK_SAVE* = "gtk-save"
  GTK_STOCK_SAVE_AS* = "gtk-save-as"
  GTK_STOCK_SELECT_COLOR* = "gtk-select-color"
  GTK_STOCK_SELECT_FONT* = "gtk-select-font"
  GTK_STOCK_SORT_ASCENDING* = "gtk-sort-ascending"
  GTK_STOCK_SORT_DESCENDING* = "gtk-sort-descending"
  GTK_STOCK_SPELL_CHECK* = "gtk-spell-check"
  GTK_STOCK_STOP* = "gtk-stop"
  GTK_STOCK_STRIKETHROUGH* = "gtk-strikethrough"
  GTK_STOCK_UNDELETE* = "gtk-undelete"
  GTK_STOCK_UNDERLINE* = "gtk-underline"
  GTK_STOCK_UNDO* = "gtk-undo"
  GTK_STOCK_YES* = "gtk-yes"
  GTK_STOCK_ZOOM_100* = "gtk-zoom-100"
  GTK_STOCK_ZOOM_FIT* = "gtk-zoom-fit"
  GTK_STOCK_ZOOM_IN* = "gtk-zoom-in"
  GTK_STOCK_ZOOM_OUT* = "gtk-zoom-out"

proc gtk_stock_add*(items: PGtkStockItem, n_items: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_stock_add".}
proc gtk_stock_add_static*(items: PGtkStockItem, n_items: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_stock_add_static".}
proc gtk_stock_lookup*(stock_id: cstring, item: PGtkStockItem): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_stock_lookup".}
proc gtk_stock_list_ids*(): PGSList{.cdecl, dynlib: gtklib,
                                     importc: "gtk_stock_list_ids".}
proc gtk_stock_item_copy*(item: PGtkStockItem): PGtkStockItem{.cdecl,
    dynlib: gtklib, importc: "gtk_stock_item_copy".}
proc gtk_stock_item_free*(item: PGtkStockItem){.cdecl, dynlib: gtklib,
    importc: "gtk_stock_item_free".}
proc GTK_TYPE_STATUSBAR*(): GType
proc GTK_STATUSBAR*(obj: pointer): PGtkStatusbar
proc GTK_STATUSBAR_CLASS*(klass: pointer): PGtkStatusbarClass
proc GTK_IS_STATUSBAR*(obj: pointer): bool
proc GTK_IS_STATUSBAR_CLASS*(klass: pointer): bool
proc GTK_STATUSBAR_GET_CLASS*(obj: pointer): PGtkStatusbarClass
const
  bm_TGtkStatusbar_has_resize_grip* = 0x00000001'i16
  bp_TGtkStatusbar_has_resize_grip* = 0'i16

proc has_resize_grip*(a: var TGtkStatusbar): guint
proc set_has_resize_grip*(a: var TGtkStatusbar, `has_resize_grip`: guint)
proc gtk_statusbar_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_statusbar_get_type".}
proc gtk_statusbar_new*(): PGtkStatusbar{.cdecl, dynlib: gtklib,
                                       importc: "gtk_statusbar_new".}
proc gtk_statusbar_get_context_id*(statusbar: PGtkStatusbar,
                                   context_description: cstring): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_statusbar_get_context_id".}
proc gtk_statusbar_push*(statusbar: PGtkStatusbar, context_id: guint,
                         text: cstring): guint{.cdecl, dynlib: gtklib,
    importc: "gtk_statusbar_push".}
proc gtk_statusbar_pop*(statusbar: PGtkStatusbar, context_id: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_statusbar_pop".}
proc gtk_statusbar_remove*(statusbar: PGtkStatusbar, context_id: guint,
                           message_id: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_statusbar_remove".}
proc gtk_statusbar_set_has_resize_grip*(statusbar: PGtkStatusbar,
                                        setting: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_statusbar_set_has_resize_grip".}
proc gtk_statusbar_get_has_resize_grip*(statusbar: PGtkStatusbar): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_statusbar_get_has_resize_grip".}
const
  bm_TGtkTable_homogeneous* = 0x00000001'i16
  bp_TGtkTable_homogeneous* = 0'i16
  bm_TGtkTableChild_xexpand* = 0x00000001'i16
  bp_TGtkTableChild_xexpand* = 0'i16
  bm_TGtkTableChild_yexpand* = 0x00000002'i16
  bp_TGtkTableChild_yexpand* = 1'i16
  bm_TGtkTableChild_xshrink* = 0x00000004'i16
  bp_TGtkTableChild_xshrink* = 2'i16
  bm_TGtkTableChild_yshrink* = 0x00000008'i16
  bp_TGtkTableChild_yshrink* = 3'i16
  bm_TGtkTableChild_xfill* = 0x00000010'i16
  bp_TGtkTableChild_xfill* = 4'i16
  bm_TGtkTableChild_yfill* = 0x00000020'i16
  bp_TGtkTableChild_yfill* = 5'i16
  bm_TGtkTableRowCol_need_expand* = 0x00000001'i16
  bp_TGtkTableRowCol_need_expand* = 0'i16
  bm_TGtkTableRowCol_need_shrink* = 0x00000002'i16
  bp_TGtkTableRowCol_need_shrink* = 1'i16
  bm_TGtkTableRowCol_expand* = 0x00000004'i16
  bp_TGtkTableRowCol_expand* = 2'i16
  bm_TGtkTableRowCol_shrink* = 0x00000008'i16
  bp_TGtkTableRowCol_shrink* = 3'i16
  bm_TGtkTableRowCol_empty* = 0x00000010'i16
  bp_TGtkTableRowCol_empty* = 4'i16

proc GTK_TYPE_TABLE*(): GType
proc GTK_TABLE*(obj: pointer): PGtkTable
proc GTK_TABLE_CLASS*(klass: pointer): PGtkTableClass
proc GTK_IS_TABLE*(obj: pointer): bool
proc GTK_IS_TABLE_CLASS*(klass: pointer): bool
proc GTK_TABLE_GET_CLASS*(obj: pointer): PGtkTableClass
proc homogeneous*(a: var TGtkTable): guint
proc set_homogeneous*(a: var TGtkTable, `homogeneous`: guint)
proc xexpand*(a: var TGtkTableChild): guint
proc set_xexpand*(a: var TGtkTableChild, `xexpand`: guint)
proc yexpand*(a: var TGtkTableChild): guint
proc set_yexpand*(a: var TGtkTableChild, `yexpand`: guint)
proc xshrink*(a: var TGtkTableChild): guint
proc set_xshrink*(a: var TGtkTableChild, `xshrink`: guint)
proc yshrink*(a: var TGtkTableChild): guint
proc set_yshrink*(a: var TGtkTableChild, `yshrink`: guint)
proc xfill*(a: var TGtkTableChild): guint
proc set_xfill*(a: var TGtkTableChild, `xfill`: guint)
proc yfill*(a: var TGtkTableChild): guint
proc set_yfill*(a: var TGtkTableChild, `yfill`: guint)
proc need_expand*(a: var TGtkTableRowCol): guint
proc set_need_expand*(a: var TGtkTableRowCol, `need_expand`: guint)
proc need_shrink*(a: var TGtkTableRowCol): guint
proc set_need_shrink*(a: var TGtkTableRowCol, `need_shrink`: guint)
proc expand*(a: var TGtkTableRowCol): guint
proc set_expand*(a: var TGtkTableRowCol, `expand`: guint)
proc shrink*(a: var TGtkTableRowCol): guint
proc set_shrink*(a: var TGtkTableRowCol, `shrink`: guint)
proc empty*(a: var TGtkTableRowCol): guint
proc set_empty*(a: var TGtkTableRowCol, `empty`: guint)
proc gtk_table_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_table_get_type".}
proc gtk_table_new*(rows: guint, columns: guint, homogeneous: gboolean): PGtkTable{.
    cdecl, dynlib: gtklib, importc: "gtk_table_new".}
proc gtk_table_resize*(table: PGtkTable, rows: guint, columns: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_table_resize".}
proc gtk_table_attach*(table: PGtkTable, child: PGtkWidget, left_attach: guint,
                       right_attach: guint, top_attach: guint,
                       bottom_attach: guint, xoptions: TGtkAttachOptions,
                       yoptions: TGtkAttachOptions, xpadding: guint,
                       ypadding: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_table_attach".}
proc gtk_table_attach_defaults*(table: PGtkTable, widget: PGtkWidget,
                                left_attach: guint, right_attach: guint,
                                top_attach: guint, bottom_attach: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_table_attach_defaults".}
proc gtk_table_set_row_spacing*(table: PGtkTable, row: guint, spacing: guint){.
    cdecl, dynlib: gtklib, importc: "gtk_table_set_row_spacing".}
proc gtk_table_get_row_spacing*(table: PGtkTable, row: guint): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_table_get_row_spacing".}
proc gtk_table_set_col_spacing*(table: PGtkTable, column: guint, spacing: guint){.
    cdecl, dynlib: gtklib, importc: "gtk_table_set_col_spacing".}
proc gtk_table_get_col_spacing*(table: PGtkTable, column: guint): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_table_get_col_spacing".}
proc gtk_table_set_row_spacings*(table: PGtkTable, spacing: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_table_set_row_spacings".}
proc gtk_table_get_default_row_spacing*(table: PGtkTable): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_table_get_default_row_spacing".}
proc gtk_table_set_col_spacings*(table: PGtkTable, spacing: guint){.cdecl,
    dynlib: gtklib, importc: "gtk_table_set_col_spacings".}
proc gtk_table_get_default_col_spacing*(table: PGtkTable): guint{.cdecl,
    dynlib: gtklib, importc: "gtk_table_get_default_col_spacing".}
proc gtk_table_set_homogeneous*(table: PGtkTable, homogeneous: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_table_set_homogeneous".}
proc gtk_table_get_homogeneous*(table: PGtkTable): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_table_get_homogeneous".}
const
  bm_TGtkTearoffMenuItem_torn_off* = 0x00000001'i16
  bp_TGtkTearoffMenuItem_torn_off* = 0'i16

proc GTK_TYPE_TEAROFF_MENU_ITEM*(): GType
proc GTK_TEAROFF_MENU_ITEM*(obj: pointer): PGtkTearoffMenuItem
proc GTK_TEAROFF_MENU_ITEM_CLASS*(klass: pointer): PGtkTearoffMenuItemClass
proc GTK_IS_TEAROFF_MENU_ITEM*(obj: pointer): bool
proc GTK_IS_TEAROFF_MENU_ITEM_CLASS*(klass: pointer): bool
proc GTK_TEAROFF_MENU_ITEM_GET_CLASS*(obj: pointer): PGtkTearoffMenuItemClass
proc torn_off*(a: var TGtkTearoffMenuItem): guint
proc set_torn_off*(a: var TGtkTearoffMenuItem, `torn_off`: guint)
proc gtk_tearoff_menu_item_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_tearoff_menu_item_get_type".}
proc gtk_tearoff_menu_item_new*(): PGtkTearoffMenuItem{.cdecl, dynlib: gtklib,
    importc: "gtk_tearoff_menu_item_new".}
const
  bm_TGtkText_line_wrap* = 0x00000001'i16
  bp_TGtkText_line_wrap* = 0'i16
  bm_TGtkText_word_wrap* = 0x00000002'i16
  bp_TGtkText_word_wrap* = 1'i16
  bm_TGtkText_use_wchar* = 0x00000004'i16
  bp_TGtkText_use_wchar* = 2'i16

proc GTK_TYPE_TEXT*(): GType
proc GTK_TEXT*(obj: pointer): PGtkText
proc GTK_TEXT_CLASS*(klass: pointer): PGtkTextClass
proc GTK_IS_TEXT*(obj: pointer): bool
proc GTK_IS_TEXT_CLASS*(klass: pointer): bool
proc GTK_TEXT_GET_CLASS*(obj: pointer): PGtkTextClass
proc line_wrap*(a: PGtkText): guint
proc set_line_wrap*(a: PGtkText, `line_wrap`: guint)
proc word_wrap*(a: PGtkText): guint
proc set_word_wrap*(a: PGtkText, `word_wrap`: guint)
proc use_wchar*(a: PGtkText): gboolean
proc set_use_wchar*(a: PGtkText, `use_wchar`: gboolean)
proc gtk_text_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                     importc: "gtk_text_get_type".}
proc gtk_text_new*(hadj: PGtkAdjustment, vadj: PGtkAdjustment): PGtkText{.
    cdecl, dynlib: gtklib, importc: "gtk_text_new".}
proc gtk_text_set_editable*(text: PGtkText, editable: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_text_set_editable".}
proc gtk_text_set_word_wrap*(text: PGtkText, word_wrap: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_text_set_word_wrap".}
proc gtk_text_set_line_wrap*(text: PGtkText, line_wrap: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_text_set_line_wrap".}
proc gtk_text_set_adjustments*(text: PGtkText, hadj: PGtkAdjustment,
                               vadj: PGtkAdjustment){.cdecl, dynlib: gtklib,
    importc: "gtk_text_set_adjustments".}
proc gtk_text_set_point*(text: PGtkText, index: guint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_set_point".}
proc gtk_text_get_point*(text: PGtkText): guint{.cdecl, dynlib: gtklib,
    importc: "gtk_text_get_point".}
proc gtk_text_get_length*(text: PGtkText): guint{.cdecl, dynlib: gtklib,
    importc: "gtk_text_get_length".}
proc gtk_text_freeze*(text: PGtkText){.cdecl, dynlib: gtklib,
                                       importc: "gtk_text_freeze".}
proc gtk_text_thaw*(text: PGtkText){.cdecl, dynlib: gtklib,
                                     importc: "gtk_text_thaw".}
proc gtk_text_insert*(text: PGtkText, font: PGdkFont, fore: PGdkColor,
                      back: PGdkColor, chars: cstring, length: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_text_insert".}
proc gtk_text_backward_delete*(text: PGtkText, nchars: guint): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_backward_delete".}
proc gtk_text_forward_delete*(text: PGtkText, nchars: guint): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_forward_delete".}
proc GTK_TEXT_INDEX_WCHAR*(t: PGtkText, index: guint): guint32
proc GTK_TEXT_INDEX_UCHAR*(t: PGtkText, index: guint): GUChar
const
  GTK_TEXT_SEARCH_VISIBLE_ONLY* = 0
  GTK_TEXT_SEARCH_TEXT_ONLY* = 1

proc GTK_TYPE_TEXT_ITER*(): GType
proc gtk_text_iter_get_buffer*(iter: PGtkTextIter): PGtkTextBuffer{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_buffer".}
proc gtk_text_iter_copy*(iter: PGtkTextIter): PGtkTextIter{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_copy".}
proc gtk_text_iter_free*(iter: PGtkTextIter){.cdecl, dynlib: gtklib,
    importc: "gtk_text_iter_free".}
proc gtk_text_iter_get_type*(): GType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_text_iter_get_type".}
proc gtk_text_iter_get_offset*(iter: PGtkTextIter): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_text_iter_get_offset".}
proc gtk_text_iter_get_line*(iter: PGtkTextIter): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_text_iter_get_line".}
proc gtk_text_iter_get_line_offset*(iter: PGtkTextIter): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_line_offset".}
proc gtk_text_iter_get_line_index*(iter: PGtkTextIter): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_line_index".}
proc gtk_text_iter_get_visible_line_offset*(iter: PGtkTextIter): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_visible_line_offset".}
proc gtk_text_iter_get_visible_line_index*(iter: PGtkTextIter): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_visible_line_index".}
proc gtk_text_iter_get_char*(iter: PGtkTextIter): gunichar{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_char".}
proc gtk_text_iter_get_slice*(start: PGtkTextIter, theEnd: PGtkTextIter): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_get_slice".}
proc gtk_text_iter_get_text*(start: PGtkTextIter, theEnd: PGtkTextIter): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_get_text".}
proc gtk_text_iter_get_visible_slice*(start: PGtkTextIter, theEnd: PGtkTextIter): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_get_visible_slice".}
proc gtk_text_iter_get_visible_text*(start: PGtkTextIter, theEnd: PGtkTextIter): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_get_visible_text".}
proc gtk_text_iter_get_pixbuf*(iter: PGtkTextIter): PGdkPixbuf{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_pixbuf".}
proc gtk_text_iter_get_marks*(iter: PGtkTextIter): PGSList{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_marks".}
proc gtk_text_iter_get_child_anchor*(iter: PGtkTextIter): PGtkTextChildAnchor{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_get_child_anchor".}
proc gtk_text_iter_get_toggled_tags*(iter: PGtkTextIter, toggled_on: gboolean): PGSList{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_get_toggled_tags".}
proc gtk_text_iter_begins_tag*(iter: PGtkTextIter, tag: PGtkTextTag): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_begins_tag".}
proc gtk_text_iter_ends_tag*(iter: PGtkTextIter, tag: PGtkTextTag): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_ends_tag".}
proc gtk_text_iter_toggles_tag*(iter: PGtkTextIter, tag: PGtkTextTag): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_toggles_tag".}
proc gtk_text_iter_has_tag*(iter: PGtkTextIter, tag: PGtkTextTag): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_has_tag".}
proc gtk_text_iter_get_tags*(iter: PGtkTextIter): PGSList{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_tags".}
proc gtk_text_iter_editable*(iter: PGtkTextIter, default_setting: gboolean): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_editable".}
proc gtk_text_iter_can_insert*(iter: PGtkTextIter, default_editability: gboolean): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_can_insert".}
proc gtk_text_iter_starts_word*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_starts_word".}
proc gtk_text_iter_ends_word*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_ends_word".}
proc gtk_text_iter_inside_word*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_inside_word".}
proc gtk_text_iter_starts_sentence*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_starts_sentence".}
proc gtk_text_iter_ends_sentence*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_ends_sentence".}
proc gtk_text_iter_inside_sentence*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_inside_sentence".}
proc gtk_text_iter_starts_line*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_starts_line".}
proc gtk_text_iter_ends_line*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_ends_line".}
proc gtk_text_iter_is_cursor_position*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_is_cursor_position".}
proc gtk_text_iter_get_chars_in_line*(iter: PGtkTextIter): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_chars_in_line".}
proc gtk_text_iter_get_bytes_in_line*(iter: PGtkTextIter): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_bytes_in_line".}
proc gtk_text_iter_get_attributes*(iter: PGtkTextIter,
                                   values: PGtkTextAttributes): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_attributes".}
proc gtk_text_iter_get_language*(iter: PGtkTextIter): PPangoLanguage{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_get_language".}
proc gtk_text_iter_is_end*(iter: PGtkTextIter): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_text_iter_is_end".}
proc gtk_text_iter_is_start*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_is_start".}
proc gtk_text_iter_forward_char*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_forward_char".}
proc gtk_text_iter_backward_char*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_backward_char".}
proc gtk_text_iter_forward_chars*(iter: PGtkTextIter, count: gint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_forward_chars".}
proc gtk_text_iter_backward_chars*(iter: PGtkTextIter, count: gint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_backward_chars".}
proc gtk_text_iter_forward_line*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_forward_line".}
proc gtk_text_iter_backward_line*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_backward_line".}
proc gtk_text_iter_forward_lines*(iter: PGtkTextIter, count: gint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_forward_lines".}
proc gtk_text_iter_backward_lines*(iter: PGtkTextIter, count: gint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_backward_lines".}
proc gtk_text_iter_forward_word_end*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_forward_word_end".}
proc gtk_text_iter_backward_word_start*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_backward_word_start".}
proc gtk_text_iter_forward_word_ends*(iter: PGtkTextIter, count: gint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_forward_word_ends".}
proc gtk_text_iter_backward_word_starts*(iter: PGtkTextIter, count: gint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_backward_word_starts".}
proc gtk_text_iter_forward_sentence_end*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_forward_sentence_end".}
proc gtk_text_iter_backward_sentence_start*(iter: PGtkTextIter): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_backward_sentence_start".}
proc gtk_text_iter_forward_sentence_ends*(iter: PGtkTextIter, count: gint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_forward_sentence_ends".}
proc gtk_text_iter_backward_sentence_starts*(iter: PGtkTextIter, count: gint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_backward_sentence_starts".}
proc gtk_text_iter_forward_cursor_position*(iter: PGtkTextIter): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_forward_cursor_position".}
proc gtk_text_iter_backward_cursor_position*(iter: PGtkTextIter): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_backward_cursor_position".}
proc gtk_text_iter_forward_cursor_positions*(iter: PGtkTextIter, count: gint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_forward_cursor_positions".}
proc gtk_text_iter_backward_cursor_positions*(iter: PGtkTextIter, count: gint): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_backward_cursor_positions".}
proc gtk_text_iter_set_offset*(iter: PGtkTextIter, char_offset: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_set_offset".}
proc gtk_text_iter_set_line*(iter: PGtkTextIter, line_number: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_set_line".}
proc gtk_text_iter_set_line_offset*(iter: PGtkTextIter, char_on_line: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_set_line_offset".}
proc gtk_text_iter_set_line_index*(iter: PGtkTextIter, byte_on_line: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_set_line_index".}
proc gtk_text_iter_forward_to_end*(iter: PGtkTextIter){.cdecl, dynlib: gtklib,
    importc: "gtk_text_iter_forward_to_end".}
proc gtk_text_iter_forward_to_line_end*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_forward_to_line_end".}
proc gtk_text_iter_set_visible_line_offset*(iter: PGtkTextIter,
    char_on_line: gint){.cdecl, dynlib: gtklib,
                         importc: "gtk_text_iter_set_visible_line_offset".}
proc gtk_text_iter_set_visible_line_index*(iter: PGtkTextIter,
    byte_on_line: gint){.cdecl, dynlib: gtklib,
                         importc: "gtk_text_iter_set_visible_line_index".}
proc gtk_text_iter_forward_to_tag_toggle*(iter: PGtkTextIter, tag: PGtkTextTag): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_forward_to_tag_toggle".}
proc gtk_text_iter_backward_to_tag_toggle*(iter: PGtkTextIter, tag: PGtkTextTag): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_backward_to_tag_toggle".}
proc gtk_text_iter_forward_find_char*(iter: PGtkTextIter,
                                      pred: TGtkTextCharPredicate,
                                      user_data: gpointer, limit: PGtkTextIter): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_forward_find_char".}
proc gtk_text_iter_backward_find_char*(iter: PGtkTextIter,
                                       pred: TGtkTextCharPredicate,
                                       user_data: gpointer, limit: PGtkTextIter): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_backward_find_char".}
proc gtk_text_iter_forward_search*(iter: PGtkTextIter, str: cstring,
                                   flags: TGtkTextSearchFlags,
                                   match_start: PGtkTextIter,
                                   match_end: PGtkTextIter, limit: PGtkTextIter): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_forward_search".}
proc gtk_text_iter_backward_search*(iter: PGtkTextIter, str: cstring,
                                    flags: TGtkTextSearchFlags,
                                    match_start: PGtkTextIter,
                                    match_end: PGtkTextIter, limit: PGtkTextIter): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_backward_search".}
proc gtk_text_iter_equal*(lhs: PGtkTextIter, rhs: PGtkTextIter): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_iter_equal".}
proc gtk_text_iter_compare*(lhs: PGtkTextIter, rhs: PGtkTextIter): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_compare".}
proc gtk_text_iter_in_range*(iter: PGtkTextIter, start: PGtkTextIter,
                             theEnd: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_in_range".}
proc gtk_text_iter_order*(first: PGtkTextIter, second: PGtkTextIter){.cdecl,
    dynlib: gtklib, importc: "gtk_text_iter_order".}
proc GTK_TYPE_TEXT_TAG*(): GType
proc GTK_TEXT_TAG*(obj: pointer): PGtkTextTag
proc GTK_TEXT_TAG_CLASS*(klass: pointer): PGtkTextTagClass
proc GTK_IS_TEXT_TAG*(obj: pointer): bool
proc GTK_IS_TEXT_TAG_CLASS*(klass: pointer): bool
proc GTK_TEXT_TAG_GET_CLASS*(obj: pointer): PGtkTextTagClass
proc GTK_TYPE_TEXT_ATTRIBUTES*(): GType
proc gtk_text_tag_get_type*(): GType{.cdecl, dynlib: gtklib,
                                      importc: "gtk_text_tag_get_type".}
proc gtk_text_tag_new*(name: cstring): PGtkTextTag{.cdecl, dynlib: gtklib,
    importc: "gtk_text_tag_new".}
proc gtk_text_tag_get_priority*(tag: PGtkTextTag): gint{.cdecl, dynlib: gtklib,
    importc: "gtk_text_tag_get_priority".}
proc gtk_text_tag_set_priority*(tag: PGtkTextTag, priority: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_text_tag_set_priority".}
proc gtk_text_tag_event*(tag: PGtkTextTag, event_object: PGObject,
                         event: PGdkEvent, iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_tag_event".}
proc gtk_text_attributes_new*(): PGtkTextAttributes{.cdecl, dynlib: gtklib,
    importc: "gtk_text_attributes_new".}
proc gtk_text_attributes_copy*(src: PGtkTextAttributes): PGtkTextAttributes{.
    cdecl, dynlib: gtklib, importc: "gtk_text_attributes_copy".}
proc gtk_text_attributes_copy_values*(src: PGtkTextAttributes,
                                      dest: PGtkTextAttributes){.cdecl,
    dynlib: gtklib, importc: "gtk_text_attributes_copy_values".}
proc gtk_text_attributes_unref*(values: PGtkTextAttributes){.cdecl,
    dynlib: gtklib, importc: "gtk_text_attributes_unref".}
proc gtk_text_attributes_ref*(values: PGtkTextAttributes){.cdecl,
    dynlib: gtklib, importc: "gtk_text_attributes_ref".}
proc gtk_text_attributes_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_text_attributes_get_type".}
const
  bm_TGtkTextTag_bg_color_set* = 0x00000001'i32
  bp_TGtkTextTag_bg_color_set* = 0'i32
  bm_TGtkTextTag_bg_stipple_set* = 0x00000002'i32
  bp_TGtkTextTag_bg_stipple_set* = 1'i32
  bm_TGtkTextTag_fg_color_set* = 0x00000004'i32
  bp_TGtkTextTag_fg_color_set* = 2'i32
  bm_TGtkTextTag_scale_set* = 0x00000008'i32
  bp_TGtkTextTag_scale_set* = 3'i32
  bm_TGtkTextTag_fg_stipple_set* = 0x00000010'i32
  bp_TGtkTextTag_fg_stipple_set* = 4'i32
  bm_TGtkTextTag_justification_set* = 0x00000020'i32
  bp_TGtkTextTag_justification_set* = 5'i32
  bm_TGtkTextTag_left_margin_set* = 0x00000040'i32
  bp_TGtkTextTag_left_margin_set* = 6'i32
  bm_TGtkTextTag_indent_set* = 0x00000080'i32
  bp_TGtkTextTag_indent_set* = 7'i32
  bm_TGtkTextTag_rise_set* = 0x00000100'i32
  bp_TGtkTextTag_rise_set* = 8'i32
  bm_TGtkTextTag_strikethrough_set* = 0x00000200'i32
  bp_TGtkTextTag_strikethrough_set* = 9'i32
  bm_TGtkTextTag_right_margin_set* = 0x00000400'i32
  bp_TGtkTextTag_right_margin_set* = 10'i32
  bm_TGtkTextTag_pixels_above_lines_set* = 0x00000800'i32
  bp_TGtkTextTag_pixels_above_lines_set* = 11'i32
  bm_TGtkTextTag_pixels_below_lines_set* = 0x00001000'i32
  bp_TGtkTextTag_pixels_below_lines_set* = 12'i32
  bm_TGtkTextTag_pixels_inside_wrap_set* = 0x00002000'i32
  bp_TGtkTextTag_pixels_inside_wrap_set* = 13'i32
  bm_TGtkTextTag_tabs_set* = 0x00004000'i32
  bp_TGtkTextTag_tabs_set* = 14'i32
  bm_TGtkTextTag_underline_set* = 0x00008000'i32
  bp_TGtkTextTag_underline_set* = 15'i32
  bm_TGtkTextTag_wrap_mode_set* = 0x00010000'i32
  bp_TGtkTextTag_wrap_mode_set* = 16'i32
  bm_TGtkTextTag_bg_full_height_set* = 0x00020000'i32
  bp_TGtkTextTag_bg_full_height_set* = 17'i32
  bm_TGtkTextTag_invisible_set* = 0x00040000'i32
  bp_TGtkTextTag_invisible_set* = 18'i32
  bm_TGtkTextTag_editable_set* = 0x00080000'i32
  bp_TGtkTextTag_editable_set* = 19'i32
  bm_TGtkTextTag_language_set* = 0x00100000'i32
  bp_TGtkTextTag_language_set* = 20'i32
  bm_TGtkTextTag_pad1* = 0x00200000'i32
  bp_TGtkTextTag_pad1* = 21'i32
  bm_TGtkTextTag_pad2* = 0x00400000'i32
  bp_TGtkTextTag_pad2* = 22'i32
  bm_TGtkTextTag_pad3* = 0x00800000'i32
  bp_TGtkTextTag_pad3* = 23'i32

proc bg_color_set*(a: var TGtkTextTag): guint
proc set_bg_color_set*(a: var TGtkTextTag, `bg_color_set`: guint)
proc bg_stipple_set*(a: var TGtkTextTag): guint
proc set_bg_stipple_set*(a: var TGtkTextTag, `bg_stipple_set`: guint)
proc fg_color_set*(a: var TGtkTextTag): guint
proc set_fg_color_set*(a: var TGtkTextTag, `fg_color_set`: guint)
proc scale_set*(a: var TGtkTextTag): guint
proc set_scale_set*(a: var TGtkTextTag, `scale_set`: guint)
proc fg_stipple_set*(a: var TGtkTextTag): guint
proc set_fg_stipple_set*(a: var TGtkTextTag, `fg_stipple_set`: guint)
proc justification_set*(a: var TGtkTextTag): guint
proc set_justification_set*(a: var TGtkTextTag, `justification_set`: guint)
proc left_margin_set*(a: var TGtkTextTag): guint
proc set_left_margin_set*(a: var TGtkTextTag, `left_margin_set`: guint)
proc indent_set*(a: var TGtkTextTag): guint
proc set_indent_set*(a: var TGtkTextTag, `indent_set`: guint)
proc rise_set*(a: var TGtkTextTag): guint
proc set_rise_set*(a: var TGtkTextTag, `rise_set`: guint)
proc strikethrough_set*(a: var TGtkTextTag): guint
proc set_strikethrough_set*(a: var TGtkTextTag, `strikethrough_set`: guint)
proc right_margin_set*(a: var TGtkTextTag): guint
proc set_right_margin_set*(a: var TGtkTextTag, `right_margin_set`: guint)
proc pixels_above_lines_set*(a: var TGtkTextTag): guint
proc set_pixels_above_lines_set*(a: var TGtkTextTag,
                                 `pixels_above_lines_set`: guint)
proc pixels_below_lines_set*(a: var TGtkTextTag): guint
proc set_pixels_below_lines_set*(a: var TGtkTextTag,
                                 `pixels_below_lines_set`: guint)
proc pixels_inside_wrap_set*(a: var TGtkTextTag): guint
proc set_pixels_inside_wrap_set*(a: var TGtkTextTag,
                                 `pixels_inside_wrap_set`: guint)
proc tabs_set*(a: var TGtkTextTag): guint
proc set_tabs_set*(a: var TGtkTextTag, `tabs_set`: guint)
proc underline_set*(a: var TGtkTextTag): guint
proc set_underline_set*(a: var TGtkTextTag, `underline_set`: guint)
proc wrap_mode_set*(a: var TGtkTextTag): guint
proc set_wrap_mode_set*(a: var TGtkTextTag, `wrap_mode_set`: guint)
proc bg_full_height_set*(a: var TGtkTextTag): guint
proc set_bg_full_height_set*(a: var TGtkTextTag, `bg_full_height_set`: guint)
proc invisible_set*(a: var TGtkTextTag): guint
proc set_invisible_set*(a: var TGtkTextTag, `invisible_set`: guint)
proc editable_set*(a: var TGtkTextTag): guint
proc set_editable_set*(a: var TGtkTextTag, `editable_set`: guint)
proc language_set*(a: var TGtkTextTag): guint
proc set_language_set*(a: var TGtkTextTag, `language_set`: guint)
proc pad1*(a: var TGtkTextTag): guint
proc set_pad1*(a: var TGtkTextTag, `pad1`: guint)
proc pad2*(a: var TGtkTextTag): guint
proc set_pad2*(a: var TGtkTextTag, `pad2`: guint)
proc pad3*(a: var TGtkTextTag): guint
proc set_pad3*(a: var TGtkTextTag, `pad3`: guint)
const
  bm_TGtkTextAppearance_underline* = 0x0000000F'i16
  bp_TGtkTextAppearance_underline* = 0'i16
  bm_TGtkTextAppearance_strikethrough* = 0x00000010'i16
  bp_TGtkTextAppearance_strikethrough* = 4'i16
  bm_TGtkTextAppearance_draw_bg* = 0x00000020'i16
  bp_TGtkTextAppearance_draw_bg* = 5'i16
  bm_TGtkTextAppearance_inside_selection* = 0x00000040'i16
  bp_TGtkTextAppearance_inside_selection* = 6'i16
  bm_TGtkTextAppearance_is_text* = 0x00000080'i16
  bp_TGtkTextAppearance_is_text* = 7'i16
  bm_TGtkTextAppearance_pad1* = 0x00000100'i16
  bp_TGtkTextAppearance_pad1* = 8'i16
  bm_TGtkTextAppearance_pad2* = 0x00000200'i16
  bp_TGtkTextAppearance_pad2* = 9'i16
  bm_TGtkTextAppearance_pad3* = 0x00000400'i16
  bp_TGtkTextAppearance_pad3* = 10'i16
  bm_TGtkTextAppearance_pad4* = 0x00000800'i16
  bp_TGtkTextAppearance_pad4* = 11'i16

proc underline*(a: var TGtkTextAppearance): guint
proc set_underline*(a: var TGtkTextAppearance, `underline`: guint)
proc strikethrough*(a: var TGtkTextAppearance): guint
proc set_strikethrough*(a: var TGtkTextAppearance, `strikethrough`: guint)
proc draw_bg*(a: var TGtkTextAppearance): guint
proc set_draw_bg*(a: var TGtkTextAppearance, `draw_bg`: guint)
proc inside_selection*(a: var TGtkTextAppearance): guint
proc set_inside_selection*(a: var TGtkTextAppearance, `inside_selection`: guint)
proc is_text*(a: var TGtkTextAppearance): guint
proc set_is_text*(a: var TGtkTextAppearance, `is_text`: guint)
proc pad1*(a: var TGtkTextAppearance): guint
proc set_pad1*(a: var TGtkTextAppearance, `pad1`: guint)
proc pad2*(a: var TGtkTextAppearance): guint
proc set_pad2*(a: var TGtkTextAppearance, `pad2`: guint)
proc pad3*(a: var TGtkTextAppearance): guint
proc set_pad3*(a: var TGtkTextAppearance, `pad3`: guint)
proc pad4*(a: var TGtkTextAppearance): guint
proc set_pad4*(a: var TGtkTextAppearance, `pad4`: guint)
const
  bm_TGtkTextAttributes_invisible* = 0x00000001'i16
  bp_TGtkTextAttributes_invisible* = 0'i16
  bm_TGtkTextAttributes_bg_full_height* = 0x00000002'i16
  bp_TGtkTextAttributes_bg_full_height* = 1'i16
  bm_TGtkTextAttributes_editable* = 0x00000004'i16
  bp_TGtkTextAttributes_editable* = 2'i16
  bm_TGtkTextAttributes_realized* = 0x00000008'i16
  bp_TGtkTextAttributes_realized* = 3'i16
  bm_TGtkTextAttributes_pad1* = 0x00000010'i16
  bp_TGtkTextAttributes_pad1* = 4'i16
  bm_TGtkTextAttributes_pad2* = 0x00000020'i16
  bp_TGtkTextAttributes_pad2* = 5'i16
  bm_TGtkTextAttributes_pad3* = 0x00000040'i16
  bp_TGtkTextAttributes_pad3* = 6'i16
  bm_TGtkTextAttributes_pad4* = 0x00000080'i16
  bp_TGtkTextAttributes_pad4* = 7'i16

proc invisible*(a: var TGtkTextAttributes): guint
proc set_invisible*(a: var TGtkTextAttributes, `invisible`: guint)
proc bg_full_height*(a: var TGtkTextAttributes): guint
proc set_bg_full_height*(a: var TGtkTextAttributes, `bg_full_height`: guint)
proc editable*(a: var TGtkTextAttributes): guint
proc set_editable*(a: var TGtkTextAttributes, `editable`: guint)
proc realized*(a: var TGtkTextAttributes): guint
proc set_realized*(a: var TGtkTextAttributes, `realized`: guint)
proc pad1*(a: var TGtkTextAttributes): guint
proc set_pad1*(a: var TGtkTextAttributes, `pad1`: guint)
proc pad2*(a: var TGtkTextAttributes): guint
proc set_pad2*(a: var TGtkTextAttributes, `pad2`: guint)
proc pad3*(a: var TGtkTextAttributes): guint
proc set_pad3*(a: var TGtkTextAttributes, `pad3`: guint)
proc pad4*(a: var TGtkTextAttributes): guint
proc set_pad4*(a: var TGtkTextAttributes, `pad4`: guint)
proc GTK_TYPE_TEXT_TAG_TABLE*(): GType
proc GTK_TEXT_TAG_TABLE*(obj: pointer): PGtkTextTagTable
proc GTK_TEXT_TAG_TABLE_CLASS*(klass: pointer): PGtkTextTagTableClass
proc GTK_IS_TEXT_TAG_TABLE*(obj: pointer): bool
proc GTK_IS_TEXT_TAG_TABLE_CLASS*(klass: pointer): bool
proc GTK_TEXT_TAG_TABLE_GET_CLASS*(obj: pointer): PGtkTextTagTableClass
proc gtk_text_tag_table_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_text_tag_table_get_type".}
proc gtk_text_tag_table_new*(): PGtkTextTagTable{.cdecl, dynlib: gtklib,
    importc: "gtk_text_tag_table_new".}
proc gtk_text_tag_table_add*(table: PGtkTextTagTable, tag: PGtkTextTag){.cdecl,
    dynlib: gtklib, importc: "gtk_text_tag_table_add".}
proc gtk_text_tag_table_remove*(table: PGtkTextTagTable, tag: PGtkTextTag){.
    cdecl, dynlib: gtklib, importc: "gtk_text_tag_table_remove".}
proc gtk_text_tag_table_lookup*(table: PGtkTextTagTable, name: cstring): PGtkTextTag{.
    cdecl, dynlib: gtklib, importc: "gtk_text_tag_table_lookup".}
proc gtk_text_tag_table_foreach*(table: PGtkTextTagTable,
                                 fun: TGtkTextTagTableForeach, data: gpointer){.
    cdecl, dynlib: gtklib, importc: "gtk_text_tag_table_foreach".}
proc gtk_text_tag_table_get_size*(table: PGtkTextTagTable): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_tag_table_get_size".}
proc gtk_text_tag_table_add_buffer*(table: PGtkTextTagTable, buffer: gpointer){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_tag_table_add_buffer".}
proc gtk_text_tag_table_remove_buffer*(table: PGtkTextTagTable,
    buffer: gpointer){.cdecl, dynlib: gtklib,
                       importc: "_gtk_text_tag_table_remove_buffer".}
proc GTK_TYPE_TEXT_MARK*(): GType
proc GTK_TEXT_MARK*(anObject: pointer): PGtkTextMark
proc GTK_TEXT_MARK_CLASS*(klass: pointer): PGtkTextMarkClass
proc GTK_IS_TEXT_MARK*(anObject: pointer): bool
proc GTK_IS_TEXT_MARK_CLASS*(klass: pointer): bool
proc GTK_TEXT_MARK_GET_CLASS*(obj: pointer): PGtkTextMarkClass
proc gtk_text_mark_get_type*(): GType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_text_mark_get_type".}
proc gtk_text_mark_set_visible*(mark: PGtkTextMark, setting: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_text_mark_set_visible".}
proc gtk_text_mark_get_visible*(mark: PGtkTextMark): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_mark_get_visible".}
proc gtk_text_mark_get_name*(mark: PGtkTextMark): cstring{.cdecl, dynlib: gtklib,
    importc: "gtk_text_mark_get_name".}
proc gtk_text_mark_get_deleted*(mark: PGtkTextMark): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_mark_get_deleted".}
proc gtk_text_mark_get_buffer*(mark: PGtkTextMark): PGtkTextBuffer{.cdecl,
    dynlib: gtklib, importc: "gtk_text_mark_get_buffer".}
proc gtk_text_mark_get_left_gravity*(mark: PGtkTextMark): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_mark_get_left_gravity".}
const
  bm_TGtkTextMarkBody_visible* = 0x00000001'i16
  bp_TGtkTextMarkBody_visible* = 0'i16
  bm_TGtkTextMarkBody_not_deleteable* = 0x00000002'i16
  bp_TGtkTextMarkBody_not_deleteable* = 1'i16

proc visible*(a: var TGtkTextMarkBody): guint
proc set_visible*(a: var TGtkTextMarkBody, `visible`: guint)
proc not_deleteable*(a: var TGtkTextMarkBody): guint
proc set_not_deleteable*(a: var TGtkTextMarkBody, `not_deleteable`: guint)
proc gtk_mark_segment_new*(tree: PGtkTextBTree, left_gravity: gboolean,
                             name: cstring): PGtkTextLineSegment{.cdecl,
    dynlib: gtklib, importc: "_gtk_mark_segment_new".}
proc GTK_TYPE_TEXT_CHILD_ANCHOR*(): GType
proc GTK_TEXT_CHILD_ANCHOR*(anObject: pointer): PGtkTextChildAnchor
proc GTK_TEXT_CHILD_ANCHOR_CLASS*(klass: pointer): PGtkTextChildAnchorClass
proc GTK_IS_TEXT_CHILD_ANCHOR*(anObject: pointer): bool
proc GTK_IS_TEXT_CHILD_ANCHOR_CLASS*(klass: pointer): bool
proc GTK_TEXT_CHILD_ANCHOR_GET_CLASS*(obj: pointer): PGtkTextChildAnchorClass
proc gtk_text_child_anchor_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_text_child_anchor_get_type".}
proc gtk_text_child_anchor_new*(): PGtkTextChildAnchor{.cdecl, dynlib: gtklib,
    importc: "gtk_text_child_anchor_new".}
proc gtk_text_child_anchor_get_widgets*(anchor: PGtkTextChildAnchor): PGList{.
    cdecl, dynlib: gtklib, importc: "gtk_text_child_anchor_get_widgets".}
proc gtk_text_child_anchor_get_deleted*(anchor: PGtkTextChildAnchor): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_child_anchor_get_deleted".}
proc gtk_pixbuf_segment_new*(pixbuf: PGdkPixbuf): PGtkTextLineSegment{.cdecl,
    dynlib: gtklib, importc: "_gtk_pixbuf_segment_new".}
proc gtk_widget_segment_new*(anchor: PGtkTextChildAnchor): PGtkTextLineSegment{.
    cdecl, dynlib: gtklib, importc: "_gtk_widget_segment_new".}
proc gtk_widget_segment_add*(widget_segment: PGtkTextLineSegment,
                               child: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "_gtk_widget_segment_add".}
proc gtk_widget_segment_remove*(widget_segment: PGtkTextLineSegment,
                                  child: PGtkWidget){.cdecl, dynlib: gtklib,
    importc: "_gtk_widget_segment_remove".}
proc gtk_widget_segment_ref*(widget_segment: PGtkTextLineSegment){.cdecl,
    dynlib: gtklib, importc: "_gtk_widget_segment_ref".}
proc gtk_widget_segment_unref*(widget_segment: PGtkTextLineSegment){.cdecl,
    dynlib: gtklib, importc: "_gtk_widget_segment_unref".}
proc gtk_anchored_child_get_layout*(child: PGtkWidget): PGtkTextLayout{.cdecl,
    dynlib: gtklib, importc: "_gtk_anchored_child_get_layout".}
proc gtk_text_line_segment_split*(iter: PGtkTextIter): PGtkTextLineSegment{.
    cdecl, dynlib: gtklib, importc: "gtk_text_line_segment_split".}
proc gtk_char_segment_new*(text: cstring, len: guint): PGtkTextLineSegment{.
    cdecl, dynlib: gtklib, importc: "_gtk_char_segment_new".}
proc gtk_char_segment_new_from_two_strings*(text1: cstring, len1: guint,
    text2: cstring, len2: guint): PGtkTextLineSegment{.cdecl, dynlib: gtklib,
    importc: "_gtk_char_segment_new_from_two_strings".}
proc gtk_toggle_segment_new*(info: PGtkTextTagInfo, StateOn: gboolean): PGtkTextLineSegment{.
    cdecl, dynlib: gtklib, importc: "_gtk_toggle_segment_new".}
proc gtk_text_btree_new*(table: PGtkTextTagTable, buffer: PGtkTextBuffer): PGtkTextBTree{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_new".}
proc gtk_text_btree_ref*(tree: PGtkTextBTree){.cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_ref".}
proc gtk_text_btree_unref*(tree: PGtkTextBTree){.cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_unref".}
proc gtk_text_btree_get_buffer*(tree: PGtkTextBTree): PGtkTextBuffer{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_get_buffer".}
proc gtk_text_btree_get_chars_changed_stamp*(tree: PGtkTextBTree): guint{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_get_chars_changed_stamp".}
proc gtk_text_btree_get_segments_changed_stamp*(tree: PGtkTextBTree): guint{.
    cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_get_segments_changed_stamp".}
proc gtk_text_btree_segments_changed*(tree: PGtkTextBTree){.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_segments_changed".}
proc gtk_text_btree_is_end*(tree: PGtkTextBTree, line: PGtkTextLine,
                              seg: PGtkTextLineSegment, byte_index: int32,
                              char_offset: int32): gboolean{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_is_end".}
proc gtk_text_btree_delete*(start: PGtkTextIter, theEnd: PGtkTextIter){.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_delete".}
proc gtk_text_btree_insert*(iter: PGtkTextIter, text: cstring, len: gint){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_insert".}
proc gtk_text_btree_insert_pixbuf*(iter: PGtkTextIter, pixbuf: PGdkPixbuf){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_insert_pixbuf".}
proc gtk_text_btree_insert_child_anchor*(iter: PGtkTextIter,
    anchor: PGtkTextChildAnchor){.cdecl, dynlib: gtklib, importc: "_gtk_text_btree_insert_child_anchor".}
proc gtk_text_btree_unregister_child_anchor*(anchor: PGtkTextChildAnchor){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_unregister_child_anchor".}
proc gtk_text_btree_find_line_by_y*(tree: PGtkTextBTree, view_id: gpointer,
                                      ypixel: gint, line_top_y: Pgint): PGtkTextLine{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_find_line_by_y".}
proc gtk_text_btree_find_line_top*(tree: PGtkTextBTree, line: PGtkTextLine,
                                     view_id: gpointer): gint{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_find_line_top".}
proc gtk_text_btree_add_view*(tree: PGtkTextBTree, layout: PGtkTextLayout){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_add_view".}
proc gtk_text_btree_remove_view*(tree: PGtkTextBTree, view_id: gpointer){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_remove_view".}
proc gtk_text_btree_invalidate_region*(tree: PGtkTextBTree,
    start: PGtkTextIter, theEnd: PGtkTextIter){.cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_invalidate_region".}
proc gtk_text_btree_get_view_size*(tree: PGtkTextBTree, view_id: gpointer,
                                     width: Pgint, height: Pgint){.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_get_view_size".}
proc gtk_text_btree_is_valid*(tree: PGtkTextBTree, view_id: gpointer): gboolean{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_is_valid".}
proc gtk_text_btree_validate*(tree: PGtkTextBTree, view_id: gpointer,
                                max_pixels: gint, y: Pgint, old_height: Pgint,
                                new_height: Pgint): gboolean{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_validate".}
proc gtk_text_btree_validate_line*(tree: PGtkTextBTree, line: PGtkTextLine,
                                     view_id: gpointer){.cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_validate_line".}
proc gtk_text_btree_tag*(start: PGtkTextIter, theEnd: PGtkTextIter,
                           tag: PGtkTextTag, apply: gboolean){.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_tag".}
proc gtk_text_btree_get_line*(tree: PGtkTextBTree, line_number: gint,
                                real_line_number: Pgint): PGtkTextLine{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_get_line".}
proc gtk_text_btree_get_line_no_last*(tree: PGtkTextBTree, line_number: gint,
                                        real_line_number: Pgint): PGtkTextLine{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_get_line_no_last".}
proc gtk_text_btree_get_end_iter_line*(tree: PGtkTextBTree): PGtkTextLine{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_get_end_iter_line".}
proc gtk_text_btree_get_line_at_char*(tree: PGtkTextBTree, char_index: gint,
                                        line_start_index: Pgint,
                                        real_char_index: Pgint): PGtkTextLine{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_get_line_at_char".}
proc gtk_text_btree_get_tags*(iter: PGtkTextIter, num_tags: Pgint): PPGtkTextTag{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_get_tags".}
proc gtk_text_btree_get_text*(start: PGtkTextIter, theEnd: PGtkTextIter,
                                include_hidden: gboolean,
                                include_nonchars: gboolean): cstring{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_get_text".}
proc gtk_text_btree_line_count*(tree: PGtkTextBTree): gint{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_line_count".}
proc gtk_text_btree_char_count*(tree: PGtkTextBTree): gint{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_char_count".}
proc gtk_text_btree_char_is_invisible*(iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_char_is_invisible".}
proc gtk_text_btree_get_iter_at_char*(tree: PGtkTextBTree, iter: PGtkTextIter,
                                        char_index: gint){.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_get_iter_at_char".}
proc gtk_text_btree_get_iter_at_line_char*(tree: PGtkTextBTree,
    iter: PGtkTextIter, line_number: gint, char_index: gint){.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_get_iter_at_line_char".}
proc gtk_text_btree_get_iter_at_line_byte*(tree: PGtkTextBTree,
    iter: PGtkTextIter, line_number: gint, byte_index: gint){.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_get_iter_at_line_byte".}
proc gtk_text_btree_get_iter_from_string*(tree: PGtkTextBTree,
    iter: PGtkTextIter, `string`: cstring): gboolean{.cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_get_iter_from_string".}
proc gtk_text_btree_get_iter_at_mark_name*(tree: PGtkTextBTree,
    iter: PGtkTextIter, mark_name: cstring): gboolean{.cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_get_iter_at_mark_name".}
proc gtk_text_btree_get_iter_at_mark*(tree: PGtkTextBTree, iter: PGtkTextIter,
                                        mark: PGtkTextMark){.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_get_iter_at_mark".}
proc gtk_text_btree_get_end_iter*(tree: PGtkTextBTree, iter: PGtkTextIter){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_get_end_iter".}
proc gtk_text_btree_get_iter_at_line*(tree: PGtkTextBTree, iter: PGtkTextIter,
                                        line: PGtkTextLine, byte_offset: gint){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_get_iter_at_line".}
proc gtk_text_btree_get_iter_at_first_toggle*(tree: PGtkTextBTree,
    iter: PGtkTextIter, tag: PGtkTextTag): gboolean{.cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_get_iter_at_first_toggle".}
proc gtk_text_btree_get_iter_at_last_toggle*(tree: PGtkTextBTree,
    iter: PGtkTextIter, tag: PGtkTextTag): gboolean{.cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_get_iter_at_last_toggle".}
proc gtk_text_btree_get_iter_at_child_anchor*(tree: PGtkTextBTree,
    iter: PGtkTextIter, anchor: PGtkTextChildAnchor){.cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_get_iter_at_child_anchor".}
proc gtk_text_btree_set_mark*(tree: PGtkTextBTree,
                                existing_mark: PGtkTextMark, name: cstring,
                                left_gravity: gboolean, index: PGtkTextIter,
                                should_exist: gboolean): PGtkTextMark{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_btree_set_mark".}
proc gtk_text_btree_remove_mark_by_name*(tree: PGtkTextBTree, name: cstring){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_remove_mark_by_name".}
proc gtk_text_btree_remove_mark*(tree: PGtkTextBTree, segment: PGtkTextMark){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_remove_mark".}
proc gtk_text_btree_get_selection_bounds*(tree: PGtkTextBTree,
    start: PGtkTextIter, theEnd: PGtkTextIter): gboolean{.cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_get_selection_bounds".}
proc gtk_text_btree_place_cursor*(tree: PGtkTextBTree, `where`: PGtkTextIter){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_place_cursor".}
proc gtk_text_btree_mark_is_insert*(tree: PGtkTextBTree, segment: PGtkTextMark): gboolean{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_mark_is_insert".}
proc gtk_text_btree_mark_is_selection_bound*(tree: PGtkTextBTree,
    segment: PGtkTextMark): gboolean{.cdecl, dynlib: gtklib, importc: "_gtk_text_btree_mark_is_selection_bound".}
proc gtk_text_btree_get_mark_by_name*(tree: PGtkTextBTree, name: cstring): PGtkTextMark{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_btree_get_mark_by_name".}
proc gtk_text_btree_first_could_contain_tag*(tree: PGtkTextBTree,
    tag: PGtkTextTag): PGtkTextLine{.cdecl, dynlib: gtklib, importc: "_gtk_text_btree_first_could_contain_tag".}
proc gtk_text_btree_last_could_contain_tag*(tree: PGtkTextBTree,
    tag: PGtkTextTag): PGtkTextLine{.cdecl, dynlib: gtklib, importc: "_gtk_text_btree_last_could_contain_tag".}
const
  bm_TGtkTextLineData_width* = 0x00FFFFFF'i32
  bp_TGtkTextLineData_width* = 0'i32
  bm_TGtkTextLineData_valid* = 0xFF000000'i32
  bp_TGtkTextLineData_valid* = 24'i32

proc width*(a: PGtkTextLineData): gint
proc set_width*(a: PGtkTextLineData, NewWidth: gint)
proc valid*(a: PGtkTextLineData): gint
proc set_valid*(a: PGtkTextLineData, `valid`: gint)
proc gtk_text_line_get_number*(line: PGtkTextLine): gint{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_line_get_number".}
proc gtk_text_line_char_has_tag*(line: PGtkTextLine, tree: PGtkTextBTree,
                                   char_in_line: gint, tag: PGtkTextTag): gboolean{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_char_has_tag".}
proc gtk_text_line_byte_has_tag*(line: PGtkTextLine, tree: PGtkTextBTree,
                                   byte_in_line: gint, tag: PGtkTextTag): gboolean{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_byte_has_tag".}
proc gtk_text_line_is_last*(line: PGtkTextLine, tree: PGtkTextBTree): gboolean{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_is_last".}
proc gtk_text_line_contains_end_iter*(line: PGtkTextLine, tree: PGtkTextBTree): gboolean{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_contains_end_iter".}
proc gtk_text_line_next*(line: PGtkTextLine): PGtkTextLine{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_line_next".}
proc gtk_text_line_next_excluding_last*(line: PGtkTextLine): PGtkTextLine{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_next_excluding_last".}
proc gtk_text_line_previous*(line: PGtkTextLine): PGtkTextLine{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_line_previous".}
proc gtk_text_line_add_data*(line: PGtkTextLine, data: PGtkTextLineData){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_add_data".}
proc gtk_text_line_remove_data*(line: PGtkTextLine, view_id: gpointer): gpointer{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_remove_data".}
proc gtk_text_line_get_data*(line: PGtkTextLine, view_id: gpointer): gpointer{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_get_data".}
proc gtk_text_line_invalidate_wrap*(line: PGtkTextLine, ld: PGtkTextLineData){.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_invalidate_wrap".}
proc gtk_text_line_char_count*(line: PGtkTextLine): gint{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_line_char_count".}
proc gtk_text_line_byte_count*(line: PGtkTextLine): gint{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_line_byte_count".}
proc gtk_text_line_char_index*(line: PGtkTextLine): gint{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_line_char_index".}
proc gtk_text_line_byte_to_segment*(line: PGtkTextLine, byte_offset: gint,
                                      seg_offset: Pgint): PGtkTextLineSegment{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_byte_to_segment".}
proc gtk_text_line_char_to_segment*(line: PGtkTextLine, char_offset: gint,
                                      seg_offset: Pgint): PGtkTextLineSegment{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_char_to_segment".}
proc gtk_text_line_byte_to_char_offsets*(line: PGtkTextLine,
    byte_offset: gint, line_char_offset: Pgint, seg_char_offset: Pgint){.cdecl,
    dynlib: gtklib, importc: "_gtk_text_line_byte_to_char_offsets".}
proc gtk_text_line_char_to_byte_offsets*(line: PGtkTextLine,
    char_offset: gint, line_byte_offset: Pgint, seg_byte_offset: Pgint){.cdecl,
    dynlib: gtklib, importc: "_gtk_text_line_char_to_byte_offsets".}
proc gtk_text_line_byte_to_any_segment*(line: PGtkTextLine, byte_offset: gint,
    seg_offset: Pgint): PGtkTextLineSegment{.cdecl, dynlib: gtklib,
    importc: "_gtk_text_line_byte_to_any_segment".}
proc gtk_text_line_char_to_any_segment*(line: PGtkTextLine, char_offset: gint,
    seg_offset: Pgint): PGtkTextLineSegment{.cdecl, dynlib: gtklib,
    importc: "_gtk_text_line_char_to_any_segment".}
proc gtk_text_line_byte_to_char*(line: PGtkTextLine, byte_offset: gint): gint{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_byte_to_char".}
proc gtk_text_line_char_to_byte*(line: PGtkTextLine, char_offset: gint): gint{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_char_to_byte".}
proc gtk_text_line_next_could_contain_tag*(line: PGtkTextLine,
    tree: PGtkTextBTree, tag: PGtkTextTag): PGtkTextLine{.cdecl, dynlib: gtklib,
    importc: "_gtk_text_line_next_could_contain_tag".}
proc gtk_text_line_previous_could_contain_tag*(line: PGtkTextLine,
    tree: PGtkTextBTree, tag: PGtkTextTag): PGtkTextLine{.cdecl, dynlib: gtklib,
    importc: "_gtk_text_line_previous_could_contain_tag".}
proc gtk_text_line_data_new*(layout: PGtkTextLayout, line: PGtkTextLine): PGtkTextLineData{.
    cdecl, dynlib: gtklib, importc: "_gtk_text_line_data_new".}
proc gtk_text_btree_check*(tree: PGtkTextBTree){.cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_check".}
proc gtk_text_btree_spew*(tree: PGtkTextBTree){.cdecl, dynlib: gtklib,
    importc: "_gtk_text_btree_spew".}
proc gtk_toggle_segment_check_func*(segPtr: PGtkTextLineSegment,
                                      line: PGtkTextLine){.cdecl,
    dynlib: gtklib, importc: "_gtk_toggle_segment_check_func".}
proc gtk_change_node_toggle_count*(node: PGtkTextBTreeNode,
                                     info: PGtkTextTagInfo, delta: gint){.cdecl,
    dynlib: gtklib, importc: "_gtk_change_node_toggle_count".}
proc gtk_text_btree_release_mark_segment*(tree: PGtkTextBTree,
    segment: PGtkTextLineSegment){.cdecl, dynlib: gtklib, importc: "_gtk_text_btree_release_mark_segment".}
proc gtk_text_btree_notify_will_remove_tag*(tree: PGtkTextBTree,
    tag: PGtkTextTag){.cdecl, dynlib: gtklib,
                       importc: "_gtk_text_btree_notify_will_remove_tag".}
const
  bm_TGtkTextBuffer_modified* = 0x00000001'i16
  bp_TGtkTextBuffer_modified* = 0'i16

proc GTK_TYPE_TEXT_BUFFER*(): GType
proc GTK_TEXT_BUFFER*(obj: pointer): PGtkTextBuffer
proc GTK_TEXT_BUFFER_CLASS*(klass: pointer): PGtkTextBufferClass
proc GTK_IS_TEXT_BUFFER*(obj: pointer): bool
proc GTK_IS_TEXT_BUFFER_CLASS*(klass: pointer): bool
proc GTK_TEXT_BUFFER_GET_CLASS*(obj: pointer): PGtkTextBufferClass
proc modified*(a: var TGtkTextBuffer): guint
proc set_modified*(a: var TGtkTextBuffer, `modified`: guint)
proc gtk_text_buffer_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_get_type".}
proc gtk_text_buffer_new*(table: PGtkTextTagTable): PGtkTextBuffer{.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_new".}
proc gtk_text_buffer_get_line_count*(buffer: PGtkTextBuffer): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_get_line_count".}
proc gtk_text_buffer_get_char_count*(buffer: PGtkTextBuffer): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_get_char_count".}
proc gtk_text_buffer_get_tag_table*(buffer: PGtkTextBuffer): PGtkTextTagTable{.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_get_tag_table".}
proc gtk_text_buffer_set_text*(buffer: PGtkTextBuffer, text: cstring, len: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_set_text".}
proc gtk_text_buffer_insert*(buffer: PGtkTextBuffer, iter: PGtkTextIter,
                             text: cstring, len: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_insert".}
proc gtk_text_buffer_insert_at_cursor*(buffer: PGtkTextBuffer, text: cstring,
                                       len: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_insert_at_cursor".}
proc gtk_text_buffer_insert_interactive*(buffer: PGtkTextBuffer,
    iter: PGtkTextIter, text: cstring, len: gint, default_editable: gboolean): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_insert_interactive".}
proc gtk_text_buffer_insert_interactive_at_cursor*(buffer: PGtkTextBuffer,
    text: cstring, len: gint, default_editable: gboolean): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_insert_interactive_at_cursor".}
proc gtk_text_buffer_insert_range*(buffer: PGtkTextBuffer, iter: PGtkTextIter,
                                   start: PGtkTextIter, theEnd: PGtkTextIter){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_insert_range".}
proc gtk_text_buffer_insert_range_interactive*(buffer: PGtkTextBuffer,
    iter: PGtkTextIter, start: PGtkTextIter, theEnd: PGtkTextIter,
    default_editable: gboolean): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_insert_range_interactive".}
proc gtk_text_buffer_delete*(buffer: PGtkTextBuffer, start: PGtkTextIter,
                             theEnd: PGtkTextIter){.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_delete".}
proc gtk_text_buffer_delete_interactive*(buffer: PGtkTextBuffer,
    start_iter: PGtkTextIter, end_iter: PGtkTextIter, default_editable: gboolean): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_delete_interactive".}
proc gtk_text_buffer_get_text*(buffer: PGtkTextBuffer, start: PGtkTextIter,
                               theEnd: PGtkTextIter,
                               include_hidden_chars: gboolean): cstring{.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_get_text".}
proc gtk_text_buffer_get_slice*(buffer: PGtkTextBuffer, start: PGtkTextIter,
                                theEnd: PGtkTextIter,
                                include_hidden_chars: gboolean): cstring{.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_get_slice".}
proc gtk_text_buffer_insert_pixbuf*(buffer: PGtkTextBuffer, iter: PGtkTextIter,
                                    pixbuf: PGdkPixbuf){.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_insert_pixbuf".}
proc gtk_text_buffer_insert_child_anchor*(buffer: PGtkTextBuffer,
    iter: PGtkTextIter, anchor: PGtkTextChildAnchor){.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_insert_child_anchor".}
proc gtk_text_buffer_create_child_anchor*(buffer: PGtkTextBuffer,
    iter: PGtkTextIter): PGtkTextChildAnchor{.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_create_child_anchor".}
proc gtk_text_buffer_create_mark*(buffer: PGtkTextBuffer, mark_name: cstring,
                                  `where`: PGtkTextIter, left_gravity: gboolean): PGtkTextMark{.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_create_mark".}
proc gtk_text_buffer_move_mark*(buffer: PGtkTextBuffer, mark: PGtkTextMark,
                                `where`: PGtkTextIter){.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_move_mark".}
proc gtk_text_buffer_delete_mark*(buffer: PGtkTextBuffer, mark: PGtkTextMark){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_delete_mark".}
proc gtk_text_buffer_get_mark*(buffer: PGtkTextBuffer, name: cstring): PGtkTextMark{.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_get_mark".}
proc gtk_text_buffer_move_mark_by_name*(buffer: PGtkTextBuffer, name: cstring,
                                        `where`: PGtkTextIter){.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_move_mark_by_name".}
proc gtk_text_buffer_delete_mark_by_name*(buffer: PGtkTextBuffer, name: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_delete_mark_by_name".}
proc gtk_text_buffer_get_insert*(buffer: PGtkTextBuffer): PGtkTextMark{.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_get_insert".}
proc gtk_text_buffer_get_selection_bound*(buffer: PGtkTextBuffer): PGtkTextMark{.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_get_selection_bound".}
proc gtk_text_buffer_place_cursor*(buffer: PGtkTextBuffer, `where`: PGtkTextIter){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_place_cursor".}
proc gtk_text_buffer_apply_tag*(buffer: PGtkTextBuffer, tag: PGtkTextTag,
                                start: PGtkTextIter, theEnd: PGtkTextIter){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_apply_tag".}
proc gtk_text_buffer_remove_tag*(buffer: PGtkTextBuffer, tag: PGtkTextTag,
                                 start: PGtkTextIter, theEnd: PGtkTextIter){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_remove_tag".}
proc gtk_text_buffer_apply_tag_by_name*(buffer: PGtkTextBuffer, name: cstring,
                                        start: PGtkTextIter,
                                        theEnd: PGtkTextIter){.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_apply_tag_by_name".}
proc gtk_text_buffer_remove_tag_by_name*(buffer: PGtkTextBuffer, name: cstring,
    start: PGtkTextIter, theEnd: PGtkTextIter){.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_remove_tag_by_name".}
proc gtk_text_buffer_remove_all_tags*(buffer: PGtkTextBuffer,
                                      start: PGtkTextIter, theEnd: PGtkTextIter){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_remove_all_tags".}
proc gtk_text_buffer_get_iter_at_line_offset*(buffer: PGtkTextBuffer,
    iter: PGtkTextIter, line_number: gint, char_offset: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_get_iter_at_line_offset".}
proc gtk_text_buffer_get_iter_at_line_index*(buffer: PGtkTextBuffer,
    iter: PGtkTextIter, line_number: gint, byte_index: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_get_iter_at_line_index".}
proc gtk_text_buffer_get_iter_at_offset*(buffer: PGtkTextBuffer,
    iter: PGtkTextIter, char_offset: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_get_iter_at_offset".}
proc gtk_text_buffer_get_iter_at_line*(buffer: PGtkTextBuffer,
                                       iter: PGtkTextIter, line_number: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_get_iter_at_line".}
proc gtk_text_buffer_get_start_iter*(buffer: PGtkTextBuffer, iter: PGtkTextIter){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_get_start_iter".}
proc gtk_text_buffer_get_end_iter*(buffer: PGtkTextBuffer, iter: PGtkTextIter){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_get_end_iter".}
proc gtk_text_buffer_get_bounds*(buffer: PGtkTextBuffer, start: PGtkTextIter,
                                 theEnd: PGtkTextIter){.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_get_bounds".}
proc gtk_text_buffer_get_iter_at_mark*(buffer: PGtkTextBuffer,
                                       iter: PGtkTextIter, mark: PGtkTextMark){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_get_iter_at_mark".}
proc gtk_text_buffer_get_iter_at_child_anchor*(buffer: PGtkTextBuffer,
    iter: PGtkTextIter, anchor: PGtkTextChildAnchor){.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_get_iter_at_child_anchor".}
proc gtk_text_buffer_get_modified*(buffer: PGtkTextBuffer): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_get_modified".}
proc gtk_text_buffer_set_modified*(buffer: PGtkTextBuffer, setting: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_set_modified".}
proc gtk_text_buffer_add_selection_clipboard*(buffer: PGtkTextBuffer,
    clipboard: PGtkClipboard){.cdecl, dynlib: gtklib, importc: "gtk_text_buffer_add_selection_clipboard".}
proc gtk_text_buffer_remove_selection_clipboard*(buffer: PGtkTextBuffer,
    clipboard: PGtkClipboard){.cdecl, dynlib: gtklib, importc: "gtk_text_buffer_remove_selection_clipboard".}
proc gtk_text_buffer_cut_clipboard*(buffer: PGtkTextBuffer,
                                    clipboard: PGtkClipboard,
                                    default_editable: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_cut_clipboard".}
proc gtk_text_buffer_copy_clipboard*(buffer: PGtkTextBuffer,
                                     clipboard: PGtkClipboard){.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_copy_clipboard".}
proc gtk_text_buffer_paste_clipboard*(buffer: PGtkTextBuffer,
                                      clipboard: PGtkClipboard,
                                      override_location: PGtkTextIter,
                                      default_editable: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_paste_clipboard".}
proc gtk_text_buffer_get_selection_bounds*(buffer: PGtkTextBuffer,
    start: PGtkTextIter, theEnd: PGtkTextIter): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_text_buffer_get_selection_bounds".}
proc gtk_text_buffer_delete_selection*(buffer: PGtkTextBuffer,
                                       interactive: gboolean,
                                       default_editable: gboolean): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_buffer_delete_selection".}
proc gtk_text_buffer_begin_user_action*(buffer: PGtkTextBuffer){.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_begin_user_action".}
proc gtk_text_buffer_end_user_action*(buffer: PGtkTextBuffer){.cdecl,
    dynlib: gtklib, importc: "gtk_text_buffer_end_user_action".}
proc gtk_text_buffer_spew*(buffer: PGtkTextBuffer){.cdecl, dynlib: gtklib,
    importc: "_gtk_text_buffer_spew".}
proc gtk_text_buffer_get_btree*(buffer: PGtkTextBuffer): PGtkTextBTree{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_buffer_get_btree".}
proc gtk_text_buffer_get_line_log_attrs*(buffer: PGtkTextBuffer,
    anywhere_in_line: PGtkTextIter, char_len: Pgint): PPangoLogAttr{.cdecl,
    dynlib: gtklib, importc: "_gtk_text_buffer_get_line_log_attrs".}
proc gtk_text_buffer_notify_will_remove_tag*(buffer: PGtkTextBuffer,
    tag: PGtkTextTag){.cdecl, dynlib: gtklib,
                       importc: "_gtk_text_buffer_notify_will_remove_tag".}
proc GTK_TYPE_TEXT_LAYOUT*(): GType
proc GTK_TEXT_LAYOUT*(obj: pointer): PGtkTextLayout
proc GTK_TEXT_LAYOUT_CLASS*(klass: pointer): PGtkTextLayoutClass
proc GTK_IS_TEXT_LAYOUT*(obj: pointer): bool
proc GTK_IS_TEXT_LAYOUT_CLASS*(klass: pointer): bool
proc GTK_TEXT_LAYOUT_GET_CLASS*(obj: pointer): PGtkTextLayoutClass
const
  bm_TGtkTextLayout_cursor_visible* = 0x00000001'i16
  bp_TGtkTextLayout_cursor_visible* = 0'i16
  bm_TGtkTextLayout_cursor_direction* = 0x00000006'i16
  bp_TGtkTextLayout_cursor_direction* = 1'i16

proc cursor_visible*(a: var TGtkTextLayout): guint
proc set_cursor_visible*(a: var TGtkTextLayout, `cursor_visible`: guint)
proc cursor_direction*(a: var TGtkTextLayout): gint
proc set_cursor_direction*(a: var TGtkTextLayout, `cursor_direction`: gint)
const
  bm_TGtkTextCursorDisplay_is_strong* = 0x00000001'i16
  bp_TGtkTextCursorDisplay_is_strong* = 0'i16
  bm_TGtkTextCursorDisplay_is_weak* = 0x00000002'i16
  bp_TGtkTextCursorDisplay_is_weak* = 1'i16

proc is_strong*(a: var TGtkTextCursorDisplay): guint
proc set_is_strong*(a: var TGtkTextCursorDisplay, `is_strong`: guint)
proc is_weak*(a: var TGtkTextCursorDisplay): guint
proc set_is_weak*(a: var TGtkTextCursorDisplay, `is_weak`: guint)
proc gtk_text_layout_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_text_layout_get_type".}
proc gtk_text_layout_new*(): PGtkTextLayout{.cdecl, dynlib: gtklib,
    importc: "gtk_text_layout_new".}
proc gtk_text_layout_set_buffer*(layout: PGtkTextLayout, buffer: PGtkTextBuffer){.
    cdecl, dynlib: gtklib, importc: "gtk_text_layout_set_buffer".}
proc gtk_text_layout_get_buffer*(layout: PGtkTextLayout): PGtkTextBuffer{.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_get_buffer".}
proc gtk_text_layout_set_default_style*(layout: PGtkTextLayout,
                                        values: PGtkTextAttributes){.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_set_default_style".}
proc gtk_text_layout_set_contexts*(layout: PGtkTextLayout,
                                   ltr_context: PPangoContext,
                                   rtl_context: PPangoContext){.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_set_contexts".}
proc gtk_text_layout_set_cursor_direction*(layout: PGtkTextLayout,
    direction: TGtkTextDirection){.cdecl, dynlib: gtklib, importc: "gtk_text_layout_set_cursor_direction".}
proc gtk_text_layout_default_style_changed*(layout: PGtkTextLayout){.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_default_style_changed".}
proc gtk_text_layout_set_screen_width*(layout: PGtkTextLayout, width: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_text_layout_set_screen_width".}
proc gtk_text_layout_set_preedit_string*(layout: PGtkTextLayout,
    preedit_string: cstring, preedit_attrs: PPangoAttrList, cursor_pos: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_text_layout_set_preedit_string".}
proc gtk_text_layout_set_cursor_visible*(layout: PGtkTextLayout,
    cursor_visible: gboolean){.cdecl, dynlib: gtklib,
                               importc: "gtk_text_layout_set_cursor_visible".}
proc gtk_text_layout_get_cursor_visible*(layout: PGtkTextLayout): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_layout_get_cursor_visible".}
proc gtk_text_layout_get_size*(layout: PGtkTextLayout, width: Pgint,
                               height: Pgint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_layout_get_size".}
proc gtk_text_layout_get_lines*(layout: PGtkTextLayout, top_y: gint,
                                bottom_y: gint, first_line_y: Pgint): PGSList{.
    cdecl, dynlib: gtklib, importc: "gtk_text_layout_get_lines".}
proc gtk_text_layout_wrap_loop_start*(layout: PGtkTextLayout){.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_wrap_loop_start".}
proc gtk_text_layout_wrap_loop_end*(layout: PGtkTextLayout){.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_wrap_loop_end".}
proc gtk_text_layout_get_line_display*(layout: PGtkTextLayout,
                                       line: PGtkTextLine, size_only: gboolean): PGtkTextLineDisplay{.
    cdecl, dynlib: gtklib, importc: "gtk_text_layout_get_line_display".}
proc gtk_text_layout_free_line_display*(layout: PGtkTextLayout,
                                        display: PGtkTextLineDisplay){.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_free_line_display".}
proc gtk_text_layout_get_line_at_y*(layout: PGtkTextLayout,
                                    target_iter: PGtkTextIter, y: gint,
                                    line_top: Pgint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_layout_get_line_at_y".}
proc gtk_text_layout_get_iter_at_pixel*(layout: PGtkTextLayout,
                                        iter: PGtkTextIter, x: gint, y: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_text_layout_get_iter_at_pixel".}
proc gtk_text_layout_invalidate*(layout: PGtkTextLayout, start: PGtkTextIter,
                                 theEnd: PGtkTextIter){.cdecl, dynlib: gtklib,
    importc: "gtk_text_layout_invalidate".}
proc gtk_text_layout_free_line_data*(layout: PGtkTextLayout, line: PGtkTextLine,
                                     line_data: PGtkTextLineData){.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_free_line_data".}
proc gtk_text_layout_is_valid*(layout: PGtkTextLayout): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_is_valid".}
proc gtk_text_layout_validate_yrange*(layout: PGtkTextLayout,
                                      anchor_line: PGtkTextIter, y0: gint,
                                      y1: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_layout_validate_yrange".}
proc gtk_text_layout_validate*(layout: PGtkTextLayout, max_pixels: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_validate".}
proc gtk_text_layout_wrap*(layout: PGtkTextLayout, line: PGtkTextLine,
                           line_data: PGtkTextLineData): PGtkTextLineData{.
    cdecl, dynlib: gtklib, importc: "gtk_text_layout_wrap".}
proc gtk_text_layout_changed*(layout: PGtkTextLayout, y: gint, old_height: gint,
                              new_height: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_layout_changed".}
proc gtk_text_layout_get_iter_location*(layout: PGtkTextLayout,
                                        iter: PGtkTextIter, rect: PGdkRectangle){.
    cdecl, dynlib: gtklib, importc: "gtk_text_layout_get_iter_location".}
proc gtk_text_layout_get_line_yrange*(layout: PGtkTextLayout,
                                      iter: PGtkTextIter, y: Pgint,
                                      height: Pgint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_layout_get_line_yrange".}
proc gtk_text_layout_get_line_xrange*(layout: PGtkTextLayout,
                                        iter: PGtkTextIter, x: Pgint,
                                        width: Pgint){.cdecl, dynlib: gtklib,
    importc: "_gtk_text_layout_get_line_xrange".}
proc gtk_text_layout_get_cursor_locations*(layout: PGtkTextLayout,
    iter: PGtkTextIter, strong_pos: PGdkRectangle, weak_pos: PGdkRectangle){.
    cdecl, dynlib: gtklib, importc: "gtk_text_layout_get_cursor_locations".}
proc gtk_text_layout_clamp_iter_to_vrange*(layout: PGtkTextLayout,
    iter: PGtkTextIter, top: gint, bottom: gint): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_clamp_iter_to_vrange".}
proc gtk_text_layout_move_iter_to_line_end*(layout: PGtkTextLayout,
    iter: PGtkTextIter, direction: gint): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_text_layout_move_iter_to_line_end".}
proc gtk_text_layout_move_iter_to_previous_line*(layout: PGtkTextLayout,
    iter: PGtkTextIter): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_text_layout_move_iter_to_previous_line".}
proc gtk_text_layout_move_iter_to_next_line*(layout: PGtkTextLayout,
    iter: PGtkTextIter): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_text_layout_move_iter_to_next_line".}
proc gtk_text_layout_move_iter_to_x*(layout: PGtkTextLayout, iter: PGtkTextIter,
                                     x: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_layout_move_iter_to_x".}
proc gtk_text_layout_move_iter_visually*(layout: PGtkTextLayout,
    iter: PGtkTextIter, count: gint): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_text_layout_move_iter_visually".}
proc gtk_text_layout_iter_starts_line*(layout: PGtkTextLayout,
                                       iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_iter_starts_line".}
proc gtk_text_layout_get_iter_at_line*(layout: PGtkTextLayout,
                                       iter: PGtkTextIter, line: PGtkTextLine,
                                       byte_offset: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_text_layout_get_iter_at_line".}
proc gtk_text_child_anchor_register_child*(anchor: PGtkTextChildAnchor,
    child: PGtkWidget, layout: PGtkTextLayout){.cdecl, dynlib: gtklib,
    importc: "gtk_text_child_anchor_register_child".}
proc gtk_text_child_anchor_unregister_child*(anchor: PGtkTextChildAnchor,
    child: PGtkWidget){.cdecl, dynlib: gtklib,
                        importc: "gtk_text_child_anchor_unregister_child".}
proc gtk_text_child_anchor_queue_resize*(anchor: PGtkTextChildAnchor,
    layout: PGtkTextLayout){.cdecl, dynlib: gtklib,
                             importc: "gtk_text_child_anchor_queue_resize".}
proc gtk_text_anchored_child_set_layout*(child: PGtkWidget,
    layout: PGtkTextLayout){.cdecl, dynlib: gtklib,
                             importc: "gtk_text_anchored_child_set_layout".}
proc gtk_text_layout_spew*(layout: PGtkTextLayout){.cdecl, dynlib: gtklib,
    importc: "gtk_text_layout_spew".}
const # GTK_TEXT_VIEW_PRIORITY_VALIDATE* = GDK_PRIORITY_REDRAW + 5
  bm_TGtkTextView_editable* = 0x00000001'i16
  bp_TGtkTextView_editable* = 0'i16
  bm_TGtkTextView_overwrite_mode* = 0x00000002'i16
  bp_TGtkTextView_overwrite_mode* = 1'i16
  bm_TGtkTextView_cursor_visible* = 0x00000004'i16
  bp_TGtkTextView_cursor_visible* = 2'i16
  bm_TGtkTextView_need_im_reset* = 0x00000008'i16
  bp_TGtkTextView_need_im_reset* = 3'i16
  bm_TGtkTextView_just_selected_element* = 0x00000010'i16
  bp_TGtkTextView_just_selected_element* = 4'i16
  bm_TGtkTextView_disable_scroll_on_focus* = 0x00000020'i16
  bp_TGtkTextView_disable_scroll_on_focus* = 5'i16
  bm_TGtkTextView_onscreen_validated* = 0x00000040'i16
  bp_TGtkTextView_onscreen_validated* = 6'i16
  bm_TGtkTextView_mouse_cursor_obscured* = 0x00000080'i16
  bp_TGtkTextView_mouse_cursor_obscured* = 7'i16

proc GTK_TYPE_TEXT_VIEW*(): GType
proc GTK_TEXT_VIEW*(obj: pointer): PGtkTextView
proc GTK_TEXT_VIEW_CLASS*(klass: pointer): PGtkTextViewClass
proc GTK_IS_TEXT_VIEW*(obj: pointer): bool
proc GTK_IS_TEXT_VIEW_CLASS*(klass: pointer): bool
proc GTK_TEXT_VIEW_GET_CLASS*(obj: pointer): PGtkTextViewClass
proc editable*(a: var TGtkTextView): guint
proc set_editable*(a: var TGtkTextView, `editable`: guint)
proc overwrite_mode*(a: var TGtkTextView): guint
proc set_overwrite_mode*(a: var TGtkTextView, `overwrite_mode`: guint)
proc cursor_visible*(a: var TGtkTextView): guint
proc set_cursor_visible*(a: var TGtkTextView, `cursor_visible`: guint)
proc need_im_reset*(a: var TGtkTextView): guint
proc set_need_im_reset*(a: var TGtkTextView, `need_im_reset`: guint)
proc just_selected_element*(a: var TGtkTextView): guint
proc set_just_selected_element*(a: var TGtkTextView,
                                `just_selected_element`: guint)
proc disable_scroll_on_focus*(a: var TGtkTextView): guint
proc set_disable_scroll_on_focus*(a: var TGtkTextView,
                                  `disable_scroll_on_focus`: guint)
proc onscreen_validated*(a: var TGtkTextView): guint
proc set_onscreen_validated*(a: var TGtkTextView, `onscreen_validated`: guint)
proc mouse_cursor_obscured*(a: var TGtkTextView): guint
proc set_mouse_cursor_obscured*(a: var TGtkTextView,
                                `mouse_cursor_obscured`: guint)
proc gtk_text_view_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_text_view_get_type".}
proc gtk_text_view_new*(): PGtkTextView{.cdecl, dynlib: gtklib,
                                       importc: "gtk_text_view_new".}
proc gtk_text_view_new_with_buffer*(buffer: PGtkTextBuffer): PGtkTextView{.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_new_with_buffer".}
proc gtk_text_view_set_buffer*(text_view: PGtkTextView, buffer: PGtkTextBuffer){.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_set_buffer".}
proc gtk_text_view_get_buffer*(text_view: PGtkTextView): PGtkTextBuffer{.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_get_buffer".}
proc gtk_text_view_scroll_to_iter*(text_view: PGtkTextView, iter: PGtkTextIter,
                                   within_margin: gdouble, use_align: gboolean,
                                   xalign: gdouble, yalign: gdouble): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_scroll_to_iter".}
proc gtk_text_view_scroll_to_mark*(text_view: PGtkTextView, mark: PGtkTextMark,
                                   within_margin: gdouble, use_align: gboolean,
                                   xalign: gdouble, yalign: gdouble){.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_scroll_to_mark".}
proc gtk_text_view_scroll_mark_onscreen*(text_view: PGtkTextView,
    mark: PGtkTextMark){.cdecl, dynlib: gtklib,
                         importc: "gtk_text_view_scroll_mark_onscreen".}
proc gtk_text_view_move_mark_onscreen*(text_view: PGtkTextView,
                                       mark: PGtkTextMark): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_move_mark_onscreen".}
proc gtk_text_view_place_cursor_onscreen*(text_view: PGtkTextView): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_place_cursor_onscreen".}
proc gtk_text_view_get_visible_rect*(text_view: PGtkTextView,
                                     visible_rect: PGdkRectangle){.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_get_visible_rect".}
proc gtk_text_view_set_cursor_visible*(text_view: PGtkTextView,
                                       setting: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_set_cursor_visible".}
proc gtk_text_view_get_cursor_visible*(text_view: PGtkTextView): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_get_cursor_visible".}
proc gtk_text_view_get_iter_location*(text_view: PGtkTextView,
                                      iter: PGtkTextIter,
                                      location: PGdkRectangle){.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_get_iter_location".}
proc gtk_text_view_get_iter_at_location*(text_view: PGtkTextView,
    iter: PGtkTextIter, x: gint, y: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_view_get_iter_at_location".}
proc gtk_text_view_get_line_yrange*(text_view: PGtkTextView, iter: PGtkTextIter,
                                    y: Pgint, height: Pgint){.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_get_line_yrange".}
proc gtk_text_view_get_line_at_y*(text_view: PGtkTextView,
                                  target_iter: PGtkTextIter, y: gint,
                                  line_top: Pgint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_view_get_line_at_y".}
proc gtk_text_view_buffer_to_window_coords*(text_view: PGtkTextView,
    win: TGtkTextWindowType, buffer_x: gint, buffer_y: gint, window_x: Pgint,
    window_y: Pgint){.cdecl, dynlib: gtklib,
                      importc: "gtk_text_view_buffer_to_window_coords".}
proc gtk_text_view_window_to_buffer_coords*(text_view: PGtkTextView,
    win: TGtkTextWindowType, window_x: gint, window_y: gint, buffer_x: Pgint,
    buffer_y: Pgint){.cdecl, dynlib: gtklib,
                      importc: "gtk_text_view_window_to_buffer_coords".}
proc gtk_text_view_get_window*(text_view: PGtkTextView, win: TGtkTextWindowType): PGdkWindow{.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_get_window".}
proc gtk_text_view_get_window_type*(text_view: PGtkTextView, window: PGdkWindow): TGtkTextWindowType{.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_get_window_type".}
proc gtk_text_view_set_border_window_size*(text_view: PGtkTextView,
    thetype: TGtkTextWindowType, size: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_view_set_border_window_size".}
proc gtk_text_view_get_border_window_size*(text_view: PGtkTextView,
    thetype: TGtkTextWindowType): gint{.cdecl, dynlib: gtklib, importc: "gtk_text_view_get_border_window_size".}
proc gtk_text_view_forward_display_line*(text_view: PGtkTextView,
    iter: PGtkTextIter): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_text_view_forward_display_line".}
proc gtk_text_view_backward_display_line*(text_view: PGtkTextView,
    iter: PGtkTextIter): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_text_view_backward_display_line".}
proc gtk_text_view_forward_display_line_end*(text_view: PGtkTextView,
    iter: PGtkTextIter): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_text_view_forward_display_line_end".}
proc gtk_text_view_backward_display_line_start*(text_view: PGtkTextView,
    iter: PGtkTextIter): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_text_view_backward_display_line_start".}
proc gtk_text_view_starts_display_line*(text_view: PGtkTextView,
                                        iter: PGtkTextIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_starts_display_line".}
proc gtk_text_view_move_visually*(text_view: PGtkTextView, iter: PGtkTextIter,
                                  count: gint): gboolean{.cdecl, dynlib: gtklib,
    importc: "gtk_text_view_move_visually".}
proc gtk_text_view_add_child_at_anchor*(text_view: PGtkTextView,
                                        child: PGtkWidget,
                                        anchor: PGtkTextChildAnchor){.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_add_child_at_anchor".}
proc gtk_text_view_add_child_in_window*(text_view: PGtkTextView,
                                        child: PGtkWidget,
                                        which_window: TGtkTextWindowType,
                                        xpos: gint, ypos: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_add_child_in_window".}
proc gtk_text_view_move_child*(text_view: PGtkTextView, child: PGtkWidget,
                               xpos: gint, ypos: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_text_view_move_child".}
proc gtk_text_view_set_wrap_mode*(text_view: PGtkTextView,
                                  wrap_mode: TGtkWrapMode){.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_set_wrap_mode".}
proc gtk_text_view_get_wrap_mode*(text_view: PGtkTextView): TGtkWrapMode{.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_get_wrap_mode".}
proc gtk_text_view_set_editable*(text_view: PGtkTextView, setting: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_set_editable".}
proc gtk_text_view_get_editable*(text_view: PGtkTextView): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_get_editable".}
proc gtk_text_view_set_pixels_above_lines*(text_view: PGtkTextView,
    pixels_above_lines: gint){.cdecl, dynlib: gtklib,
                               importc: "gtk_text_view_set_pixels_above_lines".}
proc gtk_text_view_get_pixels_above_lines*(text_view: PGtkTextView): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_get_pixels_above_lines".}
proc gtk_text_view_set_pixels_below_lines*(text_view: PGtkTextView,
    pixels_below_lines: gint){.cdecl, dynlib: gtklib,
                               importc: "gtk_text_view_set_pixels_below_lines".}
proc gtk_text_view_get_pixels_below_lines*(text_view: PGtkTextView): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_get_pixels_below_lines".}
proc gtk_text_view_set_pixels_inside_wrap*(text_view: PGtkTextView,
    pixels_inside_wrap: gint){.cdecl, dynlib: gtklib,
                               importc: "gtk_text_view_set_pixels_inside_wrap".}
proc gtk_text_view_get_pixels_inside_wrap*(text_view: PGtkTextView): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_get_pixels_inside_wrap".}
proc gtk_text_view_set_justification*(text_view: PGtkTextView,
                                      justification: TGtkJustification){.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_set_justification".}
proc gtk_text_view_get_justification*(text_view: PGtkTextView): TGtkJustification{.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_get_justification".}
proc gtk_text_view_set_left_margin*(text_view: PGtkTextView, left_margin: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_set_left_margin".}
proc gtk_text_view_get_left_margin*(text_view: PGtkTextView): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_get_left_margin".}
proc gtk_text_view_set_right_margin*(text_view: PGtkTextView, right_margin: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_set_right_margin".}
proc gtk_text_view_get_right_margin*(text_view: PGtkTextView): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_get_right_margin".}
proc gtk_text_view_set_indent*(text_view: PGtkTextView, indent: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_set_indent".}
proc gtk_text_view_get_indent*(text_view: PGtkTextView): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_get_indent".}
proc gtk_text_view_set_tabs*(text_view: PGtkTextView, tabs: PPangoTabArray){.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_set_tabs".}
proc gtk_text_view_get_tabs*(text_view: PGtkTextView): PPangoTabArray{.cdecl,
    dynlib: gtklib, importc: "gtk_text_view_get_tabs".}
proc gtk_text_view_get_default_attributes*(text_view: PGtkTextView): PGtkTextAttributes{.
    cdecl, dynlib: gtklib, importc: "gtk_text_view_get_default_attributes".}
const
  bm_TGtkTipsQuery_emit_always* = 0x00000001'i16
  bp_TGtkTipsQuery_emit_always* = 0'i16
  bm_TGtkTipsQuery_in_query* = 0x00000002'i16
  bp_TGtkTipsQuery_in_query* = 1'i16

proc GTK_TYPE_TIPS_QUERY*(): GType
proc GTK_TIPS_QUERY*(obj: pointer): PGtkTipsQuery
proc GTK_TIPS_QUERY_CLASS*(klass: pointer): PGtkTipsQueryClass
proc GTK_IS_TIPS_QUERY*(obj: pointer): bool
proc GTK_IS_TIPS_QUERY_CLASS*(klass: pointer): bool
proc GTK_TIPS_QUERY_GET_CLASS*(obj: pointer): PGtkTipsQueryClass
proc emit_always*(a: var TGtkTipsQuery): guint
proc set_emit_always*(a: var TGtkTipsQuery, `emit_always`: guint)
proc in_query*(a: var TGtkTipsQuery): guint
proc set_in_query*(a: var TGtkTipsQuery, `in_query`: guint)
proc gtk_tips_query_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_tips_query_get_type".}
proc gtk_tips_query_new*(): PGtkTipsQuery{.cdecl, dynlib: gtklib,
                                        importc: "gtk_tips_query_new".}
proc gtk_tips_query_start_query*(tips_query: PGtkTipsQuery){.cdecl,
    dynlib: gtklib, importc: "gtk_tips_query_start_query".}
proc gtk_tips_query_stop_query*(tips_query: PGtkTipsQuery){.cdecl,
    dynlib: gtklib, importc: "gtk_tips_query_stop_query".}
proc gtk_tips_query_set_caller*(tips_query: PGtkTipsQuery, caller: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "gtk_tips_query_set_caller".}
proc gtk_tips_query_set_labels*(tips_query: PGtkTipsQuery,
                                label_inactive: cstring, label_no_tip: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_tips_query_set_labels".}
const
  bm_TGtkTooltips_delay* = 0x3FFFFFFF'i32
  bp_TGtkTooltips_delay* = 0'i32
  bm_TGtkTooltips_enabled* = 0x40000000'i32
  bp_TGtkTooltips_enabled* = 30'i32
  bm_TGtkTooltips_have_grab* = 0x80000000'i32
  bp_TGtkTooltips_have_grab* = 31'i32
  bm_TGtkTooltips_use_sticky_delay* = 0x00000001'i32
  bp_TGtkTooltips_use_sticky_delay* = 0'i32

proc GTK_TYPE_TOOLTIPS*(): GType
proc GTK_TOOLTIPS*(obj: pointer): PGtkTooltips
proc GTK_TOOLTIPS_CLASS*(klass: pointer): PGtkTooltipsClass
proc GTK_IS_TOOLTIPS*(obj: pointer): bool
proc GTK_IS_TOOLTIPS_CLASS*(klass: pointer): bool
proc GTK_TOOLTIPS_GET_CLASS*(obj: pointer): PGtkTooltipsClass
proc delay*(a: var TGtkTooltips): guint
proc set_delay*(a: var TGtkTooltips, `delay`: guint)
proc enabled*(a: var TGtkTooltips): guint
proc set_enabled*(a: var TGtkTooltips, `enabled`: guint)
proc have_grab*(a: var TGtkTooltips): guint
proc set_have_grab*(a: var TGtkTooltips, `have_grab`: guint)
proc use_sticky_delay*(a: var TGtkTooltips): guint
proc set_use_sticky_delay*(a: var TGtkTooltips, `use_sticky_delay`: guint)
proc gtk_tooltips_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_tooltips_get_type".}
proc gtk_tooltips_new*(): PGtkTooltips{.cdecl, dynlib: gtklib,
                                        importc: "gtk_tooltips_new".}
proc gtk_tooltips_enable*(tooltips: PGtkTooltips){.cdecl, dynlib: gtklib,
    importc: "gtk_tooltips_enable".}
proc gtk_tooltips_disable*(tooltips: PGtkTooltips){.cdecl, dynlib: gtklib,
    importc: "gtk_tooltips_disable".}
proc gtk_tooltips_set_tip*(tooltips: PGtkTooltips, widget: PGtkWidget,
                           tip_text: cstring, tip_private: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_tooltips_set_tip".}
proc gtk_tooltips_data_get*(widget: PGtkWidget): PGtkTooltipsData{.cdecl,
    dynlib: gtklib, importc: "gtk_tooltips_data_get".}
proc gtk_tooltips_force_window*(tooltips: PGtkTooltips){.cdecl, dynlib: gtklib,
    importc: "gtk_tooltips_force_window".}
proc gtk_tooltips_toggle_keyboard_mode*(widget: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "_gtk_tooltips_toggle_keyboard_mode".}
const
  bm_TGtkToolbar_style_set* = 0x00000001'i16
  bp_TGtkToolbar_style_set* = 0'i16
  bm_TGtkToolbar_icon_size_set* = 0x00000002'i16
  bp_TGtkToolbar_icon_size_set* = 1'i16

proc GTK_TYPE_TOOLBAR*(): GType
proc GTK_TOOLBAR*(obj: pointer): PGtkToolbar
proc GTK_TOOLBAR_CLASS*(klass: pointer): PGtkToolbarClass
proc GTK_IS_TOOLBAR*(obj: pointer): bool
proc GTK_IS_TOOLBAR_CLASS*(klass: pointer): bool
proc GTK_TOOLBAR_GET_CLASS*(obj: pointer): PGtkToolbarClass
proc style_set*(a: var TGtkToolbar): guint
proc set_style_set*(a: var TGtkToolbar, `style_set`: guint)
proc icon_size_set*(a: var TGtkToolbar): guint
proc set_icon_size_set*(a: var TGtkToolbar, `icon_size_set`: guint)
proc gtk_toolbar_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                        importc: "gtk_toolbar_get_type".}
proc gtk_toolbar_new*(): PGtkToolbar{.cdecl, dynlib: gtklib,
                                     importc: "gtk_toolbar_new".}
proc gtk_toolbar_append_item*(toolbar: PGtkToolbar, text: cstring,
                              tooltip_text: cstring,
                              tooltip_private_text: cstring, icon: PGtkWidget,
                              callback: TGtkSignalFunc, user_data: gpointer): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_toolbar_append_item".}
proc gtk_toolbar_prepend_item*(toolbar: PGtkToolbar, text: cstring,
                               tooltip_text: cstring,
                               tooltip_private_text: cstring, icon: PGtkWidget,
                               callback: TGtkSignalFunc, user_data: gpointer): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_toolbar_prepend_item".}
proc gtk_toolbar_insert_item*(toolbar: PGtkToolbar, text: cstring,
                              tooltip_text: cstring,
                              tooltip_private_text: cstring, icon: PGtkWidget,
                              callback: TGtkSignalFunc, user_data: gpointer,
                              position: gint): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_insert_item".}
proc gtk_toolbar_insert_stock*(toolbar: PGtkToolbar, stock_id: cstring,
                               tooltip_text: cstring,
                               tooltip_private_text: cstring,
                               callback: TGtkSignalFunc, user_data: gpointer,
                               position: gint): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_insert_stock".}
proc gtk_toolbar_append_space*(toolbar: PGtkToolbar){.cdecl, dynlib: gtklib,
    importc: "gtk_toolbar_append_space".}
proc gtk_toolbar_prepend_space*(toolbar: PGtkToolbar){.cdecl, dynlib: gtklib,
    importc: "gtk_toolbar_prepend_space".}
proc gtk_toolbar_insert_space*(toolbar: PGtkToolbar, position: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_insert_space".}
proc gtk_toolbar_remove_space*(toolbar: PGtkToolbar, position: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_remove_space".}
proc gtk_toolbar_append_element*(toolbar: PGtkToolbar,
                                 thetype: TGtkToolbarChildType,
                                 widget: PGtkWidget, text: cstring,
                                 tooltip_text: cstring,
                                 tooltip_private_text: cstring,
                                 icon: PGtkWidget, callback: TGtkSignalFunc,
                                 user_data: gpointer): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_append_element".}
proc gtk_toolbar_prepend_element*(toolbar: PGtkToolbar,
                                  thetype: TGtkToolbarChildType,
                                  widget: PGtkWidget, text: cstring,
                                  tooltip_text: cstring,
                                  tooltip_private_text: cstring,
                                  icon: PGtkWidget, callback: TGtkSignalFunc,
                                  user_data: gpointer): PGtkWidget{.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_prepend_element".}
proc gtk_toolbar_insert_element*(toolbar: PGtkToolbar,
                                 thetype: TGtkToolbarChildType,
                                 widget: PGtkWidget, text: cstring,
                                 tooltip_text: cstring,
                                 tooltip_private_text: cstring,
                                 icon: PGtkWidget, callback: TGtkSignalFunc,
                                 user_data: gpointer, position: gint): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_toolbar_insert_element".}
proc gtk_toolbar_append_widget*(toolbar: PGtkToolbar, widget: PGtkWidget,
                                tooltip_text: cstring,
                                tooltip_private_text: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_append_widget".}
proc gtk_toolbar_prepend_widget*(toolbar: PGtkToolbar, widget: PGtkWidget,
                                 tooltip_text: cstring,
                                 tooltip_private_text: cstring){.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_prepend_widget".}
proc gtk_toolbar_insert_widget*(toolbar: PGtkToolbar, widget: PGtkWidget,
                                tooltip_text: cstring,
                                tooltip_private_text: cstring, position: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_toolbar_insert_widget".}
proc gtk_toolbar_set_orientation*(toolbar: PGtkToolbar,
                                  orientation: TGtkOrientation){.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_set_orientation".}
proc gtk_toolbar_set_style*(toolbar: PGtkToolbar, style: TGtkToolbarStyle){.
    cdecl, dynlib: gtklib, importc: "gtk_toolbar_set_style".}
proc gtk_toolbar_set_icon_size*(toolbar: PGtkToolbar, icon_size: TGtkIconSize){.
    cdecl, dynlib: gtklib, importc: "gtk_toolbar_set_icon_size".}
proc gtk_toolbar_set_tooltips*(toolbar: PGtkToolbar, enable: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_set_tooltips".}
proc gtk_toolbar_unset_style*(toolbar: PGtkToolbar){.cdecl, dynlib: gtklib,
    importc: "gtk_toolbar_unset_style".}
proc gtk_toolbar_unset_icon_size*(toolbar: PGtkToolbar){.cdecl, dynlib: gtklib,
    importc: "gtk_toolbar_unset_icon_size".}
proc gtk_toolbar_get_orientation*(toolbar: PGtkToolbar): TGtkOrientation{.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_get_orientation".}
proc gtk_toolbar_get_style*(toolbar: PGtkToolbar): TGtkToolbarStyle{.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_get_style".}
proc gtk_toolbar_get_icon_size*(toolbar: PGtkToolbar): TGtkIconSize{.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_get_icon_size".}
proc gtk_toolbar_get_tooltips*(toolbar: PGtkToolbar): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_toolbar_get_tooltips".}
const
  bm_TGtkTree_selection_mode* = 0x00000003'i16
  bp_TGtkTree_selection_mode* = 0'i16
  bm_TGtkTree_view_mode* = 0x00000004'i16
  bp_TGtkTree_view_mode* = 2'i16
  bm_TGtkTree_view_line* = 0x00000008'i16
  bp_TGtkTree_view_line* = 3'i16

proc GTK_TYPE_TREE*(): GType
proc GTK_TREE*(obj: pointer): PGtkTree
proc GTK_TREE_CLASS*(klass: pointer): PGtkTreeClass
proc GTK_IS_TREE*(obj: pointer): bool
proc GTK_IS_TREE_CLASS*(klass: pointer): bool
proc GTK_TREE_GET_CLASS*(obj: pointer): PGtkTreeClass
proc GTK_IS_ROOT_TREE*(obj: pointer): bool
proc GTK_TREE_ROOT_TREE*(obj: pointer): PGtkTree
proc GTK_TREE_SELECTION_OLD*(obj: pointer): PGList
proc selection_mode*(a: var TGtkTree): guint
proc set_selection_mode*(a: var TGtkTree, `selection_mode`: guint)
proc view_mode*(a: var TGtkTree): guint
proc set_view_mode*(a: var TGtkTree, `view_mode`: guint)
proc view_line*(a: var TGtkTree): guint
proc set_view_line*(a: var TGtkTree, `view_line`: guint)
proc gtk_tree_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                     importc: "gtk_tree_get_type".}
proc gtk_tree_new*(): PGtkTree{.cdecl, dynlib: gtklib, importc: "gtk_tree_new".}
proc gtk_tree_append*(tree: PGtkTree, tree_item: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_append".}
proc gtk_tree_prepend*(tree: PGtkTree, tree_item: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_prepend".}
proc gtk_tree_insert*(tree: PGtkTree, tree_item: PGtkWidget, position: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_insert".}
proc gtk_tree_remove_items*(tree: PGtkTree, items: PGList){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_remove_items".}
proc gtk_tree_clear_items*(tree: PGtkTree, start: gint, theEnd: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_clear_items".}
proc gtk_tree_select_item*(tree: PGtkTree, item: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_select_item".}
proc gtk_tree_unselect_item*(tree: PGtkTree, item: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_unselect_item".}
proc gtk_tree_select_child*(tree: PGtkTree, tree_item: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_select_child".}
proc gtk_tree_unselect_child*(tree: PGtkTree, tree_item: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_unselect_child".}
proc gtk_tree_child_position*(tree: PGtkTree, child: PGtkWidget): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_child_position".}
proc gtk_tree_set_selection_mode*(tree: PGtkTree, mode: TGtkSelectionMode){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_set_selection_mode".}
proc gtk_tree_set_view_mode*(tree: PGtkTree, mode: TGtkTreeViewMode){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_set_view_mode".}
proc gtk_tree_set_view_lines*(tree: PGtkTree, flag: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_set_view_lines".}
proc gtk_tree_remove_item*(tree: PGtkTree, child: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_remove_item".}
proc GTK_TYPE_TREE_DRAG_SOURCE*(): GType
proc GTK_TREE_DRAG_SOURCE*(obj: pointer): PGtkTreeDragSource
proc GTK_IS_TREE_DRAG_SOURCE*(obj: pointer): bool
proc GTK_TREE_DRAG_SOURCE_GET_IFACE*(obj: pointer): PGtkTreeDragSourceIface
proc gtk_tree_drag_source_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_drag_source_get_type".}
proc gtk_tree_drag_source_row_draggable*(drag_source: PGtkTreeDragSource,
    path: PGtkTreePath): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_tree_drag_source_row_draggable".}
proc gtk_tree_drag_source_drag_data_delete*(drag_source: PGtkTreeDragSource,
    path: PGtkTreePath): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_tree_drag_source_drag_data_delete".}
proc gtk_tree_drag_source_drag_data_get*(drag_source: PGtkTreeDragSource,
    path: PGtkTreePath, selection_data: PGtkSelectionData): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_drag_source_drag_data_get".}
proc GTK_TYPE_TREE_DRAG_DEST*(): GType
proc GTK_TREE_DRAG_DEST*(obj: pointer): PGtkTreeDragDest
proc GTK_IS_TREE_DRAG_DEST*(obj: pointer): bool
proc GTK_TREE_DRAG_DEST_GET_IFACE*(obj: pointer): PGtkTreeDragDestIface
proc gtk_tree_drag_dest_get_type*(): GType{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_drag_dest_get_type".}
proc gtk_tree_drag_dest_drag_data_received*(drag_dest: PGtkTreeDragDest,
    dest: PGtkTreePath, selection_data: PGtkSelectionData): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_drag_dest_drag_data_received".}
proc gtk_tree_drag_dest_row_drop_possible*(drag_dest: PGtkTreeDragDest,
    dest_path: PGtkTreePath, selection_data: PGtkSelectionData): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_drag_dest_row_drop_possible".}
proc gtk_tree_set_row_drag_data*(selection_data: PGtkSelectionData,
                                 tree_model: PGtkTreeModel, path: PGtkTreePath): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_set_row_drag_data".}
const
  bm_TGtkTreeItem_expanded* = 0x00000001'i16
  bp_TGtkTreeItem_expanded* = 0'i16

proc GTK_TYPE_TREE_ITEM*(): GType
proc GTK_TREE_ITEM*(obj: pointer): PGtkTreeItem
proc GTK_TREE_ITEM_CLASS*(klass: pointer): PGtkTreeItemClass
proc GTK_IS_TREE_ITEM*(obj: pointer): bool
proc GTK_IS_TREE_ITEM_CLASS*(klass: pointer): bool
proc GTK_TREE_ITEM_GET_CLASS*(obj: pointer): PGtkTreeItemClass
proc GTK_TREE_ITEM_SUBTREE*(obj: pointer): PGtkWidget
proc expanded*(a: var TGtkTreeItem): guint
proc set_expanded*(a: var TGtkTreeItem, `expanded`: guint)
proc gtk_tree_item_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_item_get_type".}
proc gtk_tree_item_new*(): PGtkTreeItem{.cdecl, dynlib: gtklib,
                                       importc: "gtk_tree_item_new".}
proc gtk_tree_item_new_with_label*(`label`: cstring): PGtkTreeItem{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_item_new_with_label".}
proc gtk_tree_item_set_subtree*(tree_item: PGtkTreeItem, subtree: PGtkWidget){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_item_set_subtree".}
proc gtk_tree_item_remove_subtree*(tree_item: PGtkTreeItem){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_item_remove_subtree".}
proc gtk_tree_item_select*(tree_item: PGtkTreeItem){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_item_select".}
proc gtk_tree_item_deselect*(tree_item: PGtkTreeItem){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_item_deselect".}
proc gtk_tree_item_expand*(tree_item: PGtkTreeItem){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_item_expand".}
proc gtk_tree_item_collapse*(tree_item: PGtkTreeItem){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_item_collapse".}
proc GTK_TYPE_TREE_SELECTION*(): GType
proc GTK_TREE_SELECTION*(obj: pointer): PGtkTreeSelection
proc GTK_TREE_SELECTION_CLASS*(klass: pointer): PGtkTreeSelectionClass
proc GTK_IS_TREE_SELECTION*(obj: pointer): bool
proc GTK_IS_TREE_SELECTION_CLASS*(klass: pointer): bool
proc GTK_TREE_SELECTION_GET_CLASS*(obj: pointer): PGtkTreeSelectionClass
proc gtk_tree_selection_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_selection_get_type".}
proc gtk_tree_selection_set_mode*(selection: PGtkTreeSelection,
                                  thetype: TGtkSelectionMode){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_selection_set_mode".}
proc gtk_tree_selection_get_mode*(selection: PGtkTreeSelection): TGtkSelectionMode{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_selection_get_mode".}
proc gtk_tree_selection_set_select_function*(selection: PGtkTreeSelection,
    fun: TGtkTreeSelectionFunc, data: gpointer, destroy: TGtkDestroyNotify){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_selection_set_select_function".}
proc gtk_tree_selection_get_user_data*(selection: PGtkTreeSelection): gpointer{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_selection_get_user_data".}
proc gtk_tree_selection_get_tree_view*(selection: PGtkTreeSelection): PGtkTreeView{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_selection_get_tree_view".}
proc gtk_tree_selection_get_selected*(selection: PGtkTreeSelection,
                                      model: PPGtkTreeModel, iter: PGtkTreeIter): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_selection_get_selected".}
proc gtk_tree_selection_get_selected_rows*(selection: PGtkTreeSelection,
    model: PPGtkTreeModel): PGList{.cdecl, dynlib: gtklib, importc: "gtk_tree_selection_get_selected_rows".}
proc gtk_tree_selection_selected_foreach*(selection: PGtkTreeSelection,
    fun: TGtkTreeSelectionForeachFunc, data: gpointer){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_selection_selected_foreach".}
proc gtk_tree_selection_select_path*(selection: PGtkTreeSelection,
                                     path: PGtkTreePath){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_selection_select_path".}
proc gtk_tree_selection_unselect_path*(selection: PGtkTreeSelection,
                                       path: PGtkTreePath){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_selection_unselect_path".}
proc gtk_tree_selection_select_iter*(selection: PGtkTreeSelection,
                                     iter: PGtkTreeIter){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_selection_select_iter".}
proc gtk_tree_selection_unselect_iter*(selection: PGtkTreeSelection,
                                       iter: PGtkTreeIter){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_selection_unselect_iter".}
proc gtk_tree_selection_path_is_selected*(selection: PGtkTreeSelection,
    path: PGtkTreePath): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_tree_selection_path_is_selected".}
proc gtk_tree_selection_iter_is_selected*(selection: PGtkTreeSelection,
    iter: PGtkTreeIter): gboolean{.cdecl, dynlib: gtklib, importc: "gtk_tree_selection_iter_is_selected".}
proc gtk_tree_selection_select_all*(selection: PGtkTreeSelection){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_selection_select_all".}
proc gtk_tree_selection_unselect_all*(selection: PGtkTreeSelection){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_selection_unselect_all".}
proc gtk_tree_selection_select_range*(selection: PGtkTreeSelection,
                                      start_path: PGtkTreePath,
                                      end_path: PGtkTreePath){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_selection_select_range".}
const
  bm_TGtkTreeStore_columns_dirty* = 0x00000001'i16
  bp_TGtkTreeStore_columns_dirty* = 0'i16

proc GTK_TYPE_TREE_STORE*(): GType
proc GTK_TREE_STORE*(obj: pointer): PGtkTreeStore
proc GTK_TREE_STORE_CLASS*(klass: pointer): PGtkTreeStoreClass
proc GTK_IS_TREE_STORE*(obj: pointer): bool
proc GTK_IS_TREE_STORE_CLASS*(klass: pointer): bool
proc GTK_TREE_STORE_GET_CLASS*(obj: pointer): PGtkTreeStoreClass
proc columns_dirty*(a: var TGtkTreeStore): guint
proc set_columns_dirty*(a: var TGtkTreeStore, `columns_dirty`: guint)
proc gtk_tree_store_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_store_get_type".}
proc gtk_tree_store_newv*(n_columns: gint, types: PGType): PGtkTreeStore{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_store_newv".}
proc gtk_tree_store_set_column_types*(tree_store: PGtkTreeStore,
                                      n_columns: gint, types: PGType){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_store_set_column_types".}
proc gtk_tree_store_set_value*(tree_store: PGtkTreeStore, iter: PGtkTreeIter,
                               column: gint, value: PGValue){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_store_set_value".}
proc gtk_tree_store_remove*(tree_store: PGtkTreeStore, iter: PGtkTreeIter){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_store_remove".}
proc gtk_tree_store_insert*(tree_store: PGtkTreeStore, iter: PGtkTreeIter,
                            parent: PGtkTreeIter, position: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_store_insert".}
proc gtk_tree_store_insert_before*(tree_store: PGtkTreeStore,
                                   iter: PGtkTreeIter, parent: PGtkTreeIter,
                                   sibling: PGtkTreeIter){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_store_insert_before".}
proc gtk_tree_store_insert_after*(tree_store: PGtkTreeStore, iter: PGtkTreeIter,
                                  parent: PGtkTreeIter, sibling: PGtkTreeIter){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_store_insert_after".}
proc gtk_tree_store_prepend*(tree_store: PGtkTreeStore, iter: PGtkTreeIter,
                             parent: PGtkTreeIter){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_store_prepend".}
proc gtk_tree_store_append*(tree_store: PGtkTreeStore, iter: PGtkTreeIter,
                            parent: PGtkTreeIter){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_store_append".}
proc gtk_tree_store_is_ancestor*(tree_store: PGtkTreeStore, iter: PGtkTreeIter,
                                 descendant: PGtkTreeIter): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_store_is_ancestor".}
proc gtk_tree_store_iter_depth*(tree_store: PGtkTreeStore, iter: PGtkTreeIter): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_store_iter_depth".}
proc gtk_tree_store_clear*(tree_store: PGtkTreeStore){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_store_clear".}
const
  bm_TGtkTreeViewColumn_visible* = 0x00000001'i16
  bp_TGtkTreeViewColumn_visible* = 0'i16
  bm_TGtkTreeViewColumn_resizable* = 0x00000002'i16
  bp_TGtkTreeViewColumn_resizable* = 1'i16
  bm_TGtkTreeViewColumn_clickable* = 0x00000004'i16
  bp_TGtkTreeViewColumn_clickable* = 2'i16
  bm_TGtkTreeViewColumn_dirty* = 0x00000008'i16
  bp_TGtkTreeViewColumn_dirty* = 3'i16
  bm_TGtkTreeViewColumn_show_sort_indicator* = 0x00000010'i16
  bp_TGtkTreeViewColumn_show_sort_indicator* = 4'i16
  bm_TGtkTreeViewColumn_maybe_reordered* = 0x00000020'i16
  bp_TGtkTreeViewColumn_maybe_reordered* = 5'i16
  bm_TGtkTreeViewColumn_reorderable* = 0x00000040'i16
  bp_TGtkTreeViewColumn_reorderable* = 6'i16
  bm_TGtkTreeViewColumn_use_resized_width* = 0x00000080'i16
  bp_TGtkTreeViewColumn_use_resized_width* = 7'i16

proc GTK_TYPE_TREE_VIEW_COLUMN*(): GType
proc GTK_TREE_VIEW_COLUMN*(obj: pointer): PGtkTreeViewColumn
proc GTK_TREE_VIEW_COLUMN_CLASS*(klass: pointer): PGtkTreeViewColumnClass
proc GTK_IS_TREE_VIEW_COLUMN*(obj: pointer): bool
proc GTK_IS_TREE_VIEW_COLUMN_CLASS*(klass: pointer): bool
proc GTK_TREE_VIEW_COLUMN_GET_CLASS*(obj: pointer): PGtkTreeViewColumnClass
proc visible*(a: var TGtkTreeViewColumn): guint
proc set_visible*(a: var TGtkTreeViewColumn, `visible`: guint)
proc resizable*(a: var TGtkTreeViewColumn): guint
proc set_resizable*(a: var TGtkTreeViewColumn, `resizable`: guint)
proc clickable*(a: var TGtkTreeViewColumn): guint
proc set_clickable*(a: var TGtkTreeViewColumn, `clickable`: guint)
proc dirty*(a: var TGtkTreeViewColumn): guint
proc set_dirty*(a: var TGtkTreeViewColumn, `dirty`: guint)
proc show_sort_indicator*(a: var TGtkTreeViewColumn): guint
proc set_show_sort_indicator*(a: var TGtkTreeViewColumn,
                              `show_sort_indicator`: guint)
proc maybe_reordered*(a: var TGtkTreeViewColumn): guint
proc set_maybe_reordered*(a: var TGtkTreeViewColumn, `maybe_reordered`: guint)
proc reorderable*(a: var TGtkTreeViewColumn): guint
proc set_reorderable*(a: var TGtkTreeViewColumn, `reorderable`: guint)
proc use_resized_width*(a: var TGtkTreeViewColumn): guint
proc set_use_resized_width*(a: var TGtkTreeViewColumn,
                            `use_resized_width`: guint)
proc gtk_tree_view_column_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_column_get_type".}
proc gtk_tree_view_column_new*(): PGtkTreeViewColumn{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_column_new".}
proc gtk_tree_view_column_pack_start*(tree_column: PGtkTreeViewColumn,
                                      cell: PGtkCellRenderer, expand: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_pack_start".}
proc gtk_tree_view_column_pack_end*(tree_column: PGtkTreeViewColumn,
                                    cell: PGtkCellRenderer, expand: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_pack_end".}
proc gtk_tree_view_column_clear*(tree_column: PGtkTreeViewColumn){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_column_clear".}
proc gtk_tree_view_column_get_cell_renderers*(tree_column: PGtkTreeViewColumn): PGList{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_cell_renderers".}
proc gtk_tree_view_column_add_attribute*(tree_column: PGtkTreeViewColumn,
    cell_renderer: PGtkCellRenderer, attribute: cstring, column: gint){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_column_add_attribute".}
proc gtk_tree_view_column_set_cell_data_func*(tree_column: PGtkTreeViewColumn,
    cell_renderer: PGtkCellRenderer, fun: TGtkTreeCellDataFunc,
    func_data: gpointer, destroy: TGtkDestroyNotify){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_column_set_cell_data_func".}
proc gtk_tree_view_column_clear_attributes*(tree_column: PGtkTreeViewColumn,
    cell_renderer: PGtkCellRenderer){.cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_clear_attributes".}
proc gtk_tree_view_column_set_spacing*(tree_column: PGtkTreeViewColumn,
                                       spacing: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_column_set_spacing".}
proc gtk_tree_view_column_get_spacing*(tree_column: PGtkTreeViewColumn): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_spacing".}
proc gtk_tree_view_column_set_visible*(tree_column: PGtkTreeViewColumn,
                                       visible: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_column_set_visible".}
proc gtk_tree_view_column_get_visible*(tree_column: PGtkTreeViewColumn): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_visible".}
proc gtk_tree_view_column_set_resizable*(tree_column: PGtkTreeViewColumn,
    resizable: gboolean){.cdecl, dynlib: gtklib,
                          importc: "gtk_tree_view_column_set_resizable".}
proc gtk_tree_view_column_get_resizable*(tree_column: PGtkTreeViewColumn): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_resizable".}
proc gtk_tree_view_column_set_sizing*(tree_column: PGtkTreeViewColumn,
                                      thetype: TGtkTreeViewColumnSizing){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_column_set_sizing".}
proc gtk_tree_view_column_get_sizing*(tree_column: PGtkTreeViewColumn): TGtkTreeViewColumnSizing{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_sizing".}
proc gtk_tree_view_column_get_width*(tree_column: PGtkTreeViewColumn): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_width".}
proc gtk_tree_view_column_get_fixed_width*(tree_column: PGtkTreeViewColumn): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_fixed_width".}
proc gtk_tree_view_column_set_fixed_width*(tree_column: PGtkTreeViewColumn,
    fixed_width: gint){.cdecl, dynlib: gtklib,
                        importc: "gtk_tree_view_column_set_fixed_width".}
proc gtk_tree_view_column_set_min_width*(tree_column: PGtkTreeViewColumn,
    min_width: gint){.cdecl, dynlib: gtklib,
                      importc: "gtk_tree_view_column_set_min_width".}
proc gtk_tree_view_column_get_min_width*(tree_column: PGtkTreeViewColumn): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_min_width".}
proc gtk_tree_view_column_set_max_width*(tree_column: PGtkTreeViewColumn,
    max_width: gint){.cdecl, dynlib: gtklib,
                      importc: "gtk_tree_view_column_set_max_width".}
proc gtk_tree_view_column_get_max_width*(tree_column: PGtkTreeViewColumn): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_max_width".}
proc gtk_tree_view_column_clicked*(tree_column: PGtkTreeViewColumn){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_column_clicked".}
proc gtk_tree_view_column_set_title*(tree_column: PGtkTreeViewColumn,
                                     title: cstring){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_column_set_title".}
proc gtk_tree_view_column_get_title*(tree_column: PGtkTreeViewColumn): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_title".}
proc gtk_tree_view_column_set_clickable*(tree_column: PGtkTreeViewColumn,
    clickable: gboolean){.cdecl, dynlib: gtklib,
                          importc: "gtk_tree_view_column_set_clickable".}
proc gtk_tree_view_column_get_clickable*(tree_column: PGtkTreeViewColumn): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_clickable".}
proc gtk_tree_view_column_set_widget*(tree_column: PGtkTreeViewColumn,
                                      widget: PGtkWidget){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_column_set_widget".}
proc gtk_tree_view_column_get_widget*(tree_column: PGtkTreeViewColumn): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_widget".}
proc gtk_tree_view_column_set_alignment*(tree_column: PGtkTreeViewColumn,
    xalign: gfloat){.cdecl, dynlib: gtklib,
                     importc: "gtk_tree_view_column_set_alignment".}
proc gtk_tree_view_column_get_alignment*(tree_column: PGtkTreeViewColumn): gfloat{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_alignment".}
proc gtk_tree_view_column_set_reorderable*(tree_column: PGtkTreeViewColumn,
    reorderable: gboolean){.cdecl, dynlib: gtklib,
                            importc: "gtk_tree_view_column_set_reorderable".}
proc gtk_tree_view_column_get_reorderable*(tree_column: PGtkTreeViewColumn): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_reorderable".}
proc gtk_tree_view_column_set_sort_column_id*(tree_column: PGtkTreeViewColumn,
    sort_column_id: gint){.cdecl, dynlib: gtklib,
                           importc: "gtk_tree_view_column_set_sort_column_id".}
proc gtk_tree_view_column_get_sort_column_id*(tree_column: PGtkTreeViewColumn): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_sort_column_id".}
proc gtk_tree_view_column_set_sort_indicator*(tree_column: PGtkTreeViewColumn,
    setting: gboolean){.cdecl, dynlib: gtklib,
                        importc: "gtk_tree_view_column_set_sort_indicator".}
proc gtk_tree_view_column_get_sort_indicator*(tree_column: PGtkTreeViewColumn): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_sort_indicator".}
proc gtk_tree_view_column_set_sort_order*(tree_column: PGtkTreeViewColumn,
    order: TGtkSortType){.cdecl, dynlib: gtklib,
                          importc: "gtk_tree_view_column_set_sort_order".}
proc gtk_tree_view_column_get_sort_order*(tree_column: PGtkTreeViewColumn): TGtkSortType{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_sort_order".}
proc gtk_tree_view_column_cell_set_cell_data*(tree_column: PGtkTreeViewColumn,
    tree_model: PGtkTreeModel, iter: PGtkTreeIter, is_expander: gboolean,
    is_expanded: gboolean){.cdecl, dynlib: gtklib,
                            importc: "gtk_tree_view_column_cell_set_cell_data".}
proc gtk_tree_view_column_cell_get_size*(tree_column: PGtkTreeViewColumn,
    cell_area: PGdkRectangle, x_offset: Pgint, y_offset: Pgint, width: Pgint,
    height: Pgint){.cdecl, dynlib: gtklib,
                    importc: "gtk_tree_view_column_cell_get_size".}
proc gtk_tree_view_column_cell_is_visible*(tree_column: PGtkTreeViewColumn): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_cell_is_visible".}
proc gtk_tree_view_column_focus_cell*(tree_column: PGtkTreeViewColumn,
                                      cell: PGtkCellRenderer){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_column_focus_cell".}
proc gtk_tree_view_column_set_expand*(tree_column: PGtkTreeViewColumn,
                                      Expand: gboolean){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_column_set_expand".}
proc gtk_tree_view_column_get_expand*(tree_column: PGtkTreeViewColumn): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_column_get_expand".}
const
  GTK_RBNODE_BLACK* = 1 shl 0
  GTK_RBNODE_RED* = 1 shl 1
  GTK_RBNODE_IS_PARENT* = 1 shl 2
  GTK_RBNODE_IS_SELECTED* = 1 shl 3
  GTK_RBNODE_IS_PRELIT* = 1 shl 4
  GTK_RBNODE_IS_SEMI_COLLAPSED* = 1 shl 5
  GTK_RBNODE_IS_SEMI_EXPANDED* = 1 shl 6
  GTK_RBNODE_INVALID* = 1 shl 7
  GTK_RBNODE_COLUMN_INVALID* = 1 shl 8
  GTK_RBNODE_DESCENDANTS_INVALID* = 1 shl 9
  GTK_RBNODE_NON_COLORS* = GTK_RBNODE_IS_PARENT or GTK_RBNODE_IS_SELECTED or
      GTK_RBNODE_IS_PRELIT or GTK_RBNODE_IS_SEMI_COLLAPSED or
      GTK_RBNODE_IS_SEMI_EXPANDED or GTK_RBNODE_INVALID or
      GTK_RBNODE_COLUMN_INVALID or GTK_RBNODE_DESCENDANTS_INVALID

const
  bm_TGtkRBNode_flags* = 0x00003FFF'i16
  bp_TGtkRBNode_flags* = 0'i16
  bm_TGtkRBNode_parity* = 0x00004000'i16
  bp_TGtkRBNode_parity* = 14'i16

proc flags*(a: PGtkRBNode): guint
proc set_flags*(a: PGtkRBNode, `flags`: guint)
proc parity*(a: PGtkRBNode): guint
proc set_parity*(a: PGtkRBNode, `parity`: guint)
proc GTK_RBNODE_GET_COLOR*(node: PGtkRBNode): guint
proc GTK_RBNODE_SET_COLOR*(node: PGtkRBNode, color: guint)
proc GTK_RBNODE_GET_HEIGHT*(node: PGtkRBNode): gint
proc GTK_RBNODE_SET_FLAG*(node: PGtkRBNode, flag: guint16)
proc GTK_RBNODE_UNSET_FLAG*(node: PGtkRBNode, flag: guint16)
proc GTK_RBNODE_FLAG_SET*(node: PGtkRBNode, flag: guint): bool
proc gtk_rbtree_push_allocator*(allocator: PGAllocator){.cdecl,
    dynlib: gtklib, importc: "_gtk_rbtree_push_allocator".}
proc gtk_rbtree_pop_allocator*(){.cdecl, dynlib: gtklib,
                                    importc: "_gtk_rbtree_pop_allocator".}
proc gtk_rbtree_new*(): PGtkRBTree{.cdecl, dynlib: gtklib,
                                      importc: "_gtk_rbtree_new".}
proc gtk_rbtree_free*(tree: PGtkRBTree){.cdecl, dynlib: gtklib,
    importc: "_gtk_rbtree_free".}
proc gtk_rbtree_remove*(tree: PGtkRBTree){.cdecl, dynlib: gtklib,
    importc: "_gtk_rbtree_remove".}
proc gtk_rbtree_destroy*(tree: PGtkRBTree){.cdecl, dynlib: gtklib,
    importc: "_gtk_rbtree_destroy".}
proc gtk_rbtree_insert_before*(tree: PGtkRBTree, node: PGtkRBNode,
                                 height: gint, valid: gboolean): PGtkRBNode{.
    cdecl, dynlib: gtklib, importc: "_gtk_rbtree_insert_before".}
proc gtk_rbtree_insert_after*(tree: PGtkRBTree, node: PGtkRBNode,
                                height: gint, valid: gboolean): PGtkRBNode{.
    cdecl, dynlib: gtklib, importc: "_gtk_rbtree_insert_after".}
proc gtk_rbtree_remove_node*(tree: PGtkRBTree, node: PGtkRBNode){.cdecl,
    dynlib: gtklib, importc: "_gtk_rbtree_remove_node".}
proc gtk_rbtree_reorder*(tree: PGtkRBTree, new_order: Pgint, length: gint){.
    cdecl, dynlib: gtklib, importc: "_gtk_rbtree_reorder".}
proc gtk_rbtree_find_count*(tree: PGtkRBTree, count: gint): PGtkRBNode{.cdecl,
    dynlib: gtklib, importc: "_gtk_rbtree_find_count".}
proc gtk_rbtree_node_set_height*(tree: PGtkRBTree, node: PGtkRBNode,
                                   height: gint){.cdecl, dynlib: gtklib,
    importc: "_gtk_rbtree_node_set_height".}
proc gtk_rbtree_node_mark_invalid*(tree: PGtkRBTree, node: PGtkRBNode){.
    cdecl, dynlib: gtklib, importc: "_gtk_rbtree_node_mark_invalid".}
proc gtk_rbtree_node_mark_valid*(tree: PGtkRBTree, node: PGtkRBNode){.cdecl,
    dynlib: gtklib, importc: "_gtk_rbtree_node_mark_valid".}
proc gtk_rbtree_column_invalid*(tree: PGtkRBTree){.cdecl, dynlib: gtklib,
    importc: "_gtk_rbtree_column_invalid".}
proc gtk_rbtree_mark_invalid*(tree: PGtkRBTree){.cdecl, dynlib: gtklib,
    importc: "_gtk_rbtree_mark_invalid".}
proc gtk_rbtree_set_fixed_height*(tree: PGtkRBTree, height: gint){.cdecl,
    dynlib: gtklib, importc: "_gtk_rbtree_set_fixed_height".}
proc gtk_rbtree_node_find_offset*(tree: PGtkRBTree, node: PGtkRBNode): gint{.
    cdecl, dynlib: gtklib, importc: "_gtk_rbtree_node_find_offset".}
proc gtk_rbtree_node_find_parity*(tree: PGtkRBTree, node: PGtkRBNode): gint{.
    cdecl, dynlib: gtklib, importc: "_gtk_rbtree_node_find_parity".}
proc gtk_rbtree_traverse*(tree: PGtkRBTree, node: PGtkRBNode,
                            order: TGTraverseType,
                            fun: TGtkRBTreeTraverseFunc, data: gpointer){.
    cdecl, dynlib: gtklib, importc: "_gtk_rbtree_traverse".}
proc gtk_rbtree_next*(tree: PGtkRBTree, node: PGtkRBNode): PGtkRBNode{.cdecl,
    dynlib: gtklib, importc: "_gtk_rbtree_next".}
proc gtk_rbtree_prev*(tree: PGtkRBTree, node: PGtkRBNode): PGtkRBNode{.cdecl,
    dynlib: gtklib, importc: "_gtk_rbtree_prev".}
proc gtk_rbtree_get_depth*(tree: PGtkRBTree): gint{.cdecl, dynlib: gtklib,
    importc: "_gtk_rbtree_get_depth".}
const
  TREE_VIEW_DRAG_WIDTH* = 6
  GTK_TREE_VIEW_IS_LIST* = 1 shl 0
  GTK_TREE_VIEW_SHOW_EXPANDERS* = 1 shl 1
  GTK_TREE_VIEW_IN_COLUMN_RESIZE* = 1 shl 2
  GTK_TREE_VIEW_ARROW_PRELIT* = 1 shl 3
  GTK_TREE_VIEW_HEADERS_VISIBLE* = 1 shl 4
  GTK_TREE_VIEW_DRAW_KEYFOCUS* = 1 shl 5
  GTK_TREE_VIEW_MODEL_SETUP* = 1 shl 6
  GTK_TREE_VIEW_IN_COLUMN_DRAG* = 1 shl 7
  DRAG_COLUMN_WINDOW_STATE_UNSET* = 0
  DRAG_COLUMN_WINDOW_STATE_ORIGINAL* = 1
  DRAG_COLUMN_WINDOW_STATE_ARROW* = 2
  DRAG_COLUMN_WINDOW_STATE_ARROW_LEFT* = 3
  DRAG_COLUMN_WINDOW_STATE_ARROW_RIGHT* = 4

proc GTK_TREE_VIEW_SET_FLAG*(tree_view: PGtkTreeView, flag: guint)
proc GTK_TREE_VIEW_UNSET_FLAG*(tree_view: PGtkTreeView, flag: guint)
proc GTK_TREE_VIEW_FLAG_SET*(tree_view: PGtkTreeView, flag: guint): bool
proc TREE_VIEW_HEADER_HEIGHT*(tree_view: PGtkTreeView): int32
proc TREE_VIEW_COLUMN_REQUESTED_WIDTH*(column: PGtkTreeViewColumn): int32
proc TREE_VIEW_DRAW_EXPANDERS*(tree_view: PGtkTreeView): bool
proc TREE_VIEW_COLUMN_DRAG_DEAD_MULTIPLIER*(tree_view: PGtkTreeView): int32
const
  bm_TGtkTreeViewPrivate_scroll_to_use_align* = 0x00000001'i16
  bp_TGtkTreeViewPrivate_scroll_to_use_align* = 0'i16
  bm_TGtkTreeViewPrivate_fixed_height_check* = 0x00000002'i16
  bp_TGtkTreeViewPrivate_fixed_height_check* = 1'i16
  bm_TGtkTreeViewPrivate_reorderable* = 0x00000004'i16
  bp_TGtkTreeViewPrivate_reorderable* = 2'i16
  bm_TGtkTreeViewPrivate_header_has_focus* = 0x00000008'i16
  bp_TGtkTreeViewPrivate_header_has_focus* = 3'i16
  bm_TGtkTreeViewPrivate_drag_column_window_state* = 0x00000070'i16
  bp_TGtkTreeViewPrivate_drag_column_window_state* = 4'i16
  bm_TGtkTreeViewPrivate_has_rules* = 0x00000080'i16
  bp_TGtkTreeViewPrivate_has_rules* = 7'i16
  bm_TGtkTreeViewPrivate_mark_rows_col_dirty* = 0x00000100'i16
  bp_TGtkTreeViewPrivate_mark_rows_col_dirty* = 8'i16
  bm_TGtkTreeViewPrivate_enable_search* = 0x00000200'i16
  bp_TGtkTreeViewPrivate_enable_search* = 9'i16
  bm_TGtkTreeViewPrivate_disable_popdown* = 0x00000400'i16
  bp_TGtkTreeViewPrivate_disable_popdown* = 10'i16

proc scroll_to_use_align*(a: var TGtkTreeViewPrivate): guint
proc set_scroll_to_use_align*(a: var TGtkTreeViewPrivate,
                              `scroll_to_use_align`: guint)
proc fixed_height_check*(a: var TGtkTreeViewPrivate): guint
proc set_fixed_height_check*(a: var TGtkTreeViewPrivate,
                             `fixed_height_check`: guint)
proc reorderable*(a: var TGtkTreeViewPrivate): guint
proc set_reorderable*(a: var TGtkTreeViewPrivate, `reorderable`: guint)
proc header_has_focus*(a: var TGtkTreeViewPrivate): guint
proc set_header_has_focus*(a: var TGtkTreeViewPrivate, `header_has_focus`: guint)
proc drag_column_window_state*(a: var TGtkTreeViewPrivate): guint
proc set_drag_column_window_state*(a: var TGtkTreeViewPrivate,
                                   `drag_column_window_state`: guint)
proc has_rules*(a: var TGtkTreeViewPrivate): guint
proc set_has_rules*(a: var TGtkTreeViewPrivate, `has_rules`: guint)
proc mark_rows_col_dirty*(a: var TGtkTreeViewPrivate): guint
proc set_mark_rows_col_dirty*(a: var TGtkTreeViewPrivate,
                              `mark_rows_col_dirty`: guint)
proc enable_search*(a: var TGtkTreeViewPrivate): guint
proc set_enable_search*(a: var TGtkTreeViewPrivate, `enable_search`: guint)
proc disable_popdown*(a: var TGtkTreeViewPrivate): guint
proc set_disable_popdown*(a: var TGtkTreeViewPrivate, `disable_popdown`: guint)
proc gtk_tree_selection_internal_select_node*(selection: PGtkTreeSelection,
    node: PGtkRBNode, tree: PGtkRBTree, path: PGtkTreePath,
    state: TGdkModifierType, override_browse_mode: gboolean){.cdecl,
    dynlib: gtklib, importc: "_gtk_tree_selection_internal_select_node".}
proc gtk_tree_view_find_node*(tree_view: PGtkTreeView, path: PGtkTreePath,
                                tree: var PGtkRBTree, node: var PGtkRBNode): gboolean{.
    cdecl, dynlib: gtklib, importc: "_gtk_tree_view_find_node".}
proc gtk_tree_view_find_path*(tree_view: PGtkTreeView, tree: PGtkRBTree,
                                node: PGtkRBNode): PGtkTreePath{.cdecl,
    dynlib: gtklib, importc: "_gtk_tree_view_find_path".}
proc gtk_tree_view_child_move_resize*(tree_view: PGtkTreeView,
                                        widget: PGtkWidget, x: gint, y: gint,
                                        width: gint, height: gint){.cdecl,
    dynlib: gtklib, importc: "_gtk_tree_view_child_move_resize".}
proc gtk_tree_view_queue_draw_node*(tree_view: PGtkTreeView, tree: PGtkRBTree,
                                      node: PGtkRBNode,
                                      clip_rect: PGdkRectangle){.cdecl,
    dynlib: gtklib, importc: "_gtk_tree_view_queue_draw_node".}
proc gtk_tree_view_column_realize_button*(column: PGtkTreeViewColumn){.cdecl,
    dynlib: gtklib, importc: "_gtk_tree_view_column_realize_button".}
proc gtk_tree_view_column_unrealize_button*(column: PGtkTreeViewColumn){.
    cdecl, dynlib: gtklib, importc: "_gtk_tree_view_column_unrealize_button".}
proc gtk_tree_view_column_set_tree_view*(column: PGtkTreeViewColumn,
    tree_view: PGtkTreeView){.cdecl, dynlib: gtklib,
                              importc: "_gtk_tree_view_column_set_tree_view".}
proc gtk_tree_view_column_unset_tree_view*(column: PGtkTreeViewColumn){.cdecl,
    dynlib: gtklib, importc: "_gtk_tree_view_column_unset_tree_view".}
proc gtk_tree_view_column_set_width*(column: PGtkTreeViewColumn, width: gint){.
    cdecl, dynlib: gtklib, importc: "_gtk_tree_view_column_set_width".}
proc gtk_tree_view_column_start_drag*(tree_view: PGtkTreeView,
                                        column: PGtkTreeViewColumn){.cdecl,
    dynlib: gtklib, importc: "_gtk_tree_view_column_start_drag".}
proc gtk_tree_view_column_start_editing*(tree_column: PGtkTreeViewColumn,
    editable_widget: PGtkCellEditable){.cdecl, dynlib: gtklib, importc: "_gtk_tree_view_column_start_editing".}
proc gtk_tree_view_column_stop_editing*(tree_column: PGtkTreeViewColumn){.
    cdecl, dynlib: gtklib, importc: "_gtk_tree_view_column_stop_editing".}
proc gtk_tree_view_install_mark_rows_col_dirty*(tree_view: PGtkTreeView){.
    cdecl, dynlib: gtklib,
    importc: "_gtk_tree_view_install_mark_rows_col_dirty".}
proc DOgtk_tree_view_column_autosize*(tree_view: PGtkTreeView,
                                      column: PGtkTreeViewColumn){.cdecl,
    dynlib: gtklib, importc: "_gtk_tree_view_column_autosize".}
proc gtk_tree_view_column_has_editable_cell*(column: PGtkTreeViewColumn): gboolean{.
    cdecl, dynlib: gtklib, importc: "_gtk_tree_view_column_has_editable_cell".}
proc gtk_tree_view_column_get_edited_cell*(column: PGtkTreeViewColumn): PGtkCellRenderer{.
    cdecl, dynlib: gtklib, importc: "_gtk_tree_view_column_get_edited_cell".}
proc gtk_tree_view_column_count_special_cells*(column: PGtkTreeViewColumn): gint{.
    cdecl, dynlib: gtklib, importc: "_gtk_tree_view_column_count_special_cells".}
proc gtk_tree_view_column_get_cell_at_pos*(column: PGtkTreeViewColumn, x: gint): PGtkCellRenderer{.
    cdecl, dynlib: gtklib, importc: "_gtk_tree_view_column_get_cell_at_pos".}
proc gtk_tree_selection_new*(): PGtkTreeSelection{.cdecl, dynlib: gtklib,
    importc: "_gtk_tree_selection_new".}
proc gtk_tree_selection_new_with_tree_view*(tree_view: PGtkTreeView): PGtkTreeSelection{.
    cdecl, dynlib: gtklib, importc: "_gtk_tree_selection_new_with_tree_view".}
proc gtk_tree_selection_set_tree_view*(selection: PGtkTreeSelection,
    tree_view: PGtkTreeView){.cdecl, dynlib: gtklib,
                              importc: "_gtk_tree_selection_set_tree_view".}
proc gtk_tree_view_column_cell_render*(tree_column: PGtkTreeViewColumn,
    window: PGdkWindow, background_area: PGdkRectangle,
    cell_area: PGdkRectangle, expose_area: PGdkRectangle, flags: guint){.cdecl,
    dynlib: gtklib, importc: "_gtk_tree_view_column_cell_render".}
proc gtk_tree_view_column_cell_focus*(tree_column: PGtkTreeViewColumn,
                                        direction: gint, left: gboolean,
                                        right: gboolean): gboolean{.cdecl,
    dynlib: gtklib, importc: "_gtk_tree_view_column_cell_focus".}
proc gtk_tree_view_column_cell_draw_focus*(tree_column: PGtkTreeViewColumn,
    window: PGdkWindow, background_area: PGdkRectangle,
    cell_area: PGdkRectangle, expose_area: PGdkRectangle, flags: guint){.cdecl,
    dynlib: gtklib, importc: "_gtk_tree_view_column_cell_draw_focus".}
proc gtk_tree_view_column_cell_set_dirty*(tree_column: PGtkTreeViewColumn,
    install_handler: gboolean){.cdecl, dynlib: gtklib, importc: "_gtk_tree_view_column_cell_set_dirty".}
proc gtk_tree_view_column_get_neighbor_sizes*(column: PGtkTreeViewColumn,
    cell: PGtkCellRenderer, left: Pgint, right: Pgint){.cdecl, dynlib: gtklib,
    importc: "_gtk_tree_view_column_get_neighbor_sizes".}
proc GTK_TYPE_TREE_VIEW*(): GType
proc GTK_TREE_VIEW*(obj: pointer): PGtkTreeView
proc GTK_TREE_VIEW_CLASS*(klass: pointer): PGtkTreeViewClass
proc GTK_IS_TREE_VIEW*(obj: pointer): bool
proc GTK_IS_TREE_VIEW_CLASS*(klass: pointer): bool
proc GTK_TREE_VIEW_GET_CLASS*(obj: pointer): PGtkTreeViewClass
proc gtk_tree_view_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_get_type".}
proc gtk_tree_view_new*(): PGtkTreeView{.cdecl, dynlib: gtklib,
                                       importc: "gtk_tree_view_new".}
proc gtk_tree_view_new_with_model*(model: PGtkTreeModel): PGtkTreeView{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_new_with_model".}
proc gtk_tree_view_get_model*(tree_view: PGtkTreeView): PGtkTreeModel{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_get_model".}
proc gtk_tree_view_set_model*(tree_view: PGtkTreeView, model: PGtkTreeModel){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_set_model".}
proc gtk_tree_view_get_selection*(tree_view: PGtkTreeView): PGtkTreeSelection{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_get_selection".}
proc gtk_tree_view_get_hadjustment*(tree_view: PGtkTreeView): PGtkAdjustment{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_get_hadjustment".}
proc gtk_tree_view_set_hadjustment*(tree_view: PGtkTreeView,
                                    adjustment: PGtkAdjustment){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_set_hadjustment".}
proc gtk_tree_view_get_vadjustment*(tree_view: PGtkTreeView): PGtkAdjustment{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_get_vadjustment".}
proc gtk_tree_view_set_vadjustment*(tree_view: PGtkTreeView,
                                    adjustment: PGtkAdjustment){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_set_vadjustment".}
proc gtk_tree_view_get_headers_visible*(tree_view: PGtkTreeView): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_get_headers_visible".}
proc gtk_tree_view_set_headers_visible*(tree_view: PGtkTreeView,
                                        headers_visible: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_set_headers_visible".}
proc gtk_tree_view_columns_autosize*(tree_view: PGtkTreeView){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_columns_autosize".}
proc gtk_tree_view_set_headers_clickable*(tree_view: PGtkTreeView,
    setting: gboolean){.cdecl, dynlib: gtklib,
                        importc: "gtk_tree_view_set_headers_clickable".}
proc gtk_tree_view_set_rules_hint*(tree_view: PGtkTreeView, setting: gboolean){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_set_rules_hint".}
proc gtk_tree_view_get_rules_hint*(tree_view: PGtkTreeView): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_get_rules_hint".}
proc gtk_tree_view_append_column*(tree_view: PGtkTreeView,
                                  column: PGtkTreeViewColumn): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_append_column".}
proc gtk_tree_view_remove_column*(tree_view: PGtkTreeView,
                                  column: PGtkTreeViewColumn): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_remove_column".}
proc gtk_tree_view_insert_column*(tree_view: PGtkTreeView,
                                  column: PGtkTreeViewColumn, position: gint): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_insert_column".}
proc gtk_tree_view_insert_column_with_data_func*(tree_view: PGtkTreeView,
    position: gint, title: cstring, cell: PGtkCellRenderer,
    fun: TGtkTreeCellDataFunc, data: gpointer, dnotify: TGDestroyNotify): gint{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_insert_column_with_data_func".}
proc gtk_tree_view_get_column*(tree_view: PGtkTreeView, n: gint): PGtkTreeViewColumn{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_get_column".}
proc gtk_tree_view_get_columns*(tree_view: PGtkTreeView): PGList{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_get_columns".}
proc gtk_tree_view_move_column_after*(tree_view: PGtkTreeView,
                                      column: PGtkTreeViewColumn,
                                      base_column: PGtkTreeViewColumn){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_move_column_after".}
proc gtk_tree_view_set_expander_column*(tree_view: PGtkTreeView,
                                        column: PGtkTreeViewColumn){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_set_expander_column".}
proc gtk_tree_view_get_expander_column*(tree_view: PGtkTreeView): PGtkTreeViewColumn{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_get_expander_column".}
proc gtk_tree_view_set_column_drag_function*(tree_view: PGtkTreeView,
    fun: TGtkTreeViewColumnDropFunc, user_data: gpointer,
    destroy: TGtkDestroyNotify){.cdecl, dynlib: gtklib, importc: "gtk_tree_view_set_column_drag_function".}
proc gtk_tree_view_scroll_to_point*(tree_view: PGtkTreeView, tree_x: gint,
                                    tree_y: gint){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_scroll_to_point".}
proc gtk_tree_view_scroll_to_cell*(tree_view: PGtkTreeView, path: PGtkTreePath,
                                   column: PGtkTreeViewColumn,
                                   use_align: gboolean, row_align: gfloat,
                                   col_align: gfloat){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_scroll_to_cell".}
proc gtk_tree_view_row_activated*(tree_view: PGtkTreeView, path: PGtkTreePath,
                                  column: PGtkTreeViewColumn){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_row_activated".}
proc gtk_tree_view_expand_all*(tree_view: PGtkTreeView){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_expand_all".}
proc gtk_tree_view_collapse_all*(tree_view: PGtkTreeView){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_collapse_all".}
proc gtk_tree_view_expand_row*(tree_view: PGtkTreeView, path: PGtkTreePath,
                               open_all: gboolean): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_expand_row".}
proc gtk_tree_view_collapse_row*(tree_view: PGtkTreeView, path: PGtkTreePath): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_collapse_row".}
proc gtk_tree_view_map_expanded_rows*(tree_view: PGtkTreeView,
                                      fun: TGtkTreeViewMappingFunc,
                                      data: gpointer){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_map_expanded_rows".}
proc gtk_tree_view_row_expanded*(tree_view: PGtkTreeView, path: PGtkTreePath): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_row_expanded".}
proc gtk_tree_view_set_reorderable*(tree_view: PGtkTreeView,
                                    reorderable: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_set_reorderable".}
proc gtk_tree_view_get_reorderable*(tree_view: PGtkTreeView): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_get_reorderable".}
proc gtk_tree_view_set_cursor*(tree_view: PGtkTreeView, path: PGtkTreePath,
                               focus_column: PGtkTreeViewColumn,
                               start_editing: gboolean){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_set_cursor".}
proc gtk_tree_view_set_cursor_on_cell*(tree_view: PGtkTreeView,
                                       path: PGtkTreePath,
                                       focus_column: PGtkTreeViewColumn,
                                       focus_cell: PGtkCellRenderer,
                                       start_editing: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_set_cursor_on_cell".}
proc gtk_tree_view_get_bin_window*(tree_view: PGtkTreeView): PGdkWindow{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_get_bin_window".}
proc gtk_tree_view_get_cell_area*(tree_view: PGtkTreeView, path: PGtkTreePath,
                                  column: PGtkTreeViewColumn,
                                  rect: PGdkRectangle){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_get_cell_area".}
proc gtk_tree_view_get_background_area*(tree_view: PGtkTreeView,
                                        path: PGtkTreePath,
                                        column: PGtkTreeViewColumn,
                                        rect: PGdkRectangle){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_get_background_area".}
proc gtk_tree_view_get_visible_rect*(tree_view: PGtkTreeView,
                                     visible_rect: PGdkRectangle){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_get_visible_rect".}
proc gtk_tree_view_widget_to_tree_coords*(tree_view: PGtkTreeView, wx: gint,
    wy: gint, tx: Pgint, ty: Pgint){.cdecl, dynlib: gtklib, importc: "gtk_tree_view_widget_to_tree_coords".}
proc gtk_tree_view_tree_to_widget_coords*(tree_view: PGtkTreeView, tx: gint,
    ty: gint, wx: Pgint, wy: Pgint){.cdecl, dynlib: gtklib, importc: "gtk_tree_view_tree_to_widget_coords".}
proc gtk_tree_view_enable_model_drag_source*(tree_view: PGtkTreeView,
    start_button_mask: TGdkModifierType, targets: PGtkTargetEntry,
    n_targets: gint, actions: TGdkDragAction){.cdecl, dynlib: gtklib,
    importc: "gtk_tree_view_enable_model_drag_source".}
proc gtk_tree_view_enable_model_drag_dest*(tree_view: PGtkTreeView,
    targets: PGtkTargetEntry, n_targets: gint, actions: TGdkDragAction){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_enable_model_drag_dest".}
proc gtk_tree_view_unset_rows_drag_source*(tree_view: PGtkTreeView){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_unset_rows_drag_source".}
proc gtk_tree_view_unset_rows_drag_dest*(tree_view: PGtkTreeView){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_unset_rows_drag_dest".}
proc gtk_tree_view_set_drag_dest_row*(tree_view: PGtkTreeView,
                                      path: PGtkTreePath,
                                      pos: TGtkTreeViewDropPosition){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_set_drag_dest_row".}
proc gtk_tree_view_create_row_drag_icon*(tree_view: PGtkTreeView,
    path: PGtkTreePath): PGdkPixmap{.cdecl, dynlib: gtklib, importc: "gtk_tree_view_create_row_drag_icon".}
proc gtk_tree_view_set_enable_search*(tree_view: PGtkTreeView,
                                      enable_search: gboolean){.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_set_enable_search".}
proc gtk_tree_view_get_enable_search*(tree_view: PGtkTreeView): gboolean{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_get_enable_search".}
proc gtk_tree_view_get_search_column*(tree_view: PGtkTreeView): gint{.cdecl,
    dynlib: gtklib, importc: "gtk_tree_view_get_search_column".}
proc gtk_tree_view_set_search_column*(tree_view: PGtkTreeView, column: gint){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_set_search_column".}
proc gtk_tree_view_get_search_equal_func*(tree_view: PGtkTreeView): TGtkTreeViewSearchEqualFunc{.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_get_search_equal_func".}
proc gtk_tree_view_set_search_equal_func*(tree_view: PGtkTreeView,
    search_equal_func: TGtkTreeViewSearchEqualFunc, search_user_data: gpointer,
    search_destroy: TGtkDestroyNotify){.cdecl, dynlib: gtklib, importc: "gtk_tree_view_set_search_equal_func".}
proc gtk_tree_view_set_destroy_count_func*(tree_view: PGtkTreeView,
    fun: TGtkTreeDestroyCountFunc, data: gpointer, destroy: TGtkDestroyNotify){.
    cdecl, dynlib: gtklib, importc: "gtk_tree_view_set_destroy_count_func".}
proc GTK_TYPE_VBUTTON_BOX*(): GType
proc GTK_VBUTTON_BOX*(obj: pointer): PGtkVButtonBox
proc GTK_VBUTTON_BOX_CLASS*(klass: pointer): PGtkVButtonBoxClass
proc GTK_IS_VBUTTON_BOX*(obj: pointer): bool
proc GTK_IS_VBUTTON_BOX_CLASS*(klass: pointer): bool
proc GTK_VBUTTON_BOX_GET_CLASS*(obj: pointer): PGtkVButtonBoxClass
proc gtk_vbutton_box_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_vbutton_box_get_type".}
proc gtk_vbutton_box_new*(): PGtkVButtonBox{.cdecl, dynlib: gtklib,
    importc: "gtk_vbutton_box_new".}
proc GTK_TYPE_VIEWPORT*(): GType
proc GTK_VIEWPORT*(obj: pointer): PGtkViewport
proc GTK_VIEWPORT_CLASS*(klass: pointer): PGtkViewportClass
proc GTK_IS_VIEWPORT*(obj: pointer): bool
proc GTK_IS_VIEWPORT_CLASS*(klass: pointer): bool
proc GTK_VIEWPORT_GET_CLASS*(obj: pointer): PGtkViewportClass
proc gtk_viewport_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_viewport_get_type".}
proc gtk_viewport_new*(hadjustment: PGtkAdjustment, vadjustment: PGtkAdjustment): PGtkViewport{.
    cdecl, dynlib: gtklib, importc: "gtk_viewport_new".}
proc gtk_viewport_get_hadjustment*(viewport: PGtkViewport): PGtkAdjustment{.
    cdecl, dynlib: gtklib, importc: "gtk_viewport_get_hadjustment".}
proc gtk_viewport_get_vadjustment*(viewport: PGtkViewport): PGtkAdjustment{.
    cdecl, dynlib: gtklib, importc: "gtk_viewport_get_vadjustment".}
proc gtk_viewport_set_hadjustment*(viewport: PGtkViewport,
                                   adjustment: PGtkAdjustment){.cdecl,
    dynlib: gtklib, importc: "gtk_viewport_set_hadjustment".}
proc gtk_viewport_set_vadjustment*(viewport: PGtkViewport,
                                   adjustment: PGtkAdjustment){.cdecl,
    dynlib: gtklib, importc: "gtk_viewport_set_vadjustment".}
proc gtk_viewport_set_shadow_type*(viewport: PGtkViewport,
                                   thetype: TGtkShadowType){.cdecl,
    dynlib: gtklib, importc: "gtk_viewport_set_shadow_type".}
proc gtk_viewport_get_shadow_type*(viewport: PGtkViewport): TGtkShadowType{.
    cdecl, dynlib: gtklib, importc: "gtk_viewport_get_shadow_type".}
proc GTK_TYPE_VPANED*(): GType
proc GTK_VPANED*(obj: pointer): PGtkVPaned
proc GTK_VPANED_CLASS*(klass: pointer): PGtkVPanedClass
proc GTK_IS_VPANED*(obj: pointer): bool
proc GTK_IS_VPANED_CLASS*(klass: pointer): bool
proc GTK_VPANED_GET_CLASS*(obj: pointer): PGtkVPanedClass
proc gtk_vpaned_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_vpaned_get_type".}
proc gtk_vpaned_new*(): PGtkVPaned{.cdecl, dynlib: gtklib,
                                    importc: "gtk_vpaned_new".}
proc GTK_TYPE_VRULER*(): GType
proc GTK_VRULER*(obj: pointer): PGtkVRuler
proc GTK_VRULER_CLASS*(klass: pointer): PGtkVRulerClass
proc GTK_IS_VRULER*(obj: pointer): bool
proc GTK_IS_VRULER_CLASS*(klass: pointer): bool
proc GTK_VRULER_GET_CLASS*(obj: pointer): PGtkVRulerClass
proc gtk_vruler_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_vruler_get_type".}
proc gtk_vruler_new*(): PGtkVRuler{.cdecl, dynlib: gtklib,
                                    importc: "gtk_vruler_new".}
proc GTK_TYPE_VSCALE*(): GType
proc GTK_VSCALE*(obj: pointer): PGtkVScale
proc GTK_VSCALE_CLASS*(klass: pointer): PGtkVScaleClass
proc GTK_IS_VSCALE*(obj: pointer): bool
proc GTK_IS_VSCALE_CLASS*(klass: pointer): bool
proc GTK_VSCALE_GET_CLASS*(obj: pointer): PGtkVScaleClass
proc gtk_vscale_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
                                       importc: "gtk_vscale_get_type".}
proc gtk_vscale_new*(adjustment: PGtkAdjustment): PGtkVScale{.cdecl,
    dynlib: gtklib, importc: "gtk_vscale_new".}
proc gtk_vscale_new_with_range*(min: gdouble, max: gdouble, step: gdouble): PGtkVScale{.
    cdecl, dynlib: gtklib, importc: "gtk_vscale_new_with_range".}
proc GTK_TYPE_VSCROLLBAR*(): GType
proc GTK_VSCROLLBAR*(obj: pointer): PGtkVScrollbar
proc GTK_VSCROLLBAR_CLASS*(klass: pointer): PGtkVScrollbarClass
proc GTK_IS_VSCROLLBAR*(obj: pointer): bool
proc GTK_IS_VSCROLLBAR_CLASS*(klass: pointer): bool
proc GTK_VSCROLLBAR_GET_CLASS*(obj: pointer): PGtkVScrollbarClass
proc gtk_vscrollbar_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_vscrollbar_get_type".}
proc gtk_vscrollbar_new*(adjustment: PGtkAdjustment): PGtkVScrollbar{.cdecl,
    dynlib: gtklib, importc: "gtk_vscrollbar_new".}
proc GTK_TYPE_VSEPARATOR*(): GType
proc GTK_VSEPARATOR*(obj: pointer): PGtkVSeparator
proc GTK_VSEPARATOR_CLASS*(klass: pointer): PGtkVSeparatorClass
proc GTK_IS_VSEPARATOR*(obj: pointer): bool
proc GTK_IS_VSEPARATOR_CLASS*(klass: pointer): bool
proc GTK_VSEPARATOR_GET_CLASS*(obj: pointer): PGtkVSeparatorClass
proc gtk_vseparator_get_type*(): TGtkType{.cdecl, dynlib: gtklib,
    importc: "gtk_vseparator_get_type".}
proc gtk_vseparator_new*(): PGtkVSeparator{.cdecl, dynlib: gtklib,
                                        importc: "gtk_vseparator_new".}
proc GTK_TYPE_OBJECT*(): GType =
  result = gtk_object_get_type()

proc GTK_CHECK_CAST*(instance: Pointer, g_type: GType): PGTypeInstance =
  result = G_TYPE_CHECK_INSTANCE_CAST(instance, g_type)

proc GTK_CHECK_CLASS_CAST*(g_class: pointer, g_type: GType): Pointer =
  result = G_TYPE_CHECK_CLASS_CAST(g_class, g_type)

proc GTK_CHECK_GET_CLASS*(instance: Pointer, g_type: GType): PGTypeClass =
  result = G_TYPE_INSTANCE_GET_CLASS(instance, g_type)

proc GTK_CHECK_TYPE*(instance: Pointer, g_type: GType): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(instance, g_type)

proc GTK_CHECK_CLASS_TYPE*(g_class: pointer, g_type: GType): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(g_class, g_type)

proc GTK_OBJECT*(anObject: pointer): PGtkObject =
  result = cast[PGtkObject](GTK_CHECK_CAST(anObject, GTK_TYPE_OBJECT()))

proc GTK_OBJECT_CLASS*(klass: pointer): PGtkObjectClass =
  result = cast[PGtkObjectClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_OBJECT()))

proc GTK_IS_OBJECT*(anObject: pointer): bool =
  result = GTK_CHECK_TYPE(anObject, GTK_TYPE_OBJECT())

proc GTK_IS_OBJECT_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_OBJECT())

proc GTK_OBJECT_GET_CLASS*(anObject: pointer): PGtkObjectClass =
  result = cast[PGtkObjectClass](GTK_CHECK_GET_CLASS(anObject, GTK_TYPE_OBJECT()))

proc GTK_OBJECT_TYPE*(anObject: pointer): GType =
  result = G_TYPE_FROM_INSTANCE(anObject)

proc GTK_OBJECT_TYPE_NAME*(anObject: pointer): cstring =
  result = g_type_name(GTK_OBJECT_TYPE(anObject))

proc GTK_OBJECT_FLAGS*(obj: pointer): guint32 =
  result = (GTK_OBJECT(obj)).flags

proc GTK_OBJECT_FLOATING*(obj: pointer): gboolean =
  result = ((GTK_OBJECT_FLAGS(obj)) and cint(GTK_FLOATING)) != 0'i32

proc GTK_OBJECT_SET_FLAGS*(obj: pointer, flag: guint32) =
  GTK_OBJECT(obj).flags = GTK_OBJECT(obj).flags or flag

proc GTK_OBJECT_UNSET_FLAGS*(obj: pointer, flag: guint32) =
  GTK_OBJECT(obj) . flags = GTK_OBJECT(obj). flags and not (flag)

proc gtk_object_data_try_key*(`string`: cstring): TGQuark =
  result = g_quark_try_string(`string`)

proc gtk_object_data_force_id*(`string`: cstring): TGQuark =
  result = g_quark_from_string(`string`)

proc GTK_CLASS_NAME*(`class`: pointer): cstring =
  result = g_type_name(G_TYPE_FROM_CLASS(`class`))

proc GTK_CLASS_TYPE*(`class`: pointer): GType =
  result = G_TYPE_FROM_CLASS(`class`)

proc GTK_TYPE_IS_OBJECT*(thetype: GType): gboolean =
  result = g_type_is_a(thetype, GTK_TYPE_OBJECT())

proc GTK_TYPE_IDENTIFIER*(): GType =
  result = gtk_identifier_get_type()

proc GTK_SIGNAL_FUNC*(f: pointer): TGtkSignalFunc =
  result = cast[TGtkSignalFunc](f)

proc gtk_type_name*(thetype: GType): cstring =
  result = g_type_name(thetype)

proc gtk_type_from_name*(name: cstring): GType =
  result = g_type_from_name(name)

proc gtk_type_parent*(thetype: GType): GType =
  result = g_type_parent(thetype)

proc gtk_type_is_a*(thetype, is_a_type: GType): gboolean =
  result = g_type_is_a(thetype, is_a_type)

proc GTK_FUNDAMENTAL_TYPE*(thetype: GType): GType =
  result = G_TYPE_FUNDAMENTAL(thetype)

proc GTK_VALUE_CHAR*(a: TGtkArg): gchar =
  var a = a
  Result = cast[ptr gchar](addr(a.d))^

proc GTK_VALUE_UCHAR*(a: TGtkArg): guchar =
  var a = a
  Result = cast[ptr guchar](addr(a.d))^

proc GTK_VALUE_BOOL*(a: TGtkArg): gboolean =
  var a = a
  Result = cast[ptr gboolean](addr(a.d))^

proc GTK_VALUE_INT*(a: TGtkArg): gint =
  var a = a
  Result = cast[ptr gint](addr(a.d))^

proc GTK_VALUE_UINT*(a: TGtkArg): guint =
  var a = a
  Result = cast[ptr guint](addr(a.d))^

proc GTK_VALUE_LONG*(a: TGtkArg): glong =
  var a = a
  Result = cast[ptr glong](addr(a.d))^

proc GTK_VALUE_ULONG*(a: TGtkArg): gulong =
  var a = a
  Result = cast[ptr gulong](addr(a.d))^

proc GTK_VALUE_FLOAT*(a: TGtkArg): gfloat =
  var a = a
  Result = cast[ptr gfloat](addr(a.d))^

proc GTK_VALUE_DOUBLE*(a: TGtkArg): gdouble =
  var a = a
  Result = cast[ptr gdouble](addr(a.d))^

proc GTK_VALUE_STRING*(a: TGtkArg): cstring =
  var a = a
  Result = cast[ptr cstring](addr(a.d))^

proc GTK_VALUE_ENUM*(a: TGtkArg): gint =
  var a = a
  Result = cast[ptr gint](addr(a.d))^

proc GTK_VALUE_FLAGS*(a: TGtkArg): guint =
  var a = a
  Result = cast[ptr guint](addr(a.d))^

proc GTK_VALUE_BOXED*(a: TGtkArg): gpointer =
  var a = a
  Result = cast[ptr gpointer](addr(a.d))^

proc GTK_VALUE_OBJECT*(a: TGtkArg): PGtkObject =
  var a = a
  Result = cast[ptr PGtkObject](addr(a.d))^

proc GTK_VALUE_POINTER*(a: TGtkArg): GPointer =
  var a = a
  Result = cast[ptr gpointer](addr(a.d))^

proc GTK_VALUE_SIGNAL*(a: TGtkArg): TGtkArgSignalData =
  var a = a
  Result = cast[ptr TGtkArgSignalData](addr(a.d))^

proc GTK_RETLOC_CHAR*(a: TGtkArg): cstring =
  var a = a
  Result = cast[ptr cstring](addr(a.d))^

proc GTK_RETLOC_UCHAR*(a: TGtkArg): Pguchar =
  var a = a
  Result = cast[ptr pguchar](addr(a.d))^

proc GTK_RETLOC_BOOL*(a: TGtkArg): Pgboolean =
  var a = a
  Result = cast[ptr pgboolean](addr(a.d))^

proc GTK_RETLOC_INT*(a: TGtkArg): Pgint =
  var a = a
  Result = cast[ptr pgint](addr(a.d))^

proc GTK_RETLOC_UINT*(a: TGtkArg): Pguint =
  var a = a
  Result = cast[ptr pguint](addr(a.d))^

proc GTK_RETLOC_LONG*(a: TGtkArg): Pglong =
  var a = a
  Result = cast[ptr pglong](addr(a.d))^

proc GTK_RETLOC_ULONG*(a: TGtkArg): Pgulong =
  var a = a
  Result = cast[ptr pgulong](addr(a.d))^

proc GTK_RETLOC_FLOAT*(a: TGtkArg): Pgfloat =
  var a = a
  Result = cast[ptr pgfloat](addr(a.d))^

proc GTK_RETLOC_DOUBLE*(a: TGtkArg): Pgdouble =
  var a = a
  Result = cast[ptr pgdouble](addr(a.d))^

proc GTK_RETLOC_STRING*(a: TGtkArg): Ppgchar =
  var a = a
  Result = cast[ptr Ppgchar](addr(a.d))^

proc GTK_RETLOC_ENUM*(a: TGtkArg): Pgint =
  var a = a
  Result = cast[ptr Pgint](addr(a.d))^

proc GTK_RETLOC_FLAGS*(a: TGtkArg): Pguint =
  var a = a
  Result = cast[ptr pguint](addr(a.d))^

proc GTK_RETLOC_BOXED*(a: TGtkArg): Pgpointer =
  var a = a
  Result = cast[ptr pgpointer](addr(a.d))^

proc GTK_RETLOC_OBJECT*(a: TGtkArg): PPGtkObject =
  var a = a
  Result = cast[ptr ppgtkobject](addr(a.d))^

proc GTK_RETLOC_POINTER*(a: TGtkArg): Pgpointer =
  var a = a
  Result = cast[ptr pgpointer](addr(a.d))^

proc GTK_TYPE_WIDGET*(): GType =
  result = gtk_widget_get_type()

proc GTK_WIDGET*(widget: pointer): PGtkWidget =
  result = cast[PGtkWidget](GTK_CHECK_CAST(widget, GTK_TYPE_WIDGET()))

proc GTK_WIDGET_CLASS*(klass: pointer): PGtkWidgetClass =
  result = cast[PGtkWidgetClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_WIDGET()))

proc GTK_IS_WIDGET*(widget: pointer): bool =
  result = GTK_CHECK_TYPE(widget, GTK_TYPE_WIDGET())

proc GTK_IS_WIDGET_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_WIDGET())

proc GTK_WIDGET_GET_CLASS*(obj: pointer): PGtkWidgetClass =
  result = cast[PGtkWidgetClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_WIDGET()))

proc GTK_WIDGET_TYPE*(wid: pointer): GType =
  result = GTK_OBJECT_TYPE(wid)

proc GTK_WIDGET_STATE*(wid: pointer): int32 =
  result = (GTK_WIDGET(wid)) . state

proc GTK_WIDGET_SAVED_STATE*(wid: pointer): int32 =
  result = (GTK_WIDGET(wid)) . saved_state

proc GTK_WIDGET_FLAGS*(wid: pointer): guint32 =
  result = GTK_OBJECT_FLAGS(wid)

proc GTK_WIDGET_TOPLEVEL*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_TOPLEVEL)) != 0'i32

proc GTK_WIDGET_NO_WINDOW*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_NO_WINDOW)) != 0'i32

proc GTK_WIDGET_REALIZED*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_REALIZED)) != 0'i32

proc GTK_WIDGET_MAPPED*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_MAPPED)) != 0'i32

proc GTK_WIDGET_VISIBLE*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_VISIBLE)) != 0'i32

proc GTK_WIDGET_DRAWABLE*(wid: pointer): gboolean =
  result = (GTK_WIDGET_VISIBLE(wid)) and (GTK_WIDGET_MAPPED(wid))

proc GTK_WIDGET_SENSITIVE*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_SENSITIVE)) != 0'i32

proc GTK_WIDGET_PARENT_SENSITIVE*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_PARENT_SENSITIVE)) != 0'i32

proc GTK_WIDGET_IS_SENSITIVE*(wid: pointer): gboolean =
  result = (GTK_WIDGET_SENSITIVE(wid)) and (GTK_WIDGET_PARENT_SENSITIVE(wid))

proc GTK_WIDGET_CAN_FOCUS*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_CAN_FOCUS)) != 0'i32

proc GTK_WIDGET_HAS_FOCUS*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_HAS_FOCUS)) != 0'i32

proc GTK_WIDGET_CAN_DEFAULT*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_CAN_DEFAULT)) != 0'i32

proc GTK_WIDGET_HAS_DEFAULT*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_HAS_DEFAULT)) != 0'i32

proc GTK_WIDGET_HAS_GRAB*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_HAS_GRAB)) != 0'i32

proc GTK_WIDGET_RC_STYLE*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_RC_STYLE)) != 0'i32

proc GTK_WIDGET_COMPOSITE_CHILD*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_COMPOSITE_CHILD)) != 0'i32

proc GTK_WIDGET_APP_PAINTABLE*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_APP_PAINTABLE)) != 0'i32

proc GTK_WIDGET_RECEIVES_DEFAULT*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_RECEIVES_DEFAULT)) != 0'i32

proc GTK_WIDGET_DOUBLE_BUFFERED*(wid: pointer): gboolean =
  result = ((GTK_WIDGET_FLAGS(wid)) and cint(GTK_DOUBLE_BUFFERED)) != 0'i32

proc GTK_TYPE_REQUISITION*(): GType =
  result = gtk_requisition_get_type()

proc x_set*(a: var TGtkWidgetAuxInfo): guint =
  result = (a.flag0 and bm_TGtkWidgetAuxInfo_x_set) shr
      bp_TGtkWidgetAuxInfo_x_set

proc set_x_set*(a: var TGtkWidgetAuxInfo, `x_set`: guint) =
  a.flag0 = a.flag0 or
      (int16(`x_set` shl bp_TGtkWidgetAuxInfo_x_set) and
      bm_TGtkWidgetAuxInfo_x_set)

proc y_set*(a: var TGtkWidgetAuxInfo): guint =
  result = (a.flag0 and bm_TGtkWidgetAuxInfo_y_set) shr
      bp_TGtkWidgetAuxInfo_y_set

proc set_y_set*(a: var TGtkWidgetAuxInfo, `y_set`: guint) =
  a.flag0 = a.flag0 or
      (int16(`y_set` shl bp_TGtkWidgetAuxInfo_y_set) and
      bm_TGtkWidgetAuxInfo_y_set)

proc gtk_widget_set_visual*(widget, visual: pointer) =
  if (Widget != nil) and (visual != nil): nil

proc gtk_widget_push_visual*(visual: pointer) =
  if (visual != nil): nil

proc gtk_widget_pop_visual*() =
  nil

proc gtk_widget_set_default_visual*(visual: pointer) =
  if (visual != nil): nil

proc gtk_widget_set_rc_style*(widget: pointer) =
  gtk_widget_set_style(cast[PGtkWidget](widget), nil)

proc gtk_widget_restore_default_style*(widget: pointer) =
  gtk_widget_set_style(cast[PGtkWidget](widget), nil)

proc GTK_WIDGET_SET_FLAGS*(wid: PGtkWidget, flags: TGtkWidgetFlags): TGtkWidgetFlags =
  cast[pGtkObject](wid).flags = cast[pGtkObject](wid).flags or (flags)
  result = cast[pGtkObject](wid).flags

proc GTK_WIDGET_UNSET_FLAGS*(wid: PGtkWidget, flags: TGtkWidgetFlags): TGtkWidgetFlags =
  cast[pGtkObject](wid).flags = cast[pGtkObject](wid).flags and (not (flags))
  result = cast[pGtkObject](wid).flags

proc GTK_TYPE_MISC*(): GType =
  result = gtk_misc_get_type()

proc GTK_MISC*(obj: pointer): PGtkMisc =
  result = cast[PGtkMisc](GTK_CHECK_CAST(obj, GTK_TYPE_MISC()))

proc GTK_MISC_CLASS*(klass: pointer): PGtkMiscClass =
  result = cast[PGtkMiscClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_MISC()))

proc GTK_IS_MISC*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_MISC())

proc GTK_IS_MISC_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_MISC())

proc GTK_MISC_GET_CLASS*(obj: pointer): PGtkMiscClass =
  result = cast[PGtkMiscClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_MISC()))

proc GTK_TYPE_ACCEL_GROUP*(): GType =
  result = gtk_accel_group_get_type()

proc GTK_ACCEL_GROUP*(anObject: pointer): PGtkAccelGroup =
  result = cast[PGtkAccelGroup](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      GTK_TYPE_ACCEL_GROUP()))

proc GTK_ACCEL_GROUP_CLASS*(klass: pointer): PGtkAccelGroupClass =
  result = cast[PGtkAccelGroupClass](G_TYPE_CHECK_CLASS_CAST(klass,
      GTK_TYPE_ACCEL_GROUP()))

proc GTK_IS_ACCEL_GROUP*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GTK_TYPE_ACCEL_GROUP())

proc GTK_IS_ACCEL_GROUP_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GTK_TYPE_ACCEL_GROUP())

proc GTK_ACCEL_GROUP_GET_CLASS*(obj: pointer): PGtkAccelGroupClass =
  result = cast[PGtkAccelGroupClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      GTK_TYPE_ACCEL_GROUP()))

proc accel_flags*(a: var TGtkAccelKey): guint =
  result = (a.flag0 and bm_TGtkAccelKey_accel_flags) shr
      bp_TGtkAccelKey_accel_flags

proc set_accel_flags*(a: var TGtkAccelKey, `accel_flags`: guint) =
  a.flag0 = a.flag0 or
      (int16(`accel_flags` shl bp_TGtkAccelKey_accel_flags) and
      bm_TGtkAccelKey_accel_flags)

proc gtk_accel_group_ref*(AccelGroup: PGtkAccelGroup) =
  discard g_object_ref(AccelGroup)

proc gtk_accel_group_unref*(AccelGroup: PGtkAccelGroup) =
  g_object_unref(AccelGroup)

proc GTK_TYPE_CONTAINER*(): GType =
  result = gtk_container_get_type()

proc GTK_CONTAINER*(obj: pointer): PGtkContainer =
  result = cast[PGtkContainer](GTK_CHECK_CAST(obj, GTK_TYPE_CONTAINER()))

proc GTK_CONTAINER_CLASS*(klass: pointer): PGtkContainerClass =
  result = cast[PGtkContainerClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_CONTAINER()))

proc GTK_IS_CONTAINER*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_CONTAINER())

proc GTK_IS_CONTAINER_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_CONTAINER())

proc GTK_CONTAINER_GET_CLASS*(obj: pointer): PGtkContainerClass =
  result = cast[PGtkContainerClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_CONTAINER()))

proc GTK_IS_RESIZE_CONTAINER*(widget: pointer): bool =
  result = (GTK_IS_CONTAINER(widget)) and
      ((resize_mode(cast[PGtkContainer](widget))) != cint(GTK_RESIZE_PARENT))

proc border_width*(a: var TGtkContainer): guint =
  result = (a.GtkContainer_flag0 and bm_TGtkContainer_border_width) shr
      bp_TGtkContainer_border_width

proc set_border_width*(a: var TGtkContainer, `border_width`: guint) =
  a.GtkContainer_flag0 = a.GtkContainer_flag0 or
      ((`border_width` shl bp_TGtkContainer_border_width) and
      bm_TGtkContainer_border_width)

proc need_resize*(a: var TGtkContainer): guint =
  result = (a.GtkContainer_flag0 and bm_TGtkContainer_need_resize) shr
      bp_TGtkContainer_need_resize

proc set_need_resize*(a: var TGtkContainer, `need_resize`: guint) =
  a.GtkContainer_flag0 = a.GtkContainer_flag0 or
      ((`need_resize` shl bp_TGtkContainer_need_resize) and
      bm_TGtkContainer_need_resize)

proc resize_mode*(a: PGtkContainer): guint =
  result = (a.GtkContainer_flag0 and bm_TGtkContainer_resize_mode) shr
      bp_TGtkContainer_resize_mode

proc set_resize_mode*(a: var TGtkContainer, `resize_mode`: guint) =
  a.GtkContainerflag0 = a.GtkContainerflag0 or
      ((`resize_mode` shl bp_TGtkContainer_resize_mode) and
      bm_TGtkContainer_resize_mode)

proc reallocate_redraws*(a: var TGtkContainer): guint =
  result = (a.GtkContainerflag0 and bm_TGtkContainer_reallocate_redraws) shr
      bp_TGtkContainer_reallocate_redraws

proc set_reallocate_redraws*(a: var TGtkContainer, `reallocate_redraws`: guint) =
  a.GtkContainerflag0 = a.GtkContainerflag0 or
      ((`reallocate_redraws` shl bp_TGtkContainer_reallocate_redraws) and
      bm_TGtkContainer_reallocate_redraws)

proc has_focus_chain*(a: var TGtkContainer): guint =
  result = (a.GtkContainerflag0 and bm_TGtkContainer_has_focus_chain) shr
      bp_TGtkContainer_has_focus_chain

proc set_has_focus_chain*(a: var TGtkContainer, `has_focus_chain`: guint) =
  a.GtkContainerflag0 = a.GtkContainerflag0 or
      ((`has_focus_chain` shl bp_TGtkContainer_has_focus_chain) and
      bm_TGtkContainer_has_focus_chain)

proc GTK_CONTAINER_WARN_INVALID_CHILD_PROPERTY_ID*(anObject: pointer,
    property_id: guint, pspec: pointer) =
  write(stdout, "WARNING: invalid child property id\n")

proc GTK_TYPE_BIN*(): GType =
  result = gtk_bin_get_type()

proc GTK_BIN*(obj: pointer): PGtkBin =
  result = cast[PGtkBin](GTK_CHECK_CAST(obj, GTK_TYPE_BIN()))

proc GTK_BIN_CLASS*(klass: pointer): PGtkBinClass =
  result = cast[PGtkBinClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_BIN()))

proc GTK_IS_BIN*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_BIN())

proc GTK_IS_BIN_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_BIN())

proc GTK_BIN_GET_CLASS*(obj: pointer): PGtkBinClass =
  result = cast[PGtkBinClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_BIN()))

proc GTK_TYPE_WINDOW*(): GType =
  result = gtk_window_get_type()

proc GTK_WINDOW*(obj: pointer): PGtkWindow =
  result = cast[PGtkWindow](GTK_CHECK_CAST(obj, GTK_TYPE_WINDOW()))

proc GTK_WINDOW_CLASS*(klass: pointer): PGtkWindowClass =
  result = cast[PGtkWindowClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_WINDOW()))

proc GTK_IS_WINDOW*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_WINDOW())

proc GTK_IS_WINDOW_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_WINDOW())

proc GTK_WINDOW_GET_CLASS*(obj: pointer): PGtkWindowClass =
  result = cast[PGtkWindowClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_WINDOW()))

proc allow_shrink*(a: var TGtkWindow): guint =
  result = (a.GtkWindow_flag0 and bm_TGtkWindow_allow_shrink) shr
      bp_TGtkWindow_allow_shrink

proc set_allow_shrink*(a: var TGtkWindow, `allow_shrink`: guint) =
  a.GtkWindow_flag0 = a.GtkWindow_flag0 or
      ((`allow_shrink` shl bp_TGtkWindow_allow_shrink) and
      bm_TGtkWindow_allow_shrink)

proc allow_grow*(a: var TGtkWindow): guint =
  result = (a.GtkWindow_flag0 and bm_TGtkWindow_allow_grow) shr
      bp_TGtkWindow_allow_grow

proc set_allow_grow*(a: var TGtkWindow, `allow_grow`: guint) =
  a.GtkWindow_flag0 = a.GtkWindow_flag0 or
      ((`allow_grow` shl bp_TGtkWindow_allow_grow) and
      bm_TGtkWindow_allow_grow)

proc configure_notify_received*(a: var TGtkWindow): guint =
  result = (a.GtkWindow_flag0 and bm_TGtkWindow_configure_notify_received) shr
      bp_TGtkWindow_configure_notify_received

proc set_configure_notify_received*(a: var TGtkWindow,
                                    `configure_notify_received`: guint) =
  a.GtkWindow_flag0 = a.GtkWindow_flag0 or
      ((`configure_notify_received` shl
      bp_TGtkWindow_configure_notify_received) and
      bm_TGtkWindow_configure_notify_received)

proc need_default_position*(a: var TGtkWindow): guint =
  result = (a.GtkWindow_flag0 and bm_TGtkWindow_need_default_position) shr
      bp_TGtkWindow_need_default_position

proc set_need_default_position*(a: var TGtkWindow,
                                `need_default_position`: guint) =
  a.GtkWindow_flag0 = a.GtkWindow_flag0 or
      ((`need_default_position` shl bp_TGtkWindow_need_default_position) and
      bm_TGtkWindow_need_default_position)

proc need_default_size*(a: var TGtkWindow): guint =
  result = (a.GtkWindow_flag0 and bm_TGtkWindow_need_default_size) shr
      bp_TGtkWindow_need_default_size

proc set_need_default_size*(a: var TGtkWindow, `need_default_size`: guint) =
  a.GtkWindow_flag0 = a.GtkWindow_flag0 or
      ((`need_default_size` shl bp_TGtkWindow_need_default_size) and
      bm_TGtkWindow_need_default_size)

proc position*(a: var TGtkWindow): guint =
  result = (a.GtkWindow_flag0 and bm_TGtkWindow_position) shr bp_TGtkWindow_position

proc set_position*(a: var TGtkWindow, `position`: guint) =
  a.GtkWindow_flag0 = a.GtkWindow_flag0 or
      ((`position` shl bp_TGtkWindow_position) and bm_TGtkWindow_position)

proc get_type*(a: var TGtkWindow): guint =
  result = (a.GtkWindow_flag0 and bm_TGtkWindow_type) shr bp_TGtkWindow_type

proc set_type*(a: var TGtkWindow, `type`: guint) =
  a.GtkWindow_flag0 = a.GtkWindow_flag0 or
      ((`type` shl bp_TGtkWindow_type) and bm_TGtkWindow_type)

proc has_user_ref_count*(a: var TGtkWindow): guint =
  result = (a.GtkWindow_flag0 and bm_TGtkWindow_has_user_ref_count) shr
      bp_TGtkWindow_has_user_ref_count

proc set_has_user_ref_count*(a: var TGtkWindow, `has_user_ref_count`: guint) =
  a.GtkWindow_flag0 = a.GtkWindow_flag0 or
      ((`has_user_ref_count` shl bp_TGtkWindow_has_user_ref_count) and
      bm_TGtkWindow_has_user_ref_count)

proc has_focus*(a: var TGtkWindow): guint =
  result = (a.GtkWindow_flag0 and bm_TGtkWindow_has_focus) shr bp_TGtkWindow_has_focus

proc set_has_focus*(a: var TGtkWindow, `has_focus`: guint) =
  a.GtkWindow_flag0 = a.GtkWindow_flag0 or
      ((`has_focus` shl bp_TGtkWindow_has_focus) and bm_TGtkWindow_has_focus)

proc modal*(a: var TGtkWindow): guint =
  result = (a.GtkWindow_flag0 and bm_TGtkWindow_modal) shr bp_TGtkWindow_modal

proc set_modal*(a: var TGtkWindow, `modal`: guint) =
  a.GtkWindow_flag0 = a.GtkWindow_flag0 or
      ((`modal` shl bp_TGtkWindow_modal) and bm_TGtkWindow_modal)

proc destroy_with_parent*(a: var TGtkWindow): guint =
  result = (a.GtkWindow_flag0 and bm_TGtkWindow_destroy_with_parent) shr
      bp_TGtkWindow_destroy_with_parent

proc set_destroy_with_parent*(a: var TGtkWindow, `destroy_with_parent`: guint) =
  a.GtkWindowflag0 = a.GtkWindowflag0 or
      ((`destroy_with_parent` shl bp_TGtkWindow_destroy_with_parent) and
      bm_TGtkWindow_destroy_with_parent)

proc has_frame*(a: var TGtkWindow): guint =
  result = (a.GtkWindowflag0 and bm_TGtkWindow_has_frame) shr bp_TGtkWindow_has_frame

proc set_has_frame*(a: var TGtkWindow, `has_frame`: guint) =
  a.GtkWindowflag0 = a.GtkWindowflag0 or
      ((`has_frame` shl bp_TGtkWindow_has_frame) and bm_TGtkWindow_has_frame)

proc iconify_initially*(a: var TGtkWindow): guint =
  result = (a.GtkWindowflag0 and bm_TGtkWindow_iconify_initially) shr
      bp_TGtkWindow_iconify_initially

proc set_iconify_initially*(a: var TGtkWindow, `iconify_initially`: guint) =
  a.GtkWindowflag0 = a.GtkWindowflag0 or
      ((`iconify_initially` shl bp_TGtkWindow_iconify_initially) and
      bm_TGtkWindow_iconify_initially)

proc stick_initially*(a: var TGtkWindow): guint =
  result = (a.GtkWindowflag0 and bm_TGtkWindow_stick_initially) shr
      bp_TGtkWindow_stick_initially

proc set_stick_initially*(a: var TGtkWindow, `stick_initially`: guint) =
  a.GtkWindowflag0 = a.GtkWindowflag0 or
      ((`stick_initially` shl bp_TGtkWindow_stick_initially) and
      bm_TGtkWindow_stick_initially)

proc maximize_initially*(a: var TGtkWindow): guint =
  result = (a.GtkWindowflag0 and bm_TGtkWindow_maximize_initially) shr
      bp_TGtkWindow_maximize_initially

proc set_maximize_initially*(a: var TGtkWindow, `maximize_initially`: guint) =
  a.GtkWindowflag0 = a.GtkWindowflag0 or
      ((`maximize_initially` shl bp_TGtkWindow_maximize_initially) and
      bm_TGtkWindow_maximize_initially)

proc decorated*(a: var TGtkWindow): guint =
  result = (a.GtkWindowflag0 and bm_TGtkWindow_decorated) shr bp_TGtkWindow_decorated

proc set_decorated*(a: var TGtkWindow, `decorated`: guint) =
  a.GtkWindowflag0 = a.GtkWindowflag0 or
      ((`decorated` shl bp_TGtkWindow_decorated) and bm_TGtkWindow_decorated)

proc type_hint*(a: var TGtkWindow): guint =
  result = (a.GtkWindowflag0 and bm_TGtkWindow_type_hint) shr bp_TGtkWindow_type_hint

proc set_type_hint*(a: var TGtkWindow, `type_hint`: guint) =
  a.GtkWindowflag0 = a.GtkWindowflag0 or
      ((`type_hint` shl bp_TGtkWindow_type_hint) and bm_TGtkWindow_type_hint)

proc gravity*(a: var TGtkWindow): guint =
  result = (a.GtkWindowflag0 and bm_TGtkWindow_gravity) shr bp_TGtkWindow_gravity

proc set_gravity*(a: var TGtkWindow, `gravity`: guint) =
  a.GtkWindowflag0 = a.GtkWindowflag0 or
      ((`gravity` shl bp_TGtkWindow_gravity) and bm_TGtkWindow_gravity)

proc GTK_TYPE_WINDOW_GROUP*(): GType =
  result = gtk_window_group_get_type()

proc GTK_WINDOW_GROUP*(anObject: pointer): PGtkWindowGroup =
  result = cast[PGtkWindowGroup](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      GTK_TYPE_WINDOW_GROUP()))

proc GTK_WINDOW_GROUP_CLASS*(klass: pointer): PGtkWindowGroupClass =
  result = cast[PGtkWindowGroupClass](G_TYPE_CHECK_CLASS_CAST(klass,
      GTK_TYPE_WINDOW_GROUP()))

proc GTK_IS_WINDOW_GROUP*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GTK_TYPE_WINDOW_GROUP())

proc GTK_IS_WINDOW_GROUP_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GTK_TYPE_WINDOW_GROUP())

proc GTK_WINDOW_GROUP_GET_CLASS*(obj: pointer): PGtkWindowGroupClass =
  result = cast[PGtkWindowGroupClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      GTK_TYPE_WINDOW_GROUP()))

proc gtk_window_position*(window: PGtkWindow, position: TGtkWindowPosition) =
  gtk_window_set_position(window, position)

proc GTK_TYPE_LABEL*(): GType =
  result = gtk_label_get_type()

proc GTK_LABEL*(obj: pointer): PGtkLabel =
  result = cast[PGtkLabel](GTK_CHECK_CAST(obj, GTK_TYPE_LABEL()))

proc GTK_LABEL_CLASS*(klass: pointer): PGtkLabelClass =
  result = cast[PGtkLabelClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_LABEL()))

proc GTK_IS_LABEL*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_LABEL())

proc GTK_IS_LABEL_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_LABEL())

proc GTK_LABEL_GET_CLASS*(obj: pointer): PGtkLabelClass =
  result = cast[PGtkLabelClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_LABEL()))

proc jtype*(a: var TGtkLabel): guint =
  result = (a.GtkLabelflag0 and bm_TGtkLabel_jtype) shr bp_TGtkLabel_jtype

proc set_jtype*(a: var TGtkLabel, `jtype`: guint) =
  a.GtkLabelflag0 = a.GtkLabelflag0 or
      (int16(`jtype` shl bp_TGtkLabel_jtype) and bm_TGtkLabel_jtype)

proc wrap*(a: var TGtkLabel): guint =
  result = (a.GtkLabelflag0 and bm_TGtkLabel_wrap) shr bp_TGtkLabel_wrap

proc set_wrap*(a: var TGtkLabel, `wrap`: guint) =
  a.GtkLabelflag0 = a.GtkLabelflag0 or (int16(`wrap` shl bp_TGtkLabel_wrap) and bm_TGtkLabel_wrap)

proc use_underline*(a: var TGtkLabel): guint =
  result = (a.GtkLabelflag0 and bm_TGtkLabel_use_underline) shr
      bp_TGtkLabel_use_underline

proc set_use_underline*(a: var TGtkLabel, `use_underline`: guint) =
  a.GtkLabelflag0 = a.GtkLabelflag0 or
      (int16(`use_underline` shl bp_TGtkLabel_use_underline) and
      bm_TGtkLabel_use_underline)

proc use_markup*(a: var TGtkLabel): guint =
  result = (a.GtkLabelflag0 and bm_TGtkLabel_use_markup) shr bp_TGtkLabel_use_markup

proc set_use_markup*(a: var TGtkLabel, `use_markup`: guint) =
  a.GtkLabelflag0 = a.GtkLabelflag0 or
      (int16(`use_markup` shl bp_TGtkLabel_use_markup) and bm_TGtkLabel_use_markup)

proc GTK_TYPE_ACCEL_LABEL*(): GType =
  result = gtk_accel_label_get_type()

proc GTK_ACCEL_LABEL*(obj: pointer): PGtkAccelLabel =
  result = cast[PGtkAccelLabel](GTK_CHECK_CAST(obj, GTK_TYPE_ACCEL_LABEL()))

proc GTK_ACCEL_LABEL_CLASS*(klass: pointer): PGtkAccelLabelClass =
  result = cast[PGtkAccelLabelClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_ACCEL_LABEL()))

proc GTK_IS_ACCEL_LABEL*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_ACCEL_LABEL())

proc GTK_IS_ACCEL_LABEL_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_ACCEL_LABEL())

proc GTK_ACCEL_LABEL_GET_CLASS*(obj: pointer): PGtkAccelLabelClass =
  result = cast[PGtkAccelLabelClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_ACCEL_LABEL()))

proc latin1_to_char*(a: var TGtkAccelLabelClass): guint =
  result = (a.GtkAccelLabelClassflag0 and bm_TGtkAccelLabelClass_latin1_to_char) shr
      bp_TGtkAccelLabelClass_latin1_to_char

proc set_latin1_to_char*(a: var TGtkAccelLabelClass, `latin1_to_char`: guint) =
  a.GtkAccelLabelClassflag0 = a.GtkAccelLabelClassflag0 or
      (int16(`latin1_to_char` shl bp_TGtkAccelLabelClass_latin1_to_char) and
      bm_TGtkAccelLabelClass_latin1_to_char)

proc gtk_accel_label_accelerator_width*(accel_label: PGtkAccelLabel): guint =
  result = gtk_accel_label_get_accel_width(accel_label)

proc GTK_TYPE_ACCESSIBLE*(): GType =
  result = gtk_accessible_get_type()

proc GTK_ACCESSIBLE*(obj: pointer): PGtkAccessible =
  result = cast[PGtkAccessible](GTK_CHECK_CAST(obj, GTK_TYPE_ACCESSIBLE()))

proc GTK_ACCESSIBLE_CLASS*(klass: pointer): PGtkAccessibleClass =
  result = cast[PGtkAccessibleClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_ACCESSIBLE()))

proc GTK_IS_ACCESSIBLE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_ACCESSIBLE())

proc GTK_IS_ACCESSIBLE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_ACCESSIBLE())

proc GTK_ACCESSIBLE_GET_CLASS*(obj: pointer): PGtkAccessibleClass =
  result = cast[PGtkAccessibleClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_ACCESSIBLE()))

proc GTK_TYPE_ADJUSTMENT*(): GType =
  result = gtk_adjustment_get_type()

proc GTK_ADJUSTMENT*(obj: pointer): PGtkAdjustment =
  result = cast[PGtkAdjustment](GTK_CHECK_CAST(obj, GTK_TYPE_ADJUSTMENT()))

proc GTK_ADJUSTMENT_CLASS*(klass: pointer): PGtkAdjustmentClass =
  result = cast[PGtkAdjustmentClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_ADJUSTMENT()))

proc GTK_IS_ADJUSTMENT*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_ADJUSTMENT())

proc GTK_IS_ADJUSTMENT_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_ADJUSTMENT())

proc GTK_ADJUSTMENT_GET_CLASS*(obj: pointer): PGtkAdjustmentClass =
  result = cast[PGtkAdjustmentClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_ADJUSTMENT()))

proc GTK_TYPE_ALIGNMENT*(): GType =
  result = gtk_alignment_get_type()

proc GTK_ALIGNMENT*(obj: pointer): PGtkAlignment =
  result = cast[PGtkAlignment](GTK_CHECK_CAST(obj, GTK_TYPE_ALIGNMENT()))

proc GTK_ALIGNMENT_CLASS*(klass: pointer): PGtkAlignmentClass =
  result = cast[PGtkAlignmentClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_ALIGNMENT()))

proc GTK_IS_ALIGNMENT*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_ALIGNMENT())

proc GTK_IS_ALIGNMENT_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_ALIGNMENT())

proc GTK_ALIGNMENT_GET_CLASS*(obj: pointer): PGtkAlignmentClass =
  result = cast[PGtkAlignmentClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_ALIGNMENT()))

proc GTK_TYPE_FRAME*(): GType =
  result = gtk_frame_get_type()

proc GTK_FRAME*(obj: pointer): PGtkFrame =
  result = cast[PGtkFrame](GTK_CHECK_CAST(obj, GTK_TYPE_FRAME()))

proc GTK_FRAME_CLASS*(klass: pointer): PGtkFrameClass =
  result = cast[PGtkFrameClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_FRAME()))

proc GTK_IS_FRAME*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_FRAME())

proc GTK_IS_FRAME_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_FRAME())

proc GTK_FRAME_GET_CLASS*(obj: pointer): PGtkFrameClass =
  result = cast[PGtkFrameClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_FRAME()))

proc GTK_TYPE_ASPECT_FRAME*(): GType =
  result = gtk_aspect_frame_get_type()

proc GTK_ASPECT_FRAME*(obj: pointer): PGtkAspectFrame =
  result = cast[PGtkAspectFrame](GTK_CHECK_CAST(obj, GTK_TYPE_ASPECT_FRAME()))

proc GTK_ASPECT_FRAME_CLASS*(klass: pointer): PGtkAspectFrameClass =
  result = cast[PGtkAspectFrameClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_ASPECT_FRAME()))

proc GTK_IS_ASPECT_FRAME*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_ASPECT_FRAME())

proc GTK_IS_ASPECT_FRAME_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_ASPECT_FRAME())

proc GTK_ASPECT_FRAME_GET_CLASS*(obj: pointer): PGtkAspectFrameClass =
  result = cast[PGtkAspectFrameClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_ASPECT_FRAME()))

proc GTK_TYPE_ARROW*(): GType =
  result = gtk_arrow_get_type()

proc GTK_ARROW*(obj: pointer): PGtkArrow =
  result = cast[PGtkArrow](GTK_CHECK_CAST(obj, GTK_TYPE_ARROW()))

proc GTK_ARROW_CLASS*(klass: pointer): PGtkArrowClass =
  result = cast[PGtkArrowClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_ARROW()))

proc GTK_IS_ARROW*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_ARROW())

proc GTK_IS_ARROW_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_ARROW())

proc GTK_ARROW_GET_CLASS*(obj: pointer): PGtkArrowClass =
  result = cast[PGtkArrowClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_ARROW()))

proc parsed*(a: var TGtkBindingSet): guint =
  result = (a.flag0 and bm_TGtkBindingSet_parsed) shr
      bp_TGtkBindingSet_parsed

proc set_parsed*(a: var TGtkBindingSet, `parsed`: guint) =
  a.flag0 = a.flag0 or
      (int16(`parsed` shl bp_TGtkBindingSet_parsed) and bm_TGtkBindingSet_parsed)

proc destroyed*(a: var TGtkBindingEntry): guint =
  result = (a.flag0 and bm_TGtkBindingEntry_destroyed) shr
      bp_TGtkBindingEntry_destroyed

proc set_destroyed*(a: var TGtkBindingEntry, `destroyed`: guint) =
  a.flag0 = a.flag0 or
      (int16(`destroyed` shl bp_TGtkBindingEntry_destroyed) and
      bm_TGtkBindingEntry_destroyed)

proc in_emission*(a: var TGtkBindingEntry): guint =
  result = (a.flag0 and bm_TGtkBindingEntry_in_emission) shr
      bp_TGtkBindingEntry_in_emission

proc set_in_emission*(a: var TGtkBindingEntry, `in_emission`: guint) =
  a.flag0 = a.flag0 or
      (int16(`in_emission` shl bp_TGtkBindingEntry_in_emission) and
      bm_TGtkBindingEntry_in_emission)

proc gtk_binding_entry_add*(binding_set: PGtkBindingSet, keyval: guint,
                            modifiers: TGdkModifierType) =
  gtk_binding_entry_clear(binding_set, keyval, modifiers)

proc GTK_TYPE_BOX*(): GType =
  result = gtk_box_get_type()

proc GTK_BOX*(obj: pointer): PGtkBox =
  result = cast[PGtkBox](GTK_CHECK_CAST(obj, GTK_TYPE_BOX()))

proc GTK_BOX_CLASS*(klass: pointer): PGtkBoxClass =
  result = cast[PGtkBoxClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_BOX()))

proc GTK_IS_BOX*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_BOX())

proc GTK_IS_BOX_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_BOX())

proc GTK_BOX_GET_CLASS*(obj: pointer): PGtkBoxClass =
  result = cast[PGtkBoxClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_BOX()))

proc homogeneous*(a: var TGtkBox): guint =
  result = (a.GtkBoxflag0 and bm_TGtkBox_homogeneous) shr bp_TGtkBox_homogeneous

proc set_homogeneous*(a: var TGtkBox, `homogeneous`: guint) =
  a.GtkBoxflag0 = a.GtkBoxflag0 or
      (int16(`homogeneous` shl bp_TGtkBox_homogeneous) and bm_TGtkBox_homogeneous)

proc expand*(a: var TGtkBoxChild): guint =
  result = (a.flag0 and bm_TGtkBoxChild_expand) shr bp_TGtkBoxChild_expand

proc set_expand*(a: var TGtkBoxChild, `expand`: guint) =
  a.flag0 = a.flag0 or
      (int16(`expand` shl bp_TGtkBoxChild_expand) and bm_TGtkBoxChild_expand)

proc fill*(a: var TGtkBoxChild): guint =
  result = (a.flag0 and bm_TGtkBoxChild_fill) shr bp_TGtkBoxChild_fill

proc set_fill*(a: var TGtkBoxChild, `fill`: guint) =
  a.flag0 = a.flag0 or
      (int16(`fill` shl bp_TGtkBoxChild_fill) and bm_TGtkBoxChild_fill)

proc pack*(a: var TGtkBoxChild): guint =
  result = (a.flag0 and bm_TGtkBoxChild_pack) shr bp_TGtkBoxChild_pack

proc set_pack*(a: var TGtkBoxChild, `pack`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pack` shl bp_TGtkBoxChild_pack) and bm_TGtkBoxChild_pack)

proc is_secondary*(a: var TGtkBoxChild): guint =
  result = (a.flag0 and bm_TGtkBoxChild_is_secondary) shr
      bp_TGtkBoxChild_is_secondary

proc set_is_secondary*(a: var TGtkBoxChild, `is_secondary`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_secondary` shl bp_TGtkBoxChild_is_secondary) and
      bm_TGtkBoxChild_is_secondary)

proc GTK_TYPE_BUTTON_BOX*(): GType =
  result = gtk_button_box_get_type()

proc GTK_BUTTON_BOX*(obj: pointer): PGtkButtonBox =
  result = cast[PGtkButtonBox](GTK_CHECK_CAST(obj, GTK_TYPE_BUTTON_BOX()))

proc GTK_BUTTON_BOX_CLASS*(klass: pointer): PGtkButtonBoxClass =
  result = cast[PGtkButtonBoxClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_BUTTON_BOX()))

proc GTK_IS_BUTTON_BOX*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_BUTTON_BOX())

proc GTK_IS_BUTTON_BOX_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_BUTTON_BOX())

proc GTK_BUTTON_BOX_GET_CLASS*(obj: pointer): PGtkButtonBoxClass =
  result = cast[PGtkButtonBoxClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_BUTTON_BOX()))

proc gtk_button_box_set_spacing*(b: pointer, s: gint) =
  gtk_box_set_spacing(GTK_BOX(b), s)

proc gtk_button_box_get_spacing*(b: pointer): gint =
  result = gtk_box_get_spacing(GTK_BOX(b))

proc GTK_TYPE_BUTTON*(): GType =
  result = gtk_button_get_type()

proc GTK_BUTTON*(obj: pointer): PGtkButton =
  result = cast[PGtkButton](GTK_CHECK_CAST(obj, GTK_TYPE_BUTTON()))

proc GTK_BUTTON_CLASS*(klass: pointer): PGtkButtonClass =
  result = cast[PGtkButtonClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_BUTTON()))

proc GTK_IS_BUTTON*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_BUTTON())

proc GTK_IS_BUTTON_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_BUTTON())

proc GTK_BUTTON_GET_CLASS*(obj: pointer): PGtkButtonClass =
  result = cast[PGtkButtonClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_BUTTON()))

proc constructed*(a: var TGtkButton): guint =
  result = (a.GtkButtonflag0 and bm_TGtkButton_constructed) shr
      bp_TGtkButton_constructed

proc set_constructed*(a: var TGtkButton, `constructed`: guint) =
  a.GtkButtonflag0 = a.GtkButtonflag0 or
      (int16(`constructed` shl bp_TGtkButton_constructed) and
      bm_TGtkButton_constructed)

proc in_button*(a: var TGtkButton): guint =
  result = (a.GtkButtonflag0 and bm_TGtkButton_in_button) shr bp_TGtkButton_in_button

proc set_in_button*(a: var TGtkButton, `in_button`: guint) =
  a.GtkButtonflag0 = a.GtkButtonflag0 or
      (int16(`in_button` shl bp_TGtkButton_in_button) and bm_TGtkButton_in_button)

proc button_down*(a: var TGtkButton): guint =
  result = (a.GtkButtonflag0 and bm_TGtkButton_button_down) shr
      bp_TGtkButton_button_down

proc set_button_down*(a: var TGtkButton, `button_down`: guint) =
  a.GtkButtonflag0 = a.GtkButtonflag0 or
      (int16(`button_down` shl bp_TGtkButton_button_down) and
      bm_TGtkButton_button_down)

proc relief*(a: var TGtkButton): guint =
  result = (a.GtkButtonflag0 and bm_TGtkButton_relief) shr bp_TGtkButton_relief

proc set_relief*(a: var TGtkButton, `relief`: guint) =
  a.GtkButtonflag0 = a.GtkButtonflag0 or
      (int16(`relief` shl bp_TGtkButton_relief) and bm_TGtkButton_relief)

proc use_underline*(a: var TGtkButton): guint =
  result = (a.GtkButtonflag0 and bm_TGtkButton_use_underline) shr
      bp_TGtkButton_use_underline

proc set_use_underline*(a: var TGtkButton, `use_underline`: guint) =
  a.GtkButtonflag0 = a.GtkButtonflag0 or
      (int16(`use_underline` shl bp_TGtkButton_use_underline) and
      bm_TGtkButton_use_underline)

proc use_stock*(a: var TGtkButton): guint =
  result = (a.GtkButtonflag0 and bm_TGtkButton_use_stock) shr bp_TGtkButton_use_stock

proc set_use_stock*(a: var TGtkButton, `use_stock`: guint) =
  a.GtkButtonflag0 = a.GtkButtonflag0 or
      (int16(`use_stock` shl bp_TGtkButton_use_stock) and bm_TGtkButton_use_stock)

proc depressed*(a: var TGtkButton): guint =
  result = (a.GtkButtonflag0 and bm_TGtkButton_depressed) shr bp_TGtkButton_depressed

proc set_depressed*(a: var TGtkButton, `depressed`: guint) =
  a.GtkButtonflag0 = a.GtkButtonflag0 or
      (int16(`depressed` shl bp_TGtkButton_depressed) and bm_TGtkButton_depressed)

proc depress_on_activate*(a: var TGtkButton): guint =
  result = (a.GtkButtonflag0 and bm_TGtkButton_depress_on_activate) shr
      bp_TGtkButton_depress_on_activate

proc set_depress_on_activate*(a: var TGtkButton, `depress_on_activate`: guint) =
  a.GtkButtonflag0 = a.GtkButtonflag0 or
      (int16(`depress_on_activate` shl bp_TGtkButton_depress_on_activate) and
      bm_TGtkButton_depress_on_activate)

proc GTK_TYPE_CALENDAR*(): GType =
  result = gtk_calendar_get_type()

proc GTK_CALENDAR*(obj: pointer): PGtkCalendar =
  result = cast[PGtkCalendar](GTK_CHECK_CAST(obj, GTK_TYPE_CALENDAR()))

proc GTK_CALENDAR_CLASS*(klass: pointer): PGtkCalendarClass =
  result = cast[PGtkCalendarClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_CALENDAR()))

proc GTK_IS_CALENDAR*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_CALENDAR())

proc GTK_IS_CALENDAR_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_CALENDAR())

proc GTK_CALENDAR_GET_CLASS*(obj: pointer): PGtkCalendarClass =
  result = cast[PGtkCalendarClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_CALENDAR()))

proc GTK_TYPE_CELL_EDITABLE*(): GType =
  result = gtk_cell_editable_get_type()

proc GTK_CELL_EDITABLE*(obj: pointer): PGtkCellEditable =
  result = cast[PGtkCellEditable](G_TYPE_CHECK_INSTANCE_CAST(obj,
      GTK_TYPE_CELL_EDITABLE()))

proc GTK_CELL_EDITABLE_CLASS*(obj: pointer): PGtkCellEditableIface =
  result = cast[PGtkCellEditableIface](G_TYPE_CHECK_CLASS_CAST(obj,
      GTK_TYPE_CELL_EDITABLE()))

proc GTK_IS_CELL_EDITABLE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GTK_TYPE_CELL_EDITABLE())

proc GTK_CELL_EDITABLE_GET_IFACE*(obj: pointer): PGtkCellEditableIface =
  result = cast[PGtkCellEditableIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      GTK_TYPE_CELL_EDITABLE()))

proc GTK_TYPE_CELL_RENDERER*(): GType =
  result = gtk_cell_renderer_get_type()

proc GTK_CELL_RENDERER*(obj: pointer): PGtkCellRenderer =
  result = cast[PGtkCellRenderer](GTK_CHECK_CAST(obj, GTK_TYPE_CELL_RENDERER()))

proc GTK_CELL_RENDERER_CLASS*(klass: pointer): PGtkCellRendererClass =
  result = cast[PGtkCellRendererClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_CELL_RENDERER()))

proc GTK_IS_CELL_RENDERER*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_CELL_RENDERER())

proc GTK_IS_CELL_RENDERER_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_CELL_RENDERER())

proc GTK_CELL_RENDERER_GET_CLASS*(obj: pointer): PGtkCellRendererClass =
  result = cast[PGtkCellRendererClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_CELL_RENDERER()))

proc mode*(a: var TGtkCellRenderer): guint =
  result = (a.GtkCellRendererflag0 and bm_TGtkCellRenderer_mode) shr
      bp_TGtkCellRenderer_mode

proc set_mode*(a: var TGtkCellRenderer, `mode`: guint) =
  a.GtkCellRendererflag0 = a.GtkCellRendererflag0 or
      (int16(`mode` shl bp_TGtkCellRenderer_mode) and bm_TGtkCellRenderer_mode)

proc visible*(a: var TGtkCellRenderer): guint =
  result = (a.GtkCellRendererflag0 and bm_TGtkCellRenderer_visible) shr
      bp_TGtkCellRenderer_visible

proc set_visible*(a: var TGtkCellRenderer, `visible`: guint) =
  a.GtkCellRendererflag0 = a.GtkCellRendererflag0 or
      (int16(`visible` shl bp_TGtkCellRenderer_visible) and
      bm_TGtkCellRenderer_visible)

proc is_expander*(a: var TGtkCellRenderer): guint =
  result = (a.GtkCellRendererflag0 and bm_TGtkCellRenderer_is_expander) shr
      bp_TGtkCellRenderer_is_expander

proc set_is_expander*(a: var TGtkCellRenderer, `is_expander`: guint) =
  a.GtkCellRendererflag0 = a.GtkCellRendererflag0 or
      (int16(`is_expander` shl bp_TGtkCellRenderer_is_expander) and
      bm_TGtkCellRenderer_is_expander)

proc is_expanded*(a: var TGtkCellRenderer): guint =
  result = (a.GtkCellRendererflag0 and bm_TGtkCellRenderer_is_expanded) shr
      bp_TGtkCellRenderer_is_expanded

proc set_is_expanded*(a: var TGtkCellRenderer, `is_expanded`: guint) =
  a.GtkCellRendererflag0 = a.GtkCellRendererflag0 or
      (int16(`is_expanded` shl bp_TGtkCellRenderer_is_expanded) and
      bm_TGtkCellRenderer_is_expanded)

proc cell_background_set*(a: var TGtkCellRenderer): guint =
  result = (a.GtkCellRendererflag0 and bm_TGtkCellRenderer_cell_background_set) shr
      bp_TGtkCellRenderer_cell_background_set

proc set_cell_background_set*(a: var TGtkCellRenderer,
                              `cell_background_set`: guint) =
  a.GtkCellRendererflag0 = a.GtkCellRendererflag0 or
      (int16(`cell_background_set` shl bp_TGtkCellRenderer_cell_background_set) and
      bm_TGtkCellRenderer_cell_background_set)

proc GTK_TYPE_CELL_RENDERER_TEXT*(): GType =
  result = gtk_cell_renderer_text_get_type()

proc GTK_CELL_RENDERER_TEXT*(obj: pointer): PGtkCellRendererText =
  result = cast[PGtkCellRendererText](GTK_CHECK_CAST(obj, GTK_TYPE_CELL_RENDERER_TEXT()))

proc GTK_CELL_RENDERER_TEXT_CLASS*(klass: pointer): PGtkCellRendererTextClass =
  result = cast[PGtkCellRendererTextClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_CELL_RENDERER_TEXT()))

proc GTK_IS_CELL_RENDERER_TEXT*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_CELL_RENDERER_TEXT())

proc GTK_IS_CELL_RENDERER_TEXT_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_CELL_RENDERER_TEXT())

proc GTK_CELL_RENDERER_TEXT_GET_CLASS*(obj: pointer): PGtkCellRendererTextClass =
  result = cast[PGtkCellRendererTextClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_CELL_RENDERER_TEXT()))

proc strikethrough*(a: var TGtkCellRendererText): guint =
  result = (a.GtkCellRendererTextflag0 and bm_TGtkCellRendererText_strikethrough) shr
      bp_TGtkCellRendererText_strikethrough

proc set_strikethrough*(a: var TGtkCellRendererText, `strikethrough`: guint) =
  a.GtkCellRendererTextflag0 = a.GtkCellRendererTextflag0 or
      (int16(`strikethrough` shl bp_TGtkCellRendererText_strikethrough) and
      bm_TGtkCellRendererText_strikethrough)

proc editable*(a: var TGtkCellRendererText): guint =
  result = (a.GtkCellRendererTextflag0 and bm_TGtkCellRendererText_editable) shr
      bp_TGtkCellRendererText_editable

proc set_editable*(a: var TGtkCellRendererText, `editable`: guint) =
  a.GtkCellRendererTextflag0 = a.GtkCellRendererTextflag0 or
      (int16(`editable` shl bp_TGtkCellRendererText_editable) and
      bm_TGtkCellRendererText_editable)

proc scale_set*(a: var TGtkCellRendererText): guint =
  result = (a.GtkCellRendererTextflag0 and bm_TGtkCellRendererText_scale_set) shr
      bp_TGtkCellRendererText_scale_set

proc set_scale_set*(a: var TGtkCellRendererText, `scale_set`: guint) =
  a.GtkCellRendererTextflag0 = a.GtkCellRendererTextflag0 or
      (int16(`scale_set` shl bp_TGtkCellRendererText_scale_set) and
      bm_TGtkCellRendererText_scale_set)

proc foreground_set*(a: var TGtkCellRendererText): guint =
  result = (a.GtkCellRendererTextflag0 and bm_TGtkCellRendererText_foreground_set) shr
      bp_TGtkCellRendererText_foreground_set

proc set_foreground_set*(a: var TGtkCellRendererText, `foreground_set`: guint) =
  a.GtkCellRendererTextflag0 = a.GtkCellRendererTextflag0 or
      (int16(`foreground_set` shl bp_TGtkCellRendererText_foreground_set) and
      bm_TGtkCellRendererText_foreground_set)

proc background_set*(a: var TGtkCellRendererText): guint =
  result = (a.GtkCellRendererTextflag0 and bm_TGtkCellRendererText_background_set) shr
      bp_TGtkCellRendererText_background_set

proc set_background_set*(a: var TGtkCellRendererText, `background_set`: guint) =
  a.GtkCellRendererTextflag0 = a.GtkCellRendererTextflag0 or
      (int16(`background_set` shl bp_TGtkCellRendererText_background_set) and
      bm_TGtkCellRendererText_background_set)

proc underline_set*(a: var TGtkCellRendererText): guint =
  result = (a.GtkCellRendererTextflag0 and bm_TGtkCellRendererText_underline_set) shr
      bp_TGtkCellRendererText_underline_set

proc set_underline_set*(a: var TGtkCellRendererText, `underline_set`: guint) =
  a.GtkCellRendererTextflag0 = a.GtkCellRendererTextflag0 or
      (int16(`underline_set` shl bp_TGtkCellRendererText_underline_set) and
      bm_TGtkCellRendererText_underline_set)

proc rise_set*(a: var TGtkCellRendererText): guint =
  result = (a.GtkCellRendererTextflag0 and bm_TGtkCellRendererText_rise_set) shr
      bp_TGtkCellRendererText_rise_set

proc set_rise_set*(a: var TGtkCellRendererText, `rise_set`: guint) =
  a.GtkCellRendererTextflag0 = a.GtkCellRendererTextflag0 or
      (int16(`rise_set` shl bp_TGtkCellRendererText_rise_set) and
      bm_TGtkCellRendererText_rise_set)

proc strikethrough_set*(a: var TGtkCellRendererText): guint =
  result = (a.GtkCellRendererTextflag0 and bm_TGtkCellRendererText_strikethrough_set) shr
      bp_TGtkCellRendererText_strikethrough_set

proc set_strikethrough_set*(a: var TGtkCellRendererText,
                            `strikethrough_set`: guint) =
  a.GtkCellRendererTextflag0 = a.GtkCellRendererTextflag0 or
      (int16(`strikethrough_set` shl bp_TGtkCellRendererText_strikethrough_set) and
      bm_TGtkCellRendererText_strikethrough_set)

proc editable_set*(a: var TGtkCellRendererText): guint =
  result = (a.GtkCellRendererTextflag0 and bm_TGtkCellRendererText_editable_set) shr
      bp_TGtkCellRendererText_editable_set

proc set_editable_set*(a: var TGtkCellRendererText, `editable_set`: guint) =
  a.GtkCellRendererTextflag0 = a.GtkCellRendererTextflag0 or
      (int16(`editable_set` shl bp_TGtkCellRendererText_editable_set) and
      bm_TGtkCellRendererText_editable_set)

proc calc_fixed_height*(a: var TGtkCellRendererText): guint =
  result = (a.GtkCellRendererTextflag0 and bm_TGtkCellRendererText_calc_fixed_height) shr
      bp_TGtkCellRendererText_calc_fixed_height

proc set_calc_fixed_height*(a: var TGtkCellRendererText,
                            `calc_fixed_height`: guint) =
  a.GtkCellRendererTextflag0 = a.GtkCellRendererTextflag0 or
      (int16(`calc_fixed_height` shl bp_TGtkCellRendererText_calc_fixed_height) and
      bm_TGtkCellRendererText_calc_fixed_height)

proc GTK_TYPE_CELL_RENDERER_TOGGLE*(): GType =
  result = gtk_cell_renderer_toggle_get_type()

proc GTK_CELL_RENDERER_TOGGLE*(obj: pointer): PGtkCellRendererToggle =
  result = cast[PGtkCellRendererToggle](GTK_CHECK_CAST(obj,
      GTK_TYPE_CELL_RENDERER_TOGGLE()))

proc GTK_CELL_RENDERER_TOGGLE_CLASS*(klass: pointer): PGtkCellRendererToggleClass =
  result = cast[PGtkCellRendererToggleClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_CELL_RENDERER_TOGGLE()))

proc GTK_IS_CELL_RENDERER_TOGGLE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_CELL_RENDERER_TOGGLE())

proc GTK_IS_CELL_RENDERER_TOGGLE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_CELL_RENDERER_TOGGLE())

proc GTK_CELL_RENDERER_TOGGLE_GET_CLASS*(obj: pointer): PGtkCellRendererToggleClass =
  result = cast[PGtkCellRendererToggleClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_CELL_RENDERER_TOGGLE()))

proc active*(a: var TGtkCellRendererToggle): guint =
  result = (a.GtkCellRendererToggleflag0 and bm_TGtkCellRendererToggle_active) shr
      bp_TGtkCellRendererToggle_active

proc set_active*(a: var TGtkCellRendererToggle, `active`: guint) =
  a.GtkCellRendererToggleflag0 = a.GtkCellRendererToggleflag0 or
      (int16(`active` shl bp_TGtkCellRendererToggle_active) and
      bm_TGtkCellRendererToggle_active)

proc activatable*(a: var TGtkCellRendererToggle): guint =
  result = (a.GtkCellRendererToggleflag0 and bm_TGtkCellRendererToggle_activatable) shr
      bp_TGtkCellRendererToggle_activatable

proc set_activatable*(a: var TGtkCellRendererToggle, `activatable`: guint) =
  a.GtkCellRendererToggleflag0 = a.GtkCellRendererToggleflag0 or
      (int16(`activatable` shl bp_TGtkCellRendererToggle_activatable) and
      bm_TGtkCellRendererToggle_activatable)

proc radio*(a: var TGtkCellRendererToggle): guint =
  result = (a.GtkCellRendererToggleflag0 and bm_TGtkCellRendererToggle_radio) shr
      bp_TGtkCellRendererToggle_radio

proc set_radio*(a: var TGtkCellRendererToggle, `radio`: guint) =
  a.GtkCellRendererToggleflag0 = a.GtkCellRendererToggleflag0 or
      (int16(`radio` shl bp_TGtkCellRendererToggle_radio) and
      bm_TGtkCellRendererToggle_radio)

proc GTK_TYPE_CELL_RENDERER_PIXBUF*(): GType =
  result = gtk_cell_renderer_pixbuf_get_type()

proc GTK_CELL_RENDERER_PIXBUF*(obj: pointer): PGtkCellRendererPixbuf =
  result = cast[PGtkCellRendererPixbuf](GTK_CHECK_CAST(obj,
      GTK_TYPE_CELL_RENDERER_PIXBUF()))

proc GTK_CELL_RENDERER_PIXBUF_CLASS*(klass: pointer): PGtkCellRendererPixbufClass =
  result = cast[PGtkCellRendererPixbufClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_CELL_RENDERER_PIXBUF()))

proc GTK_IS_CELL_RENDERER_PIXBUF*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_CELL_RENDERER_PIXBUF())

proc GTK_IS_CELL_RENDERER_PIXBUF_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_CELL_RENDERER_PIXBUF())

proc GTK_CELL_RENDERER_PIXBUF_GET_CLASS*(obj: pointer): PGtkCellRendererPixbufClass =
  result = cast[PGtkCellRendererPixbufClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_CELL_RENDERER_PIXBUF()))

proc GTK_TYPE_ITEM*(): GType =
  result = gtk_item_get_type()

proc GTK_ITEM*(obj: pointer): PGtkItem =
  result = cast[PGtkItem](GTK_CHECK_CAST(obj, GTK_TYPE_ITEM()))

proc GTK_ITEM_CLASS*(klass: pointer): PGtkItemClass =
  result = cast[PGtkItemClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_ITEM()))

proc GTK_IS_ITEM*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_ITEM())

proc GTK_IS_ITEM_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_ITEM())

proc GTK_ITEM_GET_CLASS*(obj: pointer): PGtkItemClass =
  result = cast[PGtkItemClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_ITEM()))

proc GTK_TYPE_MENU_ITEM*(): GType =
  result = gtk_menu_item_get_type()

proc GTK_MENU_ITEM*(obj: pointer): PGtkMenuItem =
  result = cast[PGtkMenuItem](GTK_CHECK_CAST(obj, GTK_TYPE_MENU_ITEM()))

proc GTK_MENU_ITEM_CLASS*(klass: pointer): PGtkMenuItemClass =
  result = cast[PGtkMenuItemClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_MENU_ITEM()))

proc GTK_IS_MENU_ITEM*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_MENU_ITEM())

proc GTK_IS_MENU_ITEM_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_MENU_ITEM())

proc GTK_MENU_ITEM_GET_CLASS*(obj: pointer): PGtkMenuItemClass =
  result = cast[PGtkMenuItemClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_MENU_ITEM()))

proc show_submenu_indicator*(a: var TGtkMenuItem): guint =
  result = (a.GtkMenuItemflag0 and bm_TGtkMenuItem_show_submenu_indicator) shr
      bp_TGtkMenuItem_show_submenu_indicator

proc set_show_submenu_indicator*(a: var TGtkMenuItem,
                                 `show_submenu_indicator`: guint) =
  a.GtkMenuItemflag0 = a.GtkMenuItemflag0 or
      (int16(`show_submenu_indicator` shl bp_TGtkMenuItem_show_submenu_indicator) and
      bm_TGtkMenuItem_show_submenu_indicator)

proc submenu_placement*(a: var TGtkMenuItem): guint =
  result = (a.GtkMenuItemflag0 and bm_TGtkMenuItem_submenu_placement) shr
      bp_TGtkMenuItem_submenu_placement

proc set_submenu_placement*(a: var TGtkMenuItem, `submenu_placement`: guint) =
  a.GtkMenuItemflag0 = a.GtkMenuItemflag0 or
      (int16(`submenu_placement` shl bp_TGtkMenuItem_submenu_placement) and
      bm_TGtkMenuItem_submenu_placement)

proc submenu_direction*(a: var TGtkMenuItem): guint =
  result = (a.GtkMenuItemflag0 and bm_TGtkMenuItem_submenu_direction) shr
      bp_TGtkMenuItem_submenu_direction

proc set_submenu_direction*(a: var TGtkMenuItem, `submenu_direction`: guint) =
  a.GtkMenuItemflag0 = a.GtkMenuItemflag0 or
      (int16(`submenu_direction` shl bp_TGtkMenuItem_submenu_direction) and
      bm_TGtkMenuItem_submenu_direction)

proc right_justify*(a: var TGtkMenuItem): guint =
  result = (a.GtkMenuItemflag0 and bm_TGtkMenuItem_right_justify) shr
      bp_TGtkMenuItem_right_justify

proc set_right_justify*(a: var TGtkMenuItem, `right_justify`: guint) =
  a.GtkMenuItemflag0 = a.GtkMenuItemflag0 or
      (int16(`right_justify` shl bp_TGtkMenuItem_right_justify) and
      bm_TGtkMenuItem_right_justify)

proc timer_from_keypress*(a: var TGtkMenuItem): guint =
  result = (a.GtkMenuItemflag0 and bm_TGtkMenuItem_timer_from_keypress) shr
      bp_TGtkMenuItem_timer_from_keypress

proc set_timer_from_keypress*(a: var TGtkMenuItem, `timer_from_keypress`: guint) =
  a.GtkMenuItemflag0 = a.GtkMenuItemflag0 or
      (int16(`timer_from_keypress` shl bp_TGtkMenuItem_timer_from_keypress) and
      bm_TGtkMenuItem_timer_from_keypress)

proc hide_on_activate*(a: var TGtkMenuItemClass): guint =
  result = (a.GtkMenuItemClassflag0 and bm_TGtkMenuItemClass_hide_on_activate) shr
      bp_TGtkMenuItemClass_hide_on_activate

proc set_hide_on_activate*(a: var TGtkMenuItemClass, `hide_on_activate`: guint) =
  a.GtkMenuItemClassflag0 = a.GtkMenuItemClassflag0 or
      (int16(`hide_on_activate` shl bp_TGtkMenuItemClass_hide_on_activate) and
      bm_TGtkMenuItemClass_hide_on_activate)

proc gtk_menu_item_right_justify*(menu_item: PGtkMenuItem) =
  gtk_menu_item_set_right_justified(menu_item, true)

proc GTK_TYPE_TOGGLE_BUTTON*(): GType =
  result = gtk_toggle_button_get_type()

proc GTK_TOGGLE_BUTTON*(obj: pointer): PGtkToggleButton =
  result = cast[PGtkToggleButton](GTK_CHECK_CAST(obj, GTK_TYPE_TOGGLE_BUTTON()))

proc GTK_TOGGLE_BUTTON_CLASS*(klass: pointer): PGtkToggleButtonClass =
  result = cast[PGtkToggleButtonClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_TOGGLE_BUTTON()))

proc GTK_IS_TOGGLE_BUTTON*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TOGGLE_BUTTON())

proc GTK_IS_TOGGLE_BUTTON_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TOGGLE_BUTTON())

proc GTK_TOGGLE_BUTTON_GET_CLASS*(obj: pointer): PGtkToggleButtonClass =
  result = cast[PGtkToggleButtonClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_TOGGLE_BUTTON()))

proc active*(a: var TGtkToggleButton): guint =
  result = (a.GtkToggleButtonflag0 and bm_TGtkToggleButton_active) shr
      bp_TGtkToggleButton_active

proc set_active*(a: var TGtkToggleButton, `active`: guint) =
  a.GtkToggleButtonflag0 = a.GtkToggleButtonflag0 or
      (int16(`active` shl bp_TGtkToggleButton_active) and
      bm_TGtkToggleButton_active)

proc draw_indicator*(a: var TGtkToggleButton): guint =
  result = (a.GtkToggleButtonflag0 and bm_TGtkToggleButton_draw_indicator) shr
      bp_TGtkToggleButton_draw_indicator

proc set_draw_indicator*(a: var TGtkToggleButton, `draw_indicator`: guint) =
  a.GtkToggleButtonflag0 = a.GtkToggleButtonflag0 or
      (int16(`draw_indicator` shl bp_TGtkToggleButton_draw_indicator) and
      bm_TGtkToggleButton_draw_indicator)

proc inconsistent*(a: var TGtkToggleButton): guint =
  result = (a.GtkToggleButtonflag0 and bm_TGtkToggleButton_inconsistent) shr
      bp_TGtkToggleButton_inconsistent

proc set_inconsistent*(a: var TGtkToggleButton, `inconsistent`: guint) =
  a.GtkToggleButtonflag0 = a.GtkToggleButtonflag0 or
      (int16(`inconsistent` shl bp_TGtkToggleButton_inconsistent) and
      bm_TGtkToggleButton_inconsistent)

proc GTK_TYPE_CHECK_BUTTON*(): GType =
  result = gtk_check_button_get_type()

proc GTK_CHECK_BUTTON*(obj: pointer): PGtkCheckButton =
  result = cast[PGtkCheckButton](GTK_CHECK_CAST(obj, GTK_TYPE_CHECK_BUTTON()))

proc GTK_CHECK_BUTTON_CLASS*(klass: pointer): PGtkCheckButtonClass =
  result = cast[PGtkCheckButtonClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_CHECK_BUTTON()))

proc GTK_IS_CHECK_BUTTON*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_CHECK_BUTTON())

proc GTK_IS_CHECK_BUTTON_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_CHECK_BUTTON())

proc GTK_CHECK_BUTTON_GET_CLASS*(obj: pointer): PGtkCheckButtonClass =
  result = cast[PGtkCheckButtonClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_CHECK_BUTTON()))

proc GTK_TYPE_CHECK_MENU_ITEM*(): GType =
  result = gtk_check_menu_item_get_type()

proc GTK_CHECK_MENU_ITEM*(obj: pointer): PGtkCheckMenuItem =
  result = cast[PGtkCheckMenuItem](GTK_CHECK_CAST(obj, GTK_TYPE_CHECK_MENU_ITEM()))

proc GTK_CHECK_MENU_ITEM_CLASS*(klass: pointer): PGtkCheckMenuItemClass =
  result = cast[PGtkCheckMenuItemClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_CHECK_MENU_ITEM()))

proc GTK_IS_CHECK_MENU_ITEM*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_CHECK_MENU_ITEM())

proc GTK_IS_CHECK_MENU_ITEM_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_CHECK_MENU_ITEM())

proc GTK_CHECK_MENU_ITEM_GET_CLASS*(obj: pointer): PGtkCheckMenuItemClass =
  result = cast[PGtkCheckMenuItemClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_CHECK_MENU_ITEM()))

proc active*(a: var TGtkCheckMenuItem): guint =
  result = (a.GtkCheckMenuItemflag0 and bm_TGtkCheckMenuItem_active) shr
      bp_TGtkCheckMenuItem_active

proc set_active*(a: var TGtkCheckMenuItem, `active`: guint) =
  a.GtkCheckMenuItemflag0 = a.GtkCheckMenuItemflag0 or
      (int16(`active` shl bp_TGtkCheckMenuItem_active) and
      bm_TGtkCheckMenuItem_active)

proc always_show_toggle*(a: var TGtkCheckMenuItem): guint =
  result = (a.GtkCheckMenuItemflag0 and bm_TGtkCheckMenuItem_always_show_toggle) shr
      bp_TGtkCheckMenuItem_always_show_toggle

proc set_always_show_toggle*(a: var TGtkCheckMenuItem,
                             `always_show_toggle`: guint) =
  a.GtkCheckMenuItemflag0 = a.GtkCheckMenuItemflag0 or
      (int16(`always_show_toggle` shl bp_TGtkCheckMenuItem_always_show_toggle) and
      bm_TGtkCheckMenuItem_always_show_toggle)

proc inconsistent*(a: var TGtkCheckMenuItem): guint =
  result = (a.GtkCheckMenuItemflag0 and bm_TGtkCheckMenuItem_inconsistent) shr
      bp_TGtkCheckMenuItem_inconsistent

proc set_inconsistent*(a: var TGtkCheckMenuItem, `inconsistent`: guint) =
  a.GtkCheckMenuItemflag0 = a.GtkCheckMenuItemflag0 or
      (int16(`inconsistent` shl bp_TGtkCheckMenuItem_inconsistent) and
      bm_TGtkCheckMenuItem_inconsistent)

proc GTK_TYPE_CLIST*(): GType =
  result = gtk_clist_get_type()

proc GTK_CLIST*(obj: pointer): PGtkCList =
  result = cast[PGtkCList](GTK_CHECK_CAST(obj, GTK_TYPE_CLIST()))

proc GTK_CLIST_CLASS*(klass: pointer): PGtkCListClass =
  result = cast[PGtkCListClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_CLIST()))

proc GTK_IS_CLIST*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_CLIST())

proc GTK_IS_CLIST_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_CLIST())

proc GTK_CLIST_GET_CLASS*(obj: pointer): PGtkCListClass =
  result = cast[PGtkCListClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_CLIST()))

proc GTK_CLIST_FLAGS*(clist: pointer): guint16 =
  result = toU16(GTK_CLIST(clist).flags)

proc GTK_CLIST_SET_FLAG*(clist: PGtkCList, flag: guint16) =
  clist.flags = GTK_CLIST(clist).flags or (flag)

proc GTK_CLIST_UNSET_FLAG*(clist: PGtkCList, flag: guint16) =
  clist.flags = GTK_CLIST(clist).flags and not (flag)

proc GTK_CLIST_IN_DRAG_get*(clist: pointer): bool =
  result = ((GTK_CLIST_FLAGS(clist)) and cint(GTK_CLIST_IN_DRAG)) != 0'i32

proc GTK_CLIST_ROW_HEIGHT_SET_get*(clist: pointer): bool =
  result = ((GTK_CLIST_FLAGS(clist)) and cint(GTK_CLIST_ROW_HEIGHT_SET)) != 0'i32

proc GTK_CLIST_SHOW_TITLES_get*(clist: pointer): bool =
  result = ((GTK_CLIST_FLAGS(clist)) and cint(GTK_CLIST_SHOW_TITLES)) != 0'i32

proc GTK_CLIST_ADD_MODE_get*(clist: pointer): bool =
  result = ((GTK_CLIST_FLAGS(clist)) and cint(GTK_CLIST_ADD_MODE)) != 0'i32

proc GTK_CLIST_AUTO_SORT_get*(clist: pointer): bool =
  result = ((GTK_CLIST_FLAGS(clist)) and cint(GTK_CLIST_AUTO_SORT)) != 0'i32

proc GTK_CLIST_AUTO_RESIZE_BLOCKED_get*(clist: pointer): bool =
  result = ((GTK_CLIST_FLAGS(clist)) and cint(GTK_CLIST_AUTO_RESIZE_BLOCKED)) != 0'i32

proc GTK_CLIST_REORDERABLE_get*(clist: pointer): bool =
  result = ((GTK_CLIST_FLAGS(clist)) and cint(GTK_CLIST_REORDERABLE)) != 0'i32

proc GTK_CLIST_USE_DRAG_ICONS_get*(clist: pointer): bool =
  result = ((GTK_CLIST_FLAGS(clist)) and cint(GTK_CLIST_USE_DRAG_ICONS)) != 0'i32

proc GTK_CLIST_DRAW_DRAG_LINE_get*(clist: pointer): bool =
  result = ((GTK_CLIST_FLAGS(clist)) and cint(GTK_CLIST_DRAW_DRAG_LINE)) != 0'i32

proc GTK_CLIST_DRAW_DRAG_RECT_get*(clist: pointer): bool =
  result = ((GTK_CLIST_FLAGS(clist)) and cint(GTK_CLIST_DRAW_DRAG_RECT)) != 0'i32

proc GTK_CLIST_ROW_get*(glist: PGList): PGtkCListRow =
  result = cast[PGtkCListRow](glist . data)

when false:
  proc GTK_CELL_TEXT_get*(cell: pointer): PGtkCellText =
    result = cast[PGtkCellText](addr((cell)))

  proc GTK_CELL_PIXMAP_get*(cell: pointer): PGtkCellPixmap =
    result = cast[PGtkCellPixmap](addr((cell)))

  proc GTK_CELL_PIXTEXT_get*(cell: pointer): PGtkCellPixText =
    result = cast[PGtkCellPixText](addr((cell)))

  proc GTK_CELL_WIDGET_get*(cell: pointer): PGtkCellWidget =
    result = cast[PGtkCellWidget](addr((cell)))

proc visible*(a: var TGtkCListColumn): guint =
  result = (a.flag0 and bm_TGtkCListColumn_visible) shr
      bp_TGtkCListColumn_visible

proc set_visible*(a: var TGtkCListColumn, `visible`: guint) =
  a.flag0 = a.flag0 or
      (int16(`visible` shl bp_TGtkCListColumn_visible) and
      bm_TGtkCListColumn_visible)

proc width_set*(a: var TGtkCListColumn): guint =
  result = (a.flag0 and bm_TGtkCListColumn_width_set) shr
      bp_TGtkCListColumn_width_set

proc set_width_set*(a: var TGtkCListColumn, `width_set`: guint) =
  a.flag0 = a.flag0 or
      (int16(`width_set` shl bp_TGtkCListColumn_width_set) and
      bm_TGtkCListColumn_width_set)

proc resizeable*(a: var TGtkCListColumn): guint =
  result = (a.flag0 and bm_TGtkCListColumn_resizeable) shr
      bp_TGtkCListColumn_resizeable

proc set_resizeable*(a: var TGtkCListColumn, `resizeable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`resizeable` shl bp_TGtkCListColumn_resizeable) and
      bm_TGtkCListColumn_resizeable)

proc auto_resize*(a: var TGtkCListColumn): guint =
  result = (a.flag0 and bm_TGtkCListColumn_auto_resize) shr
      bp_TGtkCListColumn_auto_resize

proc set_auto_resize*(a: var TGtkCListColumn, `auto_resize`: guint) =
  a.flag0 = a.flag0 or
      (int16(`auto_resize` shl bp_TGtkCListColumn_auto_resize) and
      bm_TGtkCListColumn_auto_resize)

proc button_passive*(a: var TGtkCListColumn): guint =
  result = (a.flag0 and bm_TGtkCListColumn_button_passive) shr
      bp_TGtkCListColumn_button_passive

proc set_button_passive*(a: var TGtkCListColumn, `button_passive`: guint) =
  a.flag0 = a.flag0 or
      (int16(`button_passive` shl bp_TGtkCListColumn_button_passive) and
      bm_TGtkCListColumn_button_passive)

proc fg_set*(a: var TGtkCListRow): guint =
  result = (a.flag0 and bm_TGtkCListRow_fg_set) shr bp_TGtkCListRow_fg_set

proc set_fg_set*(a: var TGtkCListRow, `fg_set`: guint) =
  a.flag0 = a.flag0 or
      (int16(`fg_set` shl bp_TGtkCListRow_fg_set) and bm_TGtkCListRow_fg_set)

proc bg_set*(a: var TGtkCListRow): guint =
  result = (a.flag0 and bm_TGtkCListRow_bg_set) shr bp_TGtkCListRow_bg_set

proc set_bg_set*(a: var TGtkCListRow, `bg_set`: guint) =
  a.flag0 = a.flag0 or
      (int16(`bg_set` shl bp_TGtkCListRow_bg_set) and bm_TGtkCListRow_bg_set)

proc selectable*(a: var TGtkCListRow): guint =
  result = (a.flag0 and bm_TGtkCListRow_selectable) shr
      bp_TGtkCListRow_selectable

proc set_selectable*(a: var TGtkCListRow, `selectable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`selectable` shl bp_TGtkCListRow_selectable) and
      bm_TGtkCListRow_selectable)

proc GTK_TYPE_DIALOG*(): GType =
  result = gtk_dialog_get_type()

proc GTK_DIALOG*(obj: pointer): PGtkDialog =
  result = cast[PGtkDialog](GTK_CHECK_CAST(obj, GTK_TYPE_DIALOG()))

proc GTK_DIALOG_CLASS*(klass: pointer): PGtkDialogClass =
  result = cast[PGtkDialogClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_DIALOG()))

proc GTK_IS_DIALOG*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_DIALOG())

proc GTK_IS_DIALOG_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_DIALOG())

proc GTK_DIALOG_GET_CLASS*(obj: pointer): PGtkDialogClass =
  result = cast[PGtkDialogClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_DIALOG()))

proc GTK_TYPE_VBOX*(): GType =
  result = gtk_vbox_get_type()

proc GTK_VBOX*(obj: pointer): PGtkVBox =
  result = cast[PGtkVBox](GTK_CHECK_CAST(obj, GTK_TYPE_VBOX()))

proc GTK_VBOX_CLASS*(klass: pointer): PGtkVBoxClass =
  result = cast[PGtkVBoxClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_VBOX()))

proc GTK_IS_VBOX*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_VBOX())

proc GTK_IS_VBOX_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_VBOX())

proc GTK_VBOX_GET_CLASS*(obj: pointer): PGtkVBoxClass =
  result = cast[PGtkVBoxClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_VBOX()))

proc GTK_TYPE_COLOR_SELECTION*(): GType =
  result = gtk_color_selection_get_type()

proc GTK_COLOR_SELECTION*(obj: pointer): PGtkColorSelection =
  result = cast[PGtkColorSelection](GTK_CHECK_CAST(obj, GTK_TYPE_COLOR_SELECTION()))

proc GTK_COLOR_SELECTION_CLASS*(klass: pointer): PGtkColorSelectionClass =
  result = cast[PGtkColorSelectionClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_COLOR_SELECTION()))

proc GTK_IS_COLOR_SELECTION*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_COLOR_SELECTION())

proc GTK_IS_COLOR_SELECTION_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_COLOR_SELECTION())

proc GTK_COLOR_SELECTION_GET_CLASS*(obj: pointer): PGtkColorSelectionClass =
  result = cast[PGtkColorSelectionClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_COLOR_SELECTION()))

proc GTK_TYPE_COLOR_SELECTION_DIALOG*(): GType =
  result = gtk_color_selection_dialog_get_type()

proc GTK_COLOR_SELECTION_DIALOG*(obj: pointer): PGtkColorSelectionDialog =
  result = cast[PGtkColorSelectionDialog](GTK_CHECK_CAST(obj,
      GTK_TYPE_COLOR_SELECTION_DIALOG()))

proc GTK_COLOR_SELECTION_DIALOG_CLASS*(klass: pointer): PGtkColorSelectionDialogClass =
  result = cast[PGtkColorSelectionDialogClass](
      GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_COLOR_SELECTION_DIALOG()))

proc GTK_IS_COLOR_SELECTION_DIALOG*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_COLOR_SELECTION_DIALOG())

proc GTK_IS_COLOR_SELECTION_DIALOG_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_COLOR_SELECTION_DIALOG())

proc GTK_COLOR_SELECTION_DIALOG_GET_CLASS*(obj: pointer): PGtkColorSelectionDialogClass =
  result = cast[PGtkColorSelectionDialogClass](
      GTK_CHECK_GET_CLASS(obj, GTK_TYPE_COLOR_SELECTION_DIALOG()))

proc GTK_TYPE_HBOX*(): GType =
  result = gtk_hbox_get_type()

proc GTK_HBOX*(obj: pointer): PGtkHBox =
  result = cast[PGtkHBox](GTK_CHECK_CAST(obj, GTK_TYPE_HBOX()))

proc GTK_HBOX_CLASS*(klass: pointer): PGtkHBoxClass =
  result = cast[PGtkHBoxClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_HBOX()))

proc GTK_IS_HBOX*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_HBOX())

proc GTK_IS_HBOX_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_HBOX())

proc GTK_HBOX_GET_CLASS*(obj: pointer): PGtkHBoxClass =
  result = cast[PGtkHBoxClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_HBOX()))

proc GTK_TYPE_COMBO*(): GType =
  result = gtk_combo_get_type()

proc GTK_COMBO*(obj: pointer): PGtkCombo =
  result = cast[PGtkCombo](GTK_CHECK_CAST(obj, GTK_TYPE_COMBO()))

proc GTK_COMBO_CLASS*(klass: pointer): PGtkComboClass =
  result = cast[PGtkComboClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_COMBO()))

proc GTK_IS_COMBO*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_COMBO())

proc GTK_IS_COMBO_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_COMBO())

proc GTK_COMBO_GET_CLASS*(obj: pointer): PGtkComboClass =
  result = cast[PGtkComboClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_COMBO()))

proc value_in_list*(a: var TGtkCombo): guint =
  result = (a.GtkComboflag0 and bm_TGtkCombo_value_in_list) shr
      bp_TGtkCombo_value_in_list

proc set_value_in_list*(a: var TGtkCombo, `value_in_list`: guint) =
  a.GtkComboflag0 = a.GtkComboflag0 or
      (int16(`value_in_list` shl bp_TGtkCombo_value_in_list) and
      bm_TGtkCombo_value_in_list)

proc ok_if_empty*(a: var TGtkCombo): guint =
  result = (a.GtkComboflag0 and bm_TGtkCombo_ok_if_empty) shr
      bp_TGtkCombo_ok_if_empty

proc set_ok_if_empty*(a: var TGtkCombo, `ok_if_empty`: guint) =
  a.GtkComboflag0 = a.GtkComboflag0 or
      (int16(`ok_if_empty` shl bp_TGtkCombo_ok_if_empty) and
      bm_TGtkCombo_ok_if_empty)

proc case_sensitive*(a: var TGtkCombo): guint =
  result = (a.GtkComboflag0 and bm_TGtkCombo_case_sensitive) shr
      bp_TGtkCombo_case_sensitive

proc set_case_sensitive*(a: var TGtkCombo, `case_sensitive`: guint) =
  a.GtkComboflag0 = a.GtkComboflag0 or
      (int16(`case_sensitive` shl bp_TGtkCombo_case_sensitive) and
      bm_TGtkCombo_case_sensitive)

proc use_arrows*(a: var TGtkCombo): guint =
  result = (a.GtkComboflag0 and bm_TGtkCombo_use_arrows) shr bp_TGtkCombo_use_arrows

proc set_use_arrows*(a: var TGtkCombo, `use_arrows`: guint) =
  a.GtkComboflag0 = a.GtkComboflag0 or
      (int16(`use_arrows` shl bp_TGtkCombo_use_arrows) and bm_TGtkCombo_use_arrows)

proc use_arrows_always*(a: var TGtkCombo): guint =
  result = (a.GtkComboflag0 and bm_TGtkCombo_use_arrows_always) shr
      bp_TGtkCombo_use_arrows_always

proc set_use_arrows_always*(a: var TGtkCombo, `use_arrows_always`: guint) =
  a.GtkComboflag0 = a.GtkComboflag0 or
      (int16(`use_arrows_always` shl bp_TGtkCombo_use_arrows_always) and
      bm_TGtkCombo_use_arrows_always)

proc GTK_TYPE_CTREE*(): GType =
  result = gtk_ctree_get_type()

proc GTK_CTREE*(obj: pointer): PGtkCTree =
  result = cast[PGtkCTree](GTK_CHECK_CAST(obj, GTK_TYPE_CTREE()))

proc GTK_CTREE_CLASS*(klass: pointer): PGtkCTreeClass =
  result = cast[PGtkCTreeClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_CTREE()))

proc GTK_IS_CTREE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_CTREE())

proc GTK_IS_CTREE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_CTREE())

proc GTK_CTREE_GET_CLASS*(obj: pointer): PGtkCTreeClass =
  result = cast[PGtkCTreeClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_CTREE()))

proc GTK_CTREE_ROW*(node: TAddress): PGtkCTreeRow =
  result = cast[PGtkCTreeRow]((cast[PGList](node)) . data)

proc GTK_CTREE_NODE*(node: TAddress): PGtkCTreeNode =
  result = cast[PGtkCTreeNode](node)

proc GTK_CTREE_NODE_NEXT*(nnode: TAddress): PGtkCTreeNode =
  result = cast[PGtkCTreeNode]((cast[PGList](nnode)) . next)

proc GTK_CTREE_NODE_PREV*(`pnode`: TAddress): PGtkCTreeNode =
  result = cast[PGtkCTreeNode]((cast[PGList](`pnode`)) . prev)

proc GTK_CTREE_FUNC*(`func`: TAddress): TGtkCTreeFunc =
  result = cast[TGtkCTreeFunc](`func`)

proc GTK_TYPE_CTREE_NODE*(): GType =
  result = gtk_ctree_node_get_type()

proc line_style*(a: var TGtkCTree): guint =
  result = (a.GtkCTreeflag0 and bm_TGtkCTree_line_style) shr bp_TGtkCTree_line_style

proc set_line_style*(a: var TGtkCTree, `line_style`: guint) =
  a.GtkCTreeflag0 = a.GtkCTreeflag0 or
      (int16(`line_style` shl bp_TGtkCTree_line_style) and bm_TGtkCTree_line_style)

proc expander_style*(a: var TGtkCTree): guint =
  result = (a.GtkCTreeflag0 and bm_TGtkCTree_expander_style) shr
      bp_TGtkCTree_expander_style

proc set_expander_style*(a: var TGtkCTree, `expander_style`: guint) =
  a.GtkCTreeflag0 = a.GtkCTreeflag0 or
      (int16(`expander_style` shl bp_TGtkCTree_expander_style) and
      bm_TGtkCTree_expander_style)

proc show_stub*(a: var TGtkCTree): guint =
  result = (a.GtkCTreeflag0 and bm_TGtkCTree_show_stub) shr bp_TGtkCTree_show_stub

proc set_show_stub*(a: var TGtkCTree, `show_stub`: guint) =
  a.GtkCTreeflag0 = a.GtkCTreeflag0 or
      (int16(`show_stub` shl bp_TGtkCTree_show_stub) and bm_TGtkCTree_show_stub)

proc is_leaf*(a: var TGtkCTreeRow): guint =
  result = (a.GtkCTreeRow_flag0 and bm_TGtkCTreeRow_is_leaf) shr bp_TGtkCTreeRow_is_leaf

proc set_is_leaf*(a: var TGtkCTreeRow, `is_leaf`: guint) =
  a.GtkCTreeRow_flag0 = a.GtkCTreeRow_flag0 or
      (int16(`is_leaf` shl bp_TGtkCTreeRow_is_leaf) and bm_TGtkCTreeRow_is_leaf)

proc expanded*(a: var TGtkCTreeRow): guint =
  result = (a.GtkCTreeRow_flag0 and bm_TGtkCTreeRow_expanded) shr
      bp_TGtkCTreeRow_expanded

proc set_expanded*(a: var TGtkCTreeRow, `expanded`: guint) =
  a.GtkCTreeRow_flag0 = a.GtkCTreeRowflag0 or
      (int16(`expanded` shl bp_TGtkCTreeRow_expanded) and bm_TGtkCTreeRow_expanded)

proc gtk_ctree_set_reorderable*(t: pointer, r: bool) =
  gtk_clist_set_reorderable(cast[PGtkCList](t), r)

proc GTK_TYPE_DRAWING_AREA*(): GType =
  result = gtk_drawing_area_get_type()

proc GTK_DRAWING_AREA*(obj: pointer): PGtkDrawingArea =
  result = cast[PGtkDrawingArea](GTK_CHECK_CAST(obj, GTK_TYPE_DRAWING_AREA()))

proc GTK_DRAWING_AREA_CLASS*(klass: pointer): PGtkDrawingAreaClass =
  result = cast[PGtkDrawingAreaClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_DRAWING_AREA()))

proc GTK_IS_DRAWING_AREA*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_DRAWING_AREA())

proc GTK_IS_DRAWING_AREA_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_DRAWING_AREA())

proc GTK_DRAWING_AREA_GET_CLASS*(obj: pointer): PGtkDrawingAreaClass =
  result = cast[PGtkDrawingAreaClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_DRAWING_AREA()))

proc GTK_TYPE_CURVE*(): GType =
  result = gtk_curve_get_type()

proc GTK_CURVE*(obj: pointer): PGtkCurve =
  result = cast[PGtkCurve](GTK_CHECK_CAST(obj, GTK_TYPE_CURVE()))

proc GTK_CURVE_CLASS*(klass: pointer): PGtkCurveClass =
  result = cast[PGtkCurveClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_CURVE()))

proc GTK_IS_CURVE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_CURVE())

proc GTK_IS_CURVE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_CURVE())

proc GTK_CURVE_GET_CLASS*(obj: pointer): PGtkCurveClass =
  result = cast[PGtkCurveClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_CURVE()))

proc GTK_TYPE_EDITABLE*(): GType =
  result = gtk_editable_get_type()

proc GTK_EDITABLE*(obj: pointer): PGtkEditable =
  result = cast[PGtkEditable](G_TYPE_CHECK_INSTANCE_CAST(obj, GTK_TYPE_EDITABLE()))

proc GTK_EDITABLE_CLASS*(vtable: pointer): PGtkEditableClass =
  result = cast[PGtkEditableClass](G_TYPE_CHECK_CLASS_CAST(vtable, GTK_TYPE_EDITABLE()))

proc GTK_IS_EDITABLE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GTK_TYPE_EDITABLE())

proc GTK_IS_EDITABLE_CLASS*(vtable: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(vtable, GTK_TYPE_EDITABLE())

proc GTK_EDITABLE_GET_CLASS*(inst: pointer): PGtkEditableClass =
  result = cast[PGtkEditableClass](G_TYPE_INSTANCE_GET_INTERFACE(inst,
      GTK_TYPE_EDITABLE()))

proc GTK_TYPE_IM_CONTEXT*(): GType =
  result = gtk_im_context_get_type()

proc GTK_IM_CONTEXT*(obj: pointer): PGtkIMContext =
  result = cast[PGtkIMContext](GTK_CHECK_CAST(obj, GTK_TYPE_IM_CONTEXT()))

proc GTK_IM_CONTEXT_CLASS*(klass: pointer): PGtkIMContextClass =
  result = cast[PGtkIMContextClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_IM_CONTEXT()))

proc GTK_IS_IM_CONTEXT*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_IM_CONTEXT())

proc GTK_IS_IM_CONTEXT_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_IM_CONTEXT())

proc GTK_IM_CONTEXT_GET_CLASS*(obj: pointer): PGtkIMContextClass =
  result = cast[PGtkIMContextClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_IM_CONTEXT()))

proc GTK_TYPE_MENU_SHELL*(): GType =
  result = gtk_menu_shell_get_type()

proc GTK_MENU_SHELL*(obj: pointer): PGtkMenuShell =
  result = cast[PGtkMenuShell](GTK_CHECK_CAST(obj, GTK_TYPE_MENU_SHELL()))

proc GTK_MENU_SHELL_CLASS*(klass: pointer): PGtkMenuShellClass =
  result = cast[PGtkMenuShellClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_MENU_SHELL()))

proc GTK_IS_MENU_SHELL*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_MENU_SHELL())

proc GTK_IS_MENU_SHELL_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_MENU_SHELL())

proc GTK_MENU_SHELL_GET_CLASS*(obj: pointer): PGtkMenuShellClass =
  result = cast[PGtkMenuShellClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_MENU_SHELL()))

proc active*(a: var TGtkMenuShell): guint =
  result = (a.GtkMenuShellflag0 and bm_TGtkMenuShell_active) shr bp_TGtkMenuShell_active

proc set_active*(a: var TGtkMenuShell, `active`: guint) =
  a.GtkMenuShellflag0 = a.GtkMenuShellflag0 or
      (int16(`active` shl bp_TGtkMenuShell_active) and bm_TGtkMenuShell_active)

proc have_grab*(a: var TGtkMenuShell): guint =
  result = (a.GtkMenuShellflag0 and bm_TGtkMenuShell_have_grab) shr
      bp_TGtkMenuShell_have_grab

proc set_have_grab*(a: var TGtkMenuShell, `have_grab`: guint) =
  a.GtkMenuShellflag0 = a.GtkMenuShellflag0 or
      (int16(`have_grab` shl bp_TGtkMenuShell_have_grab) and
      bm_TGtkMenuShell_have_grab)

proc have_xgrab*(a: var TGtkMenuShell): guint =
  result = (a.GtkMenuShellflag0 and bm_TGtkMenuShell_have_xgrab) shr
      bp_TGtkMenuShell_have_xgrab

proc set_have_xgrab*(a: var TGtkMenuShell, `have_xgrab`: guint) =
  a.GtkMenuShellflag0 = a.GtkMenuShellflag0 or
      (int16(`have_xgrab` shl bp_TGtkMenuShell_have_xgrab) and
      bm_TGtkMenuShell_have_xgrab)

proc ignore_leave*(a: var TGtkMenuShell): guint =
  result = (a.GtkMenuShellflag0 and bm_TGtkMenuShell_ignore_leave) shr
      bp_TGtkMenuShell_ignore_leave

proc set_ignore_leave*(a: var TGtkMenuShell, `ignore_leave`: guint) =
  a.GtkMenuShellflag0 = a.GtkMenuShellflag0 or
      (int16(`ignore_leave` shl bp_TGtkMenuShell_ignore_leave) and
      bm_TGtkMenuShell_ignore_leave)

proc menu_flag*(a: var TGtkMenuShell): guint =
  result = (a.GtkMenuShellflag0 and bm_TGtkMenuShell_menu_flag) shr
      bp_TGtkMenuShell_menu_flag

proc set_menu_flag*(a: var TGtkMenuShell, `menu_flag`: guint) =
  a.GtkMenuShellflag0 = a.GtkMenuShellflag0 or
      (int16(`menu_flag` shl bp_TGtkMenuShell_menu_flag) and
      bm_TGtkMenuShell_menu_flag)

proc ignore_enter*(a: var TGtkMenuShell): guint =
  result = (a.GtkMenuShellflag0 and bm_TGtkMenuShell_ignore_enter) shr
      bp_TGtkMenuShell_ignore_enter

proc set_ignore_enter*(a: var TGtkMenuShell, `ignore_enter`: guint) =
  a.GtkMenuShellflag0 = a.GtkMenuShellflag0 or
      (int16(`ignore_enter` shl bp_TGtkMenuShell_ignore_enter) and
      bm_TGtkMenuShell_ignore_enter)

proc submenu_placement*(a: var TGtkMenuShellClass): guint =
  result = (a.GtkMenuShellClassflag0 and bm_TGtkMenuShellClass_submenu_placement) shr
      bp_TGtkMenuShellClass_submenu_placement

proc set_submenu_placement*(a: var TGtkMenuShellClass,
                            `submenu_placement`: guint) =
  a.GtkMenuShellClassflag0 = a.GtkMenuShellClassflag0 or
      (int16(`submenu_placement` shl bp_TGtkMenuShellClass_submenu_placement) and
      bm_TGtkMenuShellClass_submenu_placement)

proc GTK_TYPE_MENU*(): GType =
  result = gtk_menu_get_type()

proc GTK_MENU*(obj: pointer): PGtkMenu =
  result = cast[PGtkMenu](GTK_CHECK_CAST(obj, GTK_TYPE_MENU()))

proc GTK_MENU_CLASS*(klass: pointer): PGtkMenuClass =
  result = cast[PGtkMenuClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_MENU()))

proc GTK_IS_MENU*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_MENU())

proc GTK_IS_MENU_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_MENU())

proc GTK_MENU_GET_CLASS*(obj: pointer): PGtkMenuClass =
  result = cast[PGtkMenuClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_MENU()))

proc needs_destruction_ref_count*(a: var TGtkMenu): guint =
  result = (a.GtkMenuflag0 and bm_TGtkMenu_needs_destruction_ref_count) shr
      bp_TGtkMenu_needs_destruction_ref_count

proc set_needs_destruction_ref_count*(a: var TGtkMenu,
                                      `needs_destruction_ref_count`: guint) =
  a.GtkMenuflag0 = a.GtkMenuflag0 or
      (int16(`needs_destruction_ref_count` shl
      bp_TGtkMenu_needs_destruction_ref_count) and
      bm_TGtkMenu_needs_destruction_ref_count)

proc torn_off*(a: var TGtkMenu): guint =
  result = (a.GtkMenuflag0 and bm_TGtkMenu_torn_off) shr bp_TGtkMenu_torn_off

proc set_torn_off*(a: var TGtkMenu, `torn_off`: guint) =
  a.GtkMenuflag0 = a.GtkMenuflag0 or
      (int16(`torn_off` shl bp_TGtkMenu_torn_off) and bm_TGtkMenu_torn_off)

proc tearoff_active*(a: var TGtkMenu): guint =
  result = (a.GtkMenuflag0 and bm_TGtkMenu_tearoff_active) shr
      bp_TGtkMenu_tearoff_active

proc set_tearoff_active*(a: var TGtkMenu, `tearoff_active`: guint) =
  a.GtkMenuflag0 = a.GtkMenuflag0 or
      (int16(`tearoff_active` shl bp_TGtkMenu_tearoff_active) and
      bm_TGtkMenu_tearoff_active)

proc scroll_fast*(a: var TGtkMenu): guint =
  result = (a.GtkMenuflag0 and bm_TGtkMenu_scroll_fast) shr bp_TGtkMenu_scroll_fast

proc set_scroll_fast*(a: var TGtkMenu, `scroll_fast`: guint) =
  a.GtkMenuflag0 = a.GtkMenuflag0 or
      (int16(`scroll_fast` shl bp_TGtkMenu_scroll_fast) and
      bm_TGtkMenu_scroll_fast)

proc upper_arrow_visible*(a: var TGtkMenu): guint =
  result = (a.GtkMenuflag0 and bm_TGtkMenu_upper_arrow_visible) shr
      bp_TGtkMenu_upper_arrow_visible

proc set_upper_arrow_visible*(a: var TGtkMenu, `upper_arrow_visible`: guint) =
  a.GtkMenuflag0 = a.GtkMenuflag0 or
      (int16(`upper_arrow_visible` shl bp_TGtkMenu_upper_arrow_visible) and
      bm_TGtkMenu_upper_arrow_visible)

proc lower_arrow_visible*(a: var TGtkMenu): guint =
  result = (a.GtkMenuflag0 and bm_TGtkMenu_lower_arrow_visible) shr
      bp_TGtkMenu_lower_arrow_visible

proc set_lower_arrow_visible*(a: var TGtkMenu, `lower_arrow_visible`: guint) =
  a.GtkMenuflag0 = a.GtkMenuflag0 or
      (int16(`lower_arrow_visible` shl bp_TGtkMenu_lower_arrow_visible) and
      bm_TGtkMenu_lower_arrow_visible)

proc upper_arrow_prelight*(a: var TGtkMenu): guint =
  result = (a.GtkMenuflag0 and bm_TGtkMenu_upper_arrow_prelight) shr
      bp_TGtkMenu_upper_arrow_prelight

proc set_upper_arrow_prelight*(a: var TGtkMenu, `upper_arrow_prelight`: guint) =
  a.GtkMenuflag0 = a.GtkMenuflag0 or
      (int16(`upper_arrow_prelight` shl bp_TGtkMenu_upper_arrow_prelight) and
      bm_TGtkMenu_upper_arrow_prelight)

proc lower_arrow_prelight*(a: var TGtkMenu): guint =
  result = (a.GtkMenuflag0 and bm_TGtkMenu_lower_arrow_prelight) shr
      bp_TGtkMenu_lower_arrow_prelight

proc set_lower_arrow_prelight*(a: var TGtkMenu, `lower_arrow_prelight`: guint) =
  a.GtkMenuflag0 = a.GtkMenuflag0 or
      (int16(`lower_arrow_prelight` shl bp_TGtkMenu_lower_arrow_prelight) and
      bm_TGtkMenu_lower_arrow_prelight)

proc gtk_menu_append*(menu, child: PGtkWidget) =
  gtk_menu_shell_append(cast[PGtkMenuShell](menu), child)

proc gtk_menu_prepend*(menu, child: PGtkWidget) =
  gtk_menu_shell_prepend(cast[PGtkMenuShell](menu), child)

proc gtk_menu_insert*(menu, child: PGtkWidget, pos: gint) =
  gtk_menu_shell_insert(cast[PGtkMenuShell](menu), child, pos)

proc GTK_TYPE_ENTRY*(): GType =
  result = gtk_entry_get_type()

proc GTK_ENTRY*(obj: pointer): PGtkEntry =
  result = cast[PGtkEntry](GTK_CHECK_CAST(obj, GTK_TYPE_ENTRY()))

proc GTK_ENTRY_CLASS*(klass: pointer): PGtkEntryClass =
  result = cast[PGtkEntryClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_ENTRY()))

proc GTK_IS_ENTRY*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_ENTRY())

proc GTK_IS_ENTRY_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_ENTRY())

proc GTK_ENTRY_GET_CLASS*(obj: pointer): PGtkEntryClass =
  result = cast[PGtkEntryClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_ENTRY()))

proc editable*(a: var TGtkEntry): guint =
  result = (a.GtkEntryflag0 and bm_TGtkEntry_editable) shr bp_TGtkEntry_editable

proc set_editable*(a: var TGtkEntry, `editable`: guint) =
  a.GtkEntryflag0 = a.GtkEntryflag0 or
      (int16(`editable` shl bp_TGtkEntry_editable) and bm_TGtkEntry_editable)

proc visible*(a: var TGtkEntry): guint =
  result = (a.GtkEntryflag0 and bm_TGtkEntry_visible) shr bp_TGtkEntry_visible

proc set_visible*(a: var TGtkEntry, `visible`: guint) =
  a.GtkEntryflag0 = a.GtkEntryflag0 or
      (int16(`visible` shl bp_TGtkEntry_visible) and bm_TGtkEntry_visible)

proc overwrite_mode*(a: var TGtkEntry): guint =
  result = (a.GtkEntryflag0 and bm_TGtkEntry_overwrite_mode) shr
      bp_TGtkEntry_overwrite_mode

proc set_overwrite_mode*(a: var TGtkEntry, `overwrite_mode`: guint) =
  a.GtkEntryflag0 = a.GtkEntryflag0 or
      (int16(`overwrite_mode` shl bp_TGtkEntry_overwrite_mode) and
      bm_TGtkEntry_overwrite_mode)

proc in_drag*(a: var TGtkEntry): guint =
  result = (a.GtkEntryflag0 and bm_TGtkEntry_in_drag) shr bp_TGtkEntry_in_drag

proc set_in_drag*(a: var TGtkEntry, `in_drag`: guint) =
  a.GtkEntryflag0 = a.GtkEntryflag0 or
      (int16(`in_drag` shl bp_TGtkEntry_in_drag) and bm_TGtkEntry_in_drag)

proc cache_includes_preedit*(a: var TGtkEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_cache_includes_preedit) shr
      bp_TGtkEntry_cache_includes_preedit

proc set_cache_includes_preedit*(a: var TGtkEntry,
                                 `cache_includes_preedit`: guint) =
  a.flag1 = a.flag1 or
      (int16(`cache_includes_preedit` shl bp_TGtkEntry_cache_includes_preedit) and
      bm_TGtkEntry_cache_includes_preedit)

proc need_im_reset*(a: var TGtkEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_need_im_reset) shr
      bp_TGtkEntry_need_im_reset

proc set_need_im_reset*(a: var TGtkEntry, `need_im_reset`: guint) =
  a.flag1 = a.flag1 or
      (int16(`need_im_reset` shl bp_TGtkEntry_need_im_reset) and
      bm_TGtkEntry_need_im_reset)

proc has_frame*(a: var TGtkEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_has_frame) shr bp_TGtkEntry_has_frame

proc set_has_frame*(a: var TGtkEntry, `has_frame`: guint) =
  a.flag1 = a.flag1 or
      (int16(`has_frame` shl bp_TGtkEntry_has_frame) and bm_TGtkEntry_has_frame)

proc activates_default*(a: var TGtkEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_activates_default) shr
      bp_TGtkEntry_activates_default

proc set_activates_default*(a: var TGtkEntry, `activates_default`: guint) =
  a.flag1 = a.flag1 or
      (int16(`activates_default` shl bp_TGtkEntry_activates_default) and
      bm_TGtkEntry_activates_default)

proc cursor_visible*(a: var TGtkEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_cursor_visible) shr
      bp_TGtkEntry_cursor_visible

proc set_cursor_visible*(a: var TGtkEntry, `cursor_visible`: guint) =
  a.flag1 = a.flag1 or
      (int16(`cursor_visible` shl bp_TGtkEntry_cursor_visible) and
      bm_TGtkEntry_cursor_visible)

proc in_click*(a: var TGtkEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_in_click) shr bp_TGtkEntry_in_click

proc set_in_click*(a: var TGtkEntry, `in_click`: guint) =
  a.flag1 = a.flag1 or
      (int16(`in_click` shl bp_TGtkEntry_in_click) and bm_TGtkEntry_in_click)

proc is_cell_renderer*(a: var TGtkEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_is_cell_renderer) shr
      bp_TGtkEntry_is_cell_renderer

proc set_is_cell_renderer*(a: var TGtkEntry, `is_cell_renderer`: guint) =
  a.flag1 = a.flag1 or
      (int16(`is_cell_renderer` shl bp_TGtkEntry_is_cell_renderer) and
      bm_TGtkEntry_is_cell_renderer)

proc editing_canceled*(a: var TGtkEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_editing_canceled) shr
      bp_TGtkEntry_editing_canceled

proc set_editing_canceled*(a: var TGtkEntry, `editing_canceled`: guint) =
  a.flag1 = a.flag1 or
      (int16(`editing_canceled` shl bp_TGtkEntry_editing_canceled) and
      bm_TGtkEntry_editing_canceled)

proc mouse_cursor_obscured*(a: var TGtkEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_mouse_cursor_obscured) shr
      bp_TGtkEntry_mouse_cursor_obscured

proc set_mouse_cursor_obscured*(a: var TGtkEntry, `mouse_cursor_obscured`: guint) =
  a.flag1 = a.flag1 or
      (int16(`mouse_cursor_obscured` shl bp_TGtkEntry_mouse_cursor_obscured) and
      bm_TGtkEntry_mouse_cursor_obscured)

proc GTK_TYPE_EVENT_BOX*(): GType =
  result = gtk_event_box_get_type()

proc GTK_EVENT_BOX*(obj: pointer): PGtkEventBox =
  result = cast[PGtkEventBox](GTK_CHECK_CAST(obj, GTK_TYPE_EVENT_BOX()))

proc GTK_EVENT_BOX_CLASS*(klass: pointer): PGtkEventBoxClass =
  result = cast[PGtkEventBoxClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_EVENT_BOX()))

proc GTK_IS_EVENT_BOX*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_EVENT_BOX())

proc GTK_IS_EVENT_BOX_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_EVENT_BOX())

proc GTK_EVENT_BOX_GET_CLASS*(obj: pointer): PGtkEventBoxClass =
  result = cast[PGtkEventBoxClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_EVENT_BOX()))

proc GTK_TYPE_FILE_SELECTION*(): GType =
  result = gtk_file_selection_get_type()

proc GTK_FILE_SELECTION*(obj: pointer): PGtkFileSelection =
  result = cast[PGtkFileSelection](GTK_CHECK_CAST(obj, GTK_TYPE_FILE_SELECTION()))

proc GTK_FILE_SELECTION_CLASS*(klass: pointer): PGtkFileSelectionClass =
  result = cast[PGtkFileSelectionClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_FILE_SELECTION()))

proc GTK_IS_FILE_SELECTION*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_FILE_SELECTION())

proc GTK_IS_FILE_SELECTION_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_FILE_SELECTION())

proc GTK_FILE_SELECTION_GET_CLASS*(obj: pointer): PGtkFileSelectionClass =
  result = cast[PGtkFileSelectionClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_FILE_SELECTION()))

proc GTK_TYPE_FIXED*(): GType =
  result = gtk_fixed_get_type()

proc GTK_FIXED*(obj: pointer): PGtkFixed =
  result = cast[PGtkFixed](GTK_CHECK_CAST(obj, GTK_TYPE_FIXED()))

proc GTK_FIXED_CLASS*(klass: pointer): PGtkFixedClass =
  result = cast[PGtkFixedClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_FIXED()))

proc GTK_IS_FIXED*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_FIXED())

proc GTK_IS_FIXED_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_FIXED())

proc GTK_FIXED_GET_CLASS*(obj: pointer): PGtkFixedClass =
  result = cast[PGtkFixedClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_FIXED()))

proc GTK_TYPE_FONT_SELECTION*(): GType =
  result = gtk_font_selection_get_type()

proc GTK_FONT_SELECTION*(obj: pointer): PGtkFontSelection =
  result = cast[PGtkFontSelection](GTK_CHECK_CAST(obj, GTK_TYPE_FONT_SELECTION()))

proc GTK_FONT_SELECTION_CLASS*(klass: pointer): PGtkFontSelectionClass =
  result = cast[PGtkFontSelectionClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_FONT_SELECTION()))

proc GTK_IS_FONT_SELECTION*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_FONT_SELECTION())

proc GTK_IS_FONT_SELECTION_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_FONT_SELECTION())

proc GTK_FONT_SELECTION_GET_CLASS*(obj: pointer): PGtkFontSelectionClass =
  result = cast[PGtkFontSelectionClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_FONT_SELECTION()))

proc GTK_TYPE_FONT_SELECTION_DIALOG*(): GType =
  result = gtk_font_selection_dialog_get_type()

proc GTK_FONT_SELECTION_DIALOG*(obj: pointer): PGtkFontSelectionDialog =
  result = cast[PGtkFontSelectionDialog](GTK_CHECK_CAST(obj,
      GTK_TYPE_FONT_SELECTION_DIALOG()))

proc GTK_FONT_SELECTION_DIALOG_CLASS*(klass: pointer): PGtkFontSelectionDialogClass =
  result = cast[PGtkFontSelectionDialogClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_FONT_SELECTION_DIALOG()))

proc GTK_IS_FONT_SELECTION_DIALOG*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_FONT_SELECTION_DIALOG())

proc GTK_IS_FONT_SELECTION_DIALOG_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_FONT_SELECTION_DIALOG())

proc GTK_FONT_SELECTION_DIALOG_GET_CLASS*(obj: pointer): PGtkFontSelectionDialogClass =
  result = cast[PGtkFontSelectionDialogClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_FONT_SELECTION_DIALOG()))

proc GTK_TYPE_GAMMA_CURVE*(): GType =
  result = gtk_gamma_curve_get_type()

proc GTK_GAMMA_CURVE*(obj: pointer): PGtkGammaCurve =
  result = cast[PGtkGammaCurve](GTK_CHECK_CAST(obj, GTK_TYPE_GAMMA_CURVE()))

proc GTK_GAMMA_CURVE_CLASS*(klass: pointer): PGtkGammaCurveClass =
  result = cast[PGtkGammaCurveClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_GAMMA_CURVE()))

proc GTK_IS_GAMMA_CURVE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_GAMMA_CURVE())

proc GTK_IS_GAMMA_CURVE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_GAMMA_CURVE())

proc GTK_GAMMA_CURVE_GET_CLASS*(obj: pointer): PGtkGammaCurveClass =
  result = cast[PGtkGammaCurveClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_GAMMA_CURVE()))

proc GTK_TYPE_HANDLE_BOX*(): GType =
  result = gtk_handle_box_get_type()

proc GTK_HANDLE_BOX*(obj: pointer): PGtkHandleBox =
  result = cast[PGtkHandleBox](GTK_CHECK_CAST(obj, GTK_TYPE_HANDLE_BOX()))

proc GTK_HANDLE_BOX_CLASS*(klass: pointer): PGtkHandleBoxClass =
  result = cast[PGtkHandleBoxClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_HANDLE_BOX()))

proc GTK_IS_HANDLE_BOX*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_HANDLE_BOX())

proc GTK_IS_HANDLE_BOX_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_HANDLE_BOX())

proc GTK_HANDLE_BOX_GET_CLASS*(obj: pointer): PGtkHandleBoxClass =
  result = cast[PGtkHandleBoxClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_HANDLE_BOX()))

proc handle_position*(a: var TGtkHandleBox): guint =
  result = (a.GtkHandleBoxflag0 and bm_TGtkHandleBox_handle_position) shr
      bp_TGtkHandleBox_handle_position

proc set_handle_position*(a: var TGtkHandleBox, `handle_position`: guint) =
  a.GtkHandleBoxflag0 = a.GtkHandleBoxflag0 or
      (int16(`handle_position` shl bp_TGtkHandleBox_handle_position) and
      bm_TGtkHandleBox_handle_position)

proc float_window_mapped*(a: var TGtkHandleBox): guint =
  result = (a.GtkHandleBoxflag0 and bm_TGtkHandleBox_float_window_mapped) shr
      bp_TGtkHandleBox_float_window_mapped

proc set_float_window_mapped*(a: var TGtkHandleBox, `float_window_mapped`: guint) =
  a.GtkHandleBoxflag0 = a.GtkHandleBoxflag0 or
      (int16(`float_window_mapped` shl bp_TGtkHandleBox_float_window_mapped) and
      bm_TGtkHandleBox_float_window_mapped)

proc child_detached*(a: var TGtkHandleBox): guint =
  result = (a.GtkHandleBoxflag0 and bm_TGtkHandleBox_child_detached) shr
      bp_TGtkHandleBox_child_detached

proc set_child_detached*(a: var TGtkHandleBox, `child_detached`: guint) =
  a.GtkHandleBoxflag0 = a.GtkHandleBoxflag0 or
      (int16(`child_detached` shl bp_TGtkHandleBox_child_detached) and
      bm_TGtkHandleBox_child_detached)

proc in_drag*(a: var TGtkHandleBox): guint =
  result = (a.GtkHandleBoxflag0 and bm_TGtkHandleBox_in_drag) shr
      bp_TGtkHandleBox_in_drag

proc set_in_drag*(a: var TGtkHandleBox, `in_drag`: guint) =
  a.GtkHandleBoxflag0 = a.GtkHandleBoxflag0 or
      (int16(`in_drag` shl bp_TGtkHandleBox_in_drag) and bm_TGtkHandleBox_in_drag)

proc shrink_on_detach*(a: var TGtkHandleBox): guint =
  result = (a.GtkHandleBoxflag0 and bm_TGtkHandleBox_shrink_on_detach) shr
      bp_TGtkHandleBox_shrink_on_detach

proc set_shrink_on_detach*(a: var TGtkHandleBox, `shrink_on_detach`: guint) =
  a.GtkHandleBoxflag0 = a.GtkHandleBoxflag0 or
      (int16(`shrink_on_detach` shl bp_TGtkHandleBox_shrink_on_detach) and
      bm_TGtkHandleBox_shrink_on_detach)

proc snap_edge*(a: var TGtkHandleBox): gint =
  result = (a.GtkHandleBoxflag0 and bm_TGtkHandleBox_snap_edge) shr
      bp_TGtkHandleBox_snap_edge

proc set_snap_edge*(a: var TGtkHandleBox, `snap_edge`: gint) =
  a.GtkHandleBoxflag0 = a.GtkHandleBoxflag0 or
      (int16(`snap_edge` shl bp_TGtkHandleBox_snap_edge) and
      bm_TGtkHandleBox_snap_edge)

proc GTK_TYPE_PANED*(): GType =
  result = gtk_paned_get_type()

proc GTK_PANED*(obj: pointer): PGtkPaned =
  result = cast[PGtkPaned](GTK_CHECK_CAST(obj, GTK_TYPE_PANED()))

proc GTK_PANED_CLASS*(klass: pointer): PGtkPanedClass =
  result = cast[PGtkPanedClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_PANED()))

proc GTK_IS_PANED*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_PANED())

proc GTK_IS_PANED_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_PANED())

proc GTK_PANED_GET_CLASS*(obj: pointer): PGtkPanedClass =
  result = cast[PGtkPanedClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_PANED()))

proc position_set*(a: var TGtkPaned): guint =
  result = (a.GtkPanedflag0 and bm_TGtkPaned_position_set) shr
      bp_TGtkPaned_position_set

proc set_position_set*(a: var TGtkPaned, `position_set`: guint) =
  a.GtkPanedflag0 = a.GtkPanedflag0 or
      (int16(`position_set` shl bp_TGtkPaned_position_set) and
      bm_TGtkPaned_position_set)

proc in_drag*(a: var TGtkPaned): guint =
  result = (a.GtkPanedflag0 and bm_TGtkPaned_in_drag) shr bp_TGtkPaned_in_drag

proc set_in_drag*(a: var TGtkPaned, `in_drag`: guint) =
  a.GtkPanedflag0 = a.GtkPanedflag0 or
      (int16(`in_drag` shl bp_TGtkPaned_in_drag) and bm_TGtkPaned_in_drag)

proc child1_shrink*(a: var TGtkPaned): guint =
  result = (a.GtkPanedflag0 and bm_TGtkPaned_child1_shrink) shr
      bp_TGtkPaned_child1_shrink

proc set_child1_shrink*(a: var TGtkPaned, `child1_shrink`: guint) =
  a.GtkPanedflag0 = a.GtkPanedflag0 or
      (int16(`child1_shrink` shl bp_TGtkPaned_child1_shrink) and
      bm_TGtkPaned_child1_shrink)

proc child1_resize*(a: var TGtkPaned): guint =
  result = (a.GtkPanedflag0 and bm_TGtkPaned_child1_resize) shr
      bp_TGtkPaned_child1_resize

proc set_child1_resize*(a: var TGtkPaned, `child1_resize`: guint) =
  a.GtkPanedflag0 = a.GtkPanedflag0 or
      (int16(`child1_resize` shl bp_TGtkPaned_child1_resize) and
      bm_TGtkPaned_child1_resize)

proc child2_shrink*(a: var TGtkPaned): guint =
  result = (a.GtkPanedflag0 and bm_TGtkPaned_child2_shrink) shr
      bp_TGtkPaned_child2_shrink

proc set_child2_shrink*(a: var TGtkPaned, `child2_shrink`: guint) =
  a.GtkPanedflag0 = a.GtkPanedflag0 or
      (int16(`child2_shrink` shl bp_TGtkPaned_child2_shrink) and
      bm_TGtkPaned_child2_shrink)

proc child2_resize*(a: var TGtkPaned): guint =
  result = (a.GtkPanedflag0 and bm_TGtkPaned_child2_resize) shr
      bp_TGtkPaned_child2_resize

proc set_child2_resize*(a: var TGtkPaned, `child2_resize`: guint) =
  a.GtkPanedflag0 = a.GtkPanedflag0 or
      (int16(`child2_resize` shl bp_TGtkPaned_child2_resize) and
      bm_TGtkPaned_child2_resize)

proc orientation*(a: var TGtkPaned): guint =
  result = (a.GtkPanedflag0 and bm_TGtkPaned_orientation) shr
      bp_TGtkPaned_orientation

proc set_orientation*(a: var TGtkPaned, `orientation`: guint) =
  a.GtkPanedflag0 = a.GtkPanedflag0 or
      (int16(`orientation` shl bp_TGtkPaned_orientation) and
      bm_TGtkPaned_orientation)

proc in_recursion*(a: var TGtkPaned): guint =
  result = (a.GtkPanedflag0 and bm_TGtkPaned_in_recursion) shr
      bp_TGtkPaned_in_recursion

proc set_in_recursion*(a: var TGtkPaned, `in_recursion`: guint) =
  a.GtkPanedflag0 = a.GtkPanedflag0 or
      (int16(`in_recursion` shl bp_TGtkPaned_in_recursion) and
      bm_TGtkPaned_in_recursion)

proc handle_prelit*(a: var TGtkPaned): guint =
  result = (a.GtkPanedflag0 and bm_TGtkPaned_handle_prelit) shr
      bp_TGtkPaned_handle_prelit

proc set_handle_prelit*(a: var TGtkPaned, `handle_prelit`: guint) =
  a.GtkPanedflag0 = a.GtkPanedflag0 or
      (int16(`handle_prelit` shl bp_TGtkPaned_handle_prelit) and
      bm_TGtkPaned_handle_prelit)

proc gtk_paned_gutter_size*(p: pointer, s: gint) =
  if (p != nil) and (s != 0'i32): nil

proc gtk_paned_set_gutter_size*(p: pointer, s: gint) =
  if (p != nil) and (s != 0'i32): nil

proc GTK_TYPE_HBUTTON_BOX*(): GType =
  result = gtk_hbutton_box_get_type()

proc GTK_HBUTTON_BOX*(obj: pointer): PGtkHButtonBox =
  result = cast[PGtkHButtonBox](GTK_CHECK_CAST(obj, GTK_TYPE_HBUTTON_BOX()))

proc GTK_HBUTTON_BOX_CLASS*(klass: pointer): PGtkHButtonBoxClass =
  result = cast[PGtkHButtonBoxClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_HBUTTON_BOX()))

proc GTK_IS_HBUTTON_BOX*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_HBUTTON_BOX())

proc GTK_IS_HBUTTON_BOX_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_HBUTTON_BOX())

proc GTK_HBUTTON_BOX_GET_CLASS*(obj: pointer): PGtkHButtonBoxClass =
  result = cast[PGtkHButtonBoxClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_HBUTTON_BOX()))

proc GTK_TYPE_HPANED*(): GType =
  result = gtk_hpaned_get_type()

proc GTK_HPANED*(obj: pointer): PGtkHPaned =
  result = cast[PGtkHPaned](GTK_CHECK_CAST(obj, GTK_TYPE_HPANED()))

proc GTK_HPANED_CLASS*(klass: pointer): PGtkHPanedClass =
  result = cast[PGtkHPanedClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_HPANED()))

proc GTK_IS_HPANED*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_HPANED())

proc GTK_IS_HPANED_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_HPANED())

proc GTK_HPANED_GET_CLASS*(obj: pointer): PGtkHPanedClass =
  result = cast[PGtkHPanedClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_HPANED()))

proc GTK_TYPE_RULER*(): GType =
  result = gtk_ruler_get_type()

proc GTK_RULER*(obj: pointer): PGtkRuler =
  result = cast[PGtkRuler](GTK_CHECK_CAST(obj, GTK_TYPE_RULER()))

proc GTK_RULER_CLASS*(klass: pointer): PGtkRulerClass =
  result = cast[PGtkRulerClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_RULER()))

proc GTK_IS_RULER*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_RULER())

proc GTK_IS_RULER_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_RULER())

proc GTK_RULER_GET_CLASS*(obj: pointer): PGtkRulerClass =
  result = cast[PGtkRulerClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_RULER()))

proc GTK_TYPE_HRULER*(): GType =
  result = gtk_hruler_get_type()

proc GTK_HRULER*(obj: pointer): PGtkHRuler =
  result = cast[PGtkHRuler](GTK_CHECK_CAST(obj, GTK_TYPE_HRULER()))

proc GTK_HRULER_CLASS*(klass: pointer): PGtkHRulerClass =
  result = cast[PGtkHRulerClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_HRULER()))

proc GTK_IS_HRULER*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_HRULER())

proc GTK_IS_HRULER_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_HRULER())

proc GTK_HRULER_GET_CLASS*(obj: pointer): PGtkHRulerClass =
  result = cast[PGtkHRulerClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_HRULER()))

proc GTK_TYPE_SETTINGS*(): GType =
  result = gtk_settings_get_type()

proc GTK_SETTINGS*(obj: pointer): PGtkSettings =
  result = cast[PGtkSettings](GTK_CHECK_CAST(obj, GTK_TYPE_SETTINGS()))

proc GTK_SETTINGS_CLASS*(klass: pointer): PGtkSettingsClass =
  result = cast[PGtkSettingsClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_SETTINGS()))

proc GTK_IS_SETTINGS*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_SETTINGS())

proc GTK_IS_SETTINGS_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_SETTINGS())

proc GTK_SETTINGS_GET_CLASS*(obj: pointer): PGtkSettingsClass =
  result = cast[PGtkSettingsClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_SETTINGS()))

proc GTK_TYPE_RC_STYLE*(): GType =
  result = gtk_rc_style_get_type()

proc GTK_RC_STYLE_get*(anObject: pointer): PGtkRcStyle =
  result = cast[PGtkRcStyle](G_TYPE_CHECK_INSTANCE_CAST(anObject, GTK_TYPE_RC_STYLE()))

proc GTK_RC_STYLE_CLASS*(klass: pointer): PGtkRcStyleClass =
  result = cast[PGtkRcStyleClass](G_TYPE_CHECK_CLASS_CAST(klass, GTK_TYPE_RC_STYLE()))

proc GTK_IS_RC_STYLE*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GTK_TYPE_RC_STYLE())

proc GTK_IS_RC_STYLE_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GTK_TYPE_RC_STYLE())

proc GTK_RC_STYLE_GET_CLASS*(obj: pointer): PGtkRcStyleClass =
  result = cast[PGtkRcStyleClass](G_TYPE_INSTANCE_GET_CLASS(obj, GTK_TYPE_RC_STYLE()))

proc engine_specified*(a: var TGtkRcStyle): guint =
  result = (a.GtkRcStyleflag0 and bm_TGtkRcStyle_engine_specified) shr
      bp_TGtkRcStyle_engine_specified

proc set_engine_specified*(a: var TGtkRcStyle, `engine_specified`: guint) =
  a.GtkRcStyleflag0 = a.GtkRcStyleflag0 or
      (int16(`engine_specified` shl bp_TGtkRcStyle_engine_specified) and
      bm_TGtkRcStyle_engine_specified)

proc GTK_TYPE_STYLE*(): GType =
  result = gtk_style_get_type()

proc GTK_STYLE*(anObject: pointer): PGtkStyle =
  result = cast[PGtkStyle](G_TYPE_CHECK_INSTANCE_CAST(anObject, GTK_TYPE_STYLE()))

proc GTK_STYLE_CLASS*(klass: pointer): PGtkStyleClass =
  result = cast[PGtkStyleClass](G_TYPE_CHECK_CLASS_CAST(klass, GTK_TYPE_STYLE()))

proc GTK_IS_STYLE*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GTK_TYPE_STYLE())

proc GTK_IS_STYLE_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GTK_TYPE_STYLE())

proc GTK_STYLE_GET_CLASS*(obj: pointer): PGtkStyleClass =
  result = cast[PGtkStyleClass](G_TYPE_INSTANCE_GET_CLASS(obj, GTK_TYPE_STYLE()))

proc GTK_TYPE_BORDER*(): GType =
  result = gtk_border_get_type()

proc GTK_STYLE_ATTACHED*(style: pointer): bool =
  result = ((GTK_STYLE(style)).attach_count) > 0'i32

proc gtk_style_apply_default_pixmap*(style: PGtkStyle, window: PGdkWindow,
                                     state_type: TGtkStateType,
                                     area: PGdkRectangle, x: gint, y: gint,
                                     width: gint, height: gint) =
  gtk_style_apply_default_background(style, window, true, state_type, area, x,
                                     y, width, height)

proc GTK_TYPE_RANGE*(): GType =
  result = gtk_range_get_type()

proc GTK_RANGE*(obj: pointer): PGtkRange =
  result = cast[PGtkRange](GTK_CHECK_CAST(obj, GTK_TYPE_RANGE()))

proc GTK_RANGE_CLASS*(klass: pointer): PGtkRangeClass =
  result = cast[PGtkRangeClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_RANGE()))

proc GTK_IS_RANGE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_RANGE())

proc GTK_IS_RANGE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_RANGE())

proc GTK_RANGE_GET_CLASS*(obj: pointer): PGtkRangeClass =
  result = cast[PGtkRangeClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_RANGE()))

proc inverted*(a: var TGtkRange): guint =
  result = (a.GtkRangeflag0 and bm_TGtkRange_inverted) shr bp_TGtkRange_inverted

proc set_inverted*(a: var TGtkRange, `inverted`: guint) =
  a.GtkRangeflag0 = a.GtkRangeflag0 or
      (int16(`inverted` shl bp_TGtkRange_inverted) and bm_TGtkRange_inverted)

proc flippable*(a: var TGtkRange): guint =
  result = (a.GtkRangeflag0 and bm_TGtkRange_flippable) shr bp_TGtkRange_flippable

proc set_flippable*(a: var TGtkRange, `flippable`: guint) =
  a.GtkRangeflag0 = a.GtkRangeflag0 or
      (int16(`flippable` shl bp_TGtkRange_flippable) and bm_TGtkRange_flippable)

proc has_stepper_a*(a: var TGtkRange): guint =
  result = (a.GtkRangeflag0 and bm_TGtkRange_has_stepper_a) shr
      bp_TGtkRange_has_stepper_a

proc set_has_stepper_a*(a: var TGtkRange, `has_stepper_a`: guint) =
  a.GtkRangeflag0 = a.GtkRangeflag0 or
      (int16(`has_stepper_a` shl bp_TGtkRange_has_stepper_a) and
      bm_TGtkRange_has_stepper_a)

proc has_stepper_b*(a: var TGtkRange): guint =
  result = (a.GtkRangeflag0 and bm_TGtkRange_has_stepper_b) shr
      bp_TGtkRange_has_stepper_b

proc set_has_stepper_b*(a: var TGtkRange, `has_stepper_b`: guint) =
  a.GtkRangeflag0 = a.GtkRangeflag0 or
      (int16(`has_stepper_b` shl bp_TGtkRange_has_stepper_b) and
      bm_TGtkRange_has_stepper_b)

proc has_stepper_c*(a: var TGtkRange): guint =
  result = (a.GtkRangeflag0 and bm_TGtkRange_has_stepper_c) shr
      bp_TGtkRange_has_stepper_c

proc set_has_stepper_c*(a: var TGtkRange, `has_stepper_c`: guint) =
  a.GtkRangeflag0 = a.GtkRangeflag0 or
      (int16(`has_stepper_c` shl bp_TGtkRange_has_stepper_c) and
      bm_TGtkRange_has_stepper_c)

proc has_stepper_d*(a: var TGtkRange): guint =
  result = (a.GtkRangeflag0 and bm_TGtkRange_has_stepper_d) shr
      bp_TGtkRange_has_stepper_d

proc set_has_stepper_d*(a: var TGtkRange, `has_stepper_d`: guint) =
  a.GtkRangeflag0 = a.GtkRangeflag0 or
      (int16(`has_stepper_d` shl bp_TGtkRange_has_stepper_d) and
      bm_TGtkRange_has_stepper_d)

proc need_recalc*(a: var TGtkRange): guint =
  result = (a.GtkRangeflag0 and bm_TGtkRange_need_recalc) shr
      bp_TGtkRange_need_recalc

proc set_need_recalc*(a: var TGtkRange, `need_recalc`: guint) =
  a.GtkRangeflag0 = a.GtkRangeflag0 or
      (int16(`need_recalc` shl bp_TGtkRange_need_recalc) and
      bm_TGtkRange_need_recalc)

proc slider_size_fixed*(a: var TGtkRange): guint =
  result = (a.GtkRangeflag0 and bm_TGtkRange_slider_size_fixed) shr
      bp_TGtkRange_slider_size_fixed

proc set_slider_size_fixed*(a: var TGtkRange, `slider_size_fixed`: guint) =
  a.GtkRangeflag0 = a.GtkRangeflag0 or
      (int16(`slider_size_fixed` shl bp_TGtkRange_slider_size_fixed) and
      bm_TGtkRange_slider_size_fixed)

proc trough_click_forward*(a: var TGtkRange): guint =
  result = (a.flag1 and bm_TGtkRange_trough_click_forward) shr
      bp_TGtkRange_trough_click_forward

proc set_trough_click_forward*(a: var TGtkRange, `trough_click_forward`: guint) =
  a.flag1 = a.flag1 or
      (int16(`trough_click_forward` shl bp_TGtkRange_trough_click_forward) and
      bm_TGtkRange_trough_click_forward)

proc update_pending*(a: var TGtkRange): guint =
  result = (a.flag1 and bm_TGtkRange_update_pending) shr
      bp_TGtkRange_update_pending

proc set_update_pending*(a: var TGtkRange, `update_pending`: guint) =
  a.flag1 = a.flag1 or
      (int16(`update_pending` shl bp_TGtkRange_update_pending) and
      bm_TGtkRange_update_pending)

proc GTK_TYPE_SCALE*(): GType =
  result = gtk_scale_get_type()

proc GTK_SCALE*(obj: pointer): PGtkScale =
  result = cast[PGtkScale](GTK_CHECK_CAST(obj, GTK_TYPE_SCALE()))

proc GTK_SCALE_CLASS*(klass: pointer): PGtkScaleClass =
  result = cast[PGtkScaleClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_SCALE()))

proc GTK_IS_SCALE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_SCALE())

proc GTK_IS_SCALE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_SCALE())

proc GTK_SCALE_GET_CLASS*(obj: pointer): PGtkScaleClass =
  result = cast[PGtkScaleClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_SCALE()))

proc draw_value*(a: var TGtkScale): guint =
  result = (a.GtkScaleflag0 and bm_TGtkScale_draw_value) shr bp_TGtkScale_draw_value

proc set_draw_value*(a: var TGtkScale, `draw_value`: guint) =
  a.GtkScaleflag0 = a.GtkScaleflag0 or
      (int16(`draw_value` shl bp_TGtkScale_draw_value) and bm_TGtkScale_draw_value)

proc value_pos*(a: var TGtkScale): guint =
  result = (a.GtkScaleflag0 and bm_TGtkScale_value_pos) shr bp_TGtkScale_value_pos

proc set_value_pos*(a: var TGtkScale, `value_pos`: guint) =
  a.GtkScaleflag0 = a.GtkScaleflag0 or
      (int16(`value_pos` shl bp_TGtkScale_value_pos) and bm_TGtkScale_value_pos)

proc GTK_TYPE_HSCALE*(): GType =
  result = gtk_hscale_get_type()

proc GTK_HSCALE*(obj: pointer): PGtkHScale =
  result = cast[PGtkHScale](GTK_CHECK_CAST(obj, GTK_TYPE_HSCALE()))

proc GTK_HSCALE_CLASS*(klass: pointer): PGtkHScaleClass =
  result = cast[PGtkHScaleClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_HSCALE()))

proc GTK_IS_HSCALE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_HSCALE())

proc GTK_IS_HSCALE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_HSCALE())

proc GTK_HSCALE_GET_CLASS*(obj: pointer): PGtkHScaleClass =
  result = cast[PGtkHScaleClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_HSCALE()))

proc GTK_TYPE_SCROLLBAR*(): GType =
  result = gtk_scrollbar_get_type()

proc GTK_SCROLLBAR*(obj: pointer): PGtkScrollbar =
  result = cast[PGtkScrollbar](GTK_CHECK_CAST(obj, GTK_TYPE_SCROLLBAR()))

proc GTK_SCROLLBAR_CLASS*(klass: pointer): PGtkScrollbarClass =
  result = cast[PGtkScrollbarClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_SCROLLBAR()))

proc GTK_IS_SCROLLBAR*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_SCROLLBAR())

proc GTK_IS_SCROLLBAR_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_SCROLLBAR())

proc GTK_SCROLLBAR_GET_CLASS*(obj: pointer): PGtkScrollbarClass =
  result = cast[PGtkScrollbarClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_SCROLLBAR()))

proc GTK_TYPE_HSCROLLBAR*(): GType =
  result = gtk_hscrollbar_get_type()

proc GTK_HSCROLLBAR*(obj: pointer): PGtkHScrollbar =
  result = cast[PGtkHScrollbar](GTK_CHECK_CAST(obj, GTK_TYPE_HSCROLLBAR()))

proc GTK_HSCROLLBAR_CLASS*(klass: pointer): PGtkHScrollbarClass =
  result = cast[PGtkHScrollbarClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_HSCROLLBAR()))

proc GTK_IS_HSCROLLBAR*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_HSCROLLBAR())

proc GTK_IS_HSCROLLBAR_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_HSCROLLBAR())

proc GTK_HSCROLLBAR_GET_CLASS*(obj: pointer): PGtkHScrollbarClass =
  result = cast[PGtkHScrollbarClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_HSCROLLBAR()))

proc GTK_TYPE_SEPARATOR*(): GType =
  result = gtk_separator_get_type()

proc GTK_SEPARATOR*(obj: pointer): PGtkSeparator =
  result = cast[PGtkSeparator](GTK_CHECK_CAST(obj, GTK_TYPE_SEPARATOR()))

proc GTK_SEPARATOR_CLASS*(klass: pointer): PGtkSeparatorClass =
  result = cast[PGtkSeparatorClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_SEPARATOR()))

proc GTK_IS_SEPARATOR*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_SEPARATOR())

proc GTK_IS_SEPARATOR_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_SEPARATOR())

proc GTK_SEPARATOR_GET_CLASS*(obj: pointer): PGtkSeparatorClass =
  result = cast[PGtkSeparatorClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_SEPARATOR()))

proc GTK_TYPE_HSEPARATOR*(): GType =
  result = gtk_hseparator_get_type()

proc GTK_HSEPARATOR*(obj: pointer): PGtkHSeparator =
  result = cast[PGtkHSeparator](GTK_CHECK_CAST(obj, GTK_TYPE_HSEPARATOR()))

proc GTK_HSEPARATOR_CLASS*(klass: pointer): PGtkHSeparatorClass =
  result = cast[PGtkHSeparatorClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_HSEPARATOR()))

proc GTK_IS_HSEPARATOR*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_HSEPARATOR())

proc GTK_IS_HSEPARATOR_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_HSEPARATOR())

proc GTK_HSEPARATOR_GET_CLASS*(obj: pointer): PGtkHSeparatorClass =
  result = cast[PGtkHSeparatorClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_HSEPARATOR()))

proc GTK_TYPE_ICON_FACTORY*(): GType =
  result = gtk_icon_factory_get_type()

proc GTK_ICON_FACTORY*(anObject: pointer): PGtkIconFactory =
  result = cast[PGtkIconFactory](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      GTK_TYPE_ICON_FACTORY()))

proc GTK_ICON_FACTORY_CLASS*(klass: pointer): PGtkIconFactoryClass =
  result = cast[PGtkIconFactoryClass](G_TYPE_CHECK_CLASS_CAST(klass,
      GTK_TYPE_ICON_FACTORY()))

proc GTK_IS_ICON_FACTORY*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GTK_TYPE_ICON_FACTORY())

proc GTK_IS_ICON_FACTORY_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GTK_TYPE_ICON_FACTORY())

proc GTK_ICON_FACTORY_GET_CLASS*(obj: pointer): PGtkIconFactoryClass =
  result = cast[PGtkIconFactoryClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      GTK_TYPE_ICON_FACTORY()))

proc GTK_TYPE_ICON_SET*(): GType =
  result = gtk_icon_set_get_type()

proc GTK_TYPE_ICON_SOURCE*(): GType =
  result = gtk_icon_source_get_type()

proc GTK_TYPE_IMAGE*(): GType =
  result = gtk_image_get_type()

proc GTK_IMAGE*(obj: pointer): PGtkImage =
  result = cast[PGtkImage](GTK_CHECK_CAST(obj, GTK_TYPE_IMAGE()))

proc GTK_IMAGE_CLASS*(klass: pointer): PGtkImageClass =
  result = cast[PGtkImageClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_IMAGE()))

proc GTK_IS_IMAGE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_IMAGE())

proc GTK_IS_IMAGE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_IMAGE())

proc GTK_IMAGE_GET_CLASS*(obj: pointer): PGtkImageClass =
  result = cast[PGtkImageClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_IMAGE()))

proc GTK_TYPE_IMAGE_MENU_ITEM*(): GType =
  result = gtk_image_menu_item_get_type()

proc GTK_IMAGE_MENU_ITEM*(obj: pointer): PGtkImageMenuItem =
  result = cast[PGtkImageMenuItem](GTK_CHECK_CAST(obj, GTK_TYPE_IMAGE_MENU_ITEM()))

proc GTK_IMAGE_MENU_ITEM_CLASS*(klass: pointer): PGtkImageMenuItemClass =
  result = cast[PGtkImageMenuItemClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_IMAGE_MENU_ITEM()))

proc GTK_IS_IMAGE_MENU_ITEM*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_IMAGE_MENU_ITEM())

proc GTK_IS_IMAGE_MENU_ITEM_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_IMAGE_MENU_ITEM())

proc GTK_IMAGE_MENU_ITEM_GET_CLASS*(obj: pointer): PGtkImageMenuItemClass =
  result = cast[PGtkImageMenuItemClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_IMAGE_MENU_ITEM()))

proc GTK_TYPE_IM_CONTEXT_SIMPLE*(): GType =
  result = gtk_im_context_simple_get_type()

proc GTK_IM_CONTEXT_SIMPLE*(obj: pointer): PGtkIMContextSimple =
  result = cast[PGtkIMContextSimple](GTK_CHECK_CAST(obj, GTK_TYPE_IM_CONTEXT_SIMPLE()))

proc GTK_IM_CONTEXT_SIMPLE_CLASS*(klass: pointer): PGtkIMContextSimpleClass =
  result = cast[PGtkIMContextSimpleClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_IM_CONTEXT_SIMPLE()))

proc GTK_IS_IM_CONTEXT_SIMPLE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_IM_CONTEXT_SIMPLE())

proc GTK_IS_IM_CONTEXT_SIMPLE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_IM_CONTEXT_SIMPLE())

proc GTK_IM_CONTEXT_SIMPLE_GET_CLASS*(obj: pointer): PGtkIMContextSimpleClass =
  result = cast[PGtkIMContextSimpleClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_IM_CONTEXT_SIMPLE()))

proc in_hex_sequence*(a: var TGtkIMContextSimple): guint =
  result = (a.GtkIMContextSimpleflag0 and bm_TGtkIMContextSimple_in_hex_sequence) shr
      bp_TGtkIMContextSimple_in_hex_sequence

proc set_in_hex_sequence*(a: var TGtkIMContextSimple, `in_hex_sequence`: guint) =
  a.GtkIMContextSimpleflag0 = a.GtkIMContextSimpleflag0 or
      (int16(`in_hex_sequence` shl bp_TGtkIMContextSimple_in_hex_sequence) and
      bm_TGtkIMContextSimple_in_hex_sequence)

proc GTK_TYPE_IM_MULTICONTEXT*(): GType =
  result = gtk_im_multicontext_get_type()

proc GTK_IM_MULTICONTEXT*(obj: pointer): PGtkIMMulticontext =
  result = cast[PGtkIMMulticontext](GTK_CHECK_CAST(obj, GTK_TYPE_IM_MULTICONTEXT()))

proc GTK_IM_MULTICONTEXT_CLASS*(klass: pointer): PGtkIMMulticontextClass =
  result = cast[PGtkIMMulticontextClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_IM_MULTICONTEXT()))

proc GTK_IS_IM_MULTICONTEXT*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_IM_MULTICONTEXT())

proc GTK_IS_IM_MULTICONTEXT_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_IM_MULTICONTEXT())

proc GTK_IM_MULTICONTEXT_GET_CLASS*(obj: pointer): PGtkIMMulticontextClass =
  result = cast[PGtkIMMulticontextClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_IM_MULTICONTEXT()))

proc GTK_TYPE_INPUT_DIALOG*(): GType =
  result = gtk_input_dialog_get_type()

proc GTK_INPUT_DIALOG*(obj: pointer): PGtkInputDialog =
  result = cast[PGtkInputDialog](GTK_CHECK_CAST(obj, GTK_TYPE_INPUT_DIALOG()))

proc GTK_INPUT_DIALOG_CLASS*(klass: pointer): PGtkInputDialogClass =
  result = cast[PGtkInputDialogClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_INPUT_DIALOG()))

proc GTK_IS_INPUT_DIALOG*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_INPUT_DIALOG())

proc GTK_IS_INPUT_DIALOG_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_INPUT_DIALOG())

proc GTK_INPUT_DIALOG_GET_CLASS*(obj: pointer): PGtkInputDialogClass =
  result = cast[PGtkInputDialogClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_INPUT_DIALOG()))

proc GTK_TYPE_INVISIBLE*(): GType =
  result = gtk_invisible_get_type()

proc GTK_INVISIBLE*(obj: pointer): PGtkInvisible =
  result = cast[PGtkInvisible](GTK_CHECK_CAST(obj, GTK_TYPE_INVISIBLE()))

proc GTK_INVISIBLE_CLASS*(klass: pointer): PGtkInvisibleClass =
  result = cast[PGtkInvisibleClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_INVISIBLE()))

proc GTK_IS_INVISIBLE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_INVISIBLE())

proc GTK_IS_INVISIBLE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_INVISIBLE())

proc GTK_INVISIBLE_GET_CLASS*(obj: pointer): PGtkInvisibleClass =
  result = cast[PGtkInvisibleClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_INVISIBLE()))

proc GTK_TYPE_ITEM_FACTORY*(): GType =
  result = gtk_item_factory_get_type()

proc GTK_ITEM_FACTORY*(anObject: pointer): PGtkItemFactory =
  result = cast[PGtkItemFactory](GTK_CHECK_CAST(anObject, GTK_TYPE_ITEM_FACTORY()))

proc GTK_ITEM_FACTORY_CLASS*(klass: pointer): PGtkItemFactoryClass =
  result = cast[PGtkItemFactoryClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_ITEM_FACTORY()))

proc GTK_IS_ITEM_FACTORY*(anObject: pointer): bool =
  result = GTK_CHECK_TYPE(anObject, GTK_TYPE_ITEM_FACTORY())

proc GTK_IS_ITEM_FACTORY_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_ITEM_FACTORY())

proc GTK_ITEM_FACTORY_GET_CLASS*(obj: pointer): PGtkItemFactoryClass =
  result = cast[PGtkItemFactoryClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_ITEM_FACTORY()))

proc GTK_TYPE_LAYOUT*(): GType =
  result = gtk_layout_get_type()

proc GTK_LAYOUT*(obj: pointer): PGtkLayout =
  result = cast[PGtkLayout](GTK_CHECK_CAST(obj, GTK_TYPE_LAYOUT()))

proc GTK_LAYOUT_CLASS*(klass: pointer): PGtkLayoutClass =
  result = cast[PGtkLayoutClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_LAYOUT()))

proc GTK_IS_LAYOUT*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_LAYOUT())

proc GTK_IS_LAYOUT_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_LAYOUT())

proc GTK_LAYOUT_GET_CLASS*(obj: pointer): PGtkLayoutClass =
  result = cast[PGtkLayoutClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_LAYOUT()))

proc GTK_TYPE_LIST*(): GType =
  result = gtk_list_get_type()

proc GTK_LIST*(obj: pointer): PGtkList =
  result = cast[PGtkList](GTK_CHECK_CAST(obj, GTK_TYPE_LIST()))

proc GTK_LIST_CLASS*(klass: pointer): PGtkListClass =
  result = cast[PGtkListClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_LIST()))

proc GTK_IS_LIST*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_LIST())

proc GTK_IS_LIST_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_LIST())

proc GTK_LIST_GET_CLASS*(obj: pointer): PGtkListClass =
  result = cast[PGtkListClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_LIST()))

proc selection_mode*(a: var TGtkList): guint =
  result = (a.GtkListflag0 and bm_TGtkList_selection_mode) shr
      bp_TGtkList_selection_mode

proc set_selection_mode*(a: var TGtkList, `selection_mode`: guint) =
  a.GtkListflag0 = a.GtkListflag0 or
      (int16(`selection_mode` shl bp_TGtkList_selection_mode) and
      bm_TGtkList_selection_mode)

proc drag_selection*(a: var TGtkList): guint =
  result = (a.GtkListflag0 and bm_TGtkList_drag_selection) shr
      bp_TGtkList_drag_selection

proc set_drag_selection*(a: var TGtkList, `drag_selection`: guint) =
  a.GtkListflag0 = a.GtkListflag0 or
      (int16(`drag_selection` shl bp_TGtkList_drag_selection) and
      bm_TGtkList_drag_selection)

proc add_mode*(a: var TGtkList): guint =
  result = (a.GtkListflag0 and bm_TGtkList_add_mode) shr bp_TGtkList_add_mode

proc set_add_mode*(a: var TGtkList, `add_mode`: guint) =
  a.GtkListflag0 = a.GtkListflag0 or
      (int16(`add_mode` shl bp_TGtkList_add_mode) and bm_TGtkList_add_mode)

proc gtk_list_item_get_type(): GType {.importc, cdecl, dynlib: gtklib.}

proc GTK_TYPE_LIST_ITEM*(): GType =
  result = gtk_list_item_get_type()

type
  TGtkListItem = object of TGtkItem
  TGtkListItemClass = object of TGtkItemClass
  PGtkListItem = ptr TGtkListItem
  PGtkListItemClass = ptr TGtkListItemClass

proc GTK_LIST_ITEM*(obj: pointer): PGtkListItem =
  result = cast[PGtkListItem](GTK_CHECK_CAST(obj, GTK_TYPE_LIST_ITEM()))

proc GTK_LIST_ITEM_CLASS*(klass: pointer): PGtkListItemClass =
  result = cast[PGtkListItemClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_LIST_ITEM()))

proc GTK_IS_LIST_ITEM*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_LIST_ITEM())

proc GTK_IS_LIST_ITEM_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_LIST_ITEM())

proc GTK_LIST_ITEM_GET_CLASS*(obj: pointer): PGtkListItemClass =
  result = cast[PGtkListItemClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_LIST_ITEM()))

#proc gtk_tree_model_get_type(): GType {.importc, cdecl, dynlib: gtklib.}

proc GTK_TYPE_TREE_MODEL*(): GType =
  result = gtk_tree_model_get_type()

proc GTK_TREE_MODEL*(obj: pointer): PGtkTreeModel =
  result = cast[PGtkTreeModel](G_TYPE_CHECK_INSTANCE_CAST(obj, GTK_TYPE_TREE_MODEL()))

proc GTK_IS_TREE_MODEL*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GTK_TYPE_TREE_MODEL())

proc GTK_TREE_MODEL_GET_IFACE*(obj: pointer): PGtkTreeModelIface =
  result = cast[PGtkTreeModelIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      GTK_TYPE_TREE_MODEL()))

proc GTK_TYPE_TREE_ITER*(): GType =
  result = gtk_tree_iter_get_type()

proc GTK_TYPE_TREE_PATH*(): GType =
  result = gtk_tree_path_get_type()

proc gtk_tree_path_new_root*(): PGtkTreePath =
  result = gtk_tree_path_new_first()

proc gtk_tree_model_get_iter_root*(tree_model: PGtkTreeModel, iter: PGtkTreeIter): gboolean =
  result = gtk_tree_model_get_iter_first(tree_model, iter)

proc GTK_TYPE_TREE_SORTABLE*(): GType =
  result = gtk_tree_sortable_get_type()

proc GTK_TREE_SORTABLE*(obj: pointer): PGtkTreeSortable =
  result = cast[PGtkTreeSortable](G_TYPE_CHECK_INSTANCE_CAST(obj,
      GTK_TYPE_TREE_SORTABLE()))

proc GTK_TREE_SORTABLE_CLASS*(obj: pointer): PGtkTreeSortableIface =
  result = cast[PGtkTreeSortableIface](G_TYPE_CHECK_CLASS_CAST(obj,
      GTK_TYPE_TREE_SORTABLE()))

proc GTK_IS_TREE_SORTABLE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GTK_TYPE_TREE_SORTABLE())

proc GTK_TREE_SORTABLE_GET_IFACE*(obj: pointer): PGtkTreeSortableIface =
  result = cast[PGtkTreeSortableIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      GTK_TYPE_TREE_SORTABLE()))

proc GTK_TYPE_TREE_MODEL_SORT*(): GType =
  result = gtk_tree_model_sort_get_type()

proc GTK_TREE_MODEL_SORT*(obj: pointer): PGtkTreeModelSort =
  result = cast[PGtkTreeModelSort](GTK_CHECK_CAST(obj, GTK_TYPE_TREE_MODEL_SORT()))

proc GTK_TREE_MODEL_SORT_CLASS*(klass: pointer): PGtkTreeModelSortClass =
  result = cast[PGtkTreeModelSortClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_TREE_MODEL_SORT()))

proc GTK_IS_TREE_MODEL_SORT*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TREE_MODEL_SORT())

proc GTK_IS_TREE_MODEL_SORT_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TREE_MODEL_SORT())

proc GTK_TREE_MODEL_SORT_GET_CLASS*(obj: pointer): PGtkTreeModelSortClass =
  result = cast[PGtkTreeModelSortClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_TREE_MODEL_SORT()))

proc GTK_TYPE_LIST_STORE*(): GType =
  result = gtk_list_store_get_type()

proc GTK_LIST_STORE*(obj: pointer): PGtkListStore =
  result = cast[PGtkListStore](GTK_CHECK_CAST(obj, GTK_TYPE_LIST_STORE()))

proc GTK_LIST_STORE_CLASS*(klass: pointer): PGtkListStoreClass =
  result = cast[PGtkListStoreClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_LIST_STORE()))

proc GTK_IS_LIST_STORE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_LIST_STORE())

proc GTK_IS_LIST_STORE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_LIST_STORE())

proc GTK_LIST_STORE_GET_CLASS*(obj: pointer): PGtkListStoreClass =
  result = cast[PGtkListStoreClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_LIST_STORE()))

proc columns_dirty*(a: var TGtkListStore): guint =
  result = (a.GtkListStoreflag0 and bm_TGtkListStore_columns_dirty) shr
      bp_TGtkListStore_columns_dirty

proc set_columns_dirty*(a: var TGtkListStore, `columns_dirty`: guint) =
  a.GtkListStoreflag0 = a.GtkListStoreflag0 or
      (int16(`columns_dirty` shl bp_TGtkListStore_columns_dirty) and
      bm_TGtkListStore_columns_dirty)

proc GTK_TYPE_MENU_BAR*(): GType =
  result = gtk_menu_bar_get_type()

proc GTK_MENU_BAR*(obj: pointer): PGtkMenuBar =
  result = cast[PGtkMenuBar](GTK_CHECK_CAST(obj, GTK_TYPE_MENU_BAR()))

proc GTK_MENU_BAR_CLASS*(klass: pointer): PGtkMenuBarClass =
  result = cast[PGtkMenuBarClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_MENU_BAR()))

proc GTK_IS_MENU_BAR*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_MENU_BAR())

proc GTK_IS_MENU_BAR_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_MENU_BAR())

proc GTK_MENU_BAR_GET_CLASS*(obj: pointer): PGtkMenuBarClass =
  result = cast[PGtkMenuBarClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_MENU_BAR()))

proc gtk_menu_bar_append*(menu, child: PGtkWidget) =
  gtk_menu_shell_append(cast[PGtkMenuShell](menu), child)

proc gtk_menu_bar_prepend*(menu, child: PGtkWidget) =
  gtk_menu_shell_prepend(cast[PGtkMenuShell](menu), child)

proc gtk_menu_bar_insert*(menu, child: PGtkWidget, pos: gint) =
  gtk_menu_shell_insert(cast[PGtkMenuShell](menu), child, pos)

proc GTK_TYPE_MESSAGE_DIALOG*(): GType =
  result = gtk_message_dialog_get_type()

proc GTK_MESSAGE_DIALOG*(obj: pointer): PGtkMessageDialog =
  result = cast[PGtkMessageDialog](GTK_CHECK_CAST(obj, GTK_TYPE_MESSAGE_DIALOG()))

proc GTK_MESSAGE_DIALOG_CLASS*(klass: pointer): PGtkMessageDialogClass =
  result = cast[PGtkMessageDialogClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_MESSAGE_DIALOG()))

proc GTK_IS_MESSAGE_DIALOG*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_MESSAGE_DIALOG())

proc GTK_IS_MESSAGE_DIALOG_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_MESSAGE_DIALOG())

proc GTK_MESSAGE_DIALOG_GET_CLASS*(obj: pointer): PGtkMessageDialogClass =
  result = cast[PGtkMessageDialogClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_MESSAGE_DIALOG()))

proc GTK_TYPE_NOTEBOOK*(): GType =
  result = gtk_notebook_get_type()

proc GTK_NOTEBOOK*(obj: pointer): PGtkNotebook =
  result = cast[PGtkNotebook](GTK_CHECK_CAST(obj, GTK_TYPE_NOTEBOOK()))

proc GTK_NOTEBOOK_CLASS*(klass: pointer): PGtkNotebookClass =
  result = cast[PGtkNotebookClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_NOTEBOOK()))

proc GTK_IS_NOTEBOOK*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_NOTEBOOK())

proc GTK_IS_NOTEBOOK_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_NOTEBOOK())

proc GTK_NOTEBOOK_GET_CLASS*(obj: pointer): PGtkNotebookClass =
  result = cast[PGtkNotebookClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_NOTEBOOK()))

proc show_tabs*(a: var TGtkNotebook): guint =
  result = (a.GtkNotebookflag0 and bm_TGtkNotebook_show_tabs) shr
      bp_TGtkNotebook_show_tabs

proc set_show_tabs*(a: var TGtkNotebook, `show_tabs`: guint) =
  a.GtkNotebookflag0 = a.GtkNotebookflag0 or
      (int16(`show_tabs` shl bp_TGtkNotebook_show_tabs) and
      bm_TGtkNotebook_show_tabs)

proc homogeneous*(a: var TGtkNotebook): guint =
  result = (a.GtkNotebookflag0 and bm_TGtkNotebook_homogeneous) shr
      bp_TGtkNotebook_homogeneous

proc set_homogeneous*(a: var TGtkNotebook, `homogeneous`: guint) =
  a.GtkNotebookflag0 = a.GtkNotebookflag0 or
      (int16(`homogeneous` shl bp_TGtkNotebook_homogeneous) and
      bm_TGtkNotebook_homogeneous)

proc show_border*(a: var TGtkNotebook): guint =
  result = (a.GtkNotebookflag0 and bm_TGtkNotebook_show_border) shr
      bp_TGtkNotebook_show_border

proc set_show_border*(a: var TGtkNotebook, `show_border`: guint) =
  a.GtkNotebookflag0 = a.GtkNotebookflag0 or
      (int16(`show_border` shl bp_TGtkNotebook_show_border) and
      bm_TGtkNotebook_show_border)

proc tab_pos*(a: var TGtkNotebook): guint =
  result = (a.GtkNotebookflag0 and bm_TGtkNotebook_tab_pos) shr bp_TGtkNotebook_tab_pos

proc set_tab_pos*(a: var TGtkNotebook, `tab_pos`: guint) =
  a.GtkNotebookflag0 = a.GtkNotebookflag0 or
      (int16(`tab_pos` shl bp_TGtkNotebook_tab_pos) and bm_TGtkNotebook_tab_pos)

proc scrollable*(a: var TGtkNotebook): guint =
  result = (a.GtkNotebookflag0 and bm_TGtkNotebook_scrollable) shr
      bp_TGtkNotebook_scrollable

proc set_scrollable*(a: var TGtkNotebook, `scrollable`: guint) =
  a.GtkNotebookflag0 = a.GtkNotebookflag0 or
      (int16(`scrollable` shl bp_TGtkNotebook_scrollable) and
      bm_TGtkNotebook_scrollable)

proc in_child*(a: var TGtkNotebook): guint =
  result = (a.GtkNotebookflag0 and bm_TGtkNotebook_in_child) shr
      bp_TGtkNotebook_in_child

proc set_in_child*(a: var TGtkNotebook, `in_child`: guint) =
  a.GtkNotebookflag0 = a.GtkNotebookflag0 or
      (int16(`in_child` shl bp_TGtkNotebook_in_child) and bm_TGtkNotebook_in_child)

proc click_child*(a: var TGtkNotebook): guint =
  result = (a.GtkNotebookflag0 and bm_TGtkNotebook_click_child) shr
      bp_TGtkNotebook_click_child

proc set_click_child*(a: var TGtkNotebook, `click_child`: guint) =
  a.GtkNotebookflag0 = a.GtkNotebookflag0 or
      (int16(`click_child` shl bp_TGtkNotebook_click_child) and
      bm_TGtkNotebook_click_child)

proc button*(a: var TGtkNotebook): guint =
  result = (a.GtkNotebookflag0 and bm_TGtkNotebook_button) shr bp_TGtkNotebook_button

proc set_button*(a: var TGtkNotebook, `button`: guint) =
  a.GtkNotebookflag0 = a.GtkNotebookflag0 or
      (int16(`button` shl bp_TGtkNotebook_button) and bm_TGtkNotebook_button)

proc need_timer*(a: var TGtkNotebook): guint =
  result = (a.GtkNotebookflag0 and bm_TGtkNotebook_need_timer) shr
      bp_TGtkNotebook_need_timer

proc set_need_timer*(a: var TGtkNotebook, `need_timer`: guint) =
  a.GtkNotebookflag0 = a.GtkNotebookflag0 or
      (int16(`need_timer` shl bp_TGtkNotebook_need_timer) and
      bm_TGtkNotebook_need_timer)

proc child_has_focus*(a: var TGtkNotebook): guint =
  result = (a.GtkNotebookflag0 and bm_TGtkNotebook_child_has_focus) shr
      bp_TGtkNotebook_child_has_focus

proc set_child_has_focus*(a: var TGtkNotebook, `child_has_focus`: guint) =
  a.GtkNotebookflag0 = a.GtkNotebookflag0 or
      (int16(`child_has_focus` shl bp_TGtkNotebook_child_has_focus) and
      bm_TGtkNotebook_child_has_focus)

proc have_visible_child*(a: var TGtkNotebook): guint =
  result = (a.GtkNotebookflag0 and bm_TGtkNotebook_have_visible_child) shr
      bp_TGtkNotebook_have_visible_child

proc set_have_visible_child*(a: var TGtkNotebook, `have_visible_child`: guint) =
  a.GtkNotebookflag0 = a.GtkNotebookflag0 or
      (int16(`have_visible_child` shl bp_TGtkNotebook_have_visible_child) and
      bm_TGtkNotebook_have_visible_child)

proc focus_out*(a: var TGtkNotebook): guint =
  result = (a.GtkNotebookflag0 and bm_TGtkNotebook_focus_out) shr
      bp_TGtkNotebook_focus_out

proc set_focus_out*(a: var TGtkNotebook, `focus_out`: guint) =
  a.GtkNotebookflag0 = a.GtkNotebookflag0 or
      (int16(`focus_out` shl bp_TGtkNotebook_focus_out) and
      bm_TGtkNotebook_focus_out)

proc GTK_TYPE_OLD_EDITABLE*(): GType =
  result = gtk_old_editable_get_type()

proc GTK_OLD_EDITABLE*(obj: pointer): PGtkOldEditable =
  result = cast[PGtkOldEditable](GTK_CHECK_CAST(obj, GTK_TYPE_OLD_EDITABLE()))

proc GTK_OLD_EDITABLE_CLASS*(klass: pointer): PGtkOldEditableClass =
  result = cast[PGtkOldEditableClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_OLD_EDITABLE()))

proc GTK_IS_OLD_EDITABLE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_OLD_EDITABLE())

proc GTK_IS_OLD_EDITABLE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_OLD_EDITABLE())

proc GTK_OLD_EDITABLE_GET_CLASS*(obj: pointer): PGtkOldEditableClass =
  result = cast[PGtkOldEditableClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_OLD_EDITABLE()))

proc has_selection*(a: var TGtkOldEditable): guint =
  result = (a.GtkOldEditableflag0 and bm_TGtkOldEditable_has_selection) shr
      bp_TGtkOldEditable_has_selection

proc set_has_selection*(a: var TGtkOldEditable, `has_selection`: guint) =
  a.GtkOldEditableflag0 = a.GtkOldEditableflag0 or
      (int16(`has_selection` shl bp_TGtkOldEditable_has_selection) and
      bm_TGtkOldEditable_has_selection)

proc editable*(a: var TGtkOldEditable): guint =
  result = (a.GtkOldEditableflag0 and bm_TGtkOldEditable_editable) shr
      bp_TGtkOldEditable_editable

proc set_editable*(a: var TGtkOldEditable, `editable`: guint) =
  a.GtkOldEditableflag0 = a.GtkOldEditableflag0 or
      (int16(`editable` shl bp_TGtkOldEditable_editable) and
      bm_TGtkOldEditable_editable)

proc visible*(a: var TGtkOldEditable): guint =
  result = (a.GtkOldEditableflag0 and bm_TGtkOldEditable_visible) shr
      bp_TGtkOldEditable_visible

proc set_visible*(a: var TGtkOldEditable, `visible`: guint) =
  a.GtkOldEditableflag0 = a.GtkOldEditableflag0 or
      (int16(`visible` shl bp_TGtkOldEditable_visible) and
      bm_TGtkOldEditable_visible)

proc GTK_TYPE_OPTION_MENU*(): GType =
  result = gtk_option_menu_get_type()

proc GTK_OPTION_MENU*(obj: pointer): PGtkOptionMenu =
  result = cast[PGtkOptionMenu](GTK_CHECK_CAST(obj, GTK_TYPE_OPTION_MENU()))

proc GTK_OPTION_MENU_CLASS*(klass: pointer): PGtkOptionMenuClass =
  result = cast[PGtkOptionMenuClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_OPTION_MENU()))

proc GTK_IS_OPTION_MENU*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_OPTION_MENU())

proc GTK_IS_OPTION_MENU_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_OPTION_MENU())

proc GTK_OPTION_MENU_GET_CLASS*(obj: pointer): PGtkOptionMenuClass =
  result = cast[PGtkOptionMenuClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_OPTION_MENU()))

proc GTK_TYPE_PIXMAP*(): GType =
  result = gtk_pixmap_get_type()

proc GTK_PIXMAP*(obj: pointer): PGtkPixmap =
  result = cast[PGtkPixmap](GTK_CHECK_CAST(obj, GTK_TYPE_PIXMAP()))

proc GTK_PIXMAP_CLASS*(klass: pointer): PGtkPixmapClass =
  result = cast[PGtkPixmapClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_PIXMAP()))

proc GTK_IS_PIXMAP*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_PIXMAP())

proc GTK_IS_PIXMAP_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_PIXMAP())

proc GTK_PIXMAP_GET_CLASS*(obj: pointer): PGtkPixmapClass =
  result = cast[PGtkPixmapClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_PIXMAP()))

proc build_insensitive*(a: var TGtkPixmap): guint =
  result = (a.GtkPixmapflag0 and bm_TGtkPixmap_build_insensitive) shr
      bp_TGtkPixmap_build_insensitive

proc set_build_insensitive*(a: var TGtkPixmap, `build_insensitive`: guint) =
  a.GtkPixmapflag0 = a.GtkPixmapflag0 or
      (int16(`build_insensitive` shl bp_TGtkPixmap_build_insensitive) and
      bm_TGtkPixmap_build_insensitive)

proc GTK_TYPE_PLUG*(): GType =
  result = gtk_plug_get_type()

proc GTK_PLUG*(obj: pointer): PGtkPlug =
  result = cast[PGtkPlug](GTK_CHECK_CAST(obj, GTK_TYPE_PLUG()))

proc GTK_PLUG_CLASS*(klass: pointer): PGtkPlugClass =
  result = cast[PGtkPlugClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_PLUG()))

proc GTK_IS_PLUG*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_PLUG())

proc GTK_IS_PLUG_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_PLUG())

proc GTK_PLUG_GET_CLASS*(obj: pointer): PGtkPlugClass =
  result = cast[PGtkPlugClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_PLUG()))

proc same_app*(a: var TGtkPlug): guint =
  result = (a.GtkPlugflag0 and bm_TGtkPlug_same_app) shr bp_TGtkPlug_same_app

proc set_same_app*(a: var TGtkPlug, `same_app`: guint) =
  a.GtkPlugflag0 = a.GtkPlugflag0 or
      (int16(`same_app` shl bp_TGtkPlug_same_app) and bm_TGtkPlug_same_app)

proc GTK_TYPE_PREVIEW*(): GType =
  result = gtk_preview_get_type()

proc GTK_PREVIEW*(obj: pointer): PGtkPreview =
  result = cast[PGtkPreview](GTK_CHECK_CAST(obj, GTK_TYPE_PREVIEW()))

proc GTK_PREVIEW_CLASS*(klass: pointer): PGtkPreviewClass =
  result = cast[PGtkPreviewClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_PREVIEW()))

proc GTK_IS_PREVIEW*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_PREVIEW())

proc GTK_IS_PREVIEW_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_PREVIEW())

proc GTK_PREVIEW_GET_CLASS*(obj: pointer): PGtkPreviewClass =
  result = cast[PGtkPreviewClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_PREVIEW()))

proc get_type*(a: var TGtkPreview): guint =
  result = (a.GtkPreviewflag0 and bm_TGtkPreview_type) shr bp_TGtkPreview_type

proc set_type*(a: var TGtkPreview, `type`: guint) =
  a.GtkPreviewflag0 = a.GtkPreviewflag0 or
      (int16(`type` shl bp_TGtkPreview_type) and bm_TGtkPreview_type)

proc get_expand*(a: var TGtkPreview): guint =
  result = (a.GtkPreviewflag0 and bm_TGtkPreview_expand) shr bp_TGtkPreview_expand

proc set_expand*(a: var TGtkPreview, `expand`: guint) =
  a.GtkPreviewflag0 = a.GtkPreviewflag0 or
      (int16(`expand` shl bp_TGtkPreview_expand) and bm_TGtkPreview_expand)

proc gtk_progress_get_type(): GType {.importc, cdecl, dynlib: gtklib.}

proc GTK_TYPE_PROGRESS*(): GType =
  result = gtk_progress_get_type()

proc GTK_PROGRESS*(obj: pointer): PGtkProgress =
  result = cast[PGtkProgress](GTK_CHECK_CAST(obj, GTK_TYPE_PROGRESS()))

proc GTK_PROGRESS_CLASS*(klass: pointer): PGtkProgressClass =
  result = cast[PGtkProgressClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_PROGRESS()))

proc GTK_IS_PROGRESS*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_PROGRESS())

proc GTK_IS_PROGRESS_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_PROGRESS())

proc GTK_PROGRESS_GET_CLASS*(obj: pointer): PGtkProgressClass =
  result = cast[PGtkProgressClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_PROGRESS()))

proc show_text*(a: var TGtkProgress): guint =
  result = (a.GtkProgressflag0 and bm_TGtkProgress_show_text) shr
      bp_TGtkProgress_show_text

proc set_show_text*(a: var TGtkProgress, `show_text`: guint) =
  a.GtkProgressflag0 = a.GtkProgressflag0 or
      (int16(`show_text` shl bp_TGtkProgress_show_text) and
      bm_TGtkProgress_show_text)

proc activity_mode*(a: var TGtkProgress): guint =
  result = (a.GtkProgressflag0 and bm_TGtkProgress_activity_mode) shr
      bp_TGtkProgress_activity_mode

proc set_activity_mode*(a: var TGtkProgress, `activity_mode`: guint) =
  a.GtkProgressflag0 = a.GtkProgressflag0 or
      (int16(`activity_mode` shl bp_TGtkProgress_activity_mode) and
      bm_TGtkProgress_activity_mode)

proc use_text_format*(a: var TGtkProgress): guint =
  result = (a.GtkProgressflag0 and bm_TGtkProgress_use_text_format) shr
      bp_TGtkProgress_use_text_format

proc set_use_text_format*(a: var TGtkProgress, `use_text_format`: guint) =
  a.GtkProgressflag0 = a.GtkProgressflag0 or
      (int16(`use_text_format` shl bp_TGtkProgress_use_text_format) and
      bm_TGtkProgress_use_text_format)

proc GTK_TYPE_PROGRESS_BAR*(): GType =
  result = gtk_progress_bar_get_type()

proc GTK_PROGRESS_BAR*(obj: pointer): PGtkProgressBar =
  result = cast[PGtkProgressBar](GTK_CHECK_CAST(obj, GTK_TYPE_PROGRESS_BAR()))

proc GTK_PROGRESS_BAR_CLASS*(klass: pointer): PGtkProgressBarClass =
  result = cast[PGtkProgressBarClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_PROGRESS_BAR()))

proc GTK_IS_PROGRESS_BAR*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_PROGRESS_BAR())

proc GTK_IS_PROGRESS_BAR_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_PROGRESS_BAR())

proc GTK_PROGRESS_BAR_GET_CLASS*(obj: pointer): PGtkProgressBarClass =
  result = cast[PGtkProgressBarClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_PROGRESS_BAR()))

proc activity_dir*(a: var TGtkProgressBar): guint =
  result = (a.GtkProgressBarflag0 and bm_TGtkProgressBar_activity_dir) shr
      bp_TGtkProgressBar_activity_dir

proc set_activity_dir*(a: var TGtkProgressBar, `activity_dir`: guint) =
  a.GtkProgressBarflag0 = a.GtkProgressBarflag0 or
      (int16(`activity_dir` shl bp_TGtkProgressBar_activity_dir) and
      bm_TGtkProgressBar_activity_dir)

proc GTK_TYPE_RADIO_BUTTON*(): GType =
  result = gtk_radio_button_get_type()

proc GTK_RADIO_BUTTON*(obj: pointer): PGtkRadioButton =
  result = cast[PGtkRadioButton](GTK_CHECK_CAST(obj, GTK_TYPE_RADIO_BUTTON()))

proc GTK_RADIO_BUTTON_CLASS*(klass: pointer): PGtkRadioButtonClass =
  result = cast[PGtkRadioButtonClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_RADIO_BUTTON()))

proc GTK_IS_RADIO_BUTTON*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_RADIO_BUTTON())

proc GTK_IS_RADIO_BUTTON_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_RADIO_BUTTON())

proc GTK_RADIO_BUTTON_GET_CLASS*(obj: pointer): PGtkRadioButtonClass =
  result = cast[PGtkRadioButtonClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_RADIO_BUTTON()))

proc GTK_TYPE_RADIO_MENU_ITEM*(): GType =
  result = gtk_radio_menu_item_get_type()

proc GTK_RADIO_MENU_ITEM*(obj: pointer): PGtkRadioMenuItem =
  result = cast[PGtkRadioMenuItem](GTK_CHECK_CAST(obj, GTK_TYPE_RADIO_MENU_ITEM()))

proc GTK_RADIO_MENU_ITEM_CLASS*(klass: pointer): PGtkRadioMenuItemClass =
  result = cast[PGtkRadioMenuItemClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_RADIO_MENU_ITEM()))

proc GTK_IS_RADIO_MENU_ITEM*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_RADIO_MENU_ITEM())

proc GTK_IS_RADIO_MENU_ITEM_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_RADIO_MENU_ITEM())

proc GTK_RADIO_MENU_ITEM_GET_CLASS*(obj: pointer): PGtkRadioMenuItemClass =
  result = cast[PGtkRadioMenuItemClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_RADIO_MENU_ITEM()))

proc GTK_TYPE_SCROLLED_WINDOW*(): GType =
  result = gtk_scrolled_window_get_type()

proc GTK_SCROLLED_WINDOW*(obj: pointer): PGtkScrolledWindow =
  result = cast[PGtkScrolledWindow](GTK_CHECK_CAST(obj, GTK_TYPE_SCROLLED_WINDOW()))

proc GTK_SCROLLED_WINDOW_CLASS*(klass: pointer): PGtkScrolledWindowClass =
  result = cast[PGtkScrolledWindowClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_SCROLLED_WINDOW()))

proc GTK_IS_SCROLLED_WINDOW*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_SCROLLED_WINDOW())

proc GTK_IS_SCROLLED_WINDOW_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_SCROLLED_WINDOW())

proc GTK_SCROLLED_WINDOW_GET_CLASS*(obj: pointer): PGtkScrolledWindowClass =
  result = cast[PGtkScrolledWindowClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_SCROLLED_WINDOW()))

proc hscrollbar_policy*(a: var TGtkScrolledWindow): guint =
  result = (a.GtkScrolledWindowflag0 and bm_TGtkScrolledWindow_hscrollbar_policy) shr
      bp_TGtkScrolledWindow_hscrollbar_policy

proc set_hscrollbar_policy*(a: var TGtkScrolledWindow,
                            `hscrollbar_policy`: guint) =
  a.GtkScrolledWindowflag0 = a.GtkScrolledWindowflag0 or
      (int16(`hscrollbar_policy` shl bp_TGtkScrolledWindow_hscrollbar_policy) and
      bm_TGtkScrolledWindow_hscrollbar_policy)

proc vscrollbar_policy*(a: var TGtkScrolledWindow): guint =
  result = (a.GtkScrolledWindowflag0 and bm_TGtkScrolledWindow_vscrollbar_policy) shr
      bp_TGtkScrolledWindow_vscrollbar_policy

proc set_vscrollbar_policy*(a: var TGtkScrolledWindow,
                            `vscrollbar_policy`: guint) =
  a.GtkScrolledWindowflag0 = a.GtkScrolledWindowflag0 or
      (int16(`vscrollbar_policy` shl bp_TGtkScrolledWindow_vscrollbar_policy) and
      bm_TGtkScrolledWindow_vscrollbar_policy)

proc hscrollbar_visible*(a: var TGtkScrolledWindow): guint =
  result = (a.GtkScrolledWindowflag0 and bm_TGtkScrolledWindow_hscrollbar_visible) shr
      bp_TGtkScrolledWindow_hscrollbar_visible

proc set_hscrollbar_visible*(a: var TGtkScrolledWindow,
                             `hscrollbar_visible`: guint) =
  a.GtkScrolledWindowflag0 = a.GtkScrolledWindowflag0 or
      (int16(`hscrollbar_visible` shl bp_TGtkScrolledWindow_hscrollbar_visible) and
      bm_TGtkScrolledWindow_hscrollbar_visible)

proc vscrollbar_visible*(a: var TGtkScrolledWindow): guint =
  result = (a.GtkScrolledWindowflag0 and bm_TGtkScrolledWindow_vscrollbar_visible) shr
      bp_TGtkScrolledWindow_vscrollbar_visible

proc set_vscrollbar_visible*(a: var TGtkScrolledWindow,
                             `vscrollbar_visible`: guint) =
  a.GtkScrolledWindowflag0 = a.GtkScrolledWindowflag0 or
      int16((`vscrollbar_visible` shl bp_TGtkScrolledWindow_vscrollbar_visible) and
      bm_TGtkScrolledWindow_vscrollbar_visible)

proc window_placement*(a: var TGtkScrolledWindow): guint =
  result = (a.GtkScrolledWindowflag0 and bm_TGtkScrolledWindow_window_placement) shr
      bp_TGtkScrolledWindow_window_placement

proc set_window_placement*(a: var TGtkScrolledWindow, `window_placement`: guint) =
  a.GtkScrolledWindowflag0 = a.GtkScrolledWindowflag0 or
      (int16(`window_placement` shl bp_TGtkScrolledWindow_window_placement) and
      bm_TGtkScrolledWindow_window_placement)

proc focus_out*(a: var TGtkScrolledWindow): guint =
  result = (a.GtkScrolledWindowflag0 and bm_TGtkScrolledWindow_focus_out) shr
      bp_TGtkScrolledWindow_focus_out

proc set_focus_out*(a: var TGtkScrolledWindow, `focus_out`: guint) =
  a.GtkScrolledWindowflag0 = a.GtkScrolledWindowflag0 or
      (int16(`focus_out` shl bp_TGtkScrolledWindow_focus_out) and
      bm_TGtkScrolledWindow_focus_out)

proc GTK_TYPE_SELECTION_DATA*(): GType =
  result = gtk_selection_data_get_type()

proc GTK_TYPE_SEPARATOR_MENU_ITEM*(): GType =
  result = gtk_separator_menu_item_get_type()

proc GTK_SEPARATOR_MENU_ITEM*(obj: pointer): PGtkSeparatorMenuItem =
  result = cast[PGtkSeparatorMenuItem](GTK_CHECK_CAST(obj,
      GTK_TYPE_SEPARATOR_MENU_ITEM()))

proc GTK_SEPARATOR_MENU_ITEM_CLASS*(klass: pointer): PGtkSeparatorMenuItemClass =
  result = cast[PGtkSeparatorMenuItemClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_SEPARATOR_MENU_ITEM()))

proc GTK_IS_SEPARATOR_MENU_ITEM*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_SEPARATOR_MENU_ITEM())

proc GTK_IS_SEPARATOR_MENU_ITEM_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_SEPARATOR_MENU_ITEM())

proc GTK_SEPARATOR_MENU_ITEM_GET_CLASS*(obj: pointer): PGtkSeparatorMenuItemClass =
  result = cast[PGtkSeparatorMenuItemClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_SEPARATOR_MENU_ITEM()))

proc gtk_signal_lookup*(name: cstring, object_type: GType): guint =
  result = g_signal_lookup(name, object_type)

proc gtk_signal_name*(signal_id: guint): cstring =
  result = g_signal_name(signal_id)

proc gtk_signal_emit_stop*(instance: gpointer, signal_id: guint, detail: TGQuark) =
  if detail != 0'i32: g_signal_stop_emission(instance, signal_id, 0)

proc gtk_signal_connect_full*(anObject: PGtkObject, name: cstring,
                         fun: TGtkSignalFunc, unknown1: pointer,
                         func_data: gpointer, unknown2: pointer,
                         unknown3, unknown4: int): gulong {.
  importc, cdecl, dynlib: gtklib.}

proc gtk_signal_compat_matched*(anObject: PGtkObject, fun: TGtkSignalFunc,
                                data: gpointer, m: TGSignalMatchType,
                                u: int) {.importc, cdecl, dynlib: gtklib.}

proc gtk_signal_connect*(anObject: PGtkObject, name: cstring,
                         fun: TGtkSignalFunc, func_data: gpointer): gulong =
  result = gtk_signal_connect_full(anObject, name, fun, nil, func_data, nil,
                                   0, 0)

proc gtk_signal_connect_after*(anObject: PGtkObject, name: cstring,
                               fun: TGtkSignalFunc, func_data: gpointer): gulong =
  result = gtk_signal_connect_full(anObject, name, fun, nil, func_data, nil,
                                   0, 1)

proc gtk_signal_connect_object*(anObject: PGtkObject, name: cstring,
                                fun: TGtkSignalFunc, slot_object: gpointer): gulong =
  result = gtk_signal_connect_full(anObject, name, fun, nil, slot_object, nil,
                                   1, 0)

proc gtk_signal_connect_object_after*(anObject: PGtkObject, name: cstring,
                                      fun: TGtkSignalFunc,
                                      slot_object: gpointer): gulong =
  result = gtk_signal_connect_full(anObject, name, fun, nil, slot_object, nil,
                                   1, 1)

proc gtk_signal_disconnect*(anObject: gpointer, handler_id: gulong) =
  g_signal_handler_disconnect(anObject, handler_id)

proc gtk_signal_handler_block*(anObject: gpointer, handler_id: gulong) =
  g_signal_handler_block(anObject, handler_id)

proc gtk_signal_handler_unblock*(anObject: gpointer, handler_id: gulong) =
  g_signal_handler_unblock(anObject, handler_id)

proc gtk_signal_disconnect_by_data*(anObject: PGtkObject, data: gpointer) =
  gtk_signal_compat_matched(anObject, nil, data, G_SIGNAL_MATCH_DATA, 0)

proc gtk_signal_disconnect_by_func*(anObject: PGtkObject, fun: TGtkSignalFunc,
                                    data: gpointer) =
  gtk_signal_compat_matched(anObject, fun, data, cast[TGSignalMatchType](
      G_SIGNAL_MATCH_FUNC or G_SIGNAL_MATCH_DATA), 0)

proc gtk_signal_handler_block_by_func*(anObject: PGtkObject,
                                       fun: TGtkSignalFunc, data: gpointer) =
  gtk_signal_compat_matched(anObject, fun, data, TGSignalMatchType(
      G_SIGNAL_MATCH_FUNC or G_SIGNAL_MATCH_DATA), 0)

proc gtk_signal_handler_block_by_data*(anObject: PGtkObject, data: gpointer) =
  gtk_signal_compat_matched(anObject, nil, data, G_SIGNAL_MATCH_DATA, 1)

proc gtk_signal_handler_unblock_by_func*(anObject: PGtkObject,
    fun: TGtkSignalFunc, data: gpointer) =
  gtk_signal_compat_matched(anObject, fun, data, cast[TGSignalMatchType](
      G_SIGNAL_MATCH_FUNC or G_SIGNAL_MATCH_DATA), 0)

proc gtk_signal_handler_unblock_by_data*(anObject: PGtkObject, data: gpointer) =
  gtk_signal_compat_matched(anObject, nil, data, G_SIGNAL_MATCH_DATA, 2)

proc gtk_signal_handler_pending*(anObject: PGtkObject, signal_id: guint,
                                 may_be_blocked: gboolean): gboolean =
  Result = g_signal_has_handler_pending(anObject, signal_id, 0, may_be_blocked)

proc gtk_signal_handler_pending_by_func*(anObject: PGtkObject, signal_id: guint,
    may_be_blocked: gboolean, fun: TGtkSignalFunc, data: gpointer): gboolean =
  var t: TGSignalMatchType
  t = cast[TGSignalMatchType](G_SIGNAL_MATCH_ID or G_SIGNAL_MATCH_FUNC or
      G_SIGNAL_MATCH_DATA)
  if not may_be_blocked:
    t = t or cast[TGSignalMatchType](G_SIGNAL_MATCH_UNBLOCKED)
  Result = g_signal_handler_find(anObject, t, signal_id, 0, nil, fun,
                                 data) != 0

proc GTK_TYPE_SIZE_GROUP*(): GType =
  result = gtk_size_group_get_type()

proc GTK_SIZE_GROUP*(obj: pointer): PGtkSizeGroup =
  result = cast[PGtkSizeGroup](GTK_CHECK_CAST(obj, GTK_TYPE_SIZE_GROUP()))

proc GTK_SIZE_GROUP_CLASS*(klass: pointer): PGtkSizeGroupClass =
  result = cast[PGtkSizeGroupClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_SIZE_GROUP()))

proc GTK_IS_SIZE_GROUP*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_SIZE_GROUP())

proc GTK_IS_SIZE_GROUP_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_SIZE_GROUP())

proc GTK_SIZE_GROUP_GET_CLASS*(obj: pointer): PGtkSizeGroupClass =
  result = cast[PGtkSizeGroupClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_SIZE_GROUP()))

proc have_width*(a: var TGtkSizeGroup): guint =
  result = (a.GtkSizeGroupflag0 and bm_TGtkSizeGroup_have_width) shr
      bp_TGtkSizeGroup_have_width

proc set_have_width*(a: var TGtkSizeGroup, `have_width`: guint) =
  a.GtkSizeGroupflag0 = a.GtkSizeGroupflag0 or
      (int16(`have_width` shl bp_TGtkSizeGroup_have_width) and
      bm_TGtkSizeGroup_have_width)

proc have_height*(a: var TGtkSizeGroup): guint =
  result = (a.GtkSizeGroupflag0 and bm_TGtkSizeGroup_have_height) shr
      bp_TGtkSizeGroup_have_height

proc set_have_height*(a: var TGtkSizeGroup, `have_height`: guint) =
  a.GtkSizeGroupflag0 = a.GtkSizeGroupflag0 or
      (int16(`have_height` shl bp_TGtkSizeGroup_have_height) and
      bm_TGtkSizeGroup_have_height)

proc GTK_TYPE_SOCKET*(): GType =
  result = gtk_socket_get_type()

proc GTK_SOCKET*(obj: pointer): PGtkSocket =
  result = cast[PGtkSocket](GTK_CHECK_CAST(obj, GTK_TYPE_SOCKET()))

proc GTK_SOCKET_CLASS*(klass: pointer): PGtkSocketClass =
  result = cast[PGtkSocketClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_SOCKET()))

proc GTK_IS_SOCKET*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_SOCKET())

proc GTK_IS_SOCKET_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_SOCKET())

proc GTK_SOCKET_GET_CLASS*(obj: pointer): PGtkSocketClass =
  result = cast[PGtkSocketClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_SOCKET()))

proc same_app*(a: var TGtkSocket): guint =
  result = (a.GtkSocketflag0 and bm_TGtkSocket_same_app) shr bp_TGtkSocket_same_app

proc set_same_app*(a: var TGtkSocket, `same_app`: guint) =
  a.GtkSocketflag0 = a.GtkSocketflag0 or
      (int16(`same_app` shl bp_TGtkSocket_same_app) and bm_TGtkSocket_same_app)

proc focus_in*(a: var TGtkSocket): guint =
  result = (a.GtkSocketflag0 and bm_TGtkSocket_focus_in) shr bp_TGtkSocket_focus_in

proc set_focus_in*(a: var TGtkSocket, `focus_in`: guint) =
  a.GtkSocketflag0 = a.GtkSocketflag0 or
      (int16(`focus_in` shl bp_TGtkSocket_focus_in) and bm_TGtkSocket_focus_in)

proc have_size*(a: var TGtkSocket): guint =
  result = (a.GtkSocketflag0 and bm_TGtkSocket_have_size) shr bp_TGtkSocket_have_size

proc set_have_size*(a: var TGtkSocket, `have_size`: guint) =
  a.GtkSocketflag0 = a.GtkSocketflag0 or
      (int16(`have_size` shl bp_TGtkSocket_have_size) and bm_TGtkSocket_have_size)

proc need_map*(a: var TGtkSocket): guint =
  result = (a.GtkSocketflag0 and bm_TGtkSocket_need_map) shr bp_TGtkSocket_need_map

proc set_need_map*(a: var TGtkSocket, `need_map`: guint) =
  a.GtkSocketflag0 = a.GtkSocketflag0 or
      (int16(`need_map` shl bp_TGtkSocket_need_map) and bm_TGtkSocket_need_map)

proc is_mapped*(a: var TGtkSocket): guint =
  result = (a.GtkSocketflag0 and bm_TGtkSocket_is_mapped) shr bp_TGtkSocket_is_mapped

proc set_is_mapped*(a: var TGtkSocket, `is_mapped`: guint) =
  a.GtkSocketflag0 = a.GtkSocketflag0 or
      (int16(`is_mapped` shl bp_TGtkSocket_is_mapped) and bm_TGtkSocket_is_mapped)

proc GTK_TYPE_SPIN_BUTTON*(): GType =
  result = gtk_spin_button_get_type()

proc GTK_SPIN_BUTTON*(obj: pointer): PGtkSpinButton =
  result = cast[PGtkSpinButton](GTK_CHECK_CAST(obj, GTK_TYPE_SPIN_BUTTON()))

proc GTK_SPIN_BUTTON_CLASS*(klass: pointer): PGtkSpinButtonClass =
  result = cast[PGtkSpinButtonClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_SPIN_BUTTON()))

proc GTK_IS_SPIN_BUTTON*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_SPIN_BUTTON())

proc GTK_IS_SPIN_BUTTON_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_SPIN_BUTTON())

proc GTK_SPIN_BUTTON_GET_CLASS*(obj: pointer): PGtkSpinButtonClass =
  result = cast[PGtkSpinButtonClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_SPIN_BUTTON()))

proc in_child*(a: var TGtkSpinButton): guint =
  result = (a.GtkSpinButtonflag0 and bm_TGtkSpinButton_in_child) shr
      bp_TGtkSpinButton_in_child

proc set_in_child*(a: var TGtkSpinButton, `in_child`: guint) =
  a.GtkSpinButtonflag0 = a.GtkSpinButtonflag0 or
      ((`in_child` shl bp_TGtkSpinButton_in_child) and
      bm_TGtkSpinButton_in_child)

proc click_child*(a: var TGtkSpinButton): guint =
  result = (a.GtkSpinButtonflag0 and bm_TGtkSpinButton_click_child) shr
      bp_TGtkSpinButton_click_child

proc set_click_child*(a: var TGtkSpinButton, `click_child`: guint) =
  a.GtkSpinButtonflag0 = a.GtkSpinButtonflag0 or
      ((`click_child` shl bp_TGtkSpinButton_click_child) and
      bm_TGtkSpinButton_click_child)

proc button*(a: var TGtkSpinButton): guint =
  result = (a.GtkSpinButtonflag0 and bm_TGtkSpinButton_button) shr
      bp_TGtkSpinButton_button

proc set_button*(a: var TGtkSpinButton, `button`: guint) =
  a.GtkSpinButtonflag0 = a.GtkSpinButtonflag0 or
      ((`button` shl bp_TGtkSpinButton_button) and bm_TGtkSpinButton_button)

proc need_timer*(a: var TGtkSpinButton): guint =
  result = (a.GtkSpinButtonflag0 and bm_TGtkSpinButton_need_timer) shr
      bp_TGtkSpinButton_need_timer

proc set_need_timer*(a: var TGtkSpinButton, `need_timer`: guint) =
  a.GtkSpinButtonflag0 = a.GtkSpinButtonflag0 or
      ((`need_timer` shl bp_TGtkSpinButton_need_timer) and
      bm_TGtkSpinButton_need_timer)

proc timer_calls*(a: var TGtkSpinButton): guint =
  result = (a.GtkSpinButtonflag0 and bm_TGtkSpinButton_timer_calls) shr
      bp_TGtkSpinButton_timer_calls

proc set_timer_calls*(a: var TGtkSpinButton, `timer_calls`: guint) =
  a.GtkSpinButtonflag0 = a.GtkSpinButtonflag0 or
      ((`timer_calls` shl bp_TGtkSpinButton_timer_calls) and
      bm_TGtkSpinButton_timer_calls)

proc digits*(a: var TGtkSpinButton): guint =
  result = (a.GtkSpinButtonflag0 and bm_TGtkSpinButton_digits) shr
      bp_TGtkSpinButton_digits

proc set_digits*(a: var TGtkSpinButton, `digits`: guint) =
  a.GtkSpinButtonflag0 = a.GtkSpinButtonflag0 or
      ((`digits` shl bp_TGtkSpinButton_digits) and bm_TGtkSpinButton_digits)

proc numeric*(a: var TGtkSpinButton): guint =
  result = (a.GtkSpinButtonflag0 and bm_TGtkSpinButton_numeric) shr
      bp_TGtkSpinButton_numeric

proc set_numeric*(a: var TGtkSpinButton, `numeric`: guint) =
  a.GtkSpinButtonflag0 = a.GtkSpinButtonflag0 or
      ((`numeric` shl bp_TGtkSpinButton_numeric) and
      bm_TGtkSpinButton_numeric)

proc wrap*(a: var TGtkSpinButton): guint =
  result = (a.GtkSpinButtonflag0 and bm_TGtkSpinButton_wrap) shr bp_TGtkSpinButton_wrap

proc set_wrap*(a: var TGtkSpinButton, `wrap`: guint) =
  a.GtkSpinButtonflag0 = a.GtkSpinButtonflag0 or
      ((`wrap` shl bp_TGtkSpinButton_wrap) and bm_TGtkSpinButton_wrap)

proc snap_to_ticks*(a: var TGtkSpinButton): guint =
  result = (a.GtkSpinButtonflag0 and bm_TGtkSpinButton_snap_to_ticks) shr
      bp_TGtkSpinButton_snap_to_ticks

proc set_snap_to_ticks*(a: var TGtkSpinButton, `snap_to_ticks`: guint) =
  a.GtkSpinButtonflag0 = a.GtkSpinButtonflag0 or
      ((`snap_to_ticks` shl bp_TGtkSpinButton_snap_to_ticks) and
      bm_TGtkSpinButton_snap_to_ticks)

proc GTK_TYPE_STATUSBAR*(): GType =
  result = gtk_statusbar_get_type()

proc GTK_STATUSBAR*(obj: pointer): PGtkStatusbar =
  result = cast[PGtkStatusbar](GTK_CHECK_CAST(obj, GTK_TYPE_STATUSBAR()))

proc GTK_STATUSBAR_CLASS*(klass: pointer): PGtkStatusbarClass =
  result = cast[PGtkStatusbarClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_STATUSBAR()))

proc GTK_IS_STATUSBAR*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_STATUSBAR())

proc GTK_IS_STATUSBAR_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_STATUSBAR())

proc GTK_STATUSBAR_GET_CLASS*(obj: pointer): PGtkStatusbarClass =
  result = cast[PGtkStatusbarClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_STATUSBAR()))

proc has_resize_grip*(a: var TGtkStatusbar): guint =
  result = (a.GtkStatusbarflag0 and bm_TGtkStatusbar_has_resize_grip) shr
      bp_TGtkStatusbar_has_resize_grip

proc set_has_resize_grip*(a: var TGtkStatusbar, `has_resize_grip`: guint) =
  a.GtkStatusbarflag0 = a.GtkStatusbarflag0 or
      (int16(`has_resize_grip` shl bp_TGtkStatusbar_has_resize_grip) and
      bm_TGtkStatusbar_has_resize_grip)

proc GTK_TYPE_TABLE*(): GType =
  result = gtk_table_get_type()

proc GTK_TABLE*(obj: pointer): PGtkTable =
  result = cast[PGtkTable](GTK_CHECK_CAST(obj, GTK_TYPE_TABLE()))

proc GTK_TABLE_CLASS*(klass: pointer): PGtkTableClass =
  result = cast[PGtkTableClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_TABLE()))

proc GTK_IS_TABLE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TABLE())

proc GTK_IS_TABLE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TABLE())

proc GTK_TABLE_GET_CLASS*(obj: pointer): PGtkTableClass =
  result = cast[PGtkTableClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_TABLE()))

proc homogeneous*(a: var TGtkTable): guint =
  result = (a.GtkTableflag0 and bm_TGtkTable_homogeneous) shr
      bp_TGtkTable_homogeneous

proc set_homogeneous*(a: var TGtkTable, `homogeneous`: guint) =
  a.GtkTableflag0 = a.GtkTableflag0 or
      (int16(`homogeneous` shl bp_TGtkTable_homogeneous) and
      bm_TGtkTable_homogeneous)

proc xexpand*(a: var TGtkTableChild): guint =
  result = (a.GtkTableChildflag0 and bm_TGtkTableChild_xexpand) shr
      bp_TGtkTableChild_xexpand

proc set_xexpand*(a: var TGtkTableChild, `xexpand`: guint) =
  a.GtkTableChildflag0 = a.GtkTableChildflag0 or
      (int16(`xexpand` shl bp_TGtkTableChild_xexpand) and
      bm_TGtkTableChild_xexpand)

proc yexpand*(a: var TGtkTableChild): guint =
  result = (a.GtkTableChildflag0 and bm_TGtkTableChild_yexpand) shr
      bp_TGtkTableChild_yexpand

proc set_yexpand*(a: var TGtkTableChild, `yexpand`: guint) =
  a.GtkTableChildflag0 = a.GtkTableChildflag0 or
      (int16(`yexpand` shl bp_TGtkTableChild_yexpand) and
      bm_TGtkTableChild_yexpand)

proc xshrink*(a: var TGtkTableChild): guint =
  result = (a.GtkTableChildflag0 and bm_TGtkTableChild_xshrink) shr
      bp_TGtkTableChild_xshrink

proc set_xshrink*(a: var TGtkTableChild, `xshrink`: guint) =
  a.GtkTableChildflag0 = a.GtkTableChildflag0 or
      (int16(`xshrink` shl bp_TGtkTableChild_xshrink) and
      bm_TGtkTableChild_xshrink)

proc yshrink*(a: var TGtkTableChild): guint =
  result = (a.GtkTableChildflag0 and bm_TGtkTableChild_yshrink) shr
      bp_TGtkTableChild_yshrink

proc set_yshrink*(a: var TGtkTableChild, `yshrink`: guint) =
  a.GtkTableChildflag0 = a.GtkTableChildflag0 or
      (int16(`yshrink` shl bp_TGtkTableChild_yshrink) and
      bm_TGtkTableChild_yshrink)

proc xfill*(a: var TGtkTableChild): guint =
  result = (a.GtkTableChildflag0 and bm_TGtkTableChild_xfill) shr bp_TGtkTableChild_xfill

proc set_xfill*(a: var TGtkTableChild, `xfill`: guint) =
  a.GtkTableChildflag0 = a.GtkTableChildflag0 or
      (int16(`xfill` shl bp_TGtkTableChild_xfill) and bm_TGtkTableChild_xfill)

proc yfill*(a: var TGtkTableChild): guint =
  result = (a.GtkTableChildflag0 and bm_TGtkTableChild_yfill) shr bp_TGtkTableChild_yfill

proc set_yfill*(a: var TGtkTableChild, `yfill`: guint) =
  a.GtkTableChildflag0 = a.GtkTableChildflag0 or
      (int16(`yfill` shl bp_TGtkTableChild_yfill) and bm_TGtkTableChild_yfill)

proc need_expand*(a: var TGtkTableRowCol): guint =
  result = (a.flag0 and bm_TGtkTableRowCol_need_expand) shr
      bp_TGtkTableRowCol_need_expand

proc set_need_expand*(a: var TGtkTableRowCol, `need_expand`: guint) =
  a.flag0 = a.flag0 or
      (int16(`need_expand` shl bp_TGtkTableRowCol_need_expand) and
      bm_TGtkTableRowCol_need_expand)

proc need_shrink*(a: var TGtkTableRowCol): guint =
  result = (a.flag0 and bm_TGtkTableRowCol_need_shrink) shr
      bp_TGtkTableRowCol_need_shrink

proc set_need_shrink*(a: var TGtkTableRowCol, `need_shrink`: guint) =
  a.flag0 = a.flag0 or
      (int16(`need_shrink` shl bp_TGtkTableRowCol_need_shrink) and
      bm_TGtkTableRowCol_need_shrink)

proc expand*(a: var TGtkTableRowCol): guint =
  result = (a.flag0 and bm_TGtkTableRowCol_expand) shr
      bp_TGtkTableRowCol_expand

proc set_expand*(a: var TGtkTableRowCol, `expand`: guint) =
  a.flag0 = a.flag0 or
      (int16(`expand` shl bp_TGtkTableRowCol_expand) and bm_TGtkTableRowCol_expand)

proc shrink*(a: var TGtkTableRowCol): guint =
  result = (a.flag0 and bm_TGtkTableRowCol_shrink) shr
      bp_TGtkTableRowCol_shrink

proc set_shrink*(a: var TGtkTableRowCol, `shrink`: guint) =
  a.flag0 = a.flag0 or
      (int16(`shrink` shl bp_TGtkTableRowCol_shrink) and bm_TGtkTableRowCol_shrink)

proc empty*(a: var TGtkTableRowCol): guint =
  result = (a.flag0 and bm_TGtkTableRowCol_empty) shr
      bp_TGtkTableRowCol_empty

proc set_empty*(a: var TGtkTableRowCol, `empty`: guint) =
  a.flag0 = a.flag0 or
      (int16(`empty` shl bp_TGtkTableRowCol_empty) and bm_TGtkTableRowCol_empty)

proc GTK_TYPE_TEAROFF_MENU_ITEM*(): GType =
  result = gtk_tearoff_menu_item_get_type()

proc GTK_TEAROFF_MENU_ITEM*(obj: pointer): PGtkTearoffMenuItem =
  result = cast[PGtkTearoffMenuItem](GTK_CHECK_CAST(obj, GTK_TYPE_TEAROFF_MENU_ITEM()))

proc GTK_TEAROFF_MENU_ITEM_CLASS*(klass: pointer): PGtkTearoffMenuItemClass =
  result = cast[PGtkTearoffMenuItemClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_TEAROFF_MENU_ITEM()))

proc GTK_IS_TEAROFF_MENU_ITEM*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TEAROFF_MENU_ITEM())

proc GTK_IS_TEAROFF_MENU_ITEM_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TEAROFF_MENU_ITEM())

proc GTK_TEAROFF_MENU_ITEM_GET_CLASS*(obj: pointer): PGtkTearoffMenuItemClass =
  result = cast[PGtkTearoffMenuItemClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_TEAROFF_MENU_ITEM()))

proc torn_off*(a: var TGtkTearoffMenuItem): guint =
  result = (a.GtkTearoffMenuItemflag0 and bm_TGtkTearoffMenuItem_torn_off) shr
      bp_TGtkTearoffMenuItem_torn_off

proc set_torn_off*(a: var TGtkTearoffMenuItem, `torn_off`: guint) =
  a.GtkTearoffMenuItemflag0 = a.GtkTearoffMenuItemflag0 or
      (int16(`torn_off` shl bp_TGtkTearoffMenuItem_torn_off) and
      bm_TGtkTearoffMenuItem_torn_off)

proc GTK_TYPE_TEXT*(): GType =
  result = gtk_text_get_type()

proc GTK_TEXT*(obj: pointer): PGtkText =
  result = cast[PGtkText](GTK_CHECK_CAST(obj, GTK_TYPE_TEXT()))

proc GTK_TEXT_CLASS*(klass: pointer): PGtkTextClass =
  result = cast[PGtkTextClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_TEXT()))

proc GTK_IS_TEXT*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TEXT())

proc GTK_IS_TEXT_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TEXT())

proc GTK_TEXT_GET_CLASS*(obj: pointer): PGtkTextClass =
  result = cast[PGtkTextClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_TEXT()))

proc line_wrap*(a: PGtkText): guint =
  result = (a.GtkTextflag0 and bm_TGtkText_line_wrap) shr bp_TGtkText_line_wrap

proc set_line_wrap*(a: PGtkText, `line_wrap`: guint) =
  a.GtkTextflag0 = a.GtkTextflag0 or
      (int16(`line_wrap` shl bp_TGtkText_line_wrap) and bm_TGtkText_line_wrap)

proc word_wrap*(a: PGtkText): guint =
  result = (a . GtkTextflag0 and bm_TGtkText_word_wrap) shr bp_TGtkText_word_wrap

proc set_word_wrap*(a: PGtkText, `word_wrap`: guint) =
  a.GtkTextflag0 = a.GtkTextflag0 or
      (int16(`word_wrap` shl bp_TGtkText_word_wrap) and bm_TGtkText_word_wrap)

proc use_wchar*(a: PGtkText): gboolean =
  result = ((a.GtkTextflag0 and bm_TGtkText_use_wchar) shr bp_TGtkText_use_wchar) >
      0'i16

proc set_use_wchar*(a: PGtkText, `use_wchar`: gboolean) =
  if `use_wchar`:
    a . GtkTextflag0 = a . GtkTextflag0 or bm_TGtkText_use_wchar
  else:
    a . GtkTextflag0 = a . GtkTextflag0 and not bm_TGtkText_use_wchar

proc GTK_TEXT_INDEX_WCHAR*(t: PGtkText, index: guint): guint32 =
  nil

proc GTK_TEXT_INDEX_UCHAR*(t: PGtkText, index: guint): GUChar =
  nil

proc GTK_TYPE_TEXT_ITER*(): GType =
  result = gtk_text_iter_get_type()

proc GTK_TYPE_TEXT_TAG*(): GType =
  result = gtk_text_tag_get_type()

proc GTK_TEXT_TAG*(obj: pointer): PGtkTextTag =
  result = cast[PGtkTextTag](G_TYPE_CHECK_INSTANCE_CAST(obj, GTK_TYPE_TEXT_TAG()))

proc GTK_TEXT_TAG_CLASS*(klass: pointer): PGtkTextTagClass =
  result = cast[PGtkTextTagClass](G_TYPE_CHECK_CLASS_CAST(klass, GTK_TYPE_TEXT_TAG()))

proc GTK_IS_TEXT_TAG*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GTK_TYPE_TEXT_TAG())

proc GTK_IS_TEXT_TAG_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GTK_TYPE_TEXT_TAG())

proc GTK_TEXT_TAG_GET_CLASS*(obj: pointer): PGtkTextTagClass =
  result = cast[PGtkTextTagClass](G_TYPE_INSTANCE_GET_CLASS(obj, GTK_TYPE_TEXT_TAG()))

proc GTK_TYPE_TEXT_ATTRIBUTES*(): GType =
  result = gtk_text_attributes_get_type()

proc bg_color_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_bg_color_set) shr
      bp_TGtkTextTag_bg_color_set

proc set_bg_color_set*(a: var TGtkTextTag, `bg_color_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`bg_color_set` shl bp_TGtkTextTag_bg_color_set) and
      bm_TGtkTextTag_bg_color_set)

proc bg_stipple_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_bg_stipple_set) shr
      bp_TGtkTextTag_bg_stipple_set

proc set_bg_stipple_set*(a: var TGtkTextTag, `bg_stipple_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`bg_stipple_set` shl bp_TGtkTextTag_bg_stipple_set) and
      bm_TGtkTextTag_bg_stipple_set)

proc fg_color_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_fg_color_set) shr
      bp_TGtkTextTag_fg_color_set

proc set_fg_color_set*(a: var TGtkTextTag, `fg_color_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`fg_color_set` shl bp_TGtkTextTag_fg_color_set) and
      bm_TGtkTextTag_fg_color_set)

proc scale_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_scale_set) shr
      bp_TGtkTextTag_scale_set

proc set_scale_set*(a: var TGtkTextTag, `scale_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`scale_set` shl bp_TGtkTextTag_scale_set) and
      bm_TGtkTextTag_scale_set)

proc fg_stipple_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_fg_stipple_set) shr
      bp_TGtkTextTag_fg_stipple_set

proc set_fg_stipple_set*(a: var TGtkTextTag, `fg_stipple_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`fg_stipple_set` shl bp_TGtkTextTag_fg_stipple_set) and
      bm_TGtkTextTag_fg_stipple_set)

proc justification_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_justification_set) shr
      bp_TGtkTextTag_justification_set

proc set_justification_set*(a: var TGtkTextTag, `justification_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`justification_set` shl bp_TGtkTextTag_justification_set) and
      bm_TGtkTextTag_justification_set)

proc left_margin_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_left_margin_set) shr
      bp_TGtkTextTag_left_margin_set

proc set_left_margin_set*(a: var TGtkTextTag, `left_margin_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`left_margin_set` shl bp_TGtkTextTag_left_margin_set) and
      bm_TGtkTextTag_left_margin_set)

proc indent_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_indent_set) shr
      bp_TGtkTextTag_indent_set

proc set_indent_set*(a: var TGtkTextTag, `indent_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`indent_set` shl bp_TGtkTextTag_indent_set) and
      bm_TGtkTextTag_indent_set)

proc rise_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_rise_set) shr bp_TGtkTextTag_rise_set

proc set_rise_set*(a: var TGtkTextTag, `rise_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`rise_set` shl bp_TGtkTextTag_rise_set) and bm_TGtkTextTag_rise_set)

proc strikethrough_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_strikethrough_set) shr
      bp_TGtkTextTag_strikethrough_set

proc set_strikethrough_set*(a: var TGtkTextTag, `strikethrough_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`strikethrough_set` shl bp_TGtkTextTag_strikethrough_set) and
      bm_TGtkTextTag_strikethrough_set)

proc right_margin_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_right_margin_set) shr
      bp_TGtkTextTag_right_margin_set

proc set_right_margin_set*(a: var TGtkTextTag, `right_margin_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`right_margin_set` shl bp_TGtkTextTag_right_margin_set) and
      bm_TGtkTextTag_right_margin_set)

proc pixels_above_lines_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_pixels_above_lines_set) shr
      bp_TGtkTextTag_pixels_above_lines_set

proc set_pixels_above_lines_set*(a: var TGtkTextTag,
                                 `pixels_above_lines_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`pixels_above_lines_set` shl bp_TGtkTextTag_pixels_above_lines_set) and
      bm_TGtkTextTag_pixels_above_lines_set)

proc pixels_below_lines_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_pixels_below_lines_set) shr
      bp_TGtkTextTag_pixels_below_lines_set

proc set_pixels_below_lines_set*(a: var TGtkTextTag,
                                 `pixels_below_lines_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`pixels_below_lines_set` shl bp_TGtkTextTag_pixels_below_lines_set) and
      bm_TGtkTextTag_pixels_below_lines_set)

proc pixels_inside_wrap_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_pixels_inside_wrap_set) shr
      bp_TGtkTextTag_pixels_inside_wrap_set

proc set_pixels_inside_wrap_set*(a: var TGtkTextTag,
                                 `pixels_inside_wrap_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`pixels_inside_wrap_set` shl bp_TGtkTextTag_pixels_inside_wrap_set) and
      bm_TGtkTextTag_pixels_inside_wrap_set)

proc tabs_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_tabs_set) shr bp_TGtkTextTag_tabs_set

proc set_tabs_set*(a: var TGtkTextTag, `tabs_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`tabs_set` shl bp_TGtkTextTag_tabs_set) and bm_TGtkTextTag_tabs_set)

proc underline_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_underline_set) shr
      bp_TGtkTextTag_underline_set

proc set_underline_set*(a: var TGtkTextTag, `underline_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`underline_set` shl bp_TGtkTextTag_underline_set) and
      bm_TGtkTextTag_underline_set)

proc wrap_mode_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_wrap_mode_set) shr
      bp_TGtkTextTag_wrap_mode_set

proc set_wrap_mode_set*(a: var TGtkTextTag, `wrap_mode_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`wrap_mode_set` shl bp_TGtkTextTag_wrap_mode_set) and
      bm_TGtkTextTag_wrap_mode_set)

proc bg_full_height_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_bg_full_height_set) shr
      bp_TGtkTextTag_bg_full_height_set

proc set_bg_full_height_set*(a: var TGtkTextTag, `bg_full_height_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`bg_full_height_set` shl bp_TGtkTextTag_bg_full_height_set) and
      bm_TGtkTextTag_bg_full_height_set)

proc invisible_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_invisible_set) shr
      bp_TGtkTextTag_invisible_set

proc set_invisible_set*(a: var TGtkTextTag, `invisible_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`invisible_set` shl bp_TGtkTextTag_invisible_set) and
      bm_TGtkTextTag_invisible_set)

proc editable_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_editable_set) shr
      bp_TGtkTextTag_editable_set

proc set_editable_set*(a: var TGtkTextTag, `editable_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`editable_set` shl bp_TGtkTextTag_editable_set) and
      bm_TGtkTextTag_editable_set)

proc language_set*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_language_set) shr
      bp_TGtkTextTag_language_set

proc set_language_set*(a: var TGtkTextTag, `language_set`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`language_set` shl bp_TGtkTextTag_language_set) and
      bm_TGtkTextTag_language_set)

proc pad1*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_pad1) shr bp_TGtkTextTag_pad1

proc set_pad1*(a: var TGtkTextTag, `pad1`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`pad1` shl bp_TGtkTextTag_pad1) and bm_TGtkTextTag_pad1)

proc pad2*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_pad2) shr bp_TGtkTextTag_pad2

proc set_pad2*(a: var TGtkTextTag, `pad2`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`pad2` shl bp_TGtkTextTag_pad2) and bm_TGtkTextTag_pad2)

proc pad3*(a: var TGtkTextTag): guint =
  result = (a.GtkTextTagflag0 and bm_TGtkTextTag_pad3) shr bp_TGtkTextTag_pad3

proc set_pad3*(a: var TGtkTextTag, `pad3`: guint) =
  a.GtkTextTagflag0 = a.GtkTextTagflag0 or
      ((`pad3` shl bp_TGtkTextTag_pad3) and bm_TGtkTextTag_pad3)

proc underline*(a: var TGtkTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_underline) shr
      bp_TGtkTextAppearance_underline

proc set_underline*(a: var TGtkTextAppearance, `underline`: guint) =
  a.flag0 = a.flag0 or
      (int16(`underline` shl bp_TGtkTextAppearance_underline) and
      bm_TGtkTextAppearance_underline)

proc strikethrough*(a: var TGtkTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_strikethrough) shr
      bp_TGtkTextAppearance_strikethrough

proc set_strikethrough*(a: var TGtkTextAppearance, `strikethrough`: guint) =
  a.flag0 = a.flag0 or
      (int16(`strikethrough` shl bp_TGtkTextAppearance_strikethrough) and
      bm_TGtkTextAppearance_strikethrough)

proc draw_bg*(a: var TGtkTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_draw_bg) shr
      bp_TGtkTextAppearance_draw_bg

proc set_draw_bg*(a: var TGtkTextAppearance, `draw_bg`: guint) =
  a.flag0 = a.flag0 or
      (int16(`draw_bg` shl bp_TGtkTextAppearance_draw_bg) and
      bm_TGtkTextAppearance_draw_bg)

proc inside_selection*(a: var TGtkTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_inside_selection) shr
      bp_TGtkTextAppearance_inside_selection

proc set_inside_selection*(a: var TGtkTextAppearance, `inside_selection`: guint) =
  a.flag0 = a.flag0 or
      (int16(`inside_selection` shl bp_TGtkTextAppearance_inside_selection) and
      bm_TGtkTextAppearance_inside_selection)

proc is_text*(a: var TGtkTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_is_text) shr
      bp_TGtkTextAppearance_is_text

proc set_is_text*(a: var TGtkTextAppearance, `is_text`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_text` shl bp_TGtkTextAppearance_is_text) and
      bm_TGtkTextAppearance_is_text)

proc pad1*(a: var TGtkTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_pad1) shr
      bp_TGtkTextAppearance_pad1

proc set_pad1*(a: var TGtkTextAppearance, `pad1`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad1` shl bp_TGtkTextAppearance_pad1) and bm_TGtkTextAppearance_pad1)

proc pad2*(a: var TGtkTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_pad2) shr
      bp_TGtkTextAppearance_pad2

proc set_pad2*(a: var TGtkTextAppearance, `pad2`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad2` shl bp_TGtkTextAppearance_pad2) and bm_TGtkTextAppearance_pad2)

proc pad3*(a: var TGtkTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_pad3) shr
      bp_TGtkTextAppearance_pad3

proc set_pad3*(a: var TGtkTextAppearance, `pad3`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad3` shl bp_TGtkTextAppearance_pad3) and bm_TGtkTextAppearance_pad3)

proc pad4*(a: var TGtkTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_pad4) shr
      bp_TGtkTextAppearance_pad4

proc set_pad4*(a: var TGtkTextAppearance, `pad4`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad4` shl bp_TGtkTextAppearance_pad4) and bm_TGtkTextAppearance_pad4)

proc invisible*(a: var TGtkTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_invisible) shr
      bp_TGtkTextAttributes_invisible

proc set_invisible*(a: var TGtkTextAttributes, `invisible`: guint) =
  a.flag0 = a.flag0 or
      (int16(`invisible` shl bp_TGtkTextAttributes_invisible) and
      bm_TGtkTextAttributes_invisible)

proc bg_full_height*(a: var TGtkTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_bg_full_height) shr
      bp_TGtkTextAttributes_bg_full_height

proc set_bg_full_height*(a: var TGtkTextAttributes, `bg_full_height`: guint) =
  a.flag0 = a.flag0 or
      (int16(`bg_full_height` shl bp_TGtkTextAttributes_bg_full_height) and
      bm_TGtkTextAttributes_bg_full_height)

proc editable*(a: var TGtkTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_editable) shr
      bp_TGtkTextAttributes_editable

proc set_editable*(a: var TGtkTextAttributes, `editable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`editable` shl bp_TGtkTextAttributes_editable) and
      bm_TGtkTextAttributes_editable)

proc realized*(a: var TGtkTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_realized) shr
      bp_TGtkTextAttributes_realized

proc set_realized*(a: var TGtkTextAttributes, `realized`: guint) =
  a.flag0 = a.flag0 or
      (int16(`realized` shl bp_TGtkTextAttributes_realized) and
      bm_TGtkTextAttributes_realized)

proc pad1*(a: var TGtkTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_pad1) shr
      bp_TGtkTextAttributes_pad1

proc set_pad1*(a: var TGtkTextAttributes, `pad1`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad1` shl bp_TGtkTextAttributes_pad1) and bm_TGtkTextAttributes_pad1)

proc pad2*(a: var TGtkTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_pad2) shr
      bp_TGtkTextAttributes_pad2

proc set_pad2*(a: var TGtkTextAttributes, `pad2`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad2` shl bp_TGtkTextAttributes_pad2) and bm_TGtkTextAttributes_pad2)

proc pad3*(a: var TGtkTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_pad3) shr
      bp_TGtkTextAttributes_pad3

proc set_pad3*(a: var TGtkTextAttributes, `pad3`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad3` shl bp_TGtkTextAttributes_pad3) and bm_TGtkTextAttributes_pad3)

proc pad4*(a: var TGtkTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_pad4) shr
      bp_TGtkTextAttributes_pad4

proc set_pad4*(a: var TGtkTextAttributes, `pad4`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad4` shl bp_TGtkTextAttributes_pad4) and bm_TGtkTextAttributes_pad4)

proc GTK_TYPE_TEXT_TAG_TABLE*(): GType =
  result = gtk_text_tag_table_get_type()

proc GTK_TEXT_TAG_TABLE*(obj: pointer): PGtkTextTagTable =
  result = cast[PGtkTextTagTable](G_TYPE_CHECK_INSTANCE_CAST(obj,
      GTK_TYPE_TEXT_TAG_TABLE()))

proc GTK_TEXT_TAG_TABLE_CLASS*(klass: pointer): PGtkTextTagTableClass =
  result = cast[PGtkTextTagTableClass](G_TYPE_CHECK_CLASS_CAST(klass,
      GTK_TYPE_TEXT_TAG_TABLE()))

proc GTK_IS_TEXT_TAG_TABLE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GTK_TYPE_TEXT_TAG_TABLE())

proc GTK_IS_TEXT_TAG_TABLE_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GTK_TYPE_TEXT_TAG_TABLE())

proc GTK_TEXT_TAG_TABLE_GET_CLASS*(obj: pointer): PGtkTextTagTableClass =
  result = cast[PGtkTextTagTableClass](G_TYPE_INSTANCE_GET_CLASS(obj, GTK_TYPE_TEXT_TAG_TABLE()))

proc GTK_TYPE_TEXT_MARK*(): GType =
  result = gtk_text_mark_get_type()

proc GTK_TEXT_MARK*(anObject: pointer): PGtkTextMark =
  result = cast[PGtkTextMark](G_TYPE_CHECK_INSTANCE_CAST(anObject, GTK_TYPE_TEXT_MARK()))

proc GTK_TEXT_MARK_CLASS*(klass: pointer): PGtkTextMarkClass =
  result = cast[PGtkTextMarkClass](G_TYPE_CHECK_CLASS_CAST(klass, GTK_TYPE_TEXT_MARK()))

proc GTK_IS_TEXT_MARK*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GTK_TYPE_TEXT_MARK())

proc GTK_IS_TEXT_MARK_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GTK_TYPE_TEXT_MARK())

proc GTK_TEXT_MARK_GET_CLASS*(obj: pointer): PGtkTextMarkClass =
  result = cast[PGtkTextMarkClass](G_TYPE_INSTANCE_GET_CLASS(obj, GTK_TYPE_TEXT_MARK()))

proc visible*(a: var TGtkTextMarkBody): guint =
  result = (a.flag0 and bm_TGtkTextMarkBody_visible) shr
      bp_TGtkTextMarkBody_visible

proc set_visible*(a: var TGtkTextMarkBody, `visible`: guint) =
  a.flag0 = a.flag0 or
      (int16(`visible` shl bp_TGtkTextMarkBody_visible) and
      bm_TGtkTextMarkBody_visible)

proc not_deleteable*(a: var TGtkTextMarkBody): guint =
  result = (a.flag0 and bm_TGtkTextMarkBody_not_deleteable) shr
      bp_TGtkTextMarkBody_not_deleteable

proc set_not_deleteable*(a: var TGtkTextMarkBody, `not_deleteable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`not_deleteable` shl bp_TGtkTextMarkBody_not_deleteable) and
      bm_TGtkTextMarkBody_not_deleteable)

proc GTK_TYPE_TEXT_CHILD_ANCHOR*(): GType =
  result = gtk_text_child_anchor_get_type()

proc GTK_TEXT_CHILD_ANCHOR*(anObject: pointer): PGtkTextChildAnchor =
  result = cast[PGtkTextChildAnchor](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      GTK_TYPE_TEXT_CHILD_ANCHOR()))

proc GTK_TEXT_CHILD_ANCHOR_CLASS*(klass: pointer): PGtkTextChildAnchorClass =
  result = cast[PGtkTextChildAnchorClass](G_TYPE_CHECK_CLASS_CAST(klass, GTK_TYPE_TEXT_CHILD_ANCHOR()))

proc GTK_IS_TEXT_CHILD_ANCHOR*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GTK_TYPE_TEXT_CHILD_ANCHOR())

proc GTK_IS_TEXT_CHILD_ANCHOR_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GTK_TYPE_TEXT_CHILD_ANCHOR())

proc GTK_TEXT_CHILD_ANCHOR_GET_CLASS*(obj: pointer): PGtkTextChildAnchorClass =
  result = cast[PGtkTextChildAnchorClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      GTK_TYPE_TEXT_CHILD_ANCHOR()))

proc width*(a: PGtkTextLineData): gint =
  result = a . flag0 and bm_TGtkTextLineData_width

proc set_width*(a: PGtkTextLineData, NewWidth: gint) =
  a . flag0 = (bm_TGtkTextLineData_width and NewWidth) or a . flag0

proc valid*(a: PGtkTextLineData): gint =
  result = (a . flag0 and bm_TGtkTextLineData_valid) shr
      bp_TGtkTextLineData_valid

proc set_valid*(a: PGtkTextLineData, `valid`: gint) =
  a . flag0 = a .
      flag0 or
      ((`valid` shl bp_TGtkTextLineData_valid) and bm_TGtkTextLineData_valid)

proc GTK_TYPE_TEXT_BUFFER*(): GType =
  result = gtk_text_buffer_get_type()

proc GTK_TEXT_BUFFER*(obj: pointer): PGtkTextBuffer =
  result = cast[PGtkTextBuffer](G_TYPE_CHECK_INSTANCE_CAST(obj, GTK_TYPE_TEXT_BUFFER()))

proc GTK_TEXT_BUFFER_CLASS*(klass: pointer): PGtkTextBufferClass =
  result = cast[PGtkTextBufferClass](G_TYPE_CHECK_CLASS_CAST(klass,
      GTK_TYPE_TEXT_BUFFER()))

proc GTK_IS_TEXT_BUFFER*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GTK_TYPE_TEXT_BUFFER())

proc GTK_IS_TEXT_BUFFER_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GTK_TYPE_TEXT_BUFFER())

proc GTK_TEXT_BUFFER_GET_CLASS*(obj: pointer): PGtkTextBufferClass =
  result = cast[PGtkTextBufferClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      GTK_TYPE_TEXT_BUFFER()))

proc modified*(a: var TGtkTextBuffer): guint =
  result = (a.GtkTextBufferflag0 and bm_TGtkTextBuffer_modified) shr
      bp_TGtkTextBuffer_modified

proc set_modified*(a: var TGtkTextBuffer, `modified`: guint) =
  a.GtkTextBufferflag0 = a.GtkTextBufferflag0 or
      (int16(`modified` shl bp_TGtkTextBuffer_modified) and
      bm_TGtkTextBuffer_modified)

proc GTK_TYPE_TEXT_LAYOUT*(): GType =
  result = gtk_text_layout_get_type()

proc GTK_TEXT_LAYOUT*(obj: pointer): PGtkTextLayout =
  result = cast[PGtkTextLayout](G_TYPE_CHECK_INSTANCE_CAST(obj, GTK_TYPE_TEXT_LAYOUT()))

proc GTK_TEXT_LAYOUT_CLASS*(klass: pointer): PGtkTextLayoutClass =
  result = cast[PGtkTextLayoutClass](G_TYPE_CHECK_CLASS_CAST(klass,
      GTK_TYPE_TEXT_LAYOUT()))

proc GTK_IS_TEXT_LAYOUT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GTK_TYPE_TEXT_LAYOUT())

proc GTK_IS_TEXT_LAYOUT_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GTK_TYPE_TEXT_LAYOUT())

proc GTK_TEXT_LAYOUT_GET_CLASS*(obj: pointer): PGtkTextLayoutClass =
  result = cast[PGtkTextLayoutClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      GTK_TYPE_TEXT_LAYOUT()))

proc cursor_visible*(a: var TGtkTextLayout): guint =
  result = (a.GtkTextLayoutflag0 and bm_TGtkTextLayout_cursor_visible) shr
      bp_TGtkTextLayout_cursor_visible

proc set_cursor_visible*(a: var TGtkTextLayout, `cursor_visible`: guint) =
  a.GtkTextLayoutflag0 = a.GtkTextLayoutflag0 or
      (int16(`cursor_visible` shl bp_TGtkTextLayout_cursor_visible) and
      bm_TGtkTextLayout_cursor_visible)

proc cursor_direction*(a: var TGtkTextLayout): gint =
  result = (a.GtkTextLayoutflag0 and bm_TGtkTextLayout_cursor_direction) shr
      bp_TGtkTextLayout_cursor_direction

proc set_cursor_direction*(a: var TGtkTextLayout, `cursor_direction`: gint) =
  a.GtkTextLayoutflag0 = a.GtkTextLayoutflag0 or
      (int16(`cursor_direction` shl bp_TGtkTextLayout_cursor_direction) and
      bm_TGtkTextLayout_cursor_direction)

proc is_strong*(a: var TGtkTextCursorDisplay): guint =
  result = (a.flag0 and bm_TGtkTextCursorDisplay_is_strong) shr
      bp_TGtkTextCursorDisplay_is_strong

proc set_is_strong*(a: var TGtkTextCursorDisplay, `is_strong`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_strong` shl bp_TGtkTextCursorDisplay_is_strong) and
      bm_TGtkTextCursorDisplay_is_strong)

proc is_weak*(a: var TGtkTextCursorDisplay): guint =
  result = (a.flag0 and bm_TGtkTextCursorDisplay_is_weak) shr
      bp_TGtkTextCursorDisplay_is_weak

proc set_is_weak*(a: var TGtkTextCursorDisplay, `is_weak`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_weak` shl bp_TGtkTextCursorDisplay_is_weak) and
      bm_TGtkTextCursorDisplay_is_weak)

proc GTK_TYPE_TEXT_VIEW*(): GType =
  result = gtk_text_view_get_type()

proc GTK_TEXT_VIEW*(obj: pointer): PGtkTextView =
  result = cast[PGtkTextView](GTK_CHECK_CAST(obj, GTK_TYPE_TEXT_VIEW()))

proc GTK_TEXT_VIEW_CLASS*(klass: pointer): PGtkTextViewClass =
  result = cast[PGtkTextViewClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_TEXT_VIEW()))

proc GTK_IS_TEXT_VIEW*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TEXT_VIEW())

proc GTK_IS_TEXT_VIEW_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TEXT_VIEW())

proc GTK_TEXT_VIEW_GET_CLASS*(obj: pointer): PGtkTextViewClass =
  result = cast[PGtkTextViewClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_TEXT_VIEW()))

proc editable*(a: var TGtkTextView): guint =
  result = (a.GtkTextViewflag0 and bm_TGtkTextView_editable) shr
      bp_TGtkTextView_editable

proc set_editable*(a: var TGtkTextView, `editable`: guint) =
  a.GtkTextViewflag0 = a.GtkTextViewflag0 or
      (int16(`editable` shl bp_TGtkTextView_editable) and bm_TGtkTextView_editable)

proc overwrite_mode*(a: var TGtkTextView): guint =
  result = (a.GtkTextViewflag0 and bm_TGtkTextView_overwrite_mode) shr
      bp_TGtkTextView_overwrite_mode

proc set_overwrite_mode*(a: var TGtkTextView, `overwrite_mode`: guint) =
  a.GtkTextViewflag0 = a.GtkTextViewflag0 or
      (int16(`overwrite_mode` shl bp_TGtkTextView_overwrite_mode) and
      bm_TGtkTextView_overwrite_mode)

proc cursor_visible*(a: var TGtkTextView): guint =
  result = (a.GtkTextViewflag0 and bm_TGtkTextView_cursor_visible) shr
      bp_TGtkTextView_cursor_visible

proc set_cursor_visible*(a: var TGtkTextView, `cursor_visible`: guint) =
  a.GtkTextViewflag0 = a.GtkTextViewflag0 or
      (int16(`cursor_visible` shl bp_TGtkTextView_cursor_visible) and
      bm_TGtkTextView_cursor_visible)

proc need_im_reset*(a: var TGtkTextView): guint =
  result = (a.GtkTextViewflag0 and bm_TGtkTextView_need_im_reset) shr
      bp_TGtkTextView_need_im_reset

proc set_need_im_reset*(a: var TGtkTextView, `need_im_reset`: guint) =
  a.GtkTextViewflag0 = a.GtkTextViewflag0 or
      (int16(`need_im_reset` shl bp_TGtkTextView_need_im_reset) and
      bm_TGtkTextView_need_im_reset)

proc just_selected_element*(a: var TGtkTextView): guint =
  result = (a.GtkTextViewflag0 and bm_TGtkTextView_just_selected_element) shr
      bp_TGtkTextView_just_selected_element

proc set_just_selected_element*(a: var TGtkTextView,
                                `just_selected_element`: guint) =
  a.GtkTextViewflag0 = a.GtkTextViewflag0 or
      (int16(`just_selected_element` shl bp_TGtkTextView_just_selected_element) and
      bm_TGtkTextView_just_selected_element)

proc disable_scroll_on_focus*(a: var TGtkTextView): guint =
  result = (a.GtkTextViewflag0 and bm_TGtkTextView_disable_scroll_on_focus) shr
      bp_TGtkTextView_disable_scroll_on_focus

proc set_disable_scroll_on_focus*(a: var TGtkTextView,
                                  `disable_scroll_on_focus`: guint) =
  a.GtkTextViewflag0 = a.GtkTextViewflag0 or
      (int16(`disable_scroll_on_focus` shl bp_TGtkTextView_disable_scroll_on_focus) and
      bm_TGtkTextView_disable_scroll_on_focus)

proc onscreen_validated*(a: var TGtkTextView): guint =
  result = (a.GtkTextViewflag0 and bm_TGtkTextView_onscreen_validated) shr
      bp_TGtkTextView_onscreen_validated

proc set_onscreen_validated*(a: var TGtkTextView, `onscreen_validated`: guint) =
  a.GtkTextViewflag0 = a.GtkTextViewflag0 or
      (int16(`onscreen_validated` shl bp_TGtkTextView_onscreen_validated) and
      bm_TGtkTextView_onscreen_validated)

proc mouse_cursor_obscured*(a: var TGtkTextView): guint =
  result = (a.GtkTextViewflag0 and bm_TGtkTextView_mouse_cursor_obscured) shr
      bp_TGtkTextView_mouse_cursor_obscured

proc set_mouse_cursor_obscured*(a: var TGtkTextView,
                                `mouse_cursor_obscured`: guint) =
  a.GtkTextViewflag0 = a.GtkTextViewflag0 or
      (int16(`mouse_cursor_obscured` shl bp_TGtkTextView_mouse_cursor_obscured) and
      bm_TGtkTextView_mouse_cursor_obscured)

proc GTK_TYPE_TIPS_QUERY*(): GType =
  result = gtk_tips_query_get_type()

proc GTK_TIPS_QUERY*(obj: pointer): PGtkTipsQuery =
  result = cast[PGtkTipsQuery](GTK_CHECK_CAST(obj, GTK_TYPE_TIPS_QUERY()))

proc GTK_TIPS_QUERY_CLASS*(klass: pointer): PGtkTipsQueryClass =
  result = cast[PGtkTipsQueryClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_TIPS_QUERY()))

proc GTK_IS_TIPS_QUERY*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TIPS_QUERY())

proc GTK_IS_TIPS_QUERY_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TIPS_QUERY())

proc GTK_TIPS_QUERY_GET_CLASS*(obj: pointer): PGtkTipsQueryClass =
  result = cast[PGtkTipsQueryClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_TIPS_QUERY()))

proc emit_always*(a: var TGtkTipsQuery): guint =
  result = (a.GtkTipsQueryflag0 and bm_TGtkTipsQuery_emit_always) shr
      bp_TGtkTipsQuery_emit_always

proc set_emit_always*(a: var TGtkTipsQuery, `emit_always`: guint) =
  a.GtkTipsQueryflag0 = a.GtkTipsQueryflag0 or
      (int16(`emit_always` shl bp_TGtkTipsQuery_emit_always) and
      bm_TGtkTipsQuery_emit_always)

proc in_query*(a: var TGtkTipsQuery): guint =
  result = (a.GtkTipsQueryflag0 and bm_TGtkTipsQuery_in_query) shr
      bp_TGtkTipsQuery_in_query

proc set_in_query*(a: var TGtkTipsQuery, `in_query`: guint) =
  a.GtkTipsQueryflag0 = a.GtkTipsQueryflag0 or
      (int16(`in_query` shl bp_TGtkTipsQuery_in_query) and
      bm_TGtkTipsQuery_in_query)

proc GTK_TYPE_TOOLTIPS*(): GType =
  result = gtk_tooltips_get_type()

proc GTK_TOOLTIPS*(obj: pointer): PGtkTooltips =
  result = cast[PGtkTooltips](GTK_CHECK_CAST(obj, GTK_TYPE_TOOLTIPS()))

proc GTK_TOOLTIPS_CLASS*(klass: pointer): PGtkTooltipsClass =
  result = cast[PGtkTooltipsClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_TOOLTIPS()))

proc GTK_IS_TOOLTIPS*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TOOLTIPS())

proc GTK_IS_TOOLTIPS_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TOOLTIPS())

proc GTK_TOOLTIPS_GET_CLASS*(obj: pointer): PGtkTooltipsClass =
  result = cast[PGtkTooltipsClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_TOOLTIPS()))

proc delay*(a: var TGtkTooltips): guint =
  result = (a.GtkTooltipsflag0 and bm_TGtkTooltips_delay) shr bp_TGtkTooltips_delay

proc set_delay*(a: var TGtkTooltips, `delay`: guint) =
  a.GtkTooltipsflag0 = a.GtkTooltipsflag0 or
      ((`delay` shl bp_TGtkTooltips_delay) and bm_TGtkTooltips_delay)

proc enabled*(a: var TGtkTooltips): guint =
  result = (a.GtkTooltipsflag0 and bm_TGtkTooltips_enabled) shr bp_TGtkTooltips_enabled

proc set_enabled*(a: var TGtkTooltips, `enabled`: guint) =
  a.GtkTooltipsflag0 = a.GtkTooltipsflag0 or
      ((`enabled` shl bp_TGtkTooltips_enabled) and bm_TGtkTooltips_enabled)

proc have_grab*(a: var TGtkTooltips): guint =
  result = (a.GtkTooltipsflag0 and bm_TGtkTooltips_have_grab) shr
      bp_TGtkTooltips_have_grab

proc set_have_grab*(a: var TGtkTooltips, `have_grab`: guint) =
  a.GtkTooltipsflag0 = a.GtkTooltipsflag0 or
      ((`have_grab` shl bp_TGtkTooltips_have_grab) and
      bm_TGtkTooltips_have_grab)

proc use_sticky_delay*(a: var TGtkTooltips): guint =
  result = (a.GtkTooltipsflag0 and bm_TGtkTooltips_use_sticky_delay) shr
      bp_TGtkTooltips_use_sticky_delay

proc set_use_sticky_delay*(a: var TGtkTooltips, `use_sticky_delay`: guint) =
  a.GtkTooltipsflag0 = a.GtkTooltipsflag0 or
      ((`use_sticky_delay` shl bp_TGtkTooltips_use_sticky_delay) and
      bm_TGtkTooltips_use_sticky_delay)

proc GTK_TYPE_TOOLBAR*(): GType =
  result = gtk_toolbar_get_type()

proc GTK_TOOLBAR*(obj: pointer): PGtkToolbar =
  result = cast[PGtkToolbar](GTK_CHECK_CAST(obj, GTK_TYPE_TOOLBAR()))

proc GTK_TOOLBAR_CLASS*(klass: pointer): PGtkToolbarClass =
  result = cast[PGtkToolbarClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_TOOLBAR()))

proc GTK_IS_TOOLBAR*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TOOLBAR())

proc GTK_IS_TOOLBAR_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TOOLBAR())

proc GTK_TOOLBAR_GET_CLASS*(obj: pointer): PGtkToolbarClass =
  result = cast[PGtkToolbarClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_TOOLBAR()))

proc style_set*(a: var TGtkToolbar): guint =
  result = (a.GtkToolbarflag0 and bm_TGtkToolbar_style_set) shr
      bp_TGtkToolbar_style_set

proc set_style_set*(a: var TGtkToolbar, `style_set`: guint) =
  a.GtkToolbarflag0 = a.GtkToolbarflag0 or
      (int16(`style_set` shl bp_TGtkToolbar_style_set) and
      bm_TGtkToolbar_style_set)

proc icon_size_set*(a: var TGtkToolbar): guint =
  result = (a.GtkToolbarflag0 and bm_TGtkToolbar_icon_size_set) shr
      bp_TGtkToolbar_icon_size_set

proc set_icon_size_set*(a: var TGtkToolbar, `icon_size_set`: guint) =
  a.GtkToolbarflag0 = a.GtkToolbarflag0 or
      (int16(`icon_size_set` shl bp_TGtkToolbar_icon_size_set) and
      bm_TGtkToolbar_icon_size_set)

proc GTK_TYPE_TREE*(): GType =
  result = gtk_tree_get_type()

proc GTK_TREE*(obj: pointer): PGtkTree =
  result = cast[PGtkTree](GTK_CHECK_CAST(obj, GTK_TYPE_TREE()))

proc GTK_TREE_CLASS*(klass: pointer): PGtkTreeClass =
  result = cast[PGtkTreeClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_TREE()))

proc GTK_IS_TREE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TREE())

proc GTK_IS_TREE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TREE())

proc GTK_TREE_GET_CLASS*(obj: pointer): PGtkTreeClass =
  result = cast[PGtkTreeClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_TREE()))

proc GTK_IS_ROOT_TREE*(obj: pointer): bool =
  result = (cast[PGtkObject]((GTK_TREE(obj)) . root_tree)) ==
     (cast[PGtkObject](obj))

proc GTK_TREE_ROOT_TREE*(obj: pointer): PGtkTree =
  result = GTK_TREE(obj).root_tree

proc GTK_TREE_SELECTION_OLD*(obj: pointer): PGList =
  result = (GTK_TREE_ROOT_TREE(obj)).selection

proc selection_mode*(a: var TGtkTree): guint =
  result = (a.GtkTreeflag0 and bm_TGtkTree_selection_mode) shr
      bp_TGtkTree_selection_mode

proc set_selection_mode*(a: var TGtkTree, `selection_mode`: guint) =
  a.GtkTreeflag0 = a.GtkTreeflag0 or
      (int16(`selection_mode` shl bp_TGtkTree_selection_mode) and
      bm_TGtkTree_selection_mode)

proc view_mode*(a: var TGtkTree): guint =
  result = (a.GtkTreeflag0 and bm_TGtkTree_view_mode) shr bp_TGtkTree_view_mode

proc set_view_mode*(a: var TGtkTree, `view_mode`: guint) =
  a.GtkTreeflag0 = a.GtkTreeflag0 or
      (int16(`view_mode` shl bp_TGtkTree_view_mode) and bm_TGtkTree_view_mode)

proc view_line*(a: var TGtkTree): guint =
  result = (a.GtkTreeflag0 and bm_TGtkTree_view_line) shr bp_TGtkTree_view_line

proc set_view_line*(a: var TGtkTree, `view_line`: guint) =
  a.GtkTreeflag0 = a.GtkTreeflag0 or
      (int16(`view_line` shl bp_TGtkTree_view_line) and bm_TGtkTree_view_line)

proc GTK_TYPE_TREE_DRAG_SOURCE*(): GType =
  result = gtk_tree_drag_source_get_type()

proc GTK_TREE_DRAG_SOURCE*(obj: pointer): PGtkTreeDragSource =
  result = cast[PGtkTreeDragSource](G_TYPE_CHECK_INSTANCE_CAST(obj,
      GTK_TYPE_TREE_DRAG_SOURCE()))

proc GTK_IS_TREE_DRAG_SOURCE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GTK_TYPE_TREE_DRAG_SOURCE())

proc GTK_TREE_DRAG_SOURCE_GET_IFACE*(obj: pointer): PGtkTreeDragSourceIface =
  result = cast[PGtkTreeDragSourceIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      GTK_TYPE_TREE_DRAG_SOURCE()))

proc GTK_TYPE_TREE_DRAG_DEST*(): GType =
  result = gtk_tree_drag_dest_get_type()

proc GTK_TREE_DRAG_DEST*(obj: pointer): PGtkTreeDragDest =
  result = cast[PGtkTreeDragDest](G_TYPE_CHECK_INSTANCE_CAST(obj,
      GTK_TYPE_TREE_DRAG_DEST()))

proc GTK_IS_TREE_DRAG_DEST*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GTK_TYPE_TREE_DRAG_DEST())

proc GTK_TREE_DRAG_DEST_GET_IFACE*(obj: pointer): PGtkTreeDragDestIface =
  result = cast[PGtkTreeDragDestIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      GTK_TYPE_TREE_DRAG_DEST()))

proc GTK_TYPE_TREE_ITEM*(): GType =
  result = gtk_tree_item_get_type()

proc GTK_TREE_ITEM*(obj: pointer): PGtkTreeItem =
  result = cast[PGtkTreeItem](GTK_CHECK_CAST(obj, GTK_TYPE_TREE_ITEM()))

proc GTK_TREE_ITEM_CLASS*(klass: pointer): PGtkTreeItemClass =
  result = cast[PGtkTreeItemClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_TREE_ITEM()))

proc GTK_IS_TREE_ITEM*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TREE_ITEM())

proc GTK_IS_TREE_ITEM_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TREE_ITEM())

proc GTK_TREE_ITEM_GET_CLASS*(obj: pointer): PGtkTreeItemClass =
  result = cast[PGtkTreeItemClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_TREE_ITEM()))

proc GTK_TREE_ITEM_SUBTREE*(obj: pointer): PGtkWidget =
  result = (GTK_TREE_ITEM(obj)).subtree

proc expanded*(a: var TGtkTreeItem): guint =
  result = (a.GtkTreeItemflag0 and bm_TGtkTreeItem_expanded) shr
      bp_TGtkTreeItem_expanded

proc set_expanded*(a: var TGtkTreeItem, `expanded`: guint) =
  a.GtkTreeItemflag0 = a.GtkTreeItemflag0 or
      (int16(`expanded` shl bp_TGtkTreeItem_expanded) and bm_TGtkTreeItem_expanded)

proc GTK_TYPE_TREE_SELECTION*(): GType =
  result = gtk_tree_selection_get_type()

proc GTK_TREE_SELECTION*(obj: pointer): PGtkTreeSelection =
  result = cast[PGtkTreeSelection](GTK_CHECK_CAST(obj, GTK_TYPE_TREE_SELECTION()))

proc GTK_TREE_SELECTION_CLASS*(klass: pointer): PGtkTreeSelectionClass =
  result = cast[PGtkTreeSelectionClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_TREE_SELECTION()))

proc GTK_IS_TREE_SELECTION*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TREE_SELECTION())

proc GTK_IS_TREE_SELECTION_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TREE_SELECTION())

proc GTK_TREE_SELECTION_GET_CLASS*(obj: pointer): PGtkTreeSelectionClass =
  result = cast[PGtkTreeSelectionClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_TREE_SELECTION()))

proc GTK_TYPE_TREE_STORE*(): GType =
  result = gtk_tree_store_get_type()

proc GTK_TREE_STORE*(obj: pointer): PGtkTreeStore =
  result = cast[PGtkTreeStore](GTK_CHECK_CAST(obj, GTK_TYPE_TREE_STORE()))

proc GTK_TREE_STORE_CLASS*(klass: pointer): PGtkTreeStoreClass =
  result = cast[PGtkTreeStoreClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_TREE_STORE()))

proc GTK_IS_TREE_STORE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TREE_STORE())

proc GTK_IS_TREE_STORE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TREE_STORE())

proc GTK_TREE_STORE_GET_CLASS*(obj: pointer): PGtkTreeStoreClass =
  result = cast[PGtkTreeStoreClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_TREE_STORE()))

proc columns_dirty*(a: var TGtkTreeStore): guint =
  result = (a.GtkTreeStoreflag0 and bm_TGtkTreeStore_columns_dirty) shr
      bp_TGtkTreeStore_columns_dirty

proc set_columns_dirty*(a: var TGtkTreeStore, `columns_dirty`: guint) =
  a.GtkTreeStoreflag0 = a.GtkTreeStoreflag0 or
      (int16(`columns_dirty` shl bp_TGtkTreeStore_columns_dirty) and
      bm_TGtkTreeStore_columns_dirty)

proc GTK_TYPE_TREE_VIEW_COLUMN*(): GType =
  result = gtk_tree_view_column_get_type()

proc GTK_TREE_VIEW_COLUMN*(obj: pointer): PGtkTreeViewColumn =
  result = cast[PGtkTreeViewColumn](GTK_CHECK_CAST(obj, GTK_TYPE_TREE_VIEW_COLUMN()))

proc GTK_TREE_VIEW_COLUMN_CLASS*(klass: pointer): PGtkTreeViewColumnClass =
  result = cast[PGtkTreeViewColumnClass](GTK_CHECK_CLASS_CAST(klass,
      GTK_TYPE_TREE_VIEW_COLUMN()))

proc GTK_IS_TREE_VIEW_COLUMN*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TREE_VIEW_COLUMN())

proc GTK_IS_TREE_VIEW_COLUMN_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TREE_VIEW_COLUMN())

proc GTK_TREE_VIEW_COLUMN_GET_CLASS*(obj: pointer): PGtkTreeViewColumnClass =
  result = cast[PGtkTreeViewColumnClass](GTK_CHECK_GET_CLASS(obj,
      GTK_TYPE_TREE_VIEW_COLUMN()))

proc visible*(a: var TGtkTreeViewColumn): guint =
  result = (a.GtkTreeViewColumnflag0 and bm_TGtkTreeViewColumn_visible) shr
      bp_TGtkTreeViewColumn_visible

proc set_visible*(a: var TGtkTreeViewColumn, `visible`: guint) =
  a.GtkTreeViewColumnflag0 = a.GtkTreeViewColumnflag0 or
      (int16(`visible` shl bp_TGtkTreeViewColumn_visible) and
      bm_TGtkTreeViewColumn_visible)

proc resizable*(a: var TGtkTreeViewColumn): guint =
  result = (a.GtkTreeViewColumnflag0 and bm_TGtkTreeViewColumn_resizable) shr
      bp_TGtkTreeViewColumn_resizable

proc set_resizable*(a: var TGtkTreeViewColumn, `resizable`: guint) =
  a.GtkTreeViewColumnflag0 = a.GtkTreeViewColumnflag0 or
      (int16(`resizable` shl bp_TGtkTreeViewColumn_resizable) and
      bm_TGtkTreeViewColumn_resizable)

proc clickable*(a: var TGtkTreeViewColumn): guint =
  result = (a.GtkTreeViewColumnflag0 and bm_TGtkTreeViewColumn_clickable) shr
      bp_TGtkTreeViewColumn_clickable

proc set_clickable*(a: var TGtkTreeViewColumn, `clickable`: guint) =
  a.GtkTreeViewColumnflag0 = a.GtkTreeViewColumnflag0 or
      (int16(`clickable` shl bp_TGtkTreeViewColumn_clickable) and
      bm_TGtkTreeViewColumn_clickable)

proc dirty*(a: var TGtkTreeViewColumn): guint =
  result = (a.GtkTreeViewColumnflag0 and bm_TGtkTreeViewColumn_dirty) shr
      bp_TGtkTreeViewColumn_dirty

proc set_dirty*(a: var TGtkTreeViewColumn, `dirty`: guint) =
  a.GtkTreeViewColumnflag0 = a.GtkTreeViewColumnflag0 or
      (int16(`dirty` shl bp_TGtkTreeViewColumn_dirty) and
      bm_TGtkTreeViewColumn_dirty)

proc show_sort_indicator*(a: var TGtkTreeViewColumn): guint =
  result = (a.GtkTreeViewColumnflag0 and bm_TGtkTreeViewColumn_show_sort_indicator) shr
      bp_TGtkTreeViewColumn_show_sort_indicator

proc set_show_sort_indicator*(a: var TGtkTreeViewColumn,
                              `show_sort_indicator`: guint) =
  a.GtkTreeViewColumnflag0 = a.GtkTreeViewColumnflag0 or
      (int16(`show_sort_indicator` shl bp_TGtkTreeViewColumn_show_sort_indicator) and
      bm_TGtkTreeViewColumn_show_sort_indicator)

proc maybe_reordered*(a: var TGtkTreeViewColumn): guint =
  result = (a.GtkTreeViewColumnflag0 and bm_TGtkTreeViewColumn_maybe_reordered) shr
      bp_TGtkTreeViewColumn_maybe_reordered

proc set_maybe_reordered*(a: var TGtkTreeViewColumn, `maybe_reordered`: guint) =
  a.GtkTreeViewColumnflag0 = a.GtkTreeViewColumnflag0 or
      (int16(`maybe_reordered` shl bp_TGtkTreeViewColumn_maybe_reordered) and
      bm_TGtkTreeViewColumn_maybe_reordered)

proc reorderable*(a: var TGtkTreeViewColumn): guint =
  result = (a.GtkTreeViewColumnflag0 and bm_TGtkTreeViewColumn_reorderable) shr
      bp_TGtkTreeViewColumn_reorderable

proc set_reorderable*(a: var TGtkTreeViewColumn, `reorderable`: guint) =
  a.GtkTreeViewColumnflag0 = a.GtkTreeViewColumnflag0 or
      (int16(`reorderable` shl bp_TGtkTreeViewColumn_reorderable) and
      bm_TGtkTreeViewColumn_reorderable)

proc use_resized_width*(a: var TGtkTreeViewColumn): guint =
  result = (a.GtkTreeViewColumnflag0 and bm_TGtkTreeViewColumn_use_resized_width) shr
      bp_TGtkTreeViewColumn_use_resized_width

proc set_use_resized_width*(a: var TGtkTreeViewColumn,
                            `use_resized_width`: guint) =
  a.GtkTreeViewColumnflag0 = a.GtkTreeViewColumnflag0 or
      (int16(`use_resized_width` shl bp_TGtkTreeViewColumn_use_resized_width) and
      bm_TGtkTreeViewColumn_use_resized_width)

proc flags*(a: PGtkRBNode): guint =
  result = (a . flag0 and bm_TGtkRBNode_flags) shr bp_TGtkRBNode_flags

proc set_flags*(a: PGtkRBNode, `flags`: guint) =
  a . flag0 = a .
      flag0 or (int16(`flags` shl bp_TGtkRBNode_flags) and bm_TGtkRBNode_flags)

proc parity*(a: PGtkRBNode): guint =
  result = (a . flag0 and bm_TGtkRBNode_parity) shr bp_TGtkRBNode_parity

proc set_parity*(a: PGtkRBNode, `parity`: guint) =
  a . flag0 = a .
      flag0 or (int16(`parity` shl bp_TGtkRBNode_parity) and bm_TGtkRBNode_parity)

proc GTK_RBNODE_GET_COLOR*(node: PGtkRBNode): guint =
  if node == nil:
    Result = GTK_RBNODE_BLACK
  elif (int(flags(node)) and GTK_RBNODE_RED) == GTK_RBNODE_RED:
    Result = GTK_RBNODE_RED
  else:
    Result = GTK_RBNODE_BLACK

proc GTK_RBNODE_SET_COLOR*(node: PGtkRBNode, color: guint) =
  if node == nil:
    return
  if ((flags(node) and (color)) != color):
    set_flags(node, flags(node) xor cint(GTK_RBNODE_RED or GTK_RBNODE_BLACK))

proc GTK_RBNODE_GET_HEIGHT*(node: PGtkRBNode): gint =
  var if_local1: gint
  if node.children != nil:
    if_local1 = node.children.root.offset
  else:
    if_local1 = 0
  result = node.offset - ((node.left.offset) + node.right.offset + if_local1)

proc GTK_RBNODE_FLAG_SET*(node: PGtkRBNode, flag: guint): bool =
  result = (node != nil) and ((flags(node) and (flag)) == flag)

proc GTK_RBNODE_SET_FLAG*(node: PGtkRBNode, flag: guint16) =
  set_flags(node, (flag) or flags(node))

proc GTK_RBNODE_UNSET_FLAG*(node: PGtkRBNode, flag: guint16) =
  set_flags(node, (not (flag)) and flags(node))

proc GTK_TREE_VIEW_FLAG_SET*(tree_view: PGtkTreeView, flag: guint): bool =
  result = ((tree_view.priv.flags) and (flag)) == flag

proc TREE_VIEW_HEADER_HEIGHT*(tree_view: PGtkTreeView): int32 =
  var if_local1: int32
  if GTK_TREE_VIEW_FLAG_SET(tree_view, GTK_TREE_VIEW_HEADERS_VISIBLE):
    if_local1 = tree_view.priv.header_height
  else:
    if_local1 = 0
  result = if_local1

proc TREE_VIEW_COLUMN_REQUESTED_WIDTH*(column: PGtkTreeViewColumn): int32 =
  var MinWidth, MaxWidth: int
  if column.min_width != -1'i32:
    MinWidth = column.min_width
  else:
    MinWidth = column.requested_width
  if column.max_width != - 1'i32:
    MaxWidth = column.max_width
  else:
    MaxWidth = column.requested_width
  result = CLAMP(column.requested_width, MinWidth, MaxWidth)

proc TREE_VIEW_DRAW_EXPANDERS*(tree_view: PGtkTreeView): bool =
  result = (not (GTK_TREE_VIEW_FLAG_SET(tree_view, GTK_TREE_VIEW_IS_LIST))) and
      (GTK_TREE_VIEW_FLAG_SET(tree_view, GTK_TREE_VIEW_SHOW_EXPANDERS))

proc TREE_VIEW_COLUMN_DRAG_DEAD_MULTIPLIER*(tree_view: PGtkTreeView): int32 =
  result = 10'i32 * (TREE_VIEW_HEADER_HEIGHT(tree_view))

proc scroll_to_use_align*(a: var TGtkTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_scroll_to_use_align) shr
      bp_TGtkTreeViewPrivate_scroll_to_use_align

proc set_scroll_to_use_align*(a: var TGtkTreeViewPrivate,
                              `scroll_to_use_align`: guint) =
  a.flag0 = a.flag0 or
      (int16(`scroll_to_use_align` shl bp_TGtkTreeViewPrivate_scroll_to_use_align) and
      bm_TGtkTreeViewPrivate_scroll_to_use_align)

proc fixed_height_check*(a: var TGtkTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_fixed_height_check) shr
      bp_TGtkTreeViewPrivate_fixed_height_check

proc set_fixed_height_check*(a: var TGtkTreeViewPrivate,
                             `fixed_height_check`: guint) =
  a.flag0 = a.flag0 or
      (int16(`fixed_height_check` shl bp_TGtkTreeViewPrivate_fixed_height_check) and
      bm_TGtkTreeViewPrivate_fixed_height_check)

proc reorderable*(a: var TGtkTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_reorderable) shr
      bp_TGtkTreeViewPrivate_reorderable

proc set_reorderable*(a: var TGtkTreeViewPrivate, `reorderable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`reorderable` shl bp_TGtkTreeViewPrivate_reorderable) and
      bm_TGtkTreeViewPrivate_reorderable)

proc header_has_focus*(a: var TGtkTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_header_has_focus) shr
      bp_TGtkTreeViewPrivate_header_has_focus

proc set_header_has_focus*(a: var TGtkTreeViewPrivate, `header_has_focus`: guint) =
  a.flag0 = a.flag0 or
      (int16(`header_has_focus` shl bp_TGtkTreeViewPrivate_header_has_focus) and
      bm_TGtkTreeViewPrivate_header_has_focus)

proc drag_column_window_state*(a: var TGtkTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_drag_column_window_state) shr
      bp_TGtkTreeViewPrivate_drag_column_window_state

proc set_drag_column_window_state*(a: var TGtkTreeViewPrivate,
                                   `drag_column_window_state`: guint) =
  a.flag0 = a.flag0 or
      (int16(`drag_column_window_state` shl
      bp_TGtkTreeViewPrivate_drag_column_window_state) and
      bm_TGtkTreeViewPrivate_drag_column_window_state)

proc has_rules*(a: var TGtkTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_has_rules) shr
      bp_TGtkTreeViewPrivate_has_rules

proc set_has_rules*(a: var TGtkTreeViewPrivate, `has_rules`: guint) =
  a.flag0 = a.flag0 or
      (int16(`has_rules` shl bp_TGtkTreeViewPrivate_has_rules) and
      bm_TGtkTreeViewPrivate_has_rules)

proc mark_rows_col_dirty*(a: var TGtkTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_mark_rows_col_dirty) shr
      bp_TGtkTreeViewPrivate_mark_rows_col_dirty

proc set_mark_rows_col_dirty*(a: var TGtkTreeViewPrivate,
                              `mark_rows_col_dirty`: guint) =
  a.flag0 = a.flag0 or
      (int16(`mark_rows_col_dirty` shl bp_TGtkTreeViewPrivate_mark_rows_col_dirty) and
      bm_TGtkTreeViewPrivate_mark_rows_col_dirty)

proc enable_search*(a: var TGtkTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_enable_search) shr
      bp_TGtkTreeViewPrivate_enable_search

proc set_enable_search*(a: var TGtkTreeViewPrivate, `enable_search`: guint) =
  a.flag0 = a.flag0 or
      (int16(`enable_search` shl bp_TGtkTreeViewPrivate_enable_search) and
      bm_TGtkTreeViewPrivate_enable_search)

proc disable_popdown*(a: var TGtkTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_disable_popdown) shr
      bp_TGtkTreeViewPrivate_disable_popdown

proc set_disable_popdown*(a: var TGtkTreeViewPrivate, `disable_popdown`: guint) =
  a.flag0 = a.flag0 or
      (int16(`disable_popdown` shl bp_TGtkTreeViewPrivate_disable_popdown) and
      bm_TGtkTreeViewPrivate_disable_popdown)

proc GTK_TREE_VIEW_SET_FLAG*(tree_view: PGtkTreeView, flag: guint) =
  tree_view . priv . flags = tree_view . priv . flags or (flag)

proc GTK_TREE_VIEW_UNSET_FLAG*(tree_view: PGtkTreeView, flag: guint) =
  tree_view . priv . flags = tree_view . priv . flags and not (flag)

proc GTK_TYPE_TREE_VIEW*(): GType =
  result = gtk_tree_view_get_type()

proc GTK_TREE_VIEW*(obj: pointer): PGtkTreeView =
  result = cast[PGtkTreeView](GTK_CHECK_CAST(obj, GTK_TYPE_TREE_VIEW()))

proc GTK_TREE_VIEW_CLASS*(klass: pointer): PGtkTreeViewClass =
  result = cast[PGtkTreeViewClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_TREE_VIEW()))

proc GTK_IS_TREE_VIEW*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_TREE_VIEW())

proc GTK_IS_TREE_VIEW_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_TREE_VIEW())

proc GTK_TREE_VIEW_GET_CLASS*(obj: pointer): PGtkTreeViewClass =
  result = cast[PGtkTreeViewClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_TREE_VIEW()))

proc GTK_TYPE_VBUTTON_BOX*(): GType =
  result = gtk_vbutton_box_get_type()

proc GTK_VBUTTON_BOX*(obj: pointer): PGtkVButtonBox =
  result = cast[PGtkVButtonBox](GTK_CHECK_CAST(obj, GTK_TYPE_VBUTTON_BOX()))

proc GTK_VBUTTON_BOX_CLASS*(klass: pointer): PGtkVButtonBoxClass =
  result = cast[PGtkVButtonBoxClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_VBUTTON_BOX()))

proc GTK_IS_VBUTTON_BOX*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_VBUTTON_BOX())

proc GTK_IS_VBUTTON_BOX_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_VBUTTON_BOX())

proc GTK_VBUTTON_BOX_GET_CLASS*(obj: pointer): PGtkVButtonBoxClass =
  result = cast[PGtkVButtonBoxClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_VBUTTON_BOX()))

proc GTK_TYPE_VIEWPORT*(): GType =
  result = gtk_viewport_get_type()

proc GTK_VIEWPORT*(obj: pointer): PGtkViewport =
  result = cast[PGtkViewport](GTK_CHECK_CAST(obj, GTK_TYPE_VIEWPORT()))

proc GTK_VIEWPORT_CLASS*(klass: pointer): PGtkViewportClass =
  result = cast[PGtkViewportClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_VIEWPORT()))

proc GTK_IS_VIEWPORT*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_VIEWPORT())

proc GTK_IS_VIEWPORT_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_VIEWPORT())

proc GTK_VIEWPORT_GET_CLASS*(obj: pointer): PGtkViewportClass =
  result = cast[PGtkViewportClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_VIEWPORT()))

proc GTK_TYPE_VPANED*(): GType =
  result = gtk_vpaned_get_type()

proc GTK_VPANED*(obj: pointer): PGtkVPaned =
  result = cast[PGtkVPaned](GTK_CHECK_CAST(obj, GTK_TYPE_VPANED()))

proc GTK_VPANED_CLASS*(klass: pointer): PGtkVPanedClass =
  result = cast[PGtkVPanedClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_VPANED()))

proc GTK_IS_VPANED*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_VPANED())

proc GTK_IS_VPANED_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_VPANED())

proc GTK_VPANED_GET_CLASS*(obj: pointer): PGtkVPanedClass =
  result = cast[PGtkVPanedClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_VPANED()))

proc GTK_TYPE_VRULER*(): GType =
  result = gtk_vruler_get_type()

proc GTK_VRULER*(obj: pointer): PGtkVRuler =
  result = cast[PGtkVRuler](GTK_CHECK_CAST(obj, GTK_TYPE_VRULER()))

proc GTK_VRULER_CLASS*(klass: pointer): PGtkVRulerClass =
  result = cast[PGtkVRulerClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_VRULER()))

proc GTK_IS_VRULER*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_VRULER())

proc GTK_IS_VRULER_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_VRULER())

proc GTK_VRULER_GET_CLASS*(obj: pointer): PGtkVRulerClass =
  result = cast[PGtkVRulerClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_VRULER()))

proc GTK_TYPE_VSCALE*(): GType =
  result = gtk_vscale_get_type()

proc GTK_VSCALE*(obj: pointer): PGtkVScale =
  result = cast[PGtkVScale](GTK_CHECK_CAST(obj, GTK_TYPE_VSCALE()))

proc GTK_VSCALE_CLASS*(klass: pointer): PGtkVScaleClass =
  result = cast[PGtkVScaleClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_VSCALE()))

proc GTK_IS_VSCALE*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_VSCALE())

proc GTK_IS_VSCALE_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_VSCALE())

proc GTK_VSCALE_GET_CLASS*(obj: pointer): PGtkVScaleClass =
  result = cast[PGtkVScaleClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_VSCALE()))

proc GTK_TYPE_VSCROLLBAR*(): GType =
  result = gtk_vscrollbar_get_type()

proc GTK_VSCROLLBAR*(obj: pointer): PGtkVScrollbar =
  result = cast[PGtkVScrollbar](GTK_CHECK_CAST(obj, GTK_TYPE_VSCROLLBAR()))

proc GTK_VSCROLLBAR_CLASS*(klass: pointer): PGtkVScrollbarClass =
  result = cast[PGtkVScrollbarClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_VSCROLLBAR()))

proc GTK_IS_VSCROLLBAR*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_VSCROLLBAR())

proc GTK_IS_VSCROLLBAR_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_VSCROLLBAR())

proc GTK_VSCROLLBAR_GET_CLASS*(obj: pointer): PGtkVScrollbarClass =
  result = cast[PGtkVScrollbarClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_VSCROLLBAR()))

proc GTK_TYPE_VSEPARATOR*(): GType =
  result = gtk_vseparator_get_type()

proc GTK_VSEPARATOR*(obj: pointer): PGtkVSeparator =
  result = cast[PGtkVSeparator](GTK_CHECK_CAST(obj, GTK_TYPE_VSEPARATOR()))

proc GTK_VSEPARATOR_CLASS*(klass: pointer): PGtkVSeparatorClass =
  result = cast[PGtkVSeparatorClass](GTK_CHECK_CLASS_CAST(klass, GTK_TYPE_VSEPARATOR()))

proc GTK_IS_VSEPARATOR*(obj: pointer): bool =
  result = GTK_CHECK_TYPE(obj, GTK_TYPE_VSEPARATOR())

proc GTK_IS_VSEPARATOR_CLASS*(klass: pointer): bool =
  result = GTK_CHECK_CLASS_TYPE(klass, GTK_TYPE_VSEPARATOR())

proc GTK_VSEPARATOR_GET_CLASS*(obj: pointer): PGtkVSeparatorClass =
  result = cast[PGtkVSeparatorClass](GTK_CHECK_GET_CLASS(obj, GTK_TYPE_VSEPARATOR()))


# these were missing:
type
   PGtkCellLayout* = pointer
   PPGtkCellLayout* = ptr PGtkCellLayout
   PGtkSignalRunType* = ptr TGtkSignalRunType
   TGtkSignalRunType* =  int32
   PGtkFileChooserAction* = ptr TGtkFileChooserAction
   TGtkFileChooserAction* = enum 
     GTK_FILE_CHOOSER_ACTION_OPEN,
     GTK_FILE_CHOOSER_ACTION_SAVE,
     GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER,
     GTK_FILE_CHOOSER_ACTION_CREATE_FOLDER
   PGtkFileChooserError* = ptr TGtkFileChooserError
   TGtkFileChooserError* = enum
     GTK_FILE_CHOOSER_ERROR_NONEXISTENT,
     GTK_FILE_CHOOSER_ERROR_BAD_FILENAME


const 
  GTK_ARG_READWRITE* = GTK_ARG_READABLE or GTK_ARG_WRITABLE

proc gtk_binding_entry_add_signal*(binding_set: PGtkBindingSet, keyval: guint, 
                                   modifiers: TGdkModifierType, 
                                   signal_name: cstring, n_args: guint){.varargs, 
    importc, cdecl, dynlib: gtklib.}
proc gtk_clist_new_with_titles*(columns: gint): PGtkCList{.varargs, cdecl, 
    importc, dynlib: gtklib.}
proc gtk_clist_prepend*(clist: PGtkCList): gint{.importc, varargs, cdecl, dynlib: gtklib.}
proc gtk_clist_append*(clist: PGtkCList): gint{.importc, varargs, cdecl, dynlib: gtklib.}
proc gtk_clist_insert*(clist: PGtkCList, row: gint): gint{.varargs, cdecl, 
    importc, dynlib: gtklib.}
proc gtk_cell_layout_set_attributes*(cell_layout: PGtkCellLayout, 
                                     cell: PGtkCellRenderer){.cdecl, varargs, 
    importc, dynlib: gtklib, importc: "gtk_cell_layout_set_attributes".}
proc gtk_container_add_with_properties*(container: PGtkContainer, 
                                        widget: PGtkWidget, 
                                        first_prop_name: cstring){.varargs, 
    importc, cdecl, dynlib: gtklib.}
proc gtk_container_child_set*(container: PGtkContainer, child: PGtkWidget, 
                              first_prop_name: cstring){.varargs, cdecl, 
    importc, dynlib: gtklib.}
proc gtk_container_child_get*(container: PGtkContainer, child: PGtkWidget, 
                              first_prop_name: cstring){.varargs, cdecl, 
    importc, dynlib: gtklib.}
proc gtk_container_child_set_valist*(container: PGtkContainer, 
                                     child: PGtkWidget, 
                                     first_property_name: cstring){.varargs, 
    importc, cdecl, dynlib: gtklib.}
proc gtk_container_child_get_valist*(container: PGtkContainer, 
                                     child: PGtkWidget, 
                                     first_property_name: cstring){.varargs, 
    importc, cdecl, dynlib: gtklib.}
proc gtk_ctree_new_with_titles*(columns: gint, tree_column: gint): PGtkCTree{.
    importc, varargs, cdecl, dynlib: gtklib.}
proc gtk_curve_get_vector*(curve: PGtkCurve, veclen: int32){.varargs, cdecl, 
    importc, dynlib: gtklib.}
proc gtk_curve_set_vector*(curve: PGtkCurve, veclen: int32){.varargs, cdecl, 
    importc, dynlib: gtklib.}
proc gtk_dialog_add_buttons*(dialog: PGtkDialog, first_button_text: cstring){.
    varargs, cdecl, importc, dynlib: gtklib.}
proc gtk_dialog_new_with_buttons*(title: cstring, parent: PGtkWindow, 
                                  flags: TGtkDialogFlags, 
                                  first_button_text: cstring): PGtkDialog{.
    varargs, cdecl, importc, dynlib: gtklib.}
proc gtk_list_store_new*(n_columns: gint): PGtkListStore{.varargs, cdecl, 
    importc, dynlib: gtklib.}
proc gtk_list_store_set*(list_store: PGtkListStore, iter: PGtkTreeIter){.
    varargs, cdecl, importc, dynlib: gtklib.}
proc gtk_list_store_set_valist*(list_store: PGtkListStore, iter: PGtkTreeIter){.
    varargs, cdecl, importc, dynlib: gtklib.}
proc gtk_message_dialog_new*(parent: PGtkWindow, flags: TGtkDialogFlags, 
                             thetype: TGtkMessageType, buttons: TGtkButtonsType, 
                             message_format: cstring): PGtkMessageDialog{.varargs, 
    cdecl, importc, dynlib: gtklib.}
proc gtk_signal_new*(name: cstring, signal_flags: TGtkSignalRunType, 
                     object_type: TGtkType, function_offset: guint, 
                     marshaller: TGtkSignalMarshaller, return_val: TGtkType, 
                     n_args: guint): guint{.
                     varargs, importc, cdecl, dynlib: gtklib.}
proc gtk_signal_emit*(anObject: PGtkObject, signal_id: guint){.varargs, cdecl, 
    importc, dynlib: gtklib.}
proc gtk_signal_emit_by_name*(anObject: PGtkObject, name: cstring){.varargs, 
    cdecl, importc, dynlib: gtklib.}
proc gtk_text_buffer_insert_with_tags*(buffer: PGtkTextBuffer, 
                                       iter: PGtkTextIter, text: cstring, 
                                       length: gint, first_tag: PGtkTextTag){.
    varargs, importc, cdecl, dynlib: gtklib.}
proc gtk_text_buffer_insert_with_tags_by_name*(buffer: PGtkTextBuffer, 
    iter: PGtkTextIter, text: cstring, length: gint, first_tag_name: cstring){.
    varargs, importc, cdecl, dynlib: gtklib.}
proc gtk_text_buffer_create_tag*(buffer: PGtkTextBuffer, tag_name: cstring, 
                                 first_property_name: cstring): PGtkTextTag{.
    varargs, importc, cdecl, dynlib: gtklib.}
proc gtk_tree_model_get*(tree_model: PGtkTreeModel, iter: PGtkTreeIter){.
    varargs, importc, cdecl, dynlib: gtklib.}
proc gtk_tree_model_get_valist*(tree_model: PGtkTreeModel, iter: PGtkTreeIter){.
    varargs, importc, cdecl, dynlib: gtklib.}
proc gtk_tree_store_new*(n_columns: gint): PGtkTreeStore{.varargs, cdecl, 
    importc, dynlib: gtklib.}
proc gtk_tree_store_set*(tree_store: PGtkTreeStore, iter: PGtkTreeIter){.
    varargs, cdecl, importc, dynlib: gtklib.}
proc gtk_tree_store_set_valist*(tree_store: PGtkTreeStore, iter: PGtkTreeIter){.
    varargs, cdecl, importc, dynlib: gtklib.}
proc gtk_tree_store_iter_is_valid*(tree_store: PGtkTreeStore, iter: PGtkTreeIter): gboolean{.
    cdecl, importc, dynlib: gtklib.}
proc gtk_tree_store_reorder*(tree_store: PGtkTreeStore, parent: PGtkTreeIter, 
                             new_order: pgint){.cdecl, importc, dynlib: gtklib.}
proc gtk_tree_store_swap*(tree_store: PGtkTreeStore, a: PGtkTreeIter, 
                          b: PGtkTreeIter){.cdecl, importc, dynlib: gtklib.}
proc gtk_tree_store_move_before*(tree_store: PGtkTreeStore, iter: PGtkTreeIter, 
                                 position: PGtkTreeIter){.cdecl,importc,  dynlib: gtklib.}
proc gtk_tree_store_move_after*(tree_store: PGtkTreeStore, iter: PGtkTreeIter, 
                                position: PGtkTreeIter){.cdecl,importc,  dynlib: gtklib.}
proc gtk_tree_view_insert_column_with_attributes*(tree_view: PGtkTreeView, 
    position: gint, title: cstring, cell: PGtkCellRenderer): gint{.varargs, 
    importc, cdecl, dynlib: gtklib.}
proc gtk_tree_view_column_new_with_attributes*(title: cstring, 
    cell: PGtkCellRenderer): PGtkTreeViewColumn{.importc, varargs, cdecl, dynlib: gtklib.}
proc gtk_tree_view_column_set_attributes*(tree_column: PGtkTreeViewColumn, 
    cell_renderer: PGtkCellRenderer){.importc, varargs, cdecl, dynlib: gtklib.}
proc gtk_widget_new*(thetype: TGtkType, first_property_name: cstring): PGtkWidget{.
    importc, varargs, cdecl, dynlib: gtklib.}
proc gtk_widget_set*(widget: PGtkWidget, first_property_name: cstring){.varargs, 
    importc, cdecl, dynlib: gtklib.}
proc gtk_widget_queue_clear*(widget: PGtkWidget){.importc, cdecl, dynlib: gtklib.}
proc gtk_widget_queue_clear_area*(widget: PGtkWidget, x: gint, y: gint, 
                                  width: gint, height: gint){.cdecl, 
    importc, dynlib: gtklib.}
proc gtk_widget_draw*(widget: PGtkWidget, area: PGdkRectangle){.cdecl, 
    importc, dynlib: gtklib.}
proc gtk_widget_style_get_valist*(widget: PGtkWidget, 
                                  first_property_name: cstring){.varargs, cdecl, 
    importc, dynlib: gtklib.}
proc gtk_widget_style_get*(widget: PGtkWidget, first_property_name: cstring){.
    varargs, cdecl, importc, dynlib: gtklib.}
proc gtk_file_chooser_dialog_new*(title: cstring, parent: PGtkWindow, 
                                  action: TGtkFileChooserAction, 
                                  first_button_text: cstring): PGtkDialog {.cdecl, 
    varargs, dynlib: gtklib, importc: "gtk_file_chooser_dialog_new".}
proc gtk_file_chooser_dialog_new_with_backend*(title: cstring, 
    parent: PGtkWindow, action: TGtkFileChooserAction, backend: cstring, 
    first_button_text: cstring): PGtkDialog {.varargs, cdecl, dynlib: gtklib, 
    importc: "gtk_file_chooser_dialog_new_with_backend".}
proc gtk_object_ref*(anObject: PGtkObject): PGtkObject{.cdecl,importc,  dynlib: gtklib.}
proc gtk_object_unref*(anObject: PGtkObject){.cdecl, importc, dynlib: gtklib.}
proc gtk_object_weakref*(anObject: PGtkObject, notify: TGtkDestroyNotify, 
                         data: gpointer){.cdecl, importc, dynlib: gtklib.}
proc gtk_object_weakunref*(anObject: PGtkObject, notify: TGtkDestroyNotify, 
                           data: gpointer){.cdecl, importc, dynlib: gtklib.}
proc gtk_object_set_data*(anObject: PGtkObject, key: cstring, data: gpointer){.
    cdecl, importc, dynlib: gtklib.}
proc gtk_object_set_data_full*(anObject: PGtkObject, key: cstring, 
                               data: gpointer, destroy: TGtkDestroyNotify){.
    importc, cdecl, dynlib: gtklib.}
proc gtk_object_remove_data*(anObject: PGtkObject, key: cstring){.cdecl, 
    importc, dynlib: gtklib.}
proc gtk_object_get_data*(anObject: PGtkObject, key: cstring): gpointer{.cdecl, 
    importc, dynlib: gtklib.}
proc gtk_object_remove_no_notify*(anObject: PGtkObject, key: cstring){.cdecl, 
    importc, dynlib: gtklib.}
proc gtk_object_set_user_data*(anObject: PGtkObject, data: gpointer){.cdecl, 
    importc, dynlib: gtklib.}
proc gtk_object_get_user_data*(anObject: PGtkObject): gpointer{.cdecl, 
    importc, dynlib: gtklib.}
proc gtk_object_set_data_by_id*(anObject: PGtkObject, data_id: TGQuark, 
                                data: gpointer){.cdecl, importc, dynlib: gtklib.}
proc gtk_object_set_data_by_id_full*(anObject: PGtkObject, data_id: TGQuark, 
                                     data: gpointer, destroy: TGtkDestroyNotify){.
    cdecl, importc, dynlib: gtklib.}
proc gtk_object_get_data_by_id*(anObject: PGtkObject, data_id: TGQuark): gpointer{.
    cdecl, importc, dynlib: gtklib.}
proc gtk_object_remove_data_by_id*(anObject: PGtkObject, data_id: TGQuark){.
    cdecl, importc, dynlib: gtklib.}
proc gtk_object_remove_no_notify_by_id*(anObject: PGtkObject, key_id: TGQuark){.
    cdecl, importc, dynlib: gtklib.}
proc gtk_object_data_try_key*(str: cstring): TGQuark{.cdecl, importc, dynlib: gtklib.}
proc gtk_object_data_force_id*(str: cstring): TGQuark{.cdecl, importc, dynlib: gtklib.}
proc gtk_object_get*(anObject: PGtkObject, first_property_name: cstring){.cdecl, 
    importc, varargs, dynlib: gtklib.}
proc gtk_object_set*(anObject: PGtkObject, first_property_name: cstring){.cdecl, 
    importc, varargs, dynlib: gtklib.}
proc gtk_object_add_arg_type*(arg_name: cstring, arg_type: TGtkType, 
                              arg_flags: guint, arg_id: guint){.cdecl, 
    importc, dynlib: gtklib.}


type
  PGtkFileChooser* = pointer
  PPGtkFileChooser* = ptr PGtkFileChooser

type 
  PGtkFileFilter* = pointer
  PPGtkFileFilter* = ref PGtkFileFilter
  PGtkFileFilterFlags* = ref TGtkFileFilterFlags
  TGtkFileFilterFlags* = enum 
    GTK_FILE_FILTER_FILENAME = 1 shl 0, GTK_FILE_FILTER_URI = 1 shl 1, 
    GTK_FILE_FILTER_DISPLAY_NAME = 1 shl 2, GTK_FILE_FILTER_MIME_TYPE = 1 shl 3
  PGtkFileFilterInfo* = ref TGtkFileFilterInfo
  TGtkFileFilterInfo* {.final, pure.} = object 
    contains*: TGtkFileFilterFlags
    filename*: cstring
    uri*: cstring
    display_name*: cstring
    mime_type*: cstring

  TGtkFileFilterFunc* = proc (filter_info: PGtkFileFilterInfo, data: gpointer): gboolean{.
      cdecl.}

proc GTK_TYPE_FILE_FILTER*(): GType
proc GTK_FILE_FILTER*(obj: pointer): PGtkFileFilter
proc GTK_IS_FILE_FILTER*(obj: pointer): gboolean
proc gtk_file_filter_get_type*(): GType{.cdecl, dynlib: gtklib, 
    importc: "gtk_file_filter_get_type".}
proc gtk_file_filter_new*(): PGtkFileFilter{.cdecl, dynlib: gtklib, 
    importc: "gtk_file_filter_new".}
proc gtk_file_filter_set_name*(filter: PGtkFileFilter, name: cstring){.cdecl, 
    dynlib: gtklib, importc: "gtk_file_filter_set_name".}
proc gtk_file_filter_get_name*(filter: PGtkFileFilter): cstring{.cdecl, 
    dynlib: gtklib, importc: "gtk_file_filter_get_name".}
proc gtk_file_filter_add_mime_type*(filter: PGtkFileFilter, mime_type: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_file_filter_add_mime_type".}
proc gtk_file_filter_add_pattern*(filter: PGtkFileFilter, pattern: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_file_filter_add_pattern".}
proc gtk_file_filter_add_custom*(filter: PGtkFileFilter, 
                                 needed: TGtkFileFilterFlags, 
                                 func: TGtkFileFilterFunc, data: gpointer, 
                                 notify: TGDestroyNotify){.cdecl, 
    dynlib: gtklib, importc: "gtk_file_filter_add_custom".}
proc gtk_file_filter_get_needed*(filter: PGtkFileFilter): TGtkFileFilterFlags{.
    cdecl, dynlib: gtklib, importc: "gtk_file_filter_get_needed".}
proc gtk_file_filter_filter*(filter: PGtkFileFilter, 
                             filter_info: PGtkFileFilterInfo): gboolean{.cdecl, 
    dynlib: gtklib, importc: "gtk_file_filter_filter".}

proc GTK_TYPE_FILE_FILTER(): GType = 
  result = gtk_file_filter_get_type()

proc GTK_FILE_FILTER(obj: pointer): PGtkFileFilter = 
  result = cast[PGtkFileFilter](G_TYPE_CHECK_INSTANCE_CAST(obj, 
                                GTK_TYPE_FILE_FILTER()))

proc GTK_IS_FILE_FILTER(obj: pointer): gboolean = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GTK_TYPE_FILE_FILTER())


proc gtk_file_chooser_get_type*():GType {.
  cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_type".}

proc gtk_file_chooser_error_quark*(): TGQuark {.
  cdecl, dynlib: gtklib, importc: "gtk_file_chooser_error_quark".}

proc GTK_TYPE_FILE_CHOOSER*(): GType =
  result = gtk_file_chooser_get_type()

proc GTK_FILE_CHOOSER*(obj: pointer): PGtkFileChooser =
  result = cast[PGtkFileChooser](G_TYPE_CHECK_INSTANCE_CAST(obj, 
    GTK_TYPE_FILE_CHOOSER()))

proc GTK_IS_FILE_CHOOSER*(obj: pointer): gboolean =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GTK_TYPE_FILE_CHOOSER())

proc gtk_file_chooser_set_action*(chooser: PGtkFileChooser, 
                                  action: TGtkFileChooserAction){.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_set_action".}
proc gtk_file_chooser_get_action*(chooser: PGtkFileChooser): TGtkFileChooserAction{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_action".}
proc gtk_file_chooser_set_local_only*(chooser: PGtkFileChooser, 
                                      local_only: gboolean){.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_set_local_only".}
proc gtk_file_chooser_get_local_only*(chooser: PGtkFileChooser): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_local_only".}
proc gtk_file_chooser_set_select_multiple*(chooser: PGtkFileChooser, 
    select_multiple: gboolean){.cdecl, dynlib: gtklib, 
                                importc: "gtk_file_chooser_set_select_multiple".}
proc gtk_file_chooser_get_select_multiple*(chooser: PGtkFileChooser): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_select_multiple".}
proc gtk_file_chooser_set_current_name*(chooser: PGtkFileChooser, name: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_set_current_name".}
proc gtk_file_chooser_get_filename*(chooser: PGtkFileChooser): cstring{.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_get_filename".}
proc gtk_file_chooser_set_filename*(chooser: PGtkFileChooser, filename: cstring): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_set_filename".}
proc gtk_file_chooser_select_filename*(chooser: PGtkFileChooser, 
                                       filename: cstring): gboolean{.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_select_filename".}
proc gtk_file_chooser_unselect_filename*(chooser: PGtkFileChooser, 
    filename: cstring){.cdecl, dynlib: gtklib, 
                        importc: "gtk_file_chooser_unselect_filename".}
proc gtk_file_chooser_select_all*(chooser: PGtkFileChooser){.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_select_all".}
proc gtk_file_chooser_unselect_all*(chooser: PGtkFileChooser){.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_unselect_all".}
proc gtk_file_chooser_get_filenames*(chooser: PGtkFileChooser): PGSList{.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_get_filenames".}
proc gtk_file_chooser_set_current_folder*(chooser: PGtkFileChooser, 
    filename: cstring): gboolean{.cdecl, dynlib: gtklib, 
                                 importc: "gtk_file_chooser_set_current_folder".}
proc gtk_file_chooser_get_current_folder*(chooser: PGtkFileChooser): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_current_folder".}
proc gtk_file_chooser_get_uri*(chooser: PGtkFileChooser): cstring{.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_get_uri".}
proc gtk_file_chooser_set_uri*(chooser: PGtkFileChooser, uri: cstring): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_set_uri".}
proc gtk_file_chooser_select_uri*(chooser: PGtkFileChooser, uri: cstring): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_select_uri".}
proc gtk_file_chooser_unselect_uri*(chooser: PGtkFileChooser, uri: cstring){.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_unselect_uri".}
proc gtk_file_chooser_get_uris*(chooser: PGtkFileChooser): PGSList{.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_get_uris".}
proc gtk_file_chooser_set_current_folder_uri*(chooser: PGtkFileChooser, 
    uri: cstring): gboolean{.cdecl, dynlib: gtklib, 
                            importc: "gtk_file_chooser_set_current_folder_uri".}
proc gtk_file_chooser_get_current_folder_uri*(chooser: PGtkFileChooser): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_current_folder_uri".}
proc gtk_file_chooser_set_preview_widget*(chooser: PGtkFileChooser, 
    preview_widget: PGtkWidget){.cdecl, dynlib: gtklib, 
                                 importc: "gtk_file_chooser_set_preview_widget".}
proc gtk_file_chooser_get_preview_widget*(chooser: PGtkFileChooser): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_preview_widget".}
proc gtk_file_chooser_set_preview_widget_active*(chooser: PGtkFileChooser, 
    active: gboolean){.cdecl, dynlib: gtklib, 
                       importc: "gtk_file_chooser_set_preview_widget_active".}
proc gtk_file_chooser_get_preview_widget_active*(chooser: PGtkFileChooser): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_preview_widget_active".}
proc gtk_file_chooser_set_use_preview_label*(chooser: PGtkFileChooser, 
    use_label: gboolean){.cdecl, dynlib: gtklib, 
                          importc: "gtk_file_chooser_set_use_preview_label".}
proc gtk_file_chooser_get_use_preview_label*(chooser: PGtkFileChooser): gboolean{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_use_preview_label".}
proc gtk_file_chooser_get_preview_filename*(chooser: PGtkFileChooser): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_preview_filename".}
proc gtk_file_chooser_get_preview_uri*(chooser: PGtkFileChooser): cstring{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_preview_uri".}
proc gtk_file_chooser_set_extra_widget*(chooser: PGtkFileChooser, 
                                        extra_widget: PGtkWidget){.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_set_extra_widget".}
proc gtk_file_chooser_get_extra_widget*(chooser: PGtkFileChooser): PGtkWidget{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_extra_widget".}
proc gtk_file_chooser_add_filter*(chooser: PGtkFileChooser, 
                                  filter: PGtkFileFilter){.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_add_filter".}
proc gtk_file_chooser_remove_filter*(chooser: PGtkFileChooser, 
                                     filter: PGtkFileFilter){.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_remove_filter".}
proc gtk_file_chooser_list_filters*(chooser: PGtkFileChooser): PGSList{.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_list_filters".}
proc gtk_file_chooser_set_filter*(chooser: PGtkFileChooser, 
                                  filter: PGtkFileFilter){.cdecl, 
    dynlib: gtklib, importc: "gtk_file_chooser_set_filter".}
proc gtk_file_chooser_get_filter*(chooser: PGtkFileChooser): PGtkFileFilter{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_get_filter".}
proc gtk_file_chooser_add_shortcut_folder*(chooser: PGtkFileChooser, 
    folder: cstring, error: pointer): gboolean{.cdecl, dynlib: gtklib, 
    importc: "gtk_file_chooser_add_shortcut_folder".}
proc gtk_file_chooser_remove_shortcut_folder*(chooser: PGtkFileChooser, 
    folder: cstring, error: pointer): gboolean{.cdecl, dynlib: gtklib, 
    importc: "gtk_file_chooser_remove_shortcut_folder".}
proc gtk_file_chooser_list_shortcut_folders*(chooser: PGtkFileChooser): PGSList{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_list_shortcut_folders".}
proc gtk_file_chooser_add_shortcut_folder_uri*(chooser: PGtkFileChooser, 
    uri: cstring, error: pointer): gboolean{.cdecl, dynlib: gtklib, 
    importc: "gtk_file_chooser_add_shortcut_folder_uri".}
proc gtk_file_chooser_remove_shortcut_folder_uri*(chooser: PGtkFileChooser, 
    uri: cstring, error: pointer): gboolean{.cdecl, dynlib: gtklib, 
    importc: "gtk_file_chooser_remove_shortcut_folder_uri".}
proc gtk_file_chooser_list_shortcut_folder_uris*(chooser: PGtkFileChooser): PGSList{.
    cdecl, dynlib: gtklib, importc: "gtk_file_chooser_list_shortcut_folder_uris".}

proc gtk_file_chooser_set_do_overwrite_confirmation*(chooser: PGtkFileChooser,
    do_overwrite_confirmation: gboolean) {.cdecl, dynlib: gtklib, 
    importc: "gtk_file_chooser_set_do_overwrite_confirmation".}

proc gtk_nimrod_init*() =
  var
    cmdLine {.importc: "cmdLine".}: array [0..255, cstring]
    cmdCount {.importc: "cmdCount".}: cint
  gtk_init(addr(cmdLine), addr(cmdCount))
