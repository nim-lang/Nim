{.deadCodeElim: on.}
import
  glib2, gtk2

when defined(win32):
  const
    LibGladeLib = "libglade-2.0-0.dll"
elif defined(macosx):
  const
    LibGladeLib = "libglade-2.0.dylib"
else:
  const
    LibGladeLib = "libglade-2.0.so"
type
  PLongint* = ptr int32
  PSmallInt* = ptr int16
  PByte* = ptr int8
  PWord* = ptr int16
  PDWord* = ptr int32
  PDouble* = ptr float64

proc init*(){.cdecl, dynlib: LibGladeLib, importc: "glade_init".}
proc require*(TheLibrary: cstring){.cdecl, dynlib: LibGladeLib,
                                    importc: "glade_require".}
proc provide*(TheLibrary: cstring){.cdecl, dynlib: LibGladeLib,
                                    importc: "glade_provide".}
type
  PXMLPrivate* = pointer
  PXML* = ptr TXML
  TXML* = object of TGObject
    filename*: cstring
    priv*: PXMLPrivate

  PXMLClass* = ptr TXMLClass
  TXMLClass* = object of TGObjectClass
  TXMLConnectFunc* = proc (handler_name: cstring, anObject: PGObject,
                           signal_name: cstring, signal_data: cstring,
                           connect_object: PGObject, after: gboolean,
                           user_data: gpointer){.cdecl.}

proc TYPE_XML*(): GType
proc XML*(obj: pointer): PXML
proc XML_CLASS*(klass: pointer): PXMLClass
proc IS_XML*(obj: pointer): gboolean
proc IS_XML_CLASS*(klass: pointer): gboolean
proc XML_GET_CLASS*(obj: pointer): PXMLClass
proc xml_get_type*(): GType{.cdecl, dynlib: LibGladeLib,
                             importc: "glade_xml_get_type".}
proc xml_new*(fname: cstring, root: cstring, domain: cstring): PXML{.cdecl,
    dynlib: LibGladeLib, importc: "glade_xml_new".}
proc xml_new_from_buffer*(buffer: cstring, size: int32, root: cstring,
                          domain: cstring): PXML{.cdecl, dynlib: LibGladeLib,
    importc: "glade_xml_new_from_buffer".}
proc construct*(self: PXML, fname: cstring, root: cstring, domain: cstring): gboolean{.
    cdecl, dynlib: LibGladeLib, importc: "glade_xml_construct".}
proc signal_connect*(self: PXML, handlername: cstring, func: TGCallback){.
    cdecl, dynlib: LibGladeLib, importc: "glade_xml_signal_connect".}
proc signal_connect_data*(self: PXML, handlername: cstring,
                              func: TGCallback, user_data: gpointer){.cdecl,
    dynlib: LibGladeLib, importc: "glade_xml_signal_connect_data".}
proc signal_autoconnect*(self: PXML){.cdecl, dynlib: LibGladeLib,
    importc: "glade_xml_signal_autoconnect".}
proc signal_connect_full*(self: PXML, handler_name: cstring,
                              func: TXMLConnectFunc, user_data: gpointer){.
    cdecl, dynlib: LibGladeLib, importc: "glade_xml_signal_connect_full".}
proc signal_autoconnect_full*(self: PXML, func: TXMLConnectFunc,
                                  user_data: gpointer){.cdecl,
    dynlib: LibGladeLib, importc: "glade_xml_signal_autoconnect_full".}
proc get_widget*(self: PXML, name: cstring): gtk2.PWidget{.cdecl,
    dynlib: LibGladeLib, importc: "glade_xml_get_widget".}
proc get_widget_prefix*(self: PXML, name: cstring): PGList{.cdecl,
    dynlib: LibGladeLib, importc: "glade_xml_get_widget_prefix".}
proc relative_file*(self: PXML, filename: cstring): cstring{.cdecl,
    dynlib: LibGladeLib, importc: "glade_xml_relative_file".}
proc get_widget_name*(widget: gtk2.PWidget): cstring{.cdecl, dynlib: LibGladeLib,
    importc: "glade_get_widget_name".}
proc get_widget_tree*(widget: gtk2.PWidget): PXML{.cdecl, dynlib: LibGladeLib,
    importc: "glade_get_widget_tree".}
type
  PXMLCustomWidgetHandler* = ptr TXMLCustomWidgetHandler
  TXMLCustomWidgetHandler* = gtk2.TWidget

proc set_custom_handler*(handler: TXMLCustomWidgetHandler, user_data: gpointer){.
    cdecl, dynlib: LibGladeLib, importc: "glade_set_custom_handler".}
proc gnome_init*() =
  init()

proc bonobo_init*() =
  init()

proc xml_new_from_memory*(buffer: cstring, size: int32, root: cstring,
                          domain: cstring): PXML =
  result = xml_new_from_buffer(buffer, size, root, domain)

proc TYPE_XML*(): GType =
  result = xml_get_type()

proc XML*(obj: pointer): PXML =
  result = cast[PXML](G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_XML()))

proc XML_CLASS*(klass: pointer): PXMLClass =
  result = cast[PXMLClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_XML()))

proc IS_XML*(obj: pointer): gboolean =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_XML())

proc IS_XML_CLASS*(klass: pointer): gboolean =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_XML())

proc XML_GET_CLASS*(obj: pointer): PXMLClass =
  result = cast[PXMLClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_XML()))
