import 
  glib2, gtk2

when defined(win32): 
  {.define: gtkwin.}
  const 
    LibGladeLib = "libglade-2.0-0.dll"
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

proc glade_init*(){.cdecl, dynlib: LibGladeLib, importc: "glade_init".}
proc glade_require*(TheLibrary: cstring){.cdecl, dynlib: LibGladeLib, 
    importc: "glade_require".}
proc glade_provide*(TheLibrary: cstring){.cdecl, dynlib: LibGladeLib, 
    importc: "glade_provide".}
type 
  PGladeXMLPrivate* = pointer
  PGladeXML* = ptr TGladeXML
  TGladeXML* = object of TGObject
    filename*: cstring
    priv*: PGladeXMLPrivate

  PGladeXMLClass* = ptr TGladeXMLClass
  TGladeXMLClass* = object of TGObjectClass

  TGladeXMLConnectFunc* = proc (handler_name: cstring, anObject: PGObject, 
                                signal_name: cstring, signal_data: cstring, 
                                connect_object: PGObject, after: gboolean, 
                                user_data: gpointer){.cdecl.}

proc GLADE_TYPE_XML*(): GType
proc GLADE_XML*(obj: pointer): PGladeXML
proc GLADE_XML_CLASS*(klass: pointer): PGladeXMLClass
proc GLADE_IS_XML*(obj: pointer): gboolean
proc GLADE_IS_XML_CLASS*(klass: pointer): gboolean
proc GLADE_XML_GET_CLASS*(obj: pointer): PGladeXMLClass
proc glade_xml_get_type*(): GType{.cdecl, dynlib: LibGladeLib, 
                                   importc: "glade_xml_get_type".}
proc glade_xml_new*(fname: cstring, root: cstring, domain: cstring): PGladeXML{.
    cdecl, dynlib: LibGladeLib, importc: "glade_xml_new".}
proc glade_xml_new_from_buffer*(buffer: cstring, size: int32, root: cstring, 
                                domain: cstring): PGladeXML{.cdecl, 
    dynlib: LibGladeLib, importc: "glade_xml_new_from_buffer".}
proc glade_xml_construct*(self: PGladeXML, fname: cstring, root: cstring, 
                          domain: cstring): gboolean{.cdecl, 
    dynlib: LibGladeLib, importc: "glade_xml_construct".}
proc glade_xml_signal_connect*(self: PGladeXML, handlername: cstring, 
                               func: TGCallback){.cdecl, dynlib: LibGladeLib, 
    importc: "glade_xml_signal_connect".}
proc glade_xml_signal_connect_data*(self: PGladeXML, handlername: cstring, 
                                    func: TGCallback, user_data: gpointer){.
    cdecl, dynlib: LibGladeLib, importc: "glade_xml_signal_connect_data".}
proc glade_xml_signal_autoconnect*(self: PGladeXML){.cdecl, dynlib: LibGladeLib, 
    importc: "glade_xml_signal_autoconnect".}
proc glade_xml_signal_connect_full*(self: PGladeXML, handler_name: cstring, 
                                    func: TGladeXMLConnectFunc, 
                                    user_data: gpointer){.cdecl, 
    dynlib: LibGladeLib, importc: "glade_xml_signal_connect_full".}
proc glade_xml_signal_autoconnect_full*(self: PGladeXML, 
                                        func: TGladeXMLConnectFunc, 
                                        user_data: gpointer){.cdecl, 
    dynlib: LibGladeLib, importc: "glade_xml_signal_autoconnect_full".}
proc glade_xml_get_widget*(self: PGladeXML, name: cstring): PGtkWidget{.cdecl, 
    dynlib: LibGladeLib, importc: "glade_xml_get_widget".}
proc glade_xml_get_widget_prefix*(self: PGladeXML, name: cstring): PGList{.
    cdecl, dynlib: LibGladeLib, importc: "glade_xml_get_widget_prefix".}
proc glade_xml_relative_file*(self: PGladeXML, filename: cstring): cstring{.cdecl, 
    dynlib: LibGladeLib, importc: "glade_xml_relative_file".}
proc glade_get_widget_name*(widget: PGtkWidget): cstring{.cdecl, 
    dynlib: LibGladeLib, importc: "glade_get_widget_name".}
proc glade_get_widget_tree*(widget: PGtkWidget): PGladeXML{.cdecl, 
    dynlib: LibGladeLib, importc: "glade_get_widget_tree".}
type 
  PGladeXMLCustomWidgetHandler* = ptr TGladeXMLCustomWidgetHandler
  TGladeXMLCustomWidgetHandler* = TGtkWidget

proc glade_set_custom_handler*(handler: TGladeXMLCustomWidgetHandler, 
                               user_data: gpointer){.cdecl, dynlib: LibGladeLib, 
    importc: "glade_set_custom_handler".}
proc glade_gnome_init*() = 
  glade_init()

proc glade_bonobo_init*() = 
  glade_init()

proc glade_xml_new_with_domain*(fname: cstring, root: cstring, domain: cstring): PGladeXML = 
  result = glade_xml_new(fname, root, domain)

proc glade_xml_new_from_memory*(buffer: cstring, size: int32, root: cstring, 
                                domain: cstring): PGladeXML = 
  result = glade_xml_new_from_buffer(buffer, size, root, domain)

proc GLADE_TYPE_XML*(): GType = 
  result = glade_xml_get_type()

proc GLADE_XML*(obj: pointer): PGladeXML = 
  result = cast[PGladeXML](G_TYPE_CHECK_INSTANCE_CAST(obj, GLADE_TYPE_XML()))

proc GLADE_XML_CLASS*(klass: pointer): PGladeXMLClass = 
  result = cast[PGladeXMLClass](G_TYPE_CHECK_CLASS_CAST(klass, GLADE_TYPE_XML()))

proc GLADE_IS_XML*(obj: pointer): gboolean = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GLADE_TYPE_XML())

proc GLADE_IS_XML_CLASS*(klass: pointer): gboolean = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GLADE_TYPE_XML())

proc GLADE_XML_GET_CLASS*(obj: pointer): PGladeXMLClass = 
  result = cast[PGladeXMLClass](G_TYPE_INSTANCE_GET_CLASS(obj, GLADE_TYPE_XML()))
