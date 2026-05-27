#
#            Nim's Runtime Library
#        (c) Copyright 2026 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Wrapper for the 8-bit PCRE2 API.

when sizeof(int) == 4:
  const ANCHORED* = low(int)
else:
  const ANCHORED* = int(0x80000000)

const
  NO_UTF_CHECK* = int(0x40000000)
  ENDANCHORED* = int(0x20000000)

const
  ALLOW_EMPTY_CLASS* = 0x00000001
  ALT_BSUX* = 0x00000002
  AUTO_CALLOUT* = 0x00000004
  CASELESS* = 0x00000008
  DOLLAR_ENDONLY* = 0x00000010
  DOTALL* = 0x00000020
  DUPNAMES* = 0x00000040
  EXTENDED* = 0x00000080
  FIRSTLINE* = 0x00000100
  MATCH_UNSET_BACKREF* = 0x00000200
  MULTILINE* = 0x00000400
  NEVER_UCP* = 0x00000800
  NEVER_UTF* = 0x00001000
  NO_AUTO_CAPTURE* = 0x00002000
  NO_AUTO_POSSESS* = 0x00004000
  NO_DOTSTAR_ANCHOR* = 0x00008000
  NO_START_OPTIMIZE* = 0x00010000
  NO_START_OPTIMISE* = NO_START_OPTIMIZE
  UCP* = 0x00020000
  UNGREEDY* = 0x00040000
  UTF* = 0x00080000
  UTF8* = UTF
  NEVER_BACKSLASH_C* = 0x00100000
  ALT_CIRCUMFLEX* = 0x00200000
  ALT_VERBNAMES* = 0x00400000
  USE_OFFSET_LIMIT* = 0x00800000
  EXTENDED_MORE* = 0x01000000
  LITERAL* = 0x02000000
  MATCH_INVALID_UTF* = 0x04000000
  ALT_EXTENDED_CLASS* = 0x08000000

  ## PCRE2 no longer exposes PCRE's `JAVASCRIPT_COMPAT` option. `ALT_BSUX`
  ## preserves the most important JavaScript-style escape handling.
  JAVASCRIPT_COMPAT* = ALT_BSUX

const
  JIT_COMPLETE* = 0x00000001
  JIT_PARTIAL_SOFT* = 0x00000002
  JIT_PARTIAL_HARD* = 0x00000004
  JIT_INVALID_UTF* = 0x00000100
  JIT_TEST_ALLOC* = 0x00000200

const
  NOTBOL* = 0x00000001
  NOTEOL* = 0x00000002
  NOTEMPTY* = 0x00000004
  NOTEMPTY_ATSTART* = 0x00000008
  PARTIAL_SOFT* = 0x00000010
  PARTIAL_HARD* = 0x00000020
  DFA_RESTART* = 0x00000040
  DFA_SHORTEST* = 0x00000080
  NO_JIT* = 0x00002000
  COPY_MATCHED_SUBJECT* = 0x00004000
  DISABLE_RECURSELOOP_CHECK* = 0x00040000

const
  NEWLINE_CR* = 1
  NEWLINE_LF* = 2
  NEWLINE_CRLF* = 3
  NEWLINE_ANY* = 4
  NEWLINE_ANYCRLF* = 5
  NEWLINE_NUL* = 6
  BSR_UNICODE* = 1
  BSR_ANYCRLF* = 2

const
  ERROR_NOMATCH* = -1
  ERROR_PARTIAL* = -2

  ERROR_UTF8_ERR1* = -3
  ERROR_UTF8_ERR2* = -4
  ERROR_UTF8_ERR3* = -5
  ERROR_UTF8_ERR4* = -6
  ERROR_UTF8_ERR5* = -7
  ERROR_UTF8_ERR6* = -8
  ERROR_UTF8_ERR7* = -9
  ERROR_UTF8_ERR8* = -10
  ERROR_UTF8_ERR9* = -11
  ERROR_UTF8_ERR10* = -12
  ERROR_UTF8_ERR11* = -13
  ERROR_UTF8_ERR12* = -14
  ERROR_UTF8_ERR13* = -15
  ERROR_UTF8_ERR14* = -16
  ERROR_UTF8_ERR15* = -17
  ERROR_UTF8_ERR16* = -18
  ERROR_UTF8_ERR17* = -19
  ERROR_UTF8_ERR18* = -20
  ERROR_UTF8_ERR19* = -21
  ERROR_UTF8_ERR20* = -22
  ERROR_UTF8_ERR21* = -23

  ERROR_BADDATA* = -29
  ERROR_MIXEDTABLES* = -30
  ERROR_BADMAGIC* = -31
  ERROR_BADMODE* = -32
  ERROR_BADOFFSET* = -33
  ERROR_BADOPTION* = -34
  ERROR_BADREPLACEMENT* = -35
  ERROR_BADUTFOFFSET* = -36
  ERROR_CALLOUT* = -37
  ERROR_INTERNAL* = -44
  ERROR_JIT_BADOPTION* = -45
  ERROR_JIT_STACKLIMIT* = -46
  ERROR_MATCHLIMIT* = -47
  ERROR_NOMEMORY* = -48
  ERROR_NOSUBSTRING* = -49
  ERROR_NULL* = -51
  ERROR_RECURSELOOP* = -52
  ERROR_DEPTHLIMIT* = -53
  ERROR_RECURSIONLIMIT* = ERROR_DEPTHLIMIT
  ERROR_UNAVAILABLE* = -54
  ERROR_UNSET* = -55
  ERROR_BADOFFSETLIMIT* = -56
  ERROR_HEAPLIMIT* = -63
  ERROR_DFA_UINVALID_UTF* = -66
  ERROR_INVALIDOFFSET* = -67
  ERROR_JIT_UNSUPPORTED* = -68

const
  INFO_ALLOPTIONS* = 0
  INFO_ARGOPTIONS* = 1
  INFO_BACKREFMAX* = 2
  INFO_BSR* = 3
  INFO_CAPTURECOUNT* = 4
  INFO_FIRSTCODEUNIT* = 5
  INFO_FIRSTCODETYPE* = 6
  INFO_FIRSTBITMAP* = 7
  INFO_HASCRORLF* = 8
  INFO_JCHANGED* = 9
  INFO_JITSIZE* = 10
  INFO_LASTCODEUNIT* = 11
  INFO_LASTCODETYPE* = 12
  INFO_MATCHEMPTY* = 13
  INFO_MATCHLIMIT* = 14
  INFO_MAXLOOKBEHIND* = 15
  INFO_MINLENGTH* = 16
  INFO_NAMECOUNT* = 17
  INFO_NAMEENTRYSIZE* = 18
  INFO_NAMETABLE* = 19
  INFO_NEWLINE* = 20
  INFO_DEPTHLIMIT* = 21
  INFO_RECURSIONLIMIT* = INFO_DEPTHLIMIT
  INFO_SIZE* = 22
  INFO_HASBACKSLASHC* = 23
  INFO_FRAMESIZE* = 24
  INFO_HEAPLIMIT* = 25
  INFO_EXTRAOPTIONS* = 26

const
  CONFIG_BSR* = 0
  CONFIG_JIT* = 1
  CONFIG_JITTARGET* = 2
  CONFIG_LINKSIZE* = 3
  CONFIG_MATCHLIMIT* = 4
  CONFIG_NEWLINE* = 5
  CONFIG_PARENSLIMIT* = 6
  CONFIG_DEPTHLIMIT* = 7
  CONFIG_RECURSIONLIMIT* = CONFIG_DEPTHLIMIT
  CONFIG_STACKRECURSE* = 8
  CONFIG_UNICODE* = 9
  CONFIG_UNICODE_VERSION* = 10
  CONFIG_VERSION* = 11
  CONFIG_HEAPLIMIT* = 12
  CONFIG_NEVER_BACKSLASH_C* = 13
  CONFIG_COMPILED_WIDTHS* = 14
  CONFIG_TABLES_LENGTH* = 15

const
  ZERO_TERMINATED* = not 0.csize_t
  UNSET* = not 0.csize_t

type
  Pcre* = object
  CompileContext* = object
  GeneralContext* = object
  MatchContext* = object
  MatchData* = object
  JitStack* = object

when not defined(usePcreHeader):
  when hostOS == "windows":
    const pcre2Dll = "pcre2-8.dll"
  elif hostOS == "macosx":
    const pcre2Dll = "libpcre2-8(.0|).dylib"
  else:
    const pcre2Dll = "libpcre2-8.so(.0|)"
  {.push dynlib: pcre2Dll.}
else:
  {.passC: "-DPCRE2_CODE_UNIT_WIDTH=8".}
  {.push header: "<pcre2.h>".}

{.push cdecl, importc: "pcre2_$1_8".}

proc compile*(pattern: ptr uint8,
              length: csize_t,
              options: uint32,
              errorCode: ptr cint,
              errorOffset: ptr csize_t,
              context: ptr CompileContext): ptr Pcre

proc code_free*(code: ptr Pcre)

proc config*(what: uint32,
             where: pointer): cint

proc get_error_message*(errorCode: cint,
                        buffer: ptr uint8,
                        bufferLength: csize_t): cint

proc match*(code: ptr Pcre,
            subject: ptr uint8,
            length: csize_t,
            startOffset: csize_t,
            options: uint32,
            matchData: ptr MatchData,
            context: ptr MatchContext): cint

proc match_data_create*(oveccount: uint32,
                        context: ptr GeneralContext): ptr MatchData

proc match_data_create_from_pattern*(code: ptr Pcre,
                                     context: ptr GeneralContext): ptr MatchData

proc match_data_free*(matchData: ptr MatchData)

proc get_ovector_pointer*(matchData: ptr MatchData): ptr csize_t

proc get_ovector_count*(matchData: ptr MatchData): uint32

proc pattern_info*(code: ptr Pcre,
                   what: uint32,
                   where: pointer): cint

proc jit_compile*(code: ptr Pcre,
                  options: uint32): cint

proc jit_free_unused_memory*()

{.pop.}
{.pop.}
