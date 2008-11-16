{

  Adaption of the delphi3d.net OpenGL units to FreePascal
  Sebastian Guenther (sg@freepascal.org) in 2002
  These units are free to use
}

unit Glut;

// Copyright (c) Mark J. Kilgard, 1994, 1995, 1996. */

(* This program is freely distributable without licensing fees  and is
   provided without guarantee or warrantee expressed or  implied. This
   program is -not- in the public domain. *)

{******************************************************************************}
{ Converted to Delphi by Tom Nuydens (tom@delphi3d.net)                        }
{   Contributions by Igor Karpov (glygrik@hotbox.ru)                           }
{   For the latest updates, visit Delphi3D: http://www.delphi3d.net            }
{******************************************************************************}

interface

uses
  GL;
  
const
  dllname = 'glut32.dll';
  dynlibname = '/System/Library/Frameworks/GLUT.framework/GLUT';
  libname = 'libglut.so.3';

type
  PInteger = ^Integer;
  PPChar = ^PChar;
  TGlutVoidCallback = procedure; cdecl;
  TGlut1IntCallback = procedure(value: Integer); cdecl;
  TGlut2IntCallback = procedure(v1, v2: Integer); cdecl;
  TGlut3IntCallback = procedure(v1, v2, v3: Integer); cdecl;
  TGlut4IntCallback = procedure(v1, v2, v3, v4: Integer); cdecl;
  TGlut1Char2IntCallback = procedure(c: Byte; v1, v2: Integer); cdecl;
  TGlut1UInt3IntCallback = procedure(u: Cardinal; v1, v2, v3: Integer); cdecl;

const
  GLUT_API_VERSION                = 3;
  GLUT_XLIB_IMPLEMENTATION        = 12;
  // Display mode bit masks.
  GLUT_RGB                        = 0;
  GLUT_RGBA                       = GLUT_RGB;
  GLUT_INDEX                      = 1;
  GLUT_SINGLE                     = 0;
  GLUT_DOUBLE                     = 2;
  GLUT_ACCUM                      = 4;
  GLUT_ALPHA                      = 8;
  GLUT_DEPTH                      = 16;
  GLUT_STENCIL                    = 32;
  GLUT_MULTISAMPLE                = 128;
  GLUT_STEREO                     = 256;
  GLUT_LUMINANCE                  = 512;

  // Mouse buttons.
  GLUT_LEFT_BUTTON                = 0;
  GLUT_MIDDLE_BUTTON              = 1;
  GLUT_RIGHT_BUTTON               = 2;

  // Mouse button state.
  GLUT_DOWN                       = 0;
  GLUT_UP                         = 1;

  // function keys
  GLUT_KEY_F1                     = 1;
  GLUT_KEY_F2                     = 2;
  GLUT_KEY_F3                     = 3;
  GLUT_KEY_F4                     = 4;
  GLUT_KEY_F5                     = 5;
  GLUT_KEY_F6                     = 6;
  GLUT_KEY_F7                     = 7;
  GLUT_KEY_F8                     = 8;
  GLUT_KEY_F9                     = 9;
  GLUT_KEY_F10                    = 10;
  GLUT_KEY_F11                    = 11;
  GLUT_KEY_F12                    = 12;
  // directional keys
  GLUT_KEY_LEFT                   = 100;
  GLUT_KEY_UP                     = 101;
  GLUT_KEY_RIGHT                  = 102;
  GLUT_KEY_DOWN                   = 103;
  GLUT_KEY_PAGE_UP                = 104;
  GLUT_KEY_PAGE_DOWN              = 105;
  GLUT_KEY_HOME                   = 106;
  GLUT_KEY_END                    = 107;
  GLUT_KEY_INSERT                 = 108;

  // Entry/exit  state.
  GLUT_LEFT                       = 0;
  GLUT_ENTERED                    = 1;

  // Menu usage state.
  GLUT_MENU_NOT_IN_USE            = 0;
  GLUT_MENU_IN_USE                = 1;

  // Visibility  state.
  GLUT_NOT_VISIBLE                = 0;
  GLUT_VISIBLE                    = 1;

  // Window status  state.
  GLUT_HIDDEN                     = 0;
  GLUT_FULLY_RETAINED             = 1;
  GLUT_PARTIALLY_RETAINED         = 2;
  GLUT_FULLY_COVERED              = 3;

  // Color index component selection values.
  GLUT_RED                        = 0;
  GLUT_GREEN                      = 1;
  GLUT_BLUE                       = 2;

  // Layers for use.
  GLUT_NORMAL                     = 0;
  GLUT_OVERLAY                    = 1;

{$ifdef Windows}
const
  // Stroke font constants (use these in GLUT program).
  GLUT_STROKE_ROMAN               = Pointer(0);
  GLUT_STROKE_MONO_ROMAN          = Pointer(1);

  // Bitmap font constants (use these in GLUT program).
  GLUT_BITMAP_9_BY_15             = Pointer(2);
  GLUT_BITMAP_8_BY_13             = Pointer(3);
  GLUT_BITMAP_TIMES_ROMAN_10      = Pointer(4);
  GLUT_BITMAP_TIMES_ROMAN_24      = Pointer(5);
  GLUT_BITMAP_HELVETICA_10        = Pointer(6);
  GLUT_BITMAP_HELVETICA_12        = Pointer(7);
  GLUT_BITMAP_HELVETICA_18        = Pointer(8);
{$else Windows}
var
  // Stroke font constants (use these in GLUT program).
  GLUT_STROKE_ROMAN               : Pointer;
  GLUT_STROKE_MONO_ROMAN          : Pointer;

  // Bitmap font constants (use these in GLUT program).
  GLUT_BITMAP_9_BY_15             : Pointer;
  GLUT_BITMAP_8_BY_13             : Pointer;
  GLUT_BITMAP_TIMES_ROMAN_10      : Pointer;
  GLUT_BITMAP_TIMES_ROMAN_24      : Pointer;
  GLUT_BITMAP_HELVETICA_10        : Pointer;
  GLUT_BITMAP_HELVETICA_12        : Pointer;
  GLUT_BITMAP_HELVETICA_18        : Pointer;
{$endif Windows}
const
  // glutGet parameters.
  GLUT_WINDOW_X                   = 100;
  GLUT_WINDOW_Y                   = 101;
  GLUT_WINDOW_WIDTH               = 102;
  GLUT_WINDOW_HEIGHT              = 103;
  GLUT_WINDOW_BUFFER_SIZE         = 104;
  GLUT_WINDOW_STENCIL_SIZE        = 105;
  GLUT_WINDOW_DEPTH_SIZE          = 106;
  GLUT_WINDOW_RED_SIZE            = 107;
  GLUT_WINDOW_GREEN_SIZE          = 108;
  GLUT_WINDOW_BLUE_SIZE           = 109;
  GLUT_WINDOW_ALPHA_SIZE          = 110;
  GLUT_WINDOW_ACCUM_RED_SIZE      = 111;
  GLUT_WINDOW_ACCUM_GREEN_SIZE    = 112;
  GLUT_WINDOW_ACCUM_BLUE_SIZE     = 113;
  GLUT_WINDOW_ACCUM_ALPHA_SIZE    = 114;
  GLUT_WINDOW_DOUBLEBUFFER        = 115;
  GLUT_WINDOW_RGBA                = 116;
  GLUT_WINDOW_PARENT              = 117;
  GLUT_WINDOW_NUM_CHILDREN        = 118;
  GLUT_WINDOW_COLORMAP_SIZE       = 119;
  GLUT_WINDOW_NUM_SAMPLES         = 120;
  GLUT_WINDOW_STEREO              = 121;
  GLUT_WINDOW_CURSOR              = 122;
  GLUT_SCREEN_WIDTH               = 200;
  GLUT_SCREEN_HEIGHT              = 201;
  GLUT_SCREEN_WIDTH_MM            = 202;
  GLUT_SCREEN_HEIGHT_MM           = 203;
  GLUT_MENU_NUM_ITEMS             = 300;
  GLUT_DISPLAY_MODE_POSSIBLE      = 400;
  GLUT_INIT_WINDOW_X              = 500;
  GLUT_INIT_WINDOW_Y              = 501;
  GLUT_INIT_WINDOW_WIDTH          = 502;
  GLUT_INIT_WINDOW_HEIGHT         = 503;
  GLUT_INIT_DISPLAY_MODE          = 504;
  GLUT_ELAPSED_TIME               = 700;
  GLUT_WINDOW_FORMAT_ID		  = 123;

  // glutDeviceGet parameters.
  GLUT_HAS_KEYBOARD               = 600;
  GLUT_HAS_MOUSE                  = 601;
  GLUT_HAS_SPACEBALL              = 602;
  GLUT_HAS_DIAL_AND_BUTTON_BOX    = 603;
  GLUT_HAS_TABLET                 = 604;
  GLUT_NUM_MOUSE_BUTTONS          = 605;
  GLUT_NUM_SPACEBALL_BUTTONS      = 606;
  GLUT_NUM_BUTTON_BOX_BUTTONS     = 607;
  GLUT_NUM_DIALS                  = 608;
  GLUT_NUM_TABLET_BUTTONS         = 609;
  GLUT_DEVICE_IGNORE_KEY_REPEAT   = 610;
  GLUT_DEVICE_KEY_REPEAT          = 611;
  GLUT_HAS_JOYSTICK               = 612;
  GLUT_OWNS_JOYSTICK              = 613;
  GLUT_JOYSTICK_BUTTONS           = 614;
  GLUT_JOYSTICK_AXES              = 615;
  GLUT_JOYSTICK_POLL_RATE         = 616;


  // glutLayerGet parameters.
  GLUT_OVERLAY_POSSIBLE           = 800;
  GLUT_LAYER_IN_USE               = 801;
  GLUT_HAS_OVERLAY                = 802;
  GLUT_TRANSPARENT_INDEX          = 803;
  GLUT_NORMAL_DAMAGED             = 804;
  GLUT_OVERLAY_DAMAGED            = 805;

  // glutVideoResizeGet parameters.
  GLUT_VIDEO_RESIZE_POSSIBLE       = 900;
  GLUT_VIDEO_RESIZE_IN_USE         = 901;
  GLUT_VIDEO_RESIZE_X_DELTA        = 902;
  GLUT_VIDEO_RESIZE_Y_DELTA        = 903;
  GLUT_VIDEO_RESIZE_WIDTH_DELTA    = 904;
  GLUT_VIDEO_RESIZE_HEIGHT_DELTA   = 905;
  GLUT_VIDEO_RESIZE_X              = 906;
  GLUT_VIDEO_RESIZE_Y              = 907;
  GLUT_VIDEO_RESIZE_WIDTH          = 908;
  GLUT_VIDEO_RESIZE_HEIGHT         = 909;

  // glutGetModifiers return mask.
  GLUT_ACTIVE_SHIFT                = 1;
  GLUT_ACTIVE_CTRL                 = 2;
  GLUT_ACTIVE_ALT                  = 4;

  // glutSetCursor parameters.
  // Basic arrows.
  GLUT_CURSOR_RIGHT_ARROW          = 0;
  GLUT_CURSOR_LEFT_ARROW           = 1;
  // Symbolic cursor shapes.
  GLUT_CURSOR_INFO                 = 2;
  GLUT_CURSOR_DESTROY              = 3;
  GLUT_CURSOR_HELP                 = 4;
  GLUT_CURSOR_CYCLE                = 5;
  GLUT_CURSOR_SPRAY                = 6;
  GLUT_CURSOR_WAIT                 = 7;
  GLUT_CURSOR_TEXT                 = 8;
  GLUT_CURSOR_CROSSHAIR            = 9;
  // Directional cursors.
  GLUT_CURSOR_UP_DOWN              = 10;
  GLUT_CURSOR_LEFT_RIGHT           = 11;
  // Sizing cursors.
  GLUT_CURSOR_TOP_SIDE             = 12;
  GLUT_CURSOR_BOTTOM_SIDE          = 13;
  GLUT_CURSOR_LEFT_SIDE            = 14;
  GLUT_CURSOR_RIGHT_SIDE           = 15;
  GLUT_CURSOR_TOP_LEFT_CORNER      = 16;
  GLUT_CURSOR_TOP_RIGHT_CORNER     = 17;
  GLUT_CURSOR_BOTTOM_RIGHT_CORNER  = 18;
  GLUT_CURSOR_BOTTOM_LEFT_CORNER   = 19;
  // Inherit from parent window.
  GLUT_CURSOR_INHERIT              = 100;
  // Blank cursor.
  GLUT_CURSOR_NONE                 = 101;
  // Fullscreen crosshair (if available).
  GLUT_CURSOR_FULL_CROSSHAIR       = 102;

  // GLUT device control sub-API.
  // glutSetKeyRepeat modes.
  GLUT_KEY_REPEAT_OFF      = 0;
  GLUT_KEY_REPEAT_ON       = 1;
  GLUT_KEY_REPEAT_DEFAULT  = 2;

// Joystick button masks.
  GLUT_JOYSTICK_BUTTON_A = 1;
  GLUT_JOYSTICK_BUTTON_B = 2;
  GLUT_JOYSTICK_BUTTON_C = 4;
  GLUT_JOYSTICK_BUTTON_D = 8;

  // GLUT game mode sub-API.
  // glutGameModeGet.
  GLUT_GAME_MODE_ACTIVE           = 0;
  GLUT_GAME_MODE_POSSIBLE         = 1;
  GLUT_GAME_MODE_WIDTH            = 2;
  GLUT_GAME_MODE_HEIGHT           = 3;
  GLUT_GAME_MODE_PIXEL_DEPTH      = 4;
  GLUT_GAME_MODE_REFRESH_RATE     = 5;
  GLUT_GAME_MODE_DISPLAY_CHANGED  = 6;


// GLUT initialization sub-API.
  procedure glutInit(argcp: PInteger; argv: PPChar); external dllname;
  procedure glutInitDisplayMode(mode: Word); external dllname;
  procedure glutInitDisplayString(const str: PChar); external dllname;
  procedure glutInitWindowPosition(x, y: Integer); external dllname;
  procedure glutInitWindowSize(width, height: Integer); external dllname;
  procedure glutMainLoop; external dllname;

// GLUT window sub-API.
  function glutCreateWindow(const title: PChar): Integer; external dllname;
  function glutCreateSubWindow(win, x, y, width, height: Integer): Integer; external dllname;
  procedure glutDestroyWindow(win: Integer); external dllname;
  procedure glutPostRedisplay; external dllname;
  procedure glutPostWindowRedisplay(win: Integer); external dllname;
  procedure glutSwapBuffers; external dllname;
  function glutGetWindow: Integer; external dllname;
  procedure glutSetWindow(win: Integer); external dllname;
  procedure glutSetWindowTitle(const title: PChar); external dllname;
  procedure glutSetIconTitle(const title: PChar); external dllname;
  procedure glutPositionWindow(x, y: Integer); external dllname;
  procedure glutReshapeWindow(width, height: Integer); external dllname;
  procedure glutPopWindow; external dllname;
  procedure glutPushWindow; external dllname;
  procedure glutIconifyWindow; external dllname;
  procedure glutShowWindow; external dllname;
  procedure glutHideWindow; external dllname;
  procedure glutFullScreen; external dllname;
  procedure glutSetCursor(cursor: Integer); external dllname;
  procedure glutWarpPointer(x, y: Integer); external dllname;

// GLUT overlay sub-API.
  procedure glutEstablishOverlay; external dllname;
  procedure glutRemoveOverlay; external dllname;
  procedure glutUseLayer(layer: GLenum); external dllname;
  procedure glutPostOverlayRedisplay; external dllname;
  procedure glutPostWindowOverlayRedisplay(win: Integer); external dllname;
  procedure glutShowOverlay; external dllname;
  procedure glutHideOverlay; external dllname;

// GLUT menu sub-API.
  function glutCreateMenu(callback: TGlut1IntCallback): Integer; external dllname;
  procedure glutDestroyMenu(menu: Integer); external dllname;
  function glutGetMenu: Integer; external dllname;
  procedure glutSetMenu(menu: Integer); external dllname;
  procedure glutAddMenuEntry(const caption: PChar; value: Integer); external dllname;
  procedure glutAddSubMenu(const caption: PChar; submenu: Integer); external dllname;
  procedure glutChangeToMenuEntry(item: Integer; const caption: PChar; value: Integer); external dllname;
  procedure glutChangeToSubMenu(item: Integer; const caption: PChar; submenu: Integer); external dllname;
  procedure glutRemoveMenuItem(item: Integer); external dllname;
  procedure glutAttachMenu(button: Integer); external dllname;
  procedure glutDetachMenu(button: Integer); external dllname;

// GLUT window callback sub-API.
  procedure glutDisplayFunc(f: TGlutVoidCallback); external dllname;
  procedure glutReshapeFunc(f: TGlut2IntCallback); external dllname;
  procedure glutKeyboardFunc(f: TGlut1Char2IntCallback); external dllname;
  procedure glutMouseFunc(f: TGlut4IntCallback); external dllname;
  procedure glutMotionFunc(f: TGlut2IntCallback); external dllname;
  procedure glutPassiveMotionFunc(f: TGlut2IntCallback); external dllname;
  procedure glutEntryFunc(f: TGlut1IntCallback); external dllname;
  procedure glutVisibilityFunc(f: TGlut1IntCallback); external dllname;
  procedure glutIdleFunc(f: TGlutVoidCallback); external dllname;
  procedure glutTimerFunc(millis: Word; f: TGlut1IntCallback; value: Integer); external dllname;
  procedure glutMenuStateFunc(f: TGlut1IntCallback); external dllname;
  procedure glutSpecialFunc(f: TGlut3IntCallback); external dllname;
  procedure glutSpaceballMotionFunc(f: TGlut3IntCallback); external dllname;
  procedure glutSpaceballRotateFunc(f: TGlut3IntCallback); external dllname;
  procedure glutSpaceballButtonFunc(f: TGlut2IntCallback); external dllname;
  procedure glutButtonBoxFunc(f: TGlut2IntCallback); external dllname;
  procedure glutDialsFunc(f: TGlut2IntCallback); external dllname;
  procedure glutTabletMotionFunc(f: TGlut2IntCallback); external dllname;
  procedure glutTabletButtonFunc(f: TGlut4IntCallback); external dllname;
  procedure glutMenuStatusFunc(f: TGlut3IntCallback); external dllname;
  procedure glutOverlayDisplayFunc(f:TGlutVoidCallback); external dllname;
  procedure glutWindowStatusFunc(f: TGlut1IntCallback); external dllname;
  procedure glutKeyboardUpFunc(f: TGlut1Char2IntCallback); external dllname;
  procedure glutSpecialUpFunc(f: TGlut3IntCallback); external dllname;
  procedure glutJoystickFunc(f: TGlut1UInt3IntCallback; pollInterval: Integer); external dllname;

// GLUT color index sub-API.
  procedure glutSetColor(cell: Integer; red, green, blue: GLfloat); external dllname;
  function glutGetColor(ndx, component: Integer): GLfloat; external dllname;
  procedure glutCopyColormap(win: Integer); external dllname;

// GLUT state retrieval sub-API.
  function glutGet(t: GLenum): Integer; external dllname;
  function glutDeviceGet(t: GLenum): Integer; external dllname;

// GLUT extension support sub-API
  function glutExtensionSupported(const name: PChar): Integer; external dllname;
  function glutGetModifiers: Integer; external dllname;
  function glutLayerGet(t: GLenum): Integer; external dllname;

// GLUT font sub-API
  procedure glutBitmapCharacter(font : pointer; character: Integer); external dllname;
  function glutBitmapWidth(font : pointer; character: Integer): Integer; external dllname;
  procedure glutStrokeCharacter(font : pointer; character: Integer); external dllname;
  function glutStrokeWidth(font : pointer; character: Integer): Integer; external dllname;
  function glutBitmapLength(font: pointer; const str: PChar): Integer; external dllname;
  function glutStrokeLength(font: pointer; const str: PChar): Integer; external dllname;

// GLUT pre-built models sub-API
  procedure glutWireSphere(radius: GLdouble; slices, stacks: GLint); external dllname;
  procedure glutSolidSphere(radius: GLdouble; slices, stacks: GLint); external dllname;
  procedure glutWireCone(base, height: GLdouble; slices, stacks: GLint); external dllname;
  procedure glutSolidCone(base, height: GLdouble; slices, stacks: GLint); external dllname;
  procedure glutWireCube(size: GLdouble); external dllname;
  procedure glutSolidCube(size: GLdouble); external dllname;
  procedure glutWireTorus(innerRadius, outerRadius: GLdouble; sides, rings: GLint); external dllname;
  procedure glutSolidTorus(innerRadius, outerRadius: GLdouble; sides, rings: GLint); external dllname;
  procedure glutWireDodecahedron; external dllname;
  procedure glutSolidDodecahedron; external dllname;
  procedure glutWireTeapot(size: GLdouble); external dllname;
  procedure glutSolidTeapot(size: GLdouble); external dllname;
  procedure glutWireOctahedron; external dllname;
  procedure glutSolidOctahedron; external dllname;
  procedure glutWireTetrahedron; external dllname;
  procedure glutSolidTetrahedron; external dllname;
  procedure glutWireIcosahedron; external dllname;
  procedure glutSolidIcosahedron; external dllname;

// GLUT video resize sub-API.
  function glutVideoResizeGet(param: GLenum): Integer; external dllname;
  procedure glutSetupVideoResizing; external dllname;
  procedure glutStopVideoResizing; external dllname;
  procedure glutVideoResize(x, y, width, height: Integer); external dllname;
  procedure glutVideoPan(x, y, width, height: Integer); external dllname;

// GLUT debugging sub-API.
  procedure glutReportErrors; external dllname;

// GLUT device control sub-API.

  procedure glutIgnoreKeyRepeat(ignore: Integer); external dllname;
  procedure glutSetKeyRepeat(repeatMode: Integer); external dllname;
  procedure glutForceJoystickFunc; external dllname;

// GLUT game mode sub-API.

  //example glutGameModeString('1280x1024:32@75');
  procedure glutGameModeString (const AString : PChar); external dllname;
  function glutEnterGameMode : integer; external dllname;
  procedure glutLeaveGameMode; external dllname;
  function glutGameModeGet (mode : GLenum) : integer; external dllname;


implementation

end.
