#
#
#  Translation of the Mesa GLX headers for FreePascal
#  Copyright (C) 1999 Sebastian Guenther
#
#
#  Mesa 3-D graphics library
#  Version:  3.0
#  Copyright (C) 1995-1998  Brian Paul
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the Free
#  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

import
  X, XLib, XUtil, gl

when defined(windows):
  const
    dllname = "GL.dll"
elif defined(macosx):
  const
    dllname = "/usr/X11R6/lib/libGL.dylib"
else:
  const
    dllname = "libGL.so"
const
  GLX_USE_GL* = 1
  GLX_BUFFER_SIZE* = 2
  GLX_LEVEL* = 3
  GLX_RGBA* = 4
  GLX_DOUBLEBUFFER* = 5
  GLX_STEREO* = 6
  GLX_AUX_BUFFERS* = 7
  GLX_RED_SIZE* = 8
  GLX_GREEN_SIZE* = 9
  GLX_BLUE_SIZE* = 10
  GLX_ALPHA_SIZE* = 11
  GLX_DEPTH_SIZE* = 12
  GLX_STENCIL_SIZE* = 13
  GLX_ACCUM_RED_SIZE* = 14
  GLX_ACCUM_GREEN_SIZE* = 15
  GLX_ACCUM_BLUE_SIZE* = 16
  GLX_ACCUM_ALPHA_SIZE* = 17  # GLX_EXT_visual_info extension
  GLX_X_VISUAL_TYPE_EXT* = 0x00000022
  GLX_TRANSPARENT_TYPE_EXT* = 0x00000023
  GLX_TRANSPARENT_INDEX_VALUE_EXT* = 0x00000024
  GLX_TRANSPARENT_RED_VALUE_EXT* = 0x00000025
  GLX_TRANSPARENT_GREEN_VALUE_EXT* = 0x00000026
  GLX_TRANSPARENT_BLUE_VALUE_EXT* = 0x00000027
  GLX_TRANSPARENT_ALPHA_VALUE_EXT* = 0x00000028 # Error codes returned by glXGetConfig:
  GLX_BAD_SCREEN* = 1
  GLX_BAD_ATTRIBUTE* = 2
  GLX_NO_EXTENSION* = 3
  GLX_BAD_VISUAL* = 4
  GLX_BAD_CONTEXT* = 5
  GLX_BAD_VALUE* = 6
  GLX_BAD_ENUM* = 7           # GLX 1.1 and later:
  GLX_VENDOR* = 1
  GLX_VERSION* = 2
  GLX_EXTENSIONS* = 3         # GLX_visual_info extension
  GLX_TRUE_COLOR_EXT* = 0x00008002
  GLX_DIRECT_COLOR_EXT* = 0x00008003
  GLX_PSEUDO_COLOR_EXT* = 0x00008004
  GLX_STATIC_COLOR_EXT* = 0x00008005
  GLX_GRAY_SCALE_EXT* = 0x00008006
  GLX_STATIC_GRAY_EXT* = 0x00008007
  GLX_NONE_EXT* = 0x00008000
  GLX_TRANSPARENT_RGB_EXT* = 0x00008008
  GLX_TRANSPARENT_INDEX_EXT* = 0x00008009

type                          # From XLib:
  XPixmap* = TXID
  XFont* = TXID
  XColormap* = TXID
  GLXContext* = Pointer
  GLXPixmap* = TXID
  GLXDrawable* = TXID
  GLXContextID* = TXID
  TXPixmap* = XPixmap
  TXFont* = XFont
  TXColormap* = XColormap
  TGLXContext* = GLXContext
  TGLXPixmap* = GLXPixmap
  TGLXDrawable* = GLXDrawable
  TGLXContextID* = GLXContextID

proc glXChooseVisual*(dpy: PDisplay, screen: int, attribList: ptr int32): PXVisualInfo{.
    cdecl, dynlib: dllname, importc: "glXChooseVisual".}
proc glXCreateContext*(dpy: PDisplay, vis: PXVisualInfo, shareList: GLXContext,
                       direct: bool): GLXContext{.cdecl, dynlib: dllname,
    importc: "glXCreateContext".}
proc glXDestroyContext*(dpy: PDisplay, ctx: GLXContext){.cdecl, dynlib: dllname,
    importc: "glXDestroyContext".}
proc glXMakeCurrent*(dpy: PDisplay, drawable: GLXDrawable, ctx: GLXContext): bool{.
    cdecl, dynlib: dllname, importc: "glXMakeCurrent".}
proc glXCopyContext*(dpy: PDisplay, src, dst: GLXContext, mask: int32){.cdecl,
    dynlib: dllname, importc: "glXCopyContext".}
proc glXSwapBuffers*(dpy: PDisplay, drawable: GLXDrawable){.cdecl,
    dynlib: dllname, importc: "glXSwapBuffers".}
proc glXCreateGLXPixmap*(dpy: PDisplay, visual: PXVisualInfo, pixmap: XPixmap): GLXPixmap{.
    cdecl, dynlib: dllname, importc: "glXCreateGLXPixmap".}
proc glXDestroyGLXPixmap*(dpy: PDisplay, pixmap: GLXPixmap){.cdecl,
    dynlib: dllname, importc: "glXDestroyGLXPixmap".}
proc glXQueryExtension*(dpy: PDisplay, errorb, event: var int): bool{.cdecl,
    dynlib: dllname, importc: "glXQueryExtension".}
proc glXQueryVersion*(dpy: PDisplay, maj, min: var int): bool{.cdecl,
    dynlib: dllname, importc: "glXQueryVersion".}
proc glXIsDirect*(dpy: PDisplay, ctx: GLXContext): bool{.cdecl, dynlib: dllname,
    importc: "glXIsDirect".}
proc glXGetConfig*(dpy: PDisplay, visual: PXVisualInfo, attrib: int,
                   value: var int): int{.cdecl, dynlib: dllname,
    importc: "glXGetConfig".}
proc glXGetCurrentContext*(): GLXContext{.cdecl, dynlib: dllname,
    importc: "glXGetCurrentContext".}
proc glXGetCurrentDrawable*(): GLXDrawable{.cdecl, dynlib: dllname,
    importc: "glXGetCurrentDrawable".}
proc glXWaitGL*(){.cdecl, dynlib: dllname, importc: "glXWaitGL".}
proc glXWaitX*(){.cdecl, dynlib: dllname, importc: "glXWaitX".}
proc glXUseXFont*(font: XFont, first, count, list: int){.cdecl, dynlib: dllname,
    importc: "glXUseXFont".}
  # GLX 1.1 and later
proc glXQueryExtensionsString*(dpy: PDisplay, screen: int): cstring{.cdecl,
    dynlib: dllname, importc: "glXQueryExtensionsString".}
proc glXQueryServerString*(dpy: PDisplay, screen, name: int): cstring{.cdecl,
    dynlib: dllname, importc: "glXQueryServerString".}
proc glXGetClientString*(dpy: PDisplay, name: int): cstring{.cdecl,
    dynlib: dllname, importc: "glXGetClientString".}
  # Mesa GLX Extensions
proc glXCreateGLXPixmapMESA*(dpy: PDisplay, visual: PXVisualInfo,
                             pixmap: XPixmap, cmap: XColormap): GLXPixmap{.
    cdecl, dynlib: dllname, importc: "glXCreateGLXPixmapMESA".}
proc glXReleaseBufferMESA*(dpy: PDisplay, d: GLXDrawable): bool{.cdecl,
    dynlib: dllname, importc: "glXReleaseBufferMESA".}
proc glXCopySubBufferMESA*(dpy: PDisplay, drawbale: GLXDrawable,
                           x, y, width, height: int){.cdecl, dynlib: dllname,
    importc: "glXCopySubBufferMESA".}
proc glXGetVideoSyncSGI*(counter: var int32): int{.cdecl, dynlib: dllname,
    importc: "glXGetVideoSyncSGI".}
proc glXWaitVideoSyncSGI*(divisor, remainder: int, count: var int32): int{.
    cdecl, dynlib: dllname, importc: "glXWaitVideoSyncSGI".}
# implementation
