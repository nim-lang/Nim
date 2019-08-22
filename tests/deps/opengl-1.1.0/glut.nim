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

import opengl

{.deadCodeElim: on.}

when defined(windows):
  const
    dllname = "glut32.dll"
elif defined(macosx):
  const
    dllname = "/System/Library/Frameworks/GLUT.framework/GLUT"
else:
  const
    dllname = "libglut.so.3"
type
  TGlutVoidCallback* = proc (){.cdecl.}
  TGlut1IntCallback* = proc (value: cint){.cdecl.}
  TGlut2IntCallback* = proc (v1, v2: cint){.cdecl.}
  TGlut3IntCallback* = proc (v1, v2, v3: cint){.cdecl.}
  TGlut4IntCallback* = proc (v1, v2, v3, v4: cint){.cdecl.}
  TGlut1Char2IntCallback* = proc (c: int8, v1, v2: cint){.cdecl.}
  TGlut1UInt3IntCallback* = proc (u, v1, v2, v3: cint){.cdecl.}

{.deprecated: [Pointer: pointer].}

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
    GLUT_STROKE_ROMAN* = cast[pointer](0)
    GLUT_STROKE_MONO_ROMAN* = cast[pointer](1) # Bitmap font constants (use these in GLUT program).
    GLUT_BITMAP_9_BY_15* = cast[pointer](2)
    GLUT_BITMAP_8_BY_13* = cast[pointer](3)
    GLUT_BITMAP_TIMES_ROMAN_10* = cast[pointer](4)
    GLUT_BITMAP_TIMES_ROMAN_24* = cast[pointer](5)
    GLUT_BITMAP_HELVETICA_10* = cast[pointer](6)
    GLUT_BITMAP_HELVETICA_12* = cast[pointer](7)
    GLUT_BITMAP_HELVETICA_18* = cast[pointer](8)
else:
  var                         # Stroke font constants (use these in GLUT program).
    GLUT_STROKE_ROMAN*: pointer
    GLUT_STROKE_MONO_ROMAN*: pointer # Bitmap font constants (use these in GLUT program).
    GLUT_BITMAP_9_BY_15*: pointer
    GLUT_BITMAP_8_BY_13*: pointer
    GLUT_BITMAP_TIMES_ROMAN_10*: pointer
    GLUT_BITMAP_TIMES_ROMAN_24*: pointer
    GLUT_BITMAP_HELVETICA_10*: pointer
    GLUT_BITMAP_HELVETICA_12*: pointer
    GLUT_BITMAP_HELVETICA_18*: pointer
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

{.push dynlib: dllname, importc.}
proc glutInit*(argcp: ptr cint, argv: pointer)

proc glutInit*() =
  ## version that passes `argc` and `argc` implicitely.
  var
    cmdLine {.importc: "cmdLine".}: array[0..255, cstring]
    cmdCount {.importc: "cmdCount".}: cint
  glutInit(addr(cmdCount), addr(cmdLine))

proc glutInitDisplayMode*(mode: int16)
proc glutInitDisplayString*(str: cstring)
proc glutInitWindowPosition*(x, y: int)
proc glutInitWindowSize*(width, height: int)
proc glutMainLoop*()
  # GLUT window sub-API.
proc glutCreateWindow*(title: cstring): int
proc glutCreateSubWindow*(win, x, y, width, height: int): int
proc glutDestroyWindow*(win: int)
proc glutPostRedisplay*()
proc glutPostWindowRedisplay*(win: int)
proc glutSwapBuffers*()
proc glutSetWindow*(win: int)
proc glutSetWindowTitle*(title: cstring)
proc glutSetIconTitle*(title: cstring)
proc glutPositionWindow*(x, y: int)
proc glutReshapeWindow*(width, height: int)
proc glutPopWindow*()
proc glutPushWindow*()
proc glutIconifyWindow*()
proc glutShowWindow*()
proc glutHideWindow*()
proc glutFullScreen*()
proc glutSetCursor*(cursor: int)
proc glutWarpPointer*(x, y: int)
  # GLUT overlay sub-API.
proc glutEstablishOverlay*()
proc glutRemoveOverlay*()
proc glutUseLayer*(layer: GLenum)
proc glutPostOverlayRedisplay*()
proc glutPostWindowOverlayRedisplay*(win: int)
proc glutShowOverlay*()
proc glutHideOverlay*()
  # GLUT menu sub-API.
proc glutCreateMenu*(callback: TGlut1IntCallback): int
proc glutDestroyMenu*(menu: int)
proc glutSetMenu*(menu: int)
proc glutAddMenuEntry*(caption: cstring, value: int)
proc glutAddSubMenu*(caption: cstring, submenu: int)
proc glutChangeToMenuEntry*(item: int, caption: cstring, value: int)
proc glutChangeToSubMenu*(item: int, caption: cstring, submenu: int)
proc glutRemoveMenuItem*(item: int)
proc glutAttachMenu*(button: int)
proc glutDetachMenu*(button: int)
  # GLUT window callback sub-API.
proc glutDisplayFunc*(f: TGlutVoidCallback)
proc glutReshapeFunc*(f: TGlut2IntCallback)
proc glutKeyboardFunc*(f: TGlut1Char2IntCallback)
proc glutMouseFunc*(f: TGlut4IntCallback)
proc glutMotionFunc*(f: TGlut2IntCallback)
proc glutPassiveMotionFunc*(f: TGlut2IntCallback)
proc glutEntryFunc*(f: TGlut1IntCallback)
proc glutVisibilityFunc*(f: TGlut1IntCallback)
proc glutIdleFunc*(f: TGlutVoidCallback)
proc glutTimerFunc*(millis: int16, f: TGlut1IntCallback, value: int)
proc glutMenuStateFunc*(f: TGlut1IntCallback)
proc glutSpecialFunc*(f: TGlut3IntCallback)
proc glutSpaceballMotionFunc*(f: TGlut3IntCallback)
proc glutSpaceballRotateFunc*(f: TGlut3IntCallback)
proc glutSpaceballButtonFunc*(f: TGlut2IntCallback)
proc glutButtonBoxFunc*(f: TGlut2IntCallback)
proc glutDialsFunc*(f: TGlut2IntCallback)
proc glutTabletMotionFunc*(f: TGlut2IntCallback)
proc glutTabletButtonFunc*(f: TGlut4IntCallback)
proc glutMenuStatusFunc*(f: TGlut3IntCallback)
proc glutOverlayDisplayFunc*(f: TGlutVoidCallback)
proc glutWindowStatusFunc*(f: TGlut1IntCallback)
proc glutKeyboardUpFunc*(f: TGlut1Char2IntCallback)
proc glutSpecialUpFunc*(f: TGlut3IntCallback)
proc glutJoystickFunc*(f: TGlut1UInt3IntCallback, pollInterval: int)
  # GLUT color index sub-API.
proc glutSetColor*(cell: int, red, green, blue: GLfloat)
proc glutGetColor*(ndx, component: int): GLfloat
proc glutCopyColormap*(win: int)
  # GLUT state retrieval sub-API.
  # GLUT extension support sub-API
proc glutExtensionSupported*(name: cstring): int
  # GLUT font sub-API
proc glutBitmapCharacter*(font: pointer, character: int)
proc glutBitmapWidth*(font: pointer, character: int): int
proc glutStrokeCharacter*(font: pointer, character: int)
proc glutStrokeWidth*(font: pointer, character: int): int
proc glutBitmapLength*(font: pointer, str: cstring): int
proc glutStrokeLength*(font: pointer, str: cstring): int
  # GLUT pre-built models sub-API
proc glutWireSphere*(radius: GLdouble, slices, stacks: GLint)
proc glutSolidSphere*(radius: GLdouble, slices, stacks: GLint)
proc glutWireCone*(base, height: GLdouble, slices, stacks: GLint)
proc glutSolidCone*(base, height: GLdouble, slices, stacks: GLint)
proc glutWireCube*(size: GLdouble)
proc glutSolidCube*(size: GLdouble)
proc glutWireTorus*(innerRadius, outerRadius: GLdouble, sides, rings: GLint)
proc glutSolidTorus*(innerRadius, outerRadius: GLdouble, sides, rings: GLint)
proc glutWireDodecahedron*()
proc glutSolidDodecahedron*()
proc glutWireTeapot*(size: GLdouble)
proc glutSolidTeapot*(size: GLdouble)
proc glutWireOctahedron*()
proc glutSolidOctahedron*()
proc glutWireTetrahedron*()
proc glutSolidTetrahedron*()
proc glutWireIcosahedron*()
proc glutSolidIcosahedron*()
  # GLUT video resize sub-API.
proc glutVideoResizeGet*(param: GLenum): int
proc glutSetupVideoResizing*()
proc glutStopVideoResizing*()
proc glutVideoResize*(x, y, width, height: int)
proc glutVideoPan*(x, y, width, height: int)
  # GLUT debugging sub-API.
proc glutReportErrors*()
  # GLUT device control sub-API.
proc glutIgnoreKeyRepeat*(ignore: int)
proc glutSetKeyRepeat*(repeatMode: int)
proc glutForceJoystickFunc*()
  # GLUT game mode sub-API.
  #example glutGameModeString('1280x1024:32@75');
proc glutGameModeString*(AString: cstring)
proc glutLeaveGameMode*()
proc glutGameModeGet*(mode: GLenum): int
# implementation
{.pop.} # dynlib: dllname, importc
