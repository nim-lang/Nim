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

import times

when defined(windows):
  const libname = "libcurl.dll"
elif defined(macosx):
  const libname = "libcurl-7.19.3.dylib"
elif defined(unix):
  const libname = "libcurl.so.4"

type 
  Pcurl_calloc_callback* = ptr Tcurl_calloc_callback
  Pcurl_closepolicy* = ptr Tcurl_closepolicy
  Pcurl_forms* = ptr Tcurl_forms
  Pcurl_ftpauth* = ptr Tcurl_ftpauth
  Pcurl_ftpmethod* = ptr Tcurl_ftpmethod
  Pcurl_ftpssl* = ptr Tcurl_ftpssl
  PCURL_HTTP_VERSION* = ptr TCURL_HTTP_VERSION
  Pcurl_httppost* = ptr Tcurl_httppost
  PPcurl_httppost* = ptr Pcurl_httppost
  Pcurl_infotype* = ptr Tcurl_infotype
  Pcurl_lock_access* = ptr Tcurl_lock_access
  Pcurl_lock_data* = ptr Tcurl_lock_data
  Pcurl_malloc_callback* = ptr tcurl_malloc_callback
  PCURL_NETRC_OPTION* = ptr TCURL_NETRC_OPTION
  Pcurl_proxytype* = ptr Tcurl_proxytype
  Pcurl_realloc_callback* = ptr tcurl_realloc_callback
  Pcurl_slist* = ptr Tcurl_slist
  Pcurl_socket* = ptr Tcurl_socket
  PCURL_SSL_VERSION* = ptr TCURL_SSL_VERSION
  Pcurl_strdup_callback* = ptr Tcurl_strdup_callback
  PCURL_TIMECOND* = ptr TCURL_TIMECOND
  Pcurl_version_info_data* = ptr Tcurl_version_info_data
  PCURLcode* = ptr TCURLcode
  PCURLFORMcode* = ptr TCURLFORMcode
  PCURLformoption* = ptr TCURLformoption
  PCURLINFO* = ptr TCURLINFO
  Pcurliocmd* = ptr Tcurliocmd
  Pcurlioerr* = ptr Tcurlioerr
  PCURLM* = ptr TCURLM
  PCURLMcode* = ptr TCURLMcode
  PCURLMoption* = ptr TCURLMoption
  PCURLMSG* = ptr TCURLMSG
  PCURLoption* = ptr TCURLoption
  PCURLSH* = ptr TCURLSH
  PCURLSHcode* = ptr TCURLSHcode
  PCURLSHoption* = ptr TCURLSHoption
  PCURLversion* = ptr TCURLversion
  Pfd_set* = pointer
  PCURL* = ptr TCurl
  TCurl* = pointer
  Tcurl_httppost* {.final, pure.} = object 
    next*: Pcurl_httppost
    name*: cstring
    namelength*: int32
    contents*: cstring
    contentslength*: int32
    buffer*: cstring
    bufferlength*: int32
    contenttype*: cstring
    contentheader*: Pcurl_slist
    more*: Pcurl_httppost
    flags*: int32
    showfilename*: cstring

  Tcurl_progress_callback* = proc (clientp: pointer, dltotal: float64, 
                                   dlnow: float64, ultotal: float64, 
                                   ulnow: float64): int32{.cdecl.}
  Tcurl_write_callback* = proc (buffer: cstring, size: int, nitems: int, 
                                outstream: pointer): int{.cdecl.}
  Tcurl_read_callback* = proc (buffer: cstring, size: int, nitems: int, 
                               instream: pointer): int{.cdecl.}
  Tcurl_passwd_callback* = proc (clientp: pointer, prompt: cstring, 
                                 buffer: cstring, buflen: int32): int32{.cdecl.}
  Tcurlioerr* = enum 
    CURLIOE_OK, CURLIOE_UNKNOWNCMD, CURLIOE_FAILRESTART, CURLIOE_LAST
  Tcurliocmd* = enum 
    CURLIOCMD_NOP, CURLIOCMD_RESTARTREAD, CURLIOCMD_LAST
  Tcurl_ioctl_callback* = proc (handle: PCURL, cmd: int32, 
                                clientp: pointer): Tcurlioerr {.cdecl.}
  Tcurl_malloc_callback* = proc (size: int): pointer {.cdecl.}
  Tcurl_free_callback* = proc (p: pointer) {.cdecl.}
  Tcurl_realloc_callback* = proc (p: pointer, size: int): pointer {.cdecl.}
  Tcurl_strdup_callback* = proc (str: cstring): cstring {.cdecl.}
  Tcurl_calloc_callback* = proc (nmemb: int, size: int): pointer
  Tcurl_infotype* = enum 
    CURLINFO_TEXT = 0, CURLINFO_HEADER_IN, CURLINFO_HEADER_OUT, 
    CURLINFO_DATA_IN, CURLINFO_DATA_OUT, CURLINFO_SSL_DATA_IN, 
    CURLINFO_SSL_DATA_OUT, CURLINFO_END
  Tcurl_debug_callback* = proc (handle: PCURL, theType: Tcurl_infotype, 
                                data: cstring, size: int, 
                                userptr: pointer): int32 {.cdecl.}
  TCURLcode* = enum 
    CURLE_OK = 0, CURLE_UNSUPPORTED_PROTOCOL, CURLE_FAILED_INIT, 
    CURLE_URL_MALFORMAT, CURLE_URL_MALFORMAT_USER, CURLE_COULDNT_RESOLVE_PROXY, 
    CURLE_COULDNT_RESOLVE_HOST, CURLE_COULDNT_CONNECT, 
    CURLE_FTP_WEIRD_SERVER_REPLY, CURLE_FTP_ACCESS_DENIED, 
    CURLE_FTP_USER_PASSWORD_INCORRECT, CURLE_FTP_WEIRD_PASS_REPLY, 
    CURLE_FTP_WEIRD_USER_REPLY, CURLE_FTP_WEIRD_PASV_REPLY, 
    CURLE_FTP_WEIRD_227_FORMAT, CURLE_FTP_CANT_GET_HOST, 
    CURLE_FTP_CANT_RECONNECT, CURLE_FTP_COULDNT_SET_BINARY, CURLE_PARTIAL_FILE, 
    CURLE_FTP_COULDNT_RETR_FILE, CURLE_FTP_WRITE_ERROR, CURLE_FTP_QUOTE_ERROR, 
    CURLE_HTTP_RETURNED_ERROR, CURLE_WRITE_ERROR, CURLE_MALFORMAT_USER, 
    CURLE_FTP_COULDNT_STOR_FILE, CURLE_READ_ERROR, CURLE_OUT_OF_MEMORY, 
    CURLE_OPERATION_TIMEOUTED, CURLE_FTP_COULDNT_SET_ASCII, 
    CURLE_FTP_PORT_FAILED, CURLE_FTP_COULDNT_USE_REST, 
    CURLE_FTP_COULDNT_GET_SIZE, CURLE_HTTP_RANGE_ERROR, CURLE_HTTP_POST_ERROR, 
    CURLE_SSL_CONNECT_ERROR, CURLE_BAD_DOWNLOAD_RESUME, 
    CURLE_FILE_COULDNT_READ_FILE, CURLE_LDAP_CANNOT_BIND, 
    CURLE_LDAP_SEARCH_FAILED, CURLE_LIBRARY_NOT_FOUND, CURLE_FUNCTION_NOT_FOUND, 
    CURLE_ABORTED_BY_CALLBACK, CURLE_BAD_FUNCTION_ARGUMENT, 
    CURLE_BAD_CALLING_ORDER, CURLE_INTERFACE_FAILED, CURLE_BAD_PASSWORD_ENTERED, 
    CURLE_TOO_MANY_REDIRECTS, CURLE_UNKNOWN_TELNET_OPTION, 
    CURLE_TELNET_OPTION_SYNTAX, CURLE_OBSOLETE, CURLE_SSL_PEER_CERTIFICATE, 
    CURLE_GOT_NOTHING, CURLE_SSL_ENGINE_NOTFOUND, CURLE_SSL_ENGINE_SETFAILED, 
    CURLE_SEND_ERROR, CURLE_RECV_ERROR, CURLE_SHARE_IN_USE, 
    CURLE_SSL_CERTPROBLEM, CURLE_SSL_CIPHER, CURLE_SSL_CACERT, 
    CURLE_BAD_CONTENT_ENCODING, CURLE_LDAP_INVALID_URL, CURLE_FILESIZE_EXCEEDED, 
    CURLE_FTP_SSL_FAILED, CURLE_SEND_FAIL_REWIND, CURLE_SSL_ENGINE_INITFAILED, 
    CURLE_LOGIN_DENIED, CURLE_TFTP_NOTFOUND, CURLE_TFTP_PERM, 
    CURLE_TFTP_DISKFULL, CURLE_TFTP_ILLEGAL, CURLE_TFTP_UNKNOWNID, 
    CURLE_TFTP_EXISTS, CURLE_TFTP_NOSUCHUSER, CURLE_CONV_FAILED, 
    CURLE_CONV_REQD, CURL_LAST
  Tcurl_conv_callback* = proc (buffer: cstring, len: int): TCURLcode {.cdecl.}
  Tcurl_ssl_ctx_callback* = proc (curl: PCURL, 
                                 ssl_ctx, userptr: pointer): TCURLcode {.cdecl.}
  Tcurl_proxytype* = enum 
    CURLPROXY_HTTP = 0, CURLPROXY_SOCKS4 = 4, CURLPROXY_SOCKS5 = 5
  Tcurl_ftpssl* = enum 
    CURLFTPSSL_NONE, CURLFTPSSL_TRY, CURLFTPSSL_CONTROL, CURLFTPSSL_ALL, 
    CURLFTPSSL_LAST
  Tcurl_ftpauth* = enum 
    CURLFTPAUTH_DEFAULT, CURLFTPAUTH_SSL, CURLFTPAUTH_TLS, CURLFTPAUTH_LAST
  Tcurl_ftpmethod* = enum 
    CURLFTPMETHOD_DEFAULT, CURLFTPMETHOD_MULTICWD, CURLFTPMETHOD_NOCWD, 
    CURLFTPMETHOD_SINGLECWD, CURLFTPMETHOD_LAST
  TCURLoption* = enum 
    CURLOPT_PORT = 0 + 3,
    CURLOPT_TIMEOUT = 0 + 13, 
    CURLOPT_INFILESIZE = 0 + 14, 
    CURLOPT_LOW_SPEED_LIMIT = 0 + 19, 
    CURLOPT_LOW_SPEED_TIME = 0 + 20, 
    CURLOPT_RESUME_FROM = 0 + 21,
    CURLOPT_CRLF = 0 + 27, 
    CURLOPT_SSLVERSION = 0 + 32, 
    CURLOPT_TIMECONDITION = 0 + 33, 
    CURLOPT_TIMEVALUE = 0 + 34, 
    CURLOPT_VERBOSE = 0 + 41, 
    CURLOPT_HEADER = 0 + 42, 
    CURLOPT_NOPROGRESS = 0 + 43, 
    CURLOPT_NOBODY = 0 + 44, 
    CURLOPT_FAILONERROR = 0 + 45, 
    CURLOPT_UPLOAD = 0 + 46, 
    CURLOPT_POST = 0 + 47, 
    CURLOPT_FTPLISTONLY = 0 + 48, 
    CURLOPT_FTPAPPEND = 0 + 50, 
    CURLOPT_NETRC = 0 + 51, 
    CURLOPT_FOLLOWLOCATION = 0 + 52, 
    CURLOPT_TRANSFERTEXT = 0 + 53, 
    CURLOPT_PUT = 0 + 54, 
    CURLOPT_AUTOREFERER = 0 + 58, 
    CURLOPT_PROXYPORT = 0 + 59, 
    CURLOPT_POSTFIELDSIZE = 0 + 60, 
    CURLOPT_HTTPPROXYTUNNEL = 0 + 61, 
    CURLOPT_SSL_VERIFYPEER = 0 + 64, 
    CURLOPT_MAXREDIRS = 0 + 68, 
    CURLOPT_FILETIME = 0 + 69, 
    CURLOPT_MAXCONNECTS = 0 + 71, 
    CURLOPT_CLOSEPOLICY = 0 + 72, 
    CURLOPT_FRESH_CONNECT = 0 + 74, 
    CURLOPT_FORBID_REUSE = 0 + 75, 
    CURLOPT_CONNECTTIMEOUT = 0 + 78, 
    CURLOPT_HTTPGET = 0 + 80, 
    CURLOPT_SSL_VERIFYHOST = 0 + 81, 
    CURLOPT_HTTP_VERSION = 0 + 84, 
    CURLOPT_FTP_USE_EPSV = 0 + 85, 
    CURLOPT_SSLENGINE_DEFAULT = 0 + 90, 
    CURLOPT_DNS_USE_GLOBAL_CACHE = 0 + 91, 
    CURLOPT_DNS_CACHE_TIMEOUT = 0 + 92, 
    CURLOPT_COOKIESESSION = 0 + 96, 
    CURLOPT_BUFFERSIZE = 0 + 98, 
    CURLOPT_NOSIGNAL = 0 + 99, 
    CURLOPT_PROXYTYPE = 0 + 101, 
    CURLOPT_UNRESTRICTED_AUTH = 0 + 105, 
    CURLOPT_FTP_USE_EPRT = 0 + 106, 
    CURLOPT_HTTPAUTH = 0 + 107, 
    CURLOPT_FTP_CREATE_MISSING_DIRS = 0 + 110, 
    CURLOPT_PROXYAUTH = 0 + 111, 
    CURLOPT_FTP_RESPONSE_TIMEOUT = 0 + 112, 
    CURLOPT_IPRESOLVE = 0 + 113, 
    CURLOPT_MAXFILESIZE = 0 + 114, 
    CURLOPT_FTP_SSL = 0 + 119, 
    CURLOPT_TCP_NODELAY = 0 + 121, 
    CURLOPT_FTPSSLAUTH = 0 + 129, 
    CURLOPT_IGNORE_CONTENT_LENGTH = 0 + 136, 
    CURLOPT_FTP_SKIP_PASV_IP = 0 + 137, 
    CURLOPT_FTP_FILEMETHOD = 0 + 138, 
    CURLOPT_LOCALPORT = 0 + 139, 
    CURLOPT_LOCALPORTRANGE = 0 + 140, 
    CURLOPT_CONNECT_ONLY = 0 + 141, 

    CURLOPT_FILE = 10000 + 1, 
    CURLOPT_URL = 10000 + 2,  
    CURLOPT_PROXY = 10000 + 4, 
    CURLOPT_USERPWD = 10000 + 5, 
    CURLOPT_PROXYUSERPWD = 10000 + 6, 
    CURLOPT_RANGE = 10000 + 7, 
    CURLOPT_INFILE = 10000 + 9, 
    CURLOPT_ERRORBUFFER = 10000 + 10, 
    CURLOPT_POSTFIELDS = 10000 + 15, 
    CURLOPT_REFERER = 10000 + 16, 
    CURLOPT_FTPPORT = 10000 + 17, 
    CURLOPT_USERAGENT = 10000 + 18, 
    CURLOPT_COOKIE = 10000 + 22, 
    CURLOPT_HTTPHEADER = 10000 + 23, 
    CURLOPT_HTTPPOST = 10000 + 24, 
    CURLOPT_SSLCERT = 10000 + 25, 
    CURLOPT_SSLCERTPASSWD = 10000 + 26, 
    CURLOPT_QUOTE = 10000 + 28, 
    CURLOPT_WRITEHEADER = 10000 + 29, 
    CURLOPT_COOKIEFILE = 10000 + 31, 
    CURLOPT_CUSTOMREQUEST = 10000 + 36, 
    CURLOPT_STDERR = 10000 + 37, 
    CURLOPT_POSTQUOTE = 10000 + 39, 
    CURLOPT_WRITEINFO = 10000 + 40, 
    CURLOPT_PROGRESSDATA = 10000 + 57, 
    CURLOPT_INTERFACE = 10000 + 62, 
    CURLOPT_KRB4LEVEL = 10000 + 63,
    CURLOPT_CAINFO = 10000 + 65, 
    CURLOPT_TELNETOPTIONS = 10000 + 70, 
    CURLOPT_RANDOM_FILE = 10000 + 76, 
    CURLOPT_EGDSOCKET = 10000 + 77, 
    CURLOPT_COOKIEJAR = 10000 + 82, 
    CURLOPT_SSL_CIPHER_LIST = 10000 + 83, 
    CURLOPT_SSLCERTTYPE = 10000 + 86, 
    CURLOPT_SSLKEY = 10000 + 87, 
    CURLOPT_SSLKEYTYPE = 10000 + 88, 
    CURLOPT_SSLENGINE = 10000 + 89, 
    CURLOPT_PREQUOTE = 10000 + 93, 
    CURLOPT_DEBUGDATA = 10000 + 95, 
    CURLOPT_CAPATH = 10000 + 97, 
    CURLOPT_SHARE = 10000 + 100, 
    CURLOPT_ENCODING = 10000 + 102, 
    CURLOPT_PRIVATE = 10000 + 103, 
    CURLOPT_HTTP200ALIASES = 10000 + 104, 
    CURLOPT_SSL_CTX_DATA = 10000 + 109, 
    CURLOPT_NETRC_FILE = 10000 + 118, 
    CURLOPT_SOURCE_USERPWD = 10000 + 123, 
    CURLOPT_SOURCE_PREQUOTE = 10000 + 127, 
    CURLOPT_SOURCE_POSTQUOTE = 10000 + 128, 
    CURLOPT_IOCTLDATA = 10000 + 131, 
    CURLOPT_SOURCE_URL = 10000 + 132, 
    CURLOPT_SOURCE_QUOTE = 10000 + 133, 
    CURLOPT_FTP_ACCOUNT = 10000 + 134, 
    CURLOPT_COOKIELIST = 10000 + 135, 
    CURLOPT_FTP_ALTERNATIVE_TO_USER = 10000 + 147, 
    CURLOPT_LASTENTRY = 10000 + 148,
    
    CURLOPT_WRITEFUNCTION = 20000 + 11, 
    CURLOPT_READFUNCTION = 20000 + 12, 
    CURLOPT_PROGRESSFUNCTION = 20000 + 56, 
    CURLOPT_HEADERFUNCTION = 20000 + 79, 
    CURLOPT_DEBUGFUNCTION = 20000 + 94, 
    CURLOPT_SSL_CTX_FUNCTION = 20000 + 108, 
    CURLOPT_IOCTLFUNCTION = 20000 + 130, 
    CURLOPT_CONV_FROM_NETWORK_FUNCTION = 20000 + 142, 
    CURLOPT_CONV_TO_NETWORK_FUNCTION = 20000 + 143, 
    CURLOPT_CONV_FROM_UTF8_FUNCTION = 20000 + 144, 

    CURLOPT_INFILESIZE_LARGE = 30000 + 115, 
    CURLOPT_RESUME_FROM_LARGE = 30000 + 116, 
    CURLOPT_MAXFILESIZE_LARGE = 30000 + 117, 
    CURLOPT_POSTFIELDSIZE_LARGE = 30000 + 120, 
    CURLOPT_MAX_SEND_SPEED_LARGE = 30000 + 145, 
    CURLOPT_MAX_RECV_SPEED_LARGE = 30000 + 146

    
  TCURL_HTTP_VERSION* = enum 
    CURL_HTTP_VERSION_NONE, CURL_HTTP_VERSION_1_0, CURL_HTTP_VERSION_1_1, 
    CURL_HTTP_VERSION_LAST
    
  TCURL_NETRC_OPTION* = enum 
    CURL_NETRC_IGNORED, CURL_NETRC_OPTIONAL, CURL_NETRC_REQUIRED, 
    CURL_NETRC_LAST
    
  TCURL_SSL_VERSION* = enum 
    CURL_SSLVERSION_DEFAULT, CURL_SSLVERSION_TLSv1, CURL_SSLVERSION_SSLv2, 
    CURL_SSLVERSION_SSLv3, CURL_SSLVERSION_LAST
  
  TCURL_TIMECOND* = enum 
    CURL_TIMECOND_NONE, CURL_TIMECOND_IFMODSINCE, CURL_TIMECOND_IFUNMODSINCE, 
    CURL_TIMECOND_LASTMOD, CURL_TIMECOND_LAST
  
  TCURLformoption* = enum 
    CURLFORM_NOTHING, CURLFORM_COPYNAME, CURLFORM_PTRNAME, CURLFORM_NAMELENGTH, 
    CURLFORM_COPYCONTENTS, CURLFORM_PTRCONTENTS, CURLFORM_CONTENTSLENGTH, 
    CURLFORM_FILECONTENT, CURLFORM_ARRAY, CURLFORM_OBSOLETE, CURLFORM_FILE, 
    CURLFORM_BUFFER, CURLFORM_BUFFERPTR, CURLFORM_BUFFERLENGTH, 
    CURLFORM_CONTENTTYPE, CURLFORM_CONTENTHEADER, CURLFORM_FILENAME, 
    CURLFORM_END, CURLFORM_OBSOLETE2, CURLFORM_LASTENTRY
  
  Tcurl_forms* {.pure, final.} = object 
    option*: TCURLformoption
    value*: cstring

  TCURLFORMcode* = enum 
    CURL_FORMADD_OK, CURL_FORMADD_MEMORY, CURL_FORMADD_OPTION_TWICE, 
    CURL_FORMADD_NULL, CURL_FORMADD_UNKNOWN_OPTION, CURL_FORMADD_INCOMPLETE, 
    CURL_FORMADD_ILLEGAL_ARRAY, CURL_FORMADD_DISABLED, CURL_FORMADD_LAST

  Tcurl_formget_callback* = proc (arg: pointer, buf: cstring, 
                                 length: int): int {.cdecl.}
  Tcurl_slist* {.pure, final.} = object 
    data*: cstring
    next*: Pcurl_slist

  TCURLINFO* = enum 
    CURLINFO_NONE = 0, 
    CURLINFO_LASTONE = 30,
    CURLINFO_EFFECTIVE_URL = 0x00100000 + 1, 
    CURLINFO_CONTENT_TYPE = 0x00100000 + 18, 
    CURLINFO_PRIVATE = 0x00100000 + 21, 
    CURLINFO_FTP_ENTRY_PATH = 0x00100000 + 30,

    CURLINFO_RESPONSE_CODE = 0x00200000 + 2, 
    CURLINFO_HEADER_SIZE = 0x00200000 + 11, 
    CURLINFO_REQUEST_SIZE = 0x00200000 + 12, 
    CURLINFO_SSL_VERIFYRESULT = 0x00200000 + 13, 
    CURLINFO_FILETIME = 0x00200000 + 14, 
    CURLINFO_REDIRECT_COUNT = 0x00200000 + 20, 
    CURLINFO_HTTP_CONNECTCODE = 0x00200000 + 22, 
    CURLINFO_HTTPAUTH_AVAIL = 0x00200000 + 23, 
    CURLINFO_PROXYAUTH_AVAIL = 0x00200000 + 24, 
    CURLINFO_OS_ERRNO = 0x00200000 + 25, 
    CURLINFO_NUM_CONNECTS = 0x00200000 + 26, 
    CURLINFO_LASTSOCKET = 0x00200000 + 29, 
    
    CURLINFO_TOTAL_TIME = 0x00300000 + 3, 
    CURLINFO_NAMELOOKUP_TIME = 0x00300000 + 4, 
    CURLINFO_CONNECT_TIME = 0x00300000 + 5, 
    CURLINFO_PRETRANSFER_TIME = 0x00300000 + 6, 
    CURLINFO_SIZE_UPLOAD = 0x00300000 + 7, 
    CURLINFO_SIZE_DOWNLOAD = 0x00300000 + 8, 
    CURLINFO_SPEED_DOWNLOAD = 0x00300000 + 9, 
    CURLINFO_SPEED_UPLOAD = 0x00300000 + 10, 
    CURLINFO_CONTENT_LENGTH_DOWNLOAD = 0x00300000 + 15, 
    CURLINFO_CONTENT_LENGTH_UPLOAD = 0x00300000 + 16, 
    CURLINFO_STARTTRANSFER_TIME = 0x00300000 + 17, 
    CURLINFO_REDIRECT_TIME = 0x00300000 + 19, 

    CURLINFO_SSL_ENGINES = 0x00400000 + 27, 
    CURLINFO_COOKIELIST = 0x00400000 + 28

  Tcurl_closepolicy* = enum 
    CURLCLOSEPOLICY_NONE, CURLCLOSEPOLICY_OLDEST, 
    CURLCLOSEPOLICY_LEAST_RECENTLY_USED, CURLCLOSEPOLICY_LEAST_TRAFFIC, 
    CURLCLOSEPOLICY_SLOWEST, CURLCLOSEPOLICY_CALLBACK, CURLCLOSEPOLICY_LAST
  Tcurl_lock_data* = enum 
    CURL_LOCK_DATA_NONE = 0, CURL_LOCK_DATA_SHARE, CURL_LOCK_DATA_COOKIE, 
    CURL_LOCK_DATA_DNS, CURL_LOCK_DATA_SSL_SESSION, CURL_LOCK_DATA_CONNECT, 
    CURL_LOCK_DATA_LAST
  Tcurl_lock_access* = enum 
    CURL_LOCK_ACCESS_NONE = 0, CURL_LOCK_ACCESS_SHARED = 1, 
    CURL_LOCK_ACCESS_SINGLE = 2, CURL_LOCK_ACCESS_LAST
  
  Tcurl_lock_function* = proc (handle: PCURL, data: Tcurl_lock_data, 
                              locktype: Tcurl_lock_access, 
                              userptr: pointer) {.cdecl.}
  Tcurl_unlock_function* = proc (handle: PCURL, data: Tcurl_lock_data, 
                                userptr: pointer) {.cdecl.}
  TCURLSH* = pointer
  TCURLSHcode* = enum 
    CURLSHE_OK, CURLSHE_BAD_OPTION, CURLSHE_IN_USE, CURLSHE_INVALID, 
    CURLSHE_NOMEM, CURLSHE_LAST
  
  TCURLSHoption* = enum 
    CURLSHOPT_NONE, CURLSHOPT_SHARE, CURLSHOPT_UNSHARE, CURLSHOPT_LOCKFUNC, 
    CURLSHOPT_UNLOCKFUNC, CURLSHOPT_USERDATA, CURLSHOPT_LAST
  
  TCURLversion* = enum 
    CURLVERSION_FIRST, CURLVERSION_SECOND, CURLVERSION_THIRD, CURLVERSION_LAST
  
  Tcurl_version_info_data* {.pure, final.} = object 
    age*: TCURLversion
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

  TCURLM* = pointer
  Tcurl_socket* = int32
  TCURLMcode* = enum 
    CURLM_CALL_MULTI_PERFORM = -1, 
    CURLM_OK = 0, 
    CURLM_BAD_HANDLE, 
    CURLM_BAD_EASY_HANDLE, 
    CURLM_OUT_OF_MEMORY, 
    CURLM_INTERNAL_ERROR, 
    CURLM_BAD_SOCKET, 
    CURLM_UNKNOWN_OPTION, 
    CURLM_LAST
    
  TCURLMSGEnum* = enum 
    CURLMSG_NONE, CURLMSG_DONE, CURLMSG_LAST
  TCURLMsg* {.pure, final.} = object 
    msg*: TCURLMSGEnum
    easy_handle*: PCURL
    whatever*: Pointer        #data : record
                              #      case longint of
                              #        0 : ( whatever : pointer );
                              #        1 : ( result : CURLcode );
                              #    end;
  
  Tcurl_socket_callback* = proc (easy: PCURL, s: Tcurl_socket, what: int32, 
                                 userp, socketp: pointer): int32 {.cdecl.}
  TCURLMoption* = enum 
    CURLMOPT_SOCKETDATA = 10000 + 2, 
    CURLMOPT_LASTENTRY = 10000 + 3,
    CURLMOPT_SOCKETFUNCTION = 20000 + 1
    
const 
  CURLOPT_SSLKEYPASSWD* = CURLOPT_SSLCERTPASSWD

  CURLAUTH_ANY* = not (0)
  CURLAUTH_BASIC* = 1 shl 0
  CURLAUTH_ANYSAFE* = not (CURLAUTH_BASIC)
  CURLAUTH_DIGEST* = 1 shl 1
  CURLAUTH_GSSNEGOTIATE* = 1 shl 2
  CURLAUTH_NONE* = 0
  CURLAUTH_NTLM* = 1 shl 3
  CURLE_ALREADY_COMPLETE* = 99999
  CURLE_FTP_BAD_DOWNLOAD_RESUME* = CURLE_BAD_DOWNLOAD_RESUME
  CURLE_FTP_PARTIAL_FILE* = CURLE_PARTIAL_FILE
  CURLE_HTTP_NOT_FOUND* = CURLE_HTTP_RETURNED_ERROR
  CURLE_HTTP_PORT_FAILED* = CURLE_INTERFACE_FAILED
  CURLE_OPERATION_TIMEDOUT* = CURLE_OPERATION_TIMEOUTED
  CURL_ERROR_SIZE* = 256
  CURL_FORMAT_OFF_T* = "%ld"
  CURL_GLOBAL_NOTHING* = 0
  CURL_GLOBAL_SSL* = 1 shl 0
  CURL_GLOBAL_WIN32* = 1 shl 1
  CURL_GLOBAL_ALL* = CURL_GLOBAL_SSL or CURL_GLOBAL_WIN32
  CURL_GLOBAL_DEFAULT* = CURL_GLOBAL_ALL
  CURLINFO_DOUBLE* = 0x00300000
  CURLINFO_HTTP_CODE* = CURLINFO_RESPONSE_CODE
  CURLINFO_LONG* = 0x00200000
  CURLINFO_MASK* = 0x000FFFFF
  CURLINFO_SLIST* = 0x00400000
  CURLINFO_STRING* = 0x00100000
  CURLINFO_TYPEMASK* = 0x00F00000
  CURL_IPRESOLVE_V4* = 1
  CURL_IPRESOLVE_V6* = 2
  CURL_IPRESOLVE_WHATEVER* = 0
  CURL_MAX_WRITE_SIZE* = 16384
  CURLM_CALL_MULTI_SOCKET* = CURLM_CALL_MULTI_PERFORM
  CURLOPT_CLOSEFUNCTION* = - (5)
  CURLOPT_FTPASCII* = CURLOPT_TRANSFERTEXT
  CURLOPT_HEADERDATA* = CURLOPT_WRITEHEADER
  CURLOPT_HTTPREQUEST* = - (1)
  CURLOPT_MUTE* = - (2)
  CURLOPT_PASSWDDATA* = - (4)
  CURLOPT_PASSWDFUNCTION* = - (3)
  CURLOPT_PASV_HOST* = - (9)
  CURLOPT_READDATA* = CURLOPT_INFILE
  CURLOPT_SOURCE_HOST* = - (6)
  CURLOPT_SOURCE_PATH* = - (7)
  CURLOPT_SOURCE_PORT* = - (8)
  CURLOPTTYPE_FUNCTIONPOINT* = 20000
  CURLOPTTYPE_LONG* = 0
  CURLOPTTYPE_OBJECTPOINT* = 10000
  CURLOPTTYPE_OFF_T* = 30000
  CURLOPT_WRITEDATA* = CURLOPT_FILE
  CURL_POLL_IN* = 1
  CURL_POLL_INOUT* = 3
  CURL_POLL_NONE* = 0
  CURL_POLL_OUT* = 2
  CURL_POLL_REMOVE* = 4
  CURL_READFUNC_ABORT* = 0x10000000
  CURL_SOCKET_BAD* = - (1)
  CURL_SOCKET_TIMEOUT* = CURL_SOCKET_BAD
  CURL_VERSION_ASYNCHDNS* = 1 shl 7
  CURL_VERSION_CONV* = 1 shl 12
  CURL_VERSION_DEBUG* = 1 shl 6
  CURL_VERSION_GSSNEGOTIATE* = 1 shl 5
  CURL_VERSION_IDN* = 1 shl 10
  CURL_VERSION_IPV6* = 1 shl 0
  CURL_VERSION_KERBEROS4* = 1 shl 1
  CURL_VERSION_LARGEFILE* = 1 shl 9
  CURL_VERSION_LIBZ* = 1 shl 3
  CURLVERSION_NOW* = CURLVERSION_THIRD
  CURL_VERSION_NTLM* = 1 shl 4
  CURL_VERSION_SPNEGO* = 1 shl 8
  CURL_VERSION_SSL* = 1 shl 2
  CURL_VERSION_SSPI* = 1 shl 11
  FILE_OFFSET_BITS* = 0
  FILESIZEBITS* = 0
  FUNCTIONPOINT* = CURLOPTTYPE_FUNCTIONPOINT
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

proc curl_strequal*(s1, s2: cstring): int32{.cdecl, 
    dynlib: libname, importc: "curl_strequal".}
proc curl_strnequal*(s1, s2: cstring, n: int): int32 {.cdecl, 
    dynlib: libname, importc: "curl_strnequal".}
proc curl_formadd*(httppost, last_post: PPcurl_httppost): TCURLFORMcode {.
    cdecl, varargs, dynlib: libname, importc: "curl_formadd".}

proc curl_formget*(form: Pcurl_httppost, arg: pointer, 
                   append: Tcurl_formget_callback): int32 {.cdecl, 
    dynlib: libname, importc: "curl_formget".}
proc curl_formfree*(form: Pcurl_httppost){.cdecl, dynlib: libname, 
    importc: "curl_formfree".}
proc curl_getenv*(variable: cstring): cstring{.cdecl, dynlib: libname, 
    importc: "curl_getenv".}
proc curl_version*(): cstring{.cdecl, dynlib: libname, importc: "curl_version".}
proc curl_easy_escape*(handle: PCURL, str: cstring, len: int32): cstring{.cdecl, 
    dynlib: libname, importc: "curl_easy_escape".}
proc curl_escape*(str: cstring, len: int32): cstring{.cdecl, 
    dynlib: libname, importc: "curl_escape".}
proc curl_easy_unescape*(handle: PCURL, str: cstring, len: int32, 
                         outlength: var int32): cstring{.cdecl, 
    dynlib: libname, importc: "curl_easy_unescape".}
proc curl_unescape*(str: cstring, len: int32): cstring{.cdecl, 
    dynlib: libname, importc: "curl_unescape".}
proc curl_free*(p: pointer){.cdecl, dynlib: libname, 
                             importc: "curl_free".}
proc curl_global_init*(flags: int32): TCURLcode {.cdecl, dynlib: libname, 
    importc: "curl_global_init".}
proc curl_global_init_mem*(flags: int32, m: Tcurl_malloc_callback, 
                           f: Tcurl_free_callback, r: Tcurl_realloc_callback, 
                           s: Tcurl_strdup_callback, 
                           c: Tcurl_calloc_callback): TCURLcode {.
    cdecl, dynlib: libname, importc: "curl_global_init_mem".}
proc curl_global_cleanup*() {.cdecl, dynlib: libname, 
                              importc: "curl_global_cleanup".}
proc curl_slist_append*(curl_slist: Pcurl_slist, P: cstring): Pcurl_slist {.
    cdecl, dynlib: libname, importc: "curl_slist_append".}
proc curl_slist_free_all*(para1: Pcurl_slist) {.cdecl, dynlib: libname, 
    importc: "curl_slist_free_all".}
proc curl_getdate*(p: cstring, unused: ptr TTime): TTime {.cdecl, 
    dynlib: libname, importc: "curl_getdate".}
proc curl_share_init*(): PCURLSH{.cdecl, dynlib: libname, 
                                  importc: "curl_share_init".}
proc curl_share_setopt*(para1: PCURLSH, option: TCURLSHoption): TCURLSHcode {.
    cdecl, varargs, dynlib: libname, importc: "curl_share_setopt".}

proc curl_share_cleanup*(para1: PCURLSH): TCURLSHcode {.cdecl, 
    dynlib: libname, importc: "curl_share_cleanup".}
proc curl_version_info*(para1: TCURLversion): Pcurl_version_info_data{.cdecl, 
    dynlib: libname, importc: "curl_version_info".}
proc curl_easy_strerror*(para1: TCURLcode): cstring {.cdecl, 
    dynlib: libname, importc: "curl_easy_strerror".}
proc curl_share_strerror*(para1: TCURLSHcode): cstring {.cdecl, 
    dynlib: libname, importc: "curl_share_strerror".}
proc curl_easy_init*(): PCURL {.cdecl, dynlib: libname, 
                               importc: "curl_easy_init".}
proc curl_easy_setopt*(curl: PCURL, option: TCURLoption): TCURLcode {.cdecl, 
    varargs, dynlib: libname, importc: "curl_easy_setopt".}

proc curl_easy_perform*(curl: PCURL): TCURLcode {.cdecl, dynlib: libname, 
    importc: "curl_easy_perform".}
proc curl_easy_cleanup*(curl: PCURL) {.cdecl, dynlib: libname, 
                                       importc: "curl_easy_cleanup".}
proc curl_easy_getinfo*(curl: PCURL, info: TCURLINFO): TCURLcode {.
    cdecl, varargs, dynlib: libname, importc: "curl_easy_getinfo".}

proc curl_easy_duphandle*(curl: PCURL): PCURL {.cdecl, dynlib: libname, 
    importc: "curl_easy_duphandle".}
proc curl_easy_reset*(curl: PCURL) {.cdecl, dynlib: libname, 
                                     importc: "curl_easy_reset".}
proc curl_multi_init*(): PCURLM {.cdecl, dynlib: libname, 
                                  importc: "curl_multi_init".}
proc curl_multi_add_handle*(multi_handle: PCURLM, 
                            curl_handle: PCURL): TCURLMcode {.
    cdecl, dynlib: libname, importc: "curl_multi_add_handle".}
proc curl_multi_remove_handle*(multi_handle: PCURLM, 
                               curl_handle: PCURL): TCURLMcode {.
    cdecl, dynlib: libname, importc: "curl_multi_remove_handle".}
proc curl_multi_fdset*(multi_handle: PCURLM, read_fd_set: Pfd_set, 
                       write_fd_set: Pfd_set, exc_fd_set: Pfd_set, 
                       max_fd: var int32): TCURLMcode {.cdecl, 
    dynlib: libname, importc: "curl_multi_fdset".}
proc curl_multi_perform*(multi_handle: PCURLM, 
                         running_handles: var int32): TCURLMcode {.
    cdecl, dynlib: libname, importc: "curl_multi_perform".}
proc curl_multi_cleanup*(multi_handle: PCURLM): TCURLMcode {.cdecl, 
    dynlib: libname, importc: "curl_multi_cleanup".}
proc curl_multi_info_read*(multi_handle: PCURLM, 
                           msgs_in_queue: var int32): PCURLMsg {.
    cdecl, dynlib: libname, importc: "curl_multi_info_read".}
proc curl_multi_strerror*(para1: TCURLMcode): cstring {.cdecl, 
    dynlib: libname, importc: "curl_multi_strerror".}
proc curl_multi_socket*(multi_handle: PCURLM, s: Tcurl_socket, 
                        running_handles: var int32): TCURLMcode {.cdecl, 
    dynlib: libname, importc: "curl_multi_socket".}
proc curl_multi_socket_all*(multi_handle: PCURLM, 
                            running_handles: var int32): TCURLMcode {.
    cdecl, dynlib: libname, importc: "curl_multi_socket_all".}
proc curl_multi_timeout*(multi_handle: PCURLM, milliseconds: var int32): TCURLMcode{.
    cdecl, dynlib: libname, importc: "curl_multi_timeout".}
proc curl_multi_setopt*(multi_handle: PCURLM, option: TCURLMoption): TCURLMcode{.
    cdecl, varargs, dynlib: libname, importc: "curl_multi_setopt".}

proc curl_multi_assign*(multi_handle: PCURLM, sockfd: Tcurl_socket, 
                        sockp: pointer): TCURLMcode {.cdecl, 
    dynlib: libname, importc: "curl_multi_assign".}


