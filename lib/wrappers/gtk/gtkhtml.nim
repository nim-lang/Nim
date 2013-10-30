{.deadCodeElim: on.}
import
  gtk2, glib2, atk, pango, gdk2pixbuf, gdk2

when defined(windows):
  const
    htmllib = "libgtkhtml-win32-2.0-0.dll"
elif defined(macosx):
  const
    htmllib = "libgtkhtml-2.dylib"
else:
  const
    htmllib = "libgtkhtml-2.so"
const
  DOM_UNSPECIFIED_EVENT_TYPE_ERR* = 0
  DOM_INDEX_SIZE_ERR* = 1
  DOM_DOMSTRING_SIZE_ERR* = 2
  DOM_HIERARCHY_REQUEST_ERR* = 3
  DOM_WRONG_DOCUMENT_ERR* = 4
  DOM_INVALID_CHARACTER_ERR* = 5
  DOM_NO_DATA_ALLOWED_ERR* = 6
  DOM_NO_MODIFICATION_ALLOWED_ERR* = 7
  DOM_NOT_FOUND_ERR* = 8
  DOM_NOT_SUPPORTED_ERR* = 9
  DOM_INUSE_ATTRIBUTE_ERR* = 10
  DOM_INVALID_STATE_ERR* = 11
  DOM_SYNTAX_ERR* = 12
  DOM_INVALID_MODIFICATION_ERR* = 13
  DOM_NAMESPACE_ERR* = 14
  DOM_INVALID_ACCESS_ERR* = 15
  DOM_NO_EXCEPTION* = 255
  DOM_ELEMENT_NODE* = 1
  DOM_ATTRIBUTE_NODE* = 2
  DOM_TEXT_NODE* = 3
  DOM_CDATA_SECTION_NODE* = 4
  DOM_ENTITY_REFERENCE_NODE* = 5
  DOM_ENTITY_NODE* = 6
  DOM_PROCESSING_INSTRUCTION_NODE* = 7
  DOM_COMMENT_NODE* = 8
  DOM_DOCUMENT_NODE* = 9
  DOM_DOCUMENT_TYPE_NODE* = 10
  DOM_DOCUMENT_FRAGMENT_NODE* = 11
  DOM_NOTATION_NODE* = 12
  bm_HtmlFontSpecification_weight* = 0x0000000F
  bp_HtmlFontSpecification_weight* = 0
  bm_HtmlFontSpecification_style* = 0x00000030
  bp_HtmlFontSpecification_style* = 4
  bm_HtmlFontSpecification_variant* = 0x000000C0
  bp_HtmlFontSpecification_variant* = 6
  bm_HtmlFontSpecification_stretch* = 0x00000F00
  bp_HtmlFontSpecification_stretch* = 8
  bm_HtmlFontSpecification_decoration* = 0x00007000
  bp_HtmlFontSpecification_decoration* = 12

type
  TDomString* = gchar
  PDomString* = cstring
  TDomBoolean* = gboolean
  TDomException* = gushort
  TDomTimeStamp* = guint64
  PDomNode* = ptr TDomNode
  TDomNode* = object of TGObject
    xmlnode*: pointer
    style*: pointer

  PDomException* = ptr TDomException

  PDomNodeClass* = ptr TDomNodeClass
  TDomNodeClass* = object of TGObjectClass
    `get_nodeName`*: proc (node: PDomNode): PDomString{.cdecl.}
    `get_nodeValue`*: proc (node: PDomNode, exc: PDomException): PDomString{.
        cdecl.}
    `set_nodeValue`*: proc (node: PDomNode, value: PDomString,
                            exc: PDomException): PDomString{.cdecl.}

  PDomDocument* = ptr TDomDocument
  TDomDocument*{.final, pure.} = object
    parent*: PDomNode
    iterators*: PGSList

  PDomDocumentClass* = ptr TDomDocumentClass
  TDomDocumentClass*{.final, pure.} = object
    parent_class*: PDomNodeClass

  PHtmlFocusIterator* = ptr THtmlFocusIterator
  THtmlFocusIterator* = object of TGObject
    document*: PDomDocument
    current_node*: PDomNode

  PHtmlFocusIteratorClass* = ptr THtmlFocusIteratorClass
  THtmlFocusIteratorClass* = object of TGObjectClass
  THtmlParserType* = enum
    HTML_PARSER_TYPE_HTML, HTML_PARSER_TYPE_XML
  PHtmlParser* = ptr THtmlParser
  THtmlParser* = object of TGObject
    parser_type*: THtmlParserType
    document*: PHtmlDocument
    stream*: PHtmlStream
    xmlctxt*: pointer
    res*: int32
    chars*: array[0..9, char]
    blocking*: gboolean
    blocking_node*: PDomNode

  PHtmlParserClass* = ptr THtmlParserClass
  THtmlParserClass* = object of gtk2.TObjectClass
    done_parsing*: proc (parser: PHtmlParser){.cdecl.}
    new_node*: proc (parser: PHtmlParser, node: PDomNode)
    parsed_document_node*: proc (parser: PHtmlParser, document: PDomDocument)

  PHtmlStream* = ptr THtmlStream
  THtmlStreamCloseFunc* = proc (stream: PHtmlStream, user_data: gpointer){.cdecl.}
  THtmlStreamWriteFunc* = proc (stream: PHtmlStream, buffer: cstring,
                                size: guint, user_data: gpointer){.cdecl.}
  THtmlStreamCancelFunc* = proc (stream: PHtmlStream, user_data: gpointer,
                                 cancel_data: gpointer){.cdecl.}
  THtmlStream* = object of TGObject
    write_func*: THtmlStreamWriteFunc
    close_func*: THtmlStreamCloseFunc
    cancel_func*: THtmlStreamCancelFunc
    user_data*: gpointer
    cancel_data*: gpointer
    written*: gint
    mime_type*: cstring

  PHtmlStreamClass* = ptr THtmlStreamClass
  THtmlStreamClass* = object of TGObjectClass
  THtmlStreamBufferCloseFunc* = proc (str: cstring, len: gint,
                                      user_data: gpointer){.cdecl.}
  PHtmlContext* = ptr THtmlContext
  THtmlContext* = object of TGObject
    documents*: PGSList
    standard_font*: PHtmlFontSpecification
    fixed_font*: PHtmlFontSpecification
    debug_painting*: gboolean

  PHtmlFontSpecification* = ptr THtmlFontSpecification
  THtmlFontSpecification {.final, pure.} = object

  PHtmlContextClass* = ptr THtmlContextClass
  THtmlContextClass* = object of TGObjectClass
  THtmlDocumentState* = enum
    HTML_DOCUMENT_STATE_DONE, HTML_DOCUMENT_STATE_PARSING
  PHtmlDocument* = ptr THtmlDocument
  THtmlDocument* = object of TGObject
    stylesheets*: PGSList
    current_stream*: PHtmlStream
    state*: THtmlDocumentState

  PHtmlDocumentClass* = ptr THtmlDocumentClass
  THtmlDocumentClass* = object of TGObjectClass
    request_url*: proc (document: PHtmlDocument, url: cstring,
                        stream: PHtmlStream){.cdecl.}
    link_clicked*: proc (document: PHtmlDocument, url: cstring){.cdecl.}
    set_base*: proc (document: PHtmlDocument, url: cstring){.cdecl.}
    title_changed*: proc (document: PHtmlDocument, new_title: cstring){.cdecl.}
    submit*: proc (document: PHtmlDocument, `method`: cstring, url: cstring,
                   encoding: cstring){.cdecl.}

  PHtmlView* = ptr THtmlView
  THtmlView* = object of gtk2.TLayout
    document*: PHtmlDocument
    node_table*: PGHashTable
    relayout_idle_id*: guint
    relayout_timeout_id*: guint
    mouse_down_x*: gint
    mouse_down_y*: gint
    mouse_detail*: gint
    sel_start_ypos*: gint
    sel_start_index*: gint
    sel_end_ypos*: gint
    sel_end_index*: gint
    sel_flag*: gboolean
    sel_backwards*: gboolean
    sel_start_found*: gboolean
    sel_list*: PGSList
    jump_to_anchor*: cstring
    magnification*: gdouble
    magnification_modified*: gboolean
    on_url*: gboolean

  PHtmlViewClass* = ptr THtmlViewClass
  THtmlViewClass* = object of gtk2.TLayoutClass
    move_cursor*: proc (html_view: PHtmlView, step: TMovementStep, count: gint,
                        extend_selection: gboolean){.cdecl.}
    on_url*: proc (html_view: PHtmlView, url: cstring)
    activate*: proc (html_view: PHtmlView)
    move_focus_out*: proc (html_view: PHtmlView, direction: TDirectionType)

  PDomNodeList* = ptr TDomNodeList
  TDomNodeList {.pure, final.} = object

  PDomNamedNodeMap* = ptr TDomNamedNodeMap
  TDomNamedNodeMap {.pure, final.} = object

  PDomDocumentType* = ptr TDomDocumentType
  TDomDocumentType {.pure, final.} = object

  PDomElement* = ptr TDomElement
  TDomElement = object of TDomNode

  PDomText* = ptr TDomText
  TDomText = object of TDomNode

  PDomComment* = ptr TDomComment
  TDomComment = object of TDomNode

  THtmlBox {.pure, final.} = object
  PHtmlBox* = ptr THtmlBox


proc DOM_TYPE_NODE*(): GType
proc DOM_NODE*(theobject: pointer): PDomNode
proc DOM_NODE_CLASS*(klass: pointer): PDomNodeClass
proc DOM_IS_NODE*(theobject: pointer): bool
proc DOM_IS_NODE_CLASS*(klass: pointer): bool
proc DOM_NODE_GET_CLASS*(obj: pointer): int32
proc dom_node_get_type*(): GType{.cdecl, dynlib: htmllib,
                                  importc: "dom_node_get_type".}
proc dom_Node_mkref*(node: pointer): PDomNode{.cdecl, dynlib: htmllib,
    importc: "dom_Node_mkref".}
proc get_childNodes*(node: PDomNode): PDomNodeList{.cdecl,
    dynlib: htmllib, importc: "dom_Node__get_childNodes".}
proc removeChild*(node: PDomNode, oldChild: PDomNode,
                           exc: PDomException): PDomNode{.cdecl,
    dynlib: htmllib, importc: "dom_Node_removeChild".}
proc get_nodeValue*(node: PDomNode, exc: PDomException): PDomString{.
    cdecl, dynlib: htmllib, importc: "dom_Node__get_nodeValue".}
proc get_firstChild*(node: PDomNode): PDomNode{.cdecl,
    dynlib: htmllib, importc: "dom_Node__get_firstChild".}
proc get_nodeName*(node: PDomNode): PDomString{.cdecl,
    dynlib: htmllib, importc: "dom_Node__get_nodeName".}
proc get_attributes*(node: PDomNode): PDomNamedNodeMap{.cdecl,
    dynlib: htmllib, importc: "dom_Node__get_attributes".}
proc get_doctype*(doc: PDomDocument): PDomDocumentType{.cdecl,
    dynlib: htmllib, importc: "dom_Document__get_doctype".}
proc hasChildNodes*(node: PDomNode): bool{.cdecl,
    dynlib: htmllib, importc: "dom_Node_hasChildNodes".}
proc get_parentNode*(node: PDomNode): PDomNode{.cdecl,
    dynlib: htmllib, importc: "dom_Node__get_parentNode".}
proc get_nextSibling*(node: PDomNode): PDomNode{.cdecl,
    dynlib: htmllib, importc: "dom_Node__get_nextSibling".}
proc get_nodeType*(node: PDomNode): gushort{.cdecl, dynlib: htmllib,
    importc: "dom_Node__get_nodeType".}

proc cloneNode*(node: PDomNode, deep: bool): PDomNode{.cdecl,
    dynlib: htmllib, importc: "dom_Node_cloneNode".}
proc appendChild*(node: PDomNode, newChild: PDomNode,
                           exc: PDomException): PDomNode{.cdecl,
    dynlib: htmllib, importc: "dom_Node_appendChild".}
proc get_localName*(node: PDomNode): PDomString{.cdecl,
    dynlib: htmllib, importc: "dom_Node__get_localName".}
proc get_namespaceURI*(node: PDomNode): PDomString{.cdecl,
    dynlib: htmllib, importc: "dom_Node__get_namespaceURI".}
proc get_previousSibling*(node: PDomNode): PDomNode{.cdecl,
    dynlib: htmllib, importc: "dom_Node__get_previousSibling".}
proc get_lastChild*(node: PDomNode): PDomNode{.cdecl, dynlib: htmllib,
    importc: "dom_Node__get_lastChild".}
proc set_nodeValue*(node: PDomNode, value: PDomString,
                              exc: PDomException){.cdecl, dynlib: htmllib,
    importc: "dom_Node__set_nodeValue".}
proc get_ownerDocument*(node: PDomNode): PDomDocument{.cdecl,
    dynlib: htmllib, importc: "dom_Node__get_ownerDocument".}
proc hasAttributes*(node: PDomNode): gboolean{.cdecl, dynlib: htmllib,
    importc: "dom_Node_hasAttributes".}
proc DOM_TYPE_DOCUMENT*(): GType
proc DOM_DOCUMENT*(theobject: pointer): PDomDocument
proc DOM_DOCUMENT_CLASS*(klass: pointer): PDomDocumentClass
proc DOM_IS_DOCUMENT*(theobject: pointer): bool
proc DOM_IS_DOCUMENT_CLASS*(klass: pointer): bool
proc DOM_DOCUMENT_GET_CLASS*(obj: pointer): PDomDocumentClass
proc dom_document_get_type*(): GType
proc get_documentElement*(doc: PDomDocument): PDomElement
proc createElement*(doc: PDomDocument, tagName: PDomString): PDomElement
proc createTextNode*(doc: PDomDocument, data: PDomString): PDomText
proc createComment*(doc: PDomDocument, data: PDomString): PDomComment
proc importNode*(doc: PDomDocument, importedNode: PDomNode,
                              deep: bool, exc: PDomException): PDomNode
proc HTML_TYPE_FOCUS_ITERATOR*(): GType
proc HTML_FOCUS_ITERATOR*(theobject: pointer): PHtmlFocusIterator
proc HTML_FOCUS_ITERATOR_CLASS*(klass: pointer): PHtmlFocusIteratorClass
proc HTML_IS_FOCUS_ITERATOR*(theobject: pointer): bool
proc HTML_IS_FOCUS_ITERATOR_CLASS*(klass: pointer): bool
proc HTML_FOCUS_ITERATOR_GET_CLASS*(obj: pointer): PHtmlFocusIteratorClass
proc html_focus_iterator_next_element*(document: PDomDocument,
                                       element: PDomElement): PDomElement{.
    cdecl, dynlib: htmllib, importc: "html_focus_iterator_next_element".}
proc html_focus_iterator_prev_element*(document: PDomDocument,
                                       element: PDomElement): PDomElement{.
    cdecl, dynlib: htmllib, importc: "html_focus_iterator_prev_element".}
proc HTML_PARSER_TYPE*(): GType
proc HTML_PARSER*(obj: pointer): PHtmlParser
proc HTML_PARSER_CLASS*(klass: pointer): PHtmlParserClass
proc HTML_IS_PARSER*(obj: pointer): bool
proc html_parser_get_type*(): GType
proc parser_new*(document: PHtmlDocument, parser_type: THtmlParserType): PHtmlParser
proc HTML_TYPE_STREAM*(): GType
proc HTML_STREAM*(obj: pointer): PHtmlStream
proc HTML_STREAM_CLASS*(klass: pointer): PHtmlStreamClass
proc HTML_IS_STREAM*(obj: pointer): bool
proc HTML_IS_STREAM_CLASS*(klass: pointer): bool
proc HTML_STREAM_GET_CLASS*(obj: pointer): PHtmlStreamClass
proc html_stream_get_type*(): GType{.cdecl, dynlib: htmllib,
                                     importc: "html_stream_get_type".}
proc html_stream_new*(write_func: THtmlStreamWriteFunc,
                      close_func: THtmlStreamCloseFunc, user_data: gpointer): PHtmlStream{.
    cdecl, dynlib: htmllib, importc: "html_stream_new".}
proc write*(stream: PHtmlStream, buffer: cstring, size: guint){.
    cdecl, dynlib: htmllib, importc: "html_stream_write".}
proc close*(stream: PHtmlStream){.cdecl, dynlib: htmllib,
    importc: "html_stream_close".}
proc destroy*(stream: PHtmlStream){.cdecl, dynlib: htmllib,
    importc: "html_stream_destroy".}
proc get_written*(stream: PHtmlStream): gint{.cdecl,
    dynlib: htmllib, importc: "html_stream_get_written".}
proc cancel*(stream: PHtmlStream){.cdecl, dynlib: htmllib,
    importc: "html_stream_cancel".}
proc set_cancel_func*(stream: PHtmlStream,
                                  abort_func: THtmlStreamCancelFunc,
                                  cancel_data: gpointer){.cdecl,
    dynlib: htmllib, importc: "html_stream_set_cancel_func".}
proc get_mime_type*(stream: PHtmlStream): cstring{.cdecl,
    dynlib: htmllib, importc: "html_stream_get_mime_type".}
proc set_mime_type*(stream: PHtmlStream, mime_type: cstring){.cdecl,
    dynlib: htmllib, importc: "html_stream_set_mime_type".}
proc html_stream_buffer_new*(close_func: THtmlStreamBufferCloseFunc,
                             user_data: gpointer): PHtmlStream{.cdecl,
    dynlib: htmllib, importc: "html_stream_buffer_new".}
proc event_mouse_move*(view: PHtmlView, event: Gdk2.PEventMotion){.cdecl,
    dynlib: htmllib, importc: "html_event_mouse_move".}
proc event_button_press*(view: PHtmlView, button: Gdk2.PEventButton){.cdecl,
    dynlib: htmllib, importc: "html_event_button_press".}
proc event_button_release*(view: PHtmlView, event: Gdk2.PEventButton){.cdecl,
    dynlib: htmllib, importc: "html_event_button_release".}
proc event_activate*(view: PHtmlView){.cdecl, dynlib: htmllib,
    importc: "html_event_activate".}
proc event_key_press*(view: PHtmlView, event: Gdk2.PEventKey): gboolean{.
    cdecl, dynlib: htmllib, importc: "html_event_key_press".}
proc event_find_root_box*(self: PHtmlBox, x: gint, y: gint): PHtmlBox{.
    cdecl, dynlib: htmllib, importc: "html_event_find_root_box".}
proc selection_start*(view: PHtmlView, event: Gdk2.PEventButton){.cdecl,
    dynlib: htmllib, importc: "html_selection_start".}
proc selection_end*(view: PHtmlView, event: Gdk2.PEventButton){.cdecl,
    dynlib: htmllib, importc: "html_selection_end".}
proc selection_update*(view: PHtmlView, event: Gdk2.PEventMotion){.cdecl,
    dynlib: htmllib, importc: "html_selection_update".}
proc selection_clear*(view: PHtmlView){.cdecl, dynlib: htmllib,
    importc: "html_selection_clear".}
proc selection_set*(view: PHtmlView, start: PDomNode, offset: int32,
                         len: int32){.cdecl, dynlib: htmllib,
                                      importc: "html_selection_set".}
proc HTML_CONTEXT_TYPE*(): GType
proc HTML_CONTEXT*(obj: pointer): PHtmlContext
proc HTML_CONTEXT_CLASS*(klass: pointer): PHtmlContextClass
proc HTML_IS_CONTEXT*(obj: pointer): bool
proc HTML_IS_CONTEXT_CLASS*(klass: pointer): bool
proc html_context_get_type*(): GType
proc html_context_get*(): PHtmlContext
proc HTML_TYPE_DOCUMENT*(): GType
proc HTML_DOCUMENT*(obj: pointer): PHtmlDocument
proc HTML_DOCUMENT_CLASS*(klass: pointer): PHtmlDocumentClass
proc HTML_IS_DOCUMENT*(obj: pointer): bool
proc html_document_get_type*(): GType{.cdecl, dynlib: htmllib,
                                       importc: "html_document_get_type".}
proc html_document_new*(): PHtmlDocument{.cdecl, dynlib: htmllib,
    importc: "html_document_new".}
proc open_stream*(document: PHtmlDocument, mime_type: cstring): gboolean{.
    cdecl, dynlib: htmllib, importc: "html_document_open_stream".}
proc write_stream*(document: PHtmlDocument, buffer: cstring,
                                 len: gint){.cdecl, dynlib: htmllib,
    importc: "html_document_write_stream".}
proc close_stream*(document: PHtmlDocument){.cdecl,
    dynlib: htmllib, importc: "html_document_close_stream".}
proc clear*(document: PHtmlDocument){.cdecl, dynlib: htmllib,
    importc: "html_document_clear".}
proc HTML_TYPE_VIEW*(): GType
proc HTML_VIEW*(obj: pointer): PHtmlView
proc HTML_VIEW_CLASS*(klass: pointer): PHtmlViewClass
proc HTML_IS_VIEW*(obj: pointer): bool
proc html_view_get_type*(): GType{.cdecl, dynlib: htmllib,
                                   importc: "html_view_get_type".}
proc html_view_new*(): PWidget{.cdecl, dynlib: htmllib, importc: "html_view_new".}
proc set_document*(view: PHtmlView, document: PHtmlDocument){.cdecl,
    dynlib: htmllib, importc: "html_view_set_document".}
proc jump_to_anchor*(view: PHtmlView, anchor: cstring){.cdecl,
    dynlib: htmllib, importc: "html_view_jump_to_anchor".}
proc get_magnification*(view: PHtmlView): gdouble{.cdecl,
    dynlib: htmllib, importc: "html_view_get_magnification".}
proc set_magnification*(view: PHtmlView, magnification: gdouble){.
    cdecl, dynlib: htmllib, importc: "html_view_set_magnification".}
proc zoom_in*(view: PHtmlView){.cdecl, dynlib: htmllib,
    importc: "html_view_zoom_in".}
proc zoom_out*(view: PHtmlView){.cdecl, dynlib: htmllib,
    importc: "html_view_zoom_out".}
proc zoom_reset*(view: PHtmlView){.cdecl, dynlib: htmllib,
    importc: "html_view_zoom_reset".}

proc DOM_TYPE_NODE*(): GType =
  result = dom_node_get_type()

proc DOM_NODE*(theobject: pointer): PDomNode =
  result = G_TYPE_CHECK_INSTANCE_CAST(theobject, DOM_TYPE_NODE())

proc DOM_NODE_CLASS*(klass: pointer): PDomNodeClass =
  result = G_TYPE_CHECK_CLASS_CAST(klass, DOM_TYPE_NODE(), TDomNodeClass)

proc DOM_IS_NODE*(theobject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(theobject, DOM_TYPE_NODE())

proc DOM_IS_NODE_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, DOM_TYPE_NODE())

proc DOM_NODE_GET_CLASS*(obj: pointer): PDomNodeClass =
  result = G_TYPE_INSTANCE_GET_CLASS(obj, DOM_TYPE_NODE(), TDomNodeClass)

proc DOM_TYPE_DOCUMENT*(): GType =
  result = dom_document_get_type()

proc DOM_DOCUMENT*(theobject: pointer): PDomDocument =
  result = G_TYPE_CHECK_INSTANCE_CAST(theobject, DOM_TYPE_DOCUMENT(),
                                      TDomDocument)

proc DOM_DOCUMENT_CLASS*(klass: pointer): PDomDocumentClass =
  result = G_TYPE_CHECK_CLASS_CAST(klass, DOM_TYPE_DOCUMENT(), TDomDocumentClass)

proc DOM_IS_DOCUMENT*(theobject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(theobject, DOM_TYPE_DOCUMENT())

proc DOM_IS_DOCUMENT_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, DOM_TYPE_DOCUMENT())

proc DOM_DOCUMENT_GET_CLASS*(obj: pointer): PDomDocumentClass =
  result = G_TYPE_INSTANCE_GET_CLASS(obj, DOM_TYPE_DOCUMENT(), TDomDocumentClass)

proc HTML_TYPE_FOCUS_ITERATOR*(): GType =
  result = html_focus_iterator_get_type()

proc HTML_FOCUS_ITERATOR*(theobject: pointer): PHtmlFocusIterator =
  result = G_TYPE_CHECK_INSTANCE_CAST(theobject, HTML_TYPE_FOCUS_ITERATOR(),
                                      HtmlFocusIterator)

proc HTML_FOCUS_ITERATOR_CLASS*(klass: pointer): PHtmlFocusIteratorClass =
  result = G_TYPE_CHECK_CLASS_CAST(klass, HTML_TYPE_FOCUS_ITERATOR(),
                                   HtmlFocusIteratorClass)

proc HTML_IS_FOCUS_ITERATOR*(theobject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(theobject, HTML_TYPE_FOCUS_ITERATOR())

proc HTML_IS_FOCUS_ITERATOR_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, HTML_TYPE_FOCUS_ITERATOR())

proc HTML_FOCUS_ITERATOR_GET_CLASS*(obj: pointer): PHtmlFocusIteratorClass =
  result = G_TYPE_INSTANCE_GET_CLASS(obj, HTML_TYPE_FOCUS_ITERATOR(),
                                     HtmlFocusIteratorClass)

proc HTML_PARSER_TYPE*(): GType =
  result = html_parser_get_type()

proc HTML_PARSER*(obj: pointer): PHtmlParser =
  result = CHECK_CAST(obj, HTML_PARSER_TYPE(), THtmlParser)

proc HTML_PARSER_CLASS*(klass: pointer): PHtmlParserClass =
  result = CHECK_CLASS_CAST(klass, HTML_PARSER_TYPE(), THtmlParserClass)

proc HTML_IS_PARSER*(obj: pointer): bool =
  result = CHECK_TYPE(obj, HTML_PARSER_TYPE())

proc HTML_TYPE_STREAM*(): GType =
  result = html_stream_get_type()

proc HTML_STREAM*(obj: pointer): PHtmlStream =
  result = PHtmlStream(G_TYPE_CHECK_INSTANCE_CAST(obj, HTML_TYPE_STREAM()))

proc HTML_STREAM_CLASS*(klass: pointer): PHtmlStreamClass =
  result = G_TYPE_CHECK_CLASS_CAST(klass, HTML_TYPE_STREAM())

proc HTML_IS_STREAM*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, HTML_TYPE_STREAM())

proc HTML_IS_STREAM_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, HTML_TYPE_STREAM())

proc HTML_STREAM_GET_CLASS*(obj: pointer): PHtmlStreamClass =
  result = PHtmlStreamClass(G_TYPE_INSTANCE_GET_CLASS(obj, HTML_TYPE_STREAM()))

proc HTML_CONTEXT_TYPE*(): GType =
  result = html_context_get_type()

proc HTML_CONTEXT*(obj: pointer): PHtmlContext =
  result = CHECK_CAST(obj, HTML_CONTEXT_TYPE(), THtmlContext)

proc HTML_CONTEXT_CLASS*(klass: pointer): PHtmlContextClass =
  result = CHECK_CLASS_CAST(klass, HTML_CONTEXT_TYPE(), THtmlContextClass)

proc HTML_IS_CONTEXT*(obj: pointer): bool =
  result = CHECK_TYPE(obj, HTML_CONTEXT_TYPE())

proc HTML_IS_CONTEXT_CLASS*(klass: pointer): bool =
  result = CHECK_CLASS_TYPE(klass, HTML_CONTEXT_TYPE())

proc HTML_TYPE_DOCUMENT*(): GType =
  result = html_document_get_type()

proc HTML_DOCUMENT*(obj: pointer): PHtmlDocument =
  result = PHtmlDocument(CHECK_CAST(obj, HTML_TYPE_DOCUMENT()))

proc HTML_DOCUMENT_CLASS*(klass: pointer): PHtmlDocumentClass =
  result = CHECK_CLASS_CAST(klass, HTML_TYPE_DOCUMENT())

proc HTML_IS_DOCUMENT*(obj: pointer): bool =
  result = CHECK_TYPE(obj, HTML_TYPE_DOCUMENT())

proc HTML_TYPE_VIEW*(): GType =
  result = html_view_get_type()

proc HTML_VIEW*(obj: pointer): PHtmlView =
  result = PHtmlView(CHECK_CAST(obj, HTML_TYPE_VIEW()))

proc HTML_VIEW_CLASS*(klass: pointer): PHtmlViewClass =
  result = PHtmlViewClass(CHECK_CLASS_CAST(klass, HTML_TYPE_VIEW()))

proc HTML_IS_VIEW*(obj: pointer): bool =
  result = CHECK_TYPE(obj, HTML_TYPE_VIEW())
