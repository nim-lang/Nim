REM - Run the full testsuite;  testament\tester all

REM - Uncomment the list of changes in news.txt
REM - write a news ticker entry
REM - Update the version

REM - Generate the full docs;  koch web0
REM - Generate the installers;
REM - Update the version in system.nim
REM - Test the installers
REM - Tag the release
REM - Merge devel into master
REM - Update csources

set NIMVER=%1

Rem Build -docs file:
koch web0
cd web\upload
7z a -tzip docs-%NIMVER%.zip *.html
move /y docs-%NIMVER%.zip download
cd ..\..

Rem Build csources
koch csources -d:release || exit /b

rem Grab C sources and nimsuggest
git clone --depth 1 https://github.com/nim-lang/csources_v1.git csources

set PATH=%CD%\bin;%PATH%

ReM Build Win32 version:

set PATH=C:\Users\araq\projects\mingw32\bin;%PATH%
cd csources
call build.bat
cd ..
ReM Rebuilding koch is necessary because it uses its pointer size to determine
ReM which mingw link to put in the NSIS installer.
nim c --out:koch_temp koch || exit /b
koch_temp boot -d:release || exit /b
koch_temp nsis -d:release || exit /b
koch_temp zip -d:release || exit /b
dir build
move /y build\nim_%NIMVER%.exe build\nim-%NIMVER%_x32.exe || exit /b
move /y build\nim-%NIMVER%.zip build\nim-%NIMVER%_x32.zip || exit /b


ReM Build Win64 version:
set PATH=C:\Users\araq\projects\mingw64\bin;%PATH%
cd csources
call build64.bat
cd ..
nim c --out:koch_temp koch || exit /b
koch_temp boot -d:release || exit /b
koch_temp nsis -d:release || exit /b
koch_temp zip -d:release || exit /b
move /y build\nim_%NIMVER%.exe build\nim-%NIMVER%_x64.exe || exit /b
move /y build\nim-%NIMVER%.zip build\nim-%NIMVER%_x64.zip || exit /b
