#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This file was created by a complicated procedure which saved me a considerable
# amount of time: the pcre.h header was converted to modpcre.h by hand, so that
# h2pas could handle it. Then I used pas2mor to generate a Morpork binding.
# Unfortunately, I had to fix some things later on; thus don't do all this
# again! My manual changes will be lost!

# Converted by Pas2mor v1.37
#
#  Automatically converted by H2Pas 0.99.16 from modpcre.h
#  The following command line parameters were used:
#    -D -c -l pcre.lib -T modpcre.h

{.compile: "pcre_all.c" .}

type
  Pbyte = ptr byte
  Pchar = CString
  PPchar = ptr PChar
  Pint = ptr cint
  Ppcre* = ptr TPcre
  Ppcre_callout_block = ptr tpcre_callout_block
  Ppcre_extra = ptr Tpcre_extra

#************************************************
#*       Perl-Compatible Regular Expressions    *
#************************************************
#
#   Modified by Andreas Rumpf for h2pas.

# In its original form, this is the .in file that is transformed by
# "configure" into pcre.h.
#
#           Copyright (c) 1997-2005 University of Cambridge
#
# -----------------------------------------------------------------------------
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#    * Redistributions of source code must retain the above copyright notice,
#      this list of conditions and the following disclaimer.
#
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#
#    * Neither the name of the University of Cambridge nor the names of its
#      contributors may be used to endorse or promote products derived from
#      this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------

# The file pcre.h is build by "configure". Do not edit it; instead
# make changes to pcre.in.

const
  PCRE_MAJOR* = 6
  PCRE_MINOR* = 3
  PCRE_DATE* = "2005/11/29"
  # Options
  PCRE_CASELESS* = 0x00000001
  PCRE_MULTILINE* = 0x00000002
  PCRE_DOTALL* = 0x00000004
  PCRE_EXTENDED* = 0x00000008
  PCRE_ANCHORED* = 0x00000010
  PCRE_DOLLAR_ENDONLY* = 0x00000020
  PCRE_EXTRA* = 0x00000040
  PCRE_NOTBOL* = 0x00000080
  PCRE_NOTEOL* = 0x00000100
  PCRE_UNGREEDY* = 0x00000200
  PCRE_NOTEMPTY* = 0x00000400
  PCRE_UTF8* = 0x00000800
  PCRE_NO_AUTO_CAPTURE* = 0x00001000
  PCRE_NO_UTF8_CHECK* = 0x00002000
  PCRE_AUTO_CALLOUT* = 0x00004000
  PCRE_PARTIAL* = 0x00008000
  PCRE_DFA_SHORTEST* = 0x00010000
  PCRE_DFA_RESTART* = 0x00020000
  PCRE_FIRSTLINE* = 0x00040000
  # Exec-time and get/set-time error codes
  PCRE_ERROR_NOMATCH* = -(1)
  PCRE_ERROR_NULL* = -(2)
  PCRE_ERROR_BADOPTION* = -(3)
  PCRE_ERROR_BADMAGIC* = -(4)
  PCRE_ERROR_UNKNOWN_NODE* = -(5)
  PCRE_ERROR_NOMEMORY* = -(6)
  PCRE_ERROR_NOSUBSTRING* = -(7)
  PCRE_ERROR_MATCHLIMIT* = -(8)
  # Never used by PCRE itself
  PCRE_ERROR_CALLOUT* = -(9)
  PCRE_ERROR_BADUTF8* = -(10)
  PCRE_ERROR_BADUTF8_OFFSET* = -(11)
  PCRE_ERROR_PARTIAL* = -(12)
  PCRE_ERROR_BADPARTIAL* = -(13)
  PCRE_ERROR_INTERNAL* = -(14)
  PCRE_ERROR_BADCOUNT* = -(15)
  PCRE_ERROR_DFA_UITEM* = -(16)
  PCRE_ERROR_DFA_UCOND* = -(17)
  PCRE_ERROR_DFA_UMLIMIT* = -(18)
  PCRE_ERROR_DFA_WSSIZE* = -(19)
  PCRE_ERROR_DFA_RECURSE* = -(20)
  # Request types for pcre_fullinfo()
  PCRE_INFO_OPTIONS* = 0
  PCRE_INFO_SIZE* = 1
  PCRE_INFO_CAPTURECOUNT* = 2
  PCRE_INFO_BACKREFMAX* = 3
  PCRE_INFO_FIRSTBYTE* = 4
  # For backwards compatibility
  PCRE_INFO_FIRSTCHAR* = 4
  PCRE_INFO_FIRSTTABLE* = 5
  PCRE_INFO_LASTLITERAL* = 6
  PCRE_INFO_NAMEENTRYSIZE* = 7
  PCRE_INFO_NAMECOUNT* = 8
  PCRE_INFO_NAMETABLE* = 9
  PCRE_INFO_STUDYSIZE* = 10
  PCRE_INFO_DEFAULT_TABLES* = 11
  # Request types for pcre_config()
  PCRE_CONFIG_UTF8* = 0
  PCRE_CONFIG_NEWLINE* = 1
  PCRE_CONFIG_LINK_SIZE* = 2
  PCRE_CONFIG_POSIX_MALLOC_THRESHOLD* = 3
  PCRE_CONFIG_MATCH_LIMIT* = 4
  PCRE_CONFIG_STACKRECURSE* = 5
  PCRE_CONFIG_UNICODE_PROPERTIES* = 6
  # Bit flags for the pcre_extra structure
  PCRE_EXTRA_STUDY_DATA* = 0x0001
  PCRE_EXTRA_MATCH_LIMIT* = 0x0002
  PCRE_EXTRA_CALLOUT_DATA* = 0x0004
  PCRE_EXTRA_TABLES* = 0x0008
  # Types

type
  TPcre = record
  #undefined structure


  # The structure for passing additional data to pcre_exec(). This is defined
  # in such as way as to be extensible. Always add new fields at the end,
  # in order to remain compatible. 
  # Bits for which fields are set 
  # Opaque data from pcre_study()  
  # Maximum number of calls to match()  
  # Data passed back in callouts  
  # Const before type ignored 
  # Pointer to character tables  
  Tpcre_extra* {.final.} = object
    flags: cuint
    study_data: pointer
    match_limit: cuint
    callout_data: pointer
    tables: ptr byte

  # The structure for passing out data via the pcre_callout_function. We use a
  # structure so that new fields can be added on the end in future versions,
  # without changing the API of the function, thereby allowing old clients to
  # work without modification.  
  # Identifies version of block  
  # ------------------------ Version 0 -------------------------------  
  # Number compiled into pattern  
  # The offset vector  
  # Const before type ignored 
  # The subject being matched  
  # The length of the subject  
  # Offset to start of this match attempt  
  # Where we currently are in the subject  
  # Max current capture  
  # Most recently closed capture  
  # Data passed in with the call  
  # ------------------- Added for Version 1 --------------------------  
  # Offset to next item in the pattern  
  # Length of next item in the pattern  
  # ------------------------------------------------------------------  
  TPcre_callout_block* {.final.} = object
    version: cint
    callout_number: cint
    offset_vector: ptr cint
    subject: ptr char
    subject_length: cint
    start_match: cint
    current_position: cint
    capture_top: cint
    capture_last: cint
    callout_data: pointer
    pattern_position: cint
    next_item_length: cint

# Exported PCRE functions  

proc pcre_compile*(para1: Pchar, para2: cint, para3: ptr Pchar,
                  para4: Pint, para5: Pbyte): Ppcre {.
                  importc: "pcre_compile", noconv.}

proc pcre_compile2*(para1: Pchar, para2: cint, para3: Pint, para4: PPchar,
                   para5: Pint, para6: Pbyte): Ppcre {. 
                   importc: "pcre_compile2", noconv.}

proc pcre_config*(para1: cint, para2: pointer): cint {.
  importc: "pcre_config", noconv.}

proc pcre_copy_named_substring*(para1: Ppcre, para2: Pchar, para3: Pint,
                               para4: cint, para5: Pchar, para6: Pchar,
                               para7: cint): cint {.
                               importc: "pcre_copy_named_substring", noconv.}

proc pcre_copy_substring*(para1: Pchar, para2: Pint, para3: cint, para4: cint,
                         para5: Pchar, para6: cint): cint {.
                         importc: "pcre_copy_substring", noconv.}

proc pcre_dfa_exec*(para1: Ppcre, para2: Ppcre_extra, para3: Pchar,
                   para4: cint, para5: cint, para6: cint, para7: Pint,
                   para8: cint, para9: Pint, para10: cint): cint {.
                   importc: "pcre_dfa_exec", noconv.}

proc pcre_exec*(para1: Ppcre, para2: Ppcre_extra, para3: Pchar,
               para4: cint, para5: cint, para6: cint, para7: Pint,
               para8: cint): cint {.importc: "pcre_exec", noconv.}

proc pcre_free_substring*(para1: Pchar) {.
  importc: "pcre_free_substring", noconv.}

proc pcre_free_substring_list*(para1: PPchar) {.
  importc: "pcre_free_substring_list", noconv.}

proc pcre_fullinfo*(para1: Ppcre, para2: Ppcre_extra, para3: cint,
                   para4: pointer): cint {.importc: "pcre_fullinfo", noconv.}

proc pcre_get_named_substring*(para1: Ppcre, para2: Pchar, para3: Pint,
                              para4: cint, para5: Pchar, para6: PPchar): cint {.
                              importc: "pcre_get_named_substring", noconv.}

proc pcre_get_stringnumber*(para1: Ppcre, para2: Pchar): cint {.
  importc: "pcre_get_stringnumber", noconv.}

proc pcre_get_substring*(para1: Pchar, para2: Pint, para3: cint,
                        para4: cint, para5: PPchar): cint {.
                        importc: "pcre_get_substring", noconv.}

proc pcre_get_substring_list*(para1: Pchar, para2: Pint, para3: cint,
                             para4: ptr PPchar): cint {.
                             importc: "pcre_get_substring_list", noconv.}

proc pcre_info*(para1: Ppcre, para2: Pint, para3: Pint): cint {.
  importc: "pcre_info", noconv.}

proc pcre_maketables*: ptr byte {.
  importc: "pcre_maketables", noconv.}

proc pcre_refcount*(para1: Ppcre, para2: cint): cint {.
  importc: "pcre_refcount", noconv.}

proc pcre_study*(para1: Ppcre, para2: cint,
                 para3: ptr CString): Ppcre_extra {.importc, noconv.}

proc pcre_version*: CString {.importc: "pcre_version", noconv.}

# Indirection for store get and free functions. These can be set to
# alternative malloc/free functions if required. Special ones are used in the
# non-recursive case for "frames". There is also an optional callout function
# that is triggered by the (?) regex item.
#

# we use Nimrod's memory manager (but not GC!) for these functions:
var
  pcre_malloc {.importc: "pcre_malloc".}: proc (para1: int): pointer {.noconv.}
  pcre_free {.importc: "pcre_free".}: proc (para1: pointer) {.noconv.}
  pcre_stack_malloc {.importc: "pcre_stack_malloc".}:
    proc (para1: int): pointer {.noconv.}
  pcre_stack_free  {.importc: "pcre_stack_free".}:
    proc (para1: pointer) {.noconv.}
  pcre_callout {.importc: "pcre_callout".}:
    proc (para1: Ppcre_callout_block): cint {.noconv.}

pcre_malloc = system.alloc
pcre_free = system.dealloc
pcre_stack_malloc = system.alloc
pcre_stack_free = system.dealloc
pcre_callout = nil
