#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## OpenSSL support
##
## When OpenSSL is dynamically linked, the wrapper provides partial forward and backward
## compatibility for OpenSSL versions above and below 1.1.0
##
## OpenSSL can also be statically linked using ``--dynlibOverride:ssl`` for OpenSSL >= 1.1.0.
## If you want to statically link against OpenSSL 1.0.x, you now have to
## define the ``openssl10`` symbol via ``-d:openssl10``.
##
## Build and test examples:
##
## .. code-block::
##   ./bin/nim c -d:ssl -p:. -r tests/untestable/tssl.nim
##   ./bin/nim c -d:ssl -p:. --dynlibOverride:ssl --passL:-lcrypto --passL:-lssl -r tests/untestable/tssl.nim

{.deadCodeElim: on.}  # dce option deprecated

const useWinVersion = defined(Windows) or defined(nimdoc)

when useWinVersion:
  when not defined(nimOldDlls) and defined(cpu64):
    const
      DLLSSLName* = "(libssl-1_1-x64|ssleay64|libssl64).dll"
      DLLUtilName* = "(libcrypto-1_1-x64|libeay64).dll"
  else:
    const
      DLLSSLName* = "(libssl-1_1|ssleay32|libssl32).dll"
      DLLUtilName* =  "(libcrypto-1_1|libeay32).dll"

  from winlean import SocketHandle
else:
  const versions = "(.1.1|.38|.39|.41|.43|.44|.45|.10|.1.0.2|.1.0.1|.1.0.0|.0.9.9|.0.9.8|)"

  when defined(macosx):
    const
      DLLSSLName* = "libssl" & versions & ".dylib"
      DLLUtilName* = "libcrypto" & versions & ".dylib"
  elif defined(genode):
    const
      DLLSSLName* = "libssl.lib.so"
      DLLUtilName* = "libcrypto.lib.so"
  else:
    const
      DLLSSLName* = "libssl.so" & versions
      DLLUtilName* = "libcrypto.so" & versions
  from posix import SocketHandle

import dynlib

type
  SslStruct {.final, pure.} = object
  SslPtr* = ptr SslStruct
  PSslPtr* = ptr SslPtr
  SslCtx* = SslPtr
  PSSL_METHOD* = SslPtr
  PX509* = SslPtr
  PX509_NAME* = SslPtr
  PEVP_MD* = SslPtr
  PBIO_METHOD* = SslPtr
  BIO* = SslPtr
  EVP_PKEY* = SslPtr
  PRSA* = SslPtr
  PASN1_UTCTIME* = SslPtr
  PASN1_cInt* = SslPtr
  PPasswdCb* = SslPtr
  PFunction* = proc () {.cdecl.}
  DES_cblock* = array[0..7, int8]
  PDES_cblock* = ptr DES_cblock
  des_ks_struct*{.final.} = object
    ks*: DES_cblock
    weak_key*: cInt

  des_key_schedule* = array[1..16, des_ks_struct]

  pem_password_cb* = proc(buf: cstring, size, rwflag: cint, userdata: pointer): cint {.cdecl.}

{.deprecated: [PSSL: SslPtr, PSSL_CTX: SslCtx, PBIO: BIO].}

const
  SSL_SENT_SHUTDOWN* = 1
  SSL_RECEIVED_SHUTDOWN* = 2
  EVP_MAX_MD_SIZE* = 16 + 20
  SSL_ERROR_NONE* = 0
  SSL_ERROR_SSL* = 1
  SSL_ERROR_WANT_READ* = 2
  SSL_ERROR_WANT_WRITE* = 3
  SSL_ERROR_WANT_X509_LOOKUP* = 4
  SSL_ERROR_SYSCALL* = 5      #look at error stack/return value/errno
  SSL_ERROR_ZERO_RETURN* = 6
  SSL_ERROR_WANT_CONNECT* = 7
  SSL_ERROR_WANT_ACCEPT* = 8
  SSL_CTRL_NEED_TMP_RSA* = 1
  SSL_CTRL_SET_TMP_RSA* = 2
  SSL_CTRL_SET_TMP_DH* = 3
  SSL_CTRL_SET_TMP_ECDH* = 4
  SSL_CTRL_SET_TMP_RSA_CB* = 5
  SSL_CTRL_SET_TMP_DH_CB* = 6
  SSL_CTRL_SET_TMP_ECDH_CB* = 7
  SSL_CTRL_GET_SESSION_REUSED* = 8
  SSL_CTRL_GET_CLIENT_CERT_REQUEST* = 9
  SSL_CTRL_GET_NUM_RENEGOTIATIONS* = 10
  SSL_CTRL_CLEAR_NUM_RENEGOTIATIONS* = 11
  SSL_CTRL_GET_TOTAL_RENEGOTIATIONS* = 12
  SSL_CTRL_GET_FLAGS* = 13
  SSL_CTRL_EXTRA_CHAIN_CERT* = 14
  SSL_CTRL_SET_MSG_CALLBACK* = 15
  SSL_CTRL_SET_MSG_CALLBACK_ARG* = 16 # only applies to datagram connections
  SSL_CTRL_SET_MTU* = 17      # Stats
  SSL_CTRL_SESS_NUMBER* = 20
  SSL_CTRL_SESS_CONNECT* = 21
  SSL_CTRL_SESS_CONNECT_GOOD* = 22
  SSL_CTRL_SESS_CONNECT_RENEGOTIATE* = 23
  SSL_CTRL_SESS_ACCEPT* = 24
  SSL_CTRL_SESS_ACCEPT_GOOD* = 25
  SSL_CTRL_SESS_ACCEPT_RENEGOTIATE* = 26
  SSL_CTRL_SESS_HIT* = 27
  SSL_CTRL_SESS_CB_HIT* = 28
  SSL_CTRL_SESS_MISSES* = 29
  SSL_CTRL_SESS_TIMEOUTS* = 30
  SSL_CTRL_SESS_CACHE_FULL* = 31
  SSL_CTRL_OPTIONS* = 32
  SSL_CTRL_MODE* = 33
  SSL_CTRL_GET_READ_AHEAD* = 40
  SSL_CTRL_SET_READ_AHEAD* = 41
  SSL_CTRL_SET_SESS_CACHE_SIZE* = 42
  SSL_CTRL_GET_SESS_CACHE_SIZE* = 43
  SSL_CTRL_SET_SESS_CACHE_MODE* = 44
  SSL_CTRL_GET_SESS_CACHE_MODE* = 45
  SSL_CTRL_GET_MAX_CERT_LIST* = 50
  SSL_CTRL_SET_MAX_CERT_LIST* = 51 #* Allow SSL_write(..., n) to return r with 0 < r < n (i.e. report success
                                   # * when just a single record has been written): *
  SSL_CTRL_SET_TLSEXT_SERVERNAME_CB = 53
  SSL_CTRL_SET_TLSEXT_SERVERNAME_ARG = 54
  SSL_CTRL_SET_TLSEXT_HOSTNAME = 55
  TLSEXT_NAMETYPE_host_name* = 0
  SSL_TLSEXT_ERR_OK* = 0
  SSL_TLSEXT_ERR_ALERT_WARNING* = 1
  SSL_TLSEXT_ERR_ALERT_FATAL* = 2
  SSL_TLSEXT_ERR_NOACK* = 3
  SSL_MODE_ENABLE_PARTIAL_WRITE* = 1 #* Make it possible to retry SSL_write() with changed buffer location
                                     # * (buffer contents must stay the same!); this is not the default to avoid
                                     # * the misconception that non-blocking SSL_write() behaves like
                                     # * non-blocking write(): *
  SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER* = 2 #* Never bother the application with retries if the transport
                                           # * is blocking: *
  SSL_MODE_AUTO_RETRY* = 4    #* Don't attempt to automatically build certificate chain *
  SSL_MODE_NO_AUTO_CHAIN* = 8
  SSL_OP_NO_SSLv2* = 0x01000000
  SSL_OP_NO_SSLv3* = 0x02000000
  SSL_OP_NO_TLSv1* = 0x04000000
  SSL_OP_NO_TLSv1_1* = 0x08000000
  SSL_OP_ALL* = 0x000FFFFF
  SSL_VERIFY_NONE* = 0x00000000
  SSL_VERIFY_PEER* = 0x00000001
  OPENSSL_DES_DECRYPT* = 0
  OPENSSL_DES_ENCRYPT* = 1
  X509_V_OK* = 0
  X509_V_ILLEGAL* = 1
  X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT* = 2
  X509_V_ERR_UNABLE_TO_GET_CRL* = 3
  X509_V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE* = 4
  X509_V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE* = 5
  X509_V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY* = 6
  X509_V_ERR_CERT_SIGNATURE_FAILURE* = 7
  X509_V_ERR_CRL_SIGNATURE_FAILURE* = 8
  X509_V_ERR_CERT_NOT_YET_VALID* = 9
  X509_V_ERR_CERT_HAS_EXPIRED* = 10
  X509_V_ERR_CRL_NOT_YET_VALID* = 11
  X509_V_ERR_CRL_HAS_EXPIRED* = 12
  X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD* = 13
  X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD* = 14
  X509_V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD* = 15
  X509_V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD* = 16
  X509_V_ERR_OUT_OF_MEM* = 17
  X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT* = 18
  X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN* = 19
  X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY* = 20
  X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE* = 21
  X509_V_ERR_CERT_CHAIN_TOO_LONG* = 22
  X509_V_ERR_CERT_REVOKED* = 23
  X509_V_ERR_INVALID_CA* = 24
  X509_V_ERR_PATH_LENGTH_EXCEEDED* = 25
  X509_V_ERR_INVALID_PURPOSE* = 26
  X509_V_ERR_CERT_UNTRUSTED* = 27
  X509_V_ERR_CERT_REJECTED* = 28 #These are 'informational' when looking for issuer cert
  X509_V_ERR_SUBJECT_ISSUER_MISMATCH* = 29
  X509_V_ERR_AKID_SKID_MISMATCH* = 30
  X509_V_ERR_AKID_ISSUER_SERIAL_MISMATCH* = 31
  X509_V_ERR_KEYUSAGE_NO_CERTSIGN* = 32
  X509_V_ERR_UNABLE_TO_GET_CRL_ISSUER* = 33
  X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION* = 34 #The application is not happy
  X509_V_ERR_APPLICATION_VERIFICATION* = 50
  SSL_FILETYPE_ASN1* = 2
  SSL_FILETYPE_PEM* = 1
  EVP_PKEY_RSA* = 6           # libssl.dll

  BIO_C_SET_CONNECT = 100
  BIO_C_DO_STATE_MACHINE = 101
  BIO_C_GET_SSL = 110

proc TLSv1_method*(): PSSL_METHOD{.cdecl, dynlib: DLLSSLName, importc.}

# TLS_method(), TLS_server_method(), TLS_client_method() are introduced in 1.1.0
# and support SSLv3, TLSv1, TLSv1.1 and TLSv1.2
# SSLv23_method(), SSLv23_server_method(), SSLv23_client_method() are removed in 1.1.0

when compileOption("dynlibOverride", "ssl"):
  # Static linking

  when defined(openssl10):
    proc SSL_library_init*(): cint {.cdecl, dynlib: DLLSSLName, importc, discardable.}
    proc SSL_load_error_strings*() {.cdecl, dynlib: DLLSSLName, importc.}
    proc SSLv23_method*(): PSSL_METHOD {.cdecl, dynlib: DLLSSLName, importc.}
  else:
    proc OPENSSL_init_ssl*(opts: uint64, settings: uint8): cint {.cdecl, dynlib: DLLSSLName, importc, discardable.}
    proc SSL_library_init*(): cint {.discardable.} =
      ## Initialize SSL using OPENSSL_init_ssl for OpenSSL >= 1.1.0
      return OPENSSL_init_ssl(0.uint64, 0.uint8)

    proc TLS_method*(): PSSL_METHOD {.cdecl, dynlib: DLLSSLName, importc.}
    proc SSLv23_method*(): PSSL_METHOD =
      TLS_method()

    proc OpenSSL_version_num(): culong {.cdecl, dynlib: DLLSSLName, importc.}

    proc getOpenSSLVersion*(): culong =
      ## Return OpenSSL version as unsigned long
      OpenSSL_version_num()

    proc SSL_load_error_strings*() =
      ## Removed from OpenSSL 1.1.0
      # This proc prevents breaking existing code calling SslLoadErrorStrings
      # Static linking against OpenSSL < 1.1.0 is not supported
      discard

  template OpenSSL_add_all_algorithms*() = discard

  proc SSLv23_client_method*(): PSSL_METHOD {.cdecl, dynlib: DLLSSLName, importc.}
  proc SSLv2_method*(): PSSL_METHOD {.cdecl, dynlib: DLLSSLName, importc.}
  proc SSLv3_method*(): PSSL_METHOD {.cdecl, dynlib: DLLSSLName, importc.}

else:
  # Here we're trying to stay compatible with openssl 1.0.* and 1.1.*. Some
  # symbols are loaded dynamically and we don't use them if not found.
  proc thisModule(): LibHandle {.inline.} =
    var thisMod {.global.}: LibHandle
    if thisMod.isNil: thisMod = loadLib()
    result = thisMod

  proc sslModule(): LibHandle {.inline.} =
    var sslMod {.global.}: LibHandle
    if sslMod.isNil: sslMod = loadLibPattern(DLLSSLName)
    result = sslMod

  proc sslSym(name: string): pointer =
    var dl = thisModule()
    if not dl.isNil:
      result = symAddr(dl, name)
    if result.isNil:
      dl = sslModule()
      if not dl.isNil:
        result = symAddr(dl, name)

  proc loadPSSLMethod(method1, method2: string): PSSL_METHOD =
    ## Load <method1> from OpenSSL if available, otherwise <method2>
    let m1 = cast[proc(): PSSL_METHOD {.cdecl, gcsafe.}](sslSym(method1))
    if not m1.isNil:
      return m1()
    cast[proc(): PSSL_METHOD {.cdecl, gcsafe.}](sslSym(method2))()

  proc SSL_library_init*(): cint {.discardable.} =
    ## Initialize SSL using OPENSSL_init_ssl for OpenSSL >= 1.1.0 otherwise
    ## SSL_library_init
    let theProc = cast[proc(opts: uint64, settings: uint8): cint {.cdecl.}](sslSym("OPENSSL_init_ssl"))
    if not theProc.isNil:
      return theProc(0, 0)
    let olderProc = cast[proc(): cint {.cdecl.}](sslSym("SSL_library_init"))
    if not olderProc.isNil: result = olderProc()

  proc SSL_load_error_strings*() =
    let theProc = cast[proc() {.cdecl.}](sslSym("SSL_load_error_strings"))
    if not theProc.isNil: theProc()

  proc SSLv23_client_method*(): PSSL_METHOD =
    loadPSSLMethod("SSLv23_client_method", "TLS_client_method")

  proc SSLv23_method*(): PSSL_METHOD =
    loadPSSLMethod("SSLv23_method", "TLS_method")

  proc SSLv2_method*(): PSSL_METHOD =
    loadPSSLMethod("SSLv2_method", "TLS_method")

  proc SSLv3_method*(): PSSL_METHOD =
    loadPSSLMethod("SSLv3_method", "TLS_method")

  proc TLS_method*(): PSSL_METHOD =
    loadPSSLMethod("TLS_method", "SSLv23_method")

  proc TLS_client_method*(): PSSL_METHOD =
    loadPSSLMethod("TLS_client_method", "SSLv23_client_method")

  proc TLS_server_method*(): PSSL_METHOD =
    loadPSSLMethod("TLS_server_method", "SSLv23_server_method")

  proc OpenSSL_add_all_algorithms*() =
    let theProc = cast[proc() {.cdecl.}](sslSym("OPENSSL_add_all_algorithms_conf"))
    if not theProc.isNil: theProc()

  proc getOpenSSLVersion*(): culong =
    ## Return OpenSSL version as unsigned long or 0 if not available
    let theProc = cast[proc(): culong {.cdecl.}](sslSym("OpenSSL_version_num"))
    result =
      if theProc.isNil: 0.culong
      else: theProc()

proc ERR_load_BIO_strings*(){.cdecl, dynlib: DLLUtilName, importc.}

proc SSL_new*(context: SslCtx): SslPtr{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_free*(ssl: SslPtr){.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_get_SSL_CTX*(ssl: SslPtr): SslCtx {.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_CTX_new*(meth: PSSL_METHOD): SslCtx{.cdecl,
    dynlib: DLLSSLName, importc.}
proc SSL_CTX_load_verify_locations*(ctx: SslCtx, CAfile: cstring,
    CApath: cstring): cInt{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_CTX_free*(arg0: SslCtx){.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_CTX_set_verify*(s: SslCtx, mode: int, cb: proc (a: int, b: pointer): int {.cdecl.}){.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_get_verify_result*(ssl: SslPtr): int{.cdecl,
    dynlib: DLLSSLName, importc.}

proc SSL_CTX_set_cipher_list*(s: SslCtx, ciphers: cstring): cint{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_CTX_use_certificate_file*(ctx: SslCtx, filename: cstring, typ: cInt): cInt{.
    stdcall, dynlib: DLLSSLName, importc.}
proc SSL_CTX_use_certificate_chain_file*(ctx: SslCtx, filename: cstring): cInt{.
    stdcall, dynlib: DLLSSLName, importc.}
proc SSL_CTX_use_PrivateKey_file*(ctx: SslCtx,
    filename: cstring, typ: cInt): cInt{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_CTX_check_private_key*(ctx: SslCtx): cInt{.cdecl, dynlib: DLLSSLName,
    importc.}

proc SSL_CTX_get_ex_new_index*(argl: clong, argp: pointer, new_func: pointer, dup_func: pointer, free_func: pointer): cint {.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_CTX_set_ex_data*(ssl: SslCtx, idx: cint, arg: pointer): cint {.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_CTX_get_ex_data*(ssl: SslCtx, idx: cint): pointer {.cdecl, dynlib: DLLSSLName, importc.}

proc SSL_set_fd*(ssl: SslPtr, fd: SocketHandle): cint{.cdecl, dynlib: DLLSSLName, importc.}

proc SSL_shutdown*(ssl: SslPtr): cInt{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_set_shutdown*(ssl: SslPtr, mode: cint) {.cdecl, dynlib: DLLSSLName, importc: "SSL_set_shutdown".}
proc SSL_get_shutdown*(ssl: SslPtr): cint {.cdecl, dynlib: DLLSSLName, importc: "SSL_get_shutdown".}
proc SSL_connect*(ssl: SslPtr): cint{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_read*(ssl: SslPtr, buf: pointer, num: int): cint{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_write*(ssl: SslPtr, buf: cstring, num: int): cint{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_get_error*(s: SslPtr, ret_code: cInt): cInt{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_accept*(ssl: SslPtr): cInt{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_pending*(ssl: SslPtr): cInt{.cdecl, dynlib: DLLSSLName, importc.}

proc BIO_new_mem_buf*(data: pointer, len: cint): BIO{.cdecl,
    dynlib: DLLSSLName, importc.}
proc BIO_new_ssl_connect*(ctx: SslCtx): BIO{.cdecl,
    dynlib: DLLSSLName, importc.}
proc BIO_ctrl*(bio: BIO, cmd: cint, larg: int, arg: cstring): int{.cdecl,
    dynlib: DLLSSLName, importc.}
proc BIO_get_ssl*(bio: BIO, ssl: ptr SslPtr): int =
  return BIO_ctrl(bio, BIO_C_GET_SSL, 0, cast[cstring](ssl))
proc BIO_set_conn_hostname*(bio: BIO, name: cstring): int =
  return BIO_ctrl(bio, BIO_C_SET_CONNECT, 0, name)
proc BIO_do_handshake*(bio: BIO): int =
  return BIO_ctrl(bio, BIO_C_DO_STATE_MACHINE, 0, nil)
proc BIO_do_connect*(bio: BIO): int =
  return BIO_do_handshake(bio)

when not defined(nimfix):
  proc BIO_read*(b: BIO, data: cstring, length: cInt): cInt{.cdecl,
      dynlib: DLLUtilName, importc.}
  proc BIO_write*(b: BIO, data: cstring, length: cInt): cInt{.cdecl,
      dynlib: DLLUtilName, importc.}

proc BIO_free*(b: BIO): cInt{.cdecl, dynlib: DLLUtilName, importc.}

proc ERR_print_errors_fp*(fp: File){.cdecl, dynlib: DLLSSLName, importc.}

proc ERR_error_string*(e: cInt, buf: cstring): cstring{.cdecl,
    dynlib: DLLUtilName, importc.}
proc ERR_get_error*(): cInt{.cdecl, dynlib: DLLUtilName, importc.}
proc ERR_peek_last_error*(): cInt{.cdecl, dynlib: DLLUtilName, importc.}

proc OPENSSL_config*(configName: cstring){.cdecl, dynlib: DLLSSLName, importc.}

when not useWinVersion and not defined(macosx) and not defined(android) and not defined(nimNoAllocForSSL):
  proc CRYPTO_set_mem_functions(a,b,c: pointer){.cdecl,
    dynlib: DLLUtilName, importc.}

  proc allocWrapper(size: int): pointer {.cdecl.} = alloc(size)
  proc reallocWrapper(p: pointer; newsize: int): pointer {.cdecl.} =
    if p == nil:
      if newSize > 0: result = alloc(newsize)
    elif newsize == 0: dealloc(p)
    else: result = realloc(p, newsize)
  proc deallocWrapper(p: pointer) {.cdecl.} =
    if p != nil: dealloc(p)

proc CRYPTO_malloc_init*() =
  when not useWinVersion and not defined(macosx) and not defined(android) and not defined(nimNoAllocForSSL):
    CRYPTO_set_mem_functions(allocWrapper, reallocWrapper, deallocWrapper)

proc SSL_CTX_ctrl*(ctx: SslCtx, cmd: cInt, larg: int, parg: pointer): int{.
  cdecl, dynlib: DLLSSLName, importc.}

proc SSL_CTX_callback_ctrl(ctx: SslCtx, typ: cInt, fp: PFunction): int{.
  cdecl, dynlib: DLLSSLName, importc.}

proc SSLCTXSetMode*(ctx: SslCtx, mode: int): int =
  result = SSL_CTX_ctrl(ctx, SSL_CTRL_MODE, mode, nil)

proc SSL_ctrl*(ssl: SslPtr, cmd: cInt, larg: int, parg: pointer): int{.
  cdecl, dynlib: DLLSSLName, importc.}

proc SSL_set_tlsext_host_name*(ssl: SslPtr, name: cstring): int =
  result = SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, name)
  ## Set the SNI server name extension to be used in a client hello.
  ## Returns 1 if SNI was set, 0 if current SSL configuration doesn't support SNI.


proc SSL_get_servername*(ssl: SslPtr, typ: cInt = TLSEXT_NAMETYPE_host_name): cstring {.cdecl, dynlib: DLLSSLName, importc.}
  ## Retrieve the server name requested in the client hello. This can be used
  ## in the callback set in `SSL_CTX_set_tlsext_servername_callback` to
  ## implement virtual hosting. May return `nil`.

proc SSL_CTX_set_tlsext_servername_callback*(ctx: SslCtx, cb: proc(ssl: SslPtr, cb_id: int, arg: pointer): int {.cdecl.}): int =
  ## Set the callback to be used on listening SSL connections when the client hello is received.
  ##
  ## The callback should return one of:
  ## * SSL_TLSEXT_ERR_OK
  ## * SSL_TLSEXT_ERR_ALERT_WARNING
  ## * SSL_TLSEXT_ERR_ALERT_FATAL
  ## * SSL_TLSEXT_ERR_NOACK
  result = SSL_CTX_callback_ctrl(ctx, SSL_CTRL_SET_TLSEXT_SERVERNAME_CB, cast[PFunction](cb))

proc SSL_CTX_set_tlsext_servername_arg*(ctx: SslCtx, arg: pointer): int =
  ## Set the pointer to be used in the callback registered to ``SSL_CTX_set_tlsext_servername_callback``.
  result = SSL_CTX_ctrl(ctx, SSL_CTRL_SET_TLSEXT_SERVERNAME_ARG, 0, arg)

type
  PskClientCallback* = proc (ssl: SslPtr;
    hint: cstring; identity: cstring; max_identity_len: cuint; psk: ptr cuchar;
    max_psk_len: cuint): cuint {.cdecl.}

  PskServerCallback* = proc (ssl: SslPtr;
    identity: cstring; psk: ptr cuchar; max_psk_len: cint): cuint {.cdecl.}

proc SSL_CTX_set_psk_client_callback*(ctx: SslCtx; callback: PskClientCallback) {.cdecl, dynlib: DLLSSLName, importc.}
  ## Set callback called when OpenSSL needs PSK (for client).

proc SSL_CTX_set_psk_server_callback*(ctx: SslCtx; callback: PskServerCallback) {.cdecl, dynlib: DLLSSLName, importc.}
  ## Set callback called when OpenSSL needs PSK (for server).

proc SSL_CTX_use_psk_identity_hint*(ctx: SslCtx; hint: cstring): cint {.cdecl, dynlib: DLLSSLName, importc.}
  ## Set PSK identity hint to use.

proc SSL_get_psk_identity*(ssl: SslPtr): cstring {.cdecl, dynlib: DLLSSLName, importc.}
  ## Get PSK identity.

proc bioNew*(b: PBIO_METHOD): BIO{.cdecl, dynlib: DLLUtilName, importc: "BIO_new".}
proc bioFreeAll*(b: BIO){.cdecl, dynlib: DLLUtilName, importc: "BIO_free_all".}
proc bioSMem*(): PBIO_METHOD{.cdecl, dynlib: DLLUtilName, importc: "BIO_s_mem".}
proc bioCtrlPending*(b: BIO): cInt{.cdecl, dynlib: DLLUtilName, importc: "BIO_ctrl_pending".}
proc bioRead*(b: BIO, Buf: cstring, length: cInt): cInt{.cdecl,
    dynlib: DLLUtilName, importc: "BIO_read".}
proc bioWrite*(b: BIO, Buf: cstring, length: cInt): cInt{.cdecl,
    dynlib: DLLUtilName, importc: "BIO_write".}

proc sslSetConnectState*(s: SslPtr) {.cdecl,
    dynlib: DLLSSLName, importc: "SSL_set_connect_state".}
proc sslSetAcceptState*(s: SslPtr) {.cdecl,
    dynlib: DLLSSLName, importc: "SSL_set_accept_state".}

proc sslRead*(ssl: SslPtr, buf: cstring, num: cInt): cInt{.cdecl,
      dynlib: DLLSSLName, importc: "SSL_read".}
proc sslPeek*(ssl: SslPtr, buf: cstring, num: cInt): cInt{.cdecl,
    dynlib: DLLSSLName, importc: "SSL_peek".}
proc sslWrite*(ssl: SslPtr, buf: cstring, num: cInt): cInt{.cdecl,
    dynlib: DLLSSLName, importc: "SSL_write".}

proc sslSetBio*(ssl: SslPtr, rbio, wbio: BIO) {.cdecl,
    dynlib: DLLSSLName, importc: "SSL_set_bio".}

proc sslDoHandshake*(ssl: SslPtr): cint {.cdecl,
    dynlib: DLLSSLName, importc: "SSL_do_handshake".}



proc ErrClearError*(){.cdecl, dynlib: DLLUtilName, importc: "ERR_clear_error".}
proc ErrFreeStrings*(){.cdecl, dynlib: DLLUtilName, importc: "ERR_free_strings".}
proc ErrRemoveState*(pid: cInt){.cdecl, dynlib: DLLUtilName, importc: "ERR_remove_state".}

proc PEM_read_bio_RSA_PUBKEY*(bp: BIO, x: ptr PRSA, pw: pem_password_cb, u: pointer): PRSA {.cdecl,
    dynlib: DLLSSLName, importc.}

proc RSA_verify*(kind: cint, origMsg: pointer, origMsgLen: cuint, signature: pointer,
    signatureLen: cuint, rsa: PRSA): cint {.cdecl, dynlib: DLLSSLName, importc.}

when true:
  discard
else:
  proc SslCtxSetCipherList*(arg0: PSSL_CTX, str: cstring): cInt{.cdecl,
      dynlib: DLLSSLName, importc.}
  proc SslCtxNew*(meth: PSSL_METHOD): PSSL_CTX{.cdecl,
      dynlib: DLLSSLName, importc.}

  proc SslSetFd*(s: PSSL, fd: cInt): cInt{.cdecl, dynlib: DLLSSLName, importc.}
  proc SslCTXCtrl*(ctx: PSSL_CTX, cmd: cInt, larg: int, parg: Pointer): int{.
      cdecl, dynlib: DLLSSLName, importc.}

  proc SSLSetMode*(s: PSSL, mode: int): int
  proc SSLCTXGetMode*(ctx: PSSL_CTX): int
  proc SSLGetMode*(s: PSSL): int
  proc SslMethodV2*(): PSSL_METHOD{.cdecl, dynlib: DLLSSLName, importc.}
  proc SslMethodV3*(): PSSL_METHOD{.cdecl, dynlib: DLLSSLName, importc.}
  proc SslMethodTLSV1*(): PSSL_METHOD{.cdecl, dynlib: DLLSSLName, importc.}
  proc SslMethodV23*(): PSSL_METHOD{.cdecl, dynlib: DLLSSLName, importc.}
  proc SslCtxUsePrivateKey*(ctx: PSSL_CTX, pkey: SslPtr): cInt{.cdecl,
      dynlib: DLLSSLName, importc.}
  proc SslCtxUsePrivateKeyASN1*(pk: cInt, ctx: PSSL_CTX,
      d: cstring, length: int): cInt{.cdecl, dynlib: DLLSSLName, importc.}

  proc SslCtxUseCertificate*(ctx: PSSL_CTX, x: SslPtr): cInt{.cdecl,
      dynlib: DLLSSLName, importc.}
  proc SslCtxUseCertificateASN1*(ctx: PSSL_CTX, length: int, d: cstring): cInt{.
      cdecl, dynlib: DLLSSLName, importc.}

    #  function SslCtxUseCertificateChainFile(ctx: PSSL_CTX; const filename: PChar):cInt;
  proc SslCtxUseCertificateChainFile*(ctx: PSSL_CTX, filename: cstring): cInt{.
      cdecl, dynlib: DLLSSLName, importc.}
  proc SslCtxSetDefaultPasswdCb*(ctx: PSSL_CTX, cb: PPasswdCb){.cdecl,
      dynlib: DLLSSLName, importc.}
  proc SslCtxSetDefaultPasswdCbUserdata*(ctx: PSSL_CTX, u: SslPtr){.cdecl,
      dynlib: DLLSSLName, importc.}
    #  function SslCtxLoadVerifyLocations(ctx: PSSL_CTX; const CAfile: PChar; const CApath: PChar):cInt;
  proc SslCtxLoadVerifyLocations*(ctx: PSSL_CTX, CAfile: cstring, CApath: cstring): cInt{.
      cdecl, dynlib: DLLSSLName, importc.}
  proc SslNew*(ctx: PSSL_CTX): PSSL{.cdecl, dynlib: DLLSSLName, importc.}


  proc SslConnect*(ssl: PSSL): cInt{.cdecl, dynlib: DLLSSLName, importc.}


  proc SslGetVersion*(ssl: PSSL): cstring{.cdecl, dynlib: DLLSSLName, importc.}
  proc SslGetPeerCertificate*(ssl: PSSL): PX509{.cdecl, dynlib: DLLSSLName,
      importc.}
  proc SslCtxSetVerify*(ctx: PSSL_CTX, mode: cInt, arg2: PFunction){.cdecl,
      dynlib: DLLSSLName, importc.}
  proc SSLGetCurrentCipher*(s: PSSL): SslPtr{.cdecl, dynlib: DLLSSLName, importc.}
  proc SSLCipherGetName*(c: SslPtr): cstring{.cdecl, dynlib: DLLSSLName, importc.}
  proc SSLCipherGetBits*(c: SslPtr, alg_bits: var cInt): cInt{.cdecl,
      dynlib: DLLSSLName, importc.}
  proc SSLGetVerifyResult*(ssl: PSSL): int{.cdecl, dynlib: DLLSSLName, importc.}
    # libeay.dll
  proc X509New*(): PX509{.cdecl, dynlib: DLLUtilName, importc.}
  proc X509Free*(x: PX509){.cdecl, dynlib: DLLUtilName, importc.}
  proc X509NameOneline*(a: PX509_NAME, buf: cstring, size: cInt): cstring{.
      cdecl, dynlib: DLLUtilName, importc.}
  proc X509GetSubjectName*(a: PX509): PX509_NAME{.cdecl, dynlib: DLLUtilName,
      importc.}
  proc X509GetIssuerName*(a: PX509): PX509_NAME{.cdecl, dynlib: DLLUtilName,
      importc.}
  proc X509NameHash*(x: PX509_NAME): int{.cdecl, dynlib: DLLUtilName, importc.}
    #  function SslX509Digest(data: PX509; typ: PEVP_MD; md: PChar; len: PcInt):cInt;
  proc X509Digest*(data: PX509, typ: PEVP_MD, md: cstring, length: var cInt): cInt{.
      cdecl, dynlib: DLLUtilName, importc.}
  proc X509print*(b: PBIO, a: PX509): cInt{.cdecl, dynlib: DLLUtilName, importc.}
  proc X509SetVersion*(x: PX509, version: cInt): cInt{.cdecl, dynlib: DLLUtilName,
      importc.}
  proc X509SetPubkey*(x: PX509, pkey: EVP_PKEY): cInt{.cdecl, dynlib: DLLUtilName,
      importc.}
  proc X509SetIssuerName*(x: PX509, name: PX509_NAME): cInt{.cdecl,
      dynlib: DLLUtilName, importc.}
  proc X509NameAddEntryByTxt*(name: PX509_NAME, field: cstring, typ: cInt,
                              bytes: cstring, length, loc, theSet: cInt): cInt{.
      cdecl, dynlib: DLLUtilName, importc.}
  proc X509Sign*(x: PX509, pkey: EVP_PKEY, md: PEVP_MD): cInt{.cdecl,
      dynlib: DLLUtilName, importc.}
  proc X509GmtimeAdj*(s: PASN1_UTCTIME, adj: cInt): PASN1_UTCTIME{.cdecl,
      dynlib: DLLUtilName, importc.}
  proc X509SetNotBefore*(x: PX509, tm: PASN1_UTCTIME): cInt{.cdecl,
      dynlib: DLLUtilName, importc.}
  proc X509SetNotAfter*(x: PX509, tm: PASN1_UTCTIME): cInt{.cdecl,
      dynlib: DLLUtilName, importc.}
  proc X509GetSerialNumber*(x: PX509): PASN1_cInt{.cdecl, dynlib: DLLUtilName,
      importc.}
  proc EvpPkeyNew*(): EVP_PKEY{.cdecl, dynlib: DLLUtilName, importc.}
  proc EvpPkeyFree*(pk: EVP_PKEY){.cdecl, dynlib: DLLUtilName, importc.}
  proc EvpPkeyAssign*(pkey: EVP_PKEY, typ: cInt, key: Prsa): cInt{.cdecl,
      dynlib: DLLUtilName, importc.}
  proc EvpGetDigestByName*(Name: cstring): PEVP_MD{.cdecl, dynlib: DLLUtilName,
      importc.}
  proc EVPcleanup*(){.cdecl, dynlib: DLLUtilName, importc.}
    #  function ErrErrorString(e: cInt; buf: PChar): PChar;
  proc SSLeayversion*(t: cInt): cstring{.cdecl, dynlib: DLLUtilName, importc.}


  proc OPENSSLaddallalgorithms*(){.cdecl, dynlib: DLLUtilName, importc.}
  proc CRYPTOcleanupAllExData*(){.cdecl, dynlib: DLLUtilName, importc.}
  proc RandScreen*(){.cdecl, dynlib: DLLUtilName, importc.}

  proc d2iPKCS12bio*(b: PBIO, Pkcs12: SslPtr): SslPtr{.cdecl, dynlib: DLLUtilName,
      importc.}
  proc PKCS12parse*(p12: SslPtr, pass: cstring, pkey, cert, ca: var SslPtr): cint{.
      dynlib: DLLUtilName, importc, cdecl.}

  proc PKCS12free*(p12: SslPtr){.cdecl, dynlib: DLLUtilName, importc.}
  proc RsaGenerateKey*(bits, e: cInt, callback: PFunction, cb_arg: SslPtr): PRSA{.
      cdecl, dynlib: DLLUtilName, importc.}
  proc Asn1UtctimeNew*(): PASN1_UTCTIME{.cdecl, dynlib: DLLUtilName, importc.}
  proc Asn1UtctimeFree*(a: PASN1_UTCTIME){.cdecl, dynlib: DLLUtilName, importc.}
  proc Asn1cIntSet*(a: PASN1_cInt, v: cInt): cInt{.cdecl, dynlib: DLLUtilName,
      importc.}
  proc i2dX509bio*(b: PBIO, x: PX509): cInt{.cdecl, dynlib: DLLUtilName, importc.}
  proc i2dPrivateKeyBio*(b: PBIO, pkey: EVP_PKEY): cInt{.cdecl,
      dynlib: DLLUtilName, importc.}
    # 3DES functions
  proc DESsetoddparity*(Key: des_cblock){.cdecl, dynlib: DLLUtilName, importc.}
  proc DESsetkeychecked*(key: des_cblock, schedule: des_key_schedule): cInt{.
      cdecl, dynlib: DLLUtilName, importc.}
  proc DESecbencrypt*(Input: des_cblock, output: des_cblock, ks: des_key_schedule,
                      enc: cInt){.cdecl, dynlib: DLLUtilName, importc.}
  # implementation

  proc SSLSetMode(s: PSSL, mode: int): int =
    result = SSLctrl(s, SSL_CTRL_MODE, mode, nil)

  proc SSLCTXGetMode(ctx: PSSL_CTX): int =
    result = SSLCTXctrl(ctx, SSL_CTRL_MODE, 0, nil)

  proc SSLGetMode(s: PSSL): int =
    result = SSLctrl(s, SSL_CTRL_MODE, 0, nil)

# <openssl/md5.h>
type
  MD5_LONG* = cuint
const
  MD5_CBLOCK* = 64
  MD5_LBLOCK* = int(MD5_CBLOCK div 4)
  MD5_DIGEST_LENGTH* = 16
type
  MD5_CTX* = object
    A,B,C,D,Nl,Nh: MD5_LONG
    data: array[MD5_LBLOCK, MD5_LONG]
    num: cuint

{.push callconv:cdecl, dynlib:DLLUtilName.}
proc md5_Init*(c: var MD5_CTX): cint{.importc: "MD5_Init".}
proc md5_Update*(c: var MD5_CTX; data: pointer; len: csize): cint{.importc: "MD5_Update".}
proc md5_Final*(md: cstring; c: var MD5_CTX): cint{.importc: "MD5_Final".}
proc md5*(d: ptr cuchar; n: csize; md: ptr cuchar): ptr cuchar{.importc: "MD5".}
proc md5_Transform*(c: var MD5_CTX; b: ptr cuchar){.importc: "MD5_Transform".}
{.pop.}

from strutils import toHex, toLowerAscii

proc hexStr(buf: cstring): string =
  # turn md5s output into a nice hex str
  result = newStringOfCap(32)
  for i in 0 ..< 16:
    result.add toHex(buf[i].ord, 2).toLowerAscii

proc md5_File*(file: string): string {.raises: [IOError,Exception].} =
  ## Generate MD5 hash for a file. Result is a 32 character
  # hex string with lowercase characters (like the output
  # of `md5sum`
  const
    sz = 512
  let f = open(file,fmRead)
  var
    buf: array[sz,char]
    ctx: MD5_CTX

  discard md5_init(ctx)
  while(let bytes = f.readChars(buf, 0, sz); bytes > 0):
    discard md5_update(ctx, buf[0].addr, bytes)

  discard md5_final(buf[0].addr, ctx)
  f.close

  result = hexStr(addr buf)

proc md5_Str*(str: string): string =
  ## Generate MD5 hash for a string. Result is a 32 character
  ## hex string with lowercase characters
  var
    ctx: MD5_CTX
    res: array[MD5_DIGEST_LENGTH,char]
    input = str.cstring
  discard md5_init(ctx)

  var i = 0
  while i < str.len:
    let L = min(str.len - i, 512)
    discard md5_update(ctx, input[i].addr, L)
    i += L

  discard md5_final(addr res, ctx)
  result = hexStr(addr res)
