# Copyright (c) 1998, 1999, 2000 Thai Open Source Software Center Ltd
#   See the file COPYING for copying permission.
#

when not defined(expatDll):
  when defined(windows):
    const
      expatDll = "expat.dll"
  elif defined(macosx):
    const
      expatDll = "libexpat.dylib"
  else:
    const
      expatDll = "libexpat.so(.1|)"
type
  TParserStruct{.pure, final.} = object

  PParser* = ptr TParserStruct

# The XML_Status enum gives the possible return values for several
#   API functions.  The preprocessor #defines are included so this
#   stanza can be added to code that still needs to support older
#   versions of Expat 1.95.x:
#
#   #ifndef XML_STATUS_OK
#   #define XML_STATUS_OK    1
#   #define XML_STATUS_ERROR 0
#   #endif
#
#   Otherwise, the #define hackery is quite ugly and would have been
#   dropped.
#

type
  TStatus*{.size: sizeof(cint).} = enum
    STATUS_ERROR = 0, STATUS_OK = 1, STATUS_SUSPENDED = 2
  TError*{.size: sizeof(cint).} = enum
    ERROR_NONE, ERROR_NO_MEMORY, ERROR_SYNTAX, ERROR_NO_ELEMENTS,
    ERROR_INVALID_TOKEN, ERROR_UNCLOSED_TOKEN, ERROR_PARTIAL_CHAR,
    ERROR_TAG_MISMATCH, ERROR_DUPLICATE_ATTRIBUTE,
    ERROR_JUNK_AFTER_DOC_ELEMENT,
    ERROR_PARAM_ENTITY_REF, ERROR_UNDEFINED_ENTITY, ERROR_RECURSIVE_ENTITY_REF,
    ERROR_ASYNC_ENTITY, ERROR_BAD_CHAR_REF, ERROR_BINARY_ENTITY_REF,
    ERROR_ATTRIBUTE_EXTERNAL_ENTITY_REF, ERROR_MISPLACED_XML_PI,
    ERROR_UNKNOWN_ENCODING, ERROR_INCORRECT_ENCODING,
    ERROR_UNCLOSED_CDATA_SECTION, ERROR_EXTERNAL_ENTITY_HANDLING,
    ERROR_NOT_STANDALONE, ERROR_UNEXPECTED_STATE, ERROR_ENTITY_DECLARED_IN_PE,
    ERROR_FEATURE_REQUIRES_XML_DTD, ERROR_CANT_CHANGE_FEATURE_ONCE_PARSING,
    ERROR_UNBOUND_PREFIX,
    ERROR_UNDECLARING_PREFIX, ERROR_INCOMPLETE_PE, ERROR_XML_DECL,
    ERROR_TEXT_DECL, ERROR_PUBLICID, ERROR_SUSPENDED, ERROR_NOT_SUSPENDED,
    ERROR_ABORTED, ERROR_FINISHED, ERROR_SUSPEND_PE,
    ERROR_RESERVED_PREFIX_XML, ERROR_RESERVED_PREFIX_XMLNS,
    ERROR_RESERVED_NAMESPACE_URI
  TContent_Type*{.size: sizeof(cint).} = enum
    CTYPE_EMPTY = 1, CTYPE_ANY, CTYPE_MIXED, CTYPE_NAME, CTYPE_CHOICE, CTYPE_SEQ
  TContent_Quant*{.size: sizeof(cint).} = enum
    CQUANT_NONE, CQUANT_OPT, CQUANT_REP, CQUANT_PLUS

# If type == XML_CTYPE_EMPTY or XML_CTYPE_ANY, then quant will be
#   XML_CQUANT_NONE, and the other fields will be zero or NULL.
#   If type == XML_CTYPE_MIXED, then quant will be NONE or REP and
#   numchildren will contain number of elements that may be mixed in
#   and children point to an array of XML_Content cells that will be
#   all of XML_CTYPE_NAME type with no quantification.
#
#   If type == XML_CTYPE_NAME, then the name points to the name, and
#   the numchildren field will be zero and children will be NULL. The
#   quant fields indicates any quantifiers placed on the name.
#
#   CHOICE and SEQ will have name NULL, the number of children in
#   numchildren and children will point, recursively, to an array
#   of XML_Content cells.
#
#   The EMPTY, ANY, and MIXED types will only occur at top level.
#

type
  TContent*{.pure, final.} = object
    typ*: TContent_Type
    quant*: TContent_Quant
    name*: cstring
    numchildren*: cint
    children*: ptr TContent


# This is called for an element declaration. See above for
#   description of the model argument. It's the caller's responsibility
#   to free model when finished with it.
#

type
  TElementDeclHandler* = proc (userData: pointer, name: cstring,
                               model: ptr TContent){.cdecl.}

proc SetElementDeclHandler*(parser: PParser, eldecl: TElementDeclHandler){.
    cdecl, importc: "XML_SetElementDeclHandler", dynlib: expatDll.}
# The Attlist declaration handler is called for *each* attribute. So
#   a single Attlist declaration with multiple attributes declared will
#   generate multiple calls to this handler. The "default" parameter
#   may be NULL in the case of the "#IMPLIED" or "#REQUIRED"
#   keyword. The "isrequired" parameter will be true and the default
#   value will be NULL in the case of "#REQUIRED". If "isrequired" is
#   true and default is non-NULL, then this is a "#FIXED" default.
#

type
  TAttlistDeclHandler* = proc (userData: pointer, elname: cstring,
                               attname: cstring, att_type: cstring,
                               dflt: cstring, isrequired: cint){.cdecl.}

proc SetAttlistDeclHandler*(parser: PParser, attdecl: TAttlistDeclHandler){.
    cdecl, importc: "XML_SetAttlistDeclHandler", dynlib: expatDll.}
# The XML declaration handler is called for *both* XML declarations
#   and text declarations. The way to distinguish is that the version
#   parameter will be NULL for text declarations. The encoding
#   parameter may be NULL for XML declarations. The standalone
#   parameter will be -1, 0, or 1 indicating respectively that there
#   was no standalone parameter in the declaration, that it was given
#   as no, or that it was given as yes.
#

type
  TXmlDeclHandler* = proc (userData: pointer, version: cstring,
                           encoding: cstring, standalone: cint){.cdecl.}

proc SetXmlDeclHandler*(parser: PParser, xmldecl: TXmlDeclHandler){.cdecl,
    importc: "XML_SetXmlDeclHandler", dynlib: expatDll.}
type
  TMemory_Handling_Suite*{.pure, final.} = object
    malloc_fcn*: proc (size: int): pointer{.cdecl.}
    realloc_fcn*: proc (p: pointer, size: int): pointer{.cdecl.}
    free_fcn*: proc (p: pointer){.cdecl.}


# Constructs a new parser; encoding is the encoding specified by the
#   external protocol or NULL if there is none specified.
#

proc ParserCreate*(encoding: cstring): PParser{.cdecl,
    importc: "XML_ParserCreate", dynlib: expatDll.}
# Constructs a new parser and namespace processor.  Element type
#   names and attribute names that belong to a namespace will be
#   expanded; unprefixed attribute names are never expanded; unprefixed
#   element type names are expanded only if there is a default
#   namespace. The expanded name is the concatenation of the namespace
#   URI, the namespace separator character, and the local part of the
#   name.  If the namespace separator is '\0' then the namespace URI
#   and the local part will be concatenated without any separator.
#   It is a programming error to use the separator '\0' with namespace
#   triplets (see XML_SetReturnNSTriplet).
#

proc ParserCreateNS*(encoding: cstring, namespaceSeparator: char): PParser{.
    cdecl, importc: "XML_ParserCreateNS", dynlib: expatDll.}
# Constructs a new parser using the memory management suite referred to
#   by memsuite. If memsuite is NULL, then use the standard library memory
#   suite. If namespaceSeparator is non-NULL it creates a parser with
#   namespace processing as described above. The character pointed at
#   will serve as the namespace separator.
#
#   All further memory operations used for the created parser will come from
#   the given suite.
#

proc ParserCreate_MM*(encoding: cstring, memsuite: ptr TMemory_Handling_Suite,
                      namespaceSeparator: cstring): PParser{.cdecl,
    importc: "XML_ParserCreate_MM", dynlib: expatDll.}
# Prepare a parser object to be re-used.  This is particularly
#   valuable when memory allocation overhead is disproportionatly high,
#   such as when a large number of small documnents need to be parsed.
#   All handlers are cleared from the parser, except for the
#   unknownEncodingHandler. The parser's external state is re-initialized
#   except for the values of ns and ns_triplets.
#
#   Added in Expat 1.95.3.
#

proc ParserReset*(parser: PParser, encoding: cstring): Bool{.cdecl,
    importc: "XML_ParserReset", dynlib: expatDll.}
# atts is array of name/value pairs, terminated by 0;
#   names and values are 0 terminated.
#

type
  TStartElementHandler* = proc (userData: pointer, name: cstring,
                                atts: cstringArray){.cdecl.}
  TEndElementHandler* = proc (userData: pointer, name: cstring){.cdecl.}

# s is not 0 terminated.

type
  TCharacterDataHandler* = proc (userData: pointer, s: cstring, len: cint){.
      cdecl.}

# target and data are 0 terminated

type
  TProcessingInstructionHandler* = proc (userData: pointer, target: cstring,
      data: cstring){.cdecl.}

# data is 0 terminated

type
  TCommentHandler* = proc (userData: pointer, data: cstring){.cdecl.}
  TStartCdataSectionHandler* = proc (userData: pointer){.cdecl.}
  TEndCdataSectionHandler* = proc (userData: pointer){.cdecl.}

# This is called for any characters in the XML document for which
#   there is no applicable handler.  This includes both characters that
#   are part of markup which is of a kind that is not reported
#   (comments, markup declarations), or characters that are part of a
#   construct which could be reported but for which no handler has been
#   supplied. The characters are passed exactly as they were in the XML
#   document except that they will be encoded in UTF-8 or UTF-16.
#   Line boundaries are not normalized. Note that a byte order mark
#   character is not passed to the default handler. There are no
#   guarantees about how characters are divided between calls to the
#   default handler: for example, a comment might be split between
#   multiple calls.
#

type
  TDefaultHandler* = proc (userData: pointer, s: cstring, len: cint){.cdecl.}

# This is called for the start of the DOCTYPE declaration, before
#   any DTD or internal subset is parsed.
#

type
  TStartDoctypeDeclHandler* = proc (userData: pointer, doctypeName: cstring,
                                    sysid: cstring, pubid: cstring,
                                    has_internal_subset: cint){.cdecl.}

# This is called for the start of the DOCTYPE declaration when the
#   closing > is encountered, but after processing any external
#   subset.
#

type
  TEndDoctypeDeclHandler* = proc (userData: pointer){.cdecl.}

# This is called for entity declarations. The is_parameter_entity
#   argument will be non-zero if the entity is a parameter entity, zero
#   otherwise.
#
#   For internal entities (<!ENTITY foo "bar">), value will
#   be non-NULL and systemId, publicID, and notationName will be NULL.
#   The value string is NOT nul-terminated; the length is provided in
#   the value_length argument. Since it is legal to have zero-length
#   values, do not use this argument to test for internal entities.
#
#   For external entities, value will be NULL and systemId will be
#   non-NULL. The publicId argument will be NULL unless a public
#   identifier was provided. The notationName argument will have a
#   non-NULL value only for unparsed entity declarations.
#
#   Note that is_parameter_entity can't be changed to XML_Bool, since
#   that would break binary compatibility.
#

type
  TEntityDeclHandler* = proc (userData: pointer, entityName: cstring,
                              is_parameter_entity: cint, value: cstring,
                              value_length: cint, base: cstring,
                              systemId: cstring, publicId: cstring,
                              notationName: cstring){.cdecl.}

proc SetEntityDeclHandler*(parser: PParser, handler: TEntityDeclHandler){.cdecl,
    importc: "XML_SetEntityDeclHandler", dynlib: expatDll.}
# OBSOLETE -- OBSOLETE -- OBSOLETE
#   This handler has been superceded by the EntityDeclHandler above.
#   It is provided here for backward compatibility.
#
#   This is called for a declaration of an unparsed (NDATA) entity.
#   The base argument is whatever was set by XML_SetBase. The
#   entityName, systemId and notationName arguments will never be
#   NULL. The other arguments may be.
#

type
  TUnparsedEntityDeclHandler* = proc (userData: pointer, entityName: cstring,
                                      base: cstring, systemId: cstring,
                                      publicId, notationName: cstring){.
      cdecl.}

# This is called for a declaration of notation.  The base argument is
#   whatever was set by XML_SetBase. The notationName will never be
#   NULL.  The other arguments can be.
#

type
  TNotationDeclHandler* = proc (userData: pointer, notationName: cstring,
                                base: cstring, systemId: cstring,
                                publicId: cstring){.cdecl.}

# When namespace processing is enabled, these are called once for
#   each namespace declaration. The call to the start and end element
#   handlers occur between the calls to the start and end namespace
#   declaration handlers. For an xmlns attribute, prefix will be
#   NULL.  For an xmlns="" attribute, uri will be NULL.
#

type
  TStartNamespaceDeclHandler* = proc (userData: pointer, prefix: cstring,
                                      uri: cstring){.cdecl.}
  TEndNamespaceDeclHandler* = proc (userData: pointer, prefix: cstring){.cdecl.}

# This is called if the document is not standalone, that is, it has an
#   external subset or a reference to a parameter entity, but does not
#   have standalone="yes". If this handler returns XML_STATUS_ERROR,
#   then processing will not continue, and the parser will return a
#   XML_ERROR_NOT_STANDALONE error.
#   If parameter entity parsing is enabled, then in addition to the
#   conditions above this handler will only be called if the referenced
#   entity was actually read.
#

type
  TNotStandaloneHandler* = proc (userData: pointer): cint{.cdecl.}

# This is called for a reference to an external parsed general
#   entity.  The referenced entity is not automatically parsed.  The
#   application can parse it immediately or later using
#   XML_ExternalEntityParserCreate.
#
#   The parser argument is the parser parsing the entity containing the
#   reference; it can be passed as the parser argument to
#   XML_ExternalEntityParserCreate.  The systemId argument is the
#   system identifier as specified in the entity declaration; it will
#   not be NULL.
#
#   The base argument is the system identifier that should be used as
#   the base for resolving systemId if systemId was relative; this is
#   set by XML_SetBase; it may be NULL.
#
#   The publicId argument is the public identifier as specified in the
#   entity declaration, or NULL if none was specified; the whitespace
#   in the public identifier will have been normalized as required by
#   the XML spec.
#
#   The context argument specifies the parsing context in the format
#   expected by the context argument to XML_ExternalEntityParserCreate;
#   context is valid only until the handler returns, so if the
#   referenced entity is to be parsed later, it must be copied.
#   context is NULL only when the entity is a parameter entity.
#
#   The handler should return XML_STATUS_ERROR if processing should not
#   continue because of a fatal error in the handling of the external
#   entity.  In this case the calling parser will return an
#   XML_ERROR_EXTERNAL_ENTITY_HANDLING error.
#
#   Note that unlike other handlers the first argument is the parser,
#   not userData.
#

type
  TExternalEntityRefHandler* = proc (parser: PParser, context: cstring,
                                     base: cstring, systemId: cstring,
                                     publicId: cstring): cint{.cdecl.}

# This is called in two situations:
#   1) An entity reference is encountered for which no declaration
#      has been read *and* this is not an error.
#   2) An internal entity reference is read, but not expanded, because
#      XML_SetDefaultHandler has been called.
#   Note: skipped parameter entities in declarations and skipped general
#         entities in attribute values cannot be reported, because
#         the event would be out of sync with the reporting of the
#         declarations or attribute values
#

type
  TSkippedEntityHandler* = proc (userData: pointer, entityName: cstring,
                                 is_parameter_entity: cint){.cdecl.}

# This structure is filled in by the XML_UnknownEncodingHandler to
#   provide information to the parser about encodings that are unknown
#   to the parser.
#
#   The map[b] member gives information about byte sequences whose
#   first byte is b.
#
#   If map[b] is c where c is >= 0, then b by itself encodes the
#   Unicode scalar value c.
#
#   If map[b] is -1, then the byte sequence is malformed.
#
#   If map[b] is -n, where n >= 2, then b is the first byte of an
#   n-byte sequence that encodes a single Unicode scalar value.
#
#   The data member will be passed as the first argument to the convert
#   function.
#
#   The convert function is used to convert multibyte sequences; s will
#   point to a n-byte sequence where map[(unsigned char)*s] == -n.  The
#   convert function must return the Unicode scalar value represented
#   by this byte sequence or -1 if the byte sequence is malformed.
#
#   The convert function may be NULL if the encoding is a single-byte
#   encoding, that is if map[b] >= -1 for all bytes b.
#
#   When the parser is finished with the encoding, then if release is
#   not NULL, it will call release passing it the data member; once
#   release has been called, the convert function will not be called
#   again.
#
#   Expat places certain restrictions on the encodings that are supported
#   using this mechanism.
#
#   1. Every ASCII character that can appear in a well-formed XML document,
#      other than the characters
#
#      $@\^`{}~
#
#      must be represented by a single byte, and that byte must be the
#      same byte that represents that character in ASCII.
#
#   2. No character may require more than 4 bytes to encode.
#
#   3. All characters encoded must have Unicode scalar values <=
#      0xFFFF, (i.e., characters that would be encoded by surrogates in
#      UTF-16 are  not allowed).  Note that this restriction doesn't
#      apply to the built-in support for UTF-8 and UTF-16.
#
#   4. No Unicode character may be encoded by more than one distinct
#      sequence of bytes.
#

type
  TEncoding*{.pure, final.} = object
    map*: array[0..256 - 1, cint]
    data*: pointer
    convert*: proc (data: pointer, s: cstring): cint{.cdecl.}
    release*: proc (data: pointer){.cdecl.}


# This is called for an encoding that is unknown to the parser.
#
#   The encodingHandlerData argument is that which was passed as the
#   second argument to XML_SetUnknownEncodingHandler.
#
#   The name argument gives the name of the encoding as specified in
#   the encoding declaration.
#
#   If the callback can provide information about the encoding, it must
#   fill in the XML_Encoding structure, and return XML_STATUS_OK.
#   Otherwise it must return XML_STATUS_ERROR.
#
#   If info does not describe a suitable encoding, then the parser will
#   return an XML_UNKNOWN_ENCODING error.
#

type
  TUnknownEncodingHandler* = proc (encodingHandlerData: pointer, name: cstring,
                                   info: ptr TEncoding): cint{.cdecl.}

proc SetElementHandler*(parser: PParser, start: TStartElementHandler,
                        endHandler: TEndElementHandler){.cdecl,
    importc: "XML_SetElementHandler", dynlib: expatDll.}
proc SetStartElementHandler*(parser: PParser, handler: TStartElementHandler){.
    cdecl, importc: "XML_SetStartElementHandler", dynlib: expatDll.}
proc SetEndElementHandler*(parser: PParser, handler: TEndElementHandler){.cdecl,
    importc: "XML_SetEndElementHandler", dynlib: expatDll.}
proc SetCharacterDataHandler*(parser: PParser, handler: TCharacterDataHandler){.
    cdecl, importc: "XML_SetCharacterDataHandler", dynlib: expatDll.}
proc SetProcessingInstructionHandler*(parser: PParser,
                                      handler: TProcessingInstructionHandler){.
    cdecl, importc: "XML_SetProcessingInstructionHandler", dynlib: expatDll.}
proc SetCommentHandler*(parser: PParser, handler: TCommentHandler){.cdecl,
    importc: "XML_SetCommentHandler", dynlib: expatDll.}
proc SetCdataSectionHandler*(parser: PParser, start: TStartCdataSectionHandler,
                             endHandler: TEndCdataSectionHandler){.cdecl,
    importc: "XML_SetCdataSectionHandler", dynlib: expatDll.}
proc SetStartCdataSectionHandler*(parser: PParser,
                                  start: TStartCdataSectionHandler){.cdecl,
    importc: "XML_SetStartCdataSectionHandler", dynlib: expatDll.}
proc SetEndCdataSectionHandler*(parser: PParser,
                                endHandler: TEndCdataSectionHandler){.cdecl,
    importc: "XML_SetEndCdataSectionHandler", dynlib: expatDll.}
# This sets the default handler and also inhibits expansion of
#   internal entities. These entity references will be passed to the
#   default handler, or to the skipped entity handler, if one is set.
#

proc SetDefaultHandler*(parser: PParser, handler: TDefaultHandler){.cdecl,
    importc: "XML_SetDefaultHandler", dynlib: expatDll.}
# This sets the default handler but does not inhibit expansion of
#   internal entities.  The entity reference will not be passed to the
#   default handler.
#

proc SetDefaultHandlerExpand*(parser: PParser, handler: TDefaultHandler){.cdecl,
    importc: "XML_SetDefaultHandlerExpand", dynlib: expatDll.}
proc SetDoctypeDeclHandler*(parser: PParser, start: TStartDoctypeDeclHandler,
                            endHandler: TEndDoctypeDeclHandler){.cdecl,
    importc: "XML_SetDoctypeDeclHandler", dynlib: expatDll.}
proc SetStartDoctypeDeclHandler*(parser: PParser,
                                 start: TStartDoctypeDeclHandler){.cdecl,
    importc: "XML_SetStartDoctypeDeclHandler", dynlib: expatDll.}
proc SetEndDoctypeDeclHandler*(parser: PParser,
                               endHandler: TEndDoctypeDeclHandler){.cdecl,
    importc: "XML_SetEndDoctypeDeclHandler", dynlib: expatDll.}
proc SetUnparsedEntityDeclHandler*(parser: PParser,
                                   handler: TUnparsedEntityDeclHandler){.cdecl,
    importc: "XML_SetUnparsedEntityDeclHandler", dynlib: expatDll.}
proc SetNotationDeclHandler*(parser: PParser, handler: TNotationDeclHandler){.
    cdecl, importc: "XML_SetNotationDeclHandler", dynlib: expatDll.}
proc SetNamespaceDeclHandler*(parser: PParser,
                              start: TStartNamespaceDeclHandler,
                              endHandler: TEndNamespaceDeclHandler){.cdecl,
    importc: "XML_SetNamespaceDeclHandler", dynlib: expatDll.}
proc SetStartNamespaceDeclHandler*(parser: PParser,
                                   start: TStartNamespaceDeclHandler){.cdecl,
    importc: "XML_SetStartNamespaceDeclHandler", dynlib: expatDll.}
proc SetEndNamespaceDeclHandler*(parser: PParser,
                                 endHandler: TEndNamespaceDeclHandler){.cdecl,
    importc: "XML_SetEndNamespaceDeclHandler", dynlib: expatDll.}
proc SetNotStandaloneHandler*(parser: PParser, handler: TNotStandaloneHandler){.
    cdecl, importc: "XML_SetNotStandaloneHandler", dynlib: expatDll.}
proc SetExternalEntityRefHandler*(parser: PParser,
                                  handler: TExternalEntityRefHandler){.cdecl,
    importc: "XML_SetExternalEntityRefHandler", dynlib: expatDll.}
# If a non-NULL value for arg is specified here, then it will be
#   passed as the first argument to the external entity ref handler
#   instead of the parser object.
#

proc SetExternalEntityRefHandlerArg*(parser: PParser, arg: pointer){.cdecl,
    importc: "XML_SetExternalEntityRefHandlerArg", dynlib: expatDll.}
proc SetSkippedEntityHandler*(parser: PParser, handler: TSkippedEntityHandler){.
    cdecl, importc: "XML_SetSkippedEntityHandler", dynlib: expatDll.}
proc SetUnknownEncodingHandler*(parser: PParser,
                                handler: TUnknownEncodingHandler,
                                encodingHandlerData: pointer){.cdecl,
    importc: "XML_SetUnknownEncodingHandler", dynlib: expatDll.}
# This can be called within a handler for a start element, end
#   element, processing instruction or character data.  It causes the
#   corresponding markup to be passed to the default handler.
#

proc DefaultCurrent*(parser: PParser){.cdecl, importc: "XML_DefaultCurrent",
                                       dynlib: expatDll.}
# If do_nst is non-zero, and namespace processing is in effect, and
#   a name has a prefix (i.e. an explicit namespace qualifier) then
#   that name is returned as a triplet in a single string separated by
#   the separator character specified when the parser was created: URI
#   + sep + local_name + sep + prefix.
#
#   If do_nst is zero, then namespace information is returned in the
#   default manner (URI + sep + local_name) whether or not the name
#   has a prefix.
#
#   Note: Calling XML_SetReturnNSTriplet after XML_Parse or
#     XML_ParseBuffer has no effect.
#

proc SetReturnNSTriplet*(parser: PParser, do_nst: cint){.cdecl,
    importc: "XML_SetReturnNSTriplet", dynlib: expatDll.}
# This value is passed as the userData argument to callbacks.

proc SetUserData*(parser: PParser, userData: pointer){.cdecl,
    importc: "XML_SetUserData", dynlib: expatDll.}
# Returns the last value set by XML_SetUserData or NULL.

template GetUserData*(parser: expr): expr =
  (cast[ptr pointer]((parser))[] )

# This is equivalent to supplying an encoding argument to
#   XML_ParserCreate. On success XML_SetEncoding returns non-zero,
#   zero otherwise.
#   Note: Calling XML_SetEncoding after XML_Parse or XML_ParseBuffer
#     has no effect and returns XML_STATUS_ERROR.
#

proc SetEncoding*(parser: PParser, encoding: cstring): TStatus{.cdecl,
    importc: "XML_SetEncoding", dynlib: expatDll.}
# If this function is called, then the parser will be passed as the
#   first argument to callbacks instead of userData.  The userData will
#   still be accessible using XML_GetUserData.
#

proc UseParserAsHandlerArg*(parser: PParser){.cdecl,
    importc: "XML_UseParserAsHandlerArg", dynlib: expatDll.}
# If useDTD == XML_TRUE is passed to this function, then the parser
#   will assume that there is an external subset, even if none is
#   specified in the document. In such a case the parser will call the
#   externalEntityRefHandler with a value of NULL for the systemId
#   argument (the publicId and context arguments will be NULL as well).
#   Note: For the purpose of checking WFC: Entity Declared, passing
#     useDTD == XML_TRUE will make the parser behave as if the document
#     had a DTD with an external subset.
#   Note: If this function is called, then this must be done before
#     the first call to XML_Parse or XML_ParseBuffer, since it will
#     have no effect after that.  Returns
#     XML_ERROR_CANT_CHANGE_FEATURE_ONCE_PARSING.
#   Note: If the document does not have a DOCTYPE declaration at all,
#     then startDoctypeDeclHandler and endDoctypeDeclHandler will not
#     be called, despite an external subset being parsed.
#   Note: If XML_DTD is not defined when Expat is compiled, returns
#     XML_ERROR_FEATURE_REQUIRES_XML_DTD.
#

proc UseForeignDTD*(parser: PParser, useDTD: Bool): TError{.cdecl,
    importc: "XML_UseForeignDTD", dynlib: expatDll.}
# Sets the base to be used for resolving relative URIs in system
#   identifiers in declarations.  Resolving relative identifiers is
#   left to the application: this value will be passed through as the
#   base argument to the XML_ExternalEntityRefHandler,
#   XML_NotationDeclHandler and XML_UnparsedEntityDeclHandler. The base
#   argument will be copied.  Returns XML_STATUS_ERROR if out of memory,
#   XML_STATUS_OK otherwise.
#

proc SetBase*(parser: PParser, base: cstring): TStatus{.cdecl,
    importc: "XML_SetBase", dynlib: expatDll.}
proc GetBase*(parser: PParser): cstring{.cdecl, importc: "XML_GetBase",
    dynlib: expatDll.}
# Returns the number of the attribute/value pairs passed in last call
#   to the XML_StartElementHandler that were specified in the start-tag
#   rather than defaulted. Each attribute/value pair counts as 2; thus
#   this correspondds to an index into the atts array passed to the
#   XML_StartElementHandler.
#

proc GetSpecifiedAttributeCount*(parser: PParser): cint{.cdecl,
    importc: "XML_GetSpecifiedAttributeCount", dynlib: expatDll.}
# Returns the index of the ID attribute passed in the last call to
#   XML_StartElementHandler, or -1 if there is no ID attribute.  Each
#   attribute/value pair counts as 2; thus this correspondds to an
#   index into the atts array passed to the XML_StartElementHandler.
#

proc GetIdAttributeIndex*(parser: PParser): cint{.cdecl,
    importc: "XML_GetIdAttributeIndex", dynlib: expatDll.}
# Parses some input. Returns XML_STATUS_ERROR if a fatal error is
#   detected.  The last call to XML_Parse must have isFinal true; len
#   may be zero for this call (or any other).
#
#   Though the return values for these functions has always been
#   described as a Boolean value, the implementation, at least for the
#   1.95.x series, has always returned exactly one of the XML_Status
#   values.
#

proc Parse*(parser: PParser, s: cstring, len: cint, isFinal: cint): TStatus{.
    cdecl, importc: "XML_Parse", dynlib: expatDll.}
proc GetBuffer*(parser: PParser, len: cint): pointer{.cdecl,
    importc: "XML_GetBuffer", dynlib: expatDll.}
proc ParseBuffer*(parser: PParser, len: cint, isFinal: cint): TStatus{.cdecl,
    importc: "XML_ParseBuffer", dynlib: expatDll.}
# Stops parsing, causing XML_Parse() or XML_ParseBuffer() to return.
#   Must be called from within a call-back handler, except when aborting
#   (resumable = 0) an already suspended parser. Some call-backs may
#   still follow because they would otherwise get lost. Examples:
#   - endElementHandler() for empty elements when stopped in
#     startElementHandler(),
#   - endNameSpaceDeclHandler() when stopped in endElementHandler(),
#   and possibly others.
#
#   Can be called from most handlers, including DTD related call-backs,
#   except when parsing an external parameter entity and resumable != 0.
#   Returns XML_STATUS_OK when successful, XML_STATUS_ERROR otherwise.
#   Possible error codes:
#   - XML_ERROR_SUSPENDED: when suspending an already suspended parser.
#   - XML_ERROR_FINISHED: when the parser has already finished.
#   - XML_ERROR_SUSPEND_PE: when suspending while parsing an external PE.
#
#   When resumable != 0 (true) then parsing is suspended, that is,
#   XML_Parse() and XML_ParseBuffer() return XML_STATUS_SUSPENDED.
#   Otherwise, parsing is aborted, that is, XML_Parse() and XML_ParseBuffer()
#   return XML_STATUS_ERROR with error code XML_ERROR_ABORTED.
#
#   Note*:
#   This will be applied to the current parser instance only, that is, if
#   there is a parent parser then it will continue parsing when the
#   externalEntityRefHandler() returns. It is up to the implementation of
#   the externalEntityRefHandler() to call XML_StopParser() on the parent
#   parser (recursively), if one wants to stop parsing altogether.
#
#   When suspended, parsing can be resumed by calling XML_ResumeParser().
#

proc StopParser*(parser: PParser, resumable: Bool): TStatus{.cdecl,
    importc: "XML_StopParser", dynlib: expatDll.}
# Resumes parsing after it has been suspended with XML_StopParser().
#   Must not be called from within a handler call-back. Returns same
#   status codes as XML_Parse() or XML_ParseBuffer().
#   Additional error code XML_ERROR_NOT_SUSPENDED possible.
#
#   Note*:
#   This must be called on the most deeply nested child parser instance
#   first, and on its parent parser only after the child parser has finished,
#   to be applied recursively until the document entity's parser is restarted.
#   That is, the parent parser will not resume by itself and it is up to the
#   application to call XML_ResumeParser() on it at the appropriate moment.
#

proc ResumeParser*(parser: PParser): TStatus{.cdecl,
    importc: "XML_ResumeParser", dynlib: expatDll.}
type
  TParsing* = enum
    INITIALIZED, PARSING, FINISHED, SUSPENDED
  TParsingStatus*{.pure, final.} = object
    parsing*: TParsing
    finalBuffer*: Bool


# Returns status of parser with respect to being initialized, parsing,
#   finished, or suspended and processing the final buffer.
#   XXX XML_Parse() and XML_ParseBuffer() should return XML_ParsingStatus,
#   XXX with XML_FINISHED_OK or XML_FINISHED_ERROR replacing XML_FINISHED
#

proc GetParsingStatus*(parser: PParser, status: ptr TParsingStatus){.cdecl,
    importc: "XML_GetParsingStatus", dynlib: expatDll.}
# Creates an XML_Parser object that can parse an external general
#   entity; context is a '\0'-terminated string specifying the parse
#   context; encoding is a '\0'-terminated string giving the name of
#   the externally specified encoding, or NULL if there is no
#   externally specified encoding.  The context string consists of a
#   sequence of tokens separated by formfeeds (\f); a token consisting
#   of a name specifies that the general entity of the name is open; a
#   token of the form prefix=uri specifies the namespace for a
#   particular prefix; a token of the form =uri specifies the default
#   namespace.  This can be called at any point after the first call to
#   an ExternalEntityRefHandler so longer as the parser has not yet
#   been freed.  The new parser is completely independent and may
#   safely be used in a separate thread.  The handlers and userData are
#   initialized from the parser argument.  Returns NULL if out of memory.
#   Otherwise returns a new XML_Parser object.
#

proc ExternalEntityParserCreate*(parser: PParser, context: cstring,
                                 encoding: cstring): PParser{.cdecl,
    importc: "XML_ExternalEntityParserCreate", dynlib: expatDll.}
type
  TParamEntityParsing* = enum
    PARAM_ENTITY_PARSING_NEVER, PARAM_ENTITY_PARSING_UNLESS_STANDALONE,
    PARAM_ENTITY_PARSING_ALWAYS

# Controls parsing of parameter entities (including the external DTD
#   subset). If parsing of parameter entities is enabled, then
#   references to external parameter entities (including the external
#   DTD subset) will be passed to the handler set with
#   XML_SetExternalEntityRefHandler.  The context passed will be 0.
#
#   Unlike external general entities, external parameter entities can
#   only be parsed synchronously.  If the external parameter entity is
#   to be parsed, it must be parsed during the call to the external
#   entity ref handler: the complete sequence of
#   XML_ExternalEntityParserCreate, XML_Parse/XML_ParseBuffer and
#   XML_ParserFree calls must be made during this call.  After
#   XML_ExternalEntityParserCreate has been called to create the parser
#   for the external parameter entity (context must be 0 for this
#   call), it is illegal to make any calls on the old parser until
#   XML_ParserFree has been called on the newly created parser.
#   If the library has been compiled without support for parameter
#   entity parsing (ie without XML_DTD being defined), then
#   XML_SetParamEntityParsing will return 0 if parsing of parameter
#   entities is requested; otherwise it will return non-zero.
#   Note: If XML_SetParamEntityParsing is called after XML_Parse or
#      XML_ParseBuffer, then it has no effect and will always return 0.
#

proc SetParamEntityParsing*(parser: PParser, parsing: TParamEntityParsing): cint{.
    cdecl, importc: "XML_SetParamEntityParsing", dynlib: expatDll.}
# If XML_Parse or XML_ParseBuffer have returned XML_STATUS_ERROR, then
#   XML_GetErrorCode returns information about the error.
#

proc GetErrorCode*(parser: PParser): TError{.cdecl, importc: "XML_GetErrorCode",
    dynlib: expatDll.}
# These functions return information about the current parse
#   location.  They may be called from any callback called to report
#   some parse event; in this case the location is the location of the
#   first of the sequence of characters that generated the event.  When
#   called from callbacks generated by declarations in the document
#   prologue, the location identified isn't as neatly defined, but will
#   be within the relevant markup.  When called outside of the callback
#   functions, the position indicated will be just past the last parse
#   event (regardless of whether there was an associated callback).
#
#   They may also be called after returning from a call to XML_Parse
#   or XML_ParseBuffer.  If the return value is XML_STATUS_ERROR then
#   the location is the location of the character at which the error
#   was detected; otherwise the location is the location of the last
#   parse event, as described above.
#

proc GetCurrentLineNumber*(parser: PParser): int{.cdecl,
    importc: "XML_GetCurrentLineNumber", dynlib: expatDll.}
proc GetCurrentColumnNumber*(parser: PParser): int{.cdecl,
    importc: "XML_GetCurrentColumnNumber", dynlib: expatDll.}
proc GetCurrentByteIndex*(parser: PParser): int{.cdecl,
    importc: "XML_GetCurrentByteIndex", dynlib: expatDll.}
# Return the number of bytes in the current event.
#   Returns 0 if the event is in an internal entity.
#

proc GetCurrentByteCount*(parser: PParser): cint{.cdecl,
    importc: "XML_GetCurrentByteCount", dynlib: expatDll.}
# If XML_CONTEXT_BYTES is defined, returns the input buffer, sets
#   the integer pointed to by offset to the offset within this buffer
#   of the current parse position, and sets the integer pointed to by size
#   to the size of this buffer (the number of input bytes). Otherwise
#   returns a NULL pointer. Also returns a NULL pointer if a parse isn't
#   active.
#
#   NOTE: The character pointer returned should not be used outside
#   the handler that makes the call.
#

proc GetInputContext*(parser: PParser, offset: ptr cint, size: ptr cint): cstring{.
    cdecl, importc: "XML_GetInputContext", dynlib: expatDll.}
# Frees the content model passed to the element declaration handler

proc FreeContentModel*(parser: PParser, model: ptr TContent){.cdecl,
    importc: "XML_FreeContentModel", dynlib: expatDll.}
# Exposing the memory handling functions used in Expat

proc MemMalloc*(parser: PParser, size: int): pointer{.cdecl,
    importc: "XML_MemMalloc", dynlib: expatDll.}
proc MemRealloc*(parser: PParser, p: pointer, size: int): pointer{.cdecl,
    importc: "XML_MemRealloc", dynlib: expatDll.}
proc MemFree*(parser: PParser, p: pointer){.cdecl, importc: "XML_MemFree",
    dynlib: expatDll.}
# Frees memory used by the parser.

proc ParserFree*(parser: PParser){.cdecl, importc: "XML_ParserFree",
                                   dynlib: expatDll.}
# Returns a string describing the error.

proc ErrorString*(code: TError): cstring{.cdecl, importc: "XML_ErrorString",
    dynlib: expatDll.}
# Return a string containing the version number of this expat

proc ExpatVersion*(): cstring{.cdecl, importc: "XML_ExpatVersion",
                               dynlib: expatDll.}
type
  TExpat_Version*{.pure, final.} = object
    major*: cint
    minor*: cint
    micro*: cint


# Return an XML_Expat_Version structure containing numeric version
#   number information for this version of expat.
#

proc ExpatVersionInfo*(): TExpat_Version{.cdecl,
    importc: "XML_ExpatVersionInfo", dynlib: expatDll.}
# Added in Expat 1.95.5.

type
  TFeatureEnum* = enum
    FEATURE_END = 0, FEATURE_UNICODE, FEATURE_UNICODE_WCHAR_T, FEATURE_DTD,
    FEATURE_CONTEXT_BYTES, FEATURE_MIN_SIZE, FEATURE_SIZEOF_XML_CHAR,
    FEATURE_SIZEOF_XML_LCHAR, FEATURE_NS, FEATURE_LARGE_SIZE # Additional features must be added to the end of this enum.
  TFeature*{.pure, final.} = object
    feature*: TFeatureEnum
    name*: cstring
    value*: int


proc GetFeatureList*(): ptr TFeature{.cdecl, importc: "XML_GetFeatureList",
                                      dynlib: expatDll.}
# Expat follows the GNU/Linux convention of odd number minor version for
#   beta/development releases and even number minor version for stable
#   releases. Micro is bumped with each release, and set to 0 with each
#   change to major or minor version.
#

const
  MAJOR_VERSION* = 2
  MINOR_VERSION* = 0
  MICRO_VERSION* = 1
