#
#
#            Nim's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# ---------------------------------------------------------------------
#  shfolder.dll is distributed standard with IE5.5, so it should ship
#  with 2000/XP or higher but is likely to be installed on NT/95/98 or
#  ME as well.  It works on all these systems.
#
#  The info found here is also in the registry:
#  HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders\
#  HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\
#
#  Note that not all CSIDL_* constants are supported by shlfolder.dll,
#  they should be supported by the shell32.dll, though again not on all
#  systems.
#  ---------------------------------------------------------------------

{.deadCodeElim: on.}

import 
  windows

const 
  LibName* = "SHFolder.dll"

const 
  CSIDL_PROGRAMS* = 0x00000002 # %SYSTEMDRIVE%\Program Files                                      
  CSIDL_PERSONAL* = 0x00000005 # %USERPROFILE%\My Documents                                       
  CSIDL_FAVORITES* = 0x00000006 # %USERPROFILE%\Favorites                                          
  CSIDL_STARTUP* = 0x00000007 # %USERPROFILE%\Start menu\Programs\Startup                        
  CSIDL_RECENT* = 0x00000008  # %USERPROFILE%\Recent                                             
  CSIDL_SENDTO* = 0x00000009  # %USERPROFILE%\Sendto                                             
  CSIDL_STARTMENU* = 0x0000000B # %USERPROFILE%\Start menu                                         
  CSIDL_MYMUSIC* = 0x0000000D # %USERPROFILE%\Documents\My Music                                 
  CSIDL_MYVIDEO* = 0x0000000E # %USERPROFILE%\Documents\My Videos                                
  CSIDL_DESKTOPDIRECTORY* = 0x00000010 # %USERPROFILE%\Desktop                                            
  CSIDL_NETHOOD* = 0x00000013 # %USERPROFILE%\NetHood                                            
  CSIDL_TEMPLATES* = 0x00000015 # %USERPROFILE%\Templates                                          
  CSIDL_COMMON_STARTMENU* = 0x00000016 # %PROFILEPATH%\All users\Start menu                               
  CSIDL_COMMON_PROGRAMS* = 0x00000017 # %PROFILEPATH%\All users\Start menu\Programs                      
  CSIDL_COMMON_STARTUP* = 0x00000018 # %PROFILEPATH%\All users\Start menu\Programs\Startup              
  CSIDL_COMMON_DESKTOPDIRECTORY* = 0x00000019 # %PROFILEPATH%\All users\Desktop                                  
  CSIDL_APPDATA* = 0x0000001A # %USERPROFILE%\Application Data (roaming)                         
  CSIDL_PRINTHOOD* = 0x0000001B # %USERPROFILE%\Printhood                                          
  CSIDL_LOCAL_APPDATA* = 0x0000001C # %USERPROFILE%\Local Settings\Application Data (non roaming)      
  CSIDL_COMMON_FAVORITES* = 0x0000001F # %PROFILEPATH%\All users\Favorites                                
  CSIDL_INTERNET_CACHE* = 0x00000020 # %USERPROFILE%\Local Settings\Temporary Internet Files            
  CSIDL_COOKIES* = 0x00000021 # %USERPROFILE%\Cookies                                            
  CSIDL_HISTORY* = 0x00000022 # %USERPROFILE%\Local settings\History                             
  CSIDL_COMMON_APPDATA* = 0x00000023 # %PROFILESPATH%\All Users\Application Data                        
  CSIDL_WINDOWS* = 0x00000024 # %SYSTEMROOT%                                                     
  CSIDL_SYSTEM* = 0x00000025  # %SYSTEMROOT%\SYSTEM32 (may be system on 95/98/ME)                
  CSIDL_PROGRAM_FILES* = 0x00000026 # %SYSTEMDRIVE%\Program Files                                      
  CSIDL_MYPICTURES* = 0x00000027 # %USERPROFILE%\My Documents\My Pictures                           
  CSIDL_PROFILE* = 0x00000028 # %USERPROFILE%                                                    
  CSIDL_PROGRAM_FILES_COMMON* = 0x0000002B # %SYSTEMDRIVE%\Program Files\Common                               
  CSIDL_COMMON_TEMPLATES* = 0x0000002D # %PROFILEPATH%\All Users\Templates                                
  CSIDL_COMMON_DOCUMENTS* = 0x0000002E # %PROFILEPATH%\All Users\Documents                                
  CSIDL_COMMON_ADMINTOOLS* = 0x0000002F # %PROFILEPATH%\All Users\Start Menu\Programs\Administrative Tools 
  CSIDL_ADMINTOOLS* = 0x00000030 # %USERPROFILE%\Start Menu\Programs\Administrative Tools           
  CSIDL_COMMON_MUSIC* = 0x00000035 # %PROFILEPATH%\All Users\Documents\my music                       
  CSIDL_COMMON_PICTURES* = 0x00000036 # %PROFILEPATH%\All Users\Documents\my pictures                    
  CSIDL_COMMON_VIDEO* = 0x00000037 # %PROFILEPATH%\All Users\Documents\my videos                      
  CSIDL_CDBURN_AREA* = 0x0000003B # %USERPROFILE%\Local Settings\Application Data\Microsoft\CD Burning 
  CSIDL_PROFILES* = 0x0000003E # %PROFILEPATH%                                                    
  CSIDL_FLAG_CREATE* = 0x00008000 # (force creation of requested folder if it doesn't exist yet)     
                                  # Original entry points 

proc SHGetFolderPathA*(Ahwnd: HWND, Csidl: int, Token: THandle, Flags: DWord, 
                       Path: cstring): HRESULT{.stdcall, dynlib: LibName, 
    importc: "SHGetFolderPathA".}
proc SHGetFolderPathW*(Ahwnd: HWND, Csidl: int, Token: THandle, Flags: DWord, 
                       Path: cstring): HRESULT{.stdcall, dynlib: LibName, 
    importc: "SHGetFolderPathW".}
proc SHGetFolderPath*(Ahwnd: HWND, Csidl: int, Token: THandle, Flags: DWord, 
                      Path: cstring): HRESULT{.stdcall, dynlib: LibName, 
    importc: "SHGetFolderPathA".}
type 
  PFNSHGetFolderPathA* = proc (Ahwnd: HWND, Csidl: int, Token: THandle, 
                               Flags: DWord, Path: cstring): HRESULT{.stdcall.}
  PFNSHGetFolderPathW* = proc (Ahwnd: HWND, Csidl: int, Token: THandle, 
                               Flags: DWord, Path: cstring): HRESULT{.stdcall.}
  PFNSHGetFolderPath* = PFNSHGetFolderPathA
  TSHGetFolderPathA* = PFNSHGetFolderPathA
  TSHGetFolderPathW* = PFNSHGetFolderPathW
  TSHGetFolderPath* = TSHGetFolderPathA

