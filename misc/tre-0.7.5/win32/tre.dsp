# Microsoft Developer Studio Project File - Name="tre" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Dynamic-Link Library" 0x0102

CFG=tre - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE
!MESSAGE NMAKE /f "tre.mak".
!MESSAGE
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE
!MESSAGE NMAKE /f "tre.mak" CFG="tre - Win32 Debug"
!MESSAGE
!MESSAGE Possible choices for configuration are:
!MESSAGE
!MESSAGE "tre - Win32 Release" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE "tre - Win32 Debug" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "tre - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "TRE_EXPORTS" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GX /O2 /I "../win32" /I "../lib" /I "../gnulib/lib" /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "TRE_EXPORTS" /D "HAVE_CONFIG_H" /FR /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x40c /d "NDEBUG"
# ADD RSC /l 0x40c /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /dll /machine:I386
# ADD LINK32 msvcrt.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib msvcprt.lib /nologo /dll /machine:I386
# SUBTRACT LINK32 /nodefaultlib

!ELSEIF  "$(CFG)" == "tre - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MTd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "TRE_EXPORTS" /YX /FD /GZ /c
# ADD CPP /nologo /MDd /W3 /Gm /GX /ZI /Od /I "../win32" /I "../lib" /I "../gnulib/lib" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "TRE_EXPORTS" /D "TRE_DEBUG" /D "HAVE_CONFIG_H" /FR /YX /FD /GZ /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x40c /d "_DEBUG"
# ADD RSC /l 0x40c /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /dll /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib msvcprt.lib /nologo /dll /debug /machine:I386 /pdbtype:sept

!ENDIF

# Begin Target

# Name "tre - Win32 Release"
# Name "tre - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=..\lib\regcomp.c
# End Source File
# Begin Source File

SOURCE=..\lib\regerror.c
# End Source File
# Begin Source File

SOURCE=..\lib\regexec.c
# End Source File
# Begin Source File

SOURCE="..\lib\tre-ast.c"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-compile.c"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-match-approx.c"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-match-backtrack.c"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-match-parallel.c"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-mem.c"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-parse.c"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-stack.c"
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter ""
# Begin Source File

SOURCE=.\config.h
# End Source File
# Begin Source File

SOURCE=..\gnulib\lib\gettext.h
# End Source File
# Begin Source File

SOURCE=..\lib\regex.h
# End Source File
# Begin Source File

SOURCE="..\lib\tre-ast.h"
# End Source File
# Begin Source File

SOURCE=".\tre-config.h"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-compile.h"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-internal.h"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-match-utils.h"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-mem.h"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-parse.h"
# End Source File
# Begin Source File

SOURCE="..\lib\tre-stack.h"
# End Source File
# Begin Source File

SOURCE=.\tre.def
# End Source File
# Begin Source File

SOURCE=..\lib\xmalloc.h
# End Source File
# End Group
# End Target
# Begin Group "Header Files No. 1"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# End Group
# End Project
