when defined(pcreDynlib):
  const pcreHeader = "<pcre.h>"
  when not defined(pcreDll):
    when hostOS == "windows":
      const pcreDll = "pcre.dll"
    elif hostOS == "macosx":
      const pcreDll = "libpcre(.3|.1|).dylib"
    else:
      const pcreDll = "libpcre.so(.3|.1|)"
    {.pragma: pcreImport, dynlib: pcreDll.}
  else:
    {.pragma: pcreImport, header: pcreHeader.}
else:
  {. passC: "-DHAVE_CONFIG_H", passC: "-I private/pcre_src",
     passL: "-I private/pcre_src" .}
  {. compile: "private/pcre_src/pcre_byte_order.c" .}
  {. compile: "private/pcre_src/pcre_compile.c" .}
  {. compile: "private/pcre_src/pcre_config.c" .}
  {. compile: "private/pcre_src/pcre_dfa_exec.c" .}
  {. compile: "private/pcre_src/pcre_exec.c" .}
  {. compile: "private/pcre_src/pcre_fullinfo.c" .}
  {. compile: "private/pcre_src/pcre_get.c" .}
  {. compile: "private/pcre_src/pcre_globals.c" .}
  {. compile: "private/pcre_src/pcre_jit_compile.c" .}
  {. compile: "private/pcre_src/pcre_maketables.c" .}
  {. compile: "private/pcre_src/pcre_newline.c" .}
  {. compile: "private/pcre_src/pcre_ord2utf8.c" .}
  {. compile: "private/pcre_src/pcre_refcount.c" .}
  {. compile: "private/pcre_src/pcre_string_utils.c" .}
  {. compile: "private/pcre_src/pcre_study.c" .}
  {. compile: "private/pcre_src/pcre_tables.c" .}
  {. compile: "private/pcre_src/pcre_ucd.c" .}
  {. compile: "private/pcre_src/pcre_valid_utf8.c" .}
  {. compile: "private/pcre_src/pcre_version.c" .}
  {. compile: "private/pcre_src/pcre_xclass.c" .}
  {. compile: "private/pcre_src/pcre_chartables.c" .}

  const pcreHeader = "pcre.h"
  {.pragma: pcreImport, header: pcreHeader.}

#************************************************
#       Perl-Compatible Regular Expressions      *
#***********************************************
# This is the public header file for the Pcre library, to be #included by
#applications that call the Pcre functions.
#
#           Copyright (c) 1997-2014 University of Cambridge
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
# The current Pcre version information. 


const 
  MAJOR* = 8
  MINOR* = 36
  PRERELEASE* = true
  DATE* = 2014 - 9 - 26

# When an application links to a Pcre DLL in Windows, the symbols that are
#imported have to be identified as such. When building PCRE, the appropriate
#export setting is defined in pcre_internal.h, which includes this file. So we
#don't change existing definitions of PCRE_EXP_DECL and PCRECPP_EXP_DECL. 
# By default, we use the standard "extern" declarations. 
# Have to include stdlib.h in order to ensure that size_t is defined;
#it is needed here for malloc. 

# Allow for C++ users 
# Public options. Some are compile-time only, some are run-time only, and some
#are both. Most of the compile-time options are saved with the compiled regex so
#that they can be inspected during studying (and therefore JIT compiling). Note
#that pcre_study() has its own set of options. Originally, all the options
#defined here used distinct bits. However, almost all the bits in a 32-bit word
#are now used, so in order to conserve them, option bits that were previously
#only recognized at matching time (i.e. by pcre_exec() or pcre_dfa_exec()) may
#also be used for compile-time options that affect only compiling and are not
#relevant for studying or JIT compiling.
#
#Some options for pcre_compile() change its behaviour but do not affect the
#behaviour of the execution functions. Other options are passed through to the
#execution functions and affect their behaviour, with or without affecting the
#behaviour of pcre_compile().
#
#Options that can be passed to pcre_compile() are tagged Cx below, with these
#variants:
#
#C1   Affects compile only
#C2   Does not affect compile; affects exec, dfa_exec
#C3   Affects compile, exec, dfa_exec
#C4   Affects compile, exec, dfa_exec, study
#C5   Affects compile, exec, study
#
#Options that can be set for pcre_exec() and/or pcre_dfa_exec() are flagged with
#E and D, respectively. They take precedence over C3, C4, and C5 settings passed
#from pcre_compile(). Those that are compatible with JIT execution are flagged
#with J. 

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
  UTF16* = 0x00000800
  UTF32* = 0x00000800
  NO_AUTO_CAPTURE* = 0x00001000
  NO_UTF8_CHECK* = 0x00002000
  NO_UTF16_CHECK* = 0x00002000
  NO_UTF32_CHECK* = 0x00002000
  AUTO_CALLOUT* = 0x00004000
  PARTIAL_SOFT* = 0x00008000
  PARTIAL* = 0x00008000

# This pair use the same bit. 

const 
  NEVER_UTF* = 0x00010000
  DFA_SHORTEST* = 0x00010000

# This pair use the same bit. 

const 
  NO_AUTO_POSSESS* = 0x00020000
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
  ERROR_CALLOUT* = (- 9)      # Never used by Pcre itself 
  ERROR_BADUTF8* = (- 10)     # Same for 8/16/32 
  ERROR_BADUTF16* = (- 10)    # Same for 8/16/32 
  ERROR_BADUTF32* = (- 10)    # Same for 8/16/32 
  ERROR_BADUTF8_OFFSET* = (- 11) # Same for 8/16 
  ERROR_BADUTF16_OFFSET* = (- 11) # Same for 8/16 
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
  ERROR_SHORTUTF16* = (- 25)  # Same for 8/16 
  ERROR_RECURSELOOP* = (- 26)
  ERROR_JIT_STACKLIMIT* = (- 27)
  ERROR_BADMODE* = (- 28)
  ERROR_BADENDIANNESS* = (- 29)
  ERROR_DFA_BADRESTART* = (- 30)
  ERROR_JIT_BADOPTION* = (- 31)
  ERROR_BADLENGTH* = (- 32)
  ERROR_UNSET* = (- 33)

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
  UTF8_ERR22* = 22

# Specific error codes for UTF-16 validity checks 

const 
  UTF16_ERR0* = 0
  UTF16_ERR1* = 1
  UTF16_ERR2* = 2
  UTF16_ERR3* = 3
  UTF16_ERR4* = 4

# Specific error codes for UTF-32 validity checks 

const 
  UTF32_ERR0* = 0
  UTF32_ERR1* = 1
  UTF32_ERR2* = 2
  UTF32_ERR3* = 3

# Request types for pcre_fullinfo() 

const 
  INFO_OPTIONS* = 0
  INFO_SIZE* = 1
  INFO_CAPTURECOUNT* = 2
  INFO_BACKREFMAX* = 3
  INFO_FIRSTBYTE* = 4
  INFO_FIRSTCHAR* = 4
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
  INFO_FIRSTCHARACTER* = 19
  INFO_FIRSTCHARACTERFLAGS* = 20
  INFO_REQUIREDCHAR* = 21
  INFO_REQUIREDCHARFLAGS* = 22
  INFO_MATCHLIMIT* = 23
  INFO_RECURSIONLIMIT* = 24
  INFO_MATCH_EMPTY* = 25

# Request types for pcre_config(). Do not re-arrange, in order to remain
#compatible. 

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
  CONFIG_UTF16* = 10
  CONFIG_JITTARGET* = 11
  CONFIG_UTF32* = 12
  CONFIG_PARENS_LIMIT* = 13

# Request types for pcre_study(). Do not re-arrange, in order to remain
#compatible. 

const 
  STUDY_JIT_COMPILE* = 0x00000001
  STUDY_JIT_PARTIAL_SOFT_COMPILE* = 0x00000002
  STUDY_JIT_PARTIAL_HARD_COMPILE* = 0x00000004
  STUDY_EXTRA_NEEDED* = 0x00000008

# Bit flags for the pcre[16|32]_extra structure. Do not re-arrange or redefine
#these bits, just add new ones on the end, in order to remain compatible. 

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
  Pcre* = object
  Pcre16* = object
  Pcre32* = object
  jit_stack* = object
  jit_stack16* = object
  jit_stack32* = object

# The structure for passing additional data to pcre_exec(). This is defined in
#such as way as to be extensible. Always add new fields at the end, in order to
#remain compatible. 

type 
  ExtraData* {.importc: "pcre_extra", header: "pcre.h".} = object 
    flags* {.importc: "flags".}: culong # Bits for which fields are set 
    study_data* {.importc: "study_data".}: pointer # Opaque data from pcre_study() 
    match_limit* {.importc: "match_limit".}: culong # Maximum number of calls to match() 
    callout_data* {.importc: "callout_data".}: pointer # Data passed back in callouts 
    tables* {.importc: "tables".}: ptr cuchar # Pointer to character tables 
    match_limit_recursion* {.importc: "match_limit_recursion".}: culong # Max 
                                                                        # recursive calls to match() 
    mark* {.importc: "mark".}: ptr ptr cuchar # For passing back a mark pointer 
    executable_jit* {.importc: "executable_jit".}: pointer # Contains a pointer to a compiled jit code 

# The structure for passing out data via the pcre_callout_function. We use a
#structure so that new fields can be added on the end in future versions,
#without changing the API of the function, thereby allowing old clients to work
#without modification. 

type 
  callout_block* {.importc: "pcre_callout_block", header: pcreHeader.} = object 
    version* {.importc: "version".}: cint # Identifies version of block 
                                          # ------------------------ Version 0 ------------------------------- 
    callout_number* {.importc: "callout_number".}: cint # Number compiled into pattern 
    offset_vector* {.importc: "offset_vector".}: ptr cint # The offset vector 
    subject* {.importc: "subject".}: cstring # The subject being matched 
    subject_length* {.importc: "subject_length".}: cint # The length of the subject 
    start_match* {.importc: "start_match".}: cint # Offset to start of this match attempt 
    current_position* {.importc: "current_position".}: cint # Where we currently are in the subject 
    capture_top* {.importc: "capture_top".}: cint # Max current capture 
    capture_last* {.importc: "capture_last".}: cint # Most recently closed capture 
    callout_data* {.importc: "callout_data".}: pointer # Data passed in with the call 
                                                       # ------------------- Added for Version 1 
                                                       # -------------------------- 
    pattern_position* {.importc: "pattern_position".}: cint # Offset to next item in the pattern 
    next_item_length* {.importc: "next_item_length".}: cint # Length of next item in the pattern 
                                                            # ------------------- Added for Version 2 
                                                            # -------------------------- 
    mark* {.importc: "mark".}: ptr cuchar # Pointer to current mark or NULL    
                                          # 
                                          # ------------------------------------------------------------------ 
# Indirection for store get and free functions. These can be set to
#alternative malloc/free functions if required. Special ones are used in the
#non-recursive case for "frames". There is also an optional callout function
#that is triggered by the (?) regex item. For Virtual Pascal, these definitions
#have to take another form. 

proc malloc*(a2: csize): pointer {.cdecl, importc: "pcre_malloc", pcreImport.}
proc free*(a2: pointer) {.cdecl, importc: "pcre_free", pcreImport.}
proc stack_malloc*(a2: csize): pointer {.cdecl, importc: "pcre_stack_malloc", pcreImport.}
proc stack_free*(a2: pointer) {.cdecl, importc: "pcre_free", pcreImport.}
proc callout*(a2: ptr callout_block): cint {.cdecl, importc: "pcre_callout", pcreImport.}
proc stack_guard*(): cint {.cdecl, importc: "pcre_stack_guard", pcreImport.}

# User defined callback which provides a stack just before the match starts. 

type 
  jit_callback* = proc (a2: pointer): ptr jit_stack {.cdecl.}

# Exported Pcre functions 

proc compile*(a2: cstring; a3: cint; a4: ptr cstring; a5: ptr cint; 
              a6: ptr cuchar): ptr Pcre {.cdecl, importc: "pcre_compile", 
    pcreImport.}
proc compile2*(a2: cstring; a3: cint; a4: ptr cint; a5: ptr cstring; 
               a6: ptr cint; a7: ptr cuchar): ptr Pcre {.cdecl, 
    importc: "pcre_compile2", pcreImport.}
proc config*(a2: cint; a3: pointer): cint {.cdecl, importc: "pcre_config", 
    pcreImport.}
proc copy_named_substring*(a2: ptr Pcre; a3: cstring; a4: ptr cint; a5: cint; 
                           a6: cstring; a7: cstring; a8: cint): cint {.cdecl, 
    importc: "pcre_copy_named_substring", pcreImport.}
proc copy_substring*(a2: cstring; a3: ptr cint; a4: cint; a5: cint; a6: cstring; 
                     a7: cint): cint {.cdecl, importc: "pcre_copy_substring", 
                                       pcreImport.}
proc dfa_exec*(a2: ptr Pcre; a3: ptr ExtraData; a4: cstring; a5: cint; a6: cint; 
               a7: cint; a8: ptr cint; a9: cint; a10: ptr cint; a11: cint): cint {.
    cdecl, importc: "pcre_dfa_exec", pcreImport.}
proc exec*(a2: ptr Pcre; a3: ptr ExtraData; a4: cstring; a5: cint; a6: cint; a7: cint; 
           a8: ptr cint; a9: cint): cint {.cdecl, importc: "pcre_exec", 
    pcreImport.}
proc jit_exec*(a2: ptr Pcre; a3: ptr ExtraData; a4: cstring; a5: cint; a6: cint; 
               a7: cint; a8: ptr cint; a9: cint; a10: ptr jit_stack): cint {.
    cdecl, importc: "pcre_jit_exec", pcreImport.}
proc free_substring*(a2: cstring) {.cdecl, importc: "pcre_free_substring", 
                                    pcreImport.}
proc free_substring_list*(a2: ptr cstring) {.cdecl, 
    importc: "pcre_free_substring_list", pcreImport.}
proc fullinfo*(a2: ptr Pcre; a3: ptr ExtraData; a4: cint; a5: pointer): cint {.
    cdecl, importc: "pcre_fullinfo", pcreImport.}
proc get_named_substring*(a2: ptr Pcre; a3: cstring; a4: ptr cint; a5: cint; 
                          a6: cstring; a7: cstringArray): cint {.cdecl, 
    importc: "pcre_get_named_substring", pcreImport.}
proc get_stringnumber*(a2: ptr Pcre; a3: cstring): cint {.cdecl, 
    importc: "pcre_get_stringnumber", pcreImport.}
proc get_stringtable_entries*(a2: ptr Pcre; a3: cstring; a4: cstringArray; 
                              a5: cstringArray): cint {.cdecl, 
    importc: "pcre_get_stringtable_entries", pcreImport.}
proc get_substring*(a2: cstring; a3: ptr cint; a4: cint; a5: cint; 
                    a6: cstringArray): cint {.cdecl, 
    importc: "pcre_get_substring", pcreImport.}
proc get_substring_list*(a2: cstring; a3: ptr cint; a4: cint; 
                         a5: ptr cstringArray): cint {.cdecl, 
    importc: "pcre_get_substring_list", pcreImport.}
proc maketables*(): ptr cuchar {.cdecl, importc: "pcre_maketables", 
                                 pcreImport.}
proc refcount*(a2: ptr Pcre; a3: cint): cint {.cdecl, importc: "pcre_refcount", 
    pcreImport.}
proc study*(a2: ptr Pcre; a3: cint; a4: ptr cstring): ptr ExtraData {.cdecl, 
    importc: "pcre_study", pcreImport.}
proc free_study*(a2: ptr ExtraData) {.cdecl, importc: "pcre_free_study", 
                                  pcreImport.}
proc version*(): cstring {.cdecl, importc: "pcre_version", pcreImport.}
# Utility functions for byte order swaps. 

proc pattern_to_host_byte_order*(a2: ptr Pcre; a3: ptr ExtraData; a4: ptr cuchar): cint {.
    cdecl, importc: "pcre_pattern_to_host_byte_order", pcreImport.}
# JIT compiler related functions. 

proc jit_stack_alloc*(a2: cint; a3: cint): ptr jit_stack {.cdecl, 
    importc: "pcre_jit_stack_alloc", pcreImport.}
proc jit_stack_free*(a2: ptr jit_stack) {.cdecl, importc: "pcre_jit_stack_free", 
    pcreImport.}
proc assign_jit_stack*(a2: ptr ExtraData; a3: jit_callback; a4: pointer) {.cdecl, 
    importc: "pcre_assign_jit_stack", pcreImport.}
proc jit_free_unused_memory*() {.cdecl, importc: "pcre_jit_free_unused_memory", 
                                 pcreImport.}
