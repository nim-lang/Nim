#******************************************************************************
#
#  $Id: smpeg.pas,v 1.7 2004/08/14 22:54:30 savage Exp $
#  
#
#                                                                              
#       Borland Delphi SMPEG - SDL MPEG Player Library                         
#       Conversion of the SMPEG - SDL MPEG Player Library                      
#                                                                              
# Portions created by Sam Lantinga <slouken@devolution.com> are                
# Copyright (C) 1997, 1998, 1999, 2000, 2001  Sam Lantinga                     
# 5635-34 Springhouse Dr.                                                      
# Pleasanton, CA 94588 (USA)                                                   
#                                                                              
# All Rights Reserved.                                                         
#                                                                              
# The original files are : smpeg.h                                             
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
# Tom Jones <tigertomjones@gmx.de>  His Project inspired this conversion       
# Matthias Thoma <ma.thoma@gmx.de>                                             
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
#                                                                              
#                                                                              
#                                                                              
#                                                                              
#                                                                              
#                                                                              
#                                                                              
# Requires                                                                     
# --------                                                                     
#   The SDL Runtime libraris on Win32  : SDL.dll on Linux : libSDL-1.2.so.0    
#   They are available from...                                                 
#   http://www.libsdl.org .                                                    
#                                                                              
# Programming Notes                                                            
# -----------------                                                            
#                                                                              
#                                                                              
#                                                                              
#                                                                              
# Revision History                                                             
# ----------------                                                             
#   May      08 2001 - MT : Initial conversion                                 
#                                                                              
#   October  12 2001 - DA : Various changes as suggested by David Acklam       
#                                                                              
#   April   03 2003 - DL : Added jedi-sdl.inc include file to support more     
#                          Pascal compilers. Initial support is now included   
#                          for GnuPascal, VirtualPascal, TMT and obviously     
#                          continue support for Delphi Kylix and FreePascal.   
#                                                                              
#   April   08 2003 - MK : Aka Mr Kroket - Added Better FPC support            
#                          Fixed all invalid calls to DLL.                     
#                          Changed constant names to:                          
#                          const                                               
#                          STATUS_SMPEG_ERROR = -1;                            
#                          STATUS_SMPEG_STOPPED = 0;                           
#                          STATUS_SMPEG_PLAYING = 1;                           
#                          because SMPEG_ERROR is a function (_SMPEG_error     
#                          isn't correct), and cannot be two elements with the 
#                          same name                                           
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
#  $Log: smpeg.pas,v $
#  Revision 1.7  2004/08/14 22:54:30  savage
#  Updated so that Library name defines are correctly defined for MacOS X.
#
#  Revision 1.6  2004/05/10 14:10:04  savage
#  Initial MacOS X support. Fixed defines for MACOS ( Classic ) and DARWIN ( MacOS X ).
#
#  Revision 1.5  2004/04/13 09:32:08  savage
#  Changed Shared object names back to just the .so extension to avoid conflicts on various Linux/Unix distros. Therefore developers will need to create Symbolic links to the actual Share Objects if necessary.
#
#  Revision 1.4  2004/04/02 10:40:55  savage
#  Changed Linux Shared Object name so they reflect the Symbolic Links that are created when installing the RPMs from the SDL site.
#
#  Revision 1.3  2004/03/31 22:20:02  savage
#  Windows unit not used in this file, so it was removed to keep the code tidy.
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
  

when defined(windows): 
  const 
    SmpegLibName = "smpeg.dll"
elif defined(macosx): 
  const 
    SmpegLibName = "libsmpeg.dylib"
else: 
  const 
    SmpegLibName = "libsmpeg.so"
const 
  SMPEG_FILTER_INFO_MB_ERROR* = 1
  SMPEG_FILTER_INFO_PIXEL_ERROR* = 2 # Filter info from SMPEG 

type 
  SMPEG_FilterInfo*{.final.} = object 
    yuv_mb_square_error*: PUint16
    yuv_pixel_square_error*: PUint16

  TSMPEG_FilterInfo* = SMPEG_FilterInfo
  PSMPEG_FilterInfo* = ptr SMPEG_FilterInfo # MPEG filter definition 
  PSMPEG_Filter* = ptr TSMPEG_Filter # Callback functions for the filter 
  TSMPEG_FilterCallback* = proc (dest, source: POverlay, region: PRect, 
                                 filter_info: PSMPEG_FilterInfo, data: Pointer): Pointer{.
      cdecl.}
  TSMPEG_FilterDestroy* = proc (Filter: PSMPEG_Filter): Pointer{.cdecl.} # The filter 
                                                                         # 
                                                                         # definition itself 
  TSMPEG_Filter*{.final.} = object  # The null filter (default). It simply copies the source rectangle to the video overlay. 
    flags*: Uint32
    data*: Pointer
    callback*: TSMPEG_FilterCallback
    destroy*: TSMPEG_FilterDestroy


proc SMPEGfilter_null*(): PSMPEG_Filter{.cdecl, importc: "SMPEGfilter_null", 
    dynlib: SmpegLibName.}
  # The bilinear filter. A basic low-pass filter that will produce a smoother image. 
proc SMPEGfilter_bilinear*(): PSMPEG_Filter{.cdecl, 
    importc: "SMPEGfilter_bilinear", dynlib: SmpegLibName.}
  # The deblocking filter. It filters block borders and non-intra coded blocks to reduce blockiness 
proc SMPEGfilter_deblocking*(): PSMPEG_Filter{.cdecl, 
    importc: "SMPEGfilter_deblocking", dynlib: SmpegLibName.}
  #------------------------------------------------------------------------------
  # SMPEG.h
  #------------------------------------------------------------------------------
const 
  SMPEG_MAJOR_VERSION* = 0'i8
  SMPEG_MINOR_VERSION* = 4'i8
  SMPEG_PATCHLEVEL* = 2'i8

type 
  SMPEG_version*{.final.} = object 
    major*: UInt8
    minor*: UInt8
    patch*: UInt8

  TSMPEG_version* = SMPEG_version
  PSMPEG_version* = ptr TSMPEG_version # This is the actual SMPEG object
  TSMPEG*{.final.} = object 
  PSMPEG* = ptr TSMPEG        # Used to get information about the SMPEG object 
  TSMPEG_Info*{.final.} = object 
    has_audio*: int
    has_video*: int
    width*: int
    height*: int
    current_frame*: int
    current_fps*: float64
    audio_string*: array[0..79, char]
    audio_current_frame*: int
    current_offset*: UInt32
    total_size*: UInt32
    current_time*: float64
    total_time*: float64

  PSMPEG_Info* = ptr TSMPEG_Info # Possible MPEG status codes 

const 
  STATUS_SMPEG_ERROR* = - 1
  STATUS_SMPEG_STOPPED* = 0
  STATUS_SMPEG_PLAYING* = 1

type 
  TSMPEGstatus* = int
  PSMPEGstatus* = ptr int     # Matches the declaration of SDL_UpdateRect() 
  TSMPEG_DisplayCallback* = proc (dst: PSurface, x, y: int, w, h: int): Pointer{.
      cdecl.} # Create a new SMPEG object from an MPEG file.
              #  On return, if 'info' is not NULL, it will be filled with information
              #  about the MPEG object.
              #  This function returns a new SMPEG object.  Use SMPEG_error() to find out
              #  whether or not there was a problem building the MPEG stream.
              #  The sdl_audio parameter indicates if SMPEG should initialize the SDL audio
              #  subsystem. If not, you will have to use the SMPEG_playaudio() function below
              #  to extract the decoded data. 

proc SMPEG_new*(theFile: cstring, info: PSMPEG_Info, audio: int): PSMPEG{.cdecl, 
    importc: "SMPEG_new", dynlib: SmpegLibName.}
  # The same as above for a file descriptor 
proc SMPEG_new_descr*(theFile: int, info: PSMPEG_Info, audio: int): PSMPEG{.
    cdecl, importc: "SMPEG_new_descr", dynlib: SmpegLibName.}
  #  The same as above but for a raw chunk of data.  SMPEG makes a copy of the
  #   data, so the application is free to delete after a successful call to this
  #   function. 
proc SMPEG_new_data*(data: Pointer, size: int, info: PSMPEG_Info, audio: int): PSMPEG{.
    cdecl, importc: "SMPEG_new_data", dynlib: SmpegLibName.}
  # Get current information about an SMPEG object 
proc SMPEG_getinfo*(mpeg: PSMPEG, info: PSMPEG_Info){.cdecl, 
    importc: "SMPEG_getinfo", dynlib: SmpegLibName.}
  #procedure SMPEG_getinfo(mpeg: PSMPEG; info: Pointer);
  #cdecl; external  SmpegLibName;
  # Enable or disable audio playback in MPEG stream 
proc SMPEG_enableaudio*(mpeg: PSMPEG, enable: int){.cdecl, 
    importc: "SMPEG_enableaudio", dynlib: SmpegLibName.}
  # Enable or disable video playback in MPEG stream 
proc SMPEG_enablevideo*(mpeg: PSMPEG, enable: int){.cdecl, 
    importc: "SMPEG_enablevideo", dynlib: SmpegLibName.}
  # Delete an SMPEG object 
proc SMPEG_delete*(mpeg: PSMPEG){.cdecl, importc: "SMPEG_delete", 
                                  dynlib: SmpegLibName.}
  # Get the current status of an SMPEG object 
proc SMPEG_status*(mpeg: PSMPEG): TSMPEGstatus{.cdecl, importc: "SMPEG_status", 
    dynlib: SmpegLibName.}
  # status
  # Set the audio volume of an MPEG stream, in the range 0-100 
proc SMPEG_setvolume*(mpeg: PSMPEG, volume: int){.cdecl, 
    importc: "SMPEG_setvolume", dynlib: SmpegLibName.}
  # Set the destination surface for MPEG video playback
  #  'surfLock' is a mutex used to synchronize access to 'dst', and can be NULL.
  #  'callback' is a function called when an area of 'dst' needs to be updated.
  #  If 'callback' is NULL, the default function (SDL_UpdateRect) will be used. 
proc SMPEG_setdisplay*(mpeg: PSMPEG, dst: PSurface, surfLock: Pmutex, 
                       callback: TSMPEG_DisplayCallback){.cdecl, 
    importc: "SMPEG_setdisplay", dynlib: SmpegLibName.}
  # Set or clear looping play on an SMPEG object 
proc SMPEG_loop*(mpeg: PSMPEG, repeat_: int){.cdecl, importc: "SMPEG_loop", 
    dynlib: SmpegLibName.}
  # Scale pixel display on an SMPEG object 
proc SMPEG_scaleXY*(mpeg: PSMPEG, width, height: int){.cdecl, 
    importc: "SMPEG_scaleXY", dynlib: SmpegLibName.}
proc SMPEG_scale*(mpeg: PSMPEG, scale: int){.cdecl, importc: "SMPEG_scale", 
    dynlib: SmpegLibName.}
proc SMPEG_Double*(mpeg: PSMPEG, doubleit: bool)
  # Move the video display area within the destination surface 
proc SMPEG_move*(mpeg: PSMPEG, x, y: int){.cdecl, importc: "SMPEG_move", 
    dynlib: SmpegLibName.}
  # Set the region of the video to be shown 
proc SMPEG_setdisplayregion*(mpeg: PSMPEG, x, y, w, h: int){.cdecl, 
    importc: "SMPEG_setdisplayregion", dynlib: SmpegLibName.}
  # Play an SMPEG object 
proc SMPEG_play*(mpeg: PSMPEG){.cdecl, importc: "SMPEG_play", 
                                dynlib: SmpegLibName.}
  # Pause/Resume playback of an SMPEG object
proc SMPEG_pause*(mpeg: PSMPEG){.cdecl, importc: "SMPEG_pause", 
                                 dynlib: SmpegLibName.}
  # Stop playback of an SMPEG object 
proc SMPEG_stop*(mpeg: PSMPEG){.cdecl, importc: "SMPEG_stop", 
                                dynlib: SmpegLibName.}
  # Rewind the play position of an SMPEG object to the beginning of the MPEG 
proc SMPEG_rewind*(mpeg: PSMPEG){.cdecl, importc: "SMPEG_rewind", 
                                  dynlib: SmpegLibName.}
  # Seek 'bytes' bytes in the MPEG stream 
proc SMPEG_seek*(mpeg: PSMPEG, bytes: int){.cdecl, importc: "SMPEG_seek", 
    dynlib: SmpegLibName.}
  # Skip 'seconds' seconds in the MPEG stream 
proc SMPEG_skip*(mpeg: PSMPEG, seconds: float32){.cdecl, importc: "SMPEG_skip", 
    dynlib: SmpegLibName.}
  # Render a particular frame in the MPEG video
  #   API CHANGE: This function no longer takes a target surface and position.
  #               Use SMPEG_setdisplay() and SMPEG_move() to set this information. 
proc SMPEG_renderFrame*(mpeg: PSMPEG, framenum: int){.cdecl, 
    importc: "SMPEG_renderFrame", dynlib: SmpegLibName.}
  # Render the last frame of an MPEG video 
proc SMPEG_renderFinal*(mpeg: PSMPEG, dst: PSurface, x, y: int){.cdecl, 
    importc: "SMPEG_renderFinal", dynlib: SmpegLibName.}
  # Set video filter 
proc SMPEG_filter*(mpeg: PSMPEG, filter: PSMPEG_Filter): PSMPEG_Filter{.cdecl, 
    importc: "SMPEG_filter", dynlib: SmpegLibName.}
  # Return NULL if there is no error in the MPEG stream, or an error message
  #   if there was a fatal error in the MPEG stream for the SMPEG object. 
proc SMPEG_error*(mpeg: PSMPEG): cstring{.cdecl, importc: "SMPEG_error", 
    dynlib: SmpegLibName.}
  # Exported callback function for audio playback.
  #   The function takes a buffer and the amount of data to fill, and returns
  #   the amount of data in bytes that was actually written.  This will be the
  #   amount requested unless the MPEG audio has finished.
  #
proc SMPEG_playAudio*(mpeg: PSMPEG, stream: PUInt8, length: int): int{.cdecl, 
    importc: "SMPEG_playAudio", dynlib: SmpegLibName.}
  # Wrapper for SMPEG_playAudio() that can be passed to SDL and SDL_mixer 
proc SMPEG_playAudioSDL*(mpeg: Pointer, stream: PUInt8, length: int){.cdecl, 
    importc: "SMPEG_playAudioSDL", dynlib: SmpegLibName.}
  # Get the best SDL audio spec for the audio stream 
proc SMPEG_wantedSpec*(mpeg: PSMPEG, wanted: PAudioSpec): int{.cdecl, 
    importc: "SMPEG_wantedSpec", dynlib: SmpegLibName.}
  # Inform SMPEG of the actual SDL audio spec used for sound playback 
proc SMPEG_actualSpec*(mpeg: PSMPEG, spec: PAudioSpec){.cdecl, 
    importc: "SMPEG_actualSpec", dynlib: SmpegLibName.}
  # This macro can be used to fill a version structure with the compile-time
  #  version of the SDL library. 
proc SMPEG_GETVERSION*(X: var TSMPEG_version)
# implementation

proc SMPEG_double(mpeg: PSMPEG, doubleit: bool) = 
  if doubleit: SMPEG_scale(mpeg, 2)
  else: SMPEG_scale(mpeg, 1)
  
proc SMPEG_GETVERSION(X: var TSMPEG_version) = 
  X.major = SMPEG_MAJOR_VERSION
  X.minor = SMPEG_MINOR_VERSION
  X.patch = SMPEG_PATCHLEVEL
