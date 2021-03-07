#
#
#            Nim's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

{.push, callconv: cdecl.}
when defined(nimHasStyleChecks):
  {.push styleChecks: off.}

when defined(unix):
  when defined(macosx):
    const
      lib = "(libmysqlclient|libmariadbclient)(|.20|.19|.18|.17|.16|.15).dylib"
  else:
    const
      lib = "(libmysqlclient|libmariadbclient).so(|.20|.19|.18|.17|.16|.15)"
when defined(windows):
  const
    lib = "(libmysql.dll|libmariadb.dll)"
type
  my_bool* = bool
  Pmy_bool* = ptr my_bool
  PVIO* = pointer
  Pgptr* = ptr gptr
  gptr* = cstring
  Pmy_socket* = ptr my_socket
  my_socket* = cint
  PPByte* = pointer
  cuint* = cint

#  ------------ Start of declaration in "mysql_com.h"   ---------------------
#
#  ** Common definition between mysql server & client
#
# Field/table name length

const
  NAME_LEN* = 64
  HOSTNAME_LENGTH* = 60
  USERNAME_LENGTH* = 16
  SERVER_VERSION_LENGTH* = 60
  SQLSTATE_LENGTH* = 5
  LOCAL_HOST* = "localhost"
  LOCAL_HOST_NAMEDPIPE* = '.'

const
  NAMEDPIPE* = "MySQL"
  SERVICENAME* = "MySQL"

type
  Enum_server_command* = enum
    COM_SLEEP, COM_QUIT, COM_INIT_DB, COM_QUERY, COM_FIELD_LIST, COM_CREATE_DB,
    COM_DROP_DB, COM_REFRESH, COM_SHUTDOWN, COM_STATISTICS, COM_PROCESS_INFO,
    COM_CONNECT, COM_PROCESS_KILL, COM_DEBUG, COM_PING, COM_TIME,
    COM_DELAYED_INSERT, COM_CHANGE_USER, COM_BINLOG_DUMP, COM_TABLE_DUMP,
    COM_CONNECT_OUT, COM_REGISTER_SLAVE, COM_STMT_PREPARE, COM_STMT_EXECUTE,
    COM_STMT_SEND_LONG_DATA, COM_STMT_CLOSE, COM_STMT_RESET, COM_SET_OPTION,
    COM_STMT_FETCH, COM_END
{.deprecated: [Tenum_server_command: Enum_server_command].}

const
  SCRAMBLE_LENGTH* = 20 # Length of random string sent by server on handshake;
                        # this is also length of obfuscated password,
                        # received from client
  SCRAMBLE_LENGTH_323* = 8    # length of password stored in the db:
                              # new passwords are preceded with '*'
  SCRAMBLED_PASSWORD_CHAR_LENGTH* = SCRAMBLE_LENGTH * 2 + 1
  SCRAMBLED_PASSWORD_CHAR_LENGTH_323* = SCRAMBLE_LENGTH_323 * 2
  NOT_NULL_FLAG* = 1          #  Field can't be NULL
  PRI_KEY_FLAG* = 2           #  Field is part of a primary key
  UNIQUE_KEY_FLAG* = 4        #  Field is part of a unique key
  MULTIPLE_KEY_FLAG* = 8      #  Field is part of a key
  BLOB_FLAG* = 16             #  Field is a blob
  UNSIGNED_FLAG* = 32         #  Field is unsigned
  ZEROFILL_FLAG* = 64         #  Field is zerofill
  BINARY_FLAG* = 128          #  Field is binary
                              # The following are only sent to new clients
  ENUM_FLAG* = 256            # field is an enum
  AUTO_INCREMENT_FLAG* = 512  # field is a autoincrement field
  TIMESTAMP_FLAG* = 1024      # Field is a timestamp
  SET_FLAG* = 2048            # field is a set
  NO_DEFAULT_VALUE_FLAG* = 4096 # Field doesn't have default value
  NUM_FLAG* = 32768           # Field is num (for clients)
  PART_KEY_FLAG* = 16384      # Intern; Part of some key
  GROUP_FLAG* = 32768         # Intern: Group field
  UNIQUE_FLAG* = 65536        # Intern: Used by sql_yacc
  BINCMP_FLAG* = 131072       # Intern: Used by sql_yacc
  REFRESH_GRANT* = 1          # Refresh grant tables
  REFRESH_LOG* = 2            # Start on new log file
  REFRESH_TABLES* = 4         # close all tables
  REFRESH_HOSTS* = 8          # Flush host cache
  REFRESH_STATUS* = 16        # Flush status variables
  REFRESH_THREADS* = 32       # Flush thread cache
  REFRESH_SLAVE* = 64         # Reset master info and restart slave thread
  REFRESH_MASTER* = 128 # Remove all bin logs in the index and truncate the index
                        # The following can't be set with mysql_refresh()
  REFRESH_READ_LOCK* = 16384  # Lock tables for read
  REFRESH_FAST* = 32768       # Intern flag
  REFRESH_QUERY_CACHE* = 65536 # RESET (remove all queries) from query cache
  REFRESH_QUERY_CACHE_FREE* = 0x00020000 # pack query cache
  REFRESH_DES_KEY_FILE* = 0x00040000
  REFRESH_USER_RESOURCES* = 0x00080000
  CLIENT_LONG_PASSWORD* = 1   # new more secure passwords
  CLIENT_FOUND_ROWS* = 2      # Found instead of affected rows
  CLIENT_LONG_FLAG* = 4       # Get all column flags
  CLIENT_CONNECT_WITH_DB* = 8 # One can specify db on connect
  CLIENT_NO_SCHEMA* = 16      # Don't allow database.table.column
  CLIENT_COMPRESS* = 32       # Can use compression protocol
  CLIENT_ODBC* = 64           # Odbc client
  CLIENT_LOCAL_FILES* = 128   # Can use LOAD DATA LOCAL
  CLIENT_IGNORE_SPACE* = 256  # Ignore spaces before '('
  CLIENT_PROTOCOL_41* = 512   # New 4.1 protocol
  CLIENT_INTERACTIVE* = 1024  # This is an interactive client
  CLIENT_SSL* = 2048          # Switch to SSL after handshake
  CLIENT_IGNORE_SIGPIPE* = 4096 # IGNORE sigpipes
  CLIENT_TRANSACTIONS* = 8192 # Client knows about transactions
  CLIENT_RESERVED* = 16384    # Old flag for 4.1 protocol
  CLIENT_SECURE_CONNECTION* = 32768 # New 4.1 authentication
  CLIENT_MULTI_STATEMENTS* = 65536 # Enable/disable multi-stmt support
  CLIENT_MULTI_RESULTS* = 131072 # Enable/disable multi-results
  CLIENT_REMEMBER_OPTIONS*: int = 1 shl 31
  SERVER_STATUS_IN_TRANS* = 1 # Transaction has started
  SERVER_STATUS_AUTOCOMMIT* = 2 # Server in auto_commit mode
  SERVER_STATUS_MORE_RESULTS* = 4 # More results on server
  SERVER_MORE_RESULTS_EXISTS* = 8 # Multi query - next query exists
  SERVER_QUERY_NO_GOOD_INDEX_USED* = 16
  SERVER_QUERY_NO_INDEX_USED* = 32 # The server was able to fulfill the clients request and opened a
                                   #      read-only non-scrollable cursor for a query. This flag comes
                                   #      in reply to COM_STMT_EXECUTE and COM_STMT_FETCH commands.
  SERVER_STATUS_CURSOR_EXISTS* = 64 # This flag is sent when a read-only cursor is exhausted, in reply to
                                    #      COM_STMT_FETCH command.
  SERVER_STATUS_LAST_ROW_SENT* = 128
  SERVER_STATUS_DB_DROPPED* = 256 # A database was dropped
  SERVER_STATUS_NO_BACKSLASH_ESCAPES* = 512
  ERRMSG_SIZE* = 200
  NET_READ_TIMEOUT* = 30      # Timeout on read
  NET_WRITE_TIMEOUT* = 60     # Timeout on write
  NET_WAIT_TIMEOUT* = 8 * 60 * 60 # Wait for new query
  ONLY_KILL_QUERY* = 1

const
  MAX_TINYINT_WIDTH* = 3      # Max width for a TINY w.o. sign
  MAX_SMALLINT_WIDTH* = 5     # Max width for a SHORT w.o. sign
  MAX_MEDIUMINT_WIDTH* = 8    # Max width for a INT24 w.o. sign
  MAX_INT_WIDTH* = 10         # Max width for a LONG w.o. sign
  MAX_BIGINT_WIDTH* = 20      # Max width for a LONGLONG
  MAX_CHAR_WIDTH* = 255       # Max length for a CHAR column
  MAX_BLOB_WIDTH* = 8192      # Default width for blob

type
  Pst_net* = ptr St_net
  St_net*{.final.} = object
    vio*: PVIO
    buff*: cstring
    buff_end*: cstring
    write_pos*: cstring
    read_pos*: cstring
    fd*: my_socket            # For Perl DBI/dbd
    max_packet*: int
    max_packet_size*: int
    pkt_nr*: cuint
    compress_pkt_nr*: cuint
    write_timeout*: cuint
    read_timeout*: cuint
    retry_count*: cuint
    fcntl*: cint
    compress*: my_bool #   The following variable is set if we are doing several queries in one
                       #        command ( as in LOAD TABLE ... FROM MASTER ),
                       #        and do not want to confuse the client with OK at the wrong time
    remain_in_buf*: int
    len*: int
    buf_length*: int
    where_b*: int
    return_status*: ptr cint
    reading_or_writing*: char
    save_char*: cchar
    no_send_ok*: my_bool      # For SPs and other things that do multiple stmts
    no_send_eof*: my_bool     # For SPs' first version read-only cursors
    no_send_error*: my_bool # Set if OK packet is already sent, and
                            # we do not need to send error messages
                            #   Pointer to query object in query cache, do not equal NULL (0) for
                            #        queries in cache that have not stored its results yet
                            # $endif
    last_error*: array[0..(ERRMSG_SIZE) - 1, char]
    sqlstate*: array[0..(SQLSTATE_LENGTH + 1) - 1, char]
    last_errno*: cuint
    error*: char
    query_cache_query*: gptr
    report_error*: my_bool    # We should report error (we have unreported error)
    return_errno*: my_bool

  NET* = St_net
  PNET* = ptr NET
{.deprecated: [Tst_net: St_net, TNET: NET].}

const
  packet_error* = - 1

type
  Enum_field_types* = enum    # For backward compatibility
    TYPE_DECIMAL, TYPE_TINY, TYPE_SHORT, TYPE_LONG, TYPE_FLOAT, TYPE_DOUBLE,
    TYPE_NULL, TYPE_TIMESTAMP, TYPE_LONGLONG, TYPE_INT24, TYPE_DATE, TYPE_TIME,
    TYPE_DATETIME, TYPE_YEAR, TYPE_NEWDATE, TYPE_VARCHAR, TYPE_BIT,
    TYPE_NEWDECIMAL = 246, TYPE_ENUM = 247, TYPE_SET = 248,
    TYPE_TINY_BLOB = 249, TYPE_MEDIUM_BLOB = 250, TYPE_LONG_BLOB = 251,
    TYPE_BLOB = 252, TYPE_VAR_STRING = 253, TYPE_STRING = 254,
    TYPE_GEOMETRY = 255
{.deprecated: [Tenum_field_types: Enum_field_types].}

const
  CLIENT_MULTI_QUERIES* = CLIENT_MULTI_STATEMENTS
  FIELD_TYPE_DECIMAL* = TYPE_DECIMAL
  FIELD_TYPE_NEWDECIMAL* = TYPE_NEWDECIMAL
  FIELD_TYPE_TINY* = TYPE_TINY
  FIELD_TYPE_SHORT* = TYPE_SHORT
  FIELD_TYPE_LONG* = TYPE_LONG
  FIELD_TYPE_FLOAT* = TYPE_FLOAT
  FIELD_TYPE_DOUBLE* = TYPE_DOUBLE
  FIELD_TYPE_NULL* = TYPE_NULL
  FIELD_TYPE_TIMESTAMP* = TYPE_TIMESTAMP
  FIELD_TYPE_LONGLONG* = TYPE_LONGLONG
  FIELD_TYPE_INT24* = TYPE_INT24
  FIELD_TYPE_DATE* = TYPE_DATE
  FIELD_TYPE_TIME* = TYPE_TIME
  FIELD_TYPE_DATETIME* = TYPE_DATETIME
  FIELD_TYPE_YEAR* = TYPE_YEAR
  FIELD_TYPE_NEWDATE* = TYPE_NEWDATE
  FIELD_TYPE_ENUM* = TYPE_ENUM
  FIELD_TYPE_SET* = TYPE_SET
  FIELD_TYPE_TINY_BLOB* = TYPE_TINY_BLOB
  FIELD_TYPE_MEDIUM_BLOB* = TYPE_MEDIUM_BLOB
  FIELD_TYPE_LONG_BLOB* = TYPE_LONG_BLOB
  FIELD_TYPE_BLOB* = TYPE_BLOB
  FIELD_TYPE_VAR_STRING* = TYPE_VAR_STRING
  FIELD_TYPE_STRING* = TYPE_STRING
  FIELD_TYPE_CHAR* = TYPE_TINY
  FIELD_TYPE_INTERVAL* = TYPE_ENUM
  FIELD_TYPE_GEOMETRY* = TYPE_GEOMETRY
  FIELD_TYPE_BIT* = TYPE_BIT  # Shutdown/kill enums and constants
                              # Bits for THD::killable.
  SHUTDOWN_KILLABLE_CONNECT* = chr(1 shl 0)
  SHUTDOWN_KILLABLE_TRANS* = chr(1 shl 1)
  SHUTDOWN_KILLABLE_LOCK_TABLE* = chr(1 shl 2)
  SHUTDOWN_KILLABLE_UPDATE* = chr(1 shl 3)

type
  Enum_shutdown_level* = enum
    SHUTDOWN_DEFAULT = 0, SHUTDOWN_WAIT_CONNECTIONS = 1,
    SHUTDOWN_WAIT_TRANSACTIONS = 2, SHUTDOWN_WAIT_UPDATES = 8,
    SHUTDOWN_WAIT_ALL_BUFFERS = 16, SHUTDOWN_WAIT_CRITICAL_BUFFERS = 17,
    KILL_QUERY = 254, KILL_CONNECTION = 255
  Enum_cursor_type* = enum    # options for mysql_set_option
    CURSOR_TYPE_NO_CURSOR = 0, CURSOR_TYPE_READ_ONLY = 1,
    CURSOR_TYPE_FOR_UPDATE = 2, CURSOR_TYPE_SCROLLABLE = 4
  Enum_mysql_set_option* = enum
    OPTION_MULTI_STATEMENTS_ON, OPTION_MULTI_STATEMENTS_OFF
{.deprecated: [Tenum_shutdown_level: Enum_shutdown_level,
              Tenum_cursor_type: Enum_cursor_type,
              Tenum_mysql_set_option: Enum_mysql_set_option].}

proc my_net_init*(net: PNET, vio: PVIO): my_bool{.cdecl, dynlib: lib,
    importc: "my_net_init".}
proc my_net_local_init*(net: PNET){.cdecl, dynlib: lib,
                                    importc: "my_net_local_init".}
proc net_end*(net: PNET){.cdecl, dynlib: lib, importc: "net_end".}
proc net_clear*(net: PNET){.cdecl, dynlib: lib, importc: "net_clear".}
proc net_realloc*(net: PNET, len: int): my_bool{.cdecl, dynlib: lib,
    importc: "net_realloc".}
proc net_flush*(net: PNET): my_bool{.cdecl, dynlib: lib, importc: "net_flush".}
proc my_net_write*(net: PNET, packet: cstring, length: int): my_bool{.cdecl,
    dynlib: lib, importc: "my_net_write".}
proc net_write_command*(net: PNET, command: char, header: cstring,
                        head_len: int, packet: cstring, length: int): my_bool{.
    cdecl, dynlib: lib, importc: "net_write_command".}
proc net_real_write*(net: PNET, packet: cstring, length: int): cint{.cdecl,
    dynlib: lib, importc: "net_real_write".}
proc my_net_read*(net: PNET): int{.cdecl, dynlib: lib, importc: "my_net_read".}
  # The following function is not meant for normal usage
  #      Currently it's used internally by manager.c
type
  Psockaddr* = ptr Sockaddr
  Sockaddr*{.final.} = object  # undefined structure
{.deprecated: [Tsockaddr: Sockaddr].}

proc my_connect*(s: my_socket, name: Psockaddr, namelen: cuint, timeout: cuint): cint{.
    cdecl, dynlib: lib, importc: "my_connect".}
type
  Prand_struct* = ptr Rand_struct
  Rand_struct*{.final.} = object # The following is for user defined functions
    seed1*: int
    seed2*: int
    max_value*: int
    max_value_dbl*: cdouble

  Item_result* = enum
    STRING_RESULT, REAL_RESULT, INT_RESULT, ROW_RESULT, DECIMAL_RESULT
  PItem_result* = ptr Item_result
  Pst_udf_args* = ptr St_udf_args
  St_udf_args*{.final.} = object
    arg_count*: cuint         # Number of arguments
    arg_type*: PItem_result   # Pointer to item_results
    args*: cstringArray       # Pointer to item_results
    lengths*: ptr int         # Length of string arguments
    maybe_null*: cstring      # Length of string arguments
    attributes*: cstringArray # Pointer to attribute name
    attribute_lengths*: ptr int # Length of attribute arguments

  UDF_ARGS* = St_udf_args
  PUDF_ARGS* = ptr UDF_ARGS   # This holds information about the result
  Pst_udf_init* = ptr St_udf_init
  St_udf_init*{.final.} = object
    maybe_null*: my_bool      # 1 if function can return NULL
    decimals*: cuint          # for real functions
    max_length*: int          # For string functions
    theptr*: cstring          # free pointer for function data
    const_item*: my_bool      # free pointer for function data

  UDF_INIT* = St_udf_init
  PUDF_INIT* = ptr UDF_INIT   # Constants when using compression
{.deprecated: [Trand_stuct: Rand_struct, TItem_result: Item_result,
              Tst_udf_args: St_udf_args, TUDF_ARGS: UDF_ARGS,
              Tst_udf_init: St_udf_init, TUDF_INIT: UDF_INIT].}

const
  NET_HEADER_SIZE* = 4        # standard header size
  COMP_HEADER_SIZE* = 3 # compression header extra size
                        # Prototypes to password functions
                        # These functions are used for authentication by client and server and
                        #      implemented in sql/password.c

proc randominit*(para1: Prand_struct, seed1: int, seed2: int){.cdecl,
    dynlib: lib, importc: "randominit".}
proc my_rnd*(para1: Prand_struct): cdouble{.cdecl, dynlib: lib,
    importc: "my_rnd".}
proc create_random_string*(fto: cstring, len: cuint, rand_st: Prand_struct){.
    cdecl, dynlib: lib, importc: "create_random_string".}
proc hash_password*(fto: int, password: cstring, password_len: cuint){.cdecl,
    dynlib: lib, importc: "hash_password".}
proc make_scrambled_password_323*(fto: cstring, password: cstring){.cdecl,
    dynlib: lib, importc: "make_scrambled_password_323".}
proc scramble_323*(fto: cstring, message: cstring, password: cstring){.cdecl,
    dynlib: lib, importc: "scramble_323".}
proc check_scramble_323*(para1: cstring, message: cstring, salt: int): my_bool{.
    cdecl, dynlib: lib, importc: "check_scramble_323".}
proc get_salt_from_password_323*(res: ptr int, password: cstring){.cdecl,
    dynlib: lib, importc: "get_salt_from_password_323".}
proc make_password_from_salt_323*(fto: cstring, salt: ptr int){.cdecl,
    dynlib: lib, importc: "make_password_from_salt_323".}
proc octet2hex*(fto: cstring, str: cstring, length: cuint): cstring{.cdecl,
    dynlib: lib, importc: "octet2hex".}
proc make_scrambled_password*(fto: cstring, password: cstring){.cdecl,
    dynlib: lib, importc: "make_scrambled_password".}
proc scramble*(fto: cstring, message: cstring, password: cstring){.cdecl,
    dynlib: lib, importc: "scramble".}
proc check_scramble*(reply: cstring, message: cstring, hash_stage2: pointer): my_bool{.
    cdecl, dynlib: lib, importc: "check_scramble".}
proc get_salt_from_password*(res: pointer, password: cstring){.cdecl,
    dynlib: lib, importc: "get_salt_from_password".}
proc make_password_from_salt*(fto: cstring, hash_stage2: pointer){.cdecl,
    dynlib: lib, importc: "make_password_from_salt".}
  # end of password.c
proc get_tty_password*(opt_message: cstring): cstring{.cdecl, dynlib: lib,
    importc: "get_tty_password".}
proc errno_to_sqlstate*(errno: cuint): cstring{.cdecl, dynlib: lib,
    importc: "mysql_errno_to_sqlstate".}
  # Some other useful functions
proc modify_defaults_file*(file_location: cstring, option: cstring,
                           option_value: cstring, section_name: cstring,
                           remove_option: cint): cint{.cdecl, dynlib: lib,
    importc: "load_defaults".}
proc load_defaults*(conf_file: cstring, groups: cstringArray, argc: ptr cint,
                    argv: ptr cstringArray): cint{.cdecl, dynlib: lib,
    importc: "load_defaults".}
proc my_init*(): my_bool{.cdecl, dynlib: lib, importc: "my_init".}
proc my_thread_init*(): my_bool{.cdecl, dynlib: lib, importc: "my_thread_init".}
proc my_thread_end*(){.cdecl, dynlib: lib, importc: "my_thread_end".}
const
  NULL_LENGTH*: int = int(not (0)) # For net_store_length

const
  STMT_HEADER* = 4
  LONG_DATA_HEADER* = 6 #  ------------ Stop of declaration in "mysql_com.h"   -----------------------
                        # $include "mysql_time.h"
                        # $include "mysql_version.h"
                        # $include "typelib.h"
                        # $include "my_list.h" /* for LISTs used in 'MYSQL' and 'MYSQL_STMT' */
                        #      var
                        #         mysql_port : cuint;cvar;external;
                        #         mysql_unix_port : Pchar;cvar;external;

const
  CLIENT_NET_READ_TIMEOUT* = 365 * 24 * 3600 # Timeout on read
  CLIENT_NET_WRITE_TIMEOUT* = 365 * 24 * 3600 # Timeout on write

type
  Pst_mysql_field* = ptr St_mysql_field
  St_mysql_field*{.final.} = object
    name*: cstring            # Name of column
    org_name*: cstring        # Original column name, if an alias
    table*: cstring           # Table of column if column was a field
    org_table*: cstring       # Org table name, if table was an alias
    db*: cstring              # Database for table
    catalog*: cstring         # Catalog for table
    def*: cstring             # Default value (set by mysql_list_fields)
    len*: int                 # Width of column (create length)
    max_length*: int          # Max width for selected set
    name_length*: cuint
    org_name_length*: cuint
    table_length*: cuint
    org_table_length*: cuint
    db_length*: cuint
    catalog_length*: cuint
    def_length*: cuint
    flags*: cuint             # Div flags
    decimals*: cuint          # Number of decimals in field
    charsetnr*: cuint         # Character set
    ftype*: Enum_field_types  # Type of field. See mysql_com.h for types
    extension*: pointer

  FIELD* = St_mysql_field
  PFIELD* = ptr FIELD
  PROW* = ptr ROW             # return data as array of strings
  ROW* = cstringArray
  PFIELD_OFFSET* = ptr FIELD_OFFSET # offset to current field
  FIELD_OFFSET* = cuint
{.deprecated: [Tst_mysql_field: St_mysql_field, TFIELD: FIELD, TROW: ROW,
              TFIELD_OFFSET: FIELD_OFFSET].}

proc IS_PRI_KEY*(n: int32): bool
proc IS_NOT_NULL*(n: int32): bool
proc IS_BLOB*(n: int32): bool
proc IS_NUM*(t: Enum_field_types): bool
proc INTERNAL_NUM_FIELD*(f: Pst_mysql_field): bool
proc IS_NUM_FIELD*(f: Pst_mysql_field): bool
type
  my_ulonglong* = int64
  Pmy_ulonglong* = ptr my_ulonglong

const
  COUNT_ERROR* = not (my_ulonglong(0))

type
  Pst_mysql_rows* = ptr St_mysql_rows
  St_mysql_rows*{.final.} = object
    next*: Pst_mysql_rows     # list of rows
    data*: ROW
    len*: int

  ROWS* = St_mysql_rows
  PROWS* = ptr ROWS
  PROW_OFFSET* = ptr ROW_OFFSET # offset to current row
  ROW_OFFSET* = ROWS
{.deprecated: [Tst_mysql_rows: St_mysql_rows, TROWS: ROWS,
              TROW_OFFSET: ROW_OFFSET].}

const
  ALLOC_MAX_BLOCK_TO_DROP* = 4096
  ALLOC_MAX_BLOCK_USAGE_BEFORE_DROP* = 10 # struct for once_alloc (block)

type
  Pst_used_mem* = ptr St_used_mem
  St_used_mem*{.final.} = object
    next*: Pst_used_mem       # Next block in use
    left*: cuint              # memory left in block
    size*: cuint              # size of block

  USED_MEM* = St_used_mem
  PUSED_MEM* = ptr USED_MEM
  Pst_mem_root* = ptr St_mem_root
  St_mem_root*{.final.} = object
    free*: PUSED_MEM          # blocks with free memory in it
    used*: PUSED_MEM          # blocks almost without free memory
    pre_alloc*: PUSED_MEM     # preallocated block
    min_malloc*: cuint        # if block have less memory it will be put in 'used' list
    block_size*: cuint        # initial block size
    block_num*: cuint # allocated blocks counter
                      #    first free block in queue test counter (if it exceed
                      #       MAX_BLOCK_USAGE_BEFORE_DROP block will be dropped in 'used' list)
    first_block_usage*: cuint
    error_handler*: proc (){.cdecl.}

  MEM_ROOT* = St_mem_root
  PMEM_ROOT* = ptr MEM_ROOT   #  ------------ Stop of declaration in "my_alloc.h"    ----------------------
{.deprecated: [Tst_used_mem: St_used_mem, TUSED_MEM: USED_MEM,
              Tst_mem_root: St_mem_root, TMEM_ROOT: MEM_ROOT].}

type
  Pst_mysql_data* = ptr St_mysql_data
  St_mysql_data*{.final.} = object
    rows*: my_ulonglong
    fields*: cuint
    data*: PROWS
    alloc*: MEM_ROOT
    prev_ptr*: ptr PROWS

  DATA* = St_mysql_data
  PDATA* = ptr DATA
  Option* = enum
    OPT_CONNECT_TIMEOUT, OPT_COMPRESS, OPT_NAMED_PIPE, INIT_COMMAND,
    READ_DEFAULT_FILE, READ_DEFAULT_GROUP, SET_CHARSET_DIR, SET_CHARSET_NAME,
    OPT_LOCAL_INFILE, OPT_PROTOCOL, SHARED_MEMORY_BASE_NAME, OPT_READ_TIMEOUT,
    OPT_WRITE_TIMEOUT, OPT_USE_RESULT, OPT_USE_REMOTE_CONNECTION,
    OPT_USE_EMBEDDED_CONNECTION, OPT_GUESS_CONNECTION, SET_CLIENT_IP,
    SECURE_AUTH, REPORT_DATA_TRUNCATION, OPT_RECONNECT
{.deprecated: [Tst_mysql_data: St_mysql_data, TDATA: DATA, Toption: Option].}

const
  MAX_MYSQL_MANAGER_ERR* = 256
  MAX_MYSQL_MANAGER_MSG* = 256
  MANAGER_OK* = 200
  MANAGER_INFO* = 250
  MANAGER_ACCESS* = 401
  MANAGER_CLIENT_ERR* = 450
  MANAGER_INTERNAL_ERR* = 500

type
  St_dynamic_array*{.final.} = object
    buffer*: cstring
    elements*: cuint
    max_element*: cuint
    alloc_increment*: cuint
    size_of_element*: cuint

  DYNAMIC_ARRAY* = St_dynamic_array
  Pst_dynamic_array* = ptr St_dynamic_array
  Pst_mysql_options* = ptr St_mysql_options
  St_mysql_options*{.final.} = object
    connect_timeout*: cuint
    read_timeout*: cuint
    write_timeout*: cuint
    port*: cuint
    protocol*: cuint
    client_flag*: int
    host*: cstring
    user*: cstring
    password*: cstring
    unix_socket*: cstring
    db*: cstring
    init_commands*: Pst_dynamic_array
    my_cnf_file*: cstring
    my_cnf_group*: cstring
    charset_dir*: cstring
    charset_name*: cstring
    ssl_key*: cstring         # PEM key file
    ssl_cert*: cstring        # PEM cert file
    ssl_ca*: cstring          # PEM CA file
    ssl_capath*: cstring      # PEM directory of CA-s?
    ssl_cipher*: cstring      # cipher to use
    shared_memory_base_name*: cstring
    max_allowed_packet*: int
    use_ssl*: my_bool         # if to use SSL or not
    compress*: my_bool
    named_pipe*: my_bool #  On connect, find out the replication role of the server, and
                         #       establish connections to all the peers
    rpl_probe*: my_bool #  Each call to mysql_real_query() will parse it to tell if it is a read
                        #       or a write, and direct it to the slave or the master
    rpl_parse*: my_bool #  If set, never read from a master, only from slave, when doing
                        #       a read that is replication-aware
    no_master_reads*: my_bool
    separate_thread*: my_bool
    methods_to_use*: Option
    client_ip*: cstring
    secure_auth*: my_bool     # Refuse client connecting to server if it uses old (pre-4.1.1) protocol
    report_data_truncation*: my_bool # 0 - never report, 1 - always report (default)
                                     # function pointers for local infile support
    local_infile_init*: proc (para1: var pointer, para2: cstring, para3: pointer): cint{.
        cdecl.}
    local_infile_read*: proc (para1: pointer, para2: cstring, para3: cuint): cint
    local_infile_end*: proc (para1: pointer)
    local_infile_error*: proc (para1: pointer, para2: cstring, para3: cuint): cint
    local_infile_userdata*: pointer

  Status* = enum
    STATUS_READY, STATUS_GET_RESULT, STATUS_USE_RESULT
  Protocol_type* = enum  # There are three types of queries - the ones that have to go to
                          # the master, the ones that go to a slave, and the administrative
                          # type which must happen on the pivot connection
    PROTOCOL_DEFAULT, PROTOCOL_TCP, PROTOCOL_SOCKET, PROTOCOL_PIPE,
    PROTOCOL_MEMORY
  Rpl_type* = enum
    RPL_MASTER, RPL_SLAVE, RPL_ADMIN
  Charset_info_st*{.final.} = object
    number*: cuint
    primary_number*: cuint
    binary_number*: cuint
    state*: cuint
    csname*: cstring
    name*: cstring
    comment*: cstring
    tailoring*: cstring
    ftype*: cstring
    to_lower*: cstring
    to_upper*: cstring
    sort_order*: cstring
    contractions*: ptr int16
    sort_order_big*: ptr ptr int16
    tab_to_uni*: ptr int16
    tab_from_uni*: pointer    # was ^MY_UNI_IDX
    state_map*: cstring
    ident_map*: cstring
    strxfrm_multiply*: cuint
    mbminlen*: cuint
    mbmaxlen*: cuint
    min_sort_char*: int16
    max_sort_char*: int16
    escape_with_backslash_is_dangerous*: my_bool
    cset*: pointer            # was ^MY_CHARSET_HANDLER
    coll*: pointer            # was ^MY_COLLATION_HANDLER;

  CHARSET_INFO* = Charset_info_st
  Pcharset_info_st* = ptr Charset_info_st
  Pcharacter_set* = ptr Character_set
  Character_set*{.final.} = object
    number*: cuint
    state*: cuint
    csname*: cstring
    name*: cstring
    comment*: cstring
    dir*: cstring
    mbminlen*: cuint
    mbmaxlen*: cuint

  MY_CHARSET_INFO* = Character_set
  PMY_CHARSET_INFO* = ptr MY_CHARSET_INFO
  Pst_mysql_methods* = ptr St_mysql_methods
  Pst_mysql* = ptr St_mysql
  St_mysql*{.final.} = object
    net*: NET                 # Communication parameters
    connector_fd*: gptr       # ConnectorFd for SSL
    host*: cstring
    user*: cstring
    passwd*: cstring
    unix_socket*: cstring
    server_version*: cstring
    host_info*: cstring
    info*: cstring
    db*: cstring
    charset*: Pcharset_info_st
    fields*: PFIELD
    field_alloc*: MEM_ROOT
    affected_rows*: my_ulonglong
    insert_id*: my_ulonglong  # id if insert on table with NEXTNR
    extra_info*: my_ulonglong # Used by mysqlshow, not used by mysql 5.0 and up
    thread_id*: int           # Id for connection in server
    packet_length*: int
    port*: cuint
    client_flag*: int
    server_capabilities*: int
    protocol_version*: cuint
    field_count*: cuint
    server_status*: cuint
    server_language*: cuint
    warning_count*: cuint
    options*: St_mysql_options
    status*: Status
    free_me*: my_bool         # If free in mysql_close
    reconnect*: my_bool       # set to 1 if automatic reconnect
    scramble*: array[0..(SCRAMBLE_LENGTH + 1) - 1, char] # session-wide random string
                                                         #  Set if this is the original connection, not a master or a slave we have
                                                         #       added though mysql_rpl_probe() or mysql_set_master()/ mysql_add_slave()
    rpl_pivot*: my_bool #   Pointers to the master, and the next slave connections, points to
                        #        itself if lone connection.
    master*: Pst_mysql
    next_slave*: Pst_mysql
    last_used_slave*: Pst_mysql # needed for round-robin slave pick
    last_used_con*: Pst_mysql # needed for send/read/store/use result to work correctly with replication
    stmts*: pointer           # was PList, list of all statements
    methods*: Pst_mysql_methods
    thd*: pointer #   Points to boolean flag in MYSQL_RES  or MYSQL_STMT. We set this flag
                  #        from mysql_stmt_close if close had to cancel result set of this object.
    unbuffered_fetch_owner*: Pmy_bool

  MySQL* = St_mysql
  PMySQL* = ptr MySQL
  Pst_mysql_res* = ptr St_mysql_res
  St_mysql_res*{.final.} = object
    row_count*: my_ulonglong
    fields*: PFIELD
    data*: PDATA
    data_cursor*: PROWS
    lengths*: ptr int         # column lengths of current row
    handle*: PMySQL                # for unbuffered reads
    field_alloc*: MEM_ROOT
    field_count*: cuint
    current_field*: cuint
    row*: ROW                 # If unbuffered read
    current_row*: ROW         # buffer to current row
    eof*: my_bool             # Used by mysql_fetch_row
    unbuffered_fetch_cancelled*: my_bool # mysql_stmt_close() had to cancel this result
    methods*: Pst_mysql_methods

  RES* = St_mysql_res
  PRES* = ptr RES
  Pst_mysql_stmt* = ptr St_mysql_stmt
  PSTMT* = ptr STMT
  St_mysql_methods*{.final.} = object
    read_query_result*: proc (MySQL:  PMySQL): my_bool{.cdecl.}
    advanced_command*: proc (MySQL: PMySQL, command: Enum_server_command, header: cstring,
                             header_length: int, arg: cstring, arg_length: int,
                             skip_check: my_bool): my_bool
    read_rows*: proc (MySQL: PMySQL, fields: PFIELD, fields_count: cuint): PDATA
    use_result*: proc (MySQL: PMySQL): PRES
    fetch_lengths*: proc (fto: ptr int, column: ROW, field_count: cuint)
    flush_use_result*: proc (MySQL: PMySQL)
    list_fields*: proc (MySQL: PMySQL): PFIELD
    read_prepare_result*: proc (MySQL: PMySQL, stmt: PSTMT): my_bool
    stmt_execute*: proc (stmt: PSTMT): cint
    read_binary_rows*: proc (stmt: PSTMT): cint
    unbuffered_fetch*: proc (MySQL: PMySQL, row: cstringArray): cint
    free_embedded_thd*: proc (MySQL: PMySQL)
    read_statistics*: proc (MySQL: PMySQL): cstring
    next_result*: proc (MySQL: PMySQL): my_bool
    read_change_user_result*: proc (MySQL: PMySQL, buff: cstring, passwd: cstring): cint
    read_rowsfrom_cursor*: proc (stmt: PSTMT): cint

  METHODS* = St_mysql_methods
  PMETHODS* = ptr METHODS
  Pst_mysql_manager* = ptr St_mysql_manager
  St_mysql_manager*{.final.} = object
    net*: NET
    host*: cstring
    user*: cstring
    passwd*: cstring
    port*: cuint
    free_me*: my_bool
    eof*: my_bool
    cmd_status*: cint
    last_errno*: cint
    net_buf*: cstring
    net_buf_pos*: cstring
    net_data_end*: cstring
    net_buf_size*: cint
    last_error*: array[0..(MAX_MYSQL_MANAGER_ERR) - 1, char]

  MANAGER* = St_mysql_manager
  PMANAGER* = ptr MANAGER
  Pst_mysql_parameters* = ptr St_mysql_parameters
  St_mysql_parameters*{.final.} = object
    p_max_allowed_packet*: ptr int
    p_net_buffer_length*: ptr int

  PARAMETERS* = St_mysql_parameters
  PPARAMETERS* = ptr PARAMETERS
  Enum_mysql_stmt_state* = enum
    STMT_INIT_DONE = 1, STMT_PREPARE_DONE, STMT_EXECUTE_DONE, STMT_FETCH_DONE
  Pst_mysql_bind* = ptr St_mysql_bind
  St_mysql_bind*{.final.} = object
    len*: int                 # output length pointer
    is_null*: Pmy_bool        # Pointer to null indicator
    buffer*: pointer          # buffer to get/put data
    error*: Pmy_bool          # set this if you want to track data truncations happened during fetch
    buffer_type*: Enum_field_types # buffer type
    buffer_length*: int       # buffer length, must be set for str/binary
                              # Following are for internal use. Set by mysql_stmt_bind_param
    row_ptr*: ptr byte        # for the current data position
    offset*: int              # offset position for char/binary fetch
    length_value*: int        #  Used if length is 0
    param_number*: cuint      # For null count and error messages
    pack_length*: cuint       # Internal length for packed data
    error_value*: my_bool     # used if error is 0
    is_unsigned*: my_bool     # set if integer type is unsigned
    long_data_used*: my_bool  # If used with mysql_send_long_data
    is_null_value*: my_bool   # Used if is_null is 0
    store_param_func*: proc (net: PNET, param: Pst_mysql_bind){.cdecl.}
    fetch_result*: proc (para1: Pst_mysql_bind, para2: PFIELD, row: PPByte)
    skip_result*: proc (para1: Pst_mysql_bind, para2: PFIELD, row: PPByte)

  BIND* = St_mysql_bind
  PBIND* = ptr BIND           # statement handler
  St_mysql_stmt*{.final.} = object
    mem_root*: MEM_ROOT       # root allocations
    mysql*: PMySQL                      # connection handle
    params*: PBIND            # input parameters
    `bind`*: PBIND            # input parameters
    fields*: PFIELD           # result set metadata
    result*: DATA             # cached result set
    data_cursor*: PROWS       # current row in cached result
    affected_rows*: my_ulonglong # copy of mysql->affected_rows after statement execution
    insert_id*: my_ulonglong
    read_row_func*: proc (stmt: Pst_mysql_stmt, row: PPByte): cint{.cdecl.}
    stmt_id*: int             # Id for prepared statement
    flags*: int               # i.e. type of cursor to open
    prefetch_rows*: int       # number of rows per one COM_FETCH
    server_status*: cuint # Copied from mysql->server_status after execute/fetch to know
                          # server-side cursor status for this statement.
    last_errno*: cuint        # error code
    param_count*: cuint       # input parameter count
    field_count*: cuint       # number of columns in result set
    state*: Enum_mysql_stmt_state # statement state
    last_error*: array[0..(ERRMSG_SIZE) - 1, char] # error message
    sqlstate*: array[0..(SQLSTATE_LENGTH + 1) - 1, char]
    send_types_to_server*: my_bool # Types of input parameters should be sent to server
    bind_param_done*: my_bool # input buffers were supplied
    bind_result_done*: char   # output buffers were supplied
    unbuffered_fetch_cancelled*: my_bool
    update_max_length*: my_bool

  STMT* = St_mysql_stmt

  Enum_stmt_attr_type* = enum
    STMT_ATTR_UPDATE_MAX_LENGTH, STMT_ATTR_CURSOR_TYPE, STMT_ATTR_PREFETCH_ROWS
{.deprecated: [Tst_dynamic_array: St_dynamic_array, Tst_mysql_options: St_mysql_options,
              TDYNAMIC_ARRAY: DYNAMIC_ARRAY, Tprotocol_type: Protocol_type,
              Trpl_type: Rpl_type, Tcharset_info_st: Charset_info_st,
              TCHARSET_INFO: CHARSET_INFO, Tcharacter_set: Character_set,
              TMY_CHARSET_INFO: MY_CHARSET_INFO, Tst_mysql: St_mysql,
              Tst_mysql_methods: St_mysql_methods, TMySql: MySql,
              Tst_mysql_res: St_mysql_res, TMETHODS: METHODS, TRES: RES,
              Tst_mysql_manager: St_mysql_manager, TMANAGER: MANAGER,
              Tst_mysql_parameters: St_mysql_parameters, TPARAMETERS: PARAMETERS,
              Tenum_mysql_stmt_state: Enum_mysql_stmt_state,
              Tst_mysql_bind: St_mysql_bind, TBIND: BIND, Tst_mysql_stmt: St_mysql_stmt,
              TSTMT: STMT, Tenum_stmt_attr_type: Enum_stmt_attr_type,
              Tstatus: Status].}

proc server_init*(argc: cint, argv: cstringArray, groups: cstringArray): cint{.
    cdecl, dynlib: lib, importc: "mysql_server_init".}
proc server_end*(){.cdecl, dynlib: lib, importc: "mysql_server_end".}
  # mysql_server_init/end need to be called when using libmysqld or
  #      libmysqlclient (exactly, mysql_server_init() is called by mysql_init() so
  #      you don't need to call it explicitly; but you need to call
  #      mysql_server_end() to free memory). The names are a bit misleading
  #      (mysql_SERVER* to be used when using libmysqlCLIENT). So we add more general
  #      names which suit well whether you're using libmysqld or libmysqlclient. We
  #      intend to promote these aliases over the mysql_server* ones.
proc library_init*(argc: cint, argv: cstringArray, groups: cstringArray): cint{.
    cdecl, dynlib: lib, importc: "mysql_server_init".}
proc library_end*(){.cdecl, dynlib: lib, importc: "mysql_server_end".}
proc get_parameters*(): PPARAMETERS{.stdcall, dynlib: lib,
                                     importc: "mysql_get_parameters".}
  # Set up and bring down a thread; these function should be called
  #      for each thread in an application which opens at least one MySQL
  #      connection.  All uses of the connection(s) should be between these
  #      function calls.
proc thread_init*(): my_bool{.stdcall, dynlib: lib, importc: "mysql_thread_init".}
proc thread_end*(){.stdcall, dynlib: lib, importc: "mysql_thread_end".}
  # Functions to get information from the MYSQL and MYSQL_RES structures
  #      Should definitely be used if one uses shared libraries.
proc num_rows*(res: PRES): my_ulonglong{.stdcall, dynlib: lib,
    importc: "mysql_num_rows".}
proc num_fields*(res: PRES): cuint{.stdcall, dynlib: lib,
                                    importc: "mysql_num_fields".}
proc eof*(res: PRES): my_bool{.stdcall, dynlib: lib, importc: "mysql_eof".}
proc fetch_field_direct*(res: PRES, fieldnr: cuint): PFIELD{.stdcall,
    dynlib: lib, importc: "mysql_fetch_field_direct".}
proc fetch_fields*(res: PRES): PFIELD{.stdcall, dynlib: lib,
                                       importc: "mysql_fetch_fields".}
proc row_tell*(res: PRES): ROW_OFFSET{.stdcall, dynlib: lib,
                                       importc: "mysql_row_tell".}
proc field_tell*(res: PRES): FIELD_OFFSET{.stdcall, dynlib: lib,
    importc: "mysql_field_tell".}
proc field_count*(MySQL: PMySQL): cuint{.stdcall, dynlib: lib,
                               importc: "mysql_field_count".}
proc affected_rows*(MySQL: PMySQL): my_ulonglong{.stdcall, dynlib: lib,
                                        importc: "mysql_affected_rows".}
proc insert_id*(MySQL: PMySQL): my_ulonglong{.stdcall, dynlib: lib,
                                    importc: "mysql_insert_id".}
proc errno*(MySQL: PMySQL): cuint{.stdcall, dynlib: lib, importc: "mysql_errno".}
proc error*(MySQL: PMySQL): cstring{.stdcall, dynlib: lib, importc: "mysql_error".}
proc sqlstate*(MySQL: PMySQL): cstring{.stdcall, dynlib: lib, importc: "mysql_sqlstate".}
proc warning_count*(MySQL: PMySQL): cuint{.stdcall, dynlib: lib,
                                 importc: "mysql_warning_count".}
proc info*(MySQL: PMySQL): cstring{.stdcall, dynlib: lib, importc: "mysql_info".}
proc thread_id*(MySQL: PMySQL): int{.stdcall, dynlib: lib, importc: "mysql_thread_id".}
proc character_set_name*(MySQL: PMySQL): cstring{.stdcall, dynlib: lib,
                                        importc: "mysql_character_set_name".}
proc set_character_set*(MySQL: PMySQL, csname: cstring): int32{.stdcall, dynlib: lib,
    importc: "mysql_set_character_set".}
proc init*(MySQL: PMySQL): PMySQL{.stdcall, dynlib: lib, importc: "mysql_init".}
proc ssl_set*(MySQL: PMySQL, key: cstring, cert: cstring, ca: cstring, capath: cstring,
              cipher: cstring): my_bool{.stdcall, dynlib: lib,
    importc: "mysql_ssl_set".}
proc change_user*(MySQL: PMySQL, user: cstring, passwd: cstring, db: cstring): my_bool{.
    stdcall, dynlib: lib, importc: "mysql_change_user".}
proc real_connect*(MySQL: PMySQL, host: cstring, user: cstring, passwd: cstring,
                   db: cstring, port: cuint, unix_socket: cstring,
                   clientflag: int): PMySQL{.stdcall, dynlib: lib,
                                        importc: "mysql_real_connect".}
proc select_db*(MySQL: PMySQL, db: cstring): cint{.stdcall, dynlib: lib,
    importc: "mysql_select_db".}
proc query*(MySQL: PMySQL, q: cstring): cint{.stdcall, dynlib: lib, importc: "mysql_query".}
proc send_query*(MySQL: PMySQL, q: cstring, len: int): cint{.stdcall, dynlib: lib,
    importc: "mysql_send_query".}
proc real_query*(MySQL: PMySQL, q: cstring, len: int): cint{.stdcall, dynlib: lib,
    importc: "mysql_real_query".}
proc store_result*(MySQL: PMySQL): PRES{.stdcall, dynlib: lib,
                               importc: "mysql_store_result".}
proc use_result*(MySQL: PMySQL): PRES{.stdcall, dynlib: lib, importc: "mysql_use_result".}
  # perform query on master
proc master_query*(MySQL: PMySQL, q: cstring, len: int): my_bool{.stdcall, dynlib: lib,
    importc: "mysql_master_query".}
proc master_send_query*(MySQL: PMySQL, q: cstring, len: int): my_bool{.stdcall,
    dynlib: lib, importc: "mysql_master_send_query".}
  # perform query on slave
proc slave_query*(MySQL: PMySQL, q: cstring, len: int): my_bool{.stdcall, dynlib: lib,
    importc: "mysql_slave_query".}
proc slave_send_query*(MySQL: PMySQL, q: cstring, len: int): my_bool{.stdcall,
    dynlib: lib, importc: "mysql_slave_send_query".}
proc get_character_set_info*(MySQL: PMySQL, charset: PMY_CHARSET_INFO){.stdcall,
    dynlib: lib, importc: "mysql_get_character_set_info".}
  # local infile support
const
  LOCAL_INFILE_ERROR_LEN* = 512

# procedure mysql_set_local_infile_handler(mysql:PMYSQL; local_infile_init:function (para1:Ppointer; para2:Pchar; para3:pointer):longint; local_infile_read:function (para1:pointer; para2:Pchar; para3:dword):longint; local_infile_end:procedure (_pa
# para6:pointer);cdecl;external mysqllib name 'mysql_set_local_infile_handler';

proc set_local_infile_default*(MySQL: PMySQL){.cdecl, dynlib: lib,
                                     importc: "mysql_set_local_infile_default".}
  # enable/disable parsing of all queries to decide if they go on master or
  #      slave
proc enable_rpl_parse*(MySQL: PMySQL){.stdcall, dynlib: lib,
                             importc: "mysql_enable_rpl_parse".}
proc disable_rpl_parse*(MySQL: PMySQL){.stdcall, dynlib: lib,
                              importc: "mysql_disable_rpl_parse".}
  # get the value of the parse flag
proc rpl_parse_enabled*(MySQL: PMySQL): cint{.stdcall, dynlib: lib,
                                    importc: "mysql_rpl_parse_enabled".}
  #  enable/disable reads from master
proc enable_reads_from_master*(MySQL: PMySQL){.stdcall, dynlib: lib,
                                     importc: "mysql_enable_reads_from_master".}
proc disable_reads_from_master*(MySQL: PMySQL){.stdcall, dynlib: lib, importc: "mysql_disable_reads_from_master".}
  # get the value of the master read flag
proc reads_from_master_enabled*(MySQL: PMySQL): my_bool{.stdcall, dynlib: lib,
    importc: "mysql_reads_from_master_enabled".}
proc rpl_query_type*(q: cstring, length: cint): Rpl_type{.stdcall, dynlib: lib,
    importc: "mysql_rpl_query_type".}
  # discover the master and its slaves
proc rpl_probe*(MySQL: PMySQL): my_bool{.stdcall, dynlib: lib, importc: "mysql_rpl_probe".}
  # set the master, close/free the old one, if it is not a pivot
proc set_master*(MySQL: PMySQL, host: cstring, port: cuint, user: cstring, passwd: cstring): cint{.
    stdcall, dynlib: lib, importc: "mysql_set_master".}
proc add_slave*(MySQL: PMySQL, host: cstring, port: cuint, user: cstring, passwd: cstring): cint{.
    stdcall, dynlib: lib, importc: "mysql_add_slave".}
proc shutdown*(MySQL: PMySQL, shutdown_level: Enum_shutdown_level): cint{.stdcall,
    dynlib: lib, importc: "mysql_shutdown".}
proc dump_debug_info*(MySQL: PMySQL): cint{.stdcall, dynlib: lib,
                                  importc: "mysql_dump_debug_info".}
proc refresh*(sql: PMySQL, refresh_options: cuint): cint{.stdcall, dynlib: lib,
    importc: "mysql_refresh".}
proc kill*(MySQL: PMySQL, pid: int): cint{.stdcall, dynlib: lib, importc: "mysql_kill".}
proc set_server_option*(MySQL: PMySQL, option: Enum_mysql_set_option): cint{.stdcall,
    dynlib: lib, importc: "mysql_set_server_option".}
proc ping*(MySQL: PMySQL): cint{.stdcall, dynlib: lib, importc: "mysql_ping".}
proc stat*(MySQL: PMySQL): cstring{.stdcall, dynlib: lib, importc: "mysql_stat".}
proc get_server_info*(MySQL: PMySQL): cstring{.stdcall, dynlib: lib,
                                     importc: "mysql_get_server_info".}
proc get_client_info*(): cstring{.stdcall, dynlib: lib,
                                  importc: "mysql_get_client_info".}
proc get_client_version*(): int{.stdcall, dynlib: lib,
                                 importc: "mysql_get_client_version".}
proc get_host_info*(MySQL: PMySQL): cstring{.stdcall, dynlib: lib,
                                   importc: "mysql_get_host_info".}
proc get_server_version*(MySQL: PMySQL): int{.stdcall, dynlib: lib,
                                    importc: "mysql_get_server_version".}
proc get_proto_info*(MySQL: PMySQL): cuint{.stdcall, dynlib: lib,
                                  importc: "mysql_get_proto_info".}
proc list_dbs*(MySQL: PMySQL, wild: cstring): PRES{.stdcall, dynlib: lib,
    importc: "mysql_list_dbs".}
proc list_tables*(MySQL: PMySQL, wild: cstring): PRES{.stdcall, dynlib: lib,
    importc: "mysql_list_tables".}
proc list_processes*(MySQL: PMySQL): PRES{.stdcall, dynlib: lib,
                                 importc: "mysql_list_processes".}
proc options*(MySQL: PMySQL, option: Option, arg: cstring): cint{.stdcall, dynlib: lib,
    importc: "mysql_options".}
proc free_result*(result: PRES){.stdcall, dynlib: lib,
                                 importc: "mysql_free_result".}
proc data_seek*(result: PRES, offset: my_ulonglong){.stdcall, dynlib: lib,
    importc: "mysql_data_seek".}
proc row_seek*(result: PRES, offset: ROW_OFFSET): ROW_OFFSET{.stdcall,
    dynlib: lib, importc: "mysql_row_seek".}
proc field_seek*(result: PRES, offset: FIELD_OFFSET): FIELD_OFFSET{.stdcall,
    dynlib: lib, importc: "mysql_field_seek".}
proc fetch_row*(result: PRES): ROW{.stdcall, dynlib: lib,
                                    importc: "mysql_fetch_row".}
proc fetch_lengths*(result: PRES): ptr int{.stdcall, dynlib: lib,
    importc: "mysql_fetch_lengths".}
proc fetch_field*(result: PRES): PFIELD{.stdcall, dynlib: lib,
    importc: "mysql_fetch_field".}
proc list_fields*(MySQL: PMySQL, table: cstring, wild: cstring): PRES{.stdcall,
    dynlib: lib, importc: "mysql_list_fields".}
proc escape_string*(fto: cstring, `from`: cstring, from_length: int): int{.
    stdcall, dynlib: lib, importc: "mysql_escape_string".}
proc hex_string*(fto: cstring, `from`: cstring, from_length: int): int{.stdcall,
    dynlib: lib, importc: "mysql_hex_string".}
proc real_escape_string*(MySQL: PMySQL, fto: cstring, `from`: cstring, len: int): int{.
    stdcall, dynlib: lib, importc: "mysql_real_escape_string".}
proc debug*(debug: cstring){.stdcall, dynlib: lib, importc: "mysql_debug".}
  #    function mysql_odbc_escape_string(mysql:PMYSQL; fto:Pchar; to_length:dword; from:Pchar; from_length:dword;
  #               param:pointer; extend_buffer:function (para1:pointer; to:Pchar; length:Pdword):Pchar):Pchar;stdcall;external mysqllib name 'mysql_odbc_escape_string';
proc myodbc_remove_escape*(MySQL: PMySQL, name: cstring){.stdcall, dynlib: lib,
    importc: "myodbc_remove_escape".}
proc thread_safe*(): cuint{.stdcall, dynlib: lib, importc: "mysql_thread_safe".}
proc embedded*(): my_bool{.stdcall, dynlib: lib, importc: "mysql_embedded".}
proc manager_init*(con: PMANAGER): PMANAGER{.stdcall, dynlib: lib,
    importc: "mysql_manager_init".}
proc manager_connect*(con: PMANAGER, host: cstring, user: cstring,
                      passwd: cstring, port: cuint): PMANAGER{.stdcall,
    dynlib: lib, importc: "mysql_manager_connect".}
proc manager_close*(con: PMANAGER){.stdcall, dynlib: lib,
                                    importc: "mysql_manager_close".}
proc manager_command*(con: PMANAGER, cmd: cstring, cmd_len: cint): cint{.
    stdcall, dynlib: lib, importc: "mysql_manager_command".}
proc manager_fetch_line*(con: PMANAGER, res_buf: cstring, res_buf_size: cint): cint{.
    stdcall, dynlib: lib, importc: "mysql_manager_fetch_line".}
proc read_query_result*(MySQL: PMySQL): my_bool{.stdcall, dynlib: lib,
                                       importc: "mysql_read_query_result".}
proc stmt_init*(MySQL: PMySQL): PSTMT{.stdcall, dynlib: lib, importc: "mysql_stmt_init".}
proc stmt_prepare*(stmt: PSTMT, query: cstring, len: int): cint{.stdcall,
    dynlib: lib, importc: "mysql_stmt_prepare".}
proc stmt_execute*(stmt: PSTMT): cint{.stdcall, dynlib: lib,
                                       importc: "mysql_stmt_execute".}
proc stmt_fetch*(stmt: PSTMT): cint{.stdcall, dynlib: lib,
                                     importc: "mysql_stmt_fetch".}
proc stmt_fetch_column*(stmt: PSTMT, `bind`: PBIND, column: cuint, offset: int): cint{.
    stdcall, dynlib: lib, importc: "mysql_stmt_fetch_column".}
proc stmt_store_result*(stmt: PSTMT): cint{.stdcall, dynlib: lib,
    importc: "mysql_stmt_store_result".}
proc stmt_param_count*(stmt: PSTMT): int{.stdcall, dynlib: lib,
    importc: "mysql_stmt_param_count".}
proc stmt_attr_set*(stmt: PSTMT, attr_type: Enum_stmt_attr_type, attr: pointer): my_bool{.
    stdcall, dynlib: lib, importc: "mysql_stmt_attr_set".}
proc stmt_attr_get*(stmt: PSTMT, attr_type: Enum_stmt_attr_type, attr: pointer): my_bool{.
    stdcall, dynlib: lib, importc: "mysql_stmt_attr_get".}
proc stmt_bind_param*(stmt: PSTMT, bnd: PBIND): my_bool{.stdcall, dynlib: lib,
    importc: "mysql_stmt_bind_param".}
proc stmt_bind_result*(stmt: PSTMT, bnd: PBIND): my_bool{.stdcall, dynlib: lib,
    importc: "mysql_stmt_bind_result".}
proc stmt_close*(stmt: PSTMT): my_bool{.stdcall, dynlib: lib,
                                        importc: "mysql_stmt_close".}
proc stmt_reset*(stmt: PSTMT): my_bool{.stdcall, dynlib: lib,
                                        importc: "mysql_stmt_reset".}
proc stmt_free_result*(stmt: PSTMT): my_bool{.stdcall, dynlib: lib,
    importc: "mysql_stmt_free_result".}
proc stmt_send_long_data*(stmt: PSTMT, param_number: cuint, data: cstring,
                          len: int): my_bool{.stdcall, dynlib: lib,
    importc: "mysql_stmt_send_long_data".}
proc stmt_result_metadata*(stmt: PSTMT): PRES{.stdcall, dynlib: lib,
    importc: "mysql_stmt_result_metadata".}
proc stmt_param_metadata*(stmt: PSTMT): PRES{.stdcall, dynlib: lib,
    importc: "mysql_stmt_param_metadata".}
proc stmt_errno*(stmt: PSTMT): cuint{.stdcall, dynlib: lib,
                                      importc: "mysql_stmt_errno".}
proc stmt_error*(stmt: PSTMT): cstring{.stdcall, dynlib: lib,
                                        importc: "mysql_stmt_error".}
proc stmt_sqlstate*(stmt: PSTMT): cstring{.stdcall, dynlib: lib,
    importc: "mysql_stmt_sqlstate".}
proc stmt_row_seek*(stmt: PSTMT, offset: ROW_OFFSET): ROW_OFFSET{.stdcall,
    dynlib: lib, importc: "mysql_stmt_row_seek".}
proc stmt_row_tell*(stmt: PSTMT): ROW_OFFSET{.stdcall, dynlib: lib,
    importc: "mysql_stmt_row_tell".}
proc stmt_data_seek*(stmt: PSTMT, offset: my_ulonglong){.stdcall, dynlib: lib,
    importc: "mysql_stmt_data_seek".}
proc stmt_num_rows*(stmt: PSTMT): my_ulonglong{.stdcall, dynlib: lib,
    importc: "mysql_stmt_num_rows".}
proc stmt_affected_rows*(stmt: PSTMT): my_ulonglong{.stdcall, dynlib: lib,
    importc: "mysql_stmt_affected_rows".}
proc stmt_insert_id*(stmt: PSTMT): my_ulonglong{.stdcall, dynlib: lib,
    importc: "mysql_stmt_insert_id".}
proc stmt_field_count*(stmt: PSTMT): cuint{.stdcall, dynlib: lib,
    importc: "mysql_stmt_field_count".}
proc commit*(MySQL: PMySQL): my_bool{.stdcall, dynlib: lib, importc: "mysql_commit".}
proc rollback*(MySQL: PMySQL): my_bool{.stdcall, dynlib: lib, importc: "mysql_rollback".}
proc autocommit*(MySQL: PMySQL, auto_mode: my_bool): my_bool{.stdcall, dynlib: lib,
    importc: "mysql_autocommit".}
proc more_results*(MySQL: PMySQL): my_bool{.stdcall, dynlib: lib,
                                  importc: "mysql_more_results".}
proc next_result*(MySQL: PMySQL): cint{.stdcall, dynlib: lib, importc: "mysql_next_result".}
proc close*(sock: PMySQL){.stdcall, dynlib: lib, importc: "mysql_close".}
  # status return codes
const
  NO_DATA* = 100
  DATA_TRUNCATED* = 101

proc reload*(x: PMySQL): cint
when defined(USE_OLD_FUNCTIONS):
  proc connect*(MySQL: PMySQL, host: cstring, user: cstring, passwd: cstring): PMySQL{.stdcall,
      dynlib: lib, importc: "mysql_connect".}
  proc create_db*(MySQL: PMySQL, DB: cstring): cint{.stdcall, dynlib: lib,
      importc: "mysql_create_db".}
  proc drop_db*(MySQL: PMySQL, DB: cstring): cint{.stdcall, dynlib: lib,
      importc: "mysql_drop_db".}
proc net_safe_read*(MySQL: PMySQL): cuint{.cdecl, dynlib: lib, importc: "net_safe_read".}

proc IS_PRI_KEY(n: int32): bool =
  result = (n and PRI_KEY_FLAG) != 0

proc IS_NOT_NULL(n: int32): bool =
  result = (n and NOT_NULL_FLAG) != 0

proc IS_BLOB(n: int32): bool =
  result = (n and BLOB_FLAG) != 0

proc IS_NUM_FIELD(f: Pst_mysql_field): bool =
  result = (f.flags and NUM_FLAG) != 0

proc IS_NUM(t: Enum_field_types): bool =
  result = (t <= FIELD_TYPE_INT24) or (t == FIELD_TYPE_YEAR) or
      (t == FIELD_TYPE_NEWDECIMAL)

proc INTERNAL_NUM_FIELD(f: Pst_mysql_field): bool =
  result = (f.ftype <= FIELD_TYPE_INT24) and
      ((f.ftype != FIELD_TYPE_TIMESTAMP) or (f.len == 14) or (f.len == 8)) or
      (f.ftype == FIELD_TYPE_YEAR)

proc reload(x: PMySQL): cint =
  result = refresh(x, REFRESH_GRANT)

{.pop.}
when defined(nimHasStyleChecks):
  {.pop.}
