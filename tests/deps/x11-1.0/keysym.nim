#
#Converted from X11/keysym.h and X11/keysymdef.h
#
#Capital letter consts renamed from XK_... to XKc_...
# (since Pascal isn't case-sensitive)
#
#i.e.
#C      Pascal
#XK_a   XK_a
#XK_A   XKc_A
#

#* default keysyms *
import x

const 
  XK_VoidSymbol*: TKeySym = 0x00FFFFFF # void symbol 

when defined(XK_MISCELLANY) or true: 
  const
    #*
    # * TTY Functions, cleverly chosen to map to ascii, for convenience of
    # * programming, but could have been arbitrary (at the cost of lookup
    # * tables in client code.
    # *
    XK_BackSpace*: TKeySym = 0x0000FF08  # back space, back char 
    XK_Tab*: TKeySym = 0x0000FF09
    XK_Linefeed*: TKeySym = 0x0000FF0A   # Linefeed, LF 
    XK_Clear*: TKeySym = 0x0000FF0B
    XK_Return*: TKeySym = 0x0000FF0D     # Return, enter 
    XK_Pause*: TKeySym = 0x0000FF13      # Pause, hold 
    XK_Scroll_Lock*: TKeySym = 0x0000FF14
    XK_Sys_Req*: TKeySym = 0x0000FF15
    XK_Escape*: TKeySym = 0x0000FF1B
    XK_Delete*: TKeySym = 0x0000FFFF     # Delete, rubout \
                                # International & multi-key character composition 
    XK_Multi_key*: TKeySym = 0x0000FF20  # Multi-key character compose 
    XK_Codeinput*: TKeySym = 0x0000FF37
    XK_SingleCandidate*: TKeySym = 0x0000FF3C
    XK_MultipleCandidate*: TKeySym = 0x0000FF3D
    XK_PreviousCandidate*: TKeySym = 0x0000FF3E # Japanese keyboard support 
    XK_Kanji*: TKeySym = 0x0000FF21      # Kanji, Kanji convert 
    XK_Muhenkan*: TKeySym = 0x0000FF22   # Cancel Conversion 
    XK_Henkan_Mode*: TKeySym = 0x0000FF23 # Start/Stop Conversion 
    XK_Henkan*: TKeySym = 0x0000FF23     # Alias for Henkan_Mode 
    XK_Romaji*: TKeySym = 0x0000FF24     # to Romaji 
    XK_Hiragana*: TKeySym = 0x0000FF25   # to Hiragana 
    XK_Katakana*: TKeySym = 0x0000FF26   # to Katakana 
    XK_Hiragana_Katakana*: TKeySym = 0x0000FF27 # Hiragana/Katakana toggle 
    XK_Zenkaku*: TKeySym = 0x0000FF28    # to Zenkaku 
    XK_Hankaku*: TKeySym = 0x0000FF29    # to Hankaku 
    XK_Zenkaku_Hankaku*: TKeySym = 0x0000FF2A # Zenkaku/Hankaku toggle 
    XK_Touroku*: TKeySym = 0x0000FF2B    # Add to Dictionary 
    XK_Massyo*: TKeySym = 0x0000FF2C     # Delete from Dictionary 
    XK_Kana_Lock*: TKeySym = 0x0000FF2D  # Kana Lock 
    XK_Kana_Shift*: TKeySym = 0x0000FF2E # Kana Shift 
    XK_Eisu_Shift*: TKeySym = 0x0000FF2F # Alphanumeric Shift 
    XK_Eisu_toggle*: TKeySym = 0x0000FF30 # Alphanumeric toggle 
    XK_Kanji_Bangou*: TKeySym = 0x0000FF37 # Codeinput 
    XK_Zen_Koho*: TKeySym = 0x0000FF3D   # Multiple/All Candidate(s) 
    XK_Mae_Koho*: TKeySym = 0x0000FF3E   # Previous Candidate \
                                # = $FF31 thru = $FF3F are under XK_KOREAN 
                                # Cursor control & motion 
    XK_Home*: TKeySym = 0x0000FF50
    XK_Left*: TKeySym = 0x0000FF51       # Move left, left arrow 
    XK_Up*: TKeySym = 0x0000FF52         # Move up, up arrow 
    XK_Right*: TKeySym = 0x0000FF53      # Move right, right arrow 
    XK_Down*: TKeySym = 0x0000FF54       # Move down, down arrow 
    XK_Prior*: TKeySym = 0x0000FF55      # Prior, previous 
    XK_Page_Up*: TKeySym = 0x0000FF55
    XK_Next*: TKeySym = 0x0000FF56       # Next 
    XK_Page_Down*: TKeySym = 0x0000FF56
    XK_End*: TKeySym = 0x0000FF57        # EOL 
    XK_Begin*: TKeySym = 0x0000FF58      # BOL \
                                # Misc Functions 
    XK_Select*: TKeySym = 0x0000FF60     # Select, mark 
    XK_Print*: TKeySym = 0x0000FF61
    XK_Execute*: TKeySym = 0x0000FF62    # Execute, run, do 
    XK_Insert*: TKeySym = 0x0000FF63     # Insert, insert here 
    XK_Undo*: TKeySym = 0x0000FF65       # Undo, oops 
    XK_Redo*: TKeySym = 0x0000FF66       # redo, again 
    XK_Menu*: TKeySym = 0x0000FF67
    XK_Find*: TKeySym = 0x0000FF68       # Find, search 
    XK_Cancel*: TKeySym = 0x0000FF69     # Cancel, stop, abort, exit 
    XK_Help*: TKeySym = 0x0000FF6A       # Help 
    XK_Break*: TKeySym = 0x0000FF6B
    XK_Mode_switch*: TKeySym = 0x0000FF7E # Character set switch 
    XK_script_switch*: TKeySym = 0x0000FF7E # Alias for mode_switch 
    XK_Num_Lock*: TKeySym = 0x0000FF7F   # Keypad Functions, keypad numbers cleverly chosen to map to ascii 
    XK_KP_Space*: TKeySym = 0x0000FF80   # space 
    XK_KP_Tab*: TKeySym = 0x0000FF89
    XK_KP_Enter*: TKeySym = 0x0000FF8D   # enter 
    XK_KP_F1*: TKeySym = 0x0000FF91      # PF1, KP_A, ... 
    XK_KP_F2*: TKeySym = 0x0000FF92
    XK_KP_F3*: TKeySym = 0x0000FF93
    XK_KP_F4*: TKeySym = 0x0000FF94
    XK_KP_Home*: TKeySym = 0x0000FF95
    XK_KP_Left*: TKeySym = 0x0000FF96
    XK_KP_Up*: TKeySym = 0x0000FF97
    XK_KP_Right*: TKeySym = 0x0000FF98
    XK_KP_Down*: TKeySym = 0x0000FF99
    XK_KP_Prior*: TKeySym = 0x0000FF9A
    XK_KP_Page_Up*: TKeySym = 0x0000FF9A
    XK_KP_Next*: TKeySym = 0x0000FF9B
    XK_KP_Page_Down*: TKeySym = 0x0000FF9B
    XK_KP_End*: TKeySym = 0x0000FF9C
    XK_KP_Begin*: TKeySym = 0x0000FF9D
    XK_KP_Insert*: TKeySym = 0x0000FF9E
    XK_KP_Delete*: TKeySym = 0x0000FF9F
    XK_KP_Equal*: TKeySym = 0x0000FFBD   # equals 
    XK_KP_Multiply*: TKeySym = 0x0000FFAA
    XK_KP_Add*: TKeySym = 0x0000FFAB
    XK_KP_Separator*: TKeySym = 0x0000FFAC # separator, often comma 
    XK_KP_Subtract*: TKeySym = 0x0000FFAD
    XK_KP_Decimal*: TKeySym = 0x0000FFAE
    XK_KP_Divide*: TKeySym = 0x0000FFAF
    XK_KP_0*: TKeySym = 0x0000FFB0
    XK_KP_1*: TKeySym = 0x0000FFB1
    XK_KP_2*: TKeySym = 0x0000FFB2
    XK_KP_3*: TKeySym = 0x0000FFB3
    XK_KP_4*: TKeySym = 0x0000FFB4
    XK_KP_5*: TKeySym = 0x0000FFB5
    XK_KP_6*: TKeySym = 0x0000FFB6
    XK_KP_7*: TKeySym = 0x0000FFB7
    XK_KP_8*: TKeySym = 0x0000FFB8
    XK_KP_9*: TKeySym = 0x0000FFB9 #*\
                          # * Auxilliary Functions; note the duplicate definitions for left and right
                          # * function keys;  Sun keyboards and a few other manufactures have such
                          # * function key groups on the left and/or right sides of the keyboard.
                          # * We've not found a keyboard with more than 35 function keys total.
                          # *
    XK_F1*: TKeySym = 0x0000FFBE
    XK_F2*: TKeySym = 0x0000FFBF
    XK_F3*: TKeySym = 0x0000FFC0
    XK_F4*: TKeySym = 0x0000FFC1
    XK_F5*: TKeySym = 0x0000FFC2
    XK_F6*: TKeySym = 0x0000FFC3
    XK_F7*: TKeySym = 0x0000FFC4
    XK_F8*: TKeySym = 0x0000FFC5
    XK_F9*: TKeySym = 0x0000FFC6
    XK_F10*: TKeySym = 0x0000FFC7
    XK_F11*: TKeySym = 0x0000FFC8
    XK_L1*: TKeySym = 0x0000FFC8
    XK_F12*: TKeySym = 0x0000FFC9
    XK_L2*: TKeySym = 0x0000FFC9
    XK_F13*: TKeySym = 0x0000FFCA
    XK_L3*: TKeySym = 0x0000FFCA
    XK_F14*: TKeySym = 0x0000FFCB
    XK_L4*: TKeySym = 0x0000FFCB
    XK_F15*: TKeySym = 0x0000FFCC
    XK_L5*: TKeySym = 0x0000FFCC
    XK_F16*: TKeySym = 0x0000FFCD
    XK_L6*: TKeySym = 0x0000FFCD
    XK_F17*: TKeySym = 0x0000FFCE
    XK_L7*: TKeySym = 0x0000FFCE
    XK_F18*: TKeySym = 0x0000FFCF
    XK_L8*: TKeySym = 0x0000FFCF
    XK_F19*: TKeySym = 0x0000FFD0
    XK_L9*: TKeySym = 0x0000FFD0
    XK_F20*: TKeySym = 0x0000FFD1
    XK_L10*: TKeySym = 0x0000FFD1
    XK_F21*: TKeySym = 0x0000FFD2
    XK_R1*: TKeySym = 0x0000FFD2
    XK_F22*: TKeySym = 0x0000FFD3
    XK_R2*: TKeySym = 0x0000FFD3
    XK_F23*: TKeySym = 0x0000FFD4
    XK_R3*: TKeySym = 0x0000FFD4
    XK_F24*: TKeySym = 0x0000FFD5
    XK_R4*: TKeySym = 0x0000FFD5
    XK_F25*: TKeySym = 0x0000FFD6
    XK_R5*: TKeySym = 0x0000FFD6
    XK_F26*: TKeySym = 0x0000FFD7
    XK_R6*: TKeySym = 0x0000FFD7
    XK_F27*: TKeySym = 0x0000FFD8
    XK_R7*: TKeySym = 0x0000FFD8
    XK_F28*: TKeySym = 0x0000FFD9
    XK_R8*: TKeySym = 0x0000FFD9
    XK_F29*: TKeySym = 0x0000FFDA
    XK_R9*: TKeySym = 0x0000FFDA
    XK_F30*: TKeySym = 0x0000FFDB
    XK_R10*: TKeySym = 0x0000FFDB
    XK_F31*: TKeySym = 0x0000FFDC
    XK_R11*: TKeySym = 0x0000FFDC
    XK_F32*: TKeySym = 0x0000FFDD
    XK_R12*: TKeySym = 0x0000FFDD
    XK_F33*: TKeySym = 0x0000FFDE
    XK_R13*: TKeySym = 0x0000FFDE
    XK_F34*: TKeySym = 0x0000FFDF
    XK_R14*: TKeySym = 0x0000FFDF
    XK_F35*: TKeySym = 0x0000FFE0
    XK_R15*: TKeySym = 0x0000FFE0        # Modifiers 
    XK_Shift_L*: TKeySym = 0x0000FFE1    # Left shift 
    XK_Shift_R*: TKeySym = 0x0000FFE2    # Right shift 
    XK_Control_L*: TKeySym = 0x0000FFE3  # Left control 
    XK_Control_R*: TKeySym = 0x0000FFE4  # Right control 
    XK_Caps_Lock*: TKeySym = 0x0000FFE5  # Caps lock 
    XK_Shift_Lock*: TKeySym = 0x0000FFE6 # Shift lock 
    XK_Meta_L*: TKeySym = 0x0000FFE7     # Left meta 
    XK_Meta_R*: TKeySym = 0x0000FFE8     # Right meta 
    XK_Alt_L*: TKeySym = 0x0000FFE9      # Left alt 
    XK_Alt_R*: TKeySym = 0x0000FFEA      # Right alt 
    XK_Super_L*: TKeySym = 0x0000FFEB    # Left super 
    XK_Super_R*: TKeySym = 0x0000FFEC    # Right super 
    XK_Hyper_L*: TKeySym = 0x0000FFED    # Left hyper 
    XK_Hyper_R*: TKeySym = 0x0000FFEE    # Right hyper 
# XK_MISCELLANY 
#*
# * ISO 9995 Function and Modifier Keys
# * Byte 3 = = $FE
# *

when defined(XK_XKB_KEYS) or true: 
  const
    XK_ISO_Lock*: TKeySym = 0x0000FE01
    XK_ISO_Level2_Latch*: TKeySym = 0x0000FE02
    XK_ISO_Level3_Shift*: TKeySym = 0x0000FE03
    XK_ISO_Level3_Latch*: TKeySym = 0x0000FE04
    XK_ISO_Level3_Lock*: TKeySym = 0x0000FE05
    XK_ISO_Group_Shift*: TKeySym = 0x0000FF7E # Alias for mode_switch 
    XK_ISO_Group_Latch*: TKeySym = 0x0000FE06
    XK_ISO_Group_Lock*: TKeySym = 0x0000FE07
    XK_ISO_Next_Group*: TKeySym = 0x0000FE08
    XK_ISO_Next_Group_Lock*: TKeySym = 0x0000FE09
    XK_ISO_Prev_Group*: TKeySym = 0x0000FE0A
    XK_ISO_Prev_Group_Lock*: TKeySym = 0x0000FE0B
    XK_ISO_First_Group*: TKeySym = 0x0000FE0C
    XK_ISO_First_Group_Lock*: TKeySym = 0x0000FE0D
    XK_ISO_Last_Group*: TKeySym = 0x0000FE0E
    XK_ISO_Last_Group_Lock*: TKeySym = 0x0000FE0F
    XK_ISO_Left_Tab*: TKeySym = 0x0000FE20
    XK_ISO_Move_Line_Up*: TKeySym = 0x0000FE21
    XK_ISO_Move_Line_Down*: TKeySym = 0x0000FE22
    XK_ISO_Partial_Line_Up*: TKeySym = 0x0000FE23
    XK_ISO_Partial_Line_Down*: TKeySym = 0x0000FE24
    XK_ISO_Partial_Space_Left*: TKeySym = 0x0000FE25
    XK_ISO_Partial_Space_Right*: TKeySym = 0x0000FE26
    XK_ISO_Set_Margin_Left*: TKeySym = 0x0000FE27
    XK_ISO_Set_Margin_Right*: TKeySym = 0x0000FE28
    XK_ISO_Release_Margin_Left*: TKeySym = 0x0000FE29
    XK_ISO_Release_Margin_Right*: TKeySym = 0x0000FE2A
    XK_ISO_Release_Both_Margins*: TKeySym = 0x0000FE2B
    XK_ISO_Fast_Cursor_Left*: TKeySym = 0x0000FE2C
    XK_ISO_Fast_Cursor_Right*: TKeySym = 0x0000FE2D
    XK_ISO_Fast_Cursor_Up*: TKeySym = 0x0000FE2E
    XK_ISO_Fast_Cursor_Down*: TKeySym = 0x0000FE2F
    XK_ISO_Continuous_Underline*: TKeySym = 0x0000FE30
    XK_ISO_Discontinuous_Underline*: TKeySym = 0x0000FE31
    XK_ISO_Emphasize*: TKeySym = 0x0000FE32
    XK_ISO_Center_Object*: TKeySym = 0x0000FE33
    XK_ISO_Enter*: TKeySym = 0x0000FE34
    XK_dead_grave*: TKeySym = 0x0000FE50
    XK_dead_acute*: TKeySym = 0x0000FE51
    XK_dead_circumflex*: TKeySym = 0x0000FE52
    XK_dead_tilde*: TKeySym = 0x0000FE53
    XK_dead_macron*: TKeySym = 0x0000FE54
    XK_dead_breve*: TKeySym = 0x0000FE55
    XK_dead_abovedot*: TKeySym = 0x0000FE56
    XK_dead_diaeresis*: TKeySym = 0x0000FE57
    XK_dead_abovering*: TKeySym = 0x0000FE58
    XK_dead_doubleacute*: TKeySym = 0x0000FE59
    XK_dead_caron*: TKeySym = 0x0000FE5A
    XK_dead_cedilla*: TKeySym = 0x0000FE5B
    XK_dead_ogonek*: TKeySym = 0x0000FE5C
    XK_dead_iota*: TKeySym = 0x0000FE5D
    XK_dead_voiced_sound*: TKeySym = 0x0000FE5E
    XK_dead_semivoiced_sound*: TKeySym = 0x0000FE5F
    XK_dead_belowdot*: TKeySym = 0x0000FE60
    XK_dead_hook*: TKeySym = 0x0000FE61
    XK_dead_horn*: TKeySym = 0x0000FE62
    XK_First_Virtual_Screen*: TKeySym = 0x0000FED0
    XK_Prev_Virtual_Screen*: TKeySym = 0x0000FED1
    XK_Next_Virtual_Screen*: TKeySym = 0x0000FED2
    XK_Last_Virtual_Screen*: TKeySym = 0x0000FED4
    XK_Terminate_Server*: TKeySym = 0x0000FED5
    XK_AccessX_Enable*: TKeySym = 0x0000FE70
    XK_AccessX_Feedback_Enable*: TKeySym = 0x0000FE71
    XK_RepeatKeys_Enable*: TKeySym = 0x0000FE72
    XK_SlowKeys_Enable*: TKeySym = 0x0000FE73
    XK_BounceKeys_Enable*: TKeySym = 0x0000FE74
    XK_StickyKeys_Enable*: TKeySym = 0x0000FE75
    XK_MouseKeys_Enable*: TKeySym = 0x0000FE76
    XK_MouseKeys_Accel_Enable*: TKeySym = 0x0000FE77
    XK_Overlay1_Enable*: TKeySym = 0x0000FE78
    XK_Overlay2_Enable*: TKeySym = 0x0000FE79
    XK_AudibleBell_Enable*: TKeySym = 0x0000FE7A
    XK_Pointer_Left*: TKeySym = 0x0000FEE0
    XK_Pointer_Right*: TKeySym = 0x0000FEE1
    XK_Pointer_Up*: TKeySym = 0x0000FEE2
    XK_Pointer_Down*: TKeySym = 0x0000FEE3
    XK_Pointer_UpLeft*: TKeySym = 0x0000FEE4
    XK_Pointer_UpRight*: TKeySym = 0x0000FEE5
    XK_Pointer_DownLeft*: TKeySym = 0x0000FEE6
    XK_Pointer_DownRight*: TKeySym = 0x0000FEE7
    XK_Pointer_Button_Dflt*: TKeySym = 0x0000FEE8
    XK_Pointer_Button1*: TKeySym = 0x0000FEE9
    XK_Pointer_Button2*: TKeySym = 0x0000FEEA
    XK_Pointer_Button3*: TKeySym = 0x0000FEEB
    XK_Pointer_Button4*: TKeySym = 0x0000FEEC
    XK_Pointer_Button5*: TKeySym = 0x0000FEED
    XK_Pointer_DblClick_Dflt*: TKeySym = 0x0000FEEE
    XK_Pointer_DblClick1*: TKeySym = 0x0000FEEF
    XK_Pointer_DblClick2*: TKeySym = 0x0000FEF0
    XK_Pointer_DblClick3*: TKeySym = 0x0000FEF1
    XK_Pointer_DblClick4*: TKeySym = 0x0000FEF2
    XK_Pointer_DblClick5*: TKeySym = 0x0000FEF3
    XK_Pointer_Drag_Dflt*: TKeySym = 0x0000FEF4
    XK_Pointer_Drag1*: TKeySym = 0x0000FEF5
    XK_Pointer_Drag2*: TKeySym = 0x0000FEF6
    XK_Pointer_Drag3*: TKeySym = 0x0000FEF7
    XK_Pointer_Drag4*: TKeySym = 0x0000FEF8
    XK_Pointer_Drag5*: TKeySym = 0x0000FEFD
    XK_Pointer_EnableKeys*: TKeySym = 0x0000FEF9
    XK_Pointer_Accelerate*: TKeySym = 0x0000FEFA
    XK_Pointer_DfltBtnNext*: TKeySym = 0x0000FEFB
    XK_Pointer_DfltBtnPrev*: TKeySym = 0x0000FEFC
  #*
  # * 3270 Terminal Keys
  # * Byte 3 = = $FD
  # *

when defined(XK_3270) or true: 
  const
    XK_3270_Duplicate*: TKeySym = 0x0000FD01
    XK_3270_FieldMark*: TKeySym = 0x0000FD02
    XK_3270_Right2*: TKeySym = 0x0000FD03
    XK_3270_Left2*: TKeySym = 0x0000FD04
    XK_3270_BackTab*: TKeySym = 0x0000FD05
    XK_3270_EraseEOF*: TKeySym = 0x0000FD06
    XK_3270_EraseInput*: TKeySym = 0x0000FD07
    XK_3270_Reset*: TKeySym = 0x0000FD08
    XK_3270_Quit*: TKeySym = 0x0000FD09
    XK_3270_PA1*: TKeySym = 0x0000FD0A
    XK_3270_PA2*: TKeySym = 0x0000FD0B
    XK_3270_PA3*: TKeySym = 0x0000FD0C
    XK_3270_Test*: TKeySym = 0x0000FD0D
    XK_3270_Attn*: TKeySym = 0x0000FD0E
    XK_3270_CursorBlink*: TKeySym = 0x0000FD0F
    XK_3270_AltCursor*: TKeySym = 0x0000FD10
    XK_3270_KeyClick*: TKeySym = 0x0000FD11
    XK_3270_Jump*: TKeySym = 0x0000FD12
    XK_3270_Ident*: TKeySym = 0x0000FD13
    XK_3270_Rule*: TKeySym = 0x0000FD14
    XK_3270_Copy*: TKeySym = 0x0000FD15
    XK_3270_Play*: TKeySym = 0x0000FD16
    XK_3270_Setup*: TKeySym = 0x0000FD17
    XK_3270_Record*: TKeySym = 0x0000FD18
    XK_3270_ChangeScreen*: TKeySym = 0x0000FD19
    XK_3270_DeleteWord*: TKeySym = 0x0000FD1A
    XK_3270_ExSelect*: TKeySym = 0x0000FD1B
    XK_3270_CursorSelect*: TKeySym = 0x0000FD1C
    XK_3270_PrintScreen*: TKeySym = 0x0000FD1D
    XK_3270_Enter*: TKeySym = 0x0000FD1E
#*
# *  Latin 1
# *  Byte 3 = 0
# *

when defined(XK_LATIN1) or true: 
  const
    XK_space*: TKeySym = 0x00000020
    XK_exclam*: TKeySym = 0x00000021
    XK_quotedbl*: TKeySym = 0x00000022
    XK_numbersign*: TKeySym = 0x00000023
    XK_dollar*: TKeySym = 0x00000024
    XK_percent*: TKeySym = 0x00000025
    XK_ampersand*: TKeySym = 0x00000026
    XK_apostrophe*: TKeySym = 0x00000027
    XK_quoteright*: TKeySym = 0x00000027 # deprecated 
    XK_parenleft*: TKeySym = 0x00000028
    XK_parenright*: TKeySym = 0x00000029
    XK_asterisk*: TKeySym = 0x0000002A
    XK_plus*: TKeySym = 0x0000002B
    XK_comma*: TKeySym = 0x0000002C
    XK_minus*: TKeySym = 0x0000002D
    XK_period*: TKeySym = 0x0000002E
    XK_slash*: TKeySym = 0x0000002F
    XK_0*: TKeySym = 0x00000030
    XK_1*: TKeySym = 0x00000031
    XK_2*: TKeySym = 0x00000032
    XK_3*: TKeySym = 0x00000033
    XK_4*: TKeySym = 0x00000034
    XK_5*: TKeySym = 0x00000035
    XK_6*: TKeySym = 0x00000036
    XK_7*: TKeySym = 0x00000037
    XK_8*: TKeySym = 0x00000038
    XK_9*: TKeySym = 0x00000039
    XK_colon*: TKeySym = 0x0000003A
    XK_semicolon*: TKeySym = 0x0000003B
    XK_less*: TKeySym = 0x0000003C
    XK_equal*: TKeySym = 0x0000003D
    XK_greater*: TKeySym = 0x0000003E
    XK_question*: TKeySym = 0x0000003F
    XK_at*: TKeySym = 0x00000040
    XKc_A*: TKeySym = 0x00000041
    XKc_B*: TKeySym = 0x00000042
    XKc_C*: TKeySym = 0x00000043
    XKc_D*: TKeySym = 0x00000044
    XKc_E*: TKeySym = 0x00000045
    XKc_F*: TKeySym = 0x00000046
    XKc_G*: TKeySym = 0x00000047
    XKc_H*: TKeySym = 0x00000048
    XKc_I*: TKeySym = 0x00000049
    XKc_J*: TKeySym = 0x0000004A
    XKc_K*: TKeySym = 0x0000004B
    XKc_L*: TKeySym = 0x0000004C
    XKc_M*: TKeySym = 0x0000004D
    XKc_N*: TKeySym = 0x0000004E
    XKc_O*: TKeySym = 0x0000004F
    XKc_P*: TKeySym = 0x00000050
    XKc_Q*: TKeySym = 0x00000051
    XKc_R*: TKeySym = 0x00000052
    XKc_S*: TKeySym = 0x00000053
    XKc_T*: TKeySym = 0x00000054
    XKc_U*: TKeySym = 0x00000055
    XKc_V*: TKeySym = 0x00000056
    XKc_W*: TKeySym = 0x00000057
    XKc_X*: TKeySym = 0x00000058
    XKc_Y*: TKeySym = 0x00000059
    XKc_Z*: TKeySym = 0x0000005A
    XK_bracketleft*: TKeySym = 0x0000005B
    XK_backslash*: TKeySym = 0x0000005C
    XK_bracketright*: TKeySym = 0x0000005D
    XK_asciicircum*: TKeySym = 0x0000005E
    XK_underscore*: TKeySym = 0x0000005F
    XK_grave*: TKeySym = 0x00000060
    XK_quoteleft*: TKeySym = 0x00000060  # deprecated 
    XK_a*: TKeySym = 0x00000061
    XK_b*: TKeySym = 0x00000062
    XK_c*: TKeySym = 0x00000063
    XK_d*: TKeySym = 0x00000064
    XK_e*: TKeySym = 0x00000065
    XK_f*: TKeySym = 0x00000066
    XK_g*: TKeySym = 0x00000067
    XK_h*: TKeySym = 0x00000068
    XK_i*: TKeySym = 0x00000069
    XK_j*: TKeySym = 0x0000006A
    XK_k*: TKeySym = 0x0000006B
    XK_l*: TKeySym = 0x0000006C
    XK_m*: TKeySym = 0x0000006D
    XK_n*: TKeySym = 0x0000006E
    XK_o*: TKeySym = 0x0000006F
    XK_p*: TKeySym = 0x00000070
    XK_q*: TKeySym = 0x00000071
    XK_r*: TKeySym = 0x00000072
    XK_s*: TKeySym = 0x00000073
    XK_t*: TKeySym = 0x00000074
    XK_u*: TKeySym = 0x00000075
    XK_v*: TKeySym = 0x00000076
    XK_w*: TKeySym = 0x00000077
    XK_x*: TKeySym = 0x00000078
    XK_y*: TKeySym = 0x00000079
    XK_z*: TKeySym = 0x0000007A
    XK_braceleft*: TKeySym = 0x0000007B
    XK_bar*: TKeySym = 0x0000007C
    XK_braceright*: TKeySym = 0x0000007D
    XK_asciitilde*: TKeySym = 0x0000007E
    XK_nobreakspace*: TKeySym = 0x000000A0
    XK_exclamdown*: TKeySym = 0x000000A1
    XK_cent*: TKeySym = 0x000000A2
    XK_sterling*: TKeySym = 0x000000A3
    XK_currency*: TKeySym = 0x000000A4
    XK_yen*: TKeySym = 0x000000A5
    XK_brokenbar*: TKeySym = 0x000000A6
    XK_section*: TKeySym = 0x000000A7
    XK_diaeresis*: TKeySym = 0x000000A8
    XK_copyright*: TKeySym = 0x000000A9
    XK_ordfeminine*: TKeySym = 0x000000AA
    XK_guillemotleft*: TKeySym = 0x000000AB # left angle quotation mark 
    XK_notsign*: TKeySym = 0x000000AC
    XK_hyphen*: TKeySym = 0x000000AD
    XK_registered*: TKeySym = 0x000000AE
    XK_macron*: TKeySym = 0x000000AF
    XK_degree*: TKeySym = 0x000000B0
    XK_plusminus*: TKeySym = 0x000000B1
    XK_twosuperior*: TKeySym = 0x000000B2
    XK_threesuperior*: TKeySym = 0x000000B3
    XK_acute*: TKeySym = 0x000000B4
    XK_mu*: TKeySym = 0x000000B5
    XK_paragraph*: TKeySym = 0x000000B6
    XK_periodcentered*: TKeySym = 0x000000B7
    XK_cedilla*: TKeySym = 0x000000B8
    XK_onesuperior*: TKeySym = 0x000000B9
    XK_masculine*: TKeySym = 0x000000BA
    XK_guillemotright*: TKeySym = 0x000000BB # right angle quotation mark 
    XK_onequarter*: TKeySym = 0x000000BC
    XK_onehalf*: TKeySym = 0x000000BD
    XK_threequarters*: TKeySym = 0x000000BE
    XK_questiondown*: TKeySym = 0x000000BF
    XKc_Agrave*: TKeySym = 0x000000C0
    XKc_Aacute*: TKeySym = 0x000000C1
    XKc_Acircumflex*: TKeySym = 0x000000C2
    XKc_Atilde*: TKeySym = 0x000000C3
    XKc_Adiaeresis*: TKeySym = 0x000000C4
    XKc_Aring*: TKeySym = 0x000000C5
    XKc_AE*: TKeySym = 0x000000C6
    XKc_Ccedilla*: TKeySym = 0x000000C7
    XKc_Egrave*: TKeySym = 0x000000C8
    XKc_Eacute*: TKeySym = 0x000000C9
    XKc_Ecircumflex*: TKeySym = 0x000000CA
    XKc_Ediaeresis*: TKeySym = 0x000000CB
    XKc_Igrave*: TKeySym = 0x000000CC
    XKc_Iacute*: TKeySym = 0x000000CD
    XKc_Icircumflex*: TKeySym = 0x000000CE
    XKc_Idiaeresis*: TKeySym = 0x000000CF
    XKc_ETH*: TKeySym = 0x000000D0
    XKc_Ntilde*: TKeySym = 0x000000D1
    XKc_Ograve*: TKeySym = 0x000000D2
    XKc_Oacute*: TKeySym = 0x000000D3
    XKc_Ocircumflex*: TKeySym = 0x000000D4
    XKc_Otilde*: TKeySym = 0x000000D5
    XKc_Odiaeresis*: TKeySym = 0x000000D6
    XK_multiply*: TKeySym = 0x000000D7
    XKc_Ooblique*: TKeySym = 0x000000D8
    XKc_Oslash*: TKeySym = XKc_Ooblique
    XKc_Ugrave*: TKeySym = 0x000000D9
    XKc_Uacute*: TKeySym = 0x000000DA
    XKc_Ucircumflex*: TKeySym = 0x000000DB
    XKc_Udiaeresis*: TKeySym = 0x000000DC
    XKc_Yacute*: TKeySym = 0x000000DD
    XKc_THORN*: TKeySym = 0x000000DE
    XK_ssharp*: TKeySym = 0x000000DF
    XK_agrave*: TKeySym = 0x000000E0
    XK_aacute*: TKeySym = 0x000000E1
    XK_acircumflex*: TKeySym = 0x000000E2
    XK_atilde*: TKeySym = 0x000000E3
    XK_adiaeresis*: TKeySym = 0x000000E4
    XK_aring*: TKeySym = 0x000000E5
    XK_ae*: TKeySym = 0x000000E6
    XK_ccedilla*: TKeySym = 0x000000E7
    XK_egrave*: TKeySym = 0x000000E8
    XK_eacute*: TKeySym = 0x000000E9
    XK_ecircumflex*: TKeySym = 0x000000EA
    XK_ediaeresis*: TKeySym = 0x000000EB
    XK_igrave*: TKeySym = 0x000000EC
    XK_iacute*: TKeySym = 0x000000ED
    XK_icircumflex*: TKeySym = 0x000000EE
    XK_idiaeresis*: TKeySym = 0x000000EF
    XK_eth*: TKeySym = 0x000000F0
    XK_ntilde*: TKeySym = 0x000000F1
    XK_ograve*: TKeySym = 0x000000F2
    XK_oacute*: TKeySym = 0x000000F3
    XK_ocircumflex*: TKeySym = 0x000000F4
    XK_otilde*: TKeySym = 0x000000F5
    XK_odiaeresis*: TKeySym = 0x000000F6
    XK_division*: TKeySym = 0x000000F7
    XK_oslash*: TKeySym = 0x000000F8
    XK_ooblique*: TKeySym = XK_oslash
    XK_ugrave*: TKeySym = 0x000000F9
    XK_uacute*: TKeySym = 0x000000FA
    XK_ucircumflex*: TKeySym = 0x000000FB
    XK_udiaeresis*: TKeySym = 0x000000FC
    XK_yacute*: TKeySym = 0x000000FD
    XK_thorn*: TKeySym = 0x000000FE
    XK_ydiaeresis*: TKeySym = 0x000000FF
# XK_LATIN1 
#*
# *   Latin 2
# *   Byte 3 = 1
# *

when defined(XK_LATIN2) or true: 
  const
    XKc_Aogonek*: TKeySym = 0x000001A1
    XK_breve*: TKeySym = 0x000001A2
    XKc_Lstroke*: TKeySym = 0x000001A3
    XKc_Lcaron*: TKeySym = 0x000001A5
    XKc_Sacute*: TKeySym = 0x000001A6
    XKc_Scaron*: TKeySym = 0x000001A9
    XKc_Scedilla*: TKeySym = 0x000001AA
    XKc_Tcaron*: TKeySym = 0x000001AB
    XKc_Zacute*: TKeySym = 0x000001AC
    XKc_Zcaron*: TKeySym = 0x000001AE
    XKc_Zabovedot*: TKeySym = 0x000001AF
    XK_aogonek*: TKeySym = 0x000001B1
    XK_ogonek*: TKeySym = 0x000001B2
    XK_lstroke*: TKeySym = 0x000001B3
    XK_lcaron*: TKeySym = 0x000001B5
    XK_sacute*: TKeySym = 0x000001B6
    XK_caron*: TKeySym = 0x000001B7
    XK_scaron*: TKeySym = 0x000001B9
    XK_scedilla*: TKeySym = 0x000001BA
    XK_tcaron*: TKeySym = 0x000001BB
    XK_zacute*: TKeySym = 0x000001BC
    XK_doubleacute*: TKeySym = 0x000001BD
    XK_zcaron*: TKeySym = 0x000001BE
    XK_zabovedot*: TKeySym = 0x000001BF
    XKc_Racute*: TKeySym = 0x000001C0
    XKc_Abreve*: TKeySym = 0x000001C3
    XKc_Lacute*: TKeySym = 0x000001C5
    XKc_Cacute*: TKeySym = 0x000001C6
    XKc_Ccaron*: TKeySym = 0x000001C8
    XKc_Eogonek*: TKeySym = 0x000001CA
    XKc_Ecaron*: TKeySym = 0x000001CC
    XKc_Dcaron*: TKeySym = 0x000001CF
    XKc_Dstroke*: TKeySym = 0x000001D0
    XKc_Nacute*: TKeySym = 0x000001D1
    XKc_Ncaron*: TKeySym = 0x000001D2
    XKc_Odoubleacute*: TKeySym = 0x000001D5
    XKc_Rcaron*: TKeySym = 0x000001D8
    XKc_Uring*: TKeySym = 0x000001D9
    XKc_Udoubleacute*: TKeySym = 0x000001DB
    XKc_Tcedilla*: TKeySym = 0x000001DE
    XK_racute*: TKeySym = 0x000001E0
    XK_abreve*: TKeySym = 0x000001E3
    XK_lacute*: TKeySym = 0x000001E5
    XK_cacute*: TKeySym = 0x000001E6
    XK_ccaron*: TKeySym = 0x000001E8
    XK_eogonek*: TKeySym = 0x000001EA
    XK_ecaron*: TKeySym = 0x000001EC
    XK_dcaron*: TKeySym = 0x000001EF
    XK_dstroke*: TKeySym = 0x000001F0
    XK_nacute*: TKeySym = 0x000001F1
    XK_ncaron*: TKeySym = 0x000001F2
    XK_odoubleacute*: TKeySym = 0x000001F5
    XK_udoubleacute*: TKeySym = 0x000001FB
    XK_rcaron*: TKeySym = 0x000001F8
    XK_uring*: TKeySym = 0x000001F9
    XK_tcedilla*: TKeySym = 0x000001FE
    XK_abovedot*: TKeySym = 0x000001FF
# XK_LATIN2 
#*
# *   Latin 3
# *   Byte 3 = 2
# *

when defined(XK_LATIN3) or true: 
  const
    XKc_Hstroke*: TKeySym = 0x000002A1
    XKc_Hcircumflex*: TKeySym = 0x000002A6
    XKc_Iabovedot*: TKeySym = 0x000002A9
    XKc_Gbreve*: TKeySym = 0x000002AB
    XKc_Jcircumflex*: TKeySym = 0x000002AC
    XK_hstroke*: TKeySym = 0x000002B1
    XK_hcircumflex*: TKeySym = 0x000002B6
    XK_idotless*: TKeySym = 0x000002B9
    XK_gbreve*: TKeySym = 0x000002BB
    XK_jcircumflex*: TKeySym = 0x000002BC
    XKc_Cabovedot*: TKeySym = 0x000002C5
    XKc_Ccircumflex*: TKeySym = 0x000002C6
    XKc_Gabovedot*: TKeySym = 0x000002D5
    XKc_Gcircumflex*: TKeySym = 0x000002D8
    XKc_Ubreve*: TKeySym = 0x000002DD
    XKc_Scircumflex*: TKeySym = 0x000002DE
    XK_cabovedot*: TKeySym = 0x000002E5
    XK_ccircumflex*: TKeySym = 0x000002E6
    XK_gabovedot*: TKeySym = 0x000002F5
    XK_gcircumflex*: TKeySym = 0x000002F8
    XK_ubreve*: TKeySym = 0x000002FD
    XK_scircumflex*: TKeySym = 0x000002FE
# XK_LATIN3 
#*
# *   Latin 4
# *   Byte 3 = 3
# *

when defined(XK_LATIN4) or true: 
  const
    XK_kra*: TKeySym = 0x000003A2
    XK_kappa*: TKeySym = 0x000003A2      # deprecated 
    XKc_Rcedilla*: TKeySym = 0x000003A3
    XKc_Itilde*: TKeySym = 0x000003A5
    XKc_Lcedilla*: TKeySym = 0x000003A6
    XKc_Emacron*: TKeySym = 0x000003AA
    XKc_Gcedilla*: TKeySym = 0x000003AB
    XKc_Tslash*: TKeySym = 0x000003AC
    XK_rcedilla*: TKeySym = 0x000003B3
    XK_itilde*: TKeySym = 0x000003B5
    XK_lcedilla*: TKeySym = 0x000003B6
    XK_emacron*: TKeySym = 0x000003BA
    XK_gcedilla*: TKeySym = 0x000003BB
    XK_tslash*: TKeySym = 0x000003BC
    XKc_ENG*: TKeySym = 0x000003BD
    XK_eng*: TKeySym = 0x000003BF
    XKc_Amacron*: TKeySym = 0x000003C0
    XKc_Iogonek*: TKeySym = 0x000003C7
    XKc_Eabovedot*: TKeySym = 0x000003CC
    XKc_Imacron*: TKeySym = 0x000003CF
    XKc_Ncedilla*: TKeySym = 0x000003D1
    XKc_Omacron*: TKeySym = 0x000003D2
    XKc_Kcedilla*: TKeySym = 0x000003D3
    XKc_Uogonek*: TKeySym = 0x000003D9
    XKc_Utilde*: TKeySym = 0x000003DD
    XKc_Umacron*: TKeySym = 0x000003DE
    XK_amacron*: TKeySym = 0x000003E0
    XK_iogonek*: TKeySym = 0x000003E7
    XK_eabovedot*: TKeySym = 0x000003EC
    XK_imacron*: TKeySym = 0x000003EF
    XK_ncedilla*: TKeySym = 0x000003F1
    XK_omacron*: TKeySym = 0x000003F2
    XK_kcedilla*: TKeySym = 0x000003F3
    XK_uogonek*: TKeySym = 0x000003F9
    XK_utilde*: TKeySym = 0x000003FD
    XK_umacron*: TKeySym = 0x000003FE
# XK_LATIN4 
#*
# * Latin-8
# * Byte 3 = 18
# *

when defined(XK_LATIN8) or true: 
  const
    XKc_Babovedot*: TKeySym = 0x000012A1
    XK_babovedot*: TKeySym = 0x000012A2
    XKc_Dabovedot*: TKeySym = 0x000012A6
    XKc_Wgrave*: TKeySym = 0x000012A8
    XKc_Wacute*: TKeySym = 0x000012AA
    XK_dabovedot*: TKeySym = 0x000012AB
    XKc_Ygrave*: TKeySym = 0x000012AC
    XKc_Fabovedot*: TKeySym = 0x000012B0
    XK_fabovedot*: TKeySym = 0x000012B1
    XKc_Mabovedot*: TKeySym = 0x000012B4
    XK_mabovedot*: TKeySym = 0x000012B5
    XKc_Pabovedot*: TKeySym = 0x000012B7
    XK_wgrave*: TKeySym = 0x000012B8
    XK_pabovedot*: TKeySym = 0x000012B9
    XK_wacute*: TKeySym = 0x000012BA
    XKc_Sabovedot*: TKeySym = 0x000012BB
    XK_ygrave*: TKeySym = 0x000012BC
    XKc_Wdiaeresis*: TKeySym = 0x000012BD
    XK_wdiaeresis*: TKeySym = 0x000012BE
    XK_sabovedot*: TKeySym = 0x000012BF
    XKc_Wcircumflex*: TKeySym = 0x000012D0
    XKc_Tabovedot*: TKeySym = 0x000012D7
    XKc_Ycircumflex*: TKeySym = 0x000012DE
    XK_wcircumflex*: TKeySym = 0x000012F0
    XK_tabovedot*: TKeySym = 0x000012F7
    XK_ycircumflex*: TKeySym = 0x000012FE
# XK_LATIN8 
#*
# * Latin-9 (a.k.a. Latin-0)
# * Byte 3 = 19
# *

when defined(XK_LATIN9) or true: 
  const
    XKc_OE*: TKeySym = 0x000013BC
    XK_oe*: TKeySym = 0x000013BD
    XKc_Ydiaeresis*: TKeySym = 0x000013BE
# XK_LATIN9 
#*
# * Katakana
# * Byte 3 = 4
# *

when defined(XK_KATAKANA) or true: 
  const
    XK_overline*: TKeySym = 0x0000047E
    XK_kana_fullstop*: TKeySym = 0x000004A1
    XK_kana_openingbracket*: TKeySym = 0x000004A2
    XK_kana_closingbracket*: TKeySym = 0x000004A3
    XK_kana_comma*: TKeySym = 0x000004A4
    XK_kana_conjunctive*: TKeySym = 0x000004A5
    XK_kana_middledot*: TKeySym = 0x000004A5 # deprecated 
    XKc_kana_WO*: TKeySym = 0x000004A6
    XK_kana_a*: TKeySym = 0x000004A7
    XK_kana_i*: TKeySym = 0x000004A8
    XK_kana_u*: TKeySym = 0x000004A9
    XK_kana_e*: TKeySym = 0x000004AA
    XK_kana_o*: TKeySym = 0x000004AB
    XK_kana_ya*: TKeySym = 0x000004AC
    XK_kana_yu*: TKeySym = 0x000004AD
    XK_kana_yo*: TKeySym = 0x000004AE
    XK_kana_tsu*: TKeySym = 0x000004AF
    XK_kana_tu*: TKeySym = 0x000004AF    # deprecated 
    XK_prolongedsound*: TKeySym = 0x000004B0
    XKc_kana_A*: TKeySym = 0x000004B1
    XKc_kana_I*: TKeySym = 0x000004B2
    XKc_kana_U*: TKeySym = 0x000004B3
    XKc_kana_E*: TKeySym = 0x000004B4
    XKc_kana_O*: TKeySym = 0x000004B5
    XKc_kana_KA*: TKeySym = 0x000004B6
    XKc_kana_KI*: TKeySym = 0x000004B7
    XKc_kana_KU*: TKeySym = 0x000004B8
    XKc_kana_KE*: TKeySym = 0x000004B9
    XKc_kana_KO*: TKeySym = 0x000004BA
    XKc_kana_SA*: TKeySym = 0x000004BB
    XKc_kana_SHI*: TKeySym = 0x000004BC
    XKc_kana_SU*: TKeySym = 0x000004BD
    XKc_kana_SE*: TKeySym = 0x000004BE
    XKc_kana_SO*: TKeySym = 0x000004BF
    XKc_kana_TA*: TKeySym = 0x000004C0
    XKc_kana_CHI*: TKeySym = 0x000004C1
    XKc_kana_TI*: TKeySym = 0x000004C1   # deprecated 
    XKc_kana_TSU*: TKeySym = 0x000004C2
    XKc_kana_TU*: TKeySym = 0x000004C2   # deprecated 
    XKc_kana_TE*: TKeySym = 0x000004C3
    XKc_kana_TO*: TKeySym = 0x000004C4
    XKc_kana_NA*: TKeySym = 0x000004C5
    XKc_kana_NI*: TKeySym = 0x000004C6
    XKc_kana_NU*: TKeySym = 0x000004C7
    XKc_kana_NE*: TKeySym = 0x000004C8
    XKc_kana_NO*: TKeySym = 0x000004C9
    XKc_kana_HA*: TKeySym = 0x000004CA
    XKc_kana_HI*: TKeySym = 0x000004CB
    XKc_kana_FU*: TKeySym = 0x000004CC
    XKc_kana_HU*: TKeySym = 0x000004CC   # deprecated 
    XKc_kana_HE*: TKeySym = 0x000004CD
    XKc_kana_HO*: TKeySym = 0x000004CE
    XKc_kana_MA*: TKeySym = 0x000004CF
    XKc_kana_MI*: TKeySym = 0x000004D0
    XKc_kana_MU*: TKeySym = 0x000004D1
    XKc_kana_ME*: TKeySym = 0x000004D2
    XKc_kana_MO*: TKeySym = 0x000004D3
    XKc_kana_YA*: TKeySym = 0x000004D4
    XKc_kana_YU*: TKeySym = 0x000004D5
    XKc_kana_YO*: TKeySym = 0x000004D6
    XKc_kana_RA*: TKeySym = 0x000004D7
    XKc_kana_RI*: TKeySym = 0x000004D8
    XKc_kana_RU*: TKeySym = 0x000004D9
    XKc_kana_RE*: TKeySym = 0x000004DA
    XKc_kana_RO*: TKeySym = 0x000004DB
    XKc_kana_WA*: TKeySym = 0x000004DC
    XKc_kana_N*: TKeySym = 0x000004DD
    XK_voicedsound*: TKeySym = 0x000004DE
    XK_semivoicedsound*: TKeySym = 0x000004DF
    XK_kana_switch*: TKeySym = 0x0000FF7E # Alias for mode_switch 
# XK_KATAKANA 
#*
# *  Arabic
# *  Byte 3 = 5
# *

when defined(XK_ARABIC) or true: 
  const
    XK_Farsi_0*: TKeySym = 0x00000590
    XK_Farsi_1*: TKeySym = 0x00000591
    XK_Farsi_2*: TKeySym = 0x00000592
    XK_Farsi_3*: TKeySym = 0x00000593
    XK_Farsi_4*: TKeySym = 0x00000594
    XK_Farsi_5*: TKeySym = 0x00000595
    XK_Farsi_6*: TKeySym = 0x00000596
    XK_Farsi_7*: TKeySym = 0x00000597
    XK_Farsi_8*: TKeySym = 0x00000598
    XK_Farsi_9*: TKeySym = 0x00000599
    XK_Arabic_percent*: TKeySym = 0x000005A5
    XK_Arabic_superscript_alef*: TKeySym = 0x000005A6
    XK_Arabic_tteh*: TKeySym = 0x000005A7
    XK_Arabic_peh*: TKeySym = 0x000005A8
    XK_Arabic_tcheh*: TKeySym = 0x000005A9
    XK_Arabic_ddal*: TKeySym = 0x000005AA
    XK_Arabic_rreh*: TKeySym = 0x000005AB
    XK_Arabic_comma*: TKeySym = 0x000005AC
    XK_Arabic_fullstop*: TKeySym = 0x000005AE
    XK_Arabic_0*: TKeySym = 0x000005B0
    XK_Arabic_1*: TKeySym = 0x000005B1
    XK_Arabic_2*: TKeySym = 0x000005B2
    XK_Arabic_3*: TKeySym = 0x000005B3
    XK_Arabic_4*: TKeySym = 0x000005B4
    XK_Arabic_5*: TKeySym = 0x000005B5
    XK_Arabic_6*: TKeySym = 0x000005B6
    XK_Arabic_7*: TKeySym = 0x000005B7
    XK_Arabic_8*: TKeySym = 0x000005B8
    XK_Arabic_9*: TKeySym = 0x000005B9
    XK_Arabic_semicolon*: TKeySym = 0x000005BB
    XK_Arabic_question_mark*: TKeySym = 0x000005BF
    XK_Arabic_hamza*: TKeySym = 0x000005C1
    XK_Arabic_maddaonalef*: TKeySym = 0x000005C2
    XK_Arabic_hamzaonalef*: TKeySym = 0x000005C3
    XK_Arabic_hamzaonwaw*: TKeySym = 0x000005C4
    XK_Arabic_hamzaunderalef*: TKeySym = 0x000005C5
    XK_Arabic_hamzaonyeh*: TKeySym = 0x000005C6
    XK_Arabic_alef*: TKeySym = 0x000005C7
    XK_Arabic_beh*: TKeySym = 0x000005C8
    XK_Arabic_tehmarbuta*: TKeySym = 0x000005C9
    XK_Arabic_teh*: TKeySym = 0x000005CA
    XK_Arabic_theh*: TKeySym = 0x000005CB
    XK_Arabic_jeem*: TKeySym = 0x000005CC
    XK_Arabic_hah*: TKeySym = 0x000005CD
    XK_Arabic_khah*: TKeySym = 0x000005CE
    XK_Arabic_dal*: TKeySym = 0x000005CF
    XK_Arabic_thal*: TKeySym = 0x000005D0
    XK_Arabic_ra*: TKeySym = 0x000005D1
    XK_Arabic_zain*: TKeySym = 0x000005D2
    XK_Arabic_seen*: TKeySym = 0x000005D3
    XK_Arabic_sheen*: TKeySym = 0x000005D4
    XK_Arabic_sad*: TKeySym = 0x000005D5
    XK_Arabic_dad*: TKeySym = 0x000005D6
    XK_Arabic_tah*: TKeySym = 0x000005D7
    XK_Arabic_zah*: TKeySym = 0x000005D8
    XK_Arabic_ain*: TKeySym = 0x000005D9
    XK_Arabic_ghain*: TKeySym = 0x000005DA
    XK_Arabic_tatweel*: TKeySym = 0x000005E0
    XK_Arabic_feh*: TKeySym = 0x000005E1
    XK_Arabic_qaf*: TKeySym = 0x000005E2
    XK_Arabic_kaf*: TKeySym = 0x000005E3
    XK_Arabic_lam*: TKeySym = 0x000005E4
    XK_Arabic_meem*: TKeySym = 0x000005E5
    XK_Arabic_noon*: TKeySym = 0x000005E6
    XK_Arabic_ha*: TKeySym = 0x000005E7
    XK_Arabic_heh*: TKeySym = 0x000005E7 # deprecated 
    XK_Arabic_waw*: TKeySym = 0x000005E8
    XK_Arabic_alefmaksura*: TKeySym = 0x000005E9
    XK_Arabic_yeh*: TKeySym = 0x000005EA
    XK_Arabic_fathatan*: TKeySym = 0x000005EB
    XK_Arabic_dammatan*: TKeySym = 0x000005EC
    XK_Arabic_kasratan*: TKeySym = 0x000005ED
    XK_Arabic_fatha*: TKeySym = 0x000005EE
    XK_Arabic_damma*: TKeySym = 0x000005EF
    XK_Arabic_kasra*: TKeySym = 0x000005F0
    XK_Arabic_shadda*: TKeySym = 0x000005F1
    XK_Arabic_sukun*: TKeySym = 0x000005F2
    XK_Arabic_madda_above*: TKeySym = 0x000005F3
    XK_Arabic_hamza_above*: TKeySym = 0x000005F4
    XK_Arabic_hamza_below*: TKeySym = 0x000005F5
    XK_Arabic_jeh*: TKeySym = 0x000005F6
    XK_Arabic_veh*: TKeySym = 0x000005F7
    XK_Arabic_keheh*: TKeySym = 0x000005F8
    XK_Arabic_gaf*: TKeySym = 0x000005F9
    XK_Arabic_noon_ghunna*: TKeySym = 0x000005FA
    XK_Arabic_heh_doachashmee*: TKeySym = 0x000005FB
    XK_Farsi_yeh*: TKeySym = 0x000005FC
    XK_Arabic_farsi_yeh*: TKeySym = XK_Farsi_yeh
    XK_Arabic_yeh_baree*: TKeySym = 0x000005FD
    XK_Arabic_heh_goal*: TKeySym = 0x000005FE
    XK_Arabic_switch*: TKeySym = 0x0000FF7E # Alias for mode_switch 
# XK_ARABIC 
#*
# * Cyrillic
# * Byte 3 = 6
# *

when defined(XK_CYRILLIC) or true: 
  const
    XKc_Cyrillic_GHE_bar*: TKeySym = 0x00000680
    XK_Cyrillic_ghe_bar*: TKeySym = 0x00000690
    XKc_Cyrillic_ZHE_descender*: TKeySym = 0x00000681
    XK_Cyrillic_zhe_descender*: TKeySym = 0x00000691
    XKc_Cyrillic_KA_descender*: TKeySym = 0x00000682
    XK_Cyrillic_ka_descender*: TKeySym = 0x00000692
    XKc_Cyrillic_KA_vertstroke*: TKeySym = 0x00000683
    XK_Cyrillic_ka_vertstroke*: TKeySym = 0x00000693
    XKc_Cyrillic_EN_descender*: TKeySym = 0x00000684
    XK_Cyrillic_en_descender*: TKeySym = 0x00000694
    XKc_Cyrillic_U_straight*: TKeySym = 0x00000685
    XK_Cyrillic_u_straight*: TKeySym = 0x00000695
    XKc_Cyrillic_U_straight_bar*: TKeySym = 0x00000686
    XK_Cyrillic_u_straight_bar*: TKeySym = 0x00000696
    XKc_Cyrillic_HA_descender*: TKeySym = 0x00000687
    XK_Cyrillic_ha_descender*: TKeySym = 0x00000697
    XKc_Cyrillic_CHE_descender*: TKeySym = 0x00000688
    XK_Cyrillic_che_descender*: TKeySym = 0x00000698
    XKc_Cyrillic_CHE_vertstroke*: TKeySym = 0x00000689
    XK_Cyrillic_che_vertstroke*: TKeySym = 0x00000699
    XKc_Cyrillic_SHHA*: TKeySym = 0x0000068A
    XK_Cyrillic_shha*: TKeySym = 0x0000069A
    XKc_Cyrillic_SCHWA*: TKeySym = 0x0000068C
    XK_Cyrillic_schwa*: TKeySym = 0x0000069C
    XKc_Cyrillic_I_macron*: TKeySym = 0x0000068D
    XK_Cyrillic_i_macron*: TKeySym = 0x0000069D
    XKc_Cyrillic_O_bar*: TKeySym = 0x0000068E
    XK_Cyrillic_o_bar*: TKeySym = 0x0000069E
    XKc_Cyrillic_U_macron*: TKeySym = 0x0000068F
    XK_Cyrillic_u_macron*: TKeySym = 0x0000069F
    XK_Serbian_dje*: TKeySym = 0x000006A1
    XK_Macedonia_gje*: TKeySym = 0x000006A2
    XK_Cyrillic_io*: TKeySym = 0x000006A3
    XK_Ukrainian_ie*: TKeySym = 0x000006A4
    XK_Ukranian_je*: TKeySym = 0x000006A4 # deprecated 
    XK_Macedonia_dse*: TKeySym = 0x000006A5
    XK_Ukrainian_i*: TKeySym = 0x000006A6
    XK_Ukranian_i*: TKeySym = 0x000006A6 # deprecated 
    XK_Ukrainian_yi*: TKeySym = 0x000006A7
    XK_Ukranian_yi*: TKeySym = 0x000006A7 # deprecated 
    XK_Cyrillic_je*: TKeySym = 0x000006A8
    XK_Serbian_je*: TKeySym = 0x000006A8 # deprecated 
    XK_Cyrillic_lje*: TKeySym = 0x000006A9
    XK_Serbian_lje*: TKeySym = 0x000006A9 # deprecated 
    XK_Cyrillic_nje*: TKeySym = 0x000006AA
    XK_Serbian_nje*: TKeySym = 0x000006AA # deprecated 
    XK_Serbian_tshe*: TKeySym = 0x000006AB
    XK_Macedonia_kje*: TKeySym = 0x000006AC
    XK_Ukrainian_ghe_with_upturn*: TKeySym = 0x000006AD
    XK_Byelorussian_shortu*: TKeySym = 0x000006AE
    XK_Cyrillic_dzhe*: TKeySym = 0x000006AF
    XK_Serbian_dze*: TKeySym = 0x000006AF # deprecated 
    XK_numerosign*: TKeySym = 0x000006B0
    XKc_Serbian_DJE*: TKeySym = 0x000006B1
    XKc_Macedonia_GJE*: TKeySym = 0x000006B2
    XKc_Cyrillic_IO*: TKeySym = 0x000006B3
    XKc_Ukrainian_IE*: TKeySym = 0x000006B4
    XKc_Ukranian_JE*: TKeySym = 0x000006B4 # deprecated 
    XKc_Macedonia_DSE*: TKeySym = 0x000006B5
    XKc_Ukrainian_I*: TKeySym = 0x000006B6
    XKc_Ukranian_I*: TKeySym = 0x000006B6 # deprecated 
    XKc_Ukrainian_YI*: TKeySym = 0x000006B7
    XKc_Ukranian_YI*: TKeySym = 0x000006B7 # deprecated 
    XKc_Cyrillic_JE*: TKeySym = 0x000006B8
    XKc_Serbian_JE*: TKeySym = 0x000006B8 # deprecated 
    XKc_Cyrillic_LJE*: TKeySym = 0x000006B9
    XKc_Serbian_LJE*: TKeySym = 0x000006B9 # deprecated 
    XKc_Cyrillic_NJE*: TKeySym = 0x000006BA
    XKc_Serbian_NJE*: TKeySym = 0x000006BA # deprecated 
    XKc_Serbian_TSHE*: TKeySym = 0x000006BB
    XKc_Macedonia_KJE*: TKeySym = 0x000006BC
    XKc_Ukrainian_GHE_WITH_UPTURN*: TKeySym = 0x000006BD
    XKc_Byelorussian_SHORTU*: TKeySym = 0x000006BE
    XKc_Cyrillic_DZHE*: TKeySym = 0x000006BF
    XKc_Serbian_DZE*: TKeySym = 0x000006BF # deprecated 
    XK_Cyrillic_yu*: TKeySym = 0x000006C0
    XK_Cyrillic_a*: TKeySym = 0x000006C1
    XK_Cyrillic_be*: TKeySym = 0x000006C2
    XK_Cyrillic_tse*: TKeySym = 0x000006C3
    XK_Cyrillic_de*: TKeySym = 0x000006C4
    XK_Cyrillic_ie*: TKeySym = 0x000006C5
    XK_Cyrillic_ef*: TKeySym = 0x000006C6
    XK_Cyrillic_ghe*: TKeySym = 0x000006C7
    XK_Cyrillic_ha*: TKeySym = 0x000006C8
    XK_Cyrillic_i*: TKeySym = 0x000006C9
    XK_Cyrillic_shorti*: TKeySym = 0x000006CA
    XK_Cyrillic_ka*: TKeySym = 0x000006CB
    XK_Cyrillic_el*: TKeySym = 0x000006CC
    XK_Cyrillic_em*: TKeySym = 0x000006CD
    XK_Cyrillic_en*: TKeySym = 0x000006CE
    XK_Cyrillic_o*: TKeySym = 0x000006CF
    XK_Cyrillic_pe*: TKeySym = 0x000006D0
    XK_Cyrillic_ya*: TKeySym = 0x000006D1
    XK_Cyrillic_er*: TKeySym = 0x000006D2
    XK_Cyrillic_es*: TKeySym = 0x000006D3
    XK_Cyrillic_te*: TKeySym = 0x000006D4
    XK_Cyrillic_u*: TKeySym = 0x000006D5
    XK_Cyrillic_zhe*: TKeySym = 0x000006D6
    XK_Cyrillic_ve*: TKeySym = 0x000006D7
    XK_Cyrillic_softsign*: TKeySym = 0x000006D8
    XK_Cyrillic_yeru*: TKeySym = 0x000006D9
    XK_Cyrillic_ze*: TKeySym = 0x000006DA
    XK_Cyrillic_sha*: TKeySym = 0x000006DB
    XK_Cyrillic_e*: TKeySym = 0x000006DC
    XK_Cyrillic_shcha*: TKeySym = 0x000006DD
    XK_Cyrillic_che*: TKeySym = 0x000006DE
    XK_Cyrillic_hardsign*: TKeySym = 0x000006DF
    XKc_Cyrillic_YU*: TKeySym = 0x000006E0
    XKc_Cyrillic_A*: TKeySym = 0x000006E1
    XKc_Cyrillic_BE*: TKeySym = 0x000006E2
    XKc_Cyrillic_TSE*: TKeySym = 0x000006E3
    XKc_Cyrillic_DE*: TKeySym = 0x000006E4
    XKc_Cyrillic_IE*: TKeySym = 0x000006E5
    XKc_Cyrillic_EF*: TKeySym = 0x000006E6
    XKc_Cyrillic_GHE*: TKeySym = 0x000006E7
    XKc_Cyrillic_HA*: TKeySym = 0x000006E8
    XKc_Cyrillic_I*: TKeySym = 0x000006E9
    XKc_Cyrillic_SHORTI*: TKeySym = 0x000006EA
    XKc_Cyrillic_KA*: TKeySym = 0x000006EB
    XKc_Cyrillic_EL*: TKeySym = 0x000006EC
    XKc_Cyrillic_EM*: TKeySym = 0x000006ED
    XKc_Cyrillic_EN*: TKeySym = 0x000006EE
    XKc_Cyrillic_O*: TKeySym = 0x000006EF
    XKc_Cyrillic_PE*: TKeySym = 0x000006F0
    XKc_Cyrillic_YA*: TKeySym = 0x000006F1
    XKc_Cyrillic_ER*: TKeySym = 0x000006F2
    XKc_Cyrillic_ES*: TKeySym = 0x000006F3
    XKc_Cyrillic_TE*: TKeySym = 0x000006F4
    XKc_Cyrillic_U*: TKeySym = 0x000006F5
    XKc_Cyrillic_ZHE*: TKeySym = 0x000006F6
    XKc_Cyrillic_VE*: TKeySym = 0x000006F7
    XKc_Cyrillic_SOFTSIGN*: TKeySym = 0x000006F8
    XKc_Cyrillic_YERU*: TKeySym = 0x000006F9
    XKc_Cyrillic_ZE*: TKeySym = 0x000006FA
    XKc_Cyrillic_SHA*: TKeySym = 0x000006FB
    XKc_Cyrillic_E*: TKeySym = 0x000006FC
    XKc_Cyrillic_SHCHA*: TKeySym = 0x000006FD
    XKc_Cyrillic_CHE*: TKeySym = 0x000006FE
    XKc_Cyrillic_HARDSIGN*: TKeySym = 0x000006FF
# XK_CYRILLIC 
#*
# * Greek
# * Byte 3 = 7
# *

when defined(XK_GREEK) or true: 
  const
    XKc_Greek_ALPHAaccent*: TKeySym = 0x000007A1
    XKc_Greek_EPSILONaccent*: TKeySym = 0x000007A2
    XKc_Greek_ETAaccent*: TKeySym = 0x000007A3
    XKc_Greek_IOTAaccent*: TKeySym = 0x000007A4
    XKc_Greek_IOTAdieresis*: TKeySym = 0x000007A5
    XKc_Greek_IOTAdiaeresis*: TKeySym = XKc_Greek_IOTAdieresis # old typo 
    XKc_Greek_OMICRONaccent*: TKeySym = 0x000007A7
    XKc_Greek_UPSILONaccent*: TKeySym = 0x000007A8
    XKc_Greek_UPSILONdieresis*: TKeySym = 0x000007A9
    XKc_Greek_OMEGAaccent*: TKeySym = 0x000007AB
    XK_Greek_accentdieresis*: TKeySym = 0x000007AE
    XK_Greek_horizbar*: TKeySym = 0x000007AF
    XK_Greek_alphaaccent*: TKeySym = 0x000007B1
    XK_Greek_epsilonaccent*: TKeySym = 0x000007B2
    XK_Greek_etaaccent*: TKeySym = 0x000007B3
    XK_Greek_iotaaccent*: TKeySym = 0x000007B4
    XK_Greek_iotadieresis*: TKeySym = 0x000007B5
    XK_Greek_iotaaccentdieresis*: TKeySym = 0x000007B6
    XK_Greek_omicronaccent*: TKeySym = 0x000007B7
    XK_Greek_upsilonaccent*: TKeySym = 0x000007B8
    XK_Greek_upsilondieresis*: TKeySym = 0x000007B9
    XK_Greek_upsilonaccentdieresis*: TKeySym = 0x000007BA
    XK_Greek_omegaaccent*: TKeySym = 0x000007BB
    XKc_Greek_ALPHA*: TKeySym = 0x000007C1
    XKc_Greek_BETA*: TKeySym = 0x000007C2
    XKc_Greek_GAMMA*: TKeySym = 0x000007C3
    XKc_Greek_DELTA*: TKeySym = 0x000007C4
    XKc_Greek_EPSILON*: TKeySym = 0x000007C5
    XKc_Greek_ZETA*: TKeySym = 0x000007C6
    XKc_Greek_ETA*: TKeySym = 0x000007C7
    XKc_Greek_THETA*: TKeySym = 0x000007C8
    XKc_Greek_IOTA*: TKeySym = 0x000007C9
    XKc_Greek_KAPPA*: TKeySym = 0x000007CA
    XKc_Greek_LAMDA*: TKeySym = 0x000007CB
    XKc_Greek_LAMBDA*: TKeySym = 0x000007CB
    XKc_Greek_MU*: TKeySym = 0x000007CC
    XKc_Greek_NU*: TKeySym = 0x000007CD
    XKc_Greek_XI*: TKeySym = 0x000007CE
    XKc_Greek_OMICRON*: TKeySym = 0x000007CF
    XKc_Greek_PI*: TKeySym = 0x000007D0
    XKc_Greek_RHO*: TKeySym = 0x000007D1
    XKc_Greek_SIGMA*: TKeySym = 0x000007D2
    XKc_Greek_TAU*: TKeySym = 0x000007D4
    XKc_Greek_UPSILON*: TKeySym = 0x000007D5
    XKc_Greek_PHI*: TKeySym = 0x000007D6
    XKc_Greek_CHI*: TKeySym = 0x000007D7
    XKc_Greek_PSI*: TKeySym = 0x000007D8
    XKc_Greek_OMEGA*: TKeySym = 0x000007D9
    XK_Greek_alpha*: TKeySym = 0x000007E1
    XK_Greek_beta*: TKeySym = 0x000007E2
    XK_Greek_gamma*: TKeySym = 0x000007E3
    XK_Greek_delta*: TKeySym = 0x000007E4
    XK_Greek_epsilon*: TKeySym = 0x000007E5
    XK_Greek_zeta*: TKeySym = 0x000007E6
    XK_Greek_eta*: TKeySym = 0x000007E7
    XK_Greek_theta*: TKeySym = 0x000007E8
    XK_Greek_iota*: TKeySym = 0x000007E9
    XK_Greek_kappa*: TKeySym = 0x000007EA
    XK_Greek_lamda*: TKeySym = 0x000007EB
    XK_Greek_lambda*: TKeySym = 0x000007EB
    XK_Greek_mu*: TKeySym = 0x000007EC
    XK_Greek_nu*: TKeySym = 0x000007ED
    XK_Greek_xi*: TKeySym = 0x000007EE
    XK_Greek_omicron*: TKeySym = 0x000007EF
    XK_Greek_pi*: TKeySym = 0x000007F0
    XK_Greek_rho*: TKeySym = 0x000007F1
    XK_Greek_sigma*: TKeySym = 0x000007F2
    XK_Greek_finalsmallsigma*: TKeySym = 0x000007F3
    XK_Greek_tau*: TKeySym = 0x000007F4
    XK_Greek_upsilon*: TKeySym = 0x000007F5
    XK_Greek_phi*: TKeySym = 0x000007F6
    XK_Greek_chi*: TKeySym = 0x000007F7
    XK_Greek_psi*: TKeySym = 0x000007F8
    XK_Greek_omega*: TKeySym = 0x000007F9
    XK_Greek_switch*: TKeySym = 0x0000FF7E # Alias for mode_switch 
# XK_GREEK 
#*
# * Technical
# * Byte 3 = 8
# *

when defined(XK_TECHNICAL) or true: 
  const
    XK_leftradical*: TKeySym = 0x000008A1
    XK_topleftradical*: TKeySym = 0x000008A2
    XK_horizconnector*: TKeySym = 0x000008A3
    XK_topintegral*: TKeySym = 0x000008A4
    XK_botintegral*: TKeySym = 0x000008A5
    XK_vertconnector*: TKeySym = 0x000008A6
    XK_topleftsqbracket*: TKeySym = 0x000008A7
    XK_botleftsqbracket*: TKeySym = 0x000008A8
    XK_toprightsqbracket*: TKeySym = 0x000008A9
    XK_botrightsqbracket*: TKeySym = 0x000008AA
    XK_topleftparens*: TKeySym = 0x000008AB
    XK_botleftparens*: TKeySym = 0x000008AC
    XK_toprightparens*: TKeySym = 0x000008AD
    XK_botrightparens*: TKeySym = 0x000008AE
    XK_leftmiddlecurlybrace*: TKeySym = 0x000008AF
    XK_rightmiddlecurlybrace*: TKeySym = 0x000008B0
    XK_topleftsummation*: TKeySym = 0x000008B1
    XK_botleftsummation*: TKeySym = 0x000008B2
    XK_topvertsummationconnector*: TKeySym = 0x000008B3
    XK_botvertsummationconnector*: TKeySym = 0x000008B4
    XK_toprightsummation*: TKeySym = 0x000008B5
    XK_botrightsummation*: TKeySym = 0x000008B6
    XK_rightmiddlesummation*: TKeySym = 0x000008B7
    XK_lessthanequal*: TKeySym = 0x000008BC
    XK_notequal*: TKeySym = 0x000008BD
    XK_greaterthanequal*: TKeySym = 0x000008BE
    XK_integral*: TKeySym = 0x000008BF
    XK_therefore*: TKeySym = 0x000008C0
    XK_variation*: TKeySym = 0x000008C1
    XK_infinity*: TKeySym = 0x000008C2
    XK_nabla*: TKeySym = 0x000008C5
    XK_approximate*: TKeySym = 0x000008C8
    XK_similarequal*: TKeySym = 0x000008C9
    XK_ifonlyif*: TKeySym = 0x000008CD
    XK_implies*: TKeySym = 0x000008CE
    XK_identical*: TKeySym = 0x000008CF
    XK_radical*: TKeySym = 0x000008D6
    XK_includedin*: TKeySym = 0x000008DA
    XK_includes*: TKeySym = 0x000008DB
    XK_intersection*: TKeySym = 0x000008DC
    XK_union*: TKeySym = 0x000008DD
    XK_logicaland*: TKeySym = 0x000008DE
    XK_logicalor*: TKeySym = 0x000008DF
    XK_partialderivative*: TKeySym = 0x000008EF
    XK_function*: TKeySym = 0x000008F6
    XK_leftarrow*: TKeySym = 0x000008FB
    XK_uparrow*: TKeySym = 0x000008FC
    XK_rightarrow*: TKeySym = 0x000008FD
    XK_downarrow*: TKeySym = 0x000008FE
# XK_TECHNICAL 
#*
# *  Special
# *  Byte 3 = 9
# *

when defined(XK_SPECIAL): 
  const
    XK_blank*: TKeySym = 0x000009DF
    XK_soliddiamond*: TKeySym = 0x000009E0
    XK_checkerboard*: TKeySym = 0x000009E1
    XK_ht*: TKeySym = 0x000009E2
    XK_ff*: TKeySym = 0x000009E3
    XK_cr*: TKeySym = 0x000009E4
    XK_lf*: TKeySym = 0x000009E5
    XK_nl*: TKeySym = 0x000009E8
    XK_vt*: TKeySym = 0x000009E9
    XK_lowrightcorner*: TKeySym = 0x000009EA
    XK_uprightcorner*: TKeySym = 0x000009EB
    XK_upleftcorner*: TKeySym = 0x000009EC
    XK_lowleftcorner*: TKeySym = 0x000009ED
    XK_crossinglines*: TKeySym = 0x000009EE
    XK_horizlinescan1*: TKeySym = 0x000009EF
    XK_horizlinescan3*: TKeySym = 0x000009F0
    XK_horizlinescan5*: TKeySym = 0x000009F1
    XK_horizlinescan7*: TKeySym = 0x000009F2
    XK_horizlinescan9*: TKeySym = 0x000009F3
    XK_leftt*: TKeySym = 0x000009F4
    XK_rightt*: TKeySym = 0x000009F5
    XK_bott*: TKeySym = 0x000009F6
    XK_topt*: TKeySym = 0x000009F7
    XK_vertbar*: TKeySym = 0x000009F8
# XK_SPECIAL 
#*
# *  Publishing
# *  Byte 3 = a
# *

when defined(XK_PUBLISHING) or true: 
  const
    XK_emspace*: TKeySym = 0x00000AA1
    XK_enspace*: TKeySym = 0x00000AA2
    XK_em3space*: TKeySym = 0x00000AA3
    XK_em4space*: TKeySym = 0x00000AA4
    XK_digitspace*: TKeySym = 0x00000AA5
    XK_punctspace*: TKeySym = 0x00000AA6
    XK_thinspace*: TKeySym = 0x00000AA7
    XK_hairspace*: TKeySym = 0x00000AA8
    XK_emdash*: TKeySym = 0x00000AA9
    XK_endash*: TKeySym = 0x00000AAA
    XK_signifblank*: TKeySym = 0x00000AAC
    XK_ellipsis*: TKeySym = 0x00000AAE
    XK_doubbaselinedot*: TKeySym = 0x00000AAF
    XK_onethird*: TKeySym = 0x00000AB0
    XK_twothirds*: TKeySym = 0x00000AB1
    XK_onefifth*: TKeySym = 0x00000AB2
    XK_twofifths*: TKeySym = 0x00000AB3
    XK_threefifths*: TKeySym = 0x00000AB4
    XK_fourfifths*: TKeySym = 0x00000AB5
    XK_onesixth*: TKeySym = 0x00000AB6
    XK_fivesixths*: TKeySym = 0x00000AB7
    XK_careof*: TKeySym = 0x00000AB8
    XK_figdash*: TKeySym = 0x00000ABB
    XK_leftanglebracket*: TKeySym = 0x00000ABC
    XK_decimalpoint*: TKeySym = 0x00000ABD
    XK_rightanglebracket*: TKeySym = 0x00000ABE
    XK_marker*: TKeySym = 0x00000ABF
    XK_oneeighth*: TKeySym = 0x00000AC3
    XK_threeeighths*: TKeySym = 0x00000AC4
    XK_fiveeighths*: TKeySym = 0x00000AC5
    XK_seveneighths*: TKeySym = 0x00000AC6
    XK_trademark*: TKeySym = 0x00000AC9
    XK_signaturemark*: TKeySym = 0x00000ACA
    XK_trademarkincircle*: TKeySym = 0x00000ACB
    XK_leftopentriangle*: TKeySym = 0x00000ACC
    XK_rightopentriangle*: TKeySym = 0x00000ACD
    XK_emopencircle*: TKeySym = 0x00000ACE
    XK_emopenrectangle*: TKeySym = 0x00000ACF
    XK_leftsinglequotemark*: TKeySym = 0x00000AD0
    XK_rightsinglequotemark*: TKeySym = 0x00000AD1
    XK_leftdoublequotemark*: TKeySym = 0x00000AD2
    XK_rightdoublequotemark*: TKeySym = 0x00000AD3
    XK_prescription*: TKeySym = 0x00000AD4
    XK_minutes*: TKeySym = 0x00000AD6
    XK_seconds*: TKeySym = 0x00000AD7
    XK_latincross*: TKeySym = 0x00000AD9
    XK_hexagram*: TKeySym = 0x00000ADA
    XK_filledrectbullet*: TKeySym = 0x00000ADB
    XK_filledlefttribullet*: TKeySym = 0x00000ADC
    XK_filledrighttribullet*: TKeySym = 0x00000ADD
    XK_emfilledcircle*: TKeySym = 0x00000ADE
    XK_emfilledrect*: TKeySym = 0x00000ADF
    XK_enopencircbullet*: TKeySym = 0x00000AE0
    XK_enopensquarebullet*: TKeySym = 0x00000AE1
    XK_openrectbullet*: TKeySym = 0x00000AE2
    XK_opentribulletup*: TKeySym = 0x00000AE3
    XK_opentribulletdown*: TKeySym = 0x00000AE4
    XK_openstar*: TKeySym = 0x00000AE5
    XK_enfilledcircbullet*: TKeySym = 0x00000AE6
    XK_enfilledsqbullet*: TKeySym = 0x00000AE7
    XK_filledtribulletup*: TKeySym = 0x00000AE8
    XK_filledtribulletdown*: TKeySym = 0x00000AE9
    XK_leftpointer*: TKeySym = 0x00000AEA
    XK_rightpointer*: TKeySym = 0x00000AEB
    XK_club*: TKeySym = 0x00000AEC
    XK_diamond*: TKeySym = 0x00000AED
    XK_heart*: TKeySym = 0x00000AEE
    XK_maltesecross*: TKeySym = 0x00000AF0
    XK_dagger*: TKeySym = 0x00000AF1
    XK_doubledagger*: TKeySym = 0x00000AF2
    XK_checkmark*: TKeySym = 0x00000AF3
    XK_ballotcross*: TKeySym = 0x00000AF4
    XK_musicalsharp*: TKeySym = 0x00000AF5
    XK_musicalflat*: TKeySym = 0x00000AF6
    XK_malesymbol*: TKeySym = 0x00000AF7
    XK_femalesymbol*: TKeySym = 0x00000AF8
    XK_telephone*: TKeySym = 0x00000AF9
    XK_telephonerecorder*: TKeySym = 0x00000AFA
    XK_phonographcopyright*: TKeySym = 0x00000AFB
    XK_caret*: TKeySym = 0x00000AFC
    XK_singlelowquotemark*: TKeySym = 0x00000AFD
    XK_doublelowquotemark*: TKeySym = 0x00000AFE
    XK_cursor*: TKeySym = 0x00000AFF
# XK_PUBLISHING 
#*
# *  APL
# *  Byte 3 = b
# *

when defined(XK_APL) or true: 
  const
    XK_leftcaret*: TKeySym = 0x00000BA3
    XK_rightcaret*: TKeySym = 0x00000BA6
    XK_downcaret*: TKeySym = 0x00000BA8
    XK_upcaret*: TKeySym = 0x00000BA9
    XK_overbar*: TKeySym = 0x00000BC0
    XK_downtack*: TKeySym = 0x00000BC2
    XK_upshoe*: TKeySym = 0x00000BC3
    XK_downstile*: TKeySym = 0x00000BC4
    XK_underbar*: TKeySym = 0x00000BC6
    XK_jot*: TKeySym = 0x00000BCA
    XK_quad*: TKeySym = 0x00000BCC
    XK_uptack*: TKeySym = 0x00000BCE
    XK_circle*: TKeySym = 0x00000BCF
    XK_upstile*: TKeySym = 0x00000BD3
    XK_downshoe*: TKeySym = 0x00000BD6
    XK_rightshoe*: TKeySym = 0x00000BD8
    XK_leftshoe*: TKeySym = 0x00000BDA
    XK_lefttack*: TKeySym = 0x00000BDC
    XK_righttack*: TKeySym = 0x00000BFC
# XK_APL 
#*
# * Hebrew
# * Byte 3 = c
# *

when defined(XK_HEBREW) or true: 
  const
    XK_hebrew_doublelowline*: TKeySym = 0x00000CDF
    XK_hebrew_aleph*: TKeySym = 0x00000CE0
    XK_hebrew_bet*: TKeySym = 0x00000CE1
    XK_hebrew_beth*: TKeySym = 0x00000CE1 # deprecated 
    XK_hebrew_gimel*: TKeySym = 0x00000CE2
    XK_hebrew_gimmel*: TKeySym = 0x00000CE2 # deprecated 
    XK_hebrew_dalet*: TKeySym = 0x00000CE3
    XK_hebrew_daleth*: TKeySym = 0x00000CE3 # deprecated 
    XK_hebrew_he*: TKeySym = 0x00000CE4
    XK_hebrew_waw*: TKeySym = 0x00000CE5
    XK_hebrew_zain*: TKeySym = 0x00000CE6
    XK_hebrew_zayin*: TKeySym = 0x00000CE6 # deprecated 
    XK_hebrew_chet*: TKeySym = 0x00000CE7
    XK_hebrew_het*: TKeySym = 0x00000CE7 # deprecated 
    XK_hebrew_tet*: TKeySym = 0x00000CE8
    XK_hebrew_teth*: TKeySym = 0x00000CE8 # deprecated 
    XK_hebrew_yod*: TKeySym = 0x00000CE9
    XK_hebrew_finalkaph*: TKeySym = 0x00000CEA
    XK_hebrew_kaph*: TKeySym = 0x00000CEB
    XK_hebrew_lamed*: TKeySym = 0x00000CEC
    XK_hebrew_finalmem*: TKeySym = 0x00000CED
    XK_hebrew_mem*: TKeySym = 0x00000CEE
    XK_hebrew_finalnun*: TKeySym = 0x00000CEF
    XK_hebrew_nun*: TKeySym = 0x00000CF0
    XK_hebrew_samech*: TKeySym = 0x00000CF1
    XK_hebrew_samekh*: TKeySym = 0x00000CF1 # deprecated 
    XK_hebrew_ayin*: TKeySym = 0x00000CF2
    XK_hebrew_finalpe*: TKeySym = 0x00000CF3
    XK_hebrew_pe*: TKeySym = 0x00000CF4
    XK_hebrew_finalzade*: TKeySym = 0x00000CF5
    XK_hebrew_finalzadi*: TKeySym = 0x00000CF5 # deprecated 
    XK_hebrew_zade*: TKeySym = 0x00000CF6
    XK_hebrew_zadi*: TKeySym = 0x00000CF6 # deprecated 
    XK_hebrew_qoph*: TKeySym = 0x00000CF7
    XK_hebrew_kuf*: TKeySym = 0x00000CF7 # deprecated 
    XK_hebrew_resh*: TKeySym = 0x00000CF8
    XK_hebrew_shin*: TKeySym = 0x00000CF9
    XK_hebrew_taw*: TKeySym = 0x00000CFA
    XK_hebrew_taf*: TKeySym = 0x00000CFA # deprecated 
    XK_Hebrew_switch*: TKeySym = 0x0000FF7E # Alias for mode_switch 
# XK_HEBREW 
#*
# * Thai
# * Byte 3 = d
# *

when defined(XK_THAI) or true: 
  const
    XK_Thai_kokai*: TKeySym = 0x00000DA1
    XK_Thai_khokhai*: TKeySym = 0x00000DA2
    XK_Thai_khokhuat*: TKeySym = 0x00000DA3
    XK_Thai_khokhwai*: TKeySym = 0x00000DA4
    XK_Thai_khokhon*: TKeySym = 0x00000DA5
    XK_Thai_khorakhang*: TKeySym = 0x00000DA6
    XK_Thai_ngongu*: TKeySym = 0x00000DA7
    XK_Thai_chochan*: TKeySym = 0x00000DA8
    XK_Thai_choching*: TKeySym = 0x00000DA9
    XK_Thai_chochang*: TKeySym = 0x00000DAA
    XK_Thai_soso*: TKeySym = 0x00000DAB
    XK_Thai_chochoe*: TKeySym = 0x00000DAC
    XK_Thai_yoying*: TKeySym = 0x00000DAD
    XK_Thai_dochada*: TKeySym = 0x00000DAE
    XK_Thai_topatak*: TKeySym = 0x00000DAF
    XK_Thai_thothan*: TKeySym = 0x00000DB0
    XK_Thai_thonangmontho*: TKeySym = 0x00000DB1
    XK_Thai_thophuthao*: TKeySym = 0x00000DB2
    XK_Thai_nonen*: TKeySym = 0x00000DB3
    XK_Thai_dodek*: TKeySym = 0x00000DB4
    XK_Thai_totao*: TKeySym = 0x00000DB5
    XK_Thai_thothung*: TKeySym = 0x00000DB6
    XK_Thai_thothahan*: TKeySym = 0x00000DB7
    XK_Thai_thothong*: TKeySym = 0x00000DB8
    XK_Thai_nonu*: TKeySym = 0x00000DB9
    XK_Thai_bobaimai*: TKeySym = 0x00000DBA
    XK_Thai_popla*: TKeySym = 0x00000DBB
    XK_Thai_phophung*: TKeySym = 0x00000DBC
    XK_Thai_fofa*: TKeySym = 0x00000DBD
    XK_Thai_phophan*: TKeySym = 0x00000DBE
    XK_Thai_fofan*: TKeySym = 0x00000DBF
    XK_Thai_phosamphao*: TKeySym = 0x00000DC0
    XK_Thai_moma*: TKeySym = 0x00000DC1
    XK_Thai_yoyak*: TKeySym = 0x00000DC2
    XK_Thai_rorua*: TKeySym = 0x00000DC3
    XK_Thai_ru*: TKeySym = 0x00000DC4
    XK_Thai_loling*: TKeySym = 0x00000DC5
    XK_Thai_lu*: TKeySym = 0x00000DC6
    XK_Thai_wowaen*: TKeySym = 0x00000DC7
    XK_Thai_sosala*: TKeySym = 0x00000DC8
    XK_Thai_sorusi*: TKeySym = 0x00000DC9
    XK_Thai_sosua*: TKeySym = 0x00000DCA
    XK_Thai_hohip*: TKeySym = 0x00000DCB
    XK_Thai_lochula*: TKeySym = 0x00000DCC
    XK_Thai_oang*: TKeySym = 0x00000DCD
    XK_Thai_honokhuk*: TKeySym = 0x00000DCE
    XK_Thai_paiyannoi*: TKeySym = 0x00000DCF
    XK_Thai_saraa*: TKeySym = 0x00000DD0
    XK_Thai_maihanakat*: TKeySym = 0x00000DD1
    XK_Thai_saraaa*: TKeySym = 0x00000DD2
    XK_Thai_saraam*: TKeySym = 0x00000DD3
    XK_Thai_sarai*: TKeySym = 0x00000DD4
    XK_Thai_saraii*: TKeySym = 0x00000DD5
    XK_Thai_saraue*: TKeySym = 0x00000DD6
    XK_Thai_sarauee*: TKeySym = 0x00000DD7
    XK_Thai_sarau*: TKeySym = 0x00000DD8
    XK_Thai_sarauu*: TKeySym = 0x00000DD9
    XK_Thai_phinthu*: TKeySym = 0x00000DDA
    XK_Thai_maihanakat_maitho*: TKeySym = 0x00000DDE
    XK_Thai_baht*: TKeySym = 0x00000DDF
    XK_Thai_sarae*: TKeySym = 0x00000DE0
    XK_Thai_saraae*: TKeySym = 0x00000DE1
    XK_Thai_sarao*: TKeySym = 0x00000DE2
    XK_Thai_saraaimaimuan*: TKeySym = 0x00000DE3
    XK_Thai_saraaimaimalai*: TKeySym = 0x00000DE4
    XK_Thai_lakkhangyao*: TKeySym = 0x00000DE5
    XK_Thai_maiyamok*: TKeySym = 0x00000DE6
    XK_Thai_maitaikhu*: TKeySym = 0x00000DE7
    XK_Thai_maiek*: TKeySym = 0x00000DE8
    XK_Thai_maitho*: TKeySym = 0x00000DE9
    XK_Thai_maitri*: TKeySym = 0x00000DEA
    XK_Thai_maichattawa*: TKeySym = 0x00000DEB
    XK_Thai_thanthakhat*: TKeySym = 0x00000DEC
    XK_Thai_nikhahit*: TKeySym = 0x00000DED
    XK_Thai_leksun*: TKeySym = 0x00000DF0
    XK_Thai_leknung*: TKeySym = 0x00000DF1
    XK_Thai_leksong*: TKeySym = 0x00000DF2
    XK_Thai_leksam*: TKeySym = 0x00000DF3
    XK_Thai_leksi*: TKeySym = 0x00000DF4
    XK_Thai_lekha*: TKeySym = 0x00000DF5
    XK_Thai_lekhok*: TKeySym = 0x00000DF6
    XK_Thai_lekchet*: TKeySym = 0x00000DF7
    XK_Thai_lekpaet*: TKeySym = 0x00000DF8
    XK_Thai_lekkao*: TKeySym = 0x00000DF9
# XK_THAI 
#*
# *   Korean
# *   Byte 3 = e
# *

when defined(XK_KOREAN) or true: 
  const
    XK_Hangul*: TKeySym = 0x0000FF31     # Hangul start/stop(toggle) 
    XK_Hangul_Start*: TKeySym = 0x0000FF32 # Hangul start 
    XK_Hangul_End*: TKeySym = 0x0000FF33 # Hangul end, English start 
    XK_Hangul_Hanja*: TKeySym = 0x0000FF34 # Start Hangul->Hanja Conversion 
    XK_Hangul_Jamo*: TKeySym = 0x0000FF35 # Hangul Jamo mode 
    XK_Hangul_Romaja*: TKeySym = 0x0000FF36 # Hangul Romaja mode 
    XK_Hangul_Codeinput*: TKeySym = 0x0000FF37 # Hangul code input mode 
    XK_Hangul_Jeonja*: TKeySym = 0x0000FF38 # Jeonja mode 
    XK_Hangul_Banja*: TKeySym = 0x0000FF39 # Banja mode 
    XK_Hangul_PreHanja*: TKeySym = 0x0000FF3A # Pre Hanja conversion 
    XK_Hangul_PostHanja*: TKeySym = 0x0000FF3B # Post Hanja conversion 
    XK_Hangul_SingleCandidate*: TKeySym = 0x0000FF3C # Single candidate 
    XK_Hangul_MultipleCandidate*: TKeySym = 0x0000FF3D # Multiple candidate 
    XK_Hangul_PreviousCandidate*: TKeySym = 0x0000FF3E # Previous candidate 
    XK_Hangul_Special*: TKeySym = 0x0000FF3F # Special symbols 
    XK_Hangul_switch*: TKeySym = 0x0000FF7E # Alias for mode_switch \
                                   # Hangul Consonant Characters 
    XK_Hangul_Kiyeog*: TKeySym = 0x00000EA1
    XK_Hangul_SsangKiyeog*: TKeySym = 0x00000EA2
    XK_Hangul_KiyeogSios*: TKeySym = 0x00000EA3
    XK_Hangul_Nieun*: TKeySym = 0x00000EA4
    XK_Hangul_NieunJieuj*: TKeySym = 0x00000EA5
    XK_Hangul_NieunHieuh*: TKeySym = 0x00000EA6
    XK_Hangul_Dikeud*: TKeySym = 0x00000EA7
    XK_Hangul_SsangDikeud*: TKeySym = 0x00000EA8
    XK_Hangul_Rieul*: TKeySym = 0x00000EA9
    XK_Hangul_RieulKiyeog*: TKeySym = 0x00000EAA
    XK_Hangul_RieulMieum*: TKeySym = 0x00000EAB
    XK_Hangul_RieulPieub*: TKeySym = 0x00000EAC
    XK_Hangul_RieulSios*: TKeySym = 0x00000EAD
    XK_Hangul_RieulTieut*: TKeySym = 0x00000EAE
    XK_Hangul_RieulPhieuf*: TKeySym = 0x00000EAF
    XK_Hangul_RieulHieuh*: TKeySym = 0x00000EB0
    XK_Hangul_Mieum*: TKeySym = 0x00000EB1
    XK_Hangul_Pieub*: TKeySym = 0x00000EB2
    XK_Hangul_SsangPieub*: TKeySym = 0x00000EB3
    XK_Hangul_PieubSios*: TKeySym = 0x00000EB4
    XK_Hangul_Sios*: TKeySym = 0x00000EB5
    XK_Hangul_SsangSios*: TKeySym = 0x00000EB6
    XK_Hangul_Ieung*: TKeySym = 0x00000EB7
    XK_Hangul_Jieuj*: TKeySym = 0x00000EB8
    XK_Hangul_SsangJieuj*: TKeySym = 0x00000EB9
    XK_Hangul_Cieuc*: TKeySym = 0x00000EBA
    XK_Hangul_Khieuq*: TKeySym = 0x00000EBB
    XK_Hangul_Tieut*: TKeySym = 0x00000EBC
    XK_Hangul_Phieuf*: TKeySym = 0x00000EBD
    XK_Hangul_Hieuh*: TKeySym = 0x00000EBE # Hangul Vowel Characters 
    XK_Hangul_A*: TKeySym = 0x00000EBF
    XK_Hangul_AE*: TKeySym = 0x00000EC0
    XK_Hangul_YA*: TKeySym = 0x00000EC1
    XK_Hangul_YAE*: TKeySym = 0x00000EC2
    XK_Hangul_EO*: TKeySym = 0x00000EC3
    XK_Hangul_E*: TKeySym = 0x00000EC4
    XK_Hangul_YEO*: TKeySym = 0x00000EC5
    XK_Hangul_YE*: TKeySym = 0x00000EC6
    XK_Hangul_O*: TKeySym = 0x00000EC7
    XK_Hangul_WA*: TKeySym = 0x00000EC8
    XK_Hangul_WAE*: TKeySym = 0x00000EC9
    XK_Hangul_OE*: TKeySym = 0x00000ECA
    XK_Hangul_YO*: TKeySym = 0x00000ECB
    XK_Hangul_U*: TKeySym = 0x00000ECC
    XK_Hangul_WEO*: TKeySym = 0x00000ECD
    XK_Hangul_WE*: TKeySym = 0x00000ECE
    XK_Hangul_WI*: TKeySym = 0x00000ECF
    XK_Hangul_YU*: TKeySym = 0x00000ED0
    XK_Hangul_EU*: TKeySym = 0x00000ED1
    XK_Hangul_YI*: TKeySym = 0x00000ED2
    XK_Hangul_I*: TKeySym = 0x00000ED3   # Hangul syllable-final (JongSeong) Characters 
    XK_Hangul_J_Kiyeog*: TKeySym = 0x00000ED4
    XK_Hangul_J_SsangKiyeog*: TKeySym = 0x00000ED5
    XK_Hangul_J_KiyeogSios*: TKeySym = 0x00000ED6
    XK_Hangul_J_Nieun*: TKeySym = 0x00000ED7
    XK_Hangul_J_NieunJieuj*: TKeySym = 0x00000ED8
    XK_Hangul_J_NieunHieuh*: TKeySym = 0x00000ED9
    XK_Hangul_J_Dikeud*: TKeySym = 0x00000EDA
    XK_Hangul_J_Rieul*: TKeySym = 0x00000EDB
    XK_Hangul_J_RieulKiyeog*: TKeySym = 0x00000EDC
    XK_Hangul_J_RieulMieum*: TKeySym = 0x00000EDD
    XK_Hangul_J_RieulPieub*: TKeySym = 0x00000EDE
    XK_Hangul_J_RieulSios*: TKeySym = 0x00000EDF
    XK_Hangul_J_RieulTieut*: TKeySym = 0x00000EE0
    XK_Hangul_J_RieulPhieuf*: TKeySym = 0x00000EE1
    XK_Hangul_J_RieulHieuh*: TKeySym = 0x00000EE2
    XK_Hangul_J_Mieum*: TKeySym = 0x00000EE3
    XK_Hangul_J_Pieub*: TKeySym = 0x00000EE4
    XK_Hangul_J_PieubSios*: TKeySym = 0x00000EE5
    XK_Hangul_J_Sios*: TKeySym = 0x00000EE6
    XK_Hangul_J_SsangSios*: TKeySym = 0x00000EE7
    XK_Hangul_J_Ieung*: TKeySym = 0x00000EE8
    XK_Hangul_J_Jieuj*: TKeySym = 0x00000EE9
    XK_Hangul_J_Cieuc*: TKeySym = 0x00000EEA
    XK_Hangul_J_Khieuq*: TKeySym = 0x00000EEB
    XK_Hangul_J_Tieut*: TKeySym = 0x00000EEC
    XK_Hangul_J_Phieuf*: TKeySym = 0x00000EED
    XK_Hangul_J_Hieuh*: TKeySym = 0x00000EEE # Ancient Hangul Consonant Characters 
    XK_Hangul_RieulYeorinHieuh*: TKeySym = 0x00000EEF
    XK_Hangul_SunkyeongeumMieum*: TKeySym = 0x00000EF0
    XK_Hangul_SunkyeongeumPieub*: TKeySym = 0x00000EF1
    XK_Hangul_PanSios*: TKeySym = 0x00000EF2
    XK_Hangul_KkogjiDalrinIeung*: TKeySym = 0x00000EF3
    XK_Hangul_SunkyeongeumPhieuf*: TKeySym = 0x00000EF4
    XK_Hangul_YeorinHieuh*: TKeySym = 0x00000EF5 # Ancient Hangul Vowel Characters 
    XK_Hangul_AraeA*: TKeySym = 0x00000EF6
    XK_Hangul_AraeAE*: TKeySym = 0x00000EF7 # Ancient Hangul syllable-final (JongSeong) Characters 
    XK_Hangul_J_PanSios*: TKeySym = 0x00000EF8
    XK_Hangul_J_KkogjiDalrinIeung*: TKeySym = 0x00000EF9
    XK_Hangul_J_YeorinHieuh*: TKeySym = 0x00000EFA # Korean currency symbol 
    XK_Korean_Won*: TKeySym = 0x00000EFF
# XK_KOREAN 
#*
# *   Armenian
# *   Byte 3 = = $14
# *

when defined(XK_ARMENIAN) or true: 
  const
    XK_Armenian_eternity*: TKeySym = 0x000014A1
    XK_Armenian_ligature_ew*: TKeySym = 0x000014A2
    XK_Armenian_full_stop*: TKeySym = 0x000014A3
    XK_Armenian_verjaket*: TKeySym = 0x000014A3
    XK_Armenian_parenright*: TKeySym = 0x000014A4
    XK_Armenian_parenleft*: TKeySym = 0x000014A5
    XK_Armenian_guillemotright*: TKeySym = 0x000014A6
    XK_Armenian_guillemotleft*: TKeySym = 0x000014A7
    XK_Armenian_em_dash*: TKeySym = 0x000014A8
    XK_Armenian_dot*: TKeySym = 0x000014A9
    XK_Armenian_mijaket*: TKeySym = 0x000014A9
    XK_Armenian_separation_mark*: TKeySym = 0x000014AA
    XK_Armenian_but*: TKeySym = 0x000014AA
    XK_Armenian_comma*: TKeySym = 0x000014AB
    XK_Armenian_en_dash*: TKeySym = 0x000014AC
    XK_Armenian_hyphen*: TKeySym = 0x000014AD
    XK_Armenian_yentamna*: TKeySym = 0x000014AD
    XK_Armenian_ellipsis*: TKeySym = 0x000014AE
    XK_Armenian_exclam*: TKeySym = 0x000014AF
    XK_Armenian_amanak*: TKeySym = 0x000014AF
    XK_Armenian_accent*: TKeySym = 0x000014B0
    XK_Armenian_shesht*: TKeySym = 0x000014B0
    XK_Armenian_question*: TKeySym = 0x000014B1
    XK_Armenian_paruyk*: TKeySym = 0x000014B1
    XKc_Armenian_AYB*: TKeySym = 0x000014B2
    XK_Armenian_ayb*: TKeySym = 0x000014B3
    XKc_Armenian_BEN*: TKeySym = 0x000014B4
    XK_Armenian_ben*: TKeySym = 0x000014B5
    XKc_Armenian_GIM*: TKeySym = 0x000014B6
    XK_Armenian_gim*: TKeySym = 0x000014B7
    XKc_Armenian_DA*: TKeySym = 0x000014B8
    XK_Armenian_da*: TKeySym = 0x000014B9
    XKc_Armenian_YECH*: TKeySym = 0x000014BA
    XK_Armenian_yech*: TKeySym = 0x000014BB
    XKc_Armenian_ZA*: TKeySym = 0x000014BC
    XK_Armenian_za*: TKeySym = 0x000014BD
    XKc_Armenian_E*: TKeySym = 0x000014BE
    XK_Armenian_e*: TKeySym = 0x000014BF
    XKc_Armenian_AT*: TKeySym = 0x000014C0
    XK_Armenian_at*: TKeySym = 0x000014C1
    XKc_Armenian_TO*: TKeySym = 0x000014C2
    XK_Armenian_to*: TKeySym = 0x000014C3
    XKc_Armenian_ZHE*: TKeySym = 0x000014C4
    XK_Armenian_zhe*: TKeySym = 0x000014C5
    XKc_Armenian_INI*: TKeySym = 0x000014C6
    XK_Armenian_ini*: TKeySym = 0x000014C7
    XKc_Armenian_LYUN*: TKeySym = 0x000014C8
    XK_Armenian_lyun*: TKeySym = 0x000014C9
    XKc_Armenian_KHE*: TKeySym = 0x000014CA
    XK_Armenian_khe*: TKeySym = 0x000014CB
    XKc_Armenian_TSA*: TKeySym = 0x000014CC
    XK_Armenian_tsa*: TKeySym = 0x000014CD
    XKc_Armenian_KEN*: TKeySym = 0x000014CE
    XK_Armenian_ken*: TKeySym = 0x000014CF
    XKc_Armenian_HO*: TKeySym = 0x000014D0
    XK_Armenian_ho*: TKeySym = 0x000014D1
    XKc_Armenian_DZA*: TKeySym = 0x000014D2
    XK_Armenian_dza*: TKeySym = 0x000014D3
    XKc_Armenian_GHAT*: TKeySym = 0x000014D4
    XK_Armenian_ghat*: TKeySym = 0x000014D5
    XKc_Armenian_TCHE*: TKeySym = 0x000014D6
    XK_Armenian_tche*: TKeySym = 0x000014D7
    XKc_Armenian_MEN*: TKeySym = 0x000014D8
    XK_Armenian_men*: TKeySym = 0x000014D9
    XKc_Armenian_HI*: TKeySym = 0x000014DA
    XK_Armenian_hi*: TKeySym = 0x000014DB
    XKc_Armenian_NU*: TKeySym = 0x000014DC
    XK_Armenian_nu*: TKeySym = 0x000014DD
    XKc_Armenian_SHA*: TKeySym = 0x000014DE
    XK_Armenian_sha*: TKeySym = 0x000014DF
    XKc_Armenian_VO*: TKeySym = 0x000014E0
    XK_Armenian_vo*: TKeySym = 0x000014E1
    XKc_Armenian_CHA*: TKeySym = 0x000014E2
    XK_Armenian_cha*: TKeySym = 0x000014E3
    XKc_Armenian_PE*: TKeySym = 0x000014E4
    XK_Armenian_pe*: TKeySym = 0x000014E5
    XKc_Armenian_JE*: TKeySym = 0x000014E6
    XK_Armenian_je*: TKeySym = 0x000014E7
    XKc_Armenian_RA*: TKeySym = 0x000014E8
    XK_Armenian_ra*: TKeySym = 0x000014E9
    XKc_Armenian_SE*: TKeySym = 0x000014EA
    XK_Armenian_se*: TKeySym = 0x000014EB
    XKc_Armenian_VEV*: TKeySym = 0x000014EC
    XK_Armenian_vev*: TKeySym = 0x000014ED
    XKc_Armenian_TYUN*: TKeySym = 0x000014EE
    XK_Armenian_tyun*: TKeySym = 0x000014EF
    XKc_Armenian_RE*: TKeySym = 0x000014F0
    XK_Armenian_re*: TKeySym = 0x000014F1
    XKc_Armenian_TSO*: TKeySym = 0x000014F2
    XK_Armenian_tso*: TKeySym = 0x000014F3
    XKc_Armenian_VYUN*: TKeySym = 0x000014F4
    XK_Armenian_vyun*: TKeySym = 0x000014F5
    XKc_Armenian_PYUR*: TKeySym = 0x000014F6
    XK_Armenian_pyur*: TKeySym = 0x000014F7
    XKc_Armenian_KE*: TKeySym = 0x000014F8
    XK_Armenian_ke*: TKeySym = 0x000014F9
    XKc_Armenian_O*: TKeySym = 0x000014FA
    XK_Armenian_o*: TKeySym = 0x000014FB
    XKc_Armenian_FE*: TKeySym = 0x000014FC
    XK_Armenian_fe*: TKeySym = 0x000014FD
    XK_Armenian_apostrophe*: TKeySym = 0x000014FE
    XK_Armenian_section_sign*: TKeySym = 0x000014FF
# XK_ARMENIAN 
#*
# *   Georgian
# *   Byte 3 = = $15
# *

when defined(XK_GEORGIAN) or true: 
  const
    XK_Georgian_an*: TKeySym = 0x000015D0
    XK_Georgian_ban*: TKeySym = 0x000015D1
    XK_Georgian_gan*: TKeySym = 0x000015D2
    XK_Georgian_don*: TKeySym = 0x000015D3
    XK_Georgian_en*: TKeySym = 0x000015D4
    XK_Georgian_vin*: TKeySym = 0x000015D5
    XK_Georgian_zen*: TKeySym = 0x000015D6
    XK_Georgian_tan*: TKeySym = 0x000015D7
    XK_Georgian_in*: TKeySym = 0x000015D8
    XK_Georgian_kan*: TKeySym = 0x000015D9
    XK_Georgian_las*: TKeySym = 0x000015DA
    XK_Georgian_man*: TKeySym = 0x000015DB
    XK_Georgian_nar*: TKeySym = 0x000015DC
    XK_Georgian_on*: TKeySym = 0x000015DD
    XK_Georgian_par*: TKeySym = 0x000015DE
    XK_Georgian_zhar*: TKeySym = 0x000015DF
    XK_Georgian_rae*: TKeySym = 0x000015E0
    XK_Georgian_san*: TKeySym = 0x000015E1
    XK_Georgian_tar*: TKeySym = 0x000015E2
    XK_Georgian_un*: TKeySym = 0x000015E3
    XK_Georgian_phar*: TKeySym = 0x000015E4
    XK_Georgian_khar*: TKeySym = 0x000015E5
    XK_Georgian_ghan*: TKeySym = 0x000015E6
    XK_Georgian_qar*: TKeySym = 0x000015E7
    XK_Georgian_shin*: TKeySym = 0x000015E8
    XK_Georgian_chin*: TKeySym = 0x000015E9
    XK_Georgian_can*: TKeySym = 0x000015EA
    XK_Georgian_jil*: TKeySym = 0x000015EB
    XK_Georgian_cil*: TKeySym = 0x000015EC
    XK_Georgian_char*: TKeySym = 0x000015ED
    XK_Georgian_xan*: TKeySym = 0x000015EE
    XK_Georgian_jhan*: TKeySym = 0x000015EF
    XK_Georgian_hae*: TKeySym = 0x000015F0
    XK_Georgian_he*: TKeySym = 0x000015F1
    XK_Georgian_hie*: TKeySym = 0x000015F2
    XK_Georgian_we*: TKeySym = 0x000015F3
    XK_Georgian_har*: TKeySym = 0x000015F4
    XK_Georgian_hoe*: TKeySym = 0x000015F5
    XK_Georgian_fi*: TKeySym = 0x000015F6
# XK_GEORGIAN 
#*
# * Azeri (and other Turkic or Caucasian languages of ex-USSR)
# * Byte 3 = = $16
# *

when defined(XK_CAUCASUS) or true: 
  # latin 
  const
    XKc_Ccedillaabovedot*: TKeySym = 0x000016A2
    XKc_Xabovedot*: TKeySym = 0x000016A3
    XKc_Qabovedot*: TKeySym = 0x000016A5
    XKc_Ibreve*: TKeySym = 0x000016A6
    XKc_IE*: TKeySym = 0x000016A7
    XKc_UO*: TKeySym = 0x000016A8
    XKc_Zstroke*: TKeySym = 0x000016A9
    XKc_Gcaron*: TKeySym = 0x000016AA
    XKc_Obarred*: TKeySym = 0x000016AF
    XK_ccedillaabovedot*: TKeySym = 0x000016B2
    XK_xabovedot*: TKeySym = 0x000016B3
    XKc_Ocaron*: TKeySym = 0x000016B4
    XK_qabovedot*: TKeySym = 0x000016B5
    XK_ibreve*: TKeySym = 0x000016B6
    XK_ie*: TKeySym = 0x000016B7
    XK_uo*: TKeySym = 0x000016B8
    XK_zstroke*: TKeySym = 0x000016B9
    XK_gcaron*: TKeySym = 0x000016BA
    XK_ocaron*: TKeySym = 0x000016BD
    XK_obarred*: TKeySym = 0x000016BF
    XKc_SCHWA*: TKeySym = 0x000016C6
    XK_schwa*: TKeySym = 0x000016F6 # those are not really Caucasus, but I put them here for now\ 
                           # For Inupiak 
    XKc_Lbelowdot*: TKeySym = 0x000016D1
    XKc_Lstrokebelowdot*: TKeySym = 0x000016D2
    XK_lbelowdot*: TKeySym = 0x000016E1
    XK_lstrokebelowdot*: TKeySym = 0x000016E2 # For Guarani 
    XKc_Gtilde*: TKeySym = 0x000016D3
    XK_gtilde*: TKeySym = 0x000016E3
# XK_CAUCASUS 
#*
# *   Vietnamese
# *   Byte 3 = = $1e
# *

when defined(XK_VIETNAMESE) or true:
  const 
    XKc_Abelowdot*: TKeySym = 0x00001EA0
    XK_abelowdot*: TKeySym = 0x00001EA1
    XKc_Ahook*: TKeySym = 0x00001EA2
    XK_ahook*: TKeySym = 0x00001EA3
    XKc_Acircumflexacute*: TKeySym = 0x00001EA4
    XK_acircumflexacute*: TKeySym = 0x00001EA5
    XKc_Acircumflexgrave*: TKeySym = 0x00001EA6
    XK_acircumflexgrave*: TKeySym = 0x00001EA7
    XKc_Acircumflexhook*: TKeySym = 0x00001EA8
    XK_acircumflexhook*: TKeySym = 0x00001EA9
    XKc_Acircumflextilde*: TKeySym = 0x00001EAA
    XK_acircumflextilde*: TKeySym = 0x00001EAB
    XKc_Acircumflexbelowdot*: TKeySym = 0x00001EAC
    XK_acircumflexbelowdot*: TKeySym = 0x00001EAD
    XKc_Abreveacute*: TKeySym = 0x00001EAE
    XK_abreveacute*: TKeySym = 0x00001EAF
    XKc_Abrevegrave*: TKeySym = 0x00001EB0
    XK_abrevegrave*: TKeySym = 0x00001EB1
    XKc_Abrevehook*: TKeySym = 0x00001EB2
    XK_abrevehook*: TKeySym = 0x00001EB3
    XKc_Abrevetilde*: TKeySym = 0x00001EB4
    XK_abrevetilde*: TKeySym = 0x00001EB5
    XKc_Abrevebelowdot*: TKeySym = 0x00001EB6
    XK_abrevebelowdot*: TKeySym = 0x00001EB7
    XKc_Ebelowdot*: TKeySym = 0x00001EB8
    XK_ebelowdot*: TKeySym = 0x00001EB9
    XKc_Ehook*: TKeySym = 0x00001EBA
    XK_ehook*: TKeySym = 0x00001EBB
    XKc_Etilde*: TKeySym = 0x00001EBC
    XK_etilde*: TKeySym = 0x00001EBD
    XKc_Ecircumflexacute*: TKeySym = 0x00001EBE
    XK_ecircumflexacute*: TKeySym = 0x00001EBF
    XKc_Ecircumflexgrave*: TKeySym = 0x00001EC0
    XK_ecircumflexgrave*: TKeySym = 0x00001EC1
    XKc_Ecircumflexhook*: TKeySym = 0x00001EC2
    XK_ecircumflexhook*: TKeySym = 0x00001EC3
    XKc_Ecircumflextilde*: TKeySym = 0x00001EC4
    XK_ecircumflextilde*: TKeySym = 0x00001EC5
    XKc_Ecircumflexbelowdot*: TKeySym = 0x00001EC6
    XK_ecircumflexbelowdot*: TKeySym = 0x00001EC7
    XKc_Ihook*: TKeySym = 0x00001EC8
    XK_ihook*: TKeySym = 0x00001EC9
    XKc_Ibelowdot*: TKeySym = 0x00001ECA
    XK_ibelowdot*: TKeySym = 0x00001ECB
    XKc_Obelowdot*: TKeySym = 0x00001ECC
    XK_obelowdot*: TKeySym = 0x00001ECD
    XKc_Ohook*: TKeySym = 0x00001ECE
    XK_ohook*: TKeySym = 0x00001ECF
    XKc_Ocircumflexacute*: TKeySym = 0x00001ED0
    XK_ocircumflexacute*: TKeySym = 0x00001ED1
    XKc_Ocircumflexgrave*: TKeySym = 0x00001ED2
    XK_ocircumflexgrave*: TKeySym = 0x00001ED3
    XKc_Ocircumflexhook*: TKeySym = 0x00001ED4
    XK_ocircumflexhook*: TKeySym = 0x00001ED5
    XKc_Ocircumflextilde*: TKeySym = 0x00001ED6
    XK_ocircumflextilde*: TKeySym = 0x00001ED7
    XKc_Ocircumflexbelowdot*: TKeySym = 0x00001ED8
    XK_ocircumflexbelowdot*: TKeySym = 0x00001ED9
    XKc_Ohornacute*: TKeySym = 0x00001EDA
    XK_ohornacute*: TKeySym = 0x00001EDB
    XKc_Ohorngrave*: TKeySym = 0x00001EDC
    XK_ohorngrave*: TKeySym = 0x00001EDD
    XKc_Ohornhook*: TKeySym = 0x00001EDE
    XK_ohornhook*: TKeySym = 0x00001EDF
    XKc_Ohorntilde*: TKeySym = 0x00001EE0
    XK_ohorntilde*: TKeySym = 0x00001EE1
    XKc_Ohornbelowdot*: TKeySym = 0x00001EE2
    XK_ohornbelowdot*: TKeySym = 0x00001EE3
    XKc_Ubelowdot*: TKeySym = 0x00001EE4
    XK_ubelowdot*: TKeySym = 0x00001EE5
    XKc_Uhook*: TKeySym = 0x00001EE6
    XK_uhook*: TKeySym = 0x00001EE7
    XKc_Uhornacute*: TKeySym = 0x00001EE8
    XK_uhornacute*: TKeySym = 0x00001EE9
    XKc_Uhorngrave*: TKeySym = 0x00001EEA
    XK_uhorngrave*: TKeySym = 0x00001EEB
    XKc_Uhornhook*: TKeySym = 0x00001EEC
    XK_uhornhook*: TKeySym = 0x00001EED
    XKc_Uhorntilde*: TKeySym = 0x00001EEE
    XK_uhorntilde*: TKeySym = 0x00001EEF
    XKc_Uhornbelowdot*: TKeySym = 0x00001EF0
    XK_uhornbelowdot*: TKeySym = 0x00001EF1
    XKc_Ybelowdot*: TKeySym = 0x00001EF4
    XK_ybelowdot*: TKeySym = 0x00001EF5
    XKc_Yhook*: TKeySym = 0x00001EF6
    XK_yhook*: TKeySym = 0x00001EF7
    XKc_Ytilde*: TKeySym = 0x00001EF8
    XK_ytilde*: TKeySym = 0x00001EF9
    XKc_Ohorn*: TKeySym = 0x00001EFA     # U+01a0 
    XK_ohorn*: TKeySym = 0x00001EFB      # U+01a1 
    XKc_Uhorn*: TKeySym = 0x00001EFC     # U+01af 
    XK_uhorn*: TKeySym = 0x00001EFD      # U+01b0 
    XK_combining_tilde*: TKeySym = 0x00001E9F # U+0303 
    XK_combining_grave*: TKeySym = 0x00001EF2 # U+0300 
    XK_combining_acute*: TKeySym = 0x00001EF3 # U+0301 
    XK_combining_hook*: TKeySym = 0x00001EFE # U+0309 
    XK_combining_belowdot*: TKeySym = 0x00001EFF # U+0323 
# XK_VIETNAMESE 

when defined(XK_CURRENCY) or true: 
  const
    XK_EcuSign*: TKeySym = 0x000020A0
    XK_ColonSign*: TKeySym = 0x000020A1
    XK_CruzeiroSign*: TKeySym = 0x000020A2
    XK_FFrancSign*: TKeySym = 0x000020A3
    XK_LiraSign*: TKeySym = 0x000020A4
    XK_MillSign*: TKeySym = 0x000020A5
    XK_NairaSign*: TKeySym = 0x000020A6
    XK_PesetaSign*: TKeySym = 0x000020A7
    XK_RupeeSign*: TKeySym = 0x000020A8
    XK_WonSign*: TKeySym = 0x000020A9
    XK_NewSheqelSign*: TKeySym = 0x000020AA
    XK_DongSign*: TKeySym = 0x000020AB
    XK_EuroSign*: TKeySym = 0x000020AC
# implementation
