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

const 
  XK_VoidSymbol* = 0x00FFFFFF # void symbol 

when defined(XK_MISCELLANY) or true: 
  const
    #*
    # * TTY Functions, cleverly chosen to map to ascii, for convenience of
    # * programming, but could have been arbitrary (at the cost of lookup
    # * tables in client code.
    # *
    XK_BackSpace* = 0x0000FF08  # back space, back char 
    XK_Tab* = 0x0000FF09
    XK_Linefeed* = 0x0000FF0A   # Linefeed, LF 
    XK_Clear* = 0x0000FF0B
    XK_Return* = 0x0000FF0D     # Return, enter 
    XK_Pause* = 0x0000FF13      # Pause, hold 
    XK_Scroll_Lock* = 0x0000FF14
    XK_Sys_Req* = 0x0000FF15
    XK_Escape* = 0x0000FF1B
    XK_Delete* = 0x0000FFFF     # Delete, rubout 
                                # International & multi-key character composition 
    XK_Multi_key* = 0x0000FF20  # Multi-key character compose 
    XK_Codeinput* = 0x0000FF37
    XK_SingleCandidate* = 0x0000FF3C
    XK_MultipleCandidate* = 0x0000FF3D
    XK_PreviousCandidate* = 0x0000FF3E # Japanese keyboard support 
    XK_Kanji* = 0x0000FF21      # Kanji, Kanji convert 
    XK_Muhenkan* = 0x0000FF22   # Cancel Conversion 
    XK_Henkan_Mode* = 0x0000FF23 # Start/Stop Conversion 
    XK_Henkan* = 0x0000FF23     # Alias for Henkan_Mode 
    XK_Romaji* = 0x0000FF24     # to Romaji 
    XK_Hiragana* = 0x0000FF25   # to Hiragana 
    XK_Katakana* = 0x0000FF26   # to Katakana 
    XK_Hiragana_Katakana* = 0x0000FF27 # Hiragana/Katakana toggle 
    XK_Zenkaku* = 0x0000FF28    # to Zenkaku 
    XK_Hankaku* = 0x0000FF29    # to Hankaku 
    XK_Zenkaku_Hankaku* = 0x0000FF2A # Zenkaku/Hankaku toggle 
    XK_Touroku* = 0x0000FF2B    # Add to Dictionary 
    XK_Massyo* = 0x0000FF2C     # Delete from Dictionary 
    XK_Kana_Lock* = 0x0000FF2D  # Kana Lock 
    XK_Kana_Shift* = 0x0000FF2E # Kana Shift 
    XK_Eisu_Shift* = 0x0000FF2F # Alphanumeric Shift 
    XK_Eisu_toggle* = 0x0000FF30 # Alphanumeric toggle 
    XK_Kanji_Bangou* = 0x0000FF37 # Codeinput 
    XK_Zen_Koho* = 0x0000FF3D   # Multiple/All Candidate(s) 
    XK_Mae_Koho* = 0x0000FF3E   # Previous Candidate 
                                # = $FF31 thru = $FF3F are under XK_KOREAN 
                                # Cursor control & motion 
    XK_Home* = 0x0000FF50
    XK_Left* = 0x0000FF51       # Move left, left arrow 
    XK_Up* = 0x0000FF52         # Move up, up arrow 
    XK_Right* = 0x0000FF53      # Move right, right arrow 
    XK_Down* = 0x0000FF54       # Move down, down arrow 
    XK_Prior* = 0x0000FF55      # Prior, previous 
    XK_Page_Up* = 0x0000FF55
    XK_Next* = 0x0000FF56       # Next 
    XK_Page_Down* = 0x0000FF56
    XK_End* = 0x0000FF57        # EOL 
    XK_Begin* = 0x0000FF58      # BOL 
                                # Misc Functions 
    XK_Select* = 0x0000FF60     # Select, mark 
    XK_Print* = 0x0000FF61
    XK_Execute* = 0x0000FF62    # Execute, run, do 
    XK_Insert* = 0x0000FF63     # Insert, insert here 
    XK_Undo* = 0x0000FF65       # Undo, oops 
    XK_Redo* = 0x0000FF66       # redo, again 
    XK_Menu* = 0x0000FF67
    XK_Find* = 0x0000FF68       # Find, search 
    XK_Cancel* = 0x0000FF69     # Cancel, stop, abort, exit 
    XK_Help* = 0x0000FF6A       # Help 
    XK_Break* = 0x0000FF6B
    XK_Mode_switch* = 0x0000FF7E # Character set switch 
    XK_script_switch* = 0x0000FF7E # Alias for mode_switch 
    XK_Num_Lock* = 0x0000FF7F   # Keypad Functions, keypad numbers cleverly chosen to map to ascii 
    XK_KP_Space* = 0x0000FF80   # space 
    XK_KP_Tab* = 0x0000FF89
    XK_KP_Enter* = 0x0000FF8D   # enter 
    XK_KP_F1* = 0x0000FF91      # PF1, KP_A, ... 
    XK_KP_F2* = 0x0000FF92
    XK_KP_F3* = 0x0000FF93
    XK_KP_F4* = 0x0000FF94
    XK_KP_Home* = 0x0000FF95
    XK_KP_Left* = 0x0000FF96
    XK_KP_Up* = 0x0000FF97
    XK_KP_Right* = 0x0000FF98
    XK_KP_Down* = 0x0000FF99
    XK_KP_Prior* = 0x0000FF9A
    XK_KP_Page_Up* = 0x0000FF9A
    XK_KP_Next* = 0x0000FF9B
    XK_KP_Page_Down* = 0x0000FF9B
    XK_KP_End* = 0x0000FF9C
    XK_KP_Begin* = 0x0000FF9D
    XK_KP_Insert* = 0x0000FF9E
    XK_KP_Delete* = 0x0000FF9F
    XK_KP_Equal* = 0x0000FFBD   # equals 
    XK_KP_Multiply* = 0x0000FFAA
    XK_KP_Add* = 0x0000FFAB
    XK_KP_Separator* = 0x0000FFAC # separator, often comma 
    XK_KP_Subtract* = 0x0000FFAD
    XK_KP_Decimal* = 0x0000FFAE
    XK_KP_Divide* = 0x0000FFAF
    XK_KP_0* = 0x0000FFB0
    XK_KP_1* = 0x0000FFB1
    XK_KP_2* = 0x0000FFB2
    XK_KP_3* = 0x0000FFB3
    XK_KP_4* = 0x0000FFB4
    XK_KP_5* = 0x0000FFB5
    XK_KP_6* = 0x0000FFB6
    XK_KP_7* = 0x0000FFB7
    XK_KP_8* = 0x0000FFB8
    XK_KP_9* = 0x0000FFB9 #*
                          # * Auxilliary Functions; note the duplicate definitions for left and right
                          # * function keys;  Sun keyboards and a few other manufactures have such
                          # * function key groups on the left and/or right sides of the keyboard.
                          # * We've not found a keyboard with more than 35 function keys total.
                          # *
    XK_F1* = 0x0000FFBE
    XK_F2* = 0x0000FFBF
    XK_F3* = 0x0000FFC0
    XK_F4* = 0x0000FFC1
    XK_F5* = 0x0000FFC2
    XK_F6* = 0x0000FFC3
    XK_F7* = 0x0000FFC4
    XK_F8* = 0x0000FFC5
    XK_F9* = 0x0000FFC6
    XK_F10* = 0x0000FFC7
    XK_F11* = 0x0000FFC8
    XK_L1* = 0x0000FFC8
    XK_F12* = 0x0000FFC9
    XK_L2* = 0x0000FFC9
    XK_F13* = 0x0000FFCA
    XK_L3* = 0x0000FFCA
    XK_F14* = 0x0000FFCB
    XK_L4* = 0x0000FFCB
    XK_F15* = 0x0000FFCC
    XK_L5* = 0x0000FFCC
    XK_F16* = 0x0000FFCD
    XK_L6* = 0x0000FFCD
    XK_F17* = 0x0000FFCE
    XK_L7* = 0x0000FFCE
    XK_F18* = 0x0000FFCF
    XK_L8* = 0x0000FFCF
    XK_F19* = 0x0000FFD0
    XK_L9* = 0x0000FFD0
    XK_F20* = 0x0000FFD1
    XK_L10* = 0x0000FFD1
    XK_F21* = 0x0000FFD2
    XK_R1* = 0x0000FFD2
    XK_F22* = 0x0000FFD3
    XK_R2* = 0x0000FFD3
    XK_F23* = 0x0000FFD4
    XK_R3* = 0x0000FFD4
    XK_F24* = 0x0000FFD5
    XK_R4* = 0x0000FFD5
    XK_F25* = 0x0000FFD6
    XK_R5* = 0x0000FFD6
    XK_F26* = 0x0000FFD7
    XK_R6* = 0x0000FFD7
    XK_F27* = 0x0000FFD8
    XK_R7* = 0x0000FFD8
    XK_F28* = 0x0000FFD9
    XK_R8* = 0x0000FFD9
    XK_F29* = 0x0000FFDA
    XK_R9* = 0x0000FFDA
    XK_F30* = 0x0000FFDB
    XK_R10* = 0x0000FFDB
    XK_F31* = 0x0000FFDC
    XK_R11* = 0x0000FFDC
    XK_F32* = 0x0000FFDD
    XK_R12* = 0x0000FFDD
    XK_F33* = 0x0000FFDE
    XK_R13* = 0x0000FFDE
    XK_F34* = 0x0000FFDF
    XK_R14* = 0x0000FFDF
    XK_F35* = 0x0000FFE0
    XK_R15* = 0x0000FFE0        # Modifiers 
    XK_Shift_L* = 0x0000FFE1    # Left shift 
    XK_Shift_R* = 0x0000FFE2    # Right shift 
    XK_Control_L* = 0x0000FFE3  # Left control 
    XK_Control_R* = 0x0000FFE4  # Right control 
    XK_Caps_Lock* = 0x0000FFE5  # Caps lock 
    XK_Shift_Lock* = 0x0000FFE6 # Shift lock 
    XK_Meta_L* = 0x0000FFE7     # Left meta 
    XK_Meta_R* = 0x0000FFE8     # Right meta 
    XK_Alt_L* = 0x0000FFE9      # Left alt 
    XK_Alt_R* = 0x0000FFEA      # Right alt 
    XK_Super_L* = 0x0000FFEB    # Left super 
    XK_Super_R* = 0x0000FFEC    # Right super 
    XK_Hyper_L* = 0x0000FFED    # Left hyper 
    XK_Hyper_R* = 0x0000FFEE    # Right hyper 
# XK_MISCELLANY 
#*
# * ISO 9995 Function and Modifier Keys
# * Byte 3 = = $FE
# *

when defined(XK_XKB_KEYS) or true: 
  const
    XK_ISO_Lock* = 0x0000FE01
    XK_ISO_Level2_Latch* = 0x0000FE02
    XK_ISO_Level3_Shift* = 0x0000FE03
    XK_ISO_Level3_Latch* = 0x0000FE04
    XK_ISO_Level3_Lock* = 0x0000FE05
    XK_ISO_Group_Shift* = 0x0000FF7E # Alias for mode_switch 
    XK_ISO_Group_Latch* = 0x0000FE06
    XK_ISO_Group_Lock* = 0x0000FE07
    XK_ISO_Next_Group* = 0x0000FE08
    XK_ISO_Next_Group_Lock* = 0x0000FE09
    XK_ISO_Prev_Group* = 0x0000FE0A
    XK_ISO_Prev_Group_Lock* = 0x0000FE0B
    XK_ISO_First_Group* = 0x0000FE0C
    XK_ISO_First_Group_Lock* = 0x0000FE0D
    XK_ISO_Last_Group* = 0x0000FE0E
    XK_ISO_Last_Group_Lock* = 0x0000FE0F
    XK_ISO_Left_Tab* = 0x0000FE20
    XK_ISO_Move_Line_Up* = 0x0000FE21
    XK_ISO_Move_Line_Down* = 0x0000FE22
    XK_ISO_Partial_Line_Up* = 0x0000FE23
    XK_ISO_Partial_Line_Down* = 0x0000FE24
    XK_ISO_Partial_Space_Left* = 0x0000FE25
    XK_ISO_Partial_Space_Right* = 0x0000FE26
    XK_ISO_Set_Margin_Left* = 0x0000FE27
    XK_ISO_Set_Margin_Right* = 0x0000FE28
    XK_ISO_Release_Margin_Left* = 0x0000FE29
    XK_ISO_Release_Margin_Right* = 0x0000FE2A
    XK_ISO_Release_Both_Margins* = 0x0000FE2B
    XK_ISO_Fast_Cursor_Left* = 0x0000FE2C
    XK_ISO_Fast_Cursor_Right* = 0x0000FE2D
    XK_ISO_Fast_Cursor_Up* = 0x0000FE2E
    XK_ISO_Fast_Cursor_Down* = 0x0000FE2F
    XK_ISO_Continuous_Underline* = 0x0000FE30
    XK_ISO_Discontinuous_Underline* = 0x0000FE31
    XK_ISO_Emphasize* = 0x0000FE32
    XK_ISO_Center_Object* = 0x0000FE33
    XK_ISO_Enter* = 0x0000FE34
    XK_dead_grave* = 0x0000FE50
    XK_dead_acute* = 0x0000FE51
    XK_dead_circumflex* = 0x0000FE52
    XK_dead_tilde* = 0x0000FE53
    XK_dead_macron* = 0x0000FE54
    XK_dead_breve* = 0x0000FE55
    XK_dead_abovedot* = 0x0000FE56
    XK_dead_diaeresis* = 0x0000FE57
    XK_dead_abovering* = 0x0000FE58
    XK_dead_doubleacute* = 0x0000FE59
    XK_dead_caron* = 0x0000FE5A
    XK_dead_cedilla* = 0x0000FE5B
    XK_dead_ogonek* = 0x0000FE5C
    XK_dead_iota* = 0x0000FE5D
    XK_dead_voiced_sound* = 0x0000FE5E
    XK_dead_semivoiced_sound* = 0x0000FE5F
    XK_dead_belowdot* = 0x0000FE60
    XK_dead_hook* = 0x0000FE61
    XK_dead_horn* = 0x0000FE62
    XK_First_Virtual_Screen* = 0x0000FED0
    XK_Prev_Virtual_Screen* = 0x0000FED1
    XK_Next_Virtual_Screen* = 0x0000FED2
    XK_Last_Virtual_Screen* = 0x0000FED4
    XK_Terminate_Server* = 0x0000FED5
    XK_AccessX_Enable* = 0x0000FE70
    XK_AccessX_Feedback_Enable* = 0x0000FE71
    XK_RepeatKeys_Enable* = 0x0000FE72
    XK_SlowKeys_Enable* = 0x0000FE73
    XK_BounceKeys_Enable* = 0x0000FE74
    XK_StickyKeys_Enable* = 0x0000FE75
    XK_MouseKeys_Enable* = 0x0000FE76
    XK_MouseKeys_Accel_Enable* = 0x0000FE77
    XK_Overlay1_Enable* = 0x0000FE78
    XK_Overlay2_Enable* = 0x0000FE79
    XK_AudibleBell_Enable* = 0x0000FE7A
    XK_Pointer_Left* = 0x0000FEE0
    XK_Pointer_Right* = 0x0000FEE1
    XK_Pointer_Up* = 0x0000FEE2
    XK_Pointer_Down* = 0x0000FEE3
    XK_Pointer_UpLeft* = 0x0000FEE4
    XK_Pointer_UpRight* = 0x0000FEE5
    XK_Pointer_DownLeft* = 0x0000FEE6
    XK_Pointer_DownRight* = 0x0000FEE7
    XK_Pointer_Button_Dflt* = 0x0000FEE8
    XK_Pointer_Button1* = 0x0000FEE9
    XK_Pointer_Button2* = 0x0000FEEA
    XK_Pointer_Button3* = 0x0000FEEB
    XK_Pointer_Button4* = 0x0000FEEC
    XK_Pointer_Button5* = 0x0000FEED
    XK_Pointer_DblClick_Dflt* = 0x0000FEEE
    XK_Pointer_DblClick1* = 0x0000FEEF
    XK_Pointer_DblClick2* = 0x0000FEF0
    XK_Pointer_DblClick3* = 0x0000FEF1
    XK_Pointer_DblClick4* = 0x0000FEF2
    XK_Pointer_DblClick5* = 0x0000FEF3
    XK_Pointer_Drag_Dflt* = 0x0000FEF4
    XK_Pointer_Drag1* = 0x0000FEF5
    XK_Pointer_Drag2* = 0x0000FEF6
    XK_Pointer_Drag3* = 0x0000FEF7
    XK_Pointer_Drag4* = 0x0000FEF8
    XK_Pointer_Drag5* = 0x0000FEFD
    XK_Pointer_EnableKeys* = 0x0000FEF9
    XK_Pointer_Accelerate* = 0x0000FEFA
    XK_Pointer_DfltBtnNext* = 0x0000FEFB
    XK_Pointer_DfltBtnPrev* = 0x0000FEFC
  #*
  # * 3270 Terminal Keys
  # * Byte 3 = = $FD
  # *

when defined(XK_3270) or true: 
  const
    XK_3270_Duplicate* = 0x0000FD01
    XK_3270_FieldMark* = 0x0000FD02
    XK_3270_Right2* = 0x0000FD03
    XK_3270_Left2* = 0x0000FD04
    XK_3270_BackTab* = 0x0000FD05
    XK_3270_EraseEOF* = 0x0000FD06
    XK_3270_EraseInput* = 0x0000FD07
    XK_3270_Reset* = 0x0000FD08
    XK_3270_Quit* = 0x0000FD09
    XK_3270_PA1* = 0x0000FD0A
    XK_3270_PA2* = 0x0000FD0B
    XK_3270_PA3* = 0x0000FD0C
    XK_3270_Test* = 0x0000FD0D
    XK_3270_Attn* = 0x0000FD0E
    XK_3270_CursorBlink* = 0x0000FD0F
    XK_3270_AltCursor* = 0x0000FD10
    XK_3270_KeyClick* = 0x0000FD11
    XK_3270_Jump* = 0x0000FD12
    XK_3270_Ident* = 0x0000FD13
    XK_3270_Rule* = 0x0000FD14
    XK_3270_Copy* = 0x0000FD15
    XK_3270_Play* = 0x0000FD16
    XK_3270_Setup* = 0x0000FD17
    XK_3270_Record* = 0x0000FD18
    XK_3270_ChangeScreen* = 0x0000FD19
    XK_3270_DeleteWord* = 0x0000FD1A
    XK_3270_ExSelect* = 0x0000FD1B
    XK_3270_CursorSelect* = 0x0000FD1C
    XK_3270_PrintScreen* = 0x0000FD1D
    XK_3270_Enter* = 0x0000FD1E
#*
# *  Latin 1
# *  Byte 3 = 0
# *

when defined(XK_LATIN1) or true: 
  const
    XK_space* = 0x00000020
    XK_exclam* = 0x00000021
    XK_quotedbl* = 0x00000022
    XK_numbersign* = 0x00000023
    XK_dollar* = 0x00000024
    XK_percent* = 0x00000025
    XK_ampersand* = 0x00000026
    XK_apostrophe* = 0x00000027
    XK_quoteright* = 0x00000027 # deprecated 
    XK_parenleft* = 0x00000028
    XK_parenright* = 0x00000029
    XK_asterisk* = 0x0000002A
    XK_plus* = 0x0000002B
    XK_comma* = 0x0000002C
    XK_minus* = 0x0000002D
    XK_period* = 0x0000002E
    XK_slash* = 0x0000002F
    XK_0* = 0x00000030
    XK_1* = 0x00000031
    XK_2* = 0x00000032
    XK_3* = 0x00000033
    XK_4* = 0x00000034
    XK_5* = 0x00000035
    XK_6* = 0x00000036
    XK_7* = 0x00000037
    XK_8* = 0x00000038
    XK_9* = 0x00000039
    XK_colon* = 0x0000003A
    XK_semicolon* = 0x0000003B
    XK_less* = 0x0000003C
    XK_equal* = 0x0000003D
    XK_greater* = 0x0000003E
    XK_question* = 0x0000003F
    XK_at* = 0x00000040
    XKc_A* = 0x00000041
    XKc_B* = 0x00000042
    XKc_C* = 0x00000043
    XKc_D* = 0x00000044
    XKc_E* = 0x00000045
    XKc_F* = 0x00000046
    XKc_G* = 0x00000047
    XKc_H* = 0x00000048
    XKc_I* = 0x00000049
    XKc_J* = 0x0000004A
    XKc_K* = 0x0000004B
    XKc_L* = 0x0000004C
    XKc_M* = 0x0000004D
    XKc_N* = 0x0000004E
    XKc_O* = 0x0000004F
    XKc_P* = 0x00000050
    XKc_Q* = 0x00000051
    XKc_R* = 0x00000052
    XKc_S* = 0x00000053
    XKc_T* = 0x00000054
    XKc_U* = 0x00000055
    XKc_V* = 0x00000056
    XKc_W* = 0x00000057
    XKc_X* = 0x00000058
    XKc_Y* = 0x00000059
    XKc_Z* = 0x0000005A
    XK_bracketleft* = 0x0000005B
    XK_backslash* = 0x0000005C
    XK_bracketright* = 0x0000005D
    XK_asciicircum* = 0x0000005E
    XK_underscore* = 0x0000005F
    XK_grave* = 0x00000060
    XK_quoteleft* = 0x00000060  # deprecated 
    XK_a* = 0x00000061
    XK_b* = 0x00000062
    XK_c* = 0x00000063
    XK_d* = 0x00000064
    XK_e* = 0x00000065
    XK_f* = 0x00000066
    XK_g* = 0x00000067
    XK_h* = 0x00000068
    XK_i* = 0x00000069
    XK_j* = 0x0000006A
    XK_k* = 0x0000006B
    XK_l* = 0x0000006C
    XK_m* = 0x0000006D
    XK_n* = 0x0000006E
    XK_o* = 0x0000006F
    XK_p* = 0x00000070
    XK_q* = 0x00000071
    XK_r* = 0x00000072
    XK_s* = 0x00000073
    XK_t* = 0x00000074
    XK_u* = 0x00000075
    XK_v* = 0x00000076
    XK_w* = 0x00000077
    XK_x* = 0x00000078
    XK_y* = 0x00000079
    XK_z* = 0x0000007A
    XK_braceleft* = 0x0000007B
    XK_bar* = 0x0000007C
    XK_braceright* = 0x0000007D
    XK_asciitilde* = 0x0000007E
    XK_nobreakspace* = 0x000000A0
    XK_exclamdown* = 0x000000A1
    XK_cent* = 0x000000A2
    XK_sterling* = 0x000000A3
    XK_currency* = 0x000000A4
    XK_yen* = 0x000000A5
    XK_brokenbar* = 0x000000A6
    XK_section* = 0x000000A7
    XK_diaeresis* = 0x000000A8
    XK_copyright* = 0x000000A9
    XK_ordfeminine* = 0x000000AA
    XK_guillemotleft* = 0x000000AB # left angle quotation mark 
    XK_notsign* = 0x000000AC
    XK_hyphen* = 0x000000AD
    XK_registered* = 0x000000AE
    XK_macron* = 0x000000AF
    XK_degree* = 0x000000B0
    XK_plusminus* = 0x000000B1
    XK_twosuperior* = 0x000000B2
    XK_threesuperior* = 0x000000B3
    XK_acute* = 0x000000B4
    XK_mu* = 0x000000B5
    XK_paragraph* = 0x000000B6
    XK_periodcentered* = 0x000000B7
    XK_cedilla* = 0x000000B8
    XK_onesuperior* = 0x000000B9
    XK_masculine* = 0x000000BA
    XK_guillemotright* = 0x000000BB # right angle quotation mark 
    XK_onequarter* = 0x000000BC
    XK_onehalf* = 0x000000BD
    XK_threequarters* = 0x000000BE
    XK_questiondown* = 0x000000BF
    XKc_Agrave* = 0x000000C0
    XKc_Aacute* = 0x000000C1
    XKc_Acircumflex* = 0x000000C2
    XKc_Atilde* = 0x000000C3
    XKc_Adiaeresis* = 0x000000C4
    XKc_Aring* = 0x000000C5
    XKc_AE* = 0x000000C6
    XKc_Ccedilla* = 0x000000C7
    XKc_Egrave* = 0x000000C8
    XKc_Eacute* = 0x000000C9
    XKc_Ecircumflex* = 0x000000CA
    XKc_Ediaeresis* = 0x000000CB
    XKc_Igrave* = 0x000000CC
    XKc_Iacute* = 0x000000CD
    XKc_Icircumflex* = 0x000000CE
    XKc_Idiaeresis* = 0x000000CF
    XKc_ETH* = 0x000000D0
    XKc_Ntilde* = 0x000000D1
    XKc_Ograve* = 0x000000D2
    XKc_Oacute* = 0x000000D3
    XKc_Ocircumflex* = 0x000000D4
    XKc_Otilde* = 0x000000D5
    XKc_Odiaeresis* = 0x000000D6
    XK_multiply* = 0x000000D7
    XKc_Ooblique* = 0x000000D8
    XKc_Oslash* = XKc_Ooblique
    XKc_Ugrave* = 0x000000D9
    XKc_Uacute* = 0x000000DA
    XKc_Ucircumflex* = 0x000000DB
    XKc_Udiaeresis* = 0x000000DC
    XKc_Yacute* = 0x000000DD
    XKc_THORN* = 0x000000DE
    XK_ssharp* = 0x000000DF
    XK_agrave* = 0x000000E0
    XK_aacute* = 0x000000E1
    XK_acircumflex* = 0x000000E2
    XK_atilde* = 0x000000E3
    XK_adiaeresis* = 0x000000E4
    XK_aring* = 0x000000E5
    XK_ae* = 0x000000E6
    XK_ccedilla* = 0x000000E7
    XK_egrave* = 0x000000E8
    XK_eacute* = 0x000000E9
    XK_ecircumflex* = 0x000000EA
    XK_ediaeresis* = 0x000000EB
    XK_igrave* = 0x000000EC
    XK_iacute* = 0x000000ED
    XK_icircumflex* = 0x000000EE
    XK_idiaeresis* = 0x000000EF
    XK_eth* = 0x000000F0
    XK_ntilde* = 0x000000F1
    XK_ograve* = 0x000000F2
    XK_oacute* = 0x000000F3
    XK_ocircumflex* = 0x000000F4
    XK_otilde* = 0x000000F5
    XK_odiaeresis* = 0x000000F6
    XK_division* = 0x000000F7
    XK_oslash* = 0x000000F8
    XK_ooblique* = XK_oslash
    XK_ugrave* = 0x000000F9
    XK_uacute* = 0x000000FA
    XK_ucircumflex* = 0x000000FB
    XK_udiaeresis* = 0x000000FC
    XK_yacute* = 0x000000FD
    XK_thorn* = 0x000000FE
    XK_ydiaeresis* = 0x000000FF
# XK_LATIN1 
#*
# *   Latin 2
# *   Byte 3 = 1
# *

when defined(XK_LATIN2) or true: 
  const
    XKc_Aogonek* = 0x000001A1
    XK_breve* = 0x000001A2
    XKc_Lstroke* = 0x000001A3
    XKc_Lcaron* = 0x000001A5
    XKc_Sacute* = 0x000001A6
    XKc_Scaron* = 0x000001A9
    XKc_Scedilla* = 0x000001AA
    XKc_Tcaron* = 0x000001AB
    XKc_Zacute* = 0x000001AC
    XKc_Zcaron* = 0x000001AE
    XKc_Zabovedot* = 0x000001AF
    XK_aogonek* = 0x000001B1
    XK_ogonek* = 0x000001B2
    XK_lstroke* = 0x000001B3
    XK_lcaron* = 0x000001B5
    XK_sacute* = 0x000001B6
    XK_caron* = 0x000001B7
    XK_scaron* = 0x000001B9
    XK_scedilla* = 0x000001BA
    XK_tcaron* = 0x000001BB
    XK_zacute* = 0x000001BC
    XK_doubleacute* = 0x000001BD
    XK_zcaron* = 0x000001BE
    XK_zabovedot* = 0x000001BF
    XKc_Racute* = 0x000001C0
    XKc_Abreve* = 0x000001C3
    XKc_Lacute* = 0x000001C5
    XKc_Cacute* = 0x000001C6
    XKc_Ccaron* = 0x000001C8
    XKc_Eogonek* = 0x000001CA
    XKc_Ecaron* = 0x000001CC
    XKc_Dcaron* = 0x000001CF
    XKc_Dstroke* = 0x000001D0
    XKc_Nacute* = 0x000001D1
    XKc_Ncaron* = 0x000001D2
    XKc_Odoubleacute* = 0x000001D5
    XKc_Rcaron* = 0x000001D8
    XKc_Uring* = 0x000001D9
    XKc_Udoubleacute* = 0x000001DB
    XKc_Tcedilla* = 0x000001DE
    XK_racute* = 0x000001E0
    XK_abreve* = 0x000001E3
    XK_lacute* = 0x000001E5
    XK_cacute* = 0x000001E6
    XK_ccaron* = 0x000001E8
    XK_eogonek* = 0x000001EA
    XK_ecaron* = 0x000001EC
    XK_dcaron* = 0x000001EF
    XK_dstroke* = 0x000001F0
    XK_nacute* = 0x000001F1
    XK_ncaron* = 0x000001F2
    XK_odoubleacute* = 0x000001F5
    XK_udoubleacute* = 0x000001FB
    XK_rcaron* = 0x000001F8
    XK_uring* = 0x000001F9
    XK_tcedilla* = 0x000001FE
    XK_abovedot* = 0x000001FF
# XK_LATIN2 
#*
# *   Latin 3
# *   Byte 3 = 2
# *

when defined(XK_LATIN3) or true: 
  const
    XKc_Hstroke* = 0x000002A1
    XKc_Hcircumflex* = 0x000002A6
    XKc_Iabovedot* = 0x000002A9
    XKc_Gbreve* = 0x000002AB
    XKc_Jcircumflex* = 0x000002AC
    XK_hstroke* = 0x000002B1
    XK_hcircumflex* = 0x000002B6
    XK_idotless* = 0x000002B9
    XK_gbreve* = 0x000002BB
    XK_jcircumflex* = 0x000002BC
    XKc_Cabovedot* = 0x000002C5
    XKc_Ccircumflex* = 0x000002C6
    XKc_Gabovedot* = 0x000002D5
    XKc_Gcircumflex* = 0x000002D8
    XKc_Ubreve* = 0x000002DD
    XKc_Scircumflex* = 0x000002DE
    XK_cabovedot* = 0x000002E5
    XK_ccircumflex* = 0x000002E6
    XK_gabovedot* = 0x000002F5
    XK_gcircumflex* = 0x000002F8
    XK_ubreve* = 0x000002FD
    XK_scircumflex* = 0x000002FE
# XK_LATIN3 
#*
# *   Latin 4
# *   Byte 3 = 3
# *

when defined(XK_LATIN4) or true: 
  const
    XK_kra* = 0x000003A2
    XK_kappa* = 0x000003A2      # deprecated 
    XKc_Rcedilla* = 0x000003A3
    XKc_Itilde* = 0x000003A5
    XKc_Lcedilla* = 0x000003A6
    XKc_Emacron* = 0x000003AA
    XKc_Gcedilla* = 0x000003AB
    XKc_Tslash* = 0x000003AC
    XK_rcedilla* = 0x000003B3
    XK_itilde* = 0x000003B5
    XK_lcedilla* = 0x000003B6
    XK_emacron* = 0x000003BA
    XK_gcedilla* = 0x000003BB
    XK_tslash* = 0x000003BC
    XKc_ENG* = 0x000003BD
    XK_eng* = 0x000003BF
    XKc_Amacron* = 0x000003C0
    XKc_Iogonek* = 0x000003C7
    XKc_Eabovedot* = 0x000003CC
    XKc_Imacron* = 0x000003CF
    XKc_Ncedilla* = 0x000003D1
    XKc_Omacron* = 0x000003D2
    XKc_Kcedilla* = 0x000003D3
    XKc_Uogonek* = 0x000003D9
    XKc_Utilde* = 0x000003DD
    XKc_Umacron* = 0x000003DE
    XK_amacron* = 0x000003E0
    XK_iogonek* = 0x000003E7
    XK_eabovedot* = 0x000003EC
    XK_imacron* = 0x000003EF
    XK_ncedilla* = 0x000003F1
    XK_omacron* = 0x000003F2
    XK_kcedilla* = 0x000003F3
    XK_uogonek* = 0x000003F9
    XK_utilde* = 0x000003FD
    XK_umacron* = 0x000003FE
# XK_LATIN4 
#*
# * Latin-8
# * Byte 3 = 18
# *

when defined(XK_LATIN8) or true: 
  const
    XKc_Babovedot* = 0x000012A1
    XK_babovedot* = 0x000012A2
    XKc_Dabovedot* = 0x000012A6
    XKc_Wgrave* = 0x000012A8
    XKc_Wacute* = 0x000012AA
    XK_dabovedot* = 0x000012AB
    XKc_Ygrave* = 0x000012AC
    XKc_Fabovedot* = 0x000012B0
    XK_fabovedot* = 0x000012B1
    XKc_Mabovedot* = 0x000012B4
    XK_mabovedot* = 0x000012B5
    XKc_Pabovedot* = 0x000012B7
    XK_wgrave* = 0x000012B8
    XK_pabovedot* = 0x000012B9
    XK_wacute* = 0x000012BA
    XKc_Sabovedot* = 0x000012BB
    XK_ygrave* = 0x000012BC
    XKc_Wdiaeresis* = 0x000012BD
    XK_wdiaeresis* = 0x000012BE
    XK_sabovedot* = 0x000012BF
    XKc_Wcircumflex* = 0x000012D0
    XKc_Tabovedot* = 0x000012D7
    XKc_Ycircumflex* = 0x000012DE
    XK_wcircumflex* = 0x000012F0
    XK_tabovedot* = 0x000012F7
    XK_ycircumflex* = 0x000012FE
# XK_LATIN8 
#*
# * Latin-9 (a.k.a. Latin-0)
# * Byte 3 = 19
# *

when defined(XK_LATIN9) or true: 
  const
    XKc_OE* = 0x000013BC
    XK_oe* = 0x000013BD
    XKc_Ydiaeresis* = 0x000013BE
# XK_LATIN9 
#*
# * Katakana
# * Byte 3 = 4
# *

when defined(XK_KATAKANA) or true: 
  const
    XK_overline* = 0x0000047E
    XK_kana_fullstop* = 0x000004A1
    XK_kana_openingbracket* = 0x000004A2
    XK_kana_closingbracket* = 0x000004A3
    XK_kana_comma* = 0x000004A4
    XK_kana_conjunctive* = 0x000004A5
    XK_kana_middledot* = 0x000004A5 # deprecated 
    XKc_kana_WO* = 0x000004A6
    XK_kana_a* = 0x000004A7
    XK_kana_i* = 0x000004A8
    XK_kana_u* = 0x000004A9
    XK_kana_e* = 0x000004AA
    XK_kana_o* = 0x000004AB
    XK_kana_ya* = 0x000004AC
    XK_kana_yu* = 0x000004AD
    XK_kana_yo* = 0x000004AE
    XK_kana_tsu* = 0x000004AF
    XK_kana_tu* = 0x000004AF    # deprecated 
    XK_prolongedsound* = 0x000004B0
    XKc_kana_A* = 0x000004B1
    XKc_kana_I* = 0x000004B2
    XKc_kana_U* = 0x000004B3
    XKc_kana_E* = 0x000004B4
    XKc_kana_O* = 0x000004B5
    XKc_kana_KA* = 0x000004B6
    XKc_kana_KI* = 0x000004B7
    XKc_kana_KU* = 0x000004B8
    XKc_kana_KE* = 0x000004B9
    XKc_kana_KO* = 0x000004BA
    XKc_kana_SA* = 0x000004BB
    XKc_kana_SHI* = 0x000004BC
    XKc_kana_SU* = 0x000004BD
    XKc_kana_SE* = 0x000004BE
    XKc_kana_SO* = 0x000004BF
    XKc_kana_TA* = 0x000004C0
    XKc_kana_CHI* = 0x000004C1
    XKc_kana_TI* = 0x000004C1   # deprecated 
    XKc_kana_TSU* = 0x000004C2
    XKc_kana_TU* = 0x000004C2   # deprecated 
    XKc_kana_TE* = 0x000004C3
    XKc_kana_TO* = 0x000004C4
    XKc_kana_NA* = 0x000004C5
    XKc_kana_NI* = 0x000004C6
    XKc_kana_NU* = 0x000004C7
    XKc_kana_NE* = 0x000004C8
    XKc_kana_NO* = 0x000004C9
    XKc_kana_HA* = 0x000004CA
    XKc_kana_HI* = 0x000004CB
    XKc_kana_FU* = 0x000004CC
    XKc_kana_HU* = 0x000004CC   # deprecated 
    XKc_kana_HE* = 0x000004CD
    XKc_kana_HO* = 0x000004CE
    XKc_kana_MA* = 0x000004CF
    XKc_kana_MI* = 0x000004D0
    XKc_kana_MU* = 0x000004D1
    XKc_kana_ME* = 0x000004D2
    XKc_kana_MO* = 0x000004D3
    XKc_kana_YA* = 0x000004D4
    XKc_kana_YU* = 0x000004D5
    XKc_kana_YO* = 0x000004D6
    XKc_kana_RA* = 0x000004D7
    XKc_kana_RI* = 0x000004D8
    XKc_kana_RU* = 0x000004D9
    XKc_kana_RE* = 0x000004DA
    XKc_kana_RO* = 0x000004DB
    XKc_kana_WA* = 0x000004DC
    XKc_kana_N* = 0x000004DD
    XK_voicedsound* = 0x000004DE
    XK_semivoicedsound* = 0x000004DF
    XK_kana_switch* = 0x0000FF7E # Alias for mode_switch 
# XK_KATAKANA 
#*
# *  Arabic
# *  Byte 3 = 5
# *

when defined(XK_ARABIC) or true: 
  const
    XK_Farsi_0* = 0x00000590
    XK_Farsi_1* = 0x00000591
    XK_Farsi_2* = 0x00000592
    XK_Farsi_3* = 0x00000593
    XK_Farsi_4* = 0x00000594
    XK_Farsi_5* = 0x00000595
    XK_Farsi_6* = 0x00000596
    XK_Farsi_7* = 0x00000597
    XK_Farsi_8* = 0x00000598
    XK_Farsi_9* = 0x00000599
    XK_Arabic_percent* = 0x000005A5
    XK_Arabic_superscript_alef* = 0x000005A6
    XK_Arabic_tteh* = 0x000005A7
    XK_Arabic_peh* = 0x000005A8
    XK_Arabic_tcheh* = 0x000005A9
    XK_Arabic_ddal* = 0x000005AA
    XK_Arabic_rreh* = 0x000005AB
    XK_Arabic_comma* = 0x000005AC
    XK_Arabic_fullstop* = 0x000005AE
    XK_Arabic_0* = 0x000005B0
    XK_Arabic_1* = 0x000005B1
    XK_Arabic_2* = 0x000005B2
    XK_Arabic_3* = 0x000005B3
    XK_Arabic_4* = 0x000005B4
    XK_Arabic_5* = 0x000005B5
    XK_Arabic_6* = 0x000005B6
    XK_Arabic_7* = 0x000005B7
    XK_Arabic_8* = 0x000005B8
    XK_Arabic_9* = 0x000005B9
    XK_Arabic_semicolon* = 0x000005BB
    XK_Arabic_question_mark* = 0x000005BF
    XK_Arabic_hamza* = 0x000005C1
    XK_Arabic_maddaonalef* = 0x000005C2
    XK_Arabic_hamzaonalef* = 0x000005C3
    XK_Arabic_hamzaonwaw* = 0x000005C4
    XK_Arabic_hamzaunderalef* = 0x000005C5
    XK_Arabic_hamzaonyeh* = 0x000005C6
    XK_Arabic_alef* = 0x000005C7
    XK_Arabic_beh* = 0x000005C8
    XK_Arabic_tehmarbuta* = 0x000005C9
    XK_Arabic_teh* = 0x000005CA
    XK_Arabic_theh* = 0x000005CB
    XK_Arabic_jeem* = 0x000005CC
    XK_Arabic_hah* = 0x000005CD
    XK_Arabic_khah* = 0x000005CE
    XK_Arabic_dal* = 0x000005CF
    XK_Arabic_thal* = 0x000005D0
    XK_Arabic_ra* = 0x000005D1
    XK_Arabic_zain* = 0x000005D2
    XK_Arabic_seen* = 0x000005D3
    XK_Arabic_sheen* = 0x000005D4
    XK_Arabic_sad* = 0x000005D5
    XK_Arabic_dad* = 0x000005D6
    XK_Arabic_tah* = 0x000005D7
    XK_Arabic_zah* = 0x000005D8
    XK_Arabic_ain* = 0x000005D9
    XK_Arabic_ghain* = 0x000005DA
    XK_Arabic_tatweel* = 0x000005E0
    XK_Arabic_feh* = 0x000005E1
    XK_Arabic_qaf* = 0x000005E2
    XK_Arabic_kaf* = 0x000005E3
    XK_Arabic_lam* = 0x000005E4
    XK_Arabic_meem* = 0x000005E5
    XK_Arabic_noon* = 0x000005E6
    XK_Arabic_ha* = 0x000005E7
    XK_Arabic_heh* = 0x000005E7 # deprecated 
    XK_Arabic_waw* = 0x000005E8
    XK_Arabic_alefmaksura* = 0x000005E9
    XK_Arabic_yeh* = 0x000005EA
    XK_Arabic_fathatan* = 0x000005EB
    XK_Arabic_dammatan* = 0x000005EC
    XK_Arabic_kasratan* = 0x000005ED
    XK_Arabic_fatha* = 0x000005EE
    XK_Arabic_damma* = 0x000005EF
    XK_Arabic_kasra* = 0x000005F0
    XK_Arabic_shadda* = 0x000005F1
    XK_Arabic_sukun* = 0x000005F2
    XK_Arabic_madda_above* = 0x000005F3
    XK_Arabic_hamza_above* = 0x000005F4
    XK_Arabic_hamza_below* = 0x000005F5
    XK_Arabic_jeh* = 0x000005F6
    XK_Arabic_veh* = 0x000005F7
    XK_Arabic_keheh* = 0x000005F8
    XK_Arabic_gaf* = 0x000005F9
    XK_Arabic_noon_ghunna* = 0x000005FA
    XK_Arabic_heh_doachashmee* = 0x000005FB
    XK_Farsi_yeh* = 0x000005FC
    XK_Arabic_farsi_yeh* = XK_Farsi_yeh
    XK_Arabic_yeh_baree* = 0x000005FD
    XK_Arabic_heh_goal* = 0x000005FE
    XK_Arabic_switch* = 0x0000FF7E # Alias for mode_switch 
# XK_ARABIC 
#*
# * Cyrillic
# * Byte 3 = 6
# *

when defined(XK_CYRILLIC) or true: 
  const
    XKc_Cyrillic_GHE_bar* = 0x00000680
    XK_Cyrillic_ghe_bar* = 0x00000690
    XKc_Cyrillic_ZHE_descender* = 0x00000681
    XK_Cyrillic_zhe_descender* = 0x00000691
    XKc_Cyrillic_KA_descender* = 0x00000682
    XK_Cyrillic_ka_descender* = 0x00000692
    XKc_Cyrillic_KA_vertstroke* = 0x00000683
    XK_Cyrillic_ka_vertstroke* = 0x00000693
    XKc_Cyrillic_EN_descender* = 0x00000684
    XK_Cyrillic_en_descender* = 0x00000694
    XKc_Cyrillic_U_straight* = 0x00000685
    XK_Cyrillic_u_straight* = 0x00000695
    XKc_Cyrillic_U_straight_bar* = 0x00000686
    XK_Cyrillic_u_straight_bar* = 0x00000696
    XKc_Cyrillic_HA_descender* = 0x00000687
    XK_Cyrillic_ha_descender* = 0x00000697
    XKc_Cyrillic_CHE_descender* = 0x00000688
    XK_Cyrillic_che_descender* = 0x00000698
    XKc_Cyrillic_CHE_vertstroke* = 0x00000689
    XK_Cyrillic_che_vertstroke* = 0x00000699
    XKc_Cyrillic_SHHA* = 0x0000068A
    XK_Cyrillic_shha* = 0x0000069A
    XKc_Cyrillic_SCHWA* = 0x0000068C
    XK_Cyrillic_schwa* = 0x0000069C
    XKc_Cyrillic_I_macron* = 0x0000068D
    XK_Cyrillic_i_macron* = 0x0000069D
    XKc_Cyrillic_O_bar* = 0x0000068E
    XK_Cyrillic_o_bar* = 0x0000069E
    XKc_Cyrillic_U_macron* = 0x0000068F
    XK_Cyrillic_u_macron* = 0x0000069F
    XK_Serbian_dje* = 0x000006A1
    XK_Macedonia_gje* = 0x000006A2
    XK_Cyrillic_io* = 0x000006A3
    XK_Ukrainian_ie* = 0x000006A4
    XK_Ukranian_je* = 0x000006A4 # deprecated 
    XK_Macedonia_dse* = 0x000006A5
    XK_Ukrainian_i* = 0x000006A6
    XK_Ukranian_i* = 0x000006A6 # deprecated 
    XK_Ukrainian_yi* = 0x000006A7
    XK_Ukranian_yi* = 0x000006A7 # deprecated 
    XK_Cyrillic_je* = 0x000006A8
    XK_Serbian_je* = 0x000006A8 # deprecated 
    XK_Cyrillic_lje* = 0x000006A9
    XK_Serbian_lje* = 0x000006A9 # deprecated 
    XK_Cyrillic_nje* = 0x000006AA
    XK_Serbian_nje* = 0x000006AA # deprecated 
    XK_Serbian_tshe* = 0x000006AB
    XK_Macedonia_kje* = 0x000006AC
    XK_Ukrainian_ghe_with_upturn* = 0x000006AD
    XK_Byelorussian_shortu* = 0x000006AE
    XK_Cyrillic_dzhe* = 0x000006AF
    XK_Serbian_dze* = 0x000006AF # deprecated 
    XK_numerosign* = 0x000006B0
    XKc_Serbian_DJE* = 0x000006B1
    XKc_Macedonia_GJE* = 0x000006B2
    XKc_Cyrillic_IO* = 0x000006B3
    XKc_Ukrainian_IE* = 0x000006B4
    XKc_Ukranian_JE* = 0x000006B4 # deprecated 
    XKc_Macedonia_DSE* = 0x000006B5
    XKc_Ukrainian_I* = 0x000006B6
    XKc_Ukranian_I* = 0x000006B6 # deprecated 
    XKc_Ukrainian_YI* = 0x000006B7
    XKc_Ukranian_YI* = 0x000006B7 # deprecated 
    XKc_Cyrillic_JE* = 0x000006B8
    XKc_Serbian_JE* = 0x000006B8 # deprecated 
    XKc_Cyrillic_LJE* = 0x000006B9
    XKc_Serbian_LJE* = 0x000006B9 # deprecated 
    XKc_Cyrillic_NJE* = 0x000006BA
    XKc_Serbian_NJE* = 0x000006BA # deprecated 
    XKc_Serbian_TSHE* = 0x000006BB
    XKc_Macedonia_KJE* = 0x000006BC
    XKc_Ukrainian_GHE_WITH_UPTURN* = 0x000006BD
    XKc_Byelorussian_SHORTU* = 0x000006BE
    XKc_Cyrillic_DZHE* = 0x000006BF
    XKc_Serbian_DZE* = 0x000006BF # deprecated 
    XK_Cyrillic_yu* = 0x000006C0
    XK_Cyrillic_a* = 0x000006C1
    XK_Cyrillic_be* = 0x000006C2
    XK_Cyrillic_tse* = 0x000006C3
    XK_Cyrillic_de* = 0x000006C4
    XK_Cyrillic_ie* = 0x000006C5
    XK_Cyrillic_ef* = 0x000006C6
    XK_Cyrillic_ghe* = 0x000006C7
    XK_Cyrillic_ha* = 0x000006C8
    XK_Cyrillic_i* = 0x000006C9
    XK_Cyrillic_shorti* = 0x000006CA
    XK_Cyrillic_ka* = 0x000006CB
    XK_Cyrillic_el* = 0x000006CC
    XK_Cyrillic_em* = 0x000006CD
    XK_Cyrillic_en* = 0x000006CE
    XK_Cyrillic_o* = 0x000006CF
    XK_Cyrillic_pe* = 0x000006D0
    XK_Cyrillic_ya* = 0x000006D1
    XK_Cyrillic_er* = 0x000006D2
    XK_Cyrillic_es* = 0x000006D3
    XK_Cyrillic_te* = 0x000006D4
    XK_Cyrillic_u* = 0x000006D5
    XK_Cyrillic_zhe* = 0x000006D6
    XK_Cyrillic_ve* = 0x000006D7
    XK_Cyrillic_softsign* = 0x000006D8
    XK_Cyrillic_yeru* = 0x000006D9
    XK_Cyrillic_ze* = 0x000006DA
    XK_Cyrillic_sha* = 0x000006DB
    XK_Cyrillic_e* = 0x000006DC
    XK_Cyrillic_shcha* = 0x000006DD
    XK_Cyrillic_che* = 0x000006DE
    XK_Cyrillic_hardsign* = 0x000006DF
    XKc_Cyrillic_YU* = 0x000006E0
    XKc_Cyrillic_A* = 0x000006E1
    XKc_Cyrillic_BE* = 0x000006E2
    XKc_Cyrillic_TSE* = 0x000006E3
    XKc_Cyrillic_DE* = 0x000006E4
    XKc_Cyrillic_IE* = 0x000006E5
    XKc_Cyrillic_EF* = 0x000006E6
    XKc_Cyrillic_GHE* = 0x000006E7
    XKc_Cyrillic_HA* = 0x000006E8
    XKc_Cyrillic_I* = 0x000006E9
    XKc_Cyrillic_SHORTI* = 0x000006EA
    XKc_Cyrillic_KA* = 0x000006EB
    XKc_Cyrillic_EL* = 0x000006EC
    XKc_Cyrillic_EM* = 0x000006ED
    XKc_Cyrillic_EN* = 0x000006EE
    XKc_Cyrillic_O* = 0x000006EF
    XKc_Cyrillic_PE* = 0x000006F0
    XKc_Cyrillic_YA* = 0x000006F1
    XKc_Cyrillic_ER* = 0x000006F2
    XKc_Cyrillic_ES* = 0x000006F3
    XKc_Cyrillic_TE* = 0x000006F4
    XKc_Cyrillic_U* = 0x000006F5
    XKc_Cyrillic_ZHE* = 0x000006F6
    XKc_Cyrillic_VE* = 0x000006F7
    XKc_Cyrillic_SOFTSIGN* = 0x000006F8
    XKc_Cyrillic_YERU* = 0x000006F9
    XKc_Cyrillic_ZE* = 0x000006FA
    XKc_Cyrillic_SHA* = 0x000006FB
    XKc_Cyrillic_E* = 0x000006FC
    XKc_Cyrillic_SHCHA* = 0x000006FD
    XKc_Cyrillic_CHE* = 0x000006FE
    XKc_Cyrillic_HARDSIGN* = 0x000006FF
# XK_CYRILLIC 
#*
# * Greek
# * Byte 3 = 7
# *

when defined(XK_GREEK) or true: 
  const
    XKc_Greek_ALPHAaccent* = 0x000007A1
    XKc_Greek_EPSILONaccent* = 0x000007A2
    XKc_Greek_ETAaccent* = 0x000007A3
    XKc_Greek_IOTAaccent* = 0x000007A4
    XKc_Greek_IOTAdieresis* = 0x000007A5
    XKc_Greek_IOTAdiaeresis* = XKc_Greek_IOTAdieresis # old typo 
    XKc_Greek_OMICRONaccent* = 0x000007A7
    XKc_Greek_UPSILONaccent* = 0x000007A8
    XKc_Greek_UPSILONdieresis* = 0x000007A9
    XKc_Greek_OMEGAaccent* = 0x000007AB
    XK_Greek_accentdieresis* = 0x000007AE
    XK_Greek_horizbar* = 0x000007AF
    XK_Greek_alphaaccent* = 0x000007B1
    XK_Greek_epsilonaccent* = 0x000007B2
    XK_Greek_etaaccent* = 0x000007B3
    XK_Greek_iotaaccent* = 0x000007B4
    XK_Greek_iotadieresis* = 0x000007B5
    XK_Greek_iotaaccentdieresis* = 0x000007B6
    XK_Greek_omicronaccent* = 0x000007B7
    XK_Greek_upsilonaccent* = 0x000007B8
    XK_Greek_upsilondieresis* = 0x000007B9
    XK_Greek_upsilonaccentdieresis* = 0x000007BA
    XK_Greek_omegaaccent* = 0x000007BB
    XKc_Greek_ALPHA* = 0x000007C1
    XKc_Greek_BETA* = 0x000007C2
    XKc_Greek_GAMMA* = 0x000007C3
    XKc_Greek_DELTA* = 0x000007C4
    XKc_Greek_EPSILON* = 0x000007C5
    XKc_Greek_ZETA* = 0x000007C6
    XKc_Greek_ETA* = 0x000007C7
    XKc_Greek_THETA* = 0x000007C8
    XKc_Greek_IOTA* = 0x000007C9
    XKc_Greek_KAPPA* = 0x000007CA
    XKc_Greek_LAMDA* = 0x000007CB
    XKc_Greek_LAMBDA* = 0x000007CB
    XKc_Greek_MU* = 0x000007CC
    XKc_Greek_NU* = 0x000007CD
    XKc_Greek_XI* = 0x000007CE
    XKc_Greek_OMICRON* = 0x000007CF
    XKc_Greek_PI* = 0x000007D0
    XKc_Greek_RHO* = 0x000007D1
    XKc_Greek_SIGMA* = 0x000007D2
    XKc_Greek_TAU* = 0x000007D4
    XKc_Greek_UPSILON* = 0x000007D5
    XKc_Greek_PHI* = 0x000007D6
    XKc_Greek_CHI* = 0x000007D7
    XKc_Greek_PSI* = 0x000007D8
    XKc_Greek_OMEGA* = 0x000007D9
    XK_Greek_alpha* = 0x000007E1
    XK_Greek_beta* = 0x000007E2
    XK_Greek_gamma* = 0x000007E3
    XK_Greek_delta* = 0x000007E4
    XK_Greek_epsilon* = 0x000007E5
    XK_Greek_zeta* = 0x000007E6
    XK_Greek_eta* = 0x000007E7
    XK_Greek_theta* = 0x000007E8
    XK_Greek_iota* = 0x000007E9
    XK_Greek_kappa* = 0x000007EA
    XK_Greek_lamda* = 0x000007EB
    XK_Greek_lambda* = 0x000007EB
    XK_Greek_mu* = 0x000007EC
    XK_Greek_nu* = 0x000007ED
    XK_Greek_xi* = 0x000007EE
    XK_Greek_omicron* = 0x000007EF
    XK_Greek_pi* = 0x000007F0
    XK_Greek_rho* = 0x000007F1
    XK_Greek_sigma* = 0x000007F2
    XK_Greek_finalsmallsigma* = 0x000007F3
    XK_Greek_tau* = 0x000007F4
    XK_Greek_upsilon* = 0x000007F5
    XK_Greek_phi* = 0x000007F6
    XK_Greek_chi* = 0x000007F7
    XK_Greek_psi* = 0x000007F8
    XK_Greek_omega* = 0x000007F9
    XK_Greek_switch* = 0x0000FF7E # Alias for mode_switch 
# XK_GREEK 
#*
# * Technical
# * Byte 3 = 8
# *

when defined(XK_TECHNICAL) or true: 
  const
    XK_leftradical* = 0x000008A1
    XK_topleftradical* = 0x000008A2
    XK_horizconnector* = 0x000008A3
    XK_topintegral* = 0x000008A4
    XK_botintegral* = 0x000008A5
    XK_vertconnector* = 0x000008A6
    XK_topleftsqbracket* = 0x000008A7
    XK_botleftsqbracket* = 0x000008A8
    XK_toprightsqbracket* = 0x000008A9
    XK_botrightsqbracket* = 0x000008AA
    XK_topleftparens* = 0x000008AB
    XK_botleftparens* = 0x000008AC
    XK_toprightparens* = 0x000008AD
    XK_botrightparens* = 0x000008AE
    XK_leftmiddlecurlybrace* = 0x000008AF
    XK_rightmiddlecurlybrace* = 0x000008B0
    XK_topleftsummation* = 0x000008B1
    XK_botleftsummation* = 0x000008B2
    XK_topvertsummationconnector* = 0x000008B3
    XK_botvertsummationconnector* = 0x000008B4
    XK_toprightsummation* = 0x000008B5
    XK_botrightsummation* = 0x000008B6
    XK_rightmiddlesummation* = 0x000008B7
    XK_lessthanequal* = 0x000008BC
    XK_notequal* = 0x000008BD
    XK_greaterthanequal* = 0x000008BE
    XK_integral* = 0x000008BF
    XK_therefore* = 0x000008C0
    XK_variation* = 0x000008C1
    XK_infinity* = 0x000008C2
    XK_nabla* = 0x000008C5
    XK_approximate* = 0x000008C8
    XK_similarequal* = 0x000008C9
    XK_ifonlyif* = 0x000008CD
    XK_implies* = 0x000008CE
    XK_identical* = 0x000008CF
    XK_radical* = 0x000008D6
    XK_includedin* = 0x000008DA
    XK_includes* = 0x000008DB
    XK_intersection* = 0x000008DC
    XK_union* = 0x000008DD
    XK_logicaland* = 0x000008DE
    XK_logicalor* = 0x000008DF
    XK_partialderivative* = 0x000008EF
    XK_function* = 0x000008F6
    XK_leftarrow* = 0x000008FB
    XK_uparrow* = 0x000008FC
    XK_rightarrow* = 0x000008FD
    XK_downarrow* = 0x000008FE
# XK_TECHNICAL 
#*
# *  Special
# *  Byte 3 = 9
# *

when defined(XK_SPECIAL): 
  const
    XK_blank* = 0x000009DF
    XK_soliddiamond* = 0x000009E0
    XK_checkerboard* = 0x000009E1
    XK_ht* = 0x000009E2
    XK_ff* = 0x000009E3
    XK_cr* = 0x000009E4
    XK_lf* = 0x000009E5
    XK_nl* = 0x000009E8
    XK_vt* = 0x000009E9
    XK_lowrightcorner* = 0x000009EA
    XK_uprightcorner* = 0x000009EB
    XK_upleftcorner* = 0x000009EC
    XK_lowleftcorner* = 0x000009ED
    XK_crossinglines* = 0x000009EE
    XK_horizlinescan1* = 0x000009EF
    XK_horizlinescan3* = 0x000009F0
    XK_horizlinescan5* = 0x000009F1
    XK_horizlinescan7* = 0x000009F2
    XK_horizlinescan9* = 0x000009F3
    XK_leftt* = 0x000009F4
    XK_rightt* = 0x000009F5
    XK_bott* = 0x000009F6
    XK_topt* = 0x000009F7
    XK_vertbar* = 0x000009F8
# XK_SPECIAL 
#*
# *  Publishing
# *  Byte 3 = a
# *

when defined(XK_PUBLISHING) or true: 
  const
    XK_emspace* = 0x00000AA1
    XK_enspace* = 0x00000AA2
    XK_em3space* = 0x00000AA3
    XK_em4space* = 0x00000AA4
    XK_digitspace* = 0x00000AA5
    XK_punctspace* = 0x00000AA6
    XK_thinspace* = 0x00000AA7
    XK_hairspace* = 0x00000AA8
    XK_emdash* = 0x00000AA9
    XK_endash* = 0x00000AAA
    XK_signifblank* = 0x00000AAC
    XK_ellipsis* = 0x00000AAE
    XK_doubbaselinedot* = 0x00000AAF
    XK_onethird* = 0x00000AB0
    XK_twothirds* = 0x00000AB1
    XK_onefifth* = 0x00000AB2
    XK_twofifths* = 0x00000AB3
    XK_threefifths* = 0x00000AB4
    XK_fourfifths* = 0x00000AB5
    XK_onesixth* = 0x00000AB6
    XK_fivesixths* = 0x00000AB7
    XK_careof* = 0x00000AB8
    XK_figdash* = 0x00000ABB
    XK_leftanglebracket* = 0x00000ABC
    XK_decimalpoint* = 0x00000ABD
    XK_rightanglebracket* = 0x00000ABE
    XK_marker* = 0x00000ABF
    XK_oneeighth* = 0x00000AC3
    XK_threeeighths* = 0x00000AC4
    XK_fiveeighths* = 0x00000AC5
    XK_seveneighths* = 0x00000AC6
    XK_trademark* = 0x00000AC9
    XK_signaturemark* = 0x00000ACA
    XK_trademarkincircle* = 0x00000ACB
    XK_leftopentriangle* = 0x00000ACC
    XK_rightopentriangle* = 0x00000ACD
    XK_emopencircle* = 0x00000ACE
    XK_emopenrectangle* = 0x00000ACF
    XK_leftsinglequotemark* = 0x00000AD0
    XK_rightsinglequotemark* = 0x00000AD1
    XK_leftdoublequotemark* = 0x00000AD2
    XK_rightdoublequotemark* = 0x00000AD3
    XK_prescription* = 0x00000AD4
    XK_minutes* = 0x00000AD6
    XK_seconds* = 0x00000AD7
    XK_latincross* = 0x00000AD9
    XK_hexagram* = 0x00000ADA
    XK_filledrectbullet* = 0x00000ADB
    XK_filledlefttribullet* = 0x00000ADC
    XK_filledrighttribullet* = 0x00000ADD
    XK_emfilledcircle* = 0x00000ADE
    XK_emfilledrect* = 0x00000ADF
    XK_enopencircbullet* = 0x00000AE0
    XK_enopensquarebullet* = 0x00000AE1
    XK_openrectbullet* = 0x00000AE2
    XK_opentribulletup* = 0x00000AE3
    XK_opentribulletdown* = 0x00000AE4
    XK_openstar* = 0x00000AE5
    XK_enfilledcircbullet* = 0x00000AE6
    XK_enfilledsqbullet* = 0x00000AE7
    XK_filledtribulletup* = 0x00000AE8
    XK_filledtribulletdown* = 0x00000AE9
    XK_leftpointer* = 0x00000AEA
    XK_rightpointer* = 0x00000AEB
    XK_club* = 0x00000AEC
    XK_diamond* = 0x00000AED
    XK_heart* = 0x00000AEE
    XK_maltesecross* = 0x00000AF0
    XK_dagger* = 0x00000AF1
    XK_doubledagger* = 0x00000AF2
    XK_checkmark* = 0x00000AF3
    XK_ballotcross* = 0x00000AF4
    XK_musicalsharp* = 0x00000AF5
    XK_musicalflat* = 0x00000AF6
    XK_malesymbol* = 0x00000AF7
    XK_femalesymbol* = 0x00000AF8
    XK_telephone* = 0x00000AF9
    XK_telephonerecorder* = 0x00000AFA
    XK_phonographcopyright* = 0x00000AFB
    XK_caret* = 0x00000AFC
    XK_singlelowquotemark* = 0x00000AFD
    XK_doublelowquotemark* = 0x00000AFE
    XK_cursor* = 0x00000AFF
# XK_PUBLISHING 
#*
# *  APL
# *  Byte 3 = b
# *

when defined(XK_APL) or true: 
  const
    XK_leftcaret* = 0x00000BA3
    XK_rightcaret* = 0x00000BA6
    XK_downcaret* = 0x00000BA8
    XK_upcaret* = 0x00000BA9
    XK_overbar* = 0x00000BC0
    XK_downtack* = 0x00000BC2
    XK_upshoe* = 0x00000BC3
    XK_downstile* = 0x00000BC4
    XK_underbar* = 0x00000BC6
    XK_jot* = 0x00000BCA
    XK_quad* = 0x00000BCC
    XK_uptack* = 0x00000BCE
    XK_circle* = 0x00000BCF
    XK_upstile* = 0x00000BD3
    XK_downshoe* = 0x00000BD6
    XK_rightshoe* = 0x00000BD8
    XK_leftshoe* = 0x00000BDA
    XK_lefttack* = 0x00000BDC
    XK_righttack* = 0x00000BFC
# XK_APL 
#*
# * Hebrew
# * Byte 3 = c
# *

when defined(XK_HEBREW) or true: 
  const
    XK_hebrew_doublelowline* = 0x00000CDF
    XK_hebrew_aleph* = 0x00000CE0
    XK_hebrew_bet* = 0x00000CE1
    XK_hebrew_beth* = 0x00000CE1 # deprecated 
    XK_hebrew_gimel* = 0x00000CE2
    XK_hebrew_gimmel* = 0x00000CE2 # deprecated 
    XK_hebrew_dalet* = 0x00000CE3
    XK_hebrew_daleth* = 0x00000CE3 # deprecated 
    XK_hebrew_he* = 0x00000CE4
    XK_hebrew_waw* = 0x00000CE5
    XK_hebrew_zain* = 0x00000CE6
    XK_hebrew_zayin* = 0x00000CE6 # deprecated 
    XK_hebrew_chet* = 0x00000CE7
    XK_hebrew_het* = 0x00000CE7 # deprecated 
    XK_hebrew_tet* = 0x00000CE8
    XK_hebrew_teth* = 0x00000CE8 # deprecated 
    XK_hebrew_yod* = 0x00000CE9
    XK_hebrew_finalkaph* = 0x00000CEA
    XK_hebrew_kaph* = 0x00000CEB
    XK_hebrew_lamed* = 0x00000CEC
    XK_hebrew_finalmem* = 0x00000CED
    XK_hebrew_mem* = 0x00000CEE
    XK_hebrew_finalnun* = 0x00000CEF
    XK_hebrew_nun* = 0x00000CF0
    XK_hebrew_samech* = 0x00000CF1
    XK_hebrew_samekh* = 0x00000CF1 # deprecated 
    XK_hebrew_ayin* = 0x00000CF2
    XK_hebrew_finalpe* = 0x00000CF3
    XK_hebrew_pe* = 0x00000CF4
    XK_hebrew_finalzade* = 0x00000CF5
    XK_hebrew_finalzadi* = 0x00000CF5 # deprecated 
    XK_hebrew_zade* = 0x00000CF6
    XK_hebrew_zadi* = 0x00000CF6 # deprecated 
    XK_hebrew_qoph* = 0x00000CF7
    XK_hebrew_kuf* = 0x00000CF7 # deprecated 
    XK_hebrew_resh* = 0x00000CF8
    XK_hebrew_shin* = 0x00000CF9
    XK_hebrew_taw* = 0x00000CFA
    XK_hebrew_taf* = 0x00000CFA # deprecated 
    XK_Hebrew_switch* = 0x0000FF7E # Alias for mode_switch 
# XK_HEBREW 
#*
# * Thai
# * Byte 3 = d
# *

when defined(XK_THAI) or true: 
  const
    XK_Thai_kokai* = 0x00000DA1
    XK_Thai_khokhai* = 0x00000DA2
    XK_Thai_khokhuat* = 0x00000DA3
    XK_Thai_khokhwai* = 0x00000DA4
    XK_Thai_khokhon* = 0x00000DA5
    XK_Thai_khorakhang* = 0x00000DA6
    XK_Thai_ngongu* = 0x00000DA7
    XK_Thai_chochan* = 0x00000DA8
    XK_Thai_choching* = 0x00000DA9
    XK_Thai_chochang* = 0x00000DAA
    XK_Thai_soso* = 0x00000DAB
    XK_Thai_chochoe* = 0x00000DAC
    XK_Thai_yoying* = 0x00000DAD
    XK_Thai_dochada* = 0x00000DAE
    XK_Thai_topatak* = 0x00000DAF
    XK_Thai_thothan* = 0x00000DB0
    XK_Thai_thonangmontho* = 0x00000DB1
    XK_Thai_thophuthao* = 0x00000DB2
    XK_Thai_nonen* = 0x00000DB3
    XK_Thai_dodek* = 0x00000DB4
    XK_Thai_totao* = 0x00000DB5
    XK_Thai_thothung* = 0x00000DB6
    XK_Thai_thothahan* = 0x00000DB7
    XK_Thai_thothong* = 0x00000DB8
    XK_Thai_nonu* = 0x00000DB9
    XK_Thai_bobaimai* = 0x00000DBA
    XK_Thai_popla* = 0x00000DBB
    XK_Thai_phophung* = 0x00000DBC
    XK_Thai_fofa* = 0x00000DBD
    XK_Thai_phophan* = 0x00000DBE
    XK_Thai_fofan* = 0x00000DBF
    XK_Thai_phosamphao* = 0x00000DC0
    XK_Thai_moma* = 0x00000DC1
    XK_Thai_yoyak* = 0x00000DC2
    XK_Thai_rorua* = 0x00000DC3
    XK_Thai_ru* = 0x00000DC4
    XK_Thai_loling* = 0x00000DC5
    XK_Thai_lu* = 0x00000DC6
    XK_Thai_wowaen* = 0x00000DC7
    XK_Thai_sosala* = 0x00000DC8
    XK_Thai_sorusi* = 0x00000DC9
    XK_Thai_sosua* = 0x00000DCA
    XK_Thai_hohip* = 0x00000DCB
    XK_Thai_lochula* = 0x00000DCC
    XK_Thai_oang* = 0x00000DCD
    XK_Thai_honokhuk* = 0x00000DCE
    XK_Thai_paiyannoi* = 0x00000DCF
    XK_Thai_saraa* = 0x00000DD0
    XK_Thai_maihanakat* = 0x00000DD1
    XK_Thai_saraaa* = 0x00000DD2
    XK_Thai_saraam* = 0x00000DD3
    XK_Thai_sarai* = 0x00000DD4
    XK_Thai_saraii* = 0x00000DD5
    XK_Thai_saraue* = 0x00000DD6
    XK_Thai_sarauee* = 0x00000DD7
    XK_Thai_sarau* = 0x00000DD8
    XK_Thai_sarauu* = 0x00000DD9
    XK_Thai_phinthu* = 0x00000DDA
    XK_Thai_maihanakat_maitho* = 0x00000DDE
    XK_Thai_baht* = 0x00000DDF
    XK_Thai_sarae* = 0x00000DE0
    XK_Thai_saraae* = 0x00000DE1
    XK_Thai_sarao* = 0x00000DE2
    XK_Thai_saraaimaimuan* = 0x00000DE3
    XK_Thai_saraaimaimalai* = 0x00000DE4
    XK_Thai_lakkhangyao* = 0x00000DE5
    XK_Thai_maiyamok* = 0x00000DE6
    XK_Thai_maitaikhu* = 0x00000DE7
    XK_Thai_maiek* = 0x00000DE8
    XK_Thai_maitho* = 0x00000DE9
    XK_Thai_maitri* = 0x00000DEA
    XK_Thai_maichattawa* = 0x00000DEB
    XK_Thai_thanthakhat* = 0x00000DEC
    XK_Thai_nikhahit* = 0x00000DED
    XK_Thai_leksun* = 0x00000DF0
    XK_Thai_leknung* = 0x00000DF1
    XK_Thai_leksong* = 0x00000DF2
    XK_Thai_leksam* = 0x00000DF3
    XK_Thai_leksi* = 0x00000DF4
    XK_Thai_lekha* = 0x00000DF5
    XK_Thai_lekhok* = 0x00000DF6
    XK_Thai_lekchet* = 0x00000DF7
    XK_Thai_lekpaet* = 0x00000DF8
    XK_Thai_lekkao* = 0x00000DF9
# XK_THAI 
#*
# *   Korean
# *   Byte 3 = e
# *

when defined(XK_KOREAN) or true: 
  const
    XK_Hangul* = 0x0000FF31     # Hangul start/stop(toggle) 
    XK_Hangul_Start* = 0x0000FF32 # Hangul start 
    XK_Hangul_End* = 0x0000FF33 # Hangul end, English start 
    XK_Hangul_Hanja* = 0x0000FF34 # Start Hangul->Hanja Conversion 
    XK_Hangul_Jamo* = 0x0000FF35 # Hangul Jamo mode 
    XK_Hangul_Romaja* = 0x0000FF36 # Hangul Romaja mode 
    XK_Hangul_Codeinput* = 0x0000FF37 # Hangul code input mode 
    XK_Hangul_Jeonja* = 0x0000FF38 # Jeonja mode 
    XK_Hangul_Banja* = 0x0000FF39 # Banja mode 
    XK_Hangul_PreHanja* = 0x0000FF3A # Pre Hanja conversion 
    XK_Hangul_PostHanja* = 0x0000FF3B # Post Hanja conversion 
    XK_Hangul_SingleCandidate* = 0x0000FF3C # Single candidate 
    XK_Hangul_MultipleCandidate* = 0x0000FF3D # Multiple candidate 
    XK_Hangul_PreviousCandidate* = 0x0000FF3E # Previous candidate 
    XK_Hangul_Special* = 0x0000FF3F # Special symbols 
    XK_Hangul_switch* = 0x0000FF7E # Alias for mode_switch 
                                   # Hangul Consonant Characters 
    XK_Hangul_Kiyeog* = 0x00000EA1
    XK_Hangul_SsangKiyeog* = 0x00000EA2
    XK_Hangul_KiyeogSios* = 0x00000EA3
    XK_Hangul_Nieun* = 0x00000EA4
    XK_Hangul_NieunJieuj* = 0x00000EA5
    XK_Hangul_NieunHieuh* = 0x00000EA6
    XK_Hangul_Dikeud* = 0x00000EA7
    XK_Hangul_SsangDikeud* = 0x00000EA8
    XK_Hangul_Rieul* = 0x00000EA9
    XK_Hangul_RieulKiyeog* = 0x00000EAA
    XK_Hangul_RieulMieum* = 0x00000EAB
    XK_Hangul_RieulPieub* = 0x00000EAC
    XK_Hangul_RieulSios* = 0x00000EAD
    XK_Hangul_RieulTieut* = 0x00000EAE
    XK_Hangul_RieulPhieuf* = 0x00000EAF
    XK_Hangul_RieulHieuh* = 0x00000EB0
    XK_Hangul_Mieum* = 0x00000EB1
    XK_Hangul_Pieub* = 0x00000EB2
    XK_Hangul_SsangPieub* = 0x00000EB3
    XK_Hangul_PieubSios* = 0x00000EB4
    XK_Hangul_Sios* = 0x00000EB5
    XK_Hangul_SsangSios* = 0x00000EB6
    XK_Hangul_Ieung* = 0x00000EB7
    XK_Hangul_Jieuj* = 0x00000EB8
    XK_Hangul_SsangJieuj* = 0x00000EB9
    XK_Hangul_Cieuc* = 0x00000EBA
    XK_Hangul_Khieuq* = 0x00000EBB
    XK_Hangul_Tieut* = 0x00000EBC
    XK_Hangul_Phieuf* = 0x00000EBD
    XK_Hangul_Hieuh* = 0x00000EBE # Hangul Vowel Characters 
    XK_Hangul_A* = 0x00000EBF
    XK_Hangul_AE* = 0x00000EC0
    XK_Hangul_YA* = 0x00000EC1
    XK_Hangul_YAE* = 0x00000EC2
    XK_Hangul_EO* = 0x00000EC3
    XK_Hangul_E* = 0x00000EC4
    XK_Hangul_YEO* = 0x00000EC5
    XK_Hangul_YE* = 0x00000EC6
    XK_Hangul_O* = 0x00000EC7
    XK_Hangul_WA* = 0x00000EC8
    XK_Hangul_WAE* = 0x00000EC9
    XK_Hangul_OE* = 0x00000ECA
    XK_Hangul_YO* = 0x00000ECB
    XK_Hangul_U* = 0x00000ECC
    XK_Hangul_WEO* = 0x00000ECD
    XK_Hangul_WE* = 0x00000ECE
    XK_Hangul_WI* = 0x00000ECF
    XK_Hangul_YU* = 0x00000ED0
    XK_Hangul_EU* = 0x00000ED1
    XK_Hangul_YI* = 0x00000ED2
    XK_Hangul_I* = 0x00000ED3   # Hangul syllable-final (JongSeong) Characters 
    XK_Hangul_J_Kiyeog* = 0x00000ED4
    XK_Hangul_J_SsangKiyeog* = 0x00000ED5
    XK_Hangul_J_KiyeogSios* = 0x00000ED6
    XK_Hangul_J_Nieun* = 0x00000ED7
    XK_Hangul_J_NieunJieuj* = 0x00000ED8
    XK_Hangul_J_NieunHieuh* = 0x00000ED9
    XK_Hangul_J_Dikeud* = 0x00000EDA
    XK_Hangul_J_Rieul* = 0x00000EDB
    XK_Hangul_J_RieulKiyeog* = 0x00000EDC
    XK_Hangul_J_RieulMieum* = 0x00000EDD
    XK_Hangul_J_RieulPieub* = 0x00000EDE
    XK_Hangul_J_RieulSios* = 0x00000EDF
    XK_Hangul_J_RieulTieut* = 0x00000EE0
    XK_Hangul_J_RieulPhieuf* = 0x00000EE1
    XK_Hangul_J_RieulHieuh* = 0x00000EE2
    XK_Hangul_J_Mieum* = 0x00000EE3
    XK_Hangul_J_Pieub* = 0x00000EE4
    XK_Hangul_J_PieubSios* = 0x00000EE5
    XK_Hangul_J_Sios* = 0x00000EE6
    XK_Hangul_J_SsangSios* = 0x00000EE7
    XK_Hangul_J_Ieung* = 0x00000EE8
    XK_Hangul_J_Jieuj* = 0x00000EE9
    XK_Hangul_J_Cieuc* = 0x00000EEA
    XK_Hangul_J_Khieuq* = 0x00000EEB
    XK_Hangul_J_Tieut* = 0x00000EEC
    XK_Hangul_J_Phieuf* = 0x00000EED
    XK_Hangul_J_Hieuh* = 0x00000EEE # Ancient Hangul Consonant Characters 
    XK_Hangul_RieulYeorinHieuh* = 0x00000EEF
    XK_Hangul_SunkyeongeumMieum* = 0x00000EF0
    XK_Hangul_SunkyeongeumPieub* = 0x00000EF1
    XK_Hangul_PanSios* = 0x00000EF2
    XK_Hangul_KkogjiDalrinIeung* = 0x00000EF3
    XK_Hangul_SunkyeongeumPhieuf* = 0x00000EF4
    XK_Hangul_YeorinHieuh* = 0x00000EF5 # Ancient Hangul Vowel Characters 
    XK_Hangul_AraeA* = 0x00000EF6
    XK_Hangul_AraeAE* = 0x00000EF7 # Ancient Hangul syllable-final (JongSeong) Characters 
    XK_Hangul_J_PanSios* = 0x00000EF8
    XK_Hangul_J_KkogjiDalrinIeung* = 0x00000EF9
    XK_Hangul_J_YeorinHieuh* = 0x00000EFA # Korean currency symbol 
    XK_Korean_Won* = 0x00000EFF
# XK_KOREAN 
#*
# *   Armenian
# *   Byte 3 = = $14
# *

when defined(XK_ARMENIAN) or true: 
  const
    XK_Armenian_eternity* = 0x000014A1
    XK_Armenian_ligature_ew* = 0x000014A2
    XK_Armenian_full_stop* = 0x000014A3
    XK_Armenian_verjaket* = 0x000014A3
    XK_Armenian_parenright* = 0x000014A4
    XK_Armenian_parenleft* = 0x000014A5
    XK_Armenian_guillemotright* = 0x000014A6
    XK_Armenian_guillemotleft* = 0x000014A7
    XK_Armenian_em_dash* = 0x000014A8
    XK_Armenian_dot* = 0x000014A9
    XK_Armenian_mijaket* = 0x000014A9
    XK_Armenian_separation_mark* = 0x000014AA
    XK_Armenian_but* = 0x000014AA
    XK_Armenian_comma* = 0x000014AB
    XK_Armenian_en_dash* = 0x000014AC
    XK_Armenian_hyphen* = 0x000014AD
    XK_Armenian_yentamna* = 0x000014AD
    XK_Armenian_ellipsis* = 0x000014AE
    XK_Armenian_exclam* = 0x000014AF
    XK_Armenian_amanak* = 0x000014AF
    XK_Armenian_accent* = 0x000014B0
    XK_Armenian_shesht* = 0x000014B0
    XK_Armenian_question* = 0x000014B1
    XK_Armenian_paruyk* = 0x000014B1
    XKc_Armenian_AYB* = 0x000014B2
    XK_Armenian_ayb* = 0x000014B3
    XKc_Armenian_BEN* = 0x000014B4
    XK_Armenian_ben* = 0x000014B5
    XKc_Armenian_GIM* = 0x000014B6
    XK_Armenian_gim* = 0x000014B7
    XKc_Armenian_DA* = 0x000014B8
    XK_Armenian_da* = 0x000014B9
    XKc_Armenian_YECH* = 0x000014BA
    XK_Armenian_yech* = 0x000014BB
    XKc_Armenian_ZA* = 0x000014BC
    XK_Armenian_za* = 0x000014BD
    XKc_Armenian_E* = 0x000014BE
    XK_Armenian_e* = 0x000014BF
    XKc_Armenian_AT* = 0x000014C0
    XK_Armenian_at* = 0x000014C1
    XKc_Armenian_TO* = 0x000014C2
    XK_Armenian_to* = 0x000014C3
    XKc_Armenian_ZHE* = 0x000014C4
    XK_Armenian_zhe* = 0x000014C5
    XKc_Armenian_INI* = 0x000014C6
    XK_Armenian_ini* = 0x000014C7
    XKc_Armenian_LYUN* = 0x000014C8
    XK_Armenian_lyun* = 0x000014C9
    XKc_Armenian_KHE* = 0x000014CA
    XK_Armenian_khe* = 0x000014CB
    XKc_Armenian_TSA* = 0x000014CC
    XK_Armenian_tsa* = 0x000014CD
    XKc_Armenian_KEN* = 0x000014CE
    XK_Armenian_ken* = 0x000014CF
    XKc_Armenian_HO* = 0x000014D0
    XK_Armenian_ho* = 0x000014D1
    XKc_Armenian_DZA* = 0x000014D2
    XK_Armenian_dza* = 0x000014D3
    XKc_Armenian_GHAT* = 0x000014D4
    XK_Armenian_ghat* = 0x000014D5
    XKc_Armenian_TCHE* = 0x000014D6
    XK_Armenian_tche* = 0x000014D7
    XKc_Armenian_MEN* = 0x000014D8
    XK_Armenian_men* = 0x000014D9
    XKc_Armenian_HI* = 0x000014DA
    XK_Armenian_hi* = 0x000014DB
    XKc_Armenian_NU* = 0x000014DC
    XK_Armenian_nu* = 0x000014DD
    XKc_Armenian_SHA* = 0x000014DE
    XK_Armenian_sha* = 0x000014DF
    XKc_Armenian_VO* = 0x000014E0
    XK_Armenian_vo* = 0x000014E1
    XKc_Armenian_CHA* = 0x000014E2
    XK_Armenian_cha* = 0x000014E3
    XKc_Armenian_PE* = 0x000014E4
    XK_Armenian_pe* = 0x000014E5
    XKc_Armenian_JE* = 0x000014E6
    XK_Armenian_je* = 0x000014E7
    XKc_Armenian_RA* = 0x000014E8
    XK_Armenian_ra* = 0x000014E9
    XKc_Armenian_SE* = 0x000014EA
    XK_Armenian_se* = 0x000014EB
    XKc_Armenian_VEV* = 0x000014EC
    XK_Armenian_vev* = 0x000014ED
    XKc_Armenian_TYUN* = 0x000014EE
    XK_Armenian_tyun* = 0x000014EF
    XKc_Armenian_RE* = 0x000014F0
    XK_Armenian_re* = 0x000014F1
    XKc_Armenian_TSO* = 0x000014F2
    XK_Armenian_tso* = 0x000014F3
    XKc_Armenian_VYUN* = 0x000014F4
    XK_Armenian_vyun* = 0x000014F5
    XKc_Armenian_PYUR* = 0x000014F6
    XK_Armenian_pyur* = 0x000014F7
    XKc_Armenian_KE* = 0x000014F8
    XK_Armenian_ke* = 0x000014F9
    XKc_Armenian_O* = 0x000014FA
    XK_Armenian_o* = 0x000014FB
    XKc_Armenian_FE* = 0x000014FC
    XK_Armenian_fe* = 0x000014FD
    XK_Armenian_apostrophe* = 0x000014FE
    XK_Armenian_section_sign* = 0x000014FF
# XK_ARMENIAN 
#*
# *   Georgian
# *   Byte 3 = = $15
# *

when defined(XK_GEORGIAN) or true: 
  const
    XK_Georgian_an* = 0x000015D0
    XK_Georgian_ban* = 0x000015D1
    XK_Georgian_gan* = 0x000015D2
    XK_Georgian_don* = 0x000015D3
    XK_Georgian_en* = 0x000015D4
    XK_Georgian_vin* = 0x000015D5
    XK_Georgian_zen* = 0x000015D6
    XK_Georgian_tan* = 0x000015D7
    XK_Georgian_in* = 0x000015D8
    XK_Georgian_kan* = 0x000015D9
    XK_Georgian_las* = 0x000015DA
    XK_Georgian_man* = 0x000015DB
    XK_Georgian_nar* = 0x000015DC
    XK_Georgian_on* = 0x000015DD
    XK_Georgian_par* = 0x000015DE
    XK_Georgian_zhar* = 0x000015DF
    XK_Georgian_rae* = 0x000015E0
    XK_Georgian_san* = 0x000015E1
    XK_Georgian_tar* = 0x000015E2
    XK_Georgian_un* = 0x000015E3
    XK_Georgian_phar* = 0x000015E4
    XK_Georgian_khar* = 0x000015E5
    XK_Georgian_ghan* = 0x000015E6
    XK_Georgian_qar* = 0x000015E7
    XK_Georgian_shin* = 0x000015E8
    XK_Georgian_chin* = 0x000015E9
    XK_Georgian_can* = 0x000015EA
    XK_Georgian_jil* = 0x000015EB
    XK_Georgian_cil* = 0x000015EC
    XK_Georgian_char* = 0x000015ED
    XK_Georgian_xan* = 0x000015EE
    XK_Georgian_jhan* = 0x000015EF
    XK_Georgian_hae* = 0x000015F0
    XK_Georgian_he* = 0x000015F1
    XK_Georgian_hie* = 0x000015F2
    XK_Georgian_we* = 0x000015F3
    XK_Georgian_har* = 0x000015F4
    XK_Georgian_hoe* = 0x000015F5
    XK_Georgian_fi* = 0x000015F6
# XK_GEORGIAN 
#*
# * Azeri (and other Turkic or Caucasian languages of ex-USSR)
# * Byte 3 = = $16
# *

when defined(XK_CAUCASUS) or true: 
  # latin 
  const
    XKc_Ccedillaabovedot* = 0x000016A2
    XKc_Xabovedot* = 0x000016A3
    XKc_Qabovedot* = 0x000016A5
    XKc_Ibreve* = 0x000016A6
    XKc_IE* = 0x000016A7
    XKc_UO* = 0x000016A8
    XKc_Zstroke* = 0x000016A9
    XKc_Gcaron* = 0x000016AA
    XKc_Obarred* = 0x000016AF
    XK_ccedillaabovedot* = 0x000016B2
    XK_xabovedot* = 0x000016B3
    XKc_Ocaron* = 0x000016B4
    XK_qabovedot* = 0x000016B5
    XK_ibreve* = 0x000016B6
    XK_ie* = 0x000016B7
    XK_uo* = 0x000016B8
    XK_zstroke* = 0x000016B9
    XK_gcaron* = 0x000016BA
    XK_ocaron* = 0x000016BD
    XK_obarred* = 0x000016BF
    XKc_SCHWA* = 0x000016C6
    XK_schwa* = 0x000016F6 # those are not really Caucasus, but I put them here for now 
                           # For Inupiak 
    XKc_Lbelowdot* = 0x000016D1
    XKc_Lstrokebelowdot* = 0x000016D2
    XK_lbelowdot* = 0x000016E1
    XK_lstrokebelowdot* = 0x000016E2 # For Guarani 
    XKc_Gtilde* = 0x000016D3
    XK_gtilde* = 0x000016E3
# XK_CAUCASUS 
#*
# *   Vietnamese
# *   Byte 3 = = $1e
# *

when defined(XK_VIETNAMESE) or true:
  const 
    XKc_Abelowdot* = 0x00001EA0
    XK_abelowdot* = 0x00001EA1
    XKc_Ahook* = 0x00001EA2
    XK_ahook* = 0x00001EA3
    XKc_Acircumflexacute* = 0x00001EA4
    XK_acircumflexacute* = 0x00001EA5
    XKc_Acircumflexgrave* = 0x00001EA6
    XK_acircumflexgrave* = 0x00001EA7
    XKc_Acircumflexhook* = 0x00001EA8
    XK_acircumflexhook* = 0x00001EA9
    XKc_Acircumflextilde* = 0x00001EAA
    XK_acircumflextilde* = 0x00001EAB
    XKc_Acircumflexbelowdot* = 0x00001EAC
    XK_acircumflexbelowdot* = 0x00001EAD
    XKc_Abreveacute* = 0x00001EAE
    XK_abreveacute* = 0x00001EAF
    XKc_Abrevegrave* = 0x00001EB0
    XK_abrevegrave* = 0x00001EB1
    XKc_Abrevehook* = 0x00001EB2
    XK_abrevehook* = 0x00001EB3
    XKc_Abrevetilde* = 0x00001EB4
    XK_abrevetilde* = 0x00001EB5
    XKc_Abrevebelowdot* = 0x00001EB6
    XK_abrevebelowdot* = 0x00001EB7
    XKc_Ebelowdot* = 0x00001EB8
    XK_ebelowdot* = 0x00001EB9
    XKc_Ehook* = 0x00001EBA
    XK_ehook* = 0x00001EBB
    XKc_Etilde* = 0x00001EBC
    XK_etilde* = 0x00001EBD
    XKc_Ecircumflexacute* = 0x00001EBE
    XK_ecircumflexacute* = 0x00001EBF
    XKc_Ecircumflexgrave* = 0x00001EC0
    XK_ecircumflexgrave* = 0x00001EC1
    XKc_Ecircumflexhook* = 0x00001EC2
    XK_ecircumflexhook* = 0x00001EC3
    XKc_Ecircumflextilde* = 0x00001EC4
    XK_ecircumflextilde* = 0x00001EC5
    XKc_Ecircumflexbelowdot* = 0x00001EC6
    XK_ecircumflexbelowdot* = 0x00001EC7
    XKc_Ihook* = 0x00001EC8
    XK_ihook* = 0x00001EC9
    XKc_Ibelowdot* = 0x00001ECA
    XK_ibelowdot* = 0x00001ECB
    XKc_Obelowdot* = 0x00001ECC
    XK_obelowdot* = 0x00001ECD
    XKc_Ohook* = 0x00001ECE
    XK_ohook* = 0x00001ECF
    XKc_Ocircumflexacute* = 0x00001ED0
    XK_ocircumflexacute* = 0x00001ED1
    XKc_Ocircumflexgrave* = 0x00001ED2
    XK_ocircumflexgrave* = 0x00001ED3
    XKc_Ocircumflexhook* = 0x00001ED4
    XK_ocircumflexhook* = 0x00001ED5
    XKc_Ocircumflextilde* = 0x00001ED6
    XK_ocircumflextilde* = 0x00001ED7
    XKc_Ocircumflexbelowdot* = 0x00001ED8
    XK_ocircumflexbelowdot* = 0x00001ED9
    XKc_Ohornacute* = 0x00001EDA
    XK_ohornacute* = 0x00001EDB
    XKc_Ohorngrave* = 0x00001EDC
    XK_ohorngrave* = 0x00001EDD
    XKc_Ohornhook* = 0x00001EDE
    XK_ohornhook* = 0x00001EDF
    XKc_Ohorntilde* = 0x00001EE0
    XK_ohorntilde* = 0x00001EE1
    XKc_Ohornbelowdot* = 0x00001EE2
    XK_ohornbelowdot* = 0x00001EE3
    XKc_Ubelowdot* = 0x00001EE4
    XK_ubelowdot* = 0x00001EE5
    XKc_Uhook* = 0x00001EE6
    XK_uhook* = 0x00001EE7
    XKc_Uhornacute* = 0x00001EE8
    XK_uhornacute* = 0x00001EE9
    XKc_Uhorngrave* = 0x00001EEA
    XK_uhorngrave* = 0x00001EEB
    XKc_Uhornhook* = 0x00001EEC
    XK_uhornhook* = 0x00001EED
    XKc_Uhorntilde* = 0x00001EEE
    XK_uhorntilde* = 0x00001EEF
    XKc_Uhornbelowdot* = 0x00001EF0
    XK_uhornbelowdot* = 0x00001EF1
    XKc_Ybelowdot* = 0x00001EF4
    XK_ybelowdot* = 0x00001EF5
    XKc_Yhook* = 0x00001EF6
    XK_yhook* = 0x00001EF7
    XKc_Ytilde* = 0x00001EF8
    XK_ytilde* = 0x00001EF9
    XKc_Ohorn* = 0x00001EFA     # U+01a0 
    XK_ohorn* = 0x00001EFB      # U+01a1 
    XKc_Uhorn* = 0x00001EFC     # U+01af 
    XK_uhorn* = 0x00001EFD      # U+01b0 
    XK_combining_tilde* = 0x00001E9F # U+0303 
    XK_combining_grave* = 0x00001EF2 # U+0300 
    XK_combining_acute* = 0x00001EF3 # U+0301 
    XK_combining_hook* = 0x00001EFE # U+0309 
    XK_combining_belowdot* = 0x00001EFF # U+0323 
# XK_VIETNAMESE 

when defined(XK_CURRENCY) or true: 
  const
    XK_EcuSign* = 0x000020A0
    XK_ColonSign* = 0x000020A1
    XK_CruzeiroSign* = 0x000020A2
    XK_FFrancSign* = 0x000020A3
    XK_LiraSign* = 0x000020A4
    XK_MillSign* = 0x000020A5
    XK_NairaSign* = 0x000020A6
    XK_PesetaSign* = 0x000020A7
    XK_RupeeSign* = 0x000020A8
    XK_WonSign* = 0x000020A9
    XK_NewSheqelSign* = 0x000020AA
    XK_DongSign* = 0x000020AB
    XK_EuroSign* = 0x000020AC
# implementation
