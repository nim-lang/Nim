# Readline.h -- the names of functions callable from within readline. 
# Copyright (C) 1987-2009 Free Software Foundation, Inc.
#
#   This file is part of the GNU Readline Library (Readline), a library
#   for reading lines of text with interactive input and history editing.      
#
#   Readline is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   Readline is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with Readline.  If not, see <http://www.gnu.org/licenses/>.
#

{.deadCodeElim: on.}
when defined(windows): 
  const 
    readlineDll* = "readline.dll"
elif defined(macosx): 
  # Mac OS X ships with 'libedit'
  const 
    readlineDll* = "libedit(.2|.1|).dylib"
else: 
  const 
    readlineDll* = "libreadline.so.6(|.0)"
#  mangle "'TCommandFunc'" TCommandFunc
#  mangle TvcpFunc TvcpFunc

import rltypedefs

# Some character stuff. 

const 
  control_character_threshold* = 0x00000020 # Smaller than this is control. 
  control_character_mask* = 0x0000001F # 0x20 - 1 
  meta_character_threshold* = 0x0000007F # Larger than this is Meta. 
  control_character_bit* = 0x00000040 # 0x000000, must be off. 
  meta_character_bit* = 0x00000080 # x0000000, must be on. 
  largest_char* = 255         # Largest character value. 

template CTRL_CHAR*(c: expr): expr = 
  (c < control_character_threshold and ((c and 0x00000080) == 0))

template META_CHAR*(c: expr): expr = 
  (c > meta_character_threshold and c <= largest_char)

template CTRL*(c: expr): expr = 
  (c and control_character_mask)

template META*(c: expr): expr = 
  (c or meta_character_bit)

template UNMETA*(c: expr): expr = 
  (c and not meta_character_bit)

template UNCTRL*(c: expr): expr = 
  (c or 32 or control_character_bit)

# Beware:  these only work with single-byte ASCII characters. 

const 
  RETURN_CHAR* = CTRL('M'.ord)
  RUBOUT_CHAR* = 0x0000007F
  ABORT_CHAR* = CTRL('G'.ord)
  PAGE_CHAR* = CTRL('L'.ord)
  ESC_CHAR* = CTRL('['.ord)

# A keymap contains one entry for each key in the ASCII set.
#   Each entry consists of a type and a pointer.
#   FUNCTION is the address of a function to run, or the
#   address of a keymap to indirect through.
#   TYPE says which kind of thing FUNCTION is. 

type 
  TKEYMAP_ENTRY*{.pure, final.} = object 
    typ*: char
    function*: TCommandFunc


# This must be large enough to hold bindings for all of the characters
#   in a desired character set (e.g, 128 for ASCII, 256 for ISO Latin-x,
#   and so on) plus one for subsequence matching. 

const 
  KEYMAP_SIZE* = 257
  ANYOTHERKEY* = KEYMAP_SIZE - 1

# I wanted to make the above structure contain a union of:
#   union { rl_TCommandFunc_t *function; struct _keymap_entry *keymap; } value;
#   but this made it impossible for me to create a static array.
#   Maybe I need C lessons. 

type 
  TKEYMAP_ENTRY_ARRAY* = array[0..KEYMAP_SIZE - 1, TKEYMAP_ENTRY]
  PKeymap* = ptr TKEYMAP_ENTRY

# The values that TYPE can have in a keymap entry. 

const 
  ISFUNC* = 0
  ISKMAP* = 1
  ISMACR* = 2

when false: 
  var 
    emacs_standard_keymap*{.importc: "emacs_standard_keymap", 
                            dynlib: readlineDll.}: TKEYMAP_ENTRY_ARRAY
    emacs_meta_keymap*{.importc: "emacs_meta_keymap", dynlib: readlineDll.}: TKEYMAP_ENTRY_ARRAY
    emacs_ctlx_keymap*{.importc: "emacs_ctlx_keymap", dynlib: readlineDll.}: TKEYMAP_ENTRY_ARRAY
  var 
    vi_insertion_keymap*{.importc: "vi_insertion_keymap", dynlib: readlineDll.}: TKEYMAP_ENTRY_ARRAY
    vi_movement_keymap*{.importc: "vi_movement_keymap", dynlib: readlineDll.}: TKEYMAP_ENTRY_ARRAY
# Return a new, empty keymap.
#   Free it with free() when you are done. 

proc make_bare_keymap*(): PKeymap{.cdecl, importc: "rl_make_bare_keymap", 
                                   dynlib: readlineDll.}
# Return a new keymap which is a copy of MAP. 

proc copy_keymap*(a2: PKeymap): PKeymap{.cdecl, importc: "rl_copy_keymap", 
    dynlib: readlineDll.}
# Return a new keymap with the printing characters bound to rl_insert,
#   the lowercase Meta characters bound to run their equivalents, and
#   the Meta digits bound to produce numeric arguments. 

proc make_keymap*(): PKeymap{.cdecl, importc: "rl_make_keymap", 
                              dynlib: readlineDll.}
# Free the storage associated with a keymap. 

proc discard_keymap*(a2: PKeymap){.cdecl, importc: "rl_discard_keymap", 
                                   dynlib: readlineDll.}
# These functions actually appear in bind.c 
# Return the keymap corresponding to a given name.  Names look like
#   `emacs' or `emacs-meta' or `vi-insert'.  

proc get_keymap_by_name*(a2: cstring): PKeymap{.cdecl, 
    importc: "rl_get_keymap_by_name", dynlib: readlineDll.}
# Return the current keymap. 

proc get_keymap*(): PKeymap{.cdecl, importc: "rl_get_keymap", 
                             dynlib: readlineDll.}
# Set the current keymap to MAP. 

proc set_keymap*(a2: PKeymap){.cdecl, importc: "rl_set_keymap", 
                               dynlib: readlineDll.}

const 
  tildeDll = readlineDll

type 
  Thook_func* = proc (a2: cstring): cstring{.cdecl.}

when not defined(macosx):
  # If non-null, this contains the address of a function that the application
  #   wants called before trying the standard tilde expansions.  The function
  #   is called with the text sans tilde, and returns a malloc()'ed string
  #   which is the expansion, or a NULL pointer if the expansion fails. 

  var expansion_preexpansion_hook*{.importc: "tilde_expansion_preexpansion_hook", 
                                    dynlib: tildeDll.}: Thook_func

  # If non-null, this contains the address of a function to call if the
  #   standard meaning for expanding a tilde fails.  The function is called
  #   with the text (sans tilde, as in "foo"), and returns a malloc()'ed string
  #   which is the expansion, or a NULL pointer if there is no expansion. 

  var expansion_failure_hook*{.importc: "tilde_expansion_failure_hook", 
                               dynlib: tildeDll.}: Thook_func

  # When non-null, this is a NULL terminated array of strings which
  #   are duplicates for a tilde prefix.  Bash uses this to expand
  #   `=~' and `:~'. 

  var additional_prefixes*{.importc: "tilde_additional_prefixes", dynlib: tildeDll.}: cstringArray

  # When non-null, this is a NULL terminated array of strings which match
  #   the end of a username, instead of just "/".  Bash sets this to
  #   `:' and `=~'. 

  var additional_suffixes*{.importc: "tilde_additional_suffixes", dynlib: tildeDll.}: cstringArray

# Return a new string which is the result of tilde expanding STRING. 

proc expand*(a2: cstring): cstring{.cdecl, importc: "tilde_expand", 
                                    dynlib: tildeDll.}
# Do the work of tilde expansion on FILENAME.  FILENAME starts with a
#   tilde.  If there is no expansion, call tilde_expansion_failure_hook. 

proc expand_word*(a2: cstring): cstring{.cdecl, importc: "tilde_expand_word", 
    dynlib: tildeDll.}
# Find the portion of the string beginning with ~ that should be expanded. 

proc find_word*(a2: cstring, a3: cint, a4: ptr cint): cstring{.cdecl, 
    importc: "tilde_find_word", dynlib: tildeDll.}

# Hex-encoded Readline version number. 

const 
  READLINE_VERSION* = 0x00000600 # Readline 6.0 
  VERSION_MAJOR* = 6
  VERSION_MINOR* = 0

# Readline data structures. 
# Maintaining the state of undo.  We remember individual deletes and inserts
#   on a chain of things to do. 
# The actions that undo knows how to undo.  Notice that UNDO_DELETE means
#   to insert some text, and UNDO_INSERT means to delete some text.   I.e.,
#   the code tells undo what to undo, not how to undo it. 

type 
  Tundo_code* = enum 
    UNDO_DELETE, UNDO_INSERT, UNDO_BEGIN, UNDO_END

# What an element of THE_UNDO_LIST looks like. 

type 
  TUNDO_LIST*{.pure, final.} = object 
    next*: ptr Tundo_list
    start*: cint
    theEnd*: cint             # Where the change took place. 
    text*: cstring            # The text to insert, if undoing a delete. 
    what*: Tundo_code         # Delete, Insert, Begin, End. 
  

# The current undo list for RL_LINE_BUFFER. 

when not defined(macosx):
  var undo_list*{.importc: "rl_undo_list", dynlib: readlineDll.}: ptr TUNDO_LIST

# The data structure for mapping textual names to code addresses. 

type 
  TFUNMAP*{.pure, final.} = object 
    name*: cstring
    function*: TCommandFunc


when not defined(macosx):
  var funmap*{.importc: "funmap", dynlib: readlineDll.}: ptr ptr TFUNMAP

# **************************************************************** 
#								    
#	     Functions available to bind to key sequences	    
#								    
# **************************************************************** 
# Bindable commands for numeric arguments. 

proc digit_argument*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_digit_argument", dynlib: readlineDll.}
proc universal_argument*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_universal_argument", dynlib: readlineDll.}
# Bindable commands for moving the cursor. 

proc forward_byte*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_forward_byte", 
    dynlib: readlineDll.}
proc forward_char*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_forward_char", 
    dynlib: readlineDll.}
proc forward*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_forward", 
    dynlib: readlineDll.}
proc backward_byte*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_backward_byte", dynlib: readlineDll.}
proc backward_char*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_backward_char", dynlib: readlineDll.}
proc backward*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_backward", 
    dynlib: readlineDll.}
proc beg_of_line*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_beg_of_line", 
    dynlib: readlineDll.}
proc end_of_line*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_end_of_line", 
    dynlib: readlineDll.}
proc forward_word*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_forward_word", 
    dynlib: readlineDll.}
proc backward_word*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_backward_word", dynlib: readlineDll.}
proc refresh_line*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_refresh_line", 
    dynlib: readlineDll.}
proc clear_screen*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_clear_screen", 
    dynlib: readlineDll.}
proc skip_csi_sequence*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_skip_csi_sequence", dynlib: readlineDll.}
proc arrow_keys*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_arrow_keys", 
    dynlib: readlineDll.}
# Bindable commands for inserting and deleting text. 

proc insert*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_insert", 
                                        dynlib: readlineDll.}
proc quoted_insert*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_quoted_insert", dynlib: readlineDll.}
proc tab_insert*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_tab_insert", 
    dynlib: readlineDll.}
proc newline*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_newline", 
    dynlib: readlineDll.}
proc do_lowercase_version*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_do_lowercase_version", dynlib: readlineDll.}
proc rubout*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_rubout", 
                                        dynlib: readlineDll.}
proc delete*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_delete", 
                                        dynlib: readlineDll.}
proc rubout_or_delete*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_rubout_or_delete", dynlib: readlineDll.}
proc delete_horizontal_space*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_delete_horizontal_space", dynlib: readlineDll.}
proc delete_or_show_completions*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_delete_or_show_completions", dynlib: readlineDll.}
proc insert_comment*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_insert_comment", dynlib: readlineDll.}
# Bindable commands for changing case. 

proc upcase_word*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_upcase_word", 
    dynlib: readlineDll.}
proc downcase_word*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_downcase_word", dynlib: readlineDll.}
proc capitalize_word*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_capitalize_word", dynlib: readlineDll.}
# Bindable commands for transposing characters and words. 

proc transpose_words*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_transpose_words", dynlib: readlineDll.}
proc transpose_chars*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_transpose_chars", dynlib: readlineDll.}
# Bindable commands for searching within a line. 

proc char_search*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_char_search", 
    dynlib: readlineDll.}
proc backward_char_search*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_backward_char_search", dynlib: readlineDll.}
# Bindable commands for readline's interface to the command history. 

proc beginning_of_history*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_beginning_of_history", dynlib: readlineDll.}
proc end_of_history*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_end_of_history", dynlib: readlineDll.}
proc get_next_history*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_get_next_history", dynlib: readlineDll.}
proc get_previous_history*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_get_previous_history", dynlib: readlineDll.}
# Bindable commands for managing the mark and region. 

proc set_mark*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_set_mark", 
    dynlib: readlineDll.}
proc exchange_point_and_mark*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_exchange_point_and_mark", dynlib: readlineDll.}
# Bindable commands to set the editing mode (emacs or vi). 

proc vi_editing_mode*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_editing_mode", dynlib: readlineDll.}
proc emacs_editing_mode*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_emacs_editing_mode", dynlib: readlineDll.}
# Bindable commands to change the insert mode (insert or overwrite) 

proc overwrite_mode*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_overwrite_mode", dynlib: readlineDll.}
# Bindable commands for managing key bindings. 

proc re_read_init_file*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_re_read_init_file", dynlib: readlineDll.}
proc dump_functions*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_dump_functions", dynlib: readlineDll.}
proc dump_macros*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_dump_macros", 
    dynlib: readlineDll.}
proc dump_variables*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_dump_variables", dynlib: readlineDll.}
# Bindable commands for word completion. 

proc complete*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_complete", 
    dynlib: readlineDll.}
proc possible_completions*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_possible_completions", dynlib: readlineDll.}
proc insert_completions*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_insert_completions", dynlib: readlineDll.}
proc old_menu_complete*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_old_menu_complete", dynlib: readlineDll.}
proc menu_complete*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_menu_complete", dynlib: readlineDll.}
proc backward_menu_complete*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_backward_menu_complete", dynlib: readlineDll.}
# Bindable commands for killing and yanking text, and managing the kill ring. 

proc kill_word*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_kill_word", 
    dynlib: readlineDll.}
proc backward_kill_word*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_backward_kill_word", dynlib: readlineDll.}
proc kill_line*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_kill_line", 
    dynlib: readlineDll.}
proc backward_kill_line*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_backward_kill_line", dynlib: readlineDll.}
proc kill_full_line*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_kill_full_line", dynlib: readlineDll.}
proc unix_word_rubout*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_unix_word_rubout", dynlib: readlineDll.}
proc unix_filename_rubout*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_unix_filename_rubout", dynlib: readlineDll.}
proc unix_line_discard*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_unix_line_discard", dynlib: readlineDll.}
proc copy_region_to_kill*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_copy_region_to_kill", dynlib: readlineDll.}
proc kill_region*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_kill_region", 
    dynlib: readlineDll.}
proc copy_forward_word*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_copy_forward_word", dynlib: readlineDll.}
proc copy_backward_word*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_copy_backward_word", dynlib: readlineDll.}
proc yank*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_yank", 
                                      dynlib: readlineDll.}
proc yank_pop*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_yank_pop", 
    dynlib: readlineDll.}
proc yank_nth_arg*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_yank_nth_arg", 
    dynlib: readlineDll.}
proc yank_last_arg*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_yank_last_arg", dynlib: readlineDll.}
when defined(Windows): 
  proc paste_from_clipboard*(a2: cint, a3: cint): cint{.cdecl, 
      importc: "rl_paste_from_clipboard", dynlib: readlineDll.}
# Bindable commands for incremental searching. 

proc reverse_search_history*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_reverse_search_history", dynlib: readlineDll.}
proc forward_search_history*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_forward_search_history", dynlib: readlineDll.}
# Bindable keyboard macro commands. 

proc start_kbd_macro*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_start_kbd_macro", dynlib: readlineDll.}
proc end_kbd_macro*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_end_kbd_macro", dynlib: readlineDll.}
proc call_last_kbd_macro*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_call_last_kbd_macro", dynlib: readlineDll.}
# Bindable undo commands. 

proc revert_line*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_revert_line", 
    dynlib: readlineDll.}
proc undo_command*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_undo_command", 
    dynlib: readlineDll.}
# Bindable tilde expansion commands. 

proc tilde_expand*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_tilde_expand", 
    dynlib: readlineDll.}
# Bindable terminal control commands. 

proc restart_output*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_restart_output", dynlib: readlineDll.}
proc stop_output*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_stop_output", 
    dynlib: readlineDll.}
# Miscellaneous bindable commands. 

proc abort*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_abort", 
                                       dynlib: readlineDll.}
proc tty_status*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_tty_status", 
    dynlib: readlineDll.}
# Bindable commands for incremental and non-incremental history searching. 

proc history_search_forward*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_history_search_forward", dynlib: readlineDll.}
proc history_search_backward*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_history_search_backward", dynlib: readlineDll.}
proc noninc_forward_search*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_noninc_forward_search", dynlib: readlineDll.}
proc noninc_reverse_search*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_noninc_reverse_search", dynlib: readlineDll.}
proc noninc_forward_search_again*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_noninc_forward_search_again", dynlib: readlineDll.}
proc noninc_reverse_search_again*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_noninc_reverse_search_again", dynlib: readlineDll.}
# Bindable command used when inserting a matching close character. 

proc insert_close*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_insert_close", 
    dynlib: readlineDll.}
# Not available unless READLINE_CALLBACKS is defined. 

proc callback_handler_install*(a2: cstring, a3: TvcpFunc){.cdecl, 
    importc: "rl_callback_handler_install", dynlib: readlineDll.}
proc callback_read_char*(){.cdecl, importc: "rl_callback_read_char", 
                            dynlib: readlineDll.}
proc callback_handler_remove*(){.cdecl, importc: "rl_callback_handler_remove", 
                                 dynlib: readlineDll.}
# Things for vi mode. Not available unless readline is compiled -DVI_MODE. 
# VI-mode bindable commands. 

proc vi_redo*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_redo", 
    dynlib: readlineDll.}
proc vi_undo*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_undo", 
    dynlib: readlineDll.}
proc vi_yank_arg*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_yank_arg", 
    dynlib: readlineDll.}
proc vi_fetch_history*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_fetch_history", dynlib: readlineDll.}
proc vi_search_again*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_search_again", dynlib: readlineDll.}
proc vi_search*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_search", 
    dynlib: readlineDll.}
proc vi_complete*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_complete", 
    dynlib: readlineDll.}
proc vi_tilde_expand*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_tilde_expand", dynlib: readlineDll.}
proc vi_prev_word*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_prev_word", 
    dynlib: readlineDll.}
proc vi_next_word*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_next_word", 
    dynlib: readlineDll.}
proc vi_end_word*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_end_word", 
    dynlib: readlineDll.}
proc vi_insert_beg*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_insert_beg", dynlib: readlineDll.}
proc vi_append_mode*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_append_mode", dynlib: readlineDll.}
proc vi_append_eol*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_append_eol", dynlib: readlineDll.}
proc vi_eof_maybe*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_eof_maybe", 
    dynlib: readlineDll.}
proc vi_insertion_mode*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_insertion_mode", dynlib: readlineDll.}
proc vi_insert_mode*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_insert_mode", dynlib: readlineDll.}
proc vi_movement_mode*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_movement_mode", dynlib: readlineDll.}
proc vi_arg_digit*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_arg_digit", 
    dynlib: readlineDll.}
proc vi_change_case*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_change_case", dynlib: readlineDll.}
proc vi_put*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_put", 
                                        dynlib: readlineDll.}
proc vi_column*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_column", 
    dynlib: readlineDll.}
proc vi_delete_to*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_delete_to", 
    dynlib: readlineDll.}
proc vi_change_to*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_change_to", 
    dynlib: readlineDll.}
proc vi_yank_to*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_yank_to", 
    dynlib: readlineDll.}
proc vi_rubout*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_rubout", 
    dynlib: readlineDll.}
proc vi_delete*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_delete", 
    dynlib: readlineDll.}
proc vi_back_to_indent*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_back_to_indent", dynlib: readlineDll.}
proc vi_first_print*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_first_print", dynlib: readlineDll.}
proc vi_char_search*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_char_search", dynlib: readlineDll.}
proc vi_match*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_match", 
    dynlib: readlineDll.}
proc vi_change_char*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_change_char", dynlib: readlineDll.}
proc vi_subst*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_subst", 
    dynlib: readlineDll.}
proc vi_overstrike*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_overstrike", dynlib: readlineDll.}
proc vi_overstrike_delete*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_vi_overstrike_delete", dynlib: readlineDll.}
proc vi_replace*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_replace", 
    dynlib: readlineDll.}
proc vi_set_mark*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_set_mark", 
    dynlib: readlineDll.}
proc vi_goto_mark*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_goto_mark", 
    dynlib: readlineDll.}
# VI-mode utility functions. 

proc vi_check*(): cint{.cdecl, importc: "rl_vi_check", dynlib: readlineDll.}
proc vi_domove*(a2: cint, a3: ptr cint): cint{.cdecl, importc: "rl_vi_domove", 
    dynlib: readlineDll.}
proc vi_bracktype*(a2: cint): cint{.cdecl, importc: "rl_vi_bracktype", 
                                    dynlib: readlineDll.}
proc vi_start_inserting*(a2: cint, a3: cint, a4: cint){.cdecl, 
    importc: "rl_vi_start_inserting", dynlib: readlineDll.}
# VI-mode pseudo-bindable commands, used as utility functions. 

proc vi_fXWord*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_fWord", 
    dynlib: readlineDll.}
proc vi_bXWord*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_bWord", 
    dynlib: readlineDll.}
proc vi_eXWord*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_eWord", 
    dynlib: readlineDll.}
proc vi_fword*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_fword", 
    dynlib: readlineDll.}
proc vi_bword*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_bword", 
    dynlib: readlineDll.}
proc vi_eword*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_vi_eword", 
    dynlib: readlineDll.}
# **************************************************************** 
#								    
#			Well Published Functions		    
#								    
# **************************************************************** 
# Readline functions. 
# Read a line of input.  Prompt with PROMPT.  A NULL PROMPT means none. 

proc readline*(a2: cstring): cstring{.cdecl, importc: "readline", 
                                      dynlib: readlineDll.}
proc free*(mem: cstring) {.importc: "free", nodecl.}
  ## free the buffer that `readline` returned.

proc set_prompt*(a2: cstring): cint{.cdecl, importc: "rl_set_prompt", 
                                     dynlib: readlineDll.}
proc expand_prompt*(a2: cstring): cint{.cdecl, importc: "rl_expand_prompt", 
                                        dynlib: readlineDll.}
proc initialize*(): cint{.cdecl, importc: "rl_initialize", dynlib: readlineDll.}
# Undocumented; unused by readline 

proc discard_argument*(): cint{.cdecl, importc: "rl_discard_argument", 
                                dynlib: readlineDll.}
# Utility functions to bind keys to readline commands. 

proc add_defun*(a2: cstring, a3: TCommandFunc, a4: cint): cint{.cdecl, 
    importc: "rl_add_defun", dynlib: readlineDll.}
proc bind_key*(a2: cint, a3: TCommandFunc): cint{.cdecl, 
    importc: "rl_bind_key", dynlib: readlineDll.}
proc bind_key_in_map*(a2: cint, a3: TCommandFunc, a4: PKeymap): cint{.cdecl, 
    importc: "rl_bind_key_in_map", dynlib: readlineDll.}
proc unbind_key*(a2: cint): cint{.cdecl, importc: "rl_unbind_key", 
                                  dynlib: readlineDll.}
proc unbind_key_in_map*(a2: cint, a3: PKeymap): cint{.cdecl, 
    importc: "rl_unbind_key_in_map", dynlib: readlineDll.}
proc bind_key_if_unbound*(a2: cint, a3: TCommandFunc): cint{.cdecl, 
    importc: "rl_bind_key_if_unbound", dynlib: readlineDll.}
proc bind_key_if_unbound_in_map*(a2: cint, a3: TCommandFunc, a4: PKeymap): cint{.
    cdecl, importc: "rl_bind_key_if_unbound_in_map", dynlib: readlineDll.}
proc unbind_function_in_map*(a2: TCommandFunc, a3: PKeymap): cint{.cdecl, 
    importc: "rl_unbind_function_in_map", dynlib: readlineDll.}
proc unbind_command_in_map*(a2: cstring, a3: PKeymap): cint{.cdecl, 
    importc: "rl_unbind_command_in_map", dynlib: readlineDll.}
proc bind_keyseq*(a2: cstring, a3: TCommandFunc): cint{.cdecl, 
    importc: "rl_bind_keyseq", dynlib: readlineDll.}
proc bind_keyseq_in_map*(a2: cstring, a3: TCommandFunc, a4: PKeymap): cint{.
    cdecl, importc: "rl_bind_keyseq_in_map", dynlib: readlineDll.}
proc bind_keyseq_if_unbound*(a2: cstring, a3: TCommandFunc): cint{.cdecl, 
    importc: "rl_bind_keyseq_if_unbound", dynlib: readlineDll.}
proc bind_keyseq_if_unbound_in_map*(a2: cstring, a3: TCommandFunc, 
                                    a4: PKeymap): cint{.cdecl, 
    importc: "rl_bind_keyseq_if_unbound_in_map", dynlib: readlineDll.}
proc generic_bind*(a2: cint, a3: cstring, a4: cstring, a5: PKeymap): cint{.
    cdecl, importc: "rl_generic_bind", dynlib: readlineDll.}
proc variable_value*(a2: cstring): cstring{.cdecl, importc: "rl_variable_value", 
    dynlib: readlineDll.}
proc variable_bind*(a2: cstring, a3: cstring): cint{.cdecl, 
    importc: "rl_variable_bind", dynlib: readlineDll.}
# Backwards compatibility, use rl_bind_keyseq_in_map instead. 

proc set_key*(a2: cstring, a3: TCommandFunc, a4: PKeymap): cint{.cdecl, 
    importc: "rl_set_key", dynlib: readlineDll.}
# Backwards compatibility, use rl_generic_bind instead. 

proc macro_bind*(a2: cstring, a3: cstring, a4: PKeymap): cint{.cdecl, 
    importc: "rl_macro_bind", dynlib: readlineDll.}
# Undocumented in the texinfo manual; not really useful to programs. 

proc translate_keyseq*(a2: cstring, a3: cstring, a4: ptr cint): cint{.cdecl, 
    importc: "rl_translate_keyseq", dynlib: readlineDll.}
proc untranslate_keyseq*(a2: cint): cstring{.cdecl, 
    importc: "rl_untranslate_keyseq", dynlib: readlineDll.}
proc named_function*(a2: cstring): TCommandFunc{.cdecl, 
    importc: "rl_named_function", dynlib: readlineDll.}
proc function_of_keyseq*(a2: cstring, a3: PKeymap, a4: ptr cint): TCommandFunc{.
    cdecl, importc: "rl_function_of_keyseq", dynlib: readlineDll.}
proc list_funmap_names*(){.cdecl, importc: "rl_list_funmap_names", 
                           dynlib: readlineDll.}
proc invoking_keyseqs_in_map*(a2: TCommandFunc, a3: PKeymap): cstringArray{.
    cdecl, importc: "rl_invoking_keyseqs_in_map", dynlib: readlineDll.}
proc invoking_keyseqs*(a2: TCommandFunc): cstringArray{.cdecl, 
    importc: "rl_invoking_keyseqs", dynlib: readlineDll.}
proc function_dumper*(a2: cint){.cdecl, importc: "rl_function_dumper", 
                                 dynlib: readlineDll.}
proc macro_dumper*(a2: cint){.cdecl, importc: "rl_macro_dumper", 
                              dynlib: readlineDll.}
proc variable_dumper*(a2: cint){.cdecl, importc: "rl_variable_dumper", 
                                 dynlib: readlineDll.}
proc read_init_file*(a2: cstring): cint{.cdecl, importc: "rl_read_init_file", 
    dynlib: readlineDll.}
proc parse_and_bind*(a2: cstring): cint{.cdecl, importc: "rl_parse_and_bind", 
    dynlib: readlineDll.}

proc get_keymap_name*(a2: PKeymap): cstring{.cdecl, 
    importc: "rl_get_keymap_name", dynlib: readlineDll.}

proc set_keymap_from_edit_mode*(){.cdecl, 
                                   importc: "rl_set_keymap_from_edit_mode", 
                                   dynlib: readlineDll.}
proc get_keymap_name_from_edit_mode*(): cstring{.cdecl, 
    importc: "rl_get_keymap_name_from_edit_mode", dynlib: readlineDll.}
# Functions for manipulating the funmap, which maps command names to functions. 

proc add_funmap_entry*(a2: cstring, a3: TCommandFunc): cint{.cdecl, 
    importc: "rl_add_funmap_entry", dynlib: readlineDll.}
proc funmap_names*(): cstringArray{.cdecl, importc: "rl_funmap_names", 
                                    dynlib: readlineDll.}
# Undocumented, only used internally -- there is only one funmap, and this
#   function may be called only once. 

proc initialize_funmap*(){.cdecl, importc: "rl_initialize_funmap", 
                           dynlib: readlineDll.}
# Utility functions for managing keyboard macros. 

proc push_macro_input*(a2: cstring){.cdecl, importc: "rl_push_macro_input", 
                                     dynlib: readlineDll.}
# Functions for undoing, from undo.c 

proc add_undo*(a2: Tundo_code, a3: cint, a4: cint, a5: cstring){.cdecl, 
    importc: "rl_add_undo", dynlib: readlineDll.}
proc free_undo_list*(){.cdecl, importc: "rl_free_undo_list", dynlib: readlineDll.}
proc do_undo*(): cint{.cdecl, importc: "rl_do_undo", dynlib: readlineDll.}
proc begin_undo_group*(): cint{.cdecl, importc: "rl_begin_undo_group", 
                                dynlib: readlineDll.}
proc end_undo_group*(): cint{.cdecl, importc: "rl_end_undo_group", 
                              dynlib: readlineDll.}
proc modifying*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_modifying", 
    dynlib: readlineDll.}
# Functions for redisplay. 

proc redisplay*(){.cdecl, importc: "rl_redisplay", dynlib: readlineDll.}
proc on_new_line*(): cint{.cdecl, importc: "rl_on_new_line", dynlib: readlineDll.}
proc on_new_line_with_prompt*(): cint{.cdecl, 
                                       importc: "rl_on_new_line_with_prompt", 
                                       dynlib: readlineDll.}
proc forced_update_display*(): cint{.cdecl, importc: "rl_forced_update_display", 
                                     dynlib: readlineDll.}
proc clear_message*(): cint{.cdecl, importc: "rl_clear_message", 
                             dynlib: readlineDll.}
proc reset_line_state*(): cint{.cdecl, importc: "rl_reset_line_state", 
                                dynlib: readlineDll.}
proc crlf*(): cint{.cdecl, importc: "rl_crlf", dynlib: readlineDll.}
proc message*(a2: cstring): cint{.varargs, cdecl, importc: "rl_message", 
                                  dynlib: readlineDll.}
proc show_char*(a2: cint): cint{.cdecl, importc: "rl_show_char", 
                                 dynlib: readlineDll.}
# Undocumented in texinfo manual. 

proc character_len*(a2: cint, a3: cint): cint{.cdecl, 
    importc: "rl_character_len", dynlib: readlineDll.}
# Save and restore internal prompt redisplay information. 

proc save_prompt*(){.cdecl, importc: "rl_save_prompt", dynlib: readlineDll.}
proc restore_prompt*(){.cdecl, importc: "rl_restore_prompt", dynlib: readlineDll.}
# Modifying text. 

proc replace_line*(a2: cstring, a3: cint){.cdecl, importc: "rl_replace_line", 
    dynlib: readlineDll.}
proc insert_text*(a2: cstring): cint{.cdecl, importc: "rl_insert_text", 
                                      dynlib: readlineDll.}
proc delete_text*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_delete_text", 
    dynlib: readlineDll.}
proc kill_text*(a2: cint, a3: cint): cint{.cdecl, importc: "rl_kill_text", 
    dynlib: readlineDll.}
proc copy_text*(a2: cint, a3: cint): cstring{.cdecl, importc: "rl_copy_text", 
    dynlib: readlineDll.}
# Terminal and tty mode management. 

proc prep_terminal*(a2: cint){.cdecl, importc: "rl_prep_terminal", 
                               dynlib: readlineDll.}
proc deprep_terminal*(){.cdecl, importc: "rl_deprep_terminal", 
                         dynlib: readlineDll.}
proc tty_set_default_bindings*(a2: PKeymap){.cdecl, 
    importc: "rl_tty_set_default_bindings", dynlib: readlineDll.}
proc tty_unset_default_bindings*(a2: PKeymap){.cdecl, 
    importc: "rl_tty_unset_default_bindings", dynlib: readlineDll.}
proc reset_terminal*(a2: cstring): cint{.cdecl, importc: "rl_reset_terminal", 
    dynlib: readlineDll.}
proc resize_terminal*(){.cdecl, importc: "rl_resize_terminal", 
                         dynlib: readlineDll.}
proc set_screen_size*(a2: cint, a3: cint){.cdecl, importc: "rl_set_screen_size", 
    dynlib: readlineDll.}
proc get_screen_size*(a2: ptr cint, a3: ptr cint){.cdecl, 
    importc: "rl_get_screen_size", dynlib: readlineDll.}
proc reset_screen_size*(){.cdecl, importc: "rl_reset_screen_size", 
                           dynlib: readlineDll.}
proc get_termcap*(a2: cstring): cstring{.cdecl, importc: "rl_get_termcap", 
    dynlib: readlineDll.}
# Functions for character input. 

proc stuff_char*(a2: cint): cint{.cdecl, importc: "rl_stuff_char", 
                                  dynlib: readlineDll.}
proc execute_next*(a2: cint): cint{.cdecl, importc: "rl_execute_next", 
                                    dynlib: readlineDll.}
proc clear_pending_input*(): cint{.cdecl, importc: "rl_clear_pending_input", 
                                   dynlib: readlineDll.}
proc read_key*(): cint{.cdecl, importc: "rl_read_key", dynlib: readlineDll.}
proc getc*(a2: File): cint{.cdecl, importc: "rl_getc", dynlib: readlineDll.}
proc set_keyboard_input_timeout*(a2: cint): cint{.cdecl, 
    importc: "rl_set_keyboard_input_timeout", dynlib: readlineDll.}
# `Public' utility functions . 

proc extend_line_buffer*(a2: cint){.cdecl, importc: "rl_extend_line_buffer", 
                                    dynlib: readlineDll.}
proc ding*(): cint{.cdecl, importc: "rl_ding", dynlib: readlineDll.}
proc alphabetic*(a2: cint): cint{.cdecl, importc: "rl_alphabetic", 
                                  dynlib: readlineDll.}
proc free*(a2: pointer){.cdecl, importc: "rl_free", dynlib: readlineDll.}
# Readline signal handling, from signals.c 

proc set_signals*(): cint{.cdecl, importc: "rl_set_signals", dynlib: readlineDll.}
proc clear_signals*(): cint{.cdecl, importc: "rl_clear_signals", 
                             dynlib: readlineDll.}
proc cleanup_after_signal*(){.cdecl, importc: "rl_cleanup_after_signal", 
                              dynlib: readlineDll.}
proc reset_after_signal*(){.cdecl, importc: "rl_reset_after_signal", 
                            dynlib: readlineDll.}
proc free_line_state*(){.cdecl, importc: "rl_free_line_state", 
                         dynlib: readlineDll.}
proc echo_signal_char*(a2: cint){.cdecl, importc: "rl_echo_signal_char", 
                                  dynlib: readlineDll.}
proc set_paren_blink_timeout*(a2: cint): cint{.cdecl, 
    importc: "rl_set_paren_blink_timeout", dynlib: readlineDll.}
# Undocumented. 

proc maybe_save_line*(): cint{.cdecl, importc: "rl_maybe_save_line", 
                               dynlib: readlineDll.}
proc maybe_unsave_line*(): cint{.cdecl, importc: "rl_maybe_unsave_line", 
                                 dynlib: readlineDll.}
proc maybe_replace_line*(): cint{.cdecl, importc: "rl_maybe_replace_line", 
                                  dynlib: readlineDll.}
# Completion functions. 

proc complete_internal*(a2: cint): cint{.cdecl, importc: "rl_complete_internal", 
    dynlib: readlineDll.}
proc display_match_list*(a2: cstringArray, a3: cint, a4: cint){.cdecl, 
    importc: "rl_display_match_list", dynlib: readlineDll.}
proc completion_matches*(a2: cstring, a3: Tcompentry_func): cstringArray{.
    cdecl, importc: "rl_completion_matches", dynlib: readlineDll.}
proc username_completion_function*(a2: cstring, a3: cint): cstring{.cdecl, 
    importc: "rl_username_completion_function", dynlib: readlineDll.}
proc filename_completion_function*(a2: cstring, a3: cint): cstring{.cdecl, 
    importc: "rl_filename_completion_function", dynlib: readlineDll.}
proc completion_mode*(a2: TCommandFunc): cint{.cdecl, 
    importc: "rl_completion_mode", dynlib: readlineDll.}
# **************************************************************** 
#								    
#			Well Published Variables		    
#								    
# **************************************************************** 

when false: 
  # The version of this incarnation of the readline library. 
  var library_version*{.importc: "rl_library_version", dynlib: readlineDll.}: cstring
  # e.g., "4.2" 
  var readline_version*{.importc: "rl_readline_version", dynlib: readlineDll.}: cint
  # e.g., 0x0402 
  # True if this is real GNU readline. 
  var gnu_readline_p*{.importc: "rl_gnu_readline_p", dynlib: readlineDll.}: cint
  # Flags word encapsulating the current readline state. 
  var readline_state*{.importc: "rl_readline_state", dynlib: readlineDll.}: cint
  # Says which editing mode readline is currently using.  1 means emacs mode;
  #   0 means vi mode. 
  var editing_mode*{.importc: "rl_editing_mode", dynlib: readlineDll.}: cint
  # Insert or overwrite mode for emacs mode.  1 means insert mode; 0 means
  #   overwrite mode.  Reset to insert mode on each input line. 
  var insert_mode*{.importc: "rl_insert_mode", dynlib: readlineDll.}: cint
  # The name of the calling program.  You should initialize this to
  #   whatever was in argv[0].  It is used when parsing conditionals. 
  var readline_name*{.importc: "rl_readline_name", dynlib: readlineDll.}: cstring
  # The prompt readline uses.  This is set from the argument to
  #   readline (), and should not be assigned to directly. 
  var prompt*{.importc: "rl_prompt", dynlib: readlineDll.}: cstring
  # The prompt string that is actually displayed by rl_redisplay.  Public so
  #   applications can more easily supply their own redisplay functions. 
  var display_prompt*{.importc: "rl_display_prompt", dynlib: readlineDll.}: cstring
  # The line buffer that is in use. 
  var line_buffer*{.importc: "rl_line_buffer", dynlib: readlineDll.}: cstring
  # The location of point, and end. 
  var point*{.importc: "rl_point", dynlib: readlineDll.}: cint
  var theEnd*{.importc: "rl_end", dynlib: readlineDll.}: cint
  # The mark, or saved cursor position. 
  var mark*{.importc: "rl_mark", dynlib: readlineDll.}: cint
  # Flag to indicate that readline has finished with the current input
  #   line and should return it. 
  var done*{.importc: "rl_done", dynlib: readlineDll.}: cint
  # If set to a character value, that will be the next keystroke read. 
  var pending_input*{.importc: "rl_pending_input", dynlib: readlineDll.}: cint
  # Non-zero if we called this function from _rl_dispatch().  It's present
  #   so functions can find out whether they were called from a key binding
  #   or directly from an application. 
  var dispatching*{.importc: "rl_dispatching", dynlib: readlineDll.}: cint
  # Non-zero if the user typed a numeric argument before executing the
  #   current function. 
  var explicit_arg*{.importc: "rl_explicit_arg", dynlib: readlineDll.}: cint
  # The current value of the numeric argument specified by the user. 
  var numeric_arg*{.importc: "rl_numeric_arg", dynlib: readlineDll.}: cint
  # The address of the last command function Readline executed. 
  var last_func*{.importc: "rl_last_func", dynlib: readlineDll.}: TCommandFunc
  # The name of the terminal to use. 
  var terminal_name*{.importc: "rl_terminal_name", dynlib: readlineDll.}: cstring
  # The input and output streams. 
  var instream*{.importc: "rl_instream", dynlib: readlineDll.}: File
  var outstream*{.importc: "rl_outstream", dynlib: readlineDll.}: File
  # If non-zero, Readline gives values of LINES and COLUMNS from the environment
  #   greater precedence than values fetched from the kernel when computing the
  #   screen dimensions. 
  var prefer_env_winsize*{.importc: "rl_prefer_env_winsize", dynlib: readlineDll.}: cint
  # If non-zero, then this is the address of a function to call just
  #   before readline_internal () prints the first prompt. 
  var startup_hook*{.importc: "rl_startup_hook", dynlib: readlineDll.}:  hook_func
  # If non-zero, this is the address of a function to call just before
  #   readline_internal_setup () returns and readline_internal starts
  #   reading input characters. 
  var pre_input_hook*{.importc: "rl_pre_input_hook", dynlib: readlineDll.}: hook_func
  # The address of a function to call periodically while Readline is
  #   awaiting character input, or NULL, for no event handling. 
  var event_hook*{.importc: "rl_event_hook", dynlib: readlineDll.}: hook_func
  # The address of the function to call to fetch a character from the current
  #   Readline input stream 
  var getc_function*{.importc: "rl_getc_function", dynlib: readlineDll.}: getc_func
  var redisplay_function*{.importc: "rl_redisplay_function", dynlib: readlineDll.}: voidfunc
  var prep_term_function*{.importc: "rl_prep_term_function", dynlib: readlineDll.}: vintfunc
  var deprep_term_function*{.importc: "rl_deprep_term_function", 
                             dynlib: readlineDll.}: voidfunc
  # Dispatch variables. 
  var executing_keymap*{.importc: "rl_executing_keymap", dynlib: readlineDll.}: PKeymap
  var binding_keymap*{.importc: "rl_binding_keymap", dynlib: readlineDll.}: PKeymap
  # Display variables. 
  # If non-zero, readline will erase the entire line, including any prompt,
  #   if the only thing typed on an otherwise-blank line is something bound to
  #   rl_newline. 
  var erase_empty_line*{.importc: "rl_erase_empty_line", dynlib: readlineDll.}: cint
  # If non-zero, the application has already printed the prompt (rl_prompt)
  #   before calling readline, so readline should not output it the first time
  #   redisplay is done. 
  var already_prompted*{.importc: "rl_already_prompted", dynlib: readlineDll.}: cint
  # A non-zero value means to read only this many characters rather than
  #   up to a character bound to accept-line. 
  var num_chars_to_read*{.importc: "rl_num_chars_to_read", dynlib: readlineDll.}: cint
  # The text of a currently-executing keyboard macro. 
  var executing_macro*{.importc: "rl_executing_macro", dynlib: readlineDll.}: cstring
  # Variables to control readline signal handling. 
  # If non-zero, readline will install its own signal handlers for
  #   SIGINT, SIGTERM, SIGQUIT, SIGALRM, SIGTSTP, SIGTTIN, and SIGTTOU. 
  var catch_signals*{.importc: "rl_catch_signals", dynlib: readlineDll.}: cint
  # If non-zero, readline will install a signal handler for SIGWINCH
  #   that also attempts to call any calling application's SIGWINCH signal
  #   handler.  Note that the terminal is not cleaned up before the
  #   application's signal handler is called; use rl_cleanup_after_signal()
  #   to do that. 
  var catch_sigwinch*{.importc: "rl_catch_sigwinch", dynlib: readlineDll.}: cint
  # Completion variables. 
  # Pointer to the generator function for completion_matches ().
  #   NULL means to use rl_filename_completion_function (), the default
  #   filename completer. 
  var completion_entry_function*{.importc: "rl_completion_entry_function", 
                                  dynlib: readlineDll.}: compentry_func
  # Optional generator for menu completion.  Default is
  #   rl_completion_entry_function (rl_filename_completion_function). 
  var menu_completion_entry_function*{.importc: "rl_menu_completion_entry_function", 
                                       dynlib: readlineDll.}: compentry_func
  # If rl_ignore_some_completions_function is non-NULL it is the address
  #   of a function to call after all of the possible matches have been
  #   generated, but before the actual completion is done to the input line.
  #   The function is called with one argument; a NULL terminated array
  #   of (char *).  If your function removes any of the elements, they
  #   must be free()'ed. 
  var ignore_some_completions_function*{.
      importc: "rl_ignore_some_completions_function", dynlib: readlineDll.}: compignore_func
  # Pointer to alternative function to create matches.
  #   Function is called with TEXT, START, and END.
  #   START and END are indices in RL_LINE_BUFFER saying what the boundaries
  #   of TEXT are.
  #   If this function exists and returns NULL then call the value of
  #   rl_completion_entry_function to try to match, otherwise use the
  #   array of strings returned. 
  var attempted_completion_function*{.importc: "rl_attempted_completion_function", 
                                      dynlib: readlineDll.}: completion_func
  # The basic list of characters that signal a break between words for the
  #   completer routine.  The initial contents of this variable is what
  #   breaks words in the shell, i.e. "n\"\\'`@$>". 
  var basic_word_break_characters*{.importc: "rl_basic_word_break_characters", 
                                    dynlib: readlineDll.}: cstring
  # The list of characters that signal a break between words for
  #   rl_complete_internal.  The default list is the contents of
  #   rl_basic_word_break_characters.  
  var completer_word_break_characters*{.importc: "rl_completer_word_break_characters", 
                                        dynlib: readlineDll.}: cstring
  # Hook function to allow an application to set the completion word
  #   break characters before readline breaks up the line.  Allows
  #   position-dependent word break characters. 
  var completion_word_break_hook*{.importc: "rl_completion_word_break_hook", 
                                   dynlib: readlineDll.}: cpvfunc
  # List of characters which can be used to quote a substring of the line.
  #   Completion occurs on the entire substring, and within the substring   
  #   rl_completer_word_break_characters are treated as any other character,
  #   unless they also appear within this list. 
  var completer_quote_characters*{.importc: "rl_completer_quote_characters", 
                                   dynlib: readlineDll.}: cstring
  # List of quote characters which cause a word break. 
  var basic_quote_characters*{.importc: "rl_basic_quote_characters", 
                               dynlib: readlineDll.}: cstring
  # List of characters that need to be quoted in filenames by the completer. 
  var filename_quote_characters*{.importc: "rl_filename_quote_characters", 
                                  dynlib: readlineDll.}: cstring
  # List of characters that are word break characters, but should be left
  #   in TEXT when it is passed to the completion function.  The shell uses
  #   this to help determine what kind of completing to do. 
  var special_prefixes*{.importc: "rl_special_prefixes", dynlib: readlineDll.}: cstring
  # If non-zero, then this is the address of a function to call when
  #   completing on a directory name.  The function is called with
  #   the address of a string (the current directory name) as an arg.  It
  #   changes what is displayed when the possible completions are printed
  #   or inserted. 
  var directory_completion_hook*{.importc: "rl_directory_completion_hook", 
                                  dynlib: readlineDll.}: icppfunc
  # If non-zero, this is the address of a function to call when completing
  #   a directory name.  This function takes the address of the directory name
  #   to be modified as an argument.  Unlike rl_directory_completion_hook, it
  #   only modifies the directory name used in opendir(2), not what is displayed
  #   when the possible completions are printed or inserted.  It is called
  #   before rl_directory_completion_hook.  I'm not happy with how this works
  #   yet, so it's undocumented. 
  var directory_rewrite_hook*{.importc: "rl_directory_rewrite_hook", 
                               dynlib: readlineDll.}: icppfunc
  # If non-zero, this is the address of a function to call when reading
  #   directory entries from the filesystem for completion and comparing
  #   them to the partial word to be completed.  The function should
  #   either return its first argument (if no conversion takes place) or
  #   newly-allocated memory.  This can, for instance, convert filenames
  #   between character sets for comparison against what's typed at the
  #   keyboard.  The returned value is what is added to the list of
  #   matches.  The second argument is the length of the filename to be
  #   converted. 
  var filename_rewrite_hook*{.importc: "rl_filename_rewrite_hook", 
                              dynlib: readlineDll.}: dequote_func
  # If non-zero, then this is the address of a function to call when
  #   completing a word would normally display the list of possible matches.
  #   This function is called instead of actually doing the display.
  #   It takes three arguments: (char **matches, int num_matches, int max_length)
  #   where MATCHES is the array of strings that matched, NUM_MATCHES is the
  #   number of strings in that array, and MAX_LENGTH is the length of the
  #   longest string in that array. 
  var completion_display_matches_hook*{.importc: "rl_completion_display_matches_hook", 
                                        dynlib: readlineDll.}: compdisp_func
  # Non-zero means that the results of the matches are to be treated
  #   as filenames.  This is ALWAYS zero on entry, and can only be changed
  #   within a completion entry finder function. 
  var filename_completion_desired*{.importc: "rl_filename_completion_desired", 
                                    dynlib: readlineDll.}: cint
  # Non-zero means that the results of the matches are to be quoted using
  #   double quotes (or an application-specific quoting mechanism) if the
  #   filename contains any characters in rl_word_break_chars.  This is
  #   ALWAYS non-zero on entry, and can only be changed within a completion
  #   entry finder function. 
  var filename_quoting_desired*{.importc: "rl_filename_quoting_desired", 
                                 dynlib: readlineDll.}: cint
  # Set to a function to quote a filename in an application-specific fashion.
  #   Called with the text to quote, the type of match found (single or multiple)
  #   and a pointer to the quoting character to be used, which the function can
  #   reset if desired. 
  var filename_quoting_function*{.importc: "rl_filename_quoting_function", 
                                  dynlib: readlineDll.}: quote_func
  # Function to call to remove quoting characters from a filename.  Called
  #   before completion is attempted, so the embedded quotes do not interfere
  #   with matching names in the file system. 
  var filename_dequoting_function*{.importc: "rl_filename_dequoting_function", 
                                    dynlib: readlineDll.}: dequote_func
  # Function to call to decide whether or not a word break character is
  #   quoted.  If a character is quoted, it does not break words for the
  #   completer. 
  var char_is_quoted_p*{.importc: "rl_char_is_quoted_p", dynlib: readlineDll.}: linebuf_func
  # Non-zero means to suppress normal filename completion after the
  #   user-specified completion function has been called. 
  var attempted_completion_over*{.importc: "rl_attempted_completion_over", 
                                  dynlib: readlineDll.}: cint
  # Set to a character describing the type of completion being attempted by
  #   rl_complete_internal; available for use by application completion
  #   functions. 
  var completion_type*{.importc: "rl_completion_type", dynlib: readlineDll.}: cint
  # Set to the last key used to invoke one of the completion functions 
  var completion_invoking_key*{.importc: "rl_completion_invoking_key", 
                                dynlib: readlineDll.}: cint
  # Up to this many items will be displayed in response to a
  #   possible-completions call.  After that, we ask the user if she
  #   is sure she wants to see them all.  The default value is 100. 
  var completion_query_items*{.importc: "rl_completion_query_items", 
                               dynlib: readlineDll.}: cint
  # Character appended to completed words when at the end of the line.  The
  #   default is a space.  Nothing is added if this is '\0'. 
  var completion_append_character*{.importc: "rl_completion_append_character", 
                                    dynlib: readlineDll.}: cint
  # If set to non-zero by an application completion function,
  #   rl_completion_append_character will not be appended. 
  var completion_suppress_append*{.importc: "rl_completion_suppress_append", 
                                   dynlib: readlineDll.}: cint
  # Set to any quote character readline thinks it finds before any application
  #   completion function is called. 
  var completion_quote_character*{.importc: "rl_completion_quote_character", 
                                   dynlib: readlineDll.}: cint
  # Set to a non-zero value if readline found quoting anywhere in the word to
  #   be completed; set before any application completion function is called. 
  var completion_found_quote*{.importc: "rl_completion_found_quote", 
                               dynlib: readlineDll.}: cint
  # If non-zero, the completion functions don't append any closing quote.
  #   This is set to 0 by rl_complete_internal and may be changed by an
  #   application-specific completion function. 
  var completion_suppress_quote*{.importc: "rl_completion_suppress_quote", 
                                  dynlib: readlineDll.}: cint
  # If non-zero, readline will sort the completion matches.  On by default. 
  var sort_completion_matches*{.importc: "rl_sort_completion_matches", 
                                dynlib: readlineDll.}: cint
  # If non-zero, a slash will be appended to completed filenames that are
  #   symbolic links to directory names, subject to the value of the
  #   mark-directories variable (which is user-settable).  This exists so
  #   that application completion functions can override the user's preference
  #   (set via the mark-symlinked-directories variable) if appropriate.
  #   It's set to the value of _rl_complete_mark_symlink_dirs in
  #   rl_complete_internal before any application-specific completion
  #   function is called, so without that function doing anything, the user's
  #   preferences are honored. 
  var completion_mark_symlink_dirs*{.importc: "rl_completion_mark_symlink_dirs", 
                                     dynlib: readlineDll.}: cint
  # If non-zero, then disallow duplicates in the matches. 
  var ignore_completion_duplicates*{.importc: "rl_ignore_completion_duplicates", 
                                     dynlib: readlineDll.}: cint
  # If this is non-zero, completion is (temporarily) inhibited, and the
  #   completion character will be inserted as any other. 
  var inhibit_completion*{.importc: "rl_inhibit_completion", dynlib: readlineDll.}: cint
# Input error; can be returned by (*rl_getc_function) if readline is reading
#   a top-level command (RL_ISSTATE (RL_STATE_READCMD)). 

const 
  READERR* = (- 2)

# Definitions available for use by readline clients. 

const 
  PROMPT_START_IGNORE* = '\x01'
  PROMPT_END_IGNORE* = '\x02'

# Possible values for do_replace argument to rl_filename_quoting_function,
#   called by rl_complete_internal. 

const 
  NO_MATCH* = 0
  SINGLE_MATCH* = 1
  MULT_MATCH* = 2

# Possible state values for rl_readline_state 

const 
  STATE_NONE* = 0x00000000    # no state; before first call 
  STATE_INITIALIZING* = 0x00000001 # initializing 
  STATE_INITIALIZED* = 0x00000002 # initialization done 
  STATE_TERMPREPPED* = 0x00000004 # terminal is prepped 
  STATE_READCMD* = 0x00000008 # reading a command key 
  STATE_METANEXT* = 0x00000010 # reading input after ESC 
  STATE_DISPATCHING* = 0x00000020 # dispatching to a command 
  STATE_MOREINPUT* = 0x00000040 # reading more input in a command function 
  STATE_ISEARCH* = 0x00000080 # doing incremental search 
  STATE_NSEARCH* = 0x00000100 # doing non-inc search 
  STATE_SEARCH* = 0x00000200  # doing a history search 
  STATE_NUMERICARG* = 0x00000400 # reading numeric argument 
  STATE_MACROINPUT* = 0x00000800 # getting input from a macro 
  STATE_MACRODEF* = 0x00001000 # defining keyboard macro 
  STATE_OVERWRITE* = 0x00002000 # overwrite mode 
  STATE_COMPLETING* = 0x00004000 # doing completion 
  STATE_SIGHANDLER* = 0x00008000 # in readline sighandler 
  STATE_UNDOING* = 0x00010000 # doing an undo 
  STATE_INPUTPENDING* = 0x00020000 # rl_execute_next called 
  STATE_TTYCSAVED* = 0x00040000 # tty special chars saved 
  STATE_CALLBACK* = 0x00080000 # using the callback interface 
  STATE_VIMOTION* = 0x00100000 # reading vi motion arg 
  STATE_MULTIKEY* = 0x00200000 # reading multiple-key command 
  STATE_VICMDONCE* = 0x00400000 # entered vi command mode at least once 
  STATE_REDISPLAYING* = 0x00800000 # updating terminal display 
  STATE_DONE* = 0x01000000    # done; accepted line 

template SETSTATE*(x: expr): stmt = 
  readline_state = readline_state or (x)

template UNSETSTATE*(x: expr): stmt = 
  readline_state = readline_state and not (x)

template ISSTATE*(x: expr): expr = 
  (readline_state and x) != 0

type 
  Treadline_state*{.pure, final.} = object 
    point*: cint              # line state 
    theEnd*: cint
    mark*: cint
    buffer*: cstring
    buflen*: cint
    ul*: ptr TUNDO_LIST
    prompt*: cstring          # global state 
    rlstate*: cint
    done*: cint
    kmap*: PKeymap            # input state 
    lastfunc*: TCommandFunc
    insmode*: cint
    edmode*: cint
    kseqlen*: cint
    inf*: File
    outf*: File
    pendingin*: cint
    theMacro*: cstring        # signal state 
    catchsigs*: cint
    catchsigwinch*: cint      # search state 
                              # completion state 
                              # options state 
                              # reserved for future expansion, so the struct size doesn't change 
    reserved*: array[0..64 - 1, char]


proc save_state*(a2: ptr Treadline_state): cint{.cdecl, 
    importc: "rl_save_state", dynlib: readlineDll.}
proc restore_state*(a2: ptr Treadline_state): cint{.cdecl, 
    importc: "rl_restore_state", dynlib: readlineDll.}
