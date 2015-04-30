# history.h -- the names of functions that you can call in history. 
# Copyright (C) 1989-2009 Free Software Foundation, Inc.
#
#   This file contains the GNU History Library (History), a set of
#   routines for managing the text of previously typed lines.
#
#   History is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   History is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with History.  If not, see <http://www.gnu.org/licenses/>.
#

{.deadCodeElim: on.}

import readline

const 
  historyDll = readlineDll

import times, rltypedefs

type 
  Thistdata* = pointer

# The structure used to store a history entry. 

type 
  THIST_ENTRY*{.pure, final.} = object 
    line*: cstring
    timestamp*: cstring       # char * rather than time_t for read/write 
    data*: Thistdata


# Size of the history-library-managed space in history entry HS. 

template HISTENT_BYTES*(hs: expr): expr = 
  (strlen(hs.line) + strlen(hs.timestamp))

# A structure used to pass the current state of the history stuff around. 

type 
  THISTORY_STATE*{.pure, final.} = object 
    entries*: ptr ptr THIST_ENTRY # Pointer to the entries themselves. 
    offset*: cint             # The location pointer within this array. 
    length*: cint             # Number of elements within this array. 
    size*: cint               # Number of slots allocated to this array. 
    flags*: cint


# Flag values for the `flags' member of HISTORY_STATE. 

const 
  HS_STIFLED* = 0x00000001

# Initialization and state management. 
# Begin a session in which the history functions might be used.  This
#   just initializes the interactive variables. 

proc using_history*(){.cdecl, importc: "using_history", dynlib: historyDll.}
# Return the current HISTORY_STATE of the history. 

proc history_get_history_state*(): ptr THISTORY_STATE{.cdecl, 
    importc: "history_get_history_state", dynlib: historyDll.}
# Set the state of the current history array to STATE. 

proc history_set_history_state*(a2: ptr THISTORY_STATE){.cdecl, 
    importc: "history_set_history_state", dynlib: historyDll.}
# Manage the history list. 
# Place STRING at the end of the history list.
#   The associated data field (if any) is set to NULL. 

proc add_history*(a2: cstring){.cdecl, importc: "add_history", 
                                dynlib: historyDll.}
# Change the timestamp associated with the most recent history entry to
#   STRING. 

proc add_history_time*(a2: cstring){.cdecl, importc: "add_history_time", 
                                     dynlib: historyDll.}
# A reasonably useless function, only here for completeness.  WHICH
#   is the magic number that tells us which element to delete.  The
#   elements are numbered from 0. 

proc remove_history*(a2: cint): ptr THIST_ENTRY{.cdecl, 
    importc: "remove_history", dynlib: historyDll.}
# Free the history entry H and return any application-specific data
#   associated with it. 

proc free_history_entry*(a2: ptr THIST_ENTRY): Thistdata{.cdecl, 
    importc: "free_history_entry", dynlib: historyDll.}
# Make the history entry at WHICH have LINE and DATA.  This returns
#   the old entry so you can dispose of the data.  In the case of an
#   invalid WHICH, a NULL pointer is returned. 

proc replace_history_entry*(a2: cint, a3: cstring, a4: Thistdata): ptr THIST_ENTRY{.
    cdecl, importc: "replace_history_entry", dynlib: historyDll.}
# Clear the history list and start over. 

proc clear_history*(){.cdecl, importc: "clear_history", dynlib: historyDll.}
# Stifle the history list, remembering only MAX number of entries. 

proc stifle_history*(a2: cint){.cdecl, importc: "stifle_history", 
                                dynlib: historyDll.}
# Stop stifling the history.  This returns the previous amount the
#   history was stifled by.  The value is positive if the history was
#   stifled, negative if it wasn't. 

proc unstifle_history*(): cint{.cdecl, importc: "unstifle_history", 
                                dynlib: historyDll.}
# Return 1 if the history is stifled, 0 if it is not. 

proc history_is_stifled*(): cint{.cdecl, importc: "history_is_stifled", 
                                  dynlib: historyDll.}
# Information about the history list. 
# Return a NULL terminated array of HIST_ENTRY which is the current input
#   history.  Element 0 of this list is the beginning of time.  If there
#   is no history, return NULL. 

proc history_list*(): ptr ptr THIST_ENTRY{.cdecl, importc: "history_list", 
    dynlib: historyDll.}
# Returns the number which says what history element we are now
#   looking at.  

proc where_history*(): cint{.cdecl, importc: "where_history", dynlib: historyDll.}
# Return the history entry at the current position, as determined by
#   history_offset.  If there is no entry there, return a NULL pointer. 

proc current_history*(): ptr THIST_ENTRY{.cdecl, importc: "current_history", 
    dynlib: historyDll.}
# Return the history entry which is logically at OFFSET in the history
#   array.  OFFSET is relative to history_base. 

proc history_get*(a2: cint): ptr THIST_ENTRY{.cdecl, importc: "history_get", 
    dynlib: historyDll.}
# Return the timestamp associated with the HIST_ENTRY * passed as an
#   argument 

proc history_get_time*(a2: ptr THIST_ENTRY): Time{.cdecl, 
    importc: "history_get_time", dynlib: historyDll.}
# Return the number of bytes that the primary history entries are using.
#   This just adds up the lengths of the_history->lines. 

proc history_total_bytes*(): cint{.cdecl, importc: "history_total_bytes", 
                                   dynlib: historyDll.}
# Moving around the history list. 
# Set the position in the history list to POS. 

proc history_set_pos*(a2: cint): cint{.cdecl, importc: "history_set_pos", 
                                       dynlib: historyDll.}
# Back up history_offset to the previous history entry, and return
#   a pointer to that entry.  If there is no previous entry, return
#   a NULL pointer. 

proc previous_history*(): ptr THIST_ENTRY{.cdecl, importc: "previous_history", 
    dynlib: historyDll.}
# Move history_offset forward to the next item in the input_history,
#   and return the a pointer to that entry.  If there is no next entry,
#   return a NULL pointer. 

proc next_history*(): ptr THIST_ENTRY{.cdecl, importc: "next_history", 
                                       dynlib: historyDll.}
# Searching the history list. 
# Search the history for STRING, starting at history_offset.
#   If DIRECTION < 0, then the search is through previous entries,
#   else through subsequent.  If the string is found, then
#   current_history () is the history entry, and the value of this function
#   is the offset in the line of that history entry that the string was
#   found in.  Otherwise, nothing is changed, and a -1 is returned. 

proc history_search*(a2: cstring, a3: cint): cint{.cdecl, 
    importc: "history_search", dynlib: historyDll.}
# Search the history for STRING, starting at history_offset.
#   The search is anchored: matching lines must begin with string.
#   DIRECTION is as in history_search(). 

proc history_search_prefix*(a2: cstring, a3: cint): cint{.cdecl, 
    importc: "history_search_prefix", dynlib: historyDll.}
# Search for STRING in the history list, starting at POS, an
#   absolute index into the list.  DIR, if negative, says to search
#   backwards from POS, else forwards.
#   Returns the absolute index of the history element where STRING
#   was found, or -1 otherwise. 

proc history_search_pos*(a2: cstring, a3: cint, a4: cint): cint{.cdecl, 
    importc: "history_search_pos", dynlib: historyDll.}
# Managing the history file. 
# Add the contents of FILENAME to the history list, a line at a time.
#   If FILENAME is NULL, then read from ~/.history.  Returns 0 if
#   successful, or errno if not. 

proc read_history*(a2: cstring): cint{.cdecl, importc: "read_history", 
                                       dynlib: historyDll.}
# Read a range of lines from FILENAME, adding them to the history list.
#   Start reading at the FROM'th line and end at the TO'th.  If FROM
#   is zero, start at the beginning.  If TO is less than FROM, read
#   until the end of the file.  If FILENAME is NULL, then read from
#   ~/.history.  Returns 0 if successful, or errno if not. 

proc read_history_range*(a2: cstring, a3: cint, a4: cint): cint{.cdecl, 
    importc: "read_history_range", dynlib: historyDll.}
# Write the current history to FILENAME.  If FILENAME is NULL,
#   then write the history list to ~/.history.  Values returned
#   are as in read_history ().  

proc write_history*(a2: cstring): cint{.cdecl, importc: "write_history", 
                                        dynlib: historyDll.}
# Append NELEMENT entries to FILENAME.  The entries appended are from
#   the end of the list minus NELEMENTs up to the end of the list. 

proc append_history*(a2: cint, a3: cstring): cint{.cdecl, 
    importc: "append_history", dynlib: historyDll.}
# Truncate the history file, leaving only the last NLINES lines. 

proc history_truncate_file*(a2: cstring, a3: cint): cint{.cdecl, 
    importc: "history_truncate_file", dynlib: historyDll.}
# History expansion. 
# Expand the string STRING, placing the result into OUTPUT, a pointer
#   to a string.  Returns:
#
#   0) If no expansions took place (or, if the only change in
#      the text was the de-slashifying of the history expansion
#      character)
#   1) If expansions did take place
#  -1) If there was an error in expansion.
#   2) If the returned line should just be printed.
#
#  If an error occurred in expansion, then OUTPUT contains a descriptive
#  error message. 

proc history_expand*(a2: cstring, a3: cstringArray): cint{.cdecl, 
    importc: "history_expand", dynlib: historyDll.}
# Extract a string segment consisting of the FIRST through LAST
#   arguments present in STRING.  Arguments are broken up as in
#   the shell. 

proc history_arg_extract*(a2: cint, a3: cint, a4: cstring): cstring{.cdecl, 
    importc: "history_arg_extract", dynlib: historyDll.}
# Return the text of the history event beginning at the current
#   offset into STRING.  Pass STRING with *INDEX equal to the
#   history_expansion_char that begins this specification.
#   DELIMITING_QUOTE is a character that is allowed to end the string
#   specification for what to search for in addition to the normal
#   characters `:', ` ', `\t', `\n', and sometimes `?'. 

proc get_history_event*(a2: cstring, a3: ptr cint, a4: cint): cstring{.cdecl, 
    importc: "get_history_event", dynlib: historyDll.}
# Return an array of tokens, much as the shell might.  The tokens are
#   parsed out of STRING. 

proc history_tokenize*(a2: cstring): cstringArray{.cdecl, 
    importc: "history_tokenize", dynlib: historyDll.}
when false: 
  # Exported history variables. 
  var history_base*{.importc: "history_base", dynlib: historyDll.}: cint
  var history_length*{.importc: "history_length", dynlib: historyDll.}: cint
  var history_max_entries*{.importc: "history_max_entries", dynlib: historyDll.}: cint
  var history_expansion_char*{.importc: "history_expansion_char", 
                               dynlib: historyDll.}: char
  var history_subst_char*{.importc: "history_subst_char", dynlib: historyDll.}: char
  var history_word_delimiters*{.importc: "history_word_delimiters", 
                                dynlib: historyDll.}: cstring
  var history_comment_char*{.importc: "history_comment_char", dynlib: historyDll.}: char
  var history_no_expand_chars*{.importc: "history_no_expand_chars", 
                                dynlib: historyDll.}: cstring
  var history_search_delimiter_chars*{.importc: "history_search_delimiter_chars", 
                                       dynlib: historyDll.}: cstring
  var history_quotes_inhibit_expansion*{.
      importc: "history_quotes_inhibit_expansion", dynlib: historyDll.}: cint
  var history_write_timestamps*{.importc: "history_write_timestamps", 
                                 dynlib: historyDll.}: cint
