{.deadCodeElim: on.}

discard """

curses.h:
#ifdef C2NIM
#dynlib pdcursesdll
#skipinclude
#prefix PDC_
#def FALSE
#def TRUE
#def NULL
#def bool unsigned char
#def chtype unsigned long
#def cchar_t unsigned long
#def attr_t unsigned long
#def mmask_t unsigned long
#def wchar_t char
#def PDCEX
#cdecl
#endif

pdcwin.h:
#ifdef C2NIM
#dynlib pdcursesdll
#skipinclude
#prefix pdc_
#prefix PDC_
#stdcall
#endif
"""

when defined(windows):
  import windows

  const
    pdcursesdll = "pdcurses.dll"
    unixOS = false
  {.pragma: extdecl, stdcall.}

when not defined(windows):
  const
    unixOS = true
  {.pragma: extdecl, cdecl.}

type
  cunsignedchar = char
  cunsignedlong = uint32

const
  BUILD* = 3401
  PDCURSES* = 1               # PDCurses-only routines
  XOPEN* = 1                  # X/Open Curses routines
  SYSVcurses* = 1             # System V Curses routines
  BSDcurses* = 1              # BSD Curses routines
  CHTYPE_LONG* = 1            # size of chtype; long
  ERR* = (- 1)
  OK* = 0
  BUTTON_RELEASED* = 0x00000000
  BUTTON_PRESSED* = 0x00000001
  BUTTON_CLICKED* = 0x00000002
  BUTTON_DOUBLE_CLICKED* = 0x00000003
  BUTTON_TRIPLE_CLICKED* = 0x00000004
  BUTTON_MOVED* = 0x00000005  # PDCurses
  WHEEL_SCROLLED* = 0x00000006 # PDCurses
  BUTTON_ACTION_MASK* = 0x00000007 # PDCurses
  BUTTON_MODIFIER_MASK* = 0x00000038 # PDCurses
  MOUSE_MOVED* = 0x00000008
  MOUSE_POSITION* = 0x00000010
  MOUSE_WHEEL_UP* = 0x00000020
  MOUSE_WHEEL_DOWN* = 0x00000040
  BUTTON1_RELEASED* = 0x00000001
  BUTTON1_PRESSED* = 0x00000002
  BUTTON1_CLICKED* = 0x00000004
  BUTTON1_DOUBLE_CLICKED* = 0x00000008
  BUTTON1_TRIPLE_CLICKED* = 0x00000010
  BUTTON1_MOVED* = 0x00000010 # PDCurses
  BUTTON2_RELEASED* = 0x00000020
  BUTTON2_PRESSED* = 0x00000040
  BUTTON2_CLICKED* = 0x00000080
  BUTTON2_DOUBLE_CLICKED* = 0x00000100
  BUTTON2_TRIPLE_CLICKED* = 0x00000200
  BUTTON2_MOVED* = 0x00000200 # PDCurses
  BUTTON3_RELEASED* = 0x00000400
  BUTTON3_PRESSED* = 0x00000800
  BUTTON3_CLICKED* = 0x00001000
  BUTTON3_DOUBLE_CLICKED* = 0x00002000
  BUTTON3_TRIPLE_CLICKED* = 0x00004000
  BUTTON3_MOVED* = 0x00004000 # PDCurses
  BUTTON4_RELEASED* = 0x00008000
  BUTTON4_PRESSED* = 0x00010000
  BUTTON4_CLICKED* = 0x00020000
  BUTTON4_DOUBLE_CLICKED* = 0x00040000
  BUTTON4_TRIPLE_CLICKED* = 0x00080000
  BUTTON5_RELEASED* = 0x00100000
  BUTTON5_PRESSED* = 0x00200000
  BUTTON5_CLICKED* = 0x00400000
  BUTTON5_DOUBLE_CLICKED* = 0x00800000
  BUTTON5_TRIPLE_CLICKED* = 0x01000000
  MOUSE_WHEEL_SCROLL* = 0x02000000 # PDCurses
  BUTTON_MODIFIER_SHIFT* = 0x04000000 # PDCurses
  BUTTON_MODIFIER_CONTROL* = 0x08000000 # PDCurses
  BUTTON_MODIFIER_ALT* = 0x10000000 # PDCurses
  ALL_MOUSE_EVENTS* = 0x1FFFFFFF
  REPORT_MOUSE_POSITION* = 0x20000000
  A_NORMAL* = 0
  A_ALTCHARSET* = 0x00010000
  A_RIGHTLINE* = 0x00020000
  A_LEFTLINE* = 0x00040000
  A_INVIS* = 0x00080000
  A_UNDERLINE* = 0x00100000
  A_REVERSE* = 0x00200000
  A_BLINK* = 0x00400000
  A_BOLD* = 0x00800000
  A_ATTRIBUTES* = 0xFFFF0000
  A_CHARTEXT* = 0x0000FFFF
  A_COLOR* = 0xFF000000
  A_ITALIC* = A_INVIS
  A_PROTECT* = (A_UNDERLINE or A_LEFTLINE or A_RIGHTLINE)
  ATTR_SHIFT* = 19
  COLOR_SHIFT* = 24
  A_STANDOUT* = (A_REVERSE or A_BOLD) # X/Open
  A_DIM* = A_NORMAL
  CHR_MSK* = A_CHARTEXT       # Obsolete
  ATR_MSK* = A_ATTRIBUTES     # Obsolete
  ATR_NRM* = A_NORMAL         # Obsolete
  WA_ALTCHARSET* = A_ALTCHARSET
  WA_BLINK* = A_BLINK
  WA_BOLD* = A_BOLD
  WA_DIM* = A_DIM
  WA_INVIS* = A_INVIS
  WA_LEFT* = A_LEFTLINE
  WA_PROTECT* = A_PROTECT
  WA_REVERSE* = A_REVERSE
  WA_RIGHT* = A_RIGHTLINE
  WA_STANDOUT* = A_STANDOUT
  WA_UNDERLINE* = A_UNDERLINE
  WA_HORIZONTAL* = A_NORMAL
  WA_LOW* = A_NORMAL
  WA_TOP* = A_NORMAL
  WA_VERTICAL* = A_NORMAL
  COLOR_BLACK* = 0
  COLOR_RED* = 1
  COLOR_GREEN* = 2
  COLOR_BLUE* = 4
  COLOR_CYAN* = (COLOR_BLUE or COLOR_GREEN)
  COLOR_MAGENTA* = (COLOR_RED or COLOR_BLUE)
  COLOR_YELLOW* = (COLOR_RED or COLOR_GREEN)
  COLOR_WHITE* = 7
  KEY_CODE_YES* = 0x00000100  # If get_wch() gives a key code
  KEY_BREAK* = 0x00000101     # Not on PC KBD
  KEY_DOWN* = 0x00000102      # Down arrow key
  KEY_UP* = 0x00000103        # Up arrow key
  KEY_LEFT* = 0x00000104      # Left arrow key
  KEY_RIGHT* = 0x00000105     # Right arrow key
  KEY_HOME* = 0x00000106      # home key
  KEY_BACKSPACE* = 0x00000107 # not on pc
  KEY_F0* = 0x00000108        # function keys; 64 reserved
  KEY_DL* = 0x00000148        # delete line
  KEY_IL* = 0x00000149        # insert line
  KEY_DC* = 0x0000014A        # delete character
  KEY_IC* = 0x0000014B        # insert char or enter ins mode
  KEY_EIC* = 0x0000014C       # exit insert char mode
  KEY_CLEAR* = 0x0000014D     # clear screen
  KEY_EOS* = 0x0000014E       # clear to end of screen
  KEY_EOL* = 0x0000014F       # clear to end of line
  KEY_SF* = 0x00000150        # scroll 1 line forward
  KEY_SR* = 0x00000151        # scroll 1 line back (reverse)
  KEY_NPAGE* = 0x00000152     # next page
  KEY_PPAGE* = 0x00000153     # previous page
  KEY_STAB* = 0x00000154      # set tab
  KEY_CTAB* = 0x00000155      # clear tab
  KEY_CATAB* = 0x00000156     # clear all tabs
  KEY_ENTER* = 0x00000157     # enter or send (unreliable)
  KEY_SRESET* = 0x00000158    # soft/reset (partial/unreliable)
  KEY_RESET* = 0x00000159     # reset/hard reset (unreliable)
  KEY_PRINT* = 0x0000015A     # print/copy
  KEY_LL* = 0x0000015B        # home down/bottom (lower left)
  KEY_ABORT* = 0x0000015C     # abort/terminate key (any)
  KEY_SHELP* = 0x0000015D     # short help
  KEY_LHELP* = 0x0000015E     # long help
  KEY_BTAB* = 0x0000015F      # Back tab key
  KEY_BEG* = 0x00000160       # beg(inning) key
  KEY_CANCEL* = 0x00000161    # cancel key
  KEY_CLOSE* = 0x00000162     # close key
  KEY_COMMAND* = 0x00000163   # cmd (command) key
  KEY_COPY* = 0x00000164      # copy key
  KEY_CREATE* = 0x00000165    # create key
  KEY_END* = 0x00000166       # end key
  KEY_EXIT* = 0x00000167      # exit key
  KEY_FIND* = 0x00000168      # find key
  KEY_HELP* = 0x00000169      # help key
  KEY_MARK* = 0x0000016A      # mark key
  KEY_MESSAGE* = 0x0000016B   # message key
  KEY_MOVE* = 0x0000016C      # move key
  KEY_NEXT* = 0x0000016D      # next object key
  KEY_OPEN* = 0x0000016E      # open key
  KEY_OPTIONS* = 0x0000016F   # options key
  KEY_PREVIOUS* = 0x00000170  # previous object key
  KEY_REDO* = 0x00000171      # redo key
  KEY_REFERENCE* = 0x00000172 # ref(erence) key
  KEY_REFRESH* = 0x00000173   # refresh key
  KEY_REPLACE* = 0x00000174   # replace key
  KEY_RESTART* = 0x00000175   # restart key
  KEY_RESUME* = 0x00000176    # resume key
  KEY_SAVE* = 0x00000177      # save key
  KEY_SBEG* = 0x00000178      # shifted beginning key
  KEY_SCANCEL* = 0x00000179   # shifted cancel key
  KEY_SCOMMAND* = 0x0000017A  # shifted command key
  KEY_SCOPY* = 0x0000017B     # shifted copy key
  KEY_SCREATE* = 0x0000017C   # shifted create key
  KEY_SDC* = 0x0000017D       # shifted delete char key
  KEY_SDL* = 0x0000017E       # shifted delete line key
  KEY_SELECT* = 0x0000017F    # select key
  KEY_SEND* = 0x00000180      # shifted end key
  KEY_SEOL* = 0x00000181      # shifted clear line key
  KEY_SEXIT* = 0x00000182     # shifted exit key
  KEY_SFIND* = 0x00000183     # shifted find key
  KEY_SHOME* = 0x00000184     # shifted home key
  KEY_SIC* = 0x00000185       # shifted input key
  KEY_SLEFT* = 0x00000187     # shifted left arrow key
  KEY_SMESSAGE* = 0x00000188  # shifted message key
  KEY_SMOVE* = 0x00000189     # shifted move key
  KEY_SNEXT* = 0x0000018A     # shifted next key
  KEY_SOPTIONS* = 0x0000018B  # shifted options key
  KEY_SPREVIOUS* = 0x0000018C # shifted prev key
  KEY_SPRINT* = 0x0000018D    # shifted print key
  KEY_SREDO* = 0x0000018E     # shifted redo key
  KEY_SREPLACE* = 0x0000018F  # shifted replace key
  KEY_SRIGHT* = 0x00000190    # shifted right arrow
  KEY_SRSUME* = 0x00000191    # shifted resume key
  KEY_SSAVE* = 0x00000192     # shifted save key
  KEY_SSUSPEND* = 0x00000193  # shifted suspend key
  KEY_SUNDO* = 0x00000194     # shifted undo key
  KEY_SUSPEND* = 0x00000195   # suspend key
  KEY_UNDO* = 0x00000196      # undo key
  ALT_0* = 0x00000197
  ALT_1* = 0x00000198
  ALT_2* = 0x00000199
  ALT_3* = 0x0000019A
  ALT_4* = 0x0000019B
  ALT_5* = 0x0000019C
  ALT_6* = 0x0000019D
  ALT_7* = 0x0000019E
  ALT_8* = 0x0000019F
  ALT_9* = 0x000001A0
  ALT_A* = 0x000001A1
  ALT_B* = 0x000001A2
  ALT_C* = 0x000001A3
  ALT_D* = 0x000001A4
  ALT_E* = 0x000001A5
  ALT_F* = 0x000001A6
  ALT_G* = 0x000001A7
  ALT_H* = 0x000001A8
  ALT_I* = 0x000001A9
  ALT_J* = 0x000001AA
  ALT_K* = 0x000001AB
  ALT_L* = 0x000001AC
  ALT_M* = 0x000001AD
  ALT_N* = 0x000001AE
  ALT_O* = 0x000001AF
  ALT_P* = 0x000001B0
  ALT_Q* = 0x000001B1
  ALT_R* = 0x000001B2
  ALT_S* = 0x000001B3
  ALT_T* = 0x000001B4
  ALT_U* = 0x000001B5
  ALT_V* = 0x000001B6
  ALT_W* = 0x000001B7
  ALT_X* = 0x000001B8
  ALT_Y* = 0x000001B9
  ALT_Z* = 0x000001BA
  CTL_LEFT* = 0x000001BB      # Control-Left-Arrow
  CTL_RIGHT* = 0x000001BC
  CTL_PGUP* = 0x000001BD
  CTL_PGDN* = 0x000001BE
  CTL_HOME* = 0x000001BF
  CTL_END* = 0x000001C0
  KEY_A1* = 0x000001C1        # upper left on Virtual keypad
  KEY_A2* = 0x000001C2        # upper middle on Virt. keypad
  KEY_A3* = 0x000001C3        # upper right on Vir. keypad
  KEY_B1* = 0x000001C4        # middle left on Virt. keypad
  KEY_B2* = 0x000001C5        # center on Virt. keypad
  KEY_B3* = 0x000001C6        # middle right on Vir. keypad
  KEY_C1* = 0x000001C7        # lower left on Virt. keypad
  KEY_C2* = 0x000001C8        # lower middle on Virt. keypad
  KEY_C3* = 0x000001C9        # lower right on Vir. keypad
  PADSLASH* = 0x000001CA      # slash on keypad
  PADENTER* = 0x000001CB      # enter on keypad
  CTL_PADENTER* = 0x000001CC  # ctl-enter on keypad
  ALT_PADENTER* = 0x000001CD  # alt-enter on keypad
  PADSTOP* = 0x000001CE       # stop on keypad
  PADSTAR* = 0x000001CF       # star on keypad
  PADMINUS* = 0x000001D0      # minus on keypad
  PADPLUS* = 0x000001D1       # plus on keypad
  CTL_PADSTOP* = 0x000001D2   # ctl-stop on keypad
  CTL_PADCENTER* = 0x000001D3 # ctl-enter on keypad
  CTL_PADPLUS* = 0x000001D4   # ctl-plus on keypad
  CTL_PADMINUS* = 0x000001D5  # ctl-minus on keypad
  CTL_PADSLASH* = 0x000001D6  # ctl-slash on keypad
  CTL_PADSTAR* = 0x000001D7   # ctl-star on keypad
  ALT_PADPLUS* = 0x000001D8   # alt-plus on keypad
  ALT_PADMINUS* = 0x000001D9  # alt-minus on keypad
  ALT_PADSLASH* = 0x000001DA  # alt-slash on keypad
  ALT_PADSTAR* = 0x000001DB   # alt-star on keypad
  ALT_PADSTOP* = 0x000001DC   # alt-stop on keypad
  CTL_INS* = 0x000001DD       # ctl-insert
  ALT_DEL* = 0x000001DE       # alt-delete
  ALT_INS* = 0x000001DF       # alt-insert
  CTL_UP* = 0x000001E0        # ctl-up arrow
  CTL_DOWN* = 0x000001E1      # ctl-down arrow
  CTL_TAB* = 0x000001E2       # ctl-tab
  ALT_TAB* = 0x000001E3
  ALT_MINUS* = 0x000001E4
  ALT_EQUAL* = 0x000001E5
  ALT_HOME* = 0x000001E6
  ALT_PGUP* = 0x000001E7
  ALT_PGDN* = 0x000001E8
  ALT_END* = 0x000001E9
  ALT_UP* = 0x000001EA        # alt-up arrow
  ALT_DOWN* = 0x000001EB      # alt-down arrow
  ALT_RIGHT* = 0x000001EC     # alt-right arrow
  ALT_LEFT* = 0x000001ED      # alt-left arrow
  ALT_ENTER* = 0x000001EE     # alt-enter
  ALT_ESC* = 0x000001EF       # alt-escape
  ALT_BQUOTE* = 0x000001F0    # alt-back quote
  ALT_LBRACKET* = 0x000001F1  # alt-left bracket
  ALT_RBRACKET* = 0x000001F2  # alt-right bracket
  ALT_SEMICOLON* = 0x000001F3 # alt-semi-colon
  ALT_FQUOTE* = 0x000001F4    # alt-forward quote
  ALT_COMMA* = 0x000001F5     # alt-comma
  ALT_STOP* = 0x000001F6      # alt-stop
  ALT_FSLASH* = 0x000001F7    # alt-forward slash
  ALT_BKSP* = 0x000001F8      # alt-backspace
  CTL_BKSP* = 0x000001F9      # ctl-backspace
  PAD0* = 0x000001FA          # keypad 0
  CTL_PAD0* = 0x000001FB      # ctl-keypad 0
  CTL_PAD1* = 0x000001FC
  CTL_PAD2* = 0x000001FD
  CTL_PAD3* = 0x000001FE
  CTL_PAD4* = 0x000001FF
  CTL_PAD5* = 0x00000200
  CTL_PAD6* = 0x00000201
  CTL_PAD7* = 0x00000202
  CTL_PAD8* = 0x00000203
  CTL_PAD9* = 0x00000204
  ALT_PAD0* = 0x00000205      # alt-keypad 0
  ALT_PAD1* = 0x00000206
  ALT_PAD2* = 0x00000207
  ALT_PAD3* = 0x00000208
  ALT_PAD4* = 0x00000209
  ALT_PAD5* = 0x0000020A
  ALT_PAD6* = 0x0000020B
  ALT_PAD7* = 0x0000020C
  ALT_PAD8* = 0x0000020D
  ALT_PAD9* = 0x0000020E
  CTL_DEL* = 0x0000020F       # clt-delete
  ALT_BSLASH* = 0x00000210    # alt-back slash
  CTL_ENTER* = 0x00000211     # ctl-enter
  SHF_PADENTER* = 0x00000212  # shift-enter on keypad
  SHF_PADSLASH* = 0x00000213  # shift-slash on keypad
  SHF_PADSTAR* = 0x00000214   # shift-star  on keypad
  SHF_PADPLUS* = 0x00000215   # shift-plus  on keypad
  SHF_PADMINUS* = 0x00000216  # shift-minus on keypad
  SHF_UP* = 0x00000217        # shift-up on keypad
  SHF_DOWN* = 0x00000218      # shift-down on keypad
  SHF_IC* = 0x00000219        # shift-insert on keypad
  SHF_DC* = 0x0000021A        # shift-delete on keypad
  KEY_MOUSE* = 0x0000021B     # "mouse" key
  KEY_SHIFT_L* = 0x0000021C   # Left-shift
  KEY_SHIFT_R* = 0x0000021D   # Right-shift
  KEY_CONTROL_L* = 0x0000021E # Left-control
  KEY_CONTROL_R* = 0x0000021F # Right-control
  KEY_ALT_L* = 0x00000220     # Left-alt
  KEY_ALT_R* = 0x00000221     # Right-alt
  KEY_RESIZE* = 0x00000222    # Window resize
  KEY_SUP* = 0x00000223       # Shifted up arrow
  KEY_SDOWN* = 0x00000224     # Shifted down arrow
  KEY_MIN* = KEY_BREAK        # Minimum curses key value
  KEY_MAX* = KEY_SDOWN        # Maximum curses key
  CLIP_SUCCESS* = 0
  CLIP_ACCESS_ERROR* = 1
  CLIP_EMPTY* = 2
  CLIP_MEMORY_ERROR* = 3
  KEY_MODIFIER_SHIFT* = 1
  KEY_MODIFIER_CONTROL* = 2
  KEY_MODIFIER_ALT* = 4
  KEY_MODIFIER_NUMLOCK* = 8

when appType == "gui":
  const
    BUTTON_SHIFT* = BUTTON_MODIFIER_SHIFT
    BUTTON_CONTROL* = BUTTON_MODIFIER_CONTROL
    BUTTON_CTRL* = BUTTON_MODIFIER_CONTROL
    BUTTON_ALT* = BUTTON_MODIFIER_ALT
else:
  const
    BUTTON_SHIFT* = 0x00000008
    BUTTON_CONTROL* = 0x00000010
    BUTTON_ALT* = 0x00000020

type
  TMOUSE_STATUS*{.pure, final.} = object
    x*: cint                  # absolute column, 0 based, measured in characters
    y*: cint                  # absolute row, 0 based, measured in characters
    button*: array[0..3 - 1, cshort] # state of each button
    changes*: cint            # flags indicating what has changed with the mouse

  TMEVENT*{.pure, final.} = object
    id*: cshort               # unused, always 0
    x*: cint
    y*: cint
    z*: cint                  # x, y same as MOUSE_STATUS; z unused
    bstate*: cunsignedlong    # equivalent to changes + button[], but
                              #                           in the same format as used for mousemask()

  TWINDOW*{.pure, final.} = object
    cury*: cint              # current pseudo-cursor
    curx*: cint
    maxy*: cint              # max window coordinates
    maxx*: cint
    begy*: cint              # origin on screen
    begx*: cint
    flags*: cint             # window properties
    attrs*: cunsignedlong    # standard attributes and colors
    bkgd*: cunsignedlong     # background, normally blank
    clear*: cunsignedchar    # causes clear at next refresh
    leaveit*: cunsignedchar  # leaves cursor where it is
    scroll*: cunsignedchar   # allows window scrolling
    nodelay*: cunsignedchar  # input character wait flag
    immed*: cunsignedchar    # immediate update flag
    sync*: cunsignedchar     # synchronise window ancestors
    use_keypad*: cunsignedchar # flags keypad key mode active
    y*: ptr ptr cunsignedlong # pointer to line pointer array
    firstch*: ptr cint       # first changed character in line
    lastch*: ptr cint        # last changed character in line
    tmarg*: cint             # top of scrolling region
    bmarg*: cint             # bottom of scrolling region
    delayms*: cint           # milliseconds of delay for getch()
    parx*: cint
    pary*: cint              # coords relative to parent (0,0)
    parent*: ptr TWINDOW        # subwin's pointer to parent win

  TPANELOBS*{.pure, final.} = object
    above*: ptr TPANELOBS
    pan*: ptr TPANEL

  TPANEL*{.pure, final.} = object
    win*: ptr TWINDOW
    wstarty*: cint
    wendy*: cint
    wstartx*: cint
    wendx*: cint
    below*: ptr TPANEL
    above*: ptr TPANEL
    user*: pointer
    obscure*: ptr TPANELOBS

when unixOS:
  type
    TSCREEN*{.pure, final.} = object
      alive*: cunsignedchar     # if initscr() called, and not endwin()
      autocr*: cunsignedchar    # if cr -> lf
      cbreak*: cunsignedchar    # if terminal unbuffered
      echo*: cunsignedchar      # if terminal echo
      raw_inp*: cunsignedchar   # raw input mode (v. cooked input)
      raw_out*: cunsignedchar   # raw output mode (7 v. 8 bits)
      audible*: cunsignedchar   # FALSE if the bell is visual
      mono*: cunsignedchar      # TRUE if current screen is mono
      resized*: cunsignedchar   # TRUE if TERM has been resized
      orig_attr*: cunsignedchar # TRUE if we have the original colors
      orig_fore*: cshort        # original screen foreground color
      orig_back*: cshort        # original screen foreground color
      cursrow*: cint            # position of physical cursor
      curscol*: cint            # position of physical cursor
      visibility*: cint         # visibility of cursor
      orig_cursor*: cint        # original cursor size
      lines*: cint              # new value for LINES
      cols*: cint               # new value for COLS
      trap_mbe*: cunsignedlong # trap these mouse button events
      map_mbe_to_key*: cunsignedlong # map mouse buttons to slk
      mouse_wait*: cint # time to wait (in ms) for a button release after a press
      slklines*: cint           # lines in use by slk_init()
      slk_winptr*: ptr TWINDOW   # window for slk
      linesrippedoff*: cint     # lines ripped off via ripoffline()
      linesrippedoffontop*: cint # lines ripped off on top via ripoffline()
      delaytenths*: cint        # 1/10ths second to wait block getch() for
      preserve*: cunsignedchar # TRUE if screen background to be preserved
      restore*: cint           # specifies if screen background to be restored, and how
      save_key_modifiers*: cunsignedchar # TRUE if each key modifiers saved with each key press
      return_key_modifiers*: cunsignedchar # TRUE if modifier keys are returned as "real" keys
      key_code*: cunsignedchar # TRUE if last key is a special key;
      XcurscrSize*: cint        # size of Xcurscr shared memory block
      sb_on*: cunsignedchar
      sb_viewport_y*: cint
      sb_viewport_x*: cint
      sb_total_y*: cint
      sb_total_x*: cint
      sb_cur_y*: cint
      sb_cur_x*: cint
      line_color*: cshort       # color of line attributes - default -1
else:
  type
    TSCREEN*{.pure, final.} = object
      alive*: cunsignedchar     # if initscr() called, and not endwin()
      autocr*: cunsignedchar    # if cr -> lf
      cbreak*: cunsignedchar    # if terminal unbuffered
      echo*: cunsignedchar      # if terminal echo
      raw_inp*: cunsignedchar   # raw input mode (v. cooked input)
      raw_out*: cunsignedchar   # raw output mode (7 v. 8 bits)
      audible*: cunsignedchar   # FALSE if the bell is visual
      mono*: cunsignedchar      # TRUE if current screen is mono
      resized*: cunsignedchar   # TRUE if TERM has been resized
      orig_attr*: cunsignedchar # TRUE if we have the original colors
      orig_fore*: cshort        # original screen foreground color
      orig_back*: cshort        # original screen foreground color
      cursrow*: cint            # position of physical cursor
      curscol*: cint            # position of physical cursor
      visibility*: cint         # visibility of cursor
      orig_cursor*: cint        # original cursor size
      lines*: cint              # new value for LINES
      cols*: cint               # new value for COLS
      trap_mbe*: cunsignedlong # trap these mouse button events
      map_mbe_to_key*: cunsignedlong # map mouse buttons to slk
      mouse_wait*: cint # time to wait (in ms) for a button release after a press
      slklines*: cint           # lines in use by slk_init()
      slk_winptr*: ptr TWINDOW   # window for slk
      linesrippedoff*: cint     # lines ripped off via ripoffline()
      linesrippedoffontop*: cint # lines ripped off on top via ripoffline()
      delaytenths*: cint        # 1/10ths second to wait block getch() for
      preserve*: cunsignedchar # TRUE if screen background to be preserved
      restore*: cint           # specifies if screen background to be restored, and how
      save_key_modifiers*: cunsignedchar # TRUE if each key modifiers saved with each key press
      return_key_modifiers*: cunsignedchar # TRUE if modifier keys are returned as "real" keys
      key_code*: cunsignedchar # TRUE if last key is a special key;
      line_color*: cshort       # color of line attributes - default -1

var
  LINES*{.importc: "LINES", dynlib: pdcursesdll.}: cint
  COLS*{.importc: "COLS", dynlib: pdcursesdll.}: cint
  stdscr*{.importc: "stdscr", dynlib: pdcursesdll.}: ptr TWINDOW
  curscr*{.importc: "curscr", dynlib: pdcursesdll.}: ptr TWINDOW
  SP*{.importc: "SP", dynlib: pdcursesdll.}: ptr TSCREEN
  Mouse_status*{.importc: "Mouse_status", dynlib: pdcursesdll.}: TMOUSE_STATUS
  COLORS*{.importc: "COLORS", dynlib: pdcursesdll.}: cint
  COLOR_PAIRS*{.importc: "COLOR_PAIRS", dynlib: pdcursesdll.}: cint
  TABSIZE*{.importc: "TABSIZE", dynlib: pdcursesdll.}: cint
  acs_map*{.importc: "acs_map", dynlib: pdcursesdll.}: ptr cunsignedlong
  ttytype*{.importc: "ttytype", dynlib: pdcursesdll.}: cstring

template BUTTON_CHANGED*(x: expr): expr =
  (Mouse_status.changes and (1 shl ((x) - 1)))

template BUTTON_STATUS*(x: expr): expr =
  (Mouse_status.button[(x) - 1])

template ACS_PICK*(w, n: expr): expr =
  (cast[int32](w) or A_ALTCHARSET)

template KEY_F*(n: expr): expr =
  (KEY_F0 + (n))

template COLOR_PAIR*(n: expr): expr =
  ((cast[cunsignedlong]((n)) shl COLOR_SHIFT) and A_COLOR)

template PAIR_NUMBER*(n: expr): expr =
  (((n) and A_COLOR) shr COLOR_SHIFT)

const
  #MOUSE_X_POS* = (Mouse_status.x)
  #MOUSE_Y_POS* = (Mouse_status.y)
  #A_BUTTON_CHANGED* = (Mouse_status.changes and 7)
  #MOUSE_MOVED* = (Mouse_status.changes and MOUSE_MOVED)
  #MOUSE_POS_REPORT* = (Mouse_status.changes and MOUSE_POSITION)
  #MOUSE_WHEEL_UP* = (Mouse_status.changes and MOUSE_WHEEL_UP)
  #MOUSE_WHEEL_DOWN* = (Mouse_status.changes and MOUSE_WHEEL_DOWN)
  ACS_ULCORNER* = ACS_PICK('l', '+')
  ACS_LLCORNER* = ACS_PICK('m', '+')
  ACS_URCORNER* = ACS_PICK('k', '+')
  ACS_LRCORNER* = ACS_PICK('j', '+')
  ACS_RTEE* = ACS_PICK('u', '+')
  ACS_LTEE* = ACS_PICK('t', '+')
  ACS_BTEE* = ACS_PICK('v', '+')
  ACS_TTEE* = ACS_PICK('w', '+')
  ACS_HLINE* = ACS_PICK('q', '-')
  ACS_VLINE* = ACS_PICK('x', '|')
  ACS_PLUS* = ACS_PICK('n', '+')
  ACS_S1* = ACS_PICK('o', '-')
  ACS_S9* = ACS_PICK('s', '_')
  ACS_DIAMOND* = ACS_PICK('`', '+')
  ACS_CKBOARD* = ACS_PICK('a', ':')
  ACS_DEGREE* = ACS_PICK('f', '\'')
  ACS_PLMINUS* = ACS_PICK('g', '#')
  ACS_BULLET* = ACS_PICK('~', 'o')
  ACS_LARROW* = ACS_PICK(',', '<')
  ACS_RARROW* = ACS_PICK('+', '>')
  ACS_DARROW* = ACS_PICK('.', 'v')
  ACS_UARROW* = ACS_PICK('-', '^')
  ACS_BOARD* = ACS_PICK('h', '#')
  ACS_LANTERN* = ACS_PICK('i', '*')
  ACS_BLOCK* = ACS_PICK('0', '#')
  ACS_S3* = ACS_PICK('p', '-')
  ACS_S7* = ACS_PICK('r', '-')
  ACS_LEQUAL* = ACS_PICK('y', '<')
  ACS_GEQUAL* = ACS_PICK('z', '>')
  ACS_PI* = ACS_PICK('{', 'n')
  ACS_NEQUAL* = ACS_PICK('|', '+')
  ACS_STERLING* = ACS_PICK('}', 'L')
  ACS_BSSB* = ACS_ULCORNER
  ACS_SSBB* = ACS_LLCORNER
  ACS_BBSS* = ACS_URCORNER
  ACS_SBBS* = ACS_LRCORNER
  ACS_SBSS* = ACS_RTEE
  ACS_SSSB* = ACS_LTEE
  ACS_SSBS* = ACS_BTEE
  ACS_BSSS* = ACS_TTEE
  ACS_BSBS* = ACS_HLINE
  ACS_SBSB* = ACS_VLINE
  ACS_SSSS* = ACS_PLUS
discard """WACS_ULCORNER* = (addr((acs_map['l'])))
  WACS_LLCORNER* = (addr((acs_map['m'])))
  WACS_URCORNER* = (addr((acs_map['k'])))
  WACS_LRCORNER* = (addr((acs_map['j'])))
  WACS_RTEE* = (addr((acs_map['u'])))
  WACS_LTEE* = (addr((acs_map['t'])))
  WACS_BTEE* = (addr((acs_map['v'])))
  WACS_TTEE* = (addr((acs_map['w'])))
  WACS_HLINE* = (addr((acs_map['q'])))
  WACS_VLINE* = (addr((acs_map['x'])))
  WACS_PLUS* = (addr((acs_map['n'])))
  WACS_S1* = (addr((acs_map['o'])))
  WACS_S9* = (addr((acs_map['s'])))
  WACS_DIAMOND* = (addr((acs_map['`'])))
  WACS_CKBOARD* = (addr((acs_map['a'])))
  WACS_DEGREE* = (addr((acs_map['f'])))
  WACS_PLMINUS* = (addr((acs_map['g'])))
  WACS_BULLET* = (addr((acs_map['~'])))
  WACS_LARROW* = (addr((acs_map[','])))
  WACS_RARROW* = (addr((acs_map['+'])))
  WACS_DARROW* = (addr((acs_map['.'])))
  WACS_UARROW* = (addr((acs_map['-'])))
  WACS_BOARD* = (addr((acs_map['h'])))
  WACS_LANTERN* = (addr((acs_map['i'])))
  WACS_BLOCK* = (addr((acs_map['0'])))
  WACS_S3* = (addr((acs_map['p'])))
  WACS_S7* = (addr((acs_map['r'])))
  WACS_LEQUAL* = (addr((acs_map['y'])))
  WACS_GEQUAL* = (addr((acs_map['z'])))
  WACS_PI* = (addr((acs_map['{'])))
  WACS_NEQUAL* = (addr((acs_map['|'])))
  WACS_STERLING* = (addr((acs_map['}'])))
  WACS_BSSB* = WACS_ULCORNER
  WACS_SSBB* = WACS_LLCORNER
  WACS_BBSS* = WACS_URCORNER
  WACS_SBBS* = WACS_LRCORNER
  WACS_SBSS* = WACS_RTEE
  WACS_SSSB* = WACS_LTEE
  WACS_SSBS* = WACS_BTEE
  WACS_BSSS* = WACS_TTEE
  WACS_BSBS* = WACS_HLINE
  WACS_SBSB* = WACS_VLINE
  WACS_SSSS* = WACS_PLUS"""

proc addch*(a2: cunsignedlong): cint{.extdecl, importc: "addch",
                                      dynlib: pdcursesdll.}
proc addchnstr*(a2: ptr cunsignedlong; a3: cint): cint{.extdecl,
    importc: "addchnstr", dynlib: pdcursesdll.}
proc addchstr*(a2: ptr cunsignedlong): cint{.extdecl, importc: "addchstr",
    dynlib: pdcursesdll.}
proc addnstr*(a2: cstring; a3: cint): cint{.extdecl, importc: "addnstr",
    dynlib: pdcursesdll.}
proc addstr*(a2: cstring): cint{.extdecl, importc: "addstr", dynlib: pdcursesdll.}
proc attroff*(a2: cunsignedlong): cint{.extdecl, importc: "attroff",
                                        dynlib: pdcursesdll.}
proc attron*(a2: cunsignedlong): cint{.extdecl, importc: "attron",
                                       dynlib: pdcursesdll.}
proc attrset*(a2: cunsignedlong): cint{.extdecl, importc: "attrset",
                                        dynlib: pdcursesdll.}
proc attr_get*(a2: ptr cunsignedlong; a3: ptr cshort; a4: pointer): cint{.extdecl,
    importc: "attr_get", dynlib: pdcursesdll.}
proc attr_off*(a2: cunsignedlong; a3: pointer): cint{.extdecl,
    importc: "attr_off", dynlib: pdcursesdll.}
proc attr_on*(a2: cunsignedlong; a3: pointer): cint{.extdecl, importc: "attr_on",
    dynlib: pdcursesdll.}
proc attr_set*(a2: cunsignedlong; a3: cshort; a4: pointer): cint{.extdecl,
    importc: "attr_set", dynlib: pdcursesdll.}
proc baudrate*(): cint{.extdecl, importc: "baudrate", dynlib: pdcursesdll.}
proc beep*(): cint{.extdecl, importc: "beep", dynlib: pdcursesdll.}
proc bkgd*(a2: cunsignedlong): cint{.extdecl, importc: "bkgd", dynlib: pdcursesdll.}
proc bkgdset*(a2: cunsignedlong){.extdecl, importc: "bkgdset", dynlib: pdcursesdll.}
proc border*(a2: cunsignedlong; a3: cunsignedlong; a4: cunsignedlong;
             a5: cunsignedlong; a6: cunsignedlong; a7: cunsignedlong;
             a8: cunsignedlong; a9: cunsignedlong): cint{.extdecl,
    importc: "border", dynlib: pdcursesdll.}
proc box*(a2: ptr TWINDOW; a3: cunsignedlong; a4: cunsignedlong): cint{.extdecl,
    importc: "box", dynlib: pdcursesdll.}
proc can_change_color*(): cunsignedchar{.extdecl, importc: "can_change_color",
    dynlib: pdcursesdll.}
proc cbreak*(): cint{.extdecl, importc: "cbreak", dynlib: pdcursesdll.}
proc chgat*(a2: cint; a3: cunsignedlong; a4: cshort; a5: pointer): cint{.extdecl,
    importc: "chgat", dynlib: pdcursesdll.}
proc clearok*(a2: ptr TWINDOW; a3: cunsignedchar): cint{.extdecl,
    importc: "clearok", dynlib: pdcursesdll.}
proc clear*(): cint{.extdecl, importc: "clear", dynlib: pdcursesdll.}
proc clrtobot*(): cint{.extdecl, importc: "clrtobot", dynlib: pdcursesdll.}
proc clrtoeol*(): cint{.extdecl, importc: "clrtoeol", dynlib: pdcursesdll.}
proc color_content*(a2: cshort; a3: ptr cshort; a4: ptr cshort; a5: ptr cshort): cint{.
    extdecl, importc: "color_content", dynlib: pdcursesdll.}
proc color_set*(a2: cshort; a3: pointer): cint{.extdecl, importc: "color_set",
    dynlib: pdcursesdll.}
proc copywin*(a2: ptr TWINDOW; a3: ptr TWINDOW; a4: cint; a5: cint; a6: cint;
              a7: cint; a8: cint; a9: cint; a10: cint): cint{.extdecl,
    importc: "copywin", dynlib: pdcursesdll.}
proc curs_set*(a2: cint): cint{.extdecl, importc: "curs_set", dynlib: pdcursesdll.}
proc def_prog_mode*(): cint{.extdecl, importc: "def_prog_mode",
                             dynlib: pdcursesdll.}
proc def_shell_mode*(): cint{.extdecl, importc: "def_shell_mode",
                              dynlib: pdcursesdll.}
proc delay_output*(a2: cint): cint{.extdecl, importc: "delay_output",
                                    dynlib: pdcursesdll.}
proc delch*(): cint{.extdecl, importc: "delch", dynlib: pdcursesdll.}
proc deleteln*(): cint{.extdecl, importc: "deleteln", dynlib: pdcursesdll.}
proc delscreen*(a2: ptr TSCREEN){.extdecl, importc: "delscreen",
                                 dynlib: pdcursesdll.}
proc delwin*(a2: ptr TWINDOW): cint{.extdecl, importc: "delwin",
                                    dynlib: pdcursesdll.}
proc derwin*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cint; a6: cint): ptr TWINDOW{.
    extdecl, importc: "derwin", dynlib: pdcursesdll.}
proc doupdate*(): cint{.extdecl, importc: "doupdate", dynlib: pdcursesdll.}
proc dupwin*(a2: ptr TWINDOW): ptr TWINDOW{.extdecl, importc: "dupwin",
    dynlib: pdcursesdll.}
proc echochar*(a2: cunsignedlong): cint{.extdecl, importc: "echochar",
    dynlib: pdcursesdll.}
proc echo*(): cint{.extdecl, importc: "echo", dynlib: pdcursesdll.}
proc endwin*(): cint{.extdecl, importc: "endwin", dynlib: pdcursesdll.}
proc erasechar*(): char{.extdecl, importc: "erasechar", dynlib: pdcursesdll.}
proc erase*(): cint{.extdecl, importc: "erase", dynlib: pdcursesdll.}
proc filter*(){.extdecl, importc: "filter", dynlib: pdcursesdll.}
proc flash*(): cint{.extdecl, importc: "flash", dynlib: pdcursesdll.}
proc flushinp*(): cint{.extdecl, importc: "flushinp", dynlib: pdcursesdll.}
proc getbkgd*(a2: ptr TWINDOW): cunsignedlong{.extdecl, importc: "getbkgd",
    dynlib: pdcursesdll.}
proc getnstr*(a2: cstring; a3: cint): cint{.extdecl, importc: "getnstr",
    dynlib: pdcursesdll.}
proc getstr*(a2: cstring): cint{.extdecl, importc: "getstr", dynlib: pdcursesdll.}
proc getwin*(a2: TFile): ptr TWINDOW{.extdecl, importc: "getwin",
                                        dynlib: pdcursesdll.}
proc halfdelay*(a2: cint): cint{.extdecl, importc: "halfdelay",
                                 dynlib: pdcursesdll.}
proc has_colors*(): cunsignedchar{.extdecl, importc: "has_colors",
                                   dynlib: pdcursesdll.}
proc has_ic*(): cunsignedchar{.extdecl, importc: "has_ic", dynlib: pdcursesdll.}
proc has_il*(): cunsignedchar{.extdecl, importc: "has_il", dynlib: pdcursesdll.}
proc hline*(a2: cunsignedlong; a3: cint): cint{.extdecl, importc: "hline",
    dynlib: pdcursesdll.}
proc idcok*(a2: ptr TWINDOW; a3: cunsignedchar){.extdecl, importc: "idcok",
    dynlib: pdcursesdll.}
proc idlok*(a2: ptr TWINDOW; a3: cunsignedchar): cint{.extdecl, importc: "idlok",
    dynlib: pdcursesdll.}
proc immedok*(a2: ptr TWINDOW; a3: cunsignedchar){.extdecl, importc: "immedok",
    dynlib: pdcursesdll.}
proc inchnstr*(a2: ptr cunsignedlong; a3: cint): cint{.extdecl,
    importc: "inchnstr", dynlib: pdcursesdll.}
proc inchstr*(a2: ptr cunsignedlong): cint{.extdecl, importc: "inchstr",
    dynlib: pdcursesdll.}
proc inch*(): cunsignedlong{.extdecl, importc: "inch", dynlib: pdcursesdll.}
proc init_color*(a2: cshort; a3: cshort; a4: cshort; a5: cshort): cint{.extdecl,
    importc: "init_color", dynlib: pdcursesdll.}
proc init_pair*(a2: cshort; a3: cshort; a4: cshort): cint{.extdecl,
    importc: "init_pair", dynlib: pdcursesdll.}
proc initscr*(): ptr TWINDOW{.extdecl, importc: "initscr", dynlib: pdcursesdll.}
proc innstr*(a2: cstring; a3: cint): cint{.extdecl, importc: "innstr",
    dynlib: pdcursesdll.}
proc insch*(a2: cunsignedlong): cint{.extdecl, importc: "insch",
                                      dynlib: pdcursesdll.}
proc insdelln*(a2: cint): cint{.extdecl, importc: "insdelln", dynlib: pdcursesdll.}
proc insertln*(): cint{.extdecl, importc: "insertln", dynlib: pdcursesdll.}
proc insnstr*(a2: cstring; a3: cint): cint{.extdecl, importc: "insnstr",
    dynlib: pdcursesdll.}
proc insstr*(a2: cstring): cint{.extdecl, importc: "insstr", dynlib: pdcursesdll.}
proc instr*(a2: cstring): cint{.extdecl, importc: "instr", dynlib: pdcursesdll.}
proc intrflush*(a2: ptr TWINDOW; a3: cunsignedchar): cint{.extdecl,
    importc: "intrflush", dynlib: pdcursesdll.}
proc isendwin*(): cunsignedchar{.extdecl, importc: "isendwin", dynlib: pdcursesdll.}
proc is_linetouched*(a2: ptr TWINDOW; a3: cint): cunsignedchar{.extdecl,
    importc: "is_linetouched", dynlib: pdcursesdll.}
proc is_wintouched*(a2: ptr TWINDOW): cunsignedchar{.extdecl,
    importc: "is_wintouched", dynlib: pdcursesdll.}
proc keyname*(a2: cint): cstring{.extdecl, importc: "keyname", dynlib: pdcursesdll.}
proc keypad*(a2: ptr TWINDOW; a3: cunsignedchar): cint{.extdecl, importc: "keypad",
    dynlib: pdcursesdll.}
proc killchar*(): char{.extdecl, importc: "killchar", dynlib: pdcursesdll.}
proc leaveok*(a2: ptr TWINDOW; a3: cunsignedchar): cint{.extdecl,
    importc: "leaveok", dynlib: pdcursesdll.}
proc longname*(): cstring{.extdecl, importc: "longname", dynlib: pdcursesdll.}
proc meta*(a2: ptr TWINDOW; a3: cunsignedchar): cint{.extdecl, importc: "meta",
    dynlib: pdcursesdll.}
proc move*(a2: cint; a3: cint): cint{.extdecl, importc: "move",
                                      dynlib: pdcursesdll.}
proc mvaddch*(a2: cint; a3: cint; a4: cunsignedlong): cint{.extdecl,
    importc: "mvaddch", dynlib: pdcursesdll.}
proc mvaddchnstr*(a2: cint; a3: cint; a4: ptr cunsignedlong; a5: cint): cint{.
    extdecl, importc: "mvaddchnstr", dynlib: pdcursesdll.}
proc mvaddchstr*(a2: cint; a3: cint; a4: ptr cunsignedlong): cint{.extdecl,
    importc: "mvaddchstr", dynlib: pdcursesdll.}
proc mvaddnstr*(a2: cint; a3: cint; a4: cstring; a5: cint): cint{.extdecl,
    importc: "mvaddnstr", dynlib: pdcursesdll.}
proc mvaddstr*(a2: cint; a3: cint; a4: cstring): cint{.extdecl,
    importc: "mvaddstr", dynlib: pdcursesdll.}
proc mvchgat*(a2: cint; a3: cint; a4: cint; a5: cunsignedlong; a6: cshort;
              a7: pointer): cint{.extdecl, importc: "mvchgat", dynlib: pdcursesdll.}
proc mvcur*(a2: cint; a3: cint; a4: cint; a5: cint): cint{.extdecl,
    importc: "mvcur", dynlib: pdcursesdll.}
proc mvdelch*(a2: cint; a3: cint): cint{.extdecl, importc: "mvdelch",
    dynlib: pdcursesdll.}
proc mvderwin*(a2: ptr TWINDOW; a3: cint; a4: cint): cint{.extdecl,
    importc: "mvderwin", dynlib: pdcursesdll.}
proc mvgetch*(a2: cint; a3: cint): cint{.extdecl, importc: "mvgetch",
    dynlib: pdcursesdll.}
proc mvgetnstr*(a2: cint; a3: cint; a4: cstring; a5: cint): cint{.extdecl,
    importc: "mvgetnstr", dynlib: pdcursesdll.}
proc mvgetstr*(a2: cint; a3: cint; a4: cstring): cint{.extdecl,
    importc: "mvgetstr", dynlib: pdcursesdll.}
proc mvhline*(a2: cint; a3: cint; a4: cunsignedlong; a5: cint): cint{.extdecl,
    importc: "mvhline", dynlib: pdcursesdll.}
proc mvinch*(a2: cint; a3: cint): cunsignedlong{.extdecl, importc: "mvinch",
    dynlib: pdcursesdll.}
proc mvinchnstr*(a2: cint; a3: cint; a4: ptr cunsignedlong; a5: cint): cint{.
    extdecl, importc: "mvinchnstr", dynlib: pdcursesdll.}
proc mvinchstr*(a2: cint; a3: cint; a4: ptr cunsignedlong): cint{.extdecl,
    importc: "mvinchstr", dynlib: pdcursesdll.}
proc mvinnstr*(a2: cint; a3: cint; a4: cstring; a5: cint): cint{.extdecl,
    importc: "mvinnstr", dynlib: pdcursesdll.}
proc mvinsch*(a2: cint; a3: cint; a4: cunsignedlong): cint{.extdecl,
    importc: "mvinsch", dynlib: pdcursesdll.}
proc mvinsnstr*(a2: cint; a3: cint; a4: cstring; a5: cint): cint{.extdecl,
    importc: "mvinsnstr", dynlib: pdcursesdll.}
proc mvinsstr*(a2: cint; a3: cint; a4: cstring): cint{.extdecl,
    importc: "mvinsstr", dynlib: pdcursesdll.}
proc mvinstr*(a2: cint; a3: cint; a4: cstring): cint{.extdecl, importc: "mvinstr",
    dynlib: pdcursesdll.}
proc mvprintw*(a2: cint; a3: cint; a4: cstring): cint{.varargs, extdecl,
    importc: "mvprintw", dynlib: pdcursesdll.}
proc mvscanw*(a2: cint; a3: cint; a4: cstring): cint{.varargs, extdecl,
    importc: "mvscanw", dynlib: pdcursesdll.}
proc mvvline*(a2: cint; a3: cint; a4: cunsignedlong; a5: cint): cint{.extdecl,
    importc: "mvvline", dynlib: pdcursesdll.}
proc mvwaddchnstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong;
                   a6: cint): cint{.extdecl, importc: "mvwaddchnstr",
                                    dynlib: pdcursesdll.}
proc mvwaddchstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong): cint{.
    extdecl, importc: "mvwaddchstr", dynlib: pdcursesdll.}
proc mvwaddch*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cunsignedlong): cint{.
    extdecl, importc: "mvwaddch", dynlib: pdcursesdll.}
proc mvwaddnstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring; a6: cint): cint{.
    extdecl, importc: "mvwaddnstr", dynlib: pdcursesdll.}
proc mvwaddstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring): cint{.extdecl,
    importc: "mvwaddstr", dynlib: pdcursesdll.}
proc mvwchgat*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cint; a6: cunsignedlong;
               a7: cshort; a8: pointer): cint{.extdecl, importc: "mvwchgat",
    dynlib: pdcursesdll.}
proc mvwdelch*(a2: ptr TWINDOW; a3: cint; a4: cint): cint{.extdecl,
    importc: "mvwdelch", dynlib: pdcursesdll.}
proc mvwgetch*(a2: ptr TWINDOW; a3: cint; a4: cint): cint{.extdecl,
    importc: "mvwgetch", dynlib: pdcursesdll.}
proc mvwgetnstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring; a6: cint): cint{.
    extdecl, importc: "mvwgetnstr", dynlib: pdcursesdll.}
proc mvwgetstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring): cint{.extdecl,
    importc: "mvwgetstr", dynlib: pdcursesdll.}
proc mvwhline*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cunsignedlong; a6: cint): cint{.
    extdecl, importc: "mvwhline", dynlib: pdcursesdll.}
proc mvwinchnstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong;
                  a6: cint): cint{.extdecl, importc: "mvwinchnstr",
                                   dynlib: pdcursesdll.}
proc mvwinchstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong): cint{.
    extdecl, importc: "mvwinchstr", dynlib: pdcursesdll.}
proc mvwinch*(a2: ptr TWINDOW; a3: cint; a4: cint): cunsignedlong{.extdecl,
    importc: "mvwinch", dynlib: pdcursesdll.}
proc mvwinnstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring; a6: cint): cint{.
    extdecl, importc: "mvwinnstr", dynlib: pdcursesdll.}
proc mvwinsch*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cunsignedlong): cint{.
    extdecl, importc: "mvwinsch", dynlib: pdcursesdll.}
proc mvwinsnstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring; a6: cint): cint{.
    extdecl, importc: "mvwinsnstr", dynlib: pdcursesdll.}
proc mvwinsstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring): cint{.extdecl,
    importc: "mvwinsstr", dynlib: pdcursesdll.}
proc mvwinstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring): cint{.extdecl,
    importc: "mvwinstr", dynlib: pdcursesdll.}
proc mvwin*(a2: ptr TWINDOW; a3: cint; a4: cint): cint{.extdecl, importc: "mvwin",
    dynlib: pdcursesdll.}
proc mvwprintw*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring): cint{.varargs,
    extdecl, importc: "mvwprintw", dynlib: pdcursesdll.}
proc mvwscanw*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring): cint{.varargs,
    extdecl, importc: "mvwscanw", dynlib: pdcursesdll.}
proc mvwvline*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cunsignedlong; a6: cint): cint{.
    extdecl, importc: "mvwvline", dynlib: pdcursesdll.}
proc napms*(a2: cint): cint{.extdecl, importc: "napms", dynlib: pdcursesdll.}
proc newpad*(a2: cint; a3: cint): ptr TWINDOW{.extdecl, importc: "newpad",
    dynlib: pdcursesdll.}
proc newterm*(a2: cstring; a3: TFile; a4: TFile): ptr TSCREEN{.extdecl,
    importc: "newterm", dynlib: pdcursesdll.}
proc newwin*(a2: cint; a3: cint; a4: cint; a5: cint): ptr TWINDOW{.extdecl,
    importc: "newwin", dynlib: pdcursesdll.}
proc nl*(): cint{.extdecl, importc: "nl", dynlib: pdcursesdll.}
proc nocbreak*(): cint{.extdecl, importc: "nocbreak", dynlib: pdcursesdll.}
proc nodelay*(a2: ptr TWINDOW; a3: cunsignedchar): cint{.extdecl,
    importc: "nodelay", dynlib: pdcursesdll.}
proc noecho*(): cint{.extdecl, importc: "noecho", dynlib: pdcursesdll.}
proc nonl*(): cint{.extdecl, importc: "nonl", dynlib: pdcursesdll.}
proc noqiflush*(){.extdecl, importc: "noqiflush", dynlib: pdcursesdll.}
proc noraw*(): cint{.extdecl, importc: "noraw", dynlib: pdcursesdll.}
proc notimeout*(a2: ptr TWINDOW; a3: cunsignedchar): cint{.extdecl,
    importc: "notimeout", dynlib: pdcursesdll.}
proc overlay*(a2: ptr TWINDOW; a3: ptr TWINDOW): cint{.extdecl, importc: "overlay",
    dynlib: pdcursesdll.}
proc overwrite*(a2: ptr TWINDOW; a3: ptr TWINDOW): cint{.extdecl,
    importc: "overwrite", dynlib: pdcursesdll.}
proc pair_content*(a2: cshort; a3: ptr cshort; a4: ptr cshort): cint{.extdecl,
    importc: "pair_content", dynlib: pdcursesdll.}
proc pechochar*(a2: ptr TWINDOW; a3: cunsignedlong): cint{.extdecl,
    importc: "pechochar", dynlib: pdcursesdll.}
proc pnoutrefresh*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cint; a6: cint;
                   a7: cint; a8: cint): cint{.extdecl, importc: "pnoutrefresh",
    dynlib: pdcursesdll.}
proc prefresh*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cint; a6: cint; a7: cint;
               a8: cint): cint{.extdecl, importc: "prefresh", dynlib: pdcursesdll.}
proc printw*(a2: cstring): cint{.varargs, extdecl, importc: "printw",
                                 dynlib: pdcursesdll.}
proc putwin*(a2: ptr TWINDOW; a3: TFile): cint{.extdecl, importc: "putwin",
    dynlib: pdcursesdll.}
proc qiflush*(){.extdecl, importc: "qiflush", dynlib: pdcursesdll.}
proc raw*(): cint{.extdecl, importc: "raw", dynlib: pdcursesdll.}
proc redrawwin*(a2: ptr TWINDOW): cint{.extdecl, importc: "redrawwin",
                                       dynlib: pdcursesdll.}
proc refresh*(): cint{.extdecl, importc: "refresh", dynlib: pdcursesdll.}
proc reset_prog_mode*(): cint{.extdecl, importc: "reset_prog_mode",
                               dynlib: pdcursesdll.}
proc reset_shell_mode*(): cint{.extdecl, importc: "reset_shell_mode",
                                dynlib: pdcursesdll.}
proc resetty*(): cint{.extdecl, importc: "resetty", dynlib: pdcursesdll.}
#int     ripoffline(int, int (*)(TWINDOW *, int));
proc savetty*(): cint{.extdecl, importc: "savetty", dynlib: pdcursesdll.}
proc scanw*(a2: cstring): cint{.varargs, extdecl, importc: "scanw",
                                dynlib: pdcursesdll.}
proc scr_dump*(a2: cstring): cint{.extdecl, importc: "scr_dump",
                                   dynlib: pdcursesdll.}
proc scr_init*(a2: cstring): cint{.extdecl, importc: "scr_init",
                                   dynlib: pdcursesdll.}
proc scr_restore*(a2: cstring): cint{.extdecl, importc: "scr_restore",
                                      dynlib: pdcursesdll.}
proc scr_set*(a2: cstring): cint{.extdecl, importc: "scr_set", dynlib: pdcursesdll.}
proc scrl*(a2: cint): cint{.extdecl, importc: "scrl", dynlib: pdcursesdll.}
proc scroll*(a2: ptr TWINDOW): cint{.extdecl, importc: "scroll",
                                    dynlib: pdcursesdll.}
proc scrollok*(a2: ptr TWINDOW; a3: cunsignedchar): cint{.extdecl,
    importc: "scrollok", dynlib: pdcursesdll.}
proc set_term*(a2: ptr TSCREEN): ptr TSCREEN{.extdecl, importc: "set_term",
    dynlib: pdcursesdll.}
proc setscrreg*(a2: cint; a3: cint): cint{.extdecl, importc: "setscrreg",
    dynlib: pdcursesdll.}
proc slk_attroff*(a2: cunsignedlong): cint{.extdecl, importc: "slk_attroff",
    dynlib: pdcursesdll.}
proc slk_attr_off*(a2: cunsignedlong; a3: pointer): cint{.extdecl,
    importc: "slk_attr_off", dynlib: pdcursesdll.}
proc slk_attron*(a2: cunsignedlong): cint{.extdecl, importc: "slk_attron",
    dynlib: pdcursesdll.}
proc slk_attr_on*(a2: cunsignedlong; a3: pointer): cint{.extdecl,
    importc: "slk_attr_on", dynlib: pdcursesdll.}
proc slk_attrset*(a2: cunsignedlong): cint{.extdecl, importc: "slk_attrset",
    dynlib: pdcursesdll.}
proc slk_attr_set*(a2: cunsignedlong; a3: cshort; a4: pointer): cint{.extdecl,
    importc: "slk_attr_set", dynlib: pdcursesdll.}
proc slk_clear*(): cint{.extdecl, importc: "slk_clear", dynlib: pdcursesdll.}
proc slk_color*(a2: cshort): cint{.extdecl, importc: "slk_color",
                                   dynlib: pdcursesdll.}
proc slk_init*(a2: cint): cint{.extdecl, importc: "slk_init", dynlib: pdcursesdll.}
proc slk_label*(a2: cint): cstring{.extdecl, importc: "slk_label",
                                    dynlib: pdcursesdll.}
proc slk_noutrefresh*(): cint{.extdecl, importc: "slk_noutrefresh",
                               dynlib: pdcursesdll.}
proc slk_refresh*(): cint{.extdecl, importc: "slk_refresh", dynlib: pdcursesdll.}
proc slk_restore*(): cint{.extdecl, importc: "slk_restore", dynlib: pdcursesdll.}
proc slk_set*(a2: cint; a3: cstring; a4: cint): cint{.extdecl, importc: "slk_set",
    dynlib: pdcursesdll.}
proc slk_touch*(): cint{.extdecl, importc: "slk_touch", dynlib: pdcursesdll.}
proc standend*(): cint{.extdecl, importc: "standend", dynlib: pdcursesdll.}
proc standout*(): cint{.extdecl, importc: "standout", dynlib: pdcursesdll.}
proc start_color*(): cint{.extdecl, importc: "start_color", dynlib: pdcursesdll.}
proc subpad*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cint; a6: cint): ptr TWINDOW{.
    extdecl, importc: "subpad", dynlib: pdcursesdll.}
proc subwin*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cint; a6: cint): ptr TWINDOW{.
    extdecl, importc: "subwin", dynlib: pdcursesdll.}
proc syncok*(a2: ptr TWINDOW; a3: cunsignedchar): cint{.extdecl, importc: "syncok",
    dynlib: pdcursesdll.}
proc termattrs*(): cunsignedlong{.extdecl, importc: "termattrs",
                                  dynlib: pdcursesdll.}
proc termattrs2*(): cunsignedlong{.extdecl, importc: "term_attrs",
                                   dynlib: pdcursesdll.}
proc termname*(): cstring{.extdecl, importc: "termname", dynlib: pdcursesdll.}
proc timeout*(a2: cint){.extdecl, importc: "timeout", dynlib: pdcursesdll.}
proc touchline*(a2: ptr TWINDOW; a3: cint; a4: cint): cint{.extdecl,
    importc: "touchline", dynlib: pdcursesdll.}
proc touchwin*(a2: ptr TWINDOW): cint{.extdecl, importc: "touchwin",
                                      dynlib: pdcursesdll.}
proc typeahead*(a2: cint): cint{.extdecl, importc: "typeahead",
                                 dynlib: pdcursesdll.}
proc untouchwin*(a2: ptr TWINDOW): cint{.extdecl, importc: "untouchwin",
                                        dynlib: pdcursesdll.}
proc use_env*(a2: cunsignedchar){.extdecl, importc: "use_env", dynlib: pdcursesdll.}
proc vidattr*(a2: cunsignedlong): cint{.extdecl, importc: "vidattr",
                                        dynlib: pdcursesdll.}
proc vid_attr*(a2: cunsignedlong; a3: cshort; a4: pointer): cint{.extdecl,
    importc: "vid_attr", dynlib: pdcursesdll.}
#int     vidputs(chtype, int (*)(int));
#int     vid_puts(attr_t, short, void *, int (*)(int));
proc vline*(a2: cunsignedlong; a3: cint): cint{.extdecl, importc: "vline",
    dynlib: pdcursesdll.}
proc vwprintw*(a2: ptr TWINDOW; a3: cstring): cint{.extdecl, varargs,
    importc: "vw_printw", dynlib: pdcursesdll.}
proc vwprintw2*(a2: ptr TWINDOW; a3: cstring): cint{.extdecl, varargs,
    importc: "vwprintw", dynlib: pdcursesdll.}
proc vwscanw*(a2: ptr TWINDOW; a3: cstring): cint{.extdecl, varargs,
    importc: "vw_scanw", dynlib: pdcursesdll.}
proc vwscanw2*(a2: ptr TWINDOW; a3: cstring): cint{.extdecl, varargs,
    importc: "vwscanw", dynlib: pdcursesdll.}
proc waddchnstr*(a2: ptr TWINDOW; a3: ptr cunsignedlong; a4: cint): cint{.extdecl,
    importc: "waddchnstr", dynlib: pdcursesdll.}
proc waddchstr*(a2: ptr TWINDOW; a3: ptr cunsignedlong): cint{.extdecl,
    importc: "waddchstr", dynlib: pdcursesdll.}
proc waddch*(a2: ptr TWINDOW; a3: cunsignedlong): cint{.extdecl, importc: "waddch",
    dynlib: pdcursesdll.}
proc waddnstr*(a2: ptr TWINDOW; a3: cstring; a4: cint): cint{.extdecl,
    importc: "waddnstr", dynlib: pdcursesdll.}
proc waddstr*(a2: ptr TWINDOW; a3: cstring): cint{.extdecl, importc: "waddstr",
    dynlib: pdcursesdll.}
proc wattroff*(a2: ptr TWINDOW; a3: cunsignedlong): cint{.extdecl,
    importc: "wattroff", dynlib: pdcursesdll.}
proc wattron*(a2: ptr TWINDOW; a3: cunsignedlong): cint{.extdecl,
    importc: "wattron", dynlib: pdcursesdll.}
proc wattrset*(a2: ptr TWINDOW; a3: cunsignedlong): cint{.extdecl,
    importc: "wattrset", dynlib: pdcursesdll.}
proc wattr_get*(a2: ptr TWINDOW; a3: ptr cunsignedlong; a4: ptr cshort;
                a5: pointer): cint{.extdecl, importc: "wattr_get",
                                    dynlib: pdcursesdll.}
proc wattr_off*(a2: ptr TWINDOW; a3: cunsignedlong; a4: pointer): cint{.extdecl,
    importc: "wattr_off", dynlib: pdcursesdll.}
proc wattr_on*(a2: ptr TWINDOW; a3: cunsignedlong; a4: pointer): cint{.extdecl,
    importc: "wattr_on", dynlib: pdcursesdll.}
proc wattr_set*(a2: ptr TWINDOW; a3: cunsignedlong; a4: cshort; a5: pointer): cint{.
    extdecl, importc: "wattr_set", dynlib: pdcursesdll.}
proc wbkgdset*(a2: ptr TWINDOW; a3: cunsignedlong){.extdecl, importc: "wbkgdset",
    dynlib: pdcursesdll.}
proc wbkgd*(a2: ptr TWINDOW; a3: cunsignedlong): cint{.extdecl, importc: "wbkgd",
    dynlib: pdcursesdll.}
proc wborder*(a2: ptr TWINDOW; a3: cunsignedlong; a4: cunsignedlong;
              a5: cunsignedlong; a6: cunsignedlong; a7: cunsignedlong;
              a8: cunsignedlong; a9: cunsignedlong; a10: cunsignedlong): cint{.
    extdecl, importc: "wborder", dynlib: pdcursesdll.}
proc wchgat*(a2: ptr TWINDOW; a3: cint; a4: cunsignedlong; a5: cshort;
             a6: pointer): cint{.extdecl, importc: "wchgat", dynlib: pdcursesdll.}
proc wclear*(a2: ptr TWINDOW): cint{.extdecl, importc: "wclear",
                                    dynlib: pdcursesdll.}
proc wclrtobot*(a2: ptr TWINDOW): cint{.extdecl, importc: "wclrtobot",
                                       dynlib: pdcursesdll.}
proc wclrtoeol*(a2: ptr TWINDOW): cint{.extdecl, importc: "wclrtoeol",
                                       dynlib: pdcursesdll.}
proc wcolor_set*(a2: ptr TWINDOW; a3: cshort; a4: pointer): cint{.extdecl,
    importc: "wcolor_set", dynlib: pdcursesdll.}
proc wcursyncup*(a2: ptr TWINDOW){.extdecl, importc: "wcursyncup",
                                  dynlib: pdcursesdll.}
proc wdelch*(a2: ptr TWINDOW): cint{.extdecl, importc: "wdelch",
                                    dynlib: pdcursesdll.}
proc wdeleteln*(a2: ptr TWINDOW): cint{.extdecl, importc: "wdeleteln",
                                       dynlib: pdcursesdll.}
proc wechochar*(a2: ptr TWINDOW; a3: cunsignedlong): cint{.extdecl,
    importc: "wechochar", dynlib: pdcursesdll.}
proc werase*(a2: ptr TWINDOW): cint{.extdecl, importc: "werase",
                                    dynlib: pdcursesdll.}
proc wgetch*(a2: ptr TWINDOW): cint{.extdecl, importc: "wgetch",
                                    dynlib: pdcursesdll.}
proc wgetnstr*(a2: ptr TWINDOW; a3: cstring; a4: cint): cint{.extdecl,
    importc: "wgetnstr", dynlib: pdcursesdll.}
proc wgetstr*(a2: ptr TWINDOW; a3: cstring): cint{.extdecl, importc: "wgetstr",
    dynlib: pdcursesdll.}
proc whline*(a2: ptr TWINDOW; a3: cunsignedlong; a4: cint): cint{.extdecl,
    importc: "whline", dynlib: pdcursesdll.}
proc winchnstr*(a2: ptr TWINDOW; a3: ptr cunsignedlong; a4: cint): cint{.extdecl,
    importc: "winchnstr", dynlib: pdcursesdll.}
proc winchstr*(a2: ptr TWINDOW; a3: ptr cunsignedlong): cint{.extdecl,
    importc: "winchstr", dynlib: pdcursesdll.}
proc winch*(a2: ptr TWINDOW): cunsignedlong{.extdecl, importc: "winch",
    dynlib: pdcursesdll.}
proc winnstr*(a2: ptr TWINDOW; a3: cstring; a4: cint): cint{.extdecl,
    importc: "winnstr", dynlib: pdcursesdll.}
proc winsch*(a2: ptr TWINDOW; a3: cunsignedlong): cint{.extdecl, importc: "winsch",
    dynlib: pdcursesdll.}
proc winsdelln*(a2: ptr TWINDOW; a3: cint): cint{.extdecl, importc: "winsdelln",
    dynlib: pdcursesdll.}
proc winsertln*(a2: ptr TWINDOW): cint{.extdecl, importc: "winsertln",
                                       dynlib: pdcursesdll.}
proc winsnstr*(a2: ptr TWINDOW; a3: cstring; a4: cint): cint{.extdecl,
    importc: "winsnstr", dynlib: pdcursesdll.}
proc winsstr*(a2: ptr TWINDOW; a3: cstring): cint{.extdecl, importc: "winsstr",
    dynlib: pdcursesdll.}
proc winstr*(a2: ptr TWINDOW; a3: cstring): cint{.extdecl, importc: "winstr",
    dynlib: pdcursesdll.}
proc wmove*(a2: ptr TWINDOW; a3: cint; a4: cint): cint{.extdecl, importc: "wmove",
    dynlib: pdcursesdll.}
proc wnoutrefresh*(a2: ptr TWINDOW): cint{.extdecl, importc: "wnoutrefresh",
    dynlib: pdcursesdll.}
proc wprintw*(a2: ptr TWINDOW; a3: cstring): cint{.varargs, extdecl,
    importc: "wprintw", dynlib: pdcursesdll.}
proc wredrawln*(a2: ptr TWINDOW; a3: cint; a4: cint): cint{.extdecl,
    importc: "wredrawln", dynlib: pdcursesdll.}
proc wrefresh*(a2: ptr TWINDOW): cint{.extdecl, importc: "wrefresh",
                                      dynlib: pdcursesdll.}
proc wscanw*(a2: ptr TWINDOW; a3: cstring): cint{.varargs, extdecl,
    importc: "wscanw", dynlib: pdcursesdll.}
proc wscrl*(a2: ptr TWINDOW; a3: cint): cint{.extdecl, importc: "wscrl",
    dynlib: pdcursesdll.}
proc wsetscrreg*(a2: ptr TWINDOW; a3: cint; a4: cint): cint{.extdecl,
    importc: "wsetscrreg", dynlib: pdcursesdll.}
proc wstandend*(a2: ptr TWINDOW): cint{.extdecl, importc: "wstandend",
                                       dynlib: pdcursesdll.}
proc wstandout*(a2: ptr TWINDOW): cint{.extdecl, importc: "wstandout",
                                       dynlib: pdcursesdll.}
proc wsyncdown*(a2: ptr TWINDOW){.extdecl, importc: "wsyncdown",
                                 dynlib: pdcursesdll.}
proc wsyncup*(a2: ptr TWINDOW){.extdecl, importc: "wsyncup", dynlib: pdcursesdll.}
proc wtimeout*(a2: ptr TWINDOW; a3: cint){.extdecl, importc: "wtimeout",
    dynlib: pdcursesdll.}
proc wtouchln*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cint): cint{.extdecl,
    importc: "wtouchln", dynlib: pdcursesdll.}
proc wvline*(a2: ptr TWINDOW; a3: cunsignedlong; a4: cint): cint{.extdecl,
    importc: "wvline", dynlib: pdcursesdll.}
proc addnwstr*(a2: cstring; a3: cint): cint{.extdecl, importc: "addnwstr",
    dynlib: pdcursesdll.}
proc addwstr*(a2: cstring): cint{.extdecl, importc: "addwstr",
                                      dynlib: pdcursesdll.}
proc add_wch*(a2: ptr cunsignedlong): cint{.extdecl, importc: "add_wch",
    dynlib: pdcursesdll.}
proc add_wchnstr*(a2: ptr cunsignedlong; a3: cint): cint{.extdecl,
    importc: "add_wchnstr", dynlib: pdcursesdll.}
proc add_wchstr*(a2: ptr cunsignedlong): cint{.extdecl, importc: "add_wchstr",
    dynlib: pdcursesdll.}
proc border_set*(a2: ptr cunsignedlong; a3: ptr cunsignedlong;
                 a4: ptr cunsignedlong; a5: ptr cunsignedlong;
                 a6: ptr cunsignedlong; a7: ptr cunsignedlong;
                 a8: ptr cunsignedlong; a9: ptr cunsignedlong): cint{.extdecl,
    importc: "border_set", dynlib: pdcursesdll.}
proc box_set*(a2: ptr TWINDOW; a3: ptr cunsignedlong; a4: ptr cunsignedlong): cint{.
    extdecl, importc: "box_set", dynlib: pdcursesdll.}
proc echo_wchar*(a2: ptr cunsignedlong): cint{.extdecl, importc: "echo_wchar",
    dynlib: pdcursesdll.}
proc erasewchar*(a2: cstring): cint{.extdecl, importc: "erasewchar",
    dynlib: pdcursesdll.}
proc getbkgrnd*(a2: ptr cunsignedlong): cint{.extdecl, importc: "getbkgrnd",
    dynlib: pdcursesdll.}
proc getcchar*(a2: ptr cunsignedlong; a3: cstring; a4: ptr cunsignedlong;
               a5: ptr cshort; a6: pointer): cint{.extdecl, importc: "getcchar",
    dynlib: pdcursesdll.}
proc getn_wstr*(a2: ptr cint; a3: cint): cint{.extdecl, importc: "getn_wstr",
    dynlib: pdcursesdll.}
proc get_wch*(a2: ptr cint): cint{.extdecl, importc: "get_wch",
                                     dynlib: pdcursesdll.}
proc get_wstr*(a2: ptr cint): cint{.extdecl, importc: "get_wstr",
                                      dynlib: pdcursesdll.}
proc hline_set*(a2: ptr cunsignedlong; a3: cint): cint{.extdecl,
    importc: "hline_set", dynlib: pdcursesdll.}
proc innwstr*(a2: cstring; a3: cint): cint{.extdecl, importc: "innwstr",
    dynlib: pdcursesdll.}
proc ins_nwstr*(a2: cstring; a3: cint): cint{.extdecl, importc: "ins_nwstr",
    dynlib: pdcursesdll.}
proc ins_wch*(a2: ptr cunsignedlong): cint{.extdecl, importc: "ins_wch",
    dynlib: pdcursesdll.}
proc ins_wstr*(a2: cstring): cint{.extdecl, importc: "ins_wstr",
                                       dynlib: pdcursesdll.}
proc inwstr*(a2: cstring): cint{.extdecl, importc: "inwstr",
                                     dynlib: pdcursesdll.}
proc in_wch*(a2: ptr cunsignedlong): cint{.extdecl, importc: "in_wch",
    dynlib: pdcursesdll.}
proc in_wchnstr*(a2: ptr cunsignedlong; a3: cint): cint{.extdecl,
    importc: "in_wchnstr", dynlib: pdcursesdll.}
proc in_wchstr*(a2: ptr cunsignedlong): cint{.extdecl, importc: "in_wchstr",
    dynlib: pdcursesdll.}
proc key_name*(a2: char): cstring{.extdecl, importc: "key_name",
                                      dynlib: pdcursesdll.}
proc killwchar*(a2: cstring): cint{.extdecl, importc: "killwchar",
                                        dynlib: pdcursesdll.}
proc mvaddnwstr*(a2: cint; a3: cint; a4: cstring; a5: cint): cint{.extdecl,
    importc: "mvaddnwstr", dynlib: pdcursesdll.}
proc mvaddwstr*(a2: cint; a3: cint; a4: cstring): cint{.extdecl,
    importc: "mvaddwstr", dynlib: pdcursesdll.}
proc mvadd_wch*(a2: cint; a3: cint; a4: ptr cunsignedlong): cint{.extdecl,
    importc: "mvadd_wch", dynlib: pdcursesdll.}
proc mvadd_wchnstr*(a2: cint; a3: cint; a4: ptr cunsignedlong; a5: cint): cint{.
    extdecl, importc: "mvadd_wchnstr", dynlib: pdcursesdll.}
proc mvadd_wchstr*(a2: cint; a3: cint; a4: ptr cunsignedlong): cint{.extdecl,
    importc: "mvadd_wchstr", dynlib: pdcursesdll.}
proc mvgetn_wstr*(a2: cint; a3: cint; a4: ptr cint; a5: cint): cint{.extdecl,
    importc: "mvgetn_wstr", dynlib: pdcursesdll.}
proc mvget_wch*(a2: cint; a3: cint; a4: ptr cint): cint{.extdecl,
    importc: "mvget_wch", dynlib: pdcursesdll.}
proc mvget_wstr*(a2: cint; a3: cint; a4: ptr cint): cint{.extdecl,
    importc: "mvget_wstr", dynlib: pdcursesdll.}
proc mvhline_set*(a2: cint; a3: cint; a4: ptr cunsignedlong; a5: cint): cint{.
    extdecl, importc: "mvhline_set", dynlib: pdcursesdll.}
proc mvinnwstr*(a2: cint; a3: cint; a4: cstring; a5: cint): cint{.extdecl,
    importc: "mvinnwstr", dynlib: pdcursesdll.}
proc mvins_nwstr*(a2: cint; a3: cint; a4: cstring; a5: cint): cint{.extdecl,
    importc: "mvins_nwstr", dynlib: pdcursesdll.}
proc mvins_wch*(a2: cint; a3: cint; a4: ptr cunsignedlong): cint{.extdecl,
    importc: "mvins_wch", dynlib: pdcursesdll.}
proc mvins_wstr*(a2: cint; a3: cint; a4: cstring): cint{.extdecl,
    importc: "mvins_wstr", dynlib: pdcursesdll.}
proc mvinwstr*(a2: cint; a3: cint; a4: cstring): cint{.extdecl,
    importc: "mvinwstr", dynlib: pdcursesdll.}
proc mvin_wch*(a2: cint; a3: cint; a4: ptr cunsignedlong): cint{.extdecl,
    importc: "mvin_wch", dynlib: pdcursesdll.}
proc mvin_wchnstr*(a2: cint; a3: cint; a4: ptr cunsignedlong; a5: cint): cint{.
    extdecl, importc: "mvin_wchnstr", dynlib: pdcursesdll.}
proc mvin_wchstr*(a2: cint; a3: cint; a4: ptr cunsignedlong): cint{.extdecl,
    importc: "mvin_wchstr", dynlib: pdcursesdll.}
proc mvvline_set*(a2: cint; a3: cint; a4: ptr cunsignedlong; a5: cint): cint{.
    extdecl, importc: "mvvline_set", dynlib: pdcursesdll.}
proc mvwaddnwstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring; a6: cint): cint{.
    extdecl, importc: "mvwaddnwstr", dynlib: pdcursesdll.}
proc mvwaddwstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring): cint{.
    extdecl, importc: "mvwaddwstr", dynlib: pdcursesdll.}
proc mvwadd_wch*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong): cint{.
    extdecl, importc: "mvwadd_wch", dynlib: pdcursesdll.}
proc mvwadd_wchnstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong;
                     a6: cint): cint{.extdecl, importc: "mvwadd_wchnstr",
                                      dynlib: pdcursesdll.}
proc mvwadd_wchstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong): cint{.
    extdecl, importc: "mvwadd_wchstr", dynlib: pdcursesdll.}
proc mvwgetn_wstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cint; a6: cint): cint{.
    extdecl, importc: "mvwgetn_wstr", dynlib: pdcursesdll.}
proc mvwget_wch*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cint): cint{.
    extdecl, importc: "mvwget_wch", dynlib: pdcursesdll.}
proc mvwget_wstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cint): cint{.
    extdecl, importc: "mvwget_wstr", dynlib: pdcursesdll.}
proc mvwhline_set*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong;
                   a6: cint): cint{.extdecl, importc: "mvwhline_set",
                                    dynlib: pdcursesdll.}
proc mvwinnwstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring; a6: cint): cint{.
    extdecl, importc: "mvwinnwstr", dynlib: pdcursesdll.}
proc mvwins_nwstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring; a6: cint): cint{.
    extdecl, importc: "mvwins_nwstr", dynlib: pdcursesdll.}
proc mvwins_wch*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong): cint{.
    extdecl, importc: "mvwins_wch", dynlib: pdcursesdll.}
proc mvwins_wstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring): cint{.
    extdecl, importc: "mvwins_wstr", dynlib: pdcursesdll.}
proc mvwin_wch*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong): cint{.
    extdecl, importc: "mvwin_wch", dynlib: pdcursesdll.}
proc mvwin_wchnstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong;
                    a6: cint): cint{.extdecl, importc: "mvwin_wchnstr",
                                     dynlib: pdcursesdll.}
proc mvwin_wchstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong): cint{.
    extdecl, importc: "mvwin_wchstr", dynlib: pdcursesdll.}
proc mvwinwstr*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cstring): cint{.
    extdecl, importc: "mvwinwstr", dynlib: pdcursesdll.}
proc mvwvline_set*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: ptr cunsignedlong;
                   a6: cint): cint{.extdecl, importc: "mvwvline_set",
                                    dynlib: pdcursesdll.}
proc pecho_wchar*(a2: ptr TWINDOW; a3: ptr cunsignedlong): cint{.extdecl,
    importc: "pecho_wchar", dynlib: pdcursesdll.}
proc setcchar*(a2: ptr cunsignedlong; a3: cstring; a4: cunsignedlong;
               a5: cshort; a6: pointer): cint{.extdecl, importc: "setcchar",
    dynlib: pdcursesdll.}
proc slk_wset*(a2: cint; a3: cstring; a4: cint): cint{.extdecl,
    importc: "slk_wset", dynlib: pdcursesdll.}
proc unget_wch*(a2: char): cint{.extdecl, importc: "unget_wch",
                                    dynlib: pdcursesdll.}
proc vline_set*(a2: ptr cunsignedlong; a3: cint): cint{.extdecl,
    importc: "vline_set", dynlib: pdcursesdll.}
proc waddnwstr*(a2: ptr TWINDOW; a3: cstring; a4: cint): cint{.extdecl,
    importc: "waddnwstr", dynlib: pdcursesdll.}
proc waddwstr*(a2: ptr TWINDOW; a3: cstring): cint{.extdecl,
    importc: "waddwstr", dynlib: pdcursesdll.}
proc wadd_wch*(a2: ptr TWINDOW; a3: ptr cunsignedlong): cint{.extdecl,
    importc: "wadd_wch", dynlib: pdcursesdll.}
proc wadd_wchnstr*(a2: ptr TWINDOW; a3: ptr cunsignedlong; a4: cint): cint{.
    extdecl, importc: "wadd_wchnstr", dynlib: pdcursesdll.}
proc wadd_wchstr*(a2: ptr TWINDOW; a3: ptr cunsignedlong): cint{.extdecl,
    importc: "wadd_wchstr", dynlib: pdcursesdll.}
proc wbkgrnd*(a2: ptr TWINDOW; a3: ptr cunsignedlong): cint{.extdecl,
    importc: "wbkgrnd", dynlib: pdcursesdll.}
proc wbkgrndset*(a2: ptr TWINDOW; a3: ptr cunsignedlong){.extdecl,
    importc: "wbkgrndset", dynlib: pdcursesdll.}
proc wborder_set*(a2: ptr TWINDOW; a3: ptr cunsignedlong; a4: ptr cunsignedlong;
                  a5: ptr cunsignedlong; a6: ptr cunsignedlong;
                  a7: ptr cunsignedlong; a8: ptr cunsignedlong;
                  a9: ptr cunsignedlong; a10: ptr cunsignedlong): cint{.extdecl,
    importc: "wborder_set", dynlib: pdcursesdll.}
proc wecho_wchar*(a2: ptr TWINDOW; a3: ptr cunsignedlong): cint{.extdecl,
    importc: "wecho_wchar", dynlib: pdcursesdll.}
proc wgetbkgrnd*(a2: ptr TWINDOW; a3: ptr cunsignedlong): cint{.extdecl,
    importc: "wgetbkgrnd", dynlib: pdcursesdll.}
proc wgetn_wstr*(a2: ptr TWINDOW; a3: ptr cint; a4: cint): cint{.extdecl,
    importc: "wgetn_wstr", dynlib: pdcursesdll.}
proc wget_wch*(a2: ptr TWINDOW; a3: ptr cint): cint{.extdecl,
    importc: "wget_wch", dynlib: pdcursesdll.}
proc wget_wstr*(a2: ptr TWINDOW; a3: ptr cint): cint{.extdecl,
    importc: "wget_wstr", dynlib: pdcursesdll.}
proc whline_set*(a2: ptr TWINDOW; a3: ptr cunsignedlong; a4: cint): cint{.extdecl,
    importc: "whline_set", dynlib: pdcursesdll.}
proc winnwstr*(a2: ptr TWINDOW; a3: cstring; a4: cint): cint{.extdecl,
    importc: "winnwstr", dynlib: pdcursesdll.}
proc wins_nwstr*(a2: ptr TWINDOW; a3: cstring; a4: cint): cint{.extdecl,
    importc: "wins_nwstr", dynlib: pdcursesdll.}
proc wins_wch*(a2: ptr TWINDOW; a3: ptr cunsignedlong): cint{.extdecl,
    importc: "wins_wch", dynlib: pdcursesdll.}
proc wins_wstr*(a2: ptr TWINDOW; a3: cstring): cint{.extdecl,
    importc: "wins_wstr", dynlib: pdcursesdll.}
proc winwstr*(a2: ptr TWINDOW; a3: cstring): cint{.extdecl, importc: "winwstr",
    dynlib: pdcursesdll.}
proc win_wch*(a2: ptr TWINDOW; a3: ptr cunsignedlong): cint{.extdecl,
    importc: "win_wch", dynlib: pdcursesdll.}
proc win_wchnstr*(a2: ptr TWINDOW; a3: ptr cunsignedlong; a4: cint): cint{.extdecl,
    importc: "win_wchnstr", dynlib: pdcursesdll.}
proc win_wchstr*(a2: ptr TWINDOW; a3: ptr cunsignedlong): cint{.extdecl,
    importc: "win_wchstr", dynlib: pdcursesdll.}
proc wunctrl*(a2: ptr cunsignedlong): cstring{.extdecl, importc: "wunctrl",
    dynlib: pdcursesdll.}
proc wvline_set*(a2: ptr TWINDOW; a3: ptr cunsignedlong; a4: cint): cint{.extdecl,
    importc: "wvline_set", dynlib: pdcursesdll.}
proc getattrs*(a2: ptr TWINDOW): cunsignedlong{.extdecl, importc: "getattrs",
    dynlib: pdcursesdll.}
proc getbegx*(a2: ptr TWINDOW): cint{.extdecl, importc: "getbegx",
                                     dynlib: pdcursesdll.}
proc getbegy*(a2: ptr TWINDOW): cint{.extdecl, importc: "getbegy",
                                     dynlib: pdcursesdll.}
proc getmaxx*(a2: ptr TWINDOW): cint{.extdecl, importc: "getmaxx",
                                     dynlib: pdcursesdll.}
proc getmaxy*(a2: ptr TWINDOW): cint{.extdecl, importc: "getmaxy",
                                     dynlib: pdcursesdll.}
proc getparx*(a2: ptr TWINDOW): cint{.extdecl, importc: "getparx",
                                     dynlib: pdcursesdll.}
proc getpary*(a2: ptr TWINDOW): cint{.extdecl, importc: "getpary",
                                     dynlib: pdcursesdll.}
proc getcurx*(a2: ptr TWINDOW): cint{.extdecl, importc: "getcurx",
                                     dynlib: pdcursesdll.}
proc getcury*(a2: ptr TWINDOW): cint{.extdecl, importc: "getcury",
                                     dynlib: pdcursesdll.}
proc traceoff*(){.extdecl, importc: "traceoff", dynlib: pdcursesdll.}
proc traceon*(){.extdecl, importc: "traceon", dynlib: pdcursesdll.}
proc unctrl*(a2: cunsignedlong): cstring{.extdecl, importc: "unctrl",
    dynlib: pdcursesdll.}
proc crmode*(): cint{.extdecl, importc: "crmode", dynlib: pdcursesdll.}
proc nocrmode*(): cint{.extdecl, importc: "nocrmode", dynlib: pdcursesdll.}
proc draino*(a2: cint): cint{.extdecl, importc: "draino", dynlib: pdcursesdll.}
proc resetterm*(): cint{.extdecl, importc: "resetterm", dynlib: pdcursesdll.}
proc fixterm*(): cint{.extdecl, importc: "fixterm", dynlib: pdcursesdll.}
proc saveterm*(): cint{.extdecl, importc: "saveterm", dynlib: pdcursesdll.}
proc setsyx*(a2: cint; a3: cint): cint{.extdecl, importc: "setsyx",
                                        dynlib: pdcursesdll.}
proc mouse_set*(a2: cunsignedlong): cint{.extdecl, importc: "mouse_set",
    dynlib: pdcursesdll.}
proc mouse_on*(a2: cunsignedlong): cint{.extdecl, importc: "mouse_on",
    dynlib: pdcursesdll.}
proc mouse_off*(a2: cunsignedlong): cint{.extdecl, importc: "mouse_off",
    dynlib: pdcursesdll.}
proc request_mouse_pos*(): cint{.extdecl, importc: "request_mouse_pos",
                                 dynlib: pdcursesdll.}
proc map_button*(a2: cunsignedlong): cint{.extdecl, importc: "map_button",
    dynlib: pdcursesdll.}
proc wmouse_position*(a2: ptr TWINDOW; a3: ptr cint; a4: ptr cint){.extdecl,
    importc: "wmouse_position", dynlib: pdcursesdll.}
proc getmouse*(): cunsignedlong{.extdecl, importc: "getmouse", dynlib: pdcursesdll.}
proc getbmap*(): cunsignedlong{.extdecl, importc: "getbmap", dynlib: pdcursesdll.}
proc assume_default_colors*(a2: cint; a3: cint): cint{.extdecl,
    importc: "assume_default_colors", dynlib: pdcursesdll.}
proc curses_version*(): cstring{.extdecl, importc: "curses_version",
                                 dynlib: pdcursesdll.}
proc has_key*(a2: cint): cunsignedchar{.extdecl, importc: "has_key",
                                        dynlib: pdcursesdll.}
proc use_default_colors*(): cint{.extdecl, importc: "use_default_colors",
                                  dynlib: pdcursesdll.}
proc wresize*(a2: ptr TWINDOW; a3: cint; a4: cint): cint{.extdecl,
    importc: "wresize", dynlib: pdcursesdll.}
proc mouseinterval*(a2: cint): cint{.extdecl, importc: "mouseinterval",
                                     dynlib: pdcursesdll.}
proc mousemask*(a2: cunsignedlong; a3: ptr cunsignedlong): cunsignedlong{.extdecl,
    importc: "mousemask", dynlib: pdcursesdll.}
proc mouse_trafo*(a2: ptr cint; a3: ptr cint; a4: cunsignedchar): cunsignedchar{.
    extdecl, importc: "mouse_trafo", dynlib: pdcursesdll.}
proc nc_getmouse*(a2: ptr TMEVENT): cint{.extdecl, importc: "nc_getmouse",
    dynlib: pdcursesdll.}
proc ungetmouse*(a2: ptr TMEVENT): cint{.extdecl, importc: "ungetmouse",
                                        dynlib: pdcursesdll.}
proc wenclose*(a2: ptr TWINDOW; a3: cint; a4: cint): cunsignedchar{.extdecl,
    importc: "wenclose", dynlib: pdcursesdll.}
proc wmouse_trafo*(a2: ptr TWINDOW; a3: ptr cint; a4: ptr cint; a5: cunsignedchar): cunsignedchar{.
    extdecl, importc: "wmouse_trafo", dynlib: pdcursesdll.}
proc addrawch*(a2: cunsignedlong): cint{.extdecl, importc: "addrawch",
    dynlib: pdcursesdll.}
proc insrawch*(a2: cunsignedlong): cint{.extdecl, importc: "insrawch",
    dynlib: pdcursesdll.}
proc is_termresized*(): cunsignedchar{.extdecl, importc: "is_termresized",
                                       dynlib: pdcursesdll.}
proc mvaddrawch*(a2: cint; a3: cint; a4: cunsignedlong): cint{.extdecl,
    importc: "mvaddrawch", dynlib: pdcursesdll.}
proc mvdeleteln*(a2: cint; a3: cint): cint{.extdecl, importc: "mvdeleteln",
    dynlib: pdcursesdll.}
proc mvinsertln*(a2: cint; a3: cint): cint{.extdecl, importc: "mvinsertln",
    dynlib: pdcursesdll.}
proc mvinsrawch*(a2: cint; a3: cint; a4: cunsignedlong): cint{.extdecl,
    importc: "mvinsrawch", dynlib: pdcursesdll.}
proc mvwaddrawch*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cunsignedlong): cint{.
    extdecl, importc: "mvwaddrawch", dynlib: pdcursesdll.}
proc mvwdeleteln*(a2: ptr TWINDOW; a3: cint; a4: cint): cint{.extdecl,
    importc: "mvwdeleteln", dynlib: pdcursesdll.}
proc mvwinsertln*(a2: ptr TWINDOW; a3: cint; a4: cint): cint{.extdecl,
    importc: "mvwinsertln", dynlib: pdcursesdll.}
proc mvwinsrawch*(a2: ptr TWINDOW; a3: cint; a4: cint; a5: cunsignedlong): cint{.
    extdecl, importc: "mvwinsrawch", dynlib: pdcursesdll.}
proc raw_output*(a2: cunsignedchar): cint{.extdecl, importc: "raw_output",
    dynlib: pdcursesdll.}
proc resize_term*(a2: cint; a3: cint): cint{.extdecl, importc: "resize_term",
    dynlib: pdcursesdll.}
proc resize_window*(a2: ptr TWINDOW; a3: cint; a4: cint): ptr TWINDOW{.extdecl,
    importc: "resize_window", dynlib: pdcursesdll.}
proc waddrawch*(a2: ptr TWINDOW; a3: cunsignedlong): cint{.extdecl,
    importc: "waddrawch", dynlib: pdcursesdll.}
proc winsrawch*(a2: ptr TWINDOW; a3: cunsignedlong): cint{.extdecl,
    importc: "winsrawch", dynlib: pdcursesdll.}
proc wordchar*(): char{.extdecl, importc: "wordchar", dynlib: pdcursesdll.}
proc slk_wlabel*(a2: cint): cstring{.extdecl, importc: "slk_wlabel",
    dynlib: pdcursesdll.}
proc debug*(a2: cstring){.varargs, extdecl, importc: "PDC_debug",
                          dynlib: pdcursesdll.}
proc ungetch*(a2: cint): cint{.extdecl, importc: "PDC_ungetch",
                               dynlib: pdcursesdll.}
proc set_blink*(a2: cunsignedchar): cint{.extdecl, importc: "PDC_set_blink",
    dynlib: pdcursesdll.}
proc set_line_color*(a2: cshort): cint{.extdecl, importc: "PDC_set_line_color",
                                        dynlib: pdcursesdll.}
proc set_title*(a2: cstring){.extdecl, importc: "PDC_set_title",
                              dynlib: pdcursesdll.}
proc clearclipboard*(): cint{.extdecl, importc: "PDC_clearclipboard",
                              dynlib: pdcursesdll.}
proc freeclipboard*(a2: cstring): cint{.extdecl, importc: "PDC_freeclipboard",
                                        dynlib: pdcursesdll.}
proc getclipboard*(a2: cstringArray; a3: ptr clong): cint{.extdecl,
    importc: "PDC_getclipboard", dynlib: pdcursesdll.}
proc setclipboard*(a2: cstring; a3: clong): cint{.extdecl,
    importc: "PDC_setclipboard", dynlib: pdcursesdll.}
proc get_input_fd*(): cunsignedlong{.extdecl, importc: "PDC_get_input_fd",
                                     dynlib: pdcursesdll.}
proc get_key_modifiers*(): cunsignedlong{.extdecl,
    importc: "PDC_get_key_modifiers", dynlib: pdcursesdll.}
proc return_key_modifiers*(a2: cunsignedchar): cint{.extdecl,
    importc: "PDC_return_key_modifiers", dynlib: pdcursesdll.}
proc save_key_modifiers*(a2: cunsignedchar): cint{.extdecl,
    importc: "PDC_save_key_modifiers", dynlib: pdcursesdll.}
proc bottom_panel*(pan: ptr TPANEL): cint{.extdecl, importc: "bottom_panel",
    dynlib: pdcursesdll.}
proc del_panel*(pan: ptr TPANEL): cint{.extdecl, importc: "del_panel",
                                       dynlib: pdcursesdll.}
proc hide_panel*(pan: ptr TPANEL): cint{.extdecl, importc: "hide_panel",
                                        dynlib: pdcursesdll.}
proc move_panel*(pan: ptr TPANEL; starty: cint; startx: cint): cint{.extdecl,
    importc: "move_panel", dynlib: pdcursesdll.}
proc new_panel*(win: ptr TWINDOW): ptr TPANEL{.extdecl, importc: "new_panel",
    dynlib: pdcursesdll.}
proc panel_above*(pan: ptr TPANEL): ptr TPANEL{.extdecl, importc: "panel_above",
    dynlib: pdcursesdll.}
proc panel_below*(pan: ptr TPANEL): ptr TPANEL{.extdecl, importc: "panel_below",
    dynlib: pdcursesdll.}
proc panel_hidden*(pan: ptr TPANEL): cint{.extdecl, importc: "panel_hidden",
    dynlib: pdcursesdll.}
proc panel_userptr*(pan: ptr TPANEL): pointer{.extdecl, importc: "panel_userptr",
    dynlib: pdcursesdll.}
proc panel_window*(pan: ptr TPANEL): ptr TWINDOW{.extdecl, importc: "panel_window",
    dynlib: pdcursesdll.}
proc replace_panel*(pan: ptr TPANEL; win: ptr TWINDOW): cint{.extdecl,
    importc: "replace_panel", dynlib: pdcursesdll.}
proc set_panel_userptr*(pan: ptr TPANEL; uptr: pointer): cint{.extdecl,
    importc: "set_panel_userptr", dynlib: pdcursesdll.}
proc show_panel*(pan: ptr TPANEL): cint{.extdecl, importc: "show_panel",
                                        dynlib: pdcursesdll.}
proc top_panel*(pan: ptr TPANEL): cint{.extdecl, importc: "top_panel",
                                       dynlib: pdcursesdll.}
proc update_panels*(){.extdecl, importc: "update_panels", dynlib: pdcursesdll.}

when unixOS:
  proc Xinitscr*(a2: cint; a3: cstringArray): ptr TWINDOW{.extdecl,
    importc: "Xinitscr", dynlib: pdcursesdll.}
  proc XCursesExit*(){.extdecl, importc: "XCursesExit", dynlib: pdcursesdll.}
  proc sb_init*(): cint{.extdecl, importc: "sb_init", dynlib: pdcursesdll.}
  proc sb_set_horz*(a2: cint; a3: cint; a4: cint): cint{.extdecl,
    importc: "sb_set_horz", dynlib: pdcursesdll.}
  proc sb_set_vert*(a2: cint; a3: cint; a4: cint): cint{.extdecl,
    importc: "sb_set_vert", dynlib: pdcursesdll.}
  proc sb_get_horz*(a2: ptr cint; a3: ptr cint; a4: ptr cint): cint{.extdecl,
    importc: "sb_get_horz", dynlib: pdcursesdll.}
  proc sb_get_vert*(a2: ptr cint; a3: ptr cint; a4: ptr cint): cint{.extdecl,
    importc: "sb_get_vert", dynlib: pdcursesdll.}
  proc sb_refresh*(): cint{.extdecl, importc: "sb_refresh", dynlib: pdcursesdll.}

template getch*(): expr =
  wgetch(stdscr)

template ungetch*(ch: expr): expr =
  ungetch(ch)

template getbegyx*(w, y, x: expr): expr =
  y = getbegy(w)
  x = getbegx(w)

template getmaxyx*(w, y, x: expr): expr =
  y = getmaxy(w)
  x = getmaxx(w)

template getparyx*(w, y, x: expr): expr =
  y = getpary(w)
  x = getparx(w)

template getyx*(w, y, x: expr): expr =
  y = getcury(w)
  x = getcurx(w)

template getsyx*(y, x: expr): stmt =
  if curscr.leaveit:
    (x) = - 1
    (y) = (x)
  else: getyx(curscr, (y), (x))

template getmouse*(x: expr): expr =
  nc_getmouse(x)

when defined(windows):
  var
    atrtab*{.importc: "pdc_atrtab", dynlib: pdcursesdll.}: cstring
    con_out*{.importc: "pdc_con_out", dynlib: pdcursesdll.}: HANDLE
    con_in*{.importc: "pdc_con_in", dynlib: pdcursesdll.}: HANDLE
    quick_edit*{.importc: "pdc_quick_edit", dynlib: pdcursesdll.}: DWORD

  proc get_buffer_rows*(): cint{.extdecl, importc: "PDC_get_buffer_rows",
                               dynlib: pdcursesdll.}