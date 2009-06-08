#
#
#  Adaption of the delphi3d.net OpenGL units to FreePascal
#  Sebastian Guenther (sg@freepascal.org) in 2002
#  These units are free to use
#

# Copyright (c) Mark J. Kilgard, 1994, 1995, 1996.
# This program is freely distributable without licensing fees  and is
#   provided without guarantee or warrantee expressed or  implied. This
#   program is -not- in the public domain.
#******************************************************************************
# Converted to Delphi by Tom Nuydens (tom@delphi3d.net)
#   Contributions by Igor Karpov (glygrik@hotbox.ru)
#   For the latest updates, visit Delphi3D: http://www.delphi3d.net
#******************************************************************************

import
  GL

when defined(windows):
  const dllname = "glut32.dll"
elif defined(macosx):
  const dllname = "/System/Library/Frameworks/GLUT.framework/GLUT"
else:
  const dllname = "libglut.so.3"

type
  PInteger* = ptr int
  PPChar* = ptr cstring
  TGlutVoidCallback* = proc (){.cdecl.}
  TGlut1IntCallback* = proc (value: cint){.cdecl.}
  TGlut2IntCallback* = proc (v1, v2: cint){.cdecl.}
  TGlut3IntCallback* = proc (v1, v2, v3: cint){.cdecl.}
  TGlut4IntCallback* = proc (v1, v2, v3, v4: cint){.cdecl.}
  TGlut1Char2IntCallback* = proc (c: int8, v1, v2: cint){.cdecl.}
  TGlut1UInt3IntCallback* = proc (u, v1, v2, v3: cint){.cdecl.}

const
  GLUT_API_VERSION* = 3
  GLUT_XLIB_IMPLEMENTATION* = 12 # Display mode bit masks.
  GLUT_RGB* = 0
  GLUT_RGBA* = GLUT_RGB
  GLUT_INDEX* = 1
  GLUT_SINGLE* = 0
  GLUT_DOUBLE* = 2
  GLUT_ACCUM* = 4
  GLUT_ALPHA* = 8
  GLUT_DEPTH* = 16
  GLUT_STENCIL* = 32
  GLUT_MULTISAMPLE* = 128
  GLUT_STEREO* = 256
  GLUT_LUMINANCE* = 512       # Mouse buttons.
  GLUT_LEFT_BUTTON* = 0
  GLUT_MIDDLE_BUTTON* = 1
  GLUT_RIGHT_BUTTON* = 2      # Mouse button state.
  GLUT_DOWN* = 0
  GLUT_UP* = 1                # function keys
  GLUT_KEY_F1* = 1
  GLUT_KEY_F2* = 2
  GLUT_KEY_F3* = 3
  GLUT_KEY_F4* = 4
  GLUT_KEY_F5* = 5
  GLUT_KEY_F6* = 6
  GLUT_KEY_F7* = 7
  GLUT_KEY_F8* = 8
  GLUT_KEY_F9* = 9
  GLUT_KEY_F10* = 10
  GLUT_KEY_F11* = 11
  GLUT_KEY_F12* = 12          # directional keys
  GLUT_KEY_LEFT* = 100
  GLUT_KEY_UP* = 101
  GLUT_KEY_RIGHT* = 102
  GLUT_KEY_DOWN* = 103
  GLUT_KEY_PAGE_UP* = 104
  GLUT_KEY_PAGE_DOWN* = 105
  GLUT_KEY_HOME* = 106
  GLUT_KEY_END* = 107
  GLUT_KEY_INSERT* = 108      # Entry/exit  state.
  GLUT_LEFT* = 0
  GLUT_ENTERED* = 1           # Menu usage state.
  GLUT_MENU_NOT_IN_USE* = 0
  GLUT_MENU_IN_USE* = 1       # Visibility  state.
  GLUT_NOT_VISIBLE* = 0
  GLUT_VISIBLE* = 1           # Window status  state.
  GLUT_HIDDEN* = 0
  GLUT_FULLY_RETAINED* = 1
  GLUT_PARTIALLY_RETAINED* = 2
  GLUT_FULLY_COVERED* = 3     # Color index component selection values.
  GLUT_RED* = 0
  GLUT_GREEN* = 1
  GLUT_BLUE* = 2              # Layers for use.
  GLUT_NORMAL* = 0
  GLUT_OVERLAY* = 1

when defined(Windows):
  const                       # Stroke font constants (use these in GLUT program).
    GLUT_STROKE_ROMAN* = cast[Pointer](0)
    GLUT_STROKE_MONO_ROMAN* = cast[Pointer](1) # Bitmap font constants (use these in GLUT program).
    GLUT_BITMAP_9_BY_15* = cast[Pointer](2)
    GLUT_BITMAP_8_BY_13* = cast[Pointer](3)
    GLUT_BITMAP_TIMES_ROMAN_10* = cast[Pointer](4)
    GLUT_BITMAP_TIMES_ROMAN_24* = cast[Pointer](5)
    GLUT_BITMAP_HELVETICA_10* = cast[Pointer](6)
    GLUT_BITMAP_HELVETICA_12* = cast[Pointer](7)
    GLUT_BITMAP_HELVETICA_18* = cast[Pointer](8)
else:
  var                         # Stroke font constants (use these in GLUT program).
    GLUT_STROKE_ROMAN*: Pointer
    GLUT_STROKE_MONO_ROMAN*: Pointer # Bitmap font constants (use these in GLUT program).
    GLUT_BITMAP_9_BY_15*: Pointer
    GLUT_BITMAP_8_BY_13*: Pointer
    GLUT_BITMAP_TIMES_ROMAN_10*: Pointer
    GLUT_BITMAP_TIMES_ROMAN_24*: Pointer
    GLUT_BITMAP_HELVETICA_10*: Pointer
    GLUT_BITMAP_HELVETICA_12*: Pointer
    GLUT_BITMAP_HELVETICA_18*: Pointer
const                         # glutGet parameters.
  GLUT_WINDOW_X* = 100
  GLUT_WINDOW_Y* = 101
  GLUT_WINDOW_WIDTH* = 102
  GLUT_WINDOW_HEIGHT* = 103
  GLUT_WINDOW_BUFFER_SIZE* = 104
  GLUT_WINDOW_STENCIL_SIZE* = 105
  GLUT_WINDOW_DEPTH_SIZE* = 106
  GLUT_WINDOW_RED_SIZE* = 107
  GLUT_WINDOW_GREEN_SIZE* = 108
  GLUT_WINDOW_BLUE_SIZE* = 109
  GLUT_WINDOW_ALPHA_SIZE* = 110
  GLUT_WINDOW_ACCUM_RED_SIZE* = 111
  GLUT_WINDOW_ACCUM_GREEN_SIZE* = 112
  GLUT_WINDOW_ACCUM_BLUE_SIZE* = 113
  GLUT_WINDOW_ACCUM_ALPHA_SIZE* = 114
  GLUT_WINDOW_DOUBLEBUFFER* = 115
  GLUT_WINDOW_RGBA* = 116
  GLUT_WINDOW_PARENT* = 117
  GLUT_WINDOW_NUM_CHILDREN* = 118
  GLUT_WINDOW_COLORMAP_SIZE* = 119
  GLUT_WINDOW_NUM_SAMPLES* = 120
  GLUT_WINDOW_STEREO* = 121
  GLUT_WINDOW_CURSOR* = 122
  GLUT_SCREEN_WIDTH* = 200
  GLUT_SCREEN_HEIGHT* = 201
  GLUT_SCREEN_WIDTH_MM* = 202
  GLUT_SCREEN_HEIGHT_MM* = 203
  GLUT_MENU_NUM_ITEMS* = 300
  GLUT_DISPLAY_MODE_POSSIBLE* = 400
  GLUT_INIT_WINDOW_X* = 500
  GLUT_INIT_WINDOW_Y* = 501
  GLUT_INIT_WINDOW_WIDTH* = 502
  GLUT_INIT_WINDOW_HEIGHT* = 503
  constGLUT_INIT_DISPLAY_MODE* = 504
  GLUT_ELAPSED_TIME* = 700
  GLUT_WINDOW_FORMAT_ID* = 123 # glutDeviceGet parameters.
  GLUT_HAS_KEYBOARD* = 600
  GLUT_HAS_MOUSE* = 601
  GLUT_HAS_SPACEBALL* = 602
  GLUT_HAS_DIAL_AND_BUTTON_BOX* = 603
  GLUT_HAS_TABLET* = 604
  GLUT_NUM_MOUSE_BUTTONS* = 605
  GLUT_NUM_SPACEBALL_BUTTONS* = 606
  GLUT_NUM_BUTTON_BOX_BUTTONS* = 607
  GLUT_NUM_DIALS* = 608
  GLUT_NUM_TABLET_BUTTONS* = 609
  GLUT_DEVICE_IGNORE_KEY_REPEAT* = 610
  GLUT_DEVICE_KEY_REPEAT* = 611
  GLUT_HAS_JOYSTICK* = 612
  GLUT_OWNS_JOYSTICK* = 613
  GLUT_JOYSTICK_BUTTONS* = 614
  GLUT_JOYSTICK_AXES* = 615
  GLUT_JOYSTICK_POLL_RATE* = 616 # glutLayerGet parameters.
  GLUT_OVERLAY_POSSIBLE* = 800
  GLUT_LAYER_IN_USE* = 801
  GLUT_HAS_OVERLAY* = 802
  GLUT_TRANSPARENT_INDEX* = 803
  GLUT_NORMAL_DAMAGED* = 804
  GLUT_OVERLAY_DAMAGED* = 805 # glutVideoResizeGet parameters.
  GLUT_VIDEO_RESIZE_POSSIBLE* = 900
  GLUT_VIDEO_RESIZE_IN_USE* = 901
  GLUT_VIDEO_RESIZE_X_DELTA* = 902
  GLUT_VIDEO_RESIZE_Y_DELTA* = 903
  GLUT_VIDEO_RESIZE_WIDTH_DELTA* = 904
  GLUT_VIDEO_RESIZE_HEIGHT_DELTA* = 905
  GLUT_VIDEO_RESIZE_X* = 906
  GLUT_VIDEO_RESIZE_Y* = 907
  GLUT_VIDEO_RESIZE_WIDTH* = 908
  GLUT_VIDEO_RESIZE_HEIGHT* = 909 # glutGetModifiers return mask.
  GLUT_ACTIVE_SHIFT* = 1
  GLUT_ACTIVE_CTRL* = 2
  GLUT_ACTIVE_ALT* = 4        # glutSetCursor parameters.
                              # Basic arrows.
  GLUT_CURSOR_RIGHT_ARROW* = 0
  GLUT_CURSOR_LEFT_ARROW* = 1 # Symbolic cursor shapes.
  GLUT_CURSOR_INFO* = 2
  GLUT_CURSOR_DESTROY* = 3
  GLUT_CURSOR_HELP* = 4
  GLUT_CURSOR_CYCLE* = 5
  GLUT_CURSOR_SPRAY* = 6
  GLUT_CURSOR_WAIT* = 7
  GLUT_CURSOR_TEXT* = 8
  GLUT_CURSOR_CROSSHAIR* = 9  # Directional cursors.
  GLUT_CURSOR_UP_DOWN* = 10
  GLUT_CURSOR_LEFT_RIGHT* = 11 # Sizing cursors.
  GLUT_CURSOR_TOP_SIDE* = 12
  GLUT_CURSOR_BOTTOM_SIDE* = 13
  GLUT_CURSOR_LEFT_SIDE* = 14
  GLUT_CURSOR_RIGHT_SIDE* = 15
  GLUT_CURSOR_TOP_LEFT_CORNER* = 16
  GLUT_CURSOR_TOP_RIGHT_CORNER* = 17
  GLUT_CURSOR_BOTTOM_RIGHT_CORNER* = 18
  GLUT_CURSOR_BOTTOM_LEFT_CORNER* = 19 # Inherit from parent window.
  GLUT_CURSOR_INHERIT* = 100  # Blank cursor.
  GLUT_CURSOR_NONE* = 101     # Fullscreen crosshair (if available).
  GLUT_CURSOR_FULL_CROSSHAIR* = 102 # GLUT device control sub-API.
                                    # glutSetKeyRepeat modes.
  GLUT_KEY_REPEAT_OFF* = 0
  GLUT_KEY_REPEAT_ON* = 1
  GLUT_KEY_REPEAT_DEFAULT* = 2 # Joystick button masks.
  GLUT_JOYSTICK_BUTTON_A* = 1
  GLUT_JOYSTICK_BUTTON_B* = 2
  GLUT_JOYSTICK_BUTTON_C* = 4
  GLUT_JOYSTICK_BUTTON_D* = 8 # GLUT game mode sub-API.
                              # glutGameModeGet.
  GLUT_GAME_MODE_ACTIVE* = 0
  GLUT_GAME_MODE_POSSIBLE* = 1
  GLUT_GAME_MODE_WIDTH* = 2
  GLUT_GAME_MODE_HEIGHT* = 3
  GLUT_GAME_MODE_PIXEL_DEPTH* = 4
  GLUT_GAME_MODE_REFRESH_RATE* = 5
  GLUT_GAME_MODE_DISPLAY_CHANGED* = 6 # GLUT initialization sub-API.

proc glutInit*(argcp: PInteger, argv: PPChar){.dynlib: dllname, importc.}
proc glutInitDisplayMode*(mode: int16){.dynlib: dllname, importc.}
proc glutInitDisplayString*(str: cstring){.dynlib: dllname, importc.}
proc glutInitWindowPosition*(x, y: int){.dynlib: dllname, importc.}
proc glutInitWindowSize*(width, height: int){.dynlib: dllname, importc.}
proc glutMainLoop*(){.dynlib: dllname, importc.}
  # GLUT window sub-API.
proc glutCreateWindow*(title: cstring): int{.dynlib: dllname, importc.}
proc glutCreateSubWindow*(win, x, y, width, height: int): int{.dynlib: dllname,
    importc.}
proc glutDestroyWindow*(win: int){.dynlib: dllname, importc.}
proc glutPostRedisplay*(){.dynlib: dllname, importc.}
proc glutPostWindowRedisplay*(win: int){.dynlib: dllname, importc.}
proc glutSwapBuffers*(){.dynlib: dllname, importc.}
proc glutGetWindow*(): int{.dynlib: dllname, importc.}
proc glutSetWindow*(win: int){.dynlib: dllname, importc.}
proc glutSetWindowTitle*(title: cstring){.dynlib: dllname, importc.}
proc glutSetIconTitle*(title: cstring){.dynlib: dllname, importc.}
proc glutPositionWindow*(x, y: int){.dynlib: dllname, importc.}
proc glutReshapeWindow*(width, height: int){.dynlib: dllname, importc.}
proc glutPopWindow*(){.dynlib: dllname, importc.}
proc glutPushWindow*(){.dynlib: dllname, importc.}
proc glutIconifyWindow*(){.dynlib: dllname, importc.}
proc glutShowWindow*(){.dynlib: dllname, importc.}
proc glutHideWindow*(){.dynlib: dllname, importc.}
proc glutFullScreen*(){.dynlib: dllname, importc.}
proc glutSetCursor*(cursor: int){.dynlib: dllname, importc.}
proc glutWarpPointer*(x, y: int){.dynlib: dllname, importc.}
  # GLUT overlay sub-API.
proc glutEstablishOverlay*(){.dynlib: dllname, importc.}
proc glutRemoveOverlay*(){.dynlib: dllname, importc.}
proc glutUseLayer*(layer: TGLenum){.dynlib: dllname, importc.}
proc glutPostOverlayRedisplay*(){.dynlib: dllname, importc.}
proc glutPostWindowOverlayRedisplay*(win: int){.dynlib: dllname, importc.}
proc glutShowOverlay*(){.dynlib: dllname, importc.}
proc glutHideOverlay*(){.dynlib: dllname, importc.}
  # GLUT menu sub-API.
proc glutCreateMenu*(callback: TGlut1IntCallback): int{.dynlib: dllname, importc.}
proc glutDestroyMenu*(menu: int){.dynlib: dllname, importc.}
proc glutGetMenu*(): int{.dynlib: dllname, importc.}
proc glutSetMenu*(menu: int){.dynlib: dllname, importc.}
proc glutAddMenuEntry*(caption: cstring, value: int){.dynlib: dllname, importc.}
proc glutAddSubMenu*(caption: cstring, submenu: int){.dynlib: dllname, importc.}
proc glutChangeToMenuEntry*(item: int, caption: cstring, value: int){.
    dynlib: dllname, importc.}
proc glutChangeToSubMenu*(item: int, caption: cstring, submenu: int){.
    dynlib: dllname, importc.}
proc glutRemoveMenuItem*(item: int){.dynlib: dllname, importc.}
proc glutAttachMenu*(button: int){.dynlib: dllname, importc.}
proc glutDetachMenu*(button: int){.dynlib: dllname, importc.}
  # GLUT window callback sub-API.
proc glutDisplayFunc*(f: TGlutVoidCallback){.dynlib: dllname, importc.}
proc glutReshapeFunc*(f: TGlut2IntCallback){.dynlib: dllname, importc.}
proc glutKeyboardFunc*(f: TGlut1Char2IntCallback){.dynlib: dllname, importc.}
proc glutMouseFunc*(f: TGlut4IntCallback){.dynlib: dllname, importc.}
proc glutMotionFunc*(f: TGlut2IntCallback){.dynlib: dllname, importc.}
proc glutPassiveMotionFunc*(f: TGlut2IntCallback){.dynlib: dllname, importc.}
proc glutEntryFunc*(f: TGlut1IntCallback){.dynlib: dllname, importc.}
proc glutVisibilityFunc*(f: TGlut1IntCallback){.dynlib: dllname, importc.}
proc glutIdleFunc*(f: TGlutVoidCallback){.dynlib: dllname, importc.}
proc glutTimerFunc*(millis: int16, f: TGlut1IntCallback, value: int){.
    dynlib: dllname, importc.}
proc glutMenuStateFunc*(f: TGlut1IntCallback){.dynlib: dllname, importc.}
proc glutSpecialFunc*(f: TGlut3IntCallback){.dynlib: dllname, importc.}
proc glutSpaceballMotionFunc*(f: TGlut3IntCallback){.dynlib: dllname, importc.}
proc glutSpaceballRotateFunc*(f: TGlut3IntCallback){.dynlib: dllname, importc.}
proc glutSpaceballButtonFunc*(f: TGlut2IntCallback){.dynlib: dllname, importc.}
proc glutButtonBoxFunc*(f: TGlut2IntCallback){.dynlib: dllname, importc.}
proc glutDialsFunc*(f: TGlut2IntCallback){.dynlib: dllname, importc.}
proc glutTabletMotionFunc*(f: TGlut2IntCallback){.dynlib: dllname, importc.}
proc glutTabletButtonFunc*(f: TGlut4IntCallback){.dynlib: dllname, importc.}
proc glutMenuStatusFunc*(f: TGlut3IntCallback){.dynlib: dllname, importc.}
proc glutOverlayDisplayFunc*(f: TGlutVoidCallback){.dynlib: dllname, importc.}
proc glutWindowStatusFunc*(f: TGlut1IntCallback){.dynlib: dllname, importc.}
proc glutKeyboardUpFunc*(f: TGlut1Char2IntCallback){.dynlib: dllname, importc.}
proc glutSpecialUpFunc*(f: TGlut3IntCallback){.dynlib: dllname, importc.}
proc glutJoystickFunc*(f: TGlut1UInt3IntCallback, pollInterval: int){.
    dynlib: dllname, importc.}
  # GLUT color index sub-API.
proc glutSetColor*(cell: int, red, green, blue: TGLfloat){.dynlib: dllname,
    importc.}
proc glutGetColor*(ndx, component: int): TGLfloat{.dynlib: dllname, importc.}
proc glutCopyColormap*(win: int){.dynlib: dllname, importc.}
  # GLUT state retrieval sub-API.
proc glutGet*(t: TGLenum): int{.dynlib: dllname, importc.}
proc glutDeviceGet*(t: TGLenum): int{.dynlib: dllname, importc.}
  # GLUT extension support sub-API
proc glutExtensionSupported*(name: cstring): int{.dynlib: dllname, importc.}
proc glutGetModifiers*(): int{.dynlib: dllname, importc.}
proc glutLayerGet*(t: TGLenum): int{.dynlib: dllname, importc.}
  # GLUT font sub-API
proc glutBitmapCharacter*(font: pointer, character: int){.dynlib: dllname,
    importc.}
proc glutBitmapWidth*(font: pointer, character: int): int{.dynlib: dllname,
    importc.}
proc glutStrokeCharacter*(font: pointer, character: int){.dynlib: dllname,
    importc.}
proc glutStrokeWidth*(font: pointer, character: int): int{.dynlib: dllname,
    importc.}
proc glutBitmapLength*(font: pointer, str: cstring): int{.dynlib: dllname,
    importc.}
proc glutStrokeLength*(font: pointer, str: cstring): int{.dynlib: dllname,
    importc.}
  # GLUT pre-built models sub-API
proc glutWireSphere*(radius: TGLdouble, slices, stacks: TGLint){.dynlib: dllname,
    importc.}
proc glutSolidSphere*(radius: TGLdouble, slices, stacks: TGLint){.dynlib: dllname,
    importc.}
proc glutWireCone*(base, height: TGLdouble, slices, stacks: TGLint){.
    dynlib: dllname, importc.}
proc glutSolidCone*(base, height: TGLdouble, slices, stacks: TGLint){.
    dynlib: dllname, importc.}
proc glutWireCube*(size: TGLdouble){.dynlib: dllname, importc.}
proc glutSolidCube*(size: TGLdouble){.dynlib: dllname, importc.}
proc glutWireTorus*(innerRadius, outerRadius: TGLdouble, sides, rings: TGLint){.
    dynlib: dllname, importc.}
proc glutSolidTorus*(innerRadius, outerRadius: TGLdouble, sides, rings: TGLint){.
    dynlib: dllname, importc.}
proc glutWireDodecahedron*(){.dynlib: dllname, importc.}
proc glutSolidDodecahedron*(){.dynlib: dllname, importc.}
proc glutWireTeapot*(size: TGLdouble){.dynlib: dllname, importc.}
proc glutSolidTeapot*(size: TGLdouble){.dynlib: dllname, importc.}
proc glutWireOctahedron*(){.dynlib: dllname, importc.}
proc glutSolidOctahedron*(){.dynlib: dllname, importc.}
proc glutWireTetrahedron*(){.dynlib: dllname, importc.}
proc glutSolidTetrahedron*(){.dynlib: dllname, importc.}
proc glutWireIcosahedron*(){.dynlib: dllname, importc.}
proc glutSolidIcosahedron*(){.dynlib: dllname, importc.}
  # GLUT video resize sub-API.
proc glutVideoResizeGet*(param: TGLenum): int{.dynlib: dllname, importc.}
proc glutSetupVideoResizing*(){.dynlib: dllname, importc.}
proc glutStopVideoResizing*(){.dynlib: dllname, importc.}
proc glutVideoResize*(x, y, width, height: int){.dynlib: dllname, importc.}
proc glutVideoPan*(x, y, width, height: int){.dynlib: dllname, importc.}
  # GLUT debugging sub-API.
proc glutReportErrors*(){.dynlib: dllname, importc.}
  # GLUT device control sub-API.
proc glutIgnoreKeyRepeat*(ignore: int){.dynlib: dllname, importc.}
proc glutSetKeyRepeat*(repeatMode: int){.dynlib: dllname, importc.}
proc glutForceJoystickFunc*(){.dynlib: dllname, importc.}
  # GLUT game mode sub-API.
  #example glutGameModeString('1280x1024:32@75');
proc glutGameModeString*(AString: cstring){.dynlib: dllname, importc.}
proc glutEnterGameMode*(): int{.dynlib: dllname, importc.}
proc glutLeaveGameMode*(){.dynlib: dllname, importc.}
proc glutGameModeGet*(mode: TGLenum): int{.dynlib: dllname, importc.}
# implementation
