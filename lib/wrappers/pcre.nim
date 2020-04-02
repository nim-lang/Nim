#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# The current PCRE version information.

const
  PCRE_MAJOR* = 8
  PCRE_MINOR* = 36
  PCRE_PRERELEASE* = true
  PCRE_DATE* = "2014-09-26"

# When an application links to a PCRE DLL in Windows, the symbols that are
# imported have to be identified as such. When building PCRE, the appropriate
# export setting is defined in pcre_internal.h, which includes this file. So we
# don't change existing definitions of PCRE_EXP_DECL and PCRECPP_EXP_DECL.

# By default, we use the standard "extern" declarations.

# Allow for C++ users

# Public options. Some are compile-time only, some are run-time only, and some
# are both. Most of the compile-time options are saved with the compiled regex
# so that they can be inspected during studying (and therefore JIT compiling).
# Note that pcre_study() has its own set of options. Originally, all the options
# defined here used distinct bits. However, almost all the bits in a 32-bit word
# are now used, so in order to conserve them, option bits that were previously
# only recognized at matching time (i.e. by pcre_exec() or pcre_dfa_exec()) may
# also be used for compile-time options that affect only compiling and are not
# relevant for studying or JIT compiling.
#
# Some options for pcre_compile() change its behaviour but do not affect the
# behaviour of the execution functions. Other options are passed through to the
# execution functions and affect their behaviour, with or without affecting the
# behaviour of pcre_compile().
#
# Options that can be passed to pcre_compile() are tagged Cx below, with these
# variants:
#
# C1   Affects compile only
# C2   Does not affect compile; affects exec, dfa_exec
# C3   Affects compile, exec, dfa_exec
# C4   Affects compile, exec, dfa_exec, study
# C5   Affects compile, exec, study
#
# Options that can be set for pcre_exec() and/or pcre_dfa_exec() are flagged
# with E and D, respectively. They take precedence over C3, C4, and C5 settings
# passed from pcre_compile(). Those that are compatible with JIT execution are
# flagged with J.

const
  CASELESS*          = 0x00000001  # C1
  MULTILINE*         = 0x00000002  # C1
  DOTALL*            = 0x00000004  # C1
  EXTENDED*          = 0x00000008  # C1
  ANCHORED*          = 0x00000010  # C4 E D
  DOLLAR_ENDONLY*    = 0x00000020  # C2
  EXTRA*             = 0x00000040  # C1
  NOTBOL*            = 0x00000080  #    E D J
  NOTEOL*            = 0x00000100  #    E D J
  UNGREEDY*          = 0x00000200  # C1
  NOTEMPTY*          = 0x00000400  #    E D J
  UTF8*              = 0x00000800  # C4        )
  UTF16*             = 0x00000800  # C4        ) Synonyms
  UTF32*             = 0x00000800  # C4        )
  NO_AUTO_CAPTURE*   = 0x00001000  # C1
  NO_UTF8_CHECK*     = 0x00002000  # C1 E D J  )
  NO_UTF16_CHECK*    = 0x00002000  # C1 E D J  ) Synonyms
  NO_UTF32_CHECK*    = 0x00002000  # C1 E D J  )
  AUTO_CALLOUT*      = 0x00004000  # C1
  PARTIAL_SOFT*      = 0x00008000  #    E D J  ) Synonyms
  PARTIAL*           = 0x00008000  #    E D J  )

# This pair use the same bit.
const
  NEVER_UTF*         = 0x00010000  # C1        ) Overlaid
  DFA_SHORTEST*      = 0x00010000  #      D    ) Overlaid

# This pair use the same bit.
const
  NO_AUTO_POSSESS*   = 0x00020000  # C1        ) Overlaid
  DFA_RESTART*       = 0x00020000  #      D    ) Overlaid

const
  FIRSTLINE*         = 0x00040000  # C3
  DUPNAMES*          = 0x00080000  # C1
  NEWLINE_CR*        = 0x00100000  # C3 E D
  NEWLINE_LF*        = 0x00200000  # C3 E D
  NEWLINE_CRLF*      = 0x00300000  # C3 E D
  NEWLINE_ANY*       = 0x00400000  # C3 E D
  NEWLINE_ANYCRLF*   = 0x00500000  # C3 E D
  BSR_ANYCRLF*       = 0x00800000  # C3 E D
  BSR_UNICODE*       = 0x01000000  # C3 E D
  JAVASCRIPT_COMPAT* = 0x02000000  # C5
  NO_START_OPTIMIZE* = 0x04000000  # C2 E D    ) Synonyms
  NO_START_OPTIMISE* = 0x04000000  # C2 E D    )
  PARTIAL_HARD*      = 0x08000000  #    E D J
  NOTEMPTY_ATSTART*  = 0x10000000  #    E D J
  UCP*               = 0x20000000  # C3

# Exec-time and get/set-time error codes
const
  ERROR_NOMATCH*          =  -1
  ERROR_NULL*             =  -2
  ERROR_BADOPTION*        =  -3
  ERROR_BADMAGIC*         =  -4
  ERROR_UNKNOWN_OPCODE*   =  -5
  ERROR_UNKNOWN_NODE*     =  -5 ## For backward compatibility
  ERROR_NOMEMORY*         =  -6
  ERROR_NOSUBSTRING*      =  -7
  ERROR_MATCHLIMIT*       =  -8
  ERROR_CALLOUT*          =  -9 ## Never used by PCRE itself
  ERROR_BADUTF8*          = -10 ## Same for 8/16/32
  ERROR_BADUTF16*         = -10 ## Same for 8/16/32
  ERROR_BADUTF32*         = -10 ## Same for 8/16/32
  ERROR_BADUTF8_OFFSET*   = -11 ## Same for 8/16
  ERROR_BADUTF16_OFFSET*  = -11 ## Same for 8/16
  ERROR_PARTIAL*          = -12
  ERROR_BADPARTIAL*       = -13
  ERROR_INTERNAL*         = -14
  ERROR_BADCOUNT*         = -15
  ERROR_DFA_UITEM*        = -16
  ERROR_DFA_UCOND*        = -17
  ERROR_DFA_UMLIMIT*      = -18
  ERROR_DFA_WSSIZE*       = -19
  ERROR_DFA_RECURSE*      = -20
  ERROR_RECURSIONLIMIT*   = -21
  ERROR_NULLWSLIMIT*      = -22 ## No longer actually used
  ERROR_BADNEWLINE*       = -23
  ERROR_BADOFFSET*        = -24
  ERROR_SHORTUTF8*        = -25
  ERROR_SHORTUTF16*       = -25 ## Same for 8/16
  ERROR_RECURSELOOP*      = -26
  ERROR_JIT_STACKLIMIT*   = -27
  ERROR_BADMODE*          = -28
  ERROR_BADENDIANNESS*    = -29
  ERROR_DFA_BADRESTART*   = -30
  ERROR_JIT_BADOPTION*    = -31
  ERROR_BADLENGTH*        = -32
  ERROR_UNSET*            = -33

# Specific error codes for UTF-8 validity checks
const
  UTF8_ERR0*  =  0
  UTF8_ERR1*  =  1
  UTF8_ERR2*  =  2
  UTF8_ERR3*  =  3
  UTF8_ERR4*  =  4
  UTF8_ERR5*  =  5
  UTF8_ERR6*  =  6
  UTF8_ERR7*  =  7
  UTF8_ERR8*  =  8
  UTF8_ERR9*  =  9
  UTF8_ERR10* = 10
  UTF8_ERR11* = 11
  UTF8_ERR12* = 12
  UTF8_ERR13* = 13
  UTF8_ERR14* = 14
  UTF8_ERR15* = 15
  UTF8_ERR16* = 16
  UTF8_ERR17* = 17
  UTF8_ERR18* = 18
  UTF8_ERR19* = 19
  UTF8_ERR20* = 20
  UTF8_ERR21* = 21
  UTF8_ERR22* = 22 # Unused (was non-character)

# Specific error codes for UTF-16 validity checks
const
  UTF16_ERR0* = 0
  UTF16_ERR1* = 1
  UTF16_ERR2* = 2
  UTF16_ERR3* = 3
  UTF16_ERR4* = 4 # Unused (was non-character)

# Specific error codes for UTF-32 validity checks
const
  UTF32_ERR0* = 0
  UTF32_ERR1* = 1
  UTF32_ERR2* = 2 # Unused (was non-character)
  UTF32_ERR3* = 3

# Request types for pcre_fullinfo()
const
  INFO_OPTIONS*             =  0
  INFO_SIZE*                =  1
  INFO_CAPTURECOUNT*        =  2
  INFO_BACKREFMAX*          =  3
  INFO_FIRSTBYTE*           =  4
  INFO_FIRSTCHAR*           =  4 ## For backwards compatibility
  INFO_FIRSTTABLE*          =  5
  INFO_LASTLITERAL*         =  6
  INFO_NAMEENTRYSIZE*       =  7
  INFO_NAMECOUNT*           =  8
  INFO_NAMETABLE*           =  9
  INFO_STUDYSIZE*           = 10
  INFO_DEFAULT_TABLES*      = 11
  INFO_OKPARTIAL*           = 12
  INFO_JCHANGED*            = 13
  INFO_HASCRORLF*           = 14
  INFO_MINLENGTH*           = 15
  INFO_JIT*                 = 16
  INFO_JITSIZE*             = 17
  INFO_MAXLOOKBEHIND*       = 18
  INFO_FIRSTCHARACTER*      = 19
  INFO_FIRSTCHARACTERFLAGS* = 20
  INFO_REQUIREDCHAR*        = 21
  INFO_REQUIREDCHARFLAGS*   = 22
  INFO_MATCHLIMIT*          = 23
  INFO_RECURSIONLIMIT*      = 24
  INFO_MATCH_EMPTY*         = 25

# Request types for pcre_config(). Do not re-arrange, in order to remain
# compatible.
const
  CONFIG_UTF8*                   =  0
  CONFIG_NEWLINE*                =  1
  CONFIG_LINK_SIZE*              =  2
  CONFIG_POSIX_MALLOC_THRESHOLD* =  3
  CONFIG_MATCH_LIMIT*            =  4
  CONFIG_STACKRECURSE*           =  5
  CONFIG_UNICODE_PROPERTIES*     =  6
  CONFIG_MATCH_LIMIT_RECURSION*  =  7
  CONFIG_BSR*                    =  8
  CONFIG_JIT*                    =  9
  CONFIG_UTF16*                  = 10
  CONFIG_JITTARGET*              = 11
  CONFIG_UTF32*                  = 12
  CONFIG_PARENS_LIMIT*           = 13

# Request types for pcre_study(). Do not re-arrange, in order to remain
# compatible.
const
  STUDY_JIT_COMPILE*              = 0x0001
  STUDY_JIT_PARTIAL_SOFT_COMPILE* = 0x0002
  STUDY_JIT_PARTIAL_HARD_COMPILE* = 0x0004
  STUDY_EXTRA_NEEDED*             = 0x0008

# Bit flags for the pcre[16|32]_extra structure. Do not re-arrange or redefine
# these bits, just add new ones on the end, in order to remain compatible.
const
  EXTRA_STUDY_DATA*            = 0x0001
  EXTRA_MATCH_LIMIT*           = 0x0002
  EXTRA_CALLOUT_DATA*          = 0x0004
  EXTRA_TABLES*                = 0x0008
  EXTRA_MATCH_LIMIT_RECURSION* = 0x0010
  EXTRA_MARK*                  = 0x0020
  EXTRA_EXECUTABLE_JIT*        = 0x0040

# Types
type
  Pcre* = object
  Pcre16* = object
  Pcre32* = object
  JitStack* = object
  JitStack16* = object
  JitStack32* = object

when defined(nimHasStyleChecks):
  {.push styleChecks: off.}

# The structure for passing additional data to pcre_exec(). This is defined in
# such as way as to be extensible. Always add new fields at the end, in order
# to remain compatible.
type
  ExtraData* = object
    flags*: clong                  ## Bits for which fields are set
    study_data*: pointer           ## Opaque data from pcre_study()
    match_limit*: clong            ## Maximum number of calls to match()
    callout_data*: pointer         ## Data passed back in callouts
    tables*: pointer               ## Pointer to character tables
    match_limit_recursion*: clong  ## Max recursive calls to match()
    mark*: pointer                 ## For passing back a mark pointer
    executable_jit*: pointer       ## Contains a pointer to a compiled jit code

# The structure for passing out data via the pcre_callout_function. We use a
# structure so that new fields can be added on the end in future versions,
# without changing the API of the function, thereby allowing old clients to
# work without modification.
type
  CalloutBlock* = object
    version*         : cint       ## Identifies version of block
    # ------------------------ Version 0 -------------------------------
    callout_number*  : cint       ## Number compiled into pattern
    offset_vector*   : ptr cint   ## The offset vector
    subject*         : cstring    ## The subject being matched
    subject_length*  : cint       ## The length of the subject
    start_match*     : cint       ## Offset to start of this match attempt
    current_position*: cint       ## Where we currently are in the subject
    capture_top*     : cint       ## Max current capture
    capture_last*    : cint       ## Most recently closed capture
    callout_data*    : pointer    ## Data passed in with the call
    # ------------------- Added for Version 1 --------------------------
    pattern_position*: cint       ## Offset to next item in the pattern
    next_item_length*: cint       ## Length of next item in the pattern
    # ------------------- Added for Version 2 --------------------------
    mark*            : pointer    ## Pointer to current mark or NULL
    # ------------------------------------------------------------------

when defined(nimHasStyleChecks):
  {.pop.}

# User defined callback which provides a stack just before the match starts.
type
  JitCallback* = proc (a: pointer): ptr JitStack {.cdecl.}


when not defined(usePcreHeader):
  when hostOS == "windows":
    when defined(nimOldDlls):
      const pcreDll = "pcre.dll"
    elif defined(cpu64):
      const pcreDll = "pcre64.dll"
    else:
      const pcreDll = "pcre32.dll"
  elif hostOS == "macosx":
    const pcreDll = "libpcre(.3|.1|).dylib"
  else:
    const pcreDll = "libpcre.so(.3|.1|)"
  {.push dynlib: pcreDll.}
else:
  {.push header: "<pcre.h>".}

{.push cdecl, importc: "pcre_$1".}

# Exported PCRE functions

proc compile*(pattern: cstring,
              options: cint,
              errptr: ptr cstring,
              erroffset: ptr cint,
              tableptr: pointer): ptr Pcre

proc compile2*(pattern: cstring,
               options: cint,
               errorcodeptr: ptr cint,
               errptr: ptr cstring,
               erroffset: ptr cint,
               tableptr: pointer): ptr Pcre

proc config*(what: cint,
             where: pointer): cint

proc copy_named_substring*(code: ptr Pcre,
                           subject: cstring,
                           ovector: ptr cint,
                           stringcount: cint,
                           stringname: cstring,
                           buffer: cstring,
                           buffersize: cint): cint

proc copy_substring*(subject: cstring,
                     ovector: ptr cint,
                     stringcount: cint,
                     stringnumber: cint,
                     buffer: cstring,
                     buffersize: cint): cint

proc dfa_exec*(code: ptr Pcre,
               extra: ptr ExtraData,
               subject: cstring,
               length: cint,
               startoffset: cint,
               options: cint,
               ovector: ptr cint,
               ovecsize: cint,
               workspace: ptr cint,
               wscount: cint): cint

proc exec*(code: ptr Pcre,
           extra: ptr ExtraData,
           subject: cstring,
           length: cint,
           startoffset: cint,
           options: cint,
           ovector: ptr cint,
           ovecsize: cint): cint

proc jit_exec*(code: ptr Pcre,
               extra: ptr ExtraData,
               subject: cstring,
               length: cint,
               startoffset: cint,
               options: cint,
               ovector: ptr cint,
               ovecsize: cint,
               jstack: ptr JitStack): cint

proc free_substring*(stringptr: cstring)

proc free_substring_list*(stringptr: cstringArray)

proc fullinfo*(code: ptr Pcre,
               extra: ptr ExtraData,
               what: cint,
               where: pointer): cint

proc get_named_substring*(code: ptr Pcre,
                          subject: cstring,
                          ovector: ptr cint,
                          stringcount: cint,
                          stringname: cstring,
                          stringptr: cstringArray): cint

proc get_stringnumber*(code: ptr Pcre,
                       name: cstring): cint

proc get_stringtable_entries*(code: ptr Pcre,
                              name: cstring,
                              first: cstringArray,
                              last: cstringArray): cint

proc get_substring*(subject: cstring,
                    ovector: ptr cint,
                    stringcount: cint,
                    stringnumber: cint,
                    stringptr: cstringArray): cint

proc get_substring_list*(subject: cstring,
                         ovector: ptr cint,
                         stringcount: cint,
                         listptr: ptr cstringArray): cint

proc maketables*(): pointer

proc refcount*(code: ptr Pcre,
               adjust: cint): cint

proc study*(code: ptr Pcre,
            options: cint,
            errptr: ptr cstring): ptr ExtraData

proc free_study*(extra: ptr ExtraData)

proc version*(): cstring

# Utility functions for byte order swaps.

proc pattern_to_host_byte_order*(code: ptr Pcre,
                                 extra: ptr ExtraData,
                                 tables: pointer): cint

# JIT compiler related functions.

proc jit_stack_alloc*(startsize: cint,
                      maxsize: cint): ptr JitStack

proc jit_stack_free*(stack: ptr JitStack)

proc assign_jit_stack*(extra: ptr ExtraData,
                       callback: JitCallback,
                       data: pointer)

proc jit_free_unused_memory*()


# There was an odd function with `var cstring` instead of `ptr`
proc study*(code: ptr Pcre,
            options: cint,
            errptr: var cstring): ptr ExtraData {.deprecated.}

{.pop.}
{.pop.}


type
  PPcre* {.deprecated.} = ptr Pcre
  PJitStack* {.deprecated.} = ptr JitStack
