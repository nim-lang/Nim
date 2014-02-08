#************************************************
#       Perl-Compatible Regular Expressions      *
#***********************************************
# This is the public header file for the PCRE library, to be #included by
#applications that call the PCRE functions.
#
#           Copyright (c) 1997-2010 University of Cambridge
#
#-----------------------------------------------------------------------------
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are met:
#
#     Redistributions of source code must retain the above copyright notice,
#      this list of conditions and the following disclaimer.
#
#     Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#
#     Neither the name of the University of Cambridge nor the names of its
#      contributors may be used to endorse or promote products derived from
#      this software without specific prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#POSSIBILITY OF SUCH DAMAGE.
#-----------------------------------------------------------------------------
#

{.deadcodeElim: on.}

when not defined(pcreDll):
  when hostOS == "windows":
    const pcreDll = "pcre.dll"
  elif hostOS == "macosx":
    const pcreDll = "libpcre(.3|.1|).dylib"
  else:
    const pcreDll = "libpcre.so(.3|.1|)"
  {.pragma: pcreImport, dynlib: pcreDll.}
else:
  {.pragma: pcreImport, header: "<pcre.h>".}

# The current PCRE version information. 

const 
  MAJOR* = 8
  MINOR* = 31
  PRERELEASE* = true
  DATE* = "2012-07-06"

# When an application links to a PCRE DLL in Windows, the symbols that are
# imported have to be identified as such. When building PCRE, the appropriate
# export setting is defined in pcre_internal.h, which includes this file. So we
# don't change existing definitions of PCRE_EXP_DECL and PCRECPP_EXP_DECL. 

# Have to include stdlib.h in order to ensure that size_t is defined;
# it is needed here for malloc. 

# Allow for C++ users 

# Options. Some are compile-time only, some are run-time only, and some are
# both, so we keep them all distinct. 

const 
  CASELESS* = 0x00000001
  MULTILINE* = 0x00000002
  DOTALL* = 0x00000004
  EXTENDED* = 0x00000008
  ANCHORED* = 0x00000010
  DOLLAR_ENDONLY* = 0x00000020
  EXTRA* = 0x00000040
  NOTBOL* = 0x00000080
  NOTEOL* = 0x00000100
  UNGREEDY* = 0x00000200
  NOTEMPTY* = 0x00000400
  UTF8* = 0x00000800
  NO_AUTO_CAPTURE* = 0x00001000
  NO_UTF8_CHECK* = 0x00002000
  AUTO_CALLOUT* = 0x00004000
  PARTIAL_SOFT* = 0x00008000
  PARTIAL* = 0x00008000       # Backwards compatible synonym 
  DFA_SHORTEST* = 0x00010000
  DFA_RESTART* = 0x00020000
  FIRSTLINE* = 0x00040000
  DUPNAMES* = 0x00080000
  NEWLINE_CR* = 0x00100000
  NEWLINE_LF* = 0x00200000
  NEWLINE_CRLF* = 0x00300000
  NEWLINE_ANY* = 0x00400000
  NEWLINE_ANYCRLF* = 0x00500000
  BSR_ANYCRLF* = 0x00800000
  BSR_UNICODE* = 0x01000000
  JAVASCRIPT_COMPAT* = 0x02000000
  NO_START_OPTIMIZE* = 0x04000000
  NO_START_OPTIMISE* = 0x04000000
  PARTIAL_HARD* = 0x08000000
  NOTEMPTY_ATSTART* = 0x10000000
  UCP* = 0x20000000

# Exec-time and get/set-time error codes 

const 
  ERROR_NOMATCH* = (- 1)
  ERROR_NULL* = (- 2)
  ERROR_BADOPTION* = (- 3)
  ERROR_BADMAGIC* = (- 4)
  ERROR_UNKNOWN_OPCODE* = (- 5)
  ERROR_UNKNOWN_NODE* = (- 5) # For backward compatibility 
  ERROR_NOMEMORY* = (- 6)
  ERROR_NOSUBSTRING* = (- 7)
  ERROR_MATCHLIMIT* = (- 8)
  ERROR_CALLOUT* = (- 9)      # Never used by PCRE itself 
  ERROR_BADUTF8* = (- 10)
  ERROR_BADUTF8_OFFSET* = (- 11)
  ERROR_PARTIAL* = (- 12)
  ERROR_BADPARTIAL* = (- 13)
  ERROR_INTERNAL* = (- 14)
  ERROR_BADCOUNT* = (- 15)
  ERROR_DFA_UITEM* = (- 16)
  ERROR_DFA_UCOND* = (- 17)
  ERROR_DFA_UMLIMIT* = (- 18)
  ERROR_DFA_WSSIZE* = (- 19)
  ERROR_DFA_RECURSE* = (- 20)
  ERROR_RECURSIONLIMIT* = (- 21)
  ERROR_NULLWSLIMIT* = (- 22) # No longer actually used 
  ERROR_BADNEWLINE* = (- 23)
  ERROR_BADOFFSET* = (- 24)
  ERROR_SHORTUTF8* = (- 25)
  ERROR_RECURSELOOP* = (- 26)
  ERROR_JIT_STACKLIMIT* = (- 27)
  ERROR_BADMODE* = (- 28)
  ERROR_BADENDIANNESS* = (- 29)
  ERROR_DFA_BADRESTART* = (- 30)

# Specific error codes for UTF-8 validity checks

const
  UTF8_ERR0* = 0
  UTF8_ERR1* = 1
  UTF8_ERR2* = 2
  UTF8_ERR3* = 3
  UTF8_ERR4* = 4
  UTF8_ERR5* = 5
  UTF8_ERR6* = 6
  UTF8_ERR7* = 7
  UTF8_ERR8* = 8
  UTF8_ERR9* = 9
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

# Request types for pcre_fullinfo() 

const 
  INFO_OPTIONS* = 0
  INFO_SIZE* = 1
  INFO_CAPTURECOUNT* = 2
  INFO_BACKREFMAX* = 3
  INFO_FIRSTBYTE* = 4
  INFO_FIRSTCHAR* = 4         # For backwards compatibility 
  INFO_FIRSTTABLE* = 5
  INFO_LASTLITERAL* = 6
  INFO_NAMEENTRYSIZE* = 7
  INFO_NAMECOUNT* = 8
  INFO_NAMETABLE* = 9
  INFO_STUDYSIZE* = 10
  INFO_DEFAULT_TABLES* = 11
  INFO_OKPARTIAL* = 12
  INFO_JCHANGED* = 13
  INFO_HASCRORLF* = 14
  INFO_MINLENGTH* = 15
  INFO_JIT* = 16
  INFO_JITSIZE* = 17
  INFO_MAXLOOKBEHIND* = 18

# Request types for pcre_config(). Do not re-arrange, in order to remain
# compatible. 

const 
  CONFIG_UTF8* = 0
  CONFIG_NEWLINE* = 1
  CONFIG_LINK_SIZE* = 2
  CONFIG_POSIX_MALLOC_THRESHOLD* = 3
  CONFIG_MATCH_LIMIT* = 4
  CONFIG_STACKRECURSE* = 5
  CONFIG_UNICODE_PROPERTIES* = 6
  CONFIG_MATCH_LIMIT_RECURSION* = 7
  CONFIG_BSR* = 8
  CONFIG_JIT* = 9
  CONFIG_JITTARGET* = 11

# Request types for pcre_study(). Do not re-arrange, in order to remain
# compatible.

const
  STUDY_JIT_COMPILE* = 0x00000001
  STUDY_JIT_PARTIAL_SOFT_COMPILE* = 0x00000002
  STUDY_JIT_PARTIAL_HARD_COMPILE* = 0x00000004

# Bit flags for the pcre_extra structure. Do not re-arrange or redefine
# these bits, just add new ones on the end, in order to remain compatible. 

const 
  EXTRA_STUDY_DATA* = 0x00000001
  EXTRA_MATCH_LIMIT* = 0x00000002
  EXTRA_CALLOUT_DATA* = 0x00000004
  EXTRA_TABLES* = 0x00000008
  EXTRA_MATCH_LIMIT_RECURSION* = 0x00000010
  EXTRA_MARK* = 0x00000020
  EXTRA_EXECUTABLE_JIT* = 0x00000040

# Types 

type 
  TPcre*{.pure, final.} = object
  PPcre* = ptr TPcre
  Tjit_stack*{.pure, final.} = object
  Pjit_stack* = ptr Tjit_stack

# When PCRE is compiled as a C++ library, the subject pointer type can be
# replaced with a custom type. For conventional use, the public interface is a
# const char *. 

# The structure for passing additional data to pcre_exec(). This is defined in
# such as way as to be extensible. Always add new fields at the end, in order to
# remain compatible. 

type 
  TExtra*{.pure, final.} = object 
    flags*: int                 ## Bits for which fields are set 
    study_data*: pointer        ## Opaque data from pcre_study() 
    match_limit*: int           ## Maximum number of calls to match() 
    callout_data*: pointer      ## Data passed back in callouts 
    tables*: cstring            ## Pointer to character tables 
    match_limit_recursion*: int ## Max recursive calls to match() 
    mark*: ptr cstring          ## For passing back a mark pointer 
    executable_jit*: pointer    ## Contains a pointer to a compiled jit code
  

# The structure for passing out data via the pcre_callout_function. We use a
# structure so that new fields can be added on the end in future versions,
# without changing the API of the function, thereby allowing old clients to work
# without modification. 

type 
  TCalloutBlock*{.pure, final.} = object 
    version*: cint            ## Identifies version of block 
    callout_number*: cint     ## Number compiled into pattern 
    offset_vector*: ptr cint  ## The offset vector 
    subject*: cstring         ## The subject being matched 
    subject_length*: cint     ## The length of the subject 
    start_match*: cint        ## Offset to start of this match attempt 
    current_position*: cint   ## Where we currently are in the subject 
    capture_top*: cint        ## Max current capture 
    capture_last*: cint       ## Most recently closed capture 
    callout_data*: pointer    ## Data passed in with the call 
    pattern_position*: cint   ## Offset to next item in the pattern 
    next_item_length*: cint   ## Length of next item in the pattern
    mark*: cstring            ## Pointer to current mark or NULL

# Indirection for store get and free functions. These can be set to
#alternative malloc/free functions if required. Special ones are used in the
#non-recursive case for "frames". There is also an optional callout function
#that is triggered by the (?) regex item. For Virtual Pascal, these definitions
#have to take another form.

# User defined callback which provides a stack just before the match starts.

type
  TJitCallback* = proc(p: pointer): ptr Tjit_stack{.cdecl.}

# Exported PCRE functions 

proc compile*(a2: cstring, a3: cint, a4: ptr cstring, a5: ptr cint, 
              a6: ptr char): ptr TPcre{.cdecl, importc: "pcre_compile", 
    pcreImport.}
proc compile2*(a2: cstring, a3: cint, a4: ptr cint, a5: ptr cstring, 
               a6: ptr cint, a7: ptr char): ptr TPcre{.cdecl, 
    importc: "pcre_compile2", pcreImport.}
proc config*(a2: cint, a3: pointer): cint{.cdecl, importc: "pcre_config", 
    pcreImport.}
proc copy_named_substring*(a2: ptr TPcre, a3: cstring, a4: ptr cint, a5: cint, 
                           a6: cstring, a7: cstring, a8: cint): cint{.cdecl, 
    importc: "pcre_copy_named_substring", pcreImport.}
proc copy_substring*(a2: cstring, a3: ptr cint, a4: cint, a5: cint, 
                     a6: cstring, 
                     a7: cint): cint{.cdecl, importc: "pcre_copy_substring", 
                                      pcreImport.}
proc dfa_exec*(a2: ptr TPcre, a3: ptr TExtra, a4: cstring, a5: cint, 
               a6: cint, a7: cint, a8: ptr cint, a9: cint, a10: ptr cint, 
               a11: cint): cint{.cdecl, importc: "pcre_dfa_exec", 
                                 pcreImport.}
proc exec*(a2: ptr TPcre, a3: ptr TExtra, a4: cstring, a5: cint, a6: cint, 
           a7: cint, a8: ptr cint, a9: cint): cint {.
           cdecl, importc: "pcre_exec", pcreImport.}
proc free_substring*(a2: cstring){.cdecl, importc: "pcre_free_substring", 
                                   pcreImport.}
proc free_substring_list*(a2: cstringArray){.cdecl, 
    importc: "pcre_free_substring_list", pcreImport.}
proc fullinfo*(a2: ptr TPcre, a3: ptr TExtra, a4: cint, a5: pointer): cint{.
    cdecl, importc: "pcre_fullinfo", pcreImport.}
proc get_named_substring*(a2: ptr TPcre, a3: cstring, a4: ptr cint, a5: cint, 
                          a6: cstring, a7: cstringArray): cint{.cdecl, 
    importc: "pcre_get_named_substring", pcreImport.}
proc get_stringnumber*(a2: ptr TPcre, a3: cstring): cint{.cdecl, 
    importc: "pcre_get_stringnumber", pcreImport.}
proc get_stringtable_entries*(a2: ptr TPcre, a3: cstring, a4: cstringArray, 
                              a5: cstringArray): cint{.cdecl, 
    importc: "pcre_get_stringtable_entries", pcreImport.}
proc get_substring*(a2: cstring, a3: ptr cint, a4: cint, a5: cint, 
                    a6: cstringArray): cint{.cdecl, 
    importc: "pcre_get_substring", pcreImport.}
proc get_substring_list*(a2: cstring, a3: ptr cint, a4: cint, 
                         a5: ptr cstringArray): cint{.cdecl, 
    importc: "pcre_get_substring_list", pcreImport.}
proc maketables*(): ptr char{.cdecl, importc: "pcre_maketables", 
                                       pcreImport.}
proc refcount*(a2: ptr TPcre, a3: cint): cint{.cdecl, importc: "pcre_refcount", 
    pcreImport.}
proc study*(a2: ptr TPcre, a3: cint, a4: var cstring): ptr TExtra{.cdecl, 
    importc: "pcre_study", pcreImport.}
proc version*(): cstring{.cdecl, importc: "pcre_version", pcreImport.}

# Utility functions for byte order swaps.

proc pattern_to_host_byte_order*(a2: ptr TPcre, a3: ptr TExtra,
    a4: ptr char): cint{.cdecl, importc: "pcre_pattern_to_host_byte_order",
    pcreImport.}

# JIT compiler related functions.

proc jit_stack_alloc*(a2: cint, a3: cint): ptr Tjit_stack{.cdecl,
    importc: "pcre_jit_stack_alloc", pcreImport.}
proc jit_stack_free*(a2: ptr Tjit_stack){.cdecl, importc: "pcre_jit_stack_free",
    pcreImport.}
proc assign_jit_stack*(a2: ptr TExtra, a3: TJitCallback, a4: pointer){.cdecl,
    importc: "pcre_assign_jit_stack", pcreImport.}

var 
  pcre_free*: proc (p: ptr TPcre) {.cdecl.} 
