{

  Translation of the Mesa GLX headers for FreePascal
  Copyright (C) 1999 Sebastian Guenther


  Mesa 3-D graphics library
  Version:  3.0
  Copyright (C) 1995-1998  Brian Paul

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Library General Public
  License as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Library General Public License for more details.

  You should have received a copy of the GNU Library General Public
  License along with this library; if not, write to the Free
  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
}

unit GLX;

interface

{$IFDEF Unix}
  uses
    X, XLib, XUtil, gl;
  {$DEFINE HasGLX}  // Activate GLX stuff
{$ELSE}
  {$MESSAGE Unsupported platform.}
{$ENDIF}

{$IFNDEF HasGLX}
  {$MESSAGE GLX not present on this platform.}
{$ENDIF}

const
  dylibname = '/usr/X11R6/lib/libGL.dylib';

// =======================================================
//   GLX consts, types and functions
// =======================================================

// Tokens for glXChooseVisual and glXGetConfig:
const
  GLX_USE_GL                            = 1;
  GLX_BUFFER_SIZE                       = 2;
  GLX_LEVEL                             = 3;
  GLX_RGBA                              = 4;
  GLX_DOUBLEBUFFER                      = 5;
  GLX_STEREO                            = 6;
  GLX_AUX_BUFFERS                       = 7;
  GLX_RED_SIZE                          = 8;
  GLX_GREEN_SIZE                        = 9;
  GLX_BLUE_SIZE                         = 10;
  GLX_ALPHA_SIZE                        = 11;
  GLX_DEPTH_SIZE                        = 12;
  GLX_STENCIL_SIZE                      = 13;
  GLX_ACCUM_RED_SIZE                    = 14;
  GLX_ACCUM_GREEN_SIZE                  = 15;
  GLX_ACCUM_BLUE_SIZE                   = 16;
  GLX_ACCUM_ALPHA_SIZE                  = 17;

  // GLX_EXT_visual_info extension
  GLX_X_VISUAL_TYPE_EXT                 = $22;
  GLX_TRANSPARENT_TYPE_EXT              = $23;
  GLX_TRANSPARENT_INDEX_VALUE_EXT       = $24;
  GLX_TRANSPARENT_RED_VALUE_EXT         = $25;
  GLX_TRANSPARENT_GREEN_VALUE_EXT       = $26;
  GLX_TRANSPARENT_BLUE_VALUE_EXT        = $27;
  GLX_TRANSPARENT_ALPHA_VALUE_EXT       = $28;


  // Error codes returned by glXGetConfig:
  GLX_BAD_SCREEN                        = 1;
  GLX_BAD_ATTRIBUTE                     = 2;
  GLX_NO_EXTENSION                      = 3;
  GLX_BAD_VISUAL                        = 4;
  GLX_BAD_CONTEXT                       = 5;
  GLX_BAD_VALUE                         = 6;
  GLX_BAD_ENUM                          = 7;

  // GLX 1.1 and later:
  GLX_VENDOR                            = 1;
  GLX_VERSION                           = 2;
  GLX_EXTENSIONS                        = 3;

  // GLX_visual_info extension
  GLX_TRUE_COLOR_EXT                    = $8002;
  GLX_DIRECT_COLOR_EXT                  = $8003;
  GLX_PSEUDO_COLOR_EXT                  = $8004;
  GLX_STATIC_COLOR_EXT                  = $8005;
  GLX_GRAY_SCALE_EXT                    = $8006;
  GLX_STATIC_GRAY_EXT                   = $8007;
  GLX_NONE_EXT                          = $8000;
  GLX_TRANSPARENT_RGB_EXT               = $8008;
  GLX_TRANSPARENT_INDEX_EXT             = $8009;

type
  // From XLib:
  XPixmap = TXID;
  XFont = TXID;
  XColormap = TXID;

  GLXContext = Pointer;
  GLXPixmap = TXID;
  GLXDrawable = TXID;
  GLXContextID = TXID;
  
  TXPixmap = XPixmap;
  TXFont = XFont;
  TXColormap = XColormap;

  TGLXContext = GLXContext;
  TGLXPixmap = GLXPixmap;
  TGLXDrawable = GLXDrawable;
  TGLXContextID = GLXContextID;

function glXChooseVisual(dpy: PDisplay; screen: Integer; attribList: PInteger): PXVisualInfo; cdecl; external dllname;
function glXCreateContext(dpy: PDisplay; vis: PXVisualInfo; shareList: GLXContext; direct: Boolean): GLXContext; cdecl; external dllname;
procedure glXDestroyContext(dpy: PDisplay; ctx: GLXContext); cdecl; external dllname;
function glXMakeCurrent(dpy: PDisplay; drawable: GLXDrawable; ctx: GLXContext): Boolean; cdecl; external dllname;
procedure glXCopyContext(dpy: PDisplay; src, dst: GLXContext; mask: LongWord); cdecl; external dllname;
procedure glXSwapBuffers(dpy: PDisplay; drawable: GLXDrawable); cdecl; external dllname;
function glXCreateGLXPixmap(dpy: PDisplay; visual: PXVisualInfo; pixmap: XPixmap): GLXPixmap; cdecl; external dllname;
procedure glXDestroyGLXPixmap(dpy: PDisplay; pixmap: GLXPixmap); cdecl; external dllname;
function glXQueryExtension(dpy: PDisplay; var errorb, event: Integer): Boolean; cdecl; external dllname;
function glXQueryVersion(dpy: PDisplay; var maj, min: Integer): Boolean; cdecl; external dllname;
function glXIsDirect(dpy: PDisplay; ctx: GLXContext): Boolean; cdecl; external dllname;
function glXGetConfig(dpy: PDisplay; visual: PXVisualInfo; attrib: Integer; var value: Integer): Integer; cdecl; external dllname;
function glXGetCurrentContext: GLXContext; cdecl; external dllname;
function glXGetCurrentDrawable: GLXDrawable; cdecl; external dllname;
procedure glXWaitGL; cdecl; external dllname;
procedure glXWaitX; cdecl; external dllname;
procedure glXUseXFont(font: XFont; first, count, list: Integer); cdecl; external dllname;

// GLX 1.1 and later
function glXQueryExtensionsString(dpy: PDisplay; screen: Integer): PChar; cdecl; external dllname;
function glXQueryServerString(dpy: PDisplay; screen, name: Integer): PChar; cdecl; external dllname;
function glXGetClientString(dpy: PDisplay; name: Integer): PChar; cdecl; external dllname;

// Mesa GLX Extensions
function glXCreateGLXPixmapMESA(dpy: PDisplay; visual: PXVisualInfo; pixmap: XPixmap; cmap: XColormap): GLXPixmap; cdecl; external dllname;
function glXReleaseBufferMESA(dpy: PDisplay; d: GLXDrawable): Boolean; cdecl; external dllname;
procedure glXCopySubBufferMESA(dpy: PDisplay; drawbale: GLXDrawable; x, y, width, height: Integer); cdecl; external dllname;
function glXGetVideoSyncSGI(var counter: LongWord): Integer; cdecl; external dllname;
function glXWaitVideoSyncSGI(divisor, remainder: Integer; var count: LongWord): Integer; cdecl; external dllname;

implementation

end.
