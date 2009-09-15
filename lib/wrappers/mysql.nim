#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

{.deadCodeElim: on.}

when defined(Unix): 
  const 
    mysqllib = "libmysqlclient.so.15"

# mysqllib = "libmysqlclient.so.15"
when defined(Windows): 
  const
    mysqllib = "libmysql.dll"
    
# Copyright (C) 2000-2003 MySQL AB
#  
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
#  
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#  
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA  

type 
  my_bool* = bool
  Pmy_bool* = ptr my_bool
  PVIO* = Pointer
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
  MYSQL_NAMEDPIPE* = "MySQL"
  MYSQL_SERVICENAME* = "MySQL"

type 
  enum_server_command* = enum     
    COM_SLEEP, COM_QUIT, COM_INIT_DB, COM_QUERY, COM_FIELD_LIST, COM_CREATE_DB, 
    COM_DROP_DB, COM_REFRESH, COM_SHUTDOWN, COM_STATISTICS, COM_PROCESS_INFO, 
    COM_CONNECT, COM_PROCESS_KILL, COM_DEBUG, COM_PING, COM_TIME, 
    COM_DELAYED_INSERT, COM_CHANGE_USER, COM_BINLOG_DUMP, COM_TABLE_DUMP, 
    COM_CONNECT_OUT, COM_REGISTER_SLAVE, COM_STMT_PREPARE, COM_STMT_EXECUTE, 
    COM_STMT_SEND_LONG_DATA, COM_STMT_CLOSE, COM_STMT_RESET, COM_SET_OPTION, 
    COM_STMT_FETCH, COM_END

const 
  SCRAMBLE_LENGTH* = 20 # Length of random string sent by server on handshake; 
                        # this is also length of obfuscated password, 
                        # recieved from client
  SCRAMBLE_LENGTH_323* = 8 # length of password stored in the db: 
                           # new passwords are preceeded with '*'  
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
  MYSQL_ERRMSG_SIZE* = 200
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
  MAX_CHAR_WIDTH* = 255       # Max length for a CHAR colum
  MAX_BLOB_WIDTH* = 8192      # Default width for blob

type 
  Pst_net* = ptr st_net
  st_net*{.final.} = object
    vio*: PVio
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
    last_error*: array[0..(MYSQL_ERRMSG_SIZE) - 1, char]
    sqlstate*: array[0..(SQLSTATE_LENGTH + 1) - 1, char]
    last_errno*: cuint
    error*: char
    query_cache_query*: gptr
    report_error*: my_bool    # We should report error (we have unreported error)
    return_errno*: my_bool

  NET* = st_net
  PNET* = ptr NET

const 
  packet_error* = -1

type 
  enum_field_types* = enum    # For backward compatibility  
    MYSQL_TYPE_DECIMAL, MYSQL_TYPE_TINY, MYSQL_TYPE_SHORT, MYSQL_TYPE_LONG, 
    MYSQL_TYPE_FLOAT, MYSQL_TYPE_DOUBLE, MYSQL_TYPE_NULL, MYSQL_TYPE_TIMESTAMP, 
    MYSQL_TYPE_LONGLONG, MYSQL_TYPE_INT24, MYSQL_TYPE_DATE, MYSQL_TYPE_TIME, 
    MYSQL_TYPE_DATETIME, MYSQL_TYPE_YEAR, MYSQL_TYPE_NEWDATE, 
    MYSQL_TYPE_VARCHAR, MYSQL_TYPE_BIT, MYSQL_TYPE_NEWDECIMAL = 246, 
    MYSQL_TYPE_ENUM = 247, MYSQL_TYPE_SET = 248, MYSQL_TYPE_TINY_BLOB = 249, 
    MYSQL_TYPE_MEDIUM_BLOB = 250, MYSQL_TYPE_LONG_BLOB = 251, 
    MYSQL_TYPE_BLOB = 252, MYSQL_TYPE_VAR_STRING = 253, MYSQL_TYPE_STRING = 254, 
    MYSQL_TYPE_GEOMETRY = 255

const 
  CLIENT_MULTI_QUERIES* = CLIENT_MULTI_STATEMENTS
  FIELD_TYPE_DECIMAL* = MYSQL_TYPE_DECIMAL
  FIELD_TYPE_NEWDECIMAL* = MYSQL_TYPE_NEWDECIMAL
  FIELD_TYPE_TINY* = MYSQL_TYPE_TINY
  FIELD_TYPE_SHORT* = MYSQL_TYPE_SHORT
  FIELD_TYPE_LONG* = MYSQL_TYPE_LONG
  FIELD_TYPE_FLOAT* = MYSQL_TYPE_FLOAT
  FIELD_TYPE_DOUBLE* = MYSQL_TYPE_DOUBLE
  FIELD_TYPE_NULL* = MYSQL_TYPE_NULL
  FIELD_TYPE_TIMESTAMP* = MYSQL_TYPE_TIMESTAMP
  FIELD_TYPE_LONGLONG* = MYSQL_TYPE_LONGLONG
  FIELD_TYPE_INT24* = MYSQL_TYPE_INT24
  FIELD_TYPE_DATE* = MYSQL_TYPE_DATE
  FIELD_TYPE_TIME* = MYSQL_TYPE_TIME
  FIELD_TYPE_DATETIME* = MYSQL_TYPE_DATETIME
  FIELD_TYPE_YEAR* = MYSQL_TYPE_YEAR
  FIELD_TYPE_NEWDATE* = MYSQL_TYPE_NEWDATE
  FIELD_TYPE_ENUM* = MYSQL_TYPE_ENUM
  FIELD_TYPE_SET* = MYSQL_TYPE_SET
  FIELD_TYPE_TINY_BLOB* = MYSQL_TYPE_TINY_BLOB
  FIELD_TYPE_MEDIUM_BLOB* = MYSQL_TYPE_MEDIUM_BLOB
  FIELD_TYPE_LONG_BLOB* = MYSQL_TYPE_LONG_BLOB
  FIELD_TYPE_BLOB* = MYSQL_TYPE_BLOB
  FIELD_TYPE_VAR_STRING* = MYSQL_TYPE_VAR_STRING
  FIELD_TYPE_STRING* = MYSQL_TYPE_STRING
  FIELD_TYPE_CHAR* = MYSQL_TYPE_TINY
  FIELD_TYPE_INTERVAL* = MYSQL_TYPE_ENUM
  FIELD_TYPE_GEOMETRY* = MYSQL_TYPE_GEOMETRY
  FIELD_TYPE_BIT* = MYSQL_TYPE_BIT # Shutdown/kill enums and constants  
                                   # Bits for THD::killable.  
  MYSQL_SHUTDOWN_KILLABLE_CONNECT* = chr(1 shl 0)
  MYSQL_SHUTDOWN_KILLABLE_TRANS* = chr(1 shl 1)
  MYSQL_SHUTDOWN_KILLABLE_LOCK_TABLE* = chr(1 shl 2)
  MYSQL_SHUTDOWN_KILLABLE_UPDATE* = chr(1 shl 3)
  
type 
  mysql_enum_shutdown_level* = enum 
    SHUTDOWN_DEFAULT = 0, SHUTDOWN_WAIT_CONNECTIONS = 1,  
    SHUTDOWN_WAIT_TRANSACTIONS = 2,  
    SHUTDOWN_WAIT_UPDATES = 8,  
    SHUTDOWN_WAIT_ALL_BUFFERS = 16, 
    SHUTDOWN_WAIT_CRITICAL_BUFFERS = 17,  
    KILL_QUERY = 254,        
    KILL_CONNECTION = 255
  enum_cursor_type* = enum    # options for mysql_set_option  
    CURSOR_TYPE_NO_CURSOR = 0, CURSOR_TYPE_READ_ONLY = 1, 
    CURSOR_TYPE_FOR_UPDATE = 2, CURSOR_TYPE_SCROLLABLE = 4
  enum_mysql_set_option* = enum 
    MYSQL_OPTION_MULTI_STATEMENTS_ON, MYSQL_OPTION_MULTI_STATEMENTS_OFF

proc net_new_transaction*(net: st_net): st_net
proc my_net_init*(net: PNET, vio: PVio): my_bool{.cdecl, dynlib: mysqllib, 
    importc: "my_net_init".}
proc my_net_local_init*(net: PNET){.cdecl, dynlib: mysqllib, 
                                    importc: "my_net_local_init".}
proc net_end*(net: PNET){.cdecl, dynlib: mysqllib, importc: "net_end".}
proc net_clear*(net: PNET){.cdecl, dynlib: mysqllib, importc: "net_clear".}
proc net_realloc*(net: PNET, len: int): my_bool{.cdecl, dynlib: mysqllib, 
    importc: "net_realloc".}
proc net_flush*(net: PNET): my_bool{.cdecl, dynlib: mysqllib, 
                                     importc: "net_flush".}
proc my_net_write*(net: PNET, packet: cstring, length: int): my_bool{.cdecl, 
    dynlib: mysqllib, importc: "my_net_write".}
proc net_write_command*(net: PNET, command: char, header: cstring, 
                        head_len: int, packet: cstring, length: int): my_bool{.
    cdecl, dynlib: mysqllib, importc: "net_write_command".}
proc net_real_write*(net: PNET, packet: cstring, length: int): cint{.cdecl, 
    dynlib: mysqllib, importc: "net_real_write".}
proc my_net_read*(net: PNET): int{.cdecl, dynlib: mysqllib, 
                                      importc: "my_net_read".}
  # The following function is not meant for normal usage
  #      Currently it's used internally by manager.c  
type 
  Psockaddr* = ptr sockaddr
  sockaddr*{.final.} = object  # undefined structure

proc my_connect*(s: my_socket, name: Psockaddr, namelen: cuint, timeout: cuint): cint{.
    cdecl, dynlib: mysqllib, importc: "my_connect".}
type 
  Prand_struct* = ptr rand_struct
  rand_struct*{.final.} = object  # The following is for user defined functions  
    seed1*: int
    seed2*: int
    max_value*: int
    max_value_dbl*: cdouble

  Item_result* = enum 
    STRING_RESULT, REAL_RESULT, INT_RESULT, ROW_RESULT, DECIMAL_RESULT
  PItem_result* = ptr Item_result
  Pst_udf_args* = ptr st_udf_args
  st_udf_args*{.final.} = object 
    arg_count*: cuint         # Number of arguments
    arg_type*: PItem_result   # Pointer to item_results
    args*: cstringArray             # Pointer to item_results
    lengths*: ptr int         # Length of string arguments
    maybe_null*: cstring      # Length of string arguments
    attributes*: cstringArray       # Pointer to attribute name
    attribute_lengths*: ptr int # Length of attribute arguments
  
  UDF_ARGS* = st_udf_args
  PUDF_ARGS* = ptr UDF_ARGS   # This holds information about the result  
  Pst_udf_init* = ptr st_udf_init
  st_udf_init*{.final.} = object 
    maybe_null*: my_bool      # 1 if function can return NULL
    decimals*: cuint          # for real functions
    max_length*: int          # For string functions
    theptr*: cstring          # free pointer for function data
    const_item*: my_bool      # free pointer for function data
  
  UDF_INIT* = st_udf_init
  PUDF_INIT* = ptr UDF_INIT   # Constants when using compression  

const 
  NET_HEADER_SIZE* = 4        # standard header size
  COMP_HEADER_SIZE* = 3 # compression header extra size
                        # Prototypes to password functions  
                        # These functions are used for authentication by client and server and
                        #      implemented in sql/password.c     

proc randominit*(para1: Prand_struct, seed1: int, seed2: int){.cdecl, 
    dynlib: mysqllib, importc: "randominit".}
proc my_rnd*(para1: Prand_struct): cdouble{.cdecl, dynlib: mysqllib, 
    importc: "my_rnd".}
proc create_random_string*(fto: cstring, len: cuint, rand_st: Prand_struct){.
    cdecl, dynlib: mysqllib, importc: "create_random_string".}
proc hash_password*(fto: int, password: cstring, password_len: cuint){.cdecl, 
    dynlib: mysqllib, importc: "hash_password".}
proc make_scrambled_password_323*(fto: cstring, password: cstring){.cdecl, 
    dynlib: mysqllib, importc: "make_scrambled_password_323".}
proc scramble_323*(fto: cstring, message: cstring, password: cstring){.cdecl, 
    dynlib: mysqllib, importc: "scramble_323".}
proc check_scramble_323*(para1: cstring, message: cstring, salt: int): my_bool{.
    cdecl, dynlib: mysqllib, importc: "check_scramble_323".}
proc get_salt_from_password_323*(res: ptr int, password: cstring){.cdecl, 
    dynlib: mysqllib, importc: "get_salt_from_password_323".}
proc make_password_from_salt_323*(fto: cstring, salt: ptr int){.cdecl, 
    dynlib: mysqllib, importc: "make_password_from_salt_323".}
proc octet2hex*(fto: cstring, str: cstring, length: cuint): cstring{.cdecl, 
    dynlib: mysqllib, importc: "octet2hex".}
proc make_scrambled_password*(fto: cstring, password: cstring){.cdecl, 
    dynlib: mysqllib, importc: "make_scrambled_password".}
proc scramble*(fto: cstring, message: cstring, password: cstring){.cdecl, 
    dynlib: mysqllib, importc: "scramble".}
proc check_scramble*(reply: cstring, message: cstring, hash_stage2: pointer): my_bool{.
    cdecl, dynlib: mysqllib, importc: "check_scramble".}
proc get_salt_from_password*(res: pointer, password: cstring){.cdecl, 
    dynlib: mysqllib, importc: "get_salt_from_password".}
proc make_password_from_salt*(fto: cstring, hash_stage2: pointer){.cdecl, 
    dynlib: mysqllib, importc: "make_password_from_salt".}
  # end of password.c  
proc get_tty_password*(opt_message: cstring): cstring{.cdecl, dynlib: mysqllib, 
    importc: "get_tty_password".}
proc mysql_errno_to_sqlstate*(mysql_errno: cuint): cstring{.cdecl, 
    dynlib: mysqllib, importc: "mysql_errno_to_sqlstate".}
  # Some other useful functions  
proc modify_defaults_file*(file_location: cstring, option: cstring, 
                           option_value: cstring, section_name: cstring, 
                           remove_option: cint): cint{.cdecl, dynlib: mysqllib, 
    importc: "load_defaults".}
proc load_defaults*(conf_file: cstring, groups: cstringArray, argc: ptr cint, 
                    argv: ptr cstringArray): cint{.cdecl, dynlib: mysqllib, 
    importc: "load_defaults".}
proc my_init*(): my_bool{.cdecl, dynlib: mysqllib, importc: "my_init".}
proc my_thread_init*(): my_bool{.cdecl, dynlib: mysqllib, 
                                 importc: "my_thread_init".}
proc my_thread_end*(){.cdecl, dynlib: mysqllib, importc: "my_thread_end".}
const 
  NULL_LENGTH*: int = int(not (0)) # For net_store_length

const 
  MYSQL_STMT_HEADER* = 4
  MYSQL_LONG_DATA_HEADER* = 6 #  ------------ Stop of declaration in "mysql_com.h"   -----------------------  
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
  Pst_mysql_field* = ptr st_mysql_field
  st_mysql_field*{.final.} = object 
    name*: cstring            # Name of column
    org_name*: cstring        # Original column name, if an alias
    table*: cstring           # Table of column if column was a field
    org_table*: cstring       # Org table name, if table was an alias
    db*: cstring              # Database for table
    catalog*: cstring         # Catalog for table
    def*: cstring             # Default value (set by mysql_list_fields)
    len*: int              # Width of column (create length)
    max_length*: int       # Max width for selected set
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
    ftype*: enum_field_types  # Type of field. See mysql_com.h for types
  
  MYSQL_FIELD* = st_mysql_field
  PMYSQL_FIELD* = ptr MYSQL_FIELD
  PMYSQL_ROW* = ptr MYSQL_ROW # return data as array of strings
  MYSQL_ROW* = cstringArray
  PMYSQL_FIELD_OFFSET* = ptr MYSQL_FIELD_OFFSET # offset to current field
  MYSQL_FIELD_OFFSET* = cuint

proc IS_PRI_KEY*(n: int32): bool
proc IS_NOT_NULL*(n: int32): bool
proc IS_BLOB*(n: int32): bool
proc IS_NUM*(t: enum_field_types): bool
proc INTERNAL_NUM_FIELD*(f: Pst_mysql_field): bool
proc IS_NUM_FIELD*(f: Pst_mysql_field): bool

type 
  my_ulonglong* = int64
  Pmy_ulonglong* = ptr my_ulonglong

const 
  MYSQL_COUNT_ERROR* = not (my_ulonglong(0))

type 
  Pst_mysql_rows* = ptr st_mysql_rows
  st_mysql_rows*{.final.} = object 
    next*: Pst_mysql_rows     # list of rows
    data*: MYSQL_ROW
    len*: int

  MYSQL_ROWS* = st_mysql_rows
  PMYSQL_ROWS* = ptr MYSQL_ROWS
  PMYSQL_ROW_OFFSET* = ptr MYSQL_ROW_OFFSET # offset to current row
  MYSQL_ROW_OFFSET* = MYSQL_ROWS #  ------------ Start of declaration in "my_alloc.h"     --------------------  
                                 # $include "my_alloc.h"

const 
  ALLOC_MAX_BLOCK_TO_DROP* = 4096
  ALLOC_MAX_BLOCK_USAGE_BEFORE_DROP* = 10 # struct for once_alloc (block)  

type 
  Pst_used_mem* = ptr st_used_mem
  st_used_mem*{.final.} = object 
    next*: Pst_used_mem       # Next block in use
    left*: cuint              # memory left in block
    size*: cuint              # size of block
  
  USED_MEM* = st_used_mem
  PUSED_MEM* = ptr USED_MEM
  Pst_mem_root* = ptr st_mem_root
  st_mem_root*{.final.} = object 
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

  MEM_ROOT* = st_mem_root
  PMEM_ROOT* = ptr MEM_ROOT   #  ------------ Stop of declaration in "my_alloc.h"    ----------------------  

type 
  Pst_mysql_data* = ptr st_mysql_data
  st_mysql_data*{.final.} = object 
    rows*: my_ulonglong
    fields*: cuint
    data*: PMYSQL_ROWS
    alloc*: MEM_ROOT
    prev_ptr*: ptr PMYSQL_ROWS

  MYSQL_DATA* = st_mysql_data
  PMYSQL_DATA* = ptr MYSQL_DATA
  mysql_option* = enum 
    MYSQL_OPT_CONNECT_TIMEOUT, MYSQL_OPT_COMPRESS, MYSQL_OPT_NAMED_PIPE, 
    MYSQL_INIT_COMMAND, MYSQL_READ_DEFAULT_FILE, MYSQL_READ_DEFAULT_GROUP, 
    MYSQL_SET_CHARSET_DIR, MYSQL_SET_CHARSET_NAME, MYSQL_OPT_LOCAL_INFILE, 
    MYSQL_OPT_PROTOCOL, MYSQL_SHARED_MEMORY_BASE_NAME, MYSQL_OPT_READ_TIMEOUT, 
    MYSQL_OPT_WRITE_TIMEOUT, MYSQL_OPT_USE_RESULT, 
    MYSQL_OPT_USE_REMOTE_CONNECTION, MYSQL_OPT_USE_EMBEDDED_CONNECTION, 
    MYSQL_OPT_GUESS_CONNECTION, MYSQL_SET_CLIENT_IP, MYSQL_SECURE_AUTH, 
    MYSQL_REPORT_DATA_TRUNCATION, MYSQL_OPT_RECONNECT

const 
  MAX_MYSQL_MANAGER_ERR* = 256
  MAX_MYSQL_MANAGER_MSG* = 256
  MANAGER_OK* = 200
  MANAGER_INFO* = 250
  MANAGER_ACCESS* = 401
  MANAGER_CLIENT_ERR* = 450
  MANAGER_INTERNAL_ERR* = 500

type 
  st_dynamic_array*{.final.} = object 
    buffer*: cstring
    elements*: cuint
    max_element*: cuint
    alloc_increment*: cuint
    size_of_element*: cuint

  DYNAMIC_ARRAY* = st_dynamic_array
  Pst_dynamic_array* = ptr st_dynamic_array
  Pst_mysql_options* = ptr st_mysql_options
  st_mysql_options*{.final.} = object 
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
    methods_to_use*: mysql_option
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

  mysql_status* = enum 
    MYSQL_STATUS_READY, MYSQL_STATUS_GET_RESULT, MYSQL_STATUS_USE_RESULT
  mysql_protocol_type* = enum  # There are three types of queries - the ones that have to go to
                               #      the master, the ones that go to a slave, and the adminstrative
                               #      type which must happen on the pivot connectioin 
    MYSQL_PROTOCOL_DEFAULT, MYSQL_PROTOCOL_TCP, MYSQL_PROTOCOL_SOCKET, 
    MYSQL_PROTOCOL_PIPE, MYSQL_PROTOCOL_MEMORY
  mysql_rpl_type* = enum 
    MYSQL_RPL_MASTER, MYSQL_RPL_SLAVE, MYSQL_RPL_ADMIN
  charset_info_st*{.final.} = object 
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
  
  CHARSET_INFO* = charset_info_st
  Pcharset_info_st* = ptr charset_info_st
  Pcharacter_set* = ptr character_set
  character_set*{.final.} = object 
    number*: cuint
    state*: cuint
    csname*: cstring
    name*: cstring
    comment*: cstring
    dir*: cstring
    mbminlen*: cuint
    mbmaxlen*: cuint

  MY_CHARSET_INFO* = character_set
  PMY_CHARSET_INFO* = ptr MY_CHARSET_INFO
  Pst_mysql_methods* = ptr st_mysql_methods
  Pst_mysql* = ptr st_mysql
  st_mysql*{.final.} = object 
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
    fields*: PMYSQL_FIELD
    field_alloc*: MEM_ROOT
    affected_rows*: my_ulonglong
    insert_id*: my_ulonglong  # id if insert on table with NEXTNR
    extra_info*: my_ulonglong # Used by mysqlshow, not used by mysql 5.0 and up
    thread_id*: int        # Id for connection in server
    packet_length*: int
    port*: cuint
    client_flag*: int
    server_capabilities*: int
    protocol_version*: cuint
    field_count*: cuint
    server_status*: cuint
    server_language*: cuint
    warning_count*: cuint
    options*: st_mysql_options
    status*: mysql_status
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
    stmts*: Pointer           # was PList, list of all statements
    methods*: Pst_mysql_methods
    thd*: pointer #   Points to boolean flag in MYSQL_RES  or MYSQL_STMT. We set this flag
                  #        from mysql_stmt_close if close had to cancel result set of this object.       
    unbuffered_fetch_owner*: Pmy_bool

  MYSQL* = st_mysql
  PMYSQL* = ptr MYSQL
  Pst_mysql_res* = ptr st_mysql_res
  st_mysql_res*{.final.} = object 
    row_count*: my_ulonglong
    fields*: PMYSQL_FIELD
    data*: PMYSQL_DATA
    data_cursor*: PMYSQL_ROWS
    lengths*: ptr int         # column lengths of current row
    handle*: PMYSQL           # for unbuffered reads
    field_alloc*: MEM_ROOT
    field_count*: cuint
    current_field*: cuint
    row*: MYSQL_ROW           # If unbuffered read
    current_row*: MYSQL_ROW   # buffer to current row
    eof*: my_bool             # Used by mysql_fetch_row
    unbuffered_fetch_cancelled*: my_bool # mysql_stmt_close() had to cancel this result
    methods*: Pst_mysql_methods

  MYSQL_RES* = st_mysql_res
  PMYSQL_RES* = ptr MYSQL_RES
  Pst_mysql_stmt* = ptr st_mysql_stmt
  PMYSQL_STMT* = ptr MYSQL_STMT
  st_mysql_methods*{.final.} = object 
    read_query_result*: proc (mysql: PMYSQL): my_bool{.cdecl.}
    advanced_command*: proc (mysql: PMYSQL, command: enum_server_command, 
                             header: cstring, header_length: int, 
                             arg: cstring, arg_length: int, 
                             skip_check: my_bool): my_bool
    read_rows*: proc (mysql: PMYSQL, mysql_fields: PMYSQL_FIELD, fields: cuint): PMYSQL_DATA
    use_result*: proc (mysql: PMYSQL): PMYSQL_RES
    fetch_lengths*: proc (fto: ptr int, column: MYSQL_ROW, field_count: cuint)
    flush_use_result*: proc (mysql: PMYSQL)
    list_fields*: proc (mysql: PMYSQL): PMYSQL_FIELD
    read_prepare_result*: proc (mysql: PMYSQL, stmt: PMYSQL_STMT): my_bool
    stmt_execute*: proc (stmt: PMYSQL_STMT): cint
    read_binary_rows*: proc (stmt: PMYSQL_STMT): cint
    unbuffered_fetch*: proc (mysql: PMYSQL, row: cstringArray): cint
    free_embedded_thd*: proc (mysql: PMYSQL)
    read_statistics*: proc (mysql: PMYSQL): cstring
    next_result*: proc (mysql: PMYSQL): my_bool
    read_change_user_result*: proc (mysql: PMYSQL, buff: cstring, 
                                    passwd: cstring): cint
    read_rowsfrom_cursor*: proc (stmt: PMYSQL_STMT): cint

  MYSQL_METHODS* = st_mysql_methods
  PMYSQL_METHODS* = ptr MYSQL_METHODS
  Pst_mysql_manager* = ptr st_mysql_manager
  st_mysql_manager*{.final.} = object 
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

  MYSQL_MANAGER* = st_mysql_manager
  PMYSQL_MANAGER* = ptr MYSQL_MANAGER
  Pst_mysql_parameters* = ptr st_mysql_parameters
  st_mysql_parameters*{.final.} = object 
    p_max_allowed_packet*: ptr int
    p_net_buffer_length*: ptr int

  MYSQL_PARAMETERS* = st_mysql_parameters
  PMYSQL_PARAMETERS* = ptr MYSQL_PARAMETERS
  enum_mysql_stmt_state* = enum     
    MYSQL_STMT_INIT_DONE = 1, MYSQL_STMT_PREPARE_DONE, MYSQL_STMT_EXECUTE_DONE, 
    MYSQL_STMT_FETCH_DONE
  Pst_mysql_bind* = ptr st_mysql_bind
  st_mysql_bind*{.final.} = object 
    len*: int              # output length pointer
    is_null*: Pmy_bool        # Pointer to null indicator
    buffer*: pointer          # buffer to get/put data
    error*: pmy_bool          # set this if you want to track data truncations happened during fetch
    buffer_type*: enum_field_types # buffer type
    buffer_length*: int    # buffer length, must be set for str/binary
                           # Following are for internal use. Set by mysql_stmt_bind_param  
    row_ptr*: ptr byte        # for the current data position
    offset*: int           # offset position for char/binary fetch
    length_value*: int     #  Used if length is 0
    param_number*: cuint      # For null count and error messages
    pack_length*: cuint       # Internal length for packed data
    error_value*: my_bool     # used if error is 0
    is_unsigned*: my_bool     # set if integer type is unsigned
    long_data_used*: my_bool  # If used with mysql_send_long_data
    is_null_value*: my_bool   # Used if is_null is 0
    store_param_func*: proc (net: PNET, param: Pst_mysql_bind){.cdecl.}
    fetch_result*: proc (para1: Pst_mysql_bind, para2: PMYSQL_FIELD, row: PPbyte)
    skip_result*: proc (para1: Pst_mysql_bind, para2: PMYSQL_FIELD, row: PPbyte)

  MYSQL_BIND* = st_mysql_bind
  PMYSQL_BIND* = ptr MYSQL_BIND # statement handler  
  st_mysql_stmt*{.final.} = object 
    mem_root*: MEM_ROOT       # root allocations
    mysql*: PMYSQL            # connection handle
    params*: PMYSQL_BIND      # input parameters
    `bind`*: PMYSQL_BIND      # input parameters
    fields*: PMYSQL_FIELD     # result set metadata
    result*: MYSQL_DATA       # cached result set
    data_cursor*: PMYSQL_ROWS # current row in cached result
    affected_rows*: my_ulonglong # copy of mysql->affected_rows after statement execution
    insert_id*: my_ulonglong 
    read_row_func*: proc (stmt: Pst_mysql_stmt, row: PPbyte): cint{.cdecl.}
    stmt_id*: int          # Id for prepared statement
    flags*: int            # i.e. type of cursor to open
    prefetch_rows*: int    # number of rows per one COM_FETCH
    server_status*: cuint # Copied from mysql->server_status after execute/fetch to know
                          # server-side cursor status for this statement.
    last_errno*: cuint        # error code
    param_count*: cuint       # input parameter count
    field_count*: cuint       # number of columns in result set
    state*: enum_mysql_stmt_state # statement state
    last_error*: array[0..(MYSQL_ERRMSG_SIZE) - 1, char] # error message
    sqlstate*: array[0..(SQLSTATE_LENGTH + 1) - 1, char]
    send_types_to_server*: my_bool # Types of input parameters should be sent to server
    bind_param_done*: my_bool # input buffers were supplied
    bind_result_done*: char # output buffers were supplied
    unbuffered_fetch_cancelled*: my_bool        
    update_max_length*: my_bool

  MYSQL_STMT* = st_mysql_stmt # When doing mysql_stmt_store_result calculate max_length attribute
                              # of statement metadata. This is to be consistent with the old API,
                              # where this was done automatically.
                              # In the new API we do that only by request because it slows down
                              # mysql_stmt_store_result sufficiently.       
  enum_stmt_attr_type* = enum
    STMT_ATTR_UPDATE_MAX_LENGTH, STMT_ATTR_CURSOR_TYPE,  
    STMT_ATTR_PREFETCH_ROWS 
    
proc mysql_server_init*(argc: cint, argv: cstringArray, groups: cstringArray): cint{.cdecl, 
    dynlib: mysqllib, importc: "mysql_server_init".}
proc mysql_server_end*(){.cdecl, dynlib: mysqllib, importc: "mysql_server_end".}
  # mysql_server_init/end need to be called when using libmysqld or
  #      libmysqlclient (exactly, mysql_server_init() is called by mysql_init() so
  #      you don't need to call it explicitely; but you need to call
  #      mysql_server_end() to free memory). The names are a bit misleading
  #      (mysql_SERVER* to be used when using libmysqlCLIENT). So we add more general
  #      names which suit well whether you're using libmysqld or libmysqlclient. We
  #      intend to promote these aliases over the mysql_server* ones.     
proc mysql_library_init*(argc: cint, argv: cstringArray, groups: cstringArray): cint{.cdecl, 
    dynlib: mysqllib, importc: "mysql_server_init".}
proc mysql_library_end*(){.cdecl, dynlib: mysqllib, importc: "mysql_server_end".}
proc mysql_get_parameters*(): PMYSQL_PARAMETERS{.stdcall, dynlib: mysqllib, 
    importc: "mysql_get_parameters".}
  # Set up and bring down a thread; these function should be called
  #      for each thread in an application which opens at least one MySQL
  #      connection.  All uses of the connection(s) should be between these
  #      function calls.     
proc mysql_thread_init*(): my_bool{.stdcall, dynlib: mysqllib, 
                                    importc: "mysql_thread_init".}
proc mysql_thread_end*(){.stdcall, dynlib: mysqllib, importc: "mysql_thread_end".}
  # Functions to get information from the MYSQL and MYSQL_RES structures
  #      Should definitely be used if one uses shared libraries.     
proc mysql_num_rows*(res: PMYSQL_RES): my_ulonglong{.stdcall, dynlib: mysqllib, 
    importc: "mysql_num_rows".}
proc mysql_num_fields*(res: PMYSQL_RES): cuint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_num_fields".}
proc mysql_eof*(res: PMYSQL_RES): my_bool{.stdcall, dynlib: mysqllib, 
    importc: "mysql_eof".}
proc mysql_fetch_field_direct*(res: PMYSQL_RES, fieldnr: cuint): PMYSQL_FIELD{.
    stdcall, dynlib: mysqllib, importc: "mysql_fetch_field_direct".}
proc mysql_fetch_fields*(res: PMYSQL_RES): PMYSQL_FIELD{.stdcall, 
    dynlib: mysqllib, importc: "mysql_fetch_fields".}
proc mysql_row_tell*(res: PMYSQL_RES): MYSQL_ROW_OFFSET{.stdcall, 
    dynlib: mysqllib, importc: "mysql_row_tell".}
proc mysql_field_tell*(res: PMYSQL_RES): MYSQL_FIELD_OFFSET{.stdcall, 
    dynlib: mysqllib, importc: "mysql_field_tell".}
proc mysql_field_count*(mysql: PMYSQL): cuint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_field_count".}
proc mysql_affected_rows*(mysql: PMYSQL): my_ulonglong{.stdcall, 
    dynlib: mysqllib, importc: "mysql_affected_rows".}
proc mysql_insert_id*(mysql: PMYSQL): my_ulonglong{.stdcall, dynlib: mysqllib, 
    importc: "mysql_insert_id".}
proc mysql_errno*(mysql: PMYSQL): cuint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_errno".}
proc mysql_error*(mysql: PMYSQL): cstring{.stdcall, dynlib: mysqllib, 
    importc: "mysql_error".}
proc mysql_sqlstate*(mysql: PMYSQL): cstring{.stdcall, dynlib: mysqllib, 
    importc: "mysql_sqlstate".}
proc mysql_warning_count*(mysql: PMYSQL): cuint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_warning_count".}
proc mysql_info*(mysql: PMYSQL): cstring{.stdcall, dynlib: mysqllib, 
    importc: "mysql_info".}
proc mysql_thread_id*(mysql: PMYSQL): int{.stdcall, dynlib: mysqllib, 
    importc: "mysql_thread_id".}
proc mysql_character_set_name*(mysql: PMYSQL): cstring{.stdcall, 
    dynlib: mysqllib, importc: "mysql_character_set_name".}
proc mysql_set_character_set*(mysql: PMYSQL, csname: cstring): int32{.stdcall, 
    dynlib: mysqllib, importc: "mysql_set_character_set".}
proc mysql_init*(mysql: PMYSQL): PMYSQL{.stdcall, dynlib: mysqllib, 
    importc: "mysql_init".}
proc mysql_ssl_set*(mysql: PMYSQL, key: cstring, cert: cstring, ca: cstring, 
                    capath: cstring, cipher: cstring): my_bool{.stdcall, 
    dynlib: mysqllib, importc: "mysql_ssl_set".}
proc mysql_change_user*(mysql: PMYSQL, user: cstring, passwd: cstring, 
                        db: cstring): my_bool{.stdcall, dynlib: mysqllib, 
    importc: "mysql_change_user".}
proc mysql_real_connect*(mysql: PMYSQL, host: cstring, user: cstring, 
                         passwd: cstring, db: cstring, port: cuint, 
                         unix_socket: cstring, clientflag: int): PMYSQL{.
    stdcall, dynlib: mysqllib, importc: "mysql_real_connect".}
proc mysql_select_db*(mysql: PMYSQL, db: cstring): cint{.stdcall, 
    dynlib: mysqllib, importc: "mysql_select_db".}
proc mysql_query*(mysql: PMYSQL, q: cstring): cint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_query".}
proc mysql_send_query*(mysql: PMYSQL, q: cstring, len: int): cint{.stdcall, 
    dynlib: mysqllib, importc: "mysql_send_query".}
proc mysql_real_query*(mysql: PMYSQL, q: cstring, len: int): cint{.stdcall, 
    dynlib: mysqllib, importc: "mysql_real_query".}
proc mysql_store_result*(mysql: PMYSQL): PMYSQL_RES{.stdcall, dynlib: mysqllib, 
    importc: "mysql_store_result".}
proc mysql_use_result*(mysql: PMYSQL): PMYSQL_RES{.stdcall, dynlib: mysqllib, 
    importc: "mysql_use_result".}
  # perform query on master  
proc mysql_master_query*(mysql: PMYSQL, q: cstring, len: int): my_bool{.
    stdcall, dynlib: mysqllib, importc: "mysql_master_query".}
proc mysql_master_send_query*(mysql: PMYSQL, q: cstring, len: int): my_bool{.
    stdcall, dynlib: mysqllib, importc: "mysql_master_send_query".}
  # perform query on slave  
proc mysql_slave_query*(mysql: PMYSQL, q: cstring, len: int): my_bool{.
    stdcall, dynlib: mysqllib, importc: "mysql_slave_query".}
proc mysql_slave_send_query*(mysql: PMYSQL, q: cstring, len: int): my_bool{.
    stdcall, dynlib: mysqllib, importc: "mysql_slave_send_query".}
proc mysql_get_character_set_info*(mysql: PMYSQL, charset: PMY_CHARSET_INFO){.
    stdcall, dynlib: mysqllib, importc: "mysql_get_character_set_info".}
  # local infile support  
const 
  LOCAL_INFILE_ERROR_LEN* = 512 
  
# procedure mysql_set_local_infile_handler(mysql:PMYSQL; local_infile_init:function (para1:Ppointer; para2:Pchar; para3:pointer):longint; local_infile_read:function (para1:pointer; para2:Pchar; para3:dword):longint; local_infile_end:procedure (_pa
# para6:pointer);cdecl;external mysqllib name 'mysql_set_local_infile_handler';

proc mysql_set_local_infile_default*(mysql: PMYSQL){.cdecl, dynlib: mysqllib, 
    importc: "mysql_set_local_infile_default".}
  # enable/disable parsing of all queries to decide if they go on master or
  #      slave     
proc mysql_enable_rpl_parse*(mysql: PMYSQL){.stdcall, dynlib: mysqllib, 
    importc: "mysql_enable_rpl_parse".}
proc mysql_disable_rpl_parse*(mysql: PMYSQL){.stdcall, dynlib: mysqllib, 
    importc: "mysql_disable_rpl_parse".}
  # get the value of the parse flag  
proc mysql_rpl_parse_enabled*(mysql: PMYSQL): cint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_rpl_parse_enabled".}
  #  enable/disable reads from master  
proc mysql_enable_reads_from_master*(mysql: PMYSQL){.stdcall, dynlib: mysqllib, 
    importc: "mysql_enable_reads_from_master".}
proc mysql_disable_reads_from_master*(mysql: PMYSQL){.stdcall, dynlib: mysqllib, 
    importc: "mysql_disable_reads_from_master".}
  # get the value of the master read flag  
proc mysql_reads_from_master_enabled*(mysql: PMYSQL): my_bool{.stdcall, 
    dynlib: mysqllib, importc: "mysql_reads_from_master_enabled".}
proc mysql_rpl_query_type*(q: cstring, length: cint): mysql_rpl_type{.stdcall, 
    dynlib: mysqllib, importc: "mysql_rpl_query_type".}
  # discover the master and its slaves  
proc mysql_rpl_probe*(mysql: PMYSQL): my_bool{.stdcall, dynlib: mysqllib, 
    importc: "mysql_rpl_probe".}
  # set the master, close/free the old one, if it is not a pivot  
proc mysql_set_master*(mysql: PMYSQL, host: cstring, port: cuint, user: cstring, 
                       passwd: cstring): cint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_set_master".}
proc mysql_add_slave*(mysql: PMYSQL, host: cstring, port: cuint, user: cstring, 
                      passwd: cstring): cint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_add_slave".}
proc mysql_shutdown*(mysql: PMYSQL, shutdown_level: mysql_enum_shutdown_level): cint{.
    stdcall, dynlib: mysqllib, importc: "mysql_shutdown".}
proc mysql_dump_debug_info*(mysql: PMYSQL): cint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_dump_debug_info".}
proc mysql_refresh*(mysql: PMYSQL, refresh_options: cuint): cint{.stdcall, 
    dynlib: mysqllib, importc: "mysql_refresh".}
proc mysql_kill*(mysql: PMYSQL, pid: int): cint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_kill".}
proc mysql_set_server_option*(mysql: PMYSQL, option: enum_mysql_set_option): cint{.
    stdcall, dynlib: mysqllib, importc: "mysql_set_server_option".}
proc mysql_ping*(mysql: PMYSQL): cint{.stdcall, dynlib: mysqllib, 
                                       importc: "mysql_ping".}
proc mysql_stat*(mysql: PMYSQL): cstring{.stdcall, dynlib: mysqllib, 
    importc: "mysql_stat".}
proc mysql_get_server_info*(mysql: PMYSQL): cstring{.stdcall, dynlib: mysqllib, 
    importc: "mysql_get_server_info".}
proc mysql_get_client_info*(): cstring{.stdcall, dynlib: mysqllib, 
                                        importc: "mysql_get_client_info".}
proc mysql_get_client_version*(): int{.stdcall, dynlib: mysqllib, 
    importc: "mysql_get_client_version".}
proc mysql_get_host_info*(mysql: PMYSQL): cstring{.stdcall, dynlib: mysqllib, 
    importc: "mysql_get_host_info".}
proc mysql_get_server_version*(mysql: PMYSQL): int{.stdcall, 
    dynlib: mysqllib, importc: "mysql_get_server_version".}
proc mysql_get_proto_info*(mysql: PMYSQL): cuint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_get_proto_info".}
proc mysql_list_dbs*(mysql: PMYSQL, wild: cstring): PMYSQL_RES{.stdcall, 
    dynlib: mysqllib, importc: "mysql_list_dbs".}
proc mysql_list_tables*(mysql: PMYSQL, wild: cstring): PMYSQL_RES{.stdcall, 
    dynlib: mysqllib, importc: "mysql_list_tables".}
proc mysql_list_processes*(mysql: PMYSQL): PMYSQL_RES{.stdcall, 
    dynlib: mysqllib, importc: "mysql_list_processes".}
proc mysql_options*(mysql: PMYSQL, option: mysql_option, arg: cstring): cint{.
    stdcall, dynlib: mysqllib, importc: "mysql_options".}
proc mysql_free_result*(result: PMYSQL_RES){.stdcall, dynlib: mysqllib, 
    importc: "mysql_free_result".}
proc mysql_data_seek*(result: PMYSQL_RES, offset: my_ulonglong){.stdcall, 
    dynlib: mysqllib, importc: "mysql_data_seek".}
proc mysql_row_seek*(result: PMYSQL_RES, offset: MYSQL_ROW_OFFSET): MYSQL_ROW_OFFSET{.
    stdcall, dynlib: mysqllib, importc: "mysql_row_seek".}
proc mysql_field_seek*(result: PMYSQL_RES, offset: MYSQL_FIELD_OFFSET): MYSQL_FIELD_OFFSET{.
    stdcall, dynlib: mysqllib, importc: "mysql_field_seek".}
proc mysql_fetch_row*(result: PMYSQL_RES): MYSQL_ROW{.stdcall, dynlib: mysqllib, 
    importc: "mysql_fetch_row".}
proc mysql_fetch_lengths*(result: PMYSQL_RES): ptr int{.stdcall, 
    dynlib: mysqllib, importc: "mysql_fetch_lengths".}
proc mysql_fetch_field*(result: PMYSQL_RES): PMYSQL_FIELD{.stdcall, 
    dynlib: mysqllib, importc: "mysql_fetch_field".}
proc mysql_list_fields*(mysql: PMYSQL, table: cstring, wild: cstring): PMYSQL_RES{.
    stdcall, dynlib: mysqllib, importc: "mysql_list_fields".}
proc mysql_escape_string*(fto: cstring, `from`: cstring, from_length: int): int{.
    stdcall, dynlib: mysqllib, importc: "mysql_escape_string".}
proc mysql_hex_string*(fto: cstring, `from`: cstring, from_length: int): int{.
    stdcall, dynlib: mysqllib, importc: "mysql_hex_string".}
proc mysql_real_escape_string*(mysql: PMYSQL, fto: cstring, `from`: cstring, 
                               len: int): int{.stdcall, dynlib: mysqllib, 
    importc: "mysql_real_escape_string".}
proc mysql_debug*(debug: cstring){.stdcall, dynlib: mysqllib, 
                                   importc: "mysql_debug".}
  #    function mysql_odbc_escape_string(mysql:PMYSQL; fto:Pchar; to_length:dword; from:Pchar; from_length:dword;
  #               param:pointer; extend_buffer:function (para1:pointer; to:Pchar; length:Pdword):Pchar):Pchar;stdcall;external mysqllib name 'mysql_odbc_escape_string';
proc myodbc_remove_escape*(mysql: PMYSQL, name: cstring){.stdcall, 
    dynlib: mysqllib, importc: "myodbc_remove_escape".}
proc mysql_thread_safe*(): cuint{.stdcall, dynlib: mysqllib, 
                                  importc: "mysql_thread_safe".}
proc mysql_embedded*(): my_bool{.stdcall, dynlib: mysqllib, 
                                 importc: "mysql_embedded".}
proc mysql_manager_init*(con: PMYSQL_MANAGER): PMYSQL_MANAGER{.stdcall, 
    dynlib: mysqllib, importc: "mysql_manager_init".}
proc mysql_manager_connect*(con: PMYSQL_MANAGER, host: cstring, user: cstring, 
                            passwd: cstring, port: cuint): PMYSQL_MANAGER{.
    stdcall, dynlib: mysqllib, importc: "mysql_manager_connect".}
proc mysql_manager_close*(con: PMYSQL_MANAGER){.stdcall, dynlib: mysqllib, 
    importc: "mysql_manager_close".}
proc mysql_manager_command*(con: PMYSQL_MANAGER, cmd: cstring, cmd_len: cint): cint{.
    stdcall, dynlib: mysqllib, importc: "mysql_manager_command".}
proc mysql_manager_fetch_line*(con: PMYSQL_MANAGER, res_buf: cstring, 
                               res_buf_size: cint): cint{.stdcall, 
    dynlib: mysqllib, importc: "mysql_manager_fetch_line".}
proc mysql_read_query_result*(mysql: PMYSQL): my_bool{.stdcall, 
    dynlib: mysqllib, importc: "mysql_read_query_result".}
proc mysql_stmt_init*(mysql: PMYSQL): PMYSQL_STMT{.stdcall, dynlib: mysqllib, 
    importc: "mysql_stmt_init".}
proc mysql_stmt_prepare*(stmt: PMYSQL_STMT, query: cstring, len: int): cint{.
    stdcall, dynlib: mysqllib, importc: "mysql_stmt_prepare".}
proc mysql_stmt_execute*(stmt: PMYSQL_STMT): cint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_stmt_execute".}
proc mysql_stmt_fetch*(stmt: PMYSQL_STMT): cint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_stmt_fetch".}
proc mysql_stmt_fetch_column*(stmt: PMYSQL_STMT, `bind`: PMYSQL_BIND, 
                              column: cuint, offset: int): cint{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_fetch_column".}
proc mysql_stmt_store_result*(stmt: PMYSQL_STMT): cint{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_store_result".}
proc mysql_stmt_param_count*(stmt: PMYSQL_STMT): int{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_param_count".}
proc mysql_stmt_attr_set*(stmt: PMYSQL_STMT, attr_type: enum_stmt_attr_type, 
                          attr: pointer): my_bool{.stdcall, dynlib: mysqllib, 
    importc: "mysql_stmt_attr_set".}
proc mysql_stmt_attr_get*(stmt: PMYSQL_STMT, attr_type: enum_stmt_attr_type, 
                          attr: pointer): my_bool{.stdcall, dynlib: mysqllib, 
    importc: "mysql_stmt_attr_get".}
proc mysql_stmt_bind_param*(stmt: PMYSQL_STMT, bnd: PMYSQL_BIND): my_bool{.
    stdcall, dynlib: mysqllib, importc: "mysql_stmt_bind_param".}
proc mysql_stmt_bind_result*(stmt: PMYSQL_STMT, bnd: PMYSQL_BIND): my_bool{.
    stdcall, dynlib: mysqllib, importc: "mysql_stmt_bind_result".}
proc mysql_stmt_close*(stmt: PMYSQL_STMT): my_bool{.stdcall, dynlib: mysqllib, 
    importc: "mysql_stmt_close".}
proc mysql_stmt_reset*(stmt: PMYSQL_STMT): my_bool{.stdcall, dynlib: mysqllib, 
    importc: "mysql_stmt_reset".}
proc mysql_stmt_free_result*(stmt: PMYSQL_STMT): my_bool{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_free_result".}
proc mysql_stmt_send_long_data*(stmt: PMYSQL_STMT, param_number: cuint, 
                                data: cstring, len: int): my_bool{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_send_long_data".}
proc mysql_stmt_result_metadata*(stmt: PMYSQL_STMT): PMYSQL_RES{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_result_metadata".}
proc mysql_stmt_param_metadata*(stmt: PMYSQL_STMT): PMYSQL_RES{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_param_metadata".}
proc mysql_stmt_errno*(stmt: PMYSQL_STMT): cuint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_stmt_errno".}
proc mysql_stmt_error*(stmt: PMYSQL_STMT): cstring{.stdcall, dynlib: mysqllib, 
    importc: "mysql_stmt_error".}
proc mysql_stmt_sqlstate*(stmt: PMYSQL_STMT): cstring{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_sqlstate".}
proc mysql_stmt_row_seek*(stmt: PMYSQL_STMT, offset: MYSQL_ROW_OFFSET): MYSQL_ROW_OFFSET{.
    stdcall, dynlib: mysqllib, importc: "mysql_stmt_row_seek".}
proc mysql_stmt_row_tell*(stmt: PMYSQL_STMT): MYSQL_ROW_OFFSET{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_row_tell".}
proc mysql_stmt_data_seek*(stmt: PMYSQL_STMT, offset: my_ulonglong){.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_data_seek".}
proc mysql_stmt_num_rows*(stmt: PMYSQL_STMT): my_ulonglong{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_num_rows".}
proc mysql_stmt_affected_rows*(stmt: PMYSQL_STMT): my_ulonglong{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_affected_rows".}
proc mysql_stmt_insert_id*(stmt: PMYSQL_STMT): my_ulonglong{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_insert_id".}
proc mysql_stmt_field_count*(stmt: PMYSQL_STMT): cuint{.stdcall, 
    dynlib: mysqllib, importc: "mysql_stmt_field_count".}
proc mysql_commit*(mysql: PMYSQL): my_bool{.stdcall, dynlib: mysqllib, 
    importc: "mysql_commit".}
proc mysql_rollback*(mysql: PMYSQL): my_bool{.stdcall, dynlib: mysqllib, 
    importc: "mysql_rollback".}
proc mysql_autocommit*(mysql: PMYSQL, auto_mode: my_bool): my_bool{.stdcall, 
    dynlib: mysqllib, importc: "mysql_autocommit".}
proc mysql_more_results*(mysql: PMYSQL): my_bool{.stdcall, dynlib: mysqllib, 
    importc: "mysql_more_results".}
proc mysql_next_result*(mysql: PMYSQL): cint{.stdcall, dynlib: mysqllib, 
    importc: "mysql_next_result".}
proc mysql_close*(sock: PMYSQL){.stdcall, dynlib: mysqllib, 
                                 importc: "mysql_close".}
  # status return codes  
const 
  MYSQL_NO_DATA* = 100
  MYSQL_DATA_TRUNCATED* = 101

proc mysql_reload*(mysql: PMySQL): cint

when defined(USE_OLD_FUNCTIONS): 
  proc mysql_connect*(mysql: PMYSQL, host: cstring, user: cstring, 
                      passwd: cstring): PMYSQL{.stdcall, 
      dynlib: External_library, importc: "mysql_connect".}
  proc mysql_create_db*(mysql: PMYSQL, DB: cstring): cint{.stdcall, 
      dynlib: External_library, importc: "mysql_create_db".}
  proc mysql_drop_db*(mysql: PMYSQL, DB: cstring): cint{.stdcall, 
      dynlib: External_library, importc: "mysql_drop_db".}
  proc mysql_reload*(mysql: PMySQL): cint

proc net_safe_read*(mysql: PMYSQL): cuint{.cdecl, dynlib: mysqllib, 
    importc: "net_safe_read".}

proc net_new_transaction(net: st_net): st_net = 
  assert false
  #net.pkt_nr = 0
  result = net

proc IS_PRI_KEY(n: int32): bool = 
  result = (n and PRI_KEY_FLAG) != 0

proc IS_NOT_NULL(n: int32): bool = 
  result = (n and NOT_NULL_FLAG) != 0

proc IS_BLOB(n: int32): bool = 
  result = (n and BLOB_FLAG) != 0

proc IS_NUM_FIELD(f: pst_mysql_field): bool = 
  result = (f.flags and NUM_FLAG) != 0

proc IS_NUM(t: enum_field_types): bool = 
  result = (t <= FIELD_TYPE_INT24) or (t == FIELD_TYPE_YEAR) or
      (t == FIELD_TYPE_NEWDECIMAL)

proc INTERNAL_NUM_FIELD(f: Pst_mysql_field): bool = 
  result = (f.ftype <= FIELD_TYPE_INT24) and
      ((f.ftype != FIELD_TYPE_TIMESTAMP) or (f.len == 14) or (f.len == 8)) or
      (f.ftype == FIELD_TYPE_YEAR)

proc mysql_reload(mysql: PMySQL): cint = 
  result = mysql_refresh(mysql, REFRESH_GRANT)

