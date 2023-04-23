#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when not defined(ODBCVER):
  const
    ODBCVER = 0x0351 ## define ODBC version 3.51 by default

when defined(windows):
  {.push callconv: stdcall.}
  const odbclib = "odbc32.dll"
elif defined(macosx):
  {.push callconv: stdcall.}
  const odbclib = "libodbc.dylib"
else:
  {.push callconv: cdecl.}
  const odbclib = "libodbc.so"

when defined(nimHasStyleChecks):
  {.push styleChecks: off.}

# DATA TYPES CORRESPONDENCE
#   BDE fields  ODBC types
#   ----------  ------------------
#   ftBlob      SQL_BINARY
#   ftBoolean   SQL_BIT
#   ftDate      SQL_TYPE_DATE
#   ftTime      SQL_TYPE_TIME
#   ftDateTime  SQL_TYPE_TIMESTAMP
#   ftInteger   SQL_INTEGER
#   ftSmallint  SQL_SMALLINT
#   ftFloat     SQL_DOUBLE
#   ftString    SQL_CHAR
#   ftMemo      SQL_BINARY // SQL_VARCHAR
#

type
  TSqlChar* = char
  TSqlSmallInt* = int16
  SqlUSmallInt* = int16
  SqlHandle* = pointer
  SqlHEnv* = SqlHandle
  SqlHDBC* = SqlHandle
  SqlHStmt* = SqlHandle
  SqlHDesc* = SqlHandle
  TSqlInteger* = int32
  SqlUInteger* = int32
  TSqlLen* = int
  TSqlULen* = uint
  SqlPointer* = pointer
  TSqlReal* = cfloat
  TSqlDouble* = cdouble
  TSqlFloat* = cdouble
  SqlHWND* = pointer
  PSQLCHAR* = cstring
  PSQLINTEGER* = ptr TSqlInteger
  PSQLUINTEGER* = ptr SqlUInteger
  PSQLSMALLINT* = ptr TSqlSmallInt
  PSQLUSMALLINT* = ptr SqlUSmallInt
  PSQLREAL* = ptr TSqlReal
  PSQLDOUBLE* = ptr TSqlDouble
  PSQLFLOAT* = ptr TSqlFloat
  PSQLHANDLE* = ptr SqlHandle

const                         # SQL data type codes
  SQL_UNKNOWN_TYPE* = 0
  SQL_LONGVARCHAR* = (- 1)
  SQL_BINARY* = (- 2)
  SQL_VARBINARY* = (- 3)
  SQL_LONGVARBINARY* = (- 4)
  SQL_BIGINT* = (- 5)
  SQL_TINYINT* = (- 6)
  SQL_BIT* = (- 7)
  SQL_WCHAR* = (- 8)
  SQL_WVARCHAR* = (- 9)
  SQL_WLONGVARCHAR* = (- 10)
  SQL_CHAR* = 1
  SQL_NUMERIC* = 2
  SQL_DECIMAL* = 3
  SQL_INTEGER* = 4
  SQL_SMALLINT* = 5
  SQL_FLOAT* = 6
  SQL_REAL* = 7
  SQL_DOUBLE* = 8
  SQL_DATETIME* = 9
  SQL_VARCHAR* = 12
  SQL_TYPE_DATE* = 91
  SQL_TYPE_TIME* = 92
  SQL_TYPE_TIMESTAMP* = 93
  SQL_DATE* = 9
  SQL_TIME* = 10
  SQL_TIMESTAMP* = 11
  SQL_INTERVAL* = 10
  SQL_GUID* = - 11            # interval codes

when ODBCVER >= 0x0300:
  const
    SQL_CODE_YEAR* = 1
    SQL_CODE_MONTH* = 2
    SQL_CODE_DAY* = 3
    SQL_CODE_HOUR* = 4
    SQL_CODE_MINUTE* = 5
    SQL_CODE_SECOND* = 6
    SQL_CODE_YEAR_TO_MONTH* = 7
    SQL_CODE_DAY_TO_HOUR* = 8
    SQL_CODE_DAY_TO_MINUTE* = 9
    SQL_CODE_DAY_TO_SECOND* = 10
    SQL_CODE_HOUR_TO_MINUTE* = 11
    SQL_CODE_HOUR_TO_SECOND* = 12
    SQL_CODE_MINUTE_TO_SECOND* = 13
    SQL_INTERVAL_YEAR* = 100 + SQL_CODE_YEAR
    SQL_INTERVAL_MONTH* = 100 + SQL_CODE_MONTH
    SQL_INTERVAL_DAY* = 100 + SQL_CODE_DAY
    SQL_INTERVAL_HOUR* = 100 + SQL_CODE_HOUR
    SQL_INTERVAL_MINUTE* = 100 + SQL_CODE_MINUTE
    SQL_INTERVAL_SECOND* = 100 + SQL_CODE_SECOND
    SQL_INTERVAL_YEAR_TO_MONTH* = 100 + SQL_CODE_YEAR_TO_MONTH
    SQL_INTERVAL_DAY_TO_HOUR* = 100 + SQL_CODE_DAY_TO_HOUR
    SQL_INTERVAL_DAY_TO_MINUTE* = 100 + SQL_CODE_DAY_TO_MINUTE
    SQL_INTERVAL_DAY_TO_SECOND* = 100 + SQL_CODE_DAY_TO_SECOND
    SQL_INTERVAL_HOUR_TO_MINUTE* = 100 + SQL_CODE_HOUR_TO_MINUTE
    SQL_INTERVAL_HOUR_TO_SECOND* = 100 + SQL_CODE_HOUR_TO_SECOND
    SQL_INTERVAL_MINUTE_TO_SECOND* = 100 + SQL_CODE_MINUTE_TO_SECOND
else:
  const
    SQL_INTERVAL_YEAR* = - 80
    SQL_INTERVAL_MONTH* = - 81
    SQL_INTERVAL_YEAR_TO_MONTH* = - 82
    SQL_INTERVAL_DAY* = - 83
    SQL_INTERVAL_HOUR* = - 84
    SQL_INTERVAL_MINUTE* = - 85
    SQL_INTERVAL_SECOND* = - 86
    SQL_INTERVAL_DAY_TO_HOUR* = - 87
    SQL_INTERVAL_DAY_TO_MINUTE* = - 88
    SQL_INTERVAL_DAY_TO_SECOND* = - 89
    SQL_INTERVAL_HOUR_TO_MINUTE* = - 90
    SQL_INTERVAL_HOUR_TO_SECOND* = - 91
    SQL_INTERVAL_MINUTE_TO_SECOND* = - 92


when ODBCVER < 0x0300:
  const
    SQL_UNICODE* = - 95
    SQL_UNICODE_VARCHAR* = - 96
    SQL_UNICODE_LONGVARCHAR* = - 97
    SQL_UNICODE_CHAR* = SQL_UNICODE
else:
  # The previous definitions for SQL_UNICODE_ are historical and obsolete
  const
    SQL_UNICODE* = SQL_WCHAR
    SQL_UNICODE_VARCHAR* = SQL_WVARCHAR
    SQL_UNICODE_LONGVARCHAR* = SQL_WLONGVARCHAR
    SQL_UNICODE_CHAR* = SQL_WCHAR
const                         # C datatype to SQL datatype mapping
  SQL_C_CHAR* = SQL_CHAR
  SQL_C_LONG* = SQL_INTEGER
  SQL_C_SHORT* = SQL_SMALLINT
  SQL_C_FLOAT* = SQL_REAL
  SQL_C_DOUBLE* = SQL_DOUBLE
  SQL_C_NUMERIC* = SQL_NUMERIC
  SQL_C_DEFAULT* = 99
  SQL_SIGNED_OFFSET* = - 20
  SQL_UNSIGNED_OFFSET* = - 22
  SQL_C_DATE* = SQL_DATE
  SQL_C_TIME* = SQL_TIME
  SQL_C_TIMESTAMP* = SQL_TIMESTAMP
  SQL_C_TYPE_DATE* = SQL_TYPE_DATE
  SQL_C_TYPE_TIME* = SQL_TYPE_TIME
  SQL_C_TYPE_TIMESTAMP* = SQL_TYPE_TIMESTAMP
  SQL_C_INTERVAL_YEAR* = SQL_INTERVAL_YEAR
  SQL_C_INTERVAL_MONTH* = SQL_INTERVAL_MONTH
  SQL_C_INTERVAL_DAY* = SQL_INTERVAL_DAY
  SQL_C_INTERVAL_HOUR* = SQL_INTERVAL_HOUR
  SQL_C_INTERVAL_MINUTE* = SQL_INTERVAL_MINUTE
  SQL_C_INTERVAL_SECOND* = SQL_INTERVAL_SECOND
  SQL_C_INTERVAL_YEAR_TO_MONTH* = SQL_INTERVAL_YEAR_TO_MONTH
  SQL_C_INTERVAL_DAY_TO_HOUR* = SQL_INTERVAL_DAY_TO_HOUR
  SQL_C_INTERVAL_DAY_TO_MINUTE* = SQL_INTERVAL_DAY_TO_MINUTE
  SQL_C_INTERVAL_DAY_TO_SECOND* = SQL_INTERVAL_DAY_TO_SECOND
  SQL_C_INTERVAL_HOUR_TO_MINUTE* = SQL_INTERVAL_HOUR_TO_MINUTE
  SQL_C_INTERVAL_HOUR_TO_SECOND* = SQL_INTERVAL_HOUR_TO_SECOND
  SQL_C_INTERVAL_MINUTE_TO_SECOND* = SQL_INTERVAL_MINUTE_TO_SECOND
  SQL_C_BINARY* = SQL_BINARY
  SQL_C_BIT* = SQL_BIT
  SQL_C_SBIGINT* = SQL_BIGINT + SQL_SIGNED_OFFSET # SIGNED BIGINT
  SQL_C_UBIGINT* = SQL_BIGINT + SQL_UNSIGNED_OFFSET # UNSIGNED BIGINT
  SQL_C_TINYINT* = SQL_TINYINT
  SQL_C_SLONG* = SQL_C_LONG + SQL_SIGNED_OFFSET # SIGNED INTEGER
  SQL_C_SSHORT* = SQL_C_SHORT + SQL_SIGNED_OFFSET # SIGNED SMALLINT
  SQL_C_STINYINT* = SQL_TINYINT + SQL_SIGNED_OFFSET # SIGNED TINYINT
  SQL_C_ULONG* = SQL_C_LONG + SQL_UNSIGNED_OFFSET # UNSIGNED INTEGER
  SQL_C_USHORT* = SQL_C_SHORT + SQL_UNSIGNED_OFFSET # UNSIGNED SMALLINT
  SQL_C_UTINYINT* = SQL_TINYINT + SQL_UNSIGNED_OFFSET # UNSIGNED TINYINT
  SQL_C_BOOKMARK* = SQL_C_ULONG # BOOKMARK
  SQL_C_GUID* = SQL_GUID
  SQL_TYPE_NULL* = 0

when ODBCVER < 0x0300:
  const
    SQL_TYPE_MIN* = SQL_BIT
    SQL_TYPE_MAX* = SQL_VARCHAR

const
  SQL_C_VARBOOKMARK* = SQL_C_BINARY
  SQL_API_SQLDESCRIBEPARAM* = 58
  SQL_NO_TOTAL* = - 4

type
  SQL_DATE_STRUCT* {.final, pure.} = object
    Year*: TSqlSmallInt
    Month*: SqlUSmallInt
    Day*: SqlUSmallInt

  PSQL_DATE_STRUCT* = ptr SQL_DATE_STRUCT
  SQL_TIME_STRUCT* {.final, pure.} = object
    Hour*: SqlUSmallInt
    Minute*: SqlUSmallInt
    Second*: SqlUSmallInt

  PSQL_TIME_STRUCT* = ptr SQL_TIME_STRUCT
  SQL_TIMESTAMP_STRUCT* {.final, pure.} = object
    Year*: SqlUSmallInt
    Month*: SqlUSmallInt
    Day*: SqlUSmallInt
    Hour*: SqlUSmallInt
    Minute*: SqlUSmallInt
    Second*: SqlUSmallInt
    Fraction*: SqlUInteger

  PSQL_TIMESTAMP_STRUCT* = ptr SQL_TIMESTAMP_STRUCT

const
  SQL_NAME_LEN* = 128
  SQL_OV_ODBC3* = 3
  SQL_OV_ODBC2* = 2
  SQL_ATTR_ODBC_VERSION* = 200 # Options for SQLDriverConnect
  SQL_DRIVER_NOPROMPT* = 0
  SQL_DRIVER_COMPLETE* = 1
  SQL_DRIVER_PROMPT* = 2
  SQL_DRIVER_COMPLETE_REQUIRED* = 3
  SQL_IS_POINTER* = (- 4)  # whether an attribute is a pointer or not
  SQL_IS_UINTEGER* = (- 5)
  SQL_IS_INTEGER* = (- 6)
  SQL_IS_USMALLINT* = (- 7)
  SQL_IS_SMALLINT* = (- 8)    # SQLExtendedFetch "fFetchType" values
  SQL_FETCH_BOOKMARK* = 8
  SQL_SCROLL_OPTIONS* = 44    # SQL_USE_BOOKMARKS options
  SQL_UB_OFF* = 0
  SQL_UB_ON* = 1
  SQL_UB_DEFAULT* = SQL_UB_OFF
  SQL_UB_FIXED* = SQL_UB_ON
  SQL_UB_VARIABLE* = 2        # SQL_SCROLL_OPTIONS masks
  SQL_SO_FORWARD_ONLY* = 0x00000001
  SQL_SO_KEYSET_DRIVEN* = 0x00000002
  SQL_SO_DYNAMIC* = 0x00000004
  SQL_SO_MIXED* = 0x00000008
  SQL_SO_STATIC* = 0x00000010
  SQL_BOOKMARK_PERSISTENCE* = 82
  SQL_STATIC_SENSITIVITY* = 83 # SQL_BOOKMARK_PERSISTENCE values
  SQL_BP_CLOSE* = 0x00000001
  SQL_BP_DELETE* = 0x00000002
  SQL_BP_DROP* = 0x00000004
  SQL_BP_TRANSACTION* = 0x00000008
  SQL_BP_UPDATE* = 0x00000010
  SQL_BP_OTHER_HSTMT* = 0x00000020
  SQL_BP_SCROLL* = 0x00000040
  SQL_DYNAMIC_CURSOR_ATTRIBUTES1* = 144
  SQL_DYNAMIC_CURSOR_ATTRIBUTES2* = 145
  SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1* = 146
  SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2* = 147
  SQL_INDEX_KEYWORDS* = 148
  SQL_INFO_SCHEMA_VIEWS* = 149
  SQL_KEYSET_CURSOR_ATTRIBUTES1* = 150
  SQL_KEYSET_CURSOR_ATTRIBUTES2* = 151
  SQL_STATIC_CURSOR_ATTRIBUTES1* = 167
  SQL_STATIC_CURSOR_ATTRIBUTES2* = 168 # supported SQLFetchScroll FetchOrientation's
  SQL_CA1_NEXT* = 1
  SQL_CA1_ABSOLUTE* = 2
  SQL_CA1_RELATIVE* = 4
  SQL_CA1_BOOKMARK* = 8       # supported SQLSetPos LockType's
  SQL_CA1_LOCK_NO_CHANGE* = 0x00000040
  SQL_CA1_LOCK_EXCLUSIVE* = 0x00000080
  SQL_CA1_LOCK_UNLOCK* = 0x00000100 # supported SQLSetPos Operations
  SQL_CA1_POS_POSITION* = 0x00000200
  SQL_CA1_POS_UPDATE* = 0x00000400
  SQL_CA1_POS_DELETE* = 0x00000800
  SQL_CA1_POS_REFRESH* = 0x00001000 # positioned updates and deletes
  SQL_CA1_POSITIONED_UPDATE* = 0x00002000
  SQL_CA1_POSITIONED_DELETE* = 0x00004000
  SQL_CA1_SELECT_FOR_UPDATE* = 0x00008000 # supported SQLBulkOperations operations
  SQL_CA1_BULK_ADD* = 0x00010000
  SQL_CA1_BULK_UPDATE_BY_BOOKMARK* = 0x00020000
  SQL_CA1_BULK_DELETE_BY_BOOKMARK* = 0x00040000
  SQL_CA1_BULK_FETCH_BY_BOOKMARK* = 0x00080000 # supported values for SQL_ATTR_SCROLL_CONCURRENCY
  SQL_CA2_READ_ONLY_CONCURRENCY* = 1
  SQL_CA2_LOCK_CONCURRENCY* = 2
  SQL_CA2_OPT_ROWVER_CONCURRENCY* = 4
  SQL_CA2_OPT_VALUES_CONCURRENCY* = 8 # sensitivity of the cursor to its own inserts, deletes, and updates
  SQL_CA2_SENSITIVITY_ADDITIONS* = 0x00000010
  SQL_CA2_SENSITIVITY_DELETIONS* = 0x00000020
  SQL_CA2_SENSITIVITY_UPDATES* = 0x00000040 #  semantics of SQL_ATTR_MAX_ROWS
  SQL_CA2_MAX_ROWS_SELECT* = 0x00000080
  SQL_CA2_MAX_ROWS_INSERT* = 0x00000100
  SQL_CA2_MAX_ROWS_DELETE* = 0x00000200
  SQL_CA2_MAX_ROWS_UPDATE* = 0x00000400
  SQL_CA2_MAX_ROWS_CATALOG* = 0x00000800
  SQL_CA2_MAX_ROWS_AFFECTS_ALL* = (SQL_CA2_MAX_ROWS_SELECT or
      SQL_CA2_MAX_ROWS_INSERT or SQL_CA2_MAX_ROWS_DELETE or
      SQL_CA2_MAX_ROWS_UPDATE or SQL_CA2_MAX_ROWS_CATALOG) # semantics of
                                                           # SQL_DIAG_CURSOR_ROW_COUNT
  SQL_CA2_CRC_EXACT* = 0x00001000
  SQL_CA2_CRC_APPROXIMATE* = 0x00002000 #  the kinds of positioned statements that can be simulated
  SQL_CA2_SIMULATE_NON_UNIQUE* = 0x00004000
  SQL_CA2_SIMULATE_TRY_UNIQUE* = 0x00008000
  SQL_CA2_SIMULATE_UNIQUE* = 0x00010000 #  Operations in SQLBulkOperations
  SQL_ADD* = 4
  SQL_SETPOS_MAX_OPTION_VALUE* = SQL_ADD
  SQL_UPDATE_BY_BOOKMARK* = 5
  SQL_DELETE_BY_BOOKMARK* = 6
  SQL_FETCH_BY_BOOKMARK* = 7  # Operations in SQLSetPos
  SQL_POSITION* = 0
  SQL_REFRESH* = 1
  SQL_UPDATE* = 2
  SQL_DELETE* = 3             # Lock options in SQLSetPos
  SQL_LOCK_NO_CHANGE* = 0
  SQL_LOCK_EXCLUSIVE* = 1
  SQL_LOCK_UNLOCK* = 2        # SQLExtendedFetch "rgfRowStatus" element values
  SQL_ROW_SUCCESS* = 0
  SQL_ROW_DELETED* = 1
  SQL_ROW_UPDATED* = 2
  SQL_ROW_NOROW* = 3
  SQL_ROW_ADDED* = 4
  SQL_ROW_ERROR* = 5
  SQL_ROW_SUCCESS_WITH_INFO* = 6
  SQL_ROW_PROCEED* = 0
  SQL_ROW_IGNORE* = 1
  SQL_MAX_DSN_LENGTH* = 32    # maximum data source name size
  SQL_MAX_OPTION_STRING_LENGTH* = 256
  SQL_ODBC_CURSORS* = 110
  SQL_ATTR_ODBC_CURSORS* = SQL_ODBC_CURSORS # SQL_ODBC_CURSORS options
  SQL_CUR_USE_IF_NEEDED* = 0
  SQL_CUR_USE_ODBC* = 1
  SQL_CUR_USE_DRIVER* = 2
  SQL_CUR_DEFAULT* = SQL_CUR_USE_DRIVER
  SQL_PARAM_TYPE_UNKNOWN* = 0
  SQL_PARAM_INPUT* = 1
  SQL_PARAM_INPUT_OUTPUT* = 2
  SQL_RESULT_COL* = 3
  SQL_PARAM_OUTPUT* = 4
  SQL_RETURN_VALUE* = 5       # special length/indicator values
  SQL_NULL_DATA* = (- 1)
  SQL_DATA_AT_EXEC* = (- 2)
  SQL_SUCCESS* = 0
  SQL_SUCCESS_WITH_INFO* = 1
  SQL_NO_DATA* = 100
  SQL_ERROR* = (- 1)
  SQL_INVALID_HANDLE* = (- 2)
  SQL_STILL_EXECUTING* = 2
  SQL_NEED_DATA* = 99         # flags for null-terminated string
  SQL_NTS* = (- 3)            # maximum message length
  SQL_MAX_MESSAGE_LENGTH* = 512 # date/time length constants
  SQL_DATE_LEN* = 10
  SQL_TIME_LEN* = 8           # add P+1 if precision is nonzero
  SQL_TIMESTAMP_LEN* = 19     # add P+1 if precision is nonzero
                              # handle type identifiers
  SQL_HANDLE_ENV* = 1
  SQL_HANDLE_DBC* = 2
  SQL_HANDLE_STMT* = 3
  SQL_HANDLE_DESC* = 4        # environment attribute
  SQL_ATTR_OUTPUT_NTS* = 10001 # connection attributes
  SQL_ATTR_AUTO_IPD* = 10001
  SQL_ATTR_METADATA_ID* = 10014 # statement attributes
  SQL_ATTR_APP_ROW_DESC* = 10010
  SQL_ATTR_APP_PARAM_DESC* = 10011
  SQL_ATTR_IMP_ROW_DESC* = 10012
  SQL_ATTR_IMP_PARAM_DESC* = 10013
  SQL_ATTR_CURSOR_SCROLLABLE* = (- 1)
  SQL_ATTR_CURSOR_SENSITIVITY* = (- 2)
  SQL_QUERY_TIMEOUT* = 0
  SQL_MAX_ROWS* = 1
  SQL_NOSCAN* = 2
  SQL_MAX_LENGTH* = 3
  SQL_ASYNC_ENABLE* = 4       # same as SQL_ATTR_ASYNC_ENABLE */
  SQL_BIND_TYPE* = 5
  SQL_CURSOR_TYPE* = 6
  SQL_CONCURRENCY* = 7
  SQL_KEYSET_SIZE* = 8
  SQL_ROWSET_SIZE* = 9
  SQL_SIMULATE_CURSOR* = 10
  SQL_RETRIEVE_DATA* = 11
  SQL_USE_BOOKMARKS* = 12
  SQL_GET_BOOKMARK* = 13      #      GetStmtOption Only */
  SQL_ROW_NUMBER* = 14        #      GetStmtOption Only */
  SQL_ATTR_CURSOR_TYPE* = SQL_CURSOR_TYPE
  SQL_ATTR_CONCURRENCY* = SQL_CONCURRENCY
  SQL_ATTR_FETCH_BOOKMARK_PTR* = 16
  SQL_ATTR_ROW_STATUS_PTR* = 25
  SQL_ATTR_ROWS_FETCHED_PTR* = 26
  SQL_AUTOCOMMIT* = 102
  SQL_ATTR_AUTOCOMMIT* = SQL_AUTOCOMMIT
  SQL_ATTR_ROW_NUMBER* = SQL_ROW_NUMBER
  SQL_TXN_ISOLATION* = 108
  SQL_ATTR_TXN_ISOLATION* = SQL_TXN_ISOLATION
  SQL_ATTR_MAX_ROWS* = SQL_MAX_ROWS
  SQL_ATTR_USE_BOOKMARKS* = SQL_USE_BOOKMARKS #* connection attributes */
  SQL_ACCESS_MODE* = 101      #  SQL_AUTOCOMMIT              =102;
  SQL_LOGIN_TIMEOUT* = 103
  SQL_OPT_TRACE* = 104
  SQL_OPT_TRACEFILE* = 105
  SQL_TRANSLATE_DLL* = 106
  SQL_TRANSLATE_OPTION* = 107 #  SQL_TXN_ISOLATION           =108;
  SQL_CURRENT_QUALIFIER* = 109 #  SQL_ODBC_CURSORS            =110;
  SQL_QUIET_MODE* = 111
  SQL_PACKET_SIZE* = 112      #* connection attributes with new names */
  SQL_ATTR_ACCESS_MODE* = SQL_ACCESS_MODE #  SQL_ATTR_AUTOCOMMIT                       =SQL_AUTOCOMMIT;
  SQL_ATTR_CONNECTION_DEAD* = 1209 #* GetConnectAttr only */
  SQL_ATTR_CONNECTION_TIMEOUT* = 113
  SQL_ATTR_CURRENT_CATALOG* = SQL_CURRENT_QUALIFIER
  SQL_ATTR_DISCONNECT_BEHAVIOR* = 114
  SQL_ATTR_ENLIST_IN_DTC* = 1207
  SQL_ATTR_ENLIST_IN_XA* = 1208
  SQL_ATTR_LOGIN_TIMEOUT* = SQL_LOGIN_TIMEOUT #  SQL_ATTR_ODBC_CURSORS             =SQL_ODBC_CURSORS;
  SQL_ATTR_PACKET_SIZE* = SQL_PACKET_SIZE
  SQL_ATTR_QUIET_MODE* = SQL_QUIET_MODE
  SQL_ATTR_TRACE* = SQL_OPT_TRACE
  SQL_ATTR_TRACEFILE* = SQL_OPT_TRACEFILE
  SQL_ATTR_TRANSLATE_LIB* = SQL_TRANSLATE_DLL
  SQL_ATTR_TRANSLATE_OPTION* = SQL_TRANSLATE_OPTION #  SQL_ATTR_TXN_ISOLATION                  =SQL_TXN_ISOLATION;
                                                    #* SQL_ACCESS_MODE options */
  SQL_MODE_READ_WRITE* = 0
  SQL_MODE_READ_ONLY* = 1
  SQL_MODE_DEFAULT* = SQL_MODE_READ_WRITE #* SQL_AUTOCOMMIT options */
  SQL_AUTOCOMMIT_OFF* = 0
  SQL_AUTOCOMMIT_ON* = 1
  SQL_AUTOCOMMIT_DEFAULT* = SQL_AUTOCOMMIT_ON # SQL_ATTR_CURSOR_SCROLLABLE values
  SQL_NONSCROLLABLE* = 0
  SQL_SCROLLABLE* = 1         # SQL_CURSOR_TYPE options
  SQL_CURSOR_FORWARD_ONLY* = 0
  SQL_CURSOR_KEYSET_DRIVEN* = 1
  SQL_CURSOR_DYNAMIC* = 2
  SQL_CURSOR_STATIC* = 3
  SQL_CURSOR_TYPE_DEFAULT* = SQL_CURSOR_FORWARD_ONLY # Default value
                                                     # SQL_CONCURRENCY options
  SQL_CONCUR_READ_ONLY* = 1
  SQL_CONCUR_LOCK* = 2
  SQL_CONCUR_ROWVER* = 3
  SQL_CONCUR_VALUES* = 4
  SQL_CONCUR_DEFAULT* = SQL_CONCUR_READ_ONLY # Default value
                                             # identifiers of fields in the SQL descriptor
  SQL_DESC_COUNT* = 1001
  SQL_DESC_TYPE* = 1002
  SQL_DESC_LENGTH* = 1003
  SQL_DESC_OCTET_LENGTH_PTR* = 1004
  SQL_DESC_PRECISION* = 1005
  SQL_DESC_SCALE* = 1006
  SQL_DESC_DATETIME_INTERVAL_CODE* = 1007
  SQL_DESC_NULLABLE* = 1008
  SQL_DESC_INDICATOR_PTR* = 1009
  SQL_DESC_DATA_PTR* = 1010
  SQL_DESC_NAME* = 1011
  SQL_DESC_UNNAMED* = 1012
  SQL_DESC_OCTET_LENGTH* = 1013
  SQL_DESC_ALLOC_TYPE* = 1099 # identifiers of fields in the diagnostics area
  SQL_DIAG_RETURNCODE* = 1
  SQL_DIAG_NUMBER* = 2
  SQL_DIAG_ROW_COUNT* = 3
  SQL_DIAG_SQLSTATE* = 4
  SQL_DIAG_NATIVE* = 5
  SQL_DIAG_MESSAGE_TEXT* = 6
  SQL_DIAG_DYNAMIC_FUNCTION* = 7
  SQL_DIAG_CLASS_ORIGIN* = 8
  SQL_DIAG_SUBCLASS_ORIGIN* = 9
  SQL_DIAG_CONNECTION_NAME* = 10
  SQL_DIAG_SERVER_NAME* = 11
  SQL_DIAG_DYNAMIC_FUNCTION_CODE* = 12 # dynamic function codes
  SQL_DIAG_ALTER_TABLE* = 4
  SQL_DIAG_CREATE_INDEX* = (- 1)
  SQL_DIAG_CREATE_TABLE* = 77
  SQL_DIAG_CREATE_VIEW* = 84
  SQL_DIAG_DELETE_WHERE* = 19
  SQL_DIAG_DROP_INDEX* = (- 2)
  SQL_DIAG_DROP_TABLE* = 32
  SQL_DIAG_DROP_VIEW* = 36
  SQL_DIAG_DYNAMIC_DELETE_CURSOR* = 38
  SQL_DIAG_DYNAMIC_UPDATE_CURSOR* = 81
  SQL_DIAG_GRANT* = 48
  SQL_DIAG_INSERT* = 50
  SQL_DIAG_REVOKE* = 59
  SQL_DIAG_SELECT_CURSOR* = 85
  SQL_DIAG_UNKNOWN_STATEMENT* = 0
  SQL_DIAG_UPDATE_WHERE* = 82 # Statement attribute values for cursor sensitivity
  SQL_UNSPECIFIED* = 0
  SQL_INSENSITIVE* = 1
  SQL_SENSITIVE* = 2          # GetTypeInfo() request for all data types
  SQL_ALL_TYPES* = 0          # Default conversion code for SQLBindCol(), SQLBindParam() and SQLGetData()
  SQL_DEFAULT* = 99 # SQLGetData() code indicating that the application row descriptor
                    #    specifies the data type
  SQL_ARD_TYPE* = (- 99)      # SQL date/time type subcodes
  SQL_CODE_DATE* = 1
  SQL_CODE_TIME* = 2
  SQL_CODE_TIMESTAMP* = 3     # CLI option values
  SQL_FALSE* = 0
  SQL_TRUE* = 1               # values of NULLABLE field in descriptor
  SQL_NO_NULLS* = 0
  SQL_NULLABLE* = 1 # Value returned by SQLGetTypeInfo() to denote that it is
                    # not known whether or not a data type supports null values.
  SQL_NULLABLE_UNKNOWN* = 2
  SQL_CLOSE* = 0
  SQL_DROP* = 1
  SQL_UNBIND* = 2
  SQL_RESET_PARAMS* = 3 # Codes used for FetchOrientation in SQLFetchScroll(),
                        #   and in SQLDataSources()
  SQL_FETCH_NEXT* = 1
  SQL_FETCH_FIRST* = 2
  SQL_FETCH_FIRST_USER* = 31
  SQL_FETCH_FIRST_SYSTEM* = 32 # Other codes used for FetchOrientation in SQLFetchScroll()
  SQL_FETCH_LAST* = 3
  SQL_FETCH_PRIOR* = 4
  SQL_FETCH_ABSOLUTE* = 5
  SQL_FETCH_RELATIVE* = 6
  SQL_NULL_HENV* = SqlHEnv(nil)
  SQL_NULL_HDBC* = SqlHDBC(nil)
  SQL_NULL_HSTMT* = SqlHStmt(nil)
  SQL_NULL_HDESC* = SqlHDesc(nil) #* null handle used in place of parent handle when allocating HENV */
  SQL_NULL_HANDLE* = SqlHandle(nil) #* Values that may appear in the result set of SQLSpecialColumns() */
  SQL_SCOPE_CURROW* = 0
  SQL_SCOPE_TRANSACTION* = 1
  SQL_SCOPE_SESSION* = 2      #* Column types and scopes in SQLSpecialColumns.  */
  SQL_BEST_ROWID* = 1
  SQL_ROWVER* = 2
  SQL_ROW_IDENTIFIER* = 1     #* Reserved values for UNIQUE argument of SQLStatistics() */
  SQL_INDEX_UNIQUE* = 0
  SQL_INDEX_ALL* = 1          #* Reserved values for RESERVED argument of SQLStatistics() */
  SQL_QUICK* = 0
  SQL_ENSURE* = 1             #* Values that may appear in the result set of SQLStatistics() */
  SQL_TABLE_STAT* = 0
  SQL_INDEX_CLUSTERED* = 1
  SQL_INDEX_HASHED* = 2
  SQL_INDEX_OTHER* = 3
  SQL_SCROLL_CONCURRENCY* = 43
  SQL_TXN_CAPABLE* = 46
  SQL_TRANSACTION_CAPABLE* = SQL_TXN_CAPABLE
  SQL_USER_NAME* = 47
  SQL_TXN_ISOLATION_OPTION* = 72
  SQL_TRANSACTION_ISOLATION_OPTION* = SQL_TXN_ISOLATION_OPTION
  SQL_OJ_CAPABILITIES* = 115
  SQL_OUTER_JOIN_CAPABILITIES* = SQL_OJ_CAPABILITIES
  SQL_XOPEN_CLI_YEAR* = 10000
  SQL_CURSOR_SENSITIVITY* = 10001
  SQL_DESCRIBE_PARAMETER* = 10002
  SQL_CATALOG_NAME* = 10003
  SQL_COLLATION_SEQ* = 10004
  SQL_MAX_IDENTIFIER_LEN* = 10005
  SQL_MAXIMUM_IDENTIFIER_LENGTH* = SQL_MAX_IDENTIFIER_LEN
  SQL_SCCO_READ_ONLY* = 1
  SQL_SCCO_LOCK* = 2
  SQL_SCCO_OPT_ROWVER* = 4
  SQL_SCCO_OPT_VALUES* = 8    #* SQL_TXN_CAPABLE values */
  SQL_TC_NONE* = 0
  SQL_TC_DML* = 1
  SQL_TC_ALL* = 2
  SQL_TC_DDL_COMMIT* = 3
  SQL_TC_DDL_IGNORE* = 4      #* SQL_TXN_ISOLATION_OPTION bitmasks */
  SQL_TXN_READ_UNCOMMITTED* = 1
  SQL_TRANSACTION_READ_UNCOMMITTED* = SQL_TXN_READ_UNCOMMITTED
  SQL_TXN_READ_COMMITTED* = 2
  SQL_TRANSACTION_READ_COMMITTED* = SQL_TXN_READ_COMMITTED
  SQL_TXN_REPEATABLE_READ* = 4
  SQL_TRANSACTION_REPEATABLE_READ* = SQL_TXN_REPEATABLE_READ
  SQL_TXN_SERIALIZABLE* = 8
  SQL_TRANSACTION_SERIALIZABLE* = SQL_TXN_SERIALIZABLE
  SQL_SS_ADDITIONS* = 1
  SQL_SS_DELETIONS* = 2
  SQL_SS_UPDATES* = 4         # SQLColAttributes defines
  SQL_COLUMN_COUNT* = 0
  SQL_COLUMN_NAME* = 1
  SQL_COLUMN_TYPE* = 2
  SQL_COLUMN_LENGTH* = 3
  SQL_COLUMN_PRECISION* = 4
  SQL_COLUMN_SCALE* = 5
  SQL_COLUMN_DISPLAY_SIZE* = 6
  SQL_COLUMN_NULLABLE* = 7
  SQL_COLUMN_UNSIGNED* = 8
  SQL_COLUMN_MONEY* = 9
  SQL_COLUMN_UPDATABLE* = 10
  SQL_COLUMN_AUTO_INCREMENT* = 11
  SQL_COLUMN_CASE_SENSITIVE* = 12
  SQL_COLUMN_SEARCHABLE* = 13
  SQL_COLUMN_TYPE_NAME* = 14
  SQL_COLUMN_TABLE_NAME* = 15
  SQL_COLUMN_OWNER_NAME* = 16
  SQL_COLUMN_QUALIFIER_NAME* = 17
  SQL_COLUMN_LABEL* = 18
  SQL_COLATT_OPT_MAX* = SQL_COLUMN_LABEL
  SQL_COLUMN_DRIVER_START* = 1000
  SQL_DESC_ARRAY_SIZE* = 20
  SQL_DESC_ARRAY_STATUS_PTR* = 21
  SQL_DESC_AUTO_UNIQUE_VALUE* = SQL_COLUMN_AUTO_INCREMENT
  SQL_DESC_BASE_COLUMN_NAME* = 22
  SQL_DESC_BASE_TABLE_NAME* = 23
  SQL_DESC_BIND_OFFSET_PTR* = 24
  SQL_DESC_BIND_TYPE* = 25
  SQL_DESC_CASE_SENSITIVE* = SQL_COLUMN_CASE_SENSITIVE
  SQL_DESC_CATALOG_NAME* = SQL_COLUMN_QUALIFIER_NAME
  SQL_DESC_CONCISE_TYPE* = SQL_COLUMN_TYPE
  SQL_DESC_DATETIME_INTERVAL_PRECISION* = 26
  SQL_DESC_DISPLAY_SIZE* = SQL_COLUMN_DISPLAY_SIZE
  SQL_DESC_FIXED_PREC_SCALE* = SQL_COLUMN_MONEY
  SQL_DESC_LABEL* = SQL_COLUMN_LABEL
  SQL_DESC_LITERAL_PREFIX* = 27
  SQL_DESC_LITERAL_SUFFIX* = 28
  SQL_DESC_LOCAL_TYPE_NAME* = 29
  SQL_DESC_MAXIMUM_SCALE* = 30
  SQL_DESC_MINIMUM_SCALE* = 31
  SQL_DESC_NUM_PREC_RADIX* = 32
  SQL_DESC_PARAMETER_TYPE* = 33
  SQL_DESC_ROWS_PROCESSED_PTR* = 34
  SQL_DESC_SCHEMA_NAME* = SQL_COLUMN_OWNER_NAME
  SQL_DESC_SEARCHABLE* = SQL_COLUMN_SEARCHABLE
  SQL_DESC_TYPE_NAME* = SQL_COLUMN_TYPE_NAME
  SQL_DESC_TABLE_NAME* = SQL_COLUMN_TABLE_NAME
  SQL_DESC_UNSIGNED* = SQL_COLUMN_UNSIGNED
  SQL_DESC_UPDATABLE* = SQL_COLUMN_UPDATABLE #* SQLEndTran() options */
  SQL_COMMIT* = 0
  SQL_ROLLBACK* = 1
  SQL_ATTR_ROW_ARRAY_SIZE* = 27 #* SQLConfigDataSource() options */
  ODBC_ADD_DSN* = 1
  ODBC_CONFIG_DSN* = 2
  ODBC_REMOVE_DSN* = 3
  ODBC_ADD_SYS_DSN* = 4
  ODBC_CONFIG_SYS_DSN* = 5
  ODBC_REMOVE_SYS_DSN* = 6

  SQL_ACTIVE_CONNECTIONS* = 0   # SQLGetInfo
  SQL_DATA_SOURCE_NAME* = 2
  SQL_DATA_SOURCE_READ_ONLY* = 25
  SQL_DATABASE_NAME* = 2
  SQL_DBMS_NAME* = 17
  SQL_DBMS_VERSION* = 18
  SQL_DRIVER_HDBC* = 3
  SQL_DRIVER_HENV* = 4
  SQL_DRIVER_HSTMT* = 5
  SQL_DRIVER_NAME* = 6
  SQL_DRIVER_VER* = 7
  SQL_FETCH_DIRECTION* = 8
  SQL_ODBC_VER* = 10
  SQL_DRIVER_ODBC_VER* = 77
  SQL_SERVER_NAME* = 13
  SQL_ACTIVE_ENVIRONMENTS* = 116
  SQL_ACTIVE_STATEMENTS* = 1
  SQL_SQL_CONFORMANCE* = 118
  SQL_DATETIME_LITERALS* = 119
  SQL_ASYNC_MODE* = 10021
  SQL_BATCH_ROW_COUNT* = 120
  SQL_BATCH_SUPPORT* = 121
  SQL_CATALOG_LOCATION* = 114
  #SQL_CATALOG_NAME* = 10003
  SQL_CATALOG_NAME_SEPARATOR* = 41
  SQL_CATALOG_TERM* = 42
  SQL_CATALOG_USAGE* = 92
  #SQL_COLLATION_SEQ* = 10004
  SQL_COLUMN_ALIAS* = 87
  #SQL_USER_NAME* = 47

proc SQLAllocHandle*(HandleType: TSqlSmallInt, InputHandle: SqlHandle,
                     OutputHandlePtr: var SqlHandle): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLSetEnvAttr*(EnvironmentHandle: SqlHEnv, Attribute: TSqlInteger,
                    Value: SqlPointer, StringLength: TSqlInteger): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLGetEnvAttr*(EnvironmentHandle: SqlHEnv, Attribute: TSqlInteger,
                    Value: SqlPointer, BufferLength: TSqlInteger,
                    StringLength: PSQLINTEGER): TSqlSmallInt{.dynlib: odbclib,
    importc.}
proc SQLFreeHandle*(HandleType: TSqlSmallInt, Handle: SqlHandle): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLGetDiagRec*(HandleType: TSqlSmallInt, Handle: SqlHandle,
                    RecNumber: TSqlSmallInt, Sqlstate: PSQLCHAR,
                    NativeError: var TSqlInteger, MessageText: PSQLCHAR,
                    BufferLength: TSqlSmallInt, TextLength: var TSqlSmallInt): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLGetDiagField*(HandleType: TSqlSmallInt, Handle: SqlHandle,
                      RecNumber: TSqlSmallInt, DiagIdentifier: TSqlSmallInt,
                      DiagInfoPtr: SqlPointer, BufferLength: TSqlSmallInt,
                      StringLengthPtr: var TSqlSmallInt): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLConnect*(ConnectionHandle: SqlHDBC, ServerName: PSQLCHAR,
                 NameLength1: TSqlSmallInt, UserName: PSQLCHAR,
                 NameLength2: TSqlSmallInt, Authentication: PSQLCHAR,
                 NameLength3: TSqlSmallInt): TSqlSmallInt{.dynlib: odbclib, importc.}
proc SQLDisconnect*(ConnectionHandle: SqlHDBC): TSqlSmallInt{.dynlib: odbclib,
    importc.}
proc SQLDriverConnect*(hdbc: SqlHDBC, hwnd: SqlHWND, szCsin: cstring,
                       szCLen: TSqlSmallInt, szCsout: cstring,
                       cbCSMax: TSqlSmallInt, cbCsOut: var TSqlSmallInt,
                       f: SqlUSmallInt): TSqlSmallInt{.dynlib: odbclib, importc.}
proc SQLBrowseConnect*(hdbc: SqlHDBC, szConnStrIn: PSQLCHAR,
                       cbConnStrIn: TSqlSmallInt, szConnStrOut: PSQLCHAR,
                       cbConnStrOutMax: TSqlSmallInt,
                       cbConnStrOut: var TSqlSmallInt): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLExecDirect*(StatementHandle: SqlHStmt, StatementText: PSQLCHAR,
                    TextLength: TSqlInteger): TSqlSmallInt{.dynlib: odbclib, importc.}
proc SQLExecDirectW*(StatementHandle: SqlHStmt, StatementText: WideCString,
                    TextLength: TSqlInteger): TSqlSmallInt{.dynlib: odbclib, importc.}
proc SQLPrepare*(StatementHandle: SqlHStmt, StatementText: PSQLCHAR,
                 TextLength: TSqlInteger): TSqlSmallInt{.dynlib: odbclib, importc.}
proc SQLPrepareW*(StatementHandle: SqlHStmt, StatementText: WideCString,
                 TextLength: TSqlInteger): TSqlSmallInt{.dynlib: odbclib, importc.}
proc SQLCloseCursor*(StatementHandle: SqlHStmt): TSqlSmallInt{.dynlib: odbclib,
    importc.}
proc SQLExecute*(StatementHandle: SqlHStmt): TSqlSmallInt{.dynlib: odbclib, importc.}
proc SQLFetch*(StatementHandle: SqlHStmt): TSqlSmallInt{.dynlib: odbclib, importc.}
proc SQLNumResultCols*(StatementHandle: SqlHStmt, ColumnCount: var TSqlSmallInt): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLDescribeCol*(StatementHandle: SqlHStmt, ColumnNumber: SqlUSmallInt,
                     ColumnName: PSQLCHAR, BufferLength: TSqlSmallInt,
                     NameLength: var TSqlSmallInt, DataType: var TSqlSmallInt,
                     ColumnSize: var TSqlULen,
                     DecimalDigits: var TSqlSmallInt, Nullable: var TSqlSmallInt): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLFetchScroll*(StatementHandle: SqlHStmt, FetchOrientation: TSqlSmallInt,
                     FetchOffset: TSqlLen): TSqlSmallInt{.dynlib: odbclib,
    importc.}
proc SQLExtendedFetch*(hstmt: SqlHStmt, fFetchType: SqlUSmallInt,
                       irow: TSqlLen, pcrow: var TSqlULen,
                       rgfRowStatus: PSQLUSMALLINT): TSqlSmallInt{.dynlib: odbclib,
    importc.}
proc SQLGetData*(StatementHandle: SqlHStmt, ColumnNumber: SqlUSmallInt,
                 TargetType: TSqlSmallInt, TargetValue: SqlPointer,
                 BufferLength: TSqlLen, StrLen_or_Ind: ptr TSqlLen): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLSetStmtAttr*(StatementHandle: SqlHStmt, Attribute: TSqlInteger,
                     Value: SqlPointer, StringLength: TSqlInteger): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLGetStmtAttr*(StatementHandle: SqlHStmt, Attribute: TSqlInteger,
                     Value: SqlPointer, BufferLength: TSqlInteger,
                     StringLength: PSQLINTEGER): TSqlSmallInt{.dynlib: odbclib,
    importc.}
proc SQLGetInfo*(ConnectionHandle: SqlHDBC, InfoType: SqlUSmallInt,
                 InfoValue: SqlPointer, BufferLength: TSqlSmallInt,
                 StringLength: PSQLSMALLINT): TSqlSmallInt{.dynlib: odbclib,
    importc.}
proc SQLBulkOperations*(StatementHandle: SqlHStmt, Operation: SqlUSmallInt): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLPutData*(StatementHandle: SqlHStmt, Data: SqlPointer,
                 StrLen_or_Ind: TSQLLEN): TSqlSmallInt{.dynlib: odbclib, importc.}
proc SQLBindCol*(StatementHandle: SqlHStmt, ColumnNumber: SqlUSmallInt,
                 TargetType: TSqlSmallInt, TargetValue: SqlPointer,
                 BufferLength: TSqlLEN, StrLen_or_Ind: PSQLINTEGER): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLSetPos*(hstmt: SqlHStmt, irow: SqlUSmallInt, fOption: SqlUSmallInt,
                fLock: SqlUSmallInt): TSqlSmallInt{.dynlib: odbclib, importc.}
proc SQLDataSources*(EnvironmentHandle: SqlHEnv, Direction: SqlUSmallInt,
                     ServerName: PSQLCHAR, BufferLength1: TSqlSmallInt,
                     NameLength1: PSQLSMALLINT, Description: PSQLCHAR,
                     BufferLength2: TSqlSmallInt, NameLength2: PSQLSMALLINT): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLDrivers*(EnvironmentHandle: SqlHEnv, Direction: SqlUSmallInt,
                 DriverDescription: PSQLCHAR, BufferLength1: TSqlSmallInt,
                 DescriptionLength1: PSQLSMALLINT, DriverAttributes: PSQLCHAR,
                 BufferLength2: TSqlSmallInt, AttributesLength2: PSQLSMALLINT): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLSetConnectAttr*(ConnectionHandle: SqlHDBC, Attribute: TSqlInteger,
                        Value: SqlPointer, StringLength: TSqlInteger): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLGetCursorName*(StatementHandle: SqlHStmt, CursorName: PSQLCHAR,
                       BufferLength: TSqlSmallInt, NameLength: PSQLSMALLINT): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLSetCursorName*(StatementHandle: SqlHStmt, CursorName: PSQLCHAR,
                       NameLength: TSqlSmallInt): TSqlSmallInt{.dynlib: odbclib,
    importc.}
proc SQLRowCount*(StatementHandle: SqlHStmt, RowCount: var TSQLLEN): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLBindParameter*(hstmt: SqlHStmt, ipar: SqlUSmallInt,
                       fParamType: TSqlSmallInt, fCType: TSqlSmallInt,
                       fSqlType: TSqlSmallInt, cbColDef: TSQLULEN,
                       ibScale: TSqlSmallInt, rgbValue: SqlPointer,
                       cbValueMax: TSQLLEN, pcbValue: var TSQLLEN): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLFreeStmt*(StatementHandle: SqlHStmt, Option: SqlUSmallInt): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLColAttribute*(StatementHandle: SqlHStmt, ColumnNumber: SqlUSmallInt,
                      FieldIdentifier: SqlUSmallInt,
                      CharacterAttribute: PSQLCHAR, BufferLength: TSqlSmallInt,
                      StringLength: PSQLSMALLINT,
                      NumericAttribute: TSQLLEN): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLEndTran*(HandleType: TSqlSmallInt, Handle: SqlHandle,
                 CompletionType: TSqlSmallInt): TSqlSmallInt{.dynlib: odbclib,
    importc.}
proc SQLTables*(hstmt: SqlHStmt, szTableQualifier: PSQLCHAR,
                cbTableQualifier: TSqlSmallInt, szTableOwner: PSQLCHAR,
                cbTableOwner: TSqlSmallInt, szTableName: PSQLCHAR,
                cbTableName: TSqlSmallInt, szTableType: PSQLCHAR,
                cbTableType: TSqlSmallInt): TSqlSmallInt{.dynlib: odbclib, importc.}
proc SQLColumns*(hstmt: SqlHStmt, szTableQualifier: PSQLCHAR,
                 cbTableQualifier: TSqlSmallInt, szTableOwner: PSQLCHAR,
                 cbTableOwner: TSqlSmallInt, szTableName: PSQLCHAR,
                 cbTableName: TSqlSmallInt, szColumnName: PSQLCHAR,
                 cbColumnName: TSqlSmallInt): TSqlSmallInt{.dynlib: odbclib, importc.}
proc SQLSpecialColumns*(StatementHandle: SqlHStmt, IdentifierType: SqlUSmallInt,
                        CatalogName: PSQLCHAR, NameLength1: TSqlSmallInt,
                        SchemaName: PSQLCHAR, NameLength2: TSqlSmallInt,
                        TableName: PSQLCHAR, NameLength3: TSqlSmallInt,
                        Scope: SqlUSmallInt,
                        Nullable: SqlUSmallInt): TSqlSmallInt{.
    dynlib: odbclib, importc.}
proc SQLProcedures*(hstmt: SqlHStmt, szTableQualifier: PSQLCHAR,
                    cbTableQualifier: TSqlSmallInt, szTableOwner: PSQLCHAR,
                    cbTableOwner: TSqlSmallInt, szTableName: PSQLCHAR,
                    cbTableName: TSqlSmallInt): TSqlSmallInt{.dynlib: odbclib,
    importc.}
proc SQLPrimaryKeys*(hstmt: SqlHStmt, CatalogName: PSQLCHAR,
                     NameLength1: TSqlSmallInt, SchemaName: PSQLCHAR,
                     NameLength2: TSqlSmallInt, TableName: PSQLCHAR,
                     NameLength3: TSqlSmallInt): TSqlSmallInt{.dynlib: odbclib,
    importc.}
proc SQLProcedureColumns*(hstmt: SqlHStmt, CatalogName: PSQLCHAR,
                          NameLength1: TSqlSmallInt, SchemaName: PSQLCHAR,
                          NameLength2: TSqlSmallInt, ProcName: PSQLCHAR,
                          NameLength3: TSqlSmallInt, ColumnName: PSQLCHAR,
                          NameLength4: TSqlSmallInt): TSqlSmallInt{.dynlib: odbclib,
    importc.}
proc SQLStatistics*(hstmt: SqlHStmt, CatalogName: PSQLCHAR,
                    NameLength1: TSqlSmallInt, SchemaName: PSQLCHAR,
                    NameLength2: TSqlSmallInt, TableName: PSQLCHAR,
                    NameLength3: TSqlSmallInt, Unique: SqlUSmallInt,
                    Reserved: SqlUSmallInt): TSqlSmallInt {.
                    dynlib: odbclib, importc.}
proc SQLErr*(henv: SqlHEnv, hdbc: SqlHDBC, hstmt: SqlHStmt,
              szSqlState, pfNativeError, szErrorMsg: PSQLCHAR,
              cbErrorMsgMax: TSqlSmallInt,
              pcbErrorMsg: PSQLSMALLINT): TSqlSmallInt {.
                    dynlib: odbclib, importc: "SQLError".}

{.pop.}
when defined(nimHasStyleChecks):
  {.pop.}
