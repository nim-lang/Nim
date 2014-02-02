#==============================================================================#
# Project: Ararat Synapse                                        | 003.004.001 #
#==============================================================================#
# Content: SSL support by OpenSSL                                              #
#==============================================================================#
# Copyright (c)1999-2005, Lukas Gebauer                                        #
# All rights reserved.                                                         #
#                                                                              #
# Redistribution and use in source and binary forms, with or without           #
# modification, are permitted provided that the following conditions are met:  #
#                                                                              #
# Redistributions of source code must retain the above copyright notice, this  #
# list of conditions and the following disclaimer.                             #
#                                                                              #
# Redistributions in binary form must reproduce the above copyright notice,    #
# this list of conditions and the following disclaimer in the documentation    #
# and/or other materials provided with the distribution.                       #
#                                                                              #
# Neither the name of Lukas Gebauer nor the names of its contributors may      #
# be used to endorse or promote products derived from this software without    #
# specific prior written permission.                                           #
#                                                                              #
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"  #
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    #
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE   #
# ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR  #
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL       #
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR   #
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER   #
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT           #
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY    #
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH  #
# DAMAGE.                                                                      #
#==============================================================================#
# The Initial Developer of the Original Code is Lukas Gebauer (Czech Republic).#
# Portions created by Lukas Gebauer are Copyright (c)2002-2005.                #
# All Rights Reserved.                                                         #
#==============================================================================#

## OpenSSL support

{.deadCodeElim: on.}

when defined(WINDOWS): 
  const 
    DLLSSLName = "(ssleay32|libssl32).dll"
    DLLUtilName = "libeay32.dll"
  from winlean import TSocketHandle
else:
  const
    versions = "(|.1.0.0|.0.9.9|.0.9.8|.0.9.7|.0.9.6|.0.9.5|.0.9.4)"
  when defined(macosx):
    const
      DLLSSLName = "libssl" & versions & ".dylib"
      DLLUtilName = "libcrypto" & versions & ".dylib"
  else:
    const 
      DLLSSLName = "libssl.so" & versions
      DLLUtilName = "libcrypto.so" & versions
  from posix import TSocketHandle

type 
  SslStruct {.final, pure.} = object
  SslPtr* = ptr SslStruct
  PSslPtr* = ptr SslPtr
  PSSL_CTX* = SslPtr
  PSSL* = SslPtr
  PSSL_METHOD* = SslPtr
  PX509* = SslPtr
  PX509_NAME* = SslPtr
  PEVP_MD* = SslPtr
  PBIO_METHOD* = SslPtr
  PBIO* = SslPtr
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

const 
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

proc SSL_library_init*(): cInt{.cdecl, dynlib: DLLSSLName, importc, discardable.}
proc SSL_load_error_strings*(){.cdecl, dynlib: DLLSSLName, importc.}
proc ERR_load_BIO_strings*(){.cdecl, dynlib: DLLUtilName, importc.}

proc SSLv23_client_method*(): PSSL_METHOD{.cdecl, dynlib: DLLSSLName, importc.}
proc SSLv23_method*(): PSSL_METHOD{.cdecl, dynlib: DLLSSLName, importc.}
proc SSLv2_method*(): PSSL_METHOD{.cdecl, dynlib: DLLSSLName, importc.}
proc SSLv3_method*(): PSSL_METHOD{.cdecl, dynlib: DLLSSLName, importc.}
proc TLSv1_method*(): PSSL_METHOD{.cdecl, dynlib: DLLSSLName, importc.}

proc SSL_new*(context: PSSL_CTX): PSSL{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_free*(ssl: PSSL){.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_CTX_new*(meth: PSSL_METHOD): PSSL_CTX{.cdecl,
    dynlib: DLLSSLName, importc.}
proc SSL_CTX_load_verify_locations*(ctx: PSSL_CTX, CAfile: cstring,
    CApath: cstring): cInt{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_CTX_free*(arg0: PSSL_CTX){.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_CTX_set_verify*(s: PSSL_CTX, mode: int, cb: proc (a: int, b: pointer): int {.cdecl.}){.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_get_verify_result*(ssl: PSSL): int{.cdecl,
    dynlib: DLLSSLName, importc.}

proc SSL_CTX_set_cipher_list*(s: PSSLCTX, ciphers: cstring): cint{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_CTX_use_certificate_file*(ctx: PSSL_CTX, filename: cstring, typ: cInt): cInt{.
    stdcall, dynlib: DLLSSLName, importc.}
proc SSL_CTX_use_certificate_chain_file*(ctx: PSSL_CTX, filename: cstring): cInt{.
    stdcall, dynlib: DLLSSLName, importc.}
proc SSL_CTX_use_PrivateKey_file*(ctx: PSSL_CTX,
    filename: cstring, typ: cInt): cInt{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_CTX_check_private_key*(ctx: PSSL_CTX): cInt{.cdecl, dynlib: DLLSSLName, 
    importc.}

proc SSL_set_fd*(ssl: PSSL, fd: TSocketHandle): cint{.cdecl, dynlib: DLLSSLName, importc.}

proc SSL_shutdown*(ssl: PSSL): cInt{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_connect*(ssl: PSSL): cint{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_read*(ssl: PSSL, buf: pointer, num: int): cint{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_write*(ssl: PSSL, buf: cstring, num: int): cint{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_get_error*(s: PSSL, ret_code: cInt): cInt{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_accept*(ssl: PSSL): cInt{.cdecl, dynlib: DLLSSLName, importc.}
proc SSL_pending*(ssl: PSSL): cInt{.cdecl, dynlib: DLLSSLName, importc.}

proc BIO_new_ssl_connect*(ctx: PSSL_CTX): PBIO{.cdecl,
    dynlib: DLLSSLName, importc.}
proc BIO_ctrl*(bio: PBIO, cmd: cint, larg: int, arg: cstring): int{.cdecl,
    dynlib: DLLSSLName, importc.}
proc BIO_get_ssl*(bio: PBIO, ssl: ptr PSSL): int = 
  return BIO_ctrl(bio, BIO_C_GET_SSL, 0, cast[cstring](ssl))
proc BIO_set_conn_hostname*(bio: PBIO, name: cstring): int =
  return BIO_ctrl(bio, BIO_C_SET_CONNECT, 0, name)
proc BIO_do_handshake*(bio: PBIO): int =
  return BIO_ctrl(bio, BIO_C_DO_STATE_MACHINE, 0, NIL)
proc BIO_do_connect*(bio: PBIO): int =
  return BIO_do_handshake(bio)

proc BIO_read*(b: PBIO, data: cstring, length: cInt): cInt{.cdecl, 
    dynlib: DLLUtilName, importc.}
proc BIO_write*(b: PBIO, data: cstring, length: cInt): cInt{.cdecl, 
    dynlib: DLLUtilName, importc.}

proc BIO_free*(b: PBIO): cInt{.cdecl, dynlib: DLLUtilName, importc.}

proc ERR_print_errors_fp*(fp: TFile){.cdecl, dynlib: DLLSSLName, importc.}

proc ERR_error_string*(e: cInt, buf: cstring): cstring{.cdecl, 
    dynlib: DLLUtilName, importc.}
proc ERR_get_error*(): cInt{.cdecl, dynlib: DLLUtilName, importc.}
proc ERR_peek_last_error*(): cInt{.cdecl, dynlib: DLLUtilName, importc.}

proc OpenSSL_add_all_algorithms*(){.cdecl, dynlib: DLLUtilName, importc: "OPENSSL_add_all_algorithms_conf".}

proc OPENSSL_config*(configName: cstring){.cdecl, dynlib: DLLSSLName, importc.}

when not defined(windows):
  proc CRYPTO_set_mem_functions(a,b,c: pointer){.cdecl, 
    dynlib: DLLSSLName, importc.}

proc CRYPTO_malloc_init*() =
  when not defined(windows):
    CRYPTO_set_mem_functions(alloc, realloc, dealloc)

proc SSL_CTX_ctrl*(ctx: PSSL_CTX, cmd: cInt, larg: int, parg: pointer): int{.
  cdecl, dynlib: DLLSSLName, importc.}

proc SSLCTXSetMode*(ctx: PSSL_CTX, mode: int): int =
  result = SSL_CTX_ctrl(ctx, SSL_CTRL_MODE, mode, nil)

when true:
  discard
else:
  proc SslCtxSetCipherList*(arg0: PSSL_CTX, str: cstring): cInt{.cdecl, 
      dynlib: DLLSSLName, importc.}
  proc SslCtxNew*(meth: PSSL_METHOD): PSSL_CTX{.cdecl,
      dynlib: DLLSSLName, importc.}

  proc SslSetFd*(s: PSSL, fd: cInt): cInt{.cdecl, dynlib: DLLSSLName, importc.}
  proc SslCtrl*(ssl: PSSL, cmd: cInt, larg: int, parg: Pointer): int{.cdecl, 
      dynlib: DLLSSLName, importc.}
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

  proc SslRead*(ssl: PSSL, buf: SslPtr, num: cInt): cInt{.cdecl, 
      dynlib: DLLSSLName, importc.}
  proc SslPeek*(ssl: PSSL, buf: SslPtr, num: cInt): cInt{.cdecl, 
      dynlib: DLLSSLName, importc.}
  proc SslWrite*(ssl: PSSL, buf: SslPtr, num: cInt): cInt{.cdecl, 
      dynlib: DLLSSLName, importc.}
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

  proc ErrClearError*(){.cdecl, dynlib: DLLUtilName, importc.}
  proc ErrFreeStrings*(){.cdecl, dynlib: DLLUtilName, importc.}
  proc ErrRemoveState*(pid: cInt){.cdecl, dynlib: DLLUtilName, importc.}
  proc OPENSSLaddallalgorithms*(){.cdecl, dynlib: DLLUtilName, importc.}
  proc CRYPTOcleanupAllExData*(){.cdecl, dynlib: DLLUtilName, importc.}
  proc RandScreen*(){.cdecl, dynlib: DLLUtilName, importc.}
  proc BioNew*(b: PBIO_METHOD): PBIO{.cdecl, dynlib: DLLUtilName, importc.}
  proc BioFreeAll*(b: PBIO){.cdecl, dynlib: DLLUtilName, importc.}
  proc BioSMem*(): PBIO_METHOD{.cdecl, dynlib: DLLUtilName, importc.}
  proc BioCtrlPending*(b: PBIO): cInt{.cdecl, dynlib: DLLUtilName, importc.}
  proc BioRead*(b: PBIO, Buf: cstring, length: cInt): cInt{.cdecl, 
      dynlib: DLLUtilName, importc.}
  proc BioWrite*(b: PBIO, Buf: cstring, length: cInt): cInt{.cdecl, 
      dynlib: DLLUtilName, importc.}
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

