{.deadCodeElim: on.}
when defined(windows):
  const
    gliblib = "libglib-2.0-0.dll"
    gmodulelib = "libgmodule-2.0-0.dll"
    gobjectlib = "libgobject-2.0-0.dll"
elif defined(macosx):
  const
    gliblib = "libglib-2.0.dylib"
    gmodulelib = "libgmodule-2.0.dylib"
    gobjectlib = "libgobject-2.0.dylib"
else:
  const
    gliblib = "libglib-2.0.so(|.0)"
    gmodulelib = "libgmodule-2.0.so(|.0)"
    gobjectlib = "libgobject-2.0.so(|.0)"
# gthreadlib = "libgthread-2.0.so"

type
  PGTypePlugin* = pointer
  PGParamSpecPool* = pointer
  PPchar* = ptr cstring
  PPPchar* = ptr PPchar
  PPPgchar* = ptr PPgchar
  PPgchar* = ptr cstring
  gchar* = char
  gshort* = cshort
  glong* = clong
  gint* = cint
  gboolean* = distinct gint
  guchar* = char
  gushort* = int16
  gulong* = int
  guint* = cint
  gfloat* = cfloat
  gdouble* = cdouble
  gpointer* = pointer
  Pgshort* = ptr gshort
  Pglong* = ptr glong
  Pgint* = ptr gint
  PPgint* = ptr Pgint
  Pgboolean* = ptr gboolean
  Pguchar* = ptr guchar
  PPguchar* = ptr Pguchar
  Pgushort* = ptr gushort
  Pgulong* = ptr gulong
  Pguint* = ptr guint
  Pgfloat* = ptr gfloat
  Pgdouble* = ptr gdouble
  pgpointer* = ptr gpointer
  gconstpointer* = pointer
  PGCompareFunc* = ptr TGCompareFunc
  TGCompareFunc* = proc (a, b: gconstpointer): gint{.cdecl.}
  PGCompareDataFunc* = ptr TGCompareDataFunc
  TGCompareDataFunc* = proc (a, b: gconstpointer, user_data: gpointer): gint{.
      cdecl.}
  PGEqualFunc* = ptr TGEqualFunc
  TGEqualFunc* = proc (a, b: gconstpointer): gboolean{.cdecl.}
  PGDestroyNotify* = ptr TGDestroyNotify
  TGDestroyNotify* = proc (data: gpointer){.cdecl.}
  PGFunc* = ptr TGFunc
  TGFunc* = proc (data, userdata: gpointer, key: gconstpointer){.cdecl.}
  PGHashFunc* = ptr TGHashFunc
  TGHashFunc* = proc (key: gconstpointer): guint{.cdecl.}
  PGHFunc* = ptr TGHFunc
  TGHFunc* = proc (key, value, user_data: gpointer){.cdecl.}
  PGFreeFunc* = proc (data: gpointer){.cdecl.}
  PGTimeVal* = ptr TGTimeVal
  TGTimeVal*{.final.} = object
    tv_sec*: glong
    tv_usec*: glong

  guint64* = int64
  gint8* = int8
  guint8* = int8
  gint16* = int16
  guint16* = int16
  gint32* = int32
  guint32* = int32
  gint64* = int64
  gssize* = int32
  gsize* = int32
  Pgint8* = ptr gint8
  Pguint8* = ptr guint8
  Pgint16* = ptr gint16
  Pguint16* = ptr guint16
  Pgint32* = ptr gint32
  Pguint32* = ptr guint32
  Pgint64* = ptr gint64
  Pguint64* = ptr guint64
  pgssize* = ptr gssize
  pgsize* = ptr gsize
  TGQuark* = guint32
  PGQuark* = ptr TGQuark
  PGTypeCValue* = ptr TGTypeCValue
  TGTypeCValue*{.final.} = object
    v_double*: gdouble

  GType* = gulong
  PGType* = ptr GType
  PGTypeClass* = ptr TGTypeClass
  TGTypeClass*{.final.} = object
    g_type*: GType

  PGTypeInstance* = ptr TGTypeInstance
  TGTypeInstance*{.final.} = object
    g_class*: PGTypeClass

  PGTypeInterface* = ptr TGTypeInterface
  TGTypeInterface*{.pure, inheritable.} = object
    g_type*: GType
    g_instance_type*: GType

  PGTypeQuery* = ptr TGTypeQuery
  TGTypeQuery*{.final.} = object
    theType*: GType
    type_name*: cstring
    class_size*: guint
    instance_size*: guint

  PGValue* = ptr TGValue
  TGValue*{.final.} = object
    g_type*: GType
    data*: array[0..1, gdouble]

  PGData* = pointer
  PPGData* = ptr PGData
  PGSList* = ptr TGSList
  PPGSList* = ptr PGSList
  TGSList*{.final.} = object
    data*: gpointer
    next*: PGSList

  PGList* = ptr TGList
  TGList*{.final.} = object
    data*: gpointer
    next*: PGList
    prev*: PGList

  TGParamFlags* = int32
  PGParamFlags* = ptr TGParamFlags
  PGParamSpec* = ptr TGParamSpec
  PPGParamSpec* = ptr PGParamSpec
  TGParamSpec*{.final.} = object
    g_type_instance*: TGTypeInstance
    name*: cstring
    flags*: TGParamFlags
    value_type*: GType
    owner_type*: GType
    nick*: cstring
    blurb*: cstring
    qdata*: PGData
    ref_count*: guint
    param_id*: guint

  PGParamSpecClass* = ptr TGParamSpecClass
  TGParamSpecClass*{.final.} = object
    g_type_class*: TGTypeClass
    value_type*: GType
    finalize*: proc (pspec: PGParamSpec){.cdecl.}
    value_set_default*: proc (pspec: PGParamSpec, value: PGValue){.cdecl.}
    value_validate*: proc (pspec: PGParamSpec, value: PGValue): gboolean{.cdecl.}
    values_cmp*: proc (pspec: PGParamSpec, value1: PGValue, value2: PGValue): gint{.
        cdecl.}
    dummy*: array[0..3, gpointer]

  PGParameter* = ptr TGParameter
  TGParameter*{.final.} = object
    name*: cstring
    value*: TGValue

  TGBoxedCopyFunc* = proc (boxed: gpointer): gpointer{.cdecl.}
  TGBoxedFreeFunc* = proc (boxed: gpointer){.cdecl.}
  PGsource = pointer          # I don't know and don't care

converter gbool*(nimbool: bool): gboolean =
  return ord(nimbool).gboolean

converter toBool*(gbool: gboolean): bool =
  return int(gbool) == 1

const
  G_TYPE_FUNDAMENTAL_SHIFT* = 2
  G_TYPE_FUNDAMENTAL_MAX* = 255 shl G_TYPE_FUNDAMENTAL_SHIFT
  G_TYPE_INVALID* = GType(0 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_NONE* = GType(1 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_INTERFACE* = GType(2 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_CHAR* = GType(3 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_UCHAR* = GType(4 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_BOOLEAN* = GType(5 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_INT* = GType(6 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_UINT* = GType(7 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_LONG* = GType(8 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_ULONG* = GType(9 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_INT64* = GType(10 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_UINT64* = GType(11 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_ENUM* = GType(12 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_FLAGS* = GType(13 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_FLOAT* = GType(14 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_DOUBLE* = GType(15 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_STRING* = GType(16 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_POINTER* = GType(17 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_BOXED* = GType(18 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_PARAM* = GType(19 shl G_TYPE_FUNDAMENTAL_SHIFT)
  G_TYPE_OBJECT* = GType(20 shl G_TYPE_FUNDAMENTAL_SHIFT)

const
  G_PRIORITY_HIGH_IDLE* = 100
  G_PRIORITY_DEFAULT_IDLE* = 200
  G_PRIORITY_LOW* = 300
  G_PRIORITY_HIGH* = -100
  G_PRIORITY_DEFAULT* = 0


proc G_TYPE_MAKE_FUNDAMENTAL*(x: int): GType
const
  G_TYPE_RESERVED_GLIB_FIRST* = 21
  G_TYPE_RESERVED_GLIB_LAST* = 31
  G_TYPE_RESERVED_BSE_FIRST* = 32
  G_TYPE_RESERVED_BSE_LAST* = 48
  G_TYPE_RESERVED_USER_FIRST* = 49

proc G_TYPE_IS_FUNDAMENTAL*(theType: GType): bool
proc G_TYPE_IS_DERIVED*(theType: GType): bool
proc G_TYPE_IS_INTERFACE*(theType: GType): bool
proc G_TYPE_IS_CLASSED*(theType: GType): gboolean
proc G_TYPE_IS_INSTANTIATABLE*(theType: GType): bool
proc G_TYPE_IS_DERIVABLE*(theType: GType): bool
proc G_TYPE_IS_DEEP_DERIVABLE*(theType: GType): bool
proc G_TYPE_IS_ABSTRACT*(theType: GType): bool
proc G_TYPE_IS_VALUE_ABSTRACT*(theType: GType): bool
proc G_TYPE_IS_VALUE_TYPE*(theType: GType): bool
proc G_TYPE_HAS_VALUE_TABLE*(theType: GType): bool
proc G_TYPE_CHECK_INSTANCE*(instance: Pointer): gboolean
proc G_TYPE_CHECK_INSTANCE_CAST*(instance: Pointer, g_type: GType): PGTypeInstance
proc G_TYPE_CHECK_INSTANCE_TYPE*(instance: Pointer, g_type: GType): bool
proc G_TYPE_INSTANCE_GET_CLASS*(instance: Pointer, g_type: GType): PGTypeClass
proc G_TYPE_INSTANCE_GET_INTERFACE*(instance: Pointer, g_type: GType): Pointer
proc G_TYPE_CHECK_CLASS_CAST*(g_class: pointer, g_type: GType): Pointer
proc G_TYPE_CHECK_CLASS_TYPE*(g_class: pointer, g_type: GType): bool
proc G_TYPE_CHECK_VALUE*(value: Pointer): bool
proc G_TYPE_CHECK_VALUE_TYPE*(value: pointer, g_type: GType): bool
proc G_TYPE_FROM_INSTANCE*(instance: Pointer): GType
proc G_TYPE_FROM_CLASS*(g_class: Pointer): GType
proc G_TYPE_FROM_INTERFACE*(g_iface: Pointer): GType
type
  TGTypeDebugFlags* = int32
  PGTypeDebugFlags* = ptr TGTypeDebugFlags

const
  G_TYPE_DEBUG_NONE* = 0
  G_TYPE_DEBUG_OBJECTS* = 1 shl 0
  G_TYPE_DEBUG_SIGNALS* = 1 shl 1
  G_TYPE_DEBUG_MASK* = 0x00000003

proc g_type_init*(){.cdecl, dynlib: gobjectlib, importc: "g_type_init".}
proc g_type_init*(debug_flags: TGTypeDebugFlags){.cdecl,
    dynlib: gobjectlib, importc: "g_type_init_with_debug_flags".}
proc g_type_name*(theType: GType): cstring{.cdecl, dynlib: gobjectlib,
    importc: "g_type_name".}
proc g_type_qname*(theType: GType): TGQuark{.cdecl, dynlib: gobjectlib,
    importc: "g_type_qname".}
proc g_type_from_name*(name: cstring): GType{.cdecl, dynlib: gobjectlib,
    importc: "g_type_from_name".}
proc g_type_parent*(theType: GType): GType{.cdecl, dynlib: gobjectlib,
    importc: "g_type_parent".}
proc g_type_depth*(theType: GType): guint{.cdecl, dynlib: gobjectlib,
    importc: "g_type_depth".}
proc g_type_next_base*(leaf_type: GType, root_type: GType): GType{.cdecl,
    dynlib: gobjectlib, importc: "g_type_next_base".}
proc g_type_is_a*(theType: GType, is_a_type: GType): gboolean{.cdecl,
    dynlib: gobjectlib, importc: "g_type_is_a".}
proc g_type_class_ref*(theType: GType): gpointer{.cdecl, dynlib: gobjectlib,
    importc: "g_type_class_ref".}
proc g_type_class_peek*(theType: GType): gpointer{.cdecl, dynlib: gobjectlib,
    importc: "g_type_class_peek".}
proc g_type_class_unref*(g_class: gpointer){.cdecl, dynlib: gobjectlib,
    importc: "g_type_class_unref".}
proc g_type_class_peek_parent*(g_class: gpointer): gpointer{.cdecl,
    dynlib: gobjectlib, importc: "g_type_class_peek_parent".}
proc g_type_interface_peek*(instance_class: gpointer, iface_type: GType): gpointer{.
    cdecl, dynlib: gobjectlib, importc: "g_type_interface_peek".}
proc g_type_interface_peek_parent*(g_iface: gpointer): gpointer{.cdecl,
    dynlib: gobjectlib, importc: "g_type_interface_peek_parent".}
proc g_type_children*(theType: GType, n_children: Pguint): PGType{.cdecl,
    dynlib: gobjectlib, importc: "g_type_children".}
proc g_type_interfaces*(theType: GType, n_interfaces: Pguint): PGType{.cdecl,
    dynlib: gobjectlib, importc: "g_type_interfaces".}
proc g_type_set_qdata*(theType: GType, quark: TGQuark, data: gpointer){.cdecl,
    dynlib: gobjectlib, importc: "g_type_set_qdata".}
proc g_type_get_qdata*(theType: GType, quark: TGQuark): gpointer{.cdecl,
    dynlib: gobjectlib, importc: "g_type_get_qdata".}
proc g_type_query*(theType: GType, query: PGTypeQuery){.cdecl,
    dynlib: gobjectlib, importc: "g_type_query".}
type
  TGBaseInitFunc* = proc (g_class: gpointer){.cdecl.}
  TGBaseFinalizeFunc* = proc (g_class: gpointer){.cdecl.}
  TGClassInitFunc* = proc (g_class: gpointer, class_data: gpointer){.cdecl.}
  TGClassFinalizeFunc* = proc (g_class: gpointer, class_data: gpointer){.cdecl.}
  TGInstanceInitFunc* = proc (instance: PGTypeInstance, g_class: gpointer){.
      cdecl.}
  TGInterfaceInitFunc* = proc (g_iface: gpointer, iface_data: gpointer){.cdecl.}
  TGInterfaceFinalizeFunc* = proc (g_iface: gpointer, iface_data: gpointer){.
      cdecl.}
  TGTypeClassCacheFunc* = proc (cache_data: gpointer, g_class: PGTypeClass): gboolean{.
      cdecl.}
  TGTypeFundamentalFlags* = int32
  PGTypeFundamentalFlags* = ptr TGTypeFundamentalFlags

const
  G_TYPE_FLAG_CLASSED* = 1 shl 0
  G_TYPE_FLAG_INSTANTIATABLE* = 1 shl 1
  G_TYPE_FLAG_DERIVABLE* = 1 shl 2
  G_TYPE_FLAG_DEEP_DERIVABLE* = 1 shl 3

type
  TGTypeFlags* = int32
  PGTypeFlags* = ptr TGTypeFlags

const
  G_TYPE_FLAG_ABSTRACT* = 1 shl 4
  G_TYPE_FLAG_VALUE_ABSTRACT* = 1 shl 5

type
  PGTypeValueTable* = ptr TGTypeValueTable
  TGTypeValueTable*{.final.} = object
    value_init*: proc (value: PGValue){.cdecl.}
    value_free*: proc (value: PGValue){.cdecl.}
    value_copy*: proc (src_value: PGValue, dest_value: PGValue){.cdecl.}
    value_peek_pointer*: proc (value: PGValue): gpointer{.cdecl.}
    collect_format*: cstring
    collect_value*: proc (value: PGValue, n_collect_values: guint,
                          collect_values: PGTypeCValue, collect_flags: guint): cstring{.
        cdecl.}
    lcopy_format*: cstring
    lcopy_value*: proc (value: PGValue, n_collect_values: guint,
                        collect_values: PGTypeCValue, collect_flags: guint): cstring{.
        cdecl.}

  PGTypeInfo* = ptr TGTypeInfo
  TGTypeInfo*{.final.} = object
    class_size*: guint16
    base_init*: TGBaseInitFunc
    base_finalize*: TGBaseFinalizeFunc
    class_init*: TGClassInitFunc
    class_finalize*: TGClassFinalizeFunc
    class_data*: gconstpointer
    instance_size*: guint16
    n_preallocs*: guint16
    instance_init*: TGInstanceInitFunc
    value_table*: PGTypeValueTable

  PGTypeFundamentalInfo* = ptr TGTypeFundamentalInfo
  TGTypeFundamentalInfo*{.final.} = object
    type_flags*: TGTypeFundamentalFlags

  PGInterfaceInfo* = ptr TGInterfaceInfo
  TGInterfaceInfo*{.final.} = object
    interface_init*: TGInterfaceInitFunc
    interface_finalize*: TGInterfaceFinalizeFunc
    interface_data*: gpointer


proc g_type_register_static*(parent_type: GType, type_name: cstring,
                             info: PGTypeInfo, flags: TGTypeFlags): GType{.
    cdecl, dynlib: gobjectlib, importc: "g_type_register_static".}
proc g_type_register_dynamic*(parent_type: GType, type_name: cstring,
                              plugin: PGTypePlugin, flags: TGTypeFlags): GType{.
    cdecl, dynlib: gobjectlib, importc: "g_type_register_dynamic".}
proc g_type_register_fundamental*(type_id: GType, type_name: cstring,
                                  info: PGTypeInfo,
                                  finfo: PGTypeFundamentalInfo,
                                  flags: TGTypeFlags): GType{.cdecl,
    dynlib: gobjectlib, importc: "g_type_register_fundamental".}
proc g_type_add_interface_static*(instance_type: GType, interface_type: GType,
                                  info: PGInterfaceInfo){.cdecl,
    dynlib: gobjectlib, importc: "g_type_add_interface_static".}
proc g_type_add_interface_dynamic*(instance_type: GType, interface_type: GType,
                                   plugin: PGTypePlugin){.cdecl,
    dynlib: gobjectlib, importc: "g_type_add_interface_dynamic".}
proc g_type_interface_add_prerequisite*(interface_type: GType,
                                        prerequisite_type: GType){.cdecl,
    dynlib: gobjectlib, importc: "g_type_interface_add_prerequisite".}
proc g_type_get_plugin*(theType: GType): PGTypePlugin{.cdecl,
    dynlib: gobjectlib, importc: "g_type_get_plugin".}
proc g_type_interface_get_plugin*(instance_type: GType,
                                  implementation_type: GType): PGTypePlugin{.
    cdecl, dynlib: gobjectlib, importc: "g_type_interface_get_plugin".}
proc g_type_fundamental_next*(): GType{.cdecl, dynlib: gobjectlib,
                                        importc: "g_type_fundamental_next".}
proc g_type_fundamental*(type_id: GType): GType{.cdecl, dynlib: gobjectlib,
    importc: "g_type_fundamental".}
proc g_type_create_instance*(theType: GType): PGTypeInstance{.cdecl,
    dynlib: gobjectlib, importc: "g_type_create_instance".}
proc free_instance*(instance: PGTypeInstance){.cdecl, dynlib: gobjectlib,
    importc: "g_type_free_instance".}
proc g_type_add_class_cache_func*(cache_data: gpointer,
                                  cache_func: TGTypeClassCacheFunc){.cdecl,
    dynlib: gobjectlib, importc: "g_type_add_class_cache_func".}
proc g_type_remove_class_cache_func*(cache_data: gpointer,
                                     cache_func: TGTypeClassCacheFunc){.cdecl,
    dynlib: gobjectlib, importc: "g_type_remove_class_cache_func".}
proc g_type_class_unref_uncached*(g_class: gpointer){.cdecl, dynlib: gobjectlib,
    importc: "g_type_class_unref_uncached".}
proc g_type_value_table_peek*(theType: GType): PGTypeValueTable{.cdecl,
    dynlib: gobjectlib, importc: "g_type_value_table_peek".}
proc private_g_type_check_instance*(instance: PGTypeInstance): gboolean{.cdecl,
    dynlib: gobjectlib, importc: "g_type_check_instance".}
proc private_g_type_check_instance_cast*(instance: PGTypeInstance,
    iface_type: GType): PGTypeInstance{.cdecl, dynlib: gobjectlib,
                                        importc: "g_type_check_instance_cast".}
proc private_g_type_check_instance_is_a*(instance: PGTypeInstance,
    iface_type: GType): gboolean{.cdecl, dynlib: gobjectlib,
                                  importc: "g_type_check_instance_is_a".}
proc private_g_type_check_class_cast*(g_class: PGTypeClass, is_a_type: GType): PGTypeClass{.
    cdecl, dynlib: gobjectlib, importc: "g_type_check_class_cast".}
proc private_g_type_check_class_is_a*(g_class: PGTypeClass, is_a_type: GType): gboolean{.
    cdecl, dynlib: gobjectlib, importc: "g_type_check_class_is_a".}
proc private_g_type_check_is_value_type*(theType: GType): gboolean{.cdecl,
    dynlib: gobjectlib, importc: "g_type_check_is_value_type".}
proc private_g_type_check_value*(value: PGValue): gboolean{.cdecl,
    dynlib: gobjectlib, importc: "g_type_check_value".}
proc private_g_type_check_value_holds*(value: PGValue, theType: GType): gboolean{.
    cdecl, dynlib: gobjectlib, importc: "g_type_check_value_holds".}
proc private_g_type_test_flags*(theType: GType, flags: guint): gboolean{.cdecl,
    dynlib: gobjectlib, importc: "g_type_test_flags".}
proc name_from_instance*(instance: PGTypeInstance): cstring{.cdecl,
    dynlib: gobjectlib, importc: "g_type_name_from_instance".}
proc name_from_class*(g_class: PGTypeClass): cstring{.cdecl,
    dynlib: gobjectlib, importc: "g_type_name_from_class".}
const
  G_TYPE_FLAG_RESERVED_ID_BIT* = GType(1 shl 0)

proc G_TYPE_IS_VALUE*(theType: GType): bool
proc G_IS_VALUE*(value: pointer): bool
proc G_VALUE_TYPE*(value: Pointer): GType
proc G_VALUE_TYPE_NAME*(value: Pointer): cstring
proc G_VALUE_HOLDS*(value: pointer, g_type: GType): bool
type
  TGValueTransform* = proc (src_value: PGValue, dest_value: PGValue){.cdecl.}

proc init*(value: PGValue, g_type: GType): PGValue{.cdecl,
    dynlib: gobjectlib, importc: "g_value_init".}
proc copy*(src_value: PGValue, dest_value: PGValue){.cdecl,
    dynlib: gobjectlib, importc: "g_value_copy".}
proc reset*(value: PGValue): PGValue{.cdecl, dynlib: gobjectlib,
    importc: "g_value_reset".}
proc unset*(value: PGValue){.cdecl, dynlib: gobjectlib,
                                     importc: "g_value_unset".}
proc set_instance*(value: PGValue, instance: gpointer){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_instance".}
proc fits_pointer*(value: PGValue): gboolean{.cdecl, dynlib: gobjectlib,
    importc: "g_value_fits_pointer".}
proc peek_pointer*(value: PGValue): gpointer{.cdecl, dynlib: gobjectlib,
    importc: "g_value_peek_pointer".}
proc g_value_type_compatible*(src_type: GType, dest_type: GType): gboolean{.
    cdecl, dynlib: gobjectlib, importc: "g_value_type_compatible".}
proc g_value_type_transformable*(src_type: GType, dest_type: GType): gboolean{.
    cdecl, dynlib: gobjectlib, importc: "g_value_type_transformable".}
proc transform*(src_value: PGValue, dest_value: PGValue): gboolean{.
    cdecl, dynlib: gobjectlib, importc: "g_value_transform".}
proc g_value_register_transform_func*(src_type: GType, dest_type: GType,
                                      transform_func: TGValueTransform){.cdecl,
    dynlib: gobjectlib, importc: "g_value_register_transform_func".}
const
  G_VALUE_NOCOPY_CONTENTS* = 1 shl 27

type
  PGValueArray* = ptr TGValueArray
  TGValueArray*{.final.} = object
    n_values*: guint
    values*: PGValue
    n_prealloced*: guint


proc array_get_nth*(value_array: PGValueArray, index: guint): PGValue{.
    cdecl, dynlib: gobjectlib, importc: "g_value_array_get_nth".}
proc g_value_array_new*(n_prealloced: guint): PGValueArray{.cdecl,
    dynlib: gobjectlib, importc: "g_value_array_new".}
proc array_free*(value_array: PGValueArray){.cdecl, dynlib: gobjectlib,
    importc: "g_value_array_free".}
proc array_copy*(value_array: PGValueArray): PGValueArray{.cdecl,
    dynlib: gobjectlib, importc: "g_value_array_copy".}
proc array_prepend*(value_array: PGValueArray, value: PGValue): PGValueArray{.
    cdecl, dynlib: gobjectlib, importc: "g_value_array_prepend".}
proc array_append*(value_array: PGValueArray, value: PGValue): PGValueArray{.
    cdecl, dynlib: gobjectlib, importc: "g_value_array_append".}
proc array_insert*(value_array: PGValueArray, index: guint,
                           value: PGValue): PGValueArray{.cdecl,
    dynlib: gobjectlib, importc: "g_value_array_insert".}
proc array_remove*(value_array: PGValueArray, index: guint): PGValueArray{.
    cdecl, dynlib: gobjectlib, importc: "g_value_array_remove".}
proc array_sort*(value_array: PGValueArray, compare_func: TGCompareFunc): PGValueArray{.
    cdecl, dynlib: gobjectlib, importc: "g_value_array_sort".}
proc array_sort*(value_array: PGValueArray,
                                   compare_func: TGCompareDataFunc,
                                   user_data: gpointer): PGValueArray{.cdecl,
    dynlib: gobjectlib, importc: "g_value_array_sort_with_data".}
const
  G_VALUE_COLLECT_INT* = 'i'
  G_VALUE_COLLECT_LONG* = 'l'
  G_VALUE_COLLECT_INT64* = 'q'
  G_VALUE_COLLECT_DOUBLE* = 'd'
  G_VALUE_COLLECT_POINTER* = 'p'
  G_VALUE_COLLECT_FORMAT_MAX_LENGTH* = 8

proc HOLDS_CHAR*(value: PGValue): bool
proc HOLDS_UCHAR*(value: PGValue): bool
proc HOLDS_BOOLEAN*(value: PGValue): bool
proc HOLDS_INT*(value: PGValue): bool
proc HOLDS_UINT*(value: PGValue): bool
proc HOLDS_LONG*(value: PGValue): bool
proc HOLDS_ULONG*(value: PGValue): bool
proc HOLDS_INT64*(value: PGValue): bool
proc HOLDS_UINT64*(value: PGValue): bool
proc HOLDS_FLOAT*(value: PGValue): bool
proc HOLDS_DOUBLE*(value: PGValue): bool
proc HOLDS_STRING*(value: PGValue): bool
proc HOLDS_POINTER*(value: PGValue): bool
proc set_char*(value: PGValue, v_char: gchar){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_char".}
proc get_char*(value: PGValue): gchar{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_char".}
proc set_uchar*(value: PGValue, v_uchar: guchar){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_uchar".}
proc get_uchar*(value: PGValue): guchar{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_uchar".}
proc set_boolean*(value: PGValue, v_boolean: gboolean){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_boolean".}
proc get_boolean*(value: PGValue): gboolean{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_boolean".}
proc set_int*(value: PGValue, v_int: gint){.cdecl, dynlib: gobjectlib,
    importc: "g_value_set_int".}
proc get_int*(value: PGValue): gint{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_int".}
proc set_uint*(value: PGValue, v_uint: guint){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_uint".}
proc get_uint*(value: PGValue): guint{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_uint".}
proc set_long*(value: PGValue, v_long: glong){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_long".}
proc get_long*(value: PGValue): glong{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_long".}
proc set_ulong*(value: PGValue, v_ulong: gulong){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_ulong".}
proc get_ulong*(value: PGValue): gulong{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_ulong".}
proc set_int64*(value: PGValue, v_int64: gint64){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_int64".}
proc get_int64*(value: PGValue): gint64{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_int64".}
proc set_uint64*(value: PGValue, v_uint64: guint64){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_uint64".}
proc get_uint64*(value: PGValue): guint64{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_uint64".}
proc set_float*(value: PGValue, v_float: gfloat){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_float".}
proc get_float*(value: PGValue): gfloat{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_float".}
proc set_double*(value: PGValue, v_double: gdouble){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_double".}
proc get_double*(value: PGValue): gdouble{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_double".}
proc set_string*(value: PGValue, v_string: cstring){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_string".}
proc set_static_string*(value: PGValue, v_string: cstring){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_static_string".}
proc get_string*(value: PGValue): cstring{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_string".}
proc dup_string*(value: PGValue): cstring{.cdecl, dynlib: gobjectlib,
    importc: "g_value_dup_string".}
proc set_pointer*(value: PGValue, v_pointer: gpointer){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_pointer".}
proc get_pointer*(value: PGValue): gpointer{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_pointer".}
proc g_pointer_type_register_static*(name: cstring): GType{.cdecl,
    dynlib: gobjectlib, importc: "g_pointer_type_register_static".}
proc strdup_value_contents*(value: PGValue): cstring{.cdecl,
    dynlib: gobjectlib, importc: "g_strdup_value_contents".}
proc set_string_take_ownership*(value: PGValue, v_string: cstring){.
    cdecl, dynlib: gobjectlib, importc: "g_value_set_string_take_ownership".}
type
  Tgchararray* = gchar
  Pgchararray* = ptr Tgchararray

proc G_TYPE_IS_PARAM*(theType: GType): bool
proc G_PARAM_SPEC*(pspec: Pointer): PGParamSpec
proc G_IS_PARAM_SPEC*(pspec: Pointer): bool
proc G_PARAM_SPEC_CLASS*(pclass: Pointer): PGParamSpecClass
proc G_IS_PARAM_SPEC_CLASS*(pclass: Pointer): bool
proc G_PARAM_SPEC_GET_CLASS*(pspec: Pointer): PGParamSpecClass
proc G_PARAM_SPEC_TYPE*(pspec: Pointer): GType
proc G_PARAM_SPEC_TYPE_NAME*(pspec: Pointer): cstring
proc G_PARAM_SPEC_VALUE_TYPE*(pspec: Pointer): GType
proc G_VALUE_HOLDS_PARAM*(value: Pointer): bool
const
  G_PARAM_READABLE* = 1 shl 0
  G_PARAM_WRITABLE* = 1 shl 1
  G_PARAM_CONSTRUCT* = 1 shl 2
  G_PARAM_CONSTRUCT_ONLY* = 1 shl 3
  G_PARAM_LAX_VALIDATION* = 1 shl 4
  G_PARAM_PRIVATE* = 1 shl 5
  G_PARAM_READWRITE* = G_PARAM_READABLE or G_PARAM_WRITABLE
  G_PARAM_MASK* = 0x000000FF
  G_PARAM_USER_SHIFT* = 8

proc spec_ref*(pspec: PGParamSpec): PGParamSpec{.cdecl, dynlib: gliblib,
    importc: "g_param_spec_ref".}
proc spec_unref*(pspec: PGParamSpec){.cdecl, dynlib: gliblib,
    importc: "g_param_spec_unref".}
proc spec_sink*(pspec: PGParamSpec){.cdecl, dynlib: gliblib,
    importc: "g_param_spec_sink".}
proc spec_get_qdata*(pspec: PGParamSpec, quark: TGQuark): gpointer{.
    cdecl, dynlib: gliblib, importc: "g_param_spec_get_qdata".}
proc spec_set_qdata*(pspec: PGParamSpec, quark: TGQuark, data: gpointer){.
    cdecl, dynlib: gliblib, importc: "g_param_spec_set_qdata".}
proc spec_set_qdata_full*(pspec: PGParamSpec, quark: TGQuark,
                                  data: gpointer, destroy: TGDestroyNotify){.
    cdecl, dynlib: gliblib, importc: "g_param_spec_set_qdata_full".}
proc spec_steal_qdata*(pspec: PGParamSpec, quark: TGQuark): gpointer{.
    cdecl, dynlib: gliblib, importc: "g_param_spec_steal_qdata".}
proc value_set_default*(pspec: PGParamSpec, value: PGValue){.cdecl,
    dynlib: gliblib, importc: "g_param_value_set_default".}
proc value_defaults*(pspec: PGParamSpec, value: PGValue): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_param_value_defaults".}
proc value_validate*(pspec: PGParamSpec, value: PGValue): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_param_value_validate".}
proc value_convert*(pspec: PGParamSpec, src_value: PGValue,
                            dest_value: PGValue, strict_validation: gboolean): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_param_value_convert".}
proc values_cmp*(pspec: PGParamSpec, value1: PGValue, value2: PGValue): gint{.
    cdecl, dynlib: gliblib, importc: "g_param_values_cmp".}
proc spec_get_name*(pspec: PGParamSpec): cstring{.cdecl,
    dynlib: gliblib, importc: "g_param_spec_get_name".}
proc spec_get_nick*(pspec: PGParamSpec): cstring{.cdecl,
    dynlib: gliblib, importc: "g_param_spec_get_nick".}
proc spec_get_blurb*(pspec: PGParamSpec): cstring{.cdecl,
    dynlib: gliblib, importc: "g_param_spec_get_blurb".}
proc set_param*(value: PGValue, param: PGParamSpec){.cdecl,
    dynlib: gliblib, importc: "g_value_set_param".}
proc get_param*(value: PGValue): PGParamSpec{.cdecl, dynlib: gliblib,
    importc: "g_value_get_param".}
proc dup_param*(value: PGValue): PGParamSpec{.cdecl, dynlib: gliblib,
    importc: "g_value_dup_param".}
proc set_param_take_ownership*(value: PGValue, param: PGParamSpec){.
    cdecl, dynlib: gliblib, importc: "g_value_set_param_take_ownership".}
type
  PGParamSpecTypeInfo* = ptr TGParamSpecTypeInfo
  TGParamSpecTypeInfo*{.final.} = object
    instance_size*: guint16
    n_preallocs*: guint16
    instance_init*: proc (pspec: PGParamSpec){.cdecl.}
    value_type*: GType
    finalize*: proc (pspec: PGParamSpec){.cdecl.}
    value_set_default*: proc (pspec: PGParamSpec, value: PGValue){.cdecl.}
    value_validate*: proc (pspec: PGParamSpec, value: PGValue): gboolean{.cdecl.}
    values_cmp*: proc (pspec: PGParamSpec, value1: PGValue, value2: PGValue): gint{.
        cdecl.}


proc g_param_type_register_static*(name: cstring,
                                   pspec_info: PGParamSpecTypeInfo): GType{.
    cdecl, dynlib: gliblib, importc: "g_param_type_register_static".}
proc g_param_type_register_static_constant*(name: cstring,
    pspec_info: PGParamSpecTypeInfo, opt_type: GType): GType{.cdecl,
    dynlib: gliblib, importc: "`g_param_type_register_static_constant`".}
proc g_param_spec_internal*(param_type: GType, name: cstring, nick: cstring,
                            blurb: cstring, flags: TGParamFlags): gpointer{.
    cdecl, dynlib: gliblib, importc: "g_param_spec_internal".}
proc g_param_spec_pool_new*(type_prefixing: gboolean): PGParamSpecPool{.cdecl,
    dynlib: gliblib, importc: "g_param_spec_pool_new".}
proc spec_pool_insert*(pool: PGParamSpecPool, pspec: PGParamSpec,
                               owner_type: GType){.cdecl, dynlib: gliblib,
    importc: "g_param_spec_pool_insert".}
proc spec_pool_remove*(pool: PGParamSpecPool, pspec: PGParamSpec){.
    cdecl, dynlib: gliblib, importc: "g_param_spec_pool_remove".}
proc spec_pool_lookup*(pool: PGParamSpecPool, param_name: cstring,
                               owner_type: GType, walk_ancestors: gboolean): PGParamSpec{.
    cdecl, dynlib: gliblib, importc: "g_param_spec_pool_lookup".}
proc spec_pool_list_owned*(pool: PGParamSpecPool, owner_type: GType): PGList{.
    cdecl, dynlib: gliblib, importc: "g_param_spec_pool_list_owned".}
proc spec_pool_list*(pool: PGParamSpecPool, owner_type: GType,
                             n_pspecs_p: Pguint): PPGParamSpec{.cdecl,
    dynlib: gliblib, importc: "g_param_spec_pool_list".}
type
  PGClosure* = ptr TGClosure
  PGClosureNotifyData* = ptr TGClosureNotifyData
  TGClosureNotify* = proc (data: gpointer, closure: PGClosure){.cdecl.}
  TGClosure*{.final.} = object
    flag0*: int32
    marshal*: proc (closure: PGClosure, return_value: PGValue,
                    n_param_values: guint, param_values: PGValue,
                    invocation_hint, marshal_data: gpointer){.cdecl.}
    data*: gpointer
    notifiers*: PGClosureNotifyData

  TGCallBackProcedure* = proc (){.cdecl.}
  TGCallback* = proc (){.cdecl.}
  TGClosureMarshal* = proc (closure: PGClosure, return_value: PGValue,
                            n_param_values: guint, param_values: PGValue,
                            invocation_hint: gpointer, marshal_data: gpointer){.
      cdecl.}
  TGClosureNotifyData*{.final.} = object
    data*: gpointer
    notify*: TGClosureNotify


proc G_CLOSURE_NEEDS_MARSHAL*(closure: Pointer): bool
proc N_NOTIFIERS*(cl: PGClosure): int32
proc CCLOSURE_SWAP_DATA*(cclosure: PGClosure): int32
proc G_CALLBACK*(f: pointer): TGCallback
const
  bm_TGClosure_ref_count* = 0x00007FFF'i32
  bp_TGClosure_ref_count* = 0'i32
  bm_TGClosure_meta_marshal* = 0x00008000'i32
  bp_TGClosure_meta_marshal* = 15'i32
  bm_TGClosure_n_guards* = 0x00010000'i32
  bp_TGClosure_n_guards* = 16'i32
  bm_TGClosure_n_fnotifiers* = 0x00060000'i32
  bp_TGClosure_n_fnotifiers* = 17'i32
  bm_TGClosure_n_inotifiers* = 0x07F80000'i32
  bp_TGClosure_n_inotifiers* = 19'i32
  bm_TGClosure_in_inotify* = 0x08000000'i32
  bp_TGClosure_in_inotify* = 27'i32
  bm_TGClosure_floating* = 0x10000000'i32
  bp_TGClosure_floating* = 28'i32
  bm_TGClosure_derivative_flag* = 0x20000000'i32
  bp_TGClosure_derivative_flag* = 29'i32
  bm_TGClosure_in_marshal* = 0x40000000'i32
  bp_TGClosure_in_marshal* = 30'i32
  bm_TGClosure_is_invalid* = 0x80000000'i32
  bp_TGClosure_is_invalid* = 31'i32

proc ref_count*(a: PGClosure): guint
proc set_ref_count*(a: PGClosure, ref_count: guint)
proc meta_marshal*(a: PGClosure): guint
proc set_meta_marshal*(a: PGClosure, meta_marshal: guint)
proc n_guards*(a: PGClosure): guint
proc set_n_guards*(a: PGClosure, n_guards: guint)
proc n_fnotifiers*(a: PGClosure): guint
proc set_n_fnotifiers*(a: PGClosure, n_fnotifiers: guint)
proc n_inotifiers*(a: PGClosure): guint
proc in_inotify*(a: PGClosure): guint
proc set_in_inotify*(a: PGClosure, in_inotify: guint)
proc floating*(a: PGClosure): guint
proc set_floating*(a: PGClosure, floating: guint)
proc derivative_flag*(a: PGClosure): guint
proc set_derivative_flag*(a: PGClosure, derivative_flag: guint)
proc in_marshal*(a: PGClosure): guint
proc set_in_marshal*(a: PGClosure, in_marshal: guint)
proc is_invalid*(a: PGClosure): guint
proc set_is_invalid*(a: PGClosure, is_invalid: guint)
type
  PGCClosure* = ptr TGCClosure
  TGCClosure*{.final.} = object
    closure*: TGClosure
    callback*: gpointer


proc g_cclosure_new*(callback_func: TGCallback, user_data: gpointer,
                     destroy_data: TGClosureNotify): PGClosure{.cdecl,
    dynlib: gliblib, importc: "g_cclosure_new".}
proc g_cclosure_new_swap*(callback_func: TGCallback, user_data: gpointer,
                          destroy_data: TGClosureNotify): PGClosure{.cdecl,
    dynlib: gliblib, importc: "g_cclosure_new_swap".}
proc g_signal_type_cclosure_new*(itype: GType, struct_offset: guint): PGClosure{.
    cdecl, dynlib: gliblib, importc: "g_signal_type_cclosure_new".}
proc reference*(closure: PGClosure): PGClosure{.cdecl, dynlib: gliblib,
    importc: "g_closure_ref".}
proc sink*(closure: PGClosure){.cdecl, dynlib: gliblib,
    importc: "g_closure_sink".}
proc unref*(closure: PGClosure){.cdecl, dynlib: gliblib,
    importc: "g_closure_unref".}
proc g_closure_new_simple*(sizeof_closure: guint, data: gpointer): PGClosure{.
    cdecl, dynlib: gliblib, importc: "g_closure_new_simple".}
proc add_finalize_notifier*(closure: PGClosure, notify_data: gpointer,
                                      notify_func: TGClosureNotify){.cdecl,
    dynlib: gliblib, importc: "g_closure_add_finalize_notifier".}
proc remove_finalize_notifier*(closure: PGClosure,
    notify_data: gpointer, notify_func: TGClosureNotify){.cdecl,
    dynlib: gliblib, importc: "g_closure_remove_finalize_notifier".}
proc add_invalidate_notifier*(closure: PGClosure,
                                        notify_data: gpointer,
                                        notify_func: TGClosureNotify){.cdecl,
    dynlib: gliblib, importc: "g_closure_add_invalidate_notifier".}
proc remove_invalidate_notifier*(closure: PGClosure,
    notify_data: gpointer, notify_func: TGClosureNotify){.cdecl,
    dynlib: gliblib, importc: "g_closure_remove_invalidate_notifier".}
proc add_marshal_guards*(closure: PGClosure,
                                   pre_marshal_data: gpointer,
                                   pre_marshal_notify: TGClosureNotify,
                                   post_marshal_data: gpointer,
                                   post_marshal_notify: TGClosureNotify){.cdecl,
    dynlib: gliblib, importc: "g_closure_add_marshal_guards".}
proc set_marshal*(closure: PGClosure, marshal: TGClosureMarshal){.
    cdecl, dynlib: gliblib, importc: "g_closure_set_marshal".}
proc set_meta_marshal*(closure: PGClosure, marshal_data: gpointer,
                                 meta_marshal: TGClosureMarshal){.cdecl,
    dynlib: gliblib, importc: "g_closure_set_meta_marshal".}
proc invalidate*(closure: PGClosure){.cdecl, dynlib: gliblib,
    importc: "g_closure_invalidate".}
proc invoke*(closure: PGClosure, return_value: PGValue,
                       n_param_values: guint, param_values: PGValue,
                       invocation_hint: gpointer){.cdecl, dynlib: gliblib,
    importc: "g_closure_invoke".}
type
  PGSignalInvocationHint* = ptr TGSignalInvocationHint
  PGSignalCMarshaller* = ptr TGSignalCMarshaller
  TGSignalCMarshaller* = TGClosureMarshal
  TGSignalEmissionHook* = proc (ihint: PGSignalInvocationHint,
                                n_param_values: guint, param_values: PGValue,
                                data: gpointer): gboolean{.cdecl.}
  TGSignalAccumulator* = proc (ihint: PGSignalInvocationHint,
                               return_accu: PGValue, handler_return: PGValue,
                               data: gpointer): gboolean{.cdecl.}
  PGSignalFlags* = ptr TGSignalFlags
  TGSignalFlags* = int32
  TGSignalInvocationHint*{.final.} = object
    signal_id*: guint
    detail*: TGQuark
    run_type*: TGSignalFlags

  PGSignalQuery* = ptr TGSignalQuery
  TGSignalQuery*{.final.} = object
    signal_id*: guint
    signal_name*: cstring
    itype*: GType
    signal_flags*: TGSignalFlags
    return_type*: GType
    n_params*: guint
    param_types*: PGType


const
  G_SIGNAL_RUN_FIRST* = 1 shl 0
  G_SIGNAL_RUN_LAST* = 1 shl 1
  G_SIGNAL_RUN_CLEANUP* = 1 shl 2
  G_SIGNAL_NO_RECURSE* = 1 shl 3
  G_SIGNAL_DETAILED* = 1 shl 4
  G_SIGNAL_ACTION* = 1 shl 5
  G_SIGNAL_NO_HOOKS* = 1 shl 6
  G_SIGNAL_FLAGS_MASK* = 0x0000007F

type
  PGConnectFlags* = ptr TGConnectFlags
  TGConnectFlags* = int32

const
  G_CONNECT_AFTER* = 1 shl 0
  G_CONNECT_SWAPPED* = 1 shl 1

type
  PGSignalMatchType* = ptr TGSignalMatchType
  TGSignalMatchType* = int32

const
  G_SIGNAL_MATCH_ID* = 1 shl 0
  G_SIGNAL_MATCH_DETAIL* = 1 shl 1
  G_SIGNAL_MATCH_CLOSURE* = 1 shl 2
  G_SIGNAL_MATCH_FUNC* = 1 shl 3
  G_SIGNAL_MATCH_DATA* = 1 shl 4
  G_SIGNAL_MATCH_UNBLOCKED* = 1 shl 5
  G_SIGNAL_MATCH_MASK* = 0x0000003F
  G_SIGNAL_TYPE_STATIC_SCOPE* = G_TYPE_FLAG_RESERVED_ID_BIT

proc g_signal_newv*(signal_name: cstring, itype: GType,
                    signal_flags: TGSignalFlags, class_closure: PGClosure,
                    accumulator: TGSignalAccumulator, accu_data: gpointer,
                    c_marshaller: TGSignalCMarshaller, return_type: GType,
                    n_params: guint, param_types: PGType): guint{.cdecl,
    dynlib: gobjectlib, importc: "g_signal_newv".}
proc signal_emitv*(instance_and_params: PGValue, signal_id: guint,
                     detail: TGQuark, return_value: PGValue){.cdecl,
    dynlib: gobjectlib, importc: "g_signal_emitv".}
proc g_signal_lookup*(name: cstring, itype: GType): guint{.cdecl,
    dynlib: gobjectlib, importc: "g_signal_lookup".}
proc g_signal_name*(signal_id: guint): cstring{.cdecl, dynlib: gobjectlib,
    importc: "g_signal_name".}
proc g_signal_query*(signal_id: guint, query: PGSignalQuery){.cdecl,
    dynlib: gobjectlib, importc: "g_signal_query".}
proc g_signal_list_ids*(itype: GType, n_ids: Pguint): Pguint{.cdecl,
    dynlib: gobjectlib, importc: "g_signal_list_ids".}
proc g_signal_parse_name*(detailed_signal: cstring, itype: GType,
                          signal_id_p: Pguint, detail_p: PGQuark,
                          force_detail_quark: gboolean): gboolean{.cdecl,
    dynlib: gobjectlib, importc: "g_signal_parse_name".}
proc g_signal_get_invocation_hint*(instance: gpointer): PGSignalInvocationHint{.
    cdecl, dynlib: gobjectlib, importc: "g_signal_get_invocation_hint".}
proc g_signal_stop_emission*(instance: gpointer, signal_id: guint,
                             detail: TGQuark){.cdecl, dynlib: gobjectlib,
    importc: "g_signal_stop_emission".}
proc g_signal_stop_emission_by_name*(instance: gpointer,
                                     detailed_signal: cstring){.cdecl,
    dynlib: gobjectlib, importc: "g_signal_stop_emission_by_name".}
proc g_signal_add_emission_hook*(signal_id: guint, quark: TGQuark,
                                 hook_func: TGSignalEmissionHook,
                                 hook_data: gpointer,
                                 data_destroy: TGDestroyNotify): gulong{.cdecl,
    dynlib: gobjectlib, importc: "g_signal_add_emission_hook".}
proc g_signal_remove_emission_hook*(signal_id: guint, hook_id: gulong){.cdecl,
    dynlib: gobjectlib, importc: "g_signal_remove_emission_hook".}
proc g_signal_has_handler_pending*(instance: gpointer, signal_id: guint,
                                   detail: TGQuark, may_be_blocked: gboolean): gboolean{.
    cdecl, dynlib: gobjectlib, importc: "g_signal_has_handler_pending".}
proc g_signal_connect_closure_by_id*(instance: gpointer, signal_id: guint,
                                     detail: TGQuark, closure: PGClosure,
                                     after: gboolean): gulong{.cdecl,
    dynlib: gobjectlib, importc: "g_signal_connect_closure_by_id".}
proc g_signal_connect_closure*(instance: gpointer, detailed_signal: cstring,
                               closure: PGClosure, after: gboolean): gulong{.
    cdecl, dynlib: gobjectlib, importc: "g_signal_connect_closure".}
proc g_signal_connect_data*(instance: gpointer, detailed_signal: cstring,
                            c_handler: TGCallback, data: gpointer,
                            destroy_data: TGClosureNotify,
                            connect_flags: TGConnectFlags): gulong{.cdecl,
    dynlib: gobjectlib, importc: "g_signal_connect_data".}
proc g_signal_handler_block*(instance: gpointer, handler_id: gulong){.cdecl,
    dynlib: gobjectlib, importc: "g_signal_handler_block".}
proc g_signal_handler_unblock*(instance: gpointer, handler_id: gulong){.cdecl,
    dynlib: gobjectlib, importc: "g_signal_handler_unblock".}
proc g_signal_handler_disconnect*(instance: gpointer, handler_id: gulong){.
    cdecl, dynlib: gobjectlib, importc: "g_signal_handler_disconnect".}
proc g_signal_handler_is_connected*(instance: gpointer, handler_id: gulong): gboolean{.
    cdecl, dynlib: gobjectlib, importc: "g_signal_handler_is_connected".}
proc g_signal_handler_find*(instance: gpointer, mask: TGSignalMatchType,
                            signal_id: guint, detail: TGQuark,
                            closure: PGClosure, func: gpointer, data: gpointer): gulong{.
    cdecl, dynlib: gobjectlib, importc: "g_signal_handler_find".}
proc g_signal_handlers_block_matched*(instance: gpointer,
                                      mask: TGSignalMatchType, signal_id: guint,
                                      detail: TGQuark, closure: PGClosure,
                                      func: gpointer, data: gpointer): guint{.
    cdecl, dynlib: gobjectlib, importc: "g_signal_handlers_block_matched".}
proc g_signal_handlers_unblock_matched*(instance: gpointer,
                                        mask: TGSignalMatchType,
                                        signal_id: guint, detail: TGQuark,
                                        closure: PGClosure, func: gpointer,
                                        data: gpointer): guint{.cdecl,
    dynlib: gobjectlib, importc: "g_signal_handlers_unblock_matched".}
proc g_signal_handlers_disconnect_matched*(instance: gpointer,
    mask: TGSignalMatchType, signal_id: guint, detail: TGQuark,
    closure: PGClosure, func: gpointer, data: gpointer): guint{.cdecl,
    dynlib: gobjectlib, importc: "g_signal_handlers_disconnect_matched".}
proc g_signal_override_class_closure*(signal_id: guint, instance_type: GType,
                                      class_closure: PGClosure){.cdecl,
    dynlib: gobjectlib, importc: "g_signal_override_class_closure".}
proc signal_chain_from_overridden*(instance_and_params: PGValue,
                                     return_value: PGValue){.cdecl,
    dynlib: gobjectlib, importc: "g_signal_chain_from_overridden".}
proc g_signal_connect*(instance: gpointer, detailed_signal: cstring,
                       c_handler: TGCallback, data: gpointer): gulong
proc g_signal_connect_after*(instance: gpointer, detailed_signal: cstring,
                             c_handler: TGCallback, data: gpointer): gulong
proc g_signal_connect_swapped*(instance: gpointer, detailed_signal: cstring,
                               c_handler: TGCallback, data: gpointer): gulong
proc g_signal_handlers_disconnect_by_func*(instance: gpointer,
    func, data: gpointer): guint
proc g_signal_handlers_block_by_func*(instance: gpointer, func, data: gpointer)
proc g_signal_handlers_unblock_by_func*(instance: gpointer, func, data: gpointer)
proc g_signal_handlers_destroy*(instance: gpointer){.cdecl, dynlib: gobjectlib,
    importc: "g_signal_handlers_destroy".}
proc g_signals_destroy*(itype: GType){.cdecl, dynlib: gobjectlib,
                                       importc: "`g_signals_destroy`".}
type
  TGTypePluginUse* = proc (plugin: PGTypePlugin){.cdecl.}
  TGTypePluginUnuse* = proc (plugin: PGTypePlugin){.cdecl.}
  TGTypePluginCompleteTypeInfo* = proc (plugin: PGTypePlugin, g_type: GType,
                                        info: PGTypeInfo,
                                        value_table: PGTypeValueTable){.cdecl.}
  TGTypePluginCompleteInterfaceInfo* = proc (plugin: PGTypePlugin,
      instance_type: GType, interface_type: GType, info: PGInterfaceInfo){.cdecl.}
  PGTypePluginClass* = ptr TGTypePluginClass
  TGTypePluginClass*{.final.} = object
    base_iface*: TGTypeInterface
    use_plugin*: TGTypePluginUse
    unuse_plugin*: TGTypePluginUnuse
    complete_type_info*: TGTypePluginCompleteTypeInfo
    complete_interface_info*: TGTypePluginCompleteInterfaceInfo


proc G_TYPE_TYPE_PLUGIN*(): GType
proc G_TYPE_PLUGIN*(inst: Pointer): PGTypePlugin
proc G_TYPE_PLUGIN_CLASS*(vtable: Pointer): PGTypePluginClass
proc G_IS_TYPE_PLUGIN*(inst: Pointer): bool
proc G_IS_TYPE_PLUGIN_CLASS*(vtable: Pointer): bool
proc G_TYPE_PLUGIN_GET_CLASS*(inst: Pointer): PGTypePluginClass
proc g_type_plugin_get_type*(): GType{.cdecl, dynlib: gliblib,
                                       importc: "g_type_plugin_get_type".}
proc plugin_use*(plugin: PGTypePlugin){.cdecl, dynlib: gliblib,
    importc: "g_type_plugin_use".}
proc plugin_unuse*(plugin: PGTypePlugin){.cdecl, dynlib: gliblib,
    importc: "g_type_plugin_unuse".}
proc plugin_complete_type_info*(plugin: PGTypePlugin, g_type: GType,
                                       info: PGTypeInfo,
                                       value_table: PGTypeValueTable){.cdecl,
    dynlib: gliblib, importc: "g_type_plugin_complete_type_info".}
proc plugin_complete_interface_info*(plugin: PGTypePlugin,
    instance_type: GType, interface_type: GType, info: PGInterfaceInfo){.cdecl,
    dynlib: gliblib, importc: "g_type_plugin_complete_interface_info".}
type
  PGObject* = ptr TGObject
  TGObject*{.pure, inheritable.} = object
    g_type_instance*: TGTypeInstance
    ref_count*: guint
    qdata*: PGData

  TGObjectGetPropertyFunc* = proc (anObject: PGObject, property_id: guint,
                                   value: PGValue, pspec: PGParamSpec){.cdecl.}
  TGObjectSetPropertyFunc* = proc (anObject: PGObject, property_id: guint,
                                   value: PGValue, pspec: PGParamSpec){.cdecl.}
  TGObjectFinalizeFunc* = proc (anObject: PGObject){.cdecl.}
  TGWeakNotify* = proc (data: gpointer, where_the_object_was: PGObject){.cdecl.}
  PGObjectConstructParam* = ptr TGObjectConstructParam
  PGObjectClass* = ptr TGObjectClass
  TGObjectClass*{.pure, inheritable.} = object
    g_type_class*: TGTypeClass
    construct_properties*: PGSList
    constructor*: proc (theType: GType, n_construct_properties: guint,
                        construct_properties: PGObjectConstructParam): PGObject{.
        cdecl.}
    set_property*: proc (anObject: PGObject, property_id: guint, value: PGValue,
                         pspec: PGParamSpec){.cdecl.}
    get_property*: proc (anObject: PGObject, property_id: guint, value: PGValue,
                         pspec: PGParamSpec){.cdecl.}
    dispose*: proc (anObject: PGObject){.cdecl.}
    finalize*: proc (anObject: PGObject){.cdecl.}
    dispatch_properties_changed*: proc (anObject: PGObject, n_pspecs: guint,
                                        pspecs: PPGParamSpec){.cdecl.}
    notify*: proc (anObject: PGObject, pspec: PGParamSpec){.cdecl.}
    pdummy*: array[0..7, gpointer]

  TGObjectConstructParam*{.final.} = object
    pspec*: PGParamSpec
    value*: PGValue


proc G_TYPE_IS_OBJECT*(theType: GType): bool
proc G_OBJECT*(anObject: pointer): PGObject
proc G_OBJECT_CLASS*(class: Pointer): PGObjectClass
proc G_IS_OBJECT*(anObject: pointer): bool
proc G_IS_OBJECT_CLASS*(class: Pointer): bool
proc G_OBJECT_GET_CLASS*(anObject: pointer): PGObjectClass
proc G_OBJECT_TYPE*(anObject: pointer): GType
proc G_OBJECT_TYPE_NAME*(anObject: pointer): cstring
proc G_OBJECT_CLASS_TYPE*(class: Pointer): GType
proc G_OBJECT_CLASS_NAME*(class: Pointer): cstring
proc G_VALUE_HOLDS_OBJECT*(value: Pointer): bool
proc class_install_property*(oclass: PGObjectClass, property_id: guint,
                                      pspec: PGParamSpec){.cdecl,
    dynlib: gobjectlib, importc: "g_object_class_install_property".}
proc class_find_property*(oclass: PGObjectClass, property_name: cstring): PGParamSpec{.
    cdecl, dynlib: gobjectlib, importc: "g_object_class_find_property".}
proc class_list_properties*(oclass: PGObjectClass, n_properties: Pguint): PPGParamSpec{.
    cdecl, dynlib: gobjectlib, importc: "g_object_class_list_properties".}
proc set_property*(anObject: PGObject, property_name: cstring,
                            value: PGValue){.cdecl, dynlib: gobjectlib,
    importc: "g_object_set_property".}
proc get_property*(anObject: PGObject, property_name: cstring,
                            value: PGValue){.cdecl, dynlib: gobjectlib,
    importc: "g_object_get_property".}
proc freeze_notify*(anObject: PGObject){.cdecl, dynlib: gobjectlib,
    importc: "g_object_freeze_notify".}
proc notify*(anObject: PGObject, property_name: cstring){.cdecl,
    dynlib: gobjectlib, importc: "g_object_notify".}
proc thaw_notify*(anObject: PGObject){.cdecl, dynlib: gobjectlib,
    importc: "g_object_thaw_notify".}
proc g_object_ref*(anObject: gpointer): gpointer{.cdecl, dynlib: gobjectlib,
    importc: "g_object_ref".}
proc g_object_unref*(anObject: gpointer){.cdecl, dynlib: gobjectlib,
    importc: "g_object_unref".}
proc weak_ref*(anObject: PGObject, notify: TGWeakNotify, data: gpointer){.
    cdecl, dynlib: gobjectlib, importc: "g_object_weak_ref".}
proc weak_unref*(anObject: PGObject, notify: TGWeakNotify,
                          data: gpointer){.cdecl, dynlib: gobjectlib,
    importc: "g_object_weak_unref".}
proc add_weak_pointer*(anObject: PGObject,
                                weak_pointer_location: Pgpointer){.cdecl,
    dynlib: gobjectlib, importc: "g_object_add_weak_pointer".}
proc remove_weak_pointer*(anObject: PGObject,
                                   weak_pointer_location: Pgpointer){.cdecl,
    dynlib: gobjectlib, importc: "g_object_remove_weak_pointer".}
proc get_qdata*(anObject: PGObject, quark: TGQuark): gpointer{.cdecl,
    dynlib: gobjectlib, importc: "g_object_get_qdata".}
proc set_qdata*(anObject: PGObject, quark: TGQuark, data: gpointer){.
    cdecl, dynlib: gobjectlib, importc: "g_object_set_qdata".}
proc set_qdata_full*(anObject: PGObject, quark: TGQuark,
                              data: gpointer, destroy: TGDestroyNotify){.cdecl,
    dynlib: gobjectlib, importc: "g_object_set_qdata_full".}
proc steal_qdata*(anObject: PGObject, quark: TGQuark): gpointer{.cdecl,
    dynlib: gobjectlib, importc: "g_object_steal_qdata".}
proc get_data*(anObject: PGObject, key: cstring): gpointer{.cdecl,
    dynlib: gobjectlib, importc: "g_object_get_data".}
proc set_data*(anObject: PGObject, key: cstring, data: gpointer){.
    cdecl, dynlib: gobjectlib, importc: "g_object_set_data".}
proc set_data_full*(anObject: PGObject, key: cstring, data: gpointer,
                             destroy: TGDestroyNotify){.cdecl,
    dynlib: gobjectlib, importc: "g_object_set_data_full".}
proc steal_data*(anObject: PGObject, key: cstring): gpointer{.cdecl,
    dynlib: gobjectlib, importc: "g_object_steal_data".}
proc watch_closure*(anObject: PGObject, closure: PGClosure){.cdecl,
    dynlib: gobjectlib, importc: "g_object_watch_closure".}
proc g_cclosure_new_object*(callback_func: TGCallback, anObject: PGObject): PGClosure{.
    cdecl, dynlib: gobjectlib, importc: "g_cclosure_new_object".}
proc g_cclosure_new_object_swap*(callback_func: TGCallback, anObject: PGObject): PGClosure{.
    cdecl, dynlib: gobjectlib, importc: "g_cclosure_new_object_swap".}
proc g_closure_new_object*(sizeof_closure: guint, anObject: PGObject): PGClosure{.
    cdecl, dynlib: gobjectlib, importc: "g_closure_new_object".}
proc set_object*(value: PGValue, v_object: gpointer){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_object".}
proc get_object*(value: PGValue): gpointer{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_object".}
proc dup_object*(value: PGValue): PGObject{.cdecl, dynlib: gobjectlib,
    importc: "g_value_dup_object".}
proc g_signal_connect_object*(instance: gpointer, detailed_signal: cstring,
                              c_handler: TGCallback, gobject: gpointer,
                              connect_flags: TGConnectFlags): gulong{.cdecl,
    dynlib: gobjectlib, importc: "g_signal_connect_object".}
proc run_dispose*(anObject: PGObject){.cdecl, dynlib: gobjectlib,
    importc: "g_object_run_dispose".}
proc set_object_take_ownership*(value: PGValue, v_object: gpointer){.
    cdecl, dynlib: gobjectlib, importc: "g_value_set_object_take_ownership".}
proc G_OBJECT_WARN_INVALID_PSPEC*(anObject: gpointer, pname: cstring,
                                  property_id: gint, pspec: gpointer)
proc G_OBJECT_WARN_INVALID_PROPERTY_ID*(anObject: gpointer, property_id: gint,
                                        pspec: gpointer)
type
  G_FLAGS_TYPE* = GType

const
  G_E* = 2.71828
  G_LN2* = 0.693147
  G_LN10* = 2.30259
  G_PI* = 3.14159
  G_PI_2* = 1.57080
  G_PI_4* = 0.785398
  G_SQRT2* = 1.41421
  G_LITTLE_ENDIAN* = 1234
  G_BIG_ENDIAN* = 4321
  G_PDP_ENDIAN* = 3412

proc GUINT16_SWAP_LE_BE_CONSTANT*(val: guint16): guint16
proc GUINT32_SWAP_LE_BE_CONSTANT*(val: guint32): guint32
type
  PGEnumClass* = ptr TGEnumClass
  PGEnumValue* = ptr TGEnumValue
  TGEnumClass*{.final.} = object
    g_type_class*: TGTypeClass
    minimum*: gint
    maximum*: gint
    n_values*: guint
    values*: PGEnumValue

  TGEnumValue*{.final.} = object
    value*: gint
    value_name*: cstring
    value_nick*: cstring

  PGFlagsClass* = ptr TGFlagsClass
  PGFlagsValue* = ptr TGFlagsValue
  TGFlagsClass*{.final.} = object
    g_type_class*: TGTypeClass
    mask*: guint
    n_values*: guint
    values*: PGFlagsValue

  TGFlagsValue*{.final.} = object
    value*: guint
    value_name*: cstring
    value_nick*: cstring


proc G_TYPE_IS_ENUM*(theType: GType): gboolean
proc G_ENUM_CLASS*(class: pointer): PGEnumClass
proc G_IS_ENUM_CLASS*(class: pointer): gboolean
proc G_ENUM_CLASS_TYPE*(class: pointer): GType
proc G_ENUM_CLASS_TYPE_NAME*(class: pointer): cstring
proc G_TYPE_IS_FLAGS*(theType: GType): gboolean
proc G_FLAGS_CLASS*(class: pointer): PGFlagsClass
proc G_IS_FLAGS_CLASS*(class: pointer): gboolean
proc G_FLAGS_CLASS_TYPE*(class: pointer): GType
proc G_FLAGS_CLASS_TYPE_NAME*(class: pointer): cstring
proc G_VALUE_HOLDS_ENUM*(value: pointer): gboolean
proc G_VALUE_HOLDS_FLAGS*(value: pointer): gboolean
proc get_value*(enum_class: PGEnumClass, value: gint): PGEnumValue{.
    cdecl, dynlib: gliblib, importc: "g_enum_get_value".}
proc get_value_by_name*(enum_class: PGEnumClass, name: cstring): PGEnumValue{.
    cdecl, dynlib: gliblib, importc: "g_enum_get_value_by_name".}
proc get_value_by_nick*(enum_class: PGEnumClass, nick: cstring): PGEnumValue{.
    cdecl, dynlib: gliblib, importc: "g_enum_get_value_by_nick".}
proc get_first_value*(flags_class: PGFlagsClass, value: guint): PGFlagsValue{.
    cdecl, dynlib: gliblib, importc: "g_flags_get_first_value".}
proc get_value_by_name*(flags_class: PGFlagsClass, name: cstring): PGFlagsValue{.
    cdecl, dynlib: gliblib, importc: "g_flags_get_value_by_name".}
proc get_value_by_nick*(flags_class: PGFlagsClass, nick: cstring): PGFlagsValue{.
    cdecl, dynlib: gliblib, importc: "g_flags_get_value_by_nick".}
proc set_enum*(value: PGValue, v_enum: gint){.cdecl, dynlib: gliblib,
    importc: "g_value_set_enum".}
proc get_enum*(value: PGValue): gint{.cdecl, dynlib: gliblib,
    importc: "g_value_get_enum".}
proc set_flags*(value: PGValue, v_flags: guint){.cdecl, dynlib: gliblib,
    importc: "g_value_set_flags".}
proc get_flags*(value: PGValue): guint{.cdecl, dynlib: gliblib,
    importc: "g_value_get_flags".}
proc g_enum_register_static*(name: cstring, const_static_values: PGEnumValue): GType{.
    cdecl, dynlib: gliblib, importc: "g_enum_register_static".}
proc g_flags_register_static*(name: cstring, const_static_values: PGFlagsValue): GType{.
    cdecl, dynlib: gliblib, importc: "g_flags_register_static".}
proc g_enum_complete_type_info*(g_enum_type: GType, info: PGTypeInfo,
                                const_values: PGEnumValue){.cdecl,
    dynlib: gliblib, importc: "g_enum_complete_type_info".}
proc g_flags_complete_type_info*(g_flags_type: GType, info: PGTypeInfo,
                                 const_values: PGFlagsValue){.cdecl,
    dynlib: gliblib, importc: "g_flags_complete_type_info".}
const
  G_MINFLOAT* = 0.00000
  G_MAXFLOAT* = 1.70000e+308
  G_MINDOUBLE* = G_MINFLOAT
  G_MAXDOUBLE* = G_MAXFLOAT
  G_MAXSHORT* = 32767
  G_MINSHORT* = - G_MAXSHORT - 1
  G_MAXUSHORT* = 2 * G_MAXSHORT + 1
  G_MAXINT* = 2147483647
  G_MININT* = - G_MAXINT - 1
  G_MAXUINT* = - 1
  G_MINLONG* = G_MININT
  G_MAXLONG* = G_MAXINT
  G_MAXULONG* = G_MAXUINT
  G_MAXINT64* = high(int64)
  G_MININT64* = low(int64)

const
  G_GINT16_FORMAT* = "hi"
  G_GUINT16_FORMAT* = "hu"
  G_GINT32_FORMAT* = 'i'
  G_GUINT32_FORMAT* = 'u'
  G_HAVE_GINT64* = 1
  G_GINT64_FORMAT* = "I64i"
  G_GUINT64_FORMAT* = "I64u"
  GLIB_SIZEOF_VOID_P* = SizeOf(Pointer)
  GLIB_SIZEOF_LONG* = SizeOf(int32)
  GLIB_SIZEOF_SIZE_T* = SizeOf(int32)

type
  PGSystemThread* = ptr TGSystemThread
  TGSystemThread*{.final.} = object
    data*: array[0..3, char]
    dummy_double*: float64
    dummy_pointer*: pointer
    dummy_long*: int32


const
  GLIB_SYSDEF_POLLIN* = 1
  GLIB_SYSDEF_POLLOUT* = 4
  GLIB_SYSDEF_POLLPRI* = 2
  GLIB_SYSDEF_POLLERR* = 8
  GLIB_SYSDEF_POLLHUP* = 16
  GLIB_SYSDEF_POLLNVAL* = 32

proc GUINT_TO_POINTER*(i: guint): pointer
type
  PGAsciiType* = ptr TGAsciiType
  TGAsciiType* = int32

const
  G_ASCII_ALNUM* = 1 shl 0
  G_ASCII_ALPHA* = 1 shl 1
  G_ASCII_CNTRL* = 1 shl 2
  G_ASCII_DIGIT* = 1 shl 3
  G_ASCII_GRAPH* = 1 shl 4
  G_ASCII_LOWER* = 1 shl 5
  G_ASCII_PRINT* = 1 shl 6
  G_ASCII_PUNCT* = 1 shl 7
  G_ASCII_SPACE* = 1 shl 8
  G_ASCII_UPPER* = 1 shl 9
  G_ASCII_XDIGIT* = 1 shl 10

proc g_ascii_tolower*(c: gchar): gchar{.cdecl, dynlib: gliblib,
                                        importc: "g_ascii_tolower".}
proc g_ascii_toupper*(c: gchar): gchar{.cdecl, dynlib: gliblib,
                                        importc: "g_ascii_toupper".}
proc g_ascii_digit_value*(c: gchar): gint{.cdecl, dynlib: gliblib,
    importc: "g_ascii_digit_value".}
proc g_ascii_xdigit_value*(c: gchar): gint{.cdecl, dynlib: gliblib,
    importc: "g_ascii_xdigit_value".}
const
  G_STR_DELIMITERS* = "``-|> <."

proc g_strdelimit*(str: cstring, delimiters: cstring, new_delimiter: gchar): cstring{.
    cdecl, dynlib: gliblib, importc: "g_strdelimit".}
proc g_strcanon*(str: cstring, valid_chars: cstring, substitutor: gchar): cstring{.
    cdecl, dynlib: gliblib, importc: "g_strcanon".}
proc g_strerror*(errnum: gint): cstring{.cdecl, dynlib: gliblib,
    importc: "g_strerror".}
proc g_strsignal*(signum: gint): cstring{.cdecl, dynlib: gliblib,
    importc: "g_strsignal".}
proc g_strreverse*(str: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_strreverse".}
proc g_strlcpy*(dest: cstring, src: cstring, dest_size: gsize): gsize{.cdecl,
    dynlib: gliblib, importc: "g_strlcpy".}
proc g_strlcat*(dest: cstring, src: cstring, dest_size: gsize): gsize{.cdecl,
    dynlib: gliblib, importc: "g_strlcat".}
proc g_strstr_len*(haystack: cstring, haystack_len: gssize, needle: cstring): cstring{.
    cdecl, dynlib: gliblib, importc: "g_strstr_len".}
proc g_strrstr*(haystack: cstring, needle: cstring): cstring{.cdecl,
    dynlib: gliblib, importc: "g_strrstr".}
proc g_strrstr_len*(haystack: cstring, haystack_len: gssize, needle: cstring): cstring{.
    cdecl, dynlib: gliblib, importc: "g_strrstr_len".}
proc g_str_has_suffix*(str: cstring, suffix: cstring): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_str_has_suffix".}
proc g_str_has_prefix*(str: cstring, prefix: cstring): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_str_has_prefix".}
proc g_strtod*(nptr: cstring, endptr: PPgchar): gdouble{.cdecl, dynlib: gliblib,
    importc: "g_strtod".}
proc g_ascii_strtod*(nptr: cstring, endptr: PPgchar): gdouble{.cdecl,
    dynlib: gliblib, importc: "g_ascii_strtod".}
const
  G_ASCII_DTOSTR_BUF_SIZE* = 29 + 10

proc g_ascii_dtostr*(buffer: cstring, buf_len: gint, d: gdouble): cstring{.
    cdecl, dynlib: gliblib, importc: "g_ascii_dtostr".}
proc g_ascii_formatd*(buffer: cstring, buf_len: gint, format: cstring,
                      d: gdouble): cstring{.cdecl, dynlib: gliblib,
    importc: "g_ascii_formatd".}
proc g_strchug*(str: cstring): cstring{.cdecl, dynlib: gliblib,
                                        importc: "g_strchug".}
proc g_strchomp*(str: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_strchomp".}
proc g_ascii_strcasecmp*(s1: cstring, s2: cstring): gint{.cdecl,
    dynlib: gliblib, importc: "g_ascii_strcasecmp".}
proc g_ascii_strncasecmp*(s1: cstring, s2: cstring, n: gsize): gint{.cdecl,
    dynlib: gliblib, importc: "g_ascii_strncasecmp".}
proc g_ascii_strdown*(str: cstring, len: gssize): cstring{.cdecl,
    dynlib: gliblib, importc: "g_ascii_strdown".}
proc g_ascii_strup*(str: cstring, len: gssize): cstring{.cdecl, dynlib: gliblib,
    importc: "g_ascii_strup".}
proc g_strdup*(str: cstring): cstring{.cdecl, dynlib: gliblib,
                                       importc: "g_strdup".}
proc g_strndup*(str: cstring, n: gsize): cstring{.cdecl, dynlib: gliblib,
    importc: "g_strndup".}
proc g_strnfill*(length: gsize, fill_char: gchar): cstring{.cdecl,
    dynlib: gliblib, importc: "g_strnfill".}
proc g_strcompress*(source: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_strcompress".}
proc g_strescape*(source: cstring, exceptions: cstring): cstring{.cdecl,
    dynlib: gliblib, importc: "g_strescape".}
proc g_memdup*(mem: gconstpointer, byte_size: guint): gpointer{.cdecl,
    dynlib: gliblib, importc: "g_memdup".}
proc g_strsplit*(str: cstring, delimiter: cstring, max_tokens: gint): PPgchar{.
    cdecl, dynlib: gliblib, importc: "g_strsplit".}
proc g_strjoinv*(separator: cstring, str_array: PPgchar): cstring{.cdecl,
    dynlib: gliblib, importc: "g_strjoinv".}
proc g_strfreev*(str_array: PPgchar){.cdecl, dynlib: gliblib,
                                      importc: "g_strfreev".}
proc g_strdupv*(str_array: PPgchar): PPgchar{.cdecl, dynlib: gliblib,
    importc: "g_strdupv".}
proc g_stpcpy*(dest: cstring, src: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_stpcpy".}
proc g_get_user_name*(): cstring{.cdecl, dynlib: gliblib,
                                  importc: "g_get_user_name".}
proc g_get_real_name*(): cstring{.cdecl, dynlib: gliblib,
                                  importc: "g_get_real_name".}
proc g_get_home_dir*(): cstring{.cdecl, dynlib: gliblib,
                                 importc: "g_get_home_dir".}
proc g_get_tmp_dir*(): cstring{.cdecl, dynlib: gliblib, importc: "g_get_tmp_dir".}
proc g_get_prgname*(): cstring{.cdecl, dynlib: gliblib, importc: "g_get_prgname".}
proc g_set_prgname*(prgname: cstring){.cdecl, dynlib: gliblib,
                                       importc: "g_set_prgname".}
type
  PGDebugKey* = ptr TGDebugKey
  TGDebugKey*{.final.} = object
    key*: cstring
    value*: guint


proc g_parse_debug_string*(str: cstring, keys: PGDebugKey, nkeys: guint): guint{.
    cdecl, dynlib: gliblib, importc: "g_parse_debug_string".}
proc g_path_is_absolute*(file_name: cstring): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_path_is_absolute".}
proc g_path_skip_root*(file_name: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_path_skip_root".}
proc g_basename*(file_name: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_basename".}
proc g_dirname*(file_name: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_path_get_dirname".}
proc g_get_current_dir*(): cstring{.cdecl, dynlib: gliblib,
                                    importc: "g_get_current_dir".}
proc g_path_get_basename*(file_name: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_path_get_basename".}
proc g_path_get_dirname*(file_name: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_path_get_dirname".}
proc nullify_pointer*(nullify_location: Pgpointer){.cdecl, dynlib: gliblib,
    importc: "g_nullify_pointer".}
proc g_getenv*(variable: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_getenv".}
type
  TGVoidFunc* = proc (){.cdecl.}

proc g_atexit*(func: TGVoidFunc){.cdecl, dynlib: gliblib, importc: "g_atexit".}
proc g_find_program_in_path*(program: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_find_program_in_path".}
proc g_bit_nth_lsf*(mask: gulong, nth_bit: gint): gint{.cdecl, dynlib: gliblib,
    importc: "g_bit_nth_lsf".}
proc g_bit_nth_msf*(mask: gulong, nth_bit: gint): gint{.cdecl, dynlib: gliblib,
    importc: "g_bit_nth_msf".}
proc g_bit_storage*(number: gulong): guint{.cdecl, dynlib: gliblib,
    importc: "g_bit_storage".}
type
  PPGTrashStack* = ptr PGTrashStack
  PGTrashStack* = ptr TGTrashStack
  TGTrashStack*{.final.} = object
    next*: PGTrashStack


proc g_trash_stack_push*(stack_p: PPGTrashStack, data_p: gpointer){.cdecl,
    dynlib: gliblib, importc: "g_trash_stack_push".}
proc g_trash_stack_pop*(stack_p: PPGTrashStack): gpointer{.cdecl,
    dynlib: gliblib, importc: "g_trash_stack_pop".}
proc g_trash_stack_peek*(stack_p: PPGTrashStack): gpointer{.cdecl,
    dynlib: gliblib, importc: "g_trash_stack_peek".}
proc g_trash_stack_height*(stack_p: PPGTrashStack): guint{.cdecl,
    dynlib: gliblib, importc: "g_trash_stack_height".}
type
  PGHashTable* = pointer
  TGHRFunc* = proc (key, value, user_data: gpointer): gboolean{.cdecl.}

proc g_hash_table_new*(hash_func: TGHashFunc, key_equal_func: TGEqualFunc): PGHashTable{.
    cdecl, dynlib: gliblib, importc: "g_hash_table_new".}
proc g_hash_table_new_full*(hash_func: TGHashFunc, key_equal_func: TGEqualFunc,
                            key_destroy_func: TGDestroyNotify,
                            value_destroy_func: TGDestroyNotify): PGHashTable{.
    cdecl, dynlib: gliblib, importc: "g_hash_table_new_full".}
proc table_destroy*(hash_table: PGHashTable){.cdecl, dynlib: gliblib,
    importc: "g_hash_table_destroy".}
proc table_insert*(hash_table: PGHashTable, key: gpointer,
                          value: gpointer){.cdecl, dynlib: gliblib,
    importc: "g_hash_table_insert".}
proc table_replace*(hash_table: PGHashTable, key: gpointer,
                           value: gpointer){.cdecl, dynlib: gliblib,
    importc: "g_hash_table_replace".}
proc table_remove*(hash_table: PGHashTable, key: gconstpointer): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_hash_table_remove".}
proc table_steal*(hash_table: PGHashTable, key: gconstpointer): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_hash_table_steal".}
proc table_lookup*(hash_table: PGHashTable, key: gconstpointer): gpointer{.
    cdecl, dynlib: gliblib, importc: "g_hash_table_lookup".}
proc table_lookup_extended*(hash_table: PGHashTable,
                                   lookup_key: gconstpointer,
                                   orig_key: Pgpointer, value: Pgpointer): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_hash_table_lookup_extended".}
proc table_foreach*(hash_table: PGHashTable, func: TGHFunc,
                           user_data: gpointer){.cdecl, dynlib: gliblib,
    importc: "g_hash_table_foreach".}
proc table_foreach_remove*(hash_table: PGHashTable, func: TGHRFunc,
                                  user_data: gpointer): guint{.cdecl,
    dynlib: gliblib, importc: "g_hash_table_foreach_remove".}
proc table_foreach_steal*(hash_table: PGHashTable, func: TGHRFunc,
                                 user_data: gpointer): guint{.cdecl,
    dynlib: gliblib, importc: "g_hash_table_foreach_steal".}
proc table_size*(hash_table: PGHashTable): guint{.cdecl, dynlib: gliblib,
    importc: "g_hash_table_size".}
proc g_str_equal*(v: gconstpointer, v2: gconstpointer): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_str_equal".}
proc g_str_hash*(v: gconstpointer): guint{.cdecl, dynlib: gliblib,
    importc: "g_str_hash".}
proc g_int_equal*(v: gconstpointer, v2: gconstpointer): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_int_equal".}
proc g_int_hash*(v: gconstpointer): guint{.cdecl, dynlib: gliblib,
    importc: "g_int_hash".}
proc g_direct_hash*(v: gconstpointer): guint{.cdecl, dynlib: gliblib,
    importc: "g_direct_hash".}
proc g_direct_equal*(v: gconstpointer, v2: gconstpointer): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_direct_equal".}
proc g_quark_try_string*(str: cstring): TGQuark{.cdecl, dynlib: gliblib,
    importc: "g_quark_try_string".}
proc g_quark_from_static_string*(str: cstring): TGQuark{.cdecl, dynlib: gliblib,
    importc: "g_quark_from_static_string".}
proc g_quark_from_string*(str: cstring): TGQuark{.cdecl, dynlib: gliblib,
    importc: "g_quark_from_string".}
proc g_quark_to_string*(quark: TGQuark): cstring{.cdecl, dynlib: gliblib,
    importc: "g_quark_to_string".}
const
  G_MEM_ALIGN* = GLIB_SIZEOF_VOID_P

type
  PGMemVTable* = ptr TGMemVTable
  TGMemVTable*{.final.} = object
    malloc*: proc (n_bytes: gsize): gpointer{.cdecl.}
    realloc*: proc (mem: gpointer, n_bytes: gsize): gpointer{.cdecl.}
    free*: proc (mem: gpointer){.cdecl.}
    calloc*: proc (n_blocks: gsize, n_block_bytes: gsize): gpointer{.cdecl.}
    try_malloc*: proc (n_bytes: gsize): gpointer{.cdecl.}
    try_realloc*: proc (mem: gpointer, n_bytes: gsize): gpointer{.cdecl.}

  PGMemChunk* = pointer
  PGAllocator* = pointer

proc g_malloc*(n_bytes: gulong): gpointer{.cdecl, dynlib: gliblib,
    importc: "g_malloc".}
proc g_malloc0*(n_bytes: gulong): gpointer{.cdecl, dynlib: gliblib,
    importc: "g_malloc0".}
proc g_realloc*(mem: gpointer, n_bytes: gulong): gpointer{.cdecl,
    dynlib: gliblib, importc: "g_realloc".}
proc g_free*(mem: gpointer){.cdecl, dynlib: gliblib, importc: "g_free".}
proc g_try_malloc*(n_bytes: gulong): gpointer{.cdecl, dynlib: gliblib,
    importc: "g_try_malloc".}
proc g_try_realloc*(mem: gpointer, n_bytes: gulong): gpointer{.cdecl,
    dynlib: gliblib, importc: "g_try_realloc".}
#proc g_new*(bytes_per_struct, n_structs: gsize): gpointer
#proc g_new0*(bytes_per_struct, n_structs: gsize): gpointer
#proc g_renew*(struct_size: gsize, OldMem: gpointer, n_structs: gsize): gpointer

proc set_vtable*(vtable: PGMemVTable){.cdecl, dynlib: gliblib,
    importc: "g_mem_set_vtable".}
proc g_mem_is_system_malloc*(): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_mem_is_system_malloc".}
proc g_mem_profile*(){.cdecl, dynlib: gliblib, importc: "g_mem_profile".}
proc g_chunk_new*(chunk: Pointer): Pointer
proc g_chunk_new0*(chunk: Pointer): Pointer

const
  G_ALLOC_ONLY* = 1
  G_ALLOC_AND_FREE* = 2

proc g_mem_chunk_new*(name: cstring, atom_size: gint, area_size: gulong,
                      theType: gint): PGMemChunk{.cdecl, dynlib: gliblib,
    importc: "g_mem_chunk_new".}
proc chunk_destroy*(mem_chunk: PGMemChunk){.cdecl, dynlib: gliblib,
    importc: "g_mem_chunk_destroy".}
proc chunk_alloc*(mem_chunk: PGMemChunk): gpointer{.cdecl,
    dynlib: gliblib, importc: "g_mem_chunk_alloc".}
proc chunk_alloc0*(mem_chunk: PGMemChunk): gpointer{.cdecl,
    dynlib: gliblib, importc: "g_mem_chunk_alloc0".}
proc chunk_free*(mem_chunk: PGMemChunk, mem: gpointer){.cdecl,
    dynlib: gliblib, importc: "g_mem_chunk_free".}
proc chunk_clean*(mem_chunk: PGMemChunk){.cdecl, dynlib: gliblib,
    importc: "g_mem_chunk_clean".}
proc chunk_reset*(mem_chunk: PGMemChunk){.cdecl, dynlib: gliblib,
    importc: "g_mem_chunk_reset".}
proc chunk_print*(mem_chunk: PGMemChunk){.cdecl, dynlib: gliblib,
    importc: "g_mem_chunk_print".}
proc g_mem_chunk_info*(){.cdecl, dynlib: gliblib, importc: "g_mem_chunk_info".}
proc g_blow_chunks*(){.cdecl, dynlib: gliblib, importc: "g_blow_chunks".}
proc g_allocator_new*(name: cstring, n_preallocs: guint): PGAllocator{.cdecl,
    dynlib: gliblib, importc: "g_allocator_new".}
proc free*(allocator: PGAllocator){.cdecl, dynlib: gliblib,
    importc: "g_allocator_free".}
const
  G_ALLOCATOR_LIST* = 1
  G_ALLOCATOR_SLIST* = 2
  G_ALLOCATOR_NODE* = 3

proc slist_push_allocator*(allocator: PGAllocator){.cdecl, dynlib: gliblib,
    importc: "g_slist_push_allocator".}
proc g_slist_pop_allocator*(){.cdecl, dynlib: gliblib,
                               importc: "g_slist_pop_allocator".}
proc g_slist_alloc*(): PGSList{.cdecl, dynlib: gliblib, importc: "g_slist_alloc".}
proc free*(list: PGSList){.cdecl, dynlib: gliblib,
                                   importc: "g_slist_free".}
proc free_1*(list: PGSList){.cdecl, dynlib: gliblib,
                                     importc: "g_slist_free_1".}
proc append*(list: PGSList, data: gpointer): PGSList{.cdecl,
    dynlib: gliblib, importc: "g_slist_append".}
proc prepend*(list: PGSList, data: gpointer): PGSList{.cdecl,
    dynlib: gliblib, importc: "g_slist_prepend".}
proc insert*(list: PGSList, data: gpointer, position: gint): PGSList{.
    cdecl, dynlib: gliblib, importc: "g_slist_insert".}
proc insert_sorted*(list: PGSList, data: gpointer, func: TGCompareFunc): PGSList{.
    cdecl, dynlib: gliblib, importc: "g_slist_insert_sorted".}
proc insert_before*(slist: PGSList, sibling: PGSList, data: gpointer): PGSList{.
    cdecl, dynlib: gliblib, importc: "g_slist_insert_before".}
proc concat*(list1: PGSList, list2: PGSList): PGSList{.cdecl,
    dynlib: gliblib, importc: "g_slist_concat".}
proc remove*(list: PGSList, data: gconstpointer): PGSList{.cdecl,
    dynlib: gliblib, importc: "g_slist_remove".}
proc remove_all*(list: PGSList, data: gconstpointer): PGSList{.cdecl,
    dynlib: gliblib, importc: "g_slist_remove_all".}
proc remove_link*(list: PGSList, link: PGSList): PGSList{.cdecl,
    dynlib: gliblib, importc: "g_slist_remove_link".}
proc delete_link*(list: PGSList, link: PGSList): PGSList{.cdecl,
    dynlib: gliblib, importc: "g_slist_delete_link".}
proc reverse*(list: PGSList): PGSList{.cdecl, dynlib: gliblib,
    importc: "g_slist_reverse".}
proc copy*(list: PGSList): PGSList{.cdecl, dynlib: gliblib,
    importc: "g_slist_copy".}
proc nth*(list: PGSList, n: guint): PGSList{.cdecl, dynlib: gliblib,
    importc: "g_slist_nth".}
proc find*(list: PGSList, data: gconstpointer): PGSList{.cdecl,
    dynlib: gliblib, importc: "g_slist_find".}
proc find_custom*(list: PGSList, data: gconstpointer,
                          func: TGCompareFunc): PGSList{.cdecl, dynlib: gliblib,
    importc: "g_slist_find_custom".}
proc position*(list: PGSList, llink: PGSList): gint{.cdecl,
    dynlib: gliblib, importc: "g_slist_position".}
proc index*(list: PGSList, data: gconstpointer): gint{.cdecl,
    dynlib: gliblib, importc: "g_slist_index".}
proc last*(list: PGSList): PGSList{.cdecl, dynlib: gliblib,
    importc: "g_slist_last".}
proc length*(list: PGSList): guint{.cdecl, dynlib: gliblib,
    importc: "g_slist_length".}
proc foreach*(list: PGSList, func: TGFunc, user_data: gpointer){.cdecl,
    dynlib: gliblib, importc: "g_slist_foreach".}
proc sort*(list: PGSList, compare_func: TGCompareFunc): PGSList{.cdecl,
    dynlib: gliblib, importc: "g_slist_sort".}
proc sort*(list: PGSList, compare_func: TGCompareDataFunc,
                             user_data: gpointer): PGSList{.cdecl,
    dynlib: gliblib, importc: "g_slist_sort_with_data".}
proc nth_data*(list: PGSList, n: guint): gpointer{.cdecl,
    dynlib: gliblib, importc: "g_slist_nth_data".}
proc next*(slist: PGSList): PGSList
proc list_push_allocator*(allocator: PGAllocator){.cdecl, dynlib: gliblib,
    importc: "g_list_push_allocator".}
proc g_list_pop_allocator*(){.cdecl, dynlib: gliblib,
                              importc: "g_list_pop_allocator".}
proc g_list_alloc*(): PGList{.cdecl, dynlib: gliblib, importc: "g_list_alloc".}
proc free*(list: PGList){.cdecl, dynlib: gliblib, importc: "g_list_free".}
proc free_1*(list: PGList){.cdecl, dynlib: gliblib,
                                   importc: "g_list_free_1".}
proc append*(list: PGList, data: gpointer): PGList{.cdecl,
    dynlib: gliblib, importc: "g_list_append".}
proc prepend*(list: PGList, data: gpointer): PGList{.cdecl,
    dynlib: gliblib, importc: "g_list_prepend".}
proc insert*(list: PGList, data: gpointer, position: gint): PGList{.
    cdecl, dynlib: gliblib, importc: "g_list_insert".}
proc insert_sorted*(list: PGList, data: gpointer, func: TGCompareFunc): PGList{.
    cdecl, dynlib: gliblib, importc: "g_list_insert_sorted".}
proc insert_before*(list: PGList, sibling: PGList, data: gpointer): PGList{.
    cdecl, dynlib: gliblib, importc: "g_list_insert_before".}
proc concat*(list1: PGList, list2: PGList): PGList{.cdecl,
    dynlib: gliblib, importc: "g_list_concat".}
proc remove*(list: PGList, data: gconstpointer): PGList{.cdecl,
    dynlib: gliblib, importc: "g_list_remove".}
proc remove_all*(list: PGList, data: gconstpointer): PGList{.cdecl,
    dynlib: gliblib, importc: "g_list_remove_all".}
proc remove_link*(list: PGList, llink: PGList): PGList{.cdecl,
    dynlib: gliblib, importc: "g_list_remove_link".}
proc delete_link*(list: PGList, link: PGList): PGList{.cdecl,
    dynlib: gliblib, importc: "g_list_delete_link".}
proc reverse*(list: PGList): PGList{.cdecl, dynlib: gliblib,
    importc: "g_list_reverse".}
proc copy*(list: PGList): PGList{.cdecl, dynlib: gliblib,
    importc: "g_list_copy".}
proc nth*(list: PGList, n: guint): PGList{.cdecl, dynlib: gliblib,
    importc: "g_list_nth".}
proc nth_prev*(list: PGList, n: guint): PGList{.cdecl, dynlib: gliblib,
    importc: "g_list_nth_prev".}
proc find*(list: PGList, data: gconstpointer): PGList{.cdecl,
    dynlib: gliblib, importc: "g_list_find".}
proc find_custom*(list: PGList, data: gconstpointer, func: TGCompareFunc): PGList{.
    cdecl, dynlib: gliblib, importc: "g_list_find_custom".}
proc position*(list: PGList, llink: PGList): gint{.cdecl,
    dynlib: gliblib, importc: "g_list_position".}
proc index*(list: PGList, data: gconstpointer): gint{.cdecl,
    dynlib: gliblib, importc: "g_list_index".}
proc last*(list: PGList): PGList{.cdecl, dynlib: gliblib,
    importc: "g_list_last".}
proc first*(list: PGList): PGList{.cdecl, dynlib: gliblib,
    importc: "g_list_first".}
proc length*(list: PGList): guint{.cdecl, dynlib: gliblib,
    importc: "g_list_length".}
proc foreach*(list: PGList, func: TGFunc, user_data: gpointer){.cdecl,
    dynlib: gliblib, importc: "g_list_foreach".}
proc sort*(list: PGList, compare_func: TGCompareFunc): PGList{.cdecl,
    dynlib: gliblib, importc: "g_list_sort".}
proc sort*(list: PGList, compare_func: TGCompareDataFunc,
                            user_data: gpointer): PGList{.cdecl,
    dynlib: gliblib, importc: "g_list_sort_with_data".}
proc nth_data*(list: PGList, n: guint): gpointer{.cdecl, dynlib: gliblib,
    importc: "g_list_nth_data".}
proc previous*(list: PGList): PGList
proc next*(list: PGList): PGList
type
  PGCache* = pointer
  TGCacheNewFunc* = proc (key: gpointer): gpointer{.cdecl.}
  TGCacheDupFunc* = proc (value: gpointer): gpointer{.cdecl.}
  TGCacheDestroyFunc* = proc (value: gpointer){.cdecl.}

proc g_cache_new*(value_new_func: TGCacheNewFunc,
                  value_destroy_func: TGCacheDestroyFunc,
                  key_dup_func: TGCacheDupFunc,
                  key_destroy_func: TGCacheDestroyFunc,
                  hash_key_func: TGHashFunc, hash_value_func: TGHashFunc,
                  key_equal_func: TGEqualFunc): PGCache{.cdecl, dynlib: gliblib,
    importc: "g_cache_new".}
proc destroy*(cache: PGCache){.cdecl, dynlib: gliblib,
                                       importc: "g_cache_destroy".}
proc insert*(cache: PGCache, key: gpointer): gpointer{.cdecl,
    dynlib: gliblib, importc: "g_cache_insert".}
proc remove*(cache: PGCache, value: gconstpointer){.cdecl,
    dynlib: gliblib, importc: "g_cache_remove".}
proc key_foreach*(cache: PGCache, func: TGHFunc, user_data: gpointer){.
    cdecl, dynlib: gliblib, importc: "g_cache_key_foreach".}
proc value_foreach*(cache: PGCache, func: TGHFunc, user_data: gpointer){.
    cdecl, dynlib: gliblib, importc: "g_cache_value_foreach".}
type
  PGCompletionFunc* = ptr TGCompletionFunc
  TGCompletionFunc* = gchar
  TGCompletionStrncmpFunc* = proc (s1: cstring, s2: cstring, n: gsize): gint{.
      cdecl.}
  PGCompletion* = ptr TGCompletion
  TGCompletion*{.final.} = object
    items*: PGList
    func*: TGCompletionFunc
    prefix*: cstring
    cache*: PGList
    strncmp_func*: TGCompletionStrncmpFunc


proc g_completion_new*(func: TGCompletionFunc): PGCompletion{.cdecl,
    dynlib: gliblib, importc: "g_completion_new".}
proc add_items*(cmp: PGCompletion, items: PGList){.cdecl,
    dynlib: gliblib, importc: "g_completion_add_items".}
proc remove_items*(cmp: PGCompletion, items: PGList){.cdecl,
    dynlib: gliblib, importc: "g_completion_remove_items".}
proc clear_items*(cmp: PGCompletion){.cdecl, dynlib: gliblib,
    importc: "g_completion_clear_items".}
proc complete*(cmp: PGCompletion, prefix: cstring,
                            new_prefix: PPgchar): PGList{.cdecl,
    dynlib: gliblib, importc: "g_completion_complete".}
proc set_compare*(cmp: PGCompletion,
                               strncmp_func: TGCompletionStrncmpFunc){.cdecl,
    dynlib: gliblib, importc: "g_completion_set_compare".}
proc free*(cmp: PGCompletion){.cdecl, dynlib: gliblib,
    importc: "g_completion_free".}
type
  PGConvertError* = ptr TGConvertError
  TGConvertError* = enum
    G_CONVERT_ERROR_NO_CONVERSION, G_CONVERT_ERROR_ILLEGAL_SEQUENCE,
    G_CONVERT_ERROR_FAILED, G_CONVERT_ERROR_PARTIAL_INPUT,
    G_CONVERT_ERROR_BAD_URI, G_CONVERT_ERROR_NOT_ABSOLUTE_PATH

proc G_CONVERT_ERROR*(): TGQuark
proc g_convert_error_quark*(): TGQuark{.cdecl, dynlib: gliblib,
                                        importc: "g_convert_error_quark".}
type
  PGIConv* = ptr TGIConv
  TGIConv* = pointer

proc g_iconv_open*(to_codeset: cstring, from_codeset: cstring): TGIConv{.cdecl,
    dynlib: gliblib, importc: "g_iconv_open".}
proc g_iconv*(`converter`: TGIConv, inbuf: PPgchar, inbytes_left: Pgsize,
              outbuf: PPgchar, outbytes_left: Pgsize): gsize{.cdecl,
    dynlib: gliblib, importc: "g_iconv".}
proc g_iconv_close*(`converter`: TGIConv): gint{.cdecl, dynlib: gliblib,
    importc: "g_iconv_close".}
proc g_convert*(str: cstring, len: gssize, to_codeset: cstring,
                from_codeset: cstring, bytes_read: Pgsize,
                bytes_written: Pgsize, error: pointer): cstring{.cdecl,
    dynlib: gliblib, importc: "g_convert".}
proc g_convert*(str: cstring, len: gssize, `converter`: TGIConv,
                           bytes_read: Pgsize, bytes_written: Pgsize,
                           error: pointer): cstring{.cdecl, dynlib: gliblib,
    importc: "g_convert_with_iconv".}
proc g_convert*(str: cstring, len: gssize, to_codeset: cstring,
                              from_codeset: cstring, fallback: cstring,
                              bytes_read: Pgsize, bytes_written: Pgsize,
                              error: pointer): cstring{.cdecl, dynlib: gliblib,
    importc: "g_convert_with_fallback".}
proc g_locale_to_utf8*(opsysstring: cstring, len: gssize, bytes_read: Pgsize,
                       bytes_written: Pgsize, error: pointer): cstring{.cdecl,
    dynlib: gliblib, importc: "g_locale_to_utf8".}
proc g_locale_from_utf8*(utf8string: cstring, len: gssize, bytes_read: Pgsize,
                         bytes_written: Pgsize, error: pointer): cstring{.cdecl,
    dynlib: gliblib, importc: "g_locale_from_utf8".}
proc g_filename_to_utf8*(opsysstring: cstring, len: gssize, bytes_read: Pgsize,
                         bytes_written: Pgsize, error: pointer): cstring{.cdecl,
    dynlib: gliblib, importc: "g_filename_to_utf8".}
proc g_filename_from_utf8*(utf8string: cstring, len: gssize, bytes_read: Pgsize,
                           bytes_written: Pgsize, error: pointer): cstring{.
    cdecl, dynlib: gliblib, importc: "g_filename_from_utf8".}
proc g_filename_from_uri*(uri: cstring, hostname: PPchar, error: pointer): cstring{.
    cdecl, dynlib: gliblib, importc: "g_filename_from_uri".}
proc g_filename_to_uri*(filename: cstring, hostname: cstring, error: pointer): cstring{.
    cdecl, dynlib: gliblib, importc: "g_filename_to_uri".}
type
  TGDataForeachFunc* = proc (key_id: TGQuark, data: gpointer,
                             user_data: gpointer){.cdecl.}

proc g_datalist_init*(datalist: PPGData){.cdecl, dynlib: gliblib,
    importc: "g_datalist_init".}
proc g_datalist_clear*(datalist: PPGData){.cdecl, dynlib: gliblib,
    importc: "g_datalist_clear".}
proc g_datalist_id_get_data*(datalist: PPGData, key_id: TGQuark): gpointer{.
    cdecl, dynlib: gliblib, importc: "g_datalist_id_get_data".}
proc g_datalist_id_set_data_full*(datalist: PPGData, key_id: TGQuark,
                                  data: gpointer, destroy_func: TGDestroyNotify){.
    cdecl, dynlib: gliblib, importc: "g_datalist_id_set_data_full".}
proc g_datalist_id_remove_no_notify*(datalist: PPGData, key_id: TGQuark): gpointer{.
    cdecl, dynlib: gliblib, importc: "g_datalist_id_remove_no_notify".}
proc g_datalist_foreach*(datalist: PPGData, func: TGDataForeachFunc,
                         user_data: gpointer){.cdecl, dynlib: gliblib,
    importc: "g_datalist_foreach".}
proc g_datalist_id_set_data*(datalist: PPGData, key_id: TGQuark, data: gpointer)
proc g_datalist_id_remove_data*(datalist: PPGData, key_id: TGQuark)
proc g_datalist_get_data*(datalist: PPGData, key_str: cstring): PPGData
proc g_datalist_set_data_full*(datalist: PPGData, key_str: cstring,
                               data: gpointer, destroy_func: TGDestroyNotify)
proc g_datalist_set_data*(datalist: PPGData, key_str: cstring, data: gpointer)
proc g_datalist_remove_no_notify*(datalist: PPGData, key_str: cstring)
proc g_datalist_remove_data*(datalist: PPGData, key_str: cstring)
proc g_dataset_id_get_data*(dataset_location: gconstpointer, key_id: TGQuark): gpointer{.
    cdecl, dynlib: gliblib, importc: "g_dataset_id_get_data".}
proc g_dataset_id_set_data_full*(dataset_location: gconstpointer,
                                 key_id: TGQuark, data: gpointer,
                                 destroy_func: TGDestroyNotify){.cdecl,
    dynlib: gliblib, importc: "g_dataset_id_set_data_full".}
proc g_dataset_id_remove_no_notify*(dataset_location: gconstpointer,
                                    key_id: TGQuark): gpointer{.cdecl,
    dynlib: gliblib, importc: "g_dataset_id_remove_no_notify".}
proc g_dataset_foreach*(dataset_location: gconstpointer,
                        func: TGDataForeachFunc, user_data: gpointer){.cdecl,
    dynlib: gliblib, importc: "g_dataset_foreach".}
proc g_dataset_id_set_data*(location: gconstpointer, key_id: TGQuark,
                            data: gpointer)
proc g_dataset_id_remove_data*(location: gconstpointer, key_id: TGQuark)
proc g_dataset_get_data*(location: gconstpointer, key_str: cstring): gpointer
proc g_dataset_set_data_full*(location: gconstpointer, key_str: cstring,
                              data: gpointer, destroy_func: TGDestroyNotify)
proc g_dataset_remove_no_notify*(location: gconstpointer, key_str: cstring)
proc g_dataset_set_data*(location: gconstpointer, key_str: cstring,
                         data: gpointer)
proc g_dataset_remove_data*(location: gconstpointer, key_str: cstring)
type
  PGTime* = ptr TGTime
  TGTime* = gint32
  PGDateYear* = ptr TGDateYear
  TGDateYear* = guint16
  PGDateDay* = ptr TGDateDay
  TGDateDay* = guint8
  Ptm* = ptr Ttm
  Ttm*{.final.} = object
    tm_sec*: gint
    tm_min*: gint
    tm_hour*: gint
    tm_mday*: gint
    tm_mon*: gint
    tm_year*: gint
    tm_wday*: gint
    tm_yday*: gint
    tm_isdst*: gint
    tm_gmtoff*: glong
    tm_zone*: cstring


type
  PGDateDMY* = ptr TGDateDMY
  TGDateDMY* = int

const
  G_DATE_DAY* = 0
  G_DATE_MONTH* = 1
  G_DATE_YEAR* = 2

type
  PGDateWeekday* = ptr TGDateWeekday
  TGDateWeekday* = int

const
  G_DATE_BAD_WEEKDAY* = 0
  G_DATE_MONDAY* = 1
  G_DATE_TUESDAY* = 2
  G_DATE_WEDNESDAY* = 3
  G_DATE_THURSDAY* = 4
  G_DATE_FRIDAY* = 5
  G_DATE_SATURDAY* = 6
  G_DATE_SUNDAY* = 7

type
  PGDateMonth* = ptr TGDateMonth
  TGDateMonth* = int

const
  G_DATE_BAD_MONTH* = 0
  G_DATE_JANUARY* = 1
  G_DATE_FEBRUARY* = 2
  G_DATE_MARCH* = 3
  G_DATE_APRIL* = 4
  G_DATE_MAY* = 5
  G_DATE_JUNE* = 6
  G_DATE_JULY* = 7
  G_DATE_AUGUST* = 8
  G_DATE_SEPTEMBER* = 9
  G_DATE_OCTOBER* = 10
  G_DATE_NOVEMBER* = 11
  G_DATE_DECEMBER* = 12

const
  G_DATE_BAD_JULIAN* = 0
  G_DATE_BAD_DAY* = 0
  G_DATE_BAD_YEAR* = 0

type
  PGDate* = ptr TGDate
  TGDate*{.final.} = object
    flag0*: int32
    flag1*: int32


proc g_date_new*(): PGDate{.cdecl, dynlib: gliblib, importc: "g_date_new".}
proc g_date_new_dmy*(day: TGDateDay, month: TGDateMonth, year: TGDateYear): PGDate{.
    cdecl, dynlib: gliblib, importc: "g_date_new_dmy".}
proc g_date_new_julian*(julian_day: guint32): PGDate{.cdecl, dynlib: gliblib,
    importc: "g_date_new_julian".}
proc free*(date: PGDate){.cdecl, dynlib: gliblib, importc: "g_date_free".}
proc valid*(date: PGDate): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_date_valid".}
proc g_date_valid_month*(month: TGDateMonth): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_date_valid_month".}
proc g_date_valid_year*(year: TGDateYear): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_date_valid_year".}
proc g_date_valid_weekday*(weekday: TGDateWeekday): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_date_valid_weekday".}
proc g_date_valid_julian*(julian_date: guint32): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_date_valid_julian".}
proc get_weekday*(date: PGDate): TGDateWeekday{.cdecl, dynlib: gliblib,
    importc: "g_date_get_weekday".}
proc get_month*(date: PGDate): TGDateMonth{.cdecl, dynlib: gliblib,
    importc: "g_date_get_month".}
proc get_year*(date: PGDate): TGDateYear{.cdecl, dynlib: gliblib,
    importc: "g_date_get_year".}
proc get_day*(date: PGDate): TGDateDay{.cdecl, dynlib: gliblib,
    importc: "g_date_get_day".}
proc get_julian*(date: PGDate): guint32{.cdecl, dynlib: gliblib,
    importc: "g_date_get_julian".}
proc get_day_of_year*(date: PGDate): guint{.cdecl, dynlib: gliblib,
    importc: "g_date_get_day_of_year".}
proc get_monday_week_of_year*(date: PGDate): guint{.cdecl,
    dynlib: gliblib, importc: "g_date_get_monday_week_of_year".}
proc get_sunday_week_of_year*(date: PGDate): guint{.cdecl,
    dynlib: gliblib, importc: "g_date_get_sunday_week_of_year".}
proc clear*(date: PGDate, n_dates: guint){.cdecl, dynlib: gliblib,
    importc: "g_date_clear".}
proc set_parse*(date: PGDate, str: cstring){.cdecl, dynlib: gliblib,
    importc: "g_date_set_parse".}
proc set_time*(date: PGDate, time: TGTime){.cdecl, dynlib: gliblib,
    importc: "g_date_set_time".}
proc set_month*(date: PGDate, month: TGDateMonth){.cdecl,
    dynlib: gliblib, importc: "g_date_set_month".}
proc set_day*(date: PGDate, day: TGDateDay){.cdecl, dynlib: gliblib,
    importc: "g_date_set_day".}
proc set_year*(date: PGDate, year: TGDateYear){.cdecl, dynlib: gliblib,
    importc: "g_date_set_year".}
proc set_dmy*(date: PGDate, day: TGDateDay, month: TGDateMonth,
                     y: TGDateYear){.cdecl, dynlib: gliblib,
                                     importc: "g_date_set_dmy".}
proc set_julian*(date: PGDate, julian_date: guint32){.cdecl,
    dynlib: gliblib, importc: "g_date_set_julian".}
proc is_first_of_month*(date: PGDate): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_date_is_first_of_month".}
proc is_last_of_month*(date: PGDate): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_date_is_last_of_month".}
proc add_days*(date: PGDate, n_days: guint){.cdecl, dynlib: gliblib,
    importc: "g_date_add_days".}
proc subtract_days*(date: PGDate, n_days: guint){.cdecl, dynlib: gliblib,
    importc: "g_date_subtract_days".}
proc add_months*(date: PGDate, n_months: guint){.cdecl, dynlib: gliblib,
    importc: "g_date_add_months".}
proc subtract_months*(date: PGDate, n_months: guint){.cdecl,
    dynlib: gliblib, importc: "g_date_subtract_months".}
proc add_years*(date: PGDate, n_years: guint){.cdecl, dynlib: gliblib,
    importc: "g_date_add_years".}
proc subtract_years*(date: PGDate, n_years: guint){.cdecl,
    dynlib: gliblib, importc: "g_date_subtract_years".}
proc g_date_is_leap_year*(year: TGDateYear): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_date_is_leap_year".}
proc g_date_get_days_in_month*(month: TGDateMonth, year: TGDateYear): guint8{.
    cdecl, dynlib: gliblib, importc: "g_date_get_days_in_month".}
proc g_date_get_monday_weeks_in_year*(year: TGDateYear): guint8{.cdecl,
    dynlib: gliblib, importc: "g_date_get_monday_weeks_in_year".}
proc g_date_get_sunday_weeks_in_year*(year: TGDateYear): guint8{.cdecl,
    dynlib: gliblib, importc: "g_date_get_sunday_weeks_in_year".}
proc days_between*(date1: PGDate, date2: PGDate): gint{.cdecl,
    dynlib: gliblib, importc: "g_date_days_between".}
proc compare*(lhs: PGDate, rhs: PGDate): gint{.cdecl, dynlib: gliblib,
    importc: "g_date_compare".}
proc to_struct_tm*(date: PGDate, tm: Ptm){.cdecl, dynlib: gliblib,
    importc: "g_date_to_struct_tm".}
proc clamp*(date: PGDate, min_date: PGDate, max_date: PGDate){.cdecl,
    dynlib: gliblib, importc: "g_date_clamp".}
proc order*(date1: PGDate, date2: PGDate){.cdecl, dynlib: gliblib,
    importc: "g_date_order".}
proc g_date_strftime*(s: cstring, slen: gsize, format: cstring, date: PGDate): gsize{.
    cdecl, dynlib: gliblib, importc: "g_date_strftime".}
type
  PGDir* = pointer

proc g_dir_open*(path: cstring, flags: guint, error: pointer): PGDir{.cdecl,
    dynlib: gliblib, importc: "g_dir_open".}
proc read_name*(dir: PGDir): cstring{.cdecl, dynlib: gliblib,
    importc: "g_dir_read_name".}
proc rewind*(dir: PGDir){.cdecl, dynlib: gliblib, importc: "g_dir_rewind".}
proc close*(dir: PGDir){.cdecl, dynlib: gliblib, importc: "g_dir_close".}
type
  PGFileError* = ptr TGFileError
  TGFileError* = gint

type
  PGFileTest* = ptr TGFileTest
  TGFileTest* = int

const
  G_FILE_TEST_IS_REGULAR* = 1 shl 0
  G_FILE_TEST_IS_SYMLINK* = 1 shl 1
  G_FILE_TEST_IS_DIR* = 1 shl 2
  G_FILE_TEST_IS_EXECUTABLE* = 1 shl 3
  G_FILE_TEST_EXISTS* = 1 shl 4

const
  G_FILE_ERROR_EXIST* = 0
  G_FILE_ERROR_ISDIR* = 1
  G_FILE_ERROR_ACCES* = 2
  G_FILE_ERROR_NAMETOOLONG* = 3
  G_FILE_ERROR_NOENT* = 4
  G_FILE_ERROR_NOTDIR* = 5
  G_FILE_ERROR_NXIO* = 6
  G_FILE_ERROR_NODEV* = 7
  G_FILE_ERROR_ROFS* = 8
  G_FILE_ERROR_TXTBSY* = 9
  G_FILE_ERROR_FAULT* = 10
  G_FILE_ERROR_LOOP* = 11
  G_FILE_ERROR_NOSPC* = 12
  G_FILE_ERROR_NOMEM* = 13
  G_FILE_ERROR_MFILE* = 14
  G_FILE_ERROR_NFILE* = 15
  G_FILE_ERROR_BADF* = 16
  G_FILE_ERROR_INVAL* = 17
  G_FILE_ERROR_PIPE* = 18
  G_FILE_ERROR_AGAIN* = 19
  G_FILE_ERROR_INTR* = 20
  G_FILE_ERROR_IO* = 21
  G_FILE_ERROR_PERM* = 22
  G_FILE_ERROR_FAILED* = 23

proc G_FILE_ERROR*(): TGQuark
proc g_file_error_quark*(): TGQuark{.cdecl, dynlib: gliblib,
                                     importc: "g_file_error_quark".}
proc g_file_error_from_errno*(err_no: gint): TGFileError{.cdecl,
    dynlib: gliblib, importc: "g_file_error_from_errno".}
proc g_file_test*(filename: cstring, test: TGFileTest): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_file_test".}
proc g_file_get_contents*(filename: cstring, contents: PPgchar, length: Pgsize,
                          error: pointer): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_file_get_contents".}
proc g_mkstemp*(tmpl: cstring): int32{.cdecl, dynlib: gliblib,
                                       importc: "g_mkstemp".}
proc g_file_open_tmp*(tmpl: cstring, name_used: PPchar, error: pointer): int32{.
    cdecl, dynlib: gliblib, importc: "g_file_open_tmp".}
type
  PGHook* = ptr TGHook
  TGHook*{.final.} = object
    data*: gpointer
    next*: PGHook
    prev*: PGHook
    ref_count*: guint
    hook_id*: gulong
    flags*: guint
    func*: gpointer
    destroy*: TGDestroyNotify

  PGHookList* = ptr TGHookList
  TGHookCompareFunc* = proc (new_hook: PGHook, sibling: PGHook): gint{.cdecl.}
  TGHookFindFunc* = proc (hook: PGHook, data: gpointer): gboolean{.cdecl.}
  TGHookMarshaller* = proc (hook: PGHook, marshal_data: gpointer){.cdecl.}
  TGHookCheckMarshaller* = proc (hook: PGHook, marshal_data: gpointer): gboolean{.
      cdecl.}
  TGHookFunc* = proc (data: gpointer){.cdecl.}
  TGHookCheckFunc* = proc (data: gpointer): gboolean{.cdecl.}
  TGHookFinalizeFunc* = proc (hook_list: PGHookList, hook: PGHook){.cdecl.}
  TGHookList*{.final.} = object
    seq_id*: gulong
    flag0*: int32
    hooks*: PGHook
    hook_memchunk*: PGMemChunk
    finalize_hook*: TGHookFinalizeFunc
    dummy*: array[0..1, gpointer]


type
  PGHookFlagMask* = ptr TGHookFlagMask
  TGHookFlagMask* = int

const
  G_HOOK_FLAG_ACTIVE* = 1'i32 shl 0'i32
  G_HOOK_FLAG_IN_CALL* = 1'i32 shl 1'i32
  G_HOOK_FLAG_MASK* = 0x0000000F'i32

const
  G_HOOK_FLAG_USER_SHIFT* = 4'i32
  bm_TGHookList_hook_size* = 0x0000FFFF'i32
  bp_TGHookList_hook_size* = 0'i32
  bm_TGHookList_is_setup* = 0x00010000'i32
  bp_TGHookList_is_setup* = 16'i32

proc TGHookList_hook_size*(a: PGHookList): guint
proc TGHookList_set_hook_size*(a: PGHookList, `hook_size`: guint)
proc TGHookList_is_setup*(a: PGHookList): guint
proc TGHookList_set_is_setup*(a: PGHookList, `is_setup`: guint)
proc G_HOOK*(hook: pointer): PGHook
proc FLAGS*(hook: PGHook): guint
proc ACTIVE*(hook: PGHook): bool
proc IN_CALL*(hook: PGHook): bool
proc IS_VALID*(hook: PGHook): bool
proc IS_UNLINKED*(hook: PGHook): bool
proc list_init*(hook_list: PGHookList, hook_size: guint){.cdecl,
    dynlib: gliblib, importc: "g_hook_list_init".}
proc list_clear*(hook_list: PGHookList){.cdecl, dynlib: gliblib,
    importc: "g_hook_list_clear".}
proc alloc*(hook_list: PGHookList): PGHook{.cdecl, dynlib: gliblib,
    importc: "g_hook_alloc".}
proc free*(hook_list: PGHookList, hook: PGHook){.cdecl, dynlib: gliblib,
    importc: "g_hook_free".}
proc reference*(hook_list: PGHookList, hook: PGHook){.cdecl, dynlib: gliblib,
    importc: "g_hook_ref".}
proc unref*(hook_list: PGHookList, hook: PGHook){.cdecl, dynlib: gliblib,
    importc: "g_hook_unref".}
proc destroy*(hook_list: PGHookList, hook_id: gulong): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_hook_destroy".}
proc destroy_link*(hook_list: PGHookList, hook: PGHook){.cdecl,
    dynlib: gliblib, importc: "g_hook_destroy_link".}
proc prepend*(hook_list: PGHookList, hook: PGHook){.cdecl,
    dynlib: gliblib, importc: "g_hook_prepend".}
proc insert_before*(hook_list: PGHookList, sibling: PGHook, hook: PGHook){.
    cdecl, dynlib: gliblib, importc: "g_hook_insert_before".}
proc insert_sorted*(hook_list: PGHookList, hook: PGHook,
                           func: TGHookCompareFunc){.cdecl, dynlib: gliblib,
    importc: "g_hook_insert_sorted".}
proc get*(hook_list: PGHookList, hook_id: gulong): PGHook{.cdecl,
    dynlib: gliblib, importc: "g_hook_get".}
proc find*(hook_list: PGHookList, need_valids: gboolean,
                  func: TGHookFindFunc, data: gpointer): PGHook{.cdecl,
    dynlib: gliblib, importc: "g_hook_find".}
proc find_data*(hook_list: PGHookList, need_valids: gboolean,
                       data: gpointer): PGHook{.cdecl, dynlib: gliblib,
    importc: "g_hook_find_data".}
proc find_func*(hook_list: PGHookList, need_valids: gboolean,
                       func: gpointer): PGHook{.cdecl, dynlib: gliblib,
    importc: "g_hook_find_func".}
proc find_func_data*(hook_list: PGHookList, need_valids: gboolean,
                            func: gpointer, data: gpointer): PGHook{.cdecl,
    dynlib: gliblib, importc: "g_hook_find_func_data".}
proc first_valid*(hook_list: PGHookList, may_be_in_call: gboolean): PGHook{.
    cdecl, dynlib: gliblib, importc: "g_hook_first_valid".}
proc next_valid*(hook_list: PGHookList, hook: PGHook,
                        may_be_in_call: gboolean): PGHook{.cdecl,
    dynlib: gliblib, importc: "g_hook_next_valid".}
proc compare_ids*(new_hook: PGHook, sibling: PGHook): gint{.cdecl,
    dynlib: gliblib, importc: "g_hook_compare_ids".}
proc append*(hook_list: PGHookList, hook: PGHook)
proc list_invoke_check*(hook_list: PGHookList, may_recurse: gboolean){.
    cdecl, dynlib: gliblib, importc: "g_hook_list_invoke_check".}
proc list_marshal*(hook_list: PGHookList, may_recurse: gboolean,
                          marshaller: TGHookMarshaller, marshal_data: gpointer){.
    cdecl, dynlib: gliblib, importc: "g_hook_list_marshal".}
proc list_marshal_check*(hook_list: PGHookList, may_recurse: gboolean,
                                marshaller: TGHookCheckMarshaller,
                                marshal_data: gpointer){.cdecl, dynlib: gliblib,
    importc: "g_hook_list_marshal_check".}
type
  PGThreadPool* = ptr TGThreadPool
  TGThreadPool*{.final.} = object
    func*: TGFunc
    user_data*: gpointer
    exclusive*: gboolean


proc g_thread_pool_new*(func: TGFunc, user_data: gpointer, max_threads: gint,
                        exclusive: gboolean, error: pointer): PGThreadPool{.
    cdecl, dynlib: gliblib, importc: "g_thread_pool_new".}
proc pool_push*(pool: PGThreadPool, data: gpointer, error: pointer){.
    cdecl, dynlib: gliblib, importc: "g_thread_pool_push".}
proc pool_set_max_threads*(pool: PGThreadPool, max_threads: gint,
                                    error: pointer){.cdecl, dynlib: gliblib,
    importc: "g_thread_pool_set_max_threads".}
proc pool_get_max_threads*(pool: PGThreadPool): gint{.cdecl,
    dynlib: gliblib, importc: "g_thread_pool_get_max_threads".}
proc pool_get_num_threads*(pool: PGThreadPool): guint{.cdecl,
    dynlib: gliblib, importc: "g_thread_pool_get_num_threads".}
proc pool_unprocessed*(pool: PGThreadPool): guint{.cdecl,
    dynlib: gliblib, importc: "g_thread_pool_unprocessed".}
proc pool_free*(pool: PGThreadPool, immediate: gboolean, wait: gboolean){.
    cdecl, dynlib: gliblib, importc: "g_thread_pool_free".}
proc g_thread_pool_set_max_unused_threads*(max_threads: gint){.cdecl,
    dynlib: gliblib, importc: "g_thread_pool_set_max_unused_threads".}
proc g_thread_pool_get_max_unused_threads*(): gint{.cdecl, dynlib: gliblib,
    importc: "g_thread_pool_get_max_unused_threads".}
proc g_thread_pool_get_num_unused_threads*(): guint{.cdecl, dynlib: gliblib,
    importc: "g_thread_pool_get_num_unused_threads".}
proc g_thread_pool_stop_unused_threads*(){.cdecl, dynlib: gliblib,
    importc: "g_thread_pool_stop_unused_threads".}
type
  PGTimer* = pointer

const
  G_USEC_PER_SEC* = 1000000

proc g_timer_new*(): PGTimer{.cdecl, dynlib: gliblib, importc: "g_timer_new".}
proc destroy*(timer: PGTimer){.cdecl, dynlib: gliblib,
                                       importc: "g_timer_destroy".}
proc start*(timer: PGTimer){.cdecl, dynlib: gliblib,
                                     importc: "g_timer_start".}
proc stop*(timer: PGTimer){.cdecl, dynlib: gliblib,
                                    importc: "g_timer_stop".}
proc reset*(timer: PGTimer){.cdecl, dynlib: gliblib,
                                     importc: "g_timer_reset".}
proc elapsed*(timer: PGTimer, microseconds: Pgulong): gdouble{.cdecl,
    dynlib: gliblib, importc: "g_timer_elapsed".}
proc g_usleep*(microseconds: gulong){.cdecl, dynlib: gliblib,
                                      importc: "g_usleep".}
proc val_add*(time: PGTimeVal, microseconds: glong){.cdecl,
    dynlib: gliblib, importc: "g_time_val_add".}
type
  Pgunichar* = ptr gunichar
  gunichar* = guint32
  Pgunichar2* = ptr gunichar2
  gunichar2* = guint16
  PGUnicodeType* = ptr TGUnicodeType
  TGUnicodeType* = enum
    G_UNICODE_CONTROL, G_UNICODE_FORMAT, G_UNICODE_UNASSIGNED,
    G_UNICODE_PRIVATE_USE, G_UNICODE_SURROGATE, G_UNICODE_LOWERCASE_LETTER,
    G_UNICODE_MODIFIER_LETTER, G_UNICODE_OTHER_LETTER,
    G_UNICODE_TITLECASE_LETTER, G_UNICODE_UPPERCASE_LETTER,
    G_UNICODE_COMBINING_MARK, G_UNICODE_ENCLOSING_MARK,
    G_UNICODE_NON_SPACING_MARK, G_UNICODE_DECIMAL_NUMBER,
    G_UNICODE_LETTER_NUMBER, G_UNICODE_OTHER_NUMBER,
    G_UNICODE_CONNECT_PUNCTUATION, G_UNICODE_DASH_PUNCTUATION,
    G_UNICODE_CLOSE_PUNCTUATION, G_UNICODE_FINAL_PUNCTUATION,
    G_UNICODE_INITIAL_PUNCTUATION, G_UNICODE_OTHER_PUNCTUATION,
    G_UNICODE_OPEN_PUNCTUATION, G_UNICODE_CURRENCY_SYMBOL,
    G_UNICODE_MODIFIER_SYMBOL, G_UNICODE_MATH_SYMBOL, G_UNICODE_OTHER_SYMBOL,
    G_UNICODE_LINE_SEPARATOR, G_UNICODE_PARAGRAPH_SEPARATOR,
    G_UNICODE_SPACE_SEPARATOR
  PGUnicodeBreakType* = ptr TGUnicodeBreakType
  TGUnicodeBreakType* = enum
    G_UNICODE_BREAK_MANDATORY, G_UNICODE_BREAK_CARRIAGE_RETURN,
    G_UNICODE_BREAK_LINE_FEED, G_UNICODE_BREAK_COMBINING_MARK,
    G_UNICODE_BREAK_SURROGATE, G_UNICODE_BREAK_ZERO_WIDTH_SPACE,
    G_UNICODE_BREAK_INSEPARABLE, G_UNICODE_BREAK_NON_BREAKING_GLUE,
    G_UNICODE_BREAK_CONTINGENT, G_UNICODE_BREAK_SPACE, G_UNICODE_BREAK_AFTER,
    G_UNICODE_BREAK_BEFORE, G_UNICODE_BREAK_BEFORE_AND_AFTER,
    G_UNICODE_BREAK_HYPHEN, G_UNICODE_BREAK_NON_STARTER,
    G_UNICODE_BREAK_OPEN_PUNCTUATION, G_UNICODE_BREAK_CLOSE_PUNCTUATION,
    G_UNICODE_BREAK_QUOTATION, G_UNICODE_BREAK_EXCLAMATION,
    G_UNICODE_BREAK_IDEOGRAPHIC, G_UNICODE_BREAK_NUMERIC,
    G_UNICODE_BREAK_INFIX_SEPARATOR, G_UNICODE_BREAK_SYMBOL,
    G_UNICODE_BREAK_ALPHABETIC, G_UNICODE_BREAK_PREFIX, G_UNICODE_BREAK_POSTFIX,
    G_UNICODE_BREAK_COMPLEX_CONTEXT, G_UNICODE_BREAK_AMBIGUOUS,
    G_UNICODE_BREAK_UNKNOWN

proc g_get_charset*(charset: PPchar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_get_charset".}
proc g_unichar_isalnum*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_isalnum".}
proc g_unichar_isalpha*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_isalpha".}
proc g_unichar_iscntrl*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_iscntrl".}
proc g_unichar_isdigit*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_isdigit".}
proc g_unichar_isgraph*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_isgraph".}
proc g_unichar_islower*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_islower".}
proc g_unichar_isprint*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_isprint".}
proc g_unichar_ispunct*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_ispunct".}
proc g_unichar_isspace*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_isspace".}
proc g_unichar_isupper*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_isupper".}
proc g_unichar_isxdigit*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_isxdigit".}
proc g_unichar_istitle*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_istitle".}
proc g_unichar_isdefined*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_isdefined".}
proc g_unichar_iswide*(c: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_iswide".}
proc g_unichar_toupper*(c: gunichar): gunichar{.cdecl, dynlib: gliblib,
    importc: "g_unichar_toupper".}
proc g_unichar_tolower*(c: gunichar): gunichar{.cdecl, dynlib: gliblib,
    importc: "g_unichar_tolower".}
proc g_unichar_totitle*(c: gunichar): gunichar{.cdecl, dynlib: gliblib,
    importc: "g_unichar_totitle".}
proc g_unichar_digit_value*(c: gunichar): gint{.cdecl, dynlib: gliblib,
    importc: "g_unichar_digit_value".}
proc g_unichar_xdigit_value*(c: gunichar): gint{.cdecl, dynlib: gliblib,
    importc: "g_unichar_xdigit_value".}
proc g_unichar_type*(c: gunichar): TGUnicodeType{.cdecl, dynlib: gliblib,
    importc: "g_unichar_type".}
proc g_unichar_break_type*(c: gunichar): TGUnicodeBreakType{.cdecl,
    dynlib: gliblib, importc: "g_unichar_break_type".}
proc unicode_canonical_ordering*(str: Pgunichar, len: gsize){.cdecl,
    dynlib: gliblib, importc: "g_unicode_canonical_ordering".}
proc g_unicode_canonical_decomposition*(ch: gunichar, result_len: Pgsize): Pgunichar{.
    cdecl, dynlib: gliblib, importc: "g_unicode_canonical_decomposition".}
proc utf8_next_char*(p: pguchar): pguchar
proc g_utf8_get_char*(p: cstring): gunichar{.cdecl, dynlib: gliblib,
    importc: "g_utf8_get_char".}
proc g_utf8_get_char_validated*(p: cstring, max_len: gssize): gunichar{.cdecl,
    dynlib: gliblib, importc: "g_utf8_get_char_validated".}
proc g_utf8_offset_to_pointer*(str: cstring, offset: glong): cstring{.cdecl,
    dynlib: gliblib, importc: "g_utf8_offset_to_pointer".}
proc g_utf8_pointer_to_offset*(str: cstring, pos: cstring): glong{.cdecl,
    dynlib: gliblib, importc: "g_utf8_pointer_to_offset".}
proc g_utf8_prev_char*(p: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_utf8_prev_char".}
proc g_utf8_find_next_char*(p: cstring, `end`: cstring): cstring{.cdecl,
    dynlib: gliblib, importc: "g_utf8_find_next_char".}
proc g_utf8_find_prev_char*(str: cstring, p: cstring): cstring{.cdecl,
    dynlib: gliblib, importc: "g_utf8_find_prev_char".}
proc g_utf8_strlen*(p: cstring, max: gssize): glong{.cdecl, dynlib: gliblib,
    importc: "g_utf8_strlen".}
proc g_utf8_strncpy*(dest: cstring, src: cstring, n: gsize): cstring{.cdecl,
    dynlib: gliblib, importc: "g_utf8_strncpy".}
proc g_utf8_strchr*(p: cstring, len: gssize, c: gunichar): cstring{.cdecl,
    dynlib: gliblib, importc: "g_utf8_strchr".}
proc g_utf8_strrchr*(p: cstring, len: gssize, c: gunichar): cstring{.cdecl,
    dynlib: gliblib, importc: "g_utf8_strrchr".}
proc g_utf8_to_utf16*(str: cstring, len: glong, items_read: Pglong,
                      items_written: Pglong, error: pointer): Pgunichar2{.cdecl,
    dynlib: gliblib, importc: "g_utf8_to_utf16".}
proc g_utf8_to_ucs4*(str: cstring, len: glong, items_read: Pglong,
                     items_written: Pglong, error: pointer): Pgunichar{.cdecl,
    dynlib: gliblib, importc: "g_utf8_to_ucs4".}
proc g_utf8_to_ucs4_fast*(str: cstring, len: glong, items_written: Pglong): Pgunichar{.
    cdecl, dynlib: gliblib, importc: "g_utf8_to_ucs4_fast".}
proc utf16_to_ucs4*(str: Pgunichar2, len: glong, items_read: Pglong,
                      items_written: Pglong, error: pointer): Pgunichar{.cdecl,
    dynlib: gliblib, importc: "g_utf16_to_ucs4".}
proc utf16_to_utf8*(str: Pgunichar2, len: glong, items_read: Pglong,
                      items_written: Pglong, error: pointer): cstring{.cdecl,
    dynlib: gliblib, importc: "g_utf16_to_utf8".}
proc ucs4_to_utf16*(str: Pgunichar, len: glong, items_read: Pglong,
                      items_written: Pglong, error: pointer): Pgunichar2{.cdecl,
    dynlib: gliblib, importc: "g_ucs4_to_utf16".}
proc ucs4_to_utf8*(str: Pgunichar, len: glong, items_read: Pglong,
                     items_written: Pglong, error: pointer): cstring{.cdecl,
    dynlib: gliblib, importc: "g_ucs4_to_utf8".}
proc g_unichar_to_utf8*(c: gunichar, outbuf: cstring): gint{.cdecl,
    dynlib: gliblib, importc: "g_unichar_to_utf8".}
proc g_utf8_validate*(str: cstring, max_len: gssize, `end`: PPgchar): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_utf8_validate".}
proc g_unichar_validate*(ch: gunichar): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_unichar_validate".}
proc g_utf8_strup*(str: cstring, len: gssize): cstring{.cdecl, dynlib: gliblib,
    importc: "g_utf8_strup".}
proc g_utf8_strdown*(str: cstring, len: gssize): cstring{.cdecl,
    dynlib: gliblib, importc: "g_utf8_strdown".}
proc g_utf8_casefold*(str: cstring, len: gssize): cstring{.cdecl,
    dynlib: gliblib, importc: "g_utf8_casefold".}
type
  PGNormalizeMode* = ptr TGNormalizeMode
  TGNormalizeMode* = gint

const
  G_NORMALIZE_DEFAULT* = 0
  G_NORMALIZE_NFD* = G_NORMALIZE_DEFAULT
  G_NORMALIZE_DEFAULT_COMPOSE* = 1
  G_NORMALIZE_NFC* = G_NORMALIZE_DEFAULT_COMPOSE
  G_NORMALIZE_ALL* = 2
  G_NORMALIZE_NFKD* = G_NORMALIZE_ALL
  G_NORMALIZE_ALL_COMPOSE* = 3
  G_NORMALIZE_NFKC* = G_NORMALIZE_ALL_COMPOSE

proc g_utf8_normalize*(str: cstring, len: gssize, mode: TGNormalizeMode): cstring{.
    cdecl, dynlib: gliblib, importc: "g_utf8_normalize".}
proc g_utf8_collate*(str1: cstring, str2: cstring): gint{.cdecl,
    dynlib: gliblib, importc: "g_utf8_collate".}
proc g_utf8_collate_key*(str: cstring, len: gssize): cstring{.cdecl,
    dynlib: gliblib, importc: "g_utf8_collate_key".}
type
  PGString* = ptr TGString
  TGString*{.final.} = object
    str*: cstring
    len*: gsize
    allocated_len*: gsize

  PGStringChunk* = pointer

proc g_string_chunk_new*(size: gsize): PGStringChunk{.cdecl, dynlib: gliblib,
    importc: "g_string_chunk_new".}
proc chunk_free*(chunk: PGStringChunk){.cdecl, dynlib: gliblib,
    importc: "g_string_chunk_free".}
proc chunk_insert*(chunk: PGStringChunk, str: cstring): cstring{.cdecl,
    dynlib: gliblib, importc: "g_string_chunk_insert".}
proc chunk_insert_const*(chunk: PGStringChunk, str: cstring): cstring{.
    cdecl, dynlib: gliblib, importc: "g_string_chunk_insert_const".}
proc g_string_new*(init: cstring): PGString{.cdecl, dynlib: gliblib,
    importc: "g_string_new".}
proc g_string_new_len*(init: cstring, len: gssize): PGString{.cdecl,
    dynlib: gliblib, importc: "g_string_new_len".}
proc g_string_sized_new*(dfl_size: gsize): PGString{.cdecl, dynlib: gliblib,
    importc: "g_string_sized_new".}
proc free*(str: PGString, free_segment: gboolean): cstring{.cdecl,
    dynlib: gliblib, importc: "g_string_free".}
proc equal*(v: PGString, v2: PGString): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_string_equal".}
proc hash*(str: PGString): guint{.cdecl, dynlib: gliblib,
    importc: "g_string_hash".}
proc assign*(str: PGString, rval: cstring): PGString{.cdecl,
    dynlib: gliblib, importc: "g_string_assign".}
proc truncate*(str: PGString, len: gsize): PGString{.cdecl,
    dynlib: gliblib, importc: "g_string_truncate".}
proc set_size*(str: PGString, len: gsize): PGString{.cdecl,
    dynlib: gliblib, importc: "g_string_set_size".}
proc insert_len*(str: PGString, pos: gssize, val: cstring, len: gssize): PGString{.
    cdecl, dynlib: gliblib, importc: "g_string_insert_len".}
proc append*(str: PGString, val: cstring): PGString{.cdecl,
    dynlib: gliblib, importc: "g_string_append".}
proc append_len*(str: PGString, val: cstring, len: gssize): PGString{.
    cdecl, dynlib: gliblib, importc: "g_string_append_len".}
proc append_c*(str: PGString, c: gchar): PGString{.cdecl,
    dynlib: gliblib, importc: "g_string_append_c".}
proc append_unichar*(str: PGString, wc: gunichar): PGString{.cdecl,
    dynlib: gliblib, importc: "g_string_append_unichar".}
proc prepend*(str: PGString, val: cstring): PGString{.cdecl,
    dynlib: gliblib, importc: "g_string_prepend".}
proc prepend_c*(str: PGString, c: gchar): PGString{.cdecl,
    dynlib: gliblib, importc: "g_string_prepend_c".}
proc prepend_unichar*(str: PGString, wc: gunichar): PGString{.cdecl,
    dynlib: gliblib, importc: "g_string_prepend_unichar".}
proc prepend_len*(str: PGString, val: cstring, len: gssize): PGString{.
    cdecl, dynlib: gliblib, importc: "g_string_prepend_len".}
proc insert*(str: PGString, pos: gssize, val: cstring): PGString{.
    cdecl, dynlib: gliblib, importc: "g_string_insert".}
proc insert_c*(str: PGString, pos: gssize, c: gchar): PGString{.cdecl,
    dynlib: gliblib, importc: "g_string_insert_c".}
proc insert_unichar*(str: PGString, pos: gssize, wc: gunichar): PGString{.
    cdecl, dynlib: gliblib, importc: "g_string_insert_unichar".}
proc erase*(str: PGString, pos: gssize, len: gssize): PGString{.cdecl,
    dynlib: gliblib, importc: "g_string_erase".}
proc ascii_down*(str: PGString): PGString{.cdecl, dynlib: gliblib,
    importc: "g_string_ascii_down".}
proc ascii_up*(str: PGString): PGString{.cdecl, dynlib: gliblib,
    importc: "g_string_ascii_up".}
proc down*(str: PGString): PGString{.cdecl, dynlib: gliblib,
    importc: "g_string_down".}
proc up*(str: PGString): PGString{.cdecl, dynlib: gliblib,
    importc: "g_string_up".}
type
  PGIOError* = ptr TGIOError
  TGIOError* = enum
    G_IO_ERROR_NONE, G_IO_ERROR_AGAIN, G_IO_ERROR_INVAL, G_IO_ERROR_UNKNOWN

proc G_IO_CHANNEL_ERROR*(): TGQuark
type
  PGIOChannelError* = ptr TGIOChannelError
  TGIOChannelError* = enum
    G_IO_CHANNEL_ERROR_FBIG, G_IO_CHANNEL_ERROR_INVAL, G_IO_CHANNEL_ERROR_IO,
    G_IO_CHANNEL_ERROR_ISDIR, G_IO_CHANNEL_ERROR_NOSPC, G_IO_CHANNEL_ERROR_NXIO,
    G_IO_CHANNEL_ERROR_OVERFLOW, G_IO_CHANNEL_ERROR_PIPE,
    G_IO_CHANNEL_ERROR_FAILED
  PGIOStatus* = ptr TGIOStatus
  TGIOStatus* = enum
    G_IO_STATUS_ERROR, G_IO_STATUS_NORMAL, G_IO_STATUS_EOF, G_IO_STATUS_AGAIN
  PGSeekType* = ptr TGSeekType
  TGSeekType* = enum
    G_SEEK_CUR, G_SEEK_SET, G_SEEK_END
  PGIOCondition* = ptr TGIOCondition
  TGIOCondition* = gint

const
  G_IO_IN* = GLIB_SYSDEF_POLLIN
  G_IO_OUT* = GLIB_SYSDEF_POLLOUT
  G_IO_PRI* = GLIB_SYSDEF_POLLPRI
  G_IO_ERR* = GLIB_SYSDEF_POLLERR
  G_IO_HUP* = GLIB_SYSDEF_POLLHUP
  G_IO_NVAL* = GLIB_SYSDEF_POLLNVAL

type
  PGIOFlags* = ptr TGIOFlags
  TGIOFlags* = gint

const
  G_IO_FLAG_APPEND* = 1 shl 0
  G_IO_FLAG_NONBLOCK* = 1 shl 1
  G_IO_FLAG_IS_READABLE* = 1 shl 2
  G_IO_FLAG_IS_WRITEABLE* = 1 shl 3
  G_IO_FLAG_IS_SEEKABLE* = 1 shl 4
  G_IO_FLAG_MASK* = (1 shl 5) - 1
  G_IO_FLAG_GET_MASK* = G_IO_FLAG_MASK
  G_IO_FLAG_SET_MASK* = G_IO_FLAG_APPEND or G_IO_FLAG_NONBLOCK

type
  PGIOChannel* = ptr TGIOChannel
  TGIOFunc* = proc (source: PGIOChannel, condition: TGIOCondition,
                    data: gpointer): gboolean{.cdecl.}
  PGIOFuncs* = ptr TGIOFuncs
  TGIOFuncs*{.final.} = object
    io_read*: proc (channel: PGIOChannel, buf: cstring, count: gsize,
                    bytes_read: Pgsize, err: pointer): TGIOStatus{.cdecl.}
    io_write*: proc (channel: PGIOChannel, buf: cstring, count: gsize,
                     bytes_written: Pgsize, err: pointer): TGIOStatus{.cdecl.}
    io_seek*: proc (channel: PGIOChannel, offset: gint64, theType: TGSeekType,
                    err: pointer): TGIOStatus{.cdecl.}
    io_close*: proc (channel: PGIOChannel, err: pointer): TGIOStatus{.cdecl.}
    io_create_watch*: proc (channel: PGIOChannel, condition: TGIOCondition): PGSource{.
        cdecl.}
    io_free*: proc (channel: PGIOChannel){.cdecl.}
    io_set_flags*: proc (channel: PGIOChannel, flags: TGIOFlags, err: pointer): TGIOStatus{.
        cdecl.}
    io_get_flags*: proc (channel: PGIOChannel): TGIOFlags{.cdecl.}

  TGIOChannel*{.final.} = object
    ref_count*: guint
    funcs*: PGIOFuncs
    encoding*: cstring
    read_cd*: TGIConv
    write_cd*: TGIConv
    line_term*: cstring
    line_term_len*: guint
    buf_size*: gsize
    read_buf*: PGString
    encoded_read_buf*: PGString
    write_buf*: PGString
    partial_write_buf*: array[0..5, gchar]
    flag0*: guint16
    reserved1*: gpointer
    reserved2*: gpointer


const
  bm_TGIOChannel_use_buffer* = 0x0001'i16
  bp_TGIOChannel_use_buffer* = 0'i16
  bm_TGIOChannel_do_encode* = 0x0002'i16
  bp_TGIOChannel_do_encode* = 1'i16
  bm_TGIOChannel_close_on_unref* = 0x0004'i16
  bp_TGIOChannel_close_on_unref* = 2'i16
  bm_TGIOChannel_is_readable* = 0x0008'i16
  bp_TGIOChannel_is_readable* = 3'i16
  bm_TGIOChannel_is_writeable* = 0x0010'i16
  bp_TGIOChannel_is_writeable* = 4'i16
  bm_TGIOChannel_is_seekable* = 0x0020'i16
  bp_TGIOChannel_is_seekable* = 5'i16

proc TGIOChannel_use_buffer*(a: PGIOChannel): guint
proc TGIOChannel_set_use_buffer*(a: PGIOChannel, `use_buffer`: guint)
proc TGIOChannel_do_encode*(a: PGIOChannel): guint
proc TGIOChannel_set_do_encode*(a: PGIOChannel, `do_encode`: guint)
proc TGIOChannel_close_on_unref*(a: PGIOChannel): guint
proc TGIOChannel_set_close_on_unref*(a: PGIOChannel, `close_on_unref`: guint)
proc TGIOChannel_is_readable*(a: PGIOChannel): guint
proc TGIOChannel_set_is_readable*(a: PGIOChannel, `is_readable`: guint)
proc TGIOChannel_is_writeable*(a: PGIOChannel): guint
proc TGIOChannel_set_is_writeable*(a: PGIOChannel, `is_writeable`: guint)
proc TGIOChannel_is_seekable*(a: PGIOChannel): guint
proc TGIOChannel_set_is_seekable*(a: PGIOChannel, `is_seekable`: guint)
proc channel_init*(channel: PGIOChannel){.cdecl, dynlib: gliblib,
    importc: "g_io_channel_init".}
proc channel_ref*(channel: PGIOChannel){.cdecl, dynlib: gliblib,
    importc: "g_io_channel_ref".}
proc channel_unref*(channel: PGIOChannel){.cdecl, dynlib: gliblib,
    importc: "g_io_channel_unref".}
proc channel_read*(channel: PGIOChannel, buf: cstring, count: gsize,
                        bytes_read: Pgsize): TGIOError{.cdecl, dynlib: gliblib,
    importc: "g_io_channel_read".}
proc channel_write*(channel: PGIOChannel, buf: cstring, count: gsize,
                         bytes_written: Pgsize): TGIOError{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_write".}
proc channel_seek*(channel: PGIOChannel, offset: gint64,
                        theType: TGSeekType): TGIOError{.cdecl, dynlib: gliblib,
    importc: "g_io_channel_seek".}
proc channel_close*(channel: PGIOChannel){.cdecl, dynlib: gliblib,
    importc: "g_io_channel_close".}
proc channel_shutdown*(channel: PGIOChannel, flush: gboolean, err: pointer): TGIOStatus{.
    cdecl, dynlib: gliblib, importc: "g_io_channel_shutdown".}
proc add_watch_full*(channel: PGIOChannel, priority: gint,
                          condition: TGIOCondition, func: TGIOFunc,
                          user_data: gpointer, notify: TGDestroyNotify): guint{.
    cdecl, dynlib: gliblib, importc: "g_io_add_watch_full".}
proc create_watch*(channel: PGIOChannel, condition: TGIOCondition): PGSource{.
    cdecl, dynlib: gliblib, importc: "g_io_create_watch".}
proc add_watch*(channel: PGIOChannel, condition: TGIOCondition,
                     func: TGIOFunc, user_data: gpointer): guint{.cdecl,
    dynlib: gliblib, importc: "g_io_add_watch".}
proc channel_set_buffer_size*(channel: PGIOChannel, size: gsize){.cdecl,
    dynlib: gliblib, importc: "g_io_channel_set_buffer_size".}
proc channel_get_buffer_size*(channel: PGIOChannel): gsize{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_get_buffer_size".}
proc channel_get_buffer_condition*(channel: PGIOChannel): TGIOCondition{.
    cdecl, dynlib: gliblib, importc: "g_io_channel_get_buffer_condition".}
proc channel_set_flags*(channel: PGIOChannel, flags: TGIOFlags,
                             error: pointer): TGIOStatus{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_set_flags".}
proc channel_get_flags*(channel: PGIOChannel): TGIOFlags{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_get_flags".}
proc channel_set_line_term*(channel: PGIOChannel, line_term: cstring,
                                 length: gint){.cdecl, dynlib: gliblib,
    importc: "g_io_channel_set_line_term".}
proc channel_get_line_term*(channel: PGIOChannel, length: Pgint): cstring{.
    cdecl, dynlib: gliblib, importc: "g_io_channel_get_line_term".}
proc channel_set_buffered*(channel: PGIOChannel, buffered: gboolean){.
    cdecl, dynlib: gliblib, importc: "g_io_channel_set_buffered".}
proc channel_get_buffered*(channel: PGIOChannel): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_get_buffered".}
proc channel_set_encoding*(channel: PGIOChannel, encoding: cstring,
                                error: pointer): TGIOStatus{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_set_encoding".}
proc channel_get_encoding*(channel: PGIOChannel): cstring{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_get_encoding".}
proc channel_set_close_on_unref*(channel: PGIOChannel, do_close: gboolean){.
    cdecl, dynlib: gliblib, importc: "g_io_channel_set_close_on_unref".}
proc channel_get_close_on_unref*(channel: PGIOChannel): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_get_close_on_unref".}
proc channel_flush*(channel: PGIOChannel, error: pointer): TGIOStatus{.
    cdecl, dynlib: gliblib, importc: "g_io_channel_flush".}
proc channel_read_line*(channel: PGIOChannel, str_return: PPgchar,
                             length: Pgsize, terminator_pos: Pgsize,
                             error: pointer): TGIOStatus{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_read_line".}
proc channel_read_line_string*(channel: PGIOChannel, buffer: PGString,
                                    terminator_pos: Pgsize, error: pointer): TGIOStatus{.
    cdecl, dynlib: gliblib, importc: "g_io_channel_read_line_string".}
proc channel_read_to_end*(channel: PGIOChannel, str_return: PPgchar,
                               length: Pgsize, error: pointer): TGIOStatus{.
    cdecl, dynlib: gliblib, importc: "g_io_channel_read_to_end".}
proc channel_read_chars*(channel: PGIOChannel, buf: cstring, count: gsize,
                              bytes_read: Pgsize, error: pointer): TGIOStatus{.
    cdecl, dynlib: gliblib, importc: "g_io_channel_read_chars".}
proc channel_read_unichar*(channel: PGIOChannel, thechar: Pgunichar,
                                error: pointer): TGIOStatus{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_read_unichar".}
proc channel_write_chars*(channel: PGIOChannel, buf: cstring,
                               count: gssize, bytes_written: Pgsize,
                               error: pointer): TGIOStatus{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_write_chars".}
proc channel_write_unichar*(channel: PGIOChannel, thechar: gunichar,
                                 error: pointer): TGIOStatus{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_write_unichar".}
proc channel_seek_position*(channel: PGIOChannel, offset: gint64,
                                 theType: TGSeekType, error: pointer): TGIOStatus{.
    cdecl, dynlib: gliblib, importc: "g_io_channel_seek_position".}
proc g_io_channel_new_file*(filename: cstring, mode: cstring, error: pointer): PGIOChannel{.
    cdecl, dynlib: gliblib, importc: "g_io_channel_new_file".}
proc g_io_channel_error_quark*(): TGQuark{.cdecl, dynlib: gliblib,
    importc: "g_io_channel_error_quark".}
proc g_io_channel_error_from_errno*(en: gint): TGIOChannelError{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_error_from_errno".}
proc g_io_channel_unix_new*(fd: int32): PGIOChannel{.cdecl, dynlib: gliblib,
    importc: "g_io_channel_unix_new".}
proc channel_unix_get_fd*(channel: PGIOChannel): gint{.cdecl,
    dynlib: gliblib, importc: "g_io_channel_unix_get_fd".}
const
  G_LOG_LEVEL_USER_SHIFT* = 8

type
  PGLogLevelFlags* = ptr TGLogLevelFlags
  TGLogLevelFlags* = int32

const
  G_LOG_FLAG_RECURSION* = 1 shl 0
  G_LOG_FLAG_FATAL* = 1 shl 1
  G_LOG_LEVEL_ERROR* = 1 shl 2
  G_LOG_LEVEL_CRITICAL* = 1 shl 3
  G_LOG_LEVEL_WARNING* = 1 shl 4
  G_LOG_LEVEL_MESSAGE* = 1 shl 5
  G_LOG_LEVEL_INFO* = 1 shl 6
  G_LOG_LEVEL_DEBUG* = 1 shl 7
  G_LOG_LEVEL_MASK* = not 3

const
  G_LOG_FATAL_MASK* = 5

type
  TGLogFunc* = proc (log_domain: cstring, log_level: TGLogLevelFlags,
                     TheMessage: cstring, user_data: gpointer){.cdecl.}

proc g_log_set_handler*(log_domain: cstring, log_levels: TGLogLevelFlags,
                        log_func: TGLogFunc, user_data: gpointer): guint{.cdecl,
    dynlib: gliblib, importc: "g_log_set_handler".}
proc g_log_remove_handler*(log_domain: cstring, handler_id: guint){.cdecl,
    dynlib: gliblib, importc: "g_log_remove_handler".}
proc g_log_default_handler*(log_domain: cstring, log_level: TGLogLevelFlags,
                            TheMessage: cstring, unused_data: gpointer){.cdecl,
    dynlib: gliblib, importc: "g_log_default_handler".}
proc g_log_set_fatal_mask*(log_domain: cstring, fatal_mask: TGLogLevelFlags): TGLogLevelFlags{.
    cdecl, dynlib: gliblib, importc: "g_log_set_fatal_mask".}
proc g_log_set_always_fatal*(fatal_mask: TGLogLevelFlags): TGLogLevelFlags{.
    cdecl, dynlib: gliblib, importc: "g_log_set_always_fatal".}
proc `g_log_fallback_handler`*(log_domain: cstring, log_level: TGLogLevelFlags,
                               message: cstring, unused_data: gpointer){.cdecl,
    dynlib: gliblib, importc: "g_log_fallback_handler".}
const
  G_LOG_DOMAIN* = nil

when false:
  proc g_error*(format: cstring){.varargs.}
  proc g_message*(format: cstring){.varargs.}
  proc g_critical*(format: cstring){.varargs.}
  proc g_warning*(format: cstring){.varargs.}
type
  TGPrintFunc* = proc (str: cstring){.cdecl, varargs.}

proc g_set_print_handler*(func: TGPrintFunc): TGPrintFunc{.cdecl,
    dynlib: gliblib, importc: "g_set_print_handler".}
proc g_set_printerr_handler*(func: TGPrintFunc): TGPrintFunc{.cdecl,
    dynlib: gliblib, importc: "g_set_printerr_handler".}
type
  PGMarkupError* = ptr TGMarkupError
  TGMarkupError* = enum
    G_MARKUP_ERROR_BAD_UTF8, G_MARKUP_ERROR_EMPTY, G_MARKUP_ERROR_PARSE,
    G_MARKUP_ERROR_UNKNOWN_ELEMENT, G_MARKUP_ERROR_UNKNOWN_ATTRIBUTE,
    G_MARKUP_ERROR_INVALID_CONTENT

proc G_MARKUP_ERROR*(): TGQuark
proc g_markup_error_quark*(): TGQuark{.cdecl, dynlib: gliblib,
                                       importc: "g_markup_error_quark".}
type
  PGMarkupParseFlags* = ptr TGMarkupParseFlags
  TGMarkupParseFlags* = int

const
  G_MARKUP_DO_NOT_USE_THIS_UNSUPPORTED_FLAG* = 1 shl 0

type
  PGMarkupParseContext* = ptr TGMarkupParseContext
  TGMarkupParseContext* = pointer
  PGMarkupParser* = ptr TGMarkupParser
  TGMarkupParser*{.final.} = object
    start_element*: proc (context: PGMarkupParseContext, element_name: cstring,
                          attribute_names: PPgchar, attribute_values: PPgchar,
                          user_data: gpointer, error: pointer){.cdecl.}
    end_element*: proc (context: PGMarkupParseContext, element_name: cstring,
                        user_data: gpointer, error: pointer){.cdecl.}
    text*: proc (context: PGMarkupParseContext, text: cstring, text_len: gsize,
                 user_data: gpointer, error: pointer){.cdecl.}
    passthrough*: proc (context: PGMarkupParseContext,
                        passthrough_text: cstring, text_len: gsize,
                        user_data: gpointer, error: pointer){.cdecl.}
    error*: proc (context: PGMarkupParseContext, error: pointer,
                  user_data: gpointer){.cdecl.}


proc parse_context_new*(parser: PGMarkupParser,
                                 flags: TGMarkupParseFlags, user_data: gpointer,
                                 user_data_dnotify: TGDestroyNotify): PGMarkupParseContext{.
    cdecl, dynlib: gliblib, importc: "g_markup_parse_context_new".}
proc parse_context_free*(context: PGMarkupParseContext){.cdecl,
    dynlib: gliblib, importc: "g_markup_parse_context_free".}
proc parse_context_parse*(context: PGMarkupParseContext, text: cstring,
                                   text_len: gssize, error: pointer): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_markup_parse_context_parse".}
proc parse_context_end_parse*(context: PGMarkupParseContext,
                                       error: pointer): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_markup_parse_context_end_parse".}
proc parse_context_get_position*(context: PGMarkupParseContext,
    line_number: Pgint, char_number: Pgint){.cdecl, dynlib: gliblib,
    importc: "g_markup_parse_context_get_position".}
proc g_markup_escape_text*(text: cstring, length: gssize): cstring{.cdecl,
    dynlib: gliblib, importc: "g_markup_escape_text".}
type
  PGNode* = ptr TGNode
  TGNode*{.final.} = object
    data*: gpointer
    next*: PGNode
    prev*: PGNode
    parent*: PGNode
    children*: PGNode

  PGTraverseFlags* = ptr TGTraverseFlags
  TGTraverseFlags* = gint

const
  G_TRAVERSE_LEAFS* = 1 shl 0
  G_TRAVERSE_NON_LEAFS* = 1 shl 1
  G_TRAVERSE_ALL* = G_TRAVERSE_LEAFS or G_TRAVERSE_NON_LEAFS
  G_TRAVERSE_MASK* = 0x00000003

type
  PGTraverseType* = ptr TGTraverseType
  TGTraverseType* = enum
    G_IN_ORDER, G_PRE_ORDER, G_POST_ORDER, G_LEVEL_ORDER
  TGNodeTraverseFunc* = proc (node: PGNode, data: gpointer): gboolean{.cdecl.}
  TGNodeForeachFunc* = proc (node: PGNode, data: gpointer){.cdecl.}

proc IS_ROOT*(node: PGNode): bool
proc IS_LEAF*(node: PGNode): bool
proc node_push_allocator*(allocator: PGAllocator){.cdecl, dynlib: gliblib,
    importc: "g_node_push_allocator".}
proc g_node_pop_allocator*(){.cdecl, dynlib: gliblib,
                              importc: "g_node_pop_allocator".}
proc g_node_new*(data: gpointer): PGNode{.cdecl, dynlib: gliblib,
    importc: "g_node_new".}
proc destroy*(root: PGNode){.cdecl, dynlib: gliblib,
                                    importc: "g_node_destroy".}
proc unlink*(node: PGNode){.cdecl, dynlib: gliblib,
                                   importc: "g_node_unlink".}
proc copy*(node: PGNode): PGNode{.cdecl, dynlib: gliblib,
    importc: "g_node_copy".}
proc insert*(parent: PGNode, position: gint, node: PGNode): PGNode{.
    cdecl, dynlib: gliblib, importc: "g_node_insert".}
proc insert_before*(parent: PGNode, sibling: PGNode, node: PGNode): PGNode{.
    cdecl, dynlib: gliblib, importc: "g_node_insert_before".}
proc insert_after*(parent: PGNode, sibling: PGNode, node: PGNode): PGNode{.
    cdecl, dynlib: gliblib, importc: "g_node_insert_after".}
proc prepend*(parent: PGNode, node: PGNode): PGNode{.cdecl,
    dynlib: gliblib, importc: "g_node_prepend".}
proc n_nodes*(root: PGNode, flags: TGTraverseFlags): guint{.cdecl,
    dynlib: gliblib, importc: "g_node_n_nodes".}
proc get_root*(node: PGNode): PGNode{.cdecl, dynlib: gliblib,
    importc: "g_node_get_root".}
proc is_ancestor*(node: PGNode, descendant: PGNode): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_node_is_ancestor".}
proc depth*(node: PGNode): guint{.cdecl, dynlib: gliblib,
    importc: "g_node_depth".}
proc find*(root: PGNode, order: TGTraverseType, flags: TGTraverseFlags,
                  data: gpointer): PGNode{.cdecl, dynlib: gliblib,
    importc: "g_node_find".}
proc append*(parent: PGNode, node: PGNode): PGNode
proc insert_data*(parent: PGNode, position: gint, data: gpointer): PGNode
proc insert_data_before*(parent: PGNode, sibling: PGNode, data: gpointer): PGNode
proc prepend_data*(parent: PGNode, data: gpointer): PGNode
proc append_data*(parent: PGNode, data: gpointer): PGNode
proc traverse*(root: PGNode, order: TGTraverseType,
                      flags: TGTraverseFlags, max_depth: gint,
                      func: TGNodeTraverseFunc, data: gpointer): guint{.cdecl,
    dynlib: gliblib, importc: "g_node_traverse".}
proc max_height*(root: PGNode): guint{.cdecl, dynlib: gliblib,
    importc: "g_node_max_height".}
proc children_foreach*(node: PGNode, flags: TGTraverseFlags,
                              func: TGNodeForeachFunc, data: gpointer){.cdecl,
    dynlib: gliblib, importc: "g_node_children_foreach".}
proc reverse_children*(node: PGNode){.cdecl, dynlib: gliblib,
    importc: "g_node_reverse_children".}
proc n_children*(node: PGNode): guint{.cdecl, dynlib: gliblib,
    importc: "g_node_n_children".}
proc nth_child*(node: PGNode, n: guint): PGNode{.cdecl, dynlib: gliblib,
    importc: "g_node_nth_child".}
proc last_child*(node: PGNode): PGNode{.cdecl, dynlib: gliblib,
    importc: "g_node_last_child".}
proc find_child*(node: PGNode, flags: TGTraverseFlags, data: gpointer): PGNode{.
    cdecl, dynlib: gliblib, importc: "g_node_find_child".}
proc child_position*(node: PGNode, child: PGNode): gint{.cdecl,
    dynlib: gliblib, importc: "g_node_child_position".}
proc child_index*(node: PGNode, data: gpointer): gint{.cdecl,
    dynlib: gliblib, importc: "g_node_child_index".}
proc first_sibling*(node: PGNode): PGNode{.cdecl, dynlib: gliblib,
    importc: "g_node_first_sibling".}
proc last_sibling*(node: PGNode): PGNode{.cdecl, dynlib: gliblib,
    importc: "g_node_last_sibling".}
proc prev_sibling*(node: PGNode): PGNode
proc next_sibling*(node: PGNode): PGNode
proc first_child*(node: PGNode): PGNode
type
  PGTree* = pointer
  TGTraverseFunc* = proc (key: gpointer, value: gpointer, data: gpointer): gboolean{.
      cdecl.}

proc g_tree_new*(key_compare_func: TGCompareFunc): PGTree{.cdecl,
    dynlib: gliblib, importc: "g_tree_new".}
proc g_tree_new*(key_compare_func: TGCompareDataFunc,
                           key_compare_data: gpointer): PGTree{.cdecl,
    dynlib: gliblib, importc: "g_tree_new_with_data".}
proc g_tree_new_full*(key_compare_func: TGCompareDataFunc,
                      key_compare_data: gpointer,
                      key_destroy_func: TGDestroyNotify,
                      value_destroy_func: TGDestroyNotify): PGTree{.cdecl,
    dynlib: gliblib, importc: "g_tree_new_full".}
proc destroy*(tree: PGTree){.cdecl, dynlib: gliblib,
                                    importc: "g_tree_destroy".}
proc insert*(tree: PGTree, key: gpointer, value: gpointer){.cdecl,
    dynlib: gliblib, importc: "g_tree_insert".}
proc replace*(tree: PGTree, key: gpointer, value: gpointer){.cdecl,
    dynlib: gliblib, importc: "g_tree_replace".}
proc remove*(tree: PGTree, key: gconstpointer){.cdecl, dynlib: gliblib,
    importc: "g_tree_remove".}
proc steal*(tree: PGTree, key: gconstpointer){.cdecl, dynlib: gliblib,
    importc: "g_tree_steal".}
proc lookup*(tree: PGTree, key: gconstpointer): gpointer{.cdecl,
    dynlib: gliblib, importc: "g_tree_lookup".}
proc lookup_extended*(tree: PGTree, lookup_key: gconstpointer,
                             orig_key: Pgpointer, value: Pgpointer): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_tree_lookup_extended".}
proc foreach*(tree: PGTree, func: TGTraverseFunc, user_data: gpointer){.
    cdecl, dynlib: gliblib, importc: "g_tree_foreach".}
proc search*(tree: PGTree, search_func: TGCompareFunc,
                    user_data: gconstpointer): gpointer{.cdecl, dynlib: gliblib,
    importc: "g_tree_search".}
proc height*(tree: PGTree): gint{.cdecl, dynlib: gliblib,
    importc: "g_tree_height".}
proc nnodes*(tree: PGTree): gint{.cdecl, dynlib: gliblib,
    importc: "g_tree_nnodes".}
type
  PGPatternSpec* = pointer

proc g_pattern_spec_new*(pattern: cstring): PGPatternSpec{.cdecl,
    dynlib: gliblib, importc: "g_pattern_spec_new".}
proc spec_free*(pspec: PGPatternSpec){.cdecl, dynlib: gliblib,
    importc: "g_pattern_spec_free".}
proc spec_equal*(pspec1: PGPatternSpec, pspec2: PGPatternSpec): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_pattern_spec_equal".}
proc match*(pspec: PGPatternSpec, string_length: guint, str: cstring,
                      string_reversed: cstring): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_pattern_match".}
proc match_string*(pspec: PGPatternSpec, str: cstring): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_pattern_match_string".}
proc g_pattern_match_simple*(pattern: cstring, str: cstring): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_pattern_match_simple".}
proc g_spaced_primes_closest*(num: guint): guint{.cdecl, dynlib: gliblib,
    importc: "g_spaced_primes_closest".}
proc g_qsort*(pbase: gconstpointer, total_elems: gint, size: gsize,
                        compare_func: TGCompareDataFunc, user_data: gpointer){.
    cdecl, dynlib: gliblib, importc: "g_qsort_with_data".}
type
  PGQueue* = ptr TGQueue
  TGQueue*{.final.} = object
    head*: PGList
    tail*: PGList
    length*: guint


proc g_queue_new*(): PGQueue{.cdecl, dynlib: gliblib, importc: "g_queue_new".}
proc free*(queue: PGQueue){.cdecl, dynlib: gliblib,
                                    importc: "g_queue_free".}
proc push_head*(queue: PGQueue, data: gpointer){.cdecl, dynlib: gliblib,
    importc: "g_queue_push_head".}
proc push_tail*(queue: PGQueue, data: gpointer){.cdecl, dynlib: gliblib,
    importc: "g_queue_push_tail".}
proc pop_head*(queue: PGQueue): gpointer{.cdecl, dynlib: gliblib,
    importc: "g_queue_pop_head".}
proc pop_tail*(queue: PGQueue): gpointer{.cdecl, dynlib: gliblib,
    importc: "g_queue_pop_tail".}
proc is_empty*(queue: PGQueue): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_queue_is_empty".}
proc peek_head*(queue: PGQueue): gpointer{.cdecl, dynlib: gliblib,
    importc: "g_queue_peek_head".}
proc peek_tail*(queue: PGQueue): gpointer{.cdecl, dynlib: gliblib,
    importc: "g_queue_peek_tail".}
proc push_head_link*(queue: PGQueue, link: PGList){.cdecl,
    dynlib: gliblib, importc: "g_queue_push_head_link".}
proc push_tail_link*(queue: PGQueue, link: PGList){.cdecl,
    dynlib: gliblib, importc: "g_queue_push_tail_link".}
proc pop_head_link*(queue: PGQueue): PGList{.cdecl, dynlib: gliblib,
    importc: "g_queue_pop_head_link".}
proc pop_tail_link*(queue: PGQueue): PGList{.cdecl, dynlib: gliblib,
    importc: "g_queue_pop_tail_link".}
type
  PGRand* = pointer

proc g_rand_new*(seed: guint32): PGRand{.cdecl, dynlib: gliblib,
    importc: "g_rand_new_with_seed".}
proc g_rand_new*(): PGRand{.cdecl, dynlib: gliblib, importc: "g_rand_new".}
proc free*(rand: PGRand){.cdecl, dynlib: gliblib, importc: "g_rand_free".}
proc set_seed*(rand: PGRand, seed: guint32){.cdecl, dynlib: gliblib,
    importc: "g_rand_set_seed".}
proc boolean*(rand: PGRand): gboolean
proc randint*(rand: PGRand): guint32{.cdecl, dynlib: gliblib,
    importc: "g_rand_int".}
proc int_range*(rand: PGRand, `begin`: gint32, `end`: gint32): gint32{.
    cdecl, dynlib: gliblib, importc: "g_rand_int_range".}
proc double*(rand: PGRand): gdouble{.cdecl, dynlib: gliblib,
    importc: "g_rand_double".}
proc double_range*(rand: PGRand, `begin`: gdouble, `end`: gdouble): gdouble{.
    cdecl, dynlib: gliblib, importc: "g_rand_double_range".}
proc g_random_set_seed*(seed: guint32){.cdecl, dynlib: gliblib,
                                        importc: "g_random_set_seed".}
proc g_random_boolean*(): gboolean
proc g_random_int*(): guint32{.cdecl, dynlib: gliblib, importc: "g_random_int".}
proc g_random_int_range*(`begin`: gint32, `end`: gint32): gint32{.cdecl,
    dynlib: gliblib, importc: "g_random_int_range".}
proc g_random_double*(): gdouble{.cdecl, dynlib: gliblib,
                                  importc: "g_random_double".}
proc g_random_double_range*(`begin`: gdouble, `end`: gdouble): gdouble{.cdecl,
    dynlib: gliblib, importc: "g_random_double_range".}
type
  PGTuples* = ptr TGTuples
  TGTuples*{.final.} = object
    len*: guint

  PGRelation* = pointer

proc g_relation_new*(fields: gint): PGRelation{.cdecl, dynlib: gliblib,
    importc: "g_relation_new".}
proc destroy*(relation: PGRelation){.cdecl, dynlib: gliblib,
    importc: "g_relation_destroy".}
proc index*(relation: PGRelation, field: gint, hash_func: TGHashFunc,
                       key_equal_func: TGEqualFunc){.cdecl, dynlib: gliblib,
    importc: "g_relation_index".}
proc delete*(relation: PGRelation, key: gconstpointer, field: gint): gint{.
    cdecl, dynlib: gliblib, importc: "g_relation_delete".}
proc select*(relation: PGRelation, key: gconstpointer, field: gint): PGTuples{.
    cdecl, dynlib: gliblib, importc: "g_relation_select".}
proc count*(relation: PGRelation, key: gconstpointer, field: gint): gint{.
    cdecl, dynlib: gliblib, importc: "g_relation_count".}
proc print*(relation: PGRelation){.cdecl, dynlib: gliblib,
    importc: "g_relation_print".}
proc destroy*(tuples: PGTuples){.cdecl, dynlib: gliblib,
    importc: "g_tuples_destroy".}
proc index*(tuples: PGTuples, index: gint, field: gint): gpointer{.
    cdecl, dynlib: gliblib, importc: "g_tuples_index".}
type
  PGTokenType* = ptr TGTokenType
  TGTokenType* = gint

const
  G_TOKEN_LEFT_PAREN* = 40
  G_TOKEN_RIGHT_PAREN* = 41
  G_TOKEN_LEFT_CURLY* = 123
  G_TOKEN_RIGHT_CURLY* = 125
  G_TOKEN_LEFT_BRACE* = 91
  G_TOKEN_RIGHT_BRACE* = 93
  G_TOKEN_EQUAL_SIGN* = 61
  G_TOKEN_COMMA* = 44
  G_TOKEN_NONE* = 256
  G_TOKEN_ERROR* = 257
  G_TOKEN_CHAR* = 258
  G_TOKEN_OCTAL* = 260
  G_TOKEN_INT* = 261
  G_TOKEN_HEX* = 262
  G_TOKEN_FLOAT* = 263
  G_TOKEN_STRING* = 264
  G_TOKEN_SYMBOL* = 265
  G_TOKEN_IDENTIFIER* = 266
  G_TOKEN_IDENTIFIER_NULL* = 267
  G_TOKEN_COMMENT_SINGLE* = 268
  G_TOKEN_COMMENT_MULTI* = 269
  G_TOKEN_LAST* = 270

type
  PGScanner* = ptr TGScanner
  PGScannerConfig* = ptr TGScannerConfig
  PGTokenValue* = ptr TGTokenValue
  TGTokenValue*{.final.} = object
    v_float*: gdouble

  TGScannerMsgFunc* = proc (scanner: PGScanner, message: cstring,
                            error: gboolean){.cdecl.}
  TGScanner*{.final.} = object
    user_data*: gpointer
    max_parse_errors*: guint
    parse_errors*: guint
    input_name*: cstring
    qdata*: PGData
    config*: PGScannerConfig
    token*: TGTokenType
    value*: TGTokenValue
    line*: guint
    position*: guint
    next_token*: TGTokenType
    next_value*: TGTokenValue
    next_line*: guint
    next_position*: guint
    symbol_table*: PGHashTable
    input_fd*: gint
    text*: cstring
    text_end*: cstring
    buffer*: cstring
    scope_id*: guint
    msg_handler*: TGScannerMsgFunc

  TGScannerConfig*{.final.} = object
    cset_skip_characters*: cstring
    cset_identifier_first*: cstring
    cset_identifier_nth*: cstring
    cpair_comment_single*: cstring
    flag0*: int32
    padding_dummy*: guint


const
  G_CSET_A_2_Z_UCASE* = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  G_CSET_a_2_z_lcase* = "abcdefghijklmnopqrstuvwxyz"
  G_CSET_DIGITS* = "0123456789"

const
  bm_TGScannerConfig_case_sensitive* = 0x00000001'i32
  bp_TGScannerConfig_case_sensitive* = 0'i32
  bm_TGScannerConfig_skip_comment_multi* = 0x00000002'i32
  bp_TGScannerConfig_skip_comment_multi* = 1'i32
  bm_TGScannerConfig_skip_comment_single* = 0x00000004'i32
  bp_TGScannerConfig_skip_comment_single* = 2'i32
  bm_TGScannerConfig_scan_comment_multi* = 0x00000008'i32
  bp_TGScannerConfig_scan_comment_multi* = 3'i32
  bm_TGScannerConfig_scan_identifier* = 0x00000010'i32
  bp_TGScannerConfig_scan_identifier* = 4'i32
  bm_TGScannerConfig_scan_identifier_1char* = 0x00000020'i32
  bp_TGScannerConfig_scan_identifier_1char* = 5'i32
  bm_TGScannerConfig_scan_identifier_NULL* = 0x00000040'i32
  bp_TGScannerConfig_scan_identifier_NULL* = 6'i32
  bm_TGScannerConfig_scan_symbols* = 0x00000080'i32
  bp_TGScannerConfig_scan_symbols* = 7'i32
  bm_TGScannerConfig_scan_binary* = 0x00000100'i32
  bp_TGScannerConfig_scan_binary* = 8'i32
  bm_TGScannerConfig_scan_octal* = 0x00000200'i32
  bp_TGScannerConfig_scan_octal* = 9'i32
  bm_TGScannerConfig_scan_float* = 0x00000400'i32
  bp_TGScannerConfig_scan_float* = 10'i32
  bm_TGScannerConfig_scan_hex* = 0x00000800'i32
  bp_TGScannerConfig_scan_hex* = 11'i32
  bm_TGScannerConfig_scan_hex_dollar* = 0x00001000'i32
  bp_TGScannerConfig_scan_hex_dollar* = 12'i32
  bm_TGScannerConfig_scan_string_sq* = 0x00002000'i32
  bp_TGScannerConfig_scan_string_sq* = 13'i32
  bm_TGScannerConfig_scan_string_dq* = 0x00004000'i32
  bp_TGScannerConfig_scan_string_dq* = 14'i32
  bm_TGScannerConfig_numbers_2_int* = 0x00008000'i32
  bp_TGScannerConfig_numbers_2_int* = 15'i32
  bm_TGScannerConfig_int_2_float* = 0x00010000'i32
  bp_TGScannerConfig_int_2_float* = 16'i32
  bm_TGScannerConfig_identifier_2_string* = 0x00020000'i32
  bp_TGScannerConfig_identifier_2_string* = 17'i32
  bm_TGScannerConfig_char_2_token* = 0x00040000'i32
  bp_TGScannerConfig_char_2_token* = 18'i32
  bm_TGScannerConfig_symbol_2_token* = 0x00080000'i32
  bp_TGScannerConfig_symbol_2_token* = 19'i32
  bm_TGScannerConfig_scope_0_fallback* = 0x00100000'i32
  bp_TGScannerConfig_scope_0_fallback* = 20'i32

proc TGScannerConfig_case_sensitive*(a: PGScannerConfig): guint
proc TGScannerConfig_set_case_sensitive*(a: PGScannerConfig,
    `case_sensitive`: guint)
proc TGScannerConfig_skip_comment_multi*(a: PGScannerConfig): guint
proc TGScannerConfig_set_skip_comment_multi*(a: PGScannerConfig,
    `skip_comment_multi`: guint)
proc TGScannerConfig_skip_comment_single*(a: PGScannerConfig): guint
proc TGScannerConfig_set_skip_comment_single*(a: PGScannerConfig,
    `skip_comment_single`: guint)
proc TGScannerConfig_scan_comment_multi*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scan_comment_multi*(a: PGScannerConfig,
    `scan_comment_multi`: guint)
proc TGScannerConfig_scan_identifier*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scan_identifier*(a: PGScannerConfig,
    `scan_identifier`: guint)
proc TGScannerConfig_scan_identifier_1char*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scan_identifier_1char*(a: PGScannerConfig,
    `scan_identifier_1char`: guint)
proc TGScannerConfig_scan_identifier_NULL*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scan_identifier_NULL*(a: PGScannerConfig,
    `scan_identifier_NULL`: guint)
proc TGScannerConfig_scan_symbols*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scan_symbols*(a: PGScannerConfig,
                                       `scan_symbols`: guint)
proc TGScannerConfig_scan_binary*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scan_binary*(a: PGScannerConfig,
                                      `scan_binary`: guint)
proc TGScannerConfig_scan_octal*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scan_octal*(a: PGScannerConfig, `scan_octal`: guint)
proc TGScannerConfig_scan_float*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scan_float*(a: PGScannerConfig, `scan_float`: guint)
proc TGScannerConfig_scan_hex*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scan_hex*(a: PGScannerConfig, `scan_hex`: guint)
proc TGScannerConfig_scan_hex_dollar*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scan_hex_dollar*(a: PGScannerConfig,
    `scan_hex_dollar`: guint)
proc TGScannerConfig_scan_string_sq*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scan_string_sq*(a: PGScannerConfig,
    `scan_string_sq`: guint)
proc TGScannerConfig_scan_string_dq*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scan_string_dq*(a: PGScannerConfig,
    `scan_string_dq`: guint)
proc TGScannerConfig_numbers_2_int*(a: PGScannerConfig): guint
proc TGScannerConfig_set_numbers_2_int*(a: PGScannerConfig,
                                        `numbers_2_int`: guint)
proc TGScannerConfig_int_2_float*(a: PGScannerConfig): guint
proc TGScannerConfig_set_int_2_float*(a: PGScannerConfig,
                                      `int_2_float`: guint)
proc TGScannerConfig_identifier_2_string*(a: PGScannerConfig): guint
proc TGScannerConfig_set_identifier_2_string*(a: PGScannerConfig,
    `identifier_2_string`: guint)
proc TGScannerConfig_char_2_token*(a: PGScannerConfig): guint
proc TGScannerConfig_set_char_2_token*(a: PGScannerConfig,
                                       `char_2_token`: guint)
proc TGScannerConfig_symbol_2_token*(a: PGScannerConfig): guint
proc TGScannerConfig_set_symbol_2_token*(a: PGScannerConfig,
    `symbol_2_token`: guint)
proc TGScannerConfig_scope_0_fallback*(a: PGScannerConfig): guint
proc TGScannerConfig_set_scope_0_fallback*(a: PGScannerConfig,
    `scope_0_fallback`: guint)
proc new*(config_templ: PGScannerConfig): PGScanner{.cdecl,
    dynlib: gliblib, importc: "g_scanner_new".}
proc destroy*(scanner: PGScanner){.cdecl, dynlib: gliblib,
    importc: "g_scanner_destroy".}
proc input_file*(scanner: PGScanner, input_fd: gint){.cdecl,
    dynlib: gliblib, importc: "g_scanner_input_file".}
proc sync_file_offset*(scanner: PGScanner){.cdecl, dynlib: gliblib,
    importc: "g_scanner_sync_file_offset".}
proc input_text*(scanner: PGScanner, text: cstring, text_len: guint){.
    cdecl, dynlib: gliblib, importc: "g_scanner_input_text".}
proc get_next_token*(scanner: PGScanner): TGTokenType{.cdecl,
    dynlib: gliblib, importc: "g_scanner_get_next_token".}
proc peek_next_token*(scanner: PGScanner): TGTokenType{.cdecl,
    dynlib: gliblib, importc: "g_scanner_peek_next_token".}
proc cur_token*(scanner: PGScanner): TGTokenType{.cdecl,
    dynlib: gliblib, importc: "g_scanner_cur_token".}
proc cur_value*(scanner: PGScanner): TGTokenValue{.cdecl,
    dynlib: gliblib, importc: "g_scanner_cur_value".}
proc cur_line*(scanner: PGScanner): guint{.cdecl, dynlib: gliblib,
    importc: "g_scanner_cur_line".}
proc cur_position*(scanner: PGScanner): guint{.cdecl, dynlib: gliblib,
    importc: "g_scanner_cur_position".}
proc eof*(scanner: PGScanner): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_scanner_eof".}
proc set_scope*(scanner: PGScanner, scope_id: guint): guint{.cdecl,
    dynlib: gliblib, importc: "g_scanner_set_scope".}
proc scope_add_symbol*(scanner: PGScanner, scope_id: guint,
                                 symbol: cstring, value: gpointer){.cdecl,
    dynlib: gliblib, importc: "g_scanner_scope_add_symbol".}
proc scope_remove_symbol*(scanner: PGScanner, scope_id: guint,
                                    symbol: cstring){.cdecl, dynlib: gliblib,
    importc: "g_scanner_scope_remove_symbol".}
proc scope_lookup_symbol*(scanner: PGScanner, scope_id: guint,
                                    symbol: cstring): gpointer{.cdecl,
    dynlib: gliblib, importc: "g_scanner_scope_lookup_symbol".}
proc scope_foreach_symbol*(scanner: PGScanner, scope_id: guint,
                                     func: TGHFunc, user_data: gpointer){.cdecl,
    dynlib: gliblib, importc: "g_scanner_scope_foreach_symbol".}
proc lookup_symbol*(scanner: PGScanner, symbol: cstring): gpointer{.
    cdecl, dynlib: gliblib, importc: "g_scanner_lookup_symbol".}
proc unexp_token*(scanner: PGScanner, expected_token: TGTokenType,
                            identifier_spec: cstring, symbol_spec: cstring,
                            symbol_name: cstring, `message`: cstring,
                            is_error: gint){.cdecl, dynlib: gliblib,
    importc: "g_scanner_unexp_token".}
proc G_SHELL_ERROR*(): TGQuark
type
  PGShellError* = ptr TGShellError
  TGShellError* = enum
    G_SHELL_ERROR_BAD_QUOTING, G_SHELL_ERROR_EMPTY_STRING, G_SHELL_ERROR_FAILED

proc g_shell_error_quark*(): TGQuark{.cdecl, dynlib: gliblib,
                                      importc: "g_shell_error_quark".}
proc g_shell_quote*(unquoted_string: cstring): cstring{.cdecl, dynlib: gliblib,
    importc: "g_shell_quote".}
proc g_shell_unquote*(quoted_string: cstring, error: pointer): cstring{.cdecl,
    dynlib: gliblib, importc: "g_shell_unquote".}
proc g_shell_parse_argv*(command_line: cstring, argcp: Pgint, argvp: PPPgchar,
                         error: pointer): gboolean{.cdecl, dynlib: gliblib,
    importc: "g_shell_parse_argv".}
proc G_SPAWN_ERROR*(): TGQuark
type
  PGSpawnError* = ptr TGSpawnError
  TGSpawnError* = enum
    G_SPAWN_ERROR_FORK, G_SPAWN_ERROR_READ, G_SPAWN_ERROR_CHDIR,
    G_SPAWN_ERROR_ACCES, G_SPAWN_ERROR_PERM, G_SPAWN_ERROR_2BIG,
    G_SPAWN_ERROR_NOEXEC, G_SPAWN_ERROR_NAMETOOLONG, G_SPAWN_ERROR_NOENT,
    G_SPAWN_ERROR_NOMEM, G_SPAWN_ERROR_NOTDIR, G_SPAWN_ERROR_LOOP,
    G_SPAWN_ERROR_TXTBUSY, G_SPAWN_ERROR_IO, G_SPAWN_ERROR_NFILE,
    G_SPAWN_ERROR_MFILE, G_SPAWN_ERROR_INVAL, G_SPAWN_ERROR_ISDIR,
    G_SPAWN_ERROR_LIBBAD, G_SPAWN_ERROR_FAILED
  TGSpawnChildSetupFunc* = proc (user_data: gpointer){.cdecl.}
  PGSpawnFlags* = ptr TGSpawnFlags
  TGSpawnFlags* = int

const
  G_SPAWN_LEAVE_DESCRIPTORS_OPEN* = 1 shl 0
  G_SPAWN_DO_NOT_REAP_CHILD* = 1 shl 1
  G_SPAWN_SEARCH_PATH* = 1 shl 2
  G_SPAWN_STDOUT_TO_DEV_NULL* = 1 shl 3
  G_SPAWN_STDERR_TO_DEV_NULL* = 1 shl 4
  G_SPAWN_CHILD_INHERITS_STDIN* = 1 shl 5
  G_SPAWN_FILE_AND_ARGV_ZERO* = 1 shl 6

proc g_spawn_error_quark*(): TGQuark{.cdecl, dynlib: gliblib,
                                      importc: "g_spawn_error_quark".}
proc g_spawn_async*(working_directory: cstring, argv: PPgchar, envp: PPgchar,
                    flags: TGSpawnFlags, child_setup: TGSpawnChildSetupFunc,
                    user_data: gpointer, child_pid: Pgint, error: pointer): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_spawn_async".}
proc g_spawn_async*(working_directory: cstring, argv: PPgchar,
                               envp: PPgchar, flags: TGSpawnFlags,
                               child_setup: TGSpawnChildSetupFunc,
                               user_data: gpointer, child_pid: Pgint,
                               standard_input: Pgint, standard_output: Pgint,
                               standard_error: Pgint, error: pointer): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_spawn_async_with_pipes".}
proc g_spawn_sync*(working_directory: cstring, argv: PPgchar, envp: PPgchar,
                   flags: TGSpawnFlags, child_setup: TGSpawnChildSetupFunc,
                   user_data: gpointer, standard_output: PPgchar,
                   standard_error: PPgchar, exit_status: Pgint, error: pointer): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_spawn_sync".}
proc g_spawn_command_line_sync*(command_line: cstring, standard_output: PPgchar,
                                standard_error: PPgchar, exit_status: Pgint,
                                error: pointer): gboolean{.cdecl,
    dynlib: gliblib, importc: "g_spawn_command_line_sync".}
proc g_spawn_command_line_async*(command_line: cstring, error: pointer): gboolean{.
    cdecl, dynlib: gliblib, importc: "g_spawn_command_line_async".}
proc G_TYPE_IS_BOXED*(theType: GType): gboolean
proc HOLDS_BOXED*(value: PGValue): gboolean
proc G_TYPE_CLOSURE*(): GType
proc G_TYPE_VALUE*(): GType
proc G_TYPE_VALUE_ARRAY*(): GType
proc G_TYPE_GSTRING*(): GType
proc g_boxed_copy*(boxed_type: GType, src_boxed: gconstpointer): gpointer{.
    cdecl, dynlib: gobjectlib, importc: "g_boxed_copy".}
proc g_boxed_free*(boxed_type: GType, boxed: gpointer){.cdecl,
    dynlib: gobjectlib, importc: "g_boxed_free".}
proc set_boxed*(value: PGValue, v_boxed: gconstpointer){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_boxed".}
proc set_static_boxed*(value: PGValue, v_boxed: gconstpointer){.cdecl,
    dynlib: gobjectlib, importc: "g_value_set_static_boxed".}
proc get_boxed*(value: PGValue): gpointer{.cdecl, dynlib: gobjectlib,
    importc: "g_value_get_boxed".}
proc dup_boxed*(value: PGValue): gpointer{.cdecl, dynlib: gobjectlib,
    importc: "g_value_dup_boxed".}
proc g_boxed_type_register_static*(name: cstring, boxed_copy: TGBoxedCopyFunc,
                                   boxed_free: TGBoxedFreeFunc): GType{.cdecl,
    dynlib: gobjectlib, importc: "g_boxed_type_register_static".}
proc set_boxed_take_ownership*(value: PGValue, v_boxed: gconstpointer){.
    cdecl, dynlib: gobjectlib, importc: "g_value_set_boxed_take_ownership".}
proc g_closure_get_type*(): GType{.cdecl, dynlib: gobjectlib,
                                   importc: "g_closure_get_type".}
proc g_value_get_type*(): GType{.cdecl, dynlib: gobjectlib,
                                 importc: "g_value_get_type".}
proc g_value_array_get_type*(): GType{.cdecl, dynlib: gobjectlib,
                                       importc: "g_value_array_get_type".}
proc g_gstring_get_type*(): GType{.cdecl, dynlib: gobjectlib,
                                   importc: "g_gstring_get_type".}
type
  PGModule* = pointer
  TGModuleFlags* = int32
  TGModuleCheckInit* = proc (module: PGModule): cstring{.cdecl.}
  TGModuleUnload* = proc (module: PGModule){.cdecl.}

const
  G_MODULE_BIND_LAZY* = 1 shl 0
  G_MODULE_BIND_MASK* = 1

proc g_module_supported*(): gboolean{.cdecl, dynlib: gmodulelib,
                                      importc: "g_module_supported".}
proc g_module_open*(file_name: cstring, flags: TGModuleFlags): PGModule{.cdecl,
    dynlib: gmodulelib, importc: "g_module_open".}
proc close*(module: PGModule): gboolean{.cdecl, dynlib: gmodulelib,
    importc: "g_module_close".}
proc make_resident*(module: PGModule){.cdecl, dynlib: gmodulelib,
    importc: "g_module_make_resident".}
proc g_module_error*(): cstring{.cdecl, dynlib: gmodulelib,
                                 importc: "g_module_error".}
proc symbol*(module: PGModule, symbol_name: cstring, symbol: Pgpointer): gboolean{.
    cdecl, dynlib: gmodulelib, importc: "g_module_symbol".}
proc name*(module: PGModule): cstring{.cdecl, dynlib: gmodulelib,
    importc: "g_module_name".}
proc g_module_build_path*(directory: cstring, module_name: cstring): cstring{.
    cdecl, dynlib: gmodulelib, importc: "g_module_build_path".}
proc cclosure_marshal_VOID_VOID*(closure: PGClosure, return_value: PGValue,
                                    n_param_values: GUInt,
                                    param_values: PGValue,
                                    invocation_hint: GPointer,
                                    marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__VOID".}
proc cclosure_marshal_VOID_BOOLEAN*(closure: PGClosure,
                                       return_value: PGValue,
                                       n_param_values: GUInt,
                                       param_values: PGValue,
                                       invocation_hint: GPointer,
                                       marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__BOOLEAN".}
proc cclosure_marshal_VOID_CHAR*(closure: PGClosure, return_value: PGValue,
                                    n_param_values: GUInt,
                                    param_values: PGValue,
                                    invocation_hint: GPointer,
                                    marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__CHAR".}
proc cclosure_marshal_VOID_UCHAR*(closure: PGClosure, return_value: PGValue,
                                     n_param_values: GUInt,
                                     param_values: PGValue,
                                     invocation_hint: GPointer,
                                     marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__UCHAR".}
proc cclosure_marshal_VOID_INT*(closure: PGClosure, return_value: PGValue,
                                   n_param_values: GUInt, param_values: PGValue,
                                   invocation_hint: GPointer,
                                   marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__INT".}
proc cclosure_marshal_VOID_UINT*(closure: PGClosure, return_value: PGValue,
                                    n_param_values: GUInt,
                                    param_values: PGValue,
                                    invocation_hint: GPointer,
                                    marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__UINT".}
proc cclosure_marshal_VOID_LONG*(closure: PGClosure, return_value: PGValue,
                                    n_param_values: GUInt,
                                    param_values: PGValue,
                                    invocation_hint: GPointer,
                                    marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__LONG".}
proc cclosure_marshal_VOID_ULONG*(closure: PGClosure, return_value: PGValue,
                                     n_param_values: GUInt,
                                     param_values: PGValue,
                                     invocation_hint: GPointer,
                                     marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__ULONG".}
proc cclosure_marshal_VOID_ENUM*(closure: PGClosure, return_value: PGValue,
                                    n_param_values: GUInt,
                                    param_values: PGValue,
                                    invocation_hint: GPointer,
                                    marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__ENUM".}
proc cclosure_marshal_VOID_FLAGS*(closure: PGClosure, return_value: PGValue,
                                     n_param_values: GUInt,
                                     param_values: PGValue,
                                     invocation_hint: GPointer,
                                     marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__FLAGS".}
proc cclosure_marshal_VOID_FLOAT*(closure: PGClosure, return_value: PGValue,
                                     n_param_values: GUInt,
                                     param_values: PGValue,
                                     invocation_hint: GPointer,
                                     marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__FLOAT".}
proc cclosure_marshal_VOID_DOUBLE*(closure: PGClosure, return_value: PGValue,
                                      n_param_values: GUInt,
                                      param_values: PGValue,
                                      invocation_hint: GPointer,
                                      marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__DOUBLE".}
proc cclosure_marshal_VOID_STRING*(closure: PGClosure, return_value: PGValue,
                                      n_param_values: GUInt,
                                      param_values: PGValue,
                                      invocation_hint: GPointer,
                                      marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__STRING".}
proc cclosure_marshal_VOID_PARAM*(closure: PGClosure, return_value: PGValue,
                                     n_param_values: GUInt,
                                     param_values: PGValue,
                                     invocation_hint: GPointer,
                                     marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__PARAM".}
proc cclosure_marshal_VOID_BOXED*(closure: PGClosure, return_value: PGValue,
                                     n_param_values: GUInt,
                                     param_values: PGValue,
                                     invocation_hint: GPointer,
                                     marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__BOXED".}
proc cclosure_marshal_VOID_POINTER*(closure: PGClosure,
                                       return_value: PGValue,
                                       n_param_values: GUInt,
                                       param_values: PGValue,
                                       invocation_hint: GPointer,
                                       marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__POINTER".}
proc cclosure_marshal_VOID_OBJECT*(closure: PGClosure, return_value: PGValue,
                                      n_param_values: GUInt,
                                      param_values: PGValue,
                                      invocation_hint: GPointer,
                                      marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__OBJECT".}
proc cclosure_marshal_STRING_OBJECT_POINTER*(closure: PGClosure,
    return_value: PGValue, n_param_values: GUInt, param_values: PGValue,
    invocation_hint: GPointer, marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_STRING__OBJECT_POINTER".}
proc cclosure_marshal_VOID_UINT_POINTER*(closure: PGClosure,
    return_value: PGValue, n_param_values: GUInt, param_values: PGValue,
    invocation_hint: GPointer, marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_VOID__UINT_POINTER".}
proc cclosure_marshal_BOOLEAN_FLAGS*(closure: PGClosure,
                                        return_value: PGValue,
                                        n_param_values: GUInt,
                                        param_values: PGValue,
                                        invocation_hint: GPointer,
                                        marshal_data: GPointer){.cdecl,
    dynlib: gobjectlib, importc: "g_cclosure_marshal_BOOLEAN__FLAGS".}
proc cclosure_marshal_BOOL_FLAGS*(closure: PGClosure, return_value: PGValue,
                                     n_param_values: GUInt,
                                     param_values: PGValue,
                                     invocation_hint: GPointer,
                                     marshal_data: GPointer){.cdecl,
    dynlib: gliblib, importc: "g_cclosure_marshal_BOOLEAN__FLAGS".}
proc GUINT16_SWAP_LE_BE_CONSTANT*(val: guint16): guint16 =
  Result = ((val and 0x00FF'i16) shl 8'i16) or
      ((val and 0xFF00'i16) shr 8'i16)

proc GUINT32_SWAP_LE_BE_CONSTANT*(val: guint32): guint32 =
  Result = ((val and 0x000000FF'i32) shl 24'i32) or
      ((val and 0x0000FF00'i32) shl 8'i32) or
      ((val and 0x00FF0000'i32) shr 8'i32) or
      ((val and 0xFF000000'i32) shr 24'i32)

proc GUINT_TO_POINTER*(i: guint): pointer =
  Result = cast[Pointer](TAddress(i))

when false:
  type
    PGArray* = pointer
  proc g_array_append_val*(a: PGArray, v: gpointer): PGArray =
    result = g_array_append_vals(a, addr(v), 1)

  proc g_array_prepend_val*(a: PGArray, v: gpointer): PGArray =
    result = g_array_prepend_vals(a, addr(v), 1)

  proc g_array_insert_val*(a: PGArray, i: guint, v: gpointer): PGArray =
    result = g_array_insert_vals(a, i, addr(v), 1)

  proc g_ptr_array_index*(parray: PGPtrArray, index: guint): gpointer =
    result = cast[PGPointer](cast[int](parray []. pdata) +
        index * SizeOf(GPointer))[]

  proc G_THREAD_ERROR*(): TGQuark =
    result = g_thread_error_quark()

  proc g_mutex_lock*(mutex: PGMutex) =
    if g_threads_got_initialized:
      g_thread_functions_for_glib_use.mutex_lock(mutex)

  proc g_mutex_trylock*(mutex: PGMutex): gboolean =
    if g_threads_got_initialized:
      result = g_thread_functions_for_glib_use.mutex_trylock(mutex)
    else:
      result = true

  proc g_mutex_unlock*(mutex: PGMutex) =
    if g_threads_got_initialized:
      g_thread_functions_for_glib_use.mutex_unlock(mutex)

  proc g_mutex_free*(mutex: PGMutex) =
    if g_threads_got_initialized:
      g_thread_functions_for_glib_use.mutex_free(mutex)

  proc g_cond_wait*(cond: PGCond, mutex: PGMutex) =
    if g_threads_got_initialized:
      g_thread_functions_for_glib_use.cond_wait(cond, mutex)

  proc g_cond_timed_wait*(cond: PGCond, mutex: PGMutex, end_time: PGTimeVal): gboolean =
    if g_threads_got_initialized:
      result = g_thread_functions_for_glib_use.cond_timed_wait(cond, mutex,
          end_time)
    else:
      result = true

  proc g_thread_supported*(): gboolean =
    result = g_threads_got_initialized

  proc g_mutex_new*(): PGMutex =
    result = g_thread_functions_for_glib_use.mutex_new()

  proc g_cond_new*(): PGCond =
    result = g_thread_functions_for_glib_use.cond_new()

  proc g_cond_signal*(cond: PGCond) =
    if g_threads_got_initialized:
      g_thread_functions_for_glib_use.cond_signal(cond)

  proc g_cond_broadcast*(cond: PGCond) =
    if g_threads_got_initialized:
      g_thread_functions_for_glib_use.cond_broadcast(cond)

  proc g_cond_free*(cond: PGCond) =
    if g_threads_got_initialized:
      g_thread_functions_for_glib_use.cond_free(cond)

  proc g_private_new*(dest: TGDestroyNotify): PGPrivate =
    result = g_thread_functions_for_glib_use.private_new(dest)

  proc g_private_get*(private_key: PGPrivate): gpointer =
    if g_threads_got_initialized:
      result = g_thread_functions_for_glib_use.private_get(private_key)
    else:
      result = private_key

  proc g_private_set*(private_key: var PGPrivate, data: gpointer) =
    if g_threads_got_initialized:
      nil
    else:
      private_key = data

  proc g_thread_yield*() =
    if g_threads_got_initialized:
      g_thread_functions_for_glib_use.thread_yield

  proc g_thread_create*(func: TGThreadFunc, data: gpointer, joinable: gboolean,
                        error: pointer): PGThread =
    result = g_thread_create_full(func, data, 0, joinable, false,
                                  G_THREAD_PRIORITY_NORMAL, error)

  proc g_static_mutex_get_mutex*(mutex: PPGMutex): PGMutex =
    result = g_static_mutex_get_mutex_impl(mutex)

  proc g_static_mutex_lock*(mutex: PGStaticMutex) =
    g_mutex_lock(g_static_mutex_get_mutex_impl(PPGMutex(mutex)))

  proc g_static_mutex_trylock*(mutex: PGStaticMutex): gboolean =
    result = g_mutex_trylock(g_static_mutex_get_mutex(PPGMutex(mutex)))

  proc g_static_mutex_unlock*(mutex: PGStaticMutex) =
    g_mutex_unlock(g_static_mutex_get_mutex_impl(PPGMutex(mutex)))

  proc g_main_new*(is_running: gboolean): PGMainLoop =
    result = g_main_loop_new(nil, is_running)

  proc g_main_iteration*(may_block: gboolean): gboolean =
    result = g_main_context_iteration(nil, may_block)

  proc g_main_pending*(): gboolean =
    result = g_main_context_pending(nil)

  proc g_main_set_poll_func*(func: TGPollFunc) =
    g_main_context_set_poll_func(nil, func)

proc next*(slist: PGSList): PGSList =
  if slist != nil:
    result = slist.next
  else:
    result = nil

proc g_new*(bytes_per_struct, n_structs: int): gpointer =
  result = g_malloc(n_structs * bytes_per_struct)

proc g_new0*(bytes_per_struct, n_structs: int): gpointer =
  result = g_malloc0(n_structs * bytes_per_struct)

proc g_renew*(struct_size: int, OldMem: gpointer, n_structs: int): gpointer =
  result = g_realloc(OldMem, struct_size * n_structs)

proc g_chunk_new*(chunk: Pointer): Pointer =
  result = chunk_alloc(chunk)

proc g_chunk_new0*(chunk: Pointer): Pointer =
  result = chunk_alloc0(chunk)

proc previous*(list: PGList): PGList =
  if list != nil:
    result = list.prev
  else:
    result = nil

proc next*(list: PGList): PGList =
  if list != nil:
    result = list.next
  else:
    result = nil

proc G_CONVERT_ERROR*(): TGQuark =
  result = g_convert_error_quark()

proc g_datalist_id_set_data*(datalist: PPGData, key_id: TGQuark, data: gpointer) =
  g_datalist_id_set_data_full(datalist, key_id, data, TGDestroyNotify(nil))

proc g_datalist_id_remove_data*(datalist: PPGData, key_id: TGQuark) =
  g_datalist_id_set_data(datalist, key_id, nil)

proc g_datalist_get_data*(datalist: PPGData, key_str: cstring): PPGData =
  result = cast[PPGData](g_datalist_id_get_data(datalist,
      g_quark_try_string(key_str)))

proc g_datalist_set_data_full*(datalist: PPGData, key_str: cstring,
                               data: gpointer, destroy_func: TGDestroyNotify) =
  g_datalist_id_set_data_full(datalist, g_quark_from_string(key_str), data,
                              destroy_func)

proc g_datalist_set_data*(datalist: PPGData, key_str: cstring, data: gpointer) =
  g_datalist_set_data_full(datalist, key_str, data, nil)

proc g_datalist_remove_no_notify*(datalist: PPGData, key_str: cstring) =
  discard g_datalist_id_remove_no_notify(datalist, g_quark_try_string(key_str))

proc g_datalist_remove_data*(datalist: PPGData, key_str: cstring) =
  g_datalist_id_set_data(datalist, g_quark_try_string(key_str), nil)

proc g_dataset_id_set_data*(location: gconstpointer, key_id: TGQuark,
                            data: gpointer) =
  g_dataset_id_set_data_full(location, key_id, data, nil)

proc g_dataset_id_remove_data*(location: gconstpointer, key_id: TGQuark) =
  g_dataset_id_set_data(location, key_id, nil)

proc g_dataset_get_data*(location: gconstpointer, key_str: cstring): gpointer =
  result = g_dataset_id_get_data(location, g_quark_try_string(key_str))

proc g_dataset_set_data_full*(location: gconstpointer, key_str: cstring,
                              data: gpointer, destroy_func: TGDestroyNotify) =
  g_dataset_id_set_data_full(location, g_quark_from_string(key_str), data,
                             destroy_func)

proc g_dataset_remove_no_notify*(location: gconstpointer, key_str: cstring) =
  discard g_dataset_id_remove_no_notify(location, g_quark_try_string(key_str))

proc g_dataset_set_data*(location: gconstpointer, key_str: cstring,
                         data: gpointer) =
  g_dataset_set_data_full(location, key_str, data, nil)

proc g_dataset_remove_data*(location: gconstpointer, key_str: cstring) =
  g_dataset_id_set_data(location, g_quark_try_string(key_str), nil)

proc G_FILE_ERROR*(): TGQuark =
  result = g_file_error_quark()

proc TGHookList_hook_size*(a: PGHookList): guint =
  result = (a.flag0 and bm_TGHookList_hook_size) shr bp_TGHookList_hook_size

proc TGHookList_set_hook_size*(a: PGHookList, `hook_size`: guint) =
  a.flag0 = a.flag0 or
      ((`hook_size` shl bp_TGHookList_hook_size) and bm_TGHookList_hook_size)

proc TGHookList_is_setup*(a: PGHookList): guint =
  result = (a.flag0 and bm_TGHookList_is_setup) shr bp_TGHookList_is_setup

proc TGHookList_set_is_setup*(a: PGHookList, `is_setup`: guint) =
  a.flag0 = a.flag0 or
      ((`is_setup` shl bp_TGHookList_is_setup) and bm_TGHookList_is_setup)

proc G_HOOK*(hook: pointer): PGHook =
  result = cast[PGHook](hook)

proc FLAGS*(hook: PGHook): guint =
  result = hook.flags

proc ACTIVE*(hook: PGHook): bool =
  result = (hook.flags and G_HOOK_FLAG_ACTIVE) != 0'i32

proc IN_CALL*(hook: PGHook): bool =
  result = (hook.flags and G_HOOK_FLAG_IN_CALL) != 0'i32

proc IS_VALID*(hook: PGHook): bool =
  result = (hook.hook_id != 0) and ACTIVE(hook)

proc IS_UNLINKED*(hook: PGHook): bool =
  result = (hook.next == nil) and (hook.prev == nil) and (hook.hook_id == 0) and
      (hook.ref_count == 0'i32)

proc append*(hook_list: PGHookList, hook: PGHook) =
  insert_before(hook_list, nil, hook)

proc G_IO_CHANNEL_ERROR*(): TGQuark =
  result = g_io_channel_error_quark()

proc TGIOChannel_use_buffer*(a: PGIOChannel): guint =
  result = (a.flag0 and bm_TGIOChannel_use_buffer) shr
      bp_TGIOChannel_use_buffer

proc TGIOChannel_set_use_buffer*(a: PGIOChannel, `use_buffer`: guint) =
  a.flag0 = a.flag0 or
      (int16(`use_buffer` shl bp_TGIOChannel_use_buffer) and
      bm_TGIOChannel_use_buffer)

proc TGIOChannel_do_encode*(a: PGIOChannel): guint =
  result = (a.flag0 and bm_TGIOChannel_do_encode) shr
      bp_TGIOChannel_do_encode

proc TGIOChannel_set_do_encode*(a: PGIOChannel, `do_encode`: guint) =
  a.flag0 = a.flag0 or
      (int16(`do_encode` shl bp_TGIOChannel_do_encode) and
      bm_TGIOChannel_do_encode)

proc TGIOChannel_close_on_unref*(a: PGIOChannel): guint =
  result = (a.flag0 and bm_TGIOChannel_close_on_unref) shr
      bp_TGIOChannel_close_on_unref

proc TGIOChannel_set_close_on_unref*(a: PGIOChannel, `close_on_unref`: guint) =
  a.flag0 = a.flag0 or
      (int16(`close_on_unref` shl bp_TGIOChannel_close_on_unref) and
      bm_TGIOChannel_close_on_unref)

proc TGIOChannel_is_readable*(a: PGIOChannel): guint =
  result = (a.flag0 and bm_TGIOChannel_is_readable) shr
      bp_TGIOChannel_is_readable

proc TGIOChannel_set_is_readable*(a: PGIOChannel, `is_readable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_readable` shl bp_TGIOChannel_is_readable) and
      bm_TGIOChannel_is_readable)

proc TGIOChannel_is_writeable*(a: PGIOChannel): guint =
  result = (a.flag0 and bm_TGIOChannel_is_writeable) shr
      bp_TGIOChannel_is_writeable

proc TGIOChannel_set_is_writeable*(a: PGIOChannel, `is_writeable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_writeable` shl bp_TGIOChannel_is_writeable) and
      bm_TGIOChannel_is_writeable)

proc TGIOChannel_is_seekable*(a: PGIOChannel): guint =
  result = (a.flag0 and bm_TGIOChannel_is_seekable) shr
      bp_TGIOChannel_is_seekable

proc TGIOChannel_set_is_seekable*(a: PGIOChannel, `is_seekable`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_seekable` shl bp_TGIOChannel_is_seekable) and
      bm_TGIOChannel_is_seekable)

proc utf8_next_char*(p: pguchar): pguchar =
  result = cast[pguchar](cast[TAddress](p) + 1) # p + ord((g_utf8_skip + p[] )[] )

when false:
  proc GLIB_CHECK_VERSION*(major, minor, micro: guint): bool =
    result = ((GLIB_MAJOR_VERSION > major) or
        ((GLIB_MAJOR_VERSION == major) and (GLIB_MINOR_VERSION > minor)) or
        ((GLIB_MAJOR_VERSION == major) and (GLIB_MINOR_VERSION == minor) and
        (GLIB_MICRO_VERSION >= micro)))

  proc g_error*(format: cstring) =
    g_log(G_LOG_DOMAIN, G_LOG_LEVEL_ERROR, format)

  proc g_message*(format: cstring) =
    g_log(G_LOG_DOMAIN, G_LOG_LEVEL_MESSAGE, format)

  proc g_critical*(format: cstring) =
    g_log(G_LOG_DOMAIN, G_LOG_LEVEL_CRITICAL, format)

  proc g_warning*(format: cstring) =
    g_log(G_LOG_DOMAIN, G_LOG_LEVEL_WARNING, format)

proc G_MARKUP_ERROR*(): TGQuark =
  result = g_markup_error_quark()

proc IS_ROOT*(node: PGNode): bool =
  result = (node.parent == nil) and (node.next == nil) and (node.prev == nil)

proc IS_LEAF*(node: PGNode): bool =
  result = node.children == nil

proc append*(parent: PGNode, node: PGNode): PGNode =
  result = insert_before(parent, nil, node)

proc insert_data*(parent: PGNode, position: gint, data: gpointer): PGNode =
  result = insert(parent, position, g_node_new(data))

proc insert_data_before*(parent: PGNode, sibling: PGNode,
                         data: gpointer): PGNode =
  result = insert_before(parent, sibling, g_node_new(data))

proc prepend_data*(parent: PGNode, data: gpointer): PGNode =
  result = prepend(parent, g_node_new(data))

proc append_data*(parent: PGNode, data: gpointer): PGNode =
  result = insert_before(parent, nil, g_node_new(data))

proc prev_sibling*(node: PGNode): PGNode =
  if node != nil:
    result = node.prev
  else:
    result = nil

proc next_sibling*(node: PGNode): PGNode =
  if node != nil:
    result = node.next
  else:
    result = nil

proc first_child*(node: PGNode): PGNode =
  if node != nil:
    result = node.children
  else:
    result = nil

proc boolean*(rand: PGRand): gboolean =
  result = (int(rand_int(rand)) and (1 shl 15)) != 0

proc g_random_boolean*(): gboolean =
  result = (int(g_random_int()) and (1 shl 15)) != 0

proc TGScannerConfig_case_sensitive*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_case_sensitive) shr
      bp_TGScannerConfig_case_sensitive

proc TGScannerConfig_set_case_sensitive*(a: PGScannerConfig,
    `case_sensitive`: guint) =
  a.flag0 = a.flag0 or
      ((`case_sensitive` shl bp_TGScannerConfig_case_sensitive) and
      bm_TGScannerConfig_case_sensitive)

proc TGScannerConfig_skip_comment_multi*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_skip_comment_multi) shr
      bp_TGScannerConfig_skip_comment_multi

proc TGScannerConfig_set_skip_comment_multi*(a: PGScannerConfig,
    `skip_comment_multi`: guint) =
  a.flag0 = a.flag0 or
      ((`skip_comment_multi` shl bp_TGScannerConfig_skip_comment_multi) and
      bm_TGScannerConfig_skip_comment_multi)

proc TGScannerConfig_skip_comment_single*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_skip_comment_single) shr
      bp_TGScannerConfig_skip_comment_single

proc TGScannerConfig_set_skip_comment_single*(a: PGScannerConfig,
    `skip_comment_single`: guint) =
  a.flag0 = a.flag0 or
      ((`skip_comment_single` shl bp_TGScannerConfig_skip_comment_single) and
      bm_TGScannerConfig_skip_comment_single)

proc TGScannerConfig_scan_comment_multi*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scan_comment_multi) shr
      bp_TGScannerConfig_scan_comment_multi

proc TGScannerConfig_set_scan_comment_multi*(a: PGScannerConfig,
    `scan_comment_multi`: guint) =
  a.flag0 = a.flag0 or
      ((`scan_comment_multi` shl bp_TGScannerConfig_scan_comment_multi) and
      bm_TGScannerConfig_scan_comment_multi)

proc TGScannerConfig_scan_identifier*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scan_identifier) shr
      bp_TGScannerConfig_scan_identifier

proc TGScannerConfig_set_scan_identifier*(a: PGScannerConfig,
    `scan_identifier`: guint) =
  a.flag0 = a.flag0 or
      ((`scan_identifier` shl bp_TGScannerConfig_scan_identifier) and
      bm_TGScannerConfig_scan_identifier)

proc TGScannerConfig_scan_identifier_1char*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scan_identifier_1char) shr
      bp_TGScannerConfig_scan_identifier_1char

proc TGScannerConfig_set_scan_identifier_1char*(a: PGScannerConfig,
    `scan_identifier_1char`: guint) =
  a.flag0 = a.flag0 or
      ((`scan_identifier_1char` shl bp_TGScannerConfig_scan_identifier_1char) and
      bm_TGScannerConfig_scan_identifier_1char)

proc TGScannerConfig_scan_identifier_NULL*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scan_identifier_NULL) shr
      bp_TGScannerConfig_scan_identifier_NULL

proc TGScannerConfig_set_scan_identifier_NULL*(a: PGScannerConfig,
    `scan_identifier_NULL`: guint) =
  a.flag0 = a.flag0 or
      ((`scan_identifier_NULL` shl bp_TGScannerConfig_scan_identifier_NULL) and
      bm_TGScannerConfig_scan_identifier_NULL)

proc TGScannerConfig_scan_symbols*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scan_symbols) shr
      bp_TGScannerConfig_scan_symbols

proc TGScannerConfig_set_scan_symbols*(a: PGScannerConfig,
                                       `scan_symbols`: guint) =
  a.flag0 = a.flag0 or
      ((`scan_symbols` shl bp_TGScannerConfig_scan_symbols) and
      bm_TGScannerConfig_scan_symbols)

proc TGScannerConfig_scan_binary*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scan_binary) shr
      bp_TGScannerConfig_scan_binary

proc TGScannerConfig_set_scan_binary*(a: PGScannerConfig,
                                      `scan_binary`: guint) =
  a.flag0 = a.flag0 or
      ((`scan_binary` shl bp_TGScannerConfig_scan_binary) and
      bm_TGScannerConfig_scan_binary)

proc TGScannerConfig_scan_octal*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scan_octal) shr
      bp_TGScannerConfig_scan_octal

proc TGScannerConfig_set_scan_octal*(a: PGScannerConfig, `scan_octal`: guint) =
  a.flag0 = a.flag0 or
      ((`scan_octal` shl bp_TGScannerConfig_scan_octal) and
      bm_TGScannerConfig_scan_octal)

proc TGScannerConfig_scan_float*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scan_float) shr
      bp_TGScannerConfig_scan_float

proc TGScannerConfig_set_scan_float*(a: PGScannerConfig, `scan_float`: guint) =
  a.flag0 = a.flag0 or
      ((`scan_float` shl bp_TGScannerConfig_scan_float) and
      bm_TGScannerConfig_scan_float)

proc TGScannerConfig_scan_hex*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scan_hex) shr
      bp_TGScannerConfig_scan_hex

proc TGScannerConfig_set_scan_hex*(a: PGScannerConfig, `scan_hex`: guint) =
  a.flag0 = a.flag0 or
      ((`scan_hex` shl bp_TGScannerConfig_scan_hex) and
      bm_TGScannerConfig_scan_hex)

proc TGScannerConfig_scan_hex_dollar*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scan_hex_dollar) shr
      bp_TGScannerConfig_scan_hex_dollar

proc TGScannerConfig_set_scan_hex_dollar*(a: PGScannerConfig,
    `scan_hex_dollar`: guint) =
  a.flag0 = a.flag0 or
      ((`scan_hex_dollar` shl bp_TGScannerConfig_scan_hex_dollar) and
      bm_TGScannerConfig_scan_hex_dollar)

proc TGScannerConfig_scan_string_sq*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scan_string_sq) shr
      bp_TGScannerConfig_scan_string_sq

proc TGScannerConfig_set_scan_string_sq*(a: PGScannerConfig,
    `scan_string_sq`: guint) =
  a.flag0 = a.flag0 or
      ((`scan_string_sq` shl bp_TGScannerConfig_scan_string_sq) and
      bm_TGScannerConfig_scan_string_sq)

proc TGScannerConfig_scan_string_dq*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scan_string_dq) shr
      bp_TGScannerConfig_scan_string_dq

proc TGScannerConfig_set_scan_string_dq*(a: PGScannerConfig,
    `scan_string_dq`: guint) =
  a.flag0 = a.flag0 or
      ((`scan_string_dq` shl bp_TGScannerConfig_scan_string_dq) and
      bm_TGScannerConfig_scan_string_dq)

proc TGScannerConfig_numbers_2_int*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_numbers_2_int) shr
      bp_TGScannerConfig_numbers_2_int

proc TGScannerConfig_set_numbers_2_int*(a: PGScannerConfig,
                                        `numbers_2_int`: guint) =
  a.flag0 = a.flag0 or
      ((`numbers_2_int` shl bp_TGScannerConfig_numbers_2_int) and
      bm_TGScannerConfig_numbers_2_int)

proc TGScannerConfig_int_2_float*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_int_2_float) shr
      bp_TGScannerConfig_int_2_float

proc TGScannerConfig_set_int_2_float*(a: PGScannerConfig,
                                      `int_2_float`: guint) =
  a.flag0 = a.flag0 or
      ((`int_2_float` shl bp_TGScannerConfig_int_2_float) and
      bm_TGScannerConfig_int_2_float)

proc TGScannerConfig_identifier_2_string*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_identifier_2_string) shr
      bp_TGScannerConfig_identifier_2_string

proc TGScannerConfig_set_identifier_2_string*(a: PGScannerConfig,
    `identifier_2_string`: guint) =
  a.flag0 = a.flag0 or
      ((`identifier_2_string` shl bp_TGScannerConfig_identifier_2_string) and
      bm_TGScannerConfig_identifier_2_string)

proc TGScannerConfig_char_2_token*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_char_2_token) shr
      bp_TGScannerConfig_char_2_token

proc TGScannerConfig_set_char_2_token*(a: PGScannerConfig,
                                       `char_2_token`: guint) =
  a.flag0 = a.flag0 or
      ((`char_2_token` shl bp_TGScannerConfig_char_2_token) and
      bm_TGScannerConfig_char_2_token)

proc TGScannerConfig_symbol_2_token*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_symbol_2_token) shr
      bp_TGScannerConfig_symbol_2_token

proc TGScannerConfig_set_symbol_2_token*(a: PGScannerConfig,
    `symbol_2_token`: guint) =
  a.flag0 = a.flag0 or
      ((`symbol_2_token` shl bp_TGScannerConfig_symbol_2_token) and
      bm_TGScannerConfig_symbol_2_token)

proc TGScannerConfig_scope_0_fallback*(a: PGScannerConfig): guint =
  result = (a.flag0 and bm_TGScannerConfig_scope_0_fallback) shr
      bp_TGScannerConfig_scope_0_fallback

proc TGScannerConfig_set_scope_0_fallback*(a: PGScannerConfig,
    `scope_0_fallback`: guint) =
  a.flag0 = a.flag0 or
      ((`scope_0_fallback` shl bp_TGScannerConfig_scope_0_fallback) and
      bm_TGScannerConfig_scope_0_fallback)

proc freeze_symbol_table*(scanner: PGScanner) =
  if Scanner == nil: nil

proc thaw_symbol_table*(scanner: PGScanner) =
  if Scanner == nil: nil

proc G_SHELL_ERROR*(): TGQuark =
  result = g_shell_error_quark()

proc G_SPAWN_ERROR*(): TGQuark =
  result = g_spawn_error_quark()

when false:
  proc g_ascii_isalnum*(c: gchar): bool =
    result = ((g_ascii_table[guchar(c)]) and G_ASCII_ALNUM) != 0

  proc g_ascii_isalpha*(c: gchar): bool =
    result = ((g_ascii_table[guchar(c)]) and G_ASCII_ALPHA) != 0

  proc g_ascii_iscntrl*(c: gchar): bool =
    result = ((g_ascii_table[guchar(c)]) and G_ASCII_CNTRL) != 0

  proc g_ascii_isdigit*(c: gchar): bool =
    result = ((g_ascii_table[guchar(c)]) and G_ASCII_DIGIT) != 0

  proc g_ascii_isgraph*(c: gchar): bool =
    result = ((g_ascii_table[guchar(c)]) and G_ASCII_GRAPH) != 0

  proc g_ascii_islower*(c: gchar): bool =
    result = ((g_ascii_table[guchar(c)]) and G_ASCII_LOWER) != 0

  proc g_ascii_isprint*(c: gchar): bool =
    result = ((g_ascii_table[guchar(c)]) and G_ASCII_PRINT) != 0

  proc g_ascii_ispunct*(c: gchar): bool =
    result = ((g_ascii_table[guchar(c)]) and G_ASCII_PUNCT) != 0

  proc g_ascii_isspace*(c: gchar): bool =
    result = ((g_ascii_table[guchar(c)]) and G_ASCII_SPACE) != 0

  proc g_ascii_isupper*(c: gchar): bool =
    result = ((g_ascii_table[guchar(c)]) and G_ASCII_UPPER) != 0

  proc g_ascii_isxdigit*(c: gchar): bool =
    result = ((g_ascii_table[guchar(c)]) and G_ASCII_XDIGIT) != 0

  proc g_strstrip*(str: cstring): cstring =
    result = g_strchomp(g_strchug(str))

proc G_TYPE_MAKE_FUNDAMENTAL*(x: int): GType =
  result = GType(x shl G_TYPE_FUNDAMENTAL_SHIFT)

proc G_TYPE_IS_FUNDAMENTAL*(theType: GType): bool =
  result = theType <= G_TYPE_FUNDAMENTAL_MAX

proc G_TYPE_IS_DERIVED*(theType: GType): bool =
  result = theType > G_TYPE_FUNDAMENTAL_MAX

proc G_TYPE_IS_INTERFACE*(theType: GType): bool =
  result = (G_TYPE_FUNDAMENTAL(theType)) == G_TYPE_INTERFACE

proc G_TYPE_IS_CLASSED*(theType: GType): gboolean =
  result = private_g_type_test_flags(theType, G_TYPE_FLAG_CLASSED)

proc G_TYPE_IS_INSTANTIATABLE*(theType: GType): bool =
  result = private_g_type_test_flags(theType, G_TYPE_FLAG_INSTANTIATABLE)

proc G_TYPE_IS_DERIVABLE*(theType: GType): bool =
  result = private_g_type_test_flags(theType, G_TYPE_FLAG_DERIVABLE)

proc G_TYPE_IS_DEEP_DERIVABLE*(theType: GType): bool =
  result = private_g_type_test_flags(theType, G_TYPE_FLAG_DEEP_DERIVABLE)

proc G_TYPE_IS_ABSTRACT*(theType: GType): bool =
  result = private_g_type_test_flags(theType, G_TYPE_FLAG_ABSTRACT)

proc G_TYPE_IS_VALUE_ABSTRACT*(theType: GType): bool =
  result = private_g_type_test_flags(theType, G_TYPE_FLAG_VALUE_ABSTRACT)

proc G_TYPE_IS_VALUE_TYPE*(theType: GType): bool =
  result = private_g_type_check_is_value_type(theType)

proc G_TYPE_HAS_VALUE_TABLE*(theType: GType): bool =
  result = (g_type_value_table_peek(theType)) != nil

proc G_TYPE_CHECK_INSTANCE*(instance: Pointer): gboolean =
  result = private_g_type_check_instance(cast[PGTypeInstance](instance))

proc G_TYPE_CHECK_INSTANCE_CAST*(instance: Pointer, g_type: GType): PGTypeInstance =
  result = cast[PGTypeInstance](private_g_type_check_instance_cast(
      cast[PGTypeInstance](instance), g_type))

proc G_TYPE_CHECK_INSTANCE_TYPE*(instance: Pointer, g_type: GType): bool =
  result = private_g_type_check_instance_is_a(cast[PGTypeInstance](instance),
      g_type)

proc G_TYPE_INSTANCE_GET_CLASS*(instance: Pointer, g_type: GType): PGTypeClass =
  result = cast[PGTypeInstance](Instance).g_class
  result = private_g_type_check_class_cast(result, g_type)

proc G_TYPE_INSTANCE_GET_INTERFACE*(instance: Pointer, g_type: GType): Pointer =
  result = g_type_interface_peek((cast[PGTypeInstance](instance)).g_class,
                                 g_type)

proc G_TYPE_CHECK_CLASS_CAST*(g_class: pointer, g_type: GType): Pointer =
  result = private_g_type_check_class_cast(cast[PGTypeClass](g_class), g_type)

proc G_TYPE_CHECK_CLASS_TYPE*(g_class: pointer, g_type: GType): bool =
  result = private_g_type_check_class_is_a(cast[PGTypeClass](g_class), g_type)

proc G_TYPE_CHECK_VALUE*(value: Pointer): bool =
  result = private_g_type_check_value(cast[PGValue](Value))

proc G_TYPE_CHECK_VALUE_TYPE*(value: pointer, g_type: GType): bool =
  result = private_g_type_check_value_holds(cast[PGValue](value), g_type)

proc G_TYPE_FROM_INSTANCE*(instance: Pointer): GType =
  result = G_TYPE_FROM_CLASS((cast[PGTypeInstance](instance)).g_class)

proc G_TYPE_FROM_CLASS*(g_class: Pointer): GType =
  result = (cast[PGTypeClass](g_class)).g_type

proc G_TYPE_FROM_INTERFACE*(g_iface: Pointer): GType =
  result = (cast[PGTypeInterface](g_iface)).g_type

proc G_TYPE_IS_VALUE*(theType: GType): bool =
  result = private_g_type_check_is_value_type(theType)

proc G_IS_VALUE*(value: Pointer): bool =
  result = G_TYPE_CHECK_VALUE(value)

proc G_VALUE_TYPE*(value: Pointer): GType =
  result = (cast[PGValue](value)).g_type

proc G_VALUE_TYPE_NAME*(value: Pointer): cstring =
  result = g_type_name(G_VALUE_TYPE(value))

proc G_VALUE_HOLDS*(value: pointer, g_type: GType): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, g_type)

proc G_TYPE_IS_PARAM*(theType: GType): bool =
  result = (G_TYPE_FUNDAMENTAL(theType)) == G_TYPE_PARAM

proc G_PARAM_SPEC*(pspec: Pointer): PGParamSpec =
  result = cast[PGParamSpec](G_TYPE_CHECK_INSTANCE_CAST(pspec, G_TYPE_PARAM))

proc G_IS_PARAM_SPEC*(pspec: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(pspec, G_TYPE_PARAM)

proc G_PARAM_SPEC_CLASS*(pclass: Pointer): PGParamSpecClass =
  result = cast[PGParamSpecClass](G_TYPE_CHECK_CLASS_CAST(pclass, G_TYPE_PARAM))

proc G_IS_PARAM_SPEC_CLASS*(pclass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(pclass, G_TYPE_PARAM)

proc G_PARAM_SPEC_GET_CLASS*(pspec: Pointer): PGParamSpecClass =
  result = cast[PGParamSpecClass](G_TYPE_INSTANCE_GET_CLASS(pspec, G_TYPE_PARAM))

proc G_PARAM_SPEC_TYPE*(pspec: Pointer): GType =
  result = G_TYPE_FROM_INSTANCE(pspec)

proc G_PARAM_SPEC_TYPE_NAME*(pspec: Pointer): cstring =
  result = g_type_name(G_PARAM_SPEC_TYPE(pspec))

proc G_PARAM_SPEC_VALUE_TYPE*(pspec: Pointer): GType =
  result = (G_PARAM_SPEC(pspec)).value_type

proc G_VALUE_HOLDS_PARAM*(value: Pointer): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_PARAM)

proc G_CLOSURE_NEEDS_MARSHAL*(closure: Pointer): bool =
  result = cast[PGClosure](closure).marshal == nil

proc N_NOTIFIERS*(cl: PGClosure): int32 =
  result = ((meta_marshal(cl) + ((n_guards(cl)) shl 1'i32)) +
      (n_fnotifiers(cl))) + (n_inotifiers(cl))

proc CCLOSURE_SWAP_DATA*(cclosure: PGClosure): int32 =
  result = derivative_flag(cclosure)

proc G_CALLBACK*(f: pointer): TGCallback =
  result = cast[TGCallback](f)

proc ref_count*(a: PGClosure): guint =
  result = (a.flag0 and bm_TGClosure_ref_count) shr bp_TGClosure_ref_count

proc set_ref_count*(a: PGClosure, `ref_count`: guint) =
  a.flag0 = a.flag0 or
      ((`ref_count` shl bp_TGClosure_ref_count) and bm_TGClosure_ref_count)

proc meta_marshal*(a: PGClosure): guint =
  result = (a.flag0 and bm_TGClosure_meta_marshal) shr
      bp_TGClosure_meta_marshal

proc set_meta_marshal*(a: PGClosure, `meta_marshal`: guint) =
  a.flag0 = a.flag0 or
      ((`meta_marshal` shl bp_TGClosure_meta_marshal) and
      bm_TGClosure_meta_marshal)

proc n_guards*(a: PGClosure): guint =
  result = (a.flag0 and bm_TGClosure_n_guards) shr bp_TGClosure_n_guards

proc set_n_guards*(a: PGClosure, `n_guards`: guint) =
  a.flag0 = a.flag0 or
      ((`n_guards` shl bp_TGClosure_n_guards) and bm_TGClosure_n_guards)

proc n_fnotifiers*(a: PGClosure): guint =
  result = (a.flag0 and bm_TGClosure_n_fnotifiers) shr
      bp_TGClosure_n_fnotifiers

proc set_n_fnotifiers*(a: PGClosure, `n_fnotifiers`: guint) =
  a.flag0 = a.flag0 or
      ((`n_fnotifiers` shl bp_TGClosure_n_fnotifiers) and
      bm_TGClosure_n_fnotifiers)

proc n_inotifiers*(a: PGClosure): guint =
  result = (a.flag0 and bm_TGClosure_n_inotifiers) shr
      bp_TGClosure_n_inotifiers

proc set_n_inotifiers*(a: PGClosure, `n_inotifiers`: guint) =
  a.flag0 = a.flag0 or
      ((`n_inotifiers` shl bp_TGClosure_n_inotifiers) and
      bm_TGClosure_n_inotifiers)

proc in_inotify*(a: PGClosure): guint =
  result = (a.flag0 and bm_TGClosure_in_inotify) shr bp_TGClosure_in_inotify

proc set_in_inotify*(a: PGClosure, `in_inotify`: guint) =
  a.flag0 = a.flag0 or
      ((`in_inotify` shl bp_TGClosure_in_inotify) and bm_TGClosure_in_inotify)

proc floating*(a: PGClosure): guint =
  result = (a.flag0 and bm_TGClosure_floating) shr bp_TGClosure_floating

proc set_floating*(a: PGClosure, `floating`: guint) =
  a.flag0 = a.flag0 or
      ((`floating` shl bp_TGClosure_floating) and bm_TGClosure_floating)

proc derivative_flag*(a: PGClosure): guint =
  result = (a.flag0 and bm_TGClosure_derivative_flag) shr
      bp_TGClosure_derivative_flag

proc set_derivative_flag*(a: PGClosure, `derivative_flag`: guint) =
  a.flag0 = a.flag0 or
      ((`derivative_flag` shl bp_TGClosure_derivative_flag) and
      bm_TGClosure_derivative_flag)

proc in_marshal*(a: PGClosure): guint =
  result = (a.flag0 and bm_TGClosure_in_marshal) shr bp_TGClosure_in_marshal

proc set_in_marshal*(a: PGClosure, in_marshal: guint) =
  a.flag0 = a.flag0 or
      ((in_marshal shl bp_TGClosure_in_marshal) and bm_TGClosure_in_marshal)

proc is_invalid*(a: PGClosure): guint =
  result = (a.flag0 and bm_TGClosure_is_invalid) shr bp_TGClosure_is_invalid

proc set_is_invalid*(a: PGClosure, is_invalid: guint) =
  a.flag0 = a.flag0 or
      ((is_invalid shl bp_TGClosure_is_invalid) and bm_TGClosure_is_invalid)

proc g_signal_connect*(instance: gpointer, detailed_signal: cstring,
                       c_handler: TGCallback, data: gpointer): gulong =
  result = g_signal_connect_data(instance, detailed_signal, c_handler, data,
                                 nil, TGConnectFlags(0))

proc g_signal_connect_after*(instance: gpointer, detailed_signal: cstring,
                             c_handler: TGCallback, data: gpointer): gulong =
  result = g_signal_connect_data(instance, detailed_signal, c_handler, data,
                                 nil, G_CONNECT_AFTER)

proc g_signal_connect_swapped*(instance: gpointer, detailed_signal: cstring,
                               c_handler: TGCallback, data: gpointer): gulong =
  result = g_signal_connect_data(instance, detailed_signal, c_handler, data,
                                 nil, G_CONNECT_SWAPPED)

proc g_signal_handlers_disconnect_by_func*(instance: gpointer,
    func, data: gpointer): guint =
  result = g_signal_handlers_disconnect_matched(instance,
      TGSignalMatchType(G_SIGNAL_MATCH_FUNC or G_SIGNAL_MATCH_DATA), 0, 0, nil,
      func, data)

proc g_signal_handlers_block_by_func*(instance: gpointer, func, data: gpointer) =
  discard g_signal_handlers_block_matched(instance,
      TGSignalMatchType(G_SIGNAL_MATCH_FUNC or G_SIGNAL_MATCH_DATA), 0, 0, nil,
      func, data)

proc g_signal_handlers_unblock_by_func*(instance: gpointer, func, data: gpointer) =
  discard g_signal_handlers_unblock_matched(instance,
      TGSignalMatchType(G_SIGNAL_MATCH_FUNC or G_SIGNAL_MATCH_DATA), 0, 0, nil,
      func, data)

proc G_TYPE_IS_OBJECT*(theType: GType): bool =
  result = (G_TYPE_FUNDAMENTAL(theType)) == G_TYPE_OBJECT

proc G_OBJECT*(anObject: pointer): PGObject =
  result = cast[PGObject](G_TYPE_CHECK_INSTANCE_CAST(anObject, G_TYPE_OBJECT))

proc G_OBJECT_CLASS*(class: Pointer): PGObjectClass =
  result = cast[PGObjectClass](G_TYPE_CHECK_CLASS_CAST(class, G_TYPE_OBJECT))

proc G_IS_OBJECT*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, G_TYPE_OBJECT)

proc G_IS_OBJECT_CLASS*(class: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(class, G_TYPE_OBJECT)

proc G_OBJECT_GET_CLASS*(anObject: pointer): PGObjectClass =
  result = cast[PGObjectClass](G_TYPE_INSTANCE_GET_CLASS(anObject, G_TYPE_OBJECT))

proc G_OBJECT_TYPE*(anObject: pointer): GType =
  result = G_TYPE_FROM_INSTANCE(anObject)

proc G_OBJECT_TYPE_NAME*(anObject: pointer): cstring =
  result = g_type_name(G_OBJECT_TYPE(anObject))

proc G_OBJECT_CLASS_TYPE*(class: Pointer): GType =
  result = G_TYPE_FROM_CLASS(class)

proc G_OBJECT_CLASS_NAME*(class: Pointer): cstring =
  result = g_type_name(G_OBJECT_CLASS_TYPE(class))

proc G_VALUE_HOLDS_OBJECT*(value: Pointer): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_OBJECT)

proc G_OBJECT_WARN_INVALID_PROPERTY_ID*(anObject: gpointer, property_id: gint,
                                        pspec: gpointer) =
  G_OBJECT_WARN_INVALID_PSPEC(anObject, "property", property_id, pspec)

proc G_OBJECT_WARN_INVALID_PSPEC*(anObject: gpointer, pname: cstring,
                                  property_id: gint, pspec: gpointer) =
  var
    theObject: PGObject
    pspec2: PGParamSpec
    property_id: guint
  theObject = cast[PGObject](anObject)
  pspec2 = cast[PGParamSpec](pspec)
  property_id = (property_id)
  write(stdout, "invalid thingy\x0A")
  #g_warning("%s: invalid %s id %u for \"%s\" of type `%s\' in `%s\'", "", pname,
  #          `property_id`, `pspec` . name,
  #          g_type_name(G_PARAM_SPEC_TYPE(`pspec`)),
  #          G_OBJECT_TYPE_NAME(theobject))

proc G_TYPE_TYPE_PLUGIN*(): GType =
  result = g_type_plugin_get_type()

proc G_TYPE_PLUGIN*(inst: Pointer): PGTypePlugin =
  result = PGTypePlugin(G_TYPE_CHECK_INSTANCE_CAST(inst, G_TYPE_TYPE_PLUGIN()))

proc G_TYPE_PLUGIN_CLASS*(vtable: Pointer): PGTypePluginClass =
  result = cast[PGTypePluginClass](G_TYPE_CHECK_CLASS_CAST(vtable,
      G_TYPE_TYPE_PLUGIN()))

proc G_IS_TYPE_PLUGIN*(inst: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(inst, G_TYPE_TYPE_PLUGIN())

proc G_IS_TYPE_PLUGIN_CLASS*(vtable: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(vtable, G_TYPE_TYPE_PLUGIN())

proc G_TYPE_PLUGIN_GET_CLASS*(inst: Pointer): PGTypePluginClass =
  result = cast[PGTypePluginClass](G_TYPE_INSTANCE_GET_INTERFACE(inst,
      G_TYPE_TYPE_PLUGIN()))

proc G_TYPE_IS_ENUM*(theType: GType): gboolean =
  result = (G_TYPE_FUNDAMENTAL(theType) == G_TYPE_ENUM)

proc G_ENUM_CLASS*(class: pointer): PGEnumClass =
  result = cast[PGEnumClass](G_TYPE_CHECK_CLASS_CAST(class, G_TYPE_ENUM))

proc G_IS_ENUM_CLASS*(class: pointer): gboolean =
  result = G_TYPE_CHECK_CLASS_TYPE(class, G_TYPE_ENUM)

proc G_ENUM_CLASS_TYPE*(class: pointer): GType =
  result = G_TYPE_FROM_CLASS(class)

proc G_ENUM_CLASS_TYPE_NAME*(class: pointer): cstring =
  result = g_type_name(G_ENUM_CLASS_TYPE(class))

proc G_TYPE_IS_FLAGS*(theType: GType): gboolean =
  result = (G_TYPE_FUNDAMENTAL(theType)) == G_TYPE_FLAGS

proc G_FLAGS_CLASS*(class: pointer): PGFlagsClass =
  result = cast[PGFlagsClass](G_TYPE_CHECK_CLASS_CAST(class, G_TYPE_FLAGS))

proc G_IS_FLAGS_CLASS*(class: pointer): gboolean =
  result = G_TYPE_CHECK_CLASS_TYPE(class, G_TYPE_FLAGS)

proc G_FLAGS_CLASS_TYPE*(class: pointer): GType =
  result = G_TYPE_FROM_CLASS(class)

proc G_FLAGS_CLASS_TYPE_NAME*(class: pointer): cstring =
  result = g_type_name(G_FLAGS_TYPE(cast[TAddress](class)))

proc G_VALUE_HOLDS_ENUM*(value: pointer): gboolean =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_ENUM)

proc G_VALUE_HOLDS_FLAGS*(value: pointer): gboolean =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_FLAGS)

proc CLAMP*(x, MinX, MaxX: int): int =
  if x < MinX:
    result = MinX
  elif x > MaxX:
    result = MaxX
  else:
    result = x

proc GPOINTER_TO_SIZE*(p: GPointer): GSize =
  result = GSize(cast[TAddress](p))

proc GSIZE_TO_POINTER*(s: GSize): GPointer =
  result = cast[GPointer](s)

proc HOLDS_CHAR*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_CHAR)

proc HOLDS_UCHAR*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_UCHAR)

proc HOLDS_BOOLEAN*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_BOOLEAN)

proc HOLDS_INT*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_INT)

proc HOLDS_UINT*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_UINT)

proc HOLDS_LONG*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_LONG)

proc HOLDS_ULONG*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_ULONG)

proc HOLDS_INT64*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_INT64)

proc HOLDS_UINT64*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_UINT64)

proc HOLDS_FLOAT*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_FLOAT)

proc HOLDS_DOUBLE*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_DOUBLE)

proc HOLDS_STRING*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_STRING)

proc HOLDS_POINTER*(value: PGValue): bool =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_POINTER)

proc G_TYPE_IS_BOXED*(theType: GType): gboolean =
  result = (G_TYPE_FUNDAMENTAL(theType)) == G_TYPE_BOXED

proc HOLDS_BOXED*(value: PGValue): gboolean =
  result = G_TYPE_CHECK_VALUE_TYPE(value, G_TYPE_BOXED)

proc G_TYPE_CLOSURE*(): GType =
  result = g_closure_get_type()

proc G_TYPE_VALUE*(): GType =
  result = g_value_get_type()

proc G_TYPE_VALUE_ARRAY*(): GType =
  result = g_value_array_get_type()

proc G_TYPE_GSTRING*(): GType =
  result = g_gstring_get_type()

proc g_thread_init*(vtable: pointer) {.
  cdecl, dynlib: gobjectlib, importc: "g_thread_init".}

proc g_timeout_add*(interval: guint, function, data: gpointer): guint {.
  cdecl, dynlib: gliblib, importc: "g_timeout_add".}

proc g_timeout_add_full*(priority: guint, interval: guint, function,
  data, notify: gpointer): guint {.cdecl, dynlib: gliblib,
  importc: "g_timeout_add_full".}

proc g_idle_add*(function, data: gpointer): guint {.
  cdecl, dynlib: gliblib, importc: "g_idle_add".}

proc g_idle_add_full*(priority: guint, function,
  data, notify: gpointer): guint {.cdecl, dynlib: gliblib,
  importc: "g_idle_add_full".}

proc g_source_remove*(tag: guint): gboolean {.
  cdecl, dynlib: gliblib, importc: "g_source_remove".}

proc g_signal_emit_by_name*(instance: gpointer, detailed_signal: cstring) {.
  cdecl, varargs, dynlib: gobjectlib, importc.}
