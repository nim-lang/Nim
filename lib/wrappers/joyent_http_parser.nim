#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  csize = int

  HttpDataProc* = proc (a2: ptr HttpParser, at: cstring, length: csize): cint {.cdecl.}
  HttpProc* = proc (a2: ptr HttpParser): cint {.cdecl.}

  HttpMethod* = enum
    HTTP_DELETE = 0, HTTP_GET, HTTP_HEAD, HTTP_POST, HTTP_PUT, HTTP_CONNECT,
    HTTP_OPTIONS, HTTP_TRACE, HTTP_COPY, HTTP_LOCK, HTTP_MKCOL, HTTP_MOVE,
    HTTP_PROPFIND, HTTP_PROPPATCH, HTTP_UNLOCK, HTTP_REPORT, HTTP_MKACTIVITY,
    HTTP_CHECKOUT, HTTP_MERGE, HTTP_MSEARCH, HTTP_NOTIFY, HTTP_SUBSCRIBE,
    HTTP_UNSUBSCRIBE, HTTP_PATCH

  HttpParserType* = enum
    HTTP_REQUEST, HTTP_RESPONSE, HTTP_BOTH

  ParserFlag* = enum
    F_CHUNKED = 1 shl 0,
    F_CONNECTION_KEEP_ALIVE = 1 shl 1,
    F_CONNECTION_CLOSE = 1 shl 2,
    F_TRAILING = 1 shl 3,
    F_UPGRADE = 1 shl 4,
    F_SKIPBODY = 1 shl 5

  HttpErrNo* = enum
    HPE_OK, HPE_CB_message_begin, HPE_CB_path, HPE_CB_query_string, HPE_CB_url,
    HPE_CB_fragment, HPE_CB_header_field, HPE_CB_header_value,
    HPE_CB_headers_complete, HPE_CB_body, HPE_CB_message_complete,
    HPE_INVALID_EOF_STATE, HPE_HEADER_OVERFLOW, HPE_CLOSED_CONNECTION,
    HPE_INVALID_VERSION, HPE_INVALID_STATUS, HPE_INVALID_METHOD,
    HPE_INVALID_URL, HPE_INVALID_HOST, HPE_INVALID_PORT, HPE_INVALID_PATH,
    HPE_INVALID_QUERY_STRING, HPE_INVALID_FRAGMENT, HPE_LF_EXPECTED,
    HPE_INVALID_HEADER_TOKEN, HPE_INVALID_CONTENT_LENGTH,
    HPE_INVALID_CHUNK_SIZE, HPE_INVALID_CONSTANT, HPE_INVALID_INTERNAL_STATE,
    HPE_STRICT, HPE_UNKNOWN

  HttpParser*{.pure, final, importc: "http_parser", header: "http_parser.h".} = object
    typ {.importc: "type".}: char
    flags {.importc: "flags".}: char
    state*{.importc: "state".}: char
    header_state*{.importc: "header_state".}: char
    index*{.importc: "index".}: char
    nread*{.importc: "nread".}: cint
    content_length*{.importc: "content_length".}: int64
    http_major*{.importc: "http_major".}: cshort
    http_minor*{.importc: "http_minor".}: cshort
    status_code*{.importc: "status_code".}: cshort
    http_method*{.importc: "method".}: cshort
    http_errno_bits {.importc: "http_errno".}: char
    upgrade {.importc: "upgrade".}: bool
    data*{.importc: "data".}: pointer

  HttpParserSettings*{.pure, final, importc: "http_parser_settings", header: "http_parser.h".} = object
    on_message_begin*{.importc: "on_message_begin".}: HttpProc
    on_url*{.importc: "on_url".}: HttpDataProc
    on_header_field*{.importc: "on_header_field".}: HttpDataProc
    on_header_value*{.importc: "on_header_value".}: HttpDataProc
    on_headers_complete*{.importc: "on_headers_complete".}: HttpProc
    on_body*{.importc: "on_body".}: HttpDataProc
    on_message_complete*{.importc: "on_message_complete".}: HttpProc
{.deprecated: [THttpMethod: HttpMethod, THttpParserType: HttpParserType,
              TParserFlag: ParserFlag, THttpErrNo: HttpErrNo,
              THttpParser: HttpParser, THttpParserSettings: HttpParserSettings].}

proc http_parser_init*(parser: var HttpParser, typ: HttpParserType){.
    importc: "http_parser_init", header: "http_parser.h".}

proc http_parser_execute*(parser: var HttpParser,
                          settings: var HttpParserSettings, data: cstring,
                          len: csize): csize {.
    importc: "http_parser_execute", header: "http_parser.h".}

proc http_should_keep_alive*(parser: var HttpParser): cint{.
    importc: "http_should_keep_alive", header: "http_parser.h".}

proc http_method_str*(m: HttpMethod): cstring{.
    importc: "http_method_str", header: "http_parser.h".}

proc http_errno_name*(err: HttpErrNo): cstring{.
    importc: "http_errno_name", header: "http_parser.h".}

proc http_errno_description*(err: HttpErrNo): cstring{.
    importc: "http_errno_description", header: "http_parser.h".}

