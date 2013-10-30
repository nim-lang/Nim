{.deadCodeElim: on.}
import
  glib2, atk, pango, gdk2pixbuf, gdk2

export gbool, toBool

when defined(win32):
  const
    lib = "libgtk-win32-2.0-0.dll"
elif defined(macosx):
  const
    lib = "libgtk-x11-2.0.dylib"
  # linklib gtk-x11-2.0
  # linklib gdk-x11-2.0
  # linklib pango-1.0.0
  # linklib glib-2.0.0
  # linklib gobject-2.0.0
  # linklib gdk_pixbuf-2.0.0
  # linklib atk-1.0.0
else:
  const
    lib = "libgtk-x11-2.0.so(|.0)"

const
  MAX_COMPOSE_LEN* = 7

type
  PObject* = ptr TObject
  PPGtkObject* = ptr PObject
  PArg* = ptr TArg
  PType* = ptr TType
  TType* = GType
  PWidget* = ptr TWidget
  PMisc* = ptr TMisc
  PLabel* = ptr TLabel
  PMenu* = ptr TMenu
  PAnchorType* = ptr TAnchorType
  TAnchorType* = int32
  PArrowType* = ptr TArrowType
  TArrowType* = int32
  PAttachOptions* = ptr TAttachOptions
  TAttachOptions* = int32
  PButtonBoxStyle* = ptr TButtonBoxStyle
  TButtonBoxStyle* = int32
  PCurveType* = ptr TCurveType
  TCurveType* = int32
  PDeleteType* = ptr TDeleteType
  TDeleteType* = int32
  PDirectionType* = ptr TDirectionType
  TDirectionType* = int32
  PExpanderStyle* = ptr TExpanderStyle
  TExpanderStyle* = int32
  PPGtkIconSize* = ptr PIconSize
  PIconSize* = ptr TIconSize
  TIconSize* = int32
  PTextDirection* = ptr TTextDirection
  TTextDirection* = int32
  PJustification* = ptr TJustification
  TJustification* = int32
  PMenuDirectionType* = ptr TMenuDirectionType
  TMenuDirectionType* = int32
  PMetricType* = ptr TMetricType
  TMetricType* = int32
  PMovementStep* = ptr TMovementStep
  TMovementStep* = int32
  POrientation* = ptr TOrientation
  TOrientation* = int32
  PCornerType* = ptr TCornerType
  TCornerType* = int32
  PPackType* = ptr TPackType
  TPackType* = int32
  PPathPriorityType* = ptr TPathPriorityType
  TPathPriorityType* = int32
  PPathType* = ptr TPathType
  TPathType* = int32
  PPolicyType* = ptr TPolicyType
  TPolicyType* = int32
  PPositionType* = ptr TPositionType
  TPositionType* = int32
  PReliefStyle* = ptr TReliefStyle
  TReliefStyle* = int32
  PResizeMode* = ptr TResizeMode
  TResizeMode* = int32
  PScrollType* = ptr TScrollType
  TScrollType* = int32
  PSelectionMode* = ptr TSelectionMode
  TSelectionMode* = int32
  PShadowType* = ptr TShadowType
  TShadowType* = int32
  PStateType* = ptr TStateType
  TStateType* = int32
  PSubmenuDirection* = ptr TSubmenuDirection
  TSubmenuDirection* = int32
  PSubmenuPlacement* = ptr TSubmenuPlacement
  TSubmenuPlacement* = int32
  PToolbarStyle* = ptr TToolbarStyle
  TToolbarStyle* = int32
  PUpdateType* = ptr TUpdateType
  TUpdateType* = int32
  PVisibility* = ptr TVisibility
  TVisibility* = int32
  PWindowPosition* = ptr TWindowPosition
  TWindowPosition* = int32
  PWindowType* = ptr TWindowType
  TWindowType* = int32
  PWrapMode* = ptr TWrapMode
  TWrapMode* = int32
  PSortType* = ptr TSortType
  TSortType* = int32
  PStyle* = ptr TStyle
  PPGtkTreeModel* = ptr PTreeModel
  PTreeModel* = pointer
  PTreePath* = pointer
  PTreeIter* = ptr TTreeIter
  PSelectionData* = ptr TSelectionData
  PTextTagTable* = ptr TTextTagTable
  PTextBTreeNode* = pointer
  PTextBTree* = pointer
  PTextLine* = ptr TTextLine
  PTreeViewColumn* = ptr TTreeViewColumn
  PTreeView* = ptr TTreeView
  TTreeViewColumnDropFunc* = proc (tree_view: PTreeView,
                                   column: PTreeViewColumn,
                                   prev_column: PTreeViewColumn,
                                   next_column: PTreeViewColumn, data: gpointer): gboolean{.
      cdecl.}
  TTreeViewMappingFunc* = proc (tree_view: PTreeView, path: PTreePath,
                                user_data: gpointer){.cdecl.}
  TTreeViewSearchEqualFunc* = proc (model: PTreeModel, column: gint,
                                    key: cstring, iter: PTreeIter,
                                    search_data: gpointer): gboolean{.cdecl.}
  TTreeDestroyCountFunc* = proc (tree_view: PTreeView, path: PTreePath,
                                 children: gint, user_data: gpointer){.cdecl.}
  PTreeViewDropPosition* = ptr TTreeViewDropPosition
  TTreeViewDropPosition* = enum
    TREE_VIEW_DROP_BEFORE, TREE_VIEW_DROP_AFTER, TREE_VIEW_DROP_INTO_OR_BEFORE,
    TREE_VIEW_DROP_INTO_OR_AFTER
  PObjectFlags* = ptr TObjectFlags
  TObjectFlags* = int32
  TObject* = object of TGObject
    flags*: guint32

  PObjectClass* = ptr TObjectClass
  TObjectClass* = object of TGObjectClass
    set_arg*: proc (anObject: PObject, arg: PArg, arg_id: guint){.cdecl.}
    get_arg*: proc (anObject: PObject, arg: PArg, arg_id: guint){.cdecl.}
    destroy*: proc (anObject: PObject){.cdecl.}

  PFundamentalType* = ptr TFundamentalType
  TFundamentalType* = GType
  TFunction* = proc (data: gpointer): gboolean{.cdecl.}
  TDestroyNotify* = proc (data: gpointer){.cdecl.}
  TCallbackMarshal* = proc (anObject: PObject, data: gpointer, n_args: guint,
                            args: PArg){.cdecl.}
  TSignalFunc* = proc (para1: pointer){.cdecl.}
  PSignalMarshaller* = ptr TSignalMarshaller
  TSignalMarshaller* = TGSignalCMarshaller
  TArgSignalData*{.final, pure.} = object
    f*: TSignalFunc
    d*: gpointer

  TArg*{.final, pure.} = object
    `type`*: TType
    name*: cstring
    d*: gdouble               # was a union type

  PTypeInfo* = ptr TTypeInfo
  TTypeInfo*{.final, pure.} = object
    type_name*: cstring
    object_size*: guint
    class_size*: guint
    class_init_func*: pointer #TGtkClassInitFunc
    object_init_func*: pointer #TGtkObjectInitFunc
    reserved_1*: gpointer
    reserved_2*: gpointer
    base_class_init_func*: pointer #TGtkClassInitFunc

  PEnumValue* = ptr TEnumValue
  TEnumValue* = TGEnumValue
  PFlagValue* = ptr TFlagValue
  TFlagValue* = TGFlagsValue
  PWidgetFlags* = ptr TWidgetFlags
  TWidgetFlags* = int32
  PWidgetHelpType* = ptr TWidgetHelpType
  TWidgetHelpType* = enum
    WIDGET_HELP_TOOLTIP, WIDGET_HELP_WHATS_THIS
  PAllocation* = ptr TAllocation
  TAllocation* = Gdk2.TRectangle
  TCallback* = proc (widget: PWidget, data: gpointer){.cdecl.}
  PRequisition* = ptr TRequisition
  TRequisition*{.final, pure.} = object
    width*: gint
    height*: gint

  TWidget* = object of TObject
    private_flags*: guint16
    state*: guint8
    saved_state*: guint8
    name*: cstring
    style*: PStyle
    requisition*: TRequisition
    allocation*: TAllocation
    window*: Gdk2.PWindow
    parent*: PWidget

  PWidgetClass* = ptr TWidgetClass
  TWidgetClass* = object of TObjectClass
    activate_signal*: guint
    set_scroll_adjustments_signal*: guint
    dispatch_child_properties_changed*: proc (widget: PWidget, n_pspecs: guint,
        pspecs: PPGParamSpec){.cdecl.}
    show*: proc (widget: PWidget){.cdecl.}
    show_all*: proc (widget: PWidget){.cdecl.}
    hide*: proc (widget: PWidget){.cdecl.}
    hide_all*: proc (widget: PWidget){.cdecl.}
    map*: proc (widget: PWidget){.cdecl.}
    unmap*: proc (widget: PWidget){.cdecl.}
    realize*: proc (widget: PWidget){.cdecl.}
    unrealize*: proc (widget: PWidget){.cdecl.}
    size_request*: proc (widget: PWidget, requisition: PRequisition){.cdecl.}
    size_allocate*: proc (widget: PWidget, allocation: PAllocation){.cdecl.}
    state_changed*: proc (widget: PWidget, previous_state: TStateType){.cdecl.}
    parent_set*: proc (widget: PWidget, previous_parent: PWidget){.cdecl.}
    hierarchy_changed*: proc (widget: PWidget, previous_toplevel: PWidget){.
        cdecl.}
    style_set*: proc (widget: PWidget, previous_style: PStyle){.cdecl.}
    direction_changed*: proc (widget: PWidget,
                              previous_direction: TTextDirection){.cdecl.}
    grab_notify*: proc (widget: PWidget, was_grabbed: gboolean){.cdecl.}
    child_notify*: proc (widget: PWidget, pspec: PGParamSpec){.cdecl.}
    mnemonic_activate*: proc (widget: PWidget, group_cycling: gboolean): gboolean{.
        cdecl.}
    grab_focus*: proc (widget: PWidget){.cdecl.}
    focus*: proc (widget: PWidget, direction: TDirectionType): gboolean{.cdecl.}
    event*: proc (widget: PWidget, event: Gdk2.PEvent): gboolean{.cdecl.}
    button_press_event*: proc (widget: PWidget, event: PEventButton): gboolean{.
        cdecl.}
    button_release_event*: proc (widget: PWidget, event: PEventButton): gboolean{.
        cdecl.}
    scroll_event*: proc (widget: PWidget, event: PEventScroll): gboolean{.
        cdecl.}
    motion_notify_event*: proc (widget: PWidget, event: PEventMotion): gboolean{.
        cdecl.}
    delete_event*: proc (widget: PWidget, event: PEventAny): gboolean{.cdecl.}
    destroy_event*: proc (widget: PWidget, event: PEventAny): gboolean{.cdecl.}
    expose_event*: proc (widget: PWidget, event: PEventExpose): gboolean{.
        cdecl.}
    key_press_event*: proc (widget: PWidget, event: PEventKey): gboolean{.
        cdecl.}
    key_release_event*: proc (widget: PWidget, event: PEventKey): gboolean{.
        cdecl.}
    enter_notify_event*: proc (widget: PWidget, event: PEventCrossing): gboolean{.
        cdecl.}
    leave_notify_event*: proc (widget: PWidget, event: PEventCrossing): gboolean{.
        cdecl.}
    configure_event*: proc (widget: PWidget, event: PEventConfigure): gboolean{.
        cdecl.}
    focus_in_event*: proc (widget: PWidget, event: PEventFocus): gboolean{.
        cdecl.}
    focus_out_event*: proc (widget: PWidget, event: PEventFocus): gboolean{.
        cdecl.}
    map_event*: proc (widget: PWidget, event: PEventAny): gboolean{.cdecl.}
    unmap_event*: proc (widget: PWidget, event: PEventAny): gboolean{.cdecl.}
    property_notify_event*: proc (widget: PWidget, event: PEventProperty): gboolean{.
        cdecl.}
    selection_clear_event*: proc (widget: PWidget, event: PEventSelection): gboolean{.
        cdecl.}
    selection_request_event*: proc (widget: PWidget, event: PEventSelection): gboolean{.
        cdecl.}
    selection_notify_event*: proc (widget: PWidget, event: PEventSelection): gboolean{.
        cdecl.}
    proximity_in_event*: proc (widget: PWidget, event: PEventProximity): gboolean{.
        cdecl.}
    proximity_out_event*: proc (widget: PWidget, event: PEventProximity): gboolean{.
        cdecl.}
    visibility_notify_event*: proc (widget: PWidget, event: PEventVisibility): gboolean{.
        cdecl.}
    client_event*: proc (widget: PWidget, event: PEventClient): gboolean{.
        cdecl.}
    no_expose_event*: proc (widget: PWidget, event: PEventAny): gboolean{.
        cdecl.}
    window_state_event*: proc (widget: PWidget, event: PEventWindowState): gboolean{.
        cdecl.}
    selection_get*: proc (widget: PWidget, selection_data: PSelectionData,
                          info: guint, time: guint){.cdecl.}
    selection_received*: proc (widget: PWidget, selection_data: PSelectionData,
                               time: guint){.cdecl.}
    drag_begin*: proc (widget: PWidget, context: PDragContext){.cdecl.}
    drag_end*: proc (widget: PWidget, context: PDragContext){.cdecl.}
    drag_data_get*: proc (widget: PWidget, context: PDragContext,
                          selection_data: PSelectionData, info: guint,
                          time: guint){.cdecl.}
    drag_data_delete*: proc (widget: PWidget, context: PDragContext){.cdecl.}
    drag_leave*: proc (widget: PWidget, context: PDragContext, time: guint){.
        cdecl.}
    drag_motion*: proc (widget: PWidget, context: PDragContext, x: gint,
                        y: gint, time: guint): gboolean{.cdecl.}
    drag_drop*: proc (widget: PWidget, context: PDragContext, x: gint,
                      y: gint, time: guint): gboolean{.cdecl.}
    drag_data_received*: proc (widget: PWidget, context: PDragContext,
                               x: gint, y: gint, selection_data: PSelectionData,
                               info: guint, time: guint){.cdecl.}
    popup_menu*: proc (widget: PWidget): gboolean{.cdecl.}
    show_help*: proc (widget: PWidget, help_type: TWidgetHelpType): gboolean{.
        cdecl.}
    get_accessible*: proc (widget: PWidget): atk.PObject{.cdecl.}
    reserved1: proc (){.cdecl.}
    reserved2: proc (){.cdecl.}
    reserved3: proc (){.cdecl.}
    reserved4: proc (){.cdecl.}
    reserved5*: proc (){.cdecl.}
    reserved6*: proc (){.cdecl.}
    reserved7*: proc (){.cdecl.}
    reserved8*: proc (){.cdecl.}

  PWidgetAuxInfo* = ptr TWidgetAuxInfo
  TWidgetAuxInfo*{.final, pure.} = object
    x*: gint
    y*: gint
    width*: gint
    height*: gint
    flag0*: guint16

  PWidgetShapeInfo* = ptr TWidgetShapeInfo
  TWidgetShapeInfo*{.final, pure.} = object
    offset_x*: gint16
    offset_y*: gint16
    shape_mask*: gdk2.PBitmap

  TMisc* = object of TWidget
    xalign*: gfloat
    yalign*: gfloat
    xpad*: guint16
    ypad*: guint16

  PMiscClass* = ptr TMiscClass
  TMiscClass* = object of TWidgetClass
  PAccelFlags* = ptr TAccelFlags
  TAccelFlags* = int32
  PAccelGroup* = ptr TAccelGroup
  PAccelGroupEntry* = ptr TAccelGroupEntry
  TAccelGroupActivate* = proc (accel_group: PAccelGroup,
                               acceleratable: PGObject, keyval: guint,
                               modifier: gdk2.TModifierType): gboolean{.cdecl.}
  TAccelGroup* = object of TGObject
    lock_count*: guint
    modifier_mask*: gdk2.TModifierType
    acceleratables*: PGSList
    n_accels*: guint
    priv_accels*: PAccelGroupEntry

  PAccelGroupClass* = ptr TAccelGroupClass
  TAccelGroupClass* = object of TGObjectClass
    accel_changed*: proc (accel_group: PAccelGroup, keyval: guint,
                          modifier: gdk2.TModifierType, accel_closure: PGClosure){.
        cdecl.}
    reserved1: proc (){.cdecl.}
    reserved2: proc (){.cdecl.}
    reserved3: proc (){.cdecl.}
    reserved4: proc (){.cdecl.}

  PAccelKey* = ptr TAccelKey
  TAccelKey*{.final, pure.} = object
    accel_key*: guint
    accel_mods*: gdk2.TModifierType
    flag0*: guint16

  TAccelGroupEntry*{.final, pure.} = object
    key*: TAccelKey
    closure*: PGClosure
    accel_path_quark*: TGQuark

  Taccel_group_find_func* = proc (key: PAccelKey, closure: PGClosure,
                                  data: gpointer): gboolean{.cdecl.}
  PContainer* = ptr TContainer
  TContainer* = object of TWidget
    focus_child*: PWidget
    Container_flag0*: int32

  PContainerClass* = ptr TContainerClass
  TContainerClass* = object of TWidgetClass
    add*: proc (container: PContainer, widget: PWidget){.cdecl.}
    remove*: proc (container: PContainer, widget: PWidget){.cdecl.}
    check_resize*: proc (container: PContainer){.cdecl.}
    forall*: proc (container: PContainer, include_internals: gboolean,
                   callback: TCallback, callback_data: gpointer){.cdecl.}
    set_focus_child*: proc (container: PContainer, widget: PWidget){.cdecl.}
    child_type*: proc (container: PContainer): TType{.cdecl.}
    composite_name*: proc (container: PContainer, child: PWidget): cstring{.
        cdecl.}
    set_child_property*: proc (container: PContainer, child: PWidget,
                               property_id: guint, value: PGValue,
                               pspec: PGParamSpec){.cdecl.}
    get_child_property*: proc (container: PContainer, child: PWidget,
                               property_id: guint, value: PGValue,
                               pspec: PGParamSpec){.cdecl.}
    reserved20: proc (){.cdecl.}
    reserved21: proc (){.cdecl.}
    reserved23: proc (){.cdecl.}
    reserved24: proc (){.cdecl.}

  PBin* = ptr TBin
  TBin* = object of TContainer
    child*: PWidget

  PBinClass* = ptr TBinClass
  TBinClass* = object of TContainerClass
  PWindowGeometryInfo* = pointer
  PWindowGroup* = ptr TWindowGroup
  PWindow* = ptr TWindow
  TWindow* = object of TBin
    title*: cstring
    wmclass_name*: cstring
    wmclass_class*: cstring
    wm_role*: cstring
    focus_widget*: PWidget
    default_widget*: PWidget
    transient_parent*: PWindow
    geometry_info*: PWindowGeometryInfo
    frame*: gdk2.PWindow
    group*: PWindowGroup
    configure_request_count*: guint16
    window_flag0*: int32
    frame_left*: guint
    frame_top*: guint
    frame_right*: guint
    frame_bottom*: guint
    keys_changed_handler*: guint
    mnemonic_modifier*: gdk2.TModifierType
    screen*: gdk2.PScreen

  PWindowClass* = ptr TWindowClass
  TWindowClass* = object of TBinClass
    set_focus*: proc (window: PWindow, focus: PWidget){.cdecl.}
    frame_event*: proc (window: PWindow, event: gdk2.PEvent): gboolean{.cdecl.}
    activate_focus*: proc (window: PWindow){.cdecl.}
    activate_default*: proc (window: PWindow){.cdecl.}
    move_focus*: proc (window: PWindow, direction: TDirectionType){.cdecl.}
    keys_changed*: proc (window: PWindow){.cdecl.}
    reserved30: proc (){.cdecl.}
    reserved31: proc (){.cdecl.}
    reserved32: proc (){.cdecl.}
    reserved33: proc (){.cdecl.}

  TWindowGroup* = object of TGObject
    grabs*: PGSList

  PWindowGroupClass* = ptr TWindowGroupClass
  TWindowGroupClass* = object of TGObjectClass
    reserved40: proc (){.cdecl.}
    reserved41: proc (){.cdecl.}
    reserved42: proc (){.cdecl.}
    reserved43: proc (){.cdecl.}

  TWindowKeysForeachFunc* = proc (window: PWindow, keyval: guint,
                                  modifiers: gdk2.TModifierType,
                                  is_mnemonic: gboolean, data: gpointer){.cdecl.}
  PLabelSelectionInfo* = pointer
  TLabel* = object of TMisc
    `label`*: cstring
    Label_flag0*: guint16
    mnemonic_keyval*: guint
    text*: cstring
    attrs*: pango.PAttrList
    effective_attrs*: pango.PAttrList
    layout*: pango.PLayout
    mnemonic_widget*: PWidget
    mnemonic_window*: PWindow
    select_info*: PLabelSelectionInfo

  PLabelClass* = ptr TLabelClass
  TLabelClass* = object of TMiscClass
    move_cursor*: proc (`label`: PLabel, step: TMovementStep, count: gint,
                        extend_selection: gboolean){.cdecl.}
    copy_clipboard*: proc (`label`: PLabel){.cdecl.}
    populate_popup*: proc (`label`: PLabel, menu: PMenu){.cdecl.}
    reserved50: proc (){.cdecl.}
    reserved51: proc (){.cdecl.}
    reserved52: proc (){.cdecl.}
    reserved53: proc (){.cdecl.}

  PAccelLabel* = ptr TAccelLabel
  TAccelLabel* = object of TLabel
    queue_id*: guint
    accel_padding*: guint
    accel_widget*: PWidget
    accel_closure*: PGClosure
    accel_group*: PAccelGroup
    accel_string*: cstring
    accel_string_width*: guint16

  PAccelLabelClass* = ptr TAccelLabelClass
  TAccelLabelClass* = object of TLabelClass
    signal_quote1*: cstring
    signal_quote2*: cstring
    mod_name_shift*: cstring
    mod_name_control*: cstring
    mod_name_alt*: cstring
    mod_separator*: cstring
    accel_seperator*: cstring
    AccelLabelClass_flag0*: guint16
    reserved61: proc (){.cdecl.}
    reserved62: proc (){.cdecl.}
    reserved63: proc (){.cdecl.}
    reserved64: proc (){.cdecl.}

  TAccelMapForeach* = proc (data: gpointer, accel_path: cstring,
                            accel_key: guint, accel_mods: gdk2.TModifierType,
                            changed: gboolean){.cdecl.}
  PAccessible* = ptr TAccessible
  TAccessible* = object of atk.TObject
    widget*: PWidget

  PAccessibleClass* = ptr TAccessibleClass
  TAccessibleClass* = object of atk.TObjectClass
    connect_widget_destroyed*: proc (accessible: PAccessible){.cdecl.}
    reserved71: proc (){.cdecl.}
    reserved72: proc (){.cdecl.}
    reserved73: proc (){.cdecl.}
    reserved74: proc (){.cdecl.}

  PAdjustment* = ptr TAdjustment
  TAdjustment* = object of TObject
    lower*: gdouble
    upper*: gdouble
    value*: gdouble
    step_increment*: gdouble
    page_increment*: gdouble
    page_size*: gdouble

  PAdjustmentClass* = ptr TAdjustmentClass
  TAdjustmentClass* = object of TObjectClass
    changed*: proc (adjustment: PAdjustment){.cdecl.}
    value_changed*: proc (adjustment: PAdjustment){.cdecl.}
    reserved81: proc (){.cdecl.}
    reserved82: proc (){.cdecl.}
    reserved83: proc (){.cdecl.}
    reserved84: proc (){.cdecl.}

  PAlignment* = ptr TAlignment
  TAlignment* = object of TBin
    xalign*: gfloat
    yalign*: gfloat
    xscale*: gfloat
    yscale*: gfloat

  PAlignmentClass* = ptr TAlignmentClass
  TAlignmentClass* = object of TBinClass
  PFrame* = ptr TFrame
  TFrame* = object of TBin
    label_widget*: PWidget
    shadow_type*: gint16
    label_xalign*: gfloat
    label_yalign*: gfloat
    child_allocation*: TAllocation

  PFrameClass* = ptr TFrameClass
  TFrameClass* = object of TBinClass
    compute_child_allocation*: proc (frame: PFrame, allocation: PAllocation){.
        cdecl.}

  PAspectFrame* = ptr TAspectFrame
  TAspectFrame* = object of TFrame
    xalign*: gfloat
    yalign*: gfloat
    ratio*: gfloat
    obey_child*: gboolean
    center_allocation*: TAllocation

  PAspectFrameClass* = ptr TAspectFrameClass
  TAspectFrameClass* = object of TFrameClass
  PArrow* = ptr TArrow
  TArrow* = object of TMisc
    arrow_type*: gint16
    shadow_type*: gint16

  PArrowClass* = ptr TArrowClass
  TArrowClass* = object of TMiscClass
  PBindingEntry* = ptr TBindingEntry
  PBindingSignal* = ptr TBindingSignal
  PBindingArg* = ptr TBindingArg
  PBindingSet* = ptr TBindingSet
  TBindingSet*{.final, pure.} = object
    set_name*: cstring
    priority*: gint
    widget_path_pspecs*: PGSList
    widget_class_pspecs*: PGSList
    class_branch_pspecs*: PGSList
    entries*: PBindingEntry
    current*: PBindingEntry
    flag0*: guint16

  TBindingEntry*{.final, pure.} = object
    keyval*: guint
    modifiers*: gdk2.TModifierType
    binding_set*: PBindingSet
    flag0*: guint16
    set_next*: PBindingEntry
    hash_next*: PBindingEntry
    signals*: PBindingSignal

  TBindingSignal*{.final, pure.} = object
    next*: PBindingSignal
    signal_name*: cstring
    n_args*: guint
    args*: PBindingArg

  TBindingArg*{.final, pure.} = object
    arg_type*: TType
    d*: gdouble

  PBox* = ptr TBox
  TBox* = object of TContainer
    children*: PGList
    spacing*: gint16
    box_flag0*: guint16

  PBoxClass* = ptr TBoxClass
  TBoxClass* = object of TContainerClass
  PBoxChild* = ptr TBoxChild
  TBoxChild*{.final, pure.} = object
    widget*: PWidget
    padding*: guint16
    flag0*: guint16

  PButtonBox* = ptr TButtonBox
  TButtonBox* = object of TBox
    child_min_width*: gint
    child_min_height*: gint
    child_ipad_x*: gint
    child_ipad_y*: gint
    layout_style*: TButtonBoxStyle

  PButtonBoxClass* = ptr TButtonBoxClass
  TButtonBoxClass* = object of TBoxClass
  PButton* = ptr TButton
  TButton* = object of TBin
    event_window*: gdk2.PWindow
    label_text*: cstring
    activate_timeout*: guint
    button_flag0*: guint16

  PButtonClass* = ptr TButtonClass
  TButtonClass* = object of TBinClass
    pressed*: proc (button: PButton){.cdecl.}
    released*: proc (button: PButton){.cdecl.}
    clicked*: proc (button: PButton){.cdecl.}
    enter*: proc (button: PButton){.cdecl.}
    leave*: proc (button: PButton){.cdecl.}
    activate*: proc (button: PButton){.cdecl.}
    reserved101: proc (){.cdecl.}
    reserved102: proc (){.cdecl.}
    reserved103: proc (){.cdecl.}
    reserved104: proc (){.cdecl.}

  PCalendarDisplayOptions* = ptr TCalendarDisplayOptions
  TCalendarDisplayOptions* = int32
  PCalendar* = ptr TCalendar
  TCalendar* = object of TWidget
    header_style*: PStyle
    label_style*: PStyle
    month*: gint
    year*: gint
    selected_day*: gint
    day_month*: array[0..5, array[0..6, gint]]
    day*: array[0..5, array[0..6, gint]]
    num_marked_dates*: gint
    marked_date*: array[0..30, gint]
    display_flags*: TCalendarDisplayOptions
    marked_date_color*: array[0..30, gdk2.TColor]
    gc*: gdk2.PGC
    xor_gc*: gdk2.PGC
    focus_row*: gint
    focus_col*: gint
    highlight_row*: gint
    highlight_col*: gint
    private_data*: gpointer
    grow_space*: array[0..31, gchar]
    reserved111: proc (){.cdecl.}
    reserved112: proc (){.cdecl.}
    reserved113: proc (){.cdecl.}
    reserved114: proc (){.cdecl.}

  PCalendarClass* = ptr TCalendarClass
  TCalendarClass* = object of TWidgetClass
    month_changed*: proc (calendar: PCalendar){.cdecl.}
    day_selected*: proc (calendar: PCalendar){.cdecl.}
    day_selected_double_click*: proc (calendar: PCalendar){.cdecl.}
    prev_month*: proc (calendar: PCalendar){.cdecl.}
    next_month*: proc (calendar: PCalendar){.cdecl.}
    prev_year*: proc (calendar: PCalendar){.cdecl.}
    next_year*: proc (calendar: PCalendar){.cdecl.}

  PCellEditable* = pointer
  PCellEditableIface* = ptr TCellEditableIface
  TCellEditableIface* = object of TGTypeInterface
    editing_done*: proc (cell_editable: PCellEditable){.cdecl.}
    remove_widget*: proc (cell_editable: PCellEditable){.cdecl.}
    start_editing*: proc (cell_editable: PCellEditable, event: gdk2.PEvent){.cdecl.}

  PCellRendererState* = ptr TCellRendererState
  TCellRendererState* = int32
  PCellRendererMode* = ptr TCellRendererMode
  TCellRendererMode* = enum
    CELL_RENDERER_MODE_INERT, CELL_RENDERER_MODE_ACTIVATABLE,
    CELL_RENDERER_MODE_EDITABLE
  PCellRenderer* = ptr TCellRenderer
  TCellRenderer* = object of TObject
    xalign*: gfloat
    yalign*: gfloat
    width*: gint
    height*: gint
    xpad*: guint16
    ypad*: guint16
    CellRenderer_flag0*: guint16

  PCellRendererClass* = ptr TCellRendererClass
  TCellRendererClass* = object of TObjectClass
    get_size*: proc (cell: PCellRenderer, widget: PWidget,
                     cell_area: gdk2.PRectangle, x_offset: Pgint, y_offset: Pgint,
                     width: Pgint, height: Pgint){.cdecl.}
    render*: proc (cell: PCellRenderer, window: gdk2.PWindow, widget: PWidget,
                   background_area: gdk2.PRectangle, cell_area: gdk2.PRectangle,
                   expose_area: gdk2.PRectangle, flags: TCellRendererState){.cdecl.}
    activate*: proc (cell: PCellRenderer, event: gdk2.PEvent, widget: PWidget,
                     path: cstring, background_area: gdk2.PRectangle,
                     cell_area: gdk2.PRectangle, flags: TCellRendererState): gboolean{.
        cdecl.}
    start_editing*: proc (cell: PCellRenderer, event: gdk2.PEvent,
                          widget: PWidget, path: cstring,
                          background_area: gdk2.PRectangle,
                          cell_area: gdk2.PRectangle, flags: TCellRendererState): PCellEditable{.
        cdecl.}
    reserved121: proc (){.cdecl.}
    reserved122: proc (){.cdecl.}
    reserved123: proc (){.cdecl.}
    reserved124: proc (){.cdecl.}

  PCellRendererText* = ptr TCellRendererText
  TCellRendererText* = object of TCellRenderer
    text*: cstring
    font*: pango.PFontDescription
    font_scale*: gdouble
    foreground*: pango.TColor
    background*: pango.TColor
    extra_attrs*: pango.PAttrList
    underline_style*: pango.TUnderline
    rise*: gint
    fixed_height_rows*: gint
    CellRendererText_flag0*: guint16

  PCellRendererTextClass* = ptr TCellRendererTextClass
  TCellRendererTextClass* = object of TCellRendererClass
    edited*: proc (cell_renderer_text: PCellRendererText, path: cstring,
                   new_text: cstring){.cdecl.}
    reserved131: proc (){.cdecl.}
    reserved132: proc (){.cdecl.}
    reserved133: proc (){.cdecl.}
    reserved134: proc (){.cdecl.}

  PCellRendererToggle* = ptr TCellRendererToggle
  TCellRendererToggle* = object of TCellRenderer
    CellRendererToggle_flag0*: guint16

  PCellRendererToggleClass* = ptr TCellRendererToggleClass
  TCellRendererToggleClass* = object of TCellRendererClass
    toggled*: proc (cell_renderer_toggle: PCellRendererToggle, path: cstring){.
        cdecl.}
    reserved141: proc (){.cdecl.}
    reserved142: proc (){.cdecl.}
    reserved143: proc (){.cdecl.}
    reserved144: proc (){.cdecl.}

  PCellRendererPixbuf* = ptr TCellRendererPixbuf
  TCellRendererPixbuf* = object of TCellRenderer
    pixbuf*: gdk2pixbuf.PPixbuf
    pixbuf_expander_open*: gdk2pixbuf.PPixbuf
    pixbuf_expander_closed*: gdk2pixbuf.PPixbuf

  PCellRendererPixbufClass* = ptr TCellRendererPixbufClass
  TCellRendererPixbufClass* = object of TCellRendererClass
    reserved151: proc (){.cdecl.}
    reserved152: proc (){.cdecl.}
    reserved153: proc (){.cdecl.}
    reserved154: proc (){.cdecl.}

  PItem* = ptr TItem
  TItem* = object of TBin
  PItemClass* = ptr TItemClass
  TItemClass* = object of TBinClass
    select*: proc (item: PItem){.cdecl.}
    deselect*: proc (item: PItem){.cdecl.}
    toggle*: proc (item: PItem){.cdecl.}
    reserved161: proc (){.cdecl.}
    reserved162: proc (){.cdecl.}
    reserved163: proc (){.cdecl.}
    reserved164: proc (){.cdecl.}

  PMenuItem* = ptr TMenuItem
  TMenuItem* = object of TItem
    submenu*: PWidget
    event_window*: gdk2.PWindow
    toggle_size*: guint16
    accelerator_width*: guint16
    accel_path*: cstring
    MenuItem_flag0*: guint16
    timer*: guint

  PMenuItemClass* = ptr TMenuItemClass
  TMenuItemClass* = object of TItemClass
    MenuItemClass_flag0*: guint16
    activate*: proc (menu_item: PMenuItem){.cdecl.}
    activate_item*: proc (menu_item: PMenuItem){.cdecl.}
    toggle_size_request*: proc (menu_item: PMenuItem, requisition: Pgint){.cdecl.}
    toggle_size_allocate*: proc (menu_item: PMenuItem, allocation: gint){.cdecl.}
    reserved171: proc (){.cdecl.}
    reserved172: proc (){.cdecl.}
    reserved173: proc (){.cdecl.}
    reserved174: proc (){.cdecl.}

  PToggleButton* = ptr TToggleButton
  TToggleButton* = object of TButton
    ToggleButton_flag0*: guint16

  PToggleButtonClass* = ptr TToggleButtonClass
  TToggleButtonClass* = object of TButtonClass
    toggled*: proc (toggle_button: PToggleButton){.cdecl.}
    reserved171: proc (){.cdecl.}
    reserved172: proc (){.cdecl.}
    reserved173: proc (){.cdecl.}
    reserved174: proc (){.cdecl.}

  PCheckButton* = ptr TCheckButton
  TCheckButton* = object of TToggleButton
  PCheckButtonClass* = ptr TCheckButtonClass
  TCheckButtonClass* = object of TToggleButtonClass
    draw_indicator*: proc (check_button: PCheckButton, area: gdk2.PRectangle){.
        cdecl.}
    reserved181: proc (){.cdecl.}
    reserved182: proc (){.cdecl.}
    reserved183: proc (){.cdecl.}
    reserved184: proc (){.cdecl.}

  PCheckMenuItem* = ptr TCheckMenuItem
  TCheckMenuItem* = object of TMenuItem
    CheckMenuItem_flag0*: guint16

  PCheckMenuItemClass* = ptr TCheckMenuItemClass
  TCheckMenuItemClass* = object of TMenuItemClass
    toggled*: proc (check_menu_item: PCheckMenuItem){.cdecl.}
    draw_indicator*: proc (check_menu_item: PCheckMenuItem, area: gdk2.PRectangle){.
        cdecl.}
    reserved191: proc (){.cdecl.}
    reserved192: proc (){.cdecl.}
    reserved193: proc (){.cdecl.}
    reserved194: proc (){.cdecl.}

  PClipboard* = pointer
  TClipboardReceivedFunc* = proc (clipboard: PClipboard,
                                  selection_data: PSelectionData, data: gpointer){.
      cdecl.}
  TClipboardTextReceivedFunc* = proc (clipboard: PClipboard, text: cstring,
                                      data: gpointer){.cdecl.}
  TClipboardGetFunc* = proc (clipboard: PClipboard,
                             selection_data: PSelectionData, info: guint,
                             user_data_or_owner: gpointer){.cdecl.}
  TClipboardClearFunc* = proc (clipboard: PClipboard,
                               user_data_or_owner: gpointer){.cdecl.}
  PCList* = ptr TCList
  PCListColumn* = ptr TCListColumn
  PCListRow* = ptr TCListRow
  PCell* = ptr TCell
  PCellType* = ptr TCellType
  TCellType* = enum
    CELL_EMPTY, CELL_TEXT, CELL_PIXMAP, CELL_PIXTEXT, CELL_WIDGET
  PCListDragPos* = ptr TCListDragPos
  TCListDragPos* = enum
    CLIST_DRAG_NONE, CLIST_DRAG_BEFORE, CLIST_DRAG_INTO, CLIST_DRAG_AFTER
  PButtonAction* = ptr TButtonAction
  TButtonAction* = int32
  TCListCompareFunc* = proc (clist: PCList, ptr1: gconstpointer,
                             ptr2: gconstpointer): gint{.cdecl.}
  PCListCellInfo* = ptr TCListCellInfo
  TCListCellInfo*{.final, pure.} = object
    row*: gint
    column*: gint

  PCListDestInfo* = ptr TCListDestInfo
  TCListDestInfo*{.final, pure.} = object
    cell*: TCListCellInfo
    insert_pos*: TCListDragPos

  TCList* = object of TContainer
    CList_flags*: guint16
    row_mem_chunk*: PGMemChunk
    cell_mem_chunk*: PGMemChunk
    freeze_count*: guint
    internal_allocation*: gdk2.TRectangle
    rows*: gint
    row_height*: gint
    row_list*: PGList
    row_list_end*: PGList
    columns*: gint
    column_title_area*: gdk2.TRectangle
    title_window*: gdk2.PWindow
    column*: PCListColumn
    clist_window*: gdk2.PWindow
    clist_window_width*: gint
    clist_window_height*: gint
    hoffset*: gint
    voffset*: gint
    shadow_type*: TShadowType
    selection_mode*: TSelectionMode
    selection*: PGList
    selection_end*: PGList
    undo_selection*: PGList
    undo_unselection*: PGList
    undo_anchor*: gint
    button_actions*: array[0..4, guint8]
    drag_button*: guint8
    click_cell*: TCListCellInfo
    hadjustment*: PAdjustment
    vadjustment*: PAdjustment
    xor_gc*: gdk2.PGC
    fg_gc*: gdk2.PGC
    bg_gc*: gdk2.PGC
    cursor_drag*: gdk2.PCursor
    x_drag*: gint
    focus_row*: gint
    focus_header_column*: gint
    anchor*: gint
    anchor_state*: TStateType
    drag_pos*: gint
    htimer*: gint
    vtimer*: gint
    sort_type*: TSortType
    compare*: TCListCompareFunc
    sort_column*: gint
    drag_highlight_row*: gint
    drag_highlight_pos*: TCListDragPos

  PCListClass* = ptr TCListClass
  TCListClass* = object of TContainerClass
    set_scroll_adjustments*: proc (clist: PCList, hadjustment: PAdjustment,
                                   vadjustment: PAdjustment){.cdecl.}
    refresh*: proc (clist: PCList){.cdecl.}
    select_row*: proc (clist: PCList, row: gint, column: gint, event: gdk2.PEvent){.
        cdecl.}
    unselect_row*: proc (clist: PCList, row: gint, column: gint,
                         event: gdk2.PEvent){.cdecl.}
    row_move*: proc (clist: PCList, source_row: gint, dest_row: gint){.cdecl.}
    click_column*: proc (clist: PCList, column: gint){.cdecl.}
    resize_column*: proc (clist: PCList, column: gint, width: gint){.cdecl.}
    toggle_focus_row*: proc (clist: PCList){.cdecl.}
    select_all*: proc (clist: PCList){.cdecl.}
    unselect_all*: proc (clist: PCList){.cdecl.}
    undo_selection*: proc (clist: PCList){.cdecl.}
    start_selection*: proc (clist: PCList){.cdecl.}
    end_selection*: proc (clist: PCList){.cdecl.}
    extend_selection*: proc (clist: PCList, scroll_type: TScrollType,
                             position: gfloat, auto_start_selection: gboolean){.
        cdecl.}
    scroll_horizontal*: proc (clist: PCList, scroll_type: TScrollType,
                              position: gfloat){.cdecl.}
    scroll_vertical*: proc (clist: PCList, scroll_type: TScrollType,
                            position: gfloat){.cdecl.}
    toggle_add_mode*: proc (clist: PCList){.cdecl.}
    abort_column_resize*: proc (clist: PCList){.cdecl.}
    resync_selection*: proc (clist: PCList, event: gdk2.PEvent){.cdecl.}
    selection_find*: proc (clist: PCList, row_number: gint,
                           row_list_element: PGList): PGList{.cdecl.}
    draw_row*: proc (clist: PCList, area: gdk2.PRectangle, row: gint,
                     clist_row: PCListRow){.cdecl.}
    draw_drag_highlight*: proc (clist: PCList, target_row: PCListRow,
                                target_row_number: gint, drag_pos: TCListDragPos){.
        cdecl.}
    clear*: proc (clist: PCList){.cdecl.}
    fake_unselect_all*: proc (clist: PCList, row: gint){.cdecl.}
    sort_list*: proc (clist: PCList){.cdecl.}
    insert_row*: proc (clist: PCList, row: gint): gint{.cdecl, varargs.}
    remove_row*: proc (clist: PCList, row: gint){.cdecl.}
    set_cell_contents*: proc (clist: PCList, clist_row: PCListRow, column: gint,
                              thetype: TCellType, text: cstring,
                              spacing: guint8, pixmap: gdk2.PPixmap,
                              mask: gdk2.PBitmap){.cdecl.}
    cell_size_request*: proc (clist: PCList, clist_row: PCListRow, column: gint,
                              requisition: PRequisition){.cdecl.}

  PGPtrArray = pointer
  PGArray = pointer
  TCListColumn*{.final, pure.} = object
    title*: cstring
    area*: gdk2.TRectangle
    button*: PWidget
    window*: gdk2.PWindow
    width*: gint
    min_width*: gint
    max_width*: gint
    justification*: TJustification
    flag0*: guint16

  TCListRow*{.final, pure.} = object
    cell*: PCell
    state*: TStateType
    foreground*: gdk2.TColor
    background*: gdk2.TColor
    style*: PStyle
    data*: gpointer
    destroy*: TDestroyNotify
    flag0*: guint16

  PCellText* = ptr TCellText
  TCellText*{.final, pure.} = object
    `type`*: TCellType
    vertical*: gint16
    horizontal*: gint16
    style*: PStyle
    text*: cstring

  PCellPixmap* = ptr TCellPixmap
  TCellPixmap*{.final, pure.} = object
    `type`*: TCellType
    vertical*: gint16
    horizontal*: gint16
    style*: PStyle
    pixmap*: gdk2.PPixmap
    mask*: gdk2.PBitmap

  PCellPixText* = ptr TCellPixText
  TCellPixText*{.final, pure.} = object
    `type`*: TCellType
    vertical*: gint16
    horizontal*: gint16
    style*: PStyle
    text*: cstring
    spacing*: guint8
    pixmap*: gdk2.PPixmap
    mask*: gdk2.PBitmap

  PCellWidget* = ptr TCellWidget
  TCellWidget*{.final, pure.} = object
    `type`*: TCellType
    vertical*: gint16
    horizontal*: gint16
    style*: PStyle
    widget*: PWidget

  TCell*{.final, pure.} = object
    `type`*: TCellType
    vertical*: gint16
    horizontal*: gint16
    style*: PStyle
    text*: cstring
    spacing*: guint8
    pixmap*: gdk2.PPixmap
    mask*: gdk2.PBitmap

  PDialogFlags* = ptr TDialogFlags
  TDialogFlags* = int32
  PResponseType* = ptr TResponseType
  TResponseType* = int32
  PDialog* = ptr TDialog
  TDialog* = object of TWindow
    vbox*: PBox
    action_area*: PWidget
    separator*: PWidget

  PDialogClass* = ptr TDialogClass
  TDialogClass* = object of TWindowClass
    response*: proc (dialog: PDialog, response_id: gint){.cdecl.}
    closeFile*: proc (dialog: PDialog){.cdecl.}
    reserved201: proc (){.cdecl.}
    reserved202: proc (){.cdecl.}
    reserved203: proc (){.cdecl.}
    reserved204: proc (){.cdecl.}

  PVBox* = ptr TVBox
  TVBox* = object of TBox
  PVBoxClass* = ptr TVBoxClass
  TVBoxClass* = object of TBoxClass
  TColorSelectionChangePaletteFunc* = proc (colors: gdk2.PColor, n_colors: gint){.
      cdecl.}
  TColorSelectionChangePaletteWithScreenFunc* = proc (screen: gdk2.PScreen,
      colors: gdk2.PColor, n_colors: gint){.cdecl.}
  PColorSelection* = ptr TColorSelection
  TColorSelection* = object of TVBox
    private_data*: gpointer

  PColorSelectionClass* = ptr TColorSelectionClass
  TColorSelectionClass* = object of TVBoxClass
    color_changed*: proc (color_selection: PColorSelection){.cdecl.}
    reserved211: proc (){.cdecl.}
    reserved212: proc (){.cdecl.}
    reserved213: proc (){.cdecl.}
    reserved214: proc (){.cdecl.}

  PColorSelectionDialog* = ptr TColorSelectionDialog
  TColorSelectionDialog* = object of TDialog
    colorsel*: PWidget
    ok_button*: PWidget
    cancel_button*: PWidget
    help_button*: PWidget

  PColorSelectionDialogClass* = ptr TColorSelectionDialogClass
  TColorSelectionDialogClass* = object of TDialogClass
    reserved221: proc (){.cdecl.}
    reserved222: proc (){.cdecl.}
    reserved223: proc (){.cdecl.}
    reserved224: proc (){.cdecl.}

  PHBox* = ptr THBox
  THBox* = object of TBox
  PHBoxClass* = ptr THBoxClass
  THBoxClass* = object of TBoxClass
  PCombo* = ptr TCombo
  TCombo* = object of THBox
    entry*: PWidget
    button*: PWidget
    popup*: PWidget
    popwin*: PWidget
    list*: PWidget
    entry_change_id*: guint
    list_change_id*: guint
    Combo_flag0*: guint16
    current_button*: guint16
    activate_id*: guint

  PComboClass* = ptr TComboClass
  TComboClass* = object of THBoxClass
    reserved231: proc (){.cdecl.}
    reserved232: proc (){.cdecl.}
    reserved233: proc (){.cdecl.}
    reserved234: proc (){.cdecl.}

  PCTreePos* = ptr TCTreePos
  TCTreePos* = enum
    CTREE_POS_BEFORE, CTREE_POS_AS_CHILD, CTREE_POS_AFTER
  PCTreeLineStyle* = ptr TCTreeLineStyle
  TCTreeLineStyle* = enum
    CTREE_LINES_NONE, CTREE_LINES_SOLID, CTREE_LINES_DOTTED, CTREE_LINES_TABBED
  PCTreeExpanderStyle* = ptr TCTreeExpanderStyle
  TCTreeExpanderStyle* = enum
    CTREE_EXPANDER_NONE, CTREE_EXPANDER_SQUARE, CTREE_EXPANDER_TRIANGLE,
    CTREE_EXPANDER_CIRCULAR
  PCTreeExpansionType* = ptr TCTreeExpansionType
  TCTreeExpansionType* = enum
    CTREE_EXPANSION_EXPAND, CTREE_EXPANSION_EXPAND_RECURSIVE,
    CTREE_EXPANSION_COLLAPSE, CTREE_EXPANSION_COLLAPSE_RECURSIVE,
    CTREE_EXPANSION_TOGGLE, CTREE_EXPANSION_TOGGLE_RECURSIVE
  PCTree* = ptr TCTree
  PCTreeNode* = ptr TCTreeNode
  TCTreeFunc* = proc (ctree: PCTree, node: PCTreeNode, data: gpointer){.cdecl.}
  TCTreeGNodeFunc* = proc (ctree: PCTree, depth: guint, gnode: PGNode,
                           cnode: PCTreeNode, data: gpointer): gboolean{.cdecl.}
  TCTreeCompareDragFunc* = proc (ctree: PCTree, source_node: PCTreeNode,
                                 new_parent: PCTreeNode, new_sibling: PCTreeNode): gboolean{.
      cdecl.}
  TCTree* = object of TCList
    lines_gc*: gdk2.PGC
    tree_indent*: gint
    tree_spacing*: gint
    tree_column*: gint
    CTree_flag0*: guint16
    drag_compare*: TCTreeCompareDragFunc

  PCTreeClass* = ptr TCTreeClass
  TCTreeClass* = object of TCListClass
    tree_select_row*: proc (ctree: PCTree, row: PCTreeNode, column: gint){.cdecl.}
    tree_unselect_row*: proc (ctree: PCTree, row: PCTreeNode, column: gint){.
        cdecl.}
    tree_expand*: proc (ctree: PCTree, node: PCTreeNode){.cdecl.}
    tree_collapse*: proc (ctree: PCTree, node: PCTreeNode){.cdecl.}
    tree_move*: proc (ctree: PCTree, node: PCTreeNode, new_parent: PCTreeNode,
                      new_sibling: PCTreeNode){.cdecl.}
    change_focus_row_expansion*: proc (ctree: PCTree,
                                       action: TCTreeExpansionType){.cdecl.}

  PCTreeRow* = ptr TCTreeRow
  TCTreeRow*{.final, pure.} = object
    row*: TCListRow
    parent*: PCTreeNode
    sibling*: PCTreeNode
    children*: PCTreeNode
    pixmap_closed*: gdk2.PPixmap
    mask_closed*: gdk2.PBitmap
    pixmap_opened*: gdk2.PPixmap
    mask_opened*: gdk2.PBitmap
    level*: guint16
    CTreeRow_flag0*: guint16

  TCTreeNode*{.final, pure.} = object
    list*: TGList

  PDrawingArea* = ptr TDrawingArea
  TDrawingArea* = object of TWidget
    draw_data*: gpointer

  PDrawingAreaClass* = ptr TDrawingAreaClass
  TDrawingAreaClass* = object of TWidgetClass
    reserved241: proc (){.cdecl.}
    reserved242: proc (){.cdecl.}
    reserved243: proc (){.cdecl.}
    reserved244: proc (){.cdecl.}

  Tctlpoint* = array[0..1, gfloat]
  Pctlpoint* = ptr Tctlpoint
  PCurve* = ptr TCurve
  TCurve* = object of TDrawingArea
    cursor_type*: gint
    min_x*: gfloat
    max_x*: gfloat
    min_y*: gfloat
    max_y*: gfloat
    pixmap*: gdk2.PPixmap
    curve_type*: TCurveType
    height*: gint
    grab_point*: gint
    last*: gint
    num_points*: gint
    point*: gdk2.PPoint
    num_ctlpoints*: gint
    ctlpoint*: Pctlpoint

  PCurveClass* = ptr TCurveClass
  TCurveClass* = object of TDrawingAreaClass
    curve_type_changed*: proc (curve: PCurve){.cdecl.}
    reserved251: proc (){.cdecl.}
    reserved252: proc (){.cdecl.}
    reserved253: proc (){.cdecl.}
    reserved254: proc (){.cdecl.}

  PDestDefaults* = ptr TDestDefaults
  TDestDefaults* = int32
  PTargetFlags* = ptr TTargetFlags
  TTargetFlags* = int32
  PEditable* = pointer
  PEditableClass* = ptr TEditableClass
  TEditableClass* = object of TGTypeInterface
    insert_text*: proc (editable: PEditable, text: cstring, length: gint,
                        position: Pgint){.cdecl.}
    delete_text*: proc (editable: PEditable, start_pos: gint, end_pos: gint){.
        cdecl.}
    changed*: proc (editable: PEditable){.cdecl.}
    do_insert_text*: proc (editable: PEditable, text: cstring, length: gint,
                           position: Pgint){.cdecl.}
    do_delete_text*: proc (editable: PEditable, start_pos: gint, end_pos: gint){.
        cdecl.}
    get_chars*: proc (editable: PEditable, start_pos: gint, end_pos: gint): cstring{.
        cdecl.}
    set_selection_bounds*: proc (editable: PEditable, start_pos: gint,
                                 end_pos: gint){.cdecl.}
    get_selection_bounds*: proc (editable: PEditable, start_pos: Pgint,
                                 end_pos: Pgint): gboolean{.cdecl.}
    set_position*: proc (editable: PEditable, position: gint){.cdecl.}
    get_position*: proc (editable: PEditable): gint{.cdecl.}

  PIMContext* = ptr TIMContext
  TIMContext* = object of TGObject
  PIMContextClass* = ptr TIMContextClass
  TIMContextClass* = object of TObjectClass
    preedit_start*: proc (context: PIMContext){.cdecl.}
    preedit_end*: proc (context: PIMContext){.cdecl.}
    preedit_changed*: proc (context: PIMContext){.cdecl.}
    commit*: proc (context: PIMContext, str: cstring){.cdecl.}
    retrieve_surrounding*: proc (context: PIMContext): gboolean{.cdecl.}
    delete_surrounding*: proc (context: PIMContext, offset: gint, n_chars: gint): gboolean{.
        cdecl.}
    set_client_window*: proc (context: PIMContext, window: gdk2.PWindow){.cdecl.}
    get_preedit_string*: proc (context: PIMContext, str: PPgchar,
                               attrs: var pango.PAttrList, cursor_pos: Pgint){.
        cdecl.}
    filter_keypress*: proc (context: PIMContext, event: gdk2.PEventKey): gboolean{.
        cdecl.}
    focus_in*: proc (context: PIMContext){.cdecl.}
    focus_out*: proc (context: PIMContext){.cdecl.}
    reset*: proc (context: PIMContext){.cdecl.}
    set_cursor_location*: proc (context: PIMContext, area: gdk2.PRectangle){.cdecl.}
    set_use_preedit*: proc (context: PIMContext, use_preedit: gboolean){.cdecl.}
    set_surrounding*: proc (context: PIMContext, text: cstring, len: gint,
                            cursor_index: gint){.cdecl.}
    get_surrounding*: proc (context: PIMContext, text: PPgchar,
                            cursor_index: Pgint): gboolean{.cdecl.}
    reserved261: proc (){.cdecl.}
    reserved262: proc (){.cdecl.}
    reserved263: proc (){.cdecl.}
    reserved264: proc (){.cdecl.}
    reserved265: proc (){.cdecl.}
    reserved266: proc (){.cdecl.}

  PMenuShell* = ptr TMenuShell
  TMenuShell* = object of TContainer
    children*: PGList
    active_menu_item*: PWidget
    parent_menu_shell*: PWidget
    button*: guint
    activate_time*: guint32
    MenuShell_flag0*: guint16

  PMenuShellClass* = ptr TMenuShellClass
  TMenuShellClass* = object of TContainerClass
    MenuShellClass_flag0*: guint16
    deactivate*: proc (menu_shell: PMenuShell){.cdecl.}
    selection_done*: proc (menu_shell: PMenuShell){.cdecl.}
    move_current*: proc (menu_shell: PMenuShell, direction: TMenuDirectionType){.
        cdecl.}
    activate_current*: proc (menu_shell: PMenuShell, force_hide: gboolean){.
        cdecl.}
    cancel*: proc (menu_shell: PMenuShell){.cdecl.}
    select_item*: proc (menu_shell: PMenuShell, menu_item: PWidget){.cdecl.}
    insert*: proc (menu_shell: PMenuShell, child: PWidget, position: gint){.
        cdecl.}
    reserved271: proc (){.cdecl.}
    reserved272: proc (){.cdecl.}
    reserved273: proc (){.cdecl.}
    reserved274: proc (){.cdecl.}

  TMenuPositionFunc* = proc (menu: PMenu, x: Pgint, y: Pgint,
                             push_in: Pgboolean, user_data: gpointer){.cdecl.}
  TMenuDetachFunc* = proc (attach_widget: PWidget, menu: PMenu){.cdecl.}
  TMenu* = object of TMenuShell
    parent_menu_item*: PWidget
    old_active_menu_item*: PWidget
    accel_group*: PAccelGroup
    accel_path*: cstring
    position_func*: TMenuPositionFunc
    position_func_data*: gpointer
    toggle_size*: guint
    toplevel*: PWidget
    tearoff_window*: PWidget
    tearoff_hbox*: PWidget
    tearoff_scrollbar*: PWidget
    tearoff_adjustment*: PAdjustment
    view_window*: gdk2.PWindow
    bin_window*: gdk2.PWindow
    scroll_offset*: gint
    saved_scroll_offset*: gint
    scroll_step*: gint
    timeout_id*: guint
    navigation_region*: gdk2.PRegion
    navigation_timeout*: guint
    Menu_flag0*: guint16

  PMenuClass* = ptr TMenuClass
  TMenuClass* = object of TMenuShellClass
    reserved281: proc (){.cdecl.}
    reserved282: proc (){.cdecl.}
    reserved283: proc (){.cdecl.}
    reserved284: proc (){.cdecl.}

  PEntry* = ptr TEntry
  TEntry* = object of TWidget
    text*: cstring
    Entry_flag0*: guint16
    text_length*: guint16
    text_max_length*: guint16
    text_area*: gdk2.PWindow
    im_context*: PIMContext
    popup_menu*: PWidget
    current_pos*: gint
    selection_bound*: gint
    cached_layout*: pango.PLayout
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

  PEntryClass* = ptr TEntryClass
  TEntryClass* = object of TWidgetClass
    populate_popup*: proc (entry: PEntry, menu: PMenu){.cdecl.}
    activate*: proc (entry: PEntry){.cdecl.}
    move_cursor*: proc (entry: PEntry, step: TMovementStep, count: gint,
                        extend_selection: gboolean){.cdecl.}
    insert_at_cursor*: proc (entry: PEntry, str: cstring){.cdecl.}
    delete_from_cursor*: proc (entry: PEntry, thetype: TDeleteType, count: gint){.
        cdecl.}
    cut_clipboard*: proc (entry: PEntry){.cdecl.}
    copy_clipboard*: proc (entry: PEntry){.cdecl.}
    paste_clipboard*: proc (entry: PEntry){.cdecl.}
    toggle_overwrite*: proc (entry: PEntry){.cdecl.}
    reserved291: proc (){.cdecl.}
    reserved292: proc (){.cdecl.}
    reserved293: proc (){.cdecl.}
    reserved294: proc (){.cdecl.}

  PEventBox* = ptr TEventBox
  TEventBox* = object of TBin
  PEventBoxClass* = ptr TEventBoxClass
  TEventBoxClass* = object of TBinClass
  PFileSelection* = ptr TFileSelection
  TFileSelection* = object of TDialog
    dir_list*: PWidget
    file_list*: PWidget
    selection_entry*: PWidget
    selection_text*: PWidget
    main_vbox*: PWidget
    ok_button*: PWidget
    cancel_button*: PWidget
    help_button*: PWidget
    history_pulldown*: PWidget
    history_menu*: PWidget
    history_list*: PGList
    fileop_dialog*: PWidget
    fileop_entry*: PWidget
    fileop_file*: cstring
    cmpl_state*: gpointer
    fileop_c_dir*: PWidget
    fileop_del_file*: PWidget
    fileop_ren_file*: PWidget
    button_area*: PWidget
    FileSelection_action_area*: PWidget
    selected_names*: PGPtrArray
    last_selected*: cstring

  PFileSelectionClass* = ptr TFileSelectionClass
  TFileSelectionClass* = object of TDialogClass
    reserved301: proc (){.cdecl.}
    reserved302: proc (){.cdecl.}
    reserved303: proc (){.cdecl.}
    reserved304: proc (){.cdecl.}

  PFixed* = ptr TFixed
  TFixed* = object of TContainer
    children*: PGList

  PFixedClass* = ptr TFixedClass
  TFixedClass* = object of TContainerClass
  PFixedChild* = ptr TFixedChild
  TFixedChild*{.final, pure.} = object
    widget*: PWidget
    x*: gint
    y*: gint

  PFontSelection* = ptr TFontSelection
  TFontSelection* = object of TVBox
    font_entry*: PWidget
    family_list*: PWidget
    font_style_entry*: PWidget
    face_list*: PWidget
    size_entry*: PWidget
    size_list*: PWidget
    pixels_button*: PWidget
    points_button*: PWidget
    filter_button*: PWidget
    preview_entry*: PWidget
    family*: pango.PFontFamily
    face*: pango.PFontFace
    size*: gint
    font*: gdk2.PFont

  PFontSelectionClass* = ptr TFontSelectionClass
  TFontSelectionClass* = object of TVBoxClass
    reserved311: proc (){.cdecl.}
    reserved312: proc (){.cdecl.}
    reserved313: proc (){.cdecl.}
    reserved314: proc (){.cdecl.}

  PFontSelectionDialog* = ptr TFontSelectionDialog
  TFontSelectionDialog* = object of TDialog
    fontsel*: PWidget
    main_vbox*: PWidget
    FontSelectionDialog_action_area*: PWidget
    ok_button*: PWidget
    apply_button*: PWidget
    cancel_button*: PWidget
    dialog_width*: gint
    auto_resize*: gboolean

  PFontSelectionDialogClass* = ptr TFontSelectionDialogClass
  TFontSelectionDialogClass* = object of TDialogClass
    reserved321: proc (){.cdecl.}
    reserved322: proc (){.cdecl.}
    reserved323: proc (){.cdecl.}
    reserved324: proc (){.cdecl.}

  PGammaCurve* = ptr TGammaCurve
  TGammaCurve* = object of TVBox
    table*: PWidget
    curve*: PWidget
    button*: array[0..4, PWidget]
    gamma*: gfloat
    gamma_dialog*: PWidget
    gamma_text*: PWidget

  PGammaCurveClass* = ptr TGammaCurveClass
  TGammaCurveClass* = object of TVBoxClass
    reserved331: proc (){.cdecl.}
    reserved332: proc (){.cdecl.}
    reserved333: proc (){.cdecl.}
    reserved334: proc (){.cdecl.}

  PHandleBox* = ptr THandleBox
  THandleBox* = object of TBin
    bin_window*: gdk2.PWindow
    float_window*: gdk2.PWindow
    shadow_type*: TShadowType
    HandleBox_flag0*: guint16
    deskoff_x*: gint
    deskoff_y*: gint
    attach_allocation*: TAllocation
    float_allocation*: TAllocation

  PHandleBoxClass* = ptr THandleBoxClass
  THandleBoxClass* = object of TBinClass
    child_attached*: proc (handle_box: PHandleBox, child: PWidget){.cdecl.}
    child_detached*: proc (handle_box: PHandleBox, child: PWidget){.cdecl.}
    reserved341: proc (){.cdecl.}
    reserved342: proc (){.cdecl.}
    reserved343: proc (){.cdecl.}
    reserved344: proc (){.cdecl.}

  PPaned* = ptr TPaned
  TPaned* = object of TContainer
    child1*: PWidget
    child2*: PWidget
    handle*: gdk2.PWindow
    xor_gc*: gdk2.PGC
    cursor_type*: gdk2.TCursorType
    handle_pos*: gdk2.TRectangle
    child1_size*: gint
    last_allocation*: gint
    min_position*: gint
    max_position*: gint
    Paned_flag0*: guint16
    last_child1_focus*: PWidget
    last_child2_focus*: PWidget
    saved_focus*: PWidget
    drag_pos*: gint
    original_position*: gint

  PPanedClass* = ptr TPanedClass
  TPanedClass* = object of TContainerClass
    cycle_child_focus*: proc (paned: PPaned, reverse: gboolean): gboolean{.cdecl.}
    toggle_handle_focus*: proc (paned: PPaned): gboolean{.cdecl.}
    move_handle*: proc (paned: PPaned, scroll: TScrollType): gboolean{.cdecl.}
    cycle_handle_focus*: proc (paned: PPaned, reverse: gboolean): gboolean{.
        cdecl.}
    accept_position*: proc (paned: PPaned): gboolean{.cdecl.}
    cancel_position*: proc (paned: PPaned): gboolean{.cdecl.}
    reserved351: proc (){.cdecl.}
    reserved352: proc (){.cdecl.}
    reserved353: proc (){.cdecl.}
    reserved354: proc (){.cdecl.}

  PHButtonBox* = ptr THButtonBox
  THButtonBox* = object of TButtonBox
  PHButtonBoxClass* = ptr THButtonBoxClass
  THButtonBoxClass* = object of TButtonBoxClass
  PHPaned* = ptr THPaned
  THPaned* = object of TPaned
  PHPanedClass* = ptr THPanedClass
  THPanedClass* = object of TPanedClass
  PRulerMetric* = ptr TRulerMetric
  PRuler* = ptr TRuler
  TRuler* = object of TWidget
    backing_store*: gdk2.PPixmap
    non_gr_exp_gc*: gdk2.PGC
    metric*: PRulerMetric
    xsrc*: gint
    ysrc*: gint
    slider_size*: gint
    lower*: gdouble
    upper*: gdouble
    position*: gdouble
    max_size*: gdouble

  PRulerClass* = ptr TRulerClass
  TRulerClass* = object of TWidgetClass
    draw_ticks*: proc (ruler: PRuler){.cdecl.}
    draw_pos*: proc (ruler: PRuler){.cdecl.}
    reserved361: proc (){.cdecl.}
    reserved362: proc (){.cdecl.}
    reserved363: proc (){.cdecl.}
    reserved364: proc (){.cdecl.}

  TRulerMetric*{.final, pure.} = object
    metric_name*: cstring
    abbrev*: cstring
    pixels_per_unit*: gdouble
    ruler_scale*: array[0..9, gdouble]
    subdivide*: array[0..4, gint]

  PHRuler* = ptr THRuler
  THRuler* = object of TRuler
  PHRulerClass* = ptr THRulerClass
  THRulerClass* = object of TRulerClass
  PRcContext* = pointer
  PSettings* = ptr TSettings
  TSettings* = object of TGObject
    queued_settings*: PGData
    property_values*: PGValue
    rc_context*: PRcContext
    screen*: gdk2.PScreen

  PSettingsClass* = ptr TSettingsClass
  TSettingsClass* = object of TGObjectClass
  PSettingsValue* = ptr TSettingsValue
  TSettingsValue*{.final, pure.} = object
    origin*: cstring
    value*: TGValue

  PRcFlags* = ptr TRcFlags
  TRcFlags* = int32
  PRcStyle* = ptr TRcStyle
  TRcStyle* = object of TGObject
    name*: cstring
    bg_pixmap_name*: array[0..4, cstring]
    font_desc*: pango.PFontDescription
    color_flags*: array[0..4, TRcFlags]
    fg*: array[0..4, gdk2.TColor]
    bg*: array[0..4, gdk2.TColor]
    text*: array[0..4, gdk2.TColor]
    base*: array[0..4, gdk2.TColor]
    xthickness*: gint
    ythickness*: gint
    rc_properties*: PGArray
    rc_style_lists*: PGSList
    icon_factories*: PGSList
    RcStyle_flag0*: guint16

  PRcStyleClass* = ptr TRcStyleClass
  TRcStyleClass* = object of TGObjectClass
    create_rc_style*: proc (rc_style: PRcStyle): PRcStyle{.cdecl.}
    parse*: proc (rc_style: PRcStyle, settings: PSettings, scanner: PGScanner): guint{.
        cdecl.}
    merge*: proc (dest: PRcStyle, src: PRcStyle){.cdecl.}
    create_style*: proc (rc_style: PRcStyle): PStyle{.cdecl.}
    reserved371: proc (){.cdecl.}
    reserved372: proc (){.cdecl.}
    reserved373: proc (){.cdecl.}
    reserved374: proc (){.cdecl.}

  PRcTokenType* = ptr TRcTokenType
  TRcTokenType* = enum
    RC_TOKEN_INVALID, RC_TOKEN_INCLUDE, RC_TOKEN_NORMAL, RC_TOKEN_ACTIVE,
    RC_TOKEN_PRELIGHT, RC_TOKEN_SELECTED, RC_TOKEN_INSENSITIVE, RC_TOKEN_FG,
    RC_TOKEN_BG, RC_TOKEN_TEXT, RC_TOKEN_BASE, RC_TOKEN_XTHICKNESS,
    RC_TOKEN_YTHICKNESS, RC_TOKEN_FONT, RC_TOKEN_FONTSET, RC_TOKEN_FONT_NAME,
    RC_TOKEN_BG_PIXMAP, RC_TOKEN_PIXMAP_PATH, RC_TOKEN_STYLE, RC_TOKEN_BINDING,
    RC_TOKEN_BIND, RC_TOKEN_WIDGET, RC_TOKEN_WIDGET_CLASS, RC_TOKEN_CLASS,
    RC_TOKEN_LOWEST, RC_TOKEN_GTK, RC_TOKEN_APPLICATION, RC_TOKEN_THEME,
    RC_TOKEN_RC, RC_TOKEN_HIGHEST, RC_TOKEN_ENGINE, RC_TOKEN_MODULE_PATH,
    RC_TOKEN_IM_MODULE_PATH, RC_TOKEN_IM_MODULE_FILE, RC_TOKEN_STOCK,
    RC_TOKEN_LTR, RC_TOKEN_RTL, RC_TOKEN_LAST
  PRcProperty* = ptr TRcProperty
  TRcProperty*{.final, pure.} = object
    type_name*: TGQuark
    property_name*: TGQuark
    origin*: cstring
    value*: TGValue

  PIconSource* = pointer
  TRcPropertyParser* = proc (pspec: PGParamSpec, rc_string: PGString,
                             property_value: PGValue): gboolean{.cdecl.}
  TStyle* = object of TGObject
    fg*: array[0..4, gdk2.TColor]
    bg*: array[0..4, gdk2.TColor]
    light*: array[0..4, gdk2.TColor]
    dark*: array[0..4, gdk2.TColor]
    mid*: array[0..4, gdk2.TColor]
    text*: array[0..4, gdk2.TColor]
    base*: array[0..4, gdk2.TColor]
    text_aa*: array[0..4, gdk2.TColor]
    black*: gdk2.TColor
    white*: gdk2.TColor
    font_desc*: pango.PFontDescription
    xthickness*: gint
    ythickness*: gint
    fg_gc*: array[0..4, gdk2.PGC]
    bg_gc*: array[0..4, gdk2.PGC]
    light_gc*: array[0..4, gdk2.PGC]
    dark_gc*: array[0..4, gdk2.PGC]
    mid_gc*: array[0..4, gdk2.PGC]
    text_gc*: array[0..4, gdk2.PGC]
    base_gc*: array[0..4, gdk2.PGC]
    text_aa_gc*: array[0..4, gdk2.PGC]
    black_gc*: gdk2.PGC
    white_gc*: gdk2.PGC
    bg_pixmap*: array[0..4, gdk2.PPixmap]
    attach_count*: gint
    depth*: gint
    colormap*: gdk2.PColormap
    private_font*: gdk2.PFont
    private_font_desc*: pango.PFontDescription
    rc_style*: PRcStyle
    styles*: PGSList
    property_cache*: PGArray
    icon_factories*: PGSList

  PStyleClass* = ptr TStyleClass
  TStyleClass* = object of TGObjectClass
    realize*: proc (style: PStyle){.cdecl.}
    unrealize*: proc (style: PStyle){.cdecl.}
    copy*: proc (style: PStyle, src: PStyle){.cdecl.}
    clone*: proc (style: PStyle): PStyle{.cdecl.}
    init_from_rc*: proc (style: PStyle, rc_style: PRcStyle){.cdecl.}
    set_background*: proc (style: PStyle, window: gdk2.PWindow,
                           state_type: TStateType){.cdecl.}
    render_icon*: proc (style: PStyle, source: PIconSource,
                        direction: TTextDirection, state: TStateType,
                        size: TIconSize, widget: PWidget, detail: cstring): gdk2pixbuf.PPixbuf{.
        cdecl.}
    draw_hline*: proc (style: PStyle, window: gdk2.PWindow,
                       state_type: TStateType, area: gdk2.PRectangle,
                       widget: PWidget, detail: cstring, x1: gint, x2: gint,
                       y: gint){.cdecl.}
    draw_vline*: proc (style: PStyle, window: gdk2.PWindow,
                       state_type: TStateType, area: gdk2.PRectangle,
                       widget: PWidget, detail: cstring, y1: gint, y2: gint,
                       x: gint){.cdecl.}
    draw_shadow*: proc (style: PStyle, window: gdk2.PWindow,
                        state_type: TStateType, shadow_type: TShadowType,
                        area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                        x: gint, y: gint, width: gint, height: gint){.cdecl.}
    draw_polygon*: proc (style: PStyle, window: gdk2.PWindow,
                         state_type: TStateType, shadow_type: TShadowType,
                         area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                         point: gdk2.PPoint, npoints: gint, fill: gboolean){.cdecl.}
    draw_arrow*: proc (style: PStyle, window: gdk2.PWindow,
                       state_type: TStateType, shadow_type: TShadowType,
                       area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                       arrow_type: TArrowType, fill: gboolean, x: gint, y: gint,
                       width: gint, height: gint){.cdecl.}
    draw_diamond*: proc (style: PStyle, window: gdk2.PWindow,
                         state_type: TStateType, shadow_type: TShadowType,
                         area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                         x: gint, y: gint, width: gint, height: gint){.cdecl.}
    draw_string*: proc (style: PStyle, window: gdk2.PWindow,
                        state_type: TStateType, area: gdk2.PRectangle,
                        widget: PWidget, detail: cstring, x: gint, y: gint,
                        `string`: cstring){.cdecl.}
    draw_box*: proc (style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                     shadow_type: TShadowType, area: gdk2.PRectangle,
                     widget: PWidget, detail: cstring, x: gint, y: gint,
                     width: gint, height: gint){.cdecl.}
    draw_flat_box*: proc (style: PStyle, window: gdk2.PWindow,
                          state_type: TStateType, shadow_type: TShadowType,
                          area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                          x: gint, y: gint, width: gint, height: gint){.cdecl.}
    draw_check*: proc (style: PStyle, window: gdk2.PWindow,
                       state_type: TStateType, shadow_type: TShadowType,
                       area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                       x: gint, y: gint, width: gint, height: gint){.cdecl.}
    draw_option*: proc (style: PStyle, window: gdk2.PWindow,
                        state_type: TStateType, shadow_type: TShadowType,
                        area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                        x: gint, y: gint, width: gint, height: gint){.cdecl.}
    draw_tab*: proc (style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                     shadow_type: TShadowType, area: gdk2.PRectangle,
                     widget: PWidget, detail: cstring, x: gint, y: gint,
                     width: gint, height: gint){.cdecl.}
    draw_shadow_gap*: proc (style: PStyle, window: gdk2.PWindow,
                            state_type: TStateType, shadow_type: TShadowType,
                            area: gdk2.PRectangle, widget: PWidget,
                            detail: cstring, x: gint, y: gint, width: gint,
                            height: gint, gap_side: TPositionType, gap_x: gint,
                            gap_width: gint){.cdecl.}
    draw_box_gap*: proc (style: PStyle, window: gdk2.PWindow,
                         state_type: TStateType, shadow_type: TShadowType,
                         area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                         x: gint, y: gint, width: gint, height: gint,
                         gap_side: TPositionType, gap_x: gint, gap_width: gint){.
        cdecl.}
    draw_extension*: proc (style: PStyle, window: gdk2.PWindow,
                           state_type: TStateType, shadow_type: TShadowType,
                           area: gdk2.PRectangle, widget: PWidget,
                           detail: cstring, x: gint, y: gint, width: gint,
                           height: gint, gap_side: TPositionType){.cdecl.}
    draw_focus*: proc (style: PStyle, window: gdk2.PWindow,
                       state_type: TStateType, area: gdk2.PRectangle,
                       widget: PWidget, detail: cstring, x: gint, y: gint,
                       width: gint, height: gint){.cdecl.}
    draw_slider*: proc (style: PStyle, window: gdk2.PWindow,
                        state_type: TStateType, shadow_type: TShadowType,
                        area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                        x: gint, y: gint, width: gint, height: gint,
                        orientation: TOrientation){.cdecl.}
    draw_handle*: proc (style: PStyle, window: gdk2.PWindow,
                        state_type: TStateType, shadow_type: TShadowType,
                        area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                        x: gint, y: gint, width: gint, height: gint,
                        orientation: TOrientation){.cdecl.}
    draw_expander*: proc (style: PStyle, window: gdk2.PWindow,
                          state_type: TStateType, area: gdk2.PRectangle,
                          widget: PWidget, detail: cstring, x: gint, y: gint,
                          expander_style: TExpanderStyle){.cdecl.}
    draw_layout*: proc (style: PStyle, window: gdk2.PWindow,
                        state_type: TStateType, use_text: gboolean,
                        area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                        x: gint, y: gint, layout: pango.PLayout){.cdecl.}
    draw_resize_grip*: proc (style: PStyle, window: gdk2.PWindow,
                             state_type: TStateType, area: gdk2.PRectangle,
                             widget: PWidget, detail: cstring,
                             edge: gdk2.TWindowEdge, x: gint, y: gint,
                             width: gint, height: gint){.cdecl.}
    reserved381: proc (){.cdecl.}
    reserved382: proc (){.cdecl.}
    reserved383: proc (){.cdecl.}
    reserved384: proc (){.cdecl.}
    reserved385: proc (){.cdecl.}
    reserved386: proc (){.cdecl.}
    reserved387: proc (){.cdecl.}
    reserved388: proc (){.cdecl.}
    reserved389: proc (){.cdecl.}
    reserved3810: proc (){.cdecl.}
    reserved3811: proc (){.cdecl.}
    reserved3812: proc (){.cdecl.}

  PBorder* = ptr TBorder
  TBorder*{.final, pure.} = object
    left*: gint
    right*: gint
    top*: gint
    bottom*: gint

  PRangeLayout* = pointer
  PRangeStepTimer* = pointer
  PRange* = ptr TRange
  TRange* = object of TWidget
    adjustment*: PAdjustment
    update_policy*: TUpdateType
    Range_flag0*: guint16
    min_slider_size*: gint
    orientation*: TOrientation
    range_rect*: gdk2.TRectangle
    slider_start*: gint
    slider_end*: gint
    round_digits*: gint
    flag1*: guint16
    layout*: PRangeLayout
    timer*: PRangeStepTimer
    slide_initial_slider_position*: gint
    slide_initial_coordinate*: gint
    update_timeout_id*: guint
    event_window*: gdk2.PWindow

  PRangeClass* = ptr TRangeClass
  TRangeClass* = object of TWidgetClass
    slider_detail*: cstring
    stepper_detail*: cstring
    value_changed*: proc (range: PRange){.cdecl.}
    adjust_bounds*: proc (range: PRange, new_value: gdouble){.cdecl.}
    move_slider*: proc (range: PRange, scroll: TScrollType){.cdecl.}
    get_range_border*: proc (range: PRange, border: PBorder){.cdecl.}
    reserved401: proc (){.cdecl.}
    reserved402: proc (){.cdecl.}
    reserved403: proc (){.cdecl.}
    reserved404: proc (){.cdecl.}

  PScale* = ptr TScale
  TScale* = object of TRange
    digits*: gint
    Scale_flag0*: guint16

  PScaleClass* = ptr TScaleClass
  TScaleClass* = object of TRangeClass
    format_value*: proc (scale: PScale, value: gdouble): cstring{.cdecl.}
    draw_value*: proc (scale: PScale){.cdecl.}
    reserved411: proc (){.cdecl.}
    reserved412: proc (){.cdecl.}
    reserved413: proc (){.cdecl.}
    reserved414: proc (){.cdecl.}

  PHScale* = ptr THScale
  THScale* = object of TScale
  PHScaleClass* = ptr THScaleClass
  THScaleClass* = object of TScaleClass
  PScrollbar* = ptr TScrollbar
  TScrollbar* = object of TRange
  PScrollbarClass* = ptr TScrollbarClass
  TScrollbarClass* = object of TRangeClass
    reserved421: proc (){.cdecl.}
    reserved422: proc (){.cdecl.}
    reserved423: proc (){.cdecl.}
    reserved424: proc (){.cdecl.}

  PHScrollbar* = ptr THScrollbar
  THScrollbar* = object of TScrollbar
  PHScrollbarClass* = ptr THScrollbarClass
  THScrollbarClass* = object of TScrollbarClass
  PSeparator* = ptr TSeparator
  TSeparator* = object of TWidget
  PSeparatorClass* = ptr TSeparatorClass
  TSeparatorClass* = object of TWidgetClass
  PHSeparator* = ptr THSeparator
  THSeparator* = object of TSeparator
  PHSeparatorClass* = ptr THSeparatorClass
  THSeparatorClass* = object of TSeparatorClass
  PIconFactory* = ptr TIconFactory
  TIconFactory* = object of TGObject
    icons*: PGHashTable

  PIconFactoryClass* = ptr TIconFactoryClass
  TIconFactoryClass* = object of TGObjectClass
    reserved431: proc (){.cdecl.}
    reserved432: proc (){.cdecl.}
    reserved433: proc (){.cdecl.}
    reserved434: proc (){.cdecl.}

  PIconSet* = pointer
  PImagePixmapData* = ptr TImagePixmapData
  TImagePixmapData*{.final, pure.} = object
    pixmap*: gdk2.PPixmap

  PImageImageData* = ptr TImageImageData
  TImageImageData*{.final, pure.} = object
    image*: gdk2.PImage

  PImagePixbufData* = ptr TImagePixbufData
  TImagePixbufData*{.final, pure.} = object
    pixbuf*: gdk2pixbuf.PPixbuf

  PImageStockData* = ptr TImageStockData
  TImageStockData*{.final, pure.} = object
    stock_id*: cstring

  PImageIconSetData* = ptr TImageIconSetData
  TImageIconSetData*{.final, pure.} = object
    icon_set*: PIconSet

  PImageAnimationData* = ptr TImageAnimationData
  TImageAnimationData*{.final, pure.} = object
    anim*: gdk2pixbuf.PPixbufAnimation
    iter*: gdk2pixbuf.PPixbufAnimationIter
    frame_timeout*: guint

  PImageType* = ptr TImageType
  TImageType* = enum
    IMAGE_EMPTY, IMAGE_PIXMAP, IMAGE_IMAGE, IMAGE_PIXBUF, IMAGE_STOCK,
    IMAGE_ICON_SET, IMAGE_ANIMATION
  PImage* = ptr TImage
  TImage* = object of TMisc
    storage_type*: TImageType
    pixmap*: TImagePixmapData
    mask*: gdk2.PBitmap
    icon_size*: TIconSize

  PImageClass* = ptr TImageClass
  TImageClass* = object of TMiscClass
    reserved441: proc (){.cdecl.}
    reserved442: proc (){.cdecl.}
    reserved443: proc (){.cdecl.}
    reserved444: proc (){.cdecl.}

  PImageMenuItem* = ptr TImageMenuItem
  TImageMenuItem* = object of TMenuItem
    image*: PWidget

  PImageMenuItemClass* = ptr TImageMenuItemClass
  TImageMenuItemClass* = object of TMenuItemClass
  PIMContextSimple* = ptr TIMContextSimple
  TIMContextSimple* = object of TIMContext
    tables*: PGSList
    compose_buffer*: array[0..(MAX_COMPOSE_LEN + 1) - 1, guint]
    tentative_match*: gunichar
    tentative_match_len*: gint
    IMContextSimple_flag0*: guint16

  PIMContextSimpleClass* = ptr TIMContextSimpleClass
  TIMContextSimpleClass* = object of TIMContextClass
  PIMMulticontext* = ptr TIMMulticontext
  TIMMulticontext* = object of TIMContext
    slave*: PIMContext
    client_window*: gdk2.PWindow
    context_id*: cstring

  PIMMulticontextClass* = ptr TIMMulticontextClass
  TIMMulticontextClass* = object of TIMContextClass
    reserved451: proc (){.cdecl.}
    reserved452: proc (){.cdecl.}
    reserved453: proc (){.cdecl.}
    reserved454: proc (){.cdecl.}

  PInputDialog* = ptr TInputDialog
  TInputDialog* = object of TDialog
    axis_list*: PWidget
    axis_listbox*: PWidget
    mode_optionmenu*: PWidget
    close_button*: PWidget
    save_button*: PWidget
    axis_items*: array[0..(gdk2.AXIS_LAST) - 1, PWidget]
    current_device*: gdk2.PDevice
    keys_list*: PWidget
    keys_listbox*: PWidget

  PInputDialogClass* = ptr TInputDialogClass
  TInputDialogClass* = object of TDialogClass
    enable_device*: proc (inputd: PInputDialog, device: gdk2.PDevice){.cdecl.}
    disable_device*: proc (inputd: PInputDialog, device: gdk2.PDevice){.cdecl.}
    reserved461: proc (){.cdecl.}
    reserved462: proc (){.cdecl.}
    reserved463: proc (){.cdecl.}
    reserved464: proc (){.cdecl.}

  PInvisible* = ptr TInvisible
  TInvisible* = object of TWidget
    has_user_ref_count*: gboolean
    screen*: gdk2.PScreen

  PInvisibleClass* = ptr TInvisibleClass
  TInvisibleClass* = object of TWidgetClass
    reserved701: proc (){.cdecl.}
    reserved702: proc (){.cdecl.}
    reserved703: proc (){.cdecl.}
    reserved704: proc (){.cdecl.}

  TPrintFunc* = proc (func_data: gpointer, str: cstring){.cdecl.}
  PTranslateFunc* = ptr TTranslateFunc
  TTranslateFunc* = gchar
  TItemFactoryCallback* = proc (){.cdecl.}
  TItemFactoryCallback1* = proc (callback_data: gpointer,
                                 callback_action: guint, widget: PWidget){.cdecl.}
  PItemFactory* = ptr TItemFactory
  TItemFactory* = object of TObject
    path*: cstring
    accel_group*: PAccelGroup
    widget*: PWidget
    items*: PGSList
    translate_func*: TTranslateFunc
    translate_data*: gpointer
    translate_notify*: TDestroyNotify

  PItemFactoryClass* = ptr TItemFactoryClass
  TItemFactoryClass* = object of TObjectClass
    item_ht*: PGHashTable
    reserved471: proc (){.cdecl.}
    reserved472: proc (){.cdecl.}
    reserved473: proc (){.cdecl.}
    reserved474: proc (){.cdecl.}

  PItemFactoryEntry* = ptr TItemFactoryEntry
  TItemFactoryEntry*{.final, pure.} = object
    path*: cstring
    accelerator*: cstring
    callback*: TItemFactoryCallback
    callback_action*: guint
    item_type*: cstring
    extra_data*: gconstpointer

  PItemFactoryItem* = ptr TItemFactoryItem
  TItemFactoryItem*{.final, pure.} = object
    path*: cstring
    widgets*: PGSList

  PLayout* = ptr TLayout
  TLayout* = object of TContainer
    children*: PGList
    width*: guint
    height*: guint
    hadjustment*: PAdjustment
    vadjustment*: PAdjustment
    bin_window*: gdk2.PWindow
    visibility*: gdk2.TVisibilityState
    scroll_x*: gint
    scroll_y*: gint
    freeze_count*: guint

  PLayoutClass* = ptr TLayoutClass
  TLayoutClass* = object of TContainerClass
    set_scroll_adjustments*: proc (layout: PLayout, hadjustment: PAdjustment,
                                   vadjustment: PAdjustment){.cdecl.}
    reserved481: proc (){.cdecl.}
    reserved482: proc (){.cdecl.}
    reserved483: proc (){.cdecl.}
    reserved484: proc (){.cdecl.}

  PList* = ptr TList
  TList* = object of TContainer
    children*: PGList
    selection*: PGList
    undo_selection*: PGList
    undo_unselection*: PGList
    last_focus_child*: PWidget
    undo_focus_child*: PWidget
    htimer*: guint
    vtimer*: guint
    anchor*: gint
    drag_pos*: gint
    anchor_state*: TStateType
    List_flag0*: guint16

  PListClass* = ptr TListClass
  TListClass* = object of TContainerClass
    selection_changed*: proc (list: PList){.cdecl.}
    select_child*: proc (list: PList, child: PWidget){.cdecl.}
    unselect_child*: proc (list: PList, child: PWidget){.cdecl.}

  TTreeModelForeachFunc* = proc (model: PTreeModel, path: PTreePath,
                                 iter: PTreeIter, data: gpointer): gboolean{.
      cdecl.}
  PTreeModelFlags* = ptr TTreeModelFlags
  TTreeModelFlags* = int32
  TTreeIter*{.final, pure.} = object
    stamp*: gint
    user_data*: gpointer
    user_data2*: gpointer
    user_data3*: gpointer

  PTreeModelIface* = ptr TTreeModelIface
  TTreeModelIface* = object of TGTypeInterface
    row_changed*: proc (tree_model: PTreeModel, path: PTreePath, iter: PTreeIter){.
        cdecl.}
    row_inserted*: proc (tree_model: PTreeModel, path: PTreePath,
                         iter: PTreeIter){.cdecl.}
    row_has_child_toggled*: proc (tree_model: PTreeModel, path: PTreePath,
                                  iter: PTreeIter){.cdecl.}
    row_deleted*: proc (tree_model: PTreeModel, path: PTreePath){.cdecl.}
    rows_reordered*: proc (tree_model: PTreeModel, path: PTreePath,
                           iter: PTreeIter, new_order: Pgint){.cdecl.}
    get_flags*: proc (tree_model: PTreeModel): TTreeModelFlags{.cdecl.}
    get_n_columns*: proc (tree_model: PTreeModel): gint{.cdecl.}
    get_column_type*: proc (tree_model: PTreeModel, index: gint): GType{.cdecl.}
    get_iter*: proc (tree_model: PTreeModel, iter: PTreeIter, path: PTreePath): gboolean{.
        cdecl.}
    get_path*: proc (tree_model: PTreeModel, iter: PTreeIter): PTreePath{.cdecl.}
    get_value*: proc (tree_model: PTreeModel, iter: PTreeIter, column: gint,
                      value: PGValue){.cdecl.}
    iter_next*: proc (tree_model: PTreeModel, iter: PTreeIter): gboolean{.cdecl.}
    iter_children*: proc (tree_model: PTreeModel, iter: PTreeIter,
                          parent: PTreeIter): gboolean{.cdecl.}
    iter_has_child*: proc (tree_model: PTreeModel, iter: PTreeIter): gboolean{.
        cdecl.}
    iter_n_children*: proc (tree_model: PTreeModel, iter: PTreeIter): gint{.
        cdecl.}
    iter_nth_child*: proc (tree_model: PTreeModel, iter: PTreeIter,
                           parent: PTreeIter, n: gint): gboolean{.cdecl.}
    iter_parent*: proc (tree_model: PTreeModel, iter: PTreeIter,
                        child: PTreeIter): gboolean{.cdecl.}
    ref_node*: proc (tree_model: PTreeModel, iter: PTreeIter){.cdecl.}
    unref_node*: proc (tree_model: PTreeModel, iter: PTreeIter){.cdecl.}

  PTreeSortable* = pointer
  TTreeIterCompareFunc* = proc (model: PTreeModel, a: PTreeIter, b: PTreeIter,
                                user_data: gpointer): gint{.cdecl.}
  PTreeSortableIface* = ptr TTreeSortableIface
  TTreeSortableIface* = object of TGTypeInterface
    sort_column_changed*: proc (sortable: PTreeSortable){.cdecl.}
    get_sort_column_id*: proc (sortable: PTreeSortable, sort_column_id: Pgint,
                               order: PSortType): gboolean{.cdecl.}
    set_sort_column_id*: proc (sortable: PTreeSortable, sort_column_id: gint,
                               order: TSortType){.cdecl.}
    set_sort_func*: proc (sortable: PTreeSortable, sort_column_id: gint,
                          func: TTreeIterCompareFunc, data: gpointer,
                          destroy: TDestroyNotify){.cdecl.}
    set_default_sort_func*: proc (sortable: PTreeSortable,
                                  func: TTreeIterCompareFunc, data: gpointer,
                                  destroy: TDestroyNotify){.cdecl.}
    has_default_sort_func*: proc (sortable: PTreeSortable): gboolean{.cdecl.}

  PTreeModelSort* = ptr TTreeModelSort
  TTreeModelSort* = object of TGObject
    root*: gpointer
    stamp*: gint
    child_flags*: guint
    child_model*: PTreeModel
    zero_ref_count*: gint
    sort_list*: PGList
    sort_column_id*: gint
    order*: TSortType
    default_sort_func*: TTreeIterCompareFunc
    default_sort_data*: gpointer
    default_sort_destroy*: TDestroyNotify
    changed_id*: guint
    inserted_id*: guint
    has_child_toggled_id*: guint
    deleted_id*: guint
    reordered_id*: guint

  PTreeModelSortClass* = ptr TTreeModelSortClass
  TTreeModelSortClass* = object of TGObjectClass
    reserved491: proc (){.cdecl.}
    reserved492: proc (){.cdecl.}
    reserved493: proc (){.cdecl.}
    reserved494: proc (){.cdecl.}

  PListStore* = ptr TListStore
  TListStore* = object of TGObject
    stamp*: gint
    root*: gpointer
    tail*: gpointer
    sort_list*: PGList
    n_columns*: gint
    sort_column_id*: gint
    order*: TSortType
    column_headers*: PGType
    length*: gint
    default_sort_func*: TTreeIterCompareFunc
    default_sort_data*: gpointer
    default_sort_destroy*: TDestroyNotify
    ListStore_flag0*: guint16

  PListStoreClass* = ptr TListStoreClass
  TListStoreClass* = object of TGObjectClass
    reserved501: proc (){.cdecl.}
    reserved502: proc (){.cdecl.}
    reserved503: proc (){.cdecl.}
    reserved504: proc (){.cdecl.}

  TModuleInitFunc* = proc (argc: Pgint, argv: PPPgchar){.cdecl.}
  TKeySnoopFunc* = proc (grab_widget: PWidget, event: gdk2.PEventKey,
                         func_data: gpointer): gint{.cdecl.}
  PMenuBar* = ptr TMenuBar
  TMenuBar* = object of TMenuShell
  PMenuBarClass* = ptr TMenuBarClass
  TMenuBarClass* = object of TMenuShellClass
    reserved511: proc (){.cdecl.}
    reserved512: proc (){.cdecl.}
    reserved513: proc (){.cdecl.}
    reserved514: proc (){.cdecl.}

  PMessageType* = ptr TMessageType
  TMessageType* = enum
    MESSAGE_INFO, MESSAGE_WARNING, MESSAGE_QUESTION, MESSAGE_ERROR
  PButtonsType* = ptr TButtonsType
  TButtonsType* = enum
    BUTTONS_NONE, BUTTONS_OK, BUTTONS_CLOSE, BUTTONS_CANCEL, BUTTONS_YES_NO,
    BUTTONS_OK_CANCEL
  PMessageDialog* = ptr TMessageDialog
  TMessageDialog* = object of TDialog
    image*: PWidget
    label*: PWidget

  PMessageDialogClass* = ptr TMessageDialogClass
  TMessageDialogClass* = object of TDialogClass
    reserved521: proc (){.cdecl.}
    reserved522: proc (){.cdecl.}
    reserved523: proc (){.cdecl.}
    reserved524: proc (){.cdecl.}

  PNotebookPage* = pointer
  PNotebookTab* = ptr TNotebookTab
  TNotebookTab* = enum
    NOTEBOOK_TAB_FIRST, NOTEBOOK_TAB_LAST
  PNotebook* = ptr TNotebook
  TNotebook* = object of TContainer
    cur_page*: PNotebookPage
    children*: PGList
    first_tab*: PGList
    focus_tab*: PGList
    menu*: PWidget
    event_window*: gdk2.PWindow
    timer*: guint32
    tab_hborder*: guint16
    tab_vborder*: guint16
    Notebook_flag0*: guint16

  PNotebookClass* = ptr TNotebookClass
  TNotebookClass* = object of TContainerClass
    switch_page*: proc (notebook: PNotebook, page: PNotebookPage,
                        page_num: guint){.cdecl.}
    select_page*: proc (notebook: PNotebook, move_focus: gboolean): gboolean{.
        cdecl.}
    focus_tab*: proc (notebook: PNotebook, thetype: TNotebookTab): gboolean{.
        cdecl.}
    change_current_page*: proc (notebook: PNotebook, offset: gint){.cdecl.}
    move_focus_out*: proc (notebook: PNotebook, direction: TDirectionType){.
        cdecl.}
    reserved531: proc (){.cdecl.}
    reserved532: proc (){.cdecl.}
    reserved533: proc (){.cdecl.}
    reserved534: proc (){.cdecl.}

  POldEditable* = ptr TOldEditable
  TOldEditable* = object of TWidget
    current_pos*: guint
    selection_start_pos*: guint
    selection_end_pos*: guint
    OldEditable_flag0*: guint16
    clipboard_text*: cstring

  TTextFunction* = proc (editable: POldEditable, time: guint32){.cdecl.}
  POldEditableClass* = ptr TOldEditableClass
  TOldEditableClass* = object of TWidgetClass
    activate*: proc (editable: POldEditable){.cdecl.}
    set_editable*: proc (editable: POldEditable, is_editable: gboolean){.cdecl.}
    move_cursor*: proc (editable: POldEditable, x: gint, y: gint){.cdecl.}
    move_word*: proc (editable: POldEditable, n: gint){.cdecl.}
    move_page*: proc (editable: POldEditable, x: gint, y: gint){.cdecl.}
    move_to_row*: proc (editable: POldEditable, row: gint){.cdecl.}
    move_to_column*: proc (editable: POldEditable, row: gint){.cdecl.}
    kill_char*: proc (editable: POldEditable, direction: gint){.cdecl.}
    kill_word*: proc (editable: POldEditable, direction: gint){.cdecl.}
    kill_line*: proc (editable: POldEditable, direction: gint){.cdecl.}
    cut_clipboard*: proc (editable: POldEditable){.cdecl.}
    copy_clipboard*: proc (editable: POldEditable){.cdecl.}
    paste_clipboard*: proc (editable: POldEditable){.cdecl.}
    update_text*: proc (editable: POldEditable, start_pos: gint, end_pos: gint){.
        cdecl.}
    get_chars*: proc (editable: POldEditable, start_pos: gint, end_pos: gint): cstring{.
        cdecl.}
    set_selection*: proc (editable: POldEditable, start_pos: gint, end_pos: gint){.
        cdecl.}
    set_position*: proc (editable: POldEditable, position: gint){.cdecl.}

  POptionMenu* = ptr TOptionMenu
  TOptionMenu* = object of TButton
    menu*: PWidget
    menu_item*: PWidget
    width*: guint16
    height*: guint16

  POptionMenuClass* = ptr TOptionMenuClass
  TOptionMenuClass* = object of TButtonClass
    changed*: proc (option_menu: POptionMenu){.cdecl.}
    reserved541: proc (){.cdecl.}
    reserved542: proc (){.cdecl.}
    reserved543: proc (){.cdecl.}
    reserved544: proc (){.cdecl.}

  PPixmap* = ptr TPixmap
  TPixmap* = object of TMisc
    pixmap*: gdk2.PPixmap
    mask*: gdk2.PBitmap
    pixmap_insensitive*: gdk2.PPixmap
    Pixmap_flag0*: guint16

  PPixmapClass* = ptr TPixmapClass
  TPixmapClass* = object of TMiscClass
  PPlug* = ptr TPlug
  TPlug* = object of TWindow
    socket_window*: gdk2.PWindow
    modality_window*: PWidget
    modality_group*: PWindowGroup
    grabbed_keys*: PGHashTable
    Plug_flag0*: guint16

  PPlugClass* = ptr TPlugClass
  TPlugClass* = object of TWindowClass
    embedded*: proc (plug: PPlug){.cdecl.}
    reserved551: proc (){.cdecl.}
    reserved552: proc (){.cdecl.}
    reserved553: proc (){.cdecl.}
    reserved554: proc (){.cdecl.}

  PPreview* = ptr TPreview
  TPreview* = object of TWidget
    buffer*: Pguchar
    buffer_width*: guint16
    buffer_height*: guint16
    bpp*: guint16
    rowstride*: guint16
    dither*: gdk2.TRgbDither
    Preview_flag0*: guint16

  PPreviewInfo* = ptr TPreviewInfo
  TPreviewInfo*{.final, pure.} = object
    lookup*: Pguchar
    gamma*: gdouble

  PDitherInfo* = ptr TDitherInfo
  TDitherInfo*{.final, pure.} = object
    c*: array[0..3, guchar]

  PPreviewClass* = ptr TPreviewClass
  TPreviewClass* = object of TWidgetClass
    info*: TPreviewInfo

  PProgress* = ptr TProgress
  TProgress* = object of TWidget
    adjustment*: PAdjustment
    offscreen_pixmap*: gdk2.PPixmap
    format*: cstring
    x_align*: gfloat
    y_align*: gfloat
    Progress_flag0*: guint16

  PProgressClass* = ptr TProgressClass
  TProgressClass* = object of TWidgetClass
    paint*: proc (progress: PProgress){.cdecl.}
    update*: proc (progress: PProgress){.cdecl.}
    act_mode_enter*: proc (progress: PProgress){.cdecl.}
    reserved561: proc (){.cdecl.}
    reserved562: proc (){.cdecl.}
    reserved563: proc (){.cdecl.}
    reserved564: proc (){.cdecl.}

  PProgressBarStyle* = ptr TProgressBarStyle
  TProgressBarStyle* = enum
    PROGRESS_CONTINUOUS, PROGRESS_DISCRETE
  PProgressBarOrientation* = ptr TProgressBarOrientation
  TProgressBarOrientation* = enum
    PROGRESS_LEFT_TO_RIGHT, PROGRESS_RIGHT_TO_LEFT, PROGRESS_BOTTOM_TO_TOP,
    PROGRESS_TOP_TO_BOTTOM
  PProgressBar* = ptr TProgressBar
  TProgressBar* = object of TProgress
    bar_style*: TProgressBarStyle
    orientation*: TProgressBarOrientation
    blocks*: guint
    in_block*: gint
    activity_pos*: gint
    activity_step*: guint
    activity_blocks*: guint
    pulse_fraction*: gdouble
    ProgressBar_flag0*: guint16

  PProgressBarClass* = ptr TProgressBarClass
  TProgressBarClass* = object of TProgressClass
    reserved571: proc (){.cdecl.}
    reserved572: proc (){.cdecl.}
    reserved573: proc (){.cdecl.}
    reserved574: proc (){.cdecl.}

  PRadioButton* = ptr TRadioButton
  TRadioButton* = object of TCheckButton
    group*: PGSList

  PRadioButtonClass* = ptr TRadioButtonClass
  TRadioButtonClass* = object of TCheckButtonClass
    reserved581: proc (){.cdecl.}
    reserved582: proc (){.cdecl.}
    reserved583: proc (){.cdecl.}
    reserved584: proc (){.cdecl.}

  PRadioMenuItem* = ptr TRadioMenuItem
  TRadioMenuItem* = object of TCheckMenuItem
    group*: PGSList

  PRadioMenuItemClass* = ptr TRadioMenuItemClass
  TRadioMenuItemClass* = object of TCheckMenuItemClass
    reserved591: proc (){.cdecl.}
    reserved592: proc (){.cdecl.}
    reserved593: proc (){.cdecl.}
    reserved594: proc (){.cdecl.}

  PScrolledWindow* = ptr TScrolledWindow
  TScrolledWindow* = object of TBin
    hscrollbar*: PWidget
    vscrollbar*: PWidget
    ScrolledWindow_flag0*: guint16
    shadow_type*: guint16

  PScrolledWindowClass* = ptr TScrolledWindowClass
  TScrolledWindowClass* = object of TBinClass
    scrollbar_spacing*: gint
    scroll_child*: proc (scrolled_window: PScrolledWindow, scroll: TScrollType,
                         horizontal: gboolean){.cdecl.}
    move_focus_out*: proc (scrolled_window: PScrolledWindow,
                           direction: TDirectionType){.cdecl.}
    reserved601: proc (){.cdecl.}
    reserved602: proc (){.cdecl.}
    reserved603: proc (){.cdecl.}
    reserved604: proc (){.cdecl.}

  TSelectionData*{.final, pure.} = object
    selection*: gdk2.TAtom
    target*: gdk2.TAtom
    thetype*: gdk2.TAtom
    format*: gint
    data*: Pguchar
    length*: gint
    display*: gdk2.PDisplay

  PTargetEntry* = ptr TTargetEntry
  TTargetEntry*{.final, pure.} = object
    target*: cstring
    flags*: guint
    info*: guint

  PTargetList* = ptr TTargetList
  TTargetList*{.final, pure.} = object
    list*: PGList
    ref_count*: guint

  PTargetPair* = ptr TTargetPair
  TTargetPair*{.final, pure.} = object
    target*: gdk2.TAtom
    flags*: guint
    info*: guint

  PSeparatorMenuItem* = ptr TSeparatorMenuItem
  TSeparatorMenuItem* = object of TMenuItem
  PSeparatorMenuItemClass* = ptr TSeparatorMenuItemClass
  TSeparatorMenuItemClass* = object of TMenuItemClass
  PSizeGroup* = ptr TSizeGroup
  TSizeGroup* = object of TGObject
    widgets*: PGSList
    mode*: guint8
    SizeGroup_flag0*: guint16
    requisition*: TRequisition

  PSizeGroupClass* = ptr TSizeGroupClass
  TSizeGroupClass* = object of TGObjectClass
    reserved611: proc (){.cdecl.}
    reserved612: proc (){.cdecl.}
    reserved613: proc (){.cdecl.}
    reserved614: proc (){.cdecl.}

  PSizeGroupMode* = ptr TSizeGroupMode
  TSizeGroupMode* = enum
    SIZE_GROUP_NONE, SIZE_GROUP_HORIZONTAL, SIZE_GROUP_VERTICAL, SIZE_GROUP_BOTH
  PSocket* = ptr TSocket
  TSocket* = object of TContainer
    request_width*: guint16
    request_height*: guint16
    current_width*: guint16
    current_height*: guint16
    plug_window*: gdk2.PWindow
    plug_widget*: PWidget
    xembed_version*: gshort
    Socket_flag0*: guint16
    accel_group*: PAccelGroup
    toplevel*: PWidget

  PSocketClass* = ptr TSocketClass
  TSocketClass* = object of TContainerClass
    plug_added*: proc (socket: PSocket){.cdecl.}
    plug_removed*: proc (socket: PSocket): gboolean{.cdecl.}
    reserved621: proc (){.cdecl.}
    reserved622: proc (){.cdecl.}
    reserved623: proc (){.cdecl.}
    reserved624: proc (){.cdecl.}

  PSpinButtonUpdatePolicy* = ptr TSpinButtonUpdatePolicy
  TSpinButtonUpdatePolicy* = enum
    UPDATE_ALWAYS, UPDATE_IF_VALID
  PSpinType* = ptr TSpinType
  TSpinType* = enum
    SPIN_STEP_FORWARD, SPIN_STEP_BACKWARD, SPIN_PAGE_FORWARD,
    SPIN_PAGE_BACKWARD, SPIN_HOME, SPIN_END, SPIN_USER_DEFINED
  PSpinButton* = ptr TSpinButton
  TSpinButton* = object of TEntry
    adjustment*: PAdjustment
    panel*: gdk2.PWindow
    timer*: guint32
    climb_rate*: gdouble
    timer_step*: gdouble
    update_policy*: TSpinButtonUpdatePolicy
    SpinButton_flag0*: int32

  PSpinButtonClass* = ptr TSpinButtonClass
  TSpinButtonClass* = object of TEntryClass
    input*: proc (spin_button: PSpinButton, new_value: Pgdouble): gint{.cdecl.}
    output*: proc (spin_button: PSpinButton): gint{.cdecl.}
    value_changed*: proc (spin_button: PSpinButton){.cdecl.}
    change_value*: proc (spin_button: PSpinButton, scroll: TScrollType){.cdecl.}
    reserved631: proc (){.cdecl.}
    reserved632: proc (){.cdecl.}
    reserved633: proc (){.cdecl.}
    reserved634: proc (){.cdecl.}

  PStockItem* = ptr TStockItem
  TStockItem*{.final, pure.} = object
    stock_id*: cstring
    label*: cstring
    modifier*: gdk2.TModifierType
    keyval*: guint
    translation_domain*: cstring

  PStatusbar* = ptr TStatusbar
  TStatusbar* = object of THBox
    frame*: PWidget
    `label`*: PWidget
    messages*: PGSList
    keys*: PGSList
    seq_context_id*: guint
    seq_message_id*: guint
    grip_window*: gdk2.PWindow
    Statusbar_flag0*: guint16

  PStatusbarClass* = ptr TStatusbarClass
  TStatusbarClass* = object of THBoxClass
    messages_mem_chunk*: PGMemChunk
    text_pushed*: proc (statusbar: PStatusbar, context_id: guint, text: cstring){.
        cdecl.}
    text_popped*: proc (statusbar: PStatusbar, context_id: guint, text: cstring){.
        cdecl.}
    reserved641: proc (){.cdecl.}
    reserved642: proc (){.cdecl.}
    reserved643: proc (){.cdecl.}
    reserved644: proc (){.cdecl.}

  PTableRowCol* = ptr TTableRowCol
  PTable* = ptr TTable
  TTable* = object of TContainer
    children*: PGList
    rows*: PTableRowCol
    cols*: PTableRowCol
    nrows*: guint16
    ncols*: guint16
    column_spacing*: guint16
    row_spacing*: guint16
    Table_flag0*: guint16

  PTableClass* = ptr TTableClass
  TTableClass* = object of TContainerClass
  PTableChild* = ptr TTableChild
  TTableChild*{.final, pure.} = object
    widget*: PWidget
    left_attach*: guint16
    right_attach*: guint16
    top_attach*: guint16
    bottom_attach*: guint16
    xpadding*: guint16
    ypadding*: guint16
    TableChild_flag0*: guint16

  TTableRowCol*{.final, pure.} = object
    requisition*: guint16
    allocation*: guint16
    spacing*: guint16
    flag0*: guint16

  PTearoffMenuItem* = ptr TTearoffMenuItem
  TTearoffMenuItem* = object of TMenuItem
    TearoffMenuItem_flag0*: guint16

  PTearoffMenuItemClass* = ptr TTearoffMenuItemClass
  TTearoffMenuItemClass* = object of TMenuItemClass
    reserved651: proc (){.cdecl.}
    reserved652: proc (){.cdecl.}
    reserved653: proc (){.cdecl.}
    reserved654: proc (){.cdecl.}

  PTextFont* = pointer
  PPropertyMark* = ptr TPropertyMark
  TPropertyMark*{.final, pure.} = object
    `property`*: PGList
    offset*: guint
    index*: guint

  PText* = ptr TText
  TText* = object of TOldEditable
    text_area*: gdk2.PWindow
    hadj*: PAdjustment
    vadj*: PAdjustment
    gc*: gdk2.PGC
    line_wrap_bitmap*: gdk2.PPixmap
    line_arrow_bitmap*: gdk2.PPixmap
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
    Text_flag0*: guint16
    freeze_count*: guint
    text_properties*: PGList
    text_properties_end*: PGList
    point*: TPropertyMark
    scratch_buffer*: Pguchar
    scratch_buffer_len*: guint
    last_ver_value*: gint
    cursor_pos_x*: gint
    cursor_pos_y*: gint
    cursor_mark*: TPropertyMark
    cursor_char*: gdk2.TWChar
    cursor_char_offset*: gchar
    cursor_virtual_x*: gint
    cursor_drawn_level*: gint
    current_line*: PGList
    tab_stops*: PGList
    default_tab_width*: gint
    current_font*: PTextFont
    timer*: gint
    button*: guint
    bg_gc*: gdk2.PGC

  PTextClass* = ptr TTextClass
  TTextClass* = object of TOldEditableClass
    set_scroll_adjustments*: proc (text: PText, hadjustment: PAdjustment,
                                   vadjustment: PAdjustment){.cdecl.}

  PTextSearchFlags* = ptr TTextSearchFlags
  TTextSearchFlags* = int32
  PTextIter* = ptr TTextIter
  TTextIter*{.final, pure.} = object
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

  TTextCharPredicate* = proc (ch: gunichar, user_data: gpointer): gboolean{.
      cdecl.}
  PTextTagClass* = ptr TTextTagClass
  PTextAttributes* = ptr TTextAttributes
  PTextTag* = ptr TTextTag
  PPGtkTextTag* = ptr PTextTag
  TTextTag* = object of TGObject
    table*: PTextTagTable
    name*: cstring
    priority*: int32
    values*: PTextAttributes
    TextTag_flag0*: int32

  TTextTagClass* = object of TGObjectClass
    event*: proc (tag: PTextTag, event_object: PGObject, event: gdk2.PEvent,
                  iter: PTextIter): gboolean{.cdecl.}
    reserved661: proc (){.cdecl.}
    reserved662: proc (){.cdecl.}
    reserved663: proc (){.cdecl.}
    reserved664: proc (){.cdecl.}

  PTextAppearance* = ptr TTextAppearance
  TTextAppearance*{.final, pure.} = object
    bg_color*: gdk2.TColor
    fg_color*: gdk2.TColor
    bg_stipple*: gdk2.PBitmap
    fg_stipple*: gdk2.PBitmap
    rise*: gint
    padding1*: gpointer
    flag0*: guint16

  TTextAttributes*{.final, pure.} = object
    refcount*: guint
    appearance*: TTextAppearance
    justification*: TJustification
    direction*: TTextDirection
    font*: pango.PFontDescription
    font_scale*: gdouble
    left_margin*: gint
    indent*: gint
    right_margin*: gint
    pixels_above_lines*: gint
    pixels_below_lines*: gint
    pixels_inside_wrap*: gint
    tabs*: pango.PTabArray
    wrap_mode*: TWrapMode
    language*: pango.PLanguage
    padding1*: gpointer
    flag0*: guint16

  TTextTagTableForeach* = proc (tag: PTextTag, data: gpointer){.cdecl.}
  TTextTagTable* = object of TGObject
    hash*: PGHashTable
    anonymous*: PGSList
    anon_count*: gint
    buffers*: PGSList

  PTextTagTableClass* = ptr TTextTagTableClass
  TTextTagTableClass* = object of TGObjectClass
    tag_changed*: proc (table: PTextTagTable, tag: PTextTag,
                        size_changed: gboolean){.cdecl.}
    tag_added*: proc (table: PTextTagTable, tag: PTextTag){.cdecl.}
    tag_removed*: proc (table: PTextTagTable, tag: PTextTag){.cdecl.}
    reserved1: proc (){.cdecl.}
    reserved2: proc (){.cdecl.}
    reserved3: proc (){.cdecl.}
    reserved4: proc (){.cdecl.}

  PTextMark* = ptr TTextMark
  TTextMark* = object of TGObject
    segment*: gpointer

  PTextMarkClass* = ptr TTextMarkClass
  TTextMarkClass* = object of TGObjectClass
    reserved1: proc (){.cdecl.}
    reserved2: proc (){.cdecl.}
    reserved3: proc (){.cdecl.}
    reserved4: proc (){.cdecl.}

  PTextMarkBody* = ptr TTextMarkBody
  TTextMarkBody*{.final, pure.} = object
    obj*: PTextMark
    name*: cstring
    tree*: PTextBTree
    line*: PTextLine
    flag0*: guint16

  PTextChildAnchor* = ptr TTextChildAnchor
  TTextChildAnchor* = object of TGObject
    segment*: gpointer

  PTextChildAnchorClass* = ptr TTextChildAnchorClass
  TTextChildAnchorClass* = object of TGObjectClass
    reserved1: proc (){.cdecl.}
    reserved2: proc (){.cdecl.}
    reserved3: proc (){.cdecl.}
    reserved4: proc (){.cdecl.}

  PTextPixbuf* = ptr TTextPixbuf
  TTextPixbuf*{.final, pure.} = object
    pixbuf*: gdk2pixbuf.PPixbuf

  PTextChildBody* = ptr TTextChildBody
  TTextChildBody*{.final, pure.} = object
    obj*: PTextChildAnchor
    widgets*: PGSList
    tree*: PTextBTree
    line*: PTextLine

  PTextLineSegment* = ptr TTextLineSegment
  PTextLineSegmentClass* = ptr TTextLineSegmentClass
  PTextTagInfo* = ptr TTextTagInfo
  TTextTagInfo*{.final, pure.} = object
    tag*: PTextTag
    tag_root*: PTextBTreeNode
    toggle_count*: gint

  PTextToggleBody* = ptr TTextToggleBody
  TTextToggleBody*{.final, pure.} = object
    info*: PTextTagInfo
    inNodeCounts*: gboolean

  TTextLineSegment*{.final, pure.} = object
    `type`*: PTextLineSegmentClass
    next*: PTextLineSegment
    char_count*: int32
    byte_count*: int32
    body*: TTextChildBody

  PTextSegSplitFunc* = ptr TTextSegSplitFunc
  TTextSegSplitFunc* = TTextLineSegment
  TTextSegDeleteFunc* = proc (seg: PTextLineSegment, line: PTextLine,
                              tree_gone: gboolean): gboolean{.cdecl.}
  PTextSegCleanupFunc* = ptr TTextSegCleanupFunc
  TTextSegCleanupFunc* = TTextLineSegment
  TTextSegLineChangeFunc* = proc (seg: PTextLineSegment, line: PTextLine){.cdecl.}
  TTextSegCheckFunc* = proc (seg: PTextLineSegment, line: PTextLine){.cdecl.}
  TTextLineSegmentClass*{.final, pure.} = object
    name*: cstring
    leftGravity*: gboolean
    splitFunc*: TTextSegSplitFunc
    deleteFunc*: TTextSegDeleteFunc
    cleanupFunc*: TTextSegCleanupFunc
    lineChangeFunc*: TTextSegLineChangeFunc
    checkFunc*: TTextSegCheckFunc

  PTextLineData* = ptr TTextLineData
  TTextLineData*{.final, pure.} = object
    view_id*: gpointer
    next*: PTextLineData
    height*: gint
    flag0*: int32

  TTextLine*{.final, pure.} = object
    parent*: PTextBTreeNode
    next*: PTextLine
    segments*: PTextLineSegment
    views*: PTextLineData

  PTextLogAttrCache* = pointer
  PTextBuffer* = ptr TTextBuffer
  TTextBuffer* = object of TGObject
    tag_table*: PTextTagTable
    btree*: PTextBTree
    clipboard_contents_buffers*: PGSList
    selection_clipboards*: PGSList
    log_attr_cache*: PTextLogAttrCache
    user_action_count*: guint
    TextBuffer_flag0*: guint16

  PTextBufferClass* = ptr TTextBufferClass
  TTextBufferClass* = object of TGObjectClass
    insert_text*: proc (buffer: PTextBuffer, pos: PTextIter, text: cstring,
                        length: gint){.cdecl.}
    insert_pixbuf*: proc (buffer: PTextBuffer, pos: PTextIter,
                          pixbuf: gdk2pixbuf.PPixbuf){.cdecl.}
    insert_child_anchor*: proc (buffer: PTextBuffer, pos: PTextIter,
                                anchor: PTextChildAnchor){.cdecl.}
    delete_range*: proc (buffer: PTextBuffer, start: PTextIter,
                         theEnd: PTextIter){.cdecl.}
    changed*: proc (buffer: PTextBuffer){.cdecl.}
    modified_changed*: proc (buffer: PTextBuffer){.cdecl.}
    mark_set*: proc (buffer: PTextBuffer, location: PTextIter, mark: PTextMark){.
        cdecl.}
    mark_deleted*: proc (buffer: PTextBuffer, mark: PTextMark){.cdecl.}
    apply_tag*: proc (buffer: PTextBuffer, tag: PTextTag, start_char: PTextIter,
                      end_char: PTextIter){.cdecl.}
    remove_tag*: proc (buffer: PTextBuffer, tag: PTextTag,
                       start_char: PTextIter, end_char: PTextIter){.cdecl.}
    begin_user_action*: proc (buffer: PTextBuffer){.cdecl.}
    end_user_action*: proc (buffer: PTextBuffer){.cdecl.}
    reserved1: proc (){.cdecl.}
    reserved2: proc (){.cdecl.}
    reserved3: proc (){.cdecl.}
    reserved4: proc (){.cdecl.}
    reserved5: proc (){.cdecl.}
    reserved6: proc (){.cdecl.}

  PTextLineDisplay* = ptr TTextLineDisplay
  PTextLayout* = ptr TTextLayout
  TTextLayout* = object of TGObject
    screen_width*: gint
    width*: gint
    height*: gint
    buffer*: PTextBuffer
    default_style*: PTextAttributes
    ltr_context*: pango.PContext
    rtl_context*: pango.PContext
    one_style_cache*: PTextAttributes
    one_display_cache*: PTextLineDisplay
    wrap_loop_count*: gint
    TextLayout_flag0*: guint16
    preedit_string*: cstring
    preedit_attrs*: pango.PAttrList
    preedit_len*: gint
    preedit_cursor*: gint

  PTextLayoutClass* = ptr TTextLayoutClass
  TTextLayoutClass* = object of TGObjectClass
    invalidated*: proc (layout: PTextLayout){.cdecl.}
    changed*: proc (layout: PTextLayout, y: gint, old_height: gint,
                    new_height: gint){.cdecl.}
    wrap*: proc (layout: PTextLayout, line: PTextLine, line_data: PTextLineData): PTextLineData{.
        cdecl.}
    get_log_attrs*: proc (layout: PTextLayout, line: PTextLine,
                          attrs: var pango.PLogAttr, n_attrs: Pgint){.cdecl.}
    invalidate*: proc (layout: PTextLayout, start: PTextIter, theEnd: PTextIter){.
        cdecl.}
    free_line_data*: proc (layout: PTextLayout, line: PTextLine,
                           line_data: PTextLineData){.cdecl.}
    allocate_child*: proc (layout: PTextLayout, child: PWidget, x: gint, y: gint){.
        cdecl.}
    reserved1: proc (){.cdecl.}
    reserved2: proc (){.cdecl.}
    reserved3: proc (){.cdecl.}
    reserved4: proc (){.cdecl.}

  PTextAttrAppearance* = ptr TTextAttrAppearance
  TTextAttrAppearance*{.final, pure.} = object
    attr*: pango.TAttribute
    appearance*: TTextAppearance

  PTextCursorDisplay* = ptr TTextCursorDisplay
  TTextCursorDisplay*{.final, pure.} = object
    x*: gint
    y*: gint
    height*: gint
    flag0*: guint16

  TTextLineDisplay*{.final, pure.} = object
    layout*: pango.PLayout
    cursors*: PGSList
    shaped_objects*: PGSList
    direction*: TTextDirection
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
    line*: PTextLine

  PTextWindow* = pointer
  PTextPendingScroll* = pointer
  PTextWindowType* = ptr TTextWindowType
  TTextWindowType* = enum
    TEXT_WINDOW_PRIVATE, TEXT_WINDOW_WIDGET, TEXT_WINDOW_TEXT, TEXT_WINDOW_LEFT,
    TEXT_WINDOW_RIGHT, TEXT_WINDOW_TOP, TEXT_WINDOW_BOTTOM
  PTextView* = ptr TTextView
  TTextView* = object of TContainer
    layout*: PTextLayout
    buffer*: PTextBuffer
    selection_drag_handler*: guint
    scroll_timeout*: guint
    pixels_above_lines*: gint
    pixels_below_lines*: gint
    pixels_inside_wrap*: gint
    wrap_mode*: TWrapMode
    justify*: TJustification
    left_margin*: gint
    right_margin*: gint
    indent*: gint
    tabs*: pango.PTabArray
    TextView_flag0*: guint16
    text_window*: PTextWindow
    left_window*: PTextWindow
    right_window*: PTextWindow
    top_window*: PTextWindow
    bottom_window*: PTextWindow
    hadjustment*: PAdjustment
    vadjustment*: PAdjustment
    xoffset*: gint
    yoffset*: gint
    width*: gint
    height*: gint
    virtual_cursor_x*: gint
    virtual_cursor_y*: gint
    first_para_mark*: PTextMark
    first_para_pixels*: gint
    dnd_mark*: PTextMark
    blink_timeout*: guint
    first_validate_idle*: guint
    incremental_validate_idle*: guint
    im_context*: PIMContext
    popup_menu*: PWidget
    drag_start_x*: gint
    drag_start_y*: gint
    children*: PGSList
    pending_scroll*: PTextPendingScroll
    pending_place_cursor_button*: gint

  PTextViewClass* = ptr TTextViewClass
  TTextViewClass* = object of TContainerClass
    set_scroll_adjustments*: proc (text_view: PTextView,
                                   hadjustment: PAdjustment,
                                   vadjustment: PAdjustment){.cdecl.}
    populate_popup*: proc (text_view: PTextView, menu: PMenu){.cdecl.}
    move_cursor*: proc (text_view: PTextView, step: TMovementStep, count: gint,
                        extend_selection: gboolean){.cdecl.}
    page_horizontally*: proc (text_view: PTextView, count: gint,
                              extend_selection: gboolean){.cdecl.}
    set_anchor*: proc (text_view: PTextView){.cdecl.}
    insert_at_cursor*: proc (text_view: PTextView, str: cstring){.cdecl.}
    delete_from_cursor*: proc (text_view: PTextView, thetype: TDeleteType,
                               count: gint){.cdecl.}
    cut_clipboard*: proc (text_view: PTextView){.cdecl.}
    copy_clipboard*: proc (text_view: PTextView){.cdecl.}
    paste_clipboard*: proc (text_view: PTextView){.cdecl.}
    toggle_overwrite*: proc (text_view: PTextView){.cdecl.}
    move_focus*: proc (text_view: PTextView, direction: TDirectionType){.cdecl.}
    reserved711: proc (){.cdecl.}
    reserved712: proc (){.cdecl.}
    reserved713: proc (){.cdecl.}
    reserved714: proc (){.cdecl.}
    reserved715: proc (){.cdecl.}
    reserved716: proc (){.cdecl.}
    reserved717: proc (){.cdecl.}
    reserved718: proc (){.cdecl.}

  PTipsQuery* = ptr TTipsQuery
  TTipsQuery* = object of TLabel
    TipsQuery_flag0*: guint16
    label_inactive*: cstring
    label_no_tip*: cstring
    caller*: PWidget
    last_crossed*: PWidget
    query_cursor*: gdk2.PCursor

  PTipsQueryClass* = ptr TTipsQueryClass
  TTipsQueryClass* = object of TLabelClass
    start_query*: proc (tips_query: PTipsQuery){.cdecl.}
    stop_query*: proc (tips_query: PTipsQuery){.cdecl.}
    widget_entered*: proc (tips_query: PTipsQuery, widget: PWidget,
                           tip_text: cstring, tip_private: cstring){.cdecl.}
    widget_selected*: proc (tips_query: PTipsQuery, widget: PWidget,
                            tip_text: cstring, tip_private: cstring,
                            event: gdk2.PEventButton): gint{.cdecl.}
    reserved721: proc (){.cdecl.}
    reserved722: proc (){.cdecl.}
    reserved723: proc (){.cdecl.}
    reserved724: proc (){.cdecl.}

  PTooltips* = ptr TTooltips
  PTooltipsData* = ptr TTooltipsData
  TTooltipsData*{.final, pure.} = object
    tooltips*: PTooltips
    widget*: PWidget
    tip_text*: cstring
    tip_private*: cstring

  TTooltips* = object of TObject
    tip_window*: PWidget
    tip_label*: PWidget
    active_tips_data*: PTooltipsData
    tips_data_list*: PGList
    Tooltips_flag0*: int32
    flag1*: guint16
    timer_tag*: gint
    last_popdown*: TGTimeVal

  PTooltipsClass* = ptr TTooltipsClass
  TTooltipsClass* = object of TObjectClass
    reserved1: proc (){.cdecl.}
    reserved2: proc (){.cdecl.}
    reserved3: proc (){.cdecl.}
    reserved4: proc (){.cdecl.}

  PToolbarChildType* = ptr TToolbarChildType
  TToolbarChildType* = enum
    TOOLBAR_CHILD_SPACE, TOOLBAR_CHILD_BUTTON, TOOLBAR_CHILD_TOGGLEBUTTON,
    TOOLBAR_CHILD_RADIOBUTTON, TOOLBAR_CHILD_WIDGET
  PToolbarSpaceStyle* = ptr TToolbarSpaceStyle
  TToolbarSpaceStyle* = enum
    TOOLBAR_SPACE_EMPTY, TOOLBAR_SPACE_LINE
  PToolbarChild* = ptr TToolbarChild
  TToolbarChild*{.final, pure.} = object
    `type`*: TToolbarChildType
    widget*: PWidget
    icon*: PWidget
    label*: PWidget

  PToolbar* = ptr TToolbar
  TToolbar* = object of TContainer
    num_children*: gint
    children*: PGList
    orientation*: TOrientation
    Toolbar_style*: TToolbarStyle
    icon_size*: TIconSize
    tooltips*: PTooltips
    button_maxw*: gint
    button_maxh*: gint
    style_set_connection*: guint
    icon_size_connection*: guint
    Toolbar_flag0*: guint16

  PToolbarClass* = ptr TToolbarClass
  TToolbarClass* = object of TContainerClass
    orientation_changed*: proc (toolbar: PToolbar, orientation: TOrientation){.
        cdecl.}
    style_changed*: proc (toolbar: PToolbar, style: TToolbarStyle){.cdecl.}
    reserved731: proc (){.cdecl.}
    reserved732: proc (){.cdecl.}
    reserved733: proc (){.cdecl.}
    reserved734: proc (){.cdecl.}

  PTreeViewMode* = ptr TTreeViewMode
  TTreeViewMode* = enum
    TREE_VIEW_LINE, TREE_VIEW_ITEM
  PTree* = ptr TTree
  TTree* = object of TContainer
    children*: PGList
    root_tree*: PTree
    tree_owner*: PWidget
    selection*: PGList
    level*: guint
    indent_value*: guint
    current_indent*: guint
    Tree_flag0*: guint16

  PTreeClass* = ptr TTreeClass
  TTreeClass* = object of TContainerClass
    selection_changed*: proc (tree: PTree){.cdecl.}
    select_child*: proc (tree: PTree, child: PWidget){.cdecl.}
    unselect_child*: proc (tree: PTree, child: PWidget){.cdecl.}

  PTreeDragSource* = pointer
  PTreeDragDest* = pointer
  PTreeDragSourceIface* = ptr TTreeDragSourceIface
  TTreeDragSourceIface* = object of TGTypeInterface
    row_draggable*: proc (drag_source: PTreeDragSource, path: PTreePath): gboolean{.
        cdecl.}
    drag_data_get*: proc (drag_source: PTreeDragSource, path: PTreePath,
                          selection_data: PSelectionData): gboolean{.cdecl.}
    drag_data_delete*: proc (drag_source: PTreeDragSource, path: PTreePath): gboolean{.
        cdecl.}

  PTreeDragDestIface* = ptr TTreeDragDestIface
  TTreeDragDestIface* = object of TGTypeInterface
    drag_data_received*: proc (drag_dest: PTreeDragDest, dest: PTreePath,
                               selection_data: PSelectionData): gboolean{.cdecl.}
    row_drop_possible*: proc (drag_dest: PTreeDragDest, dest_path: PTreePath,
                              selection_data: PSelectionData): gboolean{.cdecl.}

  PTreeItem* = ptr TTreeItem
  TTreeItem* = object of TItem
    subtree*: PWidget
    pixmaps_box*: PWidget
    plus_pix_widget*: PWidget
    minus_pix_widget*: PWidget
    pixmaps*: PGList
    TreeItem_flag0*: guint16

  PTreeItemClass* = ptr TTreeItemClass
  TTreeItemClass* = object of TItemClass
    expand*: proc (tree_item: PTreeItem){.cdecl.}
    collapse*: proc (tree_item: PTreeItem){.cdecl.}

  PTreeSelection* = ptr TTreeSelection
  TTreeSelectionFunc* = proc (selection: PTreeSelection, model: PTreeModel,
                              path: PTreePath,
                              path_currently_selected: gboolean, data: gpointer): gboolean{.
      cdecl.}
  TTreeSelectionForeachFunc* = proc (model: PTreeModel, path: PTreePath,
                                     iter: PTreeIter, data: gpointer){.cdecl.}
  TTreeSelection* = object of TGObject
    tree_view*: PTreeView
    thetype*: TSelectionMode
    user_func*: TTreeSelectionFunc
    user_data*: gpointer
    destroy*: TDestroyNotify

  PTreeSelectionClass* = ptr TTreeSelectionClass
  TTreeSelectionClass* = object of TGObjectClass
    changed*: proc (selection: PTreeSelection){.cdecl.}
    reserved741: proc (){.cdecl.}
    reserved742: proc (){.cdecl.}
    reserved743: proc (){.cdecl.}
    reserved744: proc (){.cdecl.}

  PTreeStore* = ptr TTreeStore
  TTreeStore* = object of TGObject
    stamp*: gint
    root*: gpointer
    last*: gpointer
    n_columns*: gint
    sort_column_id*: gint
    sort_list*: PGList
    order*: TSortType
    column_headers*: PGType
    default_sort_func*: TTreeIterCompareFunc
    default_sort_data*: gpointer
    default_sort_destroy*: TDestroyNotify
    TreeStore_flag0*: guint16

  PTreeStoreClass* = ptr TTreeStoreClass
  TTreeStoreClass* = object of TGObjectClass
    reserved751: proc (){.cdecl.}
    reserved752: proc (){.cdecl.}
    reserved753: proc (){.cdecl.}
    reserved754: proc (){.cdecl.}

  PTreeViewColumnSizing* = ptr TTreeViewColumnSizing
  TTreeViewColumnSizing* = enum
    TREE_VIEW_COLUMN_GROW_ONLY, TREE_VIEW_COLUMN_AUTOSIZE,
    TREE_VIEW_COLUMN_FIXED
  TTreeCellDataFunc* = proc (tree_column: PTreeViewColumn, cell: PCellRenderer,
                             tree_model: PTreeModel, iter: PTreeIter,
                             data: gpointer){.cdecl.}
  TTreeViewColumn* = object of TObject
    tree_view*: PWidget
    button*: PWidget
    child*: PWidget
    arrow*: PWidget
    alignment*: PWidget
    window*: gdk2.PWindow
    editable_widget*: PCellEditable
    xalign*: gfloat
    property_changed_signal*: guint
    spacing*: gint
    column_type*: TTreeViewColumnSizing
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
    sort_order*: TSortType
    TreeViewColumn_flag0*: guint16

  PTreeViewColumnClass* = ptr TTreeViewColumnClass
  TTreeViewColumnClass* = object of TObjectClass
    clicked*: proc (tree_column: PTreeViewColumn){.cdecl.}
    reserved751: proc (){.cdecl.}
    reserved752: proc (){.cdecl.}
    reserved753: proc (){.cdecl.}
    reserved754: proc (){.cdecl.}

  PRBNodeColor* = ptr TRBNodeColor
  TRBNodeColor* = int32
  PRBTree* = ptr TRBTree
  PRBNode* = ptr TRBNode
  TRBTreeTraverseFunc* = proc (tree: PRBTree, node: PRBNode, data: gpointer){.
      cdecl.}
  TRBTree*{.final, pure.} = object
    root*: PRBNode
    `nil`*: PRBNode
    parent_tree*: PRBTree
    parent_node*: PRBNode

  TRBNode*{.final, pure.} = object
    flag0*: guint16
    left*: PRBNode
    right*: PRBNode
    parent*: PRBNode
    count*: gint
    offset*: gint
    children*: PRBTree

  PTreeRowReference* = pointer
  PTreeViewFlags* = ptr TTreeViewFlags
  TTreeViewFlags* = int32
  TTreeViewSearchDialogPositionFunc* = proc (tree_view: PTreeView,
      search_dialog: PWidget){.cdecl.}
  PTreeViewColumnReorder* = ptr TTreeViewColumnReorder
  TTreeViewColumnReorder*{.final, pure.} = object
    left_align*: gint
    right_align*: gint
    left_column*: PTreeViewColumn
    right_column*: PTreeViewColumn

  PTreeViewPrivate* = ptr TTreeViewPrivate
  TTreeViewPrivate*{.final, pure.} = object
    model*: PTreeModel
    flags*: guint
    tree*: PRBTree
    button_pressed_node*: PRBNode
    button_pressed_tree*: PRBTree
    children*: PGList
    width*: gint
    height*: gint
    expander_size*: gint
    hadjustment*: PAdjustment
    vadjustment*: PAdjustment
    bin_window*: gdk2.PWindow
    header_window*: gdk2.PWindow
    drag_window*: gdk2.PWindow
    drag_highlight_window*: gdk2.PWindow
    drag_column*: PTreeViewColumn
    last_button_press*: PTreeRowReference
    last_button_press_2*: PTreeRowReference
    top_row*: PTreeRowReference
    top_row_dy*: gint
    dy*: gint
    drag_column_x*: gint
    expander_column*: PTreeViewColumn
    edited_column*: PTreeViewColumn
    presize_handler_timer*: guint
    validate_rows_timer*: guint
    scroll_sync_timer*: guint
    focus_column*: PTreeViewColumn
    anchor*: PTreeRowReference
    cursor*: PTreeRowReference
    drag_pos*: gint
    x_drag*: gint
    prelight_node*: PRBNode
    prelight_tree*: PRBTree
    expanded_collapsed_node*: PRBNode
    expanded_collapsed_tree*: PRBTree
    expand_collapse_timeout*: guint
    selection*: PTreeSelection
    n_columns*: gint
    columns*: PGList
    header_height*: gint
    column_drop_func*: TTreeViewColumnDropFunc
    column_drop_func_data*: gpointer
    column_drop_func_data_destroy*: TDestroyNotify
    column_drag_info*: PGList
    cur_reorder*: PTreeViewColumnReorder
    destroy_count_func*: TTreeDestroyCountFunc
    destroy_count_data*: gpointer
    destroy_count_destroy*: TDestroyNotify
    scroll_timeout*: guint
    drag_dest_row*: PTreeRowReference
    drag_dest_pos*: TTreeViewDropPosition
    open_dest_timeout*: guint
    pressed_button*: gint
    press_start_x*: gint
    press_start_y*: gint
    scroll_to_path*: PTreeRowReference
    scroll_to_column*: PTreeViewColumn
    scroll_to_row_align*: gfloat
    scroll_to_col_align*: gfloat
    flag0*: guint16
    search_column*: gint
    search_dialog_position_func*: TTreeViewSearchDialogPositionFunc
    search_equal_func*: TTreeViewSearchEqualFunc
    search_user_data*: gpointer
    search_destroy*: TDestroyNotify

  TTreeView* = object of TContainer
    priv*: PTreeViewPrivate

  PTreeViewClass* = ptr TTreeViewClass
  TTreeViewClass* = object of TContainerClass
    set_scroll_adjustments*: proc (tree_view: PTreeView,
                                   hadjustment: PAdjustment,
                                   vadjustment: PAdjustment){.cdecl.}
    row_activated*: proc (tree_view: PTreeView, path: PTreePath,
                          column: PTreeViewColumn){.cdecl.}
    test_expand_row*: proc (tree_view: PTreeView, iter: PTreeIter,
                            path: PTreePath): gboolean{.cdecl.}
    test_collapse_row*: proc (tree_view: PTreeView, iter: PTreeIter,
                              path: PTreePath): gboolean{.cdecl.}
    row_expanded*: proc (tree_view: PTreeView, iter: PTreeIter, path: PTreePath){.
        cdecl.}
    row_collapsed*: proc (tree_view: PTreeView, iter: PTreeIter, path: PTreePath){.
        cdecl.}
    columns_changed*: proc (tree_view: PTreeView){.cdecl.}
    cursor_changed*: proc (tree_view: PTreeView){.cdecl.}
    move_cursor*: proc (tree_view: PTreeView, step: TMovementStep, count: gint): gboolean{.
        cdecl.}
    select_all*: proc (tree_view: PTreeView){.cdecl.}
    unselect_all*: proc (tree_view: PTreeView){.cdecl.}
    select_cursor_row*: proc (tree_view: PTreeView, start_editing: gboolean){.
        cdecl.}
    toggle_cursor_row*: proc (tree_view: PTreeView){.cdecl.}
    expand_collapse_cursor_row*: proc (tree_view: PTreeView, logical: gboolean,
                                       expand: gboolean, open_all: gboolean){.
        cdecl.}
    select_cursor_parent*: proc (tree_view: PTreeView){.cdecl.}
    start_interactive_search*: proc (tree_view: PTreeView){.cdecl.}
    reserved760: proc (){.cdecl.}
    reserved761: proc (){.cdecl.}
    reserved762: proc (){.cdecl.}
    reserved763: proc (){.cdecl.}
    reserved764: proc (){.cdecl.}

  PVButtonBox* = ptr TVButtonBox
  TVButtonBox* = object of TButtonBox
  PVButtonBoxClass* = ptr TVButtonBoxClass
  TVButtonBoxClass* = object of TButtonBoxClass
  PViewport* = ptr TViewport
  TViewport* = object of TBin
    shadow_type*: TShadowType
    view_window*: gdk2.PWindow
    bin_window*: gdk2.PWindow
    hadjustment*: PAdjustment
    vadjustment*: PAdjustment

  PViewportClass* = ptr TViewportClass
  TViewportClass* = object of TBinClass
    set_scroll_adjustments*: proc (viewport: PViewport,
                                   hadjustment: PAdjustment,
                                   vadjustment: PAdjustment){.cdecl.}

  PVPaned* = ptr TVPaned
  TVPaned* = object of TPaned
  PVPanedClass* = ptr TVPanedClass
  TVPanedClass* = object of TPanedClass
  PVRuler* = ptr TVRuler
  TVRuler* = object of TRuler
  PVRulerClass* = ptr TVRulerClass
  TVRulerClass* = object of TRulerClass
  PVScale* = ptr TVScale
  TVScale* = object of TScale
  PVScaleClass* = ptr TVScaleClass
  TVScaleClass* = object of TScaleClass
  PVScrollbar* = ptr TVScrollbar
  TVScrollbar* = object of TScrollbar
  PVScrollbarClass* = ptr TVScrollbarClass
  TVScrollbarClass* = object of TScrollbarClass
  PVSeparator* = ptr TVSeparator
  TVSeparator* = object of TSeparator
  PVSeparatorClass* = ptr TVSeparatorClass
  TVSeparatorClass* = object of TSeparatorClass

const
  IN_DESTRUCTION* = 1 shl 0
  FLOATING* = 1 shl 1
  RESERVED_1* = 1 shl 2
  RESERVED_2* = 1 shl 3
  ARG_READABLE* = G_PARAM_READABLE
  ARG_WRITABLE* = G_PARAM_WRITABLE
  ARG_CONSTRUCT* = G_PARAM_CONSTRUCT
  ARG_CONSTRUCT_ONLY* = G_PARAM_CONSTRUCT_ONLY
  ARG_CHILD_ARG* = 1 shl 4

proc TYPE_OBJECT*(): GType
proc `OBJECT`*(anObject: pointer): PObject
proc OBJECT_CLASS*(klass: pointer): PObjectClass
proc IS_OBJECT*(anObject: pointer): bool
proc IS_OBJECT_CLASS*(klass: pointer): bool
proc OBJECT_GET_CLASS*(anObject: pointer): PObjectClass
proc OBJECT_TYPE*(anObject: pointer): GType
proc OBJECT_TYPE_NAME*(anObject: pointer): cstring
proc OBJECT_FLAGS*(obj: pointer): guint32
proc OBJECT_FLOATING*(obj: pointer): gboolean
proc OBJECT_SET_FLAGS*(obj: pointer, flag: guint32)
proc OBJECT_UNSET_FLAGS*(obj: pointer, flag: guint32)
proc object_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_object_get_type".}
proc object_new*(thetype: TType, first_property_name: cstring): PObject{.cdecl,
    varargs, dynlib: lib, importc: "gtk_object_new".}
proc sink*(anObject: PObject){.cdecl, dynlib: lib,
                                      importc: "gtk_object_sink".}
proc destroy*(anObject: PObject){.cdecl, dynlib: lib,
    importc: "gtk_object_destroy".}
const
  TYPE_INVALID* = G_TYPE_INVALID
  TYPE_NONE* = G_TYPE_NONE
  TYPE_ENUM* = G_TYPE_ENUM
  TYPE_FLAGS* = G_TYPE_FLAGS
  TYPE_CHAR* = G_TYPE_CHAR
  TYPE_UCHAR* = G_TYPE_UCHAR
  TYPE_BOOL* = G_TYPE_BOOLEAN
  TYPE_INT* = G_TYPE_INT
  TYPE_UINT* = G_TYPE_UINT
  TYPE_LONG* = G_TYPE_LONG
  TYPE_ULONG* = G_TYPE_ULONG
  TYPE_FLOAT* = G_TYPE_FLOAT
  TYPE_DOUBLE* = G_TYPE_DOUBLE
  TYPE_STRING* = G_TYPE_STRING
  TYPE_BOXED* = G_TYPE_BOXED
  TYPE_POINTER* = G_TYPE_POINTER

proc TYPE_IDENTIFIER*(): GType
proc identifier_get_type*(): GType{.cdecl, dynlib: lib,
                                    importc: "gtk_identifier_get_type".}
proc SIGNAL_FUNC*(f: pointer): TSignalFunc
proc type_class*(thetype: TType): gpointer{.cdecl, dynlib: lib,
    importc: "gtk_type_class".}
const
  TOPLEVEL* = 1 shl 4
  NO_WINDOW* = 1 shl 5
  constREALIZED* = 1 shl 6
  MAPPED* = 1 shl 7
  constVISIBLE* = 1 shl 8
  SENSITIVE* = 1 shl 9
  PARENT_SENSITIVE* = 1 shl 10
  CAN_FOCUS* = 1 shl 11
  constHAS_FOCUS* = 1 shl 12
  CAN_DEFAULT* = 1 shl 13
  HAS_DEFAULT* = 1 shl 14
  HAS_GRAB* = 1 shl 15
  RC_STYLE* = 1 shl 16
  COMPOSITE_CHILD* = 1 shl 17
  NO_REPARENT* = 1 shl 18
  APP_PAINTABLE* = 1 shl 19
  RECEIVES_DEFAULT* = 1 shl 20
  DOUBLE_BUFFERED* = 1 shl 21

const
  bm_TGtkWidgetAuxInfo_x_set* = 0x0001'i16
  bp_TGtkWidgetAuxInfo_x_set* = 0'i16
  bm_TGtkWidgetAuxInfo_y_set* = 0x0002'i16
  bp_TGtkWidgetAuxInfo_y_set* = 1'i16

proc TYPE_WIDGET*(): GType
proc WIDGET*(widget: pointer): PWidget
proc WIDGET_CLASS*(klass: pointer): PWidgetClass
proc IS_WIDGET*(widget: pointer): bool
proc IS_WIDGET_CLASS*(klass: pointer): bool
proc WIDGET_GET_CLASS*(obj: pointer): PWidgetClass
proc WIDGET_TYPE*(wid: pointer): GType
proc WIDGET_STATE*(wid: pointer): int32
proc WIDGET_SAVED_STATE*(wid: pointer): int32
proc WIDGET_FLAGS*(wid: pointer): guint32
proc WIDGET_TOPLEVEL*(wid: pointer): gboolean
proc WIDGET_NO_WINDOW*(wid: pointer): gboolean
proc WIDGET_REALIZED*(wid: pointer): gboolean
proc WIDGET_MAPPED*(wid: pointer): gboolean
proc WIDGET_VISIBLE*(wid: pointer): gboolean
proc WIDGET_DRAWABLE*(wid: pointer): gboolean
proc WIDGET_SENSITIVE*(wid: pointer): gboolean
proc WIDGET_PARENT_SENSITIVE*(wid: pointer): gboolean
proc WIDGET_IS_SENSITIVE*(wid: pointer): gboolean
proc WIDGET_CAN_FOCUS*(wid: pointer): gboolean
proc WIDGET_HAS_FOCUS*(wid: pointer): gboolean
proc WIDGET_CAN_DEFAULT*(wid: pointer): gboolean
proc WIDGET_HAS_DEFAULT*(wid: pointer): gboolean
proc WIDGET_HAS_GRAB*(wid: pointer): gboolean
proc WIDGET_RC_STYLE*(wid: pointer): gboolean
proc WIDGET_COMPOSITE_CHILD*(wid: pointer): gboolean
proc WIDGET_APP_PAINTABLE*(wid: pointer): gboolean
proc WIDGET_RECEIVES_DEFAULT*(wid: pointer): gboolean
proc WIDGET_DOUBLE_BUFFERED*(wid: pointer): gboolean
proc SET_FLAGS*(wid: PWidget, flags: TWidgetFlags): TWidgetFlags
proc UNSET_FLAGS*(wid: PWidget, flags: TWidgetFlags): TWidgetFlags
proc TYPE_REQUISITION*(): GType
proc x_set*(a: PWidgetAuxInfo): guint
proc set_x_set*(a: PWidgetAuxInfo, x_set: guint)
proc y_set*(a: PWidgetAuxInfo): guint
proc set_y_set*(a: PWidgetAuxInfo, y_set: guint)
proc widget_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_widget_get_type".}
proc reference*(widget: PWidget): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_widget_ref".}
proc unref*(widget: PWidget){.cdecl, dynlib: lib,
                                     importc: "gtk_widget_unref".}
proc destroy*(widget: PWidget){.cdecl, dynlib: lib,
                                       importc: "gtk_widget_destroy".}
proc destroyed*(widget: PWidget, r: var PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_destroyed".}
proc unparent*(widget: PWidget){.cdecl, dynlib: lib,
                                        importc: "gtk_widget_unparent".}
proc show*(widget: PWidget){.cdecl, dynlib: lib,
                                    importc: "gtk_widget_show".}
proc show_now*(widget: PWidget){.cdecl, dynlib: lib,
                                        importc: "gtk_widget_show_now".}
proc hide*(widget: PWidget){.cdecl, dynlib: lib,
                                    importc: "gtk_widget_hide".}
proc show_all*(widget: PWidget){.cdecl, dynlib: lib,
                                        importc: "gtk_widget_show_all".}
proc hide_all*(widget: PWidget){.cdecl, dynlib: lib,
                                        importc: "gtk_widget_hide_all".}
proc map*(widget: PWidget){.cdecl, dynlib: lib, importc: "gtk_widget_map".}
proc unmap*(widget: PWidget){.cdecl, dynlib: lib,
                                     importc: "gtk_widget_unmap".}
proc realize*(widget: PWidget){.cdecl, dynlib: lib,
                                       importc: "gtk_widget_realize".}
proc unrealize*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_unrealize".}
proc queue_draw*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_queue_draw".}
proc queue_draw_area*(widget: PWidget, x: gint, y: gint, width: gint,
                             height: gint){.cdecl, dynlib: lib,
    importc: "gtk_widget_queue_draw_area".}
proc queue_resize*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_queue_resize".}
proc size_request*(widget: PWidget, requisition: PRequisition){.cdecl,
    dynlib: lib, importc: "gtk_widget_size_request".}
proc size_allocate*(widget: PWidget, allocation: PAllocation){.cdecl,
    dynlib: lib, importc: "gtk_widget_size_allocate".}
proc get_child_requisition*(widget: PWidget, requisition: PRequisition){.
    cdecl, dynlib: lib, importc: "gtk_widget_get_child_requisition".}
proc add_accelerator*(widget: PWidget, accel_signal: cstring,
                             accel_group: PAccelGroup, accel_key: guint,
                             accel_mods: gdk2.TModifierType,
                             accel_flags: TAccelFlags){.cdecl, dynlib: lib,
    importc: "gtk_widget_add_accelerator".}
proc remove_accelerator*(widget: PWidget, accel_group: PAccelGroup,
                                accel_key: guint, accel_mods: gdk2.TModifierType): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_widget_remove_accelerator".}
proc set_accel_path*(widget: PWidget, accel_path: cstring,
                            accel_group: PAccelGroup){.cdecl, dynlib: lib,
    importc: "gtk_widget_set_accel_path".}
proc get_accel_path*(widget: PWidget, locked: Pgboolean): cstring{.cdecl,
    dynlib: lib, importc: "_gtk_widget_get_accel_path".}
proc list_accel_closures*(widget: PWidget): PGList{.cdecl, dynlib: lib,
    importc: "gtk_widget_list_accel_closures".}
proc mnemonic_activate*(widget: PWidget, group_cycling: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_widget_mnemonic_activate".}
proc event*(widget: PWidget, event: gdk2.PEvent): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_widget_event".}
proc send_expose*(widget: PWidget, event: gdk2.PEvent): gint{.cdecl,
    dynlib: lib, importc: "gtk_widget_send_expose".}
proc activate*(widget: PWidget): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_widget_activate".}
proc set_scroll_adjustments*(widget: PWidget, hadjustment: PAdjustment,
                                    vadjustment: PAdjustment): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_widget_set_scroll_adjustments".}
proc reparent*(widget: PWidget, new_parent: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_reparent".}
proc intersect*(widget: PWidget, area: gdk2.PRectangle,
                       intersection: gdk2.PRectangle): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_widget_intersect".}
proc region_intersect*(widget: PWidget, region: gdk2.PRegion): gdk2.PRegion{.
    cdecl, dynlib: lib, importc: "gtk_widget_region_intersect".}
proc freeze_child_notify*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_freeze_child_notify".}
proc child_notify*(widget: PWidget, child_property: cstring){.cdecl,
    dynlib: lib, importc: "gtk_widget_child_notify".}
proc thaw_child_notify*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_thaw_child_notify".}
proc is_focus*(widget: PWidget): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_widget_is_focus".}
proc grab_focus*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_grab_focus".}
proc grab_default*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_grab_default".}
proc set_name*(widget: PWidget, name: cstring){.cdecl, dynlib: lib,
    importc: "gtk_widget_set_name".}
proc get_name*(widget: PWidget): cstring{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_name".}
proc set_state*(widget: PWidget, state: TStateType){.cdecl, dynlib: lib,
    importc: "gtk_widget_set_state".}
proc set_sensitive*(widget: PWidget, sensitive: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_widget_set_sensitive".}
proc set_app_paintable*(widget: PWidget, app_paintable: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_widget_set_app_paintable".}
proc set_double_buffered*(widget: PWidget, double_buffered: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_widget_set_double_buffered".}
proc set_redraw_on_allocate*(widget: PWidget,
                                    redraw_on_allocate: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_widget_set_redraw_on_allocate".}
proc set_parent*(widget: PWidget, parent: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_set_parent".}
proc set_parent_window*(widget: PWidget, parent_window: gdk2.PWindow){.
    cdecl, dynlib: lib, importc: "gtk_widget_set_parent_window".}
proc set_child_visible*(widget: PWidget, is_visible: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_widget_set_child_visible".}
proc get_child_visible*(widget: PWidget): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_child_visible".}
proc get_parent*(widget: PWidget): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_parent".}
proc get_parent_window*(widget: PWidget): gdk2.PWindow{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_parent_window".}
proc child_focus*(widget: PWidget, direction: TDirectionType): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_widget_child_focus".}
proc set_size_request*(widget: PWidget, width: gint, height: gint){.
    cdecl, dynlib: lib, importc: "gtk_widget_set_size_request".}
proc get_size_request*(widget: PWidget, width: Pgint, height: Pgint){.
    cdecl, dynlib: lib, importc: "gtk_widget_get_size_request".}
proc set_events*(widget: PWidget, events: gint){.cdecl, dynlib: lib,
    importc: "gtk_widget_set_events".}
proc add_events*(widget: PWidget, events: gint){.cdecl, dynlib: lib,
    importc: "gtk_widget_add_events".}
proc set_extension_events*(widget: PWidget, mode: gdk2.TExtensionMode){.
    cdecl, dynlib: lib, importc: "gtk_widget_set_extension_events".}
proc get_extension_events*(widget: PWidget): gdk2.TExtensionMode{.cdecl,
    dynlib: lib, importc: "gtk_widget_get_extension_events".}
proc get_toplevel*(widget: PWidget): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_toplevel".}
proc get_ancestor*(widget: PWidget, widget_type: TType): PWidget{.cdecl,
    dynlib: lib, importc: "gtk_widget_get_ancestor".}
proc get_colormap*(widget: PWidget): gdk2.PColormap{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_colormap".}
proc get_visual*(widget: PWidget): gdk2.PVisual{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_visual".}
proc get_screen*(widget: PWidget): gdk2.PScreen{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_screen".}
proc has_screen*(widget: PWidget): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_widget_has_screen".}
proc get_display*(widget: PWidget): gdk2.PDisplay{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_display".}
proc get_root_window*(widget: PWidget): gdk2.PWindow{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_root_window".}
proc get_settings*(widget: PWidget): PSettings{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_settings".}
proc get_clipboard*(widget: PWidget, selection: gdk2.TAtom): PClipboard{.
    cdecl, dynlib: lib, importc: "gtk_widget_get_clipboard".}
proc get_accessible*(widget: PWidget): atk.PObject{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_accessible".}
proc set_colormap*(widget: PWidget, colormap: gdk2.PColormap){.cdecl,
    dynlib: lib, importc: "gtk_widget_set_colormap".}
proc get_events*(widget: PWidget): gint{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_events".}
proc get_pointer*(widget: PWidget, x: Pgint, y: Pgint){.cdecl,
    dynlib: lib, importc: "gtk_widget_get_pointer".}
proc is_ancestor*(widget: PWidget, ancestor: PWidget): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_widget_is_ancestor".}
proc translate_coordinates*(src_widget: PWidget, dest_widget: PWidget,
                                   src_x: gint, src_y: gint, dest_x: Pgint,
                                   dest_y: Pgint): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_widget_translate_coordinates".}
proc hide_on_delete*(widget: PWidget): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_widget_hide_on_delete".}
proc set_style*(widget: PWidget, style: PStyle){.cdecl, dynlib: lib,
    importc: "gtk_widget_set_style".}
proc ensure_style*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_ensure_style".}
proc get_style*(widget: PWidget): PStyle{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_style".}
proc modify_style*(widget: PWidget, style: PRcStyle){.cdecl, dynlib: lib,
    importc: "gtk_widget_modify_style".}
proc get_modifier_style*(widget: PWidget): PRcStyle{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_modifier_style".}
proc modify_fg*(widget: PWidget, state: TStateType, color: gdk2.PColor){.
    cdecl, dynlib: lib, importc: "gtk_widget_modify_fg".}
proc modify_bg*(widget: PWidget, state: TStateType, color: gdk2.PColor){.
    cdecl, dynlib: lib, importc: "gtk_widget_modify_bg".}
proc modify_text*(widget: PWidget, state: TStateType, color: gdk2.PColor){.
    cdecl, dynlib: lib, importc: "gtk_widget_modify_text".}
proc modify_base*(widget: PWidget, state: TStateType, color: gdk2.PColor){.
    cdecl, dynlib: lib, importc: "gtk_widget_modify_base".}
proc modify_font*(widget: PWidget, font_desc: pango.PFontDescription){.
    cdecl, dynlib: lib, importc: "gtk_widget_modify_font".}
proc create_pango_context*(widget: PWidget): pango.PContext{.cdecl,
    dynlib: lib, importc: "gtk_widget_create_pango_context".}
proc get_pango_context*(widget: PWidget): pango.PContext{.cdecl,
    dynlib: lib, importc: "gtk_widget_get_pango_context".}
proc create_pango_layout*(widget: PWidget, text: cstring): pango.PLayout{.
    cdecl, dynlib: lib, importc: "gtk_widget_create_pango_layout".}
proc render_icon*(widget: PWidget, stock_id: cstring, size: TIconSize,
                         detail: cstring): gdk2pixbuf.PPixbuf{.cdecl, dynlib: lib,
    importc: "gtk_widget_render_icon".}
proc set_composite_name*(widget: PWidget, name: cstring){.cdecl,
    dynlib: lib, importc: "gtk_widget_set_composite_name".}
proc get_composite_name*(widget: PWidget): cstring{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_composite_name".}
proc reset_rc_styles*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_reset_rc_styles".}
proc widget_push_colormap*(cmap: gdk2.PColormap){.cdecl, dynlib: lib,
    importc: "gtk_widget_push_colormap".}
proc widget_push_composite_child*(){.cdecl, dynlib: lib,
                                     importc: "gtk_widget_push_composite_child".}
proc widget_pop_composite_child*(){.cdecl, dynlib: lib,
                                    importc: "gtk_widget_pop_composite_child".}
proc widget_pop_colormap*(){.cdecl, dynlib: lib,
                             importc: "gtk_widget_pop_colormap".}
proc install_style_property*(klass: PWidgetClass,
    pspec: PGParamSpec){.cdecl, dynlib: lib,
                         importc: "gtk_widget_class_install_style_property".}
proc install_style_property_parser*(klass: PWidgetClass,
    pspec: PGParamSpec, parser: TRcPropertyParser){.cdecl, dynlib: lib,
    importc: "gtk_widget_class_install_style_property_parser".}
proc find_style_property*(klass: PWidgetClass,
                                       property_name: cstring): PGParamSpec{.
    cdecl, dynlib: lib, importc: "gtk_widget_class_find_style_property".}
proc list_style_properties*(klass: PWidgetClass,
    n_properties: Pguint): PPGParamSpec{.cdecl, dynlib: lib,
    importc: "gtk_widget_class_list_style_properties".}
proc style_get_property*(widget: PWidget, property_name: cstring,
                                value: PGValue){.cdecl, dynlib: lib,
    importc: "gtk_widget_style_get_property".}
proc widget_set_default_colormap*(colormap: gdk2.PColormap){.cdecl, dynlib: lib,
    importc: "gtk_widget_set_default_colormap".}
proc widget_get_default_style*(): PStyle{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_default_style".}
proc set_direction*(widget: PWidget, dir: TTextDirection){.cdecl,
    dynlib: lib, importc: "gtk_widget_set_direction".}
proc get_direction*(widget: PWidget): TTextDirection{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_direction".}
proc widget_set_default_direction*(dir: TTextDirection){.cdecl, dynlib: lib,
    importc: "gtk_widget_set_default_direction".}
proc widget_get_default_direction*(): TTextDirection{.cdecl, dynlib: lib,
    importc: "gtk_widget_get_default_direction".}
proc shape_combine_mask*(widget: PWidget, shape_mask: gdk2.PBitmap,
                                offset_x: gint, offset_y: gint){.cdecl,
    dynlib: lib, importc: "gtk_widget_shape_combine_mask".}
proc reset_shapes*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_widget_reset_shapes".}
proc path*(widget: PWidget, path_length: Pguint, path: PPgchar,
                  path_reversed: PPgchar){.cdecl, dynlib: lib,
    importc: "gtk_widget_path".}
proc class_path*(widget: PWidget, path_length: Pguint, path: PPgchar,
                        path_reversed: PPgchar){.cdecl, dynlib: lib,
    importc: "gtk_widget_class_path".}
proc requisition_get_type*(): GType{.cdecl, dynlib: lib,
                                     importc: "gtk_requisition_get_type".}
proc copy*(requisition: PRequisition): PRequisition{.cdecl,
    dynlib: lib, importc: "gtk_requisition_copy".}
proc free*(requisition: PRequisition){.cdecl, dynlib: lib,
    importc: "gtk_requisition_free".}
proc get_aux_info*(widget: PWidget, create: gboolean): PWidgetAuxInfo{.
    cdecl, dynlib: lib, importc: "gtk_widget_get_aux_info".}
proc propagate_hierarchy_changed*(widget: PWidget,
    previous_toplevel: PWidget){.cdecl, dynlib: lib, importc: "_gtk_widget_propagate_hierarchy_changed".}
proc widget_peek_colormap*(): gdk2.PColormap{.cdecl, dynlib: lib,
    importc: "_gtk_widget_peek_colormap".}
proc TYPE_MISC*(): GType
proc MISC*(obj: pointer): PMisc
proc MISC_CLASS*(klass: pointer): PMiscClass
proc IS_MISC*(obj: pointer): bool
proc IS_MISC_CLASS*(klass: pointer): bool
proc MISC_GET_CLASS*(obj: pointer): PMiscClass
proc misc_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_misc_get_type".}
proc set_alignment*(misc: PMisc, xalign: gfloat, yalign: gfloat){.cdecl,
    dynlib: lib, importc: "gtk_misc_set_alignment".}
proc get_alignment*(misc: PMisc, xalign, yalign: var Pgfloat){.cdecl,
    dynlib: lib, importc: "gtk_misc_get_alignment".}
proc set_padding*(misc: PMisc, xpad: gint, ypad: gint){.cdecl, dynlib: lib,
    importc: "gtk_misc_set_padding".}
proc get_padding*(misc: PMisc, xpad, ypad: var Pgint){.cdecl, dynlib: lib,
    importc: "gtk_misc_get_padding".}
const
  ACCEL_VISIBLE* = 1 shl 0
  ACCEL_LOCKED* = 1 shl 1
  ACCEL_MASK* = 0x00000007
  bm_TGtkAccelKey_accel_flags* = 0xFFFF'i16
  bp_TGtkAccelKey_accel_flags* = 0'i16

proc TYPE_ACCEL_GROUP*(): GType
proc ACCEL_GROUP*(anObject: pointer): PAccelGroup
proc ACCEL_GROUP_CLASS*(klass: pointer): PAccelGroupClass
proc IS_ACCEL_GROUP*(anObject: pointer): bool
proc IS_ACCEL_GROUP_CLASS*(klass: pointer): bool
proc ACCEL_GROUP_GET_CLASS*(obj: pointer): PAccelGroupClass
proc accel_flags*(a: PAccelKey): guint
proc set_accel_flags*(a: PAccelKey, `accel_flags`: guint)
proc accel_group_get_type*(): GType{.cdecl, dynlib: lib,
                                     importc: "gtk_accel_group_get_type".}
proc accel_group_new*(): PAccelGroup{.cdecl, dynlib: lib,
                                      importc: "gtk_accel_group_new".}
proc lock*(accel_group: PAccelGroup){.cdecl, dynlib: lib,
    importc: "gtk_accel_group_lock".}
proc unlock*(accel_group: PAccelGroup){.cdecl, dynlib: lib,
    importc: "gtk_accel_group_unlock".}
proc connect*(accel_group: PAccelGroup, accel_key: guint,
                          accel_mods: gdk2.TModifierType,
                          accel_flags: TAccelFlags, closure: PGClosure){.cdecl,
    dynlib: lib, importc: "gtk_accel_group_connect".}
proc connect_by_path*(accel_group: PAccelGroup, accel_path: cstring,
                                  closure: PGClosure){.cdecl, dynlib: lib,
    importc: "gtk_accel_group_connect_by_path".}
proc disconnect*(accel_group: PAccelGroup, closure: PGClosure): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_accel_group_disconnect".}
proc disconnect_key*(accel_group: PAccelGroup, accel_key: guint,
                                 accel_mods: gdk2.TModifierType): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_accel_group_disconnect_key".}
proc attach*(accel_group: PAccelGroup, anObject: PGObject){.cdecl,
    dynlib: lib, importc: "_gtk_accel_group_attach".}
proc detach*(accel_group: PAccelGroup, anObject: PGObject){.cdecl,
    dynlib: lib, importc: "_gtk_accel_group_detach".}
proc accel_groups_activate*(anObject: PGObject, accel_key: guint,
                            accel_mods: gdk2.TModifierType): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_accel_groups_activate".}
proc accel_groups_from_object*(anObject: PGObject): PGSList{.cdecl, dynlib: lib,
    importc: "gtk_accel_groups_from_object".}
proc find*(accel_group: PAccelGroup,
                       find_func: Taccel_group_find_func, data: gpointer): PAccelKey{.
    cdecl, dynlib: lib, importc: "gtk_accel_group_find".}
proc accel_group_from_accel_closure*(closure: PGClosure): PAccelGroup{.cdecl,
    dynlib: lib, importc: "gtk_accel_group_from_accel_closure".}
proc accelerator_valid*(keyval: guint, modifiers: gdk2.TModifierType): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_accelerator_valid".}
proc accelerator_parse*(accelerator: cstring, accelerator_key: Pguint,
                        accelerator_mods: gdk2.PModifierType){.cdecl, dynlib: lib,
    importc: "gtk_accelerator_parse".}
proc accelerator_name*(accelerator_key: guint,
                       accelerator_mods: gdk2.TModifierType): cstring{.cdecl,
    dynlib: lib, importc: "gtk_accelerator_name".}
proc accelerator_set_default_mod_mask*(default_mod_mask: gdk2.TModifierType){.
    cdecl, dynlib: lib, importc: "gtk_accelerator_set_default_mod_mask".}
proc accelerator_get_default_mod_mask*(): guint{.cdecl, dynlib: lib,
    importc: "gtk_accelerator_get_default_mod_mask".}
proc query*(accel_group: PAccelGroup, accel_key: guint,
                        accel_mods: gdk2.TModifierType, n_entries: Pguint): PAccelGroupEntry{.
    cdecl, dynlib: lib, importc: "gtk_accel_group_query".}
proc reconnect*(accel_group: PAccelGroup, accel_path_quark: TGQuark){.
    cdecl, dynlib: lib, importc: "_gtk_accel_group_reconnect".}
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

proc TYPE_CONTAINER*(): GType
proc CONTAINER*(obj: pointer): PContainer
proc CONTAINER_CLASS*(klass: pointer): PContainerClass
proc IS_CONTAINER*(obj: pointer): bool
proc IS_CONTAINER_CLASS*(klass: pointer): bool
proc CONTAINER_GET_CLASS*(obj: pointer): PContainerClass
proc IS_RESIZE_CONTAINER*(widget: pointer): bool
proc border_width*(a: PContainer): guint
proc need_resize*(a: PContainer): guint
proc set_need_resize*(a: PContainer, `need_resize`: guint)
proc resize_mode*(a: PContainer): guint
proc set_resize_mode*(a: PContainer, `resize_mode`: guint)
proc reallocate_redraws*(a: PContainer): guint
proc set_reallocate_redraws*(a: PContainer, `reallocate_redraws`: guint)
proc has_focus_chain*(a: PContainer): guint
proc set_has_focus_chain*(a: PContainer, `has_focus_chain`: guint)
proc container_get_type*(): TType{.cdecl, dynlib: lib,
                                   importc: "gtk_container_get_type".}
proc set_border_width*(container: PContainer, border_width: guint){.
    cdecl, dynlib: lib, importc: "gtk_container_set_border_width".}
proc get_border_width*(container: PContainer): guint{.cdecl,
    dynlib: lib, importc: "gtk_container_get_border_width".}
proc add*(container: PContainer, widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_container_add".}
proc remove*(container: PContainer, widget: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_container_remove".}
proc set_resize_mode*(container: PContainer, resize_mode: TResizeMode){.
    cdecl, dynlib: lib, importc: "gtk_container_set_resize_mode".}
proc get_resize_mode*(container: PContainer): TResizeMode{.cdecl,
    dynlib: lib, importc: "gtk_container_get_resize_mode".}
proc check_resize*(container: PContainer){.cdecl, dynlib: lib,
    importc: "gtk_container_check_resize".}
proc foreach*(container: PContainer, callback: TCallback,
                        callback_data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_container_foreach".}
proc get_children*(container: PContainer): PGList{.cdecl, dynlib: lib,
    importc: "gtk_container_get_children".}
proc propagate_expose*(container: PContainer, child: PWidget,
                                 event: gdk2.PEventExpose){.cdecl, dynlib: lib,
    importc: "gtk_container_propagate_expose".}
proc set_focus_chain*(container: PContainer, focusable_widgets: PGList){.
    cdecl, dynlib: lib, importc: "gtk_container_set_focus_chain".}
proc get_focus_chain*(container: PContainer, s: var PGList): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_container_get_focus_chain".}
proc unset_focus_chain*(container: PContainer){.cdecl, dynlib: lib,
    importc: "gtk_container_unset_focus_chain".}
proc set_reallocate_redraws*(container: PContainer,
                                       needs_redraws: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_container_set_reallocate_redraws".}
proc set_focus_child*(container: PContainer, child: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_container_set_focus_child".}
proc set_focus_vadjustment*(container: PContainer,
                                      adjustment: PAdjustment){.cdecl,
    dynlib: lib, importc: "gtk_container_set_focus_vadjustment".}
proc get_focus_vadjustment*(container: PContainer): PAdjustment{.
    cdecl, dynlib: lib, importc: "gtk_container_get_focus_vadjustment".}
proc set_focus_hadjustment*(container: PContainer,
                                      adjustment: PAdjustment){.cdecl,
    dynlib: lib, importc: "gtk_container_set_focus_hadjustment".}
proc get_focus_hadjustment*(container: PContainer): PAdjustment{.
    cdecl, dynlib: lib, importc: "gtk_container_get_focus_hadjustment".}
proc resize_children*(container: PContainer){.cdecl, dynlib: lib,
    importc: "gtk_container_resize_children".}
proc child_type*(container: PContainer): TType{.cdecl, dynlib: lib,
    importc: "gtk_container_child_type".}
proc install_child_property*(cclass: PContainerClass,
    property_id: guint, pspec: PGParamSpec){.cdecl, dynlib: lib,
    importc: "gtk_container_class_install_child_property".}
proc container_class_find_child_property*(cclass: PGObjectClass,
    property_name: cstring): PGParamSpec{.cdecl, dynlib: lib,
    importc: "gtk_container_class_find_child_property".}
proc container_class_list_child_properties*(cclass: PGObjectClass,
    n_properties: Pguint): PPGParamSpec{.cdecl, dynlib: lib,
    importc: "gtk_container_class_list_child_properties".}
proc child_set_property*(container: PContainer, child: PWidget,
                                   property_name: cstring, value: PGValue){.
    cdecl, dynlib: lib, importc: "gtk_container_child_set_property".}
proc child_get_property*(container: PContainer, child: PWidget,
                                   property_name: cstring, value: PGValue){.
    cdecl, dynlib: lib, importc: "gtk_container_child_get_property".}
proc CONTAINER_WARN_INVALID_CHILD_PROPERTY_ID*(anObject: pointer,
    property_id: guint, pspec: pointer)
proc forall*(container: PContainer, callback: TCallback,
                       callback_data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_container_forall".}
proc queue_resize*(container: PContainer){.cdecl, dynlib: lib,
    importc: "_gtk_container_queue_resize".}
proc clear_resize_widgets*(container: PContainer){.cdecl, dynlib: lib,
    importc: "_gtk_container_clear_resize_widgets".}
proc child_composite_name*(container: PContainer, child: PWidget): cstring{.
    cdecl, dynlib: lib, importc: "_gtk_container_child_composite_name".}
proc dequeue_resize_handler*(container: PContainer){.cdecl,
    dynlib: lib, importc: "_gtk_container_dequeue_resize_handler".}
proc focus_sort*(container: PContainer, children: PGList,
                           direction: TDirectionType, old_focus: PWidget): PGList{.
    cdecl, dynlib: lib, importc: "_gtk_container_focus_sort".}
proc TYPE_BIN*(): GType
proc BIN*(obj: pointer): PBin
proc BIN_CLASS*(klass: pointer): PBinClass
proc IS_BIN*(obj: pointer): bool
proc IS_BIN_CLASS*(klass: pointer): bool
proc BIN_GET_CLASS*(obj: pointer): PBinClass
proc bin_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_bin_get_type".}
proc get_child*(bin: PBin): PWidget{.cdecl, dynlib: lib,
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

proc TYPE_WINDOW*(): GType
proc WINDOW*(obj: pointer): PWindow
proc WINDOW_CLASS*(klass: pointer): PWindowClass
proc IS_WINDOW*(obj: pointer): bool
proc IS_WINDOW_CLASS*(klass: pointer): bool
proc WINDOW_GET_CLASS*(obj: pointer): PWindowClass
proc allow_shrink*(a: gtk2.PWindow): guint
proc set_allow_shrink*(a: gtk2.PWindow, `allow_shrink`: guint)
proc allow_grow*(a: gtk2.PWindow): guint
proc set_allow_grow*(a: gtk2.PWindow, `allow_grow`: guint)
proc configure_notify_received*(a: gtk2.PWindow): guint
proc set_configure_notify_received*(a: gtk2.PWindow,
                                    `configure_notify_received`: guint)
proc need_default_position*(a: gtk2.PWindow): guint
proc set_need_default_position*(a: gtk2.PWindow, `need_default_position`: guint)
proc need_default_size*(a: gtk2.PWindow): guint
proc set_need_default_size*(a: gtk2.PWindow, `need_default_size`: guint)
proc position*(a: gtk2.PWindow): guint
proc get_type*(a: gtk2.PWindow): guint
proc set_type*(a: gtk2.PWindow, `type`: guint)
proc has_user_ref_count*(a: gtk2.PWindow): guint
proc set_has_user_ref_count*(a: gtk2.PWindow, `has_user_ref_count`: guint)
proc has_focus*(a: gtk2.PWindow): guint
proc set_has_focus*(a: gtk2.PWindow, `has_focus`: guint)
proc modal*(a: gtk2.PWindow): guint
proc set_modal*(a: gtk2.PWindow, `modal`: guint)
proc destroy_with_parent*(a: gtk2.PWindow): guint
proc set_destroy_with_parent*(a: gtk2.PWindow, `destroy_with_parent`: guint)
proc has_frame*(a: gtk2.PWindow): guint
proc set_has_frame*(a: gtk2.PWindow, `has_frame`: guint)
proc iconify_initially*(a: gtk2.PWindow): guint
proc set_iconify_initially*(a: gtk2.PWindow, `iconify_initially`: guint)
proc stick_initially*(a: gtk2.PWindow): guint
proc set_stick_initially*(a: gtk2.PWindow, `stick_initially`: guint)
proc maximize_initially*(a: gtk2.PWindow): guint
proc set_maximize_initially*(a: gtk2.PWindow, `maximize_initially`: guint)
proc decorated*(a: gtk2.PWindow): guint
proc set_decorated*(a: gtk2.PWindow, `decorated`: guint)
proc type_hint*(a: gtk2.PWindow): guint
proc set_type_hint*(a: gtk2.PWindow, `type_hint`: guint)
proc gravity*(a: gtk2.PWindow): guint
proc set_gravity*(a: gtk2.PWindow, `gravity`: guint)
proc TYPE_WINDOW_GROUP*(): GType
proc WINDOW_GROUP*(anObject: pointer): PWindowGroup
proc WINDOW_GROUP_CLASS*(klass: pointer): PWindowGroupClass
proc IS_WINDOW_GROUP*(anObject: pointer): bool
proc IS_WINDOW_GROUP_CLASS*(klass: pointer): bool
proc WINDOW_GROUP_GET_CLASS*(obj: pointer): PWindowGroupClass
proc window_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_window_get_type".}
proc window_new*(thetype: TWindowType): PWindow{.cdecl, dynlib: lib,
    importc: "gtk_window_new".}
proc set_title*(window: PWindow, title: cstring){.cdecl, dynlib: lib,
    importc: "gtk_window_set_title".}
proc get_title*(window: PWindow): cstring{.cdecl, dynlib: lib,
    importc: "gtk_window_get_title".}
proc set_wmclass*(window: PWindow, wmclass_name: cstring,
                         wmclass_class: cstring){.cdecl, dynlib: lib,
    importc: "gtk_window_set_wmclass".}
proc set_role*(window: PWindow, role: cstring){.cdecl, dynlib: lib,
    importc: "gtk_window_set_role".}
proc get_role*(window: PWindow): cstring{.cdecl, dynlib: lib,
    importc: "gtk_window_get_role".}
proc add_accel_group*(window: PWindow, accel_group: PAccelGroup){.cdecl,
    dynlib: lib, importc: "gtk_window_add_accel_group".}
proc remove_accel_group*(window: PWindow, accel_group: PAccelGroup){.
    cdecl, dynlib: lib, importc: "gtk_window_remove_accel_group".}
proc set_position*(window: PWindow, position: TWindowPosition){.cdecl,
    dynlib: lib, importc: "gtk_window_set_position".}
proc activate_focus*(window: PWindow): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_window_activate_focus".}
proc set_focus*(window: PWindow, focus: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_window_set_focus".}
proc get_focus*(window: PWindow): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_window_get_focus".}
proc set_default*(window: PWindow, default_widget: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_window_set_default".}
proc activate_default*(window: PWindow): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_window_activate_default".}
proc set_transient_for*(window: PWindow, parent: PWindow){.cdecl,
    dynlib: lib, importc: "gtk_window_set_transient_for".}
proc get_transient_for*(window: PWindow): PWindow{.cdecl, dynlib: lib,
    importc: "gtk_window_get_transient_for".}
proc set_type_hint*(window: PWindow, hint: gdk2.TWindowTypeHint){.cdecl,
    dynlib: lib, importc: "gtk_window_set_type_hint".}
proc get_type_hint*(window: PWindow): gdk2.TWindowTypeHint{.cdecl,
    dynlib: lib, importc: "gtk_window_get_type_hint".}
proc set_destroy_with_parent*(window: PWindow, setting: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_window_set_destroy_with_parent".}
proc get_destroy_with_parent*(window: PWindow): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_window_get_destroy_with_parent".}
proc set_resizable*(window: PWindow, resizable: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_window_set_resizable".}
proc get_resizable*(window: PWindow): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_window_get_resizable".}
proc set_gravity*(window: PWindow, gravity: gdk2.TGravity){.cdecl,
    dynlib: lib, importc: "gtk_window_set_gravity".}
proc get_gravity*(window: PWindow): gdk2.TGravity{.cdecl, dynlib: lib,
    importc: "gtk_window_get_gravity".}
proc set_geometry_hints*(window: PWindow, geometry_widget: PWidget,
                                geometry: gdk2.PGeometry,
                                geom_mask: gdk2.TWindowHints){.cdecl, dynlib: lib,
    importc: "gtk_window_set_geometry_hints".}
proc set_screen*(window: PWindow, screen: gdk2.PScreen){.cdecl,
    dynlib: lib, importc: "gtk_window_set_screen".}
proc get_screen*(window: PWindow): gdk2.PScreen{.cdecl, dynlib: lib,
    importc: "gtk_window_get_screen".}
proc set_has_frame*(window: PWindow, setting: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_window_set_has_frame".}
proc get_has_frame*(window: PWindow): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_window_get_has_frame".}
proc set_frame_dimensions*(window: PWindow, left: gint, top: gint,
                                  right: gint, bottom: gint){.cdecl,
    dynlib: lib, importc: "gtk_window_set_frame_dimensions".}
proc get_frame_dimensions*(window: PWindow, left: Pgint, top: Pgint,
                                  right: Pgint, bottom: Pgint){.cdecl,
    dynlib: lib, importc: "gtk_window_get_frame_dimensions".}
proc set_decorated*(window: PWindow, setting: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_window_set_decorated".}
proc get_decorated*(window: PWindow): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_window_get_decorated".}
proc set_icon_list*(window: PWindow, list: PGList){.cdecl, dynlib: lib,
    importc: "gtk_window_set_icon_list".}
proc get_icon_list*(window: PWindow): PGList{.cdecl, dynlib: lib,
    importc: "gtk_window_get_icon_list".}
proc set_icon*(window: PWindow, icon: gdk2pixbuf.PPixbuf){.cdecl, dynlib: lib,
    importc: "gtk_window_set_icon".}
proc get_icon*(window: PWindow): gdk2pixbuf.PPixbuf{.cdecl, dynlib: lib,
    importc: "gtk_window_get_icon".}
proc window_set_default_icon_list*(list: PGList){.cdecl, dynlib: lib,
    importc: "gtk_window_set_default_icon_list".}
proc window_get_default_icon_list*(): PGList{.cdecl, dynlib: lib,
    importc: "gtk_window_get_default_icon_list".}
proc set_modal*(window: PWindow, modal: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_window_set_modal".}
proc get_modal*(window: PWindow): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_window_get_modal".}
proc window_list_toplevels*(): PGList{.cdecl, dynlib: lib,
                                       importc: "gtk_window_list_toplevels".}
proc add_mnemonic*(window: PWindow, keyval: guint, target: PWidget){.
    cdecl, dynlib: lib, importc: "gtk_window_add_mnemonic".}
proc remove_mnemonic*(window: PWindow, keyval: guint, target: PWidget){.
    cdecl, dynlib: lib, importc: "gtk_window_remove_mnemonic".}
proc mnemonic_activate*(window: PWindow, keyval: guint,
                               modifier: gdk2.TModifierType): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_window_mnemonic_activate".}
proc set_mnemonic_modifier*(window: PWindow, modifier: gdk2.TModifierType){.
    cdecl, dynlib: lib, importc: "gtk_window_set_mnemonic_modifier".}
proc get_mnemonic_modifier*(window: PWindow): gdk2.TModifierType{.cdecl,
    dynlib: lib, importc: "gtk_window_get_mnemonic_modifier".}
proc present*(window: PWindow){.cdecl, dynlib: lib,
                                       importc: "gtk_window_present".}
proc iconify*(window: PWindow){.cdecl, dynlib: lib,
                                       importc: "gtk_window_iconify".}
proc deiconify*(window: PWindow){.cdecl, dynlib: lib,
    importc: "gtk_window_deiconify".}
proc stick*(window: PWindow){.cdecl, dynlib: lib,
                                     importc: "gtk_window_stick".}
proc unstick*(window: PWindow){.cdecl, dynlib: lib,
                                       importc: "gtk_window_unstick".}
proc maximize*(window: PWindow){.cdecl, dynlib: lib,
                                        importc: "gtk_window_maximize".}
proc unmaximize*(window: PWindow){.cdecl, dynlib: lib,
    importc: "gtk_window_unmaximize".}
proc begin_resize_drag*(window: PWindow, edge: gdk2.TWindowEdge,
                               button: gint, root_x: gint, root_y: gint,
                               timestamp: guint32){.cdecl, dynlib: lib,
    importc: "gtk_window_begin_resize_drag".}
proc begin_move_drag*(window: PWindow, button: gint, root_x: gint,
                             root_y: gint, timestamp: guint32){.cdecl,
    dynlib: lib, importc: "gtk_window_begin_move_drag".}
proc set_default_size*(window: PWindow, width: gint, height: gint){.
    cdecl, dynlib: lib, importc: "gtk_window_set_default_size".}
proc get_default_size*(window: PWindow, width: Pgint, height: Pgint){.
    cdecl, dynlib: lib, importc: "gtk_window_get_default_size".}
proc resize*(window: PWindow, width: gint, height: gint){.cdecl,
    dynlib: lib, importc: "gtk_window_resize".}
proc get_size*(window: PWindow, width: Pgint, height: Pgint){.cdecl,
    dynlib: lib, importc: "gtk_window_get_size".}
proc move*(window: PWindow, x: gint, y: gint){.cdecl, dynlib: lib,
    importc: "gtk_window_move".}
proc get_position*(window: PWindow, root_x: Pgint, root_y: Pgint){.cdecl,
    dynlib: lib, importc: "gtk_window_get_position".}
proc parse_geometry*(window: PWindow, geometry: cstring): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_window_parse_geometry".}
proc reshow_with_initial_size*(window: PWindow){.cdecl, dynlib: lib,
    importc: "gtk_window_reshow_with_initial_size".}
proc window_group_get_type*(): GType{.cdecl, dynlib: lib,
                                      importc: "gtk_window_group_get_type".}
proc window_group_new*(): PWindowGroup{.cdecl, dynlib: lib,
                                        importc: "gtk_window_group_new".}
proc add_window*(window_group: PWindowGroup, window: PWindow){.
    cdecl, dynlib: lib, importc: "gtk_window_group_add_window".}
proc remove_window*(window_group: PWindowGroup, window: PWindow){.
    cdecl, dynlib: lib, importc: "gtk_window_group_remove_window".}
proc window_set_default_icon_name*(name: cstring){.cdecl, dynlib: lib,
    importc: "gtk_window_set_default_icon_name".}
proc internal_set_focus*(window: PWindow, focus: PWidget){.cdecl,
    dynlib: lib, importc: "_gtk_window_internal_set_focus".}
proc remove_embedded_xid*(window: PWindow, xid: guint){.cdecl,
    dynlib: lib, importc: "gtk_window_remove_embedded_xid".}
proc add_embedded_xid*(window: PWindow, xid: guint){.cdecl, dynlib: lib,
    importc: "gtk_window_add_embedded_xid".}
proc reposition*(window: PWindow, x: gint, y: gint){.cdecl, dynlib: lib,
    importc: "_gtk_window_reposition".}
proc constrain_size*(window: PWindow, width: gint, height: gint,
                            new_width: Pgint, new_height: Pgint){.cdecl,
    dynlib: lib, importc: "_gtk_window_constrain_size".}
proc get_group*(window: PWindow): PWindowGroup{.cdecl, dynlib: lib,
    importc: "_gtk_window_get_group".}
proc activate_key*(window: PWindow, event: gdk2.PEventKey): gboolean{.
    cdecl, dynlib: lib, importc: "_gtk_window_activate_key".}
proc keys_foreach*(window: PWindow, func: TWindowKeysForeachFunc,
                          func_data: gpointer){.cdecl, dynlib: lib,
    importc: "_gtk_window_keys_foreach".}
proc query_nonaccels*(window: PWindow, accel_key: guint,
                             accel_mods: gdk2.TModifierType): gboolean{.cdecl,
    dynlib: lib, importc: "_gtk_window_query_nonaccels".}
const
  bm_TGtkLabel_jtype* = 0x0003'i16
  bp_TGtkLabel_jtype* = 0'i16
  bm_TGtkLabel_wrap* = 0x0004'i16
  bp_TGtkLabel_wrap* = 2'i16
  bm_TGtkLabel_use_underline* = 0x0008'i16
  bp_TGtkLabel_use_underline* = 3'i16
  bm_TGtkLabel_use_markup* = 0x0010'i16
  bp_TGtkLabel_use_markup* = 4'i16

proc TYPE_LABEL*(): GType
proc LABEL*(obj: pointer): PLabel
proc LABEL_CLASS*(klass: pointer): PLabelClass
proc IS_LABEL*(obj: pointer): bool
proc IS_LABEL_CLASS*(klass: pointer): bool
proc LABEL_GET_CLASS*(obj: pointer): PLabelClass
proc jtype*(a: PLabel): guint
proc set_jtype*(a: PLabel, `jtype`: guint)
proc wrap*(a: PLabel): guint
proc set_wrap*(a: PLabel, `wrap`: guint)
proc use_underline*(a: PLabel): guint
proc set_use_underline*(a: PLabel, `use_underline`: guint)
proc use_markup*(a: PLabel): guint
proc set_use_markup*(a: PLabel, `use_markup`: guint)
proc label_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_label_get_type".}
proc label_new*(str: cstring): PLabel{.cdecl, dynlib: lib,
                                       importc: "gtk_label_new".}
proc label_new_with_mnemonic*(str: cstring): PLabel{.cdecl, dynlib: lib,
    importc: "gtk_label_new_with_mnemonic".}
proc set_text*(`label`: PLabel, str: cstring){.cdecl, dynlib: lib,
    importc: "gtk_label_set_text".}
proc get_text*(`label`: PLabel): cstring{.cdecl, dynlib: lib,
    importc: "gtk_label_get_text".}
proc set_attributes*(`label`: PLabel, attrs: pango.PAttrList){.cdecl,
    dynlib: lib, importc: "gtk_label_set_attributes".}
proc get_attributes*(`label`: PLabel): pango.PAttrList{.cdecl, dynlib: lib,
    importc: "gtk_label_get_attributes".}
proc set_label*(`label`: PLabel, str: cstring){.cdecl, dynlib: lib,
    importc: "gtk_label_set_label".}
proc get_label*(`label`: PLabel): cstring{.cdecl, dynlib: lib,
    importc: "gtk_label_get_label".}
proc set_markup*(`label`: PLabel, str: cstring){.cdecl, dynlib: lib,
    importc: "gtk_label_set_markup".}
proc set_use_markup*(`label`: PLabel, setting: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_label_set_use_markup".}
proc get_use_markup*(`label`: PLabel): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_label_get_use_markup".}
proc set_use_underline*(`label`: PLabel, setting: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_label_set_use_underline".}
proc get_use_underline*(`label`: PLabel): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_label_get_use_underline".}
proc set_markup_with_mnemonic*(`label`: PLabel, str: cstring){.cdecl,
    dynlib: lib, importc: "gtk_label_set_markup_with_mnemonic".}
proc get_mnemonic_keyval*(`label`: PLabel): guint{.cdecl, dynlib: lib,
    importc: "gtk_label_get_mnemonic_keyval".}
proc set_mnemonic_widget*(`label`: PLabel, widget: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_label_set_mnemonic_widget".}
proc get_mnemonic_widget*(`label`: PLabel): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_label_get_mnemonic_widget".}
proc set_text_with_mnemonic*(`label`: PLabel, str: cstring){.cdecl,
    dynlib: lib, importc: "gtk_label_set_text_with_mnemonic".}
proc set_justify*(`label`: PLabel, jtype: TJustification){.cdecl,
    dynlib: lib, importc: "gtk_label_set_justify".}
proc get_justify*(`label`: PLabel): TJustification{.cdecl, dynlib: lib,
    importc: "gtk_label_get_justify".}
proc set_pattern*(`label`: PLabel, pattern: cstring){.cdecl, dynlib: lib,
    importc: "gtk_label_set_pattern".}
proc set_line_wrap*(`label`: PLabel, wrap: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_label_set_line_wrap".}
proc get_line_wrap*(`label`: PLabel): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_label_get_line_wrap".}
proc set_selectable*(`label`: PLabel, setting: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_label_set_selectable".}
proc get_selectable*(`label`: PLabel): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_label_get_selectable".}
proc select_region*(`label`: PLabel, start_offset: gint, end_offset: gint){.
    cdecl, dynlib: lib, importc: "gtk_label_select_region".}
proc get_selection_bounds*(`label`: PLabel, start: Pgint, theEnd: Pgint): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_label_get_selection_bounds".}
proc get_layout*(`label`: PLabel): pango.PLayout{.cdecl, dynlib: lib,
    importc: "gtk_label_get_layout".}
proc get_layout_offsets*(`label`: PLabel, x: Pgint, y: Pgint){.cdecl,
    dynlib: lib, importc: "gtk_label_get_layout_offsets".}
const
  bm_TGtkAccelLabelClass_latin1_to_char* = 0x0001'i16
  bp_TGtkAccelLabelClass_latin1_to_char* = 0'i16

proc TYPE_ACCEL_LABEL*(): GType
proc ACCEL_LABEL*(obj: pointer): PAccelLabel
proc ACCEL_LABEL_CLASS*(klass: pointer): PAccelLabelClass
proc IS_ACCEL_LABEL*(obj: pointer): bool
proc IS_ACCEL_LABEL_CLASS*(klass: pointer): bool
proc ACCEL_LABEL_GET_CLASS*(obj: pointer): PAccelLabelClass
proc latin1_to_char*(a: PAccelLabelClass): guint
proc set_latin1_to_char*(a: PAccelLabelClass, `latin1_to_char`: guint)
proc accel_label_get_type*(): TType{.cdecl, dynlib: lib,
                                     importc: "gtk_accel_label_get_type".}
proc accel_label_new*(`string`: cstring): PAccelLabel{.cdecl, dynlib: lib,
    importc: "gtk_accel_label_new".}
proc get_accel_widget*(accel_label: PAccelLabel): PWidget{.cdecl,
    dynlib: lib, importc: "gtk_accel_label_get_accel_widget".}
proc get_accel_width*(accel_label: PAccelLabel): guint{.cdecl,
    dynlib: lib, importc: "gtk_accel_label_get_accel_width".}
proc set_accel_widget*(accel_label: PAccelLabel,
                                   accel_widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_accel_label_set_accel_widget".}
proc set_accel_closure*(accel_label: PAccelLabel,
                                    accel_closure: PGClosure){.cdecl,
    dynlib: lib, importc: "gtk_accel_label_set_accel_closure".}
proc refetch*(accel_label: PAccelLabel): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_accel_label_refetch".}
proc accel_map_add_entry*(accel_path: cstring, accel_key: guint,
                          accel_mods: gdk2.TModifierType){.cdecl, dynlib: lib,
    importc: "gtk_accel_map_add_entry".}
proc accel_map_lookup_entry*(accel_path: cstring, key: PAccelKey): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_accel_map_lookup_entry".}
proc accel_map_change_entry*(accel_path: cstring, accel_key: guint,
                             accel_mods: gdk2.TModifierType, replace: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_accel_map_change_entry".}
proc accel_map_load*(file_name: cstring){.cdecl, dynlib: lib,
    importc: "gtk_accel_map_load".}
proc accel_map_save*(file_name: cstring){.cdecl, dynlib: lib,
    importc: "gtk_accel_map_save".}
proc accel_map_foreach*(data: gpointer, foreach_func: TAccelMapForeach){.cdecl,
    dynlib: lib, importc: "gtk_accel_map_foreach".}
proc accel_map_load_fd*(fd: gint){.cdecl, dynlib: lib,
                                   importc: "gtk_accel_map_load_fd".}
proc accel_map_load_scanner*(scanner: PGScanner){.cdecl, dynlib: lib,
    importc: "gtk_accel_map_load_scanner".}
proc accel_map_save_fd*(fd: gint){.cdecl, dynlib: lib,
                                   importc: "gtk_accel_map_save_fd".}
proc accel_map_add_filter*(filter_pattern: cstring){.cdecl, dynlib: lib,
    importc: "gtk_accel_map_add_filter".}
proc accel_map_foreach_unfiltered*(data: gpointer,
                                   foreach_func: TAccelMapForeach){.cdecl,
    dynlib: lib, importc: "gtk_accel_map_foreach_unfiltered".}
proc accel_map_init*(){.cdecl, dynlib: lib, importc: "_gtk_accel_map_init".}
proc accel_map_add_group*(accel_path: cstring, accel_group: PAccelGroup){.cdecl,
    dynlib: lib, importc: "_gtk_accel_map_add_group".}
proc accel_map_remove_group*(accel_path: cstring, accel_group: PAccelGroup){.
    cdecl, dynlib: lib, importc: "_gtk_accel_map_remove_group".}
proc accel_path_is_valid*(accel_path: cstring): gboolean{.cdecl, dynlib: lib,
    importc: "_gtk_accel_path_is_valid".}
proc TYPE_ACCESSIBLE*(): GType
proc ACCESSIBLE*(obj: pointer): PAccessible
proc ACCESSIBLE_CLASS*(klass: pointer): PAccessibleClass
proc IS_ACCESSIBLE*(obj: pointer): bool
proc IS_ACCESSIBLE_CLASS*(klass: pointer): bool
proc ACCESSIBLE_GET_CLASS*(obj: pointer): PAccessibleClass
proc accessible_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_accessible_get_type".}
proc connect_widget_destroyed*(accessible: PAccessible){.cdecl,
    dynlib: lib, importc: "gtk_accessible_connect_widget_destroyed".}
proc TYPE_ADJUSTMENT*(): GType
proc ADJUSTMENT*(obj: pointer): PAdjustment
proc ADJUSTMENT_CLASS*(klass: pointer): PAdjustmentClass
proc IS_ADJUSTMENT*(obj: pointer): bool
proc IS_ADJUSTMENT_CLASS*(klass: pointer): bool
proc ADJUSTMENT_GET_CLASS*(obj: pointer): PAdjustmentClass
proc adjustment_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_adjustment_get_type".}
proc adjustment_new*(value: gdouble, lower: gdouble, upper: gdouble,
                     step_increment: gdouble, page_increment: gdouble,
                     page_size: gdouble): PAdjustment{.cdecl, dynlib: lib,
    importc: "gtk_adjustment_new".}
proc changed*(adjustment: PAdjustment){.cdecl, dynlib: lib,
    importc: "gtk_adjustment_changed".}
proc value_changed*(adjustment: PAdjustment){.cdecl, dynlib: lib,
    importc: "gtk_adjustment_value_changed".}
proc clamp_page*(adjustment: PAdjustment, lower: gdouble,
                            upper: gdouble){.cdecl, dynlib: lib,
    importc: "gtk_adjustment_clamp_page".}
proc get_value*(adjustment: PAdjustment): gdouble{.cdecl,
    dynlib: lib, importc: "gtk_adjustment_get_value".}
proc set_value*(adjustment: PAdjustment, value: gdouble){.cdecl,
    dynlib: lib, importc: "gtk_adjustment_set_value".}
proc get_upper*(adjustment: PAdjustment): gdouble{.cdecl,
    dynlib: lib, importc: "gtk_adjustment_get_upper".}
proc get_page_size*(adjustment: PAdjustment): gdouble{.cdecl,
    dynlib: lib, importc: "gtk_adjustment_get_page_size".}
proc TYPE_ALIGNMENT*(): GType
proc ALIGNMENT*(obj: pointer): PAlignment
proc ALIGNMENT_CLASS*(klass: pointer): PAlignmentClass
proc IS_ALIGNMENT*(obj: pointer): bool
proc IS_ALIGNMENT_CLASS*(klass: pointer): bool
proc ALIGNMENT_GET_CLASS*(obj: pointer): PAlignmentClass
proc alignment_get_type*(): TType{.cdecl, dynlib: lib,
                                   importc: "gtk_alignment_get_type".}
proc alignment_new*(xalign: gfloat, yalign: gfloat, xscale: gfloat,
                    yscale: gfloat): PAlignment{.cdecl, dynlib: lib,
    importc: "gtk_alignment_new".}
proc set*(alignment: PAlignment, xalign: gfloat, yalign: gfloat,
                    xscale: gfloat, yscale: gfloat){.cdecl, dynlib: lib,
    importc: "gtk_alignment_set".}
proc TYPE_FRAME*(): GType
proc FRAME*(obj: pointer): PFrame
proc FRAME_CLASS*(klass: pointer): PFrameClass
proc IS_FRAME*(obj: pointer): bool
proc IS_FRAME_CLASS*(klass: pointer): bool
proc FRAME_GET_CLASS*(obj: pointer): PFrameClass
proc frame_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_frame_get_type".}
proc frame_new*(`label`: cstring): PFrame{.cdecl, dynlib: lib,
    importc: "gtk_frame_new".}
proc set_label*(frame: PFrame, `label`: cstring){.cdecl, dynlib: lib,
    importc: "gtk_frame_set_label".}
proc get_label*(frame: PFrame): cstring{.cdecl, dynlib: lib,
    importc: "gtk_frame_get_label".}
proc set_label_widget*(frame: PFrame, label_widget: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_frame_set_label_widget".}
proc get_label_widget*(frame: PFrame): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_frame_get_label_widget".}
proc set_label_align*(frame: PFrame, xalign: gfloat, yalign: gfloat){.
    cdecl, dynlib: lib, importc: "gtk_frame_set_label_align".}
proc get_label_align*(frame: PFrame, xalign: Pgfloat, yalign: Pgfloat){.
    cdecl, dynlib: lib, importc: "gtk_frame_get_label_align".}
proc set_shadow_type*(frame: PFrame, thetype: TShadowType){.cdecl,
    dynlib: lib, importc: "gtk_frame_set_shadow_type".}
proc get_shadow_type*(frame: PFrame): TShadowType{.cdecl, dynlib: lib,
    importc: "gtk_frame_get_shadow_type".}
proc TYPE_ASPECT_FRAME*(): GType
proc ASPECT_FRAME*(obj: pointer): PAspectFrame
proc ASPECT_FRAME_CLASS*(klass: pointer): PAspectFrameClass
proc IS_ASPECT_FRAME*(obj: pointer): bool
proc IS_ASPECT_FRAME_CLASS*(klass: pointer): bool
proc ASPECT_FRAME_GET_CLASS*(obj: pointer): PAspectFrameClass
proc aspect_frame_get_type*(): TType{.cdecl, dynlib: lib,
                                      importc: "gtk_aspect_frame_get_type".}
proc aspect_frame_new*(`label`: cstring, xalign: gfloat, yalign: gfloat,
                       ratio: gfloat, obey_child: gboolean): PAspectFrame{.
    cdecl, dynlib: lib, importc: "gtk_aspect_frame_new".}
proc set*(aspect_frame: PAspectFrame, xalign: gfloat,
                       yalign: gfloat, ratio: gfloat, obey_child: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_aspect_frame_set".}
proc TYPE_ARROW*(): GType
proc ARROW*(obj: pointer): PArrow
proc ARROW_CLASS*(klass: pointer): PArrowClass
proc IS_ARROW*(obj: pointer): bool
proc IS_ARROW_CLASS*(klass: pointer): bool
proc ARROW_GET_CLASS*(obj: pointer): PArrowClass
proc arrow_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_arrow_get_type".}
proc arrow_new*(arrow_type: TArrowType, shadow_type: TShadowType): PArrow{.
    cdecl, dynlib: lib, importc: "gtk_arrow_new".}
proc set*(arrow: PArrow, arrow_type: TArrowType, shadow_type: TShadowType){.
    cdecl, dynlib: lib, importc: "gtk_arrow_set".}
const
  bm_TGtkBindingSet_parsed* = 0x0001'i16
  bp_TGtkBindingSet_parsed* = 0'i16
  bm_TGtkBindingEntry_destroyed* = 0x0001'i16
  bp_TGtkBindingEntry_destroyed* = 0'i16
  bm_TGtkBindingEntry_in_emission* = 0x0002'i16
  bp_TGtkBindingEntry_in_emission* = 1'i16

proc entry_add*(binding_set: PBindingSet, keyval: guint,
                        modifiers: gdk2.TModifierType)
proc parsed*(a: PBindingSet): guint
proc set_parsed*(a: PBindingSet, `parsed`: guint)
proc destroyed*(a: PBindingEntry): guint
proc set_destroyed*(a: PBindingEntry, `destroyed`: guint)
proc in_emission*(a: PBindingEntry): guint
proc set_in_emission*(a: PBindingEntry, `in_emission`: guint)
proc binding_set_new*(set_name: cstring): PBindingSet{.cdecl, dynlib: lib,
    importc: "gtk_binding_set_new".}
proc binding_set_by_class*(object_class: gpointer): PBindingSet{.cdecl,
    dynlib: lib, importc: "gtk_binding_set_by_class".}
proc binding_set_find*(set_name: cstring): PBindingSet{.cdecl, dynlib: lib,
    importc: "gtk_binding_set_find".}
proc bindings_activate*(anObject: PObject, keyval: guint,
                        modifiers: gdk2.TModifierType): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_bindings_activate".}
proc activate*(binding_set: PBindingSet, keyval: guint,
                           modifiers: gdk2.TModifierType, anObject: PObject): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_binding_set_activate".}
proc entry_clear*(binding_set: PBindingSet, keyval: guint,
                          modifiers: gdk2.TModifierType){.cdecl, dynlib: lib,
    importc: "gtk_binding_entry_clear".}
proc add_path*(binding_set: PBindingSet, path_type: TPathType,
                           path_pattern: cstring, priority: TPathPriorityType){.
    cdecl, dynlib: lib, importc: "gtk_binding_set_add_path".}
proc entry_remove*(binding_set: PBindingSet, keyval: guint,
                           modifiers: gdk2.TModifierType){.cdecl, dynlib: lib,
    importc: "gtk_binding_entry_remove".}
proc entry_add_signall*(binding_set: PBindingSet, keyval: guint,
                                modifiers: gdk2.TModifierType,
                                signal_name: cstring, binding_args: PGSList){.
    cdecl, dynlib: lib, importc: "gtk_binding_entry_add_signall".}
proc binding_parse_binding*(scanner: PGScanner): guint{.cdecl, dynlib: lib,
    importc: "gtk_binding_parse_binding".}
proc bindings_activate_event*(anObject: PObject, event: gdk2.PEventKey): gboolean{.
    cdecl, dynlib: lib, importc: "_gtk_bindings_activate_event".}
proc binding_reset_parsed*(){.cdecl, dynlib: lib,
                              importc: "_gtk_binding_reset_parsed".}
const
  bm_TGtkBox_homogeneous* = 0x0001'i16
  bp_TGtkBox_homogeneous* = 0'i16
  bm_TGtkBoxChild_expand* = 0x0001'i16
  bp_TGtkBoxChild_expand* = 0'i16
  bm_TGtkBoxChild_fill* = 0x0002'i16
  bp_TGtkBoxChild_fill* = 1'i16
  bm_TGtkBoxChild_pack* = 0x0004'i16
  bp_TGtkBoxChild_pack* = 2'i16
  bm_TGtkBoxChild_is_secondary* = 0x0008'i16
  bp_TGtkBoxChild_is_secondary* = 3'i16

proc TYPE_BOX*(): GType
proc BOX*(obj: pointer): PBox
proc BOX_CLASS*(klass: pointer): PBoxClass
proc IS_BOX*(obj: pointer): bool
proc IS_BOX_CLASS*(klass: pointer): bool
proc BOX_GET_CLASS*(obj: pointer): PBoxClass
proc homogeneous*(a: PBox): guint
proc set_homogeneous*(a: PBox, `homogeneous`: guint)
proc expand*(a: PBoxChild): guint
proc set_expand*(a: PBoxChild, `expand`: guint)
proc fill*(a: PBoxChild): guint
proc set_fill*(a: PBoxChild, `fill`: guint)
proc pack*(a: PBoxChild): guint
proc set_pack*(a: PBoxChild, `pack`: guint)
proc is_secondary*(a: PBoxChild): guint
proc set_is_secondary*(a: PBoxChild, `is_secondary`: guint)
proc box_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_box_get_type".}
proc pack_start*(box: PBox, child: PWidget, expand: gboolean,
                     fill: gboolean, padding: guint){.cdecl, dynlib: lib,
    importc: "gtk_box_pack_start".}
proc pack_end*(box: PBox, child: PWidget, expand: gboolean, fill: gboolean,
                   padding: guint){.cdecl, dynlib: lib,
                                    importc: "gtk_box_pack_end".}
proc pack_start_defaults*(box: PBox, widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_box_pack_start_defaults".}
proc pack_end_defaults*(box: PBox, widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_box_pack_end_defaults".}
proc set_homogeneous*(box: PBox, homogeneous: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_box_set_homogeneous".}
proc get_homogeneous*(box: PBox): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_box_get_homogeneous".}
proc set_spacing*(box: PBox, spacing: gint){.cdecl, dynlib: lib,
    importc: "gtk_box_set_spacing".}
proc get_spacing*(box: PBox): gint{.cdecl, dynlib: lib,
                                        importc: "gtk_box_get_spacing".}
proc reorder_child*(box: PBox, child: PWidget, position: gint){.cdecl,
    dynlib: lib, importc: "gtk_box_reorder_child".}
proc query_child_packing*(box: PBox, child: PWidget, expand: Pgboolean,
                              fill: Pgboolean, padding: Pguint,
                              pack_type: PPackType){.cdecl, dynlib: lib,
    importc: "gtk_box_query_child_packing".}
proc set_child_packing*(box: PBox, child: PWidget, expand: gboolean,
                            fill: gboolean, padding: guint, pack_type: TPackType){.
    cdecl, dynlib: lib, importc: "gtk_box_set_child_packing".}
const
  BUTTONBOX_DEFAULT* = - (1)

proc TYPE_BUTTON_BOX*(): GType
proc BUTTON_BOX*(obj: pointer): PButtonBox
proc BUTTON_BOX_CLASS*(klass: pointer): PButtonBoxClass
proc IS_BUTTON_BOX*(obj: pointer): bool
proc IS_BUTTON_BOX_CLASS*(klass: pointer): bool
proc BUTTON_BOX_GET_CLASS*(obj: pointer): PButtonBoxClass
proc button_box_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_button_box_get_type".}
proc get_layout*(widget: PButtonBox): TButtonBoxStyle{.cdecl,
    dynlib: lib, importc: "gtk_button_box_get_layout".}
proc set_layout*(widget: PButtonBox, layout_style: TButtonBoxStyle){.
    cdecl, dynlib: lib, importc: "gtk_button_box_set_layout".}
proc set_child_secondary*(widget: PButtonBox, child: PWidget,
                                     is_secondary: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_button_box_set_child_secondary".}
proc button_box_child_requisition*(widget: PWidget, nvis_children: var int32,
                                   nvis_secondaries: var int32,
                                   width: var int32, height: var int32){.cdecl,
    dynlib: lib, importc: "_gtk_button_box_child_requisition".}
const
  bm_TGtkButton_constructed* = 0x0001'i16
  bp_TGtkButton_constructed* = 0'i16
  bm_TGtkButton_in_button* = 0x0002'i16
  bp_TGtkButton_in_button* = 1'i16
  bm_TGtkButton_button_down* = 0x0004'i16
  bp_TGtkButton_button_down* = 2'i16
  bm_TGtkButton_relief* = 0x0018'i16
  bp_TGtkButton_relief* = 3'i16
  bm_TGtkButton_use_underline* = 0x0020'i16
  bp_TGtkButton_use_underline* = 5'i16
  bm_TGtkButton_use_stock* = 0x0040'i16
  bp_TGtkButton_use_stock* = 6'i16
  bm_TGtkButton_depressed* = 0x0080'i16
  bp_TGtkButton_depressed* = 7'i16
  bm_TGtkButton_depress_on_activate* = 0x0100'i16
  bp_TGtkButton_depress_on_activate* = 8'i16

proc TYPE_BUTTON*(): GType
proc BUTTON*(obj: pointer): PButton
proc BUTTON_CLASS*(klass: pointer): PButtonClass
proc IS_BUTTON*(obj: pointer): bool
proc IS_BUTTON_CLASS*(klass: pointer): bool
proc BUTTON_GET_CLASS*(obj: pointer): PButtonClass
proc constructed*(a: PButton): guint
proc set_constructed*(a: PButton, `constructed`: guint)
proc in_button*(a: PButton): guint
proc set_in_button*(a: PButton, `in_button`: guint)
proc button_down*(a: PButton): guint
proc set_button_down*(a: PButton, `button_down`: guint)
proc relief*(a: PButton): guint
proc use_underline*(a: PButton): guint
proc set_use_underline*(a: PButton, `use_underline`: guint)
proc use_stock*(a: PButton): guint
proc set_use_stock*(a: PButton, `use_stock`: guint)
proc depressed*(a: PButton): guint
proc set_depressed*(a: PButton, `depressed`: guint)
proc depress_on_activate*(a: PButton): guint
proc set_depress_on_activate*(a: PButton, `depress_on_activate`: guint)
proc button_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_button_get_type".}
proc button_new*(): PButton{.cdecl, dynlib: lib, importc: "gtk_button_new".}
proc button_new*(`label`: cstring): PButton{.cdecl, dynlib: lib,
    importc: "gtk_button_new_with_label".}
proc button_new_from_stock*(stock_id: cstring): PButton{.cdecl, dynlib: lib,
    importc: "gtk_button_new_from_stock".}
proc button_new_with_mnemonic*(`label`: cstring): PButton{.cdecl, dynlib: lib,
    importc: "gtk_button_new_with_mnemonic".}
proc pressed*(button: PButton){.cdecl, dynlib: lib,
                                       importc: "gtk_button_pressed".}
proc released*(button: PButton){.cdecl, dynlib: lib,
                                        importc: "gtk_button_released".}
proc clicked*(button: PButton){.cdecl, dynlib: lib,
                                       importc: "gtk_button_clicked".}
proc enter*(button: PButton){.cdecl, dynlib: lib,
                                     importc: "gtk_button_enter".}
proc leave*(button: PButton){.cdecl, dynlib: lib,
                                     importc: "gtk_button_leave".}
proc set_relief*(button: PButton, newstyle: TReliefStyle){.cdecl,
    dynlib: lib, importc: "gtk_button_set_relief".}
proc get_relief*(button: PButton): TReliefStyle{.cdecl, dynlib: lib,
    importc: "gtk_button_get_relief".}
proc set_label*(button: PButton, `label`: cstring){.cdecl, dynlib: lib,
    importc: "gtk_button_set_label".}
proc get_label*(button: PButton): cstring{.cdecl, dynlib: lib,
    importc: "gtk_button_get_label".}
proc set_use_underline*(button: PButton, use_underline: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_button_set_use_underline".}
proc get_use_underline*(button: PButton): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_button_get_use_underline".}
proc set_use_stock*(button: PButton, use_stock: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_button_set_use_stock".}
proc get_use_stock*(button: PButton): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_button_get_use_stock".}
proc set_depressed*(button: PButton, depressed: gboolean){.cdecl,
    dynlib: lib, importc: "_gtk_button_set_depressed".}
proc paint*(button: PButton, area: gdk2.PRectangle, state_type: TStateType,
                   shadow_type: TShadowType, main_detail: cstring,
                   default_detail: cstring){.cdecl, dynlib: lib,
    importc: "_gtk_button_paint".}
proc set_image*(button: PButton, image: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_button_set_image".}
proc get_image*(button: PButton): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_button_get_image".}
const
  CALENDAR_SHOW_HEADING* = 1 shl 0
  CALENDAR_SHOW_DAY_NAMES* = 1 shl 1
  CALENDAR_NO_MONTH_CHANGE* = 1 shl 2
  CALENDAR_SHOW_WEEK_NUMBERS* = 1 shl 3
  CALENDAR_WEEK_START_MONDAY* = 1 shl 4

proc TYPE_CALENDAR*(): GType
proc CALENDAR*(obj: pointer): PCalendar
proc CALENDAR_CLASS*(klass: pointer): PCalendarClass
proc IS_CALENDAR*(obj: pointer): bool
proc IS_CALENDAR_CLASS*(klass: pointer): bool
proc CALENDAR_GET_CLASS*(obj: pointer): PCalendarClass
proc calendar_get_type*(): TType{.cdecl, dynlib: lib,
                                  importc: "gtk_calendar_get_type".}
proc calendar_new*(): PCalendar{.cdecl, dynlib: lib, importc: "gtk_calendar_new".}
proc select_month*(calendar: PCalendar, month: guint, year: guint): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_calendar_select_month".}
proc select_day*(calendar: PCalendar, day: guint){.cdecl, dynlib: lib,
    importc: "gtk_calendar_select_day".}
proc mark_day*(calendar: PCalendar, day: guint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_calendar_mark_day".}
proc unmark_day*(calendar: PCalendar, day: guint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_calendar_unmark_day".}
proc clear_marks*(calendar: PCalendar){.cdecl, dynlib: lib,
    importc: "gtk_calendar_clear_marks".}
proc display_options*(calendar: PCalendar,
                               flags: TCalendarDisplayOptions){.cdecl,
    dynlib: lib, importc: "gtk_calendar_display_options".}
proc get_date*(calendar: PCalendar, year: Pguint, month: Pguint,
                        day: Pguint){.cdecl, dynlib: lib,
                                      importc: "gtk_calendar_get_date".}
proc freeze*(calendar: PCalendar){.cdecl, dynlib: lib,
    importc: "gtk_calendar_freeze".}
proc thaw*(calendar: PCalendar){.cdecl, dynlib: lib,
    importc: "gtk_calendar_thaw".}
proc TYPE_CELL_EDITABLE*(): GType
proc CELL_EDITABLE*(obj: pointer): PCellEditable
proc CELL_EDITABLE_CLASS*(obj: pointer): PCellEditableIface
proc IS_CELL_EDITABLE*(obj: pointer): bool
proc CELL_EDITABLE_GET_IFACE*(obj: pointer): PCellEditableIface
proc cell_editable_get_type*(): GType{.cdecl, dynlib: lib,
                                       importc: "gtk_cell_editable_get_type".}
proc start_editing*(cell_editable: PCellEditable, event: gdk2.PEvent){.
    cdecl, dynlib: lib, importc: "gtk_cell_editable_start_editing".}
proc editing_done*(cell_editable: PCellEditable){.cdecl,
    dynlib: lib, importc: "gtk_cell_editable_editing_done".}
proc remove_widget*(cell_editable: PCellEditable){.cdecl,
    dynlib: lib, importc: "gtk_cell_editable_remove_widget".}
const
  CELL_RENDERER_SELECTED* = 1 shl 0
  CELL_RENDERER_PRELIT* = 1 shl 1
  CELL_RENDERER_INSENSITIVE* = 1 shl 2
  CELL_RENDERER_SORTED* = 1 shl 3

const
  bm_TGtkCellRenderer_mode* = 0x0003'i16
  bp_TGtkCellRenderer_mode* = 0'i16
  bm_TGtkCellRenderer_visible* = 0x0004'i16
  bp_TGtkCellRenderer_visible* = 2'i16
  bm_TGtkCellRenderer_is_expander* = 0x0008'i16
  bp_TGtkCellRenderer_is_expander* = 3'i16
  bm_TGtkCellRenderer_is_expanded* = 0x0010'i16
  bp_TGtkCellRenderer_is_expanded* = 4'i16
  bm_TGtkCellRenderer_cell_background_set* = 0x0020'i16
  bp_TGtkCellRenderer_cell_background_set* = 5'i16

proc TYPE_CELL_RENDERER*(): GType
proc CELL_RENDERER*(obj: pointer): PCellRenderer
proc CELL_RENDERER_CLASS*(klass: pointer): PCellRendererClass
proc IS_CELL_RENDERER*(obj: pointer): bool
proc IS_CELL_RENDERER_CLASS*(klass: pointer): bool
proc CELL_RENDERER_GET_CLASS*(obj: pointer): PCellRendererClass
proc mode*(a: PCellRenderer): guint
proc set_mode*(a: PCellRenderer, `mode`: guint)
proc visible*(a: PCellRenderer): guint
proc set_visible*(a: PCellRenderer, `visible`: guint)
proc is_expander*(a: PCellRenderer): guint
proc set_is_expander*(a: PCellRenderer, `is_expander`: guint)
proc is_expanded*(a: PCellRenderer): guint
proc set_is_expanded*(a: PCellRenderer, `is_expanded`: guint)
proc cell_background_set*(a: PCellRenderer): guint
proc set_cell_background_set*(a: PCellRenderer, `cell_background_set`: guint)
proc cell_renderer_get_type*(): GType{.cdecl, dynlib: lib,
                                       importc: "gtk_cell_renderer_get_type".}
proc get_size*(cell: PCellRenderer, widget: PWidget,
                             cell_area: gdk2.PRectangle, x_offset: Pgint,
                             y_offset: Pgint, width: Pgint, height: Pgint){.
    cdecl, dynlib: lib, importc: "gtk_cell_renderer_get_size".}
proc render*(cell: PCellRenderer, window: gdk2.PWindow,
                           widget: PWidget, background_area: gdk2.PRectangle,
                           cell_area: gdk2.PRectangle, expose_area: gdk2.PRectangle,
                           flags: TCellRendererState){.cdecl, dynlib: lib,
    importc: "gtk_cell_renderer_render".}
proc activate*(cell: PCellRenderer, event: gdk2.PEvent,
                             widget: PWidget, path: cstring,
                             background_area: gdk2.PRectangle,
                             cell_area: gdk2.PRectangle, flags: TCellRendererState): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_cell_renderer_activate".}
proc start_editing*(cell: PCellRenderer, event: gdk2.PEvent,
                                  widget: PWidget, path: cstring,
                                  background_area: gdk2.PRectangle,
                                  cell_area: gdk2.PRectangle,
                                  flags: TCellRendererState): PCellEditable{.
    cdecl, dynlib: lib, importc: "gtk_cell_renderer_start_editing".}
proc set_fixed_size*(cell: PCellRenderer, width: gint,
                                   height: gint){.cdecl, dynlib: lib,
    importc: "gtk_cell_renderer_set_fixed_size".}
proc get_fixed_size*(cell: PCellRenderer, width: Pgint,
                                   height: Pgint){.cdecl, dynlib: lib,
    importc: "gtk_cell_renderer_get_fixed_size".}
const
  bm_TGtkCellRendererText_strikethrough* = 0x0001'i16
  bp_TGtkCellRendererText_strikethrough* = 0'i16
  bm_TGtkCellRendererText_editable* = 0x0002'i16
  bp_TGtkCellRendererText_editable* = 1'i16
  bm_TGtkCellRendererText_scale_set* = 0x0004'i16
  bp_TGtkCellRendererText_scale_set* = 2'i16
  bm_TGtkCellRendererText_foreground_set* = 0x0008'i16
  bp_TGtkCellRendererText_foreground_set* = 3'i16
  bm_TGtkCellRendererText_background_set* = 0x0010'i16
  bp_TGtkCellRendererText_background_set* = 4'i16
  bm_TGtkCellRendererText_underline_set* = 0x0020'i16
  bp_TGtkCellRendererText_underline_set* = 5'i16
  bm_TGtkCellRendererText_rise_set* = 0x0040'i16
  bp_TGtkCellRendererText_rise_set* = 6'i16
  bm_TGtkCellRendererText_strikethrough_set* = 0x0080'i16
  bp_TGtkCellRendererText_strikethrough_set* = 7'i16
  bm_TGtkCellRendererText_editable_set* = 0x0100'i16
  bp_TGtkCellRendererText_editable_set* = 8'i16
  bm_TGtkCellRendererText_calc_fixed_height* = 0x0200'i16
  bp_TGtkCellRendererText_calc_fixed_height* = 9'i16

proc TYPE_CELL_RENDERER_TEXT*(): GType
proc CELL_RENDERER_TEXT*(obj: pointer): PCellRendererText
proc CELL_RENDERER_TEXT_CLASS*(klass: pointer): PCellRendererTextClass
proc IS_CELL_RENDERER_TEXT*(obj: pointer): bool
proc IS_CELL_RENDERER_TEXT_CLASS*(klass: pointer): bool
proc CELL_RENDERER_TEXT_GET_CLASS*(obj: pointer): PCellRendererTextClass
proc strikethrough*(a: PCellRendererText): guint
proc set_strikethrough*(a: PCellRendererText, `strikethrough`: guint)
proc editable*(a: PCellRendererText): guint
proc set_editable*(a: PCellRendererText, `editable`: guint)
proc scale_set*(a: PCellRendererText): guint
proc set_scale_set*(a: PCellRendererText, `scale_set`: guint)
proc foreground_set*(a: PCellRendererText): guint
proc set_foreground_set*(a: PCellRendererText, `foreground_set`: guint)
proc background_set*(a: PCellRendererText): guint
proc set_background_set*(a: PCellRendererText, `background_set`: guint)
proc underline_set*(a: PCellRendererText): guint
proc set_underline_set*(a: PCellRendererText, `underline_set`: guint)
proc rise_set*(a: PCellRendererText): guint
proc set_rise_set*(a: PCellRendererText, `rise_set`: guint)
proc strikethrough_set*(a: PCellRendererText): guint
proc set_strikethrough_set*(a: PCellRendererText, `strikethrough_set`: guint)
proc editable_set*(a: PCellRendererText): guint
proc set_editable_set*(a: PCellRendererText, `editable_set`: guint)
proc calc_fixed_height*(a: PCellRendererText): guint
proc set_calc_fixed_height*(a: PCellRendererText, `calc_fixed_height`: guint)
proc cell_renderer_text_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_cell_renderer_text_get_type".}
proc cell_renderer_text_new*(): PCellRenderer{.cdecl, dynlib: lib,
    importc: "gtk_cell_renderer_text_new".}
proc text_set_fixed_height_from_font*(renderer: PCellRendererText,
    number_of_rows: gint){.cdecl, dynlib: lib, importc: "gtk_cell_renderer_text_set_fixed_height_from_font".}
const
  bm_TGtkCellRendererToggle_active* = 0x0001'i16
  bp_TGtkCellRendererToggle_active* = 0'i16
  bm_TGtkCellRendererToggle_activatable* = 0x0002'i16
  bp_TGtkCellRendererToggle_activatable* = 1'i16
  bm_TGtkCellRendererToggle_radio* = 0x0004'i16
  bp_TGtkCellRendererToggle_radio* = 2'i16

proc TYPE_CELL_RENDERER_TOGGLE*(): GType
proc CELL_RENDERER_TOGGLE*(obj: pointer): PCellRendererToggle
proc CELL_RENDERER_TOGGLE_CLASS*(klass: pointer): PCellRendererToggleClass
proc IS_CELL_RENDERER_TOGGLE*(obj: pointer): bool
proc IS_CELL_RENDERER_TOGGLE_CLASS*(klass: pointer): bool
proc CELL_RENDERER_TOGGLE_GET_CLASS*(obj: pointer): PCellRendererToggleClass
proc active*(a: PCellRendererToggle): guint
proc set_active*(a: PCellRendererToggle, `active`: guint)
proc activatable*(a: PCellRendererToggle): guint
proc set_activatable*(a: PCellRendererToggle, `activatable`: guint)
proc radio*(a: PCellRendererToggle): guint
proc set_radio*(a: PCellRendererToggle, `radio`: guint)
proc cell_renderer_toggle_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_cell_renderer_toggle_get_type".}
proc cell_renderer_toggle_new*(): PCellRenderer{.cdecl, dynlib: lib,
    importc: "gtk_cell_renderer_toggle_new".}
proc toggle_get_radio*(toggle: PCellRendererToggle): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_cell_renderer_toggle_get_radio".}
proc toggle_set_radio*(toggle: PCellRendererToggle,
                                     radio: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_cell_renderer_toggle_set_radio".}
proc toggle_get_active*(toggle: PCellRendererToggle): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_cell_renderer_toggle_get_active".}
proc toggle_set_active*(toggle: PCellRendererToggle,
                                      setting: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_cell_renderer_toggle_set_active".}
proc TYPE_CELL_RENDERER_PIXBUF*(): GType
proc CELL_RENDERER_PIXBUF*(obj: pointer): PCellRendererPixbuf
proc CELL_RENDERER_PIXBUF_CLASS*(klass: pointer): PCellRendererPixbufClass
proc IS_CELL_RENDERER_PIXBUF*(obj: pointer): bool
proc IS_CELL_RENDERER_PIXBUF_CLASS*(klass: pointer): bool
proc CELL_RENDERER_PIXBUF_GET_CLASS*(obj: pointer): PCellRendererPixbufClass
proc cell_renderer_pixbuf_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_cell_renderer_pixbuf_get_type".}
proc cell_renderer_pixbuf_new*(): PCellRenderer{.cdecl, dynlib: lib,
    importc: "gtk_cell_renderer_pixbuf_new".}
proc TYPE_ITEM*(): GType
proc ITEM*(obj: pointer): PItem
proc ITEM_CLASS*(klass: pointer): PItemClass
proc IS_ITEM*(obj: pointer): bool
proc IS_ITEM_CLASS*(klass: pointer): bool
proc ITEM_GET_CLASS*(obj: pointer): PItemClass
proc item_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_item_get_type".}
proc select*(item: PItem){.cdecl, dynlib: lib, importc: "gtk_item_select".}
proc deselect*(item: PItem){.cdecl, dynlib: lib,
                                  importc: "gtk_item_deselect".}
proc toggle*(item: PItem){.cdecl, dynlib: lib, importc: "gtk_item_toggle".}
const
  bm_TGtkMenuItem_show_submenu_indicator* = 0x0001'i16
  bp_TGtkMenuItem_show_submenu_indicator* = 0'i16
  bm_TGtkMenuItem_submenu_placement* = 0x0002'i16
  bp_TGtkMenuItem_submenu_placement* = 1'i16
  bm_TGtkMenuItem_submenu_direction* = 0x0004'i16
  bp_TGtkMenuItem_submenu_direction* = 2'i16
  bm_TGtkMenuItem_right_justify* = 0x0008'i16
  bp_TGtkMenuItem_right_justify* = 3'i16
  bm_TGtkMenuItem_timer_from_keypress* = 0x0010'i16
  bp_TGtkMenuItem_timer_from_keypress* = 4'i16
  bm_TGtkMenuItemClass_hide_on_activate* = 0x0001'i16
  bp_TGtkMenuItemClass_hide_on_activate* = 0'i16

proc TYPE_MENU_ITEM*(): GType
proc MENU_ITEM*(obj: pointer): PMenuItem
proc MENU_ITEM_CLASS*(klass: pointer): PMenuItemClass
proc IS_MENU_ITEM*(obj: pointer): bool
proc IS_MENU_ITEM_CLASS*(klass: pointer): bool
proc MENU_ITEM_GET_CLASS*(obj: pointer): PMenuItemClass
proc show_submenu_indicator*(a: PMenuItem): guint
proc set_show_submenu_indicator*(a: PMenuItem,
                                 `show_submenu_indicator`: guint)
proc submenu_placement*(a: PMenuItem): guint
proc set_submenu_placement*(a: PMenuItem, `submenu_placement`: guint)
proc submenu_direction*(a: PMenuItem): guint
proc set_submenu_direction*(a: PMenuItem, `submenu_direction`: guint)
proc right_justify*(a: PMenuItem): guint
proc set_right_justify*(a: PMenuItem, `right_justify`: guint)
proc timer_from_keypress*(a: PMenuItem): guint
proc set_timer_from_keypress*(a: PMenuItem, `timer_from_keypress`: guint)
proc hide_on_activate*(a: PMenuItemClass): guint
proc set_hide_on_activate*(a: PMenuItemClass, `hide_on_activate`: guint)
proc menu_item_get_type*(): TType{.cdecl, dynlib: lib,
                                   importc: "gtk_menu_item_get_type".}
proc menu_item_new*(): PMenuItem{.cdecl, dynlib: lib,
                                  importc: "gtk_menu_item_new".}
proc menu_item_new*(`label`: cstring): PMenuItem{.cdecl, dynlib: lib,
    importc: "gtk_menu_item_new_with_label".}
proc menu_item_new_with_mnemonic*(`label`: cstring): PMenuItem{.cdecl,
    dynlib: lib, importc: "gtk_menu_item_new_with_mnemonic".}
proc set_submenu*(menu_item: PMenuItem, submenu: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_menu_item_set_submenu".}
proc get_submenu*(menu_item: PMenuItem): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_menu_item_get_submenu".}
proc remove_submenu*(menu_item: PMenuItem){.cdecl, dynlib: lib,
    importc: "gtk_menu_item_remove_submenu".}
proc select*(menu_item: PMenuItem){.cdecl, dynlib: lib,
    importc: "gtk_menu_item_select".}
proc deselect*(menu_item: PMenuItem){.cdecl, dynlib: lib,
    importc: "gtk_menu_item_deselect".}
proc activate*(menu_item: PMenuItem){.cdecl, dynlib: lib,
    importc: "gtk_menu_item_activate".}
proc toggle_size_request*(menu_item: PMenuItem, requisition: Pgint){.
    cdecl, dynlib: lib, importc: "gtk_menu_item_toggle_size_request".}
proc toggle_size_allocate*(menu_item: PMenuItem, allocation: gint){.
    cdecl, dynlib: lib, importc: "gtk_menu_item_toggle_size_allocate".}
proc set_right_justified*(menu_item: PMenuItem,
                                    right_justified: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_menu_item_set_right_justified".}
proc get_right_justified*(menu_item: PMenuItem): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_menu_item_get_right_justified".}
proc set_accel_path*(menu_item: PMenuItem, accel_path: cstring){.
    cdecl, dynlib: lib, importc: "gtk_menu_item_set_accel_path".}
proc refresh_accel_path*(menu_item: PMenuItem, prefix: cstring,
                                   accel_group: PAccelGroup,
                                   group_changed: gboolean){.cdecl, dynlib: lib,
    importc: "_gtk_menu_item_refresh_accel_path".}
proc menu_item_is_selectable*(menu_item: PWidget): gboolean{.cdecl, dynlib: lib,
    importc: "_gtk_menu_item_is_selectable".}
const
  bm_TGtkToggleButton_active* = 0x0001'i16
  bp_TGtkToggleButton_active* = 0'i16
  bm_TGtkToggleButton_draw_indicator* = 0x0002'i16
  bp_TGtkToggleButton_draw_indicator* = 1'i16
  bm_TGtkToggleButton_inconsistent* = 0x0004'i16
  bp_TGtkToggleButton_inconsistent* = 2'i16

proc TYPE_TOGGLE_BUTTON*(): GType
proc TOGGLE_BUTTON*(obj: pointer): PToggleButton
proc TOGGLE_BUTTON_CLASS*(klass: pointer): PToggleButtonClass
proc IS_TOGGLE_BUTTON*(obj: pointer): bool
proc IS_TOGGLE_BUTTON_CLASS*(klass: pointer): bool
proc TOGGLE_BUTTON_GET_CLASS*(obj: pointer): PToggleButtonClass
proc active*(a: PToggleButton): guint
proc set_active*(a: PToggleButton, `active`: guint)
proc draw_indicator*(a: PToggleButton): guint
proc set_draw_indicator*(a: PToggleButton, `draw_indicator`: guint)
proc inconsistent*(a: PToggleButton): guint
proc set_inconsistent*(a: PToggleButton, `inconsistent`: guint)
proc toggle_button_get_type*(): TType{.cdecl, dynlib: lib,
                                       importc: "gtk_toggle_button_get_type".}
proc toggle_button_new*(): PToggleButton{.cdecl, dynlib: lib,
    importc: "gtk_toggle_button_new".}
proc toggle_button_new*(`label`: cstring): PToggleButton{.cdecl,
    dynlib: lib, importc: "gtk_toggle_button_new_with_label".}
proc toggle_button_new_with_mnemonic*(`label`: cstring): PToggleButton{.cdecl,
    dynlib: lib, importc: "gtk_toggle_button_new_with_mnemonic".}
proc set_mode*(toggle_button: PToggleButton,
                             draw_indicator: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_toggle_button_set_mode".}
proc get_mode*(toggle_button: PToggleButton): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_toggle_button_get_mode".}
proc set_active*(toggle_button: PToggleButton, is_active: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_toggle_button_set_active".}
proc get_active*(toggle_button: PToggleButton): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_toggle_button_get_active".}
proc toggled*(toggle_button: PToggleButton){.cdecl, dynlib: lib,
    importc: "gtk_toggle_button_toggled".}
proc set_inconsistent*(toggle_button: PToggleButton,
                                     setting: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_toggle_button_set_inconsistent".}
proc get_inconsistent*(toggle_button: PToggleButton): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_toggle_button_get_inconsistent".}
proc TYPE_CHECK_BUTTON*(): GType
proc CHECK_BUTTON*(obj: pointer): PCheckButton
proc CHECK_BUTTON_CLASS*(klass: pointer): PCheckButtonClass
proc IS_CHECK_BUTTON*(obj: pointer): bool
proc IS_CHECK_BUTTON_CLASS*(klass: pointer): bool
proc CHECK_BUTTON_GET_CLASS*(obj: pointer): PCheckButtonClass
proc check_button_get_type*(): TType{.cdecl, dynlib: lib,
                                      importc: "gtk_check_button_get_type".}
proc check_button_new*(): PCheckButton{.cdecl, dynlib: lib,
                                        importc: "gtk_check_button_new".}
proc check_button_new*(`label`: cstring): PCheckButton{.cdecl,
    dynlib: lib, importc: "gtk_check_button_new_with_label".}
proc check_button_new_with_mnemonic*(`label`: cstring): PCheckButton{.cdecl,
    dynlib: lib, importc: "gtk_check_button_new_with_mnemonic".}
proc get_props*(check_button: PCheckButton, indicator_size: Pgint,
                             indicator_spacing: Pgint){.cdecl, dynlib: lib,
    importc: "_gtk_check_button_get_props".}
const
  bm_TGtkCheckMenuItem_active* = 0x0001'i16
  bp_TGtkCheckMenuItem_active* = 0'i16
  bm_TGtkCheckMenuItem_always_show_toggle* = 0x0002'i16
  bp_TGtkCheckMenuItem_always_show_toggle* = 1'i16
  bm_TGtkCheckMenuItem_inconsistent* = 0x0004'i16
  bp_TGtkCheckMenuItem_inconsistent* = 2'i16

proc TYPE_CHECK_MENU_ITEM*(): GType
proc CHECK_MENU_ITEM*(obj: pointer): PCheckMenuItem
proc CHECK_MENU_ITEM_CLASS*(klass: pointer): PCheckMenuItemClass
proc IS_CHECK_MENU_ITEM*(obj: pointer): bool
proc IS_CHECK_MENU_ITEM_CLASS*(klass: pointer): bool
proc CHECK_MENU_ITEM_GET_CLASS*(obj: pointer): PCheckMenuItemClass
proc active*(a: PCheckMenuItem): guint
proc set_active*(a: PCheckMenuItem, `active`: guint)
proc always_show_toggle*(a: PCheckMenuItem): guint
proc set_always_show_toggle*(a: PCheckMenuItem, `always_show_toggle`: guint)
proc inconsistent*(a: PCheckMenuItem): guint
proc set_inconsistent*(a: PCheckMenuItem, `inconsistent`: guint)
proc check_menu_item_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_check_menu_item_get_type".}
proc check_menu_item_new*(): PCheckMenuItem{.cdecl, dynlib: lib,
                                      importc: "gtk_check_menu_item_new".}
proc check_menu_item_new*(`label`: cstring): PCheckMenuItem{.cdecl,
    dynlib: lib, importc: "gtk_check_menu_item_new_with_label".}
proc check_menu_item_new_with_mnemonic*(`label`: cstring): PCheckMenuItem{.cdecl,
    dynlib: lib, importc: "gtk_check_menu_item_new_with_mnemonic".}
proc item_set_active*(check_menu_item: PCheckMenuItem,
                                 is_active: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_check_menu_item_set_active".}
proc item_get_active*(check_menu_item: PCheckMenuItem): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_check_menu_item_get_active".}
proc item_toggled*(check_menu_item: PCheckMenuItem){.cdecl,
    dynlib: lib, importc: "gtk_check_menu_item_toggled".}
proc item_set_inconsistent*(check_menu_item: PCheckMenuItem,
                                       setting: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_check_menu_item_set_inconsistent".}
proc item_get_inconsistent*(check_menu_item: PCheckMenuItem): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_check_menu_item_get_inconsistent".}
proc clipboard_get_for_display*(display: gdk2.PDisplay, selection: gdk2.TAtom): PClipboard{.
    cdecl, dynlib: lib, importc: "gtk_clipboard_get_for_display".}
proc get_display*(clipboard: PClipboard): gdk2.PDisplay{.cdecl,
    dynlib: lib, importc: "gtk_clipboard_get_display".}
proc set_with_data*(clipboard: PClipboard, targets: PTargetEntry,
                              n_targets: guint, get_func: TClipboardGetFunc,
                              clear_func: TClipboardClearFunc,
                              user_data: gpointer): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_clipboard_set_with_data".}
proc set_with_owner*(clipboard: PClipboard, targets: PTargetEntry,
                               n_targets: guint, get_func: TClipboardGetFunc,
                               clear_func: TClipboardClearFunc, owner: PGObject): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_clipboard_set_with_owner".}
proc get_owner*(clipboard: PClipboard): PGObject{.cdecl, dynlib: lib,
    importc: "gtk_clipboard_get_owner".}
proc clear*(clipboard: PClipboard){.cdecl, dynlib: lib,
    importc: "gtk_clipboard_clear".}
proc set_text*(clipboard: PClipboard, text: cstring, len: gint){.
    cdecl, dynlib: lib, importc: "gtk_clipboard_set_text".}
proc request_contents*(clipboard: PClipboard, target: gdk2.TAtom,
                                 callback: TClipboardReceivedFunc,
                                 user_data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_clipboard_request_contents".}
proc request_text*(clipboard: PClipboard,
                             callback: TClipboardTextReceivedFunc,
                             user_data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_clipboard_request_text".}
proc wait_for_contents*(clipboard: PClipboard, target: gdk2.TAtom): PSelectionData{.
    cdecl, dynlib: lib, importc: "gtk_clipboard_wait_for_contents".}
proc wait_for_text*(clipboard: PClipboard): cstring{.cdecl,
    dynlib: lib, importc: "gtk_clipboard_wait_for_text".}
proc wait_is_text_available*(clipboard: PClipboard): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_clipboard_wait_is_text_available".}
const
  CLIST_IN_DRAG* = 1 shl 0
  CLIST_ROW_HEIGHT_SET* = 1 shl 1
  CLIST_SHOW_TITLES* = 1 shl 2
  CLIST_ADD_MODE* = 1 shl 4
  CLIST_AUTO_SORT* = 1 shl 5
  CLIST_AUTO_RESIZE_BLOCKED* = 1 shl 6
  CLIST_REORDERABLE* = 1 shl 7
  CLIST_USE_DRAG_ICONS* = 1 shl 8
  CLIST_DRAW_DRAG_LINE* = 1 shl 9
  CLIST_DRAW_DRAG_RECT* = 1 shl 10
  BUTTON_IGNORED* = 0
  BUTTON_SELECTS* = 1 shl 0
  BUTTON_DRAGS* = 1 shl 1
  BUTTON_EXPANDS* = 1 shl 2

const
  bm_TGtkCListColumn_visible* = 0x0001'i16
  bp_TGtkCListColumn_visible* = 0'i16
  bm_TGtkCListColumn_width_set* = 0x0002'i16
  bp_TGtkCListColumn_width_set* = 1'i16
  bm_TGtkCListColumn_resizeable* = 0x0004'i16
  bp_TGtkCListColumn_resizeable* = 2'i16
  bm_TGtkCListColumn_auto_resize* = 0x0008'i16
  bp_TGtkCListColumn_auto_resize* = 3'i16
  bm_TGtkCListColumn_button_passive* = 0x0010'i16
  bp_TGtkCListColumn_button_passive* = 4'i16
  bm_TGtkCListRow_fg_set* = 0x0001'i16
  bp_TGtkCListRow_fg_set* = 0'i16
  bm_TGtkCListRow_bg_set* = 0x0002'i16
  bp_TGtkCListRow_bg_set* = 1'i16
  bm_TGtkCListRow_selectable* = 0x0004'i16
  bp_TGtkCListRow_selectable* = 2'i16

proc TYPE_CLIST*(): GType
proc CLIST*(obj: pointer): PCList
proc CLIST_CLASS*(klass: pointer): PCListClass
proc IS_CLIST*(obj: pointer): bool
proc IS_CLIST_CLASS*(klass: pointer): bool
proc CLIST_GET_CLASS*(obj: pointer): PCListClass
proc CLIST_FLAGS*(clist: pointer): guint16
proc SET_FLAG*(clist: PCList, flag: guint16)
proc UNSET_FLAG*(clist: PCList, flag: guint16)
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

proc visible*(a: PCListColumn): guint
proc set_visible*(a: PCListColumn, `visible`: guint)
proc width_set*(a: PCListColumn): guint
proc set_width_set*(a: PCListColumn, `width_set`: guint)
proc resizeable*(a: PCListColumn): guint
proc set_resizeable*(a: PCListColumn, `resizeable`: guint)
proc auto_resize*(a: PCListColumn): guint
proc set_auto_resize*(a: PCListColumn, `auto_resize`: guint)
proc button_passive*(a: PCListColumn): guint
proc set_button_passive*(a: PCListColumn, `button_passive`: guint)
proc fg_set*(a: PCListRow): guint
proc set_fg_set*(a: PCListRow, `fg_set`: guint)
proc bg_set*(a: PCListRow): guint
proc set_bg_set*(a: PCListRow, `bg_set`: guint)
proc selectable*(a: PCListRow): guint
proc set_selectable*(a: PCListRow, `selectable`: guint)
proc clist_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_clist_get_type".}
proc clist_new*(columns: gint): PCList{.cdecl, dynlib: lib,
                                        importc: "gtk_clist_new".}
proc set_hadjustment*(clist: PCList, adjustment: PAdjustment){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_hadjustment".}
proc set_vadjustment*(clist: PCList, adjustment: PAdjustment){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_vadjustment".}
proc get_hadjustment*(clist: PCList): PAdjustment{.cdecl, dynlib: lib,
    importc: "gtk_clist_get_hadjustment".}
proc get_vadjustment*(clist: PCList): PAdjustment{.cdecl, dynlib: lib,
    importc: "gtk_clist_get_vadjustment".}
proc set_shadow_type*(clist: PCList, thetype: TShadowType){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_shadow_type".}
proc set_selection_mode*(clist: PCList, mode: TSelectionMode){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_selection_mode".}
proc set_reorderable*(clist: PCList, reorderable: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_reorderable".}
proc set_use_drag_icons*(clist: PCList, use_icons: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_use_drag_icons".}
proc set_button_actions*(clist: PCList, button: guint,
                               button_actions: guint8){.cdecl, dynlib: lib,
    importc: "gtk_clist_set_button_actions".}
proc freeze*(clist: PCList){.cdecl, dynlib: lib,
                                   importc: "gtk_clist_freeze".}
proc thaw*(clist: PCList){.cdecl, dynlib: lib, importc: "gtk_clist_thaw".}
proc column_titles_show*(clist: PCList){.cdecl, dynlib: lib,
    importc: "gtk_clist_column_titles_show".}
proc column_titles_hide*(clist: PCList){.cdecl, dynlib: lib,
    importc: "gtk_clist_column_titles_hide".}
proc column_title_active*(clist: PCList, column: gint){.cdecl,
    dynlib: lib, importc: "gtk_clist_column_title_active".}
proc column_title_passive*(clist: PCList, column: gint){.cdecl,
    dynlib: lib, importc: "gtk_clist_column_title_passive".}
proc column_titles_active*(clist: PCList){.cdecl, dynlib: lib,
    importc: "gtk_clist_column_titles_active".}
proc column_titles_passive*(clist: PCList){.cdecl, dynlib: lib,
    importc: "gtk_clist_column_titles_passive".}
proc set_column_title*(clist: PCList, column: gint, title: cstring){.
    cdecl, dynlib: lib, importc: "gtk_clist_set_column_title".}
proc get_column_title*(clist: PCList, column: gint): cstring{.cdecl,
    dynlib: lib, importc: "gtk_clist_get_column_title".}
proc set_column_widget*(clist: PCList, column: gint, widget: PWidget){.
    cdecl, dynlib: lib, importc: "gtk_clist_set_column_widget".}
proc get_column_widget*(clist: PCList, column: gint): PWidget{.cdecl,
    dynlib: lib, importc: "gtk_clist_get_column_widget".}
proc set_column_justification*(clist: PCList, column: gint,
                                     justification: TJustification){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_column_justification".}
proc set_column_visibility*(clist: PCList, column: gint, visible: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_clist_set_column_visibility".}
proc set_column_resizeable*(clist: PCList, column: gint,
                                  resizeable: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_clist_set_column_resizeable".}
proc set_column_auto_resize*(clist: PCList, column: gint,
                                   auto_resize: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_clist_set_column_auto_resize".}
proc columns_autosize*(clist: PCList): gint{.cdecl, dynlib: lib,
    importc: "gtk_clist_columns_autosize".}
proc optimal_column_width*(clist: PCList, column: gint): gint{.cdecl,
    dynlib: lib, importc: "gtk_clist_optimal_column_width".}
proc set_column_width*(clist: PCList, column: gint, width: gint){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_column_width".}
proc set_column_min_width*(clist: PCList, column: gint, min_width: gint){.
    cdecl, dynlib: lib, importc: "gtk_clist_set_column_min_width".}
proc set_column_max_width*(clist: PCList, column: gint, max_width: gint){.
    cdecl, dynlib: lib, importc: "gtk_clist_set_column_max_width".}
proc set_row_height*(clist: PCList, height: guint){.cdecl, dynlib: lib,
    importc: "gtk_clist_set_row_height".}
proc moveto*(clist: PCList, row: gint, column: gint, row_align: gfloat,
                   col_align: gfloat){.cdecl, dynlib: lib,
                                       importc: "gtk_clist_moveto".}
proc row_is_visible*(clist: PCList, row: gint): TVisibility{.cdecl,
    dynlib: lib, importc: "gtk_clist_row_is_visible".}
proc get_cell_type*(clist: PCList, row: gint, column: gint): TCellType{.
    cdecl, dynlib: lib, importc: "gtk_clist_get_cell_type".}
proc set_text*(clist: PCList, row: gint, column: gint, text: cstring){.
    cdecl, dynlib: lib, importc: "gtk_clist_set_text".}
proc get_text*(clist: PCList, row: gint, column: gint, text: PPgchar): gint{.
    cdecl, dynlib: lib, importc: "gtk_clist_get_text".}
proc set_pixmap*(clist: PCList, row: gint, column: gint,
                       pixmap: gdk2.PPixmap, mask: gdk2.PBitmap){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_pixmap".}
proc get_pixmap*(clist: PCList, row: gint, column: gint,
                       pixmap: var gdk2.PPixmap, mask: var gdk2.PBitmap): gint{.
    cdecl, dynlib: lib, importc: "gtk_clist_get_pixmap".}
proc set_pixtext*(clist: PCList, row: gint, column: gint, text: cstring,
                        spacing: guint8, pixmap: gdk2.PPixmap, mask: gdk2.PBitmap){.
    cdecl, dynlib: lib, importc: "gtk_clist_set_pixtext".}
proc set_foreground*(clist: PCList, row: gint, color: gdk2.PColor){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_foreground".}
proc set_background*(clist: PCList, row: gint, color: gdk2.PColor){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_background".}
proc set_cell_style*(clist: PCList, row: gint, column: gint, style: PStyle){.
    cdecl, dynlib: lib, importc: "gtk_clist_set_cell_style".}
proc get_cell_style*(clist: PCList, row: gint, column: gint): PStyle{.
    cdecl, dynlib: lib, importc: "gtk_clist_get_cell_style".}
proc set_row_style*(clist: PCList, row: gint, style: PStyle){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_row_style".}
proc get_row_style*(clist: PCList, row: gint): PStyle{.cdecl, dynlib: lib,
    importc: "gtk_clist_get_row_style".}
proc set_shift*(clist: PCList, row: gint, column: gint, vertical: gint,
                      horizontal: gint){.cdecl, dynlib: lib,
    importc: "gtk_clist_set_shift".}
proc set_selectable*(clist: PCList, row: gint, selectable: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_clist_set_selectable".}
proc get_selectable*(clist: PCList, row: gint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_clist_get_selectable".}
proc remove*(clist: PCList, row: gint){.cdecl, dynlib: lib,
    importc: "gtk_clist_remove".}
proc set_row_data*(clist: PCList, row: gint, data: gpointer){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_row_data".}
proc set_row_data_full*(clist: PCList, row: gint, data: gpointer,
                              destroy: TDestroyNotify){.cdecl, dynlib: lib,
    importc: "gtk_clist_set_row_data_full".}
proc get_row_data*(clist: PCList, row: gint): gpointer{.cdecl,
    dynlib: lib, importc: "gtk_clist_get_row_data".}
proc find_row_from_data*(clist: PCList, data: gpointer): gint{.cdecl,
    dynlib: lib, importc: "gtk_clist_find_row_from_data".}
proc select_row*(clist: PCList, row: gint, column: gint){.cdecl,
    dynlib: lib, importc: "gtk_clist_select_row".}
proc unselect_row*(clist: PCList, row: gint, column: gint){.cdecl,
    dynlib: lib, importc: "gtk_clist_unselect_row".}
proc undo_selection*(clist: PCList){.cdecl, dynlib: lib,
    importc: "gtk_clist_undo_selection".}
proc clear*(clist: PCList){.cdecl, dynlib: lib, importc: "gtk_clist_clear".}
proc get_selection_info*(clist: PCList, x: gint, y: gint, row: Pgint,
                               column: Pgint): gint{.cdecl, dynlib: lib,
    importc: "gtk_clist_get_selection_info".}
proc select_all*(clist: PCList){.cdecl, dynlib: lib,
                                       importc: "gtk_clist_select_all".}
proc unselect_all*(clist: PCList){.cdecl, dynlib: lib,
    importc: "gtk_clist_unselect_all".}
proc swap_rows*(clist: PCList, row1: gint, row2: gint){.cdecl,
    dynlib: lib, importc: "gtk_clist_swap_rows".}
proc row_move*(clist: PCList, source_row: gint, dest_row: gint){.cdecl,
    dynlib: lib, importc: "gtk_clist_row_move".}
proc set_compare_func*(clist: PCList, cmp_func: TCListCompareFunc){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_compare_func".}
proc set_sort_column*(clist: PCList, column: gint){.cdecl, dynlib: lib,
    importc: "gtk_clist_set_sort_column".}
proc set_sort_type*(clist: PCList, sort_type: TSortType){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_sort_type".}
proc sort*(clist: PCList){.cdecl, dynlib: lib, importc: "gtk_clist_sort".}
proc set_auto_sort*(clist: PCList, auto_sort: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_clist_set_auto_sort".}
proc create_cell_layout*(clist: PCList, clist_row: PCListRow, column: gint): pango.PLayout{.
    cdecl, dynlib: lib, importc: "_gtk_clist_create_cell_layout".}
const
  DIALOG_MODAL* = cint(1 shl 0)
  DIALOG_DESTROY_WITH_PARENT* = cint(1 shl 1)
  DIALOG_NO_SEPARATOR* = cint(1 shl 2)
  RESPONSE_NONE* = - cint(1)
  RESPONSE_REJECT* = - cint(2)
  RESPONSE_ACCEPT* = - cint(3)
  RESPONSE_DELETE_EVENT* = - cint(4)
  RESPONSE_OK* = - cint(5)
  RESPONSE_CANCEL* = cint(-6)
  RESPONSE_CLOSE* = - cint(7)
  RESPONSE_YES* = - cint(8)
  RESPONSE_NO* = - cint(9)
  RESPONSE_APPLY* = - cint(10)
  RESPONSE_HELP* = - cint(11)

proc TYPE_DIALOG*(): GType
proc DIALOG*(obj: pointer): PDialog
proc DIALOG_CLASS*(klass: pointer): PDialogClass
proc IS_DIALOG*(obj: pointer): bool
proc IS_DIALOG_CLASS*(klass: pointer): bool
proc DIALOG_GET_CLASS*(obj: pointer): PDialogClass
proc dialog_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_dialog_get_type".}
proc dialog_new*(): PDialog{.cdecl, dynlib: lib, importc: "gtk_dialog_new".}
proc add_action_widget*(dialog: PDialog, child: PWidget,
                               response_id: gint){.cdecl, dynlib: lib,
    importc: "gtk_dialog_add_action_widget".}
proc add_button*(dialog: PDialog, button_text: cstring, response_id: gint): PWidget{.
    cdecl, dynlib: lib, importc: "gtk_dialog_add_button".}
proc set_response_sensitive*(dialog: PDialog, response_id: gint,
                                    setting: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_dialog_set_response_sensitive".}
proc set_default_response*(dialog: PDialog, response_id: gint){.cdecl,
    dynlib: lib, importc: "gtk_dialog_set_default_response".}
proc set_has_separator*(dialog: PDialog, setting: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_dialog_set_has_separator".}
proc get_has_separator*(dialog: PDialog): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_dialog_get_has_separator".}
proc response*(dialog: PDialog, response_id: gint){.cdecl, dynlib: lib,
    importc: "gtk_dialog_response".}
proc run*(dialog: PDialog): gint{.cdecl, dynlib: lib,
    importc: "gtk_dialog_run".}
proc show_about_dialog*(parent: PWindow, firstPropertyName: cstring){.cdecl,
    dynlib: lib, importc: "gtk_show_about_dialog", varargs.}
proc TYPE_VBOX*(): GType
proc VBOX*(obj: pointer): PVBox
proc VBOX_CLASS*(klass: pointer): PVBoxClass
proc IS_VBOX*(obj: pointer): bool
proc IS_VBOX_CLASS*(klass: pointer): bool
proc VBOX_GET_CLASS*(obj: pointer): PVBoxClass
proc vbox_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_vbox_get_type".}
proc vbox_new*(homogeneous: gboolean, spacing: gint): PVBox{.cdecl, dynlib: lib,
    importc: "gtk_vbox_new".}
proc TYPE_COLOR_SELECTION*(): GType
proc COLOR_SELECTION*(obj: pointer): PColorSelection
proc COLOR_SELECTION_CLASS*(klass: pointer): PColorSelectionClass
proc IS_COLOR_SELECTION*(obj: pointer): bool
proc IS_COLOR_SELECTION_CLASS*(klass: pointer): bool
proc COLOR_SELECTION_GET_CLASS*(obj: pointer): PColorSelectionClass
proc color_selection_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_color_selection_get_type".}
proc color_selection_new*(): PColorSelection{.cdecl, dynlib: lib,
    importc: "gtk_color_selection_new".}
proc get_has_opacity_control*(colorsel: PColorSelection): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_color_selection_get_has_opacity_control".}
proc set_has_opacity_control*(colorsel: PColorSelection,
    has_opacity: gboolean){.cdecl, dynlib: lib, importc: "gtk_color_selection_set_has_opacity_control".}
proc get_has_palette*(colorsel: PColorSelection): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_color_selection_get_has_palette".}
proc set_has_palette*(colorsel: PColorSelection,
                                      has_palette: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_color_selection_set_has_palette".}
proc set_current_color*(colorsel: PColorSelection,
                                        color: gdk2.PColor){.cdecl, dynlib: lib,
    importc: "gtk_color_selection_set_current_color".}
proc set_current_alpha*(colorsel: PColorSelection,
                                        alpha: guint16){.cdecl, dynlib: lib,
    importc: "gtk_color_selection_set_current_alpha".}
proc get_current_color*(colorsel: PColorSelection,
                                        color: gdk2.PColor){.cdecl, dynlib: lib,
    importc: "gtk_color_selection_get_current_color".}
proc get_current_alpha*(colorsel: PColorSelection): guint16{.
    cdecl, dynlib: lib, importc: "gtk_color_selection_get_current_alpha".}
proc set_previous_color*(colorsel: PColorSelection,
    color: gdk2.PColor){.cdecl, dynlib: lib,
                       importc: "gtk_color_selection_set_previous_color".}
proc set_previous_alpha*(colorsel: PColorSelection,
    alpha: guint16){.cdecl, dynlib: lib,
                     importc: "gtk_color_selection_set_previous_alpha".}
proc get_previous_color*(colorsel: PColorSelection,
    color: gdk2.PColor){.cdecl, dynlib: lib,
                       importc: "gtk_color_selection_get_previous_color".}
proc get_previous_alpha*(colorsel: PColorSelection): guint16{.
    cdecl, dynlib: lib, importc: "gtk_color_selection_get_previous_alpha".}
proc is_adjusting*(colorsel: PColorSelection): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_color_selection_is_adjusting".}
proc color_selection_palette_from_string*(str: cstring, colors: var gdk2.PColor,
    n_colors: Pgint): gboolean{.cdecl, dynlib: lib, importc: "gtk_color_selection_palette_from_string".}
proc color_selection_palette_to_string*(colors: gdk2.PColor, n_colors: gint): cstring{.
    cdecl, dynlib: lib, importc: "gtk_color_selection_palette_to_string".}
proc color_selection_set_change_palette_with_screen_hook*(
    func: TColorSelectionChangePaletteWithScreenFunc): TColorSelectionChangePaletteWithScreenFunc{.
    cdecl, dynlib: lib,
    importc: "gtk_color_selection_set_change_palette_with_screen_hook".}
proc TYPE_COLOR_SELECTION_DIALOG*(): GType
proc COLOR_SELECTION_DIALOG*(obj: pointer): PColorSelectionDialog
proc COLOR_SELECTION_DIALOG_CLASS*(klass: pointer): PColorSelectionDialogClass
proc IS_COLOR_SELECTION_DIALOG*(obj: pointer): bool
proc IS_COLOR_SELECTION_DIALOG_CLASS*(klass: pointer): bool
proc COLOR_SELECTION_DIALOG_GET_CLASS*(obj: pointer): PColorSelectionDialogClass
proc color_selection_dialog_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_color_selection_dialog_get_type".}
proc color_selection_dialog_new*(title: cstring): PColorSelectionDialog{.cdecl,
    dynlib: lib, importc: "gtk_color_selection_dialog_new".}
proc TYPE_HBOX*(): GType
proc HBOX*(obj: pointer): PHBox
proc HBOX_CLASS*(klass: pointer): PHBoxClass
proc IS_HBOX*(obj: pointer): bool
proc IS_HBOX_CLASS*(klass: pointer): bool
proc HBOX_GET_CLASS*(obj: pointer): PHBoxClass
proc hbox_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_hbox_get_type".}
proc hbox_new*(homogeneous: gboolean, spacing: gint): PHBox{.cdecl, dynlib: lib,
    importc: "gtk_hbox_new".}
const
  bm_TGtkCombo_value_in_list* = 0x0001'i16
  bp_TGtkCombo_value_in_list* = 0'i16
  bm_TGtkCombo_ok_if_empty* = 0x0002'i16
  bp_TGtkCombo_ok_if_empty* = 1'i16
  bm_TGtkCombo_case_sensitive* = 0x0004'i16
  bp_TGtkCombo_case_sensitive* = 2'i16
  bm_TGtkCombo_use_arrows* = 0x0008'i16
  bp_TGtkCombo_use_arrows* = 3'i16
  bm_TGtkCombo_use_arrows_always* = 0x0010'i16
  bp_TGtkCombo_use_arrows_always* = 4'i16

proc TYPE_COMBO*(): GType
proc COMBO*(obj: pointer): PCombo
proc COMBO_CLASS*(klass: pointer): PComboClass
proc IS_COMBO*(obj: pointer): bool
proc IS_COMBO_CLASS*(klass: pointer): bool
proc COMBO_GET_CLASS*(obj: pointer): PComboClass
proc value_in_list*(a: PCombo): guint
proc set_value_in_list*(a: PCombo, `value_in_list`: guint)
proc ok_if_empty*(a: PCombo): guint
proc set_ok_if_empty*(a: PCombo, `ok_if_empty`: guint)
proc case_sensitive*(a: PCombo): guint
proc set_case_sensitive*(a: PCombo, `case_sensitive`: guint)
proc use_arrows*(a: PCombo): guint
proc set_use_arrows*(a: PCombo, `use_arrows`: guint)
proc use_arrows_always*(a: PCombo): guint
proc set_use_arrows_always*(a: PCombo, `use_arrows_always`: guint)
proc combo_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_combo_get_type".}
proc combo_new*(): PCombo{.cdecl, dynlib: lib, importc: "gtk_combo_new".}
proc set_value_in_list*(combo: PCombo, val: gboolean,
                              ok_if_empty: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_combo_set_value_in_list".}
proc set_use_arrows*(combo: PCombo, val: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_combo_set_use_arrows".}
proc set_use_arrows_always*(combo: PCombo, val: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_combo_set_use_arrows_always".}
proc set_case_sensitive*(combo: PCombo, val: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_combo_set_case_sensitive".}
proc set_item_string*(combo: PCombo, item: PItem, item_value: cstring){.
    cdecl, dynlib: lib, importc: "gtk_combo_set_item_string".}
proc set_popdown_strings*(combo: PCombo, strings: PGList){.cdecl,
    dynlib: lib, importc: "gtk_combo_set_popdown_strings".}
proc disable_activate*(combo: PCombo){.cdecl, dynlib: lib,
    importc: "gtk_combo_disable_activate".}
const
  bm_TGtkCTree_line_style* = 0x0003'i16
  bp_TGtkCTree_line_style* = 0'i16
  bm_TGtkCTree_expander_style* = 0x000C'i16
  bp_TGtkCTree_expander_style* = 2'i16
  bm_TGtkCTree_show_stub* = 0x0010'i16
  bp_TGtkCTree_show_stub* = 4'i16
  bm_TGtkCTreeRow_is_leaf* = 0x0001'i16
  bp_TGtkCTreeRow_is_leaf* = 0'i16
  bm_TGtkCTreeRow_expanded* = 0x0002'i16
  bp_TGtkCTreeRow_expanded* = 1'i16

proc TYPE_CTREE*(): GType
proc CTREE*(obj: pointer): PCTree
proc CTREE_CLASS*(klass: pointer): PCTreeClass
proc IS_CTREE*(obj: pointer): bool
proc IS_CTREE_CLASS*(klass: pointer): bool
proc CTREE_GET_CLASS*(obj: pointer): PCTreeClass
proc CTREE_ROW*(node: TAddress): PCTreeRow
proc CTREE_NODE*(node: TAddress): PCTreeNode
proc CTREE_NODE_NEXT*(nnode: TAddress): PCTreeNode
proc CTREE_NODE_PREV*(pnode: TAddress): PCTreeNode
proc CTREE_FUNC*(fun: TAddress): TCTreeFunc
proc TYPE_CTREE_NODE*(): GType
proc line_style*(a: PCTree): guint
proc set_line_style*(a: PCTree, `line_style`: guint)
proc expander_style*(a: PCTree): guint
proc set_expander_style*(a: PCTree, `expander_style`: guint)
proc show_stub*(a: PCTree): guint
proc set_show_stub*(a: PCTree, `show_stub`: guint)
proc is_leaf*(a: PCTreeRow): guint
proc set_is_leaf*(a: PCTreeRow, `is_leaf`: guint)
proc expanded*(a: PCTreeRow): guint
proc set_expanded*(a: PCTreeRow, `expanded`: guint)
proc ctree_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_ctree_get_type".}
proc ctree_new*(columns: gint, tree_column: gint): PCTree{.cdecl, dynlib: lib,
    importc: "gtk_ctree_new".}
proc insert_node*(ctree: PCTree, parent: PCTreeNode, sibling: PCTreeNode,
                        text: openarray[cstring], spacing: guint8,
                        pixmap_closed: gdk2.PPixmap, mask_closed: gdk2.PBitmap,
                        pixmap_opened: gdk2.PPixmap, mask_opened: gdk2.PBitmap,
                        is_leaf: gboolean, expanded: gboolean): PCTreeNode{.
    cdecl, dynlib: lib, importc: "gtk_ctree_insert_node".}
proc remove_node*(ctree: PCTree, node: PCTreeNode){.cdecl, dynlib: lib,
    importc: "gtk_ctree_remove_node".}
proc insert_gnode*(ctree: PCTree, parent: PCTreeNode, sibling: PCTreeNode,
                         gnode: PGNode, fun: TCTreeGNodeFunc, data: gpointer): PCTreeNode{.
    cdecl, dynlib: lib, importc: "gtk_ctree_insert_gnode".}
proc export_to_gnode*(ctree: PCTree, parent: PGNode, sibling: PGNode,
                            node: PCTreeNode, fun: TCTreeGNodeFunc,
                            data: gpointer): PGNode{.cdecl, dynlib: lib,
    importc: "gtk_ctree_export_to_gnode".}
proc post_recursive*(ctree: PCTree, node: PCTreeNode, fun: TCTreeFunc,
                           data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_ctree_post_recursive".}
proc post_recursive_to_depth*(ctree: PCTree, node: PCTreeNode,
                                    depth: gint, fun: TCTreeFunc,
                                    data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_ctree_post_recursive_to_depth".}
proc pre_recursive*(ctree: PCTree, node: PCTreeNode, fun: TCTreeFunc,
                          data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_ctree_pre_recursive".}
proc pre_recursive_to_depth*(ctree: PCTree, node: PCTreeNode,
                                   depth: gint, fun: TCTreeFunc,
                                   data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_ctree_pre_recursive_to_depth".}
proc is_viewable*(ctree: PCTree, node: PCTreeNode): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_ctree_is_viewable".}
proc last*(ctree: PCTree, node: PCTreeNode): PCTreeNode{.cdecl,
    dynlib: lib, importc: "gtk_ctree_last".}
proc find_node_ptr*(ctree: PCTree, ctree_row: PCTreeRow): PCTreeNode{.
    cdecl, dynlib: lib, importc: "gtk_ctree_find_node_ptr".}
proc node_nth*(ctree: PCTree, row: guint): PCTreeNode{.cdecl, dynlib: lib,
    importc: "gtk_ctree_node_nth".}
proc find*(ctree: PCTree, node: PCTreeNode, child: PCTreeNode): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_ctree_find".}
proc is_ancestor*(ctree: PCTree, node: PCTreeNode, child: PCTreeNode): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_ctree_is_ancestor".}
proc find_by_row_data*(ctree: PCTree, node: PCTreeNode, data: gpointer): PCTreeNode{.
    cdecl, dynlib: lib, importc: "gtk_ctree_find_by_row_data".}
proc find_all_by_row_data*(ctree: PCTree, node: PCTreeNode,
                                 data: gpointer): PGList{.cdecl, dynlib: lib,
    importc: "gtk_ctree_find_all_by_row_data".}
proc find_by_row_data_custom*(ctree: PCTree, node: PCTreeNode,
                                    data: gpointer, fun: TGCompareFunc): PCTreeNode{.
    cdecl, dynlib: lib, importc: "gtk_ctree_find_by_row_data_custom".}
proc find_all_by_row_data_custom*(ctree: PCTree, node: PCTreeNode,
                                        data: gpointer, fun: TGCompareFunc): PGList{.
    cdecl, dynlib: lib, importc: "gtk_ctree_find_all_by_row_data_custom".}
proc is_hot_spot*(ctree: PCTree, x: gint, y: gint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_ctree_is_hot_spot".}
proc move*(ctree: PCTree, node: PCTreeNode, new_parent: PCTreeNode,
                 new_sibling: PCTreeNode){.cdecl, dynlib: lib,
    importc: "gtk_ctree_move".}
proc expand*(ctree: PCTree, node: PCTreeNode){.cdecl, dynlib: lib,
    importc: "gtk_ctree_expand".}
proc expand_recursive*(ctree: PCTree, node: PCTreeNode){.cdecl,
    dynlib: lib, importc: "gtk_ctree_expand_recursive".}
proc expand_to_depth*(ctree: PCTree, node: PCTreeNode, depth: gint){.
    cdecl, dynlib: lib, importc: "gtk_ctree_expand_to_depth".}
proc collapse*(ctree: PCTree, node: PCTreeNode){.cdecl, dynlib: lib,
    importc: "gtk_ctree_collapse".}
proc collapse_recursive*(ctree: PCTree, node: PCTreeNode){.cdecl,
    dynlib: lib, importc: "gtk_ctree_collapse_recursive".}
proc collapse_to_depth*(ctree: PCTree, node: PCTreeNode, depth: gint){.
    cdecl, dynlib: lib, importc: "gtk_ctree_collapse_to_depth".}
proc toggle_expansion*(ctree: PCTree, node: PCTreeNode){.cdecl,
    dynlib: lib, importc: "gtk_ctree_toggle_expansion".}
proc toggle_expansion_recursive*(ctree: PCTree, node: PCTreeNode){.cdecl,
    dynlib: lib, importc: "gtk_ctree_toggle_expansion_recursive".}
proc select*(ctree: PCTree, node: PCTreeNode){.cdecl, dynlib: lib,
    importc: "gtk_ctree_select".}
proc select_recursive*(ctree: PCTree, node: PCTreeNode){.cdecl,
    dynlib: lib, importc: "gtk_ctree_select_recursive".}
proc unselect*(ctree: PCTree, node: PCTreeNode){.cdecl, dynlib: lib,
    importc: "gtk_ctree_unselect".}
proc unselect_recursive*(ctree: PCTree, node: PCTreeNode){.cdecl,
    dynlib: lib, importc: "gtk_ctree_unselect_recursive".}
proc real_select_recursive*(ctree: PCTree, node: PCTreeNode, state: gint){.
    cdecl, dynlib: lib, importc: "gtk_ctree_real_select_recursive".}
proc node_set_text*(ctree: PCTree, node: PCTreeNode, column: gint,
                          text: cstring){.cdecl, dynlib: lib,
    importc: "gtk_ctree_node_set_text".}
proc node_set_pixmap*(ctree: PCTree, node: PCTreeNode, column: gint,
                            pixmap: gdk2.PPixmap, mask: gdk2.PBitmap){.cdecl,
    dynlib: lib, importc: "gtk_ctree_node_set_pixmap".}
proc node_set_pixtext*(ctree: PCTree, node: PCTreeNode, column: gint,
                             text: cstring, spacing: guint8, pixmap: gdk2.PPixmap,
                             mask: gdk2.PBitmap){.cdecl, dynlib: lib,
    importc: "gtk_ctree_node_set_pixtext".}
proc set_node_info*(ctree: PCTree, node: PCTreeNode, text: cstring,
                          spacing: guint8, pixmap_closed: gdk2.PPixmap,
                          mask_closed: gdk2.PBitmap, pixmap_opened: gdk2.PPixmap,
                          mask_opened: gdk2.PBitmap, is_leaf: gboolean,
                          expanded: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_ctree_set_node_info".}
proc node_set_shift*(ctree: PCTree, node: PCTreeNode, column: gint,
                           vertical: gint, horizontal: gint){.cdecl,
    dynlib: lib, importc: "gtk_ctree_node_set_shift".}
proc node_set_selectable*(ctree: PCTree, node: PCTreeNode,
                                selectable: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_ctree_node_set_selectable".}
proc node_get_selectable*(ctree: PCTree, node: PCTreeNode): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_ctree_node_get_selectable".}
proc node_get_cell_type*(ctree: PCTree, node: PCTreeNode, column: gint): TCellType{.
    cdecl, dynlib: lib, importc: "gtk_ctree_node_get_cell_type".}
proc node_get_text*(ctree: PCTree, node: PCTreeNode, column: gint,
                          text: PPgchar): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_ctree_node_get_text".}
proc node_set_row_style*(ctree: PCTree, node: PCTreeNode, style: PStyle){.
    cdecl, dynlib: lib, importc: "gtk_ctree_node_set_row_style".}
proc node_get_row_style*(ctree: PCTree, node: PCTreeNode): PStyle{.cdecl,
    dynlib: lib, importc: "gtk_ctree_node_get_row_style".}
proc node_set_cell_style*(ctree: PCTree, node: PCTreeNode, column: gint,
                                style: PStyle){.cdecl, dynlib: lib,
    importc: "gtk_ctree_node_set_cell_style".}
proc node_get_cell_style*(ctree: PCTree, node: PCTreeNode, column: gint): PStyle{.
    cdecl, dynlib: lib, importc: "gtk_ctree_node_get_cell_style".}
proc node_set_foreground*(ctree: PCTree, node: PCTreeNode,
                                color: gdk2.PColor){.cdecl, dynlib: lib,
    importc: "gtk_ctree_node_set_foreground".}
proc node_set_background*(ctree: PCTree, node: PCTreeNode,
                                color: gdk2.PColor){.cdecl, dynlib: lib,
    importc: "gtk_ctree_node_set_background".}
proc node_set_row_data*(ctree: PCTree, node: PCTreeNode, data: gpointer){.
    cdecl, dynlib: lib, importc: "gtk_ctree_node_set_row_data".}
proc node_set_row_data_full*(ctree: PCTree, node: PCTreeNode,
                                   data: gpointer, destroy: TDestroyNotify){.
    cdecl, dynlib: lib, importc: "gtk_ctree_node_set_row_data_full".}
proc node_get_row_data*(ctree: PCTree, node: PCTreeNode): gpointer{.
    cdecl, dynlib: lib, importc: "gtk_ctree_node_get_row_data".}
proc node_moveto*(ctree: PCTree, node: PCTreeNode, column: gint,
                        row_align: gfloat, col_align: gfloat){.cdecl,
    dynlib: lib, importc: "gtk_ctree_node_moveto".}
proc node_is_visible*(ctree: PCTree, node: PCTreeNode): TVisibility{.
    cdecl, dynlib: lib, importc: "gtk_ctree_node_is_visible".}
proc set_indent*(ctree: PCTree, indent: gint){.cdecl, dynlib: lib,
    importc: "gtk_ctree_set_indent".}
proc set_spacing*(ctree: PCTree, spacing: gint){.cdecl, dynlib: lib,
    importc: "gtk_ctree_set_spacing".}
proc set_show_stub*(ctree: PCTree, show_stub: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_ctree_set_show_stub".}
proc set_line_style*(ctree: PCTree, line_style: TCTreeLineStyle){.cdecl,
    dynlib: lib, importc: "gtk_ctree_set_line_style".}
proc set_expander_style*(ctree: PCTree,
                               expander_style: TCTreeExpanderStyle){.cdecl,
    dynlib: lib, importc: "gtk_ctree_set_expander_style".}
proc set_drag_compare_func*(ctree: PCTree, cmp_func: TCTreeCompareDragFunc){.
    cdecl, dynlib: lib, importc: "gtk_ctree_set_drag_compare_func".}
proc sort_node*(ctree: PCTree, node: PCTreeNode){.cdecl, dynlib: lib,
    importc: "gtk_ctree_sort_node".}
proc sort_recursive*(ctree: PCTree, node: PCTreeNode){.cdecl,
    dynlib: lib, importc: "gtk_ctree_sort_recursive".}
proc ctree_set_reorderable*(t: pointer, r: bool)
proc ctree_node_get_type*(): GType{.cdecl, dynlib: lib,
                                    importc: "gtk_ctree_node_get_type".}
proc TYPE_DRAWING_AREA*(): GType
proc DRAWING_AREA*(obj: pointer): PDrawingArea
proc DRAWING_AREA_CLASS*(klass: pointer): PDrawingAreaClass
proc IS_DRAWING_AREA*(obj: pointer): bool
proc IS_DRAWING_AREA_CLASS*(klass: pointer): bool
proc DRAWING_AREA_GET_CLASS*(obj: pointer): PDrawingAreaClass
proc drawing_area_get_type*(): TType{.cdecl, dynlib: lib,
                                      importc: "gtk_drawing_area_get_type".}
proc drawing_area_new*(): PDrawingArea{.cdecl, dynlib: lib,
                                        importc: "gtk_drawing_area_new".}
proc TYPE_CURVE*(): GType
proc CURVE*(obj: pointer): PCurve
proc CURVE_CLASS*(klass: pointer): PCurveClass
proc IS_CURVE*(obj: pointer): bool
proc IS_CURVE_CLASS*(klass: pointer): bool
proc CURVE_GET_CLASS*(obj: pointer): PCurveClass
proc curve_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_curve_get_type".}
proc curve_new*(): PCurve{.cdecl, dynlib: lib, importc: "gtk_curve_new".}
proc reset*(curve: PCurve){.cdecl, dynlib: lib, importc: "gtk_curve_reset".}
proc set_gamma*(curve: PCurve, gamma: gfloat){.cdecl, dynlib: lib,
    importc: "gtk_curve_set_gamma".}
proc set_range*(curve: PCurve, min_x: gfloat, max_x: gfloat,
                      min_y: gfloat, max_y: gfloat){.cdecl, dynlib: lib,
    importc: "gtk_curve_set_range".}
proc set_curve_type*(curve: PCurve, thetype: TCurveType){.cdecl,
    dynlib: lib, importc: "gtk_curve_set_curve_type".}
const
  DEST_DEFAULT_MOTION* = 1 shl 0
  DEST_DEFAULT_HIGHLIGHT* = 1 shl 1
  DEST_DEFAULT_DROP* = 1 shl 2
  DEST_DEFAULT_ALL* = 0x00000007
  TARGET_SAME_APP* = 1 shl 0
  TARGET_SAME_WIDGET* = 1 shl 1

proc drag_get_data*(widget: PWidget, context: gdk2.PDragContext, target: gdk2.TAtom,
                    time: guint32){.cdecl, dynlib: lib,
                                    importc: "gtk_drag_get_data".}
proc drag_finish*(context: gdk2.PDragContext, success: gboolean, del: gboolean,
                  time: guint32){.cdecl, dynlib: lib, importc: "gtk_drag_finish".}
proc drag_get_source_widget*(context: gdk2.PDragContext): PWidget{.cdecl,
    dynlib: lib, importc: "gtk_drag_get_source_widget".}
proc drag_highlight*(widget: PWidget){.cdecl, dynlib: lib,
                                       importc: "gtk_drag_highlight".}
proc drag_unhighlight*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_drag_unhighlight".}
proc drag_dest_set*(widget: PWidget, flags: TDestDefaults,
                    targets: PTargetEntry, n_targets: gint,
                    actions: gdk2.TDragAction){.cdecl, dynlib: lib,
    importc: "gtk_drag_dest_set".}
proc drag_dest_set_proxy*(widget: PWidget, proxy_window: gdk2.PWindow,
                          protocol: gdk2.TDragProtocol, use_coordinates: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_drag_dest_set_proxy".}
proc drag_dest_unset*(widget: PWidget){.cdecl, dynlib: lib,
                                        importc: "gtk_drag_dest_unset".}
proc drag_dest_find_target*(widget: PWidget, context: gdk2.PDragContext,
                            target_list: PTargetList): gdk2.TAtom{.cdecl,
    dynlib: lib, importc: "gtk_drag_dest_find_target".}
proc drag_dest_get_target_list*(widget: PWidget): PTargetList{.cdecl,
    dynlib: lib, importc: "gtk_drag_dest_get_target_list".}
proc drag_dest_set_target_list*(widget: PWidget, target_list: PTargetList){.
    cdecl, dynlib: lib, importc: "gtk_drag_dest_set_target_list".}
proc drag_source_set*(widget: PWidget, start_button_mask: gdk2.TModifierType,
                      targets: PTargetEntry, n_targets: gint,
                      actions: gdk2.TDragAction){.cdecl, dynlib: lib,
    importc: "gtk_drag_source_set".}
proc drag_source_unset*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_drag_source_unset".}
proc drag_source_set_icon*(widget: PWidget, colormap: gdk2.PColormap,
                           pixmap: gdk2.PPixmap, mask: gdk2.PBitmap){.cdecl,
    dynlib: lib, importc: "gtk_drag_source_set_icon".}
proc drag_source_set_icon_pixbuf*(widget: PWidget, pixbuf: gdk2pixbuf.PPixbuf){.cdecl,
    dynlib: lib, importc: "gtk_drag_source_set_icon_pixbuf".}
proc drag_source_set_icon_stock*(widget: PWidget, stock_id: cstring){.cdecl,
    dynlib: lib, importc: "gtk_drag_source_set_icon_stock".}
proc drag_begin*(widget: PWidget, targets: PTargetList, actions: gdk2.TDragAction,
                 button: gint, event: gdk2.PEvent): gdk2.PDragContext{.cdecl,
    dynlib: lib, importc: "gtk_drag_begin".}
proc drag_set_icon_widget*(context: gdk2.PDragContext, widget: PWidget,
                           hot_x: gint, hot_y: gint){.cdecl, dynlib: lib,
    importc: "gtk_drag_set_icon_widget".}
proc drag_set_icon_pixmap*(context: gdk2.PDragContext, colormap: gdk2.PColormap,
                           pixmap: gdk2.PPixmap, mask: gdk2.PBitmap, hot_x: gint,
                           hot_y: gint){.cdecl, dynlib: lib,
    importc: "gtk_drag_set_icon_pixmap".}
proc drag_set_icon_pixbuf*(context: gdk2.PDragContext, pixbuf: gdk2pixbuf.PPixbuf,
                           hot_x: gint, hot_y: gint){.cdecl, dynlib: lib,
    importc: "gtk_drag_set_icon_pixbuf".}
proc drag_set_icon_stock*(context: gdk2.PDragContext, stock_id: cstring,
                          hot_x: gint, hot_y: gint){.cdecl, dynlib: lib,
    importc: "gtk_drag_set_icon_stock".}
proc drag_set_icon_default*(context: gdk2.PDragContext){.cdecl, dynlib: lib,
    importc: "gtk_drag_set_icon_default".}
proc drag_check_threshold*(widget: PWidget, start_x: gint, start_y: gint,
                           current_x: gint, current_y: gint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_drag_check_threshold".}
proc drag_source_handle_event*(widget: PWidget, event: gdk2.PEvent){.cdecl,
    dynlib: lib, importc: "_gtk_drag_source_handle_event".}
proc drag_dest_handle_event*(toplevel: PWidget, event: gdk2.PEvent){.cdecl,
    dynlib: lib, importc: "_gtk_drag_dest_handle_event".}
proc TYPE_EDITABLE*(): GType
proc EDITABLE*(obj: pointer): PEditable
proc EDITABLE_CLASS*(vtable: pointer): PEditableClass
proc IS_EDITABLE*(obj: pointer): bool
proc IS_EDITABLE_CLASS*(vtable: pointer): bool
proc EDITABLE_GET_CLASS*(inst: pointer): PEditableClass
proc editable_get_type*(): TType{.cdecl, dynlib: lib,
                                  importc: "gtk_editable_get_type".}
proc select_region*(editable: PEditable, start: gint, theEnd: gint){.
    cdecl, dynlib: lib, importc: "gtk_editable_select_region".}
proc get_selection_bounds*(editable: PEditable, start: Pgint,
                                    theEnd: Pgint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_editable_get_selection_bounds".}
proc insert_text*(editable: PEditable, new_text: cstring,
                           new_text_length: gint, position: Pgint){.cdecl,
    dynlib: lib, importc: "gtk_editable_insert_text".}
proc delete_text*(editable: PEditable, start_pos: gint, end_pos: gint){.
    cdecl, dynlib: lib, importc: "gtk_editable_delete_text".}
proc get_chars*(editable: PEditable, start_pos: gint, end_pos: gint): cstring{.
    cdecl, dynlib: lib, importc: "gtk_editable_get_chars".}
proc cut_clipboard*(editable: PEditable){.cdecl, dynlib: lib,
    importc: "gtk_editable_cut_clipboard".}
proc copy_clipboard*(editable: PEditable){.cdecl, dynlib: lib,
    importc: "gtk_editable_copy_clipboard".}
proc paste_clipboard*(editable: PEditable){.cdecl, dynlib: lib,
    importc: "gtk_editable_paste_clipboard".}
proc delete_selection*(editable: PEditable){.cdecl, dynlib: lib,
    importc: "gtk_editable_delete_selection".}
proc set_position*(editable: PEditable, position: gint){.cdecl,
    dynlib: lib, importc: "gtk_editable_set_position".}
proc get_position*(editable: PEditable): gint{.cdecl, dynlib: lib,
    importc: "gtk_editable_get_position".}
proc set_editable*(editable: PEditable, is_editable: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_editable_set_editable".}
proc get_editable*(editable: PEditable): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_editable_get_editable".}
proc TYPE_IM_CONTEXT*(): GType
proc IM_CONTEXT*(obj: pointer): PIMContext
proc IM_CONTEXT_CLASS*(klass: pointer): PIMContextClass
proc IS_IM_CONTEXT*(obj: pointer): bool
proc IS_IM_CONTEXT_CLASS*(klass: pointer): bool
proc IM_CONTEXT_GET_CLASS*(obj: pointer): PIMContextClass
proc im_context_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_im_context_get_type".}
proc set_client_window*(context: PIMContext, window: gdk2.PWindow){.
    cdecl, dynlib: lib, importc: "gtk_im_context_set_client_window".}
proc filter_keypress*(context: PIMContext, event: gdk2.PEventKey): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_im_context_filter_keypress".}
proc focus_in*(context: PIMContext){.cdecl, dynlib: lib,
    importc: "gtk_im_context_focus_in".}
proc focus_out*(context: PIMContext){.cdecl, dynlib: lib,
    importc: "gtk_im_context_focus_out".}
proc reset*(context: PIMContext){.cdecl, dynlib: lib,
    importc: "gtk_im_context_reset".}
proc set_cursor_location*(context: PIMContext, area: gdk2.PRectangle){.
    cdecl, dynlib: lib, importc: "gtk_im_context_set_cursor_location".}
proc set_use_preedit*(context: PIMContext, use_preedit: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_im_context_set_use_preedit".}
proc set_surrounding*(context: PIMContext, text: cstring, len: gint,
                                 cursor_index: gint){.cdecl, dynlib: lib,
    importc: "gtk_im_context_set_surrounding".}
proc get_surrounding*(context: PIMContext, text: PPgchar,
                                 cursor_index: Pgint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_im_context_get_surrounding".}
proc delete_surrounding*(context: PIMContext, offset: gint,
                                    n_chars: gint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_im_context_delete_surrounding".}
const
  bm_TGtkMenuShell_active* = 0x0001'i16
  bp_TGtkMenuShell_active* = 0'i16
  bm_TGtkMenuShell_have_grab* = 0x0002'i16
  bp_TGtkMenuShell_have_grab* = 1'i16
  bm_TGtkMenuShell_have_xgrab* = 0x0004'i16
  bp_TGtkMenuShell_have_xgrab* = 2'i16
  bm_TGtkMenuShell_ignore_leave* = 0x0008'i16
  bp_TGtkMenuShell_ignore_leave* = 3'i16
  bm_TGtkMenuShell_menu_flag* = 0x0010'i16
  bp_TGtkMenuShell_menu_flag* = 4'i16
  bm_TGtkMenuShell_ignore_enter* = 0x0020'i16
  bp_TGtkMenuShell_ignore_enter* = 5'i16
  bm_TGtkMenuShellClass_submenu_placement* = 0x0001'i16
  bp_TGtkMenuShellClass_submenu_placement* = 0'i16

proc TYPE_MENU_SHELL*(): GType
proc MENU_SHELL*(obj: pointer): PMenuShell
proc MENU_SHELL_CLASS*(klass: pointer): PMenuShellClass
proc IS_MENU_SHELL*(obj: pointer): bool
proc IS_MENU_SHELL_CLASS*(klass: pointer): bool
proc MENU_SHELL_GET_CLASS*(obj: pointer): PMenuShellClass
proc active*(a: PMenuShell): guint
proc set_active*(a: PMenuShell, `active`: guint)
proc have_grab*(a: PMenuShell): guint
proc set_have_grab*(a: PMenuShell, `have_grab`: guint)
proc have_xgrab*(a: PMenuShell): guint
proc set_have_xgrab*(a: PMenuShell, `have_xgrab`: guint)
proc ignore_leave*(a: PMenuShell): guint
proc set_ignore_leave*(a: PMenuShell, `ignore_leave`: guint)
proc menu_flag*(a: PMenuShell): guint
proc set_menu_flag*(a: PMenuShell, `menu_flag`: guint)
proc ignore_enter*(a: PMenuShell): guint
proc set_ignore_enter*(a: PMenuShell, `ignore_enter`: guint)
proc submenu_placement*(a: PMenuShellClass): guint
proc set_submenu_placement*(a: PMenuShellClass, `submenu_placement`: guint)
proc menu_shell_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_menu_shell_get_type".}
proc append*(menu_shell: PMenuShell, child: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_menu_shell_append".}
proc prepend*(menu_shell: PMenuShell, child: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_menu_shell_prepend".}
proc insert*(menu_shell: PMenuShell, child: PWidget, position: gint){.
    cdecl, dynlib: lib, importc: "gtk_menu_shell_insert".}
proc deactivate*(menu_shell: PMenuShell){.cdecl, dynlib: lib,
    importc: "gtk_menu_shell_deactivate".}
proc select_item*(menu_shell: PMenuShell, menu_item: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_menu_shell_select_item".}
proc deselect*(menu_shell: PMenuShell){.cdecl, dynlib: lib,
    importc: "gtk_menu_shell_deselect".}
proc activate_item*(menu_shell: PMenuShell, menu_item: PWidget,
                               force_deactivate: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_menu_shell_activate_item".}
proc select_first*(menu_shell: PMenuShell){.cdecl, dynlib: lib,
    importc: "_gtk_menu_shell_select_first".}
proc activate*(menu_shell: PMenuShell){.cdecl, dynlib: lib,
    importc: "_gtk_menu_shell_activate".}
const
  bm_TGtkMenu_needs_destruction_ref_count* = 0x0001'i16
  bp_TGtkMenu_needs_destruction_ref_count* = 0'i16
  bm_TGtkMenu_torn_off* = 0x0002'i16
  bp_TGtkMenu_torn_off* = 1'i16
  bm_TGtkMenu_tearoff_active* = 0x0004'i16
  bp_TGtkMenu_tearoff_active* = 2'i16
  bm_TGtkMenu_scroll_fast* = 0x0008'i16
  bp_TGtkMenu_scroll_fast* = 3'i16
  bm_TGtkMenu_upper_arrow_visible* = 0x0010'i16
  bp_TGtkMenu_upper_arrow_visible* = 4'i16
  bm_TGtkMenu_lower_arrow_visible* = 0x0020'i16
  bp_TGtkMenu_lower_arrow_visible* = 5'i16
  bm_TGtkMenu_upper_arrow_prelight* = 0x0040'i16
  bp_TGtkMenu_upper_arrow_prelight* = 6'i16
  bm_TGtkMenu_lower_arrow_prelight* = 0x0080'i16
  bp_TGtkMenu_lower_arrow_prelight* = 7'i16

proc TYPE_MENU*(): GType
proc MENU*(obj: pointer): PMenu
proc MENU_CLASS*(klass: pointer): PMenuClass
proc IS_MENU*(obj: pointer): bool
proc IS_MENU_CLASS*(klass: pointer): bool
proc MENU_GET_CLASS*(obj: pointer): PMenuClass
proc needs_destruction_ref_count*(a: PMenu): guint
proc set_needs_destruction_ref_count*(a: PMenu,
                                      `needs_destruction_ref_count`: guint)
proc torn_off*(a: PMenu): guint
proc set_torn_off*(a: PMenu, `torn_off`: guint)
proc tearoff_active*(a: PMenu): guint
proc set_tearoff_active*(a: PMenu, `tearoff_active`: guint)
proc scroll_fast*(a: PMenu): guint
proc set_scroll_fast*(a: PMenu, `scroll_fast`: guint)
proc upper_arrow_visible*(a: PMenu): guint
proc set_upper_arrow_visible*(a: PMenu, `upper_arrow_visible`: guint)
proc lower_arrow_visible*(a: PMenu): guint
proc set_lower_arrow_visible*(a: PMenu, `lower_arrow_visible`: guint)
proc upper_arrow_prelight*(a: PMenu): guint
proc set_upper_arrow_prelight*(a: PMenu, `upper_arrow_prelight`: guint)
proc lower_arrow_prelight*(a: PMenu): guint
proc set_lower_arrow_prelight*(a: PMenu, `lower_arrow_prelight`: guint)
proc menu_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_menu_get_type".}
proc menu_new*(): PMenu{.cdecl, dynlib: lib, importc: "gtk_menu_new".}
proc popup*(menu: PMenu, parent_menu_shell: PWidget,
                 parent_menu_item: PWidget, fun: TMenuPositionFunc,
                 data: gpointer, button: guint, activate_time: guint32){.cdecl,
    dynlib: lib, importc: "gtk_menu_popup".}
proc reposition*(menu: PMenu){.cdecl, dynlib: lib,
                                    importc: "gtk_menu_reposition".}
proc popdown*(menu: PMenu){.cdecl, dynlib: lib, importc: "gtk_menu_popdown".}
proc get_active*(menu: PMenu): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_menu_get_active".}
proc set_active*(menu: PMenu, index: guint){.cdecl, dynlib: lib,
    importc: "gtk_menu_set_active".}
proc set_accel_group*(menu: PMenu, accel_group: PAccelGroup){.cdecl,
    dynlib: lib, importc: "gtk_menu_set_accel_group".}
proc get_accel_group*(menu: PMenu): PAccelGroup{.cdecl, dynlib: lib,
    importc: "gtk_menu_get_accel_group".}
proc set_accel_path*(menu: PMenu, accel_path: cstring){.cdecl, dynlib: lib,
    importc: "gtk_menu_set_accel_path".}
proc attach_to_widget*(menu: PMenu, attach_widget: PWidget,
                            detacher: TMenuDetachFunc){.cdecl, dynlib: lib,
    importc: "gtk_menu_attach_to_widget".}
proc detach*(menu: PMenu){.cdecl, dynlib: lib, importc: "gtk_menu_detach".}
proc get_attach_widget*(menu: PMenu): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_menu_get_attach_widget".}
proc set_tearoff_state*(menu: PMenu, torn_off: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_menu_set_tearoff_state".}
proc get_tearoff_state*(menu: PMenu): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_menu_get_tearoff_state".}
proc set_title*(menu: PMenu, title: cstring){.cdecl, dynlib: lib,
    importc: "gtk_menu_set_title".}
proc get_title*(menu: PMenu): cstring{.cdecl, dynlib: lib,
    importc: "gtk_menu_get_title".}
proc reorder_child*(menu: PMenu, child: PWidget, position: gint){.cdecl,
    dynlib: lib, importc: "gtk_menu_reorder_child".}
proc set_screen*(menu: PMenu, screen: gdk2.PScreen){.cdecl, dynlib: lib,
    importc: "gtk_menu_set_screen".}
const
  bm_TGtkEntry_editable* = 0x0001'i16
  bp_TGtkEntry_editable* = 0'i16
  bm_TGtkEntry_visible* = 0x0002'i16
  bp_TGtkEntry_visible* = 1'i16
  bm_TGtkEntry_overwrite_mode* = 0x0004'i16
  bp_TGtkEntry_overwrite_mode* = 2'i16
  bm_TGtkEntry_in_drag* = 0x0008'i16
  bp_TGtkEntry_in_drag* = 3'i16
  bm_TGtkEntry_cache_includes_preedit* = 0x0001'i16
  bp_TGtkEntry_cache_includes_preedit* = 0'i16
  bm_TGtkEntry_need_im_reset* = 0x0002'i16
  bp_TGtkEntry_need_im_reset* = 1'i16
  bm_TGtkEntry_has_frame* = 0x0004'i16
  bp_TGtkEntry_has_frame* = 2'i16
  bm_TGtkEntry_activates_default* = 0x0008'i16
  bp_TGtkEntry_activates_default* = 3'i16
  bm_TGtkEntry_cursor_visible* = 0x0010'i16
  bp_TGtkEntry_cursor_visible* = 4'i16
  bm_TGtkEntry_in_click* = 0x0020'i16
  bp_TGtkEntry_in_click* = 5'i16
  bm_TGtkEntry_is_cell_renderer* = 0x0040'i16
  bp_TGtkEntry_is_cell_renderer* = 6'i16
  bm_TGtkEntry_editing_canceled* = 0x0080'i16
  bp_TGtkEntry_editing_canceled* = 7'i16
  bm_TGtkEntry_mouse_cursor_obscured* = 0x0100'i16
  bp_TGtkEntry_mouse_cursor_obscured* = 8'i16

proc TYPE_ENTRY*(): GType
proc ENTRY*(obj: pointer): PEntry
proc ENTRY_CLASS*(klass: pointer): PEntryClass
proc IS_ENTRY*(obj: pointer): bool
proc IS_ENTRY_CLASS*(klass: pointer): bool
proc ENTRY_GET_CLASS*(obj: pointer): PEntryClass
proc editable*(a: PEntry): guint
proc set_editable*(a: PEntry, `editable`: guint)
proc visible*(a: PEntry): guint
proc set_visible*(a: PEntry, `visible`: guint)
proc overwrite_mode*(a: PEntry): guint
proc set_overwrite_mode*(a: PEntry, `overwrite_mode`: guint)
proc in_drag*(a: PEntry): guint
proc set_in_drag*(a: PEntry, `in_drag`: guint)
proc cache_includes_preedit*(a: PEntry): guint
proc set_cache_includes_preedit*(a: PEntry, `cache_includes_preedit`: guint)
proc need_im_reset*(a: PEntry): guint
proc set_need_im_reset*(a: PEntry, `need_im_reset`: guint)
proc has_frame*(a: PEntry): guint
proc set_has_frame*(a: PEntry, `has_frame`: guint)
proc activates_default*(a: PEntry): guint
proc set_activates_default*(a: PEntry, `activates_default`: guint)
proc cursor_visible*(a: PEntry): guint
proc set_cursor_visible*(a: PEntry, `cursor_visible`: guint)
proc in_click*(a: PEntry): guint
proc set_in_click*(a: PEntry, `in_click`: guint)
proc is_cell_renderer*(a: PEntry): guint
proc set_is_cell_renderer*(a: PEntry, `is_cell_renderer`: guint)
proc editing_canceled*(a: PEntry): guint
proc set_editing_canceled*(a: PEntry, `editing_canceled`: guint)
proc mouse_cursor_obscured*(a: PEntry): guint
proc set_mouse_cursor_obscured*(a: PEntry, `mouse_cursor_obscured`: guint)
proc entry_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_entry_get_type".}
proc entry_new*(): PEntry{.cdecl, dynlib: lib, importc: "gtk_entry_new".}
proc set_visibility*(entry: PEntry, visible: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_entry_set_visibility".}
proc get_visibility*(entry: PEntry): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_entry_get_visibility".}
proc set_invisible_char*(entry: PEntry, ch: gunichar){.cdecl, dynlib: lib,
    importc: "gtk_entry_set_invisible_char".}
proc get_invisible_char*(entry: PEntry): gunichar{.cdecl, dynlib: lib,
    importc: "gtk_entry_get_invisible_char".}
proc set_has_frame*(entry: PEntry, setting: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_entry_set_has_frame".}
proc get_has_frame*(entry: PEntry): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_entry_get_has_frame".}
proc set_max_length*(entry: PEntry, max: gint){.cdecl, dynlib: lib,
    importc: "gtk_entry_set_max_length".}
proc get_max_length*(entry: PEntry): gint{.cdecl, dynlib: lib,
    importc: "gtk_entry_get_max_length".}
proc set_activates_default*(entry: PEntry, setting: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_entry_set_activates_default".}
proc get_activates_default*(entry: PEntry): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_entry_get_activates_default".}
proc set_width_chars*(entry: PEntry, n_chars: gint){.cdecl, dynlib: lib,
    importc: "gtk_entry_set_width_chars".}
proc get_width_chars*(entry: PEntry): gint{.cdecl, dynlib: lib,
    importc: "gtk_entry_get_width_chars".}
proc set_text*(entry: PEntry, text: cstring){.cdecl, dynlib: lib,
    importc: "gtk_entry_set_text".}
proc get_text*(entry: PEntry): cstring{.cdecl, dynlib: lib,
    importc: "gtk_entry_get_text".}
proc get_layout*(entry: PEntry): pango.PLayout{.cdecl, dynlib: lib,
    importc: "gtk_entry_get_layout".}
proc get_layout_offsets*(entry: PEntry, x: Pgint, y: Pgint){.cdecl,
    dynlib: lib, importc: "gtk_entry_get_layout_offsets".}
const
  ANCHOR_CENTER* = 0
  ANCHOR_NORTH* = 1
  ANCHOR_NORTH_WEST* = 2
  ANCHOR_NORTH_EAST* = 3
  ANCHOR_SOUTH* = 4
  ANCHOR_SOUTH_WEST* = 5
  ANCHOR_SOUTH_EAST* = 6
  ANCHOR_WEST* = 7
  ANCHOR_EAST* = 8
  ANCHOR_N* = ANCHOR_NORTH
  ANCHOR_NW* = ANCHOR_NORTH_WEST
  ANCHOR_NE* = ANCHOR_NORTH_EAST
  ANCHOR_S* = ANCHOR_SOUTH
  ANCHOR_SW* = ANCHOR_SOUTH_WEST
  ANCHOR_SE* = ANCHOR_SOUTH_EAST
  ANCHOR_W* = ANCHOR_WEST
  ANCHOR_E* = ANCHOR_EAST
  ARROW_UP* = 0
  ARROW_DOWN* = 1
  ARROW_LEFT* = 2
  ARROW_RIGHT* = 3
  constEXPAND* = 1 shl 0
  constSHRINK* = 1 shl 1
  constFILL* = 1 shl 2
  BUTTONBOX_DEFAULT_STYLE* = 0
  BUTTONBOX_SPREAD* = 1
  BUTTONBOX_EDGE* = 2
  BUTTONBOX_START* = 3
  BUTTONBOX_END* = 4
  CURVE_TYPE_LINEAR* = 0
  CURVE_TYPE_SPLINE* = 1
  CURVE_TYPE_FREE* = 2
  DELETE_CHARS* = 0
  DELETE_WORD_ENDS* = 1
  DELETE_WORDS* = 2
  DELETE_DISPLAY_LINES* = 3
  DELETE_DISPLAY_LINE_ENDS* = 4
  DELETE_PARAGRAPH_ENDS* = 5
  DELETE_PARAGRAPHS* = 6
  DELETE_WHITESPACE* = 7
  DIR_TAB_FORWARD* = 0
  DIR_TAB_BACKWARD* = 1
  DIR_UP* = 2
  DIR_DOWN* = 3
  DIR_LEFT* = 4
  DIR_RIGHT* = 5
  EXPANDER_COLLAPSED* = 0
  EXPANDER_SEMI_COLLAPSED* = 1
  EXPANDER_SEMI_EXPANDED* = 2
  EXPANDER_EXPANDED* = 3
  ICON_SIZE_INVALID* = 0
  ICON_SIZE_MENU* = 1
  ICON_SIZE_SMALL_TOOLBAR* = 2
  ICON_SIZE_LARGE_TOOLBAR* = 3
  ICON_SIZE_BUTTON* = 4
  ICON_SIZE_DND* = 5
  ICON_SIZE_DIALOG* = 6
  TEXT_DIR_NONE* = 0
  TEXT_DIR_LTR* = 1
  TEXT_DIR_RTL* = 2
  JUSTIFY_LEFT* = 0
  JUSTIFY_RIGHT* = 1
  JUSTIFY_CENTER* = 2
  JUSTIFY_FILL* = 3
  MENU_DIR_PARENT* = 0
  MENU_DIR_CHILD* = 1
  MENU_DIR_NEXT* = 2
  MENU_DIR_PREV* = 3
  PIXELS* = 0
  INCHES* = 1
  CENTIMETERS* = 2
  MOVEMENT_LOGICAL_POSITIONS* = 0
  MOVEMENT_VISUAL_POSITIONS* = 1
  MOVEMENT_WORDS* = 2
  MOVEMENT_DISPLAY_LINES* = 3
  MOVEMENT_DISPLAY_LINE_ENDS* = 4
  MOVEMENT_PARAGRAPHS* = 5
  MOVEMENT_PARAGRAPH_ENDS* = 6
  MOVEMENT_PAGES* = 7
  MOVEMENT_BUFFER_ENDS* = 8
  ORIENTATION_HORIZONTAL* = 0
  ORIENTATION_VERTICAL* = 1
  CORNER_TOP_LEFT* = 0
  CORNER_BOTTOM_LEFT* = 1
  CORNER_TOP_RIGHT* = 2
  CORNER_BOTTOM_RIGHT* = 3
  constPACK_START* = 0
  constPACK_END* = 1
  PATH_PRIO_LOWEST* = 0
  PATH_PRIO_GTK* = 4
  PATH_PRIO_APPLICATION* = 8
  PATH_PRIO_THEME* = 10
  PATH_PRIO_RC* = 12
  PATH_PRIO_HIGHEST* = 15
  PATH_WIDGET* = 0
  PATH_WIDGET_CLASS* = 1
  PATH_CLASS* = 2
  POLICY_ALWAYS* = 0
  POLICY_AUTOMATIC* = 1
  POLICY_NEVER* = 2
  POS_LEFT* = 0
  POS_RIGHT* = 1
  POS_TOP* = 2
  POS_BOTTOM* = 3
  PREVIEW_COLOR* = 0
  PREVIEW_GRAYSCALE* = 1
  RELIEF_NORMAL* = 0
  RELIEF_HALF* = 1
  RELIEF_NONE* = 2
  RESIZE_PARENT* = 0
  RESIZE_QUEUE* = 1
  RESIZE_IMMEDIATE* = 2
  SCROLL_NONE* = 0
  SCROLL_JUMP* = 1
  SCROLL_STEP_BACKWARD* = 2
  SCROLL_STEP_FORWARD* = 3
  SCROLL_PAGE_BACKWARD* = 4
  SCROLL_PAGE_FORWARD* = 5
  SCROLL_STEP_UP* = 6
  SCROLL_STEP_DOWN* = 7
  SCROLL_PAGE_UP* = 8
  SCROLL_PAGE_DOWN* = 9
  SCROLL_STEP_LEFT* = 10
  SCROLL_STEP_RIGHT* = 11
  SCROLL_PAGE_LEFT* = 12
  SCROLL_PAGE_RIGHT* = 13
  SCROLL_START* = 14
  SCROLL_END* = 15
  SELECTION_NONE* = 0
  SELECTION_SINGLE* = 1
  SELECTION_BROWSE* = 2
  SELECTION_MULTIPLE* = 3
  SELECTION_EXTENDED* = SELECTION_MULTIPLE
  SHADOW_NONE* = 0
  SHADOW_IN* = 1
  SHADOW_OUT* = 2
  SHADOW_ETCHED_IN* = 3
  SHADOW_ETCHED_OUT* = 4
  STATE_NORMAL* = 0
  STATE_ACTIVE* = 1
  STATE_PRELIGHT* = 2
  STATE_SELECTED* = 3
  STATE_INSENSITIVE* = 4
  DIRECTION_LEFT* = 0
  DIRECTION_RIGHT* = 1
  TOP_BOTTOM* = 0
  LEFT_RIGHT* = 1
  TOOLBAR_ICONS* = 0
  TOOLBAR_TEXT* = 1
  TOOLBAR_BOTH* = 2
  TOOLBAR_BOTH_HORIZ* = 3
  UPDATE_CONTINUOUS* = 0
  UPDATE_DISCONTINUOUS* = 1
  UPDATE_DELAYED* = 2
  VISIBILITY_NONE* = 0
  VISIBILITY_PARTIAL* = 1
  VISIBILITY_FULL* = 2
  WIN_POS_NONE* = 0
  WIN_POS_CENTER* = 1
  WIN_POS_MOUSE* = 2
  WIN_POS_CENTER_ALWAYS* = 3
  WIN_POS_CENTER_ON_PARENT* = 4
  WINDOW_TOPLEVEL* = 0
  WINDOW_POPUP* = 1
  WRAP_NONE* = 0
  WRAP_CHAR* = 1
  WRAP_WORD* = 2
  SORT_ASCENDING* = 0
  SORT_DESCENDING* = 1

proc TYPE_EVENT_BOX*(): GType
proc EVENT_BOX*(obj: pointer): PEventBox
proc EVENT_BOX_CLASS*(klass: pointer): PEventBoxClass
proc IS_EVENT_BOX*(obj: pointer): bool
proc IS_EVENT_BOX_CLASS*(klass: pointer): bool
proc EVENT_BOX_GET_CLASS*(obj: pointer): PEventBoxClass
proc event_box_get_type*(): TType{.cdecl, dynlib: lib,
                                   importc: "gtk_event_box_get_type".}
proc event_box_new*(): PEventBox{.cdecl, dynlib: lib,
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
    dynlib: lib, importc: "fnmatch".}
proc TYPE_FILE_SELECTION*(): GType
proc FILE_SELECTION*(obj: pointer): PFileSelection
proc FILE_SELECTION_CLASS*(klass: pointer): PFileSelectionClass
proc IS_FILE_SELECTION*(obj: pointer): bool
proc IS_FILE_SELECTION_CLASS*(klass: pointer): bool
proc FILE_SELECTION_GET_CLASS*(obj: pointer): PFileSelectionClass
proc file_selection_get_type*(): TType{.cdecl, dynlib: lib,
                                        importc: "gtk_file_selection_get_type".}
proc file_selection_new*(title: cstring): PFileSelection{.cdecl, dynlib: lib,
    importc: "gtk_file_selection_new".}
proc set_filename*(filesel: PFileSelection, filename: cstring){.
    cdecl, dynlib: lib, importc: "gtk_file_selection_set_filename".}
proc get_filename*(filesel: PFileSelection): cstring{.cdecl,
    dynlib: lib, importc: "gtk_file_selection_get_filename".}
proc complete*(filesel: PFileSelection, pattern: cstring){.cdecl,
    dynlib: lib, importc: "gtk_file_selection_complete".}
proc show_fileop_buttons*(filesel: PFileSelection){.cdecl,
    dynlib: lib, importc: "gtk_file_selection_show_fileop_buttons".}
proc hide_fileop_buttons*(filesel: PFileSelection){.cdecl,
    dynlib: lib, importc: "gtk_file_selection_hide_fileop_buttons".}
proc get_selections*(filesel: PFileSelection): PPgchar{.cdecl,
    dynlib: lib, importc: "gtk_file_selection_get_selections".}
proc set_select_multiple*(filesel: PFileSelection,
    select_multiple: gboolean){.cdecl, dynlib: lib, importc: "gtk_file_selection_set_select_multiple".}
proc get_select_multiple*(filesel: PFileSelection): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_file_selection_get_select_multiple".}
proc TYPE_FIXED*(): GType
proc FIXED*(obj: pointer): PFixed
proc FIXED_CLASS*(klass: pointer): PFixedClass
proc IS_FIXED*(obj: pointer): bool
proc IS_FIXED_CLASS*(klass: pointer): bool
proc FIXED_GET_CLASS*(obj: pointer): PFixedClass
proc fixed_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_fixed_get_type".}
proc fixed_new*(): PFixed{.cdecl, dynlib: lib, importc: "gtk_fixed_new".}
proc put*(fixed: PFixed, widget: PWidget, x: gint, y: gint){.cdecl,
    dynlib: lib, importc: "gtk_fixed_put".}
proc move*(fixed: PFixed, widget: PWidget, x: gint, y: gint){.cdecl,
    dynlib: lib, importc: "gtk_fixed_move".}
proc set_has_window*(fixed: PFixed, has_window: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_fixed_set_has_window".}
proc get_has_window*(fixed: PFixed): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_fixed_get_has_window".}
proc TYPE_FONT_SELECTION*(): GType
proc FONT_SELECTION*(obj: pointer): PFontSelection
proc FONT_SELECTION_CLASS*(klass: pointer): PFontSelectionClass
proc IS_FONT_SELECTION*(obj: pointer): bool
proc IS_FONT_SELECTION_CLASS*(klass: pointer): bool
proc FONT_SELECTION_GET_CLASS*(obj: pointer): PFontSelectionClass
proc TYPE_FONT_SELECTION_DIALOG*(): GType
proc FONT_SELECTION_DIALOG*(obj: pointer): PFontSelectionDialog
proc FONT_SELECTION_DIALOG_CLASS*(klass: pointer): PFontSelectionDialogClass
proc IS_FONT_SELECTION_DIALOG*(obj: pointer): bool
proc IS_FONT_SELECTION_DIALOG_CLASS*(klass: pointer): bool
proc FONT_SELECTION_DIALOG_GET_CLASS*(obj: pointer): PFontSelectionDialogClass
proc font_selection_get_type*(): TType{.cdecl, dynlib: lib,
                                        importc: "gtk_font_selection_get_type".}
proc font_selection_new*(): PFontSelection{.cdecl, dynlib: lib,
    importc: "gtk_font_selection_new".}
proc get_font_name*(fontsel: PFontSelection): cstring{.cdecl,
    dynlib: lib, importc: "gtk_font_selection_get_font_name".}
proc set_font_name*(fontsel: PFontSelection, fontname: cstring): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_font_selection_set_font_name".}
proc get_preview_text*(fontsel: PFontSelection): cstring{.cdecl,
    dynlib: lib, importc: "gtk_font_selection_get_preview_text".}
proc set_preview_text*(fontsel: PFontSelection, text: cstring){.
    cdecl, dynlib: lib, importc: "gtk_font_selection_set_preview_text".}
proc font_selection_dialog_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_font_selection_dialog_get_type".}
proc font_selection_dialog_new*(title: cstring): PFontSelectionDialog{.cdecl,
    dynlib: lib, importc: "gtk_font_selection_dialog_new".}
proc dialog_get_font_name*(fsd: PFontSelectionDialog): cstring{.
    cdecl, dynlib: lib, importc: "gtk_font_selection_dialog_get_font_name".}
proc dialog_set_font_name*(fsd: PFontSelectionDialog,
    fontname: cstring): gboolean{.cdecl, dynlib: lib, importc: "gtk_font_selection_dialog_set_font_name".}
proc dialog_get_preview_text*(fsd: PFontSelectionDialog): cstring{.
    cdecl, dynlib: lib, importc: "gtk_font_selection_dialog_get_preview_text".}
proc dialog_set_preview_text*(fsd: PFontSelectionDialog,
    text: cstring){.cdecl, dynlib: lib,
                    importc: "gtk_font_selection_dialog_set_preview_text".}
proc TYPE_GAMMA_CURVE*(): GType
proc GAMMA_CURVE*(obj: pointer): PGammaCurve
proc GAMMA_CURVE_CLASS*(klass: pointer): PGammaCurveClass
proc IS_GAMMA_CURVE*(obj: pointer): bool
proc IS_GAMMA_CURVE_CLASS*(klass: pointer): bool
proc GAMMA_CURVE_GET_CLASS*(obj: pointer): PGammaCurveClass
proc gamma_curve_get_type*(): TType{.cdecl, dynlib: lib,
                                     importc: "gtk_gamma_curve_get_type".}
proc gamma_curve_new*(): PGammaCurve{.cdecl, dynlib: lib,
                                      importc: "gtk_gamma_curve_new".}
proc gc_get*(depth: gint, colormap: gdk2.PColormap, values: gdk2.PGCValues,
             values_mask: gdk2.TGCValuesMask): gdk2.PGC{.cdecl, dynlib: lib,
    importc: "gtk_gc_get".}
proc gc_release*(gc: gdk2.PGC){.cdecl, dynlib: lib, importc: "gtk_gc_release".}
const
  bm_TGtkHandleBox_handle_position* = 0x0003'i16
  bp_TGtkHandleBox_handle_position* = 0'i16
  bm_TGtkHandleBox_float_window_mapped* = 0x0004'i16
  bp_TGtkHandleBox_float_window_mapped* = 2'i16
  bm_TGtkHandleBox_child_detached* = 0x0008'i16
  bp_TGtkHandleBox_child_detached* = 3'i16
  bm_TGtkHandleBox_in_drag* = 0x0010'i16
  bp_TGtkHandleBox_in_drag* = 4'i16
  bm_TGtkHandleBox_shrink_on_detach* = 0x0020'i16
  bp_TGtkHandleBox_shrink_on_detach* = 5'i16
  bm_TGtkHandleBox_snap_edge* = 0x01C0'i16
  bp_TGtkHandleBox_snap_edge* = 6'i16

proc TYPE_HANDLE_BOX*(): GType
proc HANDLE_BOX*(obj: pointer): PHandleBox
proc HANDLE_BOX_CLASS*(klass: pointer): PHandleBoxClass
proc IS_HANDLE_BOX*(obj: pointer): bool
proc IS_HANDLE_BOX_CLASS*(klass: pointer): bool
proc HANDLE_BOX_GET_CLASS*(obj: pointer): PHandleBoxClass
proc handle_position*(a: PHandleBox): guint
proc set_handle_position*(a: PHandleBox, `handle_position`: guint)
proc float_window_mapped*(a: PHandleBox): guint
proc set_float_window_mapped*(a: PHandleBox, `float_window_mapped`: guint)
proc child_detached*(a: PHandleBox): guint
proc set_child_detached*(a: PHandleBox, `child_detached`: guint)
proc in_drag*(a: PHandleBox): guint
proc set_in_drag*(a: PHandleBox, `in_drag`: guint)
proc shrink_on_detach*(a: PHandleBox): guint
proc set_shrink_on_detach*(a: PHandleBox, `shrink_on_detach`: guint)
proc snap_edge*(a: PHandleBox): gint
proc set_snap_edge*(a: PHandleBox, `snap_edge`: gint)
proc handle_box_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_handle_box_get_type".}
proc handle_box_new*(): PHandleBox{.cdecl, dynlib: lib,
                                    importc: "gtk_handle_box_new".}
proc set_shadow_type*(handle_box: PHandleBox, thetype: TShadowType){.
    cdecl, dynlib: lib, importc: "gtk_handle_box_set_shadow_type".}
proc get_shadow_type*(handle_box: PHandleBox): TShadowType{.cdecl,
    dynlib: lib, importc: "gtk_handle_box_get_shadow_type".}
proc set_handle_position*(handle_box: PHandleBox,
                                     position: TPositionType){.cdecl,
    dynlib: lib, importc: "gtk_handle_box_set_handle_position".}
proc get_handle_position*(handle_box: PHandleBox): TPositionType{.
    cdecl, dynlib: lib, importc: "gtk_handle_box_get_handle_position".}
proc set_snap_edge*(handle_box: PHandleBox, edge: TPositionType){.
    cdecl, dynlib: lib, importc: "gtk_handle_box_set_snap_edge".}
proc get_snap_edge*(handle_box: PHandleBox): TPositionType{.cdecl,
    dynlib: lib, importc: "gtk_handle_box_get_snap_edge".}
const
  bm_TGtkPaned_position_set* = 0x0001'i16
  bp_TGtkPaned_position_set* = 0'i16
  bm_TGtkPaned_in_drag* = 0x0002'i16
  bp_TGtkPaned_in_drag* = 1'i16
  bm_TGtkPaned_child1_shrink* = 0x0004'i16
  bp_TGtkPaned_child1_shrink* = 2'i16
  bm_TGtkPaned_child1_resize* = 0x0008'i16
  bp_TGtkPaned_child1_resize* = 3'i16
  bm_TGtkPaned_child2_shrink* = 0x0010'i16
  bp_TGtkPaned_child2_shrink* = 4'i16
  bm_TGtkPaned_child2_resize* = 0x0020'i16
  bp_TGtkPaned_child2_resize* = 5'i16
  bm_TGtkPaned_orientation* = 0x0040'i16
  bp_TGtkPaned_orientation* = 6'i16
  bm_TGtkPaned_in_recursion* = 0x0080'i16
  bp_TGtkPaned_in_recursion* = 7'i16
  bm_TGtkPaned_handle_prelit* = 0x0100'i16
  bp_TGtkPaned_handle_prelit* = 8'i16

proc TYPE_PANED*(): GType
proc PANED*(obj: pointer): PPaned
proc PANED_CLASS*(klass: pointer): PPanedClass
proc IS_PANED*(obj: pointer): bool
proc IS_PANED_CLASS*(klass: pointer): bool
proc PANED_GET_CLASS*(obj: pointer): PPanedClass
proc position_set*(a: PPaned): guint
proc set_position_set*(a: PPaned, `position_set`: guint)
proc in_drag*(a: PPaned): guint
proc set_in_drag*(a: PPaned, `in_drag`: guint)
proc child1_shrink*(a: PPaned): guint
proc set_child1_shrink*(a: PPaned, `child1_shrink`: guint)
proc child1_resize*(a: PPaned): guint
proc set_child1_resize*(a: PPaned, `child1_resize`: guint)
proc child2_shrink*(a: PPaned): guint
proc set_child2_shrink*(a: PPaned, `child2_shrink`: guint)
proc child2_resize*(a: PPaned): guint
proc set_child2_resize*(a: PPaned, `child2_resize`: guint)
proc orientation*(a: PPaned): guint
proc set_orientation*(a: PPaned, `orientation`: guint)
proc in_recursion*(a: PPaned): guint
proc set_in_recursion*(a: PPaned, `in_recursion`: guint)
proc handle_prelit*(a: PPaned): guint
proc set_handle_prelit*(a: PPaned, `handle_prelit`: guint)
proc paned_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_paned_get_type".}
proc add1*(paned: PPaned, child: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_paned_add1".}
proc add2*(paned: PPaned, child: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_paned_add2".}
proc pack1*(paned: PPaned, child: PWidget, resize: gboolean,
                  shrink: gboolean){.cdecl, dynlib: lib,
                                     importc: "gtk_paned_pack1".}
proc pack2*(paned: PPaned, child: PWidget, resize: gboolean,
                  shrink: gboolean){.cdecl, dynlib: lib,
                                     importc: "gtk_paned_pack2".}
proc get_position*(paned: PPaned): gint{.cdecl, dynlib: lib,
    importc: "gtk_paned_get_position".}
proc set_position*(paned: PPaned, position: gint){.cdecl, dynlib: lib,
    importc: "gtk_paned_set_position".}
proc compute_position*(paned: PPaned, allocation: gint, child1_req: gint,
                             child2_req: gint){.cdecl, dynlib: lib,
    importc: "gtk_paned_compute_position".}
proc TYPE_HBUTTON_BOX*(): GType
proc HBUTTON_BOX*(obj: pointer): PHButtonBox
proc HBUTTON_BOX_CLASS*(klass: pointer): PHButtonBoxClass
proc IS_HBUTTON_BOX*(obj: pointer): bool
proc IS_HBUTTON_BOX_CLASS*(klass: pointer): bool
proc HBUTTON_BOX_GET_CLASS*(obj: pointer): PHButtonBoxClass
proc hbutton_box_get_type*(): TType{.cdecl, dynlib: lib,
                                     importc: "gtk_hbutton_box_get_type".}
proc hbutton_box_new*(): PHButtonBox{.cdecl, dynlib: lib,
                                      importc: "gtk_hbutton_box_new".}
proc TYPE_HPANED*(): GType
proc HPANED*(obj: pointer): PHPaned
proc HPANED_CLASS*(klass: pointer): PHPanedClass
proc IS_HPANED*(obj: pointer): bool
proc IS_HPANED_CLASS*(klass: pointer): bool
proc HPANED_GET_CLASS*(obj: pointer): PHPanedClass
proc hpaned_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_hpaned_get_type".}
proc hpaned_new*(): PHPaned{.cdecl, dynlib: lib, importc: "gtk_hpaned_new".}
proc TYPE_RULER*(): GType
proc RULER*(obj: pointer): PRuler
proc RULER_CLASS*(klass: pointer): PRulerClass
proc IS_RULER*(obj: pointer): bool
proc IS_RULER_CLASS*(klass: pointer): bool
proc RULER_GET_CLASS*(obj: pointer): PRulerClass
proc ruler_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_ruler_get_type".}
proc set_metric*(ruler: PRuler, metric: TMetricType){.cdecl, dynlib: lib,
    importc: "gtk_ruler_set_metric".}
proc set_range*(ruler: PRuler, lower: gdouble, upper: gdouble,
                      position: gdouble, max_size: gdouble){.cdecl, dynlib: lib,
    importc: "gtk_ruler_set_range".}
proc draw_ticks*(ruler: PRuler){.cdecl, dynlib: lib,
                                       importc: "gtk_ruler_draw_ticks".}
proc draw_pos*(ruler: PRuler){.cdecl, dynlib: lib,
                                     importc: "gtk_ruler_draw_pos".}
proc get_metric*(ruler: PRuler): TMetricType{.cdecl, dynlib: lib,
    importc: "gtk_ruler_get_metric".}
proc get_range*(ruler: PRuler, lower: Pgdouble, upper: Pgdouble,
                      position: Pgdouble, max_size: Pgdouble){.cdecl,
    dynlib: lib, importc: "gtk_ruler_get_range".}
proc TYPE_HRULER*(): GType
proc HRULER*(obj: pointer): PHRuler
proc HRULER_CLASS*(klass: pointer): PHRulerClass
proc IS_HRULER*(obj: pointer): bool
proc IS_HRULER_CLASS*(klass: pointer): bool
proc HRULER_GET_CLASS*(obj: pointer): PHRulerClass
proc hruler_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_hruler_get_type".}
proc hruler_new*(): PHRuler{.cdecl, dynlib: lib, importc: "gtk_hruler_new".}
proc TYPE_SETTINGS*(): GType
proc SETTINGS*(obj: pointer): PSettings
proc SETTINGS_CLASS*(klass: pointer): PSettingsClass
proc IS_SETTINGS*(obj: pointer): bool
proc IS_SETTINGS_CLASS*(klass: pointer): bool
proc SETTINGS_GET_CLASS*(obj: pointer): PSettingsClass
proc settings_get_type*(): GType{.cdecl, dynlib: lib,
                                  importc: "gtk_settings_get_type".}
proc settings_get_for_screen*(screen: gdk2.PScreen): PSettings{.cdecl,
    dynlib: lib, importc: "gtk_settings_get_for_screen".}
proc settings_install_property*(pspec: PGParamSpec){.cdecl, dynlib: lib,
    importc: "gtk_settings_install_property".}
proc settings_install_property_parser*(pspec: PGParamSpec,
                                       parser: TRcPropertyParser){.cdecl,
    dynlib: lib, importc: "gtk_settings_install_property_parser".}
proc rc_property_parse_color*(pspec: PGParamSpec, gstring: PGString,
                              property_value: PGValue): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_rc_property_parse_color".}
proc rc_property_parse_enum*(pspec: PGParamSpec, gstring: PGString,
                             property_value: PGValue): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_rc_property_parse_enum".}
proc rc_property_parse_flags*(pspec: PGParamSpec, gstring: PGString,
                              property_value: PGValue): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_rc_property_parse_flags".}
proc rc_property_parse_requisition*(pspec: PGParamSpec, gstring: PGString,
                                    property_value: PGValue): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_rc_property_parse_requisition".}
proc rc_property_parse_border*(pspec: PGParamSpec, gstring: PGString,
                               property_value: PGValue): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_rc_property_parse_border".}
proc set_property_value*(settings: PSettings, name: cstring,
                                  svalue: PSettingsValue){.cdecl, dynlib: lib,
    importc: "gtk_settings_set_property_value".}
proc set_string_property*(settings: PSettings, name: cstring,
                                   v_string: cstring, origin: cstring){.cdecl,
    dynlib: lib, importc: "gtk_settings_set_string_property".}
proc set_long_property*(settings: PSettings, name: cstring,
                                 v_long: glong, origin: cstring){.cdecl,
    dynlib: lib, importc: "gtk_settings_set_long_property".}
proc set_double_property*(settings: PSettings, name: cstring,
                                   v_double: gdouble, origin: cstring){.cdecl,
    dynlib: lib, importc: "gtk_settings_set_double_property".}
proc settings_handle_event*(event: gdk2.PEventSetting){.cdecl, dynlib: lib,
    importc: "_gtk_settings_handle_event".}
proc rc_property_parser_from_type*(thetype: GType): TRcPropertyParser{.cdecl,
    dynlib: lib, importc: "_gtk_rc_property_parser_from_type".}
proc settings_parse_convert*(parser: TRcPropertyParser, src_value: PGValue,
                             pspec: PGParamSpec, dest_value: PGValue): gboolean{.
    cdecl, dynlib: lib, importc: "_gtk_settings_parse_convert".}
const
  RC_FG* = 1 shl 0
  RC_BG* = 1 shl 1
  RC_TEXT* = 1 shl 2
  RC_BASE* = 1 shl 3
  bm_TGtkRcStyle_engine_specified* = 0x0001'i16
  bp_TGtkRcStyle_engine_specified* = 0'i16

proc TYPE_RC_STYLE*(): GType
proc RC_STYLE_get*(anObject: pointer): PRcStyle
proc RC_STYLE_CLASS*(klass: pointer): PRcStyleClass
proc IS_RC_STYLE*(anObject: pointer): bool
proc IS_RC_STYLE_CLASS*(klass: pointer): bool
proc RC_STYLE_GET_CLASS*(obj: pointer): PRcStyleClass
proc engine_specified*(a: PRcStyle): guint
proc set_engine_specified*(a: PRcStyle, `engine_specified`: guint)
proc rc_init*(){.cdecl, dynlib: lib, importc: "_gtk_rc_init".}
proc rc_add_default_file*(filename: cstring){.cdecl, dynlib: lib,
    importc: "gtk_rc_add_default_file".}
proc rc_set_default_files*(filenames: PPgchar){.cdecl, dynlib: lib,
    importc: "gtk_rc_set_default_files".}
proc rc_get_default_files*(): PPgchar{.cdecl, dynlib: lib,
                                       importc: "gtk_rc_get_default_files".}
proc rc_get_style*(widget: PWidget): PStyle{.cdecl, dynlib: lib,
    importc: "gtk_rc_get_style".}
proc rc_get_style_by_paths*(settings: PSettings, widget_path: cstring,
                            class_path: cstring, thetype: GType): PStyle{.cdecl,
    dynlib: lib, importc: "gtk_rc_get_style_by_paths".}
proc rc_reparse_all_for_settings*(settings: PSettings, force_load: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_rc_reparse_all_for_settings".}
proc rc_find_pixmap_in_path*(settings: PSettings, scanner: PGScanner,
                             pixmap_file: cstring): cstring{.cdecl, dynlib: lib,
    importc: "gtk_rc_find_pixmap_in_path".}
proc rc_parse*(filename: cstring){.cdecl, dynlib: lib, importc: "gtk_rc_parse".}
proc rc_parse_string*(rc_string: cstring){.cdecl, dynlib: lib,
    importc: "gtk_rc_parse_string".}
proc rc_reparse_all*(): gboolean{.cdecl, dynlib: lib,
                                  importc: "gtk_rc_reparse_all".}
proc rc_style_get_type*(): GType{.cdecl, dynlib: lib,
                                  importc: "gtk_rc_style_get_type".}
proc rc_style_new*(): PRcStyle{.cdecl, dynlib: lib, importc: "gtk_rc_style_new".}
proc copy*(orig: PRcStyle): PRcStyle{.cdecl, dynlib: lib,
    importc: "gtk_rc_style_copy".}
proc reference*(rc_style: PRcStyle){.cdecl, dynlib: lib,
                                        importc: "gtk_rc_style_ref".}
proc unref*(rc_style: PRcStyle){.cdecl, dynlib: lib,
    importc: "gtk_rc_style_unref".}
proc rc_find_module_in_path*(module_file: cstring): cstring{.cdecl, dynlib: lib,
    importc: "gtk_rc_find_module_in_path".}
proc rc_get_theme_dir*(): cstring{.cdecl, dynlib: lib,
                                   importc: "gtk_rc_get_theme_dir".}
proc rc_get_module_dir*(): cstring{.cdecl, dynlib: lib,
                                    importc: "gtk_rc_get_module_dir".}
proc rc_get_im_module_path*(): cstring{.cdecl, dynlib: lib,
                                        importc: "gtk_rc_get_im_module_path".}
proc rc_get_im_module_file*(): cstring{.cdecl, dynlib: lib,
                                        importc: "gtk_rc_get_im_module_file".}
proc rc_scanner_new*(): PGScanner{.cdecl, dynlib: lib,
                                   importc: "gtk_rc_scanner_new".}
proc rc_parse_color*(scanner: PGScanner, color: gdk2.PColor): guint{.cdecl,
    dynlib: lib, importc: "gtk_rc_parse_color".}
proc rc_parse_state*(scanner: PGScanner, state: PStateType): guint{.cdecl,
    dynlib: lib, importc: "gtk_rc_parse_state".}
proc rc_parse_priority*(scanner: PGScanner, priority: PPathPriorityType): guint{.
    cdecl, dynlib: lib, importc: "gtk_rc_parse_priority".}
proc lookup_rc_property*(rc_style: PRcStyle, type_name: TGQuark,
                                  property_name: TGQuark): PRcProperty{.cdecl,
    dynlib: lib, importc: "_gtk_rc_style_lookup_rc_property".}
proc rc_context_get_default_font_name*(settings: PSettings): cstring{.cdecl,
    dynlib: lib, importc: "_gtk_rc_context_get_default_font_name".}
proc TYPE_STYLE*(): GType
proc STYLE*(anObject: pointer): PStyle
proc STYLE_CLASS*(klass: pointer): PStyleClass
proc IS_STYLE*(anObject: pointer): bool
proc IS_STYLE_CLASS*(klass: pointer): bool
proc STYLE_GET_CLASS*(obj: pointer): PStyleClass
proc TYPE_BORDER*(): GType
proc STYLE_ATTACHED*(style: pointer): bool
proc style_get_type*(): GType{.cdecl, dynlib: lib, importc: "gtk_style_get_type".}
proc style_new*(): PStyle{.cdecl, dynlib: lib, importc: "gtk_style_new".}
proc copy*(style: PStyle): PStyle{.cdecl, dynlib: lib,
    importc: "gtk_style_copy".}
proc attach*(style: PStyle, window: gdk2.PWindow): PStyle{.cdecl,
    dynlib: lib, importc: "gtk_style_attach".}
proc detach*(style: PStyle){.cdecl, dynlib: lib,
                                   importc: "gtk_style_detach".}
proc set_background*(style: PStyle, window: gdk2.PWindow,
                           state_type: TStateType){.cdecl, dynlib: lib,
    importc: "gtk_style_set_background".}
proc apply_default_background*(style: PStyle, window: gdk2.PWindow,
                                     set_bg: gboolean, state_type: TStateType,
                                     area: gdk2.PRectangle, x: gint, y: gint,
                                     width: gint, height: gint){.cdecl,
    dynlib: lib, importc: "gtk_style_apply_default_background".}
proc lookup_icon_set*(style: PStyle, stock_id: cstring): PIconSet{.cdecl,
    dynlib: lib, importc: "gtk_style_lookup_icon_set".}
proc render_icon*(style: PStyle, source: PIconSource,
                        direction: TTextDirection, state: TStateType,
                        size: TIconSize, widget: PWidget, detail: cstring): gdk2pixbuf.PPixbuf{.
    cdecl, dynlib: lib, importc: "gtk_style_render_icon".}
proc paint_hline*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                  area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                  x1: gint, x2: gint, y: gint){.cdecl, dynlib: lib,
    importc: "gtk_paint_hline".}
proc paint_vline*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                  area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                  y1: gint, y2: gint, x: gint){.cdecl, dynlib: lib,
    importc: "gtk_paint_vline".}
proc paint_shadow*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                   shadow_type: TShadowType, area: gdk2.PRectangle,
                   widget: PWidget, detail: cstring, x: gint, y: gint,
                   width: gint, height: gint){.cdecl, dynlib: lib,
    importc: "gtk_paint_shadow".}
proc paint_polygon*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                    shadow_type: TShadowType, area: gdk2.PRectangle,
                    widget: PWidget, detail: cstring, points: gdk2.PPoint,
                    npoints: gint, fill: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_paint_polygon".}
proc paint_arrow*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                  shadow_type: TShadowType, area: gdk2.PRectangle,
                  widget: PWidget, detail: cstring, arrow_type: TArrowType,
                  fill: gboolean, x: gint, y: gint, width: gint, height: gint){.
    cdecl, dynlib: lib, importc: "gtk_paint_arrow".}
proc paint_diamond*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                    shadow_type: TShadowType, area: gdk2.PRectangle,
                    widget: PWidget, detail: cstring, x: gint, y: gint,
                    width: gint, height: gint){.cdecl, dynlib: lib,
    importc: "gtk_paint_diamond".}
proc paint_box*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                shadow_type: TShadowType, area: gdk2.PRectangle, widget: PWidget,
                detail: cstring, x: gint, y: gint, width: gint, height: gint){.
    cdecl, dynlib: lib, importc: "gtk_paint_box".}
proc paint_flat_box*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                     shadow_type: TShadowType, area: gdk2.PRectangle,
                     widget: PWidget, detail: cstring, x: gint, y: gint,
                     width: gint, height: gint){.cdecl, dynlib: lib,
    importc: "gtk_paint_flat_box".}
proc paint_check*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                  shadow_type: TShadowType, area: gdk2.PRectangle,
                  widget: PWidget, detail: cstring, x: gint, y: gint,
                  width: gint, height: gint){.cdecl, dynlib: lib,
    importc: "gtk_paint_check".}
proc paint_option*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                   shadow_type: TShadowType, area: gdk2.PRectangle,
                   widget: PWidget, detail: cstring, x: gint, y: gint,
                   width: gint, height: gint){.cdecl, dynlib: lib,
    importc: "gtk_paint_option".}
proc paint_tab*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                shadow_type: TShadowType, area: gdk2.PRectangle, widget: PWidget,
                detail: cstring, x: gint, y: gint, width: gint, height: gint){.
    cdecl, dynlib: lib, importc: "gtk_paint_tab".}
proc paint_shadow_gap*(style: PStyle, window: gdk2.PWindow,
                       state_type: TStateType, shadow_type: TShadowType,
                       area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                       x: gint, y: gint, width: gint, height: gint,
                       gap_side: TPositionType, gap_x: gint, gap_width: gint){.
    cdecl, dynlib: lib, importc: "gtk_paint_shadow_gap".}
proc paint_box_gap*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                    shadow_type: TShadowType, area: gdk2.PRectangle,
                    widget: PWidget, detail: cstring, x: gint, y: gint,
                    width: gint, height: gint, gap_side: TPositionType,
                    gap_x: gint, gap_width: gint){.cdecl, dynlib: lib,
    importc: "gtk_paint_box_gap".}
proc paint_extension*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                      shadow_type: TShadowType, area: gdk2.PRectangle,
                      widget: PWidget, detail: cstring, x: gint, y: gint,
                      width: gint, height: gint, gap_side: TPositionType){.
    cdecl, dynlib: lib, importc: "gtk_paint_extension".}
proc paint_focus*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                  area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                  x: gint, y: gint, width: gint, height: gint){.cdecl,
    dynlib: lib, importc: "gtk_paint_focus".}
proc paint_slider*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                   shadow_type: TShadowType, area: gdk2.PRectangle,
                   widget: PWidget, detail: cstring, x: gint, y: gint,
                   width: gint, height: gint, orientation: TOrientation){.cdecl,
    dynlib: lib, importc: "gtk_paint_slider".}
proc paint_handle*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                   shadow_type: TShadowType, area: gdk2.PRectangle,
                   widget: PWidget, detail: cstring, x: gint, y: gint,
                   width: gint, height: gint, orientation: TOrientation){.cdecl,
    dynlib: lib, importc: "gtk_paint_handle".}
proc paint_expander*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                     area: gdk2.PRectangle, widget: PWidget, detail: cstring,
                     x: gint, y: gint, expander_style: TExpanderStyle){.cdecl,
    dynlib: lib, importc: "gtk_paint_expander".}
proc paint_layout*(style: PStyle, window: gdk2.PWindow, state_type: TStateType,
                   use_text: gboolean, area: gdk2.PRectangle, widget: PWidget,
                   detail: cstring, x: gint, y: gint, layout: pango.PLayout){.
    cdecl, dynlib: lib, importc: "gtk_paint_layout".}
proc paint_resize_grip*(style: PStyle, window: gdk2.PWindow,
                        state_type: TStateType, area: gdk2.PRectangle,
                        widget: PWidget, detail: cstring, edge: gdk2.TWindowEdge,
                        x: gint, y: gint, width: gint, height: gint){.cdecl,
    dynlib: lib, importc: "gtk_paint_resize_grip".}
proc border_get_type*(): GType{.cdecl, dynlib: lib,
                                importc: "gtk_border_get_type".}
proc copy*(border: PBorder): PBorder{.cdecl, dynlib: lib,
    importc: "gtk_border_copy".}
proc free*(border: PBorder){.cdecl, dynlib: lib,
                                    importc: "gtk_border_free".}
proc peek_property_value*(style: PStyle, widget_type: GType,
                                pspec: PGParamSpec, parser: TRcPropertyParser): PGValue{.
    cdecl, dynlib: lib, importc: "_gtk_style_peek_property_value".}
proc get_insertion_cursor_gc*(widget: PWidget, is_primary: gboolean): gdk2.PGC{.
    cdecl, dynlib: lib, importc: "_gtk_get_insertion_cursor_gc".}
proc draw_insertion_cursor*(widget: PWidget, drawable: gdk2.PDrawable, gc: gdk2.PGC,
                            location: gdk2.PRectangle, direction: TTextDirection,
                            draw_arrow: gboolean){.cdecl, dynlib: lib,
    importc: "_gtk_draw_insertion_cursor".}
const
  bm_TGtkRange_inverted* = 0x0001'i16
  bp_TGtkRange_inverted* = 0'i16
  bm_TGtkRange_flippable* = 0x0002'i16
  bp_TGtkRange_flippable* = 1'i16
  bm_TGtkRange_has_stepper_a* = 0x0004'i16
  bp_TGtkRange_has_stepper_a* = 2'i16
  bm_TGtkRange_has_stepper_b* = 0x0008'i16
  bp_TGtkRange_has_stepper_b* = 3'i16
  bm_TGtkRange_has_stepper_c* = 0x0010'i16
  bp_TGtkRange_has_stepper_c* = 4'i16
  bm_TGtkRange_has_stepper_d* = 0x0020'i16
  bp_TGtkRange_has_stepper_d* = 5'i16
  bm_TGtkRange_need_recalc* = 0x0040'i16
  bp_TGtkRange_need_recalc* = 6'i16
  bm_TGtkRange_slider_size_fixed* = 0x0080'i16
  bp_TGtkRange_slider_size_fixed* = 7'i16
  bm_TGtkRange_trough_click_forward* = 0x0001'i16
  bp_TGtkRange_trough_click_forward* = 0'i16
  bm_TGtkRange_update_pending* = 0x0002'i16
  bp_TGtkRange_update_pending* = 1'i16

proc TYPE_RANGE*(): GType
proc RANGE*(obj: pointer): PRange
proc RANGE_CLASS*(klass: pointer): PRangeClass
proc IS_RANGE*(obj: pointer): bool
proc IS_RANGE_CLASS*(klass: pointer): bool
proc RANGE_GET_CLASS*(obj: pointer): PRangeClass
proc inverted*(a: PRange): guint
proc set_inverted*(a: PRange, `inverted`: guint)
proc flippable*(a: PRange): guint
proc set_flippable*(a: PRange, `flippable`: guint)
proc has_stepper_a*(a: PRange): guint
proc set_has_stepper_a*(a: PRange, `has_stepper_a`: guint)
proc has_stepper_b*(a: PRange): guint
proc set_has_stepper_b*(a: PRange, `has_stepper_b`: guint)
proc has_stepper_c*(a: PRange): guint
proc set_has_stepper_c*(a: PRange, `has_stepper_c`: guint)
proc has_stepper_d*(a: PRange): guint
proc set_has_stepper_d*(a: PRange, `has_stepper_d`: guint)
proc need_recalc*(a: PRange): guint
proc set_need_recalc*(a: PRange, `need_recalc`: guint)
proc slider_size_fixed*(a: PRange): guint
proc set_slider_size_fixed*(a: PRange, `slider_size_fixed`: guint)
proc trough_click_forward*(a: PRange): guint
proc set_trough_click_forward*(a: PRange, `trough_click_forward`: guint)
proc update_pending*(a: PRange): guint
proc set_update_pending*(a: PRange, `update_pending`: guint)
proc range_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_range_get_type".}
proc set_update_policy*(range: PRange, policy: TUpdateType){.cdecl,
    dynlib: lib, importc: "gtk_range_set_update_policy".}
proc get_update_policy*(range: PRange): TUpdateType{.cdecl, dynlib: lib,
    importc: "gtk_range_get_update_policy".}
proc set_adjustment*(range: PRange, adjustment: PAdjustment){.cdecl,
    dynlib: lib, importc: "gtk_range_set_adjustment".}
proc get_adjustment*(range: PRange): PAdjustment{.cdecl, dynlib: lib,
    importc: "gtk_range_get_adjustment".}
proc set_inverted*(range: PRange, setting: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_range_set_inverted".}
proc get_inverted*(range: PRange): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_range_get_inverted".}
proc set_increments*(range: PRange, step: gdouble, page: gdouble){.cdecl,
    dynlib: lib, importc: "gtk_range_set_increments".}
proc set_range*(range: PRange, min: gdouble, max: gdouble){.cdecl,
    dynlib: lib, importc: "gtk_range_set_range".}
proc set_value*(range: PRange, value: gdouble){.cdecl, dynlib: lib,
    importc: "gtk_range_set_value".}
proc get_value*(range: PRange): gdouble{.cdecl, dynlib: lib,
    importc: "gtk_range_get_value".}
const
  bm_TGtkScale_draw_value* = 0x0001'i16
  bp_TGtkScale_draw_value* = 0'i16
  bm_TGtkScale_value_pos* = 0x0006'i16
  bp_TGtkScale_value_pos* = 1'i16

proc TYPE_SCALE*(): GType
proc SCALE*(obj: pointer): PScale
proc SCALE_CLASS*(klass: pointer): PScaleClass
proc IS_SCALE*(obj: pointer): bool
proc IS_SCALE_CLASS*(klass: pointer): bool
proc SCALE_GET_CLASS*(obj: pointer): PScaleClass
proc draw_value*(a: PScale): guint
proc set_draw_value*(a: PScale, `draw_value`: guint)
proc value_pos*(a: PScale): guint
proc set_value_pos*(a: PScale, `value_pos`: guint)
proc scale_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_scale_get_type".}
proc set_digits*(scale: PScale, digits: gint){.cdecl, dynlib: lib,
    importc: "gtk_scale_set_digits".}
proc get_digits*(scale: PScale): gint{.cdecl, dynlib: lib,
    importc: "gtk_scale_get_digits".}
proc set_draw_value*(scale: PScale, draw_value: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_scale_set_draw_value".}
proc get_draw_value*(scale: PScale): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_scale_get_draw_value".}
proc set_value_pos*(scale: PScale, pos: TPositionType){.cdecl,
    dynlib: lib, importc: "gtk_scale_set_value_pos".}
proc get_value_pos*(scale: PScale): TPositionType{.cdecl, dynlib: lib,
    importc: "gtk_scale_get_value_pos".}
proc get_value_size*(scale: PScale, width: Pgint, height: Pgint){.cdecl,
    dynlib: lib, importc: "_gtk_scale_get_value_size".}
proc format_value*(scale: PScale, value: gdouble): cstring{.cdecl,
    dynlib: lib, importc: "_gtk_scale_format_value".}
proc TYPE_HSCALE*(): GType
proc HSCALE*(obj: pointer): PHScale
proc HSCALE_CLASS*(klass: pointer): PHScaleClass
proc IS_HSCALE*(obj: pointer): bool
proc IS_HSCALE_CLASS*(klass: pointer): bool
proc HSCALE_GET_CLASS*(obj: pointer): PHScaleClass
proc hscale_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_hscale_get_type".}
proc hscale_new*(adjustment: PAdjustment): PHScale{.cdecl, dynlib: lib,
    importc: "gtk_hscale_new".}
proc hscale_new*(min: gdouble, max: gdouble, step: gdouble): PHScale{.
    cdecl, dynlib: lib, importc: "gtk_hscale_new_with_range".}
proc TYPE_SCROLLBAR*(): GType
proc SCROLLBAR*(obj: pointer): PScrollbar
proc SCROLLBAR_CLASS*(klass: pointer): PScrollbarClass
proc IS_SCROLLBAR*(obj: pointer): bool
proc IS_SCROLLBAR_CLASS*(klass: pointer): bool
proc SCROLLBAR_GET_CLASS*(obj: pointer): PScrollbarClass
proc scrollbar_get_type*(): TType{.cdecl, dynlib: lib,
                                   importc: "gtk_scrollbar_get_type".}
proc TYPE_HSCROLLBAR*(): GType
proc HSCROLLBAR*(obj: pointer): PHScrollbar
proc HSCROLLBAR_CLASS*(klass: pointer): PHScrollbarClass
proc IS_HSCROLLBAR*(obj: pointer): bool
proc IS_HSCROLLBAR_CLASS*(klass: pointer): bool
proc HSCROLLBAR_GET_CLASS*(obj: pointer): PHScrollbarClass
proc hscrollbar_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_hscrollbar_get_type".}
proc hscrollbar_new*(adjustment: PAdjustment): PHScrollbar{.cdecl, dynlib: lib,
    importc: "gtk_hscrollbar_new".}
proc TYPE_SEPARATOR*(): GType
proc SEPARATOR*(obj: pointer): PSeparator
proc SEPARATOR_CLASS*(klass: pointer): PSeparatorClass
proc IS_SEPARATOR*(obj: pointer): bool
proc IS_SEPARATOR_CLASS*(klass: pointer): bool
proc SEPARATOR_GET_CLASS*(obj: pointer): PSeparatorClass
proc separator_get_type*(): TType{.cdecl, dynlib: lib,
                                   importc: "gtk_separator_get_type".}
proc TYPE_HSEPARATOR*(): GType
proc HSEPARATOR*(obj: pointer): PHSeparator
proc HSEPARATOR_CLASS*(klass: pointer): PHSeparatorClass
proc IS_HSEPARATOR*(obj: pointer): bool
proc IS_HSEPARATOR_CLASS*(klass: pointer): bool
proc HSEPARATOR_GET_CLASS*(obj: pointer): PHSeparatorClass
proc hseparator_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_hseparator_get_type".}
proc hseparator_new*(): PHSeparator{.cdecl, dynlib: lib,
                                     importc: "gtk_hseparator_new".}
proc TYPE_ICON_FACTORY*(): GType
proc ICON_FACTORY*(anObject: pointer): PIconFactory
proc ICON_FACTORY_CLASS*(klass: pointer): PIconFactoryClass
proc IS_ICON_FACTORY*(anObject: pointer): bool
proc IS_ICON_FACTORY_CLASS*(klass: pointer): bool
proc ICON_FACTORY_GET_CLASS*(obj: pointer): PIconFactoryClass
proc TYPE_ICON_SET*(): GType
proc TYPE_ICON_SOURCE*(): GType
proc icon_factory_get_type*(): GType{.cdecl, dynlib: lib,
                                      importc: "gtk_icon_factory_get_type".}
proc icon_factory_new*(): PIconFactory{.cdecl, dynlib: lib,
                                        importc: "gtk_icon_factory_new".}
proc add*(factory: PIconFactory, stock_id: cstring,
                       icon_set: PIconSet){.cdecl, dynlib: lib,
    importc: "gtk_icon_factory_add".}
proc lookup*(factory: PIconFactory, stock_id: cstring): PIconSet{.
    cdecl, dynlib: lib, importc: "gtk_icon_factory_lookup".}
proc add_default*(factory: PIconFactory){.cdecl, dynlib: lib,
    importc: "gtk_icon_factory_add_default".}
proc remove_default*(factory: PIconFactory){.cdecl, dynlib: lib,
    importc: "gtk_icon_factory_remove_default".}
proc icon_factory_lookup_default*(stock_id: cstring): PIconSet{.cdecl,
    dynlib: lib, importc: "gtk_icon_factory_lookup_default".}
proc icon_size_lookup*(size: TIconSize, width: Pgint, height: Pgint): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_icon_size_lookup".}
proc icon_size_register*(name: cstring, width: gint, height: gint): TIconSize{.
    cdecl, dynlib: lib, importc: "gtk_icon_size_register".}
proc icon_size_register_alias*(alias: cstring, target: TIconSize){.cdecl,
    dynlib: lib, importc: "gtk_icon_size_register_alias".}
proc icon_size_from_name*(name: cstring): TIconSize{.cdecl, dynlib: lib,
    importc: "gtk_icon_size_from_name".}
proc icon_size_get_name*(size: TIconSize): cstring{.cdecl, dynlib: lib,
    importc: "gtk_icon_size_get_name".}
proc icon_set_get_type*(): GType{.cdecl, dynlib: lib,
                                  importc: "gtk_icon_set_get_type".}
proc icon_set_new*(): PIconSet{.cdecl, dynlib: lib, importc: "gtk_icon_set_new".}
proc icon_set_new_from_pixbuf*(pixbuf: gdk2pixbuf.PPixbuf): PIconSet{.cdecl,
    dynlib: lib, importc: "gtk_icon_set_new_from_pixbuf".}
proc reference*(icon_set: PIconSet): PIconSet{.cdecl, dynlib: lib,
    importc: "gtk_icon_set_ref".}
proc unref*(icon_set: PIconSet){.cdecl, dynlib: lib,
    importc: "gtk_icon_set_unref".}
proc copy*(icon_set: PIconSet): PIconSet{.cdecl, dynlib: lib,
    importc: "gtk_icon_set_copy".}
proc render_icon*(icon_set: PIconSet, style: PStyle,
                           direction: TTextDirection, state: TStateType,
                           size: TIconSize, widget: PWidget, detail: cstring): gdk2pixbuf.PPixbuf{.
    cdecl, dynlib: lib, importc: "gtk_icon_set_render_icon".}
proc add_source*(icon_set: PIconSet, source: PIconSource){.cdecl,
    dynlib: lib, importc: "gtk_icon_set_add_source".}
proc get_sizes*(icon_set: PIconSet, sizes: PPGtkIconSize,
                         n_sizes: pgint){.cdecl, dynlib: lib,
    importc: "gtk_icon_set_get_sizes".}
proc icon_source_get_type*(): GType{.cdecl, dynlib: lib,
                                     importc: "gtk_icon_source_get_type".}
proc icon_source_new*(): PIconSource{.cdecl, dynlib: lib,
                                      importc: "gtk_icon_source_new".}
proc copy*(source: PIconSource): PIconSource{.cdecl, dynlib: lib,
    importc: "gtk_icon_source_copy".}
proc free*(source: PIconSource){.cdecl, dynlib: lib,
    importc: "gtk_icon_source_free".}
proc set_filename*(source: PIconSource, filename: cstring){.cdecl,
    dynlib: lib, importc: "gtk_icon_source_set_filename".}
proc set_pixbuf*(source: PIconSource, pixbuf: gdk2pixbuf.PPixbuf){.cdecl,
    dynlib: lib, importc: "gtk_icon_source_set_pixbuf".}
proc get_filename*(source: PIconSource): cstring{.cdecl,
    dynlib: lib, importc: "gtk_icon_source_get_filename".}
proc get_pixbuf*(source: PIconSource): gdk2pixbuf.PPixbuf{.cdecl,
    dynlib: lib, importc: "gtk_icon_source_get_pixbuf".}
proc set_direction_wildcarded*(source: PIconSource,
    setting: gboolean){.cdecl, dynlib: lib,
                        importc: "gtk_icon_source_set_direction_wildcarded".}
proc set_state_wildcarded*(source: PIconSource, setting: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_icon_source_set_state_wildcarded".}
proc set_size_wildcarded*(source: PIconSource, setting: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_icon_source_set_size_wildcarded".}
proc get_size_wildcarded*(source: PIconSource): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_icon_source_get_size_wildcarded".}
proc get_state_wildcarded*(source: PIconSource): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_icon_source_get_state_wildcarded".}
proc get_direction_wildcarded*(source: PIconSource): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_icon_source_get_direction_wildcarded".}
proc set_direction*(source: PIconSource, direction: TTextDirection){.
    cdecl, dynlib: lib, importc: "gtk_icon_source_set_direction".}
proc set_state*(source: PIconSource, state: TStateType){.cdecl,
    dynlib: lib, importc: "gtk_icon_source_set_state".}
proc set_size*(source: PIconSource, size: TIconSize){.cdecl,
    dynlib: lib, importc: "gtk_icon_source_set_size".}
proc get_direction*(source: PIconSource): TTextDirection{.cdecl,
    dynlib: lib, importc: "gtk_icon_source_get_direction".}
proc get_state*(source: PIconSource): TStateType{.cdecl,
    dynlib: lib, importc: "gtk_icon_source_get_state".}
proc get_size*(source: PIconSource): TIconSize{.cdecl, dynlib: lib,
    importc: "gtk_icon_source_get_size".}
proc icon_set_invalidate_caches*(){.cdecl, dynlib: lib,
                                    importc: "_gtk_icon_set_invalidate_caches".}
proc icon_factory_list_ids*(): PGSList{.cdecl, dynlib: lib,
                                        importc: "_gtk_icon_factory_list_ids".}
proc TYPE_IMAGE*(): GType
proc IMAGE*(obj: pointer): PImage
proc IMAGE_CLASS*(klass: pointer): PImageClass
proc IS_IMAGE*(obj: pointer): bool
proc IS_IMAGE_CLASS*(klass: pointer): bool
proc IMAGE_GET_CLASS*(obj: pointer): PImageClass
proc image_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_image_get_type".}
proc image_new*(): PImage{.cdecl, dynlib: lib, importc: "gtk_image_new".}
proc image_new_from_pixmap*(pixmap: gdk2.PPixmap, mask: gdk2.PBitmap): PImage{.
    cdecl, dynlib: lib, importc: "gtk_image_new_from_pixmap".}
proc image_new_from_image*(image: gdk2.PImage, mask: gdk2.PBitmap): PImage{.cdecl,
    dynlib: lib, importc: "gtk_image_new_from_image".}
proc image_new_from_file*(filename: cstring): PImage{.cdecl, dynlib: lib,
    importc: "gtk_image_new_from_file".}
proc image_new_from_pixbuf*(pixbuf: gdk2pixbuf.PPixbuf): PImage{.cdecl, dynlib: lib,
    importc: "gtk_image_new_from_pixbuf".}
proc image_new_from_stock*(stock_id: cstring, size: TIconSize): PImage{.cdecl,
    dynlib: lib, importc: "gtk_image_new_from_stock".}
proc image_new_from_icon_set*(icon_set: PIconSet, size: TIconSize): PImage{.
    cdecl, dynlib: lib, importc: "gtk_image_new_from_icon_set".}
proc image_new_from_animation*(animation: gdk2pixbuf.PPixbufAnimation): PImage{.cdecl,
    dynlib: lib, importc: "gtk_image_new_from_animation".}
proc set_from_pixmap*(image: PImage, pixmap: gdk2.PPixmap, mask: gdk2.PBitmap){.
    cdecl, dynlib: lib, importc: "gtk_image_set_from_pixmap".}
proc set_from_image*(image: PImage, gdk_image: gdk2.PImage, mask: gdk2.PBitmap){.
    cdecl, dynlib: lib, importc: "gtk_image_set_from_image".}
proc set_from_file*(image: PImage, filename: cstring){.cdecl, dynlib: lib,
    importc: "gtk_image_set_from_file".}
proc set_from_pixbuf*(image: PImage, pixbuf: gdk2pixbuf.PPixbuf){.cdecl,
    dynlib: lib, importc: "gtk_image_set_from_pixbuf".}
proc set_from_stock*(image: PImage, stock_id: cstring, size: TIconSize){.
    cdecl, dynlib: lib, importc: "gtk_image_set_from_stock".}
proc set_from_icon_set*(image: PImage, icon_set: PIconSet, size: TIconSize){.
    cdecl, dynlib: lib, importc: "gtk_image_set_from_icon_set".}
proc set_from_animation*(image: PImage, animation: gdk2pixbuf.PPixbufAnimation){.
    cdecl, dynlib: lib, importc: "gtk_image_set_from_animation".}
proc get_storage_type*(image: PImage): TImageType{.cdecl, dynlib: lib,
    importc: "gtk_image_get_storage_type".}
proc get_pixbuf*(image: PImage): gdk2pixbuf.PPixbuf{.cdecl, dynlib: lib,
    importc: "gtk_image_get_pixbuf".}
proc get_stock*(image: PImage, stock_id: PPgchar, size: PIconSize){.cdecl,
    dynlib: lib, importc: "gtk_image_get_stock".}
proc get_animation*(image: PImage): gdk2pixbuf.PPixbufAnimation{.cdecl,
    dynlib: lib, importc: "gtk_image_get_animation".}
proc TYPE_IMAGE_MENU_ITEM*(): GType
proc IMAGE_MENU_ITEM*(obj: pointer): PImageMenuItem
proc IMAGE_MENU_ITEM_CLASS*(klass: pointer): PImageMenuItemClass
proc IS_IMAGE_MENU_ITEM*(obj: pointer): bool
proc IS_IMAGE_MENU_ITEM_CLASS*(klass: pointer): bool
proc IMAGE_MENU_ITEM_GET_CLASS*(obj: pointer): PImageMenuItemClass
proc image_menu_item_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_image_menu_item_get_type".}
proc image_menu_item_new*(): PImageMenuItem{.cdecl, dynlib: lib,
    importc: "gtk_image_menu_item_new".}
proc image_menu_item_new*(`label`: cstring): PImageMenuItem{.cdecl,
    dynlib: lib, importc: "gtk_image_menu_item_new_with_label".}
proc image_menu_item_new_with_mnemonic*(`label`: cstring): PImageMenuItem{.
    cdecl, dynlib: lib, importc: "gtk_image_menu_item_new_with_mnemonic".}
proc image_menu_item_new_from_stock*(stock_id: cstring, accel_group: PAccelGroup): PImageMenuItem{.
    cdecl, dynlib: lib, importc: "gtk_image_menu_item_new_from_stock".}
proc item_set_image*(image_menu_item: PImageMenuItem, image: PWidget){.
    cdecl, dynlib: lib, importc: "gtk_image_menu_item_set_image".}
proc item_get_image*(image_menu_item: PImageMenuItem): PWidget{.
    cdecl, dynlib: lib, importc: "gtk_image_menu_item_get_image".}
const
  bm_TGtkIMContextSimple_in_hex_sequence* = 0x0001'i16
  bp_TGtkIMContextSimple_in_hex_sequence* = 0'i16

proc TYPE_IM_CONTEXT_SIMPLE*(): GType
proc IM_CONTEXT_SIMPLE*(obj: pointer): PIMContextSimple
proc IM_CONTEXT_SIMPLE_CLASS*(klass: pointer): PIMContextSimpleClass
proc IS_IM_CONTEXT_SIMPLE*(obj: pointer): bool
proc IS_IM_CONTEXT_SIMPLE_CLASS*(klass: pointer): bool
proc IM_CONTEXT_SIMPLE_GET_CLASS*(obj: pointer): PIMContextSimpleClass
proc in_hex_sequence*(a: PIMContextSimple): guint
proc set_in_hex_sequence*(a: PIMContextSimple, `in_hex_sequence`: guint)
proc im_context_simple_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_im_context_simple_get_type".}
proc im_context_simple_new*(): PIMContext{.cdecl, dynlib: lib,
    importc: "gtk_im_context_simple_new".}
proc simple_add_table*(context_simple: PIMContextSimple,
                                  data: Pguint16, max_seq_len: gint,
                                  n_seqs: gint){.cdecl, dynlib: lib,
    importc: "gtk_im_context_simple_add_table".}
proc TYPE_IM_MULTICONTEXT*(): GType
proc IM_MULTICONTEXT*(obj: pointer): PIMMulticontext
proc IM_MULTICONTEXT_CLASS*(klass: pointer): PIMMulticontextClass
proc IS_IM_MULTICONTEXT*(obj: pointer): bool
proc IS_IM_MULTICONTEXT_CLASS*(klass: pointer): bool
proc IM_MULTICONTEXT_GET_CLASS*(obj: pointer): PIMMulticontextClass
proc im_multicontext_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_im_multicontext_get_type".}
proc im_multicontext_new*(): PIMContext{.cdecl, dynlib: lib,
    importc: "gtk_im_multicontext_new".}
proc append_menuitems*(context: PIMMulticontext,
                                       menushell: PMenuShell){.cdecl,
    dynlib: lib, importc: "gtk_im_multicontext_append_menuitems".}
proc TYPE_INPUT_DIALOG*(): GType
proc INPUT_DIALOG*(obj: pointer): PInputDialog
proc INPUT_DIALOG_CLASS*(klass: pointer): PInputDialogClass
proc IS_INPUT_DIALOG*(obj: pointer): bool
proc IS_INPUT_DIALOG_CLASS*(klass: pointer): bool
proc INPUT_DIALOG_GET_CLASS*(obj: pointer): PInputDialogClass
proc input_dialog_get_type*(): TType{.cdecl, dynlib: lib,
                                      importc: "gtk_input_dialog_get_type".}
proc input_dialog_new*(): PInputDialog{.cdecl, dynlib: lib,
                                        importc: "gtk_input_dialog_new".}
proc TYPE_INVISIBLE*(): GType
proc INVISIBLE*(obj: pointer): PInvisible
proc INVISIBLE_CLASS*(klass: pointer): PInvisibleClass
proc IS_INVISIBLE*(obj: pointer): bool
proc IS_INVISIBLE_CLASS*(klass: pointer): bool
proc INVISIBLE_GET_CLASS*(obj: pointer): PInvisibleClass
proc invisible_get_type*(): TType{.cdecl, dynlib: lib,
                                   importc: "gtk_invisible_get_type".}
proc invisible_new*(): PInvisible{.cdecl, dynlib: lib,
                                   importc: "gtk_invisible_new".}
proc invisible_new_for_screen*(screen: gdk2.PScreen): PInvisible{.cdecl,
    dynlib: lib, importc: "gtk_invisible_new_for_screen".}
proc set_screen*(invisible: PInvisible, screen: gdk2.PScreen){.cdecl,
    dynlib: lib, importc: "gtk_invisible_set_screen".}
proc get_screen*(invisible: PInvisible): gdk2.PScreen{.cdecl,
    dynlib: lib, importc: "gtk_invisible_get_screen".}
proc TYPE_ITEM_FACTORY*(): GType
proc ITEM_FACTORY*(anObject: pointer): PItemFactory
proc ITEM_FACTORY_CLASS*(klass: pointer): PItemFactoryClass
proc IS_ITEM_FACTORY*(anObject: pointer): bool
proc IS_ITEM_FACTORY_CLASS*(klass: pointer): bool
proc ITEM_FACTORY_GET_CLASS*(obj: pointer): PItemFactoryClass
proc item_factory_get_type*(): TType{.cdecl, dynlib: lib,
                                      importc: "gtk_item_factory_get_type".}
proc item_factory_new*(container_type: TType, path: cstring,
                       accel_group: PAccelGroup): PItemFactory{.cdecl,
    dynlib: lib, importc: "gtk_item_factory_new".}
proc construct*(ifactory: PItemFactory, container_type: TType,
                             path: cstring, accel_group: PAccelGroup){.cdecl,
    dynlib: lib, importc: "gtk_item_factory_construct".}
proc item_factory_add_foreign*(accel_widget: PWidget, full_path: cstring,
                               accel_group: PAccelGroup, keyval: guint,
                               modifiers: gdk2.TModifierType){.cdecl, dynlib: lib,
    importc: "gtk_item_factory_add_foreign".}
proc item_factory_from_widget*(widget: PWidget): PItemFactory{.cdecl,
    dynlib: lib, importc: "gtk_item_factory_from_widget".}
proc item_factory_path_from_widget*(widget: PWidget): cstring{.cdecl,
    dynlib: lib, importc: "gtk_item_factory_path_from_widget".}
proc get_item*(ifactory: PItemFactory, path: cstring): PWidget{.
    cdecl, dynlib: lib, importc: "gtk_item_factory_get_item".}
proc get_widget*(ifactory: PItemFactory, path: cstring): PWidget{.
    cdecl, dynlib: lib, importc: "gtk_item_factory_get_widget".}
proc get_widget_by_action*(ifactory: PItemFactory, action: guint): PWidget{.
    cdecl, dynlib: lib, importc: "gtk_item_factory_get_widget_by_action".}
proc get_item_by_action*(ifactory: PItemFactory, action: guint): PWidget{.
    cdecl, dynlib: lib, importc: "gtk_item_factory_get_item_by_action".}
proc create_item*(ifactory: PItemFactory, entry: PItemFactoryEntry,
                               callback_data: gpointer, callback_type: guint){.
    cdecl, dynlib: lib, importc: "gtk_item_factory_create_item".}
proc create_items*(ifactory: PItemFactory, n_entries: guint,
                                entries: PItemFactoryEntry,
                                callback_data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_item_factory_create_items".}
proc delete_item*(ifactory: PItemFactory, path: cstring){.cdecl,
    dynlib: lib, importc: "gtk_item_factory_delete_item".}
proc delete_entry*(ifactory: PItemFactory, entry: PItemFactoryEntry){.
    cdecl, dynlib: lib, importc: "gtk_item_factory_delete_entry".}
proc delete_entries*(ifactory: PItemFactory, n_entries: guint,
                                  entries: PItemFactoryEntry){.cdecl,
    dynlib: lib, importc: "gtk_item_factory_delete_entries".}
proc popup*(ifactory: PItemFactory, x: guint, y: guint,
                         mouse_button: guint, time: guint32){.cdecl,
    dynlib: lib, importc: "gtk_item_factory_popup".}
proc popup*(ifactory: PItemFactory, popup_data: gpointer,
                                   destroy: TDestroyNotify, x: guint, y: guint,
                                   mouse_button: guint, time: guint32){.cdecl,
    dynlib: lib, importc: "gtk_item_factory_popup_with_data".}
proc popup_data*(ifactory: PItemFactory): gpointer{.cdecl,
    dynlib: lib, importc: "gtk_item_factory_popup_data".}
proc item_factory_popup_data_from_widget*(widget: PWidget): gpointer{.cdecl,
    dynlib: lib, importc: "gtk_item_factory_popup_data_from_widget".}
proc set_translate_func*(ifactory: PItemFactory,
                                      fun: TTranslateFunc, data: gpointer,
                                      notify: TDestroyNotify){.cdecl,
    dynlib: lib, importc: "gtk_item_factory_set_translate_func".}
proc TYPE_LAYOUT*(): GType
proc LAYOUT*(obj: pointer): PLayout
proc LAYOUT_CLASS*(klass: pointer): PLayoutClass
proc IS_LAYOUT*(obj: pointer): bool
proc IS_LAYOUT_CLASS*(klass: pointer): bool
proc LAYOUT_GET_CLASS*(obj: pointer): PLayoutClass
proc layout_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_layout_get_type".}
proc layout_new*(hadjustment: PAdjustment, vadjustment: PAdjustment): PLayout{.
    cdecl, dynlib: lib, importc: "gtk_layout_new".}
proc put*(layout: PLayout, child_widget: PWidget, x: gint, y: gint){.
    cdecl, dynlib: lib, importc: "gtk_layout_put".}
proc move*(layout: PLayout, child_widget: PWidget, x: gint, y: gint){.
    cdecl, dynlib: lib, importc: "gtk_layout_move".}
proc set_size*(layout: PLayout, width: guint, height: guint){.cdecl,
    dynlib: lib, importc: "gtk_layout_set_size".}
proc get_size*(layout: PLayout, width: Pguint, height: Pguint){.cdecl,
    dynlib: lib, importc: "gtk_layout_get_size".}
proc get_hadjustment*(layout: PLayout): PAdjustment{.cdecl, dynlib: lib,
    importc: "gtk_layout_get_hadjustment".}
proc get_vadjustment*(layout: PLayout): PAdjustment{.cdecl, dynlib: lib,
    importc: "gtk_layout_get_vadjustment".}
proc set_hadjustment*(layout: PLayout, adjustment: PAdjustment){.cdecl,
    dynlib: lib, importc: "gtk_layout_set_hadjustment".}
proc set_vadjustment*(layout: PLayout, adjustment: PAdjustment){.cdecl,
    dynlib: lib, importc: "gtk_layout_set_vadjustment".}
const
  bm_TGtkList_selection_mode* = 0x0003'i16
  bp_TGtkList_selection_mode* = 0'i16
  bm_TGtkList_drag_selection* = 0x0004'i16
  bp_TGtkList_drag_selection* = 2'i16
  bm_TGtkList_add_mode* = 0x0008'i16
  bp_TGtkList_add_mode* = 3'i16

proc TYPE_LIST*(): GType
proc LIST*(obj: pointer): PList
proc LIST_CLASS*(klass: pointer): PListClass
proc IS_LIST*(obj: pointer): bool
proc IS_LIST_CLASS*(klass: pointer): bool
proc LIST_GET_CLASS*(obj: pointer): PListClass
proc selection_mode*(a: PList): guint
proc set_selection_mode*(a: PList, `selection_mode`: guint)
proc drag_selection*(a: PList): guint
proc set_drag_selection*(a: PList, `drag_selection`: guint)
proc add_mode*(a: PList): guint
proc set_add_mode*(a: PList, `add_mode`: guint)
proc list_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_list_get_type".}
proc list_new*(): PList{.cdecl, dynlib: lib, importc: "gtk_list_new".}
proc insert_items*(list: PList, items: PGList, position: gint){.cdecl,
    dynlib: lib, importc: "gtk_list_insert_items".}
proc append_items*(list: PList, items: PGList){.cdecl, dynlib: lib,
    importc: "gtk_list_append_items".}
proc prepend_items*(list: PList, items: PGList){.cdecl, dynlib: lib,
    importc: "gtk_list_prepend_items".}
proc remove_items*(list: PList, items: PGList){.cdecl, dynlib: lib,
    importc: "gtk_list_remove_items".}
proc remove_items_no_unref*(list: PList, items: PGList){.cdecl,
    dynlib: lib, importc: "gtk_list_remove_items_no_unref".}
proc clear_items*(list: PList, start: gint, theEnd: gint){.cdecl,
    dynlib: lib, importc: "gtk_list_clear_items".}
proc select_item*(list: PList, item: gint){.cdecl, dynlib: lib,
    importc: "gtk_list_select_item".}
proc unselect_item*(list: PList, item: gint){.cdecl, dynlib: lib,
    importc: "gtk_list_unselect_item".}
proc select_child*(list: PList, child: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_list_select_child".}
proc unselect_child*(list: PList, child: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_list_unselect_child".}
proc child_position*(list: PList, child: PWidget): gint{.cdecl,
    dynlib: lib, importc: "gtk_list_child_position".}
proc set_selection_mode*(list: PList, mode: TSelectionMode){.cdecl,
    dynlib: lib, importc: "gtk_list_set_selection_mode".}
proc extend_selection*(list: PList, scroll_type: TScrollType,
                            position: gfloat, auto_start_selection: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_list_extend_selection".}
proc start_selection*(list: PList){.cdecl, dynlib: lib,
    importc: "gtk_list_start_selection".}
proc end_selection*(list: PList){.cdecl, dynlib: lib,
                                       importc: "gtk_list_end_selection".}
proc select_all*(list: PList){.cdecl, dynlib: lib,
                                    importc: "gtk_list_select_all".}
proc unselect_all*(list: PList){.cdecl, dynlib: lib,
                                      importc: "gtk_list_unselect_all".}
proc scroll_horizontal*(list: PList, scroll_type: TScrollType,
                             position: gfloat){.cdecl, dynlib: lib,
    importc: "gtk_list_scroll_horizontal".}
proc scroll_vertical*(list: PList, scroll_type: TScrollType,
                           position: gfloat){.cdecl, dynlib: lib,
    importc: "gtk_list_scroll_vertical".}
proc toggle_add_mode*(list: PList){.cdecl, dynlib: lib,
    importc: "gtk_list_toggle_add_mode".}
proc toggle_focus_row*(list: PList){.cdecl, dynlib: lib,
    importc: "gtk_list_toggle_focus_row".}
proc toggle_row*(list: PList, item: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_list_toggle_row".}
proc undo_selection*(list: PList){.cdecl, dynlib: lib,
                                        importc: "gtk_list_undo_selection".}
proc end_drag_selection*(list: PList){.cdecl, dynlib: lib,
    importc: "gtk_list_end_drag_selection".}
const
  TREE_MODEL_ITERS_PERSIST* = 1 shl 0
  TREE_MODEL_LIST_ONLY* = 1 shl 1

proc TYPE_TREE_MODEL*(): GType
proc TREE_MODEL*(obj: pointer): PTreeModel
proc IS_TREE_MODEL*(obj: pointer): bool
proc TREE_MODEL_GET_IFACE*(obj: pointer): PTreeModelIface
proc TYPE_TREE_ITER*(): GType
proc TYPE_TREE_PATH*(): GType
proc tree_path_new*(): PTreePath{.cdecl, dynlib: lib,
                                  importc: "gtk_tree_path_new".}
proc tree_path_new_from_string*(path: cstring): PTreePath{.cdecl, dynlib: lib,
    importc: "gtk_tree_path_new_from_string".}
proc to_string*(path: PTreePath): cstring{.cdecl, dynlib: lib,
    importc: "gtk_tree_path_to_string".}
proc tree_path_new_root*(): PTreePath
proc tree_path_new_first*(): PTreePath{.cdecl, dynlib: lib,
                                        importc: "gtk_tree_path_new_first".}
proc append_index*(path: PTreePath, index: gint){.cdecl, dynlib: lib,
    importc: "gtk_tree_path_append_index".}
proc prepend_index*(path: PTreePath, index: gint){.cdecl, dynlib: lib,
    importc: "gtk_tree_path_prepend_index".}
proc get_depth*(path: PTreePath): gint{.cdecl, dynlib: lib,
    importc: "gtk_tree_path_get_depth".}
proc get_indices*(path: PTreePath): Pgint{.cdecl, dynlib: lib,
    importc: "gtk_tree_path_get_indices".}
proc free*(path: PTreePath){.cdecl, dynlib: lib,
                                       importc: "gtk_tree_path_free".}
proc copy*(path: PTreePath): PTreePath{.cdecl, dynlib: lib,
    importc: "gtk_tree_path_copy".}
proc tree_path_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "gtk_tree_path_get_type".}
proc compare*(a: PTreePath, b: PTreePath): gint{.cdecl, dynlib: lib,
    importc: "gtk_tree_path_compare".}
proc next*(path: PTreePath){.cdecl, dynlib: lib,
                                       importc: "gtk_tree_path_next".}
proc prev*(path: PTreePath): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_tree_path_prev".}
proc up*(path: PTreePath): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_tree_path_up".}
proc down*(path: PTreePath){.cdecl, dynlib: lib,
                                       importc: "gtk_tree_path_down".}
proc is_ancestor*(path: PTreePath, descendant: PTreePath): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_path_is_ancestor".}
proc is_descendant*(path: PTreePath, ancestor: PTreePath): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_path_is_descendant".}
proc row_reference_new*(model: PTreeModel, path: PTreePath): PTreeRowReference{.
    cdecl, dynlib: lib, importc: "gtk_tree_row_reference_new".}
proc tree_row_reference_new_proxy*(proxy: PGObject, model: PTreeModel,
                                   path: PTreePath): PTreeRowReference{.cdecl,
    dynlib: lib, importc: "gtk_tree_row_reference_new_proxy".}
proc reference_get_path*(reference: PTreeRowReference): PTreePath{.
    cdecl, dynlib: lib, importc: "gtk_tree_row_reference_get_path".}
proc reference_valid*(reference: PTreeRowReference): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_tree_row_reference_valid".}
proc reference_free*(reference: PTreeRowReference){.cdecl, dynlib: lib,
    importc: "gtk_tree_row_reference_free".}
proc tree_row_reference_inserted*(proxy: PGObject, path: PTreePath){.cdecl,
    dynlib: lib, importc: "gtk_tree_row_reference_inserted".}
proc tree_row_reference_deleted*(proxy: PGObject, path: PTreePath){.cdecl,
    dynlib: lib, importc: "gtk_tree_row_reference_deleted".}
proc tree_row_reference_reordered*(proxy: PGObject, path: PTreePath,
                                   iter: PTreeIter, new_order: Pgint){.cdecl,
    dynlib: lib, importc: "gtk_tree_row_reference_reordered".}
proc copy*(iter: PTreeIter): PTreeIter{.cdecl, dynlib: lib,
    importc: "gtk_tree_iter_copy".}
proc free*(iter: PTreeIter){.cdecl, dynlib: lib,
                                       importc: "gtk_tree_iter_free".}
proc tree_iter_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "gtk_tree_iter_get_type".}
proc tree_model_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_tree_model_get_type".}
proc get_flags*(tree_model: PTreeModel): TTreeModelFlags{.cdecl,
    dynlib: lib, importc: "gtk_tree_model_get_flags".}
proc get_n_columns*(tree_model: PTreeModel): gint{.cdecl,
    dynlib: lib, importc: "gtk_tree_model_get_n_columns".}
proc get_column_type*(tree_model: PTreeModel, index: gint): GType{.
    cdecl, dynlib: lib, importc: "gtk_tree_model_get_column_type".}
proc get_iter*(tree_model: PTreeModel, iter: PTreeIter,
                          path: PTreePath): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_tree_model_get_iter".}
proc get_iter_from_string*(tree_model: PTreeModel, iter: PTreeIter,
                                      path_string: cstring): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_tree_model_get_iter_from_string".}
proc get_iter_root*(tree_model: PTreeModel, iter: PTreeIter): gboolean
proc get_iter_first*(tree_model: PTreeModel, iter: PTreeIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_model_get_iter_first".}
proc get_path*(tree_model: PTreeModel, iter: PTreeIter): PTreePath{.
    cdecl, dynlib: lib, importc: "gtk_tree_model_get_path".}
proc get_value*(tree_model: PTreeModel, iter: PTreeIter,
                           column: gint, value: PGValue){.cdecl, dynlib: lib,
    importc: "gtk_tree_model_get_value".}
proc iter_next*(tree_model: PTreeModel, iter: PTreeIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_model_iter_next".}
proc iter_children*(tree_model: PTreeModel, iter: PTreeIter,
                               parent: PTreeIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_tree_model_iter_children".}
proc iter_has_child*(tree_model: PTreeModel, iter: PTreeIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_model_iter_has_child".}
proc iter_n_children*(tree_model: PTreeModel, iter: PTreeIter): gint{.
    cdecl, dynlib: lib, importc: "gtk_tree_model_iter_n_children".}
proc iter_nth_child*(tree_model: PTreeModel, iter: PTreeIter,
                                parent: PTreeIter, n: gint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_tree_model_iter_nth_child".}
proc iter_parent*(tree_model: PTreeModel, iter: PTreeIter,
                             child: PTreeIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_tree_model_iter_parent".}
proc get_string_from_iter*(tree_model: PTreeModel, iter: PTreeIter):
    cstring{.cdecl, dynlib: lib,
             importc: "gtk_tree_model_get_string_from_iter".}
proc ref_node*(tree_model: PTreeModel, iter: PTreeIter){.cdecl,
    dynlib: lib, importc: "gtk_tree_model_ref_node".}
proc unref_node*(tree_model: PTreeModel, iter: PTreeIter){.cdecl,
    dynlib: lib, importc: "gtk_tree_model_unref_node".}
proc foreach*(model: PTreeModel, fun: TTreeModelForeachFunc,
                         user_data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_tree_model_foreach".}
proc row_changed*(tree_model: PTreeModel, path: PTreePath,
                             iter: PTreeIter){.cdecl, dynlib: lib,
    importc: "gtk_tree_model_row_changed".}
proc row_inserted*(tree_model: PTreeModel, path: PTreePath,
                              iter: PTreeIter){.cdecl, dynlib: lib,
    importc: "gtk_tree_model_row_inserted".}
proc row_has_child_toggled*(tree_model: PTreeModel, path: PTreePath,
                                       iter: PTreeIter){.cdecl, dynlib: lib,
    importc: "gtk_tree_model_row_has_child_toggled".}
proc row_deleted*(tree_model: PTreeModel, path: PTreePath){.cdecl,
    dynlib: lib, importc: "gtk_tree_model_row_deleted".}
proc rows_reordered*(tree_model: PTreeModel, path: PTreePath,
                                iter: PTreeIter, new_order: Pgint){.cdecl,
    dynlib: lib, importc: "gtk_tree_model_rows_reordered".}
const
  TREE_SORTABLE_DEFAULT_SORT_COLUMN_ID* = - (1)

proc TYPE_TREE_SORTABLE*(): GType
proc TREE_SORTABLE*(obj: pointer): PTreeSortable
proc TREE_SORTABLE_CLASS*(obj: pointer): PTreeSortableIface
proc IS_TREE_SORTABLE*(obj: pointer): bool
proc TREE_SORTABLE_GET_IFACE*(obj: pointer): PTreeSortableIface
proc tree_sortable_get_type*(): GType{.cdecl, dynlib: lib,
                                       importc: "gtk_tree_sortable_get_type".}
proc sort_column_changed*(sortable: PTreeSortable){.cdecl,
    dynlib: lib, importc: "gtk_tree_sortable_sort_column_changed".}
proc get_sort_column_id*(sortable: PTreeSortable,
                                       sort_column_id: Pgint, order: PSortType): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_sortable_get_sort_column_id".}
proc set_sort_column_id*(sortable: PTreeSortable,
                                       sort_column_id: gint, order: TSortType){.
    cdecl, dynlib: lib, importc: "gtk_tree_sortable_set_sort_column_id".}
proc set_sort_func*(sortable: PTreeSortable, sort_column_id: gint,
                                  sort_func: TTreeIterCompareFunc,
                                  user_data: gpointer, destroy: TDestroyNotify){.
    cdecl, dynlib: lib, importc: "gtk_tree_sortable_set_sort_func".}
proc set_default_sort_func*(sortable: PTreeSortable,
    sort_func: TTreeIterCompareFunc, user_data: gpointer,
    destroy: TDestroyNotify){.cdecl, dynlib: lib, importc: "gtk_tree_sortable_set_default_sort_func".}
proc has_default_sort_func*(sortable: PTreeSortable): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_sortable_has_default_sort_func".}
proc TYPE_TREE_MODEL_SORT*(): GType
proc TREE_MODEL_SORT*(obj: pointer): PTreeModelSort
proc TREE_MODEL_SORT_CLASS*(klass: pointer): PTreeModelSortClass
proc IS_TREE_MODEL_SORT*(obj: pointer): bool
proc IS_TREE_MODEL_SORT_CLASS*(klass: pointer): bool
proc TREE_MODEL_SORT_GET_CLASS*(obj: pointer): PTreeModelSortClass
proc tree_model_sort_get_type*(): GType{.cdecl, dynlib: lib,
    importc: "gtk_tree_model_sort_get_type".}
proc sort_new*(child_model: PTreeModel): PTreeModel{.
    cdecl, dynlib: lib, importc: "gtk_tree_model_sort_new_with_model".}
proc sort_get_model*(tree_model: PTreeModelSort): PTreeModel{.cdecl,
    dynlib: lib, importc: "gtk_tree_model_sort_get_model".}
proc tree_model_sort_convert_child_path_to_path*(
    tree_model_sort: PTreeModelSort, child_path: PTreePath): PTreePath{.cdecl,
    dynlib: lib, importc: "gtk_tree_model_sort_convert_child_path_to_path".}
proc tree_model_sort_convert_child_iter_to_iter*(
    tree_model_sort: PTreeModelSort, sort_iter: PTreeIter, child_iter: PTreeIter){.
    cdecl, dynlib: lib,
    importc: "gtk_tree_model_sort_convert_child_iter_to_iter".}
proc tree_model_sort_convert_path_to_child_path*(
    tree_model_sort: PTreeModelSort, sorted_path: PTreePath): PTreePath{.cdecl,
    dynlib: lib, importc: "gtk_tree_model_sort_convert_path_to_child_path".}
proc tree_model_sort_convert_iter_to_child_iter*(
    tree_model_sort: PTreeModelSort, child_iter: PTreeIter,
    sorted_iter: PTreeIter){.cdecl, dynlib: lib, importc: "gtk_tree_model_sort_convert_iter_to_child_iter".}
proc sort_reset_default_sort_func*(tree_model_sort: PTreeModelSort){.
    cdecl, dynlib: lib, importc: "gtk_tree_model_sort_reset_default_sort_func".}
proc sort_clear_cache*(tree_model_sort: PTreeModelSort){.cdecl,
    dynlib: lib, importc: "gtk_tree_model_sort_clear_cache".}
const
  bm_TGtkListStore_columns_dirty* = 0x0001'i16
  bp_TGtkListStore_columns_dirty* = 0'i16

proc TYPE_LIST_STORE*(): GType
proc LIST_STORE*(obj: pointer): PListStore
proc LIST_STORE_CLASS*(klass: pointer): PListStoreClass
proc IS_LIST_STORE*(obj: pointer): bool
proc IS_LIST_STORE_CLASS*(klass: pointer): bool
proc LIST_STORE_GET_CLASS*(obj: pointer): PListStoreClass
proc columns_dirty*(a: PListStore): guint
proc set_columns_dirty*(a: PListStore, `columns_dirty`: guint)
proc list_store_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_list_store_get_type".}
proc list_store_newv*(n_columns: gint, types: PGType): PListStore{.cdecl,
    dynlib: lib, importc: "gtk_list_store_newv".}
proc set_column_types*(list_store: PListStore, n_columns: gint,
                                  types: PGType){.cdecl, dynlib: lib,
    importc: "gtk_list_store_set_column_types".}
proc set_value*(list_store: PListStore, iter: PTreeIter,
                           column: gint, value: PGValue){.cdecl, dynlib: lib,
    importc: "gtk_list_store_set_value".}
proc remove*(list_store: PListStore, iter: PTreeIter){.cdecl,
    dynlib: lib, importc: "gtk_list_store_remove".}
proc insert*(list_store: PListStore, iter: PTreeIter, position: gint){.
    cdecl, dynlib: lib, importc: "gtk_list_store_insert".}
proc insert_before*(list_store: PListStore, iter: PTreeIter,
                               sibling: PTreeIter){.cdecl, dynlib: lib,
    importc: "gtk_list_store_insert_before".}
proc insert_after*(list_store: PListStore, iter: PTreeIter,
                              sibling: PTreeIter){.cdecl, dynlib: lib,
    importc: "gtk_list_store_insert_after".}
proc prepend*(list_store: PListStore, iter: PTreeIter){.cdecl,
    dynlib: lib, importc: "gtk_list_store_prepend".}
proc append*(list_store: PListStore, iter: PTreeIter){.cdecl,
    dynlib: lib, importc: "gtk_list_store_append".}
proc clear*(list_store: PListStore){.cdecl, dynlib: lib,
    importc: "gtk_list_store_clear".}
when false:
  const
    PRIORITY_RESIZE* = G_PRIORITY_HIGH_IDLE + 10
proc check_version*(required_major: guint, required_minor: guint,
                    required_micro: guint): cstring{.cdecl, dynlib: lib,
    importc: "gtk_check_version".}
proc disable_setlocale*(){.cdecl, dynlib: lib, importc: "gtk_disable_setlocale".}
proc set_locale*(): cstring{.cdecl, dynlib: lib, importc: "gtk_set_locale".}
proc get_default_language*(): pango.PLanguage{.cdecl, dynlib: lib,
    importc: "gtk_get_default_language".}
proc events_pending*(): gint{.cdecl, dynlib: lib, importc: "gtk_events_pending".}
proc main_do_event*(event: gdk2.PEvent){.cdecl, dynlib: lib,
                                       importc: "gtk_main_do_event".}
proc main*(){.cdecl, dynlib: lib, importc: "gtk_main".}
proc init*(argc, argv: pointer){.cdecl, dynlib: lib, importc: "gtk_init".}
proc main_level*(): guint{.cdecl, dynlib: lib, importc: "gtk_main_level".}
proc main_quit*(){.cdecl, dynlib: lib, importc: "gtk_main_quit".}
proc main_iteration*(): gboolean{.cdecl, dynlib: lib,
                                  importc: "gtk_main_iteration".}
proc main_iteration_do*(blocking: gboolean): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_main_iteration_do".}
proc gtkTrue*(): gboolean{.cdecl, dynlib: lib, importc: "gtk_true".}
proc gtkFalse*(): gboolean{.cdecl, dynlib: lib, importc: "gtk_false".}
proc grab_add*(widget: PWidget){.cdecl, dynlib: lib, importc: "gtk_grab_add".}
proc grab_get_current*(): PWidget{.cdecl, dynlib: lib,
                                   importc: "gtk_grab_get_current".}
proc grab_remove*(widget: PWidget){.cdecl, dynlib: lib,
                                    importc: "gtk_grab_remove".}
proc init_add*(`function`: TFunction, data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_init_add".}
proc quit_add_destroy*(main_level: guint, anObject: PObject){.cdecl,
    dynlib: lib, importc: "gtk_quit_add_destroy".}
proc quit_add*(main_level: guint, `function`: TFunction, data: gpointer): guint{.
    cdecl, dynlib: lib, importc: "gtk_quit_add".}
proc quit_add_full*(main_level: guint, `function`: TFunction,
                    marshal: TCallbackMarshal, data: gpointer,
                    destroy: TDestroyNotify): guint{.cdecl, dynlib: lib,
    importc: "gtk_quit_add_full".}
proc quit_remove*(quit_handler_id: guint){.cdecl, dynlib: lib,
    importc: "gtk_quit_remove".}
proc quit_remove_by_data*(data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_quit_remove_by_data".}
proc timeout_add*(interval: guint32, `function`: TFunction, data: gpointer): guint{.
    cdecl, dynlib: lib, importc: "gtk_timeout_add".}
proc timeout_add_full*(interval: guint32, `function`: TFunction,
                       marshal: TCallbackMarshal, data: gpointer,
                       destroy: TDestroyNotify): guint{.cdecl, dynlib: lib,
    importc: "gtk_timeout_add_full".}
proc timeout_remove*(timeout_handler_id: guint){.cdecl, dynlib: lib,
    importc: "gtk_timeout_remove".}
proc idle_add*(`function`: TFunction, data: gpointer): guint{.cdecl,
    dynlib: lib, importc: "gtk_idle_add".}
proc idle_add_priority*(priority: gint, `function`: TFunction, data: gpointer): guint{.
    cdecl, dynlib: lib, importc: "gtk_idle_add_priority".}
proc idle_add_full*(priority: gint, `function`: TFunction,
                    marshal: TCallbackMarshal, data: gpointer,
                    destroy: TDestroyNotify): guint{.cdecl, dynlib: lib,
    importc: "gtk_idle_add_full".}
proc idle_remove*(idle_handler_id: guint){.cdecl, dynlib: lib,
    importc: "gtk_idle_remove".}
proc idle_remove_by_data*(data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_idle_remove_by_data".}
proc input_add_full*(source: gint, condition: gdk2.TInputCondition,
                     `function`: gdk2.TInputFunction, marshal: TCallbackMarshal,
                     data: gpointer, destroy: TDestroyNotify): guint{.cdecl,
    dynlib: lib, importc: "gtk_input_add_full".}
proc input_remove*(input_handler_id: guint){.cdecl, dynlib: lib,
    importc: "gtk_input_remove".}
proc key_snooper_install*(snooper: TKeySnoopFunc, func_data: gpointer): guint{.
    cdecl, dynlib: lib, importc: "gtk_key_snooper_install".}
proc key_snooper_remove*(snooper_handler_id: guint){.cdecl, dynlib: lib,
    importc: "gtk_key_snooper_remove".}
proc get_current_event*(): gdk2.PEvent{.cdecl, dynlib: lib,
                                      importc: "gtk_get_current_event".}
proc get_current_event_time*(): guint32{.cdecl, dynlib: lib,
    importc: "gtk_get_current_event_time".}
proc get_current_event_state*(state: gdk2.PModifierType): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_get_current_event_state".}
proc get_event_widget*(event: gdk2.PEvent): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_get_event_widget".}
proc propagate_event*(widget: PWidget, event: gdk2.PEvent){.cdecl, dynlib: lib,
    importc: "gtk_propagate_event".}
proc boolean_handled_accumulator*(ihint: PGSignalInvocationHint,
                                  return_accu: PGValue, handler_return: PGValue,
                                  dummy: gpointer): gboolean{.cdecl,
    dynlib: lib, importc: "_gtk_boolean_handled_accumulator".}
proc find_module*(name: cstring, thetype: cstring): cstring{.cdecl, dynlib: lib,
    importc: "_gtk_find_module".}
proc get_module_path*(thetype: cstring): PPgchar{.cdecl, dynlib: lib,
    importc: "_gtk_get_module_path".}
proc TYPE_MENU_BAR*(): GType
proc MENU_BAR*(obj: pointer): PMenuBar
proc MENU_BAR_CLASS*(klass: pointer): PMenuBarClass
proc IS_MENU_BAR*(obj: pointer): bool
proc IS_MENU_BAR_CLASS*(klass: pointer): bool
proc MENU_BAR_GET_CLASS*(obj: pointer): PMenuBarClass
proc menu_bar_get_type*(): TType{.cdecl, dynlib: lib,
                                  importc: "gtk_menu_bar_get_type".}
proc menu_bar_new*(): PMenuBar{.cdecl, dynlib: lib, importc: "gtk_menu_bar_new".}
proc cycle_focus*(menubar: PMenuBar, dir: TDirectionType){.cdecl,
    dynlib: lib, importc: "_gtk_menu_bar_cycle_focus".}
proc TYPE_MESSAGE_DIALOG*(): GType
proc MESSAGE_DIALOG*(obj: pointer): PMessageDialog
proc MESSAGE_DIALOG_CLASS*(klass: pointer): PMessageDialogClass
proc IS_MESSAGE_DIALOG*(obj: pointer): bool
proc IS_MESSAGE_DIALOG_CLASS*(klass: pointer): bool
proc MESSAGE_DIALOG_GET_CLASS*(obj: pointer): PMessageDialogClass
proc message_dialog_get_type*(): TType{.cdecl, dynlib: lib,
                                        importc: "gtk_message_dialog_get_type".}
const
  bm_TGtkNotebook_show_tabs* = 0x0001'i16
  bp_TGtkNotebook_show_tabs* = 0'i16
  bm_TGtkNotebook_homogeneous* = 0x0002'i16
  bp_TGtkNotebook_homogeneous* = 1'i16
  bm_TGtkNotebook_show_border* = 0x0004'i16
  bp_TGtkNotebook_show_border* = 2'i16
  bm_TGtkNotebook_tab_pos* = 0x0018'i16
  bp_TGtkNotebook_tab_pos* = 3'i16
  bm_TGtkNotebook_scrollable* = 0x0020'i16
  bp_TGtkNotebook_scrollable* = 5'i16
  bm_TGtkNotebook_in_child* = 0x00C0'i16
  bp_TGtkNotebook_in_child* = 6'i16
  bm_TGtkNotebook_click_child* = 0x0300'i16
  bp_TGtkNotebook_click_child* = 8'i16
  bm_TGtkNotebook_button* = 0x0C00'i16
  bp_TGtkNotebook_button* = 10'i16
  bm_TGtkNotebook_need_timer* = 0x1000'i16
  bp_TGtkNotebook_need_timer* = 12'i16
  bm_TGtkNotebook_child_has_focus* = 0x2000'i16
  bp_TGtkNotebook_child_has_focus* = 13'i16
  bm_TGtkNotebook_have_visible_child* = 0x4000'i16
  bp_TGtkNotebook_have_visible_child* = 14'i16
  bm_TGtkNotebook_focus_out* = 0x8000'i16
  bp_TGtkNotebook_focus_out* = 15'i16

proc TYPE_NOTEBOOK*(): GType
proc NOTEBOOK*(obj: pointer): PNotebook
proc NOTEBOOK_CLASS*(klass: pointer): PNotebookClass
proc IS_NOTEBOOK*(obj: pointer): bool
proc IS_NOTEBOOK_CLASS*(klass: pointer): bool
proc NOTEBOOK_GET_CLASS*(obj: pointer): PNotebookClass
proc show_tabs*(a: PNotebook): guint
proc set_show_tabs*(a: PNotebook, `show_tabs`: guint)
proc homogeneous*(a: PNotebook): guint
proc set_homogeneous*(a: PNotebook, `homogeneous`: guint)
proc show_border*(a: PNotebook): guint
proc set_show_border*(a: PNotebook, `show_border`: guint)
proc tab_pos*(a: PNotebook): guint
proc scrollable*(a: PNotebook): guint
proc set_scrollable*(a: PNotebook, `scrollable`: guint)
proc in_child*(a: PNotebook): guint
proc set_in_child*(a: PNotebook, `in_child`: guint)
proc click_child*(a: PNotebook): guint
proc set_click_child*(a: PNotebook, `click_child`: guint)
proc button*(a: PNotebook): guint
proc set_button*(a: PNotebook, `button`: guint)
proc need_timer*(a: PNotebook): guint
proc set_need_timer*(a: PNotebook, `need_timer`: guint)
proc child_has_focus*(a: PNotebook): guint
proc set_child_has_focus*(a: PNotebook, `child_has_focus`: guint)
proc have_visible_child*(a: PNotebook): guint
proc set_have_visible_child*(a: PNotebook, `have_visible_child`: guint)
proc focus_out*(a: PNotebook): guint
proc set_focus_out*(a: PNotebook, `focus_out`: guint)
proc notebook_get_type*(): TType{.cdecl, dynlib: lib,
                                  importc: "gtk_notebook_get_type".}
proc notebook_new*(): PNotebook{.cdecl, dynlib: lib, importc: "gtk_notebook_new".}
proc append_page*(notebook: PNotebook, child: PWidget,
                           tab_label: PWidget): gint{.cdecl, dynlib: lib,
    importc: "gtk_notebook_append_page".}
proc append_page_menu*(notebook: PNotebook, child: PWidget,
                                tab_label: PWidget, menu_label: PWidget): gint{.
    cdecl, dynlib: lib, importc: "gtk_notebook_append_page_menu".}
proc prepend_page*(notebook: PNotebook, child: PWidget,
                            tab_label: PWidget): gint{.cdecl, dynlib: lib,
    importc: "gtk_notebook_prepend_page".}
proc prepend_page_menu*(notebook: PNotebook, child: PWidget,
                                 tab_label: PWidget, menu_label: PWidget): gint{.
    cdecl, dynlib: lib, importc: "gtk_notebook_prepend_page_menu".}
proc insert_page*(notebook: PNotebook, child: PWidget,
                           tab_label: PWidget, position: gint): gint{.cdecl,
    dynlib: lib, importc: "gtk_notebook_insert_page".}
proc insert_page_menu*(notebook: PNotebook, child: PWidget,
                                tab_label: PWidget, menu_label: PWidget,
                                position: gint): gint{.cdecl, dynlib: lib,
    importc: "gtk_notebook_insert_page_menu".}
proc remove_page*(notebook: PNotebook, page_num: gint){.cdecl,
    dynlib: lib, importc: "gtk_notebook_remove_page".}
proc get_current_page*(notebook: PNotebook): gint{.cdecl, dynlib: lib,
    importc: "gtk_notebook_get_current_page".}
proc get_n_pages*(notebook: PNotebook): gint{.cdecl, dynlib: lib,
    importc: "gtk_notebook_get_n_pages".}
proc get_nth_page*(notebook: PNotebook, page_num: gint): PWidget{.
    cdecl, dynlib: lib, importc: "gtk_notebook_get_nth_page".}
proc page_num*(notebook: PNotebook, child: PWidget): gint{.cdecl,
    dynlib: lib, importc: "gtk_notebook_page_num".}
proc set_current_page*(notebook: PNotebook, page_num: gint){.cdecl,
    dynlib: lib, importc: "gtk_notebook_set_current_page".}
proc next_page*(notebook: PNotebook){.cdecl, dynlib: lib,
    importc: "gtk_notebook_next_page".}
proc prev_page*(notebook: PNotebook){.cdecl, dynlib: lib,
    importc: "gtk_notebook_prev_page".}
proc set_show_border*(notebook: PNotebook, show_border: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_notebook_set_show_border".}
proc get_show_border*(notebook: PNotebook): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_notebook_get_show_border".}
proc set_show_tabs*(notebook: PNotebook, show_tabs: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_notebook_set_show_tabs".}
proc get_show_tabs*(notebook: PNotebook): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_notebook_get_show_tabs".}
#proc set_tab_pos*(notebook: PNotebook, pos: TPositionType){.cdecl,
#    dynlib: lib, importc: "gtk_notebook_set_tab_pos".}
proc get_tab_pos*(notebook: PNotebook): TPositionType{.cdecl,
    dynlib: lib, importc: "gtk_notebook_get_tab_pos".}
proc set_scrollable*(notebook: PNotebook, scrollable: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_notebook_set_scrollable".}
proc get_scrollable*(notebook: PNotebook): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_notebook_get_scrollable".}
proc set_tab_reorderable*(notebook: PNotebook, child: PWidget, b: bool){.cdecl,
    dynlib: lib, importc: "gtk_notebook_set_tab_reorderable".}
proc get_tab_reorderable*(notebook: PNotebook, child: PWidget): bool {.cdecl,
    dynlib: lib, importc: "gtk_notebook_get_tab_reorderable".}
proc popup_enable*(notebook: PNotebook){.cdecl, dynlib: lib,
    importc: "gtk_notebook_popup_enable".}
proc popup_disable*(notebook: PNotebook){.cdecl, dynlib: lib,
    importc: "gtk_notebook_popup_disable".}
proc get_tab_label*(notebook: PNotebook, child: PWidget): PWidget{.
    cdecl, dynlib: lib, importc: "gtk_notebook_get_tab_label".}
proc set_tab_label*(notebook: PNotebook, child: PWidget,
                             tab_label: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_notebook_set_tab_label".}
proc set_tab_label_text*(notebook: PNotebook, child: PWidget,
                                  tab_text: cstring){.cdecl, dynlib: lib,
    importc: "gtk_notebook_set_tab_label_text".}
proc get_tab_label_text*(notebook: PNotebook, child: PWidget): cstring{.
    cdecl, dynlib: lib, importc: "gtk_notebook_get_tab_label_text".}
proc get_menu_label*(notebook: PNotebook, child: PWidget): PWidget{.
    cdecl, dynlib: lib, importc: "gtk_notebook_get_menu_label".}
proc set_menu_label*(notebook: PNotebook, child: PWidget,
                              menu_label: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_notebook_set_menu_label".}
proc set_menu_label_text*(notebook: PNotebook, child: PWidget,
                                   menu_text: cstring){.cdecl, dynlib: lib,
    importc: "gtk_notebook_set_menu_label_text".}
proc get_menu_label_text*(notebook: PNotebook, child: PWidget): cstring{.
    cdecl, dynlib: lib, importc: "gtk_notebook_get_menu_label_text".}
proc query_tab_label_packing*(notebook: PNotebook, child: PWidget,
                                       expand: Pgboolean, fill: Pgboolean,
                                       pack_type: PPackType){.cdecl,
    dynlib: lib, importc: "gtk_notebook_query_tab_label_packing".}
proc set_tab_label_packing*(notebook: PNotebook, child: PWidget,
                                     expand: gboolean, fill: gboolean,
                                     pack_type: TPackType){.cdecl, dynlib: lib,
    importc: "gtk_notebook_set_tab_label_packing".}
proc reorder_child*(notebook: PNotebook, child: PWidget, position: gint){.
    cdecl, dynlib: lib, importc: "gtk_notebook_reorder_child".}
const
  bm_TGtkOldEditable_has_selection* = 0x0001'i16
  bp_TGtkOldEditable_has_selection* = 0'i16
  bm_TGtkOldEditable_editable* = 0x0002'i16
  bp_TGtkOldEditable_editable* = 1'i16
  bm_TGtkOldEditable_visible* = 0x0004'i16
  bp_TGtkOldEditable_visible* = 2'i16

proc TYPE_OLD_EDITABLE*(): GType
proc OLD_EDITABLE*(obj: pointer): POldEditable
proc OLD_EDITABLE_CLASS*(klass: pointer): POldEditableClass
proc IS_OLD_EDITABLE*(obj: pointer): bool
proc IS_OLD_EDITABLE_CLASS*(klass: pointer): bool
proc OLD_EDITABLE_GET_CLASS*(obj: pointer): POldEditableClass
proc has_selection*(a: POldEditable): guint
proc set_has_selection*(a: POldEditable, `has_selection`: guint)
proc editable*(a: POldEditable): guint
proc set_editable*(a: POldEditable, `editable`: guint)
proc visible*(a: POldEditable): guint
proc set_visible*(a: POldEditable, `visible`: guint)
proc old_editable_get_type*(): TType{.cdecl, dynlib: lib,
                                      importc: "gtk_old_editable_get_type".}
proc claim_selection*(old_editable: POldEditable, claim: gboolean,
                                   time: guint32){.cdecl, dynlib: lib,
    importc: "gtk_old_editable_claim_selection".}
proc changed*(old_editable: POldEditable){.cdecl, dynlib: lib,
    importc: "gtk_old_editable_changed".}
proc TYPE_OPTION_MENU*(): GType
proc OPTION_MENU*(obj: pointer): POptionMenu
proc OPTION_MENU_CLASS*(klass: pointer): POptionMenuClass
proc IS_OPTION_MENU*(obj: pointer): bool
proc IS_OPTION_MENU_CLASS*(klass: pointer): bool
proc OPTION_MENU_GET_CLASS*(obj: pointer): POptionMenuClass
proc option_menu_get_type*(): TType{.cdecl, dynlib: lib,
                                     importc: "gtk_option_menu_get_type".}
proc option_menu_new*(): POptionMenu{.cdecl, dynlib: lib,
                                      importc: "gtk_option_menu_new".}
proc get_menu*(option_menu: POptionMenu): PWidget{.cdecl,
    dynlib: lib, importc: "gtk_option_menu_get_menu".}
proc set_menu*(option_menu: POptionMenu, menu: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_option_menu_set_menu".}
proc remove_menu*(option_menu: POptionMenu){.cdecl, dynlib: lib,
    importc: "gtk_option_menu_remove_menu".}
proc get_history*(option_menu: POptionMenu): gint{.cdecl,
    dynlib: lib, importc: "gtk_option_menu_get_history".}
proc set_history*(option_menu: POptionMenu, index: guint){.cdecl,
    dynlib: lib, importc: "gtk_option_menu_set_history".}
const
  bm_TGtkPixmap_build_insensitive* = 0x0001'i16
  bp_TGtkPixmap_build_insensitive* = 0'i16

proc TYPE_PIXMAP*(): GType
proc PIXMAP*(obj: pointer): PPixmap
proc PIXMAP_CLASS*(klass: pointer): PPixmapClass
proc IS_PIXMAP*(obj: pointer): bool
proc IS_PIXMAP_CLASS*(klass: pointer): bool
proc PIXMAP_GET_CLASS*(obj: pointer): PPixmapClass
proc build_insensitive*(a: PPixmap): guint
proc set_build_insensitive*(a: PPixmap, `build_insensitive`: guint)
proc pixmap_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_pixmap_get_type".}
proc pixmap_new*(pixmap: gdk2.PPixmap, mask: gdk2.PBitmap): PPixmap{.cdecl,
    dynlib: lib, importc: "gtk_pixmap_new".}
proc set*(pixmap: PPixmap, val: gdk2.PPixmap, mask: gdk2.PBitmap){.cdecl,
    dynlib: lib, importc: "gtk_pixmap_set".}
proc get*(pixmap: PPixmap, val: var gdk2.PPixmap, mask: var gdk2.PBitmap){.
    cdecl, dynlib: lib, importc: "gtk_pixmap_get".}
proc set_build_insensitive*(pixmap: PPixmap, build: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_pixmap_set_build_insensitive".}
const
  bm_TGtkPlug_same_app* = 0x0001'i16
  bp_TGtkPlug_same_app* = 0'i16

proc TYPE_PLUG*(): GType
proc PLUG*(obj: pointer): PPlug
proc PLUG_CLASS*(klass: pointer): PPlugClass
proc IS_PLUG*(obj: pointer): bool
proc IS_PLUG_CLASS*(klass: pointer): bool
proc PLUG_GET_CLASS*(obj: pointer): PPlugClass
proc same_app*(a: PPlug): guint
proc set_same_app*(a: PPlug, `same_app`: guint)
proc plug_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_plug_get_type".}
proc construct_for_display*(plug: PPlug, display: gdk2.PDisplay,
                                 socket_id: gdk2.TNativeWindow){.cdecl,
    dynlib: lib, importc: "gtk_plug_construct_for_display".}
proc plug_new_for_display*(display: gdk2.PDisplay, socket_id: gdk2.TNativeWindow): PPlug{.
    cdecl, dynlib: lib, importc: "gtk_plug_new_for_display".}
proc get_id*(plug: PPlug): gdk2.TNativeWindow{.cdecl, dynlib: lib,
    importc: "gtk_plug_get_id".}
proc add_to_socket*(plug: PPlug, socket: PSocket){.cdecl, dynlib: lib,
    importc: "_gtk_plug_add_to_socket".}
proc remove_from_socket*(plug: PPlug, socket: PSocket){.cdecl, dynlib: lib,
    importc: "_gtk_plug_remove_from_socket".}
const
  bm_TGtkPreview_type* = 0x0001'i16
  bp_TGtkPreview_type* = 0'i16
  bm_TGtkPreview_expand* = 0x0002'i16
  bp_TGtkPreview_expand* = 1'i16

proc TYPE_PREVIEW*(): GType
proc PREVIEW*(obj: pointer): PPreview
proc PREVIEW_CLASS*(klass: pointer): PPreviewClass
proc IS_PREVIEW*(obj: pointer): bool
proc IS_PREVIEW_CLASS*(klass: pointer): bool
proc PREVIEW_GET_CLASS*(obj: pointer): PPreviewClass
proc get_type*(a: PPreview): guint
proc set_type*(a: PPreview, `type`: guint)
proc get_expand*(a: PPreview): guint
proc set_expand*(a: PPreview, `expand`: guint)
proc preview_get_type*(): TType{.cdecl, dynlib: lib,
                                 importc: "gtk_preview_get_type".}
proc preview_uninit*(){.cdecl, dynlib: lib, importc: "gtk_preview_uninit".}
proc preview_new*(thetype: TPreviewClass): PPreview{.cdecl, dynlib: lib,
    importc: "gtk_preview_new".}
proc size*(preview: PPreview, width: gint, height: gint){.cdecl,
    dynlib: lib, importc: "gtk_preview_size".}
proc put*(preview: PPreview, window: gdk2.PWindow, gc: gdk2.PGC, srcx: gint,
                  srcy: gint, destx: gint, desty: gint, width: gint,
                  height: gint){.cdecl, dynlib: lib, importc: "gtk_preview_put".}
proc draw_row*(preview: PPreview, data: Pguchar, x: gint, y: gint,
                       w: gint){.cdecl, dynlib: lib,
                                 importc: "gtk_preview_draw_row".}
proc set_expand*(preview: PPreview, expand: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_preview_set_expand".}
proc preview_set_gamma*(gamma: float64){.cdecl, dynlib: lib,
    importc: "gtk_preview_set_gamma".}
proc preview_set_color_cube*(nred_shades: guint, ngreen_shades: guint,
                             nblue_shades: guint, ngray_shades: guint){.cdecl,
    dynlib: lib, importc: "gtk_preview_set_color_cube".}
proc preview_set_install_cmap*(install_cmap: gint){.cdecl, dynlib: lib,
    importc: "gtk_preview_set_install_cmap".}
proc preview_set_reserved*(nreserved: gint){.cdecl, dynlib: lib,
    importc: "gtk_preview_set_reserved".}
proc set_dither*(preview: PPreview, dither: gdk2.TRgbDither){.cdecl,
    dynlib: lib, importc: "gtk_preview_set_dither".}
proc preview_get_info*(): PPreviewInfo{.cdecl, dynlib: lib,
                                        importc: "gtk_preview_get_info".}
proc preview_reset*(){.cdecl, dynlib: lib, importc: "gtk_preview_reset".}
const
  bm_TGtkProgress_show_text* = 0x0001'i16
  bp_TGtkProgress_show_text* = 0'i16
  bm_TGtkProgress_activity_mode* = 0x0002'i16
  bp_TGtkProgress_activity_mode* = 1'i16
  bm_TGtkProgress_use_text_format* = 0x0004'i16
  bp_TGtkProgress_use_text_format* = 2'i16

proc show_text*(a: PProgress): guint
proc set_show_text*(a: PProgress, `show_text`: guint)
proc activity_mode*(a: PProgress): guint
proc set_activity_mode*(a: PProgress, `activity_mode`: guint)
proc use_text_format*(a: PProgress): guint
proc set_use_text_format*(a: PProgress, `use_text_format`: guint)
const
  bm_TGtkProgressBar_activity_dir* = 0x0001'i16
  bp_TGtkProgressBar_activity_dir* = 0'i16

proc TYPE_PROGRESS_BAR*(): GType
proc PROGRESS_BAR*(obj: pointer): PProgressBar
proc PROGRESS_BAR_CLASS*(klass: pointer): PProgressBarClass
proc IS_PROGRESS_BAR*(obj: pointer): bool
proc IS_PROGRESS_BAR_CLASS*(klass: pointer): bool
proc PROGRESS_BAR_GET_CLASS*(obj: pointer): PProgressBarClass
proc activity_dir*(a: PProgressBar): guint
proc set_activity_dir*(a: PProgressBar, `activity_dir`: guint)
proc progress_bar_get_type*(): TType{.cdecl, dynlib: lib,
                                      importc: "gtk_progress_bar_get_type".}
proc progress_bar_new*(): PProgressBar{.cdecl, dynlib: lib,
                                        importc: "gtk_progress_bar_new".}
proc pulse*(pbar: PProgressBar){.cdecl, dynlib: lib,
    importc: "gtk_progress_bar_pulse".}
proc set_text*(pbar: PProgressBar, text: cstring){.cdecl,
    dynlib: lib, importc: "gtk_progress_bar_set_text".}
proc set_fraction*(pbar: PProgressBar, fraction: gdouble){.cdecl,
    dynlib: lib, importc: "gtk_progress_bar_set_fraction".}
proc set_pulse_step*(pbar: PProgressBar, fraction: gdouble){.cdecl,
    dynlib: lib, importc: "gtk_progress_bar_set_pulse_step".}
proc set_orientation*(pbar: PProgressBar,
                                   orientation: TProgressBarOrientation){.cdecl,
    dynlib: lib, importc: "gtk_progress_bar_set_orientation".}
proc get_text*(pbar: PProgressBar): cstring{.cdecl, dynlib: lib,
    importc: "gtk_progress_bar_get_text".}
proc get_fraction*(pbar: PProgressBar): gdouble{.cdecl,
    dynlib: lib, importc: "gtk_progress_bar_get_fraction".}
proc get_pulse_step*(pbar: PProgressBar): gdouble{.cdecl,
    dynlib: lib, importc: "gtk_progress_bar_get_pulse_step".}
proc get_orientation*(pbar: PProgressBar): TProgressBarOrientation{.
    cdecl, dynlib: lib, importc: "gtk_progress_bar_get_orientation".}
proc TYPE_RADIO_BUTTON*(): GType
proc RADIO_BUTTON*(obj: pointer): PRadioButton
proc RADIO_BUTTON_CLASS*(klass: pointer): PRadioButtonClass
proc IS_RADIO_BUTTON*(obj: pointer): bool
proc IS_RADIO_BUTTON_CLASS*(klass: pointer): bool
proc RADIO_BUTTON_GET_CLASS*(obj: pointer): PRadioButtonClass
proc radio_button_get_type*(): TType{.cdecl, dynlib: lib,
                                      importc: "gtk_radio_button_get_type".}
proc radio_button_new*(group: PGSList): PRadioButton{.cdecl, dynlib: lib,
    importc: "gtk_radio_button_new".}
proc new_from_widget*(group: PRadioButton): PRadioButton{.cdecl,
    dynlib: lib, importc: "gtk_radio_button_new_from_widget".}
proc radio_button_new*(group: PGSList, `label`: cstring): PRadioButton{.
    cdecl, dynlib: lib, importc: "gtk_radio_button_new_with_label".}
proc radio_button_new_with_label_from_widget*(group: PRadioButton,
    `label`: cstring): PRadioButton{.cdecl, dynlib: lib, importc: "gtk_radio_button_new_with_label_from_widget".}
proc radio_button_new_with_mnemonic*(group: PGSList, `label`: cstring): PRadioButton{.
    cdecl, dynlib: lib, importc: "gtk_radio_button_new_with_mnemonic".}
proc radio_button_new_with_mnemonic_from_widget*(group: PRadioButton,
    `label`: cstring): PRadioButton{.cdecl, dynlib: lib, importc: "gtk_radio_button_new_with_mnemonic_from_widget".}
proc get_group*(radio_button: PRadioButton): PGSList{.cdecl,
    dynlib: lib, importc: "gtk_radio_button_get_group".}
proc set_group*(radio_button: PRadioButton, group: PGSList){.cdecl,
    dynlib: lib, importc: "gtk_radio_button_set_group".}
proc TYPE_RADIO_MENU_ITEM*(): GType
proc RADIO_MENU_ITEM*(obj: pointer): PRadioMenuItem
proc RADIO_MENU_ITEM_CLASS*(klass: pointer): PRadioMenuItemClass
proc IS_RADIO_MENU_ITEM*(obj: pointer): bool
proc IS_RADIO_MENU_ITEM_CLASS*(klass: pointer): bool
proc RADIO_MENU_ITEM_GET_CLASS*(obj: pointer): PRadioMenuItemClass
proc radio_menu_item_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_radio_menu_item_get_type".}
proc radio_menu_item_new*(group: PGSList): PRadioMenuItem{.cdecl, dynlib: lib,
    importc: "gtk_radio_menu_item_new".}
proc radio_menu_item_new*(group: PGSList, `label`: cstring): PRadioMenuItem{.
    cdecl, dynlib: lib, importc: "gtk_radio_menu_item_new_with_label".}
proc radio_menu_item_new_with_mnemonic*(group: PGSList, `label`: cstring): PRadioMenuItem{.
    cdecl, dynlib: lib, importc: "gtk_radio_menu_item_new_with_mnemonic".}
proc item_get_group*(radio_menu_item: PRadioMenuItem): PGSList{.
    cdecl, dynlib: lib, importc: "gtk_radio_menu_item_get_group".}
proc item_set_group*(radio_menu_item: PRadioMenuItem, group: PGSList){.
    cdecl, dynlib: lib, importc: "gtk_radio_menu_item_set_group".}
const
  bm_TGtkScrolledWindow_hscrollbar_policy* = 0x0003'i16
  bp_TGtkScrolledWindow_hscrollbar_policy* = 0'i16
  bm_TGtkScrolledWindow_vscrollbar_policy* = 0x000C'i16
  bp_TGtkScrolledWindow_vscrollbar_policy* = 2'i16
  bm_TGtkScrolledWindow_hscrollbar_visible* = 0x0010'i16
  bp_TGtkScrolledWindow_hscrollbar_visible* = 4'i16
  bm_TGtkScrolledWindow_vscrollbar_visible* = 0x0020'i16
  bp_TGtkScrolledWindow_vscrollbar_visible* = 5'i16
  bm_TGtkScrolledWindow_window_placement* = 0x00C0'i16
  bp_TGtkScrolledWindow_window_placement* = 6'i16
  bm_TGtkScrolledWindow_focus_out* = 0x0100'i16
  bp_TGtkScrolledWindow_focus_out* = 8'i16

proc TYPE_SCROLLED_WINDOW*(): GType
proc SCROLLED_WINDOW*(obj: pointer): PScrolledWindow
proc SCROLLED_WINDOW_CLASS*(klass: pointer): PScrolledWindowClass
proc IS_SCROLLED_WINDOW*(obj: pointer): bool
proc IS_SCROLLED_WINDOW_CLASS*(klass: pointer): bool
proc SCROLLED_WINDOW_GET_CLASS*(obj: pointer): PScrolledWindowClass
proc hscrollbar_policy*(a: PScrolledWindow): guint
proc set_hscrollbar_policy*(a: PScrolledWindow, `hscrollbar_policy`: guint)
proc vscrollbar_policy*(a: PScrolledWindow): guint
proc set_vscrollbar_policy*(a: PScrolledWindow, `vscrollbar_policy`: guint)
proc hscrollbar_visible*(a: PScrolledWindow): guint
proc set_hscrollbar_visible*(a: PScrolledWindow, `hscrollbar_visible`: guint)
proc vscrollbar_visible*(a: PScrolledWindow): guint
proc set_vscrollbar_visible*(a: PScrolledWindow, `vscrollbar_visible`: guint)
proc window_placement*(a: PScrolledWindow): guint
proc set_window_placement*(a: PScrolledWindow, `window_placement`: guint)
proc focus_out*(a: PScrolledWindow): guint
proc set_focus_out*(a: PScrolledWindow, `focus_out`: guint)
proc scrolled_window_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_scrolled_window_get_type".}
proc scrolled_window_new*(hadjustment: PAdjustment, vadjustment: PAdjustment): PScrolledWindow{.
    cdecl, dynlib: lib, importc: "gtk_scrolled_window_new".}
proc set_hadjustment*(scrolled_window: PScrolledWindow,
                                      hadjustment: PAdjustment){.cdecl,
    dynlib: lib, importc: "gtk_scrolled_window_set_hadjustment".}
proc set_vadjustment*(scrolled_window: PScrolledWindow,
                                      hadjustment: PAdjustment){.cdecl,
    dynlib: lib, importc: "gtk_scrolled_window_set_vadjustment".}
proc get_hadjustment*(scrolled_window: PScrolledWindow): PAdjustment{.
    cdecl, dynlib: lib, importc: "gtk_scrolled_window_get_hadjustment".}
proc get_vadjustment*(scrolled_window: PScrolledWindow): PAdjustment{.
    cdecl, dynlib: lib, importc: "gtk_scrolled_window_get_vadjustment".}
proc set_policy*(scrolled_window: PScrolledWindow,
                                 hscrollbar_policy: TPolicyType,
                                 vscrollbar_policy: TPolicyType){.cdecl,
    dynlib: lib, importc: "gtk_scrolled_window_set_policy".}
proc get_policy*(scrolled_window: PScrolledWindow,
                                 hscrollbar_policy: PPolicyType,
                                 vscrollbar_policy: PPolicyType){.cdecl,
    dynlib: lib, importc: "gtk_scrolled_window_get_policy".}
proc set_placement*(scrolled_window: PScrolledWindow,
                                    window_placement: TCornerType){.cdecl,
    dynlib: lib, importc: "gtk_scrolled_window_set_placement".}
proc get_placement*(scrolled_window: PScrolledWindow): TCornerType{.
    cdecl, dynlib: lib, importc: "gtk_scrolled_window_get_placement".}
proc set_shadow_type*(scrolled_window: PScrolledWindow,
                                      thetype: TShadowType){.cdecl, dynlib: lib,
    importc: "gtk_scrolled_window_set_shadow_type".}
proc get_shadow_type*(scrolled_window: PScrolledWindow): TShadowType{.
    cdecl, dynlib: lib, importc: "gtk_scrolled_window_get_shadow_type".}
proc add_with_viewport*(scrolled_window: PScrolledWindow,
                                        child: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_scrolled_window_add_with_viewport".}
proc TYPE_SELECTION_DATA*(): GType
proc list_new*(targets: PTargetEntry, ntargets: guint): PTargetList{.
    cdecl, dynlib: lib, importc: "gtk_target_list_new".}
proc reference*(list: PTargetList){.cdecl, dynlib: lib,
    importc: "gtk_target_list_ref".}
proc unref*(list: PTargetList){.cdecl, dynlib: lib,
    importc: "gtk_target_list_unref".}
proc add*(list: PTargetList, target: gdk2.TAtom, flags: guint,
                      info: guint){.cdecl, dynlib: lib,
                                    importc: "gtk_target_list_add".}
proc add_table*(list: PTargetList, targets: PTargetEntry,
                            ntargets: guint){.cdecl, dynlib: lib,
    importc: "gtk_target_list_add_table".}
proc remove*(list: PTargetList, target: gdk2.TAtom){.cdecl,
    dynlib: lib, importc: "gtk_target_list_remove".}
proc find*(list: PTargetList, target: gdk2.TAtom, info: Pguint): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_target_list_find".}
proc selection_owner_set*(widget: PWidget, selection: gdk2.TAtom, time: guint32): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_selection_owner_set".}
proc selection_owner_set_for_display*(display: gdk2.PDisplay, widget: PWidget,
                                      selection: gdk2.TAtom, time: guint32): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_selection_owner_set_for_display".}
proc selection_add_target*(widget: PWidget, selection: gdk2.TAtom,
                           target: gdk2.TAtom, info: guint){.cdecl, dynlib: lib,
    importc: "gtk_selection_add_target".}
proc selection_add_targets*(widget: PWidget, selection: gdk2.TAtom,
                            targets: PTargetEntry, ntargets: guint){.cdecl,
    dynlib: lib, importc: "gtk_selection_add_targets".}
proc selection_clear_targets*(widget: PWidget, selection: gdk2.TAtom){.cdecl,
    dynlib: lib, importc: "gtk_selection_clear_targets".}
proc selection_convert*(widget: PWidget, selection: gdk2.TAtom, target: gdk2.TAtom,
                        time: guint32): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_selection_convert".}
proc set*(selection_data: PSelectionData, thetype: gdk2.TAtom,
                         format: gint, data: Pguchar, length: gint){.cdecl,
    dynlib: lib, importc: "gtk_selection_data_set".}
proc set_text*(selection_data: PSelectionData, str: cstring,
                              len: gint): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_selection_data_set_text".}
proc get_text*(selection_data: PSelectionData): Pguchar{.cdecl,
    dynlib: lib, importc: "gtk_selection_data_get_text".}
proc targets_include_text*(selection_data: PSelectionData): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_selection_data_targets_include_text".}
proc selection_remove_all*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_selection_remove_all".}
proc selection_clear*(widget: PWidget, event: gdk2.PEventSelection): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_selection_clear".}
proc selection_request*(widget: PWidget, event: gdk2.PEventSelection): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_selection_request".}
proc selection_incr_event*(window: gdk2.PWindow, event: gdk2.PEventProperty): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_selection_incr_event".}
proc selection_notify*(widget: PWidget, event: gdk2.PEventSelection): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_selection_notify".}
proc selection_property_notify*(widget: PWidget, event: gdk2.PEventProperty): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_selection_property_notify".}
proc selection_data_get_type*(): GType{.cdecl, dynlib: lib,
                                        importc: "gtk_selection_data_get_type".}
proc copy*(data: PSelectionData): PSelectionData{.cdecl,
    dynlib: lib, importc: "gtk_selection_data_copy".}
proc free*(data: PSelectionData){.cdecl, dynlib: lib,
    importc: "gtk_selection_data_free".}
proc TYPE_SEPARATOR_MENU_ITEM*(): GType
proc SEPARATOR_MENU_ITEM*(obj: pointer): PSeparatorMenuItem
proc SEPARATOR_MENU_ITEM_CLASS*(klass: pointer): PSeparatorMenuItemClass
proc IS_SEPARATOR_MENU_ITEM*(obj: pointer): bool
proc IS_SEPARATOR_MENU_ITEM_CLASS*(klass: pointer): bool
proc SEPARATOR_MENU_ITEM_GET_CLASS*(obj: pointer): PSeparatorMenuItemClass
proc separator_menu_item_get_type*(): GType{.cdecl, dynlib: lib,
    importc: "gtk_separator_menu_item_get_type".}
proc separator_menu_item_new*(): PSeparatorMenuItem{.cdecl, dynlib: lib,
    importc: "gtk_separator_menu_item_new".}
const
  bm_TGtkSizeGroup_have_width* = 0x0001'i16
  bp_TGtkSizeGroup_have_width* = 0'i16
  bm_TGtkSizeGroup_have_height* = 0x0002'i16
  bp_TGtkSizeGroup_have_height* = 1'i16

proc TYPE_SIZE_GROUP*(): GType
proc SIZE_GROUP*(obj: pointer): PSizeGroup
proc SIZE_GROUP_CLASS*(klass: pointer): PSizeGroupClass
proc IS_SIZE_GROUP*(obj: pointer): bool
proc IS_SIZE_GROUP_CLASS*(klass: pointer): bool
proc SIZE_GROUP_GET_CLASS*(obj: pointer): PSizeGroupClass
proc have_width*(a: PSizeGroup): guint
proc set_have_width*(a: PSizeGroup, `have_width`: guint)
proc have_height*(a: PSizeGroup): guint
proc set_have_height*(a: PSizeGroup, `have_height`: guint)
proc size_group_get_type*(): GType{.cdecl, dynlib: lib,
                                    importc: "gtk_size_group_get_type".}
proc size_group_new*(mode: TSizeGroupMode): PSizeGroup{.cdecl, dynlib: lib,
    importc: "gtk_size_group_new".}
proc set_mode*(size_group: PSizeGroup, mode: TSizeGroupMode){.cdecl,
    dynlib: lib, importc: "gtk_size_group_set_mode".}
proc get_mode*(size_group: PSizeGroup): TSizeGroupMode{.cdecl,
    dynlib: lib, importc: "gtk_size_group_get_mode".}
proc add_widget*(size_group: PSizeGroup, widget: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_size_group_add_widget".}
proc remove_widget*(size_group: PSizeGroup, widget: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_size_group_remove_widget".}
proc size_group_get_child_requisition*(widget: PWidget,
                                       requisition: PRequisition){.cdecl,
    dynlib: lib, importc: "_gtk_size_group_get_child_requisition".}
proc size_group_compute_requisition*(widget: PWidget, requisition: PRequisition){.
    cdecl, dynlib: lib, importc: "_gtk_size_group_compute_requisition".}
proc size_group_queue_resize*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "_gtk_size_group_queue_resize".}
const
  bm_TGtkSocket_same_app* = 0x0001'i16
  bp_TGtkSocket_same_app* = 0'i16
  bm_TGtkSocket_focus_in* = 0x0002'i16
  bp_TGtkSocket_focus_in* = 1'i16
  bm_TGtkSocket_have_size* = 0x0004'i16
  bp_TGtkSocket_have_size* = 2'i16
  bm_TGtkSocket_need_map* = 0x0008'i16
  bp_TGtkSocket_need_map* = 3'i16
  bm_TGtkSocket_is_mapped* = 0x0010'i16
  bp_TGtkSocket_is_mapped* = 4'i16

proc TYPE_SOCKET*(): GType
proc SOCKET*(obj: pointer): PSocket
proc SOCKET_CLASS*(klass: pointer): PSocketClass
proc IS_SOCKET*(obj: pointer): bool
proc IS_SOCKET_CLASS*(klass: pointer): bool
proc SOCKET_GET_CLASS*(obj: pointer): PSocketClass
proc same_app*(a: PSocket): guint
proc set_same_app*(a: PSocket, `same_app`: guint)
proc focus_in*(a: PSocket): guint
proc set_focus_in*(a: PSocket, `focus_in`: guint)
proc have_size*(a: PSocket): guint
proc set_have_size*(a: PSocket, `have_size`: guint)
proc need_map*(a: PSocket): guint
proc set_need_map*(a: PSocket, `need_map`: guint)
proc is_mapped*(a: PSocket): guint
proc set_is_mapped*(a: PSocket, `is_mapped`: guint)
proc socket_new*(): PSocket{.cdecl, dynlib: lib, importc: "gtk_socket_new".}
proc socket_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_socket_get_type".}
proc add_id*(socket: PSocket, window_id: gdk2.TNativeWindow){.cdecl,
    dynlib: lib, importc: "gtk_socket_add_id".}
proc get_id*(socket: PSocket): gdk2.TNativeWindow{.cdecl, dynlib: lib,
    importc: "gtk_socket_get_id".}
const
  INPUT_ERROR* = - (1)
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

proc TYPE_SPIN_BUTTON*(): GType
proc SPIN_BUTTON*(obj: pointer): PSpinButton
proc SPIN_BUTTON_CLASS*(klass: pointer): PSpinButtonClass
proc IS_SPIN_BUTTON*(obj: pointer): bool
proc IS_SPIN_BUTTON_CLASS*(klass: pointer): bool
proc SPIN_BUTTON_GET_CLASS*(obj: pointer): PSpinButtonClass
proc in_child*(a: PSpinButton): guint
proc set_in_child*(a: PSpinButton, `in_child`: guint)
proc click_child*(a: PSpinButton): guint
proc set_click_child*(a: PSpinButton, `click_child`: guint)
proc button*(a: PSpinButton): guint
proc set_button*(a: PSpinButton, `button`: guint)
proc need_timer*(a: PSpinButton): guint
proc set_need_timer*(a: PSpinButton, `need_timer`: guint)
proc timer_calls*(a: PSpinButton): guint
proc set_timer_calls*(a: PSpinButton, `timer_calls`: guint)
proc digits*(a: PSpinButton): guint
proc set_digits*(a: PSpinButton, `digits`: guint)
proc numeric*(a: PSpinButton): guint
proc set_numeric*(a: PSpinButton, `numeric`: guint)
proc wrap*(a: PSpinButton): guint
proc set_wrap*(a: PSpinButton, `wrap`: guint)
proc snap_to_ticks*(a: PSpinButton): guint
proc set_snap_to_ticks*(a: PSpinButton, `snap_to_ticks`: guint)
proc spin_button_get_type*(): TType{.cdecl, dynlib: lib,
                                     importc: "gtk_spin_button_get_type".}
proc configure*(spin_button: PSpinButton, adjustment: PAdjustment,
                            climb_rate: gdouble, digits: guint){.cdecl,
    dynlib: lib, importc: "gtk_spin_button_configure".}
proc spin_button_new*(adjustment: PAdjustment, climb_rate: gdouble,
                      digits: guint): PSpinButton{.cdecl, dynlib: lib,
    importc: "gtk_spin_button_new".}
proc spin_button_new*(min: gdouble, max: gdouble, step: gdouble): PSpinButton{.
    cdecl, dynlib: lib, importc: "gtk_spin_button_new_with_range".}
proc set_adjustment*(spin_button: PSpinButton,
                                 adjustment: PAdjustment){.cdecl, dynlib: lib,
    importc: "gtk_spin_button_set_adjustment".}
proc get_adjustment*(spin_button: PSpinButton): PAdjustment{.cdecl,
    dynlib: lib, importc: "gtk_spin_button_get_adjustment".}
proc set_digits*(spin_button: PSpinButton, digits: guint){.cdecl,
    dynlib: lib, importc: "gtk_spin_button_set_digits".}
proc get_digits*(spin_button: PSpinButton): guint{.cdecl,
    dynlib: lib, importc: "gtk_spin_button_get_digits".}
proc set_increments*(spin_button: PSpinButton, step: gdouble,
                                 page: gdouble){.cdecl, dynlib: lib,
    importc: "gtk_spin_button_set_increments".}
proc get_increments*(spin_button: PSpinButton, step: Pgdouble,
                                 page: Pgdouble){.cdecl, dynlib: lib,
    importc: "gtk_spin_button_get_increments".}
proc set_range*(spin_button: PSpinButton, min: gdouble, max: gdouble){.
    cdecl, dynlib: lib, importc: "gtk_spin_button_set_range".}
proc get_range*(spin_button: PSpinButton, min: Pgdouble,
                            max: Pgdouble){.cdecl, dynlib: lib,
    importc: "gtk_spin_button_get_range".}
proc get_value*(spin_button: PSpinButton): gdouble{.cdecl,
    dynlib: lib, importc: "gtk_spin_button_get_value".}
proc get_value_as_int*(spin_button: PSpinButton): gint{.cdecl,
    dynlib: lib, importc: "gtk_spin_button_get_value_as_int".}
proc set_value*(spin_button: PSpinButton, value: gdouble){.cdecl,
    dynlib: lib, importc: "gtk_spin_button_set_value".}
proc set_update_policy*(spin_button: PSpinButton,
                                    policy: TSpinButtonUpdatePolicy){.cdecl,
    dynlib: lib, importc: "gtk_spin_button_set_update_policy".}
proc get_update_policy*(spin_button: PSpinButton): TSpinButtonUpdatePolicy{.
    cdecl, dynlib: lib, importc: "gtk_spin_button_get_update_policy".}
proc set_numeric*(spin_button: PSpinButton, numeric: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_spin_button_set_numeric".}
proc get_numeric*(spin_button: PSpinButton): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_spin_button_get_numeric".}
proc spin*(spin_button: PSpinButton, direction: TSpinType,
                       increment: gdouble){.cdecl, dynlib: lib,
    importc: "gtk_spin_button_spin".}
proc set_wrap*(spin_button: PSpinButton, wrap: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_spin_button_set_wrap".}
proc get_wrap*(spin_button: PSpinButton): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_spin_button_get_wrap".}
proc set_snap_to_ticks*(spin_button: PSpinButton,
                                    snap_to_ticks: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_spin_button_set_snap_to_ticks".}
proc get_snap_to_ticks*(spin_button: PSpinButton): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_spin_button_get_snap_to_ticks".}
proc update*(spin_button: PSpinButton){.cdecl, dynlib: lib,
    importc: "gtk_spin_button_update".}
const
  STOCK_DIALOG_INFO* = "gtk-dialog-info"
  STOCK_DIALOG_WARNING* = "gtk-dialog-warning"
  STOCK_DIALOG_ERROR* = "gtk-dialog-error"
  STOCK_DIALOG_QUESTION* = "gtk-dialog-question"
  STOCK_DND* = "gtk-dnd"
  STOCK_DND_MULTIPLE* = "gtk-dnd-multiple"
  STOCK_ABOUT* = "gtk-about"
  STOCK_ADD_name* = "gtk-add"
  STOCK_APPLY* = "gtk-apply"
  STOCK_BOLD* = "gtk-bold"
  STOCK_CANCEL* = "gtk-cancel"
  STOCK_CDROM* = "gtk-cdrom"
  STOCK_CLEAR* = "gtk-clear"
  STOCK_CLOSE* = "gtk-close"
  STOCK_COLOR_PICKER* = "gtk-color-picker"
  STOCK_CONVERT* = "gtk-convert"
  STOCK_CONNECT* = "gtk-connect"
  STOCK_COPY* = "gtk-copy"
  STOCK_CUT* = "gtk-cut"
  STOCK_DELETE* = "gtk-delete"
  STOCK_EDIT* = "gtk-edit"
  STOCK_EXECUTE* = "gtk-execute"
  STOCK_FIND* = "gtk-find"
  STOCK_FIND_AND_REPLACE* = "gtk-find-and-replace"
  STOCK_FLOPPY* = "gtk-floppy"
  STOCK_GOTO_BOTTOM* = "gtk-goto-bottom"
  STOCK_GOTO_FIRST* = "gtk-goto-first"
  STOCK_GOTO_LAST* = "gtk-goto-last"
  STOCK_GOTO_TOP* = "gtk-goto-top"
  STOCK_GO_BACK* = "gtk-go-back"
  STOCK_GO_DOWN* = "gtk-go-down"
  STOCK_GO_FORWARD* = "gtk-go-forward"
  STOCK_GO_UP* = "gtk-go-up"
  STOCK_HELP* = "gtk-help"
  STOCK_HOME* = "gtk-home"
  STOCK_INDEX* = "gtk-index"
  STOCK_ITALIC* = "gtk-italic"
  STOCK_JUMP_TO* = "gtk-jump-to"
  STOCK_JUSTIFY_CENTER* = "gtk-justify-center"
  STOCK_JUSTIFY_FILL* = "gtk-justify-fill"
  STOCK_JUSTIFY_LEFT* = "gtk-justify-left"
  STOCK_JUSTIFY_RIGHT* = "gtk-justify-right"
  STOCK_MEDIA_FORWARD* = "gtk-media-forward"
  STOCK_MEDIA_NEXT* = "gtk-media-next"
  STOCK_MEDIA_PAUSE* = "gtk-media-pause"
  STOCK_MEDIA_PLAY* = "gtk-media-play"
  STOCK_MEDIA_PREVIOUS* = "gtk-media-previous"
  STOCK_MEDIA_RECORD* = "gtk-media-record"
  STOCK_MEDIA_REWIND* = "gtk-media-rewind"
  STOCK_MEDIA_STOP* = "gtk-media-stop"
  STOCK_MISSING_IMAGE* = "gtk-missing-image"
  STOCK_NEW* = "gtk-new"
  STOCK_NO* = "gtk-no"
  STOCK_OK* = "gtk-ok"
  STOCK_OPEN* = "gtk-open"
  STOCK_PASTE* = "gtk-paste"
  STOCK_PREFERENCES* = "gtk-preferences"
  STOCK_PRINT* = "gtk-print"
  STOCK_PRINT_PREVIEW* = "gtk-print-preview"
  STOCK_PROPERTIES* = "gtk-properties"
  STOCK_QUIT* = "gtk-quit"
  STOCK_REDO* = "gtk-redo"
  STOCK_REFRESH* = "gtk-refresh"
  STOCK_REMOVE* = "gtk-remove"
  STOCK_REVERT_TO_SAVED* = "gtk-revert-to-saved"
  STOCK_SAVE* = "gtk-save"
  STOCK_SAVE_AS* = "gtk-save-as"
  STOCK_SELECT_COLOR* = "gtk-select-color"
  STOCK_SELECT_FONT* = "gtk-select-font"
  STOCK_SORT_ASCENDING* = "gtk-sort-ascending"
  STOCK_SORT_DESCENDING* = "gtk-sort-descending"
  STOCK_SPELL_CHECK* = "gtk-spell-check"
  STOCK_STOP* = "gtk-stop"
  STOCK_STRIKETHROUGH* = "gtk-strikethrough"
  STOCK_UNDELETE* = "gtk-undelete"
  STOCK_UNDERLINE* = "gtk-underline"
  STOCK_UNDO* = "gtk-undo"
  STOCK_YES* = "gtk-yes"
  STOCK_ZOOM_100* = "gtk-zoom-100"
  STOCK_ZOOM_FIT* = "gtk-zoom-fit"
  STOCK_ZOOM_IN* = "gtk-zoom-in"
  STOCK_ZOOM_OUT* = "gtk-zoom-out"

proc add*(items: PStockItem, n_items: guint){.cdecl, dynlib: lib,
    importc: "gtk_stock_add".}
proc add_static*(items: PStockItem, n_items: guint){.cdecl, dynlib: lib,
    importc: "gtk_stock_add_static".}
proc stock_lookup*(stock_id: cstring, item: PStockItem): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_stock_lookup".}
proc stock_list_ids*(): PGSList{.cdecl, dynlib: lib,
                                 importc: "gtk_stock_list_ids".}
proc copy*(item: PStockItem): PStockItem{.cdecl, dynlib: lib,
    importc: "gtk_stock_item_copy".}
proc free*(item: PStockItem){.cdecl, dynlib: lib,
    importc: "gtk_stock_item_free".}
proc TYPE_STATUSBAR*(): GType
proc STATUSBAR*(obj: pointer): PStatusbar
proc STATUSBAR_CLASS*(klass: pointer): PStatusbarClass
proc IS_STATUSBAR*(obj: pointer): bool
proc IS_STATUSBAR_CLASS*(klass: pointer): bool
proc STATUSBAR_GET_CLASS*(obj: pointer): PStatusbarClass
const
  bm_TGtkStatusbar_has_resize_grip* = 0x0001'i16
  bp_TGtkStatusbar_has_resize_grip* = 0'i16

proc has_resize_grip*(a: PStatusbar): guint
proc set_has_resize_grip*(a: PStatusbar, `has_resize_grip`: guint)
proc statusbar_get_type*(): TType{.cdecl, dynlib: lib,
                                   importc: "gtk_statusbar_get_type".}
proc statusbar_new*(): PStatusbar{.cdecl, dynlib: lib,
                                   importc: "gtk_statusbar_new".}
proc get_context_id*(statusbar: PStatusbar,
                               context_description: cstring): guint{.cdecl,
    dynlib: lib, importc: "gtk_statusbar_get_context_id".}
proc push*(statusbar: PStatusbar, context_id: guint, text: cstring): guint{.
    cdecl, dynlib: lib, importc: "gtk_statusbar_push".}
proc pop*(statusbar: PStatusbar, context_id: guint){.cdecl,
    dynlib: lib, importc: "gtk_statusbar_pop".}
proc remove*(statusbar: PStatusbar, context_id: guint,
                       message_id: guint){.cdecl, dynlib: lib,
    importc: "gtk_statusbar_remove".}
proc set_has_resize_grip*(statusbar: PStatusbar, setting: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_statusbar_set_has_resize_grip".}
proc get_has_resize_grip*(statusbar: PStatusbar): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_statusbar_get_has_resize_grip".}
const
  bm_TGtkTable_homogeneous* = 0x0001'i16
  bp_TGtkTable_homogeneous* = 0'i16
  bm_TGtkTableChild_xexpand* = 0x0001'i16
  bp_TGtkTableChild_xexpand* = 0'i16
  bm_TGtkTableChild_yexpand* = 0x0002'i16
  bp_TGtkTableChild_yexpand* = 1'i16
  bm_TGtkTableChild_xshrink* = 0x0004'i16
  bp_TGtkTableChild_xshrink* = 2'i16
  bm_TGtkTableChild_yshrink* = 0x0008'i16
  bp_TGtkTableChild_yshrink* = 3'i16
  bm_TGtkTableChild_xfill* = 0x0010'i16
  bp_TGtkTableChild_xfill* = 4'i16
  bm_TGtkTableChild_yfill* = 0x0020'i16
  bp_TGtkTableChild_yfill* = 5'i16
  bm_TGtkTableRowCol_need_expand* = 0x0001'i16
  bp_TGtkTableRowCol_need_expand* = 0'i16
  bm_TGtkTableRowCol_need_shrink* = 0x0002'i16
  bp_TGtkTableRowCol_need_shrink* = 1'i16
  bm_TGtkTableRowCol_expand* = 0x0004'i16
  bp_TGtkTableRowCol_expand* = 2'i16
  bm_TGtkTableRowCol_shrink* = 0x0008'i16
  bp_TGtkTableRowCol_shrink* = 3'i16
  bm_TGtkTableRowCol_empty* = 0x0010'i16
  bp_TGtkTableRowCol_empty* = 4'i16

proc TYPE_TABLE*(): GType
proc TABLE*(obj: pointer): PTable
proc TABLE_CLASS*(klass: pointer): PTableClass
proc IS_TABLE*(obj: pointer): bool
proc IS_TABLE_CLASS*(klass: pointer): bool
proc TABLE_GET_CLASS*(obj: pointer): PTableClass
proc homogeneous*(a: PTable): guint
proc set_homogeneous*(a: PTable, `homogeneous`: guint)
proc xexpand*(a: PTableChild): guint
proc set_xexpand*(a: PTableChild, `xexpand`: guint)
proc yexpand*(a: PTableChild): guint
proc set_yexpand*(a: PTableChild, `yexpand`: guint)
proc xshrink*(a: PTableChild): guint
proc set_xshrink*(a: PTableChild, `xshrink`: guint)
proc yshrink*(a: PTableChild): guint
proc set_yshrink*(a: PTableChild, `yshrink`: guint)
proc xfill*(a: PTableChild): guint
proc set_xfill*(a: PTableChild, `xfill`: guint)
proc yfill*(a: PTableChild): guint
proc set_yfill*(a: PTableChild, `yfill`: guint)
proc need_expand*(a: PTableRowCol): guint
proc set_need_expand*(a: PTableRowCol, `need_expand`: guint)
proc need_shrink*(a: PTableRowCol): guint
proc set_need_shrink*(a: PTableRowCol, `need_shrink`: guint)
proc expand*(a: PTableRowCol): guint
proc set_expand*(a: PTableRowCol, `expand`: guint)
proc shrink*(a: PTableRowCol): guint
proc set_shrink*(a: PTableRowCol, `shrink`: guint)
proc empty*(a: PTableRowCol): guint
proc set_empty*(a: PTableRowCol, `empty`: guint)
proc table_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_table_get_type".}
proc table_new*(rows: guint, columns: guint, homogeneous: gboolean): PTable{.
    cdecl, dynlib: lib, importc: "gtk_table_new".}
proc resize*(table: PTable, rows: guint, columns: guint){.cdecl,
    dynlib: lib, importc: "gtk_table_resize".}
proc attach*(table: PTable, child: PWidget, left_attach: guint,
                   right_attach: guint, top_attach: guint, bottom_attach: guint,
                   xoptions: TAttachOptions, yoptions: TAttachOptions,
                   xpadding: guint, ypadding: guint){.cdecl, dynlib: lib,
    importc: "gtk_table_attach".}
proc attach_defaults*(table: PTable, widget: PWidget, left_attach: guint,
                            right_attach: guint, top_attach: guint,
                            bottom_attach: guint){.cdecl, dynlib: lib,
    importc: "gtk_table_attach_defaults".}
proc set_row_spacing*(table: PTable, row: guint, spacing: guint){.cdecl,
    dynlib: lib, importc: "gtk_table_set_row_spacing".}
proc get_row_spacing*(table: PTable, row: guint): guint{.cdecl,
    dynlib: lib, importc: "gtk_table_get_row_spacing".}
proc set_col_spacing*(table: PTable, column: guint, spacing: guint){.
    cdecl, dynlib: lib, importc: "gtk_table_set_col_spacing".}
proc get_col_spacing*(table: PTable, column: guint): guint{.cdecl,
    dynlib: lib, importc: "gtk_table_get_col_spacing".}
proc set_row_spacings*(table: PTable, spacing: guint){.cdecl, dynlib: lib,
    importc: "gtk_table_set_row_spacings".}
proc get_default_row_spacing*(table: PTable): guint{.cdecl, dynlib: lib,
    importc: "gtk_table_get_default_row_spacing".}
proc set_col_spacings*(table: PTable, spacing: guint){.cdecl, dynlib: lib,
    importc: "gtk_table_set_col_spacings".}
proc get_default_col_spacing*(table: PTable): guint{.cdecl, dynlib: lib,
    importc: "gtk_table_get_default_col_spacing".}
proc set_homogeneous*(table: PTable, homogeneous: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_table_set_homogeneous".}
proc get_homogeneous*(table: PTable): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_table_get_homogeneous".}
const
  bm_TGtkTearoffMenuItem_torn_off* = 0x0001'i16
  bp_TGtkTearoffMenuItem_torn_off* = 0'i16

proc TYPE_TEAROFF_MENU_ITEM*(): GType
proc TEAROFF_MENU_ITEM*(obj: pointer): PTearoffMenuItem
proc TEAROFF_MENU_ITEM_CLASS*(klass: pointer): PTearoffMenuItemClass
proc IS_TEAROFF_MENU_ITEM*(obj: pointer): bool
proc IS_TEAROFF_MENU_ITEM_CLASS*(klass: pointer): bool
proc TEAROFF_MENU_ITEM_GET_CLASS*(obj: pointer): PTearoffMenuItemClass
proc torn_off*(a: PTearoffMenuItem): guint
proc set_torn_off*(a: PTearoffMenuItem, `torn_off`: guint)
proc tearoff_menu_item_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_tearoff_menu_item_get_type".}
proc tearoff_menu_item_new*(): PTearoffMenuItem{.cdecl, dynlib: lib,
    importc: "gtk_tearoff_menu_item_new".}
const
  bm_TGtkText_line_wrap* = 0x0001'i16
  bp_TGtkText_line_wrap* = 0'i16
  bm_TGtkText_word_wrap* = 0x0002'i16
  bp_TGtkText_word_wrap* = 1'i16
  bm_TGtkText_use_wchar* = 0x0004'i16
  bp_TGtkText_use_wchar* = 2'i16

proc TYPE_TEXT*(): GType
proc TEXT*(obj: pointer): PText
proc TEXT_CLASS*(klass: pointer): PTextClass
proc IS_TEXT*(obj: pointer): bool
proc IS_TEXT_CLASS*(klass: pointer): bool
proc TEXT_GET_CLASS*(obj: pointer): PTextClass
proc line_wrap*(a: PText): guint
proc set_line_wrap*(a: PText, `line_wrap`: guint)
proc word_wrap*(a: PText): guint
proc set_word_wrap*(a: PText, `word_wrap`: guint)
proc use_wchar*(a: PText): gboolean
proc set_use_wchar*(a: PText, `use_wchar`: gboolean)
proc text_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_text_get_type".}
proc text_new*(hadj: PAdjustment, vadj: PAdjustment): PText{.cdecl, dynlib: lib,
    importc: "gtk_text_new".}
proc set_editable*(text: PText, editable: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_text_set_editable".}
proc set_word_wrap*(text: PText, word_wrap: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_text_set_word_wrap".}
proc set_line_wrap*(text: PText, line_wrap: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_text_set_line_wrap".}
proc set_adjustments*(text: PText, hadj: PAdjustment, vadj: PAdjustment){.
    cdecl, dynlib: lib, importc: "gtk_text_set_adjustments".}
proc set_point*(text: PText, index: guint){.cdecl, dynlib: lib,
    importc: "gtk_text_set_point".}
proc get_point*(text: PText): guint{.cdecl, dynlib: lib,
    importc: "gtk_text_get_point".}
proc get_length*(text: PText): guint{.cdecl, dynlib: lib,
    importc: "gtk_text_get_length".}
proc freeze*(text: PText){.cdecl, dynlib: lib, importc: "gtk_text_freeze".}
proc thaw*(text: PText){.cdecl, dynlib: lib, importc: "gtk_text_thaw".}
proc insert*(text: PText, font: gdk2.PFont, fore: gdk2.PColor, back: gdk2.PColor,
                  chars: cstring, length: gint){.cdecl, dynlib: lib,
    importc: "gtk_text_insert".}
proc backward_delete*(text: PText, nchars: guint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_backward_delete".}
proc forward_delete*(text: PText, nchars: guint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_forward_delete".}
proc INDEX_WCHAR*(t: PText, index: guint): guint32
proc INDEX_UCHAR*(t: PText, index: guint): GUChar
const
  TEXT_SEARCH_VISIBLE_ONLY* = 0
  TEXT_SEARCH_TEXT_ONLY* = 1

proc TYPE_TEXT_ITER*(): GType
proc get_buffer*(iter: PTextIter): PTextBuffer{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_get_buffer".}
proc copy*(iter: PTextIter): PTextIter{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_copy".}
proc free*(iter: PTextIter){.cdecl, dynlib: lib,
                                       importc: "gtk_text_iter_free".}
proc text_iter_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "gtk_text_iter_get_type".}
proc get_offset*(iter: PTextIter): gint{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_get_offset".}
proc get_line*(iter: PTextIter): gint{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_get_line".}
proc get_line_offset*(iter: PTextIter): gint{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_get_line_offset".}
proc get_line_index*(iter: PTextIter): gint{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_get_line_index".}
proc get_visible_line_offset*(iter: PTextIter): gint{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_get_visible_line_offset".}
proc get_visible_line_index*(iter: PTextIter): gint{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_get_visible_line_index".}
proc get_char*(iter: PTextIter): gunichar{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_get_char".}
proc get_slice*(start: PTextIter, theEnd: PTextIter): cstring{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_get_slice".}
proc get_text*(start: PTextIter, theEnd: PTextIter): cstring{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_get_text".}
proc get_visible_slice*(start: PTextIter, theEnd: PTextIter): cstring{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_get_visible_slice".}
proc get_visible_text*(start: PTextIter, theEnd: PTextIter): cstring{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_get_visible_text".}
proc get_pixbuf*(iter: PTextIter): gdk2pixbuf.PPixbuf{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_get_pixbuf".}
proc get_marks*(iter: PTextIter): PGSList{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_get_marks".}
proc get_child_anchor*(iter: PTextIter): PTextChildAnchor{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_get_child_anchor".}
proc get_toggled_tags*(iter: PTextIter, toggled_on: gboolean): PGSList{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_get_toggled_tags".}
proc begins_tag*(iter: PTextIter, tag: PTextTag): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_begins_tag".}
proc ends_tag*(iter: PTextIter, tag: PTextTag): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_ends_tag".}
proc toggles_tag*(iter: PTextIter, tag: PTextTag): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_toggles_tag".}
proc has_tag*(iter: PTextIter, tag: PTextTag): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_has_tag".}
proc get_tags*(iter: PTextIter): PGSList{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_get_tags".}
proc editable*(iter: PTextIter, default_setting: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_editable".}
proc can_insert*(iter: PTextIter, default_editability: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_can_insert".}
proc starts_word*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_starts_word".}
proc ends_word*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_ends_word".}
proc inside_word*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_inside_word".}
proc starts_sentence*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_starts_sentence".}
proc ends_sentence*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_ends_sentence".}
proc inside_sentence*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_inside_sentence".}
proc starts_line*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_starts_line".}
proc ends_line*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_ends_line".}
proc is_cursor_position*(iter: PTextIter): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_is_cursor_position".}
proc get_chars_in_line*(iter: PTextIter): gint{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_get_chars_in_line".}
proc get_bytes_in_line*(iter: PTextIter): gint{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_get_bytes_in_line".}
proc get_attributes*(iter: PTextIter, values: PTextAttributes): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_get_attributes".}
proc get_language*(iter: PTextIter): pango.PLanguage{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_get_language".}
proc is_end*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_is_end".}
proc is_start*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_is_start".}
proc forward_char*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_forward_char".}
proc backward_char*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_backward_char".}
proc forward_chars*(iter: PTextIter, count: gint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_forward_chars".}
proc backward_chars*(iter: PTextIter, count: gint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_backward_chars".}
proc forward_line*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_forward_line".}
proc backward_line*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_backward_line".}
proc forward_lines*(iter: PTextIter, count: gint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_forward_lines".}
proc backward_lines*(iter: PTextIter, count: gint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_backward_lines".}
proc forward_word_end*(iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_iter_forward_word_end".}
proc backward_word_start*(iter: PTextIter): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_backward_word_start".}
proc forward_word_ends*(iter: PTextIter, count: gint): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_forward_word_ends".}
proc backward_word_starts*(iter: PTextIter, count: gint): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_backward_word_starts".}
proc forward_sentence_end*(iter: PTextIter): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_forward_sentence_end".}
proc backward_sentence_start*(iter: PTextIter): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_backward_sentence_start".}
proc forward_sentence_ends*(iter: PTextIter, count: gint): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_forward_sentence_ends".}
proc backward_sentence_starts*(iter: PTextIter, count: gint): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_backward_sentence_starts".}
proc forward_cursor_position*(iter: PTextIter): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_forward_cursor_position".}
proc backward_cursor_position*(iter: PTextIter): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_backward_cursor_position".}
proc forward_cursor_positions*(iter: PTextIter, count: gint): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_forward_cursor_positions".}
proc backward_cursor_positions*(iter: PTextIter, count: gint): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_backward_cursor_positions".}
proc set_offset*(iter: PTextIter, char_offset: gint){.cdecl,
    dynlib: lib, importc: "gtk_text_iter_set_offset".}
proc set_line*(iter: PTextIter, line_number: gint){.cdecl,
    dynlib: lib, importc: "gtk_text_iter_set_line".}
proc set_line_offset*(iter: PTextIter, char_on_line: gint){.cdecl,
    dynlib: lib, importc: "gtk_text_iter_set_line_offset".}
proc set_line_index*(iter: PTextIter, byte_on_line: gint){.cdecl,
    dynlib: lib, importc: "gtk_text_iter_set_line_index".}
proc forward_to_end*(iter: PTextIter){.cdecl, dynlib: lib,
    importc: "gtk_text_iter_forward_to_end".}
proc forward_to_line_end*(iter: PTextIter): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_forward_to_line_end".}
proc set_visible_line_offset*(iter: PTextIter, char_on_line: gint){.
    cdecl, dynlib: lib, importc: "gtk_text_iter_set_visible_line_offset".}
proc set_visible_line_index*(iter: PTextIter, byte_on_line: gint){.
    cdecl, dynlib: lib, importc: "gtk_text_iter_set_visible_line_index".}
proc forward_to_tag_toggle*(iter: PTextIter, tag: PTextTag): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_forward_to_tag_toggle".}
proc backward_to_tag_toggle*(iter: PTextIter, tag: PTextTag): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_backward_to_tag_toggle".}
proc forward_find_char*(iter: PTextIter, pred: TTextCharPredicate,
                                  user_data: gpointer, limit: PTextIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_forward_find_char".}
proc backward_find_char*(iter: PTextIter, pred: TTextCharPredicate,
                                   user_data: gpointer, limit: PTextIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_backward_find_char".}
proc forward_search*(iter: PTextIter, str: cstring,
                               flags: TTextSearchFlags, match_start: PTextIter,
                               match_end: PTextIter, limit: PTextIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_forward_search".}
proc backward_search*(iter: PTextIter, str: cstring,
                                flags: TTextSearchFlags, match_start: PTextIter,
                                match_end: PTextIter, limit: PTextIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_backward_search".}
proc equal*(lhs: PTextIter, rhs: PTextIter): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_equal".}
proc compare*(lhs: PTextIter, rhs: PTextIter): gint{.cdecl,
    dynlib: lib, importc: "gtk_text_iter_compare".}
proc in_range*(iter: PTextIter, start: PTextIter, theEnd: PTextIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_iter_in_range".}
proc order*(first: PTextIter, second: PTextIter){.cdecl, dynlib: lib,
    importc: "gtk_text_iter_order".}
proc TYPE_TEXT_TAG*(): GType
proc TEXT_TAG*(obj: pointer): PTextTag
proc TEXT_TAG_CLASS*(klass: pointer): PTextTagClass
proc IS_TEXT_TAG*(obj: pointer): bool
proc IS_TEXT_TAG_CLASS*(klass: pointer): bool
proc TEXT_TAG_GET_CLASS*(obj: pointer): PTextTagClass
proc TYPE_TEXT_ATTRIBUTES*(): GType
proc text_tag_get_type*(): GType{.cdecl, dynlib: lib,
                                  importc: "gtk_text_tag_get_type".}
proc text_tag_new*(name: cstring): PTextTag{.cdecl, dynlib: lib,
    importc: "gtk_text_tag_new".}
proc get_priority*(tag: PTextTag): gint{.cdecl, dynlib: lib,
    importc: "gtk_text_tag_get_priority".}
proc set_priority*(tag: PTextTag, priority: gint){.cdecl, dynlib: lib,
    importc: "gtk_text_tag_set_priority".}
proc event*(tag: PTextTag, event_object: PGObject, event: gdk2.PEvent,
                     iter: PTextIter): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_tag_event".}
proc text_attributes_new*(): PTextAttributes{.cdecl, dynlib: lib,
    importc: "gtk_text_attributes_new".}
proc copy*(src: PTextAttributes): PTextAttributes{.cdecl,
    dynlib: lib, importc: "gtk_text_attributes_copy".}
proc copy_values*(src: PTextAttributes, dest: PTextAttributes){.
    cdecl, dynlib: lib, importc: "gtk_text_attributes_copy_values".}
proc unref*(values: PTextAttributes){.cdecl, dynlib: lib,
    importc: "gtk_text_attributes_unref".}
proc reference*(values: PTextAttributes){.cdecl, dynlib: lib,
    importc: "gtk_text_attributes_ref".}
proc text_attributes_get_type*(): GType{.cdecl, dynlib: lib,
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

proc bg_color_set*(a: PTextTag): guint
proc set_bg_color_set*(a: PTextTag, `bg_color_set`: guint)
proc bg_stipple_set*(a: PTextTag): guint
proc set_bg_stipple_set*(a: PTextTag, `bg_stipple_set`: guint)
proc fg_color_set*(a: PTextTag): guint
proc set_fg_color_set*(a: PTextTag, `fg_color_set`: guint)
proc scale_set*(a: PTextTag): guint
proc set_scale_set*(a: PTextTag, `scale_set`: guint)
proc fg_stipple_set*(a: PTextTag): guint
proc set_fg_stipple_set*(a: PTextTag, `fg_stipple_set`: guint)
proc justification_set*(a: PTextTag): guint
proc set_justification_set*(a: PTextTag, `justification_set`: guint)
proc left_margin_set*(a: PTextTag): guint
proc set_left_margin_set*(a: PTextTag, `left_margin_set`: guint)
proc indent_set*(a: PTextTag): guint
proc set_indent_set*(a: PTextTag, `indent_set`: guint)
proc rise_set*(a: PTextTag): guint
proc set_rise_set*(a: PTextTag, `rise_set`: guint)
proc strikethrough_set*(a: PTextTag): guint
proc set_strikethrough_set*(a: PTextTag, `strikethrough_set`: guint)
proc right_margin_set*(a: PTextTag): guint
proc set_right_margin_set*(a: PTextTag, `right_margin_set`: guint)
proc pixels_above_lines_set*(a: PTextTag): guint
proc set_pixels_above_lines_set*(a: PTextTag,
                                 `pixels_above_lines_set`: guint)
proc pixels_below_lines_set*(a: PTextTag): guint
proc set_pixels_below_lines_set*(a: PTextTag,
                                 `pixels_below_lines_set`: guint)
proc pixels_inside_wrap_set*(a: PTextTag): guint
proc set_pixels_inside_wrap_set*(a: PTextTag,
                                 `pixels_inside_wrap_set`: guint)
proc tabs_set*(a: PTextTag): guint
proc set_tabs_set*(a: PTextTag, `tabs_set`: guint)
proc underline_set*(a: PTextTag): guint
proc set_underline_set*(a: PTextTag, `underline_set`: guint)
proc wrap_mode_set*(a: PTextTag): guint
proc set_wrap_mode_set*(a: PTextTag, `wrap_mode_set`: guint)
proc bg_full_height_set*(a: PTextTag): guint
proc set_bg_full_height_set*(a: PTextTag, `bg_full_height_set`: guint)
proc invisible_set*(a: PTextTag): guint
proc set_invisible_set*(a: PTextTag, `invisible_set`: guint)
proc editable_set*(a: PTextTag): guint
proc set_editable_set*(a: PTextTag, `editable_set`: guint)
proc language_set*(a: PTextTag): guint
proc set_language_set*(a: PTextTag, `language_set`: guint)
proc pad1*(a: PTextTag): guint
proc set_pad1*(a: PTextTag, `pad1`: guint)
proc pad2*(a: PTextTag): guint
proc set_pad2*(a: PTextTag, `pad2`: guint)
proc pad3*(a: PTextTag): guint
proc set_pad3*(a: PTextTag, `pad3`: guint)
const
  bm_TGtkTextAppearance_underline* = 0x000F'i16
  bp_TGtkTextAppearance_underline* = 0'i16
  bm_TGtkTextAppearance_strikethrough* = 0x0010'i16
  bp_TGtkTextAppearance_strikethrough* = 4'i16
  bm_TGtkTextAppearance_draw_bg* = 0x0020'i16
  bp_TGtkTextAppearance_draw_bg* = 5'i16
  bm_TGtkTextAppearance_inside_selection* = 0x0040'i16
  bp_TGtkTextAppearance_inside_selection* = 6'i16
  bm_TGtkTextAppearance_is_text* = 0x0080'i16
  bp_TGtkTextAppearance_is_text* = 7'i16
  bm_TGtkTextAppearance_pad1* = 0x0100'i16
  bp_TGtkTextAppearance_pad1* = 8'i16
  bm_TGtkTextAppearance_pad2* = 0x0200'i16
  bp_TGtkTextAppearance_pad2* = 9'i16
  bm_TGtkTextAppearance_pad3* = 0x0400'i16
  bp_TGtkTextAppearance_pad3* = 10'i16
  bm_TGtkTextAppearance_pad4* = 0x0800'i16
  bp_TGtkTextAppearance_pad4* = 11'i16

proc underline*(a: PTextAppearance): guint
proc set_underline*(a: PTextAppearance, `underline`: guint)
proc strikethrough*(a: PTextAppearance): guint
proc set_strikethrough*(a: PTextAppearance, `strikethrough`: guint)
proc draw_bg*(a: PTextAppearance): guint
proc set_draw_bg*(a: PTextAppearance, `draw_bg`: guint)
proc inside_selection*(a: PTextAppearance): guint
proc set_inside_selection*(a: PTextAppearance, `inside_selection`: guint)
proc is_text*(a: PTextAppearance): guint
proc set_is_text*(a: PTextAppearance, `is_text`: guint)
proc pad1*(a: PTextAppearance): guint
proc set_pad1*(a: PTextAppearance, `pad1`: guint)
proc pad2*(a: PTextAppearance): guint
proc set_pad2*(a: PTextAppearance, `pad2`: guint)
proc pad3*(a: PTextAppearance): guint
proc set_pad3*(a: PTextAppearance, `pad3`: guint)
proc pad4*(a: PTextAppearance): guint
proc set_pad4*(a: PTextAppearance, `pad4`: guint)
const
  bm_TGtkTextAttributes_invisible* = 0x0001'i16
  bp_TGtkTextAttributes_invisible* = 0'i16
  bm_TGtkTextAttributes_bg_full_height* = 0x0002'i16
  bp_TGtkTextAttributes_bg_full_height* = 1'i16
  bm_TGtkTextAttributes_editable* = 0x0004'i16
  bp_TGtkTextAttributes_editable* = 2'i16
  bm_TGtkTextAttributes_realized* = 0x0008'i16
  bp_TGtkTextAttributes_realized* = 3'i16
  bm_TGtkTextAttributes_pad1* = 0x0010'i16
  bp_TGtkTextAttributes_pad1* = 4'i16
  bm_TGtkTextAttributes_pad2* = 0x0020'i16
  bp_TGtkTextAttributes_pad2* = 5'i16
  bm_TGtkTextAttributes_pad3* = 0x0040'i16
  bp_TGtkTextAttributes_pad3* = 6'i16
  bm_TGtkTextAttributes_pad4* = 0x0080'i16
  bp_TGtkTextAttributes_pad4* = 7'i16

proc invisible*(a: PTextAttributes): guint
proc set_invisible*(a: PTextAttributes, `invisible`: guint)
proc bg_full_height*(a: PTextAttributes): guint
proc set_bg_full_height*(a: PTextAttributes, `bg_full_height`: guint)
proc editable*(a: PTextAttributes): guint
proc set_editable*(a: PTextAttributes, `editable`: guint)
proc realized*(a: PTextAttributes): guint
proc set_realized*(a: PTextAttributes, `realized`: guint)
proc pad1*(a: PTextAttributes): guint
proc set_pad1*(a: PTextAttributes, `pad1`: guint)
proc pad2*(a: PTextAttributes): guint
proc set_pad2*(a: PTextAttributes, `pad2`: guint)
proc pad3*(a: PTextAttributes): guint
proc set_pad3*(a: PTextAttributes, `pad3`: guint)
proc pad4*(a: PTextAttributes): guint
proc set_pad4*(a: PTextAttributes, `pad4`: guint)
proc TYPE_TEXT_TAG_TABLE*(): GType
proc TEXT_TAG_TABLE*(obj: pointer): PTextTagTable
proc TEXT_TAG_TABLE_CLASS*(klass: pointer): PTextTagTableClass
proc IS_TEXT_TAG_TABLE*(obj: pointer): bool
proc IS_TEXT_TAG_TABLE_CLASS*(klass: pointer): bool
proc TEXT_TAG_TABLE_GET_CLASS*(obj: pointer): PTextTagTableClass
proc text_tag_table_get_type*(): GType{.cdecl, dynlib: lib,
                                        importc: "gtk_text_tag_table_get_type".}
proc text_tag_table_new*(): PTextTagTable{.cdecl, dynlib: lib,
    importc: "gtk_text_tag_table_new".}
proc table_add*(table: PTextTagTable, tag: PTextTag){.cdecl,
    dynlib: lib, importc: "gtk_text_tag_table_add".}
proc table_remove*(table: PTextTagTable, tag: PTextTag){.cdecl,
    dynlib: lib, importc: "gtk_text_tag_table_remove".}
proc table_lookup*(table: PTextTagTable, name: cstring): PTextTag{.
    cdecl, dynlib: lib, importc: "gtk_text_tag_table_lookup".}
proc table_foreach*(table: PTextTagTable, fun: TTextTagTableForeach,
                             data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_text_tag_table_foreach".}
proc table_get_size*(table: PTextTagTable): gint{.cdecl, dynlib: lib,
    importc: "gtk_text_tag_table_get_size".}
proc table_add_buffer*(table: PTextTagTable, buffer: gpointer){.cdecl,
    dynlib: lib, importc: "_gtk_text_tag_table_add_buffer".}
proc table_remove_buffer*(table: PTextTagTable, buffer: gpointer){.
    cdecl, dynlib: lib, importc: "_gtk_text_tag_table_remove_buffer".}
proc TYPE_TEXT_MARK*(): GType
proc TEXT_MARK*(anObject: pointer): PTextMark
proc TEXT_MARK_CLASS*(klass: pointer): PTextMarkClass
proc IS_TEXT_MARK*(anObject: pointer): bool
proc IS_TEXT_MARK_CLASS*(klass: pointer): bool
proc TEXT_MARK_GET_CLASS*(obj: pointer): PTextMarkClass
proc text_mark_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "gtk_text_mark_get_type".}
proc set_visible*(mark: PTextMark, setting: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_text_mark_set_visible".}
proc get_visible*(mark: PTextMark): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_mark_get_visible".}
proc get_name*(mark: PTextMark): cstring{.cdecl, dynlib: lib,
    importc: "gtk_text_mark_get_name".}
proc get_deleted*(mark: PTextMark): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_mark_get_deleted".}
proc get_buffer*(mark: PTextMark): PTextBuffer{.cdecl, dynlib: lib,
    importc: "gtk_text_mark_get_buffer".}
proc get_left_gravity*(mark: PTextMark): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_mark_get_left_gravity".}
const
  bm_TGtkTextMarkBody_visible* = 0x0001'i16
  bp_TGtkTextMarkBody_visible* = 0'i16
  bm_TGtkTextMarkBody_not_deleteable* = 0x0002'i16
  bp_TGtkTextMarkBody_not_deleteable* = 1'i16

proc visible*(a: PTextMarkBody): guint
proc set_visible*(a: PTextMarkBody, `visible`: guint)
proc not_deleteable*(a: PTextMarkBody): guint
proc set_not_deleteable*(a: PTextMarkBody, `not_deleteable`: guint)
proc mark_segment_new*(tree: PTextBTree, left_gravity: gboolean, name: cstring): PTextLineSegment{.
    cdecl, dynlib: lib, importc: "_gtk_mark_segment_new".}
proc TYPE_TEXT_CHILD_ANCHOR*(): GType
proc TEXT_CHILD_ANCHOR*(anObject: pointer): PTextChildAnchor
proc TEXT_CHILD_ANCHOR_CLASS*(klass: pointer): PTextChildAnchorClass
proc IS_TEXT_CHILD_ANCHOR*(anObject: pointer): bool
proc IS_TEXT_CHILD_ANCHOR_CLASS*(klass: pointer): bool
proc TEXT_CHILD_ANCHOR_GET_CLASS*(obj: pointer): PTextChildAnchorClass
proc text_child_anchor_get_type*(): GType{.cdecl, dynlib: lib,
    importc: "gtk_text_child_anchor_get_type".}
proc text_child_anchor_new*(): PTextChildAnchor{.cdecl, dynlib: lib,
    importc: "gtk_text_child_anchor_new".}
proc anchor_get_widgets*(anchor: PTextChildAnchor): PGList{.cdecl,
    dynlib: lib, importc: "gtk_text_child_anchor_get_widgets".}
proc anchor_get_deleted*(anchor: PTextChildAnchor): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_child_anchor_get_deleted".}
proc pixbuf_segment_new*(pixbuf: gdk2pixbuf.PPixbuf): PTextLineSegment{.cdecl,
    dynlib: lib, importc: "_gtk_pixbuf_segment_new".}
proc widget_segment_new*(anchor: PTextChildAnchor): PTextLineSegment{.cdecl,
    dynlib: lib, importc: "_gtk_widget_segment_new".}
proc widget_segment_add*(widget_segment: PTextLineSegment, child: PWidget){.
    cdecl, dynlib: lib, importc: "_gtk_widget_segment_add".}
proc widget_segment_remove*(widget_segment: PTextLineSegment, child: PWidget){.
    cdecl, dynlib: lib, importc: "_gtk_widget_segment_remove".}
proc widget_segment_ref*(widget_segment: PTextLineSegment){.cdecl, dynlib: lib,
    importc: "_gtk_widget_segment_ref".}
proc widget_segment_unref*(widget_segment: PTextLineSegment){.cdecl,
    dynlib: lib, importc: "_gtk_widget_segment_unref".}
proc anchored_child_get_layout*(child: PWidget): PTextLayout{.cdecl,
    dynlib: lib, importc: "_gtk_anchored_child_get_layout".}
proc line_segment_split*(iter: PTextIter): PTextLineSegment{.cdecl,
    dynlib: lib, importc: "gtk_text_line_segment_split".}
proc char_segment_new*(text: cstring, len: guint): PTextLineSegment{.cdecl,
    dynlib: lib, importc: "_gtk_char_segment_new".}
proc char_segment_new_from_two_strings*(text1: cstring, len1: guint,
                                        text2: cstring, len2: guint): PTextLineSegment{.
    cdecl, dynlib: lib, importc: "_gtk_char_segment_new_from_two_strings".}
proc toggle_segment_new*(info: PTextTagInfo, StateOn: gboolean): PTextLineSegment{.
    cdecl, dynlib: lib, importc: "_gtk_toggle_segment_new".}
proc btree_new*(table: PTextTagTable, buffer: PTextBuffer): PTextBTree{.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_new".}
proc reference*(tree: PTextBTree){.cdecl, dynlib: lib,
                                   importc: "_gtk_text_btree_ref".}
proc unref*(tree: PTextBTree){.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_unref".}
proc get_buffer*(tree: PTextBTree): PTextBuffer{.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_get_buffer".}
proc get_chars_changed_stamp*(tree: PTextBTree): guint{.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_get_chars_changed_stamp".}
proc get_segments_changed_stamp*(tree: PTextBTree): guint{.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_get_segments_changed_stamp".}
proc segments_changed*(tree: PTextBTree){.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_segments_changed".}
proc is_end*(tree: PTextBTree, line: PTextLine,
                        seg: PTextLineSegment, byte_index: int32,
                        char_offset: int32): gboolean{.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_is_end".}
proc btree_delete*(start: PTextIter, theEnd: PTextIter){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_delete".}
proc btree_insert*(iter: PTextIter, text: cstring, len: gint){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_insert".}
proc btree_insert_pixbuf*(iter: PTextIter, pixbuf: gdk2pixbuf.PPixbuf){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_insert_pixbuf".}
proc btree_insert_child_anchor*(iter: PTextIter, anchor: PTextChildAnchor){.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_insert_child_anchor".}
proc btree_unregister_child_anchor*(anchor: PTextChildAnchor){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_unregister_child_anchor".}
proc find_line_by_y*(tree: PTextBTree, view_id: gpointer,
                                ypixel: gint, line_top_y: Pgint): PTextLine{.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_find_line_by_y".}
proc find_line_top*(tree: PTextBTree, line: PTextLine,
                               view_id: gpointer): gint{.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_find_line_top".}
proc add_view*(tree: PTextBTree, layout: PTextLayout){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_add_view".}
proc remove_view*(tree: PTextBTree, view_id: gpointer){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_remove_view".}
proc invalidate_region*(tree: PTextBTree, start: PTextIter,
                                   theEnd: PTextIter){.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_invalidate_region".}
proc get_view_size*(tree: PTextBTree, view_id: gpointer,
                               width: Pgint, height: Pgint){.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_get_view_size".}
proc is_valid*(tree: PTextBTree, view_id: gpointer): gboolean{.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_is_valid".}
proc validate*(tree: PTextBTree, view_id: gpointer, max_pixels: gint,
                          y: Pgint, old_height: Pgint, new_height: Pgint): gboolean{.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_validate".}
proc validate_line*(tree: PTextBTree, line: PTextLine,
                               view_id: gpointer){.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_validate_line".}
proc btree_tag*(start: PTextIter, theEnd: PTextIter, tag: PTextTag,
                     apply: gboolean){.cdecl, dynlib: lib,
                                       importc: "_gtk_text_btree_tag".}
proc get_line*(tree: PTextBTree, line_number: gint,
                          real_line_number: Pgint): PTextLine{.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_get_line".}
proc get_line_no_last*(tree: PTextBTree, line_number: gint,
                                  real_line_number: Pgint): PTextLine{.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_get_line_no_last".}
proc get_end_iter_line*(tree: PTextBTree): PTextLine{.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_get_end_iter_line".}
proc get_line_at_char*(tree: PTextBTree, char_index: gint,
                                  line_start_index: Pgint,
                                  real_char_index: Pgint): PTextLine{.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_get_line_at_char".}
proc btree_get_tags*(iter: PTextIter, num_tags: Pgint): PPGtkTextTag{.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_get_tags".}
proc btree_get_text*(start: PTextIter, theEnd: PTextIter,
                          include_hidden: gboolean, include_nonchars: gboolean): cstring{.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_get_text".}
proc line_count*(tree: PTextBTree): gint{.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_line_count".}
proc char_count*(tree: PTextBTree): gint{.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_char_count".}
proc btree_char_is_invisible*(iter: PTextIter): gboolean{.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_char_is_invisible".}
proc get_iter_at_char*(tree: PTextBTree, iter: PTextIter,
                                  char_index: gint){.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_get_iter_at_char".}
proc get_iter_at_line_char*(tree: PTextBTree, iter: PTextIter,
                                       line_number: gint, char_index: gint){.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_get_iter_at_line_char".}
proc get_iter_at_line_byte*(tree: PTextBTree, iter: PTextIter,
                                       line_number: gint, byte_index: gint){.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_get_iter_at_line_byte".}
proc get_iter_from_string*(tree: PTextBTree, iter: PTextIter,
                                      `string`: cstring): gboolean{.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_get_iter_from_string".}
proc get_iter_at_mark_name*(tree: PTextBTree, iter: PTextIter,
                                       mark_name: cstring): gboolean{.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_get_iter_at_mark_name".}
proc get_iter_at_mark*(tree: PTextBTree, iter: PTextIter,
                                  mark: PTextMark){.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_get_iter_at_mark".}
proc get_end_iter*(tree: PTextBTree, iter: PTextIter){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_get_end_iter".}
proc get_iter_at_line*(tree: PTextBTree, iter: PTextIter,
                                  line: PTextLine, byte_offset: gint){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_get_iter_at_line".}
proc get_iter_at_first_toggle*(tree: PTextBTree, iter: PTextIter,
    tag: PTextTag): gboolean{.cdecl, dynlib: lib, importc: "_gtk_text_btree_get_iter_at_first_toggle".}
proc get_iter_at_last_toggle*(tree: PTextBTree, iter: PTextIter,
    tag: PTextTag): gboolean{.cdecl, dynlib: lib, importc: "_gtk_text_btree_get_iter_at_last_toggle".}
proc get_iter_at_child_anchor*(tree: PTextBTree, iter: PTextIter,
    anchor: PTextChildAnchor){.cdecl, dynlib: lib, importc: "_gtk_text_btree_get_iter_at_child_anchor".}
proc set_mark*(tree: PTextBTree, existing_mark: PTextMark,
                          name: cstring, left_gravity: gboolean,
                          index: PTextIter, should_exist: gboolean): PTextMark{.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_set_mark".}
proc remove_mark_by_name*(tree: PTextBTree, name: cstring){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_remove_mark_by_name".}
proc remove_mark*(tree: PTextBTree, segment: PTextMark){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_remove_mark".}
proc get_selection_bounds*(tree: PTextBTree, start: PTextIter,
                                      theEnd: PTextIter): gboolean{.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_get_selection_bounds".}
proc place_cursor*(tree: PTextBTree, `where`: PTextIter){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_place_cursor".}
proc mark_is_insert*(tree: PTextBTree, segment: PTextMark): gboolean{.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_mark_is_insert".}
proc mark_is_selection_bound*(tree: PTextBTree, segment: PTextMark): gboolean{.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_mark_is_selection_bound".}
proc get_mark_by_name*(tree: PTextBTree, name: cstring): PTextMark{.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_get_mark_by_name".}
proc first_could_contain_tag*(tree: PTextBTree, tag: PTextTag): PTextLine{.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_first_could_contain_tag".}
proc last_could_contain_tag*(tree: PTextBTree, tag: PTextTag): PTextLine{.
    cdecl, dynlib: lib, importc: "_gtk_text_btree_last_could_contain_tag".}
const
  bm_TGtkTextLineData_width* = 0x00FFFFFF'i32
  bp_TGtkTextLineData_width* = 0'i32
  bm_TGtkTextLineData_valid* = 0xFF000000'i32
  bp_TGtkTextLineData_valid* = 24'i32

proc width*(a: PTextLineData): gint
proc set_width*(a: PTextLineData, NewWidth: gint)
proc valid*(a: PTextLineData): gint
proc set_valid*(a: PTextLineData, `valid`: gint)
proc get_number*(line: PTextLine): gint{.cdecl, dynlib: lib,
    importc: "_gtk_text_line_get_number".}
proc char_has_tag*(line: PTextLine, tree: PTextBTree,
                             char_in_line: gint, tag: PTextTag): gboolean{.
    cdecl, dynlib: lib, importc: "_gtk_text_line_char_has_tag".}
proc byte_has_tag*(line: PTextLine, tree: PTextBTree,
                             byte_in_line: gint, tag: PTextTag): gboolean{.
    cdecl, dynlib: lib, importc: "_gtk_text_line_byte_has_tag".}
proc is_last*(line: PTextLine, tree: PTextBTree): gboolean{.cdecl,
    dynlib: lib, importc: "_gtk_text_line_is_last".}
proc contains_end_iter*(line: PTextLine, tree: PTextBTree): gboolean{.
    cdecl, dynlib: lib, importc: "_gtk_text_line_contains_end_iter".}
proc next*(line: PTextLine): PTextLine{.cdecl, dynlib: lib,
    importc: "_gtk_text_line_next".}
proc next_excluding_last*(line: PTextLine): PTextLine{.cdecl,
    dynlib: lib, importc: "_gtk_text_line_next_excluding_last".}
proc previous*(line: PTextLine): PTextLine{.cdecl, dynlib: lib,
    importc: "_gtk_text_line_previous".}
proc add_data*(line: PTextLine, data: PTextLineData){.cdecl,
    dynlib: lib, importc: "_gtk_text_line_add_data".}
proc remove_data*(line: PTextLine, view_id: gpointer): gpointer{.
    cdecl, dynlib: lib, importc: "_gtk_text_line_remove_data".}
proc get_data*(line: PTextLine, view_id: gpointer): gpointer{.cdecl,
    dynlib: lib, importc: "_gtk_text_line_get_data".}
proc invalidate_wrap*(line: PTextLine, ld: PTextLineData){.cdecl,
    dynlib: lib, importc: "_gtk_text_line_invalidate_wrap".}
proc char_count*(line: PTextLine): gint{.cdecl, dynlib: lib,
    importc: "_gtk_text_line_char_count".}
proc byte_count*(line: PTextLine): gint{.cdecl, dynlib: lib,
    importc: "_gtk_text_line_byte_count".}
proc char_index*(line: PTextLine): gint{.cdecl, dynlib: lib,
    importc: "_gtk_text_line_char_index".}
proc byte_to_segment*(line: PTextLine, byte_offset: gint,
                                seg_offset: Pgint): PTextLineSegment{.cdecl,
    dynlib: lib, importc: "_gtk_text_line_byte_to_segment".}
proc char_to_segment*(line: PTextLine, char_offset: gint,
                                seg_offset: Pgint): PTextLineSegment{.cdecl,
    dynlib: lib, importc: "_gtk_text_line_char_to_segment".}
proc byte_to_char_offsets*(line: PTextLine, byte_offset: gint,
                                     line_char_offset: Pgint,
                                     seg_char_offset: Pgint){.cdecl,
    dynlib: lib, importc: "_gtk_text_line_byte_to_char_offsets".}
proc char_to_byte_offsets*(line: PTextLine, char_offset: gint,
                                     line_byte_offset: Pgint,
                                     seg_byte_offset: Pgint){.cdecl,
    dynlib: lib, importc: "_gtk_text_line_char_to_byte_offsets".}
proc byte_to_any_segment*(line: PTextLine, byte_offset: gint,
                                    seg_offset: Pgint): PTextLineSegment{.cdecl,
    dynlib: lib, importc: "_gtk_text_line_byte_to_any_segment".}
proc char_to_any_segment*(line: PTextLine, char_offset: gint,
                                    seg_offset: Pgint): PTextLineSegment{.cdecl,
    dynlib: lib, importc: "_gtk_text_line_char_to_any_segment".}
proc byte_to_char*(line: PTextLine, byte_offset: gint): gint{.cdecl,
    dynlib: lib, importc: "_gtk_text_line_byte_to_char".}
proc char_to_byte*(line: PTextLine, char_offset: gint): gint{.cdecl,
    dynlib: lib, importc: "_gtk_text_line_char_to_byte".}
proc next_could_contain_tag*(line: PTextLine, tree: PTextBTree,
                                       tag: PTextTag): PTextLine{.cdecl,
    dynlib: lib, importc: "_gtk_text_line_next_could_contain_tag".}
proc previous_could_contain_tag*(line: PTextLine, tree: PTextBTree,
    tag: PTextTag): PTextLine{.cdecl, dynlib: lib, importc: "_gtk_text_line_previous_could_contain_tag".}
proc line_data_new*(layout: PTextLayout, line: PTextLine): PTextLineData{.
    cdecl, dynlib: lib, importc: "_gtk_text_line_data_new".}
proc check*(tree: PTextBTree){.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_check".}
proc spew*(tree: PTextBTree){.cdecl, dynlib: lib,
    importc: "_gtk_text_btree_spew".}
proc toggle_segment_check_func*(segPtr: PTextLineSegment, line: PTextLine){.
    cdecl, dynlib: lib, importc: "_gtk_toggle_segment_check_func".}
proc change_node_toggle_count*(node: PTextBTreeNode, info: PTextTagInfo,
                               delta: gint){.cdecl, dynlib: lib,
    importc: "_gtk_change_node_toggle_count".}
proc release_mark_segment*(tree: PTextBTree,
                                      segment: PTextLineSegment){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_release_mark_segment".}
proc notify_will_remove_tag*(tree: PTextBTree, tag: PTextTag){.cdecl,
    dynlib: lib, importc: "_gtk_text_btree_notify_will_remove_tag".}
const
  bm_TGtkTextBuffer_modified* = 0x0001'i16
  bp_TGtkTextBuffer_modified* = 0'i16

proc TYPE_TEXT_BUFFER*(): GType
proc TEXT_BUFFER*(obj: pointer): PTextBuffer
proc TEXT_BUFFER_CLASS*(klass: pointer): PTextBufferClass
proc IS_TEXT_BUFFER*(obj: pointer): bool
proc IS_TEXT_BUFFER_CLASS*(klass: pointer): bool
proc TEXT_BUFFER_GET_CLASS*(obj: pointer): PTextBufferClass
proc modified*(a: PTextBuffer): guint
proc set_modified*(a: PTextBuffer, `modified`: guint)
proc text_buffer_get_type*(): GType{.cdecl, dynlib: lib,
                                     importc: "gtk_text_buffer_get_type".}
proc text_buffer_new*(table: PTextTagTable): PTextBuffer{.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_new".}
proc get_line_count*(buffer: PTextBuffer): gint{.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_get_line_count".}
proc get_char_count*(buffer: PTextBuffer): gint{.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_get_char_count".}
proc get_tag_table*(buffer: PTextBuffer): PTextTagTable{.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_get_tag_table".}
proc set_text*(buffer: PTextBuffer, text: cstring, len: gint){.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_set_text".}
proc insert*(buffer: PTextBuffer, iter: PTextIter, text: cstring,
                         len: gint){.cdecl, dynlib: lib,
                                     importc: "gtk_text_buffer_insert".}
proc insert_at_cursor*(buffer: PTextBuffer, text: cstring, len: gint){.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_insert_at_cursor".}
proc insert_interactive*(buffer: PTextBuffer, iter: PTextIter,
                                     text: cstring, len: gint,
                                     default_editable: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_insert_interactive".}
proc insert_interactive_at_cursor*(buffer: PTextBuffer,
    text: cstring, len: gint, default_editable: gboolean): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_insert_interactive_at_cursor".}
proc insert_range*(buffer: PTextBuffer, iter: PTextIter,
                               start: PTextIter, theEnd: PTextIter){.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_insert_range".}
proc insert_range_interactive*(buffer: PTextBuffer, iter: PTextIter,
    start: PTextIter, theEnd: PTextIter, default_editable: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_insert_range_interactive".}
proc delete*(buffer: PTextBuffer, start: PTextIter,
                         theEnd: PTextIter){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_delete".}
proc delete_interactive*(buffer: PTextBuffer, start_iter: PTextIter,
                                     end_iter: PTextIter,
                                     default_editable: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_delete_interactive".}
proc get_text*(buffer: PTextBuffer, start: PTextIter,
                           theEnd: PTextIter, include_hidden_chars: gboolean): cstring{.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_get_text".}
proc get_slice*(buffer: PTextBuffer, start: PTextIter,
                            theEnd: PTextIter, include_hidden_chars: gboolean): cstring{.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_get_slice".}
proc insert_pixbuf*(buffer: PTextBuffer, iter: PTextIter,
                                pixbuf: gdk2pixbuf.PPixbuf){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_insert_pixbuf".}
proc insert_child_anchor*(buffer: PTextBuffer, iter: PTextIter,
                                      anchor: PTextChildAnchor){.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_insert_child_anchor".}
proc create_child_anchor*(buffer: PTextBuffer, iter: PTextIter): PTextChildAnchor{.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_create_child_anchor".}
proc create_mark*(buffer: PTextBuffer, mark_name: cstring,
                              `where`: PTextIter, left_gravity: gboolean): PTextMark{.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_create_mark".}
proc move_mark*(buffer: PTextBuffer, mark: PTextMark,
                            `where`: PTextIter){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_move_mark".}
proc delete_mark*(buffer: PTextBuffer, mark: PTextMark){.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_delete_mark".}
proc get_mark*(buffer: PTextBuffer, name: cstring): PTextMark{.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_get_mark".}
proc move_mark_by_name*(buffer: PTextBuffer, name: cstring,
                                    `where`: PTextIter){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_move_mark_by_name".}
proc delete_mark_by_name*(buffer: PTextBuffer, name: cstring){.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_delete_mark_by_name".}
proc get_insert*(buffer: PTextBuffer): PTextMark{.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_get_insert".}
proc get_selection_bound*(buffer: PTextBuffer): PTextMark{.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_get_selection_bound".}
proc place_cursor*(buffer: PTextBuffer, `where`: PTextIter){.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_place_cursor".}
proc apply_tag*(buffer: PTextBuffer, tag: PTextTag,
                            start: PTextIter, theEnd: PTextIter){.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_apply_tag".}
proc remove_tag*(buffer: PTextBuffer, tag: PTextTag,
                             start: PTextIter, theEnd: PTextIter){.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_remove_tag".}
proc apply_tag_by_name*(buffer: PTextBuffer, name: cstring,
                                    start: PTextIter, theEnd: PTextIter){.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_apply_tag_by_name".}
proc remove_tag_by_name*(buffer: PTextBuffer, name: cstring,
                                     start: PTextIter, theEnd: PTextIter){.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_remove_tag_by_name".}
proc remove_all_tags*(buffer: PTextBuffer, start: PTextIter,
                                  theEnd: PTextIter){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_remove_all_tags".}
proc get_iter_at_line_offset*(buffer: PTextBuffer, iter: PTextIter,
    line_number: gint, char_offset: gint){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_get_iter_at_line_offset".}
proc get_iter_at_line_index*(buffer: PTextBuffer, iter: PTextIter,
    line_number: gint, byte_index: gint){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_get_iter_at_line_index".}
proc get_iter_at_offset*(buffer: PTextBuffer, iter: PTextIter,
                                     char_offset: gint){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_get_iter_at_offset".}
proc get_iter_at_line*(buffer: PTextBuffer, iter: PTextIter,
                                   line_number: gint){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_get_iter_at_line".}
proc get_start_iter*(buffer: PTextBuffer, iter: PTextIter){.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_get_start_iter".}
proc get_end_iter*(buffer: PTextBuffer, iter: PTextIter){.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_get_end_iter".}
proc get_bounds*(buffer: PTextBuffer, start: PTextIter,
                             theEnd: PTextIter){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_get_bounds".}
proc get_iter_at_mark*(buffer: PTextBuffer, iter: PTextIter,
                                   mark: PTextMark){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_get_iter_at_mark".}
proc get_iter_at_child_anchor*(buffer: PTextBuffer, iter: PTextIter,
    anchor: PTextChildAnchor){.cdecl, dynlib: lib, importc: "gtk_text_buffer_get_iter_at_child_anchor".}
proc get_modified*(buffer: PTextBuffer): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_get_modified".}
proc set_modified*(buffer: PTextBuffer, setting: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_set_modified".}
proc add_selection_clipboard*(buffer: PTextBuffer,
    clipboard: PClipboard){.cdecl, dynlib: lib,
                            importc: "gtk_text_buffer_add_selection_clipboard".}
proc remove_selection_clipboard*(buffer: PTextBuffer,
    clipboard: PClipboard){.cdecl, dynlib: lib, importc: "gtk_text_buffer_remove_selection_clipboard".}
proc cut_clipboard*(buffer: PTextBuffer, clipboard: PClipboard,
                                default_editable: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_cut_clipboard".}
proc copy_clipboard*(buffer: PTextBuffer, clipboard: PClipboard){.
    cdecl, dynlib: lib, importc: "gtk_text_buffer_copy_clipboard".}
proc paste_clipboard*(buffer: PTextBuffer, clipboard: PClipboard,
                                  override_location: PTextIter,
                                  default_editable: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_paste_clipboard".}
proc get_selection_bounds*(buffer: PTextBuffer, start: PTextIter,
                                       theEnd: PTextIter): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_get_selection_bounds".}
proc delete_selection*(buffer: PTextBuffer, interactive: gboolean,
                                   default_editable: gboolean): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_delete_selection".}
proc begin_user_action*(buffer: PTextBuffer){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_begin_user_action".}
proc end_user_action*(buffer: PTextBuffer){.cdecl, dynlib: lib,
    importc: "gtk_text_buffer_end_user_action".}
proc spew*(buffer: PTextBuffer){.cdecl, dynlib: lib,
    importc: "_gtk_text_buffer_spew".}
proc get_btree*(buffer: PTextBuffer): PTextBTree{.cdecl,
    dynlib: lib, importc: "_gtk_text_buffer_get_btree".}
proc get_line_log_attrs*(buffer: PTextBuffer,
                                     anywhere_in_line: PTextIter,
                                     char_len: Pgint): pango.PLogAttr{.cdecl,
    dynlib: lib, importc: "_gtk_text_buffer_get_line_log_attrs".}
proc notify_will_remove_tag*(buffer: PTextBuffer, tag: PTextTag){.
    cdecl, dynlib: lib, importc: "_gtk_text_buffer_notify_will_remove_tag".}
proc get_has_selection*(buffer: PTextBuffer): bool {.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_get_has_selection".}
proc select_range*(buffer: PTextBuffer, ins,
    bound: PTextIter) {.cdecl, dynlib: lib, importc: "gtk_text_buffer_select_range".}
proc backspace*(buffer: PTextBuffer, iter: PTextIter,
    interactive, defaultEditable: bool): bool {.cdecl,
    dynlib: lib, importc: "gtk_text_buffer_backspace".}

proc TYPE_TEXT_LAYOUT*(): GType
proc TEXT_LAYOUT*(obj: pointer): PTextLayout
proc TEXT_LAYOUT_CLASS*(klass: pointer): PTextLayoutClass
proc IS_TEXT_LAYOUT*(obj: pointer): bool
proc IS_TEXT_LAYOUT_CLASS*(klass: pointer): bool
proc TEXT_LAYOUT_GET_CLASS*(obj: pointer): PTextLayoutClass
const
  bm_TGtkTextLayout_cursor_visible* = 0x0001'i16
  bp_TGtkTextLayout_cursor_visible* = 0'i16
  bm_TGtkTextLayout_cursor_direction* = 0x0006'i16
  bp_TGtkTextLayout_cursor_direction* = 1'i16

proc cursor_visible*(a: PTextLayout): guint
proc set_cursor_visible*(a: PTextLayout, `cursor_visible`: guint)
proc cursor_direction*(a: PTextLayout): gint
proc set_cursor_direction*(a: PTextLayout, `cursor_direction`: gint)
const
  bm_TGtkTextCursorDisplay_is_strong* = 0x0001'i16
  bp_TGtkTextCursorDisplay_is_strong* = 0'i16
  bm_TGtkTextCursorDisplay_is_weak* = 0x0002'i16
  bp_TGtkTextCursorDisplay_is_weak* = 1'i16

proc is_strong*(a: PTextCursorDisplay): guint
proc set_is_strong*(a: PTextCursorDisplay, `is_strong`: guint)
proc is_weak*(a: PTextCursorDisplay): guint
proc set_is_weak*(a: PTextCursorDisplay, `is_weak`: guint)
proc text_layout_get_type*(): GType{.cdecl, dynlib: lib,
                                     importc: "gtk_text_layout_get_type".}
proc text_layout_new*(): PTextLayout{.cdecl, dynlib: lib,
                                      importc: "gtk_text_layout_new".}
proc set_buffer*(layout: PTextLayout, buffer: PTextBuffer){.cdecl,
    dynlib: lib, importc: "gtk_text_layout_set_buffer".}
proc get_buffer*(layout: PTextLayout): PTextBuffer{.cdecl,
    dynlib: lib, importc: "gtk_text_layout_get_buffer".}
proc set_default_style*(layout: PTextLayout, values: PTextAttributes){.
    cdecl, dynlib: lib, importc: "gtk_text_layout_set_default_style".}
proc set_contexts*(layout: PTextLayout, ltr_context: pango.PContext,
                               rtl_context: pango.PContext){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_set_contexts".}
proc set_cursor_direction*(layout: PTextLayout,
                                       direction: TTextDirection){.cdecl,
    dynlib: lib, importc: "gtk_text_layout_set_cursor_direction".}
proc default_style_changed*(layout: PTextLayout){.cdecl,
    dynlib: lib, importc: "gtk_text_layout_default_style_changed".}
proc set_screen_width*(layout: PTextLayout, width: gint){.cdecl,
    dynlib: lib, importc: "gtk_text_layout_set_screen_width".}
proc set_preedit_string*(layout: PTextLayout,
                                     preedit_string: cstring,
                                     preedit_attrs: pango.PAttrList,
                                     cursor_pos: gint){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_set_preedit_string".}
proc set_cursor_visible*(layout: PTextLayout,
                                     cursor_visible: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_text_layout_set_cursor_visible".}
proc get_cursor_visible*(layout: PTextLayout): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_layout_get_cursor_visible".}
proc get_size*(layout: PTextLayout, width: Pgint, height: Pgint){.
    cdecl, dynlib: lib, importc: "gtk_text_layout_get_size".}
proc get_lines*(layout: PTextLayout, top_y: gint, bottom_y: gint,
                            first_line_y: Pgint): PGSList{.cdecl, dynlib: lib,
    importc: "gtk_text_layout_get_lines".}
proc wrap_loop_start*(layout: PTextLayout){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_wrap_loop_start".}
proc wrap_loop_end*(layout: PTextLayout){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_wrap_loop_end".}
proc get_line_display*(layout: PTextLayout, line: PTextLine,
                                   size_only: gboolean): PTextLineDisplay{.
    cdecl, dynlib: lib, importc: "gtk_text_layout_get_line_display".}
proc free_line_display*(layout: PTextLayout,
                                    display: PTextLineDisplay){.cdecl,
    dynlib: lib, importc: "gtk_text_layout_free_line_display".}
proc get_line_at_y*(layout: PTextLayout, target_iter: PTextIter,
                                y: gint, line_top: Pgint){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_get_line_at_y".}
proc get_iter_at_pixel*(layout: PTextLayout, iter: PTextIter,
                                    x: gint, y: gint){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_get_iter_at_pixel".}
proc invalidate*(layout: PTextLayout, start: PTextIter,
                             theEnd: PTextIter){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_invalidate".}
proc free_line_data*(layout: PTextLayout, line: PTextLine,
                                 line_data: PTextLineData){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_free_line_data".}
proc is_valid*(layout: PTextLayout): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_layout_is_valid".}
proc validate_yrange*(layout: PTextLayout, anchor_line: PTextIter,
                                  y0: gint, y1: gint){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_validate_yrange".}
proc validate*(layout: PTextLayout, max_pixels: gint){.cdecl,
    dynlib: lib, importc: "gtk_text_layout_validate".}
proc wrap*(layout: PTextLayout, line: PTextLine,
                       line_data: PTextLineData): PTextLineData{.cdecl,
    dynlib: lib, importc: "gtk_text_layout_wrap".}
proc changed*(layout: PTextLayout, y: gint, old_height: gint,
                          new_height: gint){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_changed".}
proc get_iter_location*(layout: PTextLayout, iter: PTextIter,
                                    rect: gdk2.PRectangle){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_get_iter_location".}
proc get_line_yrange*(layout: PTextLayout, iter: PTextIter,
                                  y: Pgint, height: Pgint){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_get_line_yrange".}
proc get_line_xrange*(layout: PTextLayout, iter: PTextIter,
                                  x: Pgint, width: Pgint){.cdecl, dynlib: lib,
    importc: "_gtk_text_layout_get_line_xrange".}
proc get_cursor_locations*(layout: PTextLayout, iter: PTextIter,
                                       strong_pos: gdk2.PRectangle,
                                       weak_pos: gdk2.PRectangle){.cdecl,
    dynlib: lib, importc: "gtk_text_layout_get_cursor_locations".}
proc clamp_iter_to_vrange*(layout: PTextLayout, iter: PTextIter,
                                       top: gint, bottom: gint): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_layout_clamp_iter_to_vrange".}
proc move_iter_to_line_end*(layout: PTextLayout, iter: PTextIter,
                                        direction: gint): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_layout_move_iter_to_line_end".}
proc move_iter_to_previous_line*(layout: PTextLayout,
    iter: PTextIter): gboolean{.cdecl, dynlib: lib, importc: "gtk_text_layout_move_iter_to_previous_line".}
proc move_iter_to_next_line*(layout: PTextLayout, iter: PTextIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_layout_move_iter_to_next_line".}
proc move_iter_to_x*(layout: PTextLayout, iter: PTextIter, x: gint){.
    cdecl, dynlib: lib, importc: "gtk_text_layout_move_iter_to_x".}
proc move_iter_visually*(layout: PTextLayout, iter: PTextIter,
                                     count: gint): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_text_layout_move_iter_visually".}
proc iter_starts_line*(layout: PTextLayout, iter: PTextIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_layout_iter_starts_line".}
proc get_iter_at_line*(layout: PTextLayout, iter: PTextIter,
                                   line: PTextLine, byte_offset: gint){.cdecl,
    dynlib: lib, importc: "gtk_text_layout_get_iter_at_line".}
proc anchor_register_child*(anchor: PTextChildAnchor, child: PWidget,
                                       layout: PTextLayout){.cdecl, dynlib: lib,
    importc: "gtk_text_child_anchor_register_child".}
proc anchor_unregister_child*(anchor: PTextChildAnchor,
    child: PWidget){.cdecl, dynlib: lib,
                     importc: "gtk_text_child_anchor_unregister_child".}
proc anchor_queue_resize*(anchor: PTextChildAnchor,
                                     layout: PTextLayout){.cdecl, dynlib: lib,
    importc: "gtk_text_child_anchor_queue_resize".}
proc text_anchored_child_set_layout*(child: PWidget, layout: PTextLayout){.
    cdecl, dynlib: lib, importc: "gtk_text_anchored_child_set_layout".}
proc spew*(layout: PTextLayout){.cdecl, dynlib: lib,
    importc: "gtk_text_layout_spew".}
const                         # GTK_TEXT_VIEW_PRIORITY_VALIDATE* = GDK_PRIORITY_REDRAW + 5
  bm_TGtkTextView_editable* = 0x0001'i16
  bp_TGtkTextView_editable* = 0'i16
  bm_TGtkTextView_overwrite_mode* = 0x0002'i16
  bp_TGtkTextView_overwrite_mode* = 1'i16
  bm_TGtkTextView_cursor_visible* = 0x0004'i16
  bp_TGtkTextView_cursor_visible* = 2'i16
  bm_TGtkTextView_need_im_reset* = 0x0008'i16
  bp_TGtkTextView_need_im_reset* = 3'i16
  bm_TGtkTextView_just_selected_element* = 0x0010'i16
  bp_TGtkTextView_just_selected_element* = 4'i16
  bm_TGtkTextView_disable_scroll_on_focus* = 0x0020'i16
  bp_TGtkTextView_disable_scroll_on_focus* = 5'i16
  bm_TGtkTextView_onscreen_validated* = 0x0040'i16
  bp_TGtkTextView_onscreen_validated* = 6'i16
  bm_TGtkTextView_mouse_cursor_obscured* = 0x0080'i16
  bp_TGtkTextView_mouse_cursor_obscured* = 7'i16

proc TYPE_TEXT_VIEW*(): GType
proc TEXT_VIEW*(obj: pointer): PTextView
proc TEXT_VIEW_CLASS*(klass: pointer): PTextViewClass
proc IS_TEXT_VIEW*(obj: pointer): bool
proc IS_TEXT_VIEW_CLASS*(klass: pointer): bool
proc TEXT_VIEW_GET_CLASS*(obj: pointer): PTextViewClass
proc editable*(a: PTextView): guint
proc set_editable*(a: PTextView, `editable`: guint)
proc overwrite_mode*(a: PTextView): guint
proc set_overwrite_mode*(a: PTextView, `overwrite_mode`: guint)
proc cursor_visible*(a: PTextView): guint
proc set_cursor_visible*(a: PTextView, `cursor_visible`: guint)
proc need_im_reset*(a: PTextView): guint
proc set_need_im_reset*(a: PTextView, `need_im_reset`: guint)
proc just_selected_element*(a: PTextView): guint
proc set_just_selected_element*(a: PTextView, `just_selected_element`: guint)
proc disable_scroll_on_focus*(a: PTextView): guint
proc set_disable_scroll_on_focus*(a: PTextView,
                                  `disable_scroll_on_focus`: guint)
proc onscreen_validated*(a: PTextView): guint
proc set_onscreen_validated*(a: PTextView, `onscreen_validated`: guint)
proc mouse_cursor_obscured*(a: PTextView): guint
proc set_mouse_cursor_obscured*(a: PTextView, `mouse_cursor_obscured`: guint)
proc text_view_get_type*(): TType{.cdecl, dynlib: lib,
                                   importc: "gtk_text_view_get_type".}
proc text_view_new*(): PTextView{.cdecl, dynlib: lib,
                                  importc: "gtk_text_view_new".}
proc text_view_new*(buffer: PTextBuffer): PTextView{.cdecl,
    dynlib: lib, importc: "gtk_text_view_new_with_buffer".}
proc set_buffer*(text_view: PTextView, buffer: PTextBuffer){.cdecl,
    dynlib: lib, importc: "gtk_text_view_set_buffer".}
proc get_buffer*(text_view: PTextView): PTextBuffer{.cdecl,
    dynlib: lib, importc: "gtk_text_view_get_buffer".}
proc scroll_to_iter*(text_view: PTextView, iter: PTextIter,
                               within_margin: gdouble, use_align: gboolean,
                               xalign: gdouble, yalign: gdouble): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_view_scroll_to_iter".}
proc scroll_to_mark*(text_view: PTextView, mark: PTextMark,
                               within_margin: gdouble, use_align: gboolean,
                               xalign: gdouble, yalign: gdouble){.cdecl,
    dynlib: lib, importc: "gtk_text_view_scroll_to_mark".}
proc scroll_mark_onscreen*(text_view: PTextView, mark: PTextMark){.
    cdecl, dynlib: lib, importc: "gtk_text_view_scroll_mark_onscreen".}
proc move_mark_onscreen*(text_view: PTextView, mark: PTextMark): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_view_move_mark_onscreen".}
proc place_cursor_onscreen*(text_view: PTextView): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_view_place_cursor_onscreen".}
proc get_visible_rect*(text_view: PTextView,
                                 visible_rect: gdk2.PRectangle){.cdecl,
    dynlib: lib, importc: "gtk_text_view_get_visible_rect".}
proc set_cursor_visible*(text_view: PTextView, setting: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_text_view_set_cursor_visible".}
proc get_cursor_visible*(text_view: PTextView): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_view_get_cursor_visible".}
proc get_iter_location*(text_view: PTextView, iter: PTextIter,
                                  location: gdk2.PRectangle){.cdecl, dynlib: lib,
    importc: "gtk_text_view_get_iter_location".}
proc get_iter_at_location*(text_view: PTextView, iter: PTextIter,
                                     x: gint, y: gint){.cdecl, dynlib: lib,
    importc: "gtk_text_view_get_iter_at_location".}
proc get_line_yrange*(text_view: PTextView, iter: PTextIter, y: Pgint,
                                height: Pgint){.cdecl, dynlib: lib,
    importc: "gtk_text_view_get_line_yrange".}
proc get_line_at_y*(text_view: PTextView, target_iter: PTextIter,
                              y: gint, line_top: Pgint){.cdecl, dynlib: lib,
    importc: "gtk_text_view_get_line_at_y".}
proc buffer_to_window_coords*(text_view: PTextView,
                                        win: TTextWindowType, buffer_x: gint,
                                        buffer_y: gint, window_x: Pgint,
                                        window_y: Pgint){.cdecl, dynlib: lib,
    importc: "gtk_text_view_buffer_to_window_coords".}
proc window_to_buffer_coords*(text_view: PTextView,
                                        win: TTextWindowType, window_x: gint,
                                        window_y: gint, buffer_x: Pgint,
                                        buffer_y: Pgint){.cdecl, dynlib: lib,
    importc: "gtk_text_view_window_to_buffer_coords".}
proc get_window*(text_view: PTextView, win: TTextWindowType): gdk2.PWindow{.
    cdecl, dynlib: lib, importc: "gtk_text_view_get_window".}
proc get_window_type*(text_view: PTextView, window: gdk2.PWindow): TTextWindowType{.
    cdecl, dynlib: lib, importc: "gtk_text_view_get_window_type".}
proc set_border_window_size*(text_view: PTextView,
                                       thetype: TTextWindowType, size: gint){.
    cdecl, dynlib: lib, importc: "gtk_text_view_set_border_window_size".}
proc get_border_window_size*(text_view: PTextView,
                                       thetype: TTextWindowType): gint{.cdecl,
    dynlib: lib, importc: "gtk_text_view_get_border_window_size".}
proc forward_display_line*(text_view: PTextView, iter: PTextIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_view_forward_display_line".}
proc backward_display_line*(text_view: PTextView, iter: PTextIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_view_backward_display_line".}
proc forward_display_line_end*(text_view: PTextView, iter: PTextIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_view_forward_display_line_end".}
proc backward_display_line_start*(text_view: PTextView,
    iter: PTextIter): gboolean{.cdecl, dynlib: lib, importc: "gtk_text_view_backward_display_line_start".}
proc starts_display_line*(text_view: PTextView, iter: PTextIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_view_starts_display_line".}
proc move_visually*(text_view: PTextView, iter: PTextIter, count: gint): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_text_view_move_visually".}
proc add_child_at_anchor*(text_view: PTextView, child: PWidget,
                                    anchor: PTextChildAnchor){.cdecl,
    dynlib: lib, importc: "gtk_text_view_add_child_at_anchor".}
proc add_child_in_window*(text_view: PTextView, child: PWidget,
                                    which_window: TTextWindowType, xpos: gint,
                                    ypos: gint){.cdecl, dynlib: lib,
    importc: "gtk_text_view_add_child_in_window".}
proc move_child*(text_view: PTextView, child: PWidget, xpos: gint,
                           ypos: gint){.cdecl, dynlib: lib,
                                        importc: "gtk_text_view_move_child".}
proc set_wrap_mode*(text_view: PTextView, wrap_mode: TWrapMode){.
    cdecl, dynlib: lib, importc: "gtk_text_view_set_wrap_mode".}
proc get_wrap_mode*(text_view: PTextView): TWrapMode{.cdecl,
    dynlib: lib, importc: "gtk_text_view_get_wrap_mode".}
proc set_editable*(text_view: PTextView, setting: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_text_view_set_editable".}
proc get_editable*(text_view: PTextView): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_text_view_get_editable".}
proc set_pixels_above_lines*(text_view: PTextView,
                                       pixels_above_lines: gint){.cdecl,
    dynlib: lib, importc: "gtk_text_view_set_pixels_above_lines".}
proc get_pixels_above_lines*(text_view: PTextView): gint{.cdecl,
    dynlib: lib, importc: "gtk_text_view_get_pixels_above_lines".}
proc set_pixels_below_lines*(text_view: PTextView,
                                       pixels_below_lines: gint){.cdecl,
    dynlib: lib, importc: "gtk_text_view_set_pixels_below_lines".}
proc get_pixels_below_lines*(text_view: PTextView): gint{.cdecl,
    dynlib: lib, importc: "gtk_text_view_get_pixels_below_lines".}
proc set_pixels_inside_wrap*(text_view: PTextView,
                                       pixels_inside_wrap: gint){.cdecl,
    dynlib: lib, importc: "gtk_text_view_set_pixels_inside_wrap".}
proc get_pixels_inside_wrap*(text_view: PTextView): gint{.cdecl,
    dynlib: lib, importc: "gtk_text_view_get_pixels_inside_wrap".}
proc set_justification*(text_view: PTextView,
                                  justification: TJustification){.cdecl,
    dynlib: lib, importc: "gtk_text_view_set_justification".}
proc get_justification*(text_view: PTextView): TJustification{.cdecl,
    dynlib: lib, importc: "gtk_text_view_get_justification".}
proc set_left_margin*(text_view: PTextView, left_margin: gint){.cdecl,
    dynlib: lib, importc: "gtk_text_view_set_left_margin".}
proc get_left_margin*(text_view: PTextView): gint{.cdecl, dynlib: lib,
    importc: "gtk_text_view_get_left_margin".}
proc set_right_margin*(text_view: PTextView, right_margin: gint){.
    cdecl, dynlib: lib, importc: "gtk_text_view_set_right_margin".}
proc get_right_margin*(text_view: PTextView): gint{.cdecl,
    dynlib: lib, importc: "gtk_text_view_get_right_margin".}
proc set_indent*(text_view: PTextView, indent: gint){.cdecl,
    dynlib: lib, importc: "gtk_text_view_set_indent".}
proc get_indent*(text_view: PTextView): gint{.cdecl, dynlib: lib,
    importc: "gtk_text_view_get_indent".}
proc set_tabs*(text_view: PTextView, tabs: pango.PTabArray){.cdecl,
    dynlib: lib, importc: "gtk_text_view_set_tabs".}
proc get_tabs*(text_view: PTextView): pango.PTabArray{.cdecl,
    dynlib: lib, importc: "gtk_text_view_get_tabs".}
proc get_default_attributes*(text_view: PTextView): PTextAttributes{.
    cdecl, dynlib: lib, importc: "gtk_text_view_get_default_attributes".}
const
  bm_TGtkTipsQuery_emit_always* = 0x0001'i16
  bp_TGtkTipsQuery_emit_always* = 0'i16
  bm_TGtkTipsQuery_in_query* = 0x0002'i16
  bp_TGtkTipsQuery_in_query* = 1'i16

proc TYPE_TIPS_QUERY*(): GType
proc TIPS_QUERY*(obj: pointer): PTipsQuery
proc TIPS_QUERY_CLASS*(klass: pointer): PTipsQueryClass
proc IS_TIPS_QUERY*(obj: pointer): bool
proc IS_TIPS_QUERY_CLASS*(klass: pointer): bool
proc TIPS_QUERY_GET_CLASS*(obj: pointer): PTipsQueryClass
proc emit_always*(a: PTipsQuery): guint
proc set_emit_always*(a: PTipsQuery, `emit_always`: guint)
proc in_query*(a: PTipsQuery): guint
proc set_in_query*(a: PTipsQuery, `in_query`: guint)
proc tips_query_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_tips_query_get_type".}
proc tips_query_new*(): PTipsQuery{.cdecl, dynlib: lib,
                                    importc: "gtk_tips_query_new".}
proc start_query*(tips_query: PTipsQuery){.cdecl, dynlib: lib,
    importc: "gtk_tips_query_start_query".}
proc stop_query*(tips_query: PTipsQuery){.cdecl, dynlib: lib,
    importc: "gtk_tips_query_stop_query".}
proc set_caller*(tips_query: PTipsQuery, caller: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_tips_query_set_caller".}
proc set_labels*(tips_query: PTipsQuery, label_inactive: cstring,
                            label_no_tip: cstring){.cdecl, dynlib: lib,
    importc: "gtk_tips_query_set_labels".}
const
  bm_TGtkTooltips_delay* = 0x3FFFFFFF'i32
  bp_TGtkTooltips_delay* = 0'i32
  bm_TGtkTooltips_enabled* = 0x40000000'i32
  bp_TGtkTooltips_enabled* = 30'i32
  bm_TGtkTooltips_have_grab* = 0x80000000'i32
  bp_TGtkTooltips_have_grab* = 31'i32
  bm_TGtkTooltips_use_sticky_delay* = 0x00000001'i32
  bp_TGtkTooltips_use_sticky_delay* = 0'i32

proc TYPE_TOOLTIPS*(): GType
proc TOOLTIPS*(obj: pointer): PTooltips
proc TOOLTIPS_CLASS*(klass: pointer): PTooltipsClass
proc IS_TOOLTIPS*(obj: pointer): bool
proc IS_TOOLTIPS_CLASS*(klass: pointer): bool
proc TOOLTIPS_GET_CLASS*(obj: pointer): PTooltipsClass
proc delay*(a: PTooltips): guint
proc set_delay*(a: PTooltips, `delay`: guint)
proc enabled*(a: PTooltips): guint
proc set_enabled*(a: PTooltips, `enabled`: guint)
proc have_grab*(a: PTooltips): guint
proc set_have_grab*(a: PTooltips, `have_grab`: guint)
proc use_sticky_delay*(a: PTooltips): guint
proc set_use_sticky_delay*(a: PTooltips, `use_sticky_delay`: guint)
proc tooltips_get_type*(): TType{.cdecl, dynlib: lib,
                                  importc: "gtk_tooltips_get_type".}
proc tooltips_new*(): PTooltips{.cdecl, dynlib: lib, importc: "gtk_tooltips_new".}
proc enable*(tooltips: PTooltips){.cdecl, dynlib: lib,
    importc: "gtk_tooltips_enable".}
proc disable*(tooltips: PTooltips){.cdecl, dynlib: lib,
    importc: "gtk_tooltips_disable".}
proc set_tip*(tooltips: PTooltips, widget: PWidget, tip_text: cstring,
                       tip_private: cstring){.cdecl, dynlib: lib,
    importc: "gtk_tooltips_set_tip".}
proc tooltips_data_get*(widget: PWidget): PTooltipsData{.cdecl, dynlib: lib,
    importc: "gtk_tooltips_data_get".}
proc force_window*(tooltips: PTooltips){.cdecl, dynlib: lib,
    importc: "gtk_tooltips_force_window".}
proc tooltips_toggle_keyboard_mode*(widget: PWidget){.cdecl, dynlib: lib,
    importc: "_gtk_tooltips_toggle_keyboard_mode".}
const
  bm_TGtkToolbar_style_set* = 0x0001'i16
  bp_TGtkToolbar_style_set* = 0'i16
  bm_TGtkToolbar_icon_size_set* = 0x0002'i16
  bp_TGtkToolbar_icon_size_set* = 1'i16

proc TYPE_TOOLBAR*(): GType
proc TOOLBAR*(obj: pointer): PToolbar
proc TOOLBAR_CLASS*(klass: pointer): PToolbarClass
proc IS_TOOLBAR*(obj: pointer): bool
proc IS_TOOLBAR_CLASS*(klass: pointer): bool
proc TOOLBAR_GET_CLASS*(obj: pointer): PToolbarClass
proc style_set*(a: PToolbar): guint
proc set_style_set*(a: PToolbar, `style_set`: guint)
proc icon_size_set*(a: PToolbar): guint
proc set_icon_size_set*(a: PToolbar, `icon_size_set`: guint)
proc toolbar_get_type*(): TType{.cdecl, dynlib: lib,
                                 importc: "gtk_toolbar_get_type".}
proc toolbar_new*(): PToolbar{.cdecl, dynlib: lib, importc: "gtk_toolbar_new".}
proc append_item*(toolbar: PToolbar, text: cstring,
                          tooltip_text: cstring, tooltip_private_text: cstring,
                          icon: PWidget, callback: TSignalFunc,
                          user_data: gpointer): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_toolbar_append_item".}
proc prepend_item*(toolbar: PToolbar, text: cstring,
                           tooltip_text: cstring, tooltip_private_text: cstring,
                           icon: PWidget, callback: TSignalFunc,
                           user_data: gpointer): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_toolbar_prepend_item".}
proc insert_item*(toolbar: PToolbar, text: cstring,
                          tooltip_text: cstring, tooltip_private_text: cstring,
                          icon: PWidget, callback: TSignalFunc,
                          user_data: gpointer, position: gint): PWidget{.cdecl,
    dynlib: lib, importc: "gtk_toolbar_insert_item".}
proc insert_stock*(toolbar: PToolbar, stock_id: cstring,
                           tooltip_text: cstring, tooltip_private_text: cstring,
                           callback: TSignalFunc, user_data: gpointer,
                           position: gint): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_toolbar_insert_stock".}
proc append_space*(toolbar: PToolbar){.cdecl, dynlib: lib,
    importc: "gtk_toolbar_append_space".}
proc prepend_space*(toolbar: PToolbar){.cdecl, dynlib: lib,
    importc: "gtk_toolbar_prepend_space".}
proc insert_space*(toolbar: PToolbar, position: gint){.cdecl,
    dynlib: lib, importc: "gtk_toolbar_insert_space".}
proc remove_space*(toolbar: PToolbar, position: gint){.cdecl,
    dynlib: lib, importc: "gtk_toolbar_remove_space".}
proc append_element*(toolbar: PToolbar, thetype: TToolbarChildType,
                             widget: PWidget, text: cstring,
                             tooltip_text: cstring,
                             tooltip_private_text: cstring, icon: PWidget,
                             callback: TSignalFunc, user_data: gpointer): PWidget{.
    cdecl, dynlib: lib, importc: "gtk_toolbar_append_element".}
proc prepend_element*(toolbar: PToolbar, thetype: TToolbarChildType,
                              widget: PWidget, text: cstring,
                              tooltip_text: cstring,
                              tooltip_private_text: cstring, icon: PWidget,
                              callback: TSignalFunc, user_data: gpointer): PWidget{.
    cdecl, dynlib: lib, importc: "gtk_toolbar_prepend_element".}
proc insert_element*(toolbar: PToolbar, thetype: TToolbarChildType,
                             widget: PWidget, text: cstring,
                             tooltip_text: cstring,
                             tooltip_private_text: cstring, icon: PWidget,
                             callback: TSignalFunc, user_data: gpointer,
                             position: gint): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_toolbar_insert_element".}
proc append_widget*(toolbar: PToolbar, widget: PWidget,
                            tooltip_text: cstring, tooltip_private_text: cstring){.
    cdecl, dynlib: lib, importc: "gtk_toolbar_append_widget".}
proc prepend_widget*(toolbar: PToolbar, widget: PWidget,
                             tooltip_text: cstring,
                             tooltip_private_text: cstring){.cdecl, dynlib: lib,
    importc: "gtk_toolbar_prepend_widget".}
proc insert_widget*(toolbar: PToolbar, widget: PWidget,
                            tooltip_text: cstring,
                            tooltip_private_text: cstring, position: gint){.
    cdecl, dynlib: lib, importc: "gtk_toolbar_insert_widget".}
proc set_orientation*(toolbar: PToolbar, orientation: TOrientation){.
    cdecl, dynlib: lib, importc: "gtk_toolbar_set_orientation".}
proc set_style*(toolbar: PToolbar, style: TToolbarStyle){.cdecl,
    dynlib: lib, importc: "gtk_toolbar_set_style".}
proc set_icon_size*(toolbar: PToolbar, icon_size: TIconSize){.cdecl,
    dynlib: lib, importc: "gtk_toolbar_set_icon_size".}
proc set_tooltips*(toolbar: PToolbar, enable: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_toolbar_set_tooltips".}
proc unset_style*(toolbar: PToolbar){.cdecl, dynlib: lib,
    importc: "gtk_toolbar_unset_style".}
proc unset_icon_size*(toolbar: PToolbar){.cdecl, dynlib: lib,
    importc: "gtk_toolbar_unset_icon_size".}
proc get_orientation*(toolbar: PToolbar): TOrientation{.cdecl,
    dynlib: lib, importc: "gtk_toolbar_get_orientation".}
proc get_style*(toolbar: PToolbar): TToolbarStyle{.cdecl, dynlib: lib,
    importc: "gtk_toolbar_get_style".}
proc get_icon_size*(toolbar: PToolbar): TIconSize{.cdecl, dynlib: lib,
    importc: "gtk_toolbar_get_icon_size".}
proc get_tooltips*(toolbar: PToolbar): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_toolbar_get_tooltips".}
const
  bm_TGtkTree_selection_mode* = 0x0003'i16
  bp_TGtkTree_selection_mode* = 0'i16
  bm_TGtkTree_view_mode* = 0x0004'i16
  bp_TGtkTree_view_mode* = 2'i16
  bm_TGtkTree_view_line* = 0x0008'i16
  bp_TGtkTree_view_line* = 3'i16

proc TYPE_TREE*(): GType
proc TREE*(obj: pointer): PTree
proc TREE_CLASS*(klass: pointer): PTreeClass
proc IS_TREE*(obj: pointer): bool
proc IS_TREE_CLASS*(klass: pointer): bool
proc TREE_GET_CLASS*(obj: pointer): PTreeClass
proc IS_ROOT_TREE*(obj: pointer): bool
proc TREE_ROOT_TREE*(obj: pointer): PTree
proc TREE_SELECTION_OLD*(obj: pointer): PGList
proc selection_mode*(a: PTree): guint
proc set_selection_mode*(a: PTree, `selection_mode`: guint)
proc view_mode*(a: PTree): guint
proc set_view_mode*(a: PTree, `view_mode`: guint)
proc view_line*(a: PTree): guint
proc set_view_line*(a: PTree, `view_line`: guint)
proc tree_get_type*(): TType{.cdecl, dynlib: lib, importc: "gtk_tree_get_type".}
proc tree_new*(): PTree{.cdecl, dynlib: lib, importc: "gtk_tree_new".}
proc append*(tree: PTree, tree_item: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_tree_append".}
proc prepend*(tree: PTree, tree_item: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_tree_prepend".}
proc insert*(tree: PTree, tree_item: PWidget, position: gint){.cdecl,
    dynlib: lib, importc: "gtk_tree_insert".}
proc remove_items*(tree: PTree, items: PGList){.cdecl, dynlib: lib,
    importc: "gtk_tree_remove_items".}
proc clear_items*(tree: PTree, start: gint, theEnd: gint){.cdecl,
    dynlib: lib, importc: "gtk_tree_clear_items".}
proc select_item*(tree: PTree, item: gint){.cdecl, dynlib: lib,
    importc: "gtk_tree_select_item".}
proc unselect_item*(tree: PTree, item: gint){.cdecl, dynlib: lib,
    importc: "gtk_tree_unselect_item".}
proc select_child*(tree: PTree, tree_item: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_tree_select_child".}
proc unselect_child*(tree: PTree, tree_item: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_tree_unselect_child".}
proc child_position*(tree: PTree, child: PWidget): gint{.cdecl,
    dynlib: lib, importc: "gtk_tree_child_position".}
proc set_selection_mode*(tree: PTree, mode: TSelectionMode){.cdecl,
    dynlib: lib, importc: "gtk_tree_set_selection_mode".}
proc set_view_mode*(tree: PTree, mode: TTreeViewMode){.cdecl, dynlib: lib,
    importc: "gtk_tree_set_view_mode".}
proc set_view_lines*(tree: PTree, flag: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_tree_set_view_lines".}
proc remove_item*(tree: PTree, child: PWidget){.cdecl, dynlib: lib,
    importc: "gtk_tree_remove_item".}
proc TYPE_TREE_DRAG_SOURCE*(): GType
proc TREE_DRAG_SOURCE*(obj: pointer): PTreeDragSource
proc IS_TREE_DRAG_SOURCE*(obj: pointer): bool
proc TREE_DRAG_SOURCE_GET_IFACE*(obj: pointer): PTreeDragSourceIface
proc tree_drag_source_get_type*(): GType{.cdecl, dynlib: lib,
    importc: "gtk_tree_drag_source_get_type".}
proc source_row_draggable*(drag_source: PTreeDragSource,
                                     path: PTreePath): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_tree_drag_source_row_draggable".}
proc source_drag_data_delete*(drag_source: PTreeDragSource,
                                        path: PTreePath): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_tree_drag_source_drag_data_delete".}
proc source_drag_data_get*(drag_source: PTreeDragSource,
                                     path: PTreePath,
                                     selection_data: PSelectionData): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_drag_source_drag_data_get".}
proc TYPE_TREE_DRAG_DEST*(): GType
proc TREE_DRAG_DEST*(obj: pointer): PTreeDragDest
proc IS_TREE_DRAG_DEST*(obj: pointer): bool
proc TREE_DRAG_DEST_GET_IFACE*(obj: pointer): PTreeDragDestIface
proc tree_drag_dest_get_type*(): GType{.cdecl, dynlib: lib,
                                        importc: "gtk_tree_drag_dest_get_type".}
proc dest_drag_data_received*(drag_dest: PTreeDragDest,
                                        dest: PTreePath,
                                        selection_data: PSelectionData): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_drag_dest_drag_data_received".}
proc dest_row_drop_possible*(drag_dest: PTreeDragDest,
                                       dest_path: PTreePath,
                                       selection_data: PSelectionData): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_drag_dest_row_drop_possible".}
proc tree_set_row_drag_data*(selection_data: PSelectionData,
                             tree_model: PTreeModel, path: PTreePath): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_set_row_drag_data".}
const
  bm_TGtkTreeItem_expanded* = 0x0001'i16
  bp_TGtkTreeItem_expanded* = 0'i16

proc TYPE_TREE_ITEM*(): GType
proc TREE_ITEM*(obj: pointer): PTreeItem
proc TREE_ITEM_CLASS*(klass: pointer): PTreeItemClass
proc IS_TREE_ITEM*(obj: pointer): bool
proc IS_TREE_ITEM_CLASS*(klass: pointer): bool
proc TREE_ITEM_GET_CLASS*(obj: pointer): PTreeItemClass
proc TREE_ITEM_SUBTREE*(obj: pointer): PWidget
proc expanded*(a: PTreeItem): guint
proc set_expanded*(a: PTreeItem, `expanded`: guint)
proc tree_item_get_type*(): TType{.cdecl, dynlib: lib,
                                   importc: "gtk_tree_item_get_type".}
proc tree_item_new*(): PTreeItem{.cdecl, dynlib: lib,
                                  importc: "gtk_tree_item_new".}
proc tree_item_new*(`label`: cstring): PTreeItem{.cdecl, dynlib: lib,
    importc: "gtk_tree_item_new_with_label".}
proc set_subtree*(tree_item: PTreeItem, subtree: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_tree_item_set_subtree".}
proc remove_subtree*(tree_item: PTreeItem){.cdecl, dynlib: lib,
    importc: "gtk_tree_item_remove_subtree".}
proc select*(tree_item: PTreeItem){.cdecl, dynlib: lib,
    importc: "gtk_tree_item_select".}
proc deselect*(tree_item: PTreeItem){.cdecl, dynlib: lib,
    importc: "gtk_tree_item_deselect".}
proc expand*(tree_item: PTreeItem){.cdecl, dynlib: lib,
    importc: "gtk_tree_item_expand".}
proc collapse*(tree_item: PTreeItem){.cdecl, dynlib: lib,
    importc: "gtk_tree_item_collapse".}
proc TYPE_TREE_SELECTION*(): GType
proc TREE_SELECTION*(obj: pointer): PTreeSelection
proc TREE_SELECTION_CLASS*(klass: pointer): PTreeSelectionClass
proc IS_TREE_SELECTION*(obj: pointer): bool
proc IS_TREE_SELECTION_CLASS*(klass: pointer): bool
proc TREE_SELECTION_GET_CLASS*(obj: pointer): PTreeSelectionClass
proc tree_selection_get_type*(): TType{.cdecl, dynlib: lib,
                                        importc: "gtk_tree_selection_get_type".}
proc set_mode*(selection: PTreeSelection, thetype: TSelectionMode){.
    cdecl, dynlib: lib, importc: "gtk_tree_selection_set_mode".}
proc get_mode*(selection: PTreeSelection): TSelectionMode{.cdecl,
    dynlib: lib, importc: "gtk_tree_selection_get_mode".}
proc set_select_function*(selection: PTreeSelection,
    fun: TTreeSelectionFunc, data: gpointer, destroy: TDestroyNotify){.cdecl,
    dynlib: lib, importc: "gtk_tree_selection_set_select_function".}
proc get_user_data*(selection: PTreeSelection): gpointer{.cdecl,
    dynlib: lib, importc: "gtk_tree_selection_get_user_data".}
proc get_tree_view*(selection: PTreeSelection): PTreeView{.cdecl,
    dynlib: lib, importc: "gtk_tree_selection_get_tree_view".}
proc get_selected*(selection: PTreeSelection,
                                  model: PPGtkTreeModel, iter: PTreeIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_selection_get_selected".}
proc get_selected_rows*(selection: PTreeSelection,
                                       model: PPGtkTreeModel): PGList{.cdecl,
    dynlib: lib, importc: "gtk_tree_selection_get_selected_rows".}
proc selected_foreach*(selection: PTreeSelection,
                                      fun: TTreeSelectionForeachFunc,
                                      data: gpointer){.cdecl, dynlib: lib,
    importc: "gtk_tree_selection_selected_foreach".}
proc select_path*(selection: PTreeSelection, path: PTreePath){.
    cdecl, dynlib: lib, importc: "gtk_tree_selection_select_path".}
proc unselect_path*(selection: PTreeSelection, path: PTreePath){.
    cdecl, dynlib: lib, importc: "gtk_tree_selection_unselect_path".}
proc select_iter*(selection: PTreeSelection, iter: PTreeIter){.
    cdecl, dynlib: lib, importc: "gtk_tree_selection_select_iter".}
proc unselect_iter*(selection: PTreeSelection, iter: PTreeIter){.
    cdecl, dynlib: lib, importc: "gtk_tree_selection_unselect_iter".}
proc path_is_selected*(selection: PTreeSelection, path: PTreePath): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_selection_path_is_selected".}
proc iter_is_selected*(selection: PTreeSelection, iter: PTreeIter): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_selection_iter_is_selected".}
proc select_all*(selection: PTreeSelection){.cdecl, dynlib: lib,
    importc: "gtk_tree_selection_select_all".}
proc unselect_all*(selection: PTreeSelection){.cdecl,
    dynlib: lib, importc: "gtk_tree_selection_unselect_all".}
proc select_range*(selection: PTreeSelection,
                                  start_path: PTreePath, end_path: PTreePath){.
    cdecl, dynlib: lib, importc: "gtk_tree_selection_select_range".}
const
  bm_TGtkTreeStore_columns_dirty* = 0x0001'i16
  bp_TGtkTreeStore_columns_dirty* = 0'i16

proc TYPE_TREE_STORE*(): GType
proc TREE_STORE*(obj: pointer): PTreeStore
proc TREE_STORE_CLASS*(klass: pointer): PTreeStoreClass
proc IS_TREE_STORE*(obj: pointer): bool
proc IS_TREE_STORE_CLASS*(klass: pointer): bool
proc TREE_STORE_GET_CLASS*(obj: pointer): PTreeStoreClass
proc columns_dirty*(a: PTreeStore): guint
proc set_columns_dirty*(a: PTreeStore, `columns_dirty`: guint)
proc tree_store_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_tree_store_get_type".}
proc tree_store_newv*(n_columns: gint, types: PGType): PTreeStore{.cdecl,
    dynlib: lib, importc: "gtk_tree_store_newv".}
proc set_column_types*(tree_store: PTreeStore, n_columns: gint,
                                  types: PGType){.cdecl, dynlib: lib,
    importc: "gtk_tree_store_set_column_types".}
proc set_value*(tree_store: PTreeStore, iter: PTreeIter,
                           column: gint, value: PGValue){.cdecl, dynlib: lib,
    importc: "gtk_tree_store_set_value".}
proc remove*(tree_store: PTreeStore, iter: PTreeIter){.cdecl,
    dynlib: lib, importc: "gtk_tree_store_remove".}
proc insert*(tree_store: PTreeStore, iter: PTreeIter,
                        parent: PTreeIter, position: gint){.cdecl, dynlib: lib,
    importc: "gtk_tree_store_insert".}
proc insert_before*(tree_store: PTreeStore, iter: PTreeIter,
                               parent: PTreeIter, sibling: PTreeIter){.cdecl,
    dynlib: lib, importc: "gtk_tree_store_insert_before".}
proc insert_after*(tree_store: PTreeStore, iter: PTreeIter,
                              parent: PTreeIter, sibling: PTreeIter){.cdecl,
    dynlib: lib, importc: "gtk_tree_store_insert_after".}
proc prepend*(tree_store: PTreeStore, iter: PTreeIter,
                         parent: PTreeIter){.cdecl, dynlib: lib,
    importc: "gtk_tree_store_prepend".}
proc append*(tree_store: PTreeStore, iter: PTreeIter,
                        parent: PTreeIter){.cdecl, dynlib: lib,
    importc: "gtk_tree_store_append".}
proc is_ancestor*(tree_store: PTreeStore, iter: PTreeIter,
                             descendant: PTreeIter): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_tree_store_is_ancestor".}
proc iter_depth*(tree_store: PTreeStore, iter: PTreeIter): gint{.
    cdecl, dynlib: lib, importc: "gtk_tree_store_iter_depth".}
proc clear*(tree_store: PTreeStore){.cdecl, dynlib: lib,
    importc: "gtk_tree_store_clear".}
const
  bm_TGtkTreeViewColumn_visible* = 0x0001'i16
  bp_TGtkTreeViewColumn_visible* = 0'i16
  bm_TGtkTreeViewColumn_resizable* = 0x0002'i16
  bp_TGtkTreeViewColumn_resizable* = 1'i16
  bm_TGtkTreeViewColumn_clickable* = 0x0004'i16
  bp_TGtkTreeViewColumn_clickable* = 2'i16
  bm_TGtkTreeViewColumn_dirty* = 0x0008'i16
  bp_TGtkTreeViewColumn_dirty* = 3'i16
  bm_TGtkTreeViewColumn_show_sort_indicator* = 0x0010'i16
  bp_TGtkTreeViewColumn_show_sort_indicator* = 4'i16
  bm_TGtkTreeViewColumn_maybe_reordered* = 0x0020'i16
  bp_TGtkTreeViewColumn_maybe_reordered* = 5'i16
  bm_TGtkTreeViewColumn_reorderable* = 0x0040'i16
  bp_TGtkTreeViewColumn_reorderable* = 6'i16
  bm_TGtkTreeViewColumn_use_resized_width* = 0x0080'i16
  bp_TGtkTreeViewColumn_use_resized_width* = 7'i16

proc TYPE_TREE_VIEW_COLUMN*(): GType
proc TREE_VIEW_COLUMN*(obj: pointer): PTreeViewColumn
proc TREE_VIEW_COLUMN_CLASS*(klass: pointer): PTreeViewColumnClass
proc IS_TREE_VIEW_COLUMN*(obj: pointer): bool
proc IS_TREE_VIEW_COLUMN_CLASS*(klass: pointer): bool
proc TREE_VIEW_COLUMN_GET_CLASS*(obj: pointer): PTreeViewColumnClass
proc visible*(a: PTreeViewColumn): guint
proc set_visible*(a: PTreeViewColumn, `visible`: guint)
proc resizable*(a: PTreeViewColumn): guint
proc set_resizable*(a: PTreeViewColumn, `resizable`: guint)
proc clickable*(a: PTreeViewColumn): guint
proc set_clickable*(a: PTreeViewColumn, `clickable`: guint)
proc dirty*(a: PTreeViewColumn): guint
proc set_dirty*(a: PTreeViewColumn, `dirty`: guint)
proc show_sort_indicator*(a: PTreeViewColumn): guint
proc set_show_sort_indicator*(a: PTreeViewColumn,
                              `show_sort_indicator`: guint)
proc maybe_reordered*(a: PTreeViewColumn): guint
proc set_maybe_reordered*(a: PTreeViewColumn, `maybe_reordered`: guint)
proc reorderable*(a: PTreeViewColumn): guint
proc set_reorderable*(a: PTreeViewColumn, `reorderable`: guint)
proc use_resized_width*(a: PTreeViewColumn): guint
proc set_use_resized_width*(a: PTreeViewColumn, `use_resized_width`: guint)
proc tree_view_column_get_type*(): TType{.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_get_type".}
proc tree_view_column_new*(): PTreeViewColumn{.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_new".}
proc column_pack_start*(tree_column: PTreeViewColumn,
                                  cell: PCellRenderer, expand: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_pack_start".}
proc column_pack_end*(tree_column: PTreeViewColumn,
                                cell: PCellRenderer, expand: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_pack_end".}
proc column_clear*(tree_column: PTreeViewColumn){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_clear".}
proc column_get_cell_renderers*(tree_column: PTreeViewColumn): PGList{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_get_cell_renderers".}
proc column_add_attribute*(tree_column: PTreeViewColumn,
                                     cell_renderer: PCellRenderer,
                                     attribute: cstring, column: gint){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_add_attribute".}
proc column_set_cell_data_func*(tree_column: PTreeViewColumn,
    cell_renderer: PCellRenderer, fun: TTreeCellDataFunc, func_data: gpointer,
    destroy: TDestroyNotify){.cdecl, dynlib: lib, importc: "gtk_tree_view_column_set_cell_data_func".}
proc column_clear_attributes*(tree_column: PTreeViewColumn,
                                        cell_renderer: PCellRenderer){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_clear_attributes".}
proc column_set_spacing*(tree_column: PTreeViewColumn, spacing: gint){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_set_spacing".}
proc column_get_spacing*(tree_column: PTreeViewColumn): gint{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_get_spacing".}
proc column_set_visible*(tree_column: PTreeViewColumn,
                                   visible: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_set_visible".}
proc column_get_visible*(tree_column: PTreeViewColumn): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_get_visible".}
proc column_set_resizable*(tree_column: PTreeViewColumn,
                                     resizable: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_set_resizable".}
proc column_get_resizable*(tree_column: PTreeViewColumn): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_get_resizable".}
proc column_set_sizing*(tree_column: PTreeViewColumn,
                                  thetype: TTreeViewColumnSizing){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_set_sizing".}
proc column_get_sizing*(tree_column: PTreeViewColumn): TTreeViewColumnSizing{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_get_sizing".}
proc column_get_width*(tree_column: PTreeViewColumn): gint{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_get_width".}
proc column_get_fixed_width*(tree_column: PTreeViewColumn): gint{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_get_fixed_width".}
proc column_set_fixed_width*(tree_column: PTreeViewColumn,
                                       fixed_width: gint){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_set_fixed_width".}
proc column_set_min_width*(tree_column: PTreeViewColumn,
                                     min_width: gint){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_set_min_width".}
proc column_get_min_width*(tree_column: PTreeViewColumn): gint{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_get_min_width".}
proc column_set_max_width*(tree_column: PTreeViewColumn,
                                     max_width: gint){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_set_max_width".}
proc column_get_max_width*(tree_column: PTreeViewColumn): gint{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_get_max_width".}
proc column_clicked*(tree_column: PTreeViewColumn){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_clicked".}
proc column_set_title*(tree_column: PTreeViewColumn, title: cstring){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_set_title".}
proc column_get_title*(tree_column: PTreeViewColumn): cstring{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_get_title".}
proc column_set_clickable*(tree_column: PTreeViewColumn,
                                     clickable: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_set_clickable".}
proc column_get_clickable*(tree_column: PTreeViewColumn): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_get_clickable".}
proc column_set_widget*(tree_column: PTreeViewColumn, widget: PWidget){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_set_widget".}
proc column_get_widget*(tree_column: PTreeViewColumn): PWidget{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_get_widget".}
proc column_set_alignment*(tree_column: PTreeViewColumn,
                                     xalign: gfloat){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_set_alignment".}
proc column_get_alignment*(tree_column: PTreeViewColumn): gfloat{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_get_alignment".}
proc column_set_reorderable*(tree_column: PTreeViewColumn,
                                       reorderable: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_column_set_reorderable".}
proc column_get_reorderable*(tree_column: PTreeViewColumn): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_get_reorderable".}
proc column_set_sort_column_id*(tree_column: PTreeViewColumn,
    sort_column_id: gint){.cdecl, dynlib: lib,
                           importc: "gtk_tree_view_column_set_sort_column_id".}
proc column_get_sort_column_id*(tree_column: PTreeViewColumn): gint{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_get_sort_column_id".}
proc column_set_sort_indicator*(tree_column: PTreeViewColumn,
    setting: gboolean){.cdecl, dynlib: lib,
                        importc: "gtk_tree_view_column_set_sort_indicator".}
proc column_get_sort_indicator*(tree_column: PTreeViewColumn): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_get_sort_indicator".}
proc column_set_sort_order*(tree_column: PTreeViewColumn,
                                      order: TSortType){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_set_sort_order".}
proc column_get_sort_order*(tree_column: PTreeViewColumn): TSortType{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_get_sort_order".}
proc column_cell_set_cell_data*(tree_column: PTreeViewColumn,
    tree_model: PTreeModel, iter: PTreeIter, is_expander: gboolean,
    is_expanded: gboolean){.cdecl, dynlib: lib,
                            importc: "gtk_tree_view_column_cell_set_cell_data".}
proc column_cell_get_size*(tree_column: PTreeViewColumn,
                                     cell_area: gdk2.PRectangle, x_offset: Pgint,
                                     y_offset: Pgint, width: Pgint,
                                     height: Pgint){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_cell_get_size".}
proc column_cell_is_visible*(tree_column: PTreeViewColumn): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_cell_is_visible".}
proc column_focus_cell*(tree_column: PTreeViewColumn,
                                  cell: PCellRenderer){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_column_focus_cell".}
proc column_set_expand*(tree_column: PTreeViewColumn, Expand: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_set_expand".}
proc column_get_expand*(tree_column: PTreeViewColumn): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_column_get_expand".}
const
  RBNODE_BLACK* = 1 shl 0
  RBNODE_RED* = 1 shl 1
  RBNODE_IS_PARENT* = 1 shl 2
  RBNODE_IS_SELECTED* = 1 shl 3
  RBNODE_IS_PRELIT* = 1 shl 4
  RBNODE_IS_SEMI_COLLAPSED* = 1 shl 5
  RBNODE_IS_SEMI_EXPANDED* = 1 shl 6
  RBNODE_INVALID* = 1 shl 7
  RBNODE_COLUMN_INVALID* = 1 shl 8
  RBNODE_DESCENDANTS_INVALID* = 1 shl 9
  RBNODE_NON_COLORS* = RBNODE_IS_PARENT or RBNODE_IS_SELECTED or
      RBNODE_IS_PRELIT or RBNODE_IS_SEMI_COLLAPSED or RBNODE_IS_SEMI_EXPANDED or
      RBNODE_INVALID or RBNODE_COLUMN_INVALID or RBNODE_DESCENDANTS_INVALID

const
  bm_TGtkRBNode_flags* = 0x3FFF'i16
  bp_TGtkRBNode_flags* = 0'i16
  bm_TGtkRBNode_parity* = 0x4000'i16
  bp_TGtkRBNode_parity* = 14'i16

proc flags*(a: PRBNode): guint
proc set_flags*(a: PRBNode, `flags`: guint)
proc parity*(a: PRBNode): guint
proc set_parity*(a: PRBNode, `parity`: guint)
proc GET_COLOR*(node: PRBNode): guint
proc SET_COLOR*(node: PRBNode, color: guint)
proc GET_HEIGHT*(node: PRBNode): gint
proc SET_FLAG*(node: PRBNode, flag: guint16)
proc UNSET_FLAG*(node: PRBNode, flag: guint16)
proc FLAG_SET*(node: PRBNode, flag: guint): bool
proc rbtree_push_allocator*(allocator: PGAllocator){.cdecl, dynlib: lib,
    importc: "_gtk_rbtree_push_allocator".}
proc rbtree_pop_allocator*(){.cdecl, dynlib: lib,
                              importc: "_gtk_rbtree_pop_allocator".}
proc rbtree_new*(): PRBTree{.cdecl, dynlib: lib, importc: "_gtk_rbtree_new".}
proc free*(tree: PRBTree){.cdecl, dynlib: lib,
                                  importc: "_gtk_rbtree_free".}
proc remove*(tree: PRBTree){.cdecl, dynlib: lib,
                                    importc: "_gtk_rbtree_remove".}
proc destroy*(tree: PRBTree){.cdecl, dynlib: lib,
                                     importc: "_gtk_rbtree_destroy".}
proc insert_before*(tree: PRBTree, node: PRBNode, height: gint,
                           valid: gboolean): PRBNode{.cdecl, dynlib: lib,
    importc: "_gtk_rbtree_insert_before".}
proc insert_after*(tree: PRBTree, node: PRBNode, height: gint,
                          valid: gboolean): PRBNode{.cdecl, dynlib: lib,
    importc: "_gtk_rbtree_insert_after".}
proc remove_node*(tree: PRBTree, node: PRBNode){.cdecl, dynlib: lib,
    importc: "_gtk_rbtree_remove_node".}
proc reorder*(tree: PRBTree, new_order: Pgint, length: gint){.cdecl,
    dynlib: lib, importc: "_gtk_rbtree_reorder".}
proc find_count*(tree: PRBTree, count: gint): PRBNode{.cdecl,
    dynlib: lib, importc: "_gtk_rbtree_find_count".}
proc node_set_height*(tree: PRBTree, node: PRBNode, height: gint){.
    cdecl, dynlib: lib, importc: "_gtk_rbtree_node_set_height".}
proc node_mark_invalid*(tree: PRBTree, node: PRBNode){.cdecl,
    dynlib: lib, importc: "_gtk_rbtree_node_mark_invalid".}
proc node_mark_valid*(tree: PRBTree, node: PRBNode){.cdecl, dynlib: lib,
    importc: "_gtk_rbtree_node_mark_valid".}
proc column_invalid*(tree: PRBTree){.cdecl, dynlib: lib,
    importc: "_gtk_rbtree_column_invalid".}
proc mark_invalid*(tree: PRBTree){.cdecl, dynlib: lib,
    importc: "_gtk_rbtree_mark_invalid".}
proc set_fixed_height*(tree: PRBTree, height: gint){.cdecl, dynlib: lib,
    importc: "_gtk_rbtree_set_fixed_height".}
proc node_find_offset*(tree: PRBTree, node: PRBNode): gint{.cdecl,
    dynlib: lib, importc: "_gtk_rbtree_node_find_offset".}
proc node_find_parity*(tree: PRBTree, node: PRBNode): gint{.cdecl,
    dynlib: lib, importc: "_gtk_rbtree_node_find_parity".}
proc traverse*(tree: PRBTree, node: PRBNode, order: TGTraverseType,
                      fun: TRBTreeTraverseFunc, data: gpointer){.cdecl,
    dynlib: lib, importc: "_gtk_rbtree_traverse".}
proc next*(tree: PRBTree, node: PRBNode): PRBNode{.cdecl, dynlib: lib,
    importc: "_gtk_rbtree_next".}
proc prev*(tree: PRBTree, node: PRBNode): PRBNode{.cdecl, dynlib: lib,
    importc: "_gtk_rbtree_prev".}
proc get_depth*(tree: PRBTree): gint{.cdecl, dynlib: lib,
    importc: "_gtk_rbtree_get_depth".}
const
  TREE_VIEW_DRAG_WIDTH* = 6
  TREE_VIEW_IS_LIST* = 1 shl 0
  TREE_VIEW_SHOW_EXPANDERS* = 1 shl 1
  TREE_VIEW_IN_COLUMN_RESIZE* = 1 shl 2
  TREE_VIEW_ARROW_PRELIT* = 1 shl 3
  TREE_VIEW_HEADERS_VISIBLE* = 1 shl 4
  TREE_VIEW_DRAW_KEYFOCUS* = 1 shl 5
  TREE_VIEW_MODEL_SETUP* = 1 shl 6
  TREE_VIEW_IN_COLUMN_DRAG* = 1 shl 7
  DRAG_COLUMN_WINDOW_STATE_UNSET* = 0
  DRAG_COLUMN_WINDOW_STATE_ORIGINAL* = 1
  DRAG_COLUMN_WINDOW_STATE_ARROW* = 2
  DRAG_COLUMN_WINDOW_STATE_ARROW_LEFT* = 3
  DRAG_COLUMN_WINDOW_STATE_ARROW_RIGHT* = 4

proc SET_FLAG*(tree_view: PTreeView, flag: guint)
proc UNSET_FLAG*(tree_view: PTreeView, flag: guint)
proc FLAG_SET*(tree_view: PTreeView, flag: guint): bool
proc HEADER_HEIGHT*(tree_view: PTreeView): int32
proc COLUMN_REQUESTED_WIDTH*(column: PTreeViewColumn): int32
proc DRAW_EXPANDERS*(tree_view: PTreeView): bool
proc COLUMN_DRAG_DEAD_MULTIPLIER*(tree_view: PTreeView): int32
const
  bm_TGtkTreeViewPrivate_scroll_to_use_align* = 0x0001'i16
  bp_TGtkTreeViewPrivate_scroll_to_use_align* = 0'i16
  bm_TGtkTreeViewPrivate_fixed_height_check* = 0x0002'i16
  bp_TGtkTreeViewPrivate_fixed_height_check* = 1'i16
  bm_TGtkTreeViewPrivate_reorderable* = 0x0004'i16
  bp_TGtkTreeViewPrivate_reorderable* = 2'i16
  bm_TGtkTreeViewPrivate_header_has_focus* = 0x0008'i16
  bp_TGtkTreeViewPrivate_header_has_focus* = 3'i16
  bm_TGtkTreeViewPrivate_drag_column_window_state* = 0x0070'i16
  bp_TGtkTreeViewPrivate_drag_column_window_state* = 4'i16
  bm_TGtkTreeViewPrivate_has_rules* = 0x0080'i16
  bp_TGtkTreeViewPrivate_has_rules* = 7'i16
  bm_TGtkTreeViewPrivate_mark_rows_col_dirty* = 0x0100'i16
  bp_TGtkTreeViewPrivate_mark_rows_col_dirty* = 8'i16
  bm_TGtkTreeViewPrivate_enable_search* = 0x0200'i16
  bp_TGtkTreeViewPrivate_enable_search* = 9'i16
  bm_TGtkTreeViewPrivate_disable_popdown* = 0x0400'i16
  bp_TGtkTreeViewPrivate_disable_popdown* = 10'i16

proc scroll_to_use_align*(a: PTreeViewPrivate): guint
proc set_scroll_to_use_align*(a: PTreeViewPrivate,
                              `scroll_to_use_align`: guint)
proc fixed_height_check*(a: PTreeViewPrivate): guint
proc set_fixed_height_check*(a: PTreeViewPrivate,
                             `fixed_height_check`: guint)
proc reorderable*(a: PTreeViewPrivate): guint
proc set_reorderable*(a: PTreeViewPrivate, `reorderable`: guint)
proc header_has_focus*(a: PTreeViewPrivate): guint
proc set_header_has_focus*(a: PTreeViewPrivate, `header_has_focus`: guint)
proc drag_column_window_state*(a: PTreeViewPrivate): guint
proc set_drag_column_window_state*(a: PTreeViewPrivate,
                                   `drag_column_window_state`: guint)
proc has_rules*(a: PTreeViewPrivate): guint
proc set_has_rules*(a: PTreeViewPrivate, `has_rules`: guint)
proc mark_rows_col_dirty*(a: PTreeViewPrivate): guint
proc set_mark_rows_col_dirty*(a: PTreeViewPrivate,
                              `mark_rows_col_dirty`: guint)
proc enable_search*(a: PTreeViewPrivate): guint
proc set_enable_search*(a: PTreeViewPrivate, `enable_search`: guint)
proc disable_popdown*(a: PTreeViewPrivate): guint
proc set_disable_popdown*(a: PTreeViewPrivate, `disable_popdown`: guint)
proc internal_select_node*(selection: PTreeSelection,
    node: PRBNode, tree: PRBTree, path: PTreePath, state: gdk2.TModifierType,
    override_browse_mode: gboolean){.cdecl, dynlib: lib, importc: "_gtk_tree_selection_internal_select_node".}
proc find_node*(tree_view: PTreeView, path: PTreePath,
                          tree: var PRBTree, node: var PRBNode): gboolean{.
    cdecl, dynlib: lib, importc: "_gtk_tree_view_find_node".}
proc find_path*(tree_view: PTreeView, tree: PRBTree, node: PRBNode): PTreePath{.
    cdecl, dynlib: lib, importc: "_gtk_tree_view_find_path".}
proc child_move_resize*(tree_view: PTreeView, widget: PWidget,
                                  x: gint, y: gint, width: gint, height: gint){.
    cdecl, dynlib: lib, importc: "_gtk_tree_view_child_move_resize".}
proc queue_draw_node*(tree_view: PTreeView, tree: PRBTree,
                                node: PRBNode, clip_rect: gdk2.PRectangle){.
    cdecl, dynlib: lib, importc: "_gtk_tree_view_queue_draw_node".}
proc column_realize_button*(column: PTreeViewColumn){.cdecl,
    dynlib: lib, importc: "_gtk_tree_view_column_realize_button".}
proc column_unrealize_button*(column: PTreeViewColumn){.cdecl,
    dynlib: lib, importc: "_gtk_tree_view_column_unrealize_button".}
proc column_set_tree_view*(column: PTreeViewColumn,
                                     tree_view: PTreeView){.cdecl, dynlib: lib,
    importc: "_gtk_tree_view_column_set_tree_view".}
proc column_unset_tree_view*(column: PTreeViewColumn){.cdecl,
    dynlib: lib, importc: "_gtk_tree_view_column_unset_tree_view".}
proc column_set_width*(column: PTreeViewColumn, width: gint){.cdecl,
    dynlib: lib, importc: "_gtk_tree_view_column_set_width".}
proc column_start_drag*(tree_view: PTreeView, column: PTreeViewColumn){.
    cdecl, dynlib: lib, importc: "_gtk_tree_view_column_start_drag".}
proc column_start_editing*(tree_column: PTreeViewColumn,
                                     editable_widget: PCellEditable){.cdecl,
    dynlib: lib, importc: "_gtk_tree_view_column_start_editing".}
proc column_stop_editing*(tree_column: PTreeViewColumn){.cdecl,
    dynlib: lib, importc: "_gtk_tree_view_column_stop_editing".}
proc install_mark_rows_col_dirty*(tree_view: PTreeView){.cdecl,
    dynlib: lib, importc: "_gtk_tree_view_install_mark_rows_col_dirty".}
proc DOgtk_tree_view_column_autosize*(tree_view: PTreeView,
                                      column: PTreeViewColumn){.cdecl,
    dynlib: lib, importc: "_gtk_tree_view_column_autosize".}
proc column_has_editable_cell*(column: PTreeViewColumn): gboolean{.
    cdecl, dynlib: lib, importc: "_gtk_tree_view_column_has_editable_cell".}
proc column_get_edited_cell*(column: PTreeViewColumn): PCellRenderer{.
    cdecl, dynlib: lib, importc: "_gtk_tree_view_column_get_edited_cell".}
proc column_count_special_cells*(column: PTreeViewColumn): gint{.
    cdecl, dynlib: lib, importc: "_gtk_tree_view_column_count_special_cells".}
proc column_get_cell_at_pos*(column: PTreeViewColumn, x: gint): PCellRenderer{.
    cdecl, dynlib: lib, importc: "_gtk_tree_view_column_get_cell_at_pos".}
proc tree_selection_new*(): PTreeSelection{.cdecl, dynlib: lib,
    importc: "_gtk_tree_selection_new".}
proc selection_new*(tree_view: PTreeView): PTreeSelection{.
    cdecl, dynlib: lib, importc: "_gtk_tree_selection_new_with_tree_view".}
proc set_tree_view*(selection: PTreeSelection,
                                   tree_view: PTreeView){.cdecl, dynlib: lib,
    importc: "_gtk_tree_selection_set_tree_view".}
proc column_cell_render*(tree_column: PTreeViewColumn,
                                   window: gdk2.PWindow,
                                   background_area: gdk2.PRectangle,
                                   cell_area: gdk2.PRectangle,
                                   expose_area: gdk2.PRectangle, flags: guint){.
    cdecl, dynlib: lib, importc: "_gtk_tree_view_column_cell_render".}
proc column_cell_focus*(tree_column: PTreeViewColumn, direction: gint,
                                  left: gboolean, right: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "_gtk_tree_view_column_cell_focus".}
proc column_cell_draw_focus*(tree_column: PTreeViewColumn,
                                       window: gdk2.PWindow,
                                       background_area: gdk2.PRectangle,
                                       cell_area: gdk2.PRectangle,
                                       expose_area: gdk2.PRectangle, flags: guint){.
    cdecl, dynlib: lib, importc: "_gtk_tree_view_column_cell_draw_focus".}
proc column_cell_set_dirty*(tree_column: PTreeViewColumn,
                                      install_handler: gboolean){.cdecl,
    dynlib: lib, importc: "_gtk_tree_view_column_cell_set_dirty".}
proc column_get_neighbor_sizes*(column: PTreeViewColumn,
    cell: PCellRenderer, left: Pgint, right: Pgint){.cdecl, dynlib: lib,
    importc: "_gtk_tree_view_column_get_neighbor_sizes".}
proc TYPE_TREE_VIEW*(): GType
proc TREE_VIEW*(obj: pointer): PTreeView
proc TREE_VIEW_CLASS*(klass: pointer): PTreeViewClass
proc IS_TREE_VIEW*(obj: pointer): bool
proc IS_TREE_VIEW_CLASS*(klass: pointer): bool
proc TREE_VIEW_GET_CLASS*(obj: pointer): PTreeViewClass
proc tree_view_get_type*(): TType{.cdecl, dynlib: lib,
                                   importc: "gtk_tree_view_get_type".}
proc tree_view_new*(): PTreeView{.cdecl, dynlib: lib,
                                  importc: "gtk_tree_view_new".}
proc tree_view_new*(model: PTreeModel): PTreeView{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_new_with_model".}
proc get_model*(tree_view: PTreeView): PTreeModel{.cdecl, dynlib: lib,
    importc: "gtk_tree_view_get_model".}
proc set_model*(tree_view: PTreeView, model: PTreeModel){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_set_model".}
proc get_selection*(tree_view: PTreeView): PTreeSelection{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_get_selection".}
proc get_hadjustment*(tree_view: PTreeView): PAdjustment{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_get_hadjustment".}
proc set_hadjustment*(tree_view: PTreeView, adjustment: PAdjustment){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_set_hadjustment".}
proc get_vadjustment*(tree_view: PTreeView): PAdjustment{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_get_vadjustment".}
proc set_vadjustment*(tree_view: PTreeView, adjustment: PAdjustment){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_set_vadjustment".}
proc get_headers_visible*(tree_view: PTreeView): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_get_headers_visible".}
proc set_headers_visible*(tree_view: PTreeView,
                                    headers_visible: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_set_headers_visible".}
proc columns_autosize*(tree_view: PTreeView){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_columns_autosize".}
proc set_headers_clickable*(tree_view: PTreeView, setting: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_set_headers_clickable".}
proc set_rules_hint*(tree_view: PTreeView, setting: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_set_rules_hint".}
proc get_rules_hint*(tree_view: PTreeView): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_get_rules_hint".}
proc append_column*(tree_view: PTreeView, column: PTreeViewColumn): gint{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_append_column".}
proc remove_column*(tree_view: PTreeView, column: PTreeViewColumn): gint{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_remove_column".}
proc insert_column*(tree_view: PTreeView, column: PTreeViewColumn,
                              position: gint): gint{.cdecl, dynlib: lib,
    importc: "gtk_tree_view_insert_column".}
proc insert_column_with_data_func*(tree_view: PTreeView,
    position: gint, title: cstring, cell: PCellRenderer,
    fun: TTreeCellDataFunc, data: gpointer, dnotify: TGDestroyNotify): gint{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_insert_column_with_data_func".}
proc get_column*(tree_view: PTreeView, n: gint): PTreeViewColumn{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_get_column".}
proc get_columns*(tree_view: PTreeView): PGList{.cdecl, dynlib: lib,
    importc: "gtk_tree_view_get_columns".}
proc move_column_after*(tree_view: PTreeView, column: PTreeViewColumn,
                                  base_column: PTreeViewColumn){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_move_column_after".}
proc set_expander_column*(tree_view: PTreeView,
                                    column: PTreeViewColumn){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_set_expander_column".}
proc get_expander_column*(tree_view: PTreeView): PTreeViewColumn{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_get_expander_column".}
proc set_column_drag_function*(tree_view: PTreeView,
    fun: TTreeViewColumnDropFunc, user_data: gpointer, destroy: TDestroyNotify){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_set_column_drag_function".}
proc scroll_to_point*(tree_view: PTreeView, tree_x: gint, tree_y: gint){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_scroll_to_point".}
proc scroll_to_cell*(tree_view: PTreeView, path: PTreePath,
                               column: PTreeViewColumn, use_align: gboolean,
                               row_align: gfloat, col_align: gfloat){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_scroll_to_cell".}
proc row_activated*(tree_view: PTreeView, path: PTreePath,
                              column: PTreeViewColumn){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_row_activated".}
proc expand_all*(tree_view: PTreeView){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_expand_all".}
proc collapse_all*(tree_view: PTreeView){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_collapse_all".}
proc expand_row*(tree_view: PTreeView, path: PTreePath,
                           open_all: gboolean): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_tree_view_expand_row".}
proc collapse_row*(tree_view: PTreeView, path: PTreePath): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_collapse_row".}
proc map_expanded_rows*(tree_view: PTreeView,
                                  fun: TTreeViewMappingFunc, data: gpointer){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_map_expanded_rows".}
proc row_expanded*(tree_view: PTreeView, path: PTreePath): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_row_expanded".}
proc set_reorderable*(tree_view: PTreeView, reorderable: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_set_reorderable".}
proc get_reorderable*(tree_view: PTreeView): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_get_reorderable".}
proc set_cursor*(tree_view: PTreeView, path: PTreePath,
                           focus_column: PTreeViewColumn,
                           start_editing: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_set_cursor".}
proc set_cursor_on_cell*(tree_view: PTreeView, path: PTreePath,
                                   focus_column: PTreeViewColumn,
                                   focus_cell: PCellRenderer,
                                   start_editing: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_set_cursor_on_cell".}
proc get_bin_window*(tree_view: PTreeView): gdk2.PWindow{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_get_bin_window".}
proc get_cell_area*(tree_view: PTreeView, path: PTreePath,
                              column: PTreeViewColumn, rect: gdk2.PRectangle){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_get_cell_area".}
proc get_background_area*(tree_view: PTreeView, path: PTreePath,
                                    column: PTreeViewColumn, rect: gdk2.PRectangle){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_get_background_area".}
proc get_visible_rect*(tree_view: PTreeView,
                                 visible_rect: gdk2.PRectangle){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_get_visible_rect".}
proc widget_to_tree_coords*(tree_view: PTreeView, wx: gint, wy: gint,
                                      tx: Pgint, ty: Pgint){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_widget_to_tree_coords".}
proc tree_to_widget_coords*(tree_view: PTreeView, tx: gint, ty: gint,
                                      wx: Pgint, wy: Pgint){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_tree_to_widget_coords".}
proc enable_model_drag_source*(tree_view: PTreeView,
    start_button_mask: gdk2.TModifierType, targets: PTargetEntry, n_targets: gint,
    actions: gdk2.TDragAction){.cdecl, dynlib: lib,
                              importc: "gtk_tree_view_enable_model_drag_source".}
proc enable_model_drag_dest*(tree_view: PTreeView,
                                       targets: PTargetEntry, n_targets: gint,
                                       actions: gdk2.TDragAction){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_enable_model_drag_dest".}
proc unset_rows_drag_source*(tree_view: PTreeView){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_unset_rows_drag_source".}
proc unset_rows_drag_dest*(tree_view: PTreeView){.cdecl, dynlib: lib,
    importc: "gtk_tree_view_unset_rows_drag_dest".}
proc set_drag_dest_row*(tree_view: PTreeView, path: PTreePath,
                                  pos: TTreeViewDropPosition){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_set_drag_dest_row".}
proc create_row_drag_icon*(tree_view: PTreeView, path: PTreePath): gdk2.PPixmap{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_create_row_drag_icon".}
proc set_enable_search*(tree_view: PTreeView, enable_search: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_set_enable_search".}
proc get_enable_search*(tree_view: PTreeView): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_get_enable_search".}
proc get_search_column*(tree_view: PTreeView): gint{.cdecl,
    dynlib: lib, importc: "gtk_tree_view_get_search_column".}
proc set_search_column*(tree_view: PTreeView, column: gint){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_set_search_column".}
proc get_search_equal_func*(tree_view: PTreeView): TTreeViewSearchEqualFunc{.
    cdecl, dynlib: lib, importc: "gtk_tree_view_get_search_equal_func".}
proc set_search_equal_func*(tree_view: PTreeView, search_equal_func: TTreeViewSearchEqualFunc,
                                      search_user_data: gpointer,
                                      search_destroy: TDestroyNotify){.cdecl,
    dynlib: lib, importc: "gtk_tree_view_set_search_equal_func".}
proc set_destroy_count_func*(tree_view: PTreeView,
                                       fun: TTreeDestroyCountFunc,
                                       data: gpointer, destroy: TDestroyNotify){.
    cdecl, dynlib: lib, importc: "gtk_tree_view_set_destroy_count_func".}
proc TYPE_VBUTTON_BOX*(): GType
proc VBUTTON_BOX*(obj: pointer): PVButtonBox
proc VBUTTON_BOX_CLASS*(klass: pointer): PVButtonBoxClass
proc IS_VBUTTON_BOX*(obj: pointer): bool
proc IS_VBUTTON_BOX_CLASS*(klass: pointer): bool
proc VBUTTON_BOX_GET_CLASS*(obj: pointer): PVButtonBoxClass
proc vbutton_box_get_type*(): TType{.cdecl, dynlib: lib,
                                     importc: "gtk_vbutton_box_get_type".}
proc vbutton_box_new*(): PVButtonBox{.cdecl, dynlib: lib,
                                      importc: "gtk_vbutton_box_new".}
proc TYPE_VIEWPORT*(): GType
proc VIEWPORT*(obj: pointer): PViewport
proc VIEWPORT_CLASS*(klass: pointer): PViewportClass
proc IS_VIEWPORT*(obj: pointer): bool
proc IS_VIEWPORT_CLASS*(klass: pointer): bool
proc VIEWPORT_GET_CLASS*(obj: pointer): PViewportClass
proc viewport_get_type*(): TType{.cdecl, dynlib: lib,
                                  importc: "gtk_viewport_get_type".}
proc viewport_new*(hadjustment: PAdjustment, vadjustment: PAdjustment): PViewport{.
    cdecl, dynlib: lib, importc: "gtk_viewport_new".}
proc get_hadjustment*(viewport: PViewport): PAdjustment{.cdecl,
    dynlib: lib, importc: "gtk_viewport_get_hadjustment".}
proc get_vadjustment*(viewport: PViewport): PAdjustment{.cdecl,
    dynlib: lib, importc: "gtk_viewport_get_vadjustment".}
proc set_hadjustment*(viewport: PViewport, adjustment: PAdjustment){.
    cdecl, dynlib: lib, importc: "gtk_viewport_set_hadjustment".}
proc set_vadjustment*(viewport: PViewport, adjustment: PAdjustment){.
    cdecl, dynlib: lib, importc: "gtk_viewport_set_vadjustment".}
proc set_shadow_type*(viewport: PViewport, thetype: TShadowType){.
    cdecl, dynlib: lib, importc: "gtk_viewport_set_shadow_type".}
proc get_shadow_type*(viewport: PViewport): TShadowType{.cdecl,
    dynlib: lib, importc: "gtk_viewport_get_shadow_type".}
proc TYPE_VPANED*(): GType
proc VPANED*(obj: pointer): PVPaned
proc VPANED_CLASS*(klass: pointer): PVPanedClass
proc IS_VPANED*(obj: pointer): bool
proc IS_VPANED_CLASS*(klass: pointer): bool
proc VPANED_GET_CLASS*(obj: pointer): PVPanedClass
proc vpaned_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_vpaned_get_type".}
proc vpaned_new*(): PVPaned{.cdecl, dynlib: lib, importc: "gtk_vpaned_new".}
proc TYPE_VRULER*(): GType
proc VRULER*(obj: pointer): PVRuler
proc VRULER_CLASS*(klass: pointer): PVRulerClass
proc IS_VRULER*(obj: pointer): bool
proc IS_VRULER_CLASS*(klass: pointer): bool
proc VRULER_GET_CLASS*(obj: pointer): PVRulerClass
proc vruler_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_vruler_get_type".}
proc vruler_new*(): PVRuler{.cdecl, dynlib: lib, importc: "gtk_vruler_new".}
proc TYPE_VSCALE*(): GType
proc VSCALE*(obj: pointer): PVScale
proc VSCALE_CLASS*(klass: pointer): PVScaleClass
proc IS_VSCALE*(obj: pointer): bool
proc IS_VSCALE_CLASS*(klass: pointer): bool
proc VSCALE_GET_CLASS*(obj: pointer): PVScaleClass
proc vscale_get_type*(): TType{.cdecl, dynlib: lib,
                                importc: "gtk_vscale_get_type".}
proc vscale_new*(adjustment: PAdjustment): PVScale{.cdecl, dynlib: lib,
    importc: "gtk_vscale_new".}
proc vscale_new*(min: gdouble, max: gdouble, step: gdouble): PVScale{.
    cdecl, dynlib: lib, importc: "gtk_vscale_new_with_range".}
proc TYPE_VSCROLLBAR*(): GType
proc VSCROLLBAR*(obj: pointer): PVScrollbar
proc VSCROLLBAR_CLASS*(klass: pointer): PVScrollbarClass
proc IS_VSCROLLBAR*(obj: pointer): bool
proc IS_VSCROLLBAR_CLASS*(klass: pointer): bool
proc VSCROLLBAR_GET_CLASS*(obj: pointer): PVScrollbarClass
proc vscrollbar_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_vscrollbar_get_type".}
proc vscrollbar_new*(adjustment: PAdjustment): PVScrollbar{.cdecl, dynlib: lib,
    importc: "gtk_vscrollbar_new".}
proc TYPE_VSEPARATOR*(): GType
proc VSEPARATOR*(obj: pointer): PVSeparator
proc VSEPARATOR_CLASS*(klass: pointer): PVSeparatorClass
proc IS_VSEPARATOR*(obj: pointer): bool
proc IS_VSEPARATOR_CLASS*(klass: pointer): bool
proc VSEPARATOR_GET_CLASS*(obj: pointer): PVSeparatorClass
proc vseparator_get_type*(): TType{.cdecl, dynlib: lib,
                                    importc: "gtk_vseparator_get_type".}
proc vseparator_new*(): PVSeparator{.cdecl, dynlib: lib,
                                     importc: "gtk_vseparator_new".}
proc TYPE_OBJECT*(): GType =
  result = gtk2.object_get_type()

proc CHECK_CAST*(instance: Pointer, g_type: GType): PGTypeInstance =
  result = G_TYPE_CHECK_INSTANCE_CAST(instance, g_type)

proc CHECK_CLASS_CAST*(g_class: pointer, g_type: GType): Pointer =
  result = G_TYPE_CHECK_CLASS_CAST(g_class, g_type)

proc CHECK_GET_CLASS*(instance: Pointer, g_type: GType): PGTypeClass =
  result = G_TYPE_INSTANCE_GET_CLASS(instance, g_type)

proc CHECK_TYPE*(instance: Pointer, g_type: GType): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(instance, g_type)

proc CHECK_CLASS_TYPE*(g_class: pointer, g_type: GType): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(g_class, g_type)

proc `OBJECT`*(anObject: pointer): PObject =
  result = cast[PObject](CHECK_CAST(anObject, gtk2.TYPE_OBJECT()))

proc OBJECT_CLASS*(klass: pointer): PObjectClass =
  result = cast[PObjectClass](CHECK_CLASS_CAST(klass, gtk2.TYPE_OBJECT()))

proc IS_OBJECT*(anObject: pointer): bool =
  result = CHECK_TYPE(anObject, gtk2.TYPE_OBJECT())

proc IS_OBJECT_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, gtk2.TYPE_OBJECT())

proc OBJECT_GET_CLASS*(anObject: pointer): PObjectClass =
  result = cast[PObjectClass](CHECK_GET_CLASS(anObject, gtk2.TYPE_OBJECT()))

proc OBJECT_TYPE*(anObject: pointer): GType =
  result = G_TYPE_FROM_INSTANCE(anObject)

proc OBJECT_TYPE_NAME*(anObject: pointer): cstring =
  result = g_type_name(OBJECT_TYPE(anObject))

proc OBJECT_FLAGS*(obj: pointer): guint32 =
  result = (gtk2.`OBJECT`(obj)).flags

proc OBJECT_FLOATING*(obj: pointer): gboolean =
  result = ((OBJECT_FLAGS(obj)) and cint(FLOATING)) != 0'i32

proc OBJECT_SET_FLAGS*(obj: pointer, flag: guint32) =
  gtk2.`OBJECT`(obj).flags = gtk2.`OBJECT`(obj).flags or flag

proc OBJECT_UNSET_FLAGS*(obj: pointer, flag: guint32) =
  gtk2.`OBJECT`(obj).flags = gtk2.`OBJECT`(obj).flags and not (flag)

proc object_data_try_key*(`string`: cstring): TGQuark =
  result = g_quark_try_string(`string`)

proc object_data_force_id*(`string`: cstring): TGQuark =
  result = g_quark_from_string(`string`)

proc CLASS_NAME*(`class`: pointer): cstring =
  result = g_type_name(G_TYPE_FROM_CLASS(`class`))

proc CLASS_TYPE*(`class`: pointer): GType =
  result = G_TYPE_FROM_CLASS(`class`)

proc TYPE_IS_OBJECT*(thetype: GType): gboolean =
  result = g_type_is_a(thetype, gtk2.TYPE_OBJECT())

proc TYPE_IDENTIFIER*(): GType =
  result = identifier_get_type()

proc SIGNAL_FUNC*(f: pointer): TSignalFunc =
  result = cast[TSignalFunc](f)

proc type_name*(thetype: GType): cstring =
  result = g_type_name(thetype)

proc type_from_name*(name: cstring): GType =
  result = g_type_from_name(name)

proc type_parent*(thetype: GType): GType =
  result = g_type_parent(thetype)

proc type_is_a*(thetype, is_a_type: GType): gboolean =
  result = g_type_is_a(thetype, is_a_type)

proc FUNDAMENTAL_TYPE*(thetype: GType): GType =
  result = G_TYPE_FUNDAMENTAL(thetype)

proc VALUE_CHAR*(a: TArg): gchar =
  var a = a
  Result = cast[ptr gchar](addr(a.d))[]

proc VALUE_UCHAR*(a: TArg): guchar =
  var a = a
  Result = cast[ptr guchar](addr(a.d))[]

proc VALUE_BOOL*(a: TArg): gboolean =
  var a = a
  Result = cast[ptr gboolean](addr(a.d))[]

proc VALUE_INT*(a: TArg): gint =
  var a = a
  Result = cast[ptr gint](addr(a.d))[]

proc VALUE_UINT*(a: TArg): guint =
  var a = a
  Result = cast[ptr guint](addr(a.d))[]

proc VALUE_LONG*(a: TArg): glong =
  var a = a
  Result = cast[ptr glong](addr(a.d))[]

proc VALUE_ULONG*(a: TArg): gulong =
  var a = a
  Result = cast[ptr gulong](addr(a.d))[]

proc VALUE_FLOAT*(a: TArg): gfloat =
  var a = a
  Result = cast[ptr gfloat](addr(a.d))[]

proc VALUE_DOUBLE*(a: TArg): gdouble =
  var a = a
  Result = cast[ptr gdouble](addr(a.d))[]

proc VALUE_STRING*(a: TArg): cstring =
  var a = a
  Result = cast[ptr cstring](addr(a.d))[]

proc VALUE_ENUM*(a: TArg): gint =
  var a = a
  Result = cast[ptr gint](addr(a.d))[]

proc VALUE_FLAGS*(a: TArg): guint =
  var a = a
  Result = cast[ptr guint](addr(a.d))[]

proc VALUE_BOXED*(a: TArg): gpointer =
  var a = a
  Result = cast[ptr gpointer](addr(a.d))[]

proc VALUE_OBJECT*(a: TArg): PObject =
  var a = a
  Result = cast[ptr PObject](addr(a.d))[]

proc VALUE_POINTER*(a: TArg): GPointer =
  var a = a
  Result = cast[ptr gpointer](addr(a.d))[]

proc VALUE_SIGNAL*(a: TArg): TArgSignalData =
  var a = a
  Result = cast[ptr TArgSignalData](addr(a.d))[]

proc RETLOC_CHAR*(a: TArg): cstring =
  var a = a
  Result = cast[ptr cstring](addr(a.d))[]

proc RETLOC_UCHAR*(a: TArg): Pguchar =
  var a = a
  Result = cast[ptr pguchar](addr(a.d))[]

proc RETLOC_BOOL*(a: TArg): Pgboolean =
  var a = a
  Result = cast[ptr pgboolean](addr(a.d))[]

proc RETLOC_INT*(a: TArg): Pgint =
  var a = a
  Result = cast[ptr pgint](addr(a.d))[]

proc RETLOC_UINT*(a: TArg): Pguint =
  var a = a
  Result = cast[ptr pguint](addr(a.d))[]

proc RETLOC_LONG*(a: TArg): Pglong =
  var a = a
  Result = cast[ptr pglong](addr(a.d))[]

proc RETLOC_ULONG*(a: TArg): Pgulong =
  var a = a
  Result = cast[ptr pgulong](addr(a.d))[]

proc RETLOC_FLOAT*(a: TArg): Pgfloat =
  var a = a
  Result = cast[ptr pgfloat](addr(a.d))[]

proc RETLOC_DOUBLE*(a: TArg): Pgdouble =
  var a = a
  Result = cast[ptr pgdouble](addr(a.d))[]

proc RETLOC_STRING*(a: TArg): Ppgchar =
  var a = a
  Result = cast[ptr Ppgchar](addr(a.d))[]

proc RETLOC_ENUM*(a: TArg): Pgint =
  var a = a
  Result = cast[ptr Pgint](addr(a.d))[]

proc RETLOC_FLAGS*(a: TArg): Pguint =
  var a = a
  Result = cast[ptr pguint](addr(a.d))[]

proc RETLOC_BOXED*(a: TArg): Pgpointer =
  var a = a
  Result = cast[ptr pgpointer](addr(a.d))[]

proc RETLOC_OBJECT*(a: TArg): PPGtkObject =
  var a = a
  Result = cast[ptr ppgtkobject](addr(a.d))[]

proc RETLOC_POINTER*(a: TArg): Pgpointer =
  var a = a
  Result = cast[ptr pgpointer](addr(a.d))[]

proc TYPE_WIDGET*(): GType =
  result = widget_get_type()

proc WIDGET*(widget: pointer): PWidget =
  result = cast[PWidget](CHECK_CAST(widget, TYPE_WIDGET()))

proc WIDGET_CLASS*(klass: pointer): PWidgetClass =
  result = cast[PWidgetClass](CHECK_CLASS_CAST(klass, TYPE_WIDGET()))

proc IS_WIDGET*(widget: pointer): bool =
  result = CHECK_TYPE(widget, TYPE_WIDGET())

proc IS_WIDGET_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_WIDGET())

proc WIDGET_GET_CLASS*(obj: pointer): PWidgetClass =
  result = cast[PWidgetClass](CHECK_GET_CLASS(obj, TYPE_WIDGET()))

proc WIDGET_TYPE*(wid: pointer): GType =
  result = OBJECT_TYPE(wid)

proc WIDGET_STATE*(wid: pointer): int32 =
  result = (WIDGET(wid)).state

proc WIDGET_SAVED_STATE*(wid: pointer): int32 =
  result = (WIDGET(wid)).saved_state

proc WIDGET_FLAGS*(wid: pointer): guint32 =
  result = OBJECT_FLAGS(wid)

proc WIDGET_TOPLEVEL*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(TOPLEVEL)) != 0'i32

proc WIDGET_NO_WINDOW*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(NO_WINDOW)) != 0'i32

proc WIDGET_REALIZED*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(constREALIZED)) != 0'i32

proc WIDGET_MAPPED*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(MAPPED)) != 0'i32

proc WIDGET_VISIBLE*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(constVISIBLE)) != 0'i32

proc WIDGET_DRAWABLE*(wid: pointer): gboolean =
  result = (WIDGET_VISIBLE(wid)) and (WIDGET_MAPPED(wid))

proc WIDGET_SENSITIVE*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(SENSITIVE)) != 0'i32

proc WIDGET_PARENT_SENSITIVE*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(PARENT_SENSITIVE)) != 0'i32

proc WIDGET_IS_SENSITIVE*(wid: pointer): gboolean =
  result = (WIDGET_SENSITIVE(wid)) and (WIDGET_PARENT_SENSITIVE(wid))

proc WIDGET_CAN_FOCUS*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(CAN_FOCUS)) != 0'i32

proc WIDGET_HAS_FOCUS*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(constHAS_FOCUS)) != 0'i32

proc WIDGET_CAN_DEFAULT*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(CAN_DEFAULT)) != 0'i32

proc WIDGET_HAS_DEFAULT*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(HAS_DEFAULT)) != 0'i32

proc WIDGET_HAS_GRAB*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(HAS_GRAB)) != 0'i32

proc WIDGET_RC_STYLE*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(RC_STYLE)) != 0'i32

proc WIDGET_COMPOSITE_CHILD*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(COMPOSITE_CHILD)) != 0'i32

proc WIDGET_APP_PAINTABLE*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(APP_PAINTABLE)) != 0'i32

proc WIDGET_RECEIVES_DEFAULT*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(RECEIVES_DEFAULT)) != 0'i32

proc WIDGET_DOUBLE_BUFFERED*(wid: pointer): gboolean =
  result = ((WIDGET_FLAGS(wid)) and cint(DOUBLE_BUFFERED)) != 0'i32

proc TYPE_REQUISITION*(): GType =
  result = requisition_get_type()

proc x_set*(a: PWidgetAuxInfo): guint =
  result = (a.flag0 and bm_TGtkWidgetAuxInfo_x_set) shr
      bp_TGtkWidgetAuxInfo_x_set

proc set_x_set*(a: PWidgetAuxInfo, `x_set`: guint) =
  a.flag0 = a.flag0 or
      (int16(`x_set` shl bp_TGtkWidgetAuxInfo_x_set) and
      bm_TGtkWidgetAuxInfo_x_set)

proc y_set*(a: PWidgetAuxInfo): guint =
  result = (a.flag0 and bm_TGtkWidgetAuxInfo_y_set) shr
      bp_TGtkWidgetAuxInfo_y_set

proc set_y_set*(a: PWidgetAuxInfo, `y_set`: guint) =
  a.flag0 = a.flag0 or
      (int16(`y_set` shl bp_TGtkWidgetAuxInfo_y_set) and
      bm_TGtkWidgetAuxInfo_y_set)

proc widget_set_visual*(widget, visual: pointer) =
  if (Widget != nil) and (visual != nil): nil

proc widget_push_visual*(visual: pointer) =
  if (visual != nil): nil

proc widget_pop_visual*() =
  nil

proc widget_set_default_visual*(visual: pointer) =
  if (visual != nil): nil

proc widget_set_rc_style*(widget: pointer) =
  set_style(cast[PWidget](widget), nil)

proc widget_restore_default_style*(widget: pointer) =
  set_style(cast[PWidget](widget), nil)

proc SET_FLAGS*(wid: PWidget, flags: TWidgetFlags): TWidgetFlags =
  cast[pObject](wid).flags = cast[pObject](wid).flags or (flags)
  result = cast[pObject](wid).flags

proc UNSET_FLAGS*(wid: PWidget, flags: TWidgetFlags): TWidgetFlags =
  cast[pObject](wid).flags = cast[pObject](wid).flags and (not (flags))
  result = cast[pObject](wid).flags

proc TYPE_MISC*(): GType =
  result = misc_get_type()

proc MISC*(obj: pointer): PMisc =
  result = cast[PMisc](CHECK_CAST(obj, TYPE_MISC()))

proc MISC_CLASS*(klass: pointer): PMiscClass =
  result = cast[PMiscClass](CHECK_CLASS_CAST(klass, TYPE_MISC()))

proc IS_MISC*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_MISC())

proc IS_MISC_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_MISC())

proc MISC_GET_CLASS*(obj: pointer): PMiscClass =
  result = cast[PMiscClass](CHECK_GET_CLASS(obj, TYPE_MISC()))

proc TYPE_ACCEL_GROUP*(): GType =
  result = accel_group_get_type()

proc ACCEL_GROUP*(anObject: pointer): PAccelGroup =
  result = cast[PAccelGroup](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      TYPE_ACCEL_GROUP()))

proc ACCEL_GROUP_CLASS*(klass: pointer): PAccelGroupClass =
  result = cast[PAccelGroupClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_ACCEL_GROUP()))

proc IS_ACCEL_GROUP*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_ACCEL_GROUP())

proc IS_ACCEL_GROUP_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_ACCEL_GROUP())

proc ACCEL_GROUP_GET_CLASS*(obj: pointer): PAccelGroupClass =
  result = cast[PAccelGroupClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_ACCEL_GROUP()))

proc accel_flags*(a: PAccelKey): guint =
  result = (a.flag0 and bm_TGtkAccelKey_accel_flags) shr
      bp_TGtkAccelKey_accel_flags

proc set_accel_flags*(a: PAccelKey, `accel_flags`: guint) =
  a.flag0 = a.flag0 or
      (int16(`accel_flags` shl bp_TGtkAccelKey_accel_flags) and
      bm_TGtkAccelKey_accel_flags)

proc reference*(AccelGroup: PAccelGroup) =
  discard g_object_ref(AccelGroup)

proc unref*(AccelGroup: PAccelGroup) =
  g_object_unref(AccelGroup)

proc TYPE_CONTAINER*(): GType =
  result = container_get_type()

proc CONTAINER*(obj: pointer): PContainer =
  result = cast[PContainer](CHECK_CAST(obj, TYPE_CONTAINER()))

proc CONTAINER_CLASS*(klass: pointer): PContainerClass =
  result = cast[PContainerClass](CHECK_CLASS_CAST(klass, TYPE_CONTAINER()))

proc IS_CONTAINER*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_CONTAINER())

proc IS_CONTAINER_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_CONTAINER())

proc CONTAINER_GET_CLASS*(obj: pointer): PContainerClass =
  result = cast[PContainerClass](CHECK_GET_CLASS(obj, TYPE_CONTAINER()))

proc IS_RESIZE_CONTAINER*(widget: pointer): bool =
  result = (IS_CONTAINER(widget)) and
      ((resize_mode(cast[PContainer](widget))) != cint(RESIZE_PARENT))

proc border_width*(a: PContainer): guint =
  result = (a.Container_flag0 and bm_TGtkContainer_border_width) shr
      bp_TGtkContainer_border_width

proc need_resize*(a: PContainer): guint =
  result = (a.Container_flag0 and bm_TGtkContainer_need_resize) shr
      bp_TGtkContainer_need_resize

proc set_need_resize*(a: PContainer, `need_resize`: guint) =
  a.Container_flag0 = a.Container_flag0 or
      ((`need_resize` shl bp_TGtkContainer_need_resize) and
      bm_TGtkContainer_need_resize)

proc resize_mode*(a: PContainer): guint =
  result = (a.Container_flag0 and bm_TGtkContainer_resize_mode) shr
      bp_TGtkContainer_resize_mode

proc set_resize_mode*(a: PContainer, `resize_mode`: guint) =
  a.Containerflag0 = a.Containerflag0 or
      ((`resize_mode` shl bp_TGtkContainer_resize_mode) and
      bm_TGtkContainer_resize_mode)

proc reallocate_redraws*(a: PContainer): guint =
  result = (a.Containerflag0 and bm_TGtkContainer_reallocate_redraws) shr
      bp_TGtkContainer_reallocate_redraws

proc set_reallocate_redraws*(a: PContainer, `reallocate_redraws`: guint) =
  a.Containerflag0 = a.Containerflag0 or
      ((`reallocate_redraws` shl bp_TGtkContainer_reallocate_redraws) and
      bm_TGtkContainer_reallocate_redraws)

proc has_focus_chain*(a: PContainer): guint =
  result = (a.Containerflag0 and bm_TGtkContainer_has_focus_chain) shr
      bp_TGtkContainer_has_focus_chain

proc set_has_focus_chain*(a: PContainer, `has_focus_chain`: guint) =
  a.Containerflag0 = a.Containerflag0 or
      ((`has_focus_chain` shl bp_TGtkContainer_has_focus_chain) and
      bm_TGtkContainer_has_focus_chain)

proc CONTAINER_WARN_INVALID_CHILD_PROPERTY_ID*(anObject: pointer,
    property_id: guint, pspec: pointer) =
  write(stdout, "WARNING: invalid child property id\x0A")

proc TYPE_BIN*(): GType =
  result = bin_get_type()

proc BIN*(obj: pointer): PBin =
  result = cast[PBin](CHECK_CAST(obj, TYPE_BIN()))

proc BIN_CLASS*(klass: pointer): PBinClass =
  result = cast[PBinClass](CHECK_CLASS_CAST(klass, TYPE_BIN()))

proc IS_BIN*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_BIN())

proc IS_BIN_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_BIN())

proc BIN_GET_CLASS*(obj: pointer): PBinClass =
  result = cast[PBinClass](CHECK_GET_CLASS(obj, TYPE_BIN()))

proc TYPE_WINDOW*(): GType =
  result = window_get_type()

proc WINDOW*(obj: pointer): PWindow =
  result = cast[PWindow](CHECK_CAST(obj, gtk2.TYPE_WINDOW()))

proc WINDOW_CLASS*(klass: pointer): PWindowClass =
  result = cast[PWindowClass](CHECK_CLASS_CAST(klass, gtk2.TYPE_WINDOW()))

proc IS_WINDOW*(obj: pointer): bool =
  result = CHECK_TYPE(obj, gtk2.TYPE_WINDOW())

proc IS_WINDOW_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, gtk2.TYPE_WINDOW())

proc WINDOW_GET_CLASS*(obj: pointer): PWindowClass =
  result = cast[PWindowClass](CHECK_GET_CLASS(obj, gtk2.TYPE_WINDOW()))

proc allow_shrink*(a: gtk2.PWindow): guint =
  result = (a.Window_flag0 and bm_TGtkWindow_allow_shrink) shr
      bp_TGtkWindow_allow_shrink

proc set_allow_shrink*(a: gtk2.PWindow, `allow_shrink`: guint) =
  a.Window_flag0 = a.Window_flag0 or
      ((`allow_shrink` shl bp_TGtkWindow_allow_shrink) and
      bm_TGtkWindow_allow_shrink)

proc allow_grow*(a: gtk2.PWindow): guint =
  result = (a.Window_flag0 and bm_TGtkWindow_allow_grow) shr
      bp_TGtkWindow_allow_grow

proc set_allow_grow*(a: gtk2.PWindow, `allow_grow`: guint) =
  a.Window_flag0 = a.Window_flag0 or
      ((`allow_grow` shl bp_TGtkWindow_allow_grow) and
      bm_TGtkWindow_allow_grow)

proc configure_notify_received*(a: gtk2.PWindow): guint =
  result = (a.Window_flag0 and bm_TGtkWindow_configure_notify_received) shr
      bp_TGtkWindow_configure_notify_received

proc set_configure_notify_received*(a: gtk2.PWindow,
                                    `configure_notify_received`: guint) =
  a.Window_flag0 = a.Window_flag0 or
      ((`configure_notify_received` shl
      bp_TGtkWindow_configure_notify_received) and
      bm_TGtkWindow_configure_notify_received)

proc need_default_position*(a: gtk2.PWindow): guint =
  result = (a.Window_flag0 and bm_TGtkWindow_need_default_position) shr
      bp_TGtkWindow_need_default_position

proc set_need_default_position*(a: gtk2.PWindow, `need_default_position`: guint) =
  a.Window_flag0 = a.Window_flag0 or
      ((`need_default_position` shl bp_TGtkWindow_need_default_position) and
      bm_TGtkWindow_need_default_position)

proc need_default_size*(a: gtk2.PWindow): guint =
  result = (a.Window_flag0 and bm_TGtkWindow_need_default_size) shr
      bp_TGtkWindow_need_default_size

proc set_need_default_size*(a: gtk2.PWindow, `need_default_size`: guint) =
  a.Window_flag0 = a.Window_flag0 or
      ((`need_default_size` shl bp_TGtkWindow_need_default_size) and
      bm_TGtkWindow_need_default_size)

proc position*(a: gtk2.PWindow): guint =
  result = (a.Window_flag0 and bm_TGtkWindow_position) shr
      bp_TGtkWindow_position

proc get_type*(a: gtk2.PWindow): guint =
  result = (a.Window_flag0 and bm_TGtkWindow_type) shr bp_TGtkWindow_type

proc set_type*(a: gtk2.PWindow, `type`: guint) =
  a.Window_flag0 = a.Window_flag0 or
      ((`type` shl bp_TGtkWindow_type) and bm_TGtkWindow_type)

proc has_user_ref_count*(a: gtk2.PWindow): guint =
  result = (a.Window_flag0 and bm_TGtkWindow_has_user_ref_count) shr
      bp_TGtkWindow_has_user_ref_count

proc set_has_user_ref_count*(a: gtk2.PWindow, `has_user_ref_count`: guint) =
  a.Window_flag0 = a.Window_flag0 or
      ((`has_user_ref_count` shl bp_TGtkWindow_has_user_ref_count) and
      bm_TGtkWindow_has_user_ref_count)

proc has_focus*(a: gtk2.PWindow): guint =
  result = (a.Window_flag0 and bm_TGtkWindow_has_focus) shr
      bp_TGtkWindow_has_focus

proc set_has_focus*(a: gtk2.PWindow, `has_focus`: guint) =
  a.Window_flag0 = a.Window_flag0 or
      ((`has_focus` shl bp_TGtkWindow_has_focus) and bm_TGtkWindow_has_focus)

proc modal*(a: gtk2.PWindow): guint =
  result = (a.Window_flag0 and bm_TGtkWindow_modal) shr bp_TGtkWindow_modal

proc set_modal*(a: gtk2.PWindow, `modal`: guint) =
  a.Window_flag0 = a.Window_flag0 or
      ((`modal` shl bp_TGtkWindow_modal) and bm_TGtkWindow_modal)

proc destroy_with_parent*(a: gtk2.PWindow): guint =
  result = (a.Window_flag0 and bm_TGtkWindow_destroy_with_parent) shr
      bp_TGtkWindow_destroy_with_parent

proc set_destroy_with_parent*(a: gtk2.PWindow, `destroy_with_parent`: guint) =
  a.Windowflag0 = a.Windowflag0 or
      ((`destroy_with_parent` shl bp_TGtkWindow_destroy_with_parent) and
      bm_TGtkWindow_destroy_with_parent)

proc has_frame*(a: gtk2.PWindow): guint =
  result = (a.Windowflag0 and bm_TGtkWindow_has_frame) shr
      bp_TGtkWindow_has_frame

proc set_has_frame*(a: gtk2.PWindow, `has_frame`: guint) =
  a.Windowflag0 = a.Windowflag0 or
      ((`has_frame` shl bp_TGtkWindow_has_frame) and bm_TGtkWindow_has_frame)

proc iconify_initially*(a: gtk2.PWindow): guint =
  result = (a.Windowflag0 and bm_TGtkWindow_iconify_initially) shr
      bp_TGtkWindow_iconify_initially

proc set_iconify_initially*(a: gtk2.PWindow, `iconify_initially`: guint) =
  a.Windowflag0 = a.Windowflag0 or
      ((`iconify_initially` shl bp_TGtkWindow_iconify_initially) and
      bm_TGtkWindow_iconify_initially)

proc stick_initially*(a: gtk2.PWindow): guint =
  result = (a.Windowflag0 and bm_TGtkWindow_stick_initially) shr
      bp_TGtkWindow_stick_initially

proc set_stick_initially*(a: gtk2.PWindow, `stick_initially`: guint) =
  a.Windowflag0 = a.Windowflag0 or
      ((`stick_initially` shl bp_TGtkWindow_stick_initially) and
      bm_TGtkWindow_stick_initially)

proc maximize_initially*(a: gtk2.PWindow): guint =
  result = (a.Windowflag0 and bm_TGtkWindow_maximize_initially) shr
      bp_TGtkWindow_maximize_initially

proc set_maximize_initially*(a: gtk2.PWindow, `maximize_initially`: guint) =
  a.Windowflag0 = a.Windowflag0 or
      ((`maximize_initially` shl bp_TGtkWindow_maximize_initially) and
      bm_TGtkWindow_maximize_initially)

proc decorated*(a: gtk2.PWindow): guint =
  result = (a.Windowflag0 and bm_TGtkWindow_decorated) shr
      bp_TGtkWindow_decorated

proc set_decorated*(a: gtk2.PWindow, `decorated`: guint) =
  a.Windowflag0 = a.Windowflag0 or
      ((`decorated` shl bp_TGtkWindow_decorated) and bm_TGtkWindow_decorated)

proc type_hint*(a: gtk2.PWindow): guint =
  result = (a.Windowflag0 and bm_TGtkWindow_type_hint) shr
      bp_TGtkWindow_type_hint

proc set_type_hint*(a: gtk2.PWindow, `type_hint`: guint) =
  a.Windowflag0 = a.Windowflag0 or
      ((`type_hint` shl bp_TGtkWindow_type_hint) and bm_TGtkWindow_type_hint)

proc gravity*(a: gtk2.PWindow): guint =
  result = (a.Windowflag0 and bm_TGtkWindow_gravity) shr
      bp_TGtkWindow_gravity

proc set_gravity*(a: gtk2.PWindow, `gravity`: guint) =
  a.Windowflag0 = a.Windowflag0 or
      ((`gravity` shl bp_TGtkWindow_gravity) and bm_TGtkWindow_gravity)

proc TYPE_WINDOW_GROUP*(): GType =
  result = window_group_get_type()

proc WINDOW_GROUP*(anObject: pointer): PWindowGroup =
  result = cast[PWindowGroup](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      TYPE_WINDOW_GROUP()))

proc WINDOW_GROUP_CLASS*(klass: pointer): PWindowGroupClass =
  result = cast[PWindowGroupClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_WINDOW_GROUP()))

proc IS_WINDOW_GROUP*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_WINDOW_GROUP())

proc IS_WINDOW_GROUP_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_WINDOW_GROUP())

proc WINDOW_GROUP_GET_CLASS*(obj: pointer): PWindowGroupClass =
  result = cast[PWindowGroupClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_WINDOW_GROUP()))

proc TYPE_LABEL*(): GType =
  result = label_get_type()

proc LABEL*(obj: pointer): PLabel =
  result = cast[PLabel](CHECK_CAST(obj, TYPE_LABEL()))

proc LABEL_CLASS*(klass: pointer): PLabelClass =
  result = cast[PLabelClass](CHECK_CLASS_CAST(klass, TYPE_LABEL()))

proc IS_LABEL*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_LABEL())

proc IS_LABEL_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_LABEL())

proc LABEL_GET_CLASS*(obj: pointer): PLabelClass =
  result = cast[PLabelClass](CHECK_GET_CLASS(obj, TYPE_LABEL()))

proc jtype*(a: PLabel): guint =
  result = (a.Labelflag0 and bm_TGtkLabel_jtype) shr bp_TGtkLabel_jtype

proc set_jtype*(a: PLabel, `jtype`: guint) =
  a.Labelflag0 = a.Labelflag0 or
      (int16(`jtype` shl bp_TGtkLabel_jtype) and bm_TGtkLabel_jtype)

proc wrap*(a: PLabel): guint =
  result = (a.Labelflag0 and bm_TGtkLabel_wrap) shr bp_TGtkLabel_wrap

proc set_wrap*(a: PLabel, `wrap`: guint) =
  a.Labelflag0 = a.Labelflag0 or
      (int16(`wrap` shl bp_TGtkLabel_wrap) and bm_TGtkLabel_wrap)

proc use_underline*(a: PLabel): guint =
  result = (a.Labelflag0 and bm_TGtkLabel_use_underline) shr
      bp_TGtkLabel_use_underline

proc set_use_underline*(a: PLabel, `use_underline`: guint) =
  a.Labelflag0 = a.Labelflag0 or
      (int16(`use_underline` shl bp_TGtkLabel_use_underline) and
      bm_TGtkLabel_use_underline)

proc use_markup*(a: PLabel): guint =
  result = (a.Labelflag0 and bm_TGtkLabel_use_markup) shr
      bp_TGtkLabel_use_markup

proc set_use_markup*(a: PLabel, `use_markup`: guint) =
  a.Labelflag0 = a.Labelflag0 or
      (int16(`use_markup` shl bp_TGtkLabel_use_markup) and
      bm_TGtkLabel_use_markup)

proc TYPE_ACCEL_LABEL*(): GType =
  result = accel_label_get_type()

proc ACCEL_LABEL*(obj: pointer): PAccelLabel =
  result = cast[PAccelLabel](CHECK_CAST(obj, TYPE_ACCEL_LABEL()))

proc ACCEL_LABEL_CLASS*(klass: pointer): PAccelLabelClass =
  result = cast[PAccelLabelClass](CHECK_CLASS_CAST(klass, TYPE_ACCEL_LABEL()))

proc IS_ACCEL_LABEL*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_ACCEL_LABEL())

proc IS_ACCEL_LABEL_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_ACCEL_LABEL())

proc ACCEL_LABEL_GET_CLASS*(obj: pointer): PAccelLabelClass =
  result = cast[PAccelLabelClass](CHECK_GET_CLASS(obj, TYPE_ACCEL_LABEL()))

proc latin1_to_char*(a: PAccelLabelClass): guint =
  result = (a.AccelLabelClassflag0 and bm_TGtkAccelLabelClass_latin1_to_char) shr
      bp_TGtkAccelLabelClass_latin1_to_char

proc set_latin1_to_char*(a: PAccelLabelClass, `latin1_to_char`: guint) =
  a.AccelLabelClassflag0 = a.AccelLabelClassflag0 or
      (int16(`latin1_to_char` shl bp_TGtkAccelLabelClass_latin1_to_char) and
      bm_TGtkAccelLabelClass_latin1_to_char)

proc accelerator_width*(accel_label: PAccelLabel): guint =
  result = get_accel_width(accel_label)

proc TYPE_ACCESSIBLE*(): GType =
  result = accessible_get_type()

proc ACCESSIBLE*(obj: pointer): PAccessible =
  result = cast[PAccessible](CHECK_CAST(obj, TYPE_ACCESSIBLE()))

proc ACCESSIBLE_CLASS*(klass: pointer): PAccessibleClass =
  result = cast[PAccessibleClass](CHECK_CLASS_CAST(klass, TYPE_ACCESSIBLE()))

proc IS_ACCESSIBLE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_ACCESSIBLE())

proc IS_ACCESSIBLE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_ACCESSIBLE())

proc ACCESSIBLE_GET_CLASS*(obj: pointer): PAccessibleClass =
  result = cast[PAccessibleClass](CHECK_GET_CLASS(obj, TYPE_ACCESSIBLE()))

proc TYPE_ADJUSTMENT*(): GType =
  result = adjustment_get_type()

proc ADJUSTMENT*(obj: pointer): PAdjustment =
  result = cast[PAdjustment](CHECK_CAST(obj, TYPE_ADJUSTMENT()))

proc ADJUSTMENT_CLASS*(klass: pointer): PAdjustmentClass =
  result = cast[PAdjustmentClass](CHECK_CLASS_CAST(klass, TYPE_ADJUSTMENT()))

proc IS_ADJUSTMENT*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_ADJUSTMENT())

proc IS_ADJUSTMENT_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_ADJUSTMENT())

proc ADJUSTMENT_GET_CLASS*(obj: pointer): PAdjustmentClass =
  result = cast[PAdjustmentClass](CHECK_GET_CLASS(obj, TYPE_ADJUSTMENT()))

proc TYPE_ALIGNMENT*(): GType =
  result = alignment_get_type()

proc ALIGNMENT*(obj: pointer): PAlignment =
  result = cast[PAlignment](CHECK_CAST(obj, TYPE_ALIGNMENT()))

proc ALIGNMENT_CLASS*(klass: pointer): PAlignmentClass =
  result = cast[PAlignmentClass](CHECK_CLASS_CAST(klass, TYPE_ALIGNMENT()))

proc IS_ALIGNMENT*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_ALIGNMENT())

proc IS_ALIGNMENT_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_ALIGNMENT())

proc ALIGNMENT_GET_CLASS*(obj: pointer): PAlignmentClass =
  result = cast[PAlignmentClass](CHECK_GET_CLASS(obj, TYPE_ALIGNMENT()))

proc TYPE_FRAME*(): GType =
  result = frame_get_type()

proc FRAME*(obj: pointer): PFrame =
  result = cast[PFrame](CHECK_CAST(obj, TYPE_FRAME()))

proc FRAME_CLASS*(klass: pointer): PFrameClass =
  result = cast[PFrameClass](CHECK_CLASS_CAST(klass, TYPE_FRAME()))

proc IS_FRAME*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_FRAME())

proc IS_FRAME_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_FRAME())

proc FRAME_GET_CLASS*(obj: pointer): PFrameClass =
  result = cast[PFrameClass](CHECK_GET_CLASS(obj, TYPE_FRAME()))

proc TYPE_ASPECT_FRAME*(): GType =
  result = aspect_frame_get_type()

proc ASPECT_FRAME*(obj: pointer): PAspectFrame =
  result = cast[PAspectFrame](CHECK_CAST(obj, TYPE_ASPECT_FRAME()))

proc ASPECT_FRAME_CLASS*(klass: pointer): PAspectFrameClass =
  result = cast[PAspectFrameClass](CHECK_CLASS_CAST(klass, TYPE_ASPECT_FRAME()))

proc IS_ASPECT_FRAME*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_ASPECT_FRAME())

proc IS_ASPECT_FRAME_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_ASPECT_FRAME())

proc ASPECT_FRAME_GET_CLASS*(obj: pointer): PAspectFrameClass =
  result = cast[PAspectFrameClass](CHECK_GET_CLASS(obj, TYPE_ASPECT_FRAME()))

proc TYPE_ARROW*(): GType =
  result = arrow_get_type()

proc ARROW*(obj: pointer): PArrow =
  result = cast[PArrow](CHECK_CAST(obj, TYPE_ARROW()))

proc ARROW_CLASS*(klass: pointer): PArrowClass =
  result = cast[PArrowClass](CHECK_CLASS_CAST(klass, TYPE_ARROW()))

proc IS_ARROW*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_ARROW())

proc IS_ARROW_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_ARROW())

proc ARROW_GET_CLASS*(obj: pointer): PArrowClass =
  result = cast[PArrowClass](CHECK_GET_CLASS(obj, TYPE_ARROW()))

proc parsed*(a: PBindingSet): guint =
  result = (a.flag0 and bm_TGtkBindingSet_parsed) shr
      bp_TGtkBindingSet_parsed

proc set_parsed*(a: PBindingSet, `parsed`: guint) =
  a.flag0 = a.flag0 or
      (int16(`parsed` shl bp_TGtkBindingSet_parsed) and
      bm_TGtkBindingSet_parsed)

proc destroyed*(a: PBindingEntry): guint =
  result = (a.flag0 and bm_TGtkBindingEntry_destroyed) shr
      bp_TGtkBindingEntry_destroyed

proc set_destroyed*(a: PBindingEntry, `destroyed`: guint) =
  a.flag0 = a.flag0 or
      (int16(`destroyed` shl bp_TGtkBindingEntry_destroyed) and
      bm_TGtkBindingEntry_destroyed)

proc in_emission*(a: PBindingEntry): guint =
  result = (a.flag0 and bm_TGtkBindingEntry_in_emission) shr
      bp_TGtkBindingEntry_in_emission

proc set_in_emission*(a: PBindingEntry, `in_emission`: guint) =
  a.flag0 = a.flag0 or
      (int16(`in_emission` shl bp_TGtkBindingEntry_in_emission) and
      bm_TGtkBindingEntry_in_emission)

proc entry_add*(binding_set: PBindingSet, keyval: guint,
                        modifiers: gdk2.TModifierType) =
  entry_clear(binding_set, keyval, modifiers)

proc TYPE_BOX*(): GType =
  result = box_get_type()

proc BOX*(obj: pointer): PBox =
  result = cast[PBox](CHECK_CAST(obj, TYPE_BOX()))

proc BOX_CLASS*(klass: pointer): PBoxClass =
  result = cast[PBoxClass](CHECK_CLASS_CAST(klass, TYPE_BOX()))

proc IS_BOX*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_BOX())

proc IS_BOX_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_BOX())

proc BOX_GET_CLASS*(obj: pointer): PBoxClass =
  result = cast[PBoxClass](CHECK_GET_CLASS(obj, TYPE_BOX()))

proc homogeneous*(a: PBox): guint =
  result = (a.Boxflag0 and bm_TGtkBox_homogeneous) shr bp_TGtkBox_homogeneous

proc set_homogeneous*(a: PBox, `homogeneous`: guint) =
  a.Boxflag0 = a.Boxflag0 or
      (int16(`homogeneous` shl bp_TGtkBox_homogeneous) and
      bm_TGtkBox_homogeneous)

proc expand*(a: PBoxChild): guint =
  result = (a.flag0 and bm_TGtkBoxChild_expand) shr bp_TGtkBoxChild_expand

proc set_expand*(a: PBoxChild, `expand`: guint) =
  a.flag0 = a.flag0 or
      (int16(`expand` shl bp_TGtkBoxChild_expand) and bm_TGtkBoxChild_expand)

proc fill*(a: PBoxChild): guint =
  result = (a.flag0 and bm_TGtkBoxChild_fill) shr bp_TGtkBoxChild_fill

proc set_fill*(a: PBoxChild, `fill`: guint) =
  a.flag0 = a.flag0 or
      (int16(`fill` shl bp_TGtkBoxChild_fill) and bm_TGtkBoxChild_fill)

proc pack*(a: PBoxChild): guint =
  result = (a.flag0 and bm_TGtkBoxChild_pack) shr bp_TGtkBoxChild_pack

proc set_pack*(a: PBoxChild, `pack`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pack` shl bp_TGtkBoxChild_pack) and bm_TGtkBoxChild_pack)

proc is_secondary*(a: PBoxChild): guint =
  result = (a.flag0 and bm_TGtkBoxChild_is_secondary) shr
      bp_TGtkBoxChild_is_secondary

proc set_is_secondary*(a: PBoxChild, `is_secondary`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_secondary` shl bp_TGtkBoxChild_is_secondary) and
      bm_TGtkBoxChild_is_secondary)

proc TYPE_BUTTON_BOX*(): GType =
  result = button_box_get_type()

proc BUTTON_BOX*(obj: pointer): PButtonBox =
  result = cast[PButtonBox](CHECK_CAST(obj, TYPE_BUTTON_BOX()))

proc BUTTON_BOX_CLASS*(klass: pointer): PButtonBoxClass =
  result = cast[PButtonBoxClass](CHECK_CLASS_CAST(klass, TYPE_BUTTON_BOX()))

proc IS_BUTTON_BOX*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_BUTTON_BOX())

proc IS_BUTTON_BOX_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_BUTTON_BOX())

proc BUTTON_BOX_GET_CLASS*(obj: pointer): PButtonBoxClass =
  result = cast[PButtonBoxClass](CHECK_GET_CLASS(obj, TYPE_BUTTON_BOX()))

proc button_box_set_spacing*(b: pointer, s: gint) =
  set_spacing(BOX(b), s)

proc button_box_get_spacing*(b: pointer): gint =
  result = get_spacing(BOX(b))

proc TYPE_BUTTON*(): GType =
  result = button_get_type()

proc BUTTON*(obj: pointer): PButton =
  result = cast[PButton](CHECK_CAST(obj, TYPE_BUTTON()))

proc BUTTON_CLASS*(klass: pointer): PButtonClass =
  result = cast[PButtonClass](CHECK_CLASS_CAST(klass, TYPE_BUTTON()))

proc IS_BUTTON*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_BUTTON())

proc IS_BUTTON_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_BUTTON())

proc BUTTON_GET_CLASS*(obj: pointer): PButtonClass =
  result = cast[PButtonClass](CHECK_GET_CLASS(obj, TYPE_BUTTON()))

proc constructed*(a: PButton): guint =
  result = (a.Buttonflag0 and bm_TGtkButton_constructed) shr
      bp_TGtkButton_constructed

proc set_constructed*(a: PButton, `constructed`: guint) =
  a.Buttonflag0 = a.Buttonflag0 or
      (int16(`constructed` shl bp_TGtkButton_constructed) and
      bm_TGtkButton_constructed)

proc in_button*(a: PButton): guint =
  result = (a.Buttonflag0 and bm_TGtkButton_in_button) shr
      bp_TGtkButton_in_button

proc set_in_button*(a: PButton, `in_button`: guint) =
  a.Buttonflag0 = a.Buttonflag0 or
      (int16(`in_button` shl bp_TGtkButton_in_button) and
      bm_TGtkButton_in_button)

proc button_down*(a: PButton): guint =
  result = (a.Buttonflag0 and bm_TGtkButton_button_down) shr
      bp_TGtkButton_button_down

proc set_button_down*(a: PButton, `button_down`: guint) =
  a.Buttonflag0 = a.Buttonflag0 or
      (int16(`button_down` shl bp_TGtkButton_button_down) and
      bm_TGtkButton_button_down)

proc relief*(a: PButton): guint =
  result = (a.Buttonflag0 and bm_TGtkButton_relief) shr bp_TGtkButton_relief

proc use_underline*(a: PButton): guint =
  result = (a.Buttonflag0 and bm_TGtkButton_use_underline) shr
      bp_TGtkButton_use_underline

proc set_use_underline*(a: PButton, `use_underline`: guint) =
  a.Buttonflag0 = a.Buttonflag0 or
      (int16(`use_underline` shl bp_TGtkButton_use_underline) and
      bm_TGtkButton_use_underline)

proc use_stock*(a: PButton): guint =
  result = (a.Buttonflag0 and bm_TGtkButton_use_stock) shr
      bp_TGtkButton_use_stock

proc set_use_stock*(a: PButton, `use_stock`: guint) =
  a.Buttonflag0 = a.Buttonflag0 or
      (int16(`use_stock` shl bp_TGtkButton_use_stock) and
      bm_TGtkButton_use_stock)

proc depressed*(a: PButton): guint =
  result = (a.Buttonflag0 and bm_TGtkButton_depressed) shr
      bp_TGtkButton_depressed

proc set_depressed*(a: PButton, `depressed`: guint) =
  a.Buttonflag0 = a.Buttonflag0 or
      (int16(`depressed` shl bp_TGtkButton_depressed) and
      bm_TGtkButton_depressed)

proc depress_on_activate*(a: PButton): guint =
  result = (a.Buttonflag0 and bm_TGtkButton_depress_on_activate) shr
      bp_TGtkButton_depress_on_activate

proc set_depress_on_activate*(a: PButton, `depress_on_activate`: guint) =
  a.Buttonflag0 = a.Buttonflag0 or
      (int16(`depress_on_activate` shl bp_TGtkButton_depress_on_activate) and
      bm_TGtkButton_depress_on_activate)

proc TYPE_CALENDAR*(): GType =
  result = calendar_get_type()

proc CALENDAR*(obj: pointer): PCalendar =
  result = cast[PCalendar](CHECK_CAST(obj, TYPE_CALENDAR()))

proc CALENDAR_CLASS*(klass: pointer): PCalendarClass =
  result = cast[PCalendarClass](CHECK_CLASS_CAST(klass, TYPE_CALENDAR()))

proc IS_CALENDAR*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_CALENDAR())

proc IS_CALENDAR_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_CALENDAR())

proc CALENDAR_GET_CLASS*(obj: pointer): PCalendarClass =
  result = cast[PCalendarClass](CHECK_GET_CLASS(obj, TYPE_CALENDAR()))

proc TYPE_CELL_EDITABLE*(): GType =
  result = cell_editable_get_type()

proc CELL_EDITABLE*(obj: pointer): PCellEditable =
  result = cast[PCellEditable](G_TYPE_CHECK_INSTANCE_CAST(obj,
      TYPE_CELL_EDITABLE()))

proc CELL_EDITABLE_CLASS*(obj: pointer): PCellEditableIface =
  result = cast[PCellEditableIface](G_TYPE_CHECK_CLASS_CAST(obj,
      TYPE_CELL_EDITABLE()))

proc IS_CELL_EDITABLE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_CELL_EDITABLE())

proc CELL_EDITABLE_GET_IFACE*(obj: pointer): PCellEditableIface =
  result = cast[PCellEditableIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      TYPE_CELL_EDITABLE()))

proc TYPE_CELL_RENDERER*(): GType =
  result = cell_renderer_get_type()

proc CELL_RENDERER*(obj: pointer): PCellRenderer =
  result = cast[PCellRenderer](CHECK_CAST(obj, TYPE_CELL_RENDERER()))

proc CELL_RENDERER_CLASS*(klass: pointer): PCellRendererClass =
  result = cast[PCellRendererClass](CHECK_CLASS_CAST(klass, TYPE_CELL_RENDERER()))

proc IS_CELL_RENDERER*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_CELL_RENDERER())

proc IS_CELL_RENDERER_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_CELL_RENDERER())

proc CELL_RENDERER_GET_CLASS*(obj: pointer): PCellRendererClass =
  result = cast[PCellRendererClass](CHECK_GET_CLASS(obj, TYPE_CELL_RENDERER()))

proc mode*(a: PCellRenderer): guint =
  result = (a.CellRendererflag0 and bm_TGtkCellRenderer_mode) shr
      bp_TGtkCellRenderer_mode

proc set_mode*(a: PCellRenderer, `mode`: guint) =
  a.CellRendererflag0 = a.CellRendererflag0 or
      (int16(`mode` shl bp_TGtkCellRenderer_mode) and
      bm_TGtkCellRenderer_mode)

proc visible*(a: PCellRenderer): guint =
  result = (a.CellRendererflag0 and bm_TGtkCellRenderer_visible) shr
      bp_TGtkCellRenderer_visible

proc set_visible*(a: PCellRenderer, `visible`: guint) =
  a.CellRendererflag0 = a.CellRendererflag0 or
      (int16(`visible` shl bp_TGtkCellRenderer_visible) and
      bm_TGtkCellRenderer_visible)

proc is_expander*(a: PCellRenderer): guint =
  result = (a.CellRendererflag0 and bm_TGtkCellRenderer_is_expander) shr
      bp_TGtkCellRenderer_is_expander

proc set_is_expander*(a: PCellRenderer, `is_expander`: guint) =
  a.CellRendererflag0 = a.CellRendererflag0 or
      (int16(`is_expander` shl bp_TGtkCellRenderer_is_expander) and
      bm_TGtkCellRenderer_is_expander)

proc is_expanded*(a: PCellRenderer): guint =
  result = (a.CellRendererflag0 and bm_TGtkCellRenderer_is_expanded) shr
      bp_TGtkCellRenderer_is_expanded

proc set_is_expanded*(a: PCellRenderer, `is_expanded`: guint) =
  a.CellRendererflag0 = a.CellRendererflag0 or
      (int16(`is_expanded` shl bp_TGtkCellRenderer_is_expanded) and
      bm_TGtkCellRenderer_is_expanded)

proc cell_background_set*(a: PCellRenderer): guint =
  result = (a.CellRendererflag0 and bm_TGtkCellRenderer_cell_background_set) shr
      bp_TGtkCellRenderer_cell_background_set

proc set_cell_background_set*(a: PCellRenderer, `cell_background_set`: guint) =
  a.CellRendererflag0 = a.CellRendererflag0 or
      (int16(`cell_background_set` shl
      bp_TGtkCellRenderer_cell_background_set) and
      bm_TGtkCellRenderer_cell_background_set)

proc TYPE_CELL_RENDERER_TEXT*(): GType =
  result = cell_renderer_text_get_type()

proc CELL_RENDERER_TEXT*(obj: pointer): PCellRendererText =
  result = cast[PCellRendererText](CHECK_CAST(obj, TYPE_CELL_RENDERER_TEXT()))

proc CELL_RENDERER_TEXT_CLASS*(klass: pointer): PCellRendererTextClass =
  result = cast[PCellRendererTextClass](CHECK_CLASS_CAST(klass,
      TYPE_CELL_RENDERER_TEXT()))

proc IS_CELL_RENDERER_TEXT*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_CELL_RENDERER_TEXT())

proc IS_CELL_RENDERER_TEXT_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_CELL_RENDERER_TEXT())

proc CELL_RENDERER_TEXT_GET_CLASS*(obj: pointer): PCellRendererTextClass =
  result = cast[PCellRendererTextClass](CHECK_GET_CLASS(obj,
      TYPE_CELL_RENDERER_TEXT()))

proc strikethrough*(a: PCellRendererText): guint =
  result = (a.CellRendererTextflag0 and bm_TGtkCellRendererText_strikethrough) shr
      bp_TGtkCellRendererText_strikethrough

proc set_strikethrough*(a: PCellRendererText, `strikethrough`: guint) =
  a.CellRendererTextflag0 = a.CellRendererTextflag0 or
      (int16(`strikethrough` shl bp_TGtkCellRendererText_strikethrough) and
      bm_TGtkCellRendererText_strikethrough)

proc editable*(a: PCellRendererText): guint =
  result = (a.CellRendererTextflag0 and bm_TGtkCellRendererText_editable) shr
      bp_TGtkCellRendererText_editable

proc set_editable*(a: PCellRendererText, `editable`: guint) =
  a.CellRendererTextflag0 = a.CellRendererTextflag0 or
      (int16(`editable` shl bp_TGtkCellRendererText_editable) and
      bm_TGtkCellRendererText_editable)

proc scale_set*(a: PCellRendererText): guint =
  result = (a.CellRendererTextflag0 and bm_TGtkCellRendererText_scale_set) shr
      bp_TGtkCellRendererText_scale_set

proc set_scale_set*(a: PCellRendererText, `scale_set`: guint) =
  a.CellRendererTextflag0 = a.CellRendererTextflag0 or
      (int16(`scale_set` shl bp_TGtkCellRendererText_scale_set) and
      bm_TGtkCellRendererText_scale_set)

proc foreground_set*(a: PCellRendererText): guint =
  result = (a.CellRendererTextflag0 and
      bm_TGtkCellRendererText_foreground_set) shr
      bp_TGtkCellRendererText_foreground_set

proc set_foreground_set*(a: PCellRendererText, `foreground_set`: guint) =
  a.CellRendererTextflag0 = a.CellRendererTextflag0 or
      (int16(`foreground_set` shl bp_TGtkCellRendererText_foreground_set) and
      bm_TGtkCellRendererText_foreground_set)

proc background_set*(a: PCellRendererText): guint =
  result = (a.CellRendererTextflag0 and
      bm_TGtkCellRendererText_background_set) shr
      bp_TGtkCellRendererText_background_set

proc set_background_set*(a: PCellRendererText, `background_set`: guint) =
  a.CellRendererTextflag0 = a.CellRendererTextflag0 or
      (int16(`background_set` shl bp_TGtkCellRendererText_background_set) and
      bm_TGtkCellRendererText_background_set)

proc underline_set*(a: PCellRendererText): guint =
  result = (a.CellRendererTextflag0 and bm_TGtkCellRendererText_underline_set) shr
      bp_TGtkCellRendererText_underline_set

proc set_underline_set*(a: PCellRendererText, `underline_set`: guint) =
  a.CellRendererTextflag0 = a.CellRendererTextflag0 or
      (int16(`underline_set` shl bp_TGtkCellRendererText_underline_set) and
      bm_TGtkCellRendererText_underline_set)

proc rise_set*(a: PCellRendererText): guint =
  result = (a.CellRendererTextflag0 and bm_TGtkCellRendererText_rise_set) shr
      bp_TGtkCellRendererText_rise_set

proc set_rise_set*(a: PCellRendererText, `rise_set`: guint) =
  a.CellRendererTextflag0 = a.CellRendererTextflag0 or
      (int16(`rise_set` shl bp_TGtkCellRendererText_rise_set) and
      bm_TGtkCellRendererText_rise_set)

proc strikethrough_set*(a: PCellRendererText): guint =
  result = (a.CellRendererTextflag0 and
      bm_TGtkCellRendererText_strikethrough_set) shr
      bp_TGtkCellRendererText_strikethrough_set

proc set_strikethrough_set*(a: PCellRendererText, `strikethrough_set`: guint) =
  a.CellRendererTextflag0 = a.CellRendererTextflag0 or
      (int16(`strikethrough_set` shl
      bp_TGtkCellRendererText_strikethrough_set) and
      bm_TGtkCellRendererText_strikethrough_set)

proc editable_set*(a: PCellRendererText): guint =
  result = (a.CellRendererTextflag0 and bm_TGtkCellRendererText_editable_set) shr
      bp_TGtkCellRendererText_editable_set

proc set_editable_set*(a: PCellRendererText, `editable_set`: guint) =
  a.CellRendererTextflag0 = a.CellRendererTextflag0 or
      (int16(`editable_set` shl bp_TGtkCellRendererText_editable_set) and
      bm_TGtkCellRendererText_editable_set)

proc calc_fixed_height*(a: PCellRendererText): guint =
  result = (a.CellRendererTextflag0 and
      bm_TGtkCellRendererText_calc_fixed_height) shr
      bp_TGtkCellRendererText_calc_fixed_height

proc set_calc_fixed_height*(a: PCellRendererText, `calc_fixed_height`: guint) =
  a.CellRendererTextflag0 = a.CellRendererTextflag0 or
      (int16(`calc_fixed_height` shl
      bp_TGtkCellRendererText_calc_fixed_height) and
      bm_TGtkCellRendererText_calc_fixed_height)

proc TYPE_CELL_RENDERER_TOGGLE*(): GType =
  result = cell_renderer_toggle_get_type()

proc CELL_RENDERER_TOGGLE*(obj: pointer): PCellRendererToggle =
  result = cast[PCellRendererToggle](CHECK_CAST(obj, TYPE_CELL_RENDERER_TOGGLE()))

proc CELL_RENDERER_TOGGLE_CLASS*(klass: pointer): PCellRendererToggleClass =
  result = cast[PCellRendererToggleClass](CHECK_CLASS_CAST(klass,
      TYPE_CELL_RENDERER_TOGGLE()))

proc IS_CELL_RENDERER_TOGGLE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_CELL_RENDERER_TOGGLE())

proc IS_CELL_RENDERER_TOGGLE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_CELL_RENDERER_TOGGLE())

proc CELL_RENDERER_TOGGLE_GET_CLASS*(obj: pointer): PCellRendererToggleClass =
  result = cast[PCellRendererToggleClass](CHECK_GET_CLASS(obj,
      TYPE_CELL_RENDERER_TOGGLE()))

proc active*(a: PCellRendererToggle): guint =
  result = (a.CellRendererToggleflag0 and bm_TGtkCellRendererToggle_active) shr
      bp_TGtkCellRendererToggle_active

proc set_active*(a: PCellRendererToggle, `active`: guint) =
  a.CellRendererToggleflag0 = a.CellRendererToggleflag0 or
      (int16(`active` shl bp_TGtkCellRendererToggle_active) and
      bm_TGtkCellRendererToggle_active)

proc activatable*(a: PCellRendererToggle): guint =
  result = (a.CellRendererToggleflag0 and
      bm_TGtkCellRendererToggle_activatable) shr
      bp_TGtkCellRendererToggle_activatable

proc set_activatable*(a: PCellRendererToggle, `activatable`: guint) =
  a.CellRendererToggleflag0 = a.CellRendererToggleflag0 or
      (int16(`activatable` shl bp_TGtkCellRendererToggle_activatable) and
      bm_TGtkCellRendererToggle_activatable)

proc radio*(a: PCellRendererToggle): guint =
  result = (a.CellRendererToggleflag0 and bm_TGtkCellRendererToggle_radio) shr
      bp_TGtkCellRendererToggle_radio

proc set_radio*(a: PCellRendererToggle, `radio`: guint) =
  a.CellRendererToggleflag0 = a.CellRendererToggleflag0 or
      (int16(`radio` shl bp_TGtkCellRendererToggle_radio) and
      bm_TGtkCellRendererToggle_radio)

proc TYPE_CELL_RENDERER_PIXBUF*(): GType =
  result = cell_renderer_pixbuf_get_type()

proc CELL_RENDERER_PIXBUF*(obj: pointer): PCellRendererPixbuf =
  result = cast[PCellRendererPixbuf](CHECK_CAST(obj, TYPE_CELL_RENDERER_PIXBUF()))

proc CELL_RENDERER_PIXBUF_CLASS*(klass: pointer): PCellRendererPixbufClass =
  result = cast[PCellRendererPixbufClass](CHECK_CLASS_CAST(klass,
      TYPE_CELL_RENDERER_PIXBUF()))

proc IS_CELL_RENDERER_PIXBUF*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_CELL_RENDERER_PIXBUF())

proc IS_CELL_RENDERER_PIXBUF_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_CELL_RENDERER_PIXBUF())

proc CELL_RENDERER_PIXBUF_GET_CLASS*(obj: pointer): PCellRendererPixbufClass =
  result = cast[PCellRendererPixbufClass](CHECK_GET_CLASS(obj,
      TYPE_CELL_RENDERER_PIXBUF()))

proc TYPE_ITEM*(): GType =
  result = item_get_type()

proc ITEM*(obj: pointer): PItem =
  result = cast[PItem](CHECK_CAST(obj, TYPE_ITEM()))

proc ITEM_CLASS*(klass: pointer): PItemClass =
  result = cast[PItemClass](CHECK_CLASS_CAST(klass, TYPE_ITEM()))

proc IS_ITEM*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_ITEM())

proc IS_ITEM_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_ITEM())

proc ITEM_GET_CLASS*(obj: pointer): PItemClass =
  result = cast[PItemClass](CHECK_GET_CLASS(obj, TYPE_ITEM()))

proc TYPE_MENU_ITEM*(): GType =
  result = menu_item_get_type()

proc MENU_ITEM*(obj: pointer): PMenuItem =
  result = cast[PMenuItem](CHECK_CAST(obj, TYPE_MENU_ITEM()))

proc MENU_ITEM_CLASS*(klass: pointer): PMenuItemClass =
  result = cast[PMenuItemClass](CHECK_CLASS_CAST(klass, TYPE_MENU_ITEM()))

proc IS_MENU_ITEM*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_MENU_ITEM())

proc IS_MENU_ITEM_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_MENU_ITEM())

proc MENU_ITEM_GET_CLASS*(obj: pointer): PMenuItemClass =
  result = cast[PMenuItemClass](CHECK_GET_CLASS(obj, TYPE_MENU_ITEM()))

proc show_submenu_indicator*(a: PMenuItem): guint =
  result = (a.MenuItemflag0 and bm_TGtkMenuItem_show_submenu_indicator) shr
      bp_TGtkMenuItem_show_submenu_indicator

proc set_show_submenu_indicator*(a: PMenuItem,
                                 `show_submenu_indicator`: guint) =
  a.MenuItemflag0 = a.MenuItemflag0 or
      (int16(`show_submenu_indicator` shl
      bp_TGtkMenuItem_show_submenu_indicator) and
      bm_TGtkMenuItem_show_submenu_indicator)

proc submenu_placement*(a: PMenuItem): guint =
  result = (a.MenuItemflag0 and bm_TGtkMenuItem_submenu_placement) shr
      bp_TGtkMenuItem_submenu_placement

proc set_submenu_placement*(a: PMenuItem, `submenu_placement`: guint) =
  a.MenuItemflag0 = a.MenuItemflag0 or
      (int16(`submenu_placement` shl bp_TGtkMenuItem_submenu_placement) and
      bm_TGtkMenuItem_submenu_placement)

proc submenu_direction*(a: PMenuItem): guint =
  result = (a.MenuItemflag0 and bm_TGtkMenuItem_submenu_direction) shr
      bp_TGtkMenuItem_submenu_direction

proc set_submenu_direction*(a: PMenuItem, `submenu_direction`: guint) =
  a.MenuItemflag0 = a.MenuItemflag0 or
      (int16(`submenu_direction` shl bp_TGtkMenuItem_submenu_direction) and
      bm_TGtkMenuItem_submenu_direction)

proc right_justify*(a: PMenuItem): guint =
  result = (a.MenuItemflag0 and bm_TGtkMenuItem_right_justify) shr
      bp_TGtkMenuItem_right_justify

proc set_right_justify*(a: PMenuItem, `right_justify`: guint) =
  a.MenuItemflag0 = a.MenuItemflag0 or
      (int16(`right_justify` shl bp_TGtkMenuItem_right_justify) and
      bm_TGtkMenuItem_right_justify)

proc timer_from_keypress*(a: PMenuItem): guint =
  result = (a.MenuItemflag0 and bm_TGtkMenuItem_timer_from_keypress) shr
      bp_TGtkMenuItem_timer_from_keypress

proc set_timer_from_keypress*(a: PMenuItem, `timer_from_keypress`: guint) =
  a.MenuItemflag0 = a.MenuItemflag0 or
      (int16(`timer_from_keypress` shl bp_TGtkMenuItem_timer_from_keypress) and
      bm_TGtkMenuItem_timer_from_keypress)

proc hide_on_activate*(a: PMenuItemClass): guint =
  result = (a.MenuItemClassflag0 and bm_TGtkMenuItemClass_hide_on_activate) shr
      bp_TGtkMenuItemClass_hide_on_activate

proc set_hide_on_activate*(a: PMenuItemClass, `hide_on_activate`: guint) =
  a.MenuItemClassflag0 = a.MenuItemClassflag0 or
      (int16(`hide_on_activate` shl bp_TGtkMenuItemClass_hide_on_activate) and
      bm_TGtkMenuItemClass_hide_on_activate)

proc right_justify*(menu_item: PMenuItem) =
  set_right_justified(menu_item, system.true)

proc TYPE_TOGGLE_BUTTON*(): GType =
  result = toggle_button_get_type()

proc TOGGLE_BUTTON*(obj: pointer): PToggleButton =
  result = cast[PToggleButton](CHECK_CAST(obj, TYPE_TOGGLE_BUTTON()))

proc TOGGLE_BUTTON_CLASS*(klass: pointer): PToggleButtonClass =
  result = cast[PToggleButtonClass](CHECK_CLASS_CAST(klass, TYPE_TOGGLE_BUTTON()))

proc IS_TOGGLE_BUTTON*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TOGGLE_BUTTON())

proc IS_TOGGLE_BUTTON_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TOGGLE_BUTTON())

proc TOGGLE_BUTTON_GET_CLASS*(obj: pointer): PToggleButtonClass =
  result = cast[PToggleButtonClass](CHECK_GET_CLASS(obj, TYPE_TOGGLE_BUTTON()))

proc active*(a: PToggleButton): guint =
  result = (a.ToggleButtonflag0 and bm_TGtkToggleButton_active) shr
      bp_TGtkToggleButton_active

proc set_active*(a: PToggleButton, `active`: guint) =
  a.ToggleButtonflag0 = a.ToggleButtonflag0 or
      (int16(`active` shl bp_TGtkToggleButton_active) and
      bm_TGtkToggleButton_active)

proc draw_indicator*(a: PToggleButton): guint =
  result = (a.ToggleButtonflag0 and bm_TGtkToggleButton_draw_indicator) shr
      bp_TGtkToggleButton_draw_indicator

proc set_draw_indicator*(a: PToggleButton, `draw_indicator`: guint) =
  a.ToggleButtonflag0 = a.ToggleButtonflag0 or
      (int16(`draw_indicator` shl bp_TGtkToggleButton_draw_indicator) and
      bm_TGtkToggleButton_draw_indicator)

proc inconsistent*(a: PToggleButton): guint =
  result = (a.ToggleButtonflag0 and bm_TGtkToggleButton_inconsistent) shr
      bp_TGtkToggleButton_inconsistent

proc set_inconsistent*(a: PToggleButton, `inconsistent`: guint) =
  a.ToggleButtonflag0 = a.ToggleButtonflag0 or
      (int16(`inconsistent` shl bp_TGtkToggleButton_inconsistent) and
      bm_TGtkToggleButton_inconsistent)

proc TYPE_CHECK_BUTTON*(): GType =
  result = check_button_get_type()

proc CHECK_BUTTON*(obj: pointer): PCheckButton =
  result = cast[PCheckButton](CHECK_CAST(obj, TYPE_CHECK_BUTTON()))

proc CHECK_BUTTON_CLASS*(klass: pointer): PCheckButtonClass =
  result = cast[PCheckButtonClass](CHECK_CLASS_CAST(klass, TYPE_CHECK_BUTTON()))

proc IS_CHECK_BUTTON*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_CHECK_BUTTON())

proc IS_CHECK_BUTTON_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_CHECK_BUTTON())

proc CHECK_BUTTON_GET_CLASS*(obj: pointer): PCheckButtonClass =
  result = cast[PCheckButtonClass](CHECK_GET_CLASS(obj, TYPE_CHECK_BUTTON()))

proc TYPE_CHECK_MENU_ITEM*(): GType =
  result = check_menu_item_get_type()

proc CHECK_MENU_ITEM*(obj: pointer): PCheckMenuItem =
  result = cast[PCheckMenuItem](CHECK_CAST(obj, TYPE_CHECK_MENU_ITEM()))

proc CHECK_MENU_ITEM_CLASS*(klass: pointer): PCheckMenuItemClass =
  result = cast[PCheckMenuItemClass](CHECK_CLASS_CAST(klass,
      TYPE_CHECK_MENU_ITEM()))

proc IS_CHECK_MENU_ITEM*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_CHECK_MENU_ITEM())

proc IS_CHECK_MENU_ITEM_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_CHECK_MENU_ITEM())

proc CHECK_MENU_ITEM_GET_CLASS*(obj: pointer): PCheckMenuItemClass =
  result = cast[PCheckMenuItemClass](CHECK_GET_CLASS(obj, TYPE_CHECK_MENU_ITEM()))

proc active*(a: PCheckMenuItem): guint =
  result = (a.CheckMenuItemflag0 and bm_TGtkCheckMenuItem_active) shr
      bp_TGtkCheckMenuItem_active

proc set_active*(a: PCheckMenuItem, `active`: guint) =
  a.CheckMenuItemflag0 = a.CheckMenuItemflag0 or
      (int16(`active` shl bp_TGtkCheckMenuItem_active) and
      bm_TGtkCheckMenuItem_active)

proc always_show_toggle*(a: PCheckMenuItem): guint =
  result = (a.CheckMenuItemflag0 and bm_TGtkCheckMenuItem_always_show_toggle) shr
      bp_TGtkCheckMenuItem_always_show_toggle

proc set_always_show_toggle*(a: PCheckMenuItem, `always_show_toggle`: guint) =
  a.CheckMenuItemflag0 = a.CheckMenuItemflag0 or
      (int16(`always_show_toggle` shl bp_TGtkCheckMenuItem_always_show_toggle) and
      bm_TGtkCheckMenuItem_always_show_toggle)

proc inconsistent*(a: PCheckMenuItem): guint =
  result = (a.CheckMenuItemflag0 and bm_TGtkCheckMenuItem_inconsistent) shr
      bp_TGtkCheckMenuItem_inconsistent

proc set_inconsistent*(a: PCheckMenuItem, `inconsistent`: guint) =
  a.CheckMenuItemflag0 = a.CheckMenuItemflag0 or
      (int16(`inconsistent` shl bp_TGtkCheckMenuItem_inconsistent) and
      bm_TGtkCheckMenuItem_inconsistent)

proc TYPE_CLIST*(): GType =
  result = clist_get_type()

proc CLIST*(obj: pointer): PCList =
  result = cast[PCList](CHECK_CAST(obj, TYPE_CLIST()))

proc CLIST_CLASS*(klass: pointer): PCListClass =
  result = cast[PCListClass](CHECK_CLASS_CAST(klass, TYPE_CLIST()))

proc IS_CLIST*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_CLIST())

proc IS_CLIST_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_CLIST())

proc CLIST_GET_CLASS*(obj: pointer): PCListClass =
  result = cast[PCListClass](CHECK_GET_CLASS(obj, TYPE_CLIST()))

proc CLIST_FLAGS*(clist: pointer): guint16 =
  result = toU16(CLIST(clist).flags)

proc SET_FLAG*(clist: PCList, flag: guint16) =
  clist.flags = CLIST(clist).flags or (flag)

proc UNSET_FLAG*(clist: PCList, flag: guint16) =
  clist.flags = CLIST(clist).flags and not (flag)

proc CLIST_IN_DRAG_get*(clist: pointer): bool =
  result = ((CLIST_FLAGS(clist)) and cint(CLIST_IN_DRAG)) != 0'i32

proc CLIST_ROW_HEIGHT_SET_get*(clist: pointer): bool =
  result = ((CLIST_FLAGS(clist)) and cint(CLIST_ROW_HEIGHT_SET)) != 0'i32

proc CLIST_SHOW_TITLES_get*(clist: pointer): bool =
  result = ((CLIST_FLAGS(clist)) and cint(CLIST_SHOW_TITLES)) != 0'i32

proc CLIST_ADD_MODE_get*(clist: pointer): bool =
  result = ((CLIST_FLAGS(clist)) and cint(CLIST_ADD_MODE)) != 0'i32

proc CLIST_AUTO_SORT_get*(clist: pointer): bool =
  result = ((CLIST_FLAGS(clist)) and cint(CLIST_AUTO_SORT)) != 0'i32

proc CLIST_AUTO_RESIZE_BLOCKED_get*(clist: pointer): bool =
  result = ((CLIST_FLAGS(clist)) and cint(CLIST_AUTO_RESIZE_BLOCKED)) != 0'i32

proc CLIST_REORDERABLE_get*(clist: pointer): bool =
  result = ((CLIST_FLAGS(clist)) and cint(CLIST_REORDERABLE)) != 0'i32

proc CLIST_USE_DRAG_ICONS_get*(clist: pointer): bool =
  result = ((CLIST_FLAGS(clist)) and cint(CLIST_USE_DRAG_ICONS)) != 0'i32

proc CLIST_DRAW_DRAG_LINE_get*(clist: pointer): bool =
  result = ((CLIST_FLAGS(clist)) and cint(CLIST_DRAW_DRAG_LINE)) != 0'i32

proc CLIST_DRAW_DRAG_RECT_get*(clist: pointer): bool =
  result = ((CLIST_FLAGS(clist)) and cint(CLIST_DRAW_DRAG_RECT)) != 0'i32

proc CLIST_ROW_get*(glist: PGList): PCListRow =
  result = cast[PCListRow](glist.data)

when false:
  proc CELL_TEXT_get*(cell: pointer): PCellText =
    result = cast[PCellText](addr((cell)))

  proc CELL_PIXMAP_get*(cell: pointer): PCellPixmap =
    result = cast[PCellPixmap](addr((cell)))

  proc CELL_PIXTEXT_get*(cell: pointer): PCellPixText =
    result = cast[PCellPixText](addr((cell)))

  proc CELL_WIDGET_get*(cell: pointer): PCellWidget =
    result = cast[PCellWidget](addr((cell)))

proc visible*(a: PCListColumn): guint =
  result = (a.flag0 and bm_TGtkCListColumn_visible) shr
      bp_TGtkCListColumn_visible

proc set_visible*(a: PCListColumn, `visible`: guint) =
  a.flag0 = a.flag0 or
      (int16(`visible` shl bp_TGtkCListColumn_visible) and
      bm_TGtkCListColumn_visible)

proc width_set*(a: PCListColumn): guint =
  result = (a.flag0 and bm_TGtkCListColumn_width_set) shr
      bp_TGtkCListColumn_width_set

proc set_width_set*(a: PCListColumn, `width_set`: guint) =
  a.flag0 = a.flag0 or
      (int16(`width_set` shl bp_TGtkCListColumn_width_set) and
      bm_TGtkCListColumn_width_set)

proc resizeable*(a: PCListColumn): guint =
  result = (a.flag0 and bm_TGtkCListColumn_resizeable) shr
      bp_TGtkCListColumn_resizeable

proc set_resizeable*(a: PCListColumn, `resizeable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`resizeable` shl bp_TGtkCListColumn_resizeable) and
      bm_TGtkCListColumn_resizeable)

proc auto_resize*(a: PCListColumn): guint =
  result = (a.flag0 and bm_TGtkCListColumn_auto_resize) shr
      bp_TGtkCListColumn_auto_resize

proc set_auto_resize*(a: PCListColumn, `auto_resize`: guint) =
  a.flag0 = a.flag0 or
      (int16(`auto_resize` shl bp_TGtkCListColumn_auto_resize) and
      bm_TGtkCListColumn_auto_resize)

proc button_passive*(a: PCListColumn): guint =
  result = (a.flag0 and bm_TGtkCListColumn_button_passive) shr
      bp_TGtkCListColumn_button_passive

proc set_button_passive*(a: PCListColumn, `button_passive`: guint) =
  a.flag0 = a.flag0 or
      (int16(`button_passive` shl bp_TGtkCListColumn_button_passive) and
      bm_TGtkCListColumn_button_passive)

proc fg_set*(a: PCListRow): guint =
  result = (a.flag0 and bm_TGtkCListRow_fg_set) shr bp_TGtkCListRow_fg_set

proc set_fg_set*(a: PCListRow, `fg_set`: guint) =
  a.flag0 = a.flag0 or
      (int16(`fg_set` shl bp_TGtkCListRow_fg_set) and bm_TGtkCListRow_fg_set)

proc bg_set*(a: PCListRow): guint =
  result = (a.flag0 and bm_TGtkCListRow_bg_set) shr bp_TGtkCListRow_bg_set

proc set_bg_set*(a: PCListRow, `bg_set`: guint) =
  a.flag0 = a.flag0 or
      (int16(`bg_set` shl bp_TGtkCListRow_bg_set) and bm_TGtkCListRow_bg_set)

proc selectable*(a: PCListRow): guint =
  result = (a.flag0 and bm_TGtkCListRow_selectable) shr
      bp_TGtkCListRow_selectable

proc set_selectable*(a: PCListRow, `selectable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`selectable` shl bp_TGtkCListRow_selectable) and
      bm_TGtkCListRow_selectable)

proc TYPE_DIALOG*(): GType =
  result = dialog_get_type()

proc DIALOG*(obj: pointer): PDialog =
  result = cast[PDialog](CHECK_CAST(obj, TYPE_DIALOG()))

proc DIALOG_CLASS*(klass: pointer): PDialogClass =
  result = cast[PDialogClass](CHECK_CLASS_CAST(klass, TYPE_DIALOG()))

proc IS_DIALOG*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_DIALOG())

proc IS_DIALOG_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_DIALOG())

proc DIALOG_GET_CLASS*(obj: pointer): PDialogClass =
  result = cast[PDialogClass](CHECK_GET_CLASS(obj, TYPE_DIALOG()))

proc TYPE_VBOX*(): GType =
  result = vbox_get_type()

proc VBOX*(obj: pointer): PVBox =
  result = cast[PVBox](CHECK_CAST(obj, TYPE_VBOX()))

proc VBOX_CLASS*(klass: pointer): PVBoxClass =
  result = cast[PVBoxClass](CHECK_CLASS_CAST(klass, TYPE_VBOX()))

proc IS_VBOX*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_VBOX())

proc IS_VBOX_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_VBOX())

proc VBOX_GET_CLASS*(obj: pointer): PVBoxClass =
  result = cast[PVBoxClass](CHECK_GET_CLASS(obj, TYPE_VBOX()))

proc TYPE_COLOR_SELECTION*(): GType =
  result = color_selection_get_type()

proc COLOR_SELECTION*(obj: pointer): PColorSelection =
  result = cast[PColorSelection](CHECK_CAST(obj, TYPE_COLOR_SELECTION()))

proc COLOR_SELECTION_CLASS*(klass: pointer): PColorSelectionClass =
  result = cast[PColorSelectionClass](CHECK_CLASS_CAST(klass,
      TYPE_COLOR_SELECTION()))

proc IS_COLOR_SELECTION*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_COLOR_SELECTION())

proc IS_COLOR_SELECTION_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_COLOR_SELECTION())

proc COLOR_SELECTION_GET_CLASS*(obj: pointer): PColorSelectionClass =
  result = cast[PColorSelectionClass](CHECK_GET_CLASS(obj,
      TYPE_COLOR_SELECTION()))

proc TYPE_COLOR_SELECTION_DIALOG*(): GType =
  result = color_selection_dialog_get_type()

proc COLOR_SELECTION_DIALOG*(obj: pointer): PColorSelectionDialog =
  result = cast[PColorSelectionDialog](CHECK_CAST(obj,
      TYPE_COLOR_SELECTION_DIALOG()))

proc COLOR_SELECTION_DIALOG_CLASS*(klass: pointer): PColorSelectionDialogClass =
  result = cast[PColorSelectionDialogClass](CHECK_CLASS_CAST(klass,
      TYPE_COLOR_SELECTION_DIALOG()))

proc IS_COLOR_SELECTION_DIALOG*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_COLOR_SELECTION_DIALOG())

proc IS_COLOR_SELECTION_DIALOG_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_COLOR_SELECTION_DIALOG())

proc COLOR_SELECTION_DIALOG_GET_CLASS*(obj: pointer): PColorSelectionDialogClass =
  result = cast[PColorSelectionDialogClass](CHECK_GET_CLASS(obj,
      TYPE_COLOR_SELECTION_DIALOG()))

proc TYPE_HBOX*(): GType =
  result = hbox_get_type()

proc HBOX*(obj: pointer): PHBox =
  result = cast[PHBox](CHECK_CAST(obj, TYPE_HBOX()))

proc HBOX_CLASS*(klass: pointer): PHBoxClass =
  result = cast[PHBoxClass](CHECK_CLASS_CAST(klass, TYPE_HBOX()))

proc IS_HBOX*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_HBOX())

proc IS_HBOX_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_HBOX())

proc HBOX_GET_CLASS*(obj: pointer): PHBoxClass =
  result = cast[PHBoxClass](CHECK_GET_CLASS(obj, TYPE_HBOX()))

proc TYPE_COMBO*(): GType =
  result = combo_get_type()

proc COMBO*(obj: pointer): PCombo =
  result = cast[PCombo](CHECK_CAST(obj, TYPE_COMBO()))

proc COMBO_CLASS*(klass: pointer): PComboClass =
  result = cast[PComboClass](CHECK_CLASS_CAST(klass, TYPE_COMBO()))

proc IS_COMBO*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_COMBO())

proc IS_COMBO_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_COMBO())

proc COMBO_GET_CLASS*(obj: pointer): PComboClass =
  result = cast[PComboClass](CHECK_GET_CLASS(obj, TYPE_COMBO()))

proc value_in_list*(a: PCombo): guint =
  result = (a.Comboflag0 and bm_TGtkCombo_value_in_list) shr
      bp_TGtkCombo_value_in_list

proc set_value_in_list*(a: PCombo, `value_in_list`: guint) =
  a.Comboflag0 = a.Comboflag0 or
      (int16(`value_in_list` shl bp_TGtkCombo_value_in_list) and
      bm_TGtkCombo_value_in_list)

proc ok_if_empty*(a: PCombo): guint =
  result = (a.Comboflag0 and bm_TGtkCombo_ok_if_empty) shr
      bp_TGtkCombo_ok_if_empty

proc set_ok_if_empty*(a: PCombo, `ok_if_empty`: guint) =
  a.Comboflag0 = a.Comboflag0 or
      (int16(`ok_if_empty` shl bp_TGtkCombo_ok_if_empty) and
      bm_TGtkCombo_ok_if_empty)

proc case_sensitive*(a: PCombo): guint =
  result = (a.Comboflag0 and bm_TGtkCombo_case_sensitive) shr
      bp_TGtkCombo_case_sensitive

proc set_case_sensitive*(a: PCombo, `case_sensitive`: guint) =
  a.Comboflag0 = a.Comboflag0 or
      (int16(`case_sensitive` shl bp_TGtkCombo_case_sensitive) and
      bm_TGtkCombo_case_sensitive)

proc use_arrows*(a: PCombo): guint =
  result = (a.Comboflag0 and bm_TGtkCombo_use_arrows) shr
      bp_TGtkCombo_use_arrows

proc set_use_arrows*(a: PCombo, `use_arrows`: guint) =
  a.Comboflag0 = a.Comboflag0 or
      (int16(`use_arrows` shl bp_TGtkCombo_use_arrows) and
      bm_TGtkCombo_use_arrows)

proc use_arrows_always*(a: PCombo): guint =
  result = (a.Comboflag0 and bm_TGtkCombo_use_arrows_always) shr
      bp_TGtkCombo_use_arrows_always

proc set_use_arrows_always*(a: PCombo, `use_arrows_always`: guint) =
  a.Comboflag0 = a.Comboflag0 or
      (int16(`use_arrows_always` shl bp_TGtkCombo_use_arrows_always) and
      bm_TGtkCombo_use_arrows_always)

proc TYPE_CTREE*(): GType =
  result = ctree_get_type()

proc CTREE*(obj: pointer): PCTree =
  result = cast[PCTree](CHECK_CAST(obj, TYPE_CTREE()))

proc CTREE_CLASS*(klass: pointer): PCTreeClass =
  result = cast[PCTreeClass](CHECK_CLASS_CAST(klass, TYPE_CTREE()))

proc IS_CTREE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_CTREE())

proc IS_CTREE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_CTREE())

proc CTREE_GET_CLASS*(obj: pointer): PCTreeClass =
  result = cast[PCTreeClass](CHECK_GET_CLASS(obj, TYPE_CTREE()))

proc CTREE_ROW*(node: TAddress): PCTreeRow =
  result = cast[PCTreeRow]((cast[PGList](node)).data)

proc CTREE_NODE*(node: TAddress): PCTreeNode =
  result = cast[PCTreeNode](node)

proc CTREE_NODE_NEXT*(nnode: TAddress): PCTreeNode =
  result = cast[PCTreeNode]((cast[PGList](nnode)).next)

proc CTREE_NODE_PREV*(pnode: TAddress): PCTreeNode =
  result = cast[PCTreeNode]((cast[PGList](pnode)).prev)

proc CTREE_FUNC*(fun: TAddress): TCTreeFunc =
  result = cast[TCTreeFunc](fun)

proc TYPE_CTREE_NODE*(): GType =
  result = ctree_node_get_type()

proc line_style*(a: PCTree): guint =
  result = (a.CTreeflag0 and bm_TGtkCTree_line_style) shr
      bp_TGtkCTree_line_style

proc set_line_style*(a: PCTree, `line_style`: guint) =
  a.CTreeflag0 = a.CTreeflag0 or
      (int16(`line_style` shl bp_TGtkCTree_line_style) and
      bm_TGtkCTree_line_style)

proc expander_style*(a: PCTree): guint =
  result = (a.CTreeflag0 and bm_TGtkCTree_expander_style) shr
      bp_TGtkCTree_expander_style

proc set_expander_style*(a: PCTree, `expander_style`: guint) =
  a.CTreeflag0 = a.CTreeflag0 or
      (int16(`expander_style` shl bp_TGtkCTree_expander_style) and
      bm_TGtkCTree_expander_style)

proc show_stub*(a: PCTree): guint =
  result = (a.CTreeflag0 and bm_TGtkCTree_show_stub) shr
      bp_TGtkCTree_show_stub

proc set_show_stub*(a: PCTree, `show_stub`: guint) =
  a.CTreeflag0 = a.CTreeflag0 or
      (int16(`show_stub` shl bp_TGtkCTree_show_stub) and
      bm_TGtkCTree_show_stub)

proc is_leaf*(a: PCTreeRow): guint =
  result = (a.CTreeRow_flag0 and bm_TGtkCTreeRow_is_leaf) shr
      bp_TGtkCTreeRow_is_leaf

proc set_is_leaf*(a: PCTreeRow, `is_leaf`: guint) =
  a.CTreeRow_flag0 = a.CTreeRow_flag0 or
      (int16(`is_leaf` shl bp_TGtkCTreeRow_is_leaf) and
      bm_TGtkCTreeRow_is_leaf)

proc expanded*(a: PCTreeRow): guint =
  result = (a.CTreeRow_flag0 and bm_TGtkCTreeRow_expanded) shr
      bp_TGtkCTreeRow_expanded

proc set_expanded*(a: PCTreeRow, `expanded`: guint) =
  a.CTreeRow_flag0 = a.CTreeRowflag0 or
      (int16(`expanded` shl bp_TGtkCTreeRow_expanded) and
      bm_TGtkCTreeRow_expanded)

proc ctree_set_reorderable*(t: pointer, r: bool) =
  set_reorderable(cast[PCList](t), r)

proc TYPE_DRAWING_AREA*(): GType =
  result = drawing_area_get_type()

proc DRAWING_AREA*(obj: pointer): PDrawingArea =
  result = cast[PDrawingArea](CHECK_CAST(obj, TYPE_DRAWING_AREA()))

proc DRAWING_AREA_CLASS*(klass: pointer): PDrawingAreaClass =
  result = cast[PDrawingAreaClass](CHECK_CLASS_CAST(klass, TYPE_DRAWING_AREA()))

proc IS_DRAWING_AREA*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_DRAWING_AREA())

proc IS_DRAWING_AREA_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_DRAWING_AREA())

proc DRAWING_AREA_GET_CLASS*(obj: pointer): PDrawingAreaClass =
  result = cast[PDrawingAreaClass](CHECK_GET_CLASS(obj, TYPE_DRAWING_AREA()))

proc TYPE_CURVE*(): GType =
  result = curve_get_type()

proc CURVE*(obj: pointer): PCurve =
  result = cast[PCurve](CHECK_CAST(obj, TYPE_CURVE()))

proc CURVE_CLASS*(klass: pointer): PCurveClass =
  result = cast[PCurveClass](CHECK_CLASS_CAST(klass, TYPE_CURVE()))

proc IS_CURVE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_CURVE())

proc IS_CURVE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_CURVE())

proc CURVE_GET_CLASS*(obj: pointer): PCurveClass =
  result = cast[PCurveClass](CHECK_GET_CLASS(obj, TYPE_CURVE()))

proc TYPE_EDITABLE*(): GType =
  result = editable_get_type()

proc EDITABLE*(obj: pointer): PEditable =
  result = cast[PEditable](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_EDITABLE()))

proc EDITABLE_CLASS*(vtable: pointer): PEditableClass =
  result = cast[PEditableClass](G_TYPE_CHECK_CLASS_CAST(vtable, TYPE_EDITABLE()))

proc IS_EDITABLE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_EDITABLE())

proc IS_EDITABLE_CLASS*(vtable: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(vtable, TYPE_EDITABLE())

proc EDITABLE_GET_CLASS*(inst: pointer): PEditableClass =
  result = cast[PEditableClass](G_TYPE_INSTANCE_GET_INTERFACE(inst,
      TYPE_EDITABLE()))

proc TYPE_IM_CONTEXT*(): GType =
  result = im_context_get_type()

proc IM_CONTEXT*(obj: pointer): PIMContext =
  result = cast[PIMContext](CHECK_CAST(obj, TYPE_IM_CONTEXT()))

proc IM_CONTEXT_CLASS*(klass: pointer): PIMContextClass =
  result = cast[PIMContextClass](CHECK_CLASS_CAST(klass, TYPE_IM_CONTEXT()))

proc IS_IM_CONTEXT*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_IM_CONTEXT())

proc IS_IM_CONTEXT_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_IM_CONTEXT())

proc IM_CONTEXT_GET_CLASS*(obj: pointer): PIMContextClass =
  result = cast[PIMContextClass](CHECK_GET_CLASS(obj, TYPE_IM_CONTEXT()))

proc TYPE_MENU_SHELL*(): GType =
  result = menu_shell_get_type()

proc MENU_SHELL*(obj: pointer): PMenuShell =
  result = cast[PMenuShell](CHECK_CAST(obj, TYPE_MENU_SHELL()))

proc MENU_SHELL_CLASS*(klass: pointer): PMenuShellClass =
  result = cast[PMenuShellClass](CHECK_CLASS_CAST(klass, TYPE_MENU_SHELL()))

proc IS_MENU_SHELL*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_MENU_SHELL())

proc IS_MENU_SHELL_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_MENU_SHELL())

proc MENU_SHELL_GET_CLASS*(obj: pointer): PMenuShellClass =
  result = cast[PMenuShellClass](CHECK_GET_CLASS(obj, TYPE_MENU_SHELL()))

proc active*(a: PMenuShell): guint =
  result = (a.MenuShellflag0 and bm_TGtkMenuShell_active) shr
      bp_TGtkMenuShell_active

proc set_active*(a: PMenuShell, `active`: guint) =
  a.MenuShellflag0 = a.MenuShellflag0 or
      (int16(`active` shl bp_TGtkMenuShell_active) and
      bm_TGtkMenuShell_active)

proc have_grab*(a: PMenuShell): guint =
  result = (a.MenuShellflag0 and bm_TGtkMenuShell_have_grab) shr
      bp_TGtkMenuShell_have_grab

proc set_have_grab*(a: PMenuShell, `have_grab`: guint) =
  a.MenuShellflag0 = a.MenuShellflag0 or
      (int16(`have_grab` shl bp_TGtkMenuShell_have_grab) and
      bm_TGtkMenuShell_have_grab)

proc have_xgrab*(a: PMenuShell): guint =
  result = (a.MenuShellflag0 and bm_TGtkMenuShell_have_xgrab) shr
      bp_TGtkMenuShell_have_xgrab

proc set_have_xgrab*(a: PMenuShell, `have_xgrab`: guint) =
  a.MenuShellflag0 = a.MenuShellflag0 or
      (int16(`have_xgrab` shl bp_TGtkMenuShell_have_xgrab) and
      bm_TGtkMenuShell_have_xgrab)

proc ignore_leave*(a: PMenuShell): guint =
  result = (a.MenuShellflag0 and bm_TGtkMenuShell_ignore_leave) shr
      bp_TGtkMenuShell_ignore_leave

proc set_ignore_leave*(a: PMenuShell, `ignore_leave`: guint) =
  a.MenuShellflag0 = a.MenuShellflag0 or
      (int16(`ignore_leave` shl bp_TGtkMenuShell_ignore_leave) and
      bm_TGtkMenuShell_ignore_leave)

proc menu_flag*(a: PMenuShell): guint =
  result = (a.MenuShellflag0 and bm_TGtkMenuShell_menu_flag) shr
      bp_TGtkMenuShell_menu_flag

proc set_menu_flag*(a: PMenuShell, `menu_flag`: guint) =
  a.MenuShellflag0 = a.MenuShellflag0 or
      (int16(`menu_flag` shl bp_TGtkMenuShell_menu_flag) and
      bm_TGtkMenuShell_menu_flag)

proc ignore_enter*(a: PMenuShell): guint =
  result = (a.MenuShellflag0 and bm_TGtkMenuShell_ignore_enter) shr
      bp_TGtkMenuShell_ignore_enter

proc set_ignore_enter*(a: PMenuShell, `ignore_enter`: guint) =
  a.MenuShellflag0 = a.MenuShellflag0 or
      (int16(`ignore_enter` shl bp_TGtkMenuShell_ignore_enter) and
      bm_TGtkMenuShell_ignore_enter)

proc submenu_placement*(a: PMenuShellClass): guint =
  result = (a.MenuShellClassflag0 and bm_TGtkMenuShellClass_submenu_placement) shr
      bp_TGtkMenuShellClass_submenu_placement

proc set_submenu_placement*(a: PMenuShellClass, `submenu_placement`: guint) =
  a.MenuShellClassflag0 = a.MenuShellClassflag0 or
      (int16(`submenu_placement` shl bp_TGtkMenuShellClass_submenu_placement) and
      bm_TGtkMenuShellClass_submenu_placement)

proc TYPE_MENU*(): GType =
  result = menu_get_type()

proc MENU*(obj: pointer): PMenu =
  result = cast[PMenu](CHECK_CAST(obj, TYPE_MENU()))

proc MENU_CLASS*(klass: pointer): PMenuClass =
  result = cast[PMenuClass](CHECK_CLASS_CAST(klass, TYPE_MENU()))

proc IS_MENU*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_MENU())

proc IS_MENU_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_MENU())

proc MENU_GET_CLASS*(obj: pointer): PMenuClass =
  result = cast[PMenuClass](CHECK_GET_CLASS(obj, TYPE_MENU()))

proc needs_destruction_ref_count*(a: PMenu): guint =
  result = (a.Menuflag0 and bm_TGtkMenu_needs_destruction_ref_count) shr
      bp_TGtkMenu_needs_destruction_ref_count

proc set_needs_destruction_ref_count*(a: PMenu,
                                      `needs_destruction_ref_count`: guint) =
  a.Menuflag0 = a.Menuflag0 or
      (int16(`needs_destruction_ref_count` shl
      bp_TGtkMenu_needs_destruction_ref_count) and
      bm_TGtkMenu_needs_destruction_ref_count)

proc torn_off*(a: PMenu): guint =
  result = (a.Menuflag0 and bm_TGtkMenu_torn_off) shr bp_TGtkMenu_torn_off

proc set_torn_off*(a: PMenu, `torn_off`: guint) =
  a.Menuflag0 = a.Menuflag0 or
      (int16(`torn_off` shl bp_TGtkMenu_torn_off) and bm_TGtkMenu_torn_off)

proc tearoff_active*(a: PMenu): guint =
  result = (a.Menuflag0 and bm_TGtkMenu_tearoff_active) shr
      bp_TGtkMenu_tearoff_active

proc set_tearoff_active*(a: PMenu, `tearoff_active`: guint) =
  a.Menuflag0 = a.Menuflag0 or
      (int16(`tearoff_active` shl bp_TGtkMenu_tearoff_active) and
      bm_TGtkMenu_tearoff_active)

proc scroll_fast*(a: PMenu): guint =
  result = (a.Menuflag0 and bm_TGtkMenu_scroll_fast) shr
      bp_TGtkMenu_scroll_fast

proc set_scroll_fast*(a: PMenu, `scroll_fast`: guint) =
  a.Menuflag0 = a.Menuflag0 or
      (int16(`scroll_fast` shl bp_TGtkMenu_scroll_fast) and
      bm_TGtkMenu_scroll_fast)

proc upper_arrow_visible*(a: PMenu): guint =
  result = (a.Menuflag0 and bm_TGtkMenu_upper_arrow_visible) shr
      bp_TGtkMenu_upper_arrow_visible

proc set_upper_arrow_visible*(a: PMenu, `upper_arrow_visible`: guint) =
  a.Menuflag0 = a.Menuflag0 or
      (int16(`upper_arrow_visible` shl bp_TGtkMenu_upper_arrow_visible) and
      bm_TGtkMenu_upper_arrow_visible)

proc lower_arrow_visible*(a: PMenu): guint =
  result = (a.Menuflag0 and bm_TGtkMenu_lower_arrow_visible) shr
      bp_TGtkMenu_lower_arrow_visible

proc set_lower_arrow_visible*(a: PMenu, `lower_arrow_visible`: guint) =
  a.Menuflag0 = a.Menuflag0 or
      (int16(`lower_arrow_visible` shl bp_TGtkMenu_lower_arrow_visible) and
      bm_TGtkMenu_lower_arrow_visible)

proc upper_arrow_prelight*(a: PMenu): guint =
  result = (a.Menuflag0 and bm_TGtkMenu_upper_arrow_prelight) shr
      bp_TGtkMenu_upper_arrow_prelight

proc set_upper_arrow_prelight*(a: PMenu, `upper_arrow_prelight`: guint) =
  a.Menuflag0 = a.Menuflag0 or
      (int16(`upper_arrow_prelight` shl bp_TGtkMenu_upper_arrow_prelight) and
      bm_TGtkMenu_upper_arrow_prelight)

proc lower_arrow_prelight*(a: PMenu): guint =
  result = (a.Menuflag0 and bm_TGtkMenu_lower_arrow_prelight) shr
      bp_TGtkMenu_lower_arrow_prelight

proc set_lower_arrow_prelight*(a: PMenu, `lower_arrow_prelight`: guint) =
  a.Menuflag0 = a.Menuflag0 or
      (int16(`lower_arrow_prelight` shl bp_TGtkMenu_lower_arrow_prelight) and
      bm_TGtkMenu_lower_arrow_prelight)

proc menu_append*(menu, child: PWidget) =
  append(cast[PMenuShell](menu), child)

proc menu_prepend*(menu, child: PWidget) =
  prepend(cast[PMenuShell](menu), child)

proc menu_insert*(menu, child: PWidget, pos: gint) =
  insert(cast[PMenuShell](menu), child, pos)

proc TYPE_ENTRY*(): GType =
  result = entry_get_type()

proc ENTRY*(obj: pointer): PEntry =
  result = cast[PEntry](CHECK_CAST(obj, TYPE_ENTRY()))

proc ENTRY_CLASS*(klass: pointer): PEntryClass =
  result = cast[PEntryClass](CHECK_CLASS_CAST(klass, TYPE_ENTRY()))

proc IS_ENTRY*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_ENTRY())

proc IS_ENTRY_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_ENTRY())

proc ENTRY_GET_CLASS*(obj: pointer): PEntryClass =
  result = cast[PEntryClass](CHECK_GET_CLASS(obj, TYPE_ENTRY()))

proc editable*(a: PEntry): guint =
  result = (a.Entryflag0 and bm_TGtkEntry_editable) shr bp_TGtkEntry_editable

proc set_editable*(a: PEntry, `editable`: guint) =
  a.Entryflag0 = a.Entryflag0 or
      (int16(`editable` shl bp_TGtkEntry_editable) and bm_TGtkEntry_editable)

proc visible*(a: PEntry): guint =
  result = (a.Entryflag0 and bm_TGtkEntry_visible) shr bp_TGtkEntry_visible

proc set_visible*(a: PEntry, `visible`: guint) =
  a.Entryflag0 = a.Entryflag0 or
      (int16(`visible` shl bp_TGtkEntry_visible) and bm_TGtkEntry_visible)

proc overwrite_mode*(a: PEntry): guint =
  result = (a.Entryflag0 and bm_TGtkEntry_overwrite_mode) shr
      bp_TGtkEntry_overwrite_mode

proc set_overwrite_mode*(a: PEntry, `overwrite_mode`: guint) =
  a.Entryflag0 = a.Entryflag0 or
      (int16(`overwrite_mode` shl bp_TGtkEntry_overwrite_mode) and
      bm_TGtkEntry_overwrite_mode)

proc in_drag*(a: PEntry): guint =
  result = (a.Entryflag0 and bm_TGtkEntry_in_drag) shr bp_TGtkEntry_in_drag

proc set_in_drag*(a: PEntry, `in_drag`: guint) =
  a.Entryflag0 = a.Entryflag0 or
      (int16(`in_drag` shl bp_TGtkEntry_in_drag) and bm_TGtkEntry_in_drag)

proc cache_includes_preedit*(a: PEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_cache_includes_preedit) shr
      bp_TGtkEntry_cache_includes_preedit

proc set_cache_includes_preedit*(a: PEntry, `cache_includes_preedit`: guint) =
  a.flag1 = a.flag1 or
      (int16(`cache_includes_preedit` shl bp_TGtkEntry_cache_includes_preedit) and
      bm_TGtkEntry_cache_includes_preedit)

proc need_im_reset*(a: PEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_need_im_reset) shr
      bp_TGtkEntry_need_im_reset

proc set_need_im_reset*(a: PEntry, `need_im_reset`: guint) =
  a.flag1 = a.flag1 or
      (int16(`need_im_reset` shl bp_TGtkEntry_need_im_reset) and
      bm_TGtkEntry_need_im_reset)

proc has_frame*(a: PEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_has_frame) shr bp_TGtkEntry_has_frame

proc set_has_frame*(a: PEntry, `has_frame`: guint) =
  a.flag1 = a.flag1 or
      (int16(`has_frame` shl bp_TGtkEntry_has_frame) and
      bm_TGtkEntry_has_frame)

proc activates_default*(a: PEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_activates_default) shr
      bp_TGtkEntry_activates_default

proc set_activates_default*(a: PEntry, `activates_default`: guint) =
  a.flag1 = a.flag1 or
      (int16(`activates_default` shl bp_TGtkEntry_activates_default) and
      bm_TGtkEntry_activates_default)

proc cursor_visible*(a: PEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_cursor_visible) shr
      bp_TGtkEntry_cursor_visible

proc set_cursor_visible*(a: PEntry, `cursor_visible`: guint) =
  a.flag1 = a.flag1 or
      (int16(`cursor_visible` shl bp_TGtkEntry_cursor_visible) and
      bm_TGtkEntry_cursor_visible)

proc in_click*(a: PEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_in_click) shr bp_TGtkEntry_in_click

proc set_in_click*(a: PEntry, `in_click`: guint) =
  a.flag1 = a.flag1 or
      (int16(`in_click` shl bp_TGtkEntry_in_click) and bm_TGtkEntry_in_click)

proc is_cell_renderer*(a: PEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_is_cell_renderer) shr
      bp_TGtkEntry_is_cell_renderer

proc set_is_cell_renderer*(a: PEntry, `is_cell_renderer`: guint) =
  a.flag1 = a.flag1 or
      (int16(`is_cell_renderer` shl bp_TGtkEntry_is_cell_renderer) and
      bm_TGtkEntry_is_cell_renderer)

proc editing_canceled*(a: PEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_editing_canceled) shr
      bp_TGtkEntry_editing_canceled

proc set_editing_canceled*(a: PEntry, `editing_canceled`: guint) =
  a.flag1 = a.flag1 or
      (int16(`editing_canceled` shl bp_TGtkEntry_editing_canceled) and
      bm_TGtkEntry_editing_canceled)

proc mouse_cursor_obscured*(a: PEntry): guint =
  result = (a.flag1 and bm_TGtkEntry_mouse_cursor_obscured) shr
      bp_TGtkEntry_mouse_cursor_obscured

proc set_mouse_cursor_obscured*(a: PEntry, `mouse_cursor_obscured`: guint) =
  a.flag1 = a.flag1 or
      (int16(`mouse_cursor_obscured` shl bp_TGtkEntry_mouse_cursor_obscured) and
      bm_TGtkEntry_mouse_cursor_obscured)

proc TYPE_EVENT_BOX*(): GType =
  result = event_box_get_type()

proc EVENT_BOX*(obj: pointer): PEventBox =
  result = cast[PEventBox](CHECK_CAST(obj, TYPE_EVENT_BOX()))

proc EVENT_BOX_CLASS*(klass: pointer): PEventBoxClass =
  result = cast[PEventBoxClass](CHECK_CLASS_CAST(klass, TYPE_EVENT_BOX()))

proc IS_EVENT_BOX*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_EVENT_BOX())

proc IS_EVENT_BOX_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_EVENT_BOX())

proc EVENT_BOX_GET_CLASS*(obj: pointer): PEventBoxClass =
  result = cast[PEventBoxClass](CHECK_GET_CLASS(obj, TYPE_EVENT_BOX()))

proc TYPE_FILE_SELECTION*(): GType =
  result = file_selection_get_type()

proc FILE_SELECTION*(obj: pointer): PFileSelection =
  result = cast[PFileSelection](CHECK_CAST(obj, TYPE_FILE_SELECTION()))

proc FILE_SELECTION_CLASS*(klass: pointer): PFileSelectionClass =
  result = cast[PFileSelectionClass](CHECK_CLASS_CAST(klass,
      TYPE_FILE_SELECTION()))

proc IS_FILE_SELECTION*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_FILE_SELECTION())

proc IS_FILE_SELECTION_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_FILE_SELECTION())

proc FILE_SELECTION_GET_CLASS*(obj: pointer): PFileSelectionClass =
  result = cast[PFileSelectionClass](CHECK_GET_CLASS(obj, TYPE_FILE_SELECTION()))

proc TYPE_FIXED*(): GType =
  result = fixed_get_type()

proc FIXED*(obj: pointer): PFixed =
  result = cast[PFixed](CHECK_CAST(obj, TYPE_FIXED()))

proc FIXED_CLASS*(klass: pointer): PFixedClass =
  result = cast[PFixedClass](CHECK_CLASS_CAST(klass, TYPE_FIXED()))

proc IS_FIXED*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_FIXED())

proc IS_FIXED_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_FIXED())

proc FIXED_GET_CLASS*(obj: pointer): PFixedClass =
  result = cast[PFixedClass](CHECK_GET_CLASS(obj, TYPE_FIXED()))

proc TYPE_FONT_SELECTION*(): GType =
  result = font_selection_get_type()

proc FONT_SELECTION*(obj: pointer): PFontSelection =
  result = cast[PFontSelection](CHECK_CAST(obj, TYPE_FONT_SELECTION()))

proc FONT_SELECTION_CLASS*(klass: pointer): PFontSelectionClass =
  result = cast[PFontSelectionClass](CHECK_CLASS_CAST(klass,
      TYPE_FONT_SELECTION()))

proc IS_FONT_SELECTION*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_FONT_SELECTION())

proc IS_FONT_SELECTION_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_FONT_SELECTION())

proc FONT_SELECTION_GET_CLASS*(obj: pointer): PFontSelectionClass =
  result = cast[PFontSelectionClass](CHECK_GET_CLASS(obj, TYPE_FONT_SELECTION()))

proc TYPE_FONT_SELECTION_DIALOG*(): GType =
  result = font_selection_dialog_get_type()

proc FONT_SELECTION_DIALOG*(obj: pointer): PFontSelectionDialog =
  result = cast[PFontSelectionDialog](CHECK_CAST(obj,
      TYPE_FONT_SELECTION_DIALOG()))

proc FONT_SELECTION_DIALOG_CLASS*(klass: pointer): PFontSelectionDialogClass =
  result = cast[PFontSelectionDialogClass](CHECK_CLASS_CAST(klass,
      TYPE_FONT_SELECTION_DIALOG()))

proc IS_FONT_SELECTION_DIALOG*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_FONT_SELECTION_DIALOG())

proc IS_FONT_SELECTION_DIALOG_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_FONT_SELECTION_DIALOG())

proc FONT_SELECTION_DIALOG_GET_CLASS*(obj: pointer): PFontSelectionDialogClass =
  result = cast[PFontSelectionDialogClass](CHECK_GET_CLASS(obj,
      TYPE_FONT_SELECTION_DIALOG()))

proc TYPE_GAMMA_CURVE*(): GType =
  result = gamma_curve_get_type()

proc GAMMA_CURVE*(obj: pointer): PGammaCurve =
  result = cast[PGammaCurve](CHECK_CAST(obj, TYPE_GAMMA_CURVE()))

proc GAMMA_CURVE_CLASS*(klass: pointer): PGammaCurveClass =
  result = cast[PGammaCurveClass](CHECK_CLASS_CAST(klass, TYPE_GAMMA_CURVE()))

proc IS_GAMMA_CURVE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_GAMMA_CURVE())

proc IS_GAMMA_CURVE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_GAMMA_CURVE())

proc GAMMA_CURVE_GET_CLASS*(obj: pointer): PGammaCurveClass =
  result = cast[PGammaCurveClass](CHECK_GET_CLASS(obj, TYPE_GAMMA_CURVE()))

proc TYPE_HANDLE_BOX*(): GType =
  result = handle_box_get_type()

proc HANDLE_BOX*(obj: pointer): PHandleBox =
  result = cast[PHandleBox](CHECK_CAST(obj, TYPE_HANDLE_BOX()))

proc HANDLE_BOX_CLASS*(klass: pointer): PHandleBoxClass =
  result = cast[PHandleBoxClass](CHECK_CLASS_CAST(klass, TYPE_HANDLE_BOX()))

proc IS_HANDLE_BOX*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_HANDLE_BOX())

proc IS_HANDLE_BOX_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_HANDLE_BOX())

proc HANDLE_BOX_GET_CLASS*(obj: pointer): PHandleBoxClass =
  result = cast[PHandleBoxClass](CHECK_GET_CLASS(obj, TYPE_HANDLE_BOX()))

proc handle_position*(a: PHandleBox): guint =
  result = (a.HandleBoxflag0 and bm_TGtkHandleBox_handle_position) shr
      bp_TGtkHandleBox_handle_position

proc set_handle_position*(a: PHandleBox, `handle_position`: guint) =
  a.HandleBoxflag0 = a.HandleBoxflag0 or
      (int16(`handle_position` shl bp_TGtkHandleBox_handle_position) and
      bm_TGtkHandleBox_handle_position)

proc float_window_mapped*(a: PHandleBox): guint =
  result = (a.HandleBoxflag0 and bm_TGtkHandleBox_float_window_mapped) shr
      bp_TGtkHandleBox_float_window_mapped

proc set_float_window_mapped*(a: PHandleBox, `float_window_mapped`: guint) =
  a.HandleBoxflag0 = a.HandleBoxflag0 or
      (int16(`float_window_mapped` shl bp_TGtkHandleBox_float_window_mapped) and
      bm_TGtkHandleBox_float_window_mapped)

proc child_detached*(a: PHandleBox): guint =
  result = (a.HandleBoxflag0 and bm_TGtkHandleBox_child_detached) shr
      bp_TGtkHandleBox_child_detached

proc set_child_detached*(a: PHandleBox, `child_detached`: guint) =
  a.HandleBoxflag0 = a.HandleBoxflag0 or
      (int16(`child_detached` shl bp_TGtkHandleBox_child_detached) and
      bm_TGtkHandleBox_child_detached)

proc in_drag*(a: PHandleBox): guint =
  result = (a.HandleBoxflag0 and bm_TGtkHandleBox_in_drag) shr
      bp_TGtkHandleBox_in_drag

proc set_in_drag*(a: PHandleBox, `in_drag`: guint) =
  a.HandleBoxflag0 = a.HandleBoxflag0 or
      (int16(`in_drag` shl bp_TGtkHandleBox_in_drag) and
      bm_TGtkHandleBox_in_drag)

proc shrink_on_detach*(a: PHandleBox): guint =
  result = (a.HandleBoxflag0 and bm_TGtkHandleBox_shrink_on_detach) shr
      bp_TGtkHandleBox_shrink_on_detach

proc set_shrink_on_detach*(a: PHandleBox, `shrink_on_detach`: guint) =
  a.HandleBoxflag0 = a.HandleBoxflag0 or
      (int16(`shrink_on_detach` shl bp_TGtkHandleBox_shrink_on_detach) and
      bm_TGtkHandleBox_shrink_on_detach)

proc snap_edge*(a: PHandleBox): gint =
  result = (a.HandleBoxflag0 and bm_TGtkHandleBox_snap_edge) shr
      bp_TGtkHandleBox_snap_edge

proc set_snap_edge*(a: PHandleBox, `snap_edge`: gint) =
  a.HandleBoxflag0 = a.HandleBoxflag0 or
      (int16(`snap_edge` shl bp_TGtkHandleBox_snap_edge) and
      bm_TGtkHandleBox_snap_edge)

proc TYPE_PANED*(): GType =
  result = paned_get_type()

proc PANED*(obj: pointer): PPaned =
  result = cast[PPaned](CHECK_CAST(obj, TYPE_PANED()))

proc PANED_CLASS*(klass: pointer): PPanedClass =
  result = cast[PPanedClass](CHECK_CLASS_CAST(klass, TYPE_PANED()))

proc IS_PANED*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_PANED())

proc IS_PANED_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_PANED())

proc PANED_GET_CLASS*(obj: pointer): PPanedClass =
  result = cast[PPanedClass](CHECK_GET_CLASS(obj, TYPE_PANED()))

proc position_set*(a: PPaned): guint =
  result = (a.Panedflag0 and bm_TGtkPaned_position_set) shr
      bp_TGtkPaned_position_set

proc set_position_set*(a: PPaned, `position_set`: guint) =
  a.Panedflag0 = a.Panedflag0 or
      (int16(`position_set` shl bp_TGtkPaned_position_set) and
      bm_TGtkPaned_position_set)

proc in_drag*(a: PPaned): guint =
  result = (a.Panedflag0 and bm_TGtkPaned_in_drag) shr bp_TGtkPaned_in_drag

proc set_in_drag*(a: PPaned, `in_drag`: guint) =
  a.Panedflag0 = a.Panedflag0 or
      (int16(`in_drag` shl bp_TGtkPaned_in_drag) and bm_TGtkPaned_in_drag)

proc child1_shrink*(a: PPaned): guint =
  result = (a.Panedflag0 and bm_TGtkPaned_child1_shrink) shr
      bp_TGtkPaned_child1_shrink

proc set_child1_shrink*(a: PPaned, `child1_shrink`: guint) =
  a.Panedflag0 = a.Panedflag0 or
      (int16(`child1_shrink` shl bp_TGtkPaned_child1_shrink) and
      bm_TGtkPaned_child1_shrink)

proc child1_resize*(a: PPaned): guint =
  result = (a.Panedflag0 and bm_TGtkPaned_child1_resize) shr
      bp_TGtkPaned_child1_resize

proc set_child1_resize*(a: PPaned, `child1_resize`: guint) =
  a.Panedflag0 = a.Panedflag0 or
      (int16(`child1_resize` shl bp_TGtkPaned_child1_resize) and
      bm_TGtkPaned_child1_resize)

proc child2_shrink*(a: PPaned): guint =
  result = (a.Panedflag0 and bm_TGtkPaned_child2_shrink) shr
      bp_TGtkPaned_child2_shrink

proc set_child2_shrink*(a: PPaned, `child2_shrink`: guint) =
  a.Panedflag0 = a.Panedflag0 or
      (int16(`child2_shrink` shl bp_TGtkPaned_child2_shrink) and
      bm_TGtkPaned_child2_shrink)

proc child2_resize*(a: PPaned): guint =
  result = (a.Panedflag0 and bm_TGtkPaned_child2_resize) shr
      bp_TGtkPaned_child2_resize

proc set_child2_resize*(a: PPaned, `child2_resize`: guint) =
  a.Panedflag0 = a.Panedflag0 or
      (int16(`child2_resize` shl bp_TGtkPaned_child2_resize) and
      bm_TGtkPaned_child2_resize)

proc orientation*(a: PPaned): guint =
  result = (a.Panedflag0 and bm_TGtkPaned_orientation) shr
      bp_TGtkPaned_orientation

proc set_orientation*(a: PPaned, `orientation`: guint) =
  a.Panedflag0 = a.Panedflag0 or
      (int16(`orientation` shl bp_TGtkPaned_orientation) and
      bm_TGtkPaned_orientation)

proc in_recursion*(a: PPaned): guint =
  result = (a.Panedflag0 and bm_TGtkPaned_in_recursion) shr
      bp_TGtkPaned_in_recursion

proc set_in_recursion*(a: PPaned, `in_recursion`: guint) =
  a.Panedflag0 = a.Panedflag0 or
      (int16(`in_recursion` shl bp_TGtkPaned_in_recursion) and
      bm_TGtkPaned_in_recursion)

proc handle_prelit*(a: PPaned): guint =
  result = (a.Panedflag0 and bm_TGtkPaned_handle_prelit) shr
      bp_TGtkPaned_handle_prelit

proc set_handle_prelit*(a: PPaned, `handle_prelit`: guint) =
  a.Panedflag0 = a.Panedflag0 or
      (int16(`handle_prelit` shl bp_TGtkPaned_handle_prelit) and
      bm_TGtkPaned_handle_prelit)

proc paned_gutter_size*(p: pointer, s: gint) =
  if (p != nil) and (s != 0'i32): nil

proc paned_set_gutter_size*(p: pointer, s: gint) =
  if (p != nil) and (s != 0'i32): nil

proc TYPE_HBUTTON_BOX*(): GType =
  result = hbutton_box_get_type()

proc HBUTTON_BOX*(obj: pointer): PHButtonBox =
  result = cast[PHButtonBox](CHECK_CAST(obj, TYPE_HBUTTON_BOX()))

proc HBUTTON_BOX_CLASS*(klass: pointer): PHButtonBoxClass =
  result = cast[PHButtonBoxClass](CHECK_CLASS_CAST(klass, TYPE_HBUTTON_BOX()))

proc IS_HBUTTON_BOX*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_HBUTTON_BOX())

proc IS_HBUTTON_BOX_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_HBUTTON_BOX())

proc HBUTTON_BOX_GET_CLASS*(obj: pointer): PHButtonBoxClass =
  result = cast[PHButtonBoxClass](CHECK_GET_CLASS(obj, TYPE_HBUTTON_BOX()))

proc TYPE_HPANED*(): GType =
  result = hpaned_get_type()

proc HPANED*(obj: pointer): PHPaned =
  result = cast[PHPaned](CHECK_CAST(obj, TYPE_HPANED()))

proc HPANED_CLASS*(klass: pointer): PHPanedClass =
  result = cast[PHPanedClass](CHECK_CLASS_CAST(klass, TYPE_HPANED()))

proc IS_HPANED*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_HPANED())

proc IS_HPANED_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_HPANED())

proc HPANED_GET_CLASS*(obj: pointer): PHPanedClass =
  result = cast[PHPanedClass](CHECK_GET_CLASS(obj, TYPE_HPANED()))

proc TYPE_RULER*(): GType =
  result = ruler_get_type()

proc RULER*(obj: pointer): PRuler =
  result = cast[PRuler](CHECK_CAST(obj, TYPE_RULER()))

proc RULER_CLASS*(klass: pointer): PRulerClass =
  result = cast[PRulerClass](CHECK_CLASS_CAST(klass, TYPE_RULER()))

proc IS_RULER*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_RULER())

proc IS_RULER_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_RULER())

proc RULER_GET_CLASS*(obj: pointer): PRulerClass =
  result = cast[PRulerClass](CHECK_GET_CLASS(obj, TYPE_RULER()))

proc TYPE_HRULER*(): GType =
  result = hruler_get_type()

proc HRULER*(obj: pointer): PHRuler =
  result = cast[PHRuler](CHECK_CAST(obj, TYPE_HRULER()))

proc HRULER_CLASS*(klass: pointer): PHRulerClass =
  result = cast[PHRulerClass](CHECK_CLASS_CAST(klass, TYPE_HRULER()))

proc IS_HRULER*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_HRULER())

proc IS_HRULER_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_HRULER())

proc HRULER_GET_CLASS*(obj: pointer): PHRulerClass =
  result = cast[PHRulerClass](CHECK_GET_CLASS(obj, TYPE_HRULER()))

proc TYPE_SETTINGS*(): GType =
  result = settings_get_type()

proc SETTINGS*(obj: pointer): PSettings =
  result = cast[PSettings](CHECK_CAST(obj, TYPE_SETTINGS()))

proc SETTINGS_CLASS*(klass: pointer): PSettingsClass =
  result = cast[PSettingsClass](CHECK_CLASS_CAST(klass, TYPE_SETTINGS()))

proc IS_SETTINGS*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_SETTINGS())

proc IS_SETTINGS_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_SETTINGS())

proc SETTINGS_GET_CLASS*(obj: pointer): PSettingsClass =
  result = cast[PSettingsClass](CHECK_GET_CLASS(obj, TYPE_SETTINGS()))

proc TYPE_RC_STYLE*(): GType =
  result = rc_style_get_type()

proc RC_STYLE_get*(anObject: pointer): PRcStyle =
  result = cast[PRcStyle](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_RC_STYLE()))

proc RC_STYLE_CLASS*(klass: pointer): PRcStyleClass =
  result = cast[PRcStyleClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_RC_STYLE()))

proc IS_RC_STYLE*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_RC_STYLE())

proc IS_RC_STYLE_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_RC_STYLE())

proc RC_STYLE_GET_CLASS*(obj: pointer): PRcStyleClass =
  result = cast[PRcStyleClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_RC_STYLE()))

proc engine_specified*(a: PRcStyle): guint =
  result = (a.RcStyleflag0 and bm_TGtkRcStyle_engine_specified) shr
      bp_TGtkRcStyle_engine_specified

proc set_engine_specified*(a: PRcStyle, `engine_specified`: guint) =
  a.RcStyleflag0 = a.RcStyleflag0 or
      (int16(`engine_specified` shl bp_TGtkRcStyle_engine_specified) and
      bm_TGtkRcStyle_engine_specified)

proc TYPE_STYLE*(): GType =
  result = style_get_type()

proc STYLE*(anObject: pointer): PStyle =
  result = cast[PStyle](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_STYLE()))

proc STYLE_CLASS*(klass: pointer): PStyleClass =
  result = cast[PStyleClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_STYLE()))

proc IS_STYLE*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_STYLE())

proc IS_STYLE_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_STYLE())

proc STYLE_GET_CLASS*(obj: pointer): PStyleClass =
  result = cast[PStyleClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_STYLE()))

proc TYPE_BORDER*(): GType =
  result = border_get_type()

proc STYLE_ATTACHED*(style: pointer): bool =
  result = ((STYLE(style)).attach_count) > 0'i32

proc apply_default_pixmap*(style: PStyle, window: gdk2.PWindow,
                                 state_type: TStateType, area: gdk2.PRectangle,
                                 x: gint, y: gint, width: gint, height: gint) =
  apply_default_background(style, window, true, state_type, area, x, y,
                           width, height)

proc TYPE_RANGE*(): GType =
  result = range_get_type()

proc RANGE*(obj: pointer): PRange =
  result = cast[PRange](CHECK_CAST(obj, TYPE_RANGE()))

proc RANGE_CLASS*(klass: pointer): PRangeClass =
  result = cast[PRangeClass](CHECK_CLASS_CAST(klass, TYPE_RANGE()))

proc IS_RANGE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_RANGE())

proc IS_RANGE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_RANGE())

proc RANGE_GET_CLASS*(obj: pointer): PRangeClass =
  result = cast[PRangeClass](CHECK_GET_CLASS(obj, TYPE_RANGE()))

proc inverted*(a: PRange): guint =
  result = (a.Rangeflag0 and bm_TGtkRange_inverted) shr bp_TGtkRange_inverted

proc set_inverted*(a: PRange, `inverted`: guint) =
  a.Rangeflag0 = a.Rangeflag0 or
      (int16(`inverted` shl bp_TGtkRange_inverted) and bm_TGtkRange_inverted)

proc flippable*(a: PRange): guint =
  result = (a.Rangeflag0 and bm_TGtkRange_flippable) shr
      bp_TGtkRange_flippable

proc set_flippable*(a: PRange, `flippable`: guint) =
  a.Rangeflag0 = a.Rangeflag0 or
      (int16(`flippable` shl bp_TGtkRange_flippable) and
      bm_TGtkRange_flippable)

proc has_stepper_a*(a: PRange): guint =
  result = (a.Rangeflag0 and bm_TGtkRange_has_stepper_a) shr
      bp_TGtkRange_has_stepper_a

proc set_has_stepper_a*(a: PRange, `has_stepper_a`: guint) =
  a.Rangeflag0 = a.Rangeflag0 or
      (int16(`has_stepper_a` shl bp_TGtkRange_has_stepper_a) and
      bm_TGtkRange_has_stepper_a)

proc has_stepper_b*(a: PRange): guint =
  result = (a.Rangeflag0 and bm_TGtkRange_has_stepper_b) shr
      bp_TGtkRange_has_stepper_b

proc set_has_stepper_b*(a: PRange, `has_stepper_b`: guint) =
  a.Rangeflag0 = a.Rangeflag0 or
      (int16(`has_stepper_b` shl bp_TGtkRange_has_stepper_b) and
      bm_TGtkRange_has_stepper_b)

proc has_stepper_c*(a: PRange): guint =
  result = (a.Rangeflag0 and bm_TGtkRange_has_stepper_c) shr
      bp_TGtkRange_has_stepper_c

proc set_has_stepper_c*(a: PRange, `has_stepper_c`: guint) =
  a.Rangeflag0 = a.Rangeflag0 or
      (int16(`has_stepper_c` shl bp_TGtkRange_has_stepper_c) and
      bm_TGtkRange_has_stepper_c)

proc has_stepper_d*(a: PRange): guint =
  result = (a.Rangeflag0 and bm_TGtkRange_has_stepper_d) shr
      bp_TGtkRange_has_stepper_d

proc set_has_stepper_d*(a: PRange, `has_stepper_d`: guint) =
  a.Rangeflag0 = a.Rangeflag0 or
      (int16(`has_stepper_d` shl bp_TGtkRange_has_stepper_d) and
      bm_TGtkRange_has_stepper_d)

proc need_recalc*(a: PRange): guint =
  result = (a.Rangeflag0 and bm_TGtkRange_need_recalc) shr
      bp_TGtkRange_need_recalc

proc set_need_recalc*(a: PRange, `need_recalc`: guint) =
  a.Rangeflag0 = a.Rangeflag0 or
      (int16(`need_recalc` shl bp_TGtkRange_need_recalc) and
      bm_TGtkRange_need_recalc)

proc slider_size_fixed*(a: PRange): guint =
  result = (a.Rangeflag0 and bm_TGtkRange_slider_size_fixed) shr
      bp_TGtkRange_slider_size_fixed

proc set_slider_size_fixed*(a: PRange, `slider_size_fixed`: guint) =
  a.Rangeflag0 = a.Rangeflag0 or
      (int16(`slider_size_fixed` shl bp_TGtkRange_slider_size_fixed) and
      bm_TGtkRange_slider_size_fixed)

proc trough_click_forward*(a: PRange): guint =
  result = (a.flag1 and bm_TGtkRange_trough_click_forward) shr
      bp_TGtkRange_trough_click_forward

proc set_trough_click_forward*(a: PRange, `trough_click_forward`: guint) =
  a.flag1 = a.flag1 or
      (int16(`trough_click_forward` shl bp_TGtkRange_trough_click_forward) and
      bm_TGtkRange_trough_click_forward)

proc update_pending*(a: PRange): guint =
  result = (a.flag1 and bm_TGtkRange_update_pending) shr
      bp_TGtkRange_update_pending

proc set_update_pending*(a: PRange, `update_pending`: guint) =
  a.flag1 = a.flag1 or
      (int16(`update_pending` shl bp_TGtkRange_update_pending) and
      bm_TGtkRange_update_pending)

proc TYPE_SCALE*(): GType =
  result = scale_get_type()

proc SCALE*(obj: pointer): PScale =
  result = cast[PScale](CHECK_CAST(obj, TYPE_SCALE()))

proc SCALE_CLASS*(klass: pointer): PScaleClass =
  result = cast[PScaleClass](CHECK_CLASS_CAST(klass, TYPE_SCALE()))

proc IS_SCALE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_SCALE())

proc IS_SCALE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_SCALE())

proc SCALE_GET_CLASS*(obj: pointer): PScaleClass =
  result = cast[PScaleClass](CHECK_GET_CLASS(obj, TYPE_SCALE()))

proc draw_value*(a: PScale): guint =
  result = (a.Scaleflag0 and bm_TGtkScale_draw_value) shr
      bp_TGtkScale_draw_value

proc set_draw_value*(a: PScale, `draw_value`: guint) =
  a.Scaleflag0 = a.Scaleflag0 or
      (int16(`draw_value` shl bp_TGtkScale_draw_value) and
      bm_TGtkScale_draw_value)

proc value_pos*(a: PScale): guint =
  result = (a.Scaleflag0 and bm_TGtkScale_value_pos) shr
      bp_TGtkScale_value_pos

proc set_value_pos*(a: PScale, `value_pos`: guint) =
  a.Scaleflag0 = a.Scaleflag0 or
      (int16(`value_pos` shl bp_TGtkScale_value_pos) and
      bm_TGtkScale_value_pos)

proc TYPE_HSCALE*(): GType =
  result = hscale_get_type()

proc HSCALE*(obj: pointer): PHScale =
  result = cast[PHScale](CHECK_CAST(obj, TYPE_HSCALE()))

proc HSCALE_CLASS*(klass: pointer): PHScaleClass =
  result = cast[PHScaleClass](CHECK_CLASS_CAST(klass, TYPE_HSCALE()))

proc IS_HSCALE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_HSCALE())

proc IS_HSCALE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_HSCALE())

proc HSCALE_GET_CLASS*(obj: pointer): PHScaleClass =
  result = cast[PHScaleClass](CHECK_GET_CLASS(obj, TYPE_HSCALE()))

proc TYPE_SCROLLBAR*(): GType =
  result = scrollbar_get_type()

proc SCROLLBAR*(obj: pointer): PScrollbar =
  result = cast[PScrollbar](CHECK_CAST(obj, TYPE_SCROLLBAR()))

proc SCROLLBAR_CLASS*(klass: pointer): PScrollbarClass =
  result = cast[PScrollbarClass](CHECK_CLASS_CAST(klass, TYPE_SCROLLBAR()))

proc IS_SCROLLBAR*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_SCROLLBAR())

proc IS_SCROLLBAR_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_SCROLLBAR())

proc SCROLLBAR_GET_CLASS*(obj: pointer): PScrollbarClass =
  result = cast[PScrollbarClass](CHECK_GET_CLASS(obj, TYPE_SCROLLBAR()))

proc TYPE_HSCROLLBAR*(): GType =
  result = hscrollbar_get_type()

proc HSCROLLBAR*(obj: pointer): PHScrollbar =
  result = cast[PHScrollbar](CHECK_CAST(obj, TYPE_HSCROLLBAR()))

proc HSCROLLBAR_CLASS*(klass: pointer): PHScrollbarClass =
  result = cast[PHScrollbarClass](CHECK_CLASS_CAST(klass, TYPE_HSCROLLBAR()))

proc IS_HSCROLLBAR*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_HSCROLLBAR())

proc IS_HSCROLLBAR_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_HSCROLLBAR())

proc HSCROLLBAR_GET_CLASS*(obj: pointer): PHScrollbarClass =
  result = cast[PHScrollbarClass](CHECK_GET_CLASS(obj, TYPE_HSCROLLBAR()))

proc TYPE_SEPARATOR*(): GType =
  result = separator_get_type()

proc SEPARATOR*(obj: pointer): PSeparator =
  result = cast[PSeparator](CHECK_CAST(obj, TYPE_SEPARATOR()))

proc SEPARATOR_CLASS*(klass: pointer): PSeparatorClass =
  result = cast[PSeparatorClass](CHECK_CLASS_CAST(klass, TYPE_SEPARATOR()))

proc IS_SEPARATOR*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_SEPARATOR())

proc IS_SEPARATOR_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_SEPARATOR())

proc SEPARATOR_GET_CLASS*(obj: pointer): PSeparatorClass =
  result = cast[PSeparatorClass](CHECK_GET_CLASS(obj, TYPE_SEPARATOR()))

proc TYPE_HSEPARATOR*(): GType =
  result = hseparator_get_type()

proc HSEPARATOR*(obj: pointer): PHSeparator =
  result = cast[PHSeparator](CHECK_CAST(obj, TYPE_HSEPARATOR()))

proc HSEPARATOR_CLASS*(klass: pointer): PHSeparatorClass =
  result = cast[PHSeparatorClass](CHECK_CLASS_CAST(klass, TYPE_HSEPARATOR()))

proc IS_HSEPARATOR*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_HSEPARATOR())

proc IS_HSEPARATOR_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_HSEPARATOR())

proc HSEPARATOR_GET_CLASS*(obj: pointer): PHSeparatorClass =
  result = cast[PHSeparatorClass](CHECK_GET_CLASS(obj, TYPE_HSEPARATOR()))

proc TYPE_ICON_FACTORY*(): GType =
  result = icon_factory_get_type()

proc ICON_FACTORY*(anObject: pointer): PIconFactory =
  result = cast[PIconFactory](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      TYPE_ICON_FACTORY()))

proc ICON_FACTORY_CLASS*(klass: pointer): PIconFactoryClass =
  result = cast[PIconFactoryClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_ICON_FACTORY()))

proc IS_ICON_FACTORY*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_ICON_FACTORY())

proc IS_ICON_FACTORY_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_ICON_FACTORY())

proc ICON_FACTORY_GET_CLASS*(obj: pointer): PIconFactoryClass =
  result = cast[PIconFactoryClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_ICON_FACTORY()))

proc TYPE_ICON_SET*(): GType =
  result = icon_set_get_type()

proc TYPE_ICON_SOURCE*(): GType =
  result = icon_source_get_type()

proc TYPE_IMAGE*(): GType =
  result = gtk2.image_get_type()

proc IMAGE*(obj: pointer): PImage =
  result = cast[PImage](CHECK_CAST(obj, gtk2.TYPE_IMAGE()))

proc IMAGE_CLASS*(klass: pointer): PImageClass =
  result = cast[PImageClass](CHECK_CLASS_CAST(klass, gtk2.TYPE_IMAGE()))

proc IS_IMAGE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, gtk2.TYPE_IMAGE())

proc IS_IMAGE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, gtk2.TYPE_IMAGE())

proc IMAGE_GET_CLASS*(obj: pointer): PImageClass =
  result = cast[PImageClass](CHECK_GET_CLASS(obj, gtk2.TYPE_IMAGE()))

proc TYPE_IMAGE_MENU_ITEM*(): GType =
  result = image_menu_item_get_type()

proc IMAGE_MENU_ITEM*(obj: pointer): PImageMenuItem =
  result = cast[PImageMenuItem](CHECK_CAST(obj, TYPE_IMAGE_MENU_ITEM()))

proc IMAGE_MENU_ITEM_CLASS*(klass: pointer): PImageMenuItemClass =
  result = cast[PImageMenuItemClass](CHECK_CLASS_CAST(klass,
      TYPE_IMAGE_MENU_ITEM()))

proc IS_IMAGE_MENU_ITEM*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_IMAGE_MENU_ITEM())

proc IS_IMAGE_MENU_ITEM_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_IMAGE_MENU_ITEM())

proc IMAGE_MENU_ITEM_GET_CLASS*(obj: pointer): PImageMenuItemClass =
  result = cast[PImageMenuItemClass](CHECK_GET_CLASS(obj, TYPE_IMAGE_MENU_ITEM()))

proc TYPE_IM_CONTEXT_SIMPLE*(): GType =
  result = im_context_simple_get_type()

proc IM_CONTEXT_SIMPLE*(obj: pointer): PIMContextSimple =
  result = cast[PIMContextSimple](CHECK_CAST(obj, TYPE_IM_CONTEXT_SIMPLE()))

proc IM_CONTEXT_SIMPLE_CLASS*(klass: pointer): PIMContextSimpleClass =
  result = cast[PIMContextSimpleClass](CHECK_CLASS_CAST(klass,
      TYPE_IM_CONTEXT_SIMPLE()))

proc IS_IM_CONTEXT_SIMPLE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_IM_CONTEXT_SIMPLE())

proc IS_IM_CONTEXT_SIMPLE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_IM_CONTEXT_SIMPLE())

proc IM_CONTEXT_SIMPLE_GET_CLASS*(obj: pointer): PIMContextSimpleClass =
  result = cast[PIMContextSimpleClass](CHECK_GET_CLASS(obj,
      TYPE_IM_CONTEXT_SIMPLE()))

proc in_hex_sequence*(a: PIMContextSimple): guint =
  result = (a.IMContextSimpleflag0 and bm_TGtkIMContextSimple_in_hex_sequence) shr
      bp_TGtkIMContextSimple_in_hex_sequence

proc set_in_hex_sequence*(a: PIMContextSimple, `in_hex_sequence`: guint) =
  a.IMContextSimpleflag0 = a.IMContextSimpleflag0 or
      (int16(`in_hex_sequence` shl bp_TGtkIMContextSimple_in_hex_sequence) and
      bm_TGtkIMContextSimple_in_hex_sequence)

proc TYPE_IM_MULTICONTEXT*(): GType =
  result = im_multicontext_get_type()

proc IM_MULTICONTEXT*(obj: pointer): PIMMulticontext =
  result = cast[PIMMulticontext](CHECK_CAST(obj, TYPE_IM_MULTICONTEXT()))

proc IM_MULTICONTEXT_CLASS*(klass: pointer): PIMMulticontextClass =
  result = cast[PIMMulticontextClass](CHECK_CLASS_CAST(klass,
      TYPE_IM_MULTICONTEXT()))

proc IS_IM_MULTICONTEXT*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_IM_MULTICONTEXT())

proc IS_IM_MULTICONTEXT_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_IM_MULTICONTEXT())

proc IM_MULTICONTEXT_GET_CLASS*(obj: pointer): PIMMulticontextClass =
  result = cast[PIMMulticontextClass](CHECK_GET_CLASS(obj,
      TYPE_IM_MULTICONTEXT()))

proc TYPE_INPUT_DIALOG*(): GType =
  result = input_dialog_get_type()

proc INPUT_DIALOG*(obj: pointer): PInputDialog =
  result = cast[PInputDialog](CHECK_CAST(obj, TYPE_INPUT_DIALOG()))

proc INPUT_DIALOG_CLASS*(klass: pointer): PInputDialogClass =
  result = cast[PInputDialogClass](CHECK_CLASS_CAST(klass, TYPE_INPUT_DIALOG()))

proc IS_INPUT_DIALOG*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_INPUT_DIALOG())

proc IS_INPUT_DIALOG_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_INPUT_DIALOG())

proc INPUT_DIALOG_GET_CLASS*(obj: pointer): PInputDialogClass =
  result = cast[PInputDialogClass](CHECK_GET_CLASS(obj, TYPE_INPUT_DIALOG()))

proc TYPE_INVISIBLE*(): GType =
  result = invisible_get_type()

proc INVISIBLE*(obj: pointer): PInvisible =
  result = cast[PInvisible](CHECK_CAST(obj, TYPE_INVISIBLE()))

proc INVISIBLE_CLASS*(klass: pointer): PInvisibleClass =
  result = cast[PInvisibleClass](CHECK_CLASS_CAST(klass, TYPE_INVISIBLE()))

proc IS_INVISIBLE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_INVISIBLE())

proc IS_INVISIBLE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_INVISIBLE())

proc INVISIBLE_GET_CLASS*(obj: pointer): PInvisibleClass =
  result = cast[PInvisibleClass](CHECK_GET_CLASS(obj, TYPE_INVISIBLE()))

proc TYPE_ITEM_FACTORY*(): GType =
  result = item_factory_get_type()

proc ITEM_FACTORY*(anObject: pointer): PItemFactory =
  result = cast[PItemFactory](CHECK_CAST(anObject, TYPE_ITEM_FACTORY()))

proc ITEM_FACTORY_CLASS*(klass: pointer): PItemFactoryClass =
  result = cast[PItemFactoryClass](CHECK_CLASS_CAST(klass, TYPE_ITEM_FACTORY()))

proc IS_ITEM_FACTORY*(anObject: pointer): bool =
  result = CHECK_TYPE(anObject, TYPE_ITEM_FACTORY())

proc IS_ITEM_FACTORY_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_ITEM_FACTORY())

proc ITEM_FACTORY_GET_CLASS*(obj: pointer): PItemFactoryClass =
  result = cast[PItemFactoryClass](CHECK_GET_CLASS(obj, TYPE_ITEM_FACTORY()))

proc TYPE_LAYOUT*(): GType =
  result = gtk2.layout_get_type()

proc LAYOUT*(obj: pointer): PLayout =
  result = cast[PLayout](CHECK_CAST(obj, gtk2.TYPE_LAYOUT()))

proc LAYOUT_CLASS*(klass: pointer): PLayoutClass =
  result = cast[PLayoutClass](CHECK_CLASS_CAST(klass, gtk2.TYPE_LAYOUT()))

proc IS_LAYOUT*(obj: pointer): bool =
  result = CHECK_TYPE(obj, gtk2.TYPE_LAYOUT())

proc IS_LAYOUT_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, gtk2.TYPE_LAYOUT())

proc LAYOUT_GET_CLASS*(obj: pointer): PLayoutClass =
  result = cast[PLayoutClass](CHECK_GET_CLASS(obj, gtk2.TYPE_LAYOUT()))

proc TYPE_LIST*(): GType =
  result = list_get_type()

proc LIST*(obj: pointer): PList =
  result = cast[PList](CHECK_CAST(obj, TYPE_LIST()))

proc LIST_CLASS*(klass: pointer): PListClass =
  result = cast[PListClass](CHECK_CLASS_CAST(klass, TYPE_LIST()))

proc IS_LIST*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_LIST())

proc IS_LIST_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_LIST())

proc LIST_GET_CLASS*(obj: pointer): PListClass =
  result = cast[PListClass](CHECK_GET_CLASS(obj, TYPE_LIST()))

proc selection_mode*(a: PList): guint =
  result = (a.Listflag0 and bm_TGtkList_selection_mode) shr
      bp_TGtkList_selection_mode

proc set_selection_mode*(a: PList, `selection_mode`: guint) =
  a.Listflag0 = a.Listflag0 or
      (int16(`selection_mode` shl bp_TGtkList_selection_mode) and
      bm_TGtkList_selection_mode)

proc drag_selection*(a: PList): guint =
  result = (a.Listflag0 and bm_TGtkList_drag_selection) shr
      bp_TGtkList_drag_selection

proc set_drag_selection*(a: PList, `drag_selection`: guint) =
  a.Listflag0 = a.Listflag0 or
      (int16(`drag_selection` shl bp_TGtkList_drag_selection) and
      bm_TGtkList_drag_selection)

proc add_mode*(a: PList): guint =
  result = (a.Listflag0 and bm_TGtkList_add_mode) shr bp_TGtkList_add_mode

proc set_add_mode*(a: PList, `add_mode`: guint) =
  a.Listflag0 = a.Listflag0 or
      (int16(`add_mode` shl bp_TGtkList_add_mode) and bm_TGtkList_add_mode)

proc list_item_get_type(): GType{.importc: "gtk_list_item_get_type", cdecl,
                                  dynlib: lib.}
proc TYPE_LIST_ITEM*(): GType =
  result = list_item_get_type()

type
  TListItem = object of TItem
  TListItemClass = object of TItemClass
  PListItem = ptr TListItem
  PListItemClass = ptr TListItemClass

proc LIST_ITEM*(obj: pointer): PListItem =
  result = cast[PListItem](CHECK_CAST(obj, TYPE_LIST_ITEM()))

proc LIST_ITEM_CLASS*(klass: pointer): PListItemClass =
  result = cast[PListItemClass](CHECK_CLASS_CAST(klass, TYPE_LIST_ITEM()))

proc IS_LIST_ITEM*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_LIST_ITEM())

proc IS_LIST_ITEM_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_LIST_ITEM())

proc LIST_ITEM_GET_CLASS*(obj: pointer): PListItemClass =
  #proc gtk_tree_model_get_type(): GType {.importc, cdecl, dynlib: gtklib.}
  result = cast[PListItemClass](CHECK_GET_CLASS(obj, TYPE_LIST_ITEM()))

proc TYPE_TREE_MODEL*(): GType =
  result = tree_model_get_type()

proc TREE_MODEL*(obj: pointer): PTreeModel =
  result = cast[PTreeModel](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_TREE_MODEL()))

proc IS_TREE_MODEL*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_TREE_MODEL())

proc TREE_MODEL_GET_IFACE*(obj: pointer): PTreeModelIface =
  result = cast[PTreeModelIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      TYPE_TREE_MODEL()))

proc TYPE_TREE_ITER*(): GType =
  result = tree_iter_get_type()

proc TYPE_TREE_PATH*(): GType =
  result = tree_path_get_type()

proc tree_path_new_root*(): PTreePath =
  result = tree_path_new_first()

proc get_iter_root*(tree_model: PTreeModel, iter: PTreeIter): gboolean =
  result = get_iter_first(tree_model, iter)

proc TYPE_TREE_SORTABLE*(): GType =
  result = tree_sortable_get_type()

proc TREE_SORTABLE*(obj: pointer): PTreeSortable =
  result = cast[PTreeSortable](G_TYPE_CHECK_INSTANCE_CAST(obj,
      TYPE_TREE_SORTABLE()))

proc TREE_SORTABLE_CLASS*(obj: pointer): PTreeSortableIface =
  result = cast[PTreeSortableIface](G_TYPE_CHECK_CLASS_CAST(obj,
      TYPE_TREE_SORTABLE()))

proc IS_TREE_SORTABLE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_TREE_SORTABLE())

proc TREE_SORTABLE_GET_IFACE*(obj: pointer): PTreeSortableIface =
  result = cast[PTreeSortableIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      TYPE_TREE_SORTABLE()))

proc TYPE_TREE_MODEL_SORT*(): GType =
  result = tree_model_sort_get_type()

proc TREE_MODEL_SORT*(obj: pointer): PTreeModelSort =
  result = cast[PTreeModelSort](CHECK_CAST(obj, TYPE_TREE_MODEL_SORT()))

proc TREE_MODEL_SORT_CLASS*(klass: pointer): PTreeModelSortClass =
  result = cast[PTreeModelSortClass](CHECK_CLASS_CAST(klass,
      TYPE_TREE_MODEL_SORT()))

proc IS_TREE_MODEL_SORT*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TREE_MODEL_SORT())

proc IS_TREE_MODEL_SORT_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TREE_MODEL_SORT())

proc TREE_MODEL_SORT_GET_CLASS*(obj: pointer): PTreeModelSortClass =
  result = cast[PTreeModelSortClass](CHECK_GET_CLASS(obj, TYPE_TREE_MODEL_SORT()))

proc TYPE_LIST_STORE*(): GType =
  result = list_store_get_type()

proc LIST_STORE*(obj: pointer): PListStore =
  result = cast[PListStore](CHECK_CAST(obj, TYPE_LIST_STORE()))

proc LIST_STORE_CLASS*(klass: pointer): PListStoreClass =
  result = cast[PListStoreClass](CHECK_CLASS_CAST(klass, TYPE_LIST_STORE()))

proc IS_LIST_STORE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_LIST_STORE())

proc IS_LIST_STORE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_LIST_STORE())

proc LIST_STORE_GET_CLASS*(obj: pointer): PListStoreClass =
  result = cast[PListStoreClass](CHECK_GET_CLASS(obj, TYPE_LIST_STORE()))

proc columns_dirty*(a: PListStore): guint =
  result = (a.ListStoreflag0 and bm_TGtkListStore_columns_dirty) shr
      bp_TGtkListStore_columns_dirty

proc set_columns_dirty*(a: PListStore, `columns_dirty`: guint) =
  a.ListStoreflag0 = a.ListStoreflag0 or
      (int16(`columns_dirty` shl bp_TGtkListStore_columns_dirty) and
      bm_TGtkListStore_columns_dirty)

proc TYPE_MENU_BAR*(): GType =
  result = menu_bar_get_type()

proc MENU_BAR*(obj: pointer): PMenuBar =
  result = cast[PMenuBar](CHECK_CAST(obj, TYPE_MENU_BAR()))

proc MENU_BAR_CLASS*(klass: pointer): PMenuBarClass =
  result = cast[PMenuBarClass](CHECK_CLASS_CAST(klass, TYPE_MENU_BAR()))

proc IS_MENU_BAR*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_MENU_BAR())

proc IS_MENU_BAR_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_MENU_BAR())

proc MENU_BAR_GET_CLASS*(obj: pointer): PMenuBarClass =
  result = cast[PMenuBarClass](CHECK_GET_CLASS(obj, TYPE_MENU_BAR()))

proc menu_bar_append*(menu, child: PWidget) =
  append(cast[PMenuShell](menu), child)

proc menu_bar_prepend*(menu, child: PWidget) =
  prepend(cast[PMenuShell](menu), child)

proc menu_bar_insert*(menu, child: PWidget, pos: gint) =
  insert(cast[PMenuShell](menu), child, pos)

proc TYPE_MESSAGE_DIALOG*(): GType =
  result = message_dialog_get_type()

proc MESSAGE_DIALOG*(obj: pointer): PMessageDialog =
  result = cast[PMessageDialog](CHECK_CAST(obj, TYPE_MESSAGE_DIALOG()))

proc MESSAGE_DIALOG_CLASS*(klass: pointer): PMessageDialogClass =
  result = cast[PMessageDialogClass](CHECK_CLASS_CAST(klass,
      TYPE_MESSAGE_DIALOG()))

proc IS_MESSAGE_DIALOG*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_MESSAGE_DIALOG())

proc IS_MESSAGE_DIALOG_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_MESSAGE_DIALOG())

proc MESSAGE_DIALOG_GET_CLASS*(obj: pointer): PMessageDialogClass =
  result = cast[PMessageDialogClass](CHECK_GET_CLASS(obj, TYPE_MESSAGE_DIALOG()))

proc TYPE_NOTEBOOK*(): GType =
  result = notebook_get_type()

proc NOTEBOOK*(obj: pointer): PNotebook =
  result = cast[PNotebook](CHECK_CAST(obj, TYPE_NOTEBOOK()))

proc NOTEBOOK_CLASS*(klass: pointer): PNotebookClass =
  result = cast[PNotebookClass](CHECK_CLASS_CAST(klass, TYPE_NOTEBOOK()))

proc IS_NOTEBOOK*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_NOTEBOOK())

proc IS_NOTEBOOK_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_NOTEBOOK())

proc NOTEBOOK_GET_CLASS*(obj: pointer): PNotebookClass =
  result = cast[PNotebookClass](CHECK_GET_CLASS(obj, TYPE_NOTEBOOK()))

proc show_tabs*(a: PNotebook): guint =
  result = (a.Notebookflag0 and bm_TGtkNotebook_show_tabs) shr
      bp_TGtkNotebook_show_tabs

proc set_show_tabs*(a: PNotebook, `show_tabs`: guint) =
  a.Notebookflag0 = a.Notebookflag0 or
      (int16(`show_tabs` shl bp_TGtkNotebook_show_tabs) and
      bm_TGtkNotebook_show_tabs)

proc homogeneous*(a: PNotebook): guint =
  result = (a.Notebookflag0 and bm_TGtkNotebook_homogeneous) shr
      bp_TGtkNotebook_homogeneous

proc set_homogeneous*(a: PNotebook, `homogeneous`: guint) =
  a.Notebookflag0 = a.Notebookflag0 or
      (int16(`homogeneous` shl bp_TGtkNotebook_homogeneous) and
      bm_TGtkNotebook_homogeneous)

proc show_border*(a: PNotebook): guint =
  result = (a.Notebookflag0 and bm_TGtkNotebook_show_border) shr
      bp_TGtkNotebook_show_border

proc set_show_border*(a: PNotebook, `show_border`: guint) =
  a.Notebookflag0 = a.Notebookflag0 or
      (int16(`show_border` shl bp_TGtkNotebook_show_border) and
      bm_TGtkNotebook_show_border)

proc tab_pos*(a: PNotebook): guint =
  result = (a.Notebookflag0 and bm_TGtkNotebook_tab_pos) shr
      bp_TGtkNotebook_tab_pos

proc set_tab_pos*(a: PNotebook, `tab_pos`: guint) =
  a.Notebookflag0 = a.Notebookflag0 or
      (int16(`tab_pos` shl bp_TGtkNotebook_tab_pos) and
      bm_TGtkNotebook_tab_pos)

proc scrollable*(a: PNotebook): guint =
  result = (a.Notebookflag0 and bm_TGtkNotebook_scrollable) shr
      bp_TGtkNotebook_scrollable

proc set_scrollable*(a: PNotebook, `scrollable`: guint) =
  a.Notebookflag0 = a.Notebookflag0 or
      (int16(`scrollable` shl bp_TGtkNotebook_scrollable) and
      bm_TGtkNotebook_scrollable)

proc in_child*(a: PNotebook): guint =
  result = (a.Notebookflag0 and bm_TGtkNotebook_in_child) shr
      bp_TGtkNotebook_in_child

proc set_in_child*(a: PNotebook, `in_child`: guint) =
  a.Notebookflag0 = a.Notebookflag0 or
      (int16(`in_child` shl bp_TGtkNotebook_in_child) and
      bm_TGtkNotebook_in_child)

proc click_child*(a: PNotebook): guint =
  result = (a.Notebookflag0 and bm_TGtkNotebook_click_child) shr
      bp_TGtkNotebook_click_child

proc set_click_child*(a: PNotebook, `click_child`: guint) =
  a.Notebookflag0 = a.Notebookflag0 or
      (int16(`click_child` shl bp_TGtkNotebook_click_child) and
      bm_TGtkNotebook_click_child)

proc button*(a: PNotebook): guint =
  result = (a.Notebookflag0 and bm_TGtkNotebook_button) shr
      bp_TGtkNotebook_button

proc set_button*(a: PNotebook, `button`: guint) =
  a.Notebookflag0 = a.Notebookflag0 or
      (int16(`button` shl bp_TGtkNotebook_button) and bm_TGtkNotebook_button)

proc need_timer*(a: PNotebook): guint =
  result = (a.Notebookflag0 and bm_TGtkNotebook_need_timer) shr
      bp_TGtkNotebook_need_timer

proc set_need_timer*(a: PNotebook, `need_timer`: guint) =
  a.Notebookflag0 = a.Notebookflag0 or
      (int16(`need_timer` shl bp_TGtkNotebook_need_timer) and
      bm_TGtkNotebook_need_timer)

proc child_has_focus*(a: PNotebook): guint =
  result = (a.Notebookflag0 and bm_TGtkNotebook_child_has_focus) shr
      bp_TGtkNotebook_child_has_focus

proc set_child_has_focus*(a: PNotebook, `child_has_focus`: guint) =
  a.Notebookflag0 = a.Notebookflag0 or
      (int16(`child_has_focus` shl bp_TGtkNotebook_child_has_focus) and
      bm_TGtkNotebook_child_has_focus)

proc have_visible_child*(a: PNotebook): guint =
  result = (a.Notebookflag0 and bm_TGtkNotebook_have_visible_child) shr
      bp_TGtkNotebook_have_visible_child

proc set_have_visible_child*(a: PNotebook, `have_visible_child`: guint) =
  a.Notebookflag0 = a.Notebookflag0 or
      (int16(`have_visible_child` shl bp_TGtkNotebook_have_visible_child) and
      bm_TGtkNotebook_have_visible_child)

proc focus_out*(a: PNotebook): guint =
  result = (a.Notebookflag0 and bm_TGtkNotebook_focus_out) shr
      bp_TGtkNotebook_focus_out

proc set_focus_out*(a: PNotebook, `focus_out`: guint) =
  a.Notebookflag0 = a.Notebookflag0 or
      (int16(`focus_out` shl bp_TGtkNotebook_focus_out) and
      bm_TGtkNotebook_focus_out)

proc TYPE_OLD_EDITABLE*(): GType =
  result = old_editable_get_type()

proc OLD_EDITABLE*(obj: pointer): POldEditable =
  result = cast[POldEditable](CHECK_CAST(obj, TYPE_OLD_EDITABLE()))

proc OLD_EDITABLE_CLASS*(klass: pointer): POldEditableClass =
  result = cast[POldEditableClass](CHECK_CLASS_CAST(klass, TYPE_OLD_EDITABLE()))

proc IS_OLD_EDITABLE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_OLD_EDITABLE())

proc IS_OLD_EDITABLE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_OLD_EDITABLE())

proc OLD_EDITABLE_GET_CLASS*(obj: pointer): POldEditableClass =
  result = cast[POldEditableClass](CHECK_GET_CLASS(obj, TYPE_OLD_EDITABLE()))

proc has_selection*(a: POldEditable): guint =
  result = (a.OldEditableflag0 and bm_TGtkOldEditable_has_selection) shr
      bp_TGtkOldEditable_has_selection

proc set_has_selection*(a: POldEditable, `has_selection`: guint) =
  a.OldEditableflag0 = a.OldEditableflag0 or
      (int16(`has_selection` shl bp_TGtkOldEditable_has_selection) and
      bm_TGtkOldEditable_has_selection)

proc editable*(a: POldEditable): guint =
  result = (a.OldEditableflag0 and bm_TGtkOldEditable_editable) shr
      bp_TGtkOldEditable_editable

proc set_editable*(a: POldEditable, `editable`: guint) =
  a.OldEditableflag0 = a.OldEditableflag0 or
      (int16(`editable` shl bp_TGtkOldEditable_editable) and
      bm_TGtkOldEditable_editable)

proc visible*(a: POldEditable): guint =
  result = (a.OldEditableflag0 and bm_TGtkOldEditable_visible) shr
      bp_TGtkOldEditable_visible

proc set_visible*(a: POldEditable, `visible`: guint) =
  a.OldEditableflag0 = a.OldEditableflag0 or
      (int16(`visible` shl bp_TGtkOldEditable_visible) and
      bm_TGtkOldEditable_visible)

proc TYPE_OPTION_MENU*(): GType =
  result = option_menu_get_type()

proc OPTION_MENU*(obj: pointer): POptionMenu =
  result = cast[POptionMenu](CHECK_CAST(obj, TYPE_OPTION_MENU()))

proc OPTION_MENU_CLASS*(klass: pointer): POptionMenuClass =
  result = cast[POptionMenuClass](CHECK_CLASS_CAST(klass, TYPE_OPTION_MENU()))

proc IS_OPTION_MENU*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_OPTION_MENU())

proc IS_OPTION_MENU_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_OPTION_MENU())

proc OPTION_MENU_GET_CLASS*(obj: pointer): POptionMenuClass =
  result = cast[POptionMenuClass](CHECK_GET_CLASS(obj, TYPE_OPTION_MENU()))

proc TYPE_PIXMAP*(): GType =
  result = gtk2.pixmap_get_type()

proc PIXMAP*(obj: pointer): PPixmap =
  result = cast[PPixmap](CHECK_CAST(obj, gtk2.TYPE_PIXMAP()))

proc PIXMAP_CLASS*(klass: pointer): PPixmapClass =
  result = cast[PPixmapClass](CHECK_CLASS_CAST(klass, gtk2.TYPE_PIXMAP()))

proc IS_PIXMAP*(obj: pointer): bool =
  result = CHECK_TYPE(obj, gtk2.TYPE_PIXMAP())

proc IS_PIXMAP_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, gtk2.TYPE_PIXMAP())

proc PIXMAP_GET_CLASS*(obj: pointer): PPixmapClass =
  result = cast[PPixmapClass](CHECK_GET_CLASS(obj, gtk2.TYPE_PIXMAP()))

proc build_insensitive*(a: PPixmap): guint =
  result = (a.Pixmapflag0 and bm_TGtkPixmap_build_insensitive) shr
      bp_TGtkPixmap_build_insensitive

proc set_build_insensitive*(a: PPixmap, `build_insensitive`: guint) =
  a.Pixmapflag0 = a.Pixmapflag0 or
      (int16(`build_insensitive` shl bp_TGtkPixmap_build_insensitive) and
      bm_TGtkPixmap_build_insensitive)

proc TYPE_PLUG*(): GType =
  result = plug_get_type()

proc PLUG*(obj: pointer): PPlug =
  result = cast[PPlug](CHECK_CAST(obj, TYPE_PLUG()))

proc PLUG_CLASS*(klass: pointer): PPlugClass =
  result = cast[PPlugClass](CHECK_CLASS_CAST(klass, TYPE_PLUG()))

proc IS_PLUG*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_PLUG())

proc IS_PLUG_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_PLUG())

proc PLUG_GET_CLASS*(obj: pointer): PPlugClass =
  result = cast[PPlugClass](CHECK_GET_CLASS(obj, TYPE_PLUG()))

proc same_app*(a: PPlug): guint =
  result = (a.Plugflag0 and bm_TGtkPlug_same_app) shr bp_TGtkPlug_same_app

proc set_same_app*(a: PPlug, `same_app`: guint) =
  a.Plugflag0 = a.Plugflag0 or
      (int16(`same_app` shl bp_TGtkPlug_same_app) and bm_TGtkPlug_same_app)

proc TYPE_PREVIEW*(): GType =
  result = preview_get_type()

proc PREVIEW*(obj: pointer): PPreview =
  result = cast[PPreview](CHECK_CAST(obj, TYPE_PREVIEW()))

proc PREVIEW_CLASS*(klass: pointer): PPreviewClass =
  result = cast[PPreviewClass](CHECK_CLASS_CAST(klass, TYPE_PREVIEW()))

proc IS_PREVIEW*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_PREVIEW())

proc IS_PREVIEW_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_PREVIEW())

proc PREVIEW_GET_CLASS*(obj: pointer): PPreviewClass =
  result = cast[PPreviewClass](CHECK_GET_CLASS(obj, TYPE_PREVIEW()))

proc get_type*(a: PPreview): guint =
  result = (a.Previewflag0 and bm_TGtkPreview_type) shr bp_TGtkPreview_type

proc set_type*(a: PPreview, `type`: guint) =
  a.Previewflag0 = a.Previewflag0 or
      (int16(`type` shl bp_TGtkPreview_type) and bm_TGtkPreview_type)

proc get_expand*(a: PPreview): guint =
  result = (a.Previewflag0 and bm_TGtkPreview_expand) shr
      bp_TGtkPreview_expand

proc set_expand*(a: PPreview, `expand`: guint) =
  a.Previewflag0 = a.Previewflag0 or
      (int16(`expand` shl bp_TGtkPreview_expand) and bm_TGtkPreview_expand)

proc progress_get_type(): GType{.importc: "gtk_progress_get_type", cdecl,
                                 dynlib: lib.}
proc TYPE_PROGRESS*(): GType =
  result = progress_get_type()

proc PROGRESS*(obj: pointer): PProgress =
  result = cast[PProgress](CHECK_CAST(obj, TYPE_PROGRESS()))

proc PROGRESS_CLASS*(klass: pointer): PProgressClass =
  result = cast[PProgressClass](CHECK_CLASS_CAST(klass, TYPE_PROGRESS()))

proc IS_PROGRESS*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_PROGRESS())

proc IS_PROGRESS_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_PROGRESS())

proc PROGRESS_GET_CLASS*(obj: pointer): PProgressClass =
  result = cast[PProgressClass](CHECK_GET_CLASS(obj, TYPE_PROGRESS()))

proc show_text*(a: PProgress): guint =
  result = (a.Progressflag0 and bm_TGtkProgress_show_text) shr
      bp_TGtkProgress_show_text

proc set_show_text*(a: PProgress, `show_text`: guint) =
  a.Progressflag0 = a.Progressflag0 or
      (int16(`show_text` shl bp_TGtkProgress_show_text) and
      bm_TGtkProgress_show_text)

proc activity_mode*(a: PProgress): guint =
  result = (a.Progressflag0 and bm_TGtkProgress_activity_mode) shr
      bp_TGtkProgress_activity_mode

proc set_activity_mode*(a: PProgress, `activity_mode`: guint) =
  a.Progressflag0 = a.Progressflag0 or
      (int16(`activity_mode` shl bp_TGtkProgress_activity_mode) and
      bm_TGtkProgress_activity_mode)

proc use_text_format*(a: PProgress): guint =
  result = (a.Progressflag0 and bm_TGtkProgress_use_text_format) shr
      bp_TGtkProgress_use_text_format

proc set_use_text_format*(a: PProgress, `use_text_format`: guint) =
  a.Progressflag0 = a.Progressflag0 or
      (int16(`use_text_format` shl bp_TGtkProgress_use_text_format) and
      bm_TGtkProgress_use_text_format)

proc TYPE_PROGRESS_BAR*(): GType =
  result = progress_bar_get_type()

proc PROGRESS_BAR*(obj: pointer): PProgressBar =
  result = cast[PProgressBar](CHECK_CAST(obj, TYPE_PROGRESS_BAR()))

proc PROGRESS_BAR_CLASS*(klass: pointer): PProgressBarClass =
  result = cast[PProgressBarClass](CHECK_CLASS_CAST(klass, TYPE_PROGRESS_BAR()))

proc IS_PROGRESS_BAR*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_PROGRESS_BAR())

proc IS_PROGRESS_BAR_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_PROGRESS_BAR())

proc PROGRESS_BAR_GET_CLASS*(obj: pointer): PProgressBarClass =
  result = cast[PProgressBarClass](CHECK_GET_CLASS(obj, TYPE_PROGRESS_BAR()))

proc activity_dir*(a: PProgressBar): guint =
  result = (a.ProgressBarflag0 and bm_TGtkProgressBar_activity_dir) shr
      bp_TGtkProgressBar_activity_dir

proc set_activity_dir*(a: PProgressBar, `activity_dir`: guint) =
  a.ProgressBarflag0 = a.ProgressBarflag0 or
      (int16(`activity_dir` shl bp_TGtkProgressBar_activity_dir) and
      bm_TGtkProgressBar_activity_dir)

proc TYPE_RADIO_BUTTON*(): GType =
  result = radio_button_get_type()

proc RADIO_BUTTON*(obj: pointer): PRadioButton =
  result = cast[PRadioButton](CHECK_CAST(obj, TYPE_RADIO_BUTTON()))

proc RADIO_BUTTON_CLASS*(klass: pointer): PRadioButtonClass =
  result = cast[PRadioButtonClass](CHECK_CLASS_CAST(klass, TYPE_RADIO_BUTTON()))

proc IS_RADIO_BUTTON*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_RADIO_BUTTON())

proc IS_RADIO_BUTTON_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_RADIO_BUTTON())

proc RADIO_BUTTON_GET_CLASS*(obj: pointer): PRadioButtonClass =
  result = cast[PRadioButtonClass](CHECK_GET_CLASS(obj, TYPE_RADIO_BUTTON()))

proc TYPE_RADIO_MENU_ITEM*(): GType =
  result = radio_menu_item_get_type()

proc RADIO_MENU_ITEM*(obj: pointer): PRadioMenuItem =
  result = cast[PRadioMenuItem](CHECK_CAST(obj, TYPE_RADIO_MENU_ITEM()))

proc RADIO_MENU_ITEM_CLASS*(klass: pointer): PRadioMenuItemClass =
  result = cast[PRadioMenuItemClass](CHECK_CLASS_CAST(klass,
      TYPE_RADIO_MENU_ITEM()))

proc IS_RADIO_MENU_ITEM*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_RADIO_MENU_ITEM())

proc IS_RADIO_MENU_ITEM_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_RADIO_MENU_ITEM())

proc RADIO_MENU_ITEM_GET_CLASS*(obj: pointer): PRadioMenuItemClass =
  result = cast[PRadioMenuItemClass](CHECK_GET_CLASS(obj, TYPE_RADIO_MENU_ITEM()))

proc TYPE_SCROLLED_WINDOW*(): GType =
  result = scrolled_window_get_type()

proc SCROLLED_WINDOW*(obj: pointer): PScrolledWindow =
  result = cast[PScrolledWindow](CHECK_CAST(obj, TYPE_SCROLLED_WINDOW()))

proc SCROLLED_WINDOW_CLASS*(klass: pointer): PScrolledWindowClass =
  result = cast[PScrolledWindowClass](CHECK_CLASS_CAST(klass,
      TYPE_SCROLLED_WINDOW()))

proc IS_SCROLLED_WINDOW*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_SCROLLED_WINDOW())

proc IS_SCROLLED_WINDOW_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_SCROLLED_WINDOW())

proc SCROLLED_WINDOW_GET_CLASS*(obj: pointer): PScrolledWindowClass =
  result = cast[PScrolledWindowClass](CHECK_GET_CLASS(obj,
      TYPE_SCROLLED_WINDOW()))

proc hscrollbar_policy*(a: PScrolledWindow): guint =
  result = (a.ScrolledWindowflag0 and bm_TGtkScrolledWindow_hscrollbar_policy) shr
      bp_TGtkScrolledWindow_hscrollbar_policy

proc set_hscrollbar_policy*(a: PScrolledWindow, `hscrollbar_policy`: guint) =
  a.ScrolledWindowflag0 = a.ScrolledWindowflag0 or
      (int16(`hscrollbar_policy` shl bp_TGtkScrolledWindow_hscrollbar_policy) and
      bm_TGtkScrolledWindow_hscrollbar_policy)

proc vscrollbar_policy*(a: PScrolledWindow): guint =
  result = (a.ScrolledWindowflag0 and bm_TGtkScrolledWindow_vscrollbar_policy) shr
      bp_TGtkScrolledWindow_vscrollbar_policy

proc set_vscrollbar_policy*(a: PScrolledWindow, `vscrollbar_policy`: guint) =
  a.ScrolledWindowflag0 = a.ScrolledWindowflag0 or
      (int16(`vscrollbar_policy` shl bp_TGtkScrolledWindow_vscrollbar_policy) and
      bm_TGtkScrolledWindow_vscrollbar_policy)

proc hscrollbar_visible*(a: PScrolledWindow): guint =
  result = (a.ScrolledWindowflag0 and
      bm_TGtkScrolledWindow_hscrollbar_visible) shr
      bp_TGtkScrolledWindow_hscrollbar_visible

proc set_hscrollbar_visible*(a: PScrolledWindow, `hscrollbar_visible`: guint) =
  a.ScrolledWindowflag0 = a.ScrolledWindowflag0 or
      (int16(`hscrollbar_visible` shl
      bp_TGtkScrolledWindow_hscrollbar_visible) and
      bm_TGtkScrolledWindow_hscrollbar_visible)

proc vscrollbar_visible*(a: PScrolledWindow): guint =
  result = (a.ScrolledWindowflag0 and
      bm_TGtkScrolledWindow_vscrollbar_visible) shr
      bp_TGtkScrolledWindow_vscrollbar_visible

proc set_vscrollbar_visible*(a: PScrolledWindow, `vscrollbar_visible`: guint) =
  a.ScrolledWindowflag0 = a.ScrolledWindowflag0 or
      int16((`vscrollbar_visible` shl
      bp_TGtkScrolledWindow_vscrollbar_visible) and
      bm_TGtkScrolledWindow_vscrollbar_visible)

proc window_placement*(a: PScrolledWindow): guint =
  result = (a.ScrolledWindowflag0 and bm_TGtkScrolledWindow_window_placement) shr
      bp_TGtkScrolledWindow_window_placement

proc set_window_placement*(a: PScrolledWindow, `window_placement`: guint) =
  a.ScrolledWindowflag0 = a.ScrolledWindowflag0 or
      (int16(`window_placement` shl bp_TGtkScrolledWindow_window_placement) and
      bm_TGtkScrolledWindow_window_placement)

proc focus_out*(a: PScrolledWindow): guint =
  result = (a.ScrolledWindowflag0 and bm_TGtkScrolledWindow_focus_out) shr
      bp_TGtkScrolledWindow_focus_out

proc set_focus_out*(a: PScrolledWindow, `focus_out`: guint) =
  a.ScrolledWindowflag0 = a.ScrolledWindowflag0 or
      (int16(`focus_out` shl bp_TGtkScrolledWindow_focus_out) and
      bm_TGtkScrolledWindow_focus_out)

proc TYPE_SELECTION_DATA*(): GType =
  result = selection_data_get_type()

proc TYPE_SEPARATOR_MENU_ITEM*(): GType =
  result = separator_menu_item_get_type()

proc SEPARATOR_MENU_ITEM*(obj: pointer): PSeparatorMenuItem =
  result = cast[PSeparatorMenuItem](CHECK_CAST(obj, TYPE_SEPARATOR_MENU_ITEM()))

proc SEPARATOR_MENU_ITEM_CLASS*(klass: pointer): PSeparatorMenuItemClass =
  result = cast[PSeparatorMenuItemClass](CHECK_CLASS_CAST(klass,
      TYPE_SEPARATOR_MENU_ITEM()))

proc IS_SEPARATOR_MENU_ITEM*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_SEPARATOR_MENU_ITEM())

proc IS_SEPARATOR_MENU_ITEM_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_SEPARATOR_MENU_ITEM())

proc SEPARATOR_MENU_ITEM_GET_CLASS*(obj: pointer): PSeparatorMenuItemClass =
  result = cast[PSeparatorMenuItemClass](CHECK_GET_CLASS(obj,
      TYPE_SEPARATOR_MENU_ITEM()))

proc signal_lookup*(name: cstring, object_type: GType): guint =
  result = g_signal_lookup(name, object_type)

proc signal_name*(signal_id: guint): cstring =
  result = g_signal_name(signal_id)

proc signal_emit_stop*(instance: gpointer, signal_id: guint, detail: TGQuark) =
  if detail != 0'i32: g_signal_stop_emission(instance, signal_id, 0)

proc signal_connect_full*(anObject: PObject, name: cstring, fun: TSignalFunc,
                          unknown1: pointer, func_data: gpointer,
                          unknown2: pointer, unknown3, unknown4: int): gulong{.
    importc: "gtk_signal_connect_full", cdecl, dynlib: lib.}
proc signal_compat_matched*(anObject: PObject, fun: TSignalFunc,
                            data: gpointer, m: TGSignalMatchType, u: int){.
    importc: "gtk_signal_compat_matched", cdecl, dynlib: lib.}
proc signal_connect*(anObject: PObject, name: cstring, fun: TSignalFunc,
                     func_data: gpointer): gulong =
  result = signal_connect_full(anObject, name, fun, nil, func_data, nil, 0, 0)

proc signal_connect_after*(anObject: PObject, name: cstring, fun: TSignalFunc,
                           func_data: gpointer): gulong =
  result = signal_connect_full(anObject, name, fun, nil, func_data, nil, 0, 1)

proc signal_connect_object*(anObject: PObject, name: cstring,
                            fun: TSignalFunc, slot_object: gpointer): gulong =
  result = signal_connect_full(anObject, name, fun, nil, slot_object, nil, 1,
                               0)

proc signal_connect_object_after*(anObject: PObject, name: cstring,
                                  fun: TSignalFunc, slot_object: gpointer): gulong =
  result = signal_connect_full(anObject, name, fun, nil, slot_object, nil, 1,
                               1)

proc signal_disconnect*(anObject: gpointer, handler_id: gulong) =
  g_signal_handler_disconnect(anObject, handler_id)

proc signal_handler_block*(anObject: gpointer, handler_id: gulong) =
  g_signal_handler_block(anObject, handler_id)

proc signal_handler_unblock*(anObject: gpointer, handler_id: gulong) =
  g_signal_handler_unblock(anObject, handler_id)

proc signal_disconnect_by_data*(anObject: PObject, data: gpointer) =
  signal_compat_matched(anObject, nil, data, G_SIGNAL_MATCH_DATA, 0)

proc signal_disconnect_by_func*(anObject: PObject, fun: TSignalFunc,
                                data: gpointer) =
  signal_compat_matched(anObject, fun, data, cast[TGSignalMatchType](G_SIGNAL_MATCH_FUNC or
      G_SIGNAL_MATCH_DATA), 0)

proc signal_handler_block_by_func*(anObject: PObject, fun: TSignalFunc,
                                   data: gpointer) =
  signal_compat_matched(anObject, fun, data, TGSignalMatchType(
      G_SIGNAL_MATCH_FUNC or G_SIGNAL_MATCH_DATA), 0)

proc signal_handler_block_by_data*(anObject: PObject, data: gpointer) =
  signal_compat_matched(anObject, nil, data, G_SIGNAL_MATCH_DATA, 1)

proc signal_handler_unblock_by_func*(anObject: PObject, fun: TSignalFunc,
                                     data: gpointer) =
  signal_compat_matched(anObject, fun, data, cast[TGSignalMatchType](G_SIGNAL_MATCH_FUNC or
      G_SIGNAL_MATCH_DATA), 0)

proc signal_handler_unblock_by_data*(anObject: PObject, data: gpointer) =
  signal_compat_matched(anObject, nil, data, G_SIGNAL_MATCH_DATA, 2)

proc signal_handler_pending*(anObject: PObject, signal_id: guint,
                             may_be_blocked: gboolean): gboolean =
  Result = g_signal_has_handler_pending(anObject, signal_id, 0, may_be_blocked)

proc signal_handler_pending_by_func*(anObject: PObject, signal_id: guint,
                                     may_be_blocked: gboolean,
                                     fun: TSignalFunc,
                                     data: gpointer): gboolean =
  var T: TGSignalMatchType
  t = cast[TGSignalMatchType](G_SIGNAL_MATCH_ID or G_SIGNAL_MATCH_FUNC or
      G_SIGNAL_MATCH_DATA)
  if not may_be_blocked:
    t = t or cast[TGSignalMatchType](G_SIGNAL_MATCH_UNBLOCKED)
  Result = g_signal_handler_find(anObject, t, signal_id, 0, nil, fun, data) !=
      0

proc TYPE_SIZE_GROUP*(): GType =
  result = size_group_get_type()

proc SIZE_GROUP*(obj: pointer): PSizeGroup =
  result = cast[PSizeGroup](CHECK_CAST(obj, TYPE_SIZE_GROUP()))

proc SIZE_GROUP_CLASS*(klass: pointer): PSizeGroupClass =
  result = cast[PSizeGroupClass](CHECK_CLASS_CAST(klass, TYPE_SIZE_GROUP()))

proc IS_SIZE_GROUP*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_SIZE_GROUP())

proc IS_SIZE_GROUP_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_SIZE_GROUP())

proc SIZE_GROUP_GET_CLASS*(obj: pointer): PSizeGroupClass =
  result = cast[PSizeGroupClass](CHECK_GET_CLASS(obj, TYPE_SIZE_GROUP()))

proc have_width*(a: PSizeGroup): guint =
  result = (a.SizeGroupflag0 and bm_TGtkSizeGroup_have_width) shr
      bp_TGtkSizeGroup_have_width

proc set_have_width*(a: PSizeGroup, `have_width`: guint) =
  a.SizeGroupflag0 = a.SizeGroupflag0 or
      (int16(`have_width` shl bp_TGtkSizeGroup_have_width) and
      bm_TGtkSizeGroup_have_width)

proc have_height*(a: PSizeGroup): guint =
  result = (a.SizeGroupflag0 and bm_TGtkSizeGroup_have_height) shr
      bp_TGtkSizeGroup_have_height

proc set_have_height*(a: PSizeGroup, `have_height`: guint) =
  a.SizeGroupflag0 = a.SizeGroupflag0 or
      (int16(`have_height` shl bp_TGtkSizeGroup_have_height) and
      bm_TGtkSizeGroup_have_height)

proc TYPE_SOCKET*(): GType =
  result = socket_get_type()

proc SOCKET*(obj: pointer): PSocket =
  result = cast[PSocket](CHECK_CAST(obj, TYPE_SOCKET()))

proc SOCKET_CLASS*(klass: pointer): PSocketClass =
  result = cast[PSocketClass](CHECK_CLASS_CAST(klass, TYPE_SOCKET()))

proc IS_SOCKET*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_SOCKET())

proc IS_SOCKET_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_SOCKET())

proc SOCKET_GET_CLASS*(obj: pointer): PSocketClass =
  result = cast[PSocketClass](CHECK_GET_CLASS(obj, TYPE_SOCKET()))

proc same_app*(a: PSocket): guint =
  result = (a.Socketflag0 and bm_TGtkSocket_same_app) shr
      bp_TGtkSocket_same_app

proc set_same_app*(a: PSocket, `same_app`: guint) =
  a.Socketflag0 = a.Socketflag0 or
      (int16(`same_app` shl bp_TGtkSocket_same_app) and
      bm_TGtkSocket_same_app)

proc focus_in*(a: PSocket): guint =
  result = (a.Socketflag0 and bm_TGtkSocket_focus_in) shr
      bp_TGtkSocket_focus_in

proc set_focus_in*(a: PSocket, `focus_in`: guint) =
  a.Socketflag0 = a.Socketflag0 or
      (int16(`focus_in` shl bp_TGtkSocket_focus_in) and
      bm_TGtkSocket_focus_in)

proc have_size*(a: PSocket): guint =
  result = (a.Socketflag0 and bm_TGtkSocket_have_size) shr
      bp_TGtkSocket_have_size

proc set_have_size*(a: PSocket, `have_size`: guint) =
  a.Socketflag0 = a.Socketflag0 or
      (int16(`have_size` shl bp_TGtkSocket_have_size) and
      bm_TGtkSocket_have_size)

proc need_map*(a: PSocket): guint =
  result = (a.Socketflag0 and bm_TGtkSocket_need_map) shr
      bp_TGtkSocket_need_map

proc set_need_map*(a: PSocket, `need_map`: guint) =
  a.Socketflag0 = a.Socketflag0 or
      (int16(`need_map` shl bp_TGtkSocket_need_map) and
      bm_TGtkSocket_need_map)

proc is_mapped*(a: PSocket): guint =
  result = (a.Socketflag0 and bm_TGtkSocket_is_mapped) shr
      bp_TGtkSocket_is_mapped

proc set_is_mapped*(a: PSocket, `is_mapped`: guint) =
  a.Socketflag0 = a.Socketflag0 or
      (int16(`is_mapped` shl bp_TGtkSocket_is_mapped) and
      bm_TGtkSocket_is_mapped)

proc TYPE_SPIN_BUTTON*(): GType =
  result = spin_button_get_type()

proc SPIN_BUTTON*(obj: pointer): PSpinButton =
  result = cast[PSpinButton](CHECK_CAST(obj, TYPE_SPIN_BUTTON()))

proc SPIN_BUTTON_CLASS*(klass: pointer): PSpinButtonClass =
  result = cast[PSpinButtonClass](CHECK_CLASS_CAST(klass, TYPE_SPIN_BUTTON()))

proc IS_SPIN_BUTTON*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_SPIN_BUTTON())

proc IS_SPIN_BUTTON_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_SPIN_BUTTON())

proc SPIN_BUTTON_GET_CLASS*(obj: pointer): PSpinButtonClass =
  result = cast[PSpinButtonClass](CHECK_GET_CLASS(obj, TYPE_SPIN_BUTTON()))

proc in_child*(a: PSpinButton): guint =
  result = (a.SpinButtonflag0 and bm_TGtkSpinButton_in_child) shr
      bp_TGtkSpinButton_in_child

proc set_in_child*(a: PSpinButton, `in_child`: guint) =
  a.SpinButtonflag0 = a.SpinButtonflag0 or
      ((`in_child` shl bp_TGtkSpinButton_in_child) and
      bm_TGtkSpinButton_in_child)

proc click_child*(a: PSpinButton): guint =
  result = (a.SpinButtonflag0 and bm_TGtkSpinButton_click_child) shr
      bp_TGtkSpinButton_click_child

proc set_click_child*(a: PSpinButton, `click_child`: guint) =
  a.SpinButtonflag0 = a.SpinButtonflag0 or
      ((`click_child` shl bp_TGtkSpinButton_click_child) and
      bm_TGtkSpinButton_click_child)

proc button*(a: PSpinButton): guint =
  result = (a.SpinButtonflag0 and bm_TGtkSpinButton_button) shr
      bp_TGtkSpinButton_button

proc set_button*(a: PSpinButton, `button`: guint) =
  a.SpinButtonflag0 = a.SpinButtonflag0 or
      ((`button` shl bp_TGtkSpinButton_button) and bm_TGtkSpinButton_button)

proc need_timer*(a: PSpinButton): guint =
  result = (a.SpinButtonflag0 and bm_TGtkSpinButton_need_timer) shr
      bp_TGtkSpinButton_need_timer

proc set_need_timer*(a: PSpinButton, `need_timer`: guint) =
  a.SpinButtonflag0 = a.SpinButtonflag0 or
      ((`need_timer` shl bp_TGtkSpinButton_need_timer) and
      bm_TGtkSpinButton_need_timer)

proc timer_calls*(a: PSpinButton): guint =
  result = (a.SpinButtonflag0 and bm_TGtkSpinButton_timer_calls) shr
      bp_TGtkSpinButton_timer_calls

proc set_timer_calls*(a: PSpinButton, `timer_calls`: guint) =
  a.SpinButtonflag0 = a.SpinButtonflag0 or
      ((`timer_calls` shl bp_TGtkSpinButton_timer_calls) and
      bm_TGtkSpinButton_timer_calls)

proc digits*(a: PSpinButton): guint =
  result = (a.SpinButtonflag0 and bm_TGtkSpinButton_digits) shr
      bp_TGtkSpinButton_digits

proc set_digits*(a: PSpinButton, `digits`: guint) =
  a.SpinButtonflag0 = a.SpinButtonflag0 or
      ((`digits` shl bp_TGtkSpinButton_digits) and bm_TGtkSpinButton_digits)

proc numeric*(a: PSpinButton): guint =
  result = (a.SpinButtonflag0 and bm_TGtkSpinButton_numeric) shr
      bp_TGtkSpinButton_numeric

proc set_numeric*(a: PSpinButton, `numeric`: guint) =
  a.SpinButtonflag0 = a.SpinButtonflag0 or
      ((`numeric` shl bp_TGtkSpinButton_numeric) and
      bm_TGtkSpinButton_numeric)

proc wrap*(a: PSpinButton): guint =
  result = (a.SpinButtonflag0 and bm_TGtkSpinButton_wrap) shr
      bp_TGtkSpinButton_wrap

proc set_wrap*(a: PSpinButton, `wrap`: guint) =
  a.SpinButtonflag0 = a.SpinButtonflag0 or
      ((`wrap` shl bp_TGtkSpinButton_wrap) and bm_TGtkSpinButton_wrap)

proc snap_to_ticks*(a: PSpinButton): guint =
  result = (a.SpinButtonflag0 and bm_TGtkSpinButton_snap_to_ticks) shr
      bp_TGtkSpinButton_snap_to_ticks

proc set_snap_to_ticks*(a: PSpinButton, `snap_to_ticks`: guint) =
  a.SpinButtonflag0 = a.SpinButtonflag0 or
      ((`snap_to_ticks` shl bp_TGtkSpinButton_snap_to_ticks) and
      bm_TGtkSpinButton_snap_to_ticks)

proc TYPE_STATUSBAR*(): GType =
  result = statusbar_get_type()

proc STATUSBAR*(obj: pointer): PStatusbar =
  result = cast[PStatusbar](CHECK_CAST(obj, TYPE_STATUSBAR()))

proc STATUSBAR_CLASS*(klass: pointer): PStatusbarClass =
  result = cast[PStatusbarClass](CHECK_CLASS_CAST(klass, TYPE_STATUSBAR()))

proc IS_STATUSBAR*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_STATUSBAR())

proc IS_STATUSBAR_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_STATUSBAR())

proc STATUSBAR_GET_CLASS*(obj: pointer): PStatusbarClass =
  result = cast[PStatusbarClass](CHECK_GET_CLASS(obj, TYPE_STATUSBAR()))

proc has_resize_grip*(a: PStatusbar): guint =
  result = (a.Statusbarflag0 and bm_TGtkStatusbar_has_resize_grip) shr
      bp_TGtkStatusbar_has_resize_grip

proc set_has_resize_grip*(a: PStatusbar, `has_resize_grip`: guint) =
  a.Statusbarflag0 = a.Statusbarflag0 or
      (int16(`has_resize_grip` shl bp_TGtkStatusbar_has_resize_grip) and
      bm_TGtkStatusbar_has_resize_grip)

proc TYPE_TABLE*(): GType =
  result = gtk2.table_get_type()

proc TABLE*(obj: pointer): PTable =
  result = cast[PTable](CHECK_CAST(obj, gtk2.TYPE_TABLE()))

proc TABLE_CLASS*(klass: pointer): PTableClass =
  result = cast[PTableClass](CHECK_CLASS_CAST(klass, gtk2.TYPE_TABLE()))

proc IS_TABLE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, gtk2.TYPE_TABLE())

proc IS_TABLE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, gtk2.TYPE_TABLE())

proc TABLE_GET_CLASS*(obj: pointer): PTableClass =
  result = cast[PTableClass](CHECK_GET_CLASS(obj, gtk2.TYPE_TABLE()))

proc homogeneous*(a: PTable): guint =
  result = (a.Tableflag0 and bm_TGtkTable_homogeneous) shr
      bp_TGtkTable_homogeneous

proc set_homogeneous*(a: PTable, `homogeneous`: guint) =
  a.Tableflag0 = a.Tableflag0 or
      (int16(`homogeneous` shl bp_TGtkTable_homogeneous) and
      bm_TGtkTable_homogeneous)

proc xexpand*(a: PTableChild): guint =
  result = (a.TableChildflag0 and bm_TGtkTableChild_xexpand) shr
      bp_TGtkTableChild_xexpand

proc set_xexpand*(a: PTableChild, `xexpand`: guint) =
  a.TableChildflag0 = a.TableChildflag0 or
      (int16(`xexpand` shl bp_TGtkTableChild_xexpand) and
      bm_TGtkTableChild_xexpand)

proc yexpand*(a: PTableChild): guint =
  result = (a.TableChildflag0 and bm_TGtkTableChild_yexpand) shr
      bp_TGtkTableChild_yexpand

proc set_yexpand*(a: PTableChild, `yexpand`: guint) =
  a.TableChildflag0 = a.TableChildflag0 or
      (int16(`yexpand` shl bp_TGtkTableChild_yexpand) and
      bm_TGtkTableChild_yexpand)

proc xshrink*(a: PTableChild): guint =
  result = (a.TableChildflag0 and bm_TGtkTableChild_xshrink) shr
      bp_TGtkTableChild_xshrink

proc set_xshrink*(a: PTableChild, `xshrink`: guint) =
  a.TableChildflag0 = a.TableChildflag0 or
      (int16(`xshrink` shl bp_TGtkTableChild_xshrink) and
      bm_TGtkTableChild_xshrink)

proc yshrink*(a: PTableChild): guint =
  result = (a.TableChildflag0 and bm_TGtkTableChild_yshrink) shr
      bp_TGtkTableChild_yshrink

proc set_yshrink*(a: PTableChild, `yshrink`: guint) =
  a.TableChildflag0 = a.TableChildflag0 or
      (int16(`yshrink` shl bp_TGtkTableChild_yshrink) and
      bm_TGtkTableChild_yshrink)

proc xfill*(a: PTableChild): guint =
  result = (a.TableChildflag0 and bm_TGtkTableChild_xfill) shr
      bp_TGtkTableChild_xfill

proc set_xfill*(a: PTableChild, `xfill`: guint) =
  a.TableChildflag0 = a.TableChildflag0 or
      (int16(`xfill` shl bp_TGtkTableChild_xfill) and bm_TGtkTableChild_xfill)

proc yfill*(a: PTableChild): guint =
  result = (a.TableChildflag0 and bm_TGtkTableChild_yfill) shr
      bp_TGtkTableChild_yfill

proc set_yfill*(a: PTableChild, `yfill`: guint) =
  a.TableChildflag0 = a.TableChildflag0 or
      (int16(`yfill` shl bp_TGtkTableChild_yfill) and bm_TGtkTableChild_yfill)

proc need_expand*(a: PTableRowCol): guint =
  result = (a.flag0 and bm_TGtkTableRowCol_need_expand) shr
      bp_TGtkTableRowCol_need_expand

proc set_need_expand*(a: PTableRowCol, `need_expand`: guint) =
  a.flag0 = a.flag0 or
      (int16(`need_expand` shl bp_TGtkTableRowCol_need_expand) and
      bm_TGtkTableRowCol_need_expand)

proc need_shrink*(a: PTableRowCol): guint =
  result = (a.flag0 and bm_TGtkTableRowCol_need_shrink) shr
      bp_TGtkTableRowCol_need_shrink

proc set_need_shrink*(a: PTableRowCol, `need_shrink`: guint) =
  a.flag0 = a.flag0 or
      (int16(`need_shrink` shl bp_TGtkTableRowCol_need_shrink) and
      bm_TGtkTableRowCol_need_shrink)

proc expand*(a: PTableRowCol): guint =
  result = (a.flag0 and bm_TGtkTableRowCol_expand) shr
      bp_TGtkTableRowCol_expand

proc set_expand*(a: PTableRowCol, `expand`: guint) =
  a.flag0 = a.flag0 or
      (int16(`expand` shl bp_TGtkTableRowCol_expand) and
      bm_TGtkTableRowCol_expand)

proc shrink*(a: PTableRowCol): guint =
  result = (a.flag0 and bm_TGtkTableRowCol_shrink) shr
      bp_TGtkTableRowCol_shrink

proc set_shrink*(a: PTableRowCol, `shrink`: guint) =
  a.flag0 = a.flag0 or
      (int16(`shrink` shl bp_TGtkTableRowCol_shrink) and
      bm_TGtkTableRowCol_shrink)

proc empty*(a: PTableRowCol): guint =
  result = (a.flag0 and bm_TGtkTableRowCol_empty) shr
      bp_TGtkTableRowCol_empty

proc set_empty*(a: PTableRowCol, `empty`: guint) =
  a.flag0 = a.flag0 or
      (int16(`empty` shl bp_TGtkTableRowCol_empty) and
      bm_TGtkTableRowCol_empty)

proc TYPE_TEAROFF_MENU_ITEM*(): GType =
  result = tearoff_menu_item_get_type()

proc TEAROFF_MENU_ITEM*(obj: pointer): PTearoffMenuItem =
  result = cast[PTearoffMenuItem](CHECK_CAST(obj, TYPE_TEAROFF_MENU_ITEM()))

proc TEAROFF_MENU_ITEM_CLASS*(klass: pointer): PTearoffMenuItemClass =
  result = cast[PTearoffMenuItemClass](CHECK_CLASS_CAST(klass,
      TYPE_TEAROFF_MENU_ITEM()))

proc IS_TEAROFF_MENU_ITEM*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TEAROFF_MENU_ITEM())

proc IS_TEAROFF_MENU_ITEM_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TEAROFF_MENU_ITEM())

proc TEAROFF_MENU_ITEM_GET_CLASS*(obj: pointer): PTearoffMenuItemClass =
  result = cast[PTearoffMenuItemClass](CHECK_GET_CLASS(obj,
      TYPE_TEAROFF_MENU_ITEM()))

proc torn_off*(a: PTearoffMenuItem): guint =
  result = (a.TearoffMenuItemflag0 and bm_TGtkTearoffMenuItem_torn_off) shr
      bp_TGtkTearoffMenuItem_torn_off

proc set_torn_off*(a: PTearoffMenuItem, `torn_off`: guint) =
  a.TearoffMenuItemflag0 = a.TearoffMenuItemflag0 or
      (int16(`torn_off` shl bp_TGtkTearoffMenuItem_torn_off) and
      bm_TGtkTearoffMenuItem_torn_off)

proc TYPE_TEXT*(): GType =
  result = gtk2.text_get_type()

proc TEXT*(obj: pointer): PText =
  result = cast[PText](CHECK_CAST(obj, gtk2.TYPE_TEXT()))

proc TEXT_CLASS*(klass: pointer): PTextClass =
  result = cast[PTextClass](CHECK_CLASS_CAST(klass, gtk2.TYPE_TEXT()))

proc IS_TEXT*(obj: pointer): bool =
  result = CHECK_TYPE(obj, gtk2.TYPE_TEXT())

proc IS_TEXT_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, gtk2.TYPE_TEXT())

proc TEXT_GET_CLASS*(obj: pointer): PTextClass =
  result = cast[PTextClass](CHECK_GET_CLASS(obj, gtk2.TYPE_TEXT()))

proc line_wrap*(a: PText): guint =
  result = (a.Textflag0 and bm_TGtkText_line_wrap) shr bp_TGtkText_line_wrap

proc set_line_wrap*(a: PText, `line_wrap`: guint) =
  a.Textflag0 = a.Textflag0 or
      (int16(`line_wrap` shl bp_TGtkText_line_wrap) and bm_TGtkText_line_wrap)

proc word_wrap*(a: PText): guint =
  result = (a.Textflag0 and bm_TGtkText_word_wrap) shr bp_TGtkText_word_wrap

proc set_word_wrap*(a: PText, `word_wrap`: guint) =
  a.Textflag0 = a.Textflag0 or
      (int16(`word_wrap` shl bp_TGtkText_word_wrap) and bm_TGtkText_word_wrap)

proc use_wchar*(a: PText): gboolean =
  result = ((a.Textflag0 and bm_TGtkText_use_wchar) shr bp_TGtkText_use_wchar) >
      0'i16

proc set_use_wchar*(a: PText, `use_wchar`: gboolean) =
  if `use_wchar`:
    a.Textflag0 = a.Textflag0 or bm_TGtkText_use_wchar
  else:
    a.Textflag0 = a.Textflag0 and not bm_TGtkText_use_wchar

proc INDEX_WCHAR*(t: PText, index: guint): guint32 =
  nil

proc INDEX_UCHAR*(t: PText, index: guint): GUChar =
  nil

proc TYPE_TEXT_ITER*(): GType =
  result = text_iter_get_type()

proc TYPE_TEXT_TAG*(): GType =
  result = text_tag_get_type()

proc TEXT_TAG*(obj: pointer): PTextTag =
  result = cast[PTextTag](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_TEXT_TAG()))

proc TEXT_TAG_CLASS*(klass: pointer): PTextTagClass =
  result = cast[PTextTagClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_TEXT_TAG()))

proc IS_TEXT_TAG*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_TEXT_TAG())

proc IS_TEXT_TAG_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_TEXT_TAG())

proc TEXT_TAG_GET_CLASS*(obj: pointer): PTextTagClass =
  result = cast[PTextTagClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_TEXT_TAG()))

proc TYPE_TEXT_ATTRIBUTES*(): GType =
  result = text_attributes_get_type()

proc bg_color_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_bg_color_set) shr
      bp_TGtkTextTag_bg_color_set

proc set_bg_color_set*(a: PTextTag, `bg_color_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`bg_color_set` shl bp_TGtkTextTag_bg_color_set) and
      bm_TGtkTextTag_bg_color_set)

proc bg_stipple_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_bg_stipple_set) shr
      bp_TGtkTextTag_bg_stipple_set

proc set_bg_stipple_set*(a: PTextTag, `bg_stipple_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`bg_stipple_set` shl bp_TGtkTextTag_bg_stipple_set) and
      bm_TGtkTextTag_bg_stipple_set)

proc fg_color_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_fg_color_set) shr
      bp_TGtkTextTag_fg_color_set

proc set_fg_color_set*(a: PTextTag, `fg_color_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`fg_color_set` shl bp_TGtkTextTag_fg_color_set) and
      bm_TGtkTextTag_fg_color_set)

proc scale_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_scale_set) shr
      bp_TGtkTextTag_scale_set

proc set_scale_set*(a: PTextTag, `scale_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`scale_set` shl bp_TGtkTextTag_scale_set) and
      bm_TGtkTextTag_scale_set)

proc fg_stipple_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_fg_stipple_set) shr
      bp_TGtkTextTag_fg_stipple_set

proc set_fg_stipple_set*(a: PTextTag, `fg_stipple_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`fg_stipple_set` shl bp_TGtkTextTag_fg_stipple_set) and
      bm_TGtkTextTag_fg_stipple_set)

proc justification_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_justification_set) shr
      bp_TGtkTextTag_justification_set

proc set_justification_set*(a: PTextTag, `justification_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`justification_set` shl bp_TGtkTextTag_justification_set) and
      bm_TGtkTextTag_justification_set)

proc left_margin_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_left_margin_set) shr
      bp_TGtkTextTag_left_margin_set

proc set_left_margin_set*(a: PTextTag, `left_margin_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`left_margin_set` shl bp_TGtkTextTag_left_margin_set) and
      bm_TGtkTextTag_left_margin_set)

proc indent_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_indent_set) shr
      bp_TGtkTextTag_indent_set

proc set_indent_set*(a: PTextTag, `indent_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`indent_set` shl bp_TGtkTextTag_indent_set) and
      bm_TGtkTextTag_indent_set)

proc rise_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_rise_set) shr
      bp_TGtkTextTag_rise_set

proc set_rise_set*(a: PTextTag, `rise_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`rise_set` shl bp_TGtkTextTag_rise_set) and bm_TGtkTextTag_rise_set)

proc strikethrough_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_strikethrough_set) shr
      bp_TGtkTextTag_strikethrough_set

proc set_strikethrough_set*(a: PTextTag, `strikethrough_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`strikethrough_set` shl bp_TGtkTextTag_strikethrough_set) and
      bm_TGtkTextTag_strikethrough_set)

proc right_margin_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_right_margin_set) shr
      bp_TGtkTextTag_right_margin_set

proc set_right_margin_set*(a: PTextTag, `right_margin_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`right_margin_set` shl bp_TGtkTextTag_right_margin_set) and
      bm_TGtkTextTag_right_margin_set)

proc pixels_above_lines_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_pixels_above_lines_set) shr
      bp_TGtkTextTag_pixels_above_lines_set

proc set_pixels_above_lines_set*(a: PTextTag,
                                 `pixels_above_lines_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`pixels_above_lines_set` shl bp_TGtkTextTag_pixels_above_lines_set) and
      bm_TGtkTextTag_pixels_above_lines_set)

proc pixels_below_lines_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_pixels_below_lines_set) shr
      bp_TGtkTextTag_pixels_below_lines_set

proc set_pixels_below_lines_set*(a: PTextTag,
                                 `pixels_below_lines_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`pixels_below_lines_set` shl bp_TGtkTextTag_pixels_below_lines_set) and
      bm_TGtkTextTag_pixels_below_lines_set)

proc pixels_inside_wrap_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_pixels_inside_wrap_set) shr
      bp_TGtkTextTag_pixels_inside_wrap_set

proc set_pixels_inside_wrap_set*(a: PTextTag,
                                 `pixels_inside_wrap_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`pixels_inside_wrap_set` shl bp_TGtkTextTag_pixels_inside_wrap_set) and
      bm_TGtkTextTag_pixels_inside_wrap_set)

proc tabs_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_tabs_set) shr
      bp_TGtkTextTag_tabs_set

proc set_tabs_set*(a: PTextTag, `tabs_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`tabs_set` shl bp_TGtkTextTag_tabs_set) and bm_TGtkTextTag_tabs_set)

proc underline_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_underline_set) shr
      bp_TGtkTextTag_underline_set

proc set_underline_set*(a: PTextTag, `underline_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`underline_set` shl bp_TGtkTextTag_underline_set) and
      bm_TGtkTextTag_underline_set)

proc wrap_mode_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_wrap_mode_set) shr
      bp_TGtkTextTag_wrap_mode_set

proc set_wrap_mode_set*(a: PTextTag, `wrap_mode_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`wrap_mode_set` shl bp_TGtkTextTag_wrap_mode_set) and
      bm_TGtkTextTag_wrap_mode_set)

proc bg_full_height_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_bg_full_height_set) shr
      bp_TGtkTextTag_bg_full_height_set

proc set_bg_full_height_set*(a: PTextTag, `bg_full_height_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`bg_full_height_set` shl bp_TGtkTextTag_bg_full_height_set) and
      bm_TGtkTextTag_bg_full_height_set)

proc invisible_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_invisible_set) shr
      bp_TGtkTextTag_invisible_set

proc set_invisible_set*(a: PTextTag, `invisible_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`invisible_set` shl bp_TGtkTextTag_invisible_set) and
      bm_TGtkTextTag_invisible_set)

proc editable_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_editable_set) shr
      bp_TGtkTextTag_editable_set

proc set_editable_set*(a: PTextTag, `editable_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`editable_set` shl bp_TGtkTextTag_editable_set) and
      bm_TGtkTextTag_editable_set)

proc language_set*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_language_set) shr
      bp_TGtkTextTag_language_set

proc set_language_set*(a: PTextTag, `language_set`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`language_set` shl bp_TGtkTextTag_language_set) and
      bm_TGtkTextTag_language_set)

proc pad1*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_pad1) shr bp_TGtkTextTag_pad1

proc set_pad1*(a: PTextTag, `pad1`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`pad1` shl bp_TGtkTextTag_pad1) and bm_TGtkTextTag_pad1)

proc pad2*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_pad2) shr bp_TGtkTextTag_pad2

proc set_pad2*(a: PTextTag, `pad2`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`pad2` shl bp_TGtkTextTag_pad2) and bm_TGtkTextTag_pad2)

proc pad3*(a: PTextTag): guint =
  result = (a.TextTagflag0 and bm_TGtkTextTag_pad3) shr bp_TGtkTextTag_pad3

proc set_pad3*(a: PTextTag, `pad3`: guint) =
  a.TextTagflag0 = a.TextTagflag0 or
      ((`pad3` shl bp_TGtkTextTag_pad3) and bm_TGtkTextTag_pad3)

proc underline*(a: PTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_underline) shr
      bp_TGtkTextAppearance_underline

proc set_underline*(a: PTextAppearance, `underline`: guint) =
  a.flag0 = a.flag0 or
      (int16(`underline` shl bp_TGtkTextAppearance_underline) and
      bm_TGtkTextAppearance_underline)

proc strikethrough*(a: PTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_strikethrough) shr
      bp_TGtkTextAppearance_strikethrough

proc set_strikethrough*(a: PTextAppearance, `strikethrough`: guint) =
  a.flag0 = a.flag0 or
      (int16(`strikethrough` shl bp_TGtkTextAppearance_strikethrough) and
      bm_TGtkTextAppearance_strikethrough)

proc draw_bg*(a: PTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_draw_bg) shr
      bp_TGtkTextAppearance_draw_bg

proc set_draw_bg*(a: PTextAppearance, `draw_bg`: guint) =
  a.flag0 = a.flag0 or
      (int16(`draw_bg` shl bp_TGtkTextAppearance_draw_bg) and
      bm_TGtkTextAppearance_draw_bg)

proc inside_selection*(a: PTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_inside_selection) shr
      bp_TGtkTextAppearance_inside_selection

proc set_inside_selection*(a: PTextAppearance, `inside_selection`: guint) =
  a.flag0 = a.flag0 or
      (int16(`inside_selection` shl bp_TGtkTextAppearance_inside_selection) and
      bm_TGtkTextAppearance_inside_selection)

proc is_text*(a: PTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_is_text) shr
      bp_TGtkTextAppearance_is_text

proc set_is_text*(a: PTextAppearance, `is_text`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_text` shl bp_TGtkTextAppearance_is_text) and
      bm_TGtkTextAppearance_is_text)

proc pad1*(a: PTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_pad1) shr
      bp_TGtkTextAppearance_pad1

proc set_pad1*(a: PTextAppearance, `pad1`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad1` shl bp_TGtkTextAppearance_pad1) and
      bm_TGtkTextAppearance_pad1)

proc pad2*(a: PTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_pad2) shr
      bp_TGtkTextAppearance_pad2

proc set_pad2*(a: PTextAppearance, `pad2`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad2` shl bp_TGtkTextAppearance_pad2) and
      bm_TGtkTextAppearance_pad2)

proc pad3*(a: PTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_pad3) shr
      bp_TGtkTextAppearance_pad3

proc set_pad3*(a: PTextAppearance, `pad3`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad3` shl bp_TGtkTextAppearance_pad3) and
      bm_TGtkTextAppearance_pad3)

proc pad4*(a: PTextAppearance): guint =
  result = (a.flag0 and bm_TGtkTextAppearance_pad4) shr
      bp_TGtkTextAppearance_pad4

proc set_pad4*(a: PTextAppearance, `pad4`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad4` shl bp_TGtkTextAppearance_pad4) and
      bm_TGtkTextAppearance_pad4)

proc invisible*(a: PTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_invisible) shr
      bp_TGtkTextAttributes_invisible

proc set_invisible*(a: PTextAttributes, `invisible`: guint) =
  a.flag0 = a.flag0 or
      (int16(`invisible` shl bp_TGtkTextAttributes_invisible) and
      bm_TGtkTextAttributes_invisible)

proc bg_full_height*(a: PTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_bg_full_height) shr
      bp_TGtkTextAttributes_bg_full_height

proc set_bg_full_height*(a: PTextAttributes, `bg_full_height`: guint) =
  a.flag0 = a.flag0 or
      (int16(`bg_full_height` shl bp_TGtkTextAttributes_bg_full_height) and
      bm_TGtkTextAttributes_bg_full_height)

proc editable*(a: PTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_editable) shr
      bp_TGtkTextAttributes_editable

proc set_editable*(a: PTextAttributes, `editable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`editable` shl bp_TGtkTextAttributes_editable) and
      bm_TGtkTextAttributes_editable)

proc realized*(a: PTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_realized) shr
      bp_TGtkTextAttributes_realized

proc set_realized*(a: PTextAttributes, `realized`: guint) =
  a.flag0 = a.flag0 or
      (int16(`realized` shl bp_TGtkTextAttributes_realized) and
      bm_TGtkTextAttributes_realized)

proc pad1*(a: PTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_pad1) shr
      bp_TGtkTextAttributes_pad1

proc set_pad1*(a: PTextAttributes, `pad1`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad1` shl bp_TGtkTextAttributes_pad1) and
      bm_TGtkTextAttributes_pad1)

proc pad2*(a: PTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_pad2) shr
      bp_TGtkTextAttributes_pad2

proc set_pad2*(a: PTextAttributes, `pad2`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad2` shl bp_TGtkTextAttributes_pad2) and
      bm_TGtkTextAttributes_pad2)

proc pad3*(a: PTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_pad3) shr
      bp_TGtkTextAttributes_pad3

proc set_pad3*(a: PTextAttributes, `pad3`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad3` shl bp_TGtkTextAttributes_pad3) and
      bm_TGtkTextAttributes_pad3)

proc pad4*(a: PTextAttributes): guint =
  result = (a.flag0 and bm_TGtkTextAttributes_pad4) shr
      bp_TGtkTextAttributes_pad4

proc set_pad4*(a: PTextAttributes, `pad4`: guint) =
  a.flag0 = a.flag0 or
      (int16(`pad4` shl bp_TGtkTextAttributes_pad4) and
      bm_TGtkTextAttributes_pad4)

proc TYPE_TEXT_TAG_TABLE*(): GType =
  result = text_tag_table_get_type()

proc TEXT_TAG_TABLE*(obj: pointer): PTextTagTable =
  result = cast[PTextTagTable](G_TYPE_CHECK_INSTANCE_CAST(obj,
      TYPE_TEXT_TAG_TABLE()))

proc TEXT_TAG_TABLE_CLASS*(klass: pointer): PTextTagTableClass =
  result = cast[PTextTagTableClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_TEXT_TAG_TABLE()))

proc IS_TEXT_TAG_TABLE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_TEXT_TAG_TABLE())

proc IS_TEXT_TAG_TABLE_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_TEXT_TAG_TABLE())

proc TEXT_TAG_TABLE_GET_CLASS*(obj: pointer): PTextTagTableClass =
  result = cast[PTextTagTableClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_TEXT_TAG_TABLE()))

proc TYPE_TEXT_MARK*(): GType =
  result = text_mark_get_type()

proc TEXT_MARK*(anObject: pointer): PTextMark =
  result = cast[PTextMark](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_TEXT_MARK()))

proc TEXT_MARK_CLASS*(klass: pointer): PTextMarkClass =
  result = cast[PTextMarkClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_TEXT_MARK()))

proc IS_TEXT_MARK*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_TEXT_MARK())

proc IS_TEXT_MARK_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_TEXT_MARK())

proc TEXT_MARK_GET_CLASS*(obj: pointer): PTextMarkClass =
  result = cast[PTextMarkClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_TEXT_MARK()))

proc visible*(a: PTextMarkBody): guint =
  result = (a.flag0 and bm_TGtkTextMarkBody_visible) shr
      bp_TGtkTextMarkBody_visible

proc set_visible*(a: PTextMarkBody, `visible`: guint) =
  a.flag0 = a.flag0 or
      (int16(`visible` shl bp_TGtkTextMarkBody_visible) and
      bm_TGtkTextMarkBody_visible)

proc not_deleteable*(a: PTextMarkBody): guint =
  result = (a.flag0 and bm_TGtkTextMarkBody_not_deleteable) shr
      bp_TGtkTextMarkBody_not_deleteable

proc set_not_deleteable*(a: PTextMarkBody, `not_deleteable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`not_deleteable` shl bp_TGtkTextMarkBody_not_deleteable) and
      bm_TGtkTextMarkBody_not_deleteable)

proc TYPE_TEXT_CHILD_ANCHOR*(): GType =
  result = text_child_anchor_get_type()

proc TEXT_CHILD_ANCHOR*(anObject: pointer): PTextChildAnchor =
  result = cast[PTextChildAnchor](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      TYPE_TEXT_CHILD_ANCHOR()))

proc TEXT_CHILD_ANCHOR_CLASS*(klass: pointer): PTextChildAnchorClass =
  result = cast[PTextChildAnchorClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_TEXT_CHILD_ANCHOR()))

proc IS_TEXT_CHILD_ANCHOR*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_TEXT_CHILD_ANCHOR())

proc IS_TEXT_CHILD_ANCHOR_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_TEXT_CHILD_ANCHOR())

proc TEXT_CHILD_ANCHOR_GET_CLASS*(obj: pointer): PTextChildAnchorClass =
  result = cast[PTextChildAnchorClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_TEXT_CHILD_ANCHOR()))

proc width*(a: PTextLineData): gint =
  result = a.flag0 and bm_TGtkTextLineData_width

proc set_width*(a: PTextLineData, NewWidth: gint) =
  a.flag0 = (bm_TGtkTextLineData_width and NewWidth) or a.flag0

proc valid*(a: PTextLineData): gint =
  result = (a.flag0 and bm_TGtkTextLineData_valid) shr
      bp_TGtkTextLineData_valid

proc set_valid*(a: PTextLineData, `valid`: gint) =
  a.flag0 = a.flag0 or
      ((`valid` shl bp_TGtkTextLineData_valid) and bm_TGtkTextLineData_valid)

proc TYPE_TEXT_BUFFER*(): GType =
  result = text_buffer_get_type()

proc TEXT_BUFFER*(obj: pointer): PTextBuffer =
  result = cast[PTextBuffer](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_TEXT_BUFFER()))

proc TEXT_BUFFER_CLASS*(klass: pointer): PTextBufferClass =
  result = cast[PTextBufferClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_TEXT_BUFFER()))

proc IS_TEXT_BUFFER*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_TEXT_BUFFER())

proc IS_TEXT_BUFFER_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_TEXT_BUFFER())

proc TEXT_BUFFER_GET_CLASS*(obj: pointer): PTextBufferClass =
  result = cast[PTextBufferClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_TEXT_BUFFER()))

proc modified*(a: PTextBuffer): guint =
  result = (a.TextBufferflag0 and bm_TGtkTextBuffer_modified) shr
      bp_TGtkTextBuffer_modified

proc set_modified*(a: PTextBuffer, `modified`: guint) =
  a.TextBufferflag0 = a.TextBufferflag0 or
      (int16(`modified` shl bp_TGtkTextBuffer_modified) and
      bm_TGtkTextBuffer_modified)

proc TYPE_TEXT_LAYOUT*(): GType =
  result = text_layout_get_type()

proc TEXT_LAYOUT*(obj: pointer): PTextLayout =
  result = cast[PTextLayout](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_TEXT_LAYOUT()))

proc TEXT_LAYOUT_CLASS*(klass: pointer): PTextLayoutClass =
  result = cast[PTextLayoutClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_TEXT_LAYOUT()))

proc IS_TEXT_LAYOUT*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_TEXT_LAYOUT())

proc IS_TEXT_LAYOUT_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_TEXT_LAYOUT())

proc TEXT_LAYOUT_GET_CLASS*(obj: pointer): PTextLayoutClass =
  result = cast[PTextLayoutClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_TEXT_LAYOUT()))

proc cursor_visible*(a: PTextLayout): guint =
  result = (a.TextLayoutflag0 and bm_TGtkTextLayout_cursor_visible) shr
      bp_TGtkTextLayout_cursor_visible

proc set_cursor_visible*(a: PTextLayout, `cursor_visible`: guint) =
  a.TextLayoutflag0 = a.TextLayoutflag0 or
      (int16(`cursor_visible` shl bp_TGtkTextLayout_cursor_visible) and
      bm_TGtkTextLayout_cursor_visible)

proc cursor_direction*(a: PTextLayout): gint =
  result = (a.TextLayoutflag0 and bm_TGtkTextLayout_cursor_direction) shr
      bp_TGtkTextLayout_cursor_direction

proc set_cursor_direction*(a: PTextLayout, `cursor_direction`: gint) =
  a.TextLayoutflag0 = a.TextLayoutflag0 or
      (int16(`cursor_direction` shl bp_TGtkTextLayout_cursor_direction) and
      bm_TGtkTextLayout_cursor_direction)

proc is_strong*(a: PTextCursorDisplay): guint =
  result = (a.flag0 and bm_TGtkTextCursorDisplay_is_strong) shr
      bp_TGtkTextCursorDisplay_is_strong

proc set_is_strong*(a: PTextCursorDisplay, `is_strong`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_strong` shl bp_TGtkTextCursorDisplay_is_strong) and
      bm_TGtkTextCursorDisplay_is_strong)

proc is_weak*(a: PTextCursorDisplay): guint =
  result = (a.flag0 and bm_TGtkTextCursorDisplay_is_weak) shr
      bp_TGtkTextCursorDisplay_is_weak

proc set_is_weak*(a: PTextCursorDisplay, `is_weak`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_weak` shl bp_TGtkTextCursorDisplay_is_weak) and
      bm_TGtkTextCursorDisplay_is_weak)

proc TYPE_TEXT_VIEW*(): GType =
  result = text_view_get_type()

proc TEXT_VIEW*(obj: pointer): PTextView =
  result = cast[PTextView](CHECK_CAST(obj, TYPE_TEXT_VIEW()))

proc TEXT_VIEW_CLASS*(klass: pointer): PTextViewClass =
  result = cast[PTextViewClass](CHECK_CLASS_CAST(klass, TYPE_TEXT_VIEW()))

proc IS_TEXT_VIEW*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TEXT_VIEW())

proc IS_TEXT_VIEW_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TEXT_VIEW())

proc TEXT_VIEW_GET_CLASS*(obj: pointer): PTextViewClass =
  result = cast[PTextViewClass](CHECK_GET_CLASS(obj, TYPE_TEXT_VIEW()))

proc editable*(a: PTextView): guint =
  result = (a.TextViewflag0 and bm_TGtkTextView_editable) shr
      bp_TGtkTextView_editable

proc set_editable*(a: PTextView, `editable`: guint) =
  a.TextViewflag0 = a.TextViewflag0 or
      (int16(`editable` shl bp_TGtkTextView_editable) and
      bm_TGtkTextView_editable)

proc overwrite_mode*(a: PTextView): guint =
  result = (a.TextViewflag0 and bm_TGtkTextView_overwrite_mode) shr
      bp_TGtkTextView_overwrite_mode

proc set_overwrite_mode*(a: PTextView, `overwrite_mode`: guint) =
  a.TextViewflag0 = a.TextViewflag0 or
      (int16(`overwrite_mode` shl bp_TGtkTextView_overwrite_mode) and
      bm_TGtkTextView_overwrite_mode)

proc cursor_visible*(a: PTextView): guint =
  result = (a.TextViewflag0 and bm_TGtkTextView_cursor_visible) shr
      bp_TGtkTextView_cursor_visible

proc set_cursor_visible*(a: PTextView, `cursor_visible`: guint) =
  a.TextViewflag0 = a.TextViewflag0 or
      (int16(`cursor_visible` shl bp_TGtkTextView_cursor_visible) and
      bm_TGtkTextView_cursor_visible)

proc need_im_reset*(a: PTextView): guint =
  result = (a.TextViewflag0 and bm_TGtkTextView_need_im_reset) shr
      bp_TGtkTextView_need_im_reset

proc set_need_im_reset*(a: PTextView, `need_im_reset`: guint) =
  a.TextViewflag0 = a.TextViewflag0 or
      (int16(`need_im_reset` shl bp_TGtkTextView_need_im_reset) and
      bm_TGtkTextView_need_im_reset)

proc just_selected_element*(a: PTextView): guint =
  result = (a.TextViewflag0 and bm_TGtkTextView_just_selected_element) shr
      bp_TGtkTextView_just_selected_element

proc set_just_selected_element*(a: PTextView, `just_selected_element`: guint) =
  a.TextViewflag0 = a.TextViewflag0 or
      (int16(`just_selected_element` shl
      bp_TGtkTextView_just_selected_element) and
      bm_TGtkTextView_just_selected_element)

proc disable_scroll_on_focus*(a: PTextView): guint =
  result = (a.TextViewflag0 and bm_TGtkTextView_disable_scroll_on_focus) shr
      bp_TGtkTextView_disable_scroll_on_focus

proc set_disable_scroll_on_focus*(a: PTextView,
                                  `disable_scroll_on_focus`: guint) =
  a.TextViewflag0 = a.TextViewflag0 or
      (int16(`disable_scroll_on_focus` shl
      bp_TGtkTextView_disable_scroll_on_focus) and
      bm_TGtkTextView_disable_scroll_on_focus)

proc onscreen_validated*(a: PTextView): guint =
  result = (a.TextViewflag0 and bm_TGtkTextView_onscreen_validated) shr
      bp_TGtkTextView_onscreen_validated

proc set_onscreen_validated*(a: PTextView, `onscreen_validated`: guint) =
  a.TextViewflag0 = a.TextViewflag0 or
      (int16(`onscreen_validated` shl bp_TGtkTextView_onscreen_validated) and
      bm_TGtkTextView_onscreen_validated)

proc mouse_cursor_obscured*(a: PTextView): guint =
  result = (a.TextViewflag0 and bm_TGtkTextView_mouse_cursor_obscured) shr
      bp_TGtkTextView_mouse_cursor_obscured

proc set_mouse_cursor_obscured*(a: PTextView, `mouse_cursor_obscured`: guint) =
  a.TextViewflag0 = a.TextViewflag0 or
      (int16(`mouse_cursor_obscured` shl
      bp_TGtkTextView_mouse_cursor_obscured) and
      bm_TGtkTextView_mouse_cursor_obscured)

proc TYPE_TIPS_QUERY*(): GType =
  result = tips_query_get_type()

proc TIPS_QUERY*(obj: pointer): PTipsQuery =
  result = cast[PTipsQuery](CHECK_CAST(obj, TYPE_TIPS_QUERY()))

proc TIPS_QUERY_CLASS*(klass: pointer): PTipsQueryClass =
  result = cast[PTipsQueryClass](CHECK_CLASS_CAST(klass, TYPE_TIPS_QUERY()))

proc IS_TIPS_QUERY*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TIPS_QUERY())

proc IS_TIPS_QUERY_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TIPS_QUERY())

proc TIPS_QUERY_GET_CLASS*(obj: pointer): PTipsQueryClass =
  result = cast[PTipsQueryClass](CHECK_GET_CLASS(obj, TYPE_TIPS_QUERY()))

proc emit_always*(a: PTipsQuery): guint =
  result = (a.TipsQueryflag0 and bm_TGtkTipsQuery_emit_always) shr
      bp_TGtkTipsQuery_emit_always

proc set_emit_always*(a: PTipsQuery, `emit_always`: guint) =
  a.TipsQueryflag0 = a.TipsQueryflag0 or
      (int16(`emit_always` shl bp_TGtkTipsQuery_emit_always) and
      bm_TGtkTipsQuery_emit_always)

proc in_query*(a: PTipsQuery): guint =
  result = (a.TipsQueryflag0 and bm_TGtkTipsQuery_in_query) shr
      bp_TGtkTipsQuery_in_query

proc set_in_query*(a: PTipsQuery, `in_query`: guint) =
  a.TipsQueryflag0 = a.TipsQueryflag0 or
      (int16(`in_query` shl bp_TGtkTipsQuery_in_query) and
      bm_TGtkTipsQuery_in_query)

proc TYPE_TOOLTIPS*(): GType =
  result = tooltips_get_type()

proc TOOLTIPS*(obj: pointer): PTooltips =
  result = cast[PTooltips](CHECK_CAST(obj, TYPE_TOOLTIPS()))

proc TOOLTIPS_CLASS*(klass: pointer): PTooltipsClass =
  result = cast[PTooltipsClass](CHECK_CLASS_CAST(klass, TYPE_TOOLTIPS()))

proc IS_TOOLTIPS*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TOOLTIPS())

proc IS_TOOLTIPS_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TOOLTIPS())

proc TOOLTIPS_GET_CLASS*(obj: pointer): PTooltipsClass =
  result = cast[PTooltipsClass](CHECK_GET_CLASS(obj, TYPE_TOOLTIPS()))

proc delay*(a: PTooltips): guint =
  result = (a.Tooltipsflag0 and bm_TGtkTooltips_delay) shr
      bp_TGtkTooltips_delay

proc set_delay*(a: PTooltips, `delay`: guint) =
  a.Tooltipsflag0 = a.Tooltipsflag0 or
      ((`delay` shl bp_TGtkTooltips_delay) and bm_TGtkTooltips_delay)

proc enabled*(a: PTooltips): guint =
  result = (a.Tooltipsflag0 and bm_TGtkTooltips_enabled) shr
      bp_TGtkTooltips_enabled

proc set_enabled*(a: PTooltips, `enabled`: guint) =
  a.Tooltipsflag0 = a.Tooltipsflag0 or
      ((`enabled` shl bp_TGtkTooltips_enabled) and bm_TGtkTooltips_enabled)

proc have_grab*(a: PTooltips): guint =
  result = (a.Tooltipsflag0 and bm_TGtkTooltips_have_grab) shr
      bp_TGtkTooltips_have_grab

proc set_have_grab*(a: PTooltips, `have_grab`: guint) =
  a.Tooltipsflag0 = a.Tooltipsflag0 or
      ((`have_grab` shl bp_TGtkTooltips_have_grab) and
      bm_TGtkTooltips_have_grab)

proc use_sticky_delay*(a: PTooltips): guint =
  result = (a.Tooltipsflag0 and bm_TGtkTooltips_use_sticky_delay) shr
      bp_TGtkTooltips_use_sticky_delay

proc set_use_sticky_delay*(a: PTooltips, `use_sticky_delay`: guint) =
  a.Tooltipsflag0 = a.Tooltipsflag0 or
      ((`use_sticky_delay` shl bp_TGtkTooltips_use_sticky_delay) and
      bm_TGtkTooltips_use_sticky_delay)

proc TYPE_TOOLBAR*(): GType =
  result = toolbar_get_type()

proc TOOLBAR*(obj: pointer): PToolbar =
  result = cast[PToolbar](CHECK_CAST(obj, TYPE_TOOLBAR()))

proc TOOLBAR_CLASS*(klass: pointer): PToolbarClass =
  result = cast[PToolbarClass](CHECK_CLASS_CAST(klass, TYPE_TOOLBAR()))

proc IS_TOOLBAR*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TOOLBAR())

proc IS_TOOLBAR_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TOOLBAR())

proc TOOLBAR_GET_CLASS*(obj: pointer): PToolbarClass =
  result = cast[PToolbarClass](CHECK_GET_CLASS(obj, TYPE_TOOLBAR()))

proc style_set*(a: PToolbar): guint =
  result = (a.Toolbarflag0 and bm_TGtkToolbar_style_set) shr
      bp_TGtkToolbar_style_set

proc set_style_set*(a: PToolbar, `style_set`: guint) =
  a.Toolbarflag0 = a.Toolbarflag0 or
      (int16(`style_set` shl bp_TGtkToolbar_style_set) and
      bm_TGtkToolbar_style_set)

proc icon_size_set*(a: PToolbar): guint =
  result = (a.Toolbarflag0 and bm_TGtkToolbar_icon_size_set) shr
      bp_TGtkToolbar_icon_size_set

proc set_icon_size_set*(a: PToolbar, `icon_size_set`: guint) =
  a.Toolbarflag0 = a.Toolbarflag0 or
      (int16(`icon_size_set` shl bp_TGtkToolbar_icon_size_set) and
      bm_TGtkToolbar_icon_size_set)

proc TYPE_TREE*(): GType =
  result = tree_get_type()

proc TREE*(obj: pointer): PTree =
  result = cast[PTree](CHECK_CAST(obj, TYPE_TREE()))

proc TREE_CLASS*(klass: pointer): PTreeClass =
  result = cast[PTreeClass](CHECK_CLASS_CAST(klass, TYPE_TREE()))

proc IS_TREE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TREE())

proc IS_TREE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TREE())

proc TREE_GET_CLASS*(obj: pointer): PTreeClass =
  result = cast[PTreeClass](CHECK_GET_CLASS(obj, TYPE_TREE()))

proc IS_ROOT_TREE*(obj: pointer): bool =
  result = (cast[PObject]((TREE(obj)).root_tree)) == (cast[PObject](obj))

proc TREE_ROOT_TREE*(obj: pointer): PTree =
  result = TREE(obj).root_tree

proc TREE_SELECTION_OLD*(obj: pointer): PGList =
  result = (TREE_ROOT_TREE(obj)).selection

proc selection_mode*(a: PTree): guint =
  result = (a.Treeflag0 and bm_TGtkTree_selection_mode) shr
      bp_TGtkTree_selection_mode

proc set_selection_mode*(a: PTree, `selection_mode`: guint) =
  a.Treeflag0 = a.Treeflag0 or
      (int16(`selection_mode` shl bp_TGtkTree_selection_mode) and
      bm_TGtkTree_selection_mode)

proc view_mode*(a: PTree): guint =
  result = (a.Treeflag0 and bm_TGtkTree_view_mode) shr bp_TGtkTree_view_mode

proc set_view_mode*(a: PTree, `view_mode`: guint) =
  a.Treeflag0 = a.Treeflag0 or
      (int16(`view_mode` shl bp_TGtkTree_view_mode) and bm_TGtkTree_view_mode)

proc view_line*(a: PTree): guint =
  result = (a.Treeflag0 and bm_TGtkTree_view_line) shr bp_TGtkTree_view_line

proc set_view_line*(a: PTree, `view_line`: guint) =
  a.Treeflag0 = a.Treeflag0 or
      (int16(`view_line` shl bp_TGtkTree_view_line) and bm_TGtkTree_view_line)

proc TYPE_TREE_DRAG_SOURCE*(): GType =
  result = tree_drag_source_get_type()

proc TREE_DRAG_SOURCE*(obj: pointer): PTreeDragSource =
  result = cast[PTreeDragSource](G_TYPE_CHECK_INSTANCE_CAST(obj,
      TYPE_TREE_DRAG_SOURCE()))

proc IS_TREE_DRAG_SOURCE*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_TREE_DRAG_SOURCE())

proc TREE_DRAG_SOURCE_GET_IFACE*(obj: pointer): PTreeDragSourceIface =
  result = cast[PTreeDragSourceIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      TYPE_TREE_DRAG_SOURCE()))

proc TYPE_TREE_DRAG_DEST*(): GType =
  result = tree_drag_dest_get_type()

proc TREE_DRAG_DEST*(obj: pointer): PTreeDragDest =
  result = cast[PTreeDragDest](G_TYPE_CHECK_INSTANCE_CAST(obj,
      TYPE_TREE_DRAG_DEST()))

proc IS_TREE_DRAG_DEST*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_TREE_DRAG_DEST())

proc TREE_DRAG_DEST_GET_IFACE*(obj: pointer): PTreeDragDestIface =
  result = cast[PTreeDragDestIface](G_TYPE_INSTANCE_GET_INTERFACE(obj,
      TYPE_TREE_DRAG_DEST()))

proc TYPE_TREE_ITEM*(): GType =
  result = tree_item_get_type()

proc TREE_ITEM*(obj: pointer): PTreeItem =
  result = cast[PTreeItem](CHECK_CAST(obj, TYPE_TREE_ITEM()))

proc TREE_ITEM_CLASS*(klass: pointer): PTreeItemClass =
  result = cast[PTreeItemClass](CHECK_CLASS_CAST(klass, TYPE_TREE_ITEM()))

proc IS_TREE_ITEM*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TREE_ITEM())

proc IS_TREE_ITEM_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TREE_ITEM())

proc TREE_ITEM_GET_CLASS*(obj: pointer): PTreeItemClass =
  result = cast[PTreeItemClass](CHECK_GET_CLASS(obj, TYPE_TREE_ITEM()))

proc TREE_ITEM_SUBTREE*(obj: pointer): PWidget =
  result = (TREE_ITEM(obj)).subtree

proc expanded*(a: PTreeItem): guint =
  result = (a.TreeItemflag0 and bm_TGtkTreeItem_expanded) shr
      bp_TGtkTreeItem_expanded

proc set_expanded*(a: PTreeItem, `expanded`: guint) =
  a.TreeItemflag0 = a.TreeItemflag0 or
      (int16(`expanded` shl bp_TGtkTreeItem_expanded) and
      bm_TGtkTreeItem_expanded)

proc TYPE_TREE_SELECTION*(): GType =
  result = tree_selection_get_type()

proc TREE_SELECTION*(obj: pointer): PTreeSelection =
  result = cast[PTreeSelection](CHECK_CAST(obj, TYPE_TREE_SELECTION()))

proc TREE_SELECTION_CLASS*(klass: pointer): PTreeSelectionClass =
  result = cast[PTreeSelectionClass](CHECK_CLASS_CAST(klass,
      TYPE_TREE_SELECTION()))

proc IS_TREE_SELECTION*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TREE_SELECTION())

proc IS_TREE_SELECTION_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TREE_SELECTION())

proc TREE_SELECTION_GET_CLASS*(obj: pointer): PTreeSelectionClass =
  result = cast[PTreeSelectionClass](CHECK_GET_CLASS(obj, TYPE_TREE_SELECTION()))

proc TYPE_TREE_STORE*(): GType =
  result = tree_store_get_type()

proc TREE_STORE*(obj: pointer): PTreeStore =
  result = cast[PTreeStore](CHECK_CAST(obj, TYPE_TREE_STORE()))

proc TREE_STORE_CLASS*(klass: pointer): PTreeStoreClass =
  result = cast[PTreeStoreClass](CHECK_CLASS_CAST(klass, TYPE_TREE_STORE()))

proc IS_TREE_STORE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TREE_STORE())

proc IS_TREE_STORE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TREE_STORE())

proc TREE_STORE_GET_CLASS*(obj: pointer): PTreeStoreClass =
  result = cast[PTreeStoreClass](CHECK_GET_CLASS(obj, TYPE_TREE_STORE()))

proc columns_dirty*(a: PTreeStore): guint =
  result = (a.TreeStoreflag0 and bm_TGtkTreeStore_columns_dirty) shr
      bp_TGtkTreeStore_columns_dirty

proc set_columns_dirty*(a: PTreeStore, `columns_dirty`: guint) =
  a.TreeStoreflag0 = a.TreeStoreflag0 or
      (int16(`columns_dirty` shl bp_TGtkTreeStore_columns_dirty) and
      bm_TGtkTreeStore_columns_dirty)

proc TYPE_TREE_VIEW_COLUMN*(): GType =
  result = tree_view_column_get_type()

proc TREE_VIEW_COLUMN*(obj: pointer): PTreeViewColumn =
  result = cast[PTreeViewColumn](CHECK_CAST(obj, TYPE_TREE_VIEW_COLUMN()))

proc TREE_VIEW_COLUMN_CLASS*(klass: pointer): PTreeViewColumnClass =
  result = cast[PTreeViewColumnClass](CHECK_CLASS_CAST(klass,
      TYPE_TREE_VIEW_COLUMN()))

proc IS_TREE_VIEW_COLUMN*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TREE_VIEW_COLUMN())

proc IS_TREE_VIEW_COLUMN_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TREE_VIEW_COLUMN())

proc TREE_VIEW_COLUMN_GET_CLASS*(obj: pointer): PTreeViewColumnClass =
  result = cast[PTreeViewColumnClass](CHECK_GET_CLASS(obj,
      TYPE_TREE_VIEW_COLUMN()))

proc visible*(a: PTreeViewColumn): guint =
  result = (a.TreeViewColumnflag0 and bm_TGtkTreeViewColumn_visible) shr
      bp_TGtkTreeViewColumn_visible

proc set_visible*(a: PTreeViewColumn, `visible`: guint) =
  a.TreeViewColumnflag0 = a.TreeViewColumnflag0 or
      (int16(`visible` shl bp_TGtkTreeViewColumn_visible) and
      bm_TGtkTreeViewColumn_visible)

proc resizable*(a: PTreeViewColumn): guint =
  result = (a.TreeViewColumnflag0 and bm_TGtkTreeViewColumn_resizable) shr
      bp_TGtkTreeViewColumn_resizable

proc set_resizable*(a: PTreeViewColumn, `resizable`: guint) =
  a.TreeViewColumnflag0 = a.TreeViewColumnflag0 or
      (int16(`resizable` shl bp_TGtkTreeViewColumn_resizable) and
      bm_TGtkTreeViewColumn_resizable)

proc clickable*(a: PTreeViewColumn): guint =
  result = (a.TreeViewColumnflag0 and bm_TGtkTreeViewColumn_clickable) shr
      bp_TGtkTreeViewColumn_clickable

proc set_clickable*(a: PTreeViewColumn, `clickable`: guint) =
  a.TreeViewColumnflag0 = a.TreeViewColumnflag0 or
      (int16(`clickable` shl bp_TGtkTreeViewColumn_clickable) and
      bm_TGtkTreeViewColumn_clickable)

proc dirty*(a: PTreeViewColumn): guint =
  result = (a.TreeViewColumnflag0 and bm_TGtkTreeViewColumn_dirty) shr
      bp_TGtkTreeViewColumn_dirty

proc set_dirty*(a: PTreeViewColumn, `dirty`: guint) =
  a.TreeViewColumnflag0 = a.TreeViewColumnflag0 or
      (int16(`dirty` shl bp_TGtkTreeViewColumn_dirty) and
      bm_TGtkTreeViewColumn_dirty)

proc show_sort_indicator*(a: PTreeViewColumn): guint =
  result = (a.TreeViewColumnflag0 and
      bm_TGtkTreeViewColumn_show_sort_indicator) shr
      bp_TGtkTreeViewColumn_show_sort_indicator

proc set_show_sort_indicator*(a: PTreeViewColumn,
                              `show_sort_indicator`: guint) =
  a.TreeViewColumnflag0 = a.TreeViewColumnflag0 or
      (int16(`show_sort_indicator` shl
      bp_TGtkTreeViewColumn_show_sort_indicator) and
      bm_TGtkTreeViewColumn_show_sort_indicator)

proc maybe_reordered*(a: PTreeViewColumn): guint =
  result = (a.TreeViewColumnflag0 and bm_TGtkTreeViewColumn_maybe_reordered) shr
      bp_TGtkTreeViewColumn_maybe_reordered

proc set_maybe_reordered*(a: PTreeViewColumn, `maybe_reordered`: guint) =
  a.TreeViewColumnflag0 = a.TreeViewColumnflag0 or
      (int16(`maybe_reordered` shl bp_TGtkTreeViewColumn_maybe_reordered) and
      bm_TGtkTreeViewColumn_maybe_reordered)

proc reorderable*(a: PTreeViewColumn): guint =
  result = (a.TreeViewColumnflag0 and bm_TGtkTreeViewColumn_reorderable) shr
      bp_TGtkTreeViewColumn_reorderable

proc set_reorderable*(a: PTreeViewColumn, `reorderable`: guint) =
  a.TreeViewColumnflag0 = a.TreeViewColumnflag0 or
      (int16(`reorderable` shl bp_TGtkTreeViewColumn_reorderable) and
      bm_TGtkTreeViewColumn_reorderable)

proc use_resized_width*(a: PTreeViewColumn): guint =
  result = (a.TreeViewColumnflag0 and bm_TGtkTreeViewColumn_use_resized_width) shr
      bp_TGtkTreeViewColumn_use_resized_width

proc set_use_resized_width*(a: PTreeViewColumn, `use_resized_width`: guint) =
  a.TreeViewColumnflag0 = a.TreeViewColumnflag0 or
      (int16(`use_resized_width` shl bp_TGtkTreeViewColumn_use_resized_width) and
      bm_TGtkTreeViewColumn_use_resized_width)

proc flags*(a: PRBNode): guint =
  result = (a.flag0 and bm_TGtkRBNode_flags) shr bp_TGtkRBNode_flags

proc set_flags*(a: PRBNode, `flags`: guint) =
  a.flag0 = a.flag0 or
      (int16(`flags` shl bp_TGtkRBNode_flags) and bm_TGtkRBNode_flags)

proc parity*(a: PRBNode): guint =
  result = (a.flag0 and bm_TGtkRBNode_parity) shr bp_TGtkRBNode_parity

proc set_parity*(a: PRBNode, `parity`: guint) =
  a.flag0 = a.flag0 or
      (int16(`parity` shl bp_TGtkRBNode_parity) and bm_TGtkRBNode_parity)

proc GET_COLOR*(node: PRBNode): guint =
  if node == nil:
    Result = RBNODE_BLACK
  elif (int(flags(node)) and RBNODE_RED) == RBNODE_RED:
    Result = RBNODE_RED
  else:
    Result = RBNODE_BLACK

proc SET_COLOR*(node: PRBNode, color: guint) =
  if node == nil:
    return
  if ((flags(node) and (color)) != color):
    set_flags(node, flags(node) xor cint(RBNODE_RED or RBNODE_BLACK))

proc GET_HEIGHT*(node: PRBNode): gint =
  var if_local1: gint
  if node.children != nil:
    if_local1 = node.children.root.offset
  else:
    if_local1 = 0
  result = node.offset -
      ((node.left.offset) + node.right.offset + if_local1)

proc FLAG_SET*(node: PRBNode, flag: guint): bool =
  result = (node != nil) and ((flags(node) and (flag)) == flag)

proc SET_FLAG*(node: PRBNode, flag: guint16) =
  set_flags(node, (flag) or flags(node))

proc UNSET_FLAG*(node: PRBNode, flag: guint16) =
  set_flags(node, (not (flag)) and flags(node))

proc FLAG_SET*(tree_view: PTreeView, flag: guint): bool =
  result = ((tree_view.priv.flags) and (flag)) == flag

proc HEADER_HEIGHT*(tree_view: PTreeView): int32 =
  var if_local1: int32
  if FLAG_SET(tree_view, TREE_VIEW_HEADERS_VISIBLE):
    if_local1 = tree_view.priv.header_height
  else:
    if_local1 = 0
  result = if_local1

proc COLUMN_REQUESTED_WIDTH*(column: PTreeViewColumn): int32 =
  var MinWidth, MaxWidth: int
  if column.min_width != - 1'i32:
    MinWidth = column.min_width
  else:
    MinWidth = column.requested_width
  if column.max_width != - 1'i32:
    MaxWidth = column.max_width
  else:
    MaxWidth = column.requested_width
  result = CLAMP(column.requested_width, MinWidth, MaxWidth).int32

proc DRAW_EXPANDERS*(tree_view: PTreeView): bool =
  result = (not (FLAG_SET(tree_view, TREE_VIEW_IS_LIST))) and
      (FLAG_SET(tree_view, TREE_VIEW_SHOW_EXPANDERS))

proc COLUMN_DRAG_DEAD_MULTIPLIER*(tree_view: PTreeView): int32 =
  result = 10'i32 * (HEADER_HEIGHT(tree_view))

proc scroll_to_use_align*(a: PTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_scroll_to_use_align) shr
      bp_TGtkTreeViewPrivate_scroll_to_use_align

proc set_scroll_to_use_align*(a: PTreeViewPrivate,
                              `scroll_to_use_align`: guint) =
  a.flag0 = a.flag0 or
      (int16(`scroll_to_use_align` shl
      bp_TGtkTreeViewPrivate_scroll_to_use_align) and
      bm_TGtkTreeViewPrivate_scroll_to_use_align)

proc fixed_height_check*(a: PTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_fixed_height_check) shr
      bp_TGtkTreeViewPrivate_fixed_height_check

proc set_fixed_height_check*(a: PTreeViewPrivate,
                             `fixed_height_check`: guint) =
  a.flag0 = a.flag0 or
      (int16(`fixed_height_check` shl
      bp_TGtkTreeViewPrivate_fixed_height_check) and
      bm_TGtkTreeViewPrivate_fixed_height_check)

proc reorderable*(a: PTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_reorderable) shr
      bp_TGtkTreeViewPrivate_reorderable

proc set_reorderable*(a: PTreeViewPrivate, `reorderable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`reorderable` shl bp_TGtkTreeViewPrivate_reorderable) and
      bm_TGtkTreeViewPrivate_reorderable)

proc header_has_focus*(a: PTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_header_has_focus) shr
      bp_TGtkTreeViewPrivate_header_has_focus

proc set_header_has_focus*(a: PTreeViewPrivate, `header_has_focus`: guint) =
  a.flag0 = a.flag0 or
      (int16(`header_has_focus` shl bp_TGtkTreeViewPrivate_header_has_focus) and
      bm_TGtkTreeViewPrivate_header_has_focus)

proc drag_column_window_state*(a: PTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_drag_column_window_state) shr
      bp_TGtkTreeViewPrivate_drag_column_window_state

proc set_drag_column_window_state*(a: PTreeViewPrivate,
                                   `drag_column_window_state`: guint) =
  a.flag0 = a.flag0 or
      (int16(`drag_column_window_state` shl
      bp_TGtkTreeViewPrivate_drag_column_window_state) and
      bm_TGtkTreeViewPrivate_drag_column_window_state)

proc has_rules*(a: PTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_has_rules) shr
      bp_TGtkTreeViewPrivate_has_rules

proc set_has_rules*(a: PTreeViewPrivate, `has_rules`: guint) =
  a.flag0 = a.flag0 or
      (int16(`has_rules` shl bp_TGtkTreeViewPrivate_has_rules) and
      bm_TGtkTreeViewPrivate_has_rules)

proc mark_rows_col_dirty*(a: PTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_mark_rows_col_dirty) shr
      bp_TGtkTreeViewPrivate_mark_rows_col_dirty

proc set_mark_rows_col_dirty*(a: PTreeViewPrivate,
                              `mark_rows_col_dirty`: guint) =
  a.flag0 = a.flag0 or
      (int16(`mark_rows_col_dirty` shl
      bp_TGtkTreeViewPrivate_mark_rows_col_dirty) and
      bm_TGtkTreeViewPrivate_mark_rows_col_dirty)

proc enable_search*(a: PTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_enable_search) shr
      bp_TGtkTreeViewPrivate_enable_search

proc set_enable_search*(a: PTreeViewPrivate, `enable_search`: guint) =
  a.flag0 = a.flag0 or
      (int16(`enable_search` shl bp_TGtkTreeViewPrivate_enable_search) and
      bm_TGtkTreeViewPrivate_enable_search)

proc disable_popdown*(a: PTreeViewPrivate): guint =
  result = (a.flag0 and bm_TGtkTreeViewPrivate_disable_popdown) shr
      bp_TGtkTreeViewPrivate_disable_popdown

proc set_disable_popdown*(a: PTreeViewPrivate, `disable_popdown`: guint) =
  a.flag0 = a.flag0 or
      (int16(`disable_popdown` shl bp_TGtkTreeViewPrivate_disable_popdown) and
      bm_TGtkTreeViewPrivate_disable_popdown)

proc SET_FLAG*(tree_view: PTreeView, flag: guint) =
  tree_view.priv.flags = tree_view.priv.flags or (flag)

proc UNSET_FLAG*(tree_view: PTreeView, flag: guint) =
  tree_view.priv.flags = tree_view.priv.flags and not (flag)

proc TYPE_TREE_VIEW*(): GType =
  result = tree_view_get_type()

proc TREE_VIEW*(obj: pointer): PTreeView =
  result = cast[PTreeView](CHECK_CAST(obj, TYPE_TREE_VIEW()))

proc TREE_VIEW_CLASS*(klass: pointer): PTreeViewClass =
  result = cast[PTreeViewClass](CHECK_CLASS_CAST(klass, TYPE_TREE_VIEW()))

proc IS_TREE_VIEW*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_TREE_VIEW())

proc IS_TREE_VIEW_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_TREE_VIEW())

proc TREE_VIEW_GET_CLASS*(obj: pointer): PTreeViewClass =
  result = cast[PTreeViewClass](CHECK_GET_CLASS(obj, TYPE_TREE_VIEW()))

proc TYPE_VBUTTON_BOX*(): GType =
  result = vbutton_box_get_type()

proc VBUTTON_BOX*(obj: pointer): PVButtonBox =
  result = cast[PVButtonBox](CHECK_CAST(obj, TYPE_VBUTTON_BOX()))

proc VBUTTON_BOX_CLASS*(klass: pointer): PVButtonBoxClass =
  result = cast[PVButtonBoxClass](CHECK_CLASS_CAST(klass, TYPE_VBUTTON_BOX()))

proc IS_VBUTTON_BOX*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_VBUTTON_BOX())

proc IS_VBUTTON_BOX_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_VBUTTON_BOX())

proc VBUTTON_BOX_GET_CLASS*(obj: pointer): PVButtonBoxClass =
  result = cast[PVButtonBoxClass](CHECK_GET_CLASS(obj, TYPE_VBUTTON_BOX()))

proc TYPE_VIEWPORT*(): GType =
  result = viewport_get_type()

proc VIEWPORT*(obj: pointer): PViewport =
  result = cast[PViewport](CHECK_CAST(obj, TYPE_VIEWPORT()))

proc VIEWPORT_CLASS*(klass: pointer): PViewportClass =
  result = cast[PViewportClass](CHECK_CLASS_CAST(klass, TYPE_VIEWPORT()))

proc IS_VIEWPORT*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_VIEWPORT())

proc IS_VIEWPORT_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_VIEWPORT())

proc VIEWPORT_GET_CLASS*(obj: pointer): PViewportClass =
  result = cast[PViewportClass](CHECK_GET_CLASS(obj, TYPE_VIEWPORT()))

proc TYPE_VPANED*(): GType =
  result = vpaned_get_type()

proc VPANED*(obj: pointer): PVPaned =
  result = cast[PVPaned](CHECK_CAST(obj, TYPE_VPANED()))

proc VPANED_CLASS*(klass: pointer): PVPanedClass =
  result = cast[PVPanedClass](CHECK_CLASS_CAST(klass, TYPE_VPANED()))

proc IS_VPANED*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_VPANED())

proc IS_VPANED_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_VPANED())

proc VPANED_GET_CLASS*(obj: pointer): PVPanedClass =
  result = cast[PVPanedClass](CHECK_GET_CLASS(obj, TYPE_VPANED()))

proc TYPE_VRULER*(): GType =
  result = vruler_get_type()

proc VRULER*(obj: pointer): PVRuler =
  result = cast[PVRuler](CHECK_CAST(obj, TYPE_VRULER()))

proc VRULER_CLASS*(klass: pointer): PVRulerClass =
  result = cast[PVRulerClass](CHECK_CLASS_CAST(klass, TYPE_VRULER()))

proc IS_VRULER*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_VRULER())

proc IS_VRULER_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_VRULER())

proc VRULER_GET_CLASS*(obj: pointer): PVRulerClass =
  result = cast[PVRulerClass](CHECK_GET_CLASS(obj, TYPE_VRULER()))

proc TYPE_VSCALE*(): GType =
  result = vscale_get_type()

proc VSCALE*(obj: pointer): PVScale =
  result = cast[PVScale](CHECK_CAST(obj, TYPE_VSCALE()))

proc VSCALE_CLASS*(klass: pointer): PVScaleClass =
  result = cast[PVScaleClass](CHECK_CLASS_CAST(klass, TYPE_VSCALE()))

proc IS_VSCALE*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_VSCALE())

proc IS_VSCALE_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_VSCALE())

proc VSCALE_GET_CLASS*(obj: pointer): PVScaleClass =
  result = cast[PVScaleClass](CHECK_GET_CLASS(obj, TYPE_VSCALE()))

proc TYPE_VSCROLLBAR*(): GType =
  result = vscrollbar_get_type()

proc VSCROLLBAR*(obj: pointer): PVScrollbar =
  result = cast[PVScrollbar](CHECK_CAST(obj, TYPE_VSCROLLBAR()))

proc VSCROLLBAR_CLASS*(klass: pointer): PVScrollbarClass =
  result = cast[PVScrollbarClass](CHECK_CLASS_CAST(klass, TYPE_VSCROLLBAR()))

proc IS_VSCROLLBAR*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_VSCROLLBAR())

proc IS_VSCROLLBAR_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_VSCROLLBAR())

proc VSCROLLBAR_GET_CLASS*(obj: pointer): PVScrollbarClass =
  result = cast[PVScrollbarClass](CHECK_GET_CLASS(obj, TYPE_VSCROLLBAR()))

proc TYPE_VSEPARATOR*(): GType =
  result = vseparator_get_type()

proc VSEPARATOR*(obj: pointer): PVSeparator =
  result = cast[PVSeparator](CHECK_CAST(obj, TYPE_VSEPARATOR()))

proc VSEPARATOR_CLASS*(klass: pointer): PVSeparatorClass =
  result = cast[PVSeparatorClass](CHECK_CLASS_CAST(klass, TYPE_VSEPARATOR()))

proc IS_VSEPARATOR*(obj: pointer): bool =
  result = CHECK_TYPE(obj, TYPE_VSEPARATOR())

proc IS_VSEPARATOR_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, TYPE_VSEPARATOR())

proc VSEPARATOR_GET_CLASS*(obj: pointer): PVSeparatorClass =
  # these were missing:
  result = cast[PVSeparatorClass](CHECK_GET_CLASS(obj, TYPE_VSEPARATOR()))

type
  Tcelllayout {.pure, final.} = object

  PCellLayout* = tcelllayout
  PPGtkCellLayout* = ptr PCellLayout
  PSignalRunType* = ptr TSignalRunType
  TSignalRunType* = int32
  PFileChooserAction* = ptr TFileChooserAction
  TFileChooserAction* = enum
    FILE_CHOOSER_ACTION_OPEN, FILE_CHOOSER_ACTION_SAVE,
    FILE_CHOOSER_ACTION_SELECT_FOLDER, FILE_CHOOSER_ACTION_CREATE_FOLDER
  PFileChooserError* = ptr TFileChooserError
  TFileChooserError* = enum
    FILE_CHOOSER_ERROR_NONEXISTENT, FILE_CHOOSER_ERROR_BAD_FILENAME

  TFileChooser = object of TDialog
  PFileChooser* = ptr TFileChooser
  PPFileChooser* = ptr PFileChooser


const
  ARG_READWRITE* = ARG_READABLE or ARG_WRITABLE

proc entry_add_signal*(binding_set: PBindingSet, keyval: guint,
                               modifiers: gdk2.TModifierType,
                               signal_name: cstring, n_args: guint){.varargs,
    importc: "gtk_binding_entry_add_signal", cdecl, dynlib: lib.}
proc clist_new_with_titles*(columns: gint): PCList{.varargs, cdecl,
    importc: "gtk_clist_new_with_titles", dynlib: lib.}
proc prepend*(clist: PCList): gint{.importc: "gtk_clist_prepend", varargs,
    cdecl, dynlib: lib.}
proc append*(clist: PCList): gint{.importc: "gtk_clist_append", varargs,
    cdecl, dynlib: lib.}
proc insert*(clist: PCList, row: gint): gint{.varargs, cdecl,
    importc: "gtk_clist_insert", dynlib: lib.}
proc set_attributes*(cell_layout: PCellLayout, cell: PCellRenderer){.
    cdecl, varargs, importc: "gtk_cell_layout_set_attributes", dynlib: lib,
    importc: "gtk_cell_layout_set_attributes".}
proc add_with_properties*(container: PContainer, widget: PWidget,
                                    first_prop_name: cstring){.varargs,
    importc: "gtk_container_add_with_properties", cdecl, dynlib: lib.}
proc child_set*(container: PContainer, child: PWidget,
                          first_prop_name: cstring){.varargs, cdecl,
    importc: "gtk_container_child_set", dynlib: lib.}
proc child_get*(container: PContainer, child: PWidget,
                          first_prop_name: cstring){.varargs, cdecl,
    importc: "gtk_container_child_get", dynlib: lib.}
proc child_set_valist*(container: PContainer, child: PWidget,
                                 first_property_name: cstring){.varargs,
    importc: "gtk_container_child_set_valist", cdecl, dynlib: lib.}
proc child_get_valist*(container: PContainer, child: PWidget,
                                 first_property_name: cstring){.varargs,
    importc: "gtk_container_child_get_valist", cdecl, dynlib: lib.}
proc ctree_new_with_titles*(columns: gint, tree_column: gint): PCTree{.
    importc: "gtk_ctree_new_with_titles", varargs, cdecl, dynlib: lib.}
proc get_vector*(curve: PCurve, veclen: int32){.varargs, cdecl,
    importc: "gtk_curve_get_vector", dynlib: lib.}
proc set_vector*(curve: PCurve, veclen: int32){.varargs, cdecl,
    importc: "gtk_curve_set_vector", dynlib: lib.}
proc add_buttons*(dialog: PDialog, first_button_text: cstring){.varargs,
    cdecl, importc: "gtk_dialog_add_buttons", dynlib: lib.}
proc dialog_new_with_buttons*(title: cstring, parent: PWindow,
                              flags: TDialogFlags, first_button_text: cstring): PDialog{.
    varargs, cdecl, importc: "gtk_dialog_new_with_buttons", dynlib: lib.}
proc list_store_new*(n_columns: gint): PListStore{.varargs, cdecl,
    importc: "gtk_list_store_new", dynlib: lib.}
proc set*(list_store: PListStore, iter: PTreeIter){.varargs, cdecl,
    importc: "gtk_list_store_set", dynlib: lib.}
proc set_valist*(list_store: PListStore, iter: PTreeIter){.varargs,
    cdecl, importc: "gtk_list_store_set_valist", dynlib: lib.}
proc message_dialog_new*(parent: PWindow, flags: TDialogFlags,
                         thetype: TMessageType, buttons: TButtonsType,
                         message_format: cstring): PMessageDialog{.varargs,
    cdecl, importc: "gtk_message_dialog_new", dynlib: lib.}
proc set_markup*(msgDialog: PMessageDialog, str: cstring) {.cdecl,
    importc: "gtk_message_dialog_set_markup", dynlib: lib.}

proc signal_new*(name: cstring, signal_flags: TSignalRunType,
                 object_type: TType, function_offset: guint,
                 marshaller: TSignalMarshaller, return_val: TType, n_args: guint): guint{.
    varargs, importc: "gtk_signal_new", cdecl, dynlib: lib.}
proc signal_emit*(anObject: PObject, signal_id: guint){.varargs, cdecl,
    importc: "gtk_signal_emit", dynlib: lib.}
proc signal_emit_by_name*(anObject: PObject, name: cstring){.varargs, cdecl,
    importc: "gtk_signal_emit_by_name", dynlib: lib.}
proc insert_with_tags*(buffer: PTextBuffer, iter: PTextIter,
                                   text: cstring, length: gint,
                                   first_tag: PTextTag){.varargs,
    importc: "gtk_text_buffer_insert_with_tags", cdecl, dynlib: lib.}
proc insert_with_tags_by_name*(buffer: PTextBuffer, iter: PTextIter,
    text: cstring, length: gint, first_tag_name: cstring){.varargs,
    importc: "gtk_text_buffer_insert_with_tags_by_name", cdecl, dynlib: lib.}
proc create_tag*(buffer: PTextBuffer, tag_name: cstring,
                             first_property_name: cstring): PTextTag{.varargs,
    importc: "gtk_text_buffer_create_tag", cdecl, dynlib: lib.}
proc get*(tree_model: PTreeModel, iter: PTreeIter){.varargs,
    importc: "gtk_tree_model_get", cdecl, dynlib: lib.}
proc get_valist*(tree_model: PTreeModel, iter: PTreeIter){.varargs,
    importc: "gtk_tree_model_get_valist", cdecl, dynlib: lib.}
proc tree_store_new*(n_columns: gint): PTreeStore{.varargs, cdecl,
    importc: "gtk_tree_store_new", dynlib: lib.}
proc set*(tree_store: PTreeStore, iter: PTreeIter){.varargs, cdecl,
    importc: "gtk_tree_store_set", dynlib: lib.}
proc set_valist*(tree_store: PTreeStore, iter: PTreeIter){.varargs,
    cdecl, importc: "gtk_tree_store_set_valist", dynlib: lib.}
proc iter_is_valid*(tree_store: PTreeStore, iter: PTreeIter): gboolean{.
    cdecl, importc: "gtk_tree_store_iter_is_valid", dynlib: lib.}
proc reorder*(tree_store: PTreeStore, parent: PTreeIter,
                         new_order: pgint){.cdecl,
    importc: "gtk_tree_store_reorder", dynlib: lib.}
proc swap*(tree_store: PTreeStore, a: PTreeIter, b: PTreeIter){.
    cdecl, importc: "gtk_tree_store_swap", dynlib: lib.}
proc move_before*(tree_store: PTreeStore, iter: PTreeIter,
                             position: PTreeIter){.cdecl,
    importc: "gtk_tree_store_move_before", dynlib: lib.}
proc move_after*(tree_store: PTreeStore, iter: PTreeIter,
                            position: PTreeIter){.cdecl,
    importc: "gtk_tree_store_move_after", dynlib: lib.}
proc insert_column_with_attributes*(tree_view: PTreeView,
    position: gint, title: cstring, cell: PCellRenderer): gint{.varargs,
    importc: "gtk_tree_view_insert_column_with_attributes", cdecl, dynlib: lib.}
proc tree_view_column_new_with_attributes*(title: cstring, cell: PCellRenderer): PTreeViewColumn{.
    importc: "gtk_tree_view_column_new_with_attributes", varargs, cdecl,
    dynlib: lib.}
proc column_set_attributes*(tree_column: PTreeViewColumn,
                                      cell_renderer: PCellRenderer){.
    importc: "gtk_tree_view_column_set_attributes", varargs, cdecl, dynlib: lib.}
proc widget_new*(thetype: TType, first_property_name: cstring): PWidget{.
    importc: "gtk_widget_new", varargs, cdecl, dynlib: lib.}
proc set*(widget: PWidget, first_property_name: cstring){.varargs,
    importc: "gtk_widget_set", cdecl, dynlib: lib.}
proc queue_clear*(widget: PWidget){.importc: "gtk_widget_queue_clear",
    cdecl, dynlib: lib.}
proc queue_clear_area*(widget: PWidget, x: gint, y: gint, width: gint,
                              height: gint){.cdecl,
    importc: "gtk_widget_queue_clear_area", dynlib: lib.}
proc draw*(widget: PWidget, area: gdk2.PRectangle){.cdecl,
    importc: "gtk_widget_draw", dynlib: lib.}
proc style_get_valist*(widget: PWidget, first_property_name: cstring){.
    varargs, cdecl, importc: "gtk_widget_style_get_valist", dynlib: lib.}
proc style_get*(widget: PWidget, first_property_name: cstring){.varargs,
    cdecl, importc: "gtk_widget_style_get", dynlib: lib.}
proc file_chooser_dialog_new*(title: cstring, parent: PWindow,
                              action: TFileChooserAction,
                              first_button_text: cstring): PFileChooser{.cdecl,
    varargs, dynlib: lib, importc: "gtk_file_chooser_dialog_new".}

proc file_chooser_dialog_new_with_backend*(title: cstring, parent: PWindow,
    action: TFileChooserAction, backend: cstring, first_button_text: cstring): PFileChooser{.
    varargs, cdecl, dynlib: lib,
    importc: "gtk_file_chooser_dialog_new_with_backend".}
proc reference*(anObject: PObject): PObject{.cdecl, importc: "gtk_object_ref",
    dynlib: lib.}
proc unref*(anObject: PObject){.cdecl, importc: "gtk_object_unref",
                                       dynlib: lib.}
proc weakref*(anObject: PObject, notify: TDestroyNotify, data: gpointer){.
    cdecl, importc: "gtk_object_weakref", dynlib: lib.}
proc weakunref*(anObject: PObject, notify: TDestroyNotify, data: gpointer){.
    cdecl, importc: "gtk_object_weakunref", dynlib: lib.}
proc set_data*(anObject: PObject, key: cstring, data: gpointer){.cdecl,
    importc: "gtk_object_set_data", dynlib: lib.}
proc set_data_full*(anObject: PObject, key: cstring, data: gpointer,
                           destroy: TDestroyNotify){.
    importc: "gtk_object_set_data_full", cdecl, dynlib: lib.}
proc remove_data*(anObject: PObject, key: cstring){.cdecl,
    importc: "gtk_object_remove_data", dynlib: lib.}
proc get_data*(anObject: PObject, key: cstring): gpointer{.cdecl,
    importc: "gtk_object_get_data", dynlib: lib.}
proc remove_no_notify*(anObject: PObject, key: cstring){.cdecl,
    importc: "gtk_object_remove_no_notify", dynlib: lib.}
proc set_user_data*(anObject: PObject, data: gpointer){.cdecl,
    importc: "gtk_object_set_user_data", dynlib: lib.}
proc get_user_data*(anObject: PObject): gpointer{.cdecl,
    importc: "gtk_object_get_user_data", dynlib: lib.}
proc set_data_by_id*(anObject: PObject, data_id: TGQuark, data: gpointer){.
    cdecl, importc: "gtk_object_set_data_by_id", dynlib: lib.}
proc set_data_by_id_full*(anObject: PObject, data_id: TGQuark,
                                 data: gpointer, destroy: TDestroyNotify){.
    cdecl, importc: "gtk_object_set_data_by_id_full", dynlib: lib.}
proc get_data_by_id*(anObject: PObject, data_id: TGQuark): gpointer{.
    cdecl, importc: "gtk_object_get_data_by_id", dynlib: lib.}
proc remove_data_by_id*(anObject: PObject, data_id: TGQuark){.cdecl,
    importc: "gtk_object_remove_data_by_id", dynlib: lib.}
proc remove_no_notify_by_id*(anObject: PObject, key_id: TGQuark){.cdecl,
    importc: "gtk_object_remove_no_notify_by_id", dynlib: lib.}
proc object_data_try_key*(str: cstring): TGQuark{.cdecl,
    importc: "gtk_object_data_try_key", dynlib: lib.}
proc object_data_force_id*(str: cstring): TGQuark{.cdecl,
    importc: "gtk_object_data_force_id", dynlib: lib.}
proc get*(anObject: PObject, first_property_name: cstring){.cdecl,
    importc: "gtk_object_get", varargs, dynlib: lib.}
proc set*(anObject: PObject, first_property_name: cstring){.cdecl,
    importc: "gtk_object_set", varargs, dynlib: lib.}
proc object_add_arg_type*(arg_name: cstring, arg_type: TType, arg_flags: guint,
                          arg_id: guint){.cdecl,
    importc: "gtk_object_add_arg_type", dynlib: lib.}

type
  TFileFilter {.pure, final.} = object
  PFileFilter* = ptr TFileFilter
  PPGtkFileFilter* = ptr PFileFilter
  PFileFilterFlags* = ptr TFileFilterFlags
  TFileFilterFlags* = enum
    FILE_FILTER_FILENAME = 1 shl 0, FILE_FILTER_URI = 1 shl 1,
    FILE_FILTER_DISPLAY_NAME = 1 shl 2, FILE_FILTER_MIME_TYPE = 1 shl 3
  PFileFilterInfo* = ptr TFileFilterInfo
  TFileFilterInfo*{.final, pure.} = object
    contains*: TFileFilterFlags
    filename*: cstring
    uri*: cstring
    display_name*: cstring
    mime_type*: cstring

  TFileFilterFunc* = proc (filter_info: PFileFilterInfo, data: gpointer): gboolean{.
      cdecl.}

proc TYPE_FILE_FILTER*(): GType
proc FILE_FILTER*(obj: pointer): PFileFilter
proc IS_FILE_FILTER*(obj: pointer): gboolean
proc file_filter_get_type*(): GType{.cdecl, dynlib: lib,
                                     importc: "gtk_file_filter_get_type".}
proc file_filter_new*(): PFileFilter{.cdecl, dynlib: lib,
                                      importc: "gtk_file_filter_new".}
proc set_name*(filter: PFileFilter, name: cstring){.cdecl,
    dynlib: lib, importc: "gtk_file_filter_set_name".}
proc get_name*(filter: PFileFilter): cstring{.cdecl, dynlib: lib,
    importc: "gtk_file_filter_get_name".}
proc add_mime_type*(filter: PFileFilter, mime_type: cstring){.cdecl,
    dynlib: lib, importc: "gtk_file_filter_add_mime_type".}
proc add_pattern*(filter: PFileFilter, pattern: cstring){.cdecl,
    dynlib: lib, importc: "gtk_file_filter_add_pattern".}
proc add_custom*(filter: PFileFilter, needed: TFileFilterFlags,
                             func: TFileFilterFunc, data: gpointer,
                             notify: TGDestroyNotify){.cdecl, dynlib: lib,
    importc: "gtk_file_filter_add_custom".}
proc get_needed*(filter: PFileFilter): TFileFilterFlags{.cdecl,
    dynlib: lib, importc: "gtk_file_filter_get_needed".}
proc filter*(filter: PFileFilter, filter_info: PFileFilterInfo): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_file_filter_filter".}
proc TYPE_FILE_FILTER(): GType =
  result = file_filter_get_type()

proc FILE_FILTER(obj: pointer): PFileFilter =
  result = cast[PFileFilter](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_FILE_FILTER()))

proc IS_FILE_FILTER(obj: pointer): gboolean =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_FILE_FILTER())

proc file_chooser_get_type*(): GType{.cdecl, dynlib: lib,
                                      importc: "gtk_file_chooser_get_type".}
proc file_chooser_error_quark*(): TGQuark{.cdecl, dynlib: lib,
    importc: "gtk_file_chooser_error_quark".}
proc TYPE_FILE_CHOOSER*(): GType =
  result = file_chooser_get_type()

proc FILE_CHOOSER*(obj: pointer): PFileChooser =
  result = cast[PFileChooser](G_TYPE_CHECK_INSTANCE_CAST(obj,
      TYPE_FILE_CHOOSER()))

proc IS_FILE_CHOOSER*(obj: pointer): gboolean =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_FILE_CHOOSER())

proc set_action*(chooser: PFileChooser, action: TFileChooserAction){.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_set_action".}
proc get_action*(chooser: PFileChooser): TFileChooserAction{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_get_action".}
proc set_local_only*(chooser: PFileChooser, local_only: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_set_local_only".}
proc get_local_only*(chooser: PFileChooser): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_get_local_only".}
proc set_select_multiple*(chooser: PFileChooser,
                                       select_multiple: gboolean){.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_set_select_multiple".}
proc get_select_multiple*(chooser: PFileChooser): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_get_select_multiple".}
proc set_current_name*(chooser: PFileChooser, name: cstring){.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_set_current_name".}
proc get_filename*(chooser: PFileChooser): cstring{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_get_filename".}
proc set_filename*(chooser: PFileChooser, filename: cstring): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_set_filename".}
proc select_filename*(chooser: PFileChooser, filename: cstring): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_select_filename".}
proc unselect_filename*(chooser: PFileChooser, filename: cstring){.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_unselect_filename".}
proc select_all*(chooser: PFileChooser){.cdecl, dynlib: lib,
    importc: "gtk_file_chooser_select_all".}
proc unselect_all*(chooser: PFileChooser){.cdecl, dynlib: lib,
    importc: "gtk_file_chooser_unselect_all".}
proc get_filenames*(chooser: PFileChooser): PGSList{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_get_filenames".}
proc set_current_folder*(chooser: PFileChooser, filename: cstring): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_set_current_folder".}
proc get_current_folder*(chooser: PFileChooser): cstring{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_get_current_folder".}
proc get_uri*(chooser: PFileChooser): cstring{.cdecl, dynlib: lib,
    importc: "gtk_file_chooser_get_uri".}
proc set_uri*(chooser: PFileChooser, uri: cstring): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_set_uri".}
proc select_uri*(chooser: PFileChooser, uri: cstring): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_select_uri".}
proc unselect_uri*(chooser: PFileChooser, uri: cstring){.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_unselect_uri".}
proc get_uris*(chooser: PFileChooser): PGSList{.cdecl, dynlib: lib,
    importc: "gtk_file_chooser_get_uris".}
proc set_current_folder_uri*(chooser: PFileChooser, uri: cstring): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_set_current_folder_uri".}
proc get_current_folder_uri*(chooser: PFileChooser): cstring{.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_get_current_folder_uri".}
proc set_preview_widget*(chooser: PFileChooser,
                                      preview_widget: PWidget){.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_set_preview_widget".}
proc get_preview_widget*(chooser: PFileChooser): PWidget{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_get_preview_widget".}
proc set_preview_widget_active*(chooser: PFileChooser,
    active: gboolean){.cdecl, dynlib: lib,
                       importc: "gtk_file_chooser_set_preview_widget_active".}
proc get_preview_widget_active*(chooser: PFileChooser): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_get_preview_widget_active".}
proc set_use_preview_label*(chooser: PFileChooser,
    use_label: gboolean){.cdecl, dynlib: lib,
                          importc: "gtk_file_chooser_set_use_preview_label".}
proc get_use_preview_label*(chooser: PFileChooser): gboolean{.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_get_use_preview_label".}
proc get_preview_filename*(chooser: PFileChooser): cstring{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_get_preview_filename".}
proc get_preview_uri*(chooser: PFileChooser): cstring{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_get_preview_uri".}
proc set_extra_widget*(chooser: PFileChooser, extra_widget: PWidget){.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_set_extra_widget".}
proc get_extra_widget*(chooser: PFileChooser): PWidget{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_get_extra_widget".}
proc add_filter*(chooser: PFileChooser, filter: PFileFilter){.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_add_filter".}
proc remove_filter*(chooser: PFileChooser, filter: PFileFilter){.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_remove_filter".}
proc list_filters*(chooser: PFileChooser): PGSList{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_list_filters".}
proc set_filter*(chooser: PFileChooser, filter: PFileFilter){.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_set_filter".}
proc get_filter*(chooser: PFileChooser): PFileFilter{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_get_filter".}
proc add_shortcut_folder*(chooser: PFileChooser, folder: cstring,
                                       error: pointer): gboolean{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_add_shortcut_folder".}
proc remove_shortcut_folder*(chooser: PFileChooser,
    folder: cstring, error: pointer): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_file_chooser_remove_shortcut_folder".}
proc list_shortcut_folders*(chooser: PFileChooser): PGSList{.cdecl,
    dynlib: lib, importc: "gtk_file_chooser_list_shortcut_folders".}
proc add_shortcut_folder_uri*(chooser: PFileChooser, uri: cstring,
    error: pointer): gboolean{.cdecl, dynlib: lib, importc: "gtk_file_chooser_add_shortcut_folder_uri".}
proc remove_shortcut_folder_uri*(chooser: PFileChooser,
    uri: cstring, error: pointer): gboolean{.cdecl, dynlib: lib,
    importc: "gtk_file_chooser_remove_shortcut_folder_uri".}
proc list_shortcut_folder_uris*(chooser: PFileChooser): PGSList{.
    cdecl, dynlib: lib, importc: "gtk_file_chooser_list_shortcut_folder_uris".}
proc set_do_overwrite_confirmation*(chooser: PFileChooser,
    do_overwrite_confirmation: gboolean){.cdecl, dynlib: lib,
    importc: "gtk_file_chooser_set_do_overwrite_confirmation".}

proc get_realized*(w: PWidget): gboolean {.cdecl, dynlib: lib,
                                           importc: "gtk_widget_get_realized".}

proc set_skip_taskbar_hint*(window: PWindow, setting: gboolean){.cdecl,
  dynlib: lib, importc: "gtk_window_set_skip_taskbar_hint".}

type
  TTooltip* {.pure, final.} = object
  PTooltip* = ptr TTooltip

proc set_tooltip_text*(w: PWidget, t: cstring){.cdecl,
  dynlib: lib, importc: "gtk_widget_set_tooltip_text".}

proc get_tooltip_text*(w: PWidget): cstring{.cdecl,
  dynlib: lib, importc: "gtk_widget_get_tooltip_text".}

proc set_tooltip_markup*(w: PWidget, m: cstring) {.cdecl, dynlib: lib,
  importc: "gtk_widget_set_tooltip_markup".}

proc get_tooltip_markup*(w: PWidget): cstring {.cdecl, dynlib: lib,
  importc: "gtk_widget_get_tooltip_markup".}

proc set_tooltip_column*(w: PTreeview, column: gint){.cdecl,
  dynlib: lib, importc: "gtk_tree_view_set_tooltip_column".}

proc trigger_tooltip_query*(widg: PWidget){.cdecl, dynlib: lib,
  importc: "gtk_widget_trigger_tooltip_query".}

proc trigger_tooltip_query*(widg: PTooltip){.cdecl, dynlib: lib,
  importc: "gtk_tooltip_trigger_tooltip_query".}

proc set_has_tooltip*(widget: PWidget, b: gboolean){.cdecl, dynlib: lib,
  importc: "gtk_widget_set_has_tooltip".}

proc get_has_tooltip*(widget: PWidget): gboolean{.cdecl, dynlib: lib,
  importc: "gtk_widget_get_has_tooltip".}

proc set_markup*(tp: PTooltip, mk: cstring){.cdecl, dynlib: lib,
  importc: "gtk_tooltip_set_markup".}

proc set_visible_window*(evBox: PEventBox, v: gboolean){.cdecl, dynlib: lib,
  importc: "gtk_event_box_set_visible_window".}

proc get_vadjustment*(scrolled_window: PTextView): PAdjustment{.
    cdecl, dynlib: lib, importc: "gtk_text_view_get_vadjustment".}

type
  TInfoBar* = object of THBox
  PInfoBar* = ptr TInfoBar

proc info_bar_new*(): PInfoBar{.cdecl, dynlib: lib, importc: "gtk_info_bar_new".}
proc info_bar_new_with_buttons*(first_button_text: cstring): PInfoBar {.cdecl, dynlib:lib,
    varargs, importc: "gtk_info_bar_new_with_buttons".}
proc add_action_widget*(infobar: PInfoBar, child: PWidget, respID: gint) {.
    cdecl, dynlib: lib, importc: "gtk_info_bar_add_action_widget".}
proc add_button*(infobar: PInfoBar, btnText: cstring, respID: gint): PWidget{.
    cdecl, dynlib: lib, importc: "gtk_info_bar_add_button".}
proc set_response_sensitive*(infobar: PInfoBar, respID: gint, setting: gboolean){.
    cdecl, dynlib: lib, importc: "gtk_info_bar_set_response_sensitive".}
proc set_default_response*(infobar: PInfoBar, respID: gint){.cdecl,
    dynlib: lib, importc: "gtk_info_bar_set_default_response".}
proc response*(infobar: PInfoBar, respID: gint){.cdecl, dynlib: lib,
    importc: "gtk_info_bar_response".}
proc set_message_type*(infobar: PInfoBar, messageType: TMessageType){.cdecl,
    dynlib: lib, importc: "gtk_info_bar_set_message_type".}
proc get_message_type*(infobar: PInfoBar): TMessageType{.cdecl, dynlib: lib,
    importc: "gtk_info_bar_get_message_type".}
proc get_action_area*(infobar: PInfoBar): PWidget{.cdecl, dynlib: lib,
    importc: "gtk_info_bar_get_action_area".}
proc get_content_area*(infobar: PInfoBar): PContainer{.cdecl, dynlib: lib,
    importc: "gtk_info_bar_get_content_area".}

type
  TComboBox* = object of TWidget
  PComboBox* = ptr TComboBox

proc comboBoxNew*(): PComboBox{.cdecl, importc: "gtk_combo_box_new", dynlib: lib.}
proc comboBox_new_with_entry*(): PComboBox{.cdecl,
                                       importc: "gtk_combo_box_new_with_entry",
                                       dynlib: lib.}
proc comboBox_new_with_model*(model: PTreeModel): PComboBox{.cdecl,
    importc: "gtk_combo_box_new_with_model", dynlib: lib.}
proc comboBox_new_with_model_and_entry*(model: PTreeModel): PComboBox{.cdecl,
    importc: "gtk_combo_box_new_with_model_and_entry", dynlib: lib.}

proc get_wrap_width*(combo_box: PComboBox): gint{.cdecl,
    importc: "gtk_combo_box_get_wrap_width", dynlib: lib.}
proc set_wrap_width*(combo_box: PComboBox; width: gint){.cdecl,
    importc: "gtk_combo_box_set_wrap_width", dynlib: lib.}
proc get_row_span_column*(combo_box: PComboBox): gint{.cdecl,
    importc: "gtk_combo_box_get_row_span_column", dynlib: lib.}
proc set_row_span_column*(combo_box: PComboBox; row_span: gint){.cdecl,
    importc: "gtk_combo_box_set_row_span_column", dynlib: lib.}
proc get_column_span_column*(combo_box: PComboBox): gint{.cdecl,
    importc: "gtk_combo_box_get_column_span_column", dynlib: lib.}
proc set_column_span_column*(combo_box: PComboBox; column_span: gint){.
    cdecl, importc: "gtk_combo_box_set_column_span_column", dynlib: lib.}
proc get_add_tearoffs*(combo_box: PComboBox): gboolean{.cdecl,
    importc: "gtk_combo_box_get_add_tearoffs", dynlib: lib.}
proc set_add_tearoffs*(combo_box: PComboBox; add_tearoffs: gboolean){.
    cdecl, importc: "gtk_combo_box_set_add_tearoffs", dynlib: lib.}
proc get_title*(combo_box: PComboBox): ptr gchar{.cdecl,
    importc: "gtk_combo_box_get_title", dynlib: lib.}
proc set_title*(combo_box: PComboBox; title: ptr gchar){.cdecl,
    importc: "gtk_combo_box_set_title", dynlib: lib.}
proc get_focus_on_click*(combo: PComboBox): gboolean{.cdecl,
    importc: "gtk_combo_box_get_focus_on_click", dynlib: lib.}
proc set_focus_on_click*(combo: PComboBox; focus_on_click: gboolean){.
    cdecl, importc: "gtk_combo_box_set_focus_on_click", dynlib: lib.}

proc get_active*(combo_box: PComboBox): gint{.cdecl,
    importc: "gtk_combo_box_get_active", dynlib: lib.}
proc set_active*(combo_box: PComboBox; index: gint){.cdecl,
    importc: "gtk_combo_box_set_active", dynlib: lib.}
proc get_active_iter*(combo_box: PComboBox; iter: PTreeIter): gboolean{.
    cdecl, importc: "gtk_combo_box_get_active_iter", dynlib: lib.}
proc set_active_iter*(combo_box: PComboBox; iter: PTreeIter){.cdecl,
    importc: "gtk_combo_box_set_active_iter", dynlib: lib.}

proc set_model*(combo_box: PComboBox; model: PTreeModel){.cdecl,
    importc: "gtk_combo_box_set_model", dynlib: lib.}
proc get_model*(combo_box: PComboBox): PTreeModel{.cdecl,
    importc: "gtk_combo_box_get_model", dynlib: lib.}
discard """proc get_row_separator_func*(combo_box: PComboBox): GtkTreeViewRowSeparatorFunc{.
    cdecl, importc: "gtk_combo_box_get_row_separator_func", dynlib: lib.}
proc set_row_separator_func*(combo_box: PComboBox;
                             func: GtkTreeViewRowSeparatorFunc; data: gpointer;
                             destroy: GDestroyNotify){.cdecl,
    importc: "gtk_combo_box_set_row_separator_func", dynlib: lib.}"""
discard """proc set_button_sensitivity*(combo_box: PComboBox;
                             sensitivity: GtkSensitivityType){.cdecl,
    importc: "gtk_combo_box_set_button_sensitivity", dynlib: lib.}
proc get_button_sensitivity*(combo_box: PComboBox): GtkSensitivityType{.
    cdecl, importc: "gtk_combo_box_get_button_sensitivity", dynlib: lib.}"""
proc get_has_entry*(combo_box: PComboBox): gboolean{.cdecl,
    importc: "gtk_combo_box_get_has_entry", dynlib: lib.}
proc set_entry_text_column*(combo_box: PComboBox; text_column: gint){.
    cdecl, importc: "gtk_combo_box_set_entry_text_column", dynlib: lib.}
proc get_entry_text_column*(combo_box: PComboBox): gint{.cdecl,
    importc: "gtk_combo_box_get_entry_text_column", dynlib: lib.}

proc popup*(combo_box: PComboBox){.cdecl, importc: "gtk_combo_box_popup",
    dynlib: lib.}
proc popdown*(combo_box: PComboBox){.cdecl,
    importc: "gtk_combo_box_popdown", dynlib: lib.}
discard """proc get_popup_accessible*(combo_box: PComboBox): ptr AtkObject{.cdecl,
    importc: "gtk_combo_box_get_popup_accessible", dynlib: lib.}"""

type
  TComboBoxText* = object of TComboBox
  PComboBoxText* = ptr TComboBoxText

proc combo_box_text_new*(): PComboBoxText{.cdecl, importc: "gtk_combo_box_text_new",
                                 dynlib: lib.}
proc combo_box_text_new_with_entry*(): PComboBoxText{.cdecl,
    importc: "gtk_combo_box_text_new_with_entry", dynlib: lib.}
proc append_text*(combo_box: PComboBoxText; text: cstring){.cdecl,
    importc: "gtk_combo_box_text_append_text", dynlib: lib.}
proc insert_text*(combo_box: PComboBoxText; position: gint;
                       text: cstring){.cdecl,
    importc: "gtk_combo_box_text_insert_text", dynlib: lib.}
proc prepend_text*(combo_box: PComboBoxText; text: cstring){.cdecl,
    importc: "gtk_combo_box_text_prepend_text", dynlib: lib.}
proc remove*(combo_box: PComboBoxText; position: gint){.cdecl,
    importc: "gtk_combo_box_text_remove", dynlib: lib.}
proc get_active_text*(combo_box: PComboBoxText): cstring{.cdecl,
    importc: "gtk_combo_box_text_get_active_text", dynlib: lib.}
proc is_active*(win: PWindow): gboolean{.cdecl,
    importc: "gtk_window_is_active", dynlib: lib.}
proc has_toplevel_focus*(win: PWindow): gboolean{.cdecl,
    importc: "gtk_window_has_toplevel_focus", dynlib: lib.}

proc nimrod_init*() =
  var
    cmdLine{.importc: "cmdLine".}: array[0..255, cstring]
    cmdCount{.importc: "cmdCount".}: cint
  init(addr(cmdLine), addr(cmdCount))
