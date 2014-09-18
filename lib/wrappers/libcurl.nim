#
#    $Id: header,v 1.1 2000/07/13 06:33:45 michael Exp $
#    This file is part of the Free Pascal packages
#    Copyright (c) 1999-2000 by the Free Pascal development team
#
#    See the file COPYING.FPC, included in this distribution,
#    for details about the copyright.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# **********************************************************************
#
#   the curl library is governed by its own copyright, see the curl
#   website for this. 
# 

{.deadCodeElim: on.}

import 
  times

when defined(windows): 
  const 
    libname = "libcurl.dll"
elif defined(macosx): 
  const 
    libname = "libcurl-7.19.3.dylib"
elif defined(unix): 
  const 
    libname = "libcurl.so.4"
type 
  Pcalloc_callback* = ptr Tcalloc_callback
  Pclosepolicy* = ptr Tclosepolicy
  Pforms* = ptr Tforms
  Pftpauth* = ptr Tftpauth
  Pftpmethod* = ptr Tftpmethod
  Pftpssl* = ptr Tftpssl
  PHTTP_VERSION* = ptr THTTP_VERSION
  Phttppost* = ptr Thttppost
  PPcurl_httppost* = ptr Phttppost
  Pinfotype* = ptr Tinfotype
  Plock_access* = ptr Tlock_access
  Plock_data* = ptr Tlock_data
  Pmalloc_callback* = ptr Tmalloc_callback
  PNETRC_OPTION* = ptr TNETRC_OPTION
  Pproxytype* = ptr Tproxytype
  Prealloc_callback* = ptr Trealloc_callback
  Pslist* = ptr Tslist
  Psocket* = ptr Tsocket
  PSSL_VERSION* = ptr TSSL_VERSION
  Pstrdup_callback* = ptr Tstrdup_callback
  PTIMECOND* = ptr TTIMECOND
  Pversion_info_data* = ptr Tversion_info_data
  Pcode* = ptr Tcode
  PFORMcode* = ptr TFORMcode
  Pformoption* = ptr Tformoption
  PINFO* = ptr TINFO
  Piocmd* = ptr Tiocmd
  Pioerr* = ptr Tioerr
  PM* = ptr TM
  PMcode* = ptr TMcode
  PMoption* = ptr TMoption
  PMSG* = ptr TMSG
  Poption* = ptr Toption
  PSH* = ptr TSH
  PSHcode* = ptr TSHcode
  PSHoption* = ptr TSHoption
  Pversion* = ptr Tversion
  Pfd_set* = pointer
  PCurl* = ptr TCurl
  TCurl* = pointer
  Thttppost*{.final, pure.} = object 
    next*: Phttppost
    name*: cstring
    namelength*: int32
    contents*: cstring
    contentslength*: int32
    buffer*: cstring
    bufferlength*: int32
    contenttype*: cstring
    contentheader*: Pslist
    more*: Phttppost
    flags*: int32
    showfilename*: cstring

  Tprogress_callback* = proc (clientp: pointer, dltotal: float64, 
                              dlnow: float64, ultotal: float64, 
                              ulnow: float64): int32 {.cdecl.}
  Twrite_callback* = proc (buffer: cstring, size: int, nitems: int, 
                           outstream: pointer): int{.cdecl.}
  Tread_callback* = proc (buffer: cstring, size: int, nitems: int, 
                          instream: pointer): int{.cdecl.}
  Tpasswd_callback* = proc (clientp: pointer, prompt: cstring, buffer: cstring, 
                            buflen: int32): int32{.cdecl.}
  Tioerr* = enum 
    IOE_OK, IOE_UNKNOWNCMD, IOE_FAILRESTART, IOE_LAST
  Tiocmd* = enum 
    IOCMD_NOP, IOCMD_RESTARTREAD, IOCMD_LAST
  Tioctl_callback* = proc (handle: PCurl, cmd: int32, clientp: pointer): Tioerr{.
      cdecl.}
  Tmalloc_callback* = proc (size: int): pointer{.cdecl.}
  Tfree_callback* = proc (p: pointer){.cdecl.}
  Trealloc_callback* = proc (p: pointer, size: int): pointer{.cdecl.}
  Tstrdup_callback* = proc (str: cstring): cstring{.cdecl.}
  Tcalloc_callback* = proc (nmemb: int, size: int): pointer{.noconv.}
  Tinfotype* = enum 
    INFO_TEXT = 0, INFO_HEADER_IN, INFO_HEADER_OUT, INFO_DATA_IN, INFO_DATA_OUT, 
    INFO_SSL_DATA_IN, INFO_SSL_DATA_OUT, INFO_END
  Tdebug_callback* = proc (handle: PCurl, theType: Tinfotype, data: cstring, 
                           size: int, userptr: pointer): int32{.cdecl.}
  Tcode* = enum 
    E_OK = 0, E_UNSUPPORTED_PROTOCOL, E_FAILED_INIT, E_URL_MALFORMAT, 
    E_URL_MALFORMAT_USER, E_COULDNT_RESOLVE_PROXY, E_COULDNT_RESOLVE_HOST, 
    E_COULDNT_CONNECT, E_FTP_WEIRD_SERVER_REPLY, E_FTP_ACCESS_DENIED, 
    E_FTP_USER_PASSWORD_INCORRECT, E_FTP_WEIRD_PASS_REPLY, 
    E_FTP_WEIRD_USER_REPLY, E_FTP_WEIRD_PASV_REPLY, E_FTP_WEIRD_227_FORMAT, 
    E_FTP_CANT_GET_HOST, E_FTP_CANT_RECONNECT, E_FTP_COULDNT_SET_BINARY, 
    E_PARTIAL_FILE, E_FTP_COULDNT_RETR_FILE, E_FTP_WRITE_ERROR, 
    E_FTP_QUOTE_ERROR, E_HTTP_RETURNED_ERROR, E_WRITE_ERROR, E_MALFORMAT_USER, 
    E_FTP_COULDNT_STOR_FILE, E_READ_ERROR, E_OUT_OF_MEMORY, 
    E_OPERATION_TIMEOUTED, E_FTP_COULDNT_SET_ASCII, E_FTP_PORT_FAILED, 
    E_FTP_COULDNT_USE_REST, E_FTP_COULDNT_GET_SIZE, E_HTTP_RANGE_ERROR, 
    E_HTTP_POST_ERROR, E_SSL_CONNECT_ERROR, E_BAD_DOWNLOAD_RESUME, 
    E_FILE_COULDNT_READ_FILE, E_LDAP_CANNOT_BIND, E_LDAP_SEARCH_FAILED, 
    E_LIBRARY_NOT_FOUND, E_FUNCTION_NOT_FOUND, E_ABORTED_BY_CALLBACK, 
    E_BAD_FUNCTION_ARGUMENT, E_BAD_CALLING_ORDER, E_INTERFACE_FAILED, 
    E_BAD_PASSWORD_ENTERED, E_TOO_MANY_REDIRECTS, E_UNKNOWN_TELNET_OPTION, 
    E_TELNET_OPTION_SYNTAX, E_OBSOLETE, E_SSL_PEER_CERTIFICATE, E_GOT_NOTHING, 
    E_SSL_ENGINE_NOTFOUND, E_SSL_ENGINE_SETFAILED, E_SEND_ERROR, E_RECV_ERROR, 
    E_SHARE_IN_USE, E_SSL_CERTPROBLEM, E_SSL_CIPHER, E_SSL_CACERT, 
    E_BAD_CONTENT_ENCODING, E_LDAP_INVALID_URL, E_FILESIZE_EXCEEDED, 
    E_FTP_SSL_FAILED, E_SEND_FAIL_REWIND, E_SSL_ENGINE_INITFAILED, 
    E_LOGIN_DENIED, E_TFTP_NOTFOUND, E_TFTP_PERM, E_TFTP_DISKFULL, 
    E_TFTP_ILLEGAL, E_TFTP_UNKNOWNID, E_TFTP_EXISTS, E_TFTP_NOSUCHUSER, 
    E_CONV_FAILED, E_CONV_REQD, LAST
  Tconv_callback* = proc (buffer: cstring, len: int): Tcode{.cdecl.}
  Tssl_ctx_callback* = proc (curl: PCurl, ssl_ctx, userptr: pointer): Tcode{.cdecl.}
  Tproxytype* = enum 
    PROXY_HTTP = 0, PROXY_SOCKS4 = 4, PROXY_SOCKS5 = 5
  Tftpssl* = enum 
    FTPSSL_NONE, FTPSSL_TRY, FTPSSL_CONTROL, FTPSSL_ALL, FTPSSL_LAST
  Tftpauth* = enum 
    FTPAUTH_DEFAULT, FTPAUTH_SSL, FTPAUTH_TLS, FTPAUTH_LAST
  Tftpmethod* = enum 
    FTPMETHOD_DEFAULT, FTPMETHOD_MULTICWD, FTPMETHOD_NOCWD, FTPMETHOD_SINGLECWD, 
    FTPMETHOD_LAST
  Toption* = enum 
    OPT_PORT = 0 + 3, OPT_TIMEOUT = 0 + 13, OPT_INFILESIZE = 0 + 14, 
    OPT_LOW_SPEED_LIMIT = 0 + 19, OPT_LOW_SPEED_TIME = 0 + 20, 
    OPT_RESUME_FROM = 0 + 21, OPT_CRLF = 0 + 27, OPT_SSLVERSION = 0 + 32, 
    OPT_TIMECONDITION = 0 + 33, OPT_TIMEVALUE = 0 + 34, OPT_VERBOSE = 0 + 41, 
    OPT_HEADER = 0 + 42, OPT_NOPROGRESS = 0 + 43, OPT_NOBODY = 0 + 44, 
    OPT_FAILONERROR = 0 + 45, OPT_UPLOAD = 0 + 46, OPT_POST = 0 + 47, 
    OPT_FTPLISTONLY = 0 + 48, OPT_FTPAPPEND = 0 + 50, OPT_NETRC = 0 + 51, 
    OPT_FOLLOWLOCATION = 0 + 52, OPT_TRANSFERTEXT = 0 + 53, OPT_PUT = 0 + 54, 
    OPT_AUTOREFERER = 0 + 58, OPT_PROXYPORT = 0 + 59, 
    OPT_POSTFIELDSIZE = 0 + 60, OPT_HTTPPROXYTUNNEL = 0 + 61, 
    OPT_SSL_VERIFYPEER = 0 + 64, OPT_MAXREDIRS = 0 + 68, OPT_FILETIME = 0 + 69, 
    OPT_MAXCONNECTS = 0 + 71, OPT_CLOSEPOLICY = 0 + 72, 
    OPT_FRESH_CONNECT = 0 + 74, OPT_FORBID_REUSE = 0 + 75, 
    OPT_CONNECTTIMEOUT = 0 + 78, OPT_HTTPGET = 0 + 80, 
    OPT_SSL_VERIFYHOST = 0 + 81, OPT_HTTP_VERSION = 0 + 84, 
    OPT_FTP_USE_EPSV = 0 + 85, OPT_SSLENGINE_DEFAULT = 0 + 90, 
    OPT_DNS_USE_GLOBAL_CACHE = 0 + 91, OPT_DNS_CACHE_TIMEOUT = 0 + 92, 
    OPT_COOKIESESSION = 0 + 96, OPT_BUFFERSIZE = 0 + 98, OPT_NOSIGNAL = 0 + 99, 
    OPT_PROXYTYPE = 0 + 101, OPT_UNRESTRICTED_AUTH = 0 + 105, 
    OPT_FTP_USE_EPRT = 0 + 106, OPT_HTTPAUTH = 0 + 107, 
    OPT_FTP_CREATE_MISSING_DIRS = 0 + 110, OPT_PROXYAUTH = 0 + 111, 
    OPT_FTP_RESPONSE_TIMEOUT = 0 + 112, OPT_IPRESOLVE = 0 + 113, 
    OPT_MAXFILESIZE = 0 + 114, OPT_FTP_SSL = 0 + 119, OPT_TCP_NODELAY = 0 + 121, 
    OPT_FTPSSLAUTH = 0 + 129, OPT_IGNORE_CONTENT_LENGTH = 0 + 136, 
    OPT_FTP_SKIP_PASV_IP = 0 + 137, OPT_FTP_FILEMETHOD = 0 + 138, 
    OPT_LOCALPORT = 0 + 139, OPT_LOCALPORTRANGE = 0 + 140, 
    OPT_CONNECT_ONLY = 0 + 141, OPT_FILE = 10000 + 1, OPT_URL = 10000 + 2, 
    OPT_PROXY = 10000 + 4, OPT_USERPWD = 10000 + 5, 
    OPT_PROXYUSERPWD = 10000 + 6, OPT_RANGE = 10000 + 7, OPT_INFILE = 10000 + 9, 
    OPT_ERRORBUFFER = 10000 + 10, OPT_POSTFIELDS = 10000 + 15, 
    OPT_REFERER = 10000 + 16, OPT_FTPPORT = 10000 + 17, 
    OPT_USERAGENT = 10000 + 18, OPT_COOKIE = 10000 + 22, 
    OPT_HTTPHEADER = 10000 + 23, OPT_HTTPPOST = 10000 + 24, 
    OPT_SSLCERT = 10000 + 25, OPT_SSLCERTPASSWD = 10000 + 26, 
    OPT_QUOTE = 10000 + 28, OPT_WRITEHEADER = 10000 + 29, 
    OPT_COOKIEFILE = 10000 + 31, OPT_CUSTOMREQUEST = 10000 + 36, 
    OPT_STDERR = 10000 + 37, OPT_POSTQUOTE = 10000 + 39, 
    OPT_WRITEINFO = 10000 + 40, OPT_PROGRESSDATA = 10000 + 57, 
    OPT_INTERFACE = 10000 + 62, OPT_KRB4LEVEL = 10000 + 63, 
    OPT_CAINFO = 10000 + 65, OPT_TELNETOPTIONS = 10000 + 70, 
    OPT_RANDOM_FILE = 10000 + 76, OPT_EGDSOCKET = 10000 + 77, 
    OPT_COOKIEJAR = 10000 + 82, OPT_SSL_CIPHER_LIST = 10000 + 83, 
    OPT_SSLCERTTYPE = 10000 + 86, OPT_SSLKEY = 10000 + 87, 
    OPT_SSLKEYTYPE = 10000 + 88, OPT_SSLENGINE = 10000 + 89, 
    OPT_PREQUOTE = 10000 + 93, OPT_DEBUGDATA = 10000 + 95, 
    OPT_CAPATH = 10000 + 97, OPT_SHARE = 10000 + 100, 
    OPT_ENCODING = 10000 + 102, OPT_PRIVATE = 10000 + 103, 
    OPT_HTTP200ALIASES = 10000 + 104, OPT_SSL_CTX_DATA = 10000 + 109, 
    OPT_NETRC_FILE = 10000 + 118, OPT_SOURCE_USERPWD = 10000 + 123, 
    OPT_SOURCE_PREQUOTE = 10000 + 127, OPT_SOURCE_POSTQUOTE = 10000 + 128, 
    OPT_IOCTLDATA = 10000 + 131, OPT_SOURCE_URL = 10000 + 132, 
    OPT_SOURCE_QUOTE = 10000 + 133, OPT_FTP_ACCOUNT = 10000 + 134, 
    OPT_COOKIELIST = 10000 + 135, OPT_FTP_ALTERNATIVE_TO_USER = 10000 + 147, 
    OPT_LASTENTRY = 10000 + 148, OPT_WRITEFUNCTION = 20000 + 11, 
    OPT_READFUNCTION = 20000 + 12, OPT_PROGRESSFUNCTION = 20000 + 56, 
    OPT_HEADERFUNCTION = 20000 + 79, OPT_DEBUGFUNCTION = 20000 + 94, 
    OPT_SSL_CTX_FUNCTION = 20000 + 108, OPT_IOCTLFUNCTION = 20000 + 130, 
    OPT_CONV_FROM_NETWORK_FUNCTION = 20000 + 142, 
    OPT_CONV_TO_NETWORK_FUNCTION = 20000 + 143, 
    OPT_CONV_FROM_UTF8_FUNCTION = 20000 + 144, 
    OPT_INFILESIZE_LARGE = 30000 + 115, OPT_RESUME_FROM_LARGE = 30000 + 116, 
    OPT_MAXFILESIZE_LARGE = 30000 + 117, OPT_POSTFIELDSIZE_LARGE = 30000 + 120, 
    OPT_MAX_SEND_SPEED_LARGE = 30000 + 145, 
    OPT_MAX_RECV_SPEED_LARGE = 30000 + 146
  THTTP_VERSION* = enum 
    HTTP_VERSION_NONE, HTTP_VERSION_1_0, HTTP_VERSION_1_1, HTTP_VERSION_LAST
  TNETRC_OPTION* = enum 
    NETRC_IGNORED, NETRC_OPTIONAL, NETRC_REQUIRED, NETRC_LAST
  TSSL_VERSION* = enum 
    SSLVERSION_DEFAULT, SSLVERSION_TLSv1, SSLVERSION_SSLv2, SSLVERSION_SSLv3, 
    SSLVERSION_LAST
  TTIMECOND* = enum 
    TIMECOND_NONE, TIMECOND_IFMODSINCE, TIMECOND_IFUNMODSINCE, TIMECOND_LASTMOD, 
    TIMECOND_LAST
  Tformoption* = enum 
    FORM_NOTHING, FORM_COPYNAME, FORM_PTRNAME, FORM_NAMELENGTH, 
    FORM_COPYCONTENTS, FORM_PTRCONTENTS, FORM_CONTENTSLENGTH, FORM_FILECONTENT, 
    FORM_ARRAY, FORM_OBSOLETE, FORM_FILE, FORM_BUFFER, FORM_BUFFERPTR, 
    FORM_BUFFERLENGTH, FORM_CONTENTTYPE, FORM_CONTENTHEADER, FORM_FILENAME, 
    FORM_END, FORM_OBSOLETE2, FORM_LASTENTRY
  Tforms*{.pure, final.} = object 
    option*: Tformoption
    value*: cstring

  TFORMcode* = enum 
    FORMADD_OK, FORMADD_MEMORY, FORMADD_OPTION_TWICE, FORMADD_NULL, 
    FORMADD_UNKNOWN_OPTION, FORMADD_INCOMPLETE, FORMADD_ILLEGAL_ARRAY, 
    FORMADD_DISABLED, FORMADD_LAST
  Tformget_callback* = proc (arg: pointer, buf: cstring, length: int): int{.
      cdecl.}
  Tslist*{.pure, final.} = object 
    data*: cstring
    next*: Pslist

  TINFO* = enum 
    INFO_NONE = 0, INFO_LASTONE = 30, INFO_EFFECTIVE_URL = 0x00100000 + 1, 
    INFO_CONTENT_TYPE = 0x00100000 + 18, INFO_PRIVATE = 0x00100000 + 21, 
    INFO_FTP_ENTRY_PATH = 0x00100000 + 30, INFO_RESPONSE_CODE = 0x00200000 + 2, 
    INFO_HEADER_SIZE = 0x00200000 + 11, INFO_REQUEST_SIZE = 0x00200000 + 12, 
    INFO_SSL_VERIFYRESULT = 0x00200000 + 13, INFO_FILETIME = 0x00200000 + 14, 
    INFO_REDIRECT_COUNT = 0x00200000 + 20, 
    INFO_HTTP_CONNECTCODE = 0x00200000 + 22, 
    INFO_HTTPAUTH_AVAIL = 0x00200000 + 23, 
    INFO_PROXYAUTH_AVAIL = 0x00200000 + 24, INFO_OS_ERRNO = 0x00200000 + 25, 
    INFO_NUM_CONNECTS = 0x00200000 + 26, INFO_LASTSOCKET = 0x00200000 + 29, 
    INFO_TOTAL_TIME = 0x00300000 + 3, INFO_NAMELOOKUP_TIME = 0x00300000 + 4, 
    INFO_CONNECT_TIME = 0x00300000 + 5, INFO_PRETRANSFER_TIME = 0x00300000 + 6, 
    INFO_SIZE_UPLOAD = 0x00300000 + 7, INFO_SIZE_DOWNLOAD = 0x00300000 + 8, 
    INFO_SPEED_DOWNLOAD = 0x00300000 + 9, INFO_SPEED_UPLOAD = 0x00300000 + 10, 
    INFO_CONTENT_LENGTH_DOWNLOAD = 0x00300000 + 15, 
    INFO_CONTENT_LENGTH_UPLOAD = 0x00300000 + 16, 
    INFO_STARTTRANSFER_TIME = 0x00300000 + 17, 
    INFO_REDIRECT_TIME = 0x00300000 + 19, INFO_SSL_ENGINES = 0x00400000 + 27, 
    INFO_COOKIELIST = 0x00400000 + 28
  Tclosepolicy* = enum 
    CLOSEPOLICY_NONE, CLOSEPOLICY_OLDEST, CLOSEPOLICY_LEAST_RECENTLY_USED, 
    CLOSEPOLICY_LEAST_TRAFFIC, CLOSEPOLICY_SLOWEST, CLOSEPOLICY_CALLBACK, 
    CLOSEPOLICY_LAST
  Tlock_data* = enum 
    LOCK_DATA_NONE = 0, LOCK_DATA_SHARE, LOCK_DATA_COOKIE, LOCK_DATA_DNS, 
    LOCK_DATA_SSL_SESSION, LOCK_DATA_CONNECT, LOCK_DATA_LAST
  Tlock_access* = enum 
    LOCK_ACCESS_NONE = 0, LOCK_ACCESS_SHARED = 1, LOCK_ACCESS_SINGLE = 2, 
    LOCK_ACCESS_LAST
  Tlock_function* = proc (handle: PCurl, data: Tlock_data,
                          locktype: Tlock_access, 
                          userptr: pointer){.cdecl.}
  Tunlock_function* = proc (handle: PCurl, data: Tlock_data, userptr: pointer){.
      cdecl.}
  TSH* = pointer
  TSHcode* = enum 
    SHE_OK, SHE_BAD_OPTION, SHE_IN_USE, SHE_INVALID, SHE_NOMEM, SHE_LAST
  TSHoption* = enum 
    SHOPT_NONE, SHOPT_SHARE, SHOPT_UNSHARE, SHOPT_LOCKFUNC, SHOPT_UNLOCKFUNC, 
    SHOPT_USERDATA, SHOPT_LAST
  Tversion* = enum 
    VERSION_FIRST, VERSION_SECOND, VERSION_THIRD, VERSION_LAST
  Tversion_info_data*{.pure, final.} = object 
    age*: Tversion
    version*: cstring
    version_num*: int32
    host*: cstring
    features*: int32
    ssl_version*: cstring
    ssl_version_num*: int32
    libz_version*: cstring
    protocols*: cstringArray
    ares*: cstring
    ares_num*: int32
    libidn*: cstring
    iconv_ver_num*: int32

  TM* = pointer
  Tsocket* = int32
  TMcode* = enum 
    M_CALL_MULTI_PERFORM = - 1, M_OK = 0, M_BAD_HANDLE, M_BAD_EASY_HANDLE, 
    M_OUT_OF_MEMORY, M_INTERNAL_ERROR, M_BAD_SOCKET, M_UNKNOWN_OPTION, M_LAST
  TMSGEnum* = enum 
    MSG_NONE, MSG_DONE, MSG_LAST
  TMsg*{.pure, final.} = object 
    msg*: TMSGEnum
    easy_handle*: PCurl
    whatever*: pointer        #data : record
                              #      case longint of
                              #        0 : ( whatever : pointer );
                              #        1 : ( result : CURLcode );
                              #    end;
  
  Tsocket_callback* = proc (easy: PCurl, s: Tsocket, what: int32, 
                            userp, socketp: pointer): int32{.cdecl.}
  TMoption* = enum 
    MOPT_SOCKETDATA = 10000 + 2, MOPT_LASTENTRY = 10000 + 3, 
    MOPT_SOCKETFUNCTION = 20000 + 1

const 
  OPT_SSLKEYPASSWD* = OPT_SSLCERTPASSWD
  AUTH_ANY* = not (0)
  AUTH_BASIC* = 1 shl 0
  AUTH_ANYSAFE* = not (AUTH_BASIC)
  AUTH_DIGEST* = 1 shl 1
  AUTH_GSSNEGOTIATE* = 1 shl 2
  AUTH_NONE* = 0
  AUTH_NTLM* = 1 shl 3
  E_ALREADY_COMPLETE* = 99999
  E_FTP_BAD_DOWNLOAD_RESUME* = E_BAD_DOWNLOAD_RESUME
  E_FTP_PARTIAL_FILE* = E_PARTIAL_FILE
  E_HTTP_NOT_FOUND* = E_HTTP_RETURNED_ERROR
  E_HTTP_PORT_FAILED* = E_INTERFACE_FAILED
  E_OPERATION_TIMEDOUT* = E_OPERATION_TIMEOUTED
  ERROR_SIZE* = 256
  FORMAT_OFF_T* = "%ld"
  GLOBAL_NOTHING* = 0
  GLOBAL_SSL* = 1 shl 0
  GLOBAL_WIN32* = 1 shl 1
  GLOBAL_ALL* = GLOBAL_SSL or GLOBAL_WIN32
  GLOBAL_DEFAULT* = GLOBAL_ALL
  INFO_DOUBLE* = 0x00300000
  INFO_HTTP_CODE* = INFO_RESPONSE_CODE
  INFO_LONG* = 0x00200000
  INFO_MASK* = 0x000FFFFF
  INFO_SLIST* = 0x00400000
  INFO_STRING* = 0x00100000
  INFO_TYPEMASK* = 0x00F00000
  IPRESOLVE_V4* = 1
  IPRESOLVE_V6* = 2
  IPRESOLVE_WHATEVER* = 0
  MAX_WRITE_SIZE* = 16384
  M_CALL_MULTI_SOCKET* = M_CALL_MULTI_PERFORM
  OPT_CLOSEFUNCTION* = - (5)
  OPT_FTPASCII* = OPT_TRANSFERTEXT
  OPT_HEADERDATA* = OPT_WRITEHEADER
  OPT_HTTPREQUEST* = - (1)
  OPT_MUTE* = - (2)
  OPT_PASSWDDATA* = - (4)
  OPT_PASSWDFUNCTION* = - (3)
  OPT_PASV_HOST* = - (9)
  OPT_READDATA* = OPT_INFILE
  OPT_SOURCE_HOST* = - (6)
  OPT_SOURCE_PATH* = - (7)
  OPT_SOURCE_PORT* = - (8)
  OPTTYPE_FUNCTIONPOINT* = 20000
  OPTTYPE_LONG* = 0
  OPTTYPE_OBJECTPOINT* = 10000
  OPTTYPE_OFF_T* = 30000
  OPT_WRITEDATA* = OPT_FILE
  POLL_IN* = 1
  POLL_INOUT* = 3
  POLL_NONE* = 0
  POLL_OUT* = 2
  POLL_REMOVE* = 4
  READFUNC_ABORT* = 0x10000000
  SOCKET_BAD* = - (1)
  SOCKET_TIMEOUT* = SOCKET_BAD
  VERSION_ASYNCHDNS* = 1 shl 7
  VERSION_CONV* = 1 shl 12
  VERSION_DEBUG* = 1 shl 6
  VERSION_GSSNEGOTIATE* = 1 shl 5
  VERSION_IDN* = 1 shl 10
  VERSION_IPV6* = 1 shl 0
  VERSION_KERBEROS4* = 1 shl 1
  VERSION_LARGEFILE* = 1 shl 9
  VERSION_LIBZ* = 1 shl 3
  VERSION_NOW* = VERSION_THIRD
  VERSION_NTLM* = 1 shl 4
  VERSION_SPNEGO* = 1 shl 8
  VERSION_SSL* = 1 shl 2
  VERSION_SSPI* = 1 shl 11
  FILE_OFFSET_BITS* = 0
  FILESIZEBITS* = 0
  FUNCTIONPOINT* = OPTTYPE_FUNCTIONPOINT
  HTTPPOST_BUFFER* = 1 shl 4
  HTTPPOST_FILENAME* = 1 shl 0
  HTTPPOST_PTRBUFFER* = 1 shl 5
  HTTPPOST_PTRCONTENTS* = 1 shl 3
  HTTPPOST_PTRNAME* = 1 shl 2
  HTTPPOST_READFILE* = 1 shl 1
  LIBCURL_VERSION* = "7.15.5"
  LIBCURL_VERSION_MAJOR* = 7
  LIBCURL_VERSION_MINOR* = 15
  LIBCURL_VERSION_NUM* = 0x00070F05
  LIBCURL_VERSION_PATCH* = 5

proc strequal*(s1, s2: cstring): int32{.cdecl, dynlib: libname, 
                                        importc: "curl_strequal".}
proc strnequal*(s1, s2: cstring, n: int): int32{.cdecl, dynlib: libname, 
    importc: "curl_strnequal".}
proc formadd*(httppost, last_post: PPcurl_httppost): TFORMcode{.cdecl, varargs, 
    dynlib: libname, importc: "curl_formadd".}
proc formget*(form: Phttppost, arg: pointer, append: Tformget_callback): int32{.
    cdecl, dynlib: libname, importc: "curl_formget".}
proc formfree*(form: Phttppost){.cdecl, dynlib: libname, 
                                 importc: "curl_formfree".}
proc getenv*(variable: cstring): cstring{.cdecl, dynlib: libname, 
    importc: "curl_getenv".}
proc version*(): cstring{.cdecl, dynlib: libname, importc: "curl_version".}
proc easy_escape*(handle: PCurl, str: cstring, len: int32): cstring{.cdecl, 
    dynlib: libname, importc: "curl_easy_escape".}
proc escape*(str: cstring, len: int32): cstring{.cdecl, dynlib: libname, 
    importc: "curl_escape".}
proc easy_unescape*(handle: PCurl, str: cstring, len: int32, outlength: var int32): cstring{.
    cdecl, dynlib: libname, importc: "curl_easy_unescape".}
proc unescape*(str: cstring, len: int32): cstring{.cdecl, dynlib: libname, 
    importc: "curl_unescape".}
proc free*(p: pointer){.cdecl, dynlib: libname, importc: "curl_free".}
proc global_init*(flags: int32): Tcode{.cdecl, dynlib: libname, 
                                        importc: "curl_global_init".}
proc global_init_mem*(flags: int32, m: Tmalloc_callback, f: Tfree_callback, 
                      r: Trealloc_callback, s: Tstrdup_callback, 
                      c: Tcalloc_callback): Tcode{.cdecl, dynlib: libname, 
    importc: "curl_global_init_mem".}
proc global_cleanup*(){.cdecl, dynlib: libname, importc: "curl_global_cleanup".}
proc slist_append*(slist: Pslist, p: cstring): Pslist{.cdecl, dynlib: libname, 
    importc: "curl_slist_append".}
proc slist_free_all*(para1: Pslist){.cdecl, dynlib: libname, 
                                     importc: "curl_slist_free_all".}
proc getdate*(p: cstring, unused: ptr Time): Time{.cdecl, dynlib: libname, 
    importc: "curl_getdate".}
proc share_init*(): PSH{.cdecl, dynlib: libname, importc: "curl_share_init".}
proc share_setopt*(para1: PSH, option: TSHoption): TSHcode{.cdecl, varargs, 
    dynlib: libname, importc: "curl_share_setopt".}
proc share_cleanup*(para1: PSH): TSHcode{.cdecl, dynlib: libname, 
    importc: "curl_share_cleanup".}
proc version_info*(para1: Tversion): Pversion_info_data{.cdecl, dynlib: libname, 
    importc: "curl_version_info".}
proc easy_strerror*(para1: Tcode): cstring{.cdecl, dynlib: libname, 
    importc: "curl_easy_strerror".}
proc share_strerror*(para1: TSHcode): cstring{.cdecl, dynlib: libname, 
    importc: "curl_share_strerror".}
proc easy_init*(): PCurl{.cdecl, dynlib: libname, importc: "curl_easy_init".}
proc easy_setopt*(curl: PCurl, option: Toption): Tcode{.cdecl, varargs, dynlib: libname, 
    importc: "curl_easy_setopt".}
proc easy_perform*(curl: PCurl): Tcode{.cdecl, dynlib: libname, 
                                importc: "curl_easy_perform".}
proc easy_cleanup*(curl: PCurl){.cdecl, dynlib: libname, importc: "curl_easy_cleanup".}
proc easy_getinfo*(curl: PCurl, info: TINFO): Tcode{.cdecl, varargs, dynlib: libname, 
    importc: "curl_easy_getinfo".}
proc easy_duphandle*(curl: PCurl): PCurl{.cdecl, dynlib: libname, 
                              importc: "curl_easy_duphandle".}
proc easy_reset*(curl: PCurl){.cdecl, dynlib: libname, importc: "curl_easy_reset".}
proc multi_init*(): PM{.cdecl, dynlib: libname, importc: "curl_multi_init".}
proc multi_add_handle*(multi_handle: PM, handle: PCurl): TMcode{.cdecl, 
    dynlib: libname, importc: "curl_multi_add_handle".}
proc multi_remove_handle*(multi_handle: PM, handle: PCurl): TMcode{.cdecl, 
    dynlib: libname, importc: "curl_multi_remove_handle".}
proc multi_fdset*(multi_handle: PM, read_fd_set: Pfd_set, write_fd_set: Pfd_set, 
                  exc_fd_set: Pfd_set, max_fd: var int32): TMcode{.cdecl, 
    dynlib: libname, importc: "curl_multi_fdset".}
proc multi_perform*(multi_handle: PM, running_handles: var int32): TMcode{.
    cdecl, dynlib: libname, importc: "curl_multi_perform".}
proc multi_cleanup*(multi_handle: PM): TMcode{.cdecl, dynlib: libname, 
    importc: "curl_multi_cleanup".}
proc multi_info_read*(multi_handle: PM, msgs_in_queue: var int32): PMsg{.cdecl, 
    dynlib: libname, importc: "curl_multi_info_read".}
proc multi_strerror*(para1: TMcode): cstring{.cdecl, dynlib: libname, 
    importc: "curl_multi_strerror".}
proc multi_socket*(multi_handle: PM, s: Tsocket, running_handles: var int32): TMcode{.
    cdecl, dynlib: libname, importc: "curl_multi_socket".}
proc multi_socket_all*(multi_handle: PM, running_handles: var int32): TMcode{.
    cdecl, dynlib: libname, importc: "curl_multi_socket_all".}
proc multi_timeout*(multi_handle: PM, milliseconds: var int32): TMcode{.cdecl, 
    dynlib: libname, importc: "curl_multi_timeout".}
proc multi_setopt*(multi_handle: PM, option: TMoption): TMcode{.cdecl, varargs, 
    dynlib: libname, importc: "curl_multi_setopt".}
proc multi_assign*(multi_handle: PM, sockfd: Tsocket, sockp: pointer): TMcode{.
    cdecl, dynlib: libname, importc: "curl_multi_assign".}
