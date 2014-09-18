#
#  $Id: sdl_image.pas,v 1.14 2007/05/29 21:31:13 savage Exp $
#  
#
#******************************************************************************
#                                                                              
#       Borland Delphi SDL_Image - An example image loading library for use    
#                                  with SDL                                    
#       Conversion of the Simple DirectMedia Layer Image Headers               
#                                                                              
# Portions created by Sam Lantinga <slouken@devolution.com> are                
# Copyright (C) 1997, 1998, 1999, 2000, 2001  Sam Lantinga                     
# 5635-34 Springhouse Dr.                                                      
# Pleasanton, CA 94588 (USA)                                                   
#                                                                              
# All Rights Reserved.                                                         
#                                                                              
# The original files are : SDL_image.h                                         
#                                                                              
# The initial developer of this Pascal code was :                              
# Matthias Thoma <ma.thoma@gmx.de>                                             
#                                                                              
# Portions created by Matthias Thoma are                                       
# Copyright (C) 2000 - 2001 Matthias Thoma.                                    
#                                                                              
#                                                                              
# Contributor(s)                                                               
# --------------                                                               
# Dominique Louis <Dominique@SavageSoftware.com.au>                            
#                                                                              
# Obtained through:                                                            
# Joint Endeavour of Delphi Innovators ( Project JEDI )                        
#                                                                              
# You may retrieve the latest version of this file at the Project              
# JEDI home page, located at http://delphi-jedi.org                            
#                                                                              
# The contents of this file are used with permission, subject to               
# the Mozilla Public License Version 1.1 (the "License"); you may              
# not use this file except in compliance with the License. You may             
# obtain a copy of the License at                                              
# http://www.mozilla.org/MPL/MPL-1.1.html                                      
#                                                                              
# Software distributed under the License is distributed on an                  
# "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or               
# implied. See the License for the specific language governing                 
# rights and limitations under the License.                                    
#                                                                              
# Description                                                                  
# -----------                                                                  
#   A simple library to load images of various formats as SDL surfaces         
#                                                                              
# Requires                                                                     
# --------                                                                     
#   SDL.pas in your search path.                                               
#                                                                              
# Programming Notes                                                            
# -----------------                                                            
#   See the Aliens Demo on how to make use of this libaray                     
#                                                                              
# Revision History                                                             
# ----------------                                                             
#   April    02 2001 - MT : Initial Translation                                
#                                                                              
#   May      08 2001 - DL : Added ExternalSym derectives and copyright header  
#                                                                              
#   April   03 2003 - DL : Added jedi-sdl.inc include file to support more     
#                          Pascal compilers. Initial support is now included   
#                          for GnuPascal, VirtualPascal, TMT and obviously     
#                          continue support for Delphi Kylix and FreePascal.   
#                                                                              
#   April   08 2003 - MK : Aka Mr Kroket - Added Better FPC support            
#                                                                              
#   April   24 2003 - DL : under instruction from Alexey Barkovoy, I have added
#                          better TMT Pascal support and under instruction     
#                          from Prof. Abimbola Olowofoyeku (The African Chief),
#                          I have added better Gnu Pascal support              
#                                                                              
#   April   30 2003 - DL : under instruction from David Mears AKA              
#                          Jason Siletto, I have added FPC Linux support.      
#                          This was compiled with fpc 1.1, so remember to set  
#                          include file path. ie. -Fi/usr/share/fpcsrc/rtl/*   
#                                                                              
#
#  $Log: sdl_image.pas,v $
#  Revision 1.14  2007/05/29 21:31:13  savage
#  Changes as suggested by Almindor for 64bit compatibility.
#
#  Revision 1.13  2007/05/20 20:30:54  savage
#  Initial Changes to Handle 64 Bits
#
#  Revision 1.12  2006/12/02 00:14:40  savage
#  Updated to latest version
#
#  Revision 1.11  2005/04/10 18:22:59  savage
#  Changes as suggested by Michalis, thanks.
#
#  Revision 1.10  2005/04/10 11:48:33  savage
#  Changes as suggested by Michalis, thanks.
#
#  Revision 1.9  2005/01/05 01:47:07  savage
#  Changed LibName to reflect what MacOS X should have. ie libSDL*-1.2.0.dylib respectively.
#
#  Revision 1.8  2005/01/04 23:14:44  savage
#  Changed LibName to reflect what most Linux distros will have. ie libSDL*-1.2.so.0 respectively.
#
#  Revision 1.7  2005/01/01 02:03:12  savage
#  Updated to v1.2.4
#
#  Revision 1.6  2004/08/14 22:54:30  savage
#  Updated so that Library name defines are correctly defined for MacOS X.
#
#  Revision 1.5  2004/05/10 14:10:04  savage
#  Initial MacOS X support. Fixed defines for MACOS ( Classic ) and DARWIN ( MacOS X ).
#
#  Revision 1.4  2004/04/13 09:32:08  savage
#  Changed Shared object names back to just the .so extension to avoid conflicts on various Linux/Unix distros. Therefore developers will need to create Symbolic links to the actual Share Objects if necessary.
#
#  Revision 1.3  2004/04/01 20:53:23  savage
#  Changed Linux Shared Object names so they reflect the Symbolic Links that are created when installing the RPMs from the SDL site.
#
#  Revision 1.2  2004/03/30 20:23:28  savage
#  Tidied up use of UNIX compiler directive.
#
#  Revision 1.1  2004/02/14 23:35:42  savage
#  version 1 of sdl_image, sdl_mixer and smpeg.
#
#
#
#******************************************************************************

import
  sdl

when defined(windows):
  const
    ImageLibName = "SDL_Image.dll"
elif defined(macosx):
  const
    ImageLibName = "libSDL_image-1.2.0.dylib"
else:
  const
    ImageLibName = "libSDL_image(.so|-1.2.so.0)"
const
  IMAGE_MAJOR_VERSION* = 1
  IMAGE_MINOR_VERSION* = 2
  IMAGE_PATCHLEVEL* = 5

# This macro can be used to fill a version structure with the compile-time
#  version of the SDL_image library. 

proc imageVersion*(x: var Tversion)
  # This function gets the version of the dynamically linked SDL_image library.
  #   it should NOT be used to fill a version structure, instead you should
  #   use the SDL_IMAGE_VERSION() macro.
  # 
proc imgLinkedVersion*(): Pversion{.importc: "IMG_Linked_Version", 
                                    dynlib: ImageLibName.}
  # Load an image from an SDL data source.
  #   The 'type' may be one of: "BMP", "GIF", "PNG", etc.
  #
  #   If the image format supports a transparent pixel, SDL will set the
  #   colorkey for the surface.  You can enable RLE acceleration on the
  #   surface afterwards by calling:
  #        SDL_SetColorKey(image, SDL_RLEACCEL, image.format.colorkey);
  #

const
  IMG_INIT_JPG* = 0x00000001
  IMG_INIT_PNG* = 0x00000002
  IMG_INIT_TIF* = 0x00000004
  IMG_INIT_WEBP* = 0x00000008

proc imgInit*(flags: cint): int {.cdecl, importc: "IMG_Init",
                                  dynlib: ImageLibName.}
proc imgQuit*() {.cdecl, importc: "IMG_Quit",
                                  dynlib: ImageLibName.}
proc imgLoadTypedRW*(src: PRWops, freesrc: cint, theType: cstring): PSurface{.
    cdecl, importc: "IMG_LoadTyped_RW", dynlib: ImageLibName.}
  # Convenience functions 
proc imgLoad*(theFile: cstring): PSurface{.cdecl, importc: "IMG_Load", 
    dynlib: ImageLibName.}
proc imgLoadRW*(src: PRWops, freesrc: cint): PSurface{.cdecl, 
    importc: "IMG_Load_RW", dynlib: ImageLibName.}
  # Invert the alpha of a surface for use with OpenGL
  #  This function is now a no-op, and only provided for backwards compatibility. 
proc imgInvertAlpha*(theOn: cint): cint{.cdecl, importc: "IMG_InvertAlpha", 
                                        dynlib: ImageLibName.}
  # Functions to detect a file type, given a seekable source 
proc imgIsBMP*(src: PRWops): cint{.cdecl, importc: "IMG_isBMP", 
                                   dynlib: ImageLibName.}
proc imgIsGIF*(src: PRWops): cint{.cdecl, importc: "IMG_isGIF", 
                                   dynlib: ImageLibName.}
proc imgIsJPG*(src: PRWops): cint{.cdecl, importc: "IMG_isJPG", 
                                   dynlib: ImageLibName.}
proc imgIsLBM*(src: PRWops): cint{.cdecl, importc: "IMG_isLBM", 
                                   dynlib: ImageLibName.}
proc imgIsPCX*(src: PRWops): cint{.cdecl, importc: "IMG_isPCX", 
                                   dynlib: ImageLibName.}
proc imgIsPNG*(src: PRWops): cint{.cdecl, importc: "IMG_isPNG", 
                                   dynlib: ImageLibName.}
proc imgIsPNM*(src: PRWops): cint{.cdecl, importc: "IMG_isPNM", 
                                   dynlib: ImageLibName.}
proc imgIsTIF*(src: PRWops): cint{.cdecl, importc: "IMG_isTIF", 
                                   dynlib: ImageLibName.}
proc imgIsXCF*(src: PRWops): cint{.cdecl, importc: "IMG_isXCF", 
                                   dynlib: ImageLibName.}
proc imgIsXPM*(src: PRWops): cint{.cdecl, importc: "IMG_isXPM", 
                                   dynlib: ImageLibName.}
proc imgIsXV*(src: PRWops): cint{.cdecl, importc: "IMG_isXV", 
                                  dynlib: ImageLibName.}
  # Individual loading functions 
proc imgLoadBMP_RW*(src: PRWops): PSurface{.cdecl, importc: "IMG_LoadBMP_RW", 
    dynlib: ImageLibName.}
proc imgLoadGIF_RW*(src: PRWops): PSurface{.cdecl, importc: "IMG_LoadGIF_RW", 
    dynlib: ImageLibName.}
proc imgLoadJPG_RW*(src: PRWops): PSurface{.cdecl, importc: "IMG_LoadJPG_RW", 
    dynlib: ImageLibName.}
proc imgLoadLBM_RW*(src: PRWops): PSurface{.cdecl, importc: "IMG_LoadLBM_RW", 
    dynlib: ImageLibName.}
proc imgLoadPCX_RW*(src: PRWops): PSurface{.cdecl, importc: "IMG_LoadPCX_RW", 
    dynlib: ImageLibName.}
proc imgLoadPNM_RW*(src: PRWops): PSurface{.cdecl, importc: "IMG_LoadPNM_RW", 
    dynlib: ImageLibName.}
proc imgLoadPNG_RW*(src: PRWops): PSurface{.cdecl, importc: "IMG_LoadPNG_RW", 
    dynlib: ImageLibName.}
proc imgLoadTGA_RW*(src: PRWops): PSurface{.cdecl, importc: "IMG_LoadTGA_RW", 
    dynlib: ImageLibName.}
proc imgLoadTIF_RW*(src: PRWops): PSurface{.cdecl, importc: "IMG_LoadTIF_RW", 
    dynlib: ImageLibName.}
proc imgLoadXCF_RW*(src: PRWops): PSurface{.cdecl, importc: "IMG_LoadXCF_RW", 
    dynlib: ImageLibName.}
proc imgLoadXPM_RW*(src: PRWops): PSurface{.cdecl, importc: "IMG_LoadXPM_RW", 
    dynlib: ImageLibName.}
proc imgLoadXV_RW*(src: PRWops): PSurface{.cdecl, importc: "IMG_LoadXV_RW", 
    dynlib: ImageLibName.}
proc imgReadXPMFromArray*(xpm: cstringArray): PSurface{.cdecl, 
    importc: "IMG_ReadXPMFromArray", dynlib: ImageLibName.}

proc imageVersion(x: var Tversion) = 
  x.major = IMAGE_MAJOR_VERSION
  x.minor = IMAGE_MINOR_VERSION
  x.patch = IMAGE_PATCHLEVEL

